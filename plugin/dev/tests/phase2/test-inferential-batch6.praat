# ============================================================================
# EML Stats : Test Suite — Inferential Statistics (Batch 6 + Batch 9)
# ============================================================================
# Tests: @emlTableFromGroups, @emlOneWayAnova, @emlTwoWayAnova, @emlTukeyHSD
# Date: 18 March 2026
# Version: 2.0 (Batch 9: TukeyHSD refactor, etaSquared, partialEtaSq,
#   alphabetical group ordering, q statistics, unbalanced design test)
#
# Uses shared test helpers (eml-test-helpers.praat).
# Reference values computed via scipy.stats (18 Mar 2026) and
# independently verified via R (verify-inferential-batch9.R).
#
# Include order: inferential → test helpers
# No eml-core-utilities.praat needed — Batch 6 procedures don't use
# ranking helpers.
#
# ATTRIBUTION
# Framework: EML Praat Assistant by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: [Your name here] — created and verified by this individual
#
# NOTE: As of Batch 9, @emlTukeyHSD sorts groups alphabetically
# (matching R convention). Earlier versions used Praat's mean-sorted order.
# ============================================================================

include ../../../stats/eml-extract.praat
include ../../../stats/eml-inferential.praat
include ../eml-test-helpers.praat

@emlTestInit

tolerance      = 0.001
looseTolerance = 0.01
tightTolerance = 0.000001


# ══════════════════════════════════════════════════════════════════════════════
# TEST GROUP 1: @emlOneWayAnova — 3 groups, clear effect
# ══════════════════════════════════════════════════════════════════════════════

@emlTestSection: "@emlOneWayAnova — 3 groups, clear effect"

# Test Set 1: {23,25,27,22,26}, {30,33,29,31,34}, {18,20,22,19,17}
# scipy: F=45.5772, p=0.0000024783
# SS: between=373.7333, within=49.2000, total=422.9333
# df: between=2, within=12, total=14
# MS: between=186.8667, within=4.1000

emlTableFromGroups.groupLabel$[1] = "Group1"
emlTableFromGroups.groupLabel$[2] = "Group2"
emlTableFromGroups.groupLabel$[3] = "Group3"
emlTableFromGroups.groupSize[1] = 5
emlTableFromGroups.groupSize[2] = 5
emlTableFromGroups.groupSize[3] = 5
emlTableFromGroups.data# = {23, 25, 27, 22, 26, 30, 33, 29, 31, 34,
    ... 18, 20, 22, 19, 17}
@emlTableFromGroups: 3, "value", "group"
tableId1 = emlTableFromGroups.tableId

@emlOneWayAnova: tableId1, "value", "group", 0

@emlTestAssertEqualStr: "1 no error", "", emlOneWayAnova.error$
@emlTestAssertEqualNum: "1 F", 45.5772, emlOneWayAnova.fValue, tolerance
@emlTestAssertEqualNum: "1 p", 0.0000024783, emlOneWayAnova.p, tightTolerance
@emlTestAssertEqualNum: "1 SS between", 373.7333, emlOneWayAnova.ssBetween, tolerance
@emlTestAssertEqualNum: "1 SS within", 49.2, emlOneWayAnova.ssWithin, tolerance
@emlTestAssertEqualNum: "1 SS total", 422.9333, emlOneWayAnova.ssTotal, tolerance
@emlTestAssertEqualNum: "1 df between", 2, emlOneWayAnova.dfBetween, tightTolerance
@emlTestAssertEqualNum: "1 df within", 12, emlOneWayAnova.dfWithin, tightTolerance
@emlTestAssertEqualNum: "1 df total", 14, emlOneWayAnova.dfTotal, tightTolerance
@emlTestAssertEqualNum: "1 MS between", 186.8667, emlOneWayAnova.msBetween, tolerance
@emlTestAssertEqualNum: "1 MS within", 4.1, emlOneWayAnova.msWithin, tolerance
@emlTestAssertEqualNum: "1 nGroups", 3, emlOneWayAnova.nGroups, tightTolerance
@emlTestAssertEqualNum: "1 etaSquared", 0.88367, emlOneWayAnova.etaSquared, tolerance

removeObject: tableId1


# ══════════════════════════════════════════════════════════════════════════════
# TEST GROUP 2: @emlOneWayAnova — 3 groups, no effect (F≈0)
# ══════════════════════════════════════════════════════════════════════════════

@emlTestSection: "@emlOneWayAnova — 3 groups, no effect"

# Test Set 2: {10,11,12,10.5,11.5}, {10.5,11,11.5,10,12}, {11,10.5,11.5,10,12}
# scipy: F=0.0, p=1.0
# SS: between=0.0, within=7.5, total=7.5
# df: between=2, within=12, total=14

emlTableFromGroups.groupLabel$[1] = "Group1"
emlTableFromGroups.groupLabel$[2] = "Group2"
emlTableFromGroups.groupLabel$[3] = "Group3"
emlTableFromGroups.groupSize[1] = 5
emlTableFromGroups.groupSize[2] = 5
emlTableFromGroups.groupSize[3] = 5
emlTableFromGroups.data# = {10, 11, 12, 10.5, 11.5, 10.5, 11, 11.5, 10, 12,
    ... 11, 10.5, 11.5, 10, 12}
@emlTableFromGroups: 3, "value", "group"
tableId2 = emlTableFromGroups.tableId

@emlOneWayAnova: tableId2, "value", "group", 0

