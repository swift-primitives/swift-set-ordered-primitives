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

// MARK: - Set.Protocol Conformance
//
// Co-located with the type and its hot witnesses ([MOD-036] refined-C): the
// reduced `Set.Protocol` core (`__SetProtocol`) requires only `{contains, count}`
// — both declared in this (type) module — so the membership conformance lives
// here, not in the ops module. This makes the derived `isEmpty` default
// (`count == .zero`) available wherever the type itself is imported.

extension Set.Ordered: Set.`Protocol` where Element: ~Copyable {}
