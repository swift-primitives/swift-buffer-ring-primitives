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

import Buffer_Ring_Primitives
import Buffer_Ring_Primitives_Test_Support
import Memory_Heap_Primitives
import Storage_Contiguous_Primitives
import Testing

// MARK: - Test Suite Structure

@Suite
struct `Buffer.Ring.Builder Tests` {
    @Suite struct Unit {}
    @Suite struct EdgeCase {}
    @Suite struct Integration {}
    @Suite struct NonCopyable {}
    @Suite struct StaticMethods {}
}

// MARK: - Move-Only Test Fixture

private struct Move: ~Copyable {
    let value: Int
    init(_ value: Int) { self.value = value }
}

// MARK: - Iteration Helpers (drain via pop.front)

extension `Buffer.Ring.Builder Tests` {
    fileprivate static func collected(
        _ buffer: consuming Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring
    ) -> [Int] {
        var rest = consume buffer
        var result: [Int] = []
        while !rest.isEmpty {
            result.append(rest.pop.front())
        }
        return result
    }

    fileprivate static func collected(
        _ buffer: consuming Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Move>>.Ring
    ) -> [Int] {
        var rest = consume buffer
        var result: [Int] = []
        while !rest.isEmpty {
            let m = rest.pop.front()
            result.append(m.value)
        }
        return result
    }
}

// MARK: - Unit Tests

extension `Buffer.Ring.Builder Tests`.Unit {

    @Test
    func `Single element expression`() {
        let buffer: Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring { 42 }
        #expect(`Buffer.Ring.Builder Tests`.collected(buffer) == [42])
    }

    @Test
    func `Multiple element expressions push to back in order`() {
        let buffer: Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring {
            1
            2
            3
        }
        // pop.front returns elements in declaration order (FIFO)
        #expect(`Buffer.Ring.Builder Tests`.collected(buffer) == [1, 2, 3])
    }

    @Test
    func `Optional element - some`() {
        let value: Int? = 42
        let buffer: Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring { value }
        #expect(`Buffer.Ring.Builder Tests`.collected(buffer) == [42])
    }

    @Test
    func `Optional element - none`() {
        let value: Int? = nil
        let buffer: Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring { value }
        let isEmpty = buffer.isEmpty
        #expect(isEmpty)
    }

    @Test
    func `Mixed elements and optionals`() {
        let some: Int? = 2
        let none: Int? = nil
        let buffer: Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring {
            1
            some
            none
            3
        }
        #expect(`Buffer.Ring.Builder Tests`.collected(buffer) == [1, 2, 3])
    }

    @Test
    func `Empty block`() {
        let buffer: Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring {}
        let isEmpty = buffer.isEmpty
        #expect(isEmpty)
    }
}

// MARK: - Control Flow

extension `Buffer.Ring.Builder Tests`.Unit {

    @Test
    func `Conditional include`() {
        let include = true
        let buffer: Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring {
            1
            if include {
                2
            }
            3
        }
        #expect(`Buffer.Ring.Builder Tests`.collected(buffer) == [1, 2, 3])
    }

    @Test
    func `Conditional exclude`() {
        let include = false
        let buffer: Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring {
            1
            if include {
                2
            }
            3
        }
        #expect(`Buffer.Ring.Builder Tests`.collected(buffer) == [1, 3])
    }

    @Test
    func `If-else first branch`() {
        let condition = true
        let buffer: Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring {
            if condition {
                1
            } else {
                2
            }
        }
        #expect(`Buffer.Ring.Builder Tests`.collected(buffer) == [1])
    }

    @Test
    func `If-else second branch`() {
        let condition = false
        let buffer: Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring {
            if condition {
                1
            } else {
                2
            }
        }
        #expect(`Buffer.Ring.Builder Tests`.collected(buffer) == [2])
    }

    @Test
    func `Limited availability passthrough`() {
        let buffer: Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring {
            1
            if #available(macOS 26, iOS 26, *) {
                2
            }
            3
        }
        #expect(`Buffer.Ring.Builder Tests`.collected(buffer) == [1, 2, 3])
    }
}

// MARK: - Edge Cases

extension `Buffer.Ring.Builder Tests`.EdgeCase {

    @Test
    func `Deeply nested conditionals`() {
        let a = true
        let b = false
        let c = true
        let buffer: Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring {
            0
            if a {
                1
                if b {
                    2
                } else {
                    3
                    if c {
                        4
                    }
                }
            }
            99
        }
        #expect(`Buffer.Ring.Builder Tests`.collected(buffer) == [0, 1, 3, 4, 99])
    }

    @Test
    func `Many elements preserve declaration order`() {
        let buffer: Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring {
            1
            2
            3
            4
            5
            6
            7
            8
            9
            10
        }
        #expect(`Buffer.Ring.Builder Tests`.collected(buffer) == Swift.Array(1...10))
    }
}

// MARK: - Integration

extension `Buffer.Ring.Builder Tests`.Integration {

    @Test
    func `Builder result is mutable - pushBack continues sequence`() {
        var buffer: Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring {
            1
            2
            3
        }
        buffer.push.back(4)
        #expect(`Buffer.Ring.Builder Tests`.collected(buffer) == [1, 2, 3, 4])
    }

