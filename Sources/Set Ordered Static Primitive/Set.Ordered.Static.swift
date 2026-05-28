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
public import Buffer_Linear_Inline_Primitives
import Hash_Table_Static_Primitives
import Index_Primitives

extension Set.Ordered where Element: ~Copyable {

    // MARK: - Static (Fixed-Capacity, Inline Storage)

    /// A fixed-capacity, inline-storage ordered set with compile-time capacity.
    ///
    /// Composes `Buffer<Element>.Linear.Inline<capacity>` for element storage and
    /// `Hash.Table<Element>.Static<capacity>` for O(1) position lookup.
    ///
    /// - Precondition: `capacity` must be a power of two (required by Hash.Table.Static).
    // @frozen lifts the non-frozen partial-consume restriction so the consuming
    // `Sequenceable.makeIterator()` can extract `buffer`. ABI-freeze is fine
    // pre-1.0 (principal-approved).
    @frozen
    public struct Static<let capacity: Int>: ~Copyable {
        /// Element cleanup is handled by Storage.Inline's deinit.

        /// Element storage using Buffer.Linear.Inline from buffer-primitives.
        ///
        /// `@usableFromInline internal` ([MOD-036] refined-C): the hot
        /// `~Copyable`/`Copyable` operation surface co-located in this (type)
        /// module inlines cross-package to zero-witness-dispatch; the cold
        /// sequence/collection-family conformances in the ops module reach this
        /// storage only through the public `span` / `makeIterator` witnesses and
        /// the `package takeBuffer()` accessor in `Set.Ordered.Static+Iteration.swift`.
        @usableFromInline
        internal var buffer: Buffer<Element>.Linear.Inline<capacity>

        /// Hash table for O(1) position lookup.
        @usableFromInline
        internal var hashTable: Hash.Table<Element>.Static<capacity>

        /// Creates an empty inline ordered set.
        ///
        /// - Precondition: `capacity` must be a power of two.
        @inlinable
        public init() {
            self.buffer = Buffer<Element>.Linear.Inline<capacity>()
            // Hash.Table.Static.init() validates power-of-two capacity
            self.hashTable = Hash.Table<Element>.Static<capacity>()
        }

    }
}

// MARK: - Sendable

extension Set.Ordered.Static: @unsafe @unchecked Sendable where Element: Sendable {}

// MARK: - Error Typealias

extension Set.Ordered.Static {
    /// Errors that can occur during inline ordered set operations.
    public typealias Error = __SetOrderedInlineError<Element>
}
