# ============================================================================
# EML GRAPHS — ANNOTATION + STATS BRIDGE PROCEDURES
# ============================================================================
# Author: Ian Howell, Embodied Music Lab, www.embodiedmusiclab.com
# Development: Claude (Anthropic)
# Part of EML PraatGen GPL-3.0-or-later — Ian Howell, Embodied Music Lab
# Version: 3.20
# Date: 9 August 2026
#
# v3.20: THE LEGEND IS AN ANNOTATION, AND NOW PAYS FOR ITS OWN ROOM.
#        eml-draw-procedures.praat has said since 5 Aug that "any extra room
#        a figure needs is a property of what is drawn on it ... and is
#        supplied by @emlComputeAnnotationHeadroom at the annotation stage".
#        Only the significance bracket honoured it. A legend drawn inside the
#        plot is an annotation box by the same definition and contributed
#        NOTHING to the axis, so the figure was never given room for it and
#        it landed on the data — 13145 data pixels covered on a five-group
#        line chart at 6 x 4, measured on the rendered PNG, 9 Aug 2026, by
#        differencing it against the same figure on the same axis with the
#        legend suppressed. The worst of the six types measured 23702.
#        [1] @emlComputeAnnotationHeadroom takes two more arguments — the
#            laid-out legend height in inches (from @emlMeasureLegendPanel,
#            the same measurement the renderer lays itself out with, so the
#            two cannot disagree) and the corner it will occupy — and returns
#            .footroom beside .headroom, because a legend in a bottom corner
#            is not helped by room above the data. Both bands go into ONE
#            algebraic solve: the expansion is not linear in the band, so
#            solving twice and adding would be wrong. With no legend the
#            outputs are bit-identical to v3.19, and .overflow still means
#            "the brackets do not fit" and nothing else.
#        [2] The legend band is capped at emlLegendHeadroomShare (default 0.5)
#            of the panel, so a 24-entry key cannot leave a figure with no
#            plot. A capped band is NOT silently swallowed: .legendOverflow
#            goes up and the caller names the shortfall in the Info window.
#        [3] @emlPlaceElements is UNCHANGED, deliberately — see the note in
#            its header for why penalising quadrants by legend size does not
#            make the corner choice and the headroom agree, and what does.
#
# v3.19: D124 — @emlDrawAnnotationBlock wraps.
#        [1] The box was sized to its longest line exactly as handed in, so
#            one long disclosure line made it wide enough to sit over the
#            data and, on a narrow figure, to run off the canvas. Lines are
#            now wrapped through @emlWrapText to a budget taken from the
#            frame (emlAnnotBlockWidthShare, 0.55 of the inner viewport less
#            the box's padding and inset), never from a character constant —
#            annotSize scales with the viewport, so a character is a near
#            constant FRACTION of the panel and "keep it under 50
#            characters" has always meant "up to seven eighths of the panel".
#            Measured 8 Aug 2026 on a 3.6 x 3 inch 4-bar chart: box width
#            fell from 1.79 to 0.52 of the axis range, and the rightmost
#            inked pixel column from 1079 (the canvas edge, i.e. clipped)
#            to 929, which is exactly where a figure carrying no box at all
#            ends. On the real @emlDisclose path the box fell from 0.75 to
#            0.49 of the frame and the data pixels it covered from 28 to 0.
#        [2] Wrapping can only trade width for height, so the box is
#            re-wrapped wider (to at most 0.72) when it would otherwise
#            stand taller than the frame. Nothing is ever truncated.
#        [3] Praat markup survives the break: a wrapped line's Draw string is
#            cut at the same word boundaries as its Label, guarded by a word
#            count check, so the omnibus "%H(3) = ..., %p = ..." keeps its
#            italics on both halves. New helper @emlSpaceCount.
#        [4] Comment corrections. The wizard pointer for the skew/kurtosis
#            criterion was :2085 (a "Data column:" padding line) and is now
#            :2170-2175. The D95 note claimed the gate's kurtosis threshold
#            was 1; it is 7 (emlSkewThreshold 2 / emlKurtosisThreshold 7 in
#            stats/eml-output.praat), which reverses the direction of the
#            contradiction it describes — rewritten to match the code, the
#            threshold itself untouched. Two eml-analysis.praat pointers had
#            drifted (:2961 now sits in @emlDeclareKWResult, :2194 in
#            @emlRMAnovaTest's arithmetic) and now name their anchors.
#            @emlCSVAddRow, named as the reporters' CSV entry point, does
#            not exist anywhere in the plugin — the real ones are @emlCSVAdd
#            / @emlCSVAddStr / @emlCSVAddDescriptives. The Procedures index
#            listed 15 of the file's 26. v2.7's "all 6 test paths" is 4,
#            which is what its own list names and what the code has.
#            annotBlockLabel$'s "max 20 lines" is @emlDisclose's disclosure
#            cap, not the array's — the form appends a 21st.
#
# v3.18: Audit fixes (annotation/stats-bridge layer).
#        [1] @emlClearAnnotations now clears annotMatrixLabel$[] over the
#            previous figure's annotMatrixN range — stale group labels no
#            longer survive into the next figure.
#        [2] @emlBridgeGroupComparison no longer aborts when the global
#            annotCorrectionMethod$ is unset: it defaults to "holm" and
#            validates the value against what @emlDunnTest accepts.
#        [3] Stale procedure-output reads eliminated. @emlCountGroups
#            labels are captured into .gLabel$[] at bridge entry, and the
#            Dunn / one-way-ANOVA p-matrices and group names are captured
#            immediately after their calls, before any intervening
#            procedure can overwrite them. The bracket output paths read
#            the captured labels instead of annotMatrixLabel$[], which is
#            only ever written on the matrix path. @emlReportBridgeStats
#            reads emlBridgeGroupComparison.gLabel$[] for the same reason.
#        [4] @emlFormatStars now derives its thresholds from annotAlpha
#            (alpha, alpha/5, alpha/50) instead of hardcoding
#            0.05/0.01/0.001, exposes .legend$ describing the ladder in
#            force, and returns "n/a" for an undefined p instead of
#            silently reporting it as non-significant.
#        [5] The ANOVA omnibus-not-significant matrix path now sets
#            annotMatrixSig from the Tukey p-value actually printed in the
#            cell rather than hardcoding 0.
#        [6] The Kruskal-Wallis omnibus-not-significant matrix path takes
#            its marker from @emlFormatStars instead of a literal "n.s.".
#        [7] @emlReportTwoGroupComparison reports the Mann-Whitney method
#            @emlMannWhitneyU actually used (read defensively via
#            variableExists) and states the real routing rule — exact iff
#            both groups have n < 50 and there are no ties — replacing the
#            incorrect "(n < 50)" / "(n >= 50)" total-n gloss.
#        [9] Housekeeping: the matrix legend's annotAlpha read is guarded
#            the same way as @emlFormatStars; @emlMeasureMatrixLayout's
#            in-place mutation of annotMatrixLabel$[] is documented in
#            full; @emlBridgeCorrelation is marked UNUSED (no caller).
#
# v3.17: Renamed emlWizardMode → emlShowExplanations throughout.
# v3.16: Wizard mode third-column explanations. All 8 @emlReport*
#         procedures now conditionally append value-anchored
#         interpretations when emlShowExplanations = 1. "Why:" explanation
#         lines are now conditional on wizard mode (suppressed in
#         wrapper output). Report procedures affected:
#         @emlReportTwoGroupComparison, @emlReportAnovaComparison,
#         @emlReportKWComparison, @emlReportCorrelationAnalysis,
#         @emlReportRegressionAnalysis, @emlReportNormalityAnalysis,
#         @emlReportPairedComparison, @emlReportTwoWayAnova.
#
# v3.15: Bug #11 fix — @emlReportAnovaComparison Cohen's d matrix now
#         always reported, not gated behind Tukey toggle. Reads from
#         emlOneWayAnova.dMatrix## (guaranteed by orchestrator). All
#         group label references changed from .groupName$ to
#         .groupLabel$ (always set). Parallel fix in
#         @emlReportKWComparison: rank-biserial r matrix always
#         reported. Reads from emlKruskalWallis.rMatrix## (guaranteed
#         by orchestrator).
#
# v3.14: Matrix label sanitization — annotMatrixLabel$[] sanitized at
#         top of @emlMeasureMatrixLayout (after bridge data lookups,
#         before text measurement and rendering). Fixes underscore
#         rendering as subscript in matrix row/column headers.
#
# v3.13: Group sort order — removed 4 independent sort$# calls from
#        bridge and reporter procedures. Order now controlled centrally
#        by @emlCountGroups via emlGroupSortAlphabetical global.
#
# v3.12: Matrix legend bottom padding increased from fontInch*0.5 to
#        fontInch*2.0 — legend was clipping below viewport on tall
#        figures with many groups. Tukey CSV rows now include q-statistic
#        and dfWithin (were hardcoded 0). Effect labels (large/medium/
#        small) now populated on ANOVA omnibus, Tukey pairwise, and
#        Dunn pairwise CSV rows.
#
# v3.11: Bug #13 — @emlReportKWComparison Dunn CSV rows now include
#        real per-pair descriptives (n, mean, sd, median) and
#        rank-biserial r from emlDunnTest.rMatrix##. Added .tableId
#        parameter to signature. Three callers updated.
#
# v3.10: 10-group limit removal — deleted .extractIdx mapping blocks
#        in @emlBridgeGroupComparison, updated 17 @eml_getGroupData
#        calls to new 4-arg on-demand signature (eml-extract.praat),
#        reporter label source changed from emlExtractMultipleGroups
#        to emlOneWayAnova/emlTukeyHSD procedure outputs.
#
# v3.7: Pairwise effect size performance fix — k-group bridge paths AND
#        reporter pairwise loops now use @eml_getGroupData (on-demand
#        vectors) instead of per-pair @emlExtractGroupVectors calls.
#        Bridge: 6 paths updated (ANOVA sig/NS matrix+bracket, KW sig/NS
#        matrix+bracket). Reporter: @emlReportAnovaComparison d-matrix
#        and CSV loops updated (uses emlTukeyHSD.sortMap for index mapping).
#        Eliminates all per-pair table scans in k-group comparisons.
#        Reporter group descriptives inline if/elsif chain (30 lines)
#        replaced with @eml_getGroupData call.
#        Matrix panel legend swatch label reads annotAlpha instead of
#        hardcoded "p < .05". Dynamic label built by
#        @emlMeasureMatrixLayout, stored as emlMatrixLayout_pLegend$,
#        read by @emlDrawMatrixPanel at 2 sites (width + render).
# v3.6: @emlDrawMatrixPanel now calls @emlExpandDrawnExtent (from
#        eml-graph-procedures.praat) to register the matrix panel
#        viewport with the extent tracker, so @emlAssertFullViewport
#        captures the matrix panel when saving figures. Suppressed
#        panels (goto END_PANEL) correctly skip the update.
# v3.4: @emlReportBridgeStats restored as thin dispatcher — reads bridge
#        globals (.nGroups, .testType$), routes to shared reporters. Same
#        3-arg signature as original. Fixes "Procedure not found" error
#        when drawing annotated figures from eml-graphs.praat.
# v3.3: @emlReportTwoWayAnova added — shared reporter for two-way ANOVA.
#        Full ANOVA table (A, B, A×B, Error, Total), partial eta-squared,
#        "Why:" line, CSV rows (one per effect).
# v3.2: @emlReportPairedComparison added — shared reporter for paired t-test
#        and Wilcoxon signed-rank test. Uses correct output variable names
#        (.tPlus/.tMinus not .wPlus/.wMinus). "Why:" lines included.
#        CSV rows via @emlCSVAddRow. Parametric/nonparametric/both routing.
# v3.1: "Why:" pedagogical commentary added to all four shared reporters
#        (@emlReportTwoGroupComparison parametric + nonparametric,
#        @emlReportAnovaComparison, @emlReportKWComparison,
#        @emlReportCorrelationAnalysis Pearson + Spearman). Text sourced
#        from wizard @wizardRun* procedures. Always shown in Info window,
#        naturally excluded from CSV export (CSV rows are structured data).
# v3.0: @emlReportBridgeStats replaced by four shared reporter procedures
#        (@emlReportTwoGroupComparison, @emlReportAnovaComparison,
#        @emlReportKWComparison, @emlReportCorrelationAnalysis). These
#        produce identical Info window output regardless of entry point
#        (stats wrapper or graphs tool) and populate CSV rows via
#        @emlCSVAddRow for export. Uses @emlReport* primitives from
#        eml-output.praat for all formatting.
# v2.9: Matrix panel spacing tightened — clearance and gap now anchored
#        to annotInch/fontInch (panel's own font sizes) instead of
#        bodyInch (graph's body font). Non-rotated header multiplier
#        reduced from 1.8 to 1.2 (matching rotated path). Proportional
#        ratios match @emlDrawTitle for visual consistency.
# v2.8: Matrix subtitle fix — "Upper: adjusted p" added to subtitle when
#        effect sizes shown. Previously only showed "Lower: [effect label]"
#        with no description of what the upper triangle contains.
# v2.7: annotMatrixPosthoc$ global — set by @emlBridgeGroupComparison at
#        all 4 test paths (Welch t-test, Mann-Whitney U, Tukey HSD,
#        Dunn's test with configurable correction method) — the count read
#        "6" against its own list of four, and four is also what the code
#        has. Cleared by
#        @emlClearAnnotations. Subtitle in @emlDrawMatrixPanel now reads
#        "Tukey HSD · Lower: |Cohen's d|" (with effect) or just the
#        test name (without). Info window report shows "Test:" (2-group)
#        or "Post-hoc:" (k-group) line. Hardcoded "holm" in @emlDunnTest
#        call replaced by annotCorrectionMethod$ global (initialized to
#        "holm" in eml-graphs.praat, overridable by stats callers).
# v2.6: Dead @emlDrawComparisonMatrix overlay removed (−208 lines, replaced
#        by @emlDrawMatrixPanel since v1.4). .showEffect gate added to 5
#        hardcoded matrix population sites (3 effect label, 2 D-value) —
#        2-group NP/P matrix paths and ANOVA k-group significant path now
#        respect the toggle. .showNS gate added to all 6 matrix population
#        sites — upper-triangle cells show "—" when non-significant and
#        showNS = 0 (lower-triangle effect sizes unaffected).
#        New @emlMeasureMatrixLayout procedure — separates measurement
#        (rotate-then-truncate, vertical stacking, legend min width) from
#        @emlDrawMatrixPanel rendering. Matrix panel is now a pure renderer.
# v2.4: Effect size threshold branching — matrix panel now uses
#        correct thresholds per effect type: Cohen's d (0.8/0.5/0.2)
#        vs rank-biserial r (0.5/0.3/0.1). Cohen's d stored as
#        abs() in matrix (consistent with rank-biserial r). Matrix
#        subtitle reads "(magnitude)" to clarify unsigned display
#        while omnibus retains signed d. Removed >10 group hard
#        error — stats and Info window report now run for any group
#        count; matrix panel's own viewport-based display tiers
#        handle visual degradation. Column header-to-data padding
#        increased (0.3 → 0.8 fontInch) for non-rotated headers.
# v2.3: @emlPlaceElements replaces @emlAutoPlaceLegend — universal
#        quadrant-density + bracket-penalty corner selection for
#        legend and annotation block placement. All graph types
#        now use adaptive placement.
# v2.2: annotMatrixEffectLabel$ now stores full label ("Cohen's d" or
#        "rank-biserial r") instead of bare letter. Subtitle no longer
#        hardcodes "Cohen's" prefix — was producing "Cohen's r" for
#        nonparametric tests.
#
# v2.0: @emlReportBridgeStats: 2-group path now includes group descriptives
#        (N, Mean, SD, Median) matching the k-group report format.
# v1.9: @emlFormatAnnotLabel: new .effectLabel$ parameter — bracket labels
#        now show context-appropriate symbol ("d" for Cohen's d, "r" for
#        rank-biserial r) instead of hardcoded "d". All 9 callsites updated.
#        @emlBridgeGroupComparison: .forceMatrix replaced by .layoutMode
#        (1=auto, 2=brackets, 3=matrix). Auto defaults to matrix at k>=3.
#        KW omnibus string now includes epsilon-squared (e2 = H/(n-1)).
#        New @emlReportBridgeStats procedure — writes full statistical
#        report (omnibus + descriptives + p-value matrix + effect matrix)
#        to Info window, callable from both graph dispatch and stats wrappers.
# v1.8: Nonparametric k-group matrix (KW/Dunn's) now computes pairwise
#        rank-biserial |r| for the lower triangle, mirroring the ANOVA
#        path's per-pair Cohen's d. Bracket output also includes r when
#        effect sizes are requested. Subtitle auto-selects "r" label.
# v1.7: @emlDrawMatrixPanel subtitle now shows three-way conditional:
#        "Upper: adjusted p-values · Lower: Cohen's d" (parametric),
#        "Upper: adjusted p-values · Lower: rank-biserial r" (nonparam),
#        or "Adjusted p-values" (no effect sizes). Previously subtitle
#        was suppressed entirely when hasEffect = 0.
# v1.6: Bracket headroom circular dependency fix — algebraic solve for
#        post-expansion wpiY with overflow guard. Matrix panel top-down
#        sizing (1.0–1.3× responsive zone, content minimum cap). Swatch
#        squareness fix — computed in inches, converted to grid units.
# v1.4: @emlDrawMatrixPanel: new .colorMode$ parameter — B/W mode uses
#        medium grey bg for significant p-values, black bg + white text
#        for large effect sizes, dark grey + white for medium. Title and
#        subtitle spacing increased (titleY 0.5, subtitleY 1.5, headerY
#        2.2, dataTop 2.8) to prevent collision at 10 groups. Legend
#        row centered on grid midpoint instead of left-aligned.
# v1.3: @emlDrawAnnotationBlock and @emlDrawAnnotation: replaced charW
#        estimation (length * fixedWidth) with exact text measurement via
#        Text width (world coordinates): — queries the rendering engine
#        for actual rendered string width in the current font/size/axes.
#        Fixes box sizing for proportional fonts (the fundamental flaw in
#        all prior charW-based approaches). Symmetric vertical padding.
#        @emlDrawRegressionLine: white halo (width 3.5) drawn under the
#        colored line for visibility against dense data.
#        Semi-transparent backgrounds via alpha sprite for annotation block
#        (falls back to opaque white if sprites unavailable).
# v1.2: charW estimation attempts (superseded by v1.3).
# v1.1: Spearman label split (Info window plain text vs Picture window
#        markup). New @emlDrawAnnotationBlock for multi-line text boxes
#        with background fill and corner positioning. New @emlOppositeCorner.
#        annotBlockN/annotBlockLabel$/annotBlockDraw$ data structures.
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
# Procedures (all 26, in file order — this list used to name 15 and silently
# omit @emlOppositeCorner, @emlDrawAnnotationBlock, @emlDrawMatrixPanel and
# every shared reporter except the last two):
#   @emlClearAnnotations         — reset all annotation arrays
#   @emlFormatStars              — p-value to star notation
#   @emlFormatAnnotLabel         — format bracket label from p, d, style
#   @emlStackBrackets            — assign vertical tiers to brackets
#   @emlDrawBracket              — render one significance bracket
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
#   @emlBridgeGroupComparison    — run group test, populate brackets
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
# @emlFormatAnnotLabel
# Format the display label for a bracket annotation.
# Arguments: .p, .d, .style$, .showEffect, .effectLabel$
#   .p            — p-value
#   .d            — effect size value (Cohen's d, rank-biserial r, etc.)
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
        .dText$ = fixed$ (.d, 2)
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
    Font size: .fontSize
    Colour: "{0.1, 0.1, 0.1}"
    Text: .xMid, "centre", .yText, "bottom", .label$

    Colour: "Black"
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
# procedures.praat states it where the F0 minimum-span floors used to be —
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
# WRAPPING (D124). The box used to be exactly as wide as its longest line as
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
# on every figure size — the advice could not have prevented D124. The budget
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
        ; 4-bar / 5-line figure of D124 at 3.6 x 3 inches — kept narrow the
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
    endif
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
#     the bridge (@emlBridgeGroupComparison.gLabel$[]);
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
        ; D30: was {0.45} = 3.98:1 on this 0.92 ground. {0.40} = 4.80:1.
        .pNsText$     = "{0.40, 0.40, 0.40}"
        .dLargeBg$    = "{0.12, 0.12, 0.12}"
        .dLargeText$  = "{1.0, 1.0, 1.0}"
        .dMediumBg$   = "{0.45, 0.45, 0.45}"
        .dMediumText$ = "{1.0, 1.0, 1.0}"
        .dSmallBg$    = "{0.92, 0.92, 0.92}"
        ; D30: was {0.50} = 3.32:1 on this 0.92 ground. {0.40} = 4.80:1.
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
        ; D30: was {0.50} = 3.64:1 on this 0.96 ground. {0.40} = 5.26:1.
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
    # D30: this sub-line is the ONLY place in the figure that discloses which
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
        ; D30: 5.74:1 against white — see the note on the branch above.
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
                # D72: the diagonal used the same em-dash as a cell that was
                # tested and came out non-significant with the p suppressed,
                # so "self-comparison, not applicable" and "tested, not
                # significant" rendered as the same glyph at the figure's
                # delivered scale. The diagonal now carries a centre dot,
                # which cannot be mistaken for a dash at any size, and the
                # suppressed-p cells keep the dash.
                # D30: the diagonal glyph is drawn as text on the white cell
                # ground and was {0.7} = 2.11:1 — below the 4.5:1 text
                # minimum and below even the 3:1 floor for graphical marks,
                # which is self-defeating for a glyph D72 introduced
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
        # grid width is no longer the sole ceiling
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
# BRIDGE PROCEDURES
# ============================================================================