    @Test
    func `Builder result accepts pushFront after construction`() {
        var buffer: Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring {
            2
            3
        }
        buffer.push.front(1)
        // After push.front(1): buffer is [1, 2, 3] front-to-back
        #expect(`Buffer.Ring.Builder Tests`.collected(buffer) == [1, 2, 3])
    }
}

// MARK: - NonCopyable

extension `Buffer.Ring.Builder Tests`.NonCopyable {

    @Test
    func `Builder with single noncopyable element`() {
        let buffer: Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Move>>.Ring = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Move>>.Ring {
            Move(42)
        }
        #expect(`Buffer.Ring.Builder Tests`.collected(buffer) == [42])
    }

    @Test
    func `Builder with multiple noncopyable elements`() {
        let buffer: Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Move>>.Ring = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Move>>.Ring {
            Move(1)
            Move(2)
            Move(3)
        }
        #expect(`Buffer.Ring.Builder Tests`.collected(buffer) == [1, 2, 3])
    }

    @Test
    func `Builder with conditional noncopyable element - included`() {
        let include = true
        let buffer: Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Move>>.Ring = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Move>>.Ring {
            Move(1)
            if include {
                Move(2)
            }
            Move(3)
        }
        #expect(`Buffer.Ring.Builder Tests`.collected(buffer) == [1, 2, 3])
    }

    @Test
    func `Builder with conditional noncopyable element - excluded`() {
        let include = false
        let buffer: Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Move>>.Ring = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Move>>.Ring {
            Move(1)
            if include {
                Move(2)
            }
            Move(3)
        }
        #expect(`Buffer.Ring.Builder Tests`.collected(buffer) == [1, 3])
    }

    @Test
    func `Builder with if-else noncopyable`() {
        let condition = true
        let buffer: Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Move>>.Ring = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Move>>.Ring {
            if condition {
                Move(10)
            } else {
                Move(20)
            }
        }
        #expect(`Buffer.Ring.Builder Tests`.collected(buffer) == [10])
    }

    @Test
    func `Empty noncopyable builder`() {
        let buffer: Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Move>>.Ring = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Move>>.Ring {}
        let isEmpty = buffer.isEmpty
        #expect(isEmpty)
    }
}

// MARK: - Static Method Tests

extension `Buffer.Ring.Builder Tests`.StaticMethods {

    @Test
    func `buildExpression single element`() {
        let result = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.Builder.buildExpression(42)
        #expect(`Buffer.Ring.Builder Tests`.collected(result) == [42])
    }

    @Test
    func `buildExpression existing buffer`() {
        let input: Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring {
            1
            2
            3
        }
        let result = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.Builder.buildExpression(input)
        #expect(`Buffer.Ring.Builder Tests`.collected(result) == [1, 2, 3])
    }

    @Test
    func `buildExpression optional - some`() {
        let value: Int? = 42
        let result = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.Builder.buildExpression(value)
        #expect(`Buffer.Ring.Builder Tests`.collected(result) == [42])
    }

    @Test
    func `buildExpression optional - none`() {
        let value: Int? = nil
        let result = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.Builder.buildExpression(value)
        let isEmpty = result.isEmpty
        #expect(isEmpty)
    }

    @Test
    func `buildPartialBlock first`() {
        let first: Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring {
            1
            2
            3
        }
        let result = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.Builder.buildPartialBlock(first: first)
        #expect(`Buffer.Ring.Builder Tests`.collected(result) == [1, 2, 3])
    }

    @Test
    func `buildPartialBlock first void`() {
        let result = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.Builder.buildPartialBlock(first: ())
        let isEmpty = result.isEmpty
        #expect(isEmpty)
    }

    @Test
    func `buildPartialBlock accumulated and next preserves order`() {
        let acc: Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring {
            1
            2
        }
        let next: Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring {
            3
            4
        }
        let result = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.Builder.buildPartialBlock(
            accumulated: acc,
            next: next
        )
        #expect(`Buffer.Ring.Builder Tests`.collected(result) == [1, 2, 3, 4])
    }

    @Test
    func `buildBlock empty`() {
        let result = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.Builder.buildBlock()
        let isEmpty = result.isEmpty
        #expect(isEmpty)
    }

    @Test
    func `buildOptional some`() {
        let component: Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring? = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring {
            1
            2
        }
        let result = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.Builder.buildOptional(component)
        #expect(`Buffer.Ring.Builder Tests`.collected(result) == [1, 2])
    }

    @Test
    func `buildOptional none`() {
        let component: Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring? = nil
        let result = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.Builder.buildOptional(component)
        let isEmpty = result.isEmpty
        #expect(isEmpty)
    }

    @Test
    func `buildEither first`() {
        let first: Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring {
            1
            2
        }
        let result = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.Builder.buildEither(first: first)
        #expect(`Buffer.Ring.Builder Tests`.collected(result) == [1, 2])
    }

    @Test
    func `buildEither second`() {
        let second: Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring {
            3
            4
        }
        let result = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.Builder.buildEither(second: second)
        #expect(`Buffer.Ring.Builder Tests`.collected(result) == [3, 4])
    }

    @Test
    func `buildLimitedAvailability passthrough`() {
        let component: Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring {
            1
            2
            3
        }
        let result = Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>.Ring.Builder.buildLimitedAvailability(component)
        #expect(`Buffer.Ring.Builder Tests`.collected(result) == [1, 2, 3])
    }
}
