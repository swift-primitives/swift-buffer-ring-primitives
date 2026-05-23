import Ordinal_Primitives_Standard_Library_Integration
import Affine_Primitives_Standard_Library_Integration
// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-primitives open source project
//
// Copyright (c) 2024-2026 Coen ten Thije Boonkkamp and the swift-primitives project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

extension Buffer.Ring where Element: ~Copyable {
    /// A result builder for declaratively constructing ring buffers.
    ///
    /// The builder appends each declared element to the back of the ring
    /// (`push.back` semantics). For front insertion, use the imperative
    /// `push.front(_:)` API directly. Declaration order is back-fill
    /// order; consumers reading from the front via `pop.front()` see
    /// elements in the same order they were declared.
    ///
    /// ```swift
    /// let buffer: Buffer<Int>.Ring = Buffer<Int>.Ring {
    ///     1
    ///     2
    ///     3
    /// }
    /// // pop.front() returns 1, then 2, then 3 (FIFO).
    /// ```
    ///
    /// Supports `~Copyable` elements via consuming push:
    ///
    /// ```swift
    /// struct FileHandle: ~Copyable { ... }
    /// let buffer: Buffer<FileHandle>.Ring = Buffer<FileHandle>.Ring {
    ///     FileHandle()
    ///     FileHandle()
    /// }
    /// ```
    ///
    /// ## `for` Loops Not Supported
    ///
    /// `buildArray` is omitted because Swift's result-builder transform's
    /// buildArray step uses `Swift.Array<Component>`, which currently
    /// requires `Component: Copyable`. The component here is the
    /// ~Copyable `Buffer<Element>.Ring`.
    @resultBuilder
    public enum Builder {

        // MARK: - Expression Building

        @inlinable
        public static func buildExpression(
            _ expression: consuming Element
        ) -> Buffer<Element>.Ring {
            var result = Buffer<Element>.Ring(minimumCapacity: .one)
            result.push.back(consume expression)
            return result
        }

        @inlinable
        public static func buildExpression(
            _ expression: consuming Buffer<Element>.Ring
        ) -> Buffer<Element>.Ring {
            consume expression
        }

        @inlinable
        public static func buildExpression(
            _ expression: consuming Element?
        ) -> Buffer<Element>.Ring {
            var result = Buffer<Element>.Ring(minimumCapacity: .zero)
            if let value = consume expression {
                result.push.back(consume value)
            }
            return result
        }

        // MARK: - Partial Block Building

        @inlinable
        public static func buildPartialBlock(
            first: consuming Buffer<Element>.Ring
        ) -> Buffer<Element>.Ring {
            consume first
        }

        @inlinable
        public static func buildPartialBlock(
            first: Void
        ) -> Buffer<Element>.Ring {
            Buffer<Element>.Ring(minimumCapacity: .zero)
        }

        @inlinable
        public static func buildPartialBlock(
            first: Never
        ) -> Buffer<Element>.Ring {}

        @inlinable
        public static func buildPartialBlock(
            accumulated: consuming Buffer<Element>.Ring,
            next: consuming Buffer<Element>.Ring
        ) -> Buffer<Element>.Ring {
            var result = consume accumulated
            var rest = consume next
            while !rest.isEmpty {
                result.push.back(rest.pop.front())
            }
            return result
        }

        // MARK: - Block Building

        @inlinable
        public static func buildBlock() -> Buffer<Element>.Ring {
            Buffer<Element>.Ring(minimumCapacity: .zero)
        }

        // MARK: - Control Flow

        @inlinable
        public static func buildOptional(
            _ component: consuming Buffer<Element>.Ring?
        ) -> Buffer<Element>.Ring {
            if let result = consume component {
                return consume result
            }
            return Buffer<Element>.Ring(minimumCapacity: .zero)
        }

        @inlinable
        public static func buildEither(
            first: consuming Buffer<Element>.Ring
        ) -> Buffer<Element>.Ring {
            consume first
        }

        @inlinable
        public static func buildEither(
            second: consuming Buffer<Element>.Ring
        ) -> Buffer<Element>.Ring {
            consume second
        }

        // buildArray omitted: see DocC above.

        @inlinable
        public static func buildLimitedAvailability(
            _ component: consuming Buffer<Element>.Ring
        ) -> Buffer<Element>.Ring {
            consume component
        }
    }
}

// MARK: - Convenience Init

extension Buffer.Ring where Element: ~Copyable {
    /// Constructs a ring buffer from a result-builder closure.
    ///
    /// Each element is appended to the back of the ring in declaration
    /// order. Consumers reading from the front via `pop.front()` see
    /// elements in declaration order (FIFO).
    ///
    /// ```swift
    /// let buffer: Buffer<Int>.Ring = Buffer<Int>.Ring {
    ///     1
    ///     2
    ///     3
    /// }
    /// ```
    @inlinable
    public init(@Buffer.Ring.Builder _ builder: () -> Self) {
        self = builder()
    }
}

// MARK: - Sequence Bulk-Add (Copyable Element only)

extension Buffer.Ring.Builder where Element: Copyable {
    /// Bulk-add a Swift.Sequence to the back of the ring without
    /// per-iteration allocation.
    @inlinable
    public static func buildExpression<S: Swift.Sequence>(_ expression: S) -> Buffer<Element>.Ring
    where S.Element == Element {
        var result = Buffer<Element>.Ring(minimumCapacity: .zero)
        for value in expression {
            result.push.back(value)
        }
        return result
    }
}
