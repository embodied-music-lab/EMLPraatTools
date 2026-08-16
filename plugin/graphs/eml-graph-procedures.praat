# ============================================================================
# EML GRAPHS — STANDARD DRAWING PROCEDURES
# ============================================================================
# Author: Ian Howell, Embodied Music Lab, www.embodiedmusiclab.com
# Development: Claude (Anthropic)
# License: GPL-3.0-or-later
# Version: 3.31
# Date: 15 August 2026
#
# v3.31: THREE RULINGS OF 15 AUGUST 2026, none of which moves a number.
#
#        RULING 7 — THE Y-AXIS NAME AND ITS TICK LABELS NO LONGER TOUCH.
#        Praat's left-margin allocation is fixed: `Text left` anchors the
#        rotated name to the inner frame at a distance set by the font size
#        and by nothing else, tick numbers are right-aligned to that same
#        frame, and about five characters fit between them. Six is the
#        failure edge — a semitone axis reading "-33.08" left three pixels of
#        gap at 300 dpi, and an explicit two-decimal dB axis put "100.10"
#        into "Power (dB)" so that it read "Powe100.10". New
#        @emlTickLabelWidth (what a tick will read as, and how wide) and
#        @emlDrawAxisNameLeft (the name, moved only when the labels have
#        taken the room). @emlDrawAlignedMarksLeft publishes the widest
#        label it drew; @emlDrawAxes and @emlDrawAxesSelective place the
#        name through the new procedure. WIDENING THE PLUGIN'S OWN MARGIN
#        DOES NOT WORK and was measured not working — everything in the
#        margin is anchored to the frame, and the frame moves with the
#        margin. ORDINARY FIGURES ARE BYTE-IDENTICAL: all 39 of
#        harness/stress_graphs.sh re-rendered and compared.
#
#        RULING 5 — Column_k NOW HOLDS SOURCE COLUMN k. @emlCleanConvertedTable
#        numbered manufactured headers by TABLE position, and `To Table: "row"`
#        has already put the label column in position 1 by then, so source
#        column 1 was called "Column_2" and nothing was ever called
#        "Column_1". Reached by both the graphs coercion and the describe
#        wrapper, so one line repaired two doors.
#
#        RULING 8b — ONE PRESS, ONE DERIVED SOUND. The stereo gate keeps the
#        extracted channel Sound on purpose, and kept one per press: three
#        figures from one recording left three Sounds sharing one name. The
#        derived object is now named with an "eml_" prefix — which the gate's
#        header had promised since the gate was written — and new
#        @emlDropStaleChannelSounds collects the previous press's at the top
#        of the next one. Only ever a prefixed name: a channel the user
#        extracted by hand is never touched.
#
# v3.30: THE LEGEND BOX IS SEMI-TRANSPARENT ON EVERY PLATFORM, NOT JUST THE
#        TWO THAT HAVE ALPHA.
#
#        The legend's background is sprites/bg_white_a70_40.png, whose pixels
#        MEASURE RGBA (255, 255, 255, 179) — a 70.2% white wash. Praat can
#        only draw it on macOS and Windows, and @emlInitAlphaSprites is
#        correctly gated to those two: re-confirmed 9 Aug 2026 by rendering
#        the same script with and without `Insert picture from file:` on this
#        Linux build, where `compare -metric AE` scores the two PNGs
#        BYTE-IDENTICAL. Everywhere else the fallback was
#        `Paint rectangle: "White"` — an OPAQUE box. Same script, same figure,
#        and the data under the legend was visible to a mac reader and DELETED
#        for everyone else, with nothing anywhere saying so.
#
#        New section SCREEN-DOOR TRANSPARENCY, with @emlScreenSetup,
#        @emlPaintScreenRect and @emlPaintAlphaBox. Where there is no alpha
#        the box is now a white LATTICE at 0.027 inch pitch — 70% ink, 30%
#        holes — through which the data survives instead of being erased.
#        Measured on rendered pixels: ink 0.740 at 300 dpi and 0.672 at 600,
#        against the sprite's 0.702. The section header carries the two
#        rejected designs (a 45-degree hatch and a hex dot field), the
#        measurements that rejected them, and the finding underneath all
#        three: PRAAT DOES NOT ANTIALIAS AND ROUNDS RECTANGLES OUTWARD BY
#        ABOUT ONE DEVICE PIXEL, which is why the geometry carries a kerf.
#
#        Nothing changes on macOS or Windows. @emlPaintAlphaBox's sprite
#        branch issues the identical `Insert picture from file:` call with the
#        identical arguments and returns .viewportDirty = 1, which is the
#        viewport restore v3.28 added, moved verbatim behind a flag.
#
#        NOT SILENT, either way. @emlPaintAlphaBox publishes emlAlphaBgMode$
#        ("sprite" | "screen" | "opaque") for every box it paints, and puts
#        one NOTE in the Info window per session the first time a figure gets
#        the screen. The sprite path stays quiet: on the platforms where the
#        figure was already right, a note about it is noise.
#
#        NOT APPLIED to @emlDrawAnnotationBlock's background, which has the
#        same gate and the same opaque fallback in
#        eml-annotation-procedures.praat. @emlPaintAlphaBox is written to be
#        called from there unchanged — it takes world coordinates and scales
#        through emlPatWorldPerInchX/Y, which that procedure's callers set —
#        but that file is not this one's to edit.
#
# v3.29: THE LEGEND BAND NO LONGER LANDS ON THE COMPARISON MATRIX WHEN THE
#        CALLER IS NOT THE FORM.
#
#        v3.28 gave placement 3 (Below plot) one way to find out what was
#        already occupying the page under the plot: the global
#        totalCanvasHeight, read through variableExists. Inside the graphs
#        form that is exactly right — the form sizes the comparison-matrix
#        panel before it dispatches the draw and leaves
#        figure_height + matrixGap + matrixPanelHeight there — and rendering
#        the two together confirms it: on a 6 x 4 figure with a four-group
#        Tukey matrix the panel occupies 4.130 to 6.204 inches and the legend
#        band starts at 6.344, one boxInsetInches below it.
#
#        BUT totalCanvasHeight IS A FORM LOCAL. @emlInitDrawingDefaults, the
#        documented entry point for "standalone scripts or PraatGen companion
#        files", sets emlLegendPlacement and does NOT set totalCanvasHeight.
#        A caller outside the form that laid out its own matrix and asked for
#        placement 3 therefore got a band starting at the plot's own bottom
#        edge, drawn straight THROUGH the panel: measured on the same figure,
#        band 4.140 to 4.566 against a panel at 4.130 to 6.204, with the
#        omnibus line and the correction subtitle overprinted by the legend's
#        entries. 11636 dark pixels of legend ink inside the matrix band.
#
#        FIXED by settling the page bottom ONCE, before the placement branch
#        dispatches, from the larger of two sources: the form's
#        totalCanvasHeight, and the matrix's own published measurement
#        (annotMatrixN, emlMatrixLayout_suppressed, emlMatrixLayout_yMax,
#        emlFitCategoricalLabels.overhangInches — all drawing-layer globals,
#        and all necessarily already set, since @emlMeasureMatrixLayout is a
#        precondition of @emlDrawMatrixPanel). Neither source can pull the
#        band up; a form-driven figure is unchanged because the two agree
#        there. Placement 4's park now reads the same page bottom instead of
#        totalCanvasHeight alone, for the same reason.
#
#        Nothing else moved. Placements 1, 2 and 5 do not consult the page
#        bottom, and a figure with no matrix publishes no measurement, so
#        every render in harness/legend/ block 1 and block 2 is bit-identical
#        to v3.28's. Driven and measured on the pixels in
#        harness/legend/run.sh blocks 3 and 4; asserted in
#        validate/v32_legend_geometry.R sections 8 and 9.
#
# v3.28: THE LEGEND STOPS BILLING ITS RENT TO THE PLOT (D136), and D135 —
#        the label wider than the frame — closes with it.
#
#        THE OBJECTION. A user types 6 x 4 and means the DATA AREA. Until
#        now the only place a legend could go was inside the plot, so the
#        only way to give a legend room was to take room from the data, and
#        "make my figure square" became unsatisfiable — a square canvas with
#        a legend carved out of it is not a square plot. The answer is that
#        the legend moves OUT and the EXPORT grows, rather than the plot
#        shrinking IN. The plot rectangle is now identical in all five
#        placements; what changes is how much of the picture is saved.
#
#        NEW: @emlDrawLegendPanel and @emlMeasureLegendPanel, a renderer that
#        is handed a rectangle in inches and a measurer that reports what
#        would fit in one. Both work in a viewport whose world unit is one
#        inch, both set the font size BEFORE selecting it, and the renderer
#        lays itself out by calling the measurer, so the two cannot disagree.
#        The renderer MUST NOT draw outside its rectangle and MUST NOT call
#        @emlExpandDrawnExtent — the caller reports, which is what lets one
#        procedure serve a corner box (must not grow the export) and a side
#        panel (must). Also new: @emlEllipsizeToWidth.
#
#        @emlDrawLegend keeps its signature and every behaviour of an entry —
#        multi-column layout, "+N more" truncation with its Info-window NOTE,
#        the swatch drawn as the mark, the viewport re-selected at legend
#        font size — and becomes a placement dispatcher over the new panel.
#        Placement is the global emlLegendPlacement, read through
#        variableExists and defaulting to 1, so every existing caller (the
#        seven sites in eml-draw-procedures.praat, every stress case, every
#        PraatGen companion) draws exactly what it drew before.
#            1 Inside plot (DEFAULT) — export = plot rectangle, unchanged
#            2 Right of plot         — caller reports; export widens
#            3 Below plot            — caller reports; export heightens
#            4 Separate figure       — parked off-figure, saved as a 2nd file
#            5 None
#        The encoding, its registry and its dialog are in eml-graphs-form.
#
#        D135 CLOSED. "NOT HANDLED HERE: a single label wide enough that one
#        column does not fit the frame width" was true of every revision up
#        to v3.27, and it was structural: a legend that computed its own box
#        had nothing to clamp against. A legend that is GIVEN its bounds
#        does. When one column of full-width labels will not fit, the column
#        is clamped to the width that IS available and @emlEllipsizeToWidth
#        shortens each label to it, so the label comes out as
#        "Extremely long gro..." inside the box instead of running off the
#        canvas — and a NOTE says so, because a silent ellipsis is the same
#        defect as a silent truncation.
#
#        @emlMeasureGraphLayout's legend estimate is no longer dead OR wrong.
#        It now delegates to @emlMeasureLegendPanel instead of carrying a
#        single-column stack measured at bodySize (the legend is drawn at
#        annotSize at all seven call sites; measuring at the wrong size
#        inflates every width — 0.4967" vs 3.6229" for "Group label",
#        measured 8 Aug 2026 on Praat 6.6.30). New alongside the two
#        existing globals: emlLayout_legendCols / Rows / Fits.
#
#        One latent defect fixed in passing: the alpha-sprite legend
#        background called `Insert picture from file:`, which leaves the
#        viewport set to the image's bounding box, and the old code restored
#        the viewport only at the END of the procedure — after every swatch
#        and label had been drawn through it. Restored immediately now. Not
#        observable on Linux, where @emlInitAlphaSprites is gated off.
#
# v3.27: COMMENTS ONLY — no executable line changed. Five statements the code
#        or the checks contradict, corrected.
#        (1) Two places said "the annotation block does not wrap either" —
#            the v3.26 entry below, and NOT HANDLED HERE in @emlDrawLegend's
#            header. D124 closed the same day: @emlDrawAnnotationBlock now
#            wraps every entry to emlAnnotBlockWidthShare (default 0.55) of
#            the frame. The legend is now the ONLY element that does not, and
#            both places say so instead.
#        (2) The overhang itself is unchanged and still not fixed. Its
#            documentation is now anchored on `if .colsMax < 1` rather than
#            on a line number.
#        (3) @emlSetColorPalette's B/W branch reported the measured minimum
#            greyscale separation as 0.120, disagreeing with the v3.25 entry
#            below (0.1176) and with the check that produces it. Run 8 Aug
#            2026: validate/v29_figure_disclosure.R reports 0.1176. Two
#            "See validate/v29." pointers were also completed to the real
#            filename, and harness/stress_cases/legend_cap to legend_cap.praat.
#        (4) The v3.26 entry, and the zero-category branch of
#            @emlDrawCategoricalXAxis, both quoted a line of
#            eml-graphs-form.praat as the home of `prev_gvAnnotStyle = 1`.
#            That had drifted again within the day — it is ~250 lines further
#            down now. Neither quotes a line number any more; the argument
#            for the anchor was being made by a citation that could not hold.
#        (5) @emlMeasureGraphLayout's note that nothing consumes
#            emlLayout_legendWidthInches / HeightInches is TRUE, re-checked
#            8 Aug 2026, and now carries the grep that shows it.
#
# v3.26: THE LEGEND IS LAID OUT TO FIT THE FRAME (D123), and one stale
#        cross-reference corrected.
#        (1) LEGEND. @emlDrawLegend stacked one row per entry and measured
#            that stack against nothing. The palette holds 24 sub-group
#            styles, so 24 entries is a figure the plugin is built to draw:
#            at the annotation font on a 6 x 4 figure a row is 0.162", the
#            panel is 3.11" tall, and 24 rows want 3.94". Rendered before the
#            fix, the box overhung the frame by 304 px at 300 dpi and its
#            last entries ran clean off the bottom of the PNG. The fix is a
#            LAYOUT, not a cap: the frame is measured (rowsMax x colsMax =
#            capacity) and the entries are poured down the fewest columns
#            that fit the height, so 24 entries become two columns of 12 on
#            a 6 x 4 figure and three of 8 on a 10 x 3 one. Hue order runs
#            top-to-bottom down each column. A legend that fits in one column
#            gets the identical single-column geometry v3.25 drew, to the
#            last decimal — verified by rendering: a 3-entry legend's pixels
#            are unchanged. Only when capacity is still exceeded (a very
#            short frame, or labels wide enough that one column is all that
#            fits) is anything dropped, and then the last cell reads
#            "+N more" ON THE FIGURE and a NOTE naming both counts goes to
#            the Info window. Nothing is dropped in silence. New reports for
#            callers and fixtures: .nCols, .rowsPerCol, .shown, .hidden,
#            .capacity. NOT fixed here: a single label wider than the frame
#            still overhangs to the right. That is the legend's copy of the
#            D124 defect — and D124 itself was closed the same day, so the
#            annotation block now wraps to a share of the frame and the
#            legend is the only element left that does not. See NOT HANDLED
#            HERE in @emlDrawLegend's header.
#        (2) The zero-category branch of @emlDrawCategoricalXAxis cited
#            eml-graphs-form.praat by LINE NUMBER for the refusal that keeps
#            an empty table out of it. The line it named held
#            `prev_gvAnnotStyle = 1`, a grouped-violin persistence variable —
#            the citation was ~750 lines stale (7 Aug contradiction sweep,
#            C3), and the line number quoted in this entry had itself drifted
#            again within the day, which is the whole argument. It now names
#            the guard by its string, `exitScript: "Table has no
#            rows."`, which cannot drift. Checking it also showed the same
#            comment's other claim to be false: an all-blank category column
#            does NOT reach that branch, because @emlCountGroups counts the
#            empty string as a group (measured: nGroups = 1 on a 3-row table
#            of blanks). Both statements are corrected in place.
#
# v3.25: POINT MARKERS, and a greyscale ramp that uses the page.
#        (1) MARKERS. The v3.24 fill pattern needs an AREA. Scatter, line
#            chart, spaghetti and time series draw dots and lines, so all
#            four still cycled eight hues in silence above eight groups --
#            D127 unfixed, in four more chart types. New @emlDrawMarker draws
#            circle / square / triangle from NATIVE primitives (Paint circle,
#            Paint rectangle, and a stack of horizontal slices for the
#            triangle -- the same construction @emlDrawViolin uses for its
#            body). New emlSetColorPalette.marker[] gives 8 hues x 3 shapes =
#            24, the same arithmetic and the same cap as the fill patterns.
#            @emlDrawLegend grew a marker key (legendMarkered,
#            legendMarker[], legendMarkerLine) so the key shows the SHAPE and
#            not merely the hue. Not sprites: plugin/sprites/ is real and has
#            204 PNGs, but every one of them is a dot or a rectangle indexed
#            by hue, and @emlInitAlphaSprites is disabled on anything that is
#            not macOS or Windows because Praat has no cairo image branch.
#            @emlDrawScatterPlot therefore drops the sprite path above eight
#            groups, or on those two platforms the shape would never reach
#            the page.
#        (2) GREYSCALE. The v3.24 ramp ran 0.90 to 0.25, a span of 0.65, and
#            what held it there was not the eye: the stroke was derived as
#            fill - 0.30 and clamped at zero, so a fill below 0.30 collapsed
#            the stroke ramp -- and at 0.25 it already had, leaving the two
#            darkest strokes 0.043 and 0.000 apart and a greyscale LINE chart
#            with two indistinguishable series at eight groups. The fill and
#            stroke ramps are now independent: fills 0.94 to 0.10 (a span of
#            0.84) and strokes 0.63 to 0.00. New @emlMarkInk pays the cost --
#            a mark's outline, median, whiskers and pattern flip to white on
#            a dark fill and black on a light one, per channel so that
#            Okabe-Ito yellow (whose contrast is all in the blue channel) is
#            not misjudged. New @emlParseRGB underneath it. Measured
#            minimum greyscale separation on the rendered pixels: 0.1176,
#            was 0.090.
#
# v3.24: FILL PATTERNS — the palette has eight colours, not ten, and now has
#        a second dimension. @emlSetColorPalette declared ten fill/line pairs
#        whose slots 9 and 10 were LITERAL DUPLICATES of 1 and 2, so a nine-
#        or ten-sub-group figure drew two pairs of sub-groups in
#        indistinguishable colours, on the figure and in the legend, with no
#        disclosure (D127). Fixed by declaring the eight hues once and adding
#        a fill-pattern axis: 8 hues x 3 patterns (solid, diagonal hatch,
#        dots) = 24 distinguishable styles, hue cycling first so adjacent
#        sub-groups differ in the stronger cue. @emlDrawViolin and
#        @emlDrawBox take a .pattern argument and clip the pattern to the
#        mark using the scanline structure they already build; @emlDrawLegend
#        draws the swatch as the mark rather than as a block of colour, so
#        the key cannot say "solid" where the figure says "hatched". The B/W
#        branch's ten fills, which sat between 0.82 and 0.96, are replaced by
#        the eight-step 0.90-0.25 ramp @emlOptimizePaletteContrast was
#        already computing, so greyscale reaches the same 24.
#        Also fixed here: @emlDrawLegend measured and drew itself at its own
#        font size while the viewport had been selected at the body size, so
#        the legend was rendered into a rectangle slightly smaller than, and
#        offset from, the .boxLeft/.boxTop it reported to its caller. It
#        looked right because the whole legend moved together, but the box
#        the caller kept the disclosure block clear of was not the box on the
#        page. The viewport is now re-selected at the legend's font size.
#
# v3.23: @emlMeasureBarData: zero is not "no data". emlBarData_mean[g] is now
#        UNDEFINED when the group has no usable observation, and
#        emlBarData_error[g] UNDEFINED when there is no error to compute,
#        instead of both being seeded to 0. v3.22 seeded them at 0 to keep
#        undefined out of the drawing commands; the side effect was that
#        @emlDrawBarChart's "<> undefined" guards for the bar and the whisker
#        could never fire, so a group with nothing in it drew as a bar of
#        height zero — indistinguishable from a measured zero — and an
#        undefined error bar vanished in silence. Both are now suppressed by
#        the existing guards and disclosed. The visible-range fold at the end
#        of the procedure substitutes 0 for an undefined error so the axis
#        range is unaffected. See the invariant block on @emlMeasureBarData.
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
#            bar). emlBarData_mean[] and emlBarData_error[] were made
#            guaranteed-defined on return (SUPERSEDED by v3.23, which
#            restores undefined as the "no measurement" sentinel and puts the
#            burden of guarding back on the callers, where it already was).
#            New disclosure globals: emlBarData_valid[],
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
    # Legend placement (D136). 1 Inside plot / 2 Right of plot / 3 Below plot
    # / 4 Separate figure / 5 None. 1 is the default everywhere, and it is
    # the placement whose exported extent equals the plot rectangle — a
    # standalone script that sets nothing gets the figure it has always got.
    # The plugin does not call this procedure; it sets emlLegendPlacement
    # from config_legendPlacement in eml-graphs-form.praat.
    emlLegendPlacement = 1
    # The parked-legend handshake for placement 4, cleared here so a save
    # path can test it without variableExists.
    emlLegendSepActive = 0
    # Which background an on-figure box last got — "sprite", "screen" or
    # "opaque", written by @emlPaintAlphaBox. Seeded here for the same reason
    # as the line above: so a caller can read it without variableExists. The
    # companion flag is the once-per-session latch on the Info-window NOTE.
    emlAlphaBgMode$ = ""
    emlAlphaBgDisclosed = 0
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
    ; scatterAnalysisType was the one member of this set that was NOT seeded
    ; here, and @emlDrawScatterPlot reads it unconditionally on the annotate
    ; path. So every non-form caller -- a PraatGen script, a harness case,
    ; this repository's own axis probes -- aborted the whole figure at
    ; "Unknown variable: (scatterAnalysisType" the moment annotate was 1,
    ; while annotate = 0 sailed through. Found 15 Aug 2026 building the
    ; clipping reproduction. Same reasoning as the categorical-label seeds
    ; above: seed the neutral value, let any caller that knows better
    ; overwrite it. 0 = neither correlation nor regression requested, which
    ; is the value the form itself initialises to.
    scatterAnalysisType = 0
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
# Populates colour AND FILL-PATTERN arrays for data series.
#
# THE STYLE SPACE IS TWO-DIMENSIONAL (v1.23, author's ruling 7 Aug 2026).
#
# Before this revision the procedure declared TEN fill/line pairs, and slots 9
# and 10 were literal duplicates of 1 and 2: .fill$[9] and .fill$[1] were both
# "{0.70, 0.83, 0.91}", .fill$[10] and .fill$[2] both "{0.97, 0.89, 0.70}",
# and the line colours duplicated identically. The cycling rule above ten was
# `mod 8`, which is the giveaway -- this was always an EIGHT-colour palette
# whose literal declarations happened to run to ten. A nine- or ten-sub-group
# figure therefore drew two pairs of sub-groups in INDISTINGUISHABLE colours,
# on the figure and in the legend, and said nothing about it (D127).
#
# The fix is not to cut the ceiling to eight. It is to add a second dimension
# the eye reads independently of hue:
#
#     8 hues  x  3 fill patterns  =  24 distinguishable sub-group styles
#
# ORDERING -- HUE CYCLES FIRST:
#     index   1..8    the eight hues, SOLID
#     index   9..16   the same eight hues, DIAGONAL HATCH
#     index  17..24   the same eight hues, DOTTED
#
#     hue     = ((index - 1) mod 8) + 1
#     pattern = (((index - 1) div 8) mod 3) + 1      1 solid, 2 hatch, 3 dots
#
# Hue-first is deliberate. Sub-groups take consecutive indices, so ADJACENT
# sub-groups differ in hue -- the stronger cue -- and the weaker cue (pattern)
# only ever has to separate marks that are eight apart. Pattern-first would
# have put three near-identical blues next to each other.
#
# Above 24 the pair (hue, pattern) repeats. That is the ceiling
# @emlDrawGroupedViolin and @emlDrawGroupedBoxPlot hold at 24 and disclose;
# it is not raised silently anywhere.
#
# Arguments: mode$ ("color" or "bw")
#
# Outputs:
#   .line$[1..100]      stroke colour        (hue only -- repeats every 8)
#   .fill$[1..100]      body fill colour     (hue only -- repeats every 8)
#   .lightLine$[1..100] 50% blend to white   (hue only -- repeats every 8)
#   .sprite$[1..100]    alpha sprite stem    (hue only -- repeats every 8)
#   .pattern[1..100]    1 solid | 2 diagonal hatch | 3 dots   (AREA marks)
#   .marker[1..100]     1 circle | 2 square | 3 triangle      (POINT marks)
#   .hue[1..100]        which of the eight hues this index carries
#   .nHues = 8, .nPatterns = 3, .nMarkers = 3, .nStyles = 24
#
# TWO SECOND DIMENSIONS, ONE INDEX (v1.24, author's ruling 7 Aug 2026: "in
# terms of the scatter line spaghetti and time series ... we need to go ahead
# and add a square and a triangle").
#
# .pattern is a FILL pattern and needs an area to live in. A scatter dot, a
# spaghetti endpoint and a line-chart vertex have no area to fill, so those
# four chart types read .pattern, found nothing they could draw, and cycled
# eight hues silently above eight groups -- the same silence D127 was. Their
# second dimension is the marker SHAPE, and it is the same arithmetic on the
# same index, so slot i is "hue h, style band b" for both families and the
# cap is 24 for both:
#
#     .pattern[i] = .marker[i] = (((i - 1) div 8) mod 3) + 1
#
# The two are separate arrays anyway, deliberately: they are read by
# different procedures, a consumer that wants one and gets the other is a
# bug, and naming the shape "pattern" would have hidden it.
#
# NOTE THE ASYMMETRY. .line$[9] and .fill$[9] are IDENTICAL to index 1 by
# construction. That is not D127 coming back: .pattern differs, so the drawn
# mark differs. But it does mean that any consumer that reads .line$/.fill$
# and IGNORES .pattern is back to drawing two sub-groups the same way. That
# is exactly what the legend used to do, and why @emlDrawLegend now reads the
# pattern too.
#
# Note: For API users who need custom colours, set .line$[n], .fill$[n],
# .lightLine$[n] and .pattern[n] directly after calling this procedure.
# ----------------------------------------------------------------------------
procedure emlSetColorPalette: .mode$
    .nHues = 8
    .nPatterns = 3
    .nMarkers = 3
    .nStyles = .nHues * .nPatterns
    # Which branch ran, said out loud. @emlOptimizePaletteContrast used to
    # sniff this by comparing .line$[2] against the literal "{0.35, 0.35,
    # 0.35}" -- a test that silently reclassified the whole palette as
    # "colour" the moment the grey ramp changed, which it does below.
    .isBW = 1
    if .mode$ = "color"
        .isBW = 0
    endif

    if .mode$ = "color"
        # Okabe-Ito palette (accessible for colour vision deficiency).
        # EIGHT hues, declared once each. There is no ninth.
        # Line colours
        .line$[1] = "{0.00, 0.45, 0.70}"
        .line$[2] = "{0.90, 0.62, 0.00}"
        .line$[3] = "{0.34, 0.71, 0.91}"
        .line$[4] = "{0.00, 0.62, 0.45}"
        .line$[5] = "{0.84, 0.37, 0.00}"
        .line$[6] = "{0.80, 0.47, 0.65}"
        .line$[7] = "{0.95, 0.90, 0.25}"
        .line$[8] = "{0.00, 0.00, 0.00}"
        # Fill colours (70% blend toward white)
        .fill$[1] = "{0.70, 0.83, 0.91}"
        .fill$[2] = "{0.97, 0.89, 0.70}"
        .fill$[3] = "{0.80, 0.91, 0.97}"
        .fill$[4] = "{0.70, 0.89, 0.83}"
        .fill$[5] = "{0.95, 0.81, 0.70}"
        .fill$[6] = "{0.94, 0.84, 0.90}"
        .fill$[7] = "{0.99, 0.97, 0.78}"
        .fill$[8] = "{0.70, 0.70, 0.70}"
        # Light line colours (50% blend toward white)
        .lightLine$[1] = "{0.50, 0.73, 0.85}"
        .lightLine$[2] = "{0.95, 0.81, 0.50}"
        .lightLine$[3] = "{0.67, 0.85, 0.96}"
        .lightLine$[4] = "{0.50, 0.81, 0.73}"
        .lightLine$[5] = "{0.92, 0.69, 0.50}"
        .lightLine$[6] = "{0.90, 0.73, 0.82}"
        .lightLine$[7] = "{0.98, 0.95, 0.63}"
        .lightLine$[8] = "{0.50, 0.50, 0.50}"
        # Alpha sprite stems (match line$ ordering for group consistency)
        .sprite$[1] = "blue"
        .sprite$[2] = "orange"
        .sprite$[3] = "skyblue"
        .sprite$[4] = "green"
        .sprite$[5] = "vermillion"
        .sprite$[6] = "purple"
        .sprite$[7] = "yellow"
        .sprite$[8] = "black"
    else
        # B&W: EIGHT greys evenly spaced over the usable print range.
        #
        # v1.23: the old branch declared ten fills between 0.82 and 0.96 --
        # fifteen thousandths of luminance apart at the closest pair, which
        # neither a printer nor an eye resolves.
        #
        # v1.24 (author's ruling, 7 Aug 2026: "a very narrow grayscale range
        # ... make sure that we have a wide range across the entire potential
        # palette"). The 0.90 -> 0.25 ramp that replaced it spanned 0.65 of a
        # possible 1.00 and was still bounded by an accident: the stroke was
        # DERIVED from the fill as fill - 0.30, clamped at zero, so the fill
        # could not go below 0.30 without the stroke ramp collapsing. It
        # already had: with fills reaching 0.25 the two darkest strokes were
        # 0.043 and 0.000, four hundredths apart, and a greyscale LINE chart
        # (which draws in .line$ and never touches .fill$) therefore had two
        # series in indistinguishable ink at eight groups. Same defect class
        # as D127, in the other array.
        #
        # The two ramps are now INDEPENDENT, because they do different jobs:
        #
        #   .fill$   the body of an area mark, read against the WHITE PAGE.
        #            0.94 down to 0.10 in steps of 0.12 -- 84% of the full
        #            range. 0.94 still separates from the page (and every mark
        #            is outlined); 0.10 still separates from pure black text
        #            and axis ink.
        #   .line$   ink drawn ON the page: series lines, scatter points,
        #            outlines, medians, whiskers, hatch. 0.63 down to 0.00 in
        #            steps of 0.09. 0.63 is about as pale as a 1-2 pt line
        #            survives at 300 dpi; nothing paler is offered.
        #
        # Direct pairing (pale fill with pale ink) keeps a slot's fill and its
        # stroke recognisably the same "value", but it leaves the dark end
        # with a dark stroke on a dark fill. That is what @emlMarkInk fixes,
        # at the point of drawing, by the same rule @emlPatternSetup already
        # used for the hatch: when a mark's stroke does not separate from its
        # own fill, the stroke flips to white (dark fill) or black (light
        # fill). Slots 4-8 flip; slots 1-3 do not. Measured minimum separation
        # on the rendered pixels: 0.1176 (was 0.090). This said 0.120, which
        # disagreed with the same measurement in this file's own v3.25 header
        # and with the check that produces it — `MEASURED minimum greyscale
        # separation` in validate/v29_figure_disclosure.R, which reports
        # 0.1176 and asserts it clears 0.110.
        .fillMax = 0.94
        .fillMin = 0.10
        .inkMax = 0.63
        .inkMin = 0.00
        for .h from 1 to .nHues
            .fillVal = .fillMax - (.h - 1) * (.fillMax - .fillMin) / (.nHues - 1)
            .lineVal = .inkMax - (.h - 1) * (.inkMax - .inkMin) / (.nHues - 1)
            .lightVal = (.fillVal + .lineVal) / 2
            .fill$[.h] = "{" + fixed$ (.fillVal, 2) + ", "
            ... + fixed$ (.fillVal, 2) + ", " + fixed$ (.fillVal, 2) + "}"
            .line$[.h] = "{" + fixed$ (.lineVal, 2) + ", "
            ... + fixed$ (.lineVal, 2) + ", " + fixed$ (.lineVal, 2) + "}"
            .lightLine$[.h] = "{" + fixed$ (.lightVal, 2) + ", "
            ... + fixed$ (.lightVal, 2) + ", " + fixed$ (.lightVal, 2) + "}"
        endfor
        # Alpha sprite stems -- grey-based (v5): sprites use distinct grey RGB
        # values at fixed alpha, so dense overlap darkens but never reaches
        # pure black. Ordered: medium contrast first for the 2-group case.
        # 2 groups: bw04 (dark-medium grey) + bw08 (light grey)
        # 3 groups: adds bw06 (medium-light)
        .sprite$[1] = "bw04"
        .sprite$[2] = "bw08"
        .sprite$[3] = "bw06"
        .sprite$[4] = "bw02"
        .sprite$[5] = "bw09"
        .sprite$[6] = "bw05"
        .sprite$[7] = "bw03"
        .sprite$[8] = "bw07"
    endif

    # The second dimension, and the cycle above it -- identical in both
    # branches. Indices 1..8 keep the hue they were just given and take
    # pattern 1; 9..16 repeat the hues under pattern 2; 17..24 under
    # pattern 3; 25+ repeat the whole 24-style space.
    for .i from 1 to 100
        .hIdx = ((.i - 1) mod .nHues) + 1
        .hue[.i] = .hIdx
        .pattern[.i] = (((.i - 1) div .nHues) mod .nPatterns) + 1
        .marker[.i] = (((.i - 1) div .nHues) mod .nMarkers) + 1
        if .i > .nHues
            .line$[.i] = .line$[.hIdx]
            .fill$[.i] = .fill$[.hIdx]
            .lightLine$[.i] = .lightLine$[.hIdx]
            .sprite$[.i] = .sprite$[.hIdx]
        endif
    endfor

    # A legend shows a fill pattern only when the caller asks for one. Every
    # draw procedure calls this procedure first, so clearing the flag HERE is
    # what stops a patterned grouped violin from leaking its patterns into
    # the next figure's legend inside the same Praat session.
    legendPatterned = 0
    # Same argument, same place, for the marker key: a scatter drawn after a
    # grouped violin in one session must not inherit the violin's swatches,
    # and a violin drawn after a scatter must not inherit its markers.
    legendMarkered = 0
    legendMarkerLine = 0
