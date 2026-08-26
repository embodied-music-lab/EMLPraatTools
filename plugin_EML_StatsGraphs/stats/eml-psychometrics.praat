# ============================================================================
# EML Stats : Psychometrics
# ============================================================================
# Module: eml-psychometrics.praat
# Version: 1.3
# Date: 26 August 2026
#
# V1.1: Adds @emlSurveyValidateDeclaration, the survey module's declaration
#       validator. It checks a data Table against a scales Table and an
#       items Table (the two-CSV declaration described in
#       evidence/csv/lane_survey_declared_SCHEMA.md) and refuses before any
#       reliability number is computed. Stage 1 of the survey module build:
#       schemas, validator, oracles. No reversal transform, no per-subscale
#       routing, no report -- those are wired to this validator later and do
#       not live in this module.
#
# V1.2: Adds refusals 6-10 to @emlSurveyValidateDeclaration -- four
#       declaration-shape faults the verification pass proved pass silently
#       (an illegal `reversed` value, a duplicated item name, an illegal
#       scale `type`, a non-numeric item data column) plus one ordering
#       repair (a declared min not below its declared max, now caught as a
#       declaration fault instead of misreported as a bad respondent row).
#       Also exposes, once, the KR-20 naming condition (declared range
#       spans exactly two values) as a per-scale output, so Stage 2 does
#       not re-derive it. No reversal transform, no per-subscale routing,
#       no report -- still Stage 1 only.
#
# V1.3: An adversarial pass found that the scales file was validated far
#       less thoroughly than the items file: a missing required column
#       (either file) HALTED Praat outright instead of refusing, and a
#       non-numeric or missing declared min/max endpoint validated clean
#       (both guards that read it compare against `undefined`, which is
#       false against everything). Adds refusals 11-14 to close the class:
#       11 (a required column missing from either declaration file), 12
#       (a non-numeric or missing declared min/max endpoint), 13 (a scale
#       name declared more than once), 14 (an empty scale name). Refusal 7
#       (item name declared more than once) is refactored, not changed in
#       behavior, onto the new shared @eml_findDuplicateName helper that
#       refusal 13 also uses, so the items file and the scales file are no
#       longer checked for duplicates by two different pieces of logic.
#       Also fixes refusal 6's message, found in the same pass printing
#       the internal token "--undefined--" for a non-numeric `reversed`
#       value instead of the value as declared.
#
# Part of the EML Stats library (EML Praat Tools).
# License: GPL-3.0-or-later
#
# Provides: @emlCronbachAlpha, @emlAlphaInfluence,
#   @emlSurveyValidateDeclaration
#
# Internal helpers: @eml_listwiseComplete, @eml_findDuplicateName
#
# Dependencies: @emlCronbachAlpha and @emlAlphaInfluence use only Praat
# built-in vector and matrix primitives and the built-in F distribution.
#
#   @emlSurveyValidateDeclaration (v1.1) requires @emlStripHeaderQuotes from
#   eml-extract.praat. The calling script must include extract
#   before psychometrics:
#     include eml-extract.praat
#     include eml-psychometrics.praat
#
#   V1.2's refusal 8 additionally calls @emlAuditColumn, also from
#   eml-extract.praat -- no new include is needed beyond the one above.
#
#   V1.3's refusal 11 additionally calls @emlRequireColumnPresent and
#   refusal 12 calls @emlRequireNumericColumn, both from
#   eml-inferential.praat. The calling script must include inferential
#   before psychometrics as well:
#     include eml-extract.praat
#     include eml-inferential.praat
#     include eml-psychometrics.praat
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
# The confidence interval uses the Feldt (1965) F-distribution method
# with df1 = n - 1 and df2 = (n - 1)(k - 1), matching R's psych::alpha.
#
# ITS LEVEL IS AN ARGUMENT, not a constant, the same way @emlCI and the
# sibling @emlWilsonInterval take theirs. A caller working at alpha = .01
# gets a 99% interval by asking for one, and .confidence is echoed back
# beside the bounds so a report printing them can name the level it prints.
#
# Arguments:
#   .data##      - numeric matrix; rows = respondents, columns = items
#   .confidence  - confidence level as a proportion, e.g. 0.95
#
# Output:
#   .alpha            - Cronbach's alpha (covariance-based, sample
#                       variances with n - 1 denominator)
#   .ciLow            - lower bound of the Feldt interval
#   .ciHigh           - upper bound of the Feldt interval
#   .confidence       - the level the bounds were computed at, echoed
#   .k                - number of items (columns)
#   .n                - number of respondents used (complete rows)
#   .nExcluded        - rows removed by listwise deletion
#   .alphaIfDeleted#  - vector, length k: alpha of the scale with that
#                       item removed (undefined for every item when
#                       k = 2, because a one-item scale has no alpha)
#   .error$           - error message, or "" if valid
#
# Access pattern:
#   @emlCronbachAlpha: responses##, 0.95
#   a = emlCronbachAlpha.alpha
#   dropTwo = emlCronbachAlpha.alphaIfDeleted# [2]
#
# Notes:
#   - Items are assumed already scored in a consistent direction;
#     reverse-scoring is the caller's responsibility. An item scored
#     in the wrong direction lowers alpha — it is not detected here.
#   - Requires k >= 2 items and, after listwise deletion, n >= 3
#     respondents (the Feldt CI needs n - 1 >= 2).
#   - .confidence must lie strictly between 0 and 1; anything else is
#     refused in .error$ rather than handed to invFisherQ, whose tail
#     probability is undefined at 0 and at 1.
#   - Raw values are returned; callers format for display.
# ============================================================================

