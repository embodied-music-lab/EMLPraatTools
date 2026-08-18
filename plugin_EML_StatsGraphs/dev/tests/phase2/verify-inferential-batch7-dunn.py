#!/usr/bin/env python3
# ============================================================================
# EML Stats Batch 7 — Dunn's Post-Hoc External Verification (scikit-posthocs)
# ============================================================================
# Verifies the Dunn's-test reference literals baked into
# test-inferential-batch7.praat against an independent implementation.
#
# Version: 1.0
# Date: 3 August 2026
#
# Requires: scikit-posthocs, scipy, pandas, numpy. No version is pinned
# here: pinning a version is the same class of defect as pinning a
# download URL. If the API this file uses changes, the check fails loudly
# rather than silently verifying nothing.
#
# WHY THIS FILE EXISTS
# The R sibling (verify-inferential-batch7.R) covers Kruskal-Wallis but
# cannot currently cover Dunn's test at all: the dunn.test package is not
# installed and CRAN is unreachable, so that entire section registers as
# SKIPPED. Re-deriving Dunn's test longhand in R would be a
# re-implementation of the thing under test, not an external check.
# scikit-posthocs is an independent implementation and restores a genuine
# external reference.
#
# Three things this file covers that R structurally cannot, even with
# dunn.test installed:
#
#   1. Holm-adjusted pair 4 of Dunn-3. dunn.test reports ONE-TAILED
#      adjusted p-values. Holm's running-max is not linear, so doubling
#      its output does not commute with the adjustment; for that pair the
#      doubled value disagrees with the correct two-tailed one and the R
#      verifier must skip it. scikit-posthocs is natively two-sided, so no
#      doubling is involved and the pair is directly checkable.
#   2. Dunn-5 (the 3x30 large-sample set). No external verifier currently
#      touches it.
#   3. Raw (unadjusted) two-sided p-values, for the same reason as (1).
#
# The z statistics checked here are NOT recomputed from mean ranks — that
# would re-implement Dunn's test. They are derived from scikit-posthocs'
# own unadjusted two-sided p-values by z = norm.isf(p/2), which inverts
# only the normal tail, a step no part of Dunn's test is involved in.
# Sign is discarded on both sides: the library under test reports signed z
# whose sign follows its own group ordering, and the sign carries no
# information the p-value does not already carry. The Praat suite asserts
# the signs separately against its own ordering convention.
#
# Exit-code contract, shared by every verifier in this directory:
#   0 = all checks performed and passed
#   1 = at least one check FAILED
#   2 = no failures, but at least one check was SKIPPED (incomplete)
# A runner must not collapse 2 into 0.
#
# Set EML_EMIT_REFS=1 to additionally print each computed reference value
# at full precision (REF: <label> = <%.17g>). Additive only; the exit code
# is unchanged.
# ============================================================================

import os
import sys
from itertools import combinations

import numpy as np

EMIT_REFS = os.environ.get("EML_EMIT_REFS", "") == "1"

# ---------------------------------------------------------------------------
# Tolerance policy
# ---------------------------------------------------------------------------
# A literal transcribed to d decimal places carries a half-ulp of
# 0.5 * 10^-d. Verifying such a literal to any looser band cannot detect a
# mis-transcription in the digits actually written down, which is the only
# error this file exists to catch.


def ulp(d):
    """Half-unit-in-the-last-place for a literal written to d decimals."""
    return 0.5 * 10 ** (-d)


# For quantities that are exact in IEEE double arithmetic (an adjusted
# p-value clamped to exactly 1.0, a pair count).
EXACT_TOL = 1e-12

pass_count = 0
fail_count = 0
skipped = 0
skip_reasons = []


def register_skip(reason):
    global skipped
    skipped += 1
    skip_reasons.append(reason)
    print("  SKIP: %s" % reason)


