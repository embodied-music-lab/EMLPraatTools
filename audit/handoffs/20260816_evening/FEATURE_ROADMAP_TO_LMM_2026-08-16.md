# Feature roadmap — from current scope to linear mixed models

Drafted 16 Aug 2026, stress-test session. Premise: LMM is the endpoint, and the
right path is the one where every intermediate phase (a) is independently
valuable to the practitioner audience, (b) builds machinery LMM will need on
simpler models first, and (c) lands with validators in the same suite. The
engine already exists (v0.8, tabled 5 Aug: 4,436 lines, empirically at parity
with lme4/lmerTest/pbkrtest to 1e-8..9e-5, two known crash bugs, zero tests).
The roadmap's job is to make the plugin ready to RECEIVE it.

## Phase 0 — release the current scope (gate, already queued)

Nothing below starts until the assurance chain closes: automatic CI restored on
the final transferred commit, load-bearing harness evidence redriven, the built
artifact install-tested, front-door docs unified, the graphing/statistics
unification done ("one result through every door" as acceptance). This is
already ruled and ordered. It is a gate because every later phase adds surface
to a suite that must stay green, and because the unification determines the one
orchestration path all new features plug into.

## Phase 1 — within-subject aggregation pathway

The ten-singers-five-tokens feature. Collapse token-level rows to one summary
per subject-by-condition cell, then feed the EXISTING paired t / RM-ANOVA /
Wilcoxon machinery. New statistics: none. New machinery: a collapse step and
its disclosure.

- Collapse functions: mean, median, 20% trimmed mean. Default mean; median
  offered first-class (voice convention for F0; robust to one wild token).
- Disclosure, always: per-cell token count in the report and the export.
- Warning, conditional: unbalanced cell counts under median (Miller 1988 —
  small-n median bias cancels only when counts are equal). The warning names
  the imbalance and suggests mean/trimmed or equal-n truncation.
- Recorder: the collapse is a recorded step; collapse function and grouping
  columns go in the editable header block like every other choice.
- Validators: collapse arithmetic vs R (aggregate/tapply oracles), the
  unbalance warning fires exactly when it should, tidy export carries the
  summary type and n per cell.

Why first: highest value-to-cost in the whole roadmap for this audience, and
it creates the conceptual fork the wizard will later use — "balanced replicates
→ aggregate; unbalanced/missing → mixed model" — before the second branch
exists.

## Phase 2 — estimated marginal means, contrasts, simple effects

The post-model layer, built on the FIXED-effects models the plugin already
ships (one-way, two-way, RM-ANOVA). This is the emmeans logic: the machinery
that turns an omnibus result into the answers people actually publish.

- EMMs from the model's cell means and error term, with SEs and CIs.
- Custom contrasts: user-specified weight vectors over levels, checked to sum
  to zero, tested against the model error term.
- Simple effects: the two-way follow-up (effect of A within each level of B),
  with the existing adjustment vocabulary (Holm/Bonferroni) applied and the
  existing disclosure rules (figure names its test).
- Interaction plot: cell means with CI bars, through the existing graph
  machinery and recorder semantics — this is a graph family, not new drawing
  infrastructure.
- Oracles: R emmeans package for every number.

Why second: LMM output is unusable to this audience without this layer, and
building it on lm-class models first means it is validated on simple ground
before lmer-class models arrive. When LMM ships, its EMM/contrast layer is a
new BACKEND to an existing, tested front end — same dialogs, same export
vocabulary, same figures.

## Phase 3 — model diagnostics, unified

Widen the diagnostic surface on regression and ANOVA, in one framework LMM
will slot into.

- Residual panel: residuals-vs-fitted, scale-location, QQ (exists — reuse),
  leverage/influence (an OLS influence harness already exists in the repo —
  promote it from harness to feature).
- Assumption reporting consistent with the smoke-alarm philosophy: evidence
  shown, thresholds disclosed, recommendation stated but not silently enforced
  (the wizard normality ruling generalized).
- The same panel spec later serves LMM: residuals-vs-fitted and QQ carry over
  directly; add random-effect QQ and per-group residual views at that point.

Why third: cheap (much exists as harness code), closes a named gap from the
external comparison review, and defines the diagnostic contract LMM v1 must
meet — so "what does a mixed-model diagnostic screen show?" is answered before
the engine is wired in.

## Phase 4 — LMM v1

Now the engine lands into a plugin that already knows how to present models,
follow them up, diagnose them, export them, and record them.

Engine repairs first (order from the static review, all with specified fixes):
1. C1 — descending-for loop: factor interactions crash. The single most
   common design in this lab's work. Fix + the grep-lint for descending
   `for` across the whole tree.
2. H1 — ≥2-slope uncorrelated (`||`) random effects.
3. H2/H3 — Cholesky pivot guard and factorization-error propagation.
4. R² — replace the non-canonical random-slope formula (the reference itself
   was wrong; Praat faithfully reproduced it).
5. Helmert contrast scaling — the one predicted-divergent parity item; test
   it, fix if it diverges.

Test suite second, before any menu entry (the 5 Aug tabling ruling stands):
- Port the empirical audit's Praat-vs-R parity harness into validate/ as the
  LMM oracle family: the 9 datasets plus the four shapes that would have
  caught C1/H1 (categorical interaction, 2-slope ||, rank-deficient X,
  boundary/singular fit).
- Fit-level, not parse-level: every test fits and checks numbers.

Scope for v1, stated on the tin:
- Random intercepts and slopes, REML/ML, Satterthwaite df DEFAULT.
- Kenward-Roger offered with an N guard (dense-V is O(N³); unusable ~N≥2000
  — refuse or warn above a measured ceiling, don't hang).
- Wald CIs for fixed effects (documented as such); no batch profile CIs.
- Treatment/sum/polynomial contrasts (validated); Helmert per item 5.
- EMM/contrast/simple-effects layer from Phase 2 wired to the LMM backend.
- Diagnostics from Phase 3 plus random-effect QQ.

Integration, all with settled rules: wrapper dialog + coercion, 4-decimal/APA
display, tidy vocabulary (declare the new result columns; @eml_vocabCheck
already refuses unknowns), recorder (formula and columns in the editable
block), version floor, menu registration only after a GUI drive leg (the
batch-analysis precedent).

Wizard routing last: the Phase 1 fork completes — unbalanced token counts or
missing cells at the aggregation step now route to a door that exists, with
the evidence-and-tradeoffs framing rather than a deterministic switch.

## Explicitly out of scope (named so they stop being implied)

Quantile (median) mixed models, GLMMs (logistic/Poisson), crossed random
effects beyond what v0.8's parser handles, composable graph grammar, profile
CIs in batch. Each is a possible v2 conversation; none blocks the endpoint.

## Sequencing logic in one line

Phase 1 creates the fork, Phase 2 builds LMM's output layer on simple models,
Phase 3 builds its diagnostic layer the same way, Phase 4 drops the
already-verified engine into a fully prepared socket — so the riskiest code
lands last, into the most machinery, with the least new surface.