procedure emlCronbachAlpha: .data##, .confidence
    # Initialize outputs
    .alpha = undefined
    .ciLow = undefined
    .ciHigh = undefined
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
    if .confidence = undefined or .confidence <= 0 or .confidence >= 1
        .error$ = "confidence must be strictly between 0 and 1, "
        ... + "e.g. 0.95"
    elsif .k < 2
        .error$ = "Alpha needs at least 2 items; the matrix has "
        ... + string$ (.k) + "."
    elsif .n < 3
        .error$ = "Alpha needs at least 3 complete respondents; "
        ... + string$ (.nRowsIn) + " arrived and " + string$ (.n)
        ... + " remained after listwise deletion."
    else
        # --- Center per column before any variance ---
        # Variance is translation-invariant, and the sum-of-squares
        # formula below loses its signal to cancellation when a large
        # common offset rides on every value (data at 1e8 squares to
        # 1e16, past double precision's reach). Centering first keeps
        # the sums at the scale of the spread.
        .rawColSum# = columnSums# (.work##)
        .ones# = zero# (.n) + 1
        .work## = .work## - outer## (.ones#, .rawColSum# * (1 / .n))

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

            # --- Feldt (1965) confidence interval ---
            # Both tails come from .confidence, so the level the caller
            # asked for is the level the bounds carry. The two-sided tail
            # is (1 - confidence) / 2 at each end, which reproduces the
            # .025 / .975 pair exactly at the conventional 0.95.
            .tail = (1 - .confidence) / 2
            .df1 = .n - 1
            .df2 = (.n - 1) * (.k - 1)
            .ciLow = 1 - (1 - .alpha) * invFisherQ (.tail, .df1, .df2)
            .ciHigh = 1 - (1 - .alpha) * invFisherQ (1 - .tail, .df1, .df2)

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

        # --- Center per column before any variance ---
        # Same conditioning guard as @emlCronbachAlpha: the downdate
        # formulas below run on sums of squares, which cancel
        # catastrophically under a large common offset. Centering by
        # the full-sample column means leaves every variance — full
        # and leave-one-out — unchanged.
        .rawColSum# = columnSums# (.work##)
        .ones# = zero# (.n) + 1
        .work## = .work## - outer## (.ones#, .rawColSum# * (1 / .n))

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
# @emlSurveyValidateDeclaration
# ============================================================================
# Checks a survey declaration against the data it describes, before any
# reliability number is computed. The declaration is two small Tables (read
# from the two CSVs at evidence/csv/lane_survey_declared_SCHEMA.md's format
# -- a caller with a path just needs two "Read Table from comma-separated
# file..." lines, so no reader procedure lives here):
#
#   .scalesTableId - one row per subscale: columns "scale", "min", "max",
#                    "type" ("ordinal" or "continuous")
#   .itemsTableId  - one row per data column: columns "item", "role" (a
#                    scale name, "grouping", or "ignore"), "reversed" (0/1)
#
# against the data itself:
#
#   .dataTableId   - one row per respondent, one column per question
#
# Fourteen refusals. The first one found wins and stops the checks that
# follow it. Refusals 1-5 are Ian's original plan (SURVEY_MODULE_PLAN_2026-
# 08-25.md, "The validator"); refusals 6-9 are four ways the verification
# pass proved a declaration passes all five while leaving Stage 2's routing
# unsafe, each independently probed against Praat 6.6.30 and approved by
# Ian; refusal 10 is a contract repair to refusal 2, not a new probed hole,
# flagged as such where it is checked below -- it is Ian's to veto. Refusals
# 11-14 are a second adversarial pass's finding that the class of fault
# refusals 6-10 closed on the ITEMS file was never closed on the SCALES
# file: a missing required column halted Praat outright, and a non-numeric
# or missing declared min/max endpoint validated clean, on the scales file
# specifically (the items file's own required columns and its "reversed"
# and duplicate-name checks already existed).
#
#   1. An item names a column the data table does not have.
#   2. A data value falls outside its subscale's declared range. A MISSING
#      cell is not out of range -- listwise deletion handles it later, and
#      this refusal must not fire on it.
#   3. A subscale has fewer than two items.
#   4. An item declared "grouping" or "ignore" has reversed set to 1.
#   5. The scales file and the items file disagree on subscale names, in
#      EITHER direction: an item names a scale the scales file lacks, or a
#      declared scale has no item using it.
#   6. An item's `reversed` holds a value other than 0 or 1. The refusal 4
#      guard below reads "if .itemReversed[.i] = 1", true only for the
#      legal "reversed" value, so anything else passes it silently and is
#      treated as not-reversed with no disclosure.
#   7. An item name is declared more than once in survey_items.csv. Without
#      this, Stage 2 would read that column into its subscale twice -- once
#      forward, once reversed if so declared -- inflating k and injecting a
#      perfectly anti-correlated pair.
#   8. An item resolved to a subscale has a non-numeric data column. Refusal
#      2's range check reads the same cell through plain "Get value:",
#      which returns undefined for a non-numeric cell exactly as it does
#      for a genuinely missing one, so a text column (e.g. a scale item
#      mistakenly pointed at a free-text column) sails through refusal 2,
#      every row is excluded by listwise deletion, and the kernel then
#      blames the sample size for what is really a declaration fault.
#   9. A scale's `type` is neither "ordinal" nor "continuous". The scales
#      read loop never read the type column before V1.2; Stage 2 branches
#      on it to choose the ordinal-as-interval disclosure line and would
#      print the wrong one, or none, on anything else.
#  10. [CONTRACT REPAIR, not a new probed hole -- Ian's to veto] A scale's
#      declared minimum is not below its declared maximum. Before this,
#      swapped endpoints (e.g. min 5, max 1) reached refusal 2 first, which
#      then named a RESPONDENT ROW with a remedy to check that row's data --
#      sending the user to inspect clean data when the fault is the
#      declaration's own transposed pair. An inverted range is a fault in
#      the declaration itself, not in any respondent's answer, so it must
#      be caught before any respondent row is examined.
#  11. A required column ("item", "role", "reversed" in survey_items.csv;
#      "scale", "min", "max", "type" in survey_scales.csv) is missing from
#      its file. Before this, a bare "Get value:" on a missing column
#      HALTED Praat outright (proved live: a three-column "scale,min,max"
#      scales file, the shape every declaration written before V1.2 has,
#      aborts with "Error: Table ... there is no column named ""type""")
#      instead of producing one of these fourteen refusals. Checked before
#      ANYTHING else in this procedure touches either table -- including
#      the array-population loops immediately below, which are what would
#      otherwise halt.
#  12. A subscale's declared `min` or `max` is missing or not numeric.
#      Before this, "Get value:" returns `undefined` for a non-numeric or
#      empty cell, and every guard that reads it -- refusal 10's
#      ".scaleMin[.s] >= .scaleMax[.s]" and refusal 2's range comparison --
#      is FALSE against `undefined` on either side, so both silently
#      disabled (proved live: "Confidence,one,5,ordinal" returns refusal =
#      0, and Stage 2 would then compute every reverse-scored value in the
#      subscale as `undefined + max - x`). Checked before refusal 10, which
#      depends on it.
#  13. A scale name is declared more than once in survey_scales.csv.
#      Refusal 2's resolution loop assigns `.sMin` / `.sMax` on every
#      matching row with no break, so a duplicate silently makes the LAST
#      matching row win (proved live: "Confidence,1,5,ordinal" and
#      "Confidence,1,200,ordinal" both present returns refusal = 0 against
#      a planted 99). Refusal 7 already refuses exactly this fault in the
#      items file; this is its analogue for the scales file, and shares
#      its scan (@eml_findDuplicateName, below).
#  14. A scale name is empty. Unchecked by the same gap as 13: an empty
#      name is never matched against a data column the way an item name
#      is (refusal 1), so nothing else in this procedure would ever catch
#      it.
#
# ORDERING, why refusals 6, 7, 9, 10 sit before 2 and 8 rather than after
# 5, and why 11-14 sit where they do: 6, 7, 9, 10, 11, 12, 13 and 14 are
# ALL faults in the declaration ITSELF -- each is decided from
# survey_items.csv or survey_scales.csv alone, with no data Table read at
# all -- while 2 and 8 both read every respondent's data. A declaration
# fault must be reported before any data-reading refusal has a chance to
# misreport it (refusal 10's whole reason for existing), so the checked
# order is: 11, 1, 7, 6, 14, 13, 12, 9, 10, 8, 2, 3, 4, 5. Refusal 11 comes
# first of all, ahead even of refusal 1: it is the one check that must run
# before the items- and scales-array population loops themselves, which
# read every required column with a bare "Get value:" and would otherwise
# be the thing that halts. Within the remaining declaration-shape faults,
# the items-table checks (7, 8's precondition aside, then 6) run before
# the scales-table checks (14, 13, 12, 9, 10) because the items table is
# the one read first, above; 7 (no item name repeated) runs before 6 (each
# `reversed` value is legal) because a row's own name is the more basic
# fact about it, and the same reasoning orders the scales-table checks: 14
# (a scale has a name at all) before 13 (that name is not repeated) before
# 12 (its declared range is usable) before 9 (its declared type is legal)
# before 10 (its range is not transposed) -- each a more basic fact about
# a scale than the one that follows it, and 12 specifically must precede
# 10 because 10 reads exactly the two values 12 confirms are usable. This
# reordering only inserts new checks -- it does not alter what refusals
# 1-5 individually decide, so a fixture that seeds exactly one of the
# original five defects (and nothing from 6, 7, 9, 10, 11, 12, 13, 14)
# still resolves to that same original code; validate/v129_survey_
# declaration.R keeps every refusal-1-through-5 leg passing unchanged.
#
# Refusal 1 is checked before refusal 2 for a reason beyond the plan's
# ordering: refusal 2's range check reads every item's data column by name,
# and it can only do that safely once refusal 1 has confirmed every item
# names a real column. By the time refusal 2's loop runs, that precondition
# already holds.
#
# ----------------------------------------------------------------------------
# @eml_findDuplicateName
# Internal helper: shared duplicate-name scan for a declaration file's own
# name column -- survey_items.csv's "item" (refusal 7) and
# survey_scales.csv's "scale" (refusal 13) ask the SAME question of two
# different tables/columns, so this is that question, asked once, rather
# than the same nested loop written out twice.
#
# A later duplicate is reported by ITS OWN row number: the first
# occurrence is not itself wrong, so naming the second occurrence names
# the row to delete. Reports only the FIRST duplicated name found,
# scanning in row order, matching refusal 7's pre-existing behavior
# exactly (a table with more than one duplicated name reports the
# earliest one).
#
# Input:  .tableId, .columnName$, .nRows
# Output: .found    - 1 if some name repeats, 0 otherwise
#         .name$    - the repeated name (only meaningful when .found = 1)
#         .firstRow - row of the first occurrence
#         .dupRow   - row of the duplicate (the later occurrence)
# ----------------------------------------------------------------------------
procedure eml_findDuplicateName: .tableId, .columnName$, .nRows
    .found = 0
    .name$ = ""
    .firstRow = 0
    .dupRow = 0
    for .i from 1 to .nRows
        selectObject: .tableId
        .iName$ = Get value: .i, .columnName$
        for .j from .i + 1 to .nRows
            selectObject: .tableId
            .jName$ = Get value: .j, .columnName$
            if .jName$ = .iName$
                if .found = 0
                    .found = 1
                    .name$ = .iName$
                    .firstRow = .i
                    .dupRow = .j
                endif
            endif
        endfor
    endfor
