# ============================================================================
# EML GRAPHS — STANDARD DRAWING PROCEDURES
# ============================================================================
# Author: Ian Howell, Embodied Music Lab, www.embodiedmusiclab.com
# Development: Claude (Anthropic)
# License: GPL-3.0-or-later
# Version: 3.22
# Date: 2 August 2026
#
# v3.22: Undefined/validation hardening (audit items 1-3).
#        (1) @emlCheckNumericColumn no longer samples the first 5 rows and
#            no longer passes a column on a single parseable cell. It scans
#            the whole column (capped at .maxScanRows), requires EVERY
#            non-empty cell to be a strict numeric literal, treats
#            empty/whitespace cells as missing rather than failures, and
#            reports .nNumeric/.nMissing/.nCoerced/.nNonNumeric plus the
#            first offending row and its literal text. Cells that only pass
#            via number() coercion ("5,5", "30%", "1/2", "0x10", "2 3") are
#            classified as coerced and REJECTED — a silent wrong number is
#            worse than a rejected column. Parameter list and .isNumeric
#            output name/meaning are unchanged.
#        (2) @emlMeasureBarData no longer crashes on undefined values.
#            Undefined observations and undefined custom-error values are
#            skipped and counted; means, SE/SD and the visible min/max fold
#            are guarded with explicit "<> undefined" tests; single-
#            observation groups are handled explicitly (no undefined error
#            bar). emlBarData_mean[] and emlBarData_error[] are now
#            guaranteed defined on return, so nothing undefined can reach a
#            drawing command. New disclosure globals: emlBarData_valid[],
#            emlBarData_errorDefined[], emlBarData_skipped[],
#            emlBarData_errSkipped[], emlBarData_nSkipped,
#            emlBarData_nErrSkipped, emlBarData_nInvalidGroups,
#            emlBarData_nSingleObs, emlBarData_nUnmatchedRows.
#        (3) Swept the file for the same two patterns. Fixed:
#            @emlComputeAxisRange, @emlComputeNiceStep,
#            @emlSetAlphaDotGeometry (relational "guards" that are FALSE for
#            undefined and therefore let undefined through to Axes:/
#            Paint circle:), and @emlDrawViolin, @emlDrawBox,
#            @emlDrawJitteredPoints (undefined observations reaching
#            Draw line:/Paint rectangle:, or silently suppressing the whole
#            glyph). @emlCheckPlausibility was already correct.
# v3.21: Graph correctness fixes. (1) Box/violin quartiles now use the
#        shared R-7 interpolated @emlQuartiles instead of nearest-rank
#        floor(n*p), which biased the median low and collapsed it onto the
#        minimum at small n (figure now agrees with the describe table).
#        (2) Bar auto-range tracks a data minimum (emlBarData_visibleMin) so
#        all-negative means are no longer clipped at 0. (3) B/W palette now
#        recomputes sprite$ greys so alpha dots/overlap match the fill/line.
# v3.20: Group sort unification — @emlExtractUniqueValues and
#         @emlMeasureBarData now call @emlCountGroups instead of inline
#         discovery. All group ordering flows through single source.
#
# v3.18: Stereo channel handling — @emlCheckChannels no longer silently
#         converts to mono. Refactored to present user dialog via new
#         @emlHandleStereo. New @emlApplyChannelChoice for batch scripts
#         (applies pre-selected channel handling without dialog).
#         Three-procedure architecture: @emlApplyChannelChoice (mechanical
#         core), @emlHandleStereo (single-file UI wrapper),
#         @emlCheckChannels (backward-compat thin wrapper).
# v3.17: New @emlExpandDrawnExtent procedure — single source of truth
#         for extent tracker bounding box expansion. Replaces inline
#         pattern in @emlSetAdaptiveTheme; also called by
#         @emlDrawMatrixPanel (eml-annotation-procedures.praat) to
#         register the matrix panel viewport with the extent tracker.
# v3.16: New @emlMeasureBarData procedure — extracts and aggregates bar
#         chart data (unique groups, per-group means, SE/SD/custom errors,
#         visible max) into emlBarData_* globals. Called once from
#         pre-dispatch; results read by both headroom computation and
#         @emlDrawBarChart. Eliminates DRY violation between pre-dispatch
#         aggregation and draw procedure aggregation.
# v3.15: Independent per-axis control — emlShowTicks/emlShowAxisValues
#         split to emlShowTicksX/Y and emlShowAxisValuesX/Y. New
#         emlShowAxisNameX/Y globals gate axis label drawing. New
#         @emlExpandAxisControls procedure: 3 dropdown indices → 6
#         per-axis booleans. All 3 aligned mark procedures,
#         @emlDrawCategoricalXAxis, @emlDrawAxes, and
#         @emlDrawAxesSelective updated. Categorical group names
#         always visible regardless of X tick/value settings.
#         Sanitization moved to source: @emlCapitalizeLabel now calls
#         @emlSanitizeLabel (auto-generated labels). @emlDrawAxes and
#         @emlDrawAxesSelective no longer sanitize axis labels — user-typed
#         labels with Praat formatting codes (%italic, #bold, ^super,
#         _sub) pass through raw.
#         New .tickColor$ ("{0.35, 0.35, 0.35}") in @emlSetAdaptiveTheme
#         — tick value numbers draw slightly muted vs axis name labels
#         (textColor$). Applied in all 3 aligned mark procedures.
# v3.14: New @emlDrawTitle procedure — centralizes title/subtitle drawing
#         via Text special with 1:1 inch coordinate mapping. Title/subtitle
#         anchored upward from inner box top, horizontally centered on inner
#         box. Replaces 7 inline title blocks (1 in @emlDrawAxes, 6 in
#         categorical procs via eml-draw-procedures). Clipping guard for
#         small viewports.
#         @emlSetAdaptiveTheme: symmetric margins (.marginRight = .marginLeft).
#         New .bodyInch, .titleInch outputs (typography in inches). New
#         .boxInsetInches output — unified physical inset for legend,
#         annotation block, and comparison matrix boxes.
#         @emlDrawLegend insetX/Y now use boxInsetInches for equal padding.
# v3.13: @emlDrawLegend — colored line samples replaced with filled
#         square swatches; legend text labels now use axis text color
#         (textColor$) instead of group color. @emlDrawAxes title
#         centering — asserts full outer viewport before title/subtitle
#         so text centers on figure, not inner box. Subtitle support
#         (global emlSubtitle$, drawn at bodySize in grey via Text top:
#         "no"). Content-driven marginTop — computed from title/subtitle
#         typography instead of viewport height cap.
# v3.12: New @emlDrawAlignedMarksBottom procedure — mirrors Left/Right
#         for bottom x-axis ticks. @emlDrawAxes and @emlDrawAxesSelective
#         refactored to call aligned mark procedures (Left/Bottom) instead
#         of inline loops — DRY, consistent guard logic. Show axis values
#         toggle (emlShowAxisValues) added: all 3 aligned mark procedures
#         now independently control writeNumber (emlShowAxisValues) and
#         drawTick (emlShowTicks). @emlDrawAxesSelective per-axis params
#         (.showXTicks/.showYTicks) remain as hard overrides wrapping the
#         procedure calls.
# v3.11: @emlSetAdaptiveTheme — bare Helvetica replaced with
#         'emlFont$' global variable (set by main script font dropdown).
#         Theme exposes .font$ output for documentation.
# v3.10: @emlDrawLegend font restore moved before Select inner
#         viewport (was after — caused margin mismatch). Show ticks
#         toggle (emlShowTicks) guards added to @emlDrawAxes,
#         @emlDrawAxesSelective, @emlDrawAlignedMarksLeft/Right.
# v3.9: @emlDrawInnerBoxIf — wrapper for Draw inner box with boolean toggle
#        and font size assertion (resolves BUG-007/008 tick displacement).
#        @emlDrawVerticalGridlines — vertical-only gridlines for continuous
#        axes. @emlDrawLegend now restores Font size: bodySize at end
#        (font state management layer 1).
#
# v3.7: New @emlFitCategoricalLabels procedure — space-aware x-axis labels
#        with automatic truncation via Text width (world coordinates) when
#        labels exceed available slot width. Used by all categorical draw procs.
#
# These procedures provide consistent, publication-quality figure styling.
# Include this file at the top of any script that generates Picture window output.
#
# 
# v3.4 changes (from v3.3):
#   - @emlSetAdaptiveTheme: new .annotSize output — annotation/bracket font
#     that scales down more aggressively at small viewports (drops extra point
#     below baseUnit 3.5"). Prevents bracket text clipping at 4×4 viewports.
#   - @emlDrawViolin: added .width parameter (replaces hardcoded 0.35).
#     Enables narrower violins for grouped violin plots. boxWidth derived
#     from .width * 0.143 to maintain proportional quartile box.
#   - New primitive: @emlDrawBox — Tukey box-and-whisker with outlier dots.
#     Five-number summary + 1.5×IQR fences, clipped to axis bounds.
#   - New primitive: @emlDrawAlphaRect — alpha-composited filled rectangle
#     via PNG sprite stretching. Used for histogram overlap mode.
#     Falls back to opaque Paint rectangle: when sprites absent.
# v3.2 changes (from v3.1):
#   - @emlDrawLegend: replaced charW estimation with exact text measurement
#     via Text width (world coordinates):. All spacing (line height, padding,
#     insets, sample line length) now derived from font size in inches ×
#     world-per-inch, so physical spacing is uniform regardless of axis
#     scale ratios. Line height uses same 1.4× formula as annotation block.
#   - @emlSetColorPalette B/W sprites: reordered to grey-based (v5),
#     starting bw04 (dark-medium) + bw08 (light) for 2-group separation.
# v3.1 changes (from v3.0):
#   - @emlSetColorPalette: .line$[], .fill$[], .lightLine$[] extended from
#     6 to 10 entries in both color and B/W modes to match the 10-group cap.
#     Color mode adds Okabe-Ito yellow (7) and black (8); 9-10 cycle.
#     B/W mode adds 4 additional grey levels for groups 7-10.
#   - @emlSetAlphaDotGeometry: fixed inverted aspect ratio (wuPerInchY/X
#     was swapped, causing dots to flatten into horizontal dashes).
#   - @emlDrawAlphaDot: added fileReadable guard — missing sprite file
#     falls back to native Paint circle: instead of failing silently.
# v3.0 changes (from v2.9):
#   - Alpha compositing support via PNG sprite stamping:
#     @emlInitAlphaSprites — resolves sprites/ directory, checks availability
#     @emlSetAlphaDotGeometry — aspect-corrected stamp dimensions
#     @emlDrawAlphaDot — per-point alpha dot primitive with native fallback
#   - @emlSetColorPalette: added .sprite$[1..10] arrays mapping group index
#     to sprite filename stems. Color mode uses Okabe-Ito names; B/W mode
#     uses perceptually-spaced grey levels (bw01-bw10) ordered for maximal
#     separation at any group count.
#   - Requires sprites/ folder in plugin with pre-rendered PNG dots.
#     Falls back to native Paint circle: if sprites are absent.
# v2.9 changes (from v2.8):
#   - New procedure: @emlDrawAlignedMarksRight — right-side counterpart
#     of @emlDrawAlignedMarksLeft for dual-axis panels.
# v2.7 changes (from v2.6):
#   - Removed: @emlDrawAxesWithHeadroom (dead code, superseded by
#     pre-dispatch valueMax expansion pattern).
#   - Fixed: near-zero tick labels (e.g., 2.776e-17) now snap to exact 0.
#     Applied to all tick loops in @emlDrawAxes, @emlDrawAxesSelective,
#     and @emlDrawAlignedMarksLeft.
#
# v2.6 changes (from v2.5):
#   - New procedure: @emlCheckNumericColumn — validates Table column
#     contains numeric data by sampling first 5 rows.
#
# v2.5 changes (from v2.4):
#   - @emlDrawAxes and @emlDrawAxesSelective now sanitize title, xLabel,
#     yLabel at entry via @emlSanitizeLabel (Rule 28J compliance).
#
# v2.4 changes (from v2.3):
#   - New procedure: @emlDrawLegend — legend box with filled background,
#     colored sample lines, and positioned text. Uses global arrays
#     legendN, legendColor$[1..N], legendLabel$[1..N].
#
# v2.3 changes (from v2.1):
#   - RECONCILIATION: merged plugin v2.1 and KB v2.2 branches
#   - New procedures from KB: @emlSanitizeLabel, @emlDrawJitteredPoints,
#     @emlAssertFullViewport, @emlCheckChannels, @emlCheckPlausibility
#   - See EML Graphs Project Bible §8 for full divergence record
#
# v2.1 changes:
#   - @emlDrawViolin now accepts axisYMin/axisYMax for clipping to axis bounds
#   - @emlSetAdaptiveTheme: wider marginLeft for y-axis label accommodation
#
# v2.0 changes:
#   - Gridlines now align with axis ticks (shared nice-number computation)
#   - Minor gridlines (ticks + lines, no numbers) at medium/large sizes
#   - Size-adaptive tick density prevents label collision at small viewports
#   - Compressed margins at very small viewports
#
# For the EML Graphs plugin, this file lives at:
#   procedures/eml-graph-procedures.praat
# ============================================================================

# ============================================================================
# PANEL ORIGIN AND EXTENT TRACKING
# ============================================================================
# Panel origin — enables multi-panel layouts. Default: single panel
# at Picture window origin. Set via @emlSetPanelOrigin before drawing.
# All viewport coordinates computed by @emlSetAdaptiveTheme are offset
# by these values.
# ============================================================================
emlPanelOriginX = 0
emlPanelOriginY = 0

# Extent tracking — updated by @emlSetAdaptiveTheme on each call.
# Read by @emlAssertFullViewport to capture the full drawn area.
emlDrawnMinX = 0
emlDrawnMaxX = 0
emlDrawnMinY = 0
emlDrawnMaxY = 0

# ----------------------------------------------------------------------------
# @emlSetPanelOrigin
# Sets the origin for the current drawing panel. All subsequent calls to
# @emlSetAdaptiveTheme will offset viewport bounds by this origin.
# For single-panel figures, do not call (defaults are 0, 0).
# For multi-panel, call before each panel's draw procedure.
# Arguments: .x (inches from left), .y (inches from top)
# ----------------------------------------------------------------------------
procedure emlSetPanelOrigin: .x, .y
    emlPanelOriginX = .x
    emlPanelOriginY = .y
endproc

# ----------------------------------------------------------------------------
# @emlResetDrawnExtent
# Resets extent tracking to zero. Call at the start of a new figure
# (before Erase all or before the first panel).
# ----------------------------------------------------------------------------
procedure emlResetDrawnExtent
    emlDrawnMinX = 0
    emlDrawnMaxX = 0
    emlDrawnMinY = 0
    emlDrawnMaxY = 0
endproc

# ----------------------------------------------------------------------------
# @emlExpandDrawnExtent
# Expands the drawn extent bounding box to include the given rectangle.
# Called by @emlSetAdaptiveTheme (for plot panels) and by any procedure
# that draws outside the theme-managed viewport (e.g., matrix panel).
# Arguments: .left, .right, .top, .bottom (inches)
# ----------------------------------------------------------------------------
procedure emlExpandDrawnExtent: .left, .right, .top, .bottom
    if emlDrawnMinX = 0 and emlDrawnMaxX = 0
        emlDrawnMinX = .left
        emlDrawnMaxX = .right
        emlDrawnMinY = .top
        emlDrawnMaxY = .bottom
    else
        if .left < emlDrawnMinX
            emlDrawnMinX = .left
        endif
        if .right > emlDrawnMaxX
            emlDrawnMaxX = .right
        endif
        if .top < emlDrawnMinY
            emlDrawnMinY = .top
        endif
        if .bottom > emlDrawnMaxY
            emlDrawnMaxY = .bottom
        endif
    endif
endproc

# ----------------------------------------------------------------------------
# @emlSetPanelViewport
# Sets both outer and inner viewport for the current panel using
# theme-computed bounds. Replaces the repeated 2-line pattern at the
# top of every draw orchestrator.
# Requires: @emlSetAdaptiveTheme has been called for this panel.
# No arguments — reads from emlSetAdaptiveTheme outputs.
# ----------------------------------------------------------------------------
procedure emlSetPanelViewport
    Select outer viewport: emlSetAdaptiveTheme.outerLeft,
    ... emlSetAdaptiveTheme.outerRight,
    ... emlSetAdaptiveTheme.outerTop,
    ... emlSetAdaptiveTheme.outerBottom
    Select inner viewport: emlSetAdaptiveTheme.innerLeft,
    ... emlSetAdaptiveTheme.innerRight,
    ... emlSetAdaptiveTheme.innerTop,
    ... emlSetAdaptiveTheme.innerBottom
endproc

# ----------------------------------------------------------------------------
# @emlInitDrawingDefaults
# Initializes all rendering globals to sensible defaults. Call once at
# script top for standalone scripts or PraatGen companion files.
# The plugin does NOT call this — it has its own UI-driven path.
#
# Precondition for all @emlDraw* orchestrator procedures.
# ----------------------------------------------------------------------------
procedure emlInitDrawingDefaults
    # Panel origin (single panel at Picture window origin)
    emlPanelOriginX = 0
    emlPanelOriginY = 0
    # Extent tracking
    emlDrawnMinX = 0
    emlDrawnMaxX = 0
    emlDrawnMinY = 0
    emlDrawnMaxY = 0
    # Y-axis minimum tick step. 0 = unconstrained. A drawing procedure whose
    # y-axis is integral (a count, an ordinal rank) sets this to 1 so the
    # nice-number step cannot fall below a whole unit and label the axis in
    # fractions of something that has none. A procedure that sets it is
    # responsible for clearing it before returning.
    emlYAxisMinStep = 0
    # Axis display
    emlShowInnerBox = 1
    emlShowAxisNameX = 1
    emlShowAxisNameY = 1
    emlShowTicksX = 1
    emlShowTicksY = 1
    emlShowAxisValuesX = 1
    emlShowAxisValuesY = 1
    # Typography
    emlFont$ = "Helvetica"
    emlSubtitle$ = ""
    # Categorical x-axis fit state.
    #
    # @emlDrawCategoricalXAxis is a pure renderer: it READS
    # emlFitCategoricalLabels.rotated / .actualVerticalInches rather than
    # measuring, because overhang has to be known before margins are set and
    # margins are set before any drawing happens. The only caller that
    # measures is the pre-dispatch block in eml-graphs-form.praat, so until
    # 6 Aug 2026 the six categorical graph types (bar, violin, box, grouped
    # violin, grouped box, spaghetti) could not be drawn from anywhere else:
    # the renderer aborted the whole figure with "Unknown variable:
    # emlFitCategoricalLabels.rotated" before a single mark was placed.
    # Found by calling @emlDrawViolinPlot from a test harness.
    #
    # Seeding them here makes the unmeasured case degrade to a horizontal,
    # untruncated axis — labels may crowd, but the figure is produced — and
    # any caller that does measure overwrites these on the way past.
    emlFitCategoricalLabels.rotated = 0
    emlFitCategoricalLabels.overhangInches = 0
    emlFitCategoricalLabels.actualVerticalInches = 0
    emlCatMeasuredKey$ = ""
    emlBarData_key$ = ""
    # Scatter plot options
    scatterDotSize = 2
    scatterRegressionLine = 0
    scatterShowFormula = 0
    scatterShowDots = 1
    # Annotation
    annotCorrType$ = "pearson"
    annotStyle$ = "stars"
    annotShowNS = 0
    annotAlpha = 0.05
