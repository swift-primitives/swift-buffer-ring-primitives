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
import Cyclic_Index_Primitives
public import Index_Primitives
import Ordinal_Primitives_Standard_Library_Integration
import Store_Initialization_Primitives
public import Store_Ledgered_Primitives
public import Store_Protocol_Primitives

// MARK: - The seam, under the RING DISCIPLINE (front-anchored, restricted domain)
//
// The bounded twin of `Buffer.Ring+Store.Protocol.swift` (ratified ASK-B; the lawful
// domain is documented there): initialize ONLY at the back; move ONLY at the front
// (re-anchoring) or the back; the logical subscript covers any live slot; every witness
// re-syncs the storage ledger from the header. Bounded-ness is invisible to the seam —
// the seam has no growth op; a full bounded ring simply traps `initialize` like a full
// growable ring does (growth is the column's affair).
//
// The element subscript witness is supplied here GENERICALLY (the bounded buffer's own
// element subscript is pinned to the heap column — the `Buffer.Linear.Bounded`
// precedent, 1e75e0c).
extension Buffer.Ring.Bounded: Store.`Protocol` where S: Store.Ledgered.`Protocol`, S: ~Copyable {
    /// Logical element access (0 = front; wrap math in the witness); positions
    /// re-anchor after a front move.
    @inlinable
    public subscript(slot: Index<S.Element>) -> S.Element {
        _read {
            yield storage[Index.Modular.physical(forLogical: slot, head: header.head, capacity: header.capacity)]
        }
        _modify {
            yield &storage[Index.Modular.physical(forLogical: slot, head: header.head, capacity: header.capacity)]
        }
    }

    /// Initializes the slot at the BACK (`slot == count`).
    @inlinable
    public mutating func initialize(at slot: Index<S.Element>, to element: consuming S.Element) {
        precondition(slot == header.count.map(Ordinal.init), "ring seam: initialize is lawful only at the back (slot == count)")
        precondition(!header.isFull, "ring seam: initialize on a full ring")
        let tail = Index.Modular.advanced(
            header.head,
            by: Index<S.Element>.Offset(fromZero: header.count.map(Ordinal.init)),
            capacity: header.capacity
        )
        storage.initialize(at: tail, to: element)
        header.count = header.count.add.saturating(.one)
        storage.initialization = .init(header)
    }

    /// Moves the element out at the FRONT (`slot == 0`; re-anchoring) or the BACK
    /// (`slot == count − 1`).
    @inlinable
    public mutating func move(at slot: Index<S.Element>) -> S.Element {
        precondition(!header.isEmpty, "ring seam: move on an empty ring")
        if slot == .zero {
            let element = storage.move(at: header.head)
            header.head = Index.Modular.successor(of: header.head, capacity: header.capacity)
            header.count = header.count.subtract.saturating(.one)
            storage.initialization = .init(header)
            return element
        }
        let newCount = header.count.subtract.saturating(.one)
        precondition(slot == newCount.map(Ordinal.init), "ring seam: move is lawful only at the front or the back")
        let last = Index.Modular.advanced(
            header.head,
            by: Index<S.Element>.Offset(fromZero: newCount.map(Ordinal.init)),
            capacity: header.capacity
        )
        let element = storage.move(at: last)
        header.count = newCount
        storage.initialization = .init(header)
        return element
    }
}
