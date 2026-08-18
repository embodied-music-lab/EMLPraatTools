# EML Stats & Graphs

Statistical analysis and publication-quality graphing for Praat. Run t-tests, correlations, ANOVAs, and nonparametric tests without leaving Praat — no R or Python export required. Format results for direct inclusion in manuscripts.

## Installation

Installing takes about two minutes. You download one file, unzip it, drag the
folder that comes out into Praat's preferences folder, and restart Praat.
There is nothing to compile and no other software to install.

### Step 1 — Download the plugin

Go to the Releases page:

https://github.com/embodied-music-lab/EMLPraatTools/releases

Download the file named **plugin_EML_StatsGraphs.zip** from the most recent
release.

### Step 2 — Unzip it

Double-click the downloaded file.

- **macOS** unzips it as soon as you double-click.
- **Windows**: right-click the file, choose **Extract All**, then **Extract**.
- **Linux**: right-click and choose **Extract Here**, or run
  `unzip plugin_EML_StatsGraphs.zip` in a terminal.

You now have a folder called **plugin_EML_StatsGraphs**. That folder *is* the
plugin. Please do not rename it: Praat recognises the plugin by that exact
name, and a renamed folder is simply ignored.

### Step 3 — Move the folder into Praat's preferences folder

Praat keeps its preferences somewhere different on each system. Find the right
folder below, and drag `plugin_EML_StatsGraphs` into it whole — the folder
itself, not the files inside it.

#### macOS

The Praat preferences folder lives inside your user Library, which Finder hides
by default.

1. Open Finder.
2. In the menu bar, click **Go** while holding the **Option (⌥)** key. This
   reveals the hidden **Library** item.
3. Click **Library**, then open `Preferences/Praat Prefs/`.
4. Drag the `plugin_EML_StatsGraphs` folder into `Praat Prefs/`.

Full path when you are done:
`/Users/[you]/Library/Preferences/Praat Prefs/plugin_EML_StatsGraphs/`

If you prefer, press **Cmd+Shift+G** in Finder and paste this path instead:
`~/Library/Preferences/Praat Prefs/`

#### Windows

1. Open `C:\Users\[you]\Praat\`
2. Drag the `plugin_EML_StatsGraphs` folder into it.

#### Linux

1. Open `~/.praat-dir/`
2. Drag the `plugin_EML_StatsGraphs` folder into it.

### Step 4 — Restart Praat

Quit Praat completely and open it again. Praat reads its plugins only at
startup, so the new menu will not appear until you have done this.

### Verify Installation

After restarting Praat:
- The menu bar should show **New > EML Stats & Graphs** with submenu items.
- Selecting a Table in the object list should show **EML: Describe column...**, **EML: Compare groups...**, **EML: Correlate columns...**, and **EML Graphs...** in the action buttons.
- Selecting a Sound, Pitch, Spectrum, or Ltas object should show **EML Graphs...** in the action buttons.

## Quick Start (30 seconds)

Paste this into a new Praat script window and run it:

```praat
# Include the stats library
include plugin_EML_StatsGraphs/stats/eml-core-utilities.praat
include plugin_EML_StatsGraphs/stats/eml-core-descriptive.praat
include plugin_EML_StatsGraphs/stats/eml-extract.praat
include plugin_EML_StatsGraphs/stats/eml-output.praat
include plugin_EML_StatsGraphs/stats/eml-inferential.praat

# Two groups of F0 measurements (Hz)
trained# = {195, 210, 188, 203, 197, 215, 192, 208}
untrained# = {165, 172, 158, 180, 163, 170, 155, 168}

# Welch t-test (tails=2, equalVariances=0 for Welch)
@emlTTest: trained#, untrained#, 2, 0

