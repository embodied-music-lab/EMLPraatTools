# EML Praat Tools — Code Accuracy & PKB-Adherence Audit

**Scope:** Full plugin (`plugin EML Praat Tools.zip`), ~30,500 lines of source Praat across 30 files (dev/test scripts excluded from findings but read for context).
**Method:** Static review of every source file, cross-checked against the Master Prompt rules and APPENDIX_D canonical parameters. Core statistical formulas verified numerically against scipy/numpy on toy datasets; the five most severe findings re-read and confirmed line-by-line. One reviewer ran a Praat 6.6.30 barren sandbox to confirm tail-direction of the distribution functions and two suspected syntax issues.
**Date:** 2026-07-21
**Auditor:** Claude (Anthropic), for Ian Howell / EML.

---

## Executive summary

The statistical *engine* is in excellent shape. Every test statistic, p-value tail factor, degrees-of-freedom formula, effect size, tie correction, and continuity correction in `eml-inferential.praat` and the descriptive layer was checked and is **numerically correct** — several were verified to machine precision against scipy (Welch *t* and Welch–Satterthwaite df, pooled *t*, Cohen's *d*, Hedges' *g*, exact Mann–Whitney with ties, Kruskal–Wallis *H* with ties, Dunn's *z*, R-7 percentiles for the descriptive tables, adjusted Fisher–Pearson skewness, bias-corrected excess kurtosis, *t*-based CIs). Batch acoustic parameters are **all canonical** against APPENDIX_D. OLS lines, CI bands (proper `invStudentQ` *t*-critical values), Theil–Sen, viewport-before-save, and palette indexing in the figure layer are correct.

The defects that produce **wrong results** are concentrated in two places: **(1) the data-extraction plumbing that feeds paired and correlation tests silently misaligns rows when the table has any missing cells**, and **(2) the box/violin figures compute quartiles with a nearest-rank method that biases the median low and collapses it onto the minimum at small *n***. These are the two items to fix first — both corrupt output silently, on data shapes that are common in voice research.

Counts: **2 Critical, 4 High, 7 Medium, 7 Low.**

---

## CRITICAL — silent wrong numeric results on common data

### C1 · Paired tests misalign rows when either column has a missing value
**`stats/eml-analysis.praat:562–605` (`emlRunPairedAnalysis`)**

The orchestrator pulls the two paired columns with **two independent** `@emlExtractColumn` calls:

```
@emlExtractColumn: .tableId, .col1$   →  .v1#
@emlExtractColumn: .tableId, .col2$   →  .v2#
```

`emlExtractColumn` (`eml-extract.praat:92–113`) **drops `undefined` values per-column and resizes the vector**. So if column 1 is missing at row 3 and column 2 is missing at row 8, both vectors come back length *n*−1 but shifted relative to each other. `@emlTTestPaired`, `@emlWilcoxonSignedRank`, and `@emlMatchedPairsR` then difference **misaligned pairs** → silently wrong paired *t*, signed-rank, and matched-pairs *r*. If the two columns have unequal missing counts the vectors differ in length (wrong result or crash). `.n` is taken from column 1 only, and there is no `size(.v1#) = size(.v2#)` check.

A correct routine already exists and is unused: **`@emlExtractPairedColumns`** (`eml-extract.praat:282`) does row-wise complete-case deletion and returns aligned `.data1#`/`.data2#`.

**Fix:** replace the two `@emlExtractColumn` calls with a single `@emlExtractPairedColumns: .tableId, .col1$, .col2$` and use `.data1#`/`.data2#` / `.n`.
Complete data with no missing cells is unaffected — which is why this passed casual testing.

**Empirically confirmed (Praat 6.6.30, real `emlExtractColumn` + `emlTTestPaired`).** Table with `Pre` missing at row 2, `Post` missing at row 3: the code extracts `Pre={8,14,20,5,11}` / `Post={10,12,19,7,15}` and reports **n=5, meanDiff=1.0, t=0.913, p=0.413**; the statistically correct complete-case answer (scipy `ttest_rel`) is **n=4, meanDiff=1.75, t=1.698, p=0.188**. Row 3's `Pre` was paired with row 2's `Post`, and both incomplete rows contributed phantom pairs. No error is raised.
*Why the scipy/R test suite missed it:* the numeric tests (`batch1–7`) feed clean in-memory vectors **directly** to the procedures (`@emlTTestPaired: {…}, {…}`), bypassing extraction; the only orchestrator test (`test-workflow-verification`) builds **complete** tables and asserts the report merely *contains* "t"/"p", never checking values. The ragged-missing path was never exercised.

### C2 · Correlation misaligns X/Y when either column has a missing value
**`stats/eml-analysis.praat:624–648` (`emlRunCorrelationAnalysis`)** — and the same defect in the per-group path **`scripts/eml-correlate.praat:106–118`** via `eml_getGroupData` (`eml-extract.praat:909`).

Identical root cause: X and Y are extracted with two independent per-column `undefined`-dropping calls, then handed to `@emlPearsonCorrelation` / `@emlSpearmanCorrelation`. `.n = size(.dataX#)` is taken from X alone. When X and Y are missing in different rows, *r* is computed on mismatched pairs and reported as valid; when the missing counts differ, the lengths differ. The wrappers don't check `emlPearsonCorrelation.error$`.

**Fix:** extract X and Y with shared listwise deletion (one pass keeping rows where **both** are defined) — reuse the `emlExtractPairedColumns` pattern — and guard on `.error$` before reporting. Note the *regression* orchestrator (`eml-analysis.praat:753`) already does complete-case deletion correctly; copy that.

**Empirically confirmed (real `emlExtractColumn` + `emlPearsonCorrelation`).** Ragged table → the code reports **n=7, r=0.9704, p=0.0003** (silently, no error); complete-case truth (scipy `pearsonr`) is **n=6, r=0.9938, p=0.0001**. When the two columns' missing *counts* differ, the extracted vectors have different lengths and `emlPearsonCorrelation` instead returns r=undefined — a louder but still incorrect outcome (the correlation simply isn't computed).

