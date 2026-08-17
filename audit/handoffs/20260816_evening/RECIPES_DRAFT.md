# EML Praat Tools — recipes (DRAFT for Opus; ship only after harness runs each verbatim)

Worked, annotated examples for the workflows users actually have. Each recipe
shows the concept — which procedure, what its arguments mean, what variables it
returns — and then a complete runnable script. Signatures and output lists
below are copied from the procedure headers at HEAD; the headers remain the
authoritative reference.

House rule from v50: a documented example is a tested example — every recipe
must be run verbatim by a harness before this file ships. Status is marked per
recipe. R1 and R2 were run 16 Aug 2026 on Praat 6.6.30 against the current
tree; their printed outputs are real. R3 and R4 are condensed from
docs/API_EXPORT.md §3/§8, which the api_export harness already runs. R5 is an
untested draft and must not ship until driven.

## Rules of the road (read once, saves an hour)

- Praat script variables must start with a LOWERCASE letter. `P$ = ...` stops
  the script; `p$ = ...` runs.
- THE EASY WAY TO GET YOUR INCLUDE BLOCK: record any trivial workflow (New →
  EML → Record script, run one analysis, stop and save) and copy the include
  block from the top of the saved script. The recorder resolves the plugin's
  location on YOUR machine at save time and writes home-relative (~) paths
  gated on your OS and Praat version — the block is correct by construction.
  The pasted list below is the fallback if you'd rather not.
- (PENDING, change order 2h: setup.praat will generate a one-line user barrel
  at launch — eml-lib-user.praat with machine-correct internal paths — after
  which every recipe's include block becomes a single line. Opus: update this
  file to lead with it when that lands.)
- The include block lists the modules in order (later files call earlier
  ones). Praat resolves relative includes against the top-level script's
  directory, which is why the one-line barrel include the plugin uses
  internally does not work from your own folder (see docs/API_EXPORT.md,
  "Why the long include list") — and why the recorder writes the full block
  for you instead.
- After `@someProcedure: args`, its outputs are read as
  `someProcedure.outputName` — the procedure's name is the prefix, and the
  values persist until the procedure is called again.
- Check `.error$` after any call that has one. A refused call sets `.error$`
  and returns; it does not stop your script, so reading its other outputs
  without checking gives you stale or zero values.
- House style is MODERN Praat script throughout: colon-form commands, and the
  braced vector form for list arguments — `{ "spl", "group" }`, never the
  legacy space-separated string (which silently splits a name like "F0 mean"
  into two columns).
- Find your plugin path: run `writeInfoLine: preferencesDirectory$` in Praat.

The include block used by R1/R2/R5 (edit the path prefix once):

```praat
include ~/.praat-dir/plugin_EML_Praat_Tools/stats/eml-core-utilities.praat
include ~/.praat-dir/plugin_EML_Praat_Tools/stats/eml-core-descriptive.praat
include ~/.praat-dir/plugin_EML_Praat_Tools/stats/eml-extract.praat
include ~/.praat-dir/plugin_EML_Praat_Tools/stats/eml-output.praat
include ~/.praat-dir/plugin_EML_Praat_Tools/stats/eml-inferential.praat
```

(R3/R4 need the full eleven-line block from docs/API_EXPORT.md §3, because the
orchestrators and their reporters live in further modules.)

---

## R1 — compare two groups from a table (direct kernel calls)  [TESTED 16 Aug]

**The concept.** Three steps, three procedures. First, turn two groups' rows
into two numeric vectors. Second, hand the vectors to a test kernel. Third,
hand the same vectors to an effect-size kernel. Every kernel takes plain
vectors — it neither knows nor cares that they came from a Table.

**The procedures.**