endproc

# ----------------------------------------------------------------------------
# @emlOptimizePaletteContrast
# Reorders palette arrays to maximize perceptual distance for K groups.
# Must be called AFTER @emlSetColorPalette and BEFORE any drawing.
# For K < 7, skips sky blue (index 3) to avoid blue/skyblue confusion,
# and defers vermillion (5) when K < 5 to avoid orange/vermillion overlap.
# Arguments: .nGroups (number of groups that will be drawn)
# Side effect: overwrites emlSetColorPalette arrays [1..nGroups]
#
# v1.23: this procedure permutes HUE ONLY. emlSetColorPalette.pattern[] is
# indexed by slot, not by hue, so it is deliberately left alone: slots 1-8
# stay solid, 9-16 hatched, 17-24 dotted whatever hues land in them, and each
# band of eight still receives a permutation of the eight hues. That is what
# keeps all 24 (hue, pattern) pairs distinct after optimisation.
#
# v1.24: emlSetColorPalette.marker[] is left alone for exactly the same
# reason -- slots 1-8 circles, 9-16 squares, 17-24 triangles, whatever hues
# land in them -- so all 24 (hue, marker) pairs stay distinct too.
# ----------------------------------------------------------------------------
procedure emlOptimizePaletteContrast: .nGroups
    # Only remap for 2+ groups
    if .nGroups >= 2
        # Save originals. 24 slots, not 10 -- the sub-group ceiling is now 24
        # and .src can name any of them.
        for .i from 1 to 24
            .origLine$[.i] = emlSetColorPalette.line$[.i]
            .origFill$[.i] = emlSetColorPalette.fill$[.i]
            .origLightLine$[.i] = emlSetColorPalette.lightLine$[.i]
            .origSprite$[.i] = emlSetColorPalette.sprite$[.i]
        endfor

        # Which branch @emlSetColorPalette ran, read from the flag it sets.
        # This used to compare .origLine$[2] against the literal "{0.35,
        # 0.35, 0.35}", which stopped being the B/W value the moment the grey
        # ramp was respread -- a silent reclassification of every B/W figure
        # as colour.
        .isBW = emlSetColorPalette.isBW

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
            else
                # 9+ groups: the 8-hue optimised order, REPEATED VERBATIM in
                # every band of eight. v1.23: the band above eight used to be
                # the raw declaration order (blue, orange, skyblue, green...)
                # while the band below it was the optimised one (blue,
                # orange, green, purple...), so slot 3 was green and slot 11
                # was skyblue-hatched and the key read as sixteen unrelated
                # styles. Repeating the order makes the structure legible:
                # slot i and slot i+8 are THE SAME HUE under a different fill
                # pattern, which is exactly what the palette is.
                .src[1] = 1
                .src[2] = 2
                .src[3] = 4
                .src[4] = 6
                .src[5] = 7
                .src[6] = 3
                .src[7] = 5
                .src[8] = 8
                for .i from 9 to .nGroups
                    .bandIdx = ((.i - 1) mod 8) + 1
                    .src[.i] = .src[.bandIdx]
                endfor
            endif
        else
            # === B/W MODE ===
            # The same TWO INDEPENDENT RAMPS @emlSetColorPalette declares,
            # spread over however many groups there are rather than over
            # eight, so a two-group figure gets the extreme ends and a
            # six-group figure gets six evenly spaced steps. Ascending here
            # (group 1 darkest), which is the direction this procedure has
            # always used; the base palette declares the same values
            # descending. Same set either way -- what must not drift is the
            # ENDPOINTS, and they are named once in each place and stated in
            # the comment on @emlSetColorPalette's B/W branch.
            #
            # v1.24: .lineVal is no longer fill - 0.30. That derivation is
            # what pinned .fillMin at 0.25 (below it the stroke ramp clamped
            # at zero and collapsed) and it had already collapsed at the
            # bottom two slots. See @emlSetColorPalette and @emlMarkInk.
            .fillMin = 0.10
            .fillMax = 0.94
            .inkMin = 0.00
            .inkMax = 0.63
            .distinctN = min (.nGroups, 8)
            for .i from 1 to .distinctN
                if .distinctN > 1
                    .t = (.i - 1) / (.distinctN - 1)
                else
                    .t = 0.5
                endif
                .fillVal = .fillMin + .t * (.fillMax - .fillMin)
                .lineVal = .inkMin + .t * (.inkMax - .inkMin)
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

# ============================================================================
# FILL PATTERNS
# ============================================================================
# Praat has no native pattern fill. What works, and renders cleanly at
# 300 dpi, is to paint the shape solid and then draw the pattern OVER it,
# clipped to the shape by arithmetic the caller is already doing:
#
#   @emlDrawViolin already paints the body as a stack of ~500 thin horizontal
#   Paint rectangle slices, each with a known centre and half-width. For any
#   scanline the left and right extent of the body are therefore already in
#   hand, and a diagonal stripe clipped to that scanline is one subtraction.
#   @emlDrawBox is a rectangle, which is the same thing with a constant
#   half-width. NO GENERAL POLYGON CLIP IS COMPUTED ANYWHERE.
#
# Pattern codes, matching emlSetColorPalette.pattern[]:
#   1  solid            nothing drawn over the fill
#   2  diagonal hatch   45 degrees on the page, up to the right
#   3  dots             hexagonally packed, each dot drawn only where the
#                       WHOLE dot fits inside the shape, so no dot is ever
#                       chopped in half at the outline
#
# Anything other than 2 or 3 is treated as solid, so an uninitialised or
# out-of-range pattern degrades to today's behaviour rather than to an error.
# ----------------------------------------------------------------------------

# ----------------------------------------------------------------------------
# @emlSetPatternScale
# Records the world-units-per-inch of the CURRENTLY INSTALLED axes, so that
# the pattern primitives can lay out a hatch at 45 degrees ON THE PAGE and a
# dot grid that is round on the page, rather than at whatever angle the ratio
# of the two axis ranges happens to imply.
#
# Call once, immediately after `Axes:`, in any procedure that will draw a
# patterned mark. @emlDrawViolin and @emlDrawBox fall back to an assumed
# geometry when it has never been called, so an API caller that forgets gets
# a slightly-off hatch angle, not a wrong figure.
#
# IT ALSO PUBLISHES THE FRAME ITSELF (15 Aug 2026, NEW-G8-1). The four
# numbers handed in here ARE the plotting frame -- they are what was just
# passed to `Axes:` -- and until now nothing recorded them, so no primitive
# could tell a point inside the box from a point beyond it. Praat does not
# clip: `Paint circle` at x = 322 on an axis that stops at 300 draws a dot in
# the MARGIN, on top of the tick labels, at a horizontal position that
# corresponds to no value on the axis. A reader has no way to know it is not
# data. Publishing the frame here is what lets @emlDrawMarker and
# @emlDrawAlphaDot refuse it; see @emlPointInFrame.
#
# Every procedure that draws point markers already calls this immediately
# after its own `Axes:`, which is why the frame is always the current one at
# the moment a marker is placed. A caller that never calls it leaves
# emlFrameKnown at 0 and nothing clips -- the old behaviour, unchanged.
#
# Arguments: .xMin, .xMax, .yMin, .yMax (the axes just installed)
# Sets globals: emlPatWorldPerInchX, emlPatWorldPerInchY,
#               emlFrameXMin, emlFrameXMax, emlFrameYMin, emlFrameYMax,
#               emlFrameKnown
# ----------------------------------------------------------------------------
procedure emlSetPatternScale: .xMin, .xMax, .yMin, .yMax
    .innerW = emlSetAdaptiveTheme.innerRight - emlSetAdaptiveTheme.innerLeft
    .innerH = emlSetAdaptiveTheme.innerBottom - emlSetAdaptiveTheme.innerTop
    emlPatWorldPerInchX = 0
    emlPatWorldPerInchY = 0
    if .innerW > 0
        emlPatWorldPerInchX = (.xMax - .xMin) / .innerW
    endif
    if .innerH > 0
        emlPatWorldPerInchY = (.yMax - .yMin) / .innerH
    endif
    emlFrameXMin = min (.xMin, .xMax)
    emlFrameXMax = max (.xMin, .xMax)
    emlFrameYMin = min (.yMin, .yMax)
    emlFrameYMax = max (.yMin, .yMax)
    emlFrameKnown = 1
endproc

# ----------------------------------------------------------------------------
# @emlPointInFrame: .x, .y
# Is this data point inside the plotting frame the current axes describe?
#
# Outputs
#   .inside  1 = draw it, 0 = it is outside the frame the user asked for
#
# WHY (NEW-G8-1, severity 3, 15 Aug 2026). A user who types an axis range is
# choosing what the figure is about. Praat's drawing primitives take that as
# a coordinate transform and nothing more: a point beyond the range is
# converted to a page position beyond the box and painted there. Measured on
# a 30-row scatter with x typed as 100-300 against data running 90-322
# (harness/graphaxes/cases/repro_scatter_clip.praat): one dot sat on the "100"
# tick label and three sat in the right margin outside the box entirely, each
# at a page position that decodes to a value the axis does not contain.
#
# THIS DOES NOT CHANGE A SINGLE COMPUTED NUMBER, and that distinction is the
# whole of the design. The correlation, the regression, the n and the CSV are
# computed from every valid row and go on being computed from every valid
# row; a range is a VIEWPORT, not a filter, and a figure that quietly
# recomputed its statistics over the visible subset would be a far worse
# defect than the one being fixed. What changes is only whether ink is put
# down outside the box. The count of points withheld is tracked in
# emlClippedN so the caller can say so on the figure rather than let a reader
# assume the frame holds everything.
#
# UNSET FRAME MEANS NO CLIPPING. emlFrameKnown is 0 until @emlSetPatternScale
# has run for the current axes, and an API caller that never calls it gets
# exactly the behaviour this library has always had.
# ----------------------------------------------------------------------------
procedure emlPointInFrame: .x, .y
    .inside = 1
    if variableExists ("emlFrameKnown") = 0
        goto POINT_IN_FRAME_END
    endif
    if emlFrameKnown <> 1
        goto POINT_IN_FRAME_END
    endif
    ; Nested, never "or": Praat evaluates both operands and every comparison
    ; against undefined is FALSE, so an undefined coordinate would slip past
    ; a combined test. An undefined point is not inside anything.
    if .x = undefined
        .inside = 0
        goto POINT_IN_FRAME_END
    endif
    if .y = undefined
        .inside = 0
        goto POINT_IN_FRAME_END
    endif
    if .x < emlFrameXMin
        .inside = 0
    endif
    if .x > emlFrameXMax
        .inside = 0
    endif
    if .y < emlFrameYMin
        .inside = 0
    endif
    if .y > emlFrameYMax
        .inside = 0
    endif
    label POINT_IN_FRAME_END
endproc

# ----------------------------------------------------------------------------
# @emlResetClipCount
# Zero the running count of points withheld for falling outside the frame.
# Call immediately before a plotting loop; read emlClippedN after it.
# ----------------------------------------------------------------------------
procedure emlResetClipCount
    emlClippedN = 0
endproc

# ----------------------------------------------------------------------------
# @emlRegisterCollisionPoints: .x#, .y#, .n
# Publish the points that are actually ON THE PAGE, for @emlPlaceAnnotationBox
# to place the annotation panel around.
#
# ONLY THE POINTS INSIDE THE FRAME are registered, and that is not a detail:
# a point withheld by NEW-G8-1's clip was never drawn, so a box sitting where
# it would have been hides nothing. Counting it would push the panel away
# from a corner that is genuinely empty and into one that is not.
#
# Sets globals: emlCollideN, emlCollideX#, emlCollideY#
# ----------------------------------------------------------------------------
procedure emlRegisterCollisionPoints: .x#, .y#, .n
    emlCollideN = 0
    if .n < 1
        emlCollideX# = zero# (1)
        emlCollideY# = zero# (1)
        goto REGISTER_COLLIDE_END
    endif
    emlCollideX# = zero# (.n)
    emlCollideY# = zero# (.n)
    for .i from 1 to .n
        @emlPointInFrame: .x#[.i], .y#[.i]
        if emlPointInFrame.inside = 1
            emlCollideN = emlCollideN + 1
            emlCollideX#[emlCollideN] = .x#[.i]
            emlCollideY#[emlCollideN] = .y#[.i]
        endif
    endfor
    label REGISTER_COLLIDE_END
endproc

# ----------------------------------------------------------------------------
# @emlPatternSetup
# Everything a patterned fill needs, in one call: the world-per-inch scales,
# the stripe/dot geometry in inches scaled to the mark being drawn, and the
# ink colour.
#
# Arguments:
#   .fillColor$   the fill the pattern will be drawn on top of
#   .lineColor$   the mark's stroke colour
#   .halfWidth    half-width of the mark in x world units
#   .yMin, .yMax  the y axis range (used only for the scale fallback)
#
# Outputs (inches unless stated):
#   .sx, .sy      world units per inch, x and y   (world, per inch)
#   .halfIn       .halfWidth expressed in inches
#   .pitch        distance between stripe centres, measured along x
#   .stripe       stripe thickness, measured along x
#   .dotPitch     dot centre spacing, both axes
#   .dotR         dot radius
#   .ink$         the colour to draw the pattern in
#   .usable       0 when the geometry degenerates (zero-width mark, no scale)
#
# THE INK. White-on-fill is what the prototype used, and it fails on this
# palette: every colour fill is a 70% blend toward white, so a white hatch on
# "{0.99, 0.97, 0.78}" (pale yellow) is very nearly invisible, and the same
# is true of the light end of the grey ramp. The pattern is therefore drawn
# in the mark's own stroke colour -- which is the SAME hue, so the pattern
# cannot be mistaken for a different sub-group -- except on fills dark enough
# that a dark stroke would disappear into them, where it flips.
#
# v1.24: the rule moved to @emlMarkInk, which the mark's OUTLINE, median and
# whiskers now use as well, so a mark is drawn in exactly one ink throughout
# instead of a hatch that flips and an outline that does not. See there for
# why the test is per-channel rather than on the red channel alone.
# ----------------------------------------------------------------------------
procedure emlPatternSetup: .fillColor$, .lineColor$, .halfWidth, .yMin, .yMax
    .usable = 1

    # World-per-inch, from @emlSetPatternScale when it has run.
    .sx = 0
    .sy = 0
    if variableExists ("emlPatWorldPerInchX")
        .sx = emlPatWorldPerInchX
    endif
    if variableExists ("emlPatWorldPerInchY")
        .sy = emlPatWorldPerInchY
    endif
    if .sx = undefined
        .sx = 0
    endif
    if .sy = undefined
        .sy = 0
    endif
    # Fallback: assume a mark 0.15 inches wide on a 3-inch-tall panel. Wrong
    # in detail, right in order of magnitude, and it keeps the hatch a hatch.
    if .sx <= 0
        .sx = .halfWidth / 0.15
    endif
    if .sy <= 0
        .sy = (.yMax - .yMin) / 3.0
    endif
    if .sx <= 0
        .usable = 0
        .sx = 1
    endif
    if .sy <= 0
        .usable = 0
        .sy = 1
    endif

    .halfIn = .halfWidth / .sx
    if .halfIn <= 0
        .usable = 0
    endif

    # Stripe pitch scales with the mark so a narrow sub-violin still carries
    # about three stripes, and is then clamped: below ~0.022" the stripes
    # merge into a tint at 300 dpi, above ~0.075" a single wide mark shows
    # only one or two and reads as a stray line.
    .pitch = .halfIn * 0.62
    if .pitch < 0.022
        .pitch = 0.022
    endif
    if .pitch > 0.075
        .pitch = 0.075
    endif
    .stripe = .pitch * 0.40

    .dotPitch = .pitch * 1.20
    .dotR = .dotPitch * 0.26

    # Ink -- one rule, one place. @emlMarkInk is idempotent, so it does not
    # matter whether the caller already flipped the stroke it handed in.
    @emlMarkInk: .fillColor$, .lineColor$
    .ink$ = emlMarkInk.result$
endproc

# ----------------------------------------------------------------------------
# @emlParseRGB
# Pulls the three channels out of a Praat colour string "{r, g, b}".
#
# extractNumber (s$, prefix$) reads the first number AFTER the first
# occurrence of prefix$, so "{" gives red and "," gives green directly; blue
# needs the string re-anchored past the first comma first.
#
# Arguments: .rgb$
# Outputs:   .r, .g, .b   channels, 0..1  (0 when .ok = 0)
#            .ok          1 when all three parsed; 0 for a NAMED colour
#                         ("Black", "White", "Red"), which has no channels
#                         to read and must not be silently treated as {0,0,0}
# ----------------------------------------------------------------------------
procedure emlParseRGB: .rgb$
    .ok = 0
    .r = 0
    .g = 0
    .b = 0
    .rr = extractNumber (.rgb$, "{")
    .gg = extractNumber (.rgb$, ",")
    .comma = index (.rgb$, ",")
    .rest$ = ""
    if .comma > 0
        .rest$ = right$ (.rgb$, length (.rgb$) - .comma)
    endif
    .bb = extractNumber (.rest$, ",")
    # Nested, not "or": Praat evaluates both operands of or/and regardless.
    .bad = 0
    if .rr = undefined
        .bad = 1
    endif
    if .gg = undefined
        .bad = 1
    endif
    if .bb = undefined
        .bad = 1
    endif
    if .bad = 0
        .r = .rr
        .g = .gg
        .b = .bb
        .ok = 1
    endif
endproc

