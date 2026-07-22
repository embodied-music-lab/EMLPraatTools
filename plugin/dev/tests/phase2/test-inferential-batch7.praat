# ============================================================================
# EML Stats : Test Suite — Inferential Statistics (Batch 7)
# ============================================================================
# Tests: @emlKruskalWallis, @emlEpsilonSquared, @emlDunnTest
# Date: 15 March 2026
#
# Reference values: scipy.stats.kruskal, custom Dunn's (batch7_scipy_refs.py)
# R verification: verify-inferential-batch7.R (dunn.test package)
#
# Uses shared test helpers (eml-test-helpers.praat).
# ============================================================================

include ../../../stats/eml-core-utilities.praat
include ../../../stats/eml-core-descriptive.praat
include ../../../stats/eml-extract.praat
include ../../../stats/eml-output.praat
include ../../../stats/eml-inferential.praat
include ../eml-test-helpers.praat

@emlTestInit

tolerance = 0.0001
toleranceLoose = 0.001


# ============================================================================
# HELPER: Build Table from group vectors (up to 4 groups)
# ============================================================================

procedure buildTestTable: .g1#, .g2#, .g3#, .g4#
    .n1 = size (.g1#)
    .n2 = size (.g2#)
    .n3 = size (.g3#)
    .n4 = size (.g4#)
    .nTotal = .n1 + .n2 + .n3 + .n4
    .nGroups = 0
    if .n1 > 0
        .nGroups = 1
    endif
    if .n2 > 0
        .nGroups = 2
    endif
    if .n3 > 0
        .nGroups = 3
    endif
    if .n4 > 0
        .nGroups = 4
    endif

    .tableId = Create Table with column names: "testData",
    ... .nTotal, "Value Group"
    .row = 0

    for .i from 1 to .n1
        .row = .row + 1
        selectObject: .tableId
        Set numeric value: .row, "Value", .g1#[.i]
        Set string value: .row, "Group", "G1"
    endfor
    for .i from 1 to .n2
        .row = .row + 1
        selectObject: .tableId
        Set numeric value: .row, "Value", .g2#[.i]
        Set string value: .row, "Group", "G2"
    endfor
    for .i from 1 to .n3
        .row = .row + 1
        selectObject: .tableId
        Set numeric value: .row, "Value", .g3#[.i]
        Set string value: .row, "Group", "G3"
    endfor
    for .i from 1 to .n4
        .row = .row + 1
        selectObject: .tableId
        Set numeric value: .row, "Value", .g4#[.i]
        Set string value: .row, "Group", "G4"
    endfor
endproc


# ============================================================================
# Section 1: @emlKruskalWallis — Basic (Test Sets 1–4)
# ============================================================================

@emlTestSection: "KW Basic (Test Sets 1-4)"

# --- KW-1: 3 groups, clear effect, ties in raw data (22 in G1 and G3) ---

.g1# = {23, 25, 27, 22, 26}
.g2# = {30, 33, 29, 31, 34}
.g3# = {18, 20, 22, 19, 17}
@buildTestTable: .g1#, .g2#, .g3#, zero# (0)
.t1Id = buildTestTable.tableId

@emlKruskalWallis: .t1Id, "Value", "Group"

@emlTestAssertTrue: "KW-1 no error", (emlKruskalWallis.error$ = "")
@emlTestAssertEqualNum: "KW-1 H", 12.2769230769, emlKruskalWallis.h,
... tolerance
@emlTestAssertEqualNum: "KW-1 p", 0.0021582414, emlKruskalWallis.p,
... tolerance
@emlTestAssertEqualNum: "KW-1 df", 2, emlKruskalWallis.df, 0
@emlTestAssertEqualNum: "KW-1 N", 15, emlKruskalWallis.n, 0
@emlTestAssertEqualNum: "KW-1 nGroups", 3, emlKruskalWallis.nGroups, 0
@emlTestAssertEqualNum: "KW-1 epsilon-sq", 0.8769230769,
... emlKruskalWallis.epsilonSq, tolerance
@emlTestAssertEqualNum: "KW-1 tieCorrection", 0.9982142857,
... emlKruskalWallis.tieCorrection, tolerance
@emlTestAssertEqualNum: "KW-1 mean rank G1", 7.9,
... emlKruskalWallis.meanRank[1], tolerance
@emlTestAssertEqualNum: "KW-1 mean rank G2", 13.0,
... emlKruskalWallis.meanRank[2], tolerance
@emlTestAssertEqualNum: "KW-1 mean rank G3", 3.1,
... emlKruskalWallis.meanRank[3], tolerance

removeObject: .t1Id


# --- KW-2: 3 groups, no effect (identical distributions) ---

.g4# = {10, 11, 12, 10.5, 11.5}
.g5# = {10.5, 11, 11.5, 10, 12}
.g6# = {11, 10.5, 11.5, 10, 12}
@buildTestTable: .g4#, .g5#, .g6#, zero# (0)
.t2Id = buildTestTable.tableId

@emlKruskalWallis: .t2Id, "Value", "Group"

@emlTestAssertEqualNum: "KW-2 H = 0", 0.0, emlKruskalWallis.h, tolerance
@emlTestAssertEqualNum: "KW-2 p = 1", 1.0, emlKruskalWallis.p, tolerance
@emlTestAssertEqualNum: "KW-2 eps-sq = 0", 0.0,
... emlKruskalWallis.epsilonSq, tolerance
@emlTestAssertEqualNum: "KW-2 mean rank G1", 8.0,
... emlKruskalWallis.meanRank[1], tolerance
@emlTestAssertEqualNum: "KW-2 mean rank G2", 8.0,
... emlKruskalWallis.meanRank[2], tolerance
@emlTestAssertEqualNum: "KW-2 mean rank G3", 8.0,
... emlKruskalWallis.meanRank[3], tolerance

removeObject: .t2Id


# --- KW-3: 4 groups, unequal sizes, ties ---

.g7# = {5, 6, 7, 5, 6}
.g8# = {8, 9, 10, 8}
.g9# = {5, 6, 7}
.g10# = {12, 13, 14, 12, 13, 15}
@buildTestTable: .g7#, .g8#, .g9#, .g10#
.t3Id = buildTestTable.tableId

@emlKruskalWallis: .t3Id, "Value", "Group"

@emlTestAssertEqualNum: "KW-3 H", 14.9405781958, emlKruskalWallis.h,
... tolerance
@emlTestAssertEqualNum: "KW-3 p", 0.0018681395, emlKruskalWallis.p,
... tolerance
@emlTestAssertEqualNum: "KW-3 df", 3, emlKruskalWallis.df, 0
@emlTestAssertEqualNum: "KW-3 N", 18, emlKruskalWallis.n, 0
@emlTestAssertEqualNum: "KW-3 nGroups", 4, emlKruskalWallis.nGroups, 0
@emlTestAssertEqualNum: "KW-3 eps-sq", 0.8788575409,
... emlKruskalWallis.epsilonSq, tolerance
@emlTestAssertEqualNum: "KW-3 tieCorrection", 0.9876160991,
... emlKruskalWallis.tieCorrection, tolerance
@emlTestAssertEqualNum: "KW-3 mean rank G1", 4.3,
... emlKruskalWallis.meanRank[1], tolerance
@emlTestAssertEqualNum: "KW-3 mean rank G2", 10.5,
... emlKruskalWallis.meanRank[2], tolerance
@emlTestAssertEqualNum: "KW-3 mean rank G3", 4.833333,
... emlKruskalWallis.meanRank[3], toleranceLoose
@emlTestAssertEqualNum: "KW-3 mean rank G4", 15.5,
... emlKruskalWallis.meanRank[4], tolerance

removeObject: .t3Id


# --- KW-4: 2 groups ---

.g11# = {5, 7, 9, 6, 8}
.g12# = {10, 12, 11, 13, 14}
@buildTestTable: .g11#, .g12#, zero# (0), zero# (0)
.t4Id = buildTestTable.tableId

@emlKruskalWallis: .t4Id, "Value", "Group"

@emlTestAssertEqualNum: "KW-4 H (2 groups)", 6.8181818182,
... emlKruskalWallis.h, tolerance
@emlTestAssertEqualNum: "KW-4 p", 0.0090234388,
... emlKruskalWallis.p, tolerance
@emlTestAssertEqualNum: "KW-4 df = 1", 1, emlKruskalWallis.df, 0
@emlTestAssertEqualNum: "KW-4 eps-sq", 0.7575757576,
... emlKruskalWallis.epsilonSq, tolerance

removeObject: .t4Id


# ============================================================================
# Section 2: @emlKruskalWallis — Large sample (Test Set 5)
# ============================================================================

@emlTestSection: "KW Large Sample (Test Set 5)"

.lg1# = {54.967142, 48.617357, 56.476885, 65.230299, 47.658466,
... 47.658630, 65.792128, 57.674347, 45.305256, 55.425600,
... 45.365823, 45.342702, 52.419623, 30.867198, 32.750822,
... 44.377125, 39.871689, 53.142473, 40.919759, 35.876963,
... 64.656488, 47.742237, 50.675282, 35.752518, 44.556173,
... 51.109226, 38.490064, 53.756980, 43.993613, 47.083063}

.lg2# = {48.982934, 73.522782, 54.865028, 44.422891, 63.225449,
... 42.791564, 57.088636, 35.403299, 41.718140, 56.968612,
... 62.384666, 56.713683, 53.843517, 51.988963, 40.214780,
... 47.801558, 50.393612, 65.571222, 58.436183, 37.369598,
... 58.240840, 51.149177, 48.230780, 61.116763, 65.309995,
... 64.312801, 46.607825, 51.907876, 58.312634, 64.755451}

.lg3# = {40.208258, 43.143410, 33.936650, 33.037934, 53.125258,
... 58.562400, 44.279899, 55.035329, 48.616360, 38.548802,
... 48.613956, 60.380366, 44.641740, 60.646437, 18.802549,
... 53.219025, 45.870471, 42.009926, 45.917608, 25.124311,
... 42.803281, 48.571126, 59.778940, 39.817298, 36.915064,
... 39.982430, 54.154021, 48.287511, 39.702398, 50.132674}

@buildTestTable: .lg1#, .lg2#, .lg3#, zero# (0)
.t5Id = buildTestTable.tableId

@emlKruskalWallis: .t5Id, "Value", "Group"

@emlTestAssertEqualNum: "KW-5 H", 10.6403907204, emlKruskalWallis.h,
... tolerance
@emlTestAssertEqualNum: "KW-5 p", 0.0048917980, emlKruskalWallis.p,
... tolerance
@emlTestAssertEqualNum: "KW-5 N", 90, emlKruskalWallis.n, 0
@emlTestAssertEqualNum: "KW-5 eps-sq", 0.1195549519,
... emlKruskalWallis.epsilonSq, tolerance
@emlTestAssertEqualNum: "KW-5 mean rank G1", 42.466667,
... emlKruskalWallis.meanRank[1], toleranceLoose
@emlTestAssertEqualNum: "KW-5 mean rank G2", 57.700000,
... emlKruskalWallis.meanRank[2], toleranceLoose
@emlTestAssertEqualNum: "KW-5 mean rank G3", 36.333333,
... emlKruskalWallis.meanRank[3], toleranceLoose
@emlTestAssertEqualNum: "KW-5 tieCorr = 1", 1.0,
... emlKruskalWallis.tieCorrection, tolerance

removeObject: .t5Id


# ============================================================================
# Section 3: @emlKruskalWallis — Edge cases
# ============================================================================

@emlTestSection: "KW Edge Cases"

# --- KW-6: Single observation per group ---

.g16# = {1}
.g17# = {2}
.g18# = {3}
@buildTestTable: .g16#, .g17#, .g18#, zero# (0)
.t6Id = buildTestTable.tableId

@emlKruskalWallis: .t6Id, "Value", "Group"

@emlTestAssertTrue: "KW-6 no error", (emlKruskalWallis.error$ = "")
@emlTestAssertEqualNum: "KW-6 H = 2", 2.0, emlKruskalWallis.h,
... tolerance
@emlTestAssertEqualNum: "KW-6 p", 0.3678794412,
... emlKruskalWallis.p, tolerance
@emlTestAssertEqualNum: "KW-6 eps-sq = 1", 1.0,
... emlKruskalWallis.epsilonSq, tolerance

removeObject: .t6Id


# --- KW-7: All identical values ---

.g19# = {5, 5, 5}
.g20# = {5, 5, 5}
@buildTestTable: .g19#, .g20#, zero# (0), zero# (0)
.t7Id = buildTestTable.tableId

@emlKruskalWallis: .t7Id, "Value", "Group"

@emlTestAssertTrue: "KW-7 no error (all identical)",
... (emlKruskalWallis.error$ = "")
@emlTestAssertEqualNum: "KW-7 H = 0", 0, emlKruskalWallis.h, tolerance
@emlTestAssertEqualNum: "KW-7 p = 1", 1, emlKruskalWallis.p, tolerance

removeObject: .t7Id


# --- KW error: single group ---

.gSingle# = {1, 2, 3}
@buildTestTable: .gSingle#, zero# (0), zero# (0), zero# (0)
.tErrId = buildTestTable.tableId

@emlKruskalWallis: .tErrId, "Value", "Group"

@emlTestAssertTrue: "KW error: single group",
... (emlKruskalWallis.error$ <> "")

removeObject: .tErrId


# ============================================================================
# Section 4: @emlEpsilonSquared — Standalone
# ============================================================================

@emlTestSection: "Epsilon-Squared Standalone"

@emlEpsilonSquared: 12.2769230769, 15
@emlTestAssertEqualNum: "EpsSq basic", 0.8769230769,
... emlEpsilonSquared.result, tolerance

@emlEpsilonSquared: 0, 100
@emlTestAssertEqualNum: "EpsSq H=0", 0, emlEpsilonSquared.result,
... tolerance

@emlEpsilonSquared: 14, 15
@emlTestAssertEqualNum: "EpsSq H=N-1 gives 1", 1.0,
... emlEpsilonSquared.result, tolerance

@emlEpsilonSquared: 5, 1
@emlTestAssertTrue: "EpsSq error N=1", (emlEpsilonSquared.error$ <> "")

@emlEpsilonSquared: -1, 10
@emlTestAssertTrue: "EpsSq error H<0", (emlEpsilonSquared.error$ <> "")


# ============================================================================
# Section 5: @emlDunnTest — Bonferroni (Test Sets 1, 3)
# ============================================================================

@emlTestSection: "Dunn Bonferroni (Test Sets 1, 3)"

# --- Dunn-1: 3 groups, clear effect ---

.g1# = {23, 25, 27, 22, 26}
.g2# = {30, 33, 29, 31, 34}
.g3# = {18, 20, 22, 19, 17}
@buildTestTable: .g1#, .g2#, .g3#, zero# (0)
.d1Id = buildTestTable.tableId

@emlDunnTest: .d1Id, "Value", "Group", "bonferroni"

@emlTestAssertTrue: "Dunn-1 no error", (emlDunnTest.error$ = "")
@emlTestAssertEqualNum: "Dunn-1 nPairs", 3, emlDunnTest.nPairs, 0
@emlTestAssertEqualNum: "Dunn-1 nGroups", 3, emlDunnTest.nGroups, 0

# z-values: pair order (1,2), (1,3), (2,3)
@emlTestAssertEqualNum: "Dunn-1 z(1,2)", -1.80473438,
... emlDunnTest.zFlat#[1], tolerance
@emlTestAssertEqualNum: "Dunn-1 z(1,3)", 1.69857354,
... emlDunnTest.zFlat#[2], tolerance
@emlTestAssertEqualNum: "Dunn-1 z(2,3)", 3.50330792,
... emlDunnTest.zFlat#[3], tolerance

# Raw p-values
@emlTestAssertEqualNum: "Dunn-1 raw p(1,2)", 0.07111626,
... emlDunnTest.rawP#[1], tolerance
@emlTestAssertEqualNum: "Dunn-1 raw p(1,3)", 0.08939957,
... emlDunnTest.rawP#[2], tolerance
@emlTestAssertEqualNum: "Dunn-1 raw p(2,3)", 0.00045952,
... emlDunnTest.rawP#[3], tolerance

# Adjusted p-values (Bonferroni)
@emlTestAssertEqualNum: "Dunn-1 adj p(1,2) Bonf", 0.21334877,
... emlDunnTest.adjustedP#[1], tolerance
@emlTestAssertEqualNum: "Dunn-1 adj p(1,3) Bonf", 0.26819870,
... emlDunnTest.adjustedP#[2], tolerance
@emlTestAssertEqualNum: "Dunn-1 adj p(2,3) Bonf", 0.00137855,
... emlDunnTest.adjustedP#[3], tolerance

# Matrix structure
@emlTestAssertEqualNum: "Dunn-1 pMatrix diag = 1", 1,
... emlDunnTest.pMatrix##[1, 1], 0
@emlTestAssertEqualNum: "Dunn-1 pMatrix symmetric",
... emlDunnTest.pMatrix##[1, 2], emlDunnTest.pMatrix##[2, 1], 0
@emlTestAssertEqualNum: "Dunn-1 zMatrix antisymmetric",
... emlDunnTest.zMatrix##[1, 2], -emlDunnTest.zMatrix##[2, 1], 0
@emlTestAssertEqualNum: "Dunn-1 zMatrix diag = 0", 0,
... emlDunnTest.zMatrix##[1, 1], 0

removeObject: .d1Id


# --- Dunn-3: 4 groups, unequal sizes, ties (Bonferroni) ---

.g7# = {5, 6, 7, 5, 6}
.g8# = {8, 9, 10, 8}
.g9# = {5, 6, 7}
.g10# = {12, 13, 14, 12, 13, 15}
@buildTestTable: .g7#, .g8#, .g9#, .g10#
.d3Id = buildTestTable.tableId

@emlDunnTest: .d3Id, "Value", "Group", "bonferroni"

@emlTestAssertEqualNum: "Dunn-3 nPairs", 6, emlDunnTest.nPairs, 0

@emlTestAssertEqualNum: "Dunn-3 z(1,2)", -1.74208332,
... emlDunnTest.zFlat#[1], tolerance
@emlTestAssertEqualNum: "Dunn-3 z(1,3)", -0.13765210,
... emlDunnTest.zFlat#[2], tolerance
@emlTestAssertEqualNum: "Dunn-3 z(1,4)", -3.48630836,
... emlDunnTest.zFlat#[3], tolerance

@emlTestAssertEqualNum: "Dunn-3 adj p(1,2) Bonf", 0.48896320,
... emlDunnTest.adjustedP#[1], tolerance
@emlTestAssertEqualNum: "Dunn-3 adj p(1,3) Bonf", 1.00000000,
... emlDunnTest.adjustedP#[2], tolerance
@emlTestAssertEqualNum: "Dunn-3 adj p(1,4) Bonf", 0.00293842,
... emlDunnTest.adjustedP#[3], tolerance
@emlTestAssertEqualNum: "Dunn-3 adj p(2,3) Bonf", 0.97183414,
... emlDunnTest.adjustedP#[4], tolerance
@emlTestAssertEqualNum: "Dunn-3 adj p(2,4) Bonf", 0.86570575,
... emlDunnTest.adjustedP#[5], tolerance
@emlTestAssertEqualNum: "Dunn-3 adj p(3,4) Bonf", 0.02678692,
... emlDunnTest.adjustedP#[6], tolerance

removeObject: .d3Id


# ============================================================================
# Section 6: @emlDunnTest — Holm (Test Set 3)
# ============================================================================

@emlTestSection: "Dunn Holm (Test Set 3)"

.g7# = {5, 6, 7, 5, 6}
.g8# = {8, 9, 10, 8}
.g9# = {5, 6, 7}
.g10# = {12, 13, 14, 12, 13, 15}
@buildTestTable: .g7#, .g8#, .g9#, .g10#
.d3hId = buildTestTable.tableId

@emlDunnTest: .d3hId, "Value", "Group", "holm"

@emlTestAssertTrue: "Dunn-3 Holm method echoed",
... (emlDunnTest.method$ = "holm")

@emlTestAssertEqualNum: "Dunn-3 adj p(1,2) Holm", 0.32597546,
... emlDunnTest.adjustedP#[1], tolerance
@emlTestAssertEqualNum: "Dunn-3 adj p(1,3) Holm", 0.89051537,
... emlDunnTest.adjustedP#[2], tolerance
@emlTestAssertEqualNum: "Dunn-3 adj p(1,4) Holm", 0.00293842,
... emlDunnTest.adjustedP#[3], tolerance
@emlTestAssertEqualNum: "Dunn-3 adj p(2,3) Holm", 0.43285287,
... emlDunnTest.adjustedP#[4], tolerance
@emlTestAssertEqualNum: "Dunn-3 adj p(2,4) Holm", 0.43285287,
... emlDunnTest.adjustedP#[5], tolerance
@emlTestAssertEqualNum: "Dunn-3 adj p(3,4) Holm", 0.02232244,
... emlDunnTest.adjustedP#[6], tolerance

# z-values unaffected by method choice
@emlTestAssertEqualNum: "Dunn-3 z(1,4) same under Holm", -3.48630836,
... emlDunnTest.zFlat#[3], tolerance

removeObject: .d3hId


# ============================================================================
# Section 7: @emlDunnTest — Large sample (Test Set 5)
# ============================================================================

@emlTestSection: "Dunn Large Sample (Test Set 5)"

.lg1# = {54.967142, 48.617357, 56.476885, 65.230299, 47.658466,
... 47.658630, 65.792128, 57.674347, 45.305256, 55.425600,
... 45.365823, 45.342702, 52.419623, 30.867198, 32.750822,
... 44.377125, 39.871689, 53.142473, 40.919759, 35.876963,
... 64.656488, 47.742237, 50.675282, 35.752518, 44.556173,
... 51.109226, 38.490064, 53.756980, 43.993613, 47.083063}

