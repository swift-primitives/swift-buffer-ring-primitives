extension Buffer.Ring.Bounded where S: ~Copyable {
    /// Tag type for `.push` property extensions.
    public enum Push {}
}

extension Buffer.Ring.Bounded.Push where S: ~Copyable {
    /// The typed inout accessor view that `push` yields, projecting `push.back(_:)` and `push.front(_:)`.
    public typealias View = Property<Buffer<S>.Ring.Push, Buffer<S>.Ring.Bounded>.Inout.Typed<S.Element>
}

// MARK: - Push Operations (~Copyable)

extension Property.Inout.Typed
where
    Tag == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Element>>.Ring.Push,
    Base == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Element>>.Ring.Bounded,
    Element: ~Copyable
{
    /// Pushes an element to the back.
    ///
    /// Returns the rejected element if the buffer is already at its capacity ceiling.
    @inlinable
    @discardableResult
    public mutating func back(_ element: consuming Element) -> Element? {
        base.value._pushBack(consume element)
    }

    /// Pushes an element to the front.
    ///
    /// Returns the rejected element if the buffer is already at its capacity ceiling.
    @inlinable
    @discardableResult
    public mutating func front(_ element: consuming Element) -> Element? {
        base.value._pushFront(consume element)
    }
}
