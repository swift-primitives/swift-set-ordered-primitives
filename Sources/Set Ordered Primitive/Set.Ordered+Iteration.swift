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
public import Buffer_Linear_Primitive
public import Buffer_Linear_Primitives

extension Set.Ordered where Element: Copyable {

    /// A single-pass consuming iterator in insertion order. Witness for `Sequenceable`.
    @inlinable
    public consuming func makeIterator() -> Buffer<Element>.Linear.Scalar {
        buffer.makeIterator()
    }
}
