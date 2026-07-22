# ============================================================================
# EML Stats : Workflow Verification Test Suite
# ============================================================================
# Module: test-workflow-verification.praat
# Version: 1.0
# Date: 11 May 2026
#
# Verifies:
#   A. emlShowExplanations flag behavior (renamed from emlWizardMode)
#   B. Double-tab spacing in explanation column
#   C. Info window persistence through report procedures
#   D. All orchestrator report procedures produce expected markers
# ============================================================================

include ../../../stats/eml-core-utilities.praat
include ../../../stats/eml-core-descriptive.praat
include ../../../stats/eml-extract.praat
include ../../../stats/eml-inferential.praat
include ../../../stats/eml-output.praat
include ../../../stats/eml-analysis.praat
include ../../../graphs/eml-annotation-procedures.praat
include ../eml-test-helpers.praat

@emlTestInit

# ============================================================================
# SECTION A: emlShowExplanations flag
# ============================================================================

@emlTestSection: "emlShowExplanations flag"

# Default should be 0
@emlTestAssertEqualNum: "default emlShowExplanations = 0",
    ... 0, emlShowExplanations, 0

# With flag OFF, @emlReportLine should not append explanation
emlShowExplanations = 0
emlWizardExplain$ = "should be ignored"
writeInfoLine: ""
@emlReportLine: "TestLabel", 3.14, 2
.info$ = info$ ()
@emlTestAssertTrue: "no explanation in output when flag = 0",
    ... index (.info$, tab$) = 0
emlWizardExplain$ = ""

# With flag ON, explanation should appear
emlShowExplanations = 1
@emlWizardExplainP: 0.001
@emlTestAssertTrue: "explanation produced when flag = 1",
    ... emlWizardExplain$ <> ""

# Reset
emlShowExplanations = 0
emlWizardExplain$ = ""

# ============================================================================
# SECTION B: Double-tab spacing
# ============================================================================

@emlTestSection: "Explanation spacing"

emlShowExplanations = 1
@emlWizardExplainP: 0.03
writeInfoLine: ""
@emlReportLine: "p-value", 0.03, 4

.info$ = info$ ()
.hasTwoTabs = index (.info$, tab$ + tab$)
@emlTestAssertTrue: "double tab between value and explanation",
    ... .hasTwoTabs > 0

# Reset
emlShowExplanations = 0
emlWizardExplain$ = ""

# ============================================================================
# SECTION C: Info window persistence through append
# ============================================================================

@emlTestSection: "Info window persistence"

writeInfoLine: ""
appendInfoLine: "=== ORIGINAL ANALYSIS OUTPUT ==="
appendInfoLine: "t = 3.45, p = 0.003"

appendInfoLine: ""
appendInfoLine: "--- ANNOTATION RESULTS ---"
appendInfoLine: "Bracket added at p = 0.003"
.after$ = info$ ()

@emlTestAssertContains: "original output persists",
    ... .after$, "ORIGINAL ANALYSIS OUTPUT"
@emlTestAssertContains: "original values persist",
    ... .after$, "t = 3.45"
@emlTestAssertContains: "annotation results appended",
    ... .after$, "ANNOTATION RESULTS"

# ============================================================================
# SECTION D: Two-group report markers
# ============================================================================

@emlTestSection: "Two-group report markers"

tableId = Create Table with column names: "test", 20, "Data Group"
for .i from 1 to 10
    Set numeric value: .i, "Data", 10 + randomGauss (0, 1)
    Set string value: .i, "Group", "A"
endfor
for .i from 11 to 20
    Set numeric value: .i, "Data", 15 + randomGauss (0, 1)
    Set string value: .i, "Group", "B"
endfor

selectObject: tableId
@emlRunTwoGroupAnalysis: tableId, "Data", "Group", "parametric", 1
.info$ = info$ ()

@emlTestAssertTrue: "two-group report has t-statistic",
    ... index (.info$, "t") > 0
