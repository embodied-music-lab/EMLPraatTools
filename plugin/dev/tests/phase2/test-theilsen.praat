# ============================================================================
# EML Stats : Test Suite — @emlTheilSen (Theil-Sen robust regression)
# ============================================================================
# Tests: @emlTheilSen
# Date: 3 August 2026
# Version: 1.0
#
# Reference values: scipy.stats.theilslopes, via theilsen_scipy_refs.py
#                   (committed alongside this file — run it to regenerate)
# scipy 1.17.1, numpy 2.4.4
#
# WHY THIS FILE EXISTS
# EML_PROCEDURE_REGISTRY.md described @emlTheilSen as "scipy-verified".
# No test for it existed anywhere under dev/tests/ and no verification
# annotation appeared in its header, so the claim was unbacked. @emlTheilSen
# is not dead code: it is called from graphs/eml-draw-procedures.praat at
# lines 2410 and 2660, so a wrong slope reaches the user as a drawn trend
# line — the class of error a reader will not catch by eye.
#
# INTERCEPT CONVENTION
# Two conventions circulate for the Theil-Sen intercept:
#   separate (Conover 1980):  b = median(y) - slope * median(x)
#   joint:                    b = median(y - slope * x)
# @emlTheilSen implements SEPARATE. scipy.stats.theilslopes implements both
# and defaults to separate. The two agree on symmetric data, so a test built
# only on symmetric sets verifies NEITHER convention. TS-5 and TS-8 below are
# constructed so the conventions diverge visibly (TS-5: 1.3125 vs 0.9375),
# and section 2 asserts explicitly that the expected values are the separate
# ones. If the implementation were switched to joint, TS-5 and TS-8 fail
# while TS-1/TS-3/TS-4/TS-6/TS-7 would not notice.
#
# WHAT THESE SETS CANNOT DO
# TS-1, TS-6 and TS-7 are exactly collinear. On collinear data the median of
# pairwise slopes, the MEAN of pairwise slopes, and the OLS slope all
# coincide, so those three sets exercise branches (odd/even median selection,
# negative slope, the n=2 boundary) but cannot distinguish a correct
# Theil-Sen from an ordinary least-squares fit. TS-2, TS-3, TS-4, TS-5 and
# TS-8 do make that distinction. This is measured, not asserted by hand — see
# the DISCRIMINATION MAP printed by theilsen_scipy_refs.py.
#
# TOLERANCE
# Expected values are full-precision (%.17g) literals, which a double
# round-trips exactly, so none of the tolerance budget is spent on
# transcription. tsTol = 5e-11 absolute is then available entirely to absorb
# arithmetic-order differences between Praat's sort/median and scipy's. At
# the tightest site (|expected| = 0.1) the assertion is non-vacuous by a
# factor of 2e9. TS-1's separate intercept is exactly 0, which is a
# legitimate zero target; it uses tsTolZero = 1e-12 with
# @emlTestAssertEqualNum — @emlTestAssertEqualRel treats a zero expected
# value as misuse and would fail it.
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

tsTol = 5e-11
tsTolZero = 1e-12
tsExact = 0


# ============================================================================
# SECTION 1 — Valid inputs, slope / intercept / nSlopes against scipy
# ============================================================================

@emlTestSection: "TS-1: n=3, 3 pairwise slopes (ODD median branch)"
ts1X# = { 1, 2, 3 }
ts1Y# = { 2, 5, 7 }
@emlTheilSen: ts1X#, ts1Y#
@emlTestAssertEqualStr: "TS-1 no error", "", emlTheilSen.error$
@emlTestAssertEqualNum: "TS-1 slope", 2.5, emlTheilSen.slope, tsTol
@emlTestAssertEqualNum: "TS-1 intercept (separate)", 0,
... emlTheilSen.intercept, tsTolZero
@emlTestAssertEqualNum: "TS-1 nSlopes", 3, emlTheilSen.nSlopes, tsExact

@emlTestSection: "TS-2: n=4, 6 pairwise slopes (EVEN median branch, even n)"
ts2X# = { 1, 2, 3, 4 }
ts2Y# = { 2.0, 4.5, 5.5, 9.0 }
@emlTheilSen: ts2X#, ts2Y#
@emlTestAssertEqualStr: "TS-2 no error", "", emlTheilSen.error$
@emlTestAssertEqualNum: "TS-2 slope", 2.291666666666667,
... emlTheilSen.slope, tsTol
@emlTestAssertEqualNum: "TS-2 intercept (separate)", -0.72916666666666785,
... emlTheilSen.intercept, tsTol
@emlTestAssertEqualNum: "TS-2 nSlopes", 6, emlTheilSen.nSlopes, tsExact

