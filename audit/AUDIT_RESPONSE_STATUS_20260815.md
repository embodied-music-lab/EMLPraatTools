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

---

## The findings ledger schema — 17 August 2026

Author's history-migration change order of 16 August, part 1. Every row of the
findings ledger carries three fields, and the schema applies to all future
findings as well as the existing ones:

- **`fixedBy`** — full git commit hash of the fix. `""` until fixed.
- **`pinnedBy`** — validator ID(s) pinning the corrected behaviour (e.g.
  `"v66"`), or a dev-test ID where the pin lives in `plugin/dev/tests/`. `""`
  means UNPINNED.
- **`status`** — `open` | `fixed-unpinned` | `closed`. **`closed` requires BOTH
  `fixedBy` and `pinnedBy` non-empty. No other path to closed.**

`status` is mechanical from the other two rather than editorial, so the mapping
is total and a row's status is never a matter of opinion:

| `fixedBy` | `pinnedBy` | `status` |
|---|---|---|
| empty | (anything) | `open` |
| set | empty | `fixed-unpinned` |
| set | set | `closed` |

The distinction the schema exists to force is the one this document has spent
two rounds on: a defect that was repaired, and a defect that was repaired *and*
whose repair something would notice the loss of. `v61` attested a repaired
defect as open for a week; `v29` asserted renders the tree has never been able
to produce; `v68`'s pin asserted a caller count, which a nonexistent procedure
satisfies trivially. In every one of those the ledger would have said "closed"
and been wrong in the same direction. A **fixed-unpinned** row is not an
embarrassment — it is the honest state for most repairs, and the list of them is
the deliverable.

### Commit convention, on the record

From now on the subject line of any fix commit **begins with the finding ID it
closes**:

```
NEW-G5-2: the axis publication is spent when it is read
```

A commit closing more than one finding **lists every ID**:

```
NEW-G5-2, NEW-G8-3: ...
```

This is what makes `fixedBy` recoverable by search rather than by memory. The
41-row backfill below is blocked precisely because no commit in this repository
carries a finding ID in its subject line, and the archaeology has to be done by
behaviour instead.

### Enforcement

`validate/tools/check_findings_schema.py` — stock Python 3, no packages, exit 0
iff clean. It asserts that every row carries all three fields as strings, that
`status` is one of the three literals exactly (spelling included — a consumer
switching on `fixed_unpinned` silently drops the row into its default branch),
that no row is `closed` without both fields, and that every row's `status`
agrees with what its two evidence fields entail. `fixedBy`, when set, must be a
full 40-character hash **and must name a commit that actually exists in this
repository** — the check that catches a plausible-looking hash carried in from
somewhere else.

Two vacuity guards, because a checker that passes when it has nothing to check
is the failure this repository has now hit twice — the manifest whose `--check`
was correct for twelve days while nothing ran it, and every pin satisfied by the
absence of the thing it named. **A missing ledger is a FAILURE, not a skip**, and
**an empty ledger is a FAILURE**: zero rows satisfy every per-row rule vacuously.

Break-tested 17 August, four deliberate corruptions, each red and each restored:
a row with `pinnedBy` deleted; `status` spelled `fixed_unpinned`; a `closed` row
with `pinnedBy` emptied (reds twice — the explicit rule and the entailment); and
a zero-row ledger.

---

## CLEARED — the ledger was never committed here, and was landed on 17 August

**The 41-row backfill was blocked from 15 to 17 August because
`FINDINGS_MACHINE.json` was not in this repository, and never had been.** That
blocker is now cleared and the section is kept rather than deleted, because the
next reader will otherwise find three days of status entries that talk about a
checklist of record the repository did not hold, and no explanation of why.

What was established on 17 August, before the file arrived, and all of it still
stands:

- the ledger was absent from the working tree (`audit/` and repository-wide);
- and absent from **every commit on every ref** — `git log --all
  --diff-filter=A` and a full `--name-only` sweep of all 247 commits. The only
  JSON ever committed to this repository up to that point was
  `plugin/dev/tools/procs.json` and `plugin/dev/tools/theilsen_margin_rows.json`;
- and absent from both git bundles (`EMLPraatTools-2026-08-05-audit.bundle`,
  `EMLPraatTools-orchestrator-validation.bundle`) and the `push2`–`push38`
  output staging directories, all of which predate 14 August;
- and absent from the scratch and handoff trees under the working account.

The ledger was not lost. **The 14 August delivery had never been landed in this
repository at all.** `handoffs/HANDOFF_FOR_OPUS_2026-08-16.md` §"Reference Files
for Implementation" names seven files as "included in this delivery"; three were
present and four were not.

