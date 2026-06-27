import Affine_Primitives_Standard_Library_Integration
public import Iterable
import Ordinal_Primitives_Standard_Library_Integration
public import Span_Protocol_Primitives
public import Store_Protocol_Primitives

// MARK: - Buffer.Ring.Scalar — hand-written scalar Sequenceable iterator
//
// The single-pass (consuming) iterator for the `Sequenceable` conformance. It is
// a CONCRETE, LOCAL witness — deliberately NOT the generic `Memory.Cursor`
// bridge, whose generic `Sequenceable` witness demangle-crashes at runtime
// (Signal-6 `swift_getAssociatedTypeWitness`; see the deferred
// `/issue-investigation` of the demangle). A concrete per-variant scalar iterator
// avoids that witness entirely (modeled on the buffer-slab `d6fcf5b` +
// buffer-linear `dd9b8c2` scalar-iterator precedents, which build + run green for
// generic conformers).
//
// `Sequenceable.makeIterator()` is `consuming`, so the iterator OWNS the consumed
// ring and re-derives access inside each `next()` through the ring's logical
// subscript (which maps logical → physical across the two segments). Owning a
// `~Copyable` `Buffer.Ring` makes the iterator itself `~Copyable`;
// `Iterator.`Protocol`` admits `~Copyable` iterators. `Element: Copyable & Escapable`
// lets `next()` copy the element out and return it past the iterator, so NO
// `@_lifetime` annotation is used (an Escapable result rejects `@_lifetime`).
//
// The bulk `Iterable` side keeps the hand-written 2-segment `Buffer.Ring.Chunk`;
// the two distinct `Iterator` associated types are bound with the
// `@_implements(Iterable, Iterator)` / `@_implements(Sequenceable, Iterator)` split
// in `Buffer.Ring+Sequence.Protocol.swift`.

extension Buffer.Ring where S: Span.`Protocol`, S: ~Copyable, S.Element: Copyable {
    /// Scalar single-pass iterator over an owned ring buffer.
    ///
    /// Vended by the `Sequenceable` `consuming makeIterator()`. Owns the consumed
    /// buffer and yields its elements one at a time, in logical (front-to-back)
    /// order, reading through the storage's `Span.`Protocol`` span at the
    /// modular-mapped physical slot (the (b′) generic-substrate re-expression of
    /// the former Heap-only logical subscript).
    public struct Scalar: Iterator_Primitive.Iterator.`Protocol`, ~Copyable {
        @usableFromInline
        var base: Buffer<S>.Ring

        @usableFromInline
        var position: Index<S.Element>

        @inlinable
        package init(_ base: consuming Buffer<S>.Ring) {
            self.base = base
            self.position = .zero
        }
    }
}

extension Buffer.Ring.Scalar where S: Span.`Protocol`, S: ~Copyable, S.Element: Copyable {
    /// The iteration never fails: `next()` is non-throwing.
    public typealias Failure = Never

    /// Advances the iterator and returns the next element, or `nil` if exhausted.
    @inlinable
    public mutating func next() -> S.Element? {
        let end = base.count.map(Ordinal.init)
        guard position < end else { return nil }
        defer { position += .one }
        let physical = Buffer.Ring.physicalSlot(forLogical: position, header: base._header)
        // Read through the storage's per-slot subscript (the full-allocation
        // element-store surface), NOT `span`: a wrapped ring (`.two` init state,
        // head > 0, count < capacity) places front-segment physical slots in
        // `[count, capacity)`, which the count-bounded `span` (length = storage
        // count) does not cover — indexing it traps "Index out of bounds". The
        // slot subscript addresses any physical slot in `[0, capacity)`, matching
        // `Buffer.Ring.subscript` / `Buffer.Ring.forEach`.
        return base._storage[physical]
    }
}
