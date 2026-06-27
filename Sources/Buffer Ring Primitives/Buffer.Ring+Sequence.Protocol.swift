public import Sequence_Primitives
public import Span_Protocol_Primitives

// MARK: - Sequenceable for Buffer.Ring (single-pass, consuming)
//
// Satisfied by the HAND-WRITTEN scalar iterator (`Buffer.Ring.Scalar`), NOT the generic
// `Memory.Cursor` bridge — the generic witness demangle-crashes at runtime (Signal-6
// `swift_getAssociatedTypeWitness`; see the deferred `/issue-investigation`). The
// concrete per-variant scalar iterator is a local witness that avoids that demangle
// (modeled on buffer-slab `d6fcf5b` + buffer-linear `dd9b8c2`).
//
// The multipass `Iterable` side (the 2-segment `Buffer.Ring.Segments` bulk iterator)
// was ACTIVE-PRUNED at the ADT-families ring-seam commit (seat-ruled, 2026-06-10): its
// conformance was gated `S: Copyable`, and the reshaped storage tier is unconditionally
// `~Copyable` — the bound had become unsatisfiable (vacuous surface, R1). A live
// multipass story for the ring re-materializes if/when a borrowing segment iterator is
// designed against the move-only substrate.
extension Buffer.Ring: Sequenceable where S: Span.`Protocol`, S: ~Copyable, S.Element: Copyable {
    /// The single-pass iterator type vended by `makeIterator()`.
    public typealias Iterator = Buffer<S>.Ring.Scalar

    /// Consumes the ring and returns a single-pass iterator over its elements in front-to-back order.
    @inlinable
    public consuming func makeIterator() -> Buffer<S>.Ring.Scalar {
        Buffer<S>.Ring.Scalar(self)
    }
}
