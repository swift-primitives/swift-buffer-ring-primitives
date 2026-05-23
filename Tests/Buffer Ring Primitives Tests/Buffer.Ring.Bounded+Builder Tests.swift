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

import Buffer_Ring_Primitives_Test_Support
import Buffer_Ring_Primitives
import Testing

@Suite("Buffer.Ring.Bounded+Builder")
struct RingBoundedBuilderTests {
    @Suite struct WithinCapacity {}
    @Suite struct Overflow {}
    @Suite struct NonCopyable {}
}

private struct Move: ~Copyable {
    let value: Int
    init(_ value: Int) { self.value = value }
}

extension RingBoundedBuilderTests.WithinCapacity {

    @Test
    func `Constructs within capacity`() throws {
        let ring = try Buffer<Int>.Ring.Bounded(minimumCapacity: 8) {
            1
            2
            3
        }
        #expect(ring.count == 3)
    }
}

extension RingBoundedBuilderTests.Overflow {

    @Test
    func `Throws on overflow`() {
        do {
            _ = try Buffer<Int>.Ring.Bounded(minimumCapacity: 2) {
                1
                2
                3
            }
            Issue.record("expected throw")
        } catch let error {
            #expect(error == .capacityExceeded)
        }
    }
}

extension RingBoundedBuilderTests.NonCopyable {

    @Test
    func `Constructs noncopyable bounded ring`() throws {
        let ring = try Buffer<Move>.Ring.Bounded(minimumCapacity: 4) {
            Move(1)
            Move(2)
        }
        #expect(ring.count == 2)
    }
}