def check(label, expected, actual, tolerance):
    """Compare a suite literal against an externally computed value.

    `tolerance` is REQUIRED. There is deliberately no default: a default
    is how a verifier comes to check eight-decimal literals to four
    decimals without anyone choosing that. Every call site states the
    precision it is asserting.
    """
    global pass_count, fail_count
    if EMIT_REFS and actual is not None and not _isnan(actual):
        print("REF: %s = %.17g" % (label, actual))
    if actual is None or _isnan(actual) or expected is None or _isnan(expected):
        register_skip("%s (NaN/None result - check not performed)" % label)
        return
    diff = abs(expected - actual)
    if diff < tolerance:
        print("  PASS: %s (expected=%.17g, got=%.17g)" % (label, expected, actual))
        pass_count += 1
    else:
        print(
            "  FAIL: %s (expected=%.17g, got=%.17g, diff=%.17g, tol=%.17g)"
            % (label, expected, actual, diff, tolerance)
        )
        fail_count += 1


def _isnan(x):
    try:
        return x != x
    except TypeError:
        return True


# ---------------------------------------------------------------------------
# Dependency resolution
# ---------------------------------------------------------------------------
# A missing dependency must produce SKIPs (exit 2), never a silent pass and
# never a crash that a runner could read as "no failures".

HAS_SP = True
try:
    import pandas as pd
    import scikit_posthocs as sp
    from scipy import stats
except ImportError as exc:  # pragma: no cover - environment dependent
    HAS_SP = False
    IMPORT_ERROR = str(exc)

# Every check performed when the dependency is present. If the dependency
# is absent, the same number of SKIPs is registered, so the coverage
# assertion below holds in both environments and cannot be satisfied by a
# section quietly vanishing.
#
#   Dunn-1: 3 |z| + 3 raw p + 3 Bonferroni       =  9
#   Dunn-3: 6 |z| + 6 Bonferroni + 6 Holm        = 18
#   Dunn-5: 3 |z| + 3 Bonferroni                 =  6
#                                                  --
#                                                  33
#
# This constant was first written as 40 from an estimate rather than a
# count, and the assertion below caught it on the first run. Left as a
# note because it is the cheapest available demonstration that the check
# discriminates.
EXPECTED_CHECKS = 33

# ---------------------------------------------------------------------------
# Test data — transcribed from test-inferential-batch7.praat
# ---------------------------------------------------------------------------
# Sets 1 and 3 also appear in batch7_scipy_refs.py; set 5 is the large
# sample generated there with numpy's seeded default_rng equivalent and
# hardcoded into the Praat suite. The values below were extracted
# mechanically from the .praat source rather than retyped.

SET1 = {
    1: [23, 25, 27, 22, 26],
    2: [30, 33, 29, 31, 34],
    3: [18, 20, 22, 19, 17],
}

SET3 = {
    1: [5, 6, 7, 5, 6],
    2: [8, 9, 10, 8],
    3: [5, 6, 7],
    4: [12, 13, 14, 12, 13, 15],
}

SET5 = {
    1: [
        54.967142, 48.617357, 56.476885, 65.230299, 47.658466, 47.658630,
        65.792128, 57.674347, 45.305256, 55.425600, 45.365823, 45.342702,
        52.419623, 30.867198, 32.750822, 44.377125, 39.871689, 53.142473,
        40.919759, 35.876963, 64.656488, 47.742237, 50.675282, 35.752518,
        44.556173, 51.109226, 38.490064, 53.756980, 43.993613, 47.083063,
    ],
    2: [
        48.982934, 73.522782, 54.865028, 44.422891, 63.225449, 42.791564,
        57.088636, 35.403299, 41.718140, 56.968612, 62.384666, 56.713683,
        53.843517, 51.988963, 40.214780, 47.801558, 50.393612, 65.571222,
        58.436183, 37.369598, 58.240840, 51.149177, 48.230780, 61.116763,
        65.309995, 64.312801, 46.607825, 51.907876, 58.312634, 64.755451,
    ],
    3: [
        40.208258, 43.143410, 33.936650, 33.037934, 53.125258, 58.562400,
        44.279899, 55.035329, 48.616360, 38.548802, 48.613956, 60.380366,
        44.641740, 60.646437, 18.802549, 53.219025, 45.870471, 42.009926,
        45.917608, 25.124311, 42.803281, 48.571126, 59.778940, 39.817298,
        36.915064, 39.982430, 54.154021, 48.287511, 39.702398, 50.132674,
    ],
}

