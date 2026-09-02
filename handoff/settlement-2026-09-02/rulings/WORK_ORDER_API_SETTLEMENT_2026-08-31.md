# Work order — API settlement before the freeze

Fable, 31 August 2026. SUPERSEDES AND REVERSES
`RULING_RM_SIGNATURE_FREEZE_2026-08-31.md` (I had Ian's position
backwards). Ian's ruling: any known change to public API calls or
kernels happens NOW, as part of the kit work — the validation paper is
not published on a surface that changes the moment 1.0 ships. The
authoritative run validates what 1.0 actually releases.

## In scope before the authoritative run

From Sol's smoothing pass, everything that touches the public surface
or a kernel:

1. **String-vector repeated-measures signature** ships in 1.0 as the
   canonical form; the pipe-delimited form becomes a compatibility
   wrapper. (Direct reversal of the superseded ruling.)
2. **Canonical word-based procedure names** across the public surface
   — stats and drawing both — with compatibility wrappers for every
   old name (`@emlTTestAlt` pattern). Table S2 documents the canonical
   names.
3. **Uniform outcome contract**: `.ok` / `.error$` / `.warning$` on
   every public procedure; the non-uniform failure seams Sol
   catalogued are fixed, not wrapped.
4. **Result unification**: clear state on entry; the LMM stale-export
   fix.
5. **Registry/manifest** as the single source of the public surface;
   docs and the recorder generate from it; the `eml-lib-user.praat`
   barrel regenerates from the same source.
6. The **two-way kernel** (already ordered separately) — unchanged.

## Deferred past 1.0, and why that is allowed

Only items that are purely ADDITIVE — they change no validated
behavior and no Table S2 row, they only add — may wait:

- The result-Table return channel (Sol's own note: not necessary for
  the validation paper). Adding it later adds an output; it alters
  nothing the paper validated.

Nothing else on Sol's list qualifies. When in doubt, it goes in now.

## Kit consequences

- The kit drives the CANONICAL public route — that is the route the
  paper documents. Old-name wrappers get a cheap equivalence check
  (each wrapper forwards to its canonical procedure; one probe per
  wrapper, not a second full matrix).
- The outcome-contract standardization will change refusal wording;
  the D-WORDING rows and the refusal-wording comparisons re-measure
  after it lands. Counts are outputs — no total from before the
  settlement survives into any generated file.

## Sequence, amended again (this version governs)

MAXROW → refusal-set equality → NIST wiring + R-side NIST runs →
two-way kernel → API settlement (items 1–5) → kit re-pointed at the
canonical route + wrapper equivalence checks → grand_ledger → full
three-study run at a pushed commit → Tier B count verdict → Fable's
inspection → frozen-release candidate.

## Stated assumption — surface disagreement now, not after the run

I am assuming the kernel set is settled once the two-way kernel
lands: no other kernel math changes are planned for 1.0 or shortly
after. If you know of any — anything you expect to change at or right
after release — name it now so it joins this settlement. Nothing on
that list may first appear after the authoritative run.

— Fable
