# [MOD-036] Type/Ops Boundary — IN PROGRESS (base variant DONE)

**Status:** IN PROGRESS. The **base variant is DONE** (refined-C, commit
`10e120d`, build green + 126 tests pass) following swift-buffer-linear-primitives'
proven pattern. **Fixed / Static / Small variants PENDING.** Each satellite needs
its own per-variant surgery — they are NOT pure mechanical mirrors of base:
- **Fixed**: same storage shape as base (`package var buffer`/`hashTable`) but
  conformances are organized differently (no separate `.Iterator.swift`; bundled
  in the ops-side `Set.Ordered.Fixed.swift`).
- **Static**: storage is `package var _buffer: Buffer.Linear.Inline<capacity>` /
  `_hashTable: Hash.Table.Static<capacity>` (underscore-prefixed, with `buffer`/
  `storage` accessors) — the flip target + window shape differ.
- **Small**: adds spill state (`_heapHashTable: Hash.Table?`, `isSpilled`) over
  `_buffer: Buffer.Linear.Small<inlineCapacity>` — most divergent.

**Base-variant recipe applied (the template for the satellites):**
1. storage `@usableFromInline package` → `@usableFromInline internal`;
2. hot internal-touching ops (Copyable/~Copyable methods, Algebra, Indexed,
   Builder) + Hash.Protocol move into the `{…} Primitive` (type) module;
3. cold seq/coll-family conformances (Memory.Contiguous, Sequenceable,
   Sequence.Consume) stay in the ops module behind `package` windows
   (`_span`/`_makeScalar`/`_takeBuffer`) in `…+ConformanceSupport.swift`;
4. ExpressibleByArrayLiteral / Set.Protocol / Sequence.Clearable split to own ops
   files; Iterator/conformance file opts into `@_spi(Unsafe)` per [MOD-016] for
   the moved `withUnsafeBufferPointer` witness;
5. type target gains Cardinal/Ordinal product deps.

Iteration-conformance shape left UNCHANGED (Track 3, supervisor-gated): only the
storage-access path of the cold conformances changed, not the conformance set.

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
