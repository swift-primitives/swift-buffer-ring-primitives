import Affine_Primitives_Standard_Library_Integration
public import Index_Primitives
public import Memory_Allocator_Primitive
public import Memory_Allocator_Protocol_Primitives
public import Memory_Heap_Primitives
import Ordinal_Primitives_Standard_Library_Integration
public import Storage_Contiguous_Primitives
public import Storage_Primitive

// MARK: - Copyable-element features for Buffer.Ring.Bounded
//
// CoW (`ensureUnique`) is withdrawn at the storage tier (W2): `Storage.Contiguous` is unconditionally
// `~Copyable` with an explicit `copy()`, so `Buffer.Ring.Bounded` is move-only and the former
// CoW-safe mutation shadows are removed (R1 — the non-CoW surface serves Copyable elements too).
// What remains here is genuinely Copyable-only and CoW-free: array initialization + peek-by-value.

// MARK: - Array Initialization

extension Buffer.Ring.Bounded where S: ~Copyable {

    /// Creates a bounded ring buffer populated with the given elements.
    ///
    /// - Parameters:
    ///   - elements: The elements to populate the buffer with.
    ///   - capacity: The fixed capacity for the buffer.
    /// - Throws: ``Error/capacityExceeded`` if `elements.count` exceeds `capacity`.
    @inlinable
    public init<Element, Resource: Memory.Growable & ~Copyable>(_ elements: [Element], capacity: UInt) throws(Self.Error) where S == Storage<Memory.Allocator<Resource>>.Contiguous<Element> {
        guard elements.count <= Int(capacity) else { throw .capacityExceeded }
        var buffer = Self(minimumCapacity: Index<Element>.Count(Cardinal(capacity)))
        for element in elements {
            _ = buffer._pushBack(element)
        }
        self = buffer
    }
}

// MARK: - Peek Operations (read-only, by value — requires Copyable)

extension Property.Borrow.Typed
where
    Tag == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Element>>.Ring.Peek,
    Base == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Element>>.Ring.Bounded,
    Element: Copyable
{
    /// Returns the front element without removing it.
    ///
    /// - Precondition: The buffer is not empty.
    @inlinable
    public var front: Element {
        base.value.storage[base.value.header.head]
    }

    /// Returns the back element without removing it.
    ///
    /// - Precondition: The buffer is not empty.
    @inlinable
    public var back: Element {
        return base.value.storage[
            Index.Modular.advanced(
                base.value.header.head,
                by: Index<Element>.Offset(fromZero: base.value.header.count.subtract.saturating(.one).map(Ordinal.init)),
                capacity: base.value.header.capacity
            )
        ]
    }
}
