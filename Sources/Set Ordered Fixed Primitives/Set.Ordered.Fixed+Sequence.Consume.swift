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

import Index_Primitives
import Sequence_Primitives
public import Set_Primitives
public import Set_Ordered_Fixed_Primitive
public import Buffer_Linear_Bounded_Primitive
public import Buffer_Linear_Bounded_Primitives

// MARK: - consume() Implementation
//
// Set.Ordered.Fixed delegates consuming iteration entirely to Buffer.Linear.Bounded.
// Same swap pattern as Set.Ordered — buffer owns the full pipeline. The swap reaches
// storage through the `package` `takeBuffer()` accessor in the type module (no
// underscored window).

extension Set_Primitives.Set.Ordered.Fixed where Element: Copyable {
    /// Returns a consuming view: `.consume().forEach { }`
    ///
    /// ```swift
    /// let set = Set<Int>.Ordered.Fixed(capacity: Index<Int>.Count(10))
    /// set.consume().forEach { element in
    ///     // element is owned
    /// }
    /// ```
    ///
    /// - Complexity: O(1) to create the view. O(1) per element during iteration.
    // Non-`@inlinable` ([MOD-036] refined-C): cold conformance reaching storage
    // through the `package` `takeBuffer()` accessor (no underscored window).
    public consuming func consume() -> Sequence.Consume.View<Element, Buffer<Element>.Linear.Bounded.ConsumeState> {
        takeBuffer().consume()
    }
}
