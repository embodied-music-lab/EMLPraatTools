# Ruling — one analysis AND one extraction per case (rev 2)

Fable, 31 August 2026. Revision 2 replaces the first version, which
named the wrong pattern. I walked the kit's ANOVA path in the source;
the diagnosis below is measured, not relayed.

## What the code does

The analysis computes once — `@emlRunAnovaAnalysis` calls
`@emlOneWayAnova` a single time per case, and nothing re-invokes it.
The repeated work is DATA EXTRACTION: `@eml_getGroupData` is a full
interpreted scan of the whole table, and the ANOVA path calls it

- inside the orchestrator's pairwise effect-size loop (group j
  re-extracted for every (i, j) pair; eml-analysis.praat, the Cohen's d
  loop after the kernel call),
- once per group in `@emlReportAnovaComparison`'s descriptives loop,
- twice per pair again in the reporter's Tukey CSV loop.

On an 18,000-observation NIST dataset this is tens of millions of
interpreted row reads repeating one pass's work. That is the slowness
Ian hit.

## The law, extended

One analysis per case, and ONE EXTRACTION per case: each group's
vector is extracted once (a single partitioning pass over the table, or
one `@eml_getGroupData` per group, cached), and every consumer — the
effect-size loop, the descriptives, the CSV rows — reads the cached
vectors. No procedure re-scans the table for data another site already
extracted in the same case. Preferred shape: the kernel or orchestrator
holds the per-group vectors from its own extraction and exposes them;
the reporter reads, never extracts.

## The build

1. Fix the ANOVA path as above.
2. Sweep the other orchestrators and reporters for the same pattern —
   repeated `@eml_getGroupData` (or equivalent whole-table scans) on an
   unchanged case — and fix each. Report census-style: site, was, is.
3. The augmented per-observation export becomes opt-in (off by
   default; kit runs never produce it). Unchanged from rev 1.
4. Boundary unchanged from rev 1: kernel calls are legitimate for
   exploration; validation evidence comes only from the public route,
   which this makes cheap.

## Acceptance

Under the harness, one ANOVA case performs one analysis computation and
at most one extraction pass per group (call-count probe on
`@eml_getGroupData`); SmLs03 through the public route lands within the
same order of runtime as the tierC bypass. Red demo: current head,
timed on SmLs03, against the fixed path.

— Fable
