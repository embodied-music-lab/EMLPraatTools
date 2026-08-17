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

> This paragraph describes the checker as it stood on 17 August morning. It was
> extended the same day with a fourth status literal, a `pre-repo` literal for
> `fixedBy`, and a conditional `pointer` field — see *Four rows of bookkeeping,
> and the schema extension they needed* at the foot of this file.

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

> As measured on 17 August morning. Four of these seven were reclassified that
> afternoon — `D38` and `D40` to `superseded`, `D66-b/c` and `D98/D99` to
> `fixed-unpinned` on a `pre-repo` fix — and the reasoning below is what the
> reclassification was built on rather than something it overturned. Three rows
> remain `open`. See the foot of this file.

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

### Mutation testing the pins — 17 August 2026

The section above established `pinnedBy` by reverting `plugin/` wholesale to
`30bc163` and seeing which validators went red. That answers a coarser question
than the ledger asks. **Thirty-four repaired rows are carried by five commits**
— `7f62e75` (13 rows), `a4de0ee` (11), `c112b7c` (8), `d5a434b` (1), `0e0c0fa`
(1) — so no severity-1 or severity-2 row can be isolated by reverting its own
`fixedBy`: every one of the eleven sits in a bundle of eight to thirteen. A red
on a reverted `a4de0ee` proves that *something* in eleven repairs is pinned. It
does not name which.

So each row was mutated **by hand, one behaviour at a time**, in a scratch copy
of `plugin/` at `/tmp/mutation`, and only the validator(s) the row names in
`pinnedBy` were run against it. The repository's own tree was never edited:
every validator takes `EML_*_FILE` / `EML_*_DIR` / `EML_PLUGIN_DIR` overrides,
the same doors `harness/formaxis/break.sh` and `harness/bracketcap/break_v76.sh`
drive their shadow trees through, and the mutated copy is passed on those.

**The standard is the one the backfill declared and is unchanged: the source is
mutated and no harness is re-driven.** That is what a reviewer who reverts and
runs `validate/run_all.R` actually gets, because nothing in that list re-renders
a figure. Where a mutation left the validator green, the harness was then
re-driven as a separate, clearly-labelled measurement, so that "no pin" and "no
pin under the suite's own conditions" are not confused.

Two rules were kept throughout. A mutation must be a **defect a person could
write** — not a syntax error, not a call to a procedure that does not exist —
and it must **run**: three first attempts aborted the Praat drive mid-way and
were rewritten, because a validator red caused by a broken rig measures the rig.

To re-run any single row: copy `plugin/` somewhere outside the repository, make
the one edit the row's Mutation column names, and run the row's validator with
the override that validator documents in its own header — `EML_EDITTABLE_FILE`
for `v55`, `EML_PLUGIN_DIR` for `v57`/`v59`/`v63`, `EML_OUTPUT_FILE` plus
`EML_WRITER_FILE` for `v56`, `EML_PAIRED_FILE` plus `EML_CHECKDATA_FILE` for
`v60`, `EML_GRAPHSFORM_FILE` plus `EML_ANNOTPROC_FILE` for `v61`,
`EML_GRAPHS_SRC` plus `EML_SCRIPTS_SRC` for `v62`, `EML_RECORD_PROC_SRC` plus
`EML_RECORD_SRC` plus `EML_OUTPUT_SRC` for `v58`. Every row below was measured
against a baseline run of the same validator over an unmutated copy through the
same overrides, so an override that silently failed to take would have shown as
a green mutation and a green baseline of different sizes rather than as a
result.

#### The eleven severity-1 and severity-2 rows