endproc

# THE TEACHING-MESSAGE CONTRACT (docs/CHANGE_ORDER_CONFORMANCE_LINT.md): the
# rule in one sentence, the reason in one line, what to do instead. The rule
# and the reason are assembled into .error$; the fix is .remedy$, kept as
# its own output so a caller can show it separately (a dialog action line,
# a CSV note) without parsing a sentence for it.
#
# ----------------------------------------------------------------------------
# DRAFT LANGUAGE -- awaiting Ian's approval (language section, plan p.159).
# Every fragment below is user-facing wording, not logic. All five are
# collected in this one block, in refusal order, so approved wording drops
# in by editing these fragments alone; nothing below this block should need
# to change when it does. Each fragment is a literal piece of the sentence;
# the check sites concatenate them around the item/scale/row/value in
# question with "+". Every fragment is plain ASCII (CLAUDE.md: any string
# literal that can reach a file must be).
# ----------------------------------------------------------------------------
procedure emlSurveyValidateDeclaration: .dataTableId, .scalesTableId, .itemsTableId
    # --- Outputs: initialize before any check runs ---
    .error$ = ""
    .remedy$ = ""
    .refusal = 0
    .badItem$ = ""
    .badScale$ = ""
    .badRow = 0
    .badValue = undefined
    .badMin = undefined
    .badMax = undefined
    .scaleItemCount = undefined
    .badRole$ = ""
    .badDirection$ = ""
    ; V1.2 additions (refusals 6-10) below. .badItem$, .badScale$ and
    ; .badRow above are reused where they already say the right thing
    ; (refusals 6-8 name an item, 9-10 name a scale, 8 names a data row);
    ; these four are the fields those five refusals need and nothing above
    ; already carries.
    .badReversedValue = undefined
    .badItemRow = 0
    .badScaleRow = 0
    .badTypeValue$ = ""
    .badCellText$ = ""
    ; V1.3 additions (refusals 11-14) below.
    .badColumn$ = ""
    .badFile$ = ""
    .badRawValue$ = ""

    # --- Canon keyword sets (V1.2), stated ONCE here -- every check below
    # that needs to know a legal `reversed` value or a legal `type` keyword
    # reads one of these, never a literal. (The pre-existing "grouping" /
    # "ignore" role literals in refusals 4 and 5 above are untouched V1.1
    # code and outside this addition's scope.)
    .reversedValueFalse = 0
    .reversedValueTrue = 1
    .typeKeywordOrdinal$ = "ordinal"
    .typeKeywordContinuous$ = "continuous"

    ; DRAFT LANGUAGE -- awaiting Ian's approval
    # Refusal 1: item names a column the data table lacks.
    .msg1a$ = "Every item in survey_items.csv must name a column that "
    ... + "exists in the data table. Item """
    .msg1b$ = """ does not match any column header in the data table, "
    ... + "so there is nothing to read its responses from."
    .rem1$ = "Correct the item name in survey_items.csv to match the "
    ... + "data table's column header exactly, or delete this row if "
    ... + "the column no longer exists."

    ; DRAFT LANGUAGE -- awaiting Ian's approval
    # Refusal 2: a data value outside its subscale's declared range.
    .msg2a$ = "Every response must fall within its subscale's declared "
    ... + "range. Respondent row "
    .msg2b$ = ", item """
    .msg2c$ = """ (subscale """
    .msg2d$ = """), has the value "
    .msg2e$ = ", outside the declared range "
    .msg2f$ = " to "
    .msg2g$ = "."
    .rem2a$ = "Check respondent row "
    .rem2b$ = " for a data-entry error, or correct the declared range "
    ... + "for """
    .rem2c$ = """ in survey_scales.csv if the printed range was "
    ... + "mistyped."

    ; DRAFT LANGUAGE -- awaiting Ian's approval
    # Refusal 3: a subscale with fewer than two items.
    .msg3a$ = "Every subscale needs at least two items before its "
    ... + "reliability can be computed. Subscale """
    .msg3b$ = """ has "
    .msg3c$ = " item(s) declared."
    .rem3a$ = "Add another item with role """
    .rem3b$ = """ in survey_items.csv, or remove """
    .rem3c$ = """ from survey_scales.csv if it is meant to have only "
    ... + "one question."

    ; DRAFT LANGUAGE -- awaiting Ian's approval
    # Refusal 4: reversed set on a grouping or ignore column.
    .msg4a$ = "Only a scale item can be reverse-scored. Item """
    .msg4b$ = """ is declared """
    .msg4c$ = """ but has reversed set to 1."
    .rem4a$ = "Set reversed to 0 for """
    .rem4b$ = """ in survey_items.csv, or give it a subscale role if "
    ... + "it is meant to be scored."

    ; DRAFT LANGUAGE -- awaiting Ian's approval
    # Refusal 5, direction A: an item names a scale the scales file lacks.
    .msg5aA$ = "Every item's role must be a subscale declared in "
    ... + "survey_scales.csv, or the literal value grouping or ignore. "
    ... + "Item """
    .msg5aB$ = """ names """
    .msg5aC$ = """, which survey_scales.csv does not declare."
    .rem5aA$ = "Add a row for """
    .rem5aB$ = """ to survey_scales.csv, or correct the role for """
    .rem5aC$ = """ in survey_items.csv."

    ; DRAFT LANGUAGE -- awaiting Ian's approval
    # Refusal 5, direction B: a declared scale that no item uses.
    .msg5bA$ = "Every subscale in survey_scales.csv must be used by at "
    ... + "least one item. Subscale """
    .msg5bB$ = """ has no item declaring it as a role."
    .rem5bA$ = "Add an item with role """
    .rem5bB$ = """ in survey_items.csv, or remove """
    .rem5bC$ = """ from survey_scales.csv if it is not part of this "
    ... + "instrument."

    ; DRAFT LANGUAGE -- awaiting Ian's approval
    # Refusal 6: reversed holds a value other than 0 or 1.
    .msg6a$ = "reversed must be exactly 0 or 1; any other value is "
    ... + "silently treated as ""not reversed"" and the item stays "
    ... + "forward-scored with no disclosure. Item """
    .msg6b$ = """ has reversed set to "
    .msg6c$ = "."
    .rem6a$ = "Set reversed to 0 or 1 for """
    .rem6b$ = """ in survey_items.csv."

    ; DRAFT LANGUAGE -- awaiting Ian's approval
    # Refusal 7: an item name declared more than once.
    .msg7a$ = "Every item name in survey_items.csv must be unique. Item """
    .msg7b$ = """ is declared more than once; the second declaration is "
    ... + "row "
    .msg7c$ = "."
    .rem7a$ = "Remove the duplicate row for """
    .rem7b$ = """ in survey_items.csv, keeping only one."

    ; DRAFT LANGUAGE -- awaiting Ian's approval
    # Refusal 8: an item resolved to a subscale has a non-numeric data
    # column.
    .msg8a$ = "Every item scored as part of a subscale must hold numeric "
    ... + "responses. Item """
    .msg8b$ = """ (subscale """
    .msg8c$ = """) has a non-numeric value in respondent row "
    .msg8d$ = ": """
    .msg8e$ = """."
    .rem8a$ = "Correct or remove the non-numeric cell in column """
    .rem8b$ = """ (row "
    .rem8c$ = "), or change its role in survey_items.csv if the column "
    ... + "is not meant to be a scale item."

    ; DRAFT LANGUAGE -- awaiting Ian's approval
    # Refusal 9: a scale type that is neither ordinal nor continuous.
    .msg9a$ = "A subscale's type must be exactly ""ordinal"" or "
    ... + """continuous"". Subscale """
    .msg9b$ = """ declares type """
    .msg9c$ = """, which is neither."
    .rem9a$ = "Correct the type for """
    .rem9b$ = """ in survey_scales.csv to ordinal or continuous."

    ; DRAFT LANGUAGE -- awaiting Ian's approval
    # Refusal 10 [contract repair -- Ian's to veto]: a declared minimum
    # not below its declared maximum.
    .msg10a$ = "A subscale's declared minimum must be less than its "
    ... + "declared maximum. Subscale """
    .msg10b$ = """ declares min "
    .msg10c$ = " and max "
    .msg10d$ = ", which is not a valid range."
    .rem10a$ = "Check survey_scales.csv for """
    .rem10b$ = """: the min and max may be transposed."

    ; DRAFT LANGUAGE -- awaiting Ian's approval
    # Refusal 11: a required column is missing from either declaration
    # file.
    .msg11a$ = "Every column this validator depends on must be present. """
    .msg11b$ = """ has no column named """
    .msg11c$ = """."
    .rem11a$ = "Add a """
    .rem11b$ = """ column to """
    .rem11c$ = """, or restore it if it was removed by hand."

    ; DRAFT LANGUAGE -- awaiting Ian's approval
    # Refusal 12: a subscale's declared min or max is missing or not
    # numeric.
    .msg12a$ = "A subscale's declared min and max must both be numbers. "
    ... + "Subscale """
    .msg12b$ = """ declares """
    .msg12cText$ = """ as """
    .msg12dText$ = """, which is not a number."
    .msg12eEmpty$ = """ as empty, which is not a number."
    .rem12a$ = "Correct the """
    .rem12b$ = """ value for """
    .rem12c$ = """ in survey_scales.csv to a number."

    ; DRAFT LANGUAGE -- awaiting Ian's approval
    # Refusal 13: a scale name declared more than once.
    .msg13a$ = "Every subscale name in survey_scales.csv must be unique. "
    ... + "Subscale """
    .msg13b$ = """ is declared more than once; the second declaration is "
    ... + "row "
    .msg13c$ = "."
    .rem13a$ = "Remove the duplicate row for """
    .rem13b$ = """ in survey_scales.csv, keeping only one."

    ; DRAFT LANGUAGE -- awaiting Ian's approval
    # Refusal 14: a scale name is empty.
    .msg14a$ = "Every subscale in survey_scales.csv must have a name. Row "
    .msg14b$ = " has no scale name."
    .rem14a$ = "Add a scale name to the empty row in survey_scales.csv, "
    ... + "or delete the row if it is not a real subscale."
    # ------------------------------------------------------------------------
    # END draft language block.
    # ------------------------------------------------------------------------

    # --- Normalize any quoted column headers before any table lookup ---
    # Praat's CSV reader strips quotes from quoted DATA cells but not from
    # quoted HEADER cells (@emlStripHeaderQuotes, eml-extract.praat: a
    # header written by R's write.csv(), which quotes headers by default,
    # arrives as the literal string "Q1" including the quote characters,
    # and "Get column index: "Q1"" then returns 0 against it). All three
    # declaration tables are exactly as hand-editable and
    # R/Excel-exportable as each other -- evidence/csv/
    # lane_survey_declared_SCHEMA.md says as much of the two declaration
    # files ("You can also edit them by hand") -- so all three are
    # normalized here, once, before the first "Get value" / "Get column
    # index" below. Every column-name lookup that follows -- "item",
    # "role", "reversed", "scale", "min", "max", and every user-declared
    # item name matched against the data table -- then sees clean labels,
    # rather than adding a quote check at each of the several sites that
    # look a column up. @emlStripHeaderQuotes is idempotent on a table
    # with no quoted labels, so this costs nothing on a clean file.
    @emlStripHeaderQuotes: .itemsTableId
    @emlStripHeaderQuotes: .scalesTableId
    @emlStripHeaderQuotes: .dataTableId

    # --- .nScales and a safe .scaleIsKR20[] default, before ANYTHING else
    # can exit this procedure early ---
    # "Get number of rows" needs no particular column to exist, so this is
    # safe even when refusal 11 (immediately below) is about to find one
    # missing. It runs before refusal 11 for a narrower reason than
    # ordering: .scaleIsKR20[] is a Praat INDEXED variable, and reading an
    # indexed variable that was never assigned ANY value HALTS Praat with
    # "Undefined indexed variable" -- a harder failure than the plain
    # `undefined` a caller gets from an ordinary never-assigned scalar.
    # Before this, a caller that read .scaleIsKR20[1] after ANY refusal
    # (exactly what this procedure's own "Access pattern" section shows,
    # and what validate/v129_survey_declaration.R's probe does
    # unconditionally on every leg) crashed outright on refusal 11 alone,
    # because refusal 11 is the one refusal that can fire before the
    # scales-array population loop below ever runs. Every element is
    # seeded `undefined` here and overwritten with its real value in that
    # population loop when it runs; a scale that refusal 11 refuses before
    # reaching keeps its seeded `undefined`, which is a value a caller can
    # read, not a halt.
    selectObject: .scalesTableId
    .nScales = Get number of rows
    for .s from 1 to .nScales
        .scaleIsKR20[.s] = undefined
    endfor

    # ===== Refusal 11: a required column is missing from either =====
    # ===== declaration file                                     =====
    # Checked before ANYTHING else in this procedure touches either table.
    # The two array-population loops immediately below read every one of
    # these seven columns with a bare "Get value:", which HALTS Praat
    # outright when the named column does not exist -- proved live on a
    # three-column "scale,min,max" scales file (the shape every
    # declaration written before V1.2 has): "Error: Table ""scales_notype"":
    # there is no column named ""type""". @emlRequireColumnPresent
    # (eml-inferential.praat) turns that halt into an ordinary .error$
    # instead, so every column either loop is about to read is confirmed
    # present here first, in the same order each loop reads it in: the
    # items table's "item", "role", "reversed", then the scales table's
    # "scale", "min", "max", "type". This is the ONE canon list of
    # required columns for this procedure; nothing below restates it.
    .reqColCount = 7
    .reqColTable[1] = .itemsTableId
    .reqColFile$[1] = "survey_items.csv"
    .reqColName$[1] = "item"
    .reqColTable[2] = .itemsTableId
    .reqColFile$[2] = "survey_items.csv"
    .reqColName$[2] = "role"
    .reqColTable[3] = .itemsTableId
    .reqColFile$[3] = "survey_items.csv"
    .reqColName$[3] = "reversed"
    .reqColTable[4] = .scalesTableId
    .reqColFile$[4] = "survey_scales.csv"
    .reqColName$[4] = "scale"
    .reqColTable[5] = .scalesTableId
    .reqColFile$[5] = "survey_scales.csv"
    .reqColName$[5] = "min"
    .reqColTable[6] = .scalesTableId
    .reqColFile$[6] = "survey_scales.csv"
    .reqColName$[6] = "max"
    .reqColTable[7] = .scalesTableId
    .reqColFile$[7] = "survey_scales.csv"
    .reqColName$[7] = "type"

    for .c from 1 to .reqColCount
        @emlRequireColumnPresent: .reqColTable[.c], "Declaration column",
        ... .reqColName$[.c]
        if emlRequireColumnPresent.error$ <> ""
            .error$ = .msg11a$ + .reqColFile$[.c] + .msg11b$
            ... + .reqColName$[.c] + .msg11c$
            .remedy$ = .rem11a$ + .reqColName$[.c] + .rem11b$
            ... + .reqColFile$[.c] + .rem11c$
            .refusal = 11
            .badColumn$ = .reqColName$[.c]
            .badFile$ = .reqColFile$[.c]
            goto SURVEY_VALIDATE_DONE
        endif
    endfor

    # --- Read the items table into procedure-local arrays ---
    selectObject: .itemsTableId
    .nItems = Get number of rows
    for .i from 1 to .nItems
        selectObject: .itemsTableId
        .itemName$[.i] = Get value: .i, "item"
        .itemRole$[.i] = Get value: .i, "role"
        .itemReversed[.i] = Get value: .i, "reversed"
        ; V1.3: the RAW string alongside the numeric parse, for refusal
        ; 6's message. ".itemReversed[.i]" above is `undefined` for a
        ; non-numeric cell (e.g. "yes"), and printing that with
        ; "string$ (...)" produces the internal token "--undefined--" in a
        ; user-facing message -- the exact class of fault this pass is
        ; closing on the scales file, found here on the items file too.
        ; The raw text is read once, here, rather than re-read at the
        ; refusal 6 message site below.
        .itemReversedRaw$[.i] = Get value: .i, "reversed"
    endfor

    # --- Read the scales table into procedure-local arrays ---
    selectObject: .scalesTableId
    .nScales = Get number of rows
    for .s from 1 to .nScales
        selectObject: .scalesTableId
        .scaleName$[.s] = Get value: .s, "scale"
        .scaleMin[.s] = Get value: .s, "min"
        .scaleMax[.s] = Get value: .s, "max"
        ; V1.2: read once, into the same loop, rather than a second pass --
        ; refusal 9 needs .scaleType$[] and refusal 10 needs .scaleMin[] /
        ; .scaleMax[], already read above.
        .scaleType$[.s] = Get value: .s, "type"
        ; V1.2: the KR-20 naming condition, stated ONCE, here, as soon as
        ; min and max are both in hand -- "the declared range spans exactly
        ; two values, max = min + 1" (established ruling: this is a naming
        ; condition on the DECLARED RANGE alone, independent of the
        ; declared type, and it is not restated anywhere else in this
        ; procedure). Exposed as an output so Stage 2 does not re-derive it
        ; from scratch. Meaningful only when this procedure returns
        ; .refusal = 0 for a given scale; a scale that fails refusal 9 or
        ; 10 still gets an entry here, computed from whatever min/max it
        ; declared, but that entry is moot once the declaration itself is
        ; refused.
        .scaleIsKR20[.s] = .scaleMax[.s] = .scaleMin[.s] + 1
    endfor

    # ===== Refusal 14: a scale name is empty =====
    # Checked before refusal 13 (duplicate scale name): whether a scale
    # HAS a name at all is the more basic fact about it. Unchecked before
    # V1.3 by the same gap named in this pass's header: an empty scale
    # name is never matched against a data column the way an item name is
    # (refusal 1), so nothing else in this procedure would ever catch it.
    for .s from 1 to .nScales
        if .scaleName$[.s] = ""
            .error$ = .msg14a$ + string$ (.s) + .msg14b$
            .remedy$ = .rem14a$
            .refusal = 14
            .badScaleRow = .s
            goto SURVEY_VALIDATE_DONE
        endif
    endfor

    # ===== Refusal 13: a scale name declared more than once =====
    # Shares its scan with refusal 7 (an item name declared more than
    # once, below) via @eml_findDuplicateName: the two ask the same
    # question of two different tables/columns, and V1.3 does not want a
    # second copy of that nested loop.
    @eml_findDuplicateName: .scalesTableId, "scale", .nScales
    if eml_findDuplicateName.found = 1
        .error$ = .msg13a$ + eml_findDuplicateName.name$ + .msg13b$
        ... + string$ (eml_findDuplicateName.dupRow) + .msg13c$
        .remedy$ = .rem13a$ + eml_findDuplicateName.name$ + .rem13b$
        .refusal = 13
        .badScale$ = eml_findDuplicateName.name$
        .badScaleRow = eml_findDuplicateName.dupRow
        goto SURVEY_VALIDATE_DONE
    endif

    # ===== Refusal 12: a subscale's declared min or max is missing or =====
    # ===== not numeric                                                =====
    # @emlRequireNumericColumn (eml-inferential.praat), strict = 1, decides
    # WHETHER the "min" (then "max") column is clean: strict mode refuses
    # when ANY cell is unusable, which covers both a non-numeric endpoint
    # and a missing one (an empty cell is not "kind 0 valid" either).
    # Before this, "Get value:" silently returned `undefined` for either
    # fault and every guard downstream that compared against it -- refusal
    # 10's ">=" and refusal 2's range check -- was FALSE against
    # `undefined` on either side, so both silently disabled (proved live:
    # "Confidence,one,5,ordinal" returned refusal = 0). Checked before
    # refusal 10, which depends on both endpoints already being usable
    # numbers.
    #
    # @emlRequireNumericColumn does not itself say WHICH row is bad, so
    # once it says a column is not clean, the specific row is located with
    # @emlAuditColumn -- the same per-cell classifier refusal 8 already
    # calls directly, above, rather than a second classifier -- by taking
    # the smallest of its five "first bad row" outputs that is nonzero
    # (whichever condition the bad cell falls under: empty, comma-locale,
    # coerced, leading-dot, or outright unreadable, the row with the
    # smallest number is the first one that made the column unusable). Its
    # RAW text is then read as a STRING, not re-derived or re-classified,
    # purely to name it in the message without ever printing
    # "--undefined--" (refusal 5, this pass's own header finding).
    @emlRequireNumericColumn: .scalesTableId, "Subscale range", "min", 1
    .badEndpointError$ = emlRequireNumericColumn.error$
    .badEndpointCol$ = "min"
    if .badEndpointError$ = ""
        @emlRequireNumericColumn: .scalesTableId, "Subscale range", "max", 1
        .badEndpointError$ = emlRequireNumericColumn.error$
        .badEndpointCol$ = "max"
    endif
    if .badEndpointError$ <> ""
        @emlAuditColumn: .scalesTableId, .badEndpointCol$
        .badScaleRow = 0
        if emlAuditColumn.firstEmptyRow > 0
            .badScaleRow = emlAuditColumn.firstEmptyRow
        endif
        if emlAuditColumn.firstLocaleRow > 0
            if .badScaleRow = 0 or emlAuditColumn.firstLocaleRow < .badScaleRow
                .badScaleRow = emlAuditColumn.firstLocaleRow
            endif
        endif
        if emlAuditColumn.firstCoercedRow > 0
            if .badScaleRow = 0 or emlAuditColumn.firstCoercedRow < .badScaleRow
                .badScaleRow = emlAuditColumn.firstCoercedRow
            endif
        endif
        if emlAuditColumn.firstLeadingDotRow > 0
            if .badScaleRow = 0 or emlAuditColumn.firstLeadingDotRow < .badScaleRow
                .badScaleRow = emlAuditColumn.firstLeadingDotRow
            endif
        endif
        if emlAuditColumn.firstUnreadableRow > 0
            if .badScaleRow = 0 or emlAuditColumn.firstUnreadableRow < .badScaleRow
                .badScaleRow = emlAuditColumn.firstUnreadableRow
            endif
        endif
        .badScale$ = .scaleName$[.badScaleRow]
        .badColumn$ = .badEndpointCol$
        selectObject: .scalesTableId
        .badRawValue$ = Get value: .badScaleRow, .badEndpointCol$
        if .badRawValue$ = ""
            .error$ = .msg12a$ + .badScale$ + .msg12b$ + .badColumn$
            ... + .msg12eEmpty$
        else
            .error$ = .msg12a$ + .badScale$ + .msg12b$ + .badColumn$
            ... + .msg12cText$ + .badRawValue$ + .msg12dText$
        endif
        .remedy$ = .rem12a$ + .badColumn$ + .rem12b$ + .badScale$
        ... + .rem12c$
        .refusal = 12
        goto SURVEY_VALIDATE_DONE
    endif

    selectObject: .dataTableId
    .nData = Get number of rows

    # --- V1.2: each item's resolved subscale, computed ONCE -------------
    # An item's role resolves to a declared subscale when it names a value
    # in .scaleName$[]; "grouping", "ignore", and any role naming no
    # declared scale (refusal 5's own question) resolve to 0. Refusal 2's
    # own inline loop below asks this same question a second time, by
    # design: refusal 2 is pre-existing V1.1 code and this addition does
    # not alter it. Refusal 8, added in V1.2, reads .itemScaleIndex[] here
    # instead of writing that loop a third time.
    for .i from 1 to .nItems
        .itemScaleIndex[.i] = 0
        for .s from 1 to .nScales
            if .itemRole$[.i] = .scaleName$[.s]
                .itemScaleIndex[.i] = .s
            endif
        endfor
    endfor

    # ===== Refusal 1: item names a column the data table lacks =====
    for .i from 1 to .nItems
        selectObject: .dataTableId
        .colIndex = Get column index: .itemName$[.i]
        if .colIndex = 0
            .error$ = .msg1a$ + .itemName$[.i] + .msg1b$
            .remedy$ = .rem1$
            .refusal = 1
            .badItem$ = .itemName$[.i]
            goto SURVEY_VALIDATE_DONE
        endif
    endfor

    # ===== V1.2 additions: refusals 7, 6, 9, 10, 8 =====
    # All five are inserted HERE -- after refusal 1, before refusal 2 --
    # per the ordering rationale in this procedure's header comment: 7, 6,
    # 9 and 10 are pure declaration-shape faults (decided from
    # survey_items.csv / survey_scales.csv alone) and must run before any
    # refusal that reads respondent data; 8 reads respondent data but must
    # still run before refusal 2 reaches the same cells (refusal 8's own
    # reason for existing). None of the five touches refusal 1's own logic
    # above or refusal 2's below.

    # ===== Refusal 7: an item name declared more than once =====
    # A later duplicate is reported by ITS OWN row number in
    # survey_items.csv: the first occurrence is not itself wrong, so
    # naming the second occurrence names the row to delete. V1.3:
    # refactored onto @eml_findDuplicateName, shared with refusal 13's
    # identical question about survey_scales.csv's "scale" column --
    # behavior unchanged, same message fragments, same outputs.
    @eml_findDuplicateName: .itemsTableId, "item", .nItems
    if eml_findDuplicateName.found = 1
        .error$ = .msg7a$ + eml_findDuplicateName.name$ + .msg7b$
        ... + string$ (eml_findDuplicateName.dupRow) + .msg7c$
        .remedy$ = .rem7a$ + eml_findDuplicateName.name$ + .rem7b$
        .refusal = 7
        .badItem$ = eml_findDuplicateName.name$
        .badItemRow = eml_findDuplicateName.dupRow
        goto SURVEY_VALIDATE_DONE
    endif

    # ===== Refusal 6: reversed holds a value other than 0 or 1 =====
    for .i from 1 to .nItems
        if .itemReversed[.i] <> .reversedValueFalse and .itemReversed[.i] <> .reversedValueTrue
            ; V1.3: the message names the RAW declared value
            ; (.itemReversedRaw$[.i]), not "string$ (.itemReversed[.i])".
            ; A non-numeric "reversed" cell (e.g. "yes") makes the numeric
            ; parse `undefined`, and printing that with "string$ (...)"
            ; produced the internal token "--undefined--" in a user-facing
            ; message here -- the same class of fault this pass closes on
            ; the scales file (refusal 12), found on this message too.
            .error$ = .msg6a$ + .itemName$[.i] + .msg6b$
            ... + .itemReversedRaw$[.i] + .msg6c$
            .remedy$ = .rem6a$ + .itemName$[.i] + .rem6b$
            .refusal = 6
            .badItem$ = .itemName$[.i]
            .badItemRow = .i
            .badReversedValue = .itemReversed[.i]
            goto SURVEY_VALIDATE_DONE
        endif
    endfor

    # ===== Refusal 9: a scale type that is neither ordinal nor continuous =====
    for .s from 1 to .nScales
        if .scaleType$[.s] <> .typeKeywordOrdinal$ and .scaleType$[.s] <> .typeKeywordContinuous$
            .error$ = .msg9a$ + .scaleName$[.s] + .msg9b$ + .scaleType$[.s]
            ... + .msg9c$
            .remedy$ = .rem9a$ + .scaleName$[.s] + .rem9b$
            .refusal = 9
            .badScale$ = .scaleName$[.s]
            .badScaleRow = .s
            .badTypeValue$ = .scaleType$[.s]
            goto SURVEY_VALIDATE_DONE
        endif
    endfor

    # ===== Refusal 10 [CONTRACT REPAIR -- Ian's to veto]: a declared =====
    # ===== minimum not below its declared maximum                  =====
    # Checked BEFORE refusal 2 so a transposed pair of endpoints is caught
    # as the declaration fault it is, rather than reaching refusal 2's
    # per-respondent range check and being reported as a bad DATA row.
    for .s from 1 to .nScales
        if .scaleMin[.s] >= .scaleMax[.s]
            .error$ = .msg10a$ + .scaleName$[.s] + .msg10b$
            ... + string$ (.scaleMin[.s]) + .msg10c$ + string$ (.scaleMax[.s])
            ... + .msg10d$
            .remedy$ = .rem10a$ + .scaleName$[.s] + .rem10b$
            .refusal = 10
            .badScale$ = .scaleName$[.s]
            .badScaleRow = .s
            .badMin = .scaleMin[.s]
            .badMax = .scaleMax[.s]
            goto SURVEY_VALIDATE_DONE
        endif
    endfor

    # ===== Refusal 8: an item resolved to a subscale has a non-numeric =====
    # ===== data column                                                =====
    # Only items whose role resolves to a declared subscale need numeric
    # data (.itemScaleIndex[.i] > 0, computed once above) -- a grouping or
    # ignore column may legitimately hold text, e.g. Voice holding
    # "Soprano" / "Alto", and is not checked here. @emlAuditColumn
    # (eml-extract.praat) tells a non-numeric cell (its kind 3,
    # "unreadable": text that is not a number in any locale) apart from a
    # genuinely empty one (its kind 1, "empty"); only the former refuses
    # here, so a real missing cell stays exempt exactly as refusal 2's own
    # header comment requires.
    for .i from 1 to .nItems
        if .itemScaleIndex[.i] > 0
            @emlAuditColumn: .dataTableId, .itemName$[.i]
            if emlAuditColumn.error$ = "" and emlAuditColumn.nUnreadable > 0
                .matchedScaleIdx = .itemScaleIndex[.i]
                .error$ = .msg8a$ + .itemName$[.i] + .msg8b$
                ... + .scaleName$[.matchedScaleIdx] + .msg8c$
                ... + string$ (emlAuditColumn.firstUnreadableRow) + .msg8d$
                ... + emlAuditColumn.firstUnreadableValue$ + .msg8e$
                .remedy$ = .rem8a$ + .itemName$[.i] + .rem8b$
                ... + string$ (emlAuditColumn.firstUnreadableRow) + .rem8c$
                .refusal = 8
                .badItem$ = .itemName$[.i]
                .badScale$ = .scaleName$[.matchedScaleIdx]
                .badRow = emlAuditColumn.firstUnreadableRow
                .badCellText$ = emlAuditColumn.firstUnreadableValue$
                goto SURVEY_VALIDATE_DONE
            endif
        endif
    endfor

    # ===== Refusal 2: a data value outside its subscale's declared range =====
    # Every item's column is now known to exist (refusal 1 passed), so
    # "Get value:" below addresses a real column. Only items whose role
    # resolves to a declared scale are checked here; a role that resolves
    # to nothing is refusal 5's question, not this one, and is left alone.
    for .i from 1 to .nItems
        .role$ = .itemRole$[.i]
        .matched = 0
        for .s from 1 to .nScales
            if .role$ = .scaleName$[.s]
                .matched = 1
                .sMin = .scaleMin[.s]
                .sMax = .scaleMax[.s]
            endif
        endfor
        if .matched = 1
            for .r from 1 to .nData
                selectObject: .dataTableId
                .val = Get value: .r, .itemName$[.i]
                if .val <> undefined
                    if .val < .sMin or .val > .sMax
                        .error$ = .msg2a$ + string$ (.r) + .msg2b$
                        ... + .itemName$[.i] + .msg2c$ + .role$ + .msg2d$
                        ... + string$ (.val) + .msg2e$ + string$ (.sMin)
                        ... + .msg2f$ + string$ (.sMax) + .msg2g$
                        .remedy$ = .rem2a$ + string$ (.r) + .rem2b$
                        ... + .role$ + .rem2c$
                        .refusal = 2
                        .badItem$ = .itemName$[.i]
                        .badScale$ = .role$
                        .badRow = .r
                        .badValue = .val
                        .badMin = .sMin
                        .badMax = .sMax
                        goto SURVEY_VALIDATE_DONE
                    endif
                endif
            endfor
        endif
    endfor

    # ===== Refusal 3: a subscale with fewer than two items =====
    # Deliberately >= 1 here, not just < 2: a scale with ZERO items is not
    # "too few items to compute reliability on", it is refusal 5 direction
    # B below -- the scales file declaring a subscale the items file never
    # uses. Folding count = 0 into this refusal would make that direction
    # of refusal 5 unreachable (a scale nobody uses always has 0 items, so
    # this check would claim it first, every time), which is exactly the
    # dead-code trap: the plan (SURVEY_MODULE_PLAN_2026-08-25.md) pins these
    # as two named refusals, each needing its own seeded red demo, and a
    # refusal that can never fire cannot be demonstrated red.
    for .s from 1 to .nScales
        .count = 0
        for .i from 1 to .nItems
            if .itemRole$[.i] = .scaleName$[.s]
                .count = .count + 1
            endif
        endfor
        if .count >= 1 and .count < 2
            .error$ = .msg3a$ + .scaleName$[.s] + .msg3b$ + string$ (.count)
            ... + .msg3c$
            .remedy$ = .rem3a$ + .scaleName$[.s] + .rem3b$
            ... + .scaleName$[.s] + .rem3c$
            .refusal = 3
            .badScale$ = .scaleName$[.s]
            .scaleItemCount = .count
            goto SURVEY_VALIDATE_DONE
        endif
    endfor

    # ===== Refusal 4: reversed flag set on a grouping or ignore column =====
    for .i from 1 to .nItems
        if .itemReversed[.i] = 1
            if .itemRole$[.i] = "grouping" or .itemRole$[.i] = "ignore"
                .error$ = .msg4a$ + .itemName$[.i] + .msg4b$
                ... + .itemRole$[.i] + .msg4c$
                .remedy$ = .rem4a$ + .itemName$[.i] + .rem4b$
                .refusal = 4
                .badItem$ = .itemName$[.i]
                .badRole$ = .itemRole$[.i]
                goto SURVEY_VALIDATE_DONE
            endif
        endif
    endfor

    # ===== Refusal 5: scales file and items file disagree on subscale =====
    # ===== names, checked in both directions                          =====

    # Direction A: an item names a scale the scales file lacks.
    for .i from 1 to .nItems
        .role$ = .itemRole$[.i]
        if .role$ <> "grouping" and .role$ <> "ignore"
            .matched = 0
            for .s from 1 to .nScales
                if .role$ = .scaleName$[.s]
                    .matched = 1
                endif
            endfor
            if .matched = 0
                .error$ = .msg5aA$ + .itemName$[.i] + .msg5aB$ + .role$
                ... + .msg5aC$
                .remedy$ = .rem5aA$ + .role$ + .rem5aB$ + .itemName$[.i]
                ... + .rem5aC$
                .refusal = 5
                .badItem$ = .itemName$[.i]
                .badScale$ = .role$
                .badDirection$ = "item_unknown_scale"
                goto SURVEY_VALIDATE_DONE
            endif
        endif
    endfor

    # Direction B: a declared scale that no item uses.
    for .s from 1 to .nScales
        .used = 0
        for .i from 1 to .nItems
            if .itemRole$[.i] = .scaleName$[.s]
                .used = 1
            endif
        endfor
        if .used = 0
            .error$ = .msg5bA$ + .scaleName$[.s] + .msg5bB$
            .remedy$ = .rem5bA$ + .scaleName$[.s] + .rem5bB$
            ... + .scaleName$[.s] + .rem5bC$
            .refusal = 5
            .badScale$ = .scaleName$[.s]
            .badDirection$ = "scale_unused"
            goto SURVEY_VALIDATE_DONE
        endif
    endfor

    label SURVEY_VALIDATE_DONE
