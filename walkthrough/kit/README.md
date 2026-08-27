# EML Stats & Graphs walkthrough kit

## What this is

EML Stats & Graphs is a statistics plugin for Praat, the phonetics software
voice researchers use. It adds a library of 17 statistical procedures: group
comparisons, analysis of variance, rank tests, correlation, regression,
repeated measures, and a survey lane covering reliability and categorical
association. Each procedure offers choices — which test, whether to run a post
hoc, which multiple-comparison adjustment, whether to assume equal variances,
how to order the groups.

This kit is the evidence that those procedures compute what they claim. It
runs every one of them against R and shows you both answers.

## What it tests

Whether a t-test is correct in isolation is not in question.

The claim under test is that the procedures compose correctly. Choosing Welch
rather than Student, then Holm rather than Bonferroni, then alphabetical
rather than discovery group order should change exactly the numbers those
choices govern and nothing else.

The kit is built around two rules.

**Every quantity is computed twice** — once by the plugin, once by an R
package a statistician would call — and the two are compared row by row.

**Every row lands in a named category.** A quantity one side reports and the
other does not is a finding with a written reason, not an absence. The
comparison counts its categories and checks they sum to the total, so a row
cannot fall out of all of them.

## How the procedures are stress-tested

The datasets are not realistic and are not meant to be. They are 29 tables
built to sit on the boundaries where implementations break: a group of two, a
group of one, zero variance, perfectly additive columns, every difference
identical, missing values, non-numeric values, a decimal comma, a value too
large to represent.

Ordinary data exercises the path an implementation was written for.
Degenerate data exercises the paths it was not.

Some inputs are expected to be refused rather than analysed. **A refusal that
happens correctly is evidence**, so those cells are checked as strictly as any
other: both sides must refuse the same cell, and neither may emit a number
while doing it. 15 of the cells are declared refusals.

## How every combination is produced

The plugin's choices are axes. Across the 17 procedures there are nine of
them:

| axis | values |
|---|---|
| test | 9, including Welch, Student, Wilcoxon, Scheffé, Pearson, Spearman |
| post hoc | on, off |
| adjustment | Bonferroni, Holm, Benjamini-Hochberg, none |
| equal variance | assumed, not assumed |
| group order | table order, alphabetical |
| confidence level | 0.90, 0.95, 0.99 |
| continuity correction | on, off |
| lane | analysis, survey |
| expected outcome | result, refusal |

Crossing every applicable axis against every dataset a procedure legitimately
accepts gives **630 cells**. One cell is one analysis run: a procedure, a
dataset, and a value for every setting that applies to it.

Group order is an axis because it changes results. On `v11_twoway_input`,
SPL_dB by voice_type, discovery order gives t = 3.9024 and alphabetical gives
t = −3.9024. That sign reaches Cohen's d, rank-biserial r, and every pairwise
mean difference.

**All 630 cells are declared in one file, `matrix.tsv`, and both sides read
it.** Neither the Praat script nor the R script carries its own list of what
to run. A cell that exists for one language and not the other cannot happen,
because there is only one list.

## Before you start

You need Praat 6.6.30 or newer, R, and RStudio.

To set up, follow these steps:

1. Install Praat. Below 6.6.30 the plugin refuses to load.
2. Unzip `plugin_EML_StatsGraphs.zip` and drag the folder into your Praat
   preferences folder. On macOS that is `~/Library/Preferences/Praat Prefs/`.
   Do not rename the folder; Praat identifies the plugin by that exact name.
3. Restart Praat and let it finish starting. The plugin generates
   `scripts/eml-lib-user.praat` at launch, and this kit loads the plugin
   through that file.
4. In RStudio, install the eight R packages:

   ```r
   install.packages(c("rstatix","effectsize","car","afex","multcomp","nortest","coin","psych"))
   ```

On macOS, that is the whole setup. On Windows or Linux, change the one
`include` line at the top of `RUN_ME_FIRST.praat` to your own preferences
folder; the file names both paths.

## Run the kit

To run both sides and compare them, follow these steps:

1. In Praat, open `RUN_ME_FIRST.praat` and click **Run**. This takes about
   2 minutes 15 seconds.
2. In RStudio, open `run_analyses.R` and click **Source**. This takes about
   50 seconds.
3. In RStudio, open `compare.R` and click **Source**. This takes about
   3 seconds and prints the verdict.

On this tree, step 3 ends with `GREEN. Every row is accounted for.`

## How the declaration is proved

The claim that both runners read one list is testable, so the kit tests it in
both directions rather than asserting it.

