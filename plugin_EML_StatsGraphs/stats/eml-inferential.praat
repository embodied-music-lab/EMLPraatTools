# ============================================================================
# EML Stats : Inferential Statistics
# ============================================================================
# Module: eml-inferential.praat
# Version: 1.7
# Date: 27 August 2026
#
# V1.7: The Spearman branch law gains its third arm, and the arm is named
#        where it is decided. R reaches the exact branch only with no ties
#        and n <= 1290; @eml_spearmanPspearman already carried that guard,
#        so the constant is not copied. The kernel now sets .method$,
#        @emlSpearmanExactP propagates it, and the dispatch reads it rather
#        than testing n again. New .methodReason$ separates why an
#        approximation was chosen ("ties" / "large sample") from what was
#        computed; the reason is derived by exhaustive dispatch, so an
#        unrecognised label refuses rather than captioning itself, and the
#        refusal reaches every existing reader. Two pins re-checked
#        against the R-4-3-3 source and found
#        already correct: the two-sided fold (tail by q vs (n^3-n)/6, then
#        min(2p, 1)) and continuity = FALSE on the asymptotic arm.
#        Fable's branch-law ruling, 27 August 2026.
#
# V1.6: New @emlSpearmanCorrelationDispatch -- the branch law (ties present
#        -> the existing t-approximation; no ties -> @emlSpearmanExactP's
#        AS 89 exact p), and the ONE call site every door now uses to reach
#        it. Neither @emlSpearmanCorrelation nor @emlSpearmanExactP is
#        touched. Wired at eml-analysis.praat's correlation orchestrator,
#        eml-correlate.praat's and eml-wizard.praat's per-group loops, and
#        the scatter's three draw-time annotation call sites in
#        eml-draw-procedures.praat (ungrouped, per-group, overall/pooled).
#        The two disclosure sentences ("exact method (AS 89)" / "t
#        approximation (ties present)") stay in Ian's language batch,
#        unapproved -- .method$ is an internal tag only, and no call site
#        gained a print.
#
# V1.5: New @emlSpearmanExactP, a statement-for-statement port of R 4.3.3's
#        prho() (src/library/stats/src/prho.c, AS 89 — Best & Roberts 1975)
#        plus the pspearman()/tail-selection dispatch that surrounds it in
#        cor.test.default (src/library/stats/R/cor.test.R), fetched from the
#        R-4-3-3 tag. Given the same rho and n that @emlSpearmanCorrelation
#        already computes, it reproduces R's default (exact) Spearman p
#        rather than the t-approximation. Does not touch the existing rho
#        computation. As of V1.6 it is wired -- see @emlSpearmanCorrelationDispatch.
#
# V1.4: @emlPairwiseT and @emlPairwiseWilcoxon now call
#        @emlRequireNumericColumn (.strict = 0) straight after the
#        @emlRequireColumnPresent check. An all-blank data column would
#        otherwise leave both with an empty error$ and a matrix of
#        undefined: no number was produced, so nothing could be misread as
#        a result, but a direct caller could not tell a refusal from a
#        computation and was told nothing about why. They now refuse in
#        @emlAuditColumn's words, the same sentence @emlTwoWayAnova gives
#        for the same column. Not reachable from the menus, where
#        @emlRunPairwiseAnalysis asks both questions first; reachable from
#        eml-lib-stats.praat, which is the supported direct-call path.
#        No change on any column that holds numbers.
#
#
# Part of the EML Stats library (EML Stats & Graphs).
# Part of EML PraatGen GPL-3.0-or-later — Ian Howell, Embodied Music Lab
#
# Provides: @emlTTest, @emlTTestPaired, @emlCohenD,
#   @emlPearsonCorrelation, @emlSpearmanCorrelation,
#   @emlTTestAlt, @emlTTestPairedAlt,
#   @emlPearsonCorrelationAlt, @emlSpearmanCorrelationAlt,
#   @emlSpearmanExactP, @emlSpearmanCorrelationDispatch,
#   @emlMannWhitneyU, @emlWilcoxonSignedRank,
#   @emlRankBiserialR, @emlMatchedPairsR,
#   @emlBonferroni, @emlHolm, @emlBenjaminiHochberg,
#   @emlTableFromGroups, @emlOneWayAnova, @emlTwoWayAnova, @emlTukeyHSD,
#   @emlEpsilonSquared, @emlKruskalWallis, @emlDunnTest,
#   @emlPairwiseT, @emlPairwiseWilcoxon, @emlScheffe,
#   @emlBrownForsythe, @emlWelchAnova, @emlGamesHowell
#
# Dependencies:
#   @emlSpearmanCorrelation requires @emlRankVector from
#   eml-core-utilities.praat. The calling script must include
#   utilities before inferential:
#     include eml-core-utilities.praat
#     include eml-inferential.praat
#
#   @emlTukeyHSD (v0.9+) requires @emlCountGroups, @eml_getGroupData from
#   eml-extract.praat. The calling script must include extract
#   before inferential:
#     include eml-extract.praat
#     include eml-inferential.praat
#
# All procedures use the "eml" prefix (EML Stats) to avoid
# namespace collisions with user scripts.
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


# ============================================================================
# @emlTTest
# ============================================================================
# Independent-samples t-test (Welch default, Student optional).
#
# Welch's t-test does not assume equal variances and is the modern
# default. Student's pooled-variance t-test is available via the
# .equalVariances parameter for cases where equal variances are
# justified and the pooled estimate is desired.
#
# Arguments:
#   .v1#             - numeric vector, group 1
#   .v2#             - numeric vector, group 2
#   .tails           - 1 (one-tailed) or 2 (two-tailed)
#   .equalVariances  - 0 = Welch (default), 1 = Student (pooled)
#
# Output:
#   .t          - t statistic (positive when mean1 > mean2)
#   .df         - degrees of freedom (fractional for Welch)
#   .p          - p-value for the requested alternative
#   .pGreater   - one-tailed p for H1: mean1 > mean2
#   .pLess      - one-tailed p for H1: mean1 < mean2
#   .alternative$ - "two-sided" or "greater" (the alternative .p refers to)
#   .mean1      - mean of group 1
#   .mean2      - mean of group 2
#   .sd1        - SD of group 1
#   .sd2        - SD of group 2
#   .n1         - size of group 1
#   .n2         - size of group 2
#   .meanDiff   - mean1 - mean2
#   .method$    - "Welch" or "Student"
#   .error$     - error message, or "" if valid
#
# One-tailed p (.tails = 1): the alternative is FIXED as H1: mean1 >
#   mean2, matching R's t.test(v1, v2, alternative = "greater") and
#   matching what .tails = 1 means in @emlMannWhitneyU and
#   @emlWilcoxonSignedRank. A one-tailed test run in the wrong
#   direction therefore returns a p-value near 1, not near 0. For the
#   opposite alternative, read .pLess (or swap the arguments).
#
#   .tails counts tails and nothing else: it cannot say WHICH one-sided
#   alternative is meant, and (v1, v2) and (v2, v1) return p and 1 - p.
#   @emlTTestAlt names the alternative in words ("two-sided",
#   "greater", "less") and cannot be misread; prefer it in new code.
# ============================================================================

