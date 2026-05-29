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

import Set_Ordered_Small_Primitive
import Hash_Primitives_Standard_Library_Integration
import Index_Primitives_Test_Support
import Testing

// [TEST-033] per-source-target test target for the `Set Ordered Small Primitive`
// TYPE module. Exercises the co-located hot-op surface (membership, ordering,
// access, spill transition) in isolation from the umbrella — proving the type
// module's witness emission independently. Stable-behavior only; the
// iteration-conformance surface (Sequence/Sequenceable/consume/Sequence.Drain) is
// gated to Track 3 and tested via the umbrella.
//
// Two test-authoring constraints for this (generic, ~Copyable) data structure:
//   1. `Set.Ordered.Small<inlineCapacity>` is generic, so the [INST-TEST-013]
//      extension-nested `@Suite` form is compiler-infeasible (the `@Suite` macro
//      emits `static` stored properties + `@section`/`@used`, rejected in a generic
//      context). A top-level `@Suite` struct is used instead.
//   2. `Set.Ordered.Small` is unconditionally `~Copyable`; the `#expect` macro
//      requires its receiver be `Copyable`, so every accessor/op result is bound to
//      a Copyable local before asserting (never `#expect(s.foo)` directly).

@Suite("Set.Ordered.Small — type module")
struct SetOrderedSmallTypeTests {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
}

// MARK: - Equatable & Hashable (Hash.Protocol — closes the Small/Static vestigial gap)

extension SetOrderedSmallTypeTests.Unit {
    @Test func `Equality (Hash.Protocol, inline)`() {
        var a = Set<Int>.Ordered.Small<8>(); a.insert(1); a.insert(2); a.insert(3)
        var b = Set<Int>.Ordered.Small<8>(); b.insert(1); b.insert(2); b.insert(3)
        var c = Set<Int>.Ordered.Small<8>(); c.insert(3); c.insert(2); c.insert(1)
        let aEqualsB = a == b
        let aNotEqualsC = !(a == c)
        #expect(aEqualsB)
        #expect(aNotEqualsC)  // insertion order is significant
    }

    @Test func `Equality (Hash.Protocol, spilled)`() {
        var a = Set<Int>.Ordered.Small<2>(); a.insert(1); a.insert(2); a.insert(3)
        var b = Set<Int>.Ordered.Small<2>(); b.insert(1); b.insert(2); b.insert(3)
        let aSpilled = a.isSpilled
        let aEqualsB = a == b
        #expect(aSpilled)  // exercises the spilled-storage span
        #expect(aEqualsB)
    }

    @Test func `Hashable (Hash.Protocol)`() {
        var a = Set<Int>.Ordered.Small<8>(); a.insert(1); a.insert(2); a.insert(3)
        var b = Set<Int>.Ordered.Small<8>(); b.insert(1); b.insert(2); b.insert(3)
        let hashA = a.hashValue
        let hashB = b.hashValue
        #expect(hashA == hashB)
    }
}

// MARK: - Unit

extension SetOrderedSmallTypeTests.Unit {
    @Test func `insert and contains within inline capacity`() {
        var s = Set<Int>.Ordered.Small<4>()
        let empty = s.isEmpty
        #expect(empty)
        let spilled = s.isSpilled
        #expect(!spilled)
        let (inserted, index) = s.insert(1)
        #expect(inserted)
        #expect(index == 0)
        let hasOne = s.contains(1)
        #expect(hasOne)
        let count = s.count
        #expect(count == 1)
    }

    @Test func `duplicate insert is rejected`() {
        var s = Set<Int>.Ordered.Small<4>()
        s.insert(7)
        let (inserted, _) = s.insert(7)
        #expect(!inserted)
        let count = s.count
        #expect(count == 1)
    }

    @Test func `insertion order is preserved`() {
        var s = Set<Int>.Ordered.Small<4>()
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
        var s = Set<Int>.Ordered.Small<4>()
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

extension SetOrderedSmallTypeTests.`Edge Case` {
    @Test func `spills past inline capacity and retains all elements in order`() {
        var s = Set<Int>.Ordered.Small<2>()
        s.insert(1)
        s.insert(2)
        let spilledBefore = s.isSpilled
        #expect(!spilledBefore)
        s.insert(3)
        let spilledAfter = s.isSpilled
        #expect(spilledAfter)
        let count = s.count
        #expect(count == 3)
        let h1 = s.contains(1)
        let h2 = s.contains(2)
        let h3 = s.contains(3)
        #expect(h1)
        #expect(h2)
        #expect(h3)
        let e0 = s[0]
        let e2 = s[2]
        #expect(e0 == 1)
        #expect(e2 == 3)
    }

    @Test func `contains and element(at:) report absence`() {
        var s = Set<Int>.Ordered.Small<4>()
        s.insert(1)
        let has99 = s.contains(99)
        #expect(!has99)
        let e5 = try? s.element(at: 5)
        #expect(e5 == nil)
    }
}

// MARK: - Integration

extension SetOrderedSmallTypeTests.Integration {
    @Test func `insert and remove across the spill boundary`() {
        var s = Set<Int>.Ordered.Small<2>()
        for value in 1...5 {
            s.insert(value)
        }
        let spilled = s.isSpilled
        #expect(spilled)
        let count = s.count
        #expect(count == 5)
        let removed = s.remove(3)
        #expect(removed == 3)
        let count2 = s.count
        #expect(count2 == 4)
        let has3 = s.contains(3)
        #expect(!has3)
        let e0 = s[0]
        #expect(e0 == 1)
    }
}
