# EML Stats & Graphs — validation kit

The EML Stats & Graphs plugin is a project that significantly extends the
graphing and statistical analysis available inside Praat, so that voice
researchers can complete most common analyses without switching to Python
or R. The plugin drives a library of statistical processes written in
Praat's scripting language. A few processes wrap existing praat functions, but most were custon written using Praat's vector-based, interpreter-level tools. 

The purpose of the present study is to validate the statistical processes that power this plugin. The kit runs the same 624 analyses through the plugin and through R, then compares every number both programs report — 10,841 quantities in the current run. It is written for a reader who knows the statistics and has never opened Praat.

## TL/DR

The EML procedures library contains 17 procedures. This test runs 624 combinations of those procedures resulting in 10841 discrete measurements. All affirmative tests pass green with identical measures to nine decimal places. All negative tests (rejected means green) also pass. 

## The result, and where to read it

Open `results/SUMMARY.md` first. It is one page: the headline agreement,
every documented exception in plain terms, and instructions to reproduce
the run. The remaining files add detail in increasing depth:

| File | What it tells you |
|---|---|
| `results/SUMMARY.md` | The claim, the numbers, every exception explained. One page. |
| `results/coverage.md` | The 17 procedures, the R functions each is compared against, the options exercised, and the analysis counts. |
| `results/agreement_by_procedure.tsv` | Agreement rates broken out by procedure and post-hoc method. |
| `results/exceptions.tsv` | The rows where both programs computed a number and the numbers differ — currently 34 — with values and the reason side by side. |
| `results/agreements_all.tsv` | Every agreeing quantity: analysis, quantity, both values, difference. This file is long. |
| `results/disagreements_all.tsv` | Everything that is not a plain agreement — differing values, quantities only one program reports, wording differences — each row labeled by kind and carrying its reason. |
| `results/praat_reports/`, `results/r_reports/` | The full printed output of each analysis, per cell, from each program. |
| `audit/` | The working record the files above are derived from: the raw result tables and the row-by-row reconciliation, in the kit's internal vocabulary. |

## How agreement is decided

Two values agree when their relative difference is below 1e-9 — nine
significant digits. Values at machine zero (both magnitudes below 1e-12,
such as the skewness of a perfectly symmetric sample) are compared
absolutely instead; a relative difference between two rounding errors is
not informative.

Everything that fails that test appears in `disagreements_all.tsv` with a
written reason, and the comparison enforces an accounting identity: every
quantity either program reported lands in exactly one category —
agreeing, documented, or unexplained — and the run fails if anything is
unexplained. The current run has zero unexplained rows.

## What the exceptions are

Four kinds, all documented in place:

- **Precision ceilings.** The two-way ANOVA reads Praat's own printed
  table (about nine digits), and Tukey's adjusted p-values below 0.00001
  depend on each program's numerical evaluation of the studentized-range
  distribution. Largest observed effect: 0.13% in a p-value of 5e-12.
- **Quantities one side reports by design.** The plugin prints pairwise
  confidence intervals only under corrections with standard, informative
  interval constructions (Tukey, Scheffé, Bonferroni). Compatible bounds
  for stepwise procedures such as Holm exist in the literature but are
  typically uninformative for rejected hypotheses and are not reported by
  mainstream software; Dunn's test implementations report no interval at
  all. The kit's R side follows the same policy, and cross-checks the
  adjusted p-values with R's family-aware `pairwise.t.test`.
- **Places the deviation is R's.** Three cases, detailed in the next
  section: a sign error in `effectsize`, a formula departure in `psych`,
  and a definitional difference in `wilcox.test`'s shift estimate.
- **Wording.** Where data cannot be analyzed, both programs refuse the
  same analyses; each writes its refusal in its own words.

## Errors this kit has found, and an invitation

Comparing two implementations at nine significant digits surfaces errors
on both sides. The documented cases so far are on the R side.

1. **`effectsize` 0.8.6 loses the sign on the paired rank-biserial
   correlation when every difference is identical.** It returns +1
   whether the first column is uniformly above or below the second. The
   definition (R⁺ − R⁻)/(R⁺ + R⁻) gives −1 when five differences are −5,
   and `wilcox.test`'s own V statistic gets the direction right. The
   case is confined to inputs where all differences share one magnitude
   — two of the kit's nine paired comparisons, by construction.
2. **`psych::alpha` disagrees on alpha-if-deleted with a two-item
   remainder.** The derivation is short enough to check by hand: item
   variances 0.5, 0.5, 0.5, 0; total-score variance 0.5;
   (4/3)(1 − 3) = −8/3 exactly, from both the definitional and the
   covariance forms. `psych` returns −3.0.
3. **`wilcox.test`'s Hodges-Lehmann estimate on the approximation
   branch** — and this one is not an error. Two defensible definitions
   disagree: the estimator is the median of cross-differences, which the
   plugin reports on both branches, while `wilcox.test` returns a root
   of its own W function on the approximation branch, about 4e-5 from
   R's own exact-branch answer on the same data. It is recorded so
   nobody spends time diagnosing it.

If you disagree with any of these three readings, we want to hear it.
And we assume the plugin contains undiscovered edge-case errors of the
same kind: an unusual data shape or a boundary condition producing a
wrong number that these fixtures never exercise. If you find or suspect
one, tell us the analysis, the data that produced it, and the value you
expected, and we will add it to the kit as a fixture.

`run_analyses.R` is about 1,100 lines of commented R, organized by
procedure family. Reading it and checking that each R call is the right
call is a review we would value.

## Run it yourself

Requirements: Praat (6.6.30), R 4.3 or later, and eight R
packages. Install them once:

```r
install.packages(c("rstatix", "effectsize", "car", "afex",
                   "multcomp", "nortest", "coin", "psych"))
```

The R runner checks for all eight before it starts and prints this same
install line if any are missing. One further cross-check uses `DescTools`
when it is installed, and is skipped with a note when it is not.

1. Open `RUN_ME_FIRST.praat` in Praat and run it. It writes the plugin's
   results table.
2. Source `run_analyses.R` in R. It writes R's results table.
3. Source `compare.R`. It compares the two tables, prints the verdict,
   and regenerates every file in `results/`.

The fixtures are in `data/`, one CSV per dataset. `matrix.tsv` lists all
624 analyses, one row per run; its comment header documents each column.

## What this kit does not check

The kit exercises the plugin's scripting interface — the same procedures
the menus and wizard call, driven directly. Dialog behavior, menu
wording, and graphics are validated separately in the repository's
`validate/` suite. Statistics the plugin does not compute (for example,
mixed-effects models) are outside the scope of both the plugin and this
kit.
