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

public import Memory_Contiguous_Primitives

// MARK: - Memory.Contiguous.Protocol Conformance
//
// Co-located with the type and its span witness ([MOD-036] refined-C;
// conformance-placement decision, sibling to Set.Ordered+Set.Protocol.swift):
// `Memory.Contiguous.Protocol` is ~Copyable-compatible (`associatedtype Element:
// ~Copyable`), and both witnesses live in this type module — `span`
// (Set.Ordered+Iteration.swift, `where Element: ~Copyable`) and the
// `@_spi(Unsafe) withUnsafeBufferPointer` (Set.Ordered ~Copyable.swift,
// `where Element: ~Copyable`) — so the span-access conformance lives here too, at
// the `~Copyable` level. This is the memory-layer span capability, NOT iteration:
// the memory→Iterable bridge keys off `Memory.ContiguousProtocol where Self:
// Iterable` and continues to vend the borrowing `Iterator.Chunk` when the type
// also declares `: Iterable` (Copyable, in the ops module).

extension Set.Ordered: Memory.Contiguous.`Protocol` where Element: ~Copyable {}
