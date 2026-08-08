# ============================================================================
# EML Stats : Test Suite — Repeated Measures
# ============================================================================
# Tests: @emlExtractConditionMatrix, @emlFriedmanTest, @emlGGEpsilon,
#        @emlRMAnovaTest
# Version: 1.0
# Date: 4 August 2026
#
# Reference values: repeatedmeasures_refs.py
#   Friedman chi-square / p ...... scipy.stats.friedmanchisquare      [EXT]
#   RM-ANOVA F / df / p .......... statsmodels AnovaRM                [EXT]
#   GG epsilon ................... pingouin                           [EXT]
#   GG-corrected p ............... scipy.stats.f.sf on the above      [EXT]
# R verification: verify-repeated-measures.R
#   Base R has no Greenhouse-Geisser routine and neither ez nor afex is
#   installed in the environment of record, so the R file re-checks the
#   Friedman and RM-ANOVA literals as [EXT] and the GG literals only as
#   [LH] (longhand from the covariance matrix). The external GG evidence
#   is the Python generator's, not R's.
#
# Uses shared test helpers (eml-test-helpers.praat).
#
# WORKING vs KNOWN-BROKEN DATA
# The audit requires both. Working: RM_A (clean, no ties), RM_B (sphericity
# violated, epsilon just above the 1/(k-1) clamp), RM_C (heavy within-row
# ties, exercising the tie correction). Boundary / degenerate: RM_E (n = 2,
# epsilon exactly ON the clamp), RM_D (every observation identical),
# RM_F (perfectly additive, zero residual).
#
# THREE DELIBERATE NON-ASSERTIONS — read before "fixing" a skip
#
# 1. RM_D, all observations identical. The library and the external oracles
#    disagree, and the disagreement is the finding, not a tolerance problem:
#        emlFriedmanTest  clamps .c <= 0 to 1 and returns chiSq = 0, p = 1;
#                         scipy returns nan.
#        emlGGEpsilon     takes the .den <= 0 branch and returns 1;
#                         pingouin returns nan.
#        emlRMAnovaTest   computes msErr = 0, so F = 0/0 = undefined;
#                         statsmodels returns F = 0, p = 1.
#    This is the same shape as the Kruskal-Wallis all-tied path already
#    logged as an open AUTHOR DECISION (audit item 2 / batch7 item 9):
#    a value that reads as "tested, no difference" when no test was
#    possible. Asserting either answer here would silently ratify one of
#    them. The statistics are skipped with this reason; the quantities the
#    oracles and the library DO agree on (rank sums, df, condition means)
#    are asserted normally.
#
# 2. RM_F, zero residual. statsmodels reports F = 3.09e31 and pingouin
#    reports F = 8.59e15 for the same data — sixteen orders of magnitude
#    apart, because both are floating-point noise on a 0/0. No reference
#    value exists to assert against. Friedman and the condition means are
#    unaffected and are asserted.
#
# 3. Nothing in this suite was transcribed from the EML library's own
#    output. See dev/tests/REFERENCE_PROVENANCE.md.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
#            https://github.com/embodied-music-lab/PraatGen
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
#
# RESEARCH USE DISCLOSURE
# If this script is used in research or publication, disclose AI use
# per your target journal's policy. Suggested language:
#
#   "Praat analysis scripts were developed using the EML PraatGen
#    Scripting Assistant (Howell, Embodied Music Lab) with code
#    generation by Claude (Anthropic). All scripts were reviewed,
#    tested, and validated by Ian Howell."
#
# The script author assumes responsibility for the correctness and
# appropriate application of this code.
# ============================================================================

include ../../../stats/eml-core-utilities.praat
include ../../../stats/eml-core-descriptive.praat
include ../../../stats/eml-extract.praat
include ../../../stats/eml-output.praat
include ../../../stats/eml-inferential.praat
include ../../../stats/eml-analysis.praat
include ../eml-test-helpers.praat

@emlTestInit

