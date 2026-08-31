# Reader sentences — one register for three files

Drafted 27 August 2026 under Fable's two-register ruling. Every clause carries
two texts: the working `why` that lives in `compare.R` and the reconciliation,
and the reader sentence below. `SUMMARY.md`, `exceptions.tsv` and
`disagreements_all.tsv` all draw the reader sentence, so the three files can
never say different things about one clause.

A clause with no reader sentence here is a hard error at generation. Grouping
is an edit to this file, never to code.

Sentences are keyed by the clause they serve. Declared clauses key by id;
contract clauses key by the `procedure` and `quantity` pattern that identifies
them in `quantities.tsv`, because every contract row shares the single id
`CONTRACT`.

---

## pairwise-interval-scope
Rows: ~903. The plugin prints a pairwise confidence interval only under a
correction that defines one -- Tukey, Scheffe, or Bonferroni at its per-pair
level. Holm and Benjamini-Hochberg define no per-pair level, so on those rows
R's interval stands alone by design.

## r-shift-estimate
Rows: 261. R's `wilcox.test` reports a shift estimate found by searching its
own test statistic, which differs slightly from the textbook Hodges-Lehmann
definition. The plugin computes the definition, that quantity is compared, and
R's search result is recorded beside it rather than imitated.

## rank-test-effect-size
Rows: 160. For the Kruskal-Wallis test R reports eta-squared and the plugin
reports epsilon-squared. Both summarise the same effect, neither is derivable
from the other, and each side reports its own choice.

## extra-shape-statistics
Rows: 158. R's `describe` emits a second pair of skewness and kurtosis values
using a different estimator from the one both programs already agree on. The
plugin reports one estimator; R reports two, and the second has no counterpart
here.

## studentised-range-statistic
Rows: 72. The q statistic is part of how the plugin computes Tukey's test, and
R's `TukeyHSD` does not report it. It is listed rather than dropped so nothing
computed goes unrecorded.

## correlation-intermediates
Rows: 66. Each program exposes the working quantities its own method produces
-- R the S statistic from its exact method, the plugin the t and degrees of
freedom from its approximation. The p-values they lead to are compared; the
intermediates have no counterpart.

## sphericity-correction
Rows: 32. The plugin reports the Greenhouse-Geisser correction on every
repeated-measures analysis. With two conditions there is one degree of freedom
and sphericity holds trivially, so the correction has nothing to do and R does
not report it.

## paired-excluded-rows
Rows: 22. R reports how many rows it dropped for missing values; the plugin's
paired analysis does not expose that count. The analyses themselves use the
same rows.

## two-way-precision
Rows: 18. The plugin reads Praat's own printed ANOVA table, which carries about
nine significant digits, so every quantity derived from those sums inherits
that ceiling.

## refusal-wording
Rows: 17. Where data cannot be analysed, both programs refuse the same
analyses and each writes its refusal in its own words. That the same analyses
refuse is checked separately.

## rosenthal-r
Rows: 16. R reports Rosenthal's r, which is the test statistic divided by the
square root of the sample size. It is not the rank-biserial correlation the
plugin reports, and there is nothing to compare it against.

## second-rank-effect-size
Rows: 16. Where the nonparametric test runs, R's package emits its own
effect-size variant alongside the one both programs share. Only the shared one
is compared.

## cramers-v-corrected
Rows: 16. R's package emits two corrected variants of Cramer's V by default --
the Yates correction and Bergsma's bias correction -- each under a name that
says which. The plugin reports the uncorrected V, which is compared.

## tukey-tail-quadrature
Rows: 14. The q statistics match R exactly. The p-values derived from them
differ only below 0.00001, because the two programs evaluate the
studentised-range distribution differently in the far tail. Worst case is
0.13% at p about 5e-12, which is no difference at any usable significance
level.

## hl-interval-scope
Rows: 13. The plugin fills the interval around its shift estimate only under
Bonferroni, where a per-pair level exists. On other corrections it prints the
estimate without an interval.

## spearman-p-naming
Rows: 11. When a correlation runs both tests, each program files the Spearman p
under a different name -- R under the plain name, the plugin under a qualified
one. The values are compared where the names line up.

## paired-parametric-absent
Rows: 9. On a nonparametric-only paired analysis neither program computes the
paired t, its degrees of freedom, or Cohen's dz. Both mark them undefined;
only the marker names differ.

## friedman-all-identical
Rows: 7. In this fixture all six subjects give 80 for all three conditions, so
the Friedman test has no differences to rank. The plugin reports what the
formula gives on that input -- a statistic of zero and a p of one -- while R
declines to compute anything. Both are saying the same thing: there is nothing
here to detect.

## two-way-eta-squared-gap
Rows: 6. R reports both the partial and non-partial forms of eta-squared per
term; the plugin reports partial only. A known coverage gap, listed rather
than hidden.

## grouped-regression-adjusted-r2
Rows: 6. The plugin reports adjusted R-squared on ungrouped regression but not
on the grouped path. Another coverage gap.

## constant-column-mean-interval
Rows: 6. Every descriptive analysis owes a confidence interval for the mean.
Where a column has no variance R's `t.test` refuses, and the R side records
that refusal instead of a number.

## alpha-two-item-scale
Rows: 6. Removing one of two items leaves a single item, for which alpha is
undefined. The plugin prints an undefined marker; R does not attempt the
quantity. Same statement, two spellings.

## kendalls-w-derived
Rows: 3. The plugin computes Kendall's W at the point it assembles results
rather than inside the test itself, so it appears on some rows where R's own
output has no place for it.

## alpha-three-person-sample
Rows: 2. Dropping one respondent leaves two, and one item then has no
variance. R's package deletes that item and computes on the rest; the plugin
keeps it. The plugin matches the textbook formula, which gives -8/3 exactly.

## pairwise-oracle-cross-check
Rows: ~432. Holm and Benjamini-Hochberg correction define no per-pair
confidence level, so there is no interval for the plugin or R to print here
(see pairwise-interval-scope). In its place R checks itself: the adjusted
p-value from its primary per-pair test is compared against a second,
independent computation, `stats::pairwise.t.test` with unpooled variances,
run down its own code path. R verifying R; the plugin has no counterpart,
and none is owed.

## sweep
Rows: ~32. This row belongs to the sweep study, a grid of group-count and
imbalance shapes that is otherwise checked against R exactly like any other
analysis. Here the plugin side of this particular shape was not run in this
pass, so there is nothing on that side to set beside R's value yet; it is
listed as incomplete, not as a documented difference between the two
programs.

## nist
Rows: ~99. This row belongs to the NIST study, which is never checked
against R at all -- it is checked directly against a published reference
number instead, in its own part of the report. Here the plugin side of this
particular case was not run in this pass, so there is no plugin value yet to
set beside that published number; it is listed as incomplete, not as a
disagreement with the reference.
