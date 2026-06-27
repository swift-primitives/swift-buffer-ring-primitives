import Affine_Primitives_Standard_Library_Integration
import Ordinal_Primitives_Standard_Library_Integration

// MARK: - Static Operations for Copyable Elements on Storage.Contiguous<Memory.Heap>

extension Buffer.Ring where S: ~Copyable, S.Element: Copyable {

    /// Copies all elements from source to destination storage in logical order.
    ///
    /// After this call, destination contains elements at slots `0 ..< header.count`
    /// in FIFO order (linearized).
    ///
    /// The ring's initialization may be a disjoint `.two` span, so each source range
    /// is copied to its linearized destination `offset` (supplied by
    /// `initialization.linearize`), packing into `0..<count`. Reads each source slot
    /// via the typed `subscript` and fills the destination via `initialize(at:to:)`
    /// (pointer-free); because `initialize` is mutating, `destination` is `inout`.
    @inlinable
    public static func linearize(
        header: Header,
        source: borrowing Storage<Memory.Allocator<Memory.Heap>>.Contiguous<S.Element>,
        to destination: inout Storage<Memory.Allocator<Memory.Heap>>.Contiguous<S.Element>
    ) {
        header.initialization.linearize { range, offset in
            guard !range.isEmpty else { return }
            var src = range.lowerBound
            var dst = offset
            while src < range.upperBound {
                destination.initialize(at: dst, to: source[src])
                src = src.successor.saturating()
                dst = dst.successor.saturating()
            }
        }
    }

    /// Copies all ring elements to a new storage, linearized to slots `0 ..< count`.
    @inlinable
    public static func copy(
        header: Header,
        source: borrowing Storage<Memory.Allocator<Memory.Heap>>.Contiguous<S.Element>,
        to destination: inout Storage<Memory.Allocator<Memory.Heap>>.Contiguous<S.Element>
    ) {
        linearize(header: header, source: source, to: &destination)
    }
}
