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

import Finite_Primitives
import Index_Primitives
import Ordinal_Primitives
public import Set_Primitives
public import Buffer_Linear_Inline_Primitives
import Buffer_Linear_Primitive

// Note: Set.Ordered.Static is declared inside Set.Ordered (in Set.Ordered.Static.swift,
// same module). This file holds the hot-operation surface co-located with the storage
// ([MOD-036] refined-C). Set.Ordered.Static is unconditionally ~Copyable, so this whole
// surface works for ~Copyable elements.
//
// ## Architecture
//
// Set.Ordered.Static composes two lower-level primitives:
// - Buffer.Linear.Inline<capacity>: Element storage
// - Hash.Table.Static<capacity>: O(1) position lookup by hash
//
// This layering ensures single responsibility:
// - Hash table logic lives in Hash.Table.Static
// - Buffer management lives in Buffer.Linear.Inline
// - Set provides the unified API

// MARK: - Properties

extension Set_Primitives.Set.Ordered.Static where Element: ~Copyable {
    /// The number of elements in the set.
    @inlinable
    public var count: Index<Element>.Count { buffer.count }

    /// Whether the set is empty.
    @inlinable
    public var isEmpty: Bool { hashTable.isEmpty }

    /// Whether the set is at full capacity.
    @inlinable
    public var isFull: Bool { hashTable.isFull }
}

// MARK: - Core Operations

extension Set_Primitives.Set.Ordered.Static where Element: ~Copyable {
    /// Returns the bounded index of the given element, or `nil` if not present.
    ///
    /// The returned index is guaranteed to be in [0, capacity).
    ///
    /// - Complexity: O(1) average, O(n) worst case.
    @inlinable
    public func index(_ element: borrowing Element) -> Index<Element>.Bounded<capacity>? {
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
        hashTable.position(
            forHash: element.hashValue,
            context: element,
            equals: { idx, elem in buffer[idx] == elem }
        ) != nil
    }

    /// Inserts an element into the set.
    ///
    /// - Parameter element: The element to insert.
    /// - Returns: A tuple indicating whether insertion occurred and the element's bounded index.
    /// - Throws: ``Error/overflow`` if the set is full.
    /// - Complexity: O(1) average, O(n) worst case.
    @inlinable
    @discardableResult
    public mutating func insert(_ element: consuming Element) throws(__SetOrderedInlineError<Element>) -> (inserted: Bool, index: Index<Element>.Bounded<capacity>) {
        let hashValue = element.hashValue

        // Check for existing element
        if let existingPosition = hashTable.position(
            forHash: hashValue,
            equals: { idx in
                buffer[idx] == element
            }
        ) {
            return (false, existingPosition)
        }

        // Check capacity
        guard !hashTable.isFull else {
            throw .overflow(.init())
        }

        // Insert at next available position (count < capacity since !isFull)
        let position: Index<Element>.Bounded<capacity> = .init(buffer.count.map(Ordinal.init))!
        _ = buffer.append(element)
        hashTable.insert(_unchecked: (), position: position, hashValue: hashValue)

        return (true, position)
    }

    /// Removes an element from the set.
    ///
    /// - Parameter element: The element to remove.
    /// - Returns: The removed element, or `nil` if not present.
    /// - Complexity: O(n) due to element shifting.
    @inlinable
    @discardableResult
    public mutating func remove(_ element: borrowing Element) -> Element? {
        // Find and remove from hash table
        guard
            let removedPosition = hashTable.remove(
                hashValue: element.hashValue,
                context: element,
                equals: { idx, elem in buffer[idx] == elem }
            )
        else {
            return nil
        }

        // Remove element from buffer (shifts remaining elements left)
        let removed = buffer.remove(at: removedPosition)

        // Update positions in hash table for shifted elements
        hashTable.positions.decrement(after: removedPosition)

        return removed
    }

    /// Removes all elements from the set.
    ///
    /// Requires `Element: Copyable` because the inline buffer's bulk `removeAll()`
    /// does; `~Copyable` elements are emptied via the consuming `drain(_:)`.
    @inlinable
    public mutating func clear() where Element: Copyable {
        guard hashTable.count > .zero else { return }
        buffer.removeAll()
        hashTable.remove.all()
    }
}

// MARK: - Element Access
//
// These accessors return `Element` by value, so they require `Element: Copyable`.
// `~Copyable` elements use the borrowing `withElement(at:)` / `forEach` surface.

extension Set_Primitives.Set.Ordered.Static where Element: Copyable {
    /// Accesses the element at the specified index.
    @inlinable
    public func element(at index: Index<Element>) throws(__SetOrderedInlineError<Element>) -> Element {
        guard index < count else {
            throw .bounds(.init(index: index, count: count))
        }
        return buffer[index]
    }

    /// Accesses the element at a capacity-bounded index.
    ///
    /// The bounded index guarantees `index < capacity` at the type level.
    /// Only the `index < count` check remains as a runtime precondition
    /// (the slot must be initialized).
    @inlinable
    public func element(at index: Index<Element>.Bounded<capacity>) throws(__SetOrderedInlineError<Element>) -> Element {
        let unbounded = Index<Element>(index)
        guard unbounded < count else {
            throw .bounds(.init(index: Index<Element>(index), count: count))
        }
        return buffer[index]
    }

    /// Subscript access to elements by index.
    @inlinable
    public subscript(index: Index<Element>) -> Element {
        precondition(index < count, "Index out of bounds")
        return buffer[index]
    }

    /// Subscript access to elements by capacity-bounded index.
    ///
    /// - index >= 0: guaranteed by `Ordinal` (non-negative by construction)
    /// - index < capacity: guaranteed by `Finite<capacity>` (bounded by type)
    /// - index < count: checked at runtime (count is runtime state)
    @inlinable
    public subscript(index: Index<Element>.Bounded<capacity>) -> Element {
        precondition(index < count, "Index out of bounds")
        return buffer[index]
    }
}

// MARK: - First/Last Accessors

extension Set_Primitives.Set.Ordered.Static where Element: Copyable {
    /// The first element, or `nil` if the set is empty.
    @inlinable
    public var first: Element? {
        count > .zero ? buffer[.zero] : nil
    }

    /// The last element, or `nil` if the set is empty.
    @inlinable
    public var last: Element? {
        guard count > .zero else { return nil }
        let lastIndex = count.subtract.saturating(.one).map(Ordinal.init)
        return buffer[lastIndex]
    }
}

// MARK: - Borrowed Element Access

extension Set_Primitives.Set.Ordered.Static where Element: ~Copyable {
    /// Accesses the element at the given index via closure.
    @inlinable
    public func withElement<R>(at index: Index<Element>, _ body: (borrowing Element) -> R) -> R {
        precondition(index < count, "Index out of bounds")
        return body(buffer[index])
    }

    /// Accesses the element at a capacity-bounded index via closure.
    @inlinable
    public func withElement<R>(at index: Index<Element>.Bounded<capacity>, _ body: (borrowing Element) -> R) -> R {
        precondition(index < count, "Index out of bounds")
        return body(buffer[index])
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
        guard hashTable.count > .zero else { return }

        while !buffer.isEmpty {
            body(buffer.remove.first())
        }

        // Clear hash table
        hashTable.remove.all()
    }
}

// MARK: - Span Access Note
//
// Storage.Inline uses 64-byte slots to support ~Copyable elements.
// This strided layout is incompatible with Span's dense expectation.
// Use forEach or withElement for iteration instead of Span access.
