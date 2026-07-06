import Buffer_Ring_Primitives
import Memory_Allocator_Primitive
import Memory_Small_Primitives
import Storage_Contiguous_Primitives
import Testing

// MARK: - W3.1 `.Small` compile-coverage probe
//
// Verifies a `Memory.Small<n>`-leaf ring column typechecks AND runs through the
// [DS-029]-generalized ops: construction (FORM-2), enqueue past the inline budget
// (FORM-2 — grows via `S.create`, re-running the inline→heap spill decision), and
// drain (FORM-1 — `popFront` / the consuming `.drain` over the ledgered seam).
//
// This is the exact column W3.2's `Queue<E>.Small<n>` / `Queue<E>.DoubleEnded.Small<n>`
// front doors will consume: the door is a constrained alias; this probe proves the
// generalized ops resolve and behave on the `Memory.Small` growable leaf. Memory.Small
// is `Memory.Growable`, so form-2 applies; a `Memory.Inline` leaf would (correctly)
// not satisfy the growth-op fence.

@Suite("Buffer.Ring .Small coverage")
struct RingSmallCoverageTests {
    // `Memory.Small`'s n is a BYTE budget: 64 bytes ≈ 8 `Int`s inline before spilling.
    typealias SmallColumn = Storage<Memory.Allocator<Memory.Small<64>>>.Contiguous<Int>
}

extension RingSmallCoverageTests {

    @Test
    func `construct + enqueue (form-2, inline→heap spill) + drain via popFront (form-1)`() {
        // FORM-2 construction on the growable Small leaf.
        var ring = Buffer<SmallColumn>.Ring(minimumCapacity: 4)

        // FORM-2 enqueue: push 16 `Int`s (128 bytes) past the 64-byte inline budget,
        // forcing at least one inline→heap spill during growth.
        for value in 1 ... 16 {
            ring.pushBack(value)
        }
        #expect(ring.count == 16)

        // FORM-1 drain via popFront over the ledgered seam — FIFO order preserved
        // across the spill boundary.
        var expected = 1
        while ring.count > .zero {
            let element = ring.popFront()
            #expect(element == expected)
            expected += 1
        }
        #expect(expected == 17)
    }

    @Test
    func `consuming .drain (form-1) over Memory.Small<64>`() {
        var ring = Buffer<SmallColumn>.Ring(minimumCapacity: 2)
        ring.pushBack(100)
        ring.pushBack(200)
        ring.pushBack(300)
        #expect(ring.count == 3)

        // FORM-1 consuming drain — the generic `Sequence.Drain` surface the door reuses.
        var seen: [Int] = []
        ring.drain { seen.append($0) }
        #expect(seen == [100, 200, 300])
        #expect(ring.count == .zero)
    }

    @Test
    func `static seam ops (form-1) over a Memory.Small<64> substrate`() {
        let capacity: Index<Int>.Count = 8
        var header = Buffer<SmallColumn>.Ring.Header(capacity: capacity)
        var storage = SmallColumn.create(minimumCapacity: capacity)

        // FORM-1 static element ops resolve on the Small substrate (same seam as heap).
        Buffer<SmallColumn>.Ring.pushBack(1, header: &header, storage: &storage)
        Buffer<SmallColumn>.Ring.pushBack(2, header: &header, storage: &storage)
        #expect(header.count == 2)

        let first = Buffer<SmallColumn>.Ring.popFront(header: &header, storage: &storage)
        #expect(first == 1)

        Buffer<SmallColumn>.Ring.deinitializeAll(header: &header, storage: &storage)
        let headerIsEmpty = header.isEmpty
        #expect(headerIsEmpty)

        storage.initialization = .empty
    }
}
