<!--
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
-->

# Recipes — calling the statistics from your own Praat script

Five worked examples for the workflows a voice researcher actually has. Each one
shows the concept — which procedure, what its arguments mean, what variables it
hands back — and then a **complete script you can paste and run**.

`docs/API_EXPORT.md` covers the export in depth: the file shapes, the traps, the
folder rules. This page covers the layer underneath it — the kernels, which take
plain vectors and hand back numbers in variables, with no files and no windows
involved — and then shows how the two fit together.

**Every script on this page is run verbatim before it ships.** `harness/recipes/`
extracts the code blocks below out of this file — the same bytes you will paste,
not a copy of them — and runs each one in its own Praat process.
`validate/v81_recipes.R` then holds the run to three things it cannot move: the
"What it printed" blocks below, which are the capture rather than a
transcription; what base R computes from the same data; and the procedure
headers in `stats/`, so a name on this page that no procedure answers to turns
the suite red. A documented example is a tested example.

---

## Rules of the road

Read once; it saves an hour.

- **Praat script variables must start with a LOWERCASE letter.** `P$ = ...`
  stops the script; `p$ = ...` runs.
- **Two things in each script are yours to change, and nothing else is:** the
  include block, and the paths to your own data. Every script below opens with
  an include block written for Praat 6.x on Linux; if your plugin lives
  somewhere else, change the prefix — run `writeInfoLine: preferencesDirectory$`
  in Praat to see where. `docs/API_EXPORT.md` §3 lists the four platform
  locations and the one-line alternative that `setup.praat` writes for your own
  machine. The `~/voice_study/…` paths are placeholders for your files.
- **The list is in dependency order** — later files call earlier ones. Praat
  resolves a relative `include` against the folder of the top-level script that
  was run, which is why the barrel the plugin uses internally
  (`scripts/eml-lib.praat`) cannot be included from your own folder: its own
  includes would then be resolved against yours.
- **An easy way to get the block right:** record any trivial workflow (**New →
  EML → Record script**, run one analysis, stop and save) and copy the include
  block from the top of the saved script. The recorder resolves the plugin's
  location on *your* machine at save time and writes the paths gated on your OS
  and Praat version, so the block is correct by construction.
- **After `@someProcedure: args`, its outputs are read as
  `someProcedure.outputName`** — the procedure's name is the prefix. The values
  persist until that procedure is called again.
- **Check `.error$` after any call that has one.** A refused call sets `.error$`
  and returns; it does not stop your script, so reading its other outputs
  without checking gives you zeros or stale values from the previous call.
- **House style is modern Praat script:** colon-form commands, and the braced
  vector form for list arguments — `{ "spl", "group" }`, never the legacy
  space-separated string, which splits a name like `F0 mean` into two columns.
- **The procedure headers are the reference.** Argument and output names on this
  page are copied from them; when the two could ever disagree, believe the
  header in `stats/`.

---

## R1 — compare two groups from a table

**The concept.** Three steps, three procedures. First, turn two groups' rows
into two numeric vectors. Second, hand the vectors to a test kernel. Third, hand
the same vectors to an effect-size kernel. Every kernel takes plain vectors — it
neither knows nor cares that they came from a Table.

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
#   .d                - Cohen's d (positive when mean1 > mean2)
#   .g                - Hedges' g (bias-corrected d, better for small samples)
#   .pooledSD         - the standardizer
#   .correctionFactor - J, the Hedges correction: g = d * J
#   .mean1, .mean2, .n1, .n2
#   .error$           - "" on success
```

`.tails = 1` fixes the alternative at H1: mean1 > mean2, the way R's
`t.test(v1, v2, alternative = "greater")` does. Run in the wrong direction it
returns a p near 1, not near 0 — which is why `@emlTTestAlt`, which names the
direction in words, is the safer call.

**The script.**

```praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-core-utilities.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-core-descriptive.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-extract.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-output.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-inferential.praat

data = Read Table from comma-separated file: "~/voice_study/spl_by_group.csv"

# Table rows -> two named vectors
@emlExtractGroupVectors: data, "spl", "group", "soprano", "mezzo"
if emlExtractGroupVectors.error$ <> ""
    exitScript: emlExtractGroupVectors.error$
endif
v1# = emlExtractGroupVectors.group1#
v2# = emlExtractGroupVectors.group2#
writeInfoLine: "n soprano = ", emlExtractGroupVectors.n1,
...            "  n mezzo = ", emlExtractGroupVectors.n2,
...            "  excluded = ", emlExtractGroupVectors.nExcluded

