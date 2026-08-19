<!-- GENERATED FILE. Do not edit. Regenerate with: python3 validate/tools/gen_findings_index.py -->

# Findings register — EML Stats & Graphs

**This file is generated from `audit/FINDINGS_MACHINE.json` and is a view of it, not a source.** Edits here are overwritten and are caught by `gen_findings_index.py --check`. To change what a row says, change the register. To say what an earlier record got wrong, add a dated entry to `FINDINGS_NARRATIVE.md` — that file is append-only and never states current status, because status is this file's only job.

- **session** — 2026-08-14 stress-test
- **build** — plugin@HEAD
- **praat** — 6.6.30
- **accuracy verdict** — zero numeric mismatches at printed precision

## Census

| status | rows | what the literal means |
|---|---:|---|
| `open` | 4 | A repair is owed here. Nothing in the tree fixes it. |
| `fixed-unpinned` | 9 | The backfill queue: a repair this project believes it made and cannot prove. Nothing would go red if it were undone. |
| `closed` | 40 | Repaired, and something live would notice the repair going away. Both halves, or it is not closed. |
| `superseded` | 2 | Never built. The work moved to a phase of the feature roadmap, and the row's pointer says which. |
| `refuted` | 1 | Somebody looked and there was no defect. The row's pointer says what they looked at. |
| **total** | **56** | |

`status` is not an editorial field: it is entailed by `fixedBy` and `pinnedBy` (and, where the hash cannot speak, by the `pointer` kind), and `validate/tools/check_findings_schema.py` recomputes it rather than reading it. `closed` cannot be typed.

## Rows