@emlTestAssertEqualStr: "2 no error", "", emlOneWayAnova.error$
@emlTestAssertEqualNum: "2 F", 0.0, emlOneWayAnova.fValue, tolerance
@emlTestAssertEqualNum: "2 p", 1.0, emlOneWayAnova.p, tolerance
@emlTestAssertEqualNum: "2 SS between", 0.0, emlOneWayAnova.ssBetween, tolerance
@emlTestAssertEqualNum: "2 SS within", 7.5, emlOneWayAnova.ssWithin, tolerance
@emlTestAssertEqualNum: "2 SS total", 7.5, emlOneWayAnova.ssTotal, tolerance
@emlTestAssertEqualNum: "2 df between", 2, emlOneWayAnova.dfBetween, tightTolerance
@emlTestAssertEqualNum: "2 df within", 12, emlOneWayAnova.dfWithin, tightTolerance
@emlTestAssertEqualNum: "2 df total", 14, emlOneWayAnova.dfTotal, tightTolerance
@emlTestAssertEqualNum: "2 etaSquared", 0.0, emlOneWayAnova.etaSquared, tightTolerance

removeObject: tableId2


# ══════════════════════════════════════════════════════════════════════════════
# TEST GROUP 3: @emlOneWayAnova — 2 groups
# ══════════════════════════════════════════════════════════════════════════════

@emlTestSection: "@emlOneWayAnova — 2 groups"

# Test Set 3: {5,7,9,6,8}, {10,12,11,13,14}
# scipy: F=25.0, p=0.0010528258
# SS: between=62.5, within=20.0, total=82.5
# df: between=1, within=8, total=9

emlTableFromGroups.groupLabel$[1] = "Group1"
emlTableFromGroups.groupLabel$[2] = "Group2"
emlTableFromGroups.groupSize[1] = 5
emlTableFromGroups.groupSize[2] = 5
emlTableFromGroups.data# = {5, 7, 9, 6, 8, 10, 12, 11, 13, 14}
@emlTableFromGroups: 2, "value", "group"
tableId3 = emlTableFromGroups.tableId

@emlOneWayAnova: tableId3, "value", "group", 0

@emlTestAssertEqualStr: "3 no error", "", emlOneWayAnova.error$
@emlTestAssertEqualNum: "3 F", 25.0, emlOneWayAnova.fValue, tolerance
@emlTestAssertEqualNum: "3 p", 0.001053, emlOneWayAnova.p, tolerance
@emlTestAssertEqualNum: "3 SS between", 62.5, emlOneWayAnova.ssBetween, tolerance
@emlTestAssertEqualNum: "3 SS within", 20.0, emlOneWayAnova.ssWithin, tolerance
@emlTestAssertEqualNum: "3 SS total", 82.5, emlOneWayAnova.ssTotal, tolerance
@emlTestAssertEqualNum: "3 df between", 1, emlOneWayAnova.dfBetween, tightTolerance
@emlTestAssertEqualNum: "3 df within", 8, emlOneWayAnova.dfWithin, tightTolerance
@emlTestAssertEqualNum: "3 df total", 9, emlOneWayAnova.dfTotal, tightTolerance
@emlTestAssertEqualNum: "3 etaSquared", 0.757576, emlOneWayAnova.etaSquared, tolerance

removeObject: tableId3


# ══════════════════════════════════════════════════════════════════════════════
# TEST GROUP 4: @emlTwoWayAnova — 2×2, no interaction
# ══════════════════════════════════════════════════════════════════════════════

@emlTestSection: "@emlTwoWayAnova — 2x2, no interaction"

# Test Set 4:
#   Control-Male:   {10,12,11,13,14}
#   Control-Female: {15,14,16,13,17}
#   Drug-Male:      {20,22,19,21,23}
#   Drug-Female:    {25,27,24,26,28}
#
# scipy: Treatment F=200, p=2e-10, SS=500, df=1, MS=500
#         Sex       F=32,  p=3.57e-5, SS=80, df=1, MS=80
#         Interact  F=2,   p=0.1765, SS=5, df=1, MS=5
#         Error SS=40, df=16, MS=2.5
#         Total SS=625, df=19

tableId4 = Create Table with column names: "twoWayTest4", 20,
    ... "value Treatment Sex"

# Control-Male: {10,12,11,13,14}
Set numeric value: 1, "value", 10
Set string value: 1, "Treatment", "Control"
Set string value: 1, "Sex", "Male"
Set numeric value: 2, "value", 12
Set string value: 2, "Treatment", "Control"
Set string value: 2, "Sex", "Male"
Set numeric value: 3, "value", 11
Set string value: 3, "Treatment", "Control"
Set string value: 3, "Sex", "Male"
Set numeric value: 4, "value", 13
Set string value: 4, "Treatment", "Control"
Set string value: 4, "Sex", "Male"
Set numeric value: 5, "value", 14
Set string value: 5, "Treatment", "Control"
Set string value: 5, "Sex", "Male"

# Control-Female: {15,14,16,13,17}
Set numeric value: 6, "value", 15
Set string value: 6, "Treatment", "Control"
Set string value: 6, "Sex", "Female"
Set numeric value: 7, "value", 14
Set string value: 7, "Treatment", "Control"
Set string value: 7, "Sex", "Female"
Set numeric value: 8, "value", 16
Set string value: 8, "Treatment", "Control"
Set string value: 8, "Sex", "Female"
Set numeric value: 9, "value", 13
Set string value: 9, "Treatment", "Control"
Set string value: 9, "Sex", "Female"
Set numeric value: 10, "value", 17
Set string value: 10, "Treatment", "Control"
Set string value: 10, "Sex", "Female"

