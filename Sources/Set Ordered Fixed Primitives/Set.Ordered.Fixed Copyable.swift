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

public import Iterator_Chunk_Primitives
public import Iterable
public import Sequence_Primitives
public import Memory_Contiguous_Primitives
public import Memory_Iterator_Primitives

import Cardinal_Primitives
import Index_Primitives
internal import Ordinal_Primitives
public import Set_Primitives
public import Set_Ordered_Primitive
public import Buffer_Linear_Bounded_Primitive
public import Buffer_Linear_Bounded_Primitives
public import Buffer_Linear_Primitive

// ============================================================================
// MARK: - Iterable + Sequenceable (Copyable elements only)
// ============================================================================
//
// Re-uses Iterator.Chunk (multipass, borrowing) + Buffer.Linear.Bounded.Scalar
// (single-pass, consuming), mirroring buffer-linear. No Swift.Sequence — the
// iteration family is ~Copyable end-to-end.

// Memory.Contiguous.Protocol exposes the insertion-ordered span so the
// memory→Iterable bridge can vend `Iterator.Chunk`. `withUnsafeBufferPointer`
// is provided in Set.Ordered.Fixed.swift (same module).
extension Set.Ordered.Fixed: Memory.Contiguous.`Protocol` where Element: Copyable {
    public var span: Swift.Span<Element> {
        @_lifetime(borrow self)
        @inlinable
        borrowing get { buffer.span }
    }
}

// Iterable — the multipass borrowing `makeIterator()` is vended FOR FREE by the
// memory→Iterable bridge over the Memory.Contiguous.Protocol conformance above,
// yielding `Iterator.Chunk` (no hand-written iterator).
extension Set.Ordered.Fixed: Iterable where Element: Copyable {
    @_implements(Iterable, Iterator)
    public typealias IterableIterator = Iterator_Chunk_Primitives.Iterator.Chunk<Element>
}

extension Set.Ordered.Fixed: Sequenceable where Element: Copyable {
    @_implements(Sequenceable, Iterator)
    public typealias SequenceableIterator = Buffer<Element>.Linear.Bounded.Scalar

    @inlinable
    public consuming func makeIterator() -> Buffer<Element>.Linear.Bounded.Scalar {
        buffer.makeIterator()
    }

    /// Returns the count as the underestimated count since we know the exact size.
    @inlinable
    public var underestimatedCount: Int { Int(bitPattern: count) }
}

// ============================================================================
// MARK: - Sequence.Clearable Conformance
// ============================================================================

extension Set.Ordered.Fixed: Sequence.Clearable where Element: Copyable {
    /// Removes all elements from the set.
    ///
    /// The capacity remains unchanged.
    /// This enables `.forEach.consuming { }` pattern via `Property.Inout` extension.
    @inlinable
    public mutating func removeAll() {
        clear(keepingCapacity: false)
    }
}

// ============================================================================
// MARK: - Set.Protocol Conformance
// ============================================================================

extension Set.Ordered.Fixed: Set.`Protocol` {}

// ============================================================================
// MARK: - ExpressibleByArrayLiteral
// ============================================================================

extension Set.Ordered.Fixed: ExpressibleByArrayLiteral where Element: Copyable {
    @inlinable
    public init(arrayLiteral elements: Element...) {
        self = try! Self(capacity: .init(Cardinal(UInt(elements.count))))
        for element in elements {
            try! insert(element)
        }
    }
}
