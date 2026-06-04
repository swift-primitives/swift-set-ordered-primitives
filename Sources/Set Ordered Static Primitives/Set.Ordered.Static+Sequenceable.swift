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

public import Sequence_Primitives
public import Set_Ordered_Static_Primitive
public import Buffer_Linear_Primitive
public import Buffer_Linear_Inline_Primitives

// MARK: - Sequenceable (single-pass, consuming)
//
// Re-uses Buffer.Linear.Inline.Scalar (single-pass, consuming), mirroring buffer-linear.
// The consuming `makeIterator()` witness is a public member in the type module
// (Set.Ordered.Static+Sequenceable.swift) per [MOD-036] refined-C; this conformance is thin.
//
// `Set.Ordered.Static` does not conform to `Swift.Sequence`: the span-primitive iteration
// family is `~Copyable, ~Escapable` end-to-end and cannot back a Copyable stdlib
// `IteratorProtocol` without re-introducing a per-type Copyable iterator (deleted in
// the SE-0516 migration). This is the DEFERRED `Swift.Sequence`-interop axis settled
// ecosystem-wide at/before the ×16 fan-out — see set-ordered-capability-composition.md
// §2.8 / §3 (one generic `Swift.Sequence` bridge `where Element: Copyable`, vended once).

extension Set.Ordered.Static: Sequenceable where Element: Copyable {
    @_implements(Sequenceable, Iterator)
    public typealias SequenceableIterator = Buffer<Storage<Element>.Heap>.Linear.Inline<capacity>.Scalar

    /// Returns the count as the underestimated count since we know the exact size.
    @inlinable
    public var underestimatedCount: Int { Int(bitPattern: count) }
}
