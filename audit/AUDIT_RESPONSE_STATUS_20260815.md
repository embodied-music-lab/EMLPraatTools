# Audit response status — 15–16 August 2026

Ian Howell — Embodied Music Lab — GPL-3.0-or-later

Checklist of record for the 14 August stress-test round (`FINDINGS_MACHINE.json`,
41 rows), for the two batches of rulings that followed, and for the 16 August
handoff (`handoffs/HANDOFF_FOR_OPUS_2026-08-16.md`,
`handoffs/SOL_EVAL_RESPONSE_2026-08-16.md`). This file states what closed, what
is open, and — where it matters — what closed it, so a reader can check the
claim rather than take it.

Suite: **12,400 / 12,400, 0 failed, exit 0**, Praat 6.6.30, 78 validators.

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

Ten rulings, closed as recorded in the 16 August commits: the one-bin Spectrum
draws a stem to the frame floor and the same defect at `@emlDrawLTAS` — more
reachable, because an Ltas bin width is the bandwidth the caller chose rather
than 1/duration; a recorded auto axis offers `0.0 to 0.0` in the editable block,
with the publication **type-dispatched** across all 13 graph types, because
publishing `valueMin` for a waveform would have put an amplitude range in a slot
the amplitude dialog never showed; batch voice analysis registered as menu entry
56 with the GUI drive the stress-test session made a condition; skewness and
kurtosis in the tidy vocabulary; the stale oracled capture regenerated with
tolerances **re-derived** rather than carried over, because `v03` asserts the
printed p at `tol = 5e-30` precisely so that a plugin flooring it to zero would
fail; the F5 dev test fixed at the expectation rather than the message; display
leaks in active paths; the exact p tail bounded to three significant figures
(flooring at .001 flattens 5.8e-07, 2.1e-13 and 3.0e-04 into one string nine
orders of magnitude apart); bracket-layout figures disclosing their post-hoc
test; `@emlReportAlpha`'s precision escalation kept, because alpha is a
*criterion* and capping at 4 decimals prints a threshold of .0001 as zero; and
the RM-ANOVA warning string split, because one variable was printed *and*
exported — two destinations with opposite rules.

---

## Batch three (16 August handoff) — all closed

**P0 — the one-tailed p is a fixed-direction test.** The parametric kernels
computed `.p = studentQ (abs (.t), .df)` for `tails = 1`: the smaller tail of the
*absolute* statistic, so swapping the two groups returned the same p both ways
and the test could not see the direction it claimed to test. Reproduced before
repair at `t = ∓2.5298, p = 0.0227` in both directions. The tail now comes from
the signed statistic — `studentQ` on 6.6.30 is the signed upper tail — and
`.pLess` is a second evaluation on the other side rather than `1 - .pGreater`,
because at a right tail of 5.6e-46 the subtraction returns exactly zero and
hands the reader a p of 0 for a test that has a perfectly good one.
`.pGreater`, `.pLess` and `.alternative$` are exposed as `@emlMannWhitneyU`
already exposed them, so `tails = 1` now means one thing everywhere in the
plugin, and four `@...Alt` entry points name the alternative in words.

Two-sided p is byte-unchanged in all five families and pinned against R at
1e-14 — that is the regression that mattered, since every registered menu path
passes `tails = 2` and nothing shipped ever printed the defective number.

Closed by **v73** (committed capture) and **v77** (driven live). The two are one
subject in two evidentiary shapes, and the population neither inherited from the
previous 72 validators is not a procedure or a data shape — v08, v12 and v18
already read all five families. It is a **relation between two runs**. Every
individual run looked correct and only the pair was wrong, so a suite built out
of per-run assertions was blind to it by construction.

Worth recording, because it is the sharpest methodological result of the round:
**inverting the direction of the repair goes red only against the R oracle.** The
mirror of a valid answer satisfies sum-to-1, satisfies the reversal exchange and
satisfies the doubling identity. A sign-reversal matrix on its own is not
sufficient evidence.

