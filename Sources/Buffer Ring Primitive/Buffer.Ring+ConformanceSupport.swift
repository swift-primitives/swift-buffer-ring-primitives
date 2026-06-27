import Affine_Primitives_Standard_Library_Integration
import Ordinal_Primitives_Standard_Library_Integration
public import Span_Protocol_Primitives
public import Storage_Contiguous_Primitives

// MARK: - Package windows for cold ops-module conformances (refined-C, [MOD-031]/[MOD-036])
//
// The storage internals of `Buffer.Ring` and `Buffer.Ring.Inline` are
// `@usableFromInline internal` so the hot ~Copyable surface in this (type)
// module inlines cross-package to zero-witness-dispatch. The cold
// Sequence / Sequence.Drain conformances live in the
// `Buffer Ring Primitives` (base) and `Buffer Ring Inline Primitives` (Inline)
// ops modules (isolated per [MOD-004]) and reach the internals ONLY through the
// `package` windows below.
//
// These are deliberately:
//   - NOT public — encapsulation preserved (NOT Option A); and
//   - NOT @usableFromInline internal — the ops modules are *different* modules
//     and could not see an `internal` symbol by source name.
// `package` is the minimal level that lets the ops modules reference them. The
// conformances that use them are cold, so forgoing *their* cross-package
// inlining is the accepted trade-off; the hot surface is unaffected.

extension Buffer.Ring where S: ~Copyable {

    /// The ring header (head + count + capacity).
    ///
    /// Package window for the cold `Sequence` conformance.
    @usableFromInline
    package var _header: Header { header }

    /// The backing heap storage.
    ///
    /// Package window for the cold conformances that need a base pointer (`Sequence`).
    ///
    /// Yields via a `_read` coroutine (rather than returning by value) because
    /// `Storage<Memory.Allocator<Memory.Heap>>.Contiguous<S.Element>` is `~Copyable` and cannot be returned by value
    /// from a borrowing getter (the prior class-backed storage returned a shared
    /// reference). Callers borrow it for the access scope.
    @usableFromInline
    package var _storage: S {
        _read { yield storage }
    }

    /// Consuming drain in initialized (FIFO) order.
    ///
    /// Package window for the `Sequence.Drain.Protocol` conformance in the base ops module.
    ///
    /// Seam-generic: each `move(at:)` keeps the ledger COUNT accurate (its shape is
    /// prefix-normalized mid-loop, which is only observable on a trap — the body is
    /// non-throwing, so the loop has no recoverable mid-drain exit); on completion the
    /// ledger is empty and the header is reset.
    @usableFromInline
    package mutating func _drain(_ body: (consuming S.Element) -> Void) {
        while !header.isEmpty {
            let element = storage.move(at: header.head)
            header.head = Index.Modular.successor(of: header.head, capacity: header.capacity)
            header.count = header.count.subtract.saturating(.one)
            body(element)
        }
        header.head = .zero
    }
}

// MARK: - Span window (package)

extension Buffer.Ring where S: Span.`Protocol`, S: ~Copyable {
    /// Package window: the storage's count-bounded span, re-anchored through STRUCT containment
    /// (`storage` is a stored property here, so its borrow is part of the borrow of `self`; a
    /// returning span cannot exit the `_storage` coroutine window's yield scope).
    ///
    /// NOT public — the count-bounded span under-covers a WRAPPED ring ([MEM-SPAN-004]); the ops modules'
    /// iterators consume it segment-wise via the ledger ranges (the shipping contract: the old
    /// heap span documented `.two` access as out of contract too).
    @inlinable
    @_lifetime(borrow self)
    package borrowing func _span() -> Swift.Span<S.Element> {
        storage.span
    }
}