tolerance = 0.0001
toleranceTight = 0.000000001
toleranceExact = 0.000000000001
relTolerance = 0.000001


# ============================================================================
# HELPER: build a wide-format fixture Table with columns pre / mid / post
# ============================================================================

procedure buildFixtureTable: .m##
    .n = numberOfRows (.m##)
    .tableId = Create Table with column names: "rmFixture", .n, "pre mid post"
    for .i from 1 to .n
        Set numeric value: .i, "pre", .m## [.i, 1]
        Set numeric value: .i, "mid", .m## [.i, 2]
        Set numeric value: .i, "post", .m## [.i, 3]
    endfor
endproc


# ============================================================================
# THE DATASETS (identical to repeatedmeasures_refs.py)
# ============================================================================

# RM_A — clean balanced, k = 3, n = 6, no ties
rmA## = {{12, 15, 19}, {10, 14, 17}, {13, 16, 21},
... {9, 12, 16}, {11, 15, 20}, {14, 18, 23}}

# RM_B — k = 4, n = 5, sphericity violated
rmB## = {{2, 8, 3, 30}, {3, 9, 5, 10}, {4, 11, 4, 50},
... {2, 7, 6, 5}, {5, 12, 3, 40}}

# RM_C — heavy within-row ties
rmC## = {{5, 5, 8}, {7, 7, 7}, {3, 6, 6}, {4, 4, 9}, {6, 6, 6}}

# RM_D — every observation identical (degenerate)
rmD## = {{7, 7, 7}, {7, 7, 7}, {7, 7, 7}, {7, 7, 7}}

# RM_E — n = 2, the minimum the reshape admits
rmE## = {{10, 14, 21}, {12, 15, 19}}

# RM_F — perfectly additive, zero residual (degenerate)
rmF## = {{1, 6, 10}, {4, 9, 13}, {8, 13, 17}}


# ============================================================================
# SECTION A — @emlExtractConditionMatrix (complete-case reshape)
# ============================================================================

@emlTestSection: "emlExtractConditionMatrix — reshape and complete-case"

# --- F1: all cells present -------------------------------------------------
fixture## = {{12, 15, 19}, {10, 14, 17}, {13, 16, 21}, {9, 12, 16}}
@buildFixtureTable: fixture##
f1Id = buildFixtureTable.tableId

@emlExtractConditionMatrix: f1Id, "pre|mid|post"
@emlTestAssertEqualStr: "F1 error empty", "", emlExtractConditionMatrix.error$
@emlTestAssertEqualNum: "F1 n", 4, emlExtractConditionMatrix.n, 0
@emlTestAssertEqualNum: "F1 k", 3, emlExtractConditionMatrix.k, 0
@emlTestAssertEqualNum: "F1 nExcluded", 0,
... emlExtractConditionMatrix.nExcluded, 0
@emlTestAssertEqualStr: "F1 colLabel 1", "pre",
... emlExtractConditionMatrix.colLabel$ [1]
@emlTestAssertEqualStr: "F1 colLabel 2", "mid",
... emlExtractConditionMatrix.colLabel$ [2]
@emlTestAssertEqualStr: "F1 colLabel 3", "post",
... emlExtractConditionMatrix.colLabel$ [3]
@emlTestAssertEqualNum: "F1 cell [1,1]", 12,
... emlExtractConditionMatrix.data## [1, 1], 0
@emlTestAssertEqualNum: "F1 cell [1,3]", 19,
... emlExtractConditionMatrix.data## [1, 3], 0
@emlTestAssertEqualNum: "F1 cell [4,1]", 9,
... emlExtractConditionMatrix.data## [4, 1], 0
@emlTestAssertEqualNum: "F1 cell [4,3]", 16,
... emlExtractConditionMatrix.data## [4, 3], 0