| Row | Sev | Pin | Mutation (one behaviour, nothing else) | Result |
|---|---|---|---|---|
| `NEW-G10-2` | 1 | `v55` | `eml-edit-table.praat`: `@columnRemove: column_to_delete` → `selectObject: tableId` + `Remove column: column_to_delete$` — the menu label back in place of the menu index | **RED 4/95.** "no menu path calls Get value:/Set string value:/Remove column: by name"; "stray name-addressed calls at line(s) 593"; "Delete Column passes the menu INDEX to @columnRemove"; "Delete Column does not pass the menu LABEL anywhere" |
| `NEW-G10-1` | 2 | `v55` | `eml-edit-table.praat`: the `@labelInUse: new_name$, column_to_rename` call and its `elsif labelInUse.found` refusal arm deleted from the rename branch, leaving the empty-name guard | **RED 1/94.** "the rename is gated on @labelInUse" |
| `NEW-G10-3` | 2 | `v55` | `eml-edit-table.praat`: `if .nCols <= 1` → `if .nCols < 1` | **RED 1/94.** "Delete Column refuses at <= 1 column, not < 1" |
| `NEW-G1-1` | 2 | `v57` | `eml-analysis.praat`: both `if .accumulate = 0` wrappers round `@emlCSVInit` removed inside `@emlRunNormalityAnalysis`, so the collectors are cleared per column again | **RED 1/74.** "every @emlCSVInit in it is guarded by the press test (0 of 2)" |
| `NEW-G12-1` | 2 | `v56`, `v59` | Three edits, all needed for the crash: `eml-output.praat` — `Set string value: .r, .columnName$, ""` removed from `@eml_auditLabelColumn`, both `@eml_defaultRowLabels:` calls removed from `@emlWrapperInit`; `eml-extract.praat` — `or .cell$ = "?"` removed from `@eml_strictNumericColumn`'s scan | **RED 2/107 on `v56`** ("an unlabelled cell is rewritten to the empty string"; "a cell that is already empty is not written to again") and **RED 6/42 on `v59`**, in the audit's own words: `Error: Table "eml_numericProbe": the cell in row 1 of column "row" is undefined.` on Compare groups / Correlate / Regression, over Matrix and TableOfReal both |
| `NEW-G12-5` | 2 | `v56` | `eml-output.praat`: the `@eml_saveFolderWritable` call and its whole refusal-and-return block replaced by a bare `createFolder: .folder$` | **RED 5/107.** the probe's stamp; "no longer calls createFolder: unguarded"; "asks the writability question"; "a failed writability check leaves the panel by its normal exit"; "the check happens before any write" |
| `NEW-G2-1` | 2 | `v56` | `eml-output.praat`: `.result$ = replace$ (.result$, "/", "-", 0)` deleted from `@eml_saveSafeBaseName`, the other eight characters left | **RED 1/107.** "the base name sanitiser replaces / (POSIX and macOS path separator)" — the per-character form of the check earns its keep here. A coarser variant, deleting the `@eml_saveSafeBaseName:` call from the panel, reds 3/107 |
| `NEW-G3-1` | 2 | `v60` | `eml-compare-paired.praat`: `@emlTableColumnNames: tableId` and `nCols = emlTableColumnNames.nCols` moved from inside the `repeat` to immediately above it — filled once and then trusted, which is the mechanism verbatim | **RED 2/49.** "the paired form re-reads the user's table's column names on every pass"; "and refreshes nCols from the same read" |
| `NEW-G7-2` | 2 | `v62` | `eml-graphs-form.praat`: the `@emlGraphsChannelGate: objectId, "waveform"` call and its `wasConverted` block deleted, making the channel choice unreachable from EML Graphs again | **RED 2/114.** "the graphs form gates the acquired object"; "and the call sits AFTER the acquire loop closes, on the path every figure takes" |
| `NEW-G9-1` | 2 | `v61` | `eml-annotation-procedures.praat`: `emlKruskalWallis.rMatrix## = emlDunnTest.rMatrix##` deleted from the significant branch | **RED 2/84.** "the graphs bridge copies Dunn's rank-biserial matrix into emlKruskalWallis"; "the copy follows the bridge's own @emlDunnTest call" |
| `NEW-G11-2` | 2 | *(none)* | `eml-record.praat`: all four `prev_*ShowJitter` emission blocks deleted from `@emlRecordCaptureEnv`. Then, harder: `@emlRecordCaptureEnv` **and** `@emlRecordCaptureAnnotations` both stubbed to `.out$ = ""` | **GREEN 91/91 both times.** The row already carries `pinnedBy: ""`; this confirms it. `v58`'s three witnesses (`emit_jitter_lines`, `emit_annotate_lines`, `emit_bracket_render`) are read out of `harness/record/replay_out`, and the committed artefact still says what it said |

