extension Buffer.Ring where S: ~Copyable {
    /// Tag type for `.pop` property extensions.
    public enum Pop {}
}

extension Buffer.Ring.Pop where S: ~Copyable {
    /// The typed inout accessor view that `pop` yields, projecting `pop.front()` and `pop.back()`.
    public typealias View = Property<Buffer<S>.Ring.Pop, Buffer<S>.Ring>.Inout.Typed<S.Element>
}

// MARK: - Pop Operations (~Copyable)

extension Property.Inout.Typed
where
    Tag == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Element>>.Ring.Pop,
    Base == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Element>>.Ring,
    Element: ~Copyable
{
    /// Removes and returns the element at the front of the ring.
    ///
    /// - Precondition: The buffer is not empty.
    /// - Complexity: O(1)
    @inlinable
    public mutating func front() -> Element {
        base.value._popFront()
    }

    /// Removes and returns the element at the back of the ring.
    ///
    /// - Precondition: The buffer is not empty.
    /// - Complexity: O(1)
    @inlinable
    public mutating func back() -> Element {
        base.value._popBack()
    }
}