# --- F6: whitespace and an empty token in the column list ------------------
# Parsed from the SAME table as F1, so any difference is the parser's.
@emlExtractConditionMatrix: f1Id, "  pre |  mid ||post  "
@emlTestAssertEqualStr: "F6 error empty (whitespace/empty token)", "",
... emlExtractConditionMatrix.error$
@emlTestAssertEqualNum: "F6 k (empty token dropped)", 3,
... emlExtractConditionMatrix.k, 0
@emlTestAssertEqualNum: "F6 n", 4, emlExtractConditionMatrix.n, 0
@emlTestAssertEqualStr: "F6 colLabel 1 trimmed", "pre",
... emlExtractConditionMatrix.colLabel$ [1]
@emlTestAssertEqualStr: "F6 colLabel 3 trimmed", "post",
... emlExtractConditionMatrix.colLabel$ [3]

# --- F3: unknown column name ----------------------------------------------
@emlExtractConditionMatrix: f1Id, "pre|bogus|post"
@emlTestAssertEqualStr: "F3 unknown column error", "Column not found: bogus",
... emlExtractConditionMatrix.error$

# --- F4: single condition column ------------------------------------------
@emlExtractConditionMatrix: f1Id, "pre"
@emlTestAssertEqualStr: "F4 single-column error",
... "Need at least 2 condition columns.",
... emlExtractConditionMatrix.error$

removeObject: f1Id

# --- F2: two rows carry an undefined cell ---------------------------------
# Row 2 loses `mid`, row 4 loses `post`. The survivors are ORIGINAL rows 1
# and 3, and they must arrive in that order — row-wise complete-case
# deletion has to preserve the within-subject blocking.
@buildFixtureTable: fixture##
f2Id = buildFixtureTable.tableId
selectObject: f2Id
Set numeric value: 2, "mid", undefined
Set numeric value: 4, "post", undefined

@emlExtractConditionMatrix: f2Id, "pre|mid|post"
@emlTestAssertEqualStr: "F2 error empty", "", emlExtractConditionMatrix.error$
@emlTestAssertEqualNum: "F2 n (complete rows)", 2,
... emlExtractConditionMatrix.n, 0
@emlTestAssertEqualNum: "F2 k", 3, emlExtractConditionMatrix.k, 0
@emlTestAssertEqualNum: "F2 nExcluded", 2,
... emlExtractConditionMatrix.nExcluded, 0
@emlTestAssertEqualNum: "F2 survivor 1 col 1 (orig row 1)", 12,
... emlExtractConditionMatrix.data## [1, 1], 0
@emlTestAssertEqualNum: "F2 survivor 1 col 2", 15,
... emlExtractConditionMatrix.data## [1, 2], 0
@emlTestAssertEqualNum: "F2 survivor 1 col 3", 19,
... emlExtractConditionMatrix.data## [1, 3], 0
@emlTestAssertEqualNum: "F2 survivor 2 col 1 (orig row 3)", 13,
... emlExtractConditionMatrix.data## [2, 1], 0
@emlTestAssertEqualNum: "F2 survivor 2 col 2", 16,
... emlExtractConditionMatrix.data## [2, 2], 0
@emlTestAssertEqualNum: "F2 survivor 2 col 3", 21,
... emlExtractConditionMatrix.data## [2, 3], 0

removeObject: f2Id

# --- F5: fewer than two complete rows -------------------------------------
@buildFixtureTable: fixture##
f5Id = buildFixtureTable.tableId
selectObject: f5Id
Set numeric value: 1, "pre", undefined
Set numeric value: 2, "mid", undefined
Set numeric value: 3, "post", undefined

@emlExtractConditionMatrix: f5Id, "pre|mid|post"
@emlTestAssertEqualStr: "F5 too-few-complete-cases error",
... "Need at least 2 complete-case subjects (rows with all conditions present).",
... emlExtractConditionMatrix.error$

removeObject: f5Id


# ============================================================================
# SECTION B — @emlFriedmanTest
# Reference: scipy.stats.friedmanchisquare  [EXT]
# ============================================================================

@emlTestSection: "emlFriedmanTest — chi-square, df, p, rank sums"