endproc

# ----------------------------------------------------------------------------
# @emlSetAdaptiveTheme
# Computes all styling parameters from viewport dimensions
# Arguments: vpWidth (inches), vpHeight (inches)
# Outputs: .baseUnit, .bodySize, .titleSize, .annotSize, .matrixSize,
#          .matrix10Size, .scaleRatio,
#          .marginLeft, .marginRight,
#          .marginTop, .marginBottom, .marginRightWithLegend,
#          .dataLineWidth, .axisLineWidth, .gridLineWidth, .markerSize,
#          .outerLeft, .outerRight, .outerTop, .outerBottom,
#          .innerLeft, .innerRight, .innerTop, .innerBottom,
#          .targetTicksX, .targetTicksY, .useMinorTicks,
#          .axisColor$, .textColor$, .gridColor$, .minorGridColor$
# ----------------------------------------------------------------------------
procedure emlSetAdaptiveTheme: .vpWidth, .vpHeight
    # Y-axis step constraint guard. Defined here only when it does not already
    # exist, for the same reason as the panel-origin guard below: a draw
    # procedure can be entered without @emlInitDrawingDefaults having run, and
    # an undefined global aborts the figure at the first comparison.
    #
    # It must NOT be unconditionally reset here. @emlDrawAxes calls this
    # procedure again partway through a figure, so an unconditional reset would
    # clear the constraint immediately before the tick marks are drawn. Both
    # failures were observed; neither is hypothetical.
    if variableExists ("emlYAxisMinStep") = 0
        emlYAxisMinStep = 0
    endif
    # Panel origin guard — default to single-panel if not set
    if variableExists ("emlPanelOriginX") = 0
        emlPanelOriginX = 0
    endif
    if variableExists ("emlPanelOriginY") = 0
        emlPanelOriginY = 0
    endif

    .baseUnit = min (.vpWidth, .vpHeight)

    # Modular typographic scale (Major Second, ratio = 1.125)
    # Anchor = body size, derived from width-biased viewport measure.
    # Annotation/matrix tiers are ratio powers from body:
    # annotation = body / r, matrix = body / r², matrix10 = body / r³.
    # Title uses a separate 1.2× multiplier (Minor Third) for visible
    # hierarchy without affecting the smaller tiers.
    # Continuous (no rounding). Floor = 5pt (Praat legibility limit).
    .scaleRatio = 1.125
    .weighted = .vpWidth * 0.6 + .vpHeight * 0.4
    .bodySize = max (7, min (11, .weighted * 1.8))
    .titleSize = max (5, .bodySize * 1.2)
    .annotSize = max (5, .bodySize / .scaleRatio)
    .matrixSize = max (5, .bodySize / (.scaleRatio * .scaleRatio))
    .matrix10Size = max (5, .bodySize / (.scaleRatio * .scaleRatio * .scaleRatio))

    # Spacing compression factor for small viewports.
    # Controls breathing room in brackets, insets, and padding.
    # 1.0 = generous (6"+), 0.7 = tight (3"). Structural minimums
    # (text height, descender proportions) are unaffected.
    .spacingFactor = max (0.7, min (1.0, (.baseUnit - 2) / 4))

    # Margin scaling — symmetric left/right for balanced figure framing.
    # Left margin sized for tick labels + Y-axis label; right mirrors it.
    # Legend-present override (.marginRightWithLegend) handled by callers.
    .marginLeft = min (0.85, max (0.4, .vpWidth * 0.14))
    .marginRight = .marginLeft
    .marginBottom = min (0.5, max (0.2, .vpHeight * 0.14))
    .marginRightWithLegend = max (1.0, .vpWidth * 0.22)

    # Top margin — derived from title typography, not viewport height.
    # Title area height is driven by its contents (title + optional subtitle),
    # each sized from the typographic scale that already adapts to viewport.
    # Multipliers give balanced padding above and below each text element.
    .titleInch = .titleSize / 72
    .bodyInch = .bodySize / 72
    .marginTop = .titleInch * 2.5
    if emlSubtitle$ <> ""
        .marginTop = .marginTop + .bodyInch * 1.8
    endif
    .marginTop = max (0.2, .marginTop)

    # Line weight scaling
    .dataLineWidth = max (1.0, min (2.5, .baseUnit * 0.5))
    .axisLineWidth = max (0.5, min (1.0, .baseUnit * 0.25))
    .gridLineWidth = max (0.3, min (0.6, .baseUnit * 0.12))

    # Marker scaling
    .markerSize = max (0.4, min (1.2, .baseUnit * 0.25))

    # Derived viewport bounds (offset by panel origin)
    .outerLeft = emlPanelOriginX
    .outerRight = emlPanelOriginX + .vpWidth
    .outerTop = emlPanelOriginY
    .outerBottom = emlPanelOriginY + .vpHeight
    .innerLeft = emlPanelOriginX + .marginLeft
    .innerRight = emlPanelOriginX + .vpWidth - .marginRight
    .innerTop = emlPanelOriginY + .marginTop
    .innerBottom = emlPanelOriginY + .vpHeight - .marginBottom

    # Tick density — ~1 major tick per 0.5 inches of available axis, clamped 2-7
    .innerWidth = .innerRight - .innerLeft
    .innerHeight = .innerBottom - .innerTop
    .targetTicksX = max (2, min (7, round (.innerWidth / 0.5)))
    .targetTicksY = max (2, min (7, round (.innerHeight / 0.5)))

    # Minor gridlines only when there is enough room
    if .baseUnit >= 2.5
        .useMinorTicks = 1
    else
        .useMinorTicks = 0
    endif

    # Box inset — uniform physical gap between overlay boxes (legend,
    # annotation, comparison matrix) and inner box edges. Computed once
    # so all boxes share identical inset. Floor 0.12" for legibility.
    .boxInsetInches = max (0.12, .bodyInch * (0.8 + 0.4 * .spacingFactor))

    # Standard colors
    .axisColor$ = "{0.3, 0.3, 0.3}"
    .textColor$ = "{0.1, 0.1, 0.1}"
    .tickColor$ = "{0.35, 0.35, 0.35}"
    .gridColor$ = "{0.85, 0.85, 0.85}"
    .minorGridColor$ = "{0.90, 0.90, 0.90}"

    # Apply font (from global emlFont$, set by main script)
    .font$ = emlFont$
    'emlFont$'
    Font size: .bodySize

    # Update drawn extent tracking
    @emlExpandDrawnExtent: .outerLeft, .outerRight, .outerTop, .outerBottom
endproc

# ----------------------------------------------------------------------------
# @emlSetColorPalette
# Populates color arrays for data series.
# Default "color" palette is Okabe-Ito (CVD-accessible).
# Arguments: mode$ ("color" or "bw")
# Outputs: .line$[1-10], .fill$[1-10], .lightLine$[1-10], .sprite$[1-10]
# Note: For API users who need custom colors, set .line$[n], .fill$[n],
# and .lightLine$[n] directly after calling this procedure.
# ----------------------------------------------------------------------------
procedure emlSetColorPalette: .mode$
    if .mode$ = "color"
        # Okabe-Ito palette (accessible for color vision deficiency)
        # Line colors (8 distinct hues; 9-10 cycle)
        .line$[1] = "{0.00, 0.45, 0.70}"
        .line$[2] = "{0.90, 0.62, 0.00}"
        .line$[3] = "{0.34, 0.71, 0.91}"
        .line$[4] = "{0.00, 0.62, 0.45}"
        .line$[5] = "{0.84, 0.37, 0.00}"
        .line$[6] = "{0.80, 0.47, 0.65}"
        .line$[7] = "{0.95, 0.90, 0.25}"
        .line$[8] = "{0.00, 0.00, 0.00}"
        .line$[9] = "{0.00, 0.45, 0.70}"
        .line$[10] = "{0.90, 0.62, 0.00}"
        # Fill colors (70% blend toward white)
        .fill$[1] = "{0.70, 0.83, 0.91}"
        .fill$[2] = "{0.97, 0.89, 0.70}"
        .fill$[3] = "{0.80, 0.91, 0.97}"
        .fill$[4] = "{0.70, 0.89, 0.83}"
        .fill$[5] = "{0.95, 0.81, 0.70}"
        .fill$[6] = "{0.94, 0.84, 0.90}"
        .fill$[7] = "{0.99, 0.97, 0.78}"
        .fill$[8] = "{0.70, 0.70, 0.70}"
        .fill$[9] = "{0.70, 0.83, 0.91}"
        .fill$[10] = "{0.97, 0.89, 0.70}"
        # Light line colors (50% blend toward white)
        .lightLine$[1] = "{0.50, 0.73, 0.85}"
        .lightLine$[2] = "{0.95, 0.81, 0.50}"
        .lightLine$[3] = "{0.67, 0.85, 0.96}"
        .lightLine$[4] = "{0.50, 0.81, 0.73}"
        .lightLine$[5] = "{0.92, 0.69, 0.50}"
        .lightLine$[6] = "{0.90, 0.73, 0.82}"
        .lightLine$[7] = "{0.98, 0.95, 0.63}"
        .lightLine$[8] = "{0.50, 0.50, 0.50}"
        .lightLine$[9] = "{0.50, 0.73, 0.85}"
        .lightLine$[10] = "{0.95, 0.81, 0.50}"
        # Alpha sprite stems (match line$ ordering for group consistency)
        .sprite$[1] = "blue"
        .sprite$[2] = "orange"
        .sprite$[3] = "skyblue"
        .sprite$[4] = "green"
        .sprite$[5] = "vermillion"
        .sprite$[6] = "purple"
        .sprite$[7] = "yellow"
        .sprite$[8] = "black"
        .sprite$[9] = "blue"
        .sprite$[10] = "orange"
        # Cycle 8 Okabe-Ito hues for any number of groups
        for .i from 11 to 100
            .cycleIdx = ((.i - 1) mod 8) + 1
            .line$[.i] = .line$[.cycleIdx]
            .fill$[.i] = .fill$[.cycleIdx]
            .lightLine$[.i] = .lightLine$[.cycleIdx]
            .sprite$[.i] = .sprite$[.cycleIdx]
        endfor
    else
        # B&W line colors
        .line$[1] = "{0.00, 0.00, 0.00}"
        .line$[2] = "{0.35, 0.35, 0.35}"
        .line$[3] = "{0.55, 0.55, 0.55}"
        .line$[4] = "{0.45, 0.45, 0.45}"
        .line$[5] = "{0.25, 0.25, 0.25}"
        .line$[6] = "{0.65, 0.65, 0.65}"
        .line$[7] = "{0.15, 0.15, 0.15}"
        .line$[8] = "{0.50, 0.50, 0.50}"
        .line$[9] = "{0.40, 0.40, 0.40}"
        .line$[10] = "{0.75, 0.75, 0.75}"
        # B&W fill colors
        .fill$[1] = "{0.85, 0.85, 0.85}"
        .fill$[2] = "{0.90, 0.90, 0.90}"
        .fill$[3] = "{0.93, 0.93, 0.93}"
        .fill$[4] = "{0.88, 0.88, 0.88}"
        .fill$[5] = "{0.82, 0.82, 0.82}"
        .fill$[6] = "{0.95, 0.95, 0.95}"
        .fill$[7] = "{0.83, 0.83, 0.83}"
        .fill$[8] = "{0.92, 0.92, 0.92}"
        .fill$[9] = "{0.86, 0.86, 0.86}"
        .fill$[10] = "{0.96, 0.96, 0.96}"
        # B&W light line colors
        .lightLine$[1] = "{0.6, 0.6, 0.6}"
        .lightLine$[2] = "{0.7, 0.7, 0.7}"
        .lightLine$[3] = "{0.75, 0.75, 0.75}"
        .lightLine$[4] = "{0.72, 0.72, 0.72}"
        .lightLine$[5] = "{0.65, 0.65, 0.65}"
        .lightLine$[6] = "{0.78, 0.78, 0.78}"
        .lightLine$[7] = "{0.58, 0.58, 0.58}"
        .lightLine$[8] = "{0.73, 0.73, 0.73}"
        .lightLine$[9] = "{0.68, 0.68, 0.68}"
        .lightLine$[10] = "{0.80, 0.80, 0.80}"
        # Alpha sprite stems — grey-based (v5): sprites use distinct grey RGB
        # values at fixed alpha, so dense overlap darkens but never reaches
        # pure black. Ordered: medium contrast first for 2-group case.
        # 2 groups: bw04 (dark-medium grey) + bw08 (light grey) — clear separation
        # 3 groups: adds bw06 (medium-light)
        .sprite$[1] = "bw04"
        .sprite$[2] = "bw08"
        .sprite$[3] = "bw06"
        .sprite$[4] = "bw02"
        .sprite$[5] = "bw09"
        .sprite$[6] = "bw05"
        .sprite$[7] = "bw03"
        .sprite$[8] = "bw07"
        .sprite$[9] = "bw10"
        .sprite$[10] = "bw01"
        # Cycle BW sprites for groups beyond 10
        for .i from 11 to 100
            .cycleIdx = ((.i - 1) mod 8) + 1
            .line$[.i] = .line$[.cycleIdx]
            .fill$[.i] = .fill$[.cycleIdx]
            .lightLine$[.i] = .lightLine$[.cycleIdx]
            .sprite$[.i] = .sprite$[.cycleIdx]
        endfor
    endif
endproc

# ----------------------------------------------------------------------------
# @emlOptimizePaletteContrast
# Reorders palette arrays to maximize perceptual distance for K groups.
# Must be called AFTER @emlSetColorPalette and BEFORE any drawing.
# For K < 7, skips sky blue (index 3) to avoid blue/skyblue confusion,
# and defers vermillion (5) when K < 5 to avoid orange/vermillion overlap.
# Arguments: .nGroups (number of groups that will be drawn)
# Side effect: overwrites emlSetColorPalette arrays [1..nGroups]
# ----------------------------------------------------------------------------
procedure emlOptimizePaletteContrast: .nGroups
    # Only remap for 2+ groups
    if .nGroups >= 2
        # Save originals
        for .i from 1 to 10
            .origLine$[.i] = emlSetColorPalette.line$[.i]
            .origFill$[.i] = emlSetColorPalette.fill$[.i]
            .origLightLine$[.i] = emlSetColorPalette.lightLine$[.i]
            .origSprite$[.i] = emlSetColorPalette.sprite$[.i]
        endfor

        # Detect B/W mode: index 2 line color is grey in B/W, orange in color
        .isBW = 0
        if .origLine$[2] = "{0.35, 0.35, 0.35}"
            .isBW = 1
        endif

        if .isBW = 0
            # === COLOR MODE ===
            # Okabe-Ito: 1=blue 2=orange 3=skyblue 4=green
            #            5=vermillion 6=purple 7=yellow 8=black
            # Strategy: skip skyblue (3) when possible (confusable with blue).
            # Skip vermillion (5) when <5 groups (confusable with orange).
            # For 7+, all hues needed — order for max adjacent contrast.
            if .nGroups = 2
                .src[1] = 1
                .src[2] = 2
            elsif .nGroups = 3
                .src[1] = 1
                .src[2] = 2
                .src[3] = 4
            elsif .nGroups = 4
                .src[1] = 1
                .src[2] = 2
                .src[3] = 4
                .src[4] = 6
            elsif .nGroups = 5
                .src[1] = 1
                .src[2] = 2
                .src[3] = 4
                .src[4] = 5
                .src[5] = 6
            elsif .nGroups = 6
                .src[1] = 1
                .src[2] = 2
                .src[3] = 4
                .src[4] = 5
                .src[5] = 6
                .src[6] = 7
            elsif .nGroups = 7
                # All hues except black — spread confusable pairs apart
                # blue, orange, green, purple, skyblue, vermillion, yellow
                .src[1] = 1
                .src[2] = 2
                .src[3] = 4
                .src[4] = 6
                .src[5] = 3
                .src[6] = 5
                .src[7] = 7
            elsif .nGroups = 8
                # All 8 hues — confusable pairs maximally separated
                # blue, orange, green, purple, yellow, skyblue, vermillion, black
                .src[1] = 1
                .src[2] = 2
                .src[3] = 4
                .src[4] = 6
                .src[5] = 7
                .src[6] = 3
                .src[7] = 5
                .src[8] = 8
            elsif .nGroups = 9
                # 8 hues + cycle blue — keep cycle away from original
                .src[1] = 1
                .src[2] = 2
                .src[3] = 4
                .src[4] = 6
                .src[5] = 7
                .src[6] = 3
                .src[7] = 5
                .src[8] = 8
                .src[9] = 9
            elsif .nGroups = 10
                # 8 hues + cycle blue, orange
                .src[1] = 1
                .src[2] = 2
                .src[3] = 4
                .src[4] = 6
                .src[5] = 7
                .src[6] = 3
                .src[7] = 5
                .src[8] = 8
                .src[9] = 9
                .src[10] = 10
            else
                # >10 groups: 8-hue optimized order, then cycle
                .src[1] = 1
                .src[2] = 2
                .src[3] = 4
                .src[4] = 6
                .src[5] = 7
                .src[6] = 3
                .src[7] = 5
                .src[8] = 8
                for .i from 9 to .nGroups
                    .src[.i] = ((.i - 1) mod 8) + 1
                endfor
            endif
        else
            # === B/W MODE ===
            # Default B/W fills (0.82-0.96) are too narrow for overlap.
            # Compute evenly-spaced fills across usable greyscale range.
            # Lines are 0.30 darker than fill for consistent contrast.
            # Compute up to 8 distinct greys, then cycle for >8 groups.
            .fillMin = 0.25
            .fillMax = 0.90
            .distinctN = min (.nGroups, 8)
            for .i from 1 to .distinctN
                if .distinctN > 1
                    .fillVal = .fillMin + (.i - 1) * (.fillMax - .fillMin) / (.distinctN - 1)
                else
                    .fillVal = 0.85
                endif
                .lineVal = max (0, .fillVal - 0.30)
                .lightVal = (.fillVal + .lineVal) / 2
                emlSetColorPalette.fill$[.i] = "{" + fixed$ (.fillVal, 2) + ", " + fixed$ (.fillVal, 2) + ", " + fixed$ (.fillVal, 2) + "}"
                emlSetColorPalette.line$[.i] = "{" + fixed$ (.lineVal, 2) + ", " + fixed$ (.lineVal, 2) + ", " + fixed$ (.lineVal, 2) + "}"
                emlSetColorPalette.lightLine$[.i] = "{" + fixed$ (.lightVal, 2) + ", " + fixed$ (.lightVal, 2) + ", " + fixed$ (.lightVal, 2) + "}"
            endfor
            # Cycle for groups beyond 8
            for .i from .distinctN + 1 to .nGroups
                .cycleIdx = ((.i - 1) mod .distinctN) + 1
                emlSetColorPalette.fill$[.i] = emlSetColorPalette.fill$[.cycleIdx]
                emlSetColorPalette.line$[.i] = emlSetColorPalette.line$[.cycleIdx]
                emlSetColorPalette.lightLine$[.i] = emlSetColorPalette.lightLine$[.cycleIdx]
            endfor
        endif

        # Overwrite positions 1..nGroups (color mode only — B/W computed above)
        if .isBW = 0
            for .i from 1 to .nGroups
                .s = .src[.i]
                emlSetColorPalette.line$[.i] = .origLine$[.s]
                emlSetColorPalette.fill$[.i] = .origFill$[.s]
                emlSetColorPalette.lightLine$[.i] = .origLightLine$[.s]
                emlSetColorPalette.sprite$[.i] = .origSprite$[.s]
            endfor
        endif
    endif
