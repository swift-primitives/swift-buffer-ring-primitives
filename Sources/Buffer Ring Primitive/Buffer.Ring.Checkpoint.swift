import Affine_Primitives_Standard_Library_Integration
import Index_Primitives
import Ordinal_Primitives_Standard_Library_Integration

extension Buffer.Ring where S: ~Copyable {
    // MARK: - Checkpoint

    /// A snapshot of ring buffer cursor state for save/restore.
    ///
    /// Captures head and count at a point in time. Restore replays
    /// the cursor state without modifying storage contents.
    ///
    /// Ordered by consumption position: higher count (earlier in consumption)
    /// sorts first. This enables `ClosedRange<Checkpoint>` to express valid
    /// backtracking windows where lowerBound is the earliest saved position
    /// and upperBound is the current position.
    ///
    /// Equality is count-only: within a linear consumption sequence, count
    /// uniquely determines the restoration state.
    public struct Checkpoint: Copyable, Sendable {
        @usableFromInline
        package let head: Index<S.Element>

        @usableFromInline
        package let count: Index<S.Element>.Count

        @inlinable
        package init(head: Index<S.Element>, count: Index<S.Element>.Count) {
            self.head = head
            self.count = count
        }
    }
}

extension Buffer.Ring.Checkpoint: Comparable where S: ~Copyable {
    /// Two checkpoints are equal when they capture the same remaining count.
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.count == rhs.count
    }

    /// Orders by consumption position: a higher count (earlier in consumption) sorts first.
    @inlinable
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.count > rhs.count
    }
}