# ----------------------------------------------------------------------------
# @emlMarkInk
# The colour a mark's own detail is drawn in: outline, median, whiskers, and
# the hatch or dot pattern. Normally that is the mark's stroke colour -- same
# hue as the fill, so the detail can never be mistaken for a different
# sub-group. When the stroke does not separate from the fill it flips to
# white (on a dark fill) or black (on a light one).
#
# PER CHANNEL, not on the red channel and not on a luminance conversion.
# Okabe-Ito yellow is fill {0.99, 0.97, 0.78} against stroke
# {0.95, 0.90, 0.25}: the red channels are FOUR HUNDREDTHS apart and the blue
# channels are 0.53 apart. A red-channel test (which is what @emlPatternSetup
# used before v1.24, and which was correct while every fill was a pastel or a
# grey) declares yellow unreadable and paints its hatch black -- a visible
# regression, and one that would have been introduced by this very change.
# Rec.601 luminance makes the same mistake for the same reason: it weights
# blue at 0.114. The channel that actually carries the contrast decides.
#
# THRESHOLD 0.235. Below about a quarter a 0.5 pt outline and a 0.4 pt hatch
# stripe stop reading at 300 dpi. On the v1.24 greyscale ramp the fill/stroke
# separation runs 0.31, 0.28, 0.25, 0.22, 0.19, 0.16, 0.13, 0.10 down the
# eight slots, so slots 1-3 keep their grey stroke and slots 4-8 flip --
# slot 4 to black (its fill is 0.58, light), slots 5-8 to white. No pair in
# the colour palette is closer than 0.37 on its best channel, so NO COLOUR
# FILL EVER FLIPS; the colour figures this repo already ships are unchanged.
#
# The odd-looking 0.235 is deliberate: it sits halfway between the two ramp
# separations it has to separate, 0.22 and 0.25. A round 0.25 lands ON one of
# them, and "0.70 - 0.45 < 0.25" is TRUE in IEEE doubles (0.24999999999999997)
# and false in decimal, so slot 3 flipped or did not flip depending on how
# the ramp happened to be rounded. Measured that way once, on the render:
# slot 11's hatch came out black instead of the 0.45 grey the ramp asks for.
#
# Arguments: .fillColor$, .strokeColor$
# Output:    .result$   the ink, as an "{r, g, b}" string or the stroke as
#                       handed in. Idempotent: feeding .result$ back in as
#                       the stroke returns it unchanged, because white on a
#                       dark fill and black on a light one both separate.
# ----------------------------------------------------------------------------
procedure emlMarkInk: .fillColor$, .strokeColor$
    .result$ = .strokeColor$
    @emlParseRGB: .fillColor$
    .fOk = emlParseRGB.ok
    .fr = emlParseRGB.r
    .fg = emlParseRGB.g
    .fb = emlParseRGB.b
    @emlParseRGB: .strokeColor$
    .sOk = emlParseRGB.ok
    .sr = emlParseRGB.r
    .sg = emlParseRGB.g
    .sb = emlParseRGB.b
    # A named colour on either side cannot be measured, so it is left alone.
    .measurable = 0
    if .fOk = 1
        if .sOk = 1
            .measurable = 1
        endif
    endif
    if .measurable = 1
        .sep = abs (.fr - .sr)
        if abs (.fg - .sg) > .sep
            .sep = abs (.fg - .sg)
        endif
        if abs (.fb - .sb) > .sep
            .sep = abs (.fb - .sb)
        endif
        if .sep < 0.235
            .lum = (.fr + .fg + .fb) / 3
            if .lum < 0.5
                .result$ = "{1.00, 1.00, 1.00}"
            else
                .result$ = "{0.00, 0.00, 0.00}"
            endif
        endif
    endif
endproc

# ----------------------------------------------------------------------------
# @emlPaintHatchRow
# One scanline of a 45-degree hatch, clipped to [.xC - .d, .xC + .d].
#
# The stripe family is x_inches = y_inches + k * pitch, k integer, with
# x measured from the mark's centre and y from the axis floor. Solving for
# the k that can touch this scanline is two divisions; each surviving k
# contributes one Paint rectangle whose x extent is the stripe intersected
# with the body. That is the whole "clip" -- there is no polygon anywhere.
#
# Phase is locked to the MARK'S CENTRE, not to the panel, so every violin in
# a figure carries the same stripe phase and the legend swatch can reproduce
# it exactly.
#
# Arguments: .xC (centre, world x), .d (half-width, world x), .y1, .y2
#            (the scanline's world y extent), .yFloor (axis y minimum)
# Reads: emlPatternSetup.sx / .sy / .pitch / .stripe / .ink$
# ----------------------------------------------------------------------------
procedure emlPaintHatchRow: .xC, .d, .y1, .y2, .yFloor
    if .d > 0
        .dIn = .d / emlPatternSetup.sx
        .yIn = ((.y1 + .y2) / 2 - .yFloor) / emlPatternSetup.sy
        .p = emlPatternSetup.pitch
        .halfStripe = emlPatternSetup.stripe / 2
        .dNeg = 0 - .dIn
        .kLo = ceiling ((.dNeg - .halfStripe - .yIn) / .p)
        .kHi = floor ((.dIn + .halfStripe - .yIn) / .p)
        for .k from .kLo to .kHi
            .c = .yIn + .k * .p
            .a = .c - .halfStripe
            .b = .c + .halfStripe
            if .a < .dNeg
                .a = .dNeg
            endif
            if .b > .dIn
                .b = .dIn
            endif
            if .b > .a
                Paint rectangle: emlPatternSetup.ink$,
                ... .xC + .a * emlPatternSetup.sx,
                ... .xC + .b * emlPatternSetup.sx, .y1, .y2
            endif
        endfor
    endif
endproc

# ----------------------------------------------------------------------------
# @emlPaintDotRow
# One row of the dot grid, at world y .y, clipped to [.xC - .d, .xC + .d].
#
# .d must already be the SMALLEST half-width over the row's full vertical
# extent, so that requiring |x| + r <= d guarantees the whole dot is inside
# the shape. Dots that would be clipped are not drawn at all: a half-eaten
# dot at the outline reads as a printing fault, an absent one reads as the
# taper it is.
#
# Rows alternate a half-pitch offset (hexagonal packing), which is what keeps
# the dot field from reading as a fine vertical stripe pattern and being
# confused with the hatch.
#
# Arguments: .xC, .d (world x), .y (world y), .row (integer row index),
#            .yFloor (axis y minimum)
# Reads: emlPatternSetup.sx / .dotPitch / .dotR / .ink$
# ----------------------------------------------------------------------------
procedure emlPaintDotRow: .xC, .d, .y, .row, .yFloor
    if .d > 0
        .dIn = .d / emlPatternSetup.sx - emlPatternSetup.dotR
        if .dIn > 0
            .p = emlPatternSetup.dotPitch
            .offset = 0
            if .row mod 2 <> 0
                .offset = .p / 2
            endif
            .dNeg = 0 - .dIn
            .kLo = ceiling ((.dNeg - .offset) / .p)
            .kHi = floor ((.dIn - .offset) / .p)
            for .k from .kLo to .kHi
                .cx = .offset + .k * .p
                Paint circle: emlPatternSetup.ink$,
                ... .xC + .cx * emlPatternSetup.sx, .y,
                ... emlPatternSetup.dotR * emlPatternSetup.sx
            endfor
        endif
    endif
endproc


# ============================================================================
# SCREEN-DOOR TRANSPARENCY — THE ALPHA BACKGROUND WITHOUT ALPHA
# ============================================================================
# An on-figure box (the legend panel, the annotation block) is supposed to sit
# on a SEMI-TRANSPARENT white ground, so that the box can be read without the
# data under it being deleted. The plugin gets that from sprites/
# bg_white_a70_40.png, a 40 x 40 PNG whose every pixel is RGBA
# (255, 255, 255, 179). MEASURED, not read off the filename: 179/255 = 0.702,
# so the sprite is a 70.2% white wash and the data under it survives at 29.8%
# of its contrast.
#
# @emlInitAlphaSprites refuses to hand that sprite out anywhere except macOS
# and Windows, and the refusal is correct: Praat's Graphics_imageFromFile has
# a GDI+ branch and a Quartz branch and no cairo branch, so on Linux
# `Insert picture from file:` computes its coordinates and draws NOTHING. No
# error, no return code. Confirmed here 9 Aug 2026 by rendering the same
# script with and without the call: `compare -metric AE` scores the two PNGs
# BYTE-IDENTICAL.
#
# So until this file, the fallback was `Paint rectangle: "White"` — an OPAQUE
# box. Same code, same figure, and a mac reader sees a violin through the
# legend where a Linux reader sees a white hole. That is the gap this section
# closes.
#
# WHAT IT DOES INSTEAD. Screen-door transparency: a fine white LATTICE, bars
# in both axes at a fixed pitch on the page, with square holes between them.
# Ink covers about 70% of the box and the holes leave the other 30% showing
# the data untouched. At 300 dpi the cell is 8 pixels, which reads as a wash
# rather than as a plaid, and no datum under the box is erased — it is
# sampled.
#
# WHY A LATTICE AND NOT A 45-DEGREE HATCH OR A DOT FIELD. The first attempt
# was @emlPaintHatchRow's construction with the roles reversed (white stripes
# at 45 degrees, thin gaps), because that is the pattern engine this file
# already has and a 45-degree screen is what a printer would use. It was
# built and MEASURED, and it fails here for two independent reasons:
#
#   1. PRAAT DOES NOT ANTIALIAS AND IT ROUNDS OUTWARD. Measured 9 Aug 2026 by
#      painting 25 rectangles of known sub-pixel width: every rendered pixel
#      is pure black or pure white (zero intermediate values over the whole
#      test), and the painted width is the asked-for width plus about one
#      device pixel. A hatch decomposed into 0.004-inch scanlines is a stack
#      of rectangles ~1.2 pixels tall, every one of them fattened by a pixel
#      in BOTH axes, and the screen closes up: measured coverage 0.94 against
#      an asked-for 0.70. A screen that collapses to solid is worse than no
#      screen at all.
#   2. It costs 140x more primitives for the same box (0.281 s against
#      0.002 s on a 0.7 x 0.6 inch patch), because a diagonal has to be
#      sliced and an axis-aligned lattice does not.
#
#      A hex DOT field fails on the same arithmetic from the other side. At
#      70% coverage the holes are the minority, so a field of white dots has
#      to nearly touch: the gap between neighbours is 0.12 of the pitch, which
#      is under one pixel at any pitch fine enough to read as a wash.
#
# The lattice is the same idea as those two — a periodic pattern clipped to a
# rectangle, phase-locked to the rectangle's own corner, scaled through
# emlPatWorldPerInchX/Y so the geometry is stated in INCHES ON THE PAGE and is
# the same at every figure size, exactly as @emlPatternSetup states the hatch
# pitch in inches. It just does not need slicing, because both bar families
# are axis-parallel and each is a single `Paint rectangle`.
#
# THE GEOMETRY, AND WHY THESE NUMBERS.
#
#   pitch  0.027 inch. @emlPatternSetup already carries this file's ruling on
#          what a periodic pattern may measure: "below ~0.022 inch the stripes
#          merge into a tint at 300 dpi, above ~0.075 inch a single wide mark
#          shows only one or two". 0.027 is just inside the fine end of that
#          band — 8.1 pixels at 300 dpi, 16.2 at 600.
#   bar    the geometric answer, LESS A KERF. A lattice of bars covering
#          fraction f of the pitch on each axis covers 1 - (1 - f)^2 of the
#          area, so 0.702 coverage wants f = 0.454. Praat then paints every
#          bar about one device pixel wider than asked (finding 1 above), so
#          the bar is specified 0.0023 inch — 0.7 pixel at 300 dpi — thinner
#          than that, and comes out right.
#
# MEASURED, on rendered pixels, three box phases x two resolutions:
#
#          asked   300 dpi   600 dpi        sprite, for comparison
#   ink     0.702    0.740     0.672         0.702
#   holes      —     0.260     0.328         0.298
#
# Both within 0.04 of the sprite, and the 0.34-0.40 bar-fraction plateau
# either side of the chosen 0.37 renders the SAME two numbers, so the setting
# is not balanced on a rounding edge. Vector output (PDF/EPS) has no pixel
# grid and no kerf, so the screen there is the nominal 0.60 — lighter than the
# sprite, which is the safe direction: more data survives, not less.
#
# WHAT IT DOES NOT DO. It does not touch the sprite path. On macOS and Windows
# @emlPaintAlphaBox issues exactly the `Insert picture from file:` it always
# issued, with the same arguments, and nothing below runs.
# ============================================================================

# ----------------------------------------------------------------------------
# @emlScreenSetup
# The screen's geometry for the CURRENTLY INSTALLED axes, in world units.
#
# Argument:
#   .coverage   the ink fraction the screen has to read as, 0..1. Pass the
#               sprite's own alpha (0.702) to stand in for the sprite.
#
# Outputs:
#   .usable     0 when there is no world-per-inch to scale by, or the
#               coverage is undefined or non-positive. A caller that gets 0
#               must fall back to whatever it did before — an unscaled
#               lattice is not a lattice, it is noise.
#   .pitchX, .pitchY, .barX, .barY   world units
#   .pitchIn, .barIn                 inches (what the geometry is stated in)
#
# Reads: emlPatWorldPerInchX / emlPatWorldPerInchY (@emlSetPatternScale), both
# through variableExists, so a caller that never set them gets .usable = 0
# rather than an aborted figure.
# ----------------------------------------------------------------------------
procedure emlScreenSetup: .coverage
    .usable = 1

    .sx = 0
    .sy = 0
    if variableExists ("emlPatWorldPerInchX")
        .sx = emlPatWorldPerInchX
    endif
    if variableExists ("emlPatWorldPerInchY")
        .sy = emlPatWorldPerInchY
    endif
    # Nested, never "or": Praat evaluates both operands of and/or, and every
    # comparison against undefined is FALSE rather than an error, so undefined
    # is tested for on its own line.
    if .sx = undefined
        .sx = 0
    endif
    if .sy = undefined
        .sy = 0
    endif
    if .sx <= 0
        .usable = 0
    endif
    if .sy <= 0
        .usable = 0
    endif

    .cov = .coverage
    if .cov = undefined
        .cov = 0
    endif
    if .cov <= 0
        .usable = 0
        .cov = 0
    endif
    if .cov >= 1
        .cov = 0.999
    endif

    # See the section header for the pitch, the kerf, and the measurements.
    .pitchIn = 0.027
    .kerfIn = 0.0023
    .frac = 1 - sqrt (1 - .cov)
    .barIn = .frac * .pitchIn - .kerfIn
    # A bar thinner than a seventh of the pitch is a hairline the rasterizer
    # decides the width of; one thicker than six sevenths leaves no hole. Both
    # ends are clamped so an out-of-range .coverage degrades to a legible
    # screen rather than to a solid block or to nothing.
    if .barIn < 0.15 * .pitchIn
        .barIn = 0.15 * .pitchIn
    endif
    if .barIn > 0.85 * .pitchIn
        .barIn = 0.85 * .pitchIn
    endif

    .pitchX = 0
    .pitchY = 0
    .barX = 0
    .barY = 0
    if .usable = 1
        .pitchX = .pitchIn * .sx
        .pitchY = .pitchIn * .sy
        .barX = .barIn * .sx
        .barY = .barIn * .sy
    endif
endproc

# ----------------------------------------------------------------------------
# @emlPaintScreenRect
# Paints the screen over one rectangle.
#
# Arguments: .x0, .x1, .y0, .y1 (world: left, right, bottom, top),
#            .ink$ (the screen's colour — "White" for a background),
#            .coverage (see @emlScreenSetup)
#
# Output: .done — 1 if a screen was painted, 0 if the geometry was unusable
#         and the caller must fall back.
#
# PHASE IS LOCKED TO THE RECTANGLE'S OWN BOTTOM-LEFT CORNER, for the reason
# @emlPaintHatchRow locks its stripes to the mark's centre: a screen phased to
# the panel would shift under a box that moved by half a cell, and two boxes
# on one figure would carry visibly different textures.
#
# The top and right edges are closed with a bar of their own. Without them the
# lattice ends in whatever fraction of a cell the box height happened to
# leave — up to a full 0.027 inch of unscreened data directly under the box's
# own border, which reads as a leak rather than as a screen.
# ----------------------------------------------------------------------------
procedure emlPaintScreenRect: .x0, .x1, .y0, .y1, .ink$, .coverage
    .done = 0
    @emlScreenSetup: .coverage
    .go = emlScreenSetup.usable
    if .x1 - .x0 <= 0
        .go = 0
    endif
    if .y1 - .y0 <= 0
        .go = 0
    endif
    if emlScreenSetup.pitchX <= 0
        .go = 0
    endif
    if emlScreenSetup.pitchY <= 0
        .go = 0
    endif

    if .go = 1
        .pX = emlScreenSetup.pitchX
        .pY = emlScreenSetup.pitchY
        .bX = emlScreenSetup.barX
        .bY = emlScreenSetup.barY

        .nY = floor ((.y1 - .y0) / .pY)
        for .i from 0 to .nY
            .a = .y0 + .i * .pY
            .b = .a + .bY
            if .b > .y1
                .b = .y1
            endif
            if .b > .a
                Paint rectangle: .ink$, .x0, .x1, .a, .b
            endif
        endfor
        .a = .y1 - .bY
        if .a > .y0
            Paint rectangle: .ink$, .x0, .x1, .a, .y1
        endif

        .nX = floor ((.x1 - .x0) / .pX)
        for .i from 0 to .nX
            .a = .x0 + .i * .pX
            .b = .a + .bX
            if .b > .x1
                .b = .x1
            endif
            if .b > .a
                Paint rectangle: .ink$, .a, .b, .y0, .y1
            endif
        endfor
        .a = .x1 - .bX
        if .a > .x0
            Paint rectangle: .ink$, .a, .x1, .y0, .y1
        endif

        .done = 1
    endif
endproc

# ----------------------------------------------------------------------------
# @emlPaintAlphaBox
# THE background for an on-figure box, by whichever of the three means this
# platform actually has. One call site's worth of decision, in one place, so
# that the legend panel and the annotation block cannot drift apart on it.
#
# Arguments: .x0, .x1, .y0, .y1 (world: left, right, bottom, top)
#
# Outputs:
#   .mode$          "sprite" | "screen" | "opaque"
#   .viewportDirty  1 when the caller MUST re-select its own viewport and axes
#                   before drawing anything else. `Insert picture from file:`
#                   leaves the VIEWPORT set to the image's own bounding box,
#                   so everything drawn after it lands in the wrong world.
#                   Restoring it afterwards restores nothing; it only stops
#                   the damage spreading. The sprite path is the only one that
#                   sets this.
#
# Also sets the global emlAlphaBgMode$ to the same string, so that a caller,
# a harness or a validator can find out WHICH background a figure got without
# decoding the PNG — and, once per session and only on the screen path, puts
# a NOTE in the Info window saying so. The sprite path says nothing, because
# on macOS and Windows nothing has changed and a note about it would be noise
# on the platform where the figure is already right.
#
# THE SPRITE PATH IS UNCHANGED, DELIBERATELY AND EXACTLY: the same
# `Insert picture from file:` with the same four arguments, and nothing else
# on the way past. The one behaviour that did change is the case where the
# sprite directory was found but the FILE is unreadable — that used to be an
# opaque white box and is now the screen, which is the same reasoning as the
# platform case and cannot arise on an intact install.
# ----------------------------------------------------------------------------
procedure emlPaintAlphaBox: .x0, .x1, .y0, .y1
    .mode$ = "opaque"
    .viewportDirty = 0
    .spriteUsed = 0

    if variableExists ("emlAlphaSpritesInitialized")
        if emlAlphaSpritesInitialized = 1 and emlInitAlphaSprites.available = 1
            .bgFile$ = emlInitAlphaSprites.dir$ + "bg_white_a70_40.png"
            if fileReadable (.bgFile$)
                Insert picture from file: .bgFile$, .x0, .x1, .y0, .y1
                .mode$ = "sprite"
                .viewportDirty = 1
                .spriteUsed = 1
            endif
        endif
    endif

    if .spriteUsed = 0
        # 0.702 is the sprite's own measured alpha, 179/255. The screen is
        # standing in for that file and for nothing else, so the number comes
        # from the file rather than from its name.
        @emlPaintScreenRect: .x0, .x1, .y0, .y1, "White", 0.702
        if emlPaintScreenRect.done = 1
            .mode$ = "screen"
        else
            Paint rectangle: "White", .x0, .x1, .y0, .y1
            .mode$ = "opaque"
        endif
    endif

    emlAlphaBgMode$ = .mode$

    if .mode$ = "screen"
        if variableExists ("emlAlphaBgDisclosed") = 0
            emlAlphaBgDisclosed = 0
        endif
        if emlAlphaBgDisclosed = 0
            emlAlphaBgDisclosed = 1
            appendInfoLine: "NOTE: on-figure box backgrounds are drawn as a",
            ... " stipple screen on this platform — Praat draws no image here,",
            ... " so the 70% white sprite macOS and Windows use is replaced by",
            ... " a white lattice of about the same coverage. Data under the",
            ... " box shows through the gaps instead of being erased."
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
# @emlTickPrecision: .axisMin, .axisMax, .step
# Decide whether Praat may format this axis's tick numbers itself, and if not,
# how many decimals the plugin has to write instead.
#
# Outputs
#   .explicit  1 = the caller must pass its own text to `One mark`
#              0 = Praat's own formatting is correct, pass "" as before
#   .decimals  digits after the point for fixed$() when .explicit = 1
#
# WHY THIS EXISTS. `One mark left: 200.05, "yes", ...` does not print 200.05.
# It prints "200.1". `One mark left: 200.01` prints "200". Praat's automatic
# mark number carries FOUR SIGNIFICANT DIGITS and rounds -- sometimes
# mis-rounds -- everything past them away. Measured on 6.6.30, 15 Aug 2026,
# harness/graphaxes/out/markprobe.png: six marks at 200.1, 200.05, 200.01,
# 200.005, 199.95 and 199.4 came out as "200.1", "200.1", "200", "200",
# "199.9", "199.4". Two pairs of distinct heights carry one label between
# them, and 199.95 is labelled 199.9, which is not a rounding a reader can
# undo.
#
# It is invisible at ordinary scales because four significant digits is
# plenty for an axis running 0 to 100, or 75 to 500. It bites when the axis
# is NARROW AND FAR FROM ZERO -- which is exactly a sustained note: a singer
# holding 200 Hz produces a pitch track spanning a hundredth of a hertz, and
# every tick on it reads "200". The figure then shows a wildly fluctuating
# contour against six identical numbers, and there is nothing on the page to
# tell a reader that the whole vertical extent is one part in ten thousand.
# That was NEW-G7-1 (severity 3), and this is one of its two halves; the
# other is the minimum span in @emlDrawF0Contour.
#
# THE RULE. Digits needed = digits left of the point at the far end of the
# axis, plus the decimals the STEP needs to distinguish one tick from the
# next. When that total is within Praat's four, nothing changes and the
# figures this plugin has always drawn are drawn identically -- this
# procedure returns .explicit = 0 and the caller passes "" exactly as it did
# before. Only when the total exceeds four does the plugin take over the
# formatting, and then it writes the decimals the step actually needs.
#
# .decimals IS CAPPED AT 6. Past that the label is longer than the tick
# spacing can carry and the axis is unreadable for a different reason; a
# figure needing more than six decimals of tick label is a figure whose axis
# range is wrong, and @emlDrawF0Contour's minimum span is what prevents it.
# ----------------------------------------------------------------------------
procedure emlTickPrecision: .axisMin, .axisMax, .step
    .explicit = 0
    .decimals = 0
    .bad = 0
    if .step = undefined
        .bad = 1
    endif
    if .axisMin = undefined or .axisMax = undefined
        .bad = 1
    endif
    if .bad = 0
        if .step <= 0
            .bad = 1
        endif
    endif
    if .bad = 1
        goto TICK_PRECISION_END
    endif

    # Decimals the step needs. A step of 0.2 needs one, 0.05 needs two, 5
    # needs none. floor(log10(step)) is the step's own magnitude; a negative
    # magnitude is the count of decimals, a non-negative one needs none.
    .stepMag = floor (log10 (.step))
    if .stepMag < 0
        .decimals = -.stepMag
    else
        .decimals = 0
    endif

    # Digits left of the point, taken at whichever end of the axis is
    # further from zero -- that is the tick with the most of them, and the
    # one whose label runs out of significant digits first.
    .far = max (abs (.axisMin), abs (.axisMax))
    if .far >= 1
        .intDigits = floor (log10 (.far)) + 1
    else
        .intDigits = 1
    endif

    ; THREE CONDITIONS, AND EACH ONE WAS PAID FOR. The bare
    ; "more than four significant digits" test was the first version and it
    ; made two figures WORSE than it found them, both caught by re-rendering
    ; harness/stress_graphs.sh against this change:
    ;
    ;   .far >= 1 -- BELOW ONE, PRAAT SWITCHES TO SCIENTIFIC NOTATION AND IS
    ;   RIGHT TO. An axis running 8e-10 to 2.2e-9 (violin_tinyvalues) labels
    ;   as "8·10^-10" and "2.2·10^-9": four significant digits is ample there,
    ;   because the exponent carries the magnitude and the mantissa is short.
    ;   Writing those out with fixed$ gives "0.000000001", which is not a
    ;   correction, it is a worse label.
    ;
    ;   .decimals > 0 -- A STEP OF A WHOLE UNIT OR MORE CANNOT COLLIDE. On
    ;   violin_hugevalues the axis runs to 1e9 and the step is 2e8; adjacent
    ;   ticks differ in the FIRST significant digit, so Praat's "1·10^9" is
    ;   both distinct and readable and the fixed$ form is ten digits of noise.
    ;
    ;   .decimals <= 6 -- past six the label is longer than the tick spacing
    ;   can carry and the axis is unreadable for a different reason. That axis
    ;   should not have been drawn; @emlDrawF0Contour's minimum span is what
    ;   stops it, and taking Praat's answer here is the lesser evil.
    ;
    ; What is left is exactly the shape that breaks: MANY INTEGER DIGITS AND A
    ; FRACTIONAL STEP. A sustained note at 200 Hz on a hundredth-of-a-hertz
    ; axis, and nothing else.
    if .far >= 1
        if .decimals > 0
            if .decimals <= 6
                if .intDigits + .decimals > 4
                    .explicit = 1
                endif
            endif
        endif
    endif
    label TICK_PRECISION_END
endproc

