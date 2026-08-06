# Graph stress test — observations

6 August 2026. Ian Howell, Embodied Music Lab.

38 cases, one Praat process each, driven by `harness/stress_graphs.sh` over
`harness/stress_cases/`. Every figure in this document was rendered, saved and
looked at. Nothing here is reasoned from reading the source alone; where a
mechanism is asserted, the probe that established it is named.

## How the harness works, and why it is shaped that way

A Praat script error aborts the script. One driver script running twenty cases
therefore reports the first failure and hides the other nineteen behind it. So
each case gets its own process — about a second each, and an independent
verdict per case.

The draw procedures do not call `beginPause:`, so unlike the wrapper scripts
they run under `praat --run` with no X server at all. That is what makes a
38-case sweep cheap enough to re-run after every change.

Two verdicts need explaining:

- `NO_FIGURE` — the script aborted; no PNG.
- `BLANK_FRAME` — a PNG exists but under 2% of its pixels carry ink.

The second exists because of a mistake the harness made on its first run. A
draw procedure that renders axes, gridlines and a three-entry legend and then
no data at all still writes a perfectly valid PNG, and the driver called it
`OK`. `emlDrawTimeSeriesCI` produced exactly that. "The file exists" is not a
verdict. The ink fraction is crude — a genuinely sparse figure like `n = 1 per
group` trips it too — but it points at the right figures to open.

## What was broken, and is now fixed

### 1. Four draw procedures could only ever be called from the graphs form

Six of the fourteen graph types read `emlCatLabel$[]` and
`emlFitCategoricalLabels.rotated`, which only `@emlMeasureCategoricalLabels`
produces — and the only caller of that was the pre-dispatch block in
`eml-graphs-form.praat`. `emlDrawBarChart` additionally reads `emlBarData_*`,
produced only by `@emlMeasureBarData` in the same block.
`emlDrawScatterPlot` and `emlDrawTimeSeriesCI` read
`emlInitAlphaSprites.available`, initialised only there.

Any other caller got:

```
Error: Undefined indexed variable «emlCatLabel$[1]».
Error: Unknown variable: emlBarData_nGroups
Error: Unknown variable: emlInitAlphaSprites.available
```

— an abort, with nothing on the canvas and no message a user could act on.

This is not hypothetical. PraatGen's whole promise is a standalone script the
user owns and runs on its own; a generated script that drew a violin plot died
before its first mark. It is also why the fault survived this long: the draw
layer could not be exercised except through the form, so nothing ever tried.

Fixed with two guards, `@emlEnsureCategoricalLabels` and `@emlEnsureBarData`,
which re-measure only when the current measurement does not already cover this
table, column and viewport. In the form path the key matches and each costs one
string comparison, so the pre-dispatch measurement — whose overhang feeds the
margin calculation — still governs. `@emlInitAlphaSprites` was already
idempotent and is simply called where it is needed.

### 2. Rotated category labels and the x-axis title fell outside the saved figure

Three ordinary cohort names at 6×4 inches:

> Preprofessional undergraduate · Continuing education adult · Professional performing

`emlFitCategoricalLabels` truncated the first correctly to `Preprofe…`, and the
figure rendered it as `reprofe…` with its leading character off-canvas. The
x-axis title `Cohort` vanished outright.

Redrawing the identical figure into a hand-widened viewport showed both intact.
That is what identifies this as a save-extent fault rather than a placement
one: the text was always drawn in the right place, and the saved box cut
through it.

Rotated labels extend below and to the left of the theme's outer box, and the
x-axis title is pushed below them again. Neither was ever reported to
`@emlExpandDrawnExtent`, so `@emlAssertFullViewport` — which every save path
calls — selected a box that clipped them. The overhang was already being
measured; the form spent it on the gap above the comparison matrix panel and
nowhere else, so any figure without a matrix panel lost the labels.

`@emlDrawCategoricalXAxis` now reports its true extent. At 45° a right-anchored
label reaches left by the same distance it reaches down, so one measurement
serves both directions.

Evidence: `evidence/figures/violin_longlabels.png`.

### 3. Grouped scatter legends disagreed with the points they labelled

`.pointColor$[]` is filled near the top of `emlDrawScatterPlot`, before the
group count is known. `@emlOptimizePaletteContrast` then overwrites
`emlSetColorPalette.line$[1..n]` with a different ordering. The legend reads the
optimised array; the dots read the stale cache.

With three groups the optimiser skips sky blue as too close to blue and gives
group 3 green. The legend said green. The points were sky blue. A reader
matching swatch to cloud had no way to tell.

This is not masked by the sprite path — see finding 6.

Fixed by re-reading the point colours after the optimisation.

Evidence: `evidence/figures/scatter_grouped.png` (after).

### 4. Every categorical graph type aborted on a zero-row table

`.axisXMax = .nGroups + 0.5` gives 0.5 for an empty table, and `Axes:` refuses
`left = right`:

```
Error: Left and right should not be equal.
```

Six of ten table types died this way; the other four drew an empty frame. The
form refuses zero-row tables upstream (`eml-graphs-form.praat:1305`), so again
this only reaches users through the non-form routes.

Nine x-range computations are now clamped, and `@emlDrawCategoricalXAxis` draws
a centred grey **No data to plot** and appends a NOTE rather than handing back a
blank rectangle the reader has to diagnose.

