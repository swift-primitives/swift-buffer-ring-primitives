import Affine_Primitives_Standard_Library_Integration
import Ordinal_Primitives_Standard_Library_Integration

// MARK: - Subscript for Ring.Bounded (~Copyable)

extension Buffer.Ring.Bounded where S: ~Copyable {
    /// Accesses the element at the given logical index.
    ///
    /// Logical index 0 is the front of the ring. Physical slot is computed
    /// via `Index.Modular.physical(forLogical:head:capacity:)`.
    ///
    /// - Parameter index: The logical index of the element to access.
    @inlinable
    public subscript<E: ~Copyable>(index: Index<E>) -> E where S == Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E> {
        _read {
            let physical = Index.Modular.physical(
                forLogical: index,
                head: header.head,
                capacity: header.capacity
            )
            yield storage[physical]
        }
        _modify {
            let physical = Index.Modular.physical(
                forLogical: index,
                head: header.head,
                capacity: header.capacity
            )
            yield &storage[physical]
        }
    }
}
