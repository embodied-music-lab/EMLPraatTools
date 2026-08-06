# Correction — external-validation coverage was mismeasured

> **HISTORICAL RECORD.** This document describes the state of the project on
> the date in its title. It is kept for provenance and is **not** a status
> surface. Do not resume work from it and do not treat its queue, its counts,
> or its instructions as current.
>
> **Current status lives in exactly one place: `audit/FINDINGS_INDEX.md`
> (the rows, not the header prose), with the reasoning in
> `audit/PHASE_ONE_AUDIT_2026-08-06.md`.**

Date: 4 August 2026
Supersedes: the "5% externally validated" figure stated in conversation
on 4 August 2026. That figure is **withdrawn**. It was wrong.

## What I said and why it was wrong

I reported that 16 of 317 procedures (5%) had external validation. I
produced that number with this command:

    cd dev/tests/phase2
    while read p; do
      if grep -qiE "${p}" verify-*.R verify-*.py; then echo "$p" >> ext.txt; fi
    done < pub.txt

That greps each **Praat procedure name** as a literal string inside the R
and Python files. It is not a measure of coverage. The `verify-*.R`
scripts compute reference values in R and print them; the Praat suites
then assert the library's output against those printed constants. A
procedure can be fully R-validated while its name never appears in any
`.R` file — the name shows up only if a script author happened to type it
in a comment. The grep measured *mentions*, not oracles. One of its 17
hits, `emlTestAssertEqualNum`, is a test helper and not a statistics
procedure at all.

The denominator was also wrong. 317 counts every `eml`-prefixed procedure
in the plugin, including 45 graph, 25 annotation, 15 draw and 42 output
procedures. Asking what fraction of those have an R oracle is a category
error — there is no R reference value for a viewport calculation.

This is the same defect class the audit program exists to catch:
format-blind / proxy-blind aggregation, the same failure as the earlier
276→409 R miscount. I presented a proxy as a fact and led with the number.

## Correct measurement

The mapping generator → suite is recorded by the author in
`dev/tests/REFERENCE_PROVENANCE.md` (15 pairs). The correct question is
which procedures are exercised by assertions inside a suite that is fed by
an external generator. Measured by extracting `@eml*` call sites from the
eleven externally-fed suites:

    test-inferential-batch1 … batch7, batch6b, test-regression,
    test-shapiro-wilk, test-theilsen

27 distinct public procedures are called under an external oracle:

    emlBenjaminiHochberg   emlBonferroni        emlCohenD
    emlDunnTest            emlEpsilonSquared    emlHolm
    emlKruskalWallis       emlLinearRegression  emlMannWhitneyU
    emlMatchedPairsR       emlOneWayAnova       emlPairwiseT
    emlPairwiseWilcoxon    emlPearsonCorrelation emlRankBiserialR
    emlRankVector          emlScheffe           emlShapiroWilk
    emlSortWithIndex       emlSpearmanCorrelation emlTTest
    emlTTestPaired         emlTableFromGroups   emlTheilSen
    emlTukeyHSD            emlTwoWayAnova       emlWilcoxonSignedRank

### Coverage by file

| File | Procedures | Under external oracle |
|---|---|---|
| `stats/eml-inferential.praat` | 28 | **24 directly + 4 transitively = 28** |
| `stats/eml-core-descriptive.praat` | 21 | 1 (Shapiro-Wilk); 20 asserted against closed-form analytic values |
| `stats/eml-core-utilities.praat` | 15 | 2; rest are structural (sorting, ranking, table shaping) |
| `stats/eml-analysis.praat` | 21 | 0 directly; 7 tested as workflow wrappers over already-oracled procedures |
| `stats/eml-lmm.praat` | 31 | **0 — and no test of any kind** |
| `stats/eml-linalg.praat` | 10 | **0 — and no test of any kind** |
| `stats/eml-optimizer.praat` | 8 | **0 — and no test of any kind** |

The four inferential procedures with no direct external assertion are all
private helpers, reached only through publicly-oracled callers:

| Helper | Reached from | Site |
|---|---|---|
| `eml_mannWhitneyExactP` | `emlMannWhitneyU` | `eml-inferential.praat:791` |
| `eml_wilcoxonExactP` | `emlWilcoxonSignedRank` | `:1125` |
| `eml_pearsonCore` | `emlPearsonCorrelation`, `emlSpearmanCorrelation` | `:477`, `:552` |
| `eml_parseAnovaLine` | `emlTwoWayAnova` | `:2538`, `:2554`, `:2571` |