endproc

# ----------------------------------------------------------------------------
# @emlComputeAxisRange
# Computes axis bounds from data range with buffer and rounding
# Arguments: dataMin, dataMax, roundTo, isPercentage (0 or 1)
# Outputs: .axisMin, .axisMax, .degenerate (v3.22)
#
# v3.22: undefined inputs are detected explicitly rather than being allowed
# to flow through the comparison chain. In Praat every comparison against
# undefined is FALSE (u > 0, u <= 1, u >= 0 are all false), so an undefined
# .dataMin/.dataMax previously slipped past every "guard" here and produced
# an undefined .axisMin/.axisMax, which aborts the whole figure at the
# subsequent Axes: command. Undefined or non-finite input now falls back to
# a unit axis and sets .degenerate = 1 so callers can report it.
# ----------------------------------------------------------------------------
procedure emlComputeAxisRange: .dataMin, .dataMax, .roundTo, .isPercentage
    .degenerate = 0
    .badInput = 0
    if .dataMin = undefined
        .badInput = 1
    endif
    if .dataMax = undefined
        .badInput = 1
    endif
    if .roundTo = undefined
        .badInput = 1
    else
        if .roundTo <= 0
            .badInput = 1
        endif
    endif
    if .badInput = 1
        .degenerate = 1
        .axisMin = 0
        .axisMax = 1
        goto AXIS_RANGE_END
    endif
    if .isPercentage
        if .dataMax <= 1
            .axisMin = 0
            .axisMax = 1
        else
            .axisMin = 0
            .axisMax = 100
        endif
    else
        .range = .dataMax - .dataMin

        # Guard: zero range (all values identical)
        if .range = 0
            .range = abs (.dataMin) * 0.2
            if .range = 0
                .range = 1
            endif
        endif

        .buffer = .range * 0.1
        .rawMin = .dataMin - .buffer
        .rawMax = .dataMax + .buffer

        .axisMin = floor (.rawMin / .roundTo) * .roundTo
        .axisMax = ceiling (.rawMax / .roundTo) * .roundTo

        # Protect non-negative data from going below 0
        if .dataMin >= 0 and .axisMin < 0
            .axisMin = 0
        endif

        # v3.22: final safety net. If .roundTo is enormous relative to the
        # data the rounding can collapse the axis to zero width, which makes
        # every downstream tick/step computation degenerate.
        if .axisMax <= .axisMin
            .degenerate = 1
            .axisMax = .axisMin + 1
        endif
    endif
    label AXIS_RANGE_END
endproc

# ----------------------------------------------------------------------------
# @emlComputeNiceStep
# Classic nice-number algorithm for human-friendly tick spacing
# Arguments: range (axis max minus axis min), targetTicks (desired tick count)
# Outputs: .step (the nice step size)
#
# v3.22: the guard below was "if .range <= 0 or .targetTicks < 1", which is
# FALSE when .range is undefined (every relational comparison against
# undefined is false in Praat). An undefined .range therefore took the else
# branch and produced an undefined .step, which propagates into the
# gridline/tick while-loops that follow every caller. Undefined inputs are
# now tested explicitly and routed to the same fallback as an empty range.
# ----------------------------------------------------------------------------
procedure emlComputeNiceStep: .range, .targetTicks
    .bad = 0
    if .range = undefined
        .bad = 1
    endif
    if .targetTicks = undefined
        .bad = 1
    endif
    if .bad = 0
        if .range <= 0 or .targetTicks < 1
            .bad = 1
        endif
    endif
    if .bad = 1
        .step = 1
    else
        .roughStep = .range / .targetTicks
        .mag = 10 ^ floor (log10 (.roughStep))
        .norm = .roughStep / .mag
        if .norm <= 1.5
            .nice = 1
        elsif .norm <= 3
            .nice = 2
        elsif .norm <= 7
            .nice = 5
        else
            .nice = 10
        endif
        .step = .nice * .mag
    endif
endproc

# ----------------------------------------------------------------------------
# @emlDrawGridlines
# Draws gridlines aligned with nice-number tick positions
# Arguments: xMin, xMax, yMin, yMax, targetTicksX, targetTicksY, useMinor
# useMinor: 1 = draw faint interleaved minor gridlines between major ones
# Call after Axes command, before data drawing
# ----------------------------------------------------------------------------
procedure emlDrawGridlines: .xMin, .xMax, .yMin, .yMax, .targetTicksX, .targetTicksY, .useMinor
    # Compute nice step for each axis
    @emlComputeNiceStep: .yMax - .yMin, .targetTicksY
    .yStep = emlComputeNiceStep.step
    # Honour an integral y-axis: never step below a whole unit.
    if emlYAxisMinStep > 0 and .yStep < emlYAxisMinStep
        .yStep = emlYAxisMinStep
    endif
    @emlComputeNiceStep: .xMax - .xMin, .targetTicksX
    .xStep = emlComputeNiceStep.step

    # Tolerance for floating-point boundary checks
    .yTol = .yStep * 0.01
    .xTol = .xStep * 0.01

    # === Major gridlines ===
    Colour: "{0.85, 0.85, 0.85}"
    Line width: 0.5

    # Horizontal major
    .yPos = ceiling (.yMin / .yStep) * .yStep
    while .yPos <= .yMax + .yTol
        if .yPos >= .yMin - .yTol
            Draw line: .xMin, .yPos, .xMax, .yPos
        endif
        .yPos = .yPos + .yStep
    endwhile

    # Vertical major
    .xPos = ceiling (.xMin / .xStep) * .xStep
    while .xPos <= .xMax + .xTol
        if .xPos >= .xMin - .xTol
            Draw line: .xPos, .yMin, .xPos, .yMax
        endif
        .xPos = .xPos + .xStep
    endwhile

    # === Minor gridlines (halfway between majors) ===
    if .useMinor
        Colour: "{0.90, 0.90, 0.90}"
        Line width: 0.3

        .yHalf = .yStep / 2
        .yPos = ceiling (.yMin / .yStep) * .yStep - .yHalf
        if .yPos < .yMin
            .yPos = .yPos + .yStep
        endif
        while .yPos <= .yMax - .yTol
            if .yPos > .yMin + .yTol
                Draw line: .xMin, .yPos, .xMax, .yPos
            endif
            .yPos = .yPos + .yStep
        endwhile

        .xHalf = .xStep / 2
        .xPos = ceiling (.xMin / .xStep) * .xStep - .xHalf
        if .xPos < .xMin
            .xPos = .xPos + .xStep
        endif
        while .xPos <= .xMax - .xTol
            if .xPos > .xMin + .xTol
                Draw line: .xPos, .yMin, .xPos, .yMax
            endif
            .xPos = .xPos + .xStep
        endwhile
    endif

    Colour: "Black"
    Line width: 1.0
endproc

# ----------------------------------------------------------------------------
# @emlDrawHorizontalGridlines
# Draws only horizontal gridlines aligned with nice-number tick positions
# (for bar charts, histograms, violins with categorical x-axis)
# Arguments: xMin, xMax, yMin, yMax, targetTicksY, useMinor
# ----------------------------------------------------------------------------
procedure emlDrawHorizontalGridlines: .xMin, .xMax, .yMin, .yMax, .targetTicksY, .useMinor
    @emlComputeNiceStep: .yMax - .yMin, .targetTicksY
    .yStep = emlComputeNiceStep.step
    # Honour an integral y-axis: never step below a whole unit.
    if emlYAxisMinStep > 0 and .yStep < emlYAxisMinStep
        .yStep = emlYAxisMinStep
    endif
    .yTol = .yStep * 0.01

    # Major horizontal gridlines
    Colour: "{0.85, 0.85, 0.85}"
    Line width: 0.5

    .yPos = ceiling (.yMin / .yStep) * .yStep
    while .yPos <= .yMax + .yTol
        if .yPos >= .yMin - .yTol
            Draw line: .xMin, .yPos, .xMax, .yPos
        endif
        .yPos = .yPos + .yStep
    endwhile

    # Minor horizontal gridlines
    if .useMinor
        Colour: "{0.90, 0.90, 0.90}"
        Line width: 0.3

        .yHalf = .yStep / 2
        .yPos = ceiling (.yMin / .yStep) * .yStep - .yHalf
        if .yPos < .yMin
            .yPos = .yPos + .yStep
        endif
        while .yPos <= .yMax - .yTol
            if .yPos > .yMin + .yTol
                Draw line: .xMin, .yPos, .xMax, .yPos
            endif
            .yPos = .yPos + .yStep
        endwhile
    endif

    Colour: "Black"
    Line width: 1.0
endproc

# ----------------------------------------------------------------------------
# @emlDrawVerticalGridlines
# Draws only vertical gridlines aligned with nice-number tick positions
# (for continuous x-axis plots where only vertical lines are wanted)
# Arguments: xMin, xMax, yMin, yMax, targetTicksX, useMinor
# ----------------------------------------------------------------------------
procedure emlDrawVerticalGridlines: .xMin, .xMax, .yMin, .yMax, .targetTicksX, .useMinor
    @emlComputeNiceStep: .xMax - .xMin, .targetTicksX
    .xStep = emlComputeNiceStep.step
    .xTol = .xStep * 0.01

    # Major vertical gridlines
    Colour: "{0.85, 0.85, 0.85}"
    Line width: 0.5

    .xPos = ceiling (.xMin / .xStep) * .xStep
    while .xPos <= .xMax + .xTol
        if .xPos >= .xMin - .xTol
            Draw line: .xPos, .yMin, .xPos, .yMax
        endif
        .xPos = .xPos + .xStep
    endwhile

    # Minor vertical gridlines
    if .useMinor
        Colour: "{0.90, 0.90, 0.90}"
        Line width: 0.3

        .xHalf = .xStep / 2
        .xPos = ceiling (.xMin / .xStep) * .xStep - .xHalf
        if .xPos < .xMin
            .xPos = .xPos + .xStep
        endif
        while .xPos <= .xMax - .xTol
            if .xPos > .xMin + .xTol
                Draw line: .xPos, .yMin, .xPos, .yMax
            endif
            .xPos = .xPos + .xStep
        endwhile
    endif

    Colour: "Black"
    Line width: 1.0
endproc

# ----------------------------------------------------------------------------
# @emlDrawInnerBoxIf
# Wrapper for Draw inner box with boolean toggle and font state assertion.
# Reads global: emlShowInnerBox (1 = draw box, 0 = skip)
# Always asserts Font size: bodySize and axis styling before drawing.
# This resolves BUG-007/008: font size changes between @emlDrawLegend
# (annotSize) and Draw inner box caused inner viewport margin displacement.
# Call this instead of bare "Draw inner box" in all drawing procedures.
# No arguments — all state from globals.
# ----------------------------------------------------------------------------
procedure emlDrawInnerBoxIf
    Font size: emlSetAdaptiveTheme.bodySize
    Colour: emlSetAdaptiveTheme.axisColor$
    Line width: emlSetAdaptiveTheme.axisLineWidth
    if emlShowInnerBox = 1
        Draw inner box
    endif
endproc

# ----------------------------------------------------------------------------
# @emlExpandAxisControls
# Expands 3 dropdown indices (config_showAxisNames, config_showTicks,
# config_showAxisValues) to 6 per-axis boolean globals.
# Dropdown mapping: 1=None, 2=Both, 3=X only, 4=Y only
# Call after config is loaded or after dialog values are captured.
# No arguments — reads config_* globals, writes eml* globals.
# ----------------------------------------------------------------------------
procedure emlExpandAxisControls
    emlShowAxisNameX = (config_showAxisNames = 2) or (config_showAxisNames = 3)
    emlShowAxisNameY = (config_showAxisNames = 2) or (config_showAxisNames = 4)
    emlShowTicksX = (config_showTicks = 2) or (config_showTicks = 3)
    emlShowTicksY = (config_showTicks = 2) or (config_showTicks = 4)
    emlShowAxisValuesX = (config_showAxisValues = 2) or (config_showAxisValues = 3)
    emlShowAxisValuesY = (config_showAxisValues = 2) or (config_showAxisValues = 4)
endproc

# ----------------------------------------------------------------------------
# @emlDrawAlignedMarksLeft
# Draws y-axis tick marks at nice-number positions (for manual axis code)
# Arguments: yMin, yMax, targetTicks, useMinor
# Draws major ticks with numbers + optional minor ticks without numbers
# Call after Draw inner box, before axis labels
# ----------------------------------------------------------------------------
procedure emlDrawAlignedMarksLeft: .yMin, .yMax, .targetTicks, .useMinor
    if emlShowTicksY = 0 and emlShowAxisValuesY = 0
        goto ALIGNED_LEFT_END
    endif

    Colour: emlSetAdaptiveTheme.tickColor$

    # Derive dynamic mark parameters
    if emlShowAxisValuesY
        .writeNum$ = "yes"
    else
        .writeNum$ = "no"
    endif
    if emlShowTicksY
        .drawTick$ = "yes"
    else
        .drawTick$ = "no"
    endif

    @emlComputeNiceStep: .yMax - .yMin, .targetTicks
    .yStep = emlComputeNiceStep.step
    # Honour an integral y-axis: never step below a whole unit.
    if emlYAxisMinStep > 0 and .yStep < emlYAxisMinStep
        .yStep = emlYAxisMinStep
    endif
    .yTol = .yStep * 0.01

    # Major ticks with numbers
    .yPos = ceiling (.yMin / .yStep) * .yStep
    while .yPos <= .yMax + .yTol
        if .yPos >= .yMin - .yTol
            if abs (.yPos) < .yTol
                .yPos = 0
            endif
            One mark left: .yPos, .writeNum$, .drawTick$, "no", ""
        endif
        .yPos = .yPos + .yStep
    endwhile

    # Minor ticks without numbers (only when ticks are visible)
    if .useMinor and emlShowTicksY
        .yHalf = .yStep / 2
        .yPos = ceiling (.yMin / .yStep) * .yStep - .yHalf
        if .yPos < .yMin
            .yPos = .yPos + .yStep
        endif
        while .yPos <= .yMax - .yTol
            if .yPos > .yMin + .yTol
                if abs (.yPos) < .yTol
                    .yPos = 0
                endif
                One mark left: .yPos, "no", "yes", "no", ""
            endif
            .yPos = .yPos + .yStep
        endwhile
    endif
    label ALIGNED_LEFT_END
endproc

# ----------------------------------------------------------------------------
# @emlDrawAlignedMarksRight
# Draws right y-axis tick marks at nice-number positions (for dual-axis panels)
# Arguments: yMin, yMax, targetTicks, useMinor
# Draws major ticks with numbers + optional minor ticks without numbers
# Call after Draw inner box, before axis labels
# Mirrors @emlDrawAlignedMarksLeft for the right margin
# ----------------------------------------------------------------------------
procedure emlDrawAlignedMarksRight: .yMin, .yMax, .targetTicks, .useMinor
    if emlShowTicksY = 0 and emlShowAxisValuesY = 0
        goto ALIGNED_RIGHT_END
    endif

    Colour: emlSetAdaptiveTheme.tickColor$

    # Derive dynamic mark parameters
    if emlShowAxisValuesY
        .writeNum$ = "yes"
    else
        .writeNum$ = "no"
    endif
    if emlShowTicksY
        .drawTick$ = "yes"
    else
        .drawTick$ = "no"
    endif

    @emlComputeNiceStep: .yMax - .yMin, .targetTicks
    .yStep = emlComputeNiceStep.step
    # Honour an integral y-axis: never step below a whole unit.
    if emlYAxisMinStep > 0 and .yStep < emlYAxisMinStep
        .yStep = emlYAxisMinStep
    endif
    .yTol = .yStep * 0.01

    # Major ticks with numbers
    .yPos = ceiling (.yMin / .yStep) * .yStep
    while .yPos <= .yMax + .yTol
        if .yPos >= .yMin - .yTol
            if abs (.yPos) < .yTol
                .yPos = 0
            endif
            One mark right: .yPos, .writeNum$, .drawTick$, "no", ""
        endif
        .yPos = .yPos + .yStep
    endwhile

    # Minor ticks without numbers (only when ticks are visible)
    if .useMinor and emlShowTicksY
        .yHalf = .yStep / 2
        .yPos = ceiling (.yMin / .yStep) * .yStep - .yHalf
        if .yPos < .yMin
            .yPos = .yPos + .yStep
        endif
        while .yPos <= .yMax - .yTol
            if .yPos > .yMin + .yTol
                if abs (.yPos) < .yTol
                    .yPos = 0
                endif
                One mark right: .yPos, "no", "yes", "no", ""
            endif
            .yPos = .yPos + .yStep
        endwhile
    endif
    label ALIGNED_RIGHT_END
endproc

# ----------------------------------------------------------------------------
# @emlDrawAlignedMarksBottom
# Draws bottom x-axis tick marks at nice-number positions
# Arguments: xMin, xMax, targetTicks, useMinor
# Draws major ticks with numbers + optional minor ticks without numbers
# Call after Draw inner box, before axis labels
# Mirrors @emlDrawAlignedMarksLeft for the bottom margin
# Respects globals: emlShowTicksX (tick marks), emlShowAxisValuesX (numbers)
# ----------------------------------------------------------------------------
procedure emlDrawAlignedMarksBottom: .xMin, .xMax, .targetTicks, .useMinor
    if emlShowTicksX = 0 and emlShowAxisValuesX = 0
        goto ALIGNED_BOTTOM_END
    endif

    Colour: emlSetAdaptiveTheme.tickColor$

    # Derive dynamic mark parameters
    if emlShowAxisValuesX
        .writeNum$ = "yes"
    else
        .writeNum$ = "no"
    endif
    if emlShowTicksX
        .drawTick$ = "yes"
    else
        .drawTick$ = "no"
    endif

    @emlComputeNiceStep: .xMax - .xMin, .targetTicks
    .xStep = emlComputeNiceStep.step
    .xTol = .xStep * 0.01

    # Major ticks with numbers
    .xPos = ceiling (.xMin / .xStep) * .xStep
    while .xPos <= .xMax + .xTol
        if .xPos >= .xMin - .xTol
            if abs (.xPos) < .xTol
                .xPos = 0
            endif
            One mark bottom: .xPos, .writeNum$, .drawTick$, "no", ""
        endif
        .xPos = .xPos + .xStep
    endwhile

    # Minor ticks without numbers (only when ticks are visible)
    if .useMinor and emlShowTicksX
        .xHalf = .xStep / 2
        .xPos = ceiling (.xMin / .xStep) * .xStep - .xHalf
        if .xPos < .xMin
            .xPos = .xPos + .xStep
        endif
        while .xPos <= .xMax - .xTol
            if .xPos > .xMin + .xTol
                if abs (.xPos) < .xTol
                    .xPos = 0
                endif
                One mark bottom: .xPos, "no", "yes", "no", ""
            endif
            .xPos = .xPos + .xStep
        endwhile
    endif
    label ALIGNED_BOTTOM_END