procedure emlTTest: .v1#, .v2#, .tails, .equalVariances
    # Initialize outputs
    .t = undefined
    .df = undefined
    .p = undefined
    .pGreater = undefined
    .pLess = undefined
    .alternative$ = ""
    .mean1 = undefined
    .mean2 = undefined
    .sd1 = undefined
    .sd2 = undefined
    .meanDiff = undefined
    .method$ = ""
    .error$ = ""

    .n1 = size (.v1#)
    .n2 = size (.v2#)

    # --- Input validation ---
    if .n1 < 2 or .n2 < 2
        .error$ = "Each group must have at least 2 observations"
    elsif .tails < 1 or .tails > 2
        .error$ = "tails must be 1 or 2"
    else
        # --- Compute group statistics ---
        .mean1 = mean (.v1#)
        .mean2 = mean (.v2#)
        .sd1 = stdev (.v1#)
        .sd2 = stdev (.v2#)
        .meanDiff = .mean1 - .mean2
        .var1 = .sd1 * .sd1
        .var2 = .sd2 * .sd2

        # Check for zero variance in both groups
        if .var1 = 0 and .var2 = 0
            .error$ = "Both groups have zero variance"
        else
            if .equalVariances = 1
                # --- Student's t-test (pooled variance) ---
                .method$ = "Student"
                .df = .n1 + .n2 - 2
                .pooledVar = ((.n1 - 1) * .var1 + (.n2 - 1) * .var2) / .df
                .se = sqrt (.pooledVar * (1 / .n1 + 1 / .n2))
                .t = .meanDiff / .se
            else
                # --- Welch's t-test (default) ---
                .method$ = "Welch"
                .vn1 = .var1 / .n1
                .vn2 = .var2 / .n2
                .se = sqrt (.vn1 + .vn2)
                .t = .meanDiff / .se

                # Welch-Satterthwaite degrees of freedom
                .numerator = (.vn1 + .vn2) * (.vn1 + .vn2)
                .denom1 = (.vn1 * .vn1) / (.n1 - 1)
                .denom2 = (.vn2 * .vn2) / (.n2 - 1)
                .df = .numerator / (.denom1 + .denom2)
            endif

            # --- p-value ---
            # studentQ is the SIGNED upper tail P(T >= t) on 6.6.30:
            # studentQ(2.5298, 7.6) = 0.01836, studentQ(-2.5298, 7.6) =
            # 0.98164, studentQ(0, df) = 0.5. So the "greater" tail is
            # studentQ of the SIGNED t, and the "less" tail is studentQ
            # of its negation. pLess is NOT computed as 1 - pGreater:
            # that subtraction loses every significant digit of a small
            # right tail (1 - 1e-17 is exactly 1 in a double).
            .pGreater = studentQ (.t, .df)
            .pLess = studentQ (- .t, .df)
            if .tails = 2
                .alternative$ = "two-sided"
                .absT = abs (.t)
                .p = 2 * studentQ (.absT, .df)
            else
                # One-tailed: fixed alternative H1 mean1 > mean2
                .alternative$ = "greater"
                .p = .pGreater
            endif
        endif
    endif
endproc


# ============================================================================
# @emlTTestAlt
# ============================================================================
# @emlTTest with the alternative named in words rather than counted in
# tails. Praat cannot overload a procedure and cannot add an argument
# to @emlTTest without breaking every existing call site at once, so
# the explicit form is a separate entry point onto the same kernel.
#
# Arguments:
#   .v1#            - numeric vector, group 1
#   .v2#            - numeric vector, group 2
#   .alternative$   - "two-sided", "greater" (H1: mean1 > mean2) or
#                     "less" (H1: mean1 < mean2). Nothing else.
#   .equalVariances - 0 = Welch (default), 1 = Student (pooled)
#
# Output: the same fields as @emlTTest. .p is the p for the named
#   alternative; .alternative$ echoes the name it was given. An
#   unrecognised alternative sets .error$ and leaves every numeric
#   output undefined — it is not silently treated as two-sided.
# ============================================================================

procedure emlTTestAlt: .v1#, .v2#, .alternative$, .equalVariances
    .requested$ = .alternative$

    # Initialize outputs
    .t = undefined
    .df = undefined
    .p = undefined
    .pGreater = undefined
    .pLess = undefined
    .alternative$ = ""
    .mean1 = undefined
    .mean2 = undefined
    .sd1 = undefined
    .sd2 = undefined
    .meanDiff = undefined
    .n1 = undefined
    .n2 = undefined
    .method$ = ""
    .error$ = ""

    .tails = 0
    if .requested$ = "two-sided"
        .tails = 2
    elsif .requested$ = "greater"
        .tails = 1
    elsif .requested$ = "less"
        .tails = 1
    endif

    if .tails = 0
        .error$ = "alternative$ must be ""two-sided"", ""greater"" or ""less"""
    else
        @emlTTest: .v1#, .v2#, .tails, .equalVariances
        if emlTTest.error$ <> ""
            .error$ = emlTTest.error$
        else
            .t = emlTTest.t
            .df = emlTTest.df
            .pGreater = emlTTest.pGreater
            .pLess = emlTTest.pLess
            .mean1 = emlTTest.mean1
            .mean2 = emlTTest.mean2
            .sd1 = emlTTest.sd1
            .sd2 = emlTTest.sd2
            .meanDiff = emlTTest.meanDiff
            .n1 = emlTTest.n1
            .n2 = emlTTest.n2
            .method$ = emlTTest.method$
        endif
        .error$ = emlTTest.error$

        if .error$ = ""
            .alternative$ = .requested$
            if .requested$ = "less"
                .p = .pLess
            else
                # "two-sided" and "greater" are what the kernel already
                # selected for .tails = 2 and .tails = 1 respectively.
                .p = emlTTest.p
            endif
        endif
    endif
endproc


# ============================================================================
# @emlTTestPaired
# ============================================================================
# Paired-samples t-test.
#
# Computes within-subject differences (v1 - v2) and tests whether the
# mean difference differs from zero.
#
# Arguments:
#   .v1#   - numeric vector, condition 1
#   .v2#   - numeric vector, condition 2 (same length as v1#)
#   .tails - 1 (one-tailed) or 2 (two-tailed)
#
# Output:
#   .t        - t statistic
#   .df       - degrees of freedom (n - 1)
#   .p        - p-value for the requested alternative
#   .pGreater - one-tailed p for H1: v1 > v2
#   .pLess    - one-tailed p for H1: v1 < v2
#   .alternative$ - "two-sided" or "greater" (the alternative .p refers to)
#   .meanDiff - mean of differences (v1 - v2)
#   .sdDiff   - SD of differences
#   .seDiff   - standard error of the mean difference
#   .n        - number of pairs
#   .error$   - error message, or "" if valid
#
# One-tailed p (.tails = 1): the alternative is FIXED as H1: v1 > v2,
#   matching R's t.test(v1, v2, paired = TRUE, alternative =
#   "greater") and matching what .tails = 1 means in
#   @emlWilcoxonSignedRank. A one-tailed test run in the wrong
#   direction therefore returns a p-value near 1, not near 0. For the
#   opposite alternative, read .pLess (or swap the arguments).
#
#   .tails counts tails and nothing else: it cannot say WHICH one-sided
#   alternative is meant, and (v1, v2) and (v2, v1) return p and 1 - p.
#   @emlTTestPairedAlt names the alternative in words; prefer it in new
#   code.
# ============================================================================

procedure emlTTestPaired: .v1#, .v2#, .tails
    # Initialize outputs
    .t = undefined
    .df = undefined
    .p = undefined
    .pGreater = undefined
    .pLess = undefined
    .alternative$ = ""
    .meanDiff = undefined
    .sdDiff = undefined
    .seDiff = undefined
    .error$ = ""

    .n1 = size (.v1#)
    .n2 = size (.v2#)
    .n = .n1

    # --- Input validation ---
    if .n1 <> .n2
        .error$ = "Vectors must have equal length for paired test"
        .n = 0
    elsif .n < 2
        .error$ = "Need at least 2 pairs"
    elsif .tails < 1 or .tails > 2
        .error$ = "tails must be 1 or 2"
    else
        # --- Compute differences ---
        .diffs# = zero# (.n)
        for .i from 1 to .n
            .diffs#[.i] = .v1#[.i] - .v2#[.i]
        endfor

        .meanDiff = mean (.diffs#)
        .sdDiff = stdev (.diffs#)

        if .sdDiff = 0
            .error$ = "All differences are identical (zero variance)"
        else
            .seDiff = .sdDiff / sqrt (.n)
            .df = .n - 1
            .t = .meanDiff / .seDiff

            # --- p-value ---
            # studentQ is the SIGNED upper tail P(T >= t), so the
            # "greater" tail takes the signed t. .pLess is studentQ of
            # the negated t and NOT 1 - .pGreater: the subtraction
            # destroys a small right tail entirely.
            .pGreater = studentQ (.t, .df)
            .pLess = studentQ (- .t, .df)
            if .tails = 2
                .alternative$ = "two-sided"
                .absT = abs (.t)
                .p = 2 * studentQ (.absT, .df)
            else
                # One-tailed: fixed alternative H1 v1 > v2
                .alternative$ = "greater"
                .p = .pGreater
            endif
        endif
    endif
endproc


# ============================================================================
# @emlTTestPairedAlt
# ============================================================================
# @emlTTestPaired with the alternative named in words. See the note on
# @emlTTestAlt for why this is a separate entry point rather than an
# extra argument.
#
# Arguments:
#   .v1#          - numeric vector, condition 1
#   .v2#          - numeric vector, condition 2 (same length as v1#)
#   .alternative$ - "two-sided", "greater" (H1: v1 > v2) or "less"
#                   (H1: v1 < v2). Nothing else.
#
# Output: the same fields as @emlTTestPaired. An unrecognised
#   alternative sets .error$ and leaves every numeric output undefined.
# ============================================================================

procedure emlTTestPairedAlt: .v1#, .v2#, .alternative$
    .requested$ = .alternative$

    # Initialize outputs
    .t = undefined
    .df = undefined
    .p = undefined
    .pGreater = undefined
    .pLess = undefined
    .alternative$ = ""
    .meanDiff = undefined
    .sdDiff = undefined
    .seDiff = undefined
    .n = undefined
    .error$ = ""

    .tails = 0
    if .requested$ = "two-sided"
        .tails = 2
    elsif .requested$ = "greater"
        .tails = 1
    elsif .requested$ = "less"
        .tails = 1
    endif

    if .tails = 0
        .error$ = "alternative$ must be ""two-sided"", ""greater"" or ""less"""
    else
        @emlTTestPaired: .v1#, .v2#, .tails
        .error$ = emlTTestPaired.error$

        if .error$ = ""
            .t = emlTTestPaired.t
            .df = emlTTestPaired.df
            .pGreater = emlTTestPaired.pGreater
            .pLess = emlTTestPaired.pLess
            .meanDiff = emlTTestPaired.meanDiff
            .sdDiff = emlTTestPaired.sdDiff
            .seDiff = emlTTestPaired.seDiff
            .n = emlTTestPaired.n
            .alternative$ = .requested$
            if .requested$ = "less"
                .p = .pLess
            else
                .p = emlTTestPaired.p
            endif
        endif
    endif
endproc


# ============================================================================
# @emlCohenD
# ============================================================================
# Cohen's d and Hedges' g for independent samples.
#
# Cohen's d uses the pooled standard deviation as the standardizer.
# Hedges' g applies a correction factor J for small-sample bias.
#
# The correction factor is the exact form (Hedges, 1981):
#   J = exp(lnGamma(df/2) - 0.5*ln(df/2) - lnGamma((df-1)/2))
# where df = n1 + n2 - 2. Agrees with effectsize::hedges_g.
#
# Arguments:
#   .v1# - numeric vector, group 1
#   .v2# - numeric vector, group 2
#
# Output:
#   .d                - Cohen's d (positive when mean1 > mean2)
#   .g                - Hedges' g (bias-corrected d)
#   .pooledSD         - pooled standard deviation
#   .correctionFactor - J (Hedges' correction; multiply d by J to get g)
#   .mean1            - mean of group 1
#   .mean2            - mean of group 2
#   .n1               - size of group 1
#   .n2               - size of group 2
#   .error$           - error message, or "" if valid
# ============================================================================

procedure emlCohenD: .v1#, .v2#
    # Initialize outputs
    .d = undefined
    .g = undefined
    .pooledSD = undefined
    .correctionFactor = undefined
    .mean1 = undefined
    .mean2 = undefined
    .error$ = ""

    .n1 = size (.v1#)
    .n2 = size (.v2#)

    # --- Input validation ---
    if .n1 < 2 or .n2 < 2
        .error$ = "Each group must have at least 2 observations"
    else
        .mean1 = mean (.v1#)
        .mean2 = mean (.v2#)
        .sd1 = stdev (.v1#)
        .sd2 = stdev (.v2#)
        .var1 = .sd1 * .sd1
        .var2 = .sd2 * .sd2

        # Pooled standard deviation
        .df = .n1 + .n2 - 2
        .pooledVar = ((.n1 - 1) * .var1 + (.n2 - 1) * .var2) / .df
        .pooledSD = sqrt (.pooledVar)

        if .pooledSD = 0
            .error$ = "Pooled SD is zero (no variance in either group)"
        else
            # Cohen's d
            .d = (.mean1 - .mean2) / .pooledSD

            # Hedges' g correction factor, exact form (Hedges, 1981):
            # J = exp(lnGamma(df/2) - 0.5*ln(df/2) - lnGamma((df-1)/2))
            .correctionFactor = exp(lnGamma(.df / 2) - 0.5 * ln(.df / 2) - lnGamma((.df - 1) / 2))
            .g = .d * .correctionFactor
        endif
    endif
endproc


# ============================================================================
# @emlTTestInterval
# ============================================================================
# Confidence interval for a t-test mean difference, at whatever degrees
# of freedom the CALLING VARIANT already computed. Never recomputes the
# df: @emlTTest.df is Welch-Satterthwaite or pooled n1 + n2 - 2
# depending on how the caller ran it, and @emlTTestPaired.df is n - 1.
# Welch and Student take different degrees of freedom, and an interval
# built on the wrong one looks entirely plausible -- there is no wrong
# answer here that looks wrong, which is why the df is taken as an
# argument rather than derived.
#
# SE is recovered as .meanDiff / .t. That recovers the calling variant's
# OWN standard error -- Welch's or Student's, automatically, because
# .t was computed as .meanDiff / SE by that same variant. Nothing here
# recomputes an SE a second way.
#
# Follows @emlCI's guard shape (@emlDescriptive, stats/eml-core-
# descriptive.praat): a degenerate input sets every numeric output to
# undefined and .error$ to a message, and invStudentQ is reached only
# on the clean path. invStudentQ (0, df) never converges -- it hangs
# the script with no error -- so this guards .t = 0 (no SE can be
# recovered from a zero t: .meanDiff / 0) and .df = undefined (nothing
# to build a Student distribution on) BEFORE the call, not after, and
# invStudentQ (0, df) is never reached from here under any input.
#
# Arguments:
#   .meanDiff - the mean difference the calling test reported
#   .t        - that same test's t statistic
#   .df       - that same test's own degrees of freedom (not recomputed)
#   .level    - confidence level as a proportion (e.g. 0.95, or a
#               correction's own level such as 1 - alpha/m)
#
# Output:
#   .low, .high - interval bounds, or undefined on refusal
#   .error$     - "" when computed, else why not
# ============================================================================

procedure emlTTestInterval: .meanDiff, .t, .df, .level
    .low = undefined
    .high = undefined
    .error$ = ""

    if .t = 0
        .error$ = "Cannot recover a standard error from t = 0"
    elsif .df = undefined
        .error$ = "Degrees of freedom are undefined"
    else
        .se = .meanDiff / .t
        .tCrit = invStudentQ ((1 - .level) / 2, .df)
        .halfWidth = abs (.tCrit) * .se
        .low = .meanDiff - .halfWidth
        .high = .meanDiff + .halfWidth
    endif
endproc


# ============================================================================
# @emlPearsonCorrelation
# ============================================================================
# Pearson product-moment correlation coefficient.
#
# Computes r, converts to t statistic for significance testing.
# Formula: t = r * sqrt((n-2) / (1 - r^2))
#
# For perfect correlations (|r| = 1), t is undefined (division by
# zero). In this case, p is set to 0.
#
# Arguments:
#   .x#    - numeric vector, variable 1
#   .y#    - numeric vector, variable 2 (same length as x#)
#   .tails - 1 (one-tailed) or 2 (two-tailed)
#
# Output:
#   .r      - Pearson correlation coefficient
#   .t      - t statistic
#   .df     - degrees of freedom (n - 2)
#   .p      - p-value for the requested alternative
#   .pGreater - one-tailed p for H1: r > 0 (positive association)
#   .pLess    - one-tailed p for H1: r < 0 (negative association)
#   .alternative$ - "two-sided" or "greater" (the alternative .p refers to)
#   .n      - number of pairs
#   .error$ - error message, or "" if valid
#   .warning$ - non-fatal disclosure, or "" if none
#   .perfect  - 1 if |r| = 1 (t undefined), 0 otherwise
#
# One-tailed p (.tails = 1): the alternative is FIXED as H1: r > 0,
#   matching R's cor.test(x, y, alternative = "greater"). The SIGN of
#   the correlation drives the tail, not its magnitude, so a one-tailed
#   test run in the wrong direction returns a p-value near 1, not near
#   0. For the opposite alternative, read .pLess (or negate one
#   variable).
#
#   .tails counts tails and nothing else: it cannot say WHICH one-sided
#   alternative is meant, and r = +0.96 and r = -0.96 return p and
#   1 - p. @emlPearsonCorrelationAlt / @emlSpearmanCorrelationAlt name
#   the alternative in words; prefer them in new code.
# ============================================================================

# ----------------------------------------------------------------------------
# @eml_pearsonCore  (internal)
# ----------------------------------------------------------------------------
# Shared computation kernel for Pearson r and for Spearman rho (which
# is Pearson r on ranks). Factored out so that @emlSpearmanCorrelation
# does NOT call @emlPearsonCorrelation and therefore cannot overwrite
# the caller-visible emlPearsonCorrelation.* output namespace.
#
# Spearman reaches this kernel with the RANKS substituted for the raw
# values, so the sign of rho is the sign of the rank correlation and
# the directional tails below are the directional tails of rho. No
# separate direction handling is needed on that path.
#
# Output: .r .t .df .p .pGreater .pLess .alternative$ .n .error$
#         .warning$ .perfect
# ----------------------------------------------------------------------------

procedure eml_pearsonCore: .x#, .y#, .tails
    .r = undefined
    .t = undefined
    .df = undefined
    .p = undefined
    .pGreater = undefined
    .pLess = undefined
    .alternative$ = ""
    .error$ = ""
    .warning$ = ""
    .perfect = 0

    .nx = size (.x#)
    .ny = size (.y#)
    .n = .nx

    # --- Input validation ---
    if .nx <> .ny
        .error$ = "Vectors must have equal length"
        .n = 0
    elsif .n < 3
        .error$ = "Need at least 3 pairs for correlation"
    elsif .tails < 1 or .tails > 2
        .error$ = "tails must be 1 or 2"
    else
        # --- Compute Pearson r ---
        .meanX = mean (.x#)
        .meanY = mean (.y#)
        .sumXY = 0
        .sumX2 = 0
        .sumY2 = 0

        for .i from 1 to .n
            .dx = .x#[.i] - .meanX
            .dy = .y#[.i] - .meanY
            .sumXY = .sumXY + .dx * .dy
            .sumX2 = .sumX2 + .dx * .dx
            .sumY2 = .sumY2 + .dy * .dy
        endfor

        # Check for zero variance
        if .sumX2 = 0 or .sumY2 = 0
            .error$ = "One or both variables have zero variance"
        else
            .r = .sumXY / sqrt (.sumX2 * .sumY2)
            .df = .n - 2

            # --- t statistic and p-value ---
            .rSquared = .r * .r
            if .rSquared >= 1
                # Perfect correlation — t is infinite (not a number).
                # p is 0 in the limit; the undefined t must be
                # disclosed by the report layer, not printed.
                #
                # The directional tails cannot be taken from studentQ
                # here because t is not a number, so they are written
                # out at their limits, and which limit is which is
                # decided by the SIGN of r. r = +1 puts all the mass in
                # the upper tail (pGreater 0, pLess 1); r = -1 is the
                # mirror. The wrong-direction perfect effect is
                # therefore p = 1 exactly — not 0, and not undefined.
                .t = undefined
                .p = 0
                .perfect = 1
                if .r > 0
                    .pGreater = 0
                    .pLess = 1
                else
                    .pGreater = 1
                    .pLess = 0
                endif
                if .tails = 2
                    .alternative$ = "two-sided"
                else
                    .alternative$ = "greater"
                    .p = .pGreater
                endif
                .warning$ = "Perfect correlation (|r| = 1): t is infinite and is reported as undefined; p is 0 in the limit"
            else
                .t = .r * sqrt (.df / (1 - .rSquared))
                # studentQ is the SIGNED upper tail P(T >= t), and t
                # carries the sign of r, so the sign of the correlation
                # — not its magnitude — drives the tail. .pLess is
                # studentQ of the negated t, never 1 - .pGreater.
                .pGreater = studentQ (.t, .df)
                .pLess = studentQ (- .t, .df)
                if .tails = 2
                    .alternative$ = "two-sided"
                    .absT = abs (.t)
                    .p = 2 * studentQ (.absT, .df)
                else
                    # One-tailed: fixed alternative H1 r > 0
                    .alternative$ = "greater"
                    .p = .pGreater
                endif
            endif
        endif
    endif
endproc


procedure emlPearsonCorrelation: .x#, .y#, .tails
    ; Initialise every numeric output to undefined before the guard, matching
    ; the sibling entry points @emlPearsonCorrelationAlt and
    ; @emlSpearmanCorrelation, which already do this. Without it, a caller
    ; that reads .r on an error path (e.g. zero variance) before this
    ; procedure has ever succeeded once in the running script reads an
    ; unassigned variable, and Praat aborts the whole script instead of
    ; letting the caller's own .error$ guard handle the refusal.
    .r = undefined
    .t = undefined
    .df = undefined
    .p = undefined
    .pGreater = undefined
    .pLess = undefined
    .alternative$ = ""
    .n = undefined
    .warning$ = ""
    .perfect = 0
    @eml_pearsonCore: .x#, .y#, .tails
    .error$ = eml_pearsonCore.error$
    if .error$ = ""
        .r = eml_pearsonCore.r
        .t = eml_pearsonCore.t
        .df = eml_pearsonCore.df
        .p = eml_pearsonCore.p
        .pGreater = eml_pearsonCore.pGreater
        .pLess = eml_pearsonCore.pLess
        .alternative$ = eml_pearsonCore.alternative$
        .n = eml_pearsonCore.n
        .warning$ = eml_pearsonCore.warning$
        .perfect = eml_pearsonCore.perfect
    endif
endproc


# ============================================================================
# @emlPearsonCorrelationAlt
# ============================================================================
# @emlPearsonCorrelation with the alternative named in words. See the
# note on @emlTTestAlt for why this is a separate entry point.
#
# Arguments:
#   .x#           - numeric vector, variable 1
#   .y#           - numeric vector, variable 2 (same length as x#)
#   .alternative$ - "two-sided", "greater" (H1: r > 0) or "less"
#                   (H1: r < 0). Nothing else.
#
# Output: the same fields as @emlPearsonCorrelation. An unrecognised
#   alternative sets .error$ and leaves every numeric output undefined.
# ============================================================================

procedure emlPearsonCorrelationAlt: .x#, .y#, .alternative$
    .requested$ = .alternative$

    .r = undefined
    .t = undefined
    .df = undefined
    .p = undefined
    .pGreater = undefined
    .pLess = undefined
    .alternative$ = ""
    .n = undefined
    .error$ = ""
    .warning$ = ""
    .perfect = 0

    .tails = 0
    if .requested$ = "two-sided"
        .tails = 2
    elsif .requested$ = "greater"
        .tails = 1
    elsif .requested$ = "less"
        .tails = 1
    endif

    if .tails = 0
        .error$ = "alternative$ must be ""two-sided"", ""greater"" or ""less"""
    else
        @eml_pearsonCore: .x#, .y#, .tails
        .r = eml_pearsonCore.r
        .t = eml_pearsonCore.t
        .df = eml_pearsonCore.df
        .pGreater = eml_pearsonCore.pGreater
        .pLess = eml_pearsonCore.pLess
        .n = eml_pearsonCore.n
        .error$ = eml_pearsonCore.error$
        .warning$ = eml_pearsonCore.warning$
        .perfect = eml_pearsonCore.perfect

        if .error$ = ""
            .alternative$ = .requested$
            if .requested$ = "less"
                .p = .pLess
            else
                .p = eml_pearsonCore.p
            endif
        endif
    endif
endproc


# ============================================================================
# @emlSpearmanCorrelation
# ============================================================================
# Spearman rank-order correlation coefficient.
#
# Ranks both variables using @emlRankVector (with average tie handling),
# then computes Pearson r on the ranks. This is mathematically
# equivalent to the standard Spearman formula and handles ties
# correctly (unlike the simplified 1 - 6*sum(d^2)/(n*(n^2-1)) formula
# which assumes no ties).
#
# DEPENDENCY: Requires @emlRankVector from eml-core-utilities.praat.
# The calling script must include utilities before inferential.
#
# Arguments:
#   .x#    - numeric vector, variable 1
#   .y#    - numeric vector, variable 2 (same length as x#)
#   .tails - 1 (one-tailed) or 2 (two-tailed)
#
# Output:
#   .rho    - Spearman correlation coefficient
#   .t      - t statistic (same conversion as Pearson)
#   .df     - degrees of freedom (n - 2)
#   .p      - p-value for the requested alternative
#   .pGreater - one-tailed p for H1: rho > 0
#   .pLess    - one-tailed p for H1: rho < 0
#   .alternative$ - "two-sided" or "greater" (the alternative .p refers to)
#   .n      - number of pairs
#   .error$ - error message, or "" if valid
#   .warning$ - non-fatal disclosure, or "" if none
#   .perfect  - 1 if |rho| = 1 (t undefined), 0 otherwise
#
# One-tailed p (.tails = 1): the alternative is FIXED as H1: rho > 0.
#   The SIGN of the rank correlation drives the tail, not its
#   magnitude, so a one-tailed test run in the wrong direction returns
#   a p-value near 1, not near 0. For the opposite alternative, read
#   .pLess (or negate one variable).
#
#   .tails counts tails and nothing else and cannot say WHICH one-sided
#   alternative is meant — see the note in @emlPearsonCorrelation's
#   header, which shares this kernel. @emlSpearmanCorrelationAlt names
#   the alternative in words; prefer it in new code.
# ============================================================================

procedure emlSpearmanCorrelation: .x#, .y#, .tails
    # Initialize outputs
    .rho = undefined
    .t = undefined
    .df = undefined
    .p = undefined
    .pGreater = undefined
    .pLess = undefined
    .alternative$ = ""
    .error$ = ""
    .warning$ = ""
    .perfect = 0

    .nx = size (.x#)
    .ny = size (.y#)
    .n = .nx

    # --- Input validation ---
    if .nx <> .ny
        .error$ = "Vectors must have equal length"
        .n = 0
    elsif .n < 3
        .error$ = "Need at least 3 pairs for correlation"
    elsif .tails < 1 or .tails > 2
        .error$ = "tails must be 1 or 2"
    else
        # --- Rank both variables ---
        @emlRankVector: .x#
        .ranksX# = emlRankVector.ranks#

        @emlRankVector: .y#
        .ranksY# = emlRankVector.ranks#

        # --- Compute Pearson r on ranks ---
        # Calls the shared kernel, NOT @emlPearsonCorrelation, so that
        # a caller's emlPearsonCorrelation.* results survive this call.
        @eml_pearsonCore: .ranksX#, .ranksY#, .tails
        if eml_pearsonCore.error$ <> ""
            .error$ = eml_pearsonCore.error$
        else
            .rho = eml_pearsonCore.r
            .t = eml_pearsonCore.t
            .df = eml_pearsonCore.df
            .p = eml_pearsonCore.p
            .pGreater = eml_pearsonCore.pGreater
            .pLess = eml_pearsonCore.pLess
            .alternative$ = eml_pearsonCore.alternative$
            .warning$ = eml_pearsonCore.warning$
            .perfect = eml_pearsonCore.perfect
        endif
    endif
endproc


# ============================================================================
# @emlSpearmanCorrelationAlt
# ============================================================================
# @emlSpearmanCorrelation with the alternative named in words. See the
# note on @emlTTestAlt for why this is a separate entry point.
#
# Arguments:
#   .x#           - numeric vector, variable 1
#   .y#           - numeric vector, variable 2 (same length as x#)
#   .alternative$ - "two-sided", "greater" (H1: rho > 0) or "less"
#                   (H1: rho < 0). Nothing else.
#
# Output: the same fields as @emlSpearmanCorrelation. An unrecognised
#   alternative sets .error$ and leaves every numeric output undefined.
# ============================================================================

procedure emlSpearmanCorrelationAlt: .x#, .y#, .alternative$
    .requested$ = .alternative$

    .rho = undefined
    .t = undefined
    .df = undefined
    .p = undefined
    .pGreater = undefined
    .pLess = undefined
    .alternative$ = ""
    .n = undefined
    .error$ = ""
    .warning$ = ""
    .perfect = 0

    .tails = 0
    if .requested$ = "two-sided"
        .tails = 2
    elsif .requested$ = "greater"
        .tails = 1
    elsif .requested$ = "less"
        .tails = 1
    endif

    if .tails = 0
        .error$ = "alternative$ must be ""two-sided"", ""greater"" or ""less"""
    else
        @emlSpearmanCorrelation: .x#, .y#, .tails
        .rho = emlSpearmanCorrelation.rho
        .t = emlSpearmanCorrelation.t
        .df = emlSpearmanCorrelation.df
        .pGreater = emlSpearmanCorrelation.pGreater
        .pLess = emlSpearmanCorrelation.pLess
        .n = emlSpearmanCorrelation.n
        .error$ = emlSpearmanCorrelation.error$
        .warning$ = emlSpearmanCorrelation.warning$
        .perfect = emlSpearmanCorrelation.perfect

        if .error$ = ""
            .alternative$ = .requested$
            if .requested$ = "less"
                .p = .pLess
            else
                .p = emlSpearmanCorrelation.p
            endif
        endif
    endif
endproc


# ============================================================================
# INTERNAL HELPER: @eml_prho — R's prho() (AS 89), ported
# ============================================================================
# A statement-for-statement port of R 4.3.3's C routine `prho`,
# src/library/stats/src/prho.c, itself AS 89 (Best & Roberts, Appl.
# Statist. (1975) Vol. 24, No. 3, p. 377). Read from
# https://github.com/wch/r-source/blob/tags/R-4-3-3/src/library/stats/src/prho.c
# on 27 August 2026 -- that mirror's `tags/R-4-3-3`, not trunk, is a
# read of the exact release this container's installed R (4.3.3) is
# built from, per item 3's finding that trunk had drifted from the
# installed oracle for a sibling routine (wilcox.test.R's digits.rank
# default). `Rscript -e 'print(stats:::C_pRho)'` confirms the compiled
# routine this container's R actually calls is this same file's `pRho`
# SEXP wrapper, and the whole port was checked, call for call, against
# that installed routine directly (`.Call(stats:::C_pRho, is, n,
# lower)`) -- not only against cor.test()'s reported p -- across
# n = 2..2000, is at and around every branch boundary, and both
# lower_tail values: 508 cases, max |difference| 5.6e-16 (double
# rounding noise).
#
# Evaluates Pr[S >= is] when .lowerTail = 0, or Pr[S < is] when
# .lowerTail = 1, where S = (n^3 - n) * (1 - R) / 6 is Spearman's
# statistic (R the random variable; is = (n^3 - n) * (1 - r) / 6 for
# an observed r). n_small = 9 in R's source: 2 <= n <= 9 is evaluated
# by exact enumeration of all n! permutations (the same recurrence AS
# 89 gives; it is not a distribution any faster method here would
# replace, since this is the only place this plugin needs the exact
# S null distribution and it is cheap to call once per test), n > 9 by
# the Edgeworth series AS 89 gives for the tail. Both branches, and the
# is <= 0 / is > n3 short-circuits ahead of them, are ported as R has
# them -- nothing is simplified, reordered, or special-cased beyond
# what the C already does, with one exception, noted where it happens:
# Praat's exp() returns undefined on overflow instead of the C double's
# +Inf, which the Edgeworth branch's own arithmetic depends on staying
# finite-valued at extreme x. That single guard is the only place this
# port adds anything prho.c does not have; it exists to give Praat's
# arithmetic the same behaviour C's already has, not to change what
# the formula computes.
#
# n <= 9 is slow by construction (AS 89's own algorithm, not this
# port): n = 9 enumerates 362880 permutations and took ~10 s measured
# on this container's Praat 6.6.30. A caller driving many n <= 9 exact
# cases in one run should expect that; no cache is built here because
# nothing in this plugin calls this helper more than once per test (unlike
# @eml_mannWhitneyExactP and @eml_wilcoxonExactP's DP tables, which the
# Hodges-Lehmann interval procedures re-read for the same n).
#
# Input:
#   .n        - sample size, integer, matching R's `n` (caller guarantees
#               n >= 2; the n <= 1 branch is ported for completeness --
#               @emlSpearmanCorrelation already refuses n < 3 before any
#               caller can reach this helper)
#   .is       - the observed-or-shifted S value the tail is evaluated at
#               (R's `is`; may be non-integer only through the caller's
#               own rounding/offset, matching R's C signature which takes
#               a double)
#   .lowerTail - 1 for Pr[S < is], 0 for Pr[S >= is] (R's `lower_tail`)
#
# Output:
#   .pv       - the tail probability, clamped to [0, 1] exactly where
#               prho.c clamps it (the Edgeworth branch only)
# ============================================================================

procedure eml_prho: .n, .is, .lowerTail
    # Edgeworth coefficients, verbatim from prho.c
    .c1 = 0.2274
    .c2 = 0.2531
    .c3 = 0.1745
    .c4 = 0.0758
    .c5 = 0.1033
    .c6 = 0.3932
    .c7 = 0.0879
    .c8 = 0.0151
    .c9 = 0.0072
    .c10 = 0.0831
    .c11 = 0.0131
    .c12 = 4.6e-4

    .nSmall = 9

    # "Test admissibility of arguments and initialize"
    if .lowerTail = 1
        .pv = 0
    else
        .pv = 1
    endif

    if .n <= 1
        # R: ifault = 1, pv left at its init value. Unreachable from any
        # caller in this plugin (see header); ported because the routine
        # is ported whole, not only its reachable part.
    elsif .is <= 0
        # R: "if (is <= 0.) return" -- pv stays at its init value (p = 1
        # for the upper tail, p = 0 for the lower tail: S is never < 0
        # and always >= 0).
    else
        .n3 = .n
        .n3 = .n3 * (.n3 * .n3 - 1) / 3
        if .is > .n3
            # Larger than the maximal value S can take.
            .pv = 1 - .pv
        elsif .n <= .nSmall
            # --- Exact evaluation by permutation enumeration ---
            .nfac = 1
            .l# = zero# (.n)
            for .i to .n
                .nfac = .nfac * .i
                .l#[.i] = .i
            endfor

            # "KH mod: was `!=` in the code but `.eq.` in the paper"
            if .is = .n3
                .ifr = 1
            else
                .ifr = 0
                for .m to .nfac
                    .ise = 0
                    for .i to .n
                        .n1 = .i - .l#[.i]
                        .ise = .ise + .n1 * .n1
                    endfor
                    if .is <= .ise
                        .ifr = .ifr + 1
                    endif

                    # Next permutation by rotation, exactly as prho.c's
                    # do-while: n1 resets to n once per outer (.m) pass,
                    # then the rotation repeats -- using the SAME shrinking
                    # n1 -- for as long as the carry condition holds.
                    .n1 = .n
                    repeat
                        .mt = .l#[1]
                        for .i from 2 to .n1
                            .l#[.i - 1] = .l#[.i]
                        endfor
                        .n1 = .n1 - 1
                        .l#[.n1 + 1] = .mt
                    until not (.mt = .n1 + 1 and .n1 > 1)
                endfor
            endif

            if .lowerTail = 1
                .pv = (.nfac - .ifr) / .nfac
            else
                .pv = .ifr / .nfac
            endif
        else
            # --- Evaluation by Edgeworth series expansion (n > 9) ---
            .y = .n
            .b = 1 / .y
            .x = (6 * (.is - 1) * .b / (.y * .y - 1) - 1) * sqrt (.y - 1)
            # = rho * sqrt(n - 1) == rho / sqrt(var(rho)) ~ (0,1)
            .y = .x * .x
            .u = .x * .b * (.c1 + .b * (.c2 + .c3 * .b) +
                ... .y * (- .c4 + .b * (.c5 + .c6 * .b) -
                ... .y * .b * (.c7 + .c8 * .b -
                ... .y * (.c9 - .c10 * .b + .y * .b * (.c11 - .c12 * .y)))))

            # y = u / exp(y / 2) in prho.c. C's double overflows exp() to
            # +Inf here once y / 2 exceeds ~709.78, and u / Inf is then 0;
            # Praat's exp() instead returns undefined past that point, and
            # undefined / anything stays undefined. Measured: n = 2000 at
            # is = n3 (rho -> -1) hits exactly this (y = x^2 ~ 1999,
            # exp(999.5) overflows), turning a valid pv = 1 into undefined
            # with no guard. The guard below gives Praat the same
            # zero-in-the-limit behaviour the C already has -- it changes
            # no in-range value (verified across the 508-case grid above,
            # all of which fall inside n <= 9 or ordinary n > 9 magnitudes:
            # max difference from R's own C routine was 5.6e-16 with the
            # guard in place) and only fires where C's arithmetic would
            # have silently carried an infinity through the same division.
            .expHalfY = exp (.y / 2)
            if .expHalfY = undefined
                .y = 0
            else
                .y = .u / .expHalfY
            endif

            if .lowerTail = 1
                .pv = - .y + gaussP (.x)
            else
                .pv = .y + gaussQ (.x)
            endif
            # gaussP/gaussQ are Praat's normal CDF/upper tail, standing in
            # for prho.c's call to pnorm(x, 0, 1, lower_tail, FALSE).
            if .pv < 0
                .pv = 0
            endif
            if .pv > 1
                .pv = 1
            endif
        endif
    endif
endproc


# ============================================================================
# INTERNAL HELPER: @eml_spearmanPspearman — R's pspearman(), ported
# ============================================================================
# The closure cor.test.default (src/library/stats/R/cor.test.R, same
# R-4-3-3 tag as @eml_prho above) builds around C_pRho:
#
#     pspearman <- function(q, n, lower.tail = TRUE) {
#         if (n <= 1290 && exact)
#             .Call(C_pRho, round(q) + 2*lower.tail, n, lower.tail)
#         else {
#             den <- (n*(n^2-1))/6
#             if (continuity) den <- den + 1
#             r <- 1 - q/den
#             pt(r/sqrt((1-r^2)/(n-2)), df = n-2, lower.tail = !lower.tail)
#         }
#     }
#
# `exact` is TRUE on every call this plugin's kernel makes (the branch
# law already sent ties-present cases to the t-approximation before
# this is ever reached, and this plugin never sets cor.test's `exact`
# argument itself), so that half of the `if` is omitted here -- there is
# no second copy of it to disagree with. `continuity` is FALSE by
# default in cor.test.default and this kernel does not take a
# continuity argument, so that term is omitted too, not silently
# defaulted somewhere else.
#
# n > 1290 (R's own guard: "n*(n^2-1) does not overflow" at that size)
# is ROUTED TO THE SAME r THE ASYMPTOTIC BRANCH ALREADY USES: with no
# ties, r = 1 - q/den reduces algebraically to rho itself, and the t it
# builds, t = r / sqrt((1-r^2)/(n-2)), is the same t
# @emlSpearmanCorrelation's eml_pearsonCore already forms; pt(t, n-2,
# lower.tail = !lower.tail) is studentQ(t, n-2) when the caller's
# .lowerTail = 1 and studentP(t, n-2) when .lowerTail = 0 (the `!`
# inverts it). This plugin's grid (n = 5..50) never reaches this
# branch -- ported for the same reason the n <= 1 branch of @eml_prho
# is: the routine is ported whole. Not exercised by this item's proof
# below; flagged in the report as outside the pinned grid's coverage.
#
# Input:
#   .q         - R's q: (n^3 - n) * (1 - rho) / 6
#   .n         - sample size
#   .lowerTail - 1 for Pr[S < q]'s tail (R's lower.tail = TRUE),
#                0 for Pr[S >= q]'s tail (R's lower.tail = FALSE)
#
# Output:
#   .pv        - pspearman(q, n, lower.tail)
# ============================================================================

procedure eml_spearmanPspearman: .q, .n, .lowerTail
    ; The kernel owns the branch and is the ONLY place the constant
    ; appears. Callers read .method$ rather than re-testing .n --
    ; Fable's branch-law ruling, 27 August 2026. R 4.3.3's guard is
    ; n <= 1290, so 1290 itself is exact and 1291 is the first
    ; asymptotic n.
    if .n <= 1290
        .method$ = "exact"
        @eml_prho: .n, round (.q) + 2 * .lowerTail, .lowerTail
        .pv = eml_prho.pv
    else
        .method$ = "t approximation"
        ; continuity = FALSE is cor.test.default's default and this
        ; kernel takes no continuity argument, so den carries no +1.
        .den = (.n * (.n ^ 2 - 1)) / 6
        .r = 1 - .q / .den
        .rSquared = .r * .r
        if .rSquared >= 1
            # r = +-1 in the n > 1290 regime: t is infinite, as
            # @eml_pearsonCore already discloses for the ordinary
            # asymptotic path. Not reachable by this item's grid
            # (n <= 50); see the header note above.
            if .lowerTail = 1
                if .r > 0
                    .pv = 0
                else
                    .pv = 1
                endif
            else
                if .r > 0
                    .pv = 1
                else
                    .pv = 0
                endif
            endif
        else
            .t = .r / sqrt ((1 - .rSquared) / (.n - 2))
            if .lowerTail = 1
                .pv = studentQ (.t, .n - 2)
            else
                .pv = studentP (.t, .n - 2)
            endif
        endif
    endif
endproc


# ============================================================================
# @emlSpearmanExactP
# ============================================================================
# The exact-method Spearman p, given the rho and n an existing
# @emlSpearmanCorrelation call already computed. AS 89 (via @eml_prho and
# @eml_spearmanPspearman above), matching cor.test.default(method =
# "spearman")'s default (exact = TRUE) dispatch exactly, including its
# own tail selection -- ported from the same PVAL switch cor.test.R
# builds around pspearman():
#
#     q <- (n^3 - n) * (1 - r) / 6
#     PVAL <- switch(alternative,
#         two.sided = {
#             p <- if (q > (n^3-n)/6) pspearman(q, n, lower.tail=FALSE)
#                  else pspearman(q, n, lower.tail=TRUE)
#             min(2 * p, 1)
#         },
#         greater = pspearman(q, n, lower.tail = TRUE),
#         less    = pspearman(q, n, lower.tail = FALSE))
#
# Read closely: the two-sided branch's `p` is exactly the SAME call as
# "greater" when q is on the rho > 0 side of its null mean (n^3-n)/6, and
# exactly the SAME call as "less" when q is on the rho < 0 side -- q > mean
# iff rho < 0, since q = (n^3-n)(1-rho)/6. So this kernel computes
# .pGreater = pspearman(q, n, TRUE) and .pLess = pspearman(q, n, FALSE)
# once each, and the two-sided p reuses whichever of the two the sign of
# q - mean selects, rather than a third call -- one fewer than a literal
# transcription would need, and not a paraphrase: it is the identity R's
# own two.sided branch already relies on.
#
# THE BRANCH LAW belongs to the caller, not this kernel: Fable's 27
# August work order copies cor.test.default's own tie test --
# `TIES <- (min(length(unique(x)), length(unique(y))) < n)` -- for
# "ties present," and routes ties-present cases to the existing t-
# approximation instead of calling this procedure at all. This kernel
# does not re-derive or re-check that test; it assumes it has already
# been asked for the no-ties case, exactly as @eml_prho and
# @eml_spearmanPspearman above assume `exact` is TRUE.
#
# ONE-TAILED VARIANTS SELECT THE TAIL INSIDE THIS SAME PROCEDURE: both
# .pGreater and .pLess are always computed, so a caller building the
# Alt (named-alternative) entry point reads .pLess for "less" off THIS
# call, the same way @emlSpearmanCorrelationAlt already reads .pLess off
# @emlSpearmanCorrelation -- there is no separate one-tailed procedure
# to keep in step with this one.
#
# Input:
#   .rho   - Spearman's rho, already computed (e.g. by
#            @emlSpearmanCorrelation.rho). NOT recomputed here.
#   .n     - the number of pairs rho was computed from
#   .tails - 1 or 2, same convention as @emlSpearmanCorrelation: 2 is
#            two-sided; 1 fixes the one-tailed alternative to "greater"
#            (H1: rho > 0), matching the base (non-Alt) entry point's
#            existing convention. A caller wanting "less" reads .pLess
#            directly regardless of .tails, as above.
#
# Output:
#   .p           - the p-value for .tails and .alternative$
#   .pGreater    - pspearman(q, n, lower.tail = TRUE): the one-tailed
#                  p for H1: rho > 0
#   .pLess       - pspearman(q, n, lower.tail = FALSE): the one-tailed
#                  p for H1: rho < 0
#   .alternative$ - "two-sided" or "greater"
#   .method$      - "exact" (an internal tag for a caller's own
#                   branching, not the disclosed report sentence --
#                   Fable's work order holds the printed wording for
#                   the language batch)
#   .error$       - "" if valid, else the reason .p is undefined
# ============================================================================

procedure emlSpearmanExactP: .rho, .n, .tails
    .p = undefined
    .pGreater = undefined
    .pLess = undefined
    .alternative$ = ""
    .method$ = ""
    .error$ = ""

    if .n < 2
        .error$ = "Need at least 2 pairs"
    elsif .tails < 1 or .tails > 2
        .error$ = "tails must be 1 or 2"
    else
        .q = (.n ^ 3 - .n) * (1 - .rho) / 6
        .qMean = (.n ^ 3 - .n) / 6

        @eml_spearmanPspearman: .q, .n, 1
        .pGreater = eml_spearmanPspearman.pv
        @eml_spearmanPspearman: .q, .n, 0
        .pLess = eml_spearmanPspearman.pv
        ; Both calls carry the same .n, so both took the same branch.
        .method$ = eml_spearmanPspearman.method$

        if .q > .qMean
            .pTwoSided = min (1, 2 * .pLess)
        else
            .pTwoSided = min (1, 2 * .pGreater)
        endif

        if .tails = 2
            .alternative$ = "two-sided"
            .p = .pTwoSided
        else
            .alternative$ = "greater"
            .p = .pGreater
        endif
    endif
endproc


# ============================================================================
# @emlSpearmanCorrelationDispatch
# ============================================================================
# THE ONE COMPUTATION SITE for a Spearman p (Fable's 27 August work order,
# docs/WORK_ORDER_SPEARMAN_EXACT_2026-08-27.md, "One computation site").
# Every door that reports a Spearman p -- the correlation orchestrator
# (@emlRunCorrelationAnalysis), the per-group correlation (both the
# Correlate dialog and the wizard's own per-group loop), and the scatter's
# draw-time annotation (ungrouped, per-group and overall/pooled) -- calls
# THIS procedure where it used to call @emlSpearmanCorrelation directly, so
# there is exactly one place the branch law is decided, and the
# door-agreement census (v127) sees one answer from every door.
#
# NEITHER existing kernel is modified or paraphrased here. This procedure
# only ROUTES between two numbers each of them already computes:
#   @emlSpearmanCorrelation  - rho, t, df, and its own (asymptotic, t-based)
#                              p -- UNTOUCHED, called exactly as before.
#   @emlSpearmanExactP       - the AS 89 port -- UNTOUCHED, called with the
#                              rho and n the line above just produced.
#
# THE BRANCH LAW, copied verbatim from cor.test.default's own tie test:
#     TIES <- (min(length(unique(x)), length(unique(y))) < n)
# @emlRankVector's own .hasTies flag on a single vector IS that test:
# .hasTies = 1 exactly when the vector holds a repeated value, which is
# exactly unique(v) < n for that vector. Ties in EITHER variable route to
# the existing t-approximation; no ties routes to the AS 89 exact p.
#
# Arguments: identical to @emlSpearmanCorrelation -- .x#, .y#, .tails --
# every call site is a one-line drop-in swap.
#
# Output:
#   .rho, .t, .df, .n, .error$, .warning$, .perfect
#                - forwarded UNCHANGED from @emlSpearmanCorrelation.
#   .p           - the p-value this dispatch reports: the AS 89 exact p
#                  when there are no ties, @emlSpearmanCorrelation's own
#                  t-approximation p when there are. ALSO written back
#                  into emlSpearmanCorrelation.p (the qualified global),
#                  the same way @emlRunCorrelationAnalysis already
#                  restores captured outputs into that name -- so every
#                  existing reader of emlSpearmanCorrelation.p (the
#                  report layer, the CSV export) sees the routed value
#                  without itself being touched.
#   .pAsymptotic - @emlSpearmanCorrelation's own p, ALWAYS computed
#                  regardless of which branch .p took. Read by the
#                  validate check building its red demonstrations; never
#                  printed by this procedure or any caller.
#   .hasTies     - 1 if either variable has a repeated value, else 0.
#   .method$     - "exact" or "t approximation" -- an INTERNAL branch tag
#                  for a caller's own logic, the same shape as
#                  @emlMannWhitneyU.method$ ("exact" / "normal
#                  approximation"). NOT the disclosed report sentence:
#                  Fable's work order holds "exact method (AS 89)" and
#                  "t approximation (ties present)" in the language
#                  batch, unapproved. No code anywhere formats or prints
#                  either sentence yet -- see "The report line" in the
#                  work order, and eml-analysis.praat / eml-correlate.praat
#                  / eml-wizard.praat / eml-draw-procedures.praat for the
#                  wired call sites, none of which gained a print.
# ============================================================================

procedure emlSpearmanCorrelationDispatch: .x#, .y#, .tails
    @emlSpearmanCorrelation: .x#, .y#, .tails
    .rho = emlSpearmanCorrelation.rho
    .t = emlSpearmanCorrelation.t
    .df = emlSpearmanCorrelation.df
    .n = emlSpearmanCorrelation.n
    .error$ = emlSpearmanCorrelation.error$
    .warning$ = emlSpearmanCorrelation.warning$
    .perfect = emlSpearmanCorrelation.perfect
    .pAsymptotic = emlSpearmanCorrelation.p
    .p = emlSpearmanCorrelation.p
    .hasTies = 0
    .method$ = ""
    .methodReason$ = ""

    if .error$ = ""
        @emlRankVector: .x#
        .hasTiesX = emlRankVector.hasTies
        @emlRankVector: .y#
        .hasTiesY = emlRankVector.hasTies
        .hasTies = 0
        if .hasTiesX = 1
            .hasTies = 1
        endif
        if .hasTiesY = 1
            .hasTies = 1
        endif

        ; Two reasons an approximation is returned, and they are not the
        ; same fact: ties make the exact null distribution wrong, while a
        ; large n makes it unreachable. .method$ names what was computed,
        ; .methodReason$ why. Above the cutoff the kernel has already
        ; chosen, so this reads its flag and does not test .n a second
        ; time -- Fable's branch-law ruling, 27 August 2026. Both are
        ; internal tags; the printed wording is item 22 of the language
        ; batch and is unapproved, so no call site prints either.
        if .hasTies = 1
            .method$ = "t approximation"
            .methodReason$ = "ties"
            .p = .pAsymptotic
        else
            @emlSpearmanExactP: .rho, .n, .tails
            .method$ = emlSpearmanExactP.method$
            ; EXHAUSTIVE DISPATCH. Every label is matched positively and
            ; none is left as the implicit default. A single positive test
            ; is not enough: whichever label goes untested becomes the
            ; caption an unset .method$ silently claims, which is the same
            ; defect with a different victim. An unset or unknown label
            ; here is an impossible state -- @emlSpearmanExactP sets
            ; .method$ on every path that returns without an error -- and
            ; impossible states fail loudly rather than captioning
            ; themselves. Fable's ruling, 27 August 2026.
            ;
            ; The shape is @emlTTestAlt's (.error$ set, numerics left
            ; undefined) rather than @emlRMPostHoc's disclosed fallback.
            ; RMPostHoc validates an adjustment method a CALLER supplied,
            ; where substituting Holm and saying so is a defensible
            ; repair. This label is produced inside the module, so there
            ; is no substitute to defend: the only honest output is a
            ; refusal.
            if .method$ = "exact"
                .methodReason$ = ""
                .p = emlSpearmanExactP.p
            elsif .method$ = "t approximation"
                .methodReason$ = "large sample"
                .p = emlSpearmanExactP.p
            else
                .error$ = "Internal: unrecognised Spearman method label from @emlSpearmanExactP: " + .method$
                .methodReason$ = ""
                .p = undefined
            endif
        endif

        ; Written back so every EXISTING reader of emlSpearmanCorrelation.p
        ; -- the report layer, the CSV export, anything that has not been
        ; touched by this work order -- sees the routed value. The same
        ; qualified-global restoration @emlRunCorrelationAnalysis already
        ; does at its own capture site, one level up.
        ; The refusal is propagated to the SAME qualified globals every
        ; existing reader already checks. Without this the dispatch would
        ; decline to publish while @emlSpearmanCorrelation.p still held
        ; its own untouched value and .error$ still read empty -- a stale
        ; number presented as a live one, which is the failure the
        ; exhaustive dispatch above exists to prevent.
        if .error$ = ""
            emlSpearmanCorrelation.p = .p
        else
            emlSpearmanCorrelation.p = undefined
            emlSpearmanCorrelation.error$ = .error$
        endif
    endif
endproc


# ============================================================================
# INTERNAL HELPER: Exact p-value for Mann-Whitney U via DP
# ============================================================================
# Computes the exact null distribution of U1 using dynamic programming.
#
# Under the null hypothesis, all assignments of N = n1 + n2 items into
# two groups are equally likely. The distribution of U1 is computed by
# considering each rank position from highest to lowest: if the item
# belongs to group 1, it contributes the current n2 count to U1.
#
# Recurrence:
#   count(u, m, n) = count(u - n, m - 1, n) + count(u, m, n - 1)
#   where m = items remaining for group 1, n = items remaining for group 2
#
# Base case: count(0, 0, n) = 1 for all n; count(u, 0, n) = 0 for u > 0
#
# Returns cumulative probabilities (left and right tail).
# Uses the no-tie null distribution. When ties exist in the data, the
# exact p-value is slightly conservative (standard practice).
#
# Input:
#   .u1       - observed U1 statistic
#   .n1       - size of group 1
#   .n2       - size of group 2
#
# Output:
#   .pLeft    - P(U <= floor(u1)) under the null
#   .pRight   - P(U >= ceiling(u1)) under the null
#   .dp##     - the null distribution ITSELF, not merely its tails:
#               .dp## [.n1 + 1, u + 1] is the NUMBER of arrangements
#               giving U = u, for u = 0 .. .n1 * .n2. Row .n1 + 1 is the
#               only row a caller may read; the lower rows are the
#               recurrence's scaffolding for m < n1 and are not a
#               distribution of anything.
#   .total    - C(n1 + n2, n1), the sum of that row -- the denominator
#               every probability above is formed with.
#
# .dp## AND .total ARE PART OF THE CONTRACT, not incidental internals.
# @emlHodgesLehmannTwoSample needs a QUANTILE of this same null
# distribution (the critical rank k behind the exact confidence
# interval), which no pair of tail probabilities can supply, and Fable's
# 26 August work order forbids building a second copy of the
# distribution to get it. So this procedure is the one place the U null
# distribution is computed, and the row and its total are readable.
# Like every Praat procedure output they survive only until the next
# call: copy them on the following line.
# ============================================================================

procedure eml_mannWhitneyExactP: .u1, .n1, .n2
    .maxU = .n1 * .n2

    # --- Cache: the DP table is keyed by (.n1, .n2) alone (Fable's 26
    # August ruling, item 4). @emlMannWhitneyU (p-value) and
    # @emlHodgesLehmannTwoSample (critical rank) are two reads of the
    # SAME object for the same pair, and a balanced multi-group design
    # calls this procedure again, with the same (n1, n2), once per
    # remaining pair. One build must serve all of them.
    #
    # Praat has no hash map. The shape already in this plugin for "several
    # of the same kind of matrix, told apart by an index" is
    # eml-lmm.praat's .varContrast'.i'## / .rMat'.i'## family: a linear
    # array of named matrices addressed by an interpolated integer
    # suffix. This cache is that same shape -- a small linear-scan table
    # of (n1, n2) keys, each slot's matrix at .cacheDp'.slot'##.
    #
    # The cache lives in THIS procedure's own dotted namespace, so it
    # persists the same way .dp##/.total already do (survives until this
    # procedure runs again) -- except the slots ACCUMULATE across calls
    # rather than being overwritten by the next one. .cacheCount is
    # guarded with variableExists because the first call in a run has
    # never set it; that guard is the same one this plugin already uses
    # to default a persistent flag cleanly on its first read (e.g.
    # eml-analysis.praat's variableExists ("emlRMPostHoc.nPairs")) --
    # there just checking a DIFFERENT procedure's namespace from outside
    # it, rather than a procedure's own namespace from inside.
    if variableExists ("eml_mannWhitneyExactP.cacheCount") = 0
        .cacheCount = 0
    endif
    .cacheMax = 64

    .cacheHit = 0
    for .slot from 1 to .cacheCount
        if .cacheN1[.slot] = .n1 and .cacheN2[.slot] = .n2
            .cacheHit = .slot
        endif
    endfor

    if .cacheHit > 0
        # --- Cache hit: this (n1, n2) distribution was already built ---
        .total = .cacheTotal[.cacheHit]
        .dp## = .cacheDp'.cacheHit'##
    else
        .vecSize = .maxU + 1

        # DP table: dp##[m + 1, u + 1] = count(u, m, current_n)
        # Iterate n from 0 to .n2 as outer loop
        .dp## = zero## (.n1 + 1, .vecSize)

        # Base case: n = 0 → count(0, m, 0) = 1 for all m
        for .m from 0 to .n1
            .dp##[.m + 1, 1] = 1
        endfor

        # Fill DP: iterate n from 1 to .n2
        for .n from 1 to .n2
            .new## = zero## (.n1 + 1, .vecSize)
            # m = 0: count(u, 0, n) = 1 if u = 0, else 0
            .new##[1, 1] = 1

            for .m from 1 to .n1
                for .u from 0 to .m * .n
                    # count(u, m, n) = count(u - n, m - 1, n) + count(u, m, n - 1)
                    .term1 = 0
                    if .u >= .n
                        .term1 = .new##[.m, .u - .n + 1]
                    endif
                    .term2 = .dp##[.m + 1, .u + 1]
                    .new##[.m + 1, .u + 1] = .term1 + .term2
                endfor
            endfor

            .dp## = .new##
        endfor

        # Total configurations = C(n1 + n2, n1)
        .total = 0
        for .u from 0 to .maxU
            .total = .total + .dp##[.n1 + 1, .u + 1]
        endfor

        # --- Store for the next call sharing this (n1, n2) ---
        if .cacheCount < .cacheMax
            .cacheCount = .cacheCount + 1
            .cacheN1[.cacheCount] = .n1
            .cacheN2[.cacheCount] = .n2
            .cacheTotal[.cacheCount] = .total
            .cacheDp'.cacheCount'## = .dp##
        endif
    endif

    # Cumulative left tail: P(U <= floor(u1))
    .uFloor = floor (.u1)
    if .uFloor < 0
        .uFloor = 0
    endif
    if .uFloor > .maxU
        .uFloor = .maxU
    endif
    .cumLeft = 0
    for .u from 0 to .uFloor
        .cumLeft = .cumLeft + .dp##[.n1 + 1, .u + 1]
    endfor
    .pLeft = .cumLeft / .total

    # Cumulative right tail: P(U >= ceiling(u1))
    .uCeil = ceiling (.u1)
    if .uCeil < 0
        .uCeil = 0
    endif
    if .uCeil > .maxU
        .uCeil = .maxU
    endif
    .cumRight = 0
    for .u from .uCeil to .maxU
        .cumRight = .cumRight + .dp##[.n1 + 1, .u + 1]
    endfor
    .pRight = .cumRight / .total
endproc


# ============================================================================
# @emlMannWhitneyU
# ============================================================================
# Mann-Whitney U test for two independent samples.
#
# Tests whether the distributions of two groups differ. Uses rank-based
# comparison (nonparametric alternative to independent-samples t-test).
#
# Algorithm selection (matches R wilcox.test):
#   n1 < 50 AND n2 < 50 AND no ties → exact p-value via DP
#                                     (no-tie null distribution)
#   otherwise → normal approximation with continuity correction
#               and tie correction factor
#
# DEPENDENCY: Requires @emlRankVector from eml-core-utilities.praat.
# The calling script must include utilities before inferential.
#
# Arguments:
#   .v1#   - numeric vector, group 1
#   .v2#   - numeric vector, group 2
#   .tails - 1 (one-tailed) or 2 (two-tailed)
#
# Output:
#   .u1          - U statistic for group 1
#   .u2          - U statistic for group 2 (= n1*n2 - u1)
#   .p           - p-value for the requested alternative
#   .pGreater    - one-tailed p for H1: group 1 > group 2
#   .pLess       - one-tailed p for H1: group 1 < group 2
#   .alternative$ - "two-sided" or "greater" (the alternative .p refers to)
#   .n1          - size of group 1
#   .n2          - size of group 2
#   .r1          - rank sum of group 1
#   .r2          - rank sum of group 2
#   .hasTies     - 1 if the combined sample contains tied values, else 0
#   .method$     - "exact" or "normal approximation"
#   .z           - z statistic (approximation path only; undefined for exact)
#   .error$      - error message, or "" if valid
#
# One-tailed p (.tails = 1): the alternative is FIXED as H1: group 1 >
#   group 2, matching R's wilcox.test(x, y, alternative = "greater").
#   A one-tailed test run in the wrong direction therefore returns a
#   p-value near 1, not near 0. For the opposite alternative, read
#   .pLess (or swap the arguments).
# ============================================================================

procedure emlMannWhitneyU: .v1#, .v2#, .tails
    # Initialize outputs
    .u1 = undefined
    .u2 = undefined
    .p = undefined
    .pGreater = undefined
    .pLess = undefined
    .alternative$ = ""
    .r1 = undefined
    .r2 = undefined
    .hasTies = 0
    .method$ = ""
    .z = undefined
    .error$ = ""

    .n1 = size (.v1#)
    .n2 = size (.v2#)
    .nTotal = .n1 + .n2

    # --- Input validation ---
    if .n1 < 1
        .error$ = "Group 1 must have at least 1 observation"
    elsif .n2 < 1
        .error$ = "Group 2 must have at least 1 observation"
    elsif .tails < 1 or .tails > 2
        .error$ = "tails must be 1 or 2"
    else
        # --- Combine and rank ---
        .combined# = zero# (.nTotal)
        for .i from 1 to .n1
            .combined#[.i] = .v1#[.i]
        endfor
        for .i from 1 to .n2
            .combined#[.n1 + .i] = .v2#[.i]
        endfor

        @emlRankVector: .combined#
        .ranks# = emlRankVector.ranks#
        .hasTies = emlRankVector.hasTies

        # Rank sums
        .r1 = 0
        for .i from 1 to .n1
            .r1 = .r1 + .ranks#[.i]
        endfor
        .r2 = 0
        for .i from 1 to .n2
            .r2 = .r2 + .ranks#[.n1 + .i]
        endfor

        # U statistics
        .u1 = .r1 - .n1 * (.n1 + 1) / 2
        .u2 = .r2 - .n2 * (.n2 + 1) / 2
        .expectedU = .n1 * .n2 / 2

        if .tails = 2
            .alternative$ = "two-sided"
        else
            .alternative$ = "greater"
        endif

        # Exact iff n1 < 50 AND n2 < 50 AND no ties. R's wilcox.test uses
        # per-group sizes (not the combined total) and falls back to the
        # normal approximation whenever ties are present, because the
        # exact null distribution assumes untied integer ranks.
        # Nested ifs: Praat's "and" does not short-circuit.
        .useExact = 0
        if .n1 < 50
            if .n2 < 50
                if .hasTies = 0
                    .useExact = 1
                endif
            endif
        endif

        if .useExact = 1
            # --- Exact path (DP over the no-tie null distribution) ---
            .method$ = "exact"

            @eml_mannWhitneyExactP: .u1, .n1, .n2

            # pLeft = P(U <= u1) is the lower tail (group 1 < group 2);
            # pRight = P(U >= u1) is the upper tail (group 1 > group 2).
            .pLess = eml_mannWhitneyExactP.pLeft
            .pGreater = eml_mannWhitneyExactP.pRight

            if .tails = 2
                .p = min (1, 2 * min (.pLess, .pGreater))
            else
                # One-tailed: fixed alternative H1 group 1 > group 2
                .p = .pGreater
            endif
        else
            # --- Normal approximation path ---
            .method$ = "normal approximation"

            # Tie correction factor
            # T = sum(t_k^3 - t_k) for each tie group of size t_k
            # Computed from the combined ranking
            .tieCorrection = 0
            if .hasTies = 1
                # Re-sort combined to find tie group sizes
                # Use sorted values from ranks to count consecutive equal ranks
                # More efficient: count tie groups from sorted ranks
                .sortedRanks# = zero# (.nTotal)
                for .i from 1 to .nTotal
                    .sortedRanks#[.i] = .ranks#[.i]
                endfor
                # Sort ranks (they may not be in order since they're assigned
                # to original positions)
                # Use simple insertion sort for ranks
                for .i from 2 to .nTotal
                    .key = .sortedRanks#[.i]
                    .j = .i - 1
                    while .j >= 1 and .sortedRanks#[.j] > .key
                        .sortedRanks#[.j + 1] = .sortedRanks#[.j]
                        .j = .j - 1
                    endwhile
                    .sortedRanks#[.j + 1] = .key
                endfor

                # Count consecutive equal ranks
                .i = 1
                while .i <= .nTotal
                    .tieSize = 1
                    while .i + .tieSize <= .nTotal and .sortedRanks#[.i + .tieSize] = .sortedRanks#[.i]
                        .tieSize = .tieSize + 1
                    endwhile
                    if .tieSize > 1
                        .tieCorrection = .tieCorrection + (.tieSize * .tieSize * .tieSize - .tieSize)
                    endif
                    .i = .i + .tieSize
                endwhile
            endif

            # Variance with tie correction
            .varU = .n1 * .n2 * (.nTotal + 1) / 12
            if .tieCorrection > 0
                .varU = .varU - .n1 * .n2 * .tieCorrection / (12 * .nTotal * (.nTotal - 1))
            endif

            if .varU <= 0
                # Degenerate case: all values identical
                .p = 1
                .z = 0
                .pGreater = 1
                .pLess = 1
            else
                .sdU = sqrt (.varU)
                .zRaw = .u1 - .expectedU

                # Continuity correction: shift U 0.5 toward expected value
                if .zRaw > 0
                    .zNum = .zRaw - 0.5
                elsif .zRaw < 0
                    .zNum = .zRaw + 0.5
                else
                    .zNum = 0
                endif

                .z = .zNum / .sdU

                # Directional continuity corrections, as in R's wilcox.test:
                # "greater" subtracts 0.5, "less" adds 0.5.
                .zGreater = (.zRaw - 0.5) / .sdU
                .zLess = (.zRaw + 0.5) / .sdU
                .pGreater = gaussQ (.zGreater)
                .pLess = gaussQ (- .zLess)

                if .tails = 2
                    .p = 2 * gaussQ (abs (.z))
                else
                    # One-tailed: fixed alternative H1 group 1 > group 2
                    .p = .pGreater
                endif
            endif
        endif
    endif
endproc

# ============================================================================
# INTERNAL HELPER: @eml_hlTwoSampleW  — R's W(d), ported
# ============================================================================
# The standardised, continuity-corrected two-sample rank statistic that
# R's wilcox.test inverts to build its asymptotic confidence interval,
# ported line for line from R 4.3.3, src/library/stats/R/wilcox.test.R,
# the "Asymptotic confidence interval for the location parameter" block
# of wilcox.test.default:
#
#     W <- function(d) {
#         dr <- rank(c(x - d, y))
#         NTIES.CI <- table(dr)
#         dz <- sum(dr[seq_along(x)]) - n.x * (n.x + 1) / 2 - n.x * n.y / 2
#         CORRECTION.CI <- if (correct) sign(dz) * 0.5 else 0
#         SIGMA.CI <- sqrt((n.x * n.y / 12) *
#                          ((n.x + n.y + 1)
#                           - sum(NTIES.CI^3 - NTIES.CI)
#                           / ((n.x + n.y) * (n.x + n.y - 1))))
#         (dz - CORRECTION.CI) / SIGMA.CI
#     }
#
# Every piece above has a counterpart below and nothing is folded or
# simplified on the way: dz is the shifted sample's U statistic measured
# from its own null mean, the correction is the two-sided
# sign(dz) * 0.5, and SIGMA.CI carries the TIE CORRECTION RECOMPUTED AT
# THE SHIFTED DATA -- shifting group 1 by d creates and destroys ties, so
# the variance is not the variance of the unshifted sample and cannot be
# hoisted out of the loop. sum(NTIES^3 - NTIES) is exactly
# @emlRankVector's .tieCorrectionSum, which is why the ranking is done
# through that procedure rather than a second ranker written here.
#
# .correct exists because R's own code turns it off for ONE call: after
# the interval is built, R sets correct <- FALSE and root-finds W for its
# point estimate. This plugin does not take that path -- Fable's work
# order pins the estimate to the median of the cross-differences on both
# branches -- so every call from this file passes .correct = 1. The
# parameter is kept so the ported shape is the shape R has.
#
# Input:
#   .v1#     - group 1 (R's x)
#   .v2#     - group 2 (R's y)
#   .d       - the shift being tested
#   .correct - 1 to apply the continuity correction, 0 not to
#
# Output:
#   .value  - W(d), or undefined when SIGMA.CI is zero (every observation
#             in the combined sample tied, where R warns and returns NaN)
# ============================================================================

procedure eml_hlTwoSampleW: .v1#, .v2#, .d, .correct
    .n1 = size (.v1#)
    .n2 = size (.v2#)
    .nTotal = .n1 + .n2

    # dr <- rank(c(x - d, y))
    .shifted# = zero# (.nTotal)
    for .i from 1 to .n1
        .shifted#[.i] = .v1#[.i] - .d
    endfor
    for .i from 1 to .n2
        .shifted#[.n1 + .i] = .v2#[.i]
    endfor

    @emlRankVector: .shifted#
    .ranks# = emlRankVector.ranks#
    .tieSum = emlRankVector.tieCorrectionSum

    # dz <- sum(dr[seq_along(x)]) - n.x * (n.x + 1) / 2 - n.x * n.y / 2
    .rankSum = 0
    for .i from 1 to .n1
        .rankSum = .rankSum + .ranks#[.i]
    endfor
    .dz = .rankSum - .n1 * (.n1 + 1) / 2 - .n1 * .n2 / 2

    # CORRECTION.CI <- sign(dz) * 0.5   (two-sided; sign(0) is 0 in R)
    .correction = 0
    if .correct = 1
        if .dz > 0
            .correction = 0.5
        elsif .dz < 0
            .correction = -0.5
        endif
    endif

    .sigma = sqrt ((.n1 * .n2 / 12) * ((.nTotal + 1)
    ... - .tieSum / (.nTotal * (.nTotal - 1))))

    if .sigma = 0
        .value = undefined
    else
        .value = (.dz - .correction) / .sigma
    endif
endproc


# ============================================================================
# INTERNAL HELPER: @eml_hlZeroin  — R's uniroot, ported ONCE
# ============================================================================
# Brent's zeroin, ported from R 4.3.3's src/library/stats/src/zeroin.c,
# function R_zeroin2 -- the routine R's uniroot() actually calls (through
# .External2(C_zeroin2, ...)), given the two endpoint values it already
# has. wilcox.test's interval is the root of wdiff(d) = W(d) - zq, and
# ROOT-FINDING IS PART OF THE ALGORITHM, not an implementation detail
# that may be swapped for another solver: W is a STEP function, so its
# "root" is a jump location and WHICH point inside the jump comes back
# is decided by the iteration path. A bisection written from scratch
# would agree with R only to the width of a step. This one follows
# R_zeroin2's iterates -- the swap, the inverse-quadratic branch, the
# 0.75 * cb * q acceptance test, the tol_act floor on the step -- so the
# two implementations share the sequence and not merely the vicinity.
#
# Praat has no function values, so the function under investigation is
# not a parameter. R calls (*f)(b, info) at exactly one site inside the
# loop; here that site is a two-arm switch on .form, and .form is the
# ONLY thing in this procedure that knows which problem is being solved.
#
# WHY THE SWITCH RATHER THAN A SECOND COPY. The first draft of this
# helper (item 3) was two-sample-specific and its header said the paired
# form "needs its own W and therefore its own copy of this loop". Fable's
# item 4 overrules that in terms -- "THE ZEROIN PORT IS GENERAL ...
# REUSE, do not re-port ... re-porting R's zeroin a second time would be
# the clearest possible violation" -- and the order governs where it and
# the code disagree. It is also the better reading of the C: R has ONE
# zeroin.c and hands it a function pointer; two-sample and one-sample
# wilcox.test both reach the identical iteration through uniroot(). The
# thing that differs between them is W, not Brent's method, and W is
# already two procedures. So Brent's iteration -- the swap, the
# inverse-quadratic branch, the 0.75 * cb * q acceptance test, the
# tol_act floor on the step -- exists once in this tree and a drift in it
# cannot reach one branch without reaching the other.
#
# Input:
#   .form      - 1: the two-sample W, @eml_hlTwoSampleW (.v1#, .v2#)
#                2: the one-sample/paired W, @eml_hlPairedW (.v1# only,
#                   .v2# ignored -- pass an empty vector)
#   .v1#, .v2# - the sample(s), passed through to W
#   .ax, .bx   - the bracketing interval [a, b]
#   .fa, .fb   - wdiff at those endpoints, already known to the caller
#   .zq        - the quantile W is being inverted at (wdiff = W(d) - zq)
#   .tol       - acceptable tolerance (R's tol.root = 1e-4)
#   .maxit     - iteration ceiling (R's uniroot maxiter = 1000)
#   .correct   - passed through to W
#
# Output:
#   .root - the abscissa where wdiff changes sign
# ============================================================================

procedure eml_hlZeroin: .form, .v1#, .v2#, .ax, .bx, .fa, .fb, .zq, .tol, .maxit, .correct
    # EPSILON is C's DBL_EPSILON, 2^-52, which Praat has no name for.
    .epsilon = 2.220446049250313e-16

    .a = .ax
    .b = .bx
    .c = .a
    .fc = .fa
    .iter = .maxit + 1
    .root = undefined
    .done = 0

    # First test if we have found a root at an endpoint
    if .fa = 0
        .root = .a
        .done = 1
    elsif .fb = 0
        .root = .b
        .done = 1
    endif

    while .done = 0 and .iter > 0
        .iter = .iter - 1
        # Distance from the last but one to the last approximation
        .prevStep = .b - .a

        # Swap data for b to be the best approximation. Transcribed in
        # C's order: a = b, b = c, c = a leaves c holding the OLD b,
        # because a has already been overwritten.
        if abs (.fc) < abs (.fb)
            .a = .b
            .b = .c
            .c = .a
            .fa = .fb
            .fb = .fc
            .fc = .fa
        endif

        .tolAct = 2 * .epsilon * abs (.b) + .tol / 2
        .newStep = (.c - .b) / 2

        if abs (.newStep) <= .tolAct or .fb = 0
            # Acceptable approximation is found
            .root = .b
            .done = 1
        else
            # Decide if the interpolation can be tried
            if abs (.prevStep) >= .tolAct and abs (.fa) > abs (.fb)
                .cb = .c - .b
                if .a = .c
                    # Only two distinct points: linear interpolation
                    .t1 = .fb / .fa
                    .p = .cb * .t1
                    .q = 1 - .t1
                else
                    # Quadric inverse interpolation
                    .q = .fa / .fc
                    .t1 = .fb / .fc
                    .t2 = .fb / .fa
                    .p = .t2 * (.cb * .q * (.q - .t1) - (.b - .a) * (.t1 - 1))
                    .q = (.q - 1) * (.t1 - 1) * (.t2 - 1)
                endif
                # p was calculated with the opposite sign; make p
                # positive and assign the possible minus to q
                if .p > 0
                    .q = - .q
                else
                    .p = - .p
                endif
                # If b + p/q falls in [b, c] and is not too large
                if .p < (0.75 * .cb * .q - abs (.tolAct * .q) / 2)
                ... and .p < abs (.prevStep * .q / 2)
                    .newStep = .p / .q
                endif
            endif

            # Adjust the step to be not less than the tolerance
            if abs (.newStep) < .tolAct
                if .newStep > 0
                    .newStep = .tolAct
                else
                    .newStep = - .tolAct
                endif
            endif

            # Save the previous approximation, step to a new one
            .a = .b
            .fa = .fb
            .b = .b + .newStep
            # R's (*f)(b, info), the one function-pointer call in
            # zeroin.c. Praat has no function values, so the pointer is
            # a switch and .form is what was passed in its place.
            if .form = 1
                @eml_hlTwoSampleW: .v1#, .v2#, .b, .correct
                .fb = eml_hlTwoSampleW.value - .zq
            else
                @eml_hlPairedW: .v1#, .b, .correct
                .fb = eml_hlPairedW.value - .zq
            endif

            # Adjust c for it to have a sign opposite to that of b
            if (.fb > 0 and .fc > 0) or (.fb < 0 and .fc < 0)
                .c = .a
                .fc = .fa
            endif
        endif
    endwhile

    if .done = 0
        # Iterations exhausted. R returns b and flags Maxit = -1; there
        # is no flag to return here and 1000 iterations of a bracketed
        # Brent step is not a case this reaches, but the value returned
        # is R's value returned.
        .root = .b
    endif
endproc


# ============================================================================
# INTERNAL HELPER: @eml_hlTwoSampleRoot  — R's root(zq), ported
# ============================================================================
# R 4.3.3, wilcox.test.default, asymptotic two-sample branch:
#
#     root <- function(zq) {
#         f.lower <- Wmumin - zq
#         if (f.lower <= 0) return(mumin)
#         f.upper <- Wmumax - zq
#         if (f.upper >= 0) return(mumax)
#         uniroot(wdiff, lower = mumin, upper = mumax,
#                 f.lower = f.lower, f.upper = f.upper,
#                 tol = tol.root, zq = zq)$root
#     }
#
# THE TWO EARLY RETURNS ARE NOT GUARDS AGAINST BAD INPUT, they are part
# of the answer: R's own comment says "in extreme cases we need to
# return endpoints, e.g. wilcox.test(1, 2:60, conf.int = TRUE)". When
# the sample cannot push the statistic past zq anywhere in
# [mumin, mumax], the bound IS the endpoint, and a root finder called
# on an unbracketed interval would instead fail. Dropping them turns a
# legitimate wide interval into an error.
#
# Input:
#   .v1#, .v2#      - the two groups
#   .zq             - the quantile to invert at
#   .mumin, .mumax  - min(x) - max(y) and max(x) - min(y)
#   .wmin, .wmax    - W at those two endpoints, computed once by the caller
#   .correct        - passed through to W
#
# Output:
#   .result - the bound
# ============================================================================

procedure eml_hlTwoSampleRoot: .v1#, .v2#, .zq, .mumin, .mumax, .wmin, .wmax, .correct
    .fLower = .wmin - .zq
    if .fLower <= 0
        .result = .mumin
    else
        .fUpper = .wmax - .zq
        if .fUpper >= 0
            .result = .mumax
        else
            @eml_hlZeroin: 1, .v1#, .v2#, .mumin, .mumax, .fLower,
            ... .fUpper, .zq, 1e-4, 1000, .correct
            .result = eml_hlZeroin.root
        endif
    endif
endproc


# ============================================================================
# @emlHodgesLehmannTwoSample
# ============================================================================
# The Hodges-Lehmann shift estimate for two independent samples, and its
# confidence interval -- the location counterpart of the Mann-Whitney U
# test, the way a mean difference and its t interval are the counterpart
# of the t test. Specified by Fable's 26 August work order
# (docs/WORK_ORDER_INTERVALS_2026-08-26.md).
#
# THE ESTIMATE is the median of all n1 * n2 cross-differences
# v1[i] - v2[j]. On an even count it is the mean of the middle two, as
# R's median() is. The differences are ordered with Praat's NATIVE
# sort#, never a script sort: n1 * n2 is the one shape in this file
# where a per-element sorting loop is measured in seconds rather than
# milliseconds (CLAUDE.md, "Vectorize").
#
# THE BRANCH IS THE p-VALUE'S BRANCH. The gate below -- n1 < 50 AND
# n2 < 50 AND no ties in the combined sample, as three nested ifs
# because Praat's "and" does not short-circuit -- is copied verbatim
# from @emlMannWhitneyU above, which copied it from R's wilcox.test. It
# is not re-derived here and it must not drift: an interval computed on
# the exact null distribution printed beside a p-value computed on the
# normal approximation is a report that contradicts itself, and neither
# number looks wrong on its own.
#
#   exact:  the critical rank k is a QUANTILE of the U null
#           distribution, taken from the DP in @eml_mannWhitneyExactP --
#           the same distribution the exact p-value is read off, read
#           once, never rebuilt. The bounds are the k-th smallest and
#           k-th largest cross-differences, which is R's
#           c(diffs[qu], diffs[ql + 1]).
#
#   normal approximation: R's continuity-corrected z inversion, ported.
#           See @eml_hlTwoSampleW, @eml_hlTwoSampleRoot and
#           @eml_hlZeroin above; the port is line-for-line and
#           carries R's own step and tolerance, so the two share the
#           method and not merely the answer.
#
# THE CRITICAL RANK, in full, from R 4.3.3's exact two-sided branch:
#
#     qu <- qwilcox(alpha/2, n.x, n.y)
#     if (qu == 0) qu <- 1
#     ql <- n.x * n.y - qu
#     c(diffs[qu], diffs[ql + 1])
#
# and qwilcox itself (R 4.3.3, src/nmath/wilcox.c) is a cumulative scan
# over the null distribution with a fuzz applied to the PROBABILITY:
#
#     c = choose(m + n, n);
#     p = 0; q = 0;
#     if (x <= 0.5) {
#         x = x - 10 * DBL_EPSILON;
#         for(;;) { p += cwilcox(q, mm, nn) / c; if (p >= x) break; q++; }
#     } else { ...the mirror... }
#
# Both the fuzz and the "if qu == 0 then 1" bump are ported below. The
# bump is the whole difference between a coverage-bearing interval and
# an off-by-one: at qu = 0 the lower bound would index diffs[0], and one
# step either side of the correct k gives an interval that reads as
# perfectly reasonable. It is the first red demonstration in v145.
#
# Arguments:
#   .v1#   - numeric vector, group 1
#   .v2#   - numeric vector, group 2
#   .level - confidence level as a proportion (e.g. 0.95, or a
#            correction's own level such as 1 - alpha/m)
#
# Output:
#   .estimate - median of the n1 * n2 cross-differences (v1 minus v2)
#   .low      - lower confidence bound, or undefined on refusal
#   .high     - upper confidence bound, or undefined on refusal
#   .method$  - "exact" or "normal approximation"; the SAME branch
#               @emlMannWhitneyU takes on the same two vectors
#   .error$   - error message, or "" if valid
#
# DEPENDENCY: @emlRankVector from eml-core-utilities.praat, as
# @emlMannWhitneyU has.
# ============================================================================

procedure emlHodgesLehmannTwoSample: .v1#, .v2#, .level
    .estimate = undefined
    .low = undefined
    .high = undefined
    .method$ = ""
    .error$ = ""

    .n1 = size (.v1#)
    .n2 = size (.v2#)
    .nTotal = .n1 + .n2
    .nDiff = .n1 * .n2

    if .n1 < 1
        .error$ = "Group 1 must have at least 1 observation"
    elsif .n2 < 1
        .error$ = "Group 2 must have at least 1 observation"
    elsif .level <= 0 or .level >= 1
        .error$ = "Confidence level must be between 0 and 1"
    else
        # --- The n1 * n2 cross-differences, ordered ---
        #
        # The fill is a pair loop because a vector this size has to be
        # built one product-index at a time -- Praat has no slice
        # assignment and no outer-difference primitive (probed: "w# [1..3]
        # = v#" does not parse on 6.6.30). The ORDERING, which is the
        # part that costs, is sort#.
        .diffs# = zero# (.nDiff)
        for .i from 1 to .n1
            .base = (.i - 1) * .n2
            for .j from 1 to .n2
                .diffs#[.base + .j] = .v1#[.i] - .v2#[.j]
            endfor
        endfor
        .sortedDiffs# = sort# (.diffs#)

        # --- The estimate: median of those differences ---
        if .nDiff mod 2 = 1
            .estimate = .sortedDiffs#[(.nDiff + 1) / 2]
        else
            .mid = .nDiff / 2
            .estimate = (.sortedDiffs#[.mid] + .sortedDiffs#[.mid + 1]) / 2
        endif

        # --- The branch gate, verbatim from @emlMannWhitneyU ---
        .combined# = zero# (.nTotal)
        for .i from 1 to .n1
            .combined#[.i] = .v1#[.i]
        endfor
        for .i from 1 to .n2
            .combined#[.n1 + .i] = .v2#[.i]
        endfor

        @emlRankVector: .combined#
        .hasTies = emlRankVector.hasTies

        # Exact iff n1 < 50 AND n2 < 50 AND no ties. R's wilcox.test uses
        # per-group sizes (not the combined total) and falls back to the
        # normal approximation whenever ties are present, because the
        # exact null distribution assumes untied integer ranks.
        # Nested ifs: Praat's "and" does not short-circuit.
        .useExact = 0
        if .n1 < 50
            if .n2 < 50
                if .hasTies = 0
                    .useExact = 1
                endif
            endif
        endif

        .alpha = 1 - .level

        if .useExact = 1
            # --- Exact path: a quantile of the DP null distribution ---
            .method$ = "exact"

            # ONE call, for the distribution, not for its tails. The .u1
            # argument is irrelevant to the counts: the DP is built over
            # every u regardless, and 0 is passed to say plainly that no
            # tail probability is being asked for here.
            @eml_mannWhitneyExactP: 0, .n1, .n2
            .total = eml_mannWhitneyExactP.total

            # qwilcox(alpha/2, n1, n2), ported with R's own fuzz and R's
            # own accumulation: 10 DBL_EPSILON subtracted from the
            # PROBABILITY, and the cumulative sum built in probability --
            # each count divided by the total as it is added, which is
            # what "p += cwilcox(q, mm, nn) / c" does and is not the same
            # rounding as summing counts and dividing once.
            #
            # Only R's "x <= 0.5" branch is ported because only it is
            # reachable: .level is validated into (0, 1) above, so
            # .alpha / 2 is strictly inside (0, 0.5) and the mirror
            # branch cannot be entered from here. .total stands for R's
            # choose(m + n, n) -- the same number by a different route,
            # and for n1 = n2 near 50 the count exceeds 2^53, so the two
            # agree to rounding rather than exactly. That matters only if
            # the cumulative probability lands within an ulp or two of
            # alpha/2, which is the same knife-edge R's own fuzz exists
            # for.
            .x = .alpha / 2 - 10 * 2.220446049250313e-16
            .k = 0
            .p = eml_mannWhitneyExactP.dp##[.n1 + 1, 1] / .total
            while .p < .x and .k < .nDiff
                .k = .k + 1
                .p = .p
                ... + eml_mannWhitneyExactP.dp##[.n1 + 1, .k + 1] / .total
            endwhile

            # if (qu == 0) qu <- 1
            if .k = 0
                .k = 1
            endif

            .low = .sortedDiffs#[.k]
            .high = .sortedDiffs#[.nDiff + 1 - .k]
        else
            # --- Normal approximation: R's z inversion, ported ---
            .method$ = "normal approximation"

            # mumin = min(x) - max(y) and mumax = max(x) - min(y) are the
            # smallest and largest cross-differences -- the same two
            # subtractions R performs, already in hand and already
            # ordered.
            .mumin = .sortedDiffs#[1]
            .mumax = .sortedDiffs#[.nDiff]

            @eml_hlTwoSampleW: .v1#, .v2#, .mumin, 1
            .wmin = eml_hlTwoSampleW.value
            @eml_hlTwoSampleW: .v1#, .v2#, .mumax, 1
            .wmax = eml_hlTwoSampleW.value

            if .wmin = undefined or .wmax = undefined
                # SIGMA.CI = 0: every observation in the combined sample
                # is tied, and there is no variance to standardise by. R
                # warns here and hands NaN to its own root finder, which
                # then fails on a missing value; this refuses in the
                # shape @emlTTestInterval refuses, with the outputs left
                # undefined and a reason given.
                .error$ = "Cannot compute a confidence interval when "
                ... + "every observation is tied"
            else
                # qnorm(alpha/2, lower.tail = FALSE) is invGaussQ(alpha/2);
                # qnorm(alpha/2) is its negation.
                .zq = invGaussQ (.alpha / 2)

                @eml_hlTwoSampleRoot: .v1#, .v2#, .zq, .mumin, .mumax,
                ... .wmin, .wmax, 1
                .low = eml_hlTwoSampleRoot.result

                @eml_hlTwoSampleRoot: .v1#, .v2#, - .zq, .mumin, .mumax,
                ... .wmin, .wmax, 1
                .high = eml_hlTwoSampleRoot.result
            endif
        endif
    endif
endproc


# ============================================================================
# INTERNAL HELPER: Exact p-value for Wilcoxon Signed-Rank via Subset-Sum DP
# ============================================================================
# Computes the exact null distribution of T+ (sum of positive ranks)
# under the no-tie assumption: ranks are integers 1, 2, ..., n.
#
# Uses dynamic programming to count subsets of {1,...,n} with each
# possible sum. Equivalent to 2^n enumeration but O(n * maxT) time
# and O(maxT) space.
#
# Input:
#   .tPlus    - observed T+ (may be non-integer when ties exist)
#   .n        - number of non-zero differences
#
# Output:
#   .pLeft    - P(T+ <= floor(tPlus)) under no-tie null
#   .pRight   - P(T+ >= ceiling(tPlus)) under no-tie null
#   .dp#      - the null distribution ITSELF, not merely its tails:
#               .dp# [s + 1] is the NUMBER of subsets of {1, ..., n}
#               summing to s, for s = 0 .. n(n+1)/2 -- R's csignrank(s, n)
#               at every s, in one vector.
#   .total    - 2^n, the number of sign patterns and the sum of that
#               vector. R's qsignrank does NOT divide by this; it
#               multiplies each count by f = exp(-n * M_LN2), which is a
#               DIFFERENT double from 1/2^n for most n (measured: they
#               differ for 51 of the first 60 n). A caller inverting this
#               distribution against R must use R's f, not this .total;
#               .total is exposed because the p-values above are formed
#               with it and a reader of one needs the other.
#
# .dp# AND .total ARE PART OF THE CONTRACT, not incidental internals.
# @emlHodgesLehmannPaired needs a QUANTILE of this same null distribution
# (the critical rank k behind the exact paired confidence interval),
# which no pair of tail probabilities can supply, and Fable's 26 August
# work order forbids building a second copy of the distribution to get
# it. So this procedure is the one place the T+ null distribution is
# computed, and the counts and their total are readable. Like every
# Praat procedure output they survive only until the next call: copy
# them on the following line.
#
# Note: The no-tie null distribution is standard (matches R wilcox.test
# and scipy wilcoxon exact). When ties exist in the absolute differences,
# the exact test is slightly conservative.
# ============================================================================

procedure eml_wilcoxonExactP: .tPlus, .n
    .maxT = .n * (.n + 1) / 2
    .total = 2 ^ .n

    # --- Cache: the DP table is keyed by .n alone (Fable's 26 August
    # ruling, item 4 -- the signed-rank half). @emlWilcoxonSignedRank
    # (p-value) and @emlHodgesLehmannPaired (critical rank) are two reads
    # of the SAME object for the same pair-of-conditions, and a
    # repeated-measures design with a common complete-case n calls this
    # again, with the same n, for every remaining pair. One build must
    # serve all of them.
    #
    # Same cache shape as @eml_mannWhitneyExactP above (see its comment
    # for the precedent this follows: eml-lmm.praat's indexed-matrix
    # family, and this plugin's existing variableExists guard idiom for a
    # persistent value's first read) -- keyed on one integer instead of
    # two, so the slot table is a single array rather than a pair of
    # them, and each slot's null-distribution vector sits at
    # .cacheDp'.slot'#.
    if variableExists ("eml_wilcoxonExactP.cacheCount") = 0
        .cacheCount = 0
    endif
    .cacheMax = 64

    .cacheHit = 0
    for .slot from 1 to .cacheCount
        if .cacheN[.slot] = .n
            .cacheHit = .slot
        endif
    endfor

    if .cacheHit > 0
        # --- Cache hit: this n's distribution was already built ---
        .dp# = .cacheDp'.cacheHit'#
    else
        .vecSize = floor (.maxT) + 1

        # DP: .dp#[s + 1] = number of subsets of {1,...,processed} with sum = s
        .dp# = zero# (.vecSize)
        .dp#[1] = 1

        for .rank from 1 to .n
            .newDp# = zero# (.vecSize)
            for .s from 0 to floor (.maxT)
                if .dp#[.s + 1] > 0
                    # Exclude this rank
                    .newDp#[.s + 1] = .newDp#[.s + 1] + .dp#[.s + 1]
                    # Include this rank
                    .sNew = .s + .rank
                    if .sNew <= floor (.maxT)
                        .newDp#[.sNew + 1] = .newDp#[.sNew + 1] + .dp#[.s + 1]
                    endif
                endif
            endfor
            .dp# = .newDp#
        endfor

        # --- Store for the next call sharing this n ---
        if .cacheCount < .cacheMax
            .cacheCount = .cacheCount + 1
            .cacheN[.cacheCount] = .n
            .cacheDp'.cacheCount'# = .dp#
        endif
    endif

    # Left tail: P(T+ <= floor(tPlus))
    .tFloor = floor (.tPlus)
    if .tFloor > floor (.maxT)
        .tFloor = floor (.maxT)
    endif
    if .tFloor < 0
        .tFloor = 0
    endif
    .cumLeft = 0
    for .s from 0 to .tFloor
        .cumLeft = .cumLeft + .dp#[.s + 1]
    endfor
    .pLeft = .cumLeft / .total

    # Right tail: P(T+ >= ceiling(tPlus))
    .tCeil = ceiling (.tPlus)
    if .tCeil > floor (.maxT)
        .tCeil = floor (.maxT)
    endif
    if .tCeil < 0
        .tCeil = 0
    endif
    .cumRight = 0
    for .s from .tCeil to floor (.maxT)
        .cumRight = .cumRight + .dp#[.s + 1]
    endfor
    .pRight = .cumRight / .total
endproc


# ============================================================================
# @emlWilcoxonSignedRank
# ============================================================================
# @emlCohenDz
# ============================================================================
# Cohen's d_z for a paired design: the standardised mean difference using the
# standard deviation OF THE DIFFERENCES, not of the raw scores.
#
#   d_z = mean(v1 - v2) / sd(v1 - v2)
#
# This is the effect size that belongs with a paired t-test, because it is
# built from the same quantity the test statistic is built from
# (t = d_z * sqrt(n)). It is NOT interchangeable with the matched-pairs
# rank-biserial r from @emlMatchedPairsR, which uses only the ranks of the
# differences and can sit near ceiling while d_z is moderate — that happens
# whenever changes are consistent in direction but variable in size.
#
# Also returns the correlation form r = t / sqrt(t^2 + df), for callers that
# prefer an r-scaled effect size under the parametric test.
#
# Arguments:
#   .v1#, .v2# — numeric vectors of equal length (pairs)
#
# Output:
#   .dz      — Cohen's d_z (undefined if n < 2 or sd of differences is 0)
#   .rFromT  — r derived from the paired t (undefined on the same conditions)
#   .n       — number of pairs
#   .error$  — error message, or "" if valid
# ============================================================================
procedure emlCohenDz: .v1#, .v2#
    .dz = undefined
    .rFromT = undefined
    .error$ = ""
    .n = size (.v1#)

    if .n <> size (.v2#)
        .error$ = "Paired vectors must be the same length."
    elsif .n < 2
        .error$ = "Cohen's d_z is undefined for fewer than 2 pairs."
    else
        .diff# = zero# (.n)
        for .i from 1 to .n
            .diff# [.i] = .v1# [.i] - .v2# [.i]
        endfor
        .sdDiff = stdev (.diff#)
        if .sdDiff = 0
            .error$ = "Cohen's d_z is undefined when all differences are"
            .error$ = .error$ + " identical (standard deviation is zero)."
        else
            .dz = mean (.diff#) / .sdDiff
            .df = .n - 1
            .t = .dz * sqrt (.n)
            .rFromT = .t / sqrt (.t * .t + .df)
        endif
    endif
endproc


# ============================================================================
# Wilcoxon signed-rank test for paired samples.
#
# Tests whether the distribution of paired differences is symmetric
# around zero. Nonparametric alternative to the paired t-test.
#
# Algorithm selection (matches R wilcox.test, paired form):
#   n_nonzero < 50 AND no ties AND no zero differences
#                    -> exact p-value via subset-sum DP
#                       (no-tie null distribution, standard)
#   otherwise        -> normal approximation with continuity correction
#                       and tie correction factor
#
# Zero differences are excluded before ranking (standard practice).
# T+ is computed from the actual (possibly tied) ranks of absolute
# differences. For the exact path, the p-value comes from the no-tie
# null distribution (matching R and scipy convention).
#
# DEPENDENCY: Requires @emlRankVector from eml-core-utilities.praat.
# The calling script must include utilities before inferential.
#
# Arguments:
#   .v1#   - numeric vector, condition 1
#   .v2#   - numeric vector, condition 2 (same length as v1#)
#   .tails - 1 (one-tailed) or 2 (two-tailed)
#
# Output:
#   .tPlus       - T+ (sum of ranks of positive differences)
#   .tMinus      - T- (sum of ranks of negative differences)
#   .p           - p-value for the requested alternative
#   .pGreater    - one-tailed p for H1: v1 > v2
#   .pLess       - one-tailed p for H1: v1 < v2
#   .alternative$ - "two-sided" or "greater" (the alternative .p refers to)
#   .n           - number of pairs (input length)
#   .nNonzero    - number of non-zero differences (used for test)
#   .nZero       - number of zero differences (excluded)
#   .hasTies     - 1 if the absolute differences contain ties, else 0
#   .method$     - "exact" or "normal approximation"
#   .z           - z statistic (approximation path only; undefined for exact)
#   .error$      - error message, or "" if valid
#
# One-tailed p (.tails = 1): the alternative is FIXED as H1: v1 > v2,
#   matching R's wilcox.test(v1, v2, paired = TRUE, alternative =
#   "greater"). A one-tailed test run in the wrong direction therefore
#   returns a p-value near 1, not near 0. For the opposite alternative,
#   read .pLess (or swap the arguments).
# ============================================================================

procedure emlWilcoxonSignedRank: .v1#, .v2#, .tails
    # Initialize outputs
    .tPlus = undefined
    .tMinus = undefined
    .p = undefined
    .pGreater = undefined
    .pLess = undefined
    .alternative$ = ""
    .nNonzero = 0
    .nZero = 0
    .hasTies = 0
    .method$ = ""
    .z = undefined
    .error$ = ""

    .n1 = size (.v1#)
    .n2 = size (.v2#)
    .n = .n1

    # --- Input validation ---
    if .n1 <> .n2
        .error$ = "Vectors must have equal length for paired test"
        .n = 0
    elsif .n < 1
        .error$ = "Need at least 1 pair"
    elsif .tails < 1 or .tails > 2
        .error$ = "tails must be 1 or 2"
    else
        # --- Compute differences and separate zeros ---
        .allDiffs# = zero# (.n)
        for .i from 1 to .n
            .allDiffs#[.i] = .v1#[.i] - .v2#[.i]
        endfor

        # Count non-zero diffs
        .nNonzero = 0
        for .i from 1 to .n
            if .allDiffs#[.i] <> 0
                .nNonzero = .nNonzero + 1
            endif
        endfor
        .nZero = .n - .nNonzero

        if .nNonzero = 0
            .error$ = "All differences are zero; cannot perform test"
        else
            # Extract non-zero diffs
            .nonzeroDiffs# = zero# (.nNonzero)
            .idx = 0
            for .i from 1 to .n
                if .allDiffs#[.i] <> 0
                    .idx = .idx + 1
                    .nonzeroDiffs#[.idx] = .allDiffs#[.i]
                endif
            endfor

            # Absolute values of non-zero diffs
            .absDiffs# = zero# (.nNonzero)
            for .i from 1 to .nNonzero
                .absDiffs#[.i] = abs (.nonzeroDiffs#[.i])
            endfor

            # Rank absolute differences (with average tie handling)
            @emlRankVector: .absDiffs#
            .ranks# = emlRankVector.ranks#
            .hasTies = emlRankVector.hasTies

            # Compute T+ and T-
            .tPlus = 0
            .tMinus = 0
            for .i from 1 to .nNonzero
                if .nonzeroDiffs#[.i] > 0
                    .tPlus = .tPlus + .ranks#[.i]
                else
                    .tMinus = .tMinus + .ranks#[.i]
                endif
            endfor

            .expectedT = .nNonzero * (.nNonzero + 1) / 4

            if .tails = 2
                .alternative$ = "two-sided"
            else
                .alternative$ = "greater"
            endif

            # Exact iff n_nonzero < 50 AND no ties AND no zero differences.
            # R's wilcox.test falls back to the normal approximation as soon
            # as ties or zeroes are present, because the exact null
            # distribution assumes untied integer ranks over all n pairs.
            # Nested ifs: Praat's "and" does not short-circuit.
            .useExact = 0
            if .nNonzero < 50
                if .hasTies = 0
                    if .nZero = 0
                        .useExact = 1
                    endif
                endif
            endif

            if .useExact = 1
                # --- Exact path (subset-sum DP over the no-tie null) ---
                .method$ = "exact"

                @eml_wilcoxonExactP: .tPlus, .nNonzero

                # pLeft = P(T+ <= tPlus) is the lower tail (v1 < v2);
                # pRight = P(T+ >= tPlus) is the upper tail (v1 > v2).
                .pLess = eml_wilcoxonExactP.pLeft
                .pGreater = eml_wilcoxonExactP.pRight

                if .tails = 2
                    .pMin = .pLess
                    if .pGreater < .pMin
                        .pMin = .pGreater
                    endif
                    .p = 2 * .pMin
                    if .p > 1
                        .p = 1
                    endif
                else
                    # One-tailed: fixed alternative H1 v1 > v2
                    .p = .pGreater
                endif
            else
                # --- Normal approximation path ---
                .method$ = "normal approximation"

                .varT = .nNonzero * (.nNonzero + 1) * (2 * .nNonzero + 1) / 24

                # Tie correction: subtract sum(t^3 - t)/48 for each tie group
                if .hasTies = 1
                    # Sort ranks to find tie groups
                    .sortedRanks# = zero# (.nNonzero)
                    for .i from 1 to .nNonzero
                        .sortedRanks#[.i] = .ranks#[.i]
                    endfor
                    # Insertion sort
                    for .i from 2 to .nNonzero
                        .key = .sortedRanks#[.i]
                        .j = .i - 1
                        while .j >= 1 and .sortedRanks#[.j] > .key
                            .sortedRanks#[.j + 1] = .sortedRanks#[.j]
                            .j = .j - 1
                        endwhile
                        .sortedRanks#[.j + 1] = .key
                    endfor

                    # Count consecutive equal ranks
                    .tieCorrection = 0
                    .i = 1
                    while .i <= .nNonzero
                        .tieSize = 1
                        while .i + .tieSize <= .nNonzero and .sortedRanks#[.i + .tieSize] = .sortedRanks#[.i]
                            .tieSize = .tieSize + 1
                        endwhile
                        if .tieSize > 1
                            .tieCorrection = .tieCorrection + (.tieSize * .tieSize * .tieSize - .tieSize)
                        endif
                        .i = .i + .tieSize
                    endwhile

                    .varT = .varT - .tieCorrection / 48
                endif

                if .varT <= 0
                    # Degenerate case
                    .p = 1
                    .z = 0
                    .pGreater = 1
                    .pLess = 1
                else
                    .sdT = sqrt (.varT)
                    .zRaw = .tPlus - .expectedT

                    # Continuity correction
                    if .zRaw > 0
                        .zNum = .zRaw - 0.5
                    elsif .zRaw < 0
                        .zNum = .zRaw + 0.5
                    else
                        .zNum = 0
                    endif

                    .z = .zNum / .sdT

                    # Directional continuity corrections, as in R's
                    # wilcox.test: "greater" subtracts 0.5, "less" adds 0.5.
                    .zGreater = (.zRaw - 0.5) / .sdT
                    .zLess = (.zRaw + 0.5) / .sdT
                    .pGreater = gaussQ (.zGreater)
                    .pLess = gaussQ (- .zLess)

                    if .tails = 2
                        .p = 2 * gaussQ (abs (.z))
                    else
                        # One-tailed: fixed alternative H1 v1 > v2
                        .p = .pGreater
                    endif
                endif
            endif
        endif
    endif
endproc


# ============================================================================
# INTERNAL HELPER: @eml_hlPairedW  — R's one-sample W(d), ported
# ============================================================================
# R 4.3.3, src/library/stats/R/wilcox.test.R, wilcox.test.default,
# ONE-SAMPLE (and therefore paired) asymptotic branch:
#
#     W <- function(d) {
#         xd <- x - d
#         xd <- xd[xd != 0]
#         nx <- length(xd)
#         dr <- rank(abs(xd))
#         zd <- sum(dr[xd > 0]) - nx * (nx + 1)/4
#         NTIES.CI <- table(dr)
#         SIGMA.CI <- sqrt(nx * (nx + 1) * (2 * nx + 1) / 24
#                          - sum(NTIES.CI^3 - NTIES.CI) / 48)
#         if (SIGMA.CI == 0) warning(...)
#         CORRECTION.CI <- sign(zd) * 0.5
#         (zd - CORRECTION.CI) / SIGMA.CI
#     }
#
# THIS IS NOT @eml_hlTwoSampleW IN ONE-SAMPLE CLOTHES, and the three
# differences are each capable of producing a plausible wrong number:
#
#   * THE ZEROS ARE DROPPED AGAIN AT EVERY d. `xd <- xd[xd != 0]` runs
#     inside W, not once outside it, so nx is a function of d: at
#     d = min(x) the smallest observation becomes an exact zero and
#     leaves, and nx is one smaller there than it is in the middle of
#     the interval. Hoisting the strip out of the loop would change
#     Wmumin and Wmumax, which are the two values the bracket and the
#     alpha-doubling loop are decided on.
#   * THE RANKS ARE RANKS OF |xd|, not of xd, and only the positive
#     xd contribute to the rank sum. That is the signed-rank statistic
#     T+, not a rank sum over a combined sample.
#   * SIGMA.CI DIVIDES THE TIE CORRECTION BY 48, where the two-sample
#     form divides by n(n-1) inside a different expression entirely.
#
# sum(NTIES.CI^3 - NTIES.CI) is exactly @emlRankVector's
# .tieCorrectionSum (singleton groups contribute t^3 - t = 0), which is
# why the ranking is done through that procedure rather than a second
# ranker written here -- the same reason @eml_hlTwoSampleW gives.
#
# .correct exists for the same reason it exists on the two-sample
# helper: R turns the continuity correction off for ONE call, the
# uniroot that produces its own point estimate. This plugin does not
# take that path -- Fable's work order pins the estimate to the median
# of the Walsh averages on both branches -- so every call from this
# file passes .correct = 1, and the parameter is kept so the ported
# shape is the shape R has.
#
# Input:
#   .x#      - the sample (here: the non-zero paired differences, R's x)
#   .d       - the shift being tested
#   .correct - 1 to apply the continuity correction, 0 not to
#
# Output:
#   .value  - W(d), or undefined when SIGMA.CI is zero or every
#             observation equals .d (R warns and returns NaN)
# ============================================================================

procedure eml_hlPairedW: .x#, .d, .correct
    .n = size (.x#)

    # xd <- x - d;  xd <- xd[xd != 0]
    .keep# = zero# (.n)
    .nx = 0
    for .i from 1 to .n
        .shift = .x#[.i] - .d
        if .shift <> 0
            .nx = .nx + 1
            .keep#[.nx] = .shift
        endif
    endfor

    if .nx = 0
        # Every observation equals d. R's nx is 0, SIGMA.CI is sqrt(0),
        # and the division is 0/0.
        .value = undefined
    else
        .xd# = zero# (.nx)
        .absXd# = zero# (.nx)
        for .i from 1 to .nx
            .xd#[.i] = .keep#[.i]
            .absXd#[.i] = abs (.keep#[.i])
        endfor

        @emlRankVector: .absXd#
        .ranks# = emlRankVector.ranks#
        .tieSum = emlRankVector.tieCorrectionSum

        # zd <- sum(dr[xd > 0]) - nx * (nx + 1)/4
        .rankSum = 0
        for .i from 1 to .nx
            if .xd#[.i] > 0
                .rankSum = .rankSum + .ranks#[.i]
            endif
        endfor
        .zd = .rankSum - .nx * (.nx + 1) / 4

        # CORRECTION.CI <- sign(zd) * 0.5   (two-sided; sign(0) is 0 in R)
        .correction = 0
        if .correct = 1
            if .zd > 0
                .correction = 0.5
            elsif .zd < 0
                .correction = -0.5
            endif
        endif

        .sigma = sqrt (.nx * (.nx + 1) * (2 * .nx + 1) / 24 - .tieSum / 48)

        if .sigma = 0
            .value = undefined
        else
            .value = (.zd - .correction) / .sigma
        endif
    endif
endproc


# ============================================================================
# @emlHodgesLehmannPaired
# ============================================================================
# The Hodges-Lehmann shift estimate for two PAIRED samples, and its
# confidence interval -- the location counterpart of the Wilcoxon
# signed-rank test, the way a mean difference and its t interval are the
# counterpart of the paired t test. Specified by Fable's 26 August work
# order (docs/WORK_ORDER_INTERVALS_2026-08-26.md, item 4).
#
# THE ESTIMATE IS THE MEDIAN OF THE WALSH AVERAGES, and Walsh averages
# are not cross-differences. For the n paired differences
# d[i] = v1[i] - v2[i], they are (d[i] + d[j]) / 2 for every i <= j --
# n(n+1)/2 values, INCLUDING the n cases i = j, which are the d[i]
# themselves. The two-sample form of this procedure takes n1 * n2
# differences ACROSS two samples; this one takes n(n+1)/2 averages
# WITHIN one derived sample. Substituting either set for the other
# yields a number of the right magnitude and the wrong value, which is
# why the order names the set rather than the estimator. On an even
# count the median is the mean of the middle two, as R's median() is,
# and the ordering is Praat's NATIVE sort#, never a script sort.
#
# THE BRANCH IS THE p-VALUE'S BRANCH. The gate below -- n_nonzero < 50
# AND no ties AND no zero differences, as three nested ifs because
# Praat's "and" does not short-circuit -- is copied verbatim from
# @emlWilcoxonSignedRank above, which copied it from R's wilcox.test.
# It is not re-derived here and it must not drift: an interval computed
# on the exact null distribution printed beside a p-value computed on
# the normal approximation is a report that contradicts itself, and
# neither number looks wrong on its own. v145 asserts the two copies
# are one text.
#
#   exact:  the critical rank k is a QUANTILE of the T+ null
#           distribution, taken from the DP in @eml_wilcoxonExactP --
#           the same distribution the exact p-value is read off, read
#           once, never rebuilt. The bounds are the k-th smallest and
#           k-th largest Walsh averages, which is R's
#           c(diffs[qu], diffs[ql + 1]).
#
#   normal approximation: R's continuity-corrected z inversion in its
#           ONE-SAMPLE form. See @eml_hlPairedW above and @eml_hlZeroin,
#           which is the two-sample port's zeroin reused rather than a
#           second copy of Brent's method.
#
# THE CRITICAL RANK, in full, from R 4.3.3's exact one-sample branch:
#
#     diffs <- outer(x, x, `+`)
#     diffs <- sort(diffs[!lower.tri(diffs)]) / 2
#     qu <- qsignrank(alpha / 2, n)
#     if (qu == 0) qu <- 1
#     ql <- n*(n+1)/2 - qu
#     c(diffs[qu], diffs[ql+1])
#
# QSIGNRANK IS NOT QWILCOX WITH DIFFERENT COUNTS, and the difference is
# in the arithmetic, not only in the distribution. R 4.3.3,
# src/nmath/signrank.c:
#
#     f = exp(- n * M_LN2);
#     p = 0; q = 0;
#     if (x <= 0.5) {
#         x = x - 10 * DBL_EPSILON;
#         for(;;) { p += csignrank(q, nn) * f; if (p >= x) break; q++; }
#     } else { ...the mirror... }
#
# qwilcox divides each count by choose(m+n, n); qsignrank MULTIPLIES
# each count by f = exp(-n * M_LN2). Those are different roundings, and
# f is not the same double as 1/2^n: measured here, exp(-n*ln 2) differs
# from 2^-n for 51 of the first 60 n. The port below multiplies by f,
# with M_LN2 written as the literal C uses, so the accumulation is R's
# accumulation and not an algebraic equivalent of it. The fuzz -- ten
# DBL_EPSILON subtracted from the PROBABILITY, not from a count -- is
# the same in both, and only R's "x <= 0.5" branch is ported because
# .level is validated into (0, 1) and alpha/2 is therefore strictly
# inside (0, 0.5).
#
# The "if qu == 0 then 1" bump is ported for the reason it is on the
# two-sample side: at qu = 0 the lower bound would index diffs[0], and
# one step either side of the correct k gives an interval that reads as
# perfectly reasonable. It is a red demonstration in v145.
#
# WHAT THE APPROXIMATION BRANCH DOES THAT THE TWO-SAMPLE ONE DOES NOT.
# R's one-sample root() has NO endpoint early-returns; in their place,
# before any root-finding, it WIDENS alpha until the requested interval
# is bracketable:
#
#     repeat {
#         mindiff <- Wmumin - qnorm(alpha/2, lower.tail = FALSE)
#         maxdiff <- Wmumax - qnorm(alpha/2)
#         if (mindiff < 0 || maxdiff > 0) alpha <- alpha*2 else break
#     }
#     if (alpha >= 1 || 1 - conf.level < alpha*0.75) warning(...)
#     if (alpha < 1) { l <- root(...); u <- root(...) } else rep(median(x), 2)
#
# That loop is part of the ANSWER, not a guard: when it fires, both
# bounds come back at a wider level than was asked for, and when alpha
# reaches 1 the "interval" is the median of the differences twice. The
# two-sample form has no such loop and this one has no early returns;
# reusing @eml_hlTwoSampleRoot here would silently substitute one
# structure for the other.
#
# Arguments:
#   .v1#   - numeric vector, condition 1
#   .v2#   - numeric vector, condition 2 (same length as v1#)
#   .level - confidence level as a proportion (e.g. 0.95, or a
#            correction's own level such as 1 - alpha/m)
#
# Output:
#   .estimate - median of the n(n+1)/2 Walsh averages of v1 - v2
#   .low      - lower confidence bound, or undefined on refusal
#   .high     - upper confidence bound, or undefined on refusal
#   .method$  - "exact" or "normal approximation"; the SAME branch
#               @emlWilcoxonSignedRank takes on the same two vectors
#   .error$   - error message, or "" if valid
#
# DEPENDENCY: @emlRankVector from eml-core-utilities.praat, as
# @emlWilcoxonSignedRank has.
# ============================================================================

procedure emlHodgesLehmannPaired: .v1#, .v2#, .level
    .estimate = undefined
    .low = undefined
    .high = undefined
    .method$ = ""
    .error$ = ""

    .n1 = size (.v1#)
    .n2 = size (.v2#)
    .n = .n1

    # --- Input validation, in @emlWilcoxonSignedRank's own words ---
    if .n1 <> .n2
        .error$ = "Vectors must have equal length for paired test"
        .n = 0
    elsif .n < 1
        .error$ = "Need at least 1 pair"
    elsif .level <= 0 or .level >= 1
        .error$ = "Confidence level must be between 0 and 1"
    else
        # --- The differences, and the Walsh averages over ALL of them ---
        #
        # THE ESTIMATE IS COMPUTED BEFORE ANY BRANCH AND SURVIVES EVERY
        # REFUSAL BELOW, the way the two-sample procedure's median
        # cross-difference does: a sample whose interval cannot be built
        # still HAS a median Walsh average, and returning it with the
        # bounds undefined says more than returning nothing.
        .allDiffs# = zero# (.n)
        for .i from 1 to .n
            .allDiffs#[.i] = .v1#[.i] - .v2#[.i]
        endfor

        # The fill is a pair loop because Praat has no outer-sum
        # primitive and no slice assignment (probed on 6.6.30). The
        # ORDERING, which is the part that costs, is sort#.
        .nWalsh = .n * (.n + 1) / 2
        .walsh# = zero# (.nWalsh)
        .w = 0
        for .i from 1 to .n
            for .j from .i to .n
                .w = .w + 1
                .walsh#[.w] = (.allDiffs#[.i] + .allDiffs#[.j]) / 2
            endfor
        endfor
        .sortedWalsh# = sort# (.walsh#)

        if .nWalsh mod 2 = 1
            .estimate = .sortedWalsh#[(.nWalsh + 1) / 2]
        else
            .mid = .nWalsh / 2
            .estimate = (.sortedWalsh#[.mid] + .sortedWalsh#[.mid + 1]) / 2
        endif

        # Count non-zero diffs
        .nNonzero = 0
        for .i from 1 to .n
            if .allDiffs#[.i] <> 0
                .nNonzero = .nNonzero + 1
            endif
        endfor
        .nZero = .n - .nNonzero

        if .nNonzero = 0
            .error$ = "All differences are zero; cannot compute an interval"
        else
            # Extract non-zero diffs. R strips the zeroes ONCE, before
            # n is taken, and every later use of "x" in its confidence
            # interval means this stripped vector -- the branch gate's
            # n, qsignrank's n, mumin, mumax and median(x) alike.
            .nonzeroDiffs# = zero# (.nNonzero)
            .idx = 0
            for .i from 1 to .n
                if .allDiffs#[.i] <> 0
                    .idx = .idx + 1
                    .nonzeroDiffs#[.idx] = .allDiffs#[.i]
                endif
            endfor

            .absDiffs# = zero# (.nNonzero)
            for .i from 1 to .nNonzero
                .absDiffs#[.i] = abs (.nonzeroDiffs#[.i])
            endfor

            @emlRankVector: .absDiffs#
            .hasTies = emlRankVector.hasTies

            # Exact iff n_nonzero < 50 AND no ties AND no zero differences.
            # R's wilcox.test falls back to the normal approximation as soon
            # as ties or zeroes are present, because the exact null
            # distribution assumes untied integer ranks over all n pairs.
            # Nested ifs: Praat's "and" does not short-circuit.
            .useExact = 0
            if .nNonzero < 50
                if .hasTies = 0
                    if .nZero = 0
                        .useExact = 1
                    endif
                endif
            endif

            .alpha = 1 - .level

            if .useExact = 1
                # --- Exact path: a quantile of the DP null distribution ---
                .method$ = "exact"

                # The gate above guarantees .nZero = 0 on this branch, so
                # the Walsh set built over ALL n differences IS R's
                # `diffs` over its zero-stripped x, element for element,
                # and .nWalsh = .nNonzero * (.nNonzero + 1) / 2. The
                # bounds may therefore index .sortedWalsh# directly.
                #
                # ONE call, for the distribution, not for its tails. The
                # .tPlus argument is irrelevant to the counts: the DP is
                # built over every sum regardless, and 0 is passed to say
                # plainly that no tail probability is being asked for.
                @eml_wilcoxonExactP: 0, .nNonzero
                .counts# = eml_wilcoxonExactP.dp#
                .maxT = .nNonzero * (.nNonzero + 1) / 2

                # qsignrank(alpha/2, n), ported with R's own fuzz and R's
                # own accumulation: 10 DBL_EPSILON subtracted from the
                # PROBABILITY, and each count MULTIPLIED by
                # f = exp(-n * M_LN2). M_LN2 is written as the literal C
                # uses rather than as ln (2) so the factor does not
                # depend on which library computed the logarithm.
                .f = exp (- .nNonzero * 0.69314718055994530942)
                .x = .alpha / 2 - 10 * 2.220446049250313e-16
                .k = 0
                .p = .counts#[1] * .f
                while .p < .x and .k < .maxT
                    .k = .k + 1
                    .p = .p + .counts#[.k + 1] * .f
                endwhile

                # if (qu == 0) qu <- 1
                if .k = 0
                    .k = 1
                endif

                .low = .sortedWalsh#[.k]
                .high = .sortedWalsh#[.nWalsh + 1 - .k]
            else
                # --- Normal approximation: R's z inversion, ported ---
                .method$ = "normal approximation"

                # mumin = min(x) and mumax = max(x) over the ZERO-STRIPPED
                # differences -- the raw endpoints of the sample, not of
                # the Walsh set. One native sort supplies both, and the
                # median R falls back on when alpha reaches 1.
                .sortedNz# = sort# (.nonzeroDiffs#)
                .mumin = .sortedNz#[1]
                .mumax = .sortedNz#[.nNonzero]

                @eml_hlPairedW: .nonzeroDiffs#, .mumin, 1
                .wmin = eml_hlPairedW.value
                # R computes W(mumax) only when W(mumin) is finite, so
                # that its "all zero or tied" warning is issued once.
                .wmax = undefined
                if .wmin <> undefined
                    @eml_hlPairedW: .nonzeroDiffs#, .mumax, 1
                    .wmax = eml_hlPairedW.value
                endif

                if .wmin = undefined or .wmax = undefined
                    # SIGMA.CI = 0: every non-zero difference has the same
                    # magnitude and the statistic has no variance to
                    # standardise by. R warns and hands NaN to its own
                    # root finder; this refuses in the shape
                    # @emlHodgesLehmannTwoSample refuses, with the bounds
                    # left undefined, a reason given, and the estimate
                    # above still returned.
                    .error$ = "Cannot compute a confidence interval when "
                    ... + "every difference is zero or tied"
                else
                    # R's alpha-widening loop, ported. qnorm(a/2,
                    # lower.tail = FALSE) is invGaussQ(a/2) and qnorm(a/2)
                    # is its negation, so maxdiff is .wmax + that same
                    # quantile.
                    #
                    # THE LOOP TERMINATES AT alpha = 2 IN R, where
                    # qnorm(1, lower.tail = FALSE) is -infinity and both
                    # comparisons stop being satisfied. It is stopped at
                    # the same place here rather than evaluating
                    # invGaussQ at 1. A sample that would double PAST 2
                    # (possible only when a single non-zero difference
                    # survives) makes R evaluate qnorm above 1, which is
                    # NaN, and R then fails on `if (NA)`; this returns
                    # R's alpha >= 1 answer instead of failing, and the
                    # divergence is recorded because R has no answer
                    # there to agree with.
                    .alphaUsed = .alpha
                    .bracketed = 0
                    while .bracketed = 0 and .alphaUsed < 2
                        .zTry = invGaussQ (.alphaUsed / 2)
                        .minDiff = .wmin - .zTry
                        .maxDiff = .wmax + .zTry
                        if .minDiff < 0 or .maxDiff > 0
                            .alphaUsed = .alphaUsed * 2
                        else
                            .bracketed = 1
                        endif
                    endwhile

                    if .alphaUsed < 1
                        .zq = invGaussQ (.alphaUsed / 2)

                        # root(zq): a plain uniroot over [mumin, mumax]
                        # with the endpoint values already in hand. No
                        # early returns -- see the header.
                        .empty# = zero# (0)
                        @eml_hlZeroin: 2, .nonzeroDiffs#, .empty#, .mumin,
                        ... .mumax, .wmin - .zq, .wmax - .zq, .zq,
                        ... 1e-4, 1000, 1
                        .low = eml_hlZeroin.root

                        @eml_hlZeroin: 2, .nonzeroDiffs#, .empty#, .mumin,
                        ... .mumax, .wmin + .zq, .wmax + .zq, - .zq,
                        ... 1e-4, 1000, 1
                        .high = eml_hlZeroin.root
                    else
                        # rep(median(x), 2): the requested level cannot be
                        # achieved at all, and R returns the median of the
                        # differences -- NOT of the Walsh averages -- as
                        # both bounds.
                        if .nNonzero mod 2 = 1
                            .medNz = .sortedNz#[(.nNonzero + 1) / 2]
                        else
                            .midNz = .nNonzero / 2
                            .medNz = (.sortedNz#[.midNz]
                            ... + .sortedNz#[.midNz + 1]) / 2
                        endif
                        .low = .medNz
                        .high = .medNz
                    endif
                endif
            endif
        endif
    endif
endproc



# ============================================================================
# @emlRankBiserialR
# ============================================================================
# Rank-biserial correlation: effect size for Mann-Whitney U test.
#
# Measures the degree of overlap between two independent groups.
# Computed as the directed rank-biserial correlation (Wendt 1972,
# Kerby 2014):
#
#   r = (U1 - U2) / (n1 * n2)
#
# where U1 and U2 are the Mann-Whitney U statistics for groups 1 and 2.
#
# Interpretation:
#   r = +1  — complete separation, group 1 > group 2
#   r =  0  — no difference (complete overlap)
#   r = -1  — complete separation, group 1 < group 2
#
# DEPENDENCY: Requires @emlMannWhitneyU (this file) and @emlRankVector
# from eml-core-utilities.praat.
#
# Arguments:
#   .v1#   - numeric vector, group 1
#   .v2#   - numeric vector, group 2
#   .tails - 1 (one-tailed) or 2 (two-tailed) — controls p from MWU
#
# Output:
#   .r       - rank-biserial correlation (range -1 to +1)
#   .u1      - U statistic for group 1 (passthrough from MWU)
#   .u2      - U statistic for group 2 (passthrough from MWU)
#   .p       - p-value (passthrough from MWU)
#   .n1      - size of group 1
#   .n2      - size of group 2
#   .method$ - "exact" or "normal approximation" (from MWU)
#   .error$  - error message, or "" if valid
#
# Note: r is always directed regardless of .tails. The .tails parameter
# only affects the p-value computation within the internal MWU call.
# ============================================================================

procedure emlRankBiserialR: .v1#, .v2#, .tails
    # Initialize outputs
    .r = undefined
    .u1 = undefined
    .u2 = undefined
    .p = undefined
    .method$ = ""
    .error$ = ""

    .n1 = size (.v1#)
    .n2 = size (.v2#)

    # Validate .tails here as well as in the inner test, so that a bad
    # value is reported without running the test.
    if .tails < 1 or .tails > 2
        .error$ = "tails must be 1 or 2"
    endif

    if .error$ = ""
        # Run Mann-Whitney U internally
        @emlMannWhitneyU: .v1#, .v2#, .tails
        .error$ = emlMannWhitneyU.error$
    endif

    if .error$ <> ""
        .r = undefined
    else
        # Pass through MWU outputs
        .u1 = emlMannWhitneyU.u1
        .u2 = emlMannWhitneyU.u2
        .p = emlMannWhitneyU.p
        .n1 = emlMannWhitneyU.n1
        .n2 = emlMannWhitneyU.n2
        .method$ = emlMannWhitneyU.method$

        # Rank-biserial r (directed)
        .r = (.u1 - .u2) / (.n1 * .n2)
    endif
endproc


# ============================================================================
# @emlMatchedPairsR
# ============================================================================
# Matched-pairs rank-biserial correlation: effect size for the Wilcoxon
# signed-rank test.
#
# Two effect size measures are provided:
#
# 1. T-based r (always available):
#    r = (T+ - T-) / S
#    where S = n_nonzero * (n_nonzero + 1) / 2
#    This is the "simple difference formula" (Kerby 2014): the
#    proportion of favorable ranks minus unfavorable ranks.
#
# 2. Z-based r (approximation path only, Rosenthal 1991):
#    rZ = z / sqrt(n_nonzero)
#    Only meaningful when the normal approximation is used
#    (n_nonzero >= 50). Set to undefined for the exact path.
#
# Interpretation (both measures):
#   r = +1  — all differences favor v1 > v2
#   r =  0  — balanced (no directional effect)
#   r = -1  — all differences favor v2 > v1
#
# DEPENDENCY: Requires @emlWilcoxonSignedRank (this file) and
# @emlRankVector from eml-core-utilities.praat.
#
# Arguments:
#   .v1#   - numeric vector, condition 1
#   .v2#   - numeric vector, condition 2 (same length as v1#)
#   .tails - 1 (one-tailed) or 2 (two-tailed) — controls p
#
# Output:
#   .r        - T-based rank-biserial r (range -1 to +1; always available)
#   .rZ       - Z-based r (Rosenthal 1991; undefined for exact path)
#   .tPlus    - T+ (passthrough from Wilcoxon)
#   .tMinus   - T- (passthrough from Wilcoxon)
#   .p        - p-value (passthrough from Wilcoxon)
#   .n        - number of pairs (input length)
#   .nNonzero - non-zero differences (used for test)
#   .nZero    - zero differences (excluded)
#   .method$  - "exact" or "normal approximation" (from Wilcoxon)
#   .error$   - error message, or "" if valid
# ============================================================================

procedure emlMatchedPairsR: .v1#, .v2#, .tails
    # Initialize outputs
    .r = undefined
    .rZ = undefined
    .tPlus = undefined
    .tMinus = undefined
    .p = undefined
    .nNonzero = 0
    .nZero = 0
    .method$ = ""
    .error$ = ""

    .n = size (.v1#)

    # Validate .tails here as well as in the inner test, so that a bad
    # value is reported without running the test.
    if .tails < 1 or .tails > 2
        .error$ = "tails must be 1 or 2"
    endif

    if .error$ = ""
        # Run Wilcoxon signed-rank internally
        @emlWilcoxonSignedRank: .v1#, .v2#, .tails
        .error$ = emlWilcoxonSignedRank.error$
        .n = emlWilcoxonSignedRank.n
    endif

    if .error$ <> ""
        .r = undefined
    else
        # Pass through Wilcoxon outputs
        .tPlus = emlWilcoxonSignedRank.tPlus
        .tMinus = emlWilcoxonSignedRank.tMinus
        .p = emlWilcoxonSignedRank.p
        .n = emlWilcoxonSignedRank.n
        .nNonzero = emlWilcoxonSignedRank.nNonzero
        .nZero = emlWilcoxonSignedRank.nZero
        .method$ = emlWilcoxonSignedRank.method$

        # T-based r (directed, Kerby 2014)
        .sMax = .nNonzero * (.nNonzero + 1) / 2
        .r = (.tPlus - .tMinus) / .sMax

        # Z-based r (Rosenthal 1991) — approximation path only
        if .method$ = "normal approximation"
            .rZ = emlWilcoxonSignedRank.z / sqrt (.nNonzero)
        else
            .rZ = undefined
        endif
    endif
endproc


# ============================================================================
# @emlBonferroni
# ============================================================================
# Bonferroni correction for multiple comparisons.
#
# Each p-value is multiplied by the number of comparisons k, capped at 1.0.
# The most conservative standard correction; controls family-wise error rate.
#
# Undefined p-values are handled as R's p.adjust handles NA: they are
# excluded from the comparison count k and returned as undefined in
# their original positions.
#
# Arguments:
#   .pValues#  - vector of raw p-values (elements may be undefined)
#
# Output:
#   .adjusted#  - vector of adjusted p-values (same order and length as
#                 input; undefined where the input was undefined)
#   .k          - number of comparisons actually adjusted (defined inputs)
#   .nInput     - length of the input vector
#   .nUndefined - number of undefined input p-values
#   .error$     - error message, or "" if valid
# ============================================================================

procedure emlBonferroni: .pValues#
    .error$ = ""
    .nInput = size (.pValues#)
    .adjusted# = zero# (.nInput)

    # k counts only defined p-values, matching R's p.adjust, which drops
    # NA from n and returns NA in the NA positions.
    .k = 0
    for .i from 1 to .nInput
        if .pValues# [.i] <> undefined
            .k = .k + 1
        endif
    endfor
    .nUndefined = .nInput - .k

    if .nInput = 0
        .error$ = "Empty p-value vector."
    elif .k = 0
        .error$ = "All p-values are undefined."
        for .i from 1 to .nInput
            .adjusted# [.i] = undefined
        endfor
    else
        for .i from 1 to .nInput
            if .pValues# [.i] <> undefined
                .val = .pValues# [.i] * .k
                if .val > 1
                    .val = 1
                endif
                .adjusted# [.i] = .val
            else
                .adjusted# [.i] = undefined
            endif
        endfor
    endif
endproc


# ============================================================================
# @emlHolm
# ============================================================================
# Holm step-down correction for multiple comparisons (Holm 1979).
#
# Less conservative than Bonferroni while still controlling family-wise
# error rate. Procedure:
#   1. Sort p-values ascending
#   2. Multiply p[i] by (k - i + 1) where i is the ascending rank
#   3. Enforce monotonicity via running maximum (step-down)
#   4. Cap at 1.0
#   5. Return in original input order
#
# Undefined p-values are handled as R's p.adjust handles NA: they are
# excluded from the comparison count k and returned as undefined in
# their original positions.
#
# DEPENDENCY: Requires @emlSortWithIndex from eml-core-utilities.praat.
#
# Arguments:
#   .pValues#  - vector of raw p-values (elements may be undefined)
#
# Output:
#   .adjusted#  - vector of adjusted p-values (same order and length as
#                 input; undefined where the input was undefined)
#   .k          - number of comparisons actually adjusted (defined inputs)
#   .nInput     - length of the input vector
#   .nUndefined - number of undefined input p-values
#   .error$     - error message, or "" if valid
# ============================================================================

procedure emlHolm: .pValues#
    .error$ = ""
    .nInput = size (.pValues#)
    .adjusted# = zero# (.nInput)

    # k counts only defined p-values, matching R's p.adjust, which drops
    # NA from n and returns NA in the NA positions.
    .k = 0
    for .i from 1 to .nInput
        if .pValues# [.i] <> undefined
            .k = .k + 1
        endif
    endfor
    .nUndefined = .nInput - .k

    if .nInput = 0
        .error$ = "Empty p-value vector."
    elif .k = 0
        .error$ = "All p-values are undefined."
        for .i from 1 to .nInput
            .adjusted# [.i] = undefined
        endfor
    else
        # Compact the defined p-values, remembering their source positions
        .defined# = zero# (.k)
        .source# = zero# (.k)
        .j = 0
        for .i from 1 to .nInput
            if .pValues# [.i] <> undefined
                .j = .j + 1
                .defined# [.j] = .pValues# [.i]
                .source# [.j] = .i
            else
                .adjusted# [.i] = undefined
            endif
        endfor

        if .k = 1
            .adjusted# [.source# [1]] = .defined# [1]
        else
            # Sort ascending, track original indices
            @emlSortWithIndex: .defined#
            .sortedP# = emlSortWithIndex.sorted#
            .origIdx# = emlSortWithIndex.indices#

            # Step-down: multiply by (k - rank + 1), enforce running max
            .runningMax = 0
            for .i from 1 to .k
                .val = .sortedP# [.i] * (.k - .i + 1)
                if .val > .runningMax
                    .runningMax = .val
                endif
                if .runningMax > 1
                    .runningMax = 1
                endif
                # Map back to original position
                .origPos = .source# [.origIdx# [.i]]
                .adjusted# [.origPos] = .runningMax
            endfor
        endif
    endif
endproc


# ============================================================================
# @emlBenjaminiHochberg
# ============================================================================
# Benjamini-Hochberg step-up correction for multiple comparisons (1995).
#
# Controls the false discovery rate (FDR) rather than family-wise error
# rate. Less conservative than Bonferroni and Holm; appropriate when
# testing many hypotheses and some false positives are tolerable.
#
# Procedure:
#   1. Sort p-values descending
#   2. For each (processing largest first): adjusted = p * k / rank
#      where rank is the position in ascending order
#   3. Enforce monotonicity via running minimum (step-up)
#   4. Cap at 1.0
#   5. Return in original input order
#
# Undefined p-values are handled as R's p.adjust handles NA: they are
# excluded from the comparison count k and returned as undefined in
# their original positions.
#
# DEPENDENCY: Requires @emlSortWithIndex from eml-core-utilities.praat.
#
# Arguments:
#   .pValues#  - vector of raw p-values (elements may be undefined)
#
# Output:
#   .adjusted#  - vector of adjusted p-values (same order and length as
#                 input; undefined where the input was undefined)
#   .k          - number of comparisons actually adjusted (defined inputs)
#   .nInput     - length of the input vector
#   .nUndefined - number of undefined input p-values
#   .error$     - error message, or "" if valid
# ============================================================================

procedure emlBenjaminiHochberg: .pValues#
    .error$ = ""
    .nInput = size (.pValues#)
    .adjusted# = zero# (.nInput)

    # k counts only defined p-values, matching R's p.adjust, which drops
    # NA from n and returns NA in the NA positions.
    .k = 0
    for .i from 1 to .nInput
        if .pValues# [.i] <> undefined
            .k = .k + 1
        endif
    endfor
    .nUndefined = .nInput - .k

    if .nInput = 0
        .error$ = "Empty p-value vector."
    elif .k = 0
        .error$ = "All p-values are undefined."
        for .i from 1 to .nInput
            .adjusted# [.i] = undefined
        endfor
    else
        # Compact the defined p-values, remembering their source positions
        .defined# = zero# (.k)
        .source# = zero# (.k)
        .j = 0
        for .i from 1 to .nInput
            if .pValues# [.i] <> undefined
                .j = .j + 1
                .defined# [.j] = .pValues# [.i]
                .source# [.j] = .i
            else
                .adjusted# [.i] = undefined
            endif
        endfor

        if .k = 1
            .adjusted# [.source# [1]] = .defined# [1]
        else
            # Sort ascending, track original indices
            @emlSortWithIndex: .defined#
            .sortedP# = emlSortWithIndex.sorted#
            .origIdx# = emlSortWithIndex.indices#

            # Process in descending order (step-up): running minimum
            .runningMin = 1
            for .j from 1 to .k
                # Walk from largest to smallest
                .i = .k - .j + 1
                .rank = .i
                .val = .sortedP# [.i] * .k / .rank
                if .val < .runningMin
                    .runningMin = .val
                endif
                if .runningMin > 1
                    .runningMin = 1
                endif
                # Map back to original position
                .origPos = .source# [.origIdx# [.i]]
                .adjusted# [.origPos] = .runningMin
            endfor
        endif
    endif
endproc

# ============================================================================
# @eml_parseAnovaLine (INTERNAL)
# ============================================================================
# Parses a single row from Praat's ANOVA Info window output.
#
# The built-in Report one-way anova / Report two-way anova commands write
# a whitespace-aligned table to the Info window. Each row has a label
# (e.g., "Between", "Within", "Total", factor name) followed by numeric
# fields: SS, df, MS, F, p. Not all rows have all fields — "Within" and
# "Error" rows have SS, df, MS only; "Total" rows have SS, df only.
#
# Arguments:
#   .info$     - full Info window text (captured via info$() after Report)
#   .rowLabel$ - exact text of the row label to find (e.g., "Between")
#
# Output:
#   .ss  - sum of squares (or undefined if not found)
#   .df  - degrees of freedom (or undefined if not found)
#   .ms  - mean square (or undefined if row has < 3 numeric fields)
#   .f   - F statistic (or undefined if row has < 4 numeric fields)
#   .p   - p-value (or undefined if row has < 5 numeric fields)
#   .error$ - "" on success, diagnostic message on failure
#
# Notes:
#   - Matches .rowLabel$ EXACTLY against the first tab-delimited field
#     of each line (after trimming the alignment padding), then
#     tokenizes the remaining fields by whitespace. Substring matching
#     is deliberately NOT used: it collides when one label is contained
#     in another (e.g. factor "dose" inside factor "dose_time", or
#     "Error" inside a factor named "ErrorRate").
#   - number() handles scientific notation (e.g., 8.24e-195)
# ============================================================================

procedure eml_parseAnovaLine: .info$, .rowLabel$
    .ss = undefined
    .df = undefined
    .ms = undefined
    .f = undefined
    .p = undefined
    .error$ = ""

    # Locate the row by EXACT match on its first tab-delimited field.
    # The previous version used extractLine$, which returns the tail of
    # the first line CONTAINING the label as a substring. That matched
    # the wrong row whenever one label was a substring of another
    # (factor "dose" matching the row for factor "dose_time", or the
    # literal "Error" matching a factor named "ErrorRate" before it
    # reached the residual row).
    .remainder$ = ""
    .found = 0
    .lines$# = splitBy$# (.info$, newline$)

    for .li from 1 to size (.lines$#)
        if .found = 0
            .line$ = .lines$#[.li]
            .tabPos = index (.line$, tab$)
            if .tabPos > 0
                .label$ = left$ (.line$, .tabPos - 1)

                # Trim leading spaces from the label field
                while left$ (.label$, 1) = " "
                    .label$ = mid$ (.label$, 2, length (.label$) - 1)
                endwhile

                # Trim trailing spaces from the label field
                while length (.label$) > 0 and right$ (.label$, 1) = " "
                    .label$ = left$ (.label$, length (.label$) - 1)
                endwhile

                if .label$ = .rowLabel$
                    .found = 1
                    .remainder$ = mid$ (.line$, .tabPos + 1,
                    ... length (.line$) - .tabPos)
                endif
            endif
        endif
    endfor

    if .found = 0
        .error$ = "The ANOVA table has no row labelled """
        ... + .rowLabel$ + """."
    else
        # Replace tabs with spaces for consistent tokenization
        .remainder$ = replace$ (.remainder$, tab$, " ", 0)

        # Collapse multiple spaces to single space
        .prev$ = .remainder$
        .remainder$ = replace$ (.remainder$, "  ", " ", 0)
        while .remainder$ <> .prev$
            .prev$ = .remainder$
            .remainder$ = replace$ (.remainder$, "  ", " ", 0)
        endwhile

        # Trim leading spaces
        while left$ (.remainder$, 1) = " "
            .len = length (.remainder$)
            if .len > 1
                .remainder$ = mid$ (.remainder$, 2, .len - 1)
            else
                .remainder$ = ""
            endif
        endwhile

        # Trim trailing spaces
        while length (.remainder$) > 0 and right$ (.remainder$, 1) = " "
            .remainder$ = left$ (.remainder$, length (.remainder$) - 1)
        endwhile

        if .remainder$ = ""
            .error$ = "The ANOVA table row labelled """ + .rowLabel$
            ... + """ has no numeric values after the label."
        else
            # Tokenize by single spaces
            .nTokens = 0
            .work$ = .remainder$

            while length (.work$) > 0
                .nTokens = .nTokens + 1
                .spacePos = index (.work$, " ")
                if .spacePos > 0
                    .token$[.nTokens] = left$ (.work$, .spacePos - 1)
                    .work$ = mid$ (.work$, .spacePos + 1,
                    ... length (.work$) - .spacePos)
                else
                    .token$[.nTokens] = .work$
                    .work$ = ""
                endif
            endwhile

            # Map positional tokens to output fields
            # Full row (source with F and p): SS df MS F p
            # Partial row (residual): SS df MS
            # Minimal row (total): SS df
            if .nTokens >= 1
                .ss = number (.token$[1])
            endif
            if .nTokens >= 2
                .df = number (.token$[2])
            endif
            if .nTokens >= 3
                .ms = number (.token$[3])
            endif
            if .nTokens >= 4
                .f = number (.token$[4])
            endif
            if .nTokens >= 5
                .p = number (.token$[5])
            endif
        endif
    endif
endproc


# ============================================================================
# @emlTableFromGroups
# ============================================================================
# Convenience constructor: builds a Praat Table from pre-populated group
# data stored in indexed variables on this procedure's namespace.
#
# Before calling, the caller MUST set:
#   emlTableFromGroups.groupLabel$[i]  - string label for group i
#   emlTableFromGroups.groupSize[i]    - number of observations in group i
#   emlTableFromGroups.data#           - flat numeric vector of ALL values
#                                        (group 1 values, then group 2, etc.)
#
# Arguments:
#   .nGroups      - number of groups (>= 1)
#   .dataColName$ - name for the numeric data column
#   .factorColName$ - name for the string factor column
#
# Output:
#   .tableId - ID of the created Table object (caller owns cleanup)
#   .nRows   - total number of rows
#   .error$  - "" on success, diagnostic message on failure
#
# Example:
#   emlTableFromGroups.data# = {10, 12, 14, 20, 22, 24}
#   emlTableFromGroups.groupSize[1] = 3
#   emlTableFromGroups.groupSize[2] = 3
#   emlTableFromGroups.groupLabel$[1] = "Control"
#   emlTableFromGroups.groupLabel$[2] = "Treatment"
#   @emlTableFromGroups: 2, "Score", "Group"
#   tableId = emlTableFromGroups.tableId
# ============================================================================

procedure emlTableFromGroups: .nGroups, .dataColName$, .factorColName$
    .tableId = 0
    .nRows = 0
    .error$ = ""

    # --- Validate inputs ---

    if .nGroups < 1
        .error$ = "Building a table needs at least 1 group; got "
        ... + string$ (.nGroups) + "."
    endif

    if .error$ = ""
        # Sum group sizes to get total rows
        for .g from 1 to .nGroups
            .nRows = .nRows + .groupSize[.g]
        endfor

        if .nRows < 1
            .error$ = "Every group is empty, so the table would have 0 "
            ... + "rows. Each group needs at least 1 observation."
        endif
    endif

    if .error$ = ""
        # Verify data vector length matches sum of group sizes
        .dataLen = size (.data#)
        if .nRows <> .dataLen
            .error$ = "The group sizes add up to " + string$ (.nRows)
            ... + " observations, but the data vector holds "
            ... + string$ (.dataLen) + ". They must match."
        endif
    endif

    # --- Build Table ---

    if .error$ = ""
        .colSpec$ = .dataColName$ + " " + .factorColName$
        .tableId = Create Table with column names: "emlGroupTable",
        ... .nRows, .colSpec$

        # Populate rows: step through data# sequentially,
        # assigning group labels based on groupSize boundaries
        selectObject: .tableId
        .row = 0
        .dataIdx = 0
        for .g from 1 to .nGroups
            for .j from 1 to .groupSize[.g]
                .row = .row + 1
                .dataIdx = .dataIdx + 1
                Set numeric value: .row, .dataColName$, .data#[.dataIdx]
                Set string value: .row, .factorColName$, .groupLabel$[.g]
            endfor
        endfor
    endif
endproc


# ============================================================================
# @emlTukeyHSD
# ============================================================================
# Performs Tukey Honest Significant Difference post-hoc test on a Table.
#
# Computes pairwise q statistics directly from group means and pooled
# MSE, using Praat's native studentized range distribution functions
# (Get TukeyQ: / Get invTukeyQ:) for p-values and critical values.
#
# Arguments:
#   .tableId       - ID of a Table object (must be in object list)
#   .dataColumn$   - name of the numeric data column
#   .factorColumn$ - name of the string factor column
#   .alpha         - significance level for critical q (e.g., 0.05)
#
# Output:
#   .pMatrix##       - k × k symmetric matrix of pairwise p-values
#                      (diagonal = 1, off-diagonal = Tukey p)
#   .qMatrix##       - k × k symmetric matrix of q statistics
#                      (diagonal = 0)
#   .meanDiff##      - k × k antisymmetric mean differences
#                      (meanDiff[i,j] = mean_i − mean_j)
#   .qCritical       - critical q value at specified alpha
#   .dMatrix##       - k × k antisymmetric Cohen's d matrix
#                      (dMatrix[i,j] = d for group i vs group j; signed)
#   .msWithin        - pooled mean square error (MSE)
#   .dfWithin        - within-groups degrees of freedom (N − k)
#   .groupName$[i]   - group label for row/column i (1..nGroups)
#   .nGroups         - number of groups (k)
#   .nPairs          - number of unique pairwise comparisons (k*(k-1)/2)
#   .sortMap[s]      - maps sorted index s to extraction index
#   .nUndefined      - number of comparisons whose q (and therefore p)
#                      is undefined because the pooled SE was zero or
#                      undefined; such cells hold undefined, not 1
#   .warning$        - non-fatal disclosure, or "" if none
#   .error$          - "" on success, diagnostic message on failure
#
# Access pattern:
#   p-value for group 2 vs group 4: emlTukeyHSD.pMatrix##[2, 4]
#   q statistic for group 1 vs 3:   emlTukeyHSD.qMatrix##[1, 3]
#   mean difference (signed):        emlTukeyHSD.meanDiff##[1, 3]
#   Cohen's d for group 1 vs 3:     emlTukeyHSD.dMatrix##[1, 3]
#   group label for group 2:         emlTukeyHSD.groupName$[2]
#
# Notes:
#   - Groups are sorted alphabetically (matches R convention)
#   - Uses pairwise SE = sqrt(MSE * (1/n_i + 1/n_j) / 2) which
#     handles unbalanced designs naturally
#   - Cohen's d per pair uses two-group pooled SD (via @emlCohenD),
#     consistent with standalone effect size computation
#   - Requires >= 2 groups with enough observations for dfWithin >= 1
#   - Uses Get TukeyQ: (Goodies) for p-values and Get invTukeyQ:
#     for critical q — no Report parsing or Table side effects
#   - Dependencies: @emlCountGroups, @eml_getGroupData (eml-extract.praat),
#     @eml_getGroupData (eml-extract.praat),
#     @emlCohenD (eml-inferential.praat)
#   - Original Table selection is restored on return
# ============================================================================

procedure emlTukeyHSD: .tableId, .dataColumn$, .factorColumn$, .alpha
    .nGroups = 0
    .nPairs = 0
    .msWithin = undefined
    .dfWithin = undefined
    .qCritical = undefined
    .nUndefined = 0
    .warning$ = ""
    .error$ = ""

    # --- Validate inputs ---

    selectObject: .tableId
    .nRows = Get number of rows
    if .nRows < 3
        .error$ = "This test needs at least 3 observations; the table "
        ... + "has " + string$ (.nRows) + "."
    endif

    if .error$ = ""
        @emlRequireColumnPresent: .tableId, "Data column", .dataColumn$
        .error$ = emlRequireColumnPresent.error$
    endif

    if .error$ = ""
        @emlRequireColumnPresent: .tableId, "Factor column", .factorColumn$
        .error$ = emlRequireColumnPresent.error$
    endif

    # --- Discover groups ---

    if .error$ = ""
        @emlCountGroups: .tableId, .factorColumn$
        if emlCountGroups.error$ <> ""
            .error$ = emlCountGroups.error$
        else
            .nGroups = emlCountGroups.nGroups
        endif
    endif

    if .error$ = "" and .nGroups < 2
        .error$ = "This test compares 2 or more groups; the group column "
        ... + """" + .factorColumn$ + """ has " + string$ (.nGroups) + "."
    endif

    # --- Sort groups alphabetically ---

    if .error$ = ""
        # Group order controlled by emlGroupSortAlphabetical via
        # @emlCountGroups. Copy labels directly; sortMap = identity.
        for .s from 1 to .nGroups
            .groupName$[.s] = emlCountGroups.groupLabel$[.s]
            .sortMap[.s] = .s
        endfor
    endif

    # --- Compute group means, sizes, and pooled MSE ---

    if .error$ = ""
        .totalN = 0
        .ssWithin = 0

        for .s from 1 to .nGroups
            @eml_getGroupData: .tableId, .dataColumn$, .factorColumn$,
            ... .groupName$[.s]
            .groupN[.s] = eml_getGroupData.n
            .groupMean[.s] = mean (eml_getGroupData.data#)
            .totalN = .totalN + .groupN[.s]

            # SS within for this group (vectorized)
            .centered# = eml_getGroupData.data# - .groupMean[.s]
            .ssWithin = .ssWithin + sum (.centered# * .centered#)
        endfor

        .dfWithin = .totalN - .nGroups
        if .dfWithin < 1
            .error$ = string$ (.totalN) + " observations across "
            ... + string$ (.nGroups) + " groups leave no within-groups "
            ... + "degrees of freedom. There must be more observations "
            ... + "than groups."
        else
            .msWithin = .ssWithin / .dfWithin
        endif
    endif

    # --- Compute pairwise q statistics and p-values ---

    if .error$ = ""
        .pMatrix## = zero## (.nGroups, .nGroups)
        .qMatrix## = zero## (.nGroups, .nGroups)
        .meanDiff## = zero## (.nGroups, .nGroups)
        .dMatrix## = zero## (.nGroups, .nGroups)

        # Diagonal p = 1 (self-comparison)
        for .i from 1 to .nGroups
            .pMatrix##[.i, .i] = 1
        endfor

        .nPairs = .nGroups * (.nGroups - 1) / 2

        for .i from 1 to .nGroups
            for .j from .i + 1 to .nGroups
                .diff = .groupMean[.i] - .groupMean[.j]
                .se = sqrt (.msWithin
                ... * (1 / .groupN[.i] + 1 / .groupN[.j]) / 2)
                # Guard the degenerate SE explicitly. A zero or
                # undefined SE (zero pooled within-group variance, or
                # an undefined MSE) makes q undefined; the old code
                # let that fall through the "else" branch and reported
                # p = 1.000, which fails open (never significant).
                .q = undefined
                .p = undefined
                if .se <> undefined
                    if .se > 0
                        .q = abs (.diff) / .se
                    endif
                endif
                if .q <> undefined
                    if .q > 0
                        .p = Get TukeyQ: .q, .nGroups, .dfWithin, 1
                    else
                        .p = 1
                    endif
                else
                    .nUndefined = .nUndefined + 1
                endif

                .qMatrix##[.i, .j] = .q
                .qMatrix##[.j, .i] = .q
                .pMatrix##[.i, .j] = .p
                .pMatrix##[.j, .i] = .p
                .meanDiff##[.i, .j] = .diff
                .meanDiff##[.j, .i] = -.diff

                # Cohen's d per pair (two-group pooled SD)
                @eml_getGroupData: .tableId, .dataColumn$, .factorColumn$,
                ... .groupName$[.i]
                if eml_getGroupData.error$ <> ""
                    .error$ = eml_getGroupData.error$
                    .dMatrix##[.i, .j] = undefined
                    .dMatrix##[.j, .i] = undefined
                else
                    .vI# = eml_getGroupData.data#
                    @eml_getGroupData: .tableId, .dataColumn$, .factorColumn$,
                    ... .groupName$[.j]
                    if eml_getGroupData.error$ <> ""
                        .error$ = eml_getGroupData.error$
                        .dMatrix##[.i, .j] = undefined
                        .dMatrix##[.j, .i] = undefined
                    else
                        @emlCohenD: .vI#, eml_getGroupData.data#
                        if emlCohenD.error$ = ""
                            .dMatrix##[.i, .j] = emlCohenD.d
                            .dMatrix##[.j, .i] = -emlCohenD.d
                        else
                            .dMatrix##[.i, .j] = undefined
                            .dMatrix##[.j, .i] = undefined
                        endif
                    endif
                endif
            endfor
        endfor

        # Critical q value at specified alpha
        .qCritical = Get invTukeyQ: .alpha, .nGroups, .dfWithin, 1

        if .nUndefined > 0
            .warning$ = string$ (.nUndefined)
            ... + " of " + string$ (.nPairs) + " comparisons have an "
            ... + "undefined q (zero or undefined pooled standard "
            ... + "error); their p-values are undefined, not 1"
        endif
    endif

    # --- Restore selection ---

    selectObject: .tableId
endproc


# ============================================================================
# @emlOneWayAnova
# ============================================================================
# Performs one-way ANOVA on a Table with optional Tukey HSD post-hoc.
#
# Native computation (Hays 1988). Replaces the previous wrapper around
# Report one-way anova, which had a display bug (Table_extensions.cpp
# Table_printAsMeansTable: Melder_padLeft width 10 truncating means)
# and wrote to Info window as a side effect.
#
# Algorithm: Hays (1988) 12-step computational formula.
# P-value via Praat's native fisherQ(F, df1, df2).
#
# Arguments:
#   .tableId       - ID of a Table object (must be in object list)
#   .dataColumn$   - name of the numeric data column
#   .factorColumn$ - name of the string factor column
#   .tukey         - 1 to run Tukey HSD post-hoc, 0 to skip
#
# Output (always):
#   .fValue    - F statistic
#   .p         - p-value (from fisherQ)
#   .dfBetween - between-groups degrees of freedom (k - 1)
#   .dfWithin  - within-groups degrees of freedom (N - k)
#   .dfTotal   - total degrees of freedom (N - 1)
#   .ssBetween - between-groups sum of squares
#   .ssWithin  - within-groups sum of squares
#   .ssTotal   - total sum of squares
#   .msBetween - between-groups mean square
#   .msWithin  - within-groups mean square
#   .nGroups   - number of groups (k)
#   .etaSquared - eta-squared effect size (ssBetween / ssTotal)
#   .groupMean[g] - mean of group g (1..nGroups, alphabetical order)
#   .groupN[g]    - size of group g
#   .groupLabel$[g] - label of group g
#   .warning$  - non-fatal disclosure (degenerate variance), or ""
#   .error$    - "" on success, diagnostic message on failure
#
# Output (when .tukey = 1):
#   .pMatrix##     - k × k symmetric matrix of Tukey pairwise p-values
#   .qMatrix##     - k × k symmetric matrix of Tukey q statistics
#   .meanDiff##    - k × k antisymmetric mean differences
#   .dMatrix##     - k × k antisymmetric Cohen's d (from @emlTukeyHSD)
#   .qCritical     - critical q at alpha = 0.05
#   .groupName$[i] - group label for row/column i (1..nGroups, alphabetical)
#   .nPairs        - number of unique pairwise comparisons
#
# Notes:
#   - Does NOT call Report one-way anova. No Info window side effect.
#   - Group labels are in alphabetical order (matching @emlCountGroups)
#   - When tukey=1, this procedure calls @emlTukeyHSD internally
#     with alpha = 0.05. For custom alpha, call @emlTukeyHSD directly.
#   - Original Table selection is restored on return
# ============================================================================

procedure emlOneWayAnova: .tableId, .dataColumn$, .factorColumn$, .tukey
    .fValue = undefined
    .p = undefined
    .dfBetween = undefined
    .dfWithin = undefined
    .dfTotal = undefined
    .ssBetween = undefined
    .ssWithin = undefined
    .ssTotal = undefined
    .msBetween = undefined
    .msWithin = undefined
    .nGroups = undefined
    .etaSquared = undefined
    .nPairs = 0
    .warning$ = ""
    .error$ = ""

    # --- Validate inputs ---

    selectObject: .tableId
    .nRows = Get number of rows
    if .nRows < 3
        .error$ = "Need at least 3 observations, got "
        ... + string$ (.nRows) + "."
    endif

    if .error$ = ""
        @emlRequireColumnPresent: .tableId, "Data column", .dataColumn$
        .error$ = emlRequireColumnPresent.error$
    endif

    if .error$ = ""
        @emlRequireColumnPresent: .tableId, "Factor column", .factorColumn$
        .error$ = emlRequireColumnPresent.error$
    endif

    # --- Count and extract groups ---

    if .error$ = ""
        @emlCountGroups: .tableId, .factorColumn$
        if emlCountGroups.error$ <> ""
            .error$ = emlCountGroups.error$
        else
            .nGroups = emlCountGroups.nGroups
        endif
    endif

    if .error$ = "" and .nGroups < 2
        .error$ = "Group column """ + .factorColumn$ + """ has "
        ... + string$ (.nGroups) + " group. This test compares 2 or more."
    endif

    # --- Group sizes: state the diagnosis, not the first offender ---
    # The old form raised on the first group it found with fewer than
    # two observations, so a factor column that is unique per row took one
    # attempt per row to diagnose. Both numbers needed to say what is
    # actually wrong are already in hand from @emlCountGroups, so say it:
    # as many groups as rows means the column is an identifier, not a
    # grouping. Where that is not the shape, name the offenders together.

    if .error$ = ""
        .nSingleton = 0
        .singletonList$ = ""
        for .g from 1 to .nGroups
            @eml_getGroupData: .tableId, .dataColumn$, .factorColumn$,
            ... emlCountGroups.groupLabel$[.g]
            if eml_getGroupData.n < 2
                .nSingleton = .nSingleton + 1
                if .nSingleton <= 5
                    if .singletonList$ <> ""
                        .singletonList$ = .singletonList$ + ", "
                    endif
                    .singletonList$ = .singletonList$ + """"
                    ... + emlCountGroups.groupLabel$[.g] + """"
                endif
            endif
        endfor

        if .nSingleton > 0
            if .nGroups = .nRows
                .error$ = "Group column """ + .factorColumn$ + """ has "
                ... + string$ (.nGroups) + " groups for "
                ... + string$ (.nRows) + " rows - one per row. This is an "
                ... + "identifier column, not a grouping column."
            else
                .error$ = string$ (.nSingleton) + " of "
                ... + string$ (.nGroups) + " groups in """
                ... + .factorColumn$ + """ have fewer than 2 observations: "
                ... + .singletonList$
                if .nSingleton > 5
                    .error$ = .error$ + ", and "
                    ... + string$ (.nSingleton - 5) + " more"
                endif
                .error$ = .error$ + ". Every group needs at least 2."
            endif
        endif
    endif

    # --- Compute ANOVA (two-pass sums of squares) ---
    # Pass 1 collects group sizes, group means, and the grand mean.
    # Pass 2 accumulates centred deviations. The previous version used
    # the Hays (1988) raw-score computational formula
    # (SS = sum(y^2) - (sum y)^2 / N), which loses precision through
    # catastrophic cancellation when the mean is large relative to the
    # spread. The centred two-pass form is algebraically identical and
    # numerically stable.

    if .error$ = ""
        .totalN = 0
        .sumOfRawScores = 0

        for .g from 1 to .nGroups
            @eml_getGroupData: .tableId, .dataColumn$, .factorColumn$,
            ... emlCountGroups.groupLabel$[.g]
            .gN = eml_getGroupData.n
            .gData# = eml_getGroupData.data#

            # Group sizes were validated above, so every group here has
            # at least 2 observations.
            .gSum = sum (.gData#)

            .totalN = .totalN + .gN
            .sumOfRawScores = .sumOfRawScores + .gSum

            .groupMean[.g] = mean (.gData#)
            .groupN[.g] = .gN
            .groupLabel$[.g] = emlCountGroups.groupLabel$[.g]
        endfor
    endif

    if .error$ = ""
        ; ---------------------------------------------------------------
        ; CORRECTED TWO-PASS. The provisional grand mean below is only a
        ; SHIFT; every quantity is then formed in shifted coordinates and
        ; the shift's own error is measured and removed.
        ;
        ; Why: NIST StRD SmLs07-09 carry thirteen CONSTANT LEADING DIGITS,
        ; and the between-group sum of squares is about 1.68. Forming
        ; (groupMean - grandMean) on raw values cancels away nearly the
        ; whole mantissa before the squaring, and any error already sitting
        ; in grandMean is amplified by it. Subtracting the shift first means
        ; the leading digits are gone before any difference is taken.
        ;
        ; This is exact, not an approximation: ANOVA is invariant under a
        ; location shift, which is asserted independently by the Tier A
        ; property sweep (A2, "F invariant under +1e6"). The refinement .cShift
        ; is the residual error in the provisional mean, recovered as the
        ; weighted mean of the shifted group means -- a number near zero,
        ; where a double has all its precision available.
        ;
        ; Measured on 6 August 2026, correct significant digits against NIST's
        ; certified between-group sum of squares:
        ;
        ;     SmLs04    9.33 -> 15.65      SmLs07    3.31 -> 15.65
        ;
        ; (see validate/v19_nist_strd.R for the current figures)
        ; ---------------------------------------------------------------
        .shift = .sumOfRawScores / .totalN
        .ssWithin = 0
        .weightedShiftedSum = 0

        for .g from 1 to .nGroups
            @eml_getGroupData: .tableId, .dataColumn$, .factorColumn$,
            ... .groupLabel$[.g]
            .shifted# = eml_getGroupData.data# - .shift
            .shiftedMean[.g] = mean (.shifted#)
            .centered# = .shifted# - .shiftedMean[.g]

            ; Corrected two-pass (Chan, Golub & LeVeque 1983). In exact
            ; arithmetic sum(.centered#) is zero, so the second term vanishes.
            ; In floating point it is exactly the error left in .shiftedMean,
            ; and subtracting its square over n removes that error's
            ; contribution instead of squaring it into the total. Costs one
            ; extra sum per group.
            .sumDev = sum (.centered#)
            .ssWithin = .ssWithin + sum (.centered# * .centered#)
            ... - .sumDev * .sumDev / .groupN[.g]
            .weightedShiftedSum = .weightedShiftedSum
            ... + .groupN[.g] * .shiftedMean[.g]
        endfor

        ; How far the provisional shift missed the true grand mean.
        .cShift = .weightedShiftedSum / .totalN
        .grandMean = .shift + .cShift

        ; Group means are still reported in the caller's own units.
        .ssBetween = 0
        for .g from 1 to .nGroups
            .groupMean[.g] = .shift + .shiftedMean[.g]
            .gDev = .shiftedMean[.g] - .cShift
            .ssBetween = .ssBetween + .groupN[.g] * .gDev * .gDev
        endfor

        .ssTotal = .ssBetween + .ssWithin

        .dfBetween = .nGroups - 1
        .dfWithin = .totalN - .nGroups
        .dfTotal = .totalN - 1

        .msBetween = .ssBetween / .dfBetween
        .msWithin = .ssWithin / .dfWithin

        # Guard the degenerate case of zero within-group variance.
        # Without it, F is a division by zero, p is undefined, and
        # eta-squared silently reports exactly 1 with an empty error$.
        if .msWithin > 0
            .fValue = .msBetween / .msWithin
            .p = fisherQ (.fValue, .dfBetween, .dfWithin)
        else
            .fValue = undefined
            .p = undefined
            .warning$ = "Within-groups mean square is "
            ... + "zero (no variance inside any group); F and p are "
            ... + "undefined"
        endif

        if .ssTotal > 0
            .etaSquared = .ssBetween / .ssTotal
        else
            .etaSquared = undefined
            .warning$ = "Total sum of squares is zero "
            ... + "(all observations identical); eta-squared is undefined"
        endif
    endif

    # --- Tukey HSD post-hoc (optional, chained) ---

    if .error$ = "" and .tukey = 1
        ; THE ALPHA THIS PASSES FIXES .qCritical, AND NOTHING ELSE. The
        ; pairwise adjusted p-values in .pMatrix## and the q statistics in
        ; .qMatrix## are computed from the data and do not depend on it; only
        ; the critical q does, and the only readers of .qCritical are the
        ; family-wise interval the ANOVA report prints and the conf.low /
        ; conf.high pair the Tukey export frame carries. Both of those are
        ; labelled 95%, which is the level this line sets. A caller wanting
        ; another level calls @emlTukeyHSD directly, which takes .alpha.
        @emlTukeyHSD: .tableId, .dataColumn$, .factorColumn$, 0.05
        if emlTukeyHSD.error$ <> ""
            .error$ = "Tukey HSD: " + emlTukeyHSD.error$
        else
            .nPairs = emlTukeyHSD.nPairs
            .pMatrix## = emlTukeyHSD.pMatrix##
            .qMatrix## = emlTukeyHSD.qMatrix##
            .meanDiff## = emlTukeyHSD.meanDiff##
            .dMatrix## = emlTukeyHSD.dMatrix##
            .qCritical = emlTukeyHSD.qCritical
            for .g from 1 to emlTukeyHSD.nGroups
                .groupName$[.g] = emlTukeyHSD.groupName$[.g]
            endfor
        endif
    endif

    # --- Restore selection ---

    selectObject: .tableId
endproc


# ============================================================================
# @emlRequireColumnPresent
# ============================================================================
# THE ONE column-presence guard, and the sentence before @emlRequireNumeric-
# Column's. Presence, then type: a column that is not in the table has no
# type to diagnose, and @emlRequireNumericColumn deliberately returns "" for
# it so that this question is answered here instead.
#
# WHY THIS EXISTS. When the data column was simply ABSENT, two entry points
# refused by describing what the absence did to the groups rather than
# naming the column:
#
#   @emlRunTwoGroupAnalysis  Each group needs at least 2 observations.
#                            Group "G1": n=0, group "G2": n=0
#   @emlKruskalWallis        Group "H3" has 0 observations. Every group
#                            needs at least 1.
#   @emlScheffe              0 observations across 3 groups leave no
#                            within-groups degrees of freedom. ...
#
# Every one of those is TRUE and every one of them sends the reader to
# inspect their grouping variable, which is fine. The mirror image of the
# numeric-column guard:
# there, a type error was reported as missing data; here, a missing column
# is reported as a group shortage. Two more entry points -- @emlPairwiseT
# and @emlPairwiseWilcoxon -- did not refuse at all, returning an empty
# error$ and a matrix of undefined, which is D113a's shape surviving at the
# library layer because that fix was applied only to the orchestrator above
# them.
#
# ONLY THE ABSENT COLUMN, THOUGH. What this procedure fixed in those two was
# the column that is not in the table. A column that WAS in the table and
# held nothing usable went on returning an empty error$ and a matrix of
# undefined for another day, because presence and type are two guards and
# Both tests ask
# @emlRequireNumericColumn as well, immediately after asking here, and the
# order matters in the way described below: a column that is not there has
# no type to diagnose. v28 pins both refusals, separately, at this layer.
#
# WHERE IT LIVES, AND WHY THE LIBRARY AND NOT THE ORCHESTRATOR. Six of the
# eleven table-taking tests in this file already asked this question --
# @emlTukeyHSD, @emlOneWayAnova, @emlTwoWayAnova, @emlBrownForsythe,
# @emlWelchAnova, @emlGamesHowell -- each with its own two-line copy of the
# same code and the same words, thirteen copies between them. This procedure
# is those copies, collected; the other five now call it too, and the
# wording exists once.
#
# Putting the guard in the TEST rather than in the orchestrator above it is
# what makes it reach the supported direct-call path: eml-lib-stats.praat
# pulls this file in without any orchestrator, and a script that calls
# @emlKruskalWallis straight is exactly as entitled to a true diagnosis as a
# menu item is. That is also the lesson of the two pairwise tests above --
# D113a was fixed in @emlRunPairwiseAnalysis and the tests underneath it
# stayed silent for a day. @emlRunTwoGroupAnalysis is the one caller that
# takes the guard at the orchestrator instead, because its tests (@emlTTest,
# @emlMannWhitneyU) take vectors and it is itself the lowest layer on that
# path that ever sees the Table.
#
# THE WORDING IS NOT NEW. ".role$ + \" not found: \" + .columnName$" is
# character-for-character what those six have always said, and what v22 and
# v28 already assert verbatim. Nothing about their refusals changes; they
# simply stopped being thirteen copies of a sentence.
#
# NOT THE EMPTY COLUMN. A column that IS in the table and holds nothing
# usable is a different fault with a different remedy -- fill in the data,
# not pick another column -- and it is @emlRequireNumericColumn's, which
# says so in @emlAuditColumn's words ("36 cell(s) are empty (row 1 first).
# Treated as missing data."). The two must not be merged: "not found" told
# to someone whose column is merely blank would be as wrong as the group
# message this replaces.
#
# Arguments:
#   .tableId     - ID of the Table object
#   .role$       - what this column is TO THE CALLER, capitalised and
#                  leading the message: "Data column", "Factor column",
#                  "First factor column", "Second factor column".
#   .columnName$ - name of the column that must exist
#
# Output:
#   .error$ - refusal message, or "" if the column is in the table
#   .index  - the column's index, or 0. A caller that would otherwise keep
#             this in a
#             local .colIdx are welcome to it; none currently reads it.
#
# Leaves .tableId selected, which every caller already required.
# ============================================================================
procedure emlRequireColumnPresent: .tableId, .role$, .columnName$
    .error$ = ""
    selectObject: .tableId
    .index = Get column index: .columnName$
    if .index = 0
        .error$ = .role$ + " not found: " + .columnName$
    endif
endproc


# ============================================================================
# @emlRequireNumericColumn
# ============================================================================
# THE ONE column-type guard. Every analysis entry point that takes a column
# of measurements asks here before it computes anything, so that "you gave me
# a column of text" is diagnosed once, in one wording, in one place.
#
# WHY THIS EXISTS. Driven through the GUI on 7 August 2026: the two-way ANOVA
# accepted `singer` — a column of subject identifiers like "Singer_1" — as the
# measurement column and printed a full result table, F = 132.92, p = 7e-15,
# with no complaint. Praat's Table numericiser is the mechanism. `Get value:`
# on a text cell returns undefined, which every row-wise reader in this plugin
# already drops; but `Get all numbers in column:` and the built-in
# `Report two-way anova:` numericise the column AS A WHOLE, and when any cell
# is not strictly numeric they silently substitute each row's ALPHABETICAL
# RANK. Sorting twelve singer names and calling the sort order a sound
# pressure level produces a number, and nothing downstream can tell that it
# is not a measurement.
#
# The row-wise paths were not silent, but they were not honest either: they
# refused with "Need at least 3 non-missing values (found 0)", which tells a
# user their data is missing when in fact their column is the wrong type.
# One diagnosis, not eleven near-misses.
#
# WHERE IT LIVES. Conceptually this belongs beside @emlAuditColumn in
# eml-extract.praat. It is here because eml-inferential.praat is the lowest
# module that both the orchestrators (eml-analysis.praat) and the tests in
# this file are guaranteed to have loaded: eml-lib-stats.praat pulls this
# file in without eml-analysis.praat, so a guard defined there would be
# unresolvable when @emlTwoWayAnova is called from a stats-only script.
#
# NO NEW CLASSIFIER. The verdict and every user-facing sentence come from
# @emlAuditColumn, which is already "the one place that decision is made".
# This procedure adds a sentence naming the column and its role and otherwise
# quotes @emlAuditColumn verbatim, so the type diagnosis cannot drift from the
# missing-data diagnosis printed by the extraction paths.
#
# Arguments:
#   .tableId     - ID of the Table object
#   .role$       - what this column is TO THE CALLER, capitalised, e.g.
#                  "Data column", "X column", "Dependent column". Leads the
#                  message, so it reads as a sentence.
#   .columnName$ - name of the column to check
#   .strict      - 0 = refuse only when the column holds no numbers at all.
#                      A column with SOME unusable cells is not refused: the
#                      complete-case convention settled 21 July (C1/C2, and
#                      ) drops those rows and discloses the
#                      count, and that convention is not reopened here.
#                  1 = refuse when ANY cell is unusable. For callers that
#                      read the column through Praat's whole-column
#                      numericiser, where a single bad cell replaces EVERY
#                      value with its alphabetical rank and there is no
#                      per-row drop to fall back on.
#
# Output:
#   .error$ - refusal message, or "" if the column may be analysed.
#
# A column that does not exist and a table with no rows both return "". A
# column that is not there has no type to diagnose: that question belongs to
# @emlRequireColumnPresent above, which every caller here asks first, and
# answering it in two places would be the start of two wordings for it. An
# empty TABLE is still the callers' own guard, worded per call site because
# the minimum n differs by test.
# ============================================================================
procedure emlRequireNumericColumn: .tableId, .role$, .columnName$, .strict
    .error$ = ""
    .nRows = 0
    .nValid = 0
    .note$ = ""

    @emlAuditColumn: .tableId, .columnName$
    ; Praat does not short-circuit `and`, so these are nested rather than
    ; combined: emlAuditColumn.nValid is meaningless when the column was
    ; not found.
    if emlAuditColumn.error$ = ""
        .nRows = emlAuditColumn.nRows
        .nValid = emlAuditColumn.nValid
        .note$ = emlAuditColumn.note$

        if .nRows > 0
            if .nValid = 0
                .error$ = .role$ + " """ + .columnName$
                ... + """ holds no numbers."
                if .note$ <> ""
                    .error$ = .error$ + " " + .note$
                endif
            elsif .strict = 1
                if .nValid < .nRows
                    .error$ = .role$ + " """ + .columnName$
                    ... + """ is not numeric in every row. This test reads "
                    ... + "the column as a whole, so one unusable cell "
                    ... + "replaces every value with its alphabetical rank; "
                    ... + "the unusable rows cannot be dropped individually "
                    ... + "here."
                    if .note$ <> ""
                        .error$ = .error$ + " " + .note$
                    endif
                endif
            endif
        endif
    else
        ; A COLUMN THAT DOES NOT EXIST FAILS THE GATE. Without this branch
        ; .error$ stays "" from the top of the procedure and the gate reports
        ; success, which is the opposite of its own name. Every caller in this
        ; file asks @emlRequireColumnPresent first and so never reaches here;
        ; the caller this branch is for is the future one that trusts
        ; "Numeric" in the name to also mean "Present". Quotes
        ; @emlAuditColumn's own message verbatim -- the missing-column
        ; diagnosis is made in ONE place, and it is not this one.
        .error$ = emlAuditColumn.error$
    endif
endproc


# ============================================================================
# @emlTwoWayAnova
# ============================================================================
# Performs two-way ANOVA on a Table.
#
# SUM-OF-SQUARES TYPE: TYPE III (partial). The main-effect and
# interaction sums of squares come from Praat's built-in
# Report two-way anova (hidden command), which computes Type III SS;
# these agree with R (car::Anova type 3) to full printed precision on
# both balanced and unbalanced designs.
#
# The error and total terms are NOT taken from that report. Praat's
# Error and Total rows are incorrect on unbalanced designs (verified:
# an unbalanced 2x2 reported SS_Error = 499.322 / SS_Total = 1838.599
# where the true within-cell residual SS is 29.9167 and the true
# centred total SS is 1804.545). SS_Error is recomputed here from
# within-cell deviations, SS_Total from centred deviations about the
# grand mean, and F/P for all three effects are re-derived from the
# corrected MS_Error.
#
# On an unbalanced design the Type III effect sums of squares do NOT
# add up to SS_Total. This is a property of Type III SS, not an error;
# .balanced is set to 0 and .warning$ says so.
#
# Arguments:
#   .tableId   - ID of a Table object (must be in object list)
#   .dataCol$  - name of the numeric data column
#   .factor1$  - name of the first factor column (string)
#   .factor2$  - name of the second factor column (string)
#
# Output:
#   Main effect A (factor1):
#     .fA, .pA, .dfA, .ssA, .msA
#   Main effect B (factor2):
#     .fB, .pB, .dfB, .ssB, .msB
#   Interaction (A × B):
#     .fAB, .pAB, .dfAB, .ssAB, .msAB
#   Error (recomputed from within-cell deviations):
#     .ssError, .dfError, .msError
#   Total (recomputed as the centred total sum of squares):
#     .ssTotal, .dfTotal
#   As reported by Praat (traceability only, not used):
#     .ssErrorReported, .dfErrorReported, .msErrorReported
#     .ssTotalReported, .dfTotalReported
#   Design:
#     .nCells   - number of non-empty factor-level combinations
#     .nLev1    - number of distinct levels of factor 1
#     .nLev2    - number of distinct levels of factor 2
#     .minCellN - smallest cell size
#     .maxCellN - largest cell size
#     .balanced - 1 if every cell is present and equally sized, else 0
#   Effect sizes:
#     .partialEtaSqA  - partial eta-squared for factor 1
#     .partialEtaSqB  - partial eta-squared for factor 2
#     .partialEtaSqAB - partial eta-squared for interaction
#   Status:
#     .warning$ - non-fatal disclosure (unbalanced, empty cells,
#                 degenerate variance), or "" if none
#     .error$ - "" on success, diagnostic message on failure
#
# Notes:
#   - The built-in Report two-way anova is a hidden command (stable since ~2006)
#   - Info window output row order: factor1, factor2, interaction, Error, Total
#   - Interaction row label is "factor1 x factor2" (constructed internally)
#   - Parsing isolates the data section (after "Source" header) to avoid
#     matching factor names in the header line
#   - Original Table selection is restored on return
# ============================================================================

procedure emlTwoWayAnova: .tableId, .dataCol$, .factor1$, .factor2$
    .fA = undefined
    .pA = undefined
    .dfA = undefined
    .ssA = undefined
    .msA = undefined
    .fB = undefined
    .pB = undefined
    .dfB = undefined
    .ssB = undefined
    .msB = undefined
    .fAB = undefined
    .pAB = undefined
    .dfAB = undefined
    .ssAB = undefined
    .msAB = undefined
    .ssError = undefined
    .dfError = undefined
    .msError = undefined
    .ssTotal = undefined
    .dfTotal = undefined
    .ssErrorReported = undefined
    .dfErrorReported = undefined
    .msErrorReported = undefined
    .ssTotalReported = undefined
    .dfTotalReported = undefined
    .nCells = 0
    .nLev1 = 0
    .nLev2 = 0
    .minCellN = undefined
    .maxCellN = undefined
    .balanced = 1
    .partialEtaSqA = undefined
    .partialEtaSqB = undefined
    .partialEtaSqAB = undefined
    .warning$ = ""
    .error$ = ""

    # --- Validate inputs ---

    selectObject: .tableId
    .nRows = Get number of rows
    if .nRows < 4
        .error$ = "This test needs at least 4 observations; the table "
        ... + "has " + string$ (.nRows) + "."
    endif

    if .error$ = ""
        @emlRequireColumnPresent: .tableId, "Data column", .dataCol$
        .error$ = emlRequireColumnPresent.error$
    endif

    if .error$ = ""
        @emlRequireColumnPresent: .tableId, "First factor column", .factor1$
        .error$ = emlRequireColumnPresent.error$
    endif

    if .error$ = ""
        @emlRequireColumnPresent: .tableId, "Second factor column", .factor2$
        .error$ = emlRequireColumnPresent.error$
    endif

    # --- The data column must be a column of numbers ---
    #
    # STRICT, uniquely among the tests in this file. Every other path reads
    # the data column row by row and can drop an unusable cell; the built-in
    # below numericises the whole column in one go and silently substitutes
    # alphabetical ranks when any cell fails, so there is no partial answer
    # to give.

    if .error$ = ""
        @emlRequireNumericColumn: .tableId, "Data column", .dataCol$, 1
        .error$ = emlRequireNumericColumn.error$
    endif

    # --- Run Report two-way anova ---
    #
    # ASSIGNED, NOT RUN BARE, AND THE DIFFERENCE IS NOT COSMETIC (12 Aug 2026).
    #
    # `Report two-way anova: ...` on its own line CLEARS the Info window and
    # writes the report into it, so the only way to read the report was
    # info$ () -- and the caller then had to put the user's Info window back,
    # which @emlRunTwoWayAnalysis did by snapshotting info$ () beforehand and
    # replaying it with writeInfo:.
    #
    # That replay is correct in the GUI and WRONG IN BATCH. Under `praat
    # --run`, Info output is streamed to stdout as it is produced; nothing can
    # be un-printed, so writeInfo: does not restore anything -- it emits the
    # entire preceding transcript a SECOND time. Measured on 6.6.30: a
    # 27-operation driver whose ninth operation was a two-way ANOVA printed 35
    # operation lines, the first eight twice. Anything reading a batch run's
    # stdout -- a harness, a log parser, a user piping to a file -- saw
    # duplicated history and no error.
    #
    # Assigning the command's result captures the report into a string and
    # leaves the Info window untouched, so there is nothing to restore and the
    # save/restore pair is gone from the orchestrator entirely.

    if .error$ = ""
        selectObject: .tableId
        .anovaInfo$ = Report two-way anova: .dataCol$, .factor1$, .factor2$,
        ... "no"
    endif

    # --- Isolate data section (after "Source" header line) ---
    # Factor names appear both in the header sentence and in the data
    # rows. Trimming to the data section prevents false matches.

    if .error$ = ""
        .sourcePos = index (.anovaInfo$, "Source")
        if .sourcePos = 0
            .error$ = "Praat's two-way ANOVA report could not be read: "
            ... + "no Source header was found in its output."
        endif
    endif

    if .error$ = ""
        # Get substring from "Source" onward
        .fromSource$ = mid$ (.anovaInfo$, .sourcePos,
        ... length (.anovaInfo$) - .sourcePos + 1)

        # Find the first newline to skip the "Source SS Df MS F P" header
        .nlPos = index (.fromSource$, newline$)
        if .nlPos = 0
            .error$ = "Praat's two-way ANOVA report could not be read: "
            ... + "nothing follows the Source header line."
        else
            .dataSection$ = mid$ (.fromSource$, .nlPos + 1,
            ... length (.fromSource$) - .nlPos)
        endif
    endif

    # --- Parse factor 1 row: SS, df, MS, F, p ---

    if .error$ = ""
        @eml_parseAnovaLine: .dataSection$, .factor1$
        if eml_parseAnovaLine.error$ <> ""
            .error$ = "Could not read the row for the first factor. "
            ... + eml_parseAnovaLine.error$
        else
            .ssA = eml_parseAnovaLine.ss
            .dfA = eml_parseAnovaLine.df
            .msA = eml_parseAnovaLine.ms
            .fA = eml_parseAnovaLine.f
            .pA = eml_parseAnovaLine.p
        endif
    endif

    # --- Parse factor 2 row: SS, df, MS, F, p ---

    if .error$ = ""
        @eml_parseAnovaLine: .dataSection$, .factor2$
        if eml_parseAnovaLine.error$ <> ""
            .error$ = "Could not read the row for the second factor. "
            ... + eml_parseAnovaLine.error$
        else
            .ssB = eml_parseAnovaLine.ss
            .dfB = eml_parseAnovaLine.df
            .msB = eml_parseAnovaLine.ms
            .fB = eml_parseAnovaLine.f
            .pB = eml_parseAnovaLine.p
        endif
    endif

    # --- Parse interaction row: SS, df, MS, F, p ---

    if .error$ = ""
        .interactionLabel$ = .factor1$ + " x " + .factor2$
        @eml_parseAnovaLine: .dataSection$, .interactionLabel$
        if eml_parseAnovaLine.error$ <> ""
            .error$ = "Could not read the interaction row. "
            ... + eml_parseAnovaLine.error$
        else
            .ssAB = eml_parseAnovaLine.ss
            .dfAB = eml_parseAnovaLine.df
            .msAB = eml_parseAnovaLine.ms
            .fAB = eml_parseAnovaLine.f
            .pAB = eml_parseAnovaLine.p
        endif
    endif

    # --- Parse Error row: SS, df, MS (reported values, retained only
    #     for traceability — they are NOT used, see below) ---

    if .error$ = ""
        @eml_parseAnovaLine: .dataSection$, "Error"
        if eml_parseAnovaLine.error$ <> ""
            .error$ = "Could not read the Error row. "
            ... + eml_parseAnovaLine.error$
        else
            .ssErrorReported = eml_parseAnovaLine.ss
            .dfErrorReported = eml_parseAnovaLine.df
            .msErrorReported = eml_parseAnovaLine.ms
        endif
    endif

    # --- Parse Total row: SS, df (reported values, traceability only) ---

    if .error$ = ""
        @eml_parseAnovaLine: .dataSection$, "Total"
        if eml_parseAnovaLine.error$ <> ""
            .error$ = "Could not read the Total row. "
            ... + eml_parseAnovaLine.error$
        else
            .ssTotalReported = eml_parseAnovaLine.ss
            .dfTotalReported = eml_parseAnovaLine.df
        endif
    endif

    # --- Recompute the error and total terms from the raw data ---
    #
    # Praat's Report two-way anova reports Type III sums of squares for
    # the two main effects and the interaction, and those agree with R
    # (car::Anova type 3) to full printed precision. Its Error and Total
    # rows do NOT: on an unbalanced 2x2 it reported SS_Error = 499.322
    # (df 7) where the true within-cell residual sum of squares is
    # 29.9167, and SS_Total = 1838.599 where the true centred total is
    # 1804.545. Because F and P in that report are formed from the bad
    # MS_Error, they are wrong too.
    #
    # SS_Error is therefore recomputed here as the sum over cells of the
    # within-cell squared deviations, SS_Total as the centred total sum
    # of squares, and F/P for each effect are re-derived from the
    # corrected MS_Error. The Type III effect sums of squares parsed
    # from Praat are used unchanged.

    if .error$ = ""
        selectObject: .tableId
        .nObs = Get number of rows
        .nCells = 0
        .nLev1 = 0
        .nLev2 = 0
        .sumAll = 0

        for .r from 1 to .nObs
            .l1$ = Get value: .r, .factor1$
            .l2$ = Get value: .r, .factor2$
            .yv = Get value: .r, .dataCol$
            .cellKey$ = .l1$ + newline$ + .l2$

            .cellIdx = 0
            for .c from 1 to .nCells
                if .cellLabel$[.c] = .cellKey$
                    .cellIdx = .c
                endif
            endfor
            if .cellIdx = 0
                .nCells = .nCells + 1
                .cellIdx = .nCells
                .cellLabel$[.cellIdx] = .cellKey$
                .cellN[.cellIdx] = 0
                .cellSum[.cellIdx] = 0
            endif

            .cellN[.cellIdx] = .cellN[.cellIdx] + 1
            .cellSum[.cellIdx] = .cellSum[.cellIdx] + .yv
            .cellOf[.r] = .cellIdx
            .yValue[.r] = .yv
            .sumAll = .sumAll + .yv

            # Track distinct levels of each factor for the balance check
            .seen1 = 0
            for .c from 1 to .nLev1
                if .lev1$[.c] = .l1$
                    .seen1 = 1
                endif
            endfor
            if .seen1 = 0
                .nLev1 = .nLev1 + 1
                .lev1$[.nLev1] = .l1$
            endif

            .seen2 = 0
            for .c from 1 to .nLev2
                if .lev2$[.c] = .l2$
                    .seen2 = 1
                endif
            endfor
            if .seen2 = 0
                .nLev2 = .nLev2 + 1
                .lev2$[.nLev2] = .l2$
            endif
        endfor

        .grandMean = .sumAll / .nObs
        for .c from 1 to .nCells
            .cellMean[.c] = .cellSum[.c] / .cellN[.c]
        endfor

        # Two-pass (centred) accumulation — numerically stable
        .ssError = 0
        .ssTotal = 0
        for .r from 1 to .nObs
            .ci = .cellOf[.r]
            .dev = .yValue[.r] - .cellMean[.ci]
            .ssError = .ssError + .dev * .dev
            .devTotal = .yValue[.r] - .grandMean
            .ssTotal = .ssTotal + .devTotal * .devTotal
        endfor

        .dfError = .nObs - .nCells
        .dfTotal = .nObs - 1

        # --- Negative sum-of-squares guard ---
        if .ssError < 0
            .warning$ = "The computed error sum of squares was negative "
            ... + "(" + fixed$ (.ssError, 10) + "); it was clamped to 0."
            .ssError = 0
        endif
        if .ssTotal < 0
            .warning$ = "The computed total sum of squares was negative "
            ... + "(" + fixed$ (.ssTotal, 10) + "); it was clamped to 0."
            .ssTotal = 0
        endif
        if .ssA < 0 or .ssB < 0 or .ssAB < 0
            .warning$ = "At least one Type III effect sum of squares is "
            ... + "negative; the model is degenerate."
        endif

        # --- Design balance check ---
        .balanced = 1
        .minCellN = .cellN[1]
        .maxCellN = .cellN[1]
        for .c from 2 to .nCells
            if .cellN[.c] < .minCellN
                .minCellN = .cellN[.c]
            endif
            if .cellN[.c] > .maxCellN
                .maxCellN = .cellN[.c]
            endif
        endfor
        if .nCells <> .nLev1 * .nLev2
            .balanced = 0
            .warning$ = "The design has empty cells ("
            ... + string$ (.nCells) + " of " + string$ (.nLev1 * .nLev2)
            ... + " factor combinations present); Type III sums of "
            ... + "squares are not estimable for this design."
        elsif .minCellN <> .maxCellN
            .balanced = 0
            .warning$ = "The design is unbalanced (cell sizes "
            ... + string$ (.minCellN) + " to " + string$ (.maxCellN)
            ... + "); Type III sums of squares do not add up to the "
            ... + "total sum of squares."
        endif

        if .dfError > 0
            .msError = .ssError / .dfError
        else
            .msError = undefined
            .warning$ = "The error degrees of freedom is "
            ... + string$ (.dfError) + ", so the error mean square, F "
            ... + "and p are undefined."
        endif

        # --- Re-derive F and P from the corrected MS_Error ---
        .fA = undefined
        .pA = undefined
        .fB = undefined
        .pB = undefined
        .fAB = undefined
        .pAB = undefined
        if .msError <> undefined
            if .msError > 0
                .msA = .ssA / .dfA
                .msB = .ssB / .dfB
                .msAB = .ssAB / .dfAB
                .fA = .msA / .msError
                .fB = .msB / .msError
                .fAB = .msAB / .msError
                .pA = fisherQ (.fA, .dfA, .dfError)
                .pB = fisherQ (.fB, .dfB, .dfError)
                .pAB = fisherQ (.fAB, .dfAB, .dfError)
            else
                .warning$ = "The error mean square is zero (no "
                ... + "within-cell variance), so F and p are undefined."
            endif
        endif
    endif

    # --- Compute partial eta-squared effect sizes ---

    if .error$ = ""
        .partialEtaSqA = .ssA / (.ssA + .ssError)
        .partialEtaSqB = .ssB / (.ssB + .ssError)
        .partialEtaSqAB = .ssAB / (.ssAB + .ssError)
    endif

    # --- Restore selection ---

    selectObject: .tableId
endproc



# ============================================================================
# @emlEpsilonSquared
# ============================================================================
# Epsilon-squared effect size for Kruskal-Wallis H test.
#
# Computes the Tomczak & Tomczak (2014) formula:
#   epsilon^2 = H / (N - 1)
#
# This is the formula used by R rstatix::kruskal_effsize(). It ranges
# from 0 (no effect) to 1 (complete separation). Interpretive
# guidelines (Rea & Parker 2014): < 0.01 negligible, 0.01–0.06 small,
# 0.06–0.14 medium, >= 0.14 large.
#
# This procedure is intentionally standalone. Users can call it with
# any H and N (not just from @emlKruskalWallis).
#
# Arguments:
#   .h  - H statistic (Kruskal-Wallis chi-squared approximation)
#   .n  - total number of observations (N)
#
# Output:
#   .result   - epsilon-squared, capped at 1
#   .capped   - 1 if the raw value exceeded 1 and was capped, else 0
#   .warning$ - non-fatal disclosure, or "" if none
#   .error$   - error message, or "" if valid
# ============================================================================

procedure emlEpsilonSquared: .h, .n
    .result = undefined
    .capped = 0
    .warning$ = ""
    .error$ = ""

    if .n <= 1
        .error$ = "Epsilon-squared needs a total sample size greater "
        ... + "than 1; got " + string$ (.n) + "."
    elsif .h < 0
        .error$ = "Epsilon-squared needs an H statistic of 0 or more; "
        ... + "got " + string$ (.h) + "."
    else
        .result = .h / (.n - 1)
        # epsilon-squared is a proportion of variance and cannot exceed
        # 1. H can slightly overshoot N - 1 with heavy tie correction,
        # which pushes the raw ratio above 1; hence the cap below.
        if .result > 1
            .capped = 1
            .warning$ = "Epsilon-squared came out as H / (N - 1) = "
            ... + fixed$ (.result, 6) + ", which exceeds 1; it was "
            ... + "capped at 1."
            .result = 1
        endif
    endif
endproc


# ============================================================================
# @emlKruskalWallis
# ============================================================================
# Kruskal-Wallis H test for k independent samples.
#
# Nonparametric one-way ANOVA on ranks. Tests whether k groups come
# from the same distribution. Uses the chi-squared approximation for
# the p-value.
#
# The H statistic is computed natively from global ranks (not by
# wrapping Praat's hidden Report command). This gives us mean ranks
# and tie correction as structured output — needed by Dunn's post-hoc
# and avoids Info window parsing fragility.
#
# Algorithm:
#   1. Extract all data and group labels from Table
#   2. Global ranking via @emlRankVector (average ties)
#   3. H_raw = [12 / (N(N+1))] * sum(Ri^2 / ni) - 3(N+1)
#   4. Tie correction: C = 1 - sum(tj^3 - tj) / (N^3 - N)
#   5. H = H_raw / C  (or H_raw if no ties)
#   6. p = chiSquareQ(H, k-1)
#   7. epsilon^2 = H / (N-1) via @emlEpsilonSquared
#
# Arguments:
#   .tableId    - ID of a Table object
#   .dataCol$   - name of the numeric data column
#   .factorCol$ - name of the string factor column
#
# Output:
#   .h             - H statistic (tie-corrected)
#   .p             - p-value (chi-squared approximation)
#   .df            - degrees of freedom (k - 1)
#   .n             - total N
#   .nGroups       - number of groups (k)
#   .groupName$[i] - group label for group i (1..nGroups)
#   .groupN[i]     - sample size for group i
#   .meanRank[i]   - mean rank for group i
#   .epsilonSq     - epsilon-squared effect size
#   .tieCorrection - tie correction factor C (1.0 if no ties)
#   .error$        - error message, or "" if valid
#
# Limits:
#   No group limit.
#
# Dependencies:
#   @emlCountGroups, @eml_getGroupData (eml-extract.praat)
#   @emlRankVector (eml-core-utilities.praat)
#   @emlEpsilonSquared (this file)
#   chiSquareQ() (Praat built-in)
# ============================================================================

procedure emlKruskalWallis: .tableId, .dataCol$, .factorCol$
    .h = undefined
    .p = undefined
    .df = undefined
    .n = 0
    .nGroups = 0
    .epsilonSq = undefined
    .tieCorrection = undefined
    .error$ = ""

    # --- The data column must be in the table ---
    #
    # Ahead of @emlCountGroups, because a column that is not there makes
    # every group look empty and the per-group guard below then reports the
    # first empty group -- "Group "H3" has 0 observations" -- which is true,
    # is about the groups, and is not the problem. See
    # @emlRequireColumnPresent.

    @emlRequireColumnPresent: .tableId, "Data column", .dataCol$
    .error$ = emlRequireColumnPresent.error$

    # --- Discover groups ---

    if .error$ = ""
        @emlCountGroups: .tableId, .factorCol$

        if emlCountGroups.error$ <> ""
            .error$ = emlCountGroups.error$
        else
            .nGroups = emlCountGroups.nGroups

            if .nGroups < 2
                .error$ = "This test compares 2 or more groups; the group "
                ... + "column """ + .factorCol$ + """ has "
                ... + string$ (.nGroups) + "."
            endif
        endif
    endif

    if .error$ = ""
        # Get per-group sizes
        .n = 0
        for .g from 1 to .nGroups
            .groupName$[.g] = emlCountGroups.groupLabel$[.g]
            @eml_getGroupData: .tableId, .dataCol$, .factorCol$,
            ... .groupName$[.g]
            .groupN[.g] = eml_getGroupData.n
            if .groupN[.g] = 0
                .error$ = "Group """ + .groupName$[.g]
                ... + """ has 0 observations. Every group needs at "
                ... + "least 1."
            endif
            .n = .n + .groupN[.g]
        endfor
    endif

    if .error$ = ""
        # Build flat data vector in group order
        .allData# = zero# (.n)
        .idx = 0
        for .g from 1 to .nGroups
            @eml_getGroupData: .tableId, .dataCol$, .factorCol$,
            ... .groupName$[.g]
            for .j from 1 to eml_getGroupData.n
                .idx = .idx + 1
                .allData#[.idx] = eml_getGroupData.data#[.j]
            endfor
        endfor
    endif

    if .error$ = ""
        # --- Global ranking ---

        @emlRankVector: .allData#
        .ranks# = emlRankVector.ranks#

        # --- Compute rank sums and mean ranks per group ---

        .offset = 0
        for .g from 1 to .nGroups
            .rankSum[.g] = 0
            for .j from 1 to .groupN[.g]
                .rankSum[.g] = .rankSum[.g]
                ... + .ranks#[.offset + .j]
            endfor
            .meanRank[.g] = .rankSum[.g] / .groupN[.g]
            .offset = .offset + .groupN[.g]
        endfor

        # --- Compute H statistic ---
        # H_raw = [12 / (N(N+1))] * sum(Ri^2 / ni) - 3(N+1)

        .sumTerm = 0
        for .g from 1 to .nGroups
            .sumTerm = .sumTerm
            ... + (.rankSum[.g] * .rankSum[.g]) / .groupN[.g]
        endfor

        .hRaw = (12 / (.n * (.n + 1))) * .sumTerm - 3 * (.n + 1)

        # --- Tie correction ---
        # C = 1 - sum(tj^3 - tj) / (N^3 - N)

        .tieCorrSum = emlRankVector.tieCorrectionSum

        if .tieCorrSum = 0
            .tieCorrection = 1
            .h = .hRaw
        else
            .denominator = .n ^ 3 - .n
            if .denominator = 0
                # Degenerate case (N <= 1, shouldn't reach here)
                .tieCorrection = 1
                .h = .hRaw
            else
                .tieCorrection = 1 - .tieCorrSum / .denominator
                if .tieCorrection <= 0
                    # All values identical — H must be 0
                    .h = 0
                    .tieCorrection = 0
                else
                    .h = .hRaw / .tieCorrection
                endif
            endif
        endif

        # --- p-value (chi-squared approximation) ---

        .df = .nGroups - 1

        # L7: a tiny-negative H from rounding on near-identical groups must
        # not reach chiSquareQ (undefined for negative argument). Clamp to 0.
        if .h < 0
            .h = 0
        endif
        if .h = 0
            .p = 1
        else
            .p = chiSquareQ (.h, .df)
        endif

        # --- Epsilon-squared effect size ---

        @emlEpsilonSquared: .h, .n
        if emlEpsilonSquared.error$ = ""
            .epsilonSq = emlEpsilonSquared.result
        else
            .epsilonSq = undefined
        endif
    endif

    # --- Restore selection ---

    selectObject: .tableId
endproc


# ============================================================================
# @emlDunnTest
# ============================================================================
# Dunn's post-hoc test for pairwise comparisons after Kruskal-Wallis.
#
# Uses global KW ranks (not re-ranked pairs) for z-statistics, which is
# the correct Dunn's test. The alternative (pairwise MWU) re-ranks
# within each pair and is a different, less standard, procedure.
#
# Algorithm:
#   1. Extract groups and compute global ranks (same as KW)
#   2. Compute tie-corrected variance:
#      sigma^2 = N(N+1)/12 - sum(tj^3 - tj) / (12(N-1))
#   3. For each pair (i,j):
#      z_ij = (mean_rank_i - mean_rank_j) / sqrt(sigma^2 * (1/ni + 1/nj))
#   4. Two-tailed raw p: 2 * gaussQ(|z|)
#   5. Adjust p-values via user-chosen method
#   6. Populate symmetric matrices
#
# Flat vector pair ordering:
#   (1,2), (1,3), ..., (1,k), (2,3), ..., (k-1,k)
#   Same as R dunn.test output.
#
# Arguments:
#   .tableId    - ID of a Table object
#   .dataCol$   - name of the numeric data column
#   .factorCol$ - name of the string factor column
#   .method$    - p-value adjustment: "bonferroni", "holm", or "bh"
#
# Output:
#   .pMatrix##     - k x k symmetric matrix (adjusted p; diagonal = 1)
#   .zMatrix##     - k x k antisymmetric matrix (z-stats; diagonal = 0)
#   .rMatrix##     - k x k antisymmetric rank-biserial r (per-pair,
#                    independently ranked via @emlRankBiserialR)
#   .rawP#         - unadjusted p-values, C(k,2) length
#   .adjustedP#    - adjusted p-values, C(k,2) length
#   .nGroups       - k
#   .nPairs        - C(k,2)
#   .groupName$[i] - group label for group i
#   .method$       - adjustment method used (echoed back)
#   .nSkipped      - number of pairs whose z could not be computed
#   .skipReason$   - first such failure's reason, or ""
#   .error$        - error message, or "" if valid
#
# Failed comparisons:
#   A pair with a degenerate standard error (zero tie-corrected rank
#   variance, or zero pairwise SE) yields undefined in .rawP#,
#   .adjustedP#, .zMatrix## and .pMatrix##, NOT p = 1. A comparison
#   that could not be made is missing, not non-significant.
#   .nSkipped / .skipReason$ report how many and why. The adjustment
#   procedures are NA-safe and exclude these pairs from the comparison
#   count, matching R's p.adjust.
#
# Dependencies:
#   @emlCountGroups, @eml_getGroupData (eml-extract.praat)
#   (eml_getGroupData now in eml-extract.praat)
#   @emlRankVector (eml-core-utilities.praat)
#   @emlRankBiserialR (eml-inferential.praat)
#   @emlBonferroni / @emlHolm / @emlBenjaminiHochberg (this file)
#   gaussQ() (Praat built-in)
# ============================================================================

procedure emlDunnTest: .tableId, .dataCol$, .factorCol$, .method$
    .nGroups = 0
    .nPairs = 0
    .nSkipped = 0
    .skipReason$ = ""
    .error$ = ""

    # --- Validate method ---

    if .method$ <> "bonferroni" and .method$ <> "holm"
    ... and .method$ <> "bh"
        .error$ = "The p-value adjustment method must be bonferroni, "
        ... + "holm, or bh; got: " + .method$
    endif

    # --- The data column must be in the table ---
    #
    # Ahead of the group work, because a column that is not there
    # makes every group look empty and the diagnosis then lands on
    # the grouping variable instead of the column the caller named.
    # Was: "Group ""H3"" has 0 observations" -- true, about the
    # groups, and not the problem.

    if .error$ = ""
        @emlRequireColumnPresent: .tableId, "Data column", .dataCol$
        .error$ = emlRequireColumnPresent.error$
    endif

    # --- Discover groups ---

    if .error$ = ""
        @emlCountGroups: .tableId, .factorCol$

        if emlCountGroups.error$ <> ""
            .error$ = emlCountGroups.error$
        else
            .nGroups = emlCountGroups.nGroups

            if .nGroups < 2
                .error$ = "This test compares 2 or more groups; the "
                ... + "group column """ + .factorCol$ + """ has "
                ... + string$ (.nGroups) + "."
            endif
        endif
    endif

    if .error$ = ""
        # Get per-group sizes
        .n = 0
        for .g from 1 to .nGroups
            .groupName$[.g] = emlCountGroups.groupLabel$[.g]
            @eml_getGroupData: .tableId, .dataCol$, .factorCol$,
            ... .groupName$[.g]
            .groupN[.g] = eml_getGroupData.n
            if .groupN[.g] = 0
                .error$ = "Group """ + .groupName$[.g]
                ... + """ has 0 observations. Every group needs at "
                ... + "least 1."
            endif
            .n = .n + .groupN[.g]
        endfor
    endif

    if .error$ = ""
        # Build flat data vector in group order
        .allData# = zero# (.n)
        .idx = 0
        for .g from 1 to .nGroups
            @eml_getGroupData: .tableId, .dataCol$, .factorCol$,
            ... .groupName$[.g]
            for .j from 1 to eml_getGroupData.n
                .idx = .idx + 1
                .allData#[.idx] = eml_getGroupData.data#[.j]
            endfor
        endfor
    endif

    if .error$ = ""
        # --- Global ranking ---

        @emlRankVector: .allData#
        .ranks# = emlRankVector.ranks#

        # --- Compute mean ranks per group ---

        .offset = 0
        for .g from 1 to .nGroups
            .rankSum = 0
            for .j from 1 to .groupN[.g]
                .rankSum = .rankSum + .ranks#[.offset + .j]
            endfor
            .meanRank[.g] = .rankSum / .groupN[.g]
            .offset = .offset + .groupN[.g]
        endfor

        # --- Compute tie-corrected variance ---
        # sigma^2 = N(N+1)/12 - sum(tj^3 - tj) / (12(N-1))

        .sigmaSq = .n * (.n + 1) / 12
        .tieCorrSum = emlRankVector.tieCorrectionSum
        if .tieCorrSum > 0 and .n > 1
            .sigmaSq = .sigmaSq
            ... - .tieCorrSum / (12 * (.n - 1))
        endif

        # --- Pairwise z-statistics and raw p-values ---

        .nPairs = .nGroups * (.nGroups - 1) / 2
        .rawP# = zero# (.nPairs)
        .zFlat# = zero# (.nPairs)

        .pairIdx = 0
        for .i from 1 to .nGroups - 1
            for .j from .i + 1 to .nGroups
                .pairIdx = .pairIdx + 1

                .diff = .meanRank[.i] - .meanRank[.j]

                # A degenerate standard error means the comparison could
                # not be made. Propagate undefined rather than p = 1,
                # which would read as a computed non-significant result.
                if .sigmaSq <= 0
                    # Degenerate: all values identical
                    .z = undefined
                    .rawPVal = undefined
                    .nSkipped = .nSkipped + 1
                    if .skipReason$ = ""
                        .skipReason$ = "tie-corrected rank variance is "
                        ... + "zero (all values identical)"
                    endif
                else
                    .se = sqrt (.sigmaSq
                    ... * (1 / .groupN[.i] + 1 / .groupN[.j]))

                    if .se = 0
                        .z = undefined
                        .rawPVal = undefined
                        .nSkipped = .nSkipped + 1
                        if .skipReason$ = ""
                            .skipReason$ = "pairwise standard error is zero"
                        endif
                    else
                        .z = .diff / .se
                        .rawPVal = 2 * gaussQ (abs (.z))
                    endif
                endif

                .zFlat#[.pairIdx] = .z
                .rawP#[.pairIdx] = .rawPVal
            endfor
        endfor

        # --- Adjust p-values ---

        if .method$ = "bonferroni"
            @emlBonferroni: .rawP#
            .adjustedP# = emlBonferroni.adjusted#
        elsif .method$ = "holm"
            @emlHolm: .rawP#
            .adjustedP# = emlHolm.adjusted#
        elsif .method$ = "bh"
            @emlBenjaminiHochberg: .rawP#
            .adjustedP# = emlBenjaminiHochberg.adjusted#
        endif

        # --- Populate matrices ---

        .pMatrix## = zero## (.nGroups, .nGroups)
        .zMatrix## = zero## (.nGroups, .nGroups)

        # Diagonal = 1 for p, 0 for z (already zero from zero##)
        for .g from 1 to .nGroups
            .pMatrix##[.g, .g] = 1
        endfor

        # Fill upper and lower triangles
        .pairIdx = 0
        for .i from 1 to .nGroups - 1
            for .j from .i + 1 to .nGroups
                .pairIdx = .pairIdx + 1
                .pMatrix##[.i, .j] = .adjustedP#[.pairIdx]
                .pMatrix##[.j, .i] = .adjustedP#[.pairIdx]
                .zMatrix##[.i, .j] = .zFlat#[.pairIdx]
                .zMatrix##[.j, .i] = -.zFlat#[.pairIdx]
            endfor
        endfor

        # --- Pairwise rank-biserial r (independently ranked per pair) ---

        .rMatrix## = zero## (.nGroups, .nGroups)
        for .i from 1 to .nGroups - 1
            for .j from .i + 1 to .nGroups
                @eml_getGroupData: .tableId, .dataCol$, .factorCol$,
                ... .groupName$[.i]
                if eml_getGroupData.error$ <> ""
                    .error$ = eml_getGroupData.error$
                    .rMatrix##[.i, .j] = undefined
                    .rMatrix##[.j, .i] = undefined
                else
                    .vI# = eml_getGroupData.data#
                    @eml_getGroupData: .tableId, .dataCol$, .factorCol$,
                    ... .groupName$[.j]
                    if eml_getGroupData.error$ <> ""
                        .error$ = eml_getGroupData.error$
                        .rMatrix##[.i, .j] = undefined
                        .rMatrix##[.j, .i] = undefined
                    else
                        @emlRankBiserialR: .vI#, eml_getGroupData.data#, 2
                        if emlRankBiserialR.error$ = ""
                            .rMatrix##[.i, .j] = emlRankBiserialR.r
                            .rMatrix##[.j, .i] = -emlRankBiserialR.r
                        else
                            .rMatrix##[.i, .j] = undefined
                            .rMatrix##[.j, .i] = undefined
                        endif
                    endif
                endif
            endfor
        endfor
    endif

    # --- Restore selection ---

    selectObject: .tableId
endproc


# ============================================================================
# @eml_getGroupData is now in eml-extract.praat (4-arg on-demand version).
# Old 1-arg dispatcher deleted in v1.1.


# ============================================================================
# @emlPairwiseT
# ============================================================================
# All-pairs independent t-tests with p-value adjustment and Cohen's d.
#
# Runs @emlTTest and @emlCohenD for each of the C(k,2) pairs, collects
# the raw two-tailed p-values, adjusts them via the chosen method, and
# populates symmetric p-value and antisymmetric t/d matrices.
#
# Arguments:
#   .tableId    - ID of a Table object
#   .dataCol$   - name of the numeric data column
#   .factorCol$ - name of the string factor column
#   .method$    - p-value adjustment: "bonferroni", "holm", or "bh"
#   .type$      - "welch" (default) or "student"
#
# Output:
#   .pMatrix##     - k x k adjusted p-values (symmetric, diagonal = 1)
#   .tMatrix##     - k x k t-statistics (antisymmetric, diagonal = 0)
#   .dfMatrix##    - k x k degrees of freedom for the matching t
#                    (symmetric, diagonal = 0). Welch-Satterthwaite
#                    when .type$ is "welch", pooled n1 + n2 - 2 when
#                    it is "student" — the same df the p-value in
#                    .pMatrix## was computed from, so a report can
#                    print t(df). Undefined wherever .tMatrix## is.
#   .dMatrix##     - k x k Cohen's d (antisymmetric, diagonal = 0)
#   .diffMatrix##  - k x k mean difference (antisymmetric, diagonal = 0),
#                    the point estimate every row states regardless of
#                    which correction is in force -- descriptive footing,
#                    the same as .dMatrix##. Captured from @emlTTest's own
#                    .meanDiff, never recomputed. Undefined wherever
#                    .tMatrix## is.
#   .rawP#         - unadjusted p-values, C(k,2) length
#   .adjustedP#    - adjusted p-values, C(k,2) length
#   .groupName$[i] - group label for group i
#   .nGroups       - k
#   .nPairs        - C(k,2)
#   .method$       - the TEST that was run: "Welch t-test" or
#                    "Student t-test" (pooled SD)
#   .adjustMethod$ - adjustment method used (echoed back: the .method$
#                    argument, i.e. "bonferroni", "holm", or "bh")
#   .nSkipped      - number of pairs whose t-test could not be computed
#   .skipReason$   - first such failure's message, or ""
#   .error$        - error message or ""
#
# Failed comparisons:
#   A pair whose t-test errors (e.g. zero variance in both groups)
#   yields undefined in .rawP#, .adjustedP#, .tMatrix## and .pMatrix##,
#   NOT p = 1. A comparison that could not be made is missing, not
#   non-significant. .nSkipped / .skipReason$ report how many and why.
#   The adjustment procedures are NA-safe and exclude these pairs from
#   the comparison count, matching R's p.adjust.
#
# Dependencies:
#   @emlCountGroups, @eml_getGroupData (eml-extract.praat)
#   @eml_getGroupData (eml-extract.praat)
#   @emlTTest (Batch 1)
#   @emlCohenD (Batch 1)
#   @emlBonferroni / @emlHolm / @emlBenjaminiHochberg (Batch 5)
# ============================================================================

procedure emlPairwiseT: .tableId, .dataCol$, .factorCol$, .method$, .type$
    .nGroups = 0
    .nPairs = 0
    .nSkipped = 0
    .skipReason$ = ""
    .adjustMethod$ = .method$
    .error$ = ""

    # --- Validate method ---

    if .method$ <> "bonferroni" and .method$ <> "holm"
    ... and .method$ <> "bh"
        .error$ = "The p-value adjustment method must be bonferroni, "
        ... + "holm, or bh; got: " + .method$
    endif

    # --- Validate type ---

    if .error$ = ""
        if .type$ <> "welch" and .type$ <> "student"
            .error$ = "The test type must be welch or student; got: "
            ... + .type$
        endif
    endif

    # --- Name the test, and keep the adjustment separate ---
    # .method$ must not echo back the ADJUSTMENT argument, or a report
    # layer reading it printed "Pairwise holm". .method$ now names the
    # test actually run; the adjustment stays available in
    # .adjustMethod$ (captured above, before .method$ is overwritten).

    if .error$ = ""
        if .type$ = "student"
            .method$ = "Student t-test"
        else
            .method$ = "Welch t-test"
        endif
    endif

    # --- The data column must be in the table ---
    #
    # Ahead of the group work, because a column that is not there
    # makes every group look empty and the diagnosis then lands on
    # the grouping variable instead of the column the caller named.
    # Was: nothing at all. This test returned an EMPTY error$ and a
    # matrix of undefined, which is D113a's shape surviving one layer
    # below the orchestrator that was patched for it.

    if .error$ = ""
        @emlRequireColumnPresent: .tableId, "Data column", .dataCol$
        .error$ = emlRequireColumnPresent.error$
    endif

    # --- ...and it must hold numbers ---
    #
    # NOT strict. This test reads the column row by row through
    # @eml_getGroupData, so the complete-case convention applies: a
    # column with SOME unusable cells is analysed on the rows that
    # parse. Only a column holding no numbers at all is refused.
    #
    # A presence guard alone is not enough here: an
    # all-blank column still ended in an empty error$ and a matrix of
    # undefined. No number was produced and none could be misread as a
    # result -- what was missing was the sentence saying why, and the
    # caller had no way to tell a refusal from a computation. The menu
    # path never reached it, because @emlRunPairwiseAnalysis asks the
    # same two questions first; a script calling this test straight,
    # which eml-lib-stats.praat exists to support, is entitled to the
    # same answer. Same reasoning as the presence guard's, one step on.

    if .error$ = ""
        @emlRequireNumericColumn: .tableId, "Data column", .dataCol$, 0
        .error$ = emlRequireNumericColumn.error$
    endif

    # --- Discover groups ---

    if .error$ = ""
        @emlCountGroups: .tableId, .factorCol$

        if emlCountGroups.error$ <> ""
            .error$ = emlCountGroups.error$
        else
            .nGroups = emlCountGroups.nGroups
            if .nGroups < 2
                .error$ = "This test compares 2 or more groups; the "
                ... + "group column """ + .factorCol$ + """ has "
                ... + string$ (.nGroups) + "."
            endif
        endif
    endif

    if .error$ = ""
        for .g from 1 to .nGroups
            .groupName$[.g] = emlCountGroups.groupLabel$[.g]
        endfor

        # --- Determine equalVariances flag ---
        .eqVar = 0
        if .type$ = "student"
            .eqVar = 1
        endif

        # --- Pairwise tests ---

        .nPairs = .nGroups * (.nGroups - 1) / 2
        .rawP# = zero# (.nPairs)
        .tFlat# = zero# (.nPairs)
        .dfFlat# = zero# (.nPairs)
        .dFlat# = zero# (.nPairs)
        .diffFlat# = zero# (.nPairs)

        .pairIdx = 0
        .pairError$ = ""
        for .i from 1 to .nGroups - 1
            for .j from .i + 1 to .nGroups
                .pairIdx = .pairIdx + 1

                # Get group vectors
                @eml_getGroupData: .tableId, .dataCol$, .factorCol$,
                ... .groupName$[.i]
                .vI# = eml_getGroupData.data#
                @eml_getGroupData: .tableId, .dataCol$, .factorCol$,
                ... .groupName$[.j]
                .vJ# = eml_getGroupData.data#

                # t-test
                @emlTTest: .vI#, .vJ#, 2, .eqVar
                if emlTTest.error$ <> ""
                    # Record but continue — some pairs may have
                    # zero variance while others are valid. The p-value
                    # is propagated as undefined rather than 1: a
                    # comparison that could not be made is missing, not
                    # non-significant. The adjustment step is NA-safe.
                    .tFlat#[.pairIdx] = undefined
                    .dfFlat#[.pairIdx] = undefined
                    .rawP#[.pairIdx] = undefined
                    .diffFlat#[.pairIdx] = undefined
                    .nSkipped = .nSkipped + 1
                    if .skipReason$ = ""
                        .skipReason$ = emlTTest.error$
                    endif
                    if .pairError$ = ""
                        .pairError$ = emlTTest.error$
                    endif
                else
                    .tFlat#[.pairIdx] = emlTTest.t
                    # Same df the p-value above came from: Welch-
                    # Satterthwaite for .type$ "welch", pooled
                    # n1 + n2 - 2 for "student". @emlTTest picks it
                    # from .eqVar, so no branch is needed here.
                    .dfFlat#[.pairIdx] = emlTTest.df
                    .rawP#[.pairIdx] = emlTTest.p
                    # The point estimate every row states regardless of
                    # correction -- captured from @emlTTest's own
                    # .meanDiff, not recomputed.
                    .diffFlat#[.pairIdx] = emlTTest.meanDiff
                endif

                # Cohen's d
                @emlCohenD: .vI#, .vJ#
                if emlCohenD.error$ <> ""
                    .dFlat#[.pairIdx] = undefined
                else
                    .dFlat#[.pairIdx] = emlCohenD.d
                endif
            endfor
        endfor

        # --- Adjust p-values ---

        if .adjustMethod$ = "bonferroni"
            @emlBonferroni: .rawP#
            .adjustedP# = emlBonferroni.adjusted#
        elsif .adjustMethod$ = "holm"
            @emlHolm: .rawP#
            .adjustedP# = emlHolm.adjusted#
        elsif .adjustMethod$ = "bh"
            @emlBenjaminiHochberg: .rawP#
            .adjustedP# = emlBenjaminiHochberg.adjusted#
        endif

        # --- Populate matrices ---

        .pMatrix## = zero## (.nGroups, .nGroups)
        .tMatrix## = zero## (.nGroups, .nGroups)
        .dfMatrix## = zero## (.nGroups, .nGroups)
        .dMatrix## = zero## (.nGroups, .nGroups)
        .diffMatrix## = zero## (.nGroups, .nGroups)

        for .g from 1 to .nGroups
            .pMatrix##[.g, .g] = 1
        endfor

        .pairIdx = 0
        for .i from 1 to .nGroups - 1
            for .j from .i + 1 to .nGroups
                .pairIdx = .pairIdx + 1
                .pMatrix##[.i, .j] = .adjustedP#[.pairIdx]
                .pMatrix##[.j, .i] = .adjustedP#[.pairIdx]
                .tMatrix##[.i, .j] = .tFlat#[.pairIdx]
                .tMatrix##[.j, .i] = -.tFlat#[.pairIdx]
                # df is unsigned, so this matrix is symmetric where
                # .tMatrix## is antisymmetric.
                .dfMatrix##[.i, .j] = .dfFlat#[.pairIdx]
                .dfMatrix##[.j, .i] = .dfFlat#[.pairIdx]
                .dMatrix##[.i, .j] = .dFlat#[.pairIdx]
                .dMatrix##[.j, .i] = -.dFlat#[.pairIdx]
                # Point estimate, same antisymmetric convention as t and
                # d: [row, col] is row's mean minus col's.
                .diffMatrix##[.i, .j] = .diffFlat#[.pairIdx]
                .diffMatrix##[.j, .i] = -.diffFlat#[.pairIdx]
            endfor
        endfor
    endif

    # --- Restore selection ---

    selectObject: .tableId
endproc


# ============================================================================
# @emlPairwiseWilcoxon
# ============================================================================
# All-pairs Mann-Whitney U tests with p-value adjustment and
# rank-biserial r effect size.
#
# Each pair is re-ranked independently (contrast with Dunn's test,
# which preserves the global KW ranking). Use Dunn's for KW follow-up;
# use PairwiseWilcoxon for general independent-group comparisons.
#
# Arguments:
#   .tableId    - ID of a Table object
#   .dataCol$   - name of the numeric data column
#   .factorCol$ - name of the string factor column
#   .method$    - p-value adjustment: "bonferroni", "holm", or "bh"
#
# Output:
#   .pMatrix##     - k x k adjusted p-values (symmetric, diagonal = 1)
#   .uMatrix##     - k x k U1 statistics (diagonal = 0)
#   .rMatrix##     - k x k rank-biserial r (antisymmetric, diagonal = 0)
#   .rawP#         - unadjusted p-values, C(k,2) length
#   .adjustedP#    - adjusted p-values, C(k,2) length
#   .groupName$[i] - group label for group i
#   .nGroups       - k
#   .nPairs        - C(k,2)
#   .method$       - adjustment method used (echoed back)
#   .nSkipped      - number of pairs whose test could not be computed
#   .skipReason$   - first such failure's message, or ""
#   .error$        - error message or ""
#
# Failed comparisons:
#   A pair whose Mann-Whitney test errors yields undefined in .rawP#,
#   .adjustedP#, .uMatrix##, .rMatrix## and .pMatrix##, NOT p = 1. A
#   comparison that could not be made is missing, not non-significant.
#   .nSkipped / .skipReason$ report how many and why. The adjustment
#   procedures are NA-safe and exclude these pairs from the comparison
#   count, matching R's p.adjust.
#
# Dependencies:
#   @emlCountGroups, @eml_getGroupData (eml-extract.praat)
#   @eml_getGroupData (eml-extract.praat)
#   @emlRankBiserialR (Batch 4, which calls @emlMannWhitneyU internally)
#   @emlBonferroni / @emlHolm / @emlBenjaminiHochberg (Batch 5)
# ============================================================================

procedure emlPairwiseWilcoxon: .tableId, .dataCol$, .factorCol$, .method$
    .nGroups = 0
    .nPairs = 0
    .nSkipped = 0
    .skipReason$ = ""
    .error$ = ""

    # --- Validate method ---

    if .method$ <> "bonferroni" and .method$ <> "holm"
    ... and .method$ <> "bh"
        .error$ = "The p-value adjustment method must be bonferroni, "
        ... + "holm, or bh; got: " + .method$
    endif

    # --- The data column must be in the table ---
    #
    # Ahead of the group work, because a column that is not there
    # makes every group look empty and the diagnosis then lands on
    # the grouping variable instead of the column the caller named.
    # Was: nothing at all. This test returned an EMPTY error$ and a
    # matrix of undefined, which is D113a's shape surviving one layer
    # below the orchestrator that was patched for it.

    if .error$ = ""
        @emlRequireColumnPresent: .tableId, "Data column", .dataCol$
        .error$ = emlRequireColumnPresent.error$
    endif

    # --- ...and it must hold numbers ---
    #
    # NOT strict, for the same reason as @emlPairwiseT above: this test
    # reads the column row by row through @eml_getGroupData, so a column
    # with SOME unusable cells is analysed on the rows that parse and
    # only a column holding no numbers at all is refused. The full note
    # is at @emlPairwiseT; without this these two are left with a
    # presence guard and no type guard, and they are closed together
    # because a caller cannot be expected to know which of the two
    # pairwise tests answers.

    if .error$ = ""
        @emlRequireNumericColumn: .tableId, "Data column", .dataCol$, 0
        .error$ = emlRequireNumericColumn.error$
    endif

    # --- Discover groups ---

    if .error$ = ""
        @emlCountGroups: .tableId, .factorCol$

        if emlCountGroups.error$ <> ""
            .error$ = emlCountGroups.error$
        else
            .nGroups = emlCountGroups.nGroups
            if .nGroups < 2
                .error$ = "This test compares 2 or more groups; the "
                ... + "group column """ + .factorCol$ + """ has "
                ... + string$ (.nGroups) + "."
            endif
        endif
    endif

    if .error$ = ""
        for .g from 1 to .nGroups
            .groupName$[.g] = emlCountGroups.groupLabel$[.g]
        endfor

        # Cache per-group sizes (avoids redundant extraction in matrix fill)
        for .g from 1 to .nGroups
            @eml_getGroupData: .tableId, .dataCol$, .factorCol$,
            ... .groupName$[.g]
            .groupN[.g] = eml_getGroupData.n
        endfor

        # --- Pairwise tests ---

        .nPairs = .nGroups * (.nGroups - 1) / 2
        .rawP# = zero# (.nPairs)
        .uFlat# = zero# (.nPairs)
        .rFlat# = zero# (.nPairs)

        .pairIdx = 0
        for .i from 1 to .nGroups - 1
            for .j from .i + 1 to .nGroups
                .pairIdx = .pairIdx + 1

                @eml_getGroupData: .tableId, .dataCol$, .factorCol$,
                ... .groupName$[.i]
                .vI# = eml_getGroupData.data#
                @eml_getGroupData: .tableId, .dataCol$, .factorCol$,
                ... .groupName$[.j]
                .vJ# = eml_getGroupData.data#

                # MWU + rank-biserial r
                @emlRankBiserialR: .vI#, .vJ#, 2
                if emlRankBiserialR.error$ <> ""
                    # Propagate undefined rather than p = 1: a
                    # comparison that could not be made is missing,
                    # not non-significant. The adjustment is NA-safe.
                    .uFlat#[.pairIdx] = undefined
                    .rFlat#[.pairIdx] = undefined
                    .rawP#[.pairIdx] = undefined
                    .nSkipped = .nSkipped + 1
                    if .skipReason$ = ""
                        .skipReason$ = emlRankBiserialR.error$
                    endif
                else
                    .uFlat#[.pairIdx] = emlRankBiserialR.u1
                    .rFlat#[.pairIdx] = emlRankBiserialR.r
                    .rawP#[.pairIdx] = emlRankBiserialR.p
                endif
            endfor
        endfor

        # --- Adjust p-values ---

        if .method$ = "bonferroni"
            @emlBonferroni: .rawP#
            .adjustedP# = emlBonferroni.adjusted#
        elsif .method$ = "holm"
            @emlHolm: .rawP#
            .adjustedP# = emlHolm.adjusted#
        elsif .method$ = "bh"
            @emlBenjaminiHochberg: .rawP#
            .adjustedP# = emlBenjaminiHochberg.adjusted#
        endif

        # --- Populate matrices ---

        .pMatrix## = zero## (.nGroups, .nGroups)
        .uMatrix## = zero## (.nGroups, .nGroups)
        .rMatrix## = zero## (.nGroups, .nGroups)

        for .g from 1 to .nGroups
            .pMatrix##[.g, .g] = 1
        endfor

        .pairIdx = 0
        for .i from 1 to .nGroups - 1
            for .j from .i + 1 to .nGroups
                .pairIdx = .pairIdx + 1
                .pMatrix##[.i, .j] = .adjustedP#[.pairIdx]
                .pMatrix##[.j, .i] = .adjustedP#[.pairIdx]
                .uMatrix##[.i, .j] = .uFlat#[.pairIdx]
                # U2 = n1*n2 - U1; store in lower triangle
                .uMatrix##[.j, .i] = .groupN[.i] * .groupN[.j]
                ... - .uFlat#[.pairIdx]
                .rMatrix##[.i, .j] = .rFlat#[.pairIdx]
                .rMatrix##[.j, .i] = -.rFlat#[.pairIdx]
            endfor
        endfor
    endif

    # --- Restore selection ---

    selectObject: .tableId
endproc


# ============================================================================
# @emlScheffe
# ============================================================================
# Scheffé post-hoc test for pairwise (and all-contrast) comparisons.
#
# Computes the Scheffé F statistic for each pair of group means and
# tests against the F distribution with df1 = k-1, df2 = N-k. The
# critical value inherently controls FWER for all possible contrasts
# (not just pairwise), making it the most conservative standard
# post-hoc for pairwise-only comparisons.
#
# For pairwise-only comparisons, Tukey HSD or Bonferroni-adjusted
# t-tests are preferred (tighter). Use Scheffé when you may also test
# non-pairwise contrasts (e.g., group1+group2 vs group3).
#
# Algorithm:
#   1. Extract groups, compute group means and sizes
#   2. SSwithin = sum of within-group SS; MSE = SSwithin / (N - k)
#   3. For each pair (i,j):
#      diff = mean_i - mean_j
#      SE = sqrt(MSE * (1/n_i + 1/n_j))
#      F_scheffe = (diff / SE)^2 / (k - 1)
#      p = fisherQ(F_scheffe, k - 1, N - k)
#   4. Populate matrices
#
# Arguments:
#   .tableId    - ID of a Table object
#   .dataCol$   - name of the numeric data column
#   .factorCol$ - name of the string factor column
#
# Output:
#   .pMatrix##     - k x k Scheffe p-values (symmetric, diagonal = 1)
#   .fMatrix##     - k x k F-Scheffe statistics (symmetric, diagonal = 0)
#   .diffMatrix##  - k x k mean differences (antisymmetric, diagonal = 0)
#   .seMatrix##    - k x k pairwise standard errors, sqrt(MSE * (1/n_i +
#                    1/n_j)) (SYMMETRIC -- an SE has no sign -- diagonal =
#                    0). Added for @emlScheffeInterval (item 5, 26 August
#                    interval work order): the per-pair SE was computed
#                    here already, to build .fMatrix##, but discarded
#                    rather than published. This header amendment makes it
#                    a contractual output rather than an internal the
#                    interval procedure would otherwise have to recompute
#                    (and, computed a second time from .diffMatrix##/.fMatrix##
#                    alone, could not be, since the sign of the diff is
#                    lost from F).
#   .groupName$[i] - group label for group i
#   .nGroups       - k
#   .nPairs        - C(k,2)
#   .mse           - within-group mean square error
#   .dfWithin      - degrees of freedom for error term (N - k)
#   .error$        - error message or ""
#
# Dependencies:
#   @emlCountGroups, @eml_getGroupData (eml-extract.praat)
#   @eml_getGroupData (eml-extract.praat)
#   fisherQ() (Praat built-in)
# ============================================================================

procedure emlScheffe: .tableId, .dataCol$, .factorCol$
    .nGroups = 0
    .nPairs = 0
    .mse = undefined
    .dfWithin = undefined
    .error$ = ""

    # --- The data column must be in the table ---
    #
    # Ahead of the group work, because a column that is not there
    # makes every group look empty and the diagnosis then lands on
    # the grouping variable instead of the column the caller named.
    # Was: "0 observations across 3 groups leave no within-groups
    # degrees of freedom" -- a statement about the design.

    if .error$ = ""
        @emlRequireColumnPresent: .tableId, "Data column", .dataCol$
        .error$ = emlRequireColumnPresent.error$
    endif

    # --- Discover groups ---
    #
    # NESTED in `if .error$ = ""`, unlike the version this replaces. The
    # block must not run unconditionally and assign emlCountGroups.error$
    # over whatever was already in .error$, which would have thrown away
    # the missing-column refusal above whenever the FACTOR column happened
    # to be fine -- the exact case the guard exists for.

    if .error$ = ""
        @emlCountGroups: .tableId, .factorCol$

        if emlCountGroups.error$ <> ""
            .error$ = emlCountGroups.error$
        else
            .nGroups = emlCountGroups.nGroups
            if .nGroups < 2
                .error$ = "This test compares 2 or more groups; the group "
                ... + "column """ + .factorCol$ + """ has "
                ... + string$ (.nGroups) + "."
            endif
        endif
    endif

    if .error$ = ""
        for .g from 1 to .nGroups
            .groupName$[.g] = emlCountGroups.groupLabel$[.g]
        endfor

        # --- Compute group means, sizes, and SSwithin ---

        .totalN = 0
        .ssWithin = 0

        for .g from 1 to .nGroups
            @eml_getGroupData: .tableId, .dataCol$, .factorCol$,
            ... .groupName$[.g]
            .gN[.g] = eml_getGroupData.n
            .gData# = eml_getGroupData.data#
            .totalN = .totalN + .gN[.g]

            if .gN[.g] > 0
                .gMean[.g] = mean (.gData#)
            else
                .gMean[.g] = undefined
            endif

            # Within-group SS: sum of (x - group_mean)^2
            for .idx from 1 to .gN[.g]
                .dev = .gData#[.idx] - .gMean[.g]
                .ssWithin = .ssWithin + .dev * .dev
            endfor
        endfor

        # MSE
        .dfWithin = .totalN - .nGroups
        if .dfWithin <= 0
            .error$ = string$ (.totalN) + " observations across "
            ... + string$ (.nGroups) + " groups leave no within-groups "
            ... + "degrees of freedom. There must be more observations "
            ... + "than groups."
        else
            .mse = .ssWithin / .dfWithin
        endif
    endif

    if .error$ = ""
        # --- Pairwise Scheffe F and p ---

        .nPairs = .nGroups * (.nGroups - 1) / 2
        .pMatrix## = zero## (.nGroups, .nGroups)
        .fMatrix## = zero## (.nGroups, .nGroups)
        .diffMatrix## = zero## (.nGroups, .nGroups)
        .seMatrix## = zero## (.nGroups, .nGroups)

        for .g from 1 to .nGroups
            .pMatrix##[.g, .g] = 1
        endfor

        for .i from 1 to .nGroups - 1
            for .j from .i + 1 to .nGroups
                .diff = .gMean[.i] - .gMean[.j]
                .se = sqrt (.mse * (1 / .gN[.i] + 1 / .gN[.j]))

                if .se = 0
                    .fScheffe = 0
                    .pVal = 1
                else
                    .fScheffe = (.diff / .se) ^ 2
                    ... / (.nGroups - 1)
                    .pVal = fisherQ (.fScheffe,
                    ... .nGroups - 1, .dfWithin)
                endif

                .pMatrix##[.i, .j] = .pVal
                .pMatrix##[.j, .i] = .pVal
                .fMatrix##[.i, .j] = .fScheffe
                .fMatrix##[.j, .i] = .fScheffe
                .diffMatrix##[.i, .j] = .diff
                .diffMatrix##[.j, .i] = -.diff
                # SE has no sign -- symmetric, unlike .diffMatrix##.
                .seMatrix##[.i, .j] = .se
                .seMatrix##[.j, .i] = .se
            endfor
        endfor
    endif

    # --- Restore selection ---

    selectObject: .tableId
endproc


# ============================================================================
# @emlScheffeInterval
# ============================================================================
# Simultaneous confidence interval for one Scheffe pairwise mean
# difference (item 5, 26 August 2026 interval work order,
# docs/WORK_ORDER_INTERVALS_2026-08-26.md).
#
# NO ALGORITHM IS PORTED HERE. Half-width = sqrt((k-1) * F_crit) * SE,
# F_crit = invFisherQ(alpha, k-1, dfWithin) -- the textbook Scheffe
# multiplier applied to the pairwise SE @emlScheffe already computes.
#
# THE ALPHA POINT IS THE WHOLE PROCEDURE. .level is never formed here --
# there is no .level parameter at all, on purpose. Every other interval in
# this file (@emlTTestInterval, @emlHodgesLehmannTwoSample,
# @emlHodgesLehmannPaired) takes a caller-computed LEVEL, typically
# 1 - alpha/m for Bonferroni. Scheffe does not: sqrt((k-1) * F_crit) IS the
# simultaneity correction across all C(k,2) pairwise contrasts (indeed
# across every possible linear contrast, not only pairwise ones), so the
# multiplier already spends the family-wise budget. Dividing .alpha by the
# pair count on top, as the Bonferroni call sites do, would correct twice
# and return an interval narrower than the true simultaneous one while
# looking exactly as reasonable -- Fable's red demo 1 for this check names
# this exact mistake.
#
# invFisherQ(p, df1, df2) driven on Praat 6.6.30 (see the check's own
# fixture, and eml-psychometrics.praat's existing invFisherQ(0.025/0.975,
# .df1, .df2) call, which established the name and argument order first):
# it returns the F critical value whose UPPER tail probability is p,
# df1 first (between/numerator), df2 second (within/denominator) -- the
# same order @emlScheffe's own fisherQ(.fScheffe, .nGroups - 1, .dfWithin)
# call already uses for the p-value the other direction. Unlike
# invStudentQ, which hangs on invStudentQ(0, df) (@emlTTestInterval's own
# comment), invFisherQ degrades to --undefined-- at p = 0 or at either df
# <= 0 or undefined, and to 0 at p = 1 -- measured directly, no hang at any
# of those boundaries. The guard below is therefore not a hang guard; it
# exists so a caller gets a named refusal instead of a silent undefined,
# matching the family's estimate-is-descriptive / refusal-is-a-result
# convention (docs/RULING_ITEM3_CASES_2026-08-26.md, case 1).
#
# Arguments:
#   .meanDiff  - the pairwise mean difference (group i minus group j),
#                @emlScheffe's own .diffMatrix##[i, j]. Descriptive: it is
#                not corrected by anything below and survives even where
#                the interval cannot be computed, provided it is itself a
#                defined number.
#   .se        - the pairwise standard error, @emlScheffe's own
#                .seMatrix##[i, j] (sqrt(MSE * (1/n_i + 1/n_j))).
#   .k         - number of groups, @emlScheffe's .nGroups. Feeds both the
#                multiplier's (k - 1) and invFisherQ's df1 = k - 1.
#   .dfWithin  - error term degrees of freedom, @emlScheffe's own
#                .dfWithin (N - k). NEVER RECOMPUTED HERE, same rule as
#                @emlTTestInterval's df: it is the caller's variant, taken
#                as given.
#   .alpha     - THE ANALYSIS ALPHA, DIRECTLY. Never alpha/m. The
#                simultaneity correction is the multiplier above, not a
#                divided alpha.
#
# Output:
#   .low, .high - the interval bounds, or undefined if .error$ <> ""
#   .error$     - error message, or "" if valid
# ============================================================================

procedure emlScheffeInterval: .meanDiff, .se, .k, .dfWithin, .alpha
    .low = undefined
    .high = undefined
    .error$ = ""

    if .dfWithin = undefined or .dfWithin <= 0
        .error$ = "Degrees of freedom are undefined"
    elsif .k = undefined or .k < 2
        .error$ = "This test compares 2 or more groups"
    elsif .se = undefined
        .error$ = "Standard error is undefined"
    elsif .alpha = undefined
        .error$ = "Alpha is undefined"
    else
        .fCrit = invFisherQ (.alpha, .k - 1, .dfWithin)
        .halfWidth = sqrt ((.k - 1) * .fCrit) * .se
        .low = .meanDiff - .halfWidth
        .high = .meanDiff + .halfWidth
    endif
endproc


# ============================================================================
# @emlBrownForsythe
# ============================================================================
# Levene's test for homogeneity of variance with MEDIAN centring
# (Brown & Forsythe 1974), i.e. a one-way ANOVA on the absolute
# deviations from each group's own median:
#
#     z_ij = |x_ij - median_j|,  F = MS_between(z) / MS_within(z)
#
# Median centring is the robust variant: it holds its nominal size on
# skewed and heavy-tailed data, where mean centring (the original
# Levene 1960 statistic) is liberal. This is what R's
# car::leveneTest(center = median) computes, and what SPSS labels
# "Based on Median".
#
# Arguments:
#   .tableId    - ID of a Table object (must be in object list)
#   .dataCol$   - name of the numeric data column
#   .factorCol$ - name of the string factor column
#
# Output:
#   .f          - F statistic on the absolute deviations
#   .df1        - between-groups degrees of freedom (k - 1)
#   .df2        - within-groups degrees of freedom (N - k)
#   .p          - p-value (from fisherQ)
#   .nGroups    - number of groups (k)
#   .totalN     - number of observations used (N)
#   .ssBetween  - between-groups sum of squares of the deviations
#   .ssWithin   - within-groups sum of squares of the deviations
#   .msBetween  - .ssBetween / .df1
#   .msWithin   - .ssWithin / .df2
#   .groupLabel$[g] - label of group g (1..k, alphabetical)
#   .groupN[g]      - size of group g
#   .groupMedian[g] - median of group g (in the caller's own units)
#   .groupMeanDev[g] - mean absolute deviation of group g
#   .warning$   - non-fatal disclosure, or "" if none
#   .error$     - "" on success, diagnostic message on failure
#
# Notes:
#   - Refuses on exactly the conditions @emlOneWayAnova refuses on, with
#     the same messages: fewer than 3 rows, a missing column, fewer than
#     2 groups, and any group with fewer than 2 usable observations
#     (which is also how a non-numeric data column presents, since
#     @eml_getGroupData drops the unusable rows first). The offending
#     groups are named.
#   - Does NOT call @emlOneWayAnova. The ANOVA on the deviations is
#     computed here so that this procedure leaves emlOneWayAnova's own
#     outputs untouched for a caller that reports both.
#   - Sums of squares use the corrected two-pass form, as in
#     @emlOneWayAnova. The deviations are already centred near zero, so
#     the location shift @emlOneWayAnova needs is not required here.
#   - Dependencies: @emlCountGroups, @eml_getGroupData (eml-extract.praat)
#   - Original Table selection is restored on return
# ============================================================================

procedure emlBrownForsythe: .tableId, .dataCol$, .factorCol$
    .f = undefined
    .df1 = undefined
    .df2 = undefined
    .p = undefined
    .nGroups = 0
    .totalN = 0
    .ssBetween = undefined
    .ssWithin = undefined
    .msBetween = undefined
    .msWithin = undefined
    .warning$ = ""
    .error$ = ""

    # --- Validate inputs ---

    selectObject: .tableId
    .nRows = Get number of rows
    if .nRows < 3
        .error$ = "Need at least 3 observations, got "
        ... + string$ (.nRows) + "."
    endif

    if .error$ = ""
        @emlRequireColumnPresent: .tableId, "Data column", .dataCol$
        .error$ = emlRequireColumnPresent.error$
    endif

    if .error$ = ""
        @emlRequireColumnPresent: .tableId, "Factor column", .factorCol$
        .error$ = emlRequireColumnPresent.error$
    endif

    # --- Count and extract groups ---

    if .error$ = ""
        @emlCountGroups: .tableId, .factorCol$
        if emlCountGroups.error$ <> ""
            .error$ = emlCountGroups.error$
        else
            .nGroups = emlCountGroups.nGroups
        endif
    endif

    if .error$ = ""
        if .nGroups < 2
            .error$ = "Group column """ + .factorCol$ + """ has "
            ... + string$ (.nGroups) + " group. This test compares 2 or more."
        endif
    endif

    # --- Group sizes: state the diagnosis, not the first offender ---
    # Same rule, and the same message, as @emlOneWayAnova: as many
    # groups as rows means the column is an identifier; otherwise name the
    # offenders together rather than raising on the first one found.

    if .error$ = ""
        .nSingleton = 0
        .singletonList$ = ""
        for .g from 1 to .nGroups
            @eml_getGroupData: .tableId, .dataCol$, .factorCol$,
            ... emlCountGroups.groupLabel$[.g]
            if eml_getGroupData.n < 2
                .nSingleton = .nSingleton + 1
                if .nSingleton <= 5
                    if .singletonList$ <> ""
                        .singletonList$ = .singletonList$ + ", "
                    endif
                    .singletonList$ = .singletonList$ + """"
                    ... + emlCountGroups.groupLabel$[.g] + """"
                endif
            endif
        endfor

        if .nSingleton > 0
            if .nGroups = .nRows
                .error$ = "Group column """ + .factorCol$ + """ has "
                ... + string$ (.nGroups) + " groups for "
                ... + string$ (.nRows) + " rows - one per row. This is an "
                ... + "identifier column, not a grouping column."
            else
                .error$ = string$ (.nSingleton) + " of "
                ... + string$ (.nGroups) + " groups in """
                ... + .factorCol$ + """ have fewer than 2 observations: "
                ... + .singletonList$
                if .nSingleton > 5
                    .error$ = .error$ + ", and "
                    ... + string$ (.nSingleton - 5) + " more"
                endif
                .error$ = .error$ + ". Every group needs at least 2."
            endif
        endif
    endif

    # --- Pass 1: group medians, absolute deviations, SS within ---

    if .error$ = ""
        .totalN = 0
        .ssWithin = 0
        .sumOfDeviations = 0

        for .g from 1 to .nGroups
            @eml_getGroupData: .tableId, .dataCol$, .factorCol$,
            ... emlCountGroups.groupLabel$[.g]
            .gN = eml_getGroupData.n
            .gData# = eml_getGroupData.data#

            ; Median of the group. Sizes were validated above, so .gN >= 2.
            .sorted# = sort# (.gData#)
            if .gN mod 2 = 1
                .med = .sorted# [(.gN + 1) / 2]
            else
                .med = (.sorted# [.gN / 2] + .sorted# [.gN / 2 + 1]) / 2
            endif

            .dev# = abs# (.gData# - .med)

            .groupLabel$[.g] = emlCountGroups.groupLabel$[.g]
            .groupN[.g] = .gN
            .groupMedian[.g] = .med
            .groupMeanDev[.g] = mean (.dev#)

            ; Corrected two-pass within-group sum of squares (Chan, Golub &
            ; LeVeque 1983), as in @emlOneWayAnova: the second term is the
            ; error left in the group mean, removed rather than squared in.
            .centered# = .dev# - .groupMeanDev[.g]
            .sumDev = sum (.centered#)
            .ssWithin = .ssWithin + sum (.centered# * .centered#)
            ... - .sumDev * .sumDev / .gN

            .totalN = .totalN + .gN
            .sumOfDeviations = .sumOfDeviations + sum (.dev#)
        endfor
    endif

    # --- Pass 2: between-groups sum of squares, F, p ---

    if .error$ = ""
        .grandMeanDev = .sumOfDeviations / .totalN

        .ssBetween = 0
        for .g from 1 to .nGroups
            .gDev = .groupMeanDev[.g] - .grandMeanDev
            .ssBetween = .ssBetween + .groupN[.g] * .gDev * .gDev
        endfor

        .df1 = .nGroups - 1
        .df2 = .totalN - .nGroups
        .msBetween = .ssBetween / .df1
        .msWithin = .ssWithin / .df2

        ; Every observation the same distance from its group median (two
        ; observations per group, say) makes MS-within zero. F is then a
        ; division by zero, so it is refused rather than reported, in the
        ; same shape @emlOneWayAnova uses for the same degeneracy.
        if .msWithin > 0
            .f = .msBetween / .msWithin
            .p = fisherQ (.f, .df1, .df2)
        else
            .f = undefined
            .p = undefined
            .warning$ = "Within-groups mean square of the absolute "
            ... + "deviations is zero (every observation is the same "
            ... + "distance from its group median); F and p are undefined"
        endif
    endif

    # --- Restore selection ---

    selectObject: .tableId
endproc


# ============================================================================
# @emlWelchAnova
# ============================================================================
# Welch's heteroscedastic k-sample F test (Welch 1951): a one-way
# analysis of means that does not assume equal variances. This is what
# R's oneway.test(var.equal = FALSE) computes.
#
# With w_j = n_j / s_j^2 and W = sum(w_j):
#
#     xbar_w = sum(w_j * xbar_j) / W
#     A      = sum(w_j * (xbar_j - xbar_w)^2) / (k - 1)
#     L      = sum( (1 - w_j/W)^2 / (n_j - 1) )
#     B      = 2*(k - 2) / (k^2 - 1) * L
#     F      = A / (1 + B)
#     df1    = k - 1
#     df2    = (k^2 - 1) / (3 * L)
#
# The df2 given here is the same quantity as the more commonly written
# 1 / (3*B / (2*(k - 2))): substituting B cancels the (k - 2) factor,
# leaving (k^2 - 1) / (3L). Written this way it is also correct at
# k = 2, where B = 0 and the textbook form is 0/0. At k = 2 the
# statistic reduces exactly to Welch's t^2 with the
# Welch-Satterthwaite df:
#
#     A = (xbar_1 - xbar_2)^2 / (v_1 + v_2) = t_welch^2
#     (k^2-1)/(3L) = (v_1 + v_2)^2
#                    / (v_1^2/(n_1-1) + v_2^2/(n_2-1))
#
# with v_j = s_j^2/n_j. That identity is asserted numerically in
# validate/v22_homogeneity.R, not merely claimed here.
#
# Arguments:
#   .tableId    - ID of a Table object (must be in object list)
#   .dataCol$   - name of the numeric data column
#   .factorCol$ - name of the string factor column
#
# Output:
#   .f          - Welch's F statistic
#   .df1        - k - 1
#   .df2        - fractional denominator degrees of freedom
#   .p          - p-value (from fisherQ)
#   .nGroups    - number of groups (k)
#   .totalN     - number of observations used (N)
#   .sumWeights - W = sum(n_j / s_j^2)
#   .weightedMean - xbar_w
#   .lambda     - L, the weight-dispersion sum above
#   .groupLabel$[g] - label of group g (1..k, alphabetical)
#   .groupN[g]      - size of group g
#   .groupMean[g]   - mean of group g
#   .groupVar[g]    - sample variance of group g (n - 1 denominator)
#   .groupWeight[g] - w_j for group g
#   .warning$   - non-fatal disclosure, or "" if none
#   .error$     - "" on success, diagnostic message on failure
#
# Notes:
#   - Refuses, naming the offending groups, when any group has fewer
#     than 2 observations or zero variance. A zero variance is not a
#     recoverable degeneracy here: w_j = n_j/0 is the weight the whole
#     statistic is built on.
#   - Group means are formed in shifted coordinates before the weighted
#     grand mean is subtracted, for the same reason @emlOneWayAnova
#     shifts: on data with many constant leading digits, forming
#     (xbar_j - xbar_w) on raw values cancels away the mantissa before
#     the squaring. The shift is exact -- F is invariant under it.
#   - Dependencies: @emlCountGroups, @eml_getGroupData (eml-extract.praat)
#   - Original Table selection is restored on return
# ============================================================================

procedure emlWelchAnova: .tableId, .dataCol$, .factorCol$
    .f = undefined
    .df1 = undefined
    .df2 = undefined
    .p = undefined
    .nGroups = 0
    .totalN = 0
    .sumWeights = undefined
    .weightedMean = undefined
    .lambda = undefined
    .warning$ = ""
    .error$ = ""

    # --- Validate inputs ---

    selectObject: .tableId
    .nRows = Get number of rows
    if .nRows < 3
        .error$ = "Need at least 3 observations, got "
        ... + string$ (.nRows) + "."
    endif

    if .error$ = ""
        @emlRequireColumnPresent: .tableId, "Data column", .dataCol$
        .error$ = emlRequireColumnPresent.error$
    endif

    if .error$ = ""
        @emlRequireColumnPresent: .tableId, "Factor column", .factorCol$
        .error$ = emlRequireColumnPresent.error$
    endif

    # --- Count and extract groups ---

    if .error$ = ""
        @emlCountGroups: .tableId, .factorCol$
        if emlCountGroups.error$ <> ""
            .error$ = emlCountGroups.error$
        else
            .nGroups = emlCountGroups.nGroups
        endif
    endif

    if .error$ = ""
        if .nGroups < 2
            .error$ = "Group column """ + .factorCol$ + """ has "
            ... + string$ (.nGroups) + " group. This test compares 2 or more."
        endif
    endif

    # --- Group sizes and variances, in one pass, naming every offender ---

    if .error$ = ""
        .totalN = 0
        .sumOfMeans = 0
        .nSingleton = 0
        .singletonList$ = ""
        .nFlat = 0
        .flatList$ = ""

        for .g from 1 to .nGroups
            @eml_getGroupData: .tableId, .dataCol$, .factorCol$,
            ... emlCountGroups.groupLabel$[.g]
            .gN = eml_getGroupData.n
            .groupLabel$[.g] = emlCountGroups.groupLabel$[.g]
            .groupN[.g] = .gN

            if .gN < 2
                .groupMean[.g] = undefined
                .groupVar[.g] = undefined
                .nSingleton = .nSingleton + 1
                if .nSingleton <= 5
                    if .singletonList$ <> ""
                        .singletonList$ = .singletonList$ + ", "
                    endif
                    .singletonList$ = .singletonList$ + """"
                    ... + .groupLabel$[.g] + """"
                endif
            else
                .gData# = eml_getGroupData.data#
                .groupMean[.g] = mean (.gData#)

                ; Corrected two-pass variance, as elsewhere in this file.
                .centered# = .gData# - .groupMean[.g]
                .sumDev = sum (.centered#)
                .gSS = sum (.centered# * .centered#)
                ... - .sumDev * .sumDev / .gN
                if .gSS < 0
                    .gSS = 0
                endif
                .groupVar[.g] = .gSS / (.gN - 1)

                .totalN = .totalN + .gN
                .sumOfMeans = .sumOfMeans + .groupMean[.g]

                if .groupVar[.g] <= 0
                    .nFlat = .nFlat + 1
                    if .nFlat <= 5
                        if .flatList$ <> ""
                            .flatList$ = .flatList$ + ", "
                        endif
                        .flatList$ = .flatList$ + """"
                        ... + .groupLabel$[.g] + """"
                    endif
                endif
            endif
        endfor

        ; Too-small groups first: a group of one has no variance to be
        ; zero, so reporting it as flat would name the wrong defect.
        if .nSingleton > 0
            if .nGroups = .nRows
                .error$ = "Group column """ + .factorCol$ + """ has "
                ... + string$ (.nGroups) + " groups for "
                ... + string$ (.nRows) + " rows - one per row. This is an "
                ... + "identifier column, not a grouping column."
            else
                .error$ = string$ (.nSingleton) + " of "
                ... + string$ (.nGroups) + " groups in """
                ... + .factorCol$ + """ have fewer than 2 observations: "
                ... + .singletonList$
                if .nSingleton > 5
                    .error$ = .error$ + ", and "
                    ... + string$ (.nSingleton - 5) + " more"
                endif
                .error$ = .error$ + ". Every group needs at least 2."
            endif
        elsif .nFlat > 0
            .error$ = string$ (.nFlat) + " of "
            ... + string$ (.nGroups) + " groups in """
            ... + .factorCol$ + """ have zero variance: " + .flatList$
            if .nFlat > 5
                .error$ = .error$ + ", and "
                ... + string$ (.nFlat - 5) + " more"
            endif
            .error$ = .error$ + ". Welch's F weights each group by "
            ... + "n/variance, which is undefined when every observation "
            ... + "in a group is identical."
        endif
    endif

    # --- Weights, weighted grand mean, A, L, B, F ---

    if .error$ = ""
        ; The shift is only a change of origin; every difference below is
        ; formed in shifted coordinates, so the leading digits are gone
        ; before any cancellation can happen. Welch's F is invariant.
        .shift = .sumOfMeans / .nGroups

        .sumWeights = 0
        .weightedShiftedSum = 0
        for .g from 1 to .nGroups
            .groupWeight[.g] = .groupN[.g] / .groupVar[.g]
            .shiftedMean[.g] = .groupMean[.g] - .shift
            .sumWeights = .sumWeights + .groupWeight[.g]
            .weightedShiftedSum = .weightedShiftedSum
            ... + .groupWeight[.g] * .shiftedMean[.g]
        endfor

        .shiftedWeightedMean = .weightedShiftedSum / .sumWeights
        .weightedMean = .shift + .shiftedWeightedMean

        .aTerm = 0
        .lambda = 0
        for .g from 1 to .nGroups
            .dev = .shiftedMean[.g] - .shiftedWeightedMean
            .aTerm = .aTerm + .groupWeight[.g] * .dev * .dev
            .share = 1 - .groupWeight[.g] / .sumWeights
            .lambda = .lambda
            ... + .share * .share / (.groupN[.g] - 1)
        endfor

        .df1 = .nGroups - 1
        .aTerm = .aTerm / .df1
        .bTerm = 2 * (.nGroups - 2) / (.nGroups * .nGroups - 1) * .lambda

        if .lambda > 0
            .f = .aTerm / (1 + .bTerm)
            .df2 = (.nGroups * .nGroups - 1) / (3 * .lambda)
            .p = fisherQ (.f, .df1, .df2)
        else
            ; L is a sum of squares over positive denominators and cannot
            ; be zero for k >= 2 with positive variances, but a caller
            ; deserves an undefined rather than a division by zero if the
            ; arithmetic ever underflows to it.
            .f = undefined
            .df2 = undefined
            .p = undefined
            .warning$ = "The Welch weight-dispersion term is zero; the "
            ... + "denominator degrees of freedom and p are undefined"
        endif
    endif

    # --- Restore selection ---

    selectObject: .tableId
endproc


# ============================================================================
# @emlGamesHowell
# ============================================================================
# Games-Howell post-hoc test: all pairwise comparisons with Welch
# standard errors and Welch-Satterthwaite degrees of freedom, referred
# to the studentized range distribution on k means.
#
#     q_ij  = |xbar_i - xbar_j| / sqrt((s_i^2/n_i + s_j^2/n_j) / 2)
#     df_ij = (v_i + v_j)^2 / (v_i^2/(n_i-1) + v_j^2/(n_j-1)),
#             v_j = s_j^2/n_j
#     p_ij  = studentized-range upper tail of q_ij on (k, df_ij)
#
# This is Tukey-Kramer's structure with the pooled MSE replaced, per
# pair, by the two groups' own variances. Use it when the variances are
# not equal; use @emlTukeyHSD when they are.
#
# Arguments:
#   .tableId    - ID of a Table object (must be in object list)
#   .dataCol$   - name of the numeric data column
#   .factorCol$ - name of the string factor column
#   .alpha      - significance level for the critical q (e.g. 0.05)
#
# Output (same shape as @emlTukeyHSD, so a reporter can consume either):
#   .pMatrix##       - k x k symmetric matrix of pairwise p-values
#                      (diagonal = 1, off-diagonal = Games-Howell p)
#   .qMatrix##       - k x k symmetric matrix of q statistics
#                      (diagonal = 0)
#   .meanDiff##      - k x k antisymmetric mean differences
#                      (meanDiff[i,j] = mean_i - mean_j)
#   .dMatrix##       - k x k antisymmetric Cohen's d matrix
#                      (dMatrix[i,j] = d for group i vs group j; signed)
#   .groupName$[i]   - group label for row/column i (1..nGroups)
#   .nGroups         - number of groups (k)
#   .nPairs          - number of unique pairwise comparisons (k*(k-1)/2)
#   .sortMap[s]      - maps sorted index s to extraction index (identity)
#   .nUndefined      - number of comparisons whose q (and therefore p)
#                      is undefined because the pairwise SE was zero;
#                      such cells hold undefined, not 1
#   .warning$        - non-fatal disclosure, or "" if none
#   .error$          - "" on success, diagnostic message on failure
#
# Output (per-pair, where Tukey has one pooled scalar):
#   .dfMatrix##      - k x k Welch-Satterthwaite df for each pair
#   .seMatrix##      - k x k pairwise SE, sqrt((v_i + v_j)/2); this is
#                      the same quantity @emlTukeyHSD divides by, so a
#                      confidence half-width is qCrit * se in both
#   .qCritMatrix##   - k x k critical q at .alpha on (k, df_ij)
#   .groupN[g], .groupMean[g], .groupVar[g]
#
# Deliberately undefined, and NOT interchangeable with @emlTukeyHSD:
#   .msWithin, .dfWithin, .qCritical
#     Games-Howell pools nothing, so there is no single MSE, no single
#     within-groups df, and no single critical q. The names exist, and
#     hold undefined, so that a reporter written against @emlTukeyHSD's
#     shape does not abort on a missing variable -- but a reporter that
#     prints a Games-Howell interval must use .qCritMatrix## and
#     .seMatrix##, not these.
#
# Access pattern:
#   p-value for group 2 vs group 4: emlGamesHowell.pMatrix##[2, 4]
#   df for that pair:               emlGamesHowell.dfMatrix##[2, 4]
#
# Notes:
#   - Groups are sorted alphabetically (matches R convention), by the
#     same @emlCountGroups mechanism @emlTukeyHSD uses
#   - Refuses when any group has fewer than 2 observations, naming the
#     offenders: Games-Howell needs a variance inside every group
#   - A pair in which BOTH groups have zero variance has an undefined q
#     and an undefined df; it is counted in .nUndefined and disclosed in
#     .warning$, never reported as p = 1. One flat group against one
#     varying group is a defined comparison and is computed normally.
#   - Cohen's d per pair uses the two-group pooled SD (via @emlCohenD),
#     identical to @emlTukeyHSD, so the effect-size column means the
#     same thing whichever post-hoc produced it
#   - Uses Get TukeyQ: for p-values and Get invTukeyQ: for critical q,
#     both of which accept a fractional df
#   - Dependencies: @emlCountGroups, @eml_getGroupData (eml-extract.praat),
#     @emlCohenD (eml-inferential.praat)
#   - Original Table selection is restored on return
# ============================================================================

procedure emlGamesHowell: .tableId, .dataCol$, .factorCol$, .alpha
    .nGroups = 0
    .nPairs = 0
    .msWithin = undefined
    .dfWithin = undefined
    .qCritical = undefined
    .nUndefined = 0
    .warning$ = ""
    .error$ = ""

    # --- Validate inputs (same conditions as @emlTukeyHSD) ---

    selectObject: .tableId
    .nRows = Get number of rows
    if .nRows < 3
        .error$ = "This test needs at least 3 observations; the table "
        ... + "has " + string$ (.nRows) + "."
    endif

    if .error$ = ""
        @emlRequireColumnPresent: .tableId, "Data column", .dataCol$
        .error$ = emlRequireColumnPresent.error$
    endif

    if .error$ = ""
        @emlRequireColumnPresent: .tableId, "Factor column", .factorCol$
        .error$ = emlRequireColumnPresent.error$
    endif

    # --- Discover groups ---

    if .error$ = ""
        @emlCountGroups: .tableId, .factorCol$
        if emlCountGroups.error$ <> ""
            .error$ = emlCountGroups.error$
        else
            .nGroups = emlCountGroups.nGroups
        endif
    endif

    if .error$ = ""
        if .nGroups < 2
            .error$ = "This test compares 2 or more groups; the group column "
            ... + """" + .factorCol$ + """ has " + string$ (.nGroups) + "."
        endif
    endif

    # --- Group order: identity map, as in @emlTukeyHSD ---

    if .error$ = ""
        for .s from 1 to .nGroups
            .groupName$[.s] = emlCountGroups.groupLabel$[.s]
            .sortMap[.s] = .s
        endfor
    endif

    # --- Group sizes, means and variances ---
    # Unlike @emlTukeyHSD there is no pooled dfWithin to fall back on:
    # every group needs a variance of its own, so a group of one is
    # Refused here and the offenders are named together.

    if .error$ = ""
        .totalN = 0
        .nSingleton = 0
        .singletonList$ = ""

        for .g from 1 to .nGroups
            @eml_getGroupData: .tableId, .dataCol$, .factorCol$,
            ... .groupName$[.g]
            .gN = eml_getGroupData.n
            .groupN[.g] = .gN

            if .gN < 2
                .groupMean[.g] = undefined
                .groupVar[.g] = undefined
                .nSingleton = .nSingleton + 1
                if .nSingleton <= 5
                    if .singletonList$ <> ""
                        .singletonList$ = .singletonList$ + ", "
                    endif
                    .singletonList$ = .singletonList$ + """"
                    ... + .groupName$[.g] + """"
                endif
            else
                .gData# = eml_getGroupData.data#
                .groupMean[.g] = mean (.gData#)
                .centered# = .gData# - .groupMean[.g]
                .sumDev = sum (.centered#)
                .gSS = sum (.centered# * .centered#)
                ... - .sumDev * .sumDev / .gN
                if .gSS < 0
                    .gSS = 0
                endif
                .groupVar[.g] = .gSS / (.gN - 1)
                .totalN = .totalN + .gN
            endif
        endfor

        if .nSingleton > 0
            if .nGroups = .nRows
                .error$ = "Group column """ + .factorCol$ + """ has "
                ... + string$ (.nGroups) + " groups for "
                ... + string$ (.nRows) + " rows - one per row. This is an "
                ... + "identifier column, not a grouping column."
            else
                .error$ = string$ (.nSingleton) + " of "
                ... + string$ (.nGroups) + " groups in """
                ... + .factorCol$ + """ have fewer than 2 observations: "
                ... + .singletonList$
                if .nSingleton > 5
                    .error$ = .error$ + ", and "
                    ... + string$ (.nSingleton - 5) + " more"
                endif
                .error$ = .error$ + ". Every group needs at least 2."
            endif
        endif
    endif

    # --- Pairwise q, df, p and critical q ---

    if .error$ = ""
        selectObject: .tableId

        .pMatrix## = zero## (.nGroups, .nGroups)
        .qMatrix## = zero## (.nGroups, .nGroups)
        .meanDiff## = zero## (.nGroups, .nGroups)
        .dMatrix## = zero## (.nGroups, .nGroups)
        .dfMatrix## = zero## (.nGroups, .nGroups)
        .seMatrix## = zero## (.nGroups, .nGroups)
        .qCritMatrix## = zero## (.nGroups, .nGroups)

        for .i from 1 to .nGroups
            .pMatrix##[.i, .i] = 1
        endfor

        .nPairs = .nGroups * (.nGroups - 1) / 2

        for .i from 1 to .nGroups
            for .j from .i + 1 to .nGroups
                .diff = .groupMean[.i] - .groupMean[.j]
                .termI = .groupVar[.i] / .groupN[.i]
                .termJ = .groupVar[.j] / .groupN[.j]
                .se = sqrt ((.termI + .termJ) / 2)

                ; Fail closed, as @emlTukeyHSD does. Two flat groups give a
                ; zero SE; reporting p = 1 there would read as a computed
                ; non-significant result rather than as no result at all.
                .q = undefined
                .df = undefined
                .pVal = undefined
                .qCrit = undefined
                if .termI + .termJ > 0
                    .q = abs (.diff) / .se
                    .df = (.termI + .termJ) * (.termI + .termJ)
                    ... / (.termI * .termI / (.groupN[.i] - 1)
                    ... + .termJ * .termJ / (.groupN[.j] - 1))
                endif

                if .q <> undefined
                    if .q > 0
                        .pVal = Get TukeyQ: .q, .nGroups, .df, 1
                    else
                        .pVal = 1
                    endif
                    .qCrit = Get invTukeyQ: .alpha, .nGroups, .df, 1
                else
                    .nUndefined = .nUndefined + 1
                endif

                .qMatrix##[.i, .j] = .q
                .qMatrix##[.j, .i] = .q
                .pMatrix##[.i, .j] = .pVal
                .pMatrix##[.j, .i] = .pVal
                .meanDiff##[.i, .j] = .diff
                .meanDiff##[.j, .i] = -.diff
                .dfMatrix##[.i, .j] = .df
                .dfMatrix##[.j, .i] = .df
                .seMatrix##[.i, .j] = .se
                .seMatrix##[.j, .i] = .se
                .qCritMatrix##[.i, .j] = .qCrit
                .qCritMatrix##[.j, .i] = .qCrit
            endfor
        endfor

        if .nUndefined > 0
            .warning$ = string$ (.nUndefined)
            ... + " of " + string$ (.nPairs) + " comparisons have an "
            ... + "undefined q (both groups have zero variance, so the "
            ... + "pairwise standard error is zero); their p-values are "
            ... + "undefined, not 1"
        endif
    endif

    # --- Cohen's d per pair (two-group pooled SD, as in @emlTukeyHSD) ---
    # Separated from the loop above so that the studentized-range calls
    # are not interleaved with the object create/remove @eml_getGroupData
    # performs.

    if .error$ = ""
        for .i from 1 to .nGroups
            for .j from .i + 1 to .nGroups
                @eml_getGroupData: .tableId, .dataCol$, .factorCol$,
                ... .groupName$[.i]
                .vI# = eml_getGroupData.data#
                @eml_getGroupData: .tableId, .dataCol$, .factorCol$,
                ... .groupName$[.j]
                @emlCohenD: .vI#, eml_getGroupData.data#
                if emlCohenD.error$ = ""
                    .dMatrix##[.i, .j] = emlCohenD.d
                    .dMatrix##[.j, .i] = -emlCohenD.d
                else
                    .dMatrix##[.i, .j] = undefined
                    .dMatrix##[.j, .i] = undefined
                endif
            endfor
        endfor
    endif

    # --- Restore selection ---

    selectObject: .tableId
endproc


# ============================================================================
# @emlLinearRegression — Simple OLS linear regression
# ============================================================================
# Inputs:
#   .x#, .y#   — predictor and response vectors (same length, n >= 3)
#
# Outputs:
#   .slope, .intercept          — regression coefficients
#   .r, .rSquared               — Pearson r and coefficient of determination
#   .fStat, .dfReg, .dfRes, .pF — F-test for overall model significance
#   .seResidual                 — residual standard error
#   .seSlope, .seIntercept      — coefficient standard errors
#   .tSlope, .tIntercept        — t-statistics for coefficients
#   .pSlope, .pIntercept        — two-tailed p-values for coefficients
#   .n                          — sample size used
#   .error$                     — empty string if successful
#
# Method: Ordinary least squares via normal equations.
#   b = Σ(xi−x̄)(yi−ȳ) / Σ(xi−x̄)²
#   a = ȳ − b·x̄
#   F = MSreg / MSres with df1=1, df2=n−2
#   SE(b) = SE_resid / √(SSxx)
#   t = coefficient / SE(coefficient), p via studentQ
#
# Provenance: Implemented 10 May 2026. Verified against scipy.stats.linregress
#   on 4 test vectors (strong negative, weak positive, near-zero, perfect fit).
# ============================================================================

procedure emlLinearRegression: .x#, .y#
    .error$ = ""
    .n = size (.x#)

    if .n <> size (.y#)
        .error$ = "Vectors must be same length."
    elsif .n < 3
        .error$ = "Need at least 3 observations for regression."
    endif

    if .error$ = ""
        .xMean = mean (.x#)
        .yMean = mean (.y#)

        .ssXX = 0
        .ssYY = 0
        .ssXY = 0
        .sumX2 = 0
        for .i from 1 to .n
            .dx = .x# [.i] - .xMean
            .dy = .y# [.i] - .yMean
            .ssXX = .ssXX + .dx * .dx
            .ssYY = .ssYY + .dy * .dy
            .ssXY = .ssXY + .dx * .dy
            .sumX2 = .sumX2 + .x# [.i] * .x# [.i]
        endfor

        if .ssXX = 0
            .error$ = "Predictor has zero variance."
        elsif .ssYY = 0
            .error$ = "Response has zero variance."
        endif
    endif

    if .error$ = ""
        # Coefficients
        .slope = .ssXY / .ssXX
        .intercept = .yMean - .slope * .xMean

        # Correlation and R²
        .r = .ssXY / sqrt (.ssXX * .ssYY)
        .rSquared = .r * .r

        # Sums of squares decomposition
        .ssReg = .slope * .ssXY
        .ssRes = .ssYY - .ssReg

        # Degrees of freedom
        .dfReg = 1
        .dfRes = .n - 2

        # Mean squares and F-test
        .msReg = .ssReg / .dfReg
        .msRes = .ssRes / .dfRes
        .fStat = .msReg / .msRes
        .pF = fisherQ (.fStat, .dfReg, .dfRes)

        # Residual standard error
        .seResidual = sqrt (.msRes)

        # Coefficient standard errors
        .seSlope = .seResidual / sqrt (.ssXX)
        .seIntercept = .seResidual * sqrt (.sumX2 / (.n * .ssXX))

        # t-statistics and p-values (two-tailed)
        .tSlope = .slope / .seSlope
        .tIntercept = .intercept / .seIntercept
        .pSlope = 2 * studentQ (abs (.tSlope), .dfRes)
        .pIntercept = 2 * studentQ (abs (.tIntercept), .dfRes)
    endif
endproc


# ============================================================================
# @emlTheilSen — Theil-Sen robust regression estimator
# ============================================================================
# Computes the Theil-Sen slope (median of all pairwise slopes) and
# intercept. Appropriate for Spearman contexts where OLS is not
# methodologically coherent.
#
# INTERCEPT CONVENTION — separate (Conover 1980):
#
#     b = median(y) - slope * median(x)
#
# NOT the joint convention b = median(y_i - slope * x_i). The two agree on
# symmetric data and diverge otherwise, so the distinction is invisible in
# casual testing and must be stated. A docstring naming the joint form over
# code implementing the separate one is an inert mismatch — no caller reads a
# docstring — and exactly the kind of drift that makes a later "correction"
# break working code.
#
# scipy.stats.theilslopes offers both via method=; its default, "separate",
# is what this procedure matches.
#
# Arguments:
#   .x#     — predictor values (vector)
#   .y#     — response values (vector, same length as .x#)
#
# Outputs:
#   .slope      — Theil-Sen slope (median of pairwise slopes)
#   .intercept  — Theil-Sen intercept, separate convention (see above)
#   .error$     — "" if successful, error message otherwise
#   .nSlopes    — number of valid pairwise slopes computed
#
# Complexity: O(n^2) for slope computation, O(n^2 log n^2) for sort.
# Feasible for typical voice science sample sizes (n < 1000).
#
# VERIFICATION
#   Suite:      dev/tests/phase2/test-theilsen.praat (47 checks)
#   References: dev/tests/phase2/theilsen_scipy_refs.py, which emits every
#               asserted literal from scipy.stats.theilslopes at %.17g.
#   Measured:   all 24 numeric sites agree with scipy to exactly 0.0 --
#               bit-identical doubles, not merely within tolerance.
#   Controls:   six paired negative controls. Perturbing an expected literal
#               by +1e-10 fails and by +1e-11 passes, bracketing tsTol=5e-11;
#               switching this procedure to the joint intercept fails exactly
#               6 checks (TS-1/2/5/8 intercepts + 2 convention checks) while
#               TS-3/4/6/7 pass, since those sets cannot discriminate the two
#               conventions; deleting a call site is caught by the coverage
#               assertion, and passes green at a lower count without it.
# ============================================================================
procedure emlTheilSen: .x#, .y#
    .slope = undefined
    .intercept = undefined
    .error$ = ""
    .nSlopes = 0

    .n = size (.x#)
    if .n <> size (.y#)
        .error$ = "The x and y vectors must have equal length; x has "
        ... + string$ (.n) + " values and y has "
        ... + string$ (size (.y#)) + "."
    elsif .n < 2
        .error$ = "This estimator needs at least 2 observations; got "
        ... + string$ (.n) + "."
    endif

    if .error$ = ""
        # Count valid pairs (where x_i != x_j)
        .maxPairs = .n * (.n - 1) / 2
        .slopes# = zero# (.maxPairs)
        .count = 0

        for .i from 1 to .n - 1
            for .j from .i + 1 to .n
                if .x# [.i] <> .x# [.j]
                    .count = .count + 1
                    .slopes# [.count] = (.y# [.j] - .y# [.i])
                    ... / (.x# [.j] - .x# [.i])
                endif
            endfor
        endfor

        .nSlopes = .count

        if .nSlopes = 0
            .error$ = "All " + string$ (.n) + " x values are identical, "
            ... + "so no slope can be estimated. The predictor must vary."
        else
            # Extract valid slopes and sort for median
            .validSlopes# = zero# (.nSlopes)
            for .k from 1 to .nSlopes
                .validSlopes# [.k] = .slopes# [.k]
            endfor
            .sortedSlopes# = sort# (.validSlopes#)

            # Median of slopes
            .mid = ceiling (.nSlopes / 2)
            if .nSlopes mod 2 = 1
                .slope = .sortedSlopes# [.mid]
            else
                .slope = (.sortedSlopes# [.mid]
                ... + .sortedSlopes# [.mid + 1]) / 2
            endif

            # Intercept = median(y) - slope * median(x) (Conover 1980)
            .sortedY# = sort# (.y#)
            .midY = ceiling (.n / 2)
            if .n mod 2 = 1
                .medY = .sortedY# [.midY]
            else
                .medY = (.sortedY# [.midY]
                ... + .sortedY# [.midY + 1]) / 2
            endif
            .sortedX# = sort# (.x#)
            .midX = ceiling (.n / 2)
            if .n mod 2 = 1
                .medX = .sortedX# [.midX]
            else
                .medX = (.sortedX# [.midX]
                ... + .sortedX# [.midX + 1]) / 2
            endif
            .intercept = .medY - .slope * .medX
        endif
    endif
endproc


# ============================================================================
# @emlOLSInfluence: .tableId, .xCol$, .yCol$
# ============================================================================
# Leverage, Cook's distance and LEVERAGE-CORRECTED standardised residuals for
# a SIMPLE ordinary-least-squares regression (one predictor, one response,
# intercept fitted — so p = 2). This is the p = 2 sibling of
# @emlLMMInfluence, written separately rather than by driving that procedure
# with a fabricated fit. Three reasons, in order of weight:
#
#   1. @emlLMMInfluence reads its whole input from the emlLMM.* namespace —
#      x##, y#, beta#, sigma, vcovBeta##, seBeta#, thetaOpt#, z##, nObs,
#      nFixedCols, nRandomCols. Calling it for an OLS fit means WRITING all
#      eleven of those, which silently destroys any real LMM fit held in the
#      same session. A diagnostic that corrupts the model it was called
#      alongside is not reusable, it is a trap.
#   2. For p = 2 the leverage has the closed form below. @emlLMMInfluence
#      gets the same number by forming a (p+q)x(p+q) matrix, inverting it
#      with solve##, and taking n row inner products. Reusing it here would
#      not be sharing work, it would be paying for machinery that cancels.
#   3. Every FIT quantity this needs — slope, intercept, xMean, ssXX,
#      seResidual, n — is already computed and already exposed by
#      @emlLinearRegression. So this procedure repeats no statistic: it
#      delegates the fit and adds only the three quantities that fit does
#      not carry. The one thing it does repeat is the table-to-vector
#      listwise-deletion pass, and that is unavoidable, because the outputs
#      must be addressed by TABLE ROW (see "Row alignment" below).
#
# THIS PROCEDURE RE-FITS. It calls @emlLinearRegression on the same table and
# columns, with the same listwise rule @emlRunRegressionAnalysis uses, so
# emlLinearRegression.* is left holding bit-identical values to whatever it
# held before. Calling it on a DIFFERENT table than the one last fitted will
# leave emlLinearRegression.* describing THIS fit; that is intended, but a
# caller that reads emlLinearRegression.* afterwards must know it.
#
# Arguments:
#   .tableId    — Table object id
#   .xCol$      — predictor column name
#   .yCol$      — response column name
#
# Outputs — ROW ALIGNED. Every vector has one entry per TABLE ROW, not one
# per fitted observation, and rows dropped by listwise deletion carry
# `undefined`. That is what makes the augment loop a straight read: no
# second counter, no index map, nothing to keep in step.
#   .used#      — 1 if the row entered the fit, 0 if it was dropped
#   .fitted#    — a + b*x
#   .resid#     — y - fitted
#   .hat#       — h_i = 1/n + (x_i - xbar)^2 / SSxx
#   .stdResid#  — e_i / (s * sqrt(1 - h_i))          <- broom's .std.resid
#   .cooksd#    — e_i^2 * h_i / (p * s^2 * (1 - h_i)^2)
# Scalars:
#   .n          — observations that entered the fit
#   .nRows      — rows in the table
#   .p          — 2 (intercept + slope), the rank of the model
#   .sigma      — residual standard error, sqrt(sum(e^2) / (n - 2)). Formed
#                 from the residuals, NOT read off emlLinearRegression —
#                 see the note at the computation for the measured reason.
#   .slope, .intercept, .xMean, .ssXX
#   .nSingular  — how many rows sat at leverage 1
#   .error$     — "" on success; a refusal otherwise
#
# WHY .stdResid# IS NOT resid/s. The augment sites emitted `.std.resid` as
# resid / seResidual, with no leverage term. broom, and R's rstandard(),
# divide by s * sqrt(1 - h_i): a point far out in x has its residual shrunk
# by the fit, and dividing by s alone understates it — exactly for the
# points where a diagnostic is supposed to raise its voice. The two agree
# only as h_i -> 0. This is why 4(d) lands as one change: emitting the
# corrected residual and emitting .hat/.cooksd cannot be separated without
# leaving the file carrying two columns under two different conventions.
#
# REFUSALS, and why each is a refusal rather than a value.
#   n < 3, n <> other column's length, zero-variance predictor, zero-variance
#     response — inherited verbatim from @emlLinearRegression, so the wording
#     a user sees is the wording the regression itself would have used. n < 3
#     is n <= p: no residual degrees of freedom, so s does not exist.
#   s = 0 (a perfectly collinear x,y — every point on the line) — refused
#     here. Every quantity below divides by s, so there is nothing to report
#     rather than something to report carefully.
#
#     R does NOT refuse this, and the difference is worth knowing. On
#     y = 2x + 1, x = 1..9, R fits by QR, leaves residuals of order 1e-15,
#     and reports rstandard() values of -1.43, 2.52, 0.88 — quantities
#     computed entirely from rounding error, behind a warning most callers
#     never see. The normal-equations RSS here comes out exactly 0, so this
#     refuses instead. Measured, not assumed; v24 asserts both halves.
#
#     The guard is s > 0 EXACTLY, with no tolerance, so a fit that misses by
#     1e-9 is not refused and does produce large standardised residuals.
#     That is deliberate parity with R rather than an oversight — v24's
#     `nearperfect` case pins it, so widening this to a tolerance will break
#     something visible rather than silently changing what gets reported.
#
# LEVERAGE 1 IS NOT A REFUSAL. It is a property of ONE ROW, and the other
# rows are still worth reporting, so it is handled per row: h_i is clamped to
# exactly 1 and .stdResid#/.cooksd# for that row are `undefined`. The clamp
# threshold is 1 - 10*eps, which is R's: lm.influence passes
# tol = 10 * .Machine$double.eps to its C helper, which rounds any hat above
# 1 - tol up to 1, after which rstandard and cooks.distance map the resulting
# non-finite value to NaN.
#
# The clamp is the whole point and it is not cosmetic. A genuine leverage-1
# point does not land on 1.0 in floating point; it lands a few ulp either
# side. Measured on the p = 2 reduction of @emlLMMInfluence, 24 rows, one
# point carrying all the x variation: at x24 = 1.4 the hat came out
# 0.9999999999999999, passed that procedure's bare `if h < 1` test, and
# produced a Cook's D of 46.56 — a ratio of two rounding errors, printed to
# a user as the most influential point they have ever seen. R returns NaN.
# One ulp the other way (x24 = 0.7, hat 1.0000000000000002) and the same
# procedure returns undefined. A guard whose answer depends on the last bit
# of the input is not a guard.
#
# Provenance: checked against base R's
# hatvalues(), rstandard() and cooks.distance() by validate/v24_influence.R,
# driven by harness/influence/ols_influence_drive.praat. Not verified against
# anything else, and in particular not against its own author's arithmetic.
# ============================================================================
procedure emlOLSInfluence: .tableId, .xCol$, .yCol$
    .error$ = ""
    .n = 0
    .nRows = 0
    .p = 2
    .sigma = undefined
    .slope = undefined
    .intercept = undefined
    .xMean = undefined
    .ssXX = undefined
    .nSingular = 0
    .nValid = 0

    # 1 - 10*eps, R's lm.influence tolerance. Written as a literal because
    # Praat has no double-epsilon constant; string$() round-trips it.
    .hatOne = 0.999999999999997779553950749686919152736663818359375

    selectObject: .tableId
    .tableName$ = selected$ ("Table")
    .nRows = Get number of rows
    .xIdx = Get column index: .xCol$
    .yIdx = Get column index: .yCol$

    # Allocate FIRST, and to undefined. A caller that reads .hat# after a
    # refusal gets a vector of undefined rather than a vector of zeros, and
    # zero is a legal leverage.
    .alloc = max (.nRows, 1)
    .used# = zero# (.alloc)
    .fitted# = zero# (.alloc)
    .resid# = zero# (.alloc)
    .hat# = zero# (.alloc)
    .stdResid# = zero# (.alloc)
    .cooksd# = zero# (.alloc)
    for .i from 1 to .alloc
        .fitted# [.i] = undefined
        .resid# [.i] = undefined
        .hat# [.i] = undefined
        .stdResid# [.i] = undefined
        .cooksd# [.i] = undefined
    endfor

    if .xIdx = 0
        .error$ = "Column """ + .xCol$ + """ not found in table """
        ... + .tableName$ + """."
    elsif .yIdx = 0
        .error$ = "Column """ + .yCol$ + """ not found in table """
        ... + .tableName$ + """."
    endif

    # --- listwise deletion, the same rule @emlRunRegressionAnalysis uses ---
    if .error$ = ""
        for .r from 1 to .nRows
            selectObject: .tableId
            .xv = Get value: .r, .xCol$
            .yv = Get value: .r, .yCol$
            # Praat evaluates BOTH sides of `and`, so this is nested, not
            # conjoined. Same everywhere below.
            if .xv <> undefined
                if .yv <> undefined
                    .nValid = .nValid + 1
                endif
            endif
        endfor
        if .nValid < 3
            .error$ = "Need at least 3 non-missing paired observations "
            ... + "(found " + string$ (.nValid) + ")."
        endif
    endif

    if .error$ = ""
        .xClean# = zero# (.nValid)
        .yClean# = zero# (.nValid)
        .k = 0
        for .r from 1 to .nRows
            selectObject: .tableId
            .xv = Get value: .r, .xCol$
            .yv = Get value: .r, .yCol$
            if .xv <> undefined
                if .yv <> undefined
                    .k = .k + 1
                    .xClean# [.k] = .xv
                    .yClean# [.k] = .yv
                endif
            endif
        endfor

        # The fit itself is not recomputed here. @emlLinearRegression already
        # exposes every term the formulae below need.
        @emlLinearRegression: .xClean#, .yClean#
        if emlLinearRegression.error$ <> ""
            .error$ = emlLinearRegression.error$
        endif
    endif

    # --- pass 1: fitted, residual, leverage, and RSS ------------------------
    if .error$ = ""
        .n = emlLinearRegression.n
        .slope = emlLinearRegression.slope
        .intercept = emlLinearRegression.intercept
        .xMean = emlLinearRegression.xMean
        .ssXX = emlLinearRegression.ssXX
        .rss = 0

        for .r from 1 to .nRows
            selectObject: .tableId
            .xv = Get value: .r, .xCol$
            .yv = Get value: .r, .yCol$
            .ok = 0
            if .xv <> undefined
                if .yv <> undefined
                    .ok = 1
                endif
            endif
            if .ok = 1
                .used# [.r] = 1
                .dx = .xv - .xMean
                .h = 1 / .n + .dx * .dx / .ssXX
                if .h > .hatOne
                    .h = 1
                endif
                .hat# [.r] = .h
                .fit = .intercept + .slope * .xv
                .fitted# [.r] = .fit
                .e = .yv - .fit
                .resid# [.r] = .e
                .rss = .rss + .e * .e
            endif
        endfor

        # sigma FROM THE RESIDUALS, not from emlLinearRegression.seResidual.
        #
        # This is the one number here that is deliberately NOT taken from the
        # fit, and the reason is numerical. @emlLinearRegression forms
        # RSS = SSyy - b*SSxy, a difference of two quantities that are equal
        # to the extent the fit is good. On y = 2x + 1 with one point moved
        # by 1e-9 (v24's `nearperfect`) both terms are 240 and their true
        # difference is 8.9e-19, so the subtraction returns 8.5e-14 —
        # RSS too large by a factor of 96,000, sigma too large by 253.
        # Residuals, leverage, slope and intercept are all correct there to
        # the last bit; sigma alone is wrong, and every standardised residual
        # and Cook's D inherits it. Measured, 7 Aug 2026.
        #
        # sum(e^2) has no cancellation: every term is non-negative. The
        # residuals are in hand from the loop above, so this costs nothing.
        # It is not a second copy of the fit's arithmetic, it is a
        # better-conditioned form of one line of it.
        #
        # On ordinary data the two agree to within rounding, and v24 asserts
        # that on every green case — so if this ever drifts into disagreeing
        # with the `sigma` the glance frame reports, a test says so.
        .sigma = sqrt (.rss / (.n - .p))

        # not (s > 0) rather than s = 0, so a sigma that arrived as
        # `undefined` is caught by the same test.
        if not (.sigma > 0)
            .error$ = "Residual standard error is zero (the points lie "
            ... + "exactly on the line); influence diagnostics are undefined."
        endif
    endif

    # --- pass 2: the standardised quantities --------------------------------
    if .error$ = ""
        .sigSq = .sigma * .sigma
        for .r from 1 to .nRows
            if .used# [.r] = 1
                .h = .hat# [.r]
                .e = .resid# [.r]
                .oneMinusH = 1 - .h
                if .oneMinusH > 0
                    .stdResid# [.r] = .e / (.sigma * sqrt (.oneMinusH))
                    .cooksd# [.r] = (.e * .e * .h) /
                    ... (.p * .sigSq * .oneMinusH * .oneMinusH)
                else
                    # Leverage 1: the line passes through this point by
                    # construction, so its residual is zero by construction
                    # and both quantities are 0/0. Not inf, not a huge
                    # finite number — undefined, which is R's NaN.
                    .nSingular = .nSingular + 1
                    .stdResid# [.r] = undefined
                    .cooksd# [.r] = undefined
                endif
            endif
        endfor
    endif

    selectObject: .tableId
endproc


# ============================================================================
# END OF MODULE
# ============================================================================
