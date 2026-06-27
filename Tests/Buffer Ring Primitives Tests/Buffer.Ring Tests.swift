import Buffer_Ring_Primitives
import Buffer_Ring_Primitives_Test_Support
import Memory_Heap_Primitives
import Sequence_Hint_Primitives
import Storage_Contiguous_Primitives
import Testing

// Buffer.Ring is generic, so per [TEST-004] we use the parallel namespace
// pattern — @Suite in extensions of generic type specializations is silently
// not discovered by Swift Testing.

@Suite("Buffer.Ring")
struct RingGrowableTests {
    @Suite struct Unit {}
    @Suite struct EdgeCase {}
    @Suite struct Integration {}
}

// MARK: - Unit

extension RingGrowableTests.Unit {

    @Test
    func `FIFO ordering`() {
        var buffer = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring(minimumCapacity: 4)
        buffer.push.back(10)
        buffer.push.back(20)
        buffer.push.back(30)

        #expect(buffer.count == 3)

        #expect(buffer.pop.front() == 10)
        #expect(buffer.pop.front() == 20)
        #expect(buffer.pop.front() == 30)
        let bufferIsEmpty = buffer.isEmpty
        #expect(bufferIsEmpty)
    }

    @Test
    func `wrap-around behavior`() {
        var buffer = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring(minimumCapacity: 4)

        // Fill exactly to slotCapacity worth of elements
        let cap = buffer.capacity.underlying.rawValue
        var i: UInt = 0
        while i < cap {
            buffer.push.back(Int(i))
            i += 1
        }
        let bufferIsFull = buffer.isFull
        #expect(bufferIsFull)

        // Pop two, push two — forces wrap
        _ = buffer.pop.front()
        _ = buffer.pop.front()
        buffer.push.back(100)
        buffer.push.back(200)

        // Verify FIFO order after wrap
        #expect(buffer.pop.front() == 2)
        #expect(buffer.pop.front() == 3)
    }

    @Test
    func `growth doubles capacity`() {
        var buffer = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring(minimumCapacity: 2)
        let originalCap = buffer.capacity

        // Fill past capacity — triggers growth
        var i = 0
        let needed = Int(originalCap.underlying.rawValue) + 1
        while i < needed {
            buffer.push.back(i * 10)
            i += 1
        }

        #expect(buffer.capacity.underlying.rawValue > originalCap.underlying.rawValue)

        // Verify all elements survived growth in FIFO order
        i = 0
        while i < needed {
            #expect(buffer.pop.front() == i * 10)
            i += 1
        }
    }

    @Test
    func `slotCapacity invariant — capacity from storage, not request`() {
        let buffer = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring(minimumCapacity: 3)
        // slotCapacity may be > 3 (ManagedBuffer rounds up)
        #expect(buffer.capacity.underlying.rawValue >= 3)
    }

    @Test
    func `drain removes all elements in FIFO order`() {
        var buffer = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring([10, 20, 30])
        var drained: [Int] = []
        buffer.drain { drained.append($0) }
        #expect(drained == [10, 20, 30])
        let bufferIsEmpty = buffer.isEmpty
        #expect(bufferIsEmpty)
    }

    @Test
    func `removeAll clears buffer`() {
        var buffer = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring([1, 2, 3])
        buffer.remove.all()
        let bufferIsEmpty = buffer.isEmpty
        #expect(bufferIsEmpty)
        #expect(buffer.count == 0)
    }

    @Test
    func `reserveCapacity grows if needed`() {
        var buffer = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring(minimumCapacity: 2)
        buffer.reserveCapacity(Index<Int>.Count(Cardinal(100)))
        #expect(buffer.capacity.underlying.rawValue >= 100)
    }

    @Test
    func `peekFront and peekBack (Copyable)`() {
        let buffer = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring([10, 20, 30])
        // This function reads ONLY through the peek views: the 6.3.2 lifetime checker
        // false-positives ("lifetime-dependent value escapes its scope") on ~Escapable view
        // reads when the function also reads `buffer` directly (probe-verified; the count
        // coverage lives in the lifecycle tests, and peek is a borrowing read — non-mutation
        // is type-enforced).
        let bufferPeekFront = buffer.peek.front
        #expect(bufferPeekFront == 10)
        let bufferPeekBack = buffer.peek.back
        #expect(bufferPeekBack == 30)
    }

