# Remaining before the graphing push

Working tracker. Written 9 August 2026. Supersedes nothing — it collects what
is still open across the graphing layer so the push starts from a list rather
than from memory.

Status vocabulary is deliberate:

- **OPEN** — reproduced, not fixed.
- **RULED** — the author has decided; the decision is recorded and no code
  change follows.
- **BLOCKED** — waiting on an author ruling.
- **DONE (verify on Mac)** — fixed and verified on Linux; the fix touches a
  platform path this sandbox cannot exercise.

---

## 1. Legend placement — closed out

Six graph types offer the Legend placement menu (`legendPlacementStyle[t] = 5`):
5 Line ±CI, 8 Scatter, 10 Histogram, 11 Grouped Violin, 12 Grouped Box,
13 Spaghetti. The other seven have no legend and no menu
(`legendPlacementStyle[t] = 0`).

**Verified 9 Aug 2026** across all six types at all five placements, with
deterministic data so only the furniture moves — and, since **11 Aug 2026**,
re-verified on every run by `validate/v32_legend_geometry.R` §11 rather than
by the hand measurement this table records. See §7.

| | plot box (px) | canvas | notes |
|---|---|---|---|
| 1 Inside | 251–1548 | 1800 × 1350 | |
| 2 Right of plot | 251–1548 | 2177–2198 × 1350 | width varies with longest label |
| 3 Below plot | 251–1548 | 1800 × 1519 | |
| 4 Separate figure | 251–1548 | 1800 × 1350 + a second file | |
| 5 None | 251–1548 | 1800 × 1350 | |

Resolved axes identical across all five placements for every type. The plot
rectangle is invariant, which is the design guarantee.

Fixtures: `harness/legend/placement_sweep_case.praat` (types 5, 8, 10, 13),
`harness/legend/placement_matrix_case.praat` (types 11, 12, with a comparison
matrix panel).

**NOW A CHECK, 11 Aug 2026.** `placement_sweep_case.praat` was rewritten to
the legend driver's own calling convention — environment variables, the
record lines `emit_row` reads, `@stressSave` — and wired in as **block 7** of
`harness/legend/run.sh`: four types × five placements, 20 figures,
`sw_t<type>_p<placement>`. §11 of `validate/v32_legend_geometry.R` asserts
what the table above records by hand, and three things the table could not
say:

- the plot rectangle is one rectangle **in inches**, so placement 2's
  one-pixel narrowing — the effective resolution being a hair off 300 on a
  canvas that is not a whole number of inches — is accounted for rather than
  tolerated;
- placement 4's **second file exists on disk**. No other fixture in the tree
  performs the `emlLegendSepActive` select-and-save, so until now the parked
  legend was asserted from the source only. Both halves are checked: p4 writes
  one, and 1/2/3/5 write none;
- the **axis contract** (§2) measured on four running draw procedures rather
  than read out of the source — `.axis*` agrees with the resolved locals on
  5, 10 and 13, and on 8 it must NOT, because there `.xMin` is the caller's
  request and is still 0 after an auto-ranged draw.

Every one of those was verified to fail on the defect it pins before being
trusted: the parked-legend file deleted, a stray one planted, the rectangle
moved 10 px, placement 2's growth removed, the y-axis widened, and — for the
last — the scatter's parameters actually aliased to the resolved range in
`eml-draw-procedures.praat` and the figure re-rendered.

The one that was not planted is the block census, which caught this work on
its own: every §11 assertion passed on the first run and
`"the seven blocks account for every rendered case"` was the only line in the
tree that noticed twenty figures had appeared in a population nothing had
been told about.

**RULED — matrix panel width.** The comparison matrix panel only ever matches
the width of the graph itself. Author ruling, 9 Aug 2026. Verified: the panel
occupies 322–1401 px under a 251–1548 px plot box in BOTH placement 1 and
placement 2, i.e. widening the canvas for a right-hand legend does not move it.
An earlier commit (2b93fe9) called this a defect by measuring the panel against
the canvas rather than the graph; retracted in 7833c31.

**RULED — grouped violin/box legend default.** Stays `Inside`, not `None`. On
types 11 and 12 the x axis carries the category column and the legend carries
the sub-group column, so they are not redundant and suppressing the legend
leaves the sub-groups with no key.

---

## 2. FIXED — draw procedures disagreed on how they expose their resolved axes

As found:

| types | convention |
|---|---|
| 8, 10, 11, 12 | `.axisXMin` / `.axisXMax` / `.axisYMin` / `.axisYMax` |
| 5, 13 | `.xMin` / `.xMax` / `.yMin` / `.yMax` |

Every caller outside the form had to know which convention its graph type
follows, and choosing wrong failed at RUN time with a bare `Unknown variable:`
rather than at parse time. Hit while writing the sweep fixture.

### The fix that was proposed was wrong, and reading the code said so

The plan was to publish BOTH names from every procedure — additive, nothing
breaks. That would have shipped a silent-wrong-number bug. `.xMin` does not
mean the same thing in the two families:

| procedure | `.xMin` is |
|---|---|
| ts, tsci, spaghetti, bar, violin, box, gviolin, gbox, histogram | a LOCAL holding the RESOLVED range |
| **scatter** | a **PARAMETER** holding what the caller REQUESTED, `(0, 0)` meaning auto |

Aliasing the two spellings together would have made `emlDrawScatterPlot.xMin`
a name that resolves — and returns `0` for an auto-ranged scatter instead of
the range the axes were drawn at. A caller would get a wrong number rather
than an error, which is strictly worse than the problem being fixed. The
`Unknown variable:` failure at least stops.

### What was done instead

`axis*` is now the single canonical spelling for THE RANGE THE AXES WERE
ACTUALLY DRAWN AT — after auto-detection, after nice-number rounding, after
the categorical half-step padding. All ten Table-consuming draw procedures
publish it, plus `@emlDrawQQPlot`, which previously read the scatter's
directly and exposed nothing of its own. The parameters are left alone.

Consumers migrated: the form's legend-headroom block (types 5, 10, 13 read
`.yMin`; now all six read `axisY*`) and its post-dispatch annotation block
(already on `axis*`). `harness/legend/placement_sweep_case.praat` still reads
`emlDrawTimeSeriesCI.xMin`, which remains correct — it is a fixture reading a
local it knows the meaning of, not a caller guessing a convention.

**Evidence that it is pixel-neutral.** The determinism harness renders all ten
types twice per run and reports the PNG byte size; every one of the ten is
byte-identical to the size committed before this change:

```
ts 106104   tsci 80315   spaghetti 218083   bar 40928   violin 81214
box 50026   gviolin 119987   gbox 60849   scatter 134906   histogram 50194
```

Plus 39/39 stress, 52/52 disclosure, 357/357 phase1, 8221/8221 R, both round
trips PASS.

---

## 2b. FIXED — an annotated figure could lose its statistics box entirely

Found 11 August 2026 while migrating §2's consumers. **The first version of
this section was wrong and is corrected below**; the defect it half-described
turned out to be real, more serious, and reachable by an ordinary input.

### What was claimed first, and why it was wrong

The claim was that types 6, 7 and 9 seed `annotYMin`/`annotYMax` from the
dialog's `valueMin`/`valueMax` with no override, so an auto-ranged figure
would annotate against `(0, 0)` and `annotYRange` would be 0. That was
written from the POST-dispatch block alone. The form has a PRE-dispatch
resolver, gated on

```
(graph_type = 6 or 7 or 9) and annotate = 1 and annotBracketN > 0
```

which resolves `valueMin`/`valueMax` from the visible data extent, adds
bracket headroom, and passes the result INTO the draw procedure — so the
drawn axis IS `valueMin`/`valueMax` and the two spellings agree exactly.
**The bracket path was never broken.** Publishing a finding from half a
control flow is how that happened.

### What is actually wrong

The resolver requires `annotBracketN > 0`. The post-dispatch block runs on

```
annotBracketN > 0  OR  (annotTextN > 0 and annotMatrixN = 0)
```

So with an omnibus line and NO brackets, nothing resolves the range: the
legend-headroom pass, the only other thing that refreshes it, runs for types
5, 8, 10, 11, 12 and 13 — not 6, 7, 9. `@emlDrawAnnotationBlock` was handed
`(0, 0)` while the axis sat wherever the data put it.

`@emlDrawAnnotations` is NOT the exposure — it is guarded by
`if annotBracketN > 0` and is not called. The omnibus box is.

**The box is not misplaced. It is gone.** Measured on f0-scale data:

```
OMNIBUSONLY brackets=0 text=1 matrix=0
OMNIBUSONLY postDispatchRuns=1 preDispatchResolverRuns=0
OMNIBUSONLY drew axis=192 214  box got=0 0
OMNIBUSONLY label=One-way ANOVA: F(3, 52) = 0.46, p = .709
```

The figure renders cleanly, with no error and no note, and the ANOVA result
the user ticked Annotate to get is absent from it.

### It is not an edge case

`@emlBridgeGroupComparison` sets `annotTextN = 1` for the omnibus on EVERY
path, and leaves `annotBracketN` at 0 whenever no pair clears alpha. Two
routes reach the state, and the second is the common one:

1. Omnibus significant, no pairwise comparison surviving correction.
2. **Omnibus not significant.** Every non-significant ANOVA or Kruskal-Wallis
   on an auto-ranged bar, violin or box plot lands here.

A non-significant result is not a rare input, and losing its box is the case
where the reader most needs to see the number.

### The fix

`annotYMin`/`annotYMax` are now taken from the draw procedure for types 6, 7
and 9 as well, and `@emlDrawAnnotationBlock` is called with `annotY*` rather
than `valueMin`/`valueMax`. Possible only because §2 made every procedure
publish `axis*` — the migration is what surfaced this.

