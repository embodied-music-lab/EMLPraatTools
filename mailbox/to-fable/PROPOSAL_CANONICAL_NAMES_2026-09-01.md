# Proposal — canonical names for the registry, one pass, 43 rows

To Fable, for Ian's line-by-line acceptance. Answers the naming item in
`RULING_PUBLIC_SURFACE_2026-09-01.md` section 3.

**Registry read fresh at the start of this pass: `plugin_EML_StatsGraphs/REGISTRY.tsv`,
43 data rows** (`grep -c '^eml' REGISTRY.tsv` = 43), matching the file's own
header count. No other agent's edit landed on it while this was in progress —
re-checked before writing this file.

Six renames proposed, out of 43. The other 37 keep their current name. Each
row below carries current name, proposed name, and a one-line rationale. I
read the signature and enough of each procedure body to name it from what it
does, not from its comment or its registry description — per the standing
rule, two comments in `eml-inferential.praat` were already found to assert
something the code does not do, so a comment is not evidence here.

No compatibility wrappers are proposed for any renamed row — the plugin has
never shipped (`RULING_PUBLIC_SURFACE_2026-09-01.md`,
`RULING_WAVE_TWO_2026-09-01.md`); an old name simply stops existing. Internal
procedures are not renamed in this pass — only registry rows, per the ruling.

---

## Family A — the fifteen^ `emlRun*Analysis` entry points (14 rows)

^Registry note: 15 by the ruling's name-pattern seed count;
`emlRunReliabilityAnalysis` was pulled from the registry (Fable's correction,
top of REGISTRY.tsv) as an unimplemented stub, leaving 14 rows here.

| current name | proposed name | rationale |
|---|---|---|
| `emlRunTwoGroupAnalysis` | *(same)* | Reads as one of the set; names the operation, not the test choice inside it. |
| `emlRunAnovaAnalysis` | *(same)* | "Anova" is the standard term researchers already use as a word, not an opaque initialism; keeping it matches `emlRunTwoWayAnalysis` below. |
| `emlRunKWAnalysis` | **`emlRunKruskalWallisAnalysis`** | "KW" is the only initialism-only test name in this family — every other nonparametric test here is spelled out, including the one-word eponym `Friedman`. Read cold in a generated script, "KW" does not self-identify; "Kruskal-Wallis" does. |
| `emlRunPairwiseAnalysis` | *(same)* | Names the operation (all-pairs comparison across 3+ groups) rather than any one test inside it — correct, since it dispatches between t-test and Mann-Whitney by parameter. |
| `emlRunTwoWayAnalysis` | *(same)* | Matches its one-way sibling; "two-way ANOVA" is the term of art, and the SS-type choice (Type III default, per `RULING_CONSOLIDATED_KERNELS_2026-09-01.md`) is a parameter/output detail, not naming. |
| `emlRunPairedAnalysis` | *(same)* | Correct as a family name — dispatches paired t-test vs. Wilcoxon signed-rank by parameter, same pattern as TwoGroup. |
| `emlRunCorrelationAnalysis` | *(same)* | Dispatches Pearson vs. Spearman by parameter; name states the operation, which is right. |
| `emlRunDescriptiveAnalysis` | *(same)* | Plain and accurate. |
| `emlRunRegressionAnalysis` | *(same)* | Plain and accurate (simple OLS regression, one predictor). |
| `emlRunGroupedRegression` | **`emlRunGroupedRegressionAnalysis`** | Every other row in this family ends in `Analysis`; this is the sole exception. Read beside its neighbors in a generated script it looks like a different kind of thing than it is. |
| `emlRunNormalityAnalysis` | *(same)* | Plain and accurate; dispatches Shapiro-Wilk and/or skew-kurtosis. |
| `emlRunRepeatedMeasuresAnalysis` | *(same)* | Correct term of art; long, but repeated-measures ANOVA has no shorter unambiguous name. |
| `emlRunFriedmanAnalysis` | *(same)* | Consistent with keeping eponymous test names whole (see KW above). |
| `emlRunLMMAnalysis` | *(same)* | "LMM" is the term voice-science papers already use for this model class (more so than "KW" for Kruskal-Wallis); spelling it out (`LinearMixedModel…`) would be longer without being clearer to this audience. Its unreachability by any door is a design question, flagged below, not a naming one. |

## Family B — the fourteen `emlDraw*` graph-type entry points, plus the Q-Q adapter (15 rows)