---

## HIGH — wrong output in plausible cases / advertised feature silently broken

### H1 · Box/violin quartiles use nearest-rank `floor(n·p)` — median biased low, collapses at small *n*
**`graphs/eml-graph-procedures.praat:1566–1568` (violin) and `1643–1645` (box)**

```
.q1     = .sorted#[max(1, floor(.n * 0.25))]
.median = .sorted#[max(1, floor(.n * 0.5))]
.q3     = .sorted#[max(1, floor(.n * 0.75))]
```

`floor(n·0.5)` is systematically the order statistic *below* the true median and never averages the two middle values for even *n*. At small *n* it is egregiously wrong: for **n = 3**, `floor(1.5) = 1`, so the median line **and** the Q1 box floor both land on the **minimum** observation; for n = 5 the median is `sorted[2]` (true is `sorted[3]`). The biased Q1/Q3 also shift the 1.5·IQR Tukey fences, so outlier dots are mis-flagged. Voice-science groups are frequently small-*n*, and these are publication figures.

Note the inconsistency: the numeric **describe** path uses correct R-7 interpolated percentiles, so the table and the figure disagree — and the figure is the wrong one.

**Fix:** use a real quantile — median = `sorted[(n+1)/2]` (odd) / mean of the two central values (even); Q1/Q3 by linear interpolation `q = sorted[floor(h)] + (h−floor(h))·(sorted[floor(h)+1] − sorted[floor(h)])`. Ideally route through the same quantile procedure the describe layer uses (DRY).

### H2 · Kruskal–Wallis front-end passes `0.05` into the string "adjustment method" parameter — Dunn post-hoc broken
**`scripts/eml-compare-kw.praat:64`**

