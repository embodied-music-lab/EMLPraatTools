# Memo to Fable — the kit's exemption rules, and one contract clause

Executing session, 27 August 2026, against `c13f6b1`. Two separate things: a
change I intend to make, and four rules I want your ruling on before touching.

## What the kit now shows

The six plugin items reached the kit. **1,615 rows moved from excused to
compared, and every one of them agrees.** Those are the point differences and
intervals on the pairwise and repeated-measures arms, Hedges' g at its exact
correction, and the pairwise sample size that used to report undefined.

The balance invariant is built and holds. It computes its total a second,
independent way rather than by summing its own three counts, so the arithmetic
can genuinely disagree. Building it exposed two silent drops in the
reconciliation itself — a repeated one-sided key had only its first row
inspected, and a duplicate on a shared key had no handling at all. Both were
losing rows with no trace. Both now surface.

Each runner takes a procedure filter. An unfiltered run is byte-identical to
before.

**The run is not green: 258 rows unexplained.**

## The change I intend to make, stated for your objection

All 258 are one R-side quantity, `posthoc_<PAIR>_diff_wilcoxest` — R's own
`wilcox.test$estimate` on the Wilcoxon approximation branch. **It exists
because you required it**: your definition-over-implementation ruling says the
estimate follows the published definition and R's value is reported beside it.

The quantity has no clause in `quantities.tsv` and no rule in `DECLARED[]`, so
the comparison finds a quantity with no home and calls it unexplained. That is
correct behaviour.

**The fix is one contract clause declaring it R-side**, present on the
Wilcoxon arms, citing the definition-over-implementation rule already in that
file. It moves 258 rows from unexplained to documented-absent, which is what
they are.

It is a contract clause and not a rule because there is no difference to
excuse: **Praat never emits this quantity and should not.** It is R's
implementation artefact, not a statistic the plugin computes. A `DECLARED[]`
rule excuses a difference between two values, and there is no second value.

Say if you would rather it were a rule, or would rather the R side stopped
emitting it.

## Four rules I have not touched, and want ruled

An adversarial audit tested every `DECLARED[]` rule as a claim to falsify. It
found the list is **22 rules, not the 14 I had described** — eight exist that
neither of us has examined — and that **five are false**.

You have already endorsed retiring `D-NOCI`. These four are the rest, and you
have not seen them.

**`D-SCHEFFE` — 216 rows. The largest and the worst.**
Its claim is that no R package implements Scheffe's test. TRUE: the audit
enumerated exports across all 178 installed packages and found only
`lava::scheffe`, a confidence band for a regression prediction rather than the
pairwise post hoc. But the rule's own text concedes "rather than hand-deriving
the Scheffe F", so the audit derived it — base `stats` only,
`pf(F, k-1, N-k, lower = FALSE)` against the plugin's own formula. **All 216
rows matched, maximum relative difference 7.74e-15.**

The direction is what matters. **216 rows of an entire test arm currently have
no oracle at all.** The plugin's Scheffe is right, nothing was checking, and if
it drifted tomorrow the rule would keep excusing it.

**`D-TUKEYQ` — 72 rows.** Same shape. `stats::TukeyHSD` genuinely does not
expose q, but q is `|diff| / sqrt(MSE/2 (1/ni + 1/nj))` from quantities R
already has. Derived for every ANOVA+Tukey cell: **72 of 72 matched, maximum
relative difference exactly zero — bit-identical doubles.** A true statement
about one R function, used to justify leaving 72 plugin numbers unchecked.

The audit also found this rule does not assert the bound the earlier brief
claimed it did.

**`D-MINOR` — 28 rows, false on both limbs.** It says
`@emlRunPairedAnalysis` exposes no excluded-row count; `eml-analysis.praat:2536`
assigns one, and driven against R's `n_excluded` it matches on every cell — 22
rows would agree. It also says `@emlRunGroupedRegressionAnalysis` exposes no adjusted
R-squared; the plugin computes it and the runner already reaches it.

**`D-WILCOXR` — 32 rows. False reason, but the rows stay excused.** The claim
"has no plugin counterpart" is false for half of them: `@emlMatchedPairsR`
publishes `.rZ`, Rosenthal's Z/sqrt(N), named for the same paper as
`rstatix::wilcox_effsize`. But driven on the kit's own fixture it returns
undefined on the exact path, so the counterpart exists and produces nothing
comparable. The rows stay out; the reason needs rewriting.

## The question

Retiring a false rule converts its rows to comparisons. `D-SCHEFFE` and
`D-TUKEYQ` together are 288 rows that currently have no oracle and, on the
audit's evidence, agree to machine precision. `D-MINOR` is 28 more.

Do those three retire, with their rows compared? Does `D-WILCOXR` keep its
rows excused under a corrected reason?

And: **eight rules have never been examined.** The audit named them —
`D-WORDING` 17, `D-CRAMER` 16, `D-PTUKEY` 14, `D-FRIEDMAN-DEGEN` 9,
`D-ALPHA2ITEM` 6, `D-CONSTCI` 6, `D-TWOWAY-ETA` 6, `D-ALPHADROP` 2. Do you
want them audited on the same terms before the kit ships?

— executing session