| id | sev | area | status | verdict | fixedBy | pinnedBy | title |
|---|---:|---|---|---|---|---|---|
| `RULE-28I` | 0 | refuted | `open` | REFUTED | — | — | Second save after separate-legend is byte-identical full figure — viewport restore correct |
| `D136` | 3 | graphing | `open` | CONFIRMED | — | — | @emlDrawLMMForest's extent tracker and its ink describe different rectangles: it erases without resetting the union, and draws at the raw origin while reporting at the panel origin |
| `D137` | 3 | process | `open` | CONFIRMED | — | — | The normality harness drives 360 decisions and writes 26 artefacts that no validator reads |
| `NEW-G8-2` | 3 | graphs | `open` | CONFIRMED | — | — | One-sided range (min only) silently swapped to (0,min) — inverts intent |
| `D66-b/c` | 0 | closed | `fixed-unpinned` | CLOSED | `pre-repo` | — | Wizard RM + Friedman CSVs export populated, one stem one stamp — CLOSED |
| `D98/D99` | 0 | closed | `fixed-unpinned` | CLOSED | `pre-repo` | — | Post-fix evidence captured on exact r2/r5 datasets — evidence gap CLOSED |
| `D97` | 2 | stats | `fixed-unpinned` | CONFIRMED | `pre-repo` | — | RM-ANOVA omnibus printed F(2,6) = 2.11e16 on an exactly-linear table instead of refusing a zero error term |
| `D88` | 3 | graphs | `fixed-unpinned` | CONFIRMED | `pre-repo` | — | Axis granularity hard-coded to 10, so any small-range measure is squashed into the bottom of the panel |
| `D110` | 3 | clarity | `fixed-unpinned` | CONFIRMED | `pre-repo` | — | Two p-value formats in one report -- the Tukey matrix printed 0.4918 while the Games-Howell matrix 35 lines below printed .584 |
| `D123` | 3 | graphs | `fixed-unpinned` | CONFIRMED | `pre-repo` | — | @emlDrawLegend had no entry cap -- a 21-group legend ran off the top of the frame |
| `D124` | 3 | graphs | `fixed-unpinned` | CONFIRMED | `pre-repo` | — | @emlDrawAnnotationBlock did not wrap -- on a narrow figure a long disclosure line made the box wide enough to sit over the data |
| `D126` | 3 | packaging | `fixed-unpinned` | CONFIRMED | `pre-repo` | — | The GUI harness recipe recommended `pkill -9 -f matchbox`, which kills the driving shell -- the same self-kill hazard the next line warned about for praat |
| `D134` | 3 | stats | `fixed-unpinned` | CONFIRMED | `pre-repo` | — | The wizard's normality gate was a stale hand-maintained copy of the eml-analysis.praat hierarchy, and two comments named a kurtosis threshold of 1 where the code used 7 |
| `D140` | 1 | graphing | `closed` | CONFIRMED | `9a5826fd0fec1dd05ac60b6ff9e2ede79b7b6ca8` | `v97` | The wide-format line chart stops at five series and says nothing about why |
| `NEW-G10-2` | 1 | editor | `closed` | CONFIRMED | `c112b7cc0e21720fefa0e8882aaf8be78fab0936` | `v55` | Delete Column removes first label match, not user's selection — silent wrong-column data loss |
| `D138` | 2 | graphing | `closed` | CONFIRMED | `9a5826fd0fec1dd05ac60b6ff9e2ede79b7b6ca8` | `v97` | A column can be drawn as a left-hand series and as the right-axis series at once |
| `D139` | 2 | graphing | `closed` | CONFIRMED | `9a5826fd0fec1dd05ac60b6ff9e2ede79b7b6ca8` | `v97` | No key is drawn when a second axis is on and the left-hand side is ungrouped |
| `LANE-B-1` | 2 | stats | `closed` | CONFIRMED | `2f1cd7dbd30a7fb6c16ed03b30995b40e77508fc` | `v90, v93` | Alpha kernels accumulated variance without centering, so a column with a large offset lost precision to cancellation |
| `NEW-G1-1` | 2 | export | `closed` | CONFIRMED | `a4de0eecaa5b96e6d6113b69f041b99faaaadf62` | `v57` | Multi-column normality Save exports only last column to tidy/glance |
| `NEW-G2-1` | 2 | save | `closed` | CONFIRMED | `a4de0eecaa5b96e6d6113b69f041b99faaaadf62` | `v56` | Slash in Save base name aborts wrapper session, raw error points at dead window |
| `NEW-G3-1` | 2 | stats | `closed` | CONFIRMED | `c112b7cc0e21720fefa0e8882aaf8be78fab0936` | `v60` | Paired wrapper New-after-Draw rebinds to deleted reshape table — dead end |
| `NEW-G7-2` | 2 | graphs | `closed` | CONFIRMED | `7f62e751783ecb52df2d9bab961bec39e000213a` | `v62` | Stereo channel handling unreachable from EML Graphs |
| `NEW-G9-1` | 2 | graphs | `closed` | CONFIRMED | `7f62e751783ecb52df2d9bab961bec39e000213a` | `v61` | Annotated KW draw crashes when omnibus significant — whole graphs session lost |
| `NEW-G10-1` | 2 | editor | `closed` | CONFIRMED | `c112b7cc0e21720fefa0e8882aaf8be78fab0936` | `v55` | Rename Column accepts existing name — creates duplicate headers, no warning |
| `NEW-G10-3` | 2 | editor | `closed` | PARTIAL | `c112b7cc0e21720fefa0e8882aaf8be78fab0936` | `v55` | One-column Delete bypasses guard; raw error; session aborted; orphaned read-only TableEditor |
| `NEW-G11-2` | 2 | recorder | `closed` | CONFIRMED | `a4de0eecaa5b96e6d6113b69f041b99faaaadf62` | `v58` | Recorded advanced figure replays without annotation bracket + jittered points |
| `NEW-G12-1` | 2 | entry | `closed` | CONFIRMED | `a4de0eecaa5b96e6d6113b69f041b99faaaadf62` | `v56, v59` | Matrix + unlabeled TableOfReal action buttons crash before dialog (11 registered entry points) |
| `NEW-G12-5` | 2 | save | `closed` | CONFIRMED | `a4de0eecaa5b96e6d6113b69f041b99faaaadf62` | `v56` | Unwritable folder kills post-analysis cascade with raw internals (verifier raised 3->2) |
| `D1/D2` | 3 | unification | `closed` | CONFIRMED-LIVE | `7f62e751783ecb52df2d9bab961bec39e000213a` | `v61` | Custom X/Y axis labels persisted, never restored — lost in-session |
| `D5` | 3 | unification | `closed` | CONFIRMED-LIVE | `0e0c0fad999c4c9242dc6b60d068ad823c991bc3` | `v61` | Adjustment menu ignored on parametric (Tukey) annotation arm — Holm/Bonferroni pixel-identical |
| `D7` | 3 | unification | `closed` | CONFIRMED-LIVE | `7f62e751783ecb52df2d9bab961bec39e000213a` | `v61` | Wrapper annotate preset hard-reset by every beginner Draw commit |
| `D8` | 3 | unification | `closed` | CONFIRMED-LIVE | `7f62e751783ecb52df2d9bab961bec39e000213a` | `v61` | Legend placement commits only in advanced — Separate leaks unrequested _legend.png into beginner save |
| `D11` | 3 | graphs | `closed` | CONFIRMED-LIVE | `7f62e751783ecb52df2d9bab961bec39e000213a` | `v61` | Group column/order active while Use-group unchecked, value discarded |
| `D12` | 3 | stats | `closed` | CONFIRMED-LIVE | `c112b7cc0e21720fefa0e8882aaf8be78fab0936` | `v49` | Describe Table column: no Save, no Clear-Info, no completion dialog |
| `D125` | 3 | stats | `closed` | CONFIRMED | `pre-repo` | `v28` | @emlPairwiseT and @emlPairwiseWilcoxon returned an empty error and a matrix of undefined on an all-blank column -- a verdict-less gap at the library layer |
| `D135` | 3 | graphs | `closed` | CONFIRMED | `pre-repo` | `v32` | The legend overhung the frame on a single label wider than the whole frame -- the legend's copy of D124 |
| `NEW-G2-2` | 3 | clarity | `closed` | CONFIRMED | `7f62e751783ecb52df2d9bab961bec39e000213a` | `v62` | Mann-Whitney U1 glossed as 'Sum of ranks' — wrong term, number correct |
| `NEW-G4-1` | 3 | export | `closed` | CONFIRMED | `a4de0eecaa5b96e6d6113b69f041b99faaaadf62` | `v57` | ANOVA augment exports non-broom values under broom's .std.resid name; leverage missing |
| `NEW-G6-1` | 3 | clarity | `closed` | CONFIRMED | `a4de0eecaa5b96e6d6113b69f041b99faaaadf62` | `v57` | RM/Friedman refusal diagnosis computed on silently halved complete-case sample |
| `NEW-G7-1` | 3 | graphs | `closed` | CONFIRMED | `7f62e751783ecb52df2d9bab961bec39e000213a` | `v62` | Steady phonation draws as fluctuating contour over collapsed axis (verifier 2->3) |
| `NEW-G8-1` | 3 | graphs | `closed` | CONFIRMED | `7f62e751783ecb52df2d9bab961bec39e000213a` | `v62` | Out-of-range points drawn unclipped outside plot frame |
| `NEW-G8-3` | 3 | export | `closed` | CONFIRMED | `7f62e751783ecb52df2d9bab961bec39e000213a` | `v61` | Duplicate result block appended per Draw in one graphs session |
| `NEW-G8-4` | 3 | graphs | `closed` | CONFIRMED | `7f62e751783ecb52df2d9bab961bec39e000213a` | `v62` | Annotation panel hides datum; dotted ghost bleeds through text |
| `NEW-G10-4` | 3 | checkdata | `closed` | CONFIRMED | `c112b7cc0e21720fefa0e8882aaf8be78fab0936` | `v60` | File mode says 'No import problems found' on ragged CSV Praat then refuses |
| `NEW-G11-1` | 3 | recorder | `closed` | CONFIRMED | `d5a434b920eb58b219ac2b5eb4831cee9672fe37` | `v58` | Emitted script header claims home-relative portability; include block machine-absolute |
| `NEW-G11-3` | 3 | recorder | `closed` | CONFIRMED | `a4de0eecaa5b96e6d6113b69f041b99faaaadf62` | `v58` | Stale duplicate recordMeta stamps later emission with dead session's timestamp (verifier 2->3) |
| `NEW-G11-4` | 3 | recorder | `closed` | CONFIRMED | `c112b7cc0e21720fefa0e8882aaf8be78fab0936` | `v58` | Stop-and-save onto missing folder leaks raw internals, points at closed window |
| `NEW-G12-2` | 3 | entry | `closed` | CONFIRMED | `a4de0eecaa5b96e6d6113b69f041b99faaaadf62` | `v59, v63` | Coercion crash strands temp objects incl. Table shadowing source name |
| `NEW-G12-3` | 3 | clarity | `closed` | CONFIRMED | `a4de0eecaa5b96e6d6113b69f041b99faaaadf62` | `v57` | Zero-variance refusal buried in report under 'Analysis complete' modal with Save/Draw/New |
| `D4` | 4 | unification | `closed` | CONFIRMED-LIVE | `7f62e751783ecb52df2d9bab961bec39e000213a` | `v61` | Scatter dot-size/show-dots preset channel has no producer |
| `D6` | 4 | graphs | `closed` | CONFIRMED-LIVE | `7f62e751783ecb52df2d9bab961bec39e000213a` | `v61` | Histogram/GroupedViolin/GroupedBox force Matrix layout, no field offered |
| `NEW-G12-4` | 4 | clarity | `closed` | CONFIRMED | `c112b7cc0e21720fefa0e8882aaf8be78fab0936` | `v60` | Pre-dialog refusals leak raw exitScript stack noise (verifier 3->4; wording accurate) |
| `SAVED-OVERPRINT` | 4 | polish | `closed` | CONFIRMED | `a4de0eecaa5b96e6d6113b69f041b99faaaadf62` | `v56` | 'Saved' receipt overprints wrapped path lines — five sightings, one cause |
| `D40` | 3 | stats | `superseded` | CONFIRMED-LIVE | — | — | No interaction plot; two-way Draw goes to Grouped Violin |
| `D38` | 4 | stats | `superseded` | CONFIRMED-LIVE | — | — | Simple effects still absent post two-way (caution half works) |
| `D15` | 0 | refuted | `refuted` | REFUTED | — | — | Paired 'Group' literal targets its own reshaped table which always has that column |

