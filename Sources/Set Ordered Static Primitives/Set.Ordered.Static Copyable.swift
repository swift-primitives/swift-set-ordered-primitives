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
public import Buffer_Linear_Inline_Primitives
public import Memory_Contiguous_Primitives
public import Memory_Iterator_Primitives

import Cardinal_Primitives
import Index_Primitives
public import Ordinal_Primitives
public import Set_Primitives
public import Set_Ordered_Primitive
public import Buffer_Linear_Primitive
public import Buffer_Linear_Primitives

// Note: Set.Ordered.Static is unconditionally ~Copyable (inline storage requires deinit),
// so it cannot conform to Swift.Sequence which requires Copyable.
// It conforms to Sequenceable which supports ~Copyable containers.

// ============================================================================
// MARK: - Iterable + Sequenceable (Copyable elements only)
// ============================================================================
//
// Re-uses Iterator.Chunk (multipass, borrowing, over the inline buffer span) +
// Buffer.Linear.Inline.Scalar (single-pass, consuming), mirroring buffer-linear's
// Inline variant. The borrowing Iterable iterator is tied to `self` via
// `@_lifetime(borrow self)`, so no snapshot copy is needed. No Swift.Sequence
// (Static is unconditionally ~Copyable).

// Memory.Contiguous.Protocol exposes the inline buffer's span so the
// memory→Iterable bridge can vend `Iterator.Chunk`.
extension Set.Ordered.Static: Memory.Contiguous.`Protocol` where Element: Copyable {
    public var span: Swift.Span<Element> {
        @_lifetime(borrow self)
        @inlinable
        borrowing get { _buffer.span }
    }

    @inlinable
    public func withUnsafeBufferPointer<R, E: Swift.Error>(
        _ body: (UnsafeBufferPointer<Element>) throws(E) -> R
    ) throws(E) -> R {
        let span = _buffer.span
        return try unsafe span.withUnsafeBufferPointer(body)
    }
}

// Iterable — multipass borrowing `makeIterator()` vended FOR FREE by the
// memory→Iterable bridge over Memory.Contiguous.Protocol, yielding Iterator.Chunk.
extension Set.Ordered.Static: Iterable where Element: Copyable {
    @_implements(Iterable, Iterator)
    public typealias IterableIterator = Iterator_Chunk_Primitives.Iterator.Chunk<Element>
}

// Sequenceable — single-pass consuming iterator. Enabled by `@frozen` on the
// Static struct, which permits the partial consume of `_buffer`.
extension Set.Ordered.Static: Sequenceable where Element: Copyable {
    @_implements(Sequenceable, Iterator)
    public typealias SequenceableIterator = Buffer<Element>.Linear.Inline<capacity>.Scalar

    @inlinable
    public consuming func makeIterator() -> Buffer<Element>.Linear.Inline<capacity>.Scalar {
        _buffer.makeIterator()
    }

    /// Returns the count as the underestimated count since we know the exact size.
    @inlinable
    public var underestimatedCount: Int { Int(bitPattern: count) }
}

// ============================================================================
// MARK: - Set.Protocol Conformance
// ============================================================================

extension Set.Ordered.Static: Set.`Protocol` {}

// ============================================================================
// MARK: - Sequence.Clearable Conformance
// ============================================================================

extension Set.Ordered.Static: Sequence.Clearable where Element: Copyable {
    /// Removes all elements from the set.
    ///
    /// This enables `.forEach.consuming { }` pattern via `Property.Inout` extension.
    @inlinable
    public mutating func removeAll() {
        clear()
    }
}
