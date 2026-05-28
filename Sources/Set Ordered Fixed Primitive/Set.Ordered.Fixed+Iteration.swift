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
// span / makeIterator / consume), so these delegate to the buffer's public API —
// no raw-storage windows. `span` and `makeIterator` import no sequence/collection-
// primitives, so they co-locate with the storage as plain `public` members; the
// cold `Memory.Contiguous.Protocol` / `Sequenceable` conformances in the ops module
// are thin and use them as witnesses (inlinable cross-package).
//
// `consume()` is the one ops-bound member (its `Sequence.Consume.View` return type
// pulls `Sequence_Primitives`, kept out of this lean type module), so it reaches
// storage through the single `package` accessor below — named, not underscored, and
// non-`@usableFromInline` since the cold `consume()` is non-`@inlinable`.

extension Set.Ordered.Fixed where Element: Copyable {

    /// The elements in insertion order. Witness for `Memory.Contiguous.Protocol`.
    @inlinable
    public var span: Swift.Span<Element> {
        @_lifetime(borrow self)
        borrowing get { buffer.span }
    }

    /// A single-pass consuming iterator in insertion order. Witness for `Sequenceable`.
    @inlinable
    public consuming func makeIterator() -> Buffer<Element>.Linear.Bounded.Scalar {
        buffer.makeIterator()
    }

    /// Makes the storage unique and surrenders the backing buffer, leaving the
    /// consumed `self` empty. Package accessor for the ops-bound `Sequence.Consume`
    /// conformance (`consume()`).
    package consuming func takeBuffer() -> Buffer<Element>.Linear.Bounded {
        makeUnique()
        var consumeBuffer = Buffer<Element>.Linear.Bounded(minimumCapacity: .zero)
        Swift.swap(&buffer, &consumeBuffer)
        return consumeBuffer
    }
}
