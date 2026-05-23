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

extension Buffer.Ring.Small where Element: ~Copyable {
    /// Constructs a SmallVec ring buffer from a result-builder closure.
    ///
    /// Wraps the dynamic `Buffer<Element>.Ring.Builder` per Round-2
    /// Option Y. Non-throwing because Small spills inline capacity to
    /// the heap rather than failing on overflow.
    ///
    /// ```swift
    /// let ring: Buffer<Int>.Ring.Small<4> = Buffer<Int>.Ring.Small {
    ///     1; 2; 3; 4; 5  // first 4 inline, 5th spills to heap
    /// }
    /// ```
    @inlinable
    public init(
        @Buffer<Element>.Ring.Builder _ builder: () -> Buffer<Element>.Ring
    ) {
        var dynamic = builder()
        self.init()
        while !dynamic.isEmpty {
            self.push.back(dynamic.pop.front())
        }
    }
}