# Format and print the result
@emlFormatP: emlTTest.p
appendInfoLine: "t(", fixed$(emlTTest.df, 1), ") = ",
... fixed$(emlTTest.t, 2), ", p ", emlFormatP.result$
```

## Include Chain

**One line, if your script lives outside the plugin folder.** Every Praat
launch, `setup.praat` writes `eml-lib-user.praat` into the installed plugin's
own `scripts/` folder, with the paths for your machine filled in, so a script
anywhere on that machine loads the whole stack with:

```praat
include ~/.praat-dir/plugin_EML_StatsGraphs/scripts/eml-lib-user.praat
```

That is the Praat 6.x Linux path; `docs/API_EXPORT.md` gives the line for
Praat 7.x, macOS and Windows, and explains why this file has to be generated
rather than shipped. The lists below remain correct and are the fallback.

Add these lines at the top of any script that uses EML Stats:

```praat
include plugin_EML_StatsGraphs/stats/eml-core-utilities.praat
include plugin_EML_StatsGraphs/stats/eml-core-descriptive.praat
include plugin_EML_StatsGraphs/stats/eml-extract.praat
include plugin_EML_StatsGraphs/stats/eml-output.praat
include plugin_EML_StatsGraphs/stats/eml-inferential.praat
```

**Order matters.** Utilities must come before inferential because inferential procedures call `@emlRankVector` and `@emlSortWithIndex` from utilities. Extract must come before inferential because k-group procedures call `@emlExtractMultipleGroups`.

For scripts that also produce figures, add:

```praat
include plugin_EML_StatsGraphs/graphs/eml-graph-procedures.praat
```

The graphs module is independent of the stats modules. Stats-only scripts can omit it; graphs-only scripts can omit the stats includes.

## Two Ways to Use EML Stats & Graphs

**Menu items (no scripting required):** Select a Table in the object list, then click one of the **EML:** action buttons. A dialog collects your choices (which column, which test). Results appear in the Info window.

**In your own scripts:** Add the include chain at the top, then call procedures directly. `docs/RECIPES.md` is the place to start — five worked scripts, each one run verbatim by the test suite before it ships.

**Where the reference is.** There is no single procedure-reference page, and that is deliberate: `stats/` and `graphs/` define 530 procedures (`grep -c "^procedure " plugin/stats/*.praat plugin/graphs/*.praat`), and a hand-written signature list that long would be wrong in places by the end of the week it was written. What the plugin carries instead, and keeps true:

- **Every procedure is documented at its definition.** The header block above each `procedure` in `stats/` and `graphs/` gives its arguments, its outputs, and — where it matters — why it works the way it does. That is the reference; it cannot drift from the code, because it sits on top of it.
- **`MANIFEST.txt`** lists every file in the plugin with a one-line description of what it is for, so you know which module to open. It is generated from the tree by `dev/tools/build-manifest.py` and checked on every push.
- **`docs/RECIPES.md`** is five worked scripts for the workflows the plugin is actually used for: two groups from a table, paired columns and correlation, a full analysis with CSV export, a batch loop, and a Sound through Pitch into the descriptive kernels. Each one names the procedures it calls, what their arguments mean and what they hand back — and each is run verbatim by `harness/recipes/`, with its printed numbers pinned by `validate/v81_recipes.R`, so the page cannot document an API that has moved.
- **`docs/API_EXPORT.md`** is the worked how-to for `@emlExportResultFiles` — running one analysis over a folder of files and writing the result CSVs from a loop, with no dialogs.
- **`setup.praat`** is the authoritative list of menu items and action buttons, each with the script it runs.
- **Record script** (Objects → New → EML Stats & Graphs) is the fastest route from clicking to scripting: do the analysis in the GUI, then Stop recording and open, and you get a runnable, commented Praat script of *your* analysis — the recipes generalised, generated for the data in front of you.

## Files in This Plugin

| File | Description |
|------|-------------|
| `setup.praat` | Plugin registration — creates menu items and action buttons at Praat startup |
| `stats/eml-core-utilities.praat` | Vector operations: ranking, sorting, subsetting, z-scores, binning |
| `stats/eml-core-descriptive.praat` | Descriptive statistics: mean, median, SD, quartiles, skewness, kurtosis, CI |
| `stats/eml-extract.praat` | Table and acoustic object data extraction |
| `stats/eml-output.praat` | Formatted Info window reporting: APA style, p-value formatting, effect labels |
| `stats/eml-inferential.praat` | Inferential tests: t-tests, correlations, Mann-Whitney U, Wilcoxon, ANOVA, Kruskal-Wallis, post-hoc comparisons, p-value adjustment |
| `graphs/eml-graph-procedures.praat` | Publication-quality drawing: violin plots, adaptive theming, gridlines, jittered points |
| `scripts/eml-describe-table.praat` | Menu wrapper: descriptive statistics for a Table column |
| `scripts/eml-compare-groups.praat` | Menu wrapper: two-group comparison (t-test and/or Mann-Whitney U) |
| `scripts/eml-compare-k-groups.praat` | Menu wrapper: one-way ANOVA with optional Tukey HSD |
| `scripts/eml-compare-kw.praat` | Menu wrapper: Kruskal-Wallis with optional Dunn's post-hoc |
| `scripts/eml-correlate.praat` | Menu wrapper: Pearson and/or Spearman correlation |
| `scripts/eml-pairwise.praat` | Menu wrapper: pairwise t, pairwise Wilcoxon, or Scheffe post-hoc |
| `scripts/eml-graphs.praat` | EML Graphs: publication-quality figures (F0 contour, waveform, spectrum, LTAS, time series, bar chart, violin plot) with context detection, smart column prefill, and progressive disclosure |
| `scripts/eml-batch-process.praat` | Batch voice analysis: extract acoustic measures (F0, intensity, jitter, shimmer, HNR, CPPS) from a folder of Sound files to a CSV in a user-designated output folder |
| `scripts/eml-stats-demo.praat` | Visual showcase: three-panel figure with synthetic voice-science data |
| `scripts/eml-quick-start.praat` | Prints a quick-start guide to the Info window |
| `docs/RECIPES.md` | Five worked scripts for calling the statistics from your own Praat script, each run verbatim by the test suite |
| `docs/API_EXPORT.md` | Worked how-to for `@emlExportResultFiles`: one analysis over a folder of files, result CSVs written from a loop, no dialogs |
| `MANIFEST.txt` | Every file in the plugin, one line each, generated from the tree |

This table is a hand-picked selection; `MANIFEST.txt` is the complete list.

## Available Statistical Tests

**Descriptive:** mean, median, mode, SD, SEM, variance, quartiles, IQR, range, skewness, kurtosis, 95% CI, MAD, trimmed mean, geometric mean, harmonic mean.

**Two groups (parametric):** Welch t-test, Student t-test, paired t-test, Cohen's d, Hedges' g.

**Two groups (nonparametric):** Mann-Whitney U (exact + normal approximation), Wilcoxon signed-rank (exact + normal approximation), rank-biserial r, matched-pairs r.

**k groups (parametric):** One-way ANOVA, two-way ANOVA, Tukey HSD, pairwise t-tests (Welch/Student), Scheffe.

**k groups (nonparametric):** Kruskal-Wallis H, Dunn's test, pairwise Wilcoxon, epsilon-squared.

**Correlation:** Pearson r, Spearman rho.

**p-value adjustment:** Bonferroni, Holm step-down, Benjamini-Hochberg FDR.

## Further Reading

- `MANIFEST.txt` — every file in the plugin with a one-line description, so you know which module to open
- `docs/RECIPES.md` — five worked scripts for the direct-kernel API: Table to vectors, vectors to a test, and the orchestrator and exporter on top
- `docs/API_EXPORT.md` — calling `@emlExportResultFiles` from your own script, for a folder of files in a loop
- `dev/FIX_NOTES.md` — the July correctness bundle, with the reference values each fix was verified against
- `scripts/eml-stats-demo.praat` — run to see a three-panel publication figure with synthetic data

## Attribution

**Author:** Ian Howell, Embodied Music Lab ([www.embodiedmusiclab.com](http://www.embodiedmusiclab.com))
**License:** GPL-3.0-or-later
