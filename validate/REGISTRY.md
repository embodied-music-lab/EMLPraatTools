# Validation registry — EML Praat Tools

Ian Howell — Embodied Music Lab — GPL-3.0-or-later

This folder is the validation record for the EML Praat Tools statistics
layer. It exists so that the plugin's arithmetic can be checked by someone
with no access to the audit session, the sandbox, or the GUI harness.

**Nothing in this project counts as validated until a script in this folder
tests it.** Values quoted in an audit log or a chat transcript are not
validation. If a statistic is not covered by a script here, treat it as
unvalidated regardless of what any other document claims.

---

## Running it

```
Rscript validate/run_all.R
```

Requires **R only** — tested on 4.3.3. No packages are installed, loaded, or
needed; every quantity the plugin reports that base R does not provide
directly is implemented from its standard definition in `helpers.R`. This is
deliberate, so the suite runs on a stock R installation with no network
access.

Exit status is 0 if every check passes and 1 otherwise, so it can be wired
to CI unchanged. Individual scripts are also runnable on their own:

```
Rscript validate/v03_rm_anova_greenhouse_geisser.R
```

**The suite currently exits 1 by design** — 89 checks, 83 passing, 6 failing.
All six failures are the `PENDING DRIVE` markers in `v07`. See "Expected
failures" below.

---

## What is being compared against what

Each check pairs a value the plugin **printed** with a value R **computes**.

The reported values are transcribed from Info-window captures taken with
`info$()` piped to a file — not read off screenshots — and those captures
are committed under `evidence/info/`. The inputs are the exact tables the
plugin analysed, saved out of the live Praat instance *before* analysis and
committed under `evidence/csv/`.

That last point matters and is not incidental. **The plugin's demo tables
are randomly generated on each creation.** Creating a fresh
`Three groups (N=45)` table and re-running will not reproduce any number in
this suite. Every script reads a committed input file for that reason, and a
reviewer should not substitute freshly generated data.

Tolerances follow the precision the plugin prints at: 5e-4 against a
3-decimal display, 5e-5 against 4 decimals, and so on. Where the plugin
floors a small p-value to the string `< .001`, only the threshold claim can
be checked, and `check_below()` records it as such rather than inventing a
comparison.

---

## The scripts

| Script | Covers | Input | Checks |
|---|---|---|---|
| `helpers.R` | Shared harness and the statistics base R lacks: Cohen's *d* and *d*z, *r* from *t*, matched-pairs rank-biserial, RM-ANOVA with Greenhouse-Geisser, Kendall's *W* | — | — |
| `v01_pairwise_welch_bonferroni.R` | *Pairwise comparisons* wrapper: Welch *t*, Bonferroni, Cohen's *d* | `demo_3groups_input.csv` | 9 |
| `v02_pairwise_holm_differential.R` | The same wrapper run twice, one control apart, to separate an applied adjustment from a labelled one | `demo_3groups_b_input.csv` | 11 |
| `v03_rm_anova_greenhouse_geisser.R` | Stats Wizard RM-ANOVA: *F*, GG ε, condition means, Holm post-hoc | `demo_rm3_input.csv` | 14 |
| `v04_friedman.R` | Stats Wizard Friedman: χ², rank sums, Wilcoxon post-hoc, Holm on ties | `demo_rm3_input.csv` | 12 |
| `v05_paired_t.R` | *Compare paired/repeated*: paired *t*, descriptives, and the graphs-side CSV export row | `demo_paired_input.csv`, `pairedLong_results_5aug.csv` | 18 |
| `v06_D15_effect_size_defect.R` | D15, now resolved: each paired test reports its own effect size | `demo_paired_input.csv` | 6 |
| `v07_redpath_degenerate_inputs.R` | Red path: inputs that should fail or sit on a boundary | generated into `validate/redpath/` | 21 |

### Notes on individual scripts

**`v02`** is the load-bearing one for the adjustment logic. On that data the
Soprano–Mezzo contrast is `0.0527` under Bonferroni and `0.0228` under Holm —
opposite sides of .05. A control that relabelled the adjustment without
applying it could not produce that difference. It also checks Holm's
monotonicity constraint, which is the specific behaviour a naive step-down
implementation gets wrong.

**`v03`** cross-checks the RM-ANOVA twice: against the closed-form sums of
squares in `helpers.R`, and against base R's `aov()` with an `Error()`
stratum, which is an independent implementation. Both must agree with the
plugin.

