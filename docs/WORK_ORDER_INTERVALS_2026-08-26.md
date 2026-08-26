# Work order — intervals and kit items, fully pinned

Fable, 26 August 2026. Supersedes the oracles memo's answer-shaped sections.
**A conflict between this order and the code resolves in favour of this order.
A case it does not cover comes back to Fable — it is not decided in place.**

## New procedures — all in `stats/eml-inferential.praat`

**`@emlTTestInterval: .meanDiff, .t, .df, .level`** -> `.low`, `.high`,
`.error$`.
SE = `.meanDiff / .t`, which carries the calling variant's own SE, Welch or
Student, automatically. Half-width = magnitude of
`invStudentQ((1-.level)/2, .df)` x SE, with the `@emlDescriptive` guard:
`.t = 0` or `.df` undefined sets `.error$` and **no `invStudentQ(0, df)` call
is ever made — it hangs.**
The df is THE CALLER'S VARIANT DF — `@emlTTest.df` (Welch-Satterthwaite), or
pooled `n1+n2-2` for Student, or `n-1` from `@emlTTestPaired`. **Never
recomputed inside.**

**`@emlHodgesLehmannTwoSample: .v1#, .v2#, .level`** -> `.estimate`, `.low`,
`.high`, `.method$`, `.error$`.
Estimate: median of all n1*n2 cross-differences, **sorted with the native
vector sort**; even count takes the mean of the middle two.
Branch gate **copied from `@emlMannWhitneyU` verbatim**: both n < 50 and no
ties gives `.method$ = "exact"`, critical rank k from the existing
U-distribution DP, bounds at sorted differences k and n1*n2+1-k. Otherwise
`.method$ = "normal approximation"`, bounds by **porting R's
continuity-corrected z inversion — the `wilcox.test` algorithm, ported, not
paraphrased.**

**`@emlHodgesLehmannPaired: .v1#, .v2#, .level`** -> same outputs.
Estimate: median of the n(n+1)/2 Walsh averages of the differences. Exact
branch takes the critical rank from the existing T+ DP distribution;
approximation branch uses the same ported inversion in one-sample form.

**`@emlScheffeInterval: .meanDiff, .se, .k, .dfWithin, .alpha`** -> `.low`,
`.high`, `.error$`.
Half-width = `sqrt((.k-1) * invFisherQ(.alpha, .k-1, .dfWithin))` x `.se`.
**LEVEL IS ALPHA DIRECTLY — NEVER ALPHA/M.** Scheffe's multiplier IS the
simultaneity; dividing alpha again is a wrong number, and it is red demo 1 for
its check.

## Orchestrator wiring — one rule, applied uniformly

Every pairwise arm computes **the point estimate on every row** — mean
difference from `.meanDiff`, Hodges-Lehmann estimate from the procedures above
— and prints it on every row, under every correction. Descriptive footing,
the same as the effect-size matrices.

**The interval prints only when the correction in force defines it.**
Bonferroni rows at `.level = 1 - alpha/m`. Scheffe rows at alpha through
`@emlScheffeInterval`. Tukey as shipped. **Holm and BH rows: estimate yes,
interval no.**

Implementation is compute-then-conditionally-print. The computation is cheap
and the branch is one `if` at the print site.

`@emlRMPostHoc`: the paired-t branch calls `@emlTTestInterval` with df = n-1;
the signed-rank branch calls `@emlHodgesLehmannPaired`. **No Welch/Student
split exists on paired branches — mathematically none can**, and this item
says so to keep one from being built.

**`.stN`** is assigned in every arm as the total complete-case N the analysis
consumed: the per-pair sum of the two group n's where the arm is per-pair, and
the Scheffe arm's existing `.totalN` where it is design-wide. **If the Outputs
header in the current tree says otherwise, the header is stale — amend it to
this definition in the same commit.**

