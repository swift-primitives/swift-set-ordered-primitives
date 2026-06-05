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

import Builder_Primitives
import Set_Ordered_Primitives_Test_Support
import Testing

@testable import Set_Ordered_Primitives

@Suite("Set.Ordered variants + Builder")
struct SetOrderedVariantsBuilderTests {
    @Suite struct FixedSet {}
}

extension SetOrderedVariantsBuilderTests.FixedSet {
    @Test
    func `Fixed within capacity`() throws {
        let s = try Set<Int>.Ordered.Fixed(capacity: 8) { 1; 2; 3 }
        let isEmpty = s.isEmpty
        #expect(!isEmpty)
    }

    @Test
    func `Fixed throws on overflow`() {
        do {
            _ = try Set<Int>.Ordered.Fixed(capacity: 2) { 1; 2; 3; 4 }
            Issue.record("expected throw")
        } catch {
            // expected
        }
    }
}