# Welch t-test, two-sided
@emlTTest: v1#, v2#, 2, 0
appendInfoLine: "t = ", fixed$ (emlTTest.t, 4),
...             "  df = ", fixed$ (emlTTest.df, 2),
...             "  p = ", fixed$ (emlTTest.p, 4)

# Directional hypothesis, stated in words
@emlTTestAlt: v1#, v2#, "less", 0
appendInfoLine: "H1 soprano < mezzo: p = ", fixed$ (emlTTestAlt.p, 4)

# Effect size
@emlCohenD: v1#, v2#
appendInfoLine: "d = ", fixed$ (emlCohenD.d, 4),
...             "  (Hedges' g = ", fixed$ (emlCohenD.g, 4), ")"
```

**What it printed** — a 5-vs-5 table, soprano mean 81, mezzo mean 90:

```
n soprano = 5  n mezzo = 5  excluded = 0
t = -5.6921  df = 5.88  p = 0.0014
H1 soprano < mezzo: p = 0.0007
d = -3.6000  (Hedges' g = -3.2516)
```

**Nonparametric siblings**, same vectors, same shape. `@emlMannWhitneyU: v1#,
v2#, 2` returns `.u1`, `.u2`, `.p`, `.pGreater`, `.pLess`, `.alternative$`, rank
sums `.r1`/`.r2`, `.hasTies`, `.z`, and `.method$` — `"exact"` or `"normal
approximation"`, chosen the way R's `wilcox.test` chooses. `@emlRankBiserialR:
v1#, v2#, 2` is its effect size.

---

## R2 — paired columns and correlation from a wide table

**The concept.** A wide table — one row per subject, one column per condition —
becomes two aligned vectors. Complete pairs only, with the dropped rows counted
rather than silently ignored. The paired kernel tests the within-subject
difference; the correlation kernels measure association on the same two vectors.

**The procedures.**

```praat
# @emlExtractPairedColumns: .tableId, .col1$, .col2$
#   .tableId       - the Table's ID
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
#          .sdDiff, .seDiff, .n, .error$

# @emlPearsonCorrelation: .x#, .y#, .tails
#   Directional form: @emlPearsonCorrelationAlt: .x#, .y#, .alternative$
# Returns: .r, .t, .df, .p, .pGreater, .pLess, .alternative$, .n,
#          .error$, .warning$, .perfect

# @emlSpearmanCorrelation: .x#, .y#, .tails
#   Rank-based, and the same shape as Pearson except that the coefficient
#   is called .rho rather than .r.
```

`.perfect` is 1 when |r| = 1: t is infinite there and is reported as undefined,
so a script that prints `.t` without looking at `.perfect` prints `--undefined--`
on exactly the data that fits best.

**The script.**

```praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-core-utilities.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-core-descriptive.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-extract.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-output.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-inferential.praat

data = Read Table from comma-separated file: "~/voice_study/pre_post.csv"

@emlExtractPairedColumns: data, "pre", "post"
if emlExtractPairedColumns.error$ <> ""
    exitScript: emlExtractPairedColumns.error$
endif
writeInfoLine: "complete pairs: ", emlExtractPairedColumns.n,
...            "  (dropped: ", emlExtractPairedColumns.nExcludedRows, ")"

@emlTTestPaired: emlExtractPairedColumns.data1#, emlExtractPairedColumns.data2#, 2
appendInfoLine: "paired t = ", fixed$ (emlTTestPaired.t, 4),
...             "  df = ", emlTTestPaired.df,
...             "  p = ", fixed$ (emlTTestPaired.p, 4)

@emlPearsonCorrelation: emlExtractPairedColumns.data1#, emlExtractPairedColumns.data2#, 2
appendInfoLine: "r = ", fixed$ (emlPearsonCorrelation.r, 4),
...             "  p = ", fixed$ (emlPearsonCorrelation.p, 4)
```

**What it printed** — a nine-row table of jitter before and after therapy, one
row of which has no `post` value:

```
complete pairs: 8  (dropped: 1)
paired t = 3.1206  df = 7  p = 0.0168
r = 0.7897  p = 0.0197
```

The dropped row is the point of the count. Eight pairs were tested and the ninth
subject was left out, and the script says so rather than quietly reporting n = 8
from a table with nine rows in it.

**Nonparametric sibling:** `@emlWilcoxonSignedRank: v1#, v2#, 2` — same vectors,
returning `.tPlus`, `.tMinus`, `.p`, `.nNonzero`, `.nZero`, `.hasTies` and
`.method$`. `@emlMatchedPairsR` is its effect size.

---

## R3 — a full analysis with CSV export

**The concept.** The kernels in R1 and R2 give you numbers in variables. The
**orchestrators** give you what the menu command gives you — the disclosed report
in the Info window, and result files in the shape R's **broom** package uses —
because they are the same procedures the menus call. One orchestrator call, then
one exporter call.

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
#   (full list, and which of them declare: docs/API_EXPORT.md §2)

# @emlExportResultFiles: .folder$, .base$
#   .folder$ - destination folder, no trailing slash. MUST ALREADY EXIST.
#   .base$   - file-name stem, no extension; suffixes are appended
# Returns:
#   .declared    - 1 = broom frames written, 0 = legacy single file
#   .success     - 1 if at least one file was written
#   .nWritten    - how many files
#   .fileList$   - absolute paths, one per line
#   .skipped$    - frames left out and why (declared arm)
#   .actualPath$ - the single file written (legacy arm)
#   .reason$     - "" ok | "empty" nothing to export | "write" write failed
```

**The script.** This one needs the full eleven-line block: the orchestrators and
their reporters live in further modules.

```praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-core-utilities.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-core-descriptive.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-extract.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-output.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-inferential.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-result-writer.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-record.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/graphs/eml-graph-procedures.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/graphs/eml-annotation-procedures.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/graphs/eml-draw-procedures.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-analysis.praat

outputFolder$ = "~/voice_study/results"
createFolder: outputFolder$
data = Read Table from comma-separated file: "~/voice_study/singers.csv"

@emlRunAnovaAnalysis: data, "SPL_dB", "voice_type", 1
@emlExportResultFiles: outputFolder$, "anova_by_voice_type"

appendInfoLine: "declared = ", emlExportResultFiles.declared,
...             "  files written = ", emlExportResultFiles.nWritten,
...             "  reason = [", emlExportResultFiles.reason$, "]"
if emlExportResultFiles.success = 0
    appendInfoLine: "nothing written -- reason: ", emlExportResultFiles.reason$
endif
```

It writes `_tidy.csv`, `_glance.csv`, `_augment.csv`, `_posthoc_tidy.csv` and
`_effectsize_tidy.csv` under the base name — broom's column names, so R reads
them untouched. The report above them is what the menu command prints.

**What it printed.** The disclosed report is long — the ANOVA table, the
assumption checks, the group descriptives, the Tukey matrix, and a plain-English
reading of each. Its centre:

```
Source              SS              df    MS              F           p
Between             601.78          2     300.89          18.0603     < .001
Within              699.74          42    16.66
Total               1301.52         44
```

and the line the script itself added, after the report and after the files were
written:

```
declared = 1  files written = 5  reason = []
```

The traps — the folder must already exist, export must follow the analysis it
belongs to, base names are uniqued rather than overwritten — are in
`docs/API_EXPORT.md` §5–7. Read it before batch work.

---

## R4 — batch: one analysis per column, one export each

**The concept.** The exporter reads whatever the **most recent** analysis left in
the buffer. So in a loop, each analysis is followed by its own export. Export
after the loop instead and you get only the last analysis, once.

**The script.**

```praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-core-utilities.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-core-descriptive.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-extract.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-output.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-inferential.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-result-writer.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-record.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/graphs/eml-graph-procedures.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/graphs/eml-annotation-procedures.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/graphs/eml-draw-procedures.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-analysis.praat

outputFolder$ = "~/voice_study/results"
createFolder: outputFolder$
data = Read Table from comma-separated file: "~/voice_study/singers.csv"

column$ [1] = "SPL_dB"
column$ [2] = "vibrato_rate_Hz"

for i from 1 to 2
    selectObject: data
    @emlRunAnovaAnalysis: data, column$ [i], "voice_type", 1
    @emlExportResultFiles: outputFolder$, "anova_" + column$ [i]
    appendInfoLine: "BATCH ", column$ [i],
    ... ": written = ", emlExportResultFiles.nWritten,
    ... "  success = ", emlExportResultFiles.success
    if emlExportResultFiles.success = 0
        appendInfoLine: "nothing written for ", column$ [i],
        ... " -- reason: ", emlExportResultFiles.reason$
    endif
endfor
```

**What it printed.** Each pass through the loop printed its own full report and
then its own batch line — the two are not adjacent in the Info window, because
the second analysis's report sits between them. After the first column:

```
BATCH SPL_dB: written = 5  success = 1
```

and after the second:

```
BATCH vibrato_rate_Hz: written = 5  success = 1
```

Two habits worth keeping. `selectObject:` before each analysis — the
orchestrators leave your Table selected when they finish, but a draw call or a
second Table in between will not. And check `.success` **inside** the loop: a
column that refuses writes nothing and moves on, and a batch that does not look
will be short a file with no record of which one.

---

## R5 — from a Sound to statistics

**The concept.** The extract module reads Praat's own analysis objects directly.
A Pitch object becomes a vector of voiced-frame F0 values, and any kernel or
descriptive call takes that vector. This is the bridge from acoustics to the
statistics layer.

**The procedures.**

```praat
# @emlExtractPitchValues: .pitchId, .unit$
#   .pitchId - a Pitch object's ID (from To Pitch: ...)
#   .unit$   - a unit Praat's own "Get value at time..." accepts, spelled its
#              way: "Hertz", "semitones re 100 Hz", "mel", "ERB".
#              "semitones" alone is not one of them and stops the script.
# Returns:
#   .data#          - F0 values, VOICED FRAMES ONLY
#   .times#         - corresponding timestamps
#   .n              - number of voiced frames
#   .nTotal         - total frames
#   .nUnvoiced      - unvoiced frames
#   .percentVoiced  - percentage voiced

# @emlExtractFormantValues: .formantId, .formantNumber, .unit$
#   The same shape for a Formant object.
# Returns:
#   .data#       - frequency values, DEFINED FRAMES ONLY
#   .times#      - corresponding timestamps
#   .bandwidths# - corresponding bandwidths
#   .n           - defined frames
#   .nTotal      - total frames
```

There is no `.error$` on either extractor: an empty analysis object comes back
with `.n = 0` and an empty `.data#`, which is what the descriptive kernels
expect.

**The descriptive kernels.** Each takes one vector. `@emlMean`, `@emlMedian`,
`@emlSD`, `@emlSEM`, `@emlSkewness` and `@emlKurtosis` all return `.result`;
`@emlSkewness` and `@emlKurtosis` also set `.error$`, because both are undefined
for a short vector (n < 3 and n < 4) and for one with no spread at all. Three
return named parts instead:

```praat
# @emlQuartiles: .data#
# Returns:
#   .q1, .q2, .q3, .iqr

# @emlRange: .data#
# Returns:
#   .min, .max, .range

# @emlCI: .data#, .confidenceLevel
#   The level is a FRACTION -- 0.95, not 95.
# Returns:
#   .mean, .lower, .upper, .marginOfError

# @emlPercentile: .data#, .p
#   Second argument is the percentile, on 0 to 100.
# Returns:
#   .result
```

**The script.**

```praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-core-utilities.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-core-descriptive.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-extract.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-output.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-inferential.praat

sound = Read from file: "~/voice_study/sustained_a.wav"
pitch = To Pitch: 0, 75, 600

@emlExtractPitchValues: pitch, "Hertz"
f0# = emlExtractPitchValues.data#
writeInfoLine: "voiced frames: ", emlExtractPitchValues.n,
...            " of ", emlExtractPitchValues.nTotal,
...            " (", fixed$ (emlExtractPitchValues.percentVoiced, 1), "% voiced)"

@emlMedian: f0#
appendInfoLine: "median F0 = ", fixed$ (emlMedian.result, 2), " Hz"

@emlQuartiles: f0#
appendInfoLine: "IQR = ", fixed$ (emlQuartiles.q1, 2),
...             " to ", fixed$ (emlQuartiles.q3, 2), " Hz"

@emlSD: f0#
appendInfoLine: "SD = ", fixed$ (emlSD.result, 2), " Hz"
```

**What it printed** — a two-second synthetic vowel on G3 with 5 Hz vibrato and a
silent gap in the middle:

```
voiced frames: 158 of 197 (80.2% voiced)
median F0 = 196.01 Hz
IQR = 188.59 to 201.80 Hz
SD = 6.97 Hz
```

The silent gap is why `.nTotal` and `.n` differ, and it is the reason the
procedure reports both. A Pitch object has a frame everywhere; only some of them
carry a value, and a mean taken over all of them would be a mean over a variable
that does not exist in the silence.

A Formant object goes the same way: `@emlExtractFormantValues` in place of
`@emlExtractPitchValues`, and `@emlMean` or `@emlSD` on the vector it hands back.

---

## Where the evidence is

| | |
|---|---|
| the kernels | `stats/eml-inferential.praat`, `stats/eml-core-descriptive.praat` |
| the extractors | `stats/eml-extract.praat` |
| the orchestrators | `stats/eml-analysis.praat` |
| the exporter | `stats/eml-output.praat`, `@emlExportResultFiles` |
| the export in depth | `docs/API_EXPORT.md` |
| the harness that runs this page | `bash harness/recipes/run.sh` |
| the checks | `Rscript validate/v81_recipes.R` |
