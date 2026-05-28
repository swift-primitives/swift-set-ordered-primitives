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

import Set_Ordered_Static_Primitive
import Hash_Primitives_Standard_Library_Integration
import Index_Primitives_Test_Support
import Testing

// [TEST-033] per-source-target test target for the `Set Ordered Static Primitive`
// TYPE module (inline-storage / fixed-capacity throw-on-overflow variant).
// Exercises the co-located hot-op surface (membership, ordering, access,
// insert/remove, count, capacity saturation) in isolation from the umbrella —
// proving the type module's witness emission independently. Stable-behavior only;
// the iteration-conformance surface (Sequence/Sequenceable/consume/Sequence.Drain)
// is gated to Track 3 and tested via the umbrella.
//
// Three test-authoring constraints for this (generic, `~Copyable`) data structure
// — see the recipe note (Audits/mod-036-type-ops-boundary.md) and [INST-TEST-013]:
//   1. `Set.Ordered.Static<capacity>` is generic, so the extension-nested `@Suite`
//      form is compiler-infeasible (the `@Suite` macro emits `static` stored
//      properties + `@section`/`@used`, rejected in a generic context). A
//      top-level `@Suite` struct is used instead.
//   2. The variant is unconditionally `~Copyable`; `#expect` requires a `Copyable`
//      receiver, so every accessor/op result is bound to a Copyable local before
//      asserting, and the throw-on-overflow edge is asserted via `do`/`catch`
//      (not an `#expect(throws:)` closure) so the `~Copyable` set is mutated
//      in-scope, not captured by the closure.
//   3. Subscript and `element(at:)` are dual-overloaded (`Index<Element>` and
//      `Index<Element>.Bounded<capacity>`), so raw integer-literal access is
//      ambiguous; ordering is checked through the `Bounded` index returned by
//      `insert` and through `first`/`last`.

@Suite("Set.Ordered.Static — type module")
struct SetOrderedStaticTypeTests {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
}

// MARK: - Unit

extension SetOrderedStaticTypeTests.Unit {
    @Test func `insert and contains within capacity`() throws {
        var s = Set<Int>.Ordered.Static<4>()
        let empty = s.isEmpty
        #expect(empty)
        let full = s.isFull
        #expect(!full)
        let (inserted, i) = try s.insert(1)
        #expect(inserted)
        let e = s[i]
        #expect(e == 1)
        let hasOne = s.contains(1)
        #expect(hasOne)
        let count = s.count
        #expect(count == 1)
    }

    @Test func `duplicate insert is rejected`() throws {
        var s = Set<Int>.Ordered.Static<4>()
        try s.insert(7)
        let (inserted, _) = try s.insert(7)
        #expect(!inserted)
        let count = s.count
        #expect(count == 1)
    }

    @Test func `insertion order is preserved`() throws {
        var s = Set<Int>.Ordered.Static<4>()
        let (_, i0) = try s.insert(10)
        let (_, i1) = try s.insert(20)
        let (_, i2) = try s.insert(30)
        let e0 = s[i0]
        let e1 = s[i1]
        let e2 = s[i2]
        #expect(e0 == 10)
        #expect(e1 == 20)
        #expect(e2 == 30)
        let first = s.first
        let last = s.last
        #expect(first == 10)
        #expect(last == 30)
    }

    @Test func `remove returns the element and preserves survivor order`() throws {
        var s = Set<Int>.Ordered.Static<4>()
        try s.insert(1)
        try s.insert(2)
        try s.insert(3)
        let removed = s.remove(2)
        #expect(removed == 2)
        let hasTwo = s.contains(2)
        #expect(!hasTwo)
        let count = s.count
        #expect(count == 2)
        let first = s.first
        let last = s.last
        #expect(first == 1)
        #expect(last == 3)
    }
}

// MARK: - Edge Case

extension SetOrderedStaticTypeTests.`Edge Case` {
    @Test func `fills to capacity, reports isFull, and rejects overflow`() throws {
        // `Set.Ordered.Static` is backed by `Hash.Table.Static`, whose bucket
        // capacity must be a power of two; capacities used here are powers of two.
        var s = Set<Int>.Ordered.Static<4>()
        try s.insert(1)
        try s.insert(2)
        try s.insert(3)
        try s.insert(4)
        let full = s.isFull
        #expect(full)
        var threw = false
        do {
            _ = try s.insert(5)
        } catch {
            threw = true
        }
        #expect(threw)
        let count = s.count
        #expect(count == 4)
    }

    @Test func `reports absence`() throws {
        var s = Set<Int>.Ordered.Static<4>()
        try s.insert(1)
        let has99 = s.contains(99)
        #expect(!has99)
        let absent = s.index(99)
        #expect(absent == nil)
    }
}

// MARK: - Integration

extension SetOrderedStaticTypeTests.Integration {
    @Test func `remove then reinsert below capacity appends to the end`() throws {
        // Stays strictly below capacity: the saturation/overflow boundary is
        // covered by the Edge-case test; reinserting into a set that had been
        // full is out of scope for the stable type-module surface.
        var s = Set<Int>.Ordered.Static<4>()
        try s.insert(1)
        try s.insert(2)
        try s.insert(3)
        let removed = s.remove(2)
        #expect(removed == 2)
        let countAfterRemove = s.count
        #expect(countAfterRemove == 2)
        let has2 = s.contains(2)
        #expect(!has2)
        try s.insert(4)
        let count = s.count
        #expect(count == 3)
        let has4 = s.contains(4)
        #expect(has4)
        let first = s.first
        let last = s.last
        #expect(first == 1)
        #expect(last == 4)
    }
}
