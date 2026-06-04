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
// Small sets compose Buffer<Storage<Element>.Heap>.Linear.Small<inlineCapacity> for element
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
// `withElement`/`contains`/`forEach` only BORROW the storage, so they are
// `~Copyable`-safe. `contains` reads the optional `~Copyable` `hashTable` via
// borrowing optional-chaining (`hashTable?.position(...)`) — no extraction — so it no
// longer requires `Copyable` (the prior `let ht = hashTable!` forced a copy, which is
// what gated this whole group). Only the *mutating* `drain()` stays `Copyable`-gated
// (below) — the B2 hazard, surfaced not fixed.

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
            // Borrowing optional-chaining over the shared Hash.Table.Protocol `position`
            // terminal (optional chaining flattens to `Index<Element>?`). Avoids the
            // `let ht = hashTable!` copy that gated the old `index(_:)` to `Copyable`.
            // Spilled ⟹ `hashTable` is non-nil.
            return hashTable?.position(
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
            // Borrowing optional-chaining over the shared Hash.Table.Protocol membership
            // terminal — probes the optional `~Copyable` hash table without extracting it.
            // (The old `let ht = hashTable!` forced a copy, gating this op to `Copyable`.)
            // Spilled ⟹ `hashTable` is non-nil, so the `?? false` fallback is unreached.
            return hashTable?.contains(
                forHash: element.hashValue,
                context: element,
                equals: { idx, elem in buffer[idx] == elem }
            ) ?? false
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

// MARK: - Drain (Copyable-gated — B2 hazard, mutating)
//
// `drain()` must stay `Copyable`-gated: emptying the optional `~Copyable` `hashTable`
// in place crashes DiagnoseStaticExclusivity, and the take-and-put-back workaround
// hits the `~Copyable` "partial reinitialize after consume" rule. Structural redesign
// deferred to the unified iteration rework (B2 hazard — surfaced, not fixed here).

extension Set_Primitives.Set.Ordered.Small where Element: Copyable {
    /// Removes and consumes all elements.
    // on buffer.remove loop + hashTable operations in deep @inlinable chain.
    @inlinable
    public mutating func drain(_ body: (consuming Element) -> Void) {
        guard count > .zero else { return }

        while !buffer.isEmpty {
            body(buffer.remove.first())
        }

        // WORKAROUND: Extract hash table to local for .remove.all() call.
        // Direct `hashTable?.remove.all(keepingCapacity:)` crashes the
        // DiagnoseStaticExclusivity SIL pass on generic ~Copyable structs.
        // WHEN TO REMOVE: When swiftlang/swift fixes exclusivity analysis for
        // mutating coroutine accessor chains on stored properties of ~Copyable generics.
        if var ht = hashTable {
            ht.remove.all(keepingCapacity: true)
            hashTable = ht
        }
    }
}

// MARK: - Mutable Span (Direct)

extension Set_Primitives.Set.Ordered.Small where Element: ~Copyable {
    /// Direct mutable span access to the set's elements in insertion order.
    ///
    /// - Warning: Modifying elements may invalidate uniqueness if the
    ///   modifications affect element equality/hash.
    /// - Note: Raw mutable-pointer access (C interop) is on the span:
    ///   `mutableSpan.withUnsafeMutableBufferPointer { … }`.
    @inlinable
    public var mutableSpan: MutableSpan<Element> {
        @_lifetime(&self)
        mutating get { buffer.mutableSpan }
    }
}
