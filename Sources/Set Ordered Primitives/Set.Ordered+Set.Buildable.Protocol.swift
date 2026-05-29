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

// MARK: - Set.Buildable.Protocol Conformance (growable refinement)
//
// `Set.Ordered` is a growable discipline, so it conforms the constructive
// refinement `Set.Buildable.`Protocol`` and thereby inherits the Self-returning
// algebra (`union` / `intersection` / `subtracting` / `symmetricDifference`)
// from `Set Algebra Primitives` for free. `init()` + `insert` (Copyable
// elements) are the witnesses. Bounded variants (`Set.Ordered.Fixed` /
// `.Static`) do NOT conform — a Self-returning constructive op on a bounded set
// could silently overflow (model §4.2).

extension Set.Ordered: Set.Buildable.`Protocol` where Element: Copyable {}
