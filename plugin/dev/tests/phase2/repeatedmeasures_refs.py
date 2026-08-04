#!/usr/bin/env python3
# ============================================================================
# EML Stats : reference values for test-repeated-measures.praat
# ============================================================================
# Version: 1.0
# Date: 4 August 2026
#
# WHAT THIS FILE IS FOR
# It is the EXTERNAL ORACLE generator for the four repeated-measures
# procedures in stats/eml-analysis.praat:
#
#     @emlExtractConditionMatrix   (row-wise complete-case reshape)
#     @emlFriedmanTest             (tie-corrected Friedman chi-square)
#     @emlGGEpsilon                (Greenhouse-Geisser sphericity epsilon)
#     @emlRMAnovaTest              (one-way RM-ANOVA, uncorrected + GG)
#
# Every literal asserted in test-repeated-measures.praat is printed here and
# was transcribed from this output. Nothing was transcribed from the EML
# library's own output (see dev/tests/REFERENCE_PROVENANCE.md).
#
# ORACLE ASSIGNMENT
#   Friedman chi-square / p   -> scipy.stats.friedmanchisquare   [EXT]
#   RM-ANOVA F / p            -> statsmodels AnovaRM             [EXT]
#   GG epsilon, GG-corrected p-> pingouin                        [EXT]
#
# The GG oracle has to come from Python. Base R's `stats` has no
# Greenhouse-Geisser routine, and neither `ez` nor `afex` is installed in
# the environment of record (CRAN is unreachable from the sandbox). The
# companion verify-repeated-measures.R therefore checks the Friedman and
# RM-ANOVA literals as [EXT] against base R, and checks the GG literals
# only [LH] against a longhand re-derivation from the covariance matrix.
# The [EXT] GG evidence is here, not there.
#
# DATASETS
# Six, spanning working and known-degenerate input as the audit requires:
#   RM_A  clean balanced k=3 n=6, no ties            (nominal path)
#   RM_B  k=4 n=5, sphericity-violating covariance   (epsilon well below 1)
#   RM_C  heavy within-row ties                      (tie-correction path)
#   RM_D  every observation identical                (0/0 -- degenerate)
#   RM_E  n=2, the minimum the reshape admits        (boundary)
#   RM_F  perfect additive data, zero residual       (F = x/0 -- degenerate)
# Plus reshape fixtures with missing cells, an unknown column name, and a
# single condition column.
#
# Usage:  python3 repeatedmeasures_refs.py
# ============================================================================

import numpy as np
import pandas as pd
from scipy import stats
from statsmodels.stats.anova import AnovaRM
import pingouin as pg

np.set_printoptions(precision=12, suppress=False)


def banner(title):
    print()
    print("=" * 72)
    print(f"  {title}")
    print("=" * 72)


def as_long(data, name="value"):
    """Wide (n x k) ndarray -> long DataFrame for AnovaRM / pingouin."""
    n, k = data.shape
    rows = []
    for i in range(n):
        for j in range(k):
            rows.append({"subject": i + 1, "condition": j + 1, name: data[i, j]})
    return pd.DataFrame(rows)


def friedman_refs(data, label):
    """[EXT] scipy.stats.friedmanchisquare + rank sums by hand."""
    n, k = data.shape
    cols = [data[:, j] for j in range(k)]
    print(f"\n-- Friedman ({label}) --")
    try:
        res = stats.friedmanchisquare(*cols)
        chi, p = res.statistic, res.pvalue
    except Exception as exc:                       # degenerate input
        chi, p = float("nan"), float("nan")
        print(f"  scipy raised: {type(exc).__name__}: {exc}")
    # rank sums: within-row average ranks, summed down each column
    ranks = np.vstack([stats.rankdata(data[i, :], method="average")
                       for i in range(n)])
    rank_sum = ranks.sum(axis=0)
    print(f"  n = {n}   k = {k}   df = {k - 1}")
    print(f"  chiSq = {chi!r}")
    print(f"  p     = {p!r}")
    for j in range(k):
        print(f"  rankSum[{j + 1}] = {rank_sum[j]!r}")
    return chi, k - 1, p, rank_sum


