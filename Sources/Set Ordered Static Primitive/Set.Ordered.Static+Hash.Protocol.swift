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

// MARK: - Hash.Protocol Conformance (closes the Small/Static vestigial gap)
//
// base/Fixed conform to `Hash.Protocol`; Small/Static lacked it with no principled
// copyability/storage reason — genuinely vestigial (the ×16 exemplar completes, it
// doesn't just de-dup). `==`/`hash` delegate over the span via `Span:
// Equation.Protocol` / `Span: Hash.Protocol` (equation-/hash-primitives Standard
// Library Integration), identical to base/Fixed; `~Copyable`-safe (borrowing
// comparison/hashing, never copies an element out of the span).

extension Set.Ordered.Static: Hash.`Protocol` {
    /// Element-wise equality in insertion order, over the span.
    @inlinable
    public static func == (lhs: borrowing Self, rhs: borrowing Self) -> Bool {
        lhs.span == rhs.span
    }

    /// Hashes the count and elements in insertion order, over the span.
    @inlinable
    public borrowing func hash(into hasher: inout Hasher) {
        span.hash(into: &hasher)
    }
}
