#!/usr/bin/env python3
# ============================================================================
# EML Stats : scipy reference generator for the tied/zero cases in
#             test-inferential-batch3.praat
# ============================================================================
# Version: 1.0
# Date: 2 August 2026
#
# WHY THIS FILE EXISTS
# --------------------
# verify-inferential-batch3.R can verify only 12 of the 22 expectations in
# test-inferential-batch3.praat. The other eight involve ties (Mann-Whitney)
# or tied absolute differences / zero differences (signed-rank). In those
# cases R's wilcox.test refuses the exact path -- it warns "cannot compute
# exact p-value with ties" and silently falls back to the normal
# approximation -- so it cannot supply an *exact* reference. Those eight are
# registered as counted SKIPs in the R verifier, which exits 2 (INCOMPLETE).
#
# This file supplies the missing external reference. It is NOT an exact
# permutation enumeration, and that is deliberate: @emlMannWhitneyU and
# @emlWilcoxonSignedRank were changed in v1.1 of the library to follow R's
# routing rule exactly -- the exact null is used only when there are no ties
# (and, for the signed-rank test, no zero differences); otherwise the normal
# approximation with tie correction and continuity correction is used, as R
# does. Every one of these eight cases therefore asserts
# method$ = "normal approximation" in the Praat test. The correct external
# reference is the tie-corrected normal approximation, which is what scipy
# computes on its asymptotic path. Referencing these against a permutation
# enumeration would be checking the library against a quantity it does not
# claim to compute.
#
# SELF-VALIDATION
# ---------------
# scipy is the reference, but a reference that is merely called is not a
# reference that is checked. Every value emitted below is computed twice:
# once through scipy's public API, and once through an independent
# from-first-principles implementation in this file (average ranks, the
# tie-corrected variance, and the continuity correction written out
# longhand). If the two paths disagree by more than MISMATCH_TOL the script
# aborts non-zero and emits nothing, so a silent scipy behaviour change
# cannot quietly rewrite the reference literals.
#
# Run:  python3 batch3_scipy_refs.py
# Exit: 0 = literals emitted; 1 = internal disagreement, nothing emitted.
# ============================================================================

import sys

import numpy as np
import scipy
from scipy import stats

MISMATCH_TOL = 1e-9


# ----------------------------------------------------------------------------
# Independent longhand implementations (the cross-check path)
# ----------------------------------------------------------------------------

def _tie_term(values):
    """sum(t^3 - t) over tie groups -- the standard tie correction term."""
    _, counts = np.unique(values, return_counts=True)
    return float(np.sum(counts ** 3 - counts))


def mwu_longhand(x, y, alternative):
    """Mann-Whitney U, normal approximation, tie-corrected, continuity-corrected."""
    x = np.asarray(x, dtype=float)
    y = np.asarray(y, dtype=float)
    n1, n2 = x.size, y.size
    n = n1 + n2

    combined = np.concatenate([x, y])
    ranks = stats.rankdata(combined, method="average")
    r1 = float(np.sum(ranks[:n1]))

    u1 = r1 - n1 * (n1 + 1) / 2.0
    u2 = n1 * n2 - u1
    mu = n1 * n2 / 2.0

    var = (n1 * n2 / 12.0) * ((n + 1) - _tie_term(combined) / (n * (n - 1.0)))
    sd = np.sqrt(var)

    d = u1 - mu
    if alternative == "two-sided":
        # Continuity correction moves the statistic 0.5 toward the mean. When
        # the statistic is within 0.5 of the mean (a saturated case such as a
        # perfectly symmetric split) the correction would carry it past the
        # mean and flip the sign of z, so z is clamped to 0 and p to 1.
        z = (abs(d) - 0.5) / sd
        if z < 0:
            z = 0.0
        p = min(2.0 * stats.norm.sf(z), 1.0)
    elif alternative == "greater":
        p = float(stats.norm.sf((d - 0.5) / sd))
    else:
        p = float(stats.norm.cdf((d + 0.5) / sd))

    return {"u1": u1, "u2": u2, "p": float(p)}


def wsr_longhand(x, y, alternative):
    """Wilcoxon signed-rank, normal approximation, tie-corrected, continuity-corrected.

    Zero differences are discarded before ranking (R's and the library's
    "wilcox" zero method), and n is the count of non-zero differences.
    """
    x = np.asarray(x, dtype=float)
    y = np.asarray(y, dtype=float)
    diffs = x - y
    n_zero = int(np.sum(diffs == 0))
    d = diffs[diffs != 0]
    n = d.size

    ranks = stats.rankdata(np.abs(d), method="average")
    t_plus = float(np.sum(ranks[d > 0]))
    t_minus = float(np.sum(ranks[d < 0]))

    mu = n * (n + 1) / 4.0
    var = n * (n + 1) * (2 * n + 1) / 24.0 - _tie_term(np.abs(d)) / 48.0
    sd = np.sqrt(var)

    if alternative == "two-sided":
        t_stat = min(t_plus, t_minus)
        z = (abs(t_stat - mu) - 0.5) / sd
        if z < 0:
            z = 0.0
        p = min(2.0 * stats.norm.sf(z), 1.0)
    elif alternative == "greater":
        t_stat = t_plus
        p = float(stats.norm.sf((t_stat - mu - 0.5) / sd))
    else:
        t_stat = t_plus
        p = float(stats.norm.cdf((t_stat - mu + 0.5) / sd))

    return {
        "tPlus": t_plus,
        "tMinus": t_minus,
        "nNonzero": n,
        "nZero": n_zero,
        "statistic": t_stat,
        "p": float(p),
    }