Ten of the ten pinned rows go red. The eleventh was already recorded as
unpinned and is now measured as unpinned rather than inferred to be.

#### Every severity-3 and severity-4 row that carries a pin

Not a sample in the end: **all sixteen** of them, because each mutation is a
single edit and each validator runs in under a second (`v59` and `v63` launch
Praat and take six). Selection therefore needed no rule. One `fixed-unpinned`
row was mutated as a negative control, chosen because the backfill queue makes
an explicit prediction about it.

| Row | Sev | Pin | Mutation | Result |
|---|---|---|---|---|
| `D1/D2` | 3 | `v61` | `eml-graphs-form.praat`: the first of thirteen `@emlSeedAxisLabels` calls deleted — one column-mapping page left behind | **RED 1/84** (13 expected, 12 found) |
| `D11` | 3 | `v61` | form: `scatterGroupShown = tmpUseGroup` deleted and `if scatterGroupShown = 1` → `if 1 = 1`, so the group fields are built whatever the tickbox says | **RED 1/84.** "the group fields are gated on the tickbox (scatterGroupShown)" |
| `D5` | 3 | `v61` | form: one of the six `adjustOffered = 1` gate-openings deleted | **RED 2/84** (6 expected, 5 found, twice — the count and the adjacency) |
| `D7` | 3 | `v61` | form: the second of twelve `boolean: "Annotate results on graph"` deleted — one beginner arm back to hard-resetting the preset | **RED 1/84** (12 expected, 11 found) |
| `D8` | 3 | `v61` | form: `if config_showAdvanced = 0 / emlLegendPlacement = 1 / endif` deleted | **RED 1/84.** "beginner mode overrides the legend placement for the draw" |
| `D4` | 4 | `v61` | form: a read of the dead channel put back — `if emlGraphsPresetShowDots > 0 / prev_scatterShowDots = emlGraphsPresetShowDots / endif` | **RED 1/84** (0 expected, 2 found) |
| `NEW-G8-3` | 3 | `v61` | form: `if graph_type = 8 and annotate = 1 and scatterAnalysisType > 0` → `if 0`, so the scatter arm never resets its collector | **RED 1/84.** "the scatter arm resets the collector once per press" |
| `NEW-G2-2` | 3 | `v62` | `eml-annotation-procedures.praat`: the U gloss put back to `"U: Sum of ranks for the first group"` | **RED 2/114.** "no longer opens \"Sum of ranks\""; "says what U counts: pairs, out of n1 x n2" |
| `NEW-G8-4` | 3 | `v62` | `eml-draw-procedures.praat`: the first scatter path's `@emlPlaceAnnotationBox` call replaced by `emlPlaceAnnotationBox.corner1$ = "TL"` and `.collisions = 0` — the corner taken without measuring | **RED 1/114.** "both scatter paths place the panel through it" |
| `NEW-G10-4` | 3 | `v60` | `eml-check-data.praat`: `@emlCheckFileRowLengths: path$` deleted from the file-mode path | **RED 1/49.** "file mode scans row lengths" |
| `NEW-G11-4` | 3 | `v58` | `eml-record-save.praat`: `@emlRecordMakeFolder: outFolder$` deleted | **RED 1/91.** "the target folder is created before the flush" |
| `NEW-G12-2` | 3 | `v59`, `v63` | `eml-output.praat`: both `Rename: "eml_converted_" + …` lines deleted from `@emlWrapperInit` | **RED 5/41 on `v63`** — "the converted Table is renamed at creation" on `init_matrix`, `init_tor`, `init_labelled`, `init_partialcols`. **GREEN on `v59`**, and correctly: `v59`'s probe drives `@emlDescribeCoerceSelection`, a different coercion. Deleting the rename in `eml-describe-table.praat` instead reds `v59` 1/42 — the two named validators cover two different doors, and both doors are covered |
| `SAVED-OVERPRINT` | 4 | `v56` | `eml-output.praat`: `@emlWrapText: .one$, 62` in `@eml_saveReceiptLines` replaced by a one-line assignment of the raw string | **RED 1/107.** "the receipt wraps .one$ through @emlWrapText" |
| `NEW-G11-1` | 3 | `v58` | **Two mutations of the same defect, and they disagree.** (a) the render-time tilde rewrite deleted from `@emlRecordRender`, leaving `.p$ = emlRecordPluginRoot$` — the machine-absolute include block under a header claiming home-relative, which is the finding verbatim. (b) the Linux 6.x canonical fallback in `@emlPluginRoot` changed from `~/.praat-dir/…` to `/root/.praat-dir/…` | (a) **GREEN 91/91.** (b) **RED 2/91.** Pin kept — undoing `d5a434b` reds — but recorded as **half a pin**: the render-time rewrite, which is the half the audit measured, has no source assertion behind it. Everything `v58` says about the emitted include block is read off `harness/record/replay_out` |
| `NEW-G7-1` | 3 | ~~`v62`~~ | `eml-draw-procedures.praat`: `.spanFloorSemitones = 0.1` → `= 0`, so a sustained tone collapses onto its 1e-05 Hz frame again | **GREEN 114/114. PIN WITHDRAWN.** `v62`'s only source check here is `has(code_draw, "\\.spanFloorSemitones =")` — the presence of the assignment, not its value, and a zero satisfies it |
| `NEW-G8-1` | 3 | ~~`v62`~~ | `eml-graph-procedures.praat`: inside `@emlDrawMarker` only, `if emlPointInFrame.inside = 0` → `if 0` — the primitive still asks and then draws the point anyway | **GREEN 114/114. PIN WITHDRAWN.** `v62` counts `@emlPointInFrame:` call sites at `>= 2`; there are three (`@emlRegisterCollisionPoints`, `@emlDrawMarker`, `@emlDrawAlphaDot`), so one point primitive can stop clipping and the count still passes |
| `NEW-G4-1` | 3 | *(none)* | negative control. `eml-analysis.praat`: both ANOVA arms' `.std = (.v - .fit) / (.sigma * sqrt (1 - .hat))` → `/ .sigma`, the leverage term dropped | **GREEN 74/74**, as the backfill queue predicted: `v57` compares `.std.resid` against `rstandard()` off `harness/exportint/out` |