**Landed 17 August 2026,** from that delivery, as untracked files in `audit/`:

| File | What it is |
|---|---|
| `FINDINGS_MACHINE.json` | the 41-row checklist of record — the file the backfill needed |
| `EML_AUDIT_REPORT_2026-08-14.md` | the full stress-test report, §1–§10 |
| `AUTHOR_RULINGS_ADDENDUM_2026-08-14.md` | the three rulings of 14 August |
| `handoffs/LETTER_TO_OPUS_2026-08-15.md` | the five rulings and ten change orders of 15 August |

The three siblings matter as much as the ledger for reading it: the ledger rows
carry an `id`, a `severity` and a one-line `mechanism` and nothing else, so
`NEW-G8-2` is a title until §4.5 of the report says what a one-sided range does,
and `D5` is a letter until §5 and ruling 1 of the letter say which menu is being
ignored on which arm. The backfill below was done against all four together.

The 41 rows carry `fixedBy`, `pinnedBy` and `status` as of 17 August. The
archaeology, its method, and what it could not establish are in
§"The 41-row backfill" at the end of this file.

Worth keeping, because it was the sharpest half of the blocker: while
the ledger was missing, `NEW-G5-2` and `NEW-G8-3` were the only two finding IDs
that appeared anywhere in the tree, both as illustrative examples in the handoffs
and once in `validate/REGISTRY.md`. The other thirty-nine row *keys* did not
exist in this repository in any form. No amount of care would have recovered them
from prose, and the ledger is the only artefact that carries them.

### The pin claims in this document

The change order's instruction was to treat this file's "closed by vNN" entries
as claims and check that the named validator actually contains an assertion that
would go **red if the fix were reverted**, rather than merely mentioning the
area. That check was independent of the missing ledger, and every entry in it
transferred into a row's `pinnedBy` once the rows arrived. Sampled by reading,
and **confirmed genuine**:

| Claim | Verified assertion |
|---|---|
| 1a → `v61` | counts the adjustment optionmenu on six arms and no more, asserts every menu sits inside an `adjustOffered = 1` just opened, and pins the eighteen read sites against twelve guards |
| 1b → `v66`, `v69` | `v66` requires `annotMatrixPosthoc$` to name Tukey *and* state family-wise control, and requires the Dunn arm **not** to; `v69` asserts the asymmetry on the drawn figure and that no two-group arm borrows the sentence |
| P0 → `v73`, `v77` | `v77` asserts the defect's own line `.p = studentQ (.absT, .df)` is **absent** while the two-sided `2 * studentQ (.absT, .df)` survives; `v73` pins against the R oracle at `1e-14` and documents that direction-inversion reds **only** against the oracle |
| A → `v74` | asserts the stamp is written once, re-taken at dispatch, and zeroed the moment it is read — the both-or-neither shape a values-only check cannot see |
| B → `v75` | asserts on the **emitted script**: exactly one draw step heading, and the figure drawn at 195..275 rather than the discarded pass's 235 |
| C → `v76` | parses the bridge into a block tree and requires every bracket-label site to be **dominated** by `annotTextN = 1` — not an arm-scoped grep |
| D → `v68` | pin turned around: asserts `@emlCheckPlausibility` is **absent**, so re-introduction reds |

Every claim sampled by reading stands up. The seven that had not been sampled —
rulings 2, 4, 5, 6, 7, 8a, 8b, 9 and 10a, backed by `v54`, `v58`, `v62`, `v63`,
`v64`, `v65`, `v67` — were then **driven** rather than read, by the method in the
next section. Six of the seven go red: `v58`, `v62`, `v63`, `v64`, `v65` and
`v67` all fail on a plugin reverted to `30bc163`, between four and thirty checks
each. `v54` does **not**, and it was never going to: ruling 2 is that the two
version floors are two contracts, and what closes it is a paragraph in `v54`'s
header. A header is documentation. It is the right place for that ruling and it
is not a pin, and this table should stop implying otherwise.

**One correction to the table above, found by driving it.** `P0 → v73, v77` is
half right. `v77` reds hard on a reverted plugin — fifteen checks, because it
drives a real Praat out of R and nothing it reads outlives the run. `v73` stays
**green**, all 181 checks, because its input is
`evidence/csv/v73_directional_input.csv`, a committed capture that a source
revert does not touch. `v73`'s oracle comparison is exactly as good as the claim
in the table says it is, and it is a claim about a **file**, not about the tree.
The pair is still the right pair; what pins P0 against a revert is `v77` alone.
That distinction is the entire subject of the section below.

---

