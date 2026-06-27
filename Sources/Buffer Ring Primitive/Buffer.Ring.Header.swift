import Affine_Primitives_Standard_Library_Integration
import Index_Primitives
import Ordinal_Primitives_Standard_Library_Integration

//
//  Buffer.Ring.Header.swift
//  swift-buffer-primitives
//
//  Created by Coen ten Thije Boonkkamp on 04/02/2026.
//

extension Buffer.Ring where S: ~Copyable {
    /// Pure cursor state for a dynamic-capacity ring buffer.
    ///
    /// Copyable and Sendable — this is just a few integers.
    ///
    /// Blueprint: `Experiments/ring-buffer-architecture-validation/Sources/main.swift:48-101`
    @frozen
    public struct Header: Copyable, Sendable {
        /// Slot index of the first element.
        public var head: Index<S.Element>

        /// Number of initialized elements.
        public var count: Index<S.Element>.Count

        /// Total slot capacity.
        public let capacity: Index<S.Element>.Count

        /// Creates a header with the given capacity and zero elements.
        @inlinable
        public init(capacity: Index<S.Element>.Count) {
            self.head = .zero
            self.count = .zero
            self.capacity = capacity
        }
    }
}

extension Buffer.Ring.Header where S: ~Copyable {
    /// Whether the buffer has no elements.
    @inlinable
    public var isEmpty: Bool { count == .zero }

    /// Whether the buffer is at capacity.
    @inlinable
    public var isFull: Bool { count == capacity }
}

extension Buffer.Ring.Header where S: ~Copyable {
    /// Compute the `Storage.Initialization` state from ring header.
    ///
    /// Returns `.empty`, `.one`, or `.two` depending on whether elements
    /// wrap around the capacity boundary.
    @inlinable
    public var initialization: Store.Initialization<S.Element> { .init(self) }
}
