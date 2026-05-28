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
// Re-exports for Set Ordered Static Primitive (the Static-variant type module).
// Declares Set.Ordered.Static<capacity>; re-exports the base ordered-set type
// module plus the inline backing the Static type composes.

@_exported public import Set_Ordered_Primitive
@_exported public import Buffer_Linear_Primitive
@_exported public import Buffer_Linear_Inline_Primitives
@_exported public import Hash_Table_Primitives
@_exported public import Index_Primitives
