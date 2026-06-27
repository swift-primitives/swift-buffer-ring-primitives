import Affine_Primitives_Standard_Library_Integration
import Index_Primitives
import Ordinal_Primitives_Standard_Library_Integration
public import Storage_Protocol_Primitives
public import Store_Protocol_Primitives

extension Buffer where S: Store.`Protocol`, S: ~Copyable {
    // MARK: - Ring

    /// A growable ring buffer backed by heap storage.
    ///
    /// Provides double-ended push/pop operations with automatic capacity growth.
    /// Delegates all element manipulation to `Buffer.Ring` static operations
    /// defined in the `Buffer Ring Primitives` module.
    ///
    /// The storage's seam ops self-maintain its initialization ledger, so the backing's own
    /// deinit oracle handles cleanup automatically.
    @frozen
    public struct Ring: ~Copyable {

        // MARK: - Ring Fields

        // [MOD-036]: storage internals are `@usableFromInline internal` so the hot
        // ~Copyable surface co-located in this type module inlines cross-package.
        // Cold conformances + the Small satellite reach these through `package`
        // windows (see Buffer.Ring+ConformanceSupport.swift). The init stays
        // `package` so the Small satellite's spill path can construct a heap Ring.
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

/// Sendable conformance for `Buffer.Ring`.
///
/// ## Safety Invariant
///
/// `Buffer.Ring` is `~Copyable` and owns heap-backed ring storage. Single
/// ownership enforced; cross-thread transfer is a move.
///
/// ## Intended Use
///
/// - Transferring a ring buffer to a worker thread.
///
/// ## Non-Goals
///
/// - Not a shared concurrent ring buffer.
extension Buffer.Ring: @unsafe @unchecked Sendable where S: Store.`Protocol` & ~Copyable & Sendable {}
