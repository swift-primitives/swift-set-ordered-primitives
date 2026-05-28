# [MOD-036] Type/Ops Boundary — IN PROGRESS (base variant DONE + APPROVED)

**Status:** IN PROGRESS. The **base variant is DONE and supervisor-APPROVED** as
THE replication template — the windowless refined-C shape (commit `a70a436`;
build green, supervisor-verified 128 tests, hot-op cross-package inlining
preserved, no underscored windows). The earlier windowed draft (`10e120d`,
`_span`/`_makeScalar`/`_takeBuffer`) is SUPERSEDED — the fan-out copies the
windowless shape (recipe below), not the draft. **Fixed / Static / Small variants
PENDING.** Each satellite needs its own per-variant surgery — they are NOT pure
mechanical mirrors of base:
- **Fixed**: same storage shape as base (`package var buffer`/`hashTable`) but
  conformances are organized differently (no separate `.Iterator.swift`; bundled
  in the ops-side `Set.Ordered.Fixed.swift`).
- **Static**: storage is `package var _buffer: Buffer.Linear.Inline<capacity>` /
  `_hashTable: Hash.Table.Static<capacity>` (underscore-prefixed, with `buffer`/
  `storage` accessors) — the flip target + window shape differ.
- **Small**: adds spill state (`_heapHashTable: Hash.Table?`, `isSpilled`) over
  `_buffer: Buffer.Linear.Small<inlineCapacity>` — most divergent.

**Base-variant recipe (CORRECTED — the clean template for the satellites and the
fan-out). NO underscored windows; NO Copyable/~Copyable target split** (supervisor
decision: for set-ordered the Copyable partition coincides with type/ops, and a
target split only re-opens the MOD-036 inlining problem — not worth ×4×16 target
proliferation for a thin Copyable surface):

1. storage `@usableFromInline package` → `@usableFromInline internal` (hot
   `@inlinable` ops inline cross-package through it; NOT `package` — the hot
   `@inlinable` ops reference storage and `@inlinable` bodies cannot reference
   `package` symbols, [MOD-036]/[MOD-027]).
2. hot internal-touching ops (Copyable/~Copyable methods, Algebra, Indexed,
   Builder) + Hash.Protocol move into the `{…} Primitive` (type) module.
3. **Witnesses that import no sequence/collection-primitives are plain `public`
   members co-located with storage in the type module** — NOT windows. Because
   set-ordered *composes* `Buffer.Linear` (public `span`/`makeIterator`/`consume`),
   these just delegate: `Set.Ordered+Iteration.swift` declares `public var span`
   and `public consuming func makeIterator()` (both `@inlinable`, inline
   cross-package). The cold `Memory.Contiguous` / `Sequenceable` conformances in
   the ops module are then **thin** (empty / typealias-only) and use those public
   witnesses.
4. The ONE ops-bound member is `consume()` — its `Sequence.Consume.View` return
   type pulls `Sequence_Primitives`, kept out of the lean type module. It is
   **non-`@inlinable`** (cold) and reaches storage through a SINGLE named
   `package consuming func takeBuffer()` in the type module (`+Iteration.swift`) —
   named, not underscored, non-`@usableFromInline`.
5. ExpressibleByArrayLiteral / Set.Protocol / Sequence.Clearable split to own ops
   files; the Memory.Contiguous conformance file opts into `@_spi(Unsafe)` per
   [MOD-016] for the `withUnsafeBufferPointer` witness moved to the type module.
6. type target gains Cardinal/Ordinal product deps.

Iteration-conformance shape left UNCHANGED (Track 3, supervisor-gated): only the
storage-access path of the cold conformances changed, not the conformance set.

