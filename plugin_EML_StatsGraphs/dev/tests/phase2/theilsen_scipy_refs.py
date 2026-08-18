#!/usr/bin/env python3
# ============================================================================
# EML @emlTheilSen — Reference Value Computation (scipy)
# ============================================================================
# Version: 1.3
# Date: 3 August 2026
#
# Generates the reference literals asserted by test-theilsen.praat.
#
# v1.3 — the printed E-3 expectation matches the refusal text
#   eml-inferential.praat emits: "All <n> x values are identical, so no slope
#   can be estimated." User-facing text carries no procedure name, so a crib
#   quoting one would send a reader to "fix" the library. The scipy
#   behaviour it summarises was re-confirmed on scipy 1.17.1: theilslopes on
#   x = [4,4,4] warns "All `x` coordinates are identical" and returns
#   slope = nan, intercept = nan.
#
# v1.2 — the file declared its eight test vectors TWICE: once in a series of
#   refs(...) calls and again in a `_sets` list feeding the DISCRIMINATION
#   MAP. Nothing compared the two copies, so editing one would have left the
#   map characterising data the reference literals were not computed from,
#   silently. That is precisely the drift defect this file was written to
#   close in EML_PROCEDURE_REGISTRY.md, reproduced inside the closing
#   artifact. The vectors are now declared once, in `SETS`, and both
#   consumers iterate it. Per-set rationale moved from banner comments into
#   a `why` field of the same tuple, so a set cannot be added without one.
#   The comment above the DISCRIMINATION MAP does not name the collinear
#   sets either — that list is measured and printed.
#   Numeric output is unchanged; verified byte-identical to the v1.1 run
#   apart from the added WHY: lines.
#
# v1.1 — three defects in this file, found by running it rather than by
#   reading it:
#   (a) the provenance line printed `stats.__name__` (a module name) as the
#       scipy version and labelled numpy's version as scipy's;
#   (b) numpy scalar reprs leaked into the printed test data
#       (`x = [np.float64(1.0), ...]`), which is not pasteable;
#   (c) the DISCRIMINATION MAP's summary lines were hand-transcribed and had
#       already drifted — they named TS-6 and TS-7 as the collinear sets while
#       the file's own measurement flagged TS-1 as well. They are now
#       accumulated from the measurement loop. A transcribed claim
#       contradicting a computed one in the same file is the defect class this
#       file exists to close in the registry.
#   Also: the literals emitted for the .praat suite are now full-precision
#   (%.17g) rather than 10-decimal. See TOLERANCE below.
#
# WHY THIS FILE EXISTS
# EML_PROCEDURE_REGISTRY.md described @emlTheilSen as "scipy-verified".
# No test for it existed anywhere in dev/tests/ and no verification
# annotation appeared in its header. The claim was unbacked. @emlTheilSen
# is not dead code — it is live in the graphing path. Both call sites are
# inside `procedure emlDrawScatterPlot` in graphs/eml-draw-procedures.praat,
# each guarded by `.useTheilSen = 1` / `.gUseTheilSen = 1` (set when the
# annotation correlation is Spearman and OLS was not reported):
#     `@emlTheilSen: .xData#, .yData#`     ungrouped trend line
#     `@emlTheilSen: .gXTrim#, .gYTrim#`   per-group trend line
# A wrong slope reaches the user as a drawn trend line, which is exactly the
# class of error a reader will not catch by eye. Verified 8 August 2026:
#     grep -n "@emlTheilSen:" graphs/eml-draw-procedures.praat   -> 2 hits
#
# Deliberately no line numbers: they drift faster than this comment is
# revisited. A pointer here has gone stale inside a single working session,
# by 68 lines, and landed on bar-chart gridline code. Grep the call strings.
#
# INTERCEPT CONVENTION — the thing this file is actually pinning down
# There are two intercept conventions in circulation for Theil-Sen:
#   separate (Conover 1980):  b = median(y) - slope * median(x)
#   joint:                    b = median(y - slope * x)
# scipy.stats.theilslopes implements BOTH, selected by `method=`, and its
# default is 'separate'. @emlTheilSen implements 'separate'. Test Set 5
# below is constructed so the two conventions give visibly different
# intercepts; the .praat suite asserts the 'separate' value and the
# 'joint' value is printed alongside so that a future reader can see the
# assertion is convention-specific rather than accidentally satisfied by
# both. Verifying a Conover intercept against a joint reference would
# pass on symmetric data and fail on real data.
#
# TOLERANCE — why the pasteable literals are full-precision
# A previous revision of this header argued for emitting 10-decimal literals
# on the grounds that ulp(10) = 5e-11 gave the .praat suite "a real band to
# discriminate in". That reasoning is backwards, and the data below refutes
# it: TS-2's true slope is 2.291666666666667, whose 10-decimal rounding
# (2.2916666667) differs from it by 3.33e-11 — 67% of a 5e-11 tolerance
# consumed by transcription alone, before a single arithmetic difference
# between Praat and scipy is accounted for. A set landing near the .5
# rounding boundary would consume the budget exactly and sit on the knife
# edge. The tolerance must be sized for numerical reproducibility (Praat
# medians a differently-ordered sort than scipy does), not for the emitter's
# own rounding.
#
# So each set prints a PRAAT: line carrying %.17g literals, which a double
# round-trips exactly, and test-theilsen.praat asserts those with an absolute
# tolerance of 5e-11 (1e-12 for TS-1's exact-zero intercept). Transcription
# error is then nil and the full 5e-11 is available to discriminate: the
# suite's negative control perturbs a literal by 1e-10, which clears the band
# by 2x. The 10-decimal forms are still printed for human reading.
# ============================================================================