# --- RM_A: clean, no ties (tie correction factor c = 1) --------------------
@emlFriedmanTest: rmA##, 6, 3
@emlTestAssertEqualNum: "RM_A Friedman chiSq", 12, emlFriedmanTest.chiSq,
... toleranceTight
@emlTestAssertEqualNum: "RM_A Friedman df", 2, emlFriedmanTest.df, 0
@emlTestAssertEqualRel: "RM_A Friedman p", 0.002478752176666357,
... emlFriedmanTest.p, relTolerance
@emlTestAssertVectorsEqual: "RM_A Friedman rank sums", {6, 12, 18},
... emlFriedmanTest.rankSum#, toleranceExact

# --- RM_B: k = 4 -----------------------------------------------------------
@emlFriedmanTest: rmB##, 5, 4
@emlTestAssertEqualNum: "RM_B Friedman chiSq", 10.714285714285715,
... emlFriedmanTest.chiSq, toleranceTight
@emlTestAssertEqualNum: "RM_B Friedman df", 3, emlFriedmanTest.df, 0
@emlTestAssertEqualRel: "RM_B Friedman p", 0.013375553908094653,
... emlFriedmanTest.p, relTolerance
@emlTestAssertVectorsEqual: "RM_B Friedman rank sums", {6.5, 16, 9.5, 18},
... emlFriedmanTest.rankSum#, toleranceExact

# --- RM_C: heavy within-row ties (exercises the tie correction) ------------
@emlFriedmanTest: rmC##, 5, 3
@emlTestAssertEqualNum: "RM_C Friedman chiSq (tie-corrected)",
... 4.6666666666666705, emlFriedmanTest.chiSq, toleranceTight
@emlTestAssertEqualRel: "RM_C Friedman p", 0.09697196786440486,
... emlFriedmanTest.p, relTolerance
@emlTestAssertVectorsEqual: "RM_C Friedman rank sums", {8, 9.5, 12.5},
... emlFriedmanTest.rankSum#, toleranceExact

# --- RM_E: n = 2, the minimum -------------------------------------------
@emlFriedmanTest: rmE##, 2, 3
@emlTestAssertEqualNum: "RM_E Friedman chiSq (n=2)", 4,
... emlFriedmanTest.chiSq, toleranceTight
@emlTestAssertEqualRel: "RM_E Friedman p", 0.1353352832366127,
... emlFriedmanTest.p, relTolerance
@emlTestAssertVectorsEqual: "RM_E Friedman rank sums", {2, 4, 6},
... emlFriedmanTest.rankSum#, toleranceExact

# --- RM_F: zero residual — Friedman is rank-based and unaffected -----------
@emlFriedmanTest: rmF##, 3, 3
@emlTestAssertEqualNum: "RM_F Friedman chiSq (zero residual)", 6,
... emlFriedmanTest.chiSq, toleranceTight
@emlTestAssertEqualRel: "RM_F Friedman p", 0.04978706836786395,
... emlFriedmanTest.p, relTolerance
@emlTestAssertVectorsEqual: "RM_F Friedman rank sums", {3, 6, 9},
... emlFriedmanTest.rankSum#, toleranceExact

# --- RM_D: every observation identical ------------------------------------
# Rank sums are well defined and both sides agree; the test statistic is not.
@emlFriedmanTest: rmD##, 4, 3
@emlTestAssertVectorsEqual: "RM_D Friedman rank sums (all tied)", {8, 8, 8},
... emlFriedmanTest.rankSum#, toleranceExact
@emlTestAssertEqualNum: "RM_D Friedman df", 2, emlFriedmanTest.df, 0
@emlTestSkip: "RM_D Friedman chiSq",
... "all observations identical: rank-sum variance is zero, so the statistic is 0/0. The library clamps .c <= 0 to 1 and returns chiSq = 0, p = 1; scipy returns nan. Same class as the open Kruskal-Wallis all-tied AUTHOR DECISION — not asserted until the author rules."
@emlTestSkip: "RM_D Friedman p",
... "see RM_D Friedman chiSq — library returns p = 1 where scipy returns nan."