## The 41-row backfill — 17 August 2026

`audit/FINDINGS_MACHINE.json` now carries `fixedBy`, `pinnedBy` and `status` on
every row. `python3 validate/tools/check_findings_schema.py` exits 0.

| status | rows |
|---|---|
| `closed` — repaired, and something reds if the repair is undone | 26 |
| `fixed-unpinned` — repaired, and nothing in the suite would notice | 8 |
| `open` — no repair identified in this repository | 7 |

### How `fixedBy` was established

No commit in this repository carries a finding ID in its subject line — that is
the gap the convention above closes — so every hash below was read out of a
**diff**, not out of a message. For each row: locate the corrected behaviour in
the shipped source, `git log -S` the string that carries it against the file the
row's `mechanism` names, and confirm the identified commit's body describes that
behaviour. Where more than one commit touched the area, the one named is the one
that made the behaviour correct, not the first to touch it — `NEW-G11-1` is the
example worth keeping: `a4de0ee` repaired the half that was plainly broken and
made the header's portability claim *conditional*, and `d5a434b` is the commit
that made the claim true by construction. `d5a434b` is what the row carries.

Five commits carry all thirty-four repairs:

| Commit | Subject | Rows |
|---|---|---|
| `a4de0ee` | stats: export integrity, save guards, coercion, non-interactive replay | 11 |
| `7f62e75` | graphs: stereo is reachable, the KW crash is gone, and a steady tone draws flat | 13 |
| `c112b7c` | scripts: the editor stops deleting the wrong column, and describe gets a Save | 8 |
| `0e0c0fa` | graphs: the axis name clears its ticks, and a recorded auto axis replays as auto | 1 |
| `d5a434b` | recorder: the emitted include block is home-relative, full stop | 1 |

### How `pinnedBy` was established

Not by reading which validator mentions the area. **The plugin was reverted and
the validators were run.** `plugin/` at `30bc163` — the last tree before the
audit response began — was dropped into a scratch copy of this repository with
`validate/`, `harness/` and `evidence/` left at HEAD, and thirty-six validators
were run against it one at a time. Every check that turned red is a check that
would notice the loss of the repair it belongs to. Where a whole-file revert
could not attribute a red to one row, the mutation was narrowed to the single
behaviour — `NEW-G12-2` was settled by deleting the two `Rename: "eml_converted_"`
lines and nothing else, and `v63` reds on five checks.

The standard is deliberately literal: **a source revert, with no harness
re-driven.** That is what a reviewer who reverts a commit and runs the suite
actually gets, and it separates two things this repository has twice confused.
A validator that reads plugin source, or that drives a live Praat against the
tree, reds. A validator whose only input is a committed harness artefact stays
green, because the artefact still says what it said — which is precisely the
failure recorded above in `v61`'s week of attesting a repaired defect as open,
in `v45`'s pinned naming contract, and in the fifteen harnesses that no longer
reproduce. `v57` is the cleanest illustration: it names four findings in its own
header, and exactly one of them (`NEW-G1-1`) has a source-reading check behind
it. The other three are read off `harness/exportint/out`, and on a reverted tree
`v57` reports 71 of 73 passing.

### The backfill queue — eight repairs this project cannot prove

These are `fixed-unpinned`: the fix is in the tree and identified by hash, and
nothing in `validate/` would go red if it were undone. Each line is what a pin
would have to assert. None of them needs a new harness; five of them need one
static assertion against a source file a validator already reads.

