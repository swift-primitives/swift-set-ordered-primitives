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

import Cardinal_Primitives
import Index_Primitives
public import Ordinal_Primitives
public import Set_Primitives
public import Buffer_Linear_Bounded_Primitive
import Buffer_Linear_Bounded_Primitives

// Note: Set.Ordered.Fixed is declared inside Set.Ordered (in Set.Ordered.Fixed.swift,
// same module). This file holds the non-Copyable hot-operation surface co-located with
// the storage ([MOD-036] refined-C); Copyable hot ops live in `Set.Ordered.Fixed Copyable.swift`.

// MARK: - Properties

extension Set_Primitives.Set.Ordered.Fixed where Element: ~Copyable {
    /// The number of elements in the set.
    @inlinable
    public var count: Index<Element>.Count { buffer.count }

    /// Whether the set is at full capacity.
    @inlinable
    public var isFull: Bool { buffer.count >= maximumCapacity }

    /// The maximum capacity (alias for API consistency).
    @inlinable
    public var capacity: Index<Element>.Count { maximumCapacity }
}

// MARK: - Borrowed Element Access

extension Set_Primitives.Set.Ordered.Fixed where Element: ~Copyable {
    /// Accesses the element at the given index via closure.
    @inlinable
    public func withElement<R>(at index: Index<Element>, _ body: (borrowing Element) -> R) -> R {
        precondition(index < count, "Index out of bounds")
        return body(buffer[index])
    }

    /// Accesses the element at the given index via closure, with typed error on bounds failure.
    @inlinable
    public func withElement<R>(at index: Index<Element>, _ body: (borrowing Element) throws(__SetOrderedFixedError<Element>) -> R) throws(__SetOrderedFixedError<Element>) -> R {
        guard index < count else {
            throw .bounds(.init(index: index, count: count))
        }
        return try body(buffer[index])
    }

    /// Returns the index of the given element, or `nil` if not present.
    ///
    /// - Complexity: O(1) average, O(n) worst case.
    @inlinable
    public func index(_ element: borrowing Element) -> Index<Element>? {
        // Concrete witness delegating over the shared Hash.Table.Protocol `position`
        // terminal — the index-returning sibling of `contains`. Relaxed to
        // `~Copyable` via context-threading (no element capture in the closure).
        hashTable.position(
            forHash: element.hashValue,
            context: element,
            equals: { idx, elem in buffer[idx] == elem }
        )
    }

    /// Returns whether the set contains the given element.
    ///
    /// - Complexity: O(1) average, O(n) worst case.
    @inlinable
    public func contains(_ element: borrowing Element) -> Bool {
        // Concrete Set.Protocol witness delegating over the shared
        // Hash.Table.Protocol membership terminal (`position(...) != nil`).
        hashTable.contains(
            forHash: element.hashValue,
            context: element,
            equals: { idx, elem in buffer[idx] == elem }
        )
    }

    /// Removes and consumes all elements.
    @inlinable
    public mutating func drain(_ body: (consuming Element) -> Void) {
        guard buffer.count > .zero else { return }
        while !buffer.isEmpty {
            body(buffer.remove.first())
        }
        hashTable.remove.all(keepingCapacity: true)
    }
}

// MARK: - Span Access

extension Set_Primitives.Set.Ordered.Fixed where Element: Copyable {
    /// Direct mutable span access to the set's elements in insertion order.
    ///
    /// - Warning: Modifying elements through this span may invalidate the hash
    ///   table. Only use for in-place updates that preserve element identity/hash.
    /// - Note: Raw mutable-pointer access (C interop) is on the span:
    ///   `mutableSpan.withUnsafeMutableBufferPointer { … }`.
    @inlinable
    public var mutableSpan: MutableSpan<Element> {
        @_lifetime(&self)
        mutating get {
            makeUnique()
            return buffer.mutableSpan()
        }
    }
}