# ============================================================================
# SECTION C — @emlGGEpsilon
# Reference: pingouin  [EXT], cross-checked against an independent longhand
# derivation from the covariance matrix (agreement 8e-14 or better).
# ============================================================================

@emlTestSection: "emlGGEpsilon — Greenhouse-Geisser sphericity epsilon"

@emlGGEpsilon: rmA##, 6, 3
@emlTestAssertEqualNum: "RM_A GG epsilon", 0.7364273204903339,
... emlGGEpsilon.epsilon, toleranceTight

# RM_B sits just above the 1/(k-1) = 0.3333... clamp: the clamp must not fire.
@emlGGEpsilon: rmB##, 5, 4
@emlTestAssertEqualNum: "RM_B GG epsilon (sphericity violated)",
... 0.3367309662151602, emlGGEpsilon.epsilon, toleranceTight
@emlTestAssertTrue: "RM_B GG epsilon strictly above lower clamp",
... emlGGEpsilon.epsilon > 1 / 3

@emlGGEpsilon: rmC##, 5, 3
@emlTestAssertEqualNum: "RM_C GG epsilon (ties)", 0.7680935569285082,
... emlGGEpsilon.epsilon, toleranceTight

# RM_E lands exactly ON the lower clamp 1/(k-1) = 0.5.
@emlGGEpsilon: rmE##, 2, 3
@emlTestAssertEqualNum: "RM_E GG epsilon (on lower clamp)", 0.5,
... emlGGEpsilon.epsilon, toleranceTight
@emlTestAssertTrue: "RM_E GG epsilon not below lower clamp",
... emlGGEpsilon.epsilon >= 0.5

@emlTestSkip: "RM_D GG epsilon",
... "all observations identical: the covariance matrix is zero, so epsilon is 0/0. The library takes the .den <= 0 branch and returns 1; pingouin returns nan. Not asserted until the author rules on the degenerate-input contract."
@emlTestSkip: "RM_F GG epsilon",
... "zero residual: the same 0/0. Library returns 1, pingouin returns nan."


# ============================================================================
# SECTION D — @emlRMAnovaTest
# Reference: statsmodels AnovaRM for F / df / p  [EXT];
# GG-corrected p from scipy.stats.f.sf with df scaled by pingouin's epsilon.
# ============================================================================

@emlTestSection: "emlRMAnovaTest — F, df, p, GG-corrected p, condition means"

# --- RM_A ------------------------------------------------------------------
@emlRMAnovaTest: rmA##, 6, 3
@emlTestAssertEqualRel: "RM_A RM-ANOVA F", 286.7241379310342,
... emlRMAnovaTest.fStat, relTolerance
@emlTestAssertEqualNum: "RM_A RM-ANOVA dfCond", 2, emlRMAnovaTest.dfCond, 0
@emlTestAssertEqualNum: "RM_A RM-ANOVA dfErr", 10, emlRMAnovaTest.dfErr, 0
@emlTestAssertEqualRel: "RM_A RM-ANOVA p", 1.4790681869019914e-09,
... emlRMAnovaTest.p, relTolerance
@emlTestAssertEqualNum: "RM_A RM-ANOVA ggEpsilon", 0.7364273204903339,
... emlRMAnovaTest.ggEpsilon, toleranceTight
@emlTestAssertEqualRel: "RM_A RM-ANOVA pGG", 1.7527450251467276e-07,
... emlRMAnovaTest.pGG, relTolerance
@emlTestAssertVectorsEqual: "RM_A RM-ANOVA condition means",
... {11.5, 15, 19.333333333333332}, emlRMAnovaTest.condMean#, toleranceTight

