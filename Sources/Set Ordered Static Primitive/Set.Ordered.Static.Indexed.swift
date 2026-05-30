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

// MARK: - Set.Ordered.Static.Indexed

extension Set_Primitives.Set.Ordered.Static where Element: Copyable {
    /// A wrapper providing phantom-typed index access to inline-capacity ordered set storage.
    ///
    /// `Indexed<Tag>` wraps a `Set<Element>.Ordered.Static` and provides subscript access via
    /// `Index<Tag>.Bounded<capacity>` instead of `Index<Element>.Bounded<capacity>`, enabling
    /// type-safe indexing where the phantom type differs from the element type. It completes the
    /// variant-uniform `Indexed` blueprint across all four ordered-set variants.
    ///
    /// ## Bounded indices
    ///
    /// `Static` is capacity-bounded (inline `Buffer.Linear.Inline<capacity>`), so its typed index
    /// is the *bounded* `Index<Tag>.Bounded<capacity>` — the index carries the capacity bound in
    /// its type. This is the bounded-variant counterpart to the plain `Index<Tag>` surface of the
    /// growable variants (dynamic, `.Small`); the fan-out blueprint applies the same rule (a
    /// bounded discipline's `Indexed` uses bounded indices).
    ///
    /// ## Usage
    ///
    /// ```swift
    /// enum NodeTag {}
    /// var storage = try Set<Payload>.Ordered.Static<8> { … }
    ///
    /// var indexed = Set<Payload>.Ordered.Static<8>.Indexed<NodeTag>(storage)
    /// let node: Index<NodeTag>.Bounded<8> = ...
    /// indexed[node]  // Access via typed bounded index
    /// ```
    ///
    /// ## Design
    ///
    /// Follows the `Property.Typed` pattern: the nested type "smuggles" the `Tag` generic
    /// parameter into scope, allowing typed operations without protocols.
    // WHY: ~Copyable — Set.Ordered.Static is UNCONDITIONALLY ~Copyable (move-only inline
    // storage), unlike the heap-backed dynamic/Fixed variants, so the wrapper mirrors the
    // variant's copyability. (The dynamic/Fixed Indexed are Copyable.)
    // WHY: Category D — structural Sendable workaround (SP-4); Tag never stored, @unchecked
    // exists because the phantom Tag blocks Sendable inference.
    // WHEN TO REMOVE: When compiler gains structural Sendable through phantom params.
    // TRACKING: unsafe-audit-findings.md Category D SP-4.
    public struct Indexed<Tag: Copyable>: ~Copyable, @unchecked Sendable {
        @usableFromInline
        var storage: Set_Primitives.Set<Element>.Ordered.Static<capacity>

        /// Creates an indexed wrapper around the given storage.
        ///
        /// - Parameter storage: The inline-capacity ordered set to wrap.
        @inlinable
        public init(_ storage: consuming Set_Primitives.Set<Element>.Ordered.Static<capacity>) {
            self.storage = storage
        }

        /// The phantom-typed count for bounds checking.
        @inlinable
        public var count: Index_Primitives.Index<Tag>.Count {
            storage.count.retag(Tag.self)
        }

        /// Accesses the element at the given phantom-typed bounded index.
        ///
        /// - Parameter index: The typed bounded index of the element to access.
        @inlinable
        public subscript(index: Index_Primitives.Index<Tag>.Bounded<capacity>) -> Element {
            get {
                let elementIndex = index.retag(Element.self)
                return storage[elementIndex]
            }
        }
    }
}

// MARK: - Passthrough Properties

extension Set_Primitives.Set.Ordered.Static.Indexed where Element: Copyable {
    /// Whether the set is empty.
    @inlinable
    public var isEmpty: Bool { storage.isEmpty }

    /// Whether the set is at full capacity.
    @inlinable
    public var isFull: Bool { storage.isFull }
}

// MARK: - Membership Operations

extension Set_Primitives.Set.Ordered.Static.Indexed where Element: Copyable {
    /// Returns whether the set contains the given element.
    @inlinable
    public func contains(_ element: Element) -> Bool {
        storage.contains(element)
    }

    /// Returns the typed bounded index of the given element, or `nil` if not present.
    @inlinable
    public func index(_ element: Element) -> Index_Primitives.Index<Tag>.Bounded<capacity>? {
        guard let rawIndex = storage.index(element) else { return nil }
        return rawIndex.retag(Tag.self)
    }
}

// MARK: - Mutating Operations

extension Set_Primitives.Set.Ordered.Static.Indexed where Element: Copyable {
    /// Inserts an element into the set.
    ///
    /// - Parameter element: The element to insert.
    /// - Returns: A tuple indicating whether insertion occurred and the element's typed bounded index.
    /// - Throws: ``Error/overflow`` if the set is full.
    @inlinable
    @discardableResult
    public mutating func insert(
        _ element: Element
    ) throws(__SetOrderedInlineError<Element>) -> (inserted: Bool, index: Index_Primitives.Index<Tag>.Bounded<capacity>) {
        let result = try storage.insert(element)
        return (result.inserted, result.index.retag(Tag.self))
    }

    /// Removes an element from the set.
    ///
    /// - Parameter element: The element to remove.
    /// - Returns: The removed element, or `nil` if not present.
    @inlinable
    @discardableResult
    public mutating func remove(_ element: Element) -> Element? {
        storage.remove(element)
    }

    /// Removes all elements from the set.
    @inlinable
    public mutating func clear() {
        storage.clear()
    }
}

// MARK: - First/Last Accessors

extension Set_Primitives.Set.Ordered.Static.Indexed where Element: Copyable {
    /// The first element, or `nil` if the set is empty.
    @inlinable
    public var first: Element? { storage.first }

    /// The last element, or `nil` if the set is empty.
    @inlinable
    public var last: Element? { storage.last }
}