# Drug-Male: {20,22,19,21,23}
Set numeric value: 11, "value", 20
Set string value: 11, "Treatment", "Drug"
Set string value: 11, "Sex", "Male"
Set numeric value: 12, "value", 22
Set string value: 12, "Treatment", "Drug"
Set string value: 12, "Sex", "Male"
Set numeric value: 13, "value", 19
Set string value: 13, "Treatment", "Drug"
Set string value: 13, "Sex", "Male"
Set numeric value: 14, "value", 21
Set string value: 14, "Treatment", "Drug"
Set string value: 14, "Sex", "Male"
Set numeric value: 15, "value", 23
Set string value: 15, "Treatment", "Drug"
Set string value: 15, "Sex", "Male"

# Drug-Female: {25,27,24,26,28}
Set numeric value: 16, "value", 25
Set string value: 16, "Treatment", "Drug"
Set string value: 16, "Sex", "Female"
Set numeric value: 17, "value", 27
Set string value: 17, "Treatment", "Drug"
Set string value: 17, "Sex", "Female"
Set numeric value: 18, "value", 24
Set string value: 18, "Treatment", "Drug"
Set string value: 18, "Sex", "Female"
Set numeric value: 19, "value", 26
Set string value: 19, "Treatment", "Drug"
Set string value: 19, "Sex", "Female"
Set numeric value: 20, "value", 28
Set string value: 20, "Treatment", "Drug"
Set string value: 20, "Sex", "Female"

@emlTwoWayAnova: tableId4, "value", "Treatment", "Sex"

@emlTestAssertEqualStr: "4 no error", "", emlTwoWayAnova.error$

# Factor A (Treatment)
@emlTestAssertEqualNum: "4 Treatment F", 200.0, emlTwoWayAnova.fA, tolerance
@emlTestAssertEqualNum: "4 Treatment p", 0.0000000002, emlTwoWayAnova.pA, tightTolerance
@emlTestAssertEqualNum: "4 Treatment SS", 500.0, emlTwoWayAnova.ssA, tolerance
@emlTestAssertEqualNum: "4 Treatment df", 1, emlTwoWayAnova.dfA, tightTolerance
@emlTestAssertEqualNum: "4 Treatment MS", 500.0, emlTwoWayAnova.msA, tolerance

# Factor B (Sex)
@emlTestAssertEqualNum: "4 Sex F", 32.0, emlTwoWayAnova.fB, tolerance
@emlTestAssertEqualNum: "4 Sex p", 0.0000357, emlTwoWayAnova.pB, tightTolerance
@emlTestAssertEqualNum: "4 Sex SS", 80.0, emlTwoWayAnova.ssB, tolerance
@emlTestAssertEqualNum: "4 Sex df", 1, emlTwoWayAnova.dfB, tightTolerance
@emlTestAssertEqualNum: "4 Sex MS", 80.0, emlTwoWayAnova.msB, tolerance

# Interaction
@emlTestAssertEqualNum: "4 Interact F", 2.0, emlTwoWayAnova.fAB, tolerance
@emlTestAssertEqualNum: "4 Interact p", 0.1765, emlTwoWayAnova.pAB, looseTolerance
@emlTestAssertEqualNum: "4 Interact SS", 5.0, emlTwoWayAnova.ssAB, tolerance
@emlTestAssertEqualNum: "4 Interact df", 1, emlTwoWayAnova.dfAB, tightTolerance
@emlTestAssertEqualNum: "4 Interact MS", 5.0, emlTwoWayAnova.msAB, tolerance

# Error and Total
@emlTestAssertEqualNum: "4 Error SS", 40.0, emlTwoWayAnova.ssError, tolerance
@emlTestAssertEqualNum: "4 Error df", 16, emlTwoWayAnova.dfError, tightTolerance
@emlTestAssertEqualNum: "4 Error MS", 2.5, emlTwoWayAnova.msError, tolerance
@emlTestAssertEqualNum: "4 Total SS", 625.0, emlTwoWayAnova.ssTotal, tolerance
@emlTestAssertEqualNum: "4 Total df", 19, emlTwoWayAnova.dfTotal, tightTolerance

# Partial eta-squared effect sizes
# scipy: partialEtaSqA = 500/(500+40) = 0.925926
#         partialEtaSqB = 80/(80+40) = 0.666667
#         partialEtaSqAB = 5/(5+40) = 0.111111
@emlTestAssertEqualNum: "4 partialEtaSqA", 0.925926,
    ... emlTwoWayAnova.partialEtaSqA, tolerance
@emlTestAssertEqualNum: "4 partialEtaSqB", 0.666667,
    ... emlTwoWayAnova.partialEtaSqB, tolerance
@emlTestAssertEqualNum: "4 partialEtaSqAB", 0.111111,
    ... emlTwoWayAnova.partialEtaSqAB, tolerance

removeObject: tableId4


# ══════════════════════════════════════════════════════════════════════════════
# TEST GROUP 5: @emlTwoWayAnova — 2×2, with interaction
# ══════════════════════════════════════════════════════════════════════════════

@emlTestSection: "@emlTwoWayAnova — 2x2, with interaction"

# Test Set 5:
#   A-Male:   {10,12,11,13,9}
#   A-Female: {20,22,21,23,19}
#   B-Male:   {18,20,19,21,17}
#   B-Female: {19,21,20,22,18}
#
# scipy: FactorA F=24.5, p=0.000145, SS=61.25, df=1
#         FactorB F=60.5, p=7.97e-7, SS=151.25, df=1
#         Interact F=40.5, p=9.39e-6, SS=101.25, df=1
#         Error SS=40, df=16, MS=2.5
#         Total SS=353.75, df=19

tableId5 = Create Table with column names: "twoWayTest5", 20,
    ... "value FactorA FactorB"