# --- RM_B ------------------------------------------------------------------
@emlRMAnovaTest: rmB##, 5, 4
@emlTestAssertEqualRel: "RM_B RM-ANOVA F", 6.808118424727679,
... emlRMAnovaTest.fStat, relTolerance
@emlTestAssertEqualNum: "RM_B RM-ANOVA dfCond", 3, emlRMAnovaTest.dfCond, 0
@emlTestAssertEqualNum: "RM_B RM-ANOVA dfErr", 12, emlRMAnovaTest.dfErr, 0
@emlTestAssertEqualRel: "RM_B RM-ANOVA p", 0.00622328180490924,
... emlRMAnovaTest.p, relTolerance
@emlTestAssertEqualRel: "RM_B RM-ANOVA pGG (sphericity violated)",
... 0.058750528968868926, emlRMAnovaTest.pGG, relTolerance
@emlTestAssertTrue: "RM_B GG correction moves p across 0.05",
... emlRMAnovaTest.p < 0.05 and emlRMAnovaTest.pGG > 0.05
@emlTestAssertVectorsEqual: "RM_B RM-ANOVA condition means",
... {3.2, 9.4, 4.2, 27}, emlRMAnovaTest.condMean#, toleranceTight

# --- RM_C ------------------------------------------------------------------
@emlRMAnovaTest: rmC##, 5, 3
@emlTestAssertEqualRel: "RM_C RM-ANOVA F", 3.288135593220338,
... emlRMAnovaTest.fStat, relTolerance
@emlTestAssertEqualNum: "RM_C RM-ANOVA dfCond", 2, emlRMAnovaTest.dfCond, 0
@emlTestAssertEqualNum: "RM_C RM-ANOVA dfErr", 8, emlRMAnovaTest.dfErr, 0
@emlTestAssertEqualRel: "RM_C RM-ANOVA p", 0.09073486336291588,
... emlRMAnovaTest.p, relTolerance
@emlTestAssertEqualRel: "RM_C RM-ANOVA pGG", 0.11219902011637321,
... emlRMAnovaTest.pGG, relTolerance
@emlTestAssertVectorsEqual: "RM_C RM-ANOVA condition means",
... {5, 5.6, 7.2}, emlRMAnovaTest.condMean#, toleranceTight

# --- RM_E: n = 2 boundary --------------------------------------------------
@emlRMAnovaTest: rmE##, 2, 3
@emlTestAssertEqualRel: "RM_E RM-ANOVA F (n=2)", 19.000000000000004,
... emlRMAnovaTest.fStat, relTolerance
@emlTestAssertEqualNum: "RM_E RM-ANOVA dfCond (n=2)", 2,
... emlRMAnovaTest.dfCond, 0
@emlTestAssertEqualNum: "RM_E RM-ANOVA dfErr (n=2)", 2,
... emlRMAnovaTest.dfErr, 0
@emlTestAssertEqualRel: "RM_E RM-ANOVA p", 0.04999999999999999,
... emlRMAnovaTest.p, relTolerance
@emlTestAssertEqualRel: "RM_E RM-ANOVA pGG", 0.1435662931287063,
... emlRMAnovaTest.pGG, relTolerance
@emlTestAssertVectorsEqual: "RM_E RM-ANOVA condition means",
... {11, 14.5, 20}, emlRMAnovaTest.condMean#, toleranceTight

# --- RM_D: degenerate ------------------------------------------------------
# The condition means and the degrees of freedom are well defined and agree
# with statsmodels; F and p are not asserted (see the header).
@emlRMAnovaTest: rmD##, 4, 3
@emlTestAssertEqualNum: "RM_D RM-ANOVA dfCond", 2, emlRMAnovaTest.dfCond, 0
@emlTestAssertEqualNum: "RM_D RM-ANOVA dfErr", 6, emlRMAnovaTest.dfErr, 0
@emlTestAssertVectorsEqual: "RM_D RM-ANOVA condition means",
... {7, 7, 7}, emlRMAnovaTest.condMean#, toleranceExact
# The author's ruling, 5 August, is D97: refuse. statsmodels reports
# F = 0, p = 1 and pingouin reports nan for this input; neither is a
# result, and printing either invites a reader to interpret it. The
# library now returns an error naming the condition and leaves F and p
# undefined, which is asserted here rather than skipped.
@emlTestAssertTrue: "RM_D RM-ANOVA refuses (D97)",
... emlRMAnovaTest.error$ <> ""
@emlTestAssertTrue: "RM_D RM-ANOVA F is undefined",
... emlRMAnovaTest.fStat = undefined
@emlTestAssertTrue: "RM_D RM-ANOVA p is undefined",
... emlRMAnovaTest.p = undefined
@emlTestAssertContains: "RM_D refusal names the absence of variance",
... emlRMAnovaTest.error$, "no variance to partition"