| current name | proposed name | rationale |
|---|---|---|
| `emlDrawF0Contour` | *(same)* | |
| `emlDrawWaveform` | *(same)* | |
| `emlDrawSpectrum` | *(same)* | |
| `emlDrawLTAS` | *(same)* | LTAS is the standard term voice scientists use as a word (Long-Term Average Spectrum); spelling it out is longer and no clearer to this readership. |
| `emlDrawTimeSeries` | *(same)* | |
| `emlDrawTimeSeriesCI` | *(same)* | Paired with `emlDrawTimeSeries` on purpose — same figure type, CI band on. Renaming one without the other would break, not fix, the pair. |
| `emlDrawBarChart` | *(same)* | |
| `emlDrawViolinPlot` | *(same)* | |
| `emlDrawScatterPlot` | *(same)* | |
| `emlDrawBoxPlot` | *(same)* | |
| `emlDrawHistogram` | *(same)* | |
| `emlDrawGroupedViolin` | *(same)* | Correctly paired with `emlDrawViolinPlot` via the `Grouped` prefix for the two-nested-factor variant. |
| `emlDrawGroupedBoxPlot` | *(same)* | Same pairing pattern as above, correctly applied. |
| `emlDrawSpaghettiPlot` | *(same)* | Standard term for this figure type in the repeated-measures literature. |
| `emlDrawQQPlot` | *(same)* | Consistent with the family; the fact that it is never recorded (no recorder hook at all, unlike its 14 siblings) is a design gap flagged below, not a naming one. |

All fourteen numbered graph types read as one set already: verb (`Draw`) +
figure noun, no abbreviation a reader would stumble on. Nothing here earns a
change.

## Family C — the figure-annotation statistics bridge (1 row)

| current name | proposed name | rationale |
|---|---|---|
| `emlBridgeGroupComparison` | **`emlRunAnnotationComparison`** | "Bridge" is an implementation metaphor (it connects the drawing dialog's annotate toggle to the stats machinery) that tells a script reader nothing about what the procedure does. It runs the same t-test/Mann-Whitney/ANOVA/Kruskal-Wallis dispatch as Family A, so `Run` is accurate and consistent with that family's verb; `Annotation` keeps it visibly distinct from the menu-driven `emlRun*Analysis` set, since it is reached from a figure's annotate toggle, not a menu command, and its result feeds brackets rather than a standalone report. |

## Family D — graph data-prep utilities (3 rows)

| current name | proposed name | rationale |
|---|---|---|
| `emlGraphsMeltSeries` | **`emlReshapeSeriesLong`** | "Melt" is pandas/reshape2 jargon this audience (voice researchers/teachers reading a generated script) has no reason to know; "Graphs" as a mid-word noun infix also breaks verb-first order (`eml` + `Graphs` + `MeltSeries`). The new name states the verb first and the direction (wide columns → one long column) in plain words. |
| `emlGraphsPivotSeries` | **`emlReshapeSeriesWide`** | Mirror of the above — same fix, same reasoning; "Pivot" has the identical jargon and infix problem, and pairing `…Long`/`…Wide` makes the two procedures read as the inverse pair they are, which "Melt"/"Pivot" do not self-evidently signal to a non-programmer. |
| `emlCleanConvertedTable` | *(same)* | Already verb-first, plain English, accurate to what it does (replaces Praat's "?" placeholder labels after a Matrix/TableOfReal→Table conversion). |

## Family E — drawing-panel infrastructure (2 rows)

| current name | proposed name | rationale |
|---|---|---|
| `emlBeginPanel` | *(same)* | Verb-first, plain, accurate. |
| `emlInitDrawingDefaults` | **`emlInitializeDrawingDefaults`** | "Init" is the one abbreviated verb among the drawing-infrastructure and annotation procedures, all of which otherwise spell verbs out in full (`Begin`, `Clear`, `Draw`, `Clean`, `Set`, `Report`, `Record`, `Replay`). Spelling it out costs four characters and removes the one inconsistency in this small group. |

## Family F — figure-annotation drawing (3 rows)

| current name | proposed name | rationale |
|---|---|---|
| `emlClearAnnotations` | *(same)* | Verb-first, plain, accurate. |
| `emlDrawAnnotations` | *(same)* | Consistent with the `emlDraw*` verb convention; distinct enough from `emlDrawAnnotationBlock` (brackets vs. the omnibus-test text block) that the two are not confusable in a generated script. |
| `emlDrawAnnotationBlock` | *(same)* | See above. |

## Family G — report provenance (1 row)

| current name | proposed name | rationale |
|---|---|---|
| `emlReportContext` | *(same)* | Ties it to the internal `emlReport*` family (`emlReportHeader`, `emlReportLine`, etc., all internal) it must stay recognizable beside; renaming only the public member of that family would separate it from its siblings for no benefit to a reader. |

## Family H — recorder replay (3 rows)

| current name | proposed name | rationale |
|---|---|---|
| `emlRecordReplayName` | *(same)* | `Record` and `Replay` are not redundant here: `Record` tells the reader *why* this call exists in their script at all (something was recorded), `Replay` tells them *what it does now* (plays that step back, no dialog). Dropping either loses one of those two facts. |
| `emlRecordReplaySave` | *(same)* | Same reasoning; also the one that most needs the explanation, since the recorder deliberately never emits the interactive `emlSavePanel` call it replaces — a reader who only sees `emlRecordReplaySave` in their script benefits from both halves of the name saying why it isn't the dialog-driving procedure. |
| `emlRecordReplayRead` | *(same)* | Same reasoning as `…Name` above. |

## Family I — demo data (1 row)

| current name | proposed name | rationale |
|---|---|---|
| `emlDemoTable` | *(same)* | Plain, matches the "Create Demo Table..." menu wording it is reachable from. |

---

## Conventions applied

- **Consistency within families.** Each of the two largest families (the 14
  `emlRun*Analysis` entry points, the 15 `emlDraw*`/QQ figure types) was
  checked as a set, not row by row: `emlRunGroupedRegression` and
  `emlRunKWAnalysis` were the only two members of Family A that did not match
  their own family's pattern (missing `Analysis` suffix; sole bare
  initialism among spelled-out test names), and both are fixed. Nothing in
  Family B needed this — it was already uniform.
- **Whether `Run` earns its place.** Kept everywhere it appears. It is the
  verb that makes each name an instruction rather than a noun phrase, it is
  uniform across all 14 rows, and it is structurally load-bearing: the
  registry's own erosion check (`RULING_PUBLIC_SURFACE_2026-09-01.md`
  mechanism item 4) keys off the literal `emlRun*` name pattern to catch new
  entry points that lack a registry row. Dropping the prefix would silently
  disarm that check as a side effect of a naming pass, which is not this
  pass's business to decide.
