# ============================================================================
# EML Stats & Graphs — Normal Q-Q plot
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
# @emlRunNormalityAnalysis tested; the count is disclosed so a figure drawn
# from 6 of 8 rows cannot pass for a figure of all 8. See DISCLOSURE below
# for where that count goes and where it deliberately does not.
#
# DISCLOSURE
# ----------
# NOTHING HERE WRITES TO emlSubtitle$. That is the user's own field — the
# graphs form asks for it ("Subtitle") and persists it to config — so a
# machine-generated tail bolted on after " | " is text the user never wrote
# and cannot remove, ticked or not. Saving and restoring the global around
# the call does not help: the global survives and the DRAWN figure carries
# the tail.
#
# The house mechanism is @emlDiscloseBegin / @emlDisclose / @emlDiscloseEnd in
# eml-draw-procedures.praat, which both of this file's include chains already
# pull in (plugin/scripts/eml-lib.praat -> eml-lib-graphs.praat, and
# harness/qq_cases/qq_drive.praat directly). The rule it enforces is "draw
# the image as the image unless someone asks to annotate":
#
#   Info window   ALWAYS
#   The figure    ONLY when the user ticked Annotate
#   emlSubtitle$  NEVER
#
# WHY THE DISCLOSURE RUNS AFTER @emlDrawScatterPlot, NOT BEFORE
# @emlDrawScatterPlot sets annotBlockN = 0 at its Step 7 and renders the block
# itself, so anything added before the call is erased before it can be drawn.
# Adding it afterwards is the same shape eml-graphs-form.praat's POST-DISPATCH
# block already uses for the omnibus line: the panel viewport and the data
# Axes: are still current when the draw procedure returns (@emlDrawTitle
# restores both on its way out), and the axis bounds are read back from
# emlDrawScatterPlot's own locals. With scatterShowFormula = 0 and the
# correlation annotations off, the scatter's block is empty and this is the
# only box on the figure, so no second box is drawn.
#
# THE ANNOTATE THIS GATE READS is the graphs-form global, which is the user's
# tick. It is NOT the .annotate = 0 this procedure passes to
# @emlDrawScatterPlot — that argument suppresses a Pearson r on a Q-Q plot for
# a different reason, given at the call site, and has nothing to say about
# whether the user asked to see how the figure was built.
#
# WHAT IS DISCLOSED, AND WHAT WAS DROPPED
#   "n = N, Blom plotting positions (a = 3/8)."  KEPT. n is not on either
#     axis and it is not countable off the panel — the dots are drawn with
#     alpha and overlap — yet it is the number that decides how much tail
#     wiggle a reader should forgive, and it is the parameter of the plotting
#     formula named in the same breath. The a = 3/8 is load-bearing rather
#     than pedantry: R's qqnorm() uses a = 1/2 above n = 10, so a reader
#     laying this figure beside qqnorm() output and finding the tails moved
#     would otherwise conclude the plugin is wrong. validate/v23_qq_points.R
#     asserts that difference deliberately.
#   the derivation and the qqnorm() comparison  Info window only, via the
#     .advice$ channel. It is a paragraph, not a caption.
#   the dropped-row count  KEPT, in the house wording used by every other
#     draw procedure ("N row(s) ...").
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

        ; ── The plotted pairs, snapshotted ────────────────────────────────
        ; Copied out of @emlShapiroWilk's vectors before anything else runs,
        ; so the quadrant count that chooses the disclosure corner after the
        ; draw is computed from the points this figure was built from and not
        ; from whatever happens to be in emlShapiroWilk.m# by then.
        .theo# = zero# (.n)
        .samp# = zero# (.n)
        for .i from 1 to .n
            .theo# [.i] = emlShapiroWilk.m# [.i]
            .samp# [.i] = emlShapiroWilk.sorted# [.i]
        endfor

        ; ── Point table ───────────────────────────────────────────────────
        ; Two columns, one row per order statistic. Removed before return.
        .tmpId = Create Table with column names: "eml_qq_points", .n,
        ... "theoretical sample"
        selectObject: .tmpId
        for .i from 1 to .n
            Set numeric value: .i, "theoretical", .theo# [.i]
            Set numeric value: .i, "sample", .samp# [.i]
        endfor

        ; ── Labels ────────────────────────────────────────────────────────
        @emlSanitizeLabel: .colLabel$
        .display$ = emlSanitizeLabel.result$
        .title$ = "Normal Q-Q plot: " + .display$
        .xLabel$ = "Theoretical quantiles (z)"
        .yLabel$ = "Sample quantiles: " + .display$

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

        ; ── Disclosure ────────────────────────────────────────────────────
        ; See DISCLOSURE in the header. Info window always, the figure only
        ; when the user ticked Annotate, the user's subtitle never.
        @emlDiscloseBegin: "Normal Q-Q plot"
        @emlDisclose: "n = " + string$ (.n)
        ... + ", Blom plotting positions (a = 3/8).",
        ... "Theoretical quantiles are qnorm ((i - 0.375) / (n + 0.25)) "
        ... + "- the same normal scores the reported Shapiro-Wilk W was "
        ... + "computed from, so the figure and the test cannot disagree "
        ... + "about which quantiles are expected. R's qqnorm() uses "
        ... + "a = 1/2 above n = 10, so its tails sit slightly wider than "
        ... + "this axis."
        if .nDropped > 0
            @emlDisclose: string$ (.nDropped)
            ... + " row(s) excluded as missing.",
            ... "Plotted from the " + string$ (.n) + " complete value(s). "
            ... + "The Shapiro-Wilk reported beside this figure used the "
            ... + "same ones."
        endif

        ; The corner. A Q-Q plot's points lie along a rising diagonal, so
        ; the top-left and bottom-right quadrants are the empty ones and
        ; @emlPlaceElements has somewhere clean to put the box. Counting is
        ; done here, on the snapshotted pairs, against the midpoints of the
        ; axis bounds @emlDrawScatterPlot actually used — the same currency
        ; the scatter plot itself hands @emlPlaceElements. No legend is
        ; drawn on this figure (the scatter is ungrouped), hence the "".
        .axXMin = emlDrawScatterPlot.axisXMin
        .axXMax = emlDrawScatterPlot.axisXMax
        .axYMin = emlDrawScatterPlot.axisYMin
        .axYMax = emlDrawScatterPlot.axisYMax
        .xMidQ = (.axXMin + .axXMax) / 2
        .yMidQ = (.axYMin + .axYMax) / 2
        .qTL = 0
        .qTR = 0
        .qBL = 0
        .qBR = 0
        for .i from 1 to .n
            if .samp# [.i] >= .yMidQ
                if .theo# [.i] < .xMidQ
                    .qTL = .qTL + 1
                else
                    .qTR = .qTR + 1
                endif
            else
                if .theo# [.i] < .xMidQ
                    .qBL = .qBL + 1
                else
                    .qBR = .qBR + 1
                endif
            endif
        endfor
        @emlDiscloseEnd: .axXMin, .axXMax, .axYMin, .axYMax,
        ... .qTL, .qTR, .qBL, .qBR, ""

        ; The published resolved extent, so a caller of THIS procedure does
        ; not have to know it wrapped a scatter. Same contract as every
        ; emlDraw* procedure -- see @emlDrawTimeSeries.
        ;
        ; Published INSIDE the drew-a-figure branch, deliberately. On the
        ; error path (fewer than three complete values, or a failed
        ; Shapiro-Wilk) no axes exist, and a caller reading these would get
        ; `Unknown variable:` rather than a stale extent from whatever was
        ; drawn last. .drew is the flag to test first.
        .axisXMin = .axXMin
        .axisXMax = .axXMax
        .axisYMin = .axYMin
        .axisYMax = .axYMax

        scatterRegressionLine = .savedReg
        scatterShowDots = .savedDots
        scatterShowFormula = .savedFormula
        annotCorrType$ = .savedCorr$

        ; ── Clean up the temporary Table ──────────────────────────────────
        ; Unconditional. A leaked object survives the figure and turns up in
        ; the user's object list under a name they never created.
        selectObject: .tmpId
        Remove
        .tmpId = 0

        .drew = 1
    endif
endproc
