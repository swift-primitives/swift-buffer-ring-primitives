import Affine_Primitives_Standard_Library_Integration
import Index_Primitives
public import Memory_Allocator_Protocol_Primitives
import Ordinal_Primitives_Standard_Library_Integration
public import Store_Ledgered_Primitives

// MARK: - Extensions for Ring.Bounded (declared in Core)

extension Buffer.Ring.Bounded where S: ~Copyable {

    /// Creates a bounded ring buffer with at least the given capacity (any growable column).
    ///
    /// Actual capacity comes from `storage.capacity` per H6.
    @inlinable
    public init<Element: ~Copyable, Resource: Memory.Growable & ~Copyable>(minimumCapacity: Index<Element>.Count) where S == Storage<Memory.Allocator<Resource>>.Contiguous<Element> {
        let storage = S.create(minimumCapacity: minimumCapacity)
        self.init(
            header: Buffer.Ring.Header(capacity: storage.capacity),
            storage: storage
        )
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
}

// MARK: - Internal Mutations

extension Buffer.Ring.Bounded where S: ~Copyable {

    @usableFromInline
    mutating func _pushBack(_ element: consuming S.Element) -> S.Element? where S: Store.Ledgered.`Protocol` {
        if header.isFull { return element }
        Buffer.Ring.pushBack(consume element, header: &header, storage: &storage)
        return nil
    }

    @usableFromInline
    mutating func _popFront() -> S.Element where S: Store.Ledgered.`Protocol` {
        Buffer.Ring.popFront(header: &header, storage: &storage)
    }

    @usableFromInline
    mutating func _pushFront(_ element: consuming S.Element) -> S.Element? where S: Store.Ledgered.`Protocol` {
        if header.isFull { return element }
        Buffer.Ring.pushFront(consume element, header: &header, storage: &storage)
        return nil
    }

    @usableFromInline
    mutating func _popBack() -> S.Element where S: Store.Ledgered.`Protocol` {
        Buffer.Ring.popBack(header: &header, storage: &storage)
    }

    @usableFromInline
    mutating func _removeAll() where S: Store.Ledgered.`Protocol` {
        Buffer.Ring.deinitializeAll(header: &header, storage: &storage)
    }
}

// MARK: - Property.Inout.Typed (.push, .pop, .peek, .remove)

extension Buffer.Ring.Bounded where S: ~Copyable {
    /// Namespaced push operations.
    ///
    /// - `buffer.push.back(element)` — pushes to the back, returning the element if the ceiling is reached.
    /// - `buffer.push.front(element)` — pushes to the front, returning the element if the ceiling is reached.
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
