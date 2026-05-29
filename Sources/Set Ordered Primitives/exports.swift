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

// exports.swift
// Re-export internal modules for consumers.
// Users import Set_Ordered_Primitives and get the ordered-set discipline:
// the base Set.Ordered type + conformances (this module), plus every capacity
// variant (Fixed / Static / Small). Per [MOD-005] the base-ops plural doubles
// as the package umbrella.

@_exported public import Set_Ordered_Primitive
@_exported public import Set_Ordered_Fixed_Primitives
@_exported public import Set_Ordered_Static_Primitives
@_exported public import Set_Ordered_Small_Primitives
// NOTE: set algebra is NOT re-exported here. The ordered-set discipline and the
// set algebra are orthogonal concerns composed at the consumer: a consumer that
// wants algebra over Set.Ordered imports BOTH `Set_Ordered_Primitives` and
// `Set_Algebra_Primitives` (the algebra is a protocol-extension layer over
// `Set.Protocol`, so it applies to Set.Ordered on import). Minimal deps + composition.
