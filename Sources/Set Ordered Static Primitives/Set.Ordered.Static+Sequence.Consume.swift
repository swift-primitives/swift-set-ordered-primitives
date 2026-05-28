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
public import Set_Ordered_Static_Primitive
public import Buffer_Linear_Inline_Primitives
public import Buffer_Linear_Primitive

// MARK: - consume() Implementation
//
// Set.Ordered.Static delegates consuming iteration to Buffer.Linear.Inline.
// Direct delegation — no swap needed because Inline.consume() is mutating,
// leaving the buffer empty so the set's deinit is harmless. The buffer is reached
// through the `package` `takeBuffer()` accessor in the type module (no underscored
// window).

extension Set_Primitives.Set.Ordered.Static {
    /// Returns a consuming view: `.consume().forEach { }`
    ///
    /// ```swift
    /// let set = Set<Int>.Ordered.Static<8>([1, 2, 3])
    /// set.consume().forEach { element in
    ///     // element is owned
    /// }
    /// ```
    ///
    /// - Complexity: O(n) to create the view (element transfer). O(1) per element during iteration.
    // Non-`@inlinable` ([MOD-036] refined-C): cold conformance reaching storage
    // through the `package` `takeBuffer()` accessor (no underscored window).
    // `Buffer.Linear.Inline.consume()` is `mutating` (not `consuming`), so the
    // surrendered buffer is bound to a `var` before the consume call.
    public consuming func consume() -> Sequence.Consume.View<Element, Buffer<Element>.Linear.Inline<capacity>.ConsumeState> {
        var consumeBuffer = takeBuffer()
        return consumeBuffer.consume()
    }
}