Pixel-neutral everywhere it was not broken, and shown to be: on types 5, 8,
10, 11, 12 and 13 the two spellings hold the same number (either annotY*
falls through to valueMin/valueMax, or the legend-headroom pass wrote the
resolved extent into both and re-drew against it), and on 6, 7 and 9 with
brackets the pre-dispatch resolver has already made them equal. 52/52
disclosure, 10/10 determinism byte-identical, 39/39 stress, 357/357 phase1,
8221/8221 R.

Reproduced by `harness/disclosure/probe_annot_omnibus_only.praat` (defaults
land in the state) and `harness/disclosure/probe_annot_yrange.praat` (the
same call with and without the fix, two PNGs, they differ).

### The reason it survived this long is worth more than the defect

`harness/disclosure/probe_formpath.praat` says it reproduces "the form's
sequence" and is titled as a transcription of the post-dispatch block. It
passes `emlDrawViolinPlot.axisYMin`/`axisYMax` where the form passed
`valueMin`/`valueMax`. So the probe tested a CORRECTED version of the code it
claimed to be testing, and would have gone on passing however wrong the form
became.

**A hand-transcription of shipping code is not a test of it.** The block
should be factored to file scope — the way `@emlGraphsDrawWithLegendRoom`
already was, and for the same stated reason — so a probe drives the real
code instead of a copy of it. Until that happens every check on this block
has the same defect the block did. **OPEN, and the next thing to do here.**

## 2c. FIXED — one missing value killed the annotated violin and box path

Found 11 August 2026, within minutes of `probe_formpath.praat` being pointed
at the shipped code instead of a hand-copy. **The rewrite is what found it**,
and it found it by accident: the disclosure fixture blanks six of its twenty
values on purpose, and the probe fell over building the pre-dispatch state.

### The primitive

`Get maximum:` on a Table column containing a blank cell does not return
undefined. It ABORTS. Measured on 6.6.30, five rows, one blank:

```
clean max = 50
about to Get maximum on a column with one blank cell
Error: Table "t": the cell in row 3 of column "v" is undefined.
Table "t": cannot compute maximum of column 1.
```

### Where the form called it

The bracket-headroom stage, on the user's raw table:

```
else
    # Violin/Box: visible extent = raw data extent
    visibleDataMax = Get maximum: valueColName$
    visibleDataMin = Get minimum: valueColName$
endif

if visibleDataMax <> undefined and visibleDataMax > 0
```

Gated on `(graph_type = 6 or 7 or 9) and annotate = 1 and annotBracketN > 0`.
Type 6 goes through `@emlMeasureBarData` and is unaffected. **Types 7 and 9
took the raw query.**

So: a violin or box plot, Annotate ticked, at least one significant pair, and
**one missing value anywhere in the value column** — and the whole workflow
died with a raw Praat error before drawing anything.

The `if visibleDataMax <> undefined` on the next line is the tell. Someone
anticipated missing data and guarded the wrong thing: the call aborts, so the
test it guards is never reached. A guard that cannot fire reads, in review,
exactly like a guard that works.

### Why nothing caught it

- The **draw procedures tolerate missing values** — they skip the row and say
  so ("6 row(s) skipped (missing or non-numeric value)"), which is what the
  whole disclosure suite was built to check. So the dirty-data cases pass:
  they call the draw procedures directly and never touch this stage.
- The **form's stages had no caller but the form**, which needs a dialog.
- `probe_formpath.praat` transcribed the post-dispatch block and never
  reached the pre-dispatch one at all.

Missing values are the ordinary case in this plugin's domain — an unusable
token, a failed pitch extraction, an empty cell in an exported CSV. This was
not a corner.

### The fix

`@emlGraphsColumnExtent: .tableId, .colName$` — min, max and a count over the
DEFINED cells only, returning undefined bounds when there are none, so the
caller's existing undefined test finally does what it was written to do. The
headroom stage now measures the extent of exactly the rows that get drawn,
which is what it should have been agreeing with all along.

39/39 stress, 52/52 disclosure, 10/10 determinism byte-identical, 357/357
phase1, 8221/8221 R, both round trips PASS.

### What this says about the rest of the form

Two of the form's stages have now been driven by a probe for the first time,
and both had a defect in them — §2b in post-dispatch, this in pre-dispatch.
That is not evidence the form is bad; it is evidence that **the stages nothing
could call were the stages nothing had tested.** The remaining ones are worth
the same treatment: `@emlGraphsWorkflow` is still one procedure containing
context detection, preset reading, the dialog loop, CSV export and post-draw
options, and none of them can be reached without a display.

---

## 2d. PART FIXED — the stats bridge and the graph bridge did not exclude the same rows

Asked by the author 11 August 2026, after §2c: *does this mean the stats
bridge and the graph bridge have different exclusion standards?* **Yes.**
Measured, not argued — `harness/disclosure/probe_exclusion_parity.praat`.

### The two readers

| layer | reader | behaviour |
|---|---|---|
| stats | `@eml_readCell`, via `@emlExtractColumn` / `@eml_getGroupData` | **STRICT** — a cell is kept only if it is exactly the number it looks like |
| graph | `number (Get value: .i, .valueCol$)`, in every draw procedure's row filter | **LENIENT** — Praat's own numericiser |

The strict reader exists on purpose. D96 replaced the lenient filter in the
stats path with this exact reasoning: Praat coerces `1,5` to `1`, so a
European decimal comma did not drop a row — it put a DIFFERENT NUMBER into
the mean, with nothing anywhere in the report to say so. **That argument
applies word for word to a figure**, and was never applied to one.

### Measured, one cell per row

```
cell  1 '10'    strict=10     lenient=10     same
cell  3 '1,5'   strict=undef  lenient=1      DIFFER
cell  4 '30%'   strict=undef  lenient=0.3    DIFFER
cell  5 ''      strict=undef  lenient=undef  same
cell  6 '.5'    strict=undef  lenient=undef  same
cell  7 'abc'   strict=undef  lenient=undef  same
```

Two kinds diverge, and they are the two D96 was written about. Both are
kept by the figure as a wrong number rather than dropped.

### The consequence on one 10-row table

```
statsA  n=2  excluded=5          <- @eml_getGroupData on group A
figure  skipped=3                <- @emlDrawViolinPlot's disclosure line
```

Group A has seven rows. The ANOVA analyses **two** of them. The violin draws
**four** — 10, 20, and the coerced 1 and 0.3. So:

1. **The omnibus line the form paints onto the figure describes a different
   data set from the figure.** Neither layer is internally wrong, which is why
   nothing catches it.
2. **The disclosure line under-reports.** "3 row(s) skipped" is true of the
   figure and false of the analysis beside it, and the disclosure line is the
   plugin's own promise that what was dropped is stated.

### A second axis, and it is not the one that was suspected

Row 10 carries a value with a BLANK group label. `@emlCountGroups` returns
**3** — a blank label is a category — so the figure draws an unlabelled third
violin and the axis stretches to hold it (`-20..120` for data topping out at
99). `@emlGraphsColumnExtent` reports `n=7 max=99`, which is CONSISTENT with
what the figure draws.

That is worth stating plainly because the obvious suspicion, on adding a new
extent helper in §2c, is that it introduced a third standard. **It did not.**
On all ten cells it agrees with the draw layer exactly, including the blank
group, which is what an axis-extent helper must do — an extent that excluded
a point the figure plots would clip data off the figure. The helper is right;
the layer it agrees with is the one in question.

### What this is NOT

Not a proposal to make the draw layer strict on the author's behalf. That
would change published figures: every point currently plotted from a `1,5` or
a `30%` cell would disappear, which is the correct outcome by D96's own
reasoning and is still a visible change to output that has been shipped.
**It is an author ruling, and it is recorded here as one that is needed.**

Three shapes it could take:

1. **Strict everywhere.** The draw layer adopts `@eml_readCell`. Figure and
   analysis agree by construction, and the disclosure line becomes true of
   both. Changes figures.
2. **Lenient everywhere.** The stats layer reverts. Rejected on sight — D96
   exists because that silently changed a reported mean.
3. **Leave the readers alone, make the DISAGREEMENT visible.** When the two
   readers return different counts for the same column, say so on the figure
   and in the report. Changes no numbers; adds a disclosure.

1 and 3 are not exclusive. 3 is the smaller change and is worth doing whatever
is decided about 1, because the current failure mode is silence.

---

## 2e. THE RULING, AND WHAT IS DONE UNDER IT

**Author, 11 August 2026, on §2d: this has to meet a standard, not pick from
a menu. Strict everywhere.**

The standard is that a figure and the statistic printed on it describe the
same rows. There is exactly one way to have that by construction, which is
one reader; and which reader is not a free choice, because `1,5` plotted as
`1` is a wrong point on a page. D96 settled this for a mean and the same cell
plotted is no more defensible than the same cell averaged.

The objection that held this up for a turn — *it changes figures people have
already published* — is backwards. Those figures were already wrong. Changing
them is the correction, and stating it is how the people holding them find
out.

### Done

`@emlDrawColumnIsClean` tests the column once; every converted row filter then
reads cells with `@eml_readCell`, the reader `@emlExtractColumn` uses. The
column-level gate is not decoration: `@eml_readCell`'s fast path is a plain
`Get value:` and is only safe on a column already proven strictly numeric
with no empty cells, and `@eml_strictNumericColumn` copies the table to probe
the numericiser, so asking per row would be indefensible. A clean column pays
one test for the whole figure.

Converted, and measured on the parity fixture:

```
before   statsA n=2 excluded=5 | figure skipped=3 | extent n=7 max=99
after    statsA n=2 excluded=5 | figure skipped=5 | extent n=5 max=99
```

The axis moved with it, `-20..120` to `0..110`, because two points that were
never real are no longer drawn or reserved for.

| procedure | state |
|---|---|
| `@emlDrawViolinPlot` | converted |
| `@emlDrawBoxPlot` | converted |
| `@emlDrawGroupedViolin` | converted |
| `@emlDrawGroupedBoxPlot` | converted |
| `@emlGraphsColumnExtent` | converted — see below |