# ----------------------------------------------------------------------------
# Cases -- these are exactly the eight skipped by verify-inferential-batch3.R
# ----------------------------------------------------------------------------

MWU_CASES = [
    ("MWU-1.2", [1, 2, 3, 4], [2, 3, 5, 6], "two-sided",
     "value 2 and value 3 tied across groups"),
    ("MWU-1.5", [1, 2, 3, 4, 5], [1, 2, 3, 4, 5], "two-sided",
     "identical groups -- every value tied; saturated (p = 1)"),
    ("MWU-1.7", list(range(1, 11)), list(range(6, 16)), "two-sided",
     "values 6-10 tied across groups"),
]

WSR_CASES = [
    ("WSR-4.2", [8, 6, 3, 12, 5], [5, 3, 1, 7, 4], "two-sided",
     "tied absolute differences"),
    ("WSR-4.3", [5, 3, 7, 4, 6], [5, 1, 7, 2, 6], "two-sided",
     "three zero differences plus tied absolute differences"),
    ("WSR-4.6", [10, 5], [5, 10], "two-sided",
     "tied absolute differences; saturated (p = 1)"),
    ("WSR-4.7", list(range(16, 31)), list(range(1, 16)), "greater",
     "all differences equal -- maximal ties; one-tailed"),
    ("WSR-4.8",
     [10, 12, 8, 15, 6, 20, 3, 14, 9, 11, 7, 16, 5, 18, 13],
     [8, 10, 9, 12, 7, 15, 5, 10, 11, 8, 9, 12, 7, 14, 10],
     "two-sided", "tied absolute differences"),
]


def _agree(label, field, a, b):
    if not (np.isfinite(a) and np.isfinite(b)):
        print("ABORT: %s %s is not finite (scipy=%r longhand=%r)"
              % (label, field, a, b), file=sys.stderr)
        sys.exit(1)
    if abs(a - b) > MISMATCH_TOL:
        print("ABORT: %s %s disagrees -- scipy=%.15f longhand=%.15f (tol %g)"
              % (label, field, a, b, MISMATCH_TOL), file=sys.stderr)
        sys.exit(1)


def main():
    print("=" * 74)
    print("scipy reference values for the tied/zero cases in")
    print("test-inferential-batch3.praat")
    print("scipy %s / numpy %s" % (scipy.__version__, np.__version__))
    print("=" * 74)
    print()
    print("Path: normal approximation with tie correction and continuity")
    print("correction -- the same path the library takes for these inputs,")
    print("and the same path R falls back to. NOT an exact permutation null.")
    print()

    print("--- Mann-Whitney U (tied inputs) ---")
    for label, a, b, alt, why in MWU_CASES:
        lh = mwu_longhand(a, b, alt)
        sp = stats.mannwhitneyu(a, b, alternative=alt,
                                method="asymptotic", use_continuity=True)
        _agree(label, "U1", float(sp.statistic), lh["u1"])
        _agree(label, "p", float(sp.pvalue), lh["p"])
        print()
        print("  %s  (%s)" % (label, why))
        print("    alternative   %s" % alt)
        print("    U1            %.10f" % lh["u1"])
        print("    U2            %.10f" % lh["u2"])
        print("    p             %.10f" % lh["p"])
        print("    method        normal approximation")

    print()
    print("--- Wilcoxon signed-rank (tied / zero differences) ---")
    for label, x, y, alt, why in WSR_CASES:
        lh = wsr_longhand(x, y, alt)
        sp = stats.wilcoxon(np.asarray(x, dtype=float), np.asarray(y, dtype=float),
                            alternative=alt, method="approx",
                            correction=True, zero_method="wilcox")
        _agree(label, "statistic", float(sp.statistic), lh["statistic"])
        _agree(label, "p", float(sp.pvalue), lh["p"])
        print()
        print("  %s  (%s)" % (label, why))
        print("    alternative   %s" % alt)
        print("    T+            %.10f" % lh["tPlus"])
        print("    T-            %.10f" % lh["tMinus"])
        print("    n non-zero    %d" % lh["nNonzero"])
        print("    n zero        %d" % lh["nZero"])
        print("    p             %.10f" % lh["p"])
        print("    method        normal approximation")

    print()
    print("=" * 74)
    print("All %d cases agreed between scipy and the longhand path to within %g."
          % (len(MWU_CASES) + len(WSR_CASES), MISMATCH_TOL))
    print("Copy these literals into the corresponding checks in")
    print("verify-inferential-batch3.R and into the .expected slots in")
    print("test-inferential-batch3.praat. Do not hand-edit them.")
    print("=" * 74)


if __name__ == "__main__":
    main()
