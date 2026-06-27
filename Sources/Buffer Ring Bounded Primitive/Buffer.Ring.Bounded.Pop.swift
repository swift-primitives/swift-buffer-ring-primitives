extension Buffer.Ring.Bounded where S: ~Copyable {
    /// Tag type for `.pop` property extensions.
    public enum Pop {}
}

extension Buffer.Ring.Bounded.Pop where S: ~Copyable {
    /// The typed inout accessor view that `pop` yields, projecting `pop.front()` and `pop.back()`.
    public typealias View = Property<Buffer<S>.Ring.Pop, Buffer<S>.Ring.Bounded>.Inout.Typed<S.Element>
}

// MARK: - Pop Operations (~Copyable)

extension Property.Inout.Typed
where
    Tag == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Element>>.Ring.Pop,
    Base == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Element>>.Ring.Bounded,
    Element: ~Copyable
{
    /// Removes and returns the element at the front.
    ///
    /// - Precondition: The buffer is not empty.
    @inlinable
    public mutating func front() -> Element {
        base.value._popFront()
    }

    /// Removes and returns the element at the back.
    ///
    /// - Precondition: The buffer is not empty.
    @inlinable
    public mutating func back() -> Element {
        base.value._popBack()
    }
}
