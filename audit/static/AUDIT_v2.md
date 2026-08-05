# EML Praat Tools — Pre-Stress-Test Audit, **v2 (adversarially reviewed)**

**Date:** 2 August 2026
**Supersedes:** `AUDIT_EML_Praat_Tools_non-LMM_2026-08-02.md` (v1, same date). v1 should not be circulated — it contains line-number errors, three refuted findings, several mischaracterised mechanisms, understated magnitudes, and one HIGH-severity false negative in its "verified correct" section.
**Scope:** the full stats + graphs surface **excluding** LMM (`stats/eml-lmm.praat` v0.8, `stats/eml-linalg.praat`, `stats/eml-optimizer.praat`, `scripts/eml-lmm.praat`, the wizard's mixed-model route, `@emlDrawLMMForest`) — tabled at 0.8 by decision.

**Method, v1:** seven parallel read-only audits, every finding executed in Praat 6.6.30 (barren, `--run`, unpiped), differentially tested against R 4.3.3 and scipy 1.17.1 / numpy 2.4.4 / statsmodels 0.14.6.

**Method, v2:** eight further agents whose mandate was to **disprove** v1. Each was told to default to REFUTED, to regenerate every number rather than trust v1's, to re-verify every line citation against the shipped file, to establish whether each defect is *reachable from a shipped front-end* rather than only from the direct procedure API, and to rate how plausible the triggering data is in voice science. Verdict vocabulary: CONFIRMED / CONFIRMED-BUT-OVERSTATED / CONFIRMED-BUT-UNREACHABLE / MISCHARACTERIZED / REFUTED / UNRESOLVED. No plugin file was modified in either pass.

---

## 0. What the adversarial pass changed

**Three v1 findings are refuted outright.** Scheffé's `if .se = 0` branch at `:3112` is a deliberate, correct guard — not a fail-open. Dunn at `:2565/:2573` is rank-based and structurally immune to the zero-variance trigger. `emlRunRepeatedMeasuresAnalysis:1187` "discards `error$`" is vacuous — there is no `error$` on that path to discard.

**Three are mischaracterised.** Two-way ANOVA: the Type III **effect** sums of squares are correct; only Total and Error are wrong, which is a narrower and differently-shaped defect than v1 described. The `floor`/`ceiling` in the exact rank-test DPs is **not** truncation — the tie-free null has integer support, so `floor`/`ceiling` on a half-integer statistic is *exact* CDF/SF evaluation, verified identical to `pwilcox`/`psignrank`. `emlFormatP`'s boundary rounding is cosmetic, not a decision defect.

**Several are unreachable from any shipped front-end** and belong in housekeeping, not Tier 1: catastrophic cancellation (needs mean/SD > 1e7 — no voice-science quantity is in that range), `emlFormatStars(undefined)` (Tukey, Dunn and Pearson all intercept upstream), column-not-found crashes (every menu populates its column fields from optionmenus over the real Table), the reliability stub (zero call sites), and the entire `sort#` inventory (which was also incomplete — 14 sites exist, not 8, and all 8 cited are unreachable).

**Several are worse than v1 said.** Spearman's anti-conservatism peaks at **11.97×**, not 2.6×. The one-tailed divergence is **~184,700×**, not 920×. The ungrouped histogram crash fires **in the shipped default configuration on completely clean data**. `emlMeasureBarData` is a hard crash, not a silent wrong figure. `annotCorrectionMethod$` being pinned to `holm` is worse than described.

**§7 does not survive.** The "verified correct" list — the section whose whole purpose is to tell Josh what *not* to spend time on — contains a HIGH-severity false negative. See §5.

**What is now stronger than v1 claimed:** the rank-test *statistics* are correct 470/470; both exact DPs reproduce `pwilcox`/`psignrank` exactly; the normal-approximation paths match R to 4.914e-11; `emlKruskalWallis` and `emlFriedmanTest` handle fully-tied data (p = 1) where R returns NaN; the 3802-comparison positional-argument scan and the 413-field GUI scan are clean.

---

## 1. Confidence scale

Each finding carries **C** (0–100) and **R** (realism).

- **C ≥ 95** — reproduced end-to-end through a shipped front-end, numbers regenerated independently in v2, line citations verified against the current file. Would require a Praat version difference to overturn.
- **C 85–94** — mechanism proven and reproduced, but reachability depends on a configuration I inferred rather than clicked, or the magnitude is data-dependent.
- **C 70–84** — mechanism proven by reading plus a targeted probe; not driven end-to-end.
- **C < 70** — plausible, not established. None are in Tier 1.

**R** = how plausible the triggering data is in voice science: **R-high** (ordinary data), **R-medium** (a real but uncommon shape), **R-low** (contrived).

---

## 2. Silently wrong numbers — confirmed

### 2.1 Rank substitution in group extraction — CRITICAL · **C 93 · R-high**
`stats/eml-extract.praat:921` (`eml_getGroupData`), `:961–962` (`eml_getGroupPairedData`).

`Get all numbers in column:` returns **alphabetical ranks** if *any* cell in that column fails full numeric parse. Ranks are computed per group sub-table, so only the affected group is corrupted: group A becomes 1–4 while B and C keep their real 20–36 values. The `<> undefined` filter at `:916` does not catch it, because `Get value:` on the same cell partially parses `14 Hz` to 14. F went 60 → 193.4 with an empty `error$`. R reproduces the poisoned output exactly, which proves the arithmetic is right and the *inputs* are wrong.

`emlValidateNumericColumn` cannot detect the trigger — it counts partial parses as numeric.

Blast radius: `emlTukeyHSD` 1677/1732/1735 · `emlOneWayAnova` 1879 · `emlKruskalWallis` 2300/2316 · `emlDunnTest` 2499/2515/2627/2630 · `emlPairwiseT` 2755/2758 · `emlPairwiseWilcoxon` 2902/2919/2922 · `emlScheffe` 3065 · `eml-analysis.praat` 68/71/145/148/213/216 · `eml-annotation-procedures.praat` 1880–2121, 2550–2967 · `eml-check-normality.praat:130` · `eml-wizard.praat:1843, 2053` · `eml-correlate.praat:112`.

*Why C is 93 and not 99:* the mechanism and the F-value are certain. The 7 points reflect that a trailing-unit cell (`14 Hz`) is the realistic trigger I demonstrated; how often that survives a user's own data hygiene is a judgement, not a measurement.

**Fix:** replace with the row-wise `Get value:` loop `emlExtractColumn` already uses correctly; harden `emlValidateNumericColumn` to reject partial parses.

### 2.2 European decimal comma — NEW · **C 99 · R-high**
`number("5,5")` returns **5**, not undefined. This is the worst shape a coercion bug can take: no error, no dropped row, no undefined — a plausible wrong number that passes every guard downstream, including the hardened one proposed in 2.1. Any collaborator on a European locale exporting from Excel hits it.

Confirmed neighbours: `number(".5")` = undefined (row silently dropped); `number("30%")` = **0.3**; `number("1/2")` = 1; `number("2 3")` = 2; `number("0x10")` = 16; `number("inf")` / `number("nan")` = undefined; `number(" 7 ")` = 7; `number("+3")` = 3; `number("-.25")` = undefined.

`emlCountGroups` (`stats/eml-extract.praat:842`, exact string equality at `:878`) makes `Control` / `control` / `Control ` three groups, and the descriptives table renders two visually identical rows. **C 99 · R-high.**

### 2.3 Pearson/Spearman global clobber — CRITICAL · **C 99 · R-high**
`stats/eml-inferential.praat:447`; orchestrated at `stats/eml-analysis.praat:657–665` (**not** 656–664); consumed at `graphs/eml-annotation-procedures.praat:3027, 3036, 3040, 3044–3049`. Reached from `scripts/eml-correlate.praat:64` ("Both") → `:98`.

Praat procedure outputs are durable globals overwritten on the next call to the same procedure. `emlSpearmanCorrelation` calls `@emlPearsonCorrelation` on the ranks; the report then reads the clobbered values. True r = 0.6825 / p = 0.3175 displayed as 0.400 / 0.600. **v2 addition: the CSV export is corrupted identically** — so the wrong number leaves the session in a file.

**Fix:** copy `emlPearsonCorrelation.*` to caller-scope locals immediately after the call, before Spearman runs.

### 2.4 Missing `else` on the Spearman report branch — **C 96 · R-high**
Same cluster as 2.3, independently confirmed.

### 2.5 Two-way ANOVA error term — MISCHARACTERIZED, still CRITICAL · **C 96 · R-medium**
`stats/eml-inferential.praat:2054`.

v1 said "the wrong error term for every unbalanced design." Correct statement: Praat's `Report two-way anova:` computes **Type III effect SS correctly**; SS_Error is obtained by subtraction from an unweighted-means SS_Total, so **Total and Error are wrong** and every F and p inherits it. "Every unbalanced design" is overstated — the magnitude scales with the imbalance.

Reproduced: MSE 11.5× too large on one 2×2 (interaction p 0.0131 → 0.3636); 4.89× too *small* on a 2×3 (anti-conservative: p 1.05e-4 → 2.99e-10). At cell sizes 5/5/5/2 it emits **negative Error SS (−33.38), negative F, partial η² = −4.675, and an empty `error$`**. No balance check, no negative-SS check, no SS-type statement in the header.

**Fix:** compute SS_Error directly from within-cell deviations; add a balance check and a negative-SS guard; state the SS type.

### 2.6 ANOVA line parser reads the wrong factor — **C 97 · R-medium**
`stats/eml-inferential.praat:~1390`, `eml_parseAnovaLine`, uses `extractLine$`, which returns the **first** matching line.

v1's trigger was right but narrower than stated: it fires when **factor 2's name is a substring of factor 1's** (`Cond` inside `Condition`), shifting every parsed field one column and emitting a p-value of **283.67**. v2 found a second variant: a factor named `Error` or `Total` collides with the table's own summary rows.

### 2.7 Rank tests — CONFIRMED, but three of five sub-claims restated · **C 97 (mechanism) · R-medium**

**Ties under the exact null — CONFIRMED.** `emlMannWhitneyU:648` applies the exact tie-free null under ties. Matches neither R (0.05191) nor scipy exact (0.0732); EML gives 0.0479798. **Worst observed divergence 0.163, not 0.082.** `emlWilcoxonSignedRank:939` shares the defect class: EML 0.0029297 vs R 0.00703.

Decision flips, regenerated: MWU **0 flips at α = .05**, 1 at α = .01 (v1 claimed 2/2). WSR **7 flips at α = .05, 0 at α = .01** (v1 claimed 1 at .01). The net error is **bidirectional** — 7 anti-conservative against 9 conservative flips across the corpus — which v1 reported one-sidedly.

**`floor`/`ceiling` — MISCHARACTERIZED, withdrawn as a defect.** `eml_mannWhitneyExactP:542, 556` and `eml_wilcoxonExactP:803, 817`: the tie-free null has integer support, so `floor` on the left tail and `ceiling` on the right is *exact* CDF/SF evaluation of a half-integer statistic, not truncation. Both DPs reproduce `pwilcox`/`psignrank` **exactly**. The anti-conservatism is real but is concentrated in the half-integer-statistic subset — i.e. it is a *consequence of* the ties defect above, not a separate one.

**Exact/normal threshold — CONFIRMED but trivial.** `emlMannWhitneyU:648` uses `n1 + n2 < 50` where R uses `n1 < 50 && n2 < 50`. 200/200 tie-free cases took the normal path where R took exact. Consequence in p-values is small. **`emlWilcoxonSignedRank:939` is NOT a defect — its threshold matches R** (`n < 50` post-zero-exclusion). v1 was wrong to list it. The **inline comment at `:649` falsely claiming "matches R `wilcox.test` threshold" is still a defect** — it will mislead Josh. **C 99.**

**One-tailed direction — CONFIRMED, magnitude 200× worse than stated.** `:657`, `:734`, `:955` compute the one-tailed p "in the direction of the observed effect" — always the smaller tail, direction ignored. **EML vs R diverges by ~184,700×**, not 920×. Doubles the nominal Type I error. Not reachable from any shipped front-end (every `tails` argument in the shipped surface is the literal 2), but it is a live trap for the direct procedure API — and `.tails` is **unvalidated**, so a typo silently selects a branch. **C 98 · R-low from the GUI, R-high for anyone scripting against the library.**

Propagates into `emlRankBiserialR:1073`, `emlMatchedPairsR:1150`, `emlPairwiseWilcoxon:2865` — one Bonferroni-adjusted pair reads 0.0476 (significant) where R gives 0.0577 (not).

### 2.8 Correlation p-value edge cases · **C 96 · R-medium**
- `emlPearsonCorrelation:375` (**not** 372) hardcodes `p = 0` when r² ≥ 1, leaving `t = undefined`. Reached through Spearman `:418`: n = 3 perfect monotone gives p = 0 where R gives 0.3333. **The report renders it as `p < .001`** — a fabricated significant result from a degenerate computation.
- `emlSpearmanCorrelation:418` always uses the t-approximation; R uses exact AS89 for small tie-free n. **Anti-conservative by up to 11.97×**, not 2.6×. Matches scipy, not R, and this is undocumented. **C 97.**

---

## 3. `undefined` guards that fail open

Praat 6.6.30 evaluates `u > 0`, `u < 0`, `u <= 0`, `u >= 0` and `u = 0` **all FALSE**; `u <> 0` is 1; `(u > 0) or (u <= 0)` is **0**. The law of excluded middle fails. Every guard of the form `if x > 0 … else` takes the `else` branch on a failed computation.

**Confirmed:**

| Site | Effect | C | R |
|---|---|---|---|
| `emlTukeyHSD:1718` (`se` at 1715, `q` at 1717) | zero within-group variance → `q = undefined` → `.p = 1` for **every** pair. A 900-unit separation reads "definitively no effect." R gives p adj = 0. **v2 addition: `--undefined--` is rendered into the figure caption.** | 97 | medium |
| `emlOneWayAnova`, zero within-variance | **η² = 1.0000** with F/p undefined and empty `error$` | 96 | medium |
| `emlRunTwoGroupAnalysis` (`stats/eml-analysis.praat:46–107`) | never checks the engine's `error$`; `emlTTest` sets it correctly, the orchestrator discards it and prints "Magnitude negligible effect" for perfectly separated groups | 95 | medium |
| `emlPearsonCorrelation:372–375` | `r² ≥ 1` → `t = undefined`, `p = 0`, rendered `p < .001` | 96 | medium |
| zero-variance kurtosis, `stats/eml-core-descriptive.praat:287–289` | returns **−13.5** at n = 4; R returns NaN | 95 | low |
| Cohen's *d* silently dropped for n = 1 groups — NEW | 92 | low |

**Refuted:**

- **Scheffé `:3112` — REFUTED.** There is a deliberate `if .se = 0` branch. It is not a fail-open. v1 was wrong.
- **Dunn `:2565, 2573` — REFUTED.** Rank-based; structurally immune to the zero-variance trigger. v1 was wrong.
- **`emlRunRepeatedMeasuresAnalysis:1187` — REFUTED as vacuous.** No `error$` exists on that path to discard. (The *real* RM defect is worse and is in §5.)

**Fix pattern:** replace every `if x > 0` / `if p >= alpha` guard on a possibly-undefined quantity with an explicit `if x <> undefined` outer test.

---

## 4. The graphs layer

### 4.1 `emlCheckNumericColumn` samples the first five rows — NEW, and the single highest-leverage fix · **C 98 · R-high**
`graphs/eml-graph-procedures.praat:2062–2081`. `.checkRows = min (.nRows, 5)` at `:2069`; `.isNumeric = 1` if **any** of those five parses (2071–2079). Ten call sites.

This is the upstream cause of most of the graphs-crash class below. A column whose first five rows are clean passes; row 6 onward is unguarded. **Fixing this one procedure neutralises most of §4.2 without touching the drawing procedures.**

### 4.2 Aborting draw procedures · **C 96 · R-high**
v1 said "seven procedures, six abort loudly, one does not." Corrected: **five** abort, and v1 named four. The fifth is `emlDrawBarChart`.

| Procedure | Crash site |
|---|---|
| `emlDrawTimeSeries` (def `:561`) | reads 596–598 / 610–613, seeds 606–609, aborts 676 / 697 |
| `emlDrawSpaghettiPlot` (def `:1094`) | `number()` at 1147, seeds 1157–1158, aborts 1246 / 1323 |
| `emlDrawViolinPlot` | 1660–1674, 1747–1758 |
| `emlDrawBoxPlot` (def `:2446`) | read loop 2474–2476; the `sort#` abort is actually in `@emlPercentile` at `stats/eml-core-descriptive.praat:149` — v1 mis-located it |
| `emlDrawBarChart` (**1504–1622**) — v1 missed this entirely | `Paint rectangle` at **:1570** |

**Row-1 axis seeding never recovers** — if row 1 is undefined, the min/max seeds are poisoned for the whole figure even if every later row is clean. **NEW · C 95.**

Correct siblings already in the tree: `emlDrawGroupedViolin` (def **:3019**, guards **:3061** / **:3106**), `emlDrawGroupedBoxPlot` (def 3279, guards 3315/3357), `emlDrawScatterPlot` (guard 1850), `emlDrawTimeSeriesCI` (guards 821/1016).

Liveness: `graphs/eml-graphs-form.praat:5376–5421` (**not** 5370–5425) dispatches the user's Table with **zero row filters** — no `Extract rows where`, no `<> undefined` — before dispatch.

### 4.3 `emlMeasureBarData` — v1 understated: it is a HARD CRASH · **C 98 · R-high**
`graphs/eml-graph-procedures.praat`: proc **2641**, accumulate loop **2663–2684**, compute loop **2687–2713**. v1's cited range (2662–2690) truncates before the mechanism.

Not one undefined guard. `count` is incremented for the undefined row, so the denominator is wrong; mean/SD go undefined; and because `if .var > 0` (`:2694` SE, `:2703` SD) is FALSE for undefined, `emlBarData_error[.g]` keeps its `0` initialisation (2691/2700) → **a zero-length error bar for a group with real variance**. The drawing layer reports n = 4 / mean = undefined / sd = 0 where the stats layer reports n = 3 / mean = 12 on the same column. v2 reproduced these numbers verbatim — **and then found the run aborts** rather than drawing the wrong figure. `.errorMode` semantics at `:2629` (0 = none / 1 = SE / 2 = SD / 3 = custom); visible-range fold at 2722/2726.

### 4.4 Ungrouped histogram aborts on clean data, in the shipped default · **C 98 · R-high — the most embarrassing single defect**
`graphs/eml-draw-procedures.praat`: `.hasGroups = 0` at **:2672**, `.nGroups = 1` at **:2673**, guard `if .nGroups > 0` at **:2713**, crash `.grp$ = Get value: .i, .groupCol$` at **:2714**, dead `else` 2721–2723.

The guard tests `.nGroups` where it means `.hasGroups`. `.nGroups` initialises to 1 and is never 0, so `Get value: .i, ""` runs unconditionally. Single call site `graphs/eml-graphs-form.praat:5408`, fed by 3976–3979; the "Use group column" boolean at `:3995` **defaults unchecked**, and `histGroupCol$ = ""` at 4146–4147. So: **the default configuration, on completely clean data, aborts.**

### 4.5 Damage matrix — NEW
**6 of 14 graph types are unusable in at least one shipped default configuration.** (Detail in the fix order, §7.)

---

## 5. §7 of v1 does not survive — the false negative

v1 asserted **"no silent NA→0 substitution anywhere."** This is false, and the counterexample is HIGH severity.

### `emlRMPostHoc` renders an undefined raw p as an adjusted p of 0 · **C 98 · R-medium**

`stats/eml-analysis.praat:1307–1313` writes `.rawP#[.pairIdx] = emlTTestPaired.p` with **no `.error$` check**. Every sibling does check: `emlPairwiseT:2766–2770`, `emlDunnTest:2565–2579`, pairwise-Wilcoxon `:2928–2936` all substitute `rawP = 1`. `emlTTestPaired:178` leaves `.p` undefined and sets `.error$` on zero variance.

Shipped orchestrator `@emlRunRepeatedMeasuresAnalysis: t, "", "c1|c2|c3", 1, "holm"` on a 6-subject × 3-condition table with `c2 = c1 + 2` exactly produces, verbatim:

```
  Post-hoc pairwise (parametric, holm-adjusted):
    c1 vs c2: p(raw) = --undefined--, p(adj) = 0
    c1 vs c3: p(raw) = 0.0438, p(adj) = 0.0875
    c2 vs c3: p(raw) = 0.1136, p(adj) = 0.1136
```

`emlHolm` on `{0.01, undefined, 0.5}` returns `{0.03, 0.03, 0.5}` where R gives `{0.02, NA, 0.5}`. Reachable only via `scripts/eml-wizard.praat:977` / `:987` — the sole RM front-end — with Holm as the default.

**Related, NEW · C 95:** the adjustment procedures count undefined elements in `k`. `emlBonferroni:1211` uses `.k = size(.pValues#)`; `emlHolm:1254` and `emlBenjaminiHochberg:1315` follow. R uses the **non-NA** count. Every adjusted p in a family containing one failed test is inflated.

### Also withdrawn or qualified from v1 §7
- `emlEpsilonSquared:2202` computes `.result = .h / (.n - 1)` **uncapped** — can exceed 1. **C 95.**
- Hedges *J* (`emlCohenD:258`, `J = 1 - 3/(4*.df - 1)`) is **1.28% off at df = 2**, not 0.27% at df = 4. **C 99.**
- The untested remainder of §7 carries **C 72**. It was assembled from the v1 agents' positive results, and v2 only spot-checked it.

### What §7 *did* survive, at raised confidence
`emlKruskalWallis` and `emlFriedmanTest` handle fully-tied data (p = 1) where R returns **NaN** — EML is better here (**C 97**). The MW/WSR normal-approximation paths match R to **4.914e-11** (**C 99**). Both exact DPs reproduce `pwilcox` / `psignrank` exactly (**C 99**). All rank statistics correct **470/470** (**C 99**). The positional-argument scan (3802 comparisons) and GUI-field scan (413 fields) are clean (**C 97**).

---

## 6. Figures that state the wrong statistic

| # | Finding | C | R |
|---|---|---|---|
| 6.1 | **Stale `annotMatrixLabel$[]` — CRITICAL.** `graphs/eml-annotation-procedures.praat:1900, 1902` (KW/Dunn) and `2065, 2067` (ANOVA/Tukey) read it; all eight writers (1717, 1718, 1782, 1783, 1859, 1942, 2024, 2106) are inside `if .useMatrix` blocks; `@emlClearAnnotations` (**284–300**, not 284–301) resets 14 globals but **not this one**. Fresh session + Annotate + k ≥ 3 + effect sizes ON → hard abort. After any prior Matrix run → **stale labels pair the right p with the wrong pair's effect size** (observed: bracket over groups 1–2 labelled d = 4.50 when true d = −1.64, i.e. wrong sign *and* wrong magnitude). `@emlMeasureMatrixLayout` (1114–1148) also truncates these labels in place with an ellipsis. **One-line fix in `emlClearAnnotations`.** | 98 | high |
| 6.2 | **Scatter: reported line ≠ drawn line — CRITICAL.** `graphs/eml-draw-procedures.praat` **reports** OLS (2062–2068), **draws** Theil–Sen (2074–2080, drawn 2110), and prints the Theil–Sen equation unlabelled at **2122–2133** (not 2118–2134). The `"Theil-Sen:"` disclosure at **:2113** is gated `if scatterAnalysisType < 2` — suppressed exactly where needed. Observed: reported `y = 3.0855x − 3.9400, R² = 0.7500` against drawn `y = 2.0143x − 0.0786`. Grouped branch identical (report 2293–2299, fit 2304–2334, disclosure suppressed 2360). | 97 | high |
| 6.3 | **`r_squared` → Cohen's *d* thresholds.** `emlFormatEffectLabel` (`stats/eml-output.praat:315–365`, endproc **365** not 370) recognises `d, r, w, V, eta_squared, omega_squared, epsilon2, epsilon_squared`. `graphs/eml-annotation-procedures.praat:3204` passes `"r_squared"`; the else-branch (348–353) applies 0.2/0.5/0.8. R² = 0.15 renders "negligible effect." | 99 | high |
| 6.4 | **`emlFormatStars` ignores `annotAlpha`.** `graphs/eml-annotation-procedures.praat:309–319` hardcodes 0.001/0.01/0.05; bracket *inclusion* uses `annotAlpha`. α = 0.01 with p = 0.03 draws a `*`; α = 0.10 with p = 0.07 draws a bracket labelled `n.s.` | 96 | high |
| 6.5 | **Hardcoded `annotMatrixSig = 0`.** `graphs/eml-annotation-procedures.praat:2108–2116` (not 2110–2113) — non-significant omnibus in Matrix layout shows the real Tukey adjusted p but hardcodes 0 at `:2113`, painting the cell grey under a "p < alpha" legend. Reachability proved in R (k = 6, n = 4: omnibus p = 0.0529, Tukey pair p = 0.0322). The KW/Dunn branch at **:1946** writes the literal `"n.s."` instead — the two branches are mutually inconsistent. | 95 | medium |
| 6.6 | **Zero within-group variance → every Tukey p = 1.000 and `--undefined--` in the figure caption.** The §3 Tukey defect, seen from the figure side. | 97 | medium |
| 6.7 | **Bar-chart error bars: no SE/SD/custom disclosure anywhere** (a √n ambiguity). `graphs/eml-draw-procedures.praat:1504–1622`, error-bar block **1577–1596**, clamps 1584–1586 / 1589–1591, stem 1593, caps 1594/1595, `.barTop = min(mean, .yMax)` at `:1567`. Clamped bars get a **normal terminal cap**, so truncation is invisible. *Two defects, different classes, fused in v1 — split here.* The clamping half is conditional on the user setting manual axis limits (`graphs/eml-graphs-form.praat:2576–2577`), so **C 88** for that half; the missing disclosure is unconditional, **C 99**. v1's citation of `:1573` was **wrong** — that line is `Colour: emlSetColorPalette.line$[.colorIdx]`. | 99 / 88 | high / medium |
| 6.8 | **`emlFormatP` boundary — DOWNGRADED to cosmetic.** `stats/eml-output.praat:199–224` prints `p = .050` for 0.04999, 0.05000 and 0.05040 alike, but decisions use the unrounded value throughout, so no decision is wrong. It is a presentation inconsistency, not a defect. | 95 | — |
| 6.9 | **`emlFormatStars(undefined)` — CONFIRMED-BUT-UNREACHABLE.** Returns `"n.s."` with the suppression branch never firing. Tukey, Dunn and Pearson all intercept upstream, so no shipped path delivers an undefined p here. Latent trap only. | 90 | low |

---

## 7. Routing, labelling, and hard crashes

| # | Finding | C | R |
|---|---|---|---|
| 7.1 | **`@emlExtractMultipleGroups` does not exist anywhere in the plugin** (removed at `eml-extract` v1.1 — see the header comment at `stats/eml-extract.praat:25`). Called at `scripts/eml-wizard.praat:2047`, reached from Describe → "By group" (`:1355`). `:2053` also calls `@eml_getGroupData: .g` with 1 argument against the 4-parameter definition at `stats/eml-extract.praat:912` — masked by the first error. **NEW: `dev/tests/eml-integration-test.praat:176–179` is broken by the same deletion**, so the plugin's own integration suite cannot run. | 97 | high |
| 7.2 | **`@emlDrawViolin` arity.** `scripts/eml-stats-demo.praat:245–246, 247–248` (`...`-continued) pass 6 arguments; the definition at `graphs/eml-graph-procedures.praat:1414` takes 7 (missing argument is `.width`) → `Error: Empty formula.` Aborts panel 1's first violin, so **no figure draws at all**; the info-window statistics for all three panels print correctly first, which makes it look like a drawing-only problem. Root-causes the previously-logged §G "Empty formula" item. | 96 | high |
| 7.3 | **`scripts/eml-tutorial.praat:19`** — `include ../tutorial/eml-demo-procedures.praat`; **the `tutorial/` directory does not ship** (confirmed absent from MANIFEST). Parse-time failure. Registered on the menu at `setup.praat:69`. The ~105 undefined-procedure hits reported for this file are all downstream of this one include. | 99 | high |
| 7.4 | **Pairwise-t header prints the adjustment method where the test name belongs.** `stats/eml-analysis.praat:309` (not 308) reads `emlPairwiseT.method$`, which is assigned from the *adjustment* argument at `stats/eml-inferential.praat:2691` and never from the test. Header degenerates to "Pairwise holm (holm adjustment)" and **never discloses whether Welch or Student ran** — identical headers, different p (0.0178 vs 0.0185). Dispatch is correct; only the label is wrong. Wilcoxon (`:377`) and Scheffé (`~:440`) are labelled correctly. Compounded at `scripts/eml-wizard.praat:604`: plan text "Pairwise t (BH)", report "Pairwise bh (bh adjustment)." | 97 | high |
| 7.5 | **The user's adjustment choice is discarded on Draw.** `graphs/eml-annotation-procedures.praat:1842` reads `annotCorrectionMethod$`, whose **sole assignment anywhere in the plugin** is `graphs/eml-graphs-form.praat:907` (inside the per-call reset block ~888–908 of `emlGraphsWorkflow`, def `:742`) → `"holm"`. `scripts/eml-pairwise.praat:99` sets six graph presets, none for adjustment. A user who selects Bonferroni, reads a Bonferroni-adjusted table, then clicks Draw gets **Holm** brackets. The label truthfully says "holm," so the figure is internally consistent and silently contradicts the table just read. **NEW: `@emlBridgeGroupComparison` (def `:1641`, 9 params) aborts outright if `annotCorrectionMethod$` is unset** — so a front-end that doesn't route through `emlGraphsWorkflow` crashes rather than defaulting. | 95 | high |
| 7.6 | **v1 mislocated the H2 repair.** v1 §5 called `:1842` both "confirmed repaired" and the seat of the live defect above — self-contradictory. The true H2 repair site is **`scripts/eml-compare-kw.praat:64`**. | 96 | — |
| 7.7 | **Report layer prints "Method: exact" unconditionally** with a wrong "(n < 50)" gloss — `graphs/eml-annotation-procedures.praat`, `emlReportTwoGroupComparison` (def 2346), ~2440–2450. It says "exact" even when the normal approximation ran. **NEW.** | 96 | high |
| 7.8 | **`emlRMPostHoc` silent Holm fallback.** `stats/eml-analysis.praat:1294` — `if bonferroni / elsif bh / else @emlHolm`, no validation, and **the header prints the requested string**, so an unrecognised adjustment is actively mislabelled rather than merely defaulted. v1 called this "latent"; it is live via the wizard's RM route. | 95 | medium |
| 7.9 | **Dead parameters**, accepted and silently ignored: `emlRunNormalityAnalysis.testType$` (`stats/eml-analysis.praat:832`), `emlRunRepeatedMeasuresAnalysis.subjectCol$` (`:1187`), `emlRunFriedmanAnalysis.subjectCol$` (`:1242`). | 99 | high |
| 7.10 | **`emlRunReliabilityAnalysis` (`stats/eml-analysis.praat:920`) is a stub** — "Not yet implemented." **Zero call sites**, so unreachable. Housekeeping, not a crash. | 95 | low |
| 7.11 | **Column-not-found crashes — CONFIRMED-BUT-UNREACHABLE.** `stats/eml-analysis.praat:787, 843`; `stats/eml-extract.praat:916`. Every shipped menu populates its column fields from optionmenus built over the real Table, so a bad name cannot be typed. Additionally, `emlValidateNumericColumn` has **zero shipped call sites**, which makes v1's "bypasses the existing validator" claim vacuous. | 92 | low |
| 7.12 | **`sort#` inventory — WITHDRAWN.** v1 listed 8 sites; **14 exist**, and all 8 cited are unreachable given upstream guards. The one live `sort#` abort is inside `@emlPercentile` (`stats/eml-core-descriptive.praat:149`) reached from `emlDrawBoxPlot` — already covered at 4.2. | 90 | low |
| 7.13 | **Catastrophic cancellation — CONFIRMED-BUT-UNREACHABLE.** `stats/eml-inferential.praat:1891, 1906, 1908–1910` use naive `Σx² − (Σx)²/n`; `emlTukeyHSD:1684–1685` (not 1650) already uses the centered form. Real, but requires mean/SD > 1e7 — **no voice-science quantity is in that range.** Fix it for hygiene, not for the paper. | 94 | low |
| 7.14 | Asymmetries, not defects: `scripts/eml-compare-kw.praat:64` hardcodes Dunn + Holm with no dialog exposure while the wizard's KW route offers all three; `scripts/eml-wizard.praat:405, 416` hardcode Welch with no override (statistically defensible, correctly reported, undisclosed in the dialog); `emlTheilSen` is defined at `stats/eml-inferential.praat:3259` but reachable from no front-end; `emlBridgeCorrelation` (`graphs/eml-annotation-procedures.praat:2161–2186`) repeats the C1/C2 misalignment pattern but has zero callers. | 93 | — |

---

## 8. Convention disclosures Josh Gilbert needs — **the whole table survived, C 97**

Without this a naive R cross-check will report mismatches that are not defects.

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
| Spearman p | t-approximation always | matches **scipy**, not R's exact AS89 for small tie-free n — **undocumented**, and anti-conservative by up to **11.97×** |
| Hedges *J* | approximation, **1.28% error at df = 2** | header currently overstates accuracy |
| Shapiro–Wilk | wrong at exactly **n = 6** | `stats/eml-core-descriptive.praat:704` gates `if .n >= 7`; AS R94 uses `n > 5`. Δp ≈ 2e-4; 5/40,000 samples flip a decision. Root cause proven by patching a copy. All other n agree with R to ~15 significant figures. |
| KW / Friedman under complete ties | EML returns **p = 1**; R returns **NaN** | EML is better; disclose so it isn't logged as a mismatch |
| MW / WSR normal-approximation paths | match R to **4.914e-11** | continuity correction and zero-dropping both R-style |

---

## 9. Revised fix order

Re-prioritised on the v2 evidence. **Bold** = moved since v1.

### Tier 1 — can put a wrong number in the paper
1. **`emlRMPostHoc` `p(adj) = 0` from an undefined raw p** (`stats/eml-analysis.praat:1307–1313`) — add the `.error$` check every sibling already has. *Moved up from v1 Tier 4.* **C 98**
2. `Get all numbers in column:` rank substitution (`stats/eml-extract.praat:921, 961–962`) + harden `emlValidateNumericColumn` (and give it call sites). **C 93**
3. Pearson/Spearman clobber (`stats/eml-inferential.praat:447`, `stats/eml-analysis.praat:657–665`) — report **and CSV**. **C 99**
4. **`emlCheckNumericColumn` 5-row sample** (`graphs/eml-graph-procedures.praat:2069`) — one procedure; neutralises most of the graphs-crash class. *New, straight into Tier 1.* **C 98**
5. The `undefined`-fails-open guard class: Tukey `:1718`, one-way η², `emlRunTwoGroupAnalysis` discarding `error$`, `emlPearsonCorrelation:375`. **Drop Scheffé and Dunn — refuted.** **C 95–97**
6. **Zero within-group variance → every Tukey p = 1.000 with `--undefined--` in the caption.** *Was folded into item 5 in v1; it deserves its own line because the failure direction is maximally dangerous.* **C 97**
7. Two-way ANOVA: SS_Error from within-cell deviations + balance and negative-SS guards + SS-type in the header (`stats/eml-inferential.praat:2054`). *Reframed — effect SS are already correct.* **C 96**
8. Rank-test ties under the exact null (`emlMannWhitneyU:648`, `emlWilcoxonSignedRank:939`); the `n1+n2 < 50` threshold **and the false comment at `:649`**; `.tails` validation and the one-tailed direction at `:657/734/955`. **Drop the `floor`/`ceiling` item — it is exact, not truncating. Drop the WSR threshold — it matches R.** **C 97–99**
9. **Adjustment `k` counts undefined elements** (`emlBonferroni:1211`, `emlHolm:1254`, `emlBenjaminiHochberg:1315`) — use R's non-NA count. *New.* **C 95**
10. **`annotMatrixLabel$[]` reset in `@emlClearAnnotations:284–300`** — one line, kills both the crash and the wrong-sign-*d* mode. *Moved up: highest value-per-line-changed in the plugin.* **C 98**
11. Scatter reported-vs-drawn line (`graphs/eml-draw-procedures.praat:2062–2133`, `2293–2360`) — and ungate the disclosure at `:2113`. **C 97**
12. `emlMeasureBarData` undefined guards (`graphs/eml-graph-procedures.praat:2663–2713`) — port from `emlDrawGroupedViolin`. **C 98**

### Tier 2 — crashes that block the stress test
13. **`emlDrawHistogram` `.nGroups` / `.hasGroups`** (`graphs/eml-draw-procedures.praat:2672–2723`) — *moved up: the shipped default crashes on clean data.* **C 98**
14. `@emlExtractMultipleGroups` (`scripts/eml-wizard.praat:2047`) + the 1-vs-4 argument call at `:2053` + **`dev/tests/eml-integration-test.praat:176–179`**. **C 97**
15. `@emlDrawViolin` arity (`scripts/eml-stats-demo.praat:245, 247`). **C 96**
16. `scripts/eml-tutorial.praat:19` — ship `tutorial/` or unregister `setup.praat:69`. **C 99**
17. `emlDrawBarChart` (`graphs/eml-draw-procedures.praat:1570`) and **row-1 axis seeding** in `emlDrawTimeSeries` / `emlDrawSpaghettiPlot` — mostly absorbed by item 4. **C 95–96**
18. `@emlBridgeGroupComparison` aborting on unset `annotCorrectionMethod$` (`graphs/eml-annotation-procedures.praat:1641, 1842`). **C 95**

### Tier 3 — labelling and disclosure, needed for the methods section
19. `emlFormatEffectLabel` R² thresholds (`stats/eml-output.praat:348–353` / call at `graphs/eml-annotation-procedures.praat:3204`). **C 99**
20. Pairwise-t header (`stats/eml-analysis.praat:309`; root cause `stats/eml-inferential.praat:2691`) + the wizard plan/report mismatch (`scripts/eml-wizard.praat:604`). **C 97**
21. Adjustment-choice loss on Draw (`graphs/eml-graphs-form.praat:907` needs a preset; `scripts/eml-pairwise.praat:99`). **C 95**
22. `emlFormatStars` α (`:309–319`); hardcoded `annotMatrixSig = 0` (`:2113`) and the KW/Dunn `"n.s."` inconsistency (`:1946`); **"Method: exact" printed unconditionally** (`~2440–2450`). **C 95–96**
23. Error-bar SE/SD/custom disclosure (unconditional, **C 99**); clamp caps (conditional on manual axis limits, **C 88**).
24. `emlRMPostHoc` adjustment validation (`stats/eml-analysis.praat:1294`) — stop printing the requested string when a different method ran. **C 95**
25. `emlEpsilonSquared` cap at 1 (`stats/eml-inferential.praat:2202`); Hedges *J* header claim (1.28% at df = 2); Shapiro–Wilk n = 6 gate (`stats/eml-core-descriptive.praat:704`); Spearman/scipy and `pool.sd=FALSE` disclosures. **C 95–99**
26. `emlCountGroups` case/whitespace normalisation (`stats/eml-extract.praat:842, 878`); **coercion warnings, with `number("5,5") = 5` first** — the European decimal comma is the only coercion hazard that produces a plausible wrong number rather than a dropped row. **C 99**

### Tier 4 — housekeeping (demoted; none of these can reach the paper)
27. **Catastrophic cancellation** (`stats/eml-inferential.praat:1891–1910`) — *demoted from Tier 1; unreachable at voice-science magnitudes.*
28. **`sort#` inventory** — *demoted; incomplete and unreachable.*
29. **Column-existence validation** (`stats/eml-analysis.praat:787, 843`) — *demoted; unreachable from the menus.*
30. **`emlFormatP` boundary** — *demoted to cosmetic.*
31. **`emlFormatStars(undefined)`** — *demoted; latent trap only.*
32. Dead parameters (three); `emlBridgeCorrelation` (zero callers); `emlRunReliabilityAnalysis` stub — remove or document; `+=` at `stats/eml-analysis.praat:790, 809, 845, 861` (works in 6.6.30; the tracker's L1 "fixed" entry is stale); zero-variance kurtosis −13.5; Cohen's *d* dropped at n = 1.

---

## 10. What I would still not bet on

- **§7 of v1, minus the corrections above, carries C 72.** It was assembled from the first pass's positive results and only spot-checked in v2. If Josh's stress test is going to be adversarial, that list should not be treated as a no-look zone.
- The **damage matrix (4.5)** — "6 of 14 graph types unusable in at least one shipped default" — is **C 85**. It was established by driving the procedures, not by clicking every combination in the form.
- **Realism ratings are judgements, not measurements.** Where a defect is marked R-low, that is my read of voice-science data shapes, and it is the class of claim most likely to be wrong.

---

*v1 artifacts under `/home/claude/audit/a1`–`a7`; v2 refutation artifacts under `/home/claude/refute/r1`–`r8` — harnesses, R and Python verification scripts, full-enumeration conditional-permutation nulls, executed reproductions, the 3802-comparison alignment scan, and the patched-copy proof of the Shapiro–Wilk root cause. No plugin file was modified in either pass.*
