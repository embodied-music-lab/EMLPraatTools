# Verification sweep — 6 August 2026

Every open finding re-checked against the code as it stands, because the
index had stopped being a description of the plugin and become a description
of what was once filed against it. The count quoted in conversation before
this sweep — "87 open" — was 101 rows minus the rows whose severity column
said RESOLVED. It was arithmetic on a ledger. Nothing in it had been looked at.

**Method.** Six independent passes, fifteen findings each, over the 90 rows
not already marked resolved. Each finding was read in full from
DRIVE_FINDINGS_2026-08-04.md — the index summaries are truncated and in
places misleading — then traced to the code it names, and that code read as
it is now. Where a claim was about arithmetic or printed output, it was
checked by running the procedure headlessly rather than by reading: several
verdicts below rest on generated CSV rows and captured Info-window text.

**What this sweep is not.** No GUI was driven. These are static verdicts plus
headless runs. A finding about what a rendered figure looks like, or how a
dialog lays out, cannot be settled this way and is marked as such rather than
guessed at.

## Result

| Verdict | Count | Meaning |
|---|---:|---|
| **LIVE** | 80 | Defect found in current code, with file and line |
| FIXED | 7 | Index was stale; code now does the right thing |
| MISFILED | 2 | Wrong when written, or describes intended behaviour |
| CANNOT-TELL | 1 | Needs a render; no fix has been attempted either way |

**Only 7 of 90 had been fixed without the ledger noticing, and 6 of those 7
are D88-D95 — the batch worked on in the last two days.** The older findings
had not been incidentally resolved by anything. The hedge offered in
conversation, that some of the list might be stale, was wrong in the
optimistic direction.

One correction worth stating plainly: **D85 was speculated in conversation to
be possibly fixed**, on the evidence that a repeated-measures drive printed
`p = 0.0089`. It is LIVE. The RM path calls `fixed$` rather than
`@emlFormatP`, and `fixed$ (3.1e-29, 4)` prints twenty-nine decimals. The
drive simply did not produce a small enough p.

## 80 live defects, ~11 root causes

The count that matters is not 80. These cluster, and most clusters are one
decision made once and inherited everywhere. Fixing a cluster is one piece of
work; fixing eighty findings one at a time is not.

### 1. The CSV export schema — 14 findings

One header — table,data_col,group_col,group1,group2,test,statistic,df,p,effect_size,n1,n2,mean1,sd1,median1,mean2,sd2,median2 — is made to carry the output of every test in the plugin. Slots get reused for unrelated quantities (regression writes slope into mean1 and intercept into median1), zero is the not-applicable sentinel so a real zero is unreadable, the single df column cannot hold a numerator and a denominator, and two paths call emlCSVInit without ever adding a row so the export reports a write failure that never happened. This is one design decision, made once, failing in fourteen places.

`D19` `D23` `D24` `D34` `D37` `D41` `D45` `D46` `D54` `D55` `D65` `D66` `D76` `D18`

### 2. The Draw bridge recomputes under a different method — 6 findings

Clicking Draw does not annotate the analysis you ran. It re-runs statistics from preset variables that carry the columns but not the method, so a Welch/Bonferroni pairwise becomes ANOVA/Tukey, a two-way becomes a two-group Welch t on one marginal, and the second factor is dropped because no subgroup preset variable exists. The figure and its CSV are then indistinguishable from the ones a menu-initiated graph would produce.

`D32` `D33` `D51` `D63` `D64` `D25`

### 3. p-value formatting is inconsistent across paths — 4 findings

Three conventions coexist: emlFormatP's APA floor (p < .001), a raw fixed$ that expands to 29 decimals on the repeated-measures path, and a 3-decimal cap on Kruskal-Wallis that renders .002511 and .003449 identically. The label is also printed twice at ten sites because emlFormatP bakes the p = prefix into the value.

`D9` `D28` `D35` `D85`

### 4. Reports omit the interval or the descriptives — 10 findings

