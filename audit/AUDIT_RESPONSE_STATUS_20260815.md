# Audit response status — 15–16 August 2026

Ian Howell — Embodied Music Lab — GPL-3.0-or-later

Checklist of record for the 14 August stress-test round (`FINDINGS_MACHINE.json`,
41 rows) and for the two batches of rulings that followed. This file states what
closed, what is open, and — where it matters — what closed it, so a reader can
check the claim rather than take it.

Suite: **11,786 / 11,786, 0 failed, exit 0**, Praat 6.6.30, 72 validators.

---

## Batch one (15 August) — all closed

| # | Ruling | Closed by |
|---|---|---|
| 1a | Adjustment field off the parametric arm | v61 |
| 1b | Figure states Tukey's own family-wise control | v66, extended by v69 |
| 2 | Version floors are two contracts, not a discrepancy | v54 header |
| 4 | Recording buffer reads as load-bearing | v58 |
| 5 | Converted data columns numbered by SOURCE index | v63, v64 |
| 6 | No raw double reaches the Info window | v64, v65, v66 |
| 7 | No y-axis-name / tick collision | v62, v66 |
| 8a | Converted Tables accumulate | v63 |
| 8b | Stereo channel Sounds accumulate | v62 |
| 9 | Column names into the editable header block | v58 |
| 10a | A recorded auto axis replays as auto | v66, v67 |

---

## Batch two (16 August) — all closed

**1 — the one-bin Spectrum draws what it can.** A range holding exactly one bin
rendered a full frame with zero ink, and the bin not drawn held the peak of the
tone. Now a stem to the frame floor; zero bins stays empty, deliberately. The
trap was the dB conversion: the obvious `10*log10((re²+im²)/4e-10)` is **10.32 dB
low**, because Praat's `Draw:` plots spectral *density* — verified against
`To Ltas (1-to-1)` at five bin widths, then pinned in pixels against Praat's own
two-bin output. Reachability scales with 1/duration, so a 0.15 s token has 5.4 Hz
bins and any zoom under ~11 Hz emptied the frame. **The same defect was found at
`@emlDrawLTAS` and is more reachable still** — an Ltas bin width is the bandwidth
the caller chose, not 1/duration, so a 100 Hz window does it at any recording
length. Fixed the same way.

**2 — a recorded auto axis offers `0.0 to 0.0` in the editable block.** Both
halves. The form was destroying the evidence before the recorder could see it,
converting auto into explicit ahead of the draw on two paths; it now publishes the
untouched request. Worth recording: **the published pair is not one variable.**
A waveform is handed `ampMin/ampMax`, a spectrum `powerMin/powerMax`, a violin
`valueMin/valueMax` — publishing `valueMin` for a waveform would have put an
amplitude range in a slot the amplitude dialog never showed. The publication is
type-dispatched and all 13 types are driven with distinct sentinels.

**3 — batch voice analysis is registered**, menu entry 56, with the GUI drive the
stress-test session made a condition. Checked against the PraatGen corpus.

**4 — skewness and kurtosis are in the tidy vocabulary**, closing the asymmetry
where single-column normality exported them and multi-column lost them.

**5 — the stale oracled capture is regenerated**, and this was the delicate one:
`v03` asserts the printed p against R at `tol = 5e-30` *because a plugin that
floored it to zero would otherwise pass*. Tolerances were re-derived from the new
rendering rather than carried over.

**6 — the failing dev test is fixed at the expectation, not the message.** F5
asserted the too-few-complete-cases error verbatim; we had deliberately enriched
that message under NEW-G6-1 so it names the exclusion rather than reading as a
data shortage. Now an invariant substring plus a separate assertion that the
disclosure is present, so the next wording improvement does not break it.

**9 — display leaks in active paths.** The earlier "7 sites in the form" were
already closed by the 15 Aug sweep; the live one was the legend-panel ellipsis
note. `@emlCheckPlausibility` has **zero callers anywhere in the plugin** and is
therefore not an active process — see below.

**10 — the exact p tail is bounded to 3 significant figures.** The tail itself
stays: flooring at .001 flattens 5.8e-07, 2.1e-13 and 3.0e-04 into one string
nine orders of magnitude apart, which is D28/D35.

**11 — bracket-layout figures disclose their post-hoc test and correction**, on
the ggstatsplot and SPSS precedent. The two arms say different things: the
parametric arm states Tukey carries its own family-wise control, the nonparametric
arm names the method the user chose and claims nothing about it.

**12a — `@emlReportAlpha` keeps its precision escalation, and now says why.**
Alpha is a *criterion*, not a statistic; capping at 4 decimals would print a
threshold of .0001 as zero. Pinned so a future display sweep has to argue with it.

**12b — the RM-ANOVA warning string is split.** One variable was printed *and*
exported, two destinations with opposite rules, so formatting it would have
silently edited an exported value. The exported string is proven byte-unchanged.