# ----------------------------------------------------------------------------
# @emlTickLabelWidth: .value, .explicit, .decimals
# What one tick label will READ AS, and how wide it will be on the page.
#
# Outputs
#   .text$   the label as it will be rendered, "" when Praat's own form is
#            not modelled (see the window below)
#   .chars   length (.text$), 0 when not modelled
#   .mm      its width in millimetres at the CURRENT font and size, 0 when
#            not modelled
#
# WHY A PREDICTOR AND NOT A MEASUREMENT. When @emlTickPrecision has engaged,
# the plugin passes its own string to `One mark left` and there is nothing to
# predict -- .text$ is that string. When it has NOT engaged, Praat writes the
# number itself and no script can ask it what it wrote. So the automatic form
# is reconstructed here: FOUR SIGNIFICANT DIGITS, trailing zeros stripped,
# which is the rule @emlTickPrecision's header documents and which was
# re-measured on 6.6.30 on 15 Aug 2026 -- 200.05 prints "200.1", 200.01 prints
# "200", 100.10 prints "100.1", -32.98 prints "-32.98".
#
# THE WINDOW, AND WHY IT IS NARROW ON PURPOSE. Praat switches to exponent
# notation outside roughly 0.001 <= |v| < 10000, and it was measured doing so:
# at 300 dpi and 10 pt, 9999 renders 7.54 mm wide and 10000 renders 4.91 mm --
# "10^4", not "10000". Modelling that switch is guesswork, and a wrong guess
# would not be a harmless over-estimate: an axis running to 1e9 would be
# predicted as ten digits, would trigger the axis-name shift below, and would
# MOVE A FIGURE THAT IS DRAWN CORRECTLY TODAY (violin_hugevalues in
# harness/stress_cases is exactly that figure). Outside the window this
# procedure therefore returns nothing at all and the caller does nothing --
# the conservative direction, because the failure it exists to prevent is a
# collision and the failure it must not cause is a figure that moves.
#
# Requires: the ambient font and size are the ones the marks are drawn at.
# `Text width (mm)` reads the current font state, which is the same state
# BEST_PRACTICES_DRAWING's font invariant already requires be held constant
# across the whole drawing sequence.
# ----------------------------------------------------------------------------
procedure emlTickLabelWidth: .value, .explicit, .decimals
    .text$ = ""
    .chars = 0
    .mm = 0
    if .value = undefined
        goto TICK_LABEL_WIDTH_END
    endif
    if .explicit = 1
        .text$ = fixed$ (.value, .decimals)
    else
        .mag = abs (.value)
        if .mag = 0
            .text$ = "0"
        elsif .mag >= 0.001 and .mag < 10000
            # Digits left of the point, as a signed count: 0.05 gives -1, so
            # 4 - (-1) = 5 decimals, which is four significant digits after
            # the leading zeros. fixed$ then writes them and the strip below
            # removes what Praat does not print.
            .intDigits = floor (log10 (.mag)) + 1
            .d = 4 - .intDigits
            if .d < 0
                .d = 0
            endif
            .text$ = fixed$ (.value, .d)
            if index (.text$, ".") > 0
                while right$ (.text$, 1) = "0"
                    .text$ = left$ (.text$, length (.text$) - 1)
                endwhile
                if right$ (.text$, 1) = "."
                    .text$ = left$ (.text$, length (.text$) - 1)
                endif
            endif
        endif
    endif
    if .text$ <> ""
        .chars = length (.text$)
        .mm = Text width (mm): .text$
    endif
    label TICK_LABEL_WIDTH_END
endproc

# ----------------------------------------------------------------------------
# @emlDrawAxisNameLeft: .label$, .wideLabelMM, .xMin, .xMax, .yMin, .yMax
# Draw the y-axis NAME in the left margin without letting the tick numbers
# run into it.
#
# AUTHOR RULING 7, 15 August 2026: "no collision between the y-axis name and
# its tick labels. The author delegates the mechanism; the requirement is no
# collision."
#
# WHAT IS WRONG. Praat's left-margin allocation is FIXED. `Text left` puts the
# rotated axis name at a distance from the inner frame that depends on the
# font SIZE and on nothing else -- measured at 300 dpi on 6.6.30, 15 Aug 2026:
# the name's right edge sits 13.4 px per point of font size from the frame
# (94 px at 7 pt, 134 at 10, 147 at 11), and it sits there whether the ticks
# read "5" or "-32.98". Measured again in Helvetica, Times and Courier at two
# sizes: 134 px at 10 pt in all three, so the allocation is a function of size
# alone and not of the font's own metrics. Tick numbers are right-aligned to
# the frame, their right edge 1.8 px per point inside it, and they grow
# LEFTWARD into that fixed band as they get longer. About five characters fit.
# Six is the failure edge, and both of the author's cases were reproduced here
# before anything was changed:
#
#   a semitone axis with negatives, F0 (semitones re 440 Hz) against "-33.08"
#     -- 3 px of gap at 300 dpi, a quarter of a millimetre
#   an explicit two-decimal dB axis, Power (dB) against "100.10"
#     -- 4 px, and it reads as "Powe100.10"
#
# There is no truncation and no overprint. The mode is gap exhaustion.
#
# WHY NOT THE OBVIOUS FIX. Widening the plugin's own left margin does NOT
# work, and this was measured rather than reasoned: the same figure drawn at
# marginLeft 0.84" and 1.10" puts the name, the ticks and the frame in exactly
# the same relative positions, 3 px of gap in both, because everything in the
# margin is anchored to the inner frame and the frame moves with the margin.
# A wider margin buys white space on the far left and not one pixel of gap.
#
# THE MECHANISM. The name is drawn by Praat, from Praat's own anchor, into a
# frame that is momentarily declared to start further left. `Select inner
# viewport` with the left edge moved out by .shiftInch, `Axes` re-issued
# unchanged, `Text left`, then both restored -- so the name lands exactly
# where Praat would have put it for a figure whose plot began there, at the
# same vertical centre, the same rotation, the same size, and nothing else in
# the figure has been told anything. The alternative -- placing the name with
# `Text special` at a computed inch coordinate, as @emlDrawTitle does -- was
# rejected because it would replace Praat's vertical centring and baseline
# rule with a reimplementation of them, and every figure in the plugin would
# then depend on that reimplementation being right.
#
# THE SHIFT IS ZERO ON AN ORDINARY FIGURE, AND THAT IS THE POINT. A fix that
# widened the margin unconditionally would also satisfy "no collision" while
# moving every figure the plugin draws. .wideLabelMM is 0 unless some tick
# label is SIX CHARACTERS OR MORE -- the author's own threshold -- so a
# figure whose ticks read "45" or "200.2" takes the else branch below, which
# is the bare `Text left` this procedure replaced, byte for byte. Verified by
# re-rendering all 39 figures of harness/stress_graphs.sh.
#
# THE ARITHMETIC. .allowMM is the room between the tick numbers' right edge
# and the name's right edge, from the two measured constants above:
# (13.4 - 1.8) px/pt = 11.6 px/pt = 0.982 mm per point of font size. The
# clearance restored is one character width of the current font, which is the
# unit the ruling itself uses.
#
# THE SHIFT IS CLAMPED TO THE ROOM THE PANEL HAS, and the clamp is the reason
# this procedure changes no figure's SIZE. Praat saves the outer viewport that
# @emlAssertFullViewport selects, and it saves nothing outside it: measured on
# 15 Aug 2026 by drawing an axis name at 0.4" and saving from 0.5", which cut
# the name and dropped a fifth of the figure's ink. So a name pushed past the
# panel's own left edge would be sliced down its length on export unless the
# saved box grew -- and growing it is how a 6 x 4 request becomes a file that
# is not 6 x 4, which validate/v32 keeps a pinned inventory of on purpose.
# Layout is this procedure's business; the size of the user's file is not.
#
# WHAT THE CLAMP COSTS, SAID PLAINLY. On every figure this plugin's own form
# draws -- 6 x 4 at 9.36 pt -- the room is 0.29" and the shift needed is a
# tenth of that, so the clamp never engages and the collision is fully
# relieved. It engages only on a panel small enough that the axis name has
# less than its own thickness of room inside the panel: a 3 x 2 panel at 7 pt
# has 0.01" to give. There the collision is relieved by 0.01" and no further,
# and the figure keeps its size. Relieving it there as well means growing the
# saved box, which is an argued entry in v32's inventory and the author's
# call, not this procedure's.
#
# Arguments
#   .label$        the axis name, already sanitized by the caller
#   .wideLabelMM   width of the widest tick label of six characters or more,
#                  0 if there is none (from @emlDrawAlignedMarksLeft)
#   .xMin..yMax    the world window to restore, because `Select inner
#                  viewport` resets it
# Outputs
#   .shiftInch     how far the name was moved, 0 when nothing was needed
#   .roomInch      how far it COULD have moved inside the panel
#   .clamped       1 if the panel had less room than the labels needed
# ----------------------------------------------------------------------------
procedure emlDrawAxisNameLeft: .label$, .wideLabelMM, .xMin, .xMax, .yMin, .yMax
    .shiftInch = 0
    .clamped = 0
    # The room inside the panel: where the name's left edge already sits,
    # measured from the panel's own left edge. 0.0447" per point is the third
    # measured constant (13.4 px/pt at 300 dpi) and .bodyInch is one em, which
    # is at least the rotated text's thickness.
    .roomInch = emlSetAdaptiveTheme.innerLeft - emlSetAdaptiveTheme.outerLeft
    ... - 0.0447 * emlSetAdaptiveTheme.bodySize
    ... - emlSetAdaptiveTheme.bodyInch
    if .roomInch < 0
        .roomInch = 0
    endif
    if .wideLabelMM > 0
        .allowMM = 0.982 * emlSetAdaptiveTheme.bodySize
        .clearMM = Text width (mm): "0"
        .needMM = .wideLabelMM + .clearMM
        if .needMM > .allowMM
            .shiftInch = (.needMM - .allowMM) / 25.4
            if .shiftInch > .roomInch
                .shiftInch = .roomInch
                .clamped = 1
            endif
        endif
    endif
    if .shiftInch > 0
        Select inner viewport: emlSetAdaptiveTheme.innerLeft - .shiftInch,
        ... emlSetAdaptiveTheme.innerRight,
        ... emlSetAdaptiveTheme.innerTop,
        ... emlSetAdaptiveTheme.innerBottom
        Axes: .xMin, .xMax, .yMin, .yMax
        Text left: "yes", .label$
        Select inner viewport: emlSetAdaptiveTheme.innerLeft,
        ... emlSetAdaptiveTheme.innerRight,
        ... emlSetAdaptiveTheme.innerTop,
        ... emlSetAdaptiveTheme.innerBottom
        Axes: .xMin, .xMax, .yMin, .yMax
    else
        Text left: "yes", .label$
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
    ; THE WIDEST TICK LABEL THIS AXIS WILL CARRY, for @emlDrawAxisNameLeft.
    ; Six characters is the author's threshold and the measured failure edge;
    ; anything shorter leaves this at 0 and the axis name is drawn by the
    ; unchanged `Text left` call. Seeded BEFORE the early exit below, so a
    ; caller that reads it after a suppressed axis reads 0 rather than
    ; whatever the previous panel left behind.
    .wideChars = 6
    .maxWideLabelMM = 0
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

    ; Four significant digits is all Praat's own mark number carries, so a
    ; narrow axis far from zero labels every tick the same. See
    ; @emlTickPrecision. .explicit = 0 on every ordinary axis and the ""
    ; below is the call this procedure has always made.
    @emlTickPrecision: .yMin, .yMax, .yStep
    .tickExplicit = emlTickPrecision.explicit
    .tickDecimals = emlTickPrecision.decimals

    # Major ticks with numbers
    .yPos = ceiling (.yMin / .yStep) * .yStep
    while .yPos <= .yMax + .yTol
        if .yPos >= .yMin - .yTol
            if abs (.yPos) < .yTol
                .yPos = 0
            endif
            if .tickExplicit = 1 and emlShowAxisValuesY
                One mark left: .yPos, "no", .drawTick$, "no",
                ... fixed$ (.yPos, .tickDecimals)
            else
                One mark left: .yPos, .writeNum$, .drawTick$, "no", ""
            endif
            ; MEASURE WHAT WAS JUST DRAWN. Only when a number was actually
            ; written -- an axis with ticks and no values cannot collide with
            ; anything. @emlTickLabelWidth returns 0 for a label whose form
            ; Praat writes in exponent notation, and 0 keeps the name where
            ; it has always been.
            if emlShowAxisValuesY
                @emlTickLabelWidth: .yPos, .tickExplicit, .tickDecimals
                if emlTickLabelWidth.chars >= .wideChars
                    if emlTickLabelWidth.mm > .maxWideLabelMM
                        .maxWideLabelMM = emlTickLabelWidth.mm
                    endif
                endif
            endif
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

    ; Same four-significant-digit ceiling as the left margin. See
    ; @emlTickPrecision.
    @emlTickPrecision: .yMin, .yMax, .yStep
    .tickExplicit = emlTickPrecision.explicit
    .tickDecimals = emlTickPrecision.decimals

    # Major ticks with numbers
    .yPos = ceiling (.yMin / .yStep) * .yStep
    while .yPos <= .yMax + .yTol
        if .yPos >= .yMin - .yTol
            if abs (.yPos) < .yTol
                .yPos = 0
            endif
            if .tickExplicit = 1 and emlShowAxisValuesY
                One mark right: .yPos, "no", .drawTick$, "no",
                ... fixed$ (.yPos, .tickDecimals)
            else
                One mark right: .yPos, .writeNum$, .drawTick$, "no", ""
            endif
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

    ; Same four-significant-digit ceiling as the y margins. See
    ; @emlTickPrecision. A time axis running 12.000 to 12.002 seconds is the
    ; x-axis version of the sustained-note figure.
    @emlTickPrecision: .xMin, .xMax, .xStep
    .tickExplicit = emlTickPrecision.explicit
    .tickDecimals = emlTickPrecision.decimals

    # Major ticks with numbers
    .xPos = ceiling (.xMin / .xStep) * .xStep
    while .xPos <= .xMax + .xTol
        if .xPos >= .xMin - .xTol
            if abs (.xPos) < .xTol
                .xPos = 0
            endif
            if .tickExplicit = 1 and emlShowAxisValuesX
                One mark bottom: .xPos, "no", .drawTick$, "no",
                ... fixed$ (.xPos, .tickDecimals)
            else
                One mark bottom: .xPos, .writeNum$, .drawTick$, "no", ""
            endif
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
    .yWideLabelMM = emlDrawAlignedMarksLeft.maxWideLabelMM

    # --- X-axis (bottom) ticks ---
    @emlDrawAlignedMarksBottom: .xMin, .xMax,
    ... emlSetAdaptiveTheme.targetTicksX, emlSetAdaptiveTheme.useMinorTicks

    # Axis labels (gated by per-axis name visibility)
    Colour: emlSetAdaptiveTheme.textColor$
    if emlShowAxisNameX and .xLabel$ <> ""
        Text bottom: "yes", .xLabel$
    endif
    if emlShowAxisNameY and .yLabel$ <> ""
        # Ruling 7: the name goes where Praat puts it unless the tick labels
        # have already taken the room. @emlDrawAxisNameLeft says how.
        @emlDrawAxisNameLeft: .yLabel$, .yWideLabelMM,
        ... .xMin, .xMax, .yMin, .yMax
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
    # .yWideLabelMM is seeded to 0 for the panel whose ticks are suppressed:
    # no numbers were drawn there, so nothing can crowd its axis name, and
    # reading the neighbouring panel's measurement would move it for no
    # reason.
    .yWideLabelMM = 0
    if .showYTicks
        @emlDrawAlignedMarksLeft: .yMin, .yMax,
        ... emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks
        .yWideLabelMM = emlDrawAlignedMarksLeft.maxWideLabelMM
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
        @emlDrawAxisNameLeft: .yLabel$, .yWideLabelMM,
        ... .xMin, .xMax, .yMin, .yMax
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
# Arguments: xCenter, data#, fillColor$, lineColor$, axisYMin, axisYMax,
#            width, pattern
# axisYMin/axisYMax: axis bounds for clipping (prevents drawing outside frame)
# width: half-width of the violin in x-units (typically 0.35)
# pattern (v1.23): fill pattern, 1 solid | 2 diagonal hatch | 3 dots. Anything
#            else is drawn solid. Pass emlSetColorPalette.pattern[idx].
# Output (v3.22): .nSkipped = observations dropped because they were undefined
#
# v1.23: the pattern is drawn OVER the painted body, between the fill and the
# outline, and is clipped using the body's own scanline structure -- the fill
# loop already knows the half-width .d at every slice, so it stores it and the
# pattern pass reuses it. No density is computed twice for the hatch, and no
# polygon clip exists. The pattern is under the outline and under the quartile
# box on purpose: both must stay readable.
#
# v3.22: undefined observations are now skipped during the fallback draw and
# detected before the KDE runs. Previously "if .sd = 0" was the only validity
# gate; an undefined element in .data# makes .mean and .sd undefined, that
# comparison is FALSE, and the undefined bandwidth propagates into
# Paint rectangle:, which aborts the entire figure with a hard error.
# ----------------------------------------------------------------------------
procedure emlDrawViolin: .xCenter, .data#, .fillColor$, .lineColor$, .axisYMin, .axisYMax, .width, .pattern
    # v1.24: ONE ink for the whole mark. The hatch already flipped to white on
    # a dark fill and the outline, quartile box and median did not, so on the
    # widened grey ramp a slot-8 violin (fill 0.10) drew its internal box in
    # near-black on near-black and lost it. .lineColor$ is a procedure-local,
    # so rewriting it here reaches every use below -- including the
    # @emlPatternSetup call, where @emlMarkInk is idempotent.
    @emlMarkInk: .fillColor$, .lineColor$
    .lineColor$ = emlMarkInk.result$
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
    # Half-width per slice, kept so the pattern pass below can clip to the
    # body without recomputing 500 kernel sums.
    .dFill# = zero# (.nEvalFill - 1)
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
        .dFill#[.e] = .d

        # Clamp fill rectangle to axis bounds with sub-pixel overlap
        .drawY1 = max (.y1 - .overlapMargin, .axisYMin)
        .drawY2 = min (.y2 + .overlapMargin, .axisYMax)
        if .drawY1 < .drawY2
            Paint rectangle: .fillColor$, .xCenter - .d, .xCenter + .d, .drawY1, .drawY2
        endif
    endfor

    # === FILL PATTERN (over the body, under the outline) ===
    # .pattern is a parameter, so it is always defined here; 1 and anything
    # unrecognised fall through and the body stays solid.
    .doHatch = 0
    .doDots = 0
    if .pattern = 2
        .doHatch = 1
    endif
    if .pattern = 3
        .doDots = 1
    endif
    if .doHatch = 1 or .doDots = 1
        @emlPatternSetup: .fillColor$, .lineColor$, .width, .axisYMin, .axisYMax
        if emlPatternSetup.usable = 0
            .doHatch = 0
            .doDots = 0
        endif
    endif

    if .doHatch = 1
        # One scanline per fill slice: the stripes then step by well under a
        # device pixel, so the diagonal edge is as smooth as the body's own.
        for .e from 1 to .nEvalFill - 1
            .y1 = .evalMin + (.e - 1) * .evalStepFill
            .y2 = .evalMin + .e * .evalStepFill
            .drawY1 = max (.y1 - .overlapMargin, .axisYMin)
            .drawY2 = min (.y2 + .overlapMargin, .axisYMax)
            if .drawY1 < .drawY2
                @emlPaintHatchRow: .xCenter, .dFill#[.e], .drawY1, .drawY2,
                ... .axisYMin
            endif
        endfor
    endif

    if .doDots = 1
        # Dot rows are laid out on the inch grid, not the slice grid, and each
        # row's clip half-width is the SMALLEST body half-width over the row's
        # full vertical extent, so a dot is drawn only where all of it fits.
        .dotStepY = emlPatternSetup.dotPitch * emlPatternSetup.sy
        .dotRWorldY = emlPatternSetup.dotR * emlPatternSetup.sy
        .patLow = max (.evalMin, .axisYMin)
        .patHigh = min (.evalMax, .axisYMax)
        .nDotRows = 0
        if .dotStepY > 0
            .nDotRows = floor ((.patHigh - .patLow) / .dotStepY)
        endif
        for .r from 0 to .nDotRows
            .dy = .patLow + (.r + 0.5) * .dotStepY
            .dTop = .dy + .dotRWorldY
            .dBot = .dy - .dotRWorldY
            if .dTop <= .patHigh and .dBot >= .patLow
                .eLo = floor ((.dBot - .evalMin) / .evalStepFill) + 1
                .eHi = floor ((.dTop - .evalMin) / .evalStepFill) + 1
                if .eLo < 1
                    .eLo = 1
                endif
                if .eHi > .nEvalFill - 1
                    .eHi = .nEvalFill - 1
                endif
                .dMin = 0
                if .eLo <= .eHi
                    .dMin = .dFill#[.eLo]
                    for .e from .eLo to .eHi
                        if .dFill#[.e] < .dMin
                            .dMin = .dFill#[.e]
                        endif
                    endfor
                endif
                @emlPaintDotRow: .xCenter, .dMin, .dy, .r, .axisYMin
            endif
        endfor
    endif

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
#   .pattern    — fill pattern (v1.23): 1 solid | 2 diagonal hatch | 3 dots.
#                 Anything else draws solid. Pass
#                 emlSetColorPalette.pattern[idx].
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
procedure emlDrawBox: .xCenter, .data#, .fillColor$, .lineColor$, .axisYMin, .axisYMax, .width, .pattern
    # One ink for the whole mark -- see the same two lines in @emlDrawViolin.
    @emlMarkInk: .fillColor$, .lineColor$
    .lineColor$ = emlMarkInk.result$
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

    # === FILL PATTERN (over the body, under the outline and the median) ===
    # A box is a rectangle, so the "clip to the shape" the violin does with
    # its stored per-slice half-width is here a constant half-width. Same two
    # row painters, same geometry, same ink rule.
    .doHatch = 0
    .doDots = 0
    if .pattern = 2
        .doHatch = 1
    endif
    if .pattern = 3
        .doDots = 1
    endif
    if .drawQ1 >= .drawQ3
        .doHatch = 0
        .doDots = 0
    endif
    if .doHatch = 1 or .doDots = 1
        @emlPatternSetup: .fillColor$, .lineColor$, .width, .axisYMin, .axisYMax
        if emlPatternSetup.usable = 0
            .doHatch = 0
            .doDots = 0
        endif
    endif

    if .doHatch = 1
        # 0.004" scanlines: about one device pixel at 300 dpi, so the stripe
        # edges are as clean as the violin's.
        .rowH = 0.004 * emlPatternSetup.sy
        .nRows = 1
        if .rowH > 0
            .nRows = ceiling ((.drawQ3 - .drawQ1) / .rowH)
        endif
        if .nRows < 1
            .nRows = 1
        endif
        .rowStep = (.drawQ3 - .drawQ1) / .nRows
        for .r from 1 to .nRows
            .ry1 = .drawQ1 + (.r - 1) * .rowStep
            .ry2 = .drawQ1 + .r * .rowStep
            @emlPaintHatchRow: .xCenter, .width, .ry1, .ry2, .axisYMin
        endfor
    endif

    if .doDots = 1
        .dotStepY = emlPatternSetup.dotPitch * emlPatternSetup.sy
        .dotRWorldY = emlPatternSetup.dotR * emlPatternSetup.sy
        .nDotRows = 0
        if .dotStepY > 0
            .nDotRows = floor ((.drawQ3 - .drawQ1) / .dotStepY)
        endif
        for .r from 0 to .nDotRows
            .dy = .drawQ1 + (.r + 0.5) * .dotStepY
            if .dy - .dotRWorldY >= .drawQ1 and .dy + .dotRWorldY <= .drawQ3
                @emlPaintDotRow: .xCenter, .width, .dy, .r, .axisYMin
            endif
        endfor
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