## Rows in full

### `RULE-28I` — Second save after separate-legend is byte-identical full figure — viewport restore correct

`open` · severity 0 · refuted · verdict REFUTED · fixedBy *(empty)* · pinnedBy *(empty)*

### `D136` — @emlDrawLMMForest's extent tracker and its ink describe different rectangles: it erases without resetting the union, and draws at the raw origin while reporting at the panel origin

`open` · severity 3 · graphing · verdict CONFIRMED · fixedBy *(empty)* · pinnedBy *(empty)*

**Mechanism.** Two halves, both in @emlDrawLMMForest, graphs/eml-draw-procedures.praat. (1) It calls `Erase all` and never @emlResetDrawnExtent, so a union accumulated by an earlier figure survives the erase it has just performed and @emlAssertFullViewport then saves a rectangle larger than the ink. (2) Both its viewport selections are `Select outer viewport: 0, .figW, 0, .figH`, raw, while the @emlSetAdaptiveTheme call between them reports the panel at emlPanelOriginX/emlPanelOriginY to @emlExpandDrawnExtent -- so under a non-zero panel origin the tracker records one rectangle and the ink lands in another. Anchors rather than line numbers: `grep -n 'procedure emlDrawLMMForest' plugin_EML_StatsGraphs/graphs/eml-draw-procedures.praat`, then the `Erase all` and the two raw viewport lines inside that procedure.

**Measured.** Driven 18 Aug 2026 on Praat 6.6.30 by setting emlLMM.*, emlWaldCI.* and emlModelMatrix.colName*$ directly and calling the procedure. (1) A 6 x 9 box plot drawn first leaves the union at 0..6 x 0..9; the forest then erases the page, draws 6.5 x 3.1, and the union still reads 0..6.5 x 0..9 -- 5.9 inches of the saved image is page the erase had already cleared. (2) With @emlSetPanelOrigin: 3, 2 the tracker reads 3..9.5 x 2..5.1 while the ink is at 0..6.5 x 0..3.1; the rectangle @emlAssertFullViewport selects carries 0.443% ink against the drawn rectangle's 1.693%, so the saved figure is a crop of the overlap.

**Reach.** LATENT AND API-REACHABLE. The plugin's only call site is scripts/eml-lmm.praat, which draws the forest as the last thing it does, on a fresh page at the default origin -- where both halves are inert, because the union it fails to reset is its own and the origin it ignores is 0, 0. Both halves go live for a user script or a PraatGen companion that draws a figure, or sets a panel origin, and then calls @emlDrawLMMForest; page composition (63f9b1f) makes a non-zero origin an ordinary thing for a session to be carrying.

**Deferral.** THE FIX IS DEFERRED TO THE MIXED-MODEL PHASE BY AUTHOR RULING, 18 August 2026. Pinning it means driving the forest plot from a fitted model, which needs the test machinery that phase builds, and a fix landed now would be unpinned -- which is the category this ledger exists to drain. The repair is already written elsewhere in the tree: @emlBeginPanel in graphs/eml-graph-procedures.praat does the erase, the extent reset and the origin as one decision, and the viewport selections become origin-offset the way @emlGraphsDispatchDraw's and @emlDrawQQPlot's now are. validate/v94's Erase-all census names this procedure so the inventory states the truth rather than the intention.

### `D137` — The normality harness drives 360 decisions and writes 26 artefacts that no validator reads

`open` · severity 3 · process · verdict CONFIRMED · fixedBy *(empty)* · pinnedBy *(empty)*

**Mechanism.** Four files in harness/normality named validate/v32_normality_parity.R as their consumer. That validator was never built -- v32 is the legend-geometry validator -- and nothing took its place, so the rig runs, commits its output, and is checked by nothing. The comments now say so; the gap itself is open. Same shape as the evidence audit's wider finding that 451 of 637 files under evidence/ have no reader.

**Pointer.** evidence: harness/normality/run.sh named validate/v32_normality_parity.R as this rig's consumer. That file has never existed and validate/v32 is the legend-geometry validator. Three sibling files carried the same claim. Measured 18 Aug 2026: no file under validate/ references harness/normality by path, so RESULTS.tsv, decision.csv and the 24 logs beside them are committed and unchecked.

### `NEW-G8-2` — One-sided range (min only) silently swapped to (0,min) — inverts intent

`open` · severity 3 · graphs · verdict CONFIRMED · fixedBy *(empty)* · pinnedBy *(empty)*

**Mechanism.** S13 swap block, no warning

### `D66-b/c` — Wizard RM + Friedman CSVs export populated, one stem one stamp — CLOSED

`fixed-unpinned` · severity 0 · closed · verdict CLOSED · fixedBy `pre-repo` · pinnedBy *(empty)*

**Pointer.** evidence: validate/v21_shipping_paths_broom.R:231-266 the two BUILD paths that exported nothing before the repair are checked populated here — RM tidy exists at all (:238) and the Friedman tidy/glance numbers against R (:257-266). Present in this tree at the root import 9b7d5aa, 12 Aug 2026, which is the earliest in-repo evidence there can be; the repair itself was made 6 Aug, before the repository existed. This is a witness statement over the committed exports under evidence/csv_export/broom, covering the populated-export half of the title, and it is NOT a pin: a revert of plugin/ leaves those CSVs saying what they said.

### `D98/D99` — Post-fix evidence captured on exact r2/r5 datasets — evidence gap CLOSED

`fixed-unpinned` · severity 0 · closed · verdict CLOSED · fixedBy `pre-repo` · pinnedBy *(empty)*