import numpy as np
import scipy
from scipy import stats

print("=" * 70)
print("EML @emlTheilSen — Reference Value Computation (scipy)")
print("scipy %s, numpy %s" % (scipy.__version__, np.__version__))
print("=" * 70)


def refs(label, x, y, note=""):
    x = np.asarray(x, dtype=float)
    y = np.asarray(y, dtype=float)

    sep = stats.theilslopes(y, x, method="separate")
    joint = stats.theilslopes(y, x, method="joint")

    # Number of pairwise slopes with x_i != x_j. @emlTheilSen counts these
    # and exposes the count as .nSlopes, so it is asserted too: a slope
    # median computed over the wrong number of pairs can still land on a
    # plausible value, and .nSlopes is the only observable that would
    # catch it.
    n = len(x)
    n_slopes = sum(1 for i in range(n - 1) for j in range(i + 1, n)
                   if x[i] != x[j])

    print("\n" + "=" * 66)
    print("  %s" % label)
    if note:
        print("  (%s)" % note)
    print("=" * 66)
    print("  x = %s" % [float(v) for v in x])
    print("  y = %s" % [float(v) for v in y])
    print("  n = %d, nSlopes = %d, slope-count parity = %s"
          % (n, n_slopes, "odd" if n_slopes % 2 else "even"))
    print("  slope             = %.10f      (%.17g)" % (sep.slope, sep.slope))
    print("  intercept separate= %.10f      (%.17g)"
          % (sep.intercept, sep.intercept))
    print("  intercept joint   = %.10f      (%.17g)"
          % (joint.intercept, joint.intercept))
    print("  separate - joint  = %.17g" % (sep.intercept - joint.intercept))
    # Paste-ready literals for test-theilsen.praat. Full precision, so the
    # suite's tolerance is spent on Praat-vs-scipy arithmetic order rather
    # than on this file's rounding. Tag is the label's leading token.
    tag = label.split(":")[0]
    print("  PRAAT: %s  slope=%.17g  intercept=%.17g  nSlopes=%d"
          % (tag, sep.slope, sep.intercept, n_slopes))
    return sep.slope, sep.intercept, n_slopes


