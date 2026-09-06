# Punch list: library-wide de-loop

## Goal

No interpreter loop walks table rows, and no code reads or writes a table
cell row by row, anywhere in the procedures library, unless a loop is
necessary and appropriate there. Every surviving loop carries a
`; VECTOR-EXEMPT: cat1|cat2 <reason>` note, and a lint fails the build on any
un-annotated row loop or per-row cell call. The lint is the durable
guarantee; the edits are the one-time cleanup.

Scope is the whole library, not only the statistical kernels: `stats/`,
`graphs/`, and `scripts/`. The sweep on 2026-09-06 counts 243 variable-row
table calls (`Get value: .<var>`, `Set string value: .<var>`,
`Set numeric value: .<var>`) across 16 files, plus the interpreter row loops
the earlier loop census already classified.

## Guards

Each edit declares which guard it must pass. A verifier checks the guard from
disk, not from the agent's report.

- **Bit-identical.** Data-movement and element-wise changes (column reads,
  resizes, per-row copies, label matching, record and output writes) must not
  move any graded value. A single difference is a defect.
- **1e-12 relative.** Reduction changes (sums, means, sums-of-squares, matrix
  products) may move within 1e-12 relative, per
  `ACCURACY_VECTORIZATION_STUDY_2026-09-06.md`. Every cell past 1e-12 is listed
  with a disposition. These edits move numbers in the last digit or two, which
  is the documented accuracy gain, not a regression.
- **R reconciliation at 1e-9.** `results/reconciliation.tsv` stays within the
  kit's 1e-9 science tolerance for every plugin-vs-R cell. Nothing real drifts.
- **NIST non-regression.** No NIST StRD dataset's within- or between-group LRE
  decreases against base R under the project gate (`v19`, one-digit slack).

The golden reference is the 685-cell single-process output at commit
`74c6fb10`, saved under `_mailbox_live/_runs/deloop-golden/`. It re-baselines
after each gate that moves numbers within 1e-12.

## Gate C: statistical kernels

Vectorize the reduction and per-row work in the numeric kernels:
`eml-inferential`, `eml-analysis`, `eml-anova-kernel`, `eml-core-descriptive`,
`eml-psychometrics`, `eml-categorical`, `eml-studentized-range` (reads only,
never the range integration), `eml-wilcoxon-interval`, `eml-core-utilities`.
One agent per file, each carrying its census fix and the guard per loop.
Evidence:

- Bit-identical guard holds on the data-movement and element-wise cells.
- 1e-12 guard holds on the reduction cells; the over-1e-12 list is empty or
  fully dispositioned.
- `RUN_ALL_SUMMARY.tsv` shows equal or higher pass counts and no new `FAIL`.
- The NIST scorecard re-runs with no dataset losing accuracy.
- Every surviving `cat1` / `cat2` loop carries a `; VECTOR-EXEMPT` note naming
  its category and reason.

### Gate C progress (2026-09-06, single-process Praat 6.6.30 verification)

Vectorized (files that carried real loops):

- `eml-inferential` — reductions, difference vectors, rank sorts; group table
  numeric column built in one pass. Committed `e12c7064`, `58f9a2c4`.
- `eml-core-utilities` — z-score, difference, bin-edge builders. `f71a6a9e`.
- `eml-core-descriptive` — six reductions: skewness and kurtosis moment sums,
  harmonic mean (`sum(v# ^ -1)`, since Praat rejects scalar/vector division),
  trimmed and Winsorized middle sums via `part#`, MAD deviations via `abs#`.
  Bit-identical to the pre-edit code and to a sequential reference at n=250.
  `9a0b7cc6`.
- `eml-analysis` — regression extractor now probes both columns with
  `eml_strictNumericColumn`; when both are complete-numeric it reads each whole
  at C speed and skips both per-row sweeps, else it falls back to the per-row
  pairwise-complete filter. Fast path proven bit-identical to a least-squares
  reference; a holed column routes to the slow path and drops the incomplete
  pair. `02ccec6e`.
- `eml-anova-kernel` — Levene grand-sum reduction via `sum(z#)`, bit-identical.
  `be8edfba`.

Reviewed clean (already vectorized by the author; no row-by-row table calls;
remaining loops are legitimately kept and will be tagged in the Gate E pass):

