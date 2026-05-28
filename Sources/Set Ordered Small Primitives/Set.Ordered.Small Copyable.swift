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
public import Buffer_Linear_Small_Primitives
public import Memory_Contiguous_Primitives
public import Memory_Iterator_Primitives

import Cardinal_Primitives
import Index_Primitives
public import Ordinal_Primitives
public import Set_Primitives
public import Set_Ordered_Primitive
public import Buffer_Linear_Primitive
public import Buffer_Linear_Primitives
public import Buffer_Linear_Small_Primitive

// Note: Set.Ordered.Small is unconditionally ~Copyable (inline storage requires deinit),
// so it cannot conform to Swift.Sequence which requires Copyable.
// It conforms to Sequenceable which supports ~Copyable containers.

// ============================================================================
// MARK: - Iterable + Sequenceable (Copyable elements only)
// ============================================================================
//
// Re-uses Iterator.Chunk (multipass, borrowing, over the small-vec buffer span) +
// Buffer.Linear.Small.Scalar (single-pass, consuming), mirroring buffer-linear's
// Small variant. The borrowing Iterable iterator is tied to `self` via
// `@_lifetime(borrow self)`, so no snapshot copy is needed. No Swift.Sequence
// (Small is unconditionally ~Copyable).

// Memory.Contiguous.Protocol exposes the small-vec buffer's span so the
// memory→Iterable bridge can vend `Iterator.Chunk`. `withUnsafeBufferPointer`
// is provided in Set.Ordered.Small.swift (same module).
extension Set.Ordered.Small: Memory.Contiguous.`Protocol` where Element: Copyable {
    public var span: Swift.Span<Element> {
        @_lifetime(borrow self)
        @inlinable
        borrowing get { _buffer.span }
    }
}

// Iterable — multipass borrowing `makeIterator()` vended FOR FREE by the
// memory→Iterable bridge over Memory.Contiguous.Protocol, yielding Iterator.Chunk.
extension Set.Ordered.Small: Iterable where Element: Copyable {
    @_implements(Iterable, Iterator)
    public typealias IterableIterator = Iterator_Chunk_Primitives.Iterator.Chunk<Element>
}

// Sequenceable — single-pass consuming iterator. Enabled by `@frozen` on the
// Small struct, which permits the partial consume of `_buffer`.
extension Set.Ordered.Small: Sequenceable where Element: Copyable {
    @_implements(Sequenceable, Iterator)
    public typealias SequenceableIterator = Buffer<Element>.Linear.Small<inlineCapacity>.Scalar

    @inlinable
    public consuming func makeIterator() -> Buffer<Element>.Linear.Small<inlineCapacity>.Scalar {
        _buffer.makeIterator()
    }

    /// Returns the count as the underestimated count since we know the exact size.
    @inlinable
    public var underestimatedCount: Int { Int(bitPattern: count) }
}

// ============================================================================
// MARK: - Set.Protocol Conformance
// ============================================================================

extension Set.Ordered.Small: Set.`Protocol` {}

// ============================================================================
// MARK: - Sequence.Clearable Conformance
// ============================================================================

extension Set.Ordered.Small: Sequence.Clearable where Element: Copyable {
    /// Removes all elements from the set.
    ///
    /// Resets to inline mode if spilled.
    /// This enables `.forEach.consuming { }` pattern via `Property.Inout` extension.
    @inlinable
    public mutating func removeAll() {
        clear(keepingCapacity: false)
    }
}