endproc

# ============================================================================
# Outputs: @emlSurveyValidateDeclaration
# ============================================================================
#   .error$           - refusal message (rule + reason), or "" when the
#                       declaration is sound
#   .remedy$          - what to do instead, or "" when .error$ is ""
#   .refusal          - 0 when sound; else 1-14 (see the ordering comment
#                       above the procedure for what each is and the order
#                       they are checked in; refusal 10 is a contract
#                       repair, not one of Ian's original five or the four
#                       probed additions; refusals 11-14 are a second
#                       adversarial pass closing the same class of fault
#                       on the scales file that 6-10 closed on the items
#                       file)
#   .badItem$         - the item/column name implicated (refusals 1, 2, 4,
#                       6, 7, 8, and refusal 5 direction A); "" otherwise
#   .badScale$        - the subscale name implicated (refusals 2, 3, 8, 9,
#                       10, 12, 13, and refusal 5, either direction); ""
#                       otherwise (refusal 14 leaves this "" too -- the
#                       fault IS that the scale has no name)
#   .badRow           - respondent ROW NUMBER in the data table (refusals 2
#                       and 8); 0 otherwise
#   .badValue         - the offending response value (refusal 2 only);
#                       undefined otherwise
#   .badMin           - the declared range minimum for .badScale$
#                       (refusals 2 and 10); undefined otherwise
#   .badMax           - the declared range maximum for .badScale$
#                       (refusals 2 and 10); undefined otherwise
#   .scaleItemCount   - number of items declared with role .badScale$
#                       (refusal 3 only); undefined otherwise
#   .badRole$         - the disallowed role ("grouping" or "ignore") found
#                       on a reversed item (refusal 4 only); "" otherwise
#   .badDirection$    - which side of refusal 5 fired: "item_unknown_scale"
#                       or "scale_unused"; "" otherwise
#   .badReversedValue - the illegal `reversed` value found (refusal 6
#                       only); undefined otherwise
#   .badItemRow       - ROW NUMBER in the ITEMS table implicated (refusal 7:
#                       the row of the repeated item name; refusal 6: the
#                       row holding the illegal `reversed` value); 0
#                       otherwise. Not the same table as .badRow, which is
#                       always a DATA table row.
#   .badScaleRow      - ROW NUMBER in the SCALES table implicated (refusals
#                       9, 10, 12, 13 [the duplicate row], and 14); 0
#                       otherwise
#   .badTypeValue$    - the illegal `type` string found (refusal 9 only);
#                       "" otherwise
#   .badCellText$     - the literal (non-numeric) contents of the offending
#                       cell (refusal 8 only); "" otherwise
#   .badColumn$       - the column name implicated (refusal 11: the missing
#                       required column; refusal 12: "min" or "max",
#                       whichever declared endpoint is bad); "" otherwise
#   .badFile$         - which declaration file is at fault, "survey_items.csv"
#                       or "survey_scales.csv" (refusal 11 only); ""
#                       otherwise
#   .badRawValue$     - the literal declared text of the bad endpoint cell
#                       (refusal 12 only); "" both when that cell is itself
#                       empty (a missing endpoint, rather than a
#                       non-numeric one) and when refusal is not 12. Exists
#                       so a caller can name the actual offending text
#                       without ever printing the internal token
#                       "--undefined--" for it.
#   .scaleName$[1..nScales]  - each declared subscale's name, in
#                       survey_scales.csv row order
#   .scaleType$[1..nScales]  - each declared subscale's `type` field, as
#                       declared (not validated against the type-keyword
#                       canon until refusal 9 runs)
#   .scaleMin[1..nScales], .scaleMax[1..nScales] - each declared subscale's
#                       printed response range, as declared
#   .scaleIsKR20[1..nScales] - 1 when that subscale's declared range spans
#                       exactly two values (max = min + 1), else 0. THE
#                       KR-20 naming condition, stated once in this
#                       procedure and not restated anywhere else -- Stage 2
#                       reads this rather than re-deriving it from min/max
#                       itself. Meaningful only once .refusal is confirmed
#                       0 for the declaration as a whole; a scale that
#                       fails refusal 9 or 10 still gets an entry here,
#                       computed from whatever it declared, but that entry
#                       is moot once the declaration itself is refused.
#   .nScales          - number of declared subscales (length of the four
#                       arrays immediately above)
#
# Access pattern:
#   @emlSurveyValidateDeclaration: dataTable, scalesTable, itemsTable
#   if emlSurveyValidateDeclaration.error$ <> ""
#       code = emlSurveyValidateDeclaration.refusal
#       ... report emlSurveyValidateDeclaration.error$ and .remedy$ ...
#   endif
#   ... once refusal = 0, read the KR-20 condition without re-deriving it:
#   isKR20 = emlSurveyValidateDeclaration.scaleIsKR20[3]
#
# Notes:
#   - Read-only: no cell in any of the three tables is written, and no
#     file is read or written here (the caller reads the two CSVs into
#     Tables with "Read Table from comma-separated file..." first).
#   - Does not compute reversal, subscale routing, or any reliability
#     statistic. Those are Stage 2, wired on top of a clean declaration.
#   - Leaves SOME declaration Table selected on return -- whichever one the
#     last check to run happened to touch -- matching
#     @emlRequireColumnPresent's convention of leaving a Table selected
#     rather than the caller's, but WHICH Table is no longer a fixed
#     answer as of V1.3 (refusal 7's refactor onto @eml_findDuplicateName
#     leaves .itemsTableId selected even when 7 itself does not fire, so a
#     later refusal such as 9 or 10 no longer inherits .dataTableId the
#     way it did before V1.3). A caller that needs a specific Table
#     selected should select it itself rather than rely on this
#     procedure's leftover selection.
# ============================================================================

# ============================================================================
# END OF MODULE
# ============================================================================
