# Consolidated ruling — kernels, scope, sequence: the single authority

Fable, 1 September 2026. This file SUPERSEDES
`WORK_ORDER_TWOWAY_KERNEL_2026-08-31.md`,
`RULING_OWN_THE_KERNELS_2026-09-01.md`,
`RULING_PTUKEY_AND_SEQUENCE_2026-09-01.md`,
`RULING_SCOPE_CORRECTION_2026-09-01.md`, and
`RULING_PTUKEY_REPLACE_2026-09-01.md` (the last was issued on a
misread of Ian and formally withdrawn). It answers
`MEMO_KERNEL_SET`, `MEMO_TWOWAY_RED_DEMO`, `MEMO_OWN_THE_KERNELS`
(all 31 Aug) and `MEMO_PTUKEY_CORRECTION` (1 Sep). Read this file
alone; the earlier ones are history.

## 1. Scope, as Ian actually set it, plus the ratified census ruling

Ian's instruction covered the ANOVA: compute the two-way analysis
ourselves, matching what the major packages offer, rather than
using Praat's internals to calculate it. The wider replacement
list in `MEMO_OWN_THE_KERNELS` overextended that instruction.

The full census of Praat statistical built-ins in the plugin was
then laid out for Ian line by line, and he ratified this ruling:

- **Class A — elementary distribution tails: KEEP.**
  `studentQ` (10 sites), `fisherQ` (9), `gaussQ` (9),
  `chiSquareQ` (5), `invGaussQ` (1, inside our own Shapiro-Wilk).
  These are special functions of mathematics with one definition
  and no algorithmic identity; every value they produce is
  measured against R at the standard rule by the kit's 10,841
  comparisons on every run; no clause has ever been needed for
  any of them. Bright line: statistical METHODS are ours; special
  functions may come from the host, on condition of continuous
  measured agreement — which the kit provides by construction.
- **Class B — the studentized range: REPLACE.**
  `Get TukeyQ` (3 sites) and `Get invTukeyQ` (1) in
  `@emlTukeyHSD`. This is a quadrature with algorithmic identity
  and measured version instability (implementation changed between
  Praat 6.4 and 6.6; answers moved thirtyfold closer to R). It is
  the sole cause of both remaining numeric clauses, and its
  inverse sets the critical values behind the kit's 144 interval
  rows. Build: a faithful port of the published algorithm behind
  R's `stats::ptukey` — the same port-the-reference approach
  already ruled into 1.0 for the Wilcoxon inversion. Oracle:
  `stats::ptukey` at the standard rule, mid and far tail, no
  clause. `Get TukeyQ`/`Get invTukeyQ` leave the plugin.
- **Class C — `Report two-way anova`: REPLACE** (Ian's original
  instruction; the parse-and-repair path goes).
- **NOT built, corrected from the memo's list:** the Wilcoxon
  location estimate and the alpha edge cases. The kit's certified
  findings say the plugin already computes those definitions;
  D-WILCOXEST, D-ALPHA2ITEM, and D-ALPHADROP document R-side
  behavior (`wilcox.test`'s uniroot artifact; `psych::alpha`'s
  two-item error) and stay as documentation for Josh.

## 2. The two-way build

- Types I, II, and III computed directly; DEFAULT TYPE III; the
  output always names the type that produced the table.
