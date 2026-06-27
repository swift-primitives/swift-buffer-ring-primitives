# Buffer Ring Primitives

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Circular, count-tracked ring buffers over the `Buffer` namespace — double-ended push/pop/peek with O(1) wrap-around at both ends, in growable and fixed-capacity flavours, over copyable and noncopyable elements.

---

## Quick Start

A ring buffer keeps its elements in a fixed physical window and wraps the head and tail around it, so neither the front nor the back ever shifts elements — both ends are O(1). Two variants ship here: `Buffer.Ring` (growable) and `Buffer.Ring.Bounded` (fixed-capacity).

```swift
import Buffer_Ring_Primitives

// These ring buffers pin to heap-backed contiguous storage; alias the spelling once.
typealias Heap<Element> = Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Element>

// A growable, double-ended FIFO. Both ends are O(1): the head and tail wrap around
// a fixed physical window, so neither push nor pop shifts the other elements.
var ring = Buffer<Heap<Int>>.Ring(minimumCapacity: 4)
ring.push.back(1)
ring.push.back(2)
ring.push.front(0)              // prepend in O(1)
let head = ring.peek.front      // 0 — read without removing
let tail = ring.pop.back()      // 2 — remove from the back
```

`Buffer.Ring.Bounded` enforces a hard capacity ceiling. A push into a full buffer is *rejected* and handed straight back, so nothing is silently dropped and the buffer never grows:

```swift
import Buffer_Ring_Primitives

var window = Buffer<Heap<Int>>.Ring.Bounded(minimumCapacity: 2)
window.push.back(10)
window.push.back(20)
let rejected = window.push.back(30)   // Optional(30): the ceiling is reached
precondition(window.isFull && rejected == 30)
```

A ring is also constructible declaratively with a result builder (`Buffer<Heap<Int>>.Ring { 1; 2; 3 }`, where declaration order is the FIFO read order), and drains front-to-back through `drain(_:)` / `removeAll()`. When its element is `Copyable` it conforms to `Sequenceable` for single-pass iteration.

---

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/swift-primitives/swift-buffer-ring-primitives.git", branch: "main")
]
```

```swift
.target(
    name: "App",
    dependencies: [
        // The umbrella — every variant.
        .product(name: "Buffer Ring Primitives", package: "swift-buffer-ring-primitives"),
        // …or depend on a single variant, e.g. just the bounded type:
        // .product(name: "Buffer Ring Bounded Primitive", package: "swift-buffer-ring-primitives"),
    ]
)
```

The package is pre-1.0 — depend on `branch: "main"` until `0.1.0` is tagged.

---

## Architecture

Each variant ships as **two modules**: a lean type module (the `~Copyable` value type plus the operations that touch its storage) and an ops/conformances module (the `Copyable`-requiring `Sequence` conformances, kept separate so they never constrain noncopyable use). The `Buffer Ring Primitives` ops module doubles as the umbrella: it re-exports every variant.

| Product | Target | Purpose |
|---------|--------|---------|
| `Buffer Ring Primitives` | `Sources/Buffer Ring Primitives/` | Umbrella + base ops — re-exports every variant; the `Sequenceable` / `Sequence.Drain` conformances, the scalar iterator, and the `.drain` accessor for `Buffer.Ring`. |
| `Buffer Ring Primitive` | `Sources/Buffer Ring Primitive/` | The lean `Buffer.Ring` type — growable, heap-backed, `~Copyable` — with its push/pop/peek/remove operations, checkpoints, and result builder. |
| `Buffer Ring Bounded Primitive` | `Sources/Buffer Ring Bounded Primitive/` | The lean `Buffer.Ring.Bounded` type — fixed-capacity, heap-backed, `~Copyable` — whose push returns the rejected element when full. |
| `Buffer Ring Bounded Primitives` | `Sources/Buffer Ring Bounded Primitives/` | Bounded ops — the `Sequence.Drain` conformance and `.drain` accessor for `Buffer.Ring.Bounded`. |
| `Buffer Ring Primitives Test Support` | `Tests/Support/` | Re-exports the variant modules for test consumers. |

Foundation-free.

---

## Platform Support

| Platform | Status |
|----------|--------|
| macOS 26 | Full support |
| Linux | Full support |
| Windows | Full support |
| iOS / tvOS / watchOS / visionOS | Supported |

---

## Community

<!-- BEGIN: discussion -->
<!-- Discussion thread created at publication. -->
<!-- END: discussion -->

## License

Apache 2.0. See [LICENSE.md](LICENSE.md).
