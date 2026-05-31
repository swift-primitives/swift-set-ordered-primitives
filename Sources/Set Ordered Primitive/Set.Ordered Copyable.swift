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

public import Cardinal_Primitives
import Index_Primitives
public import Ordinal_Primitives
public import Set_Primitives
public import Buffer_Linear_Primitive
public import Buffer_Linear_Primitives

// ============================================================================
// MARK: - Initialization (Copyable)
// ============================================================================

extension Set.Ordered {
    /// Creates an ordered set with reserved capacity.
    @inlinable
    public init(reservingCapacity capacity: Index<Element>.Count) throws(__SetOrderedError<Element>) {
        self.init()
        if capacity > .zero {
            self.reserve(capacity)
        }
    }
}

extension Set.Ordered where Element: Copyable {
    /// Creates an ordered set containing the elements of a sequence.
    @inlinable
    public init<S: Swift.Sequence>(_ elements: S) where S.Element == Element {
        self.init()
        for element in elements {
            insert(element)
        }
    }
}

// ============================================================================
// MARK: - Coordinated CoW
// ============================================================================

extension Set.Ordered where Element: Copyable {
    /// Ensures both buffer and hash table are uniquely owned.
    ///
    /// Each component is independently checked — fixes the latent bug where
    /// `reserve()` could make the buffer unique while the hash table remained shared.
    @inlinable
    mutating func makeUnique() {
        buffer.ensureUnique()
        hashTable.ensureUnique()
    }
}

// ============================================================================
// MARK: - Core Operations (Copyable - with CoW)
// ============================================================================

extension Set.Ordered where Element: Copyable {
    /// Inserts an element into the set (CoW-aware).
    @inlinable
    @discardableResult
    public mutating func insert(_ element: Element) -> (inserted: Bool, index: Index<Element>) {
        if let existing = hashTable.position(
            forHash: element.hashValue,
            equals: { idx in buffer[idx] == element }
        ) {
            return (false, existing)
        }

        makeUnique()
        let index = buffer.count.map(Ordinal.init)
        buffer.append(element)
        hashTable.insert(_unchecked: (), position: index, hashValue: element.hashValue)

        return (true, index)
    }

    /// Removes an element from the set (CoW-aware).
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

    /// Removes all elements from the set (CoW-aware).
    @inlinable
    public mutating func clear(keepingCapacity: Bool = false) {
        makeUnique()
        buffer.removeAll()
        hashTable.remove.all(keepingCapacity: keepingCapacity)
    }
}

// ============================================================================
// MARK: - Element Access (Copyable - returns copies)
// ============================================================================

extension Set.Ordered where Element: Copyable {
    /// Accesses the element at the specified index.
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

// ============================================================================
// MARK: - First/Last Accessors (Copyable)
// ============================================================================

extension Set.Ordered where Element: Copyable {
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

// ============================================================================
// MARK: - Drain (Copyable)
// ============================================================================

extension Set.Ordered where Element: Copyable {
    /// Removes and consumes all elements.
    @inlinable
    public mutating func drain(_ body: (consuming Element) -> Void) {
        guard count > .zero else { return }
        makeUnique()
        while !buffer.isEmpty {
            body(buffer.remove.first())
        }
        hashTable.remove.all(keepingCapacity: true)
    }
}

// ============================================================================
// MARK: - Mutable Span (Copyable - with CoW)
// ============================================================================

extension Set.Ordered where Element: Copyable {
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
            return buffer.mutableSpan
        }
    }
}

// ============================================================================
// MARK: - Description (Copyable)
// ============================================================================

#if !hasFeature(Embedded)
    extension Set.Ordered where Element: Copyable {
        /// A textual representation of the set.
        public var description: String {
            var result = "Set.Ordered(["
            var isFirst = true
            var index: Index<Element> = .zero
            let end = count.map(Ordinal.init)
            while index < end {
                if !isFirst { result += ", " }
                result += String(describing: buffer[index])
                isFirst = false
                index += .one
            }
            result += "])"
            return result
        }
    }
#endif
