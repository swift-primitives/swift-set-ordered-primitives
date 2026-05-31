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

public import Iterable
public import Iterator_Chunk_Primitives
public import Sequence_Primitives
public import Memory_Iterator_Primitives
// `@_spi(Unsafe)` ([MOD-016] per-file): the `withUnsafeBufferPointer` witness for
// `Memory.Contiguous.Protocol` is the `@_spi(Unsafe)` hot op co-located in the type
// module ([MOD-036] refined-C); this conformance file must opt into the SPI to see it.
@_spi(Unsafe) public import Set_Ordered_Primitive
public import Buffer_Linear_Primitive
public import Buffer_Linear_Primitives

// MARK: - Iterable + Sequenceable (Copyable elements only)
//
// Re-uses iterator-primitives' `Iterator.Chunk` (multipass, borrowing) for
// `Iterable` and `Buffer.Linear.Scalar` (single-pass, consuming) for
// `Sequenceable` — mirroring buffer-linear's dual conformance.
//
// `Iterable.makeIterator()` is vended FOR FREE by the memory→Iterable bridge
// over the `Memory.Contiguous.Protocol` conformance (no hand-written iterator);
// the bridge constructs `Iterator.Chunk(self.span)`, so the span lifetime ties
// to `self` cleanly.
//
// `Set.Ordered` no longer conforms to `Swift.Sequence`: the iteration family is
// `~Copyable, ~Escapable` end-to-end, which cannot back a Copyable stdlib
// `IteratorProtocol`. Matches buffer-linear; PENDING ecosystem Swift.Sequence-
// interop reconciliation (array-primitives still keeps Swift.Sequence where
// Element: Copyable — the inconsistency is an ecosystem-wide decision to settle
// uniformly later). Reversible; a set's core surface is membership/algebra, not
// for-in, so the drop is low-impact now.

// `Memory.Contiguous.Protocol` conformance now lives in the type module
// (Set.Ordered+Memory.Contiguous.Protocol.swift, `where Element: ~Copyable`) per
// the conformance-placement decision. The memory→Iterable bridge keys off that
// conformance + the `Iterable` conformance below to vend `Iterator.Chunk`.
extension Set.Ordered: Iterable where Element: ~Copyable {
    @_implements(Iterable, Iterator)
    public typealias IterableIterator = Iterator_Chunk_Primitives.Iterator.Chunk<Element>
}

extension Set.Ordered: Sequenceable where Element: Copyable {
    @_implements(Sequenceable, Iterator)
    public typealias SequenceableIterator = Buffer<Element>.Linear.Scalar

    // `makeIterator()` witness is a public member in the type module
    // ([MOD-036] refined-C); this conformance is thin.

    /// Returns the count as the underestimated count since we know the exact size.
    @inlinable
    public var underestimatedCount: Int { Int(bitPattern: count) }
}
