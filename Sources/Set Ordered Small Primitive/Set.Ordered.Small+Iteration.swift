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
public import Buffer_Linear_Small_Primitive
public import Buffer_Linear_Small_Primitives

// MARK: - Iteration accessors ([MOD-036] refined-C)
//
// Set.Ordered.Small composes Buffer.Linear.Small (a complete type with public span
// / makeIterator / consume), so these delegate to the buffer's public API — no
// raw-storage windows. `span` and `makeIterator` import no sequence/collection-
// primitives, so they co-locate with the storage as plain `public` members; the cold
// `Memory.Contiguous.Protocol` / `Sequenceable` conformances in the ops module are
// thin and use them as witnesses (inlinable cross-package).
//
// `consume()` is the one ops-bound member (its `Sequence.Consume.View` return type
// pulls `Sequence_Primitives`, kept out of this lean type module), so it reaches
// storage through the single `package` accessor below — named, not underscored, and
// non-`@usableFromInline` since the cold `consume()` is non-`@inlinable`.

extension Set.Ordered.Small where Element: Copyable {

    /// The elements in insertion order. Witness for `Memory.Contiguous.Protocol`.
    @inlinable
    public var span: Swift.Span<Element> {
        @_lifetime(borrow self)
        borrowing get { buffer.span }
    }

    /// A single-pass consuming iterator in insertion order. Witness for `Sequenceable`.
    ///
    /// Enabled by `@frozen` on the Small struct, which permits the partial consume
    /// of `buffer`.
    @inlinable
    public consuming func makeIterator() -> Buffer<Element>.Linear.Small<inlineCapacity>.Scalar {
        buffer.makeIterator()
    }
}

extension Set.Ordered.Small {
    /// Surrenders the backing small-buffer, leaving the consumed `self` empty. Package
    /// accessor for the ops-bound `Sequence.Consume` conformance (`consume()`).
    ///
    /// Enabled by `@frozen` (partial consume of `buffer`). Returning `buffer`
    /// destroys the spill-only `hashTable` (releasing it), which is the surrender
    /// the ops-bound `consume()` relies on.
    package consuming func takeBuffer() -> Buffer<Element>.Linear.Small<inlineCapacity> {
        buffer
    }
}

// MARK: - Buffer Access (Escape Hatch for C Interop)

@_spi(Unsafe)
extension Set.Ordered.Small where Element: Copyable {
    /// Provides read-only access to the underlying contiguous storage.
    /// Witness for `Memory.Contiguous.Protocol`.
    ///
    /// - Warning: Prefer ``withSpan(_:)`` for safe access.
    @unsafe
    @inlinable
    public func withUnsafeBufferPointer<R, E: Swift.Error>(
        _ body: (UnsafeBufferPointer<Element>) throws(E) -> R
    ) throws(E) -> R {
        try unsafe buffer.withUnsafeBufferPointer(body)
    }

    /// Provides mutable access to the underlying contiguous storage.
    ///
    /// - Warning: Prefer ``withMutableSpan(_:)`` for safe access.
    /// - Warning: Modifying elements may invalidate uniqueness.
    @unsafe
    @inlinable
    public mutating func withUnsafeMutableBufferPointer<R, E: Swift.Error>(
        _ body: (UnsafeMutableBufferPointer<Element>) throws(E) -> R
    ) throws(E) -> R {
        try unsafe buffer.withUnsafeMutableBufferPointer(body)
    }
}
