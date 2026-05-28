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

// MARK: - ExpressibleByArrayLiteral

extension Set.Ordered: ExpressibleByArrayLiteral where Element: Copyable {
    @inlinable
    public init(arrayLiteral elements: Element...) {
        self.init(elements)
    }
}
