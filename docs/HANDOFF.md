# Handoff — read this first in a new session

Written 20 Aug 2026. Everything durable about this project lives in the
repo, on purpose, because the cloud container this work runs in is restored
from older snapshots without warning and has been five times in two days.

## Read in this order

1. `CLAUDE.md` — working rules. How commits reach Ian, what to do after a
   rollback, scope of work units. Not optional; it encodes mistakes already
   made once.
2. `docs/OPEN_ITEMS.md` — every open defect and every ruled-but-unbuilt
   item, with anchors. This is the backlog.
3. This file — the parts that are true today and not yet anywhere else.
4. `ROADMAP.md` at the repo root — where the plugin is going after 1.0.0,
   with each phase's contract, the outside software its numbers are checked
   against, and what has to be done before it starts.

## Where the work actually is

GitHub `main` is the only durable copy. The container is disposable and its
`/tmp` is wiped with it. Ian pushes; this container cannot. Every commit is
bundled to `~/EMLPraatTools` on his machine the moment it is made, and the
five push commands are pasted with it every time — see CLAUDE.md.

Before believing anything about local state, fetch and compare content, not
commit ids.

## What is in flight

- **The unification.** Drawing a figure re-runs the analysis instead of
  receiving its result; demonstrated by two identical Kruskal-Wallis reports
  fifteen seconds apart. A memo is with Fable
  (`MEMO_TO_FABLE_unification_20260819.md`, also on Ian's disk) asking her to
  rule on: how the result store is keyed to the data, whether the
  display/result split gets a validator, where the store lives given Praat
  has no result object, and whether the pitch doors are the same mechanism.
  Do not start building until that lands.
- **The form field and field-order redesign has ARRIVED** and the block on
  dialog work is lifted. `docs/RULING_DIALOG_LABELS_v3.md` is the ruling —
  it supersedes v1 and v2 — and `docs/ADDENDUM_WORDING_AND_ROADMAP.md`
  carries two wording items, a terminology audit, and the order to create
  `ROADMAP.md`. Both were measured against Praat 6.6.30 under Xvfb, not
  reasoned about. Read the ruling before touching any field label; the
  label character law in it is not a style preference, it is what stops a
  field binding to a name no script can read.
- **The dispatch coverage gap** is closed: every figure type is now driven
  through the form's own dispatch.

## Judgement calls already made, so they are not relitigated

- Ship scope is Ian's. Report severity; do not treat the open list as a
  release gate.
- Only a few open items can put a wrong number in someone's work: the
  recorder replaying a different significance decision than the session
  showed, and the graph door running a different test than the report. The
  table editor's stale-cell write was the third and is now closed. The rest
  is friction.
- Pitch parameters went canonical with no release note, by ruling.
- The forest plot was swept rather than left deferred, by ruling.
- Erase-page and the subtitle are session-scoped: default at session start,
  remembered across draws, never written to disk.

## Habits that were learned the hard way here

- Commit the artifact, not just the conclusion. Showing Ian a screenshot and
  moving on lost a finished drive once.
- When source changes, the checks that describe it may be what goes red —
  not the evidence. Read the failure before regenerating anything.
- Measure before claiming. Two wrong diagnoses in this project came from
  reasoning about Praat instead of running it; both were settled in minutes
  by a fifteen-line probe.
- A regex sweep is not an audit. The claim that a defect existed nowhere
  else was false, and reading all 128 dialogs by hand found three more plus
  one in the fix itself.
