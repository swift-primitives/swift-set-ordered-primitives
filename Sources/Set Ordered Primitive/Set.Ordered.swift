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

public import Set_Primitive
public import Buffer_Primitive
public import Buffer_Linear_Primitive
public import Storage_Primitive
public import Storage_Contiguous_Primitives
public import Memory_Heap_Primitives
public import Memory_Allocator_Primitive
public import Hash_Indexed_Primitive
import Hash_Primitives
public import Shared_Primitive
public import Index_Primitives

// MARK: - Set.Ordered (the ORDER-FACING ADT — generic over the ORDERED HASHED column)

extension __Set where S: ~Copyable {
    /// The ordered-set discipline over the `Hash.Indexed` column — the base set's
    /// sibling that puts the column's insertion order ON the surface (the W5 reshape,
    /// 2026-06-11).
    ///
    /// The base set already ITERATES in insertion order (the dense plane is the
    /// order); what it deliberately does not expose is the ORDER-FACING vocabulary.
    /// `Set.Ordered` exists for exactly that surface: positional reads
    /// (`subscript(index:)`, `first`, `last`) and position lookup (`index(of:)`) over
    /// the same membership discipline.
    ///
    /// The ratified two-column design, mirrored from `__Set`: copyability flows from
    /// the column (S5):
    ///
    /// ```swift
    /// Set<Int>.Ordered                                                            // zero-cost MOVE-ONLY (default, front door)
    /// __Set<Shared<Int, Hash.Indexed<Buffer<Storage<…System>.Contiguous<Int>>.Linear>>>.Ordered  // explicit CoW value semantics
    /// ```
    ///
    /// The column is `Hash.Indexed<Dense>`: members live DENSELY in insertion order;
    /// the hash side is the bucket position-index engine. `Shared` wraps the COMPOSITE —
    /// one box, one clone strategy. Members never mutate in place (mutability ruling
    /// (a)): the surface is insert / contains / remove / read-only positional access.
    ///
    /// ## Nest alias on the carrier ([DS-028])
    ///
    /// `Set.Ordered` is a column-preserving nest alias on the hoisted carrier `__Set`,
    /// re-applying the column parameter `S` to the sibling carrier `__SetOrdered`. The
    /// public front door is `Set<E>.Ordered` (over the canonical column):
    ///
    /// ```swift
    /// extension __Set where S: ~Copyable {
    ///     public typealias Ordered = __SetOrdered<S>
    /// }
    /// ```
    public typealias Ordered = __SetOrdered<S>
}

/// See ``Set/Ordered``. The order-facing sibling carrier, hoisted bound-free per
/// [DS-025] ([API-IMPL-009]/[PKG-NAME-006]): its column parameter `S` is bound
/// `~Copyable` **only**; every capability (observability, the ordered-read surface,
/// membership, construction) attaches by conditional `@inlinable` extension keyed on
/// the seams the column conforms. The public spelling is the `Set<E>.Ordered` front
/// door (a [DS-028] nest alias on `__Set`); the hoisted name never appears in
/// consumer signatures.
@_documentation(visibility: public)
@frozen
public struct __SetOrdered<S: ~Copyable>: ~Copyable {

    /// The ordered hashed column — move-only (the default ownership column) or a
    /// `Shared` CoW column. The ADT is a thin order-facing discipline over it; it
    /// carries NO deinit.
    @usableFromInline
    package var store: S

    /// Wraps an existing column.
    @inlinable
    public init(store: consuming S) {
        self.store = store
    }

    /// Consumes the ordered set, yielding its storage column.
    @inlinable
    public consuming func take() -> S {
        store
    }
}

// MARK: - Conditional Conformances (co-located per [COPY-FIX-004])

/// The S5 chain: `__Set<Shared<E, B>>.Ordered` is `Copyable` exactly when the ELEMENT is.
extension __SetOrdered: Copyable where S: Copyable {}

extension __SetOrdered: Sendable where S: Sendable & ~Copyable {}

// MARK: - Column-pinned construction ([MEM-COPY-017]: the split lives in `Shared`'s
// pinned constructor pair; the `Set.Ordered` forms pick the column)

extension __SetOrdered where S: ~Copyable {
    /// Creates an empty MOVE-ONLY ordered set (the default ownership column).
    @inlinable
    public init<E: Hash.Key & ~Copyable>(minimumCapacity: Index_Primitives.Index<E>.Count = .zero)
    where S == Hash.Indexed<Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Linear> {
        self.init(store: S(minimumCapacity: minimumCapacity))
    }

    /// Creates an empty CoW (value-semantic) ordered set on the `Shared` column.
    @inlinable
    public init<E: Hash.Key & SendableMetatype>(minimumCapacity: Index_Primitives.Index<E>.Count = .zero)
    where S == Shared<E, Hash.Indexed<Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Linear>> {
        self.init(store: Shared(
            Hash.Indexed<Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Linear>(minimumCapacity: minimumCapacity)
        ))
    }

    /// Creates an empty statically-unique ordered set of move-only members on the
    /// `Shared` column (the boxed flavor of the move-only regime).
    @inlinable
    public init<E: Hash.Key & SendableMetatype & ~Copyable>(minimumCapacity: Index_Primitives.Index<E>.Count = .zero)
    where S == Shared<E, Hash.Indexed<Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Linear>> {
        self.init(store: Shared(
            Hash.Indexed<Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Linear>(minimumCapacity: minimumCapacity)
        ))
    }
}
