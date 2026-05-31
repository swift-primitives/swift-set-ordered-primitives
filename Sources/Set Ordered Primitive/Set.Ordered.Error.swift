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

public import Set_Primitives
import Index_Primitives

// ===----------------------------------------------------------------------===//
// MARK: - Hoisted Error Type
// ===----------------------------------------------------------------------===//
//
// Swift does not allow nested types inside generic types to be easily accessed.
// This error type is hoisted to module level and exposed via a typealias.

/// Hoisted implementation of ``Set/Ordered/Error``.
public enum __SetOrderedError<Element: Hash.`Protocol` & ~Copyable>: Swift.Error, Sendable, Equatable {
    /// An index was out of bounds.
    case bounds(Bounds)

    /// An operation was attempted on an empty set.
    case empty(Empty)

    /// Bounds violation payload.
    public struct Bounds: Sendable, Equatable {
        public let index: Index_Primitives.Index<Element>
        public let count: Index_Primitives.Index<Element>.Count

        @inlinable
        public init(index: Index_Primitives.Index<Element>, count: Index_Primitives.Index<Element>.Count) {
            self.index = index
            self.count = count
        }
    }

    /// Empty collection payload.
    public struct Empty: Sendable, Equatable {
        @inlinable
        public init() {}
    }
}

extension __SetOrderedError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .bounds(let e): return "index \(Int(bitPattern: e.index)) out of bounds for count \(Int(bitPattern: e.count))"
        case .empty: return "operation attempted on empty ordered set"
        }
    }
}

// MARK: - Error Typealias

extension Set.Ordered {
    /// Errors that can occur during ordered set operations.
    public typealias Error = __SetOrderedError<Element>
}

// `Set.Ordered.Fixed.Error` and `Set.Ordered.Static.Error` typealiases live in
// their respective variant target modules (Set Ordered Fixed Primitive /
// Set Ordered Static Primitive), since `Fixed`/`Static` are declared there.