**Pointer.** evidence: validate/v07_redpath_degenerate_inputs.R:306-354 R2 checks D98's caution in the committed r2 capture (:306, with its placement and wording asserted on the lines below it) and R5 attests D99's groups-vs-rows refusal (:354) against evidence/shots/d99_r5_refusal_names_diagnosis.png. Present in this tree at the root import 9b7d5aa, 12 Aug 2026; both repairs were made 6 Aug and re-driven, and what the 14 Aug session closed was the evidence gap rather than code. A witness statement, not a pin: neither line executes plugin/ source.

### `D97` — RM-ANOVA omnibus printed F(2,6) = 2.11e16 on an exactly-linear table instead of refusing a zero error term

`fixed-unpinned` · severity 2 · stats · verdict CONFIRMED · fixedBy `pre-repo` · pinnedBy *(empty)*

**Mechanism.** the omnibus did not test the error term; the same run's post-hoc caught the identical condition and refused, so the check existed in the module and the omnibus did not call it The validators previously named here read committed captures and execute nothing, so by this project's own definition they are witness statements rather than pins; the repair stands, the guard does not exist.

**Pointer.** evidence: validate/v07_redpath_degenerate_inputs.R:249-256 R1 first proves the driven table really has a zero subject-by-condition residual, then asserts the capture contains no F and no p at all -- the refusal, read as an absence, on the one input that used to produce the 2.11e16. Present in this tree at the root import 9b7d5aa, 12 Aug 2026; the repair is dated 6 Aug 2026.

**Measured.** The repair is live in the shipped tree, not merely captured: stats/eml-analysis.praat:3080 refuses on `.ssErr <= 1e-10 * .ssTot`, and the comment at :3065 states why the floor has to be RELATIVE -- the residual on the filed case sits at ~1e-16 of the total, so an equality test against zero would not have fired. Prose and source agree; the index row at :279 is confirmed rather than corrected.

### `D88` — Axis granularity hard-coded to 10, so any small-range measure is squashed into the bottom of the panel

`fixed-unpinned` · severity 3 · graphs · verdict CONFIRMED · fixedBy `pre-repo` · pinnedBy *(empty)*

**Mechanism.** @emlComputeAxisRange's .roundTo argument passed the literal 10 at 12 of 17 call sites; the adaptive form already existed at the scatter site and was never propagated The validators previously named here read committed captures and execute nothing, so by this project's own definition they are witness statements rather than pins; the repair stands, the guard does not exist.

**Pointer.** evidence: validate/v07_redpath_degenerate_inputs.R:196-203 the R7 drive reads the axis @emlDrawSpaghettiPlot actually used out of evidence/info/v07_r7_axis_info.txt and asserts it is NOT the 0-10 grid, plus the data's fraction of the panel against the fraction computed here from the fixture. Present in this tree at the root import 9b7d5aa, 12 Aug 2026; the repair itself is dated 5 Aug 2026, before this repository existed.

**Measured.** SOURCE BEATS PROSE ON THE SCOPE. FINDINGS_INDEX.md:270 said "FIXED at 10 sites, verified by drive; 2 F0 sites left by design". plugin_EML_StatsGraphs/dev/FIX_NOTES.md:137 says the propagation was completed the same day -- "All 16 @emlComputeAxisRange call sites now derive their granularity from the data. No literal remains" -- and the tree agrees: measured 18 Aug 2026, every @emlComputeAxisRange call in graphs/ passes a .roundTo derived from @emlComputeNiceStep, and the only literal granularities left anywhere in the plugin are three in scripts/eml-stats-demo.praat, a demo script that draws its own figures and is not a draw procedure. The two F0 sites the index says were left by design were made adaptive; what was left literal is the pair of histogram sites, and that is D91's business, not this row's.

### `D110` — Two p-value formats in one report -- the Tukey matrix printed 0.4918 while the Games-Howell matrix 35 lines below printed .584

`fixed-unpinned` · severity 3 · clarity · verdict CONFIRMED · fixedBy `pre-repo` · pinnedBy *(empty)*

**Mechanism.** fixed$ (p, 4) in the Tukey and Dunn matrices and fixed$ (p, 6) in the one-way source table, against @emlFormatP.bare$ elsewhere; all in graphs/eml-annotation-procedures.praat The validators previously named here read committed captures and execute nothing, so by this project's own definition they are witness statements rather than pins; the repair stands, the guard does not exist.

**Pointer.** evidence: validate/v25_anova_showboth.R:158-186 asserts FORM rather than value -- every off-diagonal cell of both post-hoc matrices, and the source table's p cell, must be bare APA or one of the ceiling/floor/undefined literals, so a regression that put fixed$ back would leave every number correct and still fail here. v09 and v10 carry the re-driven captures and PROVENANCE blocks (v09:27-36, v10:31-40). Present at the root import 9b7d5aa; the repair is dated 7 Aug 2026.

**Measured.** Prose and source agree. The index row at :292 also records the cost that made this worth filing rather than sweeping -- moving the format moved numbers v09 and v10 read out of committed captures -- and the re-drive it forced is what surfaced that those captures were four revisions stale.

### `D123` — @emlDrawLegend had no entry cap -- a 21-group legend ran off the top of the frame

`fixed-unpinned` · severity 3 · graphs · verdict CONFIRMED · fixedBy `pre-repo` · pinnedBy *(empty)*

**Mechanism.** single-column layout with no measurement against the frame; the same shape as the annotation-block overflow, in the other box The validators previously named here read committed captures and execute nothing, so by this project's own definition they are witness statements rather than pins; the repair stands, the guard does not exist.

**Pointer.** evidence: validate/v32_legend_geometry.R:1043-1091 pins the single-column promise D123 made -- one entry, or any count that fits one column, keeps the previous geometry to the pixel -- and the box width, height, column count, rows per column and shown count per figure size, so a layout that started sizing by entry count rather than by widest label would show even while still fitting. v36_stress_output.R:813-870 holds containment on the saved PNG from the other side. Present at the root import 9b7d5aa; the repair is dated 8 Aug 2026.

**Measured.** Live in the shipped tree: graphs/eml-graph-procedures.praat:4686-4703 computes .rowsMax and .colsMax from the rectangle and :4695 builds the "+N more" cell, with :4761 sending the NOTE to the Info window so truncation is never silent. Prose and source agree; the index row at :304 also names the case the layout deliberately did not take, which is D135.

### `D124` — @emlDrawAnnotationBlock did not wrap -- on a narrow figure a long disclosure line made the box wide enough to sit over the data

`fixed-unpinned` · severity 3 · graphs · verdict CONFIRMED · fixedBy `pre-repo` · pinnedBy *(empty)*

**Mechanism.** the box was sized from the text rather than from the frame, so a 5-line block on a 4-bar chart spanned 0.981 of the axis range and covered 28 data pixels

