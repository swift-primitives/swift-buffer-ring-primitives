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

import Storage_Protocol_Primitives

extension Buffer.Ring where S: ~Copyable {

    /// A read-only borrow of the backing substrate.
    ///
    /// Lets consumers query *substrate-specific* properties through the composed ring —
    /// e.g. `Store.Small` (deferred Q2)'s `isSpilled` via `ring.substrate.isSpilled` — WITHOUT promoting
    /// those properties to the neutral `Storage.Protocol` seam (mirror of `Buffer.Linear.substrate`;
    /// Cleave-3 #12a, seam-free).
    @inlinable
    public var substrate: S {
        _read { yield storage }
    }
}