`@emlGraphsColumnExtent` was written in §2c against the lenient reader,
correctly, because the draw layer was lenient then. Converting the draw layer
left it behind for about an hour and it immediately showed the failure the
pairing exists to prevent: the extent still held the coerced 1 and 0.3, so the
axis reserved room for points the figure no longer drew. **The pairing is the
invariant, not either reader on its own**, and that is worth an assertion
rather than a comment.

### NOT yet done — and the standard is not met until it is

The four converted procedures are the ones the stats bridge annotates, which
is where figure-and-analysis parity is most visibly broken. They are not all
of it. Still on the lenient reader:

| procedure | reads |
|---|---|
| `@emlDrawTimeSeries` | time and value |
| `@emlDrawTimeSeriesCI` | time and value |
| `@emlDrawSpaghettiPlot` | value |
| `@emlDrawScatterPlot` | x and y, in three separate loops |
| `@emlDrawHistogram` | value, in two loops |
| `@emlMeasureBarData` | value and error bar |

**A partially strict draw layer is the §2d defect with a smaller blast
radius, not a fixed one.** Six procedures, ten reads, the same three-line
shape at each; the reason they are not in this commit is that the scatter and
histogram reads sit inside secondary loops (quality checks, the regression
fit) that need reading before they are touched, not that they are optional.

### The assertion that has to exist (v33)

Per §7 none of this counts as validated until an R script asserts it. The
check is parity, not either half:

> For each draw procedure and each fixture, the number of rows the figure
> discloses as skipped equals the number `@emlExtractColumn` excludes from the
> same column.

That is one number against one number, it fails loudly if either reader moves
without the other, and it would have caught §2d the day it was introduced.

---

## 2f. FIXED — the check-and-repair layer was mandatory on one bridge and absent from the other

Author, 11 August 2026: *don't we have a data cleaning layer? Is the issue
that it is optional rather than required?* Nearly — and the correction is
the useful part.

### It is not optional. It is mandatory on the stats path and absent from the graphs path

`plugin/scripts/eml-check-data.praat` is in the menu (Objects → New → Check &
repair data...). It repairs `1,5` → `1.5` per column via
`@emlCommaColumnMode`, `.5` → `0.5`, `n/a` → empty, and OFFERS `30%` → 0.3
with the switch off by default because the intent is ambiguous. Its own
header already names `30%` as the most dangerous case: *"it is not excluded,
it is accepted as a different number."*

But the layer that matters here is not the manual repair tool, it is the
CHECK. `@emlCheckDataScheme` audits every column and produces a printable
report naming the column, the first offending row, its literal contents, and
what to do about it. And:

| path | runs `@emlCheckDataScheme` |
|---|---|
| all ten stats wrappers, via `@emlWrapperInit` | **yes, on entry, automatically** |
| `@emlGraphsWorkflow` | **never** |

So a user who ran an ANOVA on a column of decimal commas was told. The same
user drawing the same column was told nothing. That asymmetry is the thing
underneath §2d — the lenient reader and the missing check are two halves of
one omission, which is that the graphs path skipped what the stats path does.

### What the graphs user now sees

`@emlGraphsWorkflow` calls `@emlCheckDataScheme` after context detection,
for Table / TableOfReal / Matrix contexts, and prints the existing report
verbatim — one wording, not a second that could drift from it:

```
DATA CHECK — some cells will be excluded:
  Column "v": 1 cell(s) use a comma where a decimal point belongs (row 3:
  1,5). Praat reads these as a different number, so they are excluded rather
  than guessed at. Replace the commas with points to use these values. ...
  Use Check & repair data to fix them, or re-export from your spreadsheet
  with an English (United States) locale.
```

### Why this is the half that was actually missing

The strict reader (§2e) stopped the graphs path silently coercing. It did not
make the graphs path SAY anything, and **a row that vanishes from a figure
with no explanation is only better than a wrong point on it, not good.**

The two together are the whole answer:

- **the strict reader** makes the cleaning layer non-optional IN EFFECT —
  un-cleaned cells are dropped rather than quietly turned into different
  numbers, so skipping the repair step costs you n rather than costing you
  correctness;
- **the check** makes it non-optional IN PRACTICE — the user is told, before
  the figure is drawn, which cells and why and what to do.

Neither alone is sufficient, which is why §2e on its own was not the answer.

### One thing the check recovers that both readers currently drop

`.5` is rejected by the strict reader AND by the lenient one — Praat reads a
bare leading point as undefined. The repair tool turns it into `0.5`. So for
that class the check does not merely explain a loss, it points at the only
route to keeping the data.

39/39 stress, 52/52 disclosure, 10/10 determinism byte-identical, 357/357
phase1, 8221/8221 R, both round trips PASS.

---

## 2g. DONE — every draw procedure reads cells the way the analysis does, and v33 pins it

Completes §2e. All 25 remaining lenient reads converted across six
procedures: `@emlDrawTimeSeries`, `@emlDrawTimeSeriesCI`,
`@emlDrawSpaghettiPlot`, `@emlDrawScatterPlot`, `@emlDrawHistogram`,
`@emlMeasureBarData`. No `number (Get value: ...)` row filter remains in the
graphs layer.

### Two defects found doing it, both invisible to the suites that existed

**1. `@eml_readCell` left NOTHING selected.** Its slow path goes through
`@eml_strictOneCell`, which creates a probe Table and `removeObject:`s it —
and `removeObject:` clears the selection. So on return the next bare Table
command in a caller's loop died with

```
Error: Command "Get value:" not available for current selection.
```

Six disclosure cases fell over, all of them **dirty-data** cases: a clean
column takes the fast path and never reaches the classifier. The procedure's
only caller had been `@emlExtractColumn`, whose loop calls nothing else, so
the omission had never shown. Fixed at the source rather than by re-selecting
at each call site — the entry line already selects `.tableId`, so a caller is
entitled to get back the selection it handed in, and every future caller would
otherwise have learned this the same way. `@emlDrawColumnIsClean` restores for
the same reason.

**2. `@emlMeasureBarData` tested a column that is usually `""`.** The
error-bar column is empty on every bar chart without error bars, and the
unguarded test aborted the whole figure with `there is no column named ""`.
Caught by `harness/determinism/run.sh` on the first run after the conversion.
The test is now gated on `.errorMode = 3`, the same condition as the read it
pairs with — a test on a different condition from its read is a different
question wearing the same name.

### v33, and the thing that makes it a check

