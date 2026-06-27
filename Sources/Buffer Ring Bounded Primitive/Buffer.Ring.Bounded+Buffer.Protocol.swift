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

public import Buffer_Protocol_Primitives

// MARK: - Buffer.Protocol Conformance (Ring.Bounded)

/// `Buffer.Ring.Bounded` is a `Buffer.Protocol` capability conformer.
///
/// The sole witness is `count` (`Buffer.Ring.Bounded+Operations.swift`); `isEmpty`
/// is the inherited element-domain default (`count == .zero`).
/// This is the LOGICAL capability surface only — iteration is orthogonal and NOT
/// part of this conformance. The banked `where S: ~Copyable` conformance is
/// preserved.
extension Buffer.Ring.Bounded: Buffer.`Protocol` where S: ~Copyable {
    /// The buffered element type, pinned to the substrate's element (`S.Element`).
    public typealias Element = S.Element
}
