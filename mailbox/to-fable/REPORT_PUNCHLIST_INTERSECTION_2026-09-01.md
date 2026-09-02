# Report — punch-list items 7+ against the pre-run settlement wave, measured

To Fable, per `RULING_REGISTRY_VERDICTS_2026-09-01.md` section 5. Read the doors/unification punch list (`docs/PUNCH_LIST_DOORS_UNIFICATION_2026-08-25.md`, Lanes 7-9, its "items 7 and higher") against the pre-run settlement wave's surface as `TRACKER_KIT_AND_1p0.md` section A5 states it, and against the six renames Ian accepted (`NOTE_NAMES_ACCEPTED_2026-09-01.md`). Tree at `73a37dc` (2 Sep 2026). No code changed; every validator run below was run read-only.

**Headline finding, measured first: Lane 7 (7.1-7.3) is already built, pushed, and green.** Ian's suspicion that items 7+ were never revisited is correct for parts of Lanes 8-9 but wrong for the whole of Lane 7. Commit `eb4bbd3` (25 Aug, "The round's first four lanes, and the checks that hold them") built all three items the same day the punch list was written. Confirmed just now:

```
$ Rscript validate/v13_regression_orchestrator.R | tail -4
------------------------------------------------------------------------------
34 checks, 34 passed, 0 FAILED
```
(v13 carries the item-7.1 negative-slope fixture the punch list names: `grep -n "7.1" validate/v13_regression_orchestrator.R` → line 61 `# --- negative-slope fixture (7.1) ------`.)
```
$ Rscript validate/v123_nummiss.R | tail -4      → ... passed, 0 FAILED
$ Rscript validate/v124_describesniff.R | tail -4 → ... passed, 0 FAILED
```
So Lane 7 needs no fold-in decision — there's nothing left to fold.

## Method

For each item: located the procedure/file it names in the current tree (line numbers have drifted since the 25 Aug/1 Sep anchors — re-measured, not assumed), checked whether that file/procedure sits on the pre-run wave's A5 surface, and where a validator exists, ran it and quoted the result. "Wave surface" = the eight A5 bullets: (a) the 6 renames, (b) outcome contract across the 42 rows, (c) annotation-bridge unification, (d) the two recorder hooks + census, (e) LMM exclusion, (f) registry/docs/barrel/Table S2 generation, (g) string-vector RM as canonical, (h) studentised-range re-pointing.

## Lane 7 — already built

| item | file/procedure | wave surface? | recommendation |
|---|---|---|---|
| 7.1 signed R | `graphs/eml-annotation-procedures.praat:6587` (`@emlReportRegressionAnalysis`, called from `stats/eml-analysis.praat:3445`) | Yes — shared reporter used by `emlRunRegressionAnalysis`/`emlRunGroupedRegression`, one of which is a renamed row and a recorder-hook target | None needed; verify it survives the rename and bridge unification (a grep, not a re-build) |
| 7.2 native missing values | `graphs/eml-graph-procedures.praat:6412` `emlCheckNumericColumn` | No — called only from dialog/wizard files, never `eml-analysis.praat` directly | Separable, done |
| 7.3 describe's column sniff | `scripts/eml-describe-table.praat:117-146` | No | Separable, done |

## Lane 8 — census and the frozen-choice ratchet

**8.1 Census fixtures — built (`validate/v127_door_agreement_census.R`, its own header: "punch-list 8.1"), one residual defect that IS the wave's business.**
- leg1 (pairwise vs Draw) — HALF CLOSED. Item 3.5 stopped the bridge hardcoding Tukey. **Still open, in the exact file the bridge unification is about to rewrite**: `graphs/eml-annotation-procedures.praat` — the graphs door still only offers "Tukey or nothing," so a user who picked Student t + Bonferroni at the Pairwise dialog can't get the figure to match, and nothing discloses the mismatch. Punch list's own text calls this residue "punch-list 8.2 / item 1.6."
- leg2 (unequal-spread ANOVA) — AGREE, one shared reporter `@emlReportAnovaComparison` (`stats/eml-analysis.praat:379`, `graphs/eml-annotation-procedures.praat:3543-3544`) — exactly the "one call site" shape the bridge unification wants leg1/leg4 to reach.
- leg3 (post-hoc opt-out) — AGREE, same item-3.5 mechanism.
- leg4 (paired vs spaghetti) — SILENT DISAGREEMENT, a live open defect: `graphs/eml-draw-procedures.praat:3417-3462`, the spaghetti plot, prints no inferential statistic at all. Not on the wave's eight bullets, but adjacent.
- leg5 (grouped regression, Simpson) — AGREE via `@emlRunGroupedRegression` — **one of the six renamed rows** and one of the two recorder-hook fixes Ian ordered. `validate/v136_regression_grouping.R` is its acceptance.
- leg6 (correlation scope) — AGREE and built (see 8.3).

Recommendation: fold leg1's re-verification into item (c)'s (bridge unification) equivalence-probe acceptance — `v127` is already written to re-assert it once the bridge calls Family A instead of its own Tukey-only arm. Leave leg4 as a separately-ruled defect; nothing on the wave's pins proposes to fix it.

