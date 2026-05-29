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
public import Buffer_Linear_Inline_Primitives

// MARK: - Iteration accessors ([MOD-036] refined-C)
//
// Set.Ordered.Static composes Buffer.Linear.Inline (a complete type with public
// span / makeIterator), so these delegate to the buffer's public API —
// no raw-storage windows. `span` and `makeIterator` import no sequence/collection-
// primitives, so they co-locate with the storage as plain `public` members.
// `span` is the `~Copyable` witness for the `Memory.Contiguous.Protocol`
// conformance (now co-located in this type module per the conformance-placement
// decision, Set.Ordered.Static+Memory.Contiguous.Protocol.swift); `makeIterator` is
// the `Copyable` witness for the cold `Sequenceable` conformance in the ops module.

extension Set.Ordered.Static where Element: ~Copyable {

    /// The elements in insertion order. Witness for `Memory.Contiguous.Protocol`.
    @inlinable
    public var span: Swift.Span<Element> {
        @_lifetime(borrow self)
        borrowing get { buffer.span }
    }
}

extension Set.Ordered.Static where Element: Copyable {

    /// A single-pass consuming iterator in insertion order. Witness for `Sequenceable`.
    ///
    /// Enabled by `@frozen` on the Static struct, which permits the partial consume
    /// of `buffer`.
    @inlinable
    public consuming func makeIterator() -> Buffer<Element>.Linear.Inline<capacity>.Scalar {
        buffer.makeIterator()
    }
}

// MARK: - Buffer Access (Escape Hatch for C Interop)

@_spi(Unsafe)
extension Set.Ordered.Static where Element: ~Copyable {
    /// Provides read-only access to the underlying contiguous storage.
    /// Witness for `Memory.Contiguous.Protocol`. Relaxed to `~Copyable`: the body
    /// already routes through `buffer.span` (itself `~Copyable`).
    @unsafe
    @inlinable
    public func withUnsafeBufferPointer<R, E: Swift.Error>(
        _ body: (UnsafeBufferPointer<Element>) throws(E) -> R
    ) throws(E) -> R {
        let span = buffer.span
        return try unsafe span.withUnsafeBufferPointer(body)
    }
}
