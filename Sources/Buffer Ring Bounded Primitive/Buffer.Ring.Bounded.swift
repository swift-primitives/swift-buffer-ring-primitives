import Affine_Primitives_Standard_Library_Integration
import Ordinal_Primitives_Standard_Library_Integration

extension Buffer.Ring where S: ~Copyable {
    // MARK: - Bounded (Fixed-Capacity, Heap-Allocated)

    /// A fixed-capacity ring buffer backed by heap storage.
    ///
    /// Push operations on a full buffer return the rejected element
    /// rather than growing.
    ///
    /// `storage.initialization` is kept in sync with header state (the ring discipline's
    /// arbitrary-slot ledger rule), so the backing's own deinit oracle handles cleanup automatically.
    @frozen
    public struct Bounded: ~Copyable {
        // [MOD-036]: storage internals are `@usableFromInline internal` so the hot
        // ~Copyable surface co-located in this type module inlines cross-package.
        // Bounded has no sibling-variant consumer; the cold conformances in
        // `Buffer Ring Bounded Primitives` reach these through `package` windows.
        @usableFromInline
        var header: Header

        @usableFromInline
        var storage: S

        @inlinable
        package init(header: Header, storage: consuming S) {
            self.header = header
            self.storage = storage
        }
    }
}

/// Sendable conformance for `Buffer.Ring.Bounded`.
///
/// ## Safety Invariant
///
/// `Buffer.Ring.Bounded` is `~Copyable`. Fixed-capacity ring buffer with
/// single-owner semantics.
///
/// ## Intended Use
///
/// - Transferring a bounded ring buffer to a consumer.
///
/// ## Non-Goals
///
/// - Not a shared concurrent ring buffer.
extension Buffer.Ring.Bounded: @unsafe @unchecked Sendable where S: Store.`Protocol` & ~Copyable & Sendable {}