(Superseded shape: an earlier base commit used underscored `package` windows
`_span`/`_makeScalar`/`_takeBuffer` in a `+ConformanceSupport.swift`, mirroring
buffer-linear's raw-storage-owner pattern. That over-applied — set-ordered
composes Buffer.Linear rather than owning raw `Storage.Heap`, so it delegates to
the buffer's public API. Reworked to the windowless shape above.)

## Quality bars (principal, 2026-05-28) — apply to every variant AND the fan-out

1. **No Copyable/~Copyable MODULE split.** The Copyable surface includes hot
   `@inlinable` ops (Algebra/Indexed/Builder) that MUST co-locate with storage in
   the type module for cross-package inlining — a separate module re-opens
   [MOD-036]. Keep Copyable/~Copyable at the FILE level (`X Copyable.swift` /
   `X ~Copyable.swift`); keep hot/cold at the MODULE level (type `Primitive` / ops
   `Primitives`). Do NOT split a cold-Copyable module either (premature — iteration
   shape gated; low value).
2. **No non-inlinability underscores.** Storage is `@usableFromInline internal var
   buffer` / `hashTable` — no underscore (the base proved it needs none). Strip
   `_buffer`/`_hashTable`/`_heapHashTable`/`_storage`/`_buildHashTable` →
   de-underscored. Keep an underscore ONLY if a concrete `@frozen` not-API signal
   genuinely requires it (it shouldn't). Base touch-up applied: `_storage` →
   `storage` in `Set.Ordered.Indexed.swift`.
3. **`_heapHashTable` → `hashTable`** (Small variant): drop "heap" (impl detail;
   the `?` already conveys spill-only; no intra-Small ambiguity). Keep `isSpilled`.
   (`_buildHashTable()` → `buildHashTable()` is a Small-variant rename, not base.)

---

## Original deferral note (preserved for reference)

**Status:** DEFERRED with trigger. Not a current non-conformance blocker; the
package builds green and 126 tests pass on the proven per-variant/bridge template.

## (a) The violation

Each `Set.Ordered` variant's storage is `@usableFromInline package var buffer /
hashTable` (in the **type** module), while `@inlinable public` operations that
reference that storage live in the **ops** module. Per [MOD-036], a cross-package
`@inlinable public` body must not reference `package`/`@usableFromInline package`
symbols — a downstream consumer with `@inlinable` code calling these ops cannot
see the `package` storage the inlinable body references, so cross-package
inlining silently fails / hard-errors in the consumer's whole-module build.

The clean fix (buffer-linear's proven pattern): co-locate the internal-touching
`@inlinable` surface **in the type modules** as `@usableFromInline internal`
(storage flips `package` → `internal`), and have the conformances that remain in
the ops modules reach storage through a minimal `package` window (an accessor),
not the raw fields.

## (b) Blast radius

~28 files across the 4 variants (base / Fixed / Static / Small):
- Move the internal-touching `@inlinable` method surface (the `~Copyable`
  mutating ops + Copyable instance methods that touch storage) from each ops
  module into its type module.
- Flip `buffer`/`hashTable` storage `package` → `@usableFromInline internal`.
- Add a `package` window for the conformances staying in ops (Sequenceable,
  Memory.Contiguous.Protocol, Sequence.Drain/Consume, Algebra, Iterator,
  Indexed) — e.g. in the base variant alone, 7 ops files reference storage
  (`Set.Ordered Copyable.swift`: 17 refs, `~Copyable`: 8, plus
  Algebra/Iterator/Consume/Indexed).
- [MOD-037] satellite care: do NOT flip a `package` symbol that a sibling-variant
  module references; classify cold-path (keep `package`) vs hot-path (refactor
  to call base's `@inlinable public` API).

## (c) Deferral trigger

Do it as a dedicated arc **before set-ordered is published OR before any
cross-package `@inlinable` consumer of set-ordered is added — whichever comes
first.** Latent today (set-ordered is unpublished and has no such consumer), so
the violation cannot be tripped, but it is real (deferred) modularization debt,
not ignored.

## Provenance

Deferred by principal direction (Option 1: defer MOD-036, do MOD-006, hand back)
to avoid bolting a ~28-file re-draw onto the just-green per-variant/bridge
migration. See commits `de1fb93` (per-variant decomposition), `a8602a0`
(Iterator.Chunk re-use), `f0dd1d8` ([MOD-006] dep-tightening).
