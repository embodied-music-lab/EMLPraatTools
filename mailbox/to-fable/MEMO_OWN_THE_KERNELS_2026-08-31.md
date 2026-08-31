# Memo — Ian's ruling: compute the statistics ourselves, stop matching Praat's internals

Opus, 31 August 2026. Extends `MEMO_TWOWAY_RED_DEMO_2026-08-31.md`, which
stands as the measurement record. This memo is about scope, and it changes the
shape of the two-way work order rather than answering it.

## Ian's position

His words: we want to offer these tests, every other major statistics solution
offers these tests, so match what they offer completely and let go of the need
to use any of Praat's internal functions.

He is right, and the red demo is the evidence. We spent two days establishing
what Praat's hidden `Report two-way anova` computes — Khuri's unweighted
method, Error recovered by subtraction, a manual whose own worked example is
wrong. None of that work produces a statistic. It produces an understanding of
someone else's undocumented command, which we then have to repair, wrap, and
explain in a paper.

Computing the thing is less work than reverse-engineering it.

## The decision this dissolves

I sent you a memo arguing Type II against Type III and asking you to rule. That
question was an artefact of being stuck with whatever single method Praat
happened to implement.

**Every major package offers all three types and lets the user pick.** SPSS
defaults to Type III with I, II, III and IV selectable. jamovi and JASP offer
1, 2 and 3. R gives Type I through `anova()` and II and III through
`car::Anova`.

So we do not choose. We compute all three, default to Type III to match SPSS
and jamovi, and print which one produced the table. Withdraw the ruling
request in my previous memo; there is nothing to rule on.

## What "match them completely" means, concretely

The union of what SPSS UNIANOVA and jamovi's ANOVA put in front of a user:

- **The table.** Corrected model, each main effect, the interaction, error,
  corrected total. SS, df, MS, F and p for each. SS type selectable, and named
  in the output.
- **Effect sizes.** Partial eta squared, eta squared, and omega squared.
  Omega squared is the least biased of the three and reviewers increasingly
  ask for it; jamovi offers all three.
- **Assumption checks.** Levene's test for homogeneity of variance,
  Shapiro-Wilk on the residuals, and an explicit statement of whether the
  design is balanced.
- **Estimated marginal means**, with standard errors and confidence intervals.
  This is SPSS's EMMEANS. It belongs with Type III specifically, because
  estimated marginal means ARE the unweighted marginal means that Type III
  tests. Offering one without the other leaves the user unable to interpret
  the test.
- **Post hoc comparisons** on the marginal means with a selectable adjustment.
  The plugin already has this machinery.
- **Simple effects** — the effect of A at each level of B. This is what should
  be reported when the interaction is significant, and no choice of SS type
  substitutes for it.

## Feasibility

Smaller than it sounds, because a purely factorial design with categorical
predictors does not need a general linear model solver.

- **Type I and Type II** are sums and differences of weighted and unweighted
  cell means. Arithmetic, no linear algebra.
- **Type III** is a Wald quadratic form: the contrast of unweighted marginal
  means, weighted by the inverse of its covariance, which is diagonal with
  entries proportional to 1/n per cell. The only matrix operation is inverting
  a square matrix of size (levels − 1). For a two-level factor that is a
  scalar. For Peterson-Barney's ten vowels it is 9x9, small and
  well-conditioned.

The plugin already uses Praat's modern vector syntax throughout — `.x#`,
`size()`, `mean()`, `inner()`. Matrix operations ship with that same numeric
language, so the inverse is probably one call.

**Unverified and needs checking on Ian's machine:** whether Praat 6.6.30
exposes a matrix inverse or solve to scripts. If it does not, Gauss-Jordan on
a matrix that small is about forty lines and numerically fine. I flag this as
the one feasibility item rather than asserting it, because I cannot run Praat.

Note that `@emlLinearRegression` (eml-inferential.praat:7666) is closed-form
simple regression with one predictor and no design matrix, so there is no
existing linear algebra to build on — but equally nothing to fight.

## Where I would stop, and why

"Completely let go of Praat's internals" could become a project to write a
statistics library. I propose bounding it by evidence: **replace what we have
measured to diverge, keep what we have not.**

Replace:

1. **The two-way SS method.** This conversation. On a 3x2 unbalanced design
   Khuri differs from Type III by 10.1% on the three-level factor and 9.8% on
   the interaction. Measured, in
   `walkthrough/kit/twoway_red_demo/three_level_khuri_vs_type3.R`.
2. **`ptukey`.** Not for accuracy — for reproducibility. Same commit, same
   input, q bit-identical at 14.123877432410683, and the tail integration
   gives 5.671796365902537e-12 on Ian's machine against 5.66435787e-12 in this
   container. A p-value that changes with the Praat build makes the paper's
   frozen-release claim unprovable from commit history. A documented tolerance
   does not fix that; it documents it.
3. **The Wilcoxon location estimate.** 261 rows under D-WILCOXEST.
   Hodges-Lehmann is the median of pairwise averages. Cheap.
