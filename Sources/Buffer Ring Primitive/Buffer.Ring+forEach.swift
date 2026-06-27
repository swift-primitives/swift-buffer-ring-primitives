import Affine_Primitives_Standard_Library_Integration
import Ordinal_Primitives_Standard_Library_Integration
public import Store_Protocol_Primitives

// MARK: - ~Copyable forEach for Ring

extension Buffer.Ring where S: ~Copyable {
    /// Calls `body` with a borrow of each element in FIFO order.
    @inlinable
    public func forEach(_ body: (borrowing S.Element) -> Void) {
        header.initialization.forEach { range in
            var slot = range.lowerBound
            while slot < range.upperBound {
                body(storage[slot])
                slot += .one
            }
        }
    }
}
