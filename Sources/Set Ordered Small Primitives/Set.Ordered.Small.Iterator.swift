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
public import Memory_Iterator_Primitives
// `@_spi(Unsafe)` ([MOD-016] per-file): the `withUnsafeBufferPointer` witness for
// `Memory.Contiguous.Protocol` is the `@_spi(Unsafe)` hot op co-located in the type
// module ([MOD-036] refined-C); this conformance file must opt into the SPI to see it.
@_spi(Unsafe) public import Set_Ordered_Small_Primitive
public import Buffer_Linear_Primitive
public import Buffer_Linear_Small_Primitives

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
//
// Witnesses (`span`, `makeIterator`, `withUnsafeBufferPointer`) are public members
// in the type module; these conformances are thin ([MOD-036] refined-C).

// `Memory.Contiguous.Protocol` conformance now lives in the type module
// (Set.Ordered.Small+Memory.Contiguous.Protocol.swift, `where Element: ~Copyable`)
// per the conformance-placement decision.
//
// Iterable — multipass borrowing `makeIterator()` vended FOR FREE by the
// memory→Iterable bridge over that conformance, yielding Iterator.Chunk.
extension Set.Ordered.Small: Iterable where Element: Copyable {
    @_implements(Iterable, Iterator)
    public typealias IterableIterator = Iterator_Chunk_Primitives.Iterator.Chunk<Element>
}

// Sequenceable — single-pass consuming iterator. The consuming `makeIterator()`
// witness is a public member in the type module ([MOD-036] refined-C); this
// conformance is thin. Enabled by `@frozen` on the Small struct.
extension Set.Ordered.Small: Sequenceable where Element: Copyable {
    @_implements(Sequenceable, Iterator)
    public typealias SequenceableIterator = Buffer<Element>.Linear.Small<inlineCapacity>.Scalar

    /// Returns the count as the underestimated count since we know the exact size.
    @inlinable
    public var underestimatedCount: Int { Int(bitPattern: count) }
}
