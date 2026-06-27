public import Buffer_Ring_Primitives
import Memory_Heap_Primitives
public import Storage_Contiguous_Primitives
import Storage_Protocol_Primitives

// MARK: - Ring

extension Buffer.Ring where S: Store.`Protocol`, S: ~Copyable {
    // The array-convenience init allocates a Heap ring (`Self(minimumCapacity:)`
    // is the Heap-pinned creation path), so it is pinned to the Heap substrate
    // via the init-level same-type generic — the ⑤-(N) replacement for the
    // dropped `ExpressibleByArrayLiteral` conformance (which a generic-substrate
    // type cannot carry; see the W3 fan-out report ASK-2).
    @inlinable
    public init<E>(
        _ elements: [E],
        minimumCapacity: UInt = 0
    ) where S == Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E> {
        let cap: Index<E>.Count = .init(Cardinal(Swift.max(UInt(elements.count), minimumCapacity)))
        var buffer = Self(minimumCapacity: cap)
        for element in elements {
            buffer.push.back(element)
        }
        self = buffer
    }
}
