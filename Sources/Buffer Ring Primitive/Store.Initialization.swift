import Affine_Primitives_Standard_Library_Integration
import Ordinal_Primitives_Standard_Library_Integration
import Storage_Protocol_Primitives
public import Store_Initialization_Primitives
public import Store_Protocol_Primitives

//
//  Store.Initialization.swift
//  swift-buffer-primitives
//
//  Created by Coen ten Thije Boonkkamp on 04/02/2026.
//

// Post-split respell (C6 wall, consumer instance): see buffer-linear's twin.
extension Store.Initialization where Element: ~Copyable & ~Escapable {
    /// Derives the initialized-slot ranges from a ring header, splitting a wrapped ring into its two runs.
    @inlinable
    public init<S: Store.`Protocol` & ~Copyable>(
        _ header: Buffer<S>.Ring.Header
    ) where S.Element == Element {
        if header.count == .zero {
            self = .empty
            return
        }

        let tail = header.head + header.count

        if tail <= header.capacity {
            self = .one(header.head..<tail)
        } else {
            self = .two(
                first: header.head..<header.capacity.map(Ordinal.init),
                second: .zero..<Index<Element>.Count(tail).subtract.saturating(header.capacity).map(Ordinal.init)
            )
        }
    }
}

// Post-split respell (C6 wall, consumer instance): see buffer-linear's twin.
extension Store.Initialization where Element: ~Copyable & ~Escapable {
    /// Derives the initialized-slot ranges from a compile-time-sized cyclic ring header, splitting a wrapped ring into its two runs.
    @inlinable
    public init<S: Store.`Protocol` & ~Copyable, let capacity: Int>(
        _ header: Buffer<S>.Ring.Header.Cyclic<capacity>
    ) where S.Element == Element {
        if header.count == .zero {
            self = .empty
            return
        }

        let slotCapacity = Buffer<S>.Ring.Header.Cyclic<capacity>.slotCapacity
        let headIndex = header.head.map { $0.position }
        let tail = headIndex + header.count

        if tail <= slotCapacity {
            self = .one(headIndex..<tail)
        } else {
            self = .two(
                first: headIndex..<slotCapacity.map(Ordinal.init),
                second: .zero..<Index<Element>.Count(tail).subtract.saturating(slotCapacity).map(Ordinal.init)
            )
        }
    }
}
