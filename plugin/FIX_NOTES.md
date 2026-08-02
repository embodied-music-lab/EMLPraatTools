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