# ---------------------------------------------------------------------------
# Reference literals — transcribed from test-inferential-batch7.praat
# ---------------------------------------------------------------------------
# Pair order is the same lexicographic order the library uses:
# (1,2), (1,3), (2,3) for k=3; (1,2), (1,3), (1,4), (2,3), (2,4), (3,4)
# for k=4. |z| is asserted; the suite asserts the signs separately.

# Dunn-1 (Test Set 1, k=3, Bonferroni)
D1_ABS_Z = [1.80473438, 1.69857354, 3.50330792]
D1_RAW_P = [0.07111626, 0.08939957, 0.0004595179363709061]
D1_BONF = [0.21334877, 0.26819870, 0.00137855]

# Dunn-3 (Test Set 3, k=4)
D3_ABS_Z = [1.74208332, 0.13765210, 3.48630836, 1.39846873, 1.46002104, 2.84332963]
D3_BONF = [0.48896320, 1.00000000, 0.00293842, 0.97183414, 0.86570575, 0.02678692]
D3_HOLM = [0.32597546, 0.89051537, 0.00293842, 0.43285287, 0.43285287, 0.02232244]

# Dunn-5 (Test Set 5, k=3, large sample, Bonferroni)
D5_ABS_Z = [2.25833958, 0.90926583, 3.16760541]
D5_BONF = [0.07177349, 1.00000000, 0.00461100]


def _long_frame(groups):
    rows_v = []
    rows_g = []
    for gid in sorted(groups):
        for v in groups[gid]:
            rows_v.append(float(v))
            rows_g.append(gid)
    return pd.DataFrame({"v": rows_v, "g": rows_g})


def dunn(groups, adjust):
    """Return a pair-ordered list of p-values from scikit-posthocs.

    `adjust=None` yields the unadjusted two-sided p-values.
    """
    df = _long_frame(groups)
    m = sp.posthoc_dunn(df, val_col="v", group_col="g", p_adjust=adjust)
    keys = sorted(groups)
    return [float(m.loc[a, b]) for a, b in combinations(keys, 2)]


def abs_z_from_raw(raw_p):
    """|z| implied by a two-sided p-value.

    Inverts only the standard normal tail. This does not reconstruct any
    part of Dunn's test — the p-values it consumes are scikit-posthocs'
    own output — so the resulting z remains an external reference rather
    than a re-implementation.
    """
    return [float(stats.norm.isf(p / 2.0)) for p in raw_p]


print("=" * 66)
print("EML Stats Batch 7 — Dunn's post-hoc, external verification")
print("Reference implementation: scikit-posthocs (posthoc_dunn)")
print("=" * 66)

if not HAS_SP:
    print("\nscikit-posthocs / pandas / scipy unavailable: %s" % IMPORT_ERROR)
    for i in range(EXPECTED_CHECKS):
        register_skip(
            "check %d of %d not performed (external reference implementation "
            "unavailable)" % (i + 1, EXPECTED_CHECKS)
        )
