# ============================================================================
# Test: Wizard Mode Third-Column Explanations
# ============================================================================
# Verifies that @emlReportLine and @emlReportLineString append a third
# column when emlShowExplanations = 1 and emlWizardExplain$ is set.
# Also tests that wizard explanation helpers produce non-empty strings.
#
# Revised: 3 August 2026 (v1.2)
# v1.2 — Brought under the TEST RESULT REPORTING CONTRACT (v1.1, declared in
# dev/tests/eml-test-helpers.praat). The hand-rolled summary printed
# "SOME TESTS FAILED" and then returned normally, so the process exited 0
# whatever the outcome — green by construction for any runner reading exit
# status. Local counters are now bridged into emlTestInit.* and
# @emlTestSummary emits the machine-readable sentinel. No assertion call
# site changed and the human-readable summary is untouched.
# v1.1 — @emlKurtosis returns EXCESS kurtosis (normal = 0, verified against
# scipy bias=False), so @emlWizardExplainKurtosis takes an excess value and
# must not subtract 3 again. The near-normal case below previously passed the
# RAW value 3.1, which is an excess of 3.1 and correctly reads as
# heavy-tailed. It now passes 0.1, which exercises the same branch under the
# excess convention.
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
include ../../../graphs/eml-annotation-procedures.praat

# Shared harness — used only for @emlTestInit / @emlTestSummary (the
# reporting contract). This suite keeps its own assertion helper.
include ../eml-test-helpers.praat

@emlTestInit

totalTests = 0
passedTests = 0

procedure assert: .condition, .label$
    totalTests = totalTests + 1
    if .condition
        passedTests = passedTests + 1
        appendInfoLine: "  PASS: ", .label$
    else
        appendInfoLine: "  **FAIL**: ", .label$
    endif
endproc

# ============================================================================
# 1. @emlReportLine WITHOUT wizard mode (baseline)
# ============================================================================
appendInfoLine: "--- @emlReportLine baseline ---"

writeInfoLine: ""
emlShowExplanations = 0
@emlReportLine: "TestLabel", 3.14, 2
.info$ = info$ ()
# Should NOT contain tab character
@assert: index (.info$, tab$) = 0, "No tab in normal mode"

# ============================================================================
# 2. @emlReportLine WITH wizard mode
# ============================================================================
appendInfoLine: "--- @emlReportLine wizard mode ---"

writeInfoLine: ""
emlShowExplanations = 1
emlWizardExplain$ = "This is an explanation"
@emlReportLine: "TestLabel", 3.14, 2
.info$ = info$ ()
# Should contain tab + explanation
@assert: index (.info$, tab$) > 0, "Tab present in wizard mode"
@assert: index (.info$, "This is an explanation") > 0, "Explanation text present"

# Verify explain$ was consumed (reset to "")
@assert: emlWizardExplain$ = "", "Explain$ consumed after use"

# ============================================================================
# 3. @emlReportLineString WITH wizard mode
# ============================================================================
appendInfoLine: "--- @emlReportLineString wizard mode ---"

writeInfoLine: ""
emlShowExplanations = 1
emlWizardExplain$ = "String explanation"
@emlReportLineString: "Label", "value"
.info$ = info$ ()
@assert: index (.info$, "String explanation") > 0, "String explanation present"
@assert: emlWizardExplain$ = "", "Explain$ consumed (string)"

# ============================================================================
# 4. No explain$ set in wizard mode — no tab appended
# ============================================================================
appendInfoLine: "--- wizard mode without explain$ ---"

writeInfoLine: ""
emlShowExplanations = 1
emlWizardExplain$ = ""
@emlReportLine: "TestLabel", 1.0, 1
.info$ = info$ ()
@assert: index (.info$, tab$) = 0, "No tab when explain$ empty in wizard mode"

# ============================================================================
# 5. Helper procedure outputs (non-empty strings)
# ============================================================================
appendInfoLine: "--- Helper procedures ---"

emlShowExplanations = 1

