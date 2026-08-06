# Fix report — EML Praat Tools, audit §9 items 1–32

> **HISTORICAL RECORD.** This document describes the state of the project on
> the date in its title. It is kept for provenance and is **not** a status
> surface. Do not resume work from it and do not treat its queue, its counts,
> or its instructions as current.
>
> **Current status lives in exactly one place: `audit/FINDINGS_INDEX.md`
> (the rows, not the header prose), with the reasoning in
> `audit/PHASE_ONE_AUDIT_2026-08-06.md`.**

**Date:** 2 August 2026
**Scope:** non-LMM statistics, extraction, annotation and drawing layers
**Excluded by instruction:** the LMM stack, tabled at v0.8 (`stats/eml-lmm.praat`,
`stats/eml-linalg.praat`, `stats/eml-optimizer.praat`, `scripts/eml-lmm.praat`,
the wizard's LMM route, `@emlDrawLMMForest`). None of these files was modified.
**Companion document:** `AUDIT_EML_Praat_Tools_non-LMM_v2_2026-08-02.md`, whose
§9 numbering this report follows and whose confidence ratings (C nn) are quoted
per item.

---

## 1. Summary

All thirty-two items in §9 are closed. Sixteen shipped files changed; no file
was rewritten and no procedure signature was altered except where the audit
required it (`@emlPairwiseT.method$` / `.adjustMethod$` split, item 20). Six
new internal helpers were added — `@eml_pearsonCore`, `@eml_normalizeLabel`,
`@eml_strictNumericColumn`, `@eml_hasUndefined`, `@emlAdjustMethodName`, and
the `@eml_parseAnovaLine` exact-label matcher — all file-local and all
documented at the point of definition.

Change volume against `plugin_BASELINE`, counted as changed lines (added +
removed, excluding hunk context):

| File | Δ lines | Version |
|---|---|---|
| `stats/eml-inferential.praat` | 1083 | 1.2 → 1.3 |
| `graphs/eml-draw-procedures.praat` | 673 | 1.18 → 1.19 |
| `graphs/eml-graph-procedures.praat` | 518 | 3.21 → 3.22 |
| `stats/eml-extract.praat` | 505 | 1.4 → 1.5 |
| `graphs/eml-annotation-procedures.praat` | 321 | 3.17 → 3.18 |
| `stats/eml-analysis.praat` | 297 | 1.1 → 1.2 |
| `graphs/eml-graphs-form.praat` | 151 | 1.9 → 2.2 |
| `stats/eml-core-descriptive.praat` | 106 | 1.1 → 1.2 |
| `scripts/eml-wizard.praat` | 85 | 2.1 → 2.3 |
| `stats/eml-output.praat` | 48 | 1.7 → 1.8 |
| `dev/tests/eml-integration-test.praat` | 35 | 1.0 → 1.1 |
| `scripts/eml-tutorial.praat` | 15 | 0.18 → 0.19 |
| `scripts/eml-stats-demo.praat` | 14 | 1.3 → 1.4 |
| `setup.praat` | 12 | 1.3 → 1.4 |
| `scripts/eml-pairwise.praat` | 8 | 3.0 → 3.1 |
| `scripts/eml-quick-start.praat` | 6 | — → 1.1 |

Test files revised to match corrected behaviour: `test-inferential-batch3`,
`-batch4`, `-batch6b`, `-batch7`, `test-wizard-explanations` (each carries a
v1.1 header stating what changed and why).

Verification state at delivery: Phase 1 suites 262/262 assertions, Phase 2
suites 841/841 plus the 12-group ANOVA and Shapiro–Wilk specials, integration
test 42/42, nine-file include gate `LOAD OK`. Zero failures anywhere on the
board. Differential references were regenerated against R 4.3.3 and
scipy/numpy/statsmodels; the R scripts are retained under `dev/tests/phase2/`
and the ad-hoc verifiers under the session evidence tree described in §4.

---

## 2. Tier 1 — could put a wrong number in the paper

**1 — `@emlRMPostHoc` reported p(adj) = 0 from an undefined raw p.**
`stats/eml-analysis.praat` (C 98). A pairwise test that failed inside the
repeated-measures post-hoc loop left its p undefined; the adjustment routine
multiplied undefined by k and the formatter rendered the result as an exact
zero. Failed comparisons now propagate `undefined` into the raw p-vector, the
adjustment procedures exclude them from k the way R's `p.adjust` excludes `NA`,
both the raw and adjusted columns print `n/a`, and a note names each skipped
pair with its reason.

**2 — `Get all numbers in column:` rank substitution.**
`stats/eml-extract.praat` (C 93). Praat numericises a Table column only when
every cell is a strict numeric literal; if one is not, the command silently
returns each row's *alphabetical rank* — a full column of plausible small
integers. The `self [col] <> undefined` row filter does not protect against
this, because that filter uses lenient coercion and keeps `"1,5"`, `"30%"`,
`"1/2"`, `"2 3"`. New helper `@eml_strictNumericColumn` decides the question
empirically: it appends a **non-integer sentinel** to a copy of the table and
asks for the numbers back. Rank substitution can only ever produce integers, so
a non-integer sentinel surviving the round trip proves real numericisation.
This cannot be spoofed and does not require reimplementing Praat's numeric-string
grammar in script. `@eml_getGroupData` and `@eml_getGroupPairedData` gate every
`Get all numbers in column:` behind it. `@emlValidateNumericColumn` was hardened
in the same pass (per-cell scan across every row, strict verdict, first
offending row plus its literal contents, coercion-hazard warning) and is now
actually called — it previously had zero call sites.

**3 — Pearson/Spearman output clobber, in the report *and* the CSV.**
`stats/eml-inferential.praat`, `stats/eml-analysis.praat` (C 99).
`@emlSpearmanCorrelation` computed rho by calling `@emlPearsonCorrelation` on
the ranks, overwriting `emlPearsonCorrelation.r/.t/.df/.p` — the exact qualified
globals the reporter and the CSV writer read. With `"both"` requested, the
Pearson heading carried Spearman's rank-based numbers. Two changes: the shared
kernel moved into internal `@eml_pearsonCore` so the two public procedures are
thin wrappers that no longer touch each other's outputs, and
`emlRunCorrelationAnalysis` additionally captures each test's outputs into
locals immediately after its own call and restores them before reporting. The
same capture/restore now protects the Mann–Whitney outputs in
`emlRunTwoGroupAnalysis`, which `@emlRankBiserialR` re-enters.

**4 — `@emlCheckNumericColumn` passed a column on a five-row sample.**
`graphs/eml-graph-procedures.praat` (C 98). It sampled the first five rows and
accepted the column if a single cell parsed. It now scans the whole column
(capped at `.maxScanRows`), requires every non-empty cell to be a strict
numeric literal, treats empty and whitespace cells as missing rather than
failures, and reports `.nNumeric` / `.nMissing` / `.nCoerced` / `.nNonNumeric`
plus the first offending row and its literal text. Cells that pass only via
`number()` coercion are classified as coerced and **rejected** — a silent wrong
number is worse than a rejected column. Parameter list and the name and meaning
of `.isNumeric` are unchanged.

**5 — the "undefined fails open" guard class.**
`stats/eml-inferential.praat`, `stats/eml-analysis.praat` (C 95–97). In Praat
every relational comparison against `undefined` is FALSE — `u > 0`, `u < 0`,
`u <= 0`, `u >= 0` and `u = 0` all fail — so a guard written as a comparison
lets undefined through. Fixed at the four confirmed sites: `@emlTukeyHSD`
(below), the one-way ANOVA η² denominator (zero or undefined SS-total no longer
yields η² = 1), `emlRunTwoGroupAnalysis` (which discarded every test's
`.error$`, so a failed test was printed as undefined results *and written to the
CSV*; failed branches are now dropped from the reported test type with the
reason surfaced), and `@emlPearsonCorrelation` (a perfect correlation gave an
undefined t with p = 0, which the report layer rendered as "p < .001"; `.p` is
now 0 with new `.perfect` and `.warning$` outputs, and n < 3 and zero-variance
inputs are guarded). The Scheffé and Dunn instances alleged in v1 were refuted
during the v2 pass and are not changed.

**6 — zero within-group variance made every Tukey p = 1.000.**
`stats/eml-inferential.praat` (C 97). An undefined q from a zero SE or an
undefined MS-within produced p = 1.000 for every comparison, printed under an
`--undefined--` caption. Per-comparison p is now `undefined`, counted in
`.nUndefined` and disclosed in `.warning$`.

**7 — two-way ANOVA SS_Error.**
`stats/eml-inferential.praat` (C 96). SS_Error and SS_Total were parsed out of
Praat's Type I report; they are now computed directly from within-cell
deviations, F and p re-derived from the corrected MS_Error, design balance
checked, negative SS clamped, and the SS type stated in the output header. The
Type III effect SS were already correct and are untouched. A second defect
surfaced in the same procedure: `@eml_parseAnovaLine` matched row labels by
first substring occurrence, so it returned factor1's row whenever factor2's name
was a substring of it (Error and Total collided the same way). It now matches
the label field exactly.

**8 — rank tests under the exact null with ties.**
`stats/eml-inferential.praat` (C 97–99). `@emlMannWhitneyU` used a combined-N
threshold and ignored ties entirely; it now uses R's rule — exact iff
`n1 < 50 AND n2 < 50 AND no ties`. `@emlWilcoxonSignedRank` keeps its `n < 50`
threshold, which already matched R, and adds the ties and zeroes conditions.
The false comment asserting the old threshold was correct is removed. One-tailed
p-values in both returned the smaller tail regardless of direction; the
alternative is now fixed as H1: group1 > group2, matching R, with `.pGreater`
and `.pLess` exposed. `.tails` is validated in both procedures and in
`@emlRankBiserialR` and `@emlMatchedPairsR`.

**9 — adjustment k counted undefined elements.**
`stats/eml-inferential.praat` (C 95). `@emlBonferroni`, `@emlHolm` and
`@emlBenjaminiHochberg` included undefined elements in the comparison count.
All three are now NA-safe — undefined in, undefined out, k excludes undefined —
matching R's `p.adjust`. Verified against `p.adjust` with `NA` present for all
three methods.

**10 — stale `annotMatrixLabel$[]`.**
`graphs/eml-annotation-procedures.praat` (C 98). `@emlClearAnnotations` reset
the count but not the label array, so the previous figure's group labels
survived into the next. It now clears the array over the previous figure's
`annotMatrixN` range before resetting the count. In the same pass, the bracket
output paths stopped reading `annotMatrixLabel$[]` (which is only ever written
on the matrix path) and read captured labels instead.

**11 — scatter plots reported one line and drew another.**
`graphs/eml-draw-procedures.praat` (C 97). Both the ungrouped and grouped paths
now draw the estimator they report, label the drawn line, and disclose the
estimator unconditionally rather than gating the disclosure on
`scatterAnalysisType`.

**12 — `@emlMeasureBarData` crashed on undefined values.**
`graphs/eml-graph-procedures.praat` (C 98). Undefined observations and undefined
custom-error values are skipped and counted; means, SE/SD and the visible
min/max fold are guarded with explicit `<> undefined` tests; single-observation
groups are handled explicitly with no undefined error bar. `emlBarData_mean[]`
and `emlBarData_error[]` are now guaranteed defined on return, so nothing
undefined can reach a drawing command. New disclosure globals: `emlBarData_valid[]`,
`emlBarData_errorDefined[]`, `emlBarData_skipped[]`, `emlBarData_errSkipped[]`,
`emlBarData_nSkipped`, `emlBarData_nErrSkipped`, `emlBarData_nInvalidGroups`,
`emlBarData_nSingleObs`, `emlBarData_nUnmatchedRows`.

---

## 3. Tier 2 — crashes that would block the stress test

**13 — `@emlDrawHistogram` aborted on clean single-column data.**
`graphs/eml-draw-procedures.praat` (C 98). The group loop was driven by
`.nGroups`, which is always 1 on the ungrouped path, instead of `.hasGroups`.
Now driven by `.hasGroups`; the dead else branch is removed.

**14 — calls to the deleted `@emlExtractMultipleGroups`.**
`scripts/eml-wizard.praat`, `dev/tests/eml-integration-test.praat` (C 97). The
procedure was removed in `eml-extract` v1.1 but two call sites survived, along
with a one-argument `@eml_getGroupData` call against the current four-argument
signature. Both rewritten against the current API: `@emlCountGroups` discovers
labels, `@eml_getGroupData` pulls one group on demand. Integration test 2.4 and
2.8 rewritten accordingly and both pass.

**15 — `@emlDrawViolin` called with 6 of 7 arguments.**
`scripts/eml-stats-demo.praat` (C 96). Praat binds positionally, so every
argument after the omitted `.width` bound to the wrong parameter. The half-width
is now passed explicitly as a named constant `violinHalfWidth = 0.35` — the
plugin default used by `@emlDrawViolinPlot` for one violin per integer
x-position.

**16 — the interactive tutorial included a directory that does not ship.**
`scripts/eml-tutorial.praat`, `setup.praat`, `scripts/eml-quick-start.praat`
(C 99). `tutorial/eml-demo-procedures.praat` has never been shipped with this
plugin, so every page renderer called undefined procedures. Rather than invent
tutorial content, the include is commented out, the script exits with an
explanation instead of "Procedure not found", the `setup.praat` menu
registration is removed with a comment stating the condition for restoring it,
and the quick-start guide no longer advertises the menu item.

**17 — `@emlDrawBarChart` and row-1 axis seeding.**
`graphs/eml-draw-procedures.praat` (C 95–96). The bar chart now guards every
undefined mean and error before it reaches a drawing command — an unusable bar
is skipped and recorded rather than aborting the figure. `@emlDrawTimeSeries`
and `@emlDrawSpaghettiPlot` seeded their axis ranges from row 1 unconditionally;
a blank or non-numeric first row left the seed undefined, every later comparison
against it was false, and the axis stayed undefined until `Axes:` aborted the
figure. Both now seed from the first *valid* observation, fold in only valid
values, fall back to a unit axis when nothing is usable, and say so in the Info
window. A guard sweep over the remaining aborting draw procedures — using
`@emlDrawGroupedViolin` as the reference implementation — covered
`@emlDrawTimeSeriesCI` (missing TIME cells no longer create phantom time
points), `@emlDrawViolinPlot` and `@emlDrawBoxPlot` (undefined values filtered
at accumulation so they never reach `@emlPercentile`'s `sort#`, empty groups
skipped). Dropped rows and skipped groups are reported.

**18 — `@emlBridgeGroupComparison` aborted on unset `annotCorrectionMethod$`.**
`graphs/eml-annotation-procedures.praat` (C 95). It now defaults to `"holm"` and
validates the value against what `@emlDunnTest` accepts.

---

## 4. Tier 3 — labelling and disclosure for the methods section

**19 — `@emlFormatEffectLabel` labelled R² with Cohen's *d* thresholds.**
`stats/eml-output.praat` (C 99). It now recognises `r_squared` (aliases `R2`,
`r2`) and applies Cohen's R² benchmarks 0.01 / 0.09 / 0.25 — the squares of the
r benchmarks 0.1 / 0.3 / 0.5. Under the old thresholds R² = 0.3 was labelled
small; it is large. An unrecognised effect type no longer falls back to *d*
thresholds: `.label$` is `""` and the new `.recognized` flag is 0.

**20 — "Pairwise holm" in report headers.**
`stats/eml-analysis.praat`, `stats/eml-inferential.praat`,
`scripts/eml-wizard.praat` (C 97). Root cause: `@emlPairwiseT.method$` echoed
the *adjustment* argument. It now names the test — `"Welch t-test"` or
`"Student t-test"` — and the adjustment moved to `.adjustMethod$`; the reporter
derives the header from `.test$`. Separately, the wizard announced a plan that
did not match what it dispatched: the two-group parametric route hardcoded Welch
regardless of the user's choice. A "Variance assumption" optionmenu now drives
`wizEqualVar` and the announced test name, and the ANOVA and Kruskal–Wallis
post-hoc plan strings name the method actually dispatched and no longer claim
conditional ("if significant") execution for Tukey and Dunn, which run
unconditionally.

**21 — the adjustment choice was lost on Draw.**
`graphs/eml-graphs-form.praat`, `scripts/eml-pairwise.praat` (C 95). The
annotation route hardcoded Holm. An "Adjustment method" optionmenu (Bonferroni /
Holm / Benjamini–Hochberg, default Holm) was added to all six annotate-capable
column-mapping dialogs, backed by shared persistence and a new
`@emlAdjustMethodName` index-to-string helper, plus an
`emlGraphsPresetCorrection$` preset global so a stats wrapper can carry its own
choice in; `eml-pairwise` now sets it. Two further preset-plumbing defects
surfaced and were fixed in the same file: the histogram dialog seeded the group
index but left "Use group column" unchecked, so `histGroupCol$` committed as
`""` and the grouped-histogram annotation route was silently skipped; and the
spaghetti dialog never consumed `emlGraphsPresetGroupCol$` at all, relying on a
name heuristic that runs only on the first spaghetti draw of a session. Both now
use explicit preset sentinels. `emlGraphsPresetXCol$` / `YCol$` were cleared only
inside the scatter page and leaked into the next workflow call whenever a
non-scatter type was chosen; both are cleared at workflow end.

**22 — significance-marker inconsistencies.**
`graphs/eml-annotation-procedures.praat` (C 95–96). `@emlFormatStars` hardcoded
0.05 / 0.01 / 0.001 regardless of the user's alpha; thresholds are now derived
from `annotAlpha` as alpha, alpha/5, alpha/50 — which reproduces the familiar
ladder exactly at the default 0.05 — and `.legend$` states the ladder actually
in force. The ANOVA omnibus-not-significant matrix path hardcoded
`annotMatrixSig = 0` and now takes it from the Tukey p actually printed in the
cell. The Kruskal–Wallis path's literal `"n.s."` now comes from
`@emlFormatStars`. And `@emlReportTwoGroupComparison` printed "Method: exact"
unconditionally with an incorrect "(n < 50)" total-n gloss; it now reports the
method `@emlMannWhitneyU` actually used (read defensively via `variableExists`)
and states the real routing rule — exact iff both groups have n < 50 and there
are no ties.

**23 — error-bar meaning was undisclosed, and clamped bars were silent.**
`graphs/eml-draw-procedures.praat` (C 99 / C 88). The bar chart now discloses
whether the error bars are SE, SD, or a custom column, in both the caption and
the Info window, and marks error bars truncated at the axis limits with outward
arrowheads instead of clipping them silently. The arrowhead depth (2% of the
visible y span) is set locally and deliberately — no library procedure provides
an out-of-range marker.

**24 — `@emlRMPostHoc` did not validate its adjustment argument.**
`stats/eml-analysis.praat` (C 95). An unrecognised string fell through to Holm
silently while the header printed the requested name. The header now prints the
method that actually ran and the substitution is disclosed.

**25 — five smaller correctness and documentation defects.**
`@emlEpsilonSquared` is capped at 1 with `.capped` / `.warning$` and guarded for
`.n <= 1` (`stats/eml-inferential.praat`, C 95). The Hedges' *J* header claim was
wrong: the approximation `J = 1 − 3/(4·df − 1)` overestimates the exact
gamma-ratio by at most **1.28% at df = 2**, not 0.27%, and reaches three decimal
places only at df ≥ 6; the documentation is corrected and the formula unchanged
(C 99, verified against `scipy.special.gammaln`). `@emlShapiroWilk` applied the
second pair-weight coefficient from n ≥ 7; Royston AS R94 and R's `swilk.c`
branch on n > 5, so it now applies from n ≥ 6 — n = 6 was the only sample size
in 3..12 that disagreed with R, and now agrees to 1e-6
(`stats/eml-core-descriptive.praat`, C 99). Two further defects surfaced in the
same file and are fixed: `@emlKurtosis` returned a spurious finite value (−13.5
at n = 4) when the SD is zero, where the standardised moment is 0/0, and
`@emlSkewness` had the analogous defect returning 0; both now return `undefined`
with `.error$` set.

**26 — group labels were case- and whitespace-sensitive.**
`stats/eml-extract.praat` (C 99). `"Male"`, `"male"` and `" Male"` were three
distinct groups. New helper `@eml_normalizeLabel` trims leading/trailing spaces
and tabs and lower-cases; `@emlCountGroups` uses it and warns when normalisation
merged distinct spellings, and the group extractors apply the same normalisation
so counting and extraction agree. `number()` coercion hazards are now detected
and reported, with the **European decimal comma listed first** because
`number("5,5") = 5` is the only one that yields a plausible wrong number rather
than a dropped row.

---

## 5. Tier 4 — housekeeping

**27 — catastrophic cancellation in the one-way ANOVA sums of squares.**
`stats/eml-inferential.praat`. Replaced the raw-score Hays formulas with a
two-pass centred algorithm, removing cancellation on large-offset data.

**28 — `sort#` on vectors containing undefined.**
`stats/eml-core-descriptive.praat`. `sort#` raises a hard error ("Vector
contains one or more undefined elements. Cannot sort.") that aborts the entire
calling script. New helper `@eml_hasUndefined` lets `@emlPercentile`,
`@emlTrimmedMean`, `@emlWinsorizedMean` and `@emlMAD` return `undefined`
instead. Related: `@emlCI` now rejects a confidence level outside (0, 1) — a
level of 1 made `invStudentQ(0, df)` loop forever, hanging the script.

**29 — column-existence validation.**
`stats/eml-analysis.praat`. `emlRunRegressionAnalysis` and
`emlRunNormalityAnalysis` guard their column names with `Get column index:`
instead of aborting the whole script with a raw Praat error that names no
column.

**30 — `@emlFormatP` boundary.**
`stats/eml-output.praat`. Any p in [0.9995, 1) formatted as "p = 1.000",
overstating the result as an exact 1. Such values now format as "p > .999";
p = 1 exactly still formats as "p = 1.000".

**31 — `@emlFormatStars(undefined)`.**
`graphs/eml-annotation-procedures.praat`. An undefined p fell through to
`"n.s."`. It now returns `"n/a"` — an undefined p is not the same as a
non-significant one.

**32 — dead parameters, dead procedures, and small defects.**
`stats/eml-analysis.praat`. The three reserved-but-unread parameters
(`emlRunNormalityAnalysis.testType$`, `emlRunRepeatedMeasuresAnalysis.subjectCol$`,
`emlRunFriedmanAnalysis.subjectCol$`) are documented as reserved with an
explanation of why no branch selects on them; the parameter lists are unchanged
because callers pass positionally, and removing one silently reassigns every
later argument. The unimplemented `emlRunReliabilityAnalysis` stub is marked as
such. `@emlBridgeCorrelation` is marked UNUSED (zero callers) rather than
deleted. The Friedman tie correction was re-verified against R's
`friedman.test` on tied data — formula and clamp correct, no change.

---

## 6. Two cross-file interaction adjudications

These are the two places where a local fix could have had a non-local
consequence. Both were checked explicitly and neither required further change.

**`emlBarData_*` disclosure globals (item 12).** The nine new globals are read
at six sites, all inside `graphs/eml-graph-procedures.praat`, and all are
unconditionally initialised before any read (declarations at lines 29–30,
initialisation at 2999–3000 and 3055). No other file reads them, so there is no
path on which an unconditional read can hit an unset global. No change.

**`exitScript:` in `@eml_getGroupData` / `@eml_getGroupPairedData` (item 2).**
The strict-numeric check aborts rather than returning empty data with `.error$`
set. The softer alternative was considered and rejected on evidence: a grep of
every caller across the plugin — roughly sixty call sites in
`eml-inferential.praat`, `eml-analysis.praat`, `eml-annotation-procedures.praat`,
`eml-check-normality.praat`, `eml-wizard.praat` and `eml-correlate.praat` —
found that **not one reads `.error$`**. Setting `.error$` and returning would
therefore be silently ignored at every site, reproducing exactly the
silent-wrong-number failure class the fix exists to eliminate. The abort is
object-clean (both temporaries are removed before it fires) and the message
names the offending column and the offending group.

One consequence is worth stating in the methods section: strictness is evaluated
on the **group subset**, so a clean group A together with a dirty group B aborts
the whole run rather than skipping B. For a validation-paper pipeline that is
the right disposition, and the message identifies which group is at fault.

---

## 7. Verification

Every fix was reproduced before and after, using the same script against
`plugin_BASELINE` and against the live tree, with reference values computed
independently in R 4.3.3 or scipy — never from recall.

- **R parity.** `wilcox.test` (both forms, exact and normal-approximation
  paths, with and without ties and zeroes), `p.adjust` for all three methods
  with `NA` present, `TukeyHSD`, `aov` two-way with unbalanced cells,
  `shapiro.test` across n = 3..12, `friedman.test` on tied data, `cor.test`
  for Pearson and Spearman.
- **scipy / numpy.** `scipy.special.gammaln` for the Hedges' *J* error table,
  `scipy.stats.shapiro`, `scipy.stats.kurtosis(bias=False)` for the excess-vs-raw
  convention, `scipy.stats.linregress`.
- **Praat-side reproduction.** Per-item baseline-vs-live pairs held under the
  session evidence tree `/home/claude/fix/a1`–`a7`: reproduction scripts, R and
  scipy verifiers, captured stdout, and before/after PNGs for the drawing items
  (`base_scatter.png` / `live_scatter.png`, the histogram and bar-chart probes).
- **Test board.** Phase 1: 96 + 52 + 74 + 40 = 262 assertions. Phase 2:
  57 + 48 + 87 + 82 + 111 + 165 + 85 + 108 + 36 + 29 + 33 = 841, plus the
  12-group ANOVA special (F = 216.6447, η² = 0.9803, 66 Tukey pairs) and the
  Shapiro–Wilk special (9/9). Integration test 42/42. Zero failures.

A note on reading Praat exit codes in this environment: Praat 6.6.30 segfaults
on `Quit` under `xvfb-run` (exit 139) after the script has completed
successfully. Pass/fail is judged from the contents of the output file, never
from the exit status.

---

## 8. What is still open

Nothing in §9. Three things remain outside it and are recorded here so they are
not mistaken for oversights.

1. **LMM is tabled at v0.8** and was not touched. It should not enter the
   validation paper in its current state.
2. **§10 of the v2 audit** — the "what I would still not bet on" list — stands
   unchanged. §7 of the v1 audit carries confidence 72; the damage matrix
   carries 85; the realism ratings are judgements, not measurements.
3. **`dev/tests/phase2/verify-inferential-batch3.R`** still contains an
   acknowledgement that R cannot produce exact-with-ties p-values and that those
   cases were verified via scipy. That note predates the R-parity contract now
   enforced in `@emlMannWhitneyU` and `@emlWilcoxonSignedRank` — under the
   corrected routing, the tied cases do not take the exact path at all, so the
   note is stale rather than wrong. It is a documentation cleanup, not a
   correctness issue.