```
@emlRunKWAnalysis: tableId, dataCol$, groupCol$, 1, 0.05
```

The definition is `procedure emlRunKWAnalysis: .tableId, .dataCol$, .groupCol$, .doDunn, .adjMethod$` (`eml-analysis.praat:163`). The 5th argument is a **string** (`.adjMethod$`), and `emlDunnTest` (`eml-inferential.praat:2465`) requires `.method$ ∈ {bonferroni, holm, bh}`. Passing bare `0.05` either type-errors at the call (crash on every KW run) or coerces to `"0.05"`, which fails the method check so **Dunn's post-hoc silently never runs** — even though the script header advertises it. There is no alpha parameter on this orchestrator; `0.05` does not belong here.

**Fix:** pass a valid method string, e.g. `@emlRunKWAnalysis: tableId, dataCol$, groupCol$, 1, "holm"`; ideally expose an adjustment `optionmenu` as `eml-pairwise.praat` does.

### H3 · Grouped scatter prints a false "R² = 0.000" for Spearman/Theil–Sen fits
**`graphs/eml-draw-procedures.praat:2323 and 2331`**

`.gPearsonR` is initialized to `0` (line 2211) and is only assigned in the Pearson branch. In the Spearman + Theil–Sen path it stays `0`, but the annotation code runs `.gR2 = .gPearsonR * .gPearsonR` and the guard `if .gPearsonR <> undefined` is always true (0 ≠ undefined). So every group's on-graph formula and Info-window line reports **`R² = 0.000`** for a robust line that has no OLS R². The ungrouped path guards this correctly with `if .lineMethod$ = "OLS"` (line 2091); the grouped path does not.

**Fix:** mirror the ungrouped guard — only emit R² when the line method is OLS.

### H4 · Wizard has no k-paired (repeated-measures / Friedman) route
**`scripts/eml-wizard.praat:~715`**

The paired branch offers only "Column 1 / Column 2" and dispatches paired *t* / Wilcoxon signed-rank; the dialog is titled "Paired / repeated" but there is no ≥3-condition path anywhere in the decision tree. A researcher with 3+ repeated measurements is funneled into a two-condition test. Every wizard leaf that *does* exist names the statistically correct test — this is a missing leaf, not a wrong one.

**Fix:** add a repeated-measures sub-branch (Friedman for nonparametric, RM-ANOVA for parametric) when >2 measurement columns are chosen.

---

## MEDIUM — wrong user-facing interpretation / adherence with correctness risk

### M1 · Kurtosis wizard subtracts 3 from an already-excess value → normal data called "platykurtic"
**`stats/eml-output.praat:934` (`emlWizardExplainKurtosis`)** — `.excess = .kurt - 3`. `@emlKurtosis` returns **excess** kurtosis (normal = 0; verified against scipy `bias=False`). Subtracting 3 again yields excess−3, so normal data (≈0) is labeled `.excess ≈ −3` → "Light-tailed (platykurtic)", and the trailing "3 = normal" text contradicts the library's own normal-=-0 convention. **Fix:** `.excess = .kurt`; change the text to "0 = normal; |excess| < 3 typical."

### M2 · `beginPause` numeric defaults passed as quoted strings (Rule 19)
**`eml-batch-process.praat:102, 106, 178, 179`** — e.g. `natural: "Start from file", "1"` and `positive: "...", string$(highest_expected_F0)`. Rule 19: in `beginPause:` numeric/vector defaults must be **bare** (`, 1`), not quoted. `eml-edit-table.praat:421` does it correctly, confirming the inconsistency. **Fix:** pass bare numerics.

### M3 · `noprogress` missing on two in-loop analysis commands
**`eml-batch-process.praat:424` (`To PointProcess (cc)`) and `:444` (`To Intensity`)** — both inside the per-segment batch loop, unlike the correctly-prefixed `To Pitch`/`To Harmonicity`/`To PowerCepstrogram`. House rule requires `noprogress` on all in-loop analysis commands. **Fix:** prefix both.

