import Affine_Primitives_Standard_Library_Integration
import Index_Primitives
public import Memory_Allocator_Primitive
public import Memory_Heap_Primitives
import Ordinal_Primitives_Standard_Library_Integration
public import Storage_Contiguous_Primitives
public import Storage_Primitive

// MARK: - Extensions for Ring

extension Buffer.Ring where S: ~Copyable {

    /// Creates a growable ring buffer with at least the given capacity.
    ///
    /// The actual capacity may be larger than requested per H6 —
    /// `header.capacity` is set from `storage.capacity`.
    @inlinable
    public init<E: ~Copyable>(minimumCapacity: Index<E>.Count)
    where S == Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E> {
        let storage = S.create(minimumCapacity: minimumCapacity)
        self.init(
            header: Self.Header(capacity: storage.capacity),
            storage: storage
        )
    }

    /// Creates an empty growable ring buffer (the substrate decides the start capacity).
    @inlinable
    public init<E: ~Copyable>()
    where S == Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E> {
        self.init(minimumCapacity: Index<E>.Count.zero)
    }

    /// The number of elements in the buffer.
    @inlinable
    public var count: Index<S.Element>.Count { header.count }

    /// The total slot capacity.
    @inlinable
    public var capacity: Index<S.Element>.Count { header.capacity }

    /// Whether the buffer is at capacity.
    @inlinable
    public var isFull: Bool { header.isFull }

    /// Ensures the buffer can hold at least `minimumCapacity` elements.
    @inlinable
    public mutating func reserveCapacity<E: ~Copyable>(_ minimumCapacity: Index<E>.Count)
    where S == Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E> {
        if minimumCapacity > header.capacity {
            _growTo(minimumCapacity)
        }
    }

    // MARK: - Growth (internal)

    @inlinable
    mutating func _grow<E: ~Copyable>()
    where S == Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E> {
        if header.capacity == .zero {
            _growTo(.one)
        } else {
            _growTo(header.capacity * 2)
        }
    }

    @inlinable
    mutating func _growTo<E: ~Copyable>(_ minimumCapacity: Index<E>.Count)
    where S == Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E> {
        var newStorage = S.create(minimumCapacity: minimumCapacity)
        // Read the new capacity before `newStorage` is consumed by the
        // assignment below — the substrate is `~Copyable`, so `storage = newStorage`
        // moves it and any later `newStorage.capacity` would be a use-after-consume.
        let newCapacity = newStorage.capacity
        let oldCount = header.count
        // Relocate into LINEARIZED order element-wise via the seam: each occupied physical run
        // (one or two — the wrapped ring) moves to its linear destination. The seam's per-op
        // ledger updates are prefix-shaped (its docstring routes arbitrary-slot disciplines
        // through explicit `initialization` syncs), so both ledgers are settled below: the old
        // ledger's count reaches zero through the moves (the dropped backing's oracle destroys
        // nothing), and the new storage ends `.linear(oldCount)` — re-synced from the rebuilt
        // header, the ring's sync invariant.
        header.initialization.linearize { range, offset in
            var src = range.lowerBound
            var dst = offset
            while src < range.upperBound {
                newStorage.initialize(at: dst, to: storage.move(at: src))
                src += .one
                dst += .one
            }
        }
        storage = newStorage
        header = Self.Header(capacity: newCapacity)
        header.count = oldCount
        // head is 0 after linearization
        storage.initialization = header.initialization
    }

    /// Reduces capacity to match the current count, releasing unused memory.
    ///
    /// After calling this method, `capacity == count`. The ring buffer is
    /// linearized during compaction.
    ///
    /// - Complexity: O(n) where n is the number of elements.
    @inlinable
    public mutating func compact<E: ~Copyable>() where S == Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E> {
        guard header.count < header.capacity else { return }
        if header.isEmpty {
            storage = Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>.create(minimumCapacity: .zero)
            header = .init(capacity: storage.capacity)
            return
        }
        _growTo(header.count)
    }
}