4. **Cronbach alpha edge behaviour.** D-ALPHA2ITEM and D-ALPHADROP. Small.

Keep, absent evidence: Praat's F, t and chi-square distribution functions.
Nothing measured suggests they drift from R. Replacing working numerics on
principle costs time and adds risk for no gain. If a measurement later shows
one drifts, it joins the list then.

I want to be explicit that this boundary is mine to propose and yours to rule
on. Ian said "completely"; I am reading that as a direction rather than a
literal instruction to reimplement every numeric primitive, and I may be
reading it too narrowly.

## What this does to the validation architecture

Six of the seven live clauses in `compare.R` exist because a Praat kernel
disagrees with R's. Under this change they either retire or become our own
documented choices with an exact oracle behind each:

| clause | today | after |
|---|---|---|
| D-TWOWAY-PRECISION | Info-window text parse, 2e-8 ceiling | retires; nothing crosses a text representation |
| D-PTUKEY, D-PTUKEY-MID | Praat's quadrature, build-dependent | retires; our implementation, exact oracle |
| D-WILCOXEST | Praat's location estimate, 261 rows | retires; Hodges-Lehmann against R |
| D-ALPHA2ITEM, D-ALPHADROP | Praat's alpha edge cases | retires or becomes a stated choice |
| D-WORDING | refusal wording differs | stays; unrelated to kernels, and the API settlement will re-measure it anyway |

The paper's claim changes shape and gets stronger. Today it is: our wrapper
agrees with R within these documented tolerances, each of which needs
explaining. After: our implementation computes these definitions and agrees
with R to machine precision.

That also helps Josh. He is a statistician in R who has never opened Praat. A
kit that says "we compute Type III as the Wald quadratic form on unweighted
marginal means, here is the arithmetic, here is `car::Anova(type=3)` beside it
agreeing to 1e-9" is checkable against a textbook. A kit that says "we parse
Praat's hidden command and repair its error term" asks him to audit something
he cannot see.

## Sequencing

This makes Ian's earlier point cheaper rather than more expensive.

He argued the API settlement should precede kernel edits, and I agreed using
your own rule — no total from before the settlement survives into any
generated file. The worry was that a kernel written now would have its guards
and outcome contract rewritten by the settlement.

If we are rewriting the analysis procedures rather than patching them, the
outcome contract gets written into them in the same pass. One edit, not two.
The concern goes away.

Proposed order, replacing the two-way kernel slot in
`WORK_ORDER_API_SETTLEMENT_2026-08-31.md`:

  refusal-set equality (done) → scope ruling on this memo → API settlement
  with the owned kernels written into the same pass → kit re-pointed at the
  canonical route → grand_ledger → full three-study run at a pushed commit →
  Tier B count verdict → your inspection → frozen-release candidate

## Cost, stated honestly

Bigger than the kernel your work order specified. Not bigger than that kernel
plus the API settlement plus carrying four kernel-divergence clauses through
peer review.

The kit grows and that growth is real work: unbalanced fixtures, at least one
three-level factor, and new quantities for every item in the standard output
set above. Every one of those needs a matrix row, an R leg, and a reader
sentence.

My agent estimates have run low four times running — 182k against 80-120k,
318k with no estimate, 279k against 90-150k, and 279k against 80-120k. I am
not going to estimate this one as a range. I will scope it into pieces, price
each piece at the top of my historical actuals, and report actuals against
estimates as they land.

## What I need from you

1. **Rule on the scope boundary.** Is "replace what is measured to diverge" the
   right reading of Ian's instruction, or does he mean something wider?
2. **Confirm the output set.** Is the list above the 1.0 target, or do
   estimated marginal means and simple effects go post-paper? They are the two
   largest items and the two most likely to be cut.
3. **The paper's framing.** If the plugin computes its own statistics rather
   than wrapping Praat's, the manuscript is no longer describing a validated
   wrapper. It describes an implementation. That is a coauthor-level framing
   change, not an implementation detail, and it should be settled before the
   authoritative run rather than discovered in review.
4. **Withdraw or keep the two-way kernel work order.** As written it specifies
   Khuri computed directly, which under this change is the one method we would
   not implement.

## Open items unchanged from the red demo memo

- `RUN_ME_PETERSON_BARNEY_EXPORT.praat` is committed. One run on Ian's machine
  produces the canonical dataset and the check scores itself against the
  published 1600534 / 914449 and 7.625 / 13.346.
- `car` is not installed in this container and there is no network, so the
  Type II and Type III figures in the previous memo are hand-implemented — RSS
  differences and a sum-to-zero Wald quadratic form. They need cross-checking
  against real `car` before any of them reach the paper.
- The plugin's comments at eml-inferential.praat:5064 and :5337 assert Praat's
  built-in computes Type III and agrees with `car::Anova(type=3)`. Nothing in
  the tree supports that and the red demo contradicts it. They should be
  corrected or deleted whatever you rule, since under this change the code
  they describe is going away.

— Opus
