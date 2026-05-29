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

import Set_Ordered_Primitives_Test_Support
import Testing

// Concrete validation of the powerset lattice grounding (swift-set-algebra-
// primitives' `Set.Buildable.`Protocol`.powerset()`) against the real
// `Set.Ordered` — the package's growable BuildableSet. The witness packages
// ∪ = join, ∩ = meet, ∅ = bottom, universe = top; the Boolean complement is the
// native `subtracting` (U ∖ A). (The fixture in set-algebra is intentionally not
// Buildable, so the powerset witness is exercised here.)
@Suite("Powerset Lattice (Set.Ordered)")
struct PowersetLatticeTests {}

extension PowersetLatticeTests {

    private static func ordered(_ elements: [Int]) -> Set<Int>.Ordered {
        var set = Set<Int>.Ordered()
        for element in elements { set.insert(element) }
        return set
    }

    @Test
    func `join is union, meet is intersection`() {
        let universe = PowersetLatticeTests.ordered([1, 2, 3, 4])
        let lattice = universe.powerset()
        let a = PowersetLatticeTests.ordered([1, 2])
        let b = PowersetLatticeTests.ordered([2, 3])

        #expect(toArray(lattice.join(a, b)) == toArray(a.union(b)))
        #expect(toArray(lattice.meet(a, b)) == toArray(a.intersection(b)))
        #expect(toArray(lattice.join(a, b)) == [1, 2, 3])
        #expect(toArray(lattice.meet(a, b)) == [2])
    }

    @Test
    func `bottom is empty, top is the universe`() {
        let universe = PowersetLatticeTests.ordered([1, 2, 3])
        let lattice = universe.powerset()
        #expect(toArray(lattice.bottom).isEmpty)
        #expect(toArray(lattice.top) == [1, 2, 3])
    }

    @Test
    func `inclusion: a subset of b iff a join b equals b`() {
        let universe = PowersetLatticeTests.ordered([1, 2, 3, 4])
        let lattice = universe.powerset()
        let a = PowersetLatticeTests.ordered([1, 2])
        let b = PowersetLatticeTests.ordered([1, 2, 3])
        // a ⊆ b  ⟺  a ∪ b == b   (the induced lattice order is ⊆)
        #expect(toArray(lattice.join(a, b)) == toArray(b))
        #expect(toArray(lattice.join(b, a)) != toArray(a))
    }

    @Test
    func `complement laws via native subtracting`() {
        let universe = PowersetLatticeTests.ordered([1, 2, 3, 4])
        let lattice = universe.powerset()
        let a = PowersetLatticeTests.ordered([1, 3])
        let notA = universe.subtracting(a)              // U ∖ A = {2, 4}
        #expect(toArray(notA) == [2, 4])
        // a ∨ ¬a = ⊤ (universe);  a ∧ ¬a = ⊥ (∅)
        #expect(toArray(lattice.join(a, notA)) == toArray(universe))
        #expect(toArray(lattice.meet(a, notA)).isEmpty)
    }
}