// MARK: - Internal Mutations

extension Buffer.Ring where S: ~Copyable {

    @usableFromInline
    mutating func _pushBack<E: ~Copyable>(_ element: consuming E)
    where S == Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E> {
        if header.isFull { _grow() }
        Self.pushBack(consume element, header: &header, storage: &storage)
    }

    @usableFromInline
    mutating func _popFront<E: ~Copyable>() -> E
    where S == Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E> {
        Self.popFront(header: &header, storage: &storage)
    }

    @usableFromInline
    mutating func _pushFront<E: ~Copyable>(_ element: consuming E)
    where S == Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E> {
        if header.isFull { _grow() }
        Self.pushFront(consume element, header: &header, storage: &storage)
    }

    @usableFromInline
    mutating func _popBack<E: ~Copyable>() -> E
    where S == Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E> {
        Self.popBack(header: &header, storage: &storage)
    }

    @usableFromInline
    mutating func _removeAll<E: ~Copyable>()
    where S == Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E> {
        Self.deinitializeAll(header: &header, storage: &storage)
    }

    // MARK: - Direct push/pop/remove (storage-generic; the `.push`/`.pop`/`.remove`
    // Property-view ops stay heap-pinned — generalizing a Property.Inout.Typed extension
    // over an arbitrary storage S hits the value-generic same-type wall. #12a.

    /// Pushes an element to the back of the ring (grows if full).
    @inlinable
    public mutating func pushBack<E: ~Copyable>(_ element: consuming E)
    where S == Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E> {
        _pushBack(consume element)
    }

    /// Pushes an element to the front of the ring (grows if full).
    @inlinable
    public mutating func pushFront<E: ~Copyable>(_ element: consuming E)
    where S == Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E> {
        _pushFront(consume element)
    }

    /// Removes and returns the front element.
    ///
    /// - Precondition: The buffer is not empty.
    @inlinable
    public mutating func popFront<E: ~Copyable>() -> E
    where S == Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E> {
        _popFront()
    }

    /// Removes and returns the back element.
    ///
    /// - Precondition: The buffer is not empty.
    @inlinable
    public mutating func popBack<E: ~Copyable>() -> E
    where S == Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E> {
        _popBack()
    }

    /// Removes all elements.
    @inlinable
    public mutating func removeAll<E: ~Copyable>()
    where S == Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E> {
        _removeAll()
    }
}

// MARK: - Property.Inout.Typed (.push, .pop, .peek, .remove)

extension Buffer.Ring where S: ~Copyable {
    /// Namespaced push operations.
    ///
    /// - `buffer.push.back(element)` — pushes to the back.
    /// - `buffer.push.front(element)` — pushes to the front.
    @inlinable
    public var push: Push.View {
        mutating _read {
            yield.init(&self)
        }
        mutating _modify {
            var view: Push.View = .init(&self)
            yield &view
        }
    }

    /// Namespaced pop operations.
    ///
    /// - `buffer.pop.front()` — pops from the front.
    /// - `buffer.pop.back()` — pops from the back.
    @inlinable
    public var pop: Pop.View {
        mutating _read {
            yield.init(&self)
        }
        mutating _modify {
            var view: Pop.View = .init(&self)
            yield &view
        }
    }

    /// Namespaced peek operations (read-only).
    ///
    /// - `buffer.peek.front` — peeks at the front element.
    /// - `buffer.peek.back` — peeks at the back element.
    @inlinable
    public var peek: Peek.View {
        _read {
            yield Peek.View(self)
        }
    }

    /// Namespaced remove operations.
    ///
    /// - `buffer.remove.all()` — removes all elements.
    /// - `buffer.remove.all(keepingCapacity:)` — removes all with capacity option.
    @inlinable
    public var remove: Remove.View {
        mutating _read {
            yield.init(&self)
        }
        mutating _modify {
            var view: Remove.View = .init(&self)
            yield &view
        }
    }
}
