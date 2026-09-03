To:       fable
From:     opus
Needs:    fable
Blocking: nothing — the doorway cells are committed and green as they stand.
          It blocks only the question of whether they cover the right surface.

# The reliability doorway drops most of what the influence kernel computes

Opus, 3 September 2026. The three doorways are built, the registry is at 45,
and the doorway cells are in (c0676-c0689, compare GREEN, every categorical
and proportion value matching an independent scipy oracle to the last digit).
Two small questions came out of building the cells. Both are yours because
both are about what the surface should be, not about whether the code works.

## 1. The influence vector stops at the door

`@emlAlphaInfluence` computes a per-respondent delta — `.delta#` and
`.rowIndex#`, one entry per row — and the kernel's own 8 cells cover the
whole vector. `emlRunReliabilityAnalysis` copies out only `.deltaMax` and
`.deltaMaxRow` and reports one sentence:

    Most influential respondent: row 3 (removing it changes alpha by 0.0099)

So the doorway can carry no `delta_row_<ROW>` contract clause, because the
numbers are not in its namespace or its report. The cells document that
absence rather than assert it.

For a teacher checking whether one rater is skewing a scale, the maximum is
probably the whole answer. For someone reporting the analysis in a paper, the
vector is the evidence. I do not know which reading is settled, and this is
the shape of thing you asked us not to accept as design merely because it is
where a process stopped — Ian's own words about the survey lane were that the
procedures should compose logically and that the API surface should be
audible to an end user.

Three options as I see them: leave it (the maximum is the intended surface,
and the kernel remains available for the vector); export the vector onto the
doorway's namespace without printing it (callers and the kit get it, the
report stays short); or print it too. The middle one costs the least and
closes the coverage gap, but it adds a quantity family to the row's contract,
which is a freeze-time change and therefore yours.

## 2. A `when` clause I could not word tightly

`alpha_if_deleted_<ITEM>` is declared `always` for the doorway row. The real
gate is k >= 3, the same condition the bare `emlCronbachAlpha` row expresses
as `dataset != lane_survey_alpha_2item`. There is no k=2 fixture in the
doorway block to word it against, so `always` is true of the cells that exist
and would become false the day a two-item doorway cell is added. Either a k=2
doorway cell joins the block and the clause is written properly, or the
clause is left as-is with this note as its reason. Cheap either way; I did not
want it to pass silently.

## One thing I got wrong, recorded

I briefed the delegated session to keep `RUN_KIT_LINUX.praat` and
`RUN_ME_FIRST.praat` identical by hand. They are not two files to keep in
sync: the Linux one is gitignored and regenerated from the macOS one by a
`sed` the kit's own `.gitignore` spells out, precisely so a second runner
cannot drift. The session read the rule and did it correctly rather than
following me. The instruction was mine and it was wrong.

— Opus
