# Findings index — EML Praat Tools GUI drive audit

136 findings (D1–D136) extracted from `DRIVE_FINDINGS_2026-08-04.md`, plus
those filed since by the work itself. Each row
links to the line where the finding is first stated. **Every row was
re-verified against the code on 6 August 2026 — see VERIFICATION_2026-08-06.md
for the method, the evidence and the root-cause clustering. 80 are LIVE, 7 had
been fixed without this index noticing, 2 were misfiled, 1 needs a render.
Before that sweep this file recorded what had been FILED, not what was TRUE.** The **Revisits** column
lists line numbers where the finding was later reconfirmed, revised, scoped
down, resolved, or reopened — several findings changed severity after further
evidence, so read the revisits before acting on a row.

> **Status 8 August 2026.** Four closed this pass: **D123** (legend lays out in
> multiple columns, with `+N more` truncation that is never silent — 8663 px
> outside the frame → 0 at 24 entries), **D124** (annotation block wraps to a
> frame-derived budget — box 0.981 → 0.488 of the axis range, 28 data px
> covered → 0), **D126** (every `pkill -f` / `pgrep -f` in the harness recipe
> converted to `-x`, hazard reproduced live first; the `-use_titlebar no`
> claim corrected by measurement and `MENU_MAP.md` reconciled to it), and
> **D134** (the wizard's normality gate now mirrors the `eml-analysis.praat`
> hierarchy branch for branch; kurtosis documentation corrected from 1 to the
> real 2 and 7). **D125 is NOT closed** — it is in flight. **D135 is new**, and
> was found by the D123 work rather than looked for: the legend still overhangs
> on a single label wider than the whole frame, which is the legend's copy of
> D124.
>
> **Status as of 7 August 2026.** After the author rulings
> (`reviews/AUTHOR_RULINGS_2026-08-06.md`): **4 rows LIVE, 1 PARTIAL.**
> D33, D63 and D64 are the Ruling 2 unification and are UNTOUCHED. D40 is
> Ruling 3's interaction plot, also untouched. D38 is PARTIAL — its caution
> half landed, its simple-effects half did not. D110 is new, filed 7 Aug.
> D8, D20 and D58 closed with validators behind them (v22–v26, 869 checks).
> Suite 1937/1937, exit 0.
>
> **Status 7 Aug, end of day.** Everything on the "found but not fixed"
> list is closed. Six resolved this pass (D116, D118-D122); four new ones
> filed, all found BY that work rather than looked for. Still open and
> deferred by the author: the graphing unification (D33/D63/D64), the
> two-way follow-ups (D38 simple effects, D40 interaction plot), and D84,
> which needs a render on macOS. Suite 3881/3881, exit 0.
>
> **Status 7 Aug, earlier.** Three agents ran in parallel: D110 and D111 are
> CLOSED with validators (v27 = 181 checks; v09/v10/v25 extended). D93 is
> REOPENED — driving it refuted claim 3. D113 and D114 are new, both found
> by that work rather than by looking for them. Suite 2137/2137, exit 0.
>
> **W0 of the parallel GUI plan is done.** The 3-instance rig is verified
> in this sandbox and committed as `harness/walks/rig.sh`. The
> `violin_zerovar` BLANK_FRAME is CLOSED as a detector defect, not a
> figure defect — the figure was correct all along. D111 is new, found
> while re-rendering. D84, D92 and D93 remain.

Classes: ACCURACY (wrong number or wrong test reported), CLARITY (right number,
unusable or ambiguous presentation), GRAPHING (figure defects), PACKAGING
(export schema, filenames, install layout), NOT A DEFECT (investigated and
dismissed).