**Ruling A / change order 7 — axis publication is consumed once.** Praat cannot
unset a variable, so a published request lived for the process and
`@emlRecordAxisRequest` preferred it whenever it *existed*. Existence being
permanent, "some form ran earlier this session" was indistinguishable from "this
draw came from the form". Now a step stamp: the stamp carries the state because
the **pair cannot** — 0/0 *is* the auto sentinel, so a reset pair reads as a
published auto request. Closed by **v74**.

The stamp is re-taken at dispatch rather than only at publication, and that is a
departure from the literal ruling, driven rather than reasoned: the annotation
bridge records a step of its own between publication and draw, so a stamp taken
at publication names a step the draw will never be, and the figure would be
refused its own user's range — ruling 10(b) undone by the repair meant to
protect it.

Note what this class defeats. The leak needs **two draws in one process** with
only the first going through the form, and no rig in the tree performed that
sequence; every existing axis harness was green on a tree with the bug in it,
each for a reason of its own construction. And **no pixel moves** — the figure is
drawn on the axis the draw procedure resolves, whatever the recorder writes
down — so no image comparison could ever have seen it.

**Ruling B / change order 8 — one press of Draw, one recorded step.** The legend
two-pass rewound the CSV collector and left the recorder running, so one press
emitted the figure twice and the resolved-range note named the **discarded**
pass: 195..235 beside a figure drawn at 195..275. `@emlRecordMark` /
`@emlRecordRewind` are the twin of the CSV pair and name no legend and no pass.
Closed by **v75**, which asserts on the emitted script rather than the source,
because the obvious implementation passes a source check and fails: Praat
refuses to remove a Table's only row and `nocheck` in front of that refusal is a
skip, so a figure drawn as the first thing in a recording kept its discarded
pass in silence.

**Ruling C / change order 9 — every bracket-bearing figure names its test.** Both
two-group arms composed an omnibus string and set `annotTextN` on neither, so a
Welch drive left the session carrying a bracket, `***, d = -6.08` and no test
name. Closed by **v76**, whose subject is the invariant rather than the two arms:
it parses the bridge into a block tree and requires every site that writes a
bracket label to be **dominated** by an `annotTextN = 1`. That distinction is
measured rather than argued — moving the Welch arm's line inside its own
`if .useMatrix` satisfies an arm-scoped grep while the bracket path still names
nothing.

This was the third time this shape was repaired one arm at a time.

**D — `@emlCheckPlausibility` retired**, zero callers confirmed across the whole
repository. v68's pin was turned around rather than deleted: it asserted a caller
count, which a nonexistent procedure satisfies trivially, and now asserts absence,
so re-introduction goes red.

**E — v66's first-ink trap rebuilt**, and **v62's identical site with it**, so the
repository has one answer to this and not two. `first_ink_px > 0` is satisfied by
*any* ink, so it cannot see the element it names. Both are now anchored: the
element's own extent against an unmoved control, and its position against a
published shift, with the scale derived from the evidence rather than assumed.
The vacuity is measured, not asserted — across three deliberate defects the old
check passed on 11 of 12 leg-readings with the axis name provably in the wrong
place.

**F — `validate/REGISTRY.md` now describes every validator.** Forty were absent
from the document that calls itself the full reference. Each new row names the
population it covers and what that population contains that the earlier
validators exclude *by construction*.

**G — `harness/walks/gridmode` addresses controls by label.** It exited 0 reporting
success while setting `gridlineMode` 1 where 4 was intended and moving
`outputDPI` 1→2, because D11 took two widgets off the top of the Scatter page and
a positional address outlived the layout it was measured against. The walk now
refuses below the geometry it needs, sets by label, and asserts after each control
both that the named control renders what was intended **and that no other control
moved** — the second half is what caught Output DPI.