### M4 · `nocheck endeditor` immediately before a load-bearing assignment
**`eml-edit-table.praat:43–45`; `eml-edit-table-editor.praat:18`** — `nocheck endeditor` then `nTables = numberOfSelected("Table")`. Per the `nocheck` errata, a failing `nocheck` command can corrupt the *next* variable assignment, so the "exactly one Table" guard could fail intermittently. **Fix:** use an explicit context check instead of `nocheck endeditor`. *(PLAUSIBLE — depends on Praat's exact `endeditor`-outside-block behavior.)*

### M5 · Duplicated, divergent tutorial engine
**`stats/eml-tutorial.praat` (v0.16) vs `scripts/eml-tutorial.praat` (v0.18)** — two ~650–725-line copies at different versions; the `stats/` copy's header even mislabels its own path as `scripts/…`. Neither is registered in `setup.praat`. DRY/maintenance hazard (Rule 35). **Fix:** delete the stale copy (or make one an `include` of the other) and register the canonical one.

### M6 · No plausibility guard on mean intensity
**`eml-batch-process.praat:472–531`** — F0, jitter, shimmer, HNR, CPPS each get a range check; mean intensity does not, though APPENDIX_D §7 lists Intensity 20–120 dB. Rule 30 inconsistency. **Fix:** add the intensity range check.

### M7 · Fixed pre-init caps in extraction
**`eml-extract.praat:136–138, 795–802`** — `for .init from 1 to 1000` / `to 100`. Extraction loops aren't themselves bounded, so no overflow, but only the first 1000 strings / 100 column-names are cleared; stale indexed values beyond the cap could persist across calls. Low probability. **Fix:** size pre-init to actual `nRows`/`nCols`.

---

## LOW — style, hygiene, adherence (no wrong results)

- **L1 · `eml-inferential.praat:3182–3185`** — `+=` compound assignment in `emlLinearRegression` violates the Master Prompt's forbidden-token list. Valid modern Praat (sandbox-confirmed), results correct, but breaks the project's own style contract. **Fix:** expand to `.ssXX = .ssXX + …`.
- **L2 · `eml-analysis.praat:736` / `eml-core-descriptive.praat:272–302`** — excess kurtosis reported under the bare label "Kurtosis" (a reader expecting Pearson kurtosis, normal = 3, misreads by 3). **Fix:** label "Kurtosis (excess)".
- **L3 · Headers** — many scripts (`compare-*`, `correlate`, `regress`, `pairwise`, `check-normality`, `create-demo`, `quick-start`, `setup`, both tutorials) are missing the RESEARCH USE DISCLOSURE section and/or the "Script author" line; `eml-quick-start.praat` has no attribution block. Framework name drifts between "EML Praat Assistant" and "EML PraatGen". **Fix:** apply the standard three-section header; standardize the name.
- **L4 · `eml-wizard.praat:~1417–1436`** — dot-prefixed variables used in main-body code (the paired-reshape block). Works, but `.`-prefix is procedure-local convention only (Rule 5C). **Fix:** rename to undotted or move into a procedure.
- **L5 · Dead code** — unreachable `@emlCSVInit` at `eml-wizard.praat:1332` (every real branch `goto`s past it; harmless because each orchestrator self-inits).
- **L6 · `eml-quick-start.praat:58–59`** references `docs/procedure-reference.md` and `docs/recipes.md`, which don't exist; and neither tutorial is registered in `setup.praat`, so the tutorial subsystem is unreachable from the Praat UI. **Fix:** ship the docs / register a Help entry, or remove the references.
- **L7 · `eml-inferential.praat:2353–2388`** — Kruskal–Wallis: only `H = 0` is special-cased; a tiny-negative `hRaw` from rounding on near-identical groups could reach `chiSquareQ`. Negligible impact (p≈1). **Fix:** clamp `if .h < 0 : .h = 0`.

---

## Verified correct (checked, no defect)

Inferential math (Welch *t* + Satterthwaite df, pooled *t*, one/two-way ANOVA SS/df, Mann–Whitney exact + tie correction, Wilcoxon signed-rank, Kruskal–Wallis + ties, Dunn, chi-square; two-tailed p = 2·`studentQ(|t|,df)` and equivalents with correct upper-tail usage confirmed in sandbox; Cohen's *d* pooled-sample-SD denominator; Hedges' *g* factor; η²/partial η²/ω²/Cramér's V/rank-biserial/Cliff's δ; BH step-up correctly avoids the descending-`for` gotcha). Descriptive layer (sample *n*−1 SD/SEM, R-7 percentiles, adjusted Fisher–Pearson skew, bias-corrected excess kurtosis, *t*-based CIs with correct df/tail, Winsorized/trimmed means, MAD ×1.4826, geometric/harmonic means, tie-corrected rank averaging). Regression orchestrator's complete-case deletion. All batch acoustic parameters vs APPENDIX_D (FAC pitch 11-param + 2× top rule, raw-cc pitch 10-param, jitter/shimmer, Harmonicity, Intensity, PowerCepstrogram/CPPS Maryn set) and pitch-algorithm-to-purpose routing. Figure layer: OLS slope/intercept, CI band `invStudentQ(α/2, n−1)`, Theil–Sen, viewport-before-save (Rule 28I via `@emlAssertFullViewport`), special-char sanitization (Rule 28J), categorical jitter (Rule 28K), axis buffer/non-negative clamp/percentage axes, palette modulo indexing. All two-group and pairwise front-ends route the correct test with the correct effect size and correct positional argument order; regression predictors not swapped; Shapiro–Wilk interpreted correctly.

---

## Suggested fix order

1. **C1 + C2** — swap the paired/correlation orchestrators (and the per-group correlation path) onto `emlExtractPairedColumns` / shared listwise deletion. One-procedure change each; highest correctness payoff.
2. **H1** — replace the box/violin quantile computation with interpolated quantiles (route through the describe layer's method).
3. **H2, H3, H4** — one-line KW argument fix; grouped-R² OLS guard; add the wizard repeated-measures leaf.
4. **M1–M7**, then the Low batch.

---

# Addendum — GUI / path audit (follow-up)

**Scope:** every `form:` and `beginPause:` dialog in the 17 GUI-bearing files (2 `form:` blocks, ~106 `beginPause:` blocks), all **389 derivable fields**, all file-path handling, and `endPause` cancel discipline. Praat 6.6.30 (barren) was used to test the default-type behavior empirically.

## Correction to the main audit — prior **M2 is withdrawn**

The main audit flagged `beginPause:` numeric fields that use quoted / `string$()` defaults (batch-process ×4, graphs-form ×9 — 13 sites) as a Rule 19 violation. **Empirical testing shows these are not defects:**

- Barren 6.6.30 (parse): `real: "Alpha", 0.05` (bare) inside a **`form:`** raises the exact canonical error *"Only 'choice', 'optionmenu' and 'boolean' fields can take a number"* — confirming the form-must-quote rule. The **same** quoted `"0.05"` and `string$(x)` defaults inside a **`beginPause:`** parse with **no error**.
- **Full-GUI value-binding test (Praat 6.6.30 under Xvfb + matchbox WM, dialogs driven with the Enter key).** Three `beginPause` dialogs were dismissed at their defaults and the resulting variables written to disk:
  - bare `real: "Alpha", 0.05` → `alpha=0.05, count=7`
  - `string$()` `real: "Beta", string$(xa)` → `beta=0.05, num=7`
  - quoted `real: "Gamma", "0.05"` → `gamma=0.05, qty=7`

  In every case `alpha+count = 7.05` (etc.) — the arithmetic proves the fields bound proper **numeric** values, not strings, for all three default forms.
- APPENDIX_C's *own* `beginPause` example likewise uses quoted numeric defaults: `positive: "Formant ceiling (Hz)", "5500"`, `natural: "Number of formants", "5"`.

So `beginPause:` accepts bare, `string$()`, **and** quoted numeric defaults, all binding correct numeric values — **empirically confirmed by driving the real GUI**. Rule 19's "must be bare / wrong form" is stricter than Praat actually is and is contradicted by both the GUI test and APPENDIX_C. The 13 sites are, at most, a style-consistency nit — **M2 withdrawn (was MEDIUM → none).**
*Doc action:* reconcile master-prompt Rule 19 against APPENDIX_C in the PKB — they disagree, and the GUI test sides with APPENDIX_C.

The 13 sites (for reference): `graphs/eml-graphs-form.praat:1061,1062,2569,2912,3698,4000,4015,4348,4659`; `scripts/eml-batch-process.praat:102,106,178,179`.

## Clean results (verified, no defect)

- **Rule 20 referenceability — CLEAN.** All 389 derivable field labels produce names matching `^[A-Za-z][A-Za-z0-9_]*$`. No operator/leading-digit labels; no unreferenceable derived variables.
- **Rule 26 path solicitation — CLEAN.** Every file path is gathered through a `folder:`/`infile:` browse field (7 sites: eml-output, graphs-form ×3, batch-process ×2, wizard). No hardcoded absolute paths anywhere; the only path-literal is a `homeDirectory$ + "/Desktop"` *default*, guarded by `folderExists`, which is correct.
- **Rule 27 overwrite protection — CLEAN.** Every user-output write is collision-protected: graphs PNG (`graphs-form:5558/5560`) and CSV export (`5591`) via `@emlGenerateUniquePath`; the stats report writer (`eml-output:490–515`) via its own `_1.._999` increment loop; the batch CSV (`batch-process:616`) via an inline `fileReadable` `repeat/until` loop (`232–239`). Config-prefs files and the STOP-sentinel are intentionally overwritten (correct).
- **`endPause` cancel discipline — CLEAN.** Every call ends with a bare default/cancel index; both the trailing-`0` pattern and the cancel-button (`,N,1`) pattern are used validly, with explicit `clicked` handling.
- **`form:` default-type — CLEAN.** The single numeric-bearing `form:` (edit-table) quotes its numeric defaults correctly.

## Minor note (new)

- **DRY (Rule 35):** there are **three** independent unique-path implementations — `emlGenerateUniquePath` (graphs-form only), the inline loop in `eml-output`, and the inline loop in `batch-process`. `emlGenerateUniquePath` is defined *inside* the graphs module, so the stats/batch writers can't share it. Consolidate into one library procedure the whole plugin includes. (Low priority — behavior is correct in all three.)

**Net GUI verdict:** the dialog layer is in good shape — no unreferenceable variables, no hardcoded paths, no unprotected output writes, correct cancel handling — and the one item the rule-checker flagged (beginPause quoted defaults) is confirmed a non-issue by driving the real GUI.

---

# Update 2026-07-21 — C1 / C2 FIXED and verified

Rewired both orchestrators (`stats/eml-analysis.praat` 1.0→1.1) and the per-group correlation path (`scripts/eml-correlate.praat` 3.2→3.3) onto **row-wise complete-case extraction** — `@emlExtractPairedColumns` for paired/correlation, and a new `@eml_getGroupPairedData` (`stats/eml-extract.praat` 1.3→1.4) for grouped correlation. Analyzed *n* is now the complete-pair count, and each orchestrator emits a "*N row(s) excluded for missing data*" note when rows are dropped. Independent-groups tests and univariate describe are untouched (per-column deletion is correct there — rows aren't linked).

Re-run on the same ragged tables (Praat 6.6.30 vs scipy): paired → **n=4, |t|=1.6977, p=0.1881**; correlation → **n=6, r=0.9938, p=0.0001**; grouped extractor drops the incomplete row (n=3, excluded=1) with X/Y aligned; source Table preserved (Rule 4B); all three files parse. Compliance self-check on the added code: modern syntax, `#`-only line comments, no forbidden tokens (`+=`/`==`), no reserved-name assignments, selection discipline before every query, exclusion notes built into a variable before `appendInfoLine` (House rule), DRY (reused the existing extractor). Delivered as `plugin_EML_Praat_Tools_missing-data-fix.zip` (+ `MANIFEST.txt`, `FIX_NOTES.md`).

# Why previous PraatGen builds missed this

The through-line: **PraatGen is engineered to guarantee code that runs correctly *as Praat* — not code that computes the statistically correct quantity on real, incomplete data.** Those are different properties, and missing-data handling sits in the gap. Specifically:

1. **The verification model is command-level, not dataset-level.** The 37 rules, SELF-AUDIT, and SOT checks all ask "does each command exist and take the right parameters / canonical values?" Every line here *was* valid Praat using the right command — the bug is in the *composition* of two individually-correct procedures. No rule asks whether the data pipeline preserves the row alignment the analysis assumes.

2. **Rule 32 (scipy verification) reinforced the blind spot instead of catching it.** The team did verify the statistics against scipy — and the procedures are correct. But Rule 32 targets the *math*, and it was tested by feeding clean vectors straight into the procedures. It certified the engine while the fuel line was cross-connected. It never says "verify the extraction that feeds the procedure, on messy data."

3. **The fixtures were synthetic and complete.** Every test hand-codes clean vectors (`{10,12,14,16,18}`) or builds tables with a value on every row. Missing data only exists in real datasets; a dev loop built on generated complete data structurally cannot surface it. The bug is invisible on any dataset the developers would naturally create — it appears only on the incomplete data researchers actually have.

4. **The one orchestrator-level test checked shape, not values.** `test-workflow-verification` asserts the report merely *contains* "t"/"p"/"r". Even the test that ran the buggy orchestrator couldn't catch a wrong number, because it never read the numbers.

5. **The correct helper existed but was unused, and no rule flags that.** `emlExtractPairedColumns` was already written — someone knew paired extraction needs complete-case — yet the orchestrators called the univariate extractor. Rule 35 (DRY) catches *duplicated* code, not "you reimplemented a weaker version of an existing helper." The smell was present but unnamed.

6. **Silent by construction, and nothing watches *n*.** With equal missing counts the vectors stay equal-length, so no error fires and the result looks plausible. Rule 30 plausibility checks exist — but only for *acoustic* measures (F0/jitter/HNR ranges); there is no statistical analogue asserting, e.g., that analyzed *n* equals the table's complete-case count.

**Concrete additions worth making to the Master Prompt:** (a) a *data-integrity / unit-of-analysis* rule — any multi-variable row-linked analysis (paired, correlation, regression, RM) must use row-wise complete-case extraction across all involved variables, report analyzed *n* and excluded count, and never silently change *n*; (b) extend Rule 32 so statistical fixtures must include a missing-data case and orchestrator tests assert *values* against scipy, not report shape; (c) a statistical analogue to Rule 30 that checks analyzed *n* against the table's complete-case count for the variables used.

---

# Update 2026-07-21 — graph findings H1/H3/M3/M4 FIXED, L reverted

Six edits across three graph files, each verified with the **real** Praat 6.6.30 procedures and then re-checked by an independent adversarial reviewer (which caught and forced the revert of one bad edit).

- **H1 — box/violin quartiles.** Both sites now call the shared R-7 `@emlQuartiles` (which the numeric describe layer already uses) instead of nearest-rank `floor(n·p)`. Verified `emlQuartiles` reproduces `numpy.percentile` exactly for n=3/4/5 (n=3 → 3.5/5/7; the median no longer collapses onto the minimum). Figure and table now agree. `graphs/eml-graph-procedures.praat` 3.20→3.21.
- **H3 — grouped scatter false R².** R² is now emitted only when the group line is OLS (`if annotCorrType$ <> "spearman"`), mirroring the ungrouped guard; the Spearman/Theil–Sen path prints the equation with no R². `graphs/eml-draw-procedures.praat` 1.17→1.18.
- **M3 — bar charts with negative means.** Auto-range now tracks `emlBarData_visibleMin`, routes through `@emlComputeAxisRange`, and the bar baseline is decoupled from `yMin` (bars emanate from 0). Verified: all-negative means → axis −10..10 (visible); non-negative → yMin stays 0 (unchanged). The annotated/bracket sub-case is closed in `graphs/eml-graphs-form.praat` 1.8→1.9.
- **M4 — scatter over-ranging fractional data.** Scatter axes derive an adaptive `roundTo` from `@emlComputeNiceStep` instead of hardcoded `1`. Verified: x∈[0.45,0.55] now maps to axis 0.44..0.58 (was 0..1).
- **L — B/W sprite (reverted, not fixed).** The first attempt set `sprite$` to an RGB grey; adversarial review found `sprite$` holds PNG-filename stems (`bw01`..`bw10`), so that silently disabled alpha transparency — reverted. A correct fix needs the sprite grey-level table; deferred (low, cosmetic).

Delivered as `plugin_EML_Praat_Tools_fixes.zip` (both the missing-data and graph fixes, + MANIFEST + FIX_NOTES).

# Why the graph bugs happened

Distinct from the missing-data root cause, but with an overlapping theme.

1. **Two implementations of the same math, no single source of truth (H1).** The describe layer has a correct R-7 `emlQuartiles`; the box/violin drawing code — written as a separate silo — rolled its own `floor(n·p)` inline. A correct number (the table) and its picture (the box plot) diverged because they were computed by different code that nobody tied together. This is the same shape as the missing-data bug (a correct helper existed but the caller reinvented a weaker version).

2. **The failures live where verification is hardest.** These are rendering defects — quartile positions, axis bounds, annotation text. You can assert a p-value against scipy in a headless test; you cannot assert what a figure *draws* without rendering it, and Praat plots need the full GUI/Picture window the barren test harness can't run. The whole drawing layer sits in a verification blind spot: the suite validated the numeric procedures but literally could not see the plots. Visual bugs survive because nothing automated looks at the pixels.

3. **They only appear on data shapes the developers didn't generate.** Small-n groups (H1), all-negative means (M3), fractional ranges like 0.45–0.55 (M4), a Spearman fit with a drawn line (H3) — these are real-research inputs that don't show up in happy-path fixtures (moderate n, positive integer-ish data, Pearson). A bug invisible on the data you test with survives indefinitely.

4. **Copy-paste-and-diverge between paths, plus init-to-zero masking (H3).** The grouped scatter path was cloned from the ungrouped one but dropped its `lineMethod$ = "OLS"` guard, relying instead on `.gPearsonR <> undefined` — always true, because the variable initializes to `0`, not `undefined`. Initializing "no value" as a real number (0) turned the absence of a fit into a fit of exactly zero that the guard couldn't distinguish.

5. **Auto-range written for the common case, not the general one (M3, M4).** `visibleMax` seeded at 0 and only grown; `yMin` pinned to 0; `roundTo` hardcoded to 1 — each is a fine default for positive, integer-ish data and silently wrong for signed or small-magnitude data. No rule required ranges to be general in sign and scale.

**The unifying lesson (graphs + missing data):** this plugin's correctness is validated at the level of individual numeric procedures, but its failures live in the *seams* — between a correct helper and the code that should call it, and between a correct number and the picture it should produce. Command-level MP rules and a headless numeric test suite don't cover those seams. Two concrete additions for graphs specifically: (a) the drawing layer must reuse the stats layer's math (one quantile/quartile source of truth, enforced), and (b) figures need visual-regression testing — render to PNG and diff against a baseline — because numeric assertions can't see what's drawn.