- `eml-psychometrics` — Cronbach alpha and alpha-influence already run on
  `columnSums#` / `rowSums#` / `outer##` / `mul#`. Surviving loops: two
  listwise-deletion gathers, the per-item alpha-if-deleted (k is small, column
  pulled by unit-vector `mul#`), the respondent jackknife (the leave-one-out is
  the loop), and an undefined-skipping argmax. No Praat boolean-mask or
  segment-sum primitive covers these.
- `eml-categorical` — chi-square already uses `outer##` for expected counts and
  a vectorized statistic and continuity correction. Surviving loops are the
  small-contingency-table cell validation and the expected-count diagnostic,
  both documented in-file as deliberately kept (no matrix min/count reduction at
  script level without allocating a transient object).

Deferred to the numerical lane (zero-finders and rank-inversion CIs, the same
character as the held mixed-model files; a wrong edit fails silently):

- `eml-studentized-range` — the range integration is the loop; reads only, and
  no read here is a table row sweep.
- `eml-wilcoxon-interval` — Brent zero-finder plus O(n^2) Walsh-average
  pairwise loops; the pairwise set is the Hodges-Lehmann method and an `outer##`
  rewrite would allocate an n x n matrix, the exact memory pressure this pass is
  relieving. Hold for a dedicated careful unit.

Open decision held for Ian: the group-extraction redesign in the two-way gather
and the one-way path is the real memory lever (the 256 MB ANOVA extraction).
Not spent without his steer.

## Gate D: results writers

Vectorize the record and output writers: `eml-record` (49 per-row calls, the
largest single concentration), `eml-result-writer`, `eml-output`. The recorder
and the tidy/glance/augment builders write cell by cell today; replace the
per-row writes with column formulas or bulk builds where the shape allows.
Evidence:

- Bit-identical guard holds on every graded cell these touch.
- The recorder and output validators stay green.
- The live-object count is stable across a recorder run (no leaked tables).

## Gate E: enforce

Land the loop lint. It fails, unless a `; VECTOR-EXEMPT` note is present:

- any interpreter loop whose body reads or writes a table cell by row
  (`Get value: .<var>`, `Set string value: .<var>`, `Set numeric value: .<var>`);
- any `for`/`while` that iterates observation rows.

Evidence: the lint fails on a deliberately inserted un-annotated row loop and
on an un-annotated per-row `Set` (recorded negative tests), passes on the real
tree, and its report accounts for every row loop and per-row cell call as
removed or annotated. Style matches the existing error-read lint.

## Gate F: the rest of the library

Classify and clear the row-by-row work outside the kernels and writers:
`graphs/eml-graph-procedures` (17), `graphs/eml-draw-procedures` (16),
`graphs/eml-draw-qq`, `scripts/eml-wizard` (42), `scripts/eml-batch-process`,
`scripts/eml-edit-table`, `scripts/eml-describe-table`,
`scripts/eml-compare-paired`, `scripts/eml-check-data`,
`scripts/eml-check-normality`, `stats/eml-demo-tables` (41). One agent per
file. Where a row-by-row build is genuinely the task (constructing a demo
table from literals, applying a user's single-cell edit), keep it and annotate
`cat2`; otherwise vectorize. Evidence: the lint passes on each file; any
validator or walkthrough that drives these stays green; no graded value moves.

## Deferred lane: delicate numerical files

`eml-lmm` (16 per-row calls), `eml-optimizer`, `eml-linalg`. The REML steps,
the solvers, and the decompositions are loops that carry the math; they stay,
annotated `cat2`. Their plain data-movement loops (a column read, a copy) are
vectorized in a final, careful unit, flagged before it starts because a wrong
edit here fails silently. Held under the standing hold on the mixed model
until Ian releases it.

## Re-baseline and close

After Gates C, D, F land: capture the improved numbers as the new golden
(685 cells), record its checksum and commit, run the full validator suite and
the full single-process kit. Evidence: the suite records no new failure; the
kit completes in one process; `results/reconciliation.tsv` is within 1e-9 for
every plugin-vs-R cell; the count of pre-existing unexplained plugin-vs-R
disagreements is unchanged; the grand ledger writes and exits clean.

## Model split

Sonnet builds each file, guarded so a wrong edit fails loudly against the diff.
Opus runs one verification per gate over the whole suite and the kit. Haiku
runs the mechanical sweeps and re-greps. The expensive model holds to the
end-of-gate checks and the sequencing.
