To:       fable
From:     opus
Needs:    ian
Blocking: the settlement wave's registry work

# Memo — the survey rows: what is merged, what is missing, and the one
# decision that has to come before a row proposal

`RULING_SURVEY_FINAL` and `ADDENDUM_SURVEY_IS_TESTED` ask for three
things. Two are measured below. The third — the row proposal itself —
cannot be written until Ian answers one question, because the answer
changes what the rows ARE.

## (b) Merge status: further along than expected, with one gap

MERGED into the plugin tree already:

- `stats/eml-psychometrics.praat` and `stats/eml-categorical.praat`,
  both present.
- All four validators, `v90` through `v93`, in `validate/` AND
  registered in `run_all.R`'s manifest.
- All four kernels in `walkthrough/kit/matrix.tsv` — they are already
  four of the kit's 17 validated procedures, exactly as the addendum
  says.

NOT merged, one item:

- The barrel include. `lane/survey-stats/PROPOSALS.md` item 1 asked
  for two `include` lines in `scripts/eml-lib-stats.praat`; neither
  is there. That single omission is why the door probes returned
  NO_DOOR for both modules and why `v162` exempts them. The lane's
  own report says it deliberately made no such edit.
- `MANIFEST.txt` rows, same reason.

So the merge is not settlement work of any size. It is two include
lines and two manifest rows, plus whatever the row decision below
requires.

## (a) The row proposal cannot be written yet, and here is why

**There are no survey entry procedures. There are only four kernels,
and they are not shaped like public rows.**

    procedure emlCronbachAlpha:         .data##, .confidence
    procedure emlAlphaInfluence:        .data##
    procedure emlChiSquareIndependence: .observed##, .correction
    procedure emlWilsonInterval:        .successes, .n, .confidence

Every other public row on the surface takes a table and column names:
`.tableId, .dataCol$, .groupCol$`. These take a raw matrix, or two
bare integers. A voice teacher cannot call `emlCronbachAlpha` from a
generated script without first building a matrix out of their own
table, which nothing on the public surface asks anyone to do.

`REGISTRY.tsv` says this is deliberate, naming these four
specifically: kernels stay INTERNAL, and one enters the registry only
by a considered decision.

Ian's ruling is that considered decision. But it can be honoured two
ways, and they are different amounts of work and different products:

1. **Register the four kernels as they are.** Fast — two include
   lines and four registry rows. The cost is four public procedures
   that break the surface's own shape convention, and a Table S2
   whose survey entries read differently from every other row.
2. **Build survey ENTRY procedures** in the `emlRun*Analysis` shape —
   table plus column names in, report and result-store out — that
   call the kernels the way `emlRunAnovaAnalysis` calls its kernel.
   Register those; kernels stay internal, consistent with every other
   family. Real work: two or three procedures, their refusals, their
   report wording, their recorder hooks, their kit cells.

I lean to 2, because the addendum's own standard — the survey API is
in the kit's validation scope like any other analysis family — reads
most naturally as the family having an entry point like the others.
But this is Ian's call, not mine and not a reading of yours.

## (c) The reliability stub does NOT resolve this

`emlRunReliabilityAnalysis` looks like the natural home for
Cronbach's alpha and is not:

    procedure emlRunReliabilityAnalysis: .tableId, .subjectCol$,
    ...     .raterCols$, .measure$, .scale$

Its parameters and its own text are about INTER-RATER agreement — its
report line names the ICC form. That is agreement between raters on
the same subjects. Cronbach's alpha is internal consistency among
items in a scale. Related field, different question, different data
layout.

So the stub is not a survey entry point waiting to be filled. If
option 2 is chosen, the survey entry procedures are new and the stub
stays excluded on its existing grounds.

Whether reliability and internal consistency should eventually share
a door is a real design question, and a separate one.

## One thing to confirm, because a check depends on it

`RULING_SURVEY_FINAL` says "the registry leaves 42". I read that as
the count DEPARTING from 42, since the same sentence says Table S2
and the gate's row-count assertion move with it. If it means the
count REMAINS 42, something else has to leave and I do not know what.

`v159` asserts exactly 42 today and will fail the moment a survey row
lands. That is the check doing its job, and I am not touching the
number until the reading is confirmed.

## What I need

Ian's answer on kernels-as-rows versus entry procedures. With it, the
row proposal follows in one memo: names, signatures, canonical names,
and per row its kit coverage — existing cells for the four kernels,
and for any new entry procedure the cells to be added before the
freeze, since the addendum rules out "correctly not covered" for a
survey analysis row.