| Row | Sev | Fixed by | What a pin has to assert |
|---|---|---|---|
| `NEW-G4-1` | 3 | `a4de0ee` | that the ANOVA augment's `.std.resid` is computed **with** the leverage term — `@emlOLSInfluence`, or `.hat`, reached from both ANOVA arms in `eml-analysis.praat` and not only from the regression arm. `v57` compares `.std.resid` against `rstandard()` today, but off `harness/exportint/out`, so the comparison survives the arithmetic being put back. |
| `NEW-G6-1` | 3 | `a4de0ee` | that the RM/Friedman **refusal** path reaches the exclusion note, not just the success path — the note existed before the fix and printed below results the refusal never reaches, so the assertion is a dominance one: every refusal exit in the RM branch is preceded by the disclosure, not merely that the disclosure exists. |
| `NEW-G12-3` | 3 | `a4de0ee` | that the zero-variance paired branch takes the refusal exit rather than the "Analysis complete" modal — the two are distinguishable in source, and `v57`'s check that the paired *wrapper* forks on a refusal passes on the pre-fix wrapper, so the wrapper is the wrong half to assert on. The orchestrator is the half that changed. |
| `NEW-G11-2` | 2 | `a4de0ee` | that the emitted recording restores the advanced globals it drew with (`prev_*ShowJitter`) and emits the annotation render — `v58` asserts both, off `harness/record/replay_out`. The same four counts read out of `eml-record.praat` would hold the same claim against the tree. |
| `NEW-G11-3` | 3 | `a4de0ee` | that a recording sweeps an orphaned meta table rather than hydrating from it, and that a session whose store was deleted takes no stamp from a survivor — `@emlRecordSweepOrphans` and the buffer pairing exist and are asserted only through the drive's KV file. |
| `NEW-G12-4` | 4 | `c112b7c` | **half-pinned, and the half that is missing is the one the finding names.** `v60` reds on the check-&-repair arm ("no raw `exitScript` refusal remains"). The describe wrapper's entry refusals are not asserted anywhere: putting `exitScript: "No numeric columns found in the selected Table."` back into `eml-describe-table.praat` leaves `v35`, `v49`, `v59`, `v60` and `v63` all green. The pin is the same grep `v60` already runs, pointed at the second file. |
| `D12` | 3 | `c112b7c` | that Describe Table Column offers Save, clears the Info field, and ends in a completion dialog. `v49`'s population excludes this wrapper by construction (its filter is `@emlRun[A-Za-z]+Analysis:`, and describe calls `@emlReportDescriptiveAnalysis`); `v48` counts eleven Save callers off a committed TSV. Either widen `v49`'s filter or assert the `@emlSavePanel` call site in the wrapper source. |
| `D6` | 4 | `7f62e75` | that the three graph types with no Annotation-layout menu **say so** — the fix replaced an absent field with the sentence "Comparisons appear as a matrix panel below the plot.", and no validator reads that string. One `grepl` in `v61`'s static half, beside the D4 and D11 checks it already makes on the same file. |

### The seven `open` rows, and why each is open

Three different things land on `open`, because the schema's mapping is total and
has one literal for "no `fixedBy`". They should not be read as one list.

**Not repaired, and the tree says so.** `NEW-G8-2` — a one-sided range (minimum
typed, maximum left on automatic) is still swapped into `(0, minimum)` by the
form's range-validation block, which is intact at `eml-graphs-form.praat`. What
`7f62e75` added is `@emlDiscloseClipped`, and that procedure's own header states
the position exactly: "The reordering happens in the form's range-validation
block and cannot be undone from here … What CAN be done from here, and is, is to
refuse to let the consequence pass unremarked." `v62` pins the disclosure and
says the same thing in its own comment. The disclosure fires only when
`.nOutside > 0`, so a user who types 300 as a floor on data that all sits below
300 gets the inverted range **and** silence. The row is `open`, and the mitigation
is real and is not the repair. This is the one row where reading the status
tables alone could leave a reader thinking a defect had been closed.

**Never repaired, and known not to be.** `D38` (simple effects after a
significant two-way interaction) and `D40` (no interaction plot among the graph
types). `grep -ri "simple effect"` and `"interaction plot"` return nothing in
`plugin/`. `FINDINGS_INDEX.md` already carries both as live; `D38`'s caution half
was closed on 7 August and its simple-effects half never was.

**Repaired before this repository existed.** `D66-b/c` and `D98/D99` were
resolved on 6 August 2026 and re-verified by the 14 August session. This
repository's root commit is `9b7d5aa`, 12 August 2026, which imported 2,818
files in one go. **There is no commit here for any repair made before 12
August.** Naming the root import as `fixedBy` would be false in the way the
change order warns about — by that logic the root import fixed all forty-one —
so the field is empty and the reason is this paragraph. `D98/D99` is in any case
an *evidence* closure rather than a code change: what the 14 August session
closed was the gap that the fix had never been driven on the exact committed
`r2`/`r5` datasets.

**Not defects.** `D15` and `RULE-28I` are the audit's two REFUTED rows — the
paired wrapper's literal `"Group"` preset is correct, and a second save after a
separate-legend save is byte-identical. The schema has no literal for "examined
and found not to be a defect", so both land on `open` mechanically. They are not
work. If a fourth literal is ever wanted, `refuted` is the one the ledger needs;
until then their `verdict` field carries the truth and `status` should be read
with it.

### What could not be established

Nothing in the 34 repaired rows has an unidentified commit. Every `fixedBy` in
the ledger resolves in this repository — the schema checker verifies each one
against `git cat-file` on every run, so a hash carried in from elsewhere cannot
survive a green check. The only rows with an empty `fixedBy` are the seven above,
and for each of them the emptiness is a statement rather than a gap in the
archaeology.