```praat
# @emlExtractGroupVectors: .tableId, .measureCol$, .groupCol$, .label1$, .label2$
#   .tableId     - the Table object's ID (what Read Table... returned)
#   .measureCol$ - name of the numeric column to extract
#   .groupCol$   - name of the grouping column
#   .label1$     - group label for the first vector
#   .label2$     - group label for the second vector
# Returns:
#   .group1#     - data vector for label1$
#   .group2#     - data vector for label2$
#   .n1, .n2     - sizes of the two groups
#   .nExcluded   - rows matching neither label (reported, not silently lost)
#   .error$      - "" on success

# @emlTTest: .v1#, .v2#, .tails, .equalVariances
#   .v1#, .v2#      - the two numeric vectors
#   .tails          - 2 = two-sided, 1 = one-tailed (H1: mean1 > mean2)
#   .equalVariances - 0 = Welch (default; unequal variances), 1 = Student (pooled)
# Returns:
#   .t, .df, .p     - the test (df fractional for Welch; .p answers .alternative$)
#   .pGreater       - one-tailed p for H1: mean1 > mean2
#   .pLess          - one-tailed p for H1: mean1 < mean2
#   .alternative$   - which hypothesis .p answers ("two-sided" or "greater")
#   .mean1, .mean2, .sd1, .sd2, .n1, .n2, .meanDiff
#   .method$        - "Welch" or "Student"
#   .error$         - "" on success

# @emlTTestAlt: .v1#, .v2#, .alternative$, .equalVariances
#   Same test, direction stated in words: "two-sided", "greater", or "less"
#   ("greater" means H1: mean1 > mean2). Same returns as @emlTTest.

# @emlCohenD: .v1#, .v2#
# Returns:
#   .d          - Cohen's d (positive when mean1 > mean2)
#   .g          - Hedges' g (bias-corrected d, better for small samples)
#   .pooledSD   - the standardizer
#   .error$     - "" on success
```

**The script.**

```praat
data = Read Table from comma-separated file: "~/voice_study/spl_by_group.csv"

# Table rows -> two named vectors
@emlExtractGroupVectors: data, "spl", "group", "soprano", "mezzo"
if emlExtractGroupVectors.error$ <> ""
    exitScript: emlExtractGroupVectors.error$
endif
v1# = emlExtractGroupVectors.group1#
v2# = emlExtractGroupVectors.group2#

# Welch t-test, two-sided
@emlTTest: v1#, v2#, 2, 0
writeInfoLine: "t = ", fixed$ (emlTTest.t, 4),
...            "  df = ", fixed$ (emlTTest.df, 2),
...            "  p = ", fixed$ (emlTTest.p, 4)

# Directional hypothesis, stated in words
@emlTTestAlt: v1#, v2#, "less", 0
appendInfoLine: "H1 soprano < mezzo: p = ", fixed$ (emlTTestAlt.p, 4)

# Effect size
@emlCohenD: v1#, v2#
appendInfoLine: "d = ", fixed$ (emlCohenD.d, 4),
...             "  (Hedges' g = ", fixed$ (emlCohenD.g, 4), ")"
```

**Verified output** on a 5-vs-5 test table (means 81 vs 90):

```
t = -5.6921  df = 5.88  p = 0.0014
H1 soprano < mezzo: p = 0.0007
d = -3.6000
```

**Nonparametric siblings**, same vectors, same shape: `@emlMannWhitneyU: v1#,
v2#, 2` returns `.u1`, `.u2`, `.p`, `.pGreater`, `.pLess`, `.alternative$`,
rank sums `.r1`/`.r2`, `.hasTies`, and `.exact` — and `@emlRankBiserialR: v1#,
v2#, 2` is its effect size.

---

## R2 — paired columns and correlation from a wide table  [TESTED 16 Aug]

**The concept.** A wide table (one row per subject, one column per condition)
becomes two aligned vectors — complete pairs only, with the dropped rows
counted, never silently ignored. The paired kernel tests the within-subject
difference; the correlation kernels measure association on the same vectors.

**The procedures.**

```praat
# @emlExtractPairedColumns: .tableId, .col1$, .col2$
#   .tableId - the Table's ID
#   .col1$, .col2$ - the two column names
# Returns:
#   .data1#, .data2#  - aligned vectors, COMPLETE PAIRS ONLY
#   .n                - number of complete pairs
#   .nExcludedRows    - rows dropped for a missing value in either column
#   .error$           - "" on success

# @emlTTestPaired: .v1#, .v2#, .tails
#   Paired t on the per-row differences. .tails as in @emlTTest.
#   Directional form: @emlTTestPairedAlt: .v1#, .v2#, .alternative$
# Returns: .t, .df, .p, .pGreater, .pLess, .alternative$, .meanDiff,
#          .sdDiff, .n, .error$

# @emlPearsonCorrelation: .x#, .y#, .tails
#   Directional form: @emlPearsonCorrelationAlt: .x#, .y#, .alternative$
# Returns: .r, .df, .p, .pGreater, .pLess, .alternative$, .n, .error$

# @emlSpearmanCorrelation: .x#, .y#, .tails   (rank-based; same shape, .rho)
```

