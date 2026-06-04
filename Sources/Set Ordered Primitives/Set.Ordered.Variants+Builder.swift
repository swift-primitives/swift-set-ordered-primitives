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

public import Builder_Primitives
public import Index_Primitives
public import Set_Ordered_Primitive

// MARK: - Bounded-variant `@Builder` DSL inits (one-line per variant)
//
// Growable variants (`Set.Ordered`, `Set.Ordered.Small`) inherit the free
// `init(@Builder …)` default from builder-primitives' `Buildable` — their
// boilerplate is gone. Bounded variants are NOT `Buildable` (a bounded
// `Self`-returning finalize can overflow — capability model §4.2), so each
// carries a thin THROWING `init(@Builder …)` that drains builder-primitives'
// shared `Buffer<Storage<Element>.Heap>.Linear` accumulator through the variant's own throwing
// `insert`. The `try` at the call site (`try Set.Static { … }`) makes the
// overflow explicit — the same shape the throwing `insert` already has. `Fixed`
// additionally takes a runtime `capacity:` (no no-arg `init()`).
//
// There is no set-specific `@Set.Builder` result-builder: the ecosystem-wide
// `@Builder` grammar from builder-primitives is the single DSL for every variant
// (`builder-primitives × set-primitives`). For-loops in the body are unsupported
// by that grammar (its partial result is `~Copyable`); use a single `Sequence`
// expression (`try Set.Static { 1...5 }`) instead.

extension Set.Ordered.Static where Element: Copyable {
    /// Constructs a fixed-capacity inline ordered set from a `@Builder` closure.
    /// Insertion order preserved; duplicates collapse. Overflow throws
    /// `__SetOrderedInlineError`.
    public init(
        @Builder<Element> _ content: () -> Buffer<Storage<Element>.Heap>.Linear
    ) throws(__SetOrderedInlineError<Element>) {
        var buffer = content()
        self.init()
        while !buffer.isEmpty {
            _ = try self.insert(buffer.remove.first())
        }
    }
}

extension Set.Ordered.Fixed where Element: Copyable {
    /// Constructs a heap-allocated bounded ordered set from a `@Builder` closure.
    /// Capacity at the outer init (runtime param — the one non-free case);
    /// overflow throws `__SetOrderedFixedError`.
    public init(
        capacity: Index<Element>.Count,
        @Builder<Element> _ content: () -> Buffer<Storage<Element>.Heap>.Linear
    ) throws(__SetOrderedFixedError<Element>) {
        var fixed = try Set<Element>.Ordered.Fixed(capacity: capacity)
        var buffer = content()
        while !buffer.isEmpty {
            _ = try fixed.insert(buffer.remove.first())
        }
        self = fixed
    }
}
