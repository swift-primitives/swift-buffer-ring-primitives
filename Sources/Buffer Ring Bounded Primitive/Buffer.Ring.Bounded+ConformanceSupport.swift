import Affine_Primitives_Standard_Library_Integration
import Ordinal_Primitives_Standard_Library_Integration
public import Span_Protocol_Primitives
public import Storage_Contiguous_Primitives

// MARK: - Package windows for cold ops-module conformances (refined-C, [MOD-031]/[MOD-036])
//
// Mirror of `Buffer.Ring+ConformanceSupport.swift`: Bounded's storage internals
// are `@usableFromInline internal`, so the cold `Sequence`
// conformance in `Buffer Ring Bounded Primitives` (isolated per [MOD-004])
// reach them only through these `package` windows. Not public (NOT Option A);
// not `@usableFromInline internal` (the ops module could not see an `internal`
// symbol). The conformances are cold, so forgoing their cross-package inlining
// is the accepted trade-off; the hot surface is unaffected.

extension Buffer.Ring.Bounded where S: ~Copyable {

    /// The ring header (head + count + capacity).
    ///
    /// Package window for the cold `Sequence` conformance.
    @usableFromInline
    package var _header: Buffer.Ring.Header { header }

    /// The backing heap storage.
    ///
    /// Package window for the cold conformances that need a base pointer (`Sequence`).
    ///
    /// Yields via a `_read` coroutine (rather than returning by value) because
    /// `Storage<Memory.Allocator<Memory.Heap>>.Contiguous<S.Element>` is `~Copyable` and cannot be returned by value
    /// from a borrowing getter. Callers borrow it for the access scope.
    @usableFromInline
    package var _storage: S {
        _read { yield storage }
    }

    /// Consuming drain in FIFO order.
    ///
    /// Package window for the `Sequence.Drain.Protocol` conformance in the Bounded ops module.
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

extension Buffer.Ring.Bounded where S: Span.`Protocol`, S: ~Copyable {
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