**`v04`** covers the tied case: all three post-hoc raw p-values are
identical, so Holm must give all three the same adjusted value rather than
three different step values.

**`v05`** validates the Info window and the exported CSV separately. They
disagree in precision — the CSV carries `0.0000003` where the Info window
prints `< .001` — and checking only one surface would miss that.

---

## Expected failures

Two categories of check fail on purpose. A green run would mean the suite
had stopped telling the truth.

### 1. ~~`v06` pins a defect~~ — RESOLVED 5 August 2026

Finding **D15** was: under the heading *Paired t-test*, the plugin printed
`Matched-pairs r  0.971`. That value is the matched-pairs rank-biserial
correlation of the **Wilcoxon signed-rank** test. The correlation derived
from the paired *t* is **0.871**. Both are plausible and nothing on screen
distinguished them.

The plugin now reports Cohen's *d*z and *r*-from-*t* under the paired *t*,
and the rank-biserial *r* under Wilcoxon. `v06` was rewritten to assert the
corrected behaviour and **passes**; it retains a guard check that the two
effect sizes stay numerically distinct, so a future regression that routes
the rank statistic back under the parametric heading would fail the suite.

### 2. `v07` has six `PENDING DRIVE` checks

The R side of the red path is complete and runnable. **The plugin side is
mostly not.** Each case that has not been given to the plugin carries a
deliberately failing check, so the suite cannot report green while that work
is outstanding.

**R4 is driven and passing** as of 5 August 2026. `r4_singleton_group.csv`
was loaded into Praat unchanged and taken through the Stats Wizard; the
plugin refused and named the group and its n, which is what the case
requires. Screenshot in `evidence/shots/`. The other six remain undriven.

`v07` generates its tables into `validate/redpath/` as CSV, deterministically
and with no randomness, so the same files can be loaded into Praat and driven
through the GUI unchanged.

| Case | Input | Behaviour the plugin must show |
|---|---|---|
| R1 | 8 subjects, 4 complete cases | Report the complete-case count it analysed, or refuse. Silently analysing 4 while the table shows 8 is a defect |
| R2 | n = 2 subjects, k = 3 | df error = 2. Compute or refuse, but say which; do not present a p-value from df 2 without comment |
| R3 | Zero variance throughout | Refuse, naming the zero variance |
| R4 | One group with n = 1 | Refuse, naming the group and its n — **driven 5 Aug 2026, plugin does this** |
| R5 | Grouping column unique per row | Refuse before running, naming group count against row count. 15 pairs would otherwise be attempted, none estimable |
| R6 | Non-numeric entry in a measure column | Reject the column **by type**, naming it. Not "incomplete data" — see D83 |
| R7 | Contact quotient, range 0.40–0.55 | After the D88 fix, an axis that fits the data. With `roundTo = 10` the axis is 0–10 and the data occupies 2% of the panel |

---

## Coverage, stated honestly

**Covered:** pairwise Welch *t* with Bonferroni and Holm, Cohen's *d*,
RM-ANOVA with Greenhouse-Geisser, Friedman with Wilcoxon post-hoc, paired
*t* with descriptives, matched-pairs rank-biserial, and one CSV export row.

**Not covered.** The plugin's statistics layer is substantially larger than
this. Untested here: the descriptive layer, two-group and *k*-group
comparisons driven directly rather than through pairwise, Kruskal-Wallis,
two-way ANOVA, correlation, regression, normality testing, and every
dispatcher. A separate test-inventory audit on 2 August found validation
coverage across the whole procedure library to be uneven rather than
complete. This folder does not change that; it establishes the standard and
covers what has been driven so far.

**Not a validation of the graphing layer.** Figure defects (D88, D89, D90)
are recorded in the audit log and are not testable from R.

---

## For an independent reviewer

The useful question is not whether the numbers agree — they do, and you can
confirm that in one command. It is whether the *comparisons are the right
ones*:

- Are the tolerances defensible given what the plugin displays?
- Is the Greenhouse-Geisser implementation in `helpers.R` the standard one,
  and does the `aov()` cross-check in `v03` genuinely constitute an
  independent path?
- Is the rank-biserial convention in `helpers.R` the one that makes the D15
  claim correct? The whole finding turns on that.
- Are the red-path cases in `v07` the ones worth having, and what is missing?

Disagreement on any of these is more valuable than a passing run.