**Hedges' g**: J = `exp(lnGamma(.df/2) - 0.5*ln(.df/2) - lnGamma((.df-1)/2))`,
replacing the approximate form at its one site. Delete the approximation table
comment and replace it with one line citing Hedges (1981) and
`effectsize::hedges_g` agreement.

## Commit order — serial through `eml-inferential.praat`

1. **Hedges exact.**
2. **`@emlTTestInterval` + 3.6 wiring** (procedure, plus the pairwise
   orchestrator print sites).
3. **`@emlHodgesLehmannTwoSample` + 3.8 wiring.**
4. **`@emlHodgesLehmannPaired` + 3.7 wiring, both branches, ONE COMMIT** — the
   paired-t branch consumes commit 2's procedure.
5. **`@emlScheffeInterval` + 3.9 wiring.**

**`.stN` lands in `eml-analysis.praat` and may run in parallel with any of 1-5
under the by-file rule: two agents never hold uncommitted edits to one file.**

The two documentation items ride along: the KW-ETA explainer decision with
commit 1, the two-way tolerance rule with commit 2.

## Checks — one per commit, next free v-numbers in commit order

- **Hedges**: extend the existing effect-size check with rows against
  `effectsize::hedges_g` (requireNamespace-guarded) AND a base-R `lgamma`
  evaluation, which is core and always runs. Red demo: reinstate the
  approximate J through the seeded-source variable.
- **Pairwise-t intervals**: 60 Welch + 60 Student kit cells against
  `t.test(var.equal =, conf.level = 1-alpha/m)`. Red demos, all three: a Holm
  row printing an interval; a Student interval on the Welch df, and the
  mirror; a Bonferroni interval at 1-alpha.
- **Hodges-Lehmann**, covering 3.7 and 3.8: fixtures forcing all four cells —
  {two-sample, paired} x {exact, approximation}, as small untied, tied and
  large-n — against
  `wilcox.test(conf.int = TRUE, conf.level = 1-alpha/m, paired =)`. Red demos:
  an off-by-one in the critical rank k; an interval at 1-alpha; a Holm row
  printing one.
- **Scheffe**: the core leg is the base-R definition through `qf`, and its
  header cites the definition and names itself definition-based; the optional
  leg is `DescTools::ScheffeTest` behind `requireNamespace`, with counts
  reported separately per the 121/8 convention. Red demos: a missing
  multiplier, giving an interval at 1-alpha with plain t; alpha/m substituted
  for alpha.
- **`.stN`**: the kit's 400 rows against `length()` sums. The current undefined
  is the standing red demo.

Kit discipline per the standing memo: **each commit drives its own named rows
plus canaries. Full suite and full kit at the gate only. The quantity contract
balances at every commit.**

## Language — drafted, into the batch, build gated on Ian's approval

Plumbing and checks build now. **These strings print only after Ian's en-bloc
approval.**

- `Mean difference (C1 - C2): x.xx` — already the 2.2 shape.
- `Hodges-Lehmann shift (C1 - C2): x.xx`
- Interval rendering `[low, high]` appended to the estimate line on
  interval-bearing rows, with the level named in the block header:
  `95% simultaneous intervals (Bonferroni-adjusted)` / `(Scheffe)`.
- Teaching line, toggle-following: `Confidence intervals are shown only for
  corrections that define them (Tukey, Scheffe, Bonferroni).`
- KW line, toggle-following: `Epsilon-squared is reported; it corrects a
  small-sample bias in eta-squared.`

## Delegation tiers — Opus assigns, tiers pinned

- **Kernel math** — commits 3-5's procedures and the inversion port: the
  executing session itself or its strongest agent.
- **Wiring, print sites, `.stN`, the Hedges one-liner**: cheap models.
- **Check-running and kit drives**: cheapest.
- **The model is named on every task**, per the standing rule.

The Welch-only wizard is a 4.3 gap already ruled — Student rows join the
wizard through lane 4's language batch. Out of scope here; nothing in this
order keys off the door.
