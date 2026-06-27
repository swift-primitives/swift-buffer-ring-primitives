import Affine_Primitives_Standard_Library_Integration
import Ordinal_Primitives_Standard_Library_Integration

// MARK: - Checkpoint for Ring

extension Buffer.Ring where S: ~Copyable {

    /// Captures the current cursor state as a checkpoint.
    @inlinable
    public var checkpoint: Checkpoint {
        Checkpoint(head: header.head, count: header.count)
    }

    /// Restores cursor state from a previously captured checkpoint.
    ///
    /// Updates head and count, then synchronizes `storage.initialization`.
    @inlinable
    public mutating func restore<E: ~Copyable>(to checkpoint: Checkpoint)
    where S == Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E> {
        header.head = checkpoint.head
        header.count = checkpoint.count
        storage.initialization = header.initialization
    }
}