**Pointer.** evidence: plugin_EML_StatsGraphs/graphs/eml-annotation-procedures.praat:1225-1250 the width budget is now a share of the frame (emlAnnotBlockWidthShare, default 0.55) with every entry wrapped through @emlWrapText against it, and the header above states why a character-count rule cannot bound the box: 50 characters is seven eighths of the panel at every figure size. The height guard at the same site is what stops wrapping from pushing the box off the bottom instead. Present at the root import 9b7d5aa; the repair is dated 8 Aug 2026.

**Measured.** SOURCE BEATS PROSE ON THE STATUS. FINDINGS_INDEX.md:305 reads "RESOLVED (8 Aug) ... CLOSED", but closed in this register requires a pin as well as a fix, and there is none: measured 18 Aug 2026, no file under validate/ asserts the annotation block's WIDTH against the frame. v29_figure_disclosure.R:856-878 is the nearest thing and it bounds the block's LINE COUNT (the 20-line budget), which is the vertical defect and not this one; v56 and v71 assert @emlWrapText at other call sites entirely. So this row is the backfill queue, not a closure: revert the share and nothing in the suite goes red. The fix is real and the pin is owed.

### `D126` — The GUI harness recipe recommended `pkill -9 -f matchbox`, which kills the driving shell -- the same self-kill hazard the next line warned about for praat

`fixed-unpinned` · severity 3 · packaging · verdict CONFIRMED · fixedBy `pre-repo` · pinnedBy *(empty)*

**Mechanism.** -f matches the pattern against every process's entire command line, including that of the shell running the command; it fired for real, exit 144 (128+16, SIGTERM)

**Pointer.** evidence: harness/GUI_HARNESS_RECIPE.md:10-16 the rule is stated ONCE at the top of the document -- every pkill/pgrep in this harness uses -x, none uses -f -- so a new teardown snippet inherits it rather than needing the fix repeated per site. Measured 18 Aug 2026: every pkill/pgrep INVOCATION in the recipe and in the eight harness run.sh files that quote it is the -x exact-name form; the surviving -f mentions are the NEVER column of the standing-rule table (:21-23), the reproduction of the hazard (:33-46) and the diagnosis table (:235-241) -- prohibitions, not instructions. Present at the root import 9b7d5aa; the repair is dated 8 Aug 2026.

**Measured.** SOURCE BEATS PROSE ON THE STATUS. FINDINGS_INDEX.md:307 reads "RESOLVED (8 Aug) ... CLOSED". The fix is present and I measured it, but nothing holds it: no file under validate/ reads GUI_HARNESS_RECIPE.md (v85 and v72 only mention it in comments), so a `-f` reintroduced into a teardown snippet tomorrow would be caught by nothing. Unpinned, and the pin is a grep, which is the cheapest one this queue is owed.

### `D134` — The wizard's normality gate was a stale hand-maintained copy of the eml-analysis.praat hierarchy, and two comments named a kurtosis threshold of 1 where the code used 7

`fixed-unpinned` · severity 3 · stats · verdict CONFIRMED · fixedBy `pre-repo` · pinnedBy *(empty)*

**Mechanism.** @wizardNormDiag gated on `.skKurtFail or .swFail` while the comment above it claimed parity with the hierarchy that replaced that rule on 5 Aug; 4000 random samples found 0 divergent cases at the shipped thresholds, so it was structural rather than demonstrated

**Pointer.** evidence: plugin_EML_StatsGraphs/scripts/eml-wizard.praat:2218-2249 the rule is not restated in the wizard at all: @wizardNormDiag calls @emlNormalityRecommendation and reads .shapeSevere, .swUsable, .swFail and .largeNOverride back off it, and the comment at :2218-2226 says the hand-maintained second copy stood until 8 August. The thresholds print from emlSkewThreshold and emlKurtosisThreshold at :2256-2262 rather than being spelled out, and `grep -rn 'kurtosis threshold' plugin_EML_StatsGraphs/` returns nothing outside dev/HISTORY_LEDGER.md's quotations of the old text. Present at the root import 9b7d5aa; the repair is dated 8 Aug 2026.

**Measured.** SOURCE BEATS PROSE ON THE MECHANISM AND ON THE STATUS, IN OPPOSITE DIRECTIONS. FINDINGS_INDEX.md:315 says the gate "now mirrors the eml-analysis.praat hierarchy branch for branch" and calls the row CLOSED. The tree says the mirror was DELETED, not corrected: the wizard calls the shared procedure, which is a strictly stronger repair than the one the prose credits, and the third copy the prose does not mention -- the per-group branch of scripts/eml-check-normality.praat, which had drifted to hard-coded thresholds and the retired gate -- is named at :2222-2224 as the reason. The 14 August ruling calls this row `superseded` for that reason. It is filed `fixed-unpinned` instead, because `superseded` is not a synonym in this register: it is entailed by a `roadmap:` pointer, it means the work MOVED to a roadmap phase and was never built, and it forbids both fixedBy and pinnedBy. Work was built here and it is in the tree, so the honest literal is the one that admits the fix and admits the missing pin. And the pin is missing: measured 18 Aug 2026, no file under validate/ reads @emlNormalityRecommendation or asserts that the wizard delegates to it. v65_display_standard.R drives @wizardNormDiag but asserts number FORMATTING, and v15 asserts the shared rule at the orchestrator layer, not the wizard's use of it -- so restoring a private copy in the wizard would turn nothing red.

### `D140` — The wide-format line chart stops at five series and says nothing about why

`closed` · severity 1 · graphing · verdict CONFIRMED · fixedBy `9a5826fd0fec1dd05ac60b6ff9e2ede79b7b6ca8` · pinnedBy `v97`

**Mechanism.** Five hardcoded option menus, Series 1 to Series 5. A user with six columns finds the list simply ends. The ceiling is the dialog's rather than the chart's — the long-format path on the same page takes as many series as the grouping column holds — and it is not a Praat constraint either: field declarations execute inside an open beginPause block, so the slots can be built from the columns that exist. Fixed by the restructure, where the slots no longer exist to overflow.

**Pointer.** evidence: plugin_EML_StatsGraphs/graphs/eml-graphs-form.praat declares Series 1 through Series 5 as five separate optionmenu fields. Found by Ian reading the photographed dialog at harness/dialogheight/out/advanced/t5_3_Line_Chart_Column_Mapping.png. pinned by v97 -- [seven] seven tickboxes built and read back, seven hues on the page, the tickbox loop bounded by the table with no numeric cap; break melt_ceiling_five puts 4 red.

### `NEW-G10-2` — Delete Column removes first label match, not user's selection — silent wrong-column data loss

