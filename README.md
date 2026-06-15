# Set Ordered Primitives

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)
[![CI](https://github.com/swift-primitives/swift-set-ordered-primitives/actions/workflows/ci.yml/badge.svg)](https://github.com/swift-primitives/swift-set-ordered-primitives/actions/workflows/ci.yml)

`Set<S>.Ordered` — the order-preserving set discipline over an ordered-hashed storage **column**. Like `Set<S>` it is an insertion-ordered hash set with O(1) average-case membership, but it additionally exposes **positional access**: every member has a stable index into the insertion order, so you can ask for a member's position with `index(of:)` and read by position with `set[index]`. As with the rest of the family, copyability flows from the column — move-only by default, copy-on-write via a `Shared` column.

---

## Key Features

- **Insertion order preserved** — `forEach` and positional reads follow the order members were first inserted; re-inserting an existing member is a no-op that keeps its position.
- **Positional access** — `index(of:)` returns a member's stable index; `set[index]` reads by position (a plain `Set` is membership-only).
- **Column-generic storage** — composes the ordered-hashed column; the backing is a type parameter, not a separate type per capacity policy.
- **Copyability from the column** — move-only by default (zero-cost), opt-in copy-on-write via a `Shared` column.

---

## Quick Start

```swift
import Set_Ordered_Primitives
import Set_Primitive
import Column_Primitives
import Hash_Indexed_Primitive
import Hash_Primitives_Standard_Library_Integration

// Move-only by default, over the ordered-hashed column:
var plugins = Set<Hash.Indexed<Column.Heap<String>>>.Ordered()
plugins.insert("analytics")
plugins.insert("logging")
plugins.insert("analytics")              // already present — ignored
plugins.forEach { print($0) }            // analytics, logging — insertion order

// Unlike a plain set, members are addressable by position:
if let i = plugins.index(of: "logging") {
    _ = plugins[i]                       // "logging"
}
```

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
        .product(name: "Set Ordered Primitives", package: "swift-set-ordered-primitives")
    ]
)
```

The package is pre-1.0 — depend on `branch: "main"` until `0.1.0` is tagged. Requires Swift 6.3 and macOS 26 / iOS 26 / tvOS 26 / watchOS 26 / visionOS 26 (or the corresponding Linux / Windows toolchain).

---

## Architecture

| Product | Contents | When to import |
|---------|----------|----------------|
| `Set Ordered Primitives` | Umbrella — `Set.Ordered` and its conformances | Most consumers |
| `Set Ordered Primitive` | The `Set.Ordered` value type, without the conformances | Move-only / minimal-surface use |

---

## Platform Support

| Platform         | CI  | Status       |
|------------------|-----|--------------|
| macOS 26         | Yes | Full support |
| Linux            | Yes | Full support |
| Windows          | Yes | Full support |
| iOS/tvOS/watchOS | —   | Supported    |
| Swift Embedded   | —   | Pending (nightly-toolchain follow-up) |

---

## Related Packages

- [`swift-set-primitives`](https://github.com/swift-primitives/swift-set-primitives) — the `Set` namespace, the membership contract, and the base `Set<S>` this discipline extends.
- [`swift-set-algebra-primitives`](https://github.com/swift-primitives/swift-set-algebra-primitives) — relational and constructive algebra (`isSubset`, `union`, `intersection`, …) over any `Set.Protocol` conformer.
- [`swift-hash-table-primitives`](https://github.com/swift-primitives/swift-hash-table-primitives) — the `Hash.Indexed` position-index engine the column is built on.
- [`swift-column-primitives`](https://github.com/swift-primitives/swift-column-primitives) — the column vocabulary (`Hash.Indexed`, `Column.Heap`, …) the set composes.

---

## Community

<!-- BEGIN: discussion -->
<!-- END: discussion -->

## License

Apache 2.0. See [LICENSE.md](LICENSE.md).