#### The two pins withdrawn, and what a real pin would cost

`audit/FINDINGS_MACHINE.json` now carries `pinnedBy: ""` and
`status: "fixed-unpinned"` on `NEW-G7-1` and `NEW-G8-1`.
`python3 validate/tools/check_findings_schema.py` **exits 0**; the census moves
from 26/8/7 to **24 closed, 10 fixed-unpinned, 7 open**.

Neither repair is in doubt — both are in the tree and both were re-measured
here. What is withdrawn is the claim that the suite would notice their loss.
And the cost of a real pin is one line each, because in both cases the check
that exists asserts the wrong quantity:

* `NEW-G7-1` — assert the **value**, `.spanFloorSemitones = 0.1`, not the
  presence of an assignment to it. A floor of zero is not a floor.
* `NEW-G8-1` — assert the clip **per primitive**: `@emlPointInFrame:` inside
  the body of `@emlDrawMarker` and inside the body of `@emlDrawAlphaDot`
  separately, rather than counting the file's occurrences at `>= 2`. That is
  the same correction `v62`'s own `core_bypassed` break case forced on the
  channel gate, where a file-wide grep was green on a tree with the call
  deleted from the gate.

Both are the shape this repository keeps finding: a check that a **plausible
edit satisfies while the behaviour it names is gone**. Neither was found by
reading. Both were found by mutating.

