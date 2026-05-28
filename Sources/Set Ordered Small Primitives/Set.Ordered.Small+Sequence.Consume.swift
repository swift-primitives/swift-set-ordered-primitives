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

import Sequence_Primitives
public import Set_Primitives
public import Set_Ordered_Small_Primitive
public import Buffer_Linear_Small_Primitive
public import Buffer_Linear_Primitive

// MARK: - consume() Implementation
//
// Set.Ordered.Small delegates consuming iteration to Buffer.Linear.Small.
// The composed buffer handles both inline and heap paths internally. The buffer is
// reached through the `package` `takeBuffer()` accessor in the type module (no
// underscored window); returning the buffer destroys the spill-only hash table.

extension Set_Primitives.Set.Ordered.Small where Element: Copyable {
    /// Returns a consuming view: `.consume().forEach { }`
    ///
    /// Delegates to `Buffer<Element>.Linear.Small.consume()` which handles
    /// both inline and heap storage paths internally.
    ///
    /// ```swift
    /// let set = Set<Int>.Ordered.Small<4>([1, 2, 3])
    /// set.consume().forEach { element in
    ///     // element is owned, set is consumed
    /// }
    /// ```
    ///
    /// - Complexity: O(n) to create the view (copies inline elements). O(1) per element during iteration.
    // Non-`@inlinable` ([MOD-036] refined-C): cold conformance reaching storage
    // through the `package` `takeBuffer()` accessor (no underscored window).
    // `Buffer.Linear.Small.consume()` is `mutating`, so the surrendered buffer is
    // bound to a `var` before the consume call.
    public consuming func consume() -> Sequence.Consume.View<Element, Buffer<Element>.Linear.Small<inlineCapacity>.ConsumeState> {
        var consumeBuffer = takeBuffer()
        return consumeBuffer.consume()
    }
}