@emlWizardExplainP: 0.03
@assert: emlWizardExplain$ <> "", "P explain non-empty (p=0.03)"
@assert: index (emlWizardExplain$, "significant") > 0, "P=0.03 says significant"

@emlWizardExplainP: 0.0005
@assert: index (emlWizardExplain$, "0.1") > 0, "P=0.0005 says <0.1%"

@emlWizardExplainP: 0.5
@assert: index (emlWizardExplain$, "Not") > 0, "P=0.5 says not significant"

@emlWizardExplainEffectD: 0.3
@assert: index (emlWizardExplain$, "small") > 0, "d=0.3 is small"

@emlWizardExplainEffectD: 1.2
@assert: index (emlWizardExplain$, "large") > 0, "d=1.2 is large"

@emlWizardExplainEffectR: 0.6
@assert: index (emlWizardExplain$, "large") > 0, "r=0.6 is large"

@emlWizardExplainEffectR: 0.2
@assert: index (emlWizardExplain$, "small") > 0, "r=0.2 is small"

@emlWizardExplainEffectEta2: 0.15
@assert: index (emlWizardExplain$, "large") > 0, "eta2=0.15 is large"
@assert: index (emlWizardExplain$, "15") > 0, "eta2=0.15 shows 15%"

@emlWizardExplainCorrelation: 0.72
@assert: index (emlWizardExplain$, "Very strong") > 0, "r=0.72 is very strong"
@assert: index (emlWizardExplain$, "positive") > 0, "r=0.72 is positive"

@emlWizardExplainCorrelation: -0.45
@assert: index (emlWizardExplain$, "Moderate") > 0, "r=-0.45 is moderate"
@assert: index (emlWizardExplain$, "negative") > 0, "r=-0.45 is negative"

@emlWizardExplainR2: 0.52
@assert: index (emlWizardExplain$, "52") > 0, "R2=0.52 shows 52%"

@emlWizardExplainT: 3.5
@assert: index (emlWizardExplain$, "3.5") > 0, "t=3.5 shows value"

@emlWizardExplainF: 8.0
@assert: index (emlWizardExplain$, "8.0") > 0, "F=8.0 shows value"

@emlWizardExplainNormW: 0.96
@assert: index (emlWizardExplain$, "normal") > 0, "W explain mentions normal"

@emlWizardExplainSkewness: 0.3
@assert: index (emlWizardExplain$, "symmetric") > 0, "skew=0.3 approximately symmetric"

@emlWizardExplainSkewness: -1.5
@assert: index (emlWizardExplain$, "Substantial left") > 0, "skew=-1.5 substantial left"

# Input is EXCESS kurtosis (normal = 0), not raw.
@emlWizardExplainKurtosis: 0.1
@assert: index (emlWizardExplain$, "Near-normal") > 0, "excess kurt=0.1 near-normal"

@emlWizardExplainKurtosis: 7.0
@assert: index (emlWizardExplain$, "Heavy-tailed") > 0, "excess kurt=7.0 heavy-tailed"

# ============================================================================
# SUMMARY
# ============================================================================
emlShowExplanations = 0
writeInfoLine: ""
appendInfoLine: "============================================"
appendInfoLine: "WIZARD EXPLANATIONS TEST SUMMARY"
appendInfoLine: "============================================"
appendInfoLine: "Passed: ", passedTests
appendInfoLine: "Failed: ", totalTests - passedTests
appendInfoLine: "Total:  ", totalTests
appendInfoLine: ""
if passedTests = totalTests
    appendInfoLine: "*** ALL TESTS PASSED ***"
else
    appendInfoLine: "*** SOME TESTS FAILED ***"
endif

# Bridge the local counters into the shared harness so @emlTestSummary can
# emit the machine-readable sentinel (TEST RESULT REPORTING CONTRACT v1.1).
# @emlTestSummary exitScript:s when failed > 0, so this must stay last —
# nothing that needs to run may follow it.
emlTestInit.passed = passedTests
emlTestInit.failed = totalTests - passedTests
emlTestInit.skipped = 0
emlTestInit.count = totalTests
@emlTestSummary