#### The evidence-type hypothesis, tested

The prediction under test was that the unpinned rows cluster in an early-August
stratum, when repairs landed faster than pins. **That is false here**, and the
dates settle it without argument: all thirty-four repaired rows landed on
**15 August**, in the five commits above. There is no early stratum to cluster
in.

The competing hypothesis — the backfill's own — was that the split is by
**evidence type**. Thirty-two distinct mutations were made and run through
thirty-four validator runs (two rows name two validators each), and every run
is classified below by what the check that decided it actually reads:

| Evidence the deciding check reads | Runs | Red | Green |
|---|---|---|---|
| plugin **SOURCE** — the file, read as text | 24 | 24 | 0 |
| **LIVE PRAAT**, driven out of the validator against the mutated tree | 3 | 3 | 0 |
| a **COMMITTED ARTEFACT** and nothing else | 6 | 0 | 6 |
| *(out of population — see below)* | 1 | 0 | 1 |

The variable is total across the thirty-three in-population runs: **every red
came from a check reading source or driving Praat, and not one red came from a
committed artefact.**

The thirty-fourth run is `NEW-G12-2` against `v59`, and it is green for a
reason that is not about evidence type: `v59` does drive live Praat, but its
probe enters through `@emlDescribeCoerceSelection` while the mutation was made
in `@emlWrapperInit`. Deleting the rename in the door `v59` actually drives
reds it, 1 of 42. It is kept in its own row rather than folded into either
column, because "the check reads a kind of evidence that cannot move" and "the
check drives the right kind of evidence through a different door" are different
defects with different repairs.

No other variable comes close. Severity does not predict it — the six greens
are two runs of one sev-2 row, three sev-3 rows and a sev-3 negative control.
The fixing commit does not: of the seven rows `a4de0ee` repaired that were
mutated here, five red and two do not. The validator does not: `v58`
produces both a red and a green **on the same row**, `NEW-G11-1`, from two
mutations of the same defect.

`NEW-G11-1` is the cleanest single demonstration in the set, because it holds
everything else constant: one row, one validator, one commit, one defect,
mutated two ways. The way that touches a string `v58` reads out of
`eml-record.praat` reds. The way that removes the behaviour `v58` only ever
sees through `harness/record/replay_out` does not.

**Written down as a rule, because it is a property of the whole suite and not
of these rows.** A validator's inputs divide into three kinds, and only two of
them can hold a repair in place against an edit:

> A check whose only input is a committed harness artefact cannot fail on a
> change to `plugin/`. The artefact was rendered by a tree that no longer
> exists and it will say what it said until something re-renders it. Such a
> check is evidence **about a run**, and it is often the only evidence
> available — no source assertion can see a clipped statistics box or a
> collapsed axis. But it is not a **pin**, and a row whose `pinnedBy` names
> only artefact-backed checks is `fixed-unpinned` however green the validator
> is.

The practical consequence, and it is not "re-drive everything": a pin needs
**one** assertion that reads the tree. `NEW-G7-1` and `NEW-G8-1` each need one
line. `NEW-G11-2`, `NEW-G4-1` and the render half of `NEW-G11-1` each need one.
The artefact half stays where it is and keeps doing the thing only it can do.

For completeness, and because it separates "not pinned" from "not testable":
both withdrawn rows **do** go red when the harness is re-driven against the
mutated tree. Driven through a self-contained shadow of `harness/graphaxes`
(`axes.sh` with `EML_AXES_OUTDIR` pointed away from the repository), on the
same two mutations:

* `NEW-G7-1` — **RED 3/114**, and the first line is the finding itself: *"the
  drawn axis is opened to a readable width (0.000014 Hz, from 0.000009702)"*.