endproc

# ----------------------------------------------------------------------------
# @emlDrawTitle
# Draws figure title and optional subtitle via Text special, positioned
# above the inner box and horizontally centered on it. Uses a full-canvas
# inner viewport with 1:1 inch mapping for exact coordinate control.
#
# Vertical layout: subtitle sits just above the inner box top edge,
# title sits above subtitle. Both build upward from the box.
#
# Arguments: title$, vpWidth, vpHeight, xMin, xMax, yMin, yMax
#   title$ must be pre-sanitized (caller runs @emlSanitizeLabel).
#   xMin..yMax are the current axes values to restore after drawing.
# Reads globals: emlSubtitle$, emlFont$, emlSetAdaptiveTheme.*
# Outputs: none (drawing side-effects only)
# ----------------------------------------------------------------------------
procedure emlDrawTitle: .title$, .vpWidth, .vpHeight, .xMin, .xMax, .yMin, .yMax
    if .title$ = "" and emlSubtitle$ = ""
        goto DRAW_TITLE_END
    endif

    # Full-canvas inner viewport for 1:1 inch coordinate mapping
    # y increases downward (top-down) via Axes mapping
    Select inner viewport: emlSetAdaptiveTheme.outerLeft,
    ... emlSetAdaptiveTheme.outerRight,
    ... emlSetAdaptiveTheme.outerTop,
    ... emlSetAdaptiveTheme.outerBottom
    Axes: 0, .vpWidth, .vpHeight, 0

    # Horizontal center of inner box (local coordinates — margins, not offset)
    .titleX = (emlSetAdaptiveTheme.marginLeft + .vpWidth - emlSetAdaptiveTheme.marginRight) / 2

    # Inner box top edge in local panel coordinates
    .innerBoxTopY = emlSetAdaptiveTheme.marginTop

    # Typographic spacing
    .tInch = emlSetAdaptiveTheme.titleInch
    .bInch = emlSetAdaptiveTheme.bodyInch
    .clearance = .bInch * 0.5
    .gap = .bInch * 0.4

    # Build upward (decreasing y) from inner box top
    if emlSubtitle$ <> ""
        .subtitleY = .innerBoxTopY - .clearance - .bInch / 2
        .titleY = .subtitleY - .bInch / 2 - .gap - .tInch / 2
    else
        .titleY = .innerBoxTopY - .clearance - .tInch / 2
    endif

    # Clipping guard — prevent title above panel top on small viewports
    .titleY = max (.tInch / 2, .titleY)

    if .title$ <> ""
        Colour: emlSetAdaptiveTheme.textColor$
        Text special: .titleX, "centre", .titleY, "half",
        ... emlFont$, emlSetAdaptiveTheme.titleSize, "0", .title$
    endif

    if emlSubtitle$ <> ""
        @emlSanitizeLabel: emlSubtitle$
        # D30: the subtitle was {0.55, 0.55, 0.55} — 3.35:1 against white by
        # the WCAG 2.x sRGB relative-luminance formula, below the AA 4.5:1
        # minimum for normal text and washed out in greyscale print.
        # {0.40, 0.40, 0.40} is 5.74:1 against white and still reads as
        # secondary next to the title's textColor$ ({0.1} = 17.4:1).
        # 0.46 is the lightest grey that still clears 4.5:1 on white.
        Colour: "{0.40, 0.40, 0.40}"
        Text special: .titleX, "centre", .subtitleY, "half",
        ... emlFont$, emlSetAdaptiveTheme.bodySize, "0", emlSanitizeLabel.result$
    endif

    # Restore font state BEFORE viewport — Praat uses current font size
    # to compute viewport label margins
    Font size: emlSetAdaptiveTheme.bodySize
    Select inner viewport: emlSetAdaptiveTheme.innerLeft,
    ... emlSetAdaptiveTheme.innerRight,
    ... emlSetAdaptiveTheme.innerTop,
    ... emlSetAdaptiveTheme.innerBottom
    Axes: .xMin, .xMax, .yMin, .yMax

    label DRAW_TITLE_END
endproc

# ----------------------------------------------------------------------------
# @emlDrawAxes
# Draws complete axes with box, aligned ticks, labels, and title
# Arguments: xMin, xMax, yMin, yMax, xLabel$, yLabel$, title$, vpWidth, vpHeight
# Ticks are placed at nice-number positions matching @emlDrawGridlines
# Call after all data drawing
# ----------------------------------------------------------------------------
procedure emlDrawAxes: .xMin, .xMax, .yMin, .yMax, .xLabel$, .yLabel$, .title$, .vpWidth, .vpHeight
    # Sanitize title only — axis labels are sanitized at generation
    # (auto labels via @emlCapitalizeLabel) or passed raw (user-typed,
    # which may contain intentional Praat formatting codes)
    @emlSanitizeLabel: .title$
    .title$ = emlSanitizeLabel.result$

    @emlSetAdaptiveTheme: .vpWidth, .vpHeight

    Font size: emlSetAdaptiveTheme.bodySize

    # Box
    @emlDrawInnerBoxIf

    # --- Y-axis (left) ticks ---
    @emlDrawAlignedMarksLeft: .yMin, .yMax,
    ... emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks

    # --- X-axis (bottom) ticks ---
    @emlDrawAlignedMarksBottom: .xMin, .xMax,
    ... emlSetAdaptiveTheme.targetTicksX, emlSetAdaptiveTheme.useMinorTicks

    # Axis labels (gated by per-axis name visibility)
    Colour: emlSetAdaptiveTheme.textColor$
    if emlShowAxisNameX and .xLabel$ <> ""
        Text bottom: "yes", .xLabel$
    endif
    if emlShowAxisNameY and .yLabel$ <> ""
        Text left: "yes", .yLabel$
    endif

    # Title and subtitle
    @emlDrawTitle: .title$, .vpWidth, .vpHeight, .xMin, .xMax, .yMin, .yMax

    Colour: "Black"
    Font size: emlSetAdaptiveTheme.bodySize
endproc

# ----------------------------------------------------------------------------
# @emlDrawAxesSelective
# Draws axes with selective element display (for panel grids)
# Arguments: xMin, xMax, yMin, yMax, xLabel$, yLabel$, title$,
#            vpWidth, vpHeight, showXLabel, showYLabel, showXTicks, showYTicks
# showXLabel, showYLabel, showXTicks, showYTicks are 0 or 1
# ----------------------------------------------------------------------------
procedure emlDrawAxesSelective: .xMin, .xMax, .yMin, .yMax, .xLabel$, .yLabel$, .title$, .vpWidth, .vpHeight, .showXLabel, .showYLabel, .showXTicks, .showYTicks
    # Sanitize title only — axis labels handled at generation
    @emlSanitizeLabel: .title$
    .title$ = emlSanitizeLabel.result$

    @emlSetAdaptiveTheme: .vpWidth, .vpHeight

    Font size: emlSetAdaptiveTheme.bodySize

    # Box
    @emlDrawInnerBoxIf

    # Conditional Y-axis ticks
    if .showYTicks
        @emlDrawAlignedMarksLeft: .yMin, .yMax,
        ... emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks
    endif

    # Conditional X-axis ticks
    if .showXTicks
        @emlDrawAlignedMarksBottom: .xMin, .xMax,
        ... emlSetAdaptiveTheme.targetTicksX, emlSetAdaptiveTheme.useMinorTicks
    endif

    # Conditional labels
    Colour: emlSetAdaptiveTheme.textColor$
    if .showXLabel
        Text bottom: "yes", .xLabel$
    endif
    if .showYLabel
        Text left: "yes", .yLabel$
    endif

    # Title
    if .title$ <> ""
        Font size: emlSetAdaptiveTheme.titleSize
        Text top: "yes", .title$
    endif

    Colour: "Black"
    Font size: emlSetAdaptiveTheme.bodySize
endproc


# ============================================================================
# LABEL DERIVATION — UNIT/ACRONYM TOKENS (D73) AND OVERRIDES (D90)
# ============================================================================
# @emlCapitalizeLabel used to do exactly two things: underscore→space, and
# uppercase the first character. That is Rule 28B and nothing else, so
# `SPL_dB` came out as `SPL dB` (unit not parenthesised, Rule 28C unmet) and
# any column whose unit was written in lower case lost its casing the moment
# a caller title-cased the result. The tables below are the whole heuristic:
# adding a unit is a one-line edit to emlLabelUnitMap$, adding an acronym a
# one-line edit to emlLabelAcronymMap$. No chain of ifs.
#
# Format: "|<lowercased token>:<canonical form>|" — the leading and trailing
# bars are load-bearing, @emlLookupLabelToken searches for "|token:".
#
# UNIT tokens are, in addition, lifted into a trailing parenthesis when they
# are the LAST underscore-separated token of a multi-token name:
#   F0_Hz        → F0 (Hz)
#   SPL_dB       → SPL (dB)
#   jitter_pct   → Jitter (%)
# ACRONYM tokens are only case-corrected; they name a quantity, not a unit,
# so they are never parenthesised:
#   mean_spl     → Mean SPL
#   f0_sd        → F0 SD
# Anything unrecognised falls through to the previous behaviour.
# ============================================================================
emlLabelUnitMap$ = "|hz:Hz|khz:kHz|db:dB|dba:dBA|ms:ms|s:s|pct:%|percent:%|"
emlLabelAcronymMap$ = "|spl:SPL|hnr:HNR|f0:F0|f1:F1|f2:F2|f3:F3|cpp:CPP|cpps:CPPS|sd:SD|se:SE|ci:CI|n:N|"

# D90: axis labels are derived from column names, and a wide→long reshape
# hands the graph layer the reshape's own role names — `Subject`, `Condition`,
# `Value` — so a repeated-measures figure's y-axis reads "Value" instead of
# naming the measured quantity. The override table lets a caller that KNOWS
# the real measure register it against the role name; every existing
# @emlCapitalizeLabel call site then picks it up with no change.
emlLabelOverrideN = 0

# ----------------------------------------------------------------------------
# @emlEnsureLabelTables
# Defines the label tables if this file's top-level block has not run in the
# current interpreter (same defensive pattern as the panel-origin guard).
# ----------------------------------------------------------------------------
procedure emlEnsureLabelTables
    if not variableExists ("emlLabelUnitMap$")
        emlLabelUnitMap$ = "|hz:Hz|khz:kHz|db:dB|dba:dBA|ms:ms|s:s|pct:%|percent:%|"
    endif
    if not variableExists ("emlLabelAcronymMap$")
        emlLabelAcronymMap$ = "|spl:SPL|hnr:HNR|f0:F0|f1:F1|f2:F2|f3:F3|cpp:CPP|cpps:CPPS|sd:SD|se:SE|ci:CI|n:N|"
    endif
    if not variableExists ("emlLabelOverrideN")
        emlLabelOverrideN = 0
    endif
endproc

# ----------------------------------------------------------------------------
# @emlClearLabelOverrides
# Drops every registered axis-label override. A wrapper that registers
# overrides is responsible for clearing them once its figure is drawn —
# overrides are keyed by column name and would otherwise leak into the next
# graph drawn in the same session.
# ----------------------------------------------------------------------------
procedure emlClearLabelOverrides
    emlLabelOverrideN = 0
endproc

# ----------------------------------------------------------------------------
# @emlSetLabelOverride
# Registers a display label for a column name. Re-registering a column
# replaces its entry rather than shadowing it.
# Arguments: colName$ (the column name as it appears in the Table),
#            display$ (what the axis should say; "" removes nothing, it is
#                      simply ignored at lookup time)
# ----------------------------------------------------------------------------
procedure emlSetLabelOverride: .colName$, .display$
    @emlEnsureLabelTables
    .slot = 0
    for .i from 1 to emlLabelOverrideN
        if emlLabelOverrideCol$[.i] = .colName$
            .slot = .i
        endif
    endfor
    if .slot = 0
        emlLabelOverrideN = emlLabelOverrideN + 1
        .slot = emlLabelOverrideN
    endif
    emlLabelOverrideCol$[.slot] = .colName$
    emlLabelOverrideText$[.slot] = .display$
endproc

# ----------------------------------------------------------------------------
# @emlLookupLabelOverride
# Arguments: colName$
# Outputs: .found (0/1), .result$ (the registered display label)
# ----------------------------------------------------------------------------
procedure emlLookupLabelOverride: .colName$
    @emlEnsureLabelTables
    .found = 0
    .result$ = ""
    for .i from 1 to emlLabelOverrideN
        if .found = 0
            if emlLabelOverrideCol$[.i] = .colName$
                if emlLabelOverrideText$[.i] <> ""
                    .found = 1
                    .result$ = emlLabelOverrideText$[.i]
                endif
            endif
        endif
    endfor
endproc

# ----------------------------------------------------------------------------
# @emlLookupLabelToken
# Case-insensitive exact-token lookup in one of the maps above.
# Arguments: map$ (emlLabelUnitMap$ or emlLabelAcronymMap$), token$
# Outputs: .found (0/1), .result$ (canonical form)
# ----------------------------------------------------------------------------
procedure emlLookupLabelToken: .map$, .token$
    .found = 0
    .result$ = ""
    if .token$ <> ""
        .key$ = "|" + replace_regex$ (.token$, "(.*)", "\L\1", 0) + ":"
        .at = index (.map$, .key$)
        if .at > 0
            .from = .at + length (.key$)
            .tail$ = right$ (.map$, length (.map$) - .from + 1)
            .end = index (.tail$, "|")
            if .end > 1
                .found = 1
                .result$ = left$ (.tail$, .end - 1)
            endif
        endif
    endif
endproc

# ----------------------------------------------------------------------------
# @emlFormatLabelTokens
# The heuristic itself, with no override lookup — split on underscores,
# canonicalise every recognised token, lift a trailing unit into a
# parenthesis, capitalise the leading word if it was not a recognised token,
# then sanitize.
# Arguments: raw$
# Outputs: .result$
# ----------------------------------------------------------------------------
procedure emlFormatLabelTokens: .raw$
    @emlEnsureLabelTables
    .work$ = .raw$
    .nTok = 0
    while .work$ <> ""
        .at = index (.work$, "_")
        if .at > 0
            .tok$ = left$ (.work$, .at - 1)
            .work$ = right$ (.work$, length (.work$) - .at)
        else
            .tok$ = .work$
            .work$ = ""
        endif
        if .tok$ <> ""
            .nTok = .nTok + 1
            emlLabelTok$[.nTok] = .tok$
        endif
    endwhile

    # Trailing unit token → parenthesised unit (Rule 28C). Requires at least
    # two tokens: a column named just "hz" has no measure to attach a unit to,
    # so it is only case-corrected.
    .unit$ = ""
    if .nTok >= 2
        @emlLookupLabelToken: emlLabelUnitMap$, emlLabelTok$[.nTok]
        if emlLookupLabelToken.found
            .unit$ = emlLookupLabelToken.result$
            .nTok = .nTok - 1
        endif
    endif

    .out$ = ""
    for .i from 1 to .nTok
        .tok$ = emlLabelTok$[.i]
        @emlLookupLabelToken: emlLabelUnitMap$, .tok$
        if emlLookupLabelToken.found
            .tok$ = emlLookupLabelToken.result$
        else
            @emlLookupLabelToken: emlLabelAcronymMap$, .tok$
            if emlLookupLabelToken.found
                .tok$ = emlLookupLabelToken.result$
            elsif .i = 1
                # ASCII lowercase a-z (97-122) → uppercase A-Z (65-90)
                .code = unicode (left$ (.tok$, 1))
                if .code >= 97 and .code <= 122
                    .code = .code - 32
                endif
                .tok$ = unicode$ (.code) + right$ (.tok$, length (.tok$) - 1)
            endif
        endif
        if .i = 1
            .out$ = .tok$
        else
            .out$ = .out$ + " " + .tok$
        endif
    endfor

    if .unit$ <> ""
        if .out$ = ""
            .out$ = .unit$
        else
            .out$ = .out$ + " (" + .unit$ + ")"
        endif
    endif

    # Sanitize special characters (%, #, ^, _) — auto-generated labels from
    # column names should never contain Praat markup. User-typed labels
    # bypass this procedure entirely. Note that "%" survives as "\% ", which
    # Praat renders as a literal percent sign with the escape consuming the
    # trailing space, so "(%)" comes out as "(%)".
    @emlSanitizeLabel: .out$
    .result$ = emlSanitizeLabel.result$
endproc

# ----------------------------------------------------------------------------
# @emlCapitalizeLabel
# Converts a column name to a display label. Consults the D90 override table
# first, then applies the D73 unit/acronym heuristic.
# Arguments: raw$ (the raw column name)
# Outputs: .result$ (the formatted label)
# ----------------------------------------------------------------------------
procedure emlCapitalizeLabel: .raw$
    @emlLookupLabelOverride: .raw$
    if emlLookupLabelOverride.found
        @emlFormatLabelTokens: emlLookupLabelOverride.result$
    else
        @emlFormatLabelTokens: .raw$
    endif
    .result$ = emlFormatLabelTokens.result$
endproc

# ----------------------------------------------------------------------------
# @emlDeriveAxisLabel
# D90: the explicit form of the override. Where @emlCapitalizeLabel takes the
# override from the registry, this takes it as an argument, for a caller that
# has the real measure name in hand at the call site.
# Arguments: rawCol$ (column name), override$ ("" = derive from rawCol$)
# Outputs: .result$
# ----------------------------------------------------------------------------
procedure emlDeriveAxisLabel: .rawCol$, .override$
    if .override$ <> ""
        @emlFormatLabelTokens: .override$
        .result$ = emlFormatLabelTokens.result$
    else
        @emlCapitalizeLabel: .rawCol$
        .result$ = emlCapitalizeLabel.result$
    endif
endproc

