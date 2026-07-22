# EML Praat Tools

Statistical analysis and publication-quality graphing for Praat. Run t-tests, correlations, ANOVAs, and nonparametric tests without leaving Praat — no R or Python export required. Format results for direct inclusion in manuscripts.

## Installation

### macOS

The Praat preferences folder is inside your user Library, which is hidden by default in Finder.

1. Open Finder.
2. In the menu bar, click **Go** while holding the **Option (⌥)** key. This reveals the hidden **Library** item.
3. Click **Library**, then navigate to: `Preferences/Praat Prefs/`
4. Copy the entire `plugin_EML_Praat_Tools` folder into `Praat Prefs/`.
5. Restart Praat.

Full path: `/Users/[you]/Library/Preferences/Praat Prefs/plugin_EML_Praat_Tools/`

Alternatively, in Finder you can press **Cmd+Shift+G** and paste the path directly:
`~/Library/Preferences/Praat Prefs/`

### Windows

1. Navigate to `C:\Users\[you]\Praat\`
2. Copy the entire `plugin_EML_Praat_Tools` folder there.
3. Restart Praat.

### Linux

1. Navigate to `~/.praat-dir/`
2. Copy the entire `plugin_EML_Praat_Tools` folder there.
3. Restart Praat.

### Verify Installation

After restarting Praat:
- The menu bar should show **New > EML Tools** with submenu items.
- Selecting a Table in the object list should show **EML: Describe column...**, **EML: Compare groups...**, **EML: Correlate columns...**, and **EML Graphs...** in the action buttons.
- Selecting a Sound, Pitch, Spectrum, or Ltas object should show **EML Graphs...** in the action buttons.

## Quick Start (30 seconds)

Paste this into a new Praat script window and run it:

```praat
# Include the stats library
include plugin_EML_Praat_Tools/stats/eml-core-utilities.praat
include plugin_EML_Praat_Tools/stats/eml-core-descriptive.praat
include plugin_EML_Praat_Tools/stats/eml-extract.praat
include plugin_EML_Praat_Tools/stats/eml-output.praat
include plugin_EML_Praat_Tools/stats/eml-inferential.praat

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

Add these lines at the top of any script that uses EML Stats:

```praat
include plugin_EML_Praat_Tools/stats/eml-core-utilities.praat
include plugin_EML_Praat_Tools/stats/eml-core-descriptive.praat
include plugin_EML_Praat_Tools/stats/eml-extract.praat
include plugin_EML_Praat_Tools/stats/eml-output.praat
include plugin_EML_Praat_Tools/stats/eml-inferential.praat
```

**Order matters.** Utilities must come before inferential because inferential procedures call `@emlRankVector` and `@emlSortWithIndex` from utilities. Extract must come before inferential because k-group procedures call `@emlExtractMultipleGroups`.

For scripts that also produce figures, add:

```praat
include plugin_EML_Praat_Tools/graphs/eml-graph-procedures.praat
```

The graphs module is independent of the stats modules. Stats-only scripts can omit it; graphs-only scripts can omit the stats includes.

## Two Ways to Use EML Tools

**Menu items (no scripting required):** Select a Table in the object list, then click one of the **EML:** action buttons. A dialog collects your choices (which column, which test). Results appear in the Info window.

**In your own scripts:** Add the include chain at the top, then call procedures directly. See `docs/procedure-reference.md` for all procedure signatures and `docs/recipes.md` for complete copy-paste examples.

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
| `scripts/eml-batch-process.praat` | Batch voice analysis: extract acoustic measures (F0, intensity, jitter, shimmer, HNR, CPPS) from a folder of Sound files to CSV |
| `scripts/eml-stats-demo.praat` | Visual showcase: three-panel figure with synthetic voice-science data |
| `scripts/eml-quick-start.praat` | Prints a quick-start guide to the Info window |
| `docs/procedure-reference.md` | All procedures organized by workflow, with signatures and examples |
| `docs/recipes.md` | Eight self-contained scripts for common analysis tasks |

## Available Statistical Tests

**Descriptive:** mean, median, mode, SD, SEM, variance, quartiles, IQR, range, skewness, kurtosis, 95% CI, MAD, trimmed mean, geometric mean, harmonic mean.

**Two groups (parametric):** Welch t-test, Student t-test, paired t-test, Cohen's d, Hedges' g.

**Two groups (nonparametric):** Mann-Whitney U (exact + normal approximation), Wilcoxon signed-rank (exact + normal approximation), rank-biserial r, matched-pairs r.

**k groups (parametric):** One-way ANOVA, two-way ANOVA, Tukey HSD, pairwise t-tests (Welch/Student), Scheffe.

**k groups (nonparametric):** Kruskal-Wallis H, Dunn's test, pairwise Wilcoxon, epsilon-squared.

**Correlation:** Pearson r, Spearman rho.

**p-value adjustment:** Bonferroni, Holm step-down, Benjamini-Hochberg FDR.

## Further Reading

- `docs/procedure-reference.md` — all procedures by workflow, with signatures and examples
- `docs/recipes.md` — copy-paste scripts for common analysis tasks
- `scripts/eml-stats-demo.praat` — run to see a three-panel publication figure with synthetic data

## Attribution

**Framework:** Ian Howell, Embodied Music Lab ([www.embodiedmusiclab.com](http://www.embodiedmusiclab.com))
**Code generation:** Claude (Anthropic)
**License:** Creative Commons Share-Alike
