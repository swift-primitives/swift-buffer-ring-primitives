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
// Ratified 2026-06-10 (ASK-B, spike-proven F-2). The ring conforms the 4+1-op seam over
// every LEDGERED store (`Store.Ledgered.`Protocol``): the seam's own prefix arithmetic
// cannot describe wrapped occupancy, so every witness overwrites the storage ledger with
// the header-computed shape after its cursor arithmetic — keeping the leaf's deinit
// oracle truthful on wrapped (two-run) layouts.
//
// ## THE LAWFUL DOMAIN (a ring cannot represent holes — out-of-domain ops TRAP)
//
//   • `subscript(slot:)` — every LIVE logical slot (0 = front; wrap math in the witness).
//     Positions RE-ANCHOR after a front move: old logical 1 becomes logical 0.
//   • `initialize(at:to:)` — lawful ONLY at the back (`slot == count`).
//   • `move(at:)` — lawful ONLY at the front (`slot == 0`; the head advances) or the
//     back (`slot == count − 1`; the tail retreats).
//
// The [DS-024] seam-ledger count-laws hold on this domain (proven from this package's
// own suite). Positional STABILITY differs from the linear column by design — an ADT
// whose dances assume stable mid-positions (`Array.remove(at:)`) is unlawful over a
// ring column and traps; composition lawfulness is law-gated, not type-gated (the
// Slots precedent). The `Store.Stable`/`Store.Anchored` protocol split is the recorded
// upgrade path if a real mis-composition ever bites.
extension Buffer.Ring: Store.`Protocol` where S: Store.Ledgered.`Protocol`, S: ~Copyable {
    // `capacity` and the logical element `subscript` are witnessed by the existing
    // generic members (`Buffer.Ring+Operations.swift`, `Buffer.Ring+Subscript.swift`).

    /// Initializes the slot at the BACK (`slot == count`): the seam spelling of
    /// push-back, minus growth (growth is a column op, not a seam op).
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

    /// Moves the element out at the FRONT (`slot == 0`; the head advances — positions
    /// re-anchor) or the BACK (`slot == count − 1`; the tail retreats).
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
