# ============================================================================
# EML Praat Tools — Normal Q-Q plot
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# @emlDrawQQPlot — normal quantile-quantile plot for one numeric vector.
#
# THIS IS AN ADAPTER, NOT A DRAW PROCEDURE. It writes no marks of its own.
# A Q-Q plot IS a scatter plot of sample quantiles against theoretical
# quantiles with a fitted reference line, and @emlDrawScatterPlot already
# draws exactly that — theme, gridlines, adaptive axes, alpha dots, OLS line
# and axis chrome included. Reimplementing any of it here would be a second
# copy of the same figure with its own bugs.
#
# WHERE THE THEORETICAL QUANTILES COME FROM
# -----------------------------------------
# @emlShapiroWilk already computes the Blom normal scores it needs for its
# own coefficients, and leaves them behind as emlShapiroWilk.m# alongside the
# ascending data in emlShapiroWilk.sorted#. This procedure calls it and reads
# those two vectors. They are index-paired: m#[i] is the expected normal
# score of the i-th smallest observation, sorted#[i].
#
#     m#[i] = Phi^-1 ((i - 0.375) / (n + 0.25))          (Blom, a = 3/8)
#
# CONVENTION NOTE — READ THIS BEFORE COMPARING WITH R.
# R's qqnorm() uses ppoints(n), whose `a` is 3/8 only for n <= 10 and 1/2
# for n > 10. So this plot's theoretical axis agrees with qqnorm() EXACTLY
# for n <= 10 and differs from it in the tails for n > 10 (about 0.09 in z
# at n = 30, shrinking towards the middle of the distribution). Blom is used
# here — not chosen for convenience, but because these are the same normal
# scores the reported Shapiro-Wilk W was computed from, so the figure and the
# test on screen beside it cannot disagree about what "expected" means.
# validate/v23_qq_points.R asserts both halves of this: exact agreement with
# qnorm(ppoints(n, a = 3/8)) at every n, and exact agreement with qqnorm()
# itself at n <= 10.
#
# REFUSALS
# --------
# Every refusal is a message in .error$ with .drew = 0 and nothing drawn.
#   * fewer than 3 complete values  — no order statistics to plot
#   * every value identical         — zero range; the plot is a vertical line
#   * more than 5000 values         — @emlShapiroWilk's documented ceiling,
#                                     and the normal scores come from it
# Undefined cells are dropped first and counted in .nDropped, matching what
# @emlRunNormalityAnalysis tested; the count is disclosed in the subtitle so
# a figure drawn from 6 of 8 rows cannot pass for a figure of all 8.
#
# Arguments:
#   .data#      — the column, undefined cells allowed (they are dropped)
#   .colLabel$  — column name, for the title (sanitised here)
#   .vpW, .vpH  — viewport width and height in inches
#   .colorMode$ — "color" or "bw"
#   .gridMode   — 1 both, 2 horizontal, 3 vertical, 4 off
#
# Outputs:
#   .drew       — 1 if a figure was drawn, 0 if refused
#   .error$     — refusal message, "" when .drew = 1
#   .n          — points plotted (complete cases)
#   .nDropped   — undefined cells excluded
#   .slope      — reference-line slope     (undefined when refused)
#   .intercept  — reference-line intercept (undefined when refused)
#   .w, .p      — Shapiro-Wilk W and p for the same points
#
# Requires: @emlShapiroWilk, @emlDrawScatterPlot, @emlSanitizeLabel.
# ============================================================================