.lg2# = {48.982934, 73.522782, 54.865028, 44.422891, 63.225449,
... 42.791564, 57.088636, 35.403299, 41.718140, 56.968612,
... 62.384666, 56.713683, 53.843517, 51.988963, 40.214780,
... 47.801558, 50.393612, 65.571222, 58.436183, 37.369598,
... 58.240840, 51.149177, 48.230780, 61.116763, 65.309995,
... 64.312801, 46.607825, 51.907876, 58.312634, 64.755451}

.lg3# = {40.208258, 43.143410, 33.936650, 33.037934, 53.125258,
... 58.562400, 44.279899, 55.035329, 48.616360, 38.548802,
... 48.613956, 60.380366, 44.641740, 60.646437, 18.802549,
... 53.219025, 45.870471, 42.009926, 45.917608, 25.124311,
... 42.803281, 48.571126, 59.778940, 39.817298, 36.915064,
... 39.982430, 54.154021, 48.287511, 39.702398, 50.132674}

@buildTestTable: .lg1#, .lg2#, .lg3#, zero# (0)
.d5Id = buildTestTable.tableId

@emlDunnTest: .d5Id, "Value", "Group", "bonferroni"

@emlTestAssertEqualNum: "Dunn-5 z(1,2)", -2.25833958,
... emlDunnTest.zFlat#[1], tolerance
@emlTestAssertEqualNum: "Dunn-5 z(1,3)", 0.90926583,
... emlDunnTest.zFlat#[2], tolerance
@emlTestAssertEqualNum: "Dunn-5 z(2,3)", 3.16760541,
... emlDunnTest.zFlat#[3], tolerance
@emlTestAssertEqualNum: "Dunn-5 adj p(1,2) Bonf", 0.07177349,
... emlDunnTest.adjustedP#[1], tolerance
@emlTestAssertEqualNum: "Dunn-5 adj p(1,3) Bonf", 1.00000000,
... emlDunnTest.adjustedP#[2], tolerance
@emlTestAssertEqualNum: "Dunn-5 adj p(2,3) Bonf", 0.00461100,
... emlDunnTest.adjustedP#[3], tolerance