# A-Male: {10,12,11,13,9}
Set numeric value: 1, "value", 10
Set string value: 1, "FactorA", "A"
Set string value: 1, "FactorB", "Male"
Set numeric value: 2, "value", 12
Set string value: 2, "FactorA", "A"
Set string value: 2, "FactorB", "Male"
Set numeric value: 3, "value", 11
Set string value: 3, "FactorA", "A"
Set string value: 3, "FactorB", "Male"
Set numeric value: 4, "value", 13
Set string value: 4, "FactorA", "A"
Set string value: 4, "FactorB", "Male"
Set numeric value: 5, "value", 9
Set string value: 5, "FactorA", "A"
Set string value: 5, "FactorB", "Male"

# A-Female: {20,22,21,23,19}
Set numeric value: 6, "value", 20
Set string value: 6, "FactorA", "A"
Set string value: 6, "FactorB", "Female"
Set numeric value: 7, "value", 22
Set string value: 7, "FactorA", "A"
Set string value: 7, "FactorB", "Female"
Set numeric value: 8, "value", 21
Set string value: 8, "FactorA", "A"
Set string value: 8, "FactorB", "Female"
Set numeric value: 9, "value", 23
Set string value: 9, "FactorA", "A"
Set string value: 9, "FactorB", "Female"
Set numeric value: 10, "value", 19
Set string value: 10, "FactorA", "A"
Set string value: 10, "FactorB", "Female"

# B-Male: {18,20,19,21,17}
Set numeric value: 11, "value", 18
Set string value: 11, "FactorA", "B"
Set string value: 11, "FactorB", "Male"
Set numeric value: 12, "value", 20
Set string value: 12, "FactorA", "B"
Set string value: 12, "FactorB", "Male"
Set numeric value: 13, "value", 19
Set string value: 13, "FactorA", "B"
Set string value: 13, "FactorB", "Male"
Set numeric value: 14, "value", 21
Set string value: 14, "FactorA", "B"
Set string value: 14, "FactorB", "Male"
Set numeric value: 15, "value", 17
Set string value: 15, "FactorA", "B"
Set string value: 15, "FactorB", "Male"

# B-Female: {19,21,20,22,18}
Set numeric value: 16, "value", 19
Set string value: 16, "FactorA", "B"
Set string value: 16, "FactorB", "Female"
Set numeric value: 17, "value", 21
Set string value: 17, "FactorA", "B"
Set string value: 17, "FactorB", "Female"
Set numeric value: 18, "value", 20
Set string value: 18, "FactorA", "B"
Set string value: 18, "FactorB", "Female"
Set numeric value: 19, "value", 22
Set string value: 19, "FactorA", "B"
Set string value: 19, "FactorB", "Female"
Set numeric value: 20, "value", 18
Set string value: 20, "FactorA", "B"
Set string value: 20, "FactorB", "Female"

@emlTwoWayAnova: tableId5, "value", "FactorA", "FactorB"

@emlTestAssertEqualStr: "5 no error", "", emlTwoWayAnova.error$

# Factor A
@emlTestAssertEqualNum: "5 FactorA F", 24.5, emlTwoWayAnova.fA, tolerance
@emlTestAssertEqualNum: "5 FactorA p", 0.000145, emlTwoWayAnova.pA, tightTolerance
@emlTestAssertEqualNum: "5 FactorA SS", 61.25, emlTwoWayAnova.ssA, tolerance
@emlTestAssertEqualNum: "5 FactorA df", 1, emlTwoWayAnova.dfA, tightTolerance
@emlTestAssertEqualNum: "5 FactorA MS", 61.25, emlTwoWayAnova.msA, tolerance

# Factor B
@emlTestAssertEqualNum: "5 FactorB F", 60.5, emlTwoWayAnova.fB, tolerance
@emlTestAssertEqualNum: "5 FactorB p", 0.000000797, emlTwoWayAnova.pB, tightTolerance
@emlTestAssertEqualNum: "5 FactorB SS", 151.25, emlTwoWayAnova.ssB, tolerance
@emlTestAssertEqualNum: "5 FactorB df", 1, emlTwoWayAnova.dfB, tightTolerance
@emlTestAssertEqualNum: "5 FactorB MS", 151.25, emlTwoWayAnova.msB, tolerance

# Interaction
@emlTestAssertEqualNum: "5 Interact F", 40.5, emlTwoWayAnova.fAB, tolerance
@emlTestAssertEqualNum: "5 Interact p", 0.00000939, emlTwoWayAnova.pAB, tightTolerance
@emlTestAssertEqualNum: "5 Interact SS", 101.25, emlTwoWayAnova.ssAB, tolerance
@emlTestAssertEqualNum: "5 Interact df", 1, emlTwoWayAnova.dfAB, tightTolerance
@emlTestAssertEqualNum: "5 Interact MS", 101.25, emlTwoWayAnova.msAB, tolerance

# Error and Total
@emlTestAssertEqualNum: "5 Error SS", 40.0, emlTwoWayAnova.ssError, tolerance
@emlTestAssertEqualNum: "5 Error df", 16, emlTwoWayAnova.dfError, tightTolerance
@emlTestAssertEqualNum: "5 Error MS", 2.5, emlTwoWayAnova.msError, tolerance
@emlTestAssertEqualNum: "5 Total SS", 353.75, emlTwoWayAnova.ssTotal, tolerance
@emlTestAssertEqualNum: "5 Total df", 19, emlTwoWayAnova.dfTotal, tightTolerance

# Partial eta-squared effect sizes
# scipy: partialEtaSqA = 61.25/(61.25+40) = 0.604938
#         partialEtaSqB = 151.25/(151.25+40) = 0.790850
#         partialEtaSqAB = 101.25/(101.25+40) = 0.716814
@emlTestAssertEqualNum: "5 partialEtaSqA", 0.604938,
    ... emlTwoWayAnova.partialEtaSqA, tolerance
