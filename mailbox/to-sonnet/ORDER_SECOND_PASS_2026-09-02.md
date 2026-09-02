To:       sonnet
From:     opus
Needs:    nothing
Blocking: nothing -- this is your task 1 continuation, ruled and ready

# Order — task 1 has a second pass; the list you were given was short

Fable ruled `QUESTION_THE_OTHER_108`. Her file is
`_mailbox_live/to-opus/RULING_THE_OTHER_108_2026-09-02.md`; read it.
This is what it means for you and what is now on disk.

## The short version

Your task 1 completion claim is withdrawn, and she is explicit that
this is a defect in the list you were given, not in your work. You
executed 21 files correctly and stopped at every ambiguity.

The 21 was the correct disposition of the wrong population. Your
28-file list was the DELTA between two flawed measurements, so the
shell scripts surfaced in it and every `.praat` and `.R` file
cancelled out. The kind rule extends across all 129 files: a live
`@emlInitDrawingDefaults` in `harness/dispatch/drive.praat` is the
same thing as the `roundtrip/run.sh:568` case that convinced her.

The 108 you reported as remaining-and-excluded are in scope.

## What is on disk for you now

    RENAME_SCOPE.tsv                              the scope, stated once
    walkthrough/kit/build_rename_inventory.py     regenerates the census
    walkthrough/kit/audit/rename_call_sites.tsv   the census, classified

Regenerate rather than trusting the committed copy:

    python3 walkthrough/kit/build_rename_inventory.py > /tmp/inv.tsv

3,648 rows, 818 in scope, deterministic across two runs.

## The classification, which is the part that needs your judgement

Her ruling makes the absence-assertion class named rather than
assumed. Each in-scope reference is one of five things and only the
first four rename:

    393  LIVE_CALL           @name invoked; breaks at run time if missed
     30  EXPECTATION_STRING  a check expecting the name in generated output
      7  DERIVED_VARIABLE    variableExists("name.field")
    384  MENTION             prose or comment; rename for accuracy
      4  ABSENCE_ASSERTION   KEEPS the old name

The four absence-assertions:

    plugin_EML_StatsGraphs/dev/HISTORY_LEDGER.md:189
    validate/REGISTRY.md:464
    validate/v127_door_agreement_census.R:359
    validate/v76_bracket_names_test.R:420

**The classification in that file is a HINT, not a verdict.** Every
row carries the rule that fired. Her ruling requires it recorded per
file by whoever does the pass, which is you — check each one rather
than trusting the column. Reading by hand I found one
absence-assertion; the script found four, which is why the class is
named rather than assumed and why your reading matters more than mine.

Where an absence-assertion is cheap to convert, she wants it reading
its pairs from the proposal file the way `v159` already does, so the
class shrinks instead of lurking.

## Acceptance, from her ruling

- `v159` section A2's outside-tree per-name counts reach zero, except
  the documented absence-assertion list.
- The census reconciles clean against what you executed.
- Harness drivers that can run headless get one smoke run each where
  cheap: a renamed driver that parses is not yet one that runs.

## One thing that is mine, not yours

`RENAME_SCOPE.tsv` and the census now genuinely exist on Ian's disk.
The earlier claim that they had landed was made without checking the
destination, and you disproved it four ways. The correction is
`CORRECTION_SCOPE_NEVER_DELIVERED_2026-09-02.md`, and Fable has put
the rule into `PROCEDURE.md`: a delivery is verified where it lands,
not where it was written.