removeObject: .d5Id


# ============================================================================
# Section 8: @emlDunnTest — Edge cases and errors
# ============================================================================

@emlTestSection: "Dunn Edge Cases and Errors"

# --- All identical values ---

.gId1# = {5, 5, 5}
.gId2# = {5, 5, 5}
@buildTestTable: .gId1#, .gId2#, zero# (0), zero# (0)
.dIdId = buildTestTable.tableId

@emlDunnTest: .dIdId, "Value", "Group", "bonferroni"

@emlTestAssertTrue: "Dunn all-identical no error",
... (emlDunnTest.error$ = "")
@emlTestAssertEqualNum: "Dunn all-identical z = 0", 0,
... emlDunnTest.zFlat#[1], tolerance
@emlTestAssertEqualNum: "Dunn all-identical raw p = 1", 1,
... emlDunnTest.rawP#[1], tolerance

removeObject: .dIdId


# --- Invalid method ---

.gE1# = {1, 2, 3}
.gE2# = {4, 5, 6}
@buildTestTable: .gE1#, .gE2#, zero# (0), zero# (0)
.dErrId = buildTestTable.tableId

@emlDunnTest: .dErrId, "Value", "Group", "invalid"

@emlTestAssertTrue: "Dunn error: invalid method",
... (emlDunnTest.error$ <> "")

