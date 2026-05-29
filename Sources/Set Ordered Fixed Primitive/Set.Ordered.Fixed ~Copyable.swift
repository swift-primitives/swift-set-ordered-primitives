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

    /// Iterates over all elements in the set.
    @inlinable
    public func forEach<E: Swift.Error>(_ body: (borrowing Element) throws(E) -> Void) throws(E) {
        let count = buffer.count
        guard count > .zero else { return }
        var index: Index<Element> = .zero
        let end = count.map(Ordinal.init)
        while index < end {
            try body(buffer[index])
            index += .one
        }
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

extension Set_Primitives.Set.Ordered.Fixed where Element: ~Copyable {
    /// Provides read-only span access to the set's elements in insertion order.
    @inlinable
    public func withSpan<R, E: Swift.Error>(
        _ body: (Span<Element>) throws(E) -> R
    ) throws(E) -> R {
        try body(buffer.span)
    }

    /// Provides mutable span access to the set's elements in insertion order.
    ///
    /// - Warning: Modifying elements through this span may invalidate the hash table.
    ///   Only use for in-place updates that preserve element identity/hash.
    @inlinable
    public mutating func withMutableSpan<R, E: Swift.Error>(
        _ body: (inout MutableSpan<Element>) throws(E) -> R
    ) throws(E) -> R where Element: Copyable {
        makeUnique()
        var span = buffer.mutableSpan
        return try body(&span)
    }
}

// MARK: - Buffer Access (Escape Hatch for C Interop)

@_spi(Unsafe)
extension Set_Primitives.Set.Ordered.Fixed where Element: ~Copyable {
    /// Provides read-only access to the underlying contiguous storage.
    @unsafe
    @inlinable
    public func withUnsafeBufferPointer<R, E: Swift.Error>(
        _ body: (UnsafeBufferPointer<Element>) throws(E) -> R
    ) throws(E) -> R {
        let span = buffer.span
        return try unsafe span.withUnsafeBufferPointer(body)
    }

    /// Provides mutable access to the underlying contiguous storage.
    @unsafe
    @inlinable
    public mutating func withUnsafeMutableBufferPointer<R, E: Swift.Error>(
        _ body: (UnsafeMutableBufferPointer<Element>) throws(E) -> R
    ) throws(E) -> R where Element: Copyable {
        makeUnique()
        var span = buffer.mutableSpan
        return try unsafe span.withUnsafeMutableBufferPointer(body)
    }
}

// MARK: - Hash.Protocol Conformance

extension Set_Primitives.Set.Ordered.Fixed: Hash.`Protocol` {
    /// Compares two Fixed ordered sets for element-wise equality.
    @inlinable
    public static func == (lhs: borrowing Self, rhs: borrowing Self) -> Bool {
        guard lhs.count == rhs.count else { return false }
        let count = lhs.count
        guard count > .zero else { return true }
        var index: Index<Element> = .zero
        let end = count.map(Ordinal.init)
        while index < end {
            if lhs.buffer[index] != rhs.buffer[index] {
                return false
            }
            index += .one
        }
        return true
    }

    /// Hashes the essential components of this set by feeding them into the given hasher.
    @inlinable
    public borrowing func hash(into hasher: inout Hasher) {
        hasher.combine(count)
        guard count > .zero else { return }
        var index: Index<Element> = .zero
        let end = count.map(Ordinal.init)
        while index < end {
            buffer[index].hash(into: &hasher)
            index += .one
        }
    }
}
