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

public import Set_Primitives
public import Buffer_Linear_Primitive
public import Buffer_Linear_Primitives

// MARK: - Package window for cold ops-module conformances ([MOD-036] refined-C)
//
// `buffer` / `hashTable` are `@usableFromInline internal` so the hot operation
// surface co-located in this (type) module inlines cross-package to
// zero-witness-dispatch. The cold sequence/collection-family conformances
// (`Memory.Contiguous.Protocol`, `Sequenceable`, `Sequence.Consume`) live in the
// ops module (isolated per [MOD-004]) and reach the storage ONLY through the
// package windows below.
//
// These are deliberately:
//   - NOT public — encapsulation preserved (this is NOT Option A); and
//   - NOT @usableFromInline internal — the ops module is a *different* module
//     and could not see an `internal` symbol by source name.
// `package` is the minimal level that lets the ops module reference them. The
// conformances that use them are cold (per-consumer inline counts 2-6), so
// forgoing *their* cross-package inlining is the accepted trade-off; the hot
// surface is unaffected.

extension Set.Ordered where Element: Copyable {

    /// Borrowed span over the elements in insertion order. Package window for the
    /// cold `Memory.Contiguous.Protocol` conformance (`span`) in the ops module.
    @usableFromInline
    package var _span: Swift.Span<Element> {
        @_lifetime(borrow self)
        borrowing get { buffer.span }
    }

    /// Consuming window: makes the storage unique and surrenders the backing
    /// buffer, leaving the consumed `self` empty (destruction harmless). Package
    /// window for the cold `Sequence.Consume` conformance (`consume()`).
    @usableFromInline
    package consuming func _takeBuffer() -> Buffer<Element>.Linear {
        makeUnique()
        var consumeBuffer = Buffer<Element>.Linear(minimumCapacity: .zero)
        Swift.swap(&buffer, &consumeBuffer)
        return consumeBuffer
    }

    /// Consuming window: surrenders a single-pass scalar iterator over the
    /// buffer in insertion order. Package window for the cold `Sequenceable`
    /// conformance (`makeIterator()`).
    @usableFromInline
    package consuming func _makeScalar() -> Buffer<Element>.Linear.Scalar {
        buffer.makeIterator()
    }
}