# ============================================================================
# POINT MARKERS
# ============================================================================
# The second dimension for the four chart types that draw dots and lines --
# scatter, line chart, spaghetti, time series. Author's ruling, 7 Aug 2026:
# "we need to go ahead and add a square and a triangle. If these are gonna be
# sprites, go ahead and write a Python script to generate those."
#
# THEY ARE NOT SPRITES, and the "if" is why. Three findings, in order:
#
#   1. The .sprite$[] array that @emlSetColorPalette already carries is READ
#      in exactly two places, @emlDrawAlphaDot and @emlDrawAlphaRect, and both
#      are gated on emlInitAlphaSprites.available.
#
#      A NOTE ON THE RECORD, because it matters for anyone reading the audit:
#      audit/reviews/GRAPH_STRESS_2026-08-06.md finding 6 says "plugin/sprites/
#      has never existed in the repository". THAT IS WRONG. The folder is
#      there and has been since commit a31a669 -- 204 tracked PNGs, 168 dots,
#      34 rectangles, 2 backgrounds -- and dot_blue_a50_40.png, the file
#      @emlInitAlphaSprites probes for, is one of them. So the array is live
#      on macOS and on Windows.
#
#      It is nonetheless useless for THIS job, for two independent reasons.
#      First, every sprite in the set is a DOT or a RECTANGLE: the array
#      indexes HUE, one stem per colour, and there is no shape axis in it at
#      all. Adding one means 168 more files for squares and 168 for triangles,
#      at every alpha level and every size, to express what two lines of
#      arithmetic express. Second, @emlInitAlphaSprites returns early on
#      anything that is not macOS or Windows, because Praat's
#      Graphics_imageFromFile has a GDI+ branch and a Quartz branch and NO
#      cairo branch -- on Linux it computes its coordinates and draws nothing,
#      with no error and no return code. A raster marker would therefore
#      render as a BLANK on the platform this harness measures, which is
#      exactly the failure the gate was added to stop.
#
#   2. Praat has no filled-polygon primitive to lean on either (the Polygon
#      OBJECT has "Draw (closed)", an outline, and creating and removing an
#      object per dot inside a draw loop that is already juggling Table
#      selections is not something to do). A triangle is therefore painted as
#      a stack of horizontal `Paint rectangle` slices -- the same construction
#      @emlDrawViolin uses for its body, and the same one @emlPaintHatchRow
#      uses for a stripe. Nothing new is being invented here.
#
#   3. Native drawing scales with the figure and a 40-pixel PNG does not. The
#      plugin renders anything from a 3-inch panel to a 20-inch one at 300 dpi;
#      a stamped raster is soft at the top of that range and no smaller file
#      helps at the bottom.
#
# So: native primitives, no generated assets, no Python. If Praat ever gains
# a cairo image branch that changes the calculus for ALPHA, not for shape.
#
# GEOMETRY, at the plugin's real dot sizes. `.halfIn` is the marker's radius
# in INCHES -- the circle's radius, and the reference the other two shapes are
# sized against. On a 6 x 4 inch figure @emlSetAdaptiveTheme.markerSize is
# 1.0 and @emlDrawScatterPlot's three dot sizes give .halfIn = 0.035, 0.065
# and 0.108 inches, i.e. 21, 39 and 65 pixels ACROSS at 300 dpi. Spaghetti
# and time-series markers are set in millimetres and land at 1.5 mm and
# 1.4 mm radius, about 35 and 33 pixels across. A triangle is legible from
# roughly 8 pixels across, so every one of those has room to spare; the
# measured floor is in validate/v29_figure_disclosure.R.
#
#   1 circle    radius .halfIn.                        area  3.142 halfIn^2
#   2 square    half-side 0.8862 * .halfIn.            area  3.142 halfIn^2
#   3 triangle  equilateral, circumradius 1.45*.halfIn,
#               apex up, base flat.                    area  2.731 halfIn^2
#
# The square is sized for EQUAL AREA with the circle so the two carry the
# same visual weight. An equal-area triangle would need circumradius
# 1.5551 * .halfIn and a bounding box 2.69 x 2.33 times the circle's radius,
# which crowds a dense scatter; 1.45 gives it 87% of the circle's ink in a
# 2.51 x 2.18 box, which reads as the same weight without spreading further.
# ----------------------------------------------------------------------------
# @emlDrawMarker
# One point marker, filled, no outline, at world coordinates (.x, .y).
#
# Arguments:
#   .x, .y     world coordinates of the marker CENTRE
#   .halfIn    marker radius in inches (see the geometry note above)
#   .shape     1 circle | 2 square | 3 triangle; anything else wraps mod 3
#   .color$    fill colour
#
# Requires @emlSetPatternScale to have been called for the CURRENT axes --
# the square and the triangle need world-per-inch on both axes to come out
# square rather than stretched by the axis aspect ratio, exactly as the alpha
# sprite path needed @emlSetAlphaDotGeometry. When the scale is unavailable
# or degenerate the marker falls back to `Paint circle (mm)`, which needs no
# scale at all: a circle where a triangle was asked for is a lost cue, a
# skipped point is a lost observation, and the observation wins.
# ----------------------------------------------------------------------------
procedure emlDrawMarker: .x, .y, .halfIn, .shape, .color$
    .sx = 0
    .sy = 0
    if variableExists ("emlPatWorldPerInchX")
        .sx = emlPatWorldPerInchX
    endif
    if variableExists ("emlPatWorldPerInchY")
        .sy = emlPatWorldPerInchY
    endif
    if .sx = undefined
        .sx = 0
    endif
    if .sy = undefined
        .sy = 0
    endif

    # Nested, never "or": Praat evaluates both operands of or/and, and an
    # undefined coordinate compared with <= is FALSE rather than an error, so
    # every test is written to catch undefined explicitly.
    .placeable = 1
    if .x = undefined
        .placeable = 0
    endif
    if .y = undefined
        .placeable = 0
    endif
    if .halfIn = undefined
        .placeable = 0
    endif
    if .placeable = 1
        if .halfIn <= 0
            .placeable = 0
        endif
    endif
    if .placeable = 0
        goto MARKER_END
    endif

    ; NEW-G8-1: a point outside the frame is not drawn in the margin. See
    ; @emlPointInFrame -- no frame published means no clipping, so this is a
    ; no-op for any caller that has not installed one.
    @emlPointInFrame: .x, .y
    if emlPointInFrame.inside = 0
        if variableExists ("emlClippedN") = 0
            emlClippedN = 0
        endif
        emlClippedN = emlClippedN + 1
        goto MARKER_END
    endif

    .scaled = 1
    if .sx <= 0
        .scaled = 0
    endif
    if .sy <= 0
        .scaled = 0
    endif
    if .scaled = 0
        Paint circle (mm): .color$, .x, .y, .halfIn * 25.4
        goto MARKER_END
    endif

    # An undefined or out-of-range shape draws a circle rather than nothing:
    # `undefined mod 3` is undefined, and every branch below would then be
    # FALSE and the point would vanish without a word.
    .sh = 1
    if .shape <> undefined
        .sh = ((.shape - 1) mod 3) + 1
    endif

    if .sh = 1
        # Praat's Paint circle takes its radius in world x-units and draws a
        # physically round circle, so this needs no aspect correction.
        Paint circle: .color$, .x, .y, .halfIn * .sx
    elsif .sh = 2
        .half = .halfIn * 0.8862
        Paint rectangle: .color$,
        ... .x - .half * .sx, .x + .half * .sx,
        ... .y - .half * .sy, .y + .half * .sy
    else
        # Equilateral triangle, apex up, painted as horizontal slices.
        # Circumradius .rad: apex at +rad, base at -rad/2, half-base
        # 0.8660 * rad, total height 1.5 * rad.
        .rad = .halfIn * 1.45
        .heightIn = 1.5 * .rad
        .baseHalf = 0.8660 * .rad
        # One slice per ~0.9 device pixels at 300 dpi, floor 8 (so the shape
        # survives at a tiny marker) and ceiling 48 (so a scatter of a
        # thousand triangles is 48k rectangles, not an unbounded number).
        # At 1.6 px per slice the diagonal edge was visibly stepped under
        # magnification; at 0.9 it is not, and the cost is one Paint
        # rectangle per device pixel row, which is what the violin body has
        # always cost.
        .nSlices = round (.heightIn * 300 / 0.9)
        if .nSlices < 8
            .nSlices = 8
        endif
        if .nSlices > 48
            .nSlices = 48
        endif
        .sliceIn = .heightIn / .nSlices
        # .rad is in INCHES and .y is in WORLD units, so the drop from the
        # centre to the base has to be scaled before it is subtracted. It was
        # not, in the first draft, and the triangle came out ten pixels high
        # -- caught by the crop in harness/markers/marker_case.praat, which is
        # computed from the declared geometry and clipped the apex.
        .baseY = .y - (.rad / 2) * .sy
        for .s from 0 to .nSlices - 1
            .y0 = .s * .sliceIn
            .y1 = .y0 + .sliceIn
            # Slices overlap by a third of their height. Praat antialiases
            # every rectangle edge, and abutting edges leave a visible seam
            # in the fill; an overlap costs nothing and removes it.
            .y1 = .y1 + .sliceIn / 3
            if .y1 > .heightIn
                .y1 = .heightIn
            endif
            # Half-width at the slice's LOWER edge, which over-fills by less
            # than one slice and keeps the apex from tapering to nothing.
            .w = .baseHalf * (1 - .y0 / .heightIn)
            if .w > 0
                Paint rectangle: .color$,
                ... .x - .w * .sx, .x + .w * .sx,
                ... .baseY + .y0 * .sy, .baseY + .y1 * .sy
            endif
        endfor
    endif

    label MARKER_END
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
# IT IS IDEMPOTENT, AND IT WAS NOT. Escaping an already-escaped string used to
# destroy the character it was protecting:
#
#     Jitter (\% )      escaped once   ->  renders  Jitter (%)      correct
#     Jitter (\\%  )    escaped twice  ->  renders  Jitter (  )     gone
#     Jitter (%)        never escaped  ->  renders  Jitter ()       eaten
#
# Measured 11 Aug 2026 by rendering all three. The middle line is what the
# auto-composed TITLE of every figure looked like, while the y-axis label on
# the same figure was correct -- because @emlComposeGraphTitle sanitizes each
# part it assembles (the value column via @emlCapitalizeLabel, which already
# returns "Jitter (\% )") and @emlDrawAxes then sanitizes the finished title
# AGAIN. @emlDrawAxes says why it does that: axis labels are sanitized at
# generation, titles are "passed raw". That was true when it was written.
# @emlComposeGraphTitle made it false and the draw site was never told.
#
# THE FIX IS HERE RATHER THAN AT THE DRAW SITE. Removing the second call would
# leave a user-TYPED title unescaped, which is the case that call exists to
# protect -- and a user's title is the one string in the figure this procedure
# cannot assume anything about. So the escaper is made safe to apply twice,
# and both call sites stay.
#
# HOW: NORMALISE, then escape. Every escape already present is undone first,
# so the string reaching the escaping pass is in exactly one state whatever
# state it arrived in. A sentinel-and-restore scheme was tried first and
# rejected: every sentinel that can be written in a Praat string literal is a
# string a label could also contain, so it trades one collision for another.
# Un-escaping has no such hole -- it is the exact inverse of the pass that
# follows it.
#
# The one input this treats differently from before is a label containing the
# literal characters backslash-percent-space and meaning them literally. It
# now round-trips to backslash-percent-space, which is what it rendered as
# anyway.
procedure emlSanitizeLabel: .raw$
    # First convert underscores to spaces (display-friendly)
    .result$ = replace$ (.raw$, "_", " ", 0)

    # Normalise: undo any escaping already applied, so what follows sees one
    # state. Without this, escaping ran a second time over its own output.
    .result$ = replace$ (.result$, "\% ", "%", 0)
    .result$ = replace$ (.result$, "\# ", "#", 0)
    .result$ = replace$ (.result$, "\^ ", "^", 0)

    # Then escape the special characters
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
#          .choice$ (human-readable name of what was applied, "" if mono)
# Note: Removes the original stereo Sound if conversion occurs, UNLESS the
#       caller sets emlChannelKeepOriginal = 1 first.
#
# THE KEEP SWITCH, AND WHY IT IS OPT-IN (15 Aug 2026). Removing the original
# is right for a batch: the file was read to be measured and the stereo copy
# is scaffolding. It is wrong for an interactive session, where the Sound is
# the object the USER selected in the Objects window, has probably just
# recorded, and will want again for the next figure. Deleting it out from
# under them to draw a graph is not a trade the graphs flow may make on their
# behalf, and it would also strand every "Draw Another" that re-selects the
# source. So @emlGraphsChannelGate sets the switch and the batch path, which
# has no caller here yet, keeps the documented behaviour byte for byte.
#
# The switch is read through variableExists so a caller that has never heard
# of it gets the original semantics.
# ----------------------------------------------------------------------------
procedure emlApplyChannelChoice: .soundId, .channelHandling
    selectObject: .soundId
    .nChannels = Get number of channels
    .choice$ = ""
    if .nChannels > 1
        .keep = 0
        if variableExists ("emlChannelKeepOriginal")
            if emlChannelKeepOriginal = 1
                .keep = 1
            endif
        endif
        if .channelHandling = 1
            .resultId = Convert to mono
            .choice$ = "Mix to mono"
        elsif .channelHandling = 2
            .resultId = Extract one channel: 1
            .choice$ = "Left channel only"
        elsif .channelHandling = 3
            .resultId = Extract one channel: 2
            .choice$ = "Right channel only"
        else
            # Fallback — treat unknown value as mix to mono
            .resultId = Convert to mono
            .choice$ = "Mix to mono"
        endif
        if .keep = 0
            removeObject: .soundId
        endif
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
        .choice$ = emlApplyChannelChoice.choice$
    else
        .resultId = .soundId
        .wasConverted = 0
        .choice$ = ""
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
# @emlDropStaleChannelSounds: .sourceName$
# Remove the channel Sounds a previous press of the stereo gate left behind.
#
# AUTHOR RULING 8b, 15 August 2026, severity 4. See the header of
# @emlGraphsChannelGate for what accumulated and why the fix is a name and a
# drop rather than a variable: each menu invocation is a fresh script run, so
# nothing a previous press computed survives to be read here except the
# Objects window itself.
#
# IT ONLY EVER REMOVES A SOUND THIS PLUGIN NAMED. The three candidates are
# "eml_" + the source's name + Praat's own conversion suffix, and the gate
# writes exactly that name onto the object it creates. A user's own
# "take_ch1", extracted by hand from the Objects window, does not match and
# is never touched -- which is the whole reason the prefix exists.
#
# `nocheck` because "no such object" is the ordinary case: the first press of
# a session has nothing to collect. It CLEARS THE SELECTION when it fails --
# verified on 6.6.30, 15 Aug 2026, with a Sound selected beforehand and
# numberOfSelected reading 0 afterwards -- which is the property the removal
# below depends on. If a failed lookup left the previous selection standing,
# `selected ("Sound")` would name the user's own stereo recording and this
# procedure would delete it. The caller re-selects afterwards for the same
# reason.
#
# THE LOOP, not a single removal, for the same reason ruling 8a's does: a tree
# that has already shipped the accumulating version can have any number of
# them, and the first press after this lands collects the lot. The bound is a
# safety rail, not a limit anyone should reach.
#
# Arguments: .sourceName$ - the stereo Sound's own name
# Outputs:   .nDropped    - how many were removed
# ----------------------------------------------------------------------------
procedure emlDropStaleChannelSounds: .sourceName$
    .nDropped = 0
    for .k from 1 to 3
        if .k = 1
            .cand$ = "eml_" + .sourceName$ + "_mono"
        elsif .k = 2
            .cand$ = "eml_" + .sourceName$ + "_ch1"
        else
            .cand$ = "eml_" + .sourceName$ + "_ch2"
        endif
        .safety = 0
        .more = 1
        while .more = 1 and .safety < 64
            .safety = .safety + 1
            nocheck selectObject: "Sound " + .cand$
            if numberOfSelected ("Sound") = 1
                .id = selected ("Sound")
                removeObject: .id
                .nDropped = .nDropped + 1
            else
                .more = 0
            endif
        endwhile
    endfor
endproc