* `NEW-G8-1` — **RED 2/114**: *"a typed range of 100-300 over data running
  90-322 withholds 0 point(s)"*, against the five the committed artefact
  records.

A control re-drive of the unmutated tree through the same shadow is 114/114, so
the reds are the mutations and not the rig. That is the measurement that makes
the withdrawal precise rather than pessimistic: these two repairs are provable
in about six seconds each, and they are not proved by the suite as it runs.

---

## Four rows of bookkeeping, and the schema extension they needed — 17 August 2026

Closing instructions from the verification session, items A2 and A3. Neither is
an investigation: both are rows whose `status` was wrong because the schema had
no literal for what they actually are, and both were sitting in `open` — the
literal that means *a repair is owed here* — while owing nothing.

### A2. `D38` and `D40` are not open defects. They are Phase 2

They were never fixes. The features do not exist and never did, so
`grep -ri "simple effect"` and `"interaction plot"` returning nothing in
`plugin/` is the **expected** result rather than a failed search; there is
nothing to have been repaired and nothing to have regressed. The work is
specified — with an oracle — in the feature roadmap:

| Row | now reads | pointer |
|---|---|---|
| `D38` | `superseded`, `fixedBy` and `pinnedBy` empty | `roadmap: audit/handoffs/20260816_evening/FEATURE_ROADMAP_TO_LMM_2026-08-16.md:54-56` — the Phase 2 bullet: simple effects as the two-way follow-up, effect of A within each level of B, with the existing Holm/Bonferroni vocabulary and the existing disclosure rules |
| `D40` | `superseded`, `fixedBy` and `pinnedBy` empty | the same file `:57-59` — the interaction plot as cell means with CI bars through the existing graph machinery and recorder semantics, *a graph family, not new drawing infrastructure* |

Both pointers land inside the Phase 2 section that opens at `:45`, and both are
governed by its last bullet at `:60`: **Oracles: R emmeans package for every
number.** That line is why this is a reclassification and not a deferral. A row
in `open` says the next reader should go and repair something; these two say the
next reader should go and *build* something, against a named oracle, in a phase
that is gated behind Phase 0 and Phase 1. `D38`'s caution half was closed on
7 August and is not what this row carries; the simple-effects half is.

### A3. `pre-repo`, and the convention so this class never blocks again

`D66-b/c` and `D98/D99` were repaired on 6 August 2026. This repository's root
commit is `9b7d5aa`, 12 August, a 2,818-file import. There is no commit here to
name and naming the import would be false in the way the change order warns
about — by that logic the import fixed all forty-one. Until now the field was
empty and the reason lived in a paragraph of this file, which is exactly the
shape of thing that blocks again the next time it comes up.

The convention, and it is now enforced rather than described:

> `fixedBy` may read the literal **`pre-repo`**. A row that does must carry a
> **pointer** at the earliest evidence *in this tree* that the fix is present.

| Row | now reads | pointer |
|---|---|---|
| `D66-b/c` | `fixedBy: "pre-repo"`, `pinnedBy: ""`, `status: fixed-unpinned` | `evidence: validate/v21_shipping_paths_broom.R:231-266` — the two BUILD paths that exported nothing before the repair, checked populated: RM tidy exists at all (`:238`) and the Friedman tidy/glance numbers against R (`:257-266`). Covers the populated-export half of the row's title |
| `D98/D99` | `fixedBy: "pre-repo"`, `pinnedBy: ""`, `status: fixed-unpinned` | `evidence: validate/v07_redpath_degenerate_inputs.R:306-354` — `R2` checks D98's caution in the committed `r2` capture (`:306`, placement and wording on the lines below it); `R5` attests D99's groups-vs-rows refusal (`:354`) against `evidence/shots/d99_r5_refusal_names_diagnosis.png` |

Both validators arrived in the root import, which is the earliest in-repo
evidence there can be for a repair made before the repository existed.

