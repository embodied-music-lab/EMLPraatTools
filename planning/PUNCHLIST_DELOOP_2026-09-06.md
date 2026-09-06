# Punch list: de-loop pass

Each task lists the work and the evidence that demonstrates accurate execution.
Evidence is a checkable artifact or measurement, not a judgment. A task is done
only when its evidence exists and passes.

Two guards are referenced throughout:

- **Bit-identical guard.** The affected cells in `audit/praat_results.tsv` match
  the golden baseline exactly, value for value. A single difference is a defect.
  Applies to data-movement and element-wise changes.
- **1e-12 guard.** For reduction cells, the maximum relative change from the
  golden baseline is at most 1e-12, and no affected NIST dataset loses accuracy.
  Every cell that moves past 1e-12 is listed with a disposition: benign
  reassociation with its magnitude, or a defect that was fixed. Applies to sums,
  means, sums-of-squares, and matrix products, per
  `ACCURACY_VECTORIZATION_STUDY_2026-09-06.md`.

The golden baseline is the plugin output at the pre-de-loop commit, captured for
all 685 cells before any task runs.

## Gate A: foundations

**A0. Preserve the golden baseline.**
Capture `audit/praat_results.tsv` at the pre-de-loop commit for all 685 cells and
store it as a reference with its commit SHA and a SHA-256 checksum.
Evidence: a stored file of 11,854 rows across 685 distinct cell IDs; the recorded
SHA and checksum reproduce it.

**A1. Add the object-scope primitives.**
Add `emlObjMark`, `emlScopeClose`, `emlScopeCloseKeepSel`, `emlScopeCloseKeepVec`,
and `emlKeepOnly` to a core utilities file and expose them through the barrel.
Evidence: the 29-assertion sandbox suite runs against the in-plugin copy with zero
failures, including the 3,000-cycle leak test holding the live-object count at
baseline; a plugin procedure calls `emlObjMark` and `emlScopeClose` and the live
count returns to its pre-call value.

**A2. Close the one object leak.**
Add a local `removeObject` for the Strings object in `eml_saveFileLanded`
(`eml-output.praat`).
Evidence: the live-object count before and after a call to `eml_saveFileLanded`
is equal; the bit-identical guard holds, since no number changes.

## Gate B: the extractor (the unblock)

**B1. Vectorize the five `eml-extract` loops.**
Replace the `eml_groupSubset` column scan, the `emlExtractColumn` fast-path row
loop, the `eml_strictNumericColumn` scan, and the vector resize with
`Get all numbers in column:`, `Formula (column):`, extract-based checks, and
`part#()`.
Evidence:
- Bit-identical guard holds on every cell that reads columns or groups data.
- The full 685-cell kit runs in a single Praat process, no batching, peak
  resident memory under 1 GB, no OOM in `dmesg`, and `audit/praat_results.tsv`
  reaches 11,854 rows.
- Recorded wall-clock for the plugin drive drops from the pre-change baseline.
- The four `cat1` and one `cat2` loops in the file carry `; VECTOR-EXEMPT`
  annotations naming their category.

## Gate C: statistical kernels

**C1. Vectorize the kernel reductions and reads.**
Files: `eml-inferential` (13), `eml-analysis` (14), `eml-anova-kernel` (2), the
`eml-core-descriptive` / `eml-psychometrics` / `eml-categorical` /
`eml-studentized-range` / `eml-wilcoxon-interval` group (16), and
`eml-core-utilities` (6). One agent per file, each carrying the census fix text.
Evidence:
- Bit-identical guard holds on the data-movement and element-wise cells.
- 1e-12 guard holds on the reduction cells; the list of cells exceeding 1e-12 is
  empty or fully dispositioned.
- The affected validators stay green: `RUN_ALL_SUMMARY.tsv` shows equal or higher
  pass counts and no new `FAIL`.
- The NIST scorecard re-runs and no dataset's within or between LRE decreases.
- Every surviving `cat1` and `cat2` loop in these files carries a
  `; VECTOR-EXEMPT` annotation.

## Gate D: results writers

**D1. Vectorize the record and output loops, keep the leak closed.**
Files: `eml-record`, `eml-result-writer`, `eml-output` (5 loops).
Evidence: the recorder and output validators stay green; the bit-identical guard
holds on any graded cell these touch; the live-object count is stable across a
recorder run.

## Gate E: enforce and re-verify

**E1. Land the loop lint.**
Add a check, in the style of the error-read lint, that fails any interpreter row
loop over table cells unless it carries a `; VECTOR-EXEMPT` annotation.
Evidence: the lint fails on a deliberately inserted un-annotated row loop (a
recorded negative test), passes on the real tree, and its report accounts for
every interpreter row loop as removed or annotated.

**E2. Re-baseline and verify end to end.**
Capture the improved numbers as the new reference. Run the full validator suite
and the full kit.
Evidence: `RUN_ALL_SUMMARY.tsv` records the suite verdict with no new failures;
the kit completes in one process; `results/reconciliation.tsv` is within guard of
the old baseline for every cell except those dispositioned under the 1e-12 guard;
the count of pre-existing unexplained disagreements is unchanged, showing the
de-loop did not perturb the separate plugin-versus-R question; the grand ledger
writes and exits clean.

## Deferred lane

**X1. Annotate, do not vectorize, the delicate numerical files.**
Files: `eml-lmm` (20), `eml-optimizer` (17), `eml-linalg`. Held for Fable or a
dedicated pass.
Evidence: the lint passes with every loop in these files annotated `cat1` or
`cat2`; the diff against baseline shows only comment additions, no code change.
