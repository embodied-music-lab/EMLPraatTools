# Memo to Fable — the post-hoc intervals, scoped

Executing session, 26 August 2026, against `d33e123`. Ian's decision of the
same day: Josh installs the plugin rather than running a flattened copy, so
the kit now measures the shipped library and every gap it finds is a gap a
user has.

This memo scopes one such gap. It needs a ruling because closing it changes
what the reports show, which is 1.0 scope rather than conformance.

## What was found, and how

The kit compares 630 analysis runs against R. An exemption rule, `D-NOCI`,
excused 1,500 rows on the claim that no post-hoc comparison in the plugin
returns a confidence interval.

**That claim is false for Tukey and true for everything else.** The audit
established both halves by driving, not by reading:

- `@emlDeclareTukeyResult` computes the interval from `qCritical` and
  `msWithin` and EXPORTS it as `conf.low` / `conf.high`. Driven across all 21
  ANOVA+Tukey cells and 72 pairs against R's `TukeyHSD`: **max relative
  difference 4.26e-13, nothing outside 1e-9.** Those 144 rows were unemitted
  agreement, not a gap. `docs/OPEN_ITEMS.md` and `docs/RULING_TUKEY_ALPHA.md`
  had both already treated that interval as an existing feature.
- The remaining 1,356 rows are genuinely absent, across three procedures.

## The three absences, and they are not equally hard

**Pairwise t — 864 rows (432 Welch, 432 Student). SMALL.**
`@emlPairwiseT` calls `@emlTTest` per pair. `@emlTTest` exposes `.meanDiff`,
`.df` and `.t` but no interval, so the standard error is already recoverable
as `.meanDiff / .t`. `invStudentQ` is available and this exact shape is
already built in `@emlDescriptive` (`stats/eml-core-descriptive.praat:573`),
including the documented trap that `invStudentQ(0, df)` never converges and
hangs the script. This is adding two outputs using a pattern that exists two
files away. R's `t.test` returns the interval by default, so the oracle is
free.

**Pairwise Wilcoxon — 432 rows. REAL WORK.**
The standard answer is the Hodges-Lehmann estimator with its interval — the
median of the pairwise differences, bounds from the rank distribution.
Nothing in the plugin computes it. R's `wilcox.test(conf.int = TRUE)` returns
it, so the oracle is free, but the procedure is new and needs its own
validator.

**Repeated-measures post hoc — 60 rows. NOT ASSESSED.**
`@emlRMPostHoc` keeps only `.rawP#` and `.adj#`. Whether an interval is
standard here depends on which post hoc it runs; I have not established it.

**Dunn — no ruling needed.** Intervals are not standard practice for Dunn.
This one stays absent and gets documented rather than built.

## Why this is scope and not a defect fix

Every other item on the current parse and conformance list brings an outlier
into line with a canon that already exists. This does not: no plugin
procedure other than Tukey has ever reported a post-hoc interval, so adding
one changes what a report contains. That is a 1.0 scope decision.

The asymmetry is also visible to a user today. Run ANOVA with Tukey and the
report states a range for each pair. Run the same comparison as pairwise t
and it does not.

## The questions

1. **Does pairwise t gain the interval for 1.0?** Small, precedented, oracle
   free.
2. **Does pairwise Wilcoxon gain Hodges-Lehmann for 1.0**, or is it deferred?
   New procedure, new validator, oracle free.
3. **Is the repeated-measures post hoc in or out of the question**, given I
   have not established what is standard there?
4. **Where an interval is added, does the alpha in force govern it**, as
   `docs/RULING_TUKEY_ALPHA.md` settled for Tukey? Assumed yes; stated so it
   is not assumed silently.

## What proceeds regardless

`D-NOCI` is retired and split in the kit already. The 144 Tukey rows are
compared rather than excused, and the 1,356 genuinely absent rows are
accounted for by the quantity contract rather than by an exemption. Nothing
in the kit waits on this ruling.

— executing session
