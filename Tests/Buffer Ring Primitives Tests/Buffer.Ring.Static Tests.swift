import Buffer_Ring_Primitives
import Buffer_Ring_Primitives_Test_Support
import Memory_Heap_Primitives
import Storage_Contiguous_Primitives
import Testing

@Suite("Buffer.Ring Static Operations")
struct RingStaticTests {
    @Suite struct Unit {}
    @Suite struct EdgeCase {}
}

// MARK: - Unit

extension RingStaticTests.Unit {

    @Test
    func `pushBack/popFront FIFO ordering`() {
        let cap: Index<Int>.Count = 4
        var header = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.Header(capacity: cap)
        var storage = Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>.create(minimumCapacity: cap)

        Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.pushBack(10, header: &header, storage: &storage)
        Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.pushBack(20, header: &header, storage: &storage)
        Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.pushBack(30, header: &header, storage: &storage)

        #expect(header.count == 3)

        let a = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.popFront(header: &header, storage: &storage)
        let b = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.popFront(header: &header, storage: &storage)
        let c = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.popFront(header: &header, storage: &storage)

        #expect(a == 10)
        #expect(b == 20)
        #expect(c == 30)
        let headerIsEmpty = header.isEmpty
        #expect(headerIsEmpty)

        storage.initialization = .empty
    }

    @Test
    func `pushFront/popBack ordering`() {
        let cap: Index<Int>.Count = 4
        var header = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.Header(capacity: cap)
        var storage = Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>.create(minimumCapacity: cap)

        Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.pushFront(10, header: &header, storage: &storage)
        Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.pushFront(20, header: &header, storage: &storage)

        let a = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.popBack(header: &header, storage: &storage)
        let b = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.popBack(header: &header, storage: &storage)

        #expect(a == 10)
        #expect(b == 20)
        let headerIsEmpty = header.isEmpty
        #expect(headerIsEmpty)

        storage.initialization = .empty
    }

    @Test
    func `physicalSlot logical-to-physical mapping`() {
        var header = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.Header(capacity: 8)
        header.head = 5
        header.count = 4

        // Logical 0 → physical 5
        let p0 = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.physicalSlot(forLogical: 0, header: header)
        #expect(p0 == 5)

        // Logical 3 → physical (5+3)%8 = 0
        let p3 = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.physicalSlot(forLogical: 3, header: header)
        #expect(p3 == 0)
    }

    @Test
    func `deinitializeAll clears everything`() {
        let cap: Index<Int>.Count = 4
        var header = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.Header(capacity: cap)
        var storage = Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>.create(minimumCapacity: cap)

        Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.pushBack(1, header: &header, storage: &storage)
        Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.pushBack(2, header: &header, storage: &storage)

        Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.deinitializeAll(header: &header, storage: &storage)

        let headerIsEmpty = header.isEmpty
        #expect(headerIsEmpty)
        #expect(header.head == 0)
    }

    @Test
    func `initialization sync through operations`() {
        let cap: Index<Int>.Count = 4
        var header = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.Header(capacity: cap)
        var storage = Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>.create(minimumCapacity: cap)

        // Start empty
        #expect(header.initialization == .empty)

        // Push one → .one
        Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.pushBack(42, header: &header, storage: &storage)
        switch header.initialization {
        case .one: break
        default: Issue.record("Expected .one")
        }

        // Fill capacity, advance head to force wrap
        Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.pushBack(43, header: &header, storage: &storage)
        Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.pushBack(44, header: &header, storage: &storage)
        _ = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.popFront(header: &header, storage: &storage)
        _ = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.popFront(header: &header, storage: &storage)
        Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.pushBack(45, header: &header, storage: &storage)
        Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.pushBack(46, header: &header, storage: &storage)

        // Should be wrapping → .two
        switch header.initialization {
        case .two: break
        default: Issue.record("Expected .two for wrapped state")
        }

        // Drain all → .empty
        Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.deinitializeAll(header: &header, storage: &storage)
        #expect(header.initialization == .empty)
    }
}

// MARK: - Edge Cases

extension RingStaticTests.EdgeCase {

    @Test
    func `wrap-around correctness`() {
        let cap: Index<Int>.Count = 4
        var header = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.Header(capacity: cap)
        var storage = Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>.create(minimumCapacity: cap)

        // Fill to capacity
        var i = 0
        while i < 4 {
            Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.pushBack(i, header: &header, storage: &storage)
            i += 1
        }
        let headerIsFull = header.isFull
        #expect(headerIsFull)

        // Pop two from front
        _ = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.popFront(header: &header, storage: &storage)
        _ = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.popFront(header: &header, storage: &storage)

        // Push two more — these wrap around
        Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.pushBack(100, header: &header, storage: &storage)
        Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.pushBack(200, header: &header, storage: &storage)

        // Should read: 2, 3, 100, 200
        let a = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.popFront(header: &header, storage: &storage)
        let b = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.popFront(header: &header, storage: &storage)
        let c = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.popFront(header: &header, storage: &storage)
        let d = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.popFront(header: &header, storage: &storage)

        #expect(a == 2)
        #expect(b == 3)
        #expect(c == 100)
        #expect(d == 200)

        storage.initialization = .empty
    }

    @Test
    func `pushBack and popFront on single-slot storage`() {
        let cap: Index<Int>.Count = 1
        var header = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.Header(capacity: cap)
        var storage = Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>.create(minimumCapacity: cap)

        Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.pushBack(42, header: &header, storage: &storage)
        let headerIsFull = header.isFull
        #expect(headerIsFull)
        let v = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.popFront(header: &header, storage: &storage)
        #expect(v == 42)
        let headerIsEmpty = header.isEmpty
        #expect(headerIsEmpty)

        storage.initialization = .empty
    }
}