**`pinnedBy` is untouched, and the two rows moved to `fixed-unpinned` rather
than to `closed`.** This is the point on which the convention could quietly go
wrong, so it is stated plainly: a pointer is a **witness statement** about the
past and a pin is a **live check that would go red if the repair were undone**.
Neither pointer above is a pin — `v21` reads committed CSVs under
`evidence/csv_export/broom`, and `v07`'s two checks read a capture and a
screenshot. A revert of `plugin/` leaves all three artefacts saying what they
said, which is the failure v83's header is entirely about. A pre-repo repair
with no live pin is `fixed-unpinned` exactly like every other unpinned repair,
and these two join the backfill queue on the same terms as the rest of it.

### Where the pointer lives, and why there

**A fourth field on the row, `pointer`, conditional rather than universal**,
with one grammar and two kinds:

```
"pointer": "<kind>: <path>[:<line>|:<from>-<to>] <note>"
            kind ∈ { evidence, roadmap }
```

Three alternatives were considered and rejected. *Two fields* (`supersededBy`
and `evidenceFor`) — rejected because a consumer would then need to know which
of two places to look when `fixedBy` is not a hash, and because both fields
answer the same question: **the hash cannot speak here, so what do I read
instead?** *A convention inside `mechanism`* — rejected because `mechanism` is
prose describing the defect, and a checker that greps prose for a path is a
checker that goes green on a sentence that merely mentions a filename. *A field
on every row* — rejected because a hash-fixed row needs no pointer: the hash
**is** the pointer, and forty rows carrying `"pointer": ""` would be noise that
teaches a reader the field is optional decoration.

So the field appears **exactly where the hash cannot speak**, and its absence
elsewhere is itself information. It is validated wherever it appears — a stray
pointer on a hash-fixed row still has to open the file it names — and required
on precisely two conditions: `fixedBy == "pre-repo"` demands kind `evidence`,
`status == "superseded"` demands kind `roadmap`.

`superseded` is entailed, not typed. The checker's status table — the rule that
`status` is mechanical from the row's evidence and may not be an editorial
choice — now reads:

```
fixedBy "", roadmap pointer   ->  superseded
fixedBy ""                    ->  open              (whatever pinnedBy says)
fixedBy set, pinnedBy ""      ->  fixed-unpinned
both set                      ->  closed
```

Writing `superseded` into a row therefore requires a pointer whose file the
checker opens, and a roadmap pointer may not sit beside a `fixedBy` or a
`pinnedBy` — nothing was built, so there is nothing to have fixed and nothing
to hold in place. The literal says **where the work lives**. It deliberately
does not say *whether the finding was a real defect*, which is the next section.

### Enforcement, extended — `validate/tools/check_findings_schema.py`

Four checks added to the six already there:

1. `fixedBy` is a 40-character resolvable hash **or the literal `pre-repo`**,
   spelled exactly. `pre_repo` and `PRE-REPO` are failures, and the failure
   message says so: a convention that accepts near-misses is three conventions,
   and a consumer switching on the literal drops the near-misses into its
   default branch in the same silence that made `status` spelling load-bearing.
   `pre-repo` is skipped by the git lookup — it is asserted by its pointer.
2. Every `pointer` parses, and its path **opens**. A line span is checked
   against the file's real length: a pointer at line 900 of a 300-line file
   rots exactly as silently as one at a deleted file, and the row goes on
   reading as settled either way. Absolute paths and `..` are refused. The
   note's *presence* is required; its usefulness cannot be enforced and the
   file says so rather than imposing a minimum length that invites padding.
3. `pre-repo` and `superseded` rows carry the pointer that supports them, of
   the right kind. **This is the check that makes the convention worth having**
   — the instruction it implements is that a row which says `pre-repo` and
   points at nothing is worse than the empty field it replaced, because it
   looks settled.
4. No roadmap-superseded row also claims a fix or a pin.

**Break-tested 17 August, on fixture copies in a scratch directory — the real
ledger was never edited to make a check go red.** Each corruption below was
watched red and then discarded; a control run of the unmodified copy is green.