**Repository hygiene.** The manifest had been stale for twelve days —
`--check` was correct the whole time and nothing ran it, which is the entire
failure; it is now inside the suite, and the suite is inside CI. The include
checker reported 22 entry scripts with unresolved calls, 21 of them its own false
positives, which is the shape that teaches a reader to skip the report — and the
one true entry sat in that list the whole time: `@emlAssertFullViewport`, defined
in the graphs layer and called unguarded from the stats layer, unreached only
because thirteen wrappers pass `.offerFigure = 0`. Two dead documentation links
removed rather than filled. A CI workflow added.

Writing it disproved a front-door claim: all three documents said the suite needs
"R and nothing else — no Praat". Seven validators drive a real Praat and fail
without one, and the **barren** edition does not substitute. All three now say
what is true.

---

## Author ruling, 16 August — shipped files describe current behaviour

> Pre-release ruling — do not document internally-caught errors in shipped
> files. Shipped headers describe current behavior only; defect history lives in
> git.

Applied across `plugin/` in two sweeps: the `tails` deprecation notes named in
the ruling, then every ruling reference, finding ID, dated repair narrative and
procedure tombstone in the shipped tree — roughly 900 comment lines. Every
explanation of *why the code is shaped as it is* survives, rephrased into the
present tense, wherever the reason is a property of Praat or of statistics rather
than a history of this project: `fixed$` is not a fixed-precision formatter and
returns a bare `"0"` for exact zero; Praat cannot nest a procedure call in an
expression; Praat does not short-circuit `and`; `nocheck` is a skip rather than
an error suppressor; Praat will not remove a Table's only row; `Draw:` joins bin
points with segments and plots spectral density. A reader who deletes one of
those will reintroduce the problem.

No validator needed repointing for the second sweep: every validator that reads
plugin source does so through comment-stripped statements or greps for code. One
check in v77 was repointed during the first, and it deserves recording — it
pinned the *text of a deprecation note*, which is pinning the wrong thing. It now
asserts the absence of the old formula and the presence of the behaviour.

`plugin/FIX_NOTES.md` is untouched and needs a ruling — see below.

---

## Found while integrating, and worth more than a line

**Change order 8 shipped its new procedures unguarded.** `@emlRecordMark` and
`@emlRecordRewind` were called from the graphs form without the
`variableExists ("emlRecordLoaded")` guard every neighbouring call site carries,
breaking the recorder-is-optional contract: a probe died with
`Procedure "emlRecordMark" not found` before drawing anything. `harness/norecord`
cannot catch it — it does not include the form file. Caught by driving an
unrelated harness, not by any check. Fixed, and the 19 other artefacts came back
byte-identical, which is what proves the guard is a no-op when the recorder *is*
loaded.

**Committed harness evidence largely does not reproduce.**
`validate/tools/redrive_census.sh` re-drives every harness into scratch and
byte-compares. Of 34 harnesses and 2,093 artefact files: **9 reproduce**, 7
reproduce but are not byte-stable (clock or path), **15 differ**, 1 driver fails,
2 have no artefacts, 14 have no shell driver. This is not bookkeeping. In every
case examined so far the stale evidence was hiding something:

- **v61 attests a repaired defect as open.** It prints, today, that a violin
  recorded on auto emits resolved literals and "its replay stays frozen … every
  point off the page". Ruling 10a/10b landed; the tree lifts the pair into the
  header block and the replay rescales. Same shape as `harness/graphaxes`, whose
  committed `onebin_interior_ink 0` had a validator conditionally printing "THE
  ONE-BIN SPECTRUM IS STILL AN EMPTY FRAME — NOT repaired" out of evidence that
  had stopped being true.
- **v29 asserts 144 renders the tree has never been able to produce.** Two
  harnesses read `emlDrawLegend.swatchLeft`; those locals live in
  `@emlDrawLegendPanel`, and `@emlDrawLegend` has had no `swatchLeft` at any
  commit in this repository's history. The evidence was carried in from
  elsewhere. Neither section takes an env override, so the check can only ever
  read the committed copy.
