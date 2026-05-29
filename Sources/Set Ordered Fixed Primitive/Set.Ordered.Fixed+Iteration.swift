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
public import Buffer_Linear_Bounded_Primitive
public import Buffer_Linear_Bounded_Primitives

// MARK: - Iteration accessors ([MOD-036] refined-C)
//
// Set.Ordered.Fixed composes Buffer.Linear.Bounded (a complete type with public
// span / makeIterator), so these delegate to the buffer's public API —
// no raw-storage windows. `span` and `makeIterator` import no sequence/collection-
// primitives, so they co-locate with the storage as plain `public` members.
// `span` is the `~Copyable` witness for the `Memory.Contiguous.Protocol`
// conformance (now co-located in this type module per the conformance-placement
// decision, Set.Ordered.Fixed+Memory.Contiguous.Protocol.swift); `makeIterator` is
// the `Copyable` witness for the cold `Sequenceable` conformance in the ops module.

extension Set.Ordered.Fixed where Element: ~Copyable {

    /// The elements in insertion order. Witness for `Memory.Contiguous.Protocol`.
    @inlinable
    public var span: Swift.Span<Element> {
        @_lifetime(borrow self)
        borrowing get { buffer.span }
    }
}

extension Set.Ordered.Fixed where Element: Copyable {

    /// A single-pass consuming iterator in insertion order. Witness for `Sequenceable`.
    @inlinable
    public consuming func makeIterator() -> Buffer<Element>.Linear.Bounded.Scalar {
        buffer.makeIterator()
    }
}
