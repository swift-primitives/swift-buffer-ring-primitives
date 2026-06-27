// Re-export the capability protocol so the inherited `isEmpty` (element-domain
// (D) default) is usable by consumers of every Ring variant without a separate
// `import Buffer_Protocol_Primitives` (MemberImportVisibility).
@_exported public import Buffer_Protocol_Primitives
@_exported public import Cyclic_Index_Primitives
@_exported public import Memory_Allocator_Primitive
// The dense-heap pin spelling `Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>` —
// re-export its constituents so consumers can name the backing without separate imports.
@_exported public import Memory_Heap_Primitives
@_exported public import Memory_Primitives
@_exported public import Storage_Contiguous_Primitives
@_exported public import Store_Initialization_Primitives