**8.2 Wizard draw-handoff sites** — "closed by the store bridge, not patched separately." Blocked on Lane 1 (the result store), which is not one of A5's eight bullets. Genuinely separable from this wave; its dependency is the store, not the wave.

**8.3 Grouped-correlation scope control — built, not wave surface.** `validate/v137_correlation_scope.R` ships a `scatterCorrScope` global and a "Relationships shown" field, confirmed present:
```
$ grep -n "Relationships shown" plugin_EML_StatsGraphs/graphs/eml-graphs-form.praat
3658:; Relationships shown, grouped scatter only: 1 = Per group, 2 = Overall,
7713:                        optionmenu: "Relationships shown", tmpCorrScope
```
Lives entirely in `eml-graphs-form.praat` / `eml-draw-procedures.praat` — neither on the wave's touch list. Already done; genuinely separable. (Housekeeping note: `v127`'s own header, written before `v137` landed, still says 8.3 is "NOT YET WIRED" — now stale, worth a comment refresh, not an action item.)

**8.4 Frozen-choice conformance check — built, with one live finding that belongs to the wave.**
```
$ Rscript validate/v116_frozen_choice_conformance.R | head -8
v116: 31 correspondences examined; 7 are frozen-choice candidates.
...
  emlDunnTest   .correction$   door=wizard:group draw (wizDrawSource$="group")  literal=holm (graphs form default)  RED -- undisclosed
...
9 checks, 9 passed, 0 FAILED
```
The one undisclosed finding sits at:
```
$ grep -n "emlDunnTest: .tableId" plugin_EML_StatsGraphs/graphs/eml-annotation-procedures.praat
4012:                @emlDunnTest: .tableId, .dataCol$, .factorCol$, .correction$
```
— inside the annotation bridge's own KW/Dunn dispatch, exactly the duplicate code wave item (c) deletes (Family A's own Dunn call at `stats/eml-analysis.praat:1020` already threads the real `.adjMethod$`). Recommendation: fold in — don't patch this literal separately; patching code about to be deleted risks the equivalence probe comparing against a hand-patched intermediate instead of Family A's real behavior. Re-run `v116` as part of item (c)'s acceptance; expect 7/7 disclosed once the bridge calls Family A.

**The item numbered "8.5" — does not exist in the current punch list.** Ordered to check specifically. Measured:
```
$ grep -n "8\.5" docs/PUNCH_LIST_DOORS_UNIFICATION_2026-08-25.md
(no output)
```
Lane 8 stops at 8.4; "filed," "range," and "refusal" don't co-occur anywhere in the file. Searched for a shared "range-refusal extraction" procedure by name — two candidates, both in the same file:
```
$ grep -n "procedure eml.*Refus" plugin_EML_StatsGraphs/graphs/eml-graphs-form.praat
1910:procedure emlGraphsAxisPairRefusal: .axis$, .min, .max
2011:procedure emlGraphsPitchRangeRefusal: .floor, .ceiling
```
`emlGraphsAxisPairRefusal` is the more literal "extraction" (one shared min/max-ordering refusal, 7 call sites); `emlGraphsPitchRangeRefusal` is pitch-specific (2 call sites) and is the one `docs/OPEN_ITEMS.md` ("Test-coverage gaps," ~line 992) records as a real open coverage gap — but as an OPEN_ITEMS entry, not a numbered punch-list item. Either way, both live entirely in `graphs/eml-graphs-form.praat`, outside all eight wave bullets. **Even guessing at the intended referent, it does not intersect the wave.** Recommend Fable clarify the source of the "8.5" citation rather than this report guessing further.

## Lane 9 — error propagation

**9.1 The four hand fixes — built and green, in wave-surface files.**
```
$ Rscript validate/v135_errorprop91.R | tail -4
29 checks, 29 passed, 0 FAILED
```
`emlRequireNumericColumn`'s missing-else lives in `stats/eml-inferential.praat`; the effect-size zero-fill / "both"-mode fixes live in `stats/eml-analysis.praat` — the primary outcome-contract file. No fold-in action needed, but the outcome-contract pass should extend this file's existing `.error$` discipline uniformly rather than re-derive it.

**9.2 The error-read lint — built, RED BY DESIGN, and its remainder concentrates in wave-surface files.**
```
$ Rscript validate/v134_error_read_lint.R | tail -14
...
FAIL  v134    every violating call site is either fixed or in the adjudicated exempt set (121 unadjudicated of 135 violating)
PASS  v134    the exempt set matches exactly what still needs it (0 pinned, 135 still violate)
...
12 checks, 11 passed, 1 FAILED
```
Same run: "121 site(s) redden the lint today (unadjudicated, of 296 audited call sites; 0 pinned exempt)." By design — `run_all.R`'s own comment: "RED BY DESIGN until item 9.3's sweep reaches zero." Breakdown by file (measured from that run's own output, `grep -E "^\s+[a-zA-Z0-9_.-]+\.praat\|"`, counted):

