import Buffer_Primitives_Test_Support
import Buffer_Ring_Primitives
import Buffer_Ring_Primitives_Test_Support
import Index_Primitives
import Memory_Allocator_Primitive
import Memory_Heap_Primitives
import Storage_Contiguous_Primitives
import Testing

// The ratified ring seam (ASK-B, 2026-06-10): front-anchored restricted-domain
// Store.Protocol over any ledgered store. [DS-024]: both ring columns pass the
// seam-ledger count-laws from this package's own suite; the behavioral probes mirror
// the ratification spike (.handoffs/probes-2026-06-10/queue-family-spike/).

private typealias HeapStorage<E: ~Copyable> =
    Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>

private typealias GrowableRing<E: ~Copyable> = Buffer<HeapStorage<E>>.Ring
private typealias BoundedRing<E: ~Copyable> = Buffer<HeapStorage<E>>.Ring.Bounded

// MARK: - [DS-024] — the seam-ledger laws on both ring columns

@Suite
struct RingSeamLawTests {

    @Test
    func `the growable ring obeys the seam ledger laws`() {
        let violations = Seam.Ledger.violations(
            makeEmpty: { GrowableRing<Int>(minimumCapacity: Index<Int>.Count(4)) },
            element: { $0 }
        )
        #expect(violations.isEmpty, "\(violations)")
    }

    @Test
    func `the bounded ring obeys the seam ledger laws`() {
        let violations = Seam.Ledger.violations(
            makeEmpty: { BoundedRing<Int>(minimumCapacity: Index<Int>.Count(4)) },
            element: { $0 }
        )
        #expect(violations.isEmpty, "\(violations)")
    }
}

// MARK: - The ring discipline through the seam (FIFO wrap, re-anchoring, back moves)

@Suite
struct RingSeamDisciplineTests {

    @Test
    func `FIFO order survives a physical wrap driven purely through seam ops`() {
        var ring = GrowableRing<Int>(minimumCapacity: Index<Int>.Count(4))
        ring.initialize(at: 0, to: 1)
        ring.initialize(at: 1, to: 2)
        ring.initialize(at: 2, to: 3)
        ring.initialize(at: 3, to: 4)
        let a = ring.move(at: 0)  // front-pop: head advances
        let b = ring.move(at: 0)
        #expect(a == 1)
        #expect(b == 2)
        ring.initialize(at: 2, to: 5)  // back-append: physically wraps
        ring.initialize(at: 3, to: 6)  // two-run ledger
        var seen: [Int] = []
        while !ring.isEmpty {
            seen.append(ring.move(at: 0))
        }
        #expect(seen == [3, 4, 5, 6])
    }

    @Test
    func `the logical subscript re-anchors after a front move`() {
        var ring = GrowableRing<Int>(minimumCapacity: Index<Int>.Count(4))
        ring.initialize(at: 0, to: 10)
        ring.initialize(at: 1, to: 20)
        ring.initialize(at: 2, to: 30)
        _ = ring.move(at: 0)  // 20 becomes logical 0
        let front = ring[0]
        #expect(front == 20)
        ring[1] = 33  // logical write through the wrap math
        let e1 = ring[1]
        #expect(e1 == 33)
        let n = ring.count
        #expect(n == Index<Int>.Count(2))
    }

    @Test
    func `back moves retreat the tail without touching the head`() {
        var ring = GrowableRing<Int>(minimumCapacity: Index<Int>.Count(3))
        ring.initialize(at: 0, to: 1)
        ring.initialize(at: 1, to: 2)
        ring.initialize(at: 2, to: 3)
        let back = ring.move(at: 2)
        #expect(back == 3)
        let front = ring[0]
        #expect(front == 1)
        let n = ring.count
        #expect(n == Index<Int>.Count(2))
    }

    @Test
    func `the bounded ring rides the same seam discipline`() {
        var ring = BoundedRing<Int>(minimumCapacity: Index<Int>.Count(3))
        ring.initialize(at: 0, to: 7)
        ring.initialize(at: 1, to: 8)
        _ = ring.move(at: 0)  // head advances
        ring.initialize(at: 1, to: 9)  // back-append into the freed slot's wrap
        var seen: [Int] = []
        while !ring.isEmpty {
            seen.append(ring.move(at: 0))
        }
        #expect(seen == [8, 9])
    }
}

