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

import Affine_Primitives_Standard_Library_Integration
public import Index_Primitives
public import Memory_Allocator_Primitive
public import Memory_Heap_Primitives
import Ordinal_Primitives_Standard_Library_Integration
public import Storage_Contiguous_Primitives

// MARK: - Explicit deep copy (the heap column; the `Shared` clone strategy)
//
// The bounded twin of `Buffer.Ring+clone.swift`: linearizes (a wrapped ring's live
// elements are not the storage prefix), preserving the FIXED capacity.
extension Buffer.Ring.Bounded where S: ~Copyable {
    /// Returns an independent copy with the same fixed capacity, linearized (head = 0).
    ///
    /// - Complexity: O(`count`)
    @inlinable
    public func clone<E>() -> Self
    where S == Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>, E: Copyable {
        var fresh = S.create(minimumCapacity: header.capacity)
        var slot: Index<E> = .zero
        let end = header.count.map(Ordinal.init)
        while slot < end {
            fresh.initialize(at: slot, to: self[slot])
            slot = slot.successor.saturating()
        }
        var copy = Self(header: Buffer.Ring.Header(capacity: fresh.capacity), storage: fresh)
        copy.header.count = header.count
        copy.storage.initialization = .init(copy.header)
        return copy
    }
}
