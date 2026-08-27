# Memo to Fable — item 22, the three values are not parallel

27 August 2026. From Ian, via the build session. Answers requested on one
question your item 22 ruling left open, plus one the measurement turned up.

## The question

Your ruling says Mann-Whitney and signed-rank print their existing tags and
Spearman prints method plus reason. The three values that result are not
parallel:

| Procedure | Value |
|---|---|
| Mann-Whitney | `exact` or `normal approximation` |
| Wilcoxon signed-rank | `exact` or `normal approximation` |
| Spearman | `exact method (AS 89)`, `t approximation (ties present)`, `t approximation (large sample)` |

Under one label, `exact` and `exact method (AS 89)` say different amounts
about the same kind of fact.

## Where a reader actually meets the difference

Measured in the source, not assumed.

**Not within one report.** The wizard branches on `test_approach`, so a
group comparison and a correlation are separate runs producing separate
reports. No report carries a Mann-Whitney row and a Spearman row together.
The difference shows up when a reader compares two reports, or reads the
documentation.

**But a second asymmetry does sit inside one report.** When `testType$` is
`both`, `@emlRunCorrelationAnalysis` prints Pearson and Spearman in the
same report. Spearman gets a `p method` row; Pearson gets none, because
Pearson never chooses -- its p is always the t. Those two p lines sit
together, one disclosed and one not.

That is correct as far as the computation goes. The risk is how it reads:
a row present on one p and absent on the next can be read as one p being
disclosed and the other not, rather than as one procedure making a choice
and the other having none to make.

## What is cheap and what is not

The tags are internal. `@emlMannWhitneyU.method$` and
`@emlWilcoxonSignedRank.method$` reach no printed line today, so what they
print is free to differ from what they store. Choosing a printed text for
them costs nothing in the kernels and changes no computation.

The plumbing has not been built yet. Whatever you rule lands in the same
pass, so a decision now costs one build rather than two.

## The options, with their consequences

1. **Ship as ruled.** The short tags print as they are. Nothing further is
   needed. The across-report difference stands.

2. **Bring the short two up.** Mann-Whitney and signed-rank print
   `exact method` and `normal approximation`, or a named form parallel to
   Spearman's. Cost: two new strings in the batch, no kernel change.

3. **Bring Spearman down.** Spearman prints a bare method and carries its
   reason somewhere else. Cost: the ties-versus-cutoff distinction leaves
   the result line, which is the fact the branch law exists to disclose.

On the Pearson gap, separately: leave it absent, or give a procedure with
no branch an explicit value saying so.

## What is not in question

The row shape, the placement beneath the p line, the disclosure class, the
ASCII parentheses, and the scope of three procedures in one pass. Those are
ruled and the item reflects them.

## Status

Item 22 is written and awaiting Ian. `v147` passes 1458 checks, including
the boundary twins at n = 1290 and n = 1300. The plumbing is unbuilt and
waits on this answer.
