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

// The COLUMN-GENERIC ordered surface: the count vocabulary AND the ordered-READ
// vocabulary ride the template bound — positional access needs only the seam's
// element `_read` (`Store.Protocol`) plus the ledgered `count` (`Buffer.Protocol`),
// and `Shared`'s `_read` witness is gate-free, so one declaration serves both
// columns. The ENGINE-touching ops (membership, position lookup) pin per column
// (`Set.Ordered+Columns.swift`) — they reach the engine, which only the concrete
// composite exposes. No element mutation doors (mutability ruling (a)): the
// positional subscript is `_read`-only.
public import Set_Ordered_Primitive
public import Buffer_Protocol_Primitives
public import Store_Protocol_Primitives
public import Index_Primitives
import Ordinal_Primitives_Standard_Library_Integration

extension __SetOrdered where S: ~Copyable {
    /// The number of members.
    @inlinable
    public var count: Index<S.Element>.Count { store.count }

    /// Whether the ordered set is empty.
    @inlinable
    public var isEmpty: Bool { store.isEmpty }

    /// The dense plane's current capacity.
    @inlinable
    public var capacity: Index<S.Element>.Count { store.capacity }
}

// MARK: - Positional reads (insertion order; the package's reason to exist)

extension __SetOrdered where S: ~Copyable {
    /// Reads the member at the given insertion-order position (a borrowing read;
    /// there is no positional write — mutability ruling (a)).
    ///
    /// - Precondition: `index < count`.
    /// - Complexity: O(1)
    @inlinable
    public subscript(index: Index<S.Element>) -> S.Element {
        _read {
            precondition(index < count.map(Ordinal.init), "ordered surface: index out of bounds")
            yield store[index]
        }
    }
}

extension __SetOrdered where S: ~Copyable, S.Element: Copyable {
    /// The oldest-inserted member, or `nil` if the set is empty.
    ///
    /// - Complexity: O(1)
    @inlinable
    public var first: S.Element? {
        isEmpty ? nil : store[.zero]
    }

    /// The newest-inserted member, or `nil` if the set is empty.
    ///
    /// - Complexity: O(1)
    @inlinable
    public var last: S.Element? {
        guard !isEmpty else { return nil }
        return store[count.subtract.saturating(.one).map(Ordinal.init)]
    }
}

// MARK: - Cloning (generic on the CoW column)

extension __SetOrdered where S: Copyable {
    /// Returns an independent copy of this ordered set with its own storage (the
    /// mutation gate on the fresh copy ALWAYS installs a deep copy).
    ///
    /// - Complexity: O(`capacity`)
    @inlinable
    public borrowing func clone() -> Self {
        var result = copy self
        result.store.prepareForMutation()
        return result
    }
}
