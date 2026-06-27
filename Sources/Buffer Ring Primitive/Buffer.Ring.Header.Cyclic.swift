import Affine_Primitives_Standard_Library_Integration
import Index_Primitives
import Ordinal_Primitives_Standard_Library_Integration

//
//  Buffer.Ring.Header.Cyclic.swift
//  swift-buffer-primitives
//
//  Created by Coen ten Thije Boonkkamp on 04/02/2026.
//

extension Buffer.Ring.Header where S: ~Copyable {
    /// Compile-time capacity ring header using modular arithmetic.
    ///
    /// Uses `Index<S.Element>.Cyclic<capacity>` for the head position, providing
    /// automatic wrap-around via the cyclic group Z/capacityZ. The capacity
    /// is encoded in the type — no stored capacity field needed.
    @frozen
    public struct Cyclic<let capacity: Int>: Copyable, Sendable {
        /// Slot index of the first element (modular, wraps at capacity).
        public var head: Index<S.Element>.Cyclic<capacity>

        /// Number of initialized elements.
        public var count: Index<S.Element>.Count

        /// Creates a header with zero elements.
        @inlinable
        public init() {
            // swift-linter:disable:next unchecked call site
            // REASON: [CONV-001] permitted same-package bottom-out — constructs the
            // zero modular head from the canonical `Ordinal(0)` at the extension-init
            // internals; no .retag()/.map() source exists for a fresh cyclic head.
            self.head = Index<S.Element>.Cyclic<capacity>(__unchecked: Ordinal(0))
            self.count = .zero
        }
    }
}

extension Buffer.Ring.Header.Cyclic where S: ~Copyable {
    /// Whether the buffer has no elements.
    @inlinable
    public var isEmpty: Bool { count == .zero }

    /// Whether the buffer is at capacity.
    @inlinable
    public var isFull: Bool { count == Self.slotCapacity }

    /// The total slot capacity as `Index<S.Element>.Count` (compile-time constant).
    @inlinable
    public static var slotCapacity: Index<S.Element>.Count {
        Index<S.Element>.Count(UInt(capacity))
    }
}

extension Buffer.Ring.Header.Cyclic where S: ~Copyable {
    /// Compute the `Storage.Initialization` state from ring header.
    ///
    /// Returns `.empty`, `.one`, or `.two` depending on whether elements
    /// wrap around the capacity boundary.
    @inlinable
    public var initialization: Store.Initialization<S.Element> { .init(self) }
}