**The script.**

```praat
data = Read Table from comma-separated file: "~/voice_study/pre_post.csv"

@emlExtractPairedColumns: data, "pre", "post"
if emlExtractPairedColumns.error$ <> ""
    exitScript: emlExtractPairedColumns.error$
endif
appendInfoLine: "complete pairs: ", emlExtractPairedColumns.n,
...             "  (dropped: ", emlExtractPairedColumns.nExcludedRows, ")"

@emlTTestPaired: emlExtractPairedColumns.data1#, emlExtractPairedColumns.data2#, 2
appendInfoLine: "paired t = ", fixed$ (emlTTestPaired.t, 4),
...             "  p = ", fixed$ (emlTTestPaired.p, 4)

@emlPearsonCorrelation: emlExtractPairedColumns.data1#, emlExtractPairedColumns.data2#, 2
appendInfoLine: "r = ", fixed$ (emlPearsonCorrelation.r, 4)
```

**Verified output** on an 8-pair test table:

```
complete pairs: 8
paired t = -7.5183  p = 0.0001
r = 0.9798
```

**Nonparametric sibling:** `@emlWilcoxonSignedRank: v1#, v2#, 2` — same
vectors; `@emlMatchedPairsR` is its effect size.

---

## R3 — full analysis with CSV export (the orchestrator path)  [HARNESS-RUN]

**The concept.** The kernels in R1/R2 give you numbers in variables. The
ORCHESTRATORS give you what the menu command gives you: the disclosed report
in the Info window, and result files in the shape R's broom package uses —
because they are the same procedures the menus call. One orchestrator call,
then one exporter call.

**The procedures.**

```praat
# @emlRunAnovaAnalysis: .tableId, .dataCol$, .groupCol$, .doTukey
#   .tableId   - the Table's ID
#   .dataCol$  - numeric measurement column
#   .groupCol$ - grouping column (any number of groups)
#   .doTukey   - 1 = run Tukey HSD post-hoc, 0 = omnibus only
# Prints the full disclosed report to the Info window and declares its
# results to the export buffer. Siblings, same pattern:
#   @emlRunTwoGroupAnalysis, @emlRunKWAnalysis, @emlRunPairedAnalysis,
#   @emlRunCorrelationAnalysis, @emlRunRegressionAnalysis,
#   @emlRunNormalityAnalysis, @emlRunRepeatedMeasuresAnalysis, ...
#   (full list and which declare: docs/API_EXPORT.md §2)

# @emlExportResultFiles: .folder$, .base$
#   .folder$ - destination folder, no trailing slash. MUST ALREADY EXIST.
#   .base$   - file-name stem, no extension; suffixes are appended
# Returns:
#   .declared  - 1 = broom frames written, 0 = legacy single file
#   .success   - 1 if at least one file was written
#   .nWritten  - how many files
#   .fileList$ - absolute paths, one per line
#   .skipped$  - frames left out and why (declared arm)
#   .reason$   - "" ok | "empty" nothing to export | "write" write failed
```

**The script.**

```praat
outputFolder$ = "~/voice_study/results"
createFolder: outputFolder$
data = Read Table from comma-separated file: "~/voice_study/spl_by_group.csv"

@emlRunAnovaAnalysis: data, "SPL_dB", "voice_type", 1
@emlExportResultFiles: outputFolder$, "anova_by_voice_type"

if emlExportResultFiles.success = 0
    appendInfoLine: "nothing written -- reason: ", emlExportResultFiles.reason$
endif
```