`closed` · severity 1 · editor · verdict CONFIRMED · fixedBy `c112b7cc0e21720fefa0e8882aaf8be78fab0936` · pinnedBy `v55`

**Mechanism.** eml-edit-table.praat:522 name-based Remove column; optionmenu index discarded; all editor ops name-addressed (:148,:178,:287-386)

### `D138` — A column can be drawn as a left-hand series and as the right-axis series at once

`closed` · severity 2 · graphing · verdict CONFIRMED · fixedBy `9a5826fd0fec1dd05ac60b6ff9e2ede79b7b6ca8` · pinnedBy `v97`

**Mechanism.** The guard compares the second-axis column against valueColName only, which is one column. In wide format the left side is a list of series columns, so choosing one of those for the right axis passes and the column is drawn twice: once against a scale where it reads as a flat line, once against its own. Fixed by the question-tree restructure, where the right-hand series is chosen from series not already drawn — impossible by construction rather than refused by a guard.

**Pointer.** evidence: harness/secondaxis/out/melt_carry.png shows cq drawn as an orange left-hand series flat along zero and again as the green right-axis series, with the key naming both. Found by Ian reading the figure; v95 passed 145 checks on it, having asked whether the column was carried into the melt correctly and never whether drawing it twice made sense. pinned by v97 -- [meas2] the right-hand axis is chosen from the two measurements already chosen, so the left-hand column is the OTHER one; break right_col_free puts 4 red.

### `D139` — No key is drawn when a second axis is on and the left-hand side is ungrouped

`closed` · severity 2 · graphing · verdict CONFIRMED · fixedBy `9a5826fd0fec1dd05ac60b6ff9e2ede79b7b6ca8` · pinnedBy `v97`

**Mechanism.** The legend block sits inside the grouped branch, so a grouped figure names each group plus the right-hand series tagged (right axis), while an ungrouped primary with a second series gets no key at all. That is the figure that needs one most: two unlabelled lines on two scales is exactly the ambiguity the tag exists to prevent. Fixed by the restructure, where a key appears whenever two or more series are on the page.

**Pointer.** evidence: harness/secondaxis/out/auto_pair.png and typed_pair.png carry two series on two scales and no key; grouped_pair.png carries the key correctly. Found by Ian comparing the driven figures. pinned by v97 -- [meas2] the ungrouped two-scale figure carries a two-entry key and the right-hand entry is tagged; break key_grouped_only puts 8 red.

### `LANE-B-1` — Alpha kernels accumulated variance without centering, so a column with a large offset lost precision to cancellation

`closed` · severity 2 · stats · verdict CONFIRMED · fixedBy `2f1cd7dbd30a7fb6c16ed03b30995b40e77508fc` · pinnedBy `v90, v93`

**Mechanism.** Sum-of-squares accumulated from the raw values rather than from values centered on the column mean. On ordinary questionnaire responses the loss is invisible; on a column carrying a large constant offset the subtraction of two nearly equal large numbers throws away most of the significant digits, and the reliability figure degrades quietly. Found by a stress battery in the lane before merge.

### `NEW-G1-1` — Multi-column normality Save exports only last column to tidy/glance

`closed` · severity 2 · export · verdict CONFIRMED · fixedBy `a4de0eecaa5b96e6d6113b69f041b99faaaadf62` · pinnedBy `v57`

**Mechanism.** @emlCSVInit at eml-analysis.praat:2365 called per column-loop iteration

### `NEW-G2-1` — Slash in Save base name aborts wrapper session, raw error points at dead window

`closed` · severity 2 · save · verdict CONFIRMED · fixedBy `a4de0eecaa5b96e6d6113b69f041b99faaaadf62` · pinnedBy `v56`

**Mechanism.** flush via eml-result-writer.praat:520 through @emlSavePanel; no base-name sanitization

### `NEW-G3-1` — Paired wrapper New-after-Draw rebinds to deleted reshape table — dead end

`closed` · severity 2 · stats · verdict CONFIRMED · fixedBy `c112b7cc0e21720fefa0e8882aaf8be78fab0936` · pinnedBy `v60`

**Mechanism.** reshape table deleted after Draw; form reopens against it

### `NEW-G7-2` — Stereo channel handling unreachable from EML Graphs

`closed` · severity 2 · graphs · verdict CONFIRMED · fixedBy `7f62e751783ecb52df2d9bab961bec39e000213a` · pinnedBy `v62`

**Mechanism.** @emlHandleStereo/@emlCheckChannels/@emlApplyChannelChoice eml-graph-procedures.praat:3876-3942, zero callers

### `NEW-G9-1` — Annotated KW draw crashes when omnibus significant — whole graphs session lost

`closed` · severity 2 · graphs · verdict CONFIRMED · fixedBy `7f62e751783ecb52df2d9bab961bec39e000213a` · pinnedBy `v61`

**Mechanism.** Unknown variable emlKruskalWallis.rMatrix## on significant branch

### `NEW-G10-1` — Rename Column accepts existing name — creates duplicate headers, no warning

`closed` · severity 2 · editor · verdict CONFIRMED · fixedBy `c112b7cc0e21720fefa0e8882aaf8be78fab0936` · pinnedBy `v55`

**Mechanism.** eml-edit-table.praat:553-559 only non-empty check

### `NEW-G10-3` — One-column Delete bypasses guard; raw error; session aborted; orphaned read-only TableEditor

`closed` · severity 2 · editor · verdict PARTIAL · fixedBy `c112b7cc0e21720fefa0e8882aaf8be78fab0936` · pinnedBy `v55`

**Mechanism.** guard :499 checks <1, should be <=1; wedged-form clause refuted

### `NEW-G11-2` — Recorded advanced figure replays without annotation bracket + jittered points

`closed` · severity 2 · recorder · verdict CONFIRMED · fixedBy `a4de0eecaa5b96e6d6113b69f041b99faaaadf62` · pinnedBy `v58`

**Mechanism.** emission omits advanced settings; stats/eml-record.praat emit path

### `NEW-G12-1` — Matrix + unlabeled TableOfReal action buttons crash before dialog (11 registered entry points)

`closed` · severity 2 · entry · verdict CONFIRMED · fixedBy `a4de0eecaa5b96e6d6113b69f041b99faaaadf62` · pinnedBy `v56, v59`

**Mechanism.** setup.praat registrations; S22 coercion in @emlWrapperInit

### `NEW-G12-5` — Unwritable folder kills post-analysis cascade with raw internals (verifier raised 3->2)

`closed` · severity 2 · save · verdict CONFIRMED · fixedBy `a4de0eecaa5b96e6d6113b69f041b99faaaadf62` · pinnedBy `v56`

