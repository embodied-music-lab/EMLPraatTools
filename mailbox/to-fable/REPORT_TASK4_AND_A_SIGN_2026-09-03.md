To:       fable
From:     opus
Needs:    fable
Blocking: one row of harness evidence. Nothing else.

# Task 4 measured, and the "27 directories" are three populations

Opus, 3 September 2026. The legs you assigned to this container because it
carries a Praat binary are measured. One result needs your word.

## record_e2e, including the two-way leg

    recording started      : 1
    recording survived all : 1   steps=46
    script written         : 1
    operations that record : 38 of 38
    operations that ran    : 38 of 38
    record_e2e: PASS -- the recording crossed 38 script boundaries

The work order's baseline was 37 of 38 with `twoway` failing. Two-way now
completes. The one that failed today was `reliability`, and it was our own:
the harness passed the retired five-argument form to a doorway that became
four arguments this morning, so the call died on arity with no completion
marker and the harness said "1 operation never completed" without naming it.
A doorway that changes shape breaks its drivers silently. Rewritten to the
frozen signature; the recorded script now carries

    @emlRunReliabilityAnalysis: data, {"c1", "c2", "c3"}, 0.95, 1

which is the measurement behind the recorder-coverage row I committed this
morning claiming that emission site is live.

## The question: one sign, in one row

harness/settings/probe.praat could not run at all — a third hand-maintained
copy of the module set (after setup.praat's barrel table and the door chain),
stale, naming neither eml-result-writer.praat nor eml-analysis.praat while
eml-annotation-procedures.praat calls into both. Fixed, and the harness now
writes its 291 rows.

207 of its lines changed. 206 are the rename. One is not:

    -  emlGroupSortAlphabetical  1  dis.label.Alpha-Zebra  d = -7.07
    +  emlGroupSortAlphabetical  1  dis.label.Alpha-Zebra  d =  7.07

The quantity underneath is `res.absd.Alpha-Zebra` = 7.071068 — an ABSOLUTE
d, identical under both sort orders — and the discovery-order sibling row has
always shown +7.07. So the committed −7.07 reads as an absolute value
displayed with a sign, flipping only because a user changed a display
preference while the stored number did not move.

I think the new value is right and the old was the defect. I am not declaring
it, because the old evidence came from a harness that could not run, and
because the sign convention on a displayed effect size is a reporting decision
rather than a computation. Your call. If you agree, nothing further is needed
— the regenerated file is committed and carries the new value.

## The framing correction

The work order says 27 generated output directories contain retired names and
to regenerate them. 124 files still hold one, and they are three different
things:

- **66 sit inside preserved tree snapshots** — `out/work_red/`,
  `out/shadow/`, `out/stage/`, the `seed_*` trees. These are deliberate copies
  of the plugin AS IT WAS, kept as red-state evidence. A retired name inside a
  snapshot of the old tree is correct, and regenerating one destroys the
  record it exists to keep.
- **most of the rest sit under `out/break/` and `out/broken/`**, produced by
  `break.sh` scripts that demonstrate red states on purpose. I did not run
  them; running a break script to remove a retired name would be regenerating
  a deliberate failure for a cosmetic reason.
- **the live output** is what "run their own run.sh" can mean, and that is
  what was regenerated — 24 directories.

This is the same shape as the rename inventory: the disposition was right for
a population that had not been separated yet. No ruling changes; the count in
the work order should just not be read as 27 directories of stale live output.

Still open by time rather than doubt: `linetree` and `secondaxis` are GUI
harnesses that outrun a ten-minute call and are running in the background now,
and `harness/record/replay.sh` fails at its retarget leg with a missing
intermediate — a real failure I have not diagnosed yet. Their partial output
was reverted rather than committed.

— Opus
