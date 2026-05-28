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
public import Buffer_Linear_Bounded_Primitive
public import Buffer_Linear_Bounded_Primitives
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
        @usableFromInline
        package var buffer: Buffer<Element>.Linear

        /// Hash table for O(1) position lookup.
        @usableFromInline
        package var hashTable: Hash.Table<Element>

        // MARK: - Initialization

        /// Creates an empty ordered set.
        @inlinable
        public init() {
            self.buffer = Buffer<Element>.Linear(minimumCapacity: .zero)
            self.hashTable = Hash.Table<Element>(minimumCapacity: .zero)
        }

        // MARK: - Fixed (Fixed-Capacity, Heap-Allocated)

        /// A fixed-capacity ordered set that throws on overflow.
        ///
        /// Composes `Buffer<Element>.Linear.Bounded` for element storage and
        /// `Hash.Table<Element>` for O(1) position lookup.
        // WHY: Category D — structural Sendable workaround; the type is
        // WHY: structurally value-safe but the compiler cannot synthesize
        // WHY: Sendable due to a stored pointer / generic parameter shape.
        @safe
        public struct Fixed {
            /// Element storage using Buffer.Linear.Bounded from buffer-primitives.
            @usableFromInline
            package var buffer: Buffer<Element>.Linear.Bounded

            /// Hash table for O(1) position lookup.
            @usableFromInline
            package var hashTable: Hash.Table<Element>

            /// The maximum number of elements the set can hold.
            public let maximumCapacity: Index_Primitives.Index<Element>.Count

            /// Creates a Fixed ordered set with the specified capacity.
            @inlinable
            public init(capacity: Index_Primitives.Index<Element>.Count) throws(__SetOrderedFixedError<Element>) {
                self.buffer = Buffer<Element>.Linear.Bounded(minimumCapacity: capacity)
                self.hashTable = Hash.Table<Element>(minimumCapacity: capacity)
                self.maximumCapacity = capacity
            }
        }

    }
}

// MARK: - Conditional Copyable

extension Set.Ordered: Copyable where Element: Copyable {}
extension Set.Ordered.Fixed: Copyable where Element: Copyable {}

// MARK: - Sendable

extension Set.Ordered: @unsafe @unchecked Sendable where Element: Sendable {}
extension Set.Ordered.Fixed: @unsafe @unchecked Sendable where Element: Sendable {}