@emlTestSection: "TS-3: n=7 with one gross y-outlier (robustness case)"
ts3X# = { 1, 2, 3, 4, 5, 6, 7 }
ts3Y# = { 2.1, 4.0, 6.2, 8.1, 10.0, 12.2, 40.0 }
@emlTheilSen: ts3X#, ts3Y#
@emlTestAssertEqualStr: "TS-3 no error", "", emlTheilSen.error$
@emlTestAssertEqualNum: "TS-3 slope", 2.0499999999999998,
... emlTheilSen.slope, tsTol
@emlTestAssertEqualNum: "TS-3 intercept (separate)", -0.099999999999999645,
... emlTheilSen.intercept, tsTol
@emlTestAssertEqualNum: "TS-3 nSlopes", 21, emlTheilSen.nSlopes, tsExact

@emlTestSection: "TS-4: n=6 with tied x values (pairs skipped)"
ts4X# = { 1, 1, 2, 2, 3, 3 }
ts4Y# = { 1.0, 2.0, 3.5, 4.0, 6.0, 5.5 }
@emlTheilSen: ts4X#, ts4Y#
@emlTestAssertEqualStr: "TS-4 no error", "", emlTheilSen.error$
@emlTestAssertEqualNum: "TS-4 slope", 2, emlTheilSen.slope, tsTol
@emlTestAssertEqualNum: "TS-4 intercept (separate)", -0.25,
... emlTheilSen.intercept, tsTol
# 15 unordered pairs, 3 of which share an x and must be excluded -> 12.
# nSlopes is the only observable that catches a pair-counting error: a
# median taken over the wrong pair set can still land on a plausible slope.
@emlTestAssertEqualNum: "TS-4 nSlopes (3 tied pairs excluded)", 12,
... emlTheilSen.nSlopes, tsExact

@emlTestSection: "TS-5: n=7, separate vs joint intercept DIVERGE"
ts5X# = { 0, 1, 2, 3, 4, 10, 11 }
ts5Y# = { 1.0, 3.0, 4.5, 7.5, 8.0, 21.0, 24.5 }
@emlTheilSen: ts5X#, ts5Y#
@emlTestAssertEqualStr: "TS-5 no error", "", emlTheilSen.error$
@emlTestAssertEqualNum: "TS-5 slope", 2.0625, emlTheilSen.slope, tsTol
@emlTestAssertEqualNum: "TS-5 intercept (separate)", 1.3125,
... emlTheilSen.intercept, tsTol
@emlTestAssertEqualNum: "TS-5 nSlopes", 21, emlTheilSen.nSlopes, tsExact

@emlTestSection: "TS-6: n=5, negative slope, non-integer x"
ts6X# = { 0.5, 1.25, 2.0, 3.75, 4.5 }
ts6Y# = { 10.0, 8.5, 7.0, 3.5, 2.0 }
@emlTheilSen: ts6X#, ts6Y#
@emlTestAssertEqualStr: "TS-6 no error", "", emlTheilSen.error$
@emlTestAssertEqualNum: "TS-6 slope", -2, emlTheilSen.slope, tsTol
@emlTestAssertEqualNum: "TS-6 intercept (separate)", 11,
... emlTheilSen.intercept, tsTol
@emlTestAssertEqualNum: "TS-6 nSlopes", 10, emlTheilSen.nSlopes, tsExact

@emlTestSection: "TS-7: n=2, minimum admissible input"
ts7X# = { 1, 3 }
ts7Y# = { 4, 10 }
@emlTheilSen: ts7X#, ts7Y#
@emlTestAssertEqualStr: "TS-7 no error", "", emlTheilSen.error$
@emlTestAssertEqualNum: "TS-7 slope", 3, emlTheilSen.slope, tsTol
@emlTestAssertEqualNum: "TS-7 intercept (separate)", 1,
... emlTheilSen.intercept, tsTol
@emlTestAssertEqualNum: "TS-7 nSlopes", 1, emlTheilSen.nSlopes, tsExact

@emlTestSection: "TS-8: n=9, irregular decimals (no round answer)"
ts8X# = { 0.7, 1.9, 2.3, 3.8, 4.1, 5.6, 6.2, 7.9, 8.4 }
ts8Y# = { 3.14, 4.02, 6.71, 7.05, 9.83, 10.11, 13.4, 14.02, 17.6 }
@emlTheilSen: ts8X#, ts8Y#
@emlTestAssertEqualStr: "TS-8 no error", "", emlTheilSen.error$
@emlTestAssertEqualNum: "TS-8 slope", 1.7243589743589745,
... emlTheilSen.slope, tsTol
@emlTestAssertEqualNum: "TS-8 intercept (separate)", 2.760128205128205,
... emlTheilSen.intercept, tsTol
@emlTestAssertEqualNum: "TS-8 nSlopes", 36, emlTheilSen.nSlopes, tsExact


