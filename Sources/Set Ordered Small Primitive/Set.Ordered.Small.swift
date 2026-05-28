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

public import Set_Ordered_Primitive
public import Buffer_Linear_Primitive
public import Buffer_Linear_Small_Primitive
import Hash_Table_Primitives
import Index_Primitives

extension Set.Ordered where Element: ~Copyable {

    // MARK: - Small (SmallVec Pattern)

    /// An ordered set with small-buffer optimization (SmallVec pattern).
    ///
    /// Composes `Buffer<Element>.Linear.Small<inlineCapacity>` for element storage
    /// and `Hash.Table<Element>` after spill.
    ///
    /// Inline mode uses O(n) linear scan — no hash table overhead for small sizes.
    /// Hash table activates only on spill.
    // @frozen lifts the non-frozen partial-consume restriction so the consuming
    // `Sequenceable.makeIterator()` can extract `buffer`. ABI-freeze is fine
    // pre-1.0 (principal-approved).
    @frozen
    public struct Small<let inlineCapacity: Int>: ~Copyable {
        /// Element cleanup is handled by Storage.Inline's deinit (inline path) or Storage.Heap's deinit (spilled path).

        /// Element storage — handles inline/heap dispatch internally.
        ///
        /// `@usableFromInline internal` ([MOD-036] refined-C): the hot
        /// `~Copyable`/`Copyable` operation surface co-located in this (type)
        /// module inlines cross-package to zero-witness-dispatch; the cold
        /// sequence/collection-family conformances in the ops module reach this
        /// storage only through the public `span` / `makeIterator` witnesses and
        /// the `package takeBuffer()` accessor in `Set.Ordered.Small+Iteration.swift`.
        @usableFromInline
        internal var buffer: Buffer<Element>.Linear.Small<inlineCapacity>

        /// Hash table — non-nil after spill.
        @usableFromInline
        internal var hashTable: Hash.Table<Element>?

        /// Creates an empty small ordered set.
        @inlinable
        public init() {
            self.buffer = Buffer<Element>.Linear.Small<inlineCapacity>()
            self.hashTable = nil
        }
    }
}

// MARK: - Sendable

extension Set.Ordered.Small: @unsafe @unchecked Sendable where Element: Sendable {}
