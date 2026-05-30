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
public import Set_Ordered_Primitive

// MARK: - Buildable Conformance (builder-primitives' generic build capability)
//
// `Set.Ordered` is a growable discipline, so it conforms builder-primitives'
// `Buildable` (`Initiable`'s `init()` + the neutral `add`). This (a) gives it the
// free declarative `Set<E>.Ordered { … }` DSL and (b) lets it inherit the
// Self-returning constructive algebra (`union` / `intersection` / `subtracting` /
// `symmetricDifference`) from `Set Algebra Primitives` for free — both composed
// over `Set.Protocol & Buildable`, with NO bundled `Set.Buildable.Protocol`.
//
// `init()` is the empty-set witness (from the core). `add` delegates to the
// family's own `insert`, discarding the `(inserted, index)` report — set dedup is
// the family's grow semantics, applied per element as the builder drains. Bounded
// variants (`Set.Ordered.Fixed` / `.Static`) do NOT conform — a Self-returning
// constructive op on a bounded set could silently overflow (model §4.2).

extension Set.Ordered: Buildable where Element: Copyable {
    @inlinable
    public mutating func add(_ element: consuming Element) {
        _ = self.insert(element)
    }
}
