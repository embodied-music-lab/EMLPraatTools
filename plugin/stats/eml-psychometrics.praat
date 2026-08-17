# ============================================================================
# EML Stats : Psychometrics
# ============================================================================
# Module: eml-psychometrics.praat
# Version: 1.0
# Date: 17 August 2026
#
# Part of the EML Stats library (EML Praat Tools).
# License: GPL-3.0-or-later
#
# Provides: @emlCronbachAlpha, @emlAlphaInfluence
#
# Internal helpers: @eml_listwiseComplete
#
# Dependencies: None (uses only Praat built-in vector and matrix
# primitives and the built-in F distribution).
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

# ----------------------------------------------------------------------------
# @eml_listwiseComplete
# Internal helper: remove every row of a matrix that contains at least
# one undefined cell (listwise deletion).
# Input:  .data## — numeric matrix, rows = respondents, columns = items
# Output: .clean##    — the matrix restricted to complete rows
#         .nKept      — number of complete rows
#         .nExcluded  — number of rows removed
# ----------------------------------------------------------------------------

procedure eml_listwiseComplete: .data##
    .nRows = numberOfRows (.data##)
    .nCols = numberOfColumns (.data##)

    # A row sum is undefined exactly when the row holds an undefined
    # cell, because arithmetic with undefined propagates.
    .rowTotal# = rowSums# (.data##)

    .nKept = 0
    for .i from 1 to .nRows
        if .rowTotal# [.i] <> undefined
            .nKept = .nKept + 1
        endif
    endfor
    .nExcluded = .nRows - .nKept

    .clean## = zero## (.nKept, .nCols)
    .row = 0
    for .i from 1 to .nRows
        if .rowTotal# [.i] <> undefined
            .row = .row + 1
            for .j from 1 to .nCols
                .clean## [.row, .j] = .data## [.i, .j]
            endfor
        endif
    endfor
endproc

# ============================================================================
# @emlCronbachAlpha
# ============================================================================
# Cronbach's alpha: internal consistency of a k-item scale.
#
# The input is one matrix, rows = respondents, columns = items, so a
# 20-respondent 5-item scale arrives as a 20 x 5 matrix. Rows holding
# an undefined cell are removed before computation (listwise deletion)
# and the removal is disclosed in .nExcluded.
#
# The 95% confidence interval uses the Feldt (1965) F-distribution
# method with df1 = n - 1 and df2 = (n - 1)(k - 1), matching R's
# psych::alpha.
#
# Arguments:
#   .data##  - numeric matrix; rows = respondents, columns = items
#
# Output:
#   .alpha            - Cronbach's alpha (covariance-based, sample
#                       variances with n - 1 denominator)
#   .ci95low          - lower bound of the Feldt 95% CI
#   .ci95high         - upper bound of the Feldt 95% CI
#   .k                - number of items (columns)
#   .n                - number of respondents used (complete rows)
#   .nExcluded        - rows removed by listwise deletion
#   .alphaIfDeleted#  - vector, length k: alpha of the scale with that
#                       item removed (undefined for every item when
#                       k = 2, because a one-item scale has no alpha)
#   .error$           - error message, or "" if valid
#
# Access pattern:
#   @emlCronbachAlpha: responses##
#   a = emlCronbachAlpha.alpha
#   dropTwo = emlCronbachAlpha.alphaIfDeleted# [2]
#
# Notes:
#   - Items are assumed already scored in a consistent direction;
#     reverse-scoring is the caller's responsibility. An item scored
#     in the wrong direction lowers alpha — it is not detected here.
#   - Requires k >= 2 items and, after listwise deletion, n >= 3
#     respondents (the Feldt CI needs n - 1 >= 2).
#   - Raw values are returned; callers format for display.
# ============================================================================

procedure emlCronbachAlpha: .data##
    # Initialize outputs
    .alpha = undefined
    .ci95low = undefined
    .ci95high = undefined
    .k = undefined
    .n = undefined
    .nExcluded = undefined
    .error$ = ""

    .nRowsIn = numberOfRows (.data##)
    .k = numberOfColumns (.data##)
    .alphaIfDeleted# = zero# (max (.k, 1)) + undefined

    # --- Listwise deletion, disclosed ---
    @eml_listwiseComplete: .data##
    .n = eml_listwiseComplete.nKept
    .nExcluded = eml_listwiseComplete.nExcluded
    .work## = eml_listwiseComplete.clean##

    # --- Input validation ---
    if .k < 2
        .error$ = "Alpha needs at least 2 items; the matrix has "
        ... + string$ (.k) + "."
    elsif .n < 3
        .error$ = "Alpha needs at least 3 complete respondents; "
        ... + string$ (.nRowsIn) + " arrived and " + string$ (.n)
        ... + " remained after listwise deletion."
    else
        # --- Item variances (vectorized: per-column sum and sum of
        #     squares, sample variance with n - 1 denominator) ---
        .colSum# = columnSums# (.work##)
        .colSumSq# = columnSums# (.work## * .work##)
        .itemVar# = (.colSumSq# - .colSum# * .colSum# / .n) / (.n - 1)

        # --- Total-score variance ---
        .total# = rowSums# (.work##)
        .sdTotal = stdev (.total#)
        .varTotal = .sdTotal * .sdTotal

        if .varTotal = 0
            .error$ = "The total score has zero variance; "
            ... + "alpha is undefined."
        else
            # --- Alpha ---
            .sumItemVar = sum (.itemVar#)
            .alpha = (.k / (.k - 1)) * (1 - .sumItemVar / .varTotal)

            # --- Feldt (1965) 95% CI ---
            .df1 = .n - 1
            .df2 = (.n - 1) * (.k - 1)
            .ci95low = 1 - (1 - .alpha) * invFisherQ (0.025, .df1, .df2)
            .ci95high = 1 - (1 - .alpha) * invFisherQ (0.975, .df1, .df2)

            # --- Alpha if item deleted ---
            # For k = 2 the reduced scale has one item and no alpha;
            # the vector stays undefined in that case.
            if .k >= 3
                for .j from 1 to .k
                    # Column j via matrix-vector product with the
                    # j-th unit vector.
                    .unit# = zero# (.k)
                    .unit# [.j] = 1
                    .colJ# = mul# (.work##, .unit#)
                    .reduced# = .total# - .colJ#
                    .sdReduced = stdev (.reduced#)
                    .varReduced = .sdReduced * .sdReduced
                    if .varReduced > 0
                        .sumVarReduced = .sumItemVar - .itemVar# [.j]
                        .alphaIfDeleted# [.j] = ((.k - 1) / (.k - 2))
                        ... * (1 - .sumVarReduced / .varReduced)
                    endif
                endfor
            endif
        endif
    endif
endproc

# ============================================================================
# @emlAlphaInfluence
# ============================================================================
# Respondent influence on Cronbach's alpha: leave-one-out jackknife over
# respondents. Where alpha-if-deleted asks whether one ITEM is spoiling
# the scale, this asks whether one RESPONDENT is: alpha is recomputed
# with each respondent removed, and each removal's effect on alpha is
# reported as a delta against the full complete-case alpha.
#
# The input is one matrix, rows = respondents, columns = items, the same
# shape @emlCronbachAlpha takes. Listwise deletion runs first, identical
# to the alpha kernel, and is disclosed in .nExcluded. All indexed
# outputs run over the SURVIVING rows, and .rowIndex# maps each entry
# back to its ORIGINAL row number in the input matrix, so a caller can
# still say "respondent 12" after rows above 12 were deleted.
#
# The kernel reports; it never judges. No thresholds, no outlier labels,
# no automatic exclusion — the numbers go out raw and the caller frames
# the evidence.
#
# Arguments:
#   .data##  - numeric matrix; rows = respondents, columns = items
#
# Output:
#   .alphaFull     - alpha on all complete cases (equals
#                    @emlCronbachAlpha.alpha on the same matrix)
#   .k             - number of items (columns)
#   .n             - number of respondents used (complete rows)
#   .nExcluded     - rows removed by listwise deletion
#   .alphaWithout# - vector, length n: alpha with surviving respondent
#                    j removed (undefined for an entry whose leave-one-
#                    out total score has zero variance)
#   .delta#        - vector, length n: .alphaWithout# [j] - .alphaFull
#   .rowIndex#     - vector, length n: ORIGINAL row number of surviving
#                    respondent j
#   .deltaMax      - largest absolute delta (undefined if every delta
#                    is undefined)
#   .deltaMaxRow   - ORIGINAL row number of that respondent
#   .error$        - error message, or "" if valid
#
# Access pattern:
#   @emlAlphaInfluence: responses##
#   biggest = emlAlphaInfluence.deltaMax
#   who = emlAlphaInfluence.deltaMaxRow          ; original row number
#   d12 = emlAlphaInfluence.delta# [3]           ; 3rd SURVIVING row...
#   row12 = emlAlphaInfluence.rowIndex# [3]      ; ...which is this row
#
# Notes:
#   - Requires k >= 2 items and, after listwise deletion, n >= 3
#     respondents (leave-one-out on fewer would put the covariance
#     on a single row).
#   - Each leave-one-out alpha is computed by downdating the full
#     per-item and total-score sums (one vector operation per
#     respondent), not by rebuilding a submatrix; the loop over
#     respondents is the jackknife itself.
#   - Raw values are returned; callers format for display.
# ============================================================================

procedure emlAlphaInfluence: .data##
    # Initialize outputs
    .alphaFull = undefined
    .k = undefined
    .n = undefined
    .nExcluded = undefined
    .deltaMax = undefined
    .deltaMaxRow = undefined
    .error$ = ""

    .nRowsIn = numberOfRows (.data##)
    .k = numberOfColumns (.data##)

    # --- Listwise deletion, identical to @emlCronbachAlpha ---
    @eml_listwiseComplete: .data##
    .n = eml_listwiseComplete.nKept
    .nExcluded = eml_listwiseComplete.nExcluded
    .work## = eml_listwiseComplete.clean##

    .len = max (.n, 1)
    .alphaWithout# = zero# (.len) + undefined
    .delta# = zero# (.len) + undefined
    .rowIndex# = zero# (.len) + undefined

    # --- Input validation ---
    if .k < 2
        .error$ = "Alpha needs at least 2 items; the matrix has "
        ... + string$ (.k) + "."
    elsif .n < 3
        .error$ = "Respondent influence needs at least 3 complete "
        ... + "respondents (leave-one-out on fewer would rest on a "
        ... + "single row); " + string$ (.nRowsIn) + " arrived and "
        ... + string$ (.n) + " remained after listwise deletion."
    else
        # --- Original-row mapping for the surviving rows ---
        .rowTotalIn# = rowSums# (.data##)
        .j = 0
        for .i from 1 to .nRowsIn
            if .rowTotalIn# [.i] <> undefined
                .j = .j + 1
                .rowIndex# [.j] = .i
            endif
        endfor

        # --- Full-sample sums (vectorized) ---
        .colSum# = columnSums# (.work##)
        .colSumSq# = columnSums# (.work## * .work##)
        .total# = rowSums# (.work##)
        .totSum = sum (.total#)
        .totSumSq = sum (.total# * .total#)

        # --- Full complete-case alpha ---
        .dfRows = .n - 1
        .itemVar# = (.colSumSq# - .colSum# * .colSum# / .n) / .dfRows
        .varTotal = (.totSumSq - .totSum * .totSum / .n) / .dfRows

        if .varTotal <= 0
            .error$ = "The total score has zero variance; "
            ... + "alpha is undefined."
        else
            .alphaFull = (.k / (.k - 1))
            ... * (1 - sum (.itemVar#) / .varTotal)

            # --- Jackknife: downdate the sums per respondent ---
            .m = .n - 1
            for .j from 1 to .n
                .rowVec# = row# (.work##, .j)
                .colSumJ# = .colSum# - .rowVec#
                .colSumSqJ# = .colSumSq# - .rowVec# * .rowVec#
                .totJ = .totSum - .total# [.j]
                .totSqJ = .totSumSq - .total# [.j] * .total# [.j]
                .itemVarJ# = (.colSumSqJ# - .colSumJ# * .colSumJ# / .m)
                ... / (.m - 1)
                .varTotalJ = (.totSqJ - .totJ * .totJ / .m) / (.m - 1)
                if .varTotalJ > 0
                    .alphaWithout# [.j] = (.k / (.k - 1))
                    ... * (1 - sum (.itemVarJ#) / .varTotalJ)
                    .delta# [.j] = .alphaWithout# [.j] - .alphaFull
                endif
            endfor

            # --- Largest absolute delta, reported by ORIGINAL row ---
            for .j from 1 to .n
                if .delta# [.j] <> undefined
                    .absDelta = abs (.delta# [.j])
                    if .deltaMax = undefined or .absDelta > .deltaMax
                        .deltaMax = .absDelta
                        .deltaMaxRow = .rowIndex# [.j]
                    endif
                endif
            endfor
        endif
    endif
endproc

# ============================================================================
# END OF MODULE
# ============================================================================