`harness/parity/run.sh` renders the seven procedures that publish
`.nSkippedRows` over a clean and a dirty fixture, and writes one line per
case: the figure's disclosed skipped count, and `@emlExtractColumn`'s (or
`@emlExtractPairedColumns`' , for the two two-column procedures) excluded
count on the same data.

```
name        dirty  figure  stats  verdict
violin      0      0       0      MATCH
...
violin      1      5       5      MATCH
scatter     1      6       6      MATCH
parity: PASS — 14/14 agree, and the dirty half excludes rows
```

**Both numbers come out of Praat**, from the plugin's own procedures. R
compares them and never classifies a cell — an R-side copy of the rules would
be a second implementation that drifts, and a drifted copy agreeing with
neither reader would read as a failure of the plugin.

**The check was verified to fail.** The violin's read was reverted to
`number (Get value: ...)`, alone, and:

```
FAIL  v33  violin [dirty] -- figure skipped == analysis excluded
           reported=3  computed=5
38 checks, 37 passed, 1 FAILED
```

Restored, 38/38. Given what §2b and the old `probe_formpath.praat` cost, a new
check is not finished until it has been shown to fail on the defect it claims
to pin.

**Two guards keep it from passing vacuously.** Two readers that both drop
everything, or both drop nothing, agree perfectly — so the dirty half must
exclude at least one row, and the dirty half must EXIST. The second guard
exists because the harness hit exactly that on its first run: the case script
aborted before the dirty pass, the TSV held only clean rows, and everything
"passed".

39/39 stress, 52/52 disclosure, 10/10 determinism byte-identical, 357/357
phase1, **8259/8259 R** (8221 + v33's 38), both round trips PASS.

---

## 2h. FIXED — fifteen menu entry points were dead, and no suite could see it

Found 11 August 2026 by installing the plugin under Xvfb and clicking its own
menu. The error was a dialog, not a log line:

```
Duplicate label "END_RECORD_SOURCE" on lines 29445 and 13332.
Script ".../plugin_EMLPraatTools/scripts/eml-graphs.praat" not completed.
Command "EML Graphs..." not executed.
```

**EML Graphs, the wizard, the LMM path and every analysis wrapper — 15 of
them — did not run at all.** Not on one version: 6.6.30 and 7.0 alike. The
plugin was unusable from its own menu while 8259 R checks, 39/39 stress,
52/52 disclosure, 357/357 phase1 and both round trips were green.

### The cause is one line

`eml-lib.praat` loads `eml-lib-stats.praat`, which includes
`eml-record.praat`; then it loads `eml-lib-graphs.praat`, which included it
**again**. `include` is a textual paste and `eml-record.praat` contains
`label` statements, so the second paste defined every label twice. Praat
rejects that at PARSE time, before one line runs.

`eml-lib-stats.praat` says, in a header comment, *"Including the same file
twice is harmless. `include` is a textual paste."* **That is true only of a
file with no labels in it.** The recorder acquired labels and the comment did
not.

The include was also no longer needed. It was there because
`@emlDrawViolinPlot` calls `@emlRecordViolin`, but that call is now wrapped in
`variableExists ("emlRecordActive")` and Praat only errors on an undefined
procedure when it EXECUTES the call — so an absent recorder costs nothing.

### The reason nothing caught it is the finding worth keeping

Every harness in this tree includes the individual plugin files.
`harness/stress_cases/_prelude.praat` names nine of them, one by one, and says
so. **Nothing anywhere loaded `scripts/eml-lib.praat`** — which is what all 16
shipped wrappers actually load.

So the suites exercised a composition of the plugin that no user ever runs,
and the composition every user runs had never been loaded once. Coverage of
the parts is not coverage of the assembly.

### The guard

`harness/wrappers/run.sh` runs every `plugin/scripts/*.praat` headless and
fails on a STRUCTURAL error — duplicate label, unknown symbol, unreadable
include. It does not care that a wrapper then refuses for want of a selected
Table, or dies for want of a display: those mean it parsed, which is all this
asks. 26/26 parse. The wrapper count is asserted too, so a deleted entry
point has to be dealt with on purpose rather than by silence.

---

## 2i. FIXED — the auto-composed title was escaped twice and lost the character

Found in the same GUI pass, by looking at the figure the menu produced. The
title read `Jitter (  ) by group` where the y-axis label, on the same figure,
read `Jitter (%)`.

Rendered side by side, the middle row is a pixel match for the title:

| string | renders as |
|---|---|
| `Jitter (\% )` — escaped once | `Jitter (%)` |
| `Jitter (\\%  )` — escaped twice | `Jitter (  )` |
| `Jitter (%)` — never escaped | `Jitter ()`, percent eaten, paren italic |

So this is a DOUBLE escape, not a missing one, and `@emlSanitizeLabel` is not
idempotent.

`@emlComposeGraphTitle` sanitizes every part it assembles —
`@emlCapitalizeLabel` for the value column (which already returns `Jitter
(\% )`), `@emlSanitizeLabel` for `.x$`, `.sub$` and `.source$`. Then
`@emlDrawAxes` sanitizes the finished title again. Its own comment explains
why it does that:

```
# Sanitize title only — axis labels are sanitized at generation
# (auto labels via @emlCapitalizeLabel) or passed raw (user-typed...)
```

The premise was true when written: the title WAS raw.
`@emlComposeGraphTitle` made it false, and the draw site was never told. The
axis label rendered correctly for exactly the reason the comment gives — it
is deliberately not re-sanitized.

It is not confined to the value column. Every auto-composed part is escaped
twice; only parts containing no special character survive, which is why the
defect looks isolated.

**The fix is idempotence, not removal.** Deleting the draw-site call would
leave a user-typed title unescaped, which is what that call exists to
prevent — and a user's title is the one string in the figure the escaper can
assume nothing about. So the escaper is made safe to apply twice and both
call sites stay.

`@emlSanitizeLabel` now NORMALISES before it escapes: every escape already
present is undone first, so the string reaching the escaping pass is in one
state whatever state it arrived in. A sentinel-and-restore scheme was written
first and rejected — every sentinel expressible in a Praat string literal is
a string a label could also contain, which trades one collision for another.
Un-escaping has no such hole; it is the exact inverse of the pass that
follows.

Rendered proof: the same already-escaped title that produced `Jitter (  )`
now draws `Jitter (%) by Group` after passing through `@emlDrawAxes`.

### v34, and it was verified to fail

`harness/disclosure/probe_label_escape.praat` applies the escaper ONCE, TWICE
AND THREE TIMES to seven shapes — three, not two, because a two-application
check passes on an escaper that alternates. It also asserts the specific
composition that broke (`@emlCapitalizeLabel`'s output must be a fixed point
of `@emlSanitizeLabel`) and that a figure drawn with such a title exists and
carries ink — because every intermediate STRING was correct here and only the
pixels were wrong, which is how this survived.

Removing the normalise block and re-running:

```
FAIL v34  escaping percent is stable under repetition
FAIL v34  escaping preescaped is stable under repetition
FAIL v34  escaping hash / caret / allthree ...
FAIL v34  @emlCapitalizeLabel output is a fixed point of @emlSanitizeLabel
```

Restored, 15/15. Suite total 8274.

---

## 2j. MEASURED — Praat 7's trust wall does not touch the plugin's own menu

Driven under Xvfb on 7.0, 11 August 2026, and it refines §11 rather than
contradicting it.

**A plugin menu command wrote a 300-dpi PNG with no dialog at all.** New →
+EML Tools → EML Graphs → Draw → Save produced `/root/_Violin_Plot.png`,
70284 bytes, silently.

**A script run from the command line or Script window is a different story**,
and this is where the emitted record-workflow file lives:

- Button 2, *"Yes, I allow this script to perform the action that it requests
  (and ask me again next time)"* — grants exactly ONE write. The next write
  raises a new dialog, named for the next file.
- Button 3, *"...CONTROL MY COMPUTER from now on..."* — clears the rest of
  that script.
- **The grant does not carry to another script.** A second script sent to the
  same live Praat session raised its own dialog.

So the plugin is unaffected on 7.x. **The emitted workflow script is not**,
and being re-run is that file's entire purpose. A user who opens it and
presses Run answers a dialog per save unless they grant full computer control
to it.

### Two Praat 7 facts the harness assumed wrongly

- The instance lock is `~/.config/praat/pid.txt` and `Message.txt`, NOT
  `<pref-dir>/pid`. The 6.x stale-lock recipe does not clear it, and Praat
  exits with *"An instance of Praat that is not me is already running."*
- **`--pref-dir` does not relocate the plugins folder.** Plugins load from
  `~/.config/praat/plugin_*` regardless. The plugin installed under a custom
  `--pref-dir` produced no menu at all; moved to `~/.config/praat`, the
  `+EML Tools` menu appeared.

Both mean the harness's `--pref-dir` isolation is 6.x-only.

---

## 2k. VERIFIED — the full shipping path, and the three papercuts it found are fixed

Driven end to end on 6.6.30 under Xvfb, 11 August 2026, from the plugin's own
menu: Create Demo Table -> Compare two groups -> Run -> CSV -> Draw -> column
mapping -> Draw -> Save. Every stage below had never been executed by anything
in this repository.

**What works.** The analysis runs; the CSV export writes three correctly
shaped broom files (`_tidy`, `_glance`, `_effectsize_tidy`) with broom column
names; the Draw branch hands off to the graphs form preloaded with the right
graph type; the figure draws; the save produces a clean 1800x1200 PNG.

**The §2i fix is verified through the real path.** The auto-composed title on
the saved file reads

```
Jitter (%) by group (demo 2groups)
```

where before the fix the same path produced `Jitter (  ) by group`. That is
the composed-title route, from the menu, not a probe.

### Three papercuts, all visible only by looking

1. **The Export Complete dialog draws its OK button ON TOP of the third
   filename.** It reports "Wrote 3 files:" and lists three paths; the button
   overlaps the last one. `/root` is a short folder — a real user path makes
   it worse.

2. **The Draw branch loses the Table selection.** Coming out of a completed
   analysis, which had a Table, the graphs form opens on "No Table selected"
   and asks the user to pick it again. This is the one path in the plugin that
   already knows which Table the user means.

3. **The default save filename is `_Violin_Plot`** — a leading underscore.
   The builder composes `<title>_<GraphType>` from the USER-TYPED title field,
   which is blank whenever the title was auto-composed. So the figure has a
   title and the filename does not, and every auto-titled figure a user saves
   is named with a leading underscore.

None is a wrong number and none blocks anything. All three are what a
reviewer meets in the first five minutes, and none was reachable from a
headless harness.

### Fixed, and 2 and 3 turned out to be ONE defect

**The handoff loss (2) and the leading underscore (3) had the same cause.**
`@emlGraphsWorkflow` selects its `.objectId` and detects context from it at
entry — that is how a wrapper hands over the Table it just analysed. A second
`@emlDetectContext`, at the top of the main-form loop, then read the CURRENT
Objects-window selection and threw the caller's object away, because after an
analysis the selection is no longer the source Table.

Its comment says why it is there — *"handles Go Back after user changes
selection in Objects window"* — and on the FIRST pass there has been no Go
Back to handle, so re-detecting can only discard what the caller supplied
deliberately. It is now gated on a pass counter and does exactly what its
comment says from the second pass on.

With the Table restored, the filename builder has a name to compose from, and
the saved file came out `demo_2groups_Violin_Plot.png` instead of
`_Violin_Plot.png`. **The underscore was a symptom, not a defect** — worth
recording, because fixing it where it was visible would have papered over the
handoff and left the user still picking their Table by hand.

Reproduced with and without a CSV export in between, so it was the re-detect
and not something the exporter left behind. Verified in the GUI: Compare two
groups → Run → Draw now goes straight to the column-mapping dialog.

**The dialog overlap (1)** was `comment:` given a string containing
`newline$`. It reserves the height of ONE line at layout time but draws
whatever it is handed, so the widgets below are painted over it. Now one
`comment:` per path, emitted by a `while` loop — legal between `beginPause:`
and `endPause:`, which is why every wrapper here uses `beginPause:` rather
than `form:`. Verified: three readable paths with the OK button below them.

---

## 2l. NEW — `harness/gui_e2e/run.sh`, the first check that assembles the plugin

Every harness in this tree exercises the plugin's PARTS. This one starts a
display, starts a window manager, starts Praat, and drives the shipped
workflow through its real dialogs. It exists because on 11 August 2026 four
defects were found by installing the plugin and clicking it — fifteen dead
entry points, a title that lost its special characters, a Draw branch that
threw away the Table it was handed, a dialog that painted over its own output
— and not one was visible to 8274 R checks, 39/39 stress, 52/52 disclosure,
357/357 phase1 or two byte-exact round trips.

`driver.praat` sets the presets `eml-compare-groups.praat` sets and calls
`@emlGraphsWorkflow` with a Table id — its lines 155-160, not a paraphrase of
them. Everything after that call is shipped code.

### What it asserts

The workflow must reach the column-mapping stage without ever raising
"No Table selected". It was handed a Table; asking for it again is §2k.

**Verified to fail.** With the first-pass guard removed:

```
  1. EML Graphs
  2. No Table selected
  3. No Table selected      ... and on, to the step bound
gui_e2e: FAIL — the workflow asked for an object it was handed.
gui_e2e: FAIL — never advanced to the column-mapping stage
```

Restored: `PASS — the workflow advanced to column mapping in 2 dialogs`.

### No screen coordinates, and two measured facts that make that possible

- **Return presses BUTTON 1, not the dialog's default.** The first version
  assumed the default and sat on the main form pressing Undo fourteen times,
  reporting a hang.
- **Tab walks the row exactly**: Tab ×0 → button 1, ×1 → 2, ×2 → 3, ×3 wraps.
  So Tab ×(N−1) then Return presses button N.

A harness that clicked at pixel positions would break the first time a dialog
gained a field and would then be "fixed" by moving numbers until it went
green, which is how a check stops meaning anything.

### Where it stops, and why it stops there

At column mapping. Going deeper needs a specific button per dialog, and Tab
visits every focusable widget — so the count differs with each dialog's field
count. That is solvable and it is a separate piece of work. Guessing the
counts until a run went green would produce a harness that clicks something
plausible and reports success, which is precisely the failure this file
exists to end.

The figure is not left unchecked: `harness/determinism`, `harness/stress` and
v34 all assert on rendered output. What only this harness can see is whether
the shipped workflow ADVANCES when a wrapper hands it a Table.

### The self-inflicted finding, kept because it will recur

Its own first run launched `matchbox-window-manager` without `DISPLAY` in the
environment — Xvfb takes the display as an argument, matchbox reads it from
the environment. The window manager exited 1, `xdotool windowactivate` failed
with *"Your windowmanager claims not to support _NET_ACTIVE_WINDOW"*, no
dialog took focus, and every keypress went nowhere. That is the exact failure
`harness/GUI_HARNESS_RECIPE.md` §1 warns about, met by not reading it
carefully enough. The script now fails loudly if the window manager is not
running rather than reporting the symptom.

### v35 puts both under the validation standard

`validate/v35_assembly.R` reads `harness/wrappers/out/WRAPPERS.tsv` and
`harness/gui_e2e/out/DIALOGS.tsv` — two artefacts that exist only because
something assembled the plugin and ran it. It asserts that every entry point
parses, that the barrel and the graphs entry point are among those checked by
name, that the workflow never asks for an object it was handed, and that
column mapping comes AFTER the main form rather than merely appearing (a
presence-only check cannot tell "advanced" from "fell back").

**Verified to fail on BOTH defects it pins, separately.**

Duplicate include restored:

```
FAIL v35  entry points that fail to parse   reported=0  computed=15
FAIL v35  eml-compare-groups.praat parses (Duplicate label)
          ... and thirteen more
```

First-pass guard removed:

```
FAIL v35  the workflow never asked for an object it was handed
FAIL v35  the workflow advanced to the column-mapping stage
FAIL v35  column mapping came after the main form
11 checks, 8 passed, 3 FAILED
```

Both restored: 11/11, suite total **8285**.

The per-wrapper logs and per-run PNGs stay out of the repository; the two
TSVs are the evidence and are committed, so a missing artefact is a hard stop
rather than a skip.

---

## 3. CLOSED — the categorical x-axis labels have no off switch

`Show axis values` (None / Both / X only / Y only) is in the Advanced block of
every graph type and is honoured on continuous axes.
`@emlDrawCategoricalXAxis` never reads `emlShowAxisValuesX`; it draws
`emlCatLabel$[]` unconditionally. So on the six types with a categorical x axis
the control is present in the dialog and silently does nothing.

**AUTHOR'S RULING, 11 August 2026: current behaviour is correct. Closed, not
deferred.** A categorical axis without its category names is not a figure
anyone can read, so there is nothing a user would want the control to do
there, and the control is left present rather than hidden per-type because
the Advanced block is one shared layout.

**A REVIEWER WILL FIND THIS, so it is written down rather than dropped.** The
symptom — a dialog control that has no effect on six of the graph types — is
indistinguishable from an unfinished wiring job unless the reason is stated
somewhere. This section is that statement.

If it is ever wired up anyway, the MEASUREMENT has to be gated with it.
`@emlFitCategoricalLabels` sets rotation and overhang, and both
`@emlDrawCategoricalXAxis`'s extent report and the form's matrix-gap budget
(`graphOverhangInches`) spend that reservation. Suppressing the labels without
zeroing the measurement reserves space for text that is never drawn — a gap
under the plot with nothing in it, on every affected type.

---

## 4. Known limitations, documented, not scheduled

- `@emlPlaceElements` scores whole quadrants, not the legend rectangle. A
  legend that would fit in a partly-occupied quadrant is still penalised for
  the whole quadrant.
- `@emlMeasureGraphLayout`'s legend estimate reads `legendN` before dispatch,
  so on the first pass it is measuring the previous figure's entry count.
- Two-pass render cost for inside-legend figures on types 5, 8, 10, 11, 12, 13
  (draw, read back the resolved axis, erase, redraw widened).
- Pass-1 Info notes appear twice on those figures. They are labelled, but they
  are still duplicated.
- Brackets plus a legend on one figure is refused with a NOTE rather than
  solved. No shipping type reaches it (brackets are 6/7/9, legends are
  5/8/10/11/12/13) and the arithmetic in `@emlComputeAnnotationHeadroom` would
  handle it, but the base axis has already been widened for the brackets by
  pre-dispatch, so asking again would double-spend.
- 18 `.sh` files are non-executable on the remote. The GitHub web upload form
  cannot set the executable bit and direct `git push` is blocked by the proxy,
  so this cannot be fixed from this sandbox. Fix in the packaging step.

---

## 5. Platform

**DONE (verify on Mac).** `@emlDrawAnnotationBlock` never restored the viewport
after the alpha sprite. `Insert picture from file:` leaves the viewport on the
inserted image's own bounding box, so the block's border and text were drawn
into the wrong rectangle on macOS and Windows. Invisible to every Linux render,
because Linux takes the screen-door path and never moves the viewport.

**DONE.** `@emlDrawAnnotation` — the on-graph note box — was the last labelled
box painting solid white, on every platform. Now routes through
`@emlPaintAlphaBox`.

**Established, not a defect.** Alpha compositing is unreachable from Praat
script on any platform. `Insert picture from file:` is a silent no-op on
Linux (`Graphics_imageFromFile` has GDI+ and Quartz branches, no cairo branch);
`Paint image:` on an RGBA Photo draws flat grey equal to the alpha value;
there is no Matrix→Photo recombine command. The screen-door stipple is the
Linux fallback: measured 0.734 coverage at 300 dpi against the sprite's 0.702,
holding down to 1.5 × 1.0 in.

---

## 6. Deferred by the author

Ruling 2 (D33/D63/D64 graphing unification), Ruling 3 remainder (D38, D40),
D84. Stats Demo, Quick Start, tutorial, and Batch voice analysis are tabled.

---

## 7. Validation standard

Nothing counts as validated until an authored R script tests the output,
including the red-path input. Current baseline, 12 Aug 2026:
**9356 checks, 0 failed** (`Rscript validate/run_all.R`), 39/39 stress cases
(`bash harness/stress_graphs.sh` — 29 OK, 10 expected `BLANK_FRAME_ABS`, and
now byte-identical run to run), 52/52 disclosure, 10/10 determinism
byte-identical, 14/14 parity, 26/26 wrappers, `gui_e2e` PASS, phase1 **361/361**,
both round trips PASS.

**What moved, 11-12 Aug:** 8285 -> 9330. v32 gained §11 (the four
non-categorical legend types, +346); `eml_census` landed and was wired into
v33 and v35 (+5); v36 covered the 29 unvalidated stress cases (+586); v37
gave the determinism harness its first external check (+108); and coverage.R
(v38) asked, for the first time, whether anything is looking at each artefact
at all (+26). Two harnesses
that reported only to themselves now report to an R script, and the stress
artefact became a baseline instead of noise.

**CLOSED — the four non-categorical types.** This section used to read: the
legend placement geometry is asserted by `validate/v32_legend_geometry.R`,
but the four non-categorical types were verified 9 Aug by direct pixel
measurement and those measurements are not yet in v32. They are now. §1 has
what was built; the number moved 4117 → 4463 in v32 and 8285 → 8631 across
the suite. The hand measurement in §1's table stands as the record of what
was seen that day, and is no longer the evidence.

The general point is worth keeping, because it is the one that let the dead
menu entry points ship (§2h): **a number in this file is a record of what
someone saw once. It is not a check.** Anything measured by hand here belongs
in an R script before it is relied on.

---

## 8. OPEN — the emitted workflow cannot re-run headless

Added 9 August 2026, from the first wrapper wiring of the record-workflow
feature.

`TREATMENT_record_workflow.md` §6 settles the emission level on wrapper-level
`runScript:` calls and reports that form "verified headless, two sequential
calls, arguments passed positionally and the form bypassed". **That
verification used a probe script with a `form: ... endform` block. No EML
wrapper has one** — every wrapper uses `beginPause:`, and the two do not
behave alike.

Measured against a real copy of the plugin tree:

| call | result |
|---|---|
| `runScript: ".../eml-compare-k-groups.praat", "SPL_dB", "voice_type", 1` | `Error: Found 3 arguments but expected only 0.` |
| `runScript: ".../eml-compare-k-groups.praat"` (no Table selected) | clean refusal, as designed |
| `runScript: ".../eml-compare-k-groups.praat"` (Table selected) | `Gtk-ERROR: Can't create a GtkStyleContext without a display` |

Two consequences:

1. **§9's round trip is not achievable at wrapper level** while wrappers use
   `beginPause:`. Drive the GUI, emit, run the emitted script headless, diff
   the two Info outputs — the third step cannot happen. This matters because
   §9 is the part of the proposal that is a contribution rather than a
   feature note.
2. **Making it achievable is a change to the wrappers, not to the recorder** —
   giving each a `form:` path taken when arguments are supplied. Sixteen
   wrappers, and it wants its own decision.

The recorder now emits the no-argument call with the resolved values as a
comment directly above it, plus the limitation in the code block itself.
Emitting the argument form would put a line in the user's file that cannot
run anywhere, which is worse than one that runs in the GUI only. Asserted by
`test-record-anova.praat` so a later edit cannot quietly restore it.

## 9. OPEN — a stats orchestrator reaches into the graphs tree

`@emlRunAnovaAnalysis` (in `plugin/stats/eml-analysis.praat`) calls
`@emlReportAnovaComparison`, which is defined in
`plugin/graphs/eml-annotation-procedures.praat`. So the stats stack cannot be
loaded and exercised on its own: `plugin/dev/tests/phase1/test-record-anova.praat`
has to include two graphs files to test an ANOVA.

Found while writing that test. Not fixed — moving the reporter is a question
about where reporting lives, not a defect with an obvious repair.

## 10. SUPERSEDED — the recorded workflow has no input file

**As first written:** the orchestrators are handed a `tableId`, never a path,
so nothing in the chain registers the input. The emitted script therefore
carries a correct analysis, correct numbers, a correct call line, and no
statement of what data any of it ran on. The renderer named the gap rather
than omitting it — the emitted file opened with
`INCOMPLETE -- NO INPUT FILE WAS RECORDED`.

**Superseded 9 August 2026 by the author's API-level ruling**, and the notice
no longer exists. The emitted file no longer bootstraps itself: it carries an
`include` block and operates on `selected ("Table")`, so there is no input
path for it to need. What a reader needs is not the path the recording
session read but a way to know the right object is selected now, so the
object's NAME AND SHAPE go in the header as provenance:

```
# Input: vt -- 100 rows, 2 columns
```

`@emlRecordSource` is first-wins and sets `emlRecordSourceChanged` if a later
step works on a different object, so a session that silently switched tables
is visible in the emitted file rather than averaged into it.

This section is kept rather than deleted because the original text is the
argument the design decision answered, and a reviewer reading only the
resolution would not see what was traded away: the emitted file is no longer
runnable on a bare Praat with no object loaded. That is the cost, and it was
taken deliberately.

---

## 11. RULED — Praat 7's trust wall is a platform behaviour, not a plugin defect

Found 10 August 2026, after the author asked why the session was running
Praat 6.4.x. Measured on 7.0:

```
Error: The following potentially dangerous action was requested by the
script "..." but is not allowed without --FULL-TRUST:
save a line of text to the file "..."
```

Every write in the plugin goes through the same wall: `@emlSaveConfig`, CSV
export (`@emlWrapperExportCSV`), every `Save as 300-dpi PNG file:`, the broom
three-file result writer, the record-workflow crash mirror, and now the
emitted workflow script.

**AUTHOR'S RULING, 11 August 2026.** Three parts:

1. **The supported target is 6.6.30. Test there.** 7.0.0 may relax the
   standard before it matters, and a plugin-wide change made now against a
   rule that moves is work spent twice.
2. **Command-line invocation needs the trust tag.** That is the harness's
   job, not the plugin's — `harness/_env.sh` adds `--FULL-TRUST` only when
   `_v1 >= 7`, because 6.6.30 does not know the flag.
3. **GUI invocation — standalone script or plugin — raises an approval
   window with a third button, and the approval persists until the session
   resets.** So the user's path through 7.x is a dialog they answer once, not
   a refusal. There is nothing for the plugin to detect, warn about, or work
   around.

**Consequence: no shipping file changes.** The three postures that were on
the table — refuse-with-a-message on `praatVersion >= 7000`, route writes
through a trusted menu action, or do nothing — resolve to the third, and it
is the third for a reason rather than by default: 1 and 2 would both suppress
a dialog the user is meant to see and would have to be unwound when 7.x
settles. This is recorded, not scheduled.

The version-conditional trust flag stays in the harness, verified green on
both builds:

```
PRAAT=<repo>/../praat      -> PASS (Praat 6.6.30)
PRAAT=<repo>/../praat7000  -> PASS (Praat 7.0)
```

What is still true and worth a reader knowing: phase1 is 357/357 on 7.0 with
the flag and dies without it. That is the evidence the wall exists, and it is
why the harness carries the flag rather than the plugin.

## 12. RESOLVED — the session was testing on the wrong Praat

`/usr/bin/praat` is **6.4.06, April 2024** — below the plugin's own floor
(`emlMinPraatVersion = 6630`). A bare `praat` on PATH resolves to it.
`/home/claude/praat` is the 6.6.30 symlink, and it is what
`harness/stress_graphs.sh` and `harness/disclosure/run.sh` have always used
via `PRAAT=/home/claude/praat`.

So: the 39 stress cases and the 52 disclosure runs were always on 6.6.30, and
`validate/run_all.R` runs no Praat at all (it compares committed captures
against R, so its 8221 checks are unaffected). What *was* wrong is
**phase1 and the record round trip**, which invoked a bare `praat`.

Re-run on the pinned 6.6.30: **357/357, no differences**. Nothing reported
earlier was wrong, but nothing reported earlier had been established on the
supported build either.

Two things fixed rather than noted:

- `harness/record/roundtrip.sh` now pins `PRAAT=/home/claude/praat` and
  isolates `--pref-dir`, matching the other harnesses. The missing
  `--pref-dir` is precisely why that harness passed five times and then
  failed: installing the plugin caused a `prefs5` to be written,
  `TextEncoding.outputEncoding: try ASCII, then UTF-16` took effect, and a
  byte-oriented diff stopped matching.
- `test-record.praat` asserted the tilde substitution unconditionally. It is
  conditional on `preferencesDirectory$` sitting under `homeDirectory$`,
  which is true normally and false under `--pref-dir`. The unconditional
  assertion failed under exactly the invocation the rest of the rig uses, and
  it looked like a 6.6.30-versus-6.4.06 regression until
  `preferencesDirectory$` was printed under both. Both branches are now
  checked.

---

## 13. RESOLVED — the rig is no longer pinned to one machine

10 August 2026. **30 executable files** hardcoded `/home/claude`. Now 2, both
of which quote the old form deliberately in explanatory prose
(`harness/_env.sh`, `validate/v17_broom_parity.R`), plus two `.md` files
still to sweep.

The defect was never "a copy of the repo fails elsewhere". It is that
`harness/stress_cases/_prelude.praat` included the plugin by absolute path,
so a copy rendered anywhere else **silently loaded the original tree's
plugin** and produced 39 figures that looked entirely correct while
describing a build nobody asked about. Hit for real earlier in this audit:
the only symptom was that a revert appeared not to take effect. It also meant
the audit could not be reproduced by the person it is being handed to, which
is the point of handing it over.

**New: `harness/_env.sh`**, sourced by every driver. Resolves `EML_ROOT` from
its own location, resolves `PRAAT` (`$PRAAT` → repo-adjacent → PATH),
**refuses a binary below 6.6.30**, and sets `PRAAT_TRUST=--FULL-TRUST` on
Praat 7.x. Every scratch preferences directory moved in-tree and gitignored,
or under `$TMPDIR`.

**Verified the way the original defect would have been caught.** A copy of
the repo at `/tmp/eml_copy` had a sentinel line added to *its* copy of
`@emlInitDrawingDefaults`, and only its copy:

| run | sentinel in the log |
|---|---|
| the copy's harness | present |
| the original's harness | absent |

Then the full suite from the copy: **39/39 stress, 52/52 disclosure,
roundtrip PASS**, and the copy's emitted workflow cites
`/tmp/eml_copy/plugin/...`. The original is unaffected: 39/39, 52/52,
roundtrip PASS, phase1 357/357, 8221/8221 R checks.

## 14. FIXED (12 Aug 2026) — the stress figures are not deterministic

Found while checking whether the de-absolutising had changed anything. It had
not; the numbers move on their own.

**22 of the 39 stress cases call `randomGauss` with no seed.** Two
consecutive runs of `violin_baseline` with no code change between them:

```
violin_baseline    OK   11.348%   230063
violin_baseline    OK   14.106%   289575
```

So the ink percentages and chromatic-pixel counts committed in
`harness/stress_out/RESULTS.tsv` are **not a baseline** — they churn on every
run, and every "re-render" commit in this audit has churned them. A reader
diffing two commits could easily read that as a regression.

`validate/v27_empty_frames.R` is unaffected, and deliberately so: it asserts
*inequalities* — verdict in {OK, BLANK_FRAME_ABS}, chromatic px > 0, ink > 0,
and every populated case scoring above its empty sibling — never exact
values. That was the right design and it is what keeps the suite meaningful.

Two residual risks worth a decision:

1. The empty-versus-sibling assertion depends on random draws. Its own
   comment names the tightest margin as `violin_n1` at about +15% over
   `empty_violin`. With unseeded data that margin is a random variable, so
   the check could flake. Not observed flaking, not proven not to.
2. `RESULTS.tsv` invites being read as a baseline when it is not.

The cheap fix for both is an in-script LCG in place of `randomGauss`, as
`harness/legend/placement_sweep_case.praat` already uses. It would change
every committed figure once, then never again.

**DONE, 12 Aug 2026.** All 22 converted to the LCG, each with its own seed
(20260812 + a per-case offset) so that two cases of the same shape cannot
produce the same data and make a future cross-case check pass by coincidence.
Every call site was `randomGauss(0, sd)` and became `rnd.g * sd`; the
generator was measured over 200 draws for all 22 seeds (|mean| <= 0.10,
sd 0.91-1.05), so centre and spread are preserved. `violin_outlier` keeps its
literal 5000; `violin_undefined` draws inside the `else` branch only, so its
blank rows stay blank.

**Proven, not asserted:** the harness was run twice and `RESULTS.tsv` and all
39 PNGs are byte-identical between runs. All 39 verdicts are unchanged
(29 OK, 10 BLANK_FRAME_ABS). The ink and chroma numbers moved once,
permanently, and `harness/stress_graphs.sh`'s own comment block was corrected
where it quoted the pre-seeding figure.

One thing this did NOT make reproducible: three spaghetti logs carry a
wall-clock line from Praat's stats banner, so the LOGS are not byte-identical
even though the figures are. Data lines in them are identical.

**This was the blocker on §17,** not a tidiness item. It is listed first for
that reason.

---

## 15. FIXED — a grouped histogram aborted for every caller but the form

Found 10 August 2026 by `harness/determinism/run.sh` on its first run.

`@emlDrawHistogram`'s overlay path calls `@emlDrawAlphaRect`, which reads
`emlInitAlphaSprites.available` — and `@emlDrawHistogram` never called
`@emlInitAlphaSprites`. So a histogram with **more than one group** died with

```
Error: Unknown variable: emlInitAlphaSprites.available
```

for any caller that is not `eml-graphs-form.praat`: a user script, a PraatGen
companion file, or a recorded workflow replaying itself. The form happens to
call `@emlInitAlphaSprites` itself, which is why the GUI path never saw it.

**This is the same defect that was fixed in `@emlDrawScatterPlot` and
`@emlDrawTimeSeriesCI` on 6 August**, with a comment on both explaining
exactly this failure mode. The histogram was missed.

**Why five months of stress runs never caught it:** every histogram case in
`harness/stress_cases/` draws UNGROUPED — `hist_baseline` passes `""` as the
group column — and the overlay branch is only reached with more than one
group. The suite had a histogram case, three of them, and none of them
entered the code path that was broken.

A static sweep of all ten Table-consuming draw procedures now confirms this
was the only one: no other procedure reaches `@emlDrawAlphaRect`,
`@emlDrawAlphaDot` or `@emlPaintAlphaBox` without initialising the sprites.

## 16. NEW — `harness/determinism/run.sh`

Renders each of the ten Table-consuming draw procedures **twice, in two
separate Praat processes, from one seeded fixture**, and compares the PNGs
byte for byte.

The question it answers is one the stress suite cannot: given the same data,
does a draw procedure produce the same picture twice? 22 of the 39 stress
cases use unseeded `randomGauss` (§14), so no two runs of one case are
comparable and nothing in that suite would notice a procedure that began
producing a different correct-looking figure. `v27` survives that by
asserting inequalities and never values — right for what `v27` checks, and it
leaves this unchecked.

Two *processes* rather than two draws in one script, deliberately: a
generator seeded once at the top would give the second draw different
numbers, which would measure the fixture rather than the procedure.

Result after the §15 fix: **10/10 STABLE.** So every Table-consuming draw
procedure is reproducible, and a byte-for-byte baseline is achievable for
all of them — which is what makes the §14 fix (seeding the stress cases)
worth doing rather than merely tidy.

---

## 17. FIXED (12 Aug 2026) — 29 of the 39 stress cases are exercised but not validated

Found 12 Aug 2026 by asking the coverage question of the stress artefact,
which is the question §16b's `eml_census` exists to ask.

`harness/stress_graphs.sh` renders **39** cases. `validate/v27_empty_frames.R`
asserts on the **ten** named `empty_*` cases — by design; that is what the
file is about. Nothing asserts on the other **29**:

```
bar_baseline      bar_customerr      bar_sd            box_baseline
gbox_baseline     gviolin_baseline   hist_1bin         hist_200bins
hist_baseline     legend_cap         scatter_baseline  scatter_grouped
spaghetti_baseline spaghetti_grouped ts_baseline       ts_duplicate_times
tsci_baseline     violin_12groups    violin_baseline   violin_bw
violin_hugevalues violin_longlabels  violin_n1         violin_onegroup
violin_outlier    violin_spanzero    violin_tinyvalues violin_undefined
violin_zerovar
```

**What "29 OK" currently means.** It is the DRIVER's verdict: the case ran,
Praat did not error, a PNG appeared, and its ink and chromatic-pixel counts
were measured. That is a smoke test. It is worth having and it is not what
§7 asks for — *nothing counts as validated until an authored R script tests
the output.* By that standard 29 of 39 stress cases are unvalidated, and they
are the ones named after the pathologies: `violin_undefined`,
`violin_zerovar`, `violin_spanzero`, `violin_n1`, `violin_hugevalues`,
`hist_1bin`, `hist_200bins`, `ts_duplicate_times`.

**Why it was never written, and this is the load-bearing part.** It could not
be. §14: 22 of the 39 cases call `randomGauss` with no seed, so their ink and
chroma churn on every run. An R script cannot pin a value that is a different
number each time, which is exactly why `v27` was written as inequalities and
why the other 29 were left alone. **§14 is not a tidiness item — it is the
blocker on §17.** Seeding comes first; the assertions become possible after.

**DONE, 12 Aug 2026 — `validate/v36_stress_output.R`, 586 checks.** All 39
covered, declared inventory through `eml_census`. Ink and chroma are pinned
now that §14 made them a baseline, at a stated tolerance (chroma +/-5%, the
driver's own antialiasing margin; ink +/-max(5%, 0.10 pp), the floor because
ink on a near-empty frame is mostly glyph coverage) rather than to six
figures, which would buy a brittle suite.

What each case is NAMED for is what is asserted, and the evidence is DERIVED
rather than copied: `violin_undefined`'s skipped count computed from the
fixture (24 rows / modulus 4 = 6) and matched against the disclosure line;
the histogram bin count read off the case's own draw call; `violin_hugevalues`
and `violin_tinyvalues` proven textually identical modulo the scale token and
then required to render the same figure across twenty-one orders of
magnitude; `legend_cap`'s four box slacks recomputed from the measured frame.

**Two facts nothing in the tree had recorded**, found by writing it:

- Eight violin pathologies disclose NOTHING — `violin_zerovar`, `n1`,
  `spanzero`, `hugevalues`, `tinyvalues`, `outlier`, `longlabels`,
  `12groups` have one-line logs saying only `SAVED`. Only `violin_undefined`
  prints a count. The silence is now asserted as silence rather than a NOTE
  being assumed.
- `violin_longlabels.png` is **1800 x 1410**, the only case in the artefact
  whose canvas exceeds 1200. Correct behaviour — `@emlAssertFullViewport`
  saves the drawn extent, so long labels grow the image rather than being
  clipped — and previously unrecorded anywhere.

And one claim that turned out to be false and is worth keeping: "every
populated case out-draws every empty frame" does NOT hold across the
artefact. `violin_n1` (5318), `violin_bw` (6130) and `violin_zerovar` (6046)
all score below `empty_ts` and `empty_tsci` (6969). That is exactly why v27
compares within a family and not across the artefact.

---

## 18. FIXED (12 Aug 2026) — the determinism harness has no validator

`harness/determinism/run.sh` (§16) is the only harness in the tree that no R
script reads. It prints `STABLE` / `VARIES` to stdout, writes twenty PNGs and
their logs, and exits non-zero on failure — and that is the whole of the
evidence. The **10/10 byte-identical** figure quoted in §7's baseline is the
harness reporting on itself.

That is the same shape as the 29 above and it fails the same standard. It is
also the weakest link in the chain the other harnesses hang off: determinism
is what licenses reading a diff of two renders as a regression, so if it is
the one result nobody independently checks, every byte-for-byte claim
downstream inherits that.

Two things are needed, in order:

1. The driver must emit a machine-readable artefact —
   `harness/determinism/out/DETERMINISM.tsv`, one row per type: name,
   verdict, byte size of pass A, byte size of pass B, and the differing-pixel
   count where the two disagree. Today the verdict exists only as a line of
   printed text.
2. `validate/v37_determinism.R` reads it: all ten types present by name
   (`eml_census`), every one STABLE, both passes non-empty and equal in size,
   and the two logs free of Praat errors. Plus the guard that matters —
   **the two PNGs must be compared as files on disk by the validator itself,**
   not taken from the driver's own verdict, or the check is the harness
   grading its own homework a second time.

**DONE, 12 Aug 2026 — 108 checks.** Both halves. The driver emits
`DETERMINISM.tsv` (`name, verdict, bytesA, bytesB, diffPx`) through a single
`emit_row`, and the ten byte sizes it reports match §2's recorded baseline
exactly, so the artefact did not move when the driver learned to write it.

**The guard was verified the only way that means anything.** One byte in
`scatter_b.png` was XOR-flipped in a copied directory, leaving the file length
unchanged. The verdict column still said STABLE, both recorded sizes still
agreed, and every size check still passed — and v37 failed, because it reads
both files with `readBin` and compares them itself:

```
FAIL  v37  scatter -- the two PNGs are byte-identical, compared here
FAIL  v37  scatter -- driver verdict agrees with this file's own comparison
FAIL  v37  every type the driver called STABLE really is
```

That is the whole of §18 in one test: nothing except the independent
comparison could see it.

---

## 19. FIXED (12 Aug 2026) — the coverage question is per-artefact, not per-validator

§16b added `eml_census` and wired it into `v33` and `v35`, the two validators
that read an artefact they claim entirely. It was deliberately NOT swept
across the rest, and the reason is worth writing down so nobody "finishes"
the sweep mechanically.

Most validators are scoped to a subset ON PURPOSE. `v27` reads the 39-row
stress artefact and asserts on ten cases because the file is about empty
frames. Demanding it account for all 39 would demand assertions it is not
for — and would have hidden §17 behind a green check rather than surfacing
it.

So the unit of the coverage question is the ARTEFACT, across every validator
that reads it: *for each thing a driver renders, is there some authored check
that names it?* Answering it needs a registry of which validator claims which
cases. `validate/REGISTRY.md` already exists and is the natural home.

**DONE, 12 Aug 2026 — `validate/coverage.R`, reported as `v38`, 26 checks.**

The map is **not written down**, and that is the design decision. A
hand-maintained validator-to-cases table would be one more list capable of
disagreeing with reality, which is the exact failure being guarded against.
Instead each validator calls `eml_claim()` with the same vector its own checks
loop over, as it runs, and `coverage.R` reads each artefact's population **off
disk itself** and compares. Both sides come from somewhere other than
`coverage.R`. A validator that stops asserting on a case stops claiming it in
the same edit.

Five artefacts are covered: `stress_out`, `legend_out`, `parity_out`,
`wrappers_out`, `determinism_out`. Three failures are distinguished, because
they are three different problems:

- a case rendered that **no validator claims** — §17, named in the failure;
- an artefact **no validator reads at all** — §18, the largest form of it,
  reported separately rather than as "everything is orphaned";
- a validator claiming a case that was **never rendered** — vacuous
  assertions, invisible from inside the file making them.

The failure message names the claimants, so "covered" reads as "covered BY
WHAT" rather than being taken on trust.

**Verified by reproducing the history.** Run the suite with `v36` absent —
the state the tree was actually in that morning — and v38 fails, naming the
unclaimed stress cases and reporting v27 as the sole claimant. Run it with
`v37` absent and it reports that `determinism_out` has no reader.

**And its own break test found a bug in it.** The third test — plant a
rendered case nothing claims — did NOT fail. `coverage.R` was reading the
repo default while the validators honoured their `EML_*` overrides, so the
claims came from the copy and the population from the original: two different
artefacts compared as one, reporting "covered" for precisely the case it
exists to catch. Fixed by resolving every path through the same override the
validator uses. A coverage check that silently compares two populations is
worse than none.

---

## 20. DONE (12 Aug 2026) — the script recorder is wired to the menu

The recorder has existed since 9 August: it buffers steps, renders a runnable
file and flushes it, and `eml-analysis.praat` and `eml-draw-procedures.praat`
both call into it. **Nothing switched it on.** `@emlRecordBegin` is what sets
`emlRecordActive = 1` and its only callers anywhere were two test files, so
the whole feature was capture hooks and no user could reach it.

### Not a checkbox on every form, and the reason is not mainly space

The obvious wiring is a "record this" boolean on each analysis dialog. It is
wrong twice.

It models the **wrong scope.** The recorder accumulates a SEQUENCE — begin, N
steps across different operations, one file. A per-analysis boolean cannot
express *record these four analyses and this figure into one script*, which is
the entire point, and twenty booleans that all have to agree with each other
is not a design.

And it costs a **row on twenty dialogs.** Measured: 46 `beginPause` dialogs
ship. Raw widget counts look alarming — the wizard at 338, graphs' "No Table
selected" at 210, Scatter column mapping at 65 — but those are branch-inflated
and the honest per-pass figures are much smaller (the wizard has 35
unconditional rows; most column-mapping dialogs 3 to 6). Only 11 of the 46
have no branching at all. Praat gives `beginPause` no scrollbar, and §2k's
export dialog already showed what over-running looks like: the OK button
painted over the output.

### Two menu commands, and the state is an object

`Start recording script` and `Save recorded script...`, registered in
`setup.praat` under a new `-- eml record --` separator. Two lines there, and
**no row on any dialog.**

The mechanism is a fact about Praat rather than a trick. A script run from a
menu ends and takes every variable with it — `emlRecordActive` and
`emlRecordBufferId` are gone before the next analysis starts. The Objects
window is not: it belongs to the running instance. So the buffer Table
*is* the state, and `@emlRecordInit` re-attaches to it:

```praat
nocheck selectObject: "Table emlRecordBuffer"
```

Measured 12 Aug 2026 on 6.6.30: this re-attaches by name, and when the object
is absent it leaves nothing selected and raises no error — exactly the test
wanted. There is no flag file and no preference key, so **nothing can drift
out of agreement with the data**: the switch and the buffer are one object.

Consequences, stated rather than hidden. The buffer is visible in the user's
Objects window and deleting it ends the recording — which is a reasonable
meaning, and the start dialog says so. And it is **GUI-only**: `praat --run`
starts a fresh process per script, so a recording cannot span headless
invocations. Recording is a GUI feature; a harness must drive one session.

### Table selection across menu commands — the question this raised

Asked by the author before implementation, and it was the right question. The
old behaviour: the FIRST source wins for the header, and a later step on a
different object raised `emlRecordSourceChanged`, which put this in the file:

> `# NOTE: later steps in this session ran on a DIFFERENT object.`
> `# Running this file against one Table will not reproduce them.`

Honest, and useless. That was designed when recording lived inside ONE wrapper
invocation, where switching objects was exceptional. Under session recording
it is ordinary — an ANOVA on one table, a correlation on another — so the
warning would have fired on most real sessions and the emitted script would
have been broken exactly when the feature was most useful.

**The source is now carried per step** (a new `source` column on the buffer),
and a session that used more than one object gets a **table manifest** at the
top — the author's design, and better than the inline select first built:

```praat
# Name your tables here for this recorded workflow.
# Edit a name to run the same workflow on other data;
# nothing below this block names an object.
table1$ = "voiceA"   ; steps 1 (analysis), 3 (draw)
table2$ = "voiceB"   ; step 2 (analysis)
```

and each step selects through it:

```praat
# --- Step 2 (analysis) ---
selectObject: "Table " + table2$
table = selected ("Table")
```

**Why a block and not a select per step.** Both produce a script that runs;
only one can be EDITED. Re-pointing a recorded workflow at next month's data
is the main thing anyone will want to do with the file, and that has to be one
visible place near the top rather than a hunt through the body for every
mention of an object. The body never writes an object name.

Each line carries an inline note of the steps that used it, so the manifest
also answers "what was this table for" without reading the whole file.

**A single-table session emits no manifest and no selects** — the contract it
has always had, run it with that Table selected, and verified byte-for-byte.

**`;` INLINE, NEVER `#`.** Measured 12 Aug 2026 on 6.6.30: a trailing `;`
comment after code parses, a trailing `#` does not —
`table2$ = "voiceB"   # step 2` fails with `Error: Unknown symbol: « "voiceB"   #`.
The manifest is the only place an emitted file puts a comment beside code.

**The emitted script was replayed, not just read.** Two ANOVAs recorded across
two invocations on two tables, then the emitted body run verbatim against
freshly built objects: step 1 reported groups x/y at means 63.00 and 66.00
(voiceA), step 2 reported p/q at 225.00 (voiceB). Each step landed on its own
table.

One defect found that way and not by reading the diff: removing the old
unconditional `table = selected ("Table")` left a single-source script whose
every step used `table` and where nothing assigned it. Caught by running one.

**The one ambiguity, detected where it is knowable.** The emitted script
selects by NAME, and two Tables sharing a name make that ambiguous: measured
12 Aug 2026, `selectObject: "Table vt"` with two such Tables silently picks the
MOST RECENT. At record time the id is known so the collision is visible; in the
emitted file it is not. `@emlRecordSource` now counts Tables sharing the name
and the renderer warns.

### Verified

- both new wrappers parse; the wrapper harness went 26/26 → **28/28**
- **the census caught them by name before the inventory was updated** —
  `orphaned entry point: eml-record-save.praat, eml-record-start.praat`. §16b's
  guard firing on real new work rather than a planted defect.
- a three-invocation, two-table session driven end to end: re-attach found the
  buffer each time, and the emitted script selects `voiceB` at step 2 and
  `voiceA` again at step 3
- single-table session emits no selects; duplicate-name session carries the
  warning
- phase1 **357/357**, stress 39/39 with **no figure and no number moved**,
  determinism 10/10, parity 14/14, suite **9356/9356**

### Two rulings, 12 Aug 2026, after the first cut

**ONE OBJECT TYPE WAS BAKED IN, AND THAT WAS A DEFECT IN WAITING.** The plugin
accepts a **Table, a TableOfReal and a Matrix** — the graphs form's own
`@emlDetectContext` branches on all three — and the recorder wrote
`selected$ ("Table")` and emitted `selectObject: "Table " + name$`. A recorded
Matrix workflow would have produced a script that could not select its own
data.

Fixed with a fact rather than a branch: **`selected$ ()` with no argument
returns `"Type name"`** — measured on 6.6.30, `Table vt`, `Matrix spec`,
`TableOfReal tor` — and that whole string is what `selectObject:` takes back.
So the recorder never asks what type it is holding, and a fourth type needs no
change. The manifest carries the type in the string:

```praat
data1$ = "Table voiceA"       ; step 1 (analysis)
data2$ = "Matrix spectrum"    ; step 2 (analysis)
data3$ = "TableOfReal means"  ; step 3 (analysis)
```

The emitted working variable is `data`, not `table`, for the same reason.
`object` was the obvious name and **is reserved** — Praat's `object[]` syntax
makes `object = selected ()` fail with *After "object" there should be "(" or
"["*. Measured, not assumed.

**STANDARDISED ON ONE FORMAT.** Author ruling: the manifest is emitted even
when a session used a single object, so `data1$` and the usage note are always
there. A reader who learns the format on one script then meets a second one
with a different shape has been given two things to learn for no gain, and the
single-object script gains the property that makes the block worth having —
one visible place to re-point the workflow at other data.

**Every step now selects**, not only where the object changes. Selecting on
change is a bet that nothing between two steps disturbs the selection, and
that bet has already lost once here: `removeObject:` leaves NOTHING selected,
which is how six disclosure cases died on 11 Aug. Two idempotent lines per step
buys immunity from the whole class.

**Verified by replay across all three types.** One recording over a Table, a
Matrix and a TableOfReal, then the emitted body run verbatim: the ANOVA
reported groups x/y at 63.00 and 66.00 from the Table, and the final step left
`n = 5`, the TableOfReal's column count. Each step reached its own object.

Three phase1 assertions pinned the old contract and failed, correctly. They
were rewritten to pin the new one — including `no step selects a hardcoded
object type`, which is the assertion that would have caught the original
defect. phase1 357/357 → **361/361**.

Still open and untouched by this: §8. The emitted script cannot re-run
headless, because the wrappers use `beginPause:`. The author has ruled that
acceptable for now.
