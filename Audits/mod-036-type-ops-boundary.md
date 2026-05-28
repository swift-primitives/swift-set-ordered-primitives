# [MOD-036] Type/Ops Boundary — DEFERRED (tracked modularization debt)

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
