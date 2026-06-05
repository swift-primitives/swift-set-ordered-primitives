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
public import Storage_Small_Primitives
public import Storage_Primitive
public import Buffer_Linear_Primitive
public import Buffer_Linear_Primitives
public import Set_Ordered_Small_Primitive

// MARK: - Buildable Conformance (builder-primitives' generic build capability)
//
// `Set.Ordered.Small` is small-buffer-optimized but grows beyond its inline
// threshold by spilling to the heap — a growable discipline — so it conforms
// builder-primitives' `Buildable` (`Initiable`'s `init()` + the neutral `add`),
// gaining the free `Set<E>.Ordered.Small { … }` DSL and inheriting the
// Self-returning algebra from `Set Algebra Primitives` (`Set.Protocol & Buildable`).
// `init()` is the empty-set witness; `add` delegates to `insert`, discarding the
// `(inserted, index)` report (set dedup is the family grow semantics).

extension Set.Ordered.Small: Buildable where Element: Copyable {
    @inlinable
    public mutating func add(_ element: consuming Element) {
        _ = self.insert(element)
    }
}
