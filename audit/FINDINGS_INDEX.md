# Findings index — EML Praat Tools GUI drive audit

81 findings (D1–D81) extracted from `DRIVE_FINDINGS_2026-08-04.md`. Each row
links to the line where the finding is first stated. The **Revisits** column
lists line numbers where the finding was later reconfirmed, revised, scoped
down, resolved, or reopened — several findings changed severity after further
evidence, so read the revisits before acting on a row.

Classes: ACCURACY (wrong number or wrong test reported), CLARITY (right number,
unusable or ambiguous presentation), GRAPHING (figure defects), PACKAGING
(export schema, filenames, install layout), NOT A DEFECT (investigated and
dismissed).

| ID | Class | Severity | First stated | Summary | Revisits (line) |
|----|-------|----------|--------------|---------|-----------------|
| D1 | CLARITY  | low  | [L107](DRIVE_FINDINGS_2026-08-04.md#L107) | `Try:` line paraphrases the Wizard's labels | 274, 382 |
| D2 | NOT A DEFECT  | —  | [L133](DRIVE_FINDINGS_2026-08-04.md#L133) | dismissed Pause windows persist in the X window list | — |
| D3 | CLARITY  | low  | [L293](DRIVE_FINDINGS_2026-08-04.md#L293) | only type 6 states what the data demonstrate | 372 |
| D4 | CLARITY  | medium  | [L479](DRIVE_FINDINGS_2026-08-04.md#L479) | The report line reads `Kurtosis`, but the value is excess kurtosis (normal = 0, not 3). The plugin's own `emlDescribe.summary$` in `stats/eml-core-des | — |
| D5 | CLARITY  | low  | [L488](DRIVE_FINDINGS_2026-08-04.md#L488) | No estimator conventions are disclosed anywhere | — |
| D6 | CLARITY  | medium  | [L497](DRIVE_FINDINGS_2026-08-04.md#L497) | Identifiers are underscore-stripped for display: `demo_normality` → `demo normality`, `F0_Hz` → `F0 Hz` (`eml-describe-table.praat:114–115`). Undersco | 634, 781, 973, 1070 |
| D7 | PACKAGING  | low  | [L508](DRIVE_FINDINGS_2026-08-04.md#L508) | `emlDescribe.summary$` is assembled but never used by the report path — dead abstraction | — |
| D8 | GRAPHING  | high  | [L583](DRIVE_FINDINGS_2026-08-04.md#L583) | `Check normality` offers no `Draw` button — no visual check accompanies the numeric one | — |
| D9 | CLARITY  | high  | [L591](DRIVE_FINDINGS_2026-08-04.md#L591) | The p-value row prints its label twice: | 791, 967 |
| D10 | ACCURACY  | medium-high  | [L610](DRIVE_FINDINGS_2026-08-04.md#L610) | Kurtosis threshold is very likely off by 3. `emlReportNormalityAnalysis` (`graphs/eml-annotation-procedures.praat:3491–3501`) flags shape with: | — |
| D11 | CLARITY  | low  | [L644](DRIVE_FINDINGS_2026-08-04.md#L644) | `"→ Skewness outside typical limits (\|skew\| < 1)"` | — |
| D12 | CLARITY  | medium  | [L800](DRIVE_FINDINGS_2026-08-04.md#L800) | ### D12 — CLARITY (medium). No CI on the mean difference | — |
| D13 | CLARITY  | medium  | [L810](DRIVE_FINDINGS_2026-08-04.md#L810) | ### D13 — CLARITY (medium). Subtraction direction is never stated | — |
| D14 | CLARITY  | low  | [L820](DRIVE_FINDINGS_2026-08-04.md#L820) | p is floored at .001 with no exact value anywhere | 980, 1103, 1557, 2168 |
| D15 | ACCURACY  | high  | [L896](DRIVE_FINDINGS_2026-08-04.md#L896) | nonparametric effect size reported under the parametric test — demonstrated numerically 5 Aug: printed `Matched-pairs r 0.971` is the Wilcoxon rank-biserial; the t-derived r is 0.871 | 1116, 3728 |
| D16 | CLARITY  | —  | [L1125](DRIVE_FINDINGS_2026-08-04.md#L1125) | the dialog's own escaping instructions are wrong, and fail silently | — |
| D17 | PACKAGING  | —  | [L1172](DRIVE_FINDINGS_2026-08-04.md#L1172) | `effect_label` column populated inconsistently across analyses | 1522 |
| D18 | CLARITY  | —  | [L1193](DRIVE_FINDINGS_2026-08-04.md#L1193) | default export filename names an internal artefact | 1549 |
| D19 | CLARITY  | —  | [L1204](DRIVE_FINDINGS_2026-08-04.md#L1204) | ### D19 — CLARITY, LOW — paired results shoehorned into the two-group CSV schema | 1920 |
| D20 | ACCURACY  | high  | [L1380](DRIVE_FINDINGS_2026-08-04.md#L1380) | No variance-homogeneity check anywhere, and the plugin's own demo data violates the assumption | — |
| D21 | CLARITY  | medium  | [L1417](DRIVE_FINDINGS_2026-08-04.md#L1417) | : omega² is never computed, though the library already knows how to classify it | — |
| D22 | CLARITY  | medium  | [L1427](DRIVE_FINDINGS_2026-08-04.md#L1427) | ### D22 — CLARITY (medium): the Tukey table reports p-values only | — |
| D23 | PACKAGING  | medium  | [L1441](DRIVE_FINDINGS_2026-08-04.md#L1441) | : the omnibus CSV row carries only the numerator df | 1901 |
| D24 | PACKAGING  | high  | [L1454](DRIVE_FINDINGS_2026-08-04.md#L1454) | : zero is used as the not-applicable sentinel in CSV exports | 1894 |
| D25 | CLARITY  | medium  | [L1483](DRIVE_FINDINGS_2026-08-04.md#L1483) | : the "Adjustment method" control is inert on the parametric k-group path | 1742 |
| D26 | CLARITY  | —  | [L1765](DRIVE_FINDINGS_2026-08-04.md#L1765) | the KW wrapper exposes no post-hoc control whatsoever | — |
| D27 | CLARITY  | —  | [L1796](DRIVE_FINDINGS_2026-08-04.md#L1796) | the Info window silently accumulates duplicate reports that can disagree with each other | — |
| D28 | CLARITY  | —  | [L1828](DRIVE_FINDINGS_2026-08-04.md#L1828) | the KW omnibus p never reaches full precision in the Info window | — |
| D29 | GRAPHING  | —  | [L1839](DRIVE_FINDINGS_2026-08-04.md#L1839) | the caption renders epsilon-squared as "e2" | — |
| D30 | GRAPHING  | —  | [L1855](DRIVE_FINDINGS_2026-08-04.md#L1855) | caption sub-line is low-contrast grey on white | — |
| D31 | —  | —  | [L1864](DRIVE_FINDINGS_2026-08-04.md#L1864) | ### D31 — RESOLVED as designed, downgrade to LOW — violin KDE tails extend exactly one bandwidth past the data | — |
| D32 | ACCURACY  | high  | [L2061](DRIVE_FINDINGS_2026-08-04.md#L2061) | the graph preset bridge cannot carry a second factor, so the default figure silently drops it | — |
| D33 | ACCURACY  | high  | [L2116](DRIVE_FINDINGS_2026-08-04.md#L2116) | Draw annotates a two-way design with a two-group Welch t on one marginal | — |
| D34 | CLARITY  | high-medium  | [L2157](DRIVE_FINDINGS_2026-08-04.md#L2157) | the ANOVA CSV omits SS, MS, and residual df | — |
| D35 | CLARITY  | high-medium  | [L2186](DRIVE_FINDINGS_2026-08-04.md#L2186) | worst instance of the D28 family: nine orders of magnitude flattened to one string | — |
| D36 | CLARITY  | medium-high  | [L2202](DRIVE_FINDINGS_2026-08-04.md#L2202) | no cell means and no marginal means, despite a significant interaction | — |
| D37 | CLARITY  | medium  | [L2213](DRIVE_FINDINGS_2026-08-04.md#L2213) | no N reported anywhere in the two-way block | — |
| D38 | CLARITY  | medium  | [L2220](DRIVE_FINDINGS_2026-08-04.md#L2220) | no simple effects, no post-hoc, and no caution that the interaction qualifies the main effects | — |
| D39 | PACKAGING  | medium  | [L2228](DRIVE_FINDINGS_2026-08-04.md#L2228) | stats exports default into the plugin's own install directory | — |
| D40 | GRAPHING  | medium  | [L2254](DRIVE_FINDINGS_2026-08-04.md#L2254) | no interaction plot among the 14 graph types | — |
| D41 | CLARITY  | low-medium  | [L2266](DRIVE_FINDINGS_2026-08-04.md#L2266) | no effect-magnitude labels, inconsistent with wrappers 6 and 7 | — |
| D42 | CLARITY  | low-medium  | [L2274](DRIVE_FINDINGS_2026-08-04.md#L2274) | explanation narration is asymmetric within a single transcript | — |
| D43 | GRAPHING  | low  | [L2283](DRIVE_FINDINGS_2026-08-04.md#L2283) | ### D43 — GRAPHING (low) — no auto-title, against Rule 28A | — |
| D44 | CLARITY  | —  | [L2426](DRIVE_FINDINGS_2026-08-04.md#L2426) | R² is gated behind `emlShowExplanations`, so the Info window omits it while the figure annotation displays it | — |
| D45 | ACCURACY  | —  | [L2454](DRIVE_FINDINGS_2026-08-04.md#L2454) | the CSV writes the Y variable into the `group_col` slot | — |
| D46 | ACCURACY  | —  | [L2475](DRIVE_FINDINGS_2026-08-04.md#L2475) | CSV descriptives hardcoded to six literal zeros | — |
| D47 | CLARITY  | —  | [L2496](DRIVE_FINDINGS_2026-08-04.md#L2496) | the `Group column` optionmenu is unfiltered and offers the correlated columns as grouping factors | — |
| D48 | CLARITY  | —  | [L2516](DRIVE_FINDINGS_2026-08-04.md#L2516) | per-group results print *after* the report's closing rule, with no summary and no terminator | — |
| D49 | CLARITY  | —  | [L2540](DRIVE_FINDINGS_2026-08-04.md#L2540) | 30 identical skip lines, each preceded by a blank line | — |
| D50 | CLARITY  | —  | [L2557](DRIVE_FINDINGS_2026-08-04.md#L2557) | ### D50 — CLARITY — no confidence interval on r | — |
| D51 | GRAPHING  | —  | [L2567](DRIVE_FINDINGS_2026-08-04.md#L2567) | `Regression: None` is the default on a scatter launched from a correlation, while the same figure annotates R² | — |
| D52 | CLARITY  | —  | [L2598](DRIVE_FINDINGS_2026-08-04.md#L2598) | no loop repopulation; `New` resets every control to literal defaults | — |
| D53 | CLARITY  | —  | [L2611](DRIVE_FINDINGS_2026-08-04.md#L2611) | no assumption guidance, in the one wrapper that offers the nonparametric alternative in the same dialog | — |
| D54 | ACCURACY  | —  | [L2761](DRIVE_FINDINGS_2026-08-04.md#L2761) | CSV descriptive columns are repurposed as regression coefficient slots, so the header lies about the payload | — |
| D55 | ACCURACY  | —  | [L2775](DRIVE_FINDINGS_2026-08-04.md#L2775) | `group1` and `group2` both carry the sentinel | — |
| D56 | CLARITY  | —  | [L2782](DRIVE_FINDINGS_2026-08-04.md#L2782) | the coefficients table breaks the report's own layout | — |
| D57 | CLARITY  | —  | [L2792](DRIVE_FINDINGS_2026-08-04.md#L2792) | no confidence interval on slope or intercept, despite both | — |
| D58 | CLARITY  | —  | [L2798](DRIVE_FINDINGS_2026-08-04.md#L2798) | no residual diagnostics in the one wrapper whose entire | — |
| D59 | CLARITY  | —  | [L2806](DRIVE_FINDINGS_2026-08-04.md#L2806) | `Y = slope x X + intercept` uses the letter `x` as the multiplication sign immediately adjacent to the variable `X` (`eml-regress.praat:42`). In a dia | — |
| D60 | GRAPHING  | —  | [L2815](DRIVE_FINDINGS_2026-08-04.md#L2815) | the scatter's Y axis runs 40–110 on a variable named | — |
| D61 | CLARITY  | —  | [L2825](DRIVE_FINDINGS_2026-08-04.md#L2825) | the wrapper's documented "Theil-Sen robust alternative" is unreachable from the wrapper, and the `Regression: Both` control does not mean what it appe | — |
| D62 | CLARITY  | —  | [L2855](DRIVE_FINDINGS_2026-08-04.md#L2855) | `Variance explained  large effect` formats a benchmark | — |
| D63 | ACCURACY  | —  | [L2926](DRIVE_FINDINGS_2026-08-04.md#L2926) | The figure and the exported CSV report a different test family than the analysis that launched them, with no disclosure on any screen | — |
| D64 | ACCURACY  | —  | [L2986](DRIVE_FINDINGS_2026-08-04.md#L2986) | The `Adjustment method` optionmenu on the graphing dialog is inert whenever `Test type = Parametric` and k ≥ 3 | — |
| D65 | ACCURACY  | —  | [L3010](DRIVE_FINDINGS_2026-08-04.md#L3010) | The Draw path's CSV export is byte-identical to a different wrapper's export, and claims the same default filename | — |
| D66 | ACCURACY  | high  | [L3037](DRIVE_FINDINGS_2026-08-04.md#L3037), [L3462](DRIVE_FINDINGS_2026-08-04.md#L3462) | `CSV` on the analysis-side `Analysis complete` dialog cannot ever succeed, and its failure message blames the filesystem — DEMONSTRATED on `emlRunPairwiseAnalysis` 5 Aug; row-building exists only in `graphs/eml-annotation-procedures.praat` | — |
| D67 | CLARITY  | —  | [L3062](DRIVE_FINDINGS_2026-08-04.md#L3062) | Cohen's d is printed for every pair; n, means and SDs for the groups are printed nowhere | — |
| D68 | CLARITY  | —  | [L3070](DRIVE_FINDINGS_2026-08-04.md#L3070) | No test statistic and no degrees of freedom | — |
| D69 | CLARITY  | —  | [L3077](DRIVE_FINDINGS_2026-08-04.md#L3077) | ### D69 — CLARITY — The raw p is never shown | — |
| D70 | CLARITY  | —  | [L3085](DRIVE_FINDINGS_2026-08-04.md#L3085) | No significance marking and no alpha anywhere in the report | — |
| D71 | CLARITY  | —  | [L3093](DRIVE_FINDINGS_2026-08-04.md#L3093) | Two adjacent matrices use opposite symmetry conventions, unexplained | — |
| D72 | GRAPHING  | —  | [L3108](DRIVE_FINDINGS_2026-08-04.md#L3108) | The annotation matrix encodes four states in colour and glyph, and legends none of them | — |
| D73 | GRAPHING  | —  | [L3122](DRIVE_FINDINGS_2026-08-04.md#L3122) | ### D73 — GRAPHING — Auto-derived axis label drops the unit parenthesis | — |
| D74 | CLARITY  | —  | [L3131](DRIVE_FINDINGS_2026-08-04.md#L3131) | Dialog section rule is `--- Options ---` where every other wrapper uses the box-drawing rule | — |
| D75 | CLARITY  | —  | [L3138](DRIVE_FINDINGS_2026-08-04.md#L3138) | Report header casing does not match the control that set it | — |
| D76 | CLARITY  | —  | [L3144](DRIVE_FINDINGS_2026-08-04.md#L3144) | The CSV omnibus row carries only `dfBetween`; `dfWithin` is dropped | — |
| D77 | ACCURACY  | high  | [L3242](DRIVE_FINDINGS_2026-08-04.md#L3242) | the `pre\|post` keyword makes the *time* role steal the second member of a paired pair | — |
| D78 | ACCURACY  | medium  | [L3298](DRIVE_FINDINGS_2026-08-04.md#L3298) | `groupIdx` and `subjectIdx` resolve to the same column | — |
| D79 | CLARITY  | low  | [L3379](DRIVE_FINDINGS_2026-08-04.md#L3379) | The `comment:` line documenting the subscript marker is the one line where GTK eats the marker — 13 sites in `graphs/eml-graphs-form.praat` | — |
| D80 | NOT A DEFECT  | —  | [L3414](DRIVE_FINDINGS_2026-08-04.md#L3414) | The Draw leg's wide→long reshape is correct — recorded so it is not re-opened | — |
| D81 | NOT A DEFECT  | —  | [L3436](DRIVE_FINDINGS_2026-08-04.md#L3436) | `Export Complete` reports the full destination path with underscores intact — this is what makes D39 recoverable | — |
| D82 | ACCURACY  | high  | [L3574](DRIVE_FINDINGS_2026-08-04.md#L3574) | RM condition slots default to fixed column positions 1–3 with no type filter, so `Condition 1` takes the subject ID column and the last real condition is dropped | — |
| D83 | CLARITY  | high  | [L3595](DRIVE_FINDINGS_2026-08-04.md#L3595) | The resulting failure reads "Need at least 2 complete-case subjects" on complete data, and the wizard exits, discarding three pages of choices | — |
| D84 | CLARITY  | low  | [L3616](DRIVE_FINDINGS_2026-08-04.md#L3616) | "How many repeated measurements per subject?" is overlapped by the `Conditions:` optionmenu row | — |
| D85 | CLARITY  | high  | [L3627](DRIVE_FINDINGS_2026-08-04.md#L3627) | Repeated-measures p-values print as 25–29 place decimal strings; the plugin's own `< .001` convention is not used | — |
| D86 | ACCURACY  | medium  | [L3647](DRIVE_FINDINGS_2026-08-04.md#L3647) | No effect size for RM-ANOVA (partial η²) or Friedman (Kendall's *W*), while the pairwise wrapper reports Cohen's *d* | — |
| D87 | CLARITY  | high  | [L3659](DRIVE_FINDINGS_2026-08-04.md#L3659) | CSV export and Draw share the single `wizCanDraw` flag, so repeated-measures results can be neither graphed nor exported | — |
| D88 | GRAPHING  | high  | [L3744](DRIVE_FINDINGS_2026-08-04.md#L3744) | `roundTo = 10` hard-coded at 12 of 17 `@emlComputeAxisRange` call sites, so any measure ranging under ~10 units is squashed into the bottom of the panel; the adaptive fix already existed at the scatter site | FIXED at 10 sites, verified by drive; 2 F0 sites left by design — see plugin/FIX_NOTES.md |
| D89 | GRAPHING  | medium  | [L3790](DRIVE_FINDINGS_2026-08-04.md#L3790) | An empty Title field yields a figure with no title at all — D43 confirmed on the shared graphing form, not one graph type | — |
| D90 | GRAPHING  | medium  | [L3802](DRIVE_FINDINGS_2026-08-04.md#L3802) | Axis labels read `Value` and `Condition` — the reshape's internal role names — while the real column names sit in the tick labels | — |
| D91 | GRAPHING  | medium  | [L3890](DRIVE_FINDINGS_2026-08-04.md#L3890) | The histogram frequency axis cannot be made data-derived without a tick constraint; **RESOLVED** via the `emlYAxisMinStep` constraint honoured by the four y-step procedures. All 16 axis-range sites now derive from the data | 3932 |
