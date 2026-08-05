# EML Praat Tools — Correctness Fix Bundle
Date: 2026-07-21 · Applied by: Claude (Anthropic), for Ian Howell / EML
All fixes verified with Praat 6.6.30 (barren) against numpy/scipy references; graph edits additionally
reviewed by an independent adversarial pass (one regression caught and reverted — see L).

## A. Missing-data fix (audit C1/C2)
- stats/eml-analysis.praat (1.0→1.1): emlRunPairedAnalysis + emlRunCorrelationAnalysis now use
  row-wise complete-case extraction (@emlExtractPairedColumns), preserving pairing; analyzed n =
  complete pairs; "rows excluded for missing data" note added.
- stats/eml-extract.praat (1.3→1.4): new @eml_getGroupPairedData (complete-case within a group).
- scripts/eml-correlate.praat (3.2→3.3): per-group correlation uses @eml_getGroupPairedData.
  Verified: paired n=4/t=1.6977/p=0.1881, correlation n=6/r=0.9938 — match scipy.

## B. Graph fixes (audit H1, H3, M3, M4, L)
- graphs/eml-graph-procedures.praat (3.20→3.21):
  * H1 — box & violin quartiles now call the shared R-7 @emlQuartiles instead of nearest-rank
    floor(n*p) (which biased the median low and collapsed it onto the minimum at small n; figure
    now agrees with the describe table). Verified: emlQuartiles == numpy R-7 for n=3/4/5.
  * M3 — bar auto-range now tracks emlBarData_visibleMin so negative means aren't clipped at 0.
  * L — REVERTED (see below).
- graphs/eml-draw-procedures.praat (1.17→1.18):
  * H3 — grouped scatter no longer prints a false "R² = 0.000" for Spearman/Theil-Sen; R² emitted
    only for the OLS/Pearson line (guarded on annotCorrType$, mirroring the ungrouped path).
  * M3 — bar y-range routed through @emlComputeAxisRange with the tracked min; bar baseline
    decoupled from yMin (bars emanate from 0). Verified: neg bars axis -10..10; pos bars keep 0.
  * M4 — scatter axes use adaptive @emlComputeNiceStep roundTo instead of hardcoded 1. Verified:
    fractional data 0.45..0.55 now maps to axis 0.44..0.58 (was 0..1).
