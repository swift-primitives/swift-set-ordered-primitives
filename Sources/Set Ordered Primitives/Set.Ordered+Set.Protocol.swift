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

// MARK: - Set.Protocol Conformance
//
// Kept in the ops module ([MOD-036] refined-C): `Set.Protocol` (`__SetProtocol`)
// composes the sequence/collection-family surface declared in this module, so the
// conformance is declared where those requirements are visible.

extension Set.Ordered: Set.`Protocol` {}