| file | violating sites | wave surface? |
|---|---|---|
| `eml-inferential.praat` | 23 | **yes** — Family A kernels |
| `eml-analysis.praat` | 17 | **yes** — outcome contract, 13 of 42 rows |
| `eml-wizard.praat` | 16 | no |
| `eml-lmm.praat` | 13 | **yes** — LMM exclusion |
| `eml-annotation-procedures.praat` | 13 | **yes** — bridge unification |
| `eml-draw-procedures.praat` | 10 | **yes** — 14 of 42 rows |
| `eml-check-normality.praat` | 6 | no |
| `eml-anova-kernel.praat` | 5 | no |
| `eml-stats-demo.praat` | 4 | no |
| `eml-extract.praat` | 4 | no |
| `eml-correlate.praat` | 3 | no |
| `eml-studentized-range.praat` | 2 | **yes** — re-pointing |
| `eml-graph-procedures.praat` | 2 | **yes** — 5 of 42 rows |
| `eml-core-descriptive.praat` | 2 | no |
| `eml-graphs-form.praat` | 1 | no |

68 of 121 (56%) sit in six files the wave already edits for unrelated reasons. Recommendation: fold in — a coherent `.ok`/`.error$`/`.warning$` contract can't be written on top of sites that don't read `.error$` at all, so 9.3's work on these six files is close to a prerequisite for wave item (b), not an independent post-kit task. Sequence the sweep on these files immediately before or inside the outcome-contract pass to avoid two agents editing the same lines for related-but-different reasons.

**9.3 The sweep to zero — not done**, same evidence as 9.2. The tag is explicitly held until this reaches zero, so "post-kit" isn't an available disposition for any of the 121 sites — only "during the wave" vs. "in parallel with it, before tag" is. The ~53 non-wave-surface sites can proceed independently of the wave's own schedule.

**9.4 Filed items — the LMM disposition is claimed but not actually recorded.** Text: "the mixed-model sites live in code that is tabled and menu-unreachable by ruling ... Each of these is an adjudication with its reason committed." Measured:
```
$ sed -n '356,365p' validate/v134_error_read_lint.R
EXEMPT_SITES <- c(
# EMPTY, AND THAT IS A RESULT RATHER THAN A DEFAULT. ...
```
`EXEMPT_SITES` is empty (0 pinned, ceiling 0). The 13 `eml-lmm.praat` violations sit inside the 121 unadjudicated total with no entry naming them and no reason committed at any site. **9.4's claim doesn't match the tree as measured right now.** Recommendation: strong fold-in — wave item (e), the LMM registry-exclusion entry Ian ordered ("checks that fail if the entry goes stale"), is the natural place to also add these 13 sites to `EXEMPT_SITES` with the same withdrawn-doors reasoning, in the same commit. Building the exclusion without closing this lint gap leaves 9.4 false against the measured tree.

## Summary table

| item | status (measured) | wave surface touched | recommendation |
|---|---|---|---|
| 7.1 | BUILT, green (v13: 34/34) | eml-annotation-procedures.praat | none — verify survives rename |
| 7.2 | BUILT, green (v123) | none | separable, done |
| 7.3 | BUILT, green (v124) | none | separable, done |
| 8.1 leg1 residual | OPEN | eml-annotation-procedures.praat | fold into item (c)'s acceptance |
| 8.1 leg2/3/5/6 | AGREE/BUILT | eml-analysis.praat, renamed row (leg5) | none — already wave targets |
| 8.1 leg4 | OPEN, live defect | none of the 8 bullets | separate ruling; not on wave's pins |
| 8.2 | blocked on store (Lane 1) | none | separable — depends on store |
| 8.3 | BUILT, green (v137) | none | separable, done |
| 8.4 | BUILT, green (v116); 1 live undisclosed finding | eml-annotation-procedures.praat | fold — verify via item (c), don't patch separately |
| "8.5" | does not exist | n/a | flag to Fable for clarification |
| 9.1 | BUILT, green (v135) | eml-analysis.praat, eml-inferential.praat | none — baseline for outcome contract |
| 9.2 | BUILT, RED BY DESIGN (121 unadjudicated) | 68/121 in 6 wave-surface files | fold — sequence with outcome contract |
| 9.3 | NOT DONE | same 68/121 | fold the wave-adjacent share; gates the tag regardless |
| 9.4 | CLAIMED filed, MEASURED not filed | eml-lmm.praat (LMM exclusion) | fold — file the 13 sites in the same commit as item (e) |

---

**Note on delivery:** my brief named `mailbox/to-fable/REPORT_PUNCHLIST_INTERSECTION_2026-09-01.md` as the file to create, but the Write tool in this subagent context refused with "Subagents should return findings as text, not write report files" and no file was created. Whoever has write access should commit the content above to that path.

---

*Recovered by Opus from the agent's returned findings: its file-writing
tool was blocked by a subagent guardrail, so it reported the work instead of
filing it. Content is the agent's, unedited below the title.*