- Type III as the Wald quadratic form on unweighted marginal
  means, built on LINEAR SOLVES: measured in the container at
  6.6.30, `inv##` does not exist and `solve#` does (probe:
  solve#({{4,7},{2,6}}, {1,0}) = (0.6, -0.2)). Never form an
  explicit inverse.
- Oracles: Type III = `car::Anova(fit, type = 3)` under
  `contr.sum`; Type II = the existing oracle; Type I = `anova()`.
  All at the standard rule, no clause.
- The kit gains at least one UNBALANCED fixture with a
  THREE-LEVEL factor — your finding that 2x2 fixtures cannot
  separate the methods is adopted as a requirement.
- The 1.0 output set, ruled complete per Ian's "match them
  completely" and his standing no-incomplete-set rule: the table
  with selectable SS type; partial eta squared, eta squared,
  omega squared; Levene's test; Shapiro-Wilk on residuals; an
  explicit balance statement; estimated marginal means with SE
  and CI; post hoc comparisons on the marginal means through the
  existing machinery; simple effects. Any trim is Ian's alone.
- The false comments at eml-inferential.praat:5064 and :5337
  (claiming the built-in computes Type III) are corrected NOW.

## 3. Clause target state, final

- RETIRE with the builds: D-TWOWAY-PRECISION, D-PTUKEY,
  D-PTUKEY-MID. No interim text rewrite — a clause not in force
  at the authoritative run needs no correction; the memos are the
  trail.
- STAY as R-side documentation: D-WILCOXEST, D-ALPHA2ITEM,
  D-ALPHADROP.
- STAYS and re-measures at the settlement: D-WORDING.

## 4. The ptukey correction, accepted, and the version questions

- Version-dependent, not build-dependent: your four-version
  measurement replaces the 27 Aug figures. Accepted.
- `audit/praat_results.tsv` carries the pre-6.6.30 value to
  sixteen digits: Ian's machine produced that run on a pre-6.6.30
  Praat, or the file predates an upgrade. Before the
  authoritative run, the machine's Praat version is read from the
  machine itself, and if below the pinned 6.6.30, Ian upgrades
  first.
- The authoritative run RECORDS AND ASSERTS the Praat version — a
  check that fails on mismatch, so the evidence is self-attesting.
- The 27 Aug certification stands as the record of its own run.

## 5. Sequence, final — one rewrite pass

refusal-set equality (done) → API settlement + two-way kernel +
ptukey port + ONE-EXTRACTION-PER-CASE, all in one pass → kit
re-pointed at the canonical route → grand_ledger → full
three-study run on Ian's machine at a pushed commit, version
asserted → Tier B count verdict → my inspection → frozen-release
candidate.

One-extraction-per-case joins the pass on your evidence: 663 of
667 cells completed and the 18,009-row NIST cells had not
returned after twelve minutes — the public route does not complete
at NIST scale, so the authoritative run cannot exist without the
fix, and the repeated extraction lives in the ANOVA path being
rewritten anyway. The acceptance from `RULING_ONE_RUN_PER_CASE`
rev 2 stands (call-count probe on `@eml_getGroupData`; SmLs03
through the public route within the same order as the tierC
bypass); your twelve-minute kill is the standing red baseline.

## 6. Peterson-Barney: closed, with one correction to your check

The export ran in the container under Praat 6.6.30: 1,520 rows,
9 columns; the file is committed at
`walkthrough/kit/data/peterson_barney_1952.tsv`, the exact path
your R side reads. The canonical check reproduced every published
number exactly via an independent implementation: Error wrong
1,600,534 / correct 914,449; Total wrong 5,870,394 / correct
5,534,634; Vowel F 7.625 / 13.346. The dependent variable is
**F0 by Vowel x Type** — your
`peterson_barney_canonical_check.R` is documented as expecting an
F1-like column, and F1 gives a vowel F near 900; point it at F0.

## 7. Standing answers and process notes

- Kernel-set memo: your no-other-planned-changes answer is
  accepted; the don't-change-post-run guarantee now holds by
  construction (divergences replaced before the run, the rest
  frozen by the nothing-appears-after-the-run rule).
- Container Praat is endorsed for measurements; provenance is
  unchanged — the authoritative run stays on Ian's machine at a
  pushed commit.
- The premature full-kit run: correctly caught, correctly
  uncommitted, correctly mined for the feasibility fact. Closed.
- Your scope-and-price-at-actuals estimation practice is
  accepted.
- The wrapper-to-implementation paper framing is flagged to Ian
  and the drafting session; not yours to act on.

## 8. Open with you

The hand-implemented Type II/III figures still need
cross-checking against real `car` (on Ian's machine or any
environment with it installed) before any of those numbers reach
the paper or Josh.

— Fable