**Mechanism.** no writability validation before flush

### `D1/D2` — Custom X/Y axis labels persisted, never restored — lost in-session

`closed` · severity 3 · unification · verdict CONFIRMED-LIVE · fixedBy `7f62e751783ecb52df2d9bab961bec39e000213a` · pinnedBy `v61`

**Mechanism.** config_xLabel$/yLabel$ written+parsed, zero reads

### `D5` — Adjustment menu ignored on parametric (Tukey) annotation arm — Holm/Bonferroni pixel-identical

`closed` · severity 3 · unification · verdict CONFIRMED-LIVE · fixedBy `0e0c0fad999c4c9242dc6b60d068ad823c991bc3` · pinnedBy `v61`

**Mechanism.** self-documented eml-graphs-form.praat:2777-2787

### `D7` — Wrapper annotate preset hard-reset by every beginner Draw commit

`closed` · severity 3 · unification · verdict CONFIRMED-LIVE · fixedBy `7f62e751783ecb52df2d9bab961bec39e000213a` · pinnedBy `v61`

**Mechanism.** 6 commit sites reset annotate=0; rescue only in toggle branch

### `D8` — Legend placement commits only in advanced — Separate leaks unrequested _legend.png into beginner save

`closed` · severity 3 · unification · verdict CONFIRMED-LIVE · fixedBy `7f62e751783ecb52df2d9bab961bec39e000213a` · pinnedBy `v61`

**Mechanism.** @emlCommitLegendPlacement gated on showAdvanced

### `D11` — Group column/order active while Use-group unchecked, value discarded

`closed` · severity 3 · graphs · verdict CONFIRMED-LIVE · fixedBy `7f62e751783ecb52df2d9bab961bec39e000213a` · pinnedBy `v61`

**Mechanism.** scatterGroupCol$='' :5525

### `D12` — Describe Table column: no Save, no Clear-Info, no completion dialog

`closed` · severity 3 · stats · verdict CONFIRMED-LIVE · fixedBy `c112b7cc0e21720fefa0e8882aaf8be78fab0936` · pinnedBy `v49`

**Mechanism.** only wrapper with neither; vs 14-Aug export ruling

### `D125` — @emlPairwiseT and @emlPairwiseWilcoxon returned an empty error and a matrix of undefined on an all-blank column -- a verdict-less gap at the library layer

`closed` · severity 3 · stats · verdict CONFIRMED · fixedBy `pre-repo` · pinnedBy `v28`

**Mechanism.** D116 gave both a PRESENCE guard and not a TYPE guard; unreachable through the menus because @emlRunPairwiseAnalysis refuses upstream, so no number was ever produced and none could be mistaken for a result

**Pointer.** evidence: validate/v28_column_type_guard.R:976-980 the pin is now the refusal verbatim, and deliberately the SAME sentence @emlTwoWayAnova gives for the same column, so a drift in either would have to be a drift in @emlAuditColumn's wording. The n02 loop above it (:941-955) covers all ELEVEN library sites and the SILENT_ON_EMPTY exemption list is gone rather than shortened. Present at the root import 9b7d5aa; the repair is dated 8 Aug 2026.

**Measured.** SOURCE BEATS PROSE. FINDINGS_INDEX.md:306 still reads "**LIVE 7 Aug**" and describes v28 as pinning the gap AS SILENT so it fails the day anyone closes it. Somebody closed it: v28's own header at :112-140 says "This is that day", both procedures now call @emlRequireNumericColumn with .strict = 0 immediately after the presence check, and the two silence pins were replaced by the verbatim refusal at :979-980. The index row was written before the fix and never revisited -- which is the interleaving defect this migration exists to end.

### `D135` — The legend overhung the frame on a single label wider than the whole frame -- the legend's copy of D124

`closed` · severity 3 · graphs · verdict CONFIRMED · fixedBy `pre-repo` · pinnedBy `v32`

**Mechanism.** @emlDrawLegend floored .colsMax at 1 when even one column did not fit and computed capacity as though one had, then drew the box whole; it did not report itself to @emlExpandDrawnExtent under placement 1, so the save cut it off mid-label

**Pointer.** evidence: validate/v32_legend_geometry.R:1152-1203 both states are kept: the open numbers measured 8 Aug 2026 at 17:10 (an 8208 px box on an 1800 px canvas, 1735 px of ink right of the frame, 25 px clipped at the canvas edge on the 6x4) sit in the section header as the guard, and the assertions below them are the closed behaviour -- box inside the frame, zero ink right of the frame, zero clipped at the edge, and the ellipsis disclosed in exact house wording naming the panel width and the font size that made the decision. Present at the root import 9b7d5aa; the repair is dated 8 Aug 2026.

**Measured.** SOURCE BEATS PROSE. FINDINGS_INDEX.md:316 reads "**LIVE 8 Aug**" and gives the repair as future work. v32's section 6 header at :1111-1150 records that it was written to pin D135 OPEN and had to be rewritten before it was ever committed, because the placement work closed the finding a few hours after the fixture first measured it. The index was written from the earlier state and never caught up. run_all.R:223 states the same closure from the runner's side.

### `NEW-G2-2` — Mann-Whitney U1 glossed as 'Sum of ranks' — wrong term, number correct

`closed` · severity 3 · clarity · verdict CONFIRMED · fixedBy `7f62e751783ecb52df2d9bab961bec39e000213a` · pinnedBy `v62`

**Mechanism.** output gloss text

### `NEW-G4-1` — ANOVA augment exports non-broom values under broom's .std.resid name; leverage missing

`closed` · severity 3 · export · verdict CONFIRMED · fixedBy `a4de0eecaa5b96e6d6113b69f041b99faaaadf62` · pinnedBy `v57`

**Mechanism.** D58 fix covered regression only; uniform 4.4% understatement on balanced demo

### `NEW-G6-1` — RM/Friedman refusal diagnosis computed on silently halved complete-case sample

`closed` · severity 3 · clarity · verdict CONFIRMED · fixedBy `a4de0eecaa5b96e6d6113b69f041b99faaaadf62` · pinnedBy `v57`

**Mechanism.** no exclusion disclosure in refusal path

### `NEW-G7-1` — Steady phonation draws as fluctuating contour over collapsed axis (verifier 2->3)

`closed` · severity 3 · graphs · verdict CONFIRMED · fixedBy `7f62e751783ecb52df2d9bab961bec39e000213a` · pinnedBy `v62`

**Mechanism.** axis floor + integer tick precision, not pitch analysis; needs min span + adaptive tick decimals

### `NEW-G8-1` — Out-of-range points drawn unclipped outside plot frame