Effect estimates are printed without the uncertainty that makes them interpretable, and group descriptives are absent from paths that have them in hand: no CI on a mean difference, on r, on a regression coefficient, or on a Tukey contrast; no n or group SD in the pairwise report; no cell or marginal means in the two-way, which discards Praat's own Means table to build its own.

`D12` `D22` `D36` `D37` `D50` `D57` `D67` `D68` `D69` `D86`

### 5. Column-role guessing picks the wrong column — 4 findings

The pre|post keyword makes the time role steal the second member of a paired pair, the no-group fallback lets one column hold two roles at once, the wizard's condition slots are hardcoded positional indices over an unfiltered list, and the correlate group menu offers the columns already bound to X and Y.

`D47` `D77` `D78` `D82`

### 6. emlShowExplanations is a global that leaks — 3 findings

The graphs workflow sets it to 1 and never restores it, so one Info transcript can contain an unnarrated block followed by a narrated one. Worse, on the correlation path the R-squared COMPUTATION sits inside the same conditional as its report line, so the value is not merely unnarrated but absent.

`D42` `D44` `D41`

### 7. Assumptions are never checked — 4 findings

No variance-homogeneity test exists anywhere in the plugin — no Levene, Bartlett, Brown-Forsythe or Games-Howell — and ANOVA runs unconditionally while its own explanation line claims equal variances hold. The regression path forms no residual vector at all, so nothing downstream can check normality, homoscedasticity or leverage. There is no simple-effects follow-up for a significant interaction.

`D20` `D38` `D53` `D58`

### 8. Axis, title and label defaults — 5 findings

Titles seed from an empty string and nothing composes a fallback, so the default figure is untitled. Axis labels come from column names with no unit heuristic, and on the reshaped paired table they read Condition and Value. No percentage detection, though the branch for it exists and every call site passes zero.

`D43` `D60` `D73` `D89` `D90`

### 9. Report layout and typography — 11 findings

A flush-left coefficient block against everyone else's two-space indent, a 0.55-grey sub-line under WCAG contrast, a legend that covers neither the diagonal nor the nonsignificant cell, a footer that closes the report before the per-group loop runs, and the same wrong markup-escape instruction repeated at thirteen dialog sites.

`D16` `D30` `D48` `D49` `D56` `D62` `D72` `D74` `D75` `D79` `D29`

### 10. Missing or misdescribed capability — 12 findings

Features advertised but absent (Theil-Sen in the regression header, omega-squared in the label formatter), a dead .summary$ with no consumer, no interaction or means plot among fourteen graph types, no Draw route from normality or describe, no CSV route from repeated measures, and export folders defaulting inside the plugin tree.

`D5` `D7` `D8` `D21` `D26` `D39` `D40` `D52` `D59` `D61` `D87` `D6`

### 11. Demo-table descriptions — 2 findings

The Try: lines paraphrase wizard labels rather than quoting them, never mention the direct menu routes, and only one of seven types says what its data are built to demonstrate.

`D1` `D3`

### 12. Still needs a rendered figure or a drive — 8 findings

Not settleable from source.

`D11` `D13` `D17` `D27` `D70` `D71` `D83` `D84`

## Every verdict

