import Affine_Primitives_Standard_Library_Integration
import Ordinal_Primitives_Standard_Library_Integration
public import Store_Protocol_Primitives

// MARK: - Borrowing Element Access for Ring (~Copyable)

extension Buffer.Ring where S: ~Copyable {

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

    // MARK: - Direct front/back peek (storage-generic; the `.peek.front`/`.peek.back`
    // Property-view ops stay heap-pinned — generalizing a Property.Borrow.Typed extension
    // over an arbitrary storage S hits the value-generic same-type wall. These mirror the
    // direct pushBack/popFront/removeAll and give consumers a clean named accessor. #12a.

    /// A copy of the front element.
    ///
    /// - Precondition: The buffer is not empty.
    @inlinable
    public func peekFront() -> S.Element where S.Element: Copyable {
        withFront { $0 }
    }

    /// A copy of the back element.
    ///
    /// - Precondition: The buffer is not empty.
    @inlinable
    public func peekBack() -> S.Element where S.Element: Copyable {
        withBack { $0 }
    }
}