# ============================================================================
# SECTION 2 — Intercept convention is pinned, not merely satisfied
# ============================================================================
# The assertions in section 1 already fail if the convention is switched, but
# only implicitly. These two make the claim explicit and legible: on TS-5 and
# TS-8 the joint-convention intercept is a specific WRONG answer, and the
# suite records that it is being excluded. Without them a reader has no way
# to tell, from this file alone, that the expected intercepts are
# convention-specific rather than convention-neutral.

@emlTestSection: "Intercept convention (Conover separate, not joint)"

# TS-5: separate = 1.3125, joint = 0.9375. Difference 0.375.
@emlTheilSen: ts5X#, ts5Y#
ts5JointDistance = abs (emlTheilSen.intercept - 0.9375)
@emlTestAssertTrue: "TS-5 intercept is NOT the joint value (0.9375)",
... ts5JointDistance > 0.01

# TS-8: separate = 2.760128205128205, joint = 1.9329487179487181.
@emlTheilSen: ts8X#, ts8Y#
ts8JointDistance = abs (emlTheilSen.intercept - 1.9329487179487181)
@emlTestAssertTrue: "TS-8 intercept is NOT the joint value (1.93294872)",
... ts8JointDistance > 0.01


# ============================================================================
# SECTION 3 — Error paths
# ============================================================================
# No scipy reference exists for these: scipy.stats.theilslopes on degenerate
# input returns nan or raises, so there is nothing to compare a number
# against. What IS checkable is that the guard fires with the right message
# and that .slope/.intercept stay undefined rather than becoming 0 or some
# nan-shaped value a caller would plot. A guard that sets .error$ but leaves
# a stale numeric behind is the failure mode being excluded here.

@emlTestSection: "E-1: size(x) <> size(y)"
e1X# = { 1, 2, 3 }
e1Y# = { 1, 2 }
@emlTheilSen: e1X#, e1Y#
@emlTestAssertContains: "E-1 error message", emlTheilSen.error$,
... "equal length"
@emlTestAssertUndefined: "E-1 slope undefined", emlTheilSen.slope
@emlTestAssertUndefined: "E-1 intercept undefined", emlTheilSen.intercept
@emlTestAssertEqualNum: "E-1 nSlopes = 0", 0, emlTheilSen.nSlopes, tsExact

@emlTestSection: "E-2: n = 1 (below the 2-observation minimum)"
e2X# = { 5 }
e2Y# = { 7 }
@emlTheilSen: e2X#, e2Y#
@emlTestAssertContains: "E-2 error message", emlTheilSen.error$,
... "at least 2 observations"
@emlTestAssertUndefined: "E-2 slope undefined", emlTheilSen.slope
@emlTestAssertUndefined: "E-2 intercept undefined", emlTheilSen.intercept
@emlTestAssertEqualNum: "E-2 nSlopes = 0", 0, emlTheilSen.nSlopes, tsExact

@emlTestSection: "E-3: all x identical, n >= 2 (zero valid pairs)"
e3X# = { 4, 4, 4 }
e3Y# = { 1, 2, 3 }
@emlTheilSen: e3X#, e3Y#
@emlTestAssertContains: "E-3 error message", emlTheilSen.error$,
... "all x values are identical"
@emlTestAssertUndefined: "E-3 slope undefined", emlTheilSen.slope
@emlTestAssertUndefined: "E-3 intercept undefined", emlTheilSen.intercept
@emlTestAssertEqualNum: "E-3 nSlopes = 0", 0, emlTheilSen.nSlopes, tsExact


# ============================================================================
# SECTION 4 — Coverage
# ============================================================================
# A suite that silently stops asserting halfway through still prints
# "ALL TESTS PASSED". This is the check that catches a deleted or
# accidentally-commented call site, and it is the reason the count below is
# itemised rather than eyeballed.
#
#   Section 1: 8 sets x 4 checks (no-error, slope, intercept, nSlopes) = 32
#   Section 2: 2 convention checks                                     =  2
#   Section 3: 3 error paths x 4 checks (message, slope, intercept,
#              nSlopes)                                                = 12
#                                                                       ----
#   checks performed before this one                                     46
#
# This assertion itself is check 47, so it compares against 46.

@emlTestSection: "Coverage"
tsExpectedChecks = 46
@emlTestAssertEqualNum: "coverage: all declared checks performed",
... tsExpectedChecks, emlTestInit.count, tsExact

@emlTestSummary