removeObject: .dErrId


# --- Single group ---

.gS# = {1, 2, 3}
@buildTestTable: .gS#, zero# (0), zero# (0), zero# (0)
.dSId = buildTestTable.tableId

@emlDunnTest: .dSId, "Value", "Group", "bonferroni"

@emlTestAssertTrue: "Dunn error: single group",
... (emlDunnTest.error$ <> "")

removeObject: .dSId


# --- Two groups (k=2, nPairs=1) ---

.gT1# = {1, 2, 3, 4, 5}
.gT2# = {6, 7, 8, 9, 10}
@buildTestTable: .gT1#, .gT2#, zero# (0), zero# (0)
.dTId = buildTestTable.tableId

@emlDunnTest: .dTId, "Value", "Group", "bonferroni"

@emlTestAssertTrue: "Dunn 2-group no error",
... (emlDunnTest.error$ = "")
@emlTestAssertEqualNum: "Dunn 2-group nPairs = 1", 1,
... emlDunnTest.nPairs, 0
@emlTestAssertEqualNum: "Dunn 2-group Bonf = raw",
... emlDunnTest.rawP#[1], emlDunnTest.adjustedP#[1], tolerance

removeObject: .dTId


# ============================================================================
# Section 9: @emlRankVector — tieCorrectionSum verification
# ============================================================================

