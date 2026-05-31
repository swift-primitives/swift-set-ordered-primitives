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
public import Set_Ordered_Primitive
public import Buffer_Linear_Small_Primitive

// Note: Set.Ordered.Small is declared inside Set.Ordered (in Set.Ordered.Small.swift,
// same module). This file holds the element-agnostic hot-operation surface co-located
// with the storage ([MOD-036] refined-C). Set.Ordered.Small is unconditionally
// ~Copyable, so this whole surface works for ~Copyable elements.
//
// ## Design Note
//
// Small sets compose Buffer<Element>.Linear.Small<inlineCapacity> for element
// storage. The buffer handles inline/heap dispatch internally. The set layer
// adds hash table management (activated on spill) and deduplication.
//
// - Inline mode: linear search O(n) for membership (no hash table overhead)
// - Heap mode: O(1) hash table lookup

// MARK: - Spill State

extension Set.Ordered.Small where Element: ~Copyable {
    /// Whether the set has spilled to heap storage.
    @inlinable
    public var isSpilled: Bool { buffer.isSpilled }
}

// MARK: - Properties

extension Set_Primitives.Set.Ordered.Small where Element: ~Copyable {
    /// The number of elements in the set.
    @inlinable
    public var count: Index<Element>.Count {
        buffer.count
    }

    /// The current capacity of the set.
    @inlinable
    public var capacity: Index<Element>.Count {
        buffer.capacity
    }
}

// MARK: - Borrowed Element Access (~Copyable-safe read surface)
//
// `withElement`/`contains`/`index` only BORROW the storage, so they are
// `~Copyable`-safe. When spilled, `contains`/`index` probe the sentinel-empty
// `~Copyable` `hashTable` directly (§2.9) — a borrow, no extraction, so no `Copyable`
// gate. Only the *mutating* `drain()` stays `Copyable`-gated (below) for its elements
// — the B2 hazard, surfaced not fixed.

extension Set_Primitives.Set.Ordered.Small where Element: ~Copyable {
    /// Accesses the element at the given index via closure.
    @inlinable
    public func withElement<R>(at index: Index<Element>, _ body: (borrowing Element) -> R) -> R {
        precondition(index < count, "Index out of bounds")
        return body(buffer[index])
    }

    /// Accesses the element at the given index via closure, with typed error on bounds failure.
    @inlinable
    public func withElement<R>(at index: Index<Element>, _ body: (borrowing Element) throws(__SetOrderedError<Element>) -> R) throws(__SetOrderedError<Element>) -> R {
        guard index < count else {
            throw .bounds(.init(index: index, count: count))
        }
        return try body(buffer[index])
    }

    /// Returns the index of the given element, or `nil` if not present.
    ///
    /// Uses O(1) hash-table lookup when spilled to heap, O(n) linear scan
    /// when inline (no hash table available in inline mode).
    @inlinable
    public func index(_ element: borrowing Element) -> Index<Element>? {
        if isSpilled {
            // Direct probe over the shared Hash.Table.Protocol `position` terminal.
            // `hashTable` is sentinel-empty inline, populated on spill (§2.9), so when
            // spilled this returns the real position; the borrow keeps it `~Copyable`-safe
            // (no extraction).
            return hashTable.position(
                forHash: element.hashValue,
                context: element,
                equals: { idx, elem in buffer[idx] == elem }
            )
        } else {
            var idx: Index<Element> = .zero
            let end = buffer.count.map(Ordinal.init)
            while idx < end {
                if buffer[idx] == element { return idx }
                idx += .one
            }
            return nil
        }
    }

    /// Returns whether the set contains the given element.
    ///
    /// Uses O(1) hash-table lookup when spilled to heap, O(n) linear scan
    /// when inline (no hash table available in inline mode).
    @inlinable
    public func contains(_ element: borrowing Element) -> Bool {
        if isSpilled {
            // Direct probe over the shared Hash.Table.Protocol membership terminal.
            // `hashTable` is sentinel-empty inline, populated on spill (§2.9); the borrow
            // keeps it `~Copyable`-safe (no extraction).
            return hashTable.contains(
                forHash: element.hashValue,
                context: element,
                equals: { idx, elem in buffer[idx] == elem }
            )
        } else {
            var idx: Index<Element> = .zero
            let end = buffer.count.map(Ordinal.init)
            while idx < end {
                if buffer[idx] == element { return true }
                idx += .one
            }
            return false
        }
    }

}

// MARK: - Drain (Copyable, mutating)
//
// With the sentinel-empty `hashTable` (§2.9), `drain()` empties a definitely-present
// `~Copyable` value directly — no optional unwrap, no take-and-put-back — so the
// `DiagnoseStaticExclusivity` (A11) workaround is gone. Stays `Copyable`-gated for its
// elements; the B2 Small-CoW hazard is surfaced separately, not addressed here.

extension Set_Primitives.Set.Ordered.Small where Element: Copyable {
    /// Removes and consumes all elements.
    @inlinable
    public mutating func drain(_ body: (consuming Element) -> Void) {
        guard count > .zero else { return }

        while !buffer.isEmpty {
            body(buffer.remove.first())
        }

        hashTable.remove.all(keepingCapacity: true)
    }
}

// MARK: - Span Access (Closure-Based)

extension Set_Primitives.Set.Ordered.Small where Element: ~Copyable {
    /// Safe, bounds-checked read access to contiguous storage via closure.
    ///
    /// Small sets use closure-based access because inline storage mode requires
    /// it (Span is ~Escapable and cannot be returned from property accessors
    /// without special compiler support).
    @inlinable
    public func withSpan<R, E: Swift.Error>(
        _ body: (Span<Element>) throws(E) -> R
    ) throws(E) -> R {
        try body(buffer.span)
    }

    /// Safe, bounds-checked write access to contiguous storage via closure.
    ///
    /// - Warning: Modifying elements may invalidate uniqueness if the
    ///   modifications affect element equality/hash.
    @inlinable
    public mutating func withMutableSpan<R, E: Swift.Error>(
        _ body: (inout MutableSpan<Element>) throws(E) -> R
    ) throws(E) -> R {
        var span = buffer.mutableSpan
        return try body(&span)
    }
}