> ## Correction, and a correction to the correction — 6 August 2026
>
> **First error.** D99 was marked `RESOLVED` with the note "procedure name
> gone from user-facing text". The fix touched `@emlOneWayAnova`. **Thirty-nine
> other sites still leak it**, including `emlKruskalWallis: need >= 2 groups,
> got 1`. Reopened, and it stands reopened.
>
> **Second error, in the opposite direction.** Fifteen CSV findings were then
> reopened on the belief that "the CSV rewrite" meant
> `plugin/stats/eml-result-writer.praat`, which no shipping script reaches.
> That was wrong. There were **two** pieces of CSV work dated 6 Aug and they
> were conflated:
>
> - **Rewrite A** — `@emlCSVInit` / `@emlCSVAdd` / `@emlCSVWrite` in
>   `plugin/stats/eml-output.praat` were rewritten in place to the long schema
>   `table,analysis,term,term_type,field,value`, and every call site in
>   `graphs/eml-annotation-procedures.praat` was rewritten with them. **This is
>   live and reachable** — `@emlCSVInit` is called from `eml-analysis.praat`,
>   `@emlCSVAdd` ~157 times from the reporter.
> - **Rewrite B** — `eml-result-writer.praat`, a broom-style tidy/glance/augment
>   writer, is reachable only from a test harness. It is a deferred
>   enhancement, not the closure evidence for anything.
>
> Re-verified finding by finding against rewrite A: **nine are genuinely
> fixed** (D19 D23 D24 D34 D45 D46 D54 D55 D76) and **six are not**
> (D18 D37 D39 D41 D65 D66), each for a specific reason now recorded in its
> row. So the original closure was wrong about six, and the blanket reopening
> was wrong about nine.
>
> **Two comments in the shipped code assert fixes that were never made:**
> `eml-output.praat:991-993` (D18) and `eml-annotation-procedures.praat:3946`
> (D37, D41). A fix comment is not evidence and was not treated as such in this
> re-verification.
>
> **The standard, stated once.** A finding is resolved only when a user running
> the shipped plugin cannot reproduce it, demonstrated against the emitting
> code — not against a fix comment, not against a module's existence, and not
> against a test that touches one call site of many.
>
> **Re-audit.** Every one of the 69 rows marked LIVE was re-checked against the
> current code rather than trusted from its status column. All 69 are confirmed
> still live; none had been incidentally fixed; D83 is half fixed. D92 and D93
> could not be settled by static inspection and are labelled so. Seven defects
> that no finding covers were found during the pass and are filed as D102-D108.
>
> ## Author ruling, 6 Aug 2026 — the CSV three-file split is a BLOCKER
>
> The CSV output moves to the three split files (`tidy` / `glance` /
> `augment`) via `plugin/stats/eml-result-writer.praat`. **This is Phase One
> and it is a blocker.** It is not a downstream enhancement, and any document
> in this repository that says otherwise is superseded by this line.
>
> Every path that terminates at a CSV must be converted and each conversion
> **confirmed against `broom` in `validate/`, not asserted**. Measured surface:
> 11 orchestrators in `stats/eml-analysis.praat`, 157 row-emission sites in
> `graphs/eml-annotation-procedures.praat`, 3 export surfaces (wrapper dialog,
> Draw path, Stats Wizard). Three orchestrators — `emlRunPairwiseAnalysis`,
> `emlRunRepeatedMeasuresAnalysis`, `emlRunFriedmanAnalysis` — init a CSV and
> never add a row, so those are build cases rather than convert cases (D66).
>
> ### Migration progress — COMPLETE, 6 Aug 2026
>
> **All 11 orchestrators converted**, each confirmed against base R and broom's
> documented column contract on files produced by the orchestrator the menu
> calls — never by a harness calling the writer directly.
>
> | | |
> |---|---|
> | converted | Anova (v20, 55 checks) · TwoGroup, KW, TwoWay, Paired, Correlation, Regression, Normality (v21) |
> | **built** — these emitted no rows at all before (D66) | Pairwise, RepeatedMeasures, Friedman |
> | drivers | `harness/broom_cases/anova_shipping_drive.praat`, `all_paths_drive.praat`, `contamination_probe.praat` |
> | evidence | 32 files under `evidence/csv_export/broom/` |
>
> **Cross-contamination: probed, not assumed.** `contamination_probe.praat`
> runs 8 assertions and found a real defect before the fix landed — an
> orchestrator that fails its guards reaches `goto END_*` **without ever
> calling `@emlCSVInit`**, so the previous analysis's flag and collectors
> survived. A repeated-measures run that bailed on "Need at least 2 condition
> columns" exported the *normality* analysis's tidy and glance under the RM
> name. The flag is now cleared at the first statement of all 13 orchestrators,
> before any guard can fire.
>
> Two shape defects were also caught by the checks rather than shipped: the
> writer emitted a `term` column of blanks on htest frames, which broom's
> `tidy(t.test)` does not have (an all-empty tidy column is now dropped, while
> a partly-empty one — broom's NA on the Residuals row — is kept); and the
> two-way tolerances were tighter than the arithmetic warrants, since R fits by
> QR and the plugin accumulates cell sums.
>
> | | |
> |---|---|
> | **1 of 11 converted** | `emlRunAnovaAnalysis` — confirmed by `validate/v20_shipping_anova_broom.R`, 55 checks against base R and broom's documented column contract, on files produced by the orchestrator the menu calls |
> | remaining | TwoGroup, KW, TwoWay, Paired, Correlation, Regression, Normality — convert. Pairwise, RepeatedMeasures, Friedman — build, they emit no rows today (D66) |
>
> `check_wired.sh` is now GREEN: `eml-result-writer.praat` is reachable through
> `plugin/scripts/eml-lib-stats.praat`. It no longer tracks migration progress —
> `v20`-style per-path checks do.
>
> **Cross-contamination guard, added 6 Aug and demonstrated first.** Running a
> converted analysis and then an unconverted one left `emlResult_declared` at 1,
> so an export would have written the first analysis's tables under the second
> analysis's name. `@emlCSVInit` now clears the flag and the staged frames, and
> every orchestrator calls it. This is the class of defect the "confirm each
> path" rule exists for.
>
> ## Tabled by author ruling — not open work, not deferred to Phase Two
>
> **Stats Demo, Quick Start, the interactive tutorial, and Batch voice
> analysis are tabled.** All four are unregistered from the menu in
> `plugin/setup.praat`, which documents each one. They are not counted in the
> live total, they are not in the Phase One audit's clusters, and a finding
> filed against their content is not a defect against this release.
>
> **Phase Two is multiple regression and linear mixed models. Nothing else.**
> Everything else in this index is Phase One.
>
> `validate/tools/check_wired.sh` and `validate/tools/check_calls.py` enforce
> the mechanical half of the standard: nothing unreachable, and no `@call` that
> resolves to nothing at run time.


| ID | Class | Severity | First stated | Summary | Revisits (line) |
|----|-------|----------|--------------|---------|-----------------|
| D1 | CLARITY  | RESOLVED (6 Aug, verified) | [L107](DRIVE_FINDINGS_2026-08-04.md#L107) | `Try:` line paraphrases the Wizard's labels | 274, 382 |
| D2 | NOT A DEFECT  | —  | [L133](DRIVE_FINDINGS_2026-08-04.md#L133) | dismissed Pause windows persist in the X window list | — |
| D3 | CLARITY  | RESOLVED (6 Aug, verified) | [L293](DRIVE_FINDINGS_2026-08-04.md#L293) | only type 6 states what the data demonstrate | 372 |
| D4 | CLARITY  | RESOLVED  | [L479](DRIVE_FINDINGS_2026-08-04.md#L479) | The report line reads `Kurtosis`, but the value is excess kurtosis (normal = 0, not 3). The plugin's own `emlDescribe.summary$` in `stats/eml-core-des | 4050 |
| D5 | CLARITY  | RESOLVED (6 Aug, verified) | [L488](DRIVE_FINDINGS_2026-08-04.md#L488) | No estimator conventions are disclosed anywhere | — |
| D6 | CLARITY  | RESOLVED (6 Aug, verified) | [L497](DRIVE_FINDINGS_2026-08-04.md#L497) | Identifiers are underscore-stripped for display: `demo_normality` → `demo normality`, `F0_Hz` → `F0 Hz` (`eml-describe-table.praat:114–115`). Undersco | 634, 781, 973, 1070 |
| D7 | PACKAGING  | RESOLVED (6 Aug, verified) | [L508](DRIVE_FINDINGS_2026-08-04.md#L508) | `emlDescribe.summary$` is assembled but never used by the report path — dead abstraction | — |
| D8 | GRAPHING  | RESOLVED (7 Aug, v23) | [L583](DRIVE_FINDINGS_2026-08-04.md#L583) | `Check normality` offers no `Draw` button — no visual check accompanies the numeric one — **Ruling 4.** `Draw` added to `Check normality` (`eml-check-normality.praat:210`), Q-Q from the Blom order statistics `@emlShapiroWilk` already computes, behind a mandatory column picker (and a group picker in grouped mode). `Describe Table` half ruled a documented Phase One gap; histogram overlay ruled out. v23, 177 checks | — |
| D9 | CLARITY  | RESOLVED (6 Aug, verified) | [L591](DRIVE_FINDINGS_2026-08-04.md#L591) | The p-value row prints its label twice: | 791, 967 |
| D10 | ACCURACY  | RESOLVED (verified 6 Aug)  | [L610](DRIVE_FINDINGS_2026-08-04.md#L610) | Kurtosis threshold is very likely off by 3. `emlReportNormalityAnalysis` (`graphs/eml-annotation-procedures.praat:3491–3501`) flags shape with: | 4081 |
| D11 | CLARITY  | RESOLVED (6 Aug, verified) | [L644](DRIVE_FINDINGS_2026-08-04.md#L644) | `"→ Skewness outside typical limits (\|skew\| < 1)"` | — |
| D12 | CLARITY  | RESOLVED (6 Aug, verified) | [L800](DRIVE_FINDINGS_2026-08-04.md#L800) | ### D12 — CLARITY (medium). No CI on the mean difference | — |
| D13 | CLARITY  | RESOLVED (6 Aug, verified) | [L810](DRIVE_FINDINGS_2026-08-04.md#L810) | ### D13 — CLARITY (medium). Subtraction direction is never stated | — |
| D14 | CLARITY  | MISFILED (verified 6 Aug)  | [L820](DRIVE_FINDINGS_2026-08-04.md#L820) | p is floored at .001 with no exact value anywhere | 980, 1103, 1557, 2168 |
| D15 | ACCURACY  | RESOLVED  | [L896](DRIVE_FINDINGS_2026-08-04.md#L896) | nonparametric effect size reported under the parametric test — demonstrated numerically 5 Aug: printed `Matched-pairs r 0.971` is the Wilcoxon rank-biserial; the t-derived r is 0.871 | 1116, 3728, 4110 |
| D16 | CLARITY  | RESOLVED (6 Aug, verified) | [L1125](DRIVE_FINDINGS_2026-08-04.md#L1125) | the dialog's own escaping instructions are wrong, and fail silently | — |
| D17 | PACKAGING  | RESOLVED (6 Aug, verified) | [L1172](DRIVE_FINDINGS_2026-08-04.md#L1172) | `effect_label` column populated inconsistently across analyses | 1522 |
| D18 | CLARITY  | RESOLVED (6 Aug, verified) | [L1193](DRIVE_FINDINGS_2026-08-04.md#L1193) | default export filename names an internal artefact | 1549 |
| D19 | CLARITY  | RESOLVED (re-verified 6 Aug, rewrite A)  | [L1204](DRIVE_FINDINGS_2026-08-04.md#L1204) | ### D19 — CLARITY, LOW — paired results shoehorned into the two-group CSV schema | 1920 |
| D20 | ACCURACY  | RESOLVED (7 Aug, v22+v25) | [L1380](DRIVE_FINDINGS_2026-08-04.md#L1380) | No variance-homogeneity check anywhere, and the plugin's own demo data violates the assumption — **Ruling 1, conditional show-both.** Brown-Forsythe prints always; Welch F + Games-Howell append only when it rejects. Primary test never switched. **The finding's second claim was FALSE**: the demo generator is designed near-homoscedastic (`eml-create-demo.praat:78-101`, variance ratios 1.5625 and 1.96). But FABL's counter-correction stands and is wider — `demo_3groups` vibrato p=.0391, `dump_demo_twoway` SPL p=.0014, and v09/v10/v14's own `vibrato_rate_Hz` p=.0297 all reject. v22 447 checks, v25 31 | — |
| D21 | CLARITY  | RESOLVED (6 Aug, verified) | [L1417](DRIVE_FINDINGS_2026-08-04.md#L1417) | : omega² is never computed, though the library already knows how to classify it | — |
| D22 | CLARITY  | RESOLVED (6 Aug, verified) | [L1427](DRIVE_FINDINGS_2026-08-04.md#L1427) | ### D22 — CLARITY (medium): the Tukey table reports p-values only | — |
| D23 | PACKAGING  | RESOLVED (re-verified 6 Aug, rewrite A)  | [L1441](DRIVE_FINDINGS_2026-08-04.md#L1441) | : the omnibus CSV row carries only the numerator df | 1901 |
| D24 | PACKAGING  | RESOLVED (re-verified 6 Aug, rewrite A)  | [L1454](DRIVE_FINDINGS_2026-08-04.md#L1454) | : zero is used as the not-applicable sentinel in CSV exports | 1894 |
| D25 | CLARITY  | RESOLVED (6 Aug, verified) | [L1483](DRIVE_FINDINGS_2026-08-04.md#L1483) | : the "Adjustment method" control is inert on the parametric k-group path | 1742 |
| D26 | CLARITY  | RESOLVED (6 Aug, verified) | [L1765](DRIVE_FINDINGS_2026-08-04.md#L1765) | the KW wrapper exposes no post-hoc control whatsoever | — |
| D27 | CLARITY  | RESOLVED (6 Aug, verified) | [L1796](DRIVE_FINDINGS_2026-08-04.md#L1796) | the Info window silently accumulates duplicate reports that can disagree with each other | — |
| D28 | CLARITY  | RESOLVED (6 Aug, verified) | [L1828](DRIVE_FINDINGS_2026-08-04.md#L1828) | the KW omnibus p never reaches full precision in the Info window | — |
| D29 | GRAPHING  | RESOLVED (6 Aug, verified) | [L1839](DRIVE_FINDINGS_2026-08-04.md#L1839) | the caption renders epsilon-squared as "e2" | — |
| D30 | GRAPHING  | RESOLVED (6 Aug, verified) | [L1855](DRIVE_FINDINGS_2026-08-04.md#L1855) | caption sub-line is low-contrast grey on white | — |
| D31 | —  | MISFILED (verified 6 Aug)  | [L1864](DRIVE_FINDINGS_2026-08-04.md#L1864) | ### D31 — RESOLVED as designed, downgrade to LOW — violin KDE tails extend exactly one bandwidth past the data | — |
| D32 | ACCURACY  | RESOLVED (6 Aug, verified) | [L2061](DRIVE_FINDINGS_2026-08-04.md#L2061) | the graph preset bridge cannot carry a second factor, so the default figure silently drops it | — |
| D33 | ACCURACY  | LIVE 7 Aug — Ruling 2 | [L2116](DRIVE_FINDINGS_2026-08-04.md#L2116) | Draw annotates a two-way design with a two-group Welch t on one marginal — **Ruling 2 governs.** Not a refusal: the graphing door is to call the same machinery as the wrappers, passing the launching analysis's result through and computing fresh only when entered standalone. Untouched as of 7 Aug | — |
| D34 | CLARITY  | RESOLVED (re-verified 6 Aug, rewrite A)  | [L2157](DRIVE_FINDINGS_2026-08-04.md#L2157) | the ANOVA CSV omits SS, MS, and residual df | — |
| D35 | CLARITY  | RESOLVED (6 Aug, verified) | [L2186](DRIVE_FINDINGS_2026-08-04.md#L2186) | worst instance of the D28 family: nine orders of magnitude flattened to one string | — |
| D36 | CLARITY  | RESOLVED (6 Aug, verified) | [L2202](DRIVE_FINDINGS_2026-08-04.md#L2202) | no cell means and no marginal means, despite a significant interaction | — |
| D37 | CLARITY  | RESOLVED (6 Aug, verified) | [L2213](DRIVE_FINDINGS_2026-08-04.md#L2213) | no N reported anywhere in the two-way block | — |
| D38 | CLARITY   | PARTIAL (7 Aug, v26) | [L2220](DRIVE_FINDINGS_2026-08-04.md#L2220) | no simple effects, no post-hoc, and no caution that the interaction qualifies the main effects — Caution half RESOLVED — significant interaction now prints the caveat under the table it qualifies (D98 placement), and `emlTwoWayAnova.warning$` prints at all for the first time. **Simple effects still LIVE** | — |
| D39 | PACKAGING  | RESOLVED (6 Aug, verified) | [L2228](DRIVE_FINDINGS_2026-08-04.md#L2228) | stats exports default into the plugin's own install directory | — |
| D40 | GRAPHING  | LIVE 7 Aug — Ruling 3 | [L2254](DRIVE_FINDINGS_2026-08-04.md#L2254) | no interaction plot among the 14 graph types — **Ruling 3.** Interaction plot goes in the two-way results Draw flow (Interaction plot / Grouped violin / Both, default Both, sequential), NOT as a registry type. Untouched as of 7 Aug | — |
| D41 | CLARITY  | RESOLVED (6 Aug, verified) | [L2266](DRIVE_FINDINGS_2026-08-04.md#L2266) | no effect-magnitude labels, inconsistent with wrappers 6 and 7 | — |
| D42 | CLARITY  | RESOLVED (6 Aug, verified) | [L2274](DRIVE_FINDINGS_2026-08-04.md#L2274) | explanation narration is asymmetric within a single transcript | — |
| D43 | GRAPHING  | RESOLVED (6 Aug, verified) | [L2283](DRIVE_FINDINGS_2026-08-04.md#L2283) | ### D43 — GRAPHING (low) — no auto-title, against Rule 28A | — |
| D44 | CLARITY  | RESOLVED (6 Aug, verified) | [L2426](DRIVE_FINDINGS_2026-08-04.md#L2426) | R² is gated behind `emlShowExplanations`, so the Info window omits it while the figure annotation displays it | — |
| D45 | ACCURACY  | RESOLVED (re-verified 6 Aug, rewrite A)  | [L2454](DRIVE_FINDINGS_2026-08-04.md#L2454) | the CSV writes the Y variable into the `group_col` slot | — |
| D46 | ACCURACY  | RESOLVED (re-verified 6 Aug, rewrite A)  | [L2475](DRIVE_FINDINGS_2026-08-04.md#L2475) | CSV descriptives hardcoded to six literal zeros | — |
| D47 | CLARITY  | RESOLVED (6 Aug, verified) | [L2496](DRIVE_FINDINGS_2026-08-04.md#L2496) | the `Group column` optionmenu is unfiltered and offers the correlated columns as grouping factors | — |
| D48 | CLARITY  | RESOLVED (6 Aug, verified) | [L2516](DRIVE_FINDINGS_2026-08-04.md#L2516) | per-group results print *after* the report's closing rule, with no summary and no terminator | — |
| D49 | CLARITY  | RESOLVED (6 Aug, verified) | [L2540](DRIVE_FINDINGS_2026-08-04.md#L2540) | 30 identical skip lines, each preceded by a blank line | — |
| D50 | CLARITY  | RESOLVED (6 Aug, verified) | [L2557](DRIVE_FINDINGS_2026-08-04.md#L2557) | ### D50 — CLARITY — no confidence interval on r | — |
| D51 | GRAPHING  | RESOLVED (6 Aug, verified) | [L2567](DRIVE_FINDINGS_2026-08-04.md#L2567) | `Regression: None` is the default on a scatter launched from a correlation, while the same figure annotates R² | — |
| D52 | CLARITY  | RESOLVED (6 Aug, verified) | [L2598](DRIVE_FINDINGS_2026-08-04.md#L2598) | no loop repopulation; `New` resets every control to literal defaults | — |
| D53 | CLARITY  | RESOLVED (6 Aug, verified) | [L2611](DRIVE_FINDINGS_2026-08-04.md#L2611) | no assumption guidance, in the one wrapper that offers the nonparametric alternative in the same dialog | — |
| D54 | ACCURACY  | RESOLVED (re-verified 6 Aug, rewrite A)  | [L2761](DRIVE_FINDINGS_2026-08-04.md#L2761) | CSV descriptive columns are repurposed as regression coefficient slots, so the header lies about the payload | — |
| D55 | ACCURACY  | RESOLVED (re-verified 6 Aug, rewrite A)  | [L2775](DRIVE_FINDINGS_2026-08-04.md#L2775) | `group1` and `group2` both carry the sentinel | — |
| D56 | CLARITY  | RESOLVED (6 Aug, verified) | [L2782](DRIVE_FINDINGS_2026-08-04.md#L2782) | the coefficients table breaks the report's own layout | — |
| D57 | CLARITY  | RESOLVED (6 Aug, verified) | [L2792](DRIVE_FINDINGS_2026-08-04.md#L2792) | no confidence interval on slope or intercept, despite both | — |
| D58 | CLARITY   | RESOLVED (7 Aug, v24+v21) | [L2798](DRIVE_FINDINGS_2026-08-04.md#L2798) | no residual diagnostics in the one wrapper whose entire — **Ruling 4(d).** `@emlOLSInfluence` wired into the regression augment; `.hat` and `.cooksd` exported for the first time and `.std.resid` corrected to `rstandard()`. Durbin-Watson REFUSED permanently (order-dependent; Tables carry no ordering semantics) with the reason in REGISTRY. v24 214 checks, v21 +5 | — |
| D59 | CLARITY  | RESOLVED (6 Aug, verified) | [L2806](DRIVE_FINDINGS_2026-08-04.md#L2806) | `Y = slope x X + intercept` uses the letter `x` as the multiplication sign immediately adjacent to the variable `X` (`eml-regress.praat:42`). In a dia | — |
| D60 | GRAPHING  | RESOLVED (6 Aug, verified) | [L2815](DRIVE_FINDINGS_2026-08-04.md#L2815) | the scatter's Y axis runs 40–110 on a variable named | — |
| D61 | CLARITY  | RESOLVED (6 Aug, verified) | [L2825](DRIVE_FINDINGS_2026-08-04.md#L2825) | the wrapper's documented "Theil-Sen robust alternative" is unreachable from the wrapper, and the `Regression: Both` control does not mean what it appe | — |
| D62 | CLARITY  | RESOLVED (6 Aug, verified) | [L2855](DRIVE_FINDINGS_2026-08-04.md#L2855) | `Variance explained  large effect` formats a benchmark | — |
| D63 | ACCURACY  | LIVE 7 Aug — Ruling 2 | [L2926](DRIVE_FINDINGS_2026-08-04.md#L2926) | The figure and the exported CSV report a different test family than the analysis that launched them, with no disclosure on any screen — **Ruling 2 governs.** Dissolves with the unification. Untouched as of 7 Aug | — |
| D64 | ACCURACY  | LIVE 7 Aug — Ruling 2 | [L2986](DRIVE_FINDINGS_2026-08-04.md#L2986) | The `Adjustment method` optionmenu on the graphing dialog is inert whenever `Test type = Parametric` and k ≥ 3 — **Ruling 2 governs.** The Adjustment menu becomes real once the machinery is shared. Untouched as of 7 Aug | — |
| D65 | ACCURACY  | RESOLVED (6 Aug, verified) | [L3010](DRIVE_FINDINGS_2026-08-04.md#L3010) | The Draw path's CSV export is byte-identical to a different wrapper's export, and claims the same default filename | — |
| D66 | ACCURACY  | RESOLVED (6 Aug, verified) | [L3037](DRIVE_FINDINGS_2026-08-04.md#L3037), [L3462](DRIVE_FINDINGS_2026-08-04.md#L3462) | `CSV` on the analysis-side `Analysis complete` dialog cannot ever succeed, and its failure message blames the filesystem — DEMONSTRATED on `emlRunPairwiseAnalysis` 5 Aug; row-building exists only in `graphs/eml-annotation-procedures.praat` | — |
| D67 | CLARITY  | RESOLVED (6 Aug, verified) | [L3062](DRIVE_FINDINGS_2026-08-04.md#L3062) | Cohen's d is printed for every pair; n, means and SDs for the groups are printed nowhere | — |
| D68 | CLARITY  | RESOLVED (6 Aug, verified) | [L3070](DRIVE_FINDINGS_2026-08-04.md#L3070) | No test statistic and no degrees of freedom | — |
| D69 | CLARITY  | RESOLVED (6 Aug, verified) | [L3077](DRIVE_FINDINGS_2026-08-04.md#L3077) | ### D69 — CLARITY — The raw p is never shown | — |
| D70 | CLARITY  | RESOLVED (6 Aug, verified) | [L3085](DRIVE_FINDINGS_2026-08-04.md#L3085) | No significance marking and no alpha anywhere in the report | — |
| D71 | CLARITY  | RESOLVED (6 Aug, verified) | [L3093](DRIVE_FINDINGS_2026-08-04.md#L3093) | Two adjacent matrices use opposite symmetry conventions, unexplained | — |
| D72 | GRAPHING  | RESOLVED (6 Aug, verified) | [L3108](DRIVE_FINDINGS_2026-08-04.md#L3108) | The annotation matrix encodes four states in colour and glyph, and legends none of them | — |
| D73 | GRAPHING  | RESOLVED (6 Aug, verified) | [L3122](DRIVE_FINDINGS_2026-08-04.md#L3122) | ### D73 — GRAPHING — Auto-derived axis label drops the unit parenthesis | — |
| D74 | CLARITY  | RESOLVED (6 Aug, verified) | [L3131](DRIVE_FINDINGS_2026-08-04.md#L3131) | Dialog section rule is `--- Options ---` where every other wrapper uses the box-drawing rule | — |
| D75 | CLARITY  | RESOLVED (6 Aug, verified) | [L3138](DRIVE_FINDINGS_2026-08-04.md#L3138) | Report header casing does not match the control that set it | — |
| D76 | CLARITY  | RESOLVED (re-verified 6 Aug, rewrite A)  | [L3144](DRIVE_FINDINGS_2026-08-04.md#L3144) | The CSV omnibus row carries only `dfBetween`; `dfWithin` is dropped | — |
| D77 | ACCURACY  | RESOLVED (6 Aug, verified) | [L3242](DRIVE_FINDINGS_2026-08-04.md#L3242) | the `pre\|post` keyword makes the *time* role steal the second member of a paired pair | — |
| D78 | ACCURACY  | RESOLVED (6 Aug, verified) | [L3298](DRIVE_FINDINGS_2026-08-04.md#L3298) | `groupIdx` and `subjectIdx` resolve to the same column | — |
| D79 | CLARITY  | RESOLVED (6 Aug, verified) | [L3379](DRIVE_FINDINGS_2026-08-04.md#L3379) | The `comment:` line documenting the subscript marker is the one line where GTK eats the marker — 13 sites in `graphs/eml-graphs-form.praat` | — |
| D80 | NOT A DEFECT  | —  | [L3414](DRIVE_FINDINGS_2026-08-04.md#L3414) | The Draw leg's wide→long reshape is correct — recorded so it is not re-opened | — |
| D81 | NOT A DEFECT  | —  | [L3436](DRIVE_FINDINGS_2026-08-04.md#L3436) | `Export Complete` reports the full destination path with underscores intact — this is what makes D39 recoverable | — |
| D82 | ACCURACY  | RESOLVED (6 Aug, verified) | [L3574](DRIVE_FINDINGS_2026-08-04.md#L3574) | RM condition slots default to fixed column positions 1–3 with no type filter, so `Condition 1` takes the subject ID column and the last real condition is dropped | — |
| D83 | CLARITY  | RESOLVED (6 Aug, verified) | [L3595](DRIVE_FINDINGS_2026-08-04.md#L3595) | The resulting failure reads "Need at least 2 complete-case subjects" on complete data, and the wizard exits, discarding three pages of choices | — |
| D84 | CLARITY  | NEEDS RENDER (verified 6 Aug)  | [L3616](DRIVE_FINDINGS_2026-08-04.md#L3616) | "How many repeated measurements per subject?" is overlapped by the `Conditions:` optionmenu row | — |
| D85 | CLARITY  | RESOLVED (6 Aug, verified) | [L3627](DRIVE_FINDINGS_2026-08-04.md#L3627) | Repeated-measures p-values print as 25–29 place decimal strings; the plugin's own `< .001` convention is not used | — |
| D86 | ACCURACY  | RESOLVED (6 Aug, verified) | [L3647](DRIVE_FINDINGS_2026-08-04.md#L3647) | No effect size for RM-ANOVA (partial η²) or Friedman (Kendall's *W*), while the pairwise wrapper reports Cohen's *d* | — |
| D87 | CLARITY  | RESOLVED (6 Aug, verified) | [L3659](DRIVE_FINDINGS_2026-08-04.md#L3659) | CSV export and Draw share the single `wizCanDraw` flag, so repeated-measures results can be neither graphed nor exported | — |
| D88 | GRAPHING  | RESOLVED (verified 6 Aug)  | [L3744](DRIVE_FINDINGS_2026-08-04.md#L3744) | `roundTo = 10` hard-coded at 12 of 17 `@emlComputeAxisRange` call sites, so any measure ranging under ~10 units is squashed into the bottom of the panel; the adaptive fix already existed at the scatter site | FIXED at 10 sites, verified by drive; 2 F0 sites left by design — see plugin/FIX_NOTES.md |
| D89 | GRAPHING  | RESOLVED (6 Aug, verified) | [L3790](DRIVE_FINDINGS_2026-08-04.md#L3790) | An empty Title field yields a figure with no title at all — D43 confirmed on the shared graphing form, not one graph type | — |
| D90 | GRAPHING  | RESOLVED (6 Aug, verified) | [L3802](DRIVE_FINDINGS_2026-08-04.md#L3802) | Axis labels read `Value` and `Condition` — the reshape's internal role names — while the real column names sit in the tick labels | — |
| D91 | GRAPHING  | RESOLVED (verified 6 Aug)  | [L3890](DRIVE_FINDINGS_2026-08-04.md#L3890) | The histogram frequency axis cannot be made data-derived without a tick constraint; **RESOLVED** via the `emlYAxisMinStep` constraint honoured by the four y-step procedures. All 16 axis-range sites now derive from the data | 3932 |
| D92 | GRAPHING  | RESOLVED (claim NOT re-verified 6 Aug — needs a rendered figure)  | [L3996](DRIVE_FINDINGS_2026-08-04.md#L3996) | The annotated (bracket) path pinned violin and box y-axes to zero, and the inflated range then tripled the annotation headroom — **RESOLVED**, floor now derived from the data; bar charts keep their zero floor | — |
| D93 | CLARITY | RESOLVED (7 Aug, v30) | — | Claims 1 and 2 confirmed by driving; claim 3 was FALSE and is now true. The wizard said "Nothing has been lost" and re-rendered from a column guess — a user who pressed **Run** without touching anything had a DIFFERENT analysis reported as theirs. Fixed at all nine sites plus a tenth the survey missed (correlation's `corrCol1$`/`corrCol2$` also assigned below the guard), with one helper `@wizardColIdx` modelled on the file's existing `@wizardCondSlot`, 16 call sites. The two already-correct hand-written copies were converted too, so one idiom serves the whole file. Proof: `evidence/walks/d117/pressrun_regression_FIXED_runagain.png` | 4312 |
| D94 | CLARITY  | RESOLVED (verified 6 Aug)  | [L4447](DRIVE_FINDINGS_2026-08-04.md#L4447) | `exitScript` written without its colon at 3 sites, so Praat parses it as a variable and Quit raises "Unknown variable: exitScript" instead of exiting quietly — **RESOLVED**, all three now `exitScript: ""` | 4447 |
| D95 | ACCURACY  | RESOLVED (verified 6 Aug)  | [L4460](DRIVE_FINDINGS_2026-08-04.md#L4460) | Three shape-threshold sites disagreed: the normality report judged kurtosis at 3 while the recommendation gate beside it used 1, so one report could print "within typical limits" and then send the user nonparametric. Also the last unrelabelled bare `Kurtosis` from D4 — **RESOLVED**, every site reads `emlSkewThreshold` / `emlKurtosisThreshold` | 4460 |
| D96 | ACCURACY  | RESOLVED  | [L4484](DRIVE_FINDINGS_2026-08-04.md#L4484) | **First statement WITHDRAWN** — it claimed the plugin silently dropped a row, which is false; it prints `N (undefined)`. Restated: `Get value:` collapses empty cell, unparseable string and locale decimal comma into one `undefined` bucket, so a genuine gap cannot be told from recoverable data being discarded, and neither row nor value is named | 4578 — FIXED 6 Aug: one classifier used by every extraction path; the comma cell is now excluded and named rather than silently read as a different number |
| D97 | ACCURACY  | RESOLVED  | [L4498](DRIVE_FINDINGS_2026-08-04.md#L4498) | RM-ANOVA omnibus does not check for a zero error term and printed `F(2,6) = 2.11e16` on an exactly-linear table; the same run's post-hoc caught the identical condition and refused, so the check exists in the module and the omnibus does not call it | 4578 — FIXED 6 Aug: omnibus refuses on a RELATIVE zero-error floor (`ssErr <= 1e-10 * ssTot`); an equality test against zero would not have fired |
| D98 | CLARITY  | RESOLVED  | [L4515](DRIVE_FINDINGS_2026-08-04.md#L4515) | A two-subject repeated-measures design yields F(2,2), a p-value and three post-hoc p-values with no caveat; the Greenhouse-Geisser epsilon printed 0.5000, exactly the 1/(k−1) floor forced by n = 2, so the tell is in hand at print time | 4578 — FIXED 6 Aug: caution printed directly under the GG line, placement asserted in v07 |
| D99 | CLARITY  | RESOLVED (6 Aug, verified) | [L4528](DRIVE_FINDINGS_2026-08-04.md#L4528) | A refusal on singleton groups names only the first offending group, so six take six attempts; never states the six-groups-for-six-rows diagnosis though `@emlCountGroups` holds both numbers. Also leaks the internal procedure name into user-facing text | 4578 — FIXED 6 Aug: refusal states groups-against-rows; refusal states groups-against-rows. **The procedure-name half was NOT completed**: the fix touched @emlOneWayAnova only, and 39 other sites in eml-inferential.praat still prefix their own name into user-facing error text (emlTwoWayAnova x11, emlTukeyHSD x6, emlPairwiseT x4, emlDunnTest x4, emlKruskalWallis x3, and 11 more). Reopened 6 Aug |
| D100 | ACCURACY  | high (RESOLVED)  | [L4661](DRIVE_FINDINGS_2026-08-04.md#L4661) | `scripts/eml-describe-table.praat` called `@emlReportDescriptiveAnalysis`, which lived in a module it does not include. Praat resolves a procedure name at CALL time, so the parse check passed and the menu item opened; "Procedure not found" came the instant Run was clicked. Fixed by moving the procedure to `stats/eml-output.praat`; `harness/check_includes.py` written to catch the class | — |
| D101 | ACCURACY  | high (RESOLVED)  | [L4683](DRIVE_FINDINGS_2026-08-04.md#L4683) | Nine wrappers each carried four calls into `stats/eml-lmm.praat`, which no wrapper includes, via `@emlRunLMMAnalysis` in `stats/eml-analysis.praat`. Same call-time latency as D100. Fixed by moving the orchestrator beside its engine so the two cannot be included separately | — |
| D102 | ACCURACY | RESOLVED (6 Aug, verified) | — | `emlShowExplanations` is set to 1 by `@emlGraphsWorkflow` (`graphs/eml-graphs-form.praat:794`) and never reset, so after any Draw every later analysis report in the session becomes verbose. Report content is order-dependent within a session. Root cause shared with D42 and D44 | — |
| D103 | ACCURACY | RESOLVED (6 Aug, verified) | — | `graphs/eml-graphs-form.praat:3345-3346` overwrites `scatterRegressionLine` from `prev_scatterRegressionLine` AFTER the preset bridge sets it at `:1021-1024`, so on the second and later scatter in one session the regression wrapper's preset is silently discarded and the previous dialog's choice wins. Same clobber pattern for dot size, formula and dots | — |
| D104 | ACCURACY | RESOLVED (6 Aug, verified) | — | `@emlCSVInit` runs once per orchestrator (`stats/eml-analysis.praat:858`) but `@emlReportCorrelationAnalysis` is re-invoked per group by `scripts/eml-correlate.praat:140` without re-init, so a grouped correlation export accumulates overall and per-group rows in one file, distinguished only by a `-- group` suffix on the table name | — |
| D105 | CLARITY | RESOLVED (6 Aug, verified) | — | `stats/eml-output.praat:991-993` carries a comment asserting a D18 fix at the call site. The paired wrapper never passed the intermediate table, so the comment documents a fix to something that was not broken while the real defect at `graphs/eml-graphs-form.praat:5801` survives | — |
| D106 | CLARITY | RESOLVED (6 Aug, verified) | — | `graphs/eml-annotation-procedures.praat:3946` reads `# D37: n1,n2 were literal 0,0. D41: effect_label was ""` — but the two-way block below emits no `effect_label` and prints no N to the Info window. A false closure record inside the shipped code | — |
| D107 | ACCURACY | RESOLVED (6 Aug, verified) | — | The D32 column-guessing fix was applied to the non-preset branch (`graphs/eml-graphs-form.praat:4422-4428`) but not to the preset branch (`:4396`), which is the branch the two-way wrapper takes; `gvSubIdx` there is still positional `min (2, nCols)` | — |
| D108 | ACCURACY | RESOLVED (6 Aug, verified) | — | `emlGraphsPresetCorrection$` was added so wrappers could carry their adjustment method into the figure and does seed the dialog, but on the parametric path the value is never read (`graphs/eml-annotation-procedures.praat:2151+`); only the Dunn branch consumes it. The wrapper advertises fidelity it does not have | — |
| D109 | PACKAGING | **TABLED — author ruling** | — | `scripts/eml-tutorial.praat` calls 23 procedures that nothing it includes defines (`validate/tools/check_calls.py`). Already unregistered from the menu. The tutorial is TABLED by author ruling alongside Stats Demo, Quick Start and Batch voice analysis, so this is recorded for provenance and is NOT open work | — |
| D110 | CLARITY   | RESOLVED (7 Aug, v09+v10+v25) | — | Two *p* formats in one report. The Tukey matrix prints `fixed$(p, 4)` (`0.4918`) and the Games-Howell matrix 35 lines below it prints `@emlFormatP.bare$` (`.584`) — both in `graphs/eml-annotation-procedures.praat`, both in the one-way ANOVA block, visible together in `evidence/info/v25_showboth_present_info.txt:43` and `:78`. The bare APA form is the D9/D28 direction and is correct; the Tukey matrix is the one that should move. Found while writing v25 on 7 Aug and recorded there in a comment rather than filed. **Cost:** changing the Tukey matrix format moves numbers that `v09` and `v10` read out of committed captures, so it needs those captures re-driven, which is why it is filed rather than swept — **CLOSED.** Three `fixed$` p sites converted to `@emlFormatP.bare$`: the one-way source table, the Tukey matrix, the Dunn matrix. Both matrices also gained the `.999` ceiling and the `undefined` case the hand-rolled floor missed — an undefined p used to render `--undefined--`. v25 now ASSERTS bare-APA form on every off-diagonal cell of both matrices rather than narrating the inconsistency in a comment. **v09 and v10 captures were re-driven and their provenance changed from GUI click-driven to headless**; both script headers carry a PROVENANCE block saying so. Re-driving also revealed those captures were four revisions stale — D22's Tukey CI block, Ruling 1's equal-spread lines and the D9 double-label fix were all absent from committed evidence | — |
| D111 | GRAPHING  | RESOLVED (7 Aug, v27) | — | `@emlDrawHistogram` on an empty table draws **nothing at all** (one unique colour, 0 chromatic px) where violin, box and scatter draw a labelled empty frame. **Root cause is a propagation failure, not a bespoke bug.** `@emlDrawViolinPlot` carries a `v1.19 (C 96)` fix — *"with no usable value anywhere, .globalMin stayed undefined and the undefined axis limits aborted the figure at Axes:. Fall back to a unit axis, as @emlDrawGroupedViolin already does"* — which propagated grouped-violin → violin → box by hand and stopped. The histogram instead `goto HIST_END`s past its own `Axes:` call. Fix is the same unit-axis fallback, matching an existing in-tree precedent — **CLOSED.** All ten Table-consuming draw procedures now fall back to a unit axis, draw the labelled empty frame, and disclose why. Zero `goto` and zero `label` statements remain in the draw library, and v27 asserts that statically — the construct is how the defect got in. Corrections to the original survey: only the HISTOGRAM ever drew a true blank page (1 of 10, not 4 behaviours); `emlDrawTimeSeries`, `emlDrawSpaghettiPlot` and `emlDrawScatterPlot` were already correct; `emlDrawBarChart` had no guard but survived by luck, since `emlBarData_visible*` seed at 0 and `emlComputeAxisRange` widens a zero span; `emlDrawTimeSeriesCI` had the fallback but was the only one of the ten that disclosed nothing at all. 11 populated cases rendered pixel-identical before and after | — |
| D112 | ACCURACY | RESOLVED (7 Aug, v29) | — | **Rows with missing values were dropped silently in 8 of 10 draw procedures.** All ten now disclose, reusing violin/box's wording and counter verbatim. Author ruling — *"draw the image as the image unless someone asks to annotate"*: Info window always, the figure only when Annotate is ticked, via the EXISTING annotation block; the user's subtitle never. The two procedures that were writing into `emlSubtitle$` unconditionally (time series, bar chart) stop; v29 bans the assignment statically | — |
| D113 | ACCURACY | RESOLVED (7 Aug, v28) | — | **The two-way ANOVA reported a real, significant result computed from the ALPHABETICAL ORDER of a text column.** Root cause: Praat has two column readers that disagree. `Get value:` returns undefined for a text cell — which every row-wise path in the plugin already drops — but `Get all numbers in column:` / `Report two-way anova:` numericise the column as a whole and substitute each value's alphabetical rank. Driven on `dump_demo_twoway.csv`: `singer` as the data column gave F = 132.92, p = 6.9e-15. **One bad cell is enough** — a single `n/a` in row 3 of 48 moved the reported voice_type F from 34.11 to 0.7356, because that call cannot drop a row. Nine other orchestrators already refused this input but all nine blamed MISSING DATA rather than a wrong column type. Now one guard, `@emlRequireNumericColumn`, reusing the `@emlAuditColumn` classifier that already existed, at 14 call sites. Mixed columns drop-and-disclose per the 21 July convention; two-way alone refuses, because it has no per-row drop — v28 asserts BOTH halves so the asymmetry cannot be silently tidied away | — |
| D115 | ACCURACY | RESOLVED (7 Aug, v28) | — | **Pairwise comparisons had no data-column guard at all.** Pointed at a column not in the table it returned an empty `error$` and printed a full comparison matrix of `n/a`. Same shape as D113, one degree less dangerous only because the cells read `n/a` rather than plausible numbers. Found by the D113 harness, not by looking for it | — |
| D116 | CLARITY | RESOLVED (7 Aug) | — | **Two refusals blamed the groups when the data column was absent.** Both now say `Data column not found: y` — `@emlOneWayAnova`'s existing string, not a new one. Scoping found the real spread was one layer down: five library tests had the same shape, and `@emlPairwiseT` / `@emlPairwiseWilcoxon` said **nothing at all** — empty error, matrix of undefined — which is yesterday's pairwise defect surviving below the orchestrator that was fixed. One shared guard `@emlRequireColumnPresent` replaces **thirteen** hand-copied two-line checks across six tests, placed in the TEST not the orchestrator so it reaches scripts that call the library directly. Not-found and empty stay deliberately different messages, and v28 now asserts they cannot converge | — |
| D117 | GRAPHING | RESOLVED (7 Aug, v29) | — | **The line chart came out completely blank on any table with a missing value.** `@emlDrawTimeSeries` set `.runT = undefined` when an undefined row fell inside an open run; the next row of the same time point then flushed `.aggT = .runT`, so every mean got an undefined x and no line was drawn — axes, title and subtitle only. Reproduced against unmodified HEAD. Undefined rows are now dropped, matching `@emlDrawTimeSeriesCI`; both report the same collapse count on the same table. **Behaviour change:** a time point where every observation is missing now bridges rather than gapping. Found only because the new disclosure would have claimed "the line shows the mean" on a figure with no line | — |
| D118 | GRAPHING | RESOLVED (7 Aug) | — | Grouped scatter's annotation block is capped at `20 - annotBlockN - 2`. **All-or-none, not truncation**: a box listing six of eight groups is indistinguishable from a complete one. Over budget, every line goes to the Info window in full and the figure says so. This also fixed a second-order silence — the 24-line box had already spent the budget, so the figure that overflowed was also the figure that stopped reporting its dropped rows | — |
| D119 | GRAPHING | RESOLVED (7 Aug) | — | The Q-Q file's write to `emlSubtitle$` is gone. `n = N` and the plotting-position parameter are kept but moved: `n = 40, Blom plotting positions (a = 3/8).` The parameter is load-bearing — v23 asserts this axis differs from R's `qqnorm()` above n = 10, so a reader comparing the two would otherwise conclude the plugin is wrong | — |
| D120 | ACCURACY | RESOLVED (7 Aug) | — | **A bar chart's missing group no longer draws as a bar of height zero.** Root cause fixed in `@emlMeasureBarData`, which seeded means and errors to 0 rather than undefined, making both skip-guards dead code. Both cases now disclose, with wording that states the behaviour rather than the defect: `1 bar(s) not drawn (no usable observation): G3.` and `1 error bar(s) not drawn (error undefined).` One thing depended on the 0 seed — the visible-range fold inside the same procedure — and was fixed with it | — |
| D121 | ACCURACY | RESOLVED (7 Aug) | — | The ten-colour ceiling is **kept** — `@emlSetColorPalette` declares ten fill/line pairs and cycles only eight hues above that, so an eleventh sub-group would repeat a colour already in the legend. The silence is gone: `1 sub-group(s) not drawn (palette holds 10).` Also fixed two things that made the drop invisible — the legend advertised the undrawn sub-group, and the slot geometry left a phantom eleventh gap | — |
| D122 | PACKAGING | RESOLVED (7 Aug) | — | `harness/gui.sh` matched windows on `WM_NAME`. The mechanism is narrower than first described and worth recording: GTK sets `WM_NAME` only when the title is representable in Latin-1, so an ASCII pause title carries both properties and is findable, while **every EML wizard page — all of which use an em dash — has no `WM_NAME` at all**. Locale is not the cause; `LC_ALL=C.UTF-8` does not restore a property that was never set. Fixed via `_NET_CLIENT_LIST`, and the sweep found **7 more** name-based lookups with the same assumption, including one whose comment already argued for the right matching rule while its enumeration step still used the wrong one | — |
| D123 | GRAPHING | RESOLVED (8 Aug) | — | `@emlDrawLegend` has no entry cap. A 21-group figure's legend runs off the top of the frame. Same shape as the annotation-block overflow just fixed, in the other box — **CLOSED.** Not a cap: `@emlDrawLegend` now LAYS OUT, measuring the frame for `rowsMax x colsMax` and filling multiple columns. Truncation is the last resort and is never silent — the final cell becomes `+N more` on the figure and a NOTE naming both counts goes to the Info window, because a legend that quietly dropped entries would be D127's silence again. Verified at 24 entries on a 6x4 figure: **8663 px outside the frame → 0**. One entry, or any count that fits one column, keeps the previous single-column geometry to the last decimal. **One case is deliberately NOT handled and is filed as D135**: a single label wider than the whole frame still overhangs, because `.colsMax` floors at 1 | — |
| D124 | GRAPHING | RESOLVED (8 Aug) | — | `@emlDrawAnnotationBlock` does not wrap. On a narrow figure a long disclosure line makes the box wide enough to sit over the data — seen with a 5-line box on a 4-bar chart — **CLOSED.** Every entry now wraps through `@emlWrapText` against a width budget derived from the frame (`emlAnnotBlockWidthShare`, default 0.55) rather than from the text, with a height guard so wrapping cannot push the box off the bottom instead. The case as filed went from a box spanning **0.981 of the axis range to 0.488**, and from **28 data pixels covered to 0**. The legend has NOT had this treatment — see D135 | — |
| D125 | ACCURACY | **LIVE 7 Aug** | — | At the LIBRARY layer, `@emlPairwiseT` and `@emlPairwiseWilcoxon` still return an empty error and a matrix of undefined for an all-blank column. Unreachable through the menus — the orchestrator refuses upstream — and no number is ever produced, so it is a gap rather than a live wrong answer. v28 pins it AS SILENT so it fails the day anyone closes it | — |
| D126 | PACKAGING | RESOLVED (8 Aug) | — | `harness/GUI_HARNESS_RECIPE.md` §2.1 recommends `pkill -9 -f matchbox`, which is the same self-kill hazard the very next line warns about for praat — the driving shell's own command line contains the string. It fired during a teardown (exit 144). `pkill -x matchbox-window` is the safe form. The same section's claim that `-use_titlebar no` suppresses window chrome was also contradicted by observation — **CLOSED.** Every `pkill -f` / `pgrep -f` **invocation** in the recipe converted to the `-x` exact-name form, and the rule stated ONCE at the top of the document rather than per site, so a new teardown snippet inherits it. The five surviving `-f` mentions are the prohibition itself — the "NEVER" column of the standing-rule table and the prose reproducing the hazard — not instructions. The hazard was reproduced live before the fix — `pgrep -f matchbox` matched the driving shell's own pid — and the safe form then ran without killing the shell. **The `-use_titlebar no` claim was corrected by measurement, not by softening the wording**: the flag suppresses chrome on maximized top-level windows only. Praat's Objects and Picture windows get none; a `Pause:` dialog still gets a 20 px titlebar with a close box and 4 px borders, so `xdotool getwindowgeometry` on such a dialog reports the client origin with the (+4,+20) frame offset applied a SECOND time and matches neither frame nor client — use `xwininfo`. `harness/MENU_MAP.md` was reconciled to the same measurement (it had declared one layout for a file containing two, 20 px apart) | — |
| D127 | GRAPHING | RESOLVED (7 Aug, v29) | — | The eight-colour palette no longer has two duplicate slots — they are gone structurally, not patched. Author ruling: **24 sub-group styles = 8 hues x 3 fill patterns {solid, diagonal, dots}**, cap raised 10 → 24, deliberately set well above what is readable on a default figure because someone may render very wide. Praat has no native hatch; the violin body was already a stack of horizontal slices with known extents, so stripes and dots are clipped per slice with no polygon clipping. Pattern ink is the mark's own stroke colour, not white — every fill in this palette is a 70% blend toward white, so a white hatch on pale yellow is invisible. **Greyscale reaches 24 as well**: its branch had declared ten fills between 0.82 and 0.96, fifteen thousandths apart at the closest, and now uses the same 0.90→0.25 ramp the contrast optimiser was already computing. Measured closest same-pattern pair: 0.0902 greyscale, 0.0784 colour. The legend draws the swatch as the mark rather than a block of colour | — |
| D128 | GRAPHING | RESOLVED (7 Aug, v29) | — | `@emlDrawLegend` measured and drew at its own font size while the viewport had been selected at BODY size. Praat's `Select inner viewport` converts inner to outer using the font size at call time, so the legend rendered into a rectangle smaller than — and offset from — the box it REPORTED to its caller. Everything moved together so it looked right, but the box the caller kept the disclosure block clear of was not the box on the page, and at a large legend font it is gross. Found while adding patterned swatches | — |
| D129 | GRAPHING | RESOLVED (8 Aug) | — | **Marker SHAPE is the second dimension for line-and-point types**: circle / square / triangle x 8 hues = 24, matching the filled marks. Native primitives, no generated assets — and the check the author asked for found why that mattered. `plugin/sprites/` DOES exist (204 tracked PNGs; the graph-stress audit claiming it never existed was wrong), but every sprite is a dot or a rectangle indexed by HUE with no shape axis, and `@emlInitAlphaSprites` returns early on anything that is not macOS or Windows because Praat's image loader has no cairo branch. A raster marker would have rendered blank on the machine that measures it, and on macOS the sprite path would have stamped circles for every group so shape never reached the page — invisible from here. Distinguishability floor measured on renders: **12 px across**, with the square surviving to 5 px, the opposite of the intuition | — |
| D130 | PACKAGING | RESOLVED (7 Aug) | — | A harness that renames its fixtures leaves the old `.log` files behind, and the validator kept reading a previous run's evidence and passing. Both disclosure drivers now clear their output directory before running. Same class as the mutation driver's dead cases: evidence that silently stops being about the current code | — |
| D131 | GRAPHING | RESOLVED (8 Aug, v31) | — | **A dead-end dialog a user could not escape without editing a config file.** `.gridMode` had two incompatible encodings sharing one persisted key. Draw a scatter with gridlines Off, then open a histogram: the dropdown renders blank and OK is refused, and the value is on disk so it survives a restart. Driven and screenshotted against the pre-fix tree. Second defect in the same three lines: the clamp bar/violin/box carried preserved the INDEX not the MEANING, so "Horizontal only" silently became "Off". One canonical encoding now, translated at the dialog. **Omission by a future graph type is made impossible at four layers**, the strongest being two include-time loops that `exitScript` with a named message if a new type has no registry entry — so the failure lands on the developer, not the user | — |
| D132 | PACKAGING | RESOLVED (8 Aug) | — | `gui.sh:xwins` read `xprop -root _NET_CLIENT_LIST`, which prints `"...no such atom on any window."` **on stdout with exit 0** when absent. An unanchored `sed` passed that sentence through as data, so the no-window-manager fallback the comment defends **never ran**; `printf '%d'` over seven English words returned seven zeros and every caller then ran `xwininfo -id 0`. Fixed in all three copies rather than the one that was noticed | — |
| D133 | PACKAGING | RESOLVED (8 Aug) | — | `harness/MENU_MAP.md` listed thirteen menu entries and gave Create Demo Table's y-coordinate for what is now Check & repair data — a fourteenth entry was added to `setup.praat` and `gui.sh` was updated while this table was not. The exact trap the file says it exists to prevent, carried inside it. All fourteen re-measured from a live submenu; every `gui.sh` constant agrees within 2 px | — |
| D134 | ACCURACY | RESOLVED (8 Aug) | — | Two stale thresholds contradict their own code. `@wizardNormDiag` in `eml-wizard.praat` still gates on `.skKurtFail or .swFail` while the comment above claims parity with the hierarchy that `eml-analysis.praat` says replaced it on 5 Aug (anchor: `grep -n 'skKurtFail or swFail' plugin/stats/eml-analysis.praat`, the hierarchy block — an earlier draft of this row anchored on the sentence "Until 5 August this gate", which a same-day rewrite of that comment removed); 4000 random samples found 0 divergent cases at current thresholds, so it is structural rather than demonstrated. Separately, a wizard comment and one in `eml-annotation-procedures.praat` both name a kurtosis threshold of 1 where the code uses 7 — **CLOSED.** `@wizardNormDiag`'s gate now mirrors the `eml-analysis.praat` hierarchy branch **for branch**, so a Shapiro-Wilk that does not reject gives `parametric` in both paths and shape reports without overturning the test. Verified on eight cases including forced threshold moves. The kurtosis documentation was corrected to the real constants — **2 and 7**, not 1 — and the thresholds are now printed from `emlSkewThreshold` / `emlKurtosisThreshold` rather than spelled out, so the next change cannot leave the prose behind; `grep -rn 'kurtosis threshold at' plugin/` returns nothing | — |
| D135 | GRAPHING | **LIVE 8 Aug** | — | **The legend still overhangs to the right on a single label wider than the whole frame.** This is the legend's copy of D124, and it is the one case the D123 multi-column layout deliberately did not take. `@emlDrawLegend` computes `.colsMax` from the frame width and the widest label, and when even one column does not fit it **floors `.colsMax` at 1** and computes capacity as though one column had fitted; the box is then drawn whole and runs off the right of the canvas. Anchor: `grep -n 'if .colsMax < 1' plugin/graphs/eml-graph-procedures.praat`, and the "NOT HANDLED HERE" paragraph in the same file's `@emlDrawLegend` header. Not a regression — it behaved this way before the D123 layout too — and **documented rather than silent**, which is why it is filed rather than swept. The fix is the D124 treatment: wrap the label through `@emlWrapText` against a frame-derived budget, as `@emlDrawAnnotationBlock` now does | — |
| D136 | GRAPHING | **LIVE 18 Aug, severity 3, FIX DEFERRED** | — | **`@emlDrawLMMForest`'s extent tracker and its ink describe different rectangles.** Two halves. It calls `Erase all` and never `@emlResetDrawnExtent`, so a union accumulated by an earlier figure survives the erase it just performed; and both its viewport selections are `Select outer viewport: 0, .figW, 0, .figH`, raw, while the `@emlSetAdaptiveTheme` call between them reports the panel at `emlPanelOriginX/Y`. Anchor: `grep -n 'procedure emlDrawLMMForest' plugin_EML_StatsGraphs/graphs/eml-draw-procedures.praat`, then the `Erase all` and the two raw viewport lines inside it. **Measured, not read:** a 6 x 9 box plot drawn first leaves the union at 0..6 x 0..9; the forest erases, draws 6.5 x 3.1, and the union still reads 0..6.5 x 0..9. With `@emlSetPanelOrigin: 3, 2` the tracker reads 3..9.5 x 2..5.1 while the ink is at 0..6.5 x 0..3.1 — the rectangle `@emlAssertFullViewport` selects carries 0.443% ink against the drawn rectangle's 1.693%, so the save is a crop of the overlap. **Latent and API-reachable:** the plugin's only call site, `scripts/eml-lmm.praat`, draws on a fresh page at the default origin, where both halves are inert. A user script or PraatGen companion that draws first, or sets a panel origin, reaches it — and page composition makes a non-zero origin an ordinary thing to be carrying. **THE FIX IS DEFERRED to the mixed-model phase by author ruling (18 Aug 2026)**: pinning it means driving the forest from a fitted model, which needs that phase's test machinery, and a fix landed now would be unpinned. The repair is already written elsewhere — `@emlBeginPanel` does erase, extent reset and origin as one decision | — |
| D114 | PACKAGING | RESOLVED (7 Aug) | — | Two mutation cases targeted a literal the D110 re-drive removed. Repointed. More importantly the driver can no longer decay silently: a preflight applies every case to a copy first, and a pattern that no longer matches is a **DEAD CASE** that exits 3 — a mutation that cannot fire is not a pass. Opting out now requires a named `SKIPPABLE:<reason>` that prints on every run. Restoration is by file copy under a terminating signal trap; the driver runs no git command that writes, which also makes it safe beside concurrent agents. Audit of all 7 cases: only the 2 known-broken were dead. Two bugs found while testing it — a signal trap that deleted the backup and then RESUMED, leaving 5 corrupted captures, and a restoration check that used `git status` and so failed when another agent created an untracked directory | — |
