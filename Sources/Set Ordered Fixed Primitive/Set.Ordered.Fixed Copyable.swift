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

// Copyable hot-operation surface co-located with the storage ([MOD-036] refined-C).

// MARK: - Coordinated CoW

extension Set_Primitives.Set.Ordered.Fixed where Element: Copyable {
    /// Ensures both buffer and hash table are uniquely owned.
    @inlinable
    mutating func makeUnique() {
        buffer.ensureUnique()
        hashTable.ensureUnique()
    }
}

// MARK: - Core Operations (Copyable elements)

extension Set_Primitives.Set.Ordered.Fixed where Element: Copyable {
    /// Inserts an element into the set.
    ///
    /// - Parameter element: The element to insert.
    /// - Returns: A tuple indicating whether insertion occurred and the element's index.
    /// - Throws: ``Error/overflow`` if the set is full.
    @inlinable
    @discardableResult
    public mutating func insert(_ element: Element) throws(__SetOrderedFixedError<Element>) -> (inserted: Bool, index: Index<Element>) {
        if let existing = hashTable.position(
            forHash: element.hashValue,
            equals: { idx in buffer[idx] == element }
        ) {
            return (false, existing)
        }

        let currentCount = buffer.count
        guard currentCount < maximumCapacity else {
            throw .overflow(.init())
        }
        makeUnique()
        let index = currentCount.map(Ordinal.init)
        _ = buffer.append(element)
        hashTable.insert(_unchecked: (), position: index, hashValue: element.hashValue)

        return (true, index)
    }

    /// Removes an element from the set.
    ///
    /// - Parameter element: The element to remove.
    /// - Returns: The removed element, or `nil` if not present.
    @inlinable
    @discardableResult
    public mutating func remove(_ element: Element) -> Element? {
        makeUnique()

        guard
            let removedPosition = hashTable.remove(
                hashValue: element.hashValue,
                equals: { idx in buffer[idx] == element }
            )
        else {
            return nil
        }

        let removed = buffer.remove(at: removedPosition)
        hashTable.positions.decrement(after: removedPosition)

        return removed
    }

    /// Removes all elements from the set.
    @inlinable
    public mutating func clear(keepingCapacity: Bool = false) {
        makeUnique()
        buffer.removeAll()
        hashTable.remove.all(keepingCapacity: keepingCapacity)
    }
}

// MARK: - Element Access (Copyable only)

extension Set_Primitives.Set.Ordered.Fixed where Element: Copyable {
    /// Accesses the element at the specified index.
    @inlinable
    public func element(at index: Index<Element>) throws(__SetOrderedFixedError<Element>) -> Element {
        guard index < count else {
            throw .bounds(.init(index: index, count: count))
        }
        return buffer[index]
    }

    /// Subscript access to elements by index.
    @inlinable
    public subscript(index: Index<Element>) -> Element {
        precondition(index < count, "Index out of bounds")
        return buffer[index]
    }
}

// MARK: - First/Last Accessors (Copyable only)

extension Set_Primitives.Set.Ordered.Fixed where Element: Copyable {
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