# ----------------------------------------------------------------------------
# @emlBridgeGroupComparison
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
# ----------------------------------------------------------------------------
procedure emlBridgeGroupComparison: .tableId, .dataCol$, .factorCol$, .alpha, .style$, .showNS, .showEffect, .testType$, .layoutMode
    # .layoutMode: 1 = auto, 2 = force brackets, 3 = force matrix
    .omnibus$ = ""
    .error$ = ""

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

    # =================================================================
    # 2-GROUP COMPARISON
    # =================================================================

    if .error$ = "" and .nGroups = 2
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

                    @emlFormatP: .pVal
                    .omnibus$ = "Mann-Whitney: U = " + fixed$ (.u1, 1)
                    ... + ", " + emlFormatP.formatted$
                    ... + ", r = " + fixed$ (.effectVal, 2)
                    annotMatrixPosthoc$ = "Mann-Whitney U"

                    if .useMatrix
                        @emlFormatAnnotLabel: .pVal, undefined, .style$, 0, ""
                        annotMatrixN = 2
                        annotMatrixOmnibus$ = .omnibus$
                        if .showEffect = 1
                            annotMatrixEffectLabel$ = "rank-biserial r"
                        else
                            annotMatrixEffectLabel$ = ""
                        endif
                        annotMatrixLabel$[1] = .label1$
                        annotMatrixLabel$[2] = .label2$
                        annotMatrixCell1_2$ = emlFormatAnnotLabel.result$
                        annotMatrixD1_2 = undefined
                        if .showEffect = 1
                            annotMatrixD1_2 = .effectVal
                        endif
                        if .pVal < .alpha
                            annotMatrixSig1_2 = 1
                        else
                            annotMatrixSig1_2 = 0
                        endif
                        if annotMatrixSig1_2 = 0 and .showNS = 0
                            annotMatrixCell1_2$ = "—"
                        endif
                    else
                        annotBracketN = 1
                        annotBracketI[1] = 1
                        annotBracketJ[1] = 2
                        annotBracketP[1] = .pVal
                        annotBracketD[1] = .effectVal
                        @emlFormatAnnotLabel: .pVal, .effectVal, .style$, .showEffect, "r"
                        annotBracketLabel$[1] = emlFormatAnnotLabel.result$
                        annotBracketTier[1] = 1

                        if .pVal >= .alpha and .showNS = 0
                            annotBracketN = 0
                        endif
                    endif
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

                    @emlFormatP: .pVal
                    .omnibus$ = "Welch t: t(" + fixed$ (.dfVal, 1) + ") = "
                    ... + fixed$ (.tVal, 2)
                    ... + ", " + emlFormatP.formatted$
                    if .effectVal <> undefined
                        .omnibus$ = .omnibus$
                        ... + ", d = " + fixed$ (.effectVal, 2)
                    endif
                    annotMatrixPosthoc$ = "Welch t-test"

                    if .useMatrix
                        @emlFormatAnnotLabel: .pVal, undefined, .style$, 0, ""
                        annotMatrixN = 2
                        annotMatrixOmnibus$ = .omnibus$
                        if .showEffect = 1
                            annotMatrixEffectLabel$ = "Cohen's d"
                        else
                            annotMatrixEffectLabel$ = ""
                        endif
                        annotMatrixLabel$[1] = .label1$
                        annotMatrixLabel$[2] = .label2$
                        annotMatrixCell1_2$ = emlFormatAnnotLabel.result$
                        annotMatrixD1_2 = undefined
                        if .showEffect = 1
                            annotMatrixD1_2 = .effectVal
                        endif
                        if .pVal < .alpha
                            annotMatrixSig1_2 = 1
                        else
                            annotMatrixSig1_2 = 0
                        endif
                        if annotMatrixSig1_2 = 0 and .showNS = 0
                            annotMatrixCell1_2$ = "—"
                        endif
                    else
                        annotBracketN = 1
                        annotBracketI[1] = 1
                        annotBracketJ[1] = 2
                        annotBracketP[1] = .pVal
                        annotBracketD[1] = .effectVal
                        @emlFormatAnnotLabel: .pVal, .effectVal, .style$, .showEffect, "d"
                        annotBracketLabel$[1] = emlFormatAnnotLabel.result$
                        annotBracketTier[1] = 1

                        if .pVal >= .alpha and .showNS = 0
                            annotBracketN = 0
                        endif
                    endif
                endif
            endif
        endif
    endif

    # =================================================================
    # K-GROUP COMPARISON (3-10 groups)
    # =================================================================

    if .error$ = "" and .nGroups >= 3

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

                @emlFormatP: .pOmnibus
                # D29: the caption read ", e2 = 0.272". "e2" is not notation
                # for epsilon-squared. This string is only ever drawn by
                # Text special / Text in the Picture window — as the matrix
                # panel title or as the corner annotation block — so Praat's
                # symbol escapes apply: \ep is epsilon, ^ superscripts the
                # character after it.
                .omnibus$ = "Kruskal-Wallis: H(" + string$ (.dfOmnibus) + ") = "
                ... + fixed$ (.hVal, 2)
                ... + ", " + emlFormatP.formatted$
                ... + ", \ep^2 = " + fixed$ (.epsilonSq, 3)

                # Pairwise post-hoc
                if .pOmnibus < .alpha
                    @emlDunnTest: .tableId, .dataCol$, .factorCol$, .correction$
                    # Capture Dunn's outputs into locals immediately — the
                    # loops below call other procedures between reads.
                    .dunnError$ = emlDunnTest.error$
                    if .dunnError$ = ""
                        .pMat## = emlDunnTest.pMatrix##
                    endif
                    if .dunnError$ = ""
                        annotMatrixPosthoc$ = "Dunn's test ("
                        ... + .correction$ + ")"
                        # Group order from @emlCountGroups (no remapping needed)
                        if .useMatrix
                            # --- MATRIX OUTPUT (split triangle) ---
                            # Upper triangle: p-values only (text)
                            # Lower triangle: rank-biserial |r| (numeric, rendered by panel)
                            annotMatrixN = .nGroups
                            annotMatrixOmnibus$ = .omnibus$
                            if .showEffect = 1
                                annotMatrixEffectLabel$ = "rank-biserial r"
                            else
                                annotMatrixEffectLabel$ = ""
                            endif
                            for .i from 1 to .nGroups
                                annotMatrixLabel$[.i] = .gLabel$[.i]
                            endfor
                            for .i from 1 to .nGroups - 1
                                for .j from .i + 1 to .nGroups
                                    .pairP = .pMat##[.i, .j]

                                    # p-value text only (no effect in cell)
                                    @emlFormatAnnotLabel: .pairP, undefined, .style$, 0, ""
                                    annotMatrixCell'.i'_'.j'$ = emlFormatAnnotLabel.result$
                                    if .pairP < .alpha
                                        annotMatrixSig'.i'_'.j' = 1
                                    else
                                        annotMatrixSig'.i'_'.j' = 0
                                    endif
                                    if annotMatrixSig'.i'_'.j' = 0 and .showNS = 0
                                        annotMatrixCell'.i'_'.j'$ = "—"
                                    endif

                                    # Rank-biserial r stored numerically for lower triangle
                                    annotMatrixD'.i'_'.j' = undefined
                                    if .showEffect = 1
                                        @eml_getGroupData: .tableId, .dataCol$, .factorCol$, .gLabel$[.i]
                                        .v1# = eml_getGroupData.data#
                                        @eml_getGroupData: .tableId, .dataCol$, .factorCol$, .gLabel$[.j]
                                        @emlRankBiserialR: .v1#, eml_getGroupData.data#, 2
                                        if emlRankBiserialR.error$ = ""
                                            annotMatrixD'.i'_'.j' = abs (emlRankBiserialR.r)
                                        endif
                                    endif
                                endfor
                            endfor
                        else
                            # --- BRACKET OUTPUT ---
                            annotBracketN = 0
                            for .i from 1 to .nGroups - 1
                                for .j from .i + 1 to .nGroups
                                    .pairP = .pMat##[.i, .j]

                                    # Rank-biserial r per pair if effect display requested
                                    # (labels come from the locals captured at
                                    # entry — annotMatrixLabel$[] is never
                                    # written on the bracket path)
                                    .pairD = undefined
                                    if .showEffect = 1
                                        @eml_getGroupData: .tableId, .dataCol$, .factorCol$, .gLabel$[.i]
                                        .v1# = eml_getGroupData.data#
                                        @eml_getGroupData: .tableId, .dataCol$, .factorCol$, .gLabel$[.j]
                                        @emlRankBiserialR: .v1#, eml_getGroupData.data#, 2
                                        if emlRankBiserialR.error$ = ""
                                            .pairD = abs (emlRankBiserialR.r)
                                        endif
                                    endif

                                    if .pairP < .alpha or .showNS = 1
                                        annotBracketN = annotBracketN + 1
                                        .bIdx = annotBracketN
                                        annotBracketI[.bIdx] = .i
                                        annotBracketJ[.bIdx] = .j
                                        annotBracketP[.bIdx] = .pairP
                                        annotBracketD[.bIdx] = .pairD
                                        @emlFormatAnnotLabel: .pairP, .pairD, .style$, .showEffect, "r"
                                        annotBracketLabel$[.bIdx] = emlFormatAnnotLabel.result$
                                    endif
                                endfor
                            endfor
                            @emlStackBrackets
                        endif

                        # Omnibus as text annotation (both modes)
                        annotTextN = 1
                        annotTextX[1] = 0
                        annotTextY[1] = 0
                        annotTextLabel$[1] = .omnibus$
                        annotTextAnchor$[1] = "right"
                    endif
                else
                    # Omnibus not significant
                    if .useMatrix
                        annotMatrixN = .nGroups
                        annotMatrixOmnibus$ = .omnibus$
                        if .showEffect = 1
                            annotMatrixEffectLabel$ = "rank-biserial r"
                        else
                            annotMatrixEffectLabel$ = ""
                        endif
                        for .i from 1 to .nGroups
                            annotMatrixLabel$[.i] = .gLabel$[.i]
                        endfor
                        # The omnibus was not significant, so Dunn's test was
                        # never run and no pairwise p exists. Take the
                        # non-significant marker from the shared formatter
                        # (p = 1 is non-significant at any alpha) instead of
                        # hardcoding a literal, so this path stays consistent
                        # with every other cell in the figure.
                        @emlFormatStars: 1
                        .nsMark$ = emlFormatStars.result$
                        for .i from 1 to .nGroups - 1
                            for .j from .i + 1 to .nGroups
                                annotMatrixCell'.i'_'.j'$ = .nsMark$
                                annotMatrixSig'.i'_'.j' = 0
                                if .showNS = 0
                                    annotMatrixCell'.i'_'.j'$ = "—"
                                endif
                                annotMatrixD'.i'_'.j' = undefined
                                if .showEffect = 1
                                    @eml_getGroupData: .tableId, .dataCol$, .factorCol$, .gLabel$[.i]
                                    .v1# = eml_getGroupData.data#
                                    @eml_getGroupData: .tableId, .dataCol$, .factorCol$, .gLabel$[.j]
                                    @emlRankBiserialR: .v1#, eml_getGroupData.data#, 2
                                    if emlRankBiserialR.error$ = ""
                                        annotMatrixD'.i'_'.j' = abs (emlRankBiserialR.r)
                                    endif
                                endif
                            endfor
                        endfor
                    else
                        annotTextN = 1
                        annotTextX[1] = 0
                        annotTextY[1] = 0
                        annotTextLabel$[1] = .omnibus$
                        annotTextAnchor$[1] = "right"
                    endif
                endif
            endif


        else
            # --- One-way ANOVA + Tukey HSD ---
            @emlOneWayAnova: .tableId, .dataCol$, .factorCol$, 1
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
                .pMat## = emlOneWayAnova.pMatrix##
                for .g from 1 to .nGroups
                    .statName$[.g] = emlOneWayAnova.groupName$[.g]
                endfor

                @emlFormatP: .pOmnibus
                .omnibus$ = "One-way ANOVA: F(" + string$ (.dfB) + ", "
                ... + string$ (.dfW) + ") = "
                ... + fixed$ (.fVal, 2)
                ... + ", " + emlFormatP.formatted$
                annotMatrixPosthoc$ = "Tukey HSD"

                # --------------------------------------------------------
                # Index mapping: encounter order → ANOVA alphabetical order
                # emlCountGroups uses encounter order (matches x-axis)
                # emlOneWayAnova inherits Tukey alphabetical sort
                # Order controlled by @emlCountGroups.
                # Build map from display position to stats-procedure
                # position for matrix access.
                # Build map from display order to stats order
                for .i from 1 to .nGroups
                    .sortMap[.i] = 0
                    for .g from 1 to .nGroups
                        if .gLabel$[.i] = .statName$[.g]
                            .sortMap[.i] = .g
                        endif
                    endfor
                endfor

                # Pairwise from Tukey
                if .error$ = "" and .pOmnibus < .alpha and .anovaPairs > 0
                    if .useMatrix
                        # --- MATRIX OUTPUT (split triangle) ---
                        # Upper triangle: p-values only (text)
                        # Lower triangle: Cohen's d (numeric, rendered by panel)
                        annotMatrixN = .nGroups
                        annotMatrixOmnibus$ = .omnibus$
                        if .showEffect = 1
                            annotMatrixEffectLabel$ = "Cohen's d"
                        else
                            annotMatrixEffectLabel$ = ""
                        endif
                        for .i from 1 to .nGroups
                            annotMatrixLabel$[.i] = .gLabel$[.i]
                        endfor
                        for .i from 1 to .nGroups - 1
                            for .j from .i + 1 to .nGroups
                                .pairP = .pMat##[.sortMap[.i], .sortMap[.j]]

                                # p-value text only (no effect in cell)
                                @emlFormatAnnotLabel: .pairP, undefined, .style$, 0, ""
                                annotMatrixCell'.i'_'.j'$ = emlFormatAnnotLabel.result$
                                if .pairP < .alpha
                                    annotMatrixSig'.i'_'.j' = 1
                                else
                                    annotMatrixSig'.i'_'.j' = 0
                                endif
                                if annotMatrixSig'.i'_'.j' = 0 and .showNS = 0
                                    annotMatrixCell'.i'_'.j'$ = "—"
                                endif

                                # Cohen's d stored numerically for lower triangle
                                annotMatrixD'.i'_'.j' = undefined
                                if .showEffect = 1
                                    @eml_getGroupData: .tableId, .dataCol$, .factorCol$, .gLabel$[.i]
                                    .v1# = eml_getGroupData.data#
                                    @eml_getGroupData: .tableId, .dataCol$, .factorCol$, .gLabel$[.j]
                                    @emlCohenD: .v1#, eml_getGroupData.data#
                                    if emlCohenD.error$ = ""
                                        annotMatrixD'.i'_'.j' = abs (emlCohenD.d)
                                    endif
                                endif
                            endfor
                        endfor
                    else
                        # --- BRACKET OUTPUT ---
                        annotBracketN = 0
                        for .i from 1 to .nGroups - 1
                            for .j from .i + 1 to .nGroups
                                .pairP = .pMat##[.sortMap[.i], .sortMap[.j]]

                                # Cohen's d per pair if effect display requested
                                # (labels come from the locals captured at
                                # entry — annotMatrixLabel$[] is never
                                # written on the bracket path)
                                .pairD = undefined
                                if .showEffect = 1
                                    @eml_getGroupData: .tableId, .dataCol$, .factorCol$, .gLabel$[.i]
                                    .v1# = eml_getGroupData.data#
                                    @eml_getGroupData: .tableId, .dataCol$, .factorCol$, .gLabel$[.j]
                                    @emlCohenD: .v1#, eml_getGroupData.data#
                                    if emlCohenD.error$ = ""
                                        .pairD = emlCohenD.d
                                    endif
                                endif

                                if .pairP < .alpha or .showNS = 1
                                    annotBracketN = annotBracketN + 1
                                    .bIdx = annotBracketN
                                    annotBracketI[.bIdx] = .i
                                    annotBracketJ[.bIdx] = .j
                                    annotBracketP[.bIdx] = .pairP
                                    annotBracketD[.bIdx] = .pairD
                                    @emlFormatAnnotLabel: .pairP, .pairD, .style$, .showEffect, "d"
                                    annotBracketLabel$[.bIdx] = emlFormatAnnotLabel.result$
                                endif
                            endfor
                        endfor
                        @emlStackBrackets
                    endif

                    # Omnibus as text annotation (both modes)
                    annotTextN = 1
                    annotTextX[1] = 0
                    annotTextY[1] = 0
                    annotTextLabel$[1] = .omnibus$
                    annotTextAnchor$[1] = "right"
                else
                    # Omnibus not significant or no pairs
                    if .useMatrix
                        annotMatrixN = .nGroups
                        annotMatrixOmnibus$ = .omnibus$
                        if .showEffect = 1
                            annotMatrixEffectLabel$ = "Cohen's d"
                        else
                            annotMatrixEffectLabel$ = ""
                        endif
                        for .i from 1 to .nGroups
                            annotMatrixLabel$[.i] = .gLabel$[.i]
                        endfor
                        for .i from 1 to .nGroups - 1
                            for .j from .i + 1 to .nGroups
                                .pairP = .pMat##[.sortMap[.i], .sortMap[.j]]
                                @emlFormatAnnotLabel: .pairP, undefined, .style$, 0, ""
                                annotMatrixCell'.i'_'.j'$ = emlFormatAnnotLabel.result$
                                # Significance flag must follow the Tukey
                                # p-value actually printed in the cell, not a
                                # blanket 0 — otherwise the cell text and the
                                # cell styling disagree.
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
                                    @eml_getGroupData: .tableId, .dataCol$, .factorCol$, .gLabel$[.i]
                                    .v1# = eml_getGroupData.data#
                                    @eml_getGroupData: .tableId, .dataCol$, .factorCol$, .gLabel$[.j]
                                    @emlCohenD: .v1#, eml_getGroupData.data#
                                    if emlCohenD.error$ = ""
                                        annotMatrixD'.i'_'.j' = abs (emlCohenD.d)
                                    endif
                                endif
                            endfor
                        endfor
                    else
                        annotTextN = 1
                        annotTextX[1] = 0
                        annotTextY[1] = 0
                        annotTextLabel$[1] = .omnibus$
                        annotTextAnchor$[1] = "right"
                    endif
                endif
            endif
        endif
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
    ; On 12 Aug 2026 capture hooks were added to all thirteen orchestrators
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
            ... "@emlBridgeGroupComparison: data, """ + .dataCol$ + """, """
            ... + .factorCol$ + """, " + string$ (.alpha) + ", """ + .style$
            ... + """, " + string$ (.showNS) + ", " + string$ (.showEffect)
            ... + ", """ + .testType$ + """, " + string$ (.layoutMode),
            ... "In the GUI: New > EML Tools > EML Graphs..., with statistical annotation switched on.",
            ... .error$
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
            @emlSpearmanCorrelation: .xData#, .yData#, 2
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
# @emlReportBridgeStats — thin dispatcher for graphs tool
# ============================================================================
# Called by eml-graphs.praat after @emlBridgeGroupComparison has run.
# Routes to the correct shared reporter based on bridge globals.
# Same 3-argument signature as the original monolithic reporter.
# ============================================================================
procedure emlReportBridgeStats: .tableId, .dataCol$, .groupCol$
    selectObject: .tableId
    .tableName$ = selected$ ("Table")
    .nGroups = emlBridgeGroupComparison.nGroups
    .testType$ = emlBridgeGroupComparison.testType$

    @emlCSVInit

    if .nGroups = 2
        # 2-group: extract descriptives, route to TwoGroupComparison
        # Read the labels the bridge captured, not emlCountGroups' outputs:
        # @emlCountGroups is re-invoked by the tests the bridge runs, so its
        # outputs no longer belong to this comparison by the time we get here.
        .g1$ = emlBridgeGroupComparison.gLabel$ [1]
        .g2$ = emlBridgeGroupComparison.gLabel$ [2]

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

    elsif .testType$ = "parametric"
        # k-group parametric: ANOVA (bridge ran with doTukey=1)
        @emlReportAnovaComparison: .tableName$, .dataCol$, .groupCol$,
        ... .tableId, .nGroups, 1

    else
        # k-group nonparametric: Kruskal-Wallis
        # Bridge runs Dunn's only when p < alpha
        if emlKruskalWallis.p < emlBridgeGroupComparison.alpha
            .doDunn = 1
        else
            .doDunn = 0
        endif
        @emlReportKWComparison: .tableName$, .dataCol$, .groupCol$,
        ... .tableId, .nGroups, .doDunn
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
# results to file. (This used to name @emlCSVAddRow, which has never existed
# in the plugin — nothing by that name is defined anywhere.)
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

    if .testType$ = "parametric" or .testType$ = "both"
        @emlFormatEffectLabel: emlCohenD.d, "d"
        @emlReportBlank
        @emlReportSection: emlTTest.method$
        if emlShowExplanations
            if emlTTest.method$ = "Welch"
                appendInfoLine: "  Why: Compares means of two independent "
                ... + "groups (robust to unequal variances)."
            else
                appendInfoLine: "  Why: Compares means of two independent "
                ... + "groups (assumes equal variances)."
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
        ; D9: the row label used to be "p" and the value "p = .032", so the
        ; report said "p" twice. D28/D35: the < .001 floor also hid the real
        ; value. @emlReportPWithExact prints the bare APA form and, when the
        ; label is floored, the unrounded value beside it.
        @emlReportPWithExact: "p", emlTTest.p
        if emlShowExplanations
            .diff = .mean1 - .mean2
            if .diff > 0
                emlWizardExplain$ = .displayG1$ + " mean is " + fixed$ (abs (.diff), 2) + " units higher"
            else
                emlWizardExplain$ = .displayG2$ + " mean is " + fixed$ (abs (.diff), 2) + " units higher"
            endif
        endif
        ; D13: "Mean difference" alone never said which group was subtracted
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
        ; D12: @emlTTest exposes no interval, so it is rebuilt here from the
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
            .seDiff = abs (emlTTest.meanDiff / emlTTest.t)
            .tCritDiff = invStudentQ (0.025, emlTTest.df)
            .diffLo = emlTTest.meanDiff - .tCritDiff * .seDiff
            .diffHi = emlTTest.meanDiff + .tCritDiff * .seDiff
            @emlReportLineString: "95% CI of diff",
            ... "[" + fixed$ (.diffLo, 4) + ", " + fixed$ (.diffHi, 4) + "]"
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
        @emlReportLineString: "Magnitude", emlFormatEffectLabel.label$
        # D24/D19: named fields, and an absent value writes no row.
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
            appendInfoLine: "  Why: Compares distributions of two "
            ... + "independent groups without assuming normality."
        endif
        if emlShowExplanations
            emlWizardExplain$ = "Sum of ranks: measures how much one group's values tend to exceed the other's"
        endif
        @emlReportLine: "U1", emlMannWhitneyU.u1, 1
        @emlReportLine: "U2", emlMannWhitneyU.u2, 1
        if emlMannWhitneyU.z <> undefined
            @emlReportLine: "z", emlMannWhitneyU.z, 3
        endif
        if emlShowExplanations
            @emlWizardExplainP: emlMannWhitneyU.p
        endif
        ; D9/D28
        @emlReportPWithExact: "p", emlMannWhitneyU.p
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
        @emlReportLineString: "Method", .mwuMethod$
        @emlReportBlank
        @emlReportSection: "Nonparametric Effect Size"
        if emlShowExplanations
            @emlWizardExplainEffectR: emlRankBiserialR.r
        endif
        @emlReportLine: "Rank-biserial r", emlRankBiserialR.r, 3
        @emlReportLineString: "Magnitude", emlFormatEffectLabel.label$
        if emlMannWhitneyU.z <> undefined
            .mwuDf = emlMannWhitneyU.z
        else
            .mwuDf = 0
        endif
        # D24: the Mann-Whitney has no df at all, so no df row is written
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

    # ANOVA table
    @emlReportBlank
    @emlReportSection: "ANOVA Table"
    if emlShowExplanations
        appendInfoLine: "  Why: Tests whether group means differ "
        ... + "when normality and equal variances hold."
    endif
    appendInfoLine: ""
    appendInfoLine: left$ ("Source" + "                    ", 20),
    ... left$ ("SS" + "                ", 16),
    ... left$ ("df" + "      ", 6),
    ... left$ ("MS" + "                ", 16),
    ... left$ ("F" + "            ", 12),
    ... "p"

    # D110. This cell was fixed$ (p, 6): "0.000019" under a column headed "p",
    # in the same report whose Games-Howell matrix prints the bare APA form
    # (".584") — one report, two spellings of the same quantity. It now takes
    # @emlFormatP's bare form, which is the shape the two-way source table
    # already uses (D35) and the direction D9/D28 established: no leading
    # zero, floored at .001. Nothing is lost by the floor here — the "p" row
    # printed a few lines below goes through @emlReportPWithExact, which
    # restates the unrounded value in parentheses whenever the floor bites.
    @emlFormatP: emlOneWayAnova.p
    .pCell$ = emlFormatP.bare$

    appendInfoLine: left$ ("Between" + "                    ", 20),
    ... left$ (fixed$ (emlOneWayAnova.ssBetween, 2) + "                ", 16),
    ... left$ (string$ (emlOneWayAnova.dfBetween) + "      ", 6),
    ... left$ (fixed$ (emlOneWayAnova.msBetween, 2) + "                ", 16),
    ... left$ (fixed$ (emlOneWayAnova.fValue, 4) + "            ", 12),
    ... .pCell$
    appendInfoLine: left$ ("Within" + "                    ", 20),
    ... left$ (fixed$ (emlOneWayAnova.ssWithin, 2) + "                ", 16),
    ... left$ (string$ (emlOneWayAnova.dfWithin) + "      ", 6),
    ... left$ (fixed$ (emlOneWayAnova.msWithin, 2) + "                ", 16)
    appendInfoLine: left$ ("Total" + "                    ", 20),
    ... left$ (fixed$ (emlOneWayAnova.ssTotal, 2) + "                ", 16),
    ... left$ (string$ (emlOneWayAnova.dfTotal) + "      ", 6)

    @emlReportBlank
    if emlShowExplanations
        @emlWizardExplainF: emlOneWayAnova.fValue
    endif
    @emlReportLineString: "F", fixed$ (emlOneWayAnova.fValue, 4)
    if emlShowExplanations
        @emlWizardExplainP: emlOneWayAnova.p
    endif
    ; D9/D28
    @emlReportPWithExact: "p", emlOneWayAnova.p
    .etaSq = emlOneWayAnova.etaSquared
    if emlShowExplanations
        @emlWizardExplainEffectEta2: .etaSq
    endif
    @emlReportLineString: "Effect size", "eta-squared = " + fixed$ (.etaSq, 4)

    ; --- Equal-spread check (Ruling 1: conditional show-both) ---------------
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
            appendInfoLine: "  Why: The ANOVA above pools one within-group "
            ... + "spread across all groups. This checks whether that is a "
            ... + "fair thing to do here."
        endif
        @emlReportLineString: "Equal spread",
        ... "Brown-Forsythe F(" + string$ (emlBrownForsythe.df1) + ", "
        ... + string$ (emlBrownForsythe.df2) + ") = "
        ... + fixed$ (emlBrownForsythe.f, 4)
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
    # D24: this row used to end in eight zeros meaning "not applicable".
    # D23/D76: both df now have their own field, so F(2,42) survives export.
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
        appendInfoLine: ""
        .headerLine$ = left$ ("" + "                ", 14)
        for .jGroup from 1 to .nGroups
            .colName$ = replace$ (emlOneWayAnova.groupLabel$[.jGroup], "_", " ", 0)
            if length (.colName$) > 10
                .colName$ = left$ (.colName$, 10)
            endif
            .headerLine$ = .headerLine$ + left$ (.colName$ + "            ", 12)
        endfor
        appendInfoLine: .headerLine$
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
                    ; D110. Was a hand-rolled floor plus fixed$ (p, 4), so
                    ; this matrix printed "0.4918" while the Games-Howell
                    ; matrix 35 lines below printed ".584" — the same
                    ; quantity, two formats, visible together in one report.
                    ; @emlFormatP is the single spelling: no leading zero,
                    ; the .001 floor, and the .999 ceiling and the undefined
                    ; case that the hand-rolled branch did not cover (an
                    ; undefined p fell through to fixed$ and rendered as
                    ; "--undefined--").
                    .pVal = emlOneWayAnova.pMatrix## [.iGroup, .jGroup]
                    @emlFormatP: .pVal
                    .cellText$ = emlFormatP.bare$
                endif
                .rowLine$ = .rowLine$ + left$ (.cellText$ + "            ", 12)
            endfor
            appendInfoLine: .rowLine$
        endfor

        # D22: the matrix above reports adjusted p and nothing else, so a
        # reader cannot state a result — the quantity a result is stated in is
        # the mean difference and its interval. No new numerics are needed:
        # @emlOneWayAnova already exposes the signed differences, the critical
        # q at alpha = .05, MS_within and the group sizes, so the family-wise
        # half-width is qCritical * sqrt(MSw/2 * (1/ni + 1/nj)).
        @emlReportBlank
        @emlReportSection: "Tukey HSD Mean Differences (95% family-wise CI)"
        appendInfoLine: ""
        appendInfoLine: left$ ("Comparison" + "                          ", 26),
        ... left$ ("Difference" + "              ", 14),
        ... "95% CI"
        for .iGroup from 1 to .nGroups - 1
            for .jGroup from .iGroup + 1 to .nGroups
                .ciName$ = replace$ (emlOneWayAnova.groupLabel$[.iGroup], "_", " ", 0)
                ... + " − "
                ... + replace$ (emlOneWayAnova.groupLabel$[.jGroup], "_", " ", 0)
                if length (.ciName$) > 24
                    .ciName$ = left$ (.ciName$, 24)
                endif
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
                    .ciText$ = "[" + fixed$ (.tukeyDiff - .tukeyHalf, 4)
                    ... + ", " + fixed$ (.tukeyDiff + .tukeyHalf, 4) + "]"
                endif
                appendInfoLine: left$ (.ciName$ + "                          ", 26),
                ... left$ (fixed$ (.tukeyDiff, 4) + "              ", 14),
                ... .ciText$
            endfor
        endfor

        # CSV rows for Tukey pairwise
        for .iGroup from 1 to .nGroups - 1
            for .jGroup from .iGroup + 1 to .nGroups
                .pVal = emlOneWayAnova.pMatrix## [.iGroup, .jGroup]
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
                endif
            endfor
        endfor
    endif
    @emlReportBlank
    @emlReportSection: "Pairwise Effect Sizes (Cohen's d)"
    appendInfoLine: ""
    .dHeaderLine$ = left$ ("" + "                ", 14)
    for .jGroup from 1 to .nGroups
        .colName$ = replace$ (emlOneWayAnova.groupLabel$[.jGroup], "_", " ", 0)
        if length (.colName$) > 10
            .colName$ = left$ (.colName$, 10)
        endif
        .dHeaderLine$ = .dHeaderLine$ + left$ (.colName$ + "            ", 12)
    endfor
    appendInfoLine: .dHeaderLine$
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
                .cellText$ = fixed$ (.dVal, 3)
            endif
            .dRowLine$ = .dRowLine$ + left$ (.cellText$ + "            ", 12)
        endfor
        appendInfoLine: .dRowLine$
    endfor

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
                # D24 at its worst: this branch has no test statistic and
                # no p, and used to write 0, 0, 0 — so the row read as the
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
    ; Ruling 1: never replace, never auto-switch, never make the reported
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
        ... + "shared error term. Where these agree with the block above, "
        ... + "the unequal spread did not change the conclusion. Where they "
        ... + "disagree, prefer these -- that is what they are for."

        @emlWelchAnova: .tableId, .dataCol$, .groupCol$
        if emlWelchAnova.error$ <> ""
            @emlReportLineString: "Welch's F",
            ... "not available -- " + emlWelchAnova.error$
        else
            @emlReportBlank
            @emlReportLineString: "Welch's F",
            ... "F(" + string$ (emlWelchAnova.df1) + ", "
            ... + fixed$ (emlWelchAnova.df2, 2) + ") = "
            ... + fixed$ (emlWelchAnova.f, 4)
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
                appendInfoLine: ""
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
                appendInfoLine: .ghHeader$
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
                            .ghP = emlGamesHowell.pMatrix## [.iGroup, .jGroup]
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
                    appendInfoLine: .ghLine$
                endfor

                for .iGroup from 1 to .nGroups - 1
                    for .jGroup from .iGroup + 1 to .nGroups
                        .ghP = emlGamesHowell.pMatrix## [.iGroup, .jGroup]
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

    @emlReportBlank
    @emlReportSection: "Omnibus Test"
    if emlShowExplanations
        appendInfoLine: "  Why: Nonparametric comparison of three or "
        ... + "more groups — no normality assumption needed."
    endif
    if emlShowExplanations
        emlWizardExplain$ = "Test statistic: measures rank dispersion across groups (chi-squared distributed)"
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
    ; D28: the omnibus p was floored to "p = .003" with the real value
    ; reachable only from the CSV, and the label was printed twice (D9).
    @emlReportPWithExact: "p", emlKruskalWallis.p
    if emlShowExplanations
        @emlWizardExplainEffectEta2: emlKruskalWallis.epsilonSq
    endif
    @emlReportLine: "Epsilon-squared", emlKruskalWallis.epsilonSq, 4
    @emlFormatEffectLabel: emlKruskalWallis.epsilonSq, "eta_squared"
    @emlReportLineString: "Effect magnitude", emlFormatEffectLabel.label$

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
    appendInfoLine: ""
    .grpHeader$ = left$ ("Group" + "                ", 14)
    ... + left$ ("N" + "      ", 6) + "Mean Rank"
    appendInfoLine: .grpHeader$
    for .iGroup from 1 to .nGroups
        .gName$ = replace$ (emlKruskalWallis.groupName$ [.iGroup], "_", " ", 0)
        if length (.gName$) > 12
            .gName$ = left$ (.gName$, 12)
        endif
        appendInfoLine: left$ (.gName$ + "                ", 14),
        ... left$ (string$ (emlKruskalWallis.groupN [.iGroup]) + "      ", 6),
        ... fixed$ (emlKruskalWallis.meanRank [.iGroup], 2)
    endfor

    if .doDunn
        if emlDunnTest.error$ = ""
            .adjLabel$ = emlDunnTest.method$
            @emlReportBlank
            @emlReportSection: "Dunn's Post-Hoc (adjusted p, " + .adjLabel$ + ")"
            appendInfoLine: ""
            .headerLine$ = left$ ("" + "                ", 14)
            for .jGroup from 1 to .nGroups
                .colName$ = replace$ (emlDunnTest.groupName$ [.jGroup], "_", " ", 0)
                if length (.colName$) > 10
                    .colName$ = left$ (.colName$, 10)
                endif
                .headerLine$ = .headerLine$ + left$ (.colName$ + "            ", 12)
            endfor
            appendInfoLine: .headerLine$
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
                        ; D110, as in the Tukey matrix above: one spelling of
                        ; a p-value per report. @emlFormatP also covers the
                        ; .999 ceiling and undefined, which the hand-rolled
                        ; floor did not.
                        .pVal = emlDunnTest.pMatrix## [.iGroup, .jGroup]
                        @emlFormatP: .pVal
                        .cellText$ = emlFormatP.bare$
                    endif
                    .rowLine$ = .rowLine$ + left$ (.cellText$ + "            ", 12)
                endfor
                appendInfoLine: .rowLine$
            endfor

            @emlReportBlank
            @emlReportSection: "Dunn's z-statistics"
            appendInfoLine: ""
            appendInfoLine: .headerLine$
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
                        .cellText$ = fixed$ (.zVal, 3)
                    endif
                    .rowLine$ = .rowLine$ + left$ (.cellText$ + "            ", 12)
                endfor
                appendInfoLine: .rowLine$
            endfor

            # CSV rows — per-pair descriptives + rank-biserial r
            for .iGroup from 1 to .nGroups - 1
                for .jGroup from .iGroup + 1 to .nGroups
                    .pVal = emlDunnTest.pMatrix## [.iGroup, .jGroup]
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
                    # D24: Dunn's z has no df; the zero is gone, not
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
        else
            appendInfoLine: newline$ + "Dunn's test error: " + emlDunnTest.error$
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
                endif
            endfor
        endfor
    endif
    @emlReportBlank
    @emlReportSection: "Pairwise Effect Sizes (rank-biserial r)"
    appendInfoLine: ""
    .rHeaderLine$ = left$ ("" + "                ", 14)
    for .jGroup from 1 to .nGroups
        .colName$ = replace$ (emlKruskalWallis.groupName$ [.jGroup], "_", " ", 0)
        if length (.colName$) > 10
            .colName$ = left$ (.colName$, 10)
        endif
        .rHeaderLine$ = .rHeaderLine$ + left$ (.colName$ + "            ", 12)
    endfor
    appendInfoLine: .rHeaderLine$
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
                .cellText$ = fixed$ (.rVal, 3)
            endif
            .rRowLine$ = .rRowLine$ + left$ (.cellText$ + "            ", 12)
        endfor
        appendInfoLine: .rRowLine$
    endfor

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
            ; D44: R-squared used to sit inside the explanations gate, so the
            ; Info window omitted the one number most correlation write-ups
            ; quote while the scatter figure from the same run annotated it.
            ; R-squared is a statistic, not an explanation — only the prose
            ; gloss is gated now.
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
            ; D9/D28
            @emlReportPWithExact: "p", emlPearsonCorrelation.p
            # D50: r was reported as a point estimate with no interval. The
            # Fisher z transform gives one from numbers already in hand:
            # z = atanh(r), se = 1/sqrt(n-3), interval = tanh(z +/- 1.96 se).
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
                .fisherZ = 0.5 * ln ((1 + .rPearson) / (1 - .rPearson))
                .fisherSE = 1 / sqrt (.n - 3)
                .zLo = .fisherZ - 1.96 * .fisherSE
                .zHi = .fisherZ + 1.96 * .fisherSE
                .rLo = (exp (2 * .zLo) - 1) / (exp (2 * .zLo) + 1)
                .rHi = (exp (2 * .zHi) - 1) / (exp (2 * .zHi) + 1)
                @emlReportLineString: "95% CI for r",
                ... "[" + fixed$ (.rLo, 4) + ", " + fixed$ (.rHi, 4) + "]"
            endif
            # D17: the row carried r and r_squared but left effect_label
            # empty, so a consumer joining these exports got a column that is
            # populated for the group comparisons and blank here.
            @emlFormatEffectLabel: abs (.rPearson), "r"
            .pearsonLabel$ = emlFormatEffectLabel.label$
            @emlReportLineString: "Magnitude", .pearsonLabel$
            # D45: colY$ used to land in the group_col slot, so the file
            # said the Y variable was a grouping column. Both variables now
            # have their own named field. D46: the six descriptive slots
            # were exported as 0 though both columns' descriptives exist —
            # they are simply not written here, and the term names which
            # pair the row is about.
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
            ; D9/D28
            @emlReportPWithExact: "p", emlSpearmanCorrelation.p
            # D17: rho is an effect size and had no magnitude gloss in the
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
    .eqn$ = "y = "
    ... + fixed$ (emlLinearRegression.slope, 4) + "x"
    ... + " + " + fixed$ (emlLinearRegression.intercept, 4)
    @emlReportLineString: "Equation", .eqn$
    if emlShowExplanations
        .proseEqn$ = .displayDep$ + " = "
        ... + fixed$ (emlLinearRegression.slope, 4) + " x " + .displayPred$
        ... + " + " + fixed$ (emlLinearRegression.intercept, 4)
        emlWizardExplain$ = .proseEqn$
        appendInfoLine: "  " + emlWizardExplain$
    endif
    if emlShowExplanations
        @emlWizardExplainCorrelation: emlLinearRegression.r
    endif
    @emlReportLine: "R", abs (emlLinearRegression.r), 4
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
        emlWizardExplain$ = "Typical prediction error — points deviate from the line by +/-"
        ... + fixed$ (emlLinearRegression.seResidual, 2) + " units on average"
    endif
    @emlReportLine: "Residual SE", emlLinearRegression.seResidual, 4

    @emlReportBlank
    @emlReportSection: "Overall Model Test (F)"
    .dfLabel$ = "F(" + string$ (emlLinearRegression.dfReg)
    ... + "," + string$ (emlLinearRegression.dfRes) + ")"
    if emlShowExplanations
        emlWizardExplain$ = "Overall model significance — ratio of explained to unexplained variance"
    endif
    @emlReportLine: .dfLabel$, emlLinearRegression.fStat, 4
    if emlShowExplanations
        @emlWizardExplainP: emlLinearRegression.pF
    endif
    ; D9/D28
    @emlReportPWithExact: "p", emlLinearRegression.pF

    @emlReportBlank
    @emlReportSection: "Coefficients"
    appendInfoLine: ""
    # D56: the block was flush-left inside a report whose every other block is
    # indented two spaces, the term column had no header at all, and the cells
    # under the numeric-aligned "p" header held the string "p < .001". The
    # block is now indented, the term column is headed, and the cells carry
    # @emlFormatP's bare form so the column contains values, not labels.
    # D57: SE was printed without the interval it defines. dfRes and the two
    # standard errors are already on screen, so the 95% CI is one t quantile
    # away and is printed beside each coefficient.
    .ciWidth = 0
    if emlLinearRegression.dfRes <> undefined
        if emlLinearRegression.dfRes >= 1
            .ciWidth = invStudentQ (0.025, emlLinearRegression.dfRes)
        endif
    endif
    .hdr$ = "  " + left$ ("Term" + "                    ", 20)
    ... + left$ ("Estimate" + "              ", 14)
    ... + left$ ("SE" + "              ", 14)
    ... + left$ ("t" + "              ", 12)
    ... + left$ ("p" + "            ", 12)
    ... + "95% CI"
    appendInfoLine: .hdr$
    # Intercept row
    @emlFormatP: emlLinearRegression.pIntercept
    if .ciWidth > 0
        .intHalf = .ciWidth * emlLinearRegression.seIntercept
        .intCI$ = "[" + fixed$ (emlLinearRegression.intercept - .intHalf, 4)
        ... + ", " + fixed$ (emlLinearRegression.intercept + .intHalf, 4) + "]"
    else
        .intCI$ = "not available"
    endif
    .intRow$ = "  " + left$ ("(Intercept)" + "                    ", 20)
    ... + left$ (fixed$ (emlLinearRegression.intercept, 4) + "              ", 14)
    ... + left$ (fixed$ (emlLinearRegression.seIntercept, 4) + "              ", 14)
    ... + left$ (fixed$ (emlLinearRegression.tIntercept, 3) + "              ", 12)
    ... + left$ (emlFormatP.bare$ + "            ", 12)
    ... + .intCI$
    appendInfoLine: .intRow$
    # Slope row
    @emlFormatP: emlLinearRegression.pSlope
    if .ciWidth > 0
        .slopeHalf = .ciWidth * emlLinearRegression.seSlope
        .slopeCI$ = "[" + fixed$ (emlLinearRegression.slope - .slopeHalf, 4)
        ... + ", " + fixed$ (emlLinearRegression.slope + .slopeHalf, 4) + "]"
    else
        .slopeCI$ = "not available"
    endif
    .slopeRow$ = "  " + left$ (.displayPred$ + "                    ", 20)
    ... + left$ (fixed$ (emlLinearRegression.slope, 4) + "              ", 14)
    ... + left$ (fixed$ (emlLinearRegression.seSlope, 4) + "              ", 14)
    ... + left$ (fixed$ (emlLinearRegression.tSlope, 3) + "              ", 12)
    ... + left$ (emlFormatP.bare$ + "            ", 12)
    ... + .slopeCI$
    appendInfoLine: .slopeRow$

    # Direction and magnitude
    @emlReportBlank
    if emlLinearRegression.slope > 0
        .dir$ = "positive"
        .verb$ = "increases"
    else
        .dir$ = "negative"
        .verb$ = "decreases"
    endif
    @emlFormatEffectLabel: emlLinearRegression.rSquared, "r_squared"
    appendInfoLine: "  Direction: " + .dir$
    ... + " (" + .displayDep$ + " " + .verb$
    ... + " as " + .displayPred$ + " increases)"
    # D62: this printed as "Variance explained   large effect" in the same
    # label/value layout as "R-squared   0.8770", so a Cohen benchmark verdict
    # wore the visual authority of a second computed statistic — and read as a
    # different quantity from R-squared when it is R-squared, glossed. Stated
    # as prose naming the number it is a verdict about.
    appendInfoLine: "  Variance explained: R-squared = "
    ... + fixed$ (emlLinearRegression.rSquared, 4)
    ... + " ("
    ... + fixed$ (100 * emlLinearRegression.rSquared, 1)
    ... + "% of the variance in " + .displayDep$
    ... + "), a " + emlFormatEffectLabel.label$
    ... + " by Cohen's R-squared benchmarks"

    # D54 was the clearest case of slot reuse in the whole schema: the
    # slope went into mean1, the slope's SE into sd1, the intercept into
    # median1, its SE into mean2 and R into sd2. A reader taking a column
    # mean over mean1 was averaging slopes with group means. D55: the
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
    # D57: the interval the report now prints is exported alongside it.
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
    # D4 relabelled the other three print sites and missed this one.
    @emlReportLine: "Kurtosis (excess)", emlRunNormalityAnalysis.kurtosis, 4

    # These two verdicts must use the SAME thresholds as the recommendation
    # gate in @emlRunNormalityAnalysis (stats/eml-analysis.praat), which reads
    # emlSkewThreshold and emlKurtosisThreshold — set in stats/eml-output.praat
    # to 2 and 7. These lines previously hard-coded 1 and 3. Against a gate at
    # 2 and 7 that is stricter, not looser, so the contradiction ran this way:
    # a g2 of 4 printed "Kurtosis outside typical limits" here while the gate,
    # for which 4 is well inside 7, went on to recommend a parametric test —
    # two contradictory verdicts in one report. A skewness of 1.5 did the same
    # against the old 1. (D95)
    # D11: the parenthetical used to read "(|skew| < 1)" on the FAILING branch
    # only — an assertion of the criterion at the moment it is announcing the
    # opposite, and invisible to the reader who passes. The parenthetical is
    # now worded as a stated criterion ("criterion: ...") and printed on BOTH
    # branches, so a passing reader learns what threshold was cleared.
    # The same two thresholds are announced in scripts/eml-wizard.praat, in
    # the .skKurtFail branch of its normality summary — currently :2170-2175.
    # Not fixed here because that file is owned elsewhere. (The pointer used
    # to read :2085, which is a "Data column:" padding line in the analysis
    # plan; grep for skKurtFail, the line numbers move on every insertion.)
    if abs (emlRunNormalityAnalysis.skewness) >= emlSkewThreshold
        appendInfoLine: "  → Skewness outside typical limits (criterion: |skew| < ",
        ... fixed$ (emlSkewThreshold, 0), ")"
    else
        appendInfoLine: "  → Skewness within typical limits (criterion: |skew| < ",
        ... fixed$ (emlSkewThreshold, 0), ")"
    endif
    if abs (emlRunNormalityAnalysis.kurtosis) >= emlKurtosisThreshold
        appendInfoLine: "  → Kurtosis outside typical limits (criterion: |excess kurt| < ",
        ... fixed$ (emlKurtosisThreshold, 0), ")"
    else
        appendInfoLine: "  → Kurtosis within typical limits (criterion: |excess kurt| < ",
        ... fixed$ (emlKurtosisThreshold, 0), ")"
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
        ; D9/D28. Shapiro-Wilk has no effect size, so no magnitude row
        ; belongs here and none is added (D17).
        @emlReportPWithExact: "p", emlRunNormalityAnalysis.swP
        if emlRunNormalityAnalysis.swFail
            appendInfoLine: "  → Rejects normality (p < 0.05)"
        else
            appendInfoLine: "  → Does not reject normality (p >= 0.05)"
        endif
    else
        @emlReportLineString: "Error", emlRunNormalityAnalysis.swError$
    endif

    @emlReportBlank
    @emlReportSection: "Recommendation"
    if emlRunNormalityAnalysis.recommendation$ = "parametric"
        if emlRunNormalityAnalysis.largeNOverride = 1
            appendInfoLine: "  Shapiro-Wilk rejects normality, but with n = "
            ... + string$ (emlRunNormalityAnalysis.nValid)
            ... + " the departure"
            appendInfoLine: "  is statistically detectable but practically"
            ... + " negligible"
            appendInfoLine: "  (skewness and kurtosis within acceptable"
            ... + " limits)."
            appendInfoLine: "  → Parametric tests are robust at this sample"
            ... + " size."
        else
            appendInfoLine: "  Normality appears reasonable."
            appendInfoLine: "  → Parametric tests (t-test, ANOVA, Pearson r)"
            ... + " are appropriate."
        endif
    else
        appendInfoLine: "  Evidence against normality."
        appendInfoLine: "  → Consider nonparametric tests (Mann-Whitney,"
        ... + " Kruskal-Wallis, Spearman rho)."
    endif

    # D24: skewness and kurtosis were being carried in the mean2/sd2 slots
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

    appendInfoLine: "  ", .displayC1$, ": Mean = ", fixed$ (.mean1, 3),
    ... ", SD = ", fixed$ (.sd1, 3),
    ... ", Median = ", fixed$ (.median1, 3)
    appendInfoLine: "  ", .displayC2$, ": Mean = ", fixed$ (.mean2, 3),
    ... ", SD = ", fixed$ (.sd2, 3),
    ... ", Median = ", fixed$ (.median2, 3)

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
            ; D9/D28
            @emlReportPWithExact: "p", emlTTestPaired.p
            @emlReportLine: "Mean difference", emlTTestPaired.meanDiff, 4
            @emlReportLine: "SD of differences", emlTTestPaired.sdDiff, 4

            # The effect size under the t-test is the one derived from the
            # same quantity the t is derived from. The matched-pairs rank
            # statistic belongs to the Wilcoxon and is reported in that
            # section, not here (D15).
            # D17: the magnitude was printed here but never reached the
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

            # D19: the two column names used to be packed into all four
            # level slots and n written twice, so a paired design was
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
            ; D9/D28
            @emlReportPWithExact: "p", emlWilcoxonSignedRank.p

            # D17: the matched-pairs magnitude was printed and then dropped on
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
    # D37: the Info block named the table, the column and the two factors and
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

    # D35: all three rows printed @emlFormatP's "p = " form under a column
    # already headed "p" (D9 in table form), and all three floored to
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

    appendInfoLine: left$ (.displayF1$ + "                    ", 20),
    ... left$ (fixed$ (emlTwoWayAnova.ssA, 2) + "                ", 16),
    ... left$ (string$ (emlTwoWayAnova.dfA) + "      ", 6),
    ... left$ (fixed$ (emlTwoWayAnova.msA, 2) + "                ", 16),
    ... left$ (fixed$ (emlTwoWayAnova.fA, 4) + "            ", 12),
    ... .pCellA$

    appendInfoLine: left$ (.displayF2$ + "                    ", 20),
    ... left$ (fixed$ (emlTwoWayAnova.ssB, 2) + "                ", 16),
    ... left$ (string$ (emlTwoWayAnova.dfB) + "      ", 6),
    ... left$ (fixed$ (emlTwoWayAnova.msB, 2) + "                ", 16),
    ... left$ (fixed$ (emlTwoWayAnova.fB, 4) + "            ", 12),
    ... .pCellB$

    .interLabel$ = .displayF1$ + " x " + .displayF2$
    .rawInterLabel$ = .factor1$ + "_x_" + .factor2$
    appendInfoLine: left$ (.interLabel$ + "                    ", 20),
    ... left$ (fixed$ (emlTwoWayAnova.ssAB, 2) + "                ", 16),
    ... left$ (string$ (emlTwoWayAnova.dfAB) + "      ", 6),
    ... left$ (fixed$ (emlTwoWayAnova.msAB, 2) + "                ", 16),
    ... left$ (fixed$ (emlTwoWayAnova.fAB, 4) + "            ", 12),
    ... .pCellAB$

    appendInfoLine: left$ ("Error" + "                    ", 20),
    ... left$ (fixed$ (emlTwoWayAnova.ssError, 2) + "                ", 16),
    ... left$ (string$ (emlTwoWayAnova.dfError) + "      ", 6),
    ... left$ (fixed$ (emlTwoWayAnova.msError, 2) + "                ", 16)

    appendInfoLine: left$ ("Total" + "                    ", 20),
    ... left$ (fixed$ (emlTwoWayAnova.ssTotal, 2) + "                ", 16),
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
    ; "warning" line, ~:3118) and printed NOWHERE, so a user reading the
    ; report never saw it and only a user who exported the CSV ever did.
    ; (The pointer used to read :2961, which is now inside
    ; @emlDeclareKWResult; grep the anchor, the line numbers move.)
    ; Placed immediately under the table it qualifies, following the D98
    ; ruling on caveat placement: a caveat below the effect sizes reads as
    ; being about the effect sizes.
    if emlTwoWayAnova.warning$ <> ""
        @emlReportBlank
        @emlReportNote: "Caution: " + emlTwoWayAnova.warning$
    endif

    ; A significant interaction qualifies both main effects: it says the
    ; effect of each factor DEPENDS on the level of the other, so a single
    ; main-effect F averaged across that dependence can be misleading on its
    ; own. Precedent for the wording and the placement is the RM-ANOVA
    ; caution in @emlRunRepeatedMeasuresAnalysis (eml-analysis.praat, the
    ; `emlRMAnovaTest.warning$` block, ~:2354). (The pointer used to read
    ; :2194, which is @emlRMAnovaTest's own .msErr arithmetic; grep the
    ; anchor, the line numbers move.)
    if emlTwoWayAnova.pAB < 0.05
        @emlReportBlank
        @emlReportNote: "Caution: the interaction is significant, so the "
        ... + "two main-effect rows above are averages taken across a "
        ... + "difference that is itself real. Each factor's effect depends "
        ... + "on the level of the other, and reporting either main effect "
        ... + "on its own will understate that. Read the cell means below "
        ... + "before reading the main effects."
    endif

    # Effect sizes
    # D41: the three partial eta-squareds were printed bare, with no
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
        @emlWizardExplainEffectEta2: emlTwoWayAnova.partialEtaSqA
    endif
    .etaTextA$ = fixed$ (emlTwoWayAnova.partialEtaSqA, 4)
    if .etaLabelA$ <> ""
        .etaTextA$ = .etaTextA$ + "  (" + .etaLabelA$ + ")"
    endif
    @emlReportLineString: .displayF1$, .etaTextA$
    if emlShowExplanations
        @emlWizardExplainEffectEta2: emlTwoWayAnova.partialEtaSqB
    endif
    .etaTextB$ = fixed$ (emlTwoWayAnova.partialEtaSqB, 4)
    if .etaLabelB$ <> ""
        .etaTextB$ = .etaTextB$ + "  (" + .etaLabelB$ + ")"
    endif
    @emlReportLineString: .displayF2$, .etaTextB$
    if emlShowExplanations
        @emlWizardExplainEffectEta2: emlTwoWayAnova.partialEtaSqAB
    endif
    .etaTextAB$ = fixed$ (emlTwoWayAnova.partialEtaSqAB, 4)
    if .etaLabelAB$ <> ""
        .etaTextAB$ = .etaTextAB$ + "  (" + .etaLabelAB$ + ")"
    endif
    @emlReportLineString: .interLabel$, .etaTextAB$

    # D36: the block went ANOVA table → partial eta-squared → CSV → footer
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
                    .cellMeanText$ = fixed$ (emlTwoWayAnova.cellMean[.hit], 4)
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
                .margText$ = fixed$ (.margSum / .margN, 4)
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
                .margText$ = fixed$ (.margSum / .margN, 4)
            else
                .margText$ = "no data"
            endif
            appendInfoLine: left$ (.margLabel$ + "                            ", 30),
            ... left$ (string$ (.margN) + "        ", 8),
            ... .margText$
        endfor
    endif

    # CSV rows — one per effect
    # D34: there was no denominator df, no SS and no MS, so F(1,28)
    # exported as df=1.00 and the ANOVA table could not be reconstructed
    # from the file. Every term now carries both df, its SS and its MS, and
    # the error and total rows are exported too.
    #
    # The two claims that used to stand here were both false when written.
    # D37 was recorded as fixed by the n/n_cells fields below, but the Info
    # window still reported no N at all — that is fixed above, where the
    # header block now prints total N, cell count and per-cell n. D41 was
    # recorded as fixed, but all three factor rows still emitted
    # partial_eta_squared with no effect_label beside it — the labels are
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
