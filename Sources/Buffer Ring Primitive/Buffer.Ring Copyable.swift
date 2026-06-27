import Affine_Primitives_Standard_Library_Integration
public import Index_Primitives
public import Memory_Allocator_Primitive
public import Memory_Heap_Primitives
import Ordinal_Primitives_Standard_Library_Integration
public import Storage_Contiguous_Primitives
public import Storage_Primitive

// MARK: - Copyable-element features for Buffer.Ring
//
// CoW (`ensureUnique`) is withdrawn at the storage tier (W2): `Storage.Contiguous` is unconditionally
// `~Copyable` with an explicit `copy()`, so `Buffer.Ring` is move-only and the former CoW-safe
// mutation/subscript shadows are removed (R1 — the non-CoW surface serves Copyable elements too).
// What remains here is genuinely Copyable-only and CoW-free: peek-by-value.

// MARK: - Peek Operations (read-only, by value — requires Copyable)

extension Property.Borrow.Typed
where
    Tag == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Element>>.Ring.Peek,
    Base == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Element>>.Ring,
    Element: Copyable
{
    /// Returns the front element without removing it.
    ///
    /// - Precondition: The buffer is not empty.
    /// - Complexity: O(1)
    @inlinable
    public var front: Element {
        base.value.storage[base.value.header.head]
    }

    /// Returns the back element without removing it.
    ///
    /// - Precondition: The buffer is not empty.
    /// - Complexity: O(1)
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