# ----------------------------------------------------------------------------
# @emlCommonMeasureLabel
# D90 helper for the wide→long reshapes. Given the two (or more) wide column
# names that became one long `Value` column, returns the measure they share,
# so the wrapper can register it as the y-axis override in one line:
#   jitter_pre, jitter_post           → jitter
#   f0_hz_pre,  f0_hz_post            → f0_hz
#   pre_jitter_pct, post_jitter_pct   → jitter_pct   (shared suffix)
#   spl_dB, hnr                       → ""           (nothing shared)
# Arguments: colA$, colB$
# Outputs: .stem$ (raw, underscore-separated; "" when nothing is shared),
#          .result$ (.stem$ run through the D73 heuristic; "" when no stem)
# ----------------------------------------------------------------------------
procedure emlCommonMeasureLabel: .colA$, .colB$
    .stem$ = ""

    # Shared leading tokens
    .a$ = .colA$
    .b$ = .colB$
    .more = 1
    while .more = 1
        .ia = index (.a$, "_")
        .ib = index (.b$, "_")
        if .ia > 0 and .ib > 0
            .ta$ = left$ (.a$, .ia - 1)
            .tb$ = left$ (.b$, .ib - 1)
            if .ta$ = .tb$ and .ta$ <> ""
                if .stem$ = ""
                    .stem$ = .ta$
                else
                    .stem$ = .stem$ + "_" + .ta$
                endif
                .a$ = right$ (.a$, length (.a$) - .ia)
                .b$ = right$ (.b$, length (.b$) - .ib)
            else
                .more = 0
            endif
        else
            .more = 0
        endif
    endwhile

    # Shared trailing tokens, only if nothing was shared at the front
    if .stem$ = ""
        .a$ = .colA$
        .b$ = .colB$
        .more = 1
        while .more = 1
            .ia = rindex (.a$, "_")
            .ib = rindex (.b$, "_")
            if .ia > 0 and .ib > 0
                .ta$ = right$ (.a$, length (.a$) - .ia)
                .tb$ = right$ (.b$, length (.b$) - .ib)
                if .ta$ = .tb$ and .ta$ <> ""
                    if .stem$ = ""
                        .stem$ = .ta$
                    else
                        .stem$ = .ta$ + "_" + .stem$
                    endif
                    .a$ = left$ (.a$, .ia - 1)
                    .b$ = left$ (.b$, .ib - 1)
                else
                    .more = 0
                endif
            else
                .more = 0
            endif
        endwhile
    endif

    if .stem$ = ""
        .result$ = ""
    else
        @emlFormatLabelTokens: .stem$
        .result$ = emlFormatLabelTokens.result$
    endif
endproc

