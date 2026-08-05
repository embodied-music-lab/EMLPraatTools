# EML Praat Tools — Pre-Stress-Test Audit (non-LMM surface)

**Date:** 2 August 2026
**Scope:** the entire stats + graphs surface **excluding** LMM (`stats/eml-lmm.praat` v0.8, `stats/eml-linalg.praat`, `stats/eml-optimizer.praat`, `scripts/eml-lmm.praat`, the wizard's mixed-model route, `@emlDrawLMMForest`) — tabled at 0.8 by decision.
**Method:** seven parallel read-only audits, every finding **executed** in Praat 6.6.30 (barren, `--run`, unpiped) and differentially tested against R 4.3.3 and scipy 1.17.1 / numpy 2.4.4 / statsmodels 0.14.6. No plugin file was modified during the audit.
**Purpose:** establish what must be true before Josh Gilbert's stress test of the stats for the validation paper.

---

## 0. The short answer

Four defects produce **wrong numbers with an empty `error$` on data a reasonable user would call clean**. These are the ones that could put a false number in the validation paper:

1. **`Get all numbers in column:` returns alphabetical ranks** when any cell in the column is not fully numeric — `stats/eml-extract.praat:921, 961–962`. One cell reading `14 Hz` converts that group's entire data column to 1, 2, 3, … The `<> undefined` filter does not catch it because `Get value:` on the same cell partially parses to 14. F went 60 → 193.4 with no error. This is the highest-blast-radius defect in the plugin: every ANOVA, Kruskal–Wallis, Tukey, Dunn, Scheffé, pairwise-t and pairwise-Wilcoxon route, plus the graphs bridge, reads through it.

2. **Pearson results are overwritten by Spearman before they are reported** — `stats/eml-inferential.praat:447` + `stats/eml-analysis.praat:656–664`. `emlSpearmanCorrelation` calls `@emlPearsonCorrelation` on the ranks, clobbering the durable procedure-output globals. With "Both" selected, the **Pearson section of the report and the CSV export display Spearman's rho.** True r = 0.6825 / p = 0.3175 was displayed as 0.400 / 0.600.

3. **Two-way ANOVA uses the wrong error term for every unbalanced design** — `stats/eml-inferential.praat:2054`. Delete one row from a balanced file and it breaks. Observed MSE 11.5× too large on one 2×2 (interaction p 0.0131 → 0.3636) and 4.89× too *small* on a 2×3 (anti-conservative: p 1.05e-4 → 2.99e-10). At 5/5/5/2 it emits **negative Error SS (−33.38), negative F, partial η² = −4.675, and an empty `error$`**. No balance check, no negative-SS check, no Type I/II/III statement.

4. **Post-hoc tests report p = 1 for perfectly separated groups** — Tukey `:1718`, Scheffé `:3112`, Dunn `:2565, 2573`. Zero within-group variance → `se = 0` → `q = undefined`; the guard `if .q > 0` is FALSE for `undefined`, so control falls to `else .p = 1`. R gives p adj = 0. This is the worst possible failure direction: a 900-unit separation reads as "definitively no effect."

Everything else below is either narrower, louder (crashes), or a disclosure item Josh needs so his R cross-check doesn't report spurious mismatches.

---

## 1. Silently wrong numbers on ordinary data

### 1.1 Rank substitution in group extraction — CRITICAL
`stats/eml-extract.praat:921` (`eml_getGroupData`), `:961–962` (`eml_getGroupPairedData`).

`Get all numbers in column:` silently returns **alphabetical ranks** if *any* cell in the column fails full numeric parse. Ranks are computed per group sub-table, so only the affected group is corrupted — group A becomes 1–4 while B and C keep their real 20–36 values. R reproduces the poisoned output exactly, which proves the arithmetic is correct and the *inputs* are wrong.

`emlValidateNumericColumn` **cannot detect the trigger** — it counts partial parses as numeric.

Blast radius (call sites reading through the poisoned path): `emlTukeyHSD` 1677/1732/1735 · `emlOneWayAnova` 1879 · `emlKruskalWallis` 2300/2316 · `emlDunnTest` 2499/2515/2627/2630 · `emlPairwiseT` 2755/2758 · `emlPairwiseWilcoxon` 2902/2919/2922 · `emlScheffe` 3065 · `eml-analysis.praat` 68/71/145/148/213/216 · `eml-annotation-procedures.praat` 1880–2121, 2550–2967 · `eml-check-normality.praat:130` · `eml-wizard.praat:1843, 2053` · `eml-correlate.praat:112`.

**Fix:** replace with the row-wise `Get value:` loop that `emlExtractColumn` already uses correctly, and harden `emlValidateNumericColumn` to reject partial parses.

### 1.2 Pearson/Spearman global clobber — CRITICAL
`stats/eml-inferential.praat:447`; orchestrated at `stats/eml-analysis.praat:656–664` (Pearson :657 → Spearman :660 → report :664); consumed at `graphs/eml-annotation-procedures.praat:3027, 3036, 3040, 3044–3049`. Reached from `scripts/eml-correlate.praat:64` ("Both") → `:98`.

Praat procedure outputs are durable globals overwritten on the next call to the same procedure. Spearman calls Pearson internally; the report then reads the clobbered values.

**Fix:** copy `emlPearsonCorrelation.*` to caller-scope locals immediately after the call, before Spearman runs.

### 1.3 Two-way ANOVA error term — CRITICAL
`stats/eml-inferential.praat:2054`. Wraps Praat's `Report two-way anova:`, which uses unweighted-means SS with SS_Error obtained by subtraction. Correct only for balanced designs.

**Fix:** compute SS_Error directly from within-cell deviations; add a balance check and a negative-SS guard; state the SS type in the report header.

### 1.4 Catastrophic cancellation in one-way ANOVA — CRITICAL
`stats/eml-inferential.praat:1891, 1906, 1908–1910` use the naive `Σx² − (Σx)²/n`. At mean ≈ 1e6 only ~4 significant figures survive; at 1e8 all SS collapse to 0 with F/p undefined and an empty `error$`; at 8.7e7, `ssB = −8` and `η² = 1`.

The report then contradicts itself — η² = 0 printed beside Cohen's d = −1.166 "large effect"; ANOVA F undefined beside a Tukey p = 0.046 on the same data.

`emlTukeyHSD:1650` already uses the correct centered form. **Fix:** use the centered/two-pass form throughout.

### 1.5 ANOVA line parser reads the wrong factor
`stats/eml-inferential.praat:~1390`, `eml_parseAnovaLine`, uses `extractLine$`, which returns the **first** matching line. A factor name that is a substring of the other (`Cond` vs `Condition`) shifts every parsed field one column and **emits a p-value of 283.67**.

### 1.6 Tie handling and exact-vs-approximate selection in the rank tests — CRITICAL
- `emlMannWhitneyU:648` applies the **exact tie-free null under ties**. Matches neither R (0.05191) nor scipy exact (0.0732); EML gives 0.0479798. Worst observed divergence 0.082 over 120 cases.
- Same line: the exact/normal threshold is `n1+n2 < 50` where R uses `n1 < 50 AND n2 < 50`. 200/200 tie-free cases used the normal approximation where R used exact; 2 decision flips at α = .05, 2 at α = .01. **The inline comment falsely claims it "matches R `wilcox.test` threshold."**
- `emlWilcoxonSignedRank:939` — same defect class. EML 0.0029297 vs R 0.00703 (2.4× smaller); 1 flip at α = .01.
- `eml_mannWhitneyExactP:542, 556` and `eml_wilcoxonExactP:803, 817` — half-integer statistics use `floor` on the left tail and `ceiling` on the right, truncating **both** tails. Systematically anti-conservative.
- One-tailed p at `:657, 734, 955` is computed "in the direction of the observed effect" — i.e. always the smaller tail. EML 0.00108 where R gives 1.0 (~920×). Doubles the nominal Type I error. (Not currently reachable from any front-end — every `tails` argument in the shipped surface is the literal 2 — but it is a live trap for the direct procedure API.)

Propagates into `emlRankBiserialR:1073`, `emlMatchedPairsR:1150`, `emlPairwiseWilcoxon:2865` — one Bonferroni-adjusted pair reads 0.0476 (significant) where R gives 0.0577 (not).

### 1.7 Correlation p-value edge cases
- `emlPearsonCorrelation:372` hardcodes `p = 0` when r² ≥ 1. Reached through Spearman `:418`: n = 3 perfect monotone gives p = 0 where R gives 0.3333.
- `emlSpearmanCorrelation:418` always uses the t-approximation; R uses exact AS89 for small tie-free n. 2.6× anti-conservative at n = 8. Matches scipy, not R — and this is undocumented.

---

## 2. Silently wrong numbers on degenerate or dirty data

### 2.1 `undefined` guards that fail open
Praat 6.6.30 evaluates **both** `undefined < X` and `undefined >= X` as FALSE. Every guard of the form `if .q > 0 … else` therefore takes the `else` branch on a failed computation:

- Tukey `:1718`, Scheffé `:3112`, Dunn `:2565, 2573` → **p = 1** for perfect separation (§0 item 4).
- `emlOneWayAnova` with zero within-variance → **η² = 1.0000** with F/p undefined and empty `error$`.
- `emlRunTwoGroupAnalysis` (`stats/eml-analysis.praat:46–107`) and `emlRunRepeatedMeasuresAnalysis` (`:1187`) **never check the engine's `error$`**. `emlTTest` does set it correctly; the orchestrator discards it and prints "Magnitude negligible effect" for perfectly separated groups.
- Zero-variance skewness returns 0 and kurtosis returns **−13.5** at n = 4 (`stats/eml-core-descriptive.praat:287–289`); R returns NaN.

**Fix pattern:** replace every `if x > 0` / `if p >= alpha` guard on a possibly-undefined quantity with an explicit `if x <> undefined` outer test.

### 2.2 The graphs layer has no missing-value filter — the stats layer does
Seven drawing procedures read `number(Get value:)` with no undefined guard and feed the result straight into min/max seeds, accumulators, `sort#`, or draw commands. Six abort loudly (EXIT=255). One does not:

- **`emlMeasureBarData` — `graphs/eml-graph-procedures.praat:2662–2690`** — not one undefined guard. `count` is incremented for the undefined row, so even the denominator is wrong; mean/SD/error bars all go undefined; and because `if .var > 0` is FALSE for undefined, `emlBarData_error[.g]` keeps its 0 initialisation → **a zero-length error bar for a group that has real variance**. The drawing layer reports n = 4 / mean = undefined / sd = 0 where the stats layer reports n = 3 / mean = 12 on the same column.
- Aborting (loud, but blocking): `emlDrawTimeSeries` `graphs/eml-draw-procedures.praat:596–598, 610–613` and the segment loop ~`:640` · `emlDrawSpaghettiPlot` `:1136–1140, 1160–1165, 1243` · `emlDrawViolinPlot` `:1660–1674, 1747–1758` · `emlDrawBoxPlot` `:2474–2476` (`sort#` error).

**The correct sibling already exists in the same file:** `emlDrawGroupedViolin` (`:3057–3110`) has both guards, as do `emlDrawGroupedBoxPlot`, `emlDrawScatterPlot`, `emlDrawTimeSeriesCI`. Liveness confirmed: `graphs/eml-graphs-form.praat:5370–5425` passes the user's Table through unfiltered.

### 2.3 Praat coercion hazards in Table cells
`".5"` → **undefined**, row silently dropped. `"30%"` → **0.3**, value silently divided by 100. `"inf"` / `"nan"` → undefined. `emlCountGroups` (`stats/eml-extract.praat:842`) uses exact string equality, so `Control` / `control` / `Control ` become three groups and the descriptives table renders two visually identical rows.

### 2.4 `sort#` on undefined aborts
Eight sites: `stats/eml-core-descriptive.praat:62, 94, 149, 367, 400, 653`; `stats/eml-core-utilities.praat:345, 395`.

---

## 3. Figures that state the wrong statistic

### 3.1 Stale annotation labels — CRITICAL
`graphs/eml-annotation-procedures.praat:1900, 1902` (KW/Dunn) and `:2065, 2067` (ANOVA/Tukey) read `annotMatrixLabel$[]`, which is written **only** in the MATRIX branches and is **not reset by `@emlClearAnnotations` (284–301)**.

- Fresh session + Annotate layout + k ≥ 3 + effect sizes ON → hard abort.
- After any prior Matrix run → **stale labels pair the right p with the wrong pair's effect size.** Observed: a bracket over groups 1–2 labelled d = 4.50 when the true d = −1.64.

`@emlMeasureMatrixLayout` (1114–1148) also truncates these labels in place with an ellipsis.

### 3.2 Scatter: reported line ≠ drawn line — CRITICAL
`graphs/eml-draw-procedures.praat:2062–2068` **reports** OLS via `@emlLinearRegression`; `:2074–2080` **draws** Theil–Sen; `:2118–2134` prints the Theil–Sen equation unlabelled. The `"Theil-Sen:"` disclosure at `:2113–2115` is gated `if scatterAnalysisType < 2` — suppressed exactly where it is needed. Observed: reported `y = 3.0855x − 3.9400, R² = 0.7500` against a drawn `y = 2.0143x − 0.0786`. Same defect in the grouped branch (`:2296–2299` vs `:2304–2334`, disclosure suppressed at `:2360`).

### 3.3 Effect-size and significance labelling
- `emlFormatEffectLabel` (`stats/eml-output.praat:315–370`) receives `"r_squared"` from `graphs/eml-annotation-procedures.praat:3204`, doesn't recognise it, and **applies Cohen's d thresholds to an R²** — R² = 0.15 renders as "negligible effect."
- `emlFormatStars` (`graphs/eml-annotation-procedures.praat:309–319`) hardcodes 0.001/0.01/0.05 and **ignores user-set `annotAlpha`**, while bracket *inclusion* uses it: α = 0.01 with p = 0.03 draws a `*`; α = 0.10 with p = 0.07 draws a bracket labelled `n.s.`
- `emlFormatStars(undefined)` returns `"n.s."` and the suppression branch never fires (both `<` and `>=` are FALSE for undefined) — **a failed computation renders as a real non-significant result.**
- `emlFormatP` (`stats/eml-output.praat:199`) prints `p = .050` for 0.04999, 0.05000 and 0.05040 alike while decisions use the unrounded value → a `*` beside a printed `p = .050`.
- `graphs/eml-annotation-procedures.praat:2110–2113` — non-significant omnibus in Matrix layout shows the real Tukey adjusted p but hardcodes `annotMatrixSig = 0`, painting the cell grey under a "p < alpha" legend. Reachability proved in R (k = 6, n = 4: omnibus p = 0.0529, Tukey pair p = 0.0322). The KW/Dunn branch at `:1946` writes the literal `"n.s."` instead — the two branches are inconsistent with each other.
- Bar-chart error bars (`graphs/eml-draw-procedures.praat:1504–1620, 1577–1595`) have **no disclosure anywhere of SE vs SD vs custom** (a √n ambiguity), and clamped bars/error bars get a **normal terminal cap** (`:1573, 1584–1595`), so truncation is invisible.

---

## 4. Hard crashes — loud, but they block the stress test

| Site | Defect |
|---|---|
| `scripts/eml-wizard.praat:2047` | `@emlExtractMultipleGroups` — **does not exist anywhere in the plugin** (removed at `eml-extract` v1.1). Reached from the menu: Describe → "By group" (`:1355`). `:2053` also calls `@eml_getGroupData: .g` with 1 argument against a 4-parameter definition — currently masked by the first error. |
| `graphs/eml-draw-procedures.praat:2671–2686 / 2700–2726` | `emlDrawHistogram` guards `if .nGroups > 0` where it means `.hasGroups = 1`. `.nGroups` initialises to 1 and is never 0, so `Get value: .i, ""` runs unconditionally. **Every ungrouped histogram aborts on completely clean data.** Single call site `graphs/eml-graphs-form.praat:5408`, fed by `:4143–4148`. |
| `scripts/eml-stats-demo.praat:245, 247` | `@emlDrawViolin` called with 6 arguments; the definition at `graphs/eml-graph-procedures.praat:1414` takes 7 → `Error: Empty formula.` Aborts panel 1's first violin, so no figure draws at all. (This root-causes the previously-logged §G "Empty formula" item.) Info-window statistics for all three panels print correctly first. |
| `scripts/eml-tutorial.praat:19` | `include ../tutorial/eml-demo-procedures.praat` — **the `tutorial/` directory does not ship.** Fails at parse time. Registered on the menu at `setup.praat:69`. The ~105 undefined-procedure hits reported for this file are all downstream of this one missing include. |
| `stats/eml-analysis.praat:843, 787`; `stats/eml-extract.praat:916` | Non-existent column name aborts in `emlRunNormalityAnalysis`, `emlRunRegressionAnalysis` and `emlRunTwoGroupAnalysis`, all of which bypass the existing `emlValidateNumericColumn`. Three other orchestrators return a clean error. |
| `stats/eml-analysis.praat:920` | `emlRunReliabilityAnalysis` is a stub: "Not yet implemented — scheduled for Phase 4." |

---

## 5. Routing and labelling (front-end → engine)

The exhaustive call-site/definition alignment check — 30 in-scope call sites, one row per positional argument, generated from a continuation-aware parse of 261 definitions and 1442 call sites — came back **clean**. No positional swap, no `$`/`#` type-suffix mismatch, no method-string case/spelling/hyphenation divergence, no Rule 20 derivation error, no numeric-default polarity error, no `tails` encoding error. The previously-logged H2 defect at `graphs/eml-annotation-procedures.praat:1842` is confirmed repaired.

Two live routing defects remain:

**Pairwise-t report prints the adjustment method where the test name belongs** — `stats/eml-analysis.praat:308` reads `emlPairwiseT.method$`, which holds the *p-adjustment* name, not the test. Header degenerates to "Pairwise holm (holm adjustment)" and **never discloses whether Welch or Student ran.** Student and Welch runs produce identical headers with different p-values (0.0178 vs 0.0185). The dispatch is correct; only the label is wrong. The Wilcoxon (`:377`) and Scheffé (`~:440`) branches are labelled correctly. The wizard compounds it at `eml-wizard.praat:604`: plan text says "Pairwise t (BH)", report says "Pairwise bh (bh adjustment)."

**The user's adjustment choice is discarded when they click "Draw"** — `graphs/eml-annotation-procedures.praat:1842` reads `annotCorrectionMethod$`, whose sole assignment anywhere in the plugin is `graphs/eml-graphs-form.praat:907` → `"holm"`. `scripts/eml-pairwise.praat` sets six graph presets but there is no adjustment preset, so a user who selects Bonferroni, reads a Bonferroni-adjusted table, then clicks Draw gets **Holm**-adjusted Dunn brackets. The bracket label truthfully says "holm" — so the figure is internally consistent and contradicts the table the user just read, with nothing announcing the switch.

Latent (no current caller, but a trap for any new front-end): `emlRMPostHoc` (`stats/eml-analysis.praat:1294`) silently falls back to Holm for any unrecognised adjustment string, with no validation and no disclosure — unlike `emlDunnTest` and `emlPairwiseT`, which set `.error$`. `emlBridgeCorrelation` (`graphs/eml-annotation-procedures.praat:2161–2186`) repeats the C1/C2 misalignment pattern (two independent `@emlExtractColumn` calls, count-only guard) but has no callers in the shipped tree.

Dead parameters, accepted and silently ignored: `emlRunNormalityAnalysis.testType$` (`:832`), `emlRunRepeatedMeasuresAnalysis.subjectCol$` (`:1187`), `emlRunFriedmanAnalysis.subjectCol$` (`:1242`).

Asymmetries worth knowing but not defects: `scripts/eml-compare-kw.praat:64` hardcodes Dunn on + Holm with no dialog exposure, while the wizard's KW route offers all three. `scripts/eml-wizard.praat:405, 416` hardcode Welch (`.equalVar = 0`) with no override — statistically defensible, correctly reported, undisclosed in the dialog. `Theil–Sen` is defined at `stats/eml-inferential.praat:3259` but reachable from no front-end.

---

## 6. Convention disclosures Josh Gilbert needs

Without this table a naive R cross-check will report mismatches that are not defects.

| Quantity | EML convention | Note |
|---|---|---|
| Skewness | **G1 = `e1071` type 2** | NOT type 1. 1.7520 vs 1.5034 on the same data. |
| Kurtosis | **G2 EXCESS = type 2** | NOT type 1. 2.6583 vs 1.0950. |
| MAD | `emlMAD.result` scaled by 1.4826; `.rawMAD` unscaled | matches R default |
| Percentiles / quartiles | R type 7 | |
| Variance / SD / SEM | n − 1 | |
| CI | t-based, df = n − 1 | |
| z-score | sample SD | |
| Trimmed / winsorized means | match R / DescTools | |
| `emlPairwiseT` | `pool.sd = FALSE` (per-pair pooled SD) | **undocumented** |
| Spearman p | t-approximation always | matches **scipy**, not R's exact AS89 for small tie-free n — **undocumented** |
| Hedges *J* | approximation, 0.27% error at df = 4 | header currently overstates accuracy |
| Shapiro–Wilk | wrong at exactly **n = 6** | `stats/eml-core-descriptive.praat:704` gates `if .n >= 7`; AS R94 uses `n > 5`. Δp ≈ 2e-4; 5/40,000 samples flip a decision. Root cause proven by patching a copy. All other n agree with R to ~15 significant figures. |

---

## 7. Verified correct — the trustworthy core

These were differentially tested and matched R/scipy, and should not consume Josh's time:

`emlTTest` (pooled, Welch, paired) · `emlCohenD` (*d* itself) · `emlPearsonCorrelation` (r, t, df, p) · `emlLinearRegression` (all fields, stable to 1e8) · `emlCI` · `emlVariance` / `emlSD` / `emlSEM` · `emlSkewness` · `emlKurtosis` · `emlTukeyHSD` · `emlScheffe` · `emlPairwiseT` · `emlEpsilonSquared` · `emlOneWayAnova` at moderate magnitudes · `emlTwoWayAnova` balanced · `emlRankVector` · `emlKruskalWallis` (68 cases exact) · `emlDunnTest` (1164 pair-rows exact; method-string validation sets `.error$` — no silent fallback) · `emlBonferroni` / `emlHolm` / `emlBenjaminiHochberg` (0 mismatches, monotonicity correct) · `emlFriedmanTest` (25 cases exact) · `emlTheilSen` · `emlPercentile` / `emlQuartiles` · Spearman rho itself · the MW/WSR **normal-approximation** paths (correct R-style continuity correction and zero-dropping) · `emlExtractPairedColumns` (C1/C2 fix complete) · the M7 group-cap fix · no silent NA→0 substitution anywhere · group ordering in the graphs bridge · viewport assertion before both save sites · special-character sanitization · quartile / whisker / outlier / KDE drawing · t-based (not 1.96) CI in `emlDrawTimeSeriesCI` · the H3 grouped-scatter R² fix · 11 of 14 Praat idiom hazard classes.

---

## 8. Recommended fix order before the email goes out

**Tier 1 — must fix; these can put a wrong number in the paper.**
1. `Get all numbers in column:` rank substitution (`eml-extract.praat:921, 961–962`) + harden `emlValidateNumericColumn`.
2. Pearson/Spearman clobber (`eml-inferential.praat:447`, `eml-analysis.praat:656–664`).
3. Two-way ANOVA error term + balance/negative-SS guards (`eml-inferential.praat:2054`).
4. One-way ANOVA centered SS (`eml-inferential.praat:1891, 1906, 1908–1910`).
5. The `undefined`-fails-open guard class (Tukey 1718, Scheffé 3112, Dunn 2565/2573, one-way η², the two orchestrators that discard `error$`).
6. Rank-test ties + exact/normal threshold + both-tail truncation + one-tailed direction (`emlMannWhitneyU:648`, `emlWilcoxonSignedRank:939`, `eml_*ExactP:542/556/803/817`, `:657/734/955`), and correct the false comment claiming R parity.
7. `emlMeasureBarData` undefined guards (`eml-graph-procedures.praat:2662–2690`) — port from `emlDrawGroupedViolin`.
8. Stale `annotMatrixLabel$[]` (`eml-annotation-procedures.praat:1900/1902/2065/2067` + reset in `@emlClearAnnotations`).
9. Scatter reported-vs-drawn line (`eml-draw-procedures.praat:2062–2134`, `2296–2360`).

**Tier 2 — crashes that block the stress test.**
10. `@emlExtractMultipleGroups` (`eml-wizard.praat:2047`) + the 1-vs-4 argument call at `:2053`.
11. `emlDrawHistogram` `.nGroups` / `.hasGroups` (`eml-draw-procedures.praat:2671–2726`).
12. `@emlDrawViolin` arity (`eml-stats-demo.praat:245, 247`).
13. `eml-tutorial.praat:19` missing include — ship `tutorial/` or unregister the menu entry at `setup.praat:69`.
14. Column-existence validation in the three orchestrators that bypass it.
15. `sort#`-on-undefined at the 8 sites.

**Tier 3 — labelling and disclosure, needed for the paper's methods section.**
16. Pairwise-t header (`eml-analysis.praat:308`) and the wizard plan/report string mismatch.
17. Adjustment-choice loss on Draw (`eml-graphs-form.praat:907` needs a preset).
18. `emlFormatEffectLabel` R² thresholds; `emlFormatStars` α; `emlFormatStars(undefined)`; `emlFormatP` boundary; the Matrix-layout hardcoded `annotMatrixSig = 0`; error-bar SE/SD disclosure and clamp caps.
19. Shapiro–Wilk n = 6 gate; Hedges *J* header claim; Spearman/scipy and `pool.sd=FALSE` disclosures.
20. `emlCountGroups` case/whitespace normalisation; coercion warnings for `.5` / `30%` / `inf`.

**Tier 4 — housekeeping.**
21. Dead parameters (three); `emlRMPostHoc` validation; `emlBridgeCorrelation` (latent); `emlRunReliabilityAnalysis` stub — remove or document; `+=` at `eml-analysis.praat:790, 809, 845, 861` (works in 6.6.30, but the tracker's L1 "fixed" entry is stale).

---

*Audit artifacts retained under `/home/claude/audit/a1`–`a7`: harnesses, R and Python verification scripts, executed reproductions, the 1442-call-site alignment scan, and the patched-copy proof of the Shapiro–Wilk root cause. No plugin file was modified.*