Writes `_tidy.csv`, `_glance.csv`, `_augment.csv`, `_posthoc_tidy.csv`,
`_effectsize_tidy.csv` — broom's column names, so R reads them untouched.
The traps (folder must pre-exist; export-after-LMM; base-name uniquing) are
documented in docs/API_EXPORT.md §5–7; read it before batch work.

---

## R4 — batch: one analysis per column, one export each  [HARNESS-RUN]

**The concept.** The exporter reads whatever the MOST RECENT analysis left in
the buffer — so in a loop, each analysis is followed by its own export. Export
after the loop and you get only the last analysis, once.

**The script** (procedures as in R3; from docs/API_EXPORT.md §8):

```praat
outputFolder$ = "~/voice_study/results"
createFolder: outputFolder$
data = Read Table from comma-separated file: "~/voice_study/spl_by_group.csv"

column$ [1] = "SPL_dB"
column$ [2] = "vibrato_rate_Hz"

for i from 1 to 2
    selectObject: data
    @emlRunAnovaAnalysis: data, column$ [i], "voice_type", 1
    @emlExportResultFiles: outputFolder$, "anova_" + column$ [i]
    if emlExportResultFiles.success = 0
        appendInfoLine: "nothing written for ", column$ [i],
        ... " -- reason: ", emlExportResultFiles.reason$
    endif
endfor
```

Two habits worth keeping: `selectObject:` before each analysis (a draw call or
second Table in between changes the selection), and check `.success` inside
the loop — a column that refuses writes nothing, and a batch that doesn't look
will be short a file with no record of which.

---

## R5 — from a Sound to statistics (pitch)  [DRAFT — NOT YET TESTED, do not ship undriven]

**The concept.** The extract module reads Praat analysis objects directly:
a Pitch object becomes a vector of voiced-frame F0 values, and any kernel or
descriptive call takes that vector. This is the bridge from acoustics to the
statistics layer.

**The procedures.**

```praat
# @emlExtractPitchValues: .pitchId, .unit$
#   .pitchId - a Pitch object's ID (from To Pitch: ...)
#   .unit$   - "Hertz" or "semitones" (verify exact accepted strings in the
#              header before shipping this recipe)
# Returns:
#   .data#          - F0 values, VOICED FRAMES ONLY
#   .times#         - corresponding timestamps
#   .n              - number of voiced frames
#   .nTotal         - total frames
#   .nUnvoiced      - unvoiced frames
#   .percentVoiced  - percentage voiced

# Descriptive kernels each take one vector and return .result:
#   @emlMean, @emlMedian, @emlSD, @emlSkewness, @emlKurtosis: .data#
#   @emlQuartiles: .data#  returns .q1, .q2, .q3
#   @emlPercentile: .data#, .p  (0-100)
```

**The script.**

```praat
sound = Read from file: "~/voice_study/sustained_a.wav"
pitch = To Pitch: 0, 75, 600

@emlExtractPitchValues: pitch, "Hertz"
f0# = emlExtractPitchValues.data#
appendInfoLine: "voiced frames: ", emlExtractPitchValues.n,
...             " of ", emlExtractPitchValues.nTotal,
...             " (", fixed$ (emlExtractPitchValues.percentVoiced, 1), "% voiced)"

@emlMedian: f0#
appendInfoLine: "median F0 = ", fixed$ (emlMedian.result, 2), " Hz"
```

(Opus: drive this before shipping — verify `.unit$`'s accepted strings and
every output name against the headers. R1 and R2 both needed exactly that
correction when first written.)

---

## For Opus — shipping requirements

1. This file ships as plugin/docs/RECIPES.md (inside the plugin folder, so it
   travels with the install), linked from both READMEs.
2. A recipes harness runs R1–R5 verbatim (the v50/api_export pattern) and a
   validator pins their printed outputs. No recipe ships undriven — R5
   explicitly blocked on this.
3. The annotation blocks above were copied from the procedure headers at HEAD.
   The harness should ALSO diff each annotation block against the live header
   (argument and output names), so a future signature change turns this file
   red instead of letting it drift — the recipes are documentation of record
   once shipped.
4. When the aggregation pathway (roadmap Phase 1) ships, add R6: collapse
   tokens to subject medians, then paired comparison — it will be the most
   common real workflow in this plugin's audience.
