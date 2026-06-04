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

// MARK: - Sequenceable witness (makeIterator)
//
// The single-pass consuming iterator in insertion order — the `Copyable` witness for
// the cold `Sequenceable` conformance (declared in the ops module,
// Set.Ordered+Sequenceable.swift). A public member in the type module per
// [MOD-036] refined-C; delegates to the composed buffer's public makeIterator.

extension Set.Ordered where Element: Copyable {

    /// A single-pass consuming iterator in insertion order. Witness for `Sequenceable`.
    @inlinable
    public consuming func makeIterator() -> Buffer<Storage<Element>.Heap>.Linear.Scalar {
        buffer.makeIterator()
    }
}
