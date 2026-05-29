// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-primitives open source project
//
// Copyright (c) 2024-2026 Coen ten Thije Boonkkamp and the swift-primitives project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

public import Set_Primitives
public import Set_Ordered_Primitive

// MARK: - Bounded-variant `@Set.Builder` DSL inits (one-line per variant)
//
// Growable variants (`Set.Ordered`, `Set.Ordered.Small`) inherit the free
// `init(@Set.Builder …)` default from `Set.Buildable.`Protocol`` — their
// boilerplate is gone. Bounded variants are NOT `Set.Buildable.`Protocol``
// (a bounded `Self`-returning finalize can overflow — capability model §4.2),
// so each carries a thin THROWING `init(@Set.Builder …)` over the hoisted
// family `Set.Builder`. The `try` at the call site (`try Set.Static { … }`)
// makes the overflow explicit — the same shape their throwing `insert` already
// has. `Fixed` additionally takes a runtime `capacity:` (no no-arg `init()`).

extension Set.Ordered.Static where Element: Copyable {
    /// Constructs a fixed-capacity inline ordered set from a `@Set.Builder`
    /// closure. Insertion order preserved; duplicates collapse. Overflow throws
    /// `__SetOrderedInlineError`.
    public init(
        @Set<Element>.Builder _ builder: () -> [Element]
    ) throws(__SetOrderedInlineError<Element>) {
        let elements = builder()
        self.init()
        for element in elements {
            _ = try self.insert(element)
        }
    }
}

extension Set.Ordered.Fixed where Element: Copyable {
    /// Constructs a heap-allocated bounded ordered set from a `@Set.Builder`
    /// closure. Capacity at the outer init (runtime param — the one non-free
    /// case); overflow throws `__SetOrderedFixedError`.
    public init(
        capacity: Index<Element>.Count,
        @Set<Element>.Builder _ builder: () -> [Element]
    ) throws(__SetOrderedFixedError<Element>) {
        var fixed = try Set<Element>.Ordered.Fixed(capacity: capacity)
        let elements = builder()
        for element in elements {
            _ = try fixed.insert(element)
        }
        self = fixed
    }
}