def gg_refs(data, label):
    """[EXT] pingouin Greenhouse-Geisser epsilon."""
    n, k = data.shape
    print(f"\n-- Greenhouse-Geisser ({label}) --")
    long = as_long(data)
    try:
        eps = pg.epsilon(long, dv="value", within="condition",
                         subject="subject", correction="gg")
        print(f"  epsilon (pingouin) = {eps!r}")
    except Exception as exc:
        eps = float("nan")
        print(f"  pingouin raised: {type(exc).__name__}: {exc}")
    print(f"  lower bound 1/(k-1)  = {1.0 / (k - 1)!r}")
    return eps


def gg_longhand(data):
    """Re-derivation from the covariance matrix, for cross-checking pingouin.

    This is the same estimator emlGGEpsilon implements, written independently
    from Greenhouse & Geisser (1959) as presented in Winer. It is NOT an
    external oracle -- it is a second opinion on the algebra.
    """
    n, k = data.shape
    s = np.cov(data, rowvar=False, ddof=1)
    dbar = np.trace(s) / k
    sbar = s.mean()
    rowmeans = s.mean(axis=1)
    num = k * k * (dbar - sbar) ** 2
    den = (k - 1) * (np.sum(s * s) - 2 * k * np.sum(rowmeans ** 2)
                     + k * k * sbar * sbar)
    if den <= 0:
        return 1.0
    return float(np.clip(num / den, 1.0 / (k - 1), 1.0))


def rmanova_refs(data, label, eps):
    """[EXT] statsmodels AnovaRM for F/df/p; GG-corrected p from eps."""
    n, k = data.shape
    print(f"\n-- RM-ANOVA ({label}) --")
    long = as_long(data)
    try:
        fit = AnovaRM(long, depvar="value", subject="subject",
                      within=["condition"]).fit()
        tbl = fit.anova_table
        f = float(tbl["F Value"].iloc[0])
        df1 = float(tbl["Num DF"].iloc[0])
        df2 = float(tbl["Den DF"].iloc[0])
        p = float(tbl["Pr > F"].iloc[0])
    except Exception as exc:
        f = df1 = df2 = p = float("nan")
        print(f"  statsmodels raised: {type(exc).__name__}: {exc}")
        df1, df2 = float(k - 1), float((k - 1) * (n - 1))
    print(f"  F      = {f!r}")
    print(f"  dfCond = {df1!r}   dfErr = {df2!r}")
    print(f"  p      = {p!r}")
    if not np.isnan(f) and not np.isnan(eps):
        p_gg = float(stats.f.sf(f, df1 * eps, df2 * eps))
        print(f"  p(GG, df scaled by epsilon) = {p_gg!r}")
    else:
        p_gg = float("nan")
        print("  p(GG) not computable")
    cond_mean = data.mean(axis=0)
    for j in range(k):
        print(f"  condMean[{j + 1}] = {cond_mean[j]!r}")
    return f, df1, df2, p, p_gg, cond_mean


def pingouin_rm(data, label):
    """Cross-check: pingouin's own GG-corrected p, computed end to end."""
    long = as_long(data)
    try:
        res = pg.rm_anova(long, dv="value", within="condition",
                          subject="subject", correction=True, detailed=False)
        print(f"\n-- pingouin rm_anova cross-check ({label}) --")
        with pd.option_context("display.width", 200,
                               "display.max_columns", 40):
            print(res.to_string(index=False))
    except Exception as exc:
        print(f"\n-- pingouin rm_anova ({label}): "
              f"{type(exc).__name__}: {exc}")


def full_report(data, label):
    banner(label)
    print("  data (rows = subjects, cols = conditions):")
    for row in data:
        print("    " + "  ".join(f"{v!r}" for v in row))
    friedman_refs(data, label)
    eps = gg_refs(data, label)
    lh = gg_longhand(data)
    print(f"  epsilon (longhand from covariance)   = {lh!r}")
    if not np.isnan(eps):
        print(f"  |pingouin - longhand|                = {abs(eps - lh)!r}")
    rmanova_refs(data, label, eps)
    pingouin_rm(data, label)