On a throwaway copy of the folder, the test added one row — `c9001`, a
two-group cell using axis values no existing row uses — and deleted another,
`c0157`. Both runners, unmodified, then produced results and a report for
`c9001` and produced nothing at all for `c0157`: no rows, no report file on
either side. The comparison still reported green against the modified
declaration.

A runner carrying its own hidden list would pass the first test and fail the
second.

`matrix.tsv` documents its own columns in its header.

## What the run produces

```
out/praat_results.tsv     9218 rows    long format, source = "praat"
out/r_results.tsv        11812 rows    long format, source = the R package
out/praat_reports/*.txt    630 files   one per cell, human-readable
out/r_reports/*.txt        630 files   one per cell, including refusals
out/reconciliation.tsv                 every row that is not a plain agreement
```

Both tables are long, not wide: `cell_id`, `quantity`, `value`, `source`.
One row per reported quantity, values unrounded and unformatted. A quantity
one side reports and the other does not shows up as an unmatched row rather
than a silent blank, and two packages disagreeing about the same named
quantity are two rows with different `source`.

## The verdict

```
value comparisons made       : 8903

  AGREE         8804   relative difference < 1e-9
  DECLARED      3491   differences and one-sided rows with a written reason
  UNEXPLAINED      0
```

The agreement tolerance is 1e-9 relative. It is not a knob. Two
implementations of the same formula in IEEE double should agree to near
machine precision; anything that does not is a difference worth naming
rather than a tolerance to widen.

DECLARED is not a waste bin. Every entry is a rule in `DECLARED[]` at the
bottom of `compare.R` with a written reason you can read and disagree with.
Two of them carry an asserted numerical bound, checked on every run and
printed with the observed maximum, so they cannot quietly drift:

```
D-PTUKEY            observed max relative difference 3.92e-05, limit 1e-04 -- HOLDS
D-TWOWAY-PRECISION  observed max relative difference 1.22e-08, limit 1e-07 -- HOLDS
```

## Which package supplies which comparison

Every number on the R side comes from a package function -- the one a
statistician calls for that design.

| quantity | R source |
| --- | --- |
| t-test, Mann-Whitney, ANOVA, Kruskal-Wallis, Friedman, Shapiro-Wilk, regression, correlation, chi-square, Wilson interval | `stats` (`t.test`, `wilcox.test`, `aov`, `kruskal.test`, `friedman.test`, `shapiro.test`, `lm`, `cor.test`, `chisq.test`, `prop.test`) |
| Tukey HSD | `stats::TukeyHSD` |
| two-way ANOVA, Type II SS | `car::Anova` |
| repeated-measures ANOVA, Greenhouse-Geisser | `afex::aov_ez` |
| Dunn's test | `rstatix::dunn_test` |
| all-pairs t / Wilcoxon enumeration and estimates | `rstatix::t_test`, `rstatix::wilcox_test` |
| Cohen's d, Hedges' g, rank-biserial r, eta-squared, epsilon-squared, Kendall's W, Cramer's V | `effectsize` **and** `rstatix`, emitted as separate rows |
| descriptives, skewness, kurtosis | `psych` |
| Cronbach's alpha and its Feldt CI | `psych::alpha`, `psych::alpha.ci` |
| every p-value adjustment | `stats::p.adjust` |

The kit computes six effect sizes twice, once from each package,
and never averaged or picked between. Where the two genuinely differ they
appear as two rows with different `source` and the difference is a declared
entry, not a defect to smooth over.

`multcomp`, `nortest` and `coin` are installed, but no cell calls them:
nothing in the declaration needs what they uniquely offer over the
others. They are listed because they were considered.

**Provenance, in two sentences.** Every quantity on the R side is produced
by a package a statistician would reach for anyway, called with the options
that design calls for -- not by a second copy of the plugin's arithmetic
transcribed into R. So when the two sides agree it is a plugin result
matching an independent implementation, not a script agreeing with itself.

One honest qualification. The plugin's own internal helpers -- its
distribution tails, its rank machinery -- are checked against `scipy` and
`pingouin` in this project's CI, not on every local run of this kit. What
you can verify here, on your own machine, is that the plugin agrees with R.
The third-party cross-check exists but you are taking its most recent result
on trust unless you go and look at CI.

## The one expression written by hand

No statistic on the R side is re-derived. Each comes from a package.
`compare.R` would be worthless otherwise -- if the R script
reimplemented the plugin's formulas, agreement would prove only that the
same arithmetic was typed twice.

`run_analyses.R` contains exactly one arithmetic expression that is not a
package call:

```r
pRaw <- 2 * stats::pnorm(-abs(zAll))      # Dunn's raw p, from rstatix's own z
```

