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
public import Hash_Table_Primitives
import Index_Primitives

extension Set where Element: Hash.`Protocol` & ~Copyable {

    // MARK: - Ordered (Dynamically-Growing, Heap-Allocated)

    /// An ordered set that preserves insertion order with O(1) membership testing.
    ///
    /// Composes `Buffer<Element>.Linear` for element storage and
    /// `Hash.Table<Element>` for O(1) position lookup.
    // WHY: Category D — structural Sendable workaround; the type is
    // WHY: structurally value-safe but the compiler cannot synthesize
    // WHY: Sendable due to a stored pointer / generic parameter shape.
    @safe
    public struct Ordered {

        // MARK: - Stored Properties

        /// Element storage using Buffer.Linear from buffer-primitives.
        ///
        /// `@usableFromInline internal` ([MOD-036] refined-C): the hot
        /// `~Copyable`/`Copyable` operation surface co-located in this (type)
        /// module inlines cross-package to zero-witness-dispatch; the cold
        /// sequence/collection-family conformances in the ops module reach this
        /// storage only through the `package` windows in
        /// `Set.Ordered+ConformanceSupport.swift`.
        @usableFromInline
        internal var buffer: Buffer<Element>.Linear

        /// Hash table for O(1) position lookup.
        @usableFromInline
        internal var hashTable: Hash.Table<Element>

        // MARK: - Initialization

        /// Creates an empty ordered set.
        @inlinable
        public init() {
            self.buffer = Buffer<Element>.Linear(minimumCapacity: .zero)
            self.hashTable = Hash.Table<Element>(minimumCapacity: .zero)
        }

    }
}

// MARK: - Conditional Copyable

extension Set.Ordered: Copyable where Element: Copyable {}

// MARK: - Sendable

extension Set.Ordered: @unsafe @unchecked Sendable where Element: Sendable {}