# ----------------------------------------------------------------------------
# @emlGraphsChannelGate: .soundId, .purpose$
# The EML Graphs entry to the stereo choice. Ask, once, before a stereo Sound
# becomes a figure or the object a figure is derived from.
#
# Arguments
#   .soundId   an object id. Anything that is not a multi-channel Sound
#              passes straight through, so callers do not have to check.
#   .purpose$  what the Sound is about to be used for, named in the dialog
#              ("waveform", "pitch track", "spectrum", "long-term average
#              spectrum"). A user answering this question deserves to know
#              which figure they are answering it for.
#
# Outputs
#   .resultId      the Sound to use from here on (may equal .soundId)
#   .wasConverted  1 if a channel choice was applied
#   .choice$       what was applied, for the record
#
# THE RULING THIS IMPLEMENTS (author, 14 Aug 2026, verbatim): "Stereo channel
# handling: ABSOLUTELY NECESSARY -- wire it. The Mix-to-mono / Left / Right
# choice must be reachable when an audio object is stereo. @emlHandleStereo /
# @emlCheckChannels / @emlApplyChannelChoice exist with zero callers ... Wire
# the existing procedures into the EML Graphs flow for Sound (and any
# derived-object path where channel choice matters, e.g. before To Pitch)."
#
# WHAT WAS WRONG. Those three procedures had been in the library since v3.18
# and NOTHING CALLED THEM. Not one caller, in either direction. A stereo
# recording -- and an EGG-plus-microphone recording is stereo by
# construction, which in this lab is most of them -- went to a figure with no
# question asked, and the two figures it went to were wrong in two different
# ways.
#
#   THE WAVEFORM WAS WRONG ON ITS OWN AXIS. Praat stacks the channels in two
#   half-height panels, but the plugin has already installed a single
#   amplitude axis across the whole frame. Measured, aud57 pic_g7_stereo_wave
#   .png: the axis reads -0.6 to 0.6 Pa, channel 1 is drawn centred on +0.3
#   and channel 2 on -0.3, and NEITHER trace sits where its amplitude says.
#   A reader taking channel 1's peak off that axis reads 0.55 Pa for a signal
#   whose peak is 0.25. There is no "draw them both" option here for that
#   reason: it is not a view of the data, it is a mislabelled one.
#
#   THE PITCH TRACK WAS WRONG AS A NUMBER, WHICH IS WORSE. Praat converts to
#   mono silently on the way into To Pitch. On the verifier's 220 Hz-left /
#   330 Hz-right test the resulting contour sat at about 110 Hz -- the F0 of
#   the mixture, a frequency present in NEITHER channel and in nothing the
#   singer did. A figure that looks entirely normal and reports a pitch
#   nobody sang. That is why the ruling's parenthesis matters as much as its
#   main clause.
#
# THE ORIGINAL IS KEPT. emlChannelKeepOriginal is set for the call, so the
# user's stereo Sound stays in the Objects window and the derived mono Sound
# joins it. Nothing the user selected is deleted to draw a graph, and the
# derived object's own name records the choice, so a session that is saved
# and reopened still says which channel the figure came from.
#
# ONE PRESS, ONE DERIVED SOUND (author's ruling 8b, 15 Aug 2026, severity 4).
# The derived Sound is kept on purpose -- see the paragraph above -- but it was
# kept ONCE PER PRESS. Five figures drawn from the same stereo recording with
# the same channel chosen left five Sounds called "<name>_ch1" in the Objects
# window, and that is not only clutter: `selectObject: "Sound take_ch1"` then
# answers with one of the five and the user cannot say which. It is the
# duplicate-name mechanism of S1 one level up, in the object list rather than
# in a column menu, and it arrives with no error at all. Reproduced here on
# 15 Aug 2026: three presses through the gate, three extracted Sounds.
#
# TWO HALVES, AND THE FIRST IS WHAT MAKES THE SECOND SAFE.
#
#   THE DERIVED SOUND IS RENAMED to "eml_" + Praat's own derived name, so
#   "take_ch1" becomes "eml_take_ch1". The paragraph above already promised
#   this ("the derived object's own name records the choice") and the code
#   never did it. The prefix is what makes the object identifiable as the
#   plugin's: a user who extracted the left channel by hand from the Objects
#   window has a Sound called "take_ch1", and a cleanup that matched THAT
#   name would delete their work to tidy up after itself.
#
#   THE STALE ONES ARE DROPPED AT THE TOP OF THE NEXT PRESS, which is the
#   placement @eml_dropStaleConverted uses for ruling 8a and for the same
#   reason: a cleanup at the bottom of this procedure is skipped by exactly
#   the errors it would exist to survive, and would then leak on precisely
#   the runs that matter. All three candidate names are dropped -- _mono,
#   _ch1 and _ch2 -- because the choice can differ from press to press and
#   "one derived Sound per source" is the invariant, not "one per choice".
#   A script variable cannot carry the id between presses: each menu
#   invocation is a fresh script run with a fresh variable space, which is
#   why the object's NAME has to be what identifies it.
#
# THE STALE-ID REPAIR is the part that would be a defect if it were left out.
# The graphs form remembers the object it is working from in three globals,
# and after this procedure the figure is drawn from a DIFFERENT object. If
# they were not repointed, the pitch floor/ceiling re-conversion would go
# back to originalSourceId -- the stereo Sound -- and silently re-create the
# 110 Hz contour the user had just chosen their way out of. Each is repointed
# only when it names the very Sound that was replaced, and only when it
# exists at all, so the library stays loadable outside the form.
# ----------------------------------------------------------------------------
procedure emlGraphsChannelGate: .soundId, .purpose$
    .resultId = .soundId
    .wasConverted = 0
    .choice$ = ""
    if .soundId <= 0
        goto CHANNEL_GATE_END
    endif
    selectObject: .soundId
    .full$ = selected$ ()
    .sp = index (.full$, " ")
    if .sp > 0
        .srcType$ = left$ (.full$, .sp - 1)
    else
        .srcType$ = .full$
    endif
    if .srcType$ <> "Sound"
        goto CHANNEL_GATE_END
    endif
    .nChannels = Get number of channels
    if .nChannels < 2
        goto CHANNEL_GATE_END
    endif

    .name$ = selected$ ("Sound")

    ; RULING 8b, first half: collect what the last press on this same Sound
    ; left behind, before making another one. Before the dialog rather than
    ; after it, so that a user who quits at the dialog has still had the
    ; stray from the previous press cleared -- and because the drop clears
    ; the selection, which must not happen between the choice and the
    ; conversion.
    @emlDropStaleChannelSounds: .name$
    .nStale = emlDropStaleChannelSounds.nDropped
    selectObject: .soundId

    beginPause: "Stereo Sound — choose a channel"
        comment: """" + .name$ + """ has " + string$ (.nChannels)
        ... + " channels."
        comment: "This figure is a " + .purpose$
        ... + ", which needs one channel."
        optionmenu: "Channel handling", 1
            option: "Mix to mono"
            option: "Left channel only"
            option: "Right channel only"
        comment: "Mixing two different signals — a microphone and an EGG,"
        comment: "or two singers — gives an F0 that is in neither of them."
        comment: "Your original recording is kept either way."
    .clicked = endPause: "Quit", "Continue", 2, 0
    if .clicked = 1
        exitScript: ""
    endif

    ; The mechanical core, non-destructively. The switch is set immediately
    ; before and cleared immediately after so that nothing else in the
    ; session inherits it.
    emlChannelKeepOriginal = 1
    @emlApplyChannelChoice: .soundId, channel_handling
    emlChannelKeepOriginal = 0
    .resultId = emlApplyChannelChoice.resultId
    .wasConverted = emlApplyChannelChoice.wasConverted
    .choice$ = emlApplyChannelChoice.choice$

    if .wasConverted = 1
        ; Name the derived object for what it is. Praat's own names --
        ; "<name>_mono", "<name>_ch1" -- are already distinct, but a user
        ; scanning the Objects list a week later should not have to remember
        ; which of two similar names came from which menu. The "eml_" prefix
        ; is also what lets the drop above be safe: see ruling 8b in the
        ; header.
        selectObject: .resultId
        Rename: "eml_" + selected$ ("Sound")
        appendInfoLine: "Channel choice: ", .choice$, " applied to """,
        ... .name$, """ for this ", .purpose$, ". The stereo original is",
        ... " still in the Objects window; the figure is drawn from """,
        ... selected$ ("Sound"), """."
        ; --- stale-id repair, see the header ---
        if variableExists ("originalSourceId")
            if originalSourceId = .soundId
                originalSourceId = .resultId
            endif
        endif
        if variableExists ("contextObjectId")
            if contextObjectId = .soundId
                contextObjectId = .resultId
            endif
        endif
        if variableExists ("contextOriginalSourceId")
            if contextOriginalSourceId = .soundId
                contextOriginalSourceId = .resultId
            endif
        endif
        selectObject: .resultId
    endif
    label CHANNEL_GATE_END
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

# ============================================================================
# THE LEGEND PANEL — a legend that is handed a rectangle and stays inside it
# ============================================================================
#
# WHY THIS EXISTS (D136, author's ruling 8 August 2026).
#
# The user types 6 x 4 and means it. Until this revision the only place a
# legend could go was INSIDE the plot, so the only way to give a legend more
# room was to take room away from the data. "Make my figure square" was then
# unsatisfiable: a square canvas with a legend carved out of it is not a
# square plot. The dimensions the user types describe the DATA AREA, and
# furniture must not be billed to it.
#
# So the legend moves OUT and the EXPORT grows to cover it, rather than the
# plot shrinking IN. No new save path was invented for that:
# @emlAssertFullViewport already selects the bounding box of everything
# reported to @emlExpandDrawnExtent, and that is exactly the mechanism this
# needs.
#
# ---------------------------------------------------------------------------
# EXPORT GEOMETRY — READ THIS BEFORE TOUCHING ANY PLACEMENT
# ---------------------------------------------------------------------------
# THE PLOT RECTANGLE IS IDENTICAL IN ALL FIVE PLACEMENTS. It is
# @emlSetAdaptiveTheme's outer viewport, sized from the width and height the
# user asked for; nothing below ever moves it, shrinks it, or re-derives it.
# What the placement changes is how much of the picture the SAVED IMAGE
# covers:
#
#   1 Inside plot      Legend inside the data area, auto-corner. The caller
#                      reports NOTHING to @emlExpandDrawnExtent, so the
#                      exported extent equals the plot rectangle. This is
#                      what the plugin has always drawn, and it is the
#                      DEFAULT — an existing script's figure is unchanged.
#   2 Right of plot    Legend in its own rectangle beside the plot. The
#                      CALLER reports that rectangle, so
#                      @emlAssertFullViewport widens the saved image. A 6 x 4
#                      request still yields a 6 x 4 PLOT; the PNG simply
#                      comes out wider than 6 inches.
#   3 Below plot       The same, in height instead of width.
#   4 Separate figure  Legend drawn on its own parked canvas and NOT
#                      reported, so the figure exports at its own extent; the
#                      save path then writes the legend as a SECOND FILE
#                      beside the first (<name>_legend.png).
#   5 None             Nothing drawn, nothing reported.
#
# THAT IS WHY @emlDrawLegendPanel MUST NOT CALL @emlExpandDrawnExtent. One
# renderer serves a corner box that must not grow the export and a side panel
# that must; only the caller knows which it is asking for. Moving the report
# into the renderer would make placements 1 and 4 impossible to express.
#
# WHY THE RENDERER TAKES A RECTANGLE. Before this, the legend computed its
# own box from the axes and drew wherever that landed — which is how a label
# wider than the frame came to overhang the picture (D135). A renderer that
# is GIVEN its bounds can clamp to them, and this one does: every label is
# measured, and one that will not fit its column is shortened with an
# ellipsis rather than drawn past the edge. Containment stopped being a thing
# the caller has to hope for and became arithmetic the renderer performs.
#
# WHAT IS MEASURED, AND WHERE. Both procedures below select the legend's OWN
# rectangle with `Axes: 0, w, 0, h` over a w x h inch rectangle, so one world
# unit is one inch and `Text width (world coordinates)` returns inches
# directly. Font size is set BEFORE `Select inner viewport` at every site.
# That is not a style rule: Praat converts the inner rectangle to an outer
# one using the font size IN FORCE AT THE TIME OF THE CALL and then maps
# world coordinates back through the font size in force LATER, so measuring
# at a font size other than the one that was set when the viewport was
# selected inflates every width. Measured 8 Aug 2026 on Praat 6.6.30: the
# string "Group label" measures 0.4967" when the viewport is selected at 7 pt
# and read at 7 pt, and 3.6229" when the viewport is selected at 7 pt and
# read at 20 pt — a factor of 2.55 on a font-size ratio of 2.86. That is the
# defect in @emlMeasureGraphLayout's legend estimate, which measures at
# bodySize the box that @emlDrawLegend draws at annotSize.

# ----------------------------------------------------------------------------
# @emlEllipsizeToWidth
# Shortens .text$ until it renders no wider than .maxWidth, appending "..."
# whenever anything was removed.
#
# REQUIRES a viewport already selected whose world units are inches (the
# legend panel's own `Axes: 0, w, 0, h`), and the font size already set to
# the size the text will be drawn at. Width comes from
# `Text width (world coordinates)`, so this is the real rendered width of the
# real string in the real font, not a character-count estimate.
#
# Arguments:
#   .text$     — the label, ALREADY passed through @emlSanitizeLabel
#   .maxWidth  — the budget, in world units (= inches)
# Outputs:
#   .result$   — the label, possibly shortened; "" if not even "..." fits
#   .didClip   — 1 if anything was removed
#
# THE TRAILING-BACKSLASH GUARD IS NOT DECORATION. @emlSanitizeLabel turns a
# user's "%" into "\% ", so a cut can land between the backslash and the
# character it escapes. A dangling "\" at the end of a Praat text string
# escapes what follows it and the label draws as garbage, so one more
# character comes off whenever a cut leaves one.
# ----------------------------------------------------------------------------
procedure emlEllipsizeToWidth: .text$, .maxWidth
    .result$ = .text$
    .didClip = 0
    .w = Text width (world coordinates): .result$
    if .w > .maxWidth
        .didClip = 1
        .n = length (.text$)
        .placed = 0
        while .placed = 0
            if .n < 1
                .result$ = ""
                .placed = 1
            else
                .cand$ = left$ (.text$, .n)
                ; `and` does not short-circuit in Praat, so both operands
                ; have to be safe to evaluate at .n = 0. right$ ("", 1) is
                ; "", which is simply not a backslash, so they are.
                while .n > 0 and right$ (.cand$, 1) = "\"
                    .n = .n - 1
                    .cand$ = left$ (.text$, .n)
                endwhile
                .cand$ = .cand$ + "..."
                .w = Text width (world coordinates): .cand$
                if .w <= .maxWidth
                    .result$ = .cand$
                    .placed = 1
                else
                    .n = .n - 1
                endif
            endif
        endwhile
    endif
endproc

# ----------------------------------------------------------------------------
# @emlMeasureLegendPanel
# Lays the legend out inside a .maxWidth x .maxHeight inch rectangle and
# reports what it would consume. DRAWS NOTHING.
#
# This is the procedure @emlMeasureGraphLayout's legend estimate should
# always have been. That estimate measures at bodySize a box that is drawn at
# annotSize, and models one column where the drawing has folded into several
# since D123 — so it was both wrong and, as its own header says, unread. This
# one measures at the font size the legend is actually drawn at, in the
# legend's own viewport, using the same layout arithmetic the renderer uses,
# because the renderer calls THIS to lay itself out. The two cannot disagree.
#
# Arguments:
#   .maxWidth   — width budget, inches
#   .maxHeight  — height budget, inches
#   .fontSize   — the size the legend will be DRAWN at (typically annotSize)
#
# Outputs (the contract):
#   .width   — inches the laid-out legend consumes, <= .maxWidth
#   .height  — inches it consumes, <= .maxHeight
#   .cols    — columns chosen
#   .rows    — rows per column
#   .fits    — 1 when every entry is shown at its full label inside the
#              budget; 0 when anything was dropped, ellipsized, or the
#              rectangle could not hold even one row
#
# Further outputs, for @emlDrawLegendPanel and for fixtures:
#   .cells      — cells to draw, including the "+N more" cell if any
#   .shown      — entries drawn in full
#   .hidden     — entries folded into "+N more"
#   .capacity   — .rowsMax x .colsMax, the rectangle's room
#   .truncated  — 1 if any entry was dropped
#   .clamped    — 1 if any label was ellipsized to fit the width
#   .label$[]   — the (possibly ellipsized) labels, parallel to legendLabel$[]
#   .cellW[], .colTextW[], .colOff[], .swatchSide, .lineH, .xPad, .yPad,
#   .colGap, .moreLabel$, .patterned, .markered, .markerLine
#
# READS THE EXISTING LEGEND ENTRY GLOBALS AND ONLY THOSE — legendN,
# legendLabel$[], legendColor$[], legendFill$[], legendPattern[],
# legendMarker[], legendPatterned, legendMarkered, legendMarkerLine. How
# entries are populated is unchanged and no caller has to be touched.
#
# EMITS NOTHING TO THE INFO WINDOW. It is called repeatedly while a caller
# searches for a band height, and a NOTE per probe would be noise. The NOTE
# about dropped entries belongs to @emlDrawLegendPanel, which is the
# procedure that actually drops them.
#
# Restores `Font size: bodySize` and the panel viewport before returning,
# the same invariant @emlMeasureGraphLayout keeps.
# ----------------------------------------------------------------------------
procedure emlMeasureLegendPanel: .maxWidth, .maxHeight, .fontSize
    .width = 0
    .height = 0
    .cols = 0
    .rows = 0
    .fits = 0
    .cells = 0
    .shown = 0
    .hidden = 0
    .capacity = 0
    .rowsMax = 0
    .colsMax = 0
    .truncated = 0
    .clamped = 0
    .moreLabel$ = ""
    .patterned = 0
    .markered = 0
    .markerLine = 0
    .swatchSide = 0
    .lineH = 0
    .xPad = 0
    .yPad = 0
    .colGap = 0

    .n = 0
    if variableExists ("legendN")
        .n = legendN
    endif
    if .n = undefined
        .n = 0
    endif

    ; Three independent refusals, each its own test — `and` does not
    ; short-circuit, so chaining them would evaluate all three anyway and
    ; read as though it did not.
    .go = 1
    if .n < 1
        .go = 0
    endif
    if .maxWidth < 0.05
        .go = 0
    endif
    if .maxHeight < 0.05
        .go = 0
    endif

    if .go = 1
        ; --- swatch style, read exactly as @emlDrawLegend has always read it
        if variableExists ("legendPatterned")
            if legendPatterned = 1
                .patterned = 1
            endif
        endif
        if variableExists ("legendMarkered")
            if legendMarkered = 1
                .markered = 1
            endif
        endif
        if .markered = 1
            if variableExists ("legendMarkerLine")
                if legendMarkerLine = 1
                    .markerLine = 1
                endif
            endif
        endif

        .fontInch = .fontSize / 72
        .sf = emlSetAdaptiveTheme.spacingFactor
        .lineH = .fontInch * 1.4
        .xPad = .fontInch * (0.3 + 0.3 * .sf)
        .yPad = .fontInch * (0.3 + 0.2 * .sf)
        ; Patterned swatches are drawn larger: three hatch stripes or two dot
        ; rows do not survive in a 0.8-em square. Markered ones larger again:
        ; a triangle in a 0.8-em cell is four pixels at a 7 pt legend.
        .swatchSide = .fontInch * 0.8
        if .patterned = 1
            .swatchSide = .fontInch * 1.25
        endif
        if .markered = 1
            .swatchSide = .fontInch * 1.4
        endif
        ; One xPad ON TOP OF the xPad that already trails every column, so
        ; the eye reads two columns rather than one wide one.
        .colGap = .xPad

        ; --- MEASURE AT THE REAL FONT SIZE, IN A ONE-WORLD-UNIT-PER-INCH
        ; --- VIEWPORT THE SIZE OF THE BUDGET. Font size FIRST; see the
        ; --- section header for the 2.55x error the other order produces.
        Font size: .fontSize
        Select inner viewport: 0, .maxWidth, 0, .maxHeight
        Axes: 0, .maxWidth, 0, .maxHeight

        ; Per entry, because a multi-column box sizes each column to its own
        ; widest label. The 1.05 safety margin is applied per entry, before
        ; the max rather than after, which is what leaves a one-column box
        ; bit-identical to the geometry v1.25 drew.
        .maxLabelW = 0
        for .i from 1 to .n
            .label$[.i] = legendLabel$[.i]
            .w = Text width (world coordinates): .label$[.i]
            .cellW[.i] = .w * 1.05
            if .cellW[.i] > .maxLabelW
                .maxLabelW = .cellW[.i]
            endif
        endfor

        ; THE EPSILON IS NOT DECORATION, AND IT IS NOT A FUDGE FACTOR.
        ;
        ; A caller that sizes a budget to hold exactly K rows computes
        ; 2 * yPad + K * lineH, hands that in as a rectangle, and this line
        ; divides it back out — so the quotient is mathematically the whole
        ; number K and floor() is being asked to stand on a boundary. The
        ; rectangle arrives as .y1 - .y0, a difference of two picture
        ; coordinates several inches from the origin, so it is a few units in
        ; the last place BELOW the value the caller computed, the quotient is
        ; K - 1e-16, and floor() returns K - 1. One whole row of the legend
        ; disappears and the entries in it are reported as truncated.
        ;
        ; Observed, not theorised: placement 3's band search settled on three
        ; rows for a twelve-entry legend on a 5 x 5 figure and the panel then
        ; laid out two, dropping three entries into "+3 more" (8 Aug 2026).
        ;
        ; 1e-9 of a row is 2.5e-7 pixels at 300 dpi. It can only promote a
        ; quotient already within a billionth of a whole number, which is
        ; never a row that genuinely does not fit.
        .epsFit = 0.000000001
        .rowsMax = floor ((.maxHeight - 2 * .yPad) / .lineH + .epsFit)
        if .rowsMax < 0
            .rowsMax = 0
        endif

        ; The overflow cell's width has to be known BEFORE capacity is, or
        ; the cell that announces the truncation could be the thing that
        ; overflows. Measured with .n in it, which has at least as many
        ; digits as any hidden count, so it is an upper bound on the notice.
        .moreLabel$ = "+" + string$ (.n) + " more"
        .w = Text width (world coordinates): .moreLabel$
        .unitW = .w * 1.05
        if .maxLabelW > .unitW
            .unitW = .maxLabelW
        endif

        ; Same boundary, same epsilon — see .rowsMax above.
        .colsMax = floor ((.maxWidth - 2 * .xPad + .colGap)
        ... / (.swatchSide + .xPad + .unitW + .colGap) + .epsFit)

        if .colsMax < 1
            ; D135. One column of full-width labels does not fit the
            ; rectangle. This is where the legend used to give up and draw
            ; past the edge — the box was laid out AS THOUGH one column
            ; fitted and the overhang was left to the picture.
            ;
            ; A renderer that is given its bounds does not have that option.
            ; The column is clamped to the width that IS available and every
            ; label is ellipsized to it, so a label wider than the whole
            ; frame comes out as "Extremely long gro..." inside the box
            ; instead of running off the canvas. The ellipsis is visible, and
            ; @emlDrawLegendPanel says so in the Info window, so nothing is
            ; shortened in silence either.
            .colsMax = 1
            .clamped = 1
            .budget = .maxWidth - 3 * .xPad - .swatchSide
            if .budget < 0
                .budget = 0
            endif
            ; Ellipsize against the budget BEFORE the 1.05 margin, so that
            ; cellW (which carries the margin) still lands inside it.
            .textBudget = .budget / 1.05
            .maxLabelW = 0
            for .i from 1 to .n
                @emlEllipsizeToWidth: .label$[.i], .textBudget
                .label$[.i] = emlEllipsizeToWidth.result$
                .w = Text width (world coordinates): .label$[.i]
                .cellW[.i] = .w * 1.05
                if .cellW[.i] > .maxLabelW
                    .maxLabelW = .cellW[.i]
                endif
            endfor
            @emlEllipsizeToWidth: .moreLabel$, .textBudget
            .moreLabel$ = emlEllipsizeToWidth.result$
            .w = Text width (world coordinates): .moreLabel$
            .unitW = .w * 1.05
            if .maxLabelW > .unitW
                .unitW = .maxLabelW
            endif
        endif

        .capacity = .rowsMax * .colsMax
        .cells = .n
        .shown = .n
        .hidden = 0

        if .rowsMax < 1
            ; Not one row fits. Drawing a row anyway is what the old code
            ; did (rowsMax was floored to 1) and it is drawing outside the
            ; rectangle, which is the one thing this renderer may not do.
            .cells = 0
            .shown = 0
            .hidden = .n
            .truncated = 1
        elsif .n > .capacity
            ; TRUNCATION IS THE LAST RESORT AND IT IS NEVER SILENT. The last
            ; cell becomes "+N more" ON THE FIGURE and @emlDrawLegendPanel
            ; puts a NOTE naming both counts in the Info window.
            .shown = .capacity - 1
            if .shown < 0
                .shown = 0
            endif
            .hidden = .n - .shown
            .cells = .shown + 1
            .truncated = 1
            .moreLabel$ = "+" + string$ (.hidden) + " more"
            if .clamped = 1
                @emlEllipsizeToWidth: .moreLabel$, .textBudget
                .moreLabel$ = emlEllipsizeToWidth.result$
            endif
            .w = Text width (world coordinates): .moreLabel$
            .cellW[.cells] = .w * 1.05
        endif

        if .cells > 0
            ; Fewest columns that fit the height, so the box stays narrow.
            ; .cells <= .rowsMax x .colsMax by construction, so .cols never
            ; exceeds .colsMax and the width below cannot exceed .maxWidth.
            ; A caller that wants a WIDE, SHORT panel (placement 3, below the
            ; plot) gets one by handing in a short .maxHeight rather than by
            ; asking for a different algorithm.
            .cols = ceiling (.cells / .rowsMax)
            if .cols < 1
                .cols = 1
            endif
            if .cols > .colsMax
                .cols = .colsMax
            endif
            .rows = ceiling (.cells / .cols)
            if .rows > .rowsMax
                .rows = .rowsMax
            endif
            if .cols * .rows < .cells
                ; Belt and braces. The arithmetic above says this cannot
                ; happen; if it ever does, a cell without a slot would be
                ; drawn on top of another one, so the count is cut to the
                ; slots that exist and the truncation is reported.
                .cells = .cols * .rows
                .shown = .cells - 1
                if .shown < 0
                    .shown = 0
                endif
                .hidden = .n - .shown
                .truncated = 1
            endif

            .width = 2 * .xPad + (.cols - 1) * .colGap
            .off = .xPad
            for .c from 1 to .cols
                .colTextW[.c] = 0
                for .r from 1 to .rows
                    ; Column-major fill: cell k is in column
                    ; (k-1) div rows + 1, which keeps the palette's hue order
                    ; running top-to-bottom down each column.
                    .k = (.c - 1) * .rows + .r
                    if .k <= .cells
                        if .cellW[.k] > .colTextW[.c]
                            .colTextW[.c] = .cellW[.k]
                        endif
                    endif
                endfor
                .colOff[.c] = .off
                .off = .off + .swatchSide + .xPad + .colTextW[.c] + .colGap
                .width = .width + .swatchSide + .xPad + .colTextW[.c]
            endfor
            .height = 2 * .yPad + .rows * .lineH
        endif

        .fits = 1
        if .truncated = 1
            .fits = 0
        endif
        if .clamped = 1
            .fits = 0
        endif
        if .width > .maxWidth
            .fits = 0
        endif
        if .height > .maxHeight
            .fits = 0
        endif
    endif

    ; Restore the invariant the rest of the figure runs on. Font size BEFORE
    ; the viewport, for the reason in the section header.
    Font size: emlSetAdaptiveTheme.bodySize
    @emlSetPanelViewport
endproc

# ----------------------------------------------------------------------------
# @emlDrawLegendPanel
# Draws the legend into EXACTLY the rectangle it is handed.
#
# Arguments (inches, Praat picture coordinates — x rightward and y DOWNWARD
# from the top-left of the picture, the same system @emlSetAdaptiveTheme's
# outerLeft/outerRight/outerTop/outerBottom are in):
#   .x0, .x1   — left and right edge
#   .y0, .y1   — top and bottom edge
#   .fontSize  — the size legend text is drawn at
#
# Outputs (the contract):
#   .usedWidth   — inches actually consumed, <= .x1 - .x0
#   .usedHeight  — inches actually consumed, <= .y1 - .y0
#   .shown       — entries drawn in full
#   .truncated   — 1 if any entry was dropped
# and, passed through from the layout: .cells, .cols, .rows, .hidden,
# .capacity, .clamped; plus .usedX0/.usedX1/.usedY0/.usedY1, the consumed
# sub-rectangle in the SAME picture inches the arguments are in, which is
# what a caller reports to @emlExpandDrawnExtent.
#
# THE RECTANGLE IS A BUDGET, NOT A BOX. Hand in the space the legend is
# ALLOWED to occupy; the procedure lays out inside it, consumes what it needs
# and reports what it took. Do NOT hand in a rectangle you obtained by
# measuring first: the layout sizes each column to ITS OWN widest label while
# the column COUNT is derived from the widest label overall, so a rectangle
# shrunk to a previous measurement can fit fewer columns than that
# measurement chose. Measured 8 Aug 2026 on the 24-entry fixture
# harness/stress_cases/legend_cap.praat: measuring 6 x 4's data area gives
# two columns of twelve, and re-measuring inside the resulting box gives one
# column of eleven with fourteen entries dropped. Hence one measurement, of
# the budget, here — and hence .usedWidth/.usedHeight, so a caller that needs
# the real size can have it without measuring again.
#
# CONTENT IS ANCHORED TOP-LEFT unless the global emlLegendPanelAnchor$ says
# otherwise ("top-left" default, "top-right", "bottom-left", "bottom-right").
# That global is how placement 1 reaches a corner of the data area while
# still handing in the whole data area as its budget; every other placement
# leaves it at the default. It is read through variableExists, so a caller
# that has never heard of it gets top-left.
#
# MUST NOT DRAW OUTSIDE THE RECTANGLE. That is the load-bearing constraint of
# this whole design and it is what makes D135 fixable rather than structural:
# the layout clamps the width, the ellipsis clamps the labels, the row count
# clamps the height, and Praat's own viewport clipping is the backstop. A
# change here that lets ink escape the rectangle re-opens the overhang for
# every placement at once.
#
# MUST NOT CALL @emlExpandDrawnExtent. See EXPORT GEOMETRY in the section
# header: an inside-plot legend must not grow the saved image and a side
# panel must, and only the caller knows which one it asked for. The caller
# reports.
#
# Reads the existing legend entry globals; does not write any of them.
#
# Leaves Colour Black, Line width 1.0 and `Font size: bodySize`. Leaves the
# VIEWPORT on the panel rectangle — a caller that will draw more of the
# figure afterwards must re-select its own, exactly as @emlDrawLegend does.
# ----------------------------------------------------------------------------
procedure emlDrawLegendPanel: .x0, .x1, .y0, .y1, .fontSize
    .w = .x1 - .x0
    .h = .y1 - .y0

    @emlMeasureLegendPanel: .w, .h, .fontSize
    .usedWidth = emlMeasureLegendPanel.width
    .usedHeight = emlMeasureLegendPanel.height
    .shown = emlMeasureLegendPanel.shown
    .truncated = emlMeasureLegendPanel.truncated
    .hidden = emlMeasureLegendPanel.hidden
    .cells = emlMeasureLegendPanel.cells
    .cols = emlMeasureLegendPanel.cols
    .rows = emlMeasureLegendPanel.rows
    .capacity = emlMeasureLegendPanel.capacity
    .clamped = emlMeasureLegendPanel.clamped

    ; Where the consumed box sits inside the budget. Anchoring is the only
    ; thing the anchor global changes; the layout above is already decided.
    .anchor$ = "top-left"
    if variableExists ("emlLegendPanelAnchor$")
        .anchor$ = emlLegendPanelAnchor$
    endif
    .usedX0 = .x0
    if .anchor$ = "top-right"
        .usedX0 = .x1 - .usedWidth
    endif
    if .anchor$ = "bottom-right"
        .usedX0 = .x1 - .usedWidth
    endif
    .usedY0 = .y0
    if .anchor$ = "bottom-left"
        .usedY0 = .y1 - .usedHeight
    endif
    if .anchor$ = "bottom-right"
        .usedY0 = .y1 - .usedHeight
    endif
    .usedX1 = .usedX0 + .usedWidth
    .usedY1 = .usedY0 + .usedHeight

    if .cells > 0
        .patterned = emlMeasureLegendPanel.patterned
        .markered = emlMeasureLegendPanel.markered
        .markerLine = emlMeasureLegendPanel.markerLine
        .swatchSide = emlMeasureLegendPanel.swatchSide
        .lineH = emlMeasureLegendPanel.lineH
        .xPad = emlMeasureLegendPanel.xPad
        .yPad = emlMeasureLegendPanel.yPad

        ; Font size FIRST, then the viewport. One world unit is one inch
        ; inside it, which is what lets every number below be an inch.
        Font size: .fontSize
        Select inner viewport: .x0, .x1, .y0, .y1
        Axes: 0, .w, 0, .h

        ; The pattern and marker scale for THIS viewport. @emlSetPatternScale
        ; cannot be used: it derives world-per-inch from @emlSetAdaptiveTheme's
        ; INNER viewport, which is the plot's rectangle and not this one. Here
        ; world units are inches by construction, so the scale is exactly 1 on
        ; both axes — which also makes the swatch square without a correction.
        ; The panel's own scale is restored on the way out, because the caller
        ; may still have marks to draw.
        .savedSX = 0
        .savedSY = 0
        .hadScale = 0
        if variableExists ("emlPatWorldPerInchX")
            .savedSX = emlPatWorldPerInchX
            .savedSY = emlPatWorldPerInchY
            .hadScale = 1
        endif
        emlPatWorldPerInchX = 1
        emlPatWorldPerInchY = 1

        ; AND THE DATA FRAME IS SUSPENDED FOR THE SAME REASON, one line of
        ; reasoning further on (15 Aug 2026). @emlSetPatternScale publishes
        ; the plot's frame so @emlDrawMarker can decline to paint a datum
        ; outside it (NEW-G8-1). This panel installs its OWN axes two lines
        ; above, in which one world unit is one inch — so a swatch at y = 0.9
        ; is compared against a data frame running 22 to 41 and refused, and
        ; every key vanishes from the legend while the figure still looks
        ; plausible. Measured on harness/stress_out/scatter_grouped.png: three
        ; coloured dots gone, three labels left behind.
        ;
        ; The frame belongs to the plot's world and means nothing in this one,
        ; so it is turned off here and restored on the way out beside the
        ; scale it travels with. A clip is only meaningful against the axes it
        ; was measured on.
        .savedFrame = 0
        if variableExists ("emlFrameKnown")
            .savedFrame = emlFrameKnown
        endif
        emlFrameKnown = 0

        ; y is measured UPWARD from the rectangle's bottom in this world,
        ; while the arguments are picture inches measured DOWNWARD from the
        ; top, so the anchored top edge flips as it comes in.
        .boxLeft = .usedX0 - .x0
        .boxRight = .boxLeft + .usedWidth
        .boxTop = .h - (.usedY0 - .y0)
        .boxBottom = .boxTop - .usedHeight

        ; Background fill + border. Semi-transparent by whichever means the
        ; platform has: the alpha sprite on macOS and Windows, the stipple
        ; screen everywhere else. See SCREEN-DOOR TRANSPARENCY above; the
        ; sprite branch inside @emlPaintAlphaBox issues the same
        ; `Insert picture from file:` this procedure used to issue here, so
        ; the two platforms that have alpha draw exactly what they drew.
        ;
        ; The screen needs a world-per-inch to scale by and this viewport's
        ; is already installed a few lines above: emlPatWorldPerInchX/Y are
        ; both 1 here, because `Axes: 0, .w, 0, .h` makes one world unit one
        ; inch. So the lattice is 0.027 inch on the page, as it is everywhere
        ; else, without a correction.
        @emlPaintAlphaBox: .boxLeft, .boxRight, .boxBottom, .boxTop
        if emlPaintAlphaBox.viewportDirty = 1
            ; `Insert picture from file:` left the VIEWPORT set to the
            ; image's own bounding box. Every coordinate below is in this
            ; panel's world, so the panel has to be selected again right here
            ; rather than at the end of the procedure — restoring it after
            ; the swatches are drawn restores nothing, it just stops the
            ; damage spreading.
            Font size: .fontSize
            Select inner viewport: .x0, .x1, .y0, .y1
            Axes: 0, .w, 0, .h
        endif
        Colour: "{0.7, 0.7, 0.7}"
        Line width: 0.5
        Draw rectangle: .boxLeft, .boxRight, .boxBottom, .boxTop

        ; Entries — filled swatches with axis-colored text labels
        Font size: .fontSize
        for .i from 1 to .cells
            .col = (.i - 1) div .rows + 1
            .row = .i - (.col - 1) * .rows
            .entryY = .boxTop - .yPad - (.row - 0.5) * .lineH
            .swatchLeft = .boxLeft + emlMeasureLegendPanel.colOff[.col]
            .swatchRight = .swatchLeft + .swatchSide
            .swatchTop = .entryY + .swatchSide / 2
            .swatchBottom = .entryY - .swatchSide / 2
            .textX = .swatchRight + .xPad

            if .i > .shown
                ; The overflow cell. No swatch — it stands for no one style —
                ; and it starts at the swatch column so it reads as a line of
                ; the key rather than a stray label.
                Colour: emlSetAdaptiveTheme.textColor$
                Text: .swatchLeft, "left", .entryY, "half",
                ... emlMeasureLegendPanel.moreLabel$
            elsif .markered = 1
                ; The key IS the mark: same @emlDrawMarker, same shape index,
                ; same colour, at the panel's own scale.
                .midX = (.swatchLeft + .swatchRight) / 2
                if .markerLine = 1
                    Colour: legendColor$[.i]
                    Line width: emlSetAdaptiveTheme.dataLineWidth
                    Draw line: .swatchLeft, .entryY, .swatchRight, .entryY
                    Line width: 0.5
                endif
                @emlDrawMarker: .midX, .entryY, .swatchSide * 0.42,
                ... legendMarker[.i], legendColor$[.i]
            elsif .patterned = 1
                ; Same construction the mark uses: fill, then pattern in the
                ; same ink, then the stroke colour as an outline.
                ; @emlPatternSetup is given the swatch's own half-width, so
                ; the stripe pitch scales to the swatch.
                .halfW = (.swatchRight - .swatchLeft) / 2
                .midX = (.swatchLeft + .swatchRight) / 2
                Paint rectangle: legendFill$[.i], .swatchLeft, .swatchRight,
                ... .swatchBottom, .swatchTop
                .lp = legendPattern[.i]
                .lpDo = 0
                if .lp = 2 or .lp = 3
                    .lpDo = 1
                endif
                if .lpDo = 1
                    @emlPatternSetup: legendFill$[.i], legendColor$[.i],
                    ... .halfW, 0, .h
                    if emlPatternSetup.usable = 0
                        .lpDo = 0
                    endif
                endif
                if .lpDo = 1 and .lp = 2
                    .rowH = 0.004 * emlPatternSetup.sy
                    .nRows = 1
                    if .rowH > 0
                        .nRows = ceiling ((.swatchTop - .swatchBottom) / .rowH)
                    endif
                    if .nRows < 1
                        .nRows = 1
                    endif
                    .rowStep = (.swatchTop - .swatchBottom) / .nRows
                    for .r from 1 to .nRows
                        @emlPaintHatchRow: .midX, .halfW,
                        ... .swatchBottom + (.r - 1) * .rowStep,
                        ... .swatchBottom + .r * .rowStep, .swatchBottom
                    endfor
                endif
                if .lpDo = 1 and .lp = 3
                    .dotStepY = emlPatternSetup.dotPitch * emlPatternSetup.sy
                    .dotRY = emlPatternSetup.dotR * emlPatternSetup.sy
                    .nDotRows = 0
                    if .dotStepY > 0
                        .nDotRows = floor ((.swatchTop - .swatchBottom)
                        ... / .dotStepY)
                    endif
                    for .r from 0 to .nDotRows
                        .dy = .swatchBottom + (.r + 0.5) * .dotStepY
                        if .dy - .dotRY >= .swatchBottom
                            if .dy + .dotRY <= .swatchTop
                                @emlPaintDotRow: .midX, .halfW, .dy, .r,
                                ... .swatchBottom
                            endif
                        endif
                    endfor
                endif
                ; The swatch OUTLINE takes the same @emlMarkInk flip the
                ; mark's outline takes, or a slot-8 greyscale swatch would
                ; draw a near-black border on a near-black fill.
                @emlMarkInk: legendFill$[.i], legendColor$[.i]
                Colour: emlMarkInk.result$
                Line width: 0.8
                Draw rectangle: .swatchLeft, .swatchRight, .swatchBottom,
                ... .swatchTop
                Line width: 0.5
            else
                Colour: legendColor$[.i]
                Paint rectangle: legendColor$[.i], .swatchLeft, .swatchRight,
                ... .swatchBottom, .swatchTop
            endif
            if .i <= .shown
                Colour: emlSetAdaptiveTheme.textColor$
                Text: .textX, "left", .entryY, "half",
                ... emlMeasureLegendPanel.label$[.i]
            endif
        endfor

        Colour: "Black"
        Line width: 1.0

        if .hadScale = 1
            emlPatWorldPerInchX = .savedSX
            emlPatWorldPerInchY = .savedSY
        endif
        emlFrameKnown = .savedFrame
    endif

    ; NOTHING IS DROPPED OR SHORTENED IN SILENCE. Both notices come from
    ; here, the procedure that actually did it, and not from
    ; @emlMeasureLegendPanel, which a caller may run several times while it
    ; searches for a band height.
    if .truncated = 1
        appendInfoLine: "NOTE: legend shows ", .shown, " of ", legendN,
        ... " entries — the panel has room for ", .capacity,
        ... ". The other ", .hidden, " are marked ",
        ... emlMeasureLegendPanel.moreLabel$, " on the figure."
    endif
    if .clamped = 1
        ; @eml_fixed, NOT fixed$. AUTHOR RULING, 16 AUGUST 2026: "anything in
        ; an active process needs fixed", and this line is as active as the
        ; file gets -- @emlDrawLegendPanel is what @emlDrawLegend dispatches
        ; to, every draw procedure that has a legend calls @emlDrawLegend, and
        ; EML Graphs... is registered on Objects > New and on the Table,
        ; Sound, Pitch, Spectrum, Ltas, TableOfReal and Matrix action lists.
        ;
        ; fixed$ IS NOT A FIXED-PRECISION FORMATTER. It prints
        ; max (precision, -floor (log10 |v|)) decimals, so it ESCALATES below
        ; 10^-precision and returns a bare "0" for exact zero.
        ;
        ; AND NO REACHABLE INPUT TO THIS SENTENCE IS DOWN THERE, WHICH IS
        ; MEASURED RATHER THAN ASSUMED AND IS SAID HERE SO THAT NOBODY LATER
        ; READS THIS PARAGRAPH AS A BUG REPORT. Swept 16 August 2026 on
        ; 6.6.30 -- three entries, one over-wide label, the panel budget
        ; stepped from 4.04 in down to 0.002 in -- `.clamped` is 1 from 4.04
        ; down to 0.052 and 0 at 0.048 and below, where @emlMeasureLegendPanel
        ; reports capacity 0, shows nothing and prints no note at all. So the
        ; narrowest panel that can reach this line is about 0.05 in, at which
        ; fixed$ and @eml_fixed agree to the last digit, as they do at every
        ; width above it; and .fontSize is the adaptive theme's, which never
        ; approaches 0.1 pt. Every case in harness/legend prints 3.32, 4.04 or
        ; 7.97 at 8.0, 8.3 or 9.8, and those logs and validate/v32's
        ; exact-wording assertion on them are byte-identical across this
        ; change.
        ;
        ; SO WHY CHANGE IT. Because the ruling is about the ESCAPE HATCH and
        ; not about today's arithmetic: an active Info-window line formatted
        ; through fixed$ is one edit away from lying -- change the precision
        ; to 3, or start printing a fraction of an inch, and the sentence
        ; silently grows a digit -- and the plugin now has exactly one number
        ; formatter so that no reader has to work out which sites are safe.
        ; The measurement above is the honest size of the win: nothing moves.
        ; Where the two formatters do part company is recorded in
        ; harness/formaxis's `formatter` leg.
        ;
        ; HOISTED INTO TEMPORARIES because Praat cannot nest a procedure call
        ; inside an expression: the result comes back in eml_fixed.result$ and
        ; has to be read before the next call overwrites it. @eml_fixed lives
        ; in stats/eml-output.praat and is the one implementation in the
        ; plugin; a second one here would be a second thing to keep right.
        @eml_fixed: .w, 2
        .panelStr$ = eml_fixed.result$
        @eml_fixed: .fontSize, 1
        .fontStr$ = eml_fixed.result$
        appendInfoLine: "NOTE: legend labels were shortened with an ellipsis",
        ... " — the widest one does not fit a ",
        ... .panelStr$, " inch panel at ", .fontStr$,
        ... " pt. Widen the figure, shorten the labels, or set Legend",
        ... " placement to Right of plot or Separate figure."
    endif

    Font size: emlSetAdaptiveTheme.bodySize
endproc

# ----------------------------------------------------------------------------
# @emlDrawLegend
# Draws the legend for the current panel, WHERE THE USER ASKED FOR IT.
#
# This is the entry point every draw procedure calls, and its signature has
# not changed. What changed is that it is now a PLACEMENT DISPATCHER over
# @emlDrawLegendPanel rather than a renderer of its own: it works out the
# rectangle the legend is allowed to occupy, hands that rectangle to the
# panel renderer, and — only when the placement puts the legend outside the
# plot — reports the rectangle to @emlExpandDrawnExtent so the saved image
# grows to cover it. See EXPORT GEOMETRY in the section header above.
#
# THE PLOT RECTANGLE IS NEVER TOUCHED BY ANY OF THIS. A 6 x 4 request yields
# a 6 x 4 plot in all five placements; placements 2 and 3 make the saved PNG
# larger than 6 x 4, they do not make the plot smaller.
#
# PLACEMENT COMES FROM THE GLOBAL emlLegendPlacement, read through
# variableExists and defaulting to 1. A script that predates this — every
# stress case, every PraatGen companion file, every caller in
# eml-draw-procedures.praat — sets nothing and gets placement 1, which is the
# corner box it has always drawn, at the geometry it has always drawn it.
# The plugin sets emlLegendPlacement from config_legendPlacement, whose
# encoding, registry and dialog live in eml-graphs-form.praat.
#
#   1 Inside plot     — DEFAULT. Auto-corner box inside the data area.
#   2 Right of plot   — own rectangle to the right; export widens.
#   3 Below plot      — own rectangle below; export heightens.
#   4 Separate figure — parked off-figure and saved as a second file.
#   5 None            — not drawn.
#
# Requires global variables before call:
#   legendN          — integer, number of entries. The palette holds 24
#                      sub-group styles, so 24 is the number this has to
#                      draw; there is no hard ceiling above it, because the
#                      LAYOUT is what limits the box and a ceiling written
#                      here would be a second, disagreeing limit.
#   legendColor$[1..N] — RGB colour strings for each entry
#   legendLabel$[1..N] — text labels for each entry (pre-sanitized)
#
# Optional globals, unchanged in meaning:
#   legendPatterned / legendPattern[] / legendFill$[]  — patterned swatches
#   legendMarkered  / legendMarker[]  / legendMarkerLine — the marker key
#
# WHY THE SWATCH CARRIES THE PATTERN AND THE MARK. The palette's 24 styles
# are 8 hues x 3 fill patterns, so entries 1 and 9 have the SAME
# legendColor$ and differ only in the pattern; a legend that drew colour
# alone would print two identical swatches against two different names, which
# is D127 relocated from the figure into the key. The same argument makes the
# marker key draw @emlDrawMarker rather than a square. Both are unchanged
# here — this revision moves the legend, it does not restyle an entry.
#
# THE BOX IS LAID OUT TO FIT ITS RECTANGLE. Rows that fit the height and
# columns that fit the width are counted, the entries are poured down the
# FEWEST columns that fit the height, and only if the rectangle is still
# exceeded is anything dropped — and then the last cell reads "+N more" ON
# THE FIGURE and a NOTE naming both counts goes to the Info window. At 24
# entries on a 6 x 4 figure that is two columns of 12; a legend that fits in
# one column gets the identical single-column geometry v1.24 drew. All of
# that now lives in @emlMeasureLegendPanel and is shared with every
# placement. See there for the D135 ellipsis, which is new: a label wider
# than the frame is shortened rather than drawn past the edge.
#
# Arguments:
#   xMin, xMax, yMin, yMax — current axis bounds (data coordinates)
#   position$ — corner for placement 1: "top-left" (default), "top-right",
#               "bottom-left", "bottom-right". Ignored by placements 2-5,
#               which have only one place to be.
#   fontSize  — font size for legend text (typically annotSize)
#
# Reports (procedure locals, readable by the caller after return — the names
# and meanings @emlDrawLegend has always published):
#   .nCols, .rowsPerCol — the layout chosen
#   .shown, .hidden     — entries drawn, entries folded into "+N more"
#   .capacity           — the rectangle's room, in cells
#   .boxLeft/.boxRight/.boxTop/.boxBottom — the box, IN DATA COORDINATES, so
#                         a caller keeping clear of the legend still can. For
#                         placements 2-4 these describe a rectangle outside
#                         the axis range, which is truthful: the legend is
#                         not in the plot any more and nothing in the plot
#                         needs to avoid it. For placement 5 the box is empty.
#   .placement          — the placement actually used, after clamping
#   .panelX0/.panelX1/.panelY0/.panelY1 — the rectangle, in inches
#   .truncated, .clamped — anything dropped / any label ellipsized
#
# Draws: filled white background, thin grey border, swatches drawn as the
#   mark, and text labels in axis text colour. Leaves Colour Black and Line
#   width 1.0. Restores Font size: bodySize and the panel viewport and axes
#   before returning, so the caller can carry on drawing the figure.
# ----------------------------------------------------------------------------
procedure emlDrawLegend: .xMin, .xMax, .yMin, .yMax, .position$, .fontSize
    .placement = 1
    if variableExists ("emlLegendPlacement")
        .placement = emlLegendPlacement
    endif
    ; A hand-edited config, or a caller that computed the value, can hand in
    ; anything. Out of range becomes the default rather than no legend at all.
    if .placement = undefined
        .placement = 1
    endif
    if .placement < 1
        .placement = 1
    endif
    if .placement > 5
        .placement = 1
    endif

    .nCols = 0
    .rowsPerCol = 0
    .shown = 0
    .hidden = 0
    .capacity = 0
    .truncated = 0
    .clamped = 0
    .boxLeft = .xMin
    .boxRight = .xMin
    .boxTop = .yMax
    .boxBottom = .yMax
    .panelX0 = 0
    .panelX1 = 0
    .panelY0 = 0
    .panelY1 = 0

    .n = 0
    if variableExists ("legendN")
        .n = legendN
    endif
    if .n = undefined
        .n = 0
    endif

    ; The parked-legend handshake with the save path. Cleared on EVERY call,
    ; so a figure whose placement changed from 4 to something else cannot
    ; leave a stale second file waiting to be written.
    emlLegendSepActive = 0

    .inset = emlSetAdaptiveTheme.boxInsetInches
    .innerW = emlSetAdaptiveTheme.innerRight - emlSetAdaptiveTheme.innerLeft
    .innerH = emlSetAdaptiveTheme.innerBottom - emlSetAdaptiveTheme.innerTop

    .draw = 1
    if .n < 1
        .draw = 0
    endif
    if .placement = 5
        .draw = 0
    endif

    if .draw = 1
        ; -------------------------------------------------------------------
        ; Each branch computes a BUDGET rectangle — the space the legend is
        ; allowed to occupy — and an anchor inside it. @emlDrawLegendPanel
        ; measures that budget once, consumes what it needs and reports the
        ; sub-rectangle it took back in .usedX0/.usedX1/.usedY0/.usedY1.
        ;
        ; Handing it a budget rather than a pre-measured box is not a style
        ; choice. Column COUNT comes from the widest label overall while each
        ; column is sized to its OWN widest label, so a box shrunk to a
        ; previous measurement can fit fewer columns than that measurement
        ; chose: on the 24-entry fixture, two columns of twelve measured
        ; against 6 x 4's data area become one column of eleven with fourteen
        ; entries dropped when re-measured inside their own box. One
        ; measurement, of the budget, is the fix.
        ; -------------------------------------------------------------------
        ;
        ; -------------------------------------------------------------------
        ; THE BOTTOM OF THE PAGE, as everything already committed below the
        ; plot has left it. Placements 3 and 4 both need it — 3 puts its band
        ; under it, 4 parks its panel a clear twelve inches beyond it — and
        ; both used to read it from ONE source. This is the second.
        ;
        ; SOURCE ONE, totalCanvasHeight. The graphs form sizes the comparison
        ; matrix panel before it dispatches the draw and leaves
        ; figure_height + matrixGap + matrixPanelHeight in that global, so
        ; inside the form it is the whole answer and this block changes
        ; nothing there.
        ;
        ; SOURCE TWO, THE MATRIX'S OWN MEASUREMENT, and why it had to be
        ; added. totalCanvasHeight is a FORM local. @emlDrawLegend is reached
        ; from outside the form as well: a standalone script or a PraatGen
        ; companion file calls @emlInitDrawingDefaults, which sets
        ; emlLegendPlacement and does NOT set totalCanvasHeight. Such a caller
        ; that laid out its own matrix and then asked for placement 3 got a
        ; band starting at the plot's own bottom edge, drawn straight THROUGH
        ; the matrix panel. Measured 8 Aug 2026 on a 6 x 4 figure with a
        ; four-group Tukey matrix: the band ran 4.140 to 4.566 inches while
        ; the panel ran 4.130 to 6.204, and the panel's omnibus line and its
        ; correction subtitle came out overprinted by the legend's entries —
        ; 11636 pixels of legend ink inside the matrix band, against 0 now.
        ;
        ; @emlMeasureMatrixLayout is a PRECONDITION of @emlDrawMatrixPanel —
        ; the panel is a pure renderer and reads emlMatrixLayout_* — so any
        ; caller that is going to draw a matrix has already published its
        ; height by the time a legend is drawn, wherever that caller lives.
        ; The arithmetic mirrors the form's, term for term:
        ;
        ;     totalCanvasHeight = figure_height       <- outerBottom
        ;                       + matrixGap           <- bodyInch + overhang
        ;                       + matrixPanelHeight   <- max (yMax, 1.0)
        ;
        ; graphOverhangInches is another form local, but the value it is
        ; assigned from — emlFitCategoricalLabels.overhangInches — is a
        ; drawing-layer global that @emlInitDrawingDefaults seeds at 0, so the
        ; rotated-label allowance is read from where it actually lives.
        ;
        ; THE LARGER OF THE TWO WINS, and neither can pull the band UP: the
        ; page bottom starts at the plot's own bottom edge and only ever
        ; grows. A form-driven figure is unaffected because the two sources
        ; agree there; a caller that publishes neither is unaffected because
        ; it has drawn nothing below the plot to clear.
        ; -------------------------------------------------------------------
        .pageBottom = emlSetAdaptiveTheme.outerBottom
        if variableExists ("totalCanvasHeight")
            if totalCanvasHeight <> undefined
                if totalCanvasHeight > .pageBottom
                    .pageBottom = totalCanvasHeight
                endif
            endif
        endif
        ; A matrix is "live" only if there are at least two groups to compare
        ; AND @emlMeasureMatrixLayout has published a layout that is not
        ; suppressed. No published measurement means no panel can be drawn at
        ; all, so there is nothing below the plot to clear.
        .matrixLive = 0
        if variableExists ("annotMatrixN")
            if annotMatrixN <> undefined
                if annotMatrixN >= 2
                    .matrixLive = 1
                endif
            endif
        endif
        if .matrixLive = 1
            if variableExists ("emlMatrixLayout_suppressed")
                if emlMatrixLayout_suppressed <> 0
                    .matrixLive = 0
                endif
            else
                .matrixLive = 0
            endif
        endif
        if .matrixLive = 1
            ; max (yMax, 1.0) — the form's floor, and the panel's own
            ; top-down sizing never puts the drawn bottom past it.
            .matrixH = 1.0
            if variableExists ("emlMatrixLayout_yMax")
                if emlMatrixLayout_yMax <> undefined
                    if emlMatrixLayout_yMax > .matrixH
                        .matrixH = emlMatrixLayout_yMax
                    endif
                endif
            endif
            .matrixOverhang = 0
            if variableExists ("emlFitCategoricalLabels.overhangInches")
                if emlFitCategoricalLabels.overhangInches <> undefined
                    .matrixOverhang = emlFitCategoricalLabels.overhangInches
                endif
            endif
            .matrixBottom = emlSetAdaptiveTheme.outerBottom
            ... + emlSetAdaptiveTheme.bodyInch + .matrixOverhang + .matrixH
            if .matrixBottom > .pageBottom
                .pageBottom = .matrixBottom
            endif
        endif

        emlLegendPanelAnchor$ = "top-left"
        if .placement = 1
            ; ---------------------------------------------------------------
            ; 1 INSIDE PLOT — the corner box, unchanged.
            ;
            ; Budget is the whole data area inset by boxInsetInches on all
            ; four sides, which is the same uniform physical inset every
            ; overlay box uses, and the anchor puts the box in the requested
            ; corner of it. Expressed in inches this is arithmetically the
            ; same budget and the same corner the world-coordinate version
            ; computed, so the pixels are the ones the plugin has always
            ; produced.
            ;
            ; NOTHING IS REPORTED TO @emlExpandDrawnExtent. The legend is
            ; inside the plot, the plot is already reported, and the exported
            ; extent is the plot rectangle.
            ; ---------------------------------------------------------------
            .panelX0 = emlSetAdaptiveTheme.innerLeft + .inset
            .panelX1 = emlSetAdaptiveTheme.innerRight - .inset
            .panelY0 = emlSetAdaptiveTheme.innerTop + .inset
            .panelY1 = emlSetAdaptiveTheme.innerBottom - .inset
            if .position$ = "top-right"
                emlLegendPanelAnchor$ = "top-right"
            elsif .position$ = "bottom-right"
                emlLegendPanelAnchor$ = "bottom-right"
            elsif .position$ = "bottom-left"
                emlLegendPanelAnchor$ = "bottom-left"
            else
                ; Default: top-left
                emlLegendPanelAnchor$ = "top-left"
            endif

        elsif .placement = 2
            ; ---------------------------------------------------------------
            ; 2 RIGHT OF PLOT — its own rectangle beside the figure.
            ;
            ; Height budget is the data area's height, so the panel folds
            ; into as few columns as that allows, which is as NARROW as it
            ; can be. Width budget is one figure width: a legend may double
            ; the image, it may not run away with it, and a label wider than
            ; that is ellipsized by @emlMeasureLegendPanel rather than drawn
            ; past the edge.
            ; ---------------------------------------------------------------
            .panelX0 = emlSetAdaptiveTheme.outerRight + .inset
            .panelX1 = .panelX0 + (emlSetAdaptiveTheme.outerRight
            ... - emlSetAdaptiveTheme.outerLeft)
            .panelY0 = emlSetAdaptiveTheme.innerTop
            .panelY1 = .panelY0 + .innerH

        elsif .placement = 3
            ; ---------------------------------------------------------------
            ; 3 BELOW PLOT — its own rectangle under the figure.
            ;
            ; The layout pours entries down the fewest columns that fit the
            ; HEIGHT, so a wide short strip is asked for by handing in a
            ; short height rather than by a second algorithm. The band starts
            ; at one row and grows a row at a time until everything fits or
            ; half the figure height is reached; the band that is drawn is
            ; the band the search stopped on, and the panel re-measures
            ; against that same band, so the two agree by construction.
            ;
            ; The band clears the matrix panel when there is one. Where the
            ; page bottom comes from — the form's totalCanvasHeight, or the
            ; matrix's own published measurement when the caller is not the
            ; form — is settled once in .pageBottom above; here the band
            ; simply starts one inset below it, so the legend sits under the
            ; comparison matrix rather than on top of it.
            ; ---------------------------------------------------------------
            .fontInch = .fontSize / 72
            .lineH = .fontInch * 1.4
            .yPad = .fontInch * (0.3 + 0.2 * emlSetAdaptiveTheme.spacingFactor)
            ; Left edge aligned with the DATA area, not the figure's outer
            ; edge. Aligning to outerLeft puts the panel's border on pixel
            ; column 0 of the exported PNG, where a 0.5-width line is drawn
            ; half outside the image, and leaves the key hanging to the left
            ; of everything else on the page. The band search below has to
            ; run against THIS width, not a wider one, or the row count it
            ; settles on is one the panel cannot reproduce.
            .panelX0 = emlSetAdaptiveTheme.innerLeft
            .panelX1 = emlSetAdaptiveTheme.outerRight
            .maxW = .panelX1 - .panelX0
            .bandCap = (emlSetAdaptiveTheme.outerBottom
            ... - emlSetAdaptiveTheme.outerTop) * 0.5
            .tryRows = 1
            .searching = 1
            while .searching = 1
                .band = 2 * .yPad + .tryRows * .lineH
                @emlMeasureLegendPanel: .maxW, .band, .fontSize
                if emlMeasureLegendPanel.fits = 1
                    .searching = 0
                elsif .band + .lineH > .bandCap
                    .searching = 0
                else
                    .tryRows = .tryRows + 1
                endif
            endwhile
            .below = .pageBottom
            .panelY0 = .below + .inset
            .panelY1 = .panelY0 + .band

        else
            ; ---------------------------------------------------------------
            ; 4 SEPARATE FIGURE — parked off-figure, saved as a second file.
            ;
            ; The legend is drawn NOW, on a patch of picture far below
            ; anything the figure will ever report, and is deliberately NOT
            ; reported to @emlExpandDrawnExtent — so @emlAssertFullViewport
            ; saves the figure at exactly its own extent, as if there were no
            ; legend at all. The save path then selects the parked rectangle
            ; and writes it as a second PNG beside the first.
            ;
            ; Drawing it now and selecting it later, rather than erasing the
            ; picture and redrawing, is what lets BOTH files come out of one
            ; figure: an Erase would destroy the figure the user is about to
            ; save again, and a redraw would re-run the whole analysis.
            ;
            ; THE FONT SIZE IS THE PARENT FIGURE'S. .fontSize arrives from
            ; the caller as emlSetAdaptiveTheme.annotSize — the figure's own
            ; annotation size — and is passed straight through rather than
            ; recomputed from the legend canvas. A legend canvas is small, so
            ; a recomputed size would be smaller, and a user placing the two
            ; side by side in a manuscript would get legend text visibly
            ; unlike the figure's axis labels.
            ; ---------------------------------------------------------------
            ; Twelve inches clear of the bottom of the page, and never less
            ; than 24 — the same .pageBottom placement 3 uses, so a matrix
            ; measured outside the form pushes the park down here too.
            .park = 24
            if .pageBottom + 12 > .park
                .park = .pageBottom + 12
            endif
            .panelX0 = .inset
            .panelX1 = .panelX0 + (emlSetAdaptiveTheme.outerRight
            ... - emlSetAdaptiveTheme.outerLeft)
            .panelY0 = .park + .inset
            .panelY1 = .panelY0 + (emlSetAdaptiveTheme.outerBottom
            ... - emlSetAdaptiveTheme.outerTop)
        endif

        if .panelX1 > .panelX0
            @emlDrawLegendPanel: .panelX0, .panelX1, .panelY0, .panelY1,
            ... .fontSize
            .nCols = emlDrawLegendPanel.cols
            .rowsPerCol = emlDrawLegendPanel.rows
            .shown = emlDrawLegendPanel.shown
            .hidden = emlDrawLegendPanel.hidden
            .capacity = emlDrawLegendPanel.capacity
            .truncated = emlDrawLegendPanel.truncated
            .clamped = emlDrawLegendPanel.clamped

            ; What the panel actually took, inside the budget it was given.
            ; Everything below — the extent report, the parked rectangle, the
            ; data-coordinate box — describes THIS and not the budget, or a
            ; short legend beside a tall plot would report a rectangle three
            ; times its own height and pad the exported image with white.
            .panelX0 = emlDrawLegendPanel.usedX0
            .panelX1 = emlDrawLegendPanel.usedX1
            .panelY0 = emlDrawLegendPanel.usedY0
            .panelY1 = emlDrawLegendPanel.usedY1

            ; ---------------------------------------------------------------
            ; THE REPORT. This is the whole point of the change, so it is the
            ; one place to read if the exported image is the wrong size.
            ;
            ; Placements 1 and 5 report NOTHING: the exported extent stays
            ; equal to the plot rectangle, which is what makes a 5 x 5
            ; request come out 5 x 5.
            ;
            ; Placements 2 and 3 report the LEGEND rectangle, and only that.
            ; @emlAssertFullViewport unions it with the plot rectangle, so
            ; the saved image widens or heightens to hold both. The plot
            ; rectangle is not consulted, not modified, and not re-derived —
            ; a 5 x 5 request still draws a 5 x 5 plot and simply exports a
            ; larger picture around it.
            ;
            ; Placement 4 reports NOTHING either: its legend is a SECOND
            ; FILE, and reporting it would drag the figure's extent 24
            ; inches down the canvas.
            ; ---------------------------------------------------------------
            ;
            ; The reported rectangle carries one boxInsetInches of trailing
            ; margin on the side that grows — the same physical gap that
            ; separates the panel from the plot, mirrored on the outside.
            ; Without it the panel's own border IS the last pixel column of
            ; the PNG, and a 0.5-width line centred on the boundary is drawn
            ; half outside the image. Measured before adding it on a 5 x 5
            ; figure: the exported width was 1697 px and the panel's right
            ; edge was at 1697.
            if .placement = 2
                @emlExpandDrawnExtent: .panelX0, .panelX1 + .inset,
                ... .panelY0, .panelY1
            endif
            if .placement = 3
                @emlExpandDrawnExtent: .panelX0, .panelX1,
                ... .panelY0, .panelY1 + .inset
            endif
            if .placement = 4
                emlLegendSepActive = 1
                emlLegendSepX0 = .panelX0 - .inset
                emlLegendSepX1 = .panelX1 + .inset
                emlLegendSepY0 = .panelY0 - .inset
                emlLegendSepY1 = .panelY1 + .inset
                emlLegendSepFontSize = .fontSize
            endif

            ; The box in DATA coordinates, for callers that keep clear of it.
            .wpiX = 0
            .wpiY = 0
            if .innerW > 0
                .wpiX = (.xMax - .xMin) / .innerW
            endif
            if .innerH > 0
                .wpiY = (.yMax - .yMin) / .innerH
            endif
            .boxLeft = .xMin
            ... + (.panelX0 - emlSetAdaptiveTheme.innerLeft) * .wpiX
            .boxRight = .xMin
            ... + (.panelX1 - emlSetAdaptiveTheme.innerLeft) * .wpiX
            .boxTop = .yMax
            ... - (.panelY0 - emlSetAdaptiveTheme.innerTop) * .wpiY
            .boxBottom = .yMax
            ... - (.panelY1 - emlSetAdaptiveTheme.innerTop) * .wpiY
        endif
    endif

    Colour: "Black"
    Line width: 1.0

    ; Put the anchor back to the default. It is a global, and a caller that
    ; reaches @emlDrawLegendPanel directly after a top-right legend should
    ; not inherit a corner it never asked for.
    emlLegendPanelAnchor$ = "top-left"

    ; Restore font size BEFORE viewport — Select inner viewport uses the
    ; current font size to compute margin widths, so restoring them the other
    ; way round installs a viewport measured at the legend's font.
    Font size: emlSetAdaptiveTheme.bodySize
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
    # problem — THAT ENTRY POINT has no implementation.
    #
    # It is only that entry point, and the distinction matters, because
    # "Linux cannot draw images" is the wrong lesson and was drawn from
    # this comment once already. Re-probed 9 Aug 2026 on the same build:
    #
    #   Read from file: on a PNG           -> a Photo object. Works.
    #   Paint image: on an OPAQUE Photo    -> draws, in full colour.
    #                                         FF0000 landed over blue.
    #   Create Photo: + Paint image:       -> same, with no file at all.
    #   Paint image: on an RGBA Photo      -> draws, but does NOT
    #                                         composite: it renders flat
    #                                         grey equal to the alpha
    #                                         value (a=179 -> B3B3B3).
    #   Extract red / Extract transparency -> Matrix objects. Work.
    #   Matrix -> Photo recombine          -> no such command found.
    #   Create Photo: with an alpha plane  -> impossible; the command
    #                                         takes 14 arguments, being
    #                                         a name, five x-params, five
    #                                         y-params and THREE colour
    #                                         formulas. There is no
    #                                         transparency formula.
    #
    # So Praat rasterises images on Linux perfectly well through
    # Graphics_image (the cell-array path); it is Graphics_imageFromFile
    # that is missing its cairo branch. What is unreachable from script
    # on ANY platform is alpha compositing: you cannot author a
    # transparency plane, Paint image ignores the one a file carries, and
    # the Photo -> Matrix -> Photo round trip that would let you blend by
    # hand is broken at the recombine step.
    #
    # Which is why the Linux fallback is a screen door and not the Photo
    # route. Routing the sprite through Paint image would draw the box
    # OPAQUE GREY -- strictly worse than the opaque white it replaces.
    # Cost is not the reason either; measured on this build, per box:
    # Paint rectangle 0.009 ms, Paint image 0.027 ms, screen door
    # 0.064 ms. Sixty-four microseconds is not a budget anyone is
    # spending. The sprite is used on macOS and Windows because it is
    # correct there, not because the alternatives are slow.
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
    ; NEW-G8-1: the same frame test @emlDrawMarker applies. The two paths draw
    ; the same scatter -- alpha sprites on macOS and Windows, native markers
    ; on Linux -- so a clip in one and not the other would make the defect
    ; platform-dependent, which is the hardest kind to find.
    @emlPointInFrame: .x, .y
    if emlPointInFrame.inside = 0
        if variableExists ("emlClippedN") = 0
            emlClippedN = 0
        endif
        emlClippedN = emlClippedN + 1
        goto ALPHA_DOT_END
    endif
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
    label ALPHA_DOT_END
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
#   emlLayout_legendCols         — columns the legend folds into
#   emlLayout_legendRows         — rows per column
#   emlLayout_legendFits         — 1 if every entry fits at its full label
#
# The five legend outputs come from @emlMeasureLegendPanel, the same layout
# @emlDrawLegend draws with, at the same font size (annotSize) — see the
# Legend dimensions block below for what they used to be and why.
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
    #
    # v3.28 (D136): THIS NO LONGER HAS A LAYOUT OF ITS OWN. It delegates to
    # @emlMeasureLegendPanel, which is the same procedure @emlDrawLegend uses
    # to lay itself out, so the estimate and the drawing cannot disagree.
    #
    # What it used to be, and why that was worth deleting rather than
    # documenting a third time: a SINGLE-COLUMN, UNCAPPED stack measured at
    # bodySize. Both halves were wrong. Single-column stopped being the
    # geometry at D123, when the legend began folding into as many columns as
    # the frame needs; and bodySize was never the size it is drawn at —
    # every one of the seven call sites in eml-draw-procedures.praat passes
    # emlSetAdaptiveTheme.annotSize. Measuring at the wrong size is not a
    # rounding error: Praat maps world coordinates through the font size in
    # force when the viewport was selected, and "Group label" measures
    # 0.4967" selected and read at 7 pt against 3.6229" selected at 7 pt and
    # read at 20 pt (8 Aug 2026, Praat 6.6.30). The v3.26 note said the two
    # globals had no reader anywhere and left it there. Being unread is what
    # let it stay wrong; it is now correct instead, and it is the same code
    # path the renderer runs, so it stays correct.
    #
    # The budget measured is PLACEMENT 1's — the data area inset by
    # boxInsetInches on all four sides — because that is the placement whose
    # box has to be planned around. Placements 2 and 3 do not consume figure
    # margins at all; they grow the exported image instead. See EXPORT
    # GEOMETRY above @emlDrawLegendPanel.
    if variableExists ("legendN")
        if legendN > 0
            .inset = emlSetAdaptiveTheme.boxInsetInches
            @emlMeasureLegendPanel: .innerW - 2 * .inset,
            ... .innerH - 2 * .inset, .annotSize
            emlLayout_legendWidthInches = emlMeasureLegendPanel.width
            emlLayout_legendHeightInches = emlMeasureLegendPanel.height
            emlLayout_legendCols = emlMeasureLegendPanel.cols
            emlLayout_legendRows = emlMeasureLegendPanel.rows
            emlLayout_legendFits = emlMeasureLegendPanel.fits
            # @emlMeasureLegendPanel leaves the panel viewport selected and
            # bodySize in force, but not the 0..innerW x 0..innerH axes this
            # procedure measures in, so they go back.
            Font size: .bodySize
            @emlSetPanelViewport
            Axes: 0, .innerW, 0, .innerH
        else
            emlLayout_legendWidthInches = 0
            emlLayout_legendHeightInches = 0
            emlLayout_legendCols = 0
            emlLayout_legendRows = 0
            emlLayout_legendFits = 1
        endif
    else
        emlLayout_legendWidthInches = 0
        emlLayout_legendHeightInches = 0
        emlLayout_legendCols = 0
        emlLayout_legendRows = 0
        emlLayout_legendFits = 1
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
        # Zero categories. Checked against the code 8 Aug 2026, and BOTH
        # halves of what this comment used to say were wrong.
        #
        # It is NOT "a category column of blanks". @emlCountGroups treats the
        # empty string as a label like any other, so an all-blank column comes
        # back as ONE group whose name is "" — measured on a 3-row table of
        # blanks: nGroups = 1. What actually arrives here is a 0-ROW table, or
        # a group column that does not exist (nGroups = 0 with .error$ set).
        #
        # And the refusal is not where this comment used to point. It cited a
        # line of eml-graphs-form.praat that in fact held
        # `prev_gvAnnotStyle = 1`, a grouped-violin persistence variable; the
        # citation was ~750 lines stale and was carried by eleven files until
        # the 7 Aug contradiction sweep (C3). No line number is quoted here
        # any more, because the replacement number went stale inside a day
        # too. Grep the form for the string instead:
        #
        #     exitScript: "Table has no rows."
        #
        # with `exitScript: "Table has no columns."` immediately above it. The
        # form also builds its column menus from the table's own header, so a
        # non-existent group column cannot be chosen there either. Both cases
        # therefore reach here only from a PraatGen standalone script or
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
# v3.23 (7 Aug 2026): ZERO IS NOT "NO DATA". The v3.22 invariant below used
# to read "emlBarData_mean[g] and emlBarData_error[g] are ALWAYS defined
# numbers on return", with 0 standing in for both "no usable observation" and
# "undefined error". It kept undefined out of the drawing commands, and it
# also made the two claims indistinguishable downstream: @emlDrawBarChart
# guards every bar with "emlBarData_mean[g] <> undefined" and every whisker
# with "emlBarData_error[g] <> undefined", and NEITHER GUARD COULD EVER FIRE.
# Its .nSkippedBars and .nSkippedErrors counters were dead code and both
# disclosures that read them were unreachable. A group with nothing in it
# drew as a bar of height zero — the same picture a genuine measurement of
# zero draws — and an undefined error bar drew no whisker with no note.
#
# Invariant (hard, revised): emlBarData_mean[g] is undefined exactly when
# emlBarData_valid[g] = 0, and emlBarData_error[g] is undefined exactly when
# emlBarData_errorDefined[g] = 0. The sentinel is the SAME undefined the
# consumers already test for, so "no measurement" now reaches the caller as a
# distinct value from a measurement of zero, and the two existing guards
# suppress the bar and the whisker on their own.
#
# CALLERS MUST GUARD. Every read of emlBarData_mean[g] / emlBarData_error[g]
# needs either a "<> undefined" test or a valid[g] / errorDefined[g] test
# first; an unguarded one reaches Praat's drawing commands and aborts the
# figure with «Argument "To y" has the value "undefined"», which is the very
# failure v3.22 was written to stop. The three readers in this repository —
# @emlDrawBarChart's bar loop, its error-bar loop, and its quadrant-occupancy
# scan — were already written that way, which is why they were dead. The
# visible-range scan at the foot of this procedure was NOT: it summed
# mean + error unguarded and would have dropped every group from the axis
# range under errorMode = 0, so it now substitutes 0 for an undefined error.
#
# Outputs (module-level globals):
#   emlBarData_nGroups          — number of unique groups
#   emlBarData_label$[g]        — group name for group g
#   emlBarData_mean[g]          — mean of value column for group g;
#                                 UNDEFINED when valid[g] = 0
#   emlBarData_error[g]         — error value for group g (SE/SD/custom);
#                                 UNDEFINED when errorDefined[g] = 0
#   emlBarData_count[g]         — count of USABLE observations for group g
#   emlBarData_visibleMax       — max(mean + error) across valid groups
#   emlBarData_visibleMin       — min(mean - error) across valid groups
#   emlBarData_valid[g]         — 1 if group g has >= 1 usable observation
#   emlBarData_errorDefined[g]  — 1 if the error bar for group g is a real
#                                 quantity; 0 when there is none to compute
#                                 (n = 1, no usable custom error value, or
#                                 the group itself has no observation), in
#                                 which case emlBarData_error[g] is undefined.
#                                 A non-positive variance is NOT this case:
#                                 the spread really is nil, so error = 0 with
#                                 errorDefined = 1.
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
    # Same reader as the analysis. See @emlDrawColumnIsClean.
    @emlDrawColumnIsClean: .tableId, .valueCol$
    .cleanVal = emlDrawColumnIsClean.clean
    # GUARDED, because .errorCol$ is "" on every bar chart that draws no error
    # bars -- which is most of them. The unguarded version aborted the whole
    # figure with `there is no column named ""`, caught by
    # harness/determinism/run.sh on the first run after the conversion. The
    # read it pairs with is gated on .errorMode = 3; the test has to be gated
    # on the same thing or it is a different condition wearing the same name.
    .cleanErr = 0
    if .errorMode = 3
        @emlDrawColumnIsClean: .tableId, .errorCol$
        .cleanErr = emlDrawColumnIsClean.clean
    endif
    for .i from 1 to .nRows
        selectObject: .tableId
        .thisGroup$ = Get value: .i, .groupCol$
        @eml_readCell: .tableId, .i, .valueCol$, .cleanVal
        .thisVal = eml_readCell.value
        .thisErr = undefined
        if .errorMode = 3
            @eml_readCell: .tableId, .i, .errorCol$, .cleanErr
            .thisErr = eml_readCell.value
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
        # v3.23: undefined, not 0. See the invariant at the head of this
        # procedure — 0 is a measurement, and a group with no observation has
        # not made one.
        emlBarData_mean[.g] = undefined
        emlBarData_error[.g] = undefined
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
            # v3.23: an undefined error contributes no headroom. Before the
            # sentinel change emlBarData_error[g] was 0 here whenever there
            # was nothing to compute, so this sum was always defined; it is
            # now undefined under errorMode = 0 (every group), n = 1, and a
            # missing custom error, and an unguarded sum would have failed the
            # "<> undefined" tests below and collapsed the axis to 0..0.
            .errForRange = 0
            if emlBarData_errorDefined[.g] = 1
                .errForRange = emlBarData_error[.g]
            endif
            .topVal = emlBarData_mean[.g] + .errForRange
            if .topVal <> undefined
                if .topVal > emlBarData_visibleMax
                    emlBarData_visibleMax = .topVal
                endif
            endif
            .botVal = emlBarData_mean[.g] - .errForRange
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


# ----------------------------------------------------------------------------
# @emlConvertForGraph: .sourceId, .targetType$, .pitchFloor, .pitchTop
# Turn whatever the user selected into whatever the figure needs, and record
# having done it.
#
# Outputs
#   .result      the new object's id, or 0 when this pair is not one it reaches
#   .temporary   1 when the caller must remove .result after drawing, 0 when
#                the conversion produces a working object the session keeps
#
# WHY THIS IS A PROCEDURE. Several of the plugin's figures are drawn from
# objects the user never makes. Select a Sound and ask for an F0 contour, a
# spectrum or an LTAS; select a Spectrum and ask for any of those; select a
# Matrix or a TableOfReal and ask for anything table-shaped -- the plugin
# converts, draws, and in the acoustic cases REMOVES the intermediate at the
# end of the pass. A Sound is what comes off a recorder, so for three of the
# four acoustic figures this is the path most users take.
#
# Until 12 Aug 2026 all five conversions lived inline inside
# @emlGraphsWorkflow's beginPause: loop, where the only way to reach one was a
# real X display and a driven dialog. So none was ever driven, and the
# recorder's behaviour on all of them was wrong in a way nothing could see:
# the capture hook is inside the DRAW procedure, which is handed the
# INTERMEDIATE, so every figure recorded this way emitted
#
#     data1$ = "Pitch tone"   ; step 3 (draw)
#
# naming, as the object the reader must have open, something the plugin had
# just deleted and the user never created. The emitted script could not run.
#
# THE CONVERSION IS RECORDED AS A STEP, so the manifest names what the USER
# selected and the emitted file carries the command that derives the rest,
# parameters included. The pitch floor and ceiling are a methods-section fact
# and were previously nowhere in the record.
#
# .temporary IS NOT COSMETIC. The acoustic conversions produce an object the
# form removes; the Matrix and TableOfReal ones produce a Table the session
# goes on working with, and removing that would take the user's data view with
# it. The distinction lived in whether the old inline code happened to assign
# loadedObjectId; it is now stated.
#
# Guarded on the recorder's PRESENCE, not on recording state: this file must
# stay loadable without eml-record.praat, which harness/norecord pins.
# ----------------------------------------------------------------------------
procedure emlConvertForGraph: .sourceId, .targetType$, .pitchFloor, .pitchTop
    .result = 0
    .temporary = 0
    .code$ = ""
    .why$ = ""

    selectObject: .sourceId
    .full$ = selected$ ()
    .sp = index (.full$, " ")
    if .sp > 0
        .srcType$ = left$ (.full$, .sp - 1)
    else
        .srcType$ = .full$
    endif

    .pitchArgs$ = "0, " + string$ (.pitchFloor) + ", " + string$ (.pitchTop)
    ... + ", 15, ""yes"", 0.03, 0.09, 0.50, 0.055, 0.35, 0.14"
    .pitchWhy$ = "The pitch floor and ceiling are the ones this session used. "
    ... + "They change the contour, so they belong in a methods section."

    if .srcType$ = "Sound"
        ; THE RULING'S PARENTHESIS, WIRED (15 Aug 2026). "...and any
        ; derived-object path where channel choice matters, e.g. before To
        ; Pitch." All three acoustic conversions below hand a Sound to a
        ; Praat command that will mix it down for itself if it is stereo,
        ; and say nothing. To Pitch is the one that turns that into a wrong
        ; NUMBER rather than a wrong picture -- 220 Hz left and 330 Hz right
        ; come back as a contour near 110 Hz, an F0 in neither channel --
        ; so the question is asked HERE, before the conversion, and not
        ; after, when there is no longer a stereo object to ask about.
        ;
        ; @emlGraphsChannelGate passes anything mono straight through, so
        ; the ordinary single-channel recording sees no dialog at all and
        ; this is a no-op for it.
        .gated = 0
        if .targetType$ = "Pitch"
            .gated = 1
            @emlGraphsChannelGate: .sourceId, "pitch track"
        elsif .targetType$ = "Spectrum"
            .gated = 1
            @emlGraphsChannelGate: .sourceId, "spectrum"
        elsif .targetType$ = "Ltas"
            .gated = 1
            @emlGraphsChannelGate: .sourceId, "long-term average spectrum"
        endif
        if .gated = 1
            if emlGraphsChannelGate.wasConverted = 1
                .sourceId = emlGraphsChannelGate.resultId
            endif
        endif
        selectObject: .sourceId
        if .targetType$ = "Pitch"
            .result = To Pitch (filtered autocorrelation): 0, .pitchFloor,
            ... .pitchTop, 15, "yes", 0.03, 0.09, 0.50, 0.055, 0.35, 0.14
            .code$ = "data = To Pitch (filtered autocorrelation): "
            ... + .pitchArgs$
            .why$ = .pitchWhy$
            .temporary = 1
        elsif .targetType$ = "Spectrum"
            .result = To Spectrum: "yes"
            .code$ = "data = To Spectrum: ""yes"""
            .why$ = "Fast (FFT) transform, which is what the figure was drawn "
            ... + "from."
            .temporary = 1
        elsif .targetType$ = "Ltas"
            .result = To Ltas: 100
            .code$ = "data = To Ltas: 100"
            .why$ = "100 Hz bandwidth, the value this session used."
            .temporary = 1
        endif

    elsif .srcType$ = "Spectrum"
        if .targetType$ = "Ltas"
            .result = To Ltas (1-to-1)
            .code$ = "data = To Ltas (1-to-1)"
            .why$ = "One LTAS bin per spectral bin -- no rebinning, so the "
            ... + "figure shows the spectrum's own resolution."
            .temporary = 1
        elsif .targetType$ = "Sound"
            .result = To Sound
            .code$ = "data = To Sound"
            .why$ = "Inverse transform back to a waveform."
            .temporary = 1
        elsif .targetType$ = "Pitch"
            ; TWO STEPS, and the emitted code says so. A Spectrum has no
            ; pitch track; the route is back through a Sound, and the
            ; intermediate is removed on both sides so neither the session
            ; nor the emitted script leaves one behind.
            .tmp = To Sound
            selectObject: .tmp
            .result = To Pitch (filtered autocorrelation): 0, .pitchFloor,
            ... .pitchTop, 15, "yes", 0.03, 0.09, 0.50, 0.055, 0.35, 0.14
            removeObject: .tmp
            .code$ = "tmp = To Sound" + newline$
            ... + "selectObject: tmp" + newline$
            ... + "data = To Pitch (filtered autocorrelation): " + .pitchArgs$
            ... + newline$
            ... + "removeObject: tmp" + newline$
            ... + "selectObject: data"
            .why$ = "A Spectrum carries no pitch track, so the route is back "
            ... + "through a Sound. " + .pitchWhy$
            .temporary = 1
        endif

    elsif .srcType$ = "TableOfReal"
        if .targetType$ = "Table"
            .result = To Table: "row"
            @emlCleanConvertedTable: .result
            .code$ = "data = To Table: ""row""" + newline$
            ... + "@emlCleanConvertedTable: data"
            .why$ = "Kept as a working object rather than removed after "
            ... + "drawing, so the session goes on using the Table."
            .temporary = 0
        endif

    elsif .srcType$ = "Matrix"
        if .targetType$ = "Table"
            .tmpTor = To TableOfReal
            .result = To Table: "row"
            removeObject: .tmpTor
            @emlCleanConvertedTable: .result
            .code$ = "tmp = To TableOfReal" + newline$
            ... + "data = To Table: ""row""" + newline$
            ... + "removeObject: tmp" + newline$
            ... + "selectObject: data" + newline$
            ... + "@emlCleanConvertedTable: data"
            .why$ = "A Matrix reaches a Table through a TableOfReal. Kept as "
            ... + "a working object rather than removed after drawing."
            .temporary = 0
        endif
    endif

    if .result > 0 and variableExists ("emlRecordLoaded")
        @emlRecordInit
        if emlRecordActive = 1
            @emlRecordConvert: .sourceId, .result, .code$, .why$
        endif
    endif

    if .result > 0
        selectObject: .result
    endif