    @Test
    func `pushFront and popBack (deque behavior)`() {
        var buffer = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring(minimumCapacity: 4)
        buffer.push.front(10)
        buffer.push.front(20)

        #expect(buffer.pop.back() == 10)
        #expect(buffer.pop.back() == 20)
    }

    @Test
    func `Iterable iteration (Copyable)`() {
        let buffer = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring([10, 20, 30])
        // Piecewise dual conformer: `: Iterable` (2-segment bulk `Buffer.Ring.Chunk`
        // conforming `Iterator.Chunk.Protocol` directly) and `: Sequenceable`
        // (hand-written scalar `Buffer.Ring.Scalar`). `forEach` is the `Sequenceable`
        // borrowing terminal (non-destructive). Plain `makeIterator()` is ambiguous
        // across the two conformances, so use the terminal.
        var collected: [Int] = []
        buffer.forEach { collected.append($0) }
        #expect(collected == [10, 20, 30])
    }

    @Test
    func `single element`() {
        var buffer = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring(minimumCapacity: 1)
        buffer.push.back(42)
        #expect(buffer.count == 1)
        #expect(buffer.pop.front() == 42)
        let bufferIsEmpty = buffer.isEmpty
        #expect(bufferIsEmpty)
    }

    @Test
    func `withFront borrows first element`() {
        let buffer = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring([10, 20, 30])
        let value = buffer.withFront { $0 }
        #expect(value == 10)
        #expect(buffer.count == 3)
    }

    @Test
    func `withBack borrows last element`() {
        let buffer = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring([10, 20, 30])
        let value = buffer.withBack { $0 }
        #expect(value == 30)
        #expect(buffer.count == 3)
    }

    @Test
    func `forEach visits all elements in FIFO order`() {
        let buffer = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring([10, 20, 30])
        var visited: [Int] = []
        buffer.forEach { visited.append($0) }
        #expect(visited == [10, 20, 30])
    }

    @Test
    func `checkpoint saves current position`() {
        let buffer = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring([10, 20, 30])
        let cp = buffer.checkpoint
        #expect(cp.count == 3)
    }

    @Test
    func `compact reclaims unused capacity`() {
        var buffer = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring(minimumCapacity: 100)
        buffer.push.back(1)
        buffer.push.back(2)
        buffer.compact()
        #expect(buffer.capacity.underlying.rawValue <= 4)
        #expect(buffer.pop.front() == 1)
        #expect(buffer.pop.front() == 2)
    }

    @Test
    func `hint count default`() {
        // Migrated off `Swift.Sequence.underestimatedCount` (removed with the
        // `Swift.Sequence` conformance). The institute replacement is the
        // `Sequenceable` `.hint.count` size-estimate, exposed via a mutating
        // `Property.Inout` accessor (hence `var`). `Buffer.Ring` does not
        // override it, so it returns the protocol default `.zero`.
        var buffer = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring([10, 20, 30])
        #expect(buffer.hint.count == .zero)
    }
}

// MARK: - Edge Cases

extension RingGrowableTests.EdgeCase {

    @Test
    func `empty buffer operations`() {
        let buffer = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring(minimumCapacity: 4)
        let bufferIsEmpty = buffer.isEmpty
        #expect(bufferIsEmpty)
        #expect(buffer.count == 0)
        let bufferIsFull = buffer.isFull
        #expect(!bufferIsFull)
    }

    @Test
    func `pushBack on empty then popFront`() {
        var buffer = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring(minimumCapacity: 4)
        buffer.push.back(42)
        #expect(buffer.pop.front() == 42)
        let bufferIsEmpty = buffer.isEmpty
        #expect(bufferIsEmpty)
    }

    @Test
    func `checkpoint on empty buffer`() {
        let buffer = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring(minimumCapacity: 4)
        let cp = buffer.checkpoint
        #expect(cp.count == 0)
    }

