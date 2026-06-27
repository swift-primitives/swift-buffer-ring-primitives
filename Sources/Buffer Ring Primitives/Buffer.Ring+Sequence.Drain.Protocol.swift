public import Sequence_Primitives
public import Span_Protocol_Primitives

// MARK: - Sequence.Drain.Protocol / removeAll() / .drain accessor
//
// Drain conformance + concrete clearing method isolated in the base ops module
// per [MOD-004]; cold. Drain delegates to the type module's `_drain` package
// window.

extension Buffer.Ring: Sequence.Drain.`Protocol` where S: ~Copyable {
    /// Consumes every element in FIFO (front-to-back) order, passing each to `body`.
    @inlinable
    public mutating func drain(_ body: (consuming S.Element) -> Void) {
        _drain(body)
    }
}

extension Buffer.Ring where S: Span.`Protocol`, S: ~Copyable, S.Element: Copyable {
    /// Removes every element, deinitializing each and resetting the cursor.
    @inlinable
    public mutating func removeAll() {
        // `remove.all()` is Heap-pinned (needs `S == Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>`); the
        // generic clear is the consuming drain-and-discard, which deinitializes
        // every element and resets the cursor via the lifted `initialization` sync.
        _drain { _ in }
    }
}

// MARK: - Property.Inout (.drain)

extension Buffer.Ring where S: ~Copyable {
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
