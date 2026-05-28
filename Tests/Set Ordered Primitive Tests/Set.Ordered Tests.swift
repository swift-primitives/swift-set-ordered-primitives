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

import Set_Ordered_Primitive
import Hash_Primitives_Standard_Library_Integration
import Index_Primitives_Test_Support
import Testing

// [TEST-033] per-source-target test target for the `Set Ordered Primitive` TYPE
// module (base / dynamic-heap variant). Exercises the co-located hot-op surface
// (membership, ordering, access, insert/remove, count) in isolation from the
// umbrella — proving the type module's witness emission independently.
// Stable-behavior only; the iteration-conformance surface (Sequence/Sequenceable/
// consume/Sequence.Drain) is gated to Track 3 and tested via the umbrella.
//
// Two test-authoring constraints for this (generic) data structure — see the
// recipe note (Audits/mod-036-type-ops-boundary.md) and [INST-TEST-013]:
//   1. `Set.Ordered` is generic, so the extension-nested `@Suite` form is
//      compiler-infeasible (the `@Suite` macro emits `static` stored properties +
//      `@section`/`@used`, rejected in a generic context). A top-level `@Suite`
//      struct is used instead.
//   2. The base is conditionally `~Copyable`; `#expect` requires a `Copyable`
//      receiver, so every accessor/op result is bound to a Copyable local before
//      asserting (never `#expect(s.foo)` directly). The template is kept uniform
//      with the `~Copyable` variants for ×16 fan-out fidelity.

@Suite("Set.Ordered — type module")
struct SetOrderedTypeTests {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
}

// MARK: - Unit

extension SetOrderedTypeTests.Unit {
    @Test func `insert and contains`() {
        var s = Set<Int>.Ordered()
        let empty = s.isEmpty
        #expect(empty)
        let (inserted, index) = s.insert(1)
        #expect(inserted)
        #expect(index == 0)
        let hasOne = s.contains(1)
        #expect(hasOne)
        let count = s.count
        #expect(count == 1)
    }

    @Test func `duplicate insert is rejected`() {
        var s = Set<Int>.Ordered()
        s.insert(7)
        let (inserted, index) = s.insert(7)
        #expect(!inserted)
        #expect(index == 0)
        let count = s.count
        #expect(count == 1)
    }

    @Test func `insertion order is preserved`() {
        var s = Set<Int>.Ordered()
        s.insert(10)
        s.insert(20)
        s.insert(30)
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

    @Test func `remove returns the element and preserves survivor order`() {
        var s = Set<Int>.Ordered()
        s.insert(1)
        s.insert(2)
        s.insert(3)
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

extension SetOrderedTypeTests.`Edge Case` {
    @Test func `index lookup reports position and absence`() {
        var s = Set<Int>.Ordered()
        s.insert(10)
        s.insert(20)
        s.insert(30)
        let i20 = s.index(20)
        #expect(i20 == 1)
        let i40 = s.index(40)
        #expect(i40 == nil)
        let has99 = s.contains(99)
        #expect(!has99)
    }

    @Test func `element(at:) throws out of range and reports absence`() {
        var s = Set<Int>.Ordered()
        s.insert(1)
        s.insert(2)
        s.insert(3)
        #expect(throws: Set<Int>.Ordered.Error.self) {
            _ = try s.element(at: 10)
        }
        let e5 = try? s.element(at: 5)
        #expect(e5 == nil)
    }
}

// MARK: - Integration

extension SetOrderedTypeTests.Integration {
    @Test func `interleaved insert and remove preserves order`() {
        var s = Set<Int>.Ordered()
        for value in 1...5 {
            s.insert(value)
        }
        s.remove(2)
        s.remove(4)
        let count = s.count
        #expect(count == 3)
        let e0 = s[0]
        let e1 = s[1]
        let e2 = s[2]
        #expect(e0 == 1)
        #expect(e1 == 3)
        #expect(e2 == 5)
    }
}