- **v45 pins a naming contract the author replaced.** It requires the saved stem
  `e2e_demo_Violin_Plot`; the plugin has written a stamped stem since the
  14 August "one stamp per press" ruling, and the committed artefact predates it.

**`v42`'s artefact stopped reproducing on 15 August**, bisected to `7f62e75` by
re-driving 31 ancestors. Not a plugin defect: the D8 beginner override rewrites
placement 2 to 1 when `config_showAdvanced = 0`, and the fixture never set it —
so the "legend outside" case had stopped being drawn outside, and never reset
`valueMin/valueMax` between cases, so each case inherited the previous one's
widened axis. The fixture now sets advanced mode and resets per case, and the
drive **refuses to publish** an artefact whose asked-for placement differs from
the drawn one. The plugin's own claim held: with an outside legend genuinely in
effect there is one pass and no discarded render.

**No harness driver in this repository carries an execute bit** — all 60 are mode
`0644` in git, and two rigs exec'd a sibling script directly rather than through
`bash`. The documented invocation could never have worked on a fresh clone. One
of the two failed *quietly*, recording `NO_RIG` and exiting 0. This is finding P1
wearing different clothes: git records only the executable bit, and here the
absence of it is the defect.

**`harness/normality` has no validator at all.** Four of its files name
`validate/v32_normality_parity.R` as their consumer. No such file exists, and
nothing in `validate/` reads any of its 128 artefacts.

---

## Open — needs a ruling

**1. `plugin/FIX_NOTES.md`.** Under the ruling above this file is, front to back,
defect history in a shipped tree: 241 lines, ten sections, each one a version
bump with what was wrong and what closed it, keyed to audit finding IDs. It has
been there since the repository's first commit and one commit has ever touched
it. It was left alone because it is a deliberate long-standing artefact rather
than something this week wrote. Delete it, move it to `audit/`, or keep it as the
one sanctioned exception — and note that `plugin/README.md` points at it as "what
was wrong and what closed it", which is the only remaining defect-history
reference in a shipped file. Its byline also reads "Applied by: Claude
(Anthropic), for Ian Howell / EML", which is an attribution question independent
of the ruling.

**2. Which stale harness evidence to re-drive.** Recommended order, each with its
reason: **graphseams** first, because it is the one making the suite state a live
falsehood, and it must land *with* the v61 prose rewrite or the sentence
contradicts itself; **markers + patterns** next, one identifier fixed in each
harness before re-driving, 315 files for the smallest source edit in the list;
**gui_e2e**, one file and one validator line; **legend**, bundled with v32's seven
pinned ink constants so the suite is never red between commits; then
**savepaths** and **api_export**, where nothing claims on the changed fields but
the committed evidence *shows repaired defects as open*; then **edittable**.
Leave **normality** until it has a validator, leave the six pure-staleness
harnesses to whatever pass next touches them, and do **not** re-drive
**batchgui** — its three PNGs differ only where the scratch path is painted into
the image, which is a limit of byte-comparing a screenshot.

**3. The root `README.md` still reads "coming soon."** Raised in the Sol review
under release positioning, alongside vector export for the "publication-quality"
claim and the wizard's deterministic test-selector framing. Editorial, not a
defect — it needs the author's voice, not mine.

---

## Open — no ruling needed, just work

**PKB drift** — `pkb/eml-batch-process.txt` is at 1.1 with 3 procedures against
the plugin's 1.2 with 7. Deferred by author ruling until the plugin work settles.

**The 86 stale remote files** still need a real `git push`; the upload form only
adds.

**The unification** — graphing-door statistics onto shared machinery. Ruled to be
the last thing done. Both engines already agree numerically, so it carries no
risk of changing a number, and "one result through every door" is adopted as its
acceptance test rather than as a separate project.

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