# ======================================================================
# TS-1: odd number of pairwise slopes, clean positive trend
#   n=4 -> 6 pairs (even). Use n=3 -> 3 pairs (odd) to hit the odd branch
#   of the slope-median selection.
# ======================================================================
# ============================================================================
# THE TEST SETS — declared ONCE
# ============================================================================
# v1.1 carried this data twice: once in a series of refs(...) calls and again
# in a `_sets` list that fed the DISCRIMINATION MAP. Two copies of the same
# vectors is the drift hazard this file exists to close in the registry — edit
# one and the map silently describes data the references were not computed
# from, with nothing to flag the divergence. The sets are now declared once
# here and both consumers iterate this list.
#
# Per-set rationale is carried in the `why` field rather than in banner
# comments, so a set cannot be added without its justification.

SETS = [
    ("TS-1", "n=3, 3 pairwise slopes (ODD median branch)",
     [1, 2, 3], [2, 5, 7], "",
     "n=4 gives 6 pairs (even); n=3 gives 3 (odd), hitting the odd branch "
     "of the slope-median selection."),

    ("TS-2", "n=4, 6 pairwise slopes (EVEN median branch, even n)",
     [1, 2, 3, 4], [2.0, 4.5, 5.5, 9.0], "",
     "Even number of pairwise slopes AND even n, so both median branches "
     "take the averaging path simultaneously."),

    ("TS-3", "n=7 with one gross y-outlier (robustness case)",
     [1, 2, 3, 4, 5, 6, 7], [2.1, 4.0, 6.2, 8.1, 10.0, 12.2, 40.0],
     "OLS slope on this data is far from the Theil-Sen slope",
     "The case the estimator exists for. If the implementation quietly fell "
     "back to a mean anywhere, this set separates it from OLS."),

    ("TS-4", "n=6 with tied x values (pairs skipped)",
     [1, 1, 2, 2, 3, 3], [1.0, 2.0, 3.5, 4.0, 6.0, 5.5],
     "3 of 15 pairs share an x and must be excluded",
     "Tied x values. Pairs with equal x are SKIPPED (undefined slope), so "
     "nSlopes < n(n-1)/2. This is the branch where a naive implementation "
     "divides by zero or counts a pair it should not."),

    ("TS-5", "n=7, separate vs joint intercept DIVERGE",
     [0, 1, 2, 3, 4, 10, 11], [1.0, 3.0, 4.5, 7.5, 8.0, 21.0, 24.5],
     "this is the set that pins the Conover convention",
     "CONVENTION DISCRIMINATOR. Asymmetric residuals so that "
     "median(y) - slope*median(x) != median(y - slope*x). The .praat suite "
     "asserts the separate (Conover) value; switching the implementation to "
     "the joint convention fails this set while TS-1..TS-4 might not."),

    ("TS-6", "n=5, negative slope, non-integer x",
     [0.5, 1.25, 2.0, 3.75, 4.5], [10.0, 8.5, 7.0, 3.5, 2.0], "",
     "Sign handling and the sort of a vector containing negatives."),

    ("TS-7", "n=2 (minimum admissible input, boundary of the guard)",
     [1, 3], [4, 10], "",
     "One pairwise slope; the estimator is then just the two-point slope, "
     "and the separate-convention intercept uses the mean of the two x and "
     "y values, which coincides with the line. Boundary of the .n < 2 guard."),

    ("TS-8", "n=9, irregular decimals (no round answer)",
     [0.7, 1.9, 2.3, 3.8, 4.1, 5.6, 6.2, 7.9, 8.4],
     [3.14, 4.02, 6.71, 7.05, 9.83, 10.11, 13.4, 14.02, 17.6],
     "deliberately unroundable; guards against coincidental agreement",
     "TS-1..TS-7 isolate branches but several land on round values "
     "(2.5, 3, -2, 11). A round expected value is a weaker assertion than a "
     "messy one, because more wrong implementations hit it by coincidence — "
     "TS-1's median and mean of pairwise slopes are BOTH 2.5, so TS-1 alone "
     "cannot tell a median from a mean. This set exists so that at least one "
     "slope and one intercept in the suite are values nothing arrives at by "
     "accident."),
]

