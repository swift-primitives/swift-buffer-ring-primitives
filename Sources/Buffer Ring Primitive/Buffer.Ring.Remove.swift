extension Buffer.Ring where S: ~Copyable {
    /// Tag type for `.remove` property extensions.
    public enum Remove {}
}

extension Buffer.Ring.Remove where S: ~Copyable {
    /// The typed inout accessor view that `remove` yields, projecting `remove.all()`.
    public typealias View = Property<Buffer<S>.Ring.Remove, Buffer<S>.Ring>.Inout.Typed<S.Element>
}

// MARK: - Remove Operations (~Copyable)

extension Property.Inout.Typed
where
    Tag == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Element>>.Ring.Remove,
    Base == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Element>>.Ring,
    Element: ~Copyable
{
    /// Removes all elements from the buffer.
    ///
    /// - Complexity: O(n) where n is the number of elements.
    @inlinable
    public mutating func all() {
        base.value._removeAll()
    }
}