- graphs/eml-graphs-form.praat (1.8→1.9):
  * M3 — closes the annotated/bracket sub-case so negative-mean bars with brackets also floor
    correctly (positive data unchanged via the axis procedure's non-negative guard).

## L — B/W sprite (NOT fixed; reverted)
An initial attempt set sprite$ to an RGB grey in B/W mode. Adversarial review found sprite$ holds
PNG-filename STEMS (bw01..bw10), not colors, so the RGB string produced a non-existent filename and
silently disabled alpha transparency. The change was reverted. Properly fixing the cosmetic
grey-ordering mismatch requires mapping each computed grey to the nearest bwNN sprite (needs the
sprite grey-level table) — deferred, low priority.

---

## 5 August 2026 — D88, adaptive axis rounding

**Closes finding D88.** Verified by GUI drive on Praat 6.6.30, not by inspection.

`@emlComputeAxisRange` takes a `roundTo` argument that sets the granularity
the axis bounds snap to. Twelve of its seventeen call sites passed a literal
`10`, which fixes that granularity at ten units regardless of the data's
magnitude. Any measure whose full range is small relative to 10 was
compressed into the bottom of the panel.

Ten sites now derive `roundTo` from the data via `@emlComputeNiceStep`,
which is the same nice-number logic the gridlines already use:

- `graphs/eml-draw-procedures.praat` — `@emlDrawTimeSeries`,
  `@emlDrawTimeSeriesCI`, `@emlDrawSpaghettiPlot`, `@emlDrawBarChart`,
  `@emlDrawViolinPlot`, `@emlDrawBoxPlot`, `@emlDrawGroupedViolin`,
  `@emlDrawGroupedBoxPlot`
- `graphs/eml-graphs-form.praat` — both auto-range branches in
  `@emlGraphsWorkflow` (bar, and violin/box)

This is the same change made to the scatter path on 21 July under M4 in
section B above, which was applied there and not propagated. The comment at
the scatter site already named the failing case — "fractional data
(proportions, reaction times, jitter %)".

**Follow-up, same day: the propagation was completed to 15 of 17 sites.**
The two `@emlDrawF0Contour` sites and the waveform amplitude site
(`roundTo = 0.05`) are now adaptive too. The concern that adaptive rounding
would defeat the F0 minimum-span logic was unfounded: the 50 Hz and
12-semitone corrections run *after* the axis call and widen the result when
it is too tight, so a narrower derived range is corrected upward exactly as
before. On the 50 Hz span the derived granularity reproduces the previous
10 Hz.

**The two histogram sites keep their literal `5`.** Making them adaptive was
attempted twice and backed out both times, with the failures evidenced —
see finding D91. Frequency is a count, and while the derived bounds are
correct, the tick *labels* come from `@emlDrawAxes`, which takes no tick
constraint, so the axis ends up labelled in halves. Fixing it properly means
changing a procedure every draw path calls.

**Verification — two cases driven end to end through the GUI:**

| Input | Data range | Axis before | Axis after |
|---|---|---|---|
| `evidence/csv/demo_paired_input.csv`, jitter | 0.528 – 4.191 | 0 – 10 | 0 – 5 |
| `validate/redpath/r7_small_range_measure.csv`, contact quotient | 0.401 – 0.548 | 0 – 10 | ≈0.38 – 0.56, ticks every 0.05 |

Figures: `evidence/figures/d88_FIXED_spaghetti_jitter.png` and
`d88_FIXED_spaghetti_CQ.png`, against the pre-fix
`d88_spaghetti_axis_0to10.png`.

The contact-quotient case is the one that matters: on a 0–10 axis that data
occupied under 2% of the panel height.


## 5 August 2026 — F0 axis: minimum-span floors removed

The F0 contour axis enforced a minimum visible span: 50 Hz in hertz, 12
semitones rounded to 6 in semitones. Both are gone. The axis now follows the
data, and any extra room a figure needs comes from
`@emlComputeAnnotationHeadroom` at the annotation stage, which is where it
belongs — headroom is a property of what is drawn on the figure, not of the
unit on the axis.

**These floors were a workaround for the D88 granularity bug, not a
considered design.** The v1.15 note above records Bug #11 as "semitone
auto-range minimum span enforcement now uses direct 6-st rounding instead of
re-calling @emlComputeAxisRange. Prevents overshoot to ~30 st for
constant-pitch input." That overshoot was `roundTo = 10` applied to a
semitone axis: a near-constant pitch produced a tiny range that snapped out
to a 10-unit grid. With the granularity now derived from the data, the
overshoot cannot occur and the workaround has nothing left to prevent.

**Verified by driving `@emlDrawF0Contour` on a 220 Hz tone with 2.9 Hz of
drift:**

| Unit | Measured span | Axis | Ticks |
|---|---|---|---|
| Hertz | 220.040 – 222.960 (2.9 Hz) | 219.5 – 223.5 | 0.5 Hz |
| Semitones | same signal, ≈0.23 st | −12.05 – −11.70 | 0.05 st |

Under the old floors the hertz figure would have spanned roughly 195–245 and
the drift would have read as a flat line. The semitone figure shows no trace
of the Bug #11 overshoot.

Figures: `evidence/figures/d88_f0_steady_hz_2.9Hz_span.png`,
`d88_f0_steady_semitones.png`.

**One hard-coded pair remains in this procedure and is not a defect.** When
`Get minimum`/`Get maximum` return undefined — no voiced frames anywhere —
the axis falls back to 75–500 Hz or −36 to +6 st. There is no data to derive
a range from in that case, and an empty figure still needs an axis.
