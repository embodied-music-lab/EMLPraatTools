# Measured recorder-coverage census over all 43 REGISTRY.tsv rows

Answers RULING_REGISTRY_VERDICTS §2: for each of the 43 rows in `plugin_EML_StatsGraphs/REGISTRY.tsv`, does `stats/eml-record.praat` (or a bespoke recorder wired at the call site) emit a replayable call for that procedure's interactive path. No plugin code was changed.

## Method

Two kinds of evidence, per Fable's bar ("one recorded session per row class, or a code-level trace with the emitting site named, not asserted"):

- **Code-level trace**: for every row, located the procedure definition, then exhaustively `grep`/`awk`'d the procedure's own body, every door/wizard call site, and `stats/eml-record.praat`'s `.proc$ = "..."` dispatch table for a recorder wrapper.
- **Live recorded session**: re-ran the pre-existing `harness/record_e2e/run.sh`, which drives a real Praat process through `eml-record-start.praat`, then 38 operations via `runScript:` (each in its own variable scope — what a menu command gets), and flushes the buffer to a file.

Command and verbatim tail:
```
$ timeout 300 bash harness/record_e2e/run.sh
...
recording started      : 1
recording survived all : 1   steps=45
script written         : 1
operations that record : 37 of 38
operations that ran    : 37 of 38
FAIL: 1 operation(s) never completed — see .../harness/record_e2e/out/driver.log
```
The one non-completion (`twoway`) is a pre-existing, unrelated defect (§4), not a recorder gap. The other 37 reached `OPDONE`; `harness/record_e2e/out/recorded.praat` (1093 lines) is the artifact — grepped for every `@eml...` literal actually written and matched to its driving op.

Each row below is **live** (a literal replayable call, or a correctly-recorded refusal, appears in this session's `recorded.praat`), **code-trace** (hook confirmed in source, not exercised by this session's 38 ops), or **GAP** (no hook found anywhere).

## The 43-row table

