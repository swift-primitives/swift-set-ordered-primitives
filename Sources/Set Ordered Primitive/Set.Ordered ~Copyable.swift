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
public import Buffer_Linear_Primitive
import Buffer_Linear_Primitives

// ============================================================================
// MARK: - Properties
// ============================================================================

extension Set.Ordered where Element: ~Copyable {
    /// The number of elements in the set.
    @inlinable
    public var count: Index<Element>.Count { buffer.count }

    /// The current capacity of the set.
    @inlinable
    public var capacity: Index<Element>.Count { buffer.capacity }
}

// ============================================================================
// MARK: - Reserve Capacity
// ============================================================================

extension Set.Ordered where Element: ~Copyable {
    /// Reserves enough space to store the specified number of elements.
    @inlinable
    public mutating func reserve(_ minimumCapacity: Index<Element>.Count) {
        buffer.reserveCapacity(minimumCapacity)
    }
}

// ============================================================================
// MARK: - Borrowed Element Access
// ============================================================================

extension Set.Ordered where Element: ~Copyable {
    /// Accesses the element at the given index via closure.
    ///
    /// - Parameters:
    ///   - index: The index of the element.
    ///   - body: A closure that receives a borrowed reference to the element.
    /// - Returns: The result of the closure.
    /// - Precondition: The index must be in bounds.
    @inlinable
    public func withElement<R>(at index: Index<Element>, _ body: (borrowing Element) -> R) -> R {
        precondition(index < count, "Index out of bounds")
        return body(buffer[index])
    }

    /// Accesses the element at the given index via closure, with typed error on bounds failure.
    ///
    /// - Parameters:
    ///   - index: The index of the element.
    ///   - body: A closure that receives a borrowed reference to the element.
    /// - Returns: The result of the closure.
    /// - Throws: ``Set/Ordered/Error/bounds(_:)`` if the index is out of bounds.
    @inlinable
    public func withElement<R>(at index: Index<Element>, _ body: (borrowing Element) throws(__SetOrderedError<Element>) -> R) throws(__SetOrderedError<Element>) -> R {
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
        // Concrete Set.Protocol witness delegating its body over the shared
        // Hash.Table.Protocol membership terminal (`position(...) != nil`).
        hashTable.contains(
            forHash: element.hashValue,
            context: element,
            equals: { idx, elem in buffer[idx] == elem }
        )
    }
}

// ============================================================================
// MARK: - Span Access
// ============================================================================

extension Set.Ordered where Element: ~Copyable {
    /// Provides read-only span access to the set's elements in insertion order.
    ///
    /// - Parameter body: A closure that receives the span.
    /// - Returns: The value returned by the closure.
    /// - Throws: Rethrows any error thrown by the closure.
    @inlinable
    public func withSpan<R, E: Swift.Error>(
        _ body: (Span<Element>) throws(E) -> R
    ) throws(E) -> R {
        try body(buffer.span)
    }
}

// ============================================================================
// MARK: - Buffer Access (Escape Hatch for C Interop)
// ============================================================================

@_spi(Unsafe)
extension Set.Ordered where Element: ~Copyable {
    /// Provides read-only access to the underlying contiguous storage.
    @unsafe
    @inlinable
    public func withUnsafeBufferPointer<R, E: Swift.Error>(
        _ body: (UnsafeBufferPointer<Element>) throws(E) -> R
    ) throws(E) -> R {
        let span = buffer.span
        return try unsafe span.withUnsafeBufferPointer(body)
    }
}
