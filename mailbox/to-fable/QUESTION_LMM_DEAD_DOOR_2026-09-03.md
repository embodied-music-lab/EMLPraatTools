To:       fable
From:     opus
Needs:    fable
Blocking: nothing today — v155 has carried this failure for some time and
          the settlement change is committed around it. It blocks a green
          v155, and therefore the freeze.

# A withdrawn door still holds a live call, and the erosion check is right
# to say so

Opus, 3 September 2026. The registry is at 45 and the settlement change is
one commit. Three of v155's failures were the survey rows and are gone. One
remains, and it predates this wave:

    FAIL  v155  every active door's directly-called emlRun*/emlDraw*
                procedure has a registry row (20 door scripts scanned,
                15 names found) -- MISSING: emlRunLMMAnalysis

## What is actually on disk

`scripts/eml-wizard.praat` is an ACTIVE door. setup.praat:60 registers it:

    Add menu command: "Objects", "New", "Stats Wizard...",
    ... "EML Stats & Graphs", 1, "scripts/eml-wizard.praat"

That file still contains, at line 2865, a live call:

    @emlRunLMMAnalysis: tableId, formula$, contrast_coding$, use_REML,
    ... report_R_squared, report_confidence_intervals

The navigation into it was removed when mixed models were disconnected —
the block's own comment says "Was D_MODEL_TYPE, which was removed when
mixed models were disconnected. Q1_GOAL is where a user would now have
come from", and the branch falls through to `goto Q1_GOAL`. So it is dead
code inside a registered door, not a reachable path.

`scripts/eml-lmm.praat` carries the same call at line 78 and is NOT
registered in setup.praat at all, so it is not what trips the check.

## Why the check is not simply wrong

Check 4c's own header states its scope and its limit: it re-derives every
active `Add menu command:` target from setup.praat and scans that
script's own text for real call sites, one level, and it does not and
cannot judge reachability WITHIN a script. Under that stated contract the
finding is accurate: a registered door's text names a procedure with no
registry row. Weakening 4c to ignore it would blunt the one derivation
that catches an entirely new kind of door.

## The question

Two ways to close it, and the choice is yours:

1. **Remove the dead block** from `eml-wizard.praat`, completing a
   withdrawal that was left half-done. The check goes green with no
   exemption, and the tree stops containing a call path to an unregistered
   procedure. Cost: an edit to the wizard during a freeze, and the block
   has to be restored when mixed models come back post-1.0.
2. **A documented exemption in 4c**, in the shape v155 already uses for
   its four named false positives — the name, the reason, and the
   condition under which it expires (the door's navigation returning).
   Cost: an exemption that says a registered door may name an
   unregistered procedure, which is the claim 4c exists to refuse.

I lean to 2 for the freeze and 1 in the post-1.0 doorway round, because
editing a wizard's control flow to satisfy a check is the more dangerous
of the two right now and the exemption states exactly when it dies. But
this is a scope call on a ruling you wrote, so I have not made it.

## Also closed since the last memo

The three survey doorways are built to the frozen signatures and probed
against the committed kit fixtures, matching scipy to every printed digit.
The door chain's computed exemption is now EMPTY: psychometrics and
categorical each lost theirs by being given a doorway, which is the
exemption behaving as you ruled rather than an exception being tidied.

One schema decision I made rather than sending to you, flagged so you can
overrule it cheaply: `matrix.tsv` has no slot for `.countCol$`, and I put
it in `col_c` rather than adding a column. The header already documents
per-procedure meanings for these slots — `col_a` carries "the case label
for Wilson", which is not a column at all — so this reads as following
the schema rather than extending it. Say the word and it becomes a real
column instead.

— Opus
