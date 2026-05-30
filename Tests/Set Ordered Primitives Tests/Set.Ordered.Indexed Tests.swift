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

import Testing

@testable import Set_Ordered_Primitives

// Behaviour coverage for the Indexed<Tag> phantom-typed index wrapper across ALL FOUR
// ordered-set variants — the ×16 fan-out blueprint surface. The typed index is obtained
// from `insert`'s return, then round-tripped through the subscript, so the test never
// constructs a raw index. Growable variants (dynamic, Small) use plain Index<Tag>; the
// capacity-bounded Static uses Index<Tag>.Bounded<capacity>. ~Copyable wrappers (Small,
// Static) bind results to lets before #expect (the macro captures operands by value).

@Suite("Set.Ordered.Indexed")
struct SetOrderedIndexedTests {
    @Suite struct Dynamic {}
    @Suite struct Fixed {}
    @Suite struct Small {}
    @Suite struct Static {}
}

// MARK: - Dynamic (Copyable wrapper, plain Index<Tag>)

extension SetOrderedIndexedTests.Dynamic {
    @Test
    func `insert returns a typed index that round-trips through the subscript`() {
        enum Tag {}
        var indexed = Set<Int>.Ordered.Indexed<Tag>(Set<Int>.Ordered())
        let a = indexed.insert(10)
        let b = indexed.insert(20)
        #expect(a.inserted)
        #expect(b.inserted)
        #expect(indexed[a.index] == 10)
        #expect(indexed[b.index] == 20)
        #expect(indexed.contains(10))
        #expect(!indexed.contains(99))
        #expect(indexed.index(20) == b.index)
        #expect(!indexed.isEmpty)
    }
}

// MARK: - Fixed (Copyable wrapper, plain Index<Tag>, throwing insert)

extension SetOrderedIndexedTests.Fixed {
    @Test
    func `insert returns a typed index that round-trips through the subscript`() throws {
        enum Tag {}
        var indexed = Set<Int>.Ordered.Fixed.Indexed<Tag>(try Set<Int>.Ordered.Fixed(capacity: 8))
        let a = try indexed.insert(10)
        let b = try indexed.insert(20)
        #expect(a.inserted)
        #expect(b.inserted)
        #expect(indexed[a.index] == 10)
        #expect(indexed[b.index] == 20)
        #expect(indexed.contains(10))
        #expect(!indexed.isFull)
    }
}

// MARK: - Small (~Copyable wrapper, plain Index<Tag>)

extension SetOrderedIndexedTests.Small {
    @Test
    func `insert returns a typed index that round-trips through the subscript`() {
        enum Tag {}
        var indexed = Set<Int>.Ordered.Small<8>.Indexed<Tag>(Set<Int>.Ordered.Small<8>())
        let a = indexed.insert(10)
        let b = indexed.insert(20)
        let atA = indexed[a.index]
        let atB = indexed[b.index]
        let has10 = indexed.contains(10)
        let has99 = indexed.contains(99)
        let empty = indexed.isEmpty
        #expect(a.inserted)
        #expect(b.inserted)
        #expect(atA == 10)
        #expect(atB == 20)
        #expect(has10)
        #expect(!has99)
        #expect(!empty)
    }
}

// MARK: - Static (~Copyable wrapper, BOUNDED Index<Tag>.Bounded<capacity>, throwing insert)

extension SetOrderedIndexedTests.Static {
    @Test
    func `insert returns a typed bounded index that round-trips through the subscript`() throws {
        enum Tag {}
        var indexed = Set<Int>.Ordered.Static<8>.Indexed<Tag>(Set<Int>.Ordered.Static<8>())
        let a = try indexed.insert(10)
        let b = try indexed.insert(20)
        let atA = indexed[a.index]   // a.index: Index<Tag>.Bounded<8>
        let atB = indexed[b.index]
        let has10 = indexed.contains(10)
        let full = indexed.isFull
        let empty = indexed.isEmpty
        #expect(a.inserted)
        #expect(b.inserted)
        #expect(atA == 10)
        #expect(atB == 20)
        #expect(has10)
        #expect(!full)
        #expect(!empty)
    }
}