endproc


# ----------------------------------------------------------------------------
# @emlCleanConvertedTable
# After converting TableOfReal or Matrix -> Table, fix "?" placeholders.
# Praat's To Table: "row" writes "?" for empty row/column labels.
#
# MOVED HERE FROM eml-graphs-form.praat on 12 Aug 2026. @emlConvertForGraph
# calls it, and a recorded conversion emits a call to it into a file that
# includes the draw layer but not the form -- so while it lived in the form
# the emitted script named a procedure it could not reach. It touches no
# dialog and belongs in the library.
#
# Arguments: .tableId
# Outputs: modifies .tableId in place
# ----------------------------------------------------------------------------
procedure emlCleanConvertedTable: .tableId
    selectObject: .tableId
    .nCols = Get number of columns
    .nRows = Get number of rows

    # The row-label column is named "row" by To Table: "row".
    # Check if another column is also named "row" — if so, rename the
    # row-label column (always column 1) to avoid ambiguity.
    .rowColName$ = "row"
    .hasCollision = 0
    for .iCol from 2 to .nCols
        .checkLabel$ = Get column label: .iCol
        if .checkLabel$ = "row"
            .hasCollision = 1
        endif
    endfor
    if .hasCollision
        .rowColName$ = "OriginalRowLabel"
        Rename column (by number): 1, .rowColName$
    endif

    # FIX "?" COLUMN HEADERS -> "Column_N", AND N IS THE SOURCE COLUMN'S
    # NUMBER, NOT THE TABLE'S. AUTHOR RULING, 15 August 2026 (ruling 5,
    # doors 2 and 3).
    #
    # `To Table: "row"` has already put the manufactured label column in
    # position 1 by the time this runs, so numbering by table position gave
    #
    #     source column 1  ->  table position 2  ->  named "Column_2"
    #     source column 2  ->  table position 3  ->  named "Column_3"
    #
    # and no column was ever called "Column_1" at all. A user who asks for
    # "column 2 of my Matrix" reads the menu, picks Column_2, and is handed
    # column 1's data. There is no symptom: every value is a real value, from
    # a real column, of the right length, under a heading that is off by one.
    # Auditor's evidence, leg2_converted_mx.csv, and reproduced here on
    # 15 Aug 2026 through both of this procedure's callers.
    #
    # .insertedCols IS THE COLUMNS THE COERCION PUT IN FRONT of the source's
    # first, and it is 1 at every call site because `To Table: "row"` is the
    # only conversion that reaches here -- including the arm where the
    # collision guard above has renamed that column to "OriginalRowLabel",
    # which moves its NAME and not its position.
    #
    # WHY IT IS NOT A PARAMETER, WHERE @eml_nameUnlabelledColumns TAKES ONE.
    # That procedure is private to eml-output.praat and has two call sites,
    # both in the same file. This one is PUBLIC: @emlConvertForGraph emits
    # `@emlCleanConvertedTable: data` into recorded scripts, and those
    # scripts are on users' disks. Adding an argument would make every one of
    # them fail with an arity error to buy generality no caller wants. The
    # offset is stated as a named local instead, so the arithmetic is on the
    # page and a future coercion that inserts two columns changes one line.
    #
    # THE LOOP STARTS AFTER THE INSERTED BLOCK, which is a guard and not an
    # optimisation: position 1 has no source column to be numbered after, so
    # scanning it could only write "Column_0" or a duplicate of the real
    # column 1's name -- and a duplicate header is the S1 wrong-column read
    # this repair exists to remove.
    #
    # The empty header is matched as well as "?", so this composes with a
    # caller that has already normalised one -- the same reason the r1..rn
    # pass below tests for both, and the shape @eml_nameUnlabelledColumns
    # uses at the stats door.
    .insertedCols = 1
    for .iCol from .insertedCols + 1 to .nCols
        .colLabel$ = Get column label: .iCol
        if .colLabel$ = "?" or .colLabel$ = ""
            Rename column (by number): .iCol,
            ... "Column_" + string$ (.iCol - .insertedCols)
        endif
    endfor

    # FILL THE ROW-LABEL COLUMN WITH r1..rn -- THE ONE CONVENTION.
    #
    # Six doors coerce a Matrix or a TableOfReal into a Table, and on 15 Aug
    # 2026 three of them disagreed about this column: describe filled r1..rn,
    # @emlWrapperInit left it empty, and this one filled bare integers. A user
    # got a different `row` column depending on which door they came in.
    #
    # r1..rn wins on one property: a column of bare integers reads as DATA. It
    # is offered as a numeric variable in every picker, it will be correlated
    # against, and nothing about "1, 2, 3" says "these are the row names of an
    # object that never had any". The prefix costs one character and removes
    # the ambiguity entirely.
    #
    # The empty test is not redundant. This procedure is also called AFTER a
    # caller has already normalised -- @emlDescribeCoerceSelection fills first
    # and then calls here for the header repair, and @eml_auditLabelColumn
    # rewrites "?" to "" before this can run. Matching only "?" would leave
    # those rows blank, which is the third convention arriving by the back
    # door. v63 asserts r1..rn at each door separately, on purpose: three doors
    # agreeing on the wrong thing would satisfy a parity check, and that is
    # exactly how the two .std.resid arms disagreed for a week without a red
    # line anywhere.
    for .iRow from 1 to .nRows
        .cellVal$ = Get value: .iRow, .rowColName$
        if .cellVal$ = "?" or .cellVal$ = ""
            Set string value: .iRow, .rowColName$, "r" + string$ (.iRow)
        endif
    endfor
endproc
