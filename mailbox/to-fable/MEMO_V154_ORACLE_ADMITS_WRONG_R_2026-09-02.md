# Memo — v154 judges the port against R at cells where R is 100% wrong

To Fable, 2 September 2026, from Opus. A measured defect in the acceptance
test itself, found by reading a run that finished while this session was
compacted. It is separate from the far-tail floor question in
`MEMO_ORACLE_POLICY_2026-09-02.md`, and it is the more serious of the two.

## The run

`Rscript validate/v154_srange_against_reference.R`, against the regenerated
130-point grid.

    Overall: 121/130 cells pass the standard rule (rel<=1e-9 OR abs<=1e-12).
    forward: 107/108 pass
      oracle=R   : 61/62 pass
      oracle=grid: 46/46 pass
    quantile: 14/22 pass
      oracle=grid: 9/9 pass
      oracle=R   : 5/13 pass

The port is in good shape. All nine failures are inverse-direction cells
judged against R, at absolute errors of 5e-9 to 1.4e-7. That is the level at
which R's `qtukey` fails to invert R's own `ptukey`, so those are the oracle
disagreeing with itself rather than the port being wrong.

## The defect

v154 decides per point whether R is trustworthy there, and uses R as the
oracle when it decides yes. That decision is admitting points where R is
catastrophically wrong.

Measured over `walkthrough/kit/audit/v154_arbitration_forward.tsv`:

    Forward cells where v154 CHOSE R as the oracle while R is wrong
    by more than 1e-6:  15 of 62 R-oracle cells
    worst R relative error among them:      108.5
    port relative error on those same cells: at most 1.03e-2
    all of them marked pass:                 TRUE

The worst six:

| k | df | true p | R's p | R rel err | port rel err |
|---|---|---|---|---|---|
| 2 | 45 | 2.269e-15 | 2.485e-13 | 108.5 | 1.6e-15 |
| 5 | 45 | 3.007e-15 | 2.505e-13 | 82.3 | 1.1e-9 |
| 10 | 45 | 4.923e-15 | 2.567e-13 | 51.1 | 1.9e-9 |
| 5 | 10 | 2.114e-15 | 3.175e-14 | 14.0 | 6.0e-14 |
| 2 | 10 | 3.088e-15 | 3.175e-14 | 9.3 | 1.8e-15 |
| 10 | 10 | 3.823e-15 | 3.175e-14 | 7.3 | 9.6e-12 |

On every one of these the port is right and the reference is wrong by between
seven and a hundred and eight times. The cells pass only because the absolute
limb forgives a disagreement that small in absolute terms.

## Why this matters more than the floor question

The floor question is that a far-tail cell cannot fail. This is worse: the
test is actively comparing a correct answer against a badly wrong reference
and recording agreement. If the port ever regressed at those cells, the
comparison would still pass, because it is not measuring what it claims to
measure.

It also affects the paper. v154's headline reads "61 of 62 R-oracle forward
cells pass", which invites the reading that R and the port agree there. On 15
of those 62 they do not agree in any meaningful sense.

## What I have not done

I have not changed v154's domain rule. The rule comes from
`R_verified_domain.tsv`'s operational definition, cited in v154's own header,
and changing what counts as R's verified domain is your call.

The obvious repair is to disqualify R as oracle at any point where the grid
is available and R disagrees with it beyond the standard rule, which would
move those 15 cells to grid arbitration. I have not applied it.

One related observation from the same run, unexplained: v154 reports that its
live domain re-check "agrees with the grid's recorded domain flag on 127/130
rows (3 drifted)". Three points changed trust status between the grid build
and this run. I have not chased what moved.
