extension Buffer.Ring where S: ~Copyable {
    /// Tag type for `.push` property extensions.
    public enum Push {}
}

extension Buffer.Ring.Push where S: ~Copyable {
    /// The typed inout accessor view that `push` yields, projecting `push.back(_:)` and `push.front(_:)`.
    public typealias View = Property<Buffer<S>.Ring.Push, Buffer<S>.Ring>.Inout.Typed<S.Element>
}

// MARK: - Push Operations (~Copyable)

extension Property.Inout.Typed
where
    Tag == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Element>>.Ring.Push,
    Base == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Element>>.Ring,
    Element: ~Copyable
{
    /// Pushes an element to the back of the ring.
    ///
    /// Grows the buffer if full.
    /// - Complexity: O(1) amortized
    @inlinable
    public mutating func back(_ element: consuming Element) {
        base.value._pushBack(consume element)
    }

    /// Pushes an element to the front of the ring.
    ///
    /// Grows the buffer if full.
    /// - Complexity: O(1) amortized
    @inlinable
    public mutating func front(_ element: consuming Element) {
        base.value._pushFront(consume element)
    }
}
