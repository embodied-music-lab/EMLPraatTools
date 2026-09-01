# ============================================================================
# EML Stats : Two-Way ANOVA Kernel
# ============================================================================
# Module: eml-anova-kernel.praat
# Version: 1.0
# Date: 1 September 2026
#
# WHY THIS FILE EXISTS. Praat's built-in `Report two-way anova` computes the
# main-effect and interaction sums of squares by Khuri's (1998) unweighted-
# means method, and recovers Error by SUBTRACTING those sums from a Total
# centred on the unweighted mean of the cell means. That subtraction is only
# valid when the design is balanced or proportional. Measured on Praat's own
# manual example (Peterson-Barney 1952, F0 by Vowel x Type, a proportional
# but unbalanced design): the built-in reports SS_Error = 1,600,534 where the
# correct within-cell value is 914,449, and a Vowel F of 7.625 where the
# correct value is 13.346 -- and on a genuinely NON-proportional design
# Khuri's own EFFECT sums also disagree with Type I/II/III (all three of
# which agree with each other on a proportional design, and generally do not
# on a non-proportional one). See
# mailbox/to-opus/RULING_CONSOLIDATED_KERNELS_2026-09-01.md section 1
# (Class C) and section 2 for the ruling this file answers.
#
# This module computes the two-way table DIRECTLY from raw data -- no call
# to `Report two-way anova` anywhere in this file -- for all of Type I,
# Type II and Type III sums of squares, selectable, default Type III. It is
# a standalone kernel: nothing here is wired into any menu, dialog, or
# orchestrator (eml-inferential.praat / eml-analysis.praat). That wiring is
# later, separate work.
#
# THE ARITHMETIC, IN PLAIN TERMS.
#
#   Type I  (sequential): fit intercept, then + A, then + B, then + A:B, in
#            that order; each effect's SS is the drop in residual SS (RSS)
#            when it is added. Depends on entry order for the two mains;
#            the interaction is always entered last regardless of type.
#   Type II (each main effect adjusted for the OTHER main effect, never for
#            the interaction): SS_A = RSS(B) - RSS(A+B),
#            SS_B = RSS(A) - RSS(A+B). Order-independent.
#   Type III (each effect adjusted for everything else, including the
#            interaction): computed here as a Wald quadratic form directly
#            on the UNWEIGHTED cell means, per the ruling --
#              v# = solve# (LDL'##, Lmu#)
#              SS  = inner (Lmu#, v#)
#            where mu# is the vector of the r*s cell means, L is a
#            (df x r*s) contrast matrix picking out the effect (sum-to-zero
#            contrasts, matching R's contr.sum), and D = diag(1/n_ij) is the
#            variance shape of the cell means (up to the common sigma^2,
#            which cancels out of the SS entirely -- D never carries an
#            estimate of it). NEVER an explicit inverse: `inverse##` does
#            not exist in Praat 6.6.30 and would be worse-conditioned than
#            the linear solve even where it does. This is mathematically
#            the same definition SAS/car use for Type III (the general
#            linear hypothesis on a full-rank, sum-to-zero-coded model),
#            specialised to the two-way cell-means parameterisation, which
#            is exactly saturated (1 + (r-1) + (s-1) + (r-1)(s-1) = r*s
#            parameters for r*s cells) -- so this is not an approximation
#            of Type III, it IS Type III.
#   Types I and II above are computed the same way car::Anova would get
#   them for a two-factor model with an interaction: by RSS differences of
#   nested OLS fits on a sum-coded (contr.sum) design matrix, via the
#   normal equations (X'X) beta = X'y, solved with `solve#` -- again never
#   an explicit inverse. y is centred on its grand mean first; every model
#   fit here carries an intercept, so RSS is unchanged by that shift, and
#   it keeps the (X'X)/(X'y) products near the scale of the data's spread
#   rather than its raw magnitude.
#   Error:  SS_E = sum over cells of within-cell squared deviations
#           (equivalently sum(y^2) - sum_ij T_ij^2/n_ij; computed here via
#           the centred form for the same reason eml-inferential.praat's
#           own two-way path gives for choosing it -- numerical stability).
#           df_E = N - r*s.
#   Total:  SS_T = sum(y^2) - T^2/N, i.e. squared deviations about the
#           ordinary OBSERVATION-WEIGHTED grand mean -- not the unweighted
#           mean of the cell means. That substitution is the bug being
#           fixed here. df_T = N - 1.
#   F, p:   each effect's mean square (SS/df) against MS_Error, referred to
#           fisherQ. Error is the same for all three SS types -- only the
#           effect sums differ by type.
#   Effect sizes: partial eta^2 = SS_effect / (SS_effect + SS_Error);
#           eta^2 = SS_effect / SS_Total; omega^2 (Field 2013) =
#           (SS_effect - df_effect * MS_Error) / (SS_Total + MS_Error).
#   Levene: a standard Brown-Forsythe/Levene test (median-centred), grouped
#           by the r*s cells (the interaction of both factors) -- the same
#           grouping car::leveneTest(y ~ A*B) uses by default.
#   Shapiro-Wilk: run on the ANOVA residuals (y_ijk - cell mean_ij) through
#           the plugin's OWN existing @emlShapiroWilk
#           (eml-core-descriptive.praat) -- not a second implementation.
#
# SCOPE, EXPLICITLY. This file computes the omnibus table: SS/df/MS/F/p for
# both main effects and the interaction (Types I, II, III, all three always
# computed; the requested type controls which one is reported as the
# headline table), the three effect sizes, Levene's test, Shapiro-Wilk on
# the residuals, and an explicit balance statement. It does NOT compute
# estimated marginal means, post hoc comparisons, or simple effects --
# those are later work and are named as out of scope by the brief this file
# answers. Because Type III here comes from the r*s cell means and their
# counts directly (@eml_ak2_gather's .cellMean#/.cellN#) rather than from
# any fitted model object, an EMM step built on this kernel has the numbers
# it needs already collected in one place (.cellMean#, .cellN#, the level
# name arrays) -- that should make it a straightforward addition, not an
# awkward one, but no such procedure is built here.
#
# COMPLETE DESIGNS ONLY. Every one of the r*s factor-level combinations
# must have at least one observation. An empty cell makes Type III (and
# this file's Type I/II normal-equation solves, which use the same
# saturated, sum-coded design matrix) inestimable in the ordinary sense;
# @eml_ak2_gather refuses with .error$ rather than silently dropping a
# level or producing a singular solve. (Type III with unweighted marginal
# means is meaningful only when every level combination has data to
# average in the first place.)
#
# Part of the EML Stats library (EML Stats & Graphs).
# Part of EML PraatGen GPL-3.0-or-later — Ian Howell, Embodied Music Lab
#
# Provides: @emlAnovaKernelTwoWay, @emlLeveneTest
#   (private: @eml_ak2_gather, @eml_ak2_designSubset, @eml_ak2_ols,
#    @eml_ak2_buildContrast, @eml_ak2_buildL, @eml_ak2_typeIIIeffect)
#
# Dependencies: eml-core-descriptive.praat (@emlMedian, @emlShapiroWilk).
#   Callers must `include` that file before this one. No other dependency;
#   this file does not read eml-inferential.praat, eml-analysis.praat, or
#   any menu/dialog machinery, and is not included by any of them.
#
# Praat functions used: zero#, zero##, transpose##, mul#, mul##, inner,
#   solve# (never inverse## -- it does not exist in 6.6.30), sort# (inside
#   @emlMedian), fisherQ, floor, abs.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
#            https://github.com/embodied-music-lab/PraatGen
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
#
# RESEARCH USE DISCLOSURE
# If this script is used in research or publication, disclose AI use per
# your target journal's policy. Suggested language:
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
# @emlAnovaKernelTwoWay
# ============================================================================
# Two-way ANOVA computed directly from raw data in a Table.
#
# Arguments:
#   .tableId          - ID of a Table object (must be in the object list)
#   .dataCol$         - name of the numeric data column
#   .factor1$         - name of the first factor column (string levels)
#   .factor2$         - name of the second factor column (string levels)
#   .ssTypeRequested  - 1, 2, or 3 selects that SS type as the headline
#                       table; anything else (0, undefined, 3, garbage)
#                       defaults to Type III. All three are computed
#                       regardless -- see .ssATypeI/.ssATypeII/.ssATypeIII
#                       etc. below.
#
# Output:
#   Status:
#     .ok       - 1 on success, 0 on failure
#     .error$   - "" on success, diagnostic message on failure
#     .warning$ - non-fatal disclosure (unbalanced design, an internal
#                 cross-check that did not match), or "" if none
#   Which table:
#     .ssType      - the resolved type actually reported (1, 2, or 3)
#     .ssTypeLabel$ - "Type I" / "Type II" / "Type III"
#   Design:
#     .n, .r, .s, .rs   - N, factor-1 levels, factor-2 levels, r*s cells
#     .minCellN, .maxCellN, .balanced, .balanceStatement$
#   Headline table (the .ssType selected above):
#     .dfA, .dfB, .dfAB, .dfError, .dfTotal
#     .ssA, .ssB, .ssAB, .ssError, .ssTotal
#     .msA, .msB, .msAB, .msError
#     .fA, .fB, .fAB, .pA, .pB, .pAB
#   Every SS type, always computed (df's are the same across types --
#   .dfA/.dfB/.dfAB above -- only the sums differ):
#     .ssATypeI,  .ssBTypeI,  .ssABTypeI
#     .ssATypeII, .ssBTypeII, .ssABTypeII
#     .ssATypeIII,.ssBTypeIII,.ssABTypeIII
#   Effect sizes (computed from the headline table):
#     .partialEtaSqA, .partialEtaSqB, .partialEtaSqAB
#     .etaSqA, .etaSqB, .etaSqAB
#     .omegaSqA, .omegaSqB, .omegaSqAB
#   Levene's test (median-centred, grouped by the r*s cells):
#     .leveneW, .levenePValue, .leveneDfBetween, .leveneDfWithin,
#     .leveneError$
#   Shapiro-Wilk on the residuals (y - cell mean), via the plugin's own
#   @emlShapiroWilk:
#     .shapiroW, .shapiroP, .shapiroN, .shapiroError$
# ============================================================================
procedure emlAnovaKernelTwoWay: .tableId, .dataCol$, .factor1$, .factor2$, .ssTypeRequested
    # --- resolve the requested SS type; anything but 1 or 2 -> Type III ---
    if .ssTypeRequested = 1
        .ssType = 1
    elsif .ssTypeRequested = 2
        .ssType = 2
    else
        .ssType = 3
    endif

    # --- initialise every output. Procedure "locals" are namespaced
    #     globals that persist between calls; a stale value from a prior
    #     invocation must never leak into this one. ---
    .ok = 0
    .error$ = ""
    .warning$ = ""
    .ssTypeLabel$ = ""
    .n = 0
    .r = 0
    .s = 0
    .rs = 0
    .balanced = 0
    .balanceStatement$ = ""
    .minCellN = undefined
    .maxCellN = undefined
    .dfA = undefined
    .dfB = undefined
    .dfAB = undefined
    .dfError = undefined
    .dfTotal = undefined
    .ssA = undefined
    .ssB = undefined
    .ssAB = undefined
    .ssError = undefined
    .ssTotal = undefined
    .msA = undefined
    .msB = undefined
    .msAB = undefined
    .msError = undefined
    .fA = undefined
    .fB = undefined
    .fAB = undefined
    .pA = undefined
    .pB = undefined
    .pAB = undefined
    .ssATypeI = undefined
    .ssBTypeI = undefined
    .ssABTypeI = undefined
    .ssATypeII = undefined
    .ssBTypeII = undefined
    .ssABTypeII = undefined
    .ssATypeIII = undefined
    .ssBTypeIII = undefined
    .ssABTypeIII = undefined
    .partialEtaSqA = undefined
    .partialEtaSqB = undefined
    .partialEtaSqAB = undefined
    .etaSqA = undefined
    .etaSqB = undefined
    .etaSqAB = undefined
    .omegaSqA = undefined
    .omegaSqB = undefined
    .omegaSqAB = undefined
    .leveneW = undefined
    .levenePValue = undefined
    .leveneDfBetween = undefined
    .leveneDfWithin = undefined
    .leveneError$ = ""
    .shapiroW = undefined
    .shapiroP = undefined
    .shapiroN = 0
    .shapiroError$ = ""

    # --- gather the cell structure (levels, cell means/counts, residual
    #     building blocks, the grand-mean-centred y) ---
    @eml_ak2_gather: .tableId, .dataCol$, .factor1$, .factor2$
    .error$ = eml_ak2_gather.error$

    if .error$ = ""
        .n = eml_ak2_gather.n
        .r = eml_ak2_gather.r
        .s = eml_ak2_gather.s
        .rs = eml_ak2_gather.rs
        .balanced = eml_ak2_gather.balanced
        .balanceStatement$ = eml_ak2_gather.balanceStatement$
        .minCellN = eml_ak2_gather.minCellN
        .maxCellN = eml_ak2_gather.maxCellN
        .dfA = .r - 1
        .dfB = .s - 1
        .dfAB = .dfA * .dfB
        .dfError = eml_ak2_gather.dfError
        .dfTotal = eml_ak2_gather.dfTotal
        .ssError = eml_ak2_gather.ssError
        .ssTotal = eml_ak2_gather.ssTotal
        if .balanced = 0
            .warning$ = "The design is unbalanced; Types I, II and III do "
                ... + "not in general agree with each other, and none of "
                ... + "their effect sums of squares need add up to the "
                ... + "total sum of squares."
        endif
    endif

    # --- Types I and II, via nested-model RSS differences on a sum-coded
    #     (contr.sum) design matrix -- what car::Anova(type=1/2) computes
    #     for a two-factor model with an interaction. Five nested fits:
    #     intercept only; +A; +B; +A+B; the full (saturated) model. ---
    if .error$ = ""
        @eml_ak2_designSubset: .n, .r, .s,
            ... eml_ak2_gather.aIdx#, eml_ak2_gather.bIdx#, 0, 0, 0
        @eml_ak2_ols: eml_ak2_designSubset.x##, eml_ak2_gather.yc#
        .rss0 = eml_ak2_ols.rss

        @eml_ak2_designSubset: .n, .r, .s,
            ... eml_ak2_gather.aIdx#, eml_ak2_gather.bIdx#, 1, 0, 0
        @eml_ak2_ols: eml_ak2_designSubset.x##, eml_ak2_gather.yc#
        .rssA = eml_ak2_ols.rss

        @eml_ak2_designSubset: .n, .r, .s,
            ... eml_ak2_gather.aIdx#, eml_ak2_gather.bIdx#, 0, 1, 0
        @eml_ak2_ols: eml_ak2_designSubset.x##, eml_ak2_gather.yc#
        .rssB = eml_ak2_ols.rss

        @eml_ak2_designSubset: .n, .r, .s,
            ... eml_ak2_gather.aIdx#, eml_ak2_gather.bIdx#, 1, 1, 0
        @eml_ak2_ols: eml_ak2_designSubset.x##, eml_ak2_gather.yc#
        .rssAB0 = eml_ak2_ols.rss

        @eml_ak2_designSubset: .n, .r, .s,
            ... eml_ak2_gather.aIdx#, eml_ak2_gather.bIdx#, 1, 1, 1
        @eml_ak2_ols: eml_ak2_designSubset.x##, eml_ak2_gather.yc#
        .rssFull = eml_ak2_ols.rss

        # Type I (sequential, A then B then A:B)
        .ssATypeI = .rss0 - .rssA
        .ssBTypeI = .rssA - .rssAB0
        .ssABTypeI = .rssAB0 - .rssFull

        # Type II (each main effect adjusted for the other main effect
        # only; the interaction term is identical to Type I's, order does
        # not matter for it -- it is always last).
        .ssATypeII = .rssB - .rssAB0
        .ssBTypeII = .rssA - .rssAB0
        .ssABTypeII = .rssAB0 - .rssFull
    endif

    # --- Type III, the Wald quadratic form on unweighted cell means ---
    if .error$ = ""
        @eml_ak2_buildContrast: .r
        .cA## = eml_ak2_buildContrast.c##
        @eml_ak2_buildContrast: .s
        .cB## = eml_ak2_buildContrast.c##

        @eml_ak2_buildL: .r, .s, .cA##, .cB##, 1, 0
        .lA## = eml_ak2_buildL.l##
        @eml_ak2_buildL: .r, .s, .cA##, .cB##, 0, 1
        .lB## = eml_ak2_buildL.l##
        @eml_ak2_buildL: .r, .s, .cA##, .cB##, 1, 1
        .lAB## = eml_ak2_buildL.l##

        @eml_ak2_typeIIIeffect: .lA##, eml_ak2_gather.cellMean#, eml_ak2_gather.cellN#
        .ssATypeIII = eml_ak2_typeIIIeffect.ss
        @eml_ak2_typeIIIeffect: .lB##, eml_ak2_gather.cellMean#, eml_ak2_gather.cellN#
        .ssBTypeIII = eml_ak2_typeIIIeffect.ss
        @eml_ak2_typeIIIeffect: .lAB##, eml_ak2_gather.cellMean#, eml_ak2_gather.cellN#
        .ssABTypeIII = eml_ak2_typeIIIeffect.ss
    endif

    # --- internal cross-check: the interaction sum of squares is the
    #     SAME quantity under all three types (it is always tested last,
    #     adjusted for everything else) -- a mismatch here would mean a
    #     bug in one of the two independent code paths above, not a
    #     property of the data. ---
    if .error$ = ""
        .abScale = 1
        if abs (.ssABTypeI) > .abScale
            .abScale = abs (.ssABTypeI)
        endif
        if abs (.ssABTypeI - .ssABTypeIII) > 1e-6 * .abScale
            .warning$ = .warning$
                ... + " Internal check failed: the interaction sum of "
                ... + "squares disagreed between the RSS-difference path "
                ... + "and the Wald path by more than 1e-6 relative "
                ... + "(RSS-difference " + string$ (.ssABTypeI)
                ... + ", Wald " + string$ (.ssABTypeIII) + ")."
        endif
    endif

    # --- select the headline table ---
    if .error$ = ""
        if .ssType = 1
            .ssA = .ssATypeI
            .ssB = .ssBTypeI
            .ssAB = .ssABTypeI
            .ssTypeLabel$ = "Type I"
        elsif .ssType = 2
            .ssA = .ssATypeII
            .ssB = .ssBTypeII
            .ssAB = .ssABTypeII
            .ssTypeLabel$ = "Type II"
        else
            .ssA = .ssATypeIII
            .ssB = .ssBTypeIII
            .ssAB = .ssABTypeIII
            .ssTypeLabel$ = "Type III"
        endif

        if .dfError > 0
            .msError = .ssError / .dfError
        else
            .msError = undefined
            .warning$ = .warning$ + " The error degrees of freedom is "
                ... + string$ (.dfError) + ", so the error mean square, F "
                ... + "and p are undefined."
        endif

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
                .warning$ = .warning$ + " The error mean square is zero "
                    ... + "(no within-cell variance), so F and p are "
                    ... + "undefined."
            endif
        endif

        # --- effect sizes, from the headline table ---
        .partialEtaSqA = .ssA / (.ssA + .ssError)
        .partialEtaSqB = .ssB / (.ssB + .ssError)
        .partialEtaSqAB = .ssAB / (.ssAB + .ssError)
        if .ssTotal > 0
            .etaSqA = .ssA / .ssTotal
            .etaSqB = .ssB / .ssTotal
            .etaSqAB = .ssAB / .ssTotal
        endif
        if .msError <> undefined
            .omegaSqA = (.ssA - .dfA * .msError) / (.ssTotal + .msError)
            .omegaSqB = (.ssB - .dfB * .msError) / (.ssTotal + .msError)
            .omegaSqAB = (.ssAB - .dfAB * .msError) / (.ssTotal + .msError)
        endif
    endif

    # --- Levene's test, grouped by the r*s cells ---
    if .error$ = ""
        @emlLeveneTest: .n, eml_ak2_gather.y#, eml_ak2_gather.cellOf#, .rs
        .leveneW = emlLeveneTest.w
        .levenePValue = emlLeveneTest.p
        .leveneDfBetween = emlLeveneTest.dfBetween
        .leveneDfWithin = emlLeveneTest.dfWithin
        .leveneError$ = emlLeveneTest.error$
    endif

    # --- Shapiro-Wilk on the residuals, through the plugin's own test ---
    if .error$ = ""
        .resid# = zero# (.n)
        for .row from 1 to .n
            .resid#[.row] = eml_ak2_gather.y#[.row]
                ... - eml_ak2_gather.cellMean#[eml_ak2_gather.cellOf#[.row]]
        endfor
        @emlShapiroWilk: .resid#
        .shapiroW = emlShapiroWilk.w
        .shapiroP = emlShapiroWilk.p
        .shapiroN = emlShapiroWilk.n
        .shapiroError$ = emlShapiroWilk.error$
    endif

    if .error$ = ""
        .ok = 1
    else
        .ok = 0
    endif
