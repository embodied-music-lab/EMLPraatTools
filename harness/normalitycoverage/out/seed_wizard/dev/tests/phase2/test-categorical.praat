# ============================================================================
# EML Stats : Dev tests — Categorical (@emlChiSquareIndependence,
#                                       @emlWilsonInterval)
# ============================================================================
# Module: test-categorical.praat
# Version: 1.0
# Date: 17 August 2026
#
# Run from: dev/tests/phase2/
#
# Part of the EML Stats library (EML Praat Tools).
# License: GPL-3.0-or-later
#
# Every numeric literal below is externally verified by the committed
# companion artifact verify-survey-lane.R (same directory), which
# asserts each literal against R's chisq.test and prop.test and exits
# non-zero on disagreement. Regenerate/re-check with:
#     Rscript verify-survey-lane.R
# Do not hand-edit the literals.
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

include ../../../stats/eml-categorical.praat

include ../eml-test-helpers.praat

@emlTestInit

tolerance = 0.000000001

@emlTestSection: "@emlChiSquareIndependence — 2x2, both correction settings"

# R: chisq.test(matrix(c(20,10,15,25),2,2), correct=TRUE)
#    X-squared = 4.7250000000, df = 1, p = 0.0297271833
#    correct=FALSE: X-squared = 5.8333333333, p = 0.0157252998
#    Cramér's V (uncorrected) = 0.2886751346
t## = {{20, 15}, {10, 25}}
@emlChiSquareIndependence: t##, 1
@emlTestAssertEqualStr: "corrected run has no error", "",
... emlChiSquareIndependence.error$
@emlTestAssertEqualNum: "corrected chi-square", 4.7250000000,
... emlChiSquareIndependence.chiSq, tolerance
@emlTestAssertEqualNum: "df", 1, emlChiSquareIndependence.df, 0
@emlTestAssertEqualNum: "corrected p", 0.0297271833,
... emlChiSquareIndependence.p, tolerance
@emlTestAssertEqualNum: "Cramér's V from the uncorrected statistic",
... 0.2886751346, emlChiSquareIndependence.cramersV, tolerance
@emlTestAssertEqualNum: "n", 70, emlChiSquareIndependence.n, 0
@emlTestAssertEqualStr: "no warning when all expected counts are >= 5", "",
... emlChiSquareIndependence.warning$

@emlChiSquareIndependence: t##, 0
@emlTestAssertEqualNum: "uncorrected chi-square", 5.8333333333,
... emlChiSquareIndependence.chiSq, tolerance
@emlTestAssertEqualNum: "uncorrected p", 0.0157252998,
... emlChiSquareIndependence.p, tolerance
@emlTestAssertEqualNum: "V unchanged by the correction setting",
... 0.2886751346, emlChiSquareIndependence.cramersV, tolerance

@emlTestSection: "@emlChiSquareIndependence — sparse 2x2 warns"

# R: chisq.test(matrix(c(3,2,1,4),2,2), correct=TRUE)
#    X-squared = 0.4166666667, p = 0.5186050164; all 4 expected < 5,
#    smallest expected = 2.
s## = {{3, 1}, {2, 4}}
@emlChiSquareIndependence: s##, 1
@emlTestAssertEqualNum: "sparse corrected chi-square", 0.4166666667,
... emlChiSquareIndependence.chiSq, tolerance
@emlTestAssertEqualNum: "sparse corrected p", 0.5186050164,
... emlChiSquareIndependence.p, tolerance
@emlTestAssertEqualNum: "smallest expected count", 2,
... emlChiSquareIndependence.minExpected, tolerance
@emlTestAssertEqualNum: "cells below 5", 4,
... emlChiSquareIndependence.nCellsBelow5, 0
@emlTestAssertContains: "warning fires on sparse expected counts",
... emlChiSquareIndependence.warning$, "below 5"

@emlTestSection: "@emlChiSquareIndependence — 3x4 (correction ignored)"

# R: chisq.test(3x4 table below) — correct=TRUE and correct=FALSE agree
#    above 2x2: X-squared = 10.6870232798, df = 6, p = 0.0985445284,
#    V = 0.2110195812
b## = {{12, 8, 14, 6}, {9, 11, 5, 15}, {7, 13, 10, 10}}
@emlChiSquareIndependence: b##, 1
@emlTestAssertEqualNum: "3x4 chi-square", 10.6870232798,
... emlChiSquareIndependence.chiSq, tolerance
@emlTestAssertEqualNum: "3x4 df", 6, emlChiSquareIndependence.df, 0
@emlTestAssertEqualNum: "3x4 p", 0.0985445284,
... emlChiSquareIndependence.p, tolerance
@emlTestAssertEqualNum: "3x4 Cramér's V", 0.2110195812,
... emlChiSquareIndependence.cramersV, tolerance
@emlChiSquareIndependence: b##, 0
@emlTestAssertEqualNum: "correction is a no-op above 2x2", 10.6870232798,
... emlChiSquareIndependence.chiSq, tolerance

@emlTestSection: "@emlChiSquareIndependence — zero cell is legal"