Evidence: `evidence/figures/empty_violin.png`.

## What is working

Verified by looking at the rendered figure, not by reading code.

| Case | Result |
|---|---|
| Baseline violin, 3 groups × 10 | Correct. KDE, IQR box, median mark, Okabe-Ito palette |
| Twelve groups | Legible; palette cycles past 8 without collision on a positional axis |
| n = 1 per group | Degrades to a bare level mark per group. No crash |
| Zero variance in every group | Degrades to a single level mark. No crash |
| Single group | Correct |
| Values near 1e-9 and near 1e12 | Axis labelling correct at both extremes |
| Values spanning zero | Correct |
| One value 100× the rest | Correct; axis absorbs it |
| One cell in four blank | Correct; blanks dropped, not ranked (the C96 behaviour holds) |
| Bar chart, SE / SD / custom error column | All three correct |
| Histogram, 10 bins / 1 bin / 200 bins on 36 points | All render; y-axis stays integral (the D91 fix is visible) |
| Grouped violin, grouped box | Correct |
| Spaghetti, ungrouped and grouped | Correct — one line per subject, group means overlaid |
| Time series with CI | Correct |
| Form path, annotated violin | Correct: title, palette, ANOVA line, Tukey matrix panel |

The form path was re-driven through the GUI after every change above, on
`demo_3groups` with `voice_type` as the group column and annotation on. Result
in `evidence/shots/form_path_violin_annotated_2026-08-06.png`.

## Open — not fixed, for your ruling

### 5. The graphs form defaults the group column to the subject identifier

Opening EML Graphs on the plugin's own `demo_3groups` and pressing Draw
produces a violin plot of **45 singleton groups** with 45 overlapping rotated
labels, because the default group column is `singer` — the first string column,
which is the subject ID. The factor the table exists to demonstrate,
`voice_type`, is column 2.

Every EML demo table leads with an identifier, so this is the out-of-box first
experience. A default that preferred the string column with the fewest distinct
values would land on the factor in every one of them.

### 6. `plugin/sprites/` has never existed in the repository

`@emlInitAlphaSprites` probes three locations for `dot_blue_a50_40.png`. No
sprite file exists anywhere in the tree and none is in the git history, so
`.available` is always 0 and every alpha dot falls through to
`Paint circle:`. The fallback is graceful and the figures look fine — but the
transparency feature is dead code, and overlapping points in a dense scatter
are opaque when the design says they should not be.

Either commit the sprites or retire the path. Leaving it is the worst of the
three, because the code reads as though transparency works.

### 7. `emlDrawTimeSeries` on unaggregated long-format data

Six rows, two observations at each of three times, both underlying series
rising:

> (1,10) (1,20) · (2,12) (2,22) · (3,14) (3,24)

The figure reads as **falling**. Nothing is dropped — I checked, and my first
reading of this was wrong. The procedure sorts by time and then connects every
consecutive pair of rows, so the segments at equal x are vertical, and the two
vertical segments at the extremes sit exactly on the left and right axis lines
where they are indistinguishable from the frame. What remains visible are the
descending connections between tie groups, which are artifacts of tie ordering
and carry no meaning.

Long format is the shape every EML stats tool produces and every EML demo table
uses. Options are to aggregate per time point, to require a group column, or to
refuse with a message. All three are design calls, not bug fixes.

Evidence: `evidence/figures/ts_duplicate_times.png`.

### 8. Three different conventions for "no data"

- Histogram: draws **nothing at all** — a blank white PNG — plus `WARNING:`.
- Time series: empty axes plus `NOTE:`.
- Categorical types, as of today: empty axes, **No data to plot** on the
  canvas, plus `NOTE:`.

Each is defensible alone. Together they are three answers to one question. The
histogram's is the weakest: a completely blank image is indistinguishable from
a failed export.

### 9. Smaller observations

- `@emlSetColorPalette` matches `"color"` exactly and falls through to
  greyscale for anything else. The form passes lowercase so the product is
  fine, but an API or PraatGen caller passing `"Color"` gets a silent
  greyscale figure with no warning. This cost me a full case sweep before I
  noticed.
- `0, 0` means "auto" for the y-range. Passing `undefined` — the natural
  sentinel for "no constraint" — reaches `Axes:` and aborts. Also means a
  genuine request for a 0-to-0 axis cannot be expressed, which nobody wants,
  but the convention should be documented at each signature.
- No figure states n anywhere. Three flat marks at n = 1 per group and three
  flat marks from 100 identical values are visually identical.
- 200 bins over 36 points renders without comment. A note when bins exceed n
  would cost one line.
- Grouped violin legend swatches are the saturated line colour while the
  violins are the pale fill. Mappable by hue, but a swatch drawn as fill with
  a line border would be exact.
- The draw library is not self-contained: `emlDrawViolinPlot` calls
  `emlCountGroups`, which lives in `stats/eml-extract.praat`. Fine as an
  architecture, but it means "the graphs layer" is not a thing you can include
  on its own, and the stress prelude has to carry the whole stats layer.

## Reproducing

```
harness/stress_graphs.sh            # all 38 cases
harness/stress_graphs.sh violin     # substring filter
```

Results land in `/home/claude/stress/RESULTS.tsv`; per-case PNG and log in
`/home/claude/stress/out/`.
