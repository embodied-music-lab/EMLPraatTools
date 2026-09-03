# ============================================================================
# EML GRAPHS — ANNOTATION + STATS BRIDGE PROCEDURES
# ============================================================================
# Author: Ian Howell, Embodied Music Lab, www.embodiedmusiclab.com
# Development: Claude (Anthropic)
# Part of EML PraatGen GPL-3.0-or-later — Ian Howell, Embodied Music Lab
# Version: 3.22
# Date: 9 August 2026
#
#
# Annotation drawing procedures and bridge layer connecting EML Stats
# results to annotated EML Graphs figures. Provides bracket annotations
# (pairwise comparisons), free-text annotations (omnibus stats), and
# regression line overlays.
#
# Include chain:
#   eml-graphs.praat includes this file AFTER eml-graph-procedures.praat
#   and AFTER all stats library files. This file calls stats procedures
#   and uses drawing procedures from eml-graph-procedures.praat.
#
# Architecture:
#   - Global parallel arrays carry annotation data between bridge
#     procedures (which populate them) and drawing procedures (which
#     render them). Same pattern as legendN/legendColor$/legendLabel$.
#   - Bridge procedures run the appropriate statistical test, then
#     populate the annotation arrays. The main script orchestrates:
#     bridge -> stack -> draw data -> draw annotations -> draw axes.
#
# Procedures (all 27, in file order — the list is complete, including
# @emlOppositeCorner, @emlDrawAnnotationBlock, @emlDrawMatrixPanel and every
# shared reporter):
#   @emlClearAnnotations         — reset all annotation arrays
#   @emlFormatStars              — p-value to star notation
#   @emlFormatAnnotLabel         — format bracket label from p, d, style
#   @emlStackBrackets            — assign vertical tiers to brackets
#   @emlDrawBracket              — render one significance bracket
#   @emlDrawBracketCaption       — render the post-hoc/correction caption
#                                  under the frame (bracket layout only)
#   @emlDrawAnnotation           — render positioned text box
#   @emlDrawAnnotations          — umbrella: draw all annotations
#   @emlDrawRegressionLine       — render regression line on scatter plot
#   @emlPlaceElements            — pick best corners for legend + annotation block
#   @emlComputeAnnotationHeadroom — compute extra y-space for brackets AND
#                                  for a legend drawn inside the plot
#   @emlOppositeCorner           — diagonally opposite corner name
#   @emlSpaceCount               — spaces in a string (word counting helper)
#   @emlDrawAnnotationBlock      — render the multi-line corner text box
#   @emlMeasureMatrixLayout      — measure matrix panel geometry (rotate, truncate, stack)
#   @emlDrawMatrixPanel          — render the comparison matrix panel
#   @emlRunAnnotationComparison    — run group test, populate brackets
#   @emlBridgeCorrelation        — run correlation, populate regression (UNUSED)
#   @emlReportBridgeStats        — thin dispatcher: graphs tool → shared reporter
#   @emlReportTwoGroupComparison — shared reporter: two-group comparison
#   @emlReportAnovaComparison    — shared reporter: one-way ANOVA
#   @emlReportKWComparison       — shared reporter: Kruskal-Wallis
#   @emlReportCorrelationAnalysis — shared reporter: correlation
#   @emlReportRegressionAnalysis — shared reporter: regression
#   @emlReportNormalityAnalysis  — shared reporter: normality
#   @emlReportPairedComparison   — shared reporter: paired comparison
#   @emlReportTwoWayAnova        — shared reporter: two-way ANOVA
# ============================================================================


# ============================================================================
# ANNOTATION DATA STRUCTURES (global parallel arrays)
# ============================================================================
#
# These globals are set by bridge procedures, consumed by drawing
# procedures. They must be initialized before each draw cycle via
# @emlClearAnnotations.
#
# Bracket annotations (group comparisons):
#   annotBracketN                — number of brackets to draw
#   annotBracketI[1..N]          — left group index (1-based)
#   annotBracketJ[1..N]          — right group index (1-based)
#   annotBracketP[1..N]          — p-value
#   annotBracketD[1..N]          — effect size (Cohen's d, r, or epsilon2)
#   annotBracketLabel$[1..N]     — display text
#   annotBracketTier[1..N]       — y-tier assigned by @emlStackBrackets
#   annotBracketPosthoc$         — pairwise test that produced the bracket
#                                  p-values ("Pairwise comparisons: Tukey
#                                  HSD", "Pairwise comparisons: Dunn's test").
#                                  "" on the two-group arms and whenever no
#                                  post-hoc ran.
#   annotBracketAdjust$          — what was done about multiplicity, in the
#                                  same two-arm split the matrix sub-line
#                                  carries: "already family-wise; no further
#                                  adjustment applied" on the Tukey arm,
#                                  "adjustment for multiple comparisons:
#                                  holm" on the Dunn arm, with the token the
#                                  user actually chose. Drawn as one caption
#                                  under the frame by @emlDrawBracketCaption,
#                                  which joins the two halves with an em-dash
#                                  and breaks them onto two lines at that seam
#                                  when one line will not fit.
#
# Free-text annotations (omnibus stats, correlation):
#   annotTextN                   — number of text boxes
#   annotTextX[1..N]             — x position (data coordinates)
#   annotTextY[1..N]             — y position (data coordinates)
#   annotTextLabel$[1..N]        — display text
#   annotTextAnchor$[1..N]       — alignment: "left", "centre", "right"
#
# Regression line (correlation):
#   annotRegressionN             — 0 or 1
#   annotRegressionSlope         — slope
#   annotRegressionIntercept     — intercept
#   annotRegressionR             — Pearson r (or Spearman rho)
#   annotRegressionP             — p-value
#   annotRegressionLabel$        — display label
#
# Format options (set from dialog):
#   annotStyle$                  — "p-value", "stars", "both"
#   annotAlpha                   — significance threshold
#   annotShowNS                  — 0 or 1
#   annotShowEffect              — 0 or 1
#   annotMatrixPosthoc$          — test name for subtitle/report
#                                  ("Welch t-test", "Mann-Whitney U",
#                                  "Tukey HSD", "Dunn's test (holm)")
#   annotCorrectionMethod$       — p-value correction for Dunn's test
#                                  (default "holm", set by stats callers)
#   annotPostHoc                 — ITEM 3.5. 1 = run the pairwise post-hoc,
#                                  0 = omnibus only. The Comparison menu's
#                                  own row, committed by the six
#                                  column-mapping pages in
#                                  graphs/eml-graphs-form.praat. Absent in a
#                                  tree that never opened that form, and
#                                  every read of it defaults to 1.
#
# Multi-line annotation block (scatter stats + formula):
#   annotBlockN                  — number of lines in block
#   annotBlockLabel$[1..N]       — line text, raw (no Picture markup)
#   annotBlockDraw$[1..N]        — Picture-window version (with markup)
#
#   N is capped at 20 by @emlDisclose (eml-draw-procedures.praat), but that
#   is a cap on DISCLOSURES, not on the array: the graphs form appends its
#   omnibus line afterwards, so 21 is reachable on the form path. The number
#   of lines actually DRAWN is larger again — @emlDrawAnnotationBlock wraps
#   each entry to the frame and renders the segments, so a 5-entry block can
#   render as a dozen lines.
# ============================================================================


# ----------------------------------------------------------------------------
# @emlClearAnnotations
# Reset all annotation arrays to empty state. Call at the top of each
# draw cycle before bridge procedures.
# ----------------------------------------------------------------------------
procedure emlClearAnnotations
    annotBracketN = 0
    # The bracket caption. Cleared here beside the count it travels with, so a
    # figure whose bridge never reached a post-hoc cannot inherit the previous
    # figure's sentence — the failure the matrix labels above are cleared for,
    # in a string that would be read as a claim about the statistics.
    annotBracketPosthoc$ = ""
    annotBracketAdjust$ = ""
    annotTextN = 0
    annotBlockN = 0
    annotRegressionN = 0
    annotRegressionSlope = 0
    annotRegressionIntercept = 0
    annotRegressionR = 0
    annotRegressionP = 0
    annotRegressionLabel$ = ""
    # Comparison matrix
    # annotMatrixLabel$[] is written 1..annotMatrixN by every matrix writer
    # (and truncated/sanitized in place by @emlMeasureMatrixLayout), so the
    # PREVIOUS figure's annotMatrixN bounds the range that can hold stale
    # labels. Clear that range before resetting the count.
    .priorMatrixN = 0
    if variableExists ("annotMatrixN")
        .priorMatrixN = annotMatrixN
    endif
    if .priorMatrixN <> undefined
        for .i from 1 to .priorMatrixN
            annotMatrixLabel$[.i] = ""
        endfor
    endif
    annotMatrixN = 0
    annotMatrixOmnibus$ = ""
    annotMatrixEffectLabel$ = ""
    annotMatrixPosthoc$ = ""
    emlMatrixLayout_pLegend$ = "p < .05"
endproc


# ----------------------------------------------------------------------------
# @emlFormatStars
# Convert p-value to star notation.
#
# Thresholds are driven by the global annotAlpha rather than hardcoded, so
# the star display always matches the alpha the user selected. The
# conventional three-tier ladder is scaled from alpha as
#   *   p < alpha
#   **  p < alpha / 5
#   *** p < alpha / 50
# which reproduces the familiar .05 / .01 / .001 ladder exactly at the
# default alpha = 0.05. If annotAlpha is unset, undefined, or non-positive,
# 0.05 is used.
#
# Arguments: .p (p-value; may be undefined)
# Output:
#   .result$  — "***", "**", "*", "n.s.", or "n/a" when .p is undefined
#   .legend$  — human-readable statement of the thresholds actually used,
#               e.g. "* p < .05  ** p < .01  *** p < .001"
#   .alpha    — the alpha that was applied
#   .t1/.t2/.t3 — the three thresholds (largest to smallest)
# ----------------------------------------------------------------------------
procedure emlFormatStars: .p
    .alpha = 0.05
    if variableExists ("annotAlpha")
        if annotAlpha <> undefined
            if annotAlpha > 0
                .alpha = annotAlpha
            endif
        endif
    endif
    .t1 = .alpha
    .t2 = .alpha / 5
    .t3 = .alpha / 50

    # Build the legend describing the ladder actually in force
    .thr# = { .t1, .t2, .t3 }
    .legend$ = ""
    .starRun$ = ""
    for .k from 1 to 3
        .tv = .thr#[.k]
        if .tv < 0.001
            .tt$ = fixed$ (.tv, 4)
        elsif .tv < 0.01
            .tt$ = fixed$ (.tv, 3)
        else
            .tt$ = fixed$ (.tv, 2)
        endif
        .tt$ = replace$ (.tt$, "0.", ".", 1)
        .starRun$ = .starRun$ + "*"
        if .k > 1
            .legend$ = .legend$ + "  "
        endif
        .legend$ = .legend$ + .starRun$ + " p < " + .tt$
    endfor

    if .p <> undefined
        if .p < .t3
            .result$ = "***"
        elsif .p < .t2
            .result$ = "**"
        elsif .p < .t1
            .result$ = "*"
        else
            .result$ = "n.s."
        endif
    else
        # Undefined p is NOT the same as non-significant — say so explicitly
        # rather than falling through to "n.s.".
        .result$ = "n/a"
    endif
endproc


# ----------------------------------------------------------------------------
# @emlCIAlphaInForce
# The alpha every confidence interval in this module is built at.
#
# ONE ANSWER, SO THE FIGURE AND ITS REPORT CANNOT DISAGREE. The stars, the
# error bars, the mean intervals and every bracket a report prints all read
# the alpha the user set on the graph dialog, and they read it from here, so
# a figure cannot carry a 99% error bar beside a 95% correlation band.
#
# annotAlpha is a graphs-layer global and an API or headless caller can reach
# these reporters without one, so the guard is the same shape @emlFormatStars
# uses and falls back to the same documented default of 0.05. A value outside
# the open interval (0, 1) is refused for the same reason: invStudentQ (0, df)
# never converges and invGaussQ is undefined above 1, so a quantile taken
# from one is a hang or a garbage bracket rather than a wrong number.
#
# Arguments: none (reads the global)
# Output:
#   .alpha  — the two-sided tail probability in force, strictly in (0, 1)
# ----------------------------------------------------------------------------
procedure emlCIAlphaInForce
    .alpha = 0.05
    if variableExists ("annotAlpha")
        if annotAlpha <> undefined
            if annotAlpha > 0 and annotAlpha < 1
                .alpha = annotAlpha
            endif
        endif
    endif
endproc


# ----------------------------------------------------------------------------
# @emlFormatAnnotLabel
# Format the display label for a bracket annotation.
#
# THE EFFECT SIZE IS PRINTED AS A MAGNITUDE, and the reason is that a bracket
# is the figure's COMPACT surface. A signed effect size is readable only
# beside a statement of which member of the pair the subtraction starts from;
# the bracket has room for the number and not for the sentence. The sign here
# is always left member minus right member, because the bridge only ever
# builds a bracket with annotBracketI < annotBracketJ and the groups draw left
# to right -- but that is a rule the reader would have to arrive already
# knowing, and it moves with the group ordering setting, since table order is
# the default and the left group is therefore whichever one the spreadsheet
# lists first. So the compact surface carries |d| and the Info report carries
# the signed value under a line naming the subtraction.
#
# @emlDrawMatrixPanel treats its lower triangle the same way, to two decimals
# through fixed$, and says "(magnitude)" in its subtitle; a bracket names its
# quantity inline instead, "d = 0.83" beside its p.
#
# Arguments: .p, .d, .style$, .showEffect, .effectLabel$
#   .p            — p-value
#   .d            — effect size value (Cohen's d, rank-biserial r, etc.);
#                   printed as its magnitude, sign discarded
#   .style$       — "p-value", "stars", or "both"
#   .showEffect   — 0 or 1
#   .effectLabel$ — symbol to display (e.g., "d", "r", "ε²")
# Output: .result$
# ----------------------------------------------------------------------------
procedure emlFormatAnnotLabel: .p, .d, .style$, .showEffect, .effectLabel$
    .result$ = ""

    if .style$ = "stars"
        @emlFormatStars: .p
        .result$ = emlFormatStars.result$
    elsif .style$ = "both"
        @emlFormatStars: .p
        @emlFormatP: .p
        .stars$ = emlFormatStars.result$
        .pText$ = emlFormatP.formatted$
        .result$ = .stars$ + " (" + .pText$ + ")"
    else
        # Default: p-value
        @emlFormatP: .p
        .result$ = emlFormatP.formatted$
    endif

    if .showEffect = 1 and .d <> undefined
        ; abs, and two decimals through fixed$: the same treatment
        ; @emlDrawMatrixPanel gives the effect size in its lower triangle, so
        ; the two annotation layouts of one comparison print one number.
        .dText$ = fixed$ (abs (.d), 2)
        .result$ = .result$ + ", " + .effectLabel$ + " = " + .dText$
    endif
endproc


# ----------------------------------------------------------------------------
# @emlStackBrackets
# Assign vertical tier to each bracket so none overlap.
# Algorithm: greedy, narrowest-first.
#   1. Compute span = |groupJ - groupI| for each bracket
#   2. Process brackets in ascending span order
#   3. For each bracket, find lowest tier where it does not overlap
#      any already-placed bracket
#   "Overlap" = two brackets share any x-range AND same tier
#
# Input: reads annotBracketN, annotBracketI[], annotBracketJ[]
# Output: writes annotBracketTier[1..N] (1-based, 1 = lowest)
# No arguments — reads/writes global annotBracket* arrays.
# ----------------------------------------------------------------------------
procedure emlStackBrackets
    if annotBracketN = 0
        # Nothing to do
    elsif annotBracketN = 1
        annotBracketTier[1] = 1
    else
        # Compute spans and build sort index
        for .b from 1 to annotBracketN
            .span[.b] = abs (annotBracketJ[.b] - annotBracketI[.b])
            .order[.b] = .b
            annotBracketTier[.b] = 0
        endfor

        # Insertion sort by span ascending (max 45 pairs for 10 groups)
        for .i from 2 to annotBracketN
            .keyIdx = .order[.i]
            .keySpan = .span[.keyIdx]
            .j = .i - 1
            .sorting = 1
            while .j >= 1 and .sorting = 1
                if .span[.order[.j]] > .keySpan
                    .order[.j + 1] = .order[.j]
                    .j = .j - 1
                else
                    .sorting = 0
                endif
            endwhile
            .order[.j + 1] = .keyIdx
        endfor

        # Assign tiers in span order (narrowest first)
        for .s from 1 to annotBracketN
            .b = .order[.s]
            .bLeft = min (annotBracketI[.b], annotBracketJ[.b])
            .bRight = max (annotBracketI[.b], annotBracketJ[.b])

            .tier = 1
            .placed = 0
            while .placed = 0
                .conflict = 0
                # Check all already-placed brackets at this tier
                for .c from 1 to annotBracketN
                    if annotBracketTier[.c] = .tier and .c <> .b
                        .cLeft = min (annotBracketI[.c], annotBracketJ[.c])
                        .cRight = max (annotBracketI[.c], annotBracketJ[.c])
                        # Overlap: ranges share x-space
                        if .bLeft <= .cRight and .bRight >= .cLeft
                            .conflict = 1
                        endif
                    endif
                endfor
                if .conflict = 0
                    annotBracketTier[.b] = .tier
                    .placed = 1
                else
                    .tier = .tier + 1
                endif
            endwhile
        endfor
    endif
endproc


# ----------------------------------------------------------------------------
# @emlDrawBracket
# Render one significance bracket in the current axes.
#
# Geometry:
#        label$
#   ┌──────────────────────────────┐
#   |                              |
# groupI                         groupJ
#
# Three segments: left descender, horizontal bar, right descender.
# Centered text above the horizontal bar.
#
# Arguments:
#   .xI         — x-position of left group (data coordinates)
#   .xJ         — x-position of right group (data coordinates)
#   .yBase      — y-position of lowest bracket tier
#   .tierHeight — vertical spacing between tiers (data coordinates)
#   .tier       — which tier (1-based)
#   .label$     — text to display above bracket
#   .fontSize   — text size for label
#   .lineColor$ — RGB colour string for bracket lines
# ----------------------------------------------------------------------------
procedure emlDrawBracket: .xI, .xJ, .yBase, .tierHeight, .tier, .label$, .fontSize, .lineColor$
    .yBar = .yBase + (.tier - 1) * .tierHeight + .tierHeight * 0.5
    .descenderLen = .tierHeight * 0.3
    .yBottom = .yBar - .descenderLen
    .yText = .yBar + .tierHeight * 0.15

    Colour: .lineColor$
    Line width: 1.0

    # Left descender
    Draw line: .xI, .yBottom, .xI, .yBar
    # Horizontal bar
    Draw line: .xI, .yBar, .xJ, .yBar
    # Right descender
    Draw line: .xJ, .yBottom, .xJ, .yBar

    # Label centered above bar
    .xMid = (.xI + .xJ) / 2
    ; THE SIZE TRAVELS WITH THE TEXT, NOT WITH THE PICTURE WINDOW.
    ; `Font size:` followed by `Text:` left the annotation size ambient on
    ; return, and this procedure is called in a LOOP (@emlDrawAnnotations).
    ; So bracket 1 drew its three `Draw line:` bars above at the caller's
    ; bodySize and brackets 2..n drew theirs at the size bracket 1 left
    ; behind -- one figure, two rectangles, about 2.9% apart per point of
    ; difference. `Text special:` carries its size as an argument and touches
    ; no ambient state, so every bracket on the figure, bar and label alike,
    ; is converted through the margins the caller selected the viewport with.
    Colour: "{0.1, 0.1, 0.1}"
    Text special: .xMid, "centre", .yText, "bottom",
    ... emlFont$, .fontSize, "0", .label$

    Colour: "Black"
endproc


# ----------------------------------------------------------------------------
# @emlDrawBracketCaption
# Render the post-hoc/correction caption for a bracket-layout figure, as a
# band immediately under the frame.
#
# WHY THE FIGURE CARRIES THIS AT ALL — see v3.22 in the file header for the
# full statement. The Info-window report says it too ("-- Dunn's Post-Hoc
# (adjusted p, holm) --"), so nothing is hidden from someone reading the
# report. But the figure is the artefact that leaves the session, into a slide
# or a paper or a supervision, and the reader looking at it has no report
# beside them.
#
# WHY A BAND UNDER THE FRAME AND NOT A BOX INSIDE IT. The inside of the frame
# has one free-text slot, annotTextX/annotTextY, it already carries the
# omnibus line, and it is drawn with an alpha background — so a second box
# would have to be placed by @emlPlaceElements, which scores the top quadrants
# DOWN precisely because brackets live there. A caption describing the
# brackets that lands on the brackets is worse than no caption. The band takes
# its own strip below emlSetAdaptiveTheme.outerBottom and reports the strip to
# @emlExpandDrawnExtent, which is how @emlDrawMatrixPanel already gets a panel
# into the saved image: @emlAssertFullViewport unions everything reported and
# the export grows to fit rather than cropping.
#
# WHAT AN OVERRUN LOOKS LIKE, and it is not the failure people reach for. A
# caption too wide for the canvas does not raise, does not blank the figure
# and does not move the plot. It renders, and its tail is simply not in the
# file — "adjustment for multiple comparisons: bonf" with the rest outside the
# image. The words that survive are the ones at the START of the line, so a
# check anchored on where the first ink falls sees a caption in exactly the
# right place; the position it reads moves the WRONG WAY for the thing it
# would be trying to catch. That is why this procedure
# measures with Text width (mm) against the room it actually has, scales to a
# 5 pt floor, and breaks onto two lines at the seam between the two stored
# halves rather than trusting a character count — and why it leaves .widthMM
# and .availMM behind for a harness to read.
#
# THE HALVES ARE NOT JOINED BY THIS PROCEDURE BY ACCIDENT. @emlRunAnnotationComparison
# stores the test and the adjustment clause separately. Joining them here
# means the wrap point is a seam that already exists in the data, so the
# two-line form never splits a word or a clause, and it means the two arms'
# claims can be compared as values rather than as substrings of one sentence.
#
# Arguments:
#   .fontSize   — the annotation type size to start from (shrunk to fit)
#   .axXMin, .axXMax, .axYMin, .axYMax
#               — the axes the CALLER has installed, carried in only so this
#                 procedure can put the world back. It changes the viewport,
#                 so it must restore it exactly as @emlDrawAnnotation does
#                 after the sprite path.
#
# Outputs (read by harness/bracketcap, asserted by validate/v69):
#   .drawn      — 1 if a caption was rendered, 0 if there was nothing to say
#   .lines      — 1 or 2
#   .size       — the point size finally used
#   .widthMM    — the widest rendered line, in mm
#   .availMM    — the room it had, in mm. .widthMM <= .availMM is the fit.
#   .text1$, .text2$ — exactly what was drawn, line by line
#   .top, .bottom    — the band, in inches, as reported to the extent tracker
# ----------------------------------------------------------------------------
procedure emlDrawBracketCaption: .fontSize, .axXMin, .axXMax, .axYMin, .axYMax
    .drawn = 0
    .lines = 0
    .size = .fontSize
    .widthMM = 0
    .availMM = 0
    .text1$ = ""
    .text2$ = ""
    .top = 0
    .bottom = 0

    ; variableExists, not a bare read: this procedure is reachable from an
    ; emitted replay script and from a PraatGen companion file, neither of
    ; which is obliged to have run @emlClearAnnotations first, and an
    ; undefined global aborts the figure at the comparison rather than
    ; skipping a caption.
    if variableExists ("annotBracketPosthoc$") = 0
        goto END_CAPTION
    endif
    if variableExists ("annotBracketAdjust$") = 0
        goto END_CAPTION
    endif
    if annotBracketPosthoc$ = "" or annotBracketAdjust$ = ""
        goto END_CAPTION
    endif

    .left = emlSetAdaptiveTheme.outerLeft
    .right = emlSetAdaptiveTheme.outerRight
    .top = emlSetAdaptiveTheme.outerBottom
    .sf = emlSetAdaptiveTheme.spacingFactor
    .padInch = (.fontSize / 72) * (0.6 + 0.4 * .sf)
    .availMM = (.right - .left - 2 * .padInch) * 25.4

    .joined$ = annotBracketPosthoc$ + " — " + annotBracketAdjust$

    ; A provisional band, so the measurement happens with a viewport selected
    ; and a font installed. Text width (mm) is a physical measure and does not
    ; depend on the axes, but it does depend on the font size that is actually
    ; set, so every measurement below is preceded by its own Font size.
    .bottom = .top + (.fontSize / 72) * 3
    Select outer viewport: .left, .right, .top, .bottom
    Select inner viewport: .left, .right, .top, .bottom

    .lines = 1
    .text1$ = .joined$
    Font size: .fontSize
    .widthMM = Text width (mm): .text1$
    if .widthMM > .availMM
        ; Proportional first guess, then re-measured. Praat's metrics are not
        ; exactly linear in point size, so the scale factor is a starting
        ; point and the second measurement is the one that decides.
        .size = .fontSize * .availMM / .widthMM
        if .size < 5
            .size = 5
        endif
        Font size: .size
        .widthMM = Text width (mm): .text1$
    endif

    if .widthMM > .availMM
        ; Still over at the legibility floor. Break at the seam between the
        ; two halves the bridge stored — the em-dash stays with the test name
        ; so the second line opens on the adjustment clause.
        .lines = 2
        .text1$ = annotBracketPosthoc$ + " —"
        .text2$ = annotBracketAdjust$
        .size = .fontSize
        Font size: .size
        .w1 = Text width (mm): .text1$
        .w2 = Text width (mm): .text2$
        .widthMM = max (.w1, .w2)
        if .widthMM > .availMM
            .size = .fontSize * .availMM / .widthMM
            if .size < 5
                .size = 5
            endif
            Font size: .size
            .w1 = Text width (mm): .text1$
            .w2 = Text width (mm): .text2$
            .widthMM = max (.w1, .w2)
        endif
    endif

    .lineInch = (.size / 72) * 1.45
    .gapInch = (.size / 72) * (0.35 + 0.25 * .sf)
    .bandH = .gapInch * 1.5 + .lines * .lineInch
    .bottom = .top + .bandH

    Select outer viewport: .left, .right, .top, .bottom
    Select inner viewport: .left, .right, .top, .bottom
    ; y grows downward, as in @emlDrawMatrixPanel, so line 1 is the smaller y.
    Axes: 0, .right - .left, .bandH, 0

    ; The contrast rule governs this colour for the same reason it governs
    ; the matrix sub-line: this is the only place in a bracket figure that
    ; discloses the correction. {0.40, 0.40, 0.40} is 5.74:1 against white
    ; (WCAG 2.x relative luminance, sRGB), above the 4.5:1 minimum for normal
    ; text and still clearly subordinate to the figure. Do not lighten past
    ; 0.46 (= 4.5:1) on a white ground.
    Colour: "{0.40, 0.40, 0.40}"
    .cx = (.right - .left) / 2
    .y1 = .gapInch + .lineInch * 0.5
    Text special: .cx, "centre", .y1, "half", emlFont$, .size, "0", .text1$
    if .lines = 2
        Text special: .cx, "centre", .y1 + .lineInch, "half",
        ... emlFont$, .size, "0", .text2$
    endif

    ; Without this the caption is drawn and then cropped off the export, which
    ; is indistinguishable from never having drawn it.
    @emlExpandDrawnExtent: .left, .right, .top, .bottom
    .drawn = 1

    ; Put the world back exactly as @emlDrawAnnotation does after the sprite
    ; path. Everything the caller draws after this — the axes, the omnibus
    ; block — is drawn in the axes it installed, not in this band's.
    @emlSetPanelViewport
    Axes: .axXMin, .axXMax, .axYMin, .axYMax
    Font size: emlSetAdaptiveTheme.bodySize
    Colour: "Black"
    Line width: 1.0

    label END_CAPTION
endproc


# ----------------------------------------------------------------------------
# @emlDrawAnnotation
# Render a free-positioned text box with optional background fill.
# For omnibus stats, correlation results, etc.
#
# Arguments:
#   .x        — x position (data coordinates)
#   .y        — y position (data coordinates)
#   .anchor$  — alignment: "left", "centre", "right"
#   .label$   — text to display
#   .fontSize — text size
#   .hasBg    — 1 = draw white background rectangle, 0 = text only
#   .xRange   — x-axis range (for text box width estimation)
#   .yRange   — y-axis range (for text box height estimation)
# ----------------------------------------------------------------------------
; .axXMin/.axXMax/.axYMin/.axYMax are the axes CURRENTLY INSTALLED by the
; caller, carried in purely so this procedure can put the world back after
; @emlPaintAlphaBox takes the sprite path -- `Insert picture from file:`
; leaves the viewport on the image's own bounding box. They are deliberately
; NOT used for any arithmetic: .xRange and .yRange stay the source of truth
; for .wpiX/.wpiY, because the form derives annotYRange from valueMax-valueMin
; while annotYMin/annotYMax can be overridden per graph type, so the two can
; legitimately disagree and substituting one for the other would move text.
procedure emlDrawAnnotation: .x, .y, .anchor$, .label$, .fontSize, .hasBg, .xRange, .yRange, .axXMin, .axXMax, .axYMin, .axYMax
    if .hasBg = 1
        # Measure actual rendered width (exact, font-aware)
        Font size: .fontSize
        .textW = Text width (world coordinates): .label$
        # Safety margin: screen font metrics differ slightly from PNG export
        .textW = .textW * 1.05

        # Font-size-based spacing via world-per-inch
        .innerW = emlSetAdaptiveTheme.innerRight - emlSetAdaptiveTheme.innerLeft
        .innerH = emlSetAdaptiveTheme.innerBottom - emlSetAdaptiveTheme.innerTop
        .wpiX = .xRange / .innerW
        .wpiY = .yRange / .innerH
        .fontInch = .fontSize / 72
        .sf = emlSetAdaptiveTheme.spacingFactor
        .padX = .fontInch * (0.2 + 0.2 * .sf) * .wpiX
        .padY = .fontInch * (0.2 + 0.2 * .sf) * .wpiY

        if .anchor$ = "right"
            .boxLeft = .x - .textW - .padX
            .boxRight = .x + .padX
        elsif .anchor$ = "centre"
            .boxLeft = .x - .textW / 2 - .padX
            .boxRight = .x + .textW / 2 + .padX
        else
            .boxLeft = .x - .padX
            .boxRight = .x + .textW + .padX
        endif
        .boxBottom = .y - .padY
        .boxTop = .y + .padY

        ; The user's own on-graph note. This was the last labelled box still
        ; painting solid white over whatever it landed on -- and unlike the
        ; legend and the disclosure block, it was solid on EVERY platform,
        ; because it had no sprite path at all rather than a sprite path with
        ; a bad fallback. Same painter as the other two now, so it is one of
        ; the translucent white PNGs on macOS and Windows and the screen door
        ; here.
        @emlPaintAlphaBox: .boxLeft, .boxRight, .boxBottom, .boxTop
        if emlPaintAlphaBox.viewportDirty = 1
            @emlSetPanelViewport
            Axes: .axXMin, .axXMax, .axYMin, .axYMax
            Font size: .fontSize
        endif
        Colour: "{0.7, 0.7, 0.7}"
        Line width: 0.5
        Draw rectangle: .boxLeft, .boxRight, .boxBottom, .boxTop
    endif

    Font size: .fontSize
    Colour: "{0.1, 0.1, 0.1}"
    Text: .x, .anchor$, .y, "half", .label$

    Colour: "Black"
    Line width: 1.0
    ; ...AND THE FONT SIZE, which this procedure installed three times above
    ; (the width measurement, the post-sprite restore, and the label). The box
    ; and its text are internally consistent at .fontSize and that is correct;
    ; what was not correct is leaving .fontSize ambient on return. The caller's
    ; figure runs at bodySize, and the next coordinate-dependent command it
    ; issues has to land on the rectangle it selected. @emlDrawMatrixPanel's
    ; Reset block (below, near the end of this file) is the pattern.
    Font size: emlSetAdaptiveTheme.bodySize
endproc


# ----------------------------------------------------------------------------
# @emlDrawAnnotations
# Umbrella: draw all pending annotations. Call after the main drawing
# procedure (with drawAxes suppressed) and before @emlDrawAxesWithHeadroom.
#
# Arguments:
#   .xMin, .xMax   — current axis x bounds
#   .yDataMax      — top of actual data range (brackets sit above this)
#   .yRange        — yMax - yMin of the data
#   .bracketColor$ — RGB colour string for bracket lines
#   .fontSize      — text size for annotation labels
# ----------------------------------------------------------------------------
; .axYMin/.axYMax are the installed y axis, carried through to
; @emlDrawAnnotation for its post-sprite restore only. The x axis it restores
; is .xMin/.xMax, which this procedure already has.
procedure emlDrawAnnotations: .xMin, .xMax, .yDataMax, .yRange, .bracketColor$, .fontSize, .axYMin, .axYMax
    # --- Brackets ---
    if annotBracketN > 0
        # Physically grounded tier geometry via world-per-inch
        .innerH = emlSetAdaptiveTheme.innerBottom - emlSetAdaptiveTheme.innerTop
        .wpiY = .yRange / .innerH
        .fontInch = .fontSize / 72
        .sf = emlSetAdaptiveTheme.spacingFactor
        .tierHeight = .fontInch * (1.5 + 0.9 * .sf) * .wpiY
        .yBase = .yDataMax + .fontInch * (0.5 + 0.5 * .sf) * .wpiY

        for .b from 1 to annotBracketN
            @emlDrawBracket: annotBracketI[.b], annotBracketJ[.b],
            ... .yBase, .tierHeight, annotBracketTier[.b],
            ... annotBracketLabel$[.b], .fontSize, .bracketColor$
        endfor
    endif

    # --- Text boxes ---
    if annotTextN > 0
        for .t from 1 to annotTextN
            @emlDrawAnnotation: annotTextX[.t], annotTextY[.t],
            ... annotTextAnchor$[.t], annotTextLabel$[.t],
            ... .fontSize, 1,
            ... .xMax - .xMin, .yRange,
            ... .xMin, .xMax, .axYMin, .axYMax
        endfor
    endif

    # --- Post-hoc caption (bracket layout only) ---
    # Gated on annotBracketN, not on the caption strings, and the order is
    # deliberate. The caption is a statement about the brackets: with no
    # brackets on the figure there are no drawn p-values for it to describe,
    # and the omnibus box above already names the test that produced the one
    # number the figure carries. It is drawn LAST because it is the only
    # thing here that changes the viewport for a band outside the panel, so
    # its restore is the last word on the world the caller gets back.
    if annotBracketN > 0
        @emlDrawBracketCaption: .fontSize, .xMin, .xMax, .axYMin, .axYMax
    endif
endproc


# ----------------------------------------------------------------------------
# @emlDrawRegressionLine
# Draw a regression line across the scatter plot axes.
# Computes y at xMin and xMax from the linear equation, clamps to
# axis bounds, draws a thin coloured line.
#
# Arguments:
#   .xMin, .xMax    — axis x bounds
#   .slope          — regression slope
#   .intercept      — regression intercept
#   .yAxisMin       — axis y minimum (for clamping)
#   .yAxisMax       — axis y maximum (for clamping)
#   .lineColor$     — RGB colour string
# ----------------------------------------------------------------------------
procedure emlDrawRegressionLine: .xMin, .xMax, .slope, .intercept, .yAxisMin, .yAxisMax, .lineColor$
    .y1 = .slope * .xMin + .intercept
    .y2 = .slope * .xMax + .intercept

    .drawXMin = .xMin
    .drawXMax = .xMax

    # Clamp: if y1 out of bounds, find x where line enters axis range
    if .y1 < .yAxisMin
        if .slope <> 0
            .drawXMin = (.yAxisMin - .intercept) / .slope
        endif
        .y1 = .yAxisMin
    elsif .y1 > .yAxisMax
        if .slope <> 0
            .drawXMin = (.yAxisMax - .intercept) / .slope
        endif
        .y1 = .yAxisMax
    endif

    if .y2 < .yAxisMin
        if .slope <> 0
            .drawXMax = (.yAxisMin - .intercept) / .slope
        endif
        .y2 = .yAxisMin
    elsif .y2 > .yAxisMax
        if .slope <> 0
            .drawXMax = (.yAxisMax - .intercept) / .slope
        endif
        .y2 = .yAxisMax
    endif

    # White halo for visibility against data points
    Colour: "White"
    Line width: 3.5
    Draw line: .drawXMin, .y1, .drawXMax, .y2

    # Regression line
    Colour: .lineColor$
    Line width: 2.5
    Draw line: .drawXMin, .y1, .drawXMax, .y2

    Colour: "Black"
    Line width: 1.0
endproc


# ----------------------------------------------------------------------------
# @emlPlaceElements
# Universal placement algorithm for legend and annotation block.
# Scores all four corners by data density + bracket occupation,
# then assigns corners to up to 2 floating elements.
#
# Arguments:
#   .qTL, .qTR, .qBL, .qBR — quadrant data counts (pre-computed by caller)
#   .xMid                   — x-axis midpoint (for mapping bracket positions)
#   .nElements              — 1 (legend only) or 2 (annotation block + legend)
#
# Bracket penalty: reads global annotBracketN / annotBracketI[] /
#   annotBracketJ[] to add occupation weight to top quadrants.
#   Brackets always live at the top of the plot.
#
# THERE IS NO LEGEND PENALTY, AND THAT IS DELIBERATE (v3.20). The obvious
# companion to legend headroom would be to weight the quadrants by how big
# the legend box is, so that the corner chosen here and the room made by
# @emlComputeAnnotationHeadroom agree instead of fighting. It would not help,
# for two reasons.
#
# FIRST, the box is the same size in all four corners, so a size penalty adds
# the same constant to every score and changes no ranking. What would help is
# scoring the number of points inside the legend RECTANGLE rather than inside
# the whole quadrant — a quadrant is a quarter of the panel and the box is a
# fraction of that, so a corner can be "busy" in a region the box never
# reaches. That needs the rectangle in world coordinates at every call site,
# and the call sites are the seven draw procedures. Filed, not fixed here.
#
# SECOND, the fight the headroom could have picked with this procedure does
# not happen, and the reason is a property of the scoring rather than luck.
# The room is made by moving ONE axis bound, so the y midpoint this
# procedure's callers split the quadrants on moves the same way. Give room
# ABOVE and yMid rises: every point between the old and new midpoints moves
# out of a top quadrant and into a bottom one, so both top counts fall and
# both bottom counts rise, and a legend that was in a top corner stays in a
# top corner. Give room BELOW and the mirror image holds. Only left and
# right can trade places, and the expansion is identical for both, so the
# room stays correct. Measured over the six legend-bearing types on 9 Aug
# 2026: two figures moved bottom-left -> bottom-right, none crossed between
# top and bottom.
#
# Output:
#   .corner1$ — emptiest corner (for annotation block, or sole legend)
#   .corner2$ — diagonal opposite of corner1 (for legend when 2 elements)
# ----------------------------------------------------------------------------
procedure emlPlaceElements: .qTL, .qTR, .qBL, .qBR, .xMid, .nElements
    # Add bracket penalties to top quadrants
    if variableExists ("annotBracketN")
        if annotBracketN > 0
            for .b from 1 to annotBracketN
                # Each bracket endpoint penalizes its quadrant
                if annotBracketI[.b] < .xMid
                    .qTL = .qTL + 1
                else
                    .qTR = .qTR + 1
                endif
                if annotBracketJ[.b] < .xMid
                    .qTL = .qTL + 1
                else
                    .qTR = .qTR + 1
                endif
            endfor
        endif
    endif

    # Find emptiest corner (lowest score wins)
    .minScore = .qTL
    .corner1$ = "top-left"

    if .qTR < .minScore
        .minScore = .qTR
        .corner1$ = "top-right"
    endif
    if .qBL < .minScore
        .minScore = .qBL
        .corner1$ = "bottom-left"
    endif
    if .qBR < .minScore
        .minScore = .qBR
        .corner1$ = "bottom-right"
    endif

    # Second element goes to diagonal opposite
    if .nElements >= 2
        @emlOppositeCorner: .corner1$
        .corner2$ = emlOppositeCorner.result$
    else
        .corner2$ = .corner1$
    endif
endproc


# ----------------------------------------------------------------------------
# @emlComputeAnnotationHeadroom
# Compute how much extra y-axis space a figure needs for the boxes that are
# drawn ON it. Call after @emlStackBrackets and after @emlSetAdaptiveTheme.
#
# THE CONTRACT THIS PROCEDURE IS THE OTHER HALF OF. graphs/eml-draw-
# procedures.praat states it beside the F0 minimum-span floors —
# grep for "is a property of what is drawn on it":
#
#     "Any extra room a figure needs is a property of what is drawn on it,
#      not of the unit, and is supplied by @emlComputeAnnotationHeadroom at
#      the annotation stage."
#
# Until v3.20 that was true of exactly one annotation, the significance
# bracket. A LEGEND is an annotation box by the same definition — it is
# drawn on the figure, it is not the data, and inside the plot (placement 1)
# it lands in a data corner — and it contributed nothing. The figure was
# therefore not given room for it, and it sat on the data: measured 9 Aug
# 2026 on a five-group line chart at 6 x 4, **13145 data pixels covered**,
# and 23702 on a grouped violin of the same data.
# @emlPlaceElements chooses among four corners; choosing the emptiest corner
# is not the same as making room, and on a figure whose data fills all four
# there is no empty corner to choose.
#
# Arguments:
#   .yDataRange   — yMax - yMin of the axis the figure would be drawn on
#                   WITHOUT any annotation room (the base axis)
#   .fontSize     — annotation font size (for bracket wpiY geometry)
#   .legendHeightInches — height of the laid-out legend box, in inches, as
#                   reported by @emlMeasureLegendPanel.height. Pass 0 when
#                   there is no legend, or when the legend is NOT drawn
#                   inside the plot (placements 2/3/4 grow the saved image
#                   instead and take nothing from the data area, and 5 draws
#                   nothing at all).
#   .legendCorner$ — the corner the legend is going to occupy: "top-left",
#                   "top-right", "bottom-left", "bottom-right", or "" for
#                   none. The corner decides WHICH END of the axis the room
#                   goes on. A legend in a bottom corner is not helped by
#                   room above the data.
#
# Output:
#   .headroom     — additional y-space needed ABOVE the base axis max
#   .footroom     — additional y-space needed BELOW the base axis min
#   .maxTier      — highest bracket tier assigned (0 if no brackets)
#   .overflow     — 1 if BRACKETS cannot fit in the viewport, 0 otherwise.
#                   Unchanged in meaning: it is the bracket verdict only, and
#                   its one caller suppresses brackets on it. A legend that
#                   cannot be afforded is reported separately, because the
#                   answer to it is different — see .legendOverflow.
#   .legendNeeded — inches the legend band asked for (0 if none)
#   .legendGranted— inches actually granted (< .legendNeeded when capped)
#   .legendOverflow — 1 when the band was capped, 0 otherwise
#
# HONESTY. Everything here moves an AXIS BOUND. Nothing rescales the data or
# changes what a plotted value means: a point at 88.2 dB is at 88.2 dB on the
# expanded axis exactly as it was on the base one, it simply has more empty
# axis above (or below) it. That is the whole permitted vocabulary.
#
# WHY THE SOLVE IS ALGEBRAIC. The boxes are drawn in INCHES on the panel but
# the axis is expanded in DATA UNITS, and the drawing happens on the EXPANDED
# axis — so the data-units-per-inch that converts the band is the post-
# expansion one, not the base one. With a band of k inches on a panel of
# innerH inches and a base range of R:
#
#     R + room = (R / (innerH - k)) * innerH      =>  room = k*R/(innerH - k)
#
# which is the identity the bracket term has always used. Both bands go into
# one k so that a figure carrying brackets AND a top-corner legend solves
# once rather than twice; solving twice and adding is wrong, because the
# expansion is not linear in k. (No graph type does both today — brackets are
# types 6/7/9, legends are 5/8/10/11/12/13 — but the arithmetic should not be
# the reason it cannot.)
#
# THE CAP, and why a legend is not simply suppressed. emlLegendHeadroomShare
# (default 0.5, read through variableExists) is the most of the panel the
# legend band may claim. A legend allowed to take the whole panel would leave
# a figure with a key and no plot. When the band exceeds the cap the room is
# granted up to the cap and .legendOverflow goes up, and the CALLER names the
# shortfall in the Info window: dropping a legend silently would tell the
# reader nothing about which colour is which group, and the project's rule is
# that anything dropped is named.
# ----------------------------------------------------------------------------
procedure emlComputeAnnotationHeadroom: .yDataRange, .fontSize, .legendHeightInches, .legendCorner$
    .maxTier = 0
    if annotBracketN > 0
        for .b from 1 to annotBracketN
            if annotBracketTier[.b] > .maxTier
                .maxTier = annotBracketTier[.b]
            endif
        endfor
    endif

    .innerH = emlSetAdaptiveTheme.innerBottom - emlSetAdaptiveTheme.innerTop
    .fontInch = .fontSize / 72
    .sf = emlSetAdaptiveTheme.spacingFactor

    # --- The bracket band, in inches. Arithmetic unchanged.
    .bracketInches = 0
    if .maxTier > 0
        # Must match bracket geometry: baseGap + tiers * tierHeight + topPad
        .baseGap = 0.5 + 0.5 * .sf
        .tierMult = 1.5 + 0.9 * .sf
        .kTotal = .baseGap + .maxTier * .tierMult + .baseGap
        .bracketInches = .fontInch * .kTotal
    endif

    # --- The legend band, in inches.
    #
    # @emlDrawLegend's placement-1 branch insets the legend's budget by
    # boxInsetInches on all four sides of the data area, so the box's outer
    # edge sits one inset in from the frame. The band the DATA must be kept
    # out of is that inset, plus the box, plus one more inset of clearance
    # between the box and the nearest data — the same uniform physical inset
    # every overlay box in this plugin uses, on both sides of the box.
    # ANCHOR, not a line number:
    #     grep -n 'INSIDE PLOT' plugin/graphs/eml-graph-procedures.praat
    .legendTop = 0
    .legendBottom = 0
    if .legendCorner$ = "top-left"
        .legendTop = 1
    endif
    if .legendCorner$ = "top-right"
        .legendTop = 1
    endif
    if .legendCorner$ = "bottom-left"
        .legendBottom = 1
    endif
    if .legendCorner$ = "bottom-right"
        .legendBottom = 1
    endif

    .legendNeeded = 0
    if .legendHeightInches > 0
        if .legendTop + .legendBottom > 0
            .legendNeeded = 2 * emlSetAdaptiveTheme.boxInsetInches
            ... + .legendHeightInches
        endif
    endif

    # --- The cap. Brackets keep the whole of their own demand; the legend
    # gets what is left under the share.
    .legendShare = 0.5
    if variableExists ("emlLegendHeadroomShare")
        if emlLegendHeadroomShare <> undefined
            if emlLegendHeadroomShare > 0
                .legendShare = emlLegendHeadroomShare
            endif
        endif
    endif
    .legendAffordable = .innerH * .legendShare - .bracketInches
    if .legendAffordable < 0
        .legendAffordable = 0
    endif
    .legendOverflow = 0
    .legendGranted = .legendNeeded
    if .legendNeeded > .legendAffordable
        .legendGranted = .legendAffordable
        .legendOverflow = 1
    endif

    # --- Which end of the axis each band goes on.
    .topInches = .bracketInches
    .bottomInches = 0
    if .legendTop = 1
        .topInches = .topInches + .legendGranted
    endif
    if .legendBottom = 1
        .bottomInches = .bottomInches + .legendGranted
    endif

    # --- The bracket overflow verdict. Bracket-only, exactly as before: its
    # caller reads it as "suppress the brackets", and a legend must never be
    # able to make that decision.
    .overflow = 0
    if .maxTier > 0
        if .bracketInches >= .innerH
            .overflow = 1
        endif
    endif

    if .overflow = 1
        # Brackets cannot physically fit. Same fallback value this branch has
        # always returned; the caller suppresses the brackets and does not
        # spend it.
        .headroom = .yDataRange * 0.5
        .footroom = 0
    else
        .k = .topInches + .bottomInches
        if .k <= 0
            .headroom = 0
            .footroom = 0
        elsif .k >= .innerH
            # Cannot happen with the cap above in force (brackets alone are
            # short of innerH here, and the legend is held under a share of
            # it), but a caller may set emlLegendHeadroomShare to something
            # unreasonable. Refuse rather than divide by a non-positive
            # number and hand back a negative axis.
            .headroom = 0
            .footroom = 0
            .legendOverflow = 1
            .legendGranted = 0
        else
            # Written band * range / (panel - band) rather than as a
            # data-units-per-inch factor applied twice, because that is the
            # association the bracket term has always evaluated in and
            # floating-point multiplication does not reassociate: the two
            # forms differ in the last bit at tier 4 on a 10 x 2.2 panel
            # (measured 9 Aug 2026). Bit-identical is worth one comment.
            .headroom = .topInches * .yDataRange / (.innerH - .k)
            .footroom = .bottomInches * .yDataRange / (.innerH - .k)
        endif
    endif
endproc


# ----------------------------------------------------------------------------
# @emlOppositeCorner
# Return the diagonally opposite corner. Used to separate the stats
# annotation block from the legend.
# Argument: .corner$ ("top-left", "top-right", "bottom-left", "bottom-right")
# Output: .result$
# ----------------------------------------------------------------------------
procedure emlOppositeCorner: .corner$
    if .corner$ = "top-left"
        .result$ = "bottom-right"
    elsif .corner$ = "top-right"
        .result$ = "bottom-left"
    elsif .corner$ = "bottom-left"
        .result$ = "top-right"
    else
        .result$ = "top-left"
    endif
endproc


# ----------------------------------------------------------------------------
# @emlSpaceCount: .s$
# Number of space characters in .s$. Used by @emlDrawAnnotationBlock to count
# words (spaces + 1) so a wrapped line's Praat markup can be cut at the same
# word boundaries as its plain text. Praat has no strcount, and replace$
# reports its substitution count only through the length difference.
#
# Output: .result
# ----------------------------------------------------------------------------
procedure emlSpaceCount: .s$
    .result = length (.s$) - length (replace$ (.s$, " ", "", 0))
endproc


# ----------------------------------------------------------------------------
# @emlDrawAnnotationBlock
# Render a multi-line text box with background fill in a specified corner.
# Reads from annotBlockN / annotBlockDraw$[1..N] globals.
#
# Arguments:
#   .corner$   — "top-left", "top-right", "bottom-left", "bottom-right"
#   .xMin, .xMax, .yMin, .yMax — current axis bounds
#   .fontSize  — text size for annotation lines
#
# Draws directly; no output variables.
# Uses annotBlockDraw$[] for Picture window text (may contain %% markup).
# Caller is responsible for populating annotBlockN and annotBlockDraw$[].
#
# WRAPPING. A box exactly as wide as its longest line as
# handed in. One long disclosure line therefore made the box wide enough to
# sit on top of the data, and on a narrow figure wide enough to run off the
# canvas: measured 8 Aug 2026, a 5-line block whose second line was 118
# characters, on a 3.6 x 3 inch 4-bar chart, drew a box 179% of the axis
# width — over all four bars, with the text clipped at the frame edge.
#
# Lines are now wrapped to a budget taken from the PLOTTING FRAME, never from
# a character constant. @emlReportNote is the Info window's equivalent and
# follows the same rule in its own frame — it wraps to 68 of the report's
# 72-column body, i.e. the frame less its indent. Here the frame is
# emlSetAdaptiveTheme's inner viewport and the deductions are the box's own
# padding and corner inset.
#
# A character constant cannot do this job, and the reason is worth writing
# down because @emlDisclose's "keep .short$ under about 50 characters" reads
# as though it could. annotSize scales WITH the viewport, so a character is
# very nearly a fixed fraction of the panel no matter how big the panel is.
# Measured 8 Aug 2026 at annotSize, as a share of the inner width:
#
#                          6 x 4      4.5 x 3.5     3.6 x 3
#     37 chars (the        0.506        0.537        0.653
#       omnibus line)
#     48 chars (a real     0.682        0.722        0.881
#       disclosure)
#     50 chars             0.874        0.930        1.128
#
# So "under 50 characters" has always meant "up to seven eighths of the panel",
# on every figure size — a character-count rule cannot bound it. The budget
# has to be stated as the share itself, which is emlAnnotBlockWidthShare
# (0.55): a corner box may take a little over half the frame, and the omnibus
# line that every annotated categorical figure carries still fits on one line
# at every size above.
#
# Markup survives the break. A line short enough to fit keeps its
# caller-supplied annotBlockDraw$ verbatim. A line that must be wrapped is
# broken on the LABEL — the plain text, which is what @emlWrapText and the
# width measurement can both reason about — and the Draw string is then cut at
# the same word boundaries, which works because Praat's "%" attaches to the
# word after it and @emlWrapText breaks at spaces. Word-for-word alignment is
# only valid while the two strings have the same word count, so that is
# checked; when it fails (a sanitized "\% " escape adds a space, an over-long
# token gets hard-broken mid-word) the segments fall back to being re-derived
# through @emlSanitizeLabel, exactly as @emlDisclose derives Draw from Label.
# ----------------------------------------------------------------------------
procedure emlDrawAnnotationBlock: .corner$, .xMin, .xMax, .yMin, .yMax, .fontSize
    if annotBlockN = 0
        # Nothing to draw
    else
        .xRange = .xMax - .xMin
        .yRange = .yMax - .yMin

        # Line height and spacing in world coordinates via world-per-inch
        .innerW = emlSetAdaptiveTheme.innerRight - emlSetAdaptiveTheme.innerLeft
        .innerH = emlSetAdaptiveTheme.innerBottom - emlSetAdaptiveTheme.innerTop
        .wpiX = .xRange / .innerW
        .wpiY = .yRange / .innerH
        .fontInch = .fontSize / 72
        .lineH = .fontInch * 1.4 * .wpiY

        # Padding and insets: scale with spacingFactor
        .sf = emlSetAdaptiveTheme.spacingFactor
        .padXInch = .fontInch * (0.3 + 0.2 * .sf)
        .padX = .padXInch * .wpiX
        .padY = .lineH * (0.2 + 0.15 * .sf)

        # Set font size before measuring — query uses current font metrics
        Font size: .fontSize

        ; ---- Text budget, as a share of the frame -----------------------
        if variableExists ("emlAnnotBlockWidthShare")
            .share = emlAnnotBlockWidthShare
        else
            .share = 0.55
        endif

        ; ---- Wrap, then measure ----------------------------------------
        ; Two things can send the pass round again.
        ;
        ; WIDTH. @emlWrapText counts CHARACTERS and the budget is in world
        ; units, so each over-long line converts its own budget with its own
        ; measured average character width. That estimate is off whenever a
        ; segment is unusually wide or narrow for the line it came from, so
        ; the pass repeats against the width actually measured, shrinking
        ; .fit until the widest segment fits.
        ;
        ; HEIGHT. Wrapping trades width for height, so a width budget can
        ; push the box off the TOP or BOTTOM of the frame instead — the same
        ; defect rotated 90°. When the wrapped box would stand taller than
        ; emlAnnotBlockHeightShare of the plotting frame the width share
        ; grows and the block is wrapped again, wider and shorter, up to
        ; 0.72. This is a fitting constraint and not a taste one, which is
        ; why the default is 0.95 and not something tidier: a tall narrow box
        ; is measurably the better shape. Measured 8 Aug 2026 on the
        ; 4-bar / 5-line figure at 3.6 x 3 inches — kept narrow the
        ; box is 0.38 x 0.72 of the frame and TWO bar tops stay readable;
        ; forced out to 0.72 wide it is 0.59 x 0.51 and only ONE does.
        ; Widening is what you do to avoid running off the canvas, not by
        ; preference.
        ; A block that does not fit even at 0.72 is too much text for the
        ; figure; it is drawn tall rather than silently truncated.
        .maxShare = 0.72
        if variableExists ("emlAnnotBlockHeightShare")
            .hShare = emlAnnotBlockHeightShare
        else
            .hShare = 0.95
        endif
        .fit = 1.0
        .pass = 0
        repeat
            .pass = .pass + 1
            ; Inner viewport share, less the box's own two paddings and the
            ; corner inset it is held off the axis by. Floored at four
            ; characters' worth so a pathologically small viewport still
            ; produces a wrap width @emlWrapText can work with rather than a
            ; zero or negative one.
            .availInch = .innerW * .share - 2 * .padXInch
            ... - emlSetAdaptiveTheme.boxInsetInches
            if .availInch < .fontInch * 4
                .availInch = .fontInch * 4
            endif
            .availW = .availInch * .wpiX
            .wN = 0
            for .i from 1 to annotBlockN
                .lineW = Text width (world coordinates): annotBlockLabel$[.i]
                if .lineW <= .availW
                    .wN = .wN + 1
                    .wLabel$[.wN] = annotBlockLabel$[.i]
                    .wDraw$[.wN] = annotBlockDraw$[.i]
                else
                    .maxChars = floor (length (annotBlockLabel$[.i])
                    ... * .availW * .fit / .lineW)
                    if .maxChars < 4
                        .maxChars = 4
                    endif
                    @emlWrapText: annotBlockLabel$[.i], .maxChars
                    ; Copy the segments out of emlWrapText's namespace before
                    ; anything else can call it, and count the words in each
                    ; on the way past. @emlSpaceCount is this file's helper:
                    ; words = spaces + 1 on a single-spaced string.
                    .nSeg = emlWrapText.nLines
                    .segWordSum = 0
                    for .s from 1 to .nSeg
                        .seg$[.s] = emlWrapText.line$[.s]
                        @emlSpaceCount: .seg$[.s]
                        .segWords[.s] = emlSpaceCount.result + 1
                        .segWordSum = .segWordSum + .segWords[.s]
                    endfor

                    ; Can the caller's markup be carried across the breaks?
                    ; Only if Label and Draw agree word for word AND the
                    ; segments account for exactly the Label's words (a
                    ; hard-broken over-long token would add one).
                    @emlSpaceCount: annotBlockLabel$[.i]
                    .labWords = emlSpaceCount.result + 1
                    @emlSpaceCount: annotBlockDraw$[.i]
                    .drawWords = emlSpaceCount.result + 1
                    .aligned = 0
                    if .drawWords = .labWords
                        if .segWordSum = .labWords
                            .aligned = 1
                        endif
                    endif

                    if .aligned = 1
                        ; Cut Draw at the same word boundaries.
                        .rest$ = annotBlockDraw$[.i]
                        for .s from 1 to .nSeg
                            .take$ = ""
                            for .q from 1 to .segWords[.s]
                                .sp = index (.rest$, " ")
                                if .sp = 0
                                    .tok$ = .rest$
                                    .rest$ = ""
                                else
                                    .tok$ = left$ (.rest$, .sp - 1)
                                    .rest$ = mid$ (.rest$, .sp + 1,
                                    ... length (.rest$))
                                endif
                                if .q = 1
                                    .take$ = .tok$
                                else
                                    .take$ = .take$ + " " + .tok$
                                endif
                            endfor
                            .segDraw$[.s] = .take$
                        endfor
                    else
                        ; Re-derive, the way @emlDisclose does.
                        for .s from 1 to .nSeg
                            @emlSanitizeLabel: .seg$[.s]
                            .segDraw$[.s] = emlSanitizeLabel.result$
                        endfor
                    endif

                    for .s from 1 to .nSeg
                        .wN = .wN + 1
                        .wLabel$[.wN] = .seg$[.s]
                        .wDraw$[.wN] = .segDraw$[.s]
                    endfor
                endif
            endfor
            ; Measure actual rendered width of each line (exact, font-aware).
            ; Use .wLabel$ (plain text) not .wDraw$ (markup) because markup
            ; chars affect Text width measurement.
            .textW = 0
            for .i from 1 to .wN
                .w = Text width (world coordinates): .wLabel$[.i]
                if .w > .textW
                    .textW = .w
                endif
            endfor
            ; `and` / `or` do not short-circuit here, so both operands of the
            ; height test have to be safe to evaluate unconditionally. They
            ; are: .wN >= 1 and .share is a number on every pass.
            .redo = 0
            if .textW > .availW
                .redo = 1
                .fit = .fit * (.availW / .textW) * 0.98
            elsif .wN * .lineH + 2 * .padY > .yRange * .hShare
            ... and .share < .maxShare
                .redo = 1
                .share = min (.maxShare, .share * 1.35)
                .fit = 1.0
            endif
        until .redo = 0 or .pass >= 6

        # Safety margin: screen font metrics differ slightly from PNG export
        .textW = .textW * 1.05

        .textH = .wN * .lineH
        .boxW = .textW + 2 * .padX
        .boxH = .textH + 2 * .padY

        # Inset from axes — unified with legend and matrix boxes
        .insetX = emlSetAdaptiveTheme.boxInsetInches * .wpiX
        .insetY = emlSetAdaptiveTheme.boxInsetInches * .wpiY

        ; ---- MEASURE-ONLY MODE --------------------------------------
        ; Everything above computes the box's SIZE; everything below puts it
        ; somewhere and paints it. A caller that wants to choose the corner
        ; by what is actually underneath each candidate rectangle needs the
        ; size first, and the size is not knowable without the wrap-and-fit
        ; loop that has just run.
        ;
        ; Rather than reimplement that loop in a second procedure -- where it
        ; would drift out of step with this one within a release, and the box
        ; the placement reasoned about would stop being the box that gets
        ; drawn -- the loop is run once in measure mode and once for real.
        ; It is text measurement and arithmetic, no drawing, so the cost is
        ; a repeat of a few Text-width queries.
        ;
        ; @emlPlaceAnnotationBox drives this. The flag is cleared by the
        ; caller, never here, because a procedure that resets a global it did
        ; not set is how the SECOND call ends up in measure mode too.
        if variableExists ("emlAnnotBlockMeasureOnly")
            if emlAnnotBlockMeasureOnly = 1
                ; MEASURE MODE LEAVES BY THE SIDE DOOR, SO IT CLEANS UP ITSELF.
                ; `label ANNOT_BLOCK_END` sits below the Reset block, not
                ; above it, so this goto jumps past every restore there is --
                ; including the size set at the top of this procedure for the
                ; text measurement. @emlPlaceAnnotationBox drives this pass in
                ; the MIDDLE of a figure, before the block is drawn for real,
                ; so the size it leaves behind is the size the rest of the
                ; figure would inherit. The measured outputs (.boxW, .boxH)
                ; are already computed and are not affected by this.
                Font size: emlSetAdaptiveTheme.bodySize
                goto ANNOT_BLOCK_END
            endif
        endif

        # Position based on corner
        if .corner$ = "top-left"
            .boxLeft = .xMin + .insetX
            .boxRight = .boxLeft + .boxW
            .boxTop = .yMax - .insetY
            .boxBottom = .boxTop - .boxH
            .textX = .boxLeft + .padX
        elsif .corner$ = "top-right"
            .boxRight = .xMax - .insetX
            .boxLeft = .boxRight - .boxW
            .boxTop = .yMax - .insetY
            .boxBottom = .boxTop - .boxH
            .textX = .boxLeft + .padX
        elsif .corner$ = "bottom-left"
            .boxLeft = .xMin + .insetX
            .boxRight = .boxLeft + .boxW
            .boxBottom = .yMin + .insetY
            .boxTop = .boxBottom + .boxH
            .textX = .boxLeft + .padX
        else
            # bottom-right
            .boxRight = .xMax - .insetX
            .boxLeft = .boxRight - .boxW
            .boxBottom = .yMin + .insetY
            .boxTop = .boxBottom + .boxH
            .textX = .boxLeft + .padX
        endif

        ; Background fill. Routed through @emlPaintAlphaBox so this box gets
        ; the same three-way treatment the legend does: the sprite where the
        ; platform composites it, a screen door where it does not, opaque
        ; only as a last resort. The inline copy this replaces fell back to
        ; an OPAQUE white rectangle on Linux, which erased whatever the box
        ; was sitting on -- the defect that was fixed for the legend and
        ; left standing here.
        ;
        ; @emlPaintAlphaBox reports .viewportDirty when the sprite path ran,
        ; because `Insert picture from file:` leaves the viewport on the
        ; image's own bounding box. Every coordinate below -- the border and
        ; all the text -- is in the caller's world, so the caller's viewport
        ; has to be put back before any of it is drawn. The inline copy did
        ; not do this. See the RESTORE note in the header: on Linux the call
        ; is a no-op and the viewport provably does not move, which is why
        ; no Linux render could ever have shown the difference.
        ; The restore goes through @emlSetPanelViewport rather than four
        ; literals, because this procedure is handed the AXIS RANGE and not
        ; the viewport -- its signature is (corner$, xMin, xMax, yMin, yMax,
        ; fontSize). The panel viewport is the one the figure is drawn into
        ; and the one that was in force on entry, so re-selecting it and
        ; re-installing the caller's axes puts the world back exactly.
        @emlPaintAlphaBox: .boxLeft, .boxRight, .boxBottom, .boxTop
        if emlPaintAlphaBox.viewportDirty = 1
            @emlSetPanelViewport
            Axes: .xMin, .xMax, .yMin, .yMax
            Font size: .fontSize
        endif
        Colour: "{0.7, 0.7, 0.7}"
        Line width: 0.5
        Draw rectangle: .boxLeft, .boxRight, .boxBottom, .boxTop

        # Draw lines top-to-bottom (the wrapped list, not the caller's)
        Colour: "{0.1, 0.1, 0.1}"
        .yLine = .boxTop - .padY - .lineH / 2
        for .i from 1 to .wN
            Text: .textX, "left", .yLine, "half", .wDraw$[.i]
            .yLine = .yLine - .lineH
        endfor

        # Reset
        Colour: "Black"
        Line width: 1.0
        ; ...AND THE FONT SIZE. This procedure sets it twice -- once above for
        ; the text measurement and again after @emlPaintAlphaBox's sprite path
        ; re-selects the viewport -- and it runs mid-figure on every annotated
        ; scatter, so anything drawn after it was being converted through the
        ; annotation size's margins instead of the body size's: about 2.9%
        ; per point of difference. @emlDrawMatrixPanel's Reset block is the
        ; compliant pattern and restores all three.
        Font size: emlSetAdaptiveTheme.bodySize
    endif
    label ANNOT_BLOCK_END
endproc


# ----------------------------------------------------------------------------
# @emlPlaceAnnotationBox: .xMin, .xMax, .yMin, .yMax, .fontSize,
#                         .qTL, .qTR, .qBL, .qBR, .xMid, .nElements
# Choose the annotation block's corner by what is UNDER each candidate box,
# not by how busy the quadrant around it is.
#
# Outputs
#   .corner1$    corner for the annotation block
#   .corner2$    diagonal opposite, for a legend when .nElements >= 2
#   .collisions  data points still underneath .corner1$ (0 when clear)
#   .boxW,.boxH  the measured box, in world units
#
# THE DEFECT. On an advanced scatter the
# annotation panel landed on top of a datum: the point at jitter 3.594, F0
# 79.49 was visible in the beginner figure and gone in the advanced one, and
# because the box background is a stipple screen on Linux rather than an
# opaque fill, the dot bled back THROUGH the panel as a dotted pattern across
# the text "-0.340". One figure, two failures -- a datum a reader cannot see
# and a number a reader cannot read -- from a single cause.
#
# WHY THE OLD CHOICE COULD NOT AVOID IT, and this is the part worth keeping.
# @emlPlaceElements scores QUADRANTS: a quarter of the panel each. The
# annotation box is a small fraction of a quadrant. So the emptiest quadrant
# is routinely not the emptiest place to put the box, and on a cloud that
# runs diagonally -- which every correlated scatter does -- the one or two
# points nearest a sparse corner are exactly the ones the box lands on.
# @emlPlaceElements' own header names this: "What would help is scoring the
# number of points inside the legend RECTANGLE rather than inside the whole
# quadrant ... Filed, not fixed here." This is that fix, for the annotation
# block; the legend still follows the block to the opposite corner.
#
# THE POINT CLOUD is registered by the caller in emlCollideN /
# emlCollideX# / emlCollideY# immediately before this call, because only the
# caller knows which points were actually DRAWN -- a point withheld by
# a point withheld by the frame clip is not on the page and cannot be hidden
# by a box.
# With no cloud registered this degrades to @emlPlaceElements' answer
# exactly, which is what every caller that has not been converted gets.
#
# WHEN NO CORNER IS CLEAR the emptiest is still chosen and .collisions says
# how many points remain under it. It is left to the caller to disclose that,
# because the honest response to "there is nowhere on this figure to put this
# box" is to tell the reader, not to drop the box and not to paint over the
# data in silence. Making room by moving an axis bound -- what
# @emlComputeAnnotationHeadroom does for legends and brackets -- is not
# available here: the block's text is not known until after the data have
# been plotted, and by then the axis is on the page.
# ----------------------------------------------------------------------------
procedure emlPlaceAnnotationBox: .xMin, .xMax, .yMin, .yMax, .fontSize, .qTL, .qTR, .qBL, .qBR, .xMid, .nElements
    ; Fall back to the quadrant answer whenever there is nothing to measure
    ; against or nothing to measure.
    @emlPlaceElements: .qTL, .qTR, .qBL, .qBR, .xMid, .nElements
    .corner1$ = emlPlaceElements.corner1$
    .corner2$ = emlPlaceElements.corner2$
    .collisions = 0
    .boxW = 0
    .boxH = 0
    if annotBlockN = 0
        goto PLACE_ANNOT_END
    endif
    if variableExists ("emlCollideN") = 0
        goto PLACE_ANNOT_END
    endif
    if emlCollideN < 1
        goto PLACE_ANNOT_END
    endif

    ; ---- Measure the box the caller is about to draw --------------------
    emlAnnotBlockMeasureOnly = 1
    @emlDrawAnnotationBlock: "top-left", .xMin, .xMax, .yMin, .yMax, .fontSize
    emlAnnotBlockMeasureOnly = 0
    .boxW = emlDrawAnnotationBlock.boxW
    .boxH = emlDrawAnnotationBlock.boxH
    .insetX = emlDrawAnnotationBlock.insetX
    .insetY = emlDrawAnnotationBlock.insetY
    if .boxW = undefined or .boxH = undefined
        goto PLACE_ANNOT_END
    endif
    if .boxW <= 0 or .boxH <= 0
        goto PLACE_ANNOT_END
    endif

    ; ---- The four candidate rectangles ----------------------------------
    .cName$[1] = "top-left"
    .cLeft[1] = .xMin + .insetX
    .cTop[1] = .yMax - .insetY
    .cName$[2] = "top-right"
    .cLeft[2] = .xMax - .insetX - .boxW
    .cTop[2] = .yMax - .insetY
    .cName$[3] = "bottom-left"
    .cLeft[3] = .xMin + .insetX
    .cTop[3] = .yMin + .insetY + .boxH
    .cName$[4] = "bottom-right"
    .cLeft[4] = .xMax - .insetX - .boxW
    .cTop[4] = .yMin + .insetY + .boxH

    .qScore[1] = .qTL
    .qScore[2] = .qTR
    .qScore[3] = .qBL
    .qScore[4] = .qBR

    for .c from 1 to 4
        .hit[.c] = 0
        .right = .cLeft[.c] + .boxW
        .bottom = .cTop[.c] - .boxH
        for .p from 1 to emlCollideN
            .px = emlCollideX#[.p]
            .py = emlCollideY#[.p]
            ; Nested tests, never a chained `and`: Praat evaluates both
            ; operands and an undefined coordinate compares FALSE, so a
            ; combined test would silently count nothing.
            .in = 1
            if .px = undefined
                .in = 0
            endif
            if .py = undefined
                .in = 0
            endif
            if .in = 1
                if .px < .cLeft[.c]
                    .in = 0
                endif
            endif
            if .in = 1
                if .px > .right
                    .in = 0
                endif
            endif
            if .in = 1
                if .py < .bottom
                    .in = 0
                endif
            endif
            if .in = 1
                if .py > .cTop[.c]
                    .in = 0
                endif
            endif
            if .in = 1
                .hit[.c] = .hit[.c] + 1
            endif
        endfor
    endfor

    ; ---- Fewest points under the box wins; ties go to the emptiest
    ; quadrant, which is the answer this plugin has always given and is a
    ; better tie-break than declaration order.
    .best = 1
    for .c from 2 to 4
        .take = 0
        if .hit[.c] < .hit[.best]
            .take = 1
        elsif .hit[.c] = .hit[.best]
            if .qScore[.c] < .qScore[.best]
                .take = 1
            endif
        endif
        if .take = 1
            .best = .c
        endif
    endfor

    .corner1$ = .cName$[.best]
    .collisions = .hit[.best]
    if .nElements >= 2
        @emlOppositeCorner: .corner1$
        .corner2$ = emlOppositeCorner.result$
    else
        .corner2$ = .corner1$
    endif
    label PLACE_ANNOT_END
endproc


# ============================================================================
# @emlMeasureMatrixLayout
# ============================================================================
# Measure matrix panel geometry: label rotation/truncation, vertical
# stacking, cell sizing, legend minimum width. Called before
# @emlDrawMatrixPanel — the panel is a pure renderer reading these results.
#
# Rotate-then-truncate order:
#   1. Measure each label against available width
#   2. If ANY label overflows → rotate all column headers 45°
#   3. After rotation, if ANY label STILL overflows → truncate with "…"
#   This matches the graph x-axis behavior in @emlFitCategoricalLabels.
#
# Reads globals:
#   annotMatrixN, annotMatrixLabel$[], annotMatrixEffectLabel$
#   emlSetAdaptiveTheme.* (font sizes, inner viewport, spacing)
#
# Arguments:
#   .vpLeft, .vpRight, .vpTop, .vpBottom — panel viewport (inches)
#   .fontSize — base text size for labels and cells
#
# Output (module-level globals):
#   emlMatrixLayout_scaledFont     — possibly compressed font
#   emlMatrixLayout_fontInch       — scaledFont / 72
#   emlMatrixLayout_cellW          — cell width (viewport units)
#   emlMatrixLayout_gridW          — total grid width
#   emlMatrixLayout_gridLeft       — grid left edge
#   emlMatrixLayout_gridRight      — grid right edge
#   emlMatrixLayout_gridCenter     — grid horizontal center
#   emlMatrixLayout_rotateHeaders  — 1 = rotate column headers 45°
#   emlMatrixLayout_showText       — 1 = show text, 0 = shading only
#   emlMatrixLayout_suppressed     — 1 = too narrow to display at all
#   emlMatrixLayout_titleY         — vertical position of title
#   emlMatrixLayout_subtitleY      — vertical position of subtitle
#   emlMatrixLayout_headerY        — vertical position of column headers
#   emlMatrixLayout_dataTop        — top of data grid
#   emlMatrixLayout_rowH           — row height
#   emlMatrixLayout_labelGap       — gap between labels and grid
#   emlMatrixLayout_labelRight     — right edge of row label column
#   emlMatrixLayout_maxLabelSpace  — max width for row labels
#   emlMatrixLayout_yMax           — total content height
#   emlMatrixLayout_hasEffect      — 1 = effect sizes present
#   emlMatrixLayout_legendMinWidthInches — minimum legend width from content
#   annotMatrixLabel$[]            — MUTATED IN PLACE (see below)
#
# CALLER-DATA MUTATION (documented, deliberate): this procedure overwrites
# annotMatrixLabel$[1..annotMatrixN] with a display-ready form — first
# sanitized via @emlSanitizeLabel, then truncated with an ellipsis if the row
# label column is too narrow. The bridge's raw group labels are NOT preserved
# anywhere, so:
#   * any consumer that needs the raw label (e.g. a data lookup keyed on the
#     group name) must read it BEFORE this procedure runs, or re-read it from
#     the bridge (@emlRunAnnotationComparison.gLabel$[]);
#   * the procedure is not idempotent — calling it twice at a narrower width
#     truncates an already-truncated (and already-sanitized) string;
#   * @emlClearAnnotations therefore clears annotMatrixLabel$[] over the
#     previous figure's annotMatrixN range, so mutated labels cannot leak
#     into the next figure.
# Left destructive rather than copied to a display-only array because the
# renderer (@emlDrawMatrixPanel) reads annotMatrixLabel$[] directly and lives
# in the declared no-touch set for this pass.
# ============================================================================
procedure emlMeasureMatrixLayout: .vpLeft, .vpRight, .vpTop, .vpBottom, .fontSize
    .nG = annotMatrixN
    emlMatrixLayout_suppressed = 0
    emlMatrixLayout_showText = 1
    emlMatrixLayout_rotateHeaders = 0
    emlMatrixLayout_hasEffect = 0
    emlMatrixLayout_legendMinWidthInches = 0

    if .nG < 2
        emlMatrixLayout_suppressed = 1
    endif

    if emlMatrixLayout_suppressed = 1
        goto END_MEASURE_MATRIX
    endif

    if annotMatrixEffectLabel$ <> ""
        emlMatrixLayout_hasEffect = 1
    endif

    # Sanitize labels for display (underscores, special chars).
    # Raw values were already used for data lookups in the bridge.
    for .i from 1 to .nG
        @emlSanitizeLabel: annotMatrixLabel$[.i]
        annotMatrixLabel$[.i] = emlSanitizeLabel.result$
    endfor

    .vpW = .vpRight - .vpLeft
    .vpH = .vpBottom - .vpTop

    # ----------------------------------------------------------------
    # Grid geometry — aligned to graph inner box
    # ----------------------------------------------------------------
    .innerLeftX = emlSetAdaptiveTheme.innerLeft
    .innerRightX = emlSetAdaptiveTheme.innerRight
    .innerBoxW = .innerRightX - .innerLeftX

    # Font setup
    .scaledFont = .fontSize
    .fontInch = .scaledFont / 72

    # ----------------------------------------------------------------
    # Set viewport for text measurement (must precede content sizing)
    # ----------------------------------------------------------------
    Font size: emlSetAdaptiveTheme.bodySize
    Select inner viewport: .vpLeft, .vpRight, .vpTop, .vpBottom
    Axes: 0, .vpW, .vpH, 0

    # ----------------------------------------------------------------
    # Content-aware cell sizing
    # ----------------------------------------------------------------
    # Measure the widest cell content at current font size.
    # Cell content is already populated by the bridge.
    Font size: .scaledFont
    .maxContentW = 0
    for .i from 1 to .nG - 1
        for .j from .i + 1 to .nG
            .cellText$ = annotMatrixCell'.i'_'.j'$
            # Strip "p = " / "p < " prefix as the panel renderer does
            if left$ (.cellText$, 4) = "p = "
                .measureText$ = mid$ (.cellText$, 5, length (.cellText$) - 4)
            elsif left$ (.cellText$, 4) = "p < "
                .measureText$ = "< " + mid$ (.cellText$, 5, length (.cellText$) - 4)
            else
                .measureText$ = .cellText$
            endif
            .w = Text width (world coordinates): .measureText$
            if .w > .maxContentW
                .maxContentW = .w
            endif
            # Also measure effect size text if present
            if emlMatrixLayout_hasEffect = 1
                .dVal = annotMatrixD'.i'_'.j'
                if .dVal <> undefined
                    .dText$ = fixed$ (abs (.dVal), 2)
                    .w = Text width (world coordinates): .dText$
                    if .w > .maxContentW
                        .maxContentW = .w
                    endif
                endif
            endif
        endfor
    endfor
    # Padding: content must not touch cell edges
    .contentMinCellW = .maxContentW * 1.15

    # Cell width: max of geometry-based and content-based minimums
    .referenceCellW = .innerBoxW / 10
    .maxCellW = .referenceCellW * 1.5
    .geomMinCellW = .fontInch * 3.0
    .naturalCellW = .innerBoxW / .nG
    .cellW = min (.maxCellW, max (.geomMinCellW, .naturalCellW))

    # Content floor: if content is wider than geometry allows, expand
    if .contentMinCellW > .cellW
        .cellW = .contentMinCellW
    endif

    .gridW = .nG * .cellW

    # If grid exceeds inner box: try font compression first
    if .gridW > .innerBoxW
        # Can we fit by compressing font?
        .tryFont = .scaledFont * (.innerBoxW / .gridW) * 0.95
        if .tryFont >= 5
            .scaledFont = .tryFont
            .fontInch = .scaledFont / 72
            # Re-measure content at compressed font
            Font size: .scaledFont
            .maxContentW = 0
            for .i from 1 to .nG - 1
                for .j from .i + 1 to .nG
                    .cellText$ = annotMatrixCell'.i'_'.j'$
                    if left$ (.cellText$, 4) = "p = "
                        .measureText$ = mid$ (.cellText$, 5, length (.cellText$) - 4)
                    elsif left$ (.cellText$, 4) = "p < "
                        .measureText$ = "< " + mid$ (.cellText$, 5, length (.cellText$) - 4)
                    else
                        .measureText$ = .cellText$
                    endif
                    .w = Text width (world coordinates): .measureText$
                    if .w > .maxContentW
                        .maxContentW = .w
                    endif
                endfor
            endfor
            .contentMinCellW = .maxContentW * 1.15
            .cellW = max (.contentMinCellW, .innerBoxW / .nG)
            .gridW = .nG * .cellW
        endif
    endif

    # Final overflow check: if content still can't fit → shading only
    if .gridW > .innerBoxW
        .cellW = .innerBoxW / .nG
        .gridW = .innerBoxW
        emlMatrixLayout_showText = 0
    endif

    # Center grid on inner box when narrower; fill when full
    if .gridW >= .innerBoxW
        .gridLeft = .innerLeftX
        .gridW = .innerBoxW
        .cellW = .gridW / .nG
    else
        .gridLeft = .innerLeftX + (.innerBoxW - .gridW) / 2
    endif
    .gridRight = .gridLeft + .gridW
    .gridCenter = (.gridLeft + .gridRight) / 2

    # Final tier check: too narrow for even shading?
    if .cellW < .fontInch * 1.0
        emlMatrixLayout_suppressed = 1
        ; THE SUPPRESSED PATH RESTORES THE SIZE TOO. The restore at the foot
        ; of this procedure is above `label END_MEASURE_MATRIX`, so this goto
        ; jumps past it and would leave .scaledFont ambient. The earlier goto
        ; in this procedure is safe because it fires before the first size
        ; change; this one does not. @emlMeasureMatrixLayout runs PRE-DISPATCH
        ; from the graphs form -- before the figure is drawn -- so the size it
        ; leaves is the size the figure would open on.
        Font size: emlSetAdaptiveTheme.bodySize
        goto END_MEASURE_MATRIX
    endif

    # Row labels — external to grid, right-justified in left margin
    .labelGap = .fontInch * 0.7
    .labelRight = .gridLeft - .labelGap
    .maxLabelSpace = (.gridLeft - .vpLeft) * 0.85

    # Row height
    .rowH = .fontInch * 2.1

    # ----------------------------------------------------------------
    # ROTATE-THEN-TRUNCATE (correct order)
    # ----------------------------------------------------------------
    # Step 1: Check rotation BEFORE any truncation
    .colLabelPad = .cellW * 0.85
    Font size: .scaledFont
    .maxLabelW = 0
    for .j from 1 to .nG
        .lblW = Text width (world coordinates): annotMatrixLabel$[.j]
        if .lblW > .maxLabelW
            .maxLabelW = .lblW
        endif
        if .lblW > .colLabelPad
            emlMatrixLayout_rotateHeaders = 1
        endif
    endfor

    # Step 2: Truncate — tightest constraint wins
    .maxMatrixLabelW = min (.maxLabelSpace, .cellW * 0.85)
    for .j from 1 to .nG
        .lblW = Text width (world coordinates): annotMatrixLabel$[.j]
        if .lblW > .maxMatrixLabelW
            .lo = 1
            .hi = length (annotMatrixLabel$[.j])
            .origML$ = annotMatrixLabel$[.j]
            while .lo < .hi - 1
                .mid = round ((.lo + .hi) / 2)
                .tryML$ = left$ (.origML$, .mid) + "…"
                .tryMLW = Text width (world coordinates): .tryML$
                if .tryMLW <= .maxMatrixLabelW
                    .lo = .mid
                else
                    .hi = .mid
                endif
            endwhile
            annotMatrixLabel$[.j] = left$ (.origML$, .lo) + "…"
        endif
    endfor

    # Re-measure maxLabelW after truncation (for header height calc)
    .maxLabelW = 0
    for .j from 1 to .nG
        .lblW = Text width (world coordinates): annotMatrixLabel$[.j]
        if .lblW > .maxLabelW
            .maxLabelW = .lblW
        endif
    endfor

    # ----------------------------------------------------------------
    # Title/subtitle vertical layout — responsive to content
    # Spacing anchored to the font sizes actually used in the panel
    # (annotSize for omnibus title, matrixSize for subtitle), not
    # the graph's bodySize. Matches @emlDrawTitle proportional ratios.
    # ----------------------------------------------------------------
    .annotInch = emlSetAdaptiveTheme.annotSize / 72
    .clearance = .annotInch * 0.5
    .gap = .fontInch * 0.4
    .titleY = .clearance + .annotInch / 2
    .subtitleY = .titleY + .annotInch / 2 + .gap + .fontInch / 2

    # ----------------------------------------------------------------
    # Header spacing — responsive to rotation and label dimensions
    # ----------------------------------------------------------------
    .lineH = .fontInch * 2.0

    if emlMatrixLayout_rotateHeaders
        .rotatedH = .maxLabelW * 0.707
        .headerY = .subtitleY + .fontInch / 2 + .lineH * 1.2 + .rotatedH * 0.80
    else
        .headerY = .subtitleY + .fontInch / 2 + .lineH * 1.2
    endif
    .dataTop = .headerY + .fontInch * 0.8

    # Shading-only: no headers, collapse header gap
    if emlMatrixLayout_showText = 0
        .dataTop = .subtitleY + .lineH * 0.8
    endif

    # ----------------------------------------------------------------
    # Bottom extent — includes legend if effect sizes present
    # ----------------------------------------------------------------
    if emlMatrixLayout_hasEffect = 1
        .legendGap = .fontInch * 1.5
        .legendSwatchSize = .fontInch * 2.0
        .legendBottomPad = .fontInch * 2.0
        .yMax = .dataTop + .nG * .rowH
        ... + .legendGap + .legendSwatchSize + .legendBottomPad
    else
        .yMax = .dataTop + .nG * .rowH + .fontInch * 0.5
    endif

    # Shading-only: expand grid to fill inner box
    if emlMatrixLayout_showText = 0
        .gridLeft = .innerLeftX
        .cellW = .innerBoxW / .nG
        .gridW = .innerBoxW
        .gridRight = .gridLeft + .gridW
        .gridCenter = (.gridLeft + .gridRight) / 2
    endif

    # ----------------------------------------------------------------
    # Legend minimum width from content (TODO-003)
    # ----------------------------------------------------------------
    if emlMatrixLayout_hasEffect = 1
        Font size: .scaledFont
        .textGap = .fontInch * 1.0
        .itemGap = .fontInch * 2.5
        .swatchW = .fontInch * 2.0
        # Build dynamic p-legend label from annotAlpha.
        # Guarded the same way as @emlFormatStars: an unset annotAlpha would
        # raise "Unknown variable" here, and an undefined one would render the
        # swatch as "p < --undefined--" (undefined < 0.01 is FALSE, so the
        # else branch runs). Fall back to the documented default of 0.05.
        .legendAlpha = 0.05
        if variableExists ("annotAlpha")
            if annotAlpha <> undefined
                if annotAlpha > 0
                    .legendAlpha = annotAlpha
                endif
            endif
        endif
        if .legendAlpha < 0.01
            .pLegend$ = "p < " + replace$ (fixed$ (.legendAlpha, 3), "0.", ".", 1)
        else
            .pLegend$ = "p < " + replace$ (fixed$ (.legendAlpha, 2), "0.", ".", 1)
        endif
        emlMatrixLayout_pLegend$ = .pLegend$
        .tw1 = Text width (world coordinates): .pLegend$
        .tw2 = Text width (world coordinates): "large"
        .tw3 = Text width (world coordinates): "medium"
        .tw4 = Text width (world coordinates): "small"
        .padInch = .fontInch * 1.0
        emlMatrixLayout_legendMinWidthInches = 4 * (.swatchW + .textGap)
        ... + .tw1 + .tw2 + .tw3 + .tw4 + 3 * .itemGap + 2 * .padInch
    endif

    # ----------------------------------------------------------------
    # Store all results in module-level globals
    # ----------------------------------------------------------------
    emlMatrixLayout_scaledFont = .scaledFont
    emlMatrixLayout_fontInch = .fontInch
    emlMatrixLayout_cellW = .cellW
    emlMatrixLayout_gridW = .gridW
    emlMatrixLayout_gridLeft = .gridLeft
    emlMatrixLayout_gridRight = .gridRight
    emlMatrixLayout_gridCenter = .gridCenter
    emlMatrixLayout_titleY = .titleY
    emlMatrixLayout_subtitleY = .subtitleY
    emlMatrixLayout_headerY = .headerY
    emlMatrixLayout_dataTop = .dataTop
    emlMatrixLayout_rowH = .rowH
    emlMatrixLayout_labelGap = .labelGap
    emlMatrixLayout_labelRight = .labelRight
    emlMatrixLayout_maxLabelSpace = .maxLabelSpace
    emlMatrixLayout_yMax = .yMax

    # Restore font state
    Font size: emlSetAdaptiveTheme.bodySize

    label END_MEASURE_MATRIX
endproc


# ----------------------------------------------------------------------------
# @emlDrawMatrixPanel
# Render a pairwise comparison matrix as a table panel below the plot.
# Uses its own viewport — does not draw inside the plot axes.
#
# Split-triangle layout:
#   Upper triangle = p-values (significant highlighted, NS muted)
#   Lower triangle = |Cohen's d| with 3-tier magnitude coloring
#   Diagonal = em-dash
#
# Color mode:
#   "color" — blue sig p-values, amber/gold effect size tiers
#   "bw"    — medium grey sig p-values, black/dark-grey effect tiers
#             with white text for large and medium effects
#
# Reads annotMatrixN, annotMatrixLabel$[], annotMatrixOmnibus$,
# annotMatrixCell'.i'_'.j'$, annotMatrixSig'.i'_'.j',
# annotMatrixD'.i'_'.j'
#
# Arguments:
#   .vpLeft     — left edge of panel viewport (inches)
#   .vpRight    — right edge of panel viewport (inches)
#   .vpTop      — top edge of panel viewport (inches, = bottom of plot)
#   .vpBottom   — bottom edge of panel viewport (inches)
#   .fontSize   — text size for labels and cells
#   .colorMode$ — "color" or "bw"
# ----------------------------------------------------------------------------
procedure emlDrawMatrixPanel: .vpLeft, .vpRight, .vpTop, .vpBottom, .fontSize, .colorMode$
    .nG = annotMatrixN

    # ----------------------------------------------------------------
    # Pure renderer — reads all geometry from @emlMeasureMatrixLayout.
    # No measurement, no label truncation, no rotation decisions here.
    # ----------------------------------------------------------------

    if emlMatrixLayout_suppressed = 1
        if emlMatrixLayout_showText = 0 and .nG >= 2
            appendInfoLine: "NOTE: Viewport too narrow for comparison matrix "
            ... + "— panel suppressed."
        endif
        goto END_PANEL
    endif

    # Read measured layout
    .hasEffect = emlMatrixLayout_hasEffect
    .scaledFont = emlMatrixLayout_scaledFont
    .fontInch = emlMatrixLayout_fontInch
    .cellW = emlMatrixLayout_cellW
    .gridW = emlMatrixLayout_gridW
    .gridLeft = emlMatrixLayout_gridLeft
    .gridRight = emlMatrixLayout_gridRight
    .gridCenter = emlMatrixLayout_gridCenter
    .showText = emlMatrixLayout_showText
    .rotateHeaders = emlMatrixLayout_rotateHeaders
    .titleY = emlMatrixLayout_titleY
    .subtitleY = emlMatrixLayout_subtitleY
    .headerY = emlMatrixLayout_headerY
    .dataTop = emlMatrixLayout_dataTop
    .rowH = emlMatrixLayout_rowH
    .labelGap = emlMatrixLayout_labelGap
    .labelRight = emlMatrixLayout_labelRight
    .yMax = emlMatrixLayout_yMax

    .vpW = .vpRight - .vpLeft
    .vpH = .vpBottom - .vpTop

    # ----------------------------------------------------------------
    # Top-down viewport sizing
    # ----------------------------------------------------------------
    .contentH = .yMax
    .maxH = .contentH * 1.3
    if .vpH > .maxH
        .vpBottom = .vpTop + .maxH
    elsif .vpH < .contentH
        .vpBottom = .vpTop + .contentH
    endif
    .vpH = .vpBottom - .vpTop

    # Font state invariant: bodySize before viewport assertion
    Font size: emlSetAdaptiveTheme.bodySize
    Select inner viewport: .vpLeft, .vpRight, .vpTop, .vpBottom
    Axes: 0, .vpW, .yMax, 0

    # ----------------------------------------------------------------
    # Color definitions
    # ----------------------------------------------------------------
    if .colorMode$ = "bw"
        .pSigBg$      = "{0.72, 0.72, 0.72}"
        .pSigText$    = "{0.08, 0.08, 0.08}"
        .pNsBg$       = "{0.92, 0.92, 0.92}"
        ; Was {0.45} = 3.98:1 on this 0.92 ground. {0.40} = 4.80:1.
        .pNsText$     = "{0.40, 0.40, 0.40}"
        .dLargeBg$    = "{0.12, 0.12, 0.12}"
        .dLargeText$  = "{1.0, 1.0, 1.0}"
        .dMediumBg$   = "{0.45, 0.45, 0.45}"
        .dMediumText$ = "{1.0, 1.0, 1.0}"
        .dSmallBg$    = "{0.92, 0.92, 0.92}"
        ; Was {0.50} = 3.32:1 on this 0.92 ground. {0.40} = 4.80:1.
        .dSmallText$  = "{0.40, 0.40, 0.40}"
    else
        .pSigBg$      = "{0.82, 0.90, 0.97}"
        .pSigText$    = "{0.08, 0.08, 0.08}"
        .pNsBg$       = "{0.96, 0.96, 0.96}"
        .pNsText$     = "{0.38, 0.38, 0.38}"
        .dLargeBg$    = "{0.92, 0.82, 0.55}"
        .dLargeText$  = "{0.35, 0.25, 0.01}"
        .dMediumBg$   = "{1.0, 0.93, 0.76}"
        .dMediumText$ = "{0.40, 0.31, 0.01}"
        .dSmallBg$    = "{0.96, 0.96, 0.96}"
        ; Was {0.50} = 3.64:1 on this 0.96 ground. {0.40} = 5.26:1.
        ; (.pNsText$ {0.38} on 0.96 is 5.68:1 and needs no change.)
        .dSmallText$  = "{0.40, 0.40, 0.40}"
    endif

    # ----------------------------------------------------------------
    # Title (omnibus) — centered on grid
    # ----------------------------------------------------------------
    if annotMatrixOmnibus$ <> ""
        Colour: "{0.15, 0.15, 0.15}"
        Text special: .gridCenter, "centre", .titleY, "half",
        ... emlFont$, emlSetAdaptiveTheme.annotSize, "0",
        ... annotMatrixOmnibus$
    endif

    # ----------------------------------------------------------------
    # Subtitle — centered on grid
    # ----------------------------------------------------------------
    # This sub-line is the ONLY place in the figure that discloses which
    # correction produced the annotated p-values, and it was drawn in
    # {0.55, 0.55, 0.55} — 3.35:1 against white, below the WCAG AA 4.5:1
    # minimum for normal text, and it degrades badly in greyscale print and
    # on projection. {0.40, 0.40, 0.40} is 5.74:1 against white (WCAG 2.x
    # relative luminance, sRGB), still clearly subordinate to the {0.15}
    # title above it. Do not lighten past 0.46 (= 4.5:1) on a white ground.
    if .hasEffect = 1
        Colour: "{0.40, 0.40, 0.40}"
        if annotMatrixPosthoc$ <> ""
            .sub$ = annotMatrixPosthoc$ + " · Upper: adjusted p · Lower: "
            ... + annotMatrixEffectLabel$ + " (magnitude)"
        else
            .sub$ = "Upper: adjusted p · Lower: "
            ... + annotMatrixEffectLabel$ + " (magnitude)"
        endif
        Text special: .gridCenter, "centre", .subtitleY, "half",
        ... emlFont$, .fontSize, "0", .sub$
    elsif annotMatrixPosthoc$ <> ""
        ; 5.74:1 against white — see the note on the branch above.
        Colour: "{0.40, 0.40, 0.40}"
        .sub$ = annotMatrixPosthoc$
        Text special: .gridCenter, "centre", .subtitleY, "half",
        ... emlFont$, .fontSize, "0", .sub$
    endif

    # ----------------------------------------------------------------
    # Column headers — rotation decided by @emlMeasureMatrixLayout
    # ----------------------------------------------------------------
    if .showText = 1
        Colour: "{0.08, 0.08, 0.08}"
        for .j from 1 to .nG
            .cx = .gridLeft + (.j - 1) * .cellW + .cellW / 2
            if .rotateHeaders
                Text special: .cx, "left", .headerY, "half",
                ... emlFont$, .scaledFont, "45",
                ... annotMatrixLabel$[.j]
            else
                Text special: .cx, "centre", .headerY, "half",
                ... emlFont$, .scaledFont, "0",
                ... annotMatrixLabel$[.j]
            endif
        endfor
    endif

    # ----------------------------------------------------------------
    # Data rows
    # ----------------------------------------------------------------
    for .i from 1 to .nG
        .ry = .dataTop + (.i - 1) * .rowH + .rowH / 2 + .fontInch * 0.15

        # Row label — right-justified in left margin (normal mode only)
        if .showText = 1
            Colour: "{0.08, 0.08, 0.08}"
            Text special: .labelRight, "right", .ry, "half",
            ... emlFont$, .scaledFont, "0",
            ... annotMatrixLabel$[.i]
        endif

        # Cells
        for .j from 1 to .nG
            .cx = .gridLeft + (.j - 1) * .cellW + .cellW / 2
            .cellPad = min (.cellW, .rowH) * 0.04
            .cellL = .gridLeft + (.j - 1) * .cellW + .cellPad
            .cellR = .gridLeft + (.j - 1) * .cellW + .cellW - .cellPad
            .cellT = .dataTop + (.i - 1) * .rowH + .cellPad
            .cellB = .dataTop + (.i - 1) * .rowH + .rowH - .cellPad

            if .i = .j
                # The diagonal used the same em-dash as a cell that was
                # tested and came out non-significant with the p suppressed,
                # so "self-comparison, not applicable" and "tested, not
                # significant" rendered as the same glyph at the figure's
                # delivered scale. The diagonal now carries a centre dot,
                # which cannot be mistaken for a dash at any size, and the
                # suppressed-p cells keep the dash.
                # The diagonal glyph is drawn as text on the white cell
                # ground and was {0.7} = 2.11:1 — below the 4.5:1 text
                # minimum and below even the 3:1 floor for graphical marks,
                # which is self-defeating for a glyph introduced
                # precisely so it could not be confused with the dash.
                # {0.40} = 5.74:1 on white, still lighter than the {0.08}
                # used for the data cells.
                if .showText = 1
                    Colour: "{0.40, 0.40, 0.40}"
                    Text special: .cx, "centre", .ry, "half",
                    ... emlFont$, .scaledFont, "0", "·"
                endif

            elsif .i < .j
                .ii = .i
                .jj = .j
                .sig = annotMatrixSig'.ii'_'.jj'
                .cellText$ = annotMatrixCell'.ii'_'.jj'$

                if left$ (.cellText$, 4) = "p = "
                    .cellText$ = mid$ (.cellText$, 5, length (.cellText$) - 4)
                elsif left$ (.cellText$, 4) = "p < "
                    .cellText$ = "< " + mid$ (.cellText$, 5, length (.cellText$) - 4)
                endif

                if .sig = 1
                    Paint rectangle: .pSigBg$, .cellL, .cellR, .cellT, .cellB
                    Colour: .pSigText$
                else
                    Paint rectangle: .pNsBg$, .cellL, .cellR, .cellT, .cellB
                    Colour: .pNsText$
                endif
                if .showText = 1
                    Text special: .cx, "centre", .ry, "half",
                    ... emlFont$, .scaledFont, "0", .cellText$
                endif

            else
                .ii = .j
                .jj = .i
                if .hasEffect = 1
                    .dVal = annotMatrixD'.ii'_'.jj'
                    if .dVal <> undefined
                        .absD = abs (.dVal)
                        .dText$ = fixed$ (.absD, 2)

                        if annotMatrixEffectLabel$ = "rank-biserial r"
                            .threshLarge = 0.5
                            .threshMedium = 0.3
                        else
                            .threshLarge = 0.8
                            .threshMedium = 0.5
                        endif

                        if .absD >= .threshLarge
                            Paint rectangle: .dLargeBg$, .cellL, .cellR, .cellT, .cellB
                            Colour: .dLargeText$
                        elsif .absD >= .threshMedium
                            Paint rectangle: .dMediumBg$, .cellL, .cellR, .cellT, .cellB
                            Colour: .dMediumText$
                        else
                            Paint rectangle: .dSmallBg$, .cellL, .cellR, .cellT, .cellB
                            Colour: .dSmallText$
                        endif
                        if .showText = 1
                            Text special: .cx, "centre", .ry, "half",
                            ... emlFont$, .scaledFont, "0", .dText$
                        endif
                    endif
                endif
            endif
        endfor
    endfor

    # ----------------------------------------------------------------
    # Grid lines
    # ----------------------------------------------------------------
    Colour: "{0.75, 0.75, 0.75}"
    Line width: 0.5

    for .col from 1 to .nG - 1
        .lx = .gridLeft + .col * .cellW
        Draw line: .lx, .dataTop, .lx, .dataTop + .nG * .rowH
    endfor
    for .row from 1 to .nG - 1
        .ly = .dataTop + .row * .rowH
        Draw line: .gridLeft, .ly, .gridRight, .ly
    endfor

    # ----------------------------------------------------------------
    # Color legend — uses content-based min width (TODO-003)
    # ----------------------------------------------------------------
    if .hasEffect = 1
        .legendY = .dataTop + .nG * .rowH + .fontInch * 1.5

        .swatchW = .fontInch * 2.0
        .guY = .yMax / .vpH
        .swatchH = .swatchW * .guY

        # Measure rendered label widths at scaledFont
        Font size: .scaledFont
        .textGap = .fontInch * 1.0
        .itemGap = .fontInch * 2.5
        .textW1 = Text width (world coordinates): emlMatrixLayout_pLegend$
        .textW2 = Text width (world coordinates): "large"
        .textW3 = Text width (world coordinates): "medium"
        .textW4 = Text width (world coordinates): "small"

        .totalLegendW = 4 * (.swatchW + .textGap) + .textW1 + .textW2
        ... + .textW3 + .textW4 + 3 * .itemGap

        # Legend asserts its own minimum width from content;
        # grid width is not the sole ceiling
        .legendCeiling = max (.gridW, emlMatrixLayout_legendMinWidthInches)
        if .totalLegendW > .legendCeiling
            .scale = .legendCeiling / .totalLegendW
            .itemGap = .itemGap * .scale
            .textGap = .textGap * .scale
            .swatchW = .swatchW * .scale
            .swatchH = .swatchW * .guY
            .textW1 = .textW1 * .scale
            .textW2 = .textW2 * .scale
            .textW3 = .textW3 * .scale
            .textW4 = .textW4 * .scale
            .totalLegendW = .legendCeiling
        endif

        .legendStart = .gridCenter - .totalLegendW / 2

        .lx1 = .legendStart
        Paint rectangle: .pSigBg$, .lx1, .lx1 + .swatchW,
        ... .legendY - .swatchH / 2, .legendY + .swatchH / 2
        Colour: "{0.45, 0.45, 0.45}"
        Text special: .lx1 + .swatchW + .textGap, "left", .legendY, "half",
        ... emlFont$, .scaledFont, "0", emlMatrixLayout_pLegend$

        .lx2 = .lx1 + .swatchW + .textGap + .textW1 + .itemGap
        Paint rectangle: .dLargeBg$, .lx2, .lx2 + .swatchW,
        ... .legendY - .swatchH / 2, .legendY + .swatchH / 2
        Colour: "{0.45, 0.45, 0.45}"
        Text special: .lx2 + .swatchW + .textGap, "left", .legendY, "half",
        ... emlFont$, .scaledFont, "0", "large"

        .lx3 = .lx2 + .swatchW + .textGap + .textW2 + .itemGap
        Paint rectangle: .dMediumBg$, .lx3, .lx3 + .swatchW,
        ... .legendY - .swatchH / 2, .legendY + .swatchH / 2
        Colour: "{0.45, 0.45, 0.45}"
        Text special: .lx3 + .swatchW + .textGap, "left", .legendY, "half",
        ... emlFont$, .scaledFont, "0", "medium"

        .lx4 = .lx3 + .swatchW + .textGap + .textW3 + .itemGap
        Paint rectangle: .dSmallBg$, .lx4, .lx4 + .swatchW,
        ... .legendY - .swatchH / 2, .legendY + .swatchH / 2
        Colour: "{0.45, 0.45, 0.45}"
        Text special: .lx4 + .swatchW + .textGap, "left", .legendY, "half",
        ... emlFont$, .scaledFont, "0", "small"
    endif

    # Reset
    Colour: "Black"
    Line width: 1.0
    Font size: emlSetAdaptiveTheme.bodySize

    # Update extent tracker so @emlAssertFullViewport captures this panel
    @emlExpandDrawnExtent: .vpLeft, .vpRight, .vpTop, .vpBottom

    label END_PANEL
endproc


# ============================================================================
# THE RESULT STORE — THE READ SIDE
# ============================================================================
# Provides: @emlConsumeGroupResult, @emlStoreGroupMap, @emlBridgeStoreIdentity
#
# WHAT THIS IS FOR. docs/RULING_RESULT_STORE.md, sections (c) and (d). Drawing
# a figure that RE-RUNS the analysis it annotates puts a SECOND full report in
# the Info window — the driven defect, Ian's Kruskal-Wallis to violin session
# — and can produce different numbers from the ones the user was shown at the
# analysis door, because nothing ties the two runs together. The figure
# RECEIVES the result instead.
#
# THE VALIDITY TEST IS THE FINGERPRINT, NOT A CONSUMED-ONCE STAMP, and the
# ruling is explicit about the difference: "unlike the axis request (ruling A,
# consumed once by design), a result is legitimately consumed by many figures
# until the data or a result-affecting setting changes." So there is NO spent
# flag anywhere below, and one published result may serve a violin, a box plot
# and a bar chart of the same comparison without a word in the Info window.
#
# ============================================================================
# WHAT THIS SIDE READS, AND WHAT IT ASKS SOMEBODY ELSE
# ============================================================================
# Section (d) rules the store into published globals under a SINGLE WRITE
# SITE. This file is the READ side and it WRITES NONE OF THEM. It also does
# not re-implement either half of the validity test, because a second
# comparison is a second opinion:
#
#   THE DATA HALF is @emlStoreKeyTake plus @emlFingerprintsAgree, both in
#   stats/eml-extract.praat. @emlStoreKeyTake is the one place a group
#   comparison's key is taken -- it picks the door (@emlGroupFingerprint, two
#   column names, in that order) so that a publisher and a consumer cannot
#   key the same comparison through two different doors and miss for ever
#   without being wrong out loud. It hands back the group sort order in the
#   same call, which is the other thing both sides need.
#
#   THE SETTINGS HALF is @emlStoreIdentityAgrees, also in eml-extract.praat.
#   It compares the store's identity fields -- both columns, the test, the
#   correction, alpha, the group order -- against a candidate analysis's, and
#   NAMES THE FIRST THAT DIFFERS as a field key. Its own header says the
#   sentence is not composed there: "whoever prints owns the wording."
#
#   THE WORDING is @emlRenderResultSettings and @emlSettingsChangeNote in
#   stats/eml-output.praat. The store speaks in field keys and internal
#   tokens; a reader needs "adjustment method holm -> bonferroni".
#
# So this file contributes three things and no fourth: it decides which
# QUESTION to ask (is this publication even about this comparison?), it maps
# the store's group order onto the figure's x axis, and it says the bridge's
# analysis in the store's vocabulary so the identity comparison can be made
# at all.
#
# THE PAYLOAD IT CONSUMES, all published by @emlPublishAnalysisResult:
#
#   emlStoreFormat$ / emlStoreValid / emlStoreKind$ / emlStoreKey$
#   emlStoreTableName$ / emlStoreDataCol$ / emlStoreGroupCol$
#   emlStoreNGroups / emlStoreGroupLabel$[i]
#   emlStoreOmnibusStat / emlStoreDf1 / emlStoreDf2 / emlStoreOmnibusP
#   emlStoreEffect / emlStorePairEffectLabel$
#   emlStoreHasMatrix / emlStorePMatrix## / emlStoreEffectMatrix##
#
# A REFUSAL IS PUBLISHED TOO, and reading emlStoreValid before anything else
# is what makes that discipline worth having: a run that refused leaves
# emlStoreValid = 0 in the slot the run before it filled, so a figure drawn
# after a failed analysis computes rather than quoting the analysis before the
# failed one.
#
# ============================================================================
# THE THREE THINGS THIS READER ASSUMES OF THE WRITE SITE
# ============================================================================
# Written down together because the read side and the write side were built in
# parallel, and a reconciliation pass needs ONE block to check rather than two
# files to read.
#
#   1. emlStorePMatrix## AND emlStoreEffectMatrix## ARE INDEXED BY
#      emlStoreGroupLabel$[]. NOT by the figure's x axis -- the analysis door
#      publishes Tukey's matrix in the ANOVA's alphabetical order and its
#      labels in the same order, which is not the order @emlCountGroups
#      discovers under the shipped default. @emlStoreGroupMap therefore maps
#      LABEL BY LABEL rather than trusting either order, and a label the table
#      does not carry is a miss. That is the assumption whose failure would be
#      silent and worst -- annotBracketI[] and annotBracketJ[] are x-axis
#      POSITIONS, so a mis-indexed matrix draws a real p-value over the wrong
#      pair of violins.
#   2. THE EFFECT MATRIX IS SIGNED. Each layout applies its own sign policy
#      through @emlBridgeEffectPolicy, so a store publishing magnitudes would
#      silently make the two-group and parametric-bracket arms lose a sign
#      they have always carried in annotBracketD[]. The drawn ink is magnitude
#      either way -- @emlFormatAnnotLabel and @emlDrawMatrixPanel each take
#      abs() -- because R never puts a signed value in a compact annotation
#      and Ian has ruled we follow R's convention.
#   3. FOR TWO GROUPS THE OMNIBUS IS THE COMPARISON. emlStoreHasMatrix is 0,
#      emlStoreOmnibusP is the pair's p and emlStoreEffect its effect size.
#      The consume path builds the 2 x 2 from them.
#
# ============================================================================
# WHAT A MISMATCH DOES, AND THE FOUR ANSWERS THIS READER GIVES
# ============================================================================
# Section (c), and the part that is most easily got wrong is the REPRINT:
#
#   "consume"   the data and every result-affecting setting agree. The figure
#               draws from the store. EXACTLY ONE report exists in the Info
#               window — the one the analysis door printed — and this path
#               prints NOTHING. Never a second report; the duplicate report IS
#               the defect.
#   "settings"  the data agrees and a result-affecting setting has moved. The
#               analysis re-runs and ONE line names the change, in the
#               contract's form: "Recomputed: adjustment method holm ->
#               bonferroni." Then the updated brackets. NO second report
#               block.
#   "data"      the key does not agree. The figure re-runs — it never quietly
#               draws the stale one — and the report is reprinted under the
#               24 August line, "Data changed since this analysis was last
#               run; re-measured."
#   "none"      nothing is published, or what is published cannot answer this
#               figure's question: another table, another pair of columns,
#               another kind, a refusal, an unknown schema, or an omnibus
#               published with no post-hoc beside it. The bridge computes and
#               reports exactly as it always did, and that report is the FIRST
#               report, not a second one. A figure drawn without an analysis
#               door in front of it is the common case and it must stay
#               unchanged.
#
# A PUBLICATION ABOUT ANOTHER COMPARISON IS A MISS, NOT A CHANGED DATA SET,
# and the difference is what the user is told. The key cannot tell them apart
# -- it is one digest over the table's content AND the declared scope, so a
# mismatch says only that something in either moved -- and a reader leaning on
# it alone would answer a figure of a DIFFERENT table with "Data changed since
# this analysis was last run", a sentence about an edit nobody made. Measured
# before the guard existed, harness/bridgeconsume: a two-group figure drawn
# while a three-group publication stood said exactly that.
#
# AN OMNIBUS WITHOUT A POST-HOC IS A MISS AND NOT A HALF-HIT. A user who ran
# "One-way ANOVA, no post-hoc" from the menu and then asks a violin for its
# brackets is asking for numbers that were never computed, and lane 3.1 of the
# punch list rules that a post-hoc the user asked for is never withheld. So
# the bridge computes them, and the report it prints is the first report OF
# THAT analysis rather than a duplicate of the omnibus-only one above it.
#
# THE 24 AUGUST RULE IS ONLY HALF BUILT HERE, AND SAYING SO IS PART OF
# BUILDING IT. That rule says a re-run which reproduces the stored report
# EXACTLY should print nothing at all, and reprint only when the canonical
# report text has moved. The comparison it needs is between two rendered
# reports, and every reporter in this plugin PRINTS rather than returning
# text, so the canonical rendering would have to be captured out of the Info
# window and the reporters re-entered — which also re-runs @emlCSVInit and the
# three-file declaration. That is punch item 1.2's remaining half and it is
# not built here. What is built is the conservative direction: on a key
# mismatch the report is printed WITH the line, so a reader is told too often
# rather than too rarely. A figure never quietly draws a stale number either
# way.
# ============================================================================


# ----------------------------------------------------------------------------
# @emlBridgeStoreIdentity: .nGroups, .testType$, .correction$
# ----------------------------------------------------------------------------
# THE GRAPH DOOR'S ANALYSIS, SAID IN THE STORE'S WORDS.
#
# The menu door publishes what it ran as a test token -- "welch t",
# "mann-whitney", "one-way anova + tukey", "kruskal-wallis + dunn" -- and an
# adjustment token that is EMPTY where nothing was applied. The graph door
# knows the same thing as a test TYPE plus a group count. Two vocabularies for
# one fact, and the identity comparison needs one, so the translation happens
# here and in one direction only.
#
# WHY THIS IS NOT A HACK BUT THE POINT OF THE WHOLE ITEM. A figure and a menu
# report are supposed to be the same analysis when they are the same analysis;
# that is the unification. This procedure is where the graph door states which
# analysis it is about to run, in the words the store already uses, so the two
# doors can be asked whether they agree. Get it wrong in the loose direction
# and a figure quotes a menu run of a different test; get it wrong in the
# strict direction and the cache simply never hits.
#
# THE TOKENS ARE THE MENU DOOR'S, AND v142 HOLDS THE COPIES TOGETHER. Every
# token written below must occur as a `.stTest$ =` or `.stPostHoc$` literal in
# stats/eml-analysis.praat, which is the DRY rule this repository works to: a
# procedure records the canon and a text check enforces that the copies agree.
#
# WHAT THE BRIDGE RUNS, and it is not a choice made here -- it is read off the
# arms of @emlRunAnnotationComparison:
#
#   two groups, parametric      @emlTTest with equal variances OFF -> Welch
#   two groups, nonparametric   @emlRankBiserialR, which runs Mann-Whitney
#   k groups, parametric        @emlOneWayAnova with tukey = 1, ALWAYS
#   k groups, nonparametric     @emlKruskalWallis then @emlDunnTest, ALWAYS
#
# The two "ALWAYS" are lane 3.1's ruling that a post-hoc is never gated on the
# omnibus, so the graph door has no arm that runs an omnibus alone -- which is
# why no token below names one.
#
# THE ADJUSTMENT IS EMPTY EXCEPT ON DUNN'S. Two groups is one comparison and
# nothing is corrected; Tukey's p comes from the studentized range
# distribution and is already family-wise, and the menu door publishes ""
# there for the same reason. Publishing "holm" on a Tukey figure because the
# form's menu happened to hold it would make every Tukey figure miss against
# its own menu run.
#
# Outputs:
#   .test$        - the store's test token for what this bridge will run
#   .correction$  - the store's adjustment token, "" where none applies
# ----------------------------------------------------------------------------
procedure emlBridgeStoreIdentity: .nGroups, .testType$, .correction$
    if .nGroups <= 2
        if .testType$ = "nonparametric"
            .test$ = "mann-whitney"
        else
            .test$ = "welch t"
        endif
        .correction$ = ""
    elsif .testType$ = "nonparametric"
        .test$ = "kruskal-wallis + dunn"
    else
        .test$ = "one-way anova + tukey"
        .correction$ = ""
    endif
endproc


# ----------------------------------------------------------------------------
# @emlStoreGroupMap: .tableId, .factorCol$
# ----------------------------------------------------------------------------
# WHERE EACH OF THE FIGURE'S GROUPS SITS IN THE STORE'S MATRICES.
#
# THIS IS THE PROCEDURE THAT STOPS A p-VALUE BEING DRAWN OVER THE WRONG PAIR
# OF VIOLINS, which is the worst failure this mechanism has and the only
# silent one. annotBracketI[] and annotBracketJ[] are POSITIONS ON THE X AXIS,
# in @emlCountGroups' order. The store's matrices are indexed by
# emlStoreGroupLabel$[], which is the ANALYSIS's order -- and for a one-way
# ANOVA that is Tukey's alphabetical sort, not the table's. The bridge's own
# compute path has always had to remap for exactly this reason (.sortMap[]);
# the consume path needs the same map against the store.
#
# IT MAPS BY LABEL, NOT BY ORDER, so it makes no assumption about either
# side's sort at all: for each x-axis position, which stored index carries
# that level's label? A level the store does not name, a level named twice, or
# a count that does not match is a MISS -- the figure re-runs rather than
# guessing.
#
# @emlCountGroups IS A READ OF THE GROUPING COLUMN AND RUNS NO TEST, so this
# is not a recomputation of the analysis in the sense section (c) forbids: it
# prints nothing and computes no statistic.
#
# Output:
#   .ok        - 1 when every displayed level was found exactly once
#   .n         - the number of levels the table has now
#   .map[i]    - for x-axis position i, its index in the store's arrays
#   .label$[i] - the level's label, in x-axis order
#   .error$    - @emlCountGroups' error, passed through
# ----------------------------------------------------------------------------
procedure emlStoreGroupMap: .tableId, .factorCol$
    .ok = 0
    @emlCountGroups: .tableId, .factorCol$
    .error$ = emlCountGroups.error$
    .n = emlCountGroups.nGroups

    ; Captured immediately: @emlCountGroups' outputs live only until it runs
    ; again, and this procedure's caller goes on to call other things.
    for .g from 1 to .n
        .label$[.g] = emlCountGroups.groupLabel$[.g]
    endfor

    if .error$ <> ""
        goto END_GROUP_MAP
    endif
    if .n <> emlStoreNGroups
        goto END_GROUP_MAP
    endif

    .ok = 1
    for .g from 1 to .n
        .map[.g] = 0
        .hits = 0
        for .k from 1 to emlStoreNGroups
            if emlStoreGroupLabel$[.k] = .label$[.g]
                .map[.g] = .k
                .hits = .hits + 1
            endif
        endfor
        ; ZERO IS A LEVEL THE STORE NEVER SAW. MORE THAN ONE IS TWO STORED
        ; LEVELS SHARING A LABEL, which no analysis should produce and which
        ; would make the map a coin toss. Both are misses.
        if .hits <> 1
            .ok = 0
        endif
    endfor

    label END_GROUP_MAP
endproc


# ----------------------------------------------------------------------------
# @emlConsumeGroupResult
#
# THE READ SIDE'S ONE DOOR. Asks whether the published result answers the
# question this figure is about to ask, and hands back the payload when it
# does.
#
# Arguments — the question the FIGURE is asking, in the settings in force now:
#   .tableId, .dataCol$, .factorCol$
#   .testType$        "parametric" / "nonparametric"
#   .correction$      the RESOLVED adjustment token, never the raw global
#   .alpha            the threshold the verdicts will be taken at
#   .key$             the caller's fingerprint of the data, ALREADY TAKEN, in
#                     the pass that read it. Not taken here; see the note in
#                     the body.
#   .sort$            the store's group-order token, from the same call
#
# Outputs:
#   .verdict$   "consume" / "settings" / "data" / "none" — see WHAT A MISMATCH
#               DOES above
#   .note$      the one line to print, or "" when there is nothing to say.
#               NOT printed here: this procedure decides, the bridge speaks,
#               so that every line about one draw leaves one place.
#   .test$ / .storeCorrection$
#               this figure's analysis in the store's vocabulary, for the
#               identity comparison and for the publication
#   on "consume" only, the payload, IN X-AXIS ORDER:
#     .nGroups, .gLabel$[], .pMatrix##, .eMatrix##, .effectLabel$,
#     .omnibusStat, .df1, .df2, .omnibusP, .effect
# ----------------------------------------------------------------------------
procedure emlConsumeGroupResult: .tableId, .dataCol$, .factorCol$, .testType$, .correction$, .alpha, .key$, .sort$
    .verdict$ = "none"
    .note$ = ""
    .nGroups = 0

    ; THE KEY IS THE CALLER'S, TAKEN BEFORE IT READ A SINGLE VALUE. It is an
    ; ARGUMENT and not something taken here, and that is a rule rather than a
    ; convenience: the fingerprint's header names the one failure the module
    ; cannot see -- "a caller that computes a result, lets the table change,
    ; and only then stamps a key has stamped a truthful key on a result the
    ; table may not support" -- and the rule that closes it is that the
    ; PUBLISHER takes the key in the pass that reads the data. A reader that
    ; took its own key would take a second one, at a second moment, and the
    ; publisher's would still be the one that mattered. So there is one key
    ; per draw and the publisher owns it; validate/v138 asserts the order in
    ; every publishing procedure by text.

    ; THIS FIGURE'S ANALYSIS, IN THE STORE'S WORDS. Needed whatever the
    ; verdict: the identity comparison takes it, and so does the publication
    ; the bridge makes when it re-runs.
    @emlBridgeStoreIdentity: 0, .testType$, .correction$
    .test$ = emlBridgeStoreIdentity.test$
    .storeCorrection$ = emlBridgeStoreIdentity.correction$

    ; NOTHING PUBLISHED, OR PUBLISHED UNDER ANOTHER SCHEMA, ANOTHER KIND, OR
    ; AS A REFUSAL. Every read below a test is of a name that test has just
    ; established, which is why these are separate ifs and not one condition:
    ; Praat evaluates both sides of an `and`.
    if not variableExists ("emlStoreFormat$")
        goto END_CONSUME
    endif
    if emlStoreFormat$ <> "eRS1"
        goto END_CONSUME
    endif
    if emlStoreValid <> 1
        goto END_CONSUME
    endif
    if emlStoreKind$ <> "group"
        goto END_CONSUME
    endif

    ; ---- is the publication even ABOUT this comparison? -------------------
    ; See A PUBLICATION ABOUT ANOTHER COMPARISON above. TWO TABLES MAY SHARE A
    ; NAME -- Praat rewrites a space, a bar, a comma or a slash to an
    ; underscore, so "a b" and "a_b" are one name (the fingerprint's header
    ; measures it). A shared name here costs a "data" verdict where "none" was
    ; meant, which is a re-run either way and only ever the wrong SENTENCE.
    if emlStoreDataCol$ <> .dataCol$
        goto END_CONSUME
    endif
    if emlStoreGroupCol$ <> .factorCol$
        goto END_CONSUME
    endif
    selectObject: .tableId
    .tableName$ = selected$ ("Table")
    if emlStoreTableName$ <> .tableName$
        goto END_CONSUME
    endif

    ; A KEY THAT COULD NOT BE TAKEN IS NOT KNOWLEDGE OF A CHANGE. The
    ; fingerprint refuses a table ID that is not a positive number, which is
    ; what an uninitialised caller variable looks like, and returns "". The
    ; figure must re-run -- not known never agrees -- but it must not announce
    ; an edit it did not observe.
    if .key$ = ""
        goto END_CONSUME
    endif

    ; ---- the data half ----------------------------------------------------
    @emlFingerprintsAgree: emlStoreKey$, .key$
    if emlFingerprintsAgree.same = 0
        .verdict$ = "data"
        .note$ = "Data changed since this analysis was last run; re-measured."
        goto END_CONSUME
    endif

    ; ---- how many groups is this figure drawing? --------------------------
    ; Needed before the identity comparison, because the analysis a two-group
    ; figure runs is not the analysis a three-group figure runs even at the
    ; same test type -- Welch against one-way ANOVA. @emlStoreGroupMap reads
    ; the column once and the count comes back with the map.
    @emlStoreGroupMap: .tableId, .factorCol$
    if emlStoreGroupMap.error$ <> ""
        goto END_CONSUME
    endif
    @emlBridgeStoreIdentity: emlStoreGroupMap.n, .testType$, .correction$
    .test$ = emlBridgeStoreIdentity.test$
    .storeCorrection$ = emlBridgeStoreIdentity.correction$

    ; ---- the settings half, decided by the STORE'S OWN comparison ---------
    @emlStoreIdentityAgrees: .dataCol$, .factorCol$, .test$,
    ... .storeCorrection$, .alpha, .sort$
    if emlStoreIdentityAgrees.same = 0
        .verdict$ = "settings"
        ; The wording, from the one place the settings vocabulary lives. The
        ; rendering is asked for the CANDIDATE analysis; only its field NAMES
        ; are read, and the two values come from the comparison itself.
        @emlRenderResultSettings: "group", .dataCol$, .factorCol$, .test$,
        ... .storeCorrection$, .alpha, .sort$
        @emlSettingsVocabulary
        @emlSettingsChangeNote: emlStoreIdentityAgrees.field$,
        ... emlStoreIdentityAgrees.was$, emlStoreIdentityAgrees.now$
        .note$ = emlSettingsChangeNote.note$
        goto END_CONSUME
    endif

    ; ---- is there a pairwise result to draw? ------------------------------
    ; See AN OMNIBUS WITHOUT A POST-HOC IS A MISS. For two groups the omnibus
    ; IS the comparison and no matrix is published; for three or more, a
    ; figure needs the post-hoc the store may not have been asked for.
    if emlStoreNGroups > 2 and emlStoreHasMatrix <> 1
        goto END_CONSUME
    endif

    ; ---- the map from the x axis into the store's matrices ----------------
    if emlStoreGroupMap.ok = 0
        .verdict$ = "data"
        .note$ = "Data changed since this analysis was last run; re-measured."
        goto END_CONSUME
    endif

    ; ---- consume ----------------------------------------------------------
    .verdict$ = "consume"
    .nGroups = emlStoreGroupMap.n
    for .g from 1 to .nGroups
        .gLabel$[.g] = emlStoreGroupMap.label$[.g]
    endfor

    .omnibusStat = emlStoreOmnibusStat
    .df1 = emlStoreDf1
    .df2 = emlStoreDf2
    .omnibusP = emlStoreOmnibusP
    .effect = emlStoreEffect
    .effectLabel$ = emlStorePairEffectLabel$

    .pMatrix## = zero## (.nGroups, .nGroups)
    .eMatrix## = zero## (.nGroups, .nGroups)
    if .nGroups = 2 and emlStoreHasMatrix <> 1
        ; TWO GROUPS: THE OMNIBUS IS THE COMPARISON. Assumption 3 above. The
        ; effect size is the omnibus's, and its name is the omnibus's name --
        ; there is no pairwise label because there is no pairwise table.
        .pMatrix##[1, 2] = emlStoreOmnibusP
        .eMatrix##[1, 2] = emlStoreEffect
        .effectLabel$ = emlStoreEffectLabel$
    else
        ; INTO X-AXIS ORDER, THROUGH THE MAP, AND WITH NO SIGN ARITHMETIC.
        ; The store's matrices are FULL rather than triangular: the pairwise
        ; kernels fill [i,j] and [j,i] together, p symmetrically and the
        ; effect size ANTI-symmetrically ("dMatrix##[.j, .i] = -emlCohenD.d",
        ; stats/eml-inferential.praat). So the map may send an x-axis pair to
        ; a stored pair in either direction and the cell read is already the
        ; right number with the right sign. Negating one here to "correct" an
        ; inverted pair would flip a sign that was never wrong -- which is the
        ; mistake this note exists to stop somebody making later. The bridge's
        ; own compute path has always read its Tukey matrix the same way, with
        ; .sortMap[] and no ordering test.
        for .i from 1 to .nGroups - 1
            for .j from .i + 1 to .nGroups
                .si = emlStoreGroupMap.map[.i]
                .sj = emlStoreGroupMap.map[.j]
                .pMatrix##[.i, .j] = emlStorePMatrix##[.si, .sj]
                .eMatrix##[.i, .j] = emlStoreEffectMatrix##[.si, .sj]
            endfor
        endfor
    endif

    label END_CONSUME
endproc


# ============================================================================
# BRIDGE PROCEDURES
# ============================================================================


# ----------------------------------------------------------------------------
# @emlBridgeOmnibusLine: .nGroups, .testType$, .stat, .df1, .df2, .p, .effect
# ----------------------------------------------------------------------------
# THE OMNIBUS LINE THE FIGURE CARRIES, IN ONE PLACE.
#
# It is the string drawn in the figure's corner box and, on a matrix layout,
# the panel's title; it is also the string the workflow recorder writes down
# beside the step, deliberately, so the record carries exactly what the reader
# saw on the plot. Four arms composed it in four places, and the store adds a
# fifth path that has the numbers and no arm to compose it — which is how a
# figure drawn from a stored result would come to describe its omnibus in
# different words from the same figure drawn from a re-run.
#
# WHAT EACH ARGUMENT HOLDS FOLLOWS THE TEST, and this procedure is the one
# place that knows the mapping. It is also the mapping the store's published
# omnibus fields are read through, so the two cannot part company:
#
#   two groups, nonparametric   .stat = Mann-Whitney U, .effect = rank-
#                               biserial r; .df1 and .df2 unused
#   two groups, parametric      .stat = Welch's t, .df1 = its df (a REAL
#                               number, printed to one decimal), .effect =
#                               Cohen's d, which may be undefined and is then
#                               left off the line
#   k groups, nonparametric     .stat = H, .df1 = its df (an integer),
#                               .effect = epsilon squared
#   k groups, parametric        .stat = F, .df1 = df between, .df2 = df
#                               within; .effect is not shown — the one-way
#                               ANOVA line has never carried an effect size
#                               and adding one here would change every
#                               annotated ANOVA figure in the tree
#
# THE SYMBOL ESCAPES ARE PRAAT'S AND ARE DELIBERATE. This string is only ever
# DRAWN, by Text or Text special, so "\ep" renders epsilon and "^2"
# superscripts the 2. It reached the Info window as well by way of the
# recorder's note, which is why nothing here is variable-derived text needing
# @emlSanitizeLabel: every character is a literal or a number.
#
# Output:
#   .result$ - the line
# ----------------------------------------------------------------------------
procedure emlBridgeOmnibusLine: .nGroups, .testType$, .stat, .df1, .df2, .p, .effect
    @emlFormatP: .p
    .pText$ = emlFormatP.formatted$

    if .nGroups <= 2
        if .testType$ = "nonparametric"
            .result$ = "Mann-Whitney: U = " + fixed$ (.stat, 1)
            ... + ", " + .pText$
            ... + ", r = " + fixed$ (.effect, 2)
        else
            .result$ = "Welch t: t(" + fixed$ (.df1, 1) + ") = "
            ... + fixed$ (.stat, 2)
            ... + ", " + .pText$
            if .effect <> undefined
                .result$ = .result$ + ", d = " + fixed$ (.effect, 2)
            endif
        endif
    else
        if .testType$ = "nonparametric"
            .result$ = "Kruskal-Wallis: H(" + string$ (.df1) + ") = "
            ... + fixed$ (.stat, 2)
            ... + ", " + .pText$
            ... + ", \ep^2 = " + fixed$ (.effect, 3)
        else
            .result$ = "One-way ANOVA: F(" + string$ (.df1) + ", "
            ... + string$ (.df2) + ") = "
            ... + fixed$ (.stat, 2)
            ... + ", " + .pText$
        endif
    endif
endproc


# ----------------------------------------------------------------------------
# @emlBridgeEffectPolicy: .nGroups, .testType$
# ----------------------------------------------------------------------------
# WHICH EFFECT SIZE THIS COMPARISON HAS, WHAT IT IS CALLED, AND WHAT SIGN THE
# STORED NUMBER CARRIES. Four arms of @emlRunAnnotationComparison answered these
# three questions in four places; they are answered here once, so the arm that
# COMPUTES the result and the path that CONSUMES a stored one cannot drift.
#
# THE SIGN POLICY IS PRESERVED, NOT TIDIED, AND THE ASYMMETRY IS REAL. The
# four arms have always filled annotBracketD[] and annotMatrixD*_* with
# different signs for the same kind of number:
#
#   two groups, either test    bracket SIGNED, matrix SIGNED
#   k groups, nonparametric    bracket |r|,    matrix |r|
#   k groups, parametric       bracket SIGNED, matrix |d|
#
# THE DRAWN INK IS MAGNITUDE IN EVERY ONE OF THEM, and that is the ruled
# convention: @emlFormatAnnotLabel takes abs() of whatever effect size it is
# handed before it writes a bracket label, and @emlDrawMatrixPanel takes abs()
# again before it writes a cell — because R never puts a signed value in a
# compact annotation and Ian has ruled we follow R's convention. So nothing
# about a FIGURE depends on the table above.
#
# What does depend on it is the NUMBER LEFT BEHIND in annotBracketD[] and
# annotMatrixD*_*, which the recorder emits and harness/settingspub reads. So
# the table is reproduced exactly rather than unified: unifying it would move
# recorded numbers for no ruled reason, and the place to settle it is the
# store's own published effect matrix, which is SIGNED once and lets each
# layout take what it needs (v112's census note on layoutMode says so).
#
# Outputs:
#   .label$   - the effect size's name for the matrix legend
#   .symbol$  - its short name for a bracket label ("d" / "r")
#   .bracketAbs / .matrixAbs
#             - 1 when that layout stores the magnitude, 0 when it stores the
#               signed value
# ----------------------------------------------------------------------------
procedure emlBridgeEffectPolicy: .nGroups, .testType$
    if .testType$ = "nonparametric"
        .label$ = "rank-biserial r"
        .symbol$ = "r"
    else
        .label$ = "Cohen's d"
        .symbol$ = "d"
    endif

    if .nGroups <= 2
        .bracketAbs = 0
        .matrixAbs = 0
    elsif .testType$ = "nonparametric"
        .bracketAbs = 1
        .matrixAbs = 1
    else
        .bracketAbs = 0
        .matrixAbs = 1
    endif
endproc


# ----------------------------------------------------------------------------
# @emlBridgeRenderAnnotations
# ----------------------------------------------------------------------------
# THE ONE PLACE A GROUP COMPARISON BECOMES AN ANNOTATION.
#
# WHY IT EXISTS. Before the result store, each of @emlRunAnnotationComparison's
# four arms computed its statistics and then rendered them, inline, in its own
# copy of the same two loops — four copies of the bracket loop and four of the
# matrix loop, differing in which procedure supplied the numbers. The store
# adds a FIFTH path that has the numbers already and must render them the same
# way, and a fifth copy of a loop that exists four times is how a figure drawn
# from the store starts disagreeing with the same figure drawn from a re-run.
# So the rendering is one procedure and every path calls it: the arms build
# the two matrices and hand them over, and the consume path hands over the
# matrices the store published.
#
# THE SPLIT IS NUMBERS / DISPLAY, AND THAT IS THE STORE'S SPLIT TOO. What
# arrives here is the result — p-values and effect sizes per pair, in display
# order — and what is applied here is the display: the label style, whether
# non-significant pairs are drawn, whether effect sizes are shown, alpha's
# verdict, and brackets against a matrix. Those five are v112's DISPLAY_ONLY
# list for this door, which is exactly why a stored result may be redrawn
# under any of them without re-running anything.
#
# THE GROUP LABELS ARE READ FROM emlRunAnnotationComparison.gLabel$[]. Praat
# cannot pass an array to a procedure, so the labels cannot be an argument;
# and inventing a second global array to carry them would be a second place
# the display order lives. The bridge captures those labels at entry
# precisely because they must survive every procedure call underneath it, so
# reading them here is reading the copy that was made to be read.
#
# ALPHA'S VERDICT IS GUARDED AGAINST AN UNDEFINED p ON EVERY CELL. An
# undefined p is not a comparison, and without the guard the cell TEXT and the
# cell STYLING can disagree — a cell reading "p = --undefined--" painted as
# significant. The parametric k-group arm already carried this guard and
# called it "the single, careful form of the check, applied uniformly to every
# cell"; uniformly is what it now is.
#
# Arguments:
#   .nGroups      - levels, and the order of both matrices
#   .useMatrix    - 1 for the comparison-matrix panel, 0 for brackets
#   .style$       - "p-value", "stars" or "both"
#   .showNS       - 1 draws non-significant pairs, 0 suppresses them
#   .showEffect   - 1 publishes effect sizes to the annotation, 0 does not
#   .alpha        - the threshold the verdict is taken at
#   .effectLabel$ / .effectSymbol$ / .bracketAbs / .matrixAbs
#                 - from @emlBridgeEffectPolicy
#   .omnibus$     - the omnibus line, drawn in the corner box in both layouts
#   .p##          - pairwise p, [i,j] for i < j, in display order
#   .e##          - pairwise SIGNED effect size, same shape and order.
#                   undefined where none could be computed; a missing effect
#                   size is a blank cell, never a failed annotation.
#
# Output: the annotBracket*, annotMatrix* and annotText* globals.
# ----------------------------------------------------------------------------
procedure emlBridgeRenderAnnotations: .nGroups, .useMatrix, .style$, .showNS, .showEffect, .alpha, .effectLabel$, .effectSymbol$, .bracketAbs, .matrixAbs, .omnibus$, .p##, .e##
    if .useMatrix = 1
        annotMatrixN = .nGroups
        annotMatrixOmnibus$ = .omnibus$
        if .showEffect = 1
            annotMatrixEffectLabel$ = .effectLabel$
        else
            annotMatrixEffectLabel$ = ""
        endif
        for .i from 1 to .nGroups
            annotMatrixLabel$[.i] = emlRunAnnotationComparison.gLabel$[.i]
        endfor

        for .i from 1 to .nGroups - 1
            for .j from .i + 1 to .nGroups
                .pairP = .p##[.i, .j]

                @emlFormatAnnotLabel: .pairP, undefined, .style$, 0, ""
                annotMatrixCell'.i'_'.j'$ = emlFormatAnnotLabel.result$

                annotMatrixSig'.i'_'.j' = 0
                if .pairP <> undefined
                    if .pairP < .alpha
                        annotMatrixSig'.i'_'.j' = 1
                    endif
                endif
                if annotMatrixSig'.i'_'.j' = 0 and .showNS = 0
                    annotMatrixCell'.i'_'.j'$ = "—"
                endif

                annotMatrixD'.i'_'.j' = undefined
                if .showEffect = 1
                    .cellD = .e##[.i, .j]
                    if .cellD <> undefined and .matrixAbs = 1
                        .cellD = abs (.cellD)
                    endif
                    annotMatrixD'.i'_'.j' = .cellD
                endif
            endfor
        endfor
    else
        annotBracketN = 0
        for .i from 1 to .nGroups - 1
            for .j from .i + 1 to .nGroups
                .pairP = .p##[.i, .j]

                .pairD = undefined
                if .showEffect = 1
                    .pairD = .e##[.i, .j]
                    if .pairD <> undefined and .bracketAbs = 1
                        .pairD = abs (.pairD)
                    endif
                endif

                .draw = 0
                if .showNS = 1
                    .draw = 1
                elsif .pairP <> undefined
                    if .pairP < .alpha
                        .draw = 1
                    endif
                endif

                if .draw = 1
                    annotBracketN = annotBracketN + 1
                    .bIdx = annotBracketN
                    annotBracketI[.bIdx] = .i
                    annotBracketJ[.bIdx] = .j
                    annotBracketP[.bIdx] = .pairP
                    annotBracketD[.bIdx] = .pairD
                    @emlFormatAnnotLabel: .pairP, .pairD, .style$, .showEffect,
                    ... .effectSymbol$
                    annotBracketLabel$[.bIdx] = emlFormatAnnotLabel.result$
                endif
            endfor
        endfor
        @emlStackBrackets
    endif

    ; THE OMNIBUS IN THE CORNER BOX, IN BOTH LAYOUTS. Every arm set this and
    ; every arm set it identically; the matrix panel draws its own omnibus as
    ; a title line and the form's post-dispatch stage skips the corner block
    ; whenever annotMatrixN > 0, so the matrix path is governed by the form's
    ; gate rather than by a second rule here.
    annotTextN = 1
    annotTextX[1] = 0
    annotTextY[1] = 0
    annotTextLabel$[1] = .omnibus$
    annotTextAnchor$[1] = "right"
endproc


# ----------------------------------------------------------------------------
# @emlBridgePairEffect: .tableId, .dataCol$, .factorCol$, .g1$, .g2$, .testType$
# ----------------------------------------------------------------------------
# ONE PAIR'S SIGNED EFFECT SIZE, for the matrix @emlBridgeRenderAnnotations
# is handed. Cohen's d on the parametric arm, rank-biserial r on the
# nonparametric one, always SIGNED — the sign policy is applied where the
# annotation is built, not here.
#
# A PAIR THAT CANNOT BE MEASURED COMES BACK undefined AND IS NOT AN ERROR.
# Before the store the effect sizes were computed inside the render loop and a
# failure there set the bridge's .error$, which threw the WHOLE annotation
# away — every bracket and every p-value — because one pair's effect size
# could not be formed. The p-values do not depend on it, the matrix panel and
# the bracket label both already skip an undefined effect size, and a figure
# with one blank effect cell is a better answer than no figure. So the failure
# is local and silent-by-construction rather than fatal.
# ----------------------------------------------------------------------------
procedure emlBridgePairEffect: .tableId, .dataCol$, .factorCol$, .g1$, .g2$, .testType$
    .value = undefined

    @eml_getGroupData: .tableId, .dataCol$, .factorCol$, .g1$
    if eml_getGroupData.error$ <> ""
        goto END_PAIR_EFFECT
    endif
    .v1# = eml_getGroupData.data#

    @eml_getGroupData: .tableId, .dataCol$, .factorCol$, .g2$
    if eml_getGroupData.error$ <> ""
        goto END_PAIR_EFFECT
    endif
    .v2# = eml_getGroupData.data#

    if .testType$ = "nonparametric"
        @emlRankBiserialR: .v1#, .v2#, 2
        if emlRankBiserialR.error$ = ""
            .value = emlRankBiserialR.r
        endif
    else
        @emlCohenD: .v1#, .v2#
        if emlCohenD.error$ = ""
            .value = emlCohenD.d
        endif
    endif

    label END_PAIR_EFFECT
endproc


# ----------------------------------------------------------------------------
# @emlRunAnnotationComparison
# For bar chart, violin, box plot, and grouped violin: detect number of
# groups, run the appropriate statistical test, populate bracket or matrix
# annotations.
#
# When .forceMatrix = 1 OR nGroups >= 4: populates annotMatrix* globals.
# When .forceMatrix = 0 AND nGroups <= 3: populates annotBracket* arrays.
#
# Arguments:
#   .tableId     — Table object ID
#   .dataCol$    — numeric data column name
#   .factorCol$  — group/factor column name
#   .alpha       — significance threshold (e.g., 0.05)
#   .style$      — "p-value", "stars", or "both"
#   .showNS      — 1 = show non-significant brackets, 0 = hide
#   .showEffect  — 1 = show effect sizes, 0 = hide
#   .testType$   — "parametric" or "nonparametric"
#   .forceMatrix — 1 = always use matrix output, 0 = auto (brackets ≤3)
#
# Output: populates annotBracket* or annotMatrix* global arrays.
#   Also sets:
#     .omnibus$  — formatted omnibus test result string (for Info window)
#     .error$    — "" on success, diagnostic message on failure
#
#   AND THE READ SIDE'S ANSWER (docs/RULING_RESULT_STORE.md sections c and d):
#     .verdict$      "consume" / "settings" / "data" / "none". What the store
#                    said about the question this figure asked; see
#                    @emlConsumeGroupResult.
#     .consumed      1 when the figure was drawn FROM the store and no test
#                    ran here at all.
#     .printReport   what the caller must do about the Info-window report.
#                    1 = print it, this is the first report of this result;
#                    0 = do not, either it already exists or the only thing to
#                    say was the one-line announcement. The caller obeys this
#                    and adds no rule of its own; see
#                    @emlGraphsReportBridgeIfNew.
#     .note$         the one line, when there is one to say.
#     .notePending   ITEM 1.2. 1 when .note$ still has to be PRINTED by the
#                    caller, above the report. The settings line is printed
#                    here, as it always was, because it is the whole of what
#                    that path says; the 24 August data line is NOT, because
#                    whether it is said at all depends on a comparison that
#                    is not finished when that verdict is taken.
#     .canonReport$  ITEM 1.2. The canonical rendering of the report this run
#                    would print — factual and disclosure lines only, no
#                    explanations, no timestamp — or "" when this run prints
#                    no report. Published as emlStoreReport$.
#     .key$          the data fingerprint, taken at the top of this procedure
#                    and before it read one value by group.
#     .hasPairwise   1 once a pairwise result exists to draw and to publish.
# ----------------------------------------------------------------------------
procedure emlRunAnnotationComparison: .tableId, .dataCol$, .factorCol$, .alpha, .style$, .showNS, .showEffect, .testType$, .layoutMode
    # .layoutMode: 1 = auto, 2 = force brackets, 3 = force matrix
    .omnibus$ = ""
    .error$ = ""

    ; ------------------------------------------------------------------
    ; THE READ SIDE. docs/RULING_RESULT_STORE.md sections (c) and (d):
    ; this procedure RECEIVES the analysis's result when the published one
    ; still answers the question, and re-runs when it does not.
    ;
    ; .consumed     1 when the figure was drawn from the store and no test
    ;               was run here at all.
    ; .printReport  what the CALLER should do about the Info-window report.
    ;               1 = print it (this is the first and only report for this
    ;               result); 0 = do not (either the report already exists, or
    ;               the only thing to say is the one-line announcement).
    ;               The bridge decides and the caller obeys, because the
    ;               caller is the one holding @emlReportBridgeStats.
    ; .note$        the one line, already printed here if there was one. Kept
    ;               as an output so a harness can read what was said.
    ; .verdict$     "consume" / "settings" / "data" / "none"; see
    ;               @emlConsumeGroupResult.
    ; ------------------------------------------------------------------
    .consumed = 0
    .printReport = 1
    .note$ = ""
    ; ITEM 1.2 — see .notePending in the header above.
    .notePending = 0
    .verdict$ = "none"
    ; 1 once a pairwise result exists in .pRes##/.eRes## -- which is not the
    ; same as "no error". A Dunn's post-hoc that failed, and an ANOVA with no
    ; pairs, both leave the omnibus on the figure and no matrix behind them,
    ; and there is nothing for the store to publish in either case.
    .hasPairwise = 0

    ; RESOLVED BEFORE THE STORE IS ASKED, and that ordering is the point.
    ; The store records the RESOLVED adjustment token, so two runs that both
    ; fell back to holm are the same settings and must agree; comparing the
    ; raw global would re-run an analysis because an unrecognised value had
    ; been spelled two different wrong ways.
    #
    # Resolve the p-value correction method for Dunn's post-hoc test.
    # annotCorrectionMethod$ is normally set by the graphs form, but this
    # bridge is also called directly by scripts that never touch that form.
    # Default to "holm" (the R default for p.adjust) and reject anything
    # @emlDunnTest would not accept, rather than aborting on an unset global.
    .correction$ = "holm"
    if variableExists ("annotCorrectionMethod$")
        if annotCorrectionMethod$ = "bonferroni" or annotCorrectionMethod$ = "holm" or annotCorrectionMethod$ = "bh"
            .correction$ = annotCorrectionMethod$
        else
            if annotCorrectionMethod$ <> ""
                .warnHead$ = "NOTE: unrecognised annotCorrectionMethod$ '"
                .warnTail$ = "' — using holm."
                appendInfoLine: .warnHead$ + annotCorrectionMethod$ + .warnTail$
            endif
        endif
    endif

    ; ------------------------------------------------------------------
    ; ITEM 3.5 -- THE POST-HOC CHOICE, RESOLVED FROM THE LAUNCHING DIALOG.
    ;
    ; THE RULE. A figure runs the post-hoc its user asked for, and only that
    ; one. There are exactly two places in this file where that decision is
    ; spent -- the @emlOneWayAnova call on the parametric k >= 3 arm below,
    ; and @emlReportBridgeStats' report and declarations -- and NEITHER MAY
    ; CARRY A LITERAL. A literal at either site draws a Tukey post-hoc onto
    ; every parametric k >= 3 figure whatever the user asked for, which is a
    ; silent disagreement between this door and the analysis door on the same
    ; data: validate/v127's leg1 (the Pairwise dialog set to Student t with
    ; Bonferroni) and leg3 (Compare k Groups with the post-hoc unticked). It
    ; is Fable's 26 Aug ruling that both sites take THE LAUNCHING DIALOG'S
    ; ACTUAL POST-HOC CHOICE, adding the field if none exists -- and a
    ; different literal, or a default computed here, satisfies neither site.
    ;
    ; THE CHANNEL IS annotPostHoc, and it is the channel annotCorrectionMethod$
    ; already uses a few lines above, for the same reason: this procedure's
    ; argument list is fixed by four call sites in eml-graphs-form.praat and by
    ; every user script that calls the bridge directly, so a tenth positional
    ; argument would break all of them. The graphs form's Comparison menu now
    ; carries an "ANOVA only, no pairwise tests" row and commits its answer to
    ; annotPostHoc (graphs/eml-graphs-form.praat, @emlComparisonFromMenu and
    ; the six column-mapping pages that read it). Search for the assignment,
    ; not for a line number.
    ;
    ; DEFAULT 1, AND THAT IS NOT A DISGUISED LITERAL. A caller that never
    ; touched the graphs form -- a user script, a harness probe -- has no
    ; annotPostHoc to read, and the behaviour it is entitled to is the
    ; behaviour it had before this item: run the post-hoc. What changed is
    ; that a form which DOES state a choice can now be obeyed, which is the
    ; whole of the item. Read through variableExists and in NESTED ifs, never
    ; `and`: Praat evaluates both operands, so one condition would read a
    ; global that a tree without the form has never set.
    ; ------------------------------------------------------------------
    .doTukey = 1
    if variableExists ("annotPostHoc")
        if annotPostHoc = 0
            .doTukey = 0
        endif
    endif

    ; THE KEY, TAKEN HERE AND BEFORE THIS PROCEDURE READS ONE VALUE BY GROUP.
    ; That order is the whole of the rule: the fingerprint's header names "a
    ; caller that computes a result, lets the table change, and only then
    ; stamps a key" as the one failure it cannot see from the inside, and puts
    ; the fix on the publisher -- take the key in the same pass that reads the
    ; data. This procedure is a publisher, so it takes its own, once, at the
    ; top, and both the consume check and the publication at the foot use that
    ; one key. @emlStoreKeyTake is also the one place a group comparison's key
    ; door is chosen, so a publisher and a consumer cannot key one comparison
    ; two different ways and miss for ever without being wrong out loud.
    ;
    ; Copied out of the procedure's outputs immediately: the arms below call a
    ; great deal of code before the publication reads them.
    @emlStoreKeyTake: .tableId, .dataCol$, .factorCol$
    .keyError$ = emlStoreKeyTake.error$
    .key$ = emlStoreKeyTake.key$
    .sort$ = emlStoreKeyTake.sort$

    @emlConsumeGroupResult: .tableId, .dataCol$, .factorCol$, .testType$,
    ... .correction$, .alpha, .key$, .sort$
    .verdict$ = emlConsumeGroupResult.verdict$
    .note$ = emlConsumeGroupResult.note$
    .storeTest$ = emlConsumeGroupResult.test$
    .storeCorrection$ = emlConsumeGroupResult.storeCorrection$

    if .verdict$ = "consume"
        ; NOTHING IS PRINTED ON THIS PATH. Exactly one report exists in the
        ; Info window and the analysis door printed it; a second one is the
        ; defect this whole mechanism was built to remove.
        .consumed = 1
        .printReport = 0
        .nGroups = emlConsumeGroupResult.nGroups
        for .gi from 1 to .nGroups
            .gLabel$[.gi] = emlConsumeGroupResult.gLabel$[.gi]
        endfor
        .pRes## = emlConsumeGroupResult.pMatrix##
        .eRes## = emlConsumeGroupResult.eMatrix##
        .storeEffectLabel$ = emlConsumeGroupResult.effectLabel$
        ; THE OMNIBUS LINE IS COMPOSED, NOT COPIED. The store publishes the
        ; omnibus as NUMBERS -- the statistic, its degrees of freedom, its p
        ; and its effect size -- and @emlBridgeOmnibusLine is the one place
        ; that turns those into the sentence a figure carries. Copying a
        ; pre-formatted string out of the store instead would put a second
        ; formatter in the tree and let the two drift; composing it here
        ; means a consumed figure and a recomputed figure are the same
        ; characters.
        .omniStat = emlConsumeGroupResult.omnibusStat
        .omniDf1 = emlConsumeGroupResult.df1
        .omniDf2 = emlConsumeGroupResult.df2
        .omniP = emlConsumeGroupResult.omnibusP
        .omniEffect = emlConsumeGroupResult.effect
        @emlBridgeOmnibusLine: .nGroups, .testType$, .omniStat, .omniDf1,
        ... .omniDf2, .omniP, .omniEffect
        .omnibus$ = emlBridgeOmnibusLine.result$
    elsif .verdict$ = "settings"
        ; ONE LINE, NAMING THE CHANGE, AND THEN THE UPDATED BRACKETS. No
        ; second report block: section (c) of the ruling is a contract about
        ; this exact line.
        .printReport = 0
        appendInfoLine: .note$
    elsif .verdict$ = "data"
        ; THE KEY DOES NOT AGREE, SO THE FIGURE RE-RUNS. It never quietly
        ; draws the stale one.
        ;
        ; ITEM 1.2 — AND THE LINE IS NOT PRINTED HERE ANY MORE. Ian's rule of
        ; 24 August is that THE REPORT COMPARISON, NOT THE KEY, DECIDES WHAT
        ; THE USER SEES, and "a re-run that reproduces the stored report
        ; exactly prints nothing" means nothing at all — not the report and
        ; not the line above it. The key has told us the data moved; it has
        ; not told us anything the reader can see has changed. That is
        ; settled a few hundred lines below, once this run has actually
        ; computed and been rendered, so the line waits in .notePending and
        ; @emlGraphsReportBridgeIfNew prints it if there turns out to be
        ; something to print it above.
        ;
        ; THE DEFECT THIS CLOSES, driven: publish a Kruskal-Wallis result,
        ; move one value from 10.1 to 10.2 — still the smallest value in its
        ; group, still above every other point, so not one rank moves — and
        ; the figure printed this line and a second complete 62-line report
        ; identical to the first. See harness/reprintpins' third leg.
        .notePending = 1
    endif

    if .consumed = 0
        # --- Count groups ---
        @emlCountGroups: .tableId, .factorCol$
        if emlCountGroups.error$ <> ""
            .error$ = emlCountGroups.error$
        endif

        .nGroups = emlCountGroups.nGroups

        # Capture the group labels into procedure-locals IMMEDIATELY. Praat
        # procedure outputs survive only until the same procedure runs again, and
        # @emlCountGroups is re-invoked internally by @emlDunnTest,
        # @emlOneWayAnova, @emlKruskalWallis and @emlTukeyHSD — so
        # emlCountGroups.groupLabel$[] must not be read after any of those calls.
        for .gi from 1 to .nGroups
            .gLabel$[.gi] = emlCountGroups.groupLabel$[.gi]
        endfor
    endif

    if .error$ = "" and .nGroups < 2
        .error$ = "Need at least 2 groups for comparison"
    endif

    if .error$ = "" and .nGroups > 10
        appendInfoLine: "NOTE: ", .nGroups, " groups detected. "
        ... + "Comparison matrix may be difficult to read at this size."
    endif

    # Determine output mode: brackets or matrix
    if .layoutMode = 3
        .useMatrix = 1
    elsif .layoutMode = 2
        .useMatrix = 0
    else
        # Auto: brackets for k=2, matrix for k>=3
        .useMatrix = 0
        if .nGroups >= 3
            .useMatrix = 1
        endif
    endif

    ; ------------------------------------------------------------------
    ; THE FIGURE'S DISCLOSURE — THE THREE CAPTION LINES, SET ON EVERY PATH.
    ;
    ; Per the 7 August unification ruling, carried into section (c) of
    ; docs/RULING_RESULT_STORE.md: "the figure's disclosure and the recorded
    ; script carry the settings the DRAWN statistics actually used, so a
    ; reader of the figure never needs the Info window's history to know what
    ; the brackets mean." These three lines are that disclosure — the pairwise
    ; test that produced the p-values, and what was or was not done about
    ; multiplicity — and they are drawn by @emlDrawBracketCaption under the
    ; brackets and by @emlDrawMatrixPanel under the matrix.
    ;
    ; THEY ARE SET HERE, BEFORE THE ARMS, BECAUSE THE STORE ADDED A PATH THAT
    ; RUNS NO ARM. An arm that wrote its own captions beside its own test
    ; would leave a figure drawn from a stored result carrying whatever the
    ; last figure left in these globals — a Tukey caption over Dunn's
    ; brackets, which is precisely the disagreement the store exists to end.
    ; The words, and which arm each belongs to, are the arm's; each arm keeps
    ; the note explaining its own sentence, and this block is where the three
    ; are set.
    ;
    ; WHAT THEY SAY IS DECIDED BY THE SETTINGS ACTUALLY IN FORCE: .testType$
    ; as the figure was asked for it, .nGroups as the data has it, and
    ; .correction$ as this procedure RESOLVED it — so a figure drawn after an
    ; unrecognised annotCorrectionMethod$ says "holm" and means it. On the
    ; consume path those three are the stored result's own settings, because
    ; a difference in any of them would have forced a re-run before reaching
    ; here.
    ;
    ; THE ADJUSTMENT SENTENCE IS DIFFERENT ON EVERY ARM AND THAT ASYMMETRY IS
    ; THE POINT. Tukey's p is already family-wise over the set of pairwise
    ; comparisons; Dunn's z-tests carry no family-wise control of their own
    ; and name the method the user chose; two groups is one comparison and
    ; there is no family at all. One sentence covering all three would be
    ; false on two of them whichever way it was written.
    ; ------------------------------------------------------------------
    if .error$ = "" and .nGroups >= 2
        if .nGroups = 2
            if .testType$ = "nonparametric"
                annotMatrixPosthoc$ = "Mann-Whitney U"
                annotBracketPosthoc$ = "Comparison: Mann-Whitney U test"
                annotBracketAdjust$ = "one comparison; no adjustment "
                ... + "applied"
            else
                annotMatrixPosthoc$ = "Welch t-test"
                annotBracketPosthoc$ = "Comparison: Welch t-test"
                annotBracketAdjust$ = "one comparison; no adjustment "
                ... + "applied"
            endif
        else
            if .testType$ = "nonparametric"
                annotMatrixPosthoc$ = "Dunn's test ("
                ... + .correction$ + ")"
                annotBracketPosthoc$ = "Pairwise comparisons: Dunn's test"
                annotBracketAdjust$ = "adjustment for multiple "
                ... + "comparisons: " + .correction$
            else
                annotMatrixPosthoc$ = "Tukey HSD (already family-wise)"
                annotBracketPosthoc$ = "Pairwise comparisons: Tukey HSD"
                annotBracketAdjust$ = "already family-wise; no further "
                ... + "adjustment applied"
            endif
        endif
    endif

    ; ------------------------------------------------------------------
    ; THE CONSUME PATH'S RENDERING. The store holds NUMBERS -- pairwise p
    ; and pairwise signed effect size, in display order -- and every display
    ; setting is applied here, at draw time, by the same procedure the
    ; compute arms call. That is what lets one published result serve many
    ; figures at different styles, layouts and effect-size settings without
    ; re-running anything, which is exactly what section (d) means by "a
    ; result is legitimately consumed by many figures".
    ; ------------------------------------------------------------------
    ; ------------------------------------------------------------------
    ; ITEM 3.5 -- THE OPT-OUT HAS TO HOLD ON THE CONSUME PATH TOO, or the fix
    ; is only half a fix. The store publishes a Tukey result whenever the
    ; ANALYSIS door ran one, and that result is legitimately consumed by many
    ; figures. Without this branch a user who ran Compare k Groups WITH the
    ; post-hoc, then drew a figure having picked "ANOVA only, no pairwise
    ; tests", would get Tukey brackets anyway -- drawn out of the store
    ; instead of out of a fresh @emlOneWayAnova, but drawn all the same, and
    ; that is v127's leg3 wearing the store as a costume.
    ;
    ; IT WITHHOLDS NOTHING AND RE-RUNS NOTHING. The stored result is not
    ; discarded, not re-measured and not contradicted; the figure simply
    ; carries the omnibus the user asked for. Two groups is untouched: there
    ; the omnibus IS the comparison and there is no post-hoc to decline. The
    ; nonparametric arm is untouched as well -- Dunn's is not a doTukey site
    ; and its own opt-out is not this item.
    ; ------------------------------------------------------------------
    ;
    ; The condition is built on its own line rather than continued with
    ; `...`, which this file reserves for argument lists.
    .optedOutOfPostHoc = 0
    if .doTukey = 0 and .nGroups > 2 and .testType$ <> "nonparametric"
        .optedOutOfPostHoc = 1
    endif
    if .consumed = 1 and .error$ = "" and .optedOutOfPostHoc = 1
        annotTextN = 1
        annotTextX[1] = 0
        annotTextY[1] = 0
        annotTextLabel$[1] = .omnibus$
        annotTextAnchor$[1] = "right"
    elsif .consumed = 1 and .error$ = "" and .nGroups >= 2
        .hasPairwise = 1
        @emlBridgeEffectPolicy: .nGroups, .testType$
        ; The store's own name for the pairwise effect size, so the matrix
        ; legend says what the analysis door said. A store that published no
        ; name -- a two-group result, where the effect size is the omnibus's
        ; -- falls back to the policy's name rather than to an empty legend.
        .effLabel$ = .storeEffectLabel$
        if .effLabel$ = ""
            .effLabel$ = emlBridgeEffectPolicy.label$
        endif
        .effSymbol$ = emlBridgeEffectPolicy.symbol$
        .effBracketAbs = emlBridgeEffectPolicy.bracketAbs
        .effMatrixAbs = emlBridgeEffectPolicy.matrixAbs

        @emlBridgeRenderAnnotations: .nGroups, .useMatrix, .style$,
        ... .showNS, .showEffect, .alpha, .effLabel$, .effSymbol$,
        ... .effBracketAbs, .effMatrixAbs, .omnibus$, .pRes##, .eRes##
    endif

    # =================================================================
    # 2-GROUP COMPARISON
    # =================================================================

    if .consumed = 0 and .error$ = "" and .nGroups = 2
        .label1$ = emlCountGroups.groupLabel$[1]
        .label2$ = emlCountGroups.groupLabel$[2]

        @emlExtractGroupVectors: .tableId, .dataCol$, .factorCol$, .label1$, .label2$

        if emlExtractGroupVectors.error$ <> ""
            .error$ = emlExtractGroupVectors.error$
        else
            .v1# = emlExtractGroupVectors.group1#
            .v2# = emlExtractGroupVectors.group2#

            if .testType$ = "nonparametric"
                # Mann-Whitney U + rank-biserial r
                @emlRankBiserialR: .v1#, .v2#, 2
                if emlRankBiserialR.error$ <> ""
                    .error$ = emlRankBiserialR.error$
                else
                    .pVal = emlRankBiserialR.p
                    .effectVal = emlRankBiserialR.r
                    .u1 = emlRankBiserialR.u1

                    ; THE OMNIBUS LINE COMES FROM @emlBridgeOmnibusLine on
                    ; every arm and on the consume path, so a figure drawn
                    ; from a stored result describes its test in the same
                    ; words as the same figure drawn from a re-run.
                    ; THE OMNIBUS, AS FIVE NUMBERS. They are named once, on
                    ; every arm, because two things read them: the line the
                    ; figure carries, and the publication at the foot of this
                    ; procedure. What each one holds follows the test; the
                    ; mapping is written down in @emlBridgeOmnibusLine's
                    ; header and nowhere else.
                    .omniStat = .u1
                    .omniDf1 = undefined
                    .omniDf2 = undefined
                    .omniP = .pVal
                    .omniEffect = .effectVal
                    @emlBridgeOmnibusLine: 2, .testType$, .omniStat, .omniDf1,
                    ... .omniDf2, .omniP, .omniEffect
                    .omnibus$ = emlBridgeOmnibusLine.result$
                    ; THE BRACKET CAPTION, TWO-GROUP NONPARAMETRIC ARM. One
                    ; invariant with no special case in it: EVERY
                    ; BRACKET-BEARING FIGURE NAMES ITS TEST. A reader taking
                    ; a claim off a bracket needs to know a Mann-Whitney U
                    ; produced it as much on two groups as on four. Two
                    ; groups is ONE comparison, so nothing is corrected here
                    ; and the caption must not pretend otherwise -- but "no
                    ; correction was applied" is itself a disclosure rather
                    ; than a silence, and an empty caption cannot be told
                    ; apart from a build that lost one. So the line NAMES the
                    ; test and states the reason there is nothing to adjust,
                    ; in the same voice as the k >= 3 arms: they say what
                    ; produced the p-values and then what was or was not done
                    ; about multiplicity, and this says the same two things
                    ; about a family of one.
                    ;
                    ; THE THREE CAPTION LINES ARE SET IN ONE BLOCK NEAR THE
                    ; TOP OF THIS PROCEDURE, not here, because the figure has
                    ; to carry them whether the numbers came from a test run
                    ; on this pass or from the store -- and a caption set on
                    ; the compute path only is a stored result drawn under
                    ; the PREVIOUS figure's caption. The wording, the arm it
                    ; belongs to and the reason for it are unchanged; only
                    ; the place is.

                    ; THE RESULT, IN THE ONE SHAPE EVERY PATH RENDERS FROM:
                    ; pairwise p and pairwise SIGNED effect size, indexed in
                    ; display order. One pair here, and the 2 x 2 is not
                    ; ceremony -- it is what lets this arm, the k-group arms
                    ; and the path that consumes a STORED result share
                    ; @emlBridgeRenderAnnotations instead of carrying five
                    ; copies of one loop between them.
                    ;
                    ; THE EFFECT SIZE IS STORED SIGNED AND RENDERED PER THE
                    ; ARM'S OWN SIGN POLICY. @emlBridgeEffectPolicy holds that
                    ; policy for all four arms; the drawn ink is magnitude on
                    ; every one of them either way, which is R's convention
                    ; and Ian's ruling.
                    .pRes## = zero## (2, 2)
                    .eRes## = zero## (2, 2)
                    .pRes##[1, 2] = .pVal
                    .eRes##[1, 2] = .effectVal

                    @emlBridgeEffectPolicy: 2, .testType$
                    .effLabel$ = emlBridgeEffectPolicy.label$
                    .effSymbol$ = emlBridgeEffectPolicy.symbol$
                    .effBracketAbs = emlBridgeEffectPolicy.bracketAbs
                    .effMatrixAbs = emlBridgeEffectPolicy.matrixAbs

                    ; THE TEST, IN THE CORNER BOX, IS SET BY THE RENDERER in
                    ; both layouts -- .omnibus$ is composed on this arm and
                    ; handed to it, and @emlGraphsPostDispatchAnnotations
                    ; routes it into the corner block. Without it the figure
                    ; would leave the session carrying a bracket, stars and
                    ; an effect size with nothing saying what produced them.
                    ; WHAT THE PUBLICATION NEEDS BESIDES THE FIGURE'S OWN
                    ; NUMBERS. The store states the WHOLE result on every run
                    ; (section d), so a field this arm does not compute is
                    ; published as an ABSENCE rather than left standing from
                    ; the run before it. Two groups is one comparison: there
                    ; is no post-hoc, no pairwise test statistic and no
                    ; mean-difference table, and @emlPublishAbsentMatrix is
                    ; the shape the write site takes for a k x k quantity
                    ; nobody computed -- undefined in every cell, never zeros.
                    .omniLabel$ = "U"
                    .omniEffectLabel$ = "rank-biserial r"
                    .omniN = size (.v1#) + size (.v2#)
                    .postHoc$ = ""
                    .statLabel$ = ""
                    @emlPublishAbsentMatrix: 2
                    .statRes## = emlPublishAbsentMatrix.m##
                    @emlPublishAbsentMatrix: 2
                    .diffRes## = emlPublishAbsentMatrix.m##

                    .hasPairwise = 1
                    @emlBridgeRenderAnnotations: 2, .useMatrix, .style$,
                    ... .showNS, .showEffect, .alpha, .effLabel$,
                    ... .effSymbol$, .effBracketAbs, .effMatrixAbs,
                    ... .omnibus$, .pRes##, .eRes##
                endif
            else
                # Welch t-test + Cohen's d
                @emlTTest: .v1#, .v2#, 2, 0
                if emlTTest.error$ <> ""
                    .error$ = emlTTest.error$
                else
                    .pVal = emlTTest.p
                    .tVal = emlTTest.t
                    .dfVal = emlTTest.df

                    @emlCohenD: .v1#, .v2#
                    .effectVal = undefined
                    if emlCohenD.error$ = ""
                        .effectVal = emlCohenD.d
                    endif

                    .omniStat = .tVal
                    .omniDf1 = .dfVal
                    .omniDf2 = undefined
                    .omniP = .pVal
                    .omniEffect = .effectVal
                    @emlBridgeOmnibusLine: 2, .testType$, .omniStat, .omniDf1,
                    ... .omniDf2, .omniP, .omniEffect
                    .omnibus$ = emlBridgeOmnibusLine.result$
                    ; THE BRACKET CAPTION, TWO-GROUP PARAMETRIC ARM. It says
                    ; the same two things as the Mann-Whitney arm above about
                    ; a different test: the comparison is named, and the
                    ; adjustment clause states that there was one comparison
                    ; and nothing was applied. The adjustment clause is NOT
                    ; the Tukey sentence and must not become it -- "already
                    ; family-wise" is a claim about the studentized range
                    ; distribution and a Welch t makes no such claim; here
                    ; there is simply no family. See the note on the
                    ; Mann-Whitney arm. Set with the other two in the
                    ; caption block near the top of this procedure; see the
                    ; note on the Mann-Whitney arm for why.

                    ; THE RESULT, IN THE ONE SHAPE EVERY PATH RENDERS FROM.
                    ; The twin of the block on the Mann-Whitney arm; see the
                    ; note there, and @emlBridgeRenderAnnotations' header for
                    ; why the rendering is one procedure.
                    .pRes## = zero## (2, 2)
                    .eRes## = zero## (2, 2)
                    .pRes##[1, 2] = .pVal
                    .eRes##[1, 2] = .effectVal

                    @emlBridgeEffectPolicy: 2, .testType$
                    .effLabel$ = emlBridgeEffectPolicy.label$
                    .effSymbol$ = emlBridgeEffectPolicy.symbol$
                    .effBracketAbs = emlBridgeEffectPolicy.bracketAbs
                    .effMatrixAbs = emlBridgeEffectPolicy.matrixAbs

                    ; WHAT THE PUBLICATION NEEDS BESIDES THE FIGURE'S OWN
                    ; NUMBERS. The store states the WHOLE result on every run
                    ; (section d), so a field this arm does not compute is
                    ; published as an ABSENCE rather than left standing from
                    ; the run before it. Two groups is one comparison: there
                    ; is no post-hoc, no pairwise test statistic and no
                    ; mean-difference table, and @emlPublishAbsentMatrix is
                    ; the shape the write site takes for a k x k quantity
                    ; nobody computed -- undefined in every cell, never zeros.
                    .omniLabel$ = "t"
                    .omniEffectLabel$ = "Cohen's d"
                    .omniN = size (.v1#) + size (.v2#)
                    .postHoc$ = ""
                    .statLabel$ = ""
                    @emlPublishAbsentMatrix: 2
                    .statRes## = emlPublishAbsentMatrix.m##
                    @emlPublishAbsentMatrix: 2
                    .diffRes## = emlPublishAbsentMatrix.m##

                    .hasPairwise = 1
                    @emlBridgeRenderAnnotations: 2, .useMatrix, .style$,
                    ... .showNS, .showEffect, .alpha, .effLabel$,
                    ... .effSymbol$, .effBracketAbs, .effMatrixAbs,
                    ... .omnibus$, .pRes##, .eRes##
                endif
            endif
        endif
    endif

    # =================================================================
    # K-GROUP COMPARISON (3-10 groups)
    # =================================================================

    if .consumed = 0 and .error$ = "" and .nGroups >= 3

        if .testType$ = "nonparametric"
            # --- Kruskal-Wallis + Dunn's post-hoc ---
            @emlKruskalWallis: .tableId, .dataCol$, .factorCol$
            if emlKruskalWallis.error$ <> ""
                .error$ = emlKruskalWallis.error$
            else
                .hVal = emlKruskalWallis.h
                .pOmnibus = emlKruskalWallis.p
                .dfOmnibus = emlKruskalWallis.df
                .totalN = emlKruskalWallis.n
                .epsilonSq = .hVal / (.totalN - 1)

                # The caption read ", e2 = 0.272". "e2" is not notation
                # for epsilon-squared. This string is only ever drawn by
                # Text special / Text in the Picture window — as the matrix
                # panel title or as the corner annotation block — so Praat's
                # symbol escapes apply: \ep is epsilon, ^ superscripts the
                # character after it. The line itself is composed by
                # @emlBridgeOmnibusLine, which is the one place every arm and
                # the consume path share.
                .omniStat = .hVal
                .omniDf1 = .dfOmnibus
                .omniDf2 = undefined
                .omniP = .pOmnibus
                .omniEffect = .epsilonSq
                @emlBridgeOmnibusLine: .nGroups, .testType$, .omniStat,
                ... .omniDf1, .omniDf2, .omniP, .omniEffect
                .omnibus$ = emlBridgeOmnibusLine.result$

                # PAIRWISE POST-HOC — ALWAYS, whatever the omnibus said.
                # This `if .pOmnibus < .alpha` was the graph door's half of
                # the gate the 25 Aug punch list removed (lane 3.1): the
                # user asked a figure for its statistical annotation, the
                # Kruskal-Wallis came back quiet, and Dunn's never ran. What
                # the reader got was not an empty figure — it was a MATRIX OF
                # FABRICATED CELLS. The branch below this one filled every
                # cell from @emlFormatStars on a p of exactly 1, so a figure
                # drawn on a non-significant omnibus said "n.s." about pairs
                # that had never been tested. Measured on this tree before the
                # removal: harness/posthocgate/out/bridge_kw_matrix.txt, three
                # cells, all "n.s.", no Dunn's table anywhere in the report.
                #
                # With the gate gone the cells carry Dunn's own adjusted
                # p-values and the branch that invented them is deleted, not
                # merely unreachable.
                @emlDunnTest: .tableId, .dataCol$, .factorCol$, .correction$
                # Capture Dunn's outputs into locals immediately — the
                # loops below call other procedures between reads.
                .dunnError$ = emlDunnTest.error$
                if .dunnError$ = ""
                    .pMat## = emlDunnTest.pMatrix##
                    ; THE PAIRWISE TEST STATISTIC, captured in the same breath
                    ; as the p it belongs to. The store publishes both, so a
                    ; later reader of a graph-door run is not short of the z
                    ; the menu door's run would have carried.
                    .zMat## = emlDunnTest.zMatrix##
                    # THE PAIRWISE MATRIX IS DECLARED HERE, where Dunn's
                    # succeeded, because that is the only state in which it
                    # exists. @emlReportKWComparison prints the rank-biserial
                    # matrix UNCONDITIONALLY and computes it itself only when
                    # .doDunn = 0; with .doDunn = 1 it reads
                    # emlKruskalWallis.rMatrix## and its header says that
                    # value is "guaranteed by orchestrator". The orchestrator
                    # in stats/eml-analysis.praat does guarantee it -- it
                    # makes exactly this copy after exactly this call. THIS
                    # PROCEDURE IS THE SECOND ORCHESTRATOR and never made it,
                    # so a graphs-side annotated Kruskal-Wallis draw died with
                    # "Unknown variable: emlKruskalWallis.rMatrix##". The
                    # matching guarantee on the reporting side is
                    # @emlReportBridgeStats, which asks whether Dunn's
                    # SUCCEEDED before it says .doDunn = 1, so a failed
                    # post-hoc leaves the reporter to build the matrix for
                    # itself rather than to read one that was never copied.
                    #
                    # THE COPY, NOT A RECOMPUTE. @emlDunnTest has already
                    # built this matrix from the same ranks its z-scores
                    # came from; recomputing here would be a second engine
                    # for one number and the two could drift. It is also
                    # what makes the graphs figure agree with the wrapper
                    # report to the last digit, which is the property this
                    # whole layer is being held to.
                    emlKruskalWallis.rMatrix## = emlDunnTest.rMatrix##
                endif
                if .dunnError$ = ""
                    ; THE BRACKET CAPTION, NONPARAMETRIC ARM. It NAMES the
                    ; method and claims nothing about what the method
                    ; achieves, because Dunn's z-tests carry no family-wise
                    ; control of their own — the correction is whatever the
                    ; user asked for and this sentence is a record of that
                    ; choice, not an endorsement of it. .correction$ is the
                    ; resolved token, so a figure drawn after an
                    ; unrecognised annotCorrectionMethod$ says "holm" and
                    ; means it. It is the same token the Info-window report
                    ; prints in "-- Dunn's Post-Hoc (adjusted p, holm) --",
                    ; and printing anything else here would put the figure
                    ; and the report into disagreement about the same run.
                    ; Set with the other two in the caption block near the top
                    ; of this procedure; see the note on the Mann-Whitney arm.
                    # Group order from @emlCountGroups (no remapping needed)
                    #
                    # THE RESULT, IN THE ONE SHAPE EVERY PATH RENDERS FROM:
                    # Dunn's adjusted p per pair, and the SIGNED rank-biserial
                    # r per pair, both indexed in DISPLAY order so a bracket's
                    # i and j are x-axis positions and nothing has to remap on
                    # the way to the picture. The rendering itself is
                    # @emlBridgeRenderAnnotations, which the two-group arms,
                    # the parametric arm and the path that consumes a STORED
                    # result all call -- see its header for why one procedure
                    # and not five copies of one loop.
                    .eRes## = zero## (.nGroups, .nGroups)
                    for .i from 1 to .nGroups - 1
                        for .j from .i + 1 to .nGroups
                            @emlBridgePairEffect: .tableId, .dataCol$,
                            ... .factorCol$, .gLabel$[.i], .gLabel$[.j],
                            ... .testType$
                            .eRes##[.i, .j] = emlBridgePairEffect.value
                        endfor
                    endfor

                    ; THE EFFECT SIZES ARE COMPUTED WHETHER OR NOT THEY ARE
                    ; SHOWN, and that is what makes showEffect a display
                    ; setting rather than a result setting. v112's census
                    ; classifies it DISPLAY_ONLY with a condition attached:
                    ; "In the bridge as it stands showEffect = 0 means Cohen's
                    ; d is never computed, so a result published under it
                    ; cannot serve a later figure that wants effect sizes."
                    ; Section (d) requires the store to state the WHOLE result
                    ; on every run, so the condition is discharged here: the
                    ; numbers are always formed, and .showEffect decides only
                    ; whether the annotation carries them.
                    @emlBridgeEffectPolicy: .nGroups, .testType$
                    .effLabel$ = emlBridgeEffectPolicy.label$
                    .effSymbol$ = emlBridgeEffectPolicy.symbol$
                    .effBracketAbs = emlBridgeEffectPolicy.bracketAbs
                    .effMatrixAbs = emlBridgeEffectPolicy.matrixAbs

                    ; WHAT THE PUBLICATION NEEDS BESIDES THE FIGURE'S OWN
                    ; NUMBERS -- see the note on the two-group arm. Dunn's has
                    ; a test statistic and no mean-difference table, so the z
                    ; matrix is published and the difference matrix is
                    ; published as an ABSENCE rather than as zeros.
                    .omniLabel$ = "H"
                    .omniEffectLabel$ = "epsilon squared"
                    .omniN = .totalN
                    .postHoc$ = "dunn"
                    .statLabel$ = "z"
                    .statRes## = .zMat##
                    @emlPublishAbsentMatrix: .nGroups
                    .diffRes## = emlPublishAbsentMatrix.m##

                    ; One name for the display-ordered p matrix on every
                    ; arm, so the publication at the foot of this procedure
                    ; reads one thing. Dunn's is already in display order --
                    ; see "no remapping needed" above -- so this is a copy and
                    ; not a remap.
                    .pRes## = .pMat##

                    .hasPairwise = 1
                    @emlBridgeRenderAnnotations: .nGroups, .useMatrix,
                    ... .style$, .showNS, .showEffect, .alpha, .effLabel$,
                    ... .effSymbol$, .effBracketAbs, .effMatrixAbs,
                    ... .omnibus$, .pRes##, .eRes##
                else
                    # DUNN'S COULD NOT RUN. Not a policy branch — the
                    # post-hoc is never withheld — but a figure whose
                    # post-hoc failed still has an omnibus to show, and this
                    # arm is the only place that sets it. Both layouts take
                    # it: the corner box is set on both, exactly as the
                    # success path sets it.
                    annotTextN = 1
                    annotTextX[1] = 0
                    annotTextY[1] = 0
                    annotTextLabel$[1] = .omnibus$
                    annotTextAnchor$[1] = "right"
                endif
            endif


        else
            # --- One-way ANOVA, post-hoc as the dialog asked for it ---
            ; ITEM 3.5 -- SITE 1 OF 2. This argument was the literal 1. It is
            ; now the choice resolved from annotPostHoc at the top of this
            ; procedure; see THE POST-HOC CHOICE there for the channel and for
            ; why the default is 1.
            @emlOneWayAnova: .tableId, .dataCol$, .factorCol$, .doTukey
            if emlOneWayAnova.error$ <> ""
                .error$ = emlOneWayAnova.error$
            else
                .fVal = emlOneWayAnova.fValue
                .pOmnibus = emlOneWayAnova.p
                .dfB = emlOneWayAnova.dfBetween
                .dfW = emlOneWayAnova.dfWithin
                # Capture the pairwise outputs into locals immediately — the
                # loops below call other procedures between reads.
                .anovaPairs = emlOneWayAnova.nPairs
                ; ITEM 3.5 -- THE CAPTURES ARE GUARDED BECAUSE THE OUTPUTS ARE
                ; CONDITIONAL. @emlOneWayAnova's header says so in as many
                ; words: .pMatrix##, .qMatrix##, .meanDiff##, .dMatrix## and
                ; .groupName$[] are "Output (when .tukey = 1)", and .nPairs is
                ; 0 otherwise. Reading them after a .tukey = 0 run does not
                ; return an empty matrix, it stops Praat dead -- which is why
                ; this guard is part of item 3.5 and not a tidy-up: the literal
                ; could not be removed without it. Same shape as
                ; @emlDeclareAnovaEffectSizes' own .doTukey <> 1 guard.
                if .doTukey = 1
                    .pMat## = emlOneWayAnova.pMatrix##
                    ; THE PAIRWISE TEST STATISTIC AND THE MEAN DIFFERENCES,
                    ; captured in the same breath as the p they belong to, so
                    ; the store's publication of a graph-door run states the
                    ; same whole result the menu door's does.
                    .qMat## = emlOneWayAnova.qMatrix##
                    .diffMat## = emlOneWayAnova.meanDiff##
                    for .g from 1 to .nGroups
                        .statName$[.g] = emlOneWayAnova.groupName$[.g]
                    endfor
                endif

                .omniStat = .fVal
                .omniDf1 = .dfB
                .omniDf2 = .dfW
                .omniP = .pOmnibus
                ; THE ONE-WAY ANOVA LINE CARRIES NO EFFECT SIZE, and never
                ; has; eta squared is published to the store all the same, so
                ; that a later consumer is not short of it.
                .omniEffect = undefined
                if variableExists ("emlOneWayAnova.etaSquared")
                    .omniEffect = emlOneWayAnova.etaSquared
                endif
                @emlBridgeOmnibusLine: .nGroups, .testType$, .omniStat,
                ... .omniDf1, .omniDf2, .omniP, undefined
                .omnibus$ = emlBridgeOmnibusLine.result$
                # THE FIGURE SAYS WHERE ITS
                # FAMILY-WISE CONTROL COMES FROM, and it says a different
                # thing on each arm because the two arms do a different thing.
                #
                # The graphs form does not offer an Adjustment menu when the
                # test is parametric: Tukey's p comes from the studentized
                # range distribution and is ALREADY family-wise over the set
                # of pairwise comparisons, so stacking Holm or Bonferroni on
                # top of it would correct the same family twice and hand back
                # a p that is conservative for no stated reason. The dialog
                # now reads "Adjustment method: none — Tukey HSD is already
                # family-wise." A field disappearing from a dialog is not a
                # disclosure, though: the FIGURE outlives the dialog, and this
                # sub-line is the only place in it that says which correction
                # produced the annotated p-values (see the note in
                # @emlDrawMatrixPanel). So the figure states it too.
                #
                # THE DUNN ARM IS DELIBERATELY LEFT ALONE, and that asymmetry
                # is the point rather than an oversight. Dunn's z-tests carry
                # no family-wise control of their own, the form still offers
                # the menu there, @emlDunnTest still honours it, and the
                # string that arm writes still NAMES the method the user
                # chose -- "Dunn's test (holm)". One claim covering both arms
                # would be false on one of them whichever way it was written.
                # THE BRACKET CAPTION, PARAMETRIC ARM — the same disclosure
                # carried to the other layout. The sub-line above only ever
                # reaches a MATRIX figure, and the bracket layout is the one
                # that puts the p-values and the stars directly on the
                # picture, so it names the test and the adjustment too. What
                # it says here is the parametric claim and only the
                # parametric claim: Tukey's p comes from the studentized range
                # distribution and is already family-wise over the set of
                # pairwise comparisons, so there is nothing further to apply
                # and the figure says so outright. The Dunn arm's caption is
                # a different sentence for a different reason; see its note.
                # Set with the other two in the caption block near the top of
                # this procedure; see the note on the Mann-Whitney arm.

                # --------------------------------------------------------
                # Index mapping: encounter order → ANOVA alphabetical order
                # emlCountGroups uses encounter order (matches x-axis)
                # emlOneWayAnova inherits Tukey alphabetical sort
                # Order controlled by @emlCountGroups.
                # Build map from display position to stats-procedure
                # position for matrix access.
                # Build map from display order to stats order
                ; ITEM 3.5 -- UNDER THE SAME GUARD AS THE CAPTURES ABOVE, and
                ; for the same reason: .statName$[] is @emlOneWayAnova's
                ; .groupName$[], a Tukey-only output. The map is read only
                ; inside the `.anovaPairs > 0` branch below, which a post-hoc
                ; off run never enters, so nothing downstream loses a value.
                if .doTukey = 1
                    for .i from 1 to .nGroups
                        .sortMap[.i] = 0
                        for .g from 1 to .nGroups
                            if .gLabel$[.i] = .statName$[.g]
                                .sortMap[.i] = .g
                            endif
                        endfor
                    endfor
                endif

                # PAIRWISE FROM TUKEY — ALWAYS, whatever the omnibus said.
                # The removed conjunct was `.pOmnibus < .alpha`, the parametric
                # half of the graph door's gate (punch list 2026-08-25, lane
                # 3.1). Tukey itself was never gated here — @emlOneWayAnova
                # ran it unconditionally a few lines up — so what the gate
                # withheld was the DRAWING of a post-hoc that had already run:
                # on the bracket layout a non-significant F produced a figure
                # with no bracket on it at all. Measured before the removal,
                # harness/posthocgate/out/bridge_anova_brackets.txt:
                # bracketN = 0 on a fixture whose Tukey p-values exist and are
                # printed by the report beside it.
                #
                # ITEM 3.5 DOES NOT REOPEN THAT GATE, and the distinction is
                # the whole of lane 3.1. A GATE is this code deciding, from a
                # number it has just computed, that the user may not see the
                # post-hoc — the omnibus p withholding the pairwise result.
                # What .doTukey carries is the USER'S OWN ANSWER, given at the
                # dialog before any number existed, to the question "do you
                # want a post-hoc at all". No p-value, no effect size and no
                # count of groups is consulted anywhere on its path from the
                # Comparison menu to @emlOneWayAnova. The post-hoc is still
                # never withheld from a user who asked for one.
                #
                # WHAT REMAINS IN THE CONDITION IS STRUCTURAL, not policy:
                # `.anovaPairs > 0` is "there is a matrix to read". The branch
                # this replaces drew the same matrix cells from the same
                # @emlOneWayAnova.pMatrix##, so no cell VALUE moves; what moves
                # is that the bracket layout now draws them.
                if .error$ = "" and .anovaPairs > 0
                    # THE RESULT, IN THE ONE SHAPE EVERY PATH RENDERS FROM,
                    # AND THE REMAP HAPPENS HERE AND NOWHERE ELSE. Tukey's
                    # matrix is indexed in the ANOVA's alphabetical order and
                    # the figure's x axis is in @emlCountGroups' order, so the
                    # display-ordered matrix is built once through .sortMap[]
                    # and everything downstream -- brackets, matrix cells, the
                    # store -- reads positions rather than remapping again.
                    # A second remap somewhere downstream is how a p-value
                    # ends up drawn over the wrong pair of bars.
                    .pRes## = zero## (.nGroups, .nGroups)
                    .eRes## = zero## (.nGroups, .nGroups)
                    .statRes## = zero## (.nGroups, .nGroups)
                    .diffRes## = zero## (.nGroups, .nGroups)
                    for .i from 1 to .nGroups - 1
                        for .j from .i + 1 to .nGroups
                            .pRes##[.i, .j] = .pMat##[.sortMap[.i],
                            ... .sortMap[.j]]
                            .statRes##[.i, .j] = .qMat##[.sortMap[.i],
                            ... .sortMap[.j]]
                            .diffRes##[.i, .j] = .diffMat##[.sortMap[.i],
                            ... .sortMap[.j]]
                            @emlBridgePairEffect: .tableId, .dataCol$,
                            ... .factorCol$, .gLabel$[.i], .gLabel$[.j],
                            ... .testType$
                            .eRes##[.i, .j] = emlBridgePairEffect.value
                        endfor
                    endfor

                    ; WHAT THE PUBLICATION NEEDS BESIDES THE FIGURE'S OWN
                    ; NUMBERS -- see the note on the two-group arm. Tukey has
                    ; both a test statistic and a mean-difference table, and
                    ; both are remapped into x-axis order above with the
                    ; p-values, because the store's matrices and its labels
                    ; must be indexed the same way.
                    .omniLabel$ = "F"
                    .omniEffectLabel$ = "eta squared"
                    .omniN = .dfB + .dfW + 1
                    .postHoc$ = "tukey"
                    .statLabel$ = "q"

                    ; THE EFFECT SIZES ARE COMPUTED WHETHER OR NOT THEY ARE
                    ; SHOWN; see the note on the Kruskal-Wallis arm for why
                    ; that is what makes showEffect a display setting.
                    @emlBridgeEffectPolicy: .nGroups, .testType$
                    .effLabel$ = emlBridgeEffectPolicy.label$
                    .effSymbol$ = emlBridgeEffectPolicy.symbol$
                    .effBracketAbs = emlBridgeEffectPolicy.bracketAbs
                    .effMatrixAbs = emlBridgeEffectPolicy.matrixAbs

                    .hasPairwise = 1
                    @emlBridgeRenderAnnotations: .nGroups, .useMatrix,
                    ... .style$, .showNS, .showEffect, .alpha, .effLabel$,
                    ... .effSymbol$, .effBracketAbs, .effMatrixAbs,
                    ... .omnibus$, .pRes##, .eRes##
                else
                    # NO PAIRS TO DRAW. Not a policy branch — this code
                    # withholds no post-hoc from anyone who asked for one —
                    # but with no Tukey matrix there is nothing pairwise to
                    # put on the figure, and the omnibus still belongs on it.
                    # Both layouts take the corner box, exactly as the branch
                    # above sets it.
                    #
                    # ITEM 3.5 GIVES THIS BRANCH ITS SECOND ENTRANCE, and it
                    # is the entrance the ruling asked for: .anovaPairs is
                    # @emlOneWayAnova's .nPairs, which that procedure sets to
                    # 0 when it is called with .tukey = 0. So a user who
                    # picked "ANOVA only, no pairwise tests" at the Comparison
                    # menu arrives here and gets a figure carrying the omnibus
                    # and nothing else — the same figure the Compare k Groups
                    # dialog's own post-hoc opt-out produces, which is what
                    # v127's leg3 asks these two doors to agree about.
                    annotTextN = 1
                    annotTextX[1] = 0
                    annotTextY[1] = 0
                    annotTextLabel$[1] = .omnibus$
                    annotTextAnchor$[1] = "right"
                endif
            endif
        endif
    endif
    ; ------------------------------------------------------------------
    ; ITEM 1.2 — THE CANONICAL RENDERING, AND THE PRE-PRINT COMPARISON.
    ;
    ; Fable's ruling of 26 August, amending punch item 1.2: "Canonical text is
    ; the buffer; the pre-print comparison runs buffer-only." This is that
    ; comparison, and it is HERE rather than in @emlGraphsReportBridgeIfNew
    ; for the reason that procedure's own header gives — the bridge decides
    ; and the caller obeys, because a second rule in the caller is how the
    ; bridge and the form come to disagree about one draw.
    ;
    ; WHAT BUFFER-ONLY MEANS. @emlEmitMode: 0 puts the minimal renderer into
    ; its second mode: @emlReportBridgeStats runs in full — same reporter,
    ; same numbers, same declarations — and NOTHING reaches the Info window.
    ; What comes back in emlEmitText$ is the factual and disclosure lines
    ; alone: no explanation line, no two-tab gloss, no timestamp, no
    ; provenance. That is what makes it comparable with a rendering made at
    ; another door under another explanations setting, and it is why the
    ; capture approach could not do this job — under capture the text exists
    ; only by being printed, so "identical -> print nothing" is unreachable.
    ;
    ; THE COMPARISON IS AGAINST THE STORE AS IT STANDS RIGHT NOW, before the
    ; publication below overwrites it. emlStoreReport$ is the text of the
    ; report the reader is looking at for this result, and "" means no report
    ; was printed for it — the changed-setting path publishes "" precisely so
    ; that this comparison cannot fall silent by matching a report nobody has
    ; seen.
    ;
    ; ONLY THE "data" VERDICT CAN GO SILENT HERE, and that is deliberate.
    ; Reaching it means @emlConsumeGroupResult has already established that
    ; the publication is about THIS table and THIS pair of columns, and that
    ; the only thing that moved was the data key. A "none" verdict has no
    ; such guarantee — nothing published, another comparison, another schema
    ; — so the stored text is not about this result and must not be compared
    ; with it. Silence has to be earned; this is what earns it.
    ;
    ; THE REPORTER RUNS TWICE ON THE PATH THAT PRINTS, once here and once in
    ; @emlGraphsReportBridgeIfNew, and that is the price of the shape rather
    ; than an oversight. The buffer cannot simply be flushed to the Info
    ; window instead: it holds no explanation lines by construction, so
    ; printing it would silently drop every gloss for a user who asked for
    ; them. Both renderings are deterministic reads of the same finished
    ; result, so they agree character for character. On the path that stays
    ; silent — the one the ruling expects to be the common one — the reporter
    ; runs once and nothing is printed at all.
    ; ------------------------------------------------------------------
    .canonReport$ = ""
    .priorReport$ = ""
    if variableExists ("emlStoreReport$")
        .priorReport$ = emlStoreReport$
    endif
    if .printReport = 1
        if .consumed = 0
            if .error$ = ""
                @emlEmitMode: 0
                @emlReportBridgeStats: .tableId, .dataCol$, .factorCol$
                @emlEmitMode: 1
                .canonReport$ = emlEmitText$
                if .verdict$ = "data"
                    if .priorReport$ <> ""
                        if .canonReport$ = .priorReport$
                            .printReport = 0
                            .notePending = 0
                        endif
                    endif
                endif
            endif
        endif
    endif

    ; ------------------------------------------------------------------
    ; THE RECOMPUTE PUBLISHES THROUGH THE ONE WRITE SITE.
    ;
    ; Section (d) of the ruling allows the store exactly one writer, which
    ; states the whole result on EVERY analysis run. This bridge is an
    ; analysis run -- it is the second door, and the whole reason the store
    ; exists is that two doors were computing one comparison -- so a re-run
    ; here has to reach that writer too. Without it, two figures drawn one
    ; after another with no analysis door between them would each recompute
    ; and each report, which is the duplicate report in a different costume.
    ;
    ; THE KEY IS THE ONE @emlConsumeGroupResult ALREADY TOOK, and that is
    ; deliberate. The fingerprint's header names the failure it closes: "a
    ; caller that computes a result, lets the table change, and only then
    ; stamps a key has stamped a truthful key on a result the table does not
    ; support ... take the key in the same pass that reads the data". The key
    ; passed here was taken before a single test ran.
    ;
    ; THE CALL IS GUARDED ON THE STORE'S OWN FORMAT GLOBAL, which the write
    ; site declares when it is loaded, because this file must keep working in
    ; a tree that has the read side and not yet the writer -- and because a
    ; reader that assigned the published names itself would BE a second
    ; writer, which is the one thing section (d) forbids.
    if .consumed = 0 and .error$ = "" and .hasPairwise = 1
        if variableExists ("emlStoreFormat$")
            ; THE LABELS TRAVEL IN A PUBLISHED ARRAY BECAUSE PRAAT CANNOT
            ; PASS ONE. emlPublishInLabel$[1..n] is the write site's declared
            ; hand-off, filled immediately before the call so nothing can run
            ; between the fill and the read, and it carries the DISPLAY order
            ; -- the order both matrices are indexed by and the order the
            ; figure's x axis is in.
            for .gi from 1 to .nGroups
                emlPublishInLabel$[.gi] = .gLabel$[.gi]
            endfor
            selectObject: .tableId
            .tableName$ = selected$ ("Table")
            @emlBridgeStoreIdentity: .nGroups, .testType$, .correction$
            ; ITEM 1.2 — THE CANONICAL TEXT TRAVELS IN THE DECLARED HAND-OFF,
            ; the same way the level labels do, and for the same reason: the
            ; write site's argument list is already thirty-seven long. It is
            ; "" on every path that prints no report, which is what the
            ; changed-setting path is and what "" means at the write site.
            emlPublishInReport$ = .canonReport$
            @emlPublishAnalysisResult: "emlRunAnnotationComparison", "graph",
            ... "group", .error$, .key$, .keyError$, .tableId, .tableName$,
            ... .dataCol$, .factorCol$, emlBridgeStoreIdentity.test$,
            ... emlBridgeStoreIdentity.correction$, .alpha, .sort$,
            ... .nGroups, .omniLabel$, .omniStat, .omniDf1, .omniDf2, .omniP,
            ... .omniEffectLabel$, .omniEffect, .omniN,
            ... "", undefined, undefined, undefined, "", undefined,
            ... .postHoc$, 1, .statLabel$, .effLabel$,
            ... .pRes##, .diffRes##, .statRes##, .eRes##
        endif
    endif

    ; THE OMNIBUS RESULT IS ALREADY BUILT. .omnibus$ is the string this
    ; procedure puts on the figure -- "F(2, 21) = 4.31, p = .027" or the
    ; Kruskal-Wallis equivalent -- so the record carries exactly what the
    ; reader sees on the plot, with no second formatting path to drift.
    .recResult$ = ""
    if .error$ = "" and .omnibus$ <> ""
        .recResult$ = .omnibus$ + newline$ + "  " + string$ (.nGroups)
        ... + " groups, alpha = " + fixed$ (.alpha, 3)
    endif

    ; ------------------------------------------------------------------
    ; RECORD WORKFLOW -- THE GRAPHS -> STATS PATH.
    ;
    ; THE TWO PATHS ARE ONE FEATURE AND MUST RECORD ALIKE. A user can reach
    ; the same group comparison two ways, by design: from the stats menu, or
    ; by asking a figure for its statistical annotation. This procedure IS
    ; the second way -- it runs the t-test, Mann-Whitney, one-way ANOVA,
    ; Kruskal-Wallis, Tukey and Dunn that the brackets are drawn from.
    ;
    ; Capture hooks run in all thirteen orchestrators
    ; in the stats tree and NOT here. That made the two paths disagree: the
    ; stats menu recorded an ANOVA, and the identical ANOVA reached through
    ; a violin plot's brackets recorded the figure and silently dropped the
    ; statistics. Before that change neither path recorded, so the asymmetry
    ; was introduced by fixing one half.
    ;
    ; Placed at the end, so a refusal is recorded as a step rather than
    ; vanishing -- the same rule the analysis hooks follow.
    if variableExists ("emlRecordLoaded")
        @emlRecordInit
        if emlRecordActive = 1
            @emlRecordAnalysisStep: .tableId, "Group comparison on a figure",
            ... .dataCol$ + " by " + .factorCol$ + ", " + .testType$
            ... + ", " + string$ (.nGroups) + " groups",
            ... "Reached through the figure's annotation rather than the "
            ... + "stats menu; the test and the correction are the same.",
            ... "@emlRunAnnotationComparison: data, """ + .dataCol$ + """, """
            ... + .factorCol$ + """, " + string$ (.alpha) + ", """ + .style$
            ... + """, " + string$ (.showNS) + ", " + string$ (.showEffect)
            ... + ", """ + .testType$ + """, " + string$ (.layoutMode),
            ... "In the GUI: New > EML Stats & Graphs > EML Graphs..., with statistical annotation switched on.",
            ... .recResult$, .error$
        endif
    endif
endproc


# ----------------------------------------------------------------------------
# @emlBridgeCorrelation
# For scatter plot: run correlation, populate regression line and text
# annotation arrays.
#
# STATUS: UNUSED — no caller anywhere in the plugin (verified v3.18). Retained
# rather than deleted because it is a documented part of the bridge API that
# user scripts may call directly; the scatter path in eml-graphs-form.praat
# builds its annotations inline instead. Not exercised by any test, so treat
# it as unverified. Known latent defect: the `.error$ = "" and .nX <> .nY`
# guard below relies on short-circuiting, which Praat does not do — if the
# first column extraction fails, .nX is never assigned and the guard raises
# "Unknown variable". Left as-is (out of the declared fix scope) and reported.
#
# Arguments:
#   .tableId     — Table object ID
#   .colX$       — x-axis column name
#   .colY$       — y-axis column name
#   .alpha       — significance threshold
#   .style$      — "p-value", "stars", or "both"
#   .corrType$   — "pearson" or "spearman"
#
# Output: populates annotRegression* and annotText* global arrays.
#   Also sets:
#     .result$   — formatted correlation result string (for Info window)
#     .error$    — "" on success
# ----------------------------------------------------------------------------
procedure emlBridgeCorrelation: .tableId, .colX$, .colY$, .alpha, .style$, .corrType$
    .result$ = ""
    .error$ = ""

    # Extract both columns
    @emlExtractColumn: .tableId, .colX$
    if emlExtractColumn.error$ <> ""
        .error$ = emlExtractColumn.error$
    else
        .xData# = emlExtractColumn.data#
        .nX = emlExtractColumn.n
    endif

    if .error$ = ""
        @emlExtractColumn: .tableId, .colY$
        if emlExtractColumn.error$ <> ""
            .error$ = emlExtractColumn.error$
        else
            .yData# = emlExtractColumn.data#
            .nY = emlExtractColumn.n
        endif
    endif

    if .error$ = "" and .nX <> .nY
        .error$ = "X and Y columns have different valid row counts"
    endif

    if .error$ = ""
        if .corrType$ = "spearman"
            ; ONE COMPUTATION SITE (docs/WORK_ORDER_SPEARMAN_EXACT_2026-08-27.md):
            ; routed through the dispatch rather than @emlSpearmanCorrelation
            ; directly, so that if this UNUSED procedure is ever wired to a
            ; caller it cannot come back onto the raw kernel and bypass the
            ; branch law. The dispatch writes its .p (and .error$, on
            ; failure) back into emlSpearmanCorrelation.p / .error$ itself,
            ; the same qualified-global contract every other call site
            ; already relies on -- .rho below is untouched by that write-
            ; back and still the value @emlSpearmanCorrelation set inside
            ; the dispatch's own call.
            @emlSpearmanCorrelationDispatch: .xData#, .yData#, 2
            if emlSpearmanCorrelation.error$ <> ""
                .error$ = emlSpearmanCorrelation.error$
            else
                .rVal = emlSpearmanCorrelation.rho
                .pVal = emlSpearmanCorrelation.p
                .rLabelInfo$ = "rs = "
                .rLabelDraw$ = "%%r%_s = "
            endif
        else
            @emlPearsonCorrelation: .xData#, .yData#, 2
            if emlPearsonCorrelation.error$ <> ""
                .error$ = emlPearsonCorrelation.error$
            else
                .rVal = emlPearsonCorrelation.r
                .pVal = emlPearsonCorrelation.p
                .rLabelInfo$ = "r = "
                .rLabelDraw$ = "r = "
            endif
        endif
    endif

    if .error$ = ""
        # Format r with no leading zero
        .rText$ = fixed$ (abs (.rVal), 2)
        .firstChar$ = left$ (.rText$, 1)
        .zeroChar$ = "0"
        if .firstChar$ = .zeroChar$
            .rText$ = right$ (.rText$, length (.rText$) - 1)
        endif
        if .rVal < 0
            .rText$ = "-" + .rText$
        endif

        @emlFormatP: .pVal
        .pText$ = emlFormatP.formatted$
        .result$ = .rLabelInfo$ + .rText$ + ", " + .pText$
        .drawResult$ = .rLabelDraw$ + .rText$ + ", " + .pText$

        # Regression line (always from Pearson r, even for Spearman)
        .meanX = mean (.xData#)
        .meanY = mean (.yData#)
        .sdX = stdev (.xData#)
        .sdY = stdev (.yData#)

        if .sdX > 0
            if .corrType$ = "spearman"
                # Need Pearson r for the regression line
                @emlPearsonCorrelation: .xData#, .yData#, 2
                .rForLine = emlPearsonCorrelation.r
            else
                .rForLine = .rVal
            endif

            annotRegressionN = 1
            annotRegressionSlope = .rForLine * (.sdY / .sdX)
            annotRegressionIntercept = .meanY - annotRegressionSlope * .meanX
            annotRegressionR = .rVal
            annotRegressionP = .pVal
            annotRegressionLabel$ = .drawResult$
        else
            annotRegressionN = 0
        endif

        # Text annotation (position set by caller after axes computed)
        annotTextN = 1
        annotTextX[1] = 0
        annotTextY[1] = 0
        annotTextLabel$[1] = .drawResult$
        annotTextAnchor$[1] = "left"
    endif
endproc



# ============================================================================
# THE REPORTERS BELOW WRITE TO THE INFO WINDOW, AND THE HOUSE RULE GOVERNS
# ============================================================================
# THEM: no raw double may reach the Info window.
# Statistics print at fixed decimals, p prints in APA style, and full
# precision belongs to the CSV export -- the artefact a reader is meant to
# compute from. The report is for reading.
#
# THIS FILE STRADDLES THE BOUNDARY, which is the only interesting thing about
# applying the rule here. Above this line the procedures build text that is
# DRAWN ON A PICTURE: the omnibus line over a comparison matrix, a bracket
# label, the star legend, the "p < .05" key, a Cohen's d in a matrix cell.
# Below it they build text that is PRINTED IN THE INFO WINDOW. Both kinds are
# strings made with fixed$ and the two look identical in a grep; they are not
# the same surface and the rule names one of them.
#
# THE TEST APPLIED TO EVERY SITE WAS ITS DESTINATION, traced by hand, not its
# spelling and not the procedure's name:
#
#   drawn      -> `Text`, `Text special`, `Text width` (a measurement of what
#                 will be drawn), or one of the annot* globals that
#                 @emlDrawAnnotations and @emlDrawMatrixPanel render.
#                 17 calls in 14 statements. UNTOUCHED. A figure's own text
#                 is laid out against its measured width -- @emlMeasureMatrixLayout
#                 measures the very strings @emlDrawMatrixPanel then draws --
#                 so re-formatting them is a layout change, and layout is not
#                 what the rule is about.
#
#   printed    -> `appendInfoLine`, `@emlReportLine*`, or emlWizardExplain$,
#                 which @emlReportLine appends as the explanation column.
#                 69 calls in 42 statements. ALL ROUTED THROUGH @eml_fixed.
#
#   recorded   -> @emlRunAnnotationComparison's .recResult$, which is neither.
#                 It is the workflow record's note beside a recorded call, and
#                 it is built from .omnibus$ ON PURPOSE so that the record
#                 carries the string the reader saw on the plot, character for
#                 character. One call. UNTOUCHED, for the same reason
#                 @emlRecordViolin's resolved-axis note is untouched.
#
# WHY @eml_fixed AND NOT A LOCAL HELPER. Praat's fixed$ is not a
# fixed-precision formatter -- it returns the larger of the precision asked
# for and the decimals needed to show one significant digit, and a bare "0"
# for an exact zero. @eml_fixed (stats/eml-output.praat) is the one place that
# is closed, and a second implementation here would be a second thing to keep
# right. Praat cannot nest a procedure call inside an expression, so every
# site hoists into a temporary (.fx1$, .fx2$, ...) immediately above the
# statement that prints it.
#
# WHAT A BARE fixed$ PRODUCES HERE, MEASURED. Three
# groups with identical means printed a Tukey difference column of bare "0"
# against neighbours reading "[-3.0871, 3.0871]", and a Cohen's d matrix of
# bare "0". A two-way ANOVA over values near zero printed
#
#     f1                  0.000000000000001     0.000000000000002.0000      .176
#
# -- seventeen decimals in a column padded for sixteen characters, so the SS
# cell ran into the MS cell and the MS cell into the F cell. Every one of
# those numbers was correct. Only their width was wrong.
#
# NOTHING COMPUTED MOVES. @eml_fixed formats; it never writes back, and the
# CSV writers below (@emlCSVAdd and friends) do not call it. They still emit
# full precision, which is where full precision belongs.
# ============================================================================

# ============================================================================
# @emlGraphsReportBridgeIfNew — the reprint gate
# ============================================================================
# THE ONE PLACE THAT DECIDES WHETHER A FIGURE'S ANALYSIS REPORT IS PRINTED.
#
# docs/RULING_RESULT_STORE.md section (c), and the sentence the whole store
# was built around: "Never a second full report -- the duplicate report IS the
# driven defect." @emlRunAnnotationComparison has already decided, because it is
# the only thing that knows whether it computed anything, and it leaves the
# decision in .printReport. This procedure obeys it. It adds no rule of its
# own: a second rule is how the bridge and the form come to disagree about
# one draw.
#
#   printReport = 1   nothing was published, or the DATA moved, the analysis
#                     was re-measured, and the re-measured report is not the
#                     report already in the window. This report is the first
#                     report of THAT result and it prints -- preceded, on the
#                     re-measured path, by the one line this procedure prints
#                     above it.
#   printReport = 0   the figure drew from the store (the analysis door's
#                     report is already in the window, and it is still true);
#                     or a result-affecting SETTING changed and the bridge
#                     has already said so in one line above the brackets;
#                     or -- ITEM 1.2, Fable's amendment of 26 August -- the
#                     data moved, the figure re-ran, and the re-run rendered
#                     THE SAME REPORT, character for character, as the one
#                     the reader already has. Ian's rule of 24 August: "a
#                     re-run that reproduces the stored report exactly prints
#                     nothing." Nothing means nothing: not a second report,
#                     and not the line above it either.
#
# THE ONE LINE IS PRINTED HERE ON THE DATA PATH, AND IN THE BRIDGE ON THE
# SETTINGS PATH, and that is not an inconsistency. On the settings path the
# line is the whole of what that draw says, so it is said where it is
# decided. On the data path whether it is said AT ALL depends on the
# canonical report comparison, which is not finished when that verdict is
# taken -- so the bridge leaves it in .note$ with .notePending raised and
# lowers the flag itself if the comparison comes back identical. This
# procedure still adds no rule: it prints what it is handed, or nothing.
#
# READ THROUGH variableExists. A caller that reaches this without a bridge
# run in front of it -- an error path, a user script -- has no .printReport,
# and the safe answer there is the old one: print. Silence is the answer that
# has to be earned.
#
# WHAT SUPPRESSION ALSO SUPPRESSES, said out loud because it is a real cost
# and not a detail. @emlReportBridgeStats opens with @emlCSVInit and closes by
# DECLARING the three export files, so a suppressed report is also a
# suppressed export declaration.
#
#   On the consume path that is CORRECT and is part of the point: the
#   analysis door ran this very comparison and declared it, the store proved
#   the two are the same result, and re-declaring would overwrite a correct
#   buffer with an identical one.
#
#   On the changed-setting path it is a KNOWN GAP: the bridge recomputed
#   under the new setting, the figure shows the new brackets, and the export
#   buffer still holds the analysis door's older run. Saving a CSV then saves
#   the settings the figure does not draw. Closing it needs a reporter that
#   can RENDER without printing -- the same capability punch item 1.2's
#   canonical report comparison needs -- and one mechanism closes both. It is
#   recorded in docs/OPEN_ITEMS.md rather than half-fixed here, because the
#   alternative available today is printing the second report, and the ruling
#   forbids exactly that.
# ============================================================================
procedure emlGraphsReportBridgeIfNew: .tableId, .dataCol$, .groupCol$
    .print = 1
    if variableExists ("emlRunAnnotationComparison.printReport")
        .print = emlRunAnnotationComparison.printReport
    endif

    ; ITEM 1.2 — THE LINE THE BRIDGE LEFT FOR THIS PROCEDURE TO PRINT, if it
    ; left one. Read through variableExists for the same reason .printReport
    ; is: a caller that reaches here without a bridge run in front of it has
    ; no such output, and the answer there is the old one — say nothing extra
    ; and print the report. NESTED reads, not `and`: the second read is of a
    ; name the first has just established exists.
    .notePending = 0
    .note$ = ""
    if variableExists ("emlRunAnnotationComparison.notePending")
        .notePending = emlRunAnnotationComparison.notePending
        .note$ = emlRunAnnotationComparison.note$
    endif

    if .print = 1
        if .notePending = 1
            appendInfoLine: .note$
        endif
        @emlReportBridgeStats: .tableId, .dataCol$, .groupCol$
    endif
endproc


# ============================================================================
# @emlReportBridgeStats — thin dispatcher for graphs tool
# ============================================================================
# Called by eml-graphs.praat after @emlRunAnnotationComparison has run.
# Routes to the correct shared reporter based on bridge globals.
# Same 3-argument signature as the original monolithic reporter.
# ============================================================================
procedure emlReportBridgeStats: .tableId, .dataCol$, .groupCol$
    selectObject: .tableId
    .tableName$ = selected$ ("Table")
    .nGroups = emlRunAnnotationComparison.nGroups
    .testType$ = emlRunAnnotationComparison.testType$

    ; ------------------------------------------------------------------
    ; ITEM 3.5 -- WHAT THE BRIDGE DID, ASKED OF THE BRIDGE.
    ;
    ; THIS PROCEDURE STATES NOTHING ABOUT THE POST-HOC ON ITS OWN ACCOUNT.
    ; The Comparison menu decides whether a pairwise table is wanted, the
    ; bridge resolves that answer, and this reporter reports the run the
    ; bridge just made. A reporter that assumed instead is how the Info
    ; window comes to describe a post-hoc no figure ran, and how
    ; @emlDeclareTukeyResult comes to read a matrix nobody built.
    ;
    ; SO IT ASKS. .doTukey here is @emlRunAnnotationComparison's own resolved
    ; flag, read straight off the run that has just finished -- exactly the
    ; shape the Kruskal-Wallis arm below uses for .doDunn, which asks
    ; @emlDunnTest whether it succeeded rather than assuming it did. Guarded
    ; through variableExists so a caller that reaches this reporter without
    ; the bridge (a user script, a harness) still gets a post-hoc, and
    ; NESTED, never `and`: Praat evaluates both operands.
    ; ------------------------------------------------------------------
    .doTukey = 1
    if variableExists ("emlRunAnnotationComparison.doTukey")
        .doTukey = emlRunAnnotationComparison.doTukey
    endif

    @emlCSVInit

    if .nGroups = 2
        # 2-group: extract descriptives, route to TwoGroupComparison
        # Read the labels the bridge captured, not emlCountGroups' outputs:
        # @emlCountGroups is re-invoked by the tests the bridge runs, so its
        # outputs do not belong to this comparison by the time we get here.
        .g1$ = emlRunAnnotationComparison.gLabel$[1]
        .g2$ = emlRunAnnotationComparison.gLabel$[2]

        selectObject: .tableId
        @emlExtractGroupVectors: .tableId, .dataCol$, .groupCol$, .g1$, .g2$
        .v1# = emlExtractGroupVectors.group1#
        .v2# = emlExtractGroupVectors.group2#
        .n1 = emlExtractGroupVectors.n1
        .n2 = emlExtractGroupVectors.n2

        @emlMean: .v1#
        .mean1 = emlMean.result
        @emlSD: .v1#
        .sd1 = emlSD.result
        @emlMedian: .v1#
        .med1 = emlMedian.result

        @emlMean: .v2#
        .mean2 = emlMean.result
        @emlSD: .v2#
        .sd2 = emlSD.result
        @emlMedian: .v2#
        .med2 = emlMedian.result

        @emlReportTwoGroupComparison: .tableName$, .dataCol$, .groupCol$,
        ... .g1$, .g2$,
        ... .n1, .mean1, .sd1, .med1,
        ... .n2, .mean2, .sd2, .med2, .testType$

        # THREE-FILE DECLARATION, exactly the calls @emlRunTwoGroupAnalysis
        # makes after the same reporter. Without it the graphs entry
        # point ran the analysis, printed it and filled the legacy CSV buffer,
        # but never declared -- so the Exp CSV button could only ever write the
        # old single long-format file, for an analysis the stats menu exported
        # as tidy/glance/augment. v20/v21 enumerate the stats-menu
        # orchestrators; this path is reached from the graphs form and was
        # outside that enumeration.
        #
        # EXTRAS FIRST. Staging reuses the one tidy collector, so the model's
        # own tidy has to be what is left in it when @emlResultWrite runs.
        #
        # The graphs form offers a single Test type -- Parametric or
        # Nonparametric -- on every annotate-capable column-mapping dialog, so
        # annotTestType$ is never "both" here and the two flags are one branch.
        .doPar = 1
        .doNon = 0
        if .testType$ = "nonparametric"
            .doPar = 0
            .doNon = 1
        endif
        @emlResultClearExtras
        @emlDeclareTwoGroupEffects: .doPar, .doNon
        @emlResultStageExtra: "effectsize"
        @emlDeclareTwoGroupResult: .tableName$, .dataCol$, .groupCol$,
        ... .doPar, .doNon, .g1$, .g2$

    elsif .testType$ = "parametric"
        # k-group parametric: ANOVA, with the post-hoc the bridge ran
        ; ITEM 3.5 -- SITE 2 OF 2. This argument was the literal 1, and the
        ; comment beside it read "bridge ran with doTukey=1". It is now the
        ; bridge's own resolved flag, read at the top of this procedure.
        @emlReportAnovaComparison: .tableName$, .dataCol$, .groupCol$,
        ... .tableId, .nGroups, .doTukey

        # The declaration @emlRunAnovaAnalysis makes, extras staged first.
        ; ITEM 3.5 -- AND THE POST-HOC FRAME FOLLOWS THE SAME FLAG. The three
        ; declaration calls below take .doTukey exactly where
        ; @emlRunAnovaAnalysis passes it (stats/eml-analysis.praat, the
        ; `if emlOneWayAnova.error$ = ""` block), including the `if .doTukey`
        ; around @emlDeclareTukeyResult. That guard is not decoration:
        ; @emlDeclareTukeyResult reads emlOneWayAnova.pMatrix## and
        ; .groupName$[], which a .tukey = 0 run never builds. Both doors
        ; declare the same frames for the same run, which is the agreement
        ; v127's leg1 and leg3 are about.
        #
        # ONE GUARD OVER THE WHOLE SEQUENCE, which is the shape every other
        # declaring path uses -- the Kruskal branch below, and the ten
        # orchestrators in stats/eml-analysis.praat. The model declaration used
        # to sit OUTSIDE this `if`, with only @emlResultClearExtras and the two
        # extra frames inside it; @emlRunAnovaAnalysis carried the identical
        # split apart. The clear and the declaration are one
        # decision about one run of @emlOneWayAnova and belong under one
        # condition.
        #
        # WHAT THE SPLIT COST HERE, measured rather than assumed: nothing yet,
        # on three independent counts, and none of the three is a property of
        # this procedure. (1) The four call sites in eml-graphs-form.praat all
        # skip this procedure when emlRunAnnotationComparison.error$ is non-empty,
        # and the bridge copies emlOneWayAnova.error$ into that field, so the
        # guard cannot currently be false on the menu path. (2) Reached anyway
        # -- by a script calling the bridge and this reporter without that check
        # -- @emlReportAnovaComparison above aborts on the degenerate group data
        # first, indexing an empty group vector, so control never arrives here.
        # (3) @emlDeclareOneWayAnovaResult opens with the same
        # `emlOneWayAnova.error$ <> ""` test and returns before @emlResultBegin,
        # so the call outside the guard declared nothing.
        #
        # None of that is a reason to leave it split. What the missing clear
        # would have leaked -- the previous analysis's staged post-hoc and
        # effect-size frames, written beside its tidy and glance under THIS
        # analysis's base name -- is real and reproducible; it is held off only
        # by the @emlCSVInit at the top of this procedure, which zeroes
        # emlResult_declared and emlResult_extraN. Remove that one line and the
        # leak lands. Three accidental guards in other people's files are not a
        # guard.
        if emlOneWayAnova.error$ = ""
            @emlResultClearExtras
            if .doTukey
                @emlDeclareTukeyResult: .groupCol$
                @emlResultStageExtra: "posthoc"
            endif
            @emlDeclareAnovaEffectSizes: .groupCol$, .doTukey
            @emlResultStageExtra: "effectsize"
            @emlDeclareOneWayAnovaResult: .tableName$, .dataCol$, .groupCol$,
            ... .tableId, .doTukey
        endif

    else
        # k-group nonparametric: Kruskal-Wallis
        # THE OMNIBUS DOES NOT DECIDE THIS. Whether the user asked for a
        # post-hoc decides it: @emlRunAnnotationComparison runs Dunn's on
        # every nonparametric k-group draw regardless of the omnibus
        # outcome, so a quiet Kruskal-Wallis never silently withholds a
        # post-hoc the user's figure asked for. There is a post-hoc to
        # print whenever it SUCCEEDED.
        #
        # SUCCEEDED, not merely attempted, and the difference is a crash. With
        # .doDunn = 1 @emlReportKWComparison reads emlKruskalWallis.rMatrix##
        # and does not build it, and the bridge copies that matrix out of
        # @emlDunnTest only on the branch where Dunn's returned no error. A
        # .doDunn of 1 over a FAILED Dunn's would therefore print the error
        # text and then die on a matrix nobody made. Asking the same question
        # the copy asked keeps the two in step: the reporter builds the matrix
        # for itself, and its effect-size caption says no pairwise test was
        # run -- which is what happened.
        #
        # NESTED, NOT `and`: Praat evaluates both operands, so one condition
        # would read emlDunnTest's namespace on a run that never reached it.
        .doDunn = 0
        if variableExists ("emlDunnTest.error$")
            if emlDunnTest.error$ = ""
                .doDunn = 1
            endif
        endif
        @emlReportKWComparison: .tableName$, .dataCol$, .groupCol$,
        ... .tableId, .nGroups, .doDunn

        # The declaration @emlRunKruskalWallisAnalysis makes. NESTED ifs, not `and`, for
        # the reason given above.
        if emlKruskalWallis.error$ = ""
            @emlResultClearExtras
            if .doDunn = 1
                if variableExists ("emlDunnTest.error$")
                    if emlDunnTest.error$ = ""
                        @emlDeclareDunnResult: .groupCol$
                        @emlResultStageExtra: "posthoc"
                    endif
                endif
            endif
            @emlDeclareKWResult: .tableName$, .dataCol$, .groupCol$
        endif
    endif
endproc


# ============================================================================
# SHARED REPORTERS
# ============================================================================
# These procedures produce identical Info window output regardless of
# whether the user started from a stats wrapper or the graphs tool.
# They read from test result globals — callers must run the relevant
# test procedures BEFORE calling these reporters.
#
# Each reporter also populates CSV rows via @emlCSVAdd / @emlCSVAddStr /
# @emlCSVAddDescriptives (eml-output.praat) so @emlExportStatsCSV can write
# results to file. (There is no procedure that writes a whole analysis in one
# call; each of these appends one field of one term.)
# ============================================================================


# ============================================================================
# @emlReportTwoGroupComparison
# ============================================================================
procedure emlReportTwoGroupComparison: .tableName$, .dataCol$, .groupCol$, .group1$, .group2$, .n1, .mean1, .sd1, .median1, .n2, .mean2, .sd2, .median2, .testType$
    @emlUnderscoreToSpace: .tableName$
    .displayTable$ = emlUnderscoreToSpace.result$
    @emlUnderscoreToSpace: .dataCol$
    .displayData$ = emlUnderscoreToSpace.result$
    @emlUnderscoreToSpace: .groupCol$
    .displayGroup$ = emlUnderscoreToSpace.result$
    @emlUnderscoreToSpace: .group1$
    .displayG1$ = emlUnderscoreToSpace.result$
    @emlUnderscoreToSpace: .group2$
    .displayG2$ = emlUnderscoreToSpace.result$

    @emlReportHeader: "Two-Group Comparison"
    @emlReportLineString: "Table", .displayTable$
    @emlReportLineString: "Data column", .displayData$
    @emlReportLineString: "Group column", .displayGroup$
    @emlReportBlank
    @emlReportDescriptiveHeader
    @emlReportDescriptiveRow: .displayG1$, .n1, .mean1, .sd1, .median1
    @emlReportDescriptiveRow: .displayG2$, .n2, .mean2, .sd2, .median2

    ; THE DIRECTION IS STATED ONCE, FOR BOTH ARMS. The mean-difference row
    ; below names its own subtraction, but t, Cohen's d, Hedges' g, the
    ; Mann-Whitney z and the rank-biserial r are signed too and carry the
    ; same direction: the group this report lists first against the group it
    ; lists second. Which group is listed first follows the group order in
    ; force, so it changes with the ordering setting and cannot be inferred
    ; from the names.
    @emlReportNote: "Sign: every difference below is " + .displayG1$
    ... + " minus " + .displayG2$ + ", and t, z and the effect sizes carry "
    ... + "that direction."

    if .testType$ = "parametric" or .testType$ = "both"
        @emlFormatEffectLabel: emlCohenD.d, "d"
        @emlReportBlank
        @emlReportSection: emlTTest.method$
        if emlShowExplanations
            ; ITEM 1.2 — EXPLANATION LINES, THROUGH THE EXPLAIN HELPER,
            ; WHICH NEVER BUFFERS. The outer `if emlShowExplanations` stays:
            ; it is the shape every explanation site in this file has, and
            ; @emlExplainLine guards again so no route can print one with the
            ; toggle off. .wrap = 0 because these print verbatim on one line,
            ; exactly as they always did.
            if emlTTest.method$ = "Welch"
                @emlExplainLine: "  Why: Compares means of two independent "
                ... + "groups (robust to unequal variances).", 0
            else
                @emlExplainLine: "  Why: Compares means of two independent "
                ... + "groups (assumes equal variances).", 0
            endif
        endif
        if emlShowExplanations
            @emlWizardExplainT: emlTTest.t
        endif
        @emlReportLine: "t", emlTTest.t, 3
        if emlShowExplanations
            @emlWizardExplainDfTTest: emlTTest.df, emlTTest.method$
        endif
        @emlReportLine: "df", emlTTest.df, 1
        if emlShowExplanations
            @emlWizardExplainP: emlTTest.p
        endif
        ; A row label of "p" beside a value of "p = .032" would say "p"
        ; twice, and the < .001 floor hides the real value.
        ; @emlReportPWithExact prints the bare APA form and, when the label
        ; is floored, the unrounded value beside it.
        @emlReportPWithExact: "p", emlTTest.p
        if emlShowExplanations
            .diff = .mean1 - .mean2
            if .diff > 0
                @eml_fixed: abs (.diff), 2
                .fx1$ = eml_fixed.result$
                emlWizardExplain$ = .displayG1$ + " mean is " + .fx1$ + " units higher"
            else
                @eml_fixed: abs (.diff), 2
                .fx1$ = eml_fixed.result$
                emlWizardExplain$ = .displayG2$ + " mean is " + .fx1$ + " units higher"
            endif
        endif
        ; "Mean difference" alone never said which group was subtracted
        ; from which, so the sign was unreadable without inferring it from the
        ; descriptives table. The label now names the direction, using the same
        ; ordered group labels that table printed.
        .diffLabel$ = "Mean diff (" + .displayG1$ + " − " + .displayG2$ + ")"
        if length (.diffLabel$) >= 20
            ; @emlPadRight leaves an over-long label unpadded, which would run
            ; the value straight into the ")". One space keeps them apart.
            .diffLabel$ = .diffLabel$ + " "
        endif
        @emlReportLine: .diffLabel$, emlTTest.meanDiff, 4
        ; @emlTTest exposes no interval, so it is rebuilt here from the
        ; three quantities it does expose. Both the Student and the Welch
        ; branch form t as meanDiff / SE, so SE = meanDiff / t recovers the
        ; standard error exactly, whichever branch ran.
        .ciOK = 0
        if emlTTest.t <> undefined and emlTTest.df <> undefined
            if emlTTest.t <> 0 and emlTTest.df >= 1
                .ciOK = 1
            endif
        endif
        if .ciOK = 1
            ; THE LEVEL IS THE USER'S. The quantile comes from the alpha in
            ; force, so this interval states the same confidence as the stars
            ; above it and the error bars on the figure beside it, and the
            ; label carries that level with it — a reader never has to know
            ; which alpha was set to read the bracket.
            @emlCIAlphaInForce
            .ciAlpha = emlCIAlphaInForce.alpha
            .seDiff = abs (emlTTest.meanDiff / emlTTest.t)
            .tCritDiff = invStudentQ (.ciAlpha / 2, emlTTest.df)
            .diffLo = emlTTest.meanDiff - .tCritDiff * .seDiff
            .diffHi = emlTTest.meanDiff + .tCritDiff * .seDiff
            @eml_fixed: .diffLo, 4
            .fx1$ = eml_fixed.result$
            @eml_fixed: .diffHi, 4
            .fx2$ = eml_fixed.result$
            @emlCILevelLabel: .ciAlpha
            .ciDiffLabel$ = emlCILevelLabel.percent$ + "% CI of diff"
            @emlReportLineString: .ciDiffLabel$,
            ... "[" + .fx1$ + ", " + .fx2$ + "]"
        endif
        @emlReportBlank
        @emlReportSection: "Effect Size"
        if emlShowExplanations
            @emlWizardExplainEffectD: emlCohenD.d
        endif
        @emlReportLine: "Cohen's d", emlCohenD.d, 3
        if emlShowExplanations
            @emlWizardExplainEffectG: emlCohenD.g
        endif
        @emlReportLine: "Hedges' g", emlCohenD.g, 3
        @emlReportLineString: "Magnitude", emlFormatEffectLabel.labelPhrase$
        # Named fields, and an absent value writes no row.
        @emlCSVSetTable: .tableName$
        @emlCSVTermType: "contrast"
        .contrast$ = .group1$ + " vs " + .group2$
        @emlCSVAddStr: emlTTest.method$, .contrast$, "data_column", .dataCol$
        @emlCSVAddStr: emlTTest.method$, .contrast$, "group_column", .groupCol$
        @emlCSVAdd: emlTTest.method$, .contrast$, "t", emlTTest.t
        @emlCSVAdd: emlTTest.method$, .contrast$, "df", emlTTest.df
        @emlCSVAdd: emlTTest.method$, .contrast$, "p", emlTTest.p
        @emlCSVAdd: emlTTest.method$, .contrast$, "cohens_d", emlCohenD.d
        @emlCSVAddStr: emlTTest.method$, .contrast$, "effect_label",
        ... emlFormatEffectLabel.label$
        @emlCSVAddDescriptives: emlTTest.method$, .group1$,
        ... .n1, .mean1, .sd1, .median1
        @emlCSVAddDescriptives: emlTTest.method$, .group2$,
        ... .n2, .mean2, .sd2, .median2
    endif

    if .testType$ = "nonparametric" or .testType$ = "both"
        @emlFormatEffectLabel: abs (emlRankBiserialR.r), "r"
        @emlReportBlank
        @emlReportSection: "Mann-Whitney U Test"
        if emlShowExplanations
            ; ITEM 1.2 — EXPLANATION; never buffers.
            @emlExplainLine: "  Why: Compares distributions of two "
            ... + "independent groups without assuming normality.", 0
        endif
        if emlShowExplanations
            ; This gloss opened "Sum of
            ; ranks:", and U is not a sum of ranks. The rank sum is R1;
            ; @emlMannWhitneyU computes U1 = R1 - n1(n1+1)/2, which SUBTRACTS
            ; the smallest rank total group 1 could possibly have had. On the
            ; verification table R1 = 274 against the printed U1 = 64 --
            ; the printed number was right and the sentence next to it named
            ; a different statistic. Ian's readers are voice teachers who
            ; quote these lines to students, so a wrong name here becomes a
            ; wrong definition in a studio.
            ;
            ; What U actually counts is pairs: take every value in group 1
            ; against every value in group 2, n1 x n2 comparisons in all, and
            ; U1 is how many group 1 wins (ties count a half each). That is
            ; the interpretation the rest of the old sentence was already
            ; reaching for, which is why only the opening two words were
            ; wrong -- and why the replacement keeps the same shape.
            ;
            ; ASCII "x" and not the multiplication sign, deliberately: this
            ; string is also written to the plain-text report file, and the
            ; two neighbouring Wilcoxon glosses are ASCII throughout.
            emlWizardExplain$ = "U: how often a value from one group exceeds a value from the other, out of n1 x n2 possible pairs"
        endif
        @emlReportLine: "U1", emlMannWhitneyU.u1, 1
        @emlReportLine: "U2", emlMannWhitneyU.u2, 1
        if emlMannWhitneyU.z <> undefined
            @emlReportLine: "z", emlMannWhitneyU.z, 3
        endif
        if emlShowExplanations
            @emlWizardExplainP: emlMannWhitneyU.p
        endif
        @emlReportPWithExact: "p", emlMannWhitneyU.p
        ; ITEM 22 (language batch, Fable's ruling 27 August 2026): the
        ; disclosure row naming HOW the p above was computed. ALWAYS
        ; prints, never gated on emlShowExplanations -- @emlReportLineString
        ; itself never gates the row, only the third-column gloss beside it.
        ; "exact" prints bare; any approximation prints with EVERY reason
        ; that ruled out the exact branch, comma-separated, no precedence.
        .pMethod$ = emlMannWhitneyU.method$
        if emlMannWhitneyU.method$ <> "exact"
            .pMethod$ = .pMethod$ + " (" + emlMannWhitneyU.methodReason$ + ")"
        endif
        @emlReportLineString: "p method", .pMethod$
        # Report the method @emlMannWhitneyU actually used. Read it
        # defensively — a build of eml-inferential.praat that does not expose
        # .method$ must not abort the report. The routing rule is R's
        # wilcox.test rule: exact enumeration iff BOTH groups have n < 50 AND
        # there are no ties; otherwise the normal approximation with
        # continuity and tie corrections. The old gloss claimed the rule was
        # a total-n threshold, which is wrong in both directions.
        .mwuMethod$ = "not reported"
        if variableExists ("emlMannWhitneyU.method$")
            .mwuMethod$ = emlMannWhitneyU.method$
        endif
        if emlShowExplanations
            if .mwuMethod$ = "exact"
                emlWizardExplain$ = "P-value computed by exact enumeration"
                ... + " (used when both groups have n < 50 and there are no ties)"
            elsif .mwuMethod$ = "not reported"
                emlWizardExplain$ = "P-value method not reported by the test"
                ... + " procedure"
            else
                emlWizardExplain$ = "P-value computed by normal approximation"
                ... + " with continuity and tie corrections (used when either"
                ... + " group has n >= 50, or ties are present)"
            endif
        endif
        ; Legacy "Method" row retired 27 Aug 2026: it duplicated the
        ; "p method" disclosure row above. One fact, one row -- Fable.
        @emlReportBlank
        @emlReportSection: "Nonparametric Effect Size"
        if emlShowExplanations
            @emlWizardExplainEffectR: emlRankBiserialR.r
        endif
        @emlReportLine: "Rank-biserial r", emlRankBiserialR.r, 3
        @emlReportLineString: "Magnitude", emlFormatEffectLabel.labelPhrase$

        ; |r| = 1 IS A CEILING, NOT A RECORD. Rank-biserial r is the
        ; proportion of cross-group pairs favouring one group minus the
        ; proportion favouring the other, so it reaches 1 exactly when every
        ; observation in one group outranks every observation in the other.
        ; That is complete separation and it is the largest value the
        ; statistic can take -- which means it cannot distinguish a large
        ; difference from an enormous one, and it says nothing on its own
        ; about how much the groups differ BY. It is also cheap at small n:
        ; three against three separate completely by chance about once in ten
        ; runs. Called out because "1.000" beside "large" reads as the
        ; strongest possible finding when it is a boundary being touched.
        ; Praat does not short-circuit `and`, so the guard is nested.
        if emlRankBiserialR.r <> undefined
            if abs (emlRankBiserialR.r) >= 0.999999
                @emlReportNote: "Note: r = 1 means the two groups do not "
                ... + "overlap at all -- every value in one group outranks "
                ... + "every value in the other. This is the largest value "
                ... + "the statistic can take, so it marks complete "
                ... + "separation rather than measuring how far apart the "
                ... + "groups are, and it occurs readily in small samples. "
                ... + "Read it beside the group medians and n."
            endif
        endif
        if emlMannWhitneyU.z <> undefined
            .mwuDf = emlMannWhitneyU.z
        else
            .mwuDf = 0
        endif
        # The Mann-Whitney has no df at all, so no df row is written
        # rather than a zero standing in for one.
        @emlCSVSetTable: .tableName$
        @emlCSVTermType: "contrast"
        .contrast$ = .group1$ + " vs " + .group2$
        @emlCSVAddStr: "Mann-Whitney U", .contrast$, "data_column", .dataCol$
        @emlCSVAddStr: "Mann-Whitney U", .contrast$, "group_column", .groupCol$
        @emlCSVAdd: "Mann-Whitney U", .contrast$, "U", emlMannWhitneyU.u1
        @emlCSVAdd: "Mann-Whitney U", .contrast$, "p", emlMannWhitneyU.p
        @emlCSVAdd: "Mann-Whitney U", .contrast$, "rank_biserial_r",
        ... emlRankBiserialR.r
        @emlCSVAddStr: "Mann-Whitney U", .contrast$, "effect_label",
        ... emlFormatEffectLabel.label$
        @emlCSVAddDescriptives: "Mann-Whitney U", .group1$,
        ... .n1, .mean1, .sd1, .median1
        @emlCSVAddDescriptives: "Mann-Whitney U", .group2$,
        ... .n2, .mean2, .sd2, .median2
    endif

    @emlReportFooter
endproc


# ============================================================================
# @emlReportAnovaComparison
# ============================================================================
procedure emlReportAnovaComparison: .tableName$, .dataCol$, .groupCol$, .tableId, .nGroups, .doTukey
    @emlUnderscoreToSpace: .tableName$
    .displayTable$ = emlUnderscoreToSpace.result$
    @emlUnderscoreToSpace: .dataCol$
    .displayData$ = emlUnderscoreToSpace.result$
    @emlUnderscoreToSpace: .groupCol$
    .displayGroup$ = emlUnderscoreToSpace.result$

    @emlReportHeader: "One-Way ANOVA"
    @emlReportLineString: "Table", .displayTable$
    @emlReportLineString: "Data column", .displayData$
    @emlReportLineString: "Group column", .displayGroup$
    @emlReportLine: "Groups", .nGroups, 0
    .groupList$ = ""
    for .iGroup from 1 to .nGroups
        if .iGroup > 1
            .groupList$ = .groupList$ + ", "
        endif
        .groupList$ = .groupList$
            ... + replace$ (emlOneWayAnova.groupLabel$[.iGroup], "_", " ", 0)
    endfor
    @emlReportGroupOrderLine: .groupList$

    # ANOVA table
    @emlReportBlank
    @emlReportSection: "ANOVA Table"
    if emlShowExplanations
        ; ITEM 1.2 — EXPLANATION; never buffers.
        @emlExplainLine: "  Why: Tests whether group means differ "
        ... + "when normality and equal variances hold.", 0
    endif
    ; ITEM 1.2 — FACTUAL TABLE, THROUGH THE ONE EMIT HELPER. The
    ; comma-separated arguments become one concatenated string, because
    ; appendInfoLine joins its arguments with nothing between them: the
    ; printed bytes are unchanged and the buffer holds the line the reader
    ; sees, character for character.
    @emlEmit: "", ""
    @emlEmit: left$ ("Source" + "                    ", 20)
    ... + left$ ("SS" + "                ", 16)
    ... + left$ ("df" + "      ", 6)
    ... + left$ ("MS" + "                ", 16)
    ... + left$ ("F" + "            ", 12)
    ... + "p", ""

    # This cell was fixed$ (p, 6): "0.000019" under a column headed "p",
    # in the same report whose Games-Howell matrix prints the bare APA form
    # (".584") — one report, two spellings of the same quantity. It now takes
    # @emlFormatP's bare form, which is the shape the two-way source table
    # already uses: no leading
    # zero, floored at .001. Nothing is lost by the floor here — the "p" row
    # printed a few lines below goes through @emlReportPWithExact, which
    # restates the unrounded value in parentheses whenever the floor bites.
    @emlFormatP: emlOneWayAnova.p
    .pCell$ = emlFormatP.bare$

    @eml_fixed: emlOneWayAnova.ssBetween, 2
    .fx1$ = eml_fixed.result$
    @eml_fixed: emlOneWayAnova.msBetween, 2
    .fx2$ = eml_fixed.result$
    @eml_fixed: emlOneWayAnova.fValue, 4
    .fx3$ = eml_fixed.result$
    @emlEmit: left$ ("Between" + "                    ", 20)
    ... + left$ (.fx1$ + "                ", 16)
    ... + left$ (string$ (emlOneWayAnova.dfBetween) + "      ", 6)
    ... + left$ (.fx2$ + "                ", 16)
    ... + left$ (.fx3$ + "            ", 12)
    ... + .pCell$, ""
    @eml_fixed: emlOneWayAnova.ssWithin, 2
    .fx1$ = eml_fixed.result$
    @eml_fixed: emlOneWayAnova.msWithin, 2
    .fx2$ = eml_fixed.result$
    @emlEmit: left$ ("Within" + "                    ", 20)
    ... + left$ (.fx1$ + "                ", 16)
    ... + left$ (string$ (emlOneWayAnova.dfWithin) + "      ", 6)
    ... + left$ (.fx2$ + "                ", 16), ""
    @eml_fixed: emlOneWayAnova.ssTotal, 2
    .fx1$ = eml_fixed.result$
    @emlEmit: left$ ("Total" + "                    ", 20)
    ... + left$ (.fx1$ + "                ", 16)
    ... + left$ (string$ (emlOneWayAnova.dfTotal) + "      ", 6), ""

    @emlReportBlank
    if emlShowExplanations
        @emlWizardExplainF: emlOneWayAnova.fValue
    endif
    @eml_fixed: emlOneWayAnova.fValue, 4
    .fx1$ = eml_fixed.result$
    @emlReportLineString: "F", .fx1$
    if emlShowExplanations
        @emlWizardExplainP: emlOneWayAnova.p
    endif
    @emlReportPWithExact: "p", emlOneWayAnova.p
    .etaSq = emlOneWayAnova.etaSquared
    if emlShowExplanations
        @emlWizardExplainEffectEta2: .etaSq
    endif
    @eml_fixed: .etaSq, 4
    .fx1$ = eml_fixed.result$
    @emlReportLineString: "Effect size", "eta-squared = " + .fx1$

    ; --- Equal-spread check (conditional show-both) ------------------------
    ; Brown-Forsythe runs ALWAYS and prints ALWAYS. The test above is never
    ; replaced and never switched: what the plugin reports as Student's F it
    ; goes on calling Student's F, whatever this line says. When the check
    ; rejects, a second block is appended below with Welch's F and
    ; Games-Howell, so the user is handed the tolerant version rather than
    ; only being told there is a problem.
    ;
    ; Wording is deliberate. This is a smoke alarm, not a verdict -- at small
    ; n it misses real inequality, at large n it flags inequality too small to
    ; matter. It never says the data failed anything.
    @emlBrownForsythe: .tableId, .dataCol$, .groupCol$
    .bfRan = 0
    .bfFlags = 0
    if emlBrownForsythe.error$ = ""
        .bfRan = 1
        if emlBrownForsythe.p < 0.05
            .bfFlags = 1
        endif
    endif

    if .bfRan
        if emlShowExplanations
            ; ITEM 1.2 — EXPLANATION; never buffers.
            @emlExplainLine: "  Why: The ANOVA above pools one within-group "
            ... + "spread across all groups. This checks whether that is a "
            ... + "fair thing to do here.", 0
        endif
        @eml_fixed: emlBrownForsythe.f, 4
        .fx1$ = eml_fixed.result$
        @emlReportLineString: "Equal spread",
        ... "Brown-Forsythe F(" + string$ (emlBrownForsythe.df1) + ", "
        ... + string$ (emlBrownForsythe.df2) + ") = "
        ... + .fx1$
        @emlReportPWithExact: "Equal-spread p", emlBrownForsythe.p
        if .bfFlags
            @emlReportNote: "Note: the groups differ in spread more than "
            ... + "this ANOVA's pooled error term likes. The result above is "
            ... + "still the one being reported. A version that tolerates "
            ... + "unequal spread is printed at the end of this report, "
            ... + "under If the spreads are unequal; compare the two."
        endif
    endif

    @emlFormatEffectLabel: .etaSq, "eta_squared"
    .etaLabel$ = emlFormatEffectLabel.label$
    # A wide schema would end this row in eight zeros meaning "not
    # applicable".
    # Both df now have their own field, so F(2,42) survives export.
    @emlCSVSetTable: .tableName$
    @emlCSVTermType: "omnibus"
    @emlCSVAddStr: "One-way ANOVA", "", "data_column", .dataCol$
    @emlCSVAddStr: "One-way ANOVA", "", "group_column", .groupCol$
    @emlCSVAdd: "One-way ANOVA", "", "F", emlOneWayAnova.fValue
    @emlCSVAdd: "One-way ANOVA", "", "df1", emlOneWayAnova.dfBetween
    @emlCSVAdd: "One-way ANOVA", "", "df2", emlOneWayAnova.dfWithin
    @emlCSVAdd: "One-way ANOVA", "", "p", emlOneWayAnova.p
    @emlCSVAdd: "One-way ANOVA", "", "eta_squared", .etaSq
    @emlCSVAddStr: "One-way ANOVA", "", "effect_label", .etaLabel$
    @emlCSVAdd: "One-way ANOVA", "", "ss_between", emlOneWayAnova.ssBetween
    @emlCSVAdd: "One-way ANOVA", "", "ss_within", emlOneWayAnova.ssWithin
    @emlCSVAdd: "One-way ANOVA", "", "ms_between", emlOneWayAnova.msBetween
    @emlCSVAdd: "One-way ANOVA", "", "ms_within", emlOneWayAnova.msWithin
    @emlCSVAdd: "One-way ANOVA", "", "n_groups", emlOneWayAnova.nGroups

    # Group descriptives
    @emlReportBlank
    @emlReportSection: "Group Descriptives"
    @emlReportDescriptiveHeader

    for .gIdx from 1 to .nGroups
        @eml_getGroupData: .tableId, .dataCol$, .groupCol$,
        ... emlOneWayAnova.groupLabel$[.gIdx]
        .gN = eml_getGroupData.n
        .gData# = eml_getGroupData.data#
        .gMean = mean (.gData#)
        .gSD = stdev (.gData#)
        .gSorted# = sort# (.gData#)
        .gMidIdx = ceiling (.gN / 2)
        if .gN mod 2 = 1
            .gMedian = .gSorted# [.gMidIdx]
        else
            .gMedian = (.gSorted# [.gMidIdx] + .gSorted# [.gMidIdx + 1]) / 2
        endif
        .gDisplayLabel$ = replace$ (emlOneWayAnova.groupLabel$[.gIdx], "_", " ", 0)
        @emlReportDescriptiveRow: .gDisplayLabel$, .gN, .gMean, .gSD, .gMedian
    endfor

    # Tukey pairwise p-values (only when Tukey ran)
    if .doTukey
        @emlReportBlank
        @emlReportSection: "Tukey HSD Pairwise Comparisons (p-values)"
        @emlEmit: "", ""
        .headerLine$ = left$ ("" + "                ", 14)
        for .jGroup from 1 to .nGroups
            .colName$ = replace$ (emlOneWayAnova.groupLabel$[.jGroup], "_", " ", 0)
            if length (.colName$) > 10
                .colName$ = left$ (.colName$, 10)
            endif
            .headerLine$ = .headerLine$ + left$ (.colName$ + "            ", 12)
        endfor
        @emlEmit: .headerLine$, ""
        for .iGroup from 1 to .nGroups
            .rowName$ = replace$ (emlOneWayAnova.groupLabel$[.iGroup], "_", " ", 0)
            if length (.rowName$) > 12
                .rowName$ = left$ (.rowName$, 12)
            endif
            .rowLine$ = left$ (.rowName$ + "                ", 14)
            for .jGroup from 1 to .nGroups
                if .iGroup = .jGroup
                    .cellText$ = "---"
                else
                    ; Was a hand-rolled floor plus fixed$ (p, 4), so
                    ; this matrix printed "0.4918" while the Games-Howell
                    ; matrix 35 lines below printed ".584" — the same
                    ; quantity, two formats, visible together in one report.
                    ; @emlFormatP is the single spelling: no leading zero,
                    ; the .001 floor, and the .999 ceiling and the undefined
                    ; case that the hand-rolled branch did not cover (an
                    ; undefined p fell through to fixed$ and rendered as
                    ; "--undefined--").
                    .pVal = emlOneWayAnova.pMatrix##[.iGroup, .jGroup]
                    @emlFormatP: .pVal
                    .cellText$ = emlFormatP.bare$
                endif
                .rowLine$ = .rowLine$ + left$ (.cellText$ + "            ", 12)
            endfor
            @emlEmit: .rowLine$, ""
        endfor

        # The matrix above reports adjusted p and nothing else, so a
        # reader cannot state a result — the quantity a result is stated in is
        # the mean difference and its interval. No new numerics are needed:
        # @emlOneWayAnova already exposes the signed differences, the critical
        # q at alpha = .05, MS_within and the group sizes, so the family-wise
        # half-width is qCritical * sqrt(MSw/2 * (1/ni + 1/nj)).
        @emlReportBlank
        @emlReportSection: "Tukey HSD Mean Differences (95% family-wise CI)"
        @emlEmit: "", ""
        ; THE COMPARISON COLUMN IS MEASURED, NOT ASSUMED. A fixed cut at 24
        ; characters is silent when it bites: two groups whose names share a
        ; prefix -- "Soprano belt trained" and "Soprano belt untrained" --
        ; give two different comparisons whose first 24 characters are
        ; identical, so two rows print under one label with nothing on the
        ; page to tell them apart, and a reader attributes an interval to the
        ; wrong pair. The width is therefore taken from the widest comparison
        ; this table actually holds and no name is cut.
        ;
        ; ORDINARY REPORTS ARE UNCHANGED. The floor is the 26 this table has
        ; always been laid out on, so any table whose longest comparison fits
        ; in 24 characters prints exactly as it did; only a table that would
        ; otherwise have collided gets a wider column, and a wide column is
        ; visible where a collision is not.
        .cmpWidth = 26
        for .iGroup from 1 to .nGroups - 1
            for .jGroup from .iGroup + 1 to .nGroups
                .measure$ = replace$ (emlOneWayAnova.groupLabel$[.iGroup],
                ... "_", " ", 0)
                ... + " − "
                ... + replace$ (emlOneWayAnova.groupLabel$[.jGroup],
                ... "_", " ", 0)
                if length (.measure$) + 2 > .cmpWidth
                    .cmpWidth = length (.measure$) + 2
                endif
            endfor
        endfor
        @emlPadRight: "Comparison", .cmpWidth
        ; ITEM 1.2 — factual table header.
        @emlEmit: emlPadRight.result$
        ... + left$ ("Difference" + "              ", 14)
        ... + "95% CI", ""
        for .iGroup from 1 to .nGroups - 1
            for .jGroup from .iGroup + 1 to .nGroups
                .ciName$ = replace$ (emlOneWayAnova.groupLabel$[.iGroup], "_", " ", 0)
                ... + " − "
                ... + replace$ (emlOneWayAnova.groupLabel$[.jGroup], "_", " ", 0)
                .tukeyDiff = emlOneWayAnova.meanDiff## [.iGroup, .jGroup]
                .tukeyHalf = undefined
                if emlOneWayAnova.qCritical <> undefined
                    .tukeyHalf = emlOneWayAnova.qCritical
                    ... * sqrt (emlOneWayAnova.msWithin / 2
                    ... * (1 / emlOneWayAnova.groupN[.iGroup]
                    ... + 1 / emlOneWayAnova.groupN[.jGroup]))
                endif
                if .tukeyHalf = undefined or .tukeyDiff = undefined
                    .ciText$ = "not available"
                else
                    @eml_fixed: .tukeyDiff - .tukeyHalf, 4
                    .fx1$ = eml_fixed.result$
                    @eml_fixed: .tukeyDiff + .tukeyHalf, 4
                    .fx2$ = eml_fixed.result$
                    .ciText$ = "[" + .fx1$
                    ... + ", " + .fx2$ + "]"
                endif
                @eml_fixed: .tukeyDiff, 4
                .fx1$ = eml_fixed.result$
                ; @emlPadRight pads and never cuts, and .cmpWidth was
                ; measured to be at least two wider than this name, so the
                ; gutter before the Difference column survives every name.
                @emlPadRight: .ciName$, .cmpWidth
                ; ITEM 1.2 — factual table row.
                @emlEmit: emlPadRight.result$
                ... + left$ (.fx1$ + "              ", 14)
                ... + .ciText$, ""
            endfor
        endfor

        # CSV rows for Tukey pairwise
        for .iGroup from 1 to .nGroups - 1
            for .jGroup from .iGroup + 1 to .nGroups
                .pVal = emlOneWayAnova.pMatrix##[.iGroup, .jGroup]
                .g1Label$ = emlOneWayAnova.groupLabel$[.iGroup]
                .g2Label$ = emlOneWayAnova.groupLabel$[.jGroup]
                @eml_getGroupData: .tableId, .dataCol$, .groupCol$, .g1Label$
                .n1 = eml_getGroupData.n
                .v1# = eml_getGroupData.data#
                @eml_getGroupData: .tableId, .dataCol$, .groupCol$, .g2Label$
                .n2 = eml_getGroupData.n
                .v2# = eml_getGroupData.data#
                .pairD = emlOneWayAnova.dMatrix## [.iGroup, .jGroup]
                @emlMean: .v1#
                .m1 = emlMean.result
                @emlSD: .v1#
                .s1 = emlSD.result
                @emlMedian: .v1#
                .md1 = emlMedian.result
                @emlMean: .v2#
                .m2 = emlMean.result
                @emlSD: .v2#
                .s2 = emlSD.result
                @emlMedian: .v2#
                .md2 = emlMedian.result
                @emlFormatEffectLabel: .pairD, "d"
                .dLabel$ = emlFormatEffectLabel.label$
                @emlCSVSetTable: .tableName$
                @emlCSVTermType: "contrast"
                .contrast$ = .g1Label$ + " vs " + .g2Label$
                @emlCSVAdd: "Tukey HSD", .contrast$, "q",
                ... emlOneWayAnova.qMatrix## [.iGroup, .jGroup]
                @emlCSVAdd: "Tukey HSD", .contrast$, "df",
                ... emlOneWayAnova.dfWithin
                @emlCSVAdd: "Tukey HSD", .contrast$, "p_adjusted", .pVal
                @emlCSVAdd: "Tukey HSD", .contrast$, "cohens_d", .pairD
                @emlCSVAddStr: "Tukey HSD", .contrast$, "effect_label", .dLabel$
                @emlCSVAddDescriptives: "Tukey HSD", .g1Label$,
                ... .n1, .m1, .s1, .md1
                @emlCSVAddDescriptives: "Tukey HSD", .g2Label$,
                ... .n2, .m2, .s2, .md2
            endfor
        endfor

        ; THE POST-HOC RAN, AND THE OMNIBUS MAY NOT HAVE. Under the ruled
        ; policy Tukey is never gated on the ANOVA, so this report can
        ; carry a pairwise table under an F that did not reach the level
        ; in force. The caveat is stated in a sentence rather than left
        ; implicit in the table's absence. See @emlPostHocCaution for the
        ; routing and for where the level comes from.
        @emlPostHocCaution: emlOneWayAnova.p
    endif

    # Pairwise Cohen's d (ALWAYS — bug #11 fix)
    # When called via orchestrator, dMatrix## is pre-computed.
    # When called directly (backward compat), compute it here.
    if .doTukey = 0
        emlOneWayAnova.dMatrix## = zero## (.nGroups, .nGroups)
        for .i from 1 to .nGroups - 1
            @eml_getGroupData: .tableId, .dataCol$, .groupCol$,
            ... emlOneWayAnova.groupLabel$[.i]
            .tmpV1# = eml_getGroupData.data#
            for .j from .i + 1 to .nGroups
                @eml_getGroupData: .tableId, .dataCol$, .groupCol$,
                ... emlOneWayAnova.groupLabel$[.j]
                @emlCohenD: .tmpV1#, eml_getGroupData.data#
                if emlCohenD.error$ = ""
                    emlOneWayAnova.dMatrix## [.i, .j] = emlCohenD.d
                    emlOneWayAnova.dMatrix## [.j, .i] = -emlCohenD.d
                else
                    ; Punch list 9.1, the sibling of the fix in
                    ; stats/eml-analysis.praat: a failed pair must not read
                    ; as a true zero effect. The print loop below now shows
                    ; "n/a" for it.
                    emlOneWayAnova.dMatrix## [.i, .j] = undefined
                    emlOneWayAnova.dMatrix## [.j, .i] = undefined
                endif
            endfor
        endfor
    endif
    @emlReportBlank
    @emlReportSection: "Pairwise Effect Sizes (Cohen's d)"
    ; WITH TUKEY OFF THIS GRID IS THE ONLY PAIRWISE THING IN THE REPORT, and
    ; an unlabelled grid under a heading reading "pairwise" is read as
    ; significance by someone skimming. The caption says what was not
    ; computed; its disclosure half prints whatever the explanations toggle
    ; says. Nothing is said when Tukey DID run — the adjusted p-values are
    ; right above.
    if .doTukey = 0
        @emlEffectMatrixCaption
    endif
    @emlEmit: "", ""
    .dHeaderLine$ = left$ ("" + "                ", 14)
    for .jGroup from 1 to .nGroups
        .colName$ = replace$ (emlOneWayAnova.groupLabel$[.jGroup], "_", " ", 0)
        if length (.colName$) > 10
            .colName$ = left$ (.colName$, 10)
        endif
        .dHeaderLine$ = .dHeaderLine$ + left$ (.colName$ + "            ", 12)
    endfor
    @emlEmit: .dHeaderLine$, ""
    for .iGroup from 1 to .nGroups
        .rowName$ = replace$ (emlOneWayAnova.groupLabel$[.iGroup], "_", " ", 0)
        if length (.rowName$) > 12
            .rowName$ = left$ (.rowName$, 12)
        endif
        .dRowLine$ = left$ (.rowName$ + "                ", 14)
        for .jGroup from 1 to .nGroups
            if .iGroup = .jGroup
                .cellText$ = "---"
            else
                .dVal = emlOneWayAnova.dMatrix## [.iGroup, .jGroup]
                if .dVal = undefined
                    ; Punch list 9.1. A failed pair prints as unavailable,
                    ; never as 0 -- same convention as @emlPairwiseT's own
                    ; d matrix above in this report.
                    .cellText$ = "n/a"
                else
                    @eml_fixed: .dVal, 3
                    .cellText$ = eml_fixed.result$
                endif
            endif
            .dRowLine$ = .dRowLine$ + left$ (.cellText$ + "            ", 12)
        endfor
        @emlEmit: .dRowLine$, ""
    endfor
    ; The Tukey p matrix above is SYMMETRIC and this one is ANTISYMMETRIC:
    ; d[i, j] is -d[j, i], so the sign here is the direction of the
    ; difference and not the strength of the effect. The convention is the
    ; one @emlReportPairwiseComparison prints under its own d matrix, in the
    ; same words, because a reader meeting both should meet one rule.
    @emlReportNote: "Row minus column: a negative d means the ROW group's "
    ... + "mean is lower than the COLUMN group's. |d| is the effect size."

    # CSV rows for Cohen's d only (when Tukey did NOT run)
    if .doTukey = 0
        for .iGroup from 1 to .nGroups - 1
            for .jGroup from .iGroup + 1 to .nGroups
                .g1Label$ = emlOneWayAnova.groupLabel$[.iGroup]
                .g2Label$ = emlOneWayAnova.groupLabel$[.jGroup]
                @eml_getGroupData: .tableId, .dataCol$, .groupCol$, .g1Label$
                .n1 = eml_getGroupData.n
                .v1# = eml_getGroupData.data#
                @eml_getGroupData: .tableId, .dataCol$, .groupCol$, .g2Label$
                .n2 = eml_getGroupData.n
                .v2# = eml_getGroupData.data#
                .pairD = emlOneWayAnova.dMatrix## [.iGroup, .jGroup]
                @emlMean: .v1#
                .m1 = emlMean.result
                @emlSD: .v1#
                .s1 = emlSD.result
                @emlMedian: .v1#
                .md1 = emlMedian.result
                @emlMean: .v2#
                .m2 = emlMean.result
                @emlSD: .v2#
                .s2 = emlSD.result
                @emlMedian: .v2#
                .md2 = emlMedian.result
                @emlFormatEffectLabel: .pairD, "d"
                .dLabel$ = emlFormatEffectLabel.label$
                # This branch has no test statistic and
                # no p, so writing 0, 0, 0 would make the row read as the
                # most significant result in the file. It now writes the
                # effect size it actually has and nothing else.
                @emlCSVSetTable: .tableName$
                @emlCSVTermType: "contrast"
                .contrast$ = .g1Label$ + " vs " + .g2Label$
                @emlCSVAdd: "Pairwise Cohen's d", .contrast$, "cohens_d",
                ... .pairD
                @emlCSVAddStr: "Pairwise Cohen's d", .contrast$,
                ... "effect_label", .dLabel$
                @emlCSVAddDescriptives: "Pairwise Cohen's d", .g1Label$,
                ... .n1, .m1, .s1, .md1
                @emlCSVAddDescriptives: "Pairwise Cohen's d", .g2Label$,
                ... .n2, .m2, .s2, .md2
            endfor
        endfor
    endif

    ; --- The tolerant version, printed only when the check rejected --------
    ; Never replace, never auto-switch, never make the reported
    ; primary test depend on the data. This block is ADDITIONAL. When
    ; Brown-Forsythe does not reject, a run looks exactly as it did before
    ; this feature existed, apart from the two equal-spread lines above --
    ; which is what keeps every committed capture, and Tier A property A1
    ; (F = t^2 at k = 2, an identity that Welch's F does NOT satisfy against
    ; Student's t), valid.
    if .bfFlags
        @emlReportBlank
        @emlReportSection: "If the spreads are unequal"
        @emlReportNote: "Welch's F does not pool the within-group spread, "
        ... + "and Games-Howell uses each pair's own spread instead of one "
        ... + "shared error term. Where these land on the same side of the "
        ... + "5% threshold as the block above, the unequal spread did not "
        ... + "change the thresholded decision in this sample -- which is "
        ... + "not the same as the two methods agreeing, and says nothing "
        ... + "about the next sample. Where they disagree, prefer these; "
        ... + "that is what they are for."

        @emlWelchAnova: .tableId, .dataCol$, .groupCol$
        if emlWelchAnova.error$ <> ""
            @emlReportLineString: "Welch's F",
            ... "not available -- " + emlWelchAnova.error$
        else
            @emlReportBlank
            @eml_fixed: emlWelchAnova.df2, 2
            .fx1$ = eml_fixed.result$
            @eml_fixed: emlWelchAnova.f, 4
            .fx2$ = eml_fixed.result$
            @emlReportLineString: "Welch's F",
            ... "F(" + string$ (emlWelchAnova.df1) + ", "
            ... + .fx1$ + ") = "
            ... + .fx2$
            @emlReportPWithExact: "Welch p", emlWelchAnova.p

            @emlCSVSetTable: .tableName$
            @emlCSVTermType: "omnibus"
            @emlCSVAddStr: "Welch ANOVA", "", "data_column", .dataCol$
            @emlCSVAddStr: "Welch ANOVA", "", "group_column", .groupCol$
            @emlCSVAdd: "Welch ANOVA", "", "F", emlWelchAnova.f
            @emlCSVAdd: "Welch ANOVA", "", "df1", emlWelchAnova.df1
            @emlCSVAdd: "Welch ANOVA", "", "df2", emlWelchAnova.df2
            @emlCSVAdd: "Welch ANOVA", "", "p", emlWelchAnova.p
            @emlCSVAdd: "Welch ANOVA", "", "n_groups", emlWelchAnova.nGroups
        endif

        ; Games-Howell only when there is more than one pair to draw. At
        ; k = 2 Welch's F above already IS that comparison, and a one-cell
        ; matrix would restate it.
        if .nGroups > 2
            @emlGamesHowell: .tableId, .dataCol$, .groupCol$, 0.05
            if emlGamesHowell.error$ <> ""
                @emlReportLineString: "Games-Howell",
                ... "not available -- " + emlGamesHowell.error$
            else
                @emlReportBlank
                @emlReportSection:
                ... "Games-Howell Pairwise Comparisons (p-values)"
                @emlEmit: "", ""
                .ghHeader$ = left$ ("" + "                ", 14)
                for .jGroup from 1 to .nGroups
                    .ghCol$ = replace$ (emlGamesHowell.groupName$[.jGroup],
                    ... "_", " ", 0)
                    if length (.ghCol$) > 10
                        .ghCol$ = left$ (.ghCol$, 10)
                    endif
                    .ghHeader$ = .ghHeader$
                    ... + left$ (.ghCol$ + "            ", 12)
                endfor
                @emlEmit: .ghHeader$, ""
                for .iGroup from 1 to .nGroups
                    .ghRow$ = replace$ (emlGamesHowell.groupName$[.iGroup],
                    ... "_", " ", 0)
                    if length (.ghRow$) > 12
                        .ghRow$ = left$ (.ghRow$, 12)
                    endif
                    .ghLine$ = left$ (.ghRow$ + "              ", 14)
                    for .jGroup from 1 to .nGroups
                        if .iGroup = .jGroup
                            .ghCell$ = "--"
                        else
                            .ghP = emlGamesHowell.pMatrix##[.iGroup, .jGroup]
                            if .ghP = undefined
                                .ghCell$ = "n/a"
                            else
                                @emlFormatP: .ghP
                                .ghCell$ = emlFormatP.bare$
                            endif
                        endif
                        .ghLine$ = .ghLine$
                        ... + left$ (.ghCell$ + "            ", 12)
                    endfor
                    @emlEmit: .ghLine$, ""
                endfor

                for .iGroup from 1 to .nGroups - 1
                    for .jGroup from .iGroup + 1 to .nGroups
                        .ghP = emlGamesHowell.pMatrix##[.iGroup, .jGroup]
                        if .ghP <> undefined
                            @emlCSVSetTable: .tableName$
                            @emlCSVTermType: "contrast"
                            .ghContrast$ = emlGamesHowell.groupName$[.iGroup]
                            ... + " vs " + emlGamesHowell.groupName$[.jGroup]
                            @emlCSVAdd: "Games-Howell", .ghContrast$, "q",
                            ... emlGamesHowell.qMatrix## [.iGroup, .jGroup]
                            @emlCSVAdd: "Games-Howell", .ghContrast$, "df",
                            ... emlGamesHowell.dfMatrix## [.iGroup, .jGroup]
                            @emlCSVAdd: "Games-Howell", .ghContrast$,
                            ... "p_adjusted", .ghP
                            @emlCSVAdd: "Games-Howell", .ghContrast$,
                            ... "cohens_d",
                            ... emlGamesHowell.dMatrix## [.iGroup, .jGroup]
                        endif
                    endfor
                endfor

                if emlGamesHowell.nUndefined > 0
                    @emlReportNote: string$ (emlGamesHowell.nUndefined)
                    ... + " pair(s) could not be computed -- a group with "
                    ... + "fewer than two values, or zero variance in both "
                    ... + "groups of a pair, leaves the Welch denominator "
                    ... + "undefined. Those cells read n/a rather than "
                    ... + "carrying a number with no meaning."
                endif
            endif
        endif
    endif

    @emlReportFooter
endproc


# ============================================================================
# @emlReportKWComparison
# ============================================================================
procedure emlReportKWComparison: .tableName$, .dataCol$, .groupCol$, .tableId, .nGroups, .doDunn
    @emlUnderscoreToSpace: .tableName$
    .displayTable$ = emlUnderscoreToSpace.result$
    @emlUnderscoreToSpace: .dataCol$
    .displayData$ = emlUnderscoreToSpace.result$
    @emlUnderscoreToSpace: .groupCol$
    .displayGroup$ = emlUnderscoreToSpace.result$

    @emlReportHeader: "Kruskal-Wallis H Test"
    @emlReportLineString: "Table", .displayTable$
    @emlReportLineString: "Data column", .displayData$
    @emlReportLineString: "Group column", .displayGroup$
    @emlReportLine: "Groups", .nGroups, 0
    @emlReportLine: "Total N", emlKruskalWallis.n, 0
    .groupList$ = ""
    for .iGroup from 1 to .nGroups
        if .iGroup > 1
            .groupList$ = .groupList$ + ", "
        endif
        .groupList$ = .groupList$
            ... + replace$ (emlKruskalWallis.groupName$ [.iGroup], "_", " ", 0)
    endfor
    @emlReportGroupOrderLine: .groupList$

    @emlReportBlank
    @emlReportSection: "Omnibus Test"
    if emlShowExplanations
        ; ITEM 1.2 — EXPLANATION; never buffers.
        @emlExplainLine: "  Why: Nonparametric comparison of three or "
        ... + "more groups. Every observation is ranked in one pooled "
        ... + "ranking and the groups' mean ranks are compared, so no "
        ... + "normal distribution is assumed. Observations must still be "
        ... + "independent, and reading the result as a difference in "
        ... + "MEDIANS additionally requires the groups to have similar "
        ... + "distribution shapes.", 0
    endif
    if emlShowExplanations
        emlWizardExplain$ = "Test statistic: how far the groups' mean "
        ... + "ranks sit from the overall mean rank. Its p comes from a "
        ... + "chi-squared approximation, which improves as the groups grow"
    endif
    @emlReportLine: "H", emlKruskalWallis.h, 4
    if emlShowExplanations
        emlWizardExplain$ = "Number of groups (" + string$ (.nGroups)
        ... + ") minus 1. Controls the chi-squared reference distribution."
    endif
    @emlReportLine: "df", emlKruskalWallis.df, 0
    if emlShowExplanations
        @emlWizardExplainP: emlKruskalWallis.p
    endif
    ; The omnibus p was floored to "p = .003" with the real value
    ; Reachable only from the CSV, and the label was printed twice.
    @emlReportPWithExact: "p", emlKruskalWallis.p
    if emlShowExplanations
        @emlWizardExplainEffectEpsilon2: emlKruskalWallis.epsilonSq
    endif
    @emlReportLine: "Epsilon-squared", emlKruskalWallis.epsilonSq, 4
    @emlFormatEffectLabel: emlKruskalWallis.epsilonSq, "eta_squared"
    @emlReportLineString: "Effect magnitude", emlFormatEffectLabel.labelPhrase$

    @emlCSVSetTable: .tableName$
    @emlCSVTermType: "omnibus"
    @emlCSVAddStr: "Kruskal-Wallis", "", "data_column", .dataCol$
    @emlCSVAddStr: "Kruskal-Wallis", "", "group_column", .groupCol$
    @emlCSVAdd: "Kruskal-Wallis", "", "H", emlKruskalWallis.h
    @emlCSVAdd: "Kruskal-Wallis", "", "df", emlKruskalWallis.df
    @emlCSVAdd: "Kruskal-Wallis", "", "p", emlKruskalWallis.p
    @emlCSVAdd: "Kruskal-Wallis", "", "epsilon_squared",
    ... emlKruskalWallis.epsilonSq
    @emlCSVAddStr: "Kruskal-Wallis", "", "effect_label",
    ... emlFormatEffectLabel.label$

    # Group order controlled by @emlCountGroups
    # Group order from @emlCountGroups (no remapping needed)

    # Group mean ranks
    @emlReportBlank
    @emlReportSection: "Group Mean Ranks"
    @emlEmit: "", ""
    .grpHeader$ = left$ ("Group" + "                ", 14)
    ... + left$ ("N" + "      ", 6) + "Mean Rank"
    @emlEmit: .grpHeader$, ""
    for .iGroup from 1 to .nGroups
        .gName$ = replace$ (emlKruskalWallis.groupName$ [.iGroup], "_", " ", 0)
        if length (.gName$) > 12
            .gName$ = left$ (.gName$, 12)
        endif
        @eml_fixed: emlKruskalWallis.meanRank [.iGroup], 2
        .fx1$ = eml_fixed.result$
        ; ITEM 1.2 — factual table row.
        @emlEmit: left$ (.gName$ + "                ", 14)
        ... + left$ (string$ (emlKruskalWallis.groupN [.iGroup]) + "      ", 6)
        ... + .fx1$, ""
    endfor

    if .doDunn
        if emlDunnTest.error$ = ""
            .adjLabel$ = emlDunnTest.method$
            @emlReportBlank
            @emlReportSection: "Dunn's Post-Hoc (adjusted p, " + .adjLabel$ + ")"
            @emlEmit: "", ""
            .headerLine$ = left$ ("" + "                ", 14)
            for .jGroup from 1 to .nGroups
                .colName$ = replace$ (emlDunnTest.groupName$ [.jGroup], "_", " ", 0)
                if length (.colName$) > 10
                    .colName$ = left$ (.colName$, 10)
                endif
                .headerLine$ = .headerLine$ + left$ (.colName$ + "            ", 12)
            endfor
            @emlEmit: .headerLine$, ""
            for .iGroup from 1 to .nGroups
                .rowName$ = replace$ (emlDunnTest.groupName$ [.iGroup], "_", " ", 0)
                if length (.rowName$) > 12
                    .rowName$ = left$ (.rowName$, 12)
                endif
                .rowLine$ = left$ (.rowName$ + "                ", 14)
                for .jGroup from 1 to .nGroups
                    if .iGroup = .jGroup
                        .cellText$ = "---"
                    else
                        ; As in the Tukey matrix above: one spelling of
                        ; a p-value per report. @emlFormatP also covers the
                        ; .999 ceiling and undefined, which the hand-rolled
                        ; floor did not.
                        .pVal = emlDunnTest.pMatrix##[.iGroup, .jGroup]
                        @emlFormatP: .pVal
                        .cellText$ = emlFormatP.bare$
                    endif
                    .rowLine$ = .rowLine$ + left$ (.cellText$ + "            ", 12)
                endfor
                @emlEmit: .rowLine$, ""
            endfor

            @emlReportBlank
            @emlReportSection: "Dunn's z-statistics"
            @emlEmit: "", ""
            @emlEmit: .headerLine$, ""
            for .iGroup from 1 to .nGroups
                .rowName$ = replace$ (emlDunnTest.groupName$ [.iGroup], "_", " ", 0)
                if length (.rowName$) > 12
                    .rowName$ = left$ (.rowName$, 12)
                endif
                .rowLine$ = left$ (.rowName$ + "                ", 14)
                for .jGroup from 1 to .nGroups
                    if .iGroup = .jGroup
                        .cellText$ = "---"
                    else
                        .zVal = emlDunnTest.zMatrix## [.iGroup, .jGroup]
                        @eml_fixed: .zVal, 3
                        .cellText$ = eml_fixed.result$
                    endif
                    .rowLine$ = .rowLine$ + left$ (.cellText$ + "            ", 12)
                endfor
                @emlEmit: .rowLine$, ""
            endfor
            ; The adjusted-p matrix above is symmetric; this one is not.
            ; @emlDunnTest builds each z from mean rank i minus mean rank j
            ; and fills the lower triangle with the negation, so the sign is
            ; the direction of the rank difference. Same convention, same
            ; wording, as the effect-size matrices in this file and in
            ; @emlReportPairwiseComparison.
            @emlReportNote: "Row minus column: a negative z means the ROW "
            ... + "group's mean rank is lower than the COLUMN group's. |z| "
            ... + "is the size of the standardised difference."

            # CSV rows — per-pair descriptives + rank-biserial r
            for .iGroup from 1 to .nGroups - 1
                for .jGroup from .iGroup + 1 to .nGroups
                    .pVal = emlDunnTest.pMatrix##[.iGroup, .jGroup]
                    .zVal = emlDunnTest.zMatrix## [.iGroup, .jGroup]
                    .rVal = emlDunnTest.rMatrix## [.iGroup, .jGroup]
                    .g1Label$ = emlDunnTest.groupName$ [.iGroup]
                    .g2Label$ = emlDunnTest.groupName$ [.jGroup]
                    @eml_getGroupData: .tableId, .dataCol$, .groupCol$,
                    ... .g1Label$
                    .n1 = eml_getGroupData.n
                    .v1# = eml_getGroupData.data#
                    @eml_getGroupData: .tableId, .dataCol$, .groupCol$,
                    ... .g2Label$
                    .n2 = eml_getGroupData.n
                    .v2# = eml_getGroupData.data#
                    @emlMean: .v1#
                    .m1 = emlMean.result
                    @emlSD: .v1#
                    .s1 = emlSD.result
                    @emlMedian: .v1#
                    .md1 = emlMedian.result
                    @emlMean: .v2#
                    .m2 = emlMean.result
                    @emlSD: .v2#
                    .s2 = emlSD.result
                    @emlMedian: .v2#
                    .md2 = emlMedian.result
                    @emlFormatEffectLabel: .rVal, "r"
                    .rLabel$ = emlFormatEffectLabel.label$
                    # Dunn's z has no df; the zero is gone, not
                    # replaced. The adjustment is its own field so a reader
                    # does not have to parse it out of the test name.
                    @emlCSVSetTable: .tableName$
                    @emlCSVTermType: "contrast"
                    .dunn$ = "Dunn's test"
                    .contrast$ = .g1Label$ + " vs " + .g2Label$
                    @emlCSVAddStr: .dunn$, .contrast$, "adjustment",
                    ... .adjLabel$
                    @emlCSVAdd: .dunn$, .contrast$, "z", .zVal
                    @emlCSVAdd: .dunn$, .contrast$, "p_adjusted", .pVal
                    @emlCSVAdd: .dunn$, .contrast$, "rank_biserial_r", .rVal
                    @emlCSVAddStr: .dunn$, .contrast$, "effect_label", .rLabel$
                    @emlCSVAddDescriptives: .dunn$, .g1Label$,
                    ... .n1, .m1, .s1, .md1
                    @emlCSVAddDescriptives: .dunn$, .g2Label$,
                    ... .n2, .m2, .s2, .md2
                endfor
            endfor

            ; THE POST-HOC RAN, AND THE OMNIBUS MAY NOT HAVE. Dunn's is never
            ; gated on the Kruskal-Wallis p under the ruled policy, so this
            ; report can carry a pairwise table under an H that did not reach
            ; the level in force. The caveat is stated rather than enacted by
            ; taking the table away. See @emlPostHocCaution.
            @emlPostHocCaution: emlKruskalWallis.p
        else
            ; ITEM 1.2 — a DISCLOSURE: it states that the post-hoc did not
            ; run, so it is canonical and goes through the emit helper.
            @emlEmit: newline$ + "Dunn's test error: " + emlDunnTest.error$, ""
        endif
    endif

    # Pairwise rank-biserial r (ALWAYS — parallel to ANOVA Cohen's d fix)
    # When called via orchestrator, rMatrix## is pre-computed.
    # When called directly (backward compat), compute it here.
    if .doDunn = 0
        emlKruskalWallis.rMatrix## = zero## (.nGroups, .nGroups)
        for .i from 1 to .nGroups - 1
            @eml_getGroupData: .tableId, .dataCol$, .groupCol$,
            ... emlKruskalWallis.groupName$[.i]
            .tmpV1# = eml_getGroupData.data#
            for .j from .i + 1 to .nGroups
                @eml_getGroupData: .tableId, .dataCol$, .groupCol$,
                ... emlKruskalWallis.groupName$[.j]
                @emlRankBiserialR: .tmpV1#, eml_getGroupData.data#, 2
                if emlRankBiserialR.error$ = ""
                    emlKruskalWallis.rMatrix## [.i, .j] = emlRankBiserialR.r
                    emlKruskalWallis.rMatrix## [.j, .i] = -emlRankBiserialR.r
                else
                    ; Punch list 9.1, sibling of the Cohen's d fix above.
                    emlKruskalWallis.rMatrix## [.i, .j] = undefined
                    emlKruskalWallis.rMatrix## [.j, .i] = undefined
                endif
            endfor
        endfor
    endif
    @emlReportBlank
    @emlReportSection: "Pairwise Effect Sizes (rank-biserial r)"
    ; The twin of the caption under the Cohen's d matrix, and for its reason:
    ; with Dunn's off this grid is the only pairwise thing in the report.
    if .doDunn = 0
        @emlEffectMatrixCaption
    endif
    @emlEmit: "", ""
    .rHeaderLine$ = left$ ("" + "                ", 14)
    for .jGroup from 1 to .nGroups
        .colName$ = replace$ (emlKruskalWallis.groupName$ [.jGroup], "_", " ", 0)
        if length (.colName$) > 10
            .colName$ = left$ (.colName$, 10)
        endif
        .rHeaderLine$ = .rHeaderLine$ + left$ (.colName$ + "            ", 12)
    endfor
    @emlEmit: .rHeaderLine$, ""
    for .iGroup from 1 to .nGroups
        .rowName$ = replace$ (emlKruskalWallis.groupName$ [.iGroup], "_", " ", 0)
        if length (.rowName$) > 12
            .rowName$ = left$ (.rowName$, 12)
        endif
        .rRowLine$ = left$ (.rowName$ + "                ", 14)
        for .jGroup from 1 to .nGroups
            if .iGroup = .jGroup
                .cellText$ = "---"
            else
                .rVal = emlKruskalWallis.rMatrix## [.iGroup, .jGroup]
                if .rVal = undefined
                    ; Punch list 9.1. Same convention as the Cohen's d
                    ; matrix above: a failed pair reads "n/a", never "0.000".
                    .cellText$ = "n/a"
                else
                    @eml_fixed: .rVal, 3
                    .cellText$ = eml_fixed.result$
                endif
            endif
            .rRowLine$ = .rRowLine$ + left$ (.cellText$ + "            ", 12)
        endfor
        @emlEmit: .rRowLine$, ""
    endfor
    ; Antisymmetric, for the same reason the Cohen's d matrix above is:
    ; r[i, j] is -r[j, i], so the sign is the direction and the magnitude is
    ; the effect. Same wording as @emlReportPairwiseComparison's r matrix.
    @emlReportNote: "Row minus column: a negative r means the ROW group "
    ... + "ranks lower than the COLUMN group. |r| is the effect size."

    # CSV rows for rank-biserial r (when Dunn did NOT run)
    if .doDunn = 0
        for .iGroup from 1 to .nGroups - 1
            for .jGroup from .iGroup + 1 to .nGroups
                .g1Label$ = emlKruskalWallis.groupName$ [.iGroup]
                .g2Label$ = emlKruskalWallis.groupName$ [.jGroup]
                .rVal = emlKruskalWallis.rMatrix## [.iGroup, .jGroup]
                @eml_getGroupData: .tableId, .dataCol$, .groupCol$, .g1Label$
                .n1 = eml_getGroupData.n
                .v1# = eml_getGroupData.data#
                @eml_getGroupData: .tableId, .dataCol$, .groupCol$, .g2Label$
                .n2 = eml_getGroupData.n
                .v2# = eml_getGroupData.data#
                @emlMean: .v1#
                .m1 = emlMean.result
                @emlSD: .v1#
                .s1 = emlSD.result
                @emlMedian: .v1#
                .md1 = emlMedian.result
                @emlMean: .v2#
                .m2 = emlMean.result
                @emlSD: .v2#
                .s2 = emlSD.result
                @emlMedian: .v2#
                .md2 = emlMedian.result
                @emlFormatEffectLabel: .rVal, "r"
                .rLabel$ = emlFormatEffectLabel.label$
                @emlCSVSetTable: .tableName$
                @emlCSVTermType: "contrast"
                .rbLab$ = "Pairwise rank-biserial r"
                .contrast$ = .g1Label$ + " vs " + .g2Label$
                @emlCSVAdd: .rbLab$, .contrast$, "rank_biserial_r", .rVal
                @emlCSVAddStr: .rbLab$, .contrast$, "effect_label", .rLabel$
                @emlCSVAddDescriptives: .rbLab$, .g1Label$,
                ... .n1, .m1, .s1, .md1
                @emlCSVAddDescriptives: .rbLab$, .g2Label$,
                ... .n2, .m2, .s2, .md2
            endfor
        endfor
    endif

    @emlReportFooter
endproc


# ============================================================================
# @emlReportCorrelationAnalysis
# ============================================================================
procedure emlReportCorrelationAnalysis: .tableName$, .colX$, .colY$, .n, .testType$
    @emlUnderscoreToSpace: .tableName$
    .displayTable$ = emlUnderscoreToSpace.result$
    @emlUnderscoreToSpace: .colX$
    .displayX$ = emlUnderscoreToSpace.result$
    @emlUnderscoreToSpace: .colY$
    .displayY$ = emlUnderscoreToSpace.result$

    @emlReportHeader: "Correlation Analysis"
    @emlReportLineString: "Table", .displayTable$
    @emlReportLineString: "Column X", .displayX$
    @emlReportLineString: "Column Y", .displayY$
    @emlReportLine: "N", .n, 0

    if .testType$ = "pearson" or .testType$ = "both"
        if emlPearsonCorrelation.error$ = ""
            @emlReportBlank
            @emlReportSection: "Pearson Correlation"
            if emlShowExplanations
                appendInfoLine: "  Why: Measures linear association between "
                ... + "two continuous variables."
            endif
            if emlShowExplanations
                @emlWizardExplainCorrelation: emlPearsonCorrelation.r
            endif
            @emlReportLine: "r", emlPearsonCorrelation.r, 4
            ; R-squared does NOT sit inside the explanations gate. Gated,
            ; the Info window would omit the one number most correlation
            ; write-ups quote, while the scatter figure from the same run
            ; annotated it. R-squared is a statistic, not an explanation —
            ; only the prose gloss is gated.
            .r2 = emlPearsonCorrelation.r * emlPearsonCorrelation.r
            if emlShowExplanations
                @emlWizardExplainR2: .r2
            endif
            @emlReportLine: "R-squared", .r2, 4
            if emlShowExplanations
                @emlWizardExplainT: emlPearsonCorrelation.t
            endif
            @emlReportLine: "t", emlPearsonCorrelation.t, 3
            if emlShowExplanations
                @emlWizardExplainDfCorrelation: emlPearsonCorrelation.df, .n
            endif
            @emlReportLine: "df", emlPearsonCorrelation.df, 0
            if emlShowExplanations
                @emlWizardExplainP: emlPearsonCorrelation.p
            endif
            @emlReportPWithExact: "p", emlPearsonCorrelation.p
            ; ITEM 22 (language batch, Fable's ruling 27 August 2026):
            ; Pearson's p is a literal -- @emlPearsonCorrelation never
            ; branches between an exact and an approximate null, so there
            ; is no .method$ to read and no reason to compose.
            @emlReportLineString: "p method", "t distribution"
            # An interval for r, from numbers already in hand, by the
            # Fisher z transform: z = atanh(r), se = 1/sqrt(n-3), and the
            # interval is tanh(z +/- zCrit se). It is a z interval — the
            # transform is asymptotically normal, so the quantile is normal
            # and not Student's — but the LEVEL is the user's, taken from
            # annotAlpha, so this band states the same confidence as the
            # t-based error bars and mean CIs the same figure carries. The
            # printed label carries the level with it, so a reader never has
            # to know which alpha was in force to read the bracket.
            # Undefined for n <= 3 (se blows up) and for |r| = 1 (atanh is
            # infinite), so both are guarded rather than printed as garbage.
            .rPearson = emlPearsonCorrelation.r
            .fisherOK = 0
            if .n > 3 and .rPearson <> undefined
                if abs (.rPearson) < 1
                    .fisherOK = 1
                endif
            endif
            if .fisherOK = 1
                # The level is the user's, resolved once for the whole module
                # by @emlCIAlphaInForce, so the stars and the interval cannot
                # disagree about the alpha in force.
                @emlCIAlphaInForce
                .ciAlpha = emlCIAlphaInForce.alpha
                .zCrit = invGaussQ (.ciAlpha / 2)
                .fisherZ = 0.5 * ln ((1 + .rPearson) / (1 - .rPearson))
                .fisherSE = 1 / sqrt (.n - 3)
                .zLo = .fisherZ - .zCrit * .fisherSE
                .zHi = .fisherZ + .zCrit * .fisherSE
                .rLo = (exp (2 * .zLo) - 1) / (exp (2 * .zLo) + 1)
                .rHi = (exp (2 * .zHi) - 1) / (exp (2 * .zHi) + 1)
                @eml_fixed: .rLo, 4
                .fx1$ = eml_fixed.result$
                @eml_fixed: .rHi, 4
                .fx2$ = eml_fixed.result$
                @emlCILevelLabel: .ciAlpha
                .ciLabel$ = emlCILevelLabel.percent$ + "% CI for r"
                @emlReportLineString: .ciLabel$,
                ... "[" + .fx1$ + ", " + .fx2$ + "]"
            endif
            # The row carried r and r_squared but left effect_label
            # empty, so a consumer joining these exports got a column that is
            # populated for the group comparisons and blank here.
            @emlFormatEffectLabel: abs (.rPearson), "r"
            .pearsonLabel$ = emlFormatEffectLabel.label$
            @emlReportLineString: "Magnitude", .pearsonLabel$
            # colY$ does not land in the group_col slot, which would say
            # the Y variable was a grouping column. Both variables have
            # their own named field. The six descriptive slots of a wide
            # schema are not written here at all -- both columns'
            # descriptives exist elsewhere, and the term names which pair
            # the row is about.
            @emlCSVSetTable: .tableName$
            @emlCSVTermType: "variable"
            .term$ = .colX$ + " ~ " + .colY$
            @emlCSVAddStr: "Pearson correlation", .term$, "x_column", .colX$
            @emlCSVAddStr: "Pearson correlation", .term$, "y_column", .colY$
            @emlCSVAdd: "Pearson correlation", .term$, "r",
            ... emlPearsonCorrelation.r
            @emlCSVAdd: "Pearson correlation", .term$, "t",
            ... emlPearsonCorrelation.t
            @emlCSVAdd: "Pearson correlation", .term$, "df",
            ... emlPearsonCorrelation.df
            @emlCSVAdd: "Pearson correlation", .term$, "p",
            ... emlPearsonCorrelation.p
            @emlCSVAdd: "Pearson correlation", .term$, "r_squared",
            ... emlPearsonCorrelation.r * emlPearsonCorrelation.r
            @emlCSVAddStr: "Pearson correlation", .term$, "effect_label",
            ... .pearsonLabel$
            @emlCSVAdd: "Pearson correlation", .term$, "n", .n
        else
            appendInfoLine: newline$ + "Pearson error: " + emlPearsonCorrelation.error$
        endif
    endif

    if .testType$ = "spearman" or .testType$ = "both"
        if emlSpearmanCorrelation.error$ = ""
            @emlReportBlank
            @emlReportSection: "Spearman Correlation"
            if emlShowExplanations
                appendInfoLine: "  Why: Measures monotonic association — "
                ... + "no normality assumption needed."
            endif
            if emlShowExplanations
                @emlWizardExplainCorrelation: emlSpearmanCorrelation.rho
            endif
            @emlReportLine: "rho", emlSpearmanCorrelation.rho, 4
            if emlShowExplanations
                @emlWizardExplainT: emlSpearmanCorrelation.t
            endif
            @emlReportLine: "t", emlSpearmanCorrelation.t, 3
            if emlShowExplanations
                @emlWizardExplainDfCorrelation: emlSpearmanCorrelation.df, .n
            endif
            @emlReportLine: "df", emlSpearmanCorrelation.df, 0
            if emlShowExplanations
                @emlWizardExplainP: emlSpearmanCorrelation.p
            endif
            @emlReportPWithExact: "p", emlSpearmanCorrelation.p
            ; ITEM 22 (language batch, Fable's ruling 27 August 2026). The
            ; p just printed is the value @emlSpearmanCorrelationDispatch
            ; computed (written back into emlSpearmanCorrelation.p by every
            ; caller of the dispatch, per its own contract), but .method$
            ; and .methodReason$ are read straight off the dispatch's own
            ; qualified globals -- every call site that reaches this report
            ; calls @emlSpearmanCorrelationDispatch immediately beforehand
            ; and only restores .rho/.t/.df/.p/.error$ into
            ; emlSpearmanCorrelation.*, so the dispatch's .method$ and
            ; .methodReason$ are still the ones this correlation produced.
            .pMethod$ = emlSpearmanCorrelationDispatch.method$
            if emlSpearmanCorrelationDispatch.method$ <> "exact"
                .pMethod$ = .pMethod$ + " (" + emlSpearmanCorrelationDispatch.methodReason$ + ")"
            endif
            @emlReportLineString: "p method", .pMethod$
            # Rho is an effect size and had no magnitude gloss in the
            # report and no effect_label in the export.
            @emlFormatEffectLabel: abs (emlSpearmanCorrelation.rho), "r"
            .spearmanLabel$ = emlFormatEffectLabel.label$
            @emlReportLineString: "Magnitude", .spearmanLabel$
            @emlCSVSetTable: .tableName$
            @emlCSVTermType: "variable"
            .term$ = .colX$ + " ~ " + .colY$
            @emlCSVAddStr: "Spearman correlation", .term$, "x_column", .colX$
            @emlCSVAddStr: "Spearman correlation", .term$, "y_column", .colY$
            @emlCSVAdd: "Spearman correlation", .term$, "rho",
            ... emlSpearmanCorrelation.rho
            @emlCSVAdd: "Spearman correlation", .term$, "t",
            ... emlSpearmanCorrelation.t
            @emlCSVAdd: "Spearman correlation", .term$, "df",
            ... emlSpearmanCorrelation.df
            @emlCSVAdd: "Spearman correlation", .term$, "p",
            ... emlSpearmanCorrelation.p
            @emlCSVAddStr: "Spearman correlation", .term$, "effect_label",
            ... .spearmanLabel$
            @emlCSVAdd: "Spearman correlation", .term$, "n", .n
        endif
    endif

    @emlReportFooter
endproc


# ============================================================================
# @emlReportRegressionAnalysis
# ============================================================================
# Formatted Info window report for simple linear regression.
# Reads globals from @emlLinearRegression.
# ============================================================================

procedure emlReportRegressionAnalysis: .tableName$, .depCol$, .predCol$,
... .nValid, .nUndefined
    @emlUnderscoreToSpace: .tableName$
    .displayTable$ = emlUnderscoreToSpace.result$
    @emlUnderscoreToSpace: .depCol$
    .displayDep$ = emlUnderscoreToSpace.result$
    @emlUnderscoreToSpace: .predCol$
    .displayPred$ = emlUnderscoreToSpace.result$

    @emlReportHeader: "Simple Linear Regression"
    @emlReportLineString: "Table", .displayTable$
    @emlReportLineString: "Response (Y)", .displayDep$
    @emlReportLineString: "Predictor (X)", .displayPred$
    @emlReportLine: "N", .nValid, 0
    if .nUndefined > 0
        @emlReportLine: "Excluded (missing)", .nUndefined, 0
    endif

    @emlReportBlank
    @emlReportSection: "Model"
    if emlShowExplanations
        appendInfoLine: "  Why: Tests whether the predictor linearly"
        ... + " predicts the response."
    endif
    @eml_fixed: emlLinearRegression.slope, 4
    .fx1$ = eml_fixed.result$
    @eml_fixed: emlLinearRegression.intercept, 4
    .fx2$ = eml_fixed.result$
    .eqn$ = "y = "
    ... + .fx1$ + "x"
    ... + " + " + .fx2$
    @emlReportLineString: "Equation", .eqn$
    if emlShowExplanations
        @eml_fixed: emlLinearRegression.slope, 4
        .fx1$ = eml_fixed.result$
        @eml_fixed: emlLinearRegression.intercept, 4
        .fx2$ = eml_fixed.result$
        .proseEqn$ = .displayDep$ + " = "
        ... + .fx1$ + " x " + .displayPred$
        ... + " + " + .fx2$
        emlWizardExplain$ = .proseEqn$
        appendInfoLine: "  " + emlWizardExplain$

        ; THE SLOPE IN WORDS, stated as a comparison BETWEEN cases rather
        ; than as a change WITHIN one. Per unit of the predictor, the fitted
        ; line puts predicted response this much higher or lower; it does not
        ; forecast what moving a case along X would do to it.
        @eml_fixed: abs (emlLinearRegression.slope), 4
        .slopeAbs$ = eml_fixed.result$
        if emlLinearRegression.slope >= 0
            .slopeDir$ = "higher"
        else
            .slopeDir$ = "lower"
        endif
        appendInfoLine: "  For each 1-unit increase in " + .displayPred$
        ... + ", predicted " + .displayDep$ + " is "
        ... + .slopeAbs$ + " units " + .slopeDir$ + "."
    endif
    if emlShowExplanations
        @emlWizardExplainCorrelation: emlLinearRegression.r
    endif
    @emlReportLine: "R", emlLinearRegression.r, 4
    if emlShowExplanations
        @emlWizardExplainR2: emlLinearRegression.rSquared
    endif
    @emlReportLine: "R-squared", emlLinearRegression.rSquared, 4
    .adjR2 = 1 - (1 - emlLinearRegression.rSquared) * (.nValid - 1) / (.nValid - 2)
    if emlShowExplanations
        emlWizardExplain$ = "R-squared adjusted for number of predictors — penalizes model complexity"
    endif
    @emlReportLine: "Adj. R-squared", .adjR2, 4
    if emlShowExplanations
        @eml_fixed: emlLinearRegression.seResidual, 2
        .fx1$ = eml_fixed.result$
        emlWizardExplain$ = "Typical prediction error — points deviate from the line by +/-"
        ... + .fx1$ + " units on average"
    endif
    @emlReportLine: "Residual SE", emlLinearRegression.seResidual, 4

    @emlReportBlank
    @emlReportSection: "Overall Model Test (F)"
    .dfLabel$ = "F(" + string$ (emlLinearRegression.dfReg)
    ... + "," + string$ (emlLinearRegression.dfRes) + ")"
    if emlShowExplanations
        emlWizardExplain$ = "Ratio of the mean square accounted for by the "
        ... + "model to the mean square left over. With no real association, "
        ... + "this ratio tends to be near 1"
    endif
    @emlReportLine: .dfLabel$, emlLinearRegression.fStat, 4
    if emlShowExplanations
        @emlWizardExplainP: emlLinearRegression.pF
    endif
    @emlReportPWithExact: "p", emlLinearRegression.pF

    @emlReportBlank
    @emlReportSection: "Coefficients"
    appendInfoLine: ""
    # The block was flush-left inside a report whose every other block is
    # indented two spaces, the term column had no header at all, and the cells
    # under the numeric-aligned "p" header held the string "p < .001". The
    # block is now indented, the term column is headed, and the cells carry
    # @emlFormatP's bare form so the column contains values, not labels.
    # SE is printed with the interval it defines: dfRes and the two standard
    # errors are already on screen, so the interval is one t quantile away and
    # is printed beside each coefficient.
    #
    # THE LEVEL IS THE USER'S, taken from the alpha in force, and the column
    # heading names it. A coefficient table headed "95% CI" under an alpha of
    # .01 would contradict the p column beside it, which marks significance
    # against that same alpha.
    @emlCIAlphaInForce
    .ciAlpha = emlCIAlphaInForce.alpha
    .ciWidth = 0
    if emlLinearRegression.dfRes <> undefined
        if emlLinearRegression.dfRes >= 1
            .ciWidth = invStudentQ (.ciAlpha / 2, emlLinearRegression.dfRes)
        endif
    endif
    @emlCILevelLabel: .ciAlpha
    .ciColHead$ = emlCILevelLabel.percent$ + "% CI"
    .hdr$ = "  " + left$ ("Term" + "                    ", 20)
    ... + left$ ("Estimate" + "              ", 14)
    ... + left$ ("SE" + "              ", 14)
    ... + left$ ("t" + "              ", 12)
    ... + left$ ("p" + "            ", 12)
    ... + .ciColHead$
    appendInfoLine: .hdr$
    # Intercept row
    @emlFormatP: emlLinearRegression.pIntercept
    if .ciWidth > 0
        .intHalf = .ciWidth * emlLinearRegression.seIntercept
        @eml_fixed: emlLinearRegression.intercept - .intHalf, 4
        .fx1$ = eml_fixed.result$
        @eml_fixed: emlLinearRegression.intercept + .intHalf, 4
        .fx2$ = eml_fixed.result$
        .intCI$ = "[" + .fx1$
        ... + ", " + .fx2$ + "]"
    else
        .intCI$ = "not available"
    endif
    @eml_fixed: emlLinearRegression.intercept, 4
    .fx1$ = eml_fixed.result$
    @eml_fixed: emlLinearRegression.seIntercept, 4
    .fx2$ = eml_fixed.result$
    @eml_fixed: emlLinearRegression.tIntercept, 3
    .fx3$ = eml_fixed.result$
    .intRow$ = "  " + left$ ("(Intercept)" + "                    ", 20)
    ... + left$ (.fx1$ + "              ", 14)
    ... + left$ (.fx2$ + "              ", 14)
    ... + left$ (.fx3$ + "              ", 12)
    ... + left$ (emlFormatP.bare$ + "            ", 12)
    ... + .intCI$
    appendInfoLine: .intRow$
    # Slope row
    @emlFormatP: emlLinearRegression.pSlope
    if .ciWidth > 0
        .slopeHalf = .ciWidth * emlLinearRegression.seSlope
        @eml_fixed: emlLinearRegression.slope - .slopeHalf, 4
        .fx1$ = eml_fixed.result$
        @eml_fixed: emlLinearRegression.slope + .slopeHalf, 4
        .fx2$ = eml_fixed.result$
        .slopeCI$ = "[" + .fx1$
        ... + ", " + .fx2$ + "]"
    else
        .slopeCI$ = "not available"
    endif
    @eml_fixed: emlLinearRegression.slope, 4
    .fx1$ = eml_fixed.result$
    @eml_fixed: emlLinearRegression.seSlope, 4
    .fx2$ = eml_fixed.result$
    @eml_fixed: emlLinearRegression.tSlope, 3
    .fx3$ = eml_fixed.result$
    .slopeRow$ = "  " + left$ (.displayPred$ + "                    ", 20)
    ... + left$ (.fx1$ + "              ", 14)
    ... + left$ (.fx2$ + "              ", 14)
    ... + left$ (.fx3$ + "              ", 12)
    ... + left$ (emlFormatP.bare$ + "            ", 12)
    ... + .slopeCI$
    appendInfoLine: .slopeRow$

    # Direction and magnitude
    @emlReportBlank
    ; ASSOCIATION, NOT CHANGE. A slope fitted to observational data says how
    ; predicted Y DIFFERS between cases whose X differs; it does not say what
    ; happens to a case when its X is changed. "Y increases as X increases"
    ; describes a process nobody watched. "Higher X goes with higher Y"
    ; describes what was measured, and stays true whichever way the causal
    ; arrow points -- or if it points from somewhere else entirely.
    if emlLinearRegression.slope > 0
        .dir$ = "positive"
        .verb$ = "higher"
    else
        .dir$ = "negative"
        .verb$ = "lower"
    endif
    @emlFormatEffectLabel: emlLinearRegression.rSquared, "r_squared"
    appendInfoLine: "  Direction: " + .dir$
    ... + " (cases with higher " + .displayPred$
    ... + " tend to have " + .verb$ + " " + .displayDep$ + ")"
    # This printed as "Variance explained   large effect" in the same
    # label/value layout as "R-squared   0.8770", so a Cohen benchmark verdict
    # wore the visual authority of a second computed statistic — and read as a
    # different quantity from R-squared when it is R-squared, glossed. Stated
    # as prose naming the number it is a verdict about.
    @eml_fixed: emlLinearRegression.rSquared, 4
    .fx1$ = eml_fixed.result$
    @eml_fixed: 100 * emlLinearRegression.rSquared, 1
    .fx2$ = eml_fixed.result$
    appendInfoLine: "  Model fit: R-squared = "
    ... + .fx1$
    ... + " -- the fitted model accounts for "
    ... + .fx2$
    ... + "% of the variance in " + .displayDep$
    ... + " in this sample, a " + emlFormatEffectLabel.label$
    ... + " by Cohen's R-squared benchmarks"

    # THE CLEAREST CASE OF SLOT REUSE a wide schema invites: the
    # slope went into mean1, the slope's SE into sd1, the intercept into
    # median1, its SE into mean2 and R into sd2. A reader taking a column
    # mean over mean1 averages slopes with group means, and the
    # literal "regression" was written into both group-level slots.
    # Coefficients now have their own rows, one term each.
    @emlCSVSetTable: .tableName$
    @emlCSVTermType: "omnibus"
    .regLab$ = "OLS linear regression"
    @emlCSVAddStr: .regLab$, "", "response_column", .depCol$
    @emlCSVAddStr: .regLab$, "", "predictor_column", .predCol$
    @emlCSVAdd: .regLab$, "", "F", emlLinearRegression.fStat
    @emlCSVAdd: .regLab$, "", "df1", emlLinearRegression.dfReg
    @emlCSVAdd: .regLab$, "", "df2", emlLinearRegression.dfRes
    @emlCSVAdd: .regLab$, "", "p", emlLinearRegression.pF
    @emlCSVAdd: .regLab$, "", "r", emlLinearRegression.r
    @emlCSVAdd: .regLab$, "", "r_squared", emlLinearRegression.rSquared
    @emlCSVAdd: .regLab$, "", "adj_r_squared", .adjR2
    @emlCSVAdd: .regLab$, "", "residual_se", emlLinearRegression.seResidual
    @emlCSVAddStr: .regLab$, "", "effect_label", emlFormatEffectLabel.label$
    @emlCSVAdd: .regLab$, "", "n", .nValid

    @emlCSVTermType: "coefficient"
    @emlCSVAdd: .regLab$, "(Intercept)", "estimate",
    ... emlLinearRegression.intercept
    @emlCSVAdd: .regLab$, "(Intercept)", "se",
    ... emlLinearRegression.seIntercept
    @emlCSVAdd: .regLab$, "(Intercept)", "t", emlLinearRegression.tIntercept
    @emlCSVAdd: .regLab$, "(Intercept)", "p", emlLinearRegression.pIntercept
    # The interval the report now prints is exported alongside it.
    if .ciWidth > 0
        @emlCSVAdd: .regLab$, "(Intercept)", "ci_lower",
        ... emlLinearRegression.intercept - .intHalf
        @emlCSVAdd: .regLab$, "(Intercept)", "ci_upper",
        ... emlLinearRegression.intercept + .intHalf
    endif

    @emlCSVAdd: .regLab$, .predCol$, "estimate", emlLinearRegression.slope
    @emlCSVAdd: .regLab$, .predCol$, "se", emlLinearRegression.seSlope
    @emlCSVAdd: .regLab$, .predCol$, "t", emlLinearRegression.tSlope
    @emlCSVAdd: .regLab$, .predCol$, "p", emlLinearRegression.pSlope
    if .ciWidth > 0
        @emlCSVAdd: .regLab$, .predCol$, "ci_lower",
        ... emlLinearRegression.slope - .slopeHalf
        @emlCSVAdd: .regLab$, .predCol$, "ci_upper",
        ... emlLinearRegression.slope + .slopeHalf
    endif

    @emlReportFooter
endproc


# ============================================================================
# @emlReportNormalityAnalysis
# ============================================================================
# Formatted Info window report for normality assessment.
# Reads globals from @emlRunNormalityAnalysis.
# ============================================================================

procedure emlReportNormalityAnalysis: .tableName$, .dataCol$,
... .nValid, .nUndefined
    @emlUnderscoreToSpace: .tableName$
    .displayTable$ = emlUnderscoreToSpace.result$
    @emlUnderscoreToSpace: .dataCol$
    .displayCol$ = emlUnderscoreToSpace.result$

    @emlReportHeader: "Normality Assessment"
    @emlReportLineString: "Table", .displayTable$
    @emlReportLineString: "Column", .displayCol$
    @emlReportLine: "N", .nValid, 0
    if .nUndefined > 0
        @emlReportLine: "Excluded (missing)", .nUndefined, 0
    endif

    @emlReportBlank
    @emlReportSection: "Descriptive Statistics"
    @emlReportLine: "Mean", emlRunNormalityAnalysis.mean, 4
    @emlReportLine: "SD", emlRunNormalityAnalysis.sd, 4
    @emlReportLine: "Median", emlRunNormalityAnalysis.median, 4

    @emlReportBlank
    @emlReportSection: "Distribution Shape"
    if emlShowExplanations
        appendInfoLine: "  Why: Skewness and kurtosis indicate departures"
        ... + " from a normal (bell-shaped) distribution."
    endif
    if emlShowExplanations
        @emlWizardExplainSkewness: emlRunNormalityAnalysis.skewness
    endif
    @emlReportLine: "Skewness", emlRunNormalityAnalysis.skewness, 4
    if emlShowExplanations
        @emlWizardExplainKurtosis: emlRunNormalityAnalysis.kurtosis
    endif
    # (excess): @emlKurtosis returns Fisher's g2, so a normal distribution
    # reads 0, not 3. Bare "Kurtosis" invites the Pearson reading, under
    # which -0.69 would be violently platykurtic rather than unremarkable.
    # The other three print sites carry the same label.
    @emlReportLine: "Kurtosis (excess)", emlRunNormalityAnalysis.kurtosis, 4

    # These two verdicts must use the SAME thresholds as the recommendation
    # gate in @emlRunNormalityAnalysis (stats/eml-analysis.praat), which reads
    # emlSkewThreshold and emlKurtosisThreshold — set in stats/eml-output.praat
    # to 2 and 7. A STRICTER LOCAL THRESHOLD IS NOT A SAFER ONE. Hard-code 1
    # and 3 here, against a gate at 2 and 7, and the two contradict rather
    # than the tighter one winning: a g2 of 4 prints "Kurtosis outside
    # typical limits" here while the gate, for which 4 is well inside 7, goes
    # on to recommend a parametric test — two opposite verdicts in one
    # report. A skewness of 1.5 against a local 1 does the same.
    # The parenthetical is worded as a stated criterion ("criterion: ...")
    # and printed on BOTH branches, so a passing reader learns what threshold
    # was cleared. Printed on the FAILING branch only it would assert the
    # criterion at the moment it announces the opposite, and be invisible to
    # the reader who passes.
    # The same two thresholds are announced in scripts/eml-wizard.praat, in
    # the .skKurtFail branch of its normality summary — currently :2170-2175.
    # Not fixed here because that file is owned elsewhere. (The pointer used
    # to read :2085, which is a "Data column:" padding line in the analysis
    # plan; grep for skKurtFail, the line numbers move on every insertion.)
    if abs (emlRunNormalityAnalysis.skewness) >= emlSkewThreshold
        @eml_fixed: emlSkewThreshold, 0
        .fx1$ = eml_fixed.result$
        appendInfoLine: "  → Skewness outside typical limits (criterion: |skew| < ",
        ... .fx1$, ")"
    else
        @eml_fixed: emlSkewThreshold, 0
        .fx1$ = eml_fixed.result$
        appendInfoLine: "  → Skewness within typical limits (criterion: |skew| < ",
        ... .fx1$, ")"
    endif
    if abs (emlRunNormalityAnalysis.kurtosis) >= emlKurtosisThreshold
        @eml_fixed: emlKurtosisThreshold, 0
        .fx1$ = eml_fixed.result$
        appendInfoLine: "  → Kurtosis outside typical limits (criterion: |excess kurt| < ",
        ... .fx1$, ")"
    else
        @eml_fixed: emlKurtosisThreshold, 0
        .fx1$ = eml_fixed.result$
        appendInfoLine: "  → Kurtosis within typical limits (criterion: |excess kurt| < ",
        ... .fx1$, ")"
    endif

    @emlReportBlank
    @emlReportSection: "Shapiro-Wilk Test"
    if emlShowExplanations
        appendInfoLine: "  Why: Formal test of whether the data are"
        ... + " drawn from a normal distribution."
    endif
    if emlRunNormalityAnalysis.swError$ = ""
        if emlShowExplanations
            @emlWizardExplainNormW: emlRunNormalityAnalysis.swW
        endif
        @emlReportLine: "W", emlRunNormalityAnalysis.swW, 4
        if emlShowExplanations
            @emlWizardExplainP: emlRunNormalityAnalysis.swP
        endif
        ; Shapiro-Wilk has no effect size, so no magnitude row
        ; Belongs here and none is added.
        @emlReportPWithExact: "p", emlRunNormalityAnalysis.swP
        if emlRunNormalityAnalysis.swFail
            appendInfoLine: "  → Rejects normality (p < 0.05)"
        else
            appendInfoLine: "  → Does not reject normality (p >= 0.05)"
        endif
    else
        @emlReportLineString: "Error", emlRunNormalityAnalysis.swError$
    endif

    # ── Recommendation ─────────────────────────────────────────────────────
    #
    # THIS SECTION RECOMMENDS; IT DOES NOT CERTIFY. A recommendation can be
    # declined, and the wording keeps that door open at every branch: a test
    # is "recommended", never "appropriate", because appropriateness is a
    # property of the research question and this procedure has only seen a
    # column of numbers.
    #
    # Three things are printed with the recommendation, and each is there to
    # let a reader disagree with it on the evidence:
    #
    #   * the reading it rests on, named -- not just the verdict it produced;
    #   * BOTH options when the call is close, because a rule with a
    #     threshold in it produces its least reliable answers next to the
    #     threshold, and a reader at p = .049 and a reader at p = .051 should
    #     not be handed opposite conclusions with equal confidence;
    #   * what was actually examined, which is the marginal distribution of
    #     one column. Parametric tests assume normality of the model
    #     RESIDUALS, and that is a different distribution from this one.
    #
    # Praat does not short-circuit `and`, so the close-call test is nested.
    .closeCall = 0
    if emlRunNormalityAnalysis.swError$ = ""
        if emlRunNormalityAnalysis.swP >= 0.01
            if emlRunNormalityAnalysis.swP < 0.10
                .closeCall = 1
            endif
        endif
    endif

    @emlReportBlank
    @emlReportSection: "Recommendation"
    if emlRunNormalityAnalysis.recommendation$ = "parametric"
        if emlRunNormalityAnalysis.largeNOverride = 1
            appendInfoLine: "  Shapiro-Wilk rejects normality (p < .05), but"
            ... + " skewness and kurtosis are"
            appendInfoLine: "  within the thresholds and n = "
            ... + string$ (emlRunNormalityAnalysis.nValid)
            ... + ". At this sample size the test"
            appendInfoLine: "  detects departures too small to unsettle a"
            ... + " parametric procedure."
            appendInfoLine: "  → Parametric tests (t-test, ANOVA, Pearson r)"
            ... + " are recommended."
            appendInfoLine: "  → Nonparametric tests (Mann-Whitney,"
            ... + " Kruskal-Wallis, Spearman rho) remain"
            appendInfoLine: "     a defensible choice, since the test did"
            ... + " reject."
        else
            appendInfoLine: "  Shapiro-Wilk does not reject normality"
            ... + " (p >= .05), and skewness and"
            appendInfoLine: "  kurtosis are within the thresholds."
            appendInfoLine: "  → Parametric tests (t-test, ANOVA, Pearson r)"
            ... + " are recommended."
            if .closeCall
                appendInfoLine: "  → The p is close to the .05 threshold."
                ... + " Nonparametric tests"
                appendInfoLine: "     (Mann-Whitney, Kruskal-Wallis, Spearman"
                ... + " rho) are also defensible."
            endif
        endif
    else
        appendInfoLine: "  The evidence is against normality on the reading"
        ... + " printed above."
        appendInfoLine: "  → Nonparametric tests (Mann-Whitney,"
        ... + " Kruskal-Wallis, Spearman rho) are"
        appendInfoLine: "     recommended."
        if .closeCall
            appendInfoLine: "  → The p is close to the .05 threshold."
            ... + " Parametric tests are also"
            appendInfoLine: "     defensible, particularly at larger n."
        endif
    endif
    appendInfoLine: "  What was checked: the marginal distribution of this"
    ... + " column. Parametric"
    appendInfoLine: "  tests assume normality of the model RESIDUALS, which"
    ... + " is not the same"
    appendInfoLine: "  distribution and is not examined here."

    # Skewness and kurtosis were being carried in the mean2/sd2 slots
    # while n2 and median2 were zero-as-NA. Each is now its own field.
    @emlCSVSetTable: .tableName$
    @emlCSVTermType: "variable"
    @emlCSVAddStr: "Shapiro-Wilk", .dataCol$, "data_column", .dataCol$
    @emlCSVAdd: "Shapiro-Wilk", .dataCol$, "W", emlRunNormalityAnalysis.swW
    @emlCSVAdd: "Shapiro-Wilk", .dataCol$, "p", emlRunNormalityAnalysis.swP
    @emlCSVAddStr: "Shapiro-Wilk", .dataCol$, "recommendation",
    ... emlRunNormalityAnalysis.recommendation$
    @emlCSVAdd: "Shapiro-Wilk", .dataCol$, "n", .nValid
    @emlCSVAdd: "Shapiro-Wilk", .dataCol$, "mean", emlRunNormalityAnalysis.mean
    @emlCSVAdd: "Shapiro-Wilk", .dataCol$, "sd", emlRunNormalityAnalysis.sd
    @emlCSVAdd: "Shapiro-Wilk", .dataCol$, "median",
    ... emlRunNormalityAnalysis.median
    @emlCSVAdd: "Shapiro-Wilk", .dataCol$, "skewness",
    ... emlRunNormalityAnalysis.skewness
    @emlCSVAdd: "Shapiro-Wilk", .dataCol$, "excess_kurtosis",
    ... emlRunNormalityAnalysis.kurtosis

    @emlReportFooter
endproc


# ============================================================================
# @emlReportPairedComparison
# ============================================================================
procedure emlReportPairedComparison: .tableName$, .col1$, .col2$, .n,
... .mean1, .sd1, .median1, .mean2, .sd2, .median2, .testType$
    @emlUnderscoreToSpace: .tableName$
    .displayTable$ = emlUnderscoreToSpace.result$
    @emlUnderscoreToSpace: .col1$
    .displayC1$ = emlUnderscoreToSpace.result$
    @emlUnderscoreToSpace: .col2$
    .displayC2$ = emlUnderscoreToSpace.result$

    @emlReportHeader: "Paired Comparison"
    @emlReportLineString: "Table", .displayTable$
    @emlReportLineString: "Column 1", .displayC1$
    @emlReportLineString: "Column 2", .displayC2$
    @emlReportLine: "N (pairs)", .n, 0
    @emlReportBlank

    @eml_fixed: .mean1, 3
    .fx1$ = eml_fixed.result$
    @eml_fixed: .sd1, 3
    .fx2$ = eml_fixed.result$
    @eml_fixed: .median1, 3
    .fx3$ = eml_fixed.result$
    appendInfoLine: "  ", .displayC1$, ": Mean = ", .fx1$,
    ... ", SD = ", .fx2$,
    ... ", Median = ", .fx3$
    @eml_fixed: .mean2, 3
    .fx1$ = eml_fixed.result$
    @eml_fixed: .sd2, 3
    .fx2$ = eml_fixed.result$
    @eml_fixed: .median2, 3
    .fx3$ = eml_fixed.result$
    appendInfoLine: "  ", .displayC2$, ": Mean = ", .fx1$,
    ... ", SD = ", .fx2$,
    ... ", Median = ", .fx3$

    ; THE DIRECTION IS STATED ONCE, ON THE PAGE, FOR BOTH ARMS. Every signed
    ; quantity a paired test reports -- t, Cohen's dz, r from t, the Wilcoxon
    ; z and the matched-pairs r -- is built from the same per-pair difference,
    ; and @emlTTestPaired and @emlWilcoxonSignedRank both take that as their
    ; first vector minus their second, which is column 1 minus column 2 here.
    ; A reader who has only the numbers cannot tell which way that runs, so
    ; the report says it rather than leaving it to be inferred.
    @emlReportNote: "Sign: every difference below is " + .displayC1$
    ... + " minus " + .displayC2$ + ", and t, z and the effect sizes carry "
    ... + "that direction."

    if .testType$ = "parametric" or .testType$ = "both"
        if emlTTestPaired.error$ = ""
            @emlReportBlank
            @emlReportSection: "Paired t-test"
            if emlShowExplanations
                appendInfoLine: "  Why: Tests whether the mean difference "
                ... + "between paired observations differs from zero."
            endif
            if emlShowExplanations
                @emlWizardExplainT: emlTTestPaired.t
            endif
            @emlReportLine: "t", emlTTestPaired.t, 3
            if emlShowExplanations
                @emlWizardExplainDfPaired: emlTTestPaired.df, .n
            endif
            @emlReportLine: "df", emlTTestPaired.df, 0
            if emlShowExplanations
                @emlWizardExplainP: emlTTestPaired.p
            endif
            @emlReportPWithExact: "p", emlTTestPaired.p
            ; A PAIRED SIGN FOLLOWS THE TWO COLUMNS, NOT THE GROUP SORT.
            ; @emlTTestPaired forms every pair's difference as its first
            ; vector minus its second, and @emlRunPairedAnalysis hands it
            ; column 1 first, so the printed difference is column 1 minus
            ; column 2. A bare "Mean difference" would leave that to be
            ; inferred from the two descriptive lines above, so the label
            ; names it, in the same display names those lines print.
            .diffLabel$ = "Mean diff (" + .displayC1$ + " − "
            ... + .displayC2$ + ")"
            if length (.diffLabel$) >= 20
                ; @emlPadRight leaves an over-long label unpadded, which
                ; would run the value straight into the ")". One space keeps
                ; them apart.
                .diffLabel$ = .diffLabel$ + " "
            endif
            @emlReportLine: .diffLabel$, emlTTestPaired.meanDiff, 4
            @emlReportLine: "SD of differences", emlTTestPaired.sdDiff, 4

            # The effect size under the t-test is the one derived from the
            # same quantity the t is derived from. The matched-pairs rank
            # statistic belongs to the Wilcoxon and is reported in that
            # Section, not here.
            # The magnitude was printed here but never reached the
            # export, so effect_label was blank on every paired row.
            .dzLabel$ = ""
            if emlCohenDz.error$ = ""
                @emlFormatEffectLabel: abs (emlCohenDz.dz), "d"
                .dzLabel$ = emlFormatEffectLabel.label$
                @emlReportBlank
                @emlReportSection: "Effect Size"
                @emlReportLine: "Cohen's dz", emlCohenDz.dz, 3
                @emlReportLine: "r (from t)", emlCohenDz.rFromT, 3
                @emlReportLineString: "Magnitude", .dzLabel$
            endif

            # The two column names are not packed into four level slots
            # with n written twice, which would make a paired design
            # indistinguishable from a two-group one in the file. A paired
            # design has ONE n, and it is written once.
            @emlCSVSetTable: .tableName$
            @emlCSVTermType: "contrast"
            .term$ = .col1$ + " vs " + .col2$
            @emlCSVAddStr: "Paired t-test", .term$, "design", "paired"
            @emlCSVAddStr: "Paired t-test", .term$, "column_1", .col1$
            @emlCSVAddStr: "Paired t-test", .term$, "column_2", .col2$
            @emlCSVAdd: "Paired t-test", .term$, "t", emlTTestPaired.t
            @emlCSVAdd: "Paired t-test", .term$, "df", emlTTestPaired.df
            @emlCSVAdd: "Paired t-test", .term$, "p", emlTTestPaired.p
            @emlCSVAdd: "Paired t-test", .term$, "cohens_dz", emlCohenDz.dz
            @emlCSVAddStr: "Paired t-test", .term$, "effect_label", .dzLabel$
            @emlCSVAdd: "Paired t-test", .term$, "n_pairs", .n
            @emlCSVAddDescriptives: "Paired t-test", .col1$,
            ... undefined, .mean1, .sd1, .median1
            @emlCSVAddDescriptives: "Paired t-test", .col2$,
            ... undefined, .mean2, .sd2, .median2
        else
            appendInfoLine: newline$ + "Paired t-test error: "
            ... + emlTTestPaired.error$
        endif
    endif

    if .testType$ = "nonparametric" or .testType$ = "both"
        if emlWilcoxonSignedRank.error$ = ""
            @emlReportBlank
            @emlReportSection: "Wilcoxon Signed-Rank Test"
            if emlShowExplanations
                appendInfoLine: "  Why: Nonparametric test for paired "
                ... + "observations — no normality assumption needed."
            endif
            ; THIS IS NOT THE MANN-WHITNEY GLOSS ABOVE, and the difference
            ; is not cosmetic:
            ; @emlWilcoxonSignedRank (stats/eml-inferential.praat) ranks the
            ; ABSOLUTE differences and then adds up the ranks belonging to
            ; the positive ones for T+ and the negative ones for T-. The
            ; signed-rank statistic IS a rank sum -- no n(n+1)/2 is
            ; subtracted, as it is for U -- so "Sum of ranks for positive
            ; differences" is the correct name for this number. Rewriting it
            ; to match the Mann-Whitney correction would introduce a
            ; second defect while fixing the first.
            if emlShowExplanations
                emlWizardExplain$ = "Sum of ranks for positive differences (subjects who increased)"
            endif
            @emlReportLine: "T+", emlWilcoxonSignedRank.tPlus, 1
            if emlShowExplanations
                emlWizardExplain$ = "Sum of ranks for negative differences (subjects who decreased)"
            endif
            @emlReportLine: "T-", emlWilcoxonSignedRank.tMinus, 1
            if emlWilcoxonSignedRank.z <> undefined
                @emlReportLine: "z", emlWilcoxonSignedRank.z, 3
            endif
            if emlShowExplanations
                @emlWizardExplainP: emlWilcoxonSignedRank.p
            endif
            @emlReportPWithExact: "p", emlWilcoxonSignedRank.p
            ; ITEM 22 (language batch, Fable's ruling 27 August 2026): see
            ; the identical row on the Mann-Whitney arm above for the
            ; disclosure rule -- always prints, "exact" bare, otherwise
            ; every reason that ruled out the exact branch, comma-
            ; separated, no precedence.
            .pMethod$ = emlWilcoxonSignedRank.method$
            if emlWilcoxonSignedRank.method$ <> "exact"
                .pMethod$ = .pMethod$ + " (" + emlWilcoxonSignedRank.methodReason$ + ")"
            endif
            @emlReportLineString: "p method", .pMethod$

            # The matched-pairs magnitude was printed and then dropped on
            # the way to the export.
            .mprLabel$ = ""
            if emlMatchedPairsR.error$ = ""
                @emlFormatEffectLabel: abs (emlMatchedPairsR.r), "r"
                .mprLabel$ = emlFormatEffectLabel.label$
                @emlReportBlank
                @emlReportSection: "Nonparametric Effect Size"
                if emlShowExplanations
                    @emlWizardExplainEffectR: emlMatchedPairsR.r
                endif
                @emlReportLine: "Matched-pairs r", emlMatchedPairsR.r, 3
                @emlReportLineString: "Magnitude", .mprLabel$
            endif

            if emlWilcoxonSignedRank.z <> undefined
                .wsrDf = emlWilcoxonSignedRank.z
            else
                .wsrDf = 0
            endif
            @emlCSVSetTable: .tableName$
            @emlCSVTermType: "contrast"
            .wLab$ = "Wilcoxon signed-rank"
            .term$ = .col1$ + " vs " + .col2$
            @emlCSVAddStr: .wLab$, .term$, "design", "paired"
            @emlCSVAddStr: .wLab$, .term$, "column_1", .col1$
            @emlCSVAddStr: .wLab$, .term$, "column_2", .col2$
            @emlCSVAdd: .wLab$, .term$, "T_plus",
            ... emlWilcoxonSignedRank.tPlus
            @emlCSVAdd: .wLab$, .term$, "p", emlWilcoxonSignedRank.p
            @emlCSVAdd: .wLab$, .term$, "matched_pairs_r", emlMatchedPairsR.r
            @emlCSVAddStr: .wLab$, .term$, "effect_label", .mprLabel$
            @emlCSVAdd: .wLab$, .term$, "n_pairs", .n
            @emlCSVAddDescriptives: .wLab$, .col1$,
            ... undefined, .mean1, .sd1, .median1
            @emlCSVAddDescriptives: .wLab$, .col2$,
            ... undefined, .mean2, .sd2, .median2
        else
            appendInfoLine: newline$ + "Wilcoxon error: "
            ... + emlWilcoxonSignedRank.error$
        endif
    endif

    @emlReportFooter
endproc


# ============================================================================
# @emlReportTwoWayAnova
# ============================================================================
procedure emlReportTwoWayAnova: .tableName$, .dataCol$, .factor1$, .factor2$
    @emlUnderscoreToSpace: .tableName$
    .displayTable$ = emlUnderscoreToSpace.result$
    @emlUnderscoreToSpace: .dataCol$
    .displayData$ = emlUnderscoreToSpace.result$
    @emlUnderscoreToSpace: .factor1$
    .displayF1$ = emlUnderscoreToSpace.result$
    @emlUnderscoreToSpace: .factor2$
    .displayF2$ = emlUnderscoreToSpace.result$

    @emlReportHeader: "Two-Way ANOVA"
    @emlReportLineString: "Table", .displayTable$
    @emlReportLineString: "Data column", .displayData$
    @emlReportLineString: "Factor 1", .displayF1$
    @emlReportLineString: "Factor 2", .displayF2$
    # The Info block named the table, the column and the two factors and
    # reported no N of any kind — not total, not per level, not per cell —
    # while the two-group section appended to the same transcript reported
    # N 24 / 24. @emlTwoWayAnova already carries all of it.
    @emlReportLine: "Total N", emlTwoWayAnova.nRows, 0
    @emlReportLine: "Cells", emlTwoWayAnova.nCells, 0
    if emlTwoWayAnova.minCellN = emlTwoWayAnova.maxCellN
        @emlReportLine: "n per cell", emlTwoWayAnova.minCellN, 0
    else
        @emlReportLineString: "n per cell",
        ... string$ (emlTwoWayAnova.minCellN) + " to "
        ... + string$ (emlTwoWayAnova.maxCellN) + " (unbalanced)"
    endif

    @emlReportBlank
    @emlReportSection: "ANOVA Table"
    if emlShowExplanations
        appendInfoLine: "  Why: Tests main effects of two factors "
        ... + "and their interaction."
    endif
    appendInfoLine: ""
    appendInfoLine: left$ ("Source" + "                    ", 20),
    ... left$ ("SS" + "                ", 16),
    ... left$ ("df" + "      ", 6),
    ... left$ ("MS" + "                ", 16),
    ... left$ ("F" + "            ", 12),
    ... "p"

    # All three rows printed @emlFormatP's "p = " form under a column
    # already headed "p", and all three floored to
    # "p < .001" — 5.8e-07, 2.1e-13 and 3.0e-04 reported identically, nine
    # orders of magnitude flattened in the one table whose whole point is the
    # relative strength of the three effects. The cells now carry the bare
    # APA form, and .exact$ records which of them were floored so the
    # unrounded values can be printed below the table.
    @emlFormatP: emlTwoWayAnova.pA
    .pCellA$ = emlFormatP.bare$
    .exactA$ = emlFormatP.exact$
    @emlFormatP: emlTwoWayAnova.pB
    .pCellB$ = emlFormatP.bare$
    .exactB$ = emlFormatP.exact$
    @emlFormatP: emlTwoWayAnova.pAB
    .pCellAB$ = emlFormatP.bare$
    .exactAB$ = emlFormatP.exact$

    @eml_fixed: emlTwoWayAnova.ssA, 2
    .fx1$ = eml_fixed.result$
    @eml_fixed: emlTwoWayAnova.msA, 2
    .fx2$ = eml_fixed.result$
    @eml_fixed: emlTwoWayAnova.fA, 4
    .fx3$ = eml_fixed.result$
    appendInfoLine: left$ (.displayF1$ + "                    ", 20),
    ... left$ (.fx1$ + "                ", 16),
    ... left$ (string$ (emlTwoWayAnova.dfA) + "      ", 6),
    ... left$ (.fx2$ + "                ", 16),
    ... left$ (.fx3$ + "            ", 12),
    ... .pCellA$

    @eml_fixed: emlTwoWayAnova.ssB, 2
    .fx1$ = eml_fixed.result$
    @eml_fixed: emlTwoWayAnova.msB, 2
    .fx2$ = eml_fixed.result$
    @eml_fixed: emlTwoWayAnova.fB, 4
    .fx3$ = eml_fixed.result$
    appendInfoLine: left$ (.displayF2$ + "                    ", 20),
    ... left$ (.fx1$ + "                ", 16),
    ... left$ (string$ (emlTwoWayAnova.dfB) + "      ", 6),
    ... left$ (.fx2$ + "                ", 16),
    ... left$ (.fx3$ + "            ", 12),
    ... .pCellB$

    .interLabel$ = .displayF1$ + " x " + .displayF2$
    .rawInterLabel$ = .factor1$ + "_x_" + .factor2$
    @eml_fixed: emlTwoWayAnova.ssAB, 2
    .fx1$ = eml_fixed.result$
    @eml_fixed: emlTwoWayAnova.msAB, 2
    .fx2$ = eml_fixed.result$
    @eml_fixed: emlTwoWayAnova.fAB, 4
    .fx3$ = eml_fixed.result$
    appendInfoLine: left$ (.interLabel$ + "                    ", 20),
    ... left$ (.fx1$ + "                ", 16),
    ... left$ (string$ (emlTwoWayAnova.dfAB) + "      ", 6),
    ... left$ (.fx2$ + "                ", 16),
    ... left$ (.fx3$ + "            ", 12),
    ... .pCellAB$

    @eml_fixed: emlTwoWayAnova.ssError, 2
    .fx1$ = eml_fixed.result$
    @eml_fixed: emlTwoWayAnova.msError, 2
    .fx2$ = eml_fixed.result$
    appendInfoLine: left$ ("Error" + "                    ", 20),
    ... left$ (.fx1$ + "                ", 16),
    ... left$ (string$ (emlTwoWayAnova.dfError) + "      ", 6),
    ... left$ (.fx2$ + "                ", 16)

    @eml_fixed: emlTwoWayAnova.ssTotal, 2
    .fx1$ = eml_fixed.result$
    appendInfoLine: left$ ("Total" + "                    ", 20),
    ... left$ (.fx1$ + "                ", 16),
    ... left$ (string$ (emlTwoWayAnova.dfTotal) + "      ", 6)

    # Only the floored rows need restating; at three decimals the table
    # already shows the value exactly, so this block stays silent unless a
    # p actually hit the .001 (or .999) floor.
    if .exactA$ <> "" or .exactB$ <> "" or .exactAB$ <> ""
        @emlReportBlank
        @emlReportSection: "Exact p-values"
        @emlReportPWithExact: .displayF1$, emlTwoWayAnova.pA
        @emlReportPWithExact: .displayF2$, emlTwoWayAnova.pB
        @emlReportPWithExact: .interLabel$, emlTwoWayAnova.pAB
    endif

    ; @emlTwoWayAnova sets .warning$ for conditions the user needs to know
    ; about -- unbalanced cells, an empty cell, a design the Type of sums of
    ; squares assumption does not fit. It was written to the glance frame in
    ; @emlDeclareTwoWayResult (eml-analysis.praat, the @emlGlanceStr:
    ; "warning" line) and it is printed HERE too, or a user reading the
    ; report never sees it and only a user who exported the CSV does. Grep
    ; the anchor rather than trusting a line number; they move.
    ;
    ; Placed immediately under the table it qualifies: a caveat below the
    ; effect sizes reads as being about the effect sizes.
    if emlTwoWayAnova.warning$ <> ""
        @emlReportBlank
        @emlReportNote: "Caution: " + emlTwoWayAnova.warning$
    endif

    ; A significant interaction qualifies both main effects: it says the
    ; effect of each factor DEPENDS on the level of the other, so a single
    ; main-effect F averaged across that dependence can be misleading on its
    ; own. Precedent for the wording and the placement is the RM-ANOVA
    ; caution in @emlRunRepeatedMeasuresAnalysis (eml-analysis.praat, the
    ; `emlRMAnovaTest.warning$` block). Grep the anchor rather than trusting
    ; a line number; they move.
    ;
    ; THE DIRECTION IS NOT FIXED, so the caveat does not name one. A marginal
    ; effect is an average of the simple effects, and an average sits between
    ; its terms: it is smaller than the largest and larger than the smallest.
    ; Measured on evidence/csv/dump_demo_twoway.csv, voice type marginally is
    ; 94.646 - 89.842 = 4.80 dB, while its simple effects are 8.03 dB within
    ; Singing and 1.58 dB within Speech -- the one marginal number understates
    ; the first and overstates the second at the same time. Naming a direction
    ; would be a second claim about the data, and no direction is available to
    ; claim.
    if emlTwoWayAnova.pAB < 0.05
        @emlReportBlank
        @emlReportNote: "Caution: the interaction is significant, so each "
        ... + "factor's effect depends on the level of the other. The two "
        ... + "main-effect rows above average over simple effects that "
        ... + "differ from one another, and such an average can obscure, "
        ... + "understate or overstate any one of them. Read the cell means "
        ... + "below before reading the main effects."
    endif

    # Effect sizes
    # The three partial eta-squareds were printed bare, with no
    # small/medium/large gloss, while the one-way and Kruskal-Wallis reports
    # both gloss theirs. The label is computed once per effect here and the
    # same string goes to the report and to the export.
    @emlFormatEffectLabel: emlTwoWayAnova.partialEtaSqA, "eta_squared"
    .etaLabelA$ = emlFormatEffectLabel.label$
    @emlFormatEffectLabel: emlTwoWayAnova.partialEtaSqB, "eta_squared"
    .etaLabelB$ = emlFormatEffectLabel.label$
    @emlFormatEffectLabel: emlTwoWayAnova.partialEtaSqAB, "eta_squared"
    .etaLabelAB$ = emlFormatEffectLabel.label$

    @emlReportBlank
    @emlReportSection: "Effect Sizes (partial eta-squared)"
    if emlShowExplanations
        @emlWizardExplainEffectPartialEta2: emlTwoWayAnova.partialEtaSqA
    endif
    @eml_fixed: emlTwoWayAnova.partialEtaSqA, 4
    .etaTextA$ = eml_fixed.result$
    if .etaLabelA$ <> ""
        .etaTextA$ = .etaTextA$ + "  (" + .etaLabelA$ + ")"
    endif
    @emlReportLineString: .displayF1$, .etaTextA$
    if emlShowExplanations
        @emlWizardExplainEffectPartialEta2: emlTwoWayAnova.partialEtaSqB
    endif
    @eml_fixed: emlTwoWayAnova.partialEtaSqB, 4
    .etaTextB$ = eml_fixed.result$
    if .etaLabelB$ <> ""
        .etaTextB$ = .etaTextB$ + "  (" + .etaLabelB$ + ")"
    endif
    @emlReportLineString: .displayF2$, .etaTextB$
    if emlShowExplanations
        @emlWizardExplainEffectPartialEta2: emlTwoWayAnova.partialEtaSqAB
    endif
    @eml_fixed: emlTwoWayAnova.partialEtaSqAB, 4
    .etaTextAB$ = eml_fixed.result$
    if .etaLabelAB$ <> ""
        .etaTextAB$ = .etaTextAB$ + "  (" + .etaLabelAB$ + ")"
    endif
    @emlReportLineString: .interLabel$, .etaTextAB$

    # The block went ANOVA table → partial eta-squared → CSV → footer
    # with no cell means and no marginal means, so a significant interaction
    # said the factors are not additive but never in which direction. The
    # values were already computed: @emlTwoWayAnova carries every cell's
    # label, n and mean, and both factors' level lists.
    if emlTwoWayAnova.nCells > 0
        @emlReportBlank
        @emlReportSection: "Cell Means"
        appendInfoLine: ""
        appendInfoLine: left$ (.displayF1$ + "                    ", 18),
        ... left$ (.displayF2$ + "                    ", 18),
        ... left$ ("n" + "        ", 8),
        ... "Mean"
        for .a from 1 to emlTwoWayAnova.nLev1
            for .b from 1 to emlTwoWayAnova.nLev2
                # @emlTwoWayAnova keys cells as level1 + newline$ + level2.
                .cellKey$ = emlTwoWayAnova.lev1$[.a] + newline$
                ... + emlTwoWayAnova.lev2$[.b]
                .hit = 0
                for .c from 1 to emlTwoWayAnova.nCells
                    if emlTwoWayAnova.cellLabel$[.c] = .cellKey$
                        .hit = .c
                    endif
                endfor
                .rowA$ = replace$ (emlTwoWayAnova.lev1$[.a], "_", " ", 0)
                if length (.rowA$) > 16
                    .rowA$ = left$ (.rowA$, 16)
                endif
                .rowB$ = replace$ (emlTwoWayAnova.lev2$[.b], "_", " ", 0)
                if length (.rowB$) > 16
                    .rowB$ = left$ (.rowB$, 16)
                endif
                if .hit = 0
                    .cellNText$ = "0"
                    .cellMeanText$ = "empty cell"
                else
                    .cellNText$ = string$ (emlTwoWayAnova.cellN[.hit])
                    @eml_fixed: emlTwoWayAnova.cellMean[.hit], 4
                    .cellMeanText$ = eml_fixed.result$
                endif
                appendInfoLine: left$ (.rowA$ + "                    ", 18),
                ... left$ (.rowB$ + "                    ", 18),
                ... left$ (.cellNText$ + "        ", 8),
                ... .cellMeanText$
            endfor
        endfor

        # Marginal means, weighted by cell n so they stay correct on an
        # unbalanced design.
        @emlReportBlank
        @emlReportSection: "Marginal Means"
        appendInfoLine: ""
        appendInfoLine: left$ ("Level" + "                            ", 30),
        ... left$ ("n" + "        ", 8),
        ... "Mean"
        for .a from 1 to emlTwoWayAnova.nLev1
            .margN = 0
            .margSum = 0
            .keyA$ = emlTwoWayAnova.lev1$[.a] + newline$
            for .c from 1 to emlTwoWayAnova.nCells
                # The newline in the key anchors the match, so a level named
                # "a" cannot swallow the cells of a level named "ab".
                .headA$ = left$ (emlTwoWayAnova.cellLabel$[.c],
                ... length (.keyA$))
                if .headA$ = .keyA$
                    .margN = .margN + emlTwoWayAnova.cellN[.c]
                    .margSum = .margSum
                    ... + emlTwoWayAnova.cellN[.c] * emlTwoWayAnova.cellMean[.c]
                endif
            endfor
            .margLabel$ = .displayF1$ + ": "
            ... + replace$ (emlTwoWayAnova.lev1$[.a], "_", " ", 0)
            if length (.margLabel$) > 28
                .margLabel$ = left$ (.margLabel$, 28)
            endif
            if .margN > 0
                @eml_fixed: .margSum / .margN, 4
                .margText$ = eml_fixed.result$
            else
                .margText$ = "no data"
            endif
            appendInfoLine: left$ (.margLabel$ + "                            ", 30),
            ... left$ (string$ (.margN) + "        ", 8),
            ... .margText$
        endfor
        for .b from 1 to emlTwoWayAnova.nLev2
            .margN = 0
            .margSum = 0
            .keyB$ = newline$ + emlTwoWayAnova.lev2$[.b]
            for .c from 1 to emlTwoWayAnova.nCells
                .tailB$ = right$ (emlTwoWayAnova.cellLabel$[.c],
                ... length (.keyB$))
                if .tailB$ = .keyB$
                    .margN = .margN + emlTwoWayAnova.cellN[.c]
                    .margSum = .margSum
                    ... + emlTwoWayAnova.cellN[.c] * emlTwoWayAnova.cellMean[.c]
                endif
            endfor
            .margLabel$ = .displayF2$ + ": "
            ... + replace$ (emlTwoWayAnova.lev2$[.b], "_", " ", 0)
            if length (.margLabel$) > 28
                .margLabel$ = left$ (.margLabel$, 28)
            endif
            if .margN > 0
                @eml_fixed: .margSum / .margN, 4
                .margText$ = eml_fixed.result$
            else
                .margText$ = "no data"
            endif
            appendInfoLine: left$ (.margLabel$ + "                            ", 30),
            ... left$ (string$ (.margN) + "        ", 8),
            ... .margText$
        endfor
    endif

    # CSV rows — one per effect
    # EVERY TERM CARRIES BOTH df, ITS SS AND ITS MS, and the error and total
    # rows are exported too. A single df column exports F(1,28) as df=1.00
    # and the ANOVA table cannot be reconstructed from the file.
    #
    # N is stated in both places: the n/n_cells fields below carry it into
    # the export, and the header block above prints total N, cell count and
    # per-cell n into the Info window. Every factor row's
    # partial_eta_squared has an effect_label beside it -- the labels are
    # computed above and written below.
    @emlCSVSetTable: .tableName$
    @emlCSVTermType: "omnibus"
    .twLab$ = "Two-way ANOVA"
    @emlCSVAddStr: .twLab$, "", "data_column", .dataCol$
    @emlCSVAddStr: .twLab$, "", "factor_1", .factor1$
    @emlCSVAddStr: .twLab$, "", "factor_2", .factor2$
    @emlCSVAdd: .twLab$, "", "n", emlTwoWayAnova.nRows
    @emlCSVAdd: .twLab$, "", "n_cells", emlTwoWayAnova.nCells

    @emlCSVTermType: "factor"
    @emlCSVAdd: .twLab$, .factor1$, "F", emlTwoWayAnova.fA
    @emlCSVAdd: .twLab$, .factor1$, "df1", emlTwoWayAnova.dfA
    @emlCSVAdd: .twLab$, .factor1$, "df2", emlTwoWayAnova.dfError
    @emlCSVAdd: .twLab$, .factor1$, "p", emlTwoWayAnova.pA
    @emlCSVAdd: .twLab$, .factor1$, "ss", emlTwoWayAnova.ssA
    @emlCSVAdd: .twLab$, .factor1$, "ms", emlTwoWayAnova.msA
    @emlCSVAdd: .twLab$, .factor1$, "partial_eta_squared",
    ... emlTwoWayAnova.partialEtaSqA
    @emlCSVAddStr: .twLab$, .factor1$, "effect_label", .etaLabelA$

    @emlCSVAdd: .twLab$, .factor2$, "F", emlTwoWayAnova.fB
    @emlCSVAdd: .twLab$, .factor2$, "df1", emlTwoWayAnova.dfB
    @emlCSVAdd: .twLab$, .factor2$, "df2", emlTwoWayAnova.dfError
    @emlCSVAdd: .twLab$, .factor2$, "p", emlTwoWayAnova.pB
    @emlCSVAdd: .twLab$, .factor2$, "ss", emlTwoWayAnova.ssB
    @emlCSVAdd: .twLab$, .factor2$, "ms", emlTwoWayAnova.msB
    @emlCSVAdd: .twLab$, .factor2$, "partial_eta_squared",
    ... emlTwoWayAnova.partialEtaSqB
    @emlCSVAddStr: .twLab$, .factor2$, "effect_label", .etaLabelB$

    @emlCSVAdd: .twLab$, .rawInterLabel$, "F", emlTwoWayAnova.fAB
    @emlCSVAdd: .twLab$, .rawInterLabel$, "df1", emlTwoWayAnova.dfAB
    @emlCSVAdd: .twLab$, .rawInterLabel$, "df2", emlTwoWayAnova.dfError
    @emlCSVAdd: .twLab$, .rawInterLabel$, "p", emlTwoWayAnova.pAB
    @emlCSVAdd: .twLab$, .rawInterLabel$, "ss", emlTwoWayAnova.ssAB
    @emlCSVAdd: .twLab$, .rawInterLabel$, "ms", emlTwoWayAnova.msAB
    @emlCSVAdd: .twLab$, .rawInterLabel$, "partial_eta_squared",
    ... emlTwoWayAnova.partialEtaSqAB
    @emlCSVAddStr: .twLab$, .rawInterLabel$, "effect_label", .etaLabelAB$

    @emlCSVTermType: "error"
    @emlCSVAdd: .twLab$, "Error", "df1", emlTwoWayAnova.dfError
    @emlCSVAdd: .twLab$, "Error", "ss", emlTwoWayAnova.ssError
    @emlCSVAdd: .twLab$, "Error", "ms", emlTwoWayAnova.msError

    @emlCSVTermType: "total"
    @emlCSVAdd: .twLab$, "Total", "df1", emlTwoWayAnova.dfTotal
    @emlCSVAdd: .twLab$, "Total", "ss", emlTwoWayAnova.ssTotal

    @emlReportFooter
endproc


# ============================================================================
# END OF EML ANNOTATION PROCEDURES
# ============================================================================