| Corruption (fixture) | Result |
|---|---|
| `D66-b/c` `pre-repo`, `pointer` deleted | **RED 1** — "fixedBy \"pre-repo\" with no valid `evidence:` pointer — name the earliest thing in this tree that shows the fix present" |
| `D38` `superseded`, `pointer` deleted | **RED 2** — the missing pointer, **and** the entailment: "status 'superseded', but fixedBy empty and pinnedBy empty entail 'open'". The literal cannot survive the loss of the thing that earns it |
| `D98/D99` `fixedBy: "pre_repo"` | **RED 1** — "neither a 40-char hex hash nor 'pre-repo' — the pre-repo literal is spelled exactly 'pre-repo'" |
| `D98/D99` `fixedBy: "PRE-REPO"` | **RED 1** — same check, same message |
| `D66-b/c` pointer path `v21_shipping_paths_brooom.R` | **RED 2** — "pointer names validate/v21_shipping_paths_brooom.R, which does not exist", and the row falls back to unsupported |

Four more were run for the same reason the four above were: `:306-9999` past
`v07`'s last line (**RED**, "past its last line (453)"); a pointer stripped to
a bare path with no note (**RED 3**); a roadmap pointer with `fixedBy` set
(**RED 3**, including "roadmap pointer, but fixedBy set — nothing was built");
and an `evidence:` pointer relabelled `roadmap:` on a `pre-repo` row (**RED 2**).

`python3 validate/tools/check_findings_schema.py` **exits 0** on the ledger as
it now stands, thirteen checks, all green.

### The census

| status | rows | change |
|---|---|---|
| `closed` | 24 | — |
| `fixed-unpinned` | 12 | +2 (`D66-b/c`, `D98/D99`) |
| `open` | 3 | −4 |
| `superseded` | 2 | +2 (`D38`, `D40`) |

Forty-one rows. The three that remain `open` are `NEW-G8-2` — the one true
unrepaired defect in the list, the one-sided range still swapped by the form's
range-validation block — and `D15` and `RULE-28I`, which are next.

### BLOCKED ON THE AUTHOR: one sentence would move `D15` and `RULE-28I`

Both are `open` and neither is work. `D15` — the paired wrapper's literal
`"Group"` preset targets its own reshaped table, which always has that column.
`RULE-28I` — a second save after a separate-legend save is byte-identical to
the full figure; the viewport restore is correct. The audit examined both and
**refuted** both. Their `verdict` field says `REFUTED` today and their `status`
says `open`, because the schema's mapping is total and has one literal for "no
`fixedBy`".

The closing instructions propose a fourth status literal, `refuted`, for exactly
these two rows, and mark the proposal **AWAITING IAN**. It has not been ruled
on, so **nothing was done to these two rows**: they are where they were, with
the statuses they had, and no near-synonym was invented to route around the
ruling. `superseded` was not stretched over them either — it says where work
moved, and there is no work here to move.

**Recommendation: add it.** The reason is the one this file has been making
about `closed` from the start. A status literal is what a consumer switches on,
and `open` currently carries three different meanings — *not repaired*
(`NEW-G8-2`), *never a fix, now roadmap work* (settled above), and *examined and
found not to be a defect at all*. The first two are now separated. The third is
not, and it is the one that misleads in the expensive direction: a reader
counting `open` rows to size the remaining work counts two rows of nothing, and
a reader who trusts `status` over `verdict` believes this project has two more
defects than it has. The cost is one literal, one line in `STATUSES`, and the
same requirement the other new literal carries — a `refuted` row must have
empty `fixedBy` and empty `pinnedBy`, because there was nothing to fix.

**The sentence needed, in a line:** *"Add `refuted` as a fourth status literal;
`D15` and `RULE-28I` take it."* Or a refusal, which is equally actionable — in
which case the recommendation is that `verdict` be documented as the field that
carries this distinction and the census be read as `open − 2` wherever it is
quoted.