---

## Open — needs a ruling

**A. The axis publication is session-scoped and escapes the form.** Praat cannot
unset a variable, so once the form publishes the request it lives for the process.
`eml-draw-qq.praat:259` calls `@emlDrawScatterPlot` with `0, 0, 0, 0` and no form;
after an EML Graphs draw at 0–100 in the same session, a recorded Q-Q step would
carry 0–100. Closing it needs a validity flag read by `@emlRecordAxisRequest`
(`eml-record.praat:1716`). It could not be half-fixed: the contract is
both-or-neither, and setting the pair to 0/0 on exit would be worse, because 0/0
*is* the auto sentinel.

**B. A legend-bearing figure records two draw steps.** `@emlGraphsDrawWithLegendRoom`
rewinds the CSV collector between passes but there is no `emlRecordMark` /
`emlRecordRewind`, so the emitted script says `steps 1 (draw), 2 (draw)` and its
resolved-range note names the **discarded** first pass (195..235) while the figure
was drawn at 195..275. Same shape as NEW-G8-3, in the record rather than the export.

**C. A two-group bracket figure names no test anywhere on it.** Both two-group arms
of `@emlBridgeGroupComparison` compose an omnibus string and neither sets
`annotTextN` — only the k≥3 arms do — so the form has no line to route into the
corner box. Whole-figure OCR of a Welch drive finds a bracket, `***, d = -6.08`,
and no test name. This is exactly the defect ruling 11 closed, one arm further
down. Not repaired, because it moves figures the ruling did not name and the
remedy is a choice: set `annotTextN` on the two-group arms, or give them a caption
of their own stating one comparison and no adjustment.

---

## Open — no ruling needed, just work

**D. `@emlCheckPlausibility` is dead code** — `eml-graph-procedures.praat:4823`,
three `fixed$` calls into `appendInfoLine`, zero callers. v68 pins the caller count
at 0, so wiring it up turns v68 red until someone argues for it. Either wire it or
retire it; it should not sit in between.

**E. v66 carries the first-ink trap** at `:633-636` and `:547-549`, asserting
`first_ink_px > 0`. That measurement moves the *wrong way* for a clipped element —
the same trap that was found and rebuilt elsewhere this week.

**F. `validate/REGISTRY.md`'s per-script narrative stops at v38.** Thirty-four
validators — v39 through v72 — are absent from the document that describes itself
as "the full reference: what every script covers". The counts lint is clean because
it checks totals, not enumeration. This is documentation debt, not a defect, but it
is larger than it looks and should not be closed by appending one line for v72.

**G. `harness/walks/gridmode`'s committed evidence does not reproduce, and it is
live.** Found while re-driving after the menu re-measure, and it is *not* caused by
any change this week — a counterfactual against `0fdc21e^`'s plugin gives the
identical wrong result. Two problems stacked. The documented `GEOM=1400x1600x24`
is required: at the rig default of 1280x900 the Scatter form runs off-screen and
`gbtn` finds zero buttons. At the correct geometry the walk completes and reports
*"accepted: Draw proceeded, no error dialog"* — while setting the **wrong
controls**: `gridlineMode: 1` where `SCAT_ITEM=4` intends 4, and `outputDPI` moved
1 → 2. `walks/gridmode/walk.sh:70 GRID_SCATTER=13` is a widget ordinal whose
comment no longer matches the rendered page.

This is the same class as the menu-coordinate drift — a positional address that
silently outlives the layout it was measured against — and it exits 0 while
reporting success, which is the part that matters. Committed evidence was left
untouched (scratch `OUT` throughout) so the finding stays visible.

**H. The 86 stale remote files** still need a real `git push`; the upload form only
adds.

**I. PKB drift** — `pkb/eml-batch-process.txt` is at 1.1 with 3 procedures against
the plugin's 1.2 with 7. Deferred by author ruling until the plugin work settles.

**J. The unification** — graphing-door statistics onto shared machinery. Ruled to
be the last thing done. Both engines already agree numerically, so it carries no
risk of changing a number, and the audit's engine-agreement measurements are its
free regression baseline.

---

## Not a defect, recorded so it stops being re-filed

**The two version floors are two contracts.** PraatGen's measured floor is 6.4.39
and its §S15A requires a generated script to warn and never refuse — the user owns
the result and their Praat is whatever it is. This plugin declares 6.6.30 and
refuses, because every capture under `evidence/info/` was produced on that build:
running lower would produce output whose banner claims a validation that does not
exist for that build.

**The environmental flake seen under six concurrent agents.** Two shadow-tree runs
had a Praat leg exit with a zero-byte log, no leg marker and no PNG, producing
spurious reds; identical re-runs were clean. Load contention on a two-core box, not
a defect. The *intended* reds were stable in every run.
