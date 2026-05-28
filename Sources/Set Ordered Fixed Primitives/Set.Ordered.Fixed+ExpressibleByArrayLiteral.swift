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

import Cardinal_Primitives
import Index_Primitives
public import Set_Primitives
public import Set_Ordered_Fixed_Primitive

// MARK: - ExpressibleByArrayLiteral

extension Set.Ordered.Fixed: ExpressibleByArrayLiteral where Element: Copyable {
    @inlinable
    public init(arrayLiteral elements: Element...) {
        self = try! Self(capacity: .init(Cardinal(UInt(elements.count))))
        for element in elements {
            try! insert(element)
        }
    }
}