endproc


# ============================================================================
# @eml_ak2_gather   (private)
# ============================================================================
# Reads the whole table once to discover factor levels, then a second time
# to resolve each row to a (factor-1 index, factor-2 index, r*s cell index)
# and accumulate cell sums. Two passes rather than one because the r*s cell
# index used everywhere downstream (row-major: cell (i,j) -> (i-1)*s + j)
# needs s = the FINAL count of factor-2 levels, which is not known until
# every row has been seen once.
#
# Output:
#   .error$, .n, .r, .s, .rs
#   .lev1$[1..r], .lev2$[1..s]          - level names, first-appearance order
#   .y#, .aIdx#, .bIdx#, .cellOf#       - per-row (length .n)
#   .cellN#, .cellSum#, .cellMean#      - per-cell (length .rs, row-major)
#   .grandSum, .grandMean, .yc#         - .yc# = .y# centred on .grandMean
#   .minCellN, .maxCellN, .balanced, .balanceStatement$
#   .ssError, .dfError, .ssTotal, .dfTotal
# ============================================================================
procedure eml_ak2_gather: .tableId, .dataCol$, .factor1$, .factor2$
    .error$ = ""
    .n = 0
    .r = 0
    .s = 0
    .rs = 0

    selectObject: .tableId
    .colD = Get column index: .dataCol$
    .col1 = Get column index: .factor1$
    .col2 = Get column index: .factor2$
    if .colD = 0
        .error$ = "Data column """ + .dataCol$ + """ was not found."
    elsif .col1 = 0
        .error$ = "First factor column """ + .factor1$ + """ was not found."
    elsif .col2 = 0
        .error$ = "Second factor column """ + .factor2$ + """ was not found."
    endif

    if .error$ = ""
        .n = Get number of rows
        if .n < 4
            .error$ = "This test needs at least 4 observations; the table "
                ... + "has " + string$ (.n) + "."
        endif
    endif

    # --- pass 1: discover factor levels, first-appearance order ---
    if .error$ = ""
        for .row from 1 to .n
            .l1$ = Get value: .row, .factor1$
            .l2$ = Get value: .row, .factor2$

            .seen1 = 0
            for .i from 1 to .r
                if .lev1$[.i] = .l1$
                    .seen1 = 1
                endif
            endfor
            if .seen1 = 0
                .r = .r + 1
                .lev1$[.r] = .l1$
            endif

            .seen2 = 0
            for .j from 1 to .s
                if .lev2$[.j] = .l2$
                    .seen2 = 1
                endif
            endfor
            if .seen2 = 0
                .s = .s + 1
                .lev2$[.s] = .l2$
            endif
        endfor
        .rs = .r * .s

        if .r < 2
            .error$ = "The first factor """ + .factor1$ + """ needs at "
                ... + "least 2 levels; found " + string$ (.r) + "."
        elsif .s < 2
            .error$ = "The second factor """ + .factor2$ + """ needs at "
                ... + "least 2 levels; found " + string$ (.s) + "."
        endif
    endif

    # --- pass 2: resolve each row to (aIdx, bIdx, cellOf), accumulate ---
    if .error$ = ""
        .y# = zero# (.n)
        .aIdx# = zero# (.n)
        .bIdx# = zero# (.n)
        .cellOf# = zero# (.n)
        .cellN# = zero# (.rs)
        .cellSum# = zero# (.rs)
        .grandSum = 0

        for .row from 1 to .n
            .yv = Get value: .row, .dataCol$
            .l1$ = Get value: .row, .factor1$
            .l2$ = Get value: .row, .factor2$

            .ai = 0
            for .i from 1 to .r
                if .lev1$[.i] = .l1$
                    .ai = .i
                endif
            endfor
            .bi = 0
            for .j from 1 to .s
                if .lev2$[.j] = .l2$
                    .bi = .j
                endif
            endfor
            .c = (.ai - 1) * .s + .bi

            .y#[.row] = .yv
            .aIdx#[.row] = .ai
            .bIdx#[.row] = .bi
            .cellOf#[.row] = .c
            .cellN#[.c] = .cellN#[.c] + 1
            .cellSum#[.c] = .cellSum#[.c] + .yv
            .grandSum = .grandSum + .yv
        endfor
        .grandMean = .grandSum / .n

        # --- completeness ---
        .nEmpty = 0
        .minCellN = .cellN#[1]
        .maxCellN = .cellN#[1]
        for .c from 1 to .rs
            if .cellN#[.c] = 0
                .nEmpty = .nEmpty + 1
            endif
            if .cellN#[.c] < .minCellN
                .minCellN = .cellN#[.c]
            endif
            if .cellN#[.c] > .maxCellN
                .maxCellN = .cellN#[.c]
            endif
        endfor
        if .nEmpty > 0
            .error$ = "The design has " + string$ (.nEmpty) + " empty "
                ... + "factor-level combination(s) out of " + string$ (.rs)
                ... + "; this kernel (and Type III sums of squares in "
                ... + "general) requires every cell to be non-empty."
        endif
    endif

    if .error$ = ""
        .cellMean# = zero# (.rs)
        for .c from 1 to .rs
            .cellMean#[.c] = .cellSum#[.c] / .cellN#[.c]
        endfor

        .balanced = 1
        if .minCellN <> .maxCellN
            .balanced = 0
        endif
        if .balanced = 1
            .balanceStatement$ = "The design is balanced: all "
                ... + string$ (.rs) + " cells have n = " + string$ (.minCellN)
                ... + " (N = " + string$ (.n) + ")."
        else
            .balanceStatement$ = "The design is unbalanced: cell sizes "
                ... + "range from " + string$ (.minCellN) + " to "
                ... + string$ (.maxCellN) + " across " + string$ (.rs)
                ... + " cells (N = " + string$ (.n) + ")."
        endif

        # y centred on the grand mean. Every model fit downstream carries
        # an intercept, so this shift changes none of their RSS values --
        # it only keeps the normal-equation products near the scale of the
        # data's spread rather than its raw magnitude, the same numerical
        # motivation eml-linalg.praat's callers centre for elsewhere.
        .yc# = zero# (.n)
        for .row from 1 to .n
            .yc#[.row] = .y#[.row] - .grandMean
        endfor

        # SS_Error: within-cell squared deviations. SS_Total: squared
        # deviations about the observation-weighted grand mean (equal to
        # inner(.yc#, .yc#), since .yc# is already that deviation) -- NOT
        # the unweighted mean of the cell means, which is the bug in
        # Praat's built-in `Report two-way anova` that this file exists to
        # avoid reproducing.
        .ssError = 0
        for .row from 1 to .n
            .dev = .y#[.row] - .cellMean#[.cellOf#[.row]]
            .ssError = .ssError + .dev * .dev
        endfor
        .ssTotal = inner (.yc#, .yc#)
        .dfError = .n - .rs
        .dfTotal = .n - 1
    endif
endproc


# ============================================================================
# @eml_ak2_designSubset   (private)
# ============================================================================
# Builds a sum-coded (contr.sum) design matrix for one of the five nested
# models this file needs: intercept only; +A; +B; +A+B; the full
# (saturated) model. Column layout: intercept (1 column), then A's r-1
# contrast columns (contrast k: +1 at level k, -1 at level r), then B's s-1
# contrast columns (contrast l: +1 at level l, -1 at level s), then the
# (r-1)(s-1) interaction columns (products of the A and B contrasts). Only
# the block(s) named by .includeA/.includeB/.includeAB are actually built;
# this file only ever calls it with .includeAB = 1 when both .includeA and
# .includeB are also 1.
#
# Output: .x## (.n x p, p depending on which blocks were requested)
# ============================================================================
procedure eml_ak2_designSubset: .n, .r, .s, .aIdx#, .bIdx#, .includeA, .includeB, .includeAB
    .pA = 0
    if .includeA = 1
        .pA = .r - 1
    endif
    .pB = 0
    if .includeB = 1
        .pB = .s - 1
    endif
    .pAB = 0
    if .includeAB = 1
        .pAB = .pA * .pB
    endif
    .p = 1 + .pA + .pB + .pAB
    .x## = zero## (.n, .p)

    for .row from 1 to .n
        .a = .aIdx#[.row]
        .b = .bIdx#[.row]
        .x##[.row, 1] = 1
        .col = 1

        if .includeA = 1
            for .k from 1 to .pA
                .col = .col + 1
                .val = 0
                if .a = .k
                    .val = 1
                elsif .a = .r
                    .val = -1
                endif
                .x##[.row, .col] = .val
            endfor
        endif

        if .includeB = 1
            for .l from 1 to .pB
                .col = .col + 1
                .val = 0
                if .b = .l
                    .val = 1
                elsif .b = .s
                    .val = -1
                endif
                .x##[.row, .col] = .val
            endfor
        endif

        if .includeAB = 1
            for .k from 1 to .pA
                .valA = 0
                if .a = .k
                    .valA = 1
                elsif .a = .r
                    .valA = -1
                endif
                for .l from 1 to .pB
                    .col = .col + 1
                    .valB = 0
                    if .b = .l
                        .valB = 1
                    elsif .b = .s
                        .valB = -1
                    endif
                    .x##[.row, .col] = .valA * .valB
                endfor
            endfor
        endif
    endfor
endproc


# ============================================================================
# @eml_ak2_ols   (private)
# ============================================================================
# Ordinary least squares via the normal equations, solved with `solve#` --
# never an explicit inverse. RSS = y'y - beta'(X'y), which needs only the
# solved beta and the already-computed X'y (no need to form X*beta and
# subtract row by row).
#
# Output: .rss
# ============================================================================
procedure eml_ak2_ols: .x##, .y#
    .xt## = transpose## (.x##)
    .xtx## = mul## (.xt##, .x##)
    .xty# = mul# (.xt##, .y#)
    .beta# = solve# (.xtx##, .xty#)
    .rss = inner (.y#, .y#) - inner (.beta#, .xty#)
endproc


# ============================================================================
# @eml_ak2_buildContrast   (private)
# ============================================================================
# The (r-1) x r simple sum-to-zero contrast matrix for an r-level factor:
# contrast k has +1 at level k, -1 at the reference level r. Any full-rank
# basis of the same (r-1)-dimensional contrast space gives the identical
# Type III SS through @eml_ak2_typeIIIeffect's Wald form (the quadratic
# form is invariant to the choice of basis for L's row space), so this
# particular choice of contrasts is a convenience, not a constraint on the
# result.
#
# Output: .c## ((r-1) x r)
# ============================================================================
procedure eml_ak2_buildContrast: .r
    .k = .r - 1
    .c## = zero## (.k, .r)
    for .i from 1 to .k
        .c##[.i, .i] = 1
        .c##[.i, .r] = -1
    endfor
endproc


# ============================================================================
# @eml_ak2_buildL   (private)
# ============================================================================
# Builds the Type III contrast matrix L for one effect, mapping the r*s
# cell means (row-major: cell (i,j) at column (i-1)*s + j) to the effect's
# contrast space:
#   .isA=1, .isB=0 -> L_A  ((r-1) x rs): row k, column c = C_A[k, i(c)] / s
#                     (the 1/s makes each row of L_A pick out the UNWEIGHTED
#                     row mean's k-th contrast: the average of s cell means,
#                     each cell counted once regardless of n_ij)
#   .isA=0, .isB=1 -> L_B  ((s-1) x rs): row l, column c = C_B[l, j(c)] / r
#   .isA=1, .isB=1 -> L_AB ((r-1)(s-1) x rs): row (k,l), column c =
#                     C_A[k, i(c)] * C_B[l, j(c)]  -- no averaging factor;
#                     the interaction contrast acts on individual cell
#                     means directly.
#
# Output: .l## (k x rs, k depending on which effect was requested)
# ============================================================================
procedure eml_ak2_buildL: .r, .s, .cA##, .cB##, .isA, .isB
    .rs = .r * .s

    if .isA = 1 and .isB = 0
        .k = .r - 1
        .l## = zero## (.k, .rs)
        for .c from 1 to .rs
            .ic = floor ((.c - 1) / .s) + 1
            for .kk from 1 to .k
                .l##[.kk, .c] = .cA##[.kk, .ic] / .s
            endfor
        endfor
    elsif .isA = 0 and .isB = 1
        .k = .s - 1
        .l## = zero## (.k, .rs)
        for .c from 1 to .rs
            .ic = floor ((.c - 1) / .s) + 1
            .jc = .c - (.ic - 1) * .s
            for .kk from 1 to .k
                .l##[.kk, .c] = .cB##[.kk, .jc] / .r
            endfor
        endfor
    else
        .kA = .r - 1
        .kB = .s - 1
        .k = .kA * .kB
        .l## = zero## (.k, .rs)
        for .c from 1 to .rs
            .ic = floor ((.c - 1) / .s) + 1
            .jc = .c - (.ic - 1) * .s
            for .kk from 1 to .kA
                for .ll from 1 to .kB
                    .p = (.kk - 1) * .kB + .ll
                    .l##[.p, .c] = .cA##[.kk, .ic] * .cB##[.ll, .jc]
                endfor
            endfor
        endfor
    endif
endproc


# ============================================================================
# @eml_ak2_typeIIIeffect   (private)
# ============================================================================
# The Wald quadratic form for one Type III effect, per the ruling:
#   Lmu#   = L * mu#                          (mu# = the r*s cell means)
#   LDL'## = L * diag(1/n_ij) * L'            (built directly as weighted
#                                               inner products -- D is
#                                               never formed as a matrix)
#   v#     = solve# (LDL'##, Lmu#)            -- never inverse##
#   SS     = inner (Lmu#, v#)
#
# Arguments: .l## (contrast matrix), .cellMean#, .cellN# (row-major, rs)
# Output: .ss
# ============================================================================
procedure eml_ak2_typeIIIeffect: .l##, .cellMean#, .cellN#
    .k = numberOfRows (.l##)
    .rs = numberOfColumns (.l##)

    .lmu# = mul# (.l##, .cellMean#)

    .ldl## = zero## (.k, .k)
    for .p from 1 to .k
        for .q from .p to .k
            .acc = 0
            for .c from 1 to .rs
                .acc = .acc + .l##[.p, .c] * .l##[.q, .c] / .cellN#[.c]
            endfor
            .ldl##[.p, .q] = .acc
            .ldl##[.q, .p] = .acc
        endfor
    endfor

    .v# = solve# (.ldl##, .lmu#)
    .ss = inner (.lmu#, .v#)
endproc


# ============================================================================
# @emlLeveneTest
# ============================================================================
# Standard Levene's test for homogeneity of variance, median-centred
# (Brown & Forsythe 1974's variant, and the default of R's
# car::leveneTest): for each group, z_i = |value_i - group median|; the
# test statistic is the one-way ANOVA F of z on the grouping.
#
# Arguments:
#   .n         - number of observations
#   .value#    - the data, length .n
#   .groupOf#  - integer group index (1..k) per observation, length .n
#   .k         - number of groups
#
# Output:
#   .w, .p, .dfBetween, .dfWithin, .error$ ("" on success)
# ============================================================================
procedure emlLeveneTest: .n, .value#, .groupOf#, .k
    .error$ = ""
    .w = undefined
    .p = undefined
    .dfBetween = undefined
    .dfWithin = undefined

    if .n < 2
        .error$ = "Levene's test needs at least 2 observations; got "
            ... + string$ (.n) + "."
        goto END_LEVENE
    endif
    if .k < 2
        .error$ = "Levene's test needs at least 2 groups; got "
            ... + string$ (.k) + "."
        goto END_LEVENE
    endif

    .gn# = zero# (.k)
    for .row from 1 to .n
        .g = .groupOf#[.row]
        .gn#[.g] = .gn#[.g] + 1
    endfor
    .anyEmpty = 0
    for .g from 1 to .k
        if .gn#[.g] = 0
            .anyEmpty = 1
        endif
    endfor
    if .anyEmpty = 1
        .error$ = "Levene's test needs every group to be non-empty."
        goto END_LEVENE
    endif

    # per-group value vectors (dynamic names -- Praat's `'`-interpolation
    # of a variable into another variable's name works inside a procedure
    # body), so @emlMedian can be called on each group's own values.
    for .g from 1 to .k
        .gVals'.g'# = zero# (.gn#[.g])
        .fillPos[.g] = 0
    endfor
    for .row from 1 to .n
        .g = .groupOf#[.row]
        .fillPos[.g] = .fillPos[.g] + 1
        .gVals'.g'#[.fillPos[.g]] = .value#[.row]
    endfor

    .gMed# = zero# (.k)
    for .g from 1 to .k
        @emlMedian: .gVals'.g'#
        .gMed#[.g] = emlMedian.result
    endfor

    .z# = zero# (.n)
    .zGroupSum# = zero# (.k)
    for .row from 1 to .n
        .g = .groupOf#[.row]
        .zv = abs (.value#[.row] - .gMed#[.g])
        .z#[.row] = .zv
        .zGroupSum#[.g] = .zGroupSum#[.g] + .zv
    endfor

    .zGrandSum = 0
    for .row from 1 to .n
        .zGrandSum = .zGrandSum + .z#[.row]
    endfor
    .zGrandMean = .zGrandSum / .n

    .zGroupMean# = zero# (.k)
    .ssBetween = 0
    for .g from 1 to .k
        .zGroupMean#[.g] = .zGroupSum#[.g] / .gn#[.g]
        .diffg = .zGroupMean#[.g] - .zGrandMean
        .ssBetween = .ssBetween + .gn#[.g] * .diffg * .diffg
    endfor

    .ssWithin = 0
    for .row from 1 to .n
        .g = .groupOf#[.row]
        .d = .z#[.row] - .zGroupMean#[.g]
        .ssWithin = .ssWithin + .d * .d
    endfor

    .dfBetween = .k - 1
    .dfWithin = .n - .k
    if .dfWithin <= 0
        .error$ = "Levene's test needs within-group degrees of freedom "
            ... + "greater than 0; got " + string$ (.dfWithin) + "."
        goto END_LEVENE
    endif

    .msBetween = .ssBetween / .dfBetween
    .msWithin = .ssWithin / .dfWithin
    if .msWithin <= 0
        .error$ = "Levene's test found zero within-group variance in the "
            ... + "absolute deviations from the group medians; W and p "
            ... + "are undefined."
        goto END_LEVENE
    endif

    .w = .msBetween / .msWithin
    .p = fisherQ (.w, .dfBetween, .dfWithin)

    label END_LEVENE
endproc