@emlTestAssertEqualNum: "5 partialEtaSqB", 0.790850,
    ... emlTwoWayAnova.partialEtaSqB, tolerance
@emlTestAssertEqualNum: "5 partialEtaSqAB", 0.716814,
    ... emlTwoWayAnova.partialEtaSqAB, tolerance

removeObject: tableId5


# ══════════════════════════════════════════════════════════════════════════════
# TEST GROUP 6: @emlTukeyHSD — standalone, 4 groups
# ══════════════════════════════════════════════════════════════════════════════

@emlTestSection: "@emlTukeyHSD — standalone, 4 groups"

# Test Set 6: {5,6,7,5.5,6.5}, {8,9,10,8.5,9.5}, {5.5,6,7.5,6,5}, {12,13,14,12.5,13.5}
# Group means: Group1=6.0, Group2=9.0, Group3=6.0, Group4=13.0
#
# Alphabetical order (Batch 9+): Group1, Group2, Group3, Group4
# MSE = 0.6875, dfWithin = 16
# qCritical(0.05, 4, 16) = 4.046093
#
# scipy pairwise q and p (alphabetical):
#   [1,2] G1vG2: q=8.0904, p=1.6781e-4, meanDiff=-3.0
#   [1,3] G1vG3: q=0.0,    p=1.0,       meanDiff=0.0
#   [1,4] G1vG4: q=18.878, p=2.4299e-9, meanDiff=-7.0
#   [2,3] G2vG3: q=8.0904, p=1.6781e-4, meanDiff=3.0
#   [2,4] G2vG4: q=10.787, p=5.6001e-6, meanDiff=-4.0
#   [3,4] G3vG4: q=18.878, p=2.4299e-9, meanDiff=-7.0

emlTableFromGroups.groupLabel$[1] = "Group1"
emlTableFromGroups.groupLabel$[2] = "Group2"
emlTableFromGroups.groupLabel$[3] = "Group3"
emlTableFromGroups.groupLabel$[4] = "Group4"
emlTableFromGroups.groupSize[1] = 5
emlTableFromGroups.groupSize[2] = 5
emlTableFromGroups.groupSize[3] = 5
emlTableFromGroups.groupSize[4] = 5
emlTableFromGroups.data# = {5, 6, 7, 5.5, 6.5, 8, 9, 10, 8.5, 9.5,
    ... 5.5, 6, 7.5, 6, 5, 12, 13, 14, 12.5, 13.5}
@emlTableFromGroups: 4, "value", "group"
tableId6 = emlTableFromGroups.tableId

@emlTukeyHSD: tableId6, "value", "group", 0.05

@emlTestAssertEqualStr: "6 no error", "", emlTukeyHSD.error$
@emlTestAssertEqualNum: "6 nGroups", 4, emlTukeyHSD.nGroups, tightTolerance
@emlTestAssertEqualNum: "6 nPairs", 6, emlTukeyHSD.nPairs, tightTolerance

# Group names in alphabetical order
@emlTestAssertEqualStr: "6 groupName 1", "Group1", emlTukeyHSD.groupName$[1]
@emlTestAssertEqualStr: "6 groupName 2", "Group2", emlTukeyHSD.groupName$[2]
@emlTestAssertEqualStr: "6 groupName 3", "Group3", emlTukeyHSD.groupName$[3]
@emlTestAssertEqualStr: "6 groupName 4", "Group4", emlTukeyHSD.groupName$[4]

# Pooled MSE and degrees of freedom
@emlTestAssertEqualNum: "6 msWithin", 0.6875, emlTukeyHSD.msWithin, tightTolerance
@emlTestAssertEqualNum: "6 dfWithin", 16, emlTukeyHSD.dfWithin, tightTolerance

# Critical q at alpha=0.05
@emlTestAssertEqualNum: "6 qCritical", 4.046093,
    ... emlTukeyHSD.qCritical, tolerance

# Diagonal p = 1
@emlTestAssertEqualNum: "6 diag [1,1]", 1.0, emlTukeyHSD.pMatrix##[1, 1], tightTolerance
@emlTestAssertEqualNum: "6 diag [2,2]", 1.0, emlTukeyHSD.pMatrix##[2, 2], tightTolerance
@emlTestAssertEqualNum: "6 diag [3,3]", 1.0, emlTukeyHSD.pMatrix##[3, 3], tightTolerance
@emlTestAssertEqualNum: "6 diag [4,4]", 1.0, emlTukeyHSD.pMatrix##[4, 4], tightTolerance

# Pairwise p-values (alphabetical order)
@emlTestAssertEqualNum: "6 G1vG2 p [1,2]", 0.000168,
    ... emlTukeyHSD.pMatrix##[1, 2], looseTolerance
@emlTestAssertEqualNum: "6 G1vG3 p [1,3]", 1.0,
    ... emlTukeyHSD.pMatrix##[1, 3], looseTolerance
@emlTestAssertEqualNum: "6 G1vG4 p [1,4]", 0.0000000024,
    ... emlTukeyHSD.pMatrix##[1, 4], tightTolerance
@emlTestAssertEqualNum: "6 G2vG3 p [2,3]", 0.000168,
    ... emlTukeyHSD.pMatrix##[2, 3], looseTolerance
@emlTestAssertEqualNum: "6 G2vG4 p [2,4]", 0.0000056,
    ... emlTukeyHSD.pMatrix##[2, 4], tightTolerance
@emlTestAssertEqualNum: "6 G3vG4 p [3,4]", 0.0000000024,
    ... emlTukeyHSD.pMatrix##[3, 4], tightTolerance

# Pairwise q statistics
@emlTestAssertEqualNum: "6 G1vG2 q [1,2]", 8.0904,
    ... emlTukeyHSD.qMatrix##[1, 2], tolerance
