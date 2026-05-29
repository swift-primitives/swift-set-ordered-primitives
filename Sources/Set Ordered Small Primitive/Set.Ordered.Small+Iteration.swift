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
// / makeIterator), so these delegate to the buffer's public API — no
// raw-storage windows. `span` and `makeIterator` import no sequence/collection-
// primitives, so they co-locate with the storage as plain `public` members.
// `span` is the `~Copyable` witness for the `Memory.Contiguous.Protocol`
// conformance (now co-located in this type module per the conformance-placement
// decision, Set.Ordered.Small+Memory.Contiguous.Protocol.swift); `makeIterator` is
// the `Copyable` witness for the cold `Sequenceable` conformance in the ops module.

extension Set.Ordered.Small where Element: ~Copyable {

    /// The elements in insertion order. Witness for `Memory.Contiguous.Protocol`.
    @inlinable
    public var span: Swift.Span<Element> {
        @_lifetime(borrow self)
        borrowing get { buffer.span }
    }
}

extension Set.Ordered.Small where Element: Copyable {

    /// A single-pass consuming iterator in insertion order. Witness for `Sequenceable`.
    ///
    /// Enabled by `@frozen` on the Small struct, which permits the partial consume
    /// of `buffer`.
    @inlinable
    public consuming func makeIterator() -> Buffer<Element>.Linear.Small<inlineCapacity>.Scalar {
        buffer.makeIterator()
    }
}

// MARK: - Buffer Access (Escape Hatch for C Interop)

@_spi(Unsafe)
extension Set.Ordered.Small where Element: ~Copyable {
    /// Provides read-only access to the underlying contiguous storage.
    /// Witness for `Memory.Contiguous.Protocol`.
    ///
    /// - Warning: Prefer ``withSpan(_:)`` for safe access.
    @unsafe
    @inlinable
    public func withUnsafeBufferPointer<R, E: Swift.Error>(
        _ body: (UnsafeBufferPointer<Element>) throws(E) -> R
    ) throws(E) -> R {
        // Relaxed to `~Copyable` via `buffer.span` (itself `~Copyable`); the buffer's
        // own `withUnsafeBufferPointer` is `Copyable`-gated, so route through the
        // span — matching base/Fixed/Static.
        let span = buffer.span
        return try unsafe span.withUnsafeBufferPointer(body)
    }
}

@_spi(Unsafe)
extension Set.Ordered.Small where Element: Copyable {
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