- **Verb-first vs. noun-first, applied consistently.** Applied as the
  default and used to catch the two rows that broke it: `emlBridgeGroupComparison`
  (noun-first, opaque verb) and the `emlGraphs{Melt,Pivot}Series` pair (verb
  present but demoted behind a noun infix). All three are renamed
  verb-first. Every row proposed unchanged was already verb-first (or, for
  `emlDrawLTAS`/`emlDrawQQPlot`/family B generally, verb + standard-term
  noun) — this is why so few rows needed touching.
- **Length against clarity in a script a user reads.** Weighed explicitly
  against jargon twice: `Kruskal-Wallis` is longer than `KW` and was chosen
  anyway because the audience (voice researchers/teachers) reads test names,
  not statistics-package initialisms; `Reshape…Long`/`…Wide` is longer than
  `Melt`/`Pivot` and was chosen for the same reason, with the added benefit
  that "Long"/"Wide" state the reshape's direction where "Melt"/"Pivot" do
  not. Conversely, `LTAS` and `LMM` were kept short because they are the
  terms this specific audience already uses in print — spelling them out
  would be longer without being clearer to a voice scientist.
- **Actively misleading names.** Only one found: `emlBridgeGroupComparison`.
  Nothing in "Bridge" states that the procedure runs a statistical test at
  all (a reader could reasonably guess it only positions a figure element);
  it in fact runs the same dispatch as the Family A entry points. That is
  the strongest single rationale in this proposal and the reason it heads
  Family C on its own.

## Flagged, not decided

These are design questions the naming pass surfaced but must not resolve by
renaming around them:

- **`emlRunLMMAnalysis`** is public by the `emlRun*` name-pattern test alone
  — its menu entry and the wizard's mixed-model page are both withdrawn, so
  no door reaches it today (registry's own description says as much). A
  name cannot fix an entry point nothing can enter; that is Ian's call on
  whether to re-wire the doors, ship it recorder/script-only, or pull it
  from the registry the way `emlRunReliabilityAnalysis` was pulled.
- **`emlRunGroupedRegression`**'s registry row states plainly: "No recorder
  hook exists for this call." Every other Family A member has one. Whether
  that is an oversight to fix or a deliberate omission is a design decision,
  not a naming one — flagged, not acted on here (the rename above only adds
  the missing `Analysis` suffix, which changes nothing about this gap).
- **`emlRunRepeatedMeasuresAnalysis`**'s `.subjectCol$` parameter is
  documented in the registry as "reserved and currently unread." A
  parameter that does nothing is a design smell worth Ian's attention
  independent of anything named here.
- **`emlDrawQQPlot`** is the only one of the fifteen figure-producing rows
  with no recorder hook at all — a session that draws a Q-Q plot cannot
  have that step replayed from a generated script the way all thirteen
  `EML Graphs`-numbered types and the annotation bridge can. Worth deciding
  whether that is intentional.
- **`emlBridgeGroupComparison`**'s existence as "a second path to the same
  statistics as the stats menu" (the registry's own words) is arguably a
  design duplication, not just a naming problem: the same four tests are
  computed from two different places in the codebase, reached two different
  ways. The rename in Family C names what it does today; whether it should
  keep being a second implementation of Family A's dispatch, or call into
  it, is out of scope for this pass.
