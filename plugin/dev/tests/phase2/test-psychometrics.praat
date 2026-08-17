# ============================================================================
# EML Stats : Dev tests — Psychometrics (@emlCronbachAlpha)
# ============================================================================
# Module: test-psychometrics.praat
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
# asserts each literal against R's psych::alpha and exits non-zero on
# disagreement. Regenerate/re-check with:
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

include ../../../stats/eml-psychometrics.praat

include ../eml-test-helpers.praat

@emlTestInit

tolerance = 0.000000001

@emlTestSection: "@emlCronbachAlpha — 5-item scale, complete data"

# R: psych::alpha on the 10 x 5 matrix below (check.keys = FALSE)
#    raw_alpha = 0.9491763761, Feldt 95% CI [0.8733351023, 0.9855775272]
d## = {{2, 3, 3, 3, 2}, {4, 4, 3, 4, 4}, {3, 4, 4, 3, 3},
... {5, 5, 4, 5, 5}, {1, 2, 2, 1, 2}, {4, 3, 3, 4, 4},
... {2, 2, 3, 2, 2}, {5, 4, 5, 5, 4}, {3, 3, 3, 3, 4}, {4, 5, 4, 4, 5}}
@emlCronbachAlpha: d##
@emlTestAssertEqualStr: "clean run has no error", "", emlCronbachAlpha.error$
@emlTestAssertEqualNum: "alpha", 0.9491763761, emlCronbachAlpha.alpha, tolerance
@emlTestAssertEqualNum: "Feldt CI lower", 0.8733351023, emlCronbachAlpha.ci95low, tolerance
@emlTestAssertEqualNum: "Feldt CI upper", 0.9855775272, emlCronbachAlpha.ci95high, tolerance
@emlTestAssertEqualNum: "k", 5, emlCronbachAlpha.k, 0
@emlTestAssertEqualNum: "n", 10, emlCronbachAlpha.n, 0
@emlTestAssertEqualNum: "nExcluded", 0, emlCronbachAlpha.nExcluded, 0
expectedDrop# = {0.9209039548, 0.9375000000, 0.9580922322,
... 0.9237002026, 0.9393183707}
@emlTestAssertVectorsEqual: "alpha-if-deleted vector", expectedDrop#,
... emlCronbachAlpha.alphaIfDeleted#, tolerance

@emlTestSection: "@emlCronbachAlpha — listwise deletion disclosed"

# Same matrix with one cell undefined: row 2 drops, n = 9.
# R: raw_alpha on the 9 complete rows = 0.9528130672
dm## = {{2, 3, 3, 3, 2}, {4, undefined, 3, 4, 4}, {3, 4, 4, 3, 3},
... {5, 5, 4, 5, 5}, {1, 2, 2, 1, 2}, {4, 3, 3, 4, 4},
... {2, 2, 3, 2, 2}, {5, 4, 5, 5, 4}, {3, 3, 3, 3, 4}, {4, 5, 4, 4, 5}}
@emlCronbachAlpha: dm##
@emlTestAssertEqualStr: "missing-cell run has no error", "", emlCronbachAlpha.error$
@emlTestAssertEqualNum: "alpha after listwise deletion", 0.9528130672,
... emlCronbachAlpha.alpha, tolerance
@emlTestAssertEqualNum: "n counts complete rows only", 9, emlCronbachAlpha.n, 0
@emlTestAssertEqualNum: "nExcluded discloses the dropped row", 1,
... emlCronbachAlpha.nExcluded, 0

@emlTestSection: "@emlCronbachAlpha — 2-item edge"

# R: raw_alpha on columns 1-2 of the clean matrix = 0.8823529412.
# A one-item scale has no alpha, so alpha-if-deleted stays undefined.
d2## = {{2, 3}, {4, 4}, {3, 4}, {5, 5}, {1, 2},
... {4, 3}, {2, 2}, {5, 4}, {3, 3}, {4, 5}}
@emlCronbachAlpha: d2##
@emlTestAssertEqualStr: "2-item run has no error", "", emlCronbachAlpha.error$
@emlTestAssertEqualNum: "2-item alpha", 0.8823529412, emlCronbachAlpha.alpha, tolerance
@emlTestAssertUndefined: "alpha-if-deleted item 1 undefined at k = 2",
... emlCronbachAlpha.alphaIfDeleted# [1]
@emlTestAssertUndefined: "alpha-if-deleted item 2 undefined at k = 2",
... emlCronbachAlpha.alphaIfDeleted# [2]

@emlTestSection: "@emlCronbachAlpha — refusals"

one## = {{1}, {2}, {3}}
@emlCronbachAlpha: one##
@emlTestAssertContains: "one item is refused", emlCronbachAlpha.error$,
... "at least 2 items"
@emlTestAssertUndefined: "alpha undefined on refusal", emlCronbachAlpha.alpha

small## = {{1, 2}, {3, 4}}
@emlCronbachAlpha: small##
@emlTestAssertContains: "two respondents are refused", emlCronbachAlpha.error$,
... "at least 3 complete respondents"

# All rows share the same totals: total variance is zero.
flat## = {{3, 3}, {2, 4}, {4, 2}}
@emlCronbachAlpha: flat##
@emlTestAssertContains: "zero total variance is refused", emlCronbachAlpha.error$,
... "zero variance"

