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

// MARK: - removeAll()

extension Set.Ordered where Element: Copyable {
    /// Removes all elements from the set.
    @inlinable
    public mutating func removeAll() {
        clear(keepingCapacity: false)
    }
}
