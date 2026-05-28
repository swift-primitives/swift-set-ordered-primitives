# Set Ordered Primitives

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

The **ordered set discipline** over the `Set` namespace: insertion-order-preserving sets with O(1) membership testing and set algebra, in four capacity flavours — growable, fixed, inline, and small-buffer-optimized.

---

## Quick Start

```swift
import Set_Ordered_Primitives

// Growable, heap-backed — insertion order is preserved exactly.
var plugins: Set<String>.Ordered = .init()
plugins.insert("analytics")
plugins.insert("logging")
plugins.insert("analytics")  // duplicate — ignored, index unchanged

// Iteration always reflects insertion order.
plugins.forEach { print($0) }  // analytics, logging

// Set algebra preserves order from the receiver.
var required: Set<String>.Ordered = .init()
required.insert("logging")
required.insert("security")

let active = plugins.algebra.union(required)
// active: ["analytics", "logging", "security"]

let missing = required.algebra.subtract(plugins)
// missing: ["security"]

// Result builder — control-flow support, duplicates collapsed.
let tags = Set<String>.Ordered {
    "swift"
    "open-source"
    "swift"   // ignored
}
```

Union and subtract preserve the receiver's insertion order for shared elements, then append elements from the other set that are not yet present — giving set algebra a deterministic, reproducible element sequence that `Swift.Set` cannot provide.

---

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/swift-primitives/swift-set-ordered-primitives.git", branch: "main")
]
```

```swift
.target(
    name: "App",
    dependencies: [
        // The umbrella — the whole package.
        .product(name: "Set Ordered Primitives", package: "swift-set-ordered-primitives"),
        // …or depend on just the variant you use, e.g.:
        // .product(name: "Set Ordered Small Primitives", package: "swift-set-ordered-primitives"),
    ]
)
```

The package is pre-1.0 — depend on `branch: "main"` until `0.1.0` is tagged. Requires Swift 6.3
and macOS 26 / iOS 26 / tvOS 26 / watchOS 26 / visionOS 26 (or the matching Linux toolchain).

---

## Variants

| Type | Storage | Reach for it when |
|------|---------|-------------------|
| `Set<Element>.Ordered` | heap, growable | the size isn't known up front |
| `Set<Element>.Ordered.Fixed` | heap, fixed maximum | there is a hard capacity ceiling; throws on overflow |
| `Set<Element>.Ordered.Static<n>` | inline, compile-time capacity | the maximum is small and known at compile time; no heap allocation |
| `Set<Element>.Ordered.Small<n>` | inline → heap | usually small, occasionally larger (SBO); hash table activates only on spill |

Every variant is generic over `Element`, including noncopyable element types where the storage model permits.

---

## Architecture

Each variant ships as **two modules**: a lean type module (the value type, its initializers, and the hot insert/remove/algebra surface) and a conformances module (`Sequence` / `Collection` conformances, kept separate so they never constrain noncopyable use). Importing `Set Ordered Primitives` (the umbrella product) brings in the whole package — all four variants plus their conformances. Importing a single variant product such as `Set Ordered Small Primitives` brings in only that variant.

---

## Related Packages

- `swift-set-primitives` — the `Set` namespace, `Hash.Protocol`, and set-domain vocabulary this package builds on.
- `swift-buffer-linear-primitives` — the `Buffer.Linear` storage substrate used by every variant.
- `swift-hash-table-primitives` — the `Hash.Table` backing used for O(1) membership lookup.

---

## License

Apache License 2.0. See [LICENSE](LICENSE.md) for details.
