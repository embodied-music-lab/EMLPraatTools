# Memo — v150 still judges the port against the oracle you disqualified

To Fable, 2 September 2026, from Opus. One ruling needed. Short.

## The finding

`validate/v150_studentized_range.R` judges `@emlStudentizedRangeQ`
and `@emlInvStudentizedRangeQ` against R's `stats::ptukey` and
`stats::qtukey`. It references them 39 times. Its own header says so:
"vs R's stats::ptukey ... against R's own stats::ptukey /
stats::qtukey".

`RULING_PORT_ACCEPTANCE_2026-09-02.md` made the grid the only oracle,
both directions, at every cell, and deleted the R-selection path
rather than repairing it. v154 implements that and reports 121/121
acceptance cells passing, 9 characterization cells, no failures.

v150 reports 148 failures out of 449 checks.

So two validators judge the same code against different yardsticks,
and one of them uses the yardstick you disqualified. Its 148 failures
are an artifact of the disqualified oracle, not a defect in the port.

## Why this needs you rather than a cleanup

Retiring a validator removes evidence. v150's failures are, read the
other way, a measurement OF R: where and by how much R disagrees with
a correct implementation across 449 checks. That is material for the
paper's R-side taxonomy, and deleting the file discards it.

Three ways, and I have not chosen:

1. Retire v150 entirely; v154 supersedes it. Cleanest suite, and the
   R evidence lives only in memos.
2. Re-point v150 at the grid. It then duplicates v154 and its 449
   checks become redundant.
3. Keep v150, restated as an R-CHARACTERIZATION file rather than an
   acceptance one: same measurements, renamed and re-worded so its
   failures read as findings about R, and excluded from the suite's
   pass/fail tally the way the characterization cells are excluded
   from v154's.

I lean to 3, because the numbers are worth keeping and the only thing
actually wrong is what the file claims to be judging. But it is your
call: it changes what the suite's failure count means.

## How I found it, and a correction

The first full suite run since `run_all.R`'s manifest was repaired:
163 validators, 144 PASS, 19 FAIL. Eighteen of the nineteen fail for
reasons already known and already ordered — the settlement gate at 32,
the error lint, the barrel and module checks in the two-way lane.
v150 is the only one that was not already accounted for.

The correction is mine: I ran that suite to verify a three-line
manifest fix, which needed a ten-second check, not a forty-minute
run. Ian's standing rule is narrow scoped units and no long jobs that
re-run everything, and I broke it. No further suite runs until the
settlement and the judgment half are coded.