else:
    print("scikit-posthocs version: %s" % getattr(sp, "__version__", "unknown"))

    # -----------------------------------------------------------------------
    # Dunn-1 — Test Set 1, k=3
    # -----------------------------------------------------------------------
    print("\n--- Dunn-1 (Test Set 1, k=3) ---")
    d1_raw = dunn(SET1, None)
    d1_bonf = dunn(SET1, "bonferroni")
    d1_z = abs_z_from_raw(d1_raw)
    pairs3 = list(combinations([1, 2, 3], 2))

    for i, (a, b) in enumerate(pairs3):
        check("Dunn-1 |z| pair (%d,%d)" % (a, b), D1_ABS_Z[i], d1_z[i], ulp(8))
    for i, (a, b) in enumerate(pairs3):
        # Pairs 1 and 2 are 8-decimal literals; pair 3 is transcribed at
        # full double precision in the suite and is checked relative to
        # its own magnitude rather than to an absolute 8-decimal band,
        # which would be ~1e5 times its own value and therefore vacuous.
        if i == 2:
            tol = abs(D1_RAW_P[i]) * 1e-9
        else:
            tol = ulp(8)
        check("Dunn-1 raw p pair (%d,%d)" % (a, b), D1_RAW_P[i], d1_raw[i], tol)
    for i, (a, b) in enumerate(pairs3):
        check("Dunn-1 Bonferroni adj p pair (%d,%d)" % (a, b),
              D1_BONF[i], d1_bonf[i], ulp(8))

    # -----------------------------------------------------------------------
    # Dunn-3 — Test Set 3, k=4, ties and unequal group sizes
    # -----------------------------------------------------------------------
    print("\n--- Dunn-3 (Test Set 3, k=4, ties, unequal n) ---")
    d3_raw = dunn(SET3, None)
    d3_bonf = dunn(SET3, "bonferroni")
    d3_holm = dunn(SET3, "holm")
    d3_z = abs_z_from_raw(d3_raw)
    pairs4 = list(combinations([1, 2, 3, 4], 2))

    for i, (a, b) in enumerate(pairs4):
        check("Dunn-3 |z| pair (%d,%d)" % (a, b), D3_ABS_Z[i], d3_z[i], ulp(8))
    for i, (a, b) in enumerate(pairs4):
        # Pair (1,3) clamps to exactly 1.0 under Bonferroni.
        tol = EXACT_TOL if D3_BONF[i] == 1.0 else ulp(8)
        check("Dunn-3 Bonferroni adj p pair (%d,%d)" % (a, b),
              D3_BONF[i], d3_bonf[i], tol)
    for i, (a, b) in enumerate(pairs4):
        # Pair 4 (groups 2,3) is the one the R sibling must skip: doubling
        # dunn.test's one-tailed Holm output does not commute with the
        # running-max. scikit-posthocs is natively two-sided, so it is
        # checked here on the same footing as every other pair.
        check("Dunn-3 Holm adj p pair (%d,%d)" % (a, b),
              D3_HOLM[i], d3_holm[i], ulp(8))

    # -----------------------------------------------------------------------
    # Dunn-5 — Test Set 5, k=3, n=30 per group
    # -----------------------------------------------------------------------
    print("\n--- Dunn-5 (Test Set 5, k=3, n=30 each) ---")
    d5_raw = dunn(SET5, None)
    d5_bonf = dunn(SET5, "bonferroni")
    d5_z = abs_z_from_raw(d5_raw)

    for i, (a, b) in enumerate(pairs3):
        check("Dunn-5 |z| pair (%d,%d)" % (a, b), D5_ABS_Z[i], d5_z[i], ulp(8))
    for i, (a, b) in enumerate(pairs3):
        tol = EXACT_TOL if D5_BONF[i] == 1.0 else ulp(8)
        check("Dunn-5 Bonferroni adj p pair (%d,%d)" % (a, b),
              D5_BONF[i], d5_bonf[i], tol)

# ---------------------------------------------------------------------------
# Coverage assertion
# ---------------------------------------------------------------------------
# An audit tool must report its own coverage. Without this, a check
# deleted by a control-flow change reduces the count silently and the run
# still reads green.

performed = pass_count + fail_count + skipped
if performed != EXPECTED_CHECKS:
    fail_count += 1
    print(
        "  FAIL: coverage (expected %d checks to be performed, saw %d)"
        % (EXPECTED_CHECKS, performed)
    )

print("\n" + "=" * 66)
print(
    "Python Verification: %d passed, %d failed, %d skipped (of %d expected)"
    % (pass_count, fail_count, skipped, EXPECTED_CHECKS)
)
if fail_count > 0:
    print("SOME CHECKS FAILED")
elif skipped > 0:
    print("INCOMPLETE - %d check(s) skipped, 0 failed." % skipped)
    for r in skip_reasons[:5]:
        print("  * %s" % r)
    if len(skip_reasons) > 5:
        print("  * ... and %d more" % (len(skip_reasons) - 5))
    print("This run does NOT constitute verification of the skipped checks.")
else:
    print("ALL CHECKS PASSED")
print("=" * 66)

if fail_count > 0:
    sys.exit(1)
if skipped > 0:
    sys.exit(2)
sys.exit(0)