for _tag, _desc, _x, _y, _note, _why in SETS:
    print("\n" + "-" * 66)
    print("  WHY: %s" % _why)
    refs("%s: %s" % (_tag, _desc), _x, _y, note=_note)

# ======================================================================
# DISCRIMINATION MAP
# ======================================================================
# A test set only earns credit for what it can actually distinguish. Some
# of the sets above are exactly collinear, which means the median of
# pairwise slopes, the MEAN of pairwise slopes, and the OLS slope all
# coincide — those sets exercise branches (odd/even median selection,
# negative slope, the n=2 boundary) but they cannot tell a correct
# Theil-Sen from an ordinary least-squares fit. WHICH sets those are is
# measured below and printed; it is deliberately not named in this comment,
# because a named list here is a second copy of a computed fact and drifts
# the moment a set is edited.
#
# This loop iterates the SAME `SETS` table the references were computed
# from. v1.1 kept a second copy of the vectors here, so editing one copy
# left the map describing data the references were not computed from.
print("\n" + "=" * 70)
print("DISCRIMINATION MAP — what each set can actually distinguish")
print("=" * 70)
print("  set    median        mean          OLS           |med-mean|  |med-OLS|")
_degenerate = []
_discriminates_estimator = []
_discriminates_convention = []
for _lab, _d, _x, _y, _n, _w in SETS:
    _x = np.asarray(_x, float)
    _y = np.asarray(_y, float)
    _s = [(_y[j] - _y[i]) / (_x[j] - _x[i])
          for i in range(len(_x)) for j in range(i + 1, len(_x))
          if _x[i] != _x[j]]
    _med = float(np.median(_s))
    _mean = float(np.mean(_s))
    _ols = float(np.polyfit(_x, _y, 1)[0])
    _deg = abs(_med - _mean) < 1e-9 and abs(_med - _ols) < 1e-9
    _flag = "  <- DEGENERATE (cannot distinguish estimator)" if _deg else ""
    (_degenerate if _deg else _discriminates_estimator).append(_lab)
    # Does this set separate the two intercept conventions?
    _sep = float(stats.theilslopes(_y, _x, method="separate").intercept)
    _joi = float(stats.theilslopes(_y, _x, method="joint").intercept)
    if abs(_sep - _joi) > 1e-9:
        _discriminates_convention.append(_lab)
    print("  %-6s %-13.10f %-13.10f %-13.10f %-11.4g %-11.4g%s"
          % (_lab, _med, _mean, _ols, abs(_med - _mean), abs(_med - _ols),
             _flag))

# These three lists are MEASURED above, not transcribed. A hand-written
# summary drifts the moment a set is added or its data edited — that is the
# same defect this file was written to close in the registry.
print("\n  Sets that DO discriminate median-vs-mean/OLS: %s"
      % ", ".join(_discriminates_estimator))
print("  Sets that DO discriminate separate-vs-joint intercept: %s"
      % ", ".join(_discriminates_convention))
print("  Exactly collinear (branch coverage only): %s"
      % ", ".join(_degenerate))

print("\n" + "=" * 70)
print("ERROR-PATH CASES (no scipy reference — asserted on .error$ only)")
print("=" * 70)
print("  E-1: size(x) != size(y)      -> 'x and y must have equal length'")
print("  E-2: n = 1                   -> 'need at least 2 observations'")
print("  E-3: all x identical, n >= 2 -> 'All 3 x values are identical'")
print("       scipy.stats.theilslopes on all-identical x returns nan/raises;")
print("       there is no external reference to check against, so the")
print("       .praat suite asserts the guard fires and that .slope stays")
print("       undefined rather than becoming 0 or nan-shaped garbage.")
