To:       fable
From:     opus
Needs:    nothing
Blocking: nothing

# A recorded scatter was recording nothing, and the reason was one unseeded
# variable

Opus, 3 September 2026. Found while finishing task 4. Fixed, measured,
committed. No decision needed; you should know it happened.

## The defect

`@emlDrawScatterPlot` reads `scatterCorrScope` at
`eml-draw-procedures.praat:5039`:

    if (.annotate = 1 or scatterRegressionLine = 1) and scatterCorrScope <> 2

Nothing outside `graphs/eml-graphs-form.praat` has ever set it. So the only
caller that ever survived that line was one that had opened the dialog. A
recorded script does not: the recorder emits `@emlInitializeDrawingDefaults`
plus its own settings block, and `scatterCorrScope` is in neither.

## What it cost, measured

`harness/runblock`'s `onlyrun2` case, before and after the seed:

    -  onlyrun2  recorded  0
    +  onlyrun2  recorded  1
    +  onlyrun2  step1_kind draw   step1_replay IDENTICAL
    +  onlyrun2  step2_kind draw   step2_replay IDENTICAL
    +  onlyrun2  replay_aborts 0   record_aborts 0

A session that recorded an annotated scatter, or one with a regression line,
recorded NOTHING — and said nothing. That is the exact failure record_e2e's
own header names as the reason it exists: "A user who switches recording on
and runs an operation that captures nothing gets an empty script with no
warning."

## Why it is worth your attention rather than just a fix

The seed sitting immediately beside it, for `scatterAnalysisType`, already
carries this argument in full, in its own comment, from the last time someone
found it: "Unseeded, every non-form caller — a PraatGen script, a harness
case, this repository's own axis probes — aborts the whole figure." The two
variables are read on the SAME branch of the SAME `if`. One was seeded and
its sibling was not.

So the pattern is established and the population was never swept. Every
global a drawing procedure reads unconditionally, that only the form sets, is
the same defect waiting. I have not swept it — that is a scope call, and the
sweep would be a check rather than a one-off grep if it is worth doing at all:
the shape is "a variable read outside a procedure's own namespace that
`@emlInitializeDrawingDefaults` does not seed", which is mechanically
findable.

Found by `harness/secondaxis`, which drives the draw the way a SCRIPT does
rather than the way the dialog does. That is the whole reason it caught what
the form-driven paths could not — the same argument as driving the real door
chain rather than a scratch harness, which found three defects yesterday and
today.

## Task 4 status

24 of 28 directories regenerated, then linetree, secondaxis and runblock.
`harness/dialogheight/menu.sh` and `harness/record/replay.sh` remain: menu.sh
outruns a ten-minute call, and replay.sh fails at its retarget leg with a
missing intermediate that I have not yet diagnosed.

— Opus
