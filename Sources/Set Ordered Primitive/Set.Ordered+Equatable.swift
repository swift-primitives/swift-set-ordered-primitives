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

// The S5 carrier: the conformance rides the COLUMN (`Shared` is the element-keyed
// carrier — `Shared: Equatable where Element: Equatable` walks the dense prefix in
// order). For an ORDERED set the column's order-sensitive equality IS the semantic:
// two ordered sets are equal exactly when they hold the same members in the same
// insertion order. Move-only columns carry no `Equatable` (no copyable observation),
// so the conformance never fires for them — capability flows from the column.

extension __SetOrdered: Equatable where S: Equatable {
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.store == rhs.store
    }
}
