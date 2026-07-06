import Affine_Primitives_Standard_Library_Integration
import Ordinal_Primitives_Standard_Library_Integration
public import Storage_Protocol_Primitives
public import Store_Ledgered_Primitives
public import Store_Protocol_Primitives

// MARK: - Static Operations for ~Copyable Elements on the substrate
//
// The element-moving operations (push/pop front/back, deinitialize-all) use ONLY
// the inherited element-store surface (`initialize(at:to:)` / `move(at:)`) plus
// the lifted `storage.initialization` sync (ASK-1 (b′), 2026-06-04). They are
// therefore seam-generic over any LEDGERED store (`S: Store.`Protocol`` for the
// slot transitions + `Store.Ledgered.`Protocol`` for the settable `initialization`
// ledger the wrapped ring must overwrite) — this is the [DS-029] FORM-1 spelling
// (seam-generic, W3): the bodies touch no heap-specific surface, so one extension
// serves every ledgered column (heap, small, inline, bounded). The storage is
// threaded `inout S` (the buffer's own field, passed `&storage`). Allocation /
// growth / CoW need the column's own `create` and stay [DS-029] FORM-2
// (allocation-generic pin) in `Buffer.Ring+Operations.swift` /
// `Buffer.Ring Copyable.swift`.

extension Buffer.Ring where S: ~Copyable {

    // MARK: Push Back

    /// Writes element at the tail position `(head + count) mod capacity`.
    ///
    /// - Precondition: `header.count < header.capacity` (not full).
    /// - Note: Uses `Modular.advanced` per H1 — no manual `%`.
    @inlinable
    public static func pushBack(
        _ element: consuming S.Element,
        header: inout Header,
        storage: inout S
    ) where S: Store.Ledgered.`Protocol` {
        let countOffset = Index<S.Element>.Offset(fromZero: header.count.map(Ordinal.init))
        let tail = Index.Modular.advanced(header.head, by: countOffset, capacity: header.capacity)

        storage.initialize(at: tail, to: consume element)

        header.count = header.count.add.saturating(.one)

        storage.initialization = header.initialization
    }

    // MARK: Pop Front

    /// Removes and returns the element at head.
    ///
    /// - Precondition: `header.count > 0` (not empty).
    /// - Note: Uses `Modular.successor` per H1 — no manual `%`.
    @inlinable
    public static func popFront(
        header: inout Header,
        storage: inout S
    ) -> S.Element where S: Store.Ledgered.`Protocol` {
        let element = storage.move(at: header.head)

        header.head = Index.Modular.successor(of: header.head, capacity: header.capacity)

        header.count = header.count.subtract.saturating(.one)

        storage.initialization = header.initialization

        return element
    }

    // MARK: Push Front

    /// Writes element at `(head - 1) mod capacity`.
    ///
    /// - Precondition: `header.count < header.capacity` (not full).
    /// - Note: Uses `Modular.predecessor` per H1 — no manual `%`.
    @inlinable
    public static func pushFront(
        _ element: consuming S.Element,
        header: inout Header,
        storage: inout S
    ) where S: Store.Ledgered.`Protocol` {
        header.head = Index.Modular.predecessor(of: header.head, capacity: header.capacity)

        storage.initialize(at: header.head, to: consume element)

        header.count = header.count.add.saturating(.one)

        storage.initialization = header.initialization
    }

    // MARK: Pop Back

    /// Removes and returns the most recently enqueued element (the one at
    /// the back of the ring).
    ///
    /// - Precondition: `header.count > 0` (not empty).
    @inlinable
    public static func popBack(
        header: inout Header,
        storage: inout S
    ) -> S.Element where S: Store.Ledgered.`Protocol` {
        let newCount = header.count.subtract.saturating(.one)
        let lastOffset = Index<S.Element>.Offset(fromZero: newCount.map(Ordinal.init))
        let lastSlot = Index.Modular.advanced(header.head, by: lastOffset, capacity: header.capacity)

        let element = storage.move(at: lastSlot)

        header.count = newCount

        storage.initialization = header.initialization

        return element
    }

    // MARK: Logical to Physical

    /// Maps logical index (0 = front of buffer) to physical storage slot.
    @inlinable
    public static func physicalSlot(
        forLogical logicalIndex: Index<S.Element>,
        header: Header
    ) -> Index<S.Element> {
        Index.Modular.physical(
            forLogical: logicalIndex,
            head: header.head,
            capacity: header.capacity
        )
    }

    // MARK: Deinitialize All

    /// Deinitializes all elements tracked by the header.
    ///
    /// Drains front-to-back via `popFront` — the inherited-element-store transition
    /// (`move(at:)`) per slot; dropping each returned ~Copyable value deinitializes
    /// it (mirrors the seam idiom `_ = move(at:)`, the
    /// slab-reference generic-substrate idiom). Reusing `popFront` keeps the modular
    /// head/count arithmetic in one place and the op seam-generic over
    /// `S: Store.Ledgered.`Protocol`` (no reach into a substrate-only ranged `deinitialize`).
    @inlinable
    public static func deinitializeAll(
        header: inout Header,
        storage: inout S
    ) where S: Store.Ledgered.`Protocol` {
        while !header.isEmpty {
            _ = popFront(header: &header, storage: &storage)
        }
        header.head = .zero
        storage.initialization = .empty
    }
}
