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
public import Set_Ordered_Small_Primitive

// MARK: - Set.Buildable.Protocol Conformance (growable refinement)
//
// `Set.Ordered.Small` is small-buffer-optimized but grows beyond its inline
// threshold by spilling to the heap — a growable discipline — so it conforms
// `Set.Buildable.`Protocol`` and inherits the Self-returning algebra from
// `Set Algebra Primitives`. `init()` + `insert` (Copyable elements) are the
// witnesses.

extension Set.Ordered.Small: Set.Buildable.`Protocol` where Element: Copyable {}
