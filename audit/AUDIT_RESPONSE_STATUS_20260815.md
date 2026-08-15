# Audit response status — 15 August 2026

Ian Howell — Embodied Music Lab — GPL-3.0-or-later

Checklist of record for the 14 August stress-test round (`FINDINGS_MACHINE.json`,
41 rows) and for the ten rulings and change orders of 15 August. This file states
what closed, what is open, and — where it matters — what closed it, so that a
reader can check the claim rather than take it.

Suite at the time of writing: **11248 / 11248, 0 failed, exit 0**, Praat 6.6.30.

---

## The 15 August rulings

| # | Ruling | State |
|---|---|---|
| 1a | Adjustment field removed from the parametric arm | closed — `eml-graphs-form.praat`, v61 |
| 1b | Annotated figure states Tukey's own family-wise control | closed — `eml-annotation-procedures.praat`, v66 |
| 2 | Version floors: two artefacts, two contracts, no change | closed — v54 header corrected |
| 3 | Skewness/kurtosis into the tidy vocabulary | **open**, see below |
| 4 | Recording buffer reads as load-bearing | closed — `emlRecording_DO_NOT_REMOVE`, v58 |
| 5 | Converted data columns numbered by SOURCE index | closed at all three doors — v63, v64 |
| 6 | No raw double reaches the Info window | closed in the five owned files — v64, v65, v66 |
| 7 | No y-axis-name / tick collision | closed at all nine sites — v62, v66 |
| 8a | Converted Tables accumulate | closed — v63 |
| 8b | Stereo channel Sounds accumulate | closed — v62 |
| 8c | One-bin Spectrum draws an empty frame | **open — needs a ruling** |
| 9 | Column names lifted into the editable header block | closed — v58, proved by retarget drive |
| 10a | A recorded auto axis replays as auto | closed — `@emlRecordViolin`, v66 |
| 10b | An explicit range emitted into the editable block | **open**, see below |

---

## Open, with what each one needs

### Ruling 3 — skewness and kurtosis in the tidy vocabulary
Both halves sit in files that were not in any agent's ownership this round:
`eml-result-writer.praat:109` (the whitelist) and `eml-analysis.praat:4481-4492`
(the declaration). v64 **measures** the asymmetry live and prints the repair
rather than asserting it, so the suite is green either way. Measured today:
multi-column tidy carries `term, statistic, p.value, method`; single-column
glance carries `skewness, kurtosis`. v64 asserts the *premise* — single-column
must keep them — so a "fix" that deletes them from glance goes red.

The hazard on the way in, recorded in `validate/REGISTRY.md` and worth repeating:
**the tidy vocabulary is a WHITELIST walked by `@eml_orderedCols`, and a column
that is not in it is silently dropped.** An earlier attempt at this shipped a
file containing only `term` and `method`.

### Ruling 8c — the one-bin Spectrum
Measured twice, independently, on different fixtures. A Spectrum whose x-range
holds exactly one bin draws a titled, labelled, gridded, tick-marked frame with
**zero ink inside it**. The bin not drawn holds the peak of the tone (90.4 dB on
one fixture, 81.9 on the other). Two bins in range draw normally. Zero bins is
also empty. Mechanism: Praat's `Draw:` joins bin points with segments, and one
point is no segment — the peak is on the axis and not on the paper.

Widening the range is ruled out by NEW-G8-1, which v62 §3 already asserts. The
choice is between drawing a stem or marker and refusing with a message, and it
is a UX call. Site: `@emlDrawSpectrum`, `plugin/graphs/eml-draw-procedures.praat:1129`.

### Ruling 10b — an explicit range into the editable block
10(a) landed: a violin recorded with the axis on auto now emits `0, 0` and
rescales at replay. 10(b) needs `@emlRecordColumnSpec` to gain numeric slots and
`@emlRecordQuotedLiteral` to grow a numeric lift path with a "do not lift the
`0,0` sentinel" rule — a change to ruling 9's machinery, which should land with
it rather than beside it.