# ----------------------------------------------------------------------------
# @emlPaintSmoothBand
# Paints interpolated confidence/SD band for smooth appearance
# Requires global arrays before call: bandX#, bandLower#, bandUpper#
# Arguments: fillColor$, subsamples (interpolation points per segment, typically 5)
# ----------------------------------------------------------------------------
procedure emlPaintSmoothBand: .fillColor$, .subsamples
    .n = size (bandX#)

    for .i from 1 to .n - 1
        .xStart = bandX#[.i]
        .xEnd = bandX#[.i + 1]
        .xStep = (.xEnd - .xStart) / .subsamples

        for .j from 0 to .subsamples - 1
            .t = .j / .subsamples
            .tNext = (.j + 1) / .subsamples
            .xLeft = .xStart + .j * .xStep
            .xRight = .xStart + (.j + 1) * .xStep

            # Interpolate bounds
            .yLowerLeft = bandLower#[.i] * (1 - .t) + bandLower#[.i + 1] * .t
            .yUpperLeft = bandUpper#[.i] * (1 - .t) + bandUpper#[.i + 1] * .t
            .yLowerRight = bandLower#[.i] * (1 - .tNext) + bandLower#[.i + 1] * .tNext
            .yUpperRight = bandUpper#[.i] * (1 - .tNext) + bandUpper#[.i + 1] * .tNext
            .yLower = (.yLowerLeft + .yLowerRight) / 2
            .yUpper = (.yUpperLeft + .yUpperRight) / 2

            Paint rectangle: .fillColor$, .xLeft, .xRight, .yLower, .yUpper
        endfor
    endfor
endproc

# ----------------------------------------------------------------------------
# @emlDrawViolin
# Draws smooth violin plot with kernel density estimation and quartile box
# Arguments: xCenter, data#, fillColor$, lineColor$, axisYMin, axisYMax, width
# axisYMin/axisYMax: axis bounds for clipping (prevents drawing outside frame)
# width: half-width of the violin in x-units (typically 0.35)
# Output (v3.22): .nSkipped = observations dropped because they were undefined
#
# v3.22: undefined observations are now skipped during the fallback draw and
# detected before the KDE runs. Previously "if .sd = 0" was the only validity
# gate; an undefined element in .data# makes .mean and .sd undefined, that
# comparison is FALSE, and the undefined bandwidth propagates into
# Paint rectangle:, which aborts the entire figure with a hard error.
# ----------------------------------------------------------------------------
procedure emlDrawViolin: .xCenter, .data#, .fillColor$, .lineColor$, .axisYMin, .axisYMax, .width
    .n = size (.data#)
    .nSkipped = 0

    # Guard: need at least 4 observations for meaningful violin + quartile box
    if .n < 4
        # Fallback: draw individual data points as short horizontal marks
        Colour: .lineColor$
        Line width: 1.5
        for .i from 1 to .n
            .pt = .data#[.i]
            if .pt <> undefined
                Draw line: .xCenter - .width * 0.3, .pt, .xCenter + .width * 0.3, .pt
            else
                .nSkipped = .nSkipped + 1
            endif
        endfor
        Colour: "Black"
        Line width: 1.0
        # Skip rest of procedure via early structure
        goto VIOLIN_END
    endif

    # v3.22: reject undefined observations before any statistic is computed.
    # A single undefined element poisons .mean, .sd and .bandwidth, and every
    # subsequent comparison against those values evaluates FALSE, so no
    # existing guard catches it.
    for .i from 1 to .n
        if .data#[.i] = undefined
            .nSkipped = .nSkipped + 1
        endif
    endfor
    if .nSkipped > 0
        goto VIOLIN_END
    endif

    .dataMin = min (.data#)
    .dataMax = max (.data#)

    # Compute mean and SD for bandwidth
    .mean = 0
    for .i from 1 to .n
        .mean = .mean + .data#[.i]
    endfor
    .mean = .mean / .n

    .variance = 0
    for .i from 1 to .n
        .variance = .variance + (.data#[.i] - .mean) ^ 2
    endfor
    .sd = sqrt (.variance / (.n - 1))

    # v3.22: belt-and-braces. Overflow in the sum-of-squares can still yield a
    # non-finite .sd; bail out rather than feed it to the KDE.
    if .sd = undefined
        goto VIOLIN_END
    endif

    # Guard: if SD is zero (all identical values), draw a horizontal line
    if .sd = 0
        Colour: .lineColor$
        Line width: 1.5
        Draw line: .xCenter - .width * 0.6, .mean, .xCenter + .width * 0.6, .mean
        Colour: "Black"
        Line width: 1.0
        goto VIOLIN_END
    endif

    # Silverman bandwidth
    .bandwidth = 0.9 * .sd * .n ^ (-0.2)

    # Extended evaluation range for smooth tails
    .evalMin = .dataMin - .bandwidth
    .evalMax = .dataMax + .bandwidth

    # High resolution for smooth fill (500 slices eliminates visible banding
    # at typical viewport sizes; each slice < 1 device pixel)
    .nEvalFill = 500
    .evalStepFill = (.evalMax - .evalMin) / (.nEvalFill - 1)

    # Find max density for scaling
    .maxDensity = 0
    for .e from 1 to .nEvalFill
        .y = .evalMin + (.e - 1) * .evalStepFill
        .density = 0
        for .i from 1 to .n
            .u = (.y - .data#[.i]) / .bandwidth
            .density = .density + exp (-0.5 * .u * .u)
        endfor
        .density = .density / (.n * .bandwidth * sqrt (2 * pi))
        if .density > .maxDensity
            .maxDensity = .density
        endif
    endfor

    # Scale factor
    .violinWidth = .width
    .scaleFactor = .violinWidth / .maxDensity

    # === FILL (clipped to axis bounds) ===
    # Sub-pixel overlap (0.5 step) between adjacent slices prevents
    # gap artifacts from coordinate rounding. Fill is opaque, so
    # overlap is invisible — eliminates banding.
    .overlapMargin = .evalStepFill * 0.5
    for .e from 1 to .nEvalFill - 1
        .y1 = .evalMin + (.e - 1) * .evalStepFill
        .y2 = .evalMin + .e * .evalStepFill
        .yMid = (.y1 + .y2) / 2

        .d = 0
        for .i from 1 to .n
            .u = (.yMid - .data#[.i]) / .bandwidth
            .d = .d + exp (-0.5 * .u * .u)
        endfor
        .d = .d / (.n * .bandwidth * sqrt (2 * pi)) * .scaleFactor

        # Clamp fill rectangle to axis bounds with sub-pixel overlap
        .drawY1 = max (.y1 - .overlapMargin, .axisYMin)
        .drawY2 = min (.y2 + .overlapMargin, .axisYMax)
        if .drawY1 < .drawY2
            Paint rectangle: .fillColor$, .xCenter - .d, .xCenter + .d, .drawY1, .drawY2
        endif
    endfor

    # === OUTLINE ===
    .nEvalLine = 80
    .evalStepLine = (.evalMax - .evalMin) / (.nEvalLine - 1)

    # Compute densities for outline
    for .e from 1 to .nEvalLine
        .y'.e' = .evalMin + (.e - 1) * .evalStepLine
        .d'.e' = 0
        for .i from 1 to .n
            .u = (.y'.e' - .data#[.i]) / .bandwidth
            .d'.e' = .d'.e' + exp (-0.5 * .u * .u)
        endfor
        .d'.e' = .d'.e' / (.n * .bandwidth * sqrt (2 * pi)) * .scaleFactor
    endfor

    # Draw connected outline (clipped to axis bounds)
    Colour: .lineColor$
    Line width: 1.0

    for .e from 1 to .nEvalLine - 1
        .eNext = .e + 1

        # Clamp y values to axis bounds for outline
        .cy1 = max (.y'.e', .axisYMin)
        .cy1 = min (.cy1, .axisYMax)
        .cy2 = max (.y'.eNext', .axisYMin)
        .cy2 = min (.cy2, .axisYMax)

        # Only draw if at least one point is within bounds
        if .y'.e' <= .axisYMax and .y'.eNext' >= .axisYMin
            .x1 = .xCenter - .d'.e'
            .x2 = .xCenter - .d'.eNext'
            Draw line: .x1, .cy1, .x2, .cy2

            .x1 = .xCenter + .d'.e'
            .x2 = .xCenter + .d'.eNext'
            Draw line: .x1, .cy1, .x2, .cy2
        endif
    endfor

    # Close top and bottom (only if within bounds)
    if .y'.nEvalLine' >= .axisYMin and .y'.nEvalLine' <= .axisYMax
        Draw line: .xCenter - .d'.nEvalLine', .y'.nEvalLine', .xCenter + .d'.nEvalLine', .y'.nEvalLine'
    endif
    if .y1 >= .axisYMin and .y1 <= .axisYMax
        Draw line: .xCenter - .d1, .y1, .xCenter + .d1, .y1
    endif

    # === QUARTILE BOX (clipped to axis bounds) ===
    .sorted# = .data#
    for .i from 1 to .n - 1
        for .j from 1 to .n - .i
            if .sorted#[.j] > .sorted#[.j + 1]
                .temp = .sorted#[.j]
                .sorted#[.j] = .sorted#[.j + 1]
                .sorted#[.j + 1] = .temp
            endif
        endfor
    endfor

    # Quartiles via the shared R-7 interpolated procedure (matches the
    # numeric describe layer). The old nearest-rank floor(n*p) biased the
    # median low and collapsed it onto the minimum at small n.
    @emlQuartiles: .data#
    .q1 = emlQuartiles.q1
    .median = emlQuartiles.q2
    .q3 = emlQuartiles.q3

    # Clamp quartile box to axis bounds
    .drawQ1 = max (.q1, .axisYMin)
    .drawQ3 = min (.q3, .axisYMax)

    .boxWidth = .width * 0.143
    if .drawQ1 < .drawQ3
        Paint rectangle: "White", .xCenter - .boxWidth, .xCenter + .boxWidth, .drawQ1, .drawQ3
        Colour: .lineColor$
        Line width: 0.8
        Draw rectangle: .xCenter - .boxWidth, .xCenter + .boxWidth, .drawQ1, .drawQ3
    endif

    # Median line (only if within bounds)
    if .median >= .axisYMin and .median <= .axisYMax
        Line width: 1.5
        Colour: .lineColor$
        Draw line: .xCenter - .boxWidth, .median, .xCenter + .boxWidth, .median
    endif

    Colour: "Black"
    Line width: 1.0

    label VIOLIN_END
endproc


# ----------------------------------------------------------------------------
# @emlDrawBox
# Draws a single box-and-whisker plot at a categorical x-position.
# Uses Tukey whiskers (1.5*IQR) with outlier dots beyond fences.
# Arguments:
#   .xCenter    — categorical x-position
#   .data#      — numeric data vector for this group
#   .fillColor$ — RGB fill for box body
#   .lineColor$ — RGB stroke for box, whiskers, and outliers
#   .axisYMin   — y-axis lower bound for clipping
#   .axisYMax   — y-axis upper bound for clipping
#   .width      — half-width of box body in x-units
# Outputs:
#   .q1Out, .medianOut, .q3Out — quartile values
#   .whiskerLowOut, .whiskerHighOut — Tukey whisker endpoints
#   .nSkipped — observations dropped because they were undefined (v3.22)
#
# v3.22: every existing "guard" in this procedure is a relational comparison
# (.drawQ1 < .drawQ3, .median >= .axisYMin, ...). All of those are FALSE when
# the operand is undefined, so an undefined element in .data# silently
# suppressed the entire box with no disclosure — and on the .n = 1 path it
# reached Draw line: with an undefined y and aborted the figure. Undefined
# observations are now detected up front and reported through .nSkipped.
# ----------------------------------------------------------------------------
procedure emlDrawBox: .xCenter, .data#, .fillColor$, .lineColor$, .axisYMin, .axisYMax, .width
    .n = size (.data#)
    .nSkipped = 0

    # Guard: need at least 1 observation
    if .n < 1
        goto BOX_END
    endif

    # v3.22: undefined observations poison the sort, the quartiles and the
    # Tukey fences. Detect them before anything is drawn.
    for .i from 1 to .n
        if .data#[.i] = undefined
            .nSkipped = .nSkipped + 1
        endif
    endfor
    if .nSkipped > 0
        goto BOX_END
    endif

    # Single point: draw a horizontal mark
    if .n = 1
        Colour: .lineColor$
        Line width: 1.5
        Draw line: .xCenter - .width, .data#[1], .xCenter + .width, .data#[1]
        Colour: "Black"
        Line width: 1.0
        goto BOX_END
    endif

    # Sort data (bubble sort — fine for per-group sizes)
    .sorted# = .data#
    for .i from 1 to .n - 1
        for .j from 1 to .n - .i
            if .sorted#[.j] > .sorted#[.j + 1]
                .temp = .sorted#[.j]
                .sorted#[.j] = .sorted#[.j + 1]
                .sorted#[.j + 1] = .temp
            endif
        endfor
    endfor

    # Five-number summary — quartiles via the shared R-7 interpolated
    # procedure (matches the numeric describe layer). The old nearest-rank
    # floor(n*p) biased Q1/median/Q3 low, which also shifted the Tukey fences.
    @emlQuartiles: .data#
    .q1 = emlQuartiles.q1
    .median = emlQuartiles.q2
    .q3 = emlQuartiles.q3
    .iqr = .q3 - .q1

    # Tukey fences
    .lowerFence = .q1 - 1.5 * .iqr
    .upperFence = .q3 + 1.5 * .iqr

    # Whisker endpoints: furthest non-outlier data points
    .whiskerLow = .sorted#[1]
    for .i from 1 to .n
        if .sorted#[.i] >= .lowerFence
            .whiskerLow = .sorted#[.i]
            goto BOX_FOUND_LOW
        endif
    endfor
    label BOX_FOUND_LOW

    .whiskerHigh = .sorted#[.n]
    for .i from 1 to .n
        if .sorted#[.i] <= .upperFence
            .whiskerHigh = .sorted#[.i]
        endif
    endfor

    # Clamp drawing to axis bounds
    .drawQ1 = max (.q1, .axisYMin)
    .drawQ3 = min (.q3, .axisYMax)
    .drawWhiskerLow = max (.whiskerLow, .axisYMin)
    .drawWhiskerHigh = min (.whiskerHigh, .axisYMax)

    .capW = .width * 0.6

    # === FILL BOX (Q1-Q3) ===
    if .drawQ1 < .drawQ3
        Paint rectangle: .fillColor$, .xCenter - .width, .xCenter + .width, .drawQ1, .drawQ3
    endif

    # === BOX OUTLINE ===
    Colour: .lineColor$
    Line width: 0.8
    if .drawQ1 < .drawQ3
        Draw rectangle: .xCenter - .width, .xCenter + .width, .drawQ1, .drawQ3
    endif

    # === MEDIAN LINE ===
    if .median >= .axisYMin and .median <= .axisYMax
        Line width: 1.8
        Draw line: .xCenter - .width, .median, .xCenter + .width, .median
    endif

    # === WHISKER LINES + CAPS ===
    Line width: 0.8

    # Lower whisker
    if .drawWhiskerLow < .drawQ1 and .drawWhiskerLow >= .axisYMin
        Draw line: .xCenter, .drawQ1, .xCenter, .drawWhiskerLow
        Draw line: .xCenter - .capW, .drawWhiskerLow, .xCenter + .capW, .drawWhiskerLow
    endif

    # Upper whisker
    if .drawWhiskerHigh > .drawQ3 and .drawWhiskerHigh <= .axisYMax
        Draw line: .xCenter, .drawQ3, .xCenter, .drawWhiskerHigh
        Draw line: .xCenter - .capW, .drawWhiskerHigh, .xCenter + .capW, .drawWhiskerHigh
    endif

    # === OUTLIER DOTS ===
    .outlierRadius = .width * 0.2
    for .i from 1 to .n
        if .sorted#[.i] < .lowerFence or .sorted#[.i] > .upperFence
            if .sorted#[.i] >= .axisYMin and .sorted#[.i] <= .axisYMax
                Draw circle: .xCenter, .sorted#[.i], .outlierRadius
            endif
        endif
    endfor

    # === EXPOSE QUARTILE VALUES ===
    .q1Out = .q1
    .medianOut = .median
    .q3Out = .q3
    .whiskerLowOut = .whiskerLow
    .whiskerHighOut = .whiskerHigh

    # Reset state
    Colour: "Black"
    Line width: 1.0

    label BOX_END
endproc


# ----------------------------------------------------------------------------
# @emlSanitizeLabel
# Escapes Praat text-rendering special characters (%, #, ^, _) so they
# display as literal characters instead of triggering style toggles.
# Also converts underscores to spaces for display-friendly labels.
# Arguments: raw$ (the raw string, e.g., a column name or user input)
# Outputs: .result$ (the sanitized string safe for Text: commands)
#
# NOTE: Call this on ANY string that will be passed to Text:, Text left:,
# Text bottom:, Text top:, or One mark: commands — unless you intentionally
# want style formatting.
# ----------------------------------------------------------------------------
procedure emlSanitizeLabel: .raw$
    # First convert underscores to spaces (display-friendly)
    .result$ = replace$ (.raw$, "_", " ", 0)
    # Then escape any remaining special characters
    # Order matters: % first because \% contains no other specials
    .result$ = replace$ (.result$, "%", "\% ", 0)
    .result$ = replace$ (.result$, "#", "\# ", 0)
    .result$ = replace$ (.result$, "^", "\^ ", 0)
    # Note: _ already converted to space above, but if someone passes
    # a string where underscores should be literal underscores (rare),
    # they would need a separate procedure.
endproc

# ----------------------------------------------------------------------------
# @emlDrawJitteredPoints
# Draws individual data points with horizontal jitter at a categorical
# x-position. Prevents point overlap in strip plots, overlaid on box/violin.
# Requires global array before call: jitterData# (the y-values to plot)
# Arguments: xCenter, lineColor$, markerSize, jitterWidth
#   xCenter: the categorical x-position (e.g., 1, 2, 3)
#   lineColor$: RGB colour string for the points
#   markerSize: point diameter in mm
#   jitterWidth: half-width of jitter range (e.g., 0.12 for ±0.12)
# Outputs: .nSkipped — points dropped because the y-value was undefined (v3.22)
#
# v3.22: this loop had no validity check at all — an undefined element in
# jitterData# went straight into Draw line: and aborted the figure with a
# hard error. Undefined points are now skipped and counted.
# ----------------------------------------------------------------------------
procedure emlDrawJitteredPoints: .xCenter, .lineColor$, .markerSize, .jitterWidth
    .n = size (jitterData#)
    .nSkipped = 0
    Colour: .lineColor$

    # Loop-invariant: half-length of the cross mark in world units
    .halfMark = .markerSize * 0.003

    for .i from 1 to .n
        .yPlot = jitterData#[.i]
        if .yPlot <> undefined
            .jitter = randomUniform (-.jitterWidth, .jitterWidth)
            .xPlot = .xCenter + .jitter

            # Draw as small cross mark
            Draw line: .xPlot, .yPlot - .halfMark, .xPlot, .yPlot + .halfMark
            Draw line: .xPlot - .halfMark, .yPlot, .xPlot + .halfMark, .yPlot
        else
            .nSkipped = .nSkipped + 1
        endif
    endfor

    Colour: "Black"
endproc

# ----------------------------------------------------------------------------
# @emlAssertFullViewport
# Selects the full outer viewport encompassing everything drawn since
# the last @emlResetDrawnExtent. Call before Save as ... PNG/PDF file:.
# No arguments — reads tracked bounding box from @emlSetAdaptiveTheme.
# Uses raw Select outer viewport: (not offset by panel origin, since
# this operates at figure level, not panel level).
# ----------------------------------------------------------------------------
procedure emlAssertFullViewport
    Select outer viewport: emlDrawnMinX, emlDrawnMaxX,
    ... emlDrawnMinY, emlDrawnMaxY
endproc

# ----------------------------------------------------------------------------
# @emlApplyChannelChoice
# Mechanical core for stereo channel handling. Applies a pre-selected
# channel handling choice without presenting any UI. For batch scripts
# where the choice is made once in the settings dialog.
# Arguments: .soundId (the Sound object ID)
#            .channelHandling (1 = Mix to mono, 2 = Left channel,
#                              3 = Right channel)
# Outputs: .resultId (the resulting Sound ID — may be same or new)
#          .wasConverted (1 if conversion happened, 0 if already mono)
# Note: Removes the original stereo Sound if conversion occurs.
# ----------------------------------------------------------------------------
procedure emlApplyChannelChoice: .soundId, .channelHandling
    selectObject: .soundId
    .nChannels = Get number of channels
    if .nChannels > 1
        if .channelHandling = 1
            .resultId = Convert to mono
        elsif .channelHandling = 2
            .resultId = Extract one channel: 1
        elsif .channelHandling = 3
            .resultId = Extract one channel: 2
        else
            # Fallback — treat unknown value as mix to mono
            .resultId = Convert to mono
        endif
        removeObject: .soundId
        .wasConverted = 1
    else
        .resultId = .soundId
        .wasConverted = 0
    endif
endproc

# ----------------------------------------------------------------------------
# @emlHandleStereo
# UI wrapper for single-file stereo handling. Checks channel count; if
# stereo, presents a beginPause dialog asking the user how to handle it.
# If mono, passes through silently.
# Arguments: .soundId (the Sound object ID)
#            .fileName$ (display name shown in the dialog)
# Outputs: .resultId (the resulting Sound ID — may be same or new)
#          .wasConverted (1 if conversion happened, 0 if already mono)
# Note: Removes the original stereo Sound if conversion occurs.
#       Calls @emlApplyChannelChoice for the mechanical work.
# ----------------------------------------------------------------------------
procedure emlHandleStereo: .soundId, .fileName$
    selectObject: .soundId
    .nChannels = Get number of channels
    if .nChannels > 1
        beginPause: "Stereo file detected"
            comment: "The file """ + .fileName$ + """ has "
            ... + string$ (.nChannels) + " channels."
            optionmenu: "Channel handling", 1
                option: "Mix to mono"
                option: "Left channel only"
                option: "Right channel only"
        .clicked = endPause: "Quit", "Continue", 2, 0
        if .clicked = 1
            exitScript: "User quit."
        endif
        @emlApplyChannelChoice: .soundId, channel_handling
        .resultId = emlApplyChannelChoice.resultId
        .wasConverted = emlApplyChannelChoice.wasConverted
    else
        .resultId = .soundId
        .wasConverted = 0
    endif
endproc

# ----------------------------------------------------------------------------
# @emlCheckChannels
# Backward-compatible wrapper. Checks channel count and presents a
# dialog if stereo. Thin wrapper around @emlHandleStereo.
# Arguments: .soundId (the Sound object ID)
# Outputs: .resultId (the mono Sound ID — may be same as input or new)
#          .wasConverted (1 if conversion happened, 0 if already mono)
# ----------------------------------------------------------------------------
procedure emlCheckChannels: .soundId
    selectObject: .soundId
    .name$ = selected$ ("Sound")
    @emlHandleStereo: .soundId, .name$
    .resultId = emlHandleStereo.resultId
    .wasConverted = emlHandleStereo.wasConverted
endproc

# ----------------------------------------------------------------------------
# @emlCheckPlausibility
# Checks a measured value against expected bounds and emits a warning
# if outside range. Does nothing if value is undefined.
# Arguments: value, lowerBound, upperBound, measureName$, unit$
# Outputs: .inRange (1 if plausible or undefined, 0 if warning emitted)
# ----------------------------------------------------------------------------
procedure emlCheckPlausibility: .value, .lowerBound, .upperBound, .measureName$, .unit$
    .inRange = 1
    if .value <> undefined
        if .value < .lowerBound or .value > .upperBound
            appendInfoLine: "WARNING: ", .measureName$, " = ",
            ... fixed$ (.value, 2), " ", .unit$,
            ... " — outside expected range (",
            ... fixed$ (.lowerBound, 0), " to ",
            ... fixed$ (.upperBound, 0), " ", .unit$, ")."
            .inRange = 0
        endif
    else
        appendInfoLine: "WARNING: ", .measureName$, " returned undefined."
    endif
endproc

# ----------------------------------------------------------------------------
# @emlDrawLegend
# Draws a legend box with filled background, colored swatches, and labels.
# Positions the legend in a corner of the current plot area using data coords.
#
# Requires global variables before call:
#   legendN          — integer, number of entries (1–6)
#   legendColor$[1..N] — RGB colour strings for each entry
#   legendLabel$[1..N] — text labels for each entry (pre-sanitized if needed)
#
# Arguments:
#   xMin, xMax, yMin, yMax — current axis bounds (data coordinates)
#   position$ — "top-left" or "top-right"
#   fontSize  — font size for legend text (typically bodySize - 1)
#
# Draws: filled white rectangle, thin grey border, colored square swatches,
#   and text labels in axis text color. Leaves Colour as Black and Line width as 1.0.
# Note: Font size is set to fontSize and NOT restored. Caller manages
#   font state after return (e.g., @emlDrawAxes will set its own size).
# ----------------------------------------------------------------------------
procedure emlDrawLegend: .xMin, .xMax, .yMin, .yMax, .position$, .fontSize
    .xRange = .xMax - .xMin
    .yRange = .yMax - .yMin

    # Compute world-per-inch for both axes so all spacing is
    # physically uniform regardless of axis scale differences
    .innerW = emlSetAdaptiveTheme.innerRight - emlSetAdaptiveTheme.innerLeft
    .innerH = emlSetAdaptiveTheme.innerBottom - emlSetAdaptiveTheme.innerTop
    .wpiX = .xRange / .innerW
    .wpiY = .yRange / .innerH

    # All spacing derived from font size (in inches) × world-per-inch
    .fontInch = .fontSize / 72
    .sf = emlSetAdaptiveTheme.spacingFactor
    .lineH = .fontInch * 1.4 * .wpiY
    .xPad = .fontInch * (0.3 + 0.3 * .sf) * .wpiX
    .yPad = .fontInch * (0.3 + 0.2 * .sf) * .wpiY
    .swatchSide = .fontInch * 0.8
    .swatchW = .swatchSide * .wpiX
    .swatchH = .swatchSide * .wpiY
    .insetX = emlSetAdaptiveTheme.boxInsetInches * .wpiX
    .insetY = emlSetAdaptiveTheme.boxInsetInches * .wpiY

    # Measure actual rendered width of longest label (exact, font-aware)
    Font size: .fontSize
    .textWidth = 0
    for .i from 1 to legendN
        .w = Text width (world coordinates): legendLabel$[.i]
        if .w > .textWidth
            .textWidth = .w
        endif
    endfor
    # Safety margin: screen font metrics differ slightly from PNG export
    .textWidth = .textWidth * 1.05

    # Box dimensions
    .totalHeight = .yPad + legendN * .lineH + .yPad
    .totalWidth = .xPad + .swatchW + .xPad + .textWidth + .xPad

    # Anchor position (uniform physical inset from axes)
    if .position$ = "top-right"
        .boxLeft = .xMax - .insetX - .totalWidth
        .boxTop = .yMax - .insetY
    elsif .position$ = "bottom-left"
        .boxLeft = .xMin + .insetX
        .boxTop = .yMin + .insetY + .totalHeight
    elsif .position$ = "bottom-right"
        .boxLeft = .xMax - .insetX - .totalWidth
        .boxTop = .yMin + .insetY + .totalHeight
    else
        # Default: top-left
        .boxLeft = .xMin + .insetX
        .boxTop = .yMax - .insetY
    endif
    .boxRight = .boxLeft + .totalWidth
    .boxBottom = .boxTop - .totalHeight

    # Background fill + border (semi-transparent if sprites available)
    if variableExists ("emlAlphaSpritesInitialized")
        if emlAlphaSpritesInitialized = 1 and emlInitAlphaSprites.available = 1
            .bgFile$ = emlInitAlphaSprites.dir$ + "bg_white_a70_40.png"
            if fileReadable (.bgFile$)
                Insert picture from file: .bgFile$, .boxLeft, .boxRight, .boxBottom, .boxTop
            else
                Paint rectangle: "White", .boxLeft, .boxRight, .boxBottom, .boxTop
            endif
        else
            Paint rectangle: "White", .boxLeft, .boxRight, .boxBottom, .boxTop
        endif
    else
        Paint rectangle: "White", .boxLeft, .boxRight, .boxBottom, .boxTop
    endif
    Colour: "{0.7, 0.7, 0.7}"
    Line width: 0.5
    Draw rectangle: .boxLeft, .boxRight, .boxBottom, .boxTop

    # Entries — filled swatches with axis-colored text labels
    Font size: .fontSize
    for .i from 1 to legendN
        .entryY = .boxTop - .yPad - (.i - 0.5) * .lineH
        .swatchLeft = .boxLeft + .xPad
        .swatchRight = .swatchLeft + .swatchW
        .swatchTop = .entryY + .swatchH / 2
        .swatchBottom = .entryY - .swatchH / 2
        .textX = .swatchRight + .xPad

        Colour: legendColor$[.i]
        Paint rectangle: legendColor$[.i], .swatchLeft, .swatchRight, .swatchBottom, .swatchTop
        Colour: emlSetAdaptiveTheme.textColor$
        Text: .textX, "left", .entryY, "half", legendLabel$[.i]
    endfor

    Colour: "Black"
    Line width: 1.0

    # Restore font size BEFORE viewport — Select inner viewport uses
    # current font size to compute margin widths. Must be bodySize.
    Font size: emlSetAdaptiveTheme.bodySize

    # Restore viewport and axes — Insert picture from file: changes
    # the selected viewport to the image's bounding box, which corrupts
    # all subsequent drawing commands (ticks, labels, inner box).
    Select inner viewport: emlSetAdaptiveTheme.innerLeft,
    ... emlSetAdaptiveTheme.innerRight,
    ... emlSetAdaptiveTheme.innerTop,
    ... emlSetAdaptiveTheme.innerBottom
    Axes: .xMin, .xMax, .yMin, .yMax
endproc

# ----------------------------------------------------------------------------
# @emlCheckNumericColumn
# Tests whether a Table column is safe to feed to number() for plotting.
#
# v3.22: was "sample the first 5 rows, pass if ANY one of them parses" —
# a column whose first five cells happened to be numeric, or that held a
# single numeric cell among text, was declared numeric and every downstream
# draw procedure then aborted or drew garbage. Now: EVERY row is scanned and
# EVERY non-empty cell must parse cleanly.
#
# Cell classification (one of four):
#   missing      — empty or whitespace-only; not a failure, not evidence
#   numeric      — matches a strict decimal/exponent literal AND number()
#                  returns a defined value
#   coerced      — number() returns a value only via a lossy coercion, e.g.
#                  number("5,5")=5, number("30%")=0.3, number("1/2")=1,
#                  number("2 3")=2, number("0x10")=16, number("5x")=5.
#                  These are wrong-number hazards, NOT passes: they are
#                  counted as offending cells and force .isNumeric = 0.
#   non-numeric  — number() is undefined. Note that Praat's number() cannot
#                  parse a leading-dot literal (number(".5") is undefined),
#                  so ".5" lands here even though it looks numeric.
#
# .isNumeric = 1 only when at least one cell is numeric and no cell is
# coerced or non-numeric.
#
# Rows scanned are capped at .maxScanRows (100000) as a safety valve on
# pathological tables; ~37 us/row measured on Praat 6.6.30, so the cap costs
# a few seconds worst case and is far above any plottable table. When the cap
# bites, .truncated = 1 and the verdict rests on the scanned prefix only.
#
# Arguments: .tableId, .colName$
#
# Outputs:
#   .isNumeric        — 0/1 verdict (UNCHANGED NAME AND MEANING-AS-FLAG)
#   .nRows            — rows in the table
#   .nChecked         — rows actually scanned
#   .truncated        — 1 if .maxScanRows cap stopped the scan, else 0
#   .nNumeric         — cells that parsed cleanly
#   .nMissing         — empty/whitespace cells (treated as missing)
#   .nCoerced         — cells accepted by number() only via a lossy coercion
#   .nNonNumeric      — cells number() could not parse at all
#   .nBad             — .nCoerced + .nNonNumeric (total offending cells)
#   .firstBadRow      — 1-based row of the first offending cell (0 if none)
#   .firstBadValue$   — literal contents of that cell ("" if none)
#   .firstBadKind$    — "coerced" or "non-numeric" ("" if none)
#   .firstCoercedRow  — 1-based row of the first coercion hazard (0 if none)
#   .firstCoercedValue$ — literal contents of that cell ("" if none)
#   .reason$          — one-line human-readable summary for the caller
# ----------------------------------------------------------------------------
procedure emlCheckNumericColumn: .tableId, .colName$
    .maxScanRows = 100000
    .isNumeric = 0
    .nRows = 0
    .nChecked = 0
    .truncated = 0
    .nNumeric = 0
    .nMissing = 0
    .nCoerced = 0
    .nNonNumeric = 0
    .nBad = 0
    .firstBadRow = 0
    .firstBadValue$ = ""
    .firstBadKind$ = ""
    .firstCoercedRow = 0
    .firstCoercedValue$ = ""
    .reason$ = "no column specified"
    if .colName$ = ""
        goto CHECK_NUM_END
    endif

    # Whitespace-only and strict-numeric-literal patterns. Built by
    # concatenation with tab$ so no literal tab or backslash escape appears
    # in the source.
    .wsPat$ = "^[ " + tab$ + "]*$"
    .numPat$ = "^[ " + tab$ + "]*[+-]?([0-9]+[.]?[0-9]*|[.][0-9]+)([eE][+-]?[0-9]+)?[ " + tab$ + "]*$"

    selectObject: .tableId
    .nRows = Get number of rows
    .nChecked = min (.nRows, .maxScanRows)
    if .nChecked < .nRows
        .truncated = 1
    endif

    for .i from 1 to .nChecked
        .val$ = Get value: .i, .colName$
        .isBlank = index_regex (.val$, .wsPat$)
        if .isBlank > 0
            .nMissing = .nMissing + 1
        else
            .looksNumeric = index_regex (.val$, .numPat$)
            .val = number (.val$)
            .parsed = 0
            if .val <> undefined
                .parsed = 1
            endif
            if .looksNumeric > 0 and .parsed = 1
                .nNumeric = .nNumeric + 1
            else
                .kind$ = "non-numeric"
                if .parsed = 1
                    .kind$ = "coerced"
                    .nCoerced = .nCoerced + 1
                    if .firstCoercedRow = 0
                        .firstCoercedRow = .i
                        .firstCoercedValue$ = .val$
                    endif
                else
                    .nNonNumeric = .nNonNumeric + 1
                endif
                if .firstBadRow = 0
                    .firstBadRow = .i
                    .firstBadValue$ = .val$
                    .firstBadKind$ = .kind$
                endif
            endif
        endif
    endfor

    .nBad = .nCoerced + .nNonNumeric
    if .nBad = 0 and .nNumeric > 0
        .isNumeric = 1
    endif

    # Build the caller-facing summary
    if .isNumeric = 1
        .reason$ = "column " + .colName$ + " is numeric ("
        ... + string$ (.nNumeric) + " values, "
        ... + string$ (.nMissing) + " blank)"
    elsif .nNumeric = 0 and .nBad = 0
        .reason$ = "column " + .colName$ + " has no usable values ("
        ... + string$ (.nChecked) + " rows scanned, all blank)"
    else
        .reason$ = "column " + .colName$ + " is not numeric: "
        ... + string$ (.nBad) + " of " + string$ (.nChecked)
        ... + " cells unusable (" + string$ (.nNonNumeric)
        ... + " unparseable, " + string$ (.nCoerced)
        ... + " silently coerced); first offender row "
        ... + string$ (.firstBadRow) + " = " + .firstBadValue$
        ... + " (" + .firstBadKind$ + ")"
    endif
    if .truncated = 1
        .reason$ = .reason$ + " [scan capped at " + string$ (.maxScanRows) + " rows]"
    endif

    label CHECK_NUM_END
endproc

# ----------------------------------------------------------------------------
# @emlInitAlphaSprites
# Resolves the sprites/ directory and checks availability.
# Call once per session (guarded by global emlAlphaSpritesInitialized).
# Outputs: .available (1 if sprites found, 0 if not — triggers fallback),
#          .dir$ (absolute path to sprites/ folder with trailing /)
# ----------------------------------------------------------------------------
procedure emlInitAlphaSprites
    if variableExists ("emlAlphaSpritesInitialized")
        if emlAlphaSpritesInitialized = 1
            goto SPRITES_INIT_DONE
        endif
    endif

    .available = 0
    .dir$ = ""

    # ------------------------------------------------------------------
    # Platform gate. This has to come before the file search, because a
    # readable sprite file is NOT evidence that the sprite will render.
    #
    # Praat draws an image from a file in Graphics_imageFromFile
    # (sys/Graphics_image.cpp). That function has a GDI+ branch for
    # Windows and a Quartz branch for macOS and NO cairo branch at all —
    # on Linux it computes its coordinates and returns without drawing.
    # No error, no return code, nothing on the canvas.
    #
    # So on Linux the old fileReadable test was actively harmful: it
    # passed, .available went to 1, the Paint circle fallback was skipped,
    # and every dot in a grouped scatter or a time-series CI band silently
    # vanished. Verified 6 Aug 2026 on Praat 6.6.30/GTK by drawing a
    # Paint circle and an Insert picture from file side by side in the
    # Picture window: the circle appeared, the image did not, for both an
    # RGBA sprite and a plain RGB PNG. Not an alpha problem, not a path
    # problem — the platform has no implementation.
    #
    # Opaque dots on Linux are a real cosmetic loss in dense scatters.
    # A blank plot is not a cosmetic loss. If Praat ever gains a cairo
    # branch, delete this gate and nothing else changes.
    # ------------------------------------------------------------------
    if not (macintosh or windows)
        emlAlphaSpritesInitialized = 1
        goto SPRITES_INIT_DONE
    endif

    # Strategy 1: installed plugin in preferences directory
    .tryPath$ = preferencesDirectory$ + "/plugin_EML_Praat_Tools/sprites/"
    .testFile$ = .tryPath$ + "dot_blue_a50_40.png"
    if fileReadable (.testFile$)
        .dir$ = .tryPath$
        .available = 1
        goto SPRITES_FOUND
    endif

    # Strategy 2: development layout (running from scripts/)
    .tryPath$ = defaultDirectory$ + "/../sprites/"
    .testFile$ = .tryPath$ + "dot_blue_a50_40.png"
    if fileReadable (.testFile$)
        .dir$ = .tryPath$
        .available = 1
        goto SPRITES_FOUND
    endif

    # Strategy 3: sprites in same folder as running script
    .tryPath$ = defaultDirectory$ + "/sprites/"
    .testFile$ = .tryPath$ + "dot_blue_a50_40.png"
    if fileReadable (.testFile$)
        .dir$ = .tryPath$
        .available = 1
    endif

    label SPRITES_FOUND
    emlAlphaSpritesInitialized = 1

    label SPRITES_INIT_DONE
endproc

# ----------------------------------------------------------------------------
# @emlSetAlphaDotGeometry
# Computes aspect-corrected stamp dimensions for alpha dots.
# Call once per plot after axes are established, before drawing any dots.
# Arguments:
#   .axisXMin, .axisXMax — current x-axis range
#   .axisYMin, .axisYMax — current y-axis range
#   .innerLeft, .innerRight — inner viewport x bounds (inches)
#   .innerTop, .innerBottom — inner viewport y bounds (inches)
#   .dotHalf — desired dot half-width in world x-units
# Outputs:
#   .stampHalfX — half-width for stamp in world x-units (= .dotHalf)
#   .stampHalfY — half-height for stamp in world y-units (aspect-corrected)
# ----------------------------------------------------------------------------
procedure emlSetAlphaDotGeometry: .axisXMin, .axisXMax, .axisYMin, .axisYMax, .innerLeft, .innerRight, .innerTop, .innerBottom, .dotHalf
    .xRange = .axisXMax - .axisXMin
    .yRange = .axisYMax - .axisYMin
    .vpWidth = .innerRight - .innerLeft
    .vpHeight = .innerBottom - .innerTop

    # Guard against zero ranges.
    # v3.22: "= 0" is FALSE for undefined, so an undefined axis bound (the
    # usual consequence of an all-undefined data column) previously took the
    # else branch and produced an undefined .stampHalfY, which then reaches
    # Paint circle: / Insert picture from file: in @emlDrawAlphaDot. Undefined
    # ranges are now folded into the same degenerate fallback as zero ranges.
    .degenerate = 0
    if .xRange = undefined
        .degenerate = 1
    endif
    if .yRange = undefined
        .degenerate = 1
    endif
    if .vpWidth = undefined
        .degenerate = 1
    endif
    if .vpHeight = undefined
        .degenerate = 1
    endif
    if .dotHalf = undefined
        .degenerate = 1
    endif
    if .degenerate = 0
        if .xRange = 0 or .yRange = 0 or .vpWidth = 0 or .vpHeight = 0
            .degenerate = 1
        endif
    endif
    if .degenerate = 1
        .stampHalfX = .dotHalf
        .stampHalfY = .dotHalf
        if .dotHalf = undefined
            .stampHalfX = 0
            .stampHalfY = 0
        endif
    else
        # World units per viewport inch
        .wuPerInchX = .xRange / .vpWidth
        .wuPerInchY = .yRange / .vpHeight

        .stampHalfX = .dotHalf
        # Scale y so the dot is circular in physical (inch) space
        .stampHalfY = .dotHalf * (.wuPerInchY / .wuPerInchX)
    endif
endproc

# ----------------------------------------------------------------------------
# @emlDrawAlphaDot
# Draws a single alpha-composited dot at the given world coordinates.
# Uses pre-rendered PNG sprites stamped via Insert picture from file:.
# Falls back to native Paint circle: if sprites are unavailable.
#
# Requires: @emlInitAlphaSprites called first (checks .available)
#           @emlSetAlphaDotGeometry called first (provides stamp dims)
#           @emlSetColorPalette called first (provides .sprite$[] mapping)
#
# Arguments:
#   .x, .y        — world coordinates for dot centre
#   .groupIndex   — palette group (1-based, maps to sprite$[])
#   .colorMode$   — "color" or "bw"
#   .alphaLevel$  — alpha tag: "a50", "a70", or "a100" (color mode only;
#                   ignored in B/W mode where alpha is baked into the sprite)
#   .fallbackColor$ — Praat colour string for native fallback
# ----------------------------------------------------------------------------
procedure emlDrawAlphaDot: .x, .y, .groupIndex, .colorMode$, .alphaLevel$, .fallbackColor$
    if emlInitAlphaSprites.available = 0
        # Fallback: native opaque dot
        Paint circle: .fallbackColor$, .x, .y, emlSetAlphaDotGeometry.stampHalfX
    else
        # Clamp group index to valid range
        .idx = ((.groupIndex - 1) mod 10) + 1

        # Build sprite filename
        .stem$ = emlSetColorPalette.sprite$[.idx]

        if .colorMode$ = "bw"
            # B/W sprites: alpha is baked into the level
            .file$ = emlInitAlphaSprites.dir$ + "dot_" + .stem$ + "_40.png"
        else
            # Color sprites: append alpha level
            .file$ = emlInitAlphaSprites.dir$ + "dot_" + .stem$ + "_" + .alphaLevel$ + "_40.png"
        endif

        # Guard: fall back to native if specific sprite file is missing
        if not fileReadable (.file$)
            Paint circle: .fallbackColor$, .x, .y, emlSetAlphaDotGeometry.stampHalfX
        else
            # Stamp with aspect-corrected dimensions
            .hx = emlSetAlphaDotGeometry.stampHalfX
            .hy = emlSetAlphaDotGeometry.stampHalfY
            Insert picture from file: .file$, .x - .hx, .x + .hx, .y - .hy, .y + .hy
        endif
    endif
endproc

# ----------------------------------------------------------------------------
# @emlDrawAlphaRect
# Draws a semi-transparent filled rectangle using a PNG sprite stretched
# to the specified world-coordinate bounds. Falls back to native opaque
# Paint rectangle: if sprites are unavailable.
#
# Sprite naming: rect_[colorStem]_[alphaLevel]_40.png (color mode)
#                rect_[colorStem]_40.png (B/W mode)
# Sprites are solid-color 4x4 pixel PNGs with alpha channel.
#
# Requires: @emlInitAlphaSprites called first
#           @emlSetColorPalette called first
#
# Arguments:
#   .x1, .x2       — world x bounds (left, right)
#   .y1, .y2       — world y bounds (bottom, top)
#   .groupIndex    — palette group (1-based)
#   .colorMode$    — "color" or "bw"
#   .alphaLevel$   — alpha tag: "a30", "a50", "a70"
#   .fallbackColor$ — Praat colour string for opaque fallback
# ----------------------------------------------------------------------------
procedure emlDrawAlphaRect: .x1, .x2, .y1, .y2, .groupIndex, .colorMode$, .alphaLevel$, .fallbackColor$
    if emlInitAlphaSprites.available = 0
        Paint rectangle: .fallbackColor$, .x1, .x2, .y1, .y2
    else
        .idx = ((.groupIndex - 1) mod 10) + 1
        .stem$ = emlSetColorPalette.sprite$[.idx]

        if .colorMode$ = "bw"
            .file$ = emlInitAlphaSprites.dir$ + "rect_" + .stem$ + "_40.png"
        else
            .file$ = emlInitAlphaSprites.dir$ + "rect_" + .stem$ + "_" + .alphaLevel$ + "_40.png"
        endif

        if not fileReadable (.file$)
            Paint rectangle: .fallbackColor$, .x1, .x2, .y1, .y2
        else
            Insert picture from file: .file$, .x1, .x2, .y1, .y2
        endif
    endif
endproc

# ----------------------------------------------------------------------------
# @emlLightenColor
# Parse an RGB colour string and blend toward white.
# Used for spaghetti strand lines — muted individual traces under bold mean.
#
# Arguments:
#   .rgb$    — Praat RGB string, e.g., "{0.3, 0.5, 0.7}"
#   .amount  — blend fraction toward white (0.0 = no change, 1.0 = white)
#
# Output:
#   .result$ — lightened RGB string
# ----------------------------------------------------------------------------
procedure emlLightenColor: .rgb$, .amount
    # Strip braces: "{0.3, 0.5, 0.7}" → "0.3, 0.5, 0.7"
    .inner$ = mid$ (.rgb$, 2, length (.rgb$) - 2)

    # Parse R
    .comma1 = index (.inner$, ",")
    .r = number (left$ (.inner$, .comma1 - 1))
    .rest$ = mid$ (.inner$, .comma1 + 2, length (.inner$) - .comma1 - 1)

    # Parse G
    .comma2 = index (.rest$, ",")
    .g = number (left$ (.rest$, .comma2 - 1))

    # Parse B
    .b = number (mid$ (.rest$, .comma2 + 2, length (.rest$) - .comma2 - 1))

    # Blend toward white
    .r = .r + .amount * (1.0 - .r)
    .g = .g + .amount * (1.0 - .g)
    .b = .b + .amount * (1.0 - .b)

    .result$ = "{" + fixed$ (.r, 3) + ", " + fixed$ (.g, 3) + ", " + fixed$ (.b, 3) + "}"
endproc


# ============================================================================
# @emlFitCategoricalLabels
# Measures categorical x-axis labels against available slot width.
# If any label exceeds the slot, sets .rotated = 1 (caller should use
# Text special: at 45° instead of One mark bottom:).
# Rotated labels truncated via binary search against 2.1× normal axis
# clearance, measured in physical inches.
#
# Arguments:
#   .nLabels   — number of labels
#   .xMin      — axis minimum (typically 0.5)
#   .xMax      — axis maximum (typically nLabels + 0.5)
#
# Reads/writes:
#   emlCatLabel$[1..nLabels] — sanitized display labels (truncated in-place)
#
# Exports:
#   .rotated              — 0 = normal, 1 = labels should be drawn rotated
#   .overhangInches       — extra inches below normal clearance consumed by
#                           rotated labels (used by matrix panel positioning)
#   .actualVerticalInches — total vertical projection of rotated labels in
#                           inches (used by x-axis label offset calculation)
#
# Requires axes and @emlSetAdaptiveTheme to be set before calling.
# ============================================================================

procedure emlFitCategoricalLabels: .nLabels, .xMin, .xMax
    # Available width per slot in world coordinates
    .slotWidth = (.xMax - .xMin) / .nLabels
    # Allow 85% of slot for text (leave gap between labels)
    .maxTextWidth = .slotWidth * 0.85

    # Check if any label exceeds available width
    .rotated = 0
    .overhangInches = 0
    .actualVerticalInches = 0
    for .i from 1 to .nLabels
        .w = Text width (world coordinates): emlCatLabel$[.i]
        if .w > .maxTextWidth
            .rotated = 1
            .i = .nLabels
        endif
    endfor

    # For rotated labels, truncate based on spatial clearance
    if .rotated
        # Normal clearance below inner box ≈ 2.5 font heights (inches)
        .fontInches = emlSetAdaptiveTheme.bodySize / 72
        .normalClearance = 2.5 * .fontInches
        # Max vertical extent: 1.4× normal clearance
        .maxVerticalExtent = 1.4 * .normalClearance
        # At 45°, vertical extent = physical text width × sin(45°)
        .maxPhysicalWidth = .maxVerticalExtent / 0.707
        # Convert physical inch limit to x-world-coordinates
        .xRange = .xMax - .xMin
        .innerW = emlSetAdaptiveTheme.innerRight - emlSetAdaptiveTheme.innerLeft
        .maxRotatedWC = .maxPhysicalWidth * (.xRange / .innerW)

        # Measure actual max label extent (after truncation) for overhang
        .maxActualW = 0
        for .i from 1 to .nLabels
            .w = Text width (world coordinates): emlCatLabel$[.i]
            if .w > .maxRotatedWC
                # Binary search for truncation point
                .lo = 1
                .hi = length (emlCatLabel$[.i])
                .origLabel$ = emlCatLabel$[.i]
                while .lo < .hi - 1
                    .mid = round ((.lo + .hi) / 2)
                    .tryLabel$ = left$ (.origLabel$, .mid) + "…"
                    .tryW = Text width (world coordinates): .tryLabel$
                    if .tryW <= .maxRotatedWC
                        .lo = .mid
                    else
                        .hi = .mid
                    endif
                endwhile
                emlCatLabel$[.i] = left$ (.origLabel$, .lo) + "…"
                .w = Text width (world coordinates): emlCatLabel$[.i]
            endif
            if .w > .maxActualW
                .maxActualW = .w
            endif
        endfor

        # Overhang = rotated vertical extent minus normal clearance
        .maxActualPhysW = .maxActualW * (.innerW / .xRange)
        .actualVertical = .maxActualPhysW * 0.707
        .actualVerticalInches = .actualVertical
        .overhangInches = max (0, .actualVertical - .normalClearance)
    endif
endproc


# ============================================================================
# @emlExtractUniqueValues
# ============================================================================
# Extracts unique values from a Table column in encounter order.
# Populates the module-level emlCatLabel$[] array with sanitized labels.
#
# Preconditions: Table .tableId exists and has column .colName$.
# Outputs:
#   .nLabels              — number of unique values found
#   emlCatLabel$[1..n]    — sanitized display labels (module-level)
#   .raw$[1..n]           — unsanitized original values (local)
# ============================================================================

procedure emlExtractUniqueValues: .tableId, .colName$
    @emlCountGroups: .tableId, .colName$
    .nLabels = emlCountGroups.nGroups
    for .i from 1 to .nLabels
        .raw$[.i] = emlCountGroups.groupLabel$[.i]
        @emlSanitizeLabel: .raw$[.i]
        emlCatLabel$[.i] = emlSanitizeLabel.result$
    endfor
endproc


# ============================================================================
# @emlMeasureCategoricalLabels
# ============================================================================
# Orchestrates categorical label measurement: extraction, viewport setup,
# rotation/truncation/overhang computation.
#
# Preconditions:
#   - @emlSetAdaptiveTheme already called (theme state set)
#   - Table .tableId exists and has column .colName$
#
# Outputs (via sub-procedure state):
#   .nLabels                                  — number of categories
#   emlCatLabel$[1..n]                        — sanitized display labels
#   emlFitCategoricalLabels.rotated           — 1 if labels need rotation
#   emlFitCategoricalLabels.overhangInches    — rotated extent beyond normal
#   emlFitCategoricalLabels.actualVerticalInches — total rotated vertical extent
# ============================================================================

procedure emlMeasureCategoricalLabels: .tableId, .colName$, .vpW, .vpH
    # Extract unique category labels
    @emlExtractUniqueValues: .tableId, .colName$
    .nLabels = emlExtractUniqueValues.nLabels

    # Measurement viewport — same geometry as production
    .xMin = 0.5
    .xMax = max (1, .nLabels) + 0.5   ; clamp: 0 categories would make left = right
    Font size: emlSetAdaptiveTheme.bodySize
    @emlSetPanelViewport
    Axes: .xMin, .xMax, 0, 1

    # Measure rotation, truncation, overhang
    @emlFitCategoricalLabels: .nLabels, .xMin, .xMax

    # Record what was measured, so @emlEnsureCategoricalLabels can tell a
    # measurement that already covers this table/column/viewport from one that
    # does not. Viewport dimensions belong in the key: rotation and truncation
    # are both functions of available width.
    emlCatMeasuredKey$ = string$ (.tableId) + "|" + .colName$ + "|"
    ... + string$ (.vpW) + "x" + string$ (.vpH)
endproc


# ============================================================================
# @emlEnsureCategoricalLabels
# ============================================================================
# Measures categorical labels unless the current measurement already covers
# this table, column and viewport.
#
# @emlDrawCategoricalXAxis is a pure renderer over emlCatLabel$[] and
# emlFitCategoricalLabels.*, and until 6 Aug 2026 the ONLY thing that
# populated them was the pre-dispatch block in eml-graphs-form.praat. Every
# other route into a categorical graph type — a PraatGen standalone script, a
# test harness, any future wrapper — aborted the figure outright at
# "Undefined indexed variable «emlCatLabel$[1]»", with nothing drawn and no
# message a user could act on.
#
# Call this EARLY in a draw procedure — after @emlSetAdaptiveTheme, before the
# procedure sets its own Axes. @emlMeasureCategoricalLabels installs its own
# measurement viewport and axes, so calling it mid-draw would silently rescale
# everything drawn afterwards.
#
# In the form path the key matches and this is a no-op, so the pre-dispatch
# measurement (whose overhang feeds the margin calculation) still governs.
# ============================================================================

procedure emlEnsureCategoricalLabels: .tableId, .colName$, .vpW, .vpH
    .key$ = string$ (.tableId) + "|" + .colName$ + "|"
    ... + string$ (.vpW) + "x" + string$ (.vpH)
    if not variableExists ("emlCatMeasuredKey$")
        emlCatMeasuredKey$ = ""
    endif
    if emlCatMeasuredKey$ <> .key$
        @emlMeasureCategoricalLabels: .tableId, .colName$, .vpW, .vpH
    endif
endproc


# ============================================================================
# @emlMeasureGraphLayout
# ============================================================================
# Universal frame measurement for all graph types. Measures rendered
# dimensions of title, axis labels, and legend at the current theme's
# font sizes. Called once before draw dispatch.
#
# All graph types pass through this procedure so that the measurement
# pipeline is identical regardless of graph type. For continuous types,
# the measurements supplement the theme's fixed margins. For future
# responsive margins (TODO-047), the data is already available.
#
# Arguments:
#   .vpW, .vpH    — viewport dimensions (inches)
#   .title$       — figure title (empty string if none)
#   .xLabel$      — x-axis label (empty string if none)
#   .yLabel$      — y-axis label (empty string if none)
#
# Reads globals:
#   legendN, legendLabel$[1..N]  — legend entries (if populated by caller)
#   emlSetAdaptiveTheme.*        — font sizes, margins, spacing
#
# Output (module-level globals):
#   emlLayout_titleHeightInches  — total title block height (0 if no title)
#   emlLayout_xLabelHeightInches — x-axis label height including gap
#   emlLayout_yLabelWidthInches  — y-axis label width including gap
#   emlLayout_legendWidthInches  — legend box width (0 if no legend)
#   emlLayout_legendHeightInches — legend box height (0 if no legend)
# ============================================================================
procedure emlMeasureGraphLayout: .vpW, .vpH, .title$, .xLabel$, .yLabel$
    .bodySize = emlSetAdaptiveTheme.bodySize
    .annotSize = emlSetAdaptiveTheme.annotSize
    .bodyInch = .bodySize / 72
    .annotInch = .annotSize / 72
    .sf = emlSetAdaptiveTheme.spacingFactor

    # --- Measurement viewport ---
    # Use a 0–1 world coordinate system for inch-based measurement.
    # Text width (world coordinates) returns in world units; with
    # axes 0..innerW and 0..innerH, world units = inches.
    Font size: .bodySize
    @emlSetPanelViewport
    .innerW = emlSetAdaptiveTheme.innerRight - emlSetAdaptiveTheme.innerLeft
    .innerH = emlSetAdaptiveTheme.innerBottom - emlSetAdaptiveTheme.innerTop
    Axes: 0, .innerW, 0, .innerH

    # --- Title height ---
    if .title$ <> ""
        .clearance = .bodyInch * 0.3
        .titleLineH = .annotInch * 1.4
        .gapBelow = .bodyInch * 0.3
        emlLayout_titleHeightInches = .clearance + .titleLineH + .gapBelow
    else
        emlLayout_titleHeightInches = 0
    endif

    # --- X-axis label height ---
    if .xLabel$ <> ""
        .xGapAbove = .bodyInch * 0.4
        .xLineH = .bodyInch * 1.2
        emlLayout_xLabelHeightInches = .xGapAbove + .xLineH
    else
        emlLayout_xLabelHeightInches = 0
    endif

    # --- Y-axis label width ---
    if .yLabel$ <> ""
        Font size: .bodySize
        .yTextW = Text width (world coordinates): .yLabel$
        .yTextW = .yTextW * 1.05
        # Rotated 90° — height becomes width contribution
        .yGap = .bodyInch * 0.5
        emlLayout_yLabelWidthInches = .bodyInch + .yGap
    else
        emlLayout_yLabelWidthInches = 0
    endif

    # --- Legend dimensions ---
    if variableExists ("legendN")
        if legendN > 0
            .fontInch = .bodySize / 72
            .lineH = .fontInch * 1.4
            .xPad = .fontInch * (0.3 + 0.3 * .sf)
            .yPad = .fontInch * (0.3 + 0.2 * .sf)
            .swatchSide = .fontInch * 0.8

            Font size: .bodySize
            .maxLabelW = 0
            for .i from 1 to legendN
                .w = Text width (world coordinates): legendLabel$[.i]
                if .w > .maxLabelW
                    .maxLabelW = .w
                endif
            endfor
            .maxLabelW = .maxLabelW * 1.05

            emlLayout_legendWidthInches = .xPad + .swatchSide + .xPad + .maxLabelW + .xPad
            emlLayout_legendHeightInches = .yPad + legendN * .lineH + .yPad
        else
            emlLayout_legendWidthInches = 0
            emlLayout_legendHeightInches = 0
        endif
    else
        emlLayout_legendWidthInches = 0
        emlLayout_legendHeightInches = 0
    endif

    # Restore font state invariant
    Font size: .bodySize
endproc


# ============================================================================
# @emlDrawCategoricalXAxis
# ============================================================================
# Renders categorical x-axis: tick marks, category labels (horizontal or
# rotated at 45°), and x-axis label (with rotated offset when needed).
#
# Pure renderer — reads pre-computed state from:
#   emlCatLabel$[1..n]                        — display labels
#   emlFitCategoricalLabels.rotated           — rotation flag
#   emlFitCategoricalLabels.actualVerticalInches — for offset calculation
#   emlSetAdaptiveTheme.bodySize / .innerBottom / .innerTop — theme state
#   emlFont$                                  — current font family
#
# Does NOT handle y-axis label or title — those are separate concerns.
# ============================================================================

procedure emlDrawCategoricalXAxis: .nLabels, .xMin, .xMax, .yMin, .yMax, .xLabel$
    Font size: emlSetAdaptiveTheme.bodySize
    Colour: emlSetAdaptiveTheme.textColor$
    if emlShowTicksX
        .drawTick$ = "yes"
    else
        .drawTick$ = "no"
    endif
    if .nLabels < 1
        # Zero categories — a 0-row table, or a category column of blanks.
        # The graphs form refuses this upstream (eml-graphs-form.praat:1305),
        # so the case only reaches here from a PraatGen standalone script or
        # another wrapper. Until 6 Aug 2026 every categorical type then died at
        # "Left and right should not be equal" when Axes: received 0.5, 0.5.
        # The x-range is clamped now, so say plainly what happened instead of
        # handing back a blank rectangle the reader has to diagnose.
        Font size: emlSetAdaptiveTheme.bodySize
        Colour: "{0.45, 0.45, 0.45}"
        Text: (.xMin + .xMax) / 2, "centre", (.yMin + .yMax) / 2, "half",
        ... "No data to plot"
        Colour: emlSetAdaptiveTheme.textColor$
        appendInfoLine: "NOTE: no categories found in the group column — ",
        ... "empty axes drawn."
        goto CAT_LABELS_DONE
    endif

    if emlFitCategoricalLabels.rotated
        for .i from 1 to .nLabels
            One mark bottom: .i, "no", .drawTick$, "no", ""
            Text special: .i, "Right",
            ... .yMin - (.yMax - .yMin) * 0.04, "Half",
            ... emlFont$, emlSetAdaptiveTheme.bodySize, "45",
            ... emlCatLabel$[.i]
        endfor
    else
        for .i from 1 to .nLabels
            One mark bottom: .i, "no", .drawTick$, "no", emlCatLabel$[.i]
        endfor
    endif

    label CAT_LABELS_DONE

    # X-axis label
    if .xLabel$ <> "" and emlShowAxisNameX
        if emlFitCategoricalLabels.rotated = 0
            Text bottom: "yes", .xLabel$
        else
            .yRange = .yMax - .yMin
            .innerH = emlSetAdaptiveTheme.innerBottom - emlSetAdaptiveTheme.innerTop
            .fontInch = emlSetAdaptiveTheme.bodySize / 72
            .wpiY = .yRange / .innerH
            .offsetWC = .yRange * 0.04
            ... + emlFitCategoricalLabels.actualVerticalInches * .wpiY
            ... + .fontInch * 1.0 * .wpiY
            Text special: (.xMin + .xMax) / 2, "centre",
            ... .yMin - .offsetWC, "half",
            ... emlFont$, emlSetAdaptiveTheme.bodySize, "0", .xLabel$
        endif
    endif

    # ------------------------------------------------------------------
    # Tell the extent tracker where the rotated block actually landed.
    #
    # 6 Aug 2026. Rotated labels are drawn below and to the LEFT of the
    # theme's outer box, and the x-axis title is pushed below them again.
    # Neither was reported to @emlExpandDrawnExtent, so
    # @emlAssertFullViewport — which every save path calls — selected a box
    # that cut through both. Observed on three ordinary cohort names at
    # 6x4 inches: "Preprofessional undergraduate" truncated correctly to
    # "Preprofe…" and then rendered as "reprofe…" with its first character
    # off-canvas, and the x-axis title "Cohort" vanished entirely. Redrawing
    # the identical figure into a hand-widened viewport showed both intact,
    # which is what identifies this as a save-extent fault and not a
    # placement one. The overhang was already being measured — the form just
    # spent it on the gap above the comparison matrix panel and nowhere else,
    # so a figure with no matrix panel (the common case) lost the labels.
    #
    # At 45 degrees a right-anchored label extends left by the same physical
    # distance it extends down, so one measurement serves both directions.
    # ------------------------------------------------------------------
    if emlFitCategoricalLabels.rotated
        .extraDown = emlFitCategoricalLabels.actualVerticalInches
        if .xLabel$ <> "" and emlShowAxisNameX
            # Title sits a further font height below the rotated block.
            .extraDown = .extraDown + emlSetAdaptiveTheme.bodySize / 72 * 2
        endif
        .leftReach = emlSetAdaptiveTheme.innerLeft
        ... - emlFitCategoricalLabels.actualVerticalInches
        @emlExpandDrawnExtent: emlPanelOriginX + .leftReach,
        ... emlPanelOriginX + emlSetAdaptiveTheme.outerRight,
        ... emlPanelOriginY + emlSetAdaptiveTheme.outerTop,
        ... emlPanelOriginY + emlSetAdaptiveTheme.outerBottom + .extraDown
    endif

endproc


# ============================================================================
# @emlMeasureBarData
# ============================================================================
# Extracts and aggregates bar chart data from a Table: unique groups,
# per-group means, per-group error values (SE/SD/custom), and the visible
# maximum (max of mean + error across groups). Called once from pre-dispatch;
# results read by both headroom computation and @emlDrawBarChart.
#
# Arguments:
#   .tableId     — Table object ID
#   .groupCol$   — group column name
#   .valueCol$   — value column name
#   .errorMode   — 0=none, 1=SE, 2=SD, 3=custom column
#   .errorCol$   — custom error column name (used only when .errorMode = 3)
#
# v3.22: undefined-value discipline. Previously any unparseable cell in the
# value column entered the accumulation, so .sum / .sumSq / the group mean all
# became undefined. Because "undefined > 0" is FALSE the SE/SD guard silently
# took the else branch and reported error = 0, but the undefined mean reached
# @emlDrawBarChart's "Paint rectangle:" and aborted the ENTIRE figure with
# «Argument "To y" has the value "undefined"». Undefined observations are now
# skipped during accumulation (the guard pattern used by @emlDrawGroupedViolin),
# counted, and disclosed; every use of a mean or variance is guarded with an
# explicit "<> undefined" test.
#
# Invariant (hard): emlBarData_mean[g] and emlBarData_error[g] are ALWAYS
# defined numbers on return, so no undefined can reach a drawing command.
# A group with no usable observation gets mean = 0 / error = 0 and
# emlBarData_valid[g] = 0 — it paints as a zero-height (invisible) bar rather
# than aborting the figure. Callers should consult emlBarData_valid[g] before
# treating a bar as data.
#
# Outputs (module-level globals):
#   emlBarData_nGroups          — number of unique groups
#   emlBarData_label$[g]        — group name for group g
#   emlBarData_mean[g]          — mean of value column for group g
#                                 (always defined; 0 when valid[g] = 0)
#   emlBarData_error[g]         — error value for group g (SE/SD/custom/0)
#                                 (always defined; 0 when errorDefined[g] = 0)
#   emlBarData_count[g]         — count of USABLE observations for group g
#   emlBarData_visibleMax       — max(mean + error) across valid groups
#   emlBarData_visibleMin       — min(mean - error) across valid groups
#   emlBarData_valid[g]         — 1 if group g has >= 1 usable observation
#   emlBarData_errorDefined[g]  — 1 if the error bar for group g is a real
#                                 quantity; 0 when it is undefined and was
#                                 substituted with 0 (n = 1, no usable custom
#                                 error value, or a non-positive variance)
#   emlBarData_skipped[g]       — undefined value cells skipped in group g
#   emlBarData_errSkipped[g]    — undefined custom-error cells skipped (mode 3)
#   emlBarData_nSkipped         — total undefined value cells skipped
#   emlBarData_nErrSkipped      — total undefined custom-error cells skipped
#   emlBarData_nInvalidGroups   — groups with no usable observation
#   emlBarData_nSingleObs       — groups with exactly one usable observation
#                                 (SE/SD undefined by definition)
#   emlBarData_nUnmatchedRows   — rows whose group label matched no group
# ============================================================================

procedure emlMeasureBarData: .tableId, .groupCol$, .valueCol$, .errorMode, .errorCol$

    # Extract unique groups
    selectObject: .tableId
    .nRows = Get number of rows

    # Extract unique groups via single source
    @emlCountGroups: .tableId, .groupCol$
    emlBarData_nGroups = emlCountGroups.nGroups
    for .g from 1 to emlBarData_nGroups
        emlBarData_label$[.g] = emlCountGroups.groupLabel$[.g]
    endfor

    # Initialize accumulators
    emlBarData_nSkipped = 0
    emlBarData_nErrSkipped = 0
    emlBarData_nInvalidGroups = 0
    emlBarData_nSingleObs = 0
    emlBarData_nUnmatchedRows = 0
    for .g from 1 to emlBarData_nGroups
        emlBarData_count[.g] = 0
        emlBarData_skipped[.g] = 0
        emlBarData_errSkipped[.g] = 0
        emlBarData_valid[.g] = 0
        emlBarData_errorDefined[.g] = 0
        .sum[.g] = 0
        .sumSq[.g] = 0
        .errSum[.g] = 0
        .errCount[.g] = 0
    endfor

    # Accumulate per-group sums, skipping undefined observations
    for .i from 1 to .nRows
        selectObject: .tableId
        .thisGroup$ = Get value: .i, .groupCol$
        .val$ = Get value: .i, .valueCol$
        .thisVal = number (.val$)
        .thisErr = undefined
        if .errorMode = 3
            .errVal$ = Get value: .i, .errorCol$
            .thisErr = number (.errVal$)
        endif

        .gIdx = 0
        for .g from 1 to emlBarData_nGroups
            if .thisGroup$ = emlBarData_label$[.g]
                .gIdx = .g
            endif
        endfor

        if .gIdx > 0
            if .thisVal <> undefined
                emlBarData_count[.gIdx] = emlBarData_count[.gIdx] + 1
                .sum[.gIdx] = .sum[.gIdx] + .thisVal
                .sumSq[.gIdx] = .sumSq[.gIdx] + .thisVal * .thisVal
            else
                emlBarData_skipped[.gIdx] = emlBarData_skipped[.gIdx] + 1
                emlBarData_nSkipped = emlBarData_nSkipped + 1
            endif
            if .errorMode = 3
                if .thisErr <> undefined
                    .errSum[.gIdx] = .errSum[.gIdx] + .thisErr
                    .errCount[.gIdx] = .errCount[.gIdx] + 1
                else
                    emlBarData_errSkipped[.gIdx] = emlBarData_errSkipped[.gIdx] + 1
                    emlBarData_nErrSkipped = emlBarData_nErrSkipped + 1
                endif
            endif
        else
            emlBarData_nUnmatchedRows = emlBarData_nUnmatchedRows + 1
        endif
    endfor

    # Compute means and errors. Every quotient and every sqrt argument is
    # guarded; the outputs are guaranteed defined so no undefined can reach a
    # drawing command downstream.
    for .g from 1 to emlBarData_nGroups
        emlBarData_mean[.g] = 0
        emlBarData_error[.g] = 0
        emlBarData_errorDefined[.g] = 0

        if emlBarData_count[.g] > 0
            .m = .sum[.g] / emlBarData_count[.g]
            if .m <> undefined
                emlBarData_mean[.g] = .m
                emlBarData_valid[.g] = 1
            endif
        endif

        if emlBarData_valid[.g] = 0
            emlBarData_nInvalidGroups = emlBarData_nInvalidGroups + 1
        endif

        # n = 1 leaves SE and SD undefined by definition. Say so explicitly
        # (errorDefined = 0) instead of emitting a bar with an undefined,
        # or a misleadingly zero, error bar.
        if emlBarData_count[.g] = 1
            emlBarData_nSingleObs = emlBarData_nSingleObs + 1
        endif

        if emlBarData_valid[.g] = 1
            if .errorMode = 1 or .errorMode = 2
                if emlBarData_count[.g] > 1
                    .var = (.sumSq[.g] - .sum[.g] * .sum[.g] / emlBarData_count[.g]) / (emlBarData_count[.g] - 1)
                    if .var <> undefined
                        if .var > 0
                            if .errorMode = 1
                                # SE: sd / sqrt(n)
                                emlBarData_error[.g] = sqrt (.var) / sqrt (emlBarData_count[.g])
                            else
                                # SD
                                emlBarData_error[.g] = sqrt (.var)
                            endif
                            emlBarData_errorDefined[.g] = 1
                        else
                            # Zero (or, from rounding, slightly negative)
                            # variance: the spread really is nil.
                            emlBarData_error[.g] = 0
                            emlBarData_errorDefined[.g] = 1
                        endif
                    endif
                endif
            elsif .errorMode = 3
                # Custom column: average of the usable error values per group
                if .errCount[.g] > 0
                    .err = .errSum[.g] / .errCount[.g]
                    if .err <> undefined
                        emlBarData_error[.g] = .err
                        emlBarData_errorDefined[.g] = 1
                    endif
                endif
            endif
        endif
    endfor

    # Compute visible maximum (max of mean + error) and minimum (min of
    # mean - error). Both seed at 0 so 0 stays the baseline for all-positive
    # OR all-negative data; visibleMin only goes negative when a group's
    # (mean - error) drops below 0, so negative-mean bars are no longer clipped.
    # Groups with no usable observation are excluded — their sentinel mean of 0
    # must not be mistaken for a data point.
    emlBarData_visibleMax = 0
    emlBarData_visibleMin = 0
    for .g from 1 to emlBarData_nGroups
        if emlBarData_valid[.g] = 1
            .topVal = emlBarData_mean[.g] + emlBarData_error[.g]
            if .topVal <> undefined
                if .topVal > emlBarData_visibleMax
                    emlBarData_visibleMax = .topVal
                endif
            endif
            .botVal = emlBarData_mean[.g] - emlBarData_error[.g]
            if .botVal <> undefined
                if .botVal < emlBarData_visibleMin
                    emlBarData_visibleMin = .botVal
                endif
            endif
        endif
    endfor

    # Key for @emlEnsureBarData: what this measurement actually covers.
    emlBarData_key$ = string$ (.tableId) + "|" + .groupCol$ + "|"
    ... + .valueCol$ + "|" + string$ (.errorMode) + "|" + .errorCol$

endproc


# ============================================================================
# @emlEnsureBarData
# ============================================================================
# Measures bar chart data unless the current emlBarData_* state already covers
# this table, these columns and this error mode.
#
# @emlDrawBarChart is a pure renderer over emlBarData_*; the only producer was
# the pre-dispatch block in eml-graphs-form.praat, so every other caller hit
# "Unknown variable: emlBarData_nGroups" and drew nothing. In the form path
# the key matches and this costs one string comparison.
# ============================================================================

procedure emlEnsureBarData: .tableId, .groupCol$, .valueCol$, .errorMode, .errorCol$
    .key$ = string$ (.tableId) + "|" + .groupCol$ + "|"
    ... + .valueCol$ + "|" + string$ (.errorMode) + "|" + .errorCol$
    if not variableExists ("emlBarData_key$")
        emlBarData_key$ = ""
    endif
    if emlBarData_key$ <> .key$
        @emlMeasureBarData: .tableId, .groupCol$, .valueCol$, .errorMode, .errorCol$
    endif
endproc

# ============================================================================
# END OF EML GRAPHS PROCEDURES
# ============================================================================
