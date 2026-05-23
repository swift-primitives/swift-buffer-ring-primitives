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

extension Buffer.Ring.Inline where Element: ~Copyable {
    /// Constructs a fixed-capacity inline ring buffer from a result-builder closure.
    ///
    /// Wraps the dynamic `Buffer<Element>.Ring.Builder` per Round-2
    /// Option Y. Each declared element is pushed to the back of the ring
    /// (matches the Round-1 back-default semantic). Capacity is checked
    /// up front; overflow throws `Error.capacityExceeded` before any
    /// element is moved into `self`.
    ///
    /// ```swift
    /// let ring: Buffer<Int>.Ring.Inline<8> = try Buffer<Int>.Ring.Inline {
    ///     1; 2; 3
    /// }
    /// ```
    @inlinable
    public init(
        @Buffer<Element>.Ring.Builder _ builder: () -> Buffer<Element>.Ring
    ) throws(Self.Error) {
        var dynamic = builder()
        let cap = Index<Element>.Count(UInt(capacity))
        guard dynamic.count <= cap else {
            throw .capacityExceeded
        }
        self.init()
        while !dynamic.isEmpty {
            _ = self.push.back(dynamic.pop.front())
        }
    }
}
