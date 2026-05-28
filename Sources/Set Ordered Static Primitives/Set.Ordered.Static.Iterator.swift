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
// `@_spi(Unsafe)` ([MOD-016] per-file): the `withUnsafeBufferPointer` witness for
// `Memory.Contiguous.Protocol` is the `@_spi(Unsafe)` hot op co-located in the type
// module ([MOD-036] refined-C); this conformance file must opt into the SPI to see it.
@_spi(Unsafe) public import Set_Ordered_Static_Primitive
public import Buffer_Linear_Primitive
public import Buffer_Linear_Inline_Primitives

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
//
// Witnesses (`span`, `makeIterator`, `withUnsafeBufferPointer`) are public members
// in the type module; these conformances are thin ([MOD-036] refined-C).

// Memory.Contiguous.Protocol exposes the inline buffer's span so the
// memory→Iterable bridge can vend `Iterator.Chunk`. `span` and
// `withUnsafeBufferPointer` are provided in the type module (same package).
extension Set.Ordered.Static: Memory.Contiguous.`Protocol` where Element: Copyable {}

// Iterable — multipass borrowing `makeIterator()` vended FOR FREE by the
// memory→Iterable bridge over Memory.Contiguous.Protocol, yielding Iterator.Chunk.
extension Set.Ordered.Static: Iterable where Element: Copyable {
    @_implements(Iterable, Iterator)
    public typealias IterableIterator = Iterator_Chunk_Primitives.Iterator.Chunk<Element>
}

// Sequenceable — single-pass consuming iterator. The consuming `makeIterator()`
// witness is a public member in the type module ([MOD-036] refined-C); this
// conformance is thin.
extension Set.Ordered.Static: Sequenceable where Element: Copyable {
    @_implements(Sequenceable, Iterator)
    public typealias SequenceableIterator = Buffer<Element>.Linear.Inline<capacity>.Scalar

    /// Returns the count as the underestimated count since we know the exact size.
    @inlinable
    public var underestimatedCount: Int { Int(bitPattern: count) }
}