@emlTestAssertEqualNum: "6 G1vG3 q [1,3]", 0.0,
    ... emlTukeyHSD.qMatrix##[1, 3], tightTolerance
@emlTestAssertEqualNum: "6 G1vG4 q [1,4]", 18.8776,
    ... emlTukeyHSD.qMatrix##[1, 4], tolerance
@emlTestAssertEqualNum: "6 G2vG4 q [2,4]", 10.7872,
    ... emlTukeyHSD.qMatrix##[2, 4], tolerance

# Mean differences (antisymmetric)
@emlTestAssertEqualNum: "6 G1-G2 meanDiff [1,2]", -3.0,
    ... emlTukeyHSD.meanDiff##[1, 2], tightTolerance
@emlTestAssertEqualNum: "6 G1-G3 meanDiff [1,3]", 0.0,
    ... emlTukeyHSD.meanDiff##[1, 3], tightTolerance
@emlTestAssertEqualNum: "6 G1-G4 meanDiff [1,4]", -7.0,
    ... emlTukeyHSD.meanDiff##[1, 4], tightTolerance
@emlTestAssertEqualNum: "6 G2-G3 meanDiff [2,3]", 3.0,
    ... emlTukeyHSD.meanDiff##[2, 3], tightTolerance

# Symmetry checks (p and q symmetric, meanDiff antisymmetric)
@emlTestAssertEqualNum: "6 p symm [2,1]=[1,2]",
    ... emlTukeyHSD.pMatrix##[1, 2], emlTukeyHSD.pMatrix##[2, 1], tightTolerance
@emlTestAssertEqualNum: "6 q symm [3,1]=[1,3]",
    ... emlTukeyHSD.qMatrix##[1, 3], emlTukeyHSD.qMatrix##[3, 1], tightTolerance
@emlTestAssertEqualNum: "6 meanDiff antisymm [2,1]",
    ... emlTukeyHSD.meanDiff##[2, 1], -emlTukeyHSD.meanDiff##[1, 2], tightTolerance

removeObject: tableId6


# ══════════════════════════════════════════════════════════════════════════════
# TEST GROUP 7: @emlOneWayAnova with tukey=1 chaining
# ══════════════════════════════════════════════════════════════════════════════

@emlTestSection: "@emlOneWayAnova — tukey chaining"

# Reuse Test Set 1 data, but with tukey=1 to exercise the chaining path
# Group means: Group1=24.6, Group2=31.4, Group3=19.2
#
# Alphabetical order (Batch 9+): Group1, Group2, Group3
# MSE = 4.1, dfWithin = 12
# etaSquared = 373.7333 / 422.9333 = 0.88367
# qCritical(0.05, 3, 12) = 3.77293
#
# scipy Tukey p-values (alphabetical):
#   [1,2] G1vG2: q=7.5093, p=5.024e-4, meanDiff=-6.8
#   [1,3] G1vG3: q=5.9633, p=3.167e-3, meanDiff=5.4
#   [2,3] G2vG3: q=13.473, p=1.683e-6, meanDiff=12.2

emlTableFromGroups.groupLabel$[1] = "Group1"
emlTableFromGroups.groupLabel$[2] = "Group2"
emlTableFromGroups.groupLabel$[3] = "Group3"
emlTableFromGroups.groupSize[1] = 5
emlTableFromGroups.groupSize[2] = 5
emlTableFromGroups.groupSize[3] = 5
emlTableFromGroups.data# = {23, 25, 27, 22, 26, 30, 33, 29, 31, 34,
    ... 18, 20, 22, 19, 17}
@emlTableFromGroups: 3, "value", "group"
tableId7 = emlTableFromGroups.tableId

@emlOneWayAnova: tableId7, "value", "group", 1

@emlTestAssertEqualStr: "7 no error", "", emlOneWayAnova.error$

# ANOVA stats should be identical to Group 1
@emlTestAssertEqualNum: "7 F", 45.5772, emlOneWayAnova.fValue, tolerance
@emlTestAssertEqualNum: "7 etaSquared", 0.88367,
    ... emlOneWayAnova.etaSquared, tolerance

# Tukey outputs chained through (alphabetical order)
@emlTestAssertEqualNum: "7 nPairs", 3, emlOneWayAnova.nPairs, tightTolerance
@emlTestAssertEqualNum: "7 Tukey G1vG2 p [1,2]", 0.000502,
    ... emlOneWayAnova.pMatrix##[1, 2], looseTolerance
@emlTestAssertEqualNum: "7 Tukey G1vG3 p [1,3]", 0.003167,
    ... emlOneWayAnova.pMatrix##[1, 3], looseTolerance
@emlTestAssertEqualNum: "7 Tukey G2vG3 p [2,3]", 0.0000017,
    ... emlOneWayAnova.pMatrix##[2, 3], tightTolerance

# q statistics
@emlTestAssertEqualNum: "7 Tukey G1vG2 q [1,2]", 7.5093,
    ... emlOneWayAnova.qMatrix##[1, 2], tolerance
@emlTestAssertEqualNum: "7 Tukey G1vG3 q [1,3]", 5.9633,
    ... emlOneWayAnova.qMatrix##[1, 3], tolerance
@emlTestAssertEqualNum: "7 Tukey G2vG3 q [2,3]", 13.4726,
    ... emlOneWayAnova.qMatrix##[2, 3], tolerance

# Mean differences
@emlTestAssertEqualNum: "7 meanDiff G1-G2 [1,2]", -6.8,
    ... emlOneWayAnova.meanDiff##[1, 2], tightTolerance
@emlTestAssertEqualNum: "7 meanDiff G1-G3 [1,3]", 5.4,
    ... emlOneWayAnova.meanDiff##[1, 3], tightTolerance
