import Affine_Primitives_Standard_Library_Integration
import Ordinal_Primitives_Standard_Library_Integration
public import Store_Ledgered_Primitives

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
    public mutating func restore(to checkpoint: Checkpoint)
    where S: Store.Ledgered.`Protocol` {
        header.head = checkpoint.head
        header.count = checkpoint.count
        storage.initialization = header.initialization
    }
}