# ============================================================================
# THE DATASETS
# ============================================================================

RM_A = np.array([
    [12.0, 15.0, 19.0],
    [10.0, 14.0, 17.0],
    [13.0, 16.0, 21.0],
    [ 9.0, 12.0, 16.0],
    [11.0, 15.0, 20.0],
    [14.0, 18.0, 23.0],
], dtype=float)

RM_B = np.array([
    [ 2.0,  8.0,  3.0, 30.0],
    [ 3.0,  9.0,  5.0, 10.0],
    [ 4.0, 11.0,  4.0, 50.0],
    [ 2.0,  7.0,  6.0,  5.0],
    [ 5.0, 12.0,  3.0, 40.0],
], dtype=float)

RM_C = np.array([
    [ 5.0,  5.0,  8.0],
    [ 7.0,  7.0,  7.0],
    [ 3.0,  6.0,  6.0],
    [ 4.0,  4.0,  9.0],
    [ 6.0,  6.0,  6.0],
], dtype=float)

RM_D = np.array([
    [7.0, 7.0, 7.0],
    [7.0, 7.0, 7.0],
    [7.0, 7.0, 7.0],
    [7.0, 7.0, 7.0],
], dtype=float)

RM_E = np.array([
    [10.0, 14.0, 21.0],
    [12.0, 15.0, 19.0],
], dtype=float)

# perfectly additive: value = subject effect + condition effect, no residual
RM_F = np.array([
    [ 1.0 + 0.0,  1.0 + 5.0,  1.0 + 9.0],
    [ 4.0 + 0.0,  4.0 + 5.0,  4.0 + 9.0],
    [ 8.0 + 0.0,  8.0 + 5.0,  8.0 + 9.0],
], dtype=float)


if __name__ == "__main__":
    print("=" * 72)
    print("EML Stats — repeated-measures reference values")
    print("=" * 72)
    print(f"  numpy       {np.__version__}")
    print(f"  scipy       {stats.__name__} / {__import__('scipy').__version__}")
    print(f"  pandas      {pd.__version__}")
    print(f"  statsmodels {__import__('statsmodels').__version__}")
    print(f"  pingouin    {pg.__version__}")

    full_report(RM_A, "RM_A — clean balanced, k=3 n=6, no ties")
    full_report(RM_B, "RM_B — k=4 n=5, sphericity violated")
    full_report(RM_C, "RM_C — heavy within-row ties")
    full_report(RM_D, "RM_D — every observation identical (degenerate)")
    full_report(RM_E, "RM_E — n=2, minimum admissible")
    full_report(RM_F, "RM_F — perfectly additive, zero residual (degenerate)")

    banner("RESHAPE FIXTURES (emlExtractConditionMatrix)")
    print("""
  F1  4 rows x 3 condition columns, all cells present.
        pre  mid  post
         12   15   19
         10   14   17
         13   16   21
          9   12   16
      expect n=4  k=3  nExcluded=0  error$=""

  F2  same, but row 2 has an undefined cell in `mid`
      and row 4 has an undefined cell in `post`.
      expect n=2  k=3  nExcluded=2  error$=""
      surviving rows are the ORIGINAL rows 1 and 3, in order:
        data[1,] = 12 15 19
        data[2,] = 13 16 21

  F3  column list names a column that is not in the table.
      expect error$ = "Column not found: bogus"

  F4  column list has a single entry.
      expect error$ = "Need at least 2 condition columns."

  F5  every row has at least one undefined cell -> fewer than 2 complete.
      expect error$ = "Need at least 2 complete-case subjects "
                      "(rows with all conditions present)."

  F6  whitespace and an empty token in the column list:
        "  pre |  mid ||post  "
      expect the parser to trim and drop the empty token: k=3, no error.
""")
