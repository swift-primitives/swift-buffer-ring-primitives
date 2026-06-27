@_exported public import Buffer_Ring_Bounded_Primitives
// `Buffer Ring Primitives` is the base conformances module AND the [MOD-005] umbrella:
// it re-exports the package's OWN modules so `import Buffer_Ring_Primitives` surfaces
// the whole package. Exports narrowed at the ADT-families ring cleanup (seat-authorized
// 2026-06-10): no external re-exports — consumers import Sequence/Iterable vocabulary
// explicitly.
@_exported public import Buffer_Ring_Primitive