# --- RM_F: zero residual ---------------------------------------------------
@emlRMAnovaTest: rmF##, 3, 3
@emlTestAssertEqualNum: "RM_F RM-ANOVA dfCond", 2, emlRMAnovaTest.dfCond, 0
@emlTestAssertEqualNum: "RM_F RM-ANOVA dfErr", 4, emlRMAnovaTest.dfErr, 0
@emlTestAssertVectorsEqual: "RM_F RM-ANOVA condition means",
... {4.333333333333333, 9.333333333333334, 13.333333333333334},
... emlRMAnovaTest.condMean#, toleranceTight
# D97. statsmodels reports 3.09e31 here and pingouin 8.59e15 for the same
# input: the disagreement IS the evidence that neither is a number. The
# floor that catches this is relative — ssErr is around 1e-16 of ssTot,
# not zero — so an equality test against 0 would not fire.
@emlTestAssertTrue: "RM_F RM-ANOVA refuses (D97)",
... emlRMAnovaTest.error$ <> ""
@emlTestAssertTrue: "RM_F RM-ANOVA F is undefined",
... emlRMAnovaTest.fStat = undefined
@emlTestAssertTrue: "RM_F RM-ANOVA p is undefined",
... emlRMAnovaTest.p = undefined
@emlTestAssertContains: "RM_F refusal names the zero residual",
... emlRMAnovaTest.error$, "residual is zero"


# ============================================================================
# SECTION E — end-to-end: reshape feeding the tests
# The reshape is the shared input path; a bug there corrupts every result
# downstream, so it is exercised once in composition rather than in isolation.
# ============================================================================

@emlTestSection: "Reshape composed with Friedman and RM-ANOVA"

@buildFixtureTable: fixture##
e1Id = buildFixtureTable.tableId
selectObject: e1Id
Set numeric value: 2, "mid", undefined
Set numeric value: 4, "post", undefined

@emlExtractConditionMatrix: e1Id, "pre|mid|post"
extractedN = emlExtractConditionMatrix.n
extractedK = emlExtractConditionMatrix.k
extracted## = emlExtractConditionMatrix.data##

# Surviving rows are {12,15,19} and {13,16,21}: within-row ranks 1,2,3 twice,
# so rank sums are 2, 4, 6 and chiSq = 4 — identical to RM_E, which has the
# same rank pattern. Reference: repeatedmeasures_refs.py, RM_E.
@emlFriedmanTest: extracted##, extractedN, extractedK
@emlTestAssertEqualNum: "composed Friedman chiSq", 4,
... emlFriedmanTest.chiSq, toleranceTight
@emlTestAssertEqualRel: "composed Friedman p", 0.1353352832366127,
... emlFriedmanTest.p, relTolerance

@emlRMAnovaTest: extracted##, extractedN, extractedK
@emlTestAssertEqualNum: "composed RM-ANOVA dfErr", 2,
... emlRMAnovaTest.dfErr, 0
@emlTestAssertVectorsEqual: "composed RM-ANOVA condition means",
... {12.5, 15.5, 20}, emlRMAnovaTest.condMean#, toleranceTight

removeObject: e1Id


# ============================================================================
# Summary
# ============================================================================

@emlTestSummary
