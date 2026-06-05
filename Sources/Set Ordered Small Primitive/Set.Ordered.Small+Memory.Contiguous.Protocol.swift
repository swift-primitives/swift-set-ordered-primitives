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
public import Storage_Small_Primitives
public import Storage_Primitive
public import Buffer_Linear_Primitive
public import Buffer_Linear_Primitives
public import Span_Protocol_Primitives
public import Buffer_Linear_Small_Primitive

// MARK: - Span.`Protocol` Conformance
//
// Co-located with the type and its span witness ([MOD-036] refined-C;
// conformance-placement decision, sibling to Set.Ordered.Small+Set.Protocol.swift):
// `Span.\`Protocol\`` is ~Copyable-compatible (`associatedtype Element:
// ~Copyable`); its single requirement `span` is witnessed below (`where Element:
// ~Copyable`), co-located with the type. This is the span capability,
// NOT iteration: the memory→Iterable bridge keys off `Span.\`Protocol\`
// where Self: Iterable` and continues to vend the borrowing `Iterator.Chunk` when
// the type also declares `: Iterable` (Copyable, in the ops module). `where Element:
// ~Copyable` is explicit so the bare extension does not implicitly gate `Copyable`.

extension Set.Ordered.Small: Span.`Protocol` where Element: ~Copyable {
    /// The elements in insertion order. Witness for `Span.\`Protocol\``.
    @inlinable
    public var span: Swift.Span<Element> {
        @_lifetime(borrow self)
        borrowing get { buffer.span }
    }
}
