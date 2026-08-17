# EML Praat Tools

Statistics, graphing, and data management inside Praat — built for voice
researchers, teachers, and students who want publication-ready analysis without
leaving the program their data already lives in.

By Ian Howell, Embodied Music Lab. Licensed GPL-3.0-or-later.

## What it does

**Statistics.** Compare two groups (Welch or Student t, Mann-Whitney), paired
and repeated measures (paired t, Wilcoxon, RM-ANOVA, Friedman), three or more
groups (one-way and two-way ANOVA, Kruskal-Wallis, Welch ANOVA, Brown-Forsythe),
with the follow-ups those tests need: Tukey, Games-Howell, Dunn, Scheffé, and
pairwise comparisons with Holm, Bonferroni, or Benjamini-Hochberg adjustment.
Correlation (Pearson, Spearman), linear regression with diagnostics, normality
checks (Shapiro-Wilk, with skewness and kurtosis), and effect sizes throughout —
Cohen's d, eta-squared, epsilon-squared, rank-biserial r.

Every number this plugin prints has been checked against R. The validation
suite — 12,400 automated comparisons — runs the same analyses in both programs
and requires agreement.

**A Stats Wizard** that walks you from "I have a table and a question" to a
completed, disclosed analysis: it examines your data, shows you the evidence
for its recommendation, and never hides what it excluded or why.

**Graphs.** Violin plots, scatter plots, box plots, pitch contours, spectra,
LTAS, waveforms, and Q-Q plots, in a beginner mode that makes good decisions
for you and an advanced mode that hands you the controls — axes, annotation
brackets with the test named on the figure, legends, jitter, DPI. Figures state
their statistics honestly: every significance bracket names the test that
produced it.

**Data management.** Import checking and repair, a table editor, column
describe-and-export, and demo data to learn on. Exports are tidy CSVs with a
declared vocabulary — the same result appears identically in the Info window,
the export, the figure, and the recorded script.

**A script recorder.** Work through the menus, press record, and get back a
runnable Praat script of what you did — object names, column names, and axis
choices lifted into one editable block at the top, so retargeting the workflow
to new data means editing a few lines, not hunting through code. Replays run
headless: dialogs author the script; the script just runs.

**Batch voice analysis.** Point it at a folder of recordings and get a CSV of
acoustic measures per file, with error rows for files that couldn't be
processed rather than silent skips.

**A scripting API.** Everything the menus do, your own Praat scripts can call
directly. One include line loads the library:

    include <path-to-plugin>/scripts/eml-lib.praat

and every statistical procedure is then available as a call —
`@emlTTest`, `@emlOneWayAnova`, `@emlMannWhitneyU`, `@emlPearsonCorrelation`,
and the rest — taking numeric vectors and returning named results
(`emlTTest.t`, `emlTTest.p`, `emlTTest.pGreater`, ...). Directional
one-tailed tests are explicit: the `@emlTTestAlt`-family procedures take
`"two-sided"`, `"greater"`, or `"less"` and state which hypothesis the
returned p-value answers. `@emlExportResultFiles` writes the same tidy CSVs
the Save button writes, with no dialog, which is what makes an analysis loop
over forty files possible — see `docs/API_EXPORT.md` for a worked, tested
example including the batch loop. Every procedure documents its arguments
and outputs in its own header, and `MANIFEST.txt` maps every file to what it
contains. The numbers you get from a script are the same numbers the menus
print: both go through the same validated kernels.

## Requirements

Praat 6.6.30 or later. The plugin checks and will decline to run on older
versions — every number it prints was validated on 6.6.30, and it won't print
numbers under a banner it can't stand behind. Praat is free:
https://www.fon.hum.uva.nl/praat/

## Installation

1. Download and unzip the plugin.
2. Move the entire `plugin_EML_Praat_Tools` folder into your Praat preferences
   directory:
   - macOS: `~/Library/Preferences/Praat Prefs/`
   - Windows: `C:\Users\<you>\Praat\`
   - Linux: `~/.praat-dir/`
3. Restart Praat.

You'll find the tools in the **New** menu under EML, and as buttons in the
Objects window when you select a Table or Sound.

## Getting started

Create a demo table (New → EML → Create Demo Table) and open the Stats Wizard
on it. The wizard is the guided path; every analysis it runs is also available
directly from the menus when you know what you want. To learn the graphing
side, select the demo table and open EML Graphs — beginner mode will draw you a
sensible figure from any supported object.

For scripting, the gentlest on-ramp is the recorder: start it (New → EML →
Record script), do your analysis through the menus, then stop and save. The
saved script shows you the API calls for exactly what you just did, with the
editable choices gathered at the top — a working example, written by your own
workflow. From there, the procedure headers and `docs/API_EXPORT.md` take you
the rest of the way to fully scripted batch analysis.

## What this plugin is — and isn't

It covers the core statistical procedures of voice research and teaching:
group comparison, paired designs, correlation, regression, normality, effect
sizes, and the figures that report them. It is not a general statistics
package: no mixed models yet (in development), no GLMs, no factor analysis.
If your design outgrows what's here, R or jamovi are the right next step —
and the tidy CSV exports are designed to travel there cleanly.

## Support and source

Source, issues, and updates: https://github.com/embodied-music-lab/EMLPraatTools
Embodied Music Lab: https://www.embodiedmusiclab.com

If this plugin contributes to published research, please cite it and disclose
per your journal's policy. Analysis scripts generated by this plugin embed
their own provenance.