**And it has a prior question.** `eml-graphs-form.praat` converts auto into
explicit *before* the draw on two paths: the bracket-headroom block, and the
legend-room second pass. So even with 10(b) built, an annotated figure or any
legend-bearing type still records explicit literals for a user who chose auto.
The replay has no form and cannot do the two-pass widening, so:

> **auto** loses the legend room at replay; **explicit** freezes the frame.

Neither is right by default and the choice is Ian's.

---

## Not a defect, recorded so it stops being re-filed

**The two version floors are two contracts, not a discrepancy.** PraatGen's
measured floor is 6.4.39 and its §S15A requires a generated script to warn and
never refuse — the user owns the result and their Praat is whatever it is. This
plugin declares 6.6.30 and refuses, because every capture under `evidence/info/`
was produced on that build: running lower would not produce slightly-less-
validated output, it would produce output whose banner claims a validation that
does not exist for that build. Ruled 15 Aug; v54's header now carries it.

---

## Evidence freshness — open, and larger than it looks

Four committed artefacts still carry the pre-ruling-6 number format. Three are
inert; **one is load-bearing and must not be regenerated casually.**

Inert — no validator reads the affected strings:
- `harness/normality/out/pergroup/g03_severe_grouped.txt`
- `harness/parity/out/parity.log`
- `evidence/info/rp_r6_describe_info.txt:156` (`Skewness 0.000000000000004`)

Load-bearing:
- `evidence/info/wizard_rm3_rmanova_and_friedman.txt` — read by **v03** and
  **v04**. Its p-lines predate `@emlFormatP` and print the bare double
  (`p = 0.000…03`, 29 decimals). v03 asserts that number against R at
  `tol = 5e-30`, and its own comment records why the tolerance was hardened in
  August: *a plugin that floored this p to zero would otherwise have PASSED.*

The plugin today prints `p < .001  (3.0e-29)` — APA plus the exact tail through
`@emlFormatP`, which `@emlInlineP` still carries. So the capture is stale in
SHAPE while the precision v03 depends on is still produced, just in a different
position on the line. Regenerating it therefore means re-reading v03's and v04's
accessors against the new shape and re-deriving their tolerances, not re-running
a script. **That is its own piece of work and was not done at the end of this
session on purpose** — a bad regeneration here would quietly weaken the two
checks that exist to catch a floored p.

---

## Bookkeeping against FINDINGS_MACHINE.json

Spot-verified fixed-and-verified by the stress-test session on a fresh GUI
instance: `NEW-G10-2` (editor sentinel shim), `NEW-G12-1` (Matrix/TableOfReal
doors), `NEW-G7-2` (stereo, 220 L / 330 R reads 220 rather than the 110 GCD),
`NEW-G9-1` (standalone annotated Kruskal-Wallis, H / ε² / three Holm-adjusted
Dunn p's by exact-rank computation), `NEW-G1-1` (three-row normality export).

`D7` — the annotate-preset discard on beginner Draw — **is closed**, and the
gui_adv evidence says so in one integer: the Info report carries three analysis
sections where it carried two, because the beginner draw now annotates too.
v51's expectation moved 2 → 3 with the reason in its header.

The audit report's §7 documentation items are all superseded by the
delete-totals-from-prose lint, except the `gui.sh` coordinate note, which the
seventeen-entry re-measure closed.

---

## Still awaiting a ruling from earlier rounds

- **Batch voice analysis registration.** 255 checks across v52/v53/v54 where it
  had none. The stress-test session's standing recommendation is one
  savepaths-style GUI drive through the real dialog before the menu line returns.
- **The unification** — graphing-door statistics onto shared machinery. A
  project, not a fix. The audit's engine-agreement measurements stand as its
  regression baseline, and since both engines already agree numerically it
  carries no risk of changing any number.
