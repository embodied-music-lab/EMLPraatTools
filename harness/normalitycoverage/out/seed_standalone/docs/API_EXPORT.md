<!--
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
-->

# Exporting results from your own Praat script

**`@emlExportResultFiles`** — the export the plugin uses when you press **Save**,
called directly from a script you wrote.

This page is for the case where you are not clicking. You have twenty singers'
files, or forty vowels, and you want one analysis run over all of them with the
result files written as you go. Everything the Save dialog does is available to
a script; this is the one procedure that does the writing.

Nothing on this page opens a window. The procedure asks no questions, prints no
dialog and returns to your script, which is what makes it usable inside a loop.

Every claim here was checked by running it. `harness/api_export/run.sh` drives
the procedure eight ways and `validate/v50_api_export.R` reads what came out —
including the example script below, which the harness runs verbatim, and the
batch loop in §8, which it runs too.

---

## 1. What you get: two shapes, and which one arrives

The plugin is part-way through a migration, and the export has a fork in it.
Which side you land on is decided by the **analysis you ran**, not by anything
you pass to the exporter.

### The broom shape — when the analysis *declared*

Most analyses describe their results to the plugin cell by cell, in the shape
R's **broom** package uses. When one of those has run, the export writes a
**set of files sharing one base name**:

| file | one row per | contents |
|---|---|---|
| `<base>_tidy.csv` | model **term** | what `broom::tidy()` returns |
| `<base>_glance.csv` | **model** | what `broom::glance()` returns — one row |
| `<base>_augment.csv` | **observation** | your input table plus `.fitted`, `.resid`, … |
| `<base>_posthoc_tidy.csv` | contrast | staged extra: Tukey, Dunn, pairwise |
| `<base>_effectsize_tidy.csv` | effect | staged extra: eta², Cohen's *d*, … |

The first three are the standard set. The last two appear only when the
analysis produced them — a post-hoc test is a *separate model object* in R and
gets its own `tidy()` call there, so it gets its own file here.

A one-way ANOVA with Tukey on the shipped demo data writes all five. Its
`_tidy.csv`:

```
term,df,sumsq,meansq,statistic,p.value
voice_type,2,601.7837208125036,300.8918604062518,18.060297415058738,2.1885613623027198e-06
Residuals,42,699.736989188529,16.66040450448879,,
```

Those two empty cells on the `Residuals` row are deliberate: an ANOVA has no
*F* and no *p* for its residual line, and R reads an empty cell as `NA`. The
column names and their order are broom's, so `read_csv()` followed by
`modelsummary`, `gt` or `flextable` works on these files untouched.

**A frame with no rows produces no file.** That is not a failure, and the
procedure tells you which frames it left out and why — see `.skipped$` in §4. A
normality test, for instance, has no per-observation quantity, so it writes
`_tidy.csv` and `_glance.csv` and reports

```
augment: this analysis has no per-observation quantities
```

An empty `_augment.csv` containing only a header would be indistinguishable
from a failed export, which is why one is never written.

### The legacy shape — when the analysis did *not* declare

An analysis that has not been converted fills a single long-format buffer
instead, and the export writes **one file**, `<base>.csv`, with six columns:

```
table,analysis,term,term_type,field,value
demo_3groups_input,Descriptive statistics,SPL_dB,group,n,45
demo_3groups_input,Descriptive statistics,SPL_dB,group,mean,88.95182018331927
```

One row per number rather than one row per term. It is honest and complete, but
it is not broom-shaped: you will reshape it yourself on the R side.

### Which one you get — never both, never neither

The fork is on **whether the analysis declared**, and only that. The exporter
does not consult a list of analysis names, so a path converts by declaring and
nothing here changes. In one call you get the broom set or the legacy file, and
`.declared` tells you which happened.

---

## 2. Which analyses declare