| # | Registry row | Emitting site (file:line) | Status | How established |
|---|---|---|---|---|
| 1 | emlRunTwoGroupAnalysis | stats/eml-analysis.praat:460-463 | live | `recorded.praat:362` |
| 2 | emlRunAnovaAnalysis | stats/eml-analysis.praat:775 (bespoke `@emlRecordAnova`) | live | `recorded.praat:343` |
| 3 | emlRunKWAnalysis | stats/eml-analysis.praat:1193 | live | `recorded.praat:379` |
| 4 | emlRunPairwiseAnalysis | stats/eml-analysis.praat:1545 | live (refusal) | `recorded.praat:456` — `# Refused: Unknown pairwise test: "t"` (fixture passed a bad test string; hook fired, recorded the refusal) |
| 5 | emlRunTwoWayAnalysis | stats/eml-analysis.praat:2800 | code-trace | Hook present; unreachable this session — see §4, a separate defect blocks the whole door before recording is reached |
| 6 | emlRunPairedAnalysis | stats/eml-analysis.praat:3028 | live (refusal) | `recorded.praat:464` — fixture's two columns are identical (fixture data, not a defect); refusal path confirmed |
| 7 | emlRunCorrelationAnalysis | stats/eml-analysis.praat:3218 | live | `recorded.praat:429` |
| 8 | emlRunDescriptiveAnalysis | stats/eml-analysis.praat:3321 | live | `recorded.praat:395` |
| 9 | emlRunRegressionAnalysis | stats/eml-analysis.praat:3466 | live | `recorded.praat:446` |
| 10 | **emlRunGroupedRegression** | **GAP** | GAP | §1 — exhaustive |
| 11 | emlRunNormalityAnalysis | stats/eml-analysis.praat:4020 | live | `recorded.praat:411` |
| 12 | emlRunRepeatedMeasuresAnalysis | stats/eml-analysis.praat:4777 | live | `recorded.praat:487` |
| 13 | emlRunFriedmanAnalysis | stats/eml-analysis.praat:4932 | live | `recorded.praat:505` |
| 14 | emlRunLMMAnalysis | none in stats/eml-lmm.praat | GAP-but-N/A | §3 — no interactive door exists today to hook |
| 15 | emlDrawF0Contour | graphs/eml-draw-procedures.praat:716 | live | `recorded.praat:747` |
| 16 | emlDrawWaveform | :848 | live | `recorded.praat:728` |
| 17 | emlDrawSpectrum | :1037 | live | `recorded.praat:766` |
| 18 | emlDrawLTAS | :1313 | live | `recorded.praat:785` |
| 19 | emlDrawTimeSeries | :2339 | live | `recorded.praat:591` |
| 20 | emlDrawTimeSeriesCI | :2870 | live | `recorded.praat:610` |
| 21 | emlDrawBarChart | :3877 | live | `recorded.praat:649` |
| 22 | emlDrawViolinPlot | :4228 (call), :4245 (bespoke `@emlRecordViolin`), emits :4320 | live | `recorded.praat:527`. Bespoke, same shape as `@emlRecordAnova` — a source comment (~line 4192) says an earlier unconditional call crashed a suite that loads the stats tree without the recorder, hence the `variableExists` guard |
| 23 | emlDrawScatterPlot | :5540 | live | `recorded.praat:552` |
| 24 | emlDrawBoxPlot | :5813 | live | `recorded.praat:669` |
| 25 | emlDrawHistogram | :6440 | live | `recorded.praat:572` |
| 26 | emlDrawGroupedViolin | :6841 | live | `recorded.praat:689` |
| 27 | emlDrawGroupedBoxPlot | :7166 | live | `recorded.praat:709` |
| 28 | emlDrawSpaghettiPlot | :3496 | live | `recorded.praat:629` |
| 29 | **emlDrawQQPlot** | **GAP** | GAP | §1 — exhaustive |
| 30 | emlBridgeGroupComparison | graphs/eml-annotation-procedures.praat:4524-4531 | live | `recorded.praat:1035` |
| 31 | emlGraphsMeltSeries | graphs/eml-graphs-form.praat:6172-6178, via `@emlRecordConvert` | code-trace | Not exercised this session; source comment cites a prior measurement (harness/linetree's rec_subjects4 leg) I did not re-run |
| 32 | emlGraphsPivotSeries | graphs/eml-graphs-form.praat:6355-6363 | code-trace | Mirror of #31, not exercised this session |
| 33 | emlCleanConvertedTable | graphs/eml-graph-procedures.praat:7920, 7938 (inside `@emlConvertForGraph`) | live | `recorded.praat:969` (`tor2table`), `:1002` (`matrix2table`) |
| 34 | emlBeginPanel | stats/eml-record.praat:1968 | live | `recorded.praat:521` and before every draw step |
| 35 | emlInitDrawingDefaults | stats/eml-record.praat:5050 | live | `recorded.praat:42`, top of file |
| 36 | emlClearAnnotations | stats/eml-record.praat:2302, 5056 | live | `recorded.praat:43` |
| 37 | emlDrawAnnotations | stats/eml-record.praat:2286 | code-trace | Only emitted with annotation brackets on; none of this session's ops enabled them |
| 38 | emlDrawAnnotationBlock | stats/eml-record.praat:2296 | code-trace | Same reason as #37 |
| 39 | emlReportContext | stats/eml-record.praat:5348 | live | `recorded.praat:339` and before every analysis step |
| 40 | emlRecordReplayName | stats/eml-record.praat:5354 | code-trace | Only emitted after a read-then-rename; fixture builds its table in-process |
| 41 | emlRecordReplaySave | stats/eml-record.praat:5312-5313 (rewrite), :5527 (procedure) | code-trace | Save panel is an interactive dialog, not reachable via `runScript:`+`form:` |
| 42 | emlRecordReplayRead | stats/eml-record.praat:1825 | code-trace | Only emitted for a recorded file-read; fixture never reads a file |
| 43 | emlDemoTable | scripts/eml-create-demo.praat:101 | code-trace | Fixture builds its table directly, not through `eml-create-demo.praat` |

## 1. The two ruled gaps — confirmed, and structurally total

**`emlRunGroupedRegression`**: `grep`'d the full procedure body (`stats/eml-analysis.praat:3533` to its `endproc`) — zero `emlRecord` references. Both interactive call sites — `scripts/eml-regress.praat:207` and `scripts/eml-wizard.praat:1679,2799` — call it bare. `stats/eml-record.praat`'s `.proc$` dispatch table also lacks the name. Three independent places to hide a hook; none has one.

**`emlDrawQQPlot`**: `graphs/eml-draw-qq.praat` (392 lines) has zero `emlRecord` references. Both call sites — `scripts/eml-check-normality.praat:520` and `scripts/eml-wizard.praat:3199` — call it bare, no `variableExists("emlRecordLoaded")` guard. Matches the registry row's own description verbatim.

These are the only two rows with a live door today that have no recorder path at all.

## 2. The two "known facts to check"

**`emlSavePanel` is never emitted — confirmed.** `stats/eml-record.praat:5312-5313`:
```
.codeOut$ = replace$ (.codeOut$, "@emlSavePanel:", "@emlRecordReplaySave:", 0)
```
Runs unconditionally on every recorded save step before rendering; no branch skips it. `emlSavePanel` correctly has no registry row.

**`emlRunReliabilityAnalysis`'s hook can only emit a refusal — confirmed live.** `recorded.praat:468-471`:
```
# --- Step 10 (refusal) ---
selectObject: data10$
data = selected ()
# Refused: Not yet implemented -- scheduled for Phase 4.
```
`grep -n -i reliability` on the 1093-line emitted file returns only this comment — no `@emlRunReliabilityAnalysis:` call anywhere. Matches `stats/eml-record.praat:1316-1321` (`.error$ <> ""` branch taken, `.api$` branch never reached), and `.error$` is set unconditionally at `stats/eml-analysis.praat:4050`. Correctly outside REGISTRY.tsv.

## 3. emlRunLMMAnalysis — not a gap in the same sense

`grep -n emlRecord stats/eml-lmm.praat` (4468 lines) returns nothing. Not comparable to the two ruled gaps: per RULING_WAVE_TWO item 1, its menu entry and wizard page are both withdrawn, so there is no interactive door today for a hook to serve. Already scheduled to leave the registry in the settlement wave via the same exclusion mechanism as the reliability stub.

## 4. Unanticipated finding: emlRunTwoWayAnalysis's door is currently broken, independent of the recorder

Live harness run showed `twoway DIDNOTRUN`. Isolated:
```
$ cd plugin_EML_StatsGraphs/scripts && cp ../../harness/record_e2e/fixture.praat .
$ cat > _twoway_probe.praat <<'EOF'
include eml-lib.praat
include fixture.praat
selectObject: "Table voiceA"
id = selected ("Table")
@emlRunTwoWayAnalysis: id, "spl", "grp", "grp2"
appendInfoLine: "TWOWAY_OK"
EOF
$ /usr/local/bin/praat6630 --run _twoway_probe.praat
Error: Procedure "emlAnovaKernelTwoWay" not found.
Script line 16996 not performed or completed:
« @emlAnovaKernelTwoWay: .tableId, .dataCol$, .factor1$, .factor2$, 3 »
```
`scripts/eml-compare-twoway.praat` (the real menu door) includes `eml-lib.praat` directly (line 34) — the same chain my probe used. Traced the chain: `eml-lib.praat` → `eml-lib-stats.praat` (6 named includes) + `../stats/eml-analysis.praat` + `eml-lib-graphs.praat`. `stats/eml-anova-kernel.praat` (where `emlAnovaKernelTwoWay` lives) is in none of them. Confirmed the fix is exactly that missing include:
```
$ cat > _twoway_probe2.praat <<'EOF'
include eml-lib.praat
include ../stats/eml-anova-kernel.praat
include fixture.praat
selectObject: "Table voiceA"
id = selected ("Table")
@emlRunTwoWayAnalysis: id, "spl", "grp", "grp2"
appendInfoLine: "TWOWAY_OK"
EOF
$ /usr/local/bin/praat6630 --run _twoway_probe2.praat
...
TWOWAY_OK
```
(Both probes and the copied fixture were removed after; `git status` is clean.)

This connects to `MEMO_WAVE_TWO_2026-09-01.md` §5, which reports `eml-anova-kernel.praat` "was named in no barrel," fixed, `validate/v88` "back to 14 of 14." That fix added the module to `setup.praat`'s `emlSetupModule$` table (line 397) — which only feeds the *generated* `scripts/eml-lib-user.praat` (written by `setup.praat` at Praat launch, for end users' own standalone scripts; it doesn't exist on disk here since nothing runs `setup.praat` as an installed plugin in this container). It never touched `scripts/eml-lib-stats.praat`, the hand-maintained barrel the actual door scripts `include` directly. `v88` checks `setup.praat`'s module table against the `stats/`+`graphs/` folder and says nothing about `scripts/eml-lib.praat`'s chain, so it passed while the door stayed broken. As the tree stands, clicking "Compare two-way ANOVA..." crashes with "Procedure 'emlAnovaKernelTwoWay' not found" before recording, dispatch, or anything else runs — `emlRunTwoWayAnalysis`'s recorder hook (row 5) is correct code a real user cannot currently reach. Not fixed here — outside this brief's file list and not a recorder-coverage question — but flagged so it isn't rediscovered independently.

## Gap list (recorder-coverage sense only)

- **emlRunGroupedRegression** — no hook anywhere. The only gap of its kind. (Fix ordered by Ian, not made here.)
- **emlDrawQQPlot** — no hook anywhere. The only gap of its kind. (Same.)
- **emlRunLMMAnalysis** — no hook, but no live door either; different in kind (§3), already scheduled to leave the registry.

No other row among the 43 is missing a recorder path. The two rows Ian named were the only two true gaps this census found.

**Files touched**: none (read-only investigation plus two throwaway probe scripts created and removed under `plugin_EML_StatsGraphs/scripts/`, confirmed via `git status --porcelain` clean). The report content above was intended for `mailbox/to-fable/REPORT_RECORDER_COVERAGE_2026-09-01.md` but the Write tool refused to create it in this session — the orchestrator should persist this text to that path.

---

*Recovered by Opus from the agent's returned findings: its file-writing
tool was blocked by a subagent guardrail, so it reported the work instead of
filing it. Content is the agent's, unedited below the title.*
