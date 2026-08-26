# Ruling — post-hoc intervals, complete. Items 3.6, 3.7, 3.8

Fable with Ian, 26 August 2026. Answers all four questions in
`docs/MEMO_TO_FABLE_INTERVALS_2026-08-26.md` and replaces anything earlier on
the subject. Files in punch REV 3 beside 7.4-7.7; until REV 3 lands, this
document is the authority on intervals.

**Ian's governing decision: THE PROCEDURE SET SHIPS COMPLETE. No interval is
deferred.** Every absence that remains is a documented standard-practice
decision, never a gap.

## The coherence law — record it; it survives this round

**AN INTERVAL PRINTS ONLY WHEN ITS COVERAGE MATCHES THE CORRECTION IN FORCE.**

R's default `t.test` interval is uncorrected. Printing it beside a corrected
p-value is THE UNCORRECTED-P BAN IN INTERVAL FORM, and it never ships. Tukey's
intervals are legitimate because they are simultaneous by construction.

Consequently:

- Intervals appear on **Tukey** rows and on **Bonferroni** rows, the latter at
  **1 - alpha/m per pair**.
- **Holm and BH rows print NO interval**, with one teaching line — following
  the explainer toggle — saying intervals appear only with corrections that
  define them.
- **The alpha in force governs every interval level.** Entailed by the law, so
  NO INTERVAL LEVEL MAY EXIST AS ITS OWN LITERAL.

## 3.6 — pairwise t gains the interval (1.0)

Bonferroni rows only, level 1 - alpha/m per pair.

SE recovered as `.meanDiff / .t`. Reuse the `@emlDescriptive` interval shape
INCLUDING its `invStudentQ(0, df)` hang guard.

Oracle: `t.test(conf.level = 1 - alpha/m)` per pair.

Red demonstrations: a Holm row printing an interval; a Bonferroni interval
computed at 1 - alpha.

## 3.7 — RM post-hoc gains intervals on both branches (1.0)

Resolved by READING, not assessment: `@emlRMPostHoc` runs paired t
(parametric) and Wilcoxon signed-rank (nonparametric).

- **Paired-t branch** inherits 3.6. Oracle `t.test(paired = TRUE, ...)`.
- **Signed-rank branch** inherits 3.8 in one-sample form: Hodges-Lehmann
  pseudomedian of the differences (median of the Walsh averages), exact
  critical rank from the T+ null distribution THE PLUGIN ALREADY COMPUTES BY
  DP; the approximation branch ports R's inversion. Oracle
  `wilcox.test(paired = TRUE, conf.int = TRUE, conf.level = 1 - alpha/m)`.

The 60 rows move from not-assessed to compared.

## 3.8 — pairwise Wilcoxon gains the Hodges-Lehmann shift and interval (1.0)

**Estimator:** median of the n1*n2 cross-differences — mean of the middle two
on an even count, matching R.

**Exact branch** (both n < 50, no ties — THE SAME GATE THE P-VALUE ALREADY
USES): bounds are order statistics of the sorted cross-differences at ranks
`k` and `n1*n2 + 1 - k`, with `k` from `@emlMannWhitneyU`'s EXISTING DP null
distribution.

**Approximation branch:** port R's continuity-corrected z inversion, so the
implementations share the ALGORITHM, not just the answer.

The branch in use is disclosed the way the p-value's already is.

**Cross-differences are sorted with the native vector sort, NEVER a script
loop.**

Oracle: `wilcox.test(conf.int = TRUE, conf.level = 1 - alpha/m)` with the
exact/approx flag PINNED PER CELL to match the plugin's own gate. Fixtures
force both branches: small untied; tied; large-n.

Red demonstrations: an off-by-one in `k`; a Holm row with an interval; an
interval at 1 - alpha.

## Dunn, and what is already done

**Dunn — absent by standard practice, documented, CLOSED.**

`D-NOCI`'s retirement and the 144 Tukey rows moving from excused to compared
are endorsed as done.

## Language

Every new report line — the two Hodges-Lehmann lines, the interval column
headings, the teaching line — DRAFTS INTO THE LANGUAGE BATCH for Ian's en-bloc
approval before any dialog or report prints it.

## Validation scoping — Ian's direction, STANDING RULE

Scope every validation leg so THE COST OF A CHANGE IS THE COST OF WHAT
CHANGED. We are not rerunning everything every time.

- **New checks are self-contained files runnable alone.** Each interval item
  gets its own validator, or its own named section with a run-one entry point,
  green or red independently of the rest of the suite.
- **Kit runs are subsettable.** The 630-run kit gains a way to run ONLY THE
  ROWS A CHANGE TOUCHES — by procedure family, or by the quantity-contract
  tag. The interval work drives its own 864 + 432 + 60 + 144 rows without
  re-driving the other families. Full-kit runs happen AT GATES, not per
  commit.
- **Mid-lane regression cover is CANARIES, NOT SWEEPS:** a small named set of
  untouched checks runs per commit; the full suite runs at the gate and at
  Fable's inspection, per the standing batched-re-drive rule.
- **Re-baselines batch once at the end** (existing ruling); nothing here
  changes that.