Read this as the state of the migration on **14 August 2026**, not as a
permanent property. `validate/v50_api_export.R` reads the list back out of
`stats/eml-analysis.praat` and fails if this table drifts.

**These DECLARE** — you get broom frames:

| procedure | what it is |
|---|---|
| `@emlRunTwoGroupAnalysis` | *t*-test / Mann–Whitney |
| `@emlRunAnovaAnalysis` | one-way ANOVA (+ Tukey) |
| `@emlRunKWAnalysis` | Kruskal–Wallis (+ Dunn) |
| `@emlRunPairwiseAnalysis` | pairwise comparisons |
| `@emlRunTwoWayAnalysis` | two-way ANOVA |
| `@emlRunPairedAnalysis` | paired *t* / Wilcoxon |
| `@emlRunCorrelationAnalysis` | Pearson / Spearman |
| `@emlRunRegressionAnalysis` | simple linear regression |
| `@emlRunNormalityAnalysis` | Shapiro–Wilk + shape statistics |
| `@emlRunRepeatedMeasuresAnalysis` | RM-ANOVA |
| `@emlRunFriedmanAnalysis` | Friedman |

**This one does NOT** — you get the legacy file:

| procedure | what it is |
|---|---|
| `@emlRunDescriptiveAnalysis` | descriptive statistics for one column |

`@emlRunDescriptiveAnalysis` became exportable on **14 August 2026** and it was
deliberately wired to the **legacy buffer**, not converted. The reason is the
tidy vocabulary: it is a whitelist of broom's column names — a name outside it
is refused outright — and a descriptive pass reports sixteen statistics of
which only `skewness` and `kurtosis` are in it. `q1`, `q3`, `iqr`, `min`,
`max`, `range`, `variance` and the median have no broom name to be filed
under. One long-format file keeps all sixteen.

**Two procedures export nothing at all.** `@emlRunReliabilityAnalysis` is a
Phase 4 stub and refuses immediately. `@emlRunLMMAnalysis` computes a real
mixed model but writes into neither buffer — **do not call the exporter after
it**, and see §7.

---

## 3. A complete script

Save this as `my_analysis.praat` anywhere you like — your Desktop, your project
folder — and run it with **Praat → Open Praat script…** then **Run**, or from a
terminal with `praat --run my_analysis.praat`.

**The include block is the only part you may have to edit,** and only if your
plugin lives somewhere other than the Linux/Praat 6 location below. The other
locations are:

```
Praat 6.x  Linux    ~/.praat-dir/plugin_EML_StatsGraphs
Praat 7.x  Linux    ~/.config/praat/plugin_EML_StatsGraphs
macOS               ~/Library/Preferences/Praat Prefs/plugin_EML_StatsGraphs
Windows             ~/Praat/plugin_EML_StatsGraphs
```

Not sure? Run `writeInfoLine: preferencesDirectory$` in Praat and look.

### One line, and it is written for your machine

`setup.praat` runs every time Praat starts, from the folder the plugin is
installed in, and writes `eml-lib-user.praat` into the plugin's own `scripts/`
folder with the paths for **your** installation already filled in, so the whole
include block collapses
to one line — pick the row for your platform and paste the line:

| Praat / OS | the one line |
| --- | --- |
| Praat 6.x Linux | `include ~/.praat-dir/plugin_EML_StatsGraphs/scripts/eml-lib-user.praat` |
| Praat 7.x Linux | `include ~/.config/praat/plugin_EML_StatsGraphs/scripts/eml-lib-user.praat` |
| macOS | `include ~/Library/Preferences/Praat Prefs/plugin_EML_StatsGraphs/scripts/eml-lib-user.praat` |
| Windows | `include ~/Praat/plugin_EML_StatsGraphs/scripts/eml-lib-user.praat` |

It loads exactly the modules below, in the same order. Move the plugin,
or upgrade to a Praat that keeps its preferences somewhere else, and the next
launch rewrites the file for the new location; a launch that would change
nothing writes nothing. Do not edit it — it is generated, and your edit goes
away the next time the paths change.

