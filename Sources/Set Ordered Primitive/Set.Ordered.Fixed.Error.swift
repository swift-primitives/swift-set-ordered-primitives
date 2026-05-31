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

/// Hoisted implementation of ``Set/Ordered/Fixed/Error``.
public enum __SetOrderedFixedError<Element: Hash.`Protocol` & ~Copyable>: Swift.Error, Sendable, Equatable {
    /// The index is out of bounds.
    case bounds(Bounds)

    /// The set is empty.
    case empty(Empty)

    /// The set is full and cannot accept more elements.
    case overflow(Overflow)

    /// The specified capacity is invalid.
    case invalidCapacity(InvalidCapacity)

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

    /// Overflow payload.
    public struct Overflow: Sendable, Equatable {
        @inlinable
        public init() {}
    }

    /// Invalid capacity payload.
    public struct InvalidCapacity: Sendable, Equatable {
        @inlinable
        public init() {}
    }
}

extension __SetOrderedFixedError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .bounds(let e):
            return "index \(Int(bitPattern: e.index)) out of bounds for count \(Int(bitPattern: e.count))"
        case .empty:
            return "operation attempted on empty Fixed set"
        case .overflow:
            return "Fixed set is full"
        case .invalidCapacity:
            return "invalid capacity"
        }
    }
}
