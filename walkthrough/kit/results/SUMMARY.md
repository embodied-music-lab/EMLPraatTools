# Validation summary — EML Stats & Graphs against R

Run 28 August 2026. Verdict: **NOT GREEN — see results/reconciliation.tsv**.

## What was compared

The kit ran 624 analyses through 17 of the plugin's statistical procedures, and ran the same 624 analyses in R. It then compared 10841 numerical results.

**10792 of 10841 agree** to at least nine significant digits (values at machine zero are compared absolutely, below 1e-12). The rest are listed in full in `exceptions.tsv` and `disagreements_all.tsv`, one row each, with the reason beside the numbers. There are no unexplained differences: an accounting identity inside the comparison proves every quantity from both programs landed in exactly one category (the balance invariant in `audit/VERDICT.txt`), and the run fails loudly if one ever doesn't.

## The documented differences, in plain terms

**Pairwise Oracle Cross Check (432).** Holm and Benjamini-Hochberg correction define no per-pair confidence level, so there is no interval for the plugin or R to print here (see pairwise-interval-scope). In its place R checks itself: the adjusted p-value from its primary per-pair test is compared against a second, independent computation, `stats::pairwise.t.test` with unpooled variances, run down its own code path. R verifying R; the plugin has no counterpart, and none is owed.

**R Shift Estimate (261).** R's `wilcox.test` reports a shift estimate found by searching its own test statistic, which differs slightly from the textbook Hodges-Lehmann definition. The plugin computes the definition, that quantity is compared, and R's search result is recorded beside it rather than imitated.

**Rank Test Effect Size (160).** For the Kruskal-Wallis test R reports eta-squared and the plugin reports epsilon-squared. Both summarise the same effect, neither is derivable from the other, and each side reports its own choice.

**Extra Shape Statistics (158).** R's `describe` emits a second pair of skewness and kurtosis values using a different estimator from the one both programs already agree on. The plugin reports one estimator; R reports two, and the second has no counterpart here.

**Studentised Range Statistic (72).** The q statistic is part of how the plugin computes Tukey's test, and R's `TukeyHSD` does not report it. It is listed rather than dropped so nothing computed goes unrecorded.

**Correlation Intermediates (66).** Each program exposes the working quantities its own method produces -- R the S statistic from its exact method, the plugin the t and degrees of freedom from its approximation. The p-values they lead to are compared; the intermediates have no counterpart.

**Sphericity Correction (32).** The plugin reports the Greenhouse-Geisser correction on every repeated-measures analysis. With two conditions there is one degree of freedom and sphericity holds trivially, so the correction has nothing to do and R does not report it.

**Hl Interval Scope (26).** The plugin fills the interval around its shift estimate only under Bonferroni, where a per-pair level exists. On other corrections it prints the estimate without an interval.

**Paired Excluded Rows (22).** R reports how many rows it dropped for missing values; the plugin's paired analysis does not expose that count. The analyses themselves use the same rows.

**Two Way Precision (18).** The plugin reads Praat's own printed ANOVA table, which carries about nine significant digits, so every quantity derived from those sums inherits that ceiling.

**Cramers V Corrected (16).** R's package emits two corrected variants of Cramer's V by default -- the Yates correction and Bergsma's bias correction -- each under a name that says which. The plugin reports the uncorrected V, which is compared.

**Rosenthal R (16).** R reports Rosenthal's r, which is the test statistic divided by the square root of the sample size. It is not the rank-biserial correlation the plugin reports, and there is nothing to compare it against.

**Second Rank Effect Size (16).** Where the nonparametric test runs, R's package emits its own effect-size variant alongside the one both programs share. Only the shared one is compared.

**Refusal Wording (15).** Where data cannot be analysed, both programs refuse the same analyses and each writes its refusal in its own words. That the same analyses refuse is checked separately.

**Tukey Tail Quadrature (14).** The q statistics match R exactly. The p-values derived from them differ only below 0.00001, because the two programs evaluate the studentised-range distribution differently in the far tail. Worst case is 0.13% at p about 5e-12, which is no difference at any usable significance level.

**Constant Column Mean Interval (12).** Every descriptive analysis owes a confidence interval for the mean. Where a column has no variance R's `t.test` refuses, and the R side records that refusal instead of a number.

**Spearman P Naming (11).** When a correlation runs both tests, each program files the Spearman p under a different name -- R under the plain name, the plugin under a qualified one. The values are compared where the names line up.

**Paired Parametric Absent (9).** On a nonparametric-only paired analysis neither program computes the paired t, its degrees of freedom, or Cohen's dz. Both mark them undefined; only the marker names differ.

**Alpha Two Item Scale (6).** Removing one of two items leaves a single item, for which alpha is undefined. The plugin prints an undefined marker; R does not attempt the quantity. Same statement, two spellings.

**Grouped Regression Adjusted R2 (6).** The plugin reports adjusted R-squared on ungrouped regression but not on the grouped path. Another coverage gap.

**Two Way Eta Squared Gap (6).** R reports both the partial and non-partial forms of eta-squared per term; the plugin reports partial only. A known coverage gap, listed rather than hidden.

**Friedman All Identical (4).** In this fixture all six subjects give 80 for all three conditions, so the Friedman test has no differences to rank. The plugin reports what the formula gives on that input -- a statistic of zero and a p of one -- while R declines to compute anything. Both are saying the same thing: there is nothing here to detect.

**Kendalls W Derived (3).** The plugin computes Kendall's W at the point it assembles results rather than inside the test itself, so it appears on some rows where R's own output has no place for it.

**Alpha Three Person Sample (2).** Dropping one respondent leaves two, and one item then has no variance. R's package deletes that item and computes on the rest; the plugin keeps it. The plugin matches the textbook formula, which gives -8/3 exactly.

## Run it yourself

1. Open `RUN_ME_FIRST.praat` in Praat and run it.
2. Source `run_analyses.R` in R.
3. Source `compare.R`. It prints this verdict and rewrites this folder.

The full row-by-row working record, including the two raw result tables
and `VERDICT.txt`, is in `audit/`; every per-analysis report from both
programs is in `results/praat_reports/` and `results/r_reports/`.