### The full include block, which always works

Written out, this is what that one line expands to, and it is the fallback if
the generated file is not there — a plugin folder that cannot be written to,
or a script that has to run on a machine where Praat has never been started
since the plugin was installed. It is also what the workflow recorder writes
into every script it emits.

```praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-core-utilities.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-core-descriptive.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-extract.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-output.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-inferential.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-psychometrics.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-categorical.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-result-writer.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-record.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/graphs/eml-graph-procedures.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/graphs/eml-annotation-procedures.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/graphs/eml-draw-procedures.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-analysis.praat

# Where the numbers come from, and where the files go.
inputFile$  = "~/voice_study/demo_3groups_input.csv"
outputFolder$ = "~/voice_study/results"
baseName$   = "anova_by_voice_type"

# THE FOLDER IS YOURS TO MAKE. The Save dialog calls createFolder: on whatever
# you typed into it; @emlExportResultFiles does not, and Praat stops the whole
# script on the first write into a folder that is not there.
createFolder: outputFolder$

# One Table, read the way Praat reads any CSV.
data = Read Table from comma-separated file: inputFile$

# The analysis. This one DECLARES, so the export below writes broom frames.
@emlRunAnovaAnalysis: data, "SPL_dB", "voice_type", 1

# The export. No dialog, no questions: a folder and a base name.
@emlExportResultFiles: outputFolder$, baseName$

# What it did. Read these rather than assuming -- an analysis that declared
# nothing and an analysis that failed both come back with nWritten = 0, and
# .reason$ is what tells them apart.
appendInfoLine: "declared : ", emlExportResultFiles.declared
appendInfoLine: "success  : ", emlExportResultFiles.success
appendInfoLine: "written  : ", emlExportResultFiles.nWritten
appendInfoLine: "reason   : ", emlExportResultFiles.reason$
if emlExportResultFiles.declared = 1
    appendInfoLine: "frames written:"
    appendInfoLine: emlExportResultFiles.fileList$
    if emlExportResultFiles.skipped$ <> ""
        appendInfoLine: "frames skipped, and why:"
        appendInfoLine: emlExportResultFiles.skipped$
    endif
else
    appendInfoLine: "one long-format file: ", emlExportResultFiles.actualPath$
endif
```

Running it on the shipped demo table prints:

```
declared : 1
success  : 1
written  : 5
reason   :
frames written:
…/anova_by_voice_type_tidy.csv
…/anova_by_voice_type_glance.csv
…/anova_by_voice_type_augment.csv
…/anova_by_voice_type_posthoc_tidy.csv
…/anova_by_voice_type_effectsize_tidy.csv
```

### Why the long include list, and not `include eml-lib.praat`

The plugin ships barrels — `scripts/eml-lib.praat`, `scripts/eml-lib-stats.praat`
— and they are the right thing for a script that lives **inside**
`plugin/scripts/`, which is where all sixteen menu commands live.

They do not work from your own folder, and the reason is a rule of Praat's
`include`, not a bug in the plugin. **A relative path inside an included file
resolves against the folder of the script you RAN, not the folder of the file
the line is written in.** The barrel's own lines read `include ../stats/…`, so
running your script from `~/voice_study/` makes Praat look for
`~/voice_study/../stats/…` and stop with

```
Error: Cannot open file "…/../stats/eml-core-utilities.praat".
```

Giving the barrel an absolute path does not help: the failure is one level in,
in the barrel's own relative lines. Measured on Praat 6.6.30, 14 August 2026,
and it is the same reason the workflow recorder writes out a full include list
rather than a barrel.

**`eml-lib-user.praat` is the one barrel that does work from your folder**, and
the difference is that its lines are not relative. A shipped file cannot know
where it will be installed; `setup.praat` runs from there, so it can, and it
writes the paths out in full. That is why the one-line include above is a
generated file and not a shipped one.