@emlTestAssertEqualNum: "7 meanDiff G2-G3 [2,3]", 12.2,
    ... emlOneWayAnova.meanDiff##[2, 3], tightTolerance

# Critical q
@emlTestAssertEqualNum: "7 qCritical", 3.77293,
    ... emlOneWayAnova.qCritical, tolerance

# Group names in alphabetical order
@emlTestAssertEqualStr: "7 groupName 1", "Group1",
    ... emlOneWayAnova.groupName$[1]
@emlTestAssertEqualStr: "7 groupName 2", "Group2",
    ... emlOneWayAnova.groupName$[2]
@emlTestAssertEqualStr: "7 groupName 3", "Group3",
    ... emlOneWayAnova.groupName$[3]

removeObject: tableId7


# ══════════════════════════════════════════════════════════════════════════════
# TEST GROUP 8: @emlTableFromGroups — round-trip validation
# ══════════════════════════════════════════════════════════════════════════════

@emlTestSection: "@emlTableFromGroups — round-trip"

# Minimal 2-group case: verify Table structure

emlTableFromGroups.groupLabel$[1] = "Alpha"
emlTableFromGroups.groupLabel$[2] = "Beta"
emlTableFromGroups.groupSize[1] = 3
emlTableFromGroups.groupSize[2] = 2
emlTableFromGroups.data# = {10, 20, 30, 40, 50}
@emlTableFromGroups: 2, "Score", "Category"

@emlTestAssertEqualStr: "8 no error", "", emlTableFromGroups.error$
@emlTestAssertEqualNum: "8 nRows", 5, emlTableFromGroups.nRows, tightTolerance
@emlTestAssertTrue: "8 tableId > 0", emlTableFromGroups.tableId > 0

# Verify Table contents
selectObject: emlTableFromGroups.tableId
nRows8 = Get number of rows
@emlTestAssertEqualNum: "8 table rows", 5, nRows8, tightTolerance

# Spot-check values
selectObject: emlTableFromGroups.tableId
val8_1 = Get value: 1, "Score"
val8_3 = Get value: 3, "Score"
val8_4 = Get value: 4, "Score"
val8_5 = Get value: 5, "Score"
cat8_1$ = Get value: 1, "Category"
cat8_3$ = Get value: 3, "Category"
cat8_4$ = Get value: 4, "Category"
cat8_5$ = Get value: 5, "Category"

@emlTestAssertEqualNum: "8 row 1 value", 10, val8_1, tightTolerance
@emlTestAssertEqualNum: "8 row 3 value", 30, val8_3, tightTolerance
@emlTestAssertEqualNum: "8 row 4 value", 40, val8_4, tightTolerance
@emlTestAssertEqualNum: "8 row 5 value", 50, val8_5, tightTolerance
@emlTestAssertEqualStr: "8 row 1 category", "Alpha", cat8_1$
@emlTestAssertEqualStr: "8 row 3 category", "Alpha", cat8_3$
@emlTestAssertEqualStr: "8 row 4 category", "Beta", cat8_4$
@emlTestAssertEqualStr: "8 row 5 category", "Beta", cat8_5$

removeObject: emlTableFromGroups.tableId


# ══════════════════════════════════════════════════════════════════════════════
# TEST GROUP 9: Error handling
# ══════════════════════════════════════════════════════════════════════════════

@emlTestSection: "Error handling"

# --- 9.1: Missing data column (one-way) ---

tableId9a = Create Table with column names: "errTest1", 5, "score group"
selectObject: tableId9a
for iRow from 1 to 5
    Set numeric value: iRow, "score", iRow
    Set string value: iRow, "group", "A"
endfor

@emlOneWayAnova: tableId9a, "wrongColumn", "group", 0
@emlTestAssertContains: "9.1 missing data col",
    ... emlOneWayAnova.error$, "data column not found"

removeObject: tableId9a

# --- 9.2: Missing factor column (one-way) ---

tableId9b = Create Table with column names: "errTest2", 5, "score group"
selectObject: tableId9b
for iRow from 1 to 5
    Set numeric value: iRow, "score", iRow
    Set string value: iRow, "group", "A"
endfor

@emlOneWayAnova: tableId9b, "score", "wrongFactor", 0
@emlTestAssertContains: "9.2 missing factor col",
    ... emlOneWayAnova.error$, "factor column not found"

removeObject: tableId9b

# --- 9.3: Too few observations (Tukey) ---

tableId9c = Create Table with column names: "errTest3", 2, "val grp"
selectObject: tableId9c
Set numeric value: 1, "val", 10
Set string value: 1, "grp", "X"
Set numeric value: 2, "val", 20
Set string value: 2, "grp", "Y"

@emlTukeyHSD: tableId9c, "val", "grp", 0.05
@emlTestAssertContains: "9.3 too few obs Tukey",
    ... emlTukeyHSD.error$, "at least 3"

removeObject: tableId9c

# --- 9.4: Missing column (two-way) ---

tableId9d = Create Table with column names: "errTest4", 4,
    ... "value Factor1 Factor2"
selectObject: tableId9d
for iRow from 1 to 4
    Set numeric value: iRow, "value", iRow
    if iRow <= 2
        Set string value: iRow, "Factor1", "A"
    else
        Set string value: iRow, "Factor1", "B"
    endif
    if iRow mod 2 = 1
        Set string value: iRow, "Factor2", "X"
    else
        Set string value: iRow, "Factor2", "Y"
    endif
endfor

@emlTwoWayAnova: tableId9d, "value", "Missing", "Factor2"
@emlTestAssertContains: "9.4 missing factor1 two-way",
    ... emlTwoWayAnova.error$, "factor1 column not found"

removeObject: tableId9d