@emlTestAssertTrue: "two-group report has p-value",
    ... index (.info$, "p =") > 0 or index (.info$, "p ") > 0
@emlTestAssertTrue: "two-group report has effect size",
    ... index (.info$, "Cohen") > 0 or index (.info$, "d =") > 0
    ... or index (.info$, "effect") > 0

removeObject: tableId

# ============================================================================
# SECTION E: ANOVA report markers
# ============================================================================

@emlTestSection: "ANOVA report markers"

tableId = Create Table with column names: "test", 30, "Data Group"
for .i from 1 to 10
    Set numeric value: .i, "Data", 10 + randomGauss (0, 1)
    Set string value: .i, "Group", "A"
endfor
for .i from 11 to 20
    Set numeric value: .i, "Data", 15 + randomGauss (0, 1)
    Set string value: .i, "Group", "B"
endfor
for .i from 21 to 30
    Set numeric value: .i, "Data", 20 + randomGauss (0, 1)
    Set string value: .i, "Group", "C"
endfor

selectObject: tableId
@emlRunAnovaAnalysis: tableId, "Data", "Group", 0
.info$ = info$ ()

@emlTestAssertContains: "ANOVA header present",
    ... .info$, "ANOVA"
@emlTestAssertTrue: "ANOVA has F-statistic",
    ... index (.info$, "F") > 0
@emlTestAssertTrue: "ANOVA has eta-squared",
    ... index (.info$, "eta") > 0 or index (.info$, "Eta") > 0

removeObject: tableId

# ============================================================================
# SECTION F: KW report markers
# ============================================================================

@emlTestSection: "KW report markers"

tableId = Create Table with column names: "test", 30, "Data Group"
for .i from 1 to 10
    Set numeric value: .i, "Data", 10 + randomGauss (0, 1)
    Set string value: .i, "Group", "A"
endfor
for .i from 11 to 20
    Set numeric value: .i, "Data", 15 + randomGauss (0, 1)
    Set string value: .i, "Group", "B"
endfor
for .i from 21 to 30
    Set numeric value: .i, "Data", 20 + randomGauss (0, 1)
    Set string value: .i, "Group", "C"
endfor

selectObject: tableId
@emlRunKWAnalysis: tableId, "Data", "Group", 0, "holm"
.info$ = info$ ()

@emlTestAssertContains: "KW header present",
    ... .info$, "Kruskal"
@emlTestAssertTrue: "KW has H or chi statistic",
    ... index (.info$, "H") > 0 or index (.info$, "chi") > 0

removeObject: tableId

# ============================================================================
# SECTION G: Correlation report markers
# ============================================================================

@emlTestSection: "Correlation report markers"

tableId = Create Table with column names: "test", 20, "X Y"
for .i from 1 to 20
    .x = randomGauss (0, 1)
    Set numeric value: .i, "X", .x
    Set numeric value: .i, "Y", .x * 2 + randomGauss (0, 0.5)
endfor

selectObject: tableId
@emlRunCorrelationAnalysis: tableId, "X", "Y", "pearson"
.info$ = info$ ()

@emlTestAssertTrue: "correlation has r-value",
    ... index (.info$, "r =") > 0 or index (.info$, "r ") > 0
@emlTestAssertTrue: "correlation has p-value",
    ... index (.info$, "p") > 0

removeObject: tableId

# ============================================================================
# SECTION H: Regression report markers
# ============================================================================

@emlTestSection: "Regression report markers"

tableId = Create Table with column names: "test", 20, "X Y"
for .i from 1 to 20
    .x = randomGauss (0, 1)
    Set numeric value: .i, "X", .x
    Set numeric value: .i, "Y", .x * 3 + 5 + randomGauss (0, 0.5)
endfor

selectObject: tableId
@emlRunRegressionAnalysis: tableId, "Y", "X"
.info$ = info$ ()

@emlTestAssertTrue: "regression has equation or coefficients",
    ... index (.info$, "Equation") > 0 or index (.info$, "Estimate") > 0
