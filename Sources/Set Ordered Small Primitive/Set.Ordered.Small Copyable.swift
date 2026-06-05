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
public import Storage_Small_Primitives
public import Storage_Primitive
public import Buffer_Linear_Primitive
public import Buffer_Linear_Primitives
import Index_Primitives
public import Ordinal_Primitives
public import Set_Primitives
public import Set_Ordered_Primitive
public import Buffer_Linear_Small_Primitive

// This file holds the `where Element: Copyable` hot-operation surface co-located
// with the storage ([MOD-036] refined-C). These ops inline cross-package to
// zero-witness-dispatch through the `@usableFromInline internal` storage.

// MARK: - Core Operations (Copyable elements)

extension Set_Primitives.Set.Ordered.Small where Element: Copyable {
    /// Inserts an element into the set.
    ///
    /// If inline storage is full, spills to heap automatically.
    @inlinable
    @discardableResult
    public mutating func insert(_ element: Element) -> (inserted: Bool, index: Index<Element>) {
        if let existing = index(element) {
            return (false, existing)
        }

        let wasSpilled = buffer.substrate.isSpilled
        let index = buffer.count.map(Ordinal.init)
        buffer.append(element)

        if wasSpilled {
            hashTable!.insert(_unchecked: (), position: index, hashValue: element.hashValue)
        } else if buffer.substrate.isSpilled {
            buildHashTable()
        }

        return (true, index)
    }

    /// Removes an element from the set.
    @inlinable
    @discardableResult
    public mutating func remove(_ element: Element) -> Element? {
        if isSpilled {
            guard
                let removedPosition = hashTable!.remove(
                    hashValue: element.hashValue,
                    equals: { idx in buffer[idx] == element }
                )
            else { return nil }

            let removed = buffer.remove(at: removedPosition)

            // WORKAROUND: Extract hash table to local for .positions.decrement() call.
            // Direct `hashTable!.positions.decrement(after:)` crashes the
            // DiagnoseStaticExclusivity SIL pass on generic ~Copyable structs.
            // WHEN TO REMOVE: When swiftlang/swift fixes exclusivity analysis for
            // mutating coroutine accessor chains on stored properties of ~Copyable generics.
            var ht = hashTable!
            ht.positions.decrement(after: removedPosition)
            hashTable = ht

            return removed
        } else {
            guard let idx = index(element) else { return nil }
            return buffer.remove(at: idx)
        }
    }

    /// Removes all elements from the set.
    @inlinable
    public mutating func clear(keepingCapacity: Bool = false) {
        buffer.removeAll(keepingCapacity: keepingCapacity)
        if keepingCapacity {
            // WORKAROUND: Extract hash table to local for .remove.all() call.
            // Direct `hashTable?.remove.all(keepingCapacity:)` crashes the
            // DiagnoseStaticExclusivity SIL pass on generic ~Copyable structs.
            // WHEN TO REMOVE: When swiftlang/swift fixes exclusivity analysis for
            // mutating coroutine accessor chains on stored properties of ~Copyable generics.
            if var ht = hashTable {
                ht.remove.all(keepingCapacity: true)
                hashTable = ht
            }
        } else {
            hashTable = nil
        }
    }
}

// MARK: - Build Hash Table

extension Set_Primitives.Set.Ordered.Small where Element: Copyable {
    /// Builds a hash table over all elements after spill.
    @usableFromInline
    mutating func buildHashTable() {
        let count = buffer.count
        hashTable = Hash.Table<Element>(minimumCapacity: count)
        var idx: Index<Element> = .zero
        let end = count.map(Ordinal.init)
        while idx < end {
            hashTable!.insert(_unchecked: (), position: idx, hashValue: buffer[idx].hashValue)
            idx += .one
        }
    }
}

// MARK: - Element Access (Copyable)

extension Set_Primitives.Set.Ordered.Small where Element: Copyable {
    /// Accesses the element at the specified index, with typed error on bounds failure.
    ///
    /// For an optional result, use `try? set.element(at: index)`.
    @inlinable
    public func element(at index: Index<Element>) throws(__SetOrderedError<Element>) -> Element {
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

// MARK: - First/Last Accessors (Copyable)

extension Set_Primitives.Set.Ordered.Small where Element: Copyable {
    /// The first element, or `nil` if the set is empty.
    @inlinable
    public var first: Element? {
        guard count > .zero else { return nil }
        return buffer[.zero]
    }

    /// The last element, or `nil` if the set is empty.
    @inlinable
    public var last: Element? {
        guard count > .zero else { return nil }
        let lastIndex = count.subtract.saturating(.one).map(Ordinal.init)
        return buffer[lastIndex]
    }
}