procedure emlDrawQQPlot: .data#, .colLabel$, .vpW, .vpH, .colorMode$, .gridMode
    .drew = 0
    .error$ = ""
    .n = 0
    .nDropped = 0
    .slope = undefined
    .intercept = undefined
    .w = undefined
    .p = undefined
    .tmpId = 0

    ; ── Complete cases ────────────────────────────────────────────────────
    ; An undefined element reaching sort# would be sorted to an arbitrary
    ; position and then paired with a normal score belonging to a different
    ; observation, which is a wrong figure rather than a missing one.
    .nIn = size (.data#)
    if .nIn > 0
        .keep# = zero# (.nIn)
        for .i from 1 to .nIn
            if .data# [.i] <> undefined
                .n = .n + 1
                .keep# [.n] = .data# [.i]
            endif
        endfor
    endif
    .nDropped = .nIn - .n

    if .n < 3
        .error$ = "Need at least 3 non-missing values to draw a Q-Q plot "
        ... + "(found " + string$ (.n) + ")."
    endif

    ; ── Normal scores, from the same procedure that tested the column ─────
    if .error$ = ""
        .clean# = zero# (.n)
        for .i from 1 to .n
            .clean# [.i] = .keep# [.i]
        endfor

        @emlShapiroWilk: .clean#
        if emlShapiroWilk.error$ <> ""
            ; Covers zero range and the n > 5000 ceiling. Praat does not
            ; short-circuit, so this is nested rather than ANDed with the
            ; test above: emlShapiroWilk.m# does not exist until a call
            ; has succeeded at least once, and would be STALE — a vector of
            ; the wrong length from a previous column — if this one failed.
            .error$ = emlShapiroWilk.error$
        else
            .w = emlShapiroWilk.w
            .p = emlShapiroWilk.p
        endif
    endif

    if .error$ = ""
        ; ── Drawing globals ───────────────────────────────────────────────
        ; Same self-heal idiom as @emlDrawLMMForest. This procedure is
        ; reachable from a stats wrapper and from a headless harness, neither
        ; of which goes through the graphs form, and Praat aborts on an
        ; undefined global the moment one is read inside an if.
        if variableExists ("emlShowTicksX") = 0
            @emlInitDrawingDefaults
        endif
        if variableExists ("scatterRegressionLine") = 0
            @emlInitDrawingDefaults
        endif

        ; ── Point table ───────────────────────────────────────────────────
        ; Two columns, one row per order statistic. Removed before return.
        .tmpId = Create Table with column names: "eml_qq_points", .n,
        ... "theoretical sample"
        selectObject: .tmpId
        for .i from 1 to .n
            Set numeric value: .i, "theoretical", emlShapiroWilk.m# [.i]
            Set numeric value: .i, "sample", emlShapiroWilk.sorted# [.i]
        endfor

        ; ── Labels ────────────────────────────────────────────────────────
        @emlSanitizeLabel: .colLabel$
        .display$ = emlSanitizeLabel.result$
        .title$ = "Normal Q-Q plot: " + .display$
        .xLabel$ = "Theoretical quantiles (z)"
        .yLabel$ = "Sample quantiles: " + .display$

        ; The dropped-row count belongs ON the figure. A Q-Q of 6 complete
        ; cases out of 8 rows is a different claim from a Q-Q of 8.
        .savedSubtitle$ = ""
        if variableExists ("emlSubtitle$")
            .savedSubtitle$ = emlSubtitle$
        endif
        emlSubtitle$ = "n = " + string$ (.n) + ", Blom plotting positions"
        if .nDropped > 0
            emlSubtitle$ = emlSubtitle$ + "; " + string$ (.nDropped)
            ... + " row(s) excluded as missing"
        endif

        ; ── Draw ──────────────────────────────────────────────────────────
        ; Scatter-plot globals are saved and restored: this procedure is
        ; called from tools that are not the graphs form, and must not leave
        ; the form's settings altered behind it.
        ;
        ; annotate = 0 deliberately. The annotation path reads
        ; scatterAnalysisType, which @emlInitDrawingDefaults does not define
        ; (only the graphs form does), and a Pearson r on a Q-Q plot would
        ; be a second, unlabelled normality statistic competing with the
        ; Shapiro-Wilk the checker already reported.
        .savedReg = scatterRegressionLine
        .savedDots = scatterShowDots
        .savedFormula = scatterShowFormula
        .savedCorr$ = annotCorrType$
        scatterRegressionLine = 1
        scatterShowDots = 1
        scatterShowFormula = 0
        annotCorrType$ = "pearson"

        Erase all
        @emlResetDrawnExtent
        Select outer viewport: 0, .vpW, 0, .vpH
        @emlDrawScatterPlot: .tmpId, .title$, .xLabel$, .yLabel$,
        ... .vpW, .vpH, .colorMode$, .gridMode,
        ... "theoretical", "sample", "", 0, 0, 0, 0, 0

        .slope = emlDrawScatterPlot.slope
        .intercept = emlDrawScatterPlot.intercept

        scatterRegressionLine = .savedReg
        scatterShowDots = .savedDots
        scatterShowFormula = .savedFormula
        annotCorrType$ = .savedCorr$
        emlSubtitle$ = .savedSubtitle$

        ; ── Clean up the temporary Table ──────────────────────────────────
        ; Unconditional. A leaked object survives the figure and turns up in
        ; the user's object list under a name they never created.
        selectObject: .tmpId
        Remove
        .tmpId = 0

        .drew = 1
    endif
endproc