**The inferential statistics library is externally validated end to end.**
That matches the development history: 442 external checks currently pass
(409 from eight R scripts, 33 from the scikit-posthocs Dunn verifier),
zero failures. 442 checks over 28 procedures is a plausible density; 442
over the 16 my grep reported was the tell I should have caught.

### Descriptive statistics are validated, just not by R

`dev/tests/phase1/test-core-descriptive.praat` states its own standard:
"Validates all procedures against analytically computed expected values."
For mean, median, variance, SD, percentile and MAD the closed-form value
is the stronger oracle — R would only be re-deriving the same arithmetic.
This is not an unvalidated area. It is validated by a different and
adequate method, and the reason it does not appear in the R generator
table is that R was never the right tool for it.

## The gap, as it stood before the tabling ruling

**49 procedures have no test of any kind, in any suite:**

- `stats/eml-lmm.praat` — 31 procedures. Mixed models, REML, bootstrap CI.
- `stats/eml-linalg.praat` — 10 procedures. Cholesky decomposition,
  triangular solves, log-determinant, matrix inverse.
- `stats/eml-optimizer.praat` — 8 procedures. Nelder–Mead, BOBYQA
  (init, trust-region step, alternative move, rescue), bound projection.

Verified by grepping every `@procName` call site across all of
`dev/tests/` — zero matches for any of the 49.

## AUTHOR RULING, 4 August 2026 — the LMM module is tabled

The ruling removes more than the 31 procedures it names. `eml-lmm.praat`
is the **sole consumer** of both `eml-linalg.praat` and
`eml-optimizer.praat`. Verified by tracing all 18 procedures in those two
files for call sites outside their own file:

| File | Procedure | Called from |
|---|---|---|
| linalg | `emlCholesky` | `stats/eml-lmm.praat` |
| linalg | `emlTriangularLogDet` | `stats/eml-lmm.praat` |
| linalg | `emlCholeskySolve` | `stats/eml-lmm.praat` |
| linalg | `emlLogDeterminant` | **no caller in the plugin** |
| linalg | `emlForwardSolve` | **no caller** |
| linalg | `emlBackSolve` | **no caller** |
| linalg | `emlCholeskySolveMulti` | **no caller** |
| linalg | `emlCholeskyInverse` | **no caller** |
| linalg | `emlForwardSolveMulti` | **no caller** |
| linalg | `emlBackSolveMulti` | **no caller** |
| optimizer | `emlNelderMead` | `stats/eml-lmm.praat` |
| optimizer | `emlBOBYQA` | `stats/eml-lmm.praat` |
| optimizer | `emlProjectOntoBounds` | **no caller** |
| optimizer | `emlBOBYQAUpdate` | **no caller** |
| optimizer | `emlBOBYQATrsbox` | **no caller** |
| optimizer | `emlBOBYQAAltmov` | **no caller** |
| optimizer | `emlBOBYQAInit` | **no caller** |
| optimizer | `emlBOBYQARescue` | **no caller** |

Twelve of the eighteen are reachable from nothing at all; the remaining
six are reachable only from LMM. Nothing outside the tabled module
depends on either file. Tabling LMM therefore tables all **49**
procedures, and `emlRunLMMAnalysis` in `eml-analysis.praat` goes with
them.

Consequence: the coverage gap described above is **not an open item**. Do
not re-raise LMM, linalg or optimizer as an unvalidated surface. They are
deferred by author ruling, not overlooked.

## The residual gap after tabling — CLOSED 4 August 2026

Four procedures in `stats/eml-analysis.praat` had no external oracle and
no test of any kind. All served the repeated-measures path:

| Procedure | Lines | How it gets its answer |
|---|---|---|
| `emlFriedmanTest` | 1222–1272 (50) | computes its own chi-square statistic; p via `chiSquareQ` |
| `emlGGEpsilon` | 1278–1339 (61) | Greenhouse–Geisser epsilon derived from scratch — no internal calls at all |
| `emlRMAnovaTest` | 1346–1391 (45) | computes its own F; p via `fisherQ`; depends on `@emlGGEpsilon` |
| `emlExtractConditionMatrix` | 1142–1214 (72) | row-wise complete-case reshape into an n×k matrix; no statistics, but a bug here corrupts every repeated-measures result downstream |

All four now carry external-oracle assertions. Three artifacts, all in
`dev/tests/phase2/`:

| Artifact | Lines | Result |
|---|---|---|
| `repeatedmeasures_refs.py` | 291 | the `[EXT]` generator — scipy, statsmodels, pingouin |
| `test-repeated-measures.praat` | 451 | **90 passed / 0 failed / 6 skipped / 96 total — INCOMPLETE by design** |
| `verify-repeated-measures.R` | 578 | **101 passed / 0 failed / 10 skipped — EXIT=2 (INCOMPLETE, not FAILED)** |

**Correction to the earlier availability claim in this section.** It said
Greenhouse–Geisser epsilon "comes from `ez::ezANOVA` or `afex::aov_ez`."
Neither package is installed in the sandbox and CRAN is unreachable, so
base R affords **no** external GG oracle at all. The genuine `[EXT]` GG
oracle is **pingouin 0.6.1**, and it therefore lives in the Python
generator — `REFERENCE_PROVENANCE.md` forbids `library()`/`require()` in
the `.R` generators. The `.R` file re-derives epsilon longhand from
`cov()` and labels those checks `[LH]`, which catch transcription and
arithmetic slips but not a shared misunderstanding of the estimator.
Friedman (`stats::friedman.test`) and RM-ANOVA (`aov` with an
`Error(subject/condition)` stratum) are `[EXT]` in both files.

Six datasets span working and known-broken input: RM_A clean k=3 n=6;
RM_B k=4 n=5 sphericity violated (epsilon 0.33673, just above the
1/(k−1)=0.33333 clamp); RM_C heavy within-row ties; RM_D every
observation identical; RM_E n=2 with epsilon exactly **on** the clamp;
RM_F perfectly additive, zero residual.

**Substantive finding: zero disagreements.** All 101 base-R checks agreed
with the literals transcribed from scipy/statsmodels/pingouin. No
transcription error exists in the suite.

**Six quantities are asserted in neither file — pending AUTHOR
DECISION.** They are three new instances of the audit-item-2/9
fabricated-result class:

| Input | Library returns | Oracle returns |
|---|---|---|
| RM_D `emlFriedmanTest` | chiSq 0, p 1 (clamps `.c <= 0` to 1) | scipy `nan` |
| RM_D `emlGGEpsilon` | 1 (`.den <= 0` branch) | pingouin `nan` |
| RM_D `emlRMAnovaTest` | F `undefined` (msErr 0) | statsmodels F 0, p 1 |
| RM_F `emlGGEpsilon` | 1 | pingouin `nan` |
| RM_F `emlRMAnovaTest` | — | statsmodels 3.09e31 vs pingouin 8.58e15; **no reference value exists** |

Do not "fix" a skip by adopting the library's own output — that converts
the suite from a test into a regression lock
(`REFERENCE_PROVENANCE.md`).

Two procedures in the same file are **not** gaps:

- `emlRMPostHoc` (1514–1620) delegates entirely to already-oracled
  procedures — `@emlTTestPaired`, `@emlWilcoxonSignedRank`,
  `@emlBonferroni`, `@emlHolm`, `@emlBenjaminiHochberg`. It contributes no
  statistic of its own.
- `emlRunReliabilityAnalysis` (1129–1131) is a declared Phase 4 stub with
  no call sites. It sets a non-empty `.error$` and computes nothing. The
  code says so in a comment above the procedure.

## Corrected statement

The statistics the plugin actually ships for hypothesis testing — t-tests,
ANOVA (one-way, two-way), Kruskal–Wallis, Mann–Whitney, Wilcoxon, Dunn,
Tukey, Scheffé, pairwise t and Wilcoxon, all three multiple-comparison
corrections, all four effect sizes, both correlations, linear regression,
Theil–Sen, Shapiro–Wilk — are confirmed against R or scipy, exactly as the
author described. With LMM (and its exclusive linalg/optimizer
dependencies) tabled by author ruling, and the four repeated-measures
procedures oracled as of 4 August 2026, **there is no remaining
unvalidated statistical surface in the shipping plugin.**

What remains is not a coverage gap but a set of **author decisions about
degenerate-input behaviour** — six quantities where the library returns a
number and the external oracle returns `nan` (or where two external
oracles disagree by sixteen orders of magnitude). Those are recorded as
registered skips in both suites, which is why each reports INCOMPLETE
rather than PASS. INCOMPLETE is the honest status; it is not a failure,
and it must not be cleared by adopting the library's own output as the
expected value.
