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

// MARK: - Hash.Protocol Conformance

extension Set_Primitives.Set.Ordered.Fixed: Hash.`Protocol` {
    /// Compares two Fixed ordered sets for element-wise equality, over the span
    /// (`Span: Equation.Protocol`, equation-primitives Standard Library Integration).
    @inlinable
    public static func == (lhs: borrowing Self, rhs: borrowing Self) -> Bool {
        lhs.span == rhs.span
    }

    /// Hashes the count and elements of this set, over the span
    /// (`Span: Hash.Protocol`, hash-primitives Standard Library Integration).
    @inlinable
    public borrowing func hash(into hasher: inout Hasher) {
        span.hash(into: &hasher)
    }
}
