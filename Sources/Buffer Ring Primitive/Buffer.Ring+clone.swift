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
// LINEARIZES: a wrapped ring's live elements are NOT the storage prefix, so
// `storage.copy()` (which copies `[0, count)`) would duplicate the wrong slots. The
// clone reads logical order through the wrap math and writes a fresh linear prefix
// (head = 0) — the `_growTo` relocation discipline, minus the consume.
extension Buffer.Ring where S: ~Copyable {
    /// Returns an independent copy with the same capacity, linearized (head = 0).
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
        var copy = Self(header: Header(capacity: fresh.capacity), storage: fresh)
        copy.header.count = header.count
        copy.storage.initialization = .init(copy.header)
        return copy
    }
}
