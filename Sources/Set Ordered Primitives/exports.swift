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

// Umbrella per [MOD-005]: re-exports the IN-PACKAGE type target only — zero
// cross-package re-exports (the leg-8 narrow-exports standard). The column
// vocabulary (`Hash.Indexed`, `Shared`, `Buffer`, `Storage`, `Index`, …) is the
// dependencies' surface; consumers that spell columns import those packages
// themselves.

@_exported public import Set_Ordered_Primitive
