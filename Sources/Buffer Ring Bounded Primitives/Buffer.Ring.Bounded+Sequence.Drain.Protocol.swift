public import Sequence_Primitives

// MARK: - Sequence.Drain.Protocol / removeAll() / .drain accessor
//
// Drain conformance + concrete clearing method isolated in the Bounded ops
// module per [MOD-004]; cold. Drain delegates to the type module's `_drain`
// package window.

extension Buffer.Ring.Bounded: Sequence.Drain.`Protocol` where S: ~Copyable {
    /// Consumes every element in FIFO (front-to-back) order, passing each to `body`.
    @inlinable
    public mutating func drain(_ body: (consuming S.Element) -> Void) {
        _drain(body)
    }
}

// MARK: - Property.Inout (.drain)

extension Buffer.Ring.Bounded where S: ~Copyable {
    /// The drain accessor, projecting the consuming `drain(_:)` operation.
    @inlinable
    public var drain: Property<Sequence.Drain, Self>.Inout {
        mutating _read {
            yield Property<Sequence.Drain, Self>.Inout(&self)
        }
        mutating _modify {
            var accessor = Property<Sequence.Drain, Self>.Inout(&self)
            yield &accessor
        }
    }
}