@emlTestSection: "RankVector tieCorrectionSum"

# No ties
@emlRankVector: {5, 3, 1, 4, 2}
@emlTestAssertEqualNum: "tieCorrSum no ties", 0,
... emlRankVector.tieCorrectionSum, 0

# One tie group of size 2: t^3 - t = 8 - 2 = 6
@emlRankVector: {10, 20, 20, 30}
@emlTestAssertEqualNum: "tieCorrSum tie-2", 6,
... emlRankVector.tieCorrectionSum, 0

# All tied (size 3): t^3 - t = 27 - 3 = 24
@emlRankVector: {7, 7, 7}
@emlTestAssertEqualNum: "tieCorrSum all-tied-3", 24,
... emlRankVector.tieCorrectionSum, 0

# Two tie groups of size 2: 6 + 6 = 12
@emlRankVector: {1, 1, 2, 2, 3}
@emlTestAssertEqualNum: "tieCorrSum two-groups", 12,
... emlRankVector.tieCorrectionSum, 0

# Empty
@emlRankVector: zero# (0)
@emlTestAssertEqualNum: "tieCorrSum empty", 0,
... emlRankVector.tieCorrectionSum, 0

# Single element
@emlRankVector: {42}
@emlTestAssertEqualNum: "tieCorrSum single", 0,
... emlRankVector.tieCorrectionSum, 0

# KW-3 full data: ties in 5(3),6(3),7(2),8(2),12(2),13(2)
# Sum = 24 + 24 + 6 + 6 + 6 + 6 = 72
.kwData# = {5, 6, 7, 5, 6, 8, 9, 10, 8, 5, 6, 7,
... 12, 13, 14, 12, 13, 15}
@emlRankVector: .kwData#
@emlTestAssertEqualNum: "tieCorrSum KW-3 data", 72,
... emlRankVector.tieCorrectionSum, 0


# ============================================================================
# Summary
# ============================================================================

@emlTestSummary
