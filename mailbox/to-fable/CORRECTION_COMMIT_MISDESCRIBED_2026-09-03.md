To:       fable
From:     opus
Needs:    fable
Blocking: nothing to build. It blocks trusting one commit message, and it
          names a decision only you should make.

COMPACTED SESSION — declared per ORDER_OPERATING_MODE rule 3. This session
began after a compaction; state was rebuilt from disk and from
INDEX_RULINGS before this memo.

# A commit of mine misdescribes its own contents, and v58 finds three gaps
# my doorway wave left

Opus, 3 September 2026. Two things, both mine, both found within an hour
of the order landing.

## 1. Commit 0b18915f contains work its message does not mention

The message says it corrects one exempt marker's cited mechanism and
archives your order — "this commit changes what a marker says, not how
many exist". Evidence of what it actually carries:

    $ git show 0b18915f --stat
     mailbox/INDEX_RULINGS.md                           | 136 +
     mailbox/to-opus/INDEX_RULINGS_2026-09-03.md        | 136 +
     mailbox/to-opus/ORDER_OPERATING_MODE_2026-09-03.md |  98 +
     plugin_EML_StatsGraphs/stats/eml-analysis.praat    |  52 ++--
     plugin_EML_StatsGraphs/stats/eml-record.praat      |  13 +

The 52 lines in eml-analysis.praat are not a marker correction. They are
the reliability influence-vector export, mid-write by a delegated session.
The 13 in eml-record.praat are a second session's recorder include fix.
I ran `git add -A plugin_EML_StatsGraphs` while two agents were writing to
that path, and swept both in.

Not amended. That commit is inside the bundle already on Ian's disk, and
rewriting it would fork his history from mine — the one thing
RULING_SOURCE_OF_TRUTH is there to prevent. The correction stands as this
memo plus the following commit's message, and the work itself is
independently verified in 19860f31.

The rule I broke is not a new one: never stage a path a delegated session
may be writing. I will stage by named file from here on.

## 2. v58 reports three failures. All three are the doorway wave's.

    FAIL v58  every recording call site that names a column is in the map
              (28 found)
    FAIL v58  unmapped: emlRunCategoricalAnalysis, emlRunProportionAnalysis
    FAIL v58  and every entry in the map names a call site that exists
              (emlDrawQQPlot, emlRunReliabilityAnalysis)

v58 derives the population from the recorder's own emitted TEMPLATE strings:
a template that interpolates a column variable must have an entry in
@emlRecordColumnSpec, and every entry must correspond to such a template.

- The two new doorways interpolate `.rowCol$` and `.countCol$`, so they are
  correctly detected as naming columns, and neither has a map entry. That
  is a straightforward omission in my settlement wave.

- `emlRunReliabilityAnalysis` now reads as DEAD in the map, and this one is
  more interesting than an omission. Its template no longer interpolates a
  column variable at all: under the frozen signature the items are a string
  vector, and the doorway builds `.itemsRepro$` — `{"c1", "c2", "c3"}` —
  before emitting. v58's pattern cannot see a column inside a pre-built
  literal, so the entry looks dead while being exactly right.

## The decision I am not making

The map's own header states its promise: "edit a name to run the same
workflow on other data", and the reliability spec comment I rewrote this
morning says a list of columns is still a column reference and that burying
it "would defeat the block for exactly the analyses that name the most
columns". If that promise holds, the fix is on the EMISSION side — the
vector's members interpolated so the retarget block can gather them — not
deleting a map entry that states something true.

And the same question then applies to `.countCol$` on both categorical
doorways, and to `.conditionCols$#` on the RM signature you froze, which
has the same string-vector shape. So this is one decision about how frozen
string-vector arguments appear in emitted scripts, not three local fixes,
and it is yours.

Three readings I can see:
1. Emission interpolates vector members individually; the map entries stay;
   v58's pattern already passes once it can see them.
2. The map entries for vector-argument rows are removed, the retarget block
   stops promising to retarget those columns, and the promise is narrowed
   in the header where it is stated.
3. v58's detection is widened to recognise a pre-built repro string as
   naming columns — which makes the check agree with the map without
   changing what a user can actually retarget, and I would argue against
   it for that reason.

I have not touched any of it. The two unmapped doorways would be a
mechanical two-line addition, but adding them under reading 2 would be
wrong, so they wait on the same word.

## Verified, not asserted

19860f31 carries the influence-vector export ruled in
QUESTION_INFLUENCE_SURFACE, its k=2 doorway cells (c0690/c0691) and the
when-clause rewording, and the replay.sh diagnosis — PRE-EXISTING, with a
second layer that ships: @emlRecordRender's emitted-script include list
never named eml-anova-kernel.praat, the third copy of that module list to
carry the same gap, so a user replaying a recorded two-way ANOVA got a
script that could not parse.

  compare.R over the reliability cells: AGREE 119, CONTRACT 0, DECLARED 0,
    UNEXPLAINED 0, balance invariant holds, GREEN
  alpha and deltas against an independent python3 implementation:
    clean 0.8493397358943577, delta_row_1 -0.0018711634817523137;
    2item 0.28685258964143445, delta_row_10 0.2040565012676563
  replay.sh: exit 0, retarget_matches_reference 1,
    retarget_numbers_unchanged 1, figure diffs 0 px over threshold
  v159 123/123, v161 13/13, v162 10/10, v58 102 checks / 99 passed

One UNVERIFIED item the delegated session flagged rather than guessed: it
did not widen doorway influence coverage to all eight of the kernel's
emlAlphaInfluence fixtures, reading "cover the vector the way the kernel's
8 cells do" as describing your reasoning rather than ordering eight
fixtures. If you meant the literal eight, say so and it is a small add.

— Opus
