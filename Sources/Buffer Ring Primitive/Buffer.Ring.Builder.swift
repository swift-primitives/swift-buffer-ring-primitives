import Affine_Primitives_Standard_Library_Integration
// Explicit `Buffer.Protocol` import: the @inlinable builder body below uses the
// inherited `isEmpty` default (not relied on transitively); `public` per [MOD-027].
public import Buffer_Protocol_Primitives
import Ordinal_Primitives_Standard_Library_Integration

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

extension Buffer.Ring where S: ~Copyable {
    /// A result builder for declaratively constructing ring buffers.
    ///
    /// The builder appends each declared element to the back of the ring
    /// (`push.back` semantics). For front insertion, use the imperative
    /// `push.front(_:)` API directly. Declaration order is back-fill
    /// order; consumers reading from the front via `pop.front()` see
    /// elements in the same order they were declared.
    ///
    /// ```swift
    /// let buffer: Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring {
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
    /// let buffer: Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<FileHandle>>.Ring = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<FileHandle>>.Ring {
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
    /// ~Copyable `Buffer<S>.Ring`.
    @resultBuilder
    public enum Builder {

        // MARK: - Expression Building

        /// Wraps a single element into a one-element ring component.
        @inlinable
        public static func buildExpression<E: ~Copyable>(
            _ expression: consuming E
        ) -> Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Ring where S == Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E> {
            var result = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Ring(minimumCapacity: .one)
            result.push.back(consume expression)
            return result
        }

        /// Passes a ring expression through unchanged as a component.
        @inlinable
        public static func buildExpression<E: ~Copyable>(
            _ expression: consuming Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Ring
        ) -> Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Ring where S == Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E> {
            consume expression
        }

        /// Wraps an optional element, contributing nothing when it is `nil`.
        @inlinable
        public static func buildExpression<E: ~Copyable>(
            _ expression: consuming E?
        ) -> Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Ring where S == Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E> {
            var result = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Ring(minimumCapacity: .zero)
            if let value = consume expression {
                result.push.back(consume value)
            }
            return result
        }

        // MARK: - Partial Block Building

        /// Begins a block from its first ring component.
        @inlinable
        public static func buildPartialBlock<E: ~Copyable>(
            first: consuming Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Ring
        ) -> Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Ring where S == Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E> {
            consume first
        }

        /// Begins a block from a `Void` statement, yielding an empty ring.
        @inlinable
        public static func buildPartialBlock<E: ~Copyable>(
            first: Void
        ) -> Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Ring where S == Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E> {
            Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Ring(minimumCapacity: .zero)
        }

        /// Begins a block from an unreachable (`Never`) statement.
        @inlinable
        public static func buildPartialBlock<E: ~Copyable>(
            first: Never
        ) -> Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Ring where S == Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E> {}

        /// Appends the next ring's elements onto the accumulated ring, preserving order.
        @inlinable
        public static func buildPartialBlock<E: ~Copyable>(
            accumulated: consuming Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Ring,
            next: consuming Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Ring
        ) -> Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Ring where S == Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E> {
            var result = consume accumulated
            var rest = consume next
            while !rest.isEmpty {
                result.push.back(rest.pop.front())
            }
            return result
        }

        // MARK: - Block Building

        /// Builds an empty ring from an empty block.
        @inlinable
        public static func buildBlock<E: ~Copyable>() -> Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Ring where S == Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E> {
            Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Ring(minimumCapacity: .zero)
        }

        // MARK: - Control Flow

        /// Contributes the component of an `if`-without-`else` block, or an empty ring when absent.
        @inlinable
        public static func buildOptional<E: ~Copyable>(
            _ component: consuming Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Ring?
        ) -> Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Ring where S == Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E> {
            if let result = consume component {
                return consume result
            }
            return Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Ring(minimumCapacity: .zero)
        }

        /// Selects the first branch of an `if`/`else`.
        @inlinable
        public static func buildEither<E: ~Copyable>(
            first: consuming Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Ring
        ) -> Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Ring where S == Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E> {
            consume first
        }

        /// Selects the second branch of an `if`/`else`.
        @inlinable
        public static func buildEither<E: ~Copyable>(
            second: consuming Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Ring
        ) -> Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Ring where S == Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E> {
            consume second
        }

        // buildArray omitted: see DocC above.

        /// Passes a component out of a limited-availability (`if #available`) block.
        @inlinable
        public static func buildLimitedAvailability<E: ~Copyable>(
            _ component: consuming Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Ring
        ) -> Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Ring where S == Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E> {
            consume component
        }
    }
}

// MARK: - Convenience Init

extension Buffer.Ring where S: ~Copyable {
    /// Constructs a ring buffer from a result-builder closure.
    ///
    /// Each element is appended to the back of the ring in declaration
    /// order. Consumers reading from the front via `pop.front()` see
    /// elements in declaration order (FIFO).
    ///
    /// ```swift
    /// let buffer: Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring {
    ///     1
    ///     2
    ///     3
    /// }
    /// ```
    @inlinable
    public init<E: ~Copyable>(@Buffer.Ring.Builder _ builder: () -> Self) where S == Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E> {
        self = builder()
    }
}

// MARK: - Sequence Bulk-Add (Copyable Element only)

extension Buffer.Ring.Builder where S: ~Copyable {
    /// Bulk-add a Swift.Sequence to the back of the ring without
    /// per-iteration allocation.
    @inlinable
    public static func buildExpression<E, Seq: Swift.Sequence>(_ expression: Seq) -> Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Ring
    where S == Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>, E: Copyable, Seq.Element == E {
        var result = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Ring(minimumCapacity: .zero)
        for value in expression {
            result.push.back(value)
        }
        return result
    }
}