    @Test
    func `reserveCapacity with zero is no-op`() {
        var buffer = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring(minimumCapacity: 4)
        let originalCap = buffer.capacity
        buffer.reserveCapacity(.zero)
        #expect(buffer.capacity == originalCap)
    }

    @Test
    func `compact on already-compact buffer`() {
        var buffer = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring([1, 2, 3, 4])
        buffer.compact()
        // Should not crash; capacity should be >= count
        #expect(buffer.count == 4)
        #expect(buffer.pop.front() == 1)
    }
}

// MARK: - Integration

extension RingGrowableTests.Integration {

    @Test
    func `interleaved push/pop maintains order`() {
        var buffer = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring(minimumCapacity: 4)
        buffer.push.back(1)
        buffer.push.back(2)
        #expect(buffer.pop.front() == 1)
        buffer.push.back(3)
        #expect(buffer.pop.front() == 2)
        #expect(buffer.pop.front() == 3)
        let bufferIsEmpty = buffer.isEmpty
        #expect(bufferIsEmpty)
    }

    @Test
    func `checkpoint restore skips intermediate elements`() {
        var buffer = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring(minimumCapacity: 8)
        buffer.push.back(10)
        buffer.push.back(20)
        let cp = buffer.checkpoint
        buffer.push.back(30)
        buffer.push.back(40)

        buffer.restore(to: cp)
        #expect(buffer.count == 2)
        #expect(buffer.pop.front() == 10)
        #expect(buffer.pop.front() == 20)
        let bufferIsEmpty = buffer.isEmpty
        #expect(bufferIsEmpty)
    }

    @Test
    func `drain then reuse buffer`() {
        var buffer = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring([10, 20, 30])
        buffer.drain { _ in }
        let bufferIsEmpty = buffer.isEmpty
        #expect(bufferIsEmpty)

        buffer.push.back(40)
        buffer.push.back(50)
        #expect(buffer.pop.front() == 40)
        #expect(buffer.pop.front() == 50)
    }

    @Test
    func `multipass re-iterate`() {
        let buffer = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring([1, 2, 3])
        // `forEach` (the borrowing `Sequenceable` terminal) is non-destructive, so
        // the buffer survives and can be re-iterated — the multipass property of the
        // `Iterable` (borrowing) attachable.
        var first: [Int] = []
        buffer.forEach { first.append($0) }

        var collected: [Int] = []
        buffer.forEach { collected.append($0) }
        #expect(first == [1, 2, 3])
        #expect(collected == [1, 2, 3])
    }

    // Regression: the consuming `Sequenceable` scalar (`Buffer.Ring.Scalar`) read
    // elements through the storage's count-bounded `span`, but `physicalSlot`
    // produces capacity-relative slots. Once the ring head has advanced (pop.front)
    // the front-segment physical slots land in `[count, capacity)`, which the
    // count-bounded span did not cover — the scalar trapped "Index out of bounds".
    // Drive the consuming scalar over a wrapped (`.two`) ring and over a head-offset
    // `.one` ring and assert exact FIFO output.

    @Test
    func `consuming scalar over wrapped ring is FIFO`() {
        var buffer = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring(minimumCapacity: 8)
        for i in 0..<8 { buffer.push.back(i) }
        for _ in 0..<5 { _ = buffer.pop.front() }  // head advances to 5
        for i in 100..<104 { buffer.push.back(i) }  // wraps → .two

        var collected: [Int] = []
        buffer.drain { collected.append($0) }
        #expect(collected == [5, 6, 7, 100, 101, 102, 103])
    }

    @Test
    func `consuming scalar with head offset, no wrap, is FIFO`() {
        var buffer = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring(minimumCapacity: 8)
        for i in 0..<4 { buffer.push.back(i) }
        for _ in 0..<2 { _ = buffer.pop.front() }  // head=2, count=2, .one(2..<4)

        var collected: [Int] = []
        buffer.drain { collected.append($0) }
        #expect(collected == [2, 3])
    }
}
