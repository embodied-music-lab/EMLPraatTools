# Roadmap — EML Stats & Graphs

This is the phase register: where the plugin is going, what each phase
owes, what checks it against outside software, and what must be true
before it starts. One authoritative list, in the repo, so it does not
live only in handoff documents.

`docs/OPEN_ITEMS.md` is the other standing list — defects and
ruled-but-unbuilt work inside the current scope. This file is features
beyond it. Maintained the same way: update it when a phase opens,
changes, or closes.

Endpoint: linear mixed models. Every phase before it is independently
useful on its own, and builds machinery the mixed models will need on
simpler ground first.

---

## Phase 0 — release the current scope

**Contract.** The assurance chain closes: continuous integration running
automatically on the shipped commit, harness evidence re-driven where a
check reads it, the built plugin installed and tested from the artifact,
front-door documentation unified, and the graphing/statistics
unification done.

**Oracles.** The existing suite. No new outside references.

**Gate.** This one is the gate for everything below. Later phases add
surface to a suite that has to stay green, and the unification fixes the
single path every new feature plugs into.

---

## Phase 1 — repeated measurements on the same subject

One unit. The ten-singers-five-tokens feature, its reliability
statistics, and the honesty disclosure that goes with them.

**Contract.**

- Collapse token-level rows to one summary per subject-by-condition
  cell, then feed the existing paired t / RM-ANOVA / Wilcoxon machinery.
  Collapse functions: mean (default), median (offered first-class — the
  voice convention for F0, and robust to one wild token), 20% trimmed
  mean.
- ICC(2,1) and ICC(2,k) on the token replicates: how much of the
  variation is between subjects rather than between tokens of the same
  subject, for a single token and for the mean of k.
- Spearman-Brown reliability of the k-token mean, so the user can see
  what averaging k tokens bought them and what k would buy.
- Effective n disclosed at the moment of aggregation, in the report and
  in the export, alongside the per-cell token count — the number of
  independent observations the test actually has, not the number of rows
  that went in.
- Unbalanced cell counts under the median get a warning that names the
  imbalance and offers mean, trimmed mean, or equal-n truncation.
- The guided fork: balanced replicates aggregate; unbalanced or missing
  cells route to a mixed model. Phase 1 builds the first branch and
  states the second exists.
- The collapse is a recorded step; collapse function and grouping
  columns sit in the editable header block like every other choice.

**Oracles.** R `aggregate` and `tapply` for the collapse arithmetic;
the `psych` package for ICC and Spearman-Brown. Tidy export carries the
summary type, the per-cell n, and the effective n.

**Gate.** Phase 0.

---

## Phase 1p — classical power and sample size

**Not gated on mixed models.** Runs whenever there is room for it. Only
simulation-based power for mixed designs waits for Phase 4.

**Contract.** Power, sample size, and detectable effect size for the
tests the plugin already ships: t (one-sample, paired, two-sample),
one-way and factorial ANOVA, correlation, proportions. Each answer
states which quantity was solved for and on what assumptions.

**Oracles.** R `pwr` and `MBESS`; G\*Power for the reference cases.

**Gate.** Phase 0.

---

## Phase 2 — estimated marginal means, contrasts, simple effects

**Contract.** The layer that turns an omnibus result into the numbers
people publish, built on the fixed-effects models the plugin already
ships.

- Estimated marginal means from the model's cell means and error term,
  with standard errors and confidence intervals.
- Custom contrasts: user-supplied weights over levels, checked to sum to
  zero, tested against the model error term.
- Simple effects: the two-way follow-up — the effect of one factor
  within each level of the other — using the adjustment vocabulary and
  disclosure rules already in place.
- Interaction plot: cell means with interval bars, through the existing
  graph machinery and recorder semantics. A graph family, not new
  drawing infrastructure.

**Oracles.** R `emmeans`, for every number.

**Gate.** Phase 0. Validated on simple models so that when mixed models
arrive, their follow-up layer is a new engine behind a front end that
already works.

---

## Phase 3 — model diagnostics, unified

**Contract.** One diagnostic framework across regression and ANOVA that
mixed models will later slot into: residuals against fitted values,
scale-location, QQ, and leverage/influence. Assumptions are reported the
way the wizard reports normality — evidence shown, thresholds stated,
recommendation made and not silently enforced.

**Oracles.** R `stats::influence.measures` and `plot.lm` quantities.

**Gate.** Phase 0. Defines the diagnostic contract mixed models v1 must
meet before the engine is wired in.

---

## Phase 4 — linear mixed models, version 1

**Contract.** Engine repairs first, then the test suite, then the menu
entry — in that order.

Repairs: the descending-`for` loop that crashes factor interactions
(plus a lint for descending `for` across the tree); two or more
uncorrelated random slopes; the Cholesky pivot guard and error
propagation; the non-canonical random-slope R-squared; Helmert contrast
scaling.

Scope on the tin: random intercepts and slopes, REML and ML,
Satterthwaite degrees of freedom by default, Kenward-Roger offered with
a size guard, Wald intervals for fixed effects, treatment/sum/polynomial
contrasts, the Phase 2 follow-up layer wired to the mixed backend, the
Phase 3 diagnostics plus random-effect QQ.

Then the wizard fork from Phase 1 completes: unbalanced token counts or
missing cells route to a door that now exists.

**Oracles.** R `lme4`, `lmerTest`, `pbkrtest` — the parity harness
ported into `validate/` as a fit-level oracle family, including the four
shapes that would have caught the known crashes: categorical
interaction, two uncorrelated slopes, rank-deficient design matrix, and
a boundary/singular fit.

**Gate.** Phases 1, 2 and 3. No menu entry until the test suite passes
and a GUI drive leg is green.

---

## Out of scope, named so they stop being implied

Quantile (median) mixed models; generalized mixed models (logistic,
Poisson); crossed random effects beyond what the current parser handles;
a composable graph grammar; profile confidence intervals in batch. Each
is a possible later conversation; none blocks the endpoint.
