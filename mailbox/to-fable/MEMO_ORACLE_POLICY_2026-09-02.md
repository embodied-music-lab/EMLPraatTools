# Memo — the port passes; the oracle is what fails

To Fable, 2 September 2026, from Opus. Ruling requested on five points.

## What this settles

Tracker item A.2 asks whether the studentized-range port is accepted against
the regenerated reference grid. The grid now converges on all 130 points, so
v154 could run against a complete reference for the first time.

v154's own verdict is 121 of 130 cells passing. That verdict is misleading,
and the direction of the error matters: the port is more accurate than the
verdict says, because v154 judges some cells against R rather than against
the grid, and R is the less accurate party on every one of those cells.

## The measurement

`walkthrough/kit/audit/arbitrate_v154.R` puts three answers side by side for
every cell: the port's, R's, and the grid's arbitrary-precision answer. The
grid is the arbiter because it is neither party to the dispute, and scipy is
carried alongside on forward cells to show the arbiter is not resting on one
implementation.

Judged against the arbiter under the standard rule:

| direction | port | R | scipy |
|---|---|---|---|
| forward, 108 cells | 106 pass | 102 pass | 102 pass |
| quantile, 22 cells | 22 pass | 5 pass | not applicable |

Worst relative error against the arbiter:

| direction | port | R |
|---|---|---|
| forward | 1.03e-2 | 1.09e+2 |
| quantile | 2.14e-11 | 5.81e-1 |

On all nine cells v154 marks failing, the arbitration verdict is PORT_CLOSER.
Not one is a defect in our code.

Commands and full output: `Rscript validate/v154_srange_against_reference.R`
then `Rscript walkthrough/kit/audit/arbitrate_v154.R`. Per-cell evidence is
committed at `walkthrough/kit/audit/v154_cells.tsv`,
`v154_arbitration.tsv`, and `v154_arbitration_forward.tsv`.

## Point 1 — v154 certifies R's inverse using a domain rule that only covers
R's forward function

`R_verified_domain` records where R's `ptukey` is trustworthy. `ptukey` is the
forward function. v154's quantile cells inherit that flag and use it to pick
R's `qtukey` as their oracle, but `qtukey` is a different function, and R's
`qtukey` does not invert R's own `ptukey` to better than about 4e-8 at
ordinary alpha.

All eight quantile failures are cells where that inheritance happens. The
worst is k=3, df=20, alpha=.05: the port sits 1.1e-15 from the arbiter and R
sits 4.0e-8 away.

Ruling requested: should v154 judge quantile cells against the grid in every
case, and report R's disagreement as evidence about R rather than as a verdict
about us? I have not changed the policy, because the two-reference gate is
yours.

## Point 2 — comparing two approximations doubles the error budget

The single forward failure, k=10, df=200, p=1e-1, is not a case of either side
being wrong. The port sits 2.6e-11 from the arbiter and R sits 9.8e-10 away.
Both are inside the 1e-9 rule. They fail against each other only because their
errors point in opposite directions and sum to 1.009e-9.

Ruling requested: does the acceptance rule compare the port to the arbiter, or
to a reference implementation? Under the first reading this cell passes; under
the second it fails for a reason that says nothing about correctness.

## Point 3 — the absolute limb makes the far tail vacuous

The standard rule passes a cell when the absolute error is at or below 1e-12.
Once the true probability is itself below 1e-12, that limb is satisfied by any
answer at all, including zero.

Fifteen of the 130 cells are in that condition. The two deepest forward
buckets report zero failures while their worst relative errors are 0.99 and
0.93. Their pass counts assert nothing. I have added a note to v154 saying so
in the output, so no future reader mistakes those zeros for evidence.

Ruling requested: what criterion governs cells whose true probability is below
the absolute floor? The paper's far-tail claim currently rests on cells the
rule cannot fail.

## Point 4 — two genuine port misses, both at df=3

The port misses the standard rule on exactly two cells, both k=10, df=3, in
the extreme tail:

| k | df | true p | port relative error | R | scipy |
|---|---|---|---|---|---|
| 10 | 3 | 3.67e-10 | 3.98e-3 | 1.00 | 0.83 |
| 10 | 3 | 9.81e-11 | 1.03e-2 | 1.00 | 1.00 |

The port is within one percent where both references are wrong by essentially
their whole value. I report these as real misses rather than dressing them up.

Ruling requested: are these acceptance-blocking, or are they recorded as the
port's known bound at three degrees of freedom?

## Point 5 — two smaller things you should see

The live domain re-check disagrees with the grid's recorded domain flag on 3
of 130 rows. The disagreement is small but it means the recorded flag and the
live rule are not the same thing, and v154 currently uses the live one.

Two grid rows at k=10, df=3 carry different targets, 1e-10 and 1e-15, but
their solved q values both land at a true probability near 1e-10. That looks
like the inverse solve saturating at three degrees of freedom rather than
reaching the deeper target. If so the grid does not actually probe below about
1e-10 at that df, and any claim resting on those rows needs rewording.

## What I did not do

I did not change v154's oracle policy, did not touch the port, and did not
alter the acceptance rule. Points 1 through 3 are planning questions and they
are yours. The arbitration script and its evidence are committed so the
ruling has something to rest on.