So: one generated line, or the whole block written out. The block is pasted
verbatim from what the recorder emits, and the order matters — later files
call into earlier ones.

**`eml-lib-stats.praat` is not enough on its own** even when the paths do
resolve. It stops at the statistics engine; the orchestrators live in
`stats/eml-analysis.praat`, and their reporters live in
`graphs/eml-annotation-procedures.praat`. Omit either and
`@emlRunAnovaAnalysis` stops with *Procedure "emlReportAnovaComparison" not
found* — from the middle of the analysis, after it has already printed.

---

## 4. What the procedure gives you back

```praat
@emlExportResultFiles: .folder$, .base$
```

| argument | |
|---|---|
| `.folder$` | destination folder, **no trailing slash**. Must already exist. |
| `.base$` | file-name stem, **no extension**. Suffixes are appended for you. |

`.base$` is a *base name*, not a file name. Typing `"results.csv"` gets you
`results.csv_tidy.csv`.

Afterwards, seven outputs:

| output | |
|---|---|
| `.declared` | `1` if the analysis declared and you got broom frames; `0` if it fell back to the legacy file. |
| `.success` | `1` if at least one file was written. |
| `.nWritten` | how many files. `5` for ANOVA-with-Tukey, `1` for the legacy arm, `0` for an empty export. |
| `.fileList$` | the absolute paths, one per line, newline-separated. Empty when nothing was written. |
| `.skipped$` | *(declared arm)* which frames were left out and why, one `verb: reason` per line. Empty when all three were written. |
| `.actualPath$` | *(legacy arm)* the single file written. **See the warning below.** |
| `.reason$` | `""` when all is well, `"empty"` when there was nothing to write, `"write"` when the write itself failed. |

**`.reason$ = "empty"` is the one to check for.** It means the procedure ran
correctly and had nothing to export — either nothing declared and the legacy
buffer was empty, or an analysis declared but produced no rows. It is not a
disk error, and a caller that reports it as one tells the user their disk
refused a file the plugin never attempted to write.

> **Careful with `.actualPath$`.** On the legacy arm it is set to the path the
> procedure *would have used* **even when nothing was written** — after an
> empty export it names a `.csv` that does not exist. Branch on `.success` or
> `.nWritten`, never on `.actualPath$` being non-empty.

### Calling it when nothing has run

This is legal, it is defined, and it does not stop your script:

```
declared = 0    success = 0    nWritten = 0    reason$ = "empty"
```

No file is created. It matters because it is the *first* call in a fresh
session, before any analysis — the one case the Save dialog can never reach,
because the dialog only offers a CSV tickbox once there is something to export.
(The guard that makes this survive is written as nested `if`s rather than
`and`, because Praat evaluates **both** sides of `and` before applying it and
would abort on `emlResult_declared` not existing.)

---

## 5. The folder must already exist

`@emlExportResultFiles` contains **no `createFolder:`**. The Save dialog calls
it — `folder:` is a freely editable field, so a user can type a path that is
not there yet — but that call is in `@emlSavePanel`, before the exporter, and
an API caller inherits none of it.

Skip it and Praat stops your whole script at the first write:

```
Error: Cannot create file “…/results/anova_by_voice_type_tidy.csv”.
Hint: one of the folders in this file path does not exist.
Formula not run.
Script line 13456 not performed or completed:
« writeFile: .path$, eml_renderTidy.text$ »
```

The line number is inside the plugin, not inside your script, which is what
makes this one confusing to meet for the first time.

**Control never returns to your script**, so there is no `.success` to test and
no `.reason$` to read — the procedure's outputs are not merely wrong, they are
gone, and Praat reports *Unknown variable* if you try to read them. Both arms
fail this way; neither degrades gracefully.

One line prevents it, and it is free to repeat — `createFolder:` on a folder
that already exists does nothing:

```praat
createFolder: outputFolder$
```

---

## 6. Running it twice: what happens to the first set

Both arms are non-destructive, but they protect themselves differently.

**The declared arm uniques the BASE, once, against the tidy frame.** Before
writing anything it probes `<base>_tidy.csv`. If that file is there it walks
`<base>_1`, `<base>_2`, … until it finds a free one, and then **every frame in
the set uses the walked base**:

```
first call   twice_tidy.csv    twice_glance.csv    twice_augment.csv    twice_posthoc_tidy.csv    twice_effectsize_tidy.csv
second call  twice_1_tidy.csv  twice_1_glance.csv  twice_1_augment.csv  twice_1_posthoc_tidy.csv  twice_1_effectsize_tidy.csv
```

The point is that the *set stays a set*. Uniquing each file independently — the
obvious implementation — would leave frame 1 of the new export sitting beside
frames 2 and 3 of the old one under names that read as siblings, which is a
worse outcome than an honest overwrite. The tidy frame is the probe because it
is the frame the writer always attempts.

**The legacy arm** uniques the single file instead, inside the writer:
`describe_spl.csv`, then `describe_spl_1.csv`.

**If you want your own naming**, put it in `.base$` — a timestamp is what the
Save dialog seeds its field with, and it sorts chronologically in a file
browser where `_1`, `_2` does not:

```praat
@emlFileStamp
@emlExportResultFiles: outputFolder$, "anova_" + emlFileStamp.result$
```

One caveat if you are cleaning up between runs: the probe looks at
`<base>_tidy.csv` only. Delete that file and leave its siblings, and the next
export under the same base will overwrite them.

---

## 7. Known trap: do not export after a mixed model

`@emlRunLMMAnalysis` is the one analysis procedure that writes into **neither**
buffer — it neither declares nor fills the legacy buffer, and, unlike every
other orchestrator, it does not clear them on entry either.

So if you run something else first and then export after an LMM:

```praat
@emlRunAnovaAnalysis: data, "SPL_dB", "voice_type", 1
@emlRunLMMAnalysis:   data, "SPL_dB ~ vibrato_rate_Hz + (1 | voice_type)", "treatment", 1, 1, 1
@emlExportResultFiles: outputFolder$, "lmm_results"
```

you get five files called `lmm_results_*` **containing the ANOVA**.
`lmm_results_glance.csv` says `method = One-way ANOVA` in a file named for a
mixed model. Verified 14 August 2026 on Praat 6.6.30. Nothing warns you.

Menu users are not exposed to this — the LMM window has no Save button, which
is consistent with there being nothing to save. Until the LMM path is
converted, treat its results as Info-window output only, and if you must export
around it, run the exporter **before** the LMM call.

---

## 8. Putting it in a loop

The pattern for a batch. Note that the analysis is re-run each time, which is
what refills the collectors — the exporter reads whatever the *most recent*
analysis left, so one export must follow each analysis, not follow the loop.

```praat
createFolder: outputFolder$
data = Read Table from comma-separated file: inputFile$

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

Two habits worth keeping:

- **`selectObject:` before each analysis.** The orchestrators leave your Table
  selected when they finish, but a draw call or a second Table in between will
  not.
- **Check `.success` inside the loop.** A column that refuses — non-numeric,
  fewer than two groups — writes nothing and moves on, and a batch that does
  not look will be short a file with no record of which one.

---

## 9. Where the evidence is

| | |
|---|---|
| the procedure | `stats/eml-output.praat`, `@emlExportResultFiles` |
| the frame writer | `stats/eml-result-writer.praat` |
| which analyses declare | `stats/eml-analysis.praat`, the `@emlDeclare*` procedures |
| the harness | `bash harness/api_export/run.sh` |
| the checks | `Rscript validate/v50_api_export.R` |
| the dialog path, for comparison | `harness/savepaths/`, `validate/v48_save_paths.R` |
