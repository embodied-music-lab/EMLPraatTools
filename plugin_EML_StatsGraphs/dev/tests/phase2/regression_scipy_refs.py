#!/usr/bin/env python3
# ============================================================================
# EML Stats : scipy reference generator for test-regression.praat
# ============================================================================
# Version: 1.0
# Date: 2 August 2026
#
# Emits the expected literals asserted by test-regression.praat. This file is
# the external validation artifact for @emlLinearRegression: the Praat test's
# expected values must be copied from this script's output, never computed by
# hand and never re-derived from the same closed form the procedure uses.
#
# scipy.stats.linregress is an independent implementation. The F statistic and
# its p-value are not returned by linregress, so they are obtained from
# scipy.stats.f.sf on the t-to-F identity F = t^2 for simple regression, which
# is itself checked against a direct sums-of-squares computation below. If the
# two disagree the script exits non-zero rather than emitting literals.
#
# Run:  python3 regression_scipy_refs.py
# ============================================================================

import sys

import numpy as np
import scipy
from scipy import stats

DATASETS = {
    "Strong negative (n=10)": (
        [2, 4, 6, 8, 10, 12, 14, 16, 18, 20],
        [1.8, 1.5, 1.3, 1.1, 0.9, 0.7, 0.8, 0.6, 0.5, 0.4],
    ),
    "Weak positive (n=10)": (
        [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
        [2.1, 1.8, 2.5, 2.2, 2.9, 2.4, 3.1, 2.7, 3.0, 2.8],
    ),
    "Non-significant (n=8)": (
        [1, 2, 3, 4, 5, 6, 7, 8],
        [5.0, 4.8, 5.2, 5.1, 4.9, 5.0, 5.3, 4.7],
    ),
    "n=3 minimum": (
        [1, 2, 3],
        [10, 20, 30],
    ),
}

MISMATCH_TOL = 1e-9


def refs(x, y):
    x = np.asarray(x, dtype=float)
    y = np.asarray(y, dtype=float)
    n = x.size
    df = n - 2

    lr = stats.linregress(x, y)

    yhat = lr.intercept + lr.slope * x
    ss_res = float(np.sum((y - yhat) ** 2))
    ss_reg = float(np.sum((yhat - y.mean()) ** 2))

    se_resid = float(np.sqrt(ss_res / df)) if df > 0 else float("nan")

    # F from the sums of squares (direct), and F from t^2 (identity).
    f_direct = (ss_reg / 1.0) / (ss_res / df) if ss_res > 0 and df > 0 else float("inf")
    t_slope = lr.slope / lr.stderr if lr.stderr > 0 else float("inf")
    f_from_t = t_slope ** 2

    if np.isfinite(f_direct) and np.isfinite(f_from_t):
        rel = abs(f_direct - f_from_t) / max(abs(f_direct), 1.0)
        if rel > MISMATCH_TOL:
            print(
                "ABORT: F from sums-of-squares (%r) disagrees with t^2 (%r)"
                % (f_direct, f_from_t),
                file=sys.stderr,
            )
            sys.exit(1)

    p_f = float(stats.f.sf(f_direct, 1, df)) if np.isfinite(f_direct) and df > 0 else 0.0

    return {
        "n": n,
        "slope": lr.slope,
        "intercept": lr.intercept,
        "r": lr.rvalue,
        "rSquared": lr.rvalue ** 2,
        "fStat": f_direct,
        "pF": p_f,
        "seResidual": se_resid,
        "seSlope": lr.stderr,
        "seIntercept": lr.intercept_stderr,
        "tSlope": t_slope,
        "pSlope": lr.pvalue,
    }


def main():
    print("=" * 74)
    print("scipy reference values for test-regression.praat")
    print("scipy %s / numpy %s" % (scipy.__version__, np.__version__))
    print("=" * 74)
    for label, (x, y) in DATASETS.items():
        print()
        print("--- %s ---" % label)
        r = refs(x, y)
        for key in (
            "n",
            "slope",
            "intercept",
            "r",
            "rSquared",
            "fStat",
            "pF",
            "seResidual",
            "seSlope",
            "seIntercept",
            "tSlope",
            "pSlope",
        ):
            v = r[key]
            print("  %-12s %.10f" % (key, v) if isinstance(v, float) else "  %-12s %d" % (key, v))
    print()
    print("Copy these literals into the .expected slot of the corresponding")
    print("@emlTestAssertEqualNum calls in test-regression.praat.")


if __name__ == "__main__":
    main()
