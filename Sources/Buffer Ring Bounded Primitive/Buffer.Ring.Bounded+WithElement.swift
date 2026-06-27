import Affine_Primitives_Standard_Library_Integration
import Ordinal_Primitives_Standard_Library_Integration
public import Store_Protocol_Primitives

// MARK: - Borrowing Element Access for Ring.Bounded (~Copyable)

extension Buffer.Ring.Bounded where S: ~Copyable {

    /// Calls `body` with a borrow of the front element.
    ///
    /// - Precondition: The buffer is not empty.
    @inlinable
    public func withFront<R: ~Copyable>(_ body: (borrowing S.Element) -> R) -> R {
        return body(storage[header.head])
    }

    /// Calls `body` with a borrow of the back element.
    ///
    /// - Precondition: The buffer is not empty.
    @inlinable
    public func withBack<R: ~Copyable>(_ body: (borrowing S.Element) -> R) -> R {
        return body(
            storage[
                Index.Modular.advanced(
                    header.head,
                    by: Index<S.Element>.Offset(fromZero: header.count.subtract.saturating(.one).map(Ordinal.init)),
                    capacity: header.capacity
                )
            ]
        )
    }
}