@emlTestSection: "@emlAlphaInfluence — leave-one-out over respondents"

# R: base-R LOO over the 10 x 5 clean matrix (leave each row out,
#    covariance-matrix alpha on the remainder; deltas vs full alpha)
#    full = 0.9491763761, without row 1 = 0.9519787645
#    (delta 0.0028023884), without row 10 = 0.9487500000,
#    max |delta| = 0.0214143364 at row 5
@emlAlphaInfluence: d##
@emlTestAssertEqualStr: "influence run has no error", "",
... emlAlphaInfluence.error$
@emlTestAssertEqualNum: "alphaFull", 0.9491763761,
... emlAlphaInfluence.alphaFull, tolerance
@emlCronbachAlpha: d##
@emlTestAssertEqualNum: "alphaFull equals the alpha kernel's alpha",
... emlCronbachAlpha.alpha, emlAlphaInfluence.alphaFull, tolerance
@emlTestAssertEqualNum: "alpha without respondent 1", 0.9519787645,
... emlAlphaInfluence.alphaWithout# [1], tolerance
@emlTestAssertEqualNum: "delta for respondent 1", 0.0028023884,
... emlAlphaInfluence.delta# [1], tolerance
@emlTestAssertEqualNum: "alpha without respondent 10", 0.9487500000,
... emlAlphaInfluence.alphaWithout# [10], tolerance
@emlTestAssertEqualNum: "largest absolute delta", 0.0214143364,
... emlAlphaInfluence.deltaMax, tolerance
@emlTestAssertEqualNum: "its respondent (original row)", 5,
... emlAlphaInfluence.deltaMaxRow, 0

@emlTestSection: "@emlAlphaInfluence — original-row mapping after deletion"

# Same matrix with cells missing in rows 2 and 4: those rows drop, and
# every indexed output must still speak in ORIGINAL row numbers.
# R: n = 8, full = 0.9458111702, dominant respondent = original row 5
#    (surviving index 3); rowIndex maps survivor 3 -> 5, survivor 8 -> 10.
di## = {{2, 3, 3, 3, 2}, {4, undefined, 3, 4, 4}, {3, 4, 4, 3, 3},
... {5, 5, undefined, 5, 5}, {1, 2, 2, 1, 2}, {4, 3, 3, 4, 4},
... {2, 2, 3, 2, 2}, {5, 4, 5, 5, 4}, {3, 3, 3, 3, 4}, {4, 5, 4, 4, 5}}
@emlAlphaInfluence: di##
@emlTestAssertEqualNum: "n counts complete rows only", 8,
... emlAlphaInfluence.n, 0
@emlTestAssertEqualNum: "nExcluded discloses the dropped rows", 2,
... emlAlphaInfluence.nExcluded, 0
@emlTestAssertEqualNum: "alphaFull after deletion", 0.9458111702,
... emlAlphaInfluence.alphaFull, tolerance
@emlTestAssertEqualNum: "survivor 3 maps to original row 5", 5,
... emlAlphaInfluence.rowIndex# [3], 0
@emlTestAssertEqualNum: "survivor 8 maps to original row 10", 10,
... emlAlphaInfluence.rowIndex# [8], 0
@emlTestAssertEqualNum: "dominant delta reported by original row", 5,
... emlAlphaInfluence.deltaMaxRow, 0

@emlTestSection: "conditioning — a large common offset changes nothing"

# Alpha is translation-invariant: the clean 10 x 5 matrix shifted by
# 100 000 000 must reproduce every value bit-for-bit against the same
# R-verified literals. This is the stress case that a sum-of-squares
# implementation fails by cancellation (values at 1e8 square to 1e16,
# past double precision), pinned so it cannot come back.
dOff## = d## + 100000000
@emlCronbachAlpha: dOff##
@emlTestAssertEqualStr: "offset alpha run has no error", "",
... emlCronbachAlpha.error$
@emlTestAssertEqualNum: "offset alpha equals the clean literal",
... 0.9491763761, emlCronbachAlpha.alpha, tolerance
@emlTestAssertEqualNum: "offset Feldt CI lower unchanged", 0.8733351023,
... emlCronbachAlpha.ci95low, tolerance
@emlAlphaInfluence: dOff##
@emlTestAssertEqualNum: "offset influence alphaFull unchanged",
... 0.9491763761, emlAlphaInfluence.alphaFull, tolerance
@emlTestAssertEqualNum: "offset largest absolute delta unchanged",
... 0.0214143364, emlAlphaInfluence.deltaMax, tolerance
@emlTestAssertEqualNum: "offset dominant respondent unchanged", 5,
... emlAlphaInfluence.deltaMaxRow, 0

@emlTestSection: "@emlAlphaInfluence — refusals"

two## = {{1, 2}, {3, 4}}
@emlAlphaInfluence: two##
@emlTestAssertContains: "two respondents are refused",
... emlAlphaInfluence.error$, "at least 3 complete respondents"
@emlTestAssertUndefined: "deltaMax undefined on refusal",
... emlAlphaInfluence.deltaMax

oneItem## = {{1}, {2}, {3}}
@emlAlphaInfluence: oneItem##
@emlTestAssertContains: "one item is refused (influence)",
... emlAlphaInfluence.error$, "at least 2 items"

@emlTestSummary
