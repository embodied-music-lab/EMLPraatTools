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
deterministic data so only the furniture moves:

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

## 2. OPEN — draw procedures disagree on how they expose their resolved axes

| types | convention |
|---|---|
| 8, 10, 11, 12 | `.axisXMin` / `.axisXMax` / `.axisYMin` / `.axisYMax` |
| 5, 13 | `.xMin` / `.xMax` / `.yMin` / `.yMax` |

Every caller outside the form has to know which convention its graph type
follows, and choosing wrong fails at RUN time with a bare `Unknown variable:`
rather than at parse time. Hit while writing the sweep fixture.

The fix is to publish both names from every draw procedure — additive, so no
existing caller breaks — and then migrate the annotation bridge and the form's
post-dispatch block onto the `axis*` spelling. Cheap, but it touches all six
procedures plus two consumers, so it belongs in the push and not before it.

---

## 3. OPEN — the categorical x-axis labels have no off switch

`Show axis values` (None / Both / X only / Y only) is in the Advanced block of
every graph type and is honoured on continuous axes.
`@emlDrawCategoricalXAxis` never reads `emlShowAxisValuesX`; it draws
`emlCatLabel$[]` unconditionally. So on the six types with a categorical x axis
the control is present in the dialog and silently does nothing.

Author has seen this and said the current behaviour is fine, so it is recorded
rather than scheduled. If it is ever wired up, the measurement has to be gated
too — `@emlFitCategoricalLabels` sets rotation and overhang, and both
`@emlDrawCategoricalXAxis`'s extent report and the form's matrix-gap budget
(`graphOverhangInches`) spend that reservation. Suppressing the labels without
zeroing the measurement reserves space for text that is never drawn.

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
including the red-path input. Current baseline: **8221 checks, 0 failed**
(`Rscript validate/run_all.R`), 39/39 stress cases
(`bash harness/stress_graphs.sh` — 29 OK, 10 expected `BLANK_FRAME_ABS`),
disclosure harness clean across 28 combinations, phase1 294/294.

Not yet covered by an R script: the legend placement geometry above is
asserted by `validate/v32_legend_geometry.R` (4117 checks), but the four
non-categorical types were verified 9 Aug by direct pixel measurement in this
session and those measurements are **not** yet in v32. That is the first
item of the push.

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

## 10. OPEN — the recorded workflow has no input file

The orchestrators are handed a `tableId`, never a path, so nothing in the
chain registers the input. The emitted script therefore carries a correct
analysis, correct numbers, a correct call line, and **no statement of what
data any of it ran on**.

The renderer names the gap rather than omitting it — the emitted file opens
with `INCOMPLETE -- NO INPUT FILE WAS RECORDED` — and the test asserts that
notice is present. Closing it means registering the path at the layer that
opens the file, which is the next increment of the feature.
