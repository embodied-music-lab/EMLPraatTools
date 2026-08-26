# EML Stats & Graphs -- walkthrough kit

This folder is self-contained. Nothing is installed anywhere, nothing else
needs cloning, and there is no Praat plugin to install.

Three files are meant to be run, in this order:

1. `RUN_ME_FIRST.praat` -- open in Praat, click Run. About 2m15s.
2. `run_analyses.R` -- open in RStudio, click Source. About 50 seconds.
3. `compare.R` -- open in RStudio, click Source. About 3 seconds.

The third one prints the verdict. On this tree it ends with `GREEN. Every
row is accounted for.`

For R you need eight packages, once:

```r
install.packages(c("rstatix","effectsize","car","afex","multcomp","nortest","coin","psych"))
```

Praat must be 6.6.30 or newer; the library refuses to load below that.

## What this is

630 declared cells. 17 procedures, 29 datasets, and every combination of
test / post-hoc / adjustment / equal-variance / group-order that the
plugin's own dialogs can produce. Two independent implementations run all
630: the actual plugin code, and an R script that calls installed packages.
Then the two result tables are joined on `(cell_id, quantity)` and every
single row has to be accounted for.

The point is not that the plugin computes a t-test. It is that a large set
of procedures *combine* correctly -- that choosing Welch rather than
Student, then Holm rather than Bonferroni, then alphabetical rather than
discovery group order, changes exactly the numbers it should and nothing
else. Group order is a real axis, not a formality: on `v11_twoway_input`,
SPL_dB by voice_type, discovery order gives t = 3.9024 and alphabetical
gives t = -3.9024, and that sign reaches Cohen's d, rank-biserial r and
every pairwise mean difference.

15 of the 630 cells are declared to *refuse*. A refusal that happens
correctly is evidence, so those are checked as strictly as the rest: both
sides must refuse the same cell, and neither may emit a number while doing
it.

## The declaration: `matrix.tsv`

Neither runner carries its own list of what to run. Both read `matrix.tsv`,
one row per cell. Read its header; the columns are documented there.

That is the design, not an implementation detail: a cell that exists for one
language and not the other cannot happen, because there is only one list.

Both directions of that property are tested, not asserted. On a throwaway
copy of this folder, one row was appended (`c9001`, a two-group cell with
axis values no existing row uses) and one row was deleted (`c0157`). Both
runners, byte-for-byte unmodified, then produced results and a report for
`c9001` and produced nothing at all for `c0157` -- no rows, no report file
in either `out/praat_reports/` or `out/r_reports/`. `compare.R` still
reported GREEN on the modified declaration. The second direction is the one
that matters: a runner carrying its own hidden list would pass the first
test and fail this one.

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
quantity are simply two rows with different `source`.

## The verdict

```
value comparisons made       : 8903

  AGREE         8804   relative difference < 1e-9
  DECLARED      3491   differences and one-sided rows with a written reason
  UNEXPLAINED      0
```

The agreement tolerance is 1e-9 relative and is not a knob. Two
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

Every number on the R side comes from a package function, chosen because it
is the one a statistician would call for that design.

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

Six effect sizes are deliberately computed twice, once from each package,
and never averaged or picked between. Where the two genuinely differ they
appear as two rows with different `source` and the difference is a declared
entry, not a defect to smooth over.

`multcomp`, `nortest` and `coin` are installed and loaded but no cell calls
them: nothing in the declaration needs what they uniquely offer over the
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

## Only one thing is written out by hand

The rule on the R side is that no statistic is re-derived; each is called
from a package. `compare.R` would be worthless otherwise -- if the R script
reimplemented the plugin's formulas, agreement would prove only that the
same arithmetic was typed twice.

There is exactly one arithmetic expression in `run_analyses.R` that is not a
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

## Findings

The reconciliation found real defects. They are listed here rather than
tuned away, and each has an id you can grep for in `compare.R` and in
`out/reconciliation.tsv`.

**In the plugin:**

- `D-PARSE`. `rp_r6_parse_conditions_input.csv` contains the cell `"73,4"`.
  Praat's own `number()` primitive reads that as **73** -- it stops at the
  comma and drops the fraction. `@emlRunNormalityAnalysis` accepts the cell
  on that basis and reports n=4 including a silently wrong value;
  `@emlRunDescriptiveAnalysis` rejects the same cell and reports n=3. Two
  procedures disagree with each other about one cell in one column of one
  file, and neither reads it as 73.4. The R side applies the documented rule
  and reads 73.4, so these cells stay red on purpose.
- `D-PAIRWISE-N`. `@emlRunPairwiseAnalysis` lists `.stN` in its own Outputs
  header, initialises it to `undefined`, and never assigns it. The procedure
  cannot report the sample size it analysed. This went unnoticed because the
  runner used to drop undefined values silently; both runners now emit an
  explicit `<quantity>_undefined` marker instead, which is how it surfaced.
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

**In the R side, found and fixed during this pass** (they were making the
table look worse than the plugin deserved):

- `rstatix::wilcox_effsize` computes r = Z/√N, Rosenthal's r. It was being
  emitted under the name `rank_biserial`, so two different statistics looked
  like one disagreement -- and because it is unsigned, the orientation could
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
  sentinel, not a p-value, and it was being emitted as one.
- `effectsize` 0.8.6 returns an *unsigned* paired rank-biserial when every
  paired difference has the same magnitude: +1 whether the first column is
  uniformly above or uniformly below the second. `wilcox.test`'s V correctly
  distinguishes the two. This is an upstream bug; the sign is restored where
  the direction is not in doubt, and the workaround is commented at the site.
- Both runners were silently dropping non-finite values, and the R side was
  writing `%.15g` where `%.17g` is needed to round-trip a double. Both are
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
   expose a wrong number, not just an ugly one?
2. Where in `run_analyses.R` would you have written the statistics
   differently, and why?
3. If you handed a paper using this kit to a reviewer, what would they still
   not accept about how these numbers were produced or reported?
