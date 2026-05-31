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
// `Set.Ordered` does not conform to `Swift.Sequence`: the span-primitive iteration
// family is `~Copyable, ~Escapable` end-to-end and cannot back a Copyable stdlib
// `IteratorProtocol` without re-introducing a per-type Copyable iterator (deleted in
// the SE-0516 migration). This is the DEFERRED `Swift.Sequence`-interop axis (design
// §2.8 reconciled 2026-05-31): the migrated span-primitive types — Set.Ordered,
// Buffer.Linear, and Array (grep-verified: array-primitives has NO `Swift.Sequence`
// conformance, only a generic builder constraint) — all drop the per-type Copyable
// iterator. The eventual uniform shape is a single generic `Swift.Sequence` bridge
// (`where Element: Copyable`, vended once and inherited), settled ecosystem-wide
// at/before the ×16 fan-out — NOT a per-type wart baked onto the exemplar template.
// (A set's core surface is membership/algebra, not for-in; the drop is low-impact.)

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
