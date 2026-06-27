# ``Buffer_Ring_Primitives``

The ring buffer discipline over `Buffer` — growable, bounded, inline, and
small-buffer-optimized circular storage for noncopyable elements.

## Overview

`Buffer.Ring` is circular, count-tracked storage with front/back element access and
double-ended push/pop operations. Logical index 0 is the front of the ring; the physical
slot wraps around via modular arithmetic, so neither end requires shifting. It comes in four
capacity flavours that share one API and all support noncopyable (`~Copyable`) element types:

- **`Buffer.Ring`** — heap-backed and growable.
- **`Buffer.Ring.Bounded`** — heap-backed with a fixed maximum capacity (push returns the rejected element when full).
- **`Buffer.Ring.Inline<n>`** — fixed inline storage, no heap allocation.
- **`Buffer.Ring.Small<n>`** — small-buffer optimization: inline until it overflows, then spills to the heap.

Importing `Buffer_Ring_Primitives` brings in every variant. A consumer that needs only one
variant imports that variant's module directly — for example `Buffer_Ring_Small_Primitives`.

```swift
import Buffer_Ring_Primitives

var ring = Buffer<Storage<Int>.Contiguous<Memory.Heap<Int>>>.Ring(minimumCapacity: 4)
ring.push.back(1)
ring.push.front(0)
let front = ring.peek.front       // 0
_ = ring.pop.back()               // 1
```

## Topics

### Scope

- <doc:Buffer-Ring-Scope>
