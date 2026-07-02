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

// Set Ordered Primitive declares the order-facing discipline: the hoisted,
// bound-free carrier `__SetOrdered<S: ~Copyable>` ([DS-025]), its
// `Set<E>.Ordered` front door (a [DS-028] nest alias on the `__Set` carrier), the
// pinned construction trio, and the S5 `Equatable`/`Hashable` carriers. The
// generic ordered-read surface and the pinned membership/ordered ops live in the
// umbrella target. Zero re-exports here (leg-8 narrow-exports standard): the
// column vocabulary is the dependency's surface, not this package's.
