# Open items — EML Stats & Graphs, road to 1.0.0

Kept in the repo on purpose: this file survives session loss. Update it
when an item is opened, changed, or closed. Newest ruling wins.

## Defects Ian has seen and reported (not yet fixed)

1. Inner box / gridlines don't line up. On Ian's Mac the drawn box is
   ~2-3% smaller than the gridline rectangle, so a regression line appears
   to overshoot the top. Measured in two of his EPS files; NOT reproducible
   on the Linux build here — gridlines and tick marks coincide exactly.
   Ruled out: font size at gridline time, theme re-run, the legend-room
   two-pass. Remaining hypothesis: platform font metrics (Praat computes
   margins from font metrics; macOS and Linux differ). Testable only on
   Ian's machine.
2. R-squared is reported twice in the scatter note.
3. The text wrapper breaks "label = value" across lines.
4. Subtitle text persists between runs, and is read without a guard.
5. "Erase page first" is not remembered between runs (form default is
   hard-coded to on).
6. Legend placement label should read "(when drawn)".
7. Recorder: stopping with nothing recorded does not stop. Ruled 19 Aug —
   stop must always stop and say plainly that nothing was written.
8. Recorder status messages clear the Info window. Ruled — they must append.
9. Recorder leaves a process table in the Objects window.
10. Recorder does not record creation of the demo table. Ruled 19 Aug —
    creation becomes a recorded step, split by source.

## Ruled, not yet built

- Recorder state publication (ruling of 19 Aug). The form publishes its
  complete display state; the recorder emits it ahead of each draw step;
  a validator pins three sets equal — seeded, published, emitted. Includes
  per-figure-type session-vs-replay legs and one mutation demonstration.
  Reason it matters: the form's annotation-style default and the replay
  default are different constants, so every recorded annotated scatter
  replays with a different significance decision than the session showed.
- Open sub-question, unruled: whether ~10 runtime bookkeeping globals get a
  written exclusion list in that validator.

## Test-coverage gaps to close

- No check drives any figure type through the form's own dispatch. This is
  why the scatter crash of 19 Aug shipped.
- Ledger rows owed: 19 tracked process files under harness/dialogheight;
  replay receipt lag in the vector-figure harness; two plugin versions can
  produce a truncated menu with no warning.

## From the 19 Aug audit — font geometry (class not yet closed)

The scatter is fixed and Ian confirms it. The CLASS is not closed. Still owed:

- The annotation block leaves the ambient font size at annotation size when
  it returns: its Reset block restores colour and line width but not size.
  Everything drawn after it in that figure is on a displaced rectangle.
  (A sibling procedure elsewhere in the same file restores size correctly —
  copy that.)
- Two bare `Draw inner box` calls bypass the wrapper: the coefficient forest
  plot, and the faceted-histogram panel loop.
- Full census: every site that sets an ambient size other than body size and
  does not restore it before the next coordinate command.
- A render-level validator that parses the saved figure and asserts the box,
  the ticks, and the plotted extremes all land on ONE rectangle, per figure
  type. Plus a mutation demonstration.

## From the 19 Aug audit — pitch canon, encoding, paths

- Pitch analysis parameters become canonical everywhere, including dev tests
  and the code the recorder emits. Four sites in the graphs layer change one
  setting; one procedure owns each parameter set; the emitted string is
  generated from the same source as the executed call. NOTE: this shifts a
  reported mean by roughly 1 Hz on a short token — a user-visible change.
- CSV and report files get an ASCII fold at the file boundary. One non-ASCII
  character makes Praat rewrite the whole file in UTF-16, which is unreadable
  to R, pandas and Excel.
- The duplicate-filename loop is replaced by the shared unique-path procedure.

## New from Ian, 19 Aug

- After Record is pressed, all objects are deselected. The recording's own
  table is never what the user wants selected.
- Driving ANOVA through to a violin plot in the wizard, Save offered only the
  data, not the image. Needs a sweep of every path that produces a figure.

## In flight right now

- Uncommitted: a guard in the graphs form so drawing from outside the form
  no longer aborts on an unset series-role variable.
- Line-chart verification re-drive: 10 of 15 legs green, 5 remain
  (long_titled, wide_titled, and the three recorder legs).

## Shipped but not yet on GitHub

- c70d183, the scatter crash fix. Ian has it locally as eml-crashfix.bundle.
  GitHub main is at 40f2d2e until he pushes.
