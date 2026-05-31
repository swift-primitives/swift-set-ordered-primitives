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
public import Memory_Contiguous_Primitives

// MARK: - Memory.Contiguous.Protocol Conformance
//
// Co-located with the type and its span witness ([MOD-036] refined-C;
// conformance-placement decision, sibling to Set.Ordered.Small+Set.Protocol.swift):
// `Memory.Contiguous.Protocol` is ~Copyable-compatible (`associatedtype Element:
// ~Copyable`); its single requirement `span`
// (Set.Ordered.Small+Iteration.swift, `where Element: ~Copyable`) is witnessed in
// this type module. This is the memory-layer span capability, NOT iteration: the
// memory→Iterable bridge keys off `Memory.ContiguousProtocol where Self: Iterable`
// and continues to vend the borrowing `Iterator.Chunk` when the type also declares
// `: Iterable` (Copyable, in the ops module). `where Element: ~Copyable` is explicit
// so the bare extension does not implicitly gate `Copyable`.

extension Set.Ordered.Small: Memory.Contiguous.`Protocol` where Element: ~Copyable {}
