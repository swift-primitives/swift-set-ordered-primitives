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

// The S5 carrier — see `Set.Ordered+Equatable.swift` for the column-riding note.
// `Shared: Hashable` combines count + the dense prefix in order, so equal ordered
// sets (same members, same insertion order) hash equal.

extension __SetOrdered: Hashable where S: Hashable {
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(store)
    }
}
