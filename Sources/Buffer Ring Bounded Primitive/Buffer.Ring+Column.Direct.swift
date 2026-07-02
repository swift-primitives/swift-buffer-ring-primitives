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

public import Store_Protocol_Primitives
public import Store_Ledgered_Primitives

// MARK: - Column.Direct (the axis-changing-alias fence, [DS-028])

/// `Buffer.Ring` is a DIRECT canonical column: it conforms to `Column.Direct` (the hoisted
/// `__ColumnDirect` marker, [DS-028] law 1). Its capacity-twin column ``Column/Direct/Bounded``
/// is the fixed-capacity `Buffer.Ring.Bounded`, through which the column-PRESERVING `.Bounded`
/// alias maps ([DS-028] law 2). The nested `Buffer.Ring.Bounded` type witnesses the `Bounded`
/// requirement by member-name inference — no explicit typealias needed.
///
/// The bound is `where S: Store.Ledgered.`Protocol`` — the same bound `Buffer.Ring`'s
/// `Store.`Protocol`` conformance carries (the ring rides the ledger for its count), which is
/// what `__ColumnDirect`'s `__StoreProtocol` refinement requires. Only the conformance + twin
/// land here; ring op generalization stays W3.
extension Buffer.Ring: __ColumnDirect where S: Store.Ledgered.`Protocol`, S: ~Copyable {}