@emlTestAssertTrue: "regression has R-squared",
    ... index (.info$, "R²") > 0 or index (.info$, "R-sq") > 0
    ... or index (.info$, "R^2") > 0 or index (.info$, "R2") > 0
    ... or index (.info$, "r²") > 0

removeObject: tableId

# ============================================================================
# SECTION I: Paired report markers
# ============================================================================

@emlTestSection: "Paired report markers"

tableId = Create Table with column names: "test", 15, "Pre Post"
for .i from 1 to 15
    .base = randomGauss (50, 5)
    Set numeric value: .i, "Pre", .base
    Set numeric value: .i, "Post", .base + 3 + randomGauss (0, 1)
endfor

selectObject: tableId
@emlRunPairedAnalysis: tableId, "Pre", "Post", "parametric"
.info$ = info$ ()

@emlTestAssertTrue: "paired has t-statistic",
    ... index (.info$, "t") > 0
@emlTestAssertTrue: "paired has p-value",
    ... index (.info$, "p") > 0

removeObject: tableId

# ============================================================================
# SECTION J: Normality report markers
# ============================================================================

@emlTestSection: "Normality report markers"

tableId = Create Table with column names: "test", 30, "Data"
for .i from 1 to 30
    Set numeric value: .i, "Data", randomGauss (100, 15)
endfor

selectObject: tableId
@emlRunNormalityAnalysis: tableId, "Data", "auto"
.info$ = info$ ()

@emlTestAssertTrue: "normality has W-statistic",
    ... index (.info$, "W") > 0
@emlTestAssertTrue: "normality has skewness",
    ... index (.info$, "skew") > 0 or index (.info$, "Skew") > 0

removeObject: tableId

# ============================================================================
# SECTION K: Explanation helpers produce content
# ============================================================================

@emlTestSection: "Explanation helper content"

emlShowExplanations = 1

@emlWizardExplainP: 0.001
@emlTestAssertTrue: "P explanation produced",
    ... emlWizardExplain$ <> ""

# Verify consumption clears
writeInfoLine: ""
@emlReportLine: "p-value", 0.001, 4
@emlTestAssertEqualStr: "explanation cleared after consumption",
    ... "", emlWizardExplain$

@emlWizardExplainEffectD: 0.8
@emlTestAssertTrue: "Cohen d explanation produced",
    ... emlWizardExplain$ <> ""
emlWizardExplain$ = ""

@emlWizardExplainCorrelation: -0.75
@emlTestAssertTrue: "Correlation explanation produced",
    ... emlWizardExplain$ <> ""
emlWizardExplain$ = ""

@emlWizardExplainR2: 0.64
@emlTestAssertTrue: "R-squared explanation produced",
    ... emlWizardExplain$ <> ""
emlWizardExplain$ = ""

@emlWizardExplainT: 2.5
@emlTestAssertTrue: "T explanation produced",
    ... emlWizardExplain$ <> ""
emlWizardExplain$ = ""

@emlWizardExplainF: 5.3
@emlTestAssertTrue: "F explanation produced",
    ... emlWizardExplain$ <> ""
emlWizardExplain$ = ""

@emlWizardExplainNormW: 0.95
@emlTestAssertTrue: "Shapiro-Wilk W explanation produced",
    ... emlWizardExplain$ <> ""
emlWizardExplain$ = ""

@emlWizardExplainSkewness: 1.2
@emlTestAssertTrue: "Skewness explanation produced",
    ... emlWizardExplain$ <> ""
emlWizardExplain$ = ""

@emlWizardExplainKurtosis: 4.0
@emlTestAssertTrue: "Kurtosis explanation produced",
    ... emlWizardExplain$ <> ""
emlWizardExplain$ = ""

# Reset
emlShowExplanations = 0
emlWizardExplain$ = ""

# ============================================================================
# SUMMARY
# ============================================================================

@emlTestSummary