# R: chisq.test(matrix(c(10,5,0,8),2,2), correct=FALSE)
#    X-squared = 9.4358974359, p = 0.0021277894, V = 0.6405126152
z## = {{10, 0}, {5, 8}}
@emlChiSquareIndependence: z##, 0
@emlTestAssertEqualStr: "zero-cell run has no error", "",
... emlChiSquareIndependence.error$
@emlTestAssertEqualNum: "zero-cell chi-square", 9.4358974359,
... emlChiSquareIndependence.chiSq, tolerance
@emlTestAssertEqualNum: "zero-cell V", 0.6405126152,
... emlChiSquareIndependence.cramersV, tolerance

@emlTestSection: "@emlChiSquareIndependence — refusals"

zm## = {{5, 0}, {7, 0}}
@emlChiSquareIndependence: zm##, 0
@emlTestAssertContains: "zero column margin is refused",
... emlChiSquareIndependence.error$, "zero row or column total"
@emlTestAssertUndefined: "chiSq undefined on refusal",
... emlChiSquareIndependence.chiSq

neg## = {{5, -1}, {7, 3}}
@emlChiSquareIndependence: neg##, 0
@emlTestAssertContains: "negative count is refused",
... emlChiSquareIndependence.error$, "non-negative"

u## = {{5, undefined}, {7, 3}}
@emlChiSquareIndependence: u##, 0
@emlTestAssertContains: "undefined cell is refused",
... emlChiSquareIndependence.error$, "undefined cell"

t2## = {{20, 15}, {10, 25}}
@emlChiSquareIndependence: t2##, 2
@emlTestAssertContains: "correction outside 0/1 is refused",
... emlChiSquareIndependence.error$, "correction must be 0 or 1"

row## = {{5, 7}}
@emlChiSquareIndependence: row##, 0
@emlTestAssertContains: "a 1 x 2 table is refused",
... emlChiSquareIndependence.error$, "at least 2 x 2"

@emlTestSection: "@emlWilsonInterval — brief's case grid"

# R: prop.test(x, n, conf.level, correct=FALSE)$conf.int
@emlWilsonInterval: 17, 20, 0.95
@emlTestAssertEqualStr: "central run has no error", "", emlWilsonInterval.error$
@emlTestAssertEqualNum: "central propHat", 0.85, emlWilsonInterval.propHat, 0
@emlTestAssertEqualNum: "central lower", 0.6395811353,
... emlWilsonInterval.ciLow, tolerance
@emlTestAssertEqualNum: "central upper", 0.9476312541,
... emlWilsonInterval.ciHigh, tolerance

@emlWilsonInterval: 3, 5, 0.95
@emlTestAssertEqualNum: "n = 5 lower", 0.2307242813,
... emlWilsonInterval.ciLow, tolerance
@emlTestAssertEqualNum: "n = 5 upper", 0.8823792258,
... emlWilsonInterval.ciHigh, tolerance

@emlWilsonInterval: 950, 1000, 0.99
@emlTestAssertEqualNum: "n = 1000, 99% lower", 0.9290930273,
... emlWilsonInterval.ciLow, tolerance
@emlTestAssertEqualNum: "n = 1000, 99% upper", 0.9649749243,
... emlWilsonInterval.ciHigh, tolerance

@emlTestSection: "@emlWilsonInterval — endpoints, where Wilson earns its keep"

@emlWilsonInterval: 0, 10, 0.95
@emlTestAssertEqualNum: "x = 0 lower is exactly 0", 0,
... emlWilsonInterval.ciLow, 0
@emlTestAssertEqualNum: "x = 0 upper", 0.2775327999,
... emlWilsonInterval.ciHigh, tolerance
@emlTestAssertTrue: "x = 0 interval has positive width (Wald is zero-width here)",
... emlWilsonInterval.ciHigh - emlWilsonInterval.ciLow > 0.01

@emlWilsonInterval: 10, 10, 0.95
@emlTestAssertEqualNum: "x = n upper is exactly 1", 1,
... emlWilsonInterval.ciHigh, 0
@emlTestAssertEqualNum: "x = n lower", 0.7224672001,
... emlWilsonInterval.ciLow, tolerance
@emlTestAssertTrue: "x = n interval has positive width (Wald is zero-width here)",
... emlWilsonInterval.ciHigh - emlWilsonInterval.ciLow > 0.01

@emlTestSection: "@emlWilsonInterval — refusals"

@emlWilsonInterval: 3.5, 5, 0.95
@emlTestAssertContains: "non-integer successes are refused",
... emlWilsonInterval.error$, "integer between 0 and n"

@emlWilsonInterval: 7, 5, 0.95
@emlTestAssertContains: "successes above n are refused",
... emlWilsonInterval.error$, "integer between 0 and n"

@emlWilsonInterval: 3, 0, 0.95
@emlTestAssertContains: "n = 0 is refused",
... emlWilsonInterval.error$, "positive integer"

@emlWilsonInterval: 3, 5, 95
@emlTestAssertContains: "confidence of 95 (not 0.95) is refused",
... emlWilsonInterval.error$, "strictly between 0 and 1"

@emlTestSummary
