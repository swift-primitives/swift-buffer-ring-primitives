# Buffer Ring Primitives — Scope

What this package is, and what it deliberately leaves to its siblings.

## Overview

`swift-buffer-ring-primitives` provides the **ring (circular) buffer discipline** over the
`Buffer` namespace: count-tracked storage with wrap-around physical slots, front/back element
access, and double-ended push/pop. It defines ``Buffer/Ring`` and its capacity variants:

- ``Buffer/Ring`` — heap-backed and growable.
- `Buffer.Ring.Bounded` — heap-backed with a fixed maximum capacity.
- `Buffer.Ring.Inline` — fixed inline storage, no heap allocation.
- `Buffer.Ring.Small` — small-buffer optimization: inline storage that spills to the heap on overflow.

It is one specialized buffer discipline among siblings — linear, slab, linked, slots, arena,
aligned, unbounded — each its own package. Every variant supports noncopyable (`~Copyable`)
element types.

## Module shape

Each variant ships as **two modules**:

- A **type module** (`Buffer Ring …​ Primitive`, singular) — the lean `~Copyable` value type
  together with the operations that touch its storage internals (push / pop / peek / remove /
  forEach / subscript). Those operations are `@usableFromInline internal` and live next to the
  storage so they remain inlinable across package boundaries.
- A **conformances module** (`Buffer Ring …​ Primitives`, plural) — the `Copyable`-requiring
  protocol conformances (`Sequence`, `Sequence.Drain`), kept in their own
  module so they never constrain the type's noncopyable support.

`Buffer Ring Primitives` is both the base conformances module and the package umbrella:
`import Buffer_Ring_Primitives` brings in the whole package, while a consumer who needs only
one variant imports that variant's module directly.

> This two-module shape is a structural choice — co-locating internal operations with their
> storage is a standard-library-grade technique for keeping a public type lean while its
> operations stay inlinable. It is not a workaround for any compiler defect.

## Core targets

| Module | Form | Holds |
|--------|------|-------|
| `Buffer Ring Primitive` | type | `Buffer.Ring`, `Buffer.Ring.Inline`, `.Header`, `.Header.Cyclic`, `.Checkpoint`, `.Builder`, the Push/Pop/Peek/Remove tag namespaces, internal ops |
| `Buffer Ring Bounded Primitive` | type | `Buffer.Ring.Bounded`, internal ops |
| `Buffer Ring Small Primitive` | type | `Buffer.Ring.Small`, internal ops |
| `Buffer Ring Primitives` | conformances + umbrella | base conformances; re-exports every variant |
| `Buffer Ring Bounded Primitives` | conformances | `Bounded` conformances |
| `Buffer Ring Inline Primitives` | conformances | `Inline` conformances |
| `Buffer Ring Small Primitives` | conformances | `Small` conformances |

## Out of scope

| Capability | Belongs in |
|------------|------------|
| Other buffer disciplines (linear, slab, linked, slots, arena) | `swift-buffer-{linear,slab,linked,slots,arena}-primitives` |
| Aligned and unbounded buffer forms | `swift-buffer-aligned-primitives`, `swift-buffer-unbounded-primitives` |
| The `Buffer` namespace and capacity-growth vocabulary | `swift-buffer-primitives` |
| Raw heap and inline storage substrate | `swift-storage-primitives` |
| The modular (wrap-around) index arithmetic | `swift-cyclic-index-primitives`, `swift-index-primitives` |

## Evaluation rule

Additions are evaluated against this scope. A buffer form that is not the *ring* discipline
extracts to its own sibling package rather than growing this one. A new operation belongs here
only if it operates *on* a ring buffer; storage, growth, and modular-index concerns delegate to
the packages above.
