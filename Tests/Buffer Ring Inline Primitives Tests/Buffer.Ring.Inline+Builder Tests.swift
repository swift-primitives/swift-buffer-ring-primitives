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
import Buffer_Ring_Inline_Primitives
import Buffer_Ring_Primitives
import Testing

@Suite("Buffer.Ring.Inline+Builder")
struct RingInlineBuilderTests {
    @Suite struct WithinCapacity {}
    @Suite struct Overflow {}
    @Suite struct NonCopyable {}
    @Suite struct Small {}
}

private struct Move: ~Copyable {
    let value: Int
    init(_ value: Int) { self.value = value }
}

extension RingInlineBuilderTests.WithinCapacity {

    @Test
    func `Constructs within capacity`() throws {
        let ring = try Buffer<Int>.Ring.Inline<8> {
            1
            2
            3
        }
        #expect(ring.count == 3)
    }
}

extension RingInlineBuilderTests.Overflow {

    @Test
    func `Throws on overflow`() {
        do {
            _ = try Buffer<Int>.Ring.Inline<2> {
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

extension RingInlineBuilderTests.NonCopyable {

    @Test
    func `Constructs noncopyable inline ring`() throws {
        let ring = try Buffer<Move>.Ring.Inline<4> {
            Move(1)
            Move(2)
            Move(3)
        }
        #expect(ring.count == 3)
    }
}

extension RingInlineBuilderTests.Small {

    @Test
    func `Buffer.Ring.Small constructs within inline capacity`() {
        let ring = Buffer<Int>.Ring.Small<8> {
            1
            2
            3
        }
        #expect(ring.count == 3)
    }

    @Test
    func `Buffer.Ring.Small spills to heap on overflow`() {
        let ring = Buffer<Int>.Ring.Small<2> {
            1
            2
            3
            4
            5
        }
        #expect(ring.count == 5)
    }
}