| ID | Class | Verdict | Where | Evidence |
|---|---|---|---|---|
| D1 | CLARITY | **LIVE** | `scripts/eml-create-demo.praat:58` | All seven Try: lines still paraphrase the wizard's actual labels; direct menu routes still unmentioned |
| D3 | CLARITY | **LIVE** | `scripts/eml-create-demo.praat:208` | Only type 6 states what the data demonstrate; types 1-5 give column names only |
| D5 | CLARITY | **LIVE** | `stats/eml-output.praat:156` | emlReportFooter prints a rule and nothing else; no estimator conventions disclosed anywhere |
| D6 | CLARITY | **LIVE** | `stats/eml-output.praat:1204` | Underscore stripping moved into emlReportDescriptiveAnalysis intact; check-normality still inconsistent within one dialog |
| D7 | PACKAGING | **LIVE** | `stats/eml-core-descriptive.praat:642` | .summary$ built from 16 concatenations, no production consumer |
| D8 | GRAPHING | **LIVE** | `scripts/eml-check-normality.praat:219` | Completion dialog is Done/New; emlGraphsWorkflow appears in neither normality nor describe |
| D9 | CLARITY | **LIVE** | `graphs/eml-annotation-procedures.praat:2598` | 10 sites print label "p" against emlFormatP's "p = " prefix; no .bare$ was added |
| D10 | ACCURACY | **FIXED** | `stats/eml-output.praat:89` | Thresholds are now sourced globals (West/Finch/Curran 1995); the Pearson/excess confusion is gone |
| D11 | CLARITY | **LIVE** | `graphs/eml-annotation-procedures.praat:3503` | Failing branch still asserts |skew| < 2 at the moment it announces the opposite |
| D12 | CLARITY | **LIVE** | `graphs/eml-annotation-procedures.praat:2607` | Mean difference printed bare; emlTTest exposes no CI bounds to print |
| D13 | CLARITY | **LIVE** | `graphs/eml-annotation-procedures.praat:2607` | Label has no (g1 - g2) direction; sign uninterpretable with explanations off |
| D14 | CLARITY | **MISFILED** | `stats/eml-output.praat:614` | CSV uses fixed$(p,6) which auto-extends; the flooring claim is disproven. Residual: tiny p exports at ~1 significant digit |
| D16 | CLARITY | **LIVE** | `graphs/eml-graphs-form.praat:1442` | All 13 sites carry the same wrong escape instruction; render confirms \_% prints nothing |
| D17 | PACKAGING | **LIVE** | `graphs/eml-annotation-procedures.praat:3272` | 7 sites pass "" for esLabel$, 9 pass a real label, 1 passes a third convention |
| D18 | CLARITY | **LIVE** | `graphs/eml-graphs-form.praat:5758` | Export name derives from the reshaped intermediate; paired wrapper still pre-fills pairedLong_results |
| D19 | CLARITY | **LIVE** | `graphs/eml-annotation-procedures.praat:3642` | Paired reporter packs two column names into all four schema slots and passes n twice |
| D20 | ACCURACY | **LIVE** | `graphs/eml-annotation-procedures.praat:2718` | No Levene/Bartlett/Brown-Forsythe/Games-Howell anywhere; ANOVA runs unconditionally |
| D21 | CLARITY | **LIVE** | `stats/eml-output.praat:380` | omega_squared branch exists in the label formatter; no procedure computes omega-squared |
| D22 | CLARITY | **LIVE** | `graphs/eml-annotation-procedures.praat:2793` | Tukey prints p and d only; no mean difference, no CI, q computed but never printed |
| D23 | PACKAGING | **LIVE** | `graphs/eml-annotation-procedures.praat:2763` | dfWithin reaches CSV only through Tukey rows; with Tukey off the error df is absent |
| D24 | PACKAGING | **LIVE** | `stats/eml-output.praat:601` | Zero is still the not-applicable sentinel; 8 zeros written for omnibus descriptives |
| D25 | CLARITY | **LIVE** | `graphs/eml-graphs-form.praat:2632` | Adjustment method offered in 6 dialogs ungated; only the Dunn branch consumes it |
| D26 | CLARITY | **LIVE** | `scripts/eml-compare-kw.praat:77` | Post-hoc and adjustment hardcoded to 1/holm; no user control, unlike the ANOVA sibling |
| D27 | CLARITY | **LIVE** | `stats/eml-output.praat:137` | Header cannot distinguish analysis-path from graph-path blocks; Draw re-runs and re-reports |
| D28 | CLARITY | **LIVE** | `graphs/eml-annotation-procedures.praat:2992` | KW p capped at 3 decimals with no numeric row; .002511 and .003449 both render p = .003 |
| D29 | GRAPHING | **LIVE** | `graphs/eml-annotation-procedures.praat:1997` | Caption builds literal "e2 = "; no escape used on this path |
| D30 | GRAPHING | **LIVE** | `graphs/eml-annotation-procedures.praat:1509` | Post-hoc sub-line at 0.55 grey unconditionally, ~3.3:1 contrast, under WCAG 4.5:1 |
| D31 | — | **MISFILED** | `graphs/eml-draw-procedures.praat:2026` | Self-classified RESOLVED as designed; Silverman bandwidth extension is intended. Trim control still absent |
| D32 | ACCURACY | **LIVE** | `scripts/eml-compare-twoway.praat:117` | factor2$ goes nowhere; no subgroup preset variable exists; type-11 fallback picks column 2 = the same factor |
| D33 | ACCURACY | **LIVE** | `graphs/eml-graphs-form.praat:5358` | Draw from a two-way wrapper is indistinguishable from a menu grouped violin; annotates with a two-group Welch t |
| D34 | CLARITY | **LIVE** | `stats/eml-output.praat:597` | No SS, MS or denominator df column; F(1,28) exports as df=1.00 and cannot be reconstructed |
| D35 | CLARITY | **LIVE** | `stats/eml-output.praat:248` | p = 1.06e-14 and p = 1.59e-20 print as the identical string in one table |
| D36 | CLARITY | **LIVE** | `graphs/eml-annotation-procedures.praat:3715` | No cell or marginal means; Praat's own Means table is computed then discarded |
| D37 | CLARITY | **LIVE** | `graphs/eml-annotation-procedures.praat:3715` | No per-cell n, per-level n or total N; CSV writes n1,n2 as literal 0,0 |
| D38 | CLARITY | **LIVE** | `graphs/eml-annotation-procedures.praat:3715` | No simple-effects code anywhere in the plugin; no caution tying main effects to the interaction |
| D39 | PACKAGING | **LIVE** | `stats/eml-output.praat:784` | Export folder defaults to the running script's directory inside the plugin tree |
| D40 | GRAPHING | **LIVE** | `graphs/eml-graphs-form.praat:137` | 14 graph types, none an interaction or means plot; Line Chart has no subgroup option |
| D41 | CLARITY | **LIVE** | `graphs/eml-annotation-procedures.praat:3801` | All three two-way rows pass "" for effect_label; the Info narration is gated off on the wrapper path |
| D42 | CLARITY | **LIVE** | `graphs/eml-graphs-form.praat:794` | emlGraphsWorkflow sets emlShowExplanations = 1 and never restores it; one transcript, two narration modes |
| D43 | GRAPHING | **LIVE** | `graphs/eml-graphs-form.praat:900` | Title seeds from an empty string; nothing composes a default, so emlDrawTitle short-circuits |
| D44 | CLARITY | **LIVE** | `graphs/eml-annotation-procedures.praat:3251` | R-squared computation AND its report line both sit inside if emlShowExplanations |
| D45 | ACCURACY | **LIVE** | `graphs/eml-annotation-procedures.praat:3268` | Y variable written into the group_col slot; confirmed in a generated export |
| D46 | ACCURACY | **LIVE** | `graphs/eml-annotation-procedures.praat:3273` | Six descriptive slots exported as 0 though both columns' descriptives are well defined |
| D47 | CLARITY | **LIVE** | `scripts/eml-correlate.praat:64` | Group column menu lists every column, unfiltered, including the two bound to X and Y |
| D48 | CLARITY | **LIVE** | `scripts/eml-correlate.praat:118` | Footer closes the report before the per-group loop runs; groups print after the terminator |
| D49 | CLARITY | **LIVE** | `scripts/eml-correlate.praat:157` | Two lines per skipped group, no accumulator; a 30-level column costs 60 lines |
| D50 | CLARITY | **LIVE** | `graphs/eml-annotation-procedures.praat:3267` | No confidence interval on r; no Fisher-z code exists in the procedure |
| D51 | GRAPHING | **LIVE** | `scripts/eml-correlate.praat:169` | Draw bridge never sets emlGraphsPresetRegressionLine, so the line is None while the annotation still writes r and R-squared |
| D52 | CLARITY | **LIVE** | `stats/eml-output.praat:672` | Narrowed by D93 but not closed: Clear Info window is hardcoded to 0 with no seed parameter |
| D53 | CLARITY | **LIVE** | `scripts/eml-correlate.praat:56` | No normality screen and no note that Spearman is the rank-based alternative |
| D54 | ACCURACY | **LIVE** | `graphs/eml-annotation-procedures.praat:3433` | Slope in mean1, slope SE in sd1, intercept in median1, R in sd2; no coefficient columns added |
| D55 | ACCURACY | **LIVE** | `graphs/eml-annotation-procedures.praat:3434` | Literal "regression" written into both group-level slots |
| D56 | CLARITY | **LIVE** | `graphs/eml-annotation-procedures.praat:3395` | Coefficient block flush-left at column 0 against every other line's 2-space indent |
| D57 | CLARITY | **LIVE** | `graphs/eml-annotation-procedures.praat:3395` | No coefficient CIs; no t-quantile call anywhere in the regression reporter |
| D58 | CLARITY | **LIVE** | `stats/eml-analysis.praat:990` | No residual vector, no Shapiro-Wilk, no homoscedasticity, leverage or Durbin-Watson on the regression path |
| D59 | CLARITY | **LIVE** | `scripts/eml-regress.praat:49` | Dialog and Info window both use bare x for the predictor instead of its name |
| D60 | GRAPHING | **LIVE** | `graphs/eml-draw-procedures.praat:2277` | isPercentage branch exists; all ~16 call sites pass literal 0, so nothing detects a percentage measure |
| D61 | CLARITY | **LIVE** | `scripts/eml-regress.praat:5` | Header advertises Theil-Sen; wrapper never calls it and the draw gate can never fire from this path |
| D62 | CLARITY | **LIVE** | `graphs/eml-annotation-procedures.praat:3431` | Cohen-style benchmark routed through the same value formatter as R-squared and residual SE |
| D63 | ACCURACY | **LIVE** | `graphs/eml-annotation-procedures.praat:2173` | Welch/Bonferroni analysis still yields an ANOVA/Tukey figure and CSV; no divergence warning |
| D64 | ACCURACY | **LIVE** | `graphs/eml-annotation-procedures.praat:2151` | Adjustment method consumed only by the Dunn branch; 6 dialogs offer it unscoped |
| D65 | ACCURACY | **LIVE** | `graphs/eml-graphs-form.praat:5758` | Pairwise-then-Draw CSV is byte-identical to the ANOVA CSV; default name is analysis-blind |
| D66 | ACCURACY | **LIVE** | `stats/eml-analysis.praat:422` | emlCSVInit without any AddRow; export returns success = 0 and reports "Could not write CSV file" |
| D67 | CLARITY | **LIVE** | `stats/eml-analysis.praat:456` | No n, no group mean, no group SD in the pairwise report |
| D68 | CLARITY | **LIVE** | `stats/eml-analysis.praat:464` | tMatrix## is computed and documented but never reported; no df anywhere |
| D69 | CLARITY | **LIVE** | `stats/eml-analysis.praat:464` | rawP# computed and documented, never read by the reporter |
| D70 | CLARITY | **LIVE** | `stats/eml-analysis.praat:456` | No alpha echoed and no significance marking. Note: the dialog never had an Alpha field |
| D71 | CLARITY | **LIVE** | `stats/eml-analysis.praat:499` | Antisymmetric d matrix printed with no note that the sign encodes row-minus-column |
| D72 | GRAPHING | **LIVE** | `graphs/eml-annotation-procedures.praat:1583` | Diagonal and nonsignificant cells are the same grey dash; legend covers neither. Alpha IS stated |
| D73 | GRAPHING | **LIVE** | `graphs/eml-graph-procedures.praat:1475` | No unit heuristic exists; SPL_dB becomes "SPL dB" against hand-written "Frequency (Hz)" |
| D74 | CLARITY | **LIVE** | `stats/eml-output.praat:671` | Shared field block uses --- Options --- against every wrapper's box rule |
| D75 | CLARITY | **LIVE** | `stats/eml-analysis.praat:453` | Header prints lowercase bonferroni against a menu that reads Bonferroni |
| D76 | CLARITY | **LIVE** | `graphs/eml-annotation-procedures.praat:2760` | Single df column carries dfBetween; error df appears only in Tukey rows |
| D77 | ACCURACY | **LIVE** | `stats/eml-extract.praat:2109` | pre|post keyword still weight-6 for time; probe returns jitter_pre vs HNR_pre as the paired default |
| D78 | ACCURACY | **LIVE** | `stats/eml-extract.praat:2240` | No taken[] test on the no-group fallback; probe returns column 1 as both group and subject |
| D79 | CLARITY | **LIVE** | `graphs/eml-graphs-form.praat:1442` | Same 13 sites as D16; line untouched since the pre-audit commit |
| D82 | ACCURACY | **LIVE** | `scripts/eml-wizard.praat:985` | Condition slots still hardcoded indices 2/3/4 over an unfiltered column list; role guessing is jumped past |
| D83 | CLARITY | **LIVE** | `stats/eml-analysis.praat:1232` | Teardown half fixed by D93; the misleading message is intact and names no column |
| D84 | CLARITY | **CANNOT-TELL** | `scripts/eml-wizard.praat:810` | Block byte-identical since 2 August, no fix attempted; overlap is a GTK layout question needing a render |
| D85 | CLARITY | **LIVE** | `stats/eml-analysis.praat:1548` | RM path uses fixed$ not emlFormatP; fixed$(3.1e-29, 4) prints 29 decimals |
| D86 | ACCURACY | **LIVE** | `stats/eml-analysis.praat:1546` | No effect size of any kind on the repeated-measures path; no partial eta-squared, no Kendall's W |
| D87 | CLARITY | **LIVE** | `scripts/eml-wizard.praat:1744` | One wizCanDraw flag still gates both CSV and Draw; RM results get the two-button dialog |
| D88 | GRAPHING | **FIXED** | `graphs/eml-draw-procedures.praat:1326` | Every call site now passes a computed axisRoundTo from emlComputeNiceStep; the literal 10 is gone |
| D89 | GRAPHING | **LIVE** | `graphs/eml-graph-procedures.praat:1313` | Empty title draws nothing; no fallback composed from table, columns, test or p |
| D90 | GRAPHING | **LIVE** | `graphs/eml-graphs-form.praat:5241` | Spaghetti axes read Condition and Value; the real measure names reach only the tick labels |
| D91 | GRAPHING | **FIXED** | `graphs/eml-draw-procedures.praat:3041` | emlYAxisMinStep declared, guarded, honoured by four step procedures and released at HIST_END |
| D92 | GRAPHING | **FIXED** | `graphs/eml-graphs-form.praat:5448` | Annotated auto-range tracks visibleDataMin; the literal 0 floor is gone from the violin/box branch |
| D93 | CLARITY | **FIXED** | `stats/eml-output.praat:1106` | emlErrorDialog implements the ruling across 36 call sites; no bare pauseScript: error surface remains |
| D94 | CLARITY | **FIXED** | `scripts/eml-describe-table.praat:89` | All three sites read exitScript: ""; no bare exitScript remains in plugin/ |
| D95 | ACCURACY | **FIXED** | `graphs/eml-annotation-procedures.praat:3502` | Every judging site reads the shared constants; the missed D4 label is relabelled |