`rstatix` rounds every p-value it reports to three significant digits --
hard-wired in its internal `as_tidy_stat(round.p = TRUE, digits = 3)`, with
no user-facing option on `t_test`, `wilcox_test` or `dunn_test`. Rounding is
a display decision and has no business in a comparison table, so no p-value
here is taken from an `rstatix` column. For the tests `stats` also provides,
the p comes from `stats`. Dunn's test has no `stats` equivalent, so the
statistic still comes from `rstatix::dunn_test` and only the two-sided
normal tail is read off it with `stats::pnorm`.

Everything else that looks like arithmetic is an identity between quantities
already reported in the same table -- `mean_diff` as the difference of two
reported means, `u2` as `n1*n2 - u1`, a mean square as `SS/df`, `prop_hat`
as `x/n`, and counts. None of them is a second implementation of a test.

## Reading the reconciliation file

`out/reconciliation.tsv` carries one row per quantity that is not a plain
agreement. Two of its columns tell you how much weight the row's excuse
carries:

- `why` is the rule's stated reason, the same text that appears in
  `DECLARED[]` in `compare.R`.
- `enforcement` says whether that reason is checked. A rule reading
  `BOUND ENFORCED` names the limit the difference must stay under, the
  worst case observed on this run, and whether it holds. A rule reading
  `PROSE ONLY` checks nothing: it argues that a difference is acceptable and
  cannot tell you if it has stopped being so.

Two of the nine rules carry a bound. The other seven do not.

## Scheffe

`D-SCHEFFE` says no installed R package implements Scheffe's test, which is
true of this container and not of CRAN: `DescTools::ScheffeTest` and
`agricolae::scheffe.test` both do. Neither is packaged for Debian, and the
build environment cannot reach CRAN, so the R side evaluates the published
definition instead -- the statistic is `(diff/SE)^2 / (k-1)` and the p-value
comes from base R's own `pf`.

The statistical work is done by `pf`; the rest is the definition. It is still
our arithmetic rather than an independent implementation. Install either
package and compare against `D-SCHEFFE`'s 40 rows if you want a third
answer.

## Potential conflicts with R that may be errors in R

Three quantities where this plugin and an R package disagree, and the
disagreement is not the plugin being wrong. Each is stated so you can check it
rather than take it.

**Paired rank-biserial, when every difference is identical.**
`effectsize` 0.8.6 returns an unsigned result: +1 whether the first column is
uniformly above or uniformly below the second. The definition gives
`(R+ - R-)/(R+ + R-)`, so five differences of -5 give R+ = 0, R- = 15, and the
answer is -1. `wilcox.test`'s own V statistic distinguishes the two directions
correctly.

In every non-degenerate case `effectsize` gets the sign right, so this is
confined to inputs where all differences share one magnitude. Two of the kit's
nine paired comparisons have that property by construction; the five
substantial ones do not.

**Alpha-if-deleted, on a two-item remainder.**
The plugin reports the definitional value; `psych` reports something else.
The derivation, which is short enough to check: item variances 0.5, 0.5, 0.5
and 0; total variance 0.5; `(4/3)(1 - 3) = -8/3` exactly. Both the
definitional and the covariance forms give -8/3.

**The Hodges-Lehmann estimate on the approximation branch.**
This one is not an error in R. It is two defensible definitions disagreeing,
and it is recorded here so you do not spend time diagnosing it.

The estimator is the median of the cross-differences, and that is what the
plugin reports on both branches. On the approximation branch `wilcox.test`
instead returns a `uniroot` of its own W function -- measured about 4e-5 from
R's own exact-branch answer on the same data. This kit oracles the estimate
against `median(outer(x, y, "-"))` and emits R's value beside it under
`posthoc_<PAIR>_diff_wilcoxest`, so the gap stays visible. The interval bounds
still come from `wilcox.test`, because bounds are defined by test inversion
and the estimate is not.

If you disagree with any of the three, that is the most useful thing you can
tell us.

## Findings

The reconciliation found real defects. This section names them rather than
tuning them away. Each carries an id you can grep for in `compare.R` and in
`out/reconciliation.tsv`.

**In the plugin:**

- `D-PARSE`. `rp_r6_parse_conditions_input.csv` contains the cell `"73,4"`.
  Praat's own `number()` primitive reads that as **73**; it stops at the comma
  and drops the fraction. `@emlRunNormalityAnalysis` accepts the cell
  on that basis and reports n=4 including a silently wrong value;
  `@emlRunDescriptiveAnalysis` rejects the same cell and reports n=3. Two
  procedures disagree with each other about one cell in one column of one
  file, and neither reads it as 73.4. The R side applies the documented rule
  and reads 73.4, so these cells stay red on purpose.
