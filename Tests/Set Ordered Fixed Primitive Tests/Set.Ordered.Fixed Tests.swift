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

import Set_Ordered_Fixed_Primitive
import Hash_Primitives_Standard_Library_Integration
import Index_Primitives_Test_Support
import Testing

// [TEST-033] per-source-target test target for the `Set Ordered Fixed Primitive`
// TYPE module (bounded / throw-on-overflow variant). Exercises the co-located
// hot-op surface (membership, ordering, access, insert/remove, count, capacity
// saturation) in isolation from the umbrella — proving the type module's witness
// emission independently. Stable-behavior only; the iteration-conformance surface
// (Sequence/Sequenceable/consume/Sequence.Drain) is gated to Track 3 and tested
// via the umbrella.
//
// Two test-authoring constraints for this (generic) data structure — see the
// recipe note (Audits/mod-036-type-ops-boundary.md) and [INST-TEST-013]:
//   1. `Set.Ordered.Fixed` is generic, so the extension-nested `@Suite` form is
//      compiler-infeasible (the `@Suite` macro emits `static` stored properties +
//      `@section`/`@used`, rejected in a generic context). A top-level `@Suite`
//      struct is used instead.
//   2. The variant is conditionally `~Copyable`; `#expect` requires a `Copyable`
//      receiver, so every accessor/op result is bound to a Copyable local before
//      asserting (never `#expect(s.foo)` directly). The throw-on-overflow edge is
//      asserted via `do`/`catch` (not an `#expect(throws:)` closure) so the
//      `~Copyable` set is mutated in-scope, not captured by the closure.

@Suite("Set.Ordered.Fixed — type module")
struct SetOrderedFixedTypeTests {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
}

// MARK: - Unit

extension SetOrderedFixedTypeTests.Unit {
    @Test func `insert and contains within capacity`() throws {
        var s = try Set<Int>.Ordered.Fixed(capacity: 4)
        let empty = s.isEmpty
        #expect(empty)
        let full = s.isFull
        #expect(!full)
        let (inserted, index) = try s.insert(1)
        #expect(inserted)
        #expect(index == 0)
        let hasOne = s.contains(1)
        #expect(hasOne)
        let count = s.count
        #expect(count == 1)
    }

    @Test func `duplicate insert is rejected`() throws {
        var s = try Set<Int>.Ordered.Fixed(capacity: 4)
        try s.insert(7)
        let (inserted, _) = try s.insert(7)
        #expect(!inserted)
        let count = s.count
        #expect(count == 1)
    }

    @Test func `insertion order is preserved`() throws {
        var s = try Set<Int>.Ordered.Fixed(capacity: 4)
        try s.insert(10)
        try s.insert(20)
        try s.insert(30)
        let e0 = s[0]
        let e1 = s[1]
        let e2 = s[2]
        #expect(e0 == 10)
        #expect(e1 == 20)
        #expect(e2 == 30)
        let first = s.first
        let last = s.last
        #expect(first == 10)
        #expect(last == 30)
    }

    @Test func `remove returns the element and preserves survivor order`() throws {
        var s = try Set<Int>.Ordered.Fixed(capacity: 4)
        try s.insert(1)
        try s.insert(2)
        try s.insert(3)
        let removed = s.remove(2)
        #expect(removed == 2)
        let hasTwo = s.contains(2)
        #expect(!hasTwo)
        let count = s.count
        #expect(count == 2)
        let e0 = s[0]
        let e1 = s[1]
        #expect(e0 == 1)
        #expect(e1 == 3)
    }
}

// MARK: - Edge Case

extension SetOrderedFixedTypeTests.`Edge Case` {
    @Test func `fills to capacity, reports isFull, and rejects overflow`() throws {
        var s = try Set<Int>.Ordered.Fixed(capacity: 2)
        try s.insert(1)
        try s.insert(2)
        let full = s.isFull
        #expect(full)
        var threw = false
        do {
            _ = try s.insert(3)
        } catch {
            threw = true
        }
        #expect(threw)
        let count = s.count
        #expect(count == 2)
    }

    @Test func `contains and element(at:) report absence`() throws {
        var s = try Set<Int>.Ordered.Fixed(capacity: 4)
        try s.insert(1)
        let has99 = s.contains(99)
        #expect(!has99)
        let e5 = try? s.element(at: 5)
        #expect(e5 == nil)
    }
}

// MARK: - Integration

extension SetOrderedFixedTypeTests.Integration {
    @Test func `insert and remove across the capacity boundary`() throws {
        var s = try Set<Int>.Ordered.Fixed(capacity: 3)
        try s.insert(1)
        try s.insert(2)
        try s.insert(3)
        let fullBefore = s.isFull
        #expect(fullBefore)
        let removed = s.remove(2)
        #expect(removed == 2)
        let fullAfter = s.isFull
        #expect(!fullAfter)
        try s.insert(4)
        let count = s.count
        #expect(count == 3)
        let e0 = s[0]
        let e1 = s[1]
        let e2 = s[2]
        #expect(e0 == 1)
        #expect(e1 == 3)
        #expect(e2 == 4)
    }
}
