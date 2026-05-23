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

extension Buffer.Ring.Bounded where Element: ~Copyable {
    /// Constructs a heap-allocated bounded ring buffer from a result-builder closure.
    ///
    /// Wraps the dynamic `Buffer<Element>.Ring.Builder` per Round-2
    /// Option Y. Capacity is supplied at the outer init; overflow throws
    /// `Error.capacityExceeded` before any element is moved into `self`.
    ///
    /// ```swift
    /// let ring: Buffer<Int>.Ring.Bounded = try Buffer<Int>.Ring.Bounded(
    ///     minimumCapacity: 8
    /// ) {
    ///     1; 2; 3
    /// }
    /// ```
    @inlinable
    public init(
        minimumCapacity: Index<Element>.Count,
        @Buffer<Element>.Ring.Builder _ builder: () -> Buffer<Element>.Ring
    ) throws(Self.Error) {
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