- `D-PAIRWISE-N`. `@emlRunPairwiseAnalysis` lists `.stN` in its own Outputs
  header, initialises it to `undefined`, and never assigns it. The procedure
  cannot report the sample size it analysed. The runner previously dropped
  undefined values
  silently, which hid this. Both runners now emit an explicit
  `<quantity>_undefined` marker instead, which is how it surfaced.
- `D-HEDGES`. Hedges' g uses the approximate bias correction
  `J = 1 - 3/(4df-1)`. Hedges (1981) gives the exact
  `J = Γ(df/2) / (√(df/2)·Γ((df-1)/2))` and presents the other as an
  approximation for hand computation. Praat has `lnGamma`, so the exact form
  is available. The error is ~2e-5 relative and changes no conclusion, but
  the published definition is the exact one.
- `D-NOCI` (1500 rows, the largest single entry). No post-hoc comparison in
  the plugin returns a confidence interval -- not Tukey, Dunn, pairwise t,
  pairwise Wilcoxon or Scheffe. Each gives a statistic, a p and an effect
  size.
- `D-NODIFF` (720 rows). `@emlRunPairwiseAnalysis` explicitly marks its
  difference matrix absent for the t and Wilcoxon arms. So the plugin will
  tell you a pair differs, and by how much in standard-deviation units, but
  not by how much in the data's own units.
- `D-TWOWAY-PRECISION`. `@emlRunTwoWayAnalysis` does not compute the two-way
  ANOVA; it parses the text of Praat's built-in `Report two-way anova`,
  which prints SS to about nine significant digits. Every quantity derived
  from those sums inherits the ceiling. The two sides still agree to ~1e-8,
  but this procedure structurally cannot reach machine precision the way
  every other one here does.
- `D-SPEARMAN`. Spearman's p is the large-sample t-approximation on n-2 df.
  `cor.test` returns the exact permutation p for small n without ties. At
  rho = 1 the exact p is 2/n! and the approximation collapses to ~0. Both
  runners also emit `spearman_p_asymptotic`, and *those* agree exactly --
  which is what pins the difference to the choice of tail rather than to
  arithmetic.

**In the R side, found and fixed during this pass** (each made the table
look worse
than the plugin deserved):

- `rstatix::wilcox_effsize` computes r = Z/√N, Rosenthal's r. The kit emitted
  it under the name `rank_biserial`, so two
  different statistics looked like one disagreement -- and because it is
  unsigned, the orientation could
  never be made to match. It is now `wilcox_r`; `effectsize::rank_biserial`
  is the rank-biserial correlation and matches the plugin exactly.
- `rstatix::cramer_v` defaults to Yates-corrected and
  `effectsize::cramers_v` defaults to Bergsma's bias-corrected V. Neither is
  the plain V, and they are not each other. Yates corrects a *test*, not an
  effect size, so the declaration's `correction` axis governs `chisq.test`
  and is deliberately not carried into V. All three values are emitted,
  under names that say which is which.
- `psych::describe` defaults to `type = 3` skewness and kurtosis (the b1/b2
  moment ratios). The estimator meant by the bare word "skewness" in applied
  reporting is `type = 2`, the G1/G2 that SPSS, SAS and Excel compute. Both
  are emitted; the type-3 values keep their own names so the choice is
  visible in the data and not only in a comment.
- `afex` returns `GG eps = NA` when it cannot compute a Greenhouse-Geisser
  correction, but prints `Pr(>F[GG])` as `0` in the same row. That 0 is a
  sentinel, not a p-value, and the R side emitted it as one.
- `effectsize` 0.8.6 returns an *unsigned* paired rank-biserial when every
  paired difference has the same magnitude: +1 whether the first column is
  uniformly above or uniformly below the second. `wilcox.test`'s V correctly
  distinguishes the two. This is an upstream bug; the sign is restored where
  the direction is not in doubt, and the workaround is commented at the site.
- Both runners silently dropped non-finite values, and the R side wrote
  `%.15g` where `%.17g` is needed to round-trip a double. Both are
  fixed; the first is what exposed `D-PAIRWISE-N`.

**In `matrix.tsv`, reported and not edited:** nine cells marked `expect=ok`
are refused by *both* implementations -- c0375, c0381, c0492-c0494,
c0528-c0531. Each is a degenerate fixture (perfectly additive columns, or
n=2), and in several cases the row's own `note` column already names the
degeneracy that causes the refusal. The `expect` annotation looks like the
thing to correct, not either runner. `RUN_ME_FIRST.praat` prints all nine at
the end of every run.

## Three questions for you

1. What dataset would you construct that you think would break this --
   expose a wrong number, not an ugly one?
2. Where in `run_analyses.R` would you have written the statistics
   differently, and why?
3. If you handed a paper using this kit to a reviewer, what would they still
   not accept about how these numbers were produced or reported?
