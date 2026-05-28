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
@_spi(Unsafe) public import Set_Ordered_Fixed_Primitive
public import Set_Primitives
public import Buffer_Linear_Bounded_Primitive
public import Buffer_Linear_Bounded_Primitives

// ============================================================================
// MARK: - Iterable + Sequenceable (Copyable elements only)
// ============================================================================
//
// Re-uses Iterator.Chunk (multipass, borrowing) + Buffer.Linear.Bounded.Scalar
// (single-pass, consuming), mirroring buffer-linear. No Swift.Sequence — the
// iteration family is ~Copyable end-to-end.
//
// Witnesses (`span`, `makeIterator`, `withUnsafeBufferPointer`) are public members
// in the type module; these conformances are thin ([MOD-036] refined-C).

// Memory.Contiguous.Protocol exposes the insertion-ordered span so the
// memory→Iterable bridge can vend `Iterator.Chunk`. `span` and
// `withUnsafeBufferPointer` are provided in the type module (same package).
extension Set.Ordered.Fixed: Memory.Contiguous.`Protocol` where Element: Copyable {}

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

    // `makeIterator()` witness is a public member in the type module
    // ([MOD-036] refined-C); this conformance is thin.

    /// Returns the count as the underestimated count since we know the exact size.
    @inlinable
    public var underestimatedCount: Int { Int(bitPattern: count) }
}