`closed` · severity 3 · graphs · verdict CONFIRMED · fixedBy `7f62e751783ecb52df2d9bab961bec39e000213a` · pinnedBy `v62`

**Mechanism.** no clip to user-set range

### `NEW-G8-3` — Duplicate result block appended per Draw in one graphs session

`closed` · severity 3 · export · verdict CONFIRMED · fixedBy `7f62e751783ecb52df2d9bab961bec39e000213a` · pinnedBy `v61`

**Mechanism.** collector not reset per press

### `NEW-G8-4` — Annotation panel hides datum; dotted ghost bleeds through text

`closed` · severity 3 · graphs · verdict CONFIRMED · fixedBy `7f62e751783ecb52df2d9bab961bec39e000213a` · pinnedBy `v62`

**Mechanism.** panel/datum collision, no avoidance

### `NEW-G10-4` — File mode says 'No import problems found' on ragged CSV Praat then refuses

`closed` · severity 3 · checkdata · verdict CONFIRMED · fixedBy `c112b7cc0e21720fefa0e8882aaf8be78fab0936` · pinnedBy `v60`

**Mechanism.** no row-length consistency check

### `NEW-G11-1` — Emitted script header claims home-relative portability; include block machine-absolute

`closed` · severity 3 · recorder · verdict CONFIRMED · fixedBy `d5a434b920eb58b219ac2b5eb4831cee9672fe37` · pinnedBy `v58`

**Mechanism.** emit path writes absolute includes

### `NEW-G11-3` — Stale duplicate recordMeta stamps later emission with dead session's timestamp (verifier 2->3)

`closed` · severity 3 · recorder · verdict CONFIRMED · fixedBy `a4de0eecaa5b96e6d6113b69f041b99faaaadf62` · pinnedBy `v58`

**Mechanism.** meta lookup takes first match; steps emit correctly

### `NEW-G11-4` — Stop-and-save onto missing folder leaks raw internals, points at closed window

`closed` · severity 3 · recorder · verdict CONFIRMED · fixedBy `c112b7cc0e21720fefa0e8882aaf8be78fab0936` · pinnedBy `v58`

**Mechanism.** eml-record-save.praat own writer, no createFolder

### `NEW-G12-2` — Coercion crash strands temp objects incl. Table shadowing source name

`closed` · severity 3 · entry · verdict CONFIRMED · fixedBy `a4de0eecaa5b96e6d6113b69f041b99faaaadf62` · pinnedBy `v59, v63`

**Mechanism.** cleanup never runs after native crash

### `NEW-G12-3` — Zero-variance refusal buried in report under 'Analysis complete' modal with Save/Draw/New

`closed` · severity 3 · clarity · verdict CONFIRMED · fixedBy `a4de0eecaa5b96e6d6113b69f041b99faaaadf62` · pinnedBy `v57`

**Mechanism.** refusal not surfaced modally; contrast r4 gold-standard modal

### `D4` — Scatter dot-size/show-dots preset channel has no producer

`closed` · severity 4 · unification · verdict CONFIRMED-LIVE · fixedBy `7f62e751783ecb52df2d9bab961bec39e000213a` · pinnedBy `v61`

**Mechanism.** emlGraphsPresetDotSize read :2728/2735, never written

### `D6` — Histogram/GroupedViolin/GroupedBox force Matrix layout, no field offered

`closed` · severity 4 · graphs · verdict CONFIRMED-LIVE · fixedBy `7f62e751783ecb52df2d9bab961bec39e000213a` · pinnedBy `v61`

**Mechanism.** annotLayoutMode=3 forced :7476-7478

### `NEW-G12-4` — Pre-dialog refusals leak raw exitScript stack noise (verifier 3->4; wording accurate)

`closed` · severity 4 · clarity · verdict CONFIRMED · fixedBy `c112b7cc0e21720fefa0e8882aaf8be78fab0936` · pinnedBy `v60`

**Mechanism.** 3 exitScript sites bypass @emlErrorDialog

### `SAVED-OVERPRINT` — 'Saved' receipt overprints wrapped path lines — five sightings, one cause

`closed` · severity 4 · polish · verdict CONFIRMED · fixedBy `a4de0eecaa5b96e6d6113b69f041b99faaaadf62` · pinnedBy `v56`

**Mechanism.** stats/eml-output.praat receipt reserves one line, draws many; @emlWrapText exists

### `D40` — No interaction plot; two-way Draw goes to Grouped Violin

`superseded` · severity 3 · stats · verdict CONFIRMED-LIVE · fixedBy *(empty)* · pinnedBy *(empty)*

**Mechanism.** Ruling 3 unimplemented

**Pointer.** roadmap: audit/handoffs/20260816_evening/FEATURE_ROADMAP_TO_LMM_2026-08-16.md:57-59 the interaction plot is specified in Phase 2 (heading at :45) as cell means with CI bars through the existing graph machinery and recorder semantics, a graph family rather than new drawing infrastructure; oracle R emmeans (:60). Never built, so grep finds nothing in plugin/ and that is the expected result, not a gap.

### `D38` — Simple effects still absent post two-way (caution half works)

`superseded` · severity 4 · stats · verdict CONFIRMED-LIVE · fixedBy *(empty)* · pinnedBy *(empty)*

**Mechanism.** matches index PARTIAL

**Pointer.** roadmap: audit/handoffs/20260816_evening/FEATURE_ROADMAP_TO_LMM_2026-08-16.md:54-56 simple effects are specified in Phase 2 (heading at :45) as the two-way follow-up, effect of A within each level of B, with the existing Holm/Bonferroni vocabulary and the existing disclosure rules; oracle R emmeans (:60). Never built, so grep finds nothing in plugin/ and that is the expected result, not a gap. The caution half of D38 was closed 7 Aug and is not this row's remainder.

### `D15` — Paired 'Group' literal targets its own reshaped table which always has that column

`refuted` · severity 0 · refuted · verdict REFUTED · fixedBy *(empty)* · pinnedBy *(empty)*

**Pointer.** refutation: validate/v60_wrapper_paths.R:231-240 the finding suspected a hardcoded column name pointing at the user's table. The check asserts BOTH halves of the refutation against the paired wrapper's source, read off disk with comments stripped: the literal is there (emlGraphsPresetGroupCol$ = "Group", plugin/scripts/eml-compare-paired.praat:332) AND the table it addresses is the wrapper's own reshape, created four lines above it with the column names Subject, Condition, Value, Group (:239) — so the column it names always exists. Live rather than committed: delete either line from the plugin and this check goes red, which is why the section is headed THE REFUTED FINDING, PINNED (:232) and the header at :87-93 tells a later reader tidying up "hardcoded strings" to argue with a failing check. Nothing was repaired here and nothing needs pinning.
