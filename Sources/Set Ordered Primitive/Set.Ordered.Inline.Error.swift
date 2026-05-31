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

/// Hoisted implementation of ``Set/Ordered/Inline/Error``.
public enum __SetOrderedInlineError<Element: Hash.`Protocol` & ~Copyable>: Swift.Error, Sendable, Equatable {
    /// The set is full and cannot accept more elements.
    case overflow(Overflow)

    /// The index is out of bounds.
    case bounds(Bounds)

    /// Overflow payload.
    public struct Overflow: Sendable, Equatable {
        @inlinable
        public init() {}
    }

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
}

extension __SetOrderedInlineError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .overflow:
            return "inline set is full"
        case .bounds(let e):
            return "index \(Int(bitPattern: e.index)) out of bounds for count \(Int(bitPattern: e.count))"
        }
    }
}