# --- 9.5: @emlTableFromGroups — data vector mismatch ---

emlTableFromGroups.groupLabel$[1] = "A"
emlTableFromGroups.groupLabel$[2] = "B"
emlTableFromGroups.groupSize[1] = 3
emlTableFromGroups.groupSize[2] = 3
emlTableFromGroups.data# = {1, 2, 3, 4}
@emlTableFromGroups: 2, "val", "grp"
@emlTestAssertContains: "9.5 data vector mismatch",
    ... emlTableFromGroups.error$, "does not match"

# --- 9.6: @emlTableFromGroups — zero groups ---

emlTableFromGroups.data# = {1}
emlTableFromGroups.groupSize[1] = 1
emlTableFromGroups.groupLabel$[1] = "X"
@emlTableFromGroups: 0, "val", "grp"
@emlTestAssertContains: "9.6 zero groups",
    ... emlTableFromGroups.error$, "nGroups must be >= 1"


# ══════════════════════════════════════════════════════════════════════════════
# TEST GROUP 10: @emlTukeyHSD — unbalanced 3-group design
# ══════════════════════════════════════════════════════════════════════════════

@emlTestSection: "@emlTukeyHSD — unbalanced 3 groups"

# Test Set 10: A={10,12,11}, B={20,22,21,23}, C={15,17}
# Unbalanced: n_A=3, n_B=4, n_C=2
# Group means: A=11.0, B=21.5, C=16.0
# Alphabetical: A, B, C
#
# MSE = 1.5, dfWithin = 6
# qCritical(0.05, 3, 6) = 4.339195
#
# scipy pairwise (using pairwise SE):
#   [1,2] AvB: q=15.8745, p=7.373e-5, meanDiff=-10.5
#   [1,3] AvC: q=6.3246,  p=1.004e-2, meanDiff=-5.0
#   [2,3] BvC: q=7.3333,  p=4.909e-3, meanDiff=5.5

tableId10 = Create Table with column names: "unbalancedTest", 9,
    ... "value group"

# A: {10, 12, 11}
selectObject: tableId10
Set numeric value: 1, "value", 10
Set string value: 1, "group", "A"
Set numeric value: 2, "value", 12
Set string value: 2, "group", "A"
Set numeric value: 3, "value", 11
Set string value: 3, "group", "A"

# B: {20, 22, 21, 23}
Set numeric value: 4, "value", 20
Set string value: 4, "group", "B"
Set numeric value: 5, "value", 22
Set string value: 5, "group", "B"
Set numeric value: 6, "value", 21
Set string value: 6, "group", "B"
Set numeric value: 7, "value", 23
Set string value: 7, "group", "B"

# C: {15, 17}
Set numeric value: 8, "value", 15
Set string value: 8, "group", "C"
Set numeric value: 9, "value", 17
Set string value: 9, "group", "C"

@emlTukeyHSD: tableId10, "value", "group", 0.05

@emlTestAssertEqualStr: "10 no error", "", emlTukeyHSD.error$
@emlTestAssertEqualNum: "10 nGroups", 3, emlTukeyHSD.nGroups, tightTolerance
@emlTestAssertEqualNum: "10 nPairs", 3, emlTukeyHSD.nPairs, tightTolerance

# Group names in alphabetical order
@emlTestAssertEqualStr: "10 groupName 1", "A", emlTukeyHSD.groupName$[1]
@emlTestAssertEqualStr: "10 groupName 2", "B", emlTukeyHSD.groupName$[2]
@emlTestAssertEqualStr: "10 groupName 3", "C", emlTukeyHSD.groupName$[3]

# Pooled MSE and degrees of freedom
@emlTestAssertEqualNum: "10 msWithin", 1.5, emlTukeyHSD.msWithin, tightTolerance
@emlTestAssertEqualNum: "10 dfWithin", 6, emlTukeyHSD.dfWithin, tightTolerance
@emlTestAssertEqualNum: "10 qCritical", 4.339195,
    ... emlTukeyHSD.qCritical, tolerance

# Pairwise p-values
@emlTestAssertEqualNum: "10 AvB p [1,2]", 0.0000737,
    ... emlTukeyHSD.pMatrix##[1, 2], tightTolerance
@emlTestAssertEqualNum: "10 AvC p [1,3]", 0.01004,
    ... emlTukeyHSD.pMatrix##[1, 3], looseTolerance
@emlTestAssertEqualNum: "10 BvC p [2,3]", 0.004909,
    ... emlTukeyHSD.pMatrix##[2, 3], looseTolerance

# Pairwise q statistics
@emlTestAssertEqualNum: "10 AvB q [1,2]", 15.8745,
    ... emlTukeyHSD.qMatrix##[1, 2], tolerance
@emlTestAssertEqualNum: "10 AvC q [1,3]", 6.3246,
    ... emlTukeyHSD.qMatrix##[1, 3], tolerance
@emlTestAssertEqualNum: "10 BvC q [2,3]", 7.3333,
    ... emlTukeyHSD.qMatrix##[2, 3], tolerance

# Mean differences
@emlTestAssertEqualNum: "10 A-B meanDiff [1,2]", -10.5,
    ... emlTukeyHSD.meanDiff##[1, 2], tightTolerance
@emlTestAssertEqualNum: "10 A-C meanDiff [1,3]", -5.0,
    ... emlTukeyHSD.meanDiff##[1, 3], tightTolerance
@emlTestAssertEqualNum: "10 B-C meanDiff [2,3]", 5.5,
    ... emlTukeyHSD.meanDiff##[2, 3], tightTolerance

removeObject: tableId10


# ══════════════════════════════════════════════════════════════════════════════
# SUMMARY
# ══════════════════════════════════════════════════════════════════════════════

@emlTestSummary
