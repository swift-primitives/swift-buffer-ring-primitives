extension Buffer.Ring.Bounded where S: ~Copyable {
    /// Tag type for `.peek` property extensions.
    public enum Peek {}
}

extension Buffer.Ring.Bounded.Peek where S: ~Copyable {
    /// The typed borrowing accessor view that `peek` yields, projecting `peek.front` and `peek.back`.
    public typealias View = Property<Buffer<S>.Ring.Peek, Buffer<S>.Ring.Bounded>.Borrow.Typed<S.Element>
}