// MARK: - The ledger sync drives the storage oracle on WRAPPED layouts

@Suite(.serialized)
struct RingSeamTeardownTests {

    @Test
    func `dropping a WRAPPED ring destroys exactly the live elements`() {
        SeamProbe.reset()
        do {
            var ring = GrowableRing<SeamItem>(minimumCapacity: Index<SeamItem>.Count(4))
            ring.initialize(at: Index<SeamItem>(Ordinal(UInt(0))), to: SeamItem(1))
            ring.initialize(at: Index<SeamItem>(Ordinal(UInt(1))), to: SeamItem(2))
            ring.initialize(at: Index<SeamItem>(Ordinal(UInt(2))), to: SeamItem(3))
            ring.initialize(at: Index<SeamItem>(Ordinal(UInt(3))), to: SeamItem(4))
            _ = ring.move(at: Index<SeamItem>(Ordinal(UInt(0))))  // destroy 1
            _ = ring.move(at: Index<SeamItem>(Ordinal(UInt(0))))  // destroy 2
            ring.initialize(at: Index<SeamItem>(Ordinal(UInt(2))), to: SeamItem(5))  // wraps
            ring.initialize(at: Index<SeamItem>(Ordinal(UInt(3))), to: SeamItem(6))  // two-run
            let mid = SeamProbe.destroyedSorted
            #expect(mid == [1, 2])
        }
        let all = SeamProbe.destroyedSorted
        #expect(all == [1, 2, 3, 4, 5, 6])  // the oracle walked BOTH runs
    }
}

private struct SeamItem: ~Copyable {
    let id: Int
    init(_ id: Int) { self.id = id }
    deinit { SeamProbe.recordDestroy(id) }
}

/// Per-suite recorder (the deterministic-gate rule: cross-suite parallelism races a
/// shared recorder).
private enum SeamProbe {
    nonisolated(unsafe) static var _destroyed: [Int] = []
    static func reset() { unsafe _destroyed = [] }
    static func recordDestroy(_ id: Int) { unsafe _destroyed.append(id) }
    static var destroyedSorted: [Int] { unsafe _destroyed.sorted() }
}

// MARK: - clone (the Shared strategy): linearizing deep copy, wrapped-state-correct

@Suite
struct RingCloneTests {

    @Test
    func `cloning a WRAPPED ring preserves logical order and detaches storage`() {
        var ring = GrowableRing<Int>(minimumCapacity: Index<Int>.Count(4))
        ring.initialize(at: 0, to: 1)
        ring.initialize(at: 1, to: 2)
        ring.initialize(at: 2, to: 3)
        ring.initialize(at: 3, to: 4)
        _ = ring.move(at: 0)
        _ = ring.move(at: 0)
        ring.initialize(at: 2, to: 5)  // wrapped: live = [3, 4, 5]
        var copy = ring.clone()
        let copyCount = copy.count
        #expect(copyCount == Index<Int>.Count(3))
        copy[0] = 300  // mutate the copy only
        let mine = ring[0]
        let theirs = copy[0]
        #expect(mine == 3)
        #expect(theirs == 300)
        var seen: [Int] = []
        while !copy.isEmpty {
            seen.append(copy.move(at: 0))
        }
        #expect(seen == [300, 4, 5])  // logical order preserved through the wrap
    }

    @Test
    func `cloning a bounded ring preserves the fixed capacity`() {
        var ring = BoundedRing<Int>(minimumCapacity: Index<Int>.Count(3))
        ring.initialize(at: 0, to: 7)
        ring.initialize(at: 1, to: 8)
        let copy = ring.clone()
        let cap = copy.capacity
        let n = copy.count
        #expect(cap == ring.capacity)
        #expect(n == Index<Int>.Count(2))
        let front = copy[0]
        #expect(front == 7)
    }
}
