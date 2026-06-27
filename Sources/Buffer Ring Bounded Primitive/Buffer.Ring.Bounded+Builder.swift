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

extension Buffer.Ring.Bounded where S: ~Copyable {
    /// Constructs a heap-allocated bounded ring buffer from a result-builder closure.
    ///
    /// Wraps the dynamic `Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<S.Element>>.Ring.Builder` per Round-2
    /// Option Y. Capacity is supplied at the outer init; overflow throws
    /// `Error.capacityExceeded` before any element is moved into `self`.
    ///
    /// ```swift
    /// let ring: Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.Bounded = try Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.Bounded(
    ///     minimumCapacity: 8
    /// ) {
    ///     1; 2; 3
    /// }
    /// ```
    @inlinable
    public init<E: ~Copyable>(
        minimumCapacity: Index<E>.Count,
        @Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Ring.Builder _ builder: () -> Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Ring
    ) throws(Self.Error) where S == Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E> {
        var dynamic = builder()
        guard dynamic.count <= minimumCapacity else {
            throw .capacityExceeded
        }
        self.init(minimumCapacity: minimumCapacity)
        while !dynamic.isEmpty {
            _ = self.push.back(dynamic.pop.front())
        }
    }
}
