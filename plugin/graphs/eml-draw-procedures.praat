# ============================================================================
# EML GRAPHS — DRAWING PROCEDURES
# ============================================================================
# Author: Ian Howell, Embodied Music Lab, www.embodiedmusiclab.com
# Development: Claude (Anthropic)
# Part of EML PraatGen GPL-3.0-or-later — Ian Howell, Embodied Music Lab
# Version: 1.26
# v1.26: COMMENTS ONLY — no executable line changed. The D124 wave falsified
#        this file's account of the annotation block; three statements fixed.
#        (1) @emlDisclose's contract said "@emlDrawAnnotationBlock does not
#        wrap: the box is as wide as its longest line" and "KEEP .short$ UNDER
#        ABOUT 50 CHARACTERS". The block wraps now — every entry is broken
#        through @emlWrapText against emlAnnotBlockWidthShare (default 0.55 of
#        the inner viewport), with a height guard that re-wraps wider, to at
#        most 0.72, only when the box would exceed emlAnnotBlockHeightShare
#        (0.95) of the frame. The character rule was never a width guarantee
#        even before that: annotSize scales WITH the viewport, so a
#        48-character line took 0.68 of the inner width at 6 x 4 inches and
#        0.88 at 3.6 x 3 — inside the old rule, over half the panel at both.
#        The contract now states the share, what the 20-line budget actually
#        counts, and why shorter is still better.
#        (2) The LINE BUDGET note claimed @emlDrawAnnotationBlock's contract
#        documents the 20-line maximum. It does not and never did — it points
#        back here. Rewritten to say what the 20 is: a cap on @emlDisclose's
#        own entries, not on annotBlockN (@emlDrawScatterPlot and
#        eml-graphs-form.praat both append outside it) and not on drawn rows,
#        which wrapping makes larger again.
#        (3) The @emlDiscloseBegin counting rule said the indent excludes
#        "the three mentions of it in comments"; there are eight, and the
#        figure moves whenever one of these comments is reworded, so the rule
#        no longer quotes it.
# v1.25: COMMENTS ONLY — no executable line changed. Eight stale statements
#        corrected: counts that disagreed with the list or the code under
#        them, and pointers to things that do not exist. Three came from the
#        7 Aug 2026 contradiction sweep
#        (audit/reviews/CONTRADICTION_SWEEP_2026-08-07.md, C10); the rest
#        from a file-wide sweep for the same class of error.
#        (1) "Contains all 14 drawing procedures" (v1.0 entry below): there
#        are 15. The count now carries the rule that derives it, under
#        Procedures, so the next reader does not have to trust it.
#        (2) The Procedures list itself was missing @emlDrawLMMForest, which
#        is how the 14 went unnoticed: the list agreed with it.
#        (3) "Real implementations for all 7 graph types" above the DRAWING
#        PROCEDURES section: two different counts of one thing in one header,
#        neither of them 15.
#        (4) "the MAIN EXECUTION section below": there is no such section in
#        this file or anywhere in the plugin. The dispatch it meant is the
#        DISPATCH (DRAW) block of eml-graphs-form.praat, now named.
#        (5) @emlDrawTimeSeries's header still described drawing modes B and
#        C (spaghetti strands by ID, mean overlay) and a CI band. The
#        procedure takes no .idCol$, no .showMean and no band columns — the
#        banner immediately under it has said "reverted, modes A + D only"
#        the whole time. The palette line was also pre-v1.24: point marks
#        now cycle 8 hues x 3 marker shapes, not 8 hues.
#        (6) @emlDrawHistogram's header called its second grouped mode
#        "side-by-side". The code at Step 9-10 draws FACETED vertically
#        stacked panels with shared axes; every other mention in the file
#        says faceted. Also: eml-output.praat added to Dependencies (the
#        spaghetti summary calls @emlReportHeader and four siblings) and
#        @emlDrawGroupedBoxPlot's "See the note above Step 3's equivalent"
#        repointed, that procedure having no numbered steps.
#
# v1.24: MARKER SHAPES for the four chart types that draw dots and lines.
#        v1.23 gave the AREA marks a second dimension (8 hues x 3 fill
#        patterns) and left the point marks where they were: a scatter, a
#        line chart, a spaghetti plot and a time series have no area to fill,
#        so all four went on cycling eight hues in silence above eight
#        groups. Each now draws through @emlDrawMarker and takes its shape
#        from emlSetColorPalette.marker[] -- circle, square, triangle, on the
#        same slot arithmetic, so the ceiling is 24 for both families -- and
#        each sets the legend's marker key so the key shows the shape and not
#        merely the hue. @emlDrawTimeSeries and @emlDrawTimeSeriesCI drew no
#        point markers at all before this and now place one at every plotted
#        vertex that lies on the panel (not clamped: a clamped marker would
#        claim an observation at a value nobody measured).
#        @emlDrawScatterPlot additionally stands its alpha-sprite path down
#        above eight groups -- the sprite set is circles only, so on macOS
#        and Windows, where the sprites actually render, the shape would
#        never have reached the page. Its B/W point colour moves from .fill$
#        to .lightLine$, because the widened grey ramp takes .fill$ to 0.94
#        and a 0.94 dot with no outline is not on the page at all.
#
# v1.23: The sub-group ceiling goes from 10 to 24. @emlSetColorPalette now
#        defines a style as (one of 8 hues) x (one of 3 fill patterns:
#        solid, diagonal hatch, dots), so 24 sub-groups can be drawn
#        distinguishably where 10 could not — the old ten included two
#        literal duplicates (D127) and refused eight styles that were
#        genuinely available. @emlDrawGroupedViolin and @emlDrawGroupedBoxPlot
#        pass the pattern through to the primitives, the legend carries it,
#        and the over-cap disclosure names the 8 x 3 space rather than a bare
#        count. Set on the author's ruling that the boundary be "in excess of
#        what we think is reasonable" — 24 sub-violins are not readable on a
#        default 6-inch figure and are perfectly readable on a wide one, and
#        that is the user's call to make.
#
# v1.22: Three more silences, all found by the v1.21 disclosure work — a
#        procedure that knew it had dropped something and did not say so.
#        Same ruling, same three channels, same helpers.
#        (1) THE OVER-CAP SCATTER. @emlDrawScatterPlot's grouped path writes
#        a Pearson line, a Spearman line and a fitted-line formula PER GROUP
#        straight into annotBlockN, bypassing @emlDisclose and its 20-line
#        budget. At eight groups that is 24 lines: measured 7 Aug 2026, the
#        box ran from the top of the panel, across the x-axis and off the
#        bottom edge of the figure, and the dropped-row disclosure that
#        followed was refused by the spent budget and never appeared. The
#        lines are now buffered and committed ALL OR NONE — a box holding six
#        of eight groups is indistinguishable from a complete one — and when
#        they do not fit, every one of them is printed to the Info window and
#        the figure says so in one line.
#        (2) ZERO IS NOT "NO DATA". @emlMeasureBarData (v3.23, in
#        eml-graph-procedures.praat) seeded emlBarData_mean[] and
#        emlBarData_error[] to 0 rather than undefined, so this file's
#        "<> undefined" guards for the bar and the whisker could never fire:
#        .nSkippedBars and .nSkippedErrors were dead code and both
#        disclosures reading them were unreachable. A group with no usable
#        observation drew as a bar of height zero — the same mark a measured
#        zero draws — and a whisker whose error was undefined simply did not
#        appear. Fixed at the root; both guards now fire, the omitted bars
#        are NAMED, and the v1.21 stopgap line "N group(s) shown at zero" is
#        gone with the behaviour it described.
#        (3) THE ELEVENTH SUB-GROUP. @emlDrawGroupedViolin and
#        @emlDrawGroupedBoxPlot drop sub-groups past the tenth because
#        @emlSetColorPalette declares ten fill/line pairs over eight hues.
#        THE CAP IS LEGITIMATE AND IS NOT RAISED. It was silent, and the
#        legend still listed sub-groups that had no violin or box anywhere on
#        the figure. Now disclosed by name and row count, the legend is
#        capped to what was drawn, and the slot geometry divides by the drawn
#        count so the remaining violins stay centred.
#        Verified by validate/v29_figure_disclosure.R.
# v1.21: Figure disclosure unified across the ten Table-consuming draw
#        procedures, to the author's ruling of 7 Aug 2026 — "Let's draw the
#        image as the image unless someone asks to annotate."
#        (1) Nothing in this file writes to emlSubtitle$ any more.
#        @emlDrawTimeSeries appended " | Mean per time point" and
#        @emlDrawBarChart appended an error-bar/truncation/omitted-bars
#        caption; both saved and restored the global, so it was never
#        permanently corrupted, but the DRAWN figure carried the user's own
#        subtitle with a machine tail after " | ", and drew it whether or not
#        Annotate was ticked. emlSubtitle$ is the user's field: the graphs
#        form asks for it and persists it to config.
#        (2) All ten disclose dropped rows, in one wording and one counter
#        idiom taken from @emlDrawViolinPlot and @emlDrawBoxPlot, which were
#        the only two that did. Silent before: histogram, bar, scatter,
#        grouped violin, grouped box, spaghetti, time series; time series
#        with CI had the count but in its own words and indentation.
#        (3) The four procedures that plot a MEAN rather than raw values now
#        all say so — @emlDrawTimeSeries already did, @emlDrawTimeSeriesCI,
#        @emlDrawBarChart and the line chart (graph type 5 with CI off, which
#        IS @emlDrawTimeSeries) did not.
#        (4) New @emlDiscloseBegin / @emlDisclose / @emlDiscloseEnd carry all
#        of the above: Info window always, figure only when the user ticked
#        Annotate, through the existing annotation block. See the block
#        comment on those procedures for why the gate could not simply be
#        left to @emlDrawAnnotationBlock.
#        Verified by validate/v29_figure_disclosure.R.
# v1.20: @emlDrawLMMForest brought into line with the drawing standards.
#        (1) Rule 1: the bare `Marks bottom: 5` is replaced by
#        @emlDrawAlignedMarksBottom with theme-derived tick targets, so the
#        12%-buffered coefficient axis gets nice-number labels instead of
#        arbitrary quarter-range values. (2) Rule 2: the procedure now opens
#        with the theme prologue (@emlSetAdaptiveTheme / @emlSetColorPalette)
#        that the other 14 draw procedures already used — it was the only one
#        without it, so its margins, and therefore its box, ticks and labels,
#        previously depended on whatever ambient font size the Picture window
#        happened to hold. (3) Because the LMM tool reaches this procedure
#        outside the graphs form, the display-toggle globals and colorMode$
#        are seeded through a variableExists guard — without it the new marks
#        call aborts with "Unknown variable" on the shipped path. (4) Rule 34:
#        line widths, marker size, tick colour, text colour and the series
#        colour now come from the theme and palette rather than hardcoded
#        constants and bare Grey/Black; the four inlined replace$ calls are
#        replaced by @emlSanitizeLabel. Deliberately deferred: adopting
#        @emlDrawTitle, which would require converting the figure from the
#        outer-viewport layout model to the theme's inner-viewport model.
#        No arguments or return variables change.
# v1.19: Robustness and disclosure fixes. (1) @emlDrawHistogram ungrouped
#        path no longer aborts on clean single-column data — the group loop
#        is driven by .hasGroups instead of the always-1 .nGroups, and the
#        dead else branch is removed. (2) @emlDrawScatterPlot (ungrouped and
#        grouped) now draws the same estimator it reports, labels the drawn
#        line, and discloses the estimator unconditionally instead of gating
#        the disclosure on scatterAnalysisType. (3) @emlDrawBarChart guards
#        every undefined mean/error before it reaches a drawing command — an
#        unusable bar is skipped and recorded rather than aborting the
#        figure — discloses the error-bar meaning (SE / SD / custom column)
#        in the caption and Info window, and marks error bars truncated at
#        the axis limits with outward arrowheads instead of clipping them
#        silently. (4) Axis seeding in @emlDrawTimeSeries and
#        @emlDrawSpaghettiPlot no longer takes row 1 on faith — ranges are
#        folded from the first valid observation, with a 0..1 fallback and
#        an Info-window note when nothing is usable. (5) Guard sweep over
#        the aborting draw procedures, using @emlDrawGroupedViolin as the
#        reference: @emlDrawTimeSeries, @emlDrawSpaghettiPlot,
#        @emlDrawTimeSeriesCI (missing TIME cells no longer create phantom
#        time points), @emlDrawViolinPlot and @emlDrawBoxPlot (undefined
#        values filtered at accumulation so they never reach @emlPercentile's
#        sort#, empty groups skipped, unit-axis fallback). Dropped rows and
#        skipped groups are reported in the Info window.
# v1.18: Graph correctness fixes. (1) Grouped scatter no longer prints a
#        false "R² = 0.000" for Spearman/Theil-Sen fits — R² is emitted only
#        for the OLS/Pearson line (guarded on annotCorrType$, mirroring the
#        ungrouped path). (2) Bar chart y-range routed through
#        @emlComputeAxisRange with the tracked data min, and bar baseline
#        decoupled from yMin (bars emanate from 0) so all-negative means
#        render. (3) Scatter axes use an adaptive @emlComputeNiceStep roundTo
#        instead of a hardcoded 1, so fractional data is not over-ranged.
# v1.17: Per-group scatter correlation output replaced with shared
#        reporter (@emlReportCorrelationAnalysis) for rich Info window output
#        including R-squared, effect size labels, and Why commentary.
# Date: 6 April 2026
#
# v1.16: Group sort unification — replaced all inline group discovery
#         with @emlCountGroups calls: @emlDrawViolinPlot,
#         @emlDrawBoxPlot, @emlDrawGroupedViolin, @emlDrawGroupedBoxPlot,
#         @emlDrawSpaghettiPlot (conditions and subjects). Legend labels
#         sanitized in @emlDrawTimeSeries, @emlDrawTimeSeriesCI, and
#         @emlDrawSpaghettiPlot (underscore→subscript fix). All draw
#         procedures now use single source for group ordering.
#
# v1.15: Bug #3 — 1-group faceted histogram forced through ungrouped
#        path (hasGroups=0, displayMode=1) to prevent viewport mismatch.
#        Bug #11 — semitone auto-range minimum span enforcement now uses
#        direct 6-st rounding instead of re-calling @emlComputeAxisRange.
#        Prevents overshoot to ~30 st for constant-pitch input.
#
# v1.12: @emlDrawTimeSeriesCI: CI critical value changed from hardcoded
#         1.96 (normal approximation) to invStudentQ(annotAlpha/2, n-1)
#         for correct t-distribution intervals at any sample size and
#         confidence level. Reads global annotAlpha (default 0.05 = 95%
#         CI). At n=5 and α=0.05, gives t=2.776 vs the old z=1.96.
# v1.11: Faceted histogram group labels moved from right margin to left
#         margin (Text left:, rotated 90°). Truncation with binary search
#         when label physical width exceeds 85% of panel height. Right
#         margin reverted to standard (no longer widened for labels).
# v1.10: @emlDrawBarChart refactored to pure renderer — all data extraction
#         (unique groups, aggregation, SE/SD/custom error computation) removed.
#         Now reads pre-computed emlBarData_* globals from @emlMeasureBarData
#         (eml-graph-procedures.praat). Signature unchanged for dispatch
#         uniformity.
# v1.9: @emlDrawBarChart signature change — .errorCol$ replaced by
#         .errorMode (0=none, 1=SE, 2=SD, 3=custom) + .errorCol$ (for
#         custom only). SE and SD computed internally from value column
#         per group using single-pass variance (sum of squares). Error
#         bar drawing condition uses .errorMode > 0 instead of .hasError.
# v1.8: Per-axis visibility — all 8 direct axis label draws (Text left/
#        Text bottom) gated by emlShowAxisNameY/emlShowAxisNameX globals.
#        Axis label sanitization removed from all 6 draw procedures —
#        auto-generated labels sanitized at source (@emlCapitalizeLabel),
#        user-typed labels pass through raw to support Praat formatting
#        codes. Title sanitization preserved. Group label sanitization
#        preserved. Scatter alpha sprites always on when available —
#        removed group-column condition gate so ungrouped scatters show
#        density transparency.
# v1.6: Faceted histogram x-axis ticks — replaced Marks bottom: with
#        @emlDrawAlignedMarksBottom for nice-number alignment consistent
#        with gridlines and all other axis tick drawing.
# v1.5: All 12 hardcoded "Helvetica" in Text special: calls replaced
#        with emlFont$ global variable (set by main script font dropdown).
# v1.4: Debug lines removed. All 7 legend callers updated to
#        @emlPlaceElements (adaptive corner selection). Font state
#        fixes: bodySize before all Select inner viewport calls.
#        Faceted histogram restructured: symmetric right margin,
#        gridlines inside branch, group labels outside box.
# v1.3: All Draw inner box calls replaced with @emlDrawInnerBoxIf (font
#        state assertion + boolean toggle). Gridline dispatch updated:
#        continuous types now 4-way (Both/Horizontal/Vertical/Off),
#        categorical types now 2-way (Horizontal/Off).
#
# v1.1: All 6 categorical label sections now use @emlFitCategoricalLabels
#        for space-aware rotation + truncation. Faceted histogram uses
#        per-facet tick count from panel height instead of full canvas.
# v1.0: Extracted from eml-graphs.praat v2.28 to enable shared use by
#        both the graph UI (eml-graphs.praat) and stats wrapper scripts.
#        Contains the drawing procedures and no standalone executable code.
#        The count stated here was 14 and was never updated when
#        @emlDrawLMMForest was added; it is 15 now. See Procedures
#        below for the live count and the rule that derives it.
#
# Dependencies:
#   eml-graph-procedures.praat   — theme, palette, axes, violin/box primitives
#   eml-annotation-procedures.praat — bridge, annotation rendering
#   eml-output.praat             — @emlReportHeader / @emlReportSection /
#                                  @emlReportLine / @emlReportLineString /
#                                  @emlReportBlank / @emlReportFooter /
#                                  @emlUnderscoreToSpace (spaghetti summary)
#   eml-core-utilities.praat     — vector utilities; reached indirectly, via
#                                  @emlSpearmanCorrelation -> @emlRankVector
#   eml-core-descriptive.praat   — descriptive stats; reached indirectly, via
#                                  @emlDrawViolin / @emlDrawBox -> @emlQuartiles
#   eml-extract.praat            — group extraction
#   eml-inferential.praat        — statistical tests
#
# Procedures: 15 of them. THE COUNTING RULE, so this number can be checked
# rather than believed:
#     grep -c "^procedure emlDraw" plugin/graphs/eml-draw-procedures.praat
# A drawing procedure is defined at column 1 and named emlDraw*; every one of
# them is a whole-figure entry point, and this file holds no emlDraw* helpers
# (the primitives — @emlDrawViolin, @emlDrawBox, @emlDrawMarker, @emlDrawAxes
# and the rest — live in eml-graph-procedures.praat and are NOT counted here).
# The 15 split three ways by what they consume:
#   * 10 take a Table object id plus column names (@emlDrawTimeSeries through
#     @emlDrawGroupedBoxPlot below). These are exactly the ten that disclose:
#     grep -c "^    @emlDiscloseBegin:" on this file returns 10. The leading
#     four-space indent is what makes that a count of CALL SITES rather than
#     of mentions: every mention in a comment block begins with "#", or with
#     spaces then "#", so none of them matches. (The bare pattern without the
#     indent does NOT return 10, and the figure it does return moves whenever
#     one of these comments is reworded — do not quote it here.)
#   * 4 take another Praat object — Pitch, Sound, Spectrum, Ltas.
#   * 1, @emlDrawLMMForest, takes no argument at all and reads emlLMM.* /
#     emlWaldCI.* globals.
# Fourteen of the 15 are reached from the DISPATCH (DRAW) block of
# eml-graphs-form.praat; @emlDrawLMMForest is called by eml-lmm.praat.
#
# The 15, in the order they are defined below:
#   @emlDrawF0Contour       — F0 contour from Pitch object
#   @emlDrawWaveform        — waveform from Sound object
#   @emlDrawSpectrum        — spectrum from Spectrum object
#   @emlDrawLTAS            — long-term average spectrum
#   @emlDrawTimeSeries      — time series (modes A + D)
#   @emlDrawTimeSeriesCI    — time series with confidence interval
#   @emlDrawSpaghettiPlot   — individual subject traces (categorical x)
#   @emlDrawBarChart        — grouped bar chart with error bars
#   @emlDrawViolinPlot      — violin plot
#   @emlDrawScatterPlot     — scatter plot with regression
#   @emlDrawBoxPlot         — box plot (Tukey whiskers)
#   @emlDrawHistogram       — histogram (overlap or faceted)
#   @emlDrawGroupedViolin   — two-factor violin (category × sub-group)
#   @emlDrawGroupedBoxPlot  — two-factor box plot
#   @emlDrawLMMForest       — LMM fixed-effect coefficient forest plot
#                             (no arguments; not on the graphs-form dispatch)
#
# Disclosure helpers (v1.21):
#   @emlDiscloseBegin       — open a disclosure batch for one figure
#   @emlDisclose            — one disclosure, routed to its channels
#   @emlDiscloseEnd         — render the batch into the annotation block
# ============================================================================

# ============================================================================
# FIGURE DISCLOSURE — @emlDiscloseBegin / @emlDisclose / @emlDiscloseEnd
# ============================================================================
# v1.21, 7 Aug 2026. The author's ruling: "Let's draw the image as the image
# unless someone asks to annotate." Three channels, one rule each.
#
#   Info window   ALWAYS. Every disclosure goes here unconditionally, whatever
#                 the caller is and whatever the user ticked. The Info window
#                 is where a reader goes to find out what a figure did, and it
#                 costs the figure nothing.
#
#   The figure    ONLY when the user ticked Annotate. Rendered through the
#                 EXISTING annotation block — annotBlockN / annotBlockLabel$[]
#                 / annotBlockDraw$[], drawn by @emlDrawAnnotationBlock into a
#                 corner chosen by @emlPlaceElements. No new text slot and no
#                 new class of on-figure element were invented for this.
#
#   emlSubtitle$  NEVER. It is the USER'S field: the graphs form asks for it
#                 ("Subtitle") and persists it to config. @emlDrawTimeSeries
#                 and @emlDrawBarChart used to append a machine caption to it
#                 after " | " — saved and restored, so the global survived,
#                 but the DRAWN figure carried the user's own words with a
#                 tail bolted on that the user never wrote and could not
#                 remove, whether or not Annotate was ticked. Both are gone.
#                 Nothing in this file writes to emlSubtitle$.
#
# WHY THE GATE LIVES HERE AND NOT IN @emlDrawAnnotationBlock
# ----------------------------------------------------------
# The block is NOT already gated on `annotate`. Verified 7 Aug 2026 by drawing
# a scatter plot with annotate = 0 and scatterShowFormula = 1: the OLS formula
# box rendered. @emlDrawScatterPlot's two call sites under the comment
# "Formula on graph if requested (independent of annotate)" populate the block
# from scatterShowFormula alone, and the render site is guarded only by
# `if annotBlockN > 0`. So a non-empty block does not mean the user asked for
# annotations, and the ruling has to be enforced at the point where a line is
# ADDED. That is what @emlDisclose does. The pre-existing formula and
# correlation lines keep their own behaviour; only disclosures are gated.
#
# `annotate` is a graphs-form global. Standalone callers — the stats wrappers,
# the LMM tool, harness/stress_cases — never set it, so it is read through
# variableExists: undefined means "the user ticked nothing", which is the safe
# reading of a ruling whose default is a clean figure.
#
# LINE BUDGET
# -----------
# @emlDisclose stops adding at 20 entries. The Info window is never capped.
#
# 20 is a budget on what one figure may TRY to say. It is not a ceiling on
# annotBlockN and it is not a promise about the box:
#   * Other code writes into the block directly. @emlDrawScatterPlot's stats
#     lines and eml-graphs-form.praat's POST-DISPATCH omnibus line both append
#     to annotBlockN without going through @emlDisclose, so neither is counted
#     against the 20.
#   * Since D124 (8 Aug 2026) @emlDrawAnnotationBlock WRAPS each entry to a
#     share of the plotting frame, so the number of rows RENDERED is larger
#     again — one long entry can render as four. Height, not width, is now
#     what a wordy disclosure costs. See the contract on @emlDisclose below.
# The glossary entry for annotBlockN in eml-annotation-procedures.praat is the
# other half of this; this comment used to claim that
# @emlDrawAnnotationBlock's contract documented the 20 itself, which it never
# did — it points back here.
#
# USAGE inside a draw procedure:
#     @emlDiscloseBegin: "Bar chart"
#     ... draw the data ...
#     @emlDisclose: "3 row(s) skipped (missing or non-numeric value).", ""
#     @emlDiscloseEnd: xMin, xMax, yMin, yMax, qTL, qTR, qBL, qBR, legendCorner$
#
# .legendCorner$ is the corner this figure's legend went to, or "" if it drew
# none. The disclosure box must not land there, and it must not land on the
# graphs form's own omnibus box either — see @emlDiscloseEnd.
#
# @emlDrawScatterPlot is the one exception: it already owns an annotation
# block and already renders it, so it calls @emlDiscloseBegin/@emlDisclose and
# lets its own existing render site carry the lines. It does not call
# @emlDiscloseEnd — doing so would draw a second box.
# ============================================================================

# ----------------------------------------------------------------------------
# @emlDiscloseBegin: .chart$
# Opens a disclosure batch. .chart$ is the figure's name in prose; it prefixes
# every Info-window line so a transcript with several figures in it says which
# figure each note came from.
#
# Outputs (globals, deliberately — @emlDisclose and @emlDiscloseEnd are
# separate procedures and Praat has no other way to share state between them):
#   emlDiscloseChart$    — the name passed in
#   emlDiscloseBase      — annotBlockN on entry, restored by @emlDiscloseEnd
#   emlDiscloseOnFigure  — 1 if the user ticked Annotate, else 0
#   emlDiscloseInfoN     — lines sent to the Info window this figure
#   emlDiscloseFigN      — lines placed on the figure this figure
#   emlDiscloseFigLabel$[1..emlDiscloseFigN] — their text
#
# The last three are the disclosure LEDGER. The Info channel is observable
# from the transcript; the figure channel is not, short of decoding a PNG, so
# the ledger is how a caller — or validate/v29_figure_disclosure.R — finds out
# what actually reached the figure. It survives @emlDiscloseEnd, which hands
# annotBlockN back to its entry value.
# ----------------------------------------------------------------------------
procedure emlDiscloseBegin: .chart$
    emlDiscloseChart$ = .chart$
    if variableExists ("annotBlockN") = 0
        annotBlockN = 0
    endif
    emlDiscloseBase = annotBlockN
    emlDiscloseOnFigure = 0
    if variableExists ("annotate")
        if annotate = 1
            emlDiscloseOnFigure = 1
        endif
    endif
    emlDiscloseInfoN = 0
    emlDiscloseFigN = 0
endproc

# ----------------------------------------------------------------------------
# @emlDisclose: .short$, .advice$
# One disclosure.
#   .short$   the fact. Goes to BOTH channels, so it has to fit in a corner
#             box.
#
#             WHAT THE BOX GUARANTEES (D124, 8 Aug 2026).
#             @emlDrawAnnotationBlock WRAPS. Every entry is broken through
#             @emlWrapText against a budget taken from the PLOTTING FRAME —
#             emlAnnotBlockWidthShare, default 0.55 of the inner viewport,
#             less the box's own padding and its corner inset — so however
#             long .short$ is, the box no longer reaches across the panel or
#             off the canvas. A height guard re-wraps wider, to at most 0.72,
#             and only when the box would otherwise stand taller than
#             emlAnnotBlockHeightShare (default 0.95) of the frame. Both
#             globals are read through variableExists, so a caller that wants
#             a narrower or a taller box may set either before it draws.
#
#             WHAT IT COSTS INSTEAD IS HEIGHT. The 20 above is 20 CALLER
#             ENTRIES, not 20 drawn rows: a long .short$ spends one of the 20
#             and can render as four rows. So shorter is still better — not
#             because a long line overhangs any more, but because a corner box
#             half the frame wide and a third of it tall covers the data it is
#             about. @emlDrawScatterPlot's formula line, at 39 characters, is
#             the calibration for a line that reads as a caption.
#
#             THE CHARACTER RULE IS GONE, AND WAS NEVER A GUARANTEE. This
#             contract used to say "KEEP .short$ UNDER ABOUT 50 CHARACTERS".
#             It could not have prevented D124: annotSize scales WITH the
#             viewport, so a character is very nearly a fixed FRACTION of the
#             panel at every figure size, and a fraction is not what a
#             character count controls. Measured 8 Aug 2026 at annotSize, a
#             48-character line took 0.68 of the inner width at 6 x 4 inches
#             and 0.88 at 3.6 x 3 — inside the old rule, over half the panel
#             at both sizes. The observation the rule came from is still a
#             real defect and is the one the wrap fixes: 7 Aug 2026, a
#             71-character mean note on a 6-inch time series, placed in the
#             correct corner, with the rising line running underneath it.
#             The full measurement table is in @emlDrawAnnotationBlock's own
#             header in eml-annotation-procedures.praat.
#   .advice$  the counts and what to do about it — including the sentence
#             @emlDrawTimeSeries already wrote, which names the graph type
#             that would show what this one cannot. Info window ONLY: it is a
#             paragraph, not a caption. Pass "" when there is nothing to add.
# ----------------------------------------------------------------------------
procedure emlDisclose: .short$, .advice$
    .infoLine$ = emlDiscloseChart$ + ": " + .short$
    if .advice$ <> ""
        .infoLine$ = .infoLine$ + " " + .advice$
    endif
    appendInfoLine: .infoLine$
    emlDiscloseInfoN = emlDiscloseInfoN + 1
    if emlDiscloseOnFigure = 1
        if annotBlockN < 20
            annotBlockN = annotBlockN + 1
            ; Label is measured, Draw is rendered.
            ;
            ; Draw goes through @emlSanitizeLabel because Praat's text
            ; renderer reads "%", "#" and "^" as markup, not as characters.
            ; Observed 7 Aug 2026: @emlDrawTimeSeriesCI's "band shows the
            ; 95% CI." rendered on the figure as "band shows the 95 CI." —
            ; the per-cent sign silently became an italic toggle and
            ; disappeared. Any disclosure that quotes a confidence level, or
            ; a user's column name, can carry one of those three.
            ;
            ; Label stays raw, which is what @emlDrawAnnotationBlock's own
            ; comment asks for: it measures Label because the backslash
            ; escapes in Draw would be counted as characters and the box
            ; would come out wider than the text it holds.
            annotBlockLabel$[annotBlockN] = .short$
            @emlSanitizeLabel: .short$
            annotBlockDraw$[annotBlockN] = emlSanitizeLabel.result$
            emlDiscloseFigN = emlDiscloseFigN + 1
            emlDiscloseFigLabel$[emlDiscloseFigN] = .short$
        endif
    endif
endproc

# ----------------------------------------------------------------------------
# @emlDiscloseEnd: .xMin, .xMax, .yMin, .yMax, .qTL, .qTR, .qBL, .qBR,
#                  .legendCorner$
# Renders whatever @emlDisclose put on the figure, then hands the annotation
# block back exactly as it was found.
#
# THE RESTORE. eml-graphs-form.praat's POST-DISPATCH block appends its own
# omnibus line to annotBlockN AFTER the draw procedure returns and renders the
# block itself; lines left behind here would be drawn a second time, in a
# second box.
#
# THE CORNER. Two boxes can be on an annotated categorical figure at once —
# this one, and the form's omnibus box. The form's corner is not negotiable
# and not visible to @emlPlaceElements: eml-graphs-form.praat sends it to
# "bottom-right" when there are brackets and "top-right" when there are not.
# Drawn 7 Aug 2026 without this guard, an annotated violin plot with two
# significance brackets put BOTH boxes in the bottom-right corner and the
# Kruskal-Wallis line was painted over the top of "6 row(s) skip…".
#
# Rather than second-guess @emlPlaceElements, the corners that are already
# spoken for — the legend's, and the form's — are declared BUSY by adding a
# large occupancy weight to their quadrants. That is the currency
# @emlPlaceElements already reasons in, so the library keeps making the
# choice and this procedure only tells it what is in the way.
#
# The form's rule is duplicated here, which is a coupling worth naming: the
# right long-term fix is for the form to route its omnibus line through this
# same block instead of rendering a second one, and that is a change in
# eml-graphs-form.praat.
#
# Call this while the panel viewport and the data's Axes: are still current —
# the block is positioned in world coordinates.
# ----------------------------------------------------------------------------
procedure emlDiscloseEnd: .xMin, .xMax, .yMin, .yMax, .qTL, .qTR, .qBL, .qBR, .legendCorner$
    if annotBlockN > emlDiscloseBase
        # Occupancy weight big enough to outrank any real quadrant count.
        # A quadrant holds at most one point per table row, and Praat tables
        # in this plugin are not millions of rows.
        .busy = 1000000

        # (a) The legend, if this figure drew one.
        if .legendCorner$ = "top-left"
            .qTL = .qTL + .busy
        elsif .legendCorner$ = "top-right"
            .qTR = .qTR + .busy
        elsif .legendCorner$ = "bottom-left"
            .qBL = .qBL + .busy
        elsif .legendCorner$ = "bottom-right"
            .qBR = .qBR + .busy
        endif

        # (b) The graphs form's omnibus box, if the form is going to draw
        # one after this procedure returns. Mirrors the POST-DISPATCH
        # condition in eml-graphs-form.praat: it renders only when Annotate
        # is on AND (there are brackets, OR there is an omnibus line and no
        # comparison-matrix panel); the corner is bottom-right with brackets
        # and top-right without. Every global is read through
        # variableExists — a standalone caller sets none of them.
        .fBrackets = 0
        .fText = 0
        .fMatrix = 0
        .fAnnotate = 0
        if variableExists ("annotate")
            .fAnnotate = annotate
        endif
        if variableExists ("annotBracketN")
            .fBrackets = annotBracketN
        endif
        if variableExists ("annotTextN")
            .fText = annotTextN
        endif
        if variableExists ("annotMatrixN")
            .fMatrix = annotMatrixN
        endif
        if .fAnnotate = 1
            if .fBrackets > 0
                .qBR = .qBR + .busy
            elsif .fText > 0
                if .fMatrix = 0
                    .qTR = .qTR + .busy
                endif
            endif
        endif

        @emlPlaceElements: .qTL, .qTR, .qBL, .qBR, (.xMin + .xMax) / 2, 1
        @emlDrawAnnotationBlock: emlPlaceElements.corner1$,
        ... .xMin, .xMax, .yMin, .yMax, emlSetAdaptiveTheme.annotSize
        annotBlockN = emlDiscloseBase
    endif
endproc

# ============================================================================
# DRAWING PROCEDURES
# ============================================================================
# The 15 drawing procedures themselves, counted by the rule stated under
# Procedures at the top of this file. Fourteen of them are reached from the
# DISPATCH (DRAW) block of eml-graphs-form.praat, whose 13 graph_type branches
# cover all fourteen — branch 5 chooses between @emlDrawTimeSeries and
# @emlDrawTimeSeriesCI — and each signature here matches its call there.
# @emlDrawLMMForest is the fifteenth: it is not on that dispatch, takes no
# arguments, and is called from plugin/scripts/eml-lmm.praat.
# ============================================================================

# ----------------------------------------------------------------------------
# @emlDrawF0Contour
# Draws a publication-quality F0 contour from a Pitch object.
# Source: v1.0 (17 Feb 2026), adapted for plugin dispatch signature.
# v1.1: Y-axis unit option (Hz or semitones re 440 Hz). Unit-branched
#        queries, auto-range, and draw command.
# ----------------------------------------------------------------------------
# Requires: @emlInitDrawingDefaults (or manual global initialization).
# Reads globals: emlPanelOriginX, emlPanelOriginY (via @emlSetAdaptiveTheme).
# ============================================================================
# @emlDrawColumnIsClean: .tableId, .colName$
# ============================================================================
# Can this column be read with the fast path? Returns .clean, 1 or 0.
#
# THIS EXISTS SO THE FIGURE AND THE ANALYSIS EXCLUDE THE SAME ROWS.
#
# Until 11 August 2026 every draw procedure's row filter called
# `number (Get value: ...)` -- Praat's own numericiser. That is the LENIENT
# test D96 removed from the stats path for being insufficient, and the two
# layers therefore disagreed about which rows were usable. Measured, on a
# fixture with one awkward cell per row
# (harness/disclosure/probe_exclusion_parity.praat):
#
#     cell '1,5'   stats: dropped      figure: plotted as 1
#     cell '30%'   stats: dropped      figure: plotted as 0.3
#
#     @eml_getGroupData group A   ->  n=2, excluded=5
#     @emlDrawViolinPlot           ->  four points, "3 row(s) skipped"
#
# So the omnibus line the form paints onto the figure described a different
# data set from the figure, and the disclosure line -- this plugin's own
# promise that what was dropped is stated -- was true of the figure and
# false of the analysis printed beside it.
#
# D96's argument was about a mean. It applies unchanged to a point on a page:
# a European decimal comma silently becoming a different number is not more
# defensible plotted than averaged. So the draw layer now reads cells with
# @eml_readCell, the same reader @emlExtractColumn uses.
#
# WHY A COLUMN-LEVEL TEST AND NOT JUST @eml_readCell EVERYWHERE.
# @eml_readCell's fast path is a plain `Get value:`, which is only safe on a
# column already proven strictly numeric with no empty cells -- exactly the
# gate @emlExtractColumn applies before its own row loop. Asking once per
# column means a clean column costs one extra test for the whole figure, and
# only a column that actually contains something ambiguous pays for per-cell
# classification. @eml_strictNumericColumn copies the table to probe the
# numericiser, so calling it per row would be indefensible; calling it once
# is what the stats path already does.
#
# THE GRAPHS LAYER DEPENDING ON THE STATS LAYER IS NOT NEW. @emlDrawViolinPlot
# already calls @emlCountGroups from plugin/stats/eml-extract.praat, which is
# why harness/stress_cases/_prelude.praat loads the stats files to render a
# figure. See §9 of audit/GRAPHING_PUSH_REMAINING.md for the direction that
# IS worth questioning.
# ============================================================================
procedure emlDrawColumnIsClean: .tableId, .colName$
    @eml_strictNumericColumn: .tableId, .colName$
    .clean = 0
    if eml_strictNumericColumn.strict = 1
        if eml_strictNumericColumn.unreadable = 0
            .clean = 1
        endif
    endif
    # Leave the caller's table selected, for the reason spelled out in
    # @eml_readCell: @eml_strictNumericColumn copies the table and
    # removeObject:s the copy, and removeObject: leaves NOTHING selected.
    selectObject: .tableId
endproc


procedure emlDrawF0Contour: .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .tMin, .tMax, .fMin, .fMax, .yUnit

    # Step 1: Set up theme and palette
    @emlSetAdaptiveTheme: .vpW, .vpH
    @emlSetColorPalette: .colorMode$

    # Determine unit string for queries
    if .yUnit = 2
        .unitStr$ = "semitones re 440 Hz"
    else
        .unitStr$ = "Hertz"
    endif

    # Step 2: Compute time range (both 0 = auto)
    selectObject: .objectId
    .startTime = Get start time
    .endTime = Get end time
    if .tMin = 0 and .tMax = 0
        .timeMin = .startTime
        .timeMax = .endTime
    else
        .timeMin = .tMin
        .timeMax = .tMax
        # Clamp to object domain
        if .timeMin >= .endTime or .timeMax <= .startTime
            appendInfoLine: "WARNING: Time range (",
            ... fixed$ (.timeMin, 3), " – ", fixed$ (.timeMax, 3),
            ... " s) outside Pitch domain (",
            ... fixed$ (.startTime, 3), " – ", fixed$ (.endTime, 3),
            ... " s). Using full domain."
            .timeMin = .startTime
            .timeMax = .endTime
        else
            if .timeMin < .startTime
                .timeMin = .startTime
            endif
            if .timeMax > .endTime
                .timeMax = .endTime
            endif
        endif
    endif

    # Step 3: Compute frequency/semitone range (both 0 = auto)
    selectObject: .objectId
    .pitchMin = Get minimum: 0, 0, .unitStr$, "parabolic"
    .pitchMax = Get maximum: 0, 0, .unitStr$, "parabolic"

    if .pitchMin = undefined or .pitchMax = undefined
        if .yUnit = 2
            .autoFreqMin = -36
            .autoFreqMax = 6
        else
            .autoFreqMin = 75
            .autoFreqMax = 500
        endif
    else
        # The axis follows the data. There is no minimum span: a sustained
        # note held within two hertz should read as a flat line on a two-hertz
        # axis, not be hidden inside a fifty-hertz window that makes it look
        # steady when the point is how steady it is. Any extra room a figure
        # needs is a property of what is drawn on it, not of the unit, and is
        # supplied by @emlComputeAnnotationHeadroom at the annotation stage.
        @emlComputeNiceStep: .pitchMax - (.pitchMin), emlSetAdaptiveTheme.targetTicksY
        .axisRoundTo = emlComputeNiceStep.step
        @emlComputeAxisRange: .pitchMin, .pitchMax, .axisRoundTo, 0
        .autoFreqMin = emlComputeAxisRange.axisMin
        .autoFreqMax = emlComputeAxisRange.axisMax
    endif

    if .fMin = 0 and .fMax = 0
        .freqMin = .autoFreqMin
        .freqMax = .autoFreqMax
    else
        .freqMin = .fMin
        .freqMax = .fMax
    endif

    # Step 4: Set viewport and axes
    @emlSetPanelViewport
    Axes: .timeMin, .timeMax, .freqMin, .freqMax

    # Step 5: Draw gridlines (if requested)
    # gridMode: 1=Both, 2=Horizontal only, 3=Vertical only, 4=Off
    if .gridMode = 1
        @emlDrawGridlines: .timeMin, .timeMax, .freqMin, .freqMax, emlSetAdaptiveTheme.targetTicksX, emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks
    elsif .gridMode = 2
        @emlDrawHorizontalGridlines: .timeMin, .timeMax, .freqMin, .freqMax, emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks
    elsif .gridMode = 3
        @emlDrawVerticalGridlines: .timeMin, .timeMax, .freqMin, .freqMax, emlSetAdaptiveTheme.targetTicksX, emlSetAdaptiveTheme.useMinorTicks
    endif

    # Step 6: Draw the F0 contour
    selectObject: .objectId
    Colour: emlSetColorPalette.line$[1]
    Line width: emlSetAdaptiveTheme.dataLineWidth
    if .yUnit = 2
        Draw semitones (re 440 Hz): .timeMin, .timeMax, .freqMin, .freqMax, "no"
    else
        Draw: .timeMin, .timeMax, .freqMin, .freqMax, "no"
    endif

    # Step 7: Draw axes on top
    @emlDrawAxes: .timeMin, .timeMax, .freqMin, .freqMax, .xLabel$, .yLabel$, .title$, .vpW, .vpH

    # Step 8: Reset state
    Colour: "Black"
    Line width: 1.0
endproc

# ----------------------------------------------------------------------------
# @emlDrawWaveform
# Draws a publication-quality waveform from a Sound object.
# Uses stepped symmetric amplitude bounds and zero-line reference.
# Source: task spec (17 Feb 2026), adapted for plugin dispatch signature.
# ----------------------------------------------------------------------------
# Requires: @emlInitDrawingDefaults (or manual global initialization).
# Reads globals: emlPanelOriginX, emlPanelOriginY (via @emlSetAdaptiveTheme).
procedure emlDrawWaveform: .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .tMin, .tMax, .aMin, .aMax

    @emlSetAdaptiveTheme: .vpW, .vpH
    @emlSetColorPalette: .colorMode$

    # Step 2: Compute time range (both 0 = auto)
    selectObject: .objectId
    .startTime = Get start time
    .endTime = Get end time
    if .tMin = 0 and .tMax = 0
        .timeMin = .startTime
        .timeMax = .endTime
    else
        .timeMin = .tMin
        .timeMax = .tMax
        # Clamp to object domain
        if .timeMin >= .endTime or .timeMax <= .startTime
            appendInfoLine: "WARNING: Time range (",
            ... fixed$ (.timeMin, 3), " – ", fixed$ (.timeMax, 3),
            ... " s) outside Sound domain (",
            ... fixed$ (.startTime, 3), " – ", fixed$ (.endTime, 3),
            ... " s). Using full domain."
            .timeMin = .startTime
            .timeMax = .endTime
        else
            if .timeMin < .startTime
                .timeMin = .startTime
            endif
            if .timeMax > .endTime
                .timeMax = .endTime
            endif
        endif
    endif

    # Step 3: Compute amplitude range
    selectObject: .objectId
    .maxAmp = Get maximum: .timeMin, .timeMax, "Sinc70"
    .minAmp = Get minimum: .timeMin, .timeMax, "Sinc70"

    if .aMin = 0 and .aMax = 0
        # Auto: symmetric range with buffer via emlComputeAxisRange
        .absMax = max (abs (.maxAmp), abs (.minAmp))
        # Adaptive rounding grid: amplitude is scale-free (normalised, Pa, or
        # arbitrary units), so the granularity must come from the data.
        @emlComputeNiceStep: .absMax - (0), emlSetAdaptiveTheme.targetTicksY
        .axisRoundTo = emlComputeNiceStep.step
        @emlComputeAxisRange: 0, .absMax, .axisRoundTo, 0
        .ampBound = emlComputeAxisRange.axisMax
        .ampTop = .ampBound
        .ampBottom = -.ampBound
    else
        # Custom: user values taken literally
        .ampBottom = .aMin
        .ampTop = .aMax
    endif

    # Step 4: Set viewport and axes
    @emlSetPanelViewport
    Axes: .timeMin, .timeMax, .ampBottom, .ampTop

    # Step 5: Draw gridlines (if requested)
    # gridMode: 1=Both, 2=Horizontal only, 3=Vertical only, 4=Off
    if .gridMode = 1
        @emlDrawGridlines: .timeMin, .timeMax, .ampBottom, .ampTop, emlSetAdaptiveTheme.targetTicksX, emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks
    elsif .gridMode = 2
        @emlDrawHorizontalGridlines: .timeMin, .timeMax, .ampBottom, .ampTop, emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks
    elsif .gridMode = 3
        @emlDrawVerticalGridlines: .timeMin, .timeMax, .ampBottom, .ampTop, emlSetAdaptiveTheme.targetTicksX, emlSetAdaptiveTheme.useMinorTicks
    endif

    # Step 6: Draw zero line (faint reference)
    Colour: "{0.85, 0.85, 0.85}"
    Line width: 0.5
    Draw line: .timeMin, 0, .timeMax, 0

    # Step 7: Draw the waveform
    selectObject: .objectId
    Colour: emlSetColorPalette.line$[1]
    Line width: emlSetAdaptiveTheme.dataLineWidth
    Draw: .timeMin, .timeMax, .ampBottom, .ampTop, "no", "Curve"

    # Step 8: Draw axes on top
    @emlDrawAxes: .timeMin, .timeMax, .ampBottom, .ampTop, .xLabel$, .yLabel$, .title$, .vpW, .vpH

    # Step 9: Reset state
    Colour: "Black"
    Line width: 1.0
endproc

# ----------------------------------------------------------------------------
# @emlDrawSpectrum
# Draws a publication-quality Spectrum plot.
# Source: v1.1 (17 Feb 2026), adapted for plugin dispatch signature.
# v1.1: Fixed frequency auto-detection (uses sensible defaults, not time queries).
# ----------------------------------------------------------------------------
# Requires: @emlInitDrawingDefaults (or manual global initialization).
# Reads globals: emlPanelOriginX, emlPanelOriginY (via @emlSetAdaptiveTheme).
procedure emlDrawSpectrum: .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .fMin, .fMax, .pMin, .pMax

    # Set up theme and palette
    @emlSetAdaptiveTheme: .vpW, .vpH
    @emlSetColorPalette: .colorMode$

    # Compute frequency range (both 0 = auto)
    if .fMin = 0 and .fMax = 0
        .freqMin = 0
        .freqMax = 5000
    else
        .freqMin = .fMin
        .freqMax = .fMax
    endif

    # Compute power range (both 0 = auto)
    if .pMin = 0 and .pMax = 0
        .powerMin = 0
        .powerMax = 80
    else
        .powerMin = .pMin
        .powerMax = .pMax
    endif

    # Set viewport and axes
    @emlSetPanelViewport
    Axes: .freqMin, .freqMax, .powerMin, .powerMax

    # Draw gridlines if requested
    # gridMode: 1=Both, 2=Horizontal only, 3=Vertical only, 4=Off
    if .gridMode = 1
        @emlDrawGridlines: .freqMin, .freqMax, .powerMin, .powerMax, emlSetAdaptiveTheme.targetTicksX, emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks
    elsif .gridMode = 2
        @emlDrawHorizontalGridlines: .freqMin, .freqMax, .powerMin, .powerMax, emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks
    elsif .gridMode = 3
        @emlDrawVerticalGridlines: .freqMin, .freqMax, .powerMin, .powerMax, emlSetAdaptiveTheme.targetTicksX, emlSetAdaptiveTheme.useMinorTicks
    endif

    # Draw the spectrum
    selectObject: .objectId
    Colour: emlSetColorPalette.line$[1]
    Line width: emlSetAdaptiveTheme.dataLineWidth
    Draw: .freqMin, .freqMax, .powerMin, .powerMax, "no"

    # Draw axes
    @emlDrawAxes: .freqMin, .freqMax, .powerMin, .powerMax, .xLabel$, .yLabel$, .title$, .vpW, .vpH

    # Reset state
    Colour: "Black"
    Line width: 1.0
endproc

# ----------------------------------------------------------------------------
# @emlDrawLTAS
# Draws a publication-quality LTAS plot with optional multi-method overlay.
# Source: v1.2 (26 Mar 2026).
# v1.1: Fixed frequency auto-detection (uses sensible defaults, not time queries).
# v1.2: Multi-method overlay (Curve, Bars, Poles, Speckles) with sequential
#        Okabe-Ito color assignment. Draw order back-to-front:
#        Bars → Speckles → Poles → Curve. Fallback if all disabled: Curve.
# ----------------------------------------------------------------------------
# Requires: @emlInitDrawingDefaults (or manual global initialization).
# Reads globals: emlPanelOriginX, emlPanelOriginY (via @emlSetAdaptiveTheme).
procedure emlDrawLTAS: .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .fMin, .fMax, .pMin, .pMax, .showCurve, .showBars, .showPoles, .showSpeckles

    # Set up theme and palette
    @emlSetAdaptiveTheme: .vpW, .vpH
    @emlSetColorPalette: .colorMode$

    # Fallback: if nothing enabled, draw Curve
    if .showCurve = 0 and .showBars = 0 and .showPoles = 0 and .showSpeckles = 0
        .showCurve = 1
    endif

    # Compute frequency range (both 0 = auto)
    if .fMin = 0 and .fMax = 0
        .freqMin = 0
        .freqMax = 5000
    else
        .freqMin = .fMin
        .freqMax = .fMax
    endif

    # Compute power range (both 0 = auto)
    if .pMin = 0 and .pMax = 0
        .powerMin = -20
        .powerMax = 80
    else
        .powerMin = .pMin
        .powerMax = .pMax
    endif

    # Set viewport and axes
    @emlSetPanelViewport
    Axes: .freqMin, .freqMax, .powerMin, .powerMax

    # Draw gridlines if requested
    # gridMode: 1=Both, 2=Horizontal only, 3=Vertical only, 4=Off
    if .gridMode = 1
        @emlDrawGridlines: .freqMin, .freqMax, .powerMin, .powerMax, emlSetAdaptiveTheme.targetTicksX, emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks
    elsif .gridMode = 2
        @emlDrawHorizontalGridlines: .freqMin, .freqMax, .powerMin, .powerMax, emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks
    elsif .gridMode = 3
        @emlDrawVerticalGridlines: .freqMin, .freqMax, .powerMin, .powerMax, emlSetAdaptiveTheme.targetTicksX, emlSetAdaptiveTheme.useMinorTicks
    endif

    # Build draw queue: back-to-front order (Bars, Poles, Curve, Speckles)
    # Speckles drawn last to cap poles visually.
    # Each enabled method gets the next sequential palette color.
    .colorIdx = 0

    # --- Bars (back layer — native, respects viewport) ---
    if .showBars
        .colorIdx = .colorIdx + 1
        selectObject: .objectId
        Colour: emlSetColorPalette.line$[.colorIdx]
        Line width: emlSetAdaptiveTheme.dataLineWidth
        Draw: .freqMin, .freqMax, .powerMin, .powerMax, "no", "Bars"
    endif

    # --- Poles (custom — thin lines from 0 to value, clamped) ---
    if .showPoles
        .colorIdx = .colorIdx + 1
        selectObject: .objectId
        .nBins = Get number of bins
        Colour: emlSetColorPalette.line$[.colorIdx]
        Line width: emlSetAdaptiveTheme.dataLineWidth
        # Origin at 0, clamped to axis bounds
        .poleOrigin = 0
        if .poleOrigin < .powerMin
            .poleOrigin = .powerMin
        endif
        if .poleOrigin > .powerMax
            .poleOrigin = .powerMax
        endif
        for .iBin from 1 to .nBins
            selectObject: .objectId
            .binFreq = Get frequency from bin number: .iBin
            .binVal = Get value in bin: .iBin
            if .binVal <> undefined
                if .binFreq >= .freqMin and .binFreq <= .freqMax
                    # Clamp value to axis bounds (don't skip — draw visible portion)
                    .clampedVal = .binVal
                    if .clampedVal < .powerMin
                        .clampedVal = .powerMin
                    endif
                    if .clampedVal > .powerMax
                        .clampedVal = .powerMax
                    endif
                    Draw line: .binFreq, .poleOrigin, .binFreq, .clampedVal
                endif
            endif
        endfor
    endif

    # --- Curve (native) ---
    if .showCurve
        .colorIdx = .colorIdx + 1
        selectObject: .objectId
        Colour: emlSetColorPalette.line$[.colorIdx]
        Line width: emlSetAdaptiveTheme.dataLineWidth
        Draw: .freqMin, .freqMax, .powerMin, .powerMax, "no", "Curve"
    endif

    # --- Speckles (custom — dots at data values, drawn last to cap poles) ---
    if .showSpeckles
        .colorIdx = .colorIdx + 1
        selectObject: .objectId
        .nBins = Get number of bins
        Colour: emlSetColorPalette.line$[.colorIdx]
        # Dot radius in world x-coordinates (frequency)
        .dotRadius = (.freqMax - .freqMin) * 0.006
        for .iBin from 1 to .nBins
            selectObject: .objectId
            .binFreq = Get frequency from bin number: .iBin
            .binVal = Get value in bin: .iBin
            if .binVal <> undefined
                if .binFreq >= .freqMin and .binFreq <= .freqMax
                    if .binVal >= .powerMin and .binVal <= .powerMax
                        Paint circle: emlSetColorPalette.line$[.colorIdx], .binFreq, .binVal, .dotRadius
                    endif
                endif
            endif
        endfor
    endif

    # Draw axes
    @emlDrawAxes: .freqMin, .freqMax, .powerMin, .powerMax, .xLabel$, .yLabel$, .title$, .vpW, .vpH

    # Reset state
    Colour: "Black"
    Line width: 1.0
endproc

# ----------------------------------------------------------------------------
# @emlDrawTimeSeries
# Draws a publication-quality time series plot: one line, or one line per
# group, with a marker at every plotted vertex.
#
# Drawing modes (determined by column configuration):
#   A — No group column: a single line
#   D — Group column: one line per group (grouped time series)
#
# There are no modes B and C. They were spaghetti strands keyed on an ID
# column, with an optional mean overlay, and they were reverted — the banner
# immediately below has said so the whole time this header contradicted it.
# The signature is the proof: no .idCol$, no .showMean, and no band columns
# either, so the CI band this header used to promise for mode A is not here.
# Individual traces are @emlDrawSpaghettiPlot; a CI band is
# @emlDrawTimeSeriesCI.
#
# The group count is not capped. v1.24: the palette gives each group one of
# 8 Okabe-Ito hues AND one of 3 marker shapes, so 24 groups are drawn
# distinguishably; past 24 the (hue, shape) pair repeats.
# ----------------------------------------------------------------------------
# ============================================================================
# @emlDrawTimeSeries (reverted — modes A + D only)
# ============================================================================
# Simple time series: one line, or one line per group. No individuals.
# ============================================================================
# Requires: @emlInitDrawingDefaults (or manual global initialization).
# Reads globals: emlPanelOriginX, emlPanelOriginY (via @emlSetAdaptiveTheme).
procedure emlDrawTimeSeries: .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .timeCol$, .valueCol$, .groupCol$, .tMin, .tMax, .vMin, .vMax
    # The column test runs once, at procedure entry, because the flag is
    # read by loops that a conditional does not always reach. Same reader
    # as the analysis -- see @emlDrawColumnIsClean.
    @emlDrawColumnIsClean: .objectId, .timeCol$
    .cleanTimeObj = emlDrawColumnIsClean.clean
    @emlDrawColumnIsClean: .objectId, .valueCol$
    .cleanValObj = emlDrawColumnIsClean.clean


    # Step 1: Setup
    @emlSetAdaptiveTheme: .vpW, .vpH
    @emlSetColorPalette: .colorMode$
    # v1.21: this procedure is also the LINE CHART. Graph type 5 with the CI
    # toggle off dispatches here; with it on, to @emlDrawTimeSeriesCI. There
    # is no separate @emlDrawLineChart.
    @emlDiscloseBegin: "Time series"
    # v1.21: the corner the legend takes, so @emlDiscloseEnd can keep the
    # disclosure box out of it. Empty until a legend is actually drawn.
    .legendCorner$ = ""

    .hasGroup = 0
    .nGroups = 0
    if .groupCol$ <> ""
        @emlCountGroups: .objectId, .groupCol$
        if emlCountGroups.error$ = "" and emlCountGroups.nGroups > 1
            .hasGroup = 1
            .nGroups = emlCountGroups.nGroups
            @emlOptimizePaletteContrast: .nGroups
            for .g from 1 to .nGroups
                .grpLabel$[.g] = emlCountGroups.groupLabel$[.g]
            endfor
        endif
    endif

    # Step 2: Copy and sort table
    selectObject: .objectId
    .tempTable = Copy: "eml_ts_temp"
    if .hasGroup = 1
        Sort rows: .groupCol$ + " " + .timeCol$
    else
        Sort rows: .timeCol$
    endif

    # Step 3: Read data
    selectObject: .tempTable
    .nRows = Get number of rows
    # v1.21: count the rows the figure will not use, HERE, before Step 3b
    # rewrites .nRows to the collapsed length. Same counter idiom as
    # @emlDrawViolinPlot; reported at the end of the procedure.
    .nSkippedRows = 0
    # Same reader as the analysis. See @emlDrawColumnIsClean.
    @emlDrawColumnIsClean: .tempTable, .timeCol$
    .cleanTimeTmp = emlDrawColumnIsClean.clean
    @emlDrawColumnIsClean: .tempTable, .valueCol$
    .cleanValTmp = emlDrawColumnIsClean.clean
    for .i from 1 to .nRows
        selectObject: .tempTable
        @eml_readCell: .tempTable, .i, .timeCol$, .cleanTimeTmp
        .rowT'.i' = eml_readCell.value
        @eml_readCell: .tempTable, .i, .valueCol$, .cleanValTmp
        .rowY'.i' = eml_readCell.value
        if .hasGroup = 1
            .rowGrp'.i'$ = Get value: .i, .groupCol$
        endif
        ; Nested, not "or": and/or do not short-circuit in Praat, and both
        ; operands here are already evaluated anyway.
        .rowUsable = 0
        if .rowT'.i' <> undefined
            if .rowY'.i' <> undefined
                .rowUsable = 1
            endif
        endif
        if .rowUsable = 0
            .nSkippedRows = .nSkippedRows + 1
        endif
    endfor
    removeObject: .tempTable

    # ------------------------------------------------------------------
    # Step 3b: collapse repeated time points to their mean.
    #
    # 6 Aug 2026. Step 7 draws a segment between every consecutive pair of
    # sorted rows. That is only a series when there is one row per time.
    # Long format -- the shape every EML stats tool emits and every EML demo
    # table uses -- has several observations per time, and the result was a
    # figure that could invert the trend it was drawing.
    #
    # Worked example, two rising subjects: (1,10) (1,20) (2,12) (2,22)
    # (3,14) (3,24). Sorted, the segments are 10->20 vertical at x=1, then
    # 20->12 DOWN, then 12->22 vertical at x=2, then 22->14 DOWN, then
    # 14->24 vertical at x=3. The three vertical segments land exactly on
    # x = 1, 2, 3, two of which are the left and right axis lines, so what
    # the reader sees is the two descending connectors: a falling line
    # drawn from data that rises. Nothing was dropped and no arithmetic was
    # wrong -- the rendering simply had no concept of a series.
    #
    # Collapsing to the per-time mean (per group when grouped) is what a
    # time series of repeated measures means, and it is what the sibling
    # @emlDrawTimeSeriesCI already does before it adds its band. Rows are
    # already sorted by (group, time), so one linear pass suffices.
    # ------------------------------------------------------------------
    .nCollapsed = 0
    .aggN = 0
    .runSum = 0
    .runCount = 0
    .runT = undefined
    .runGrp$ = ""
    for .i from 1 to .nRows + 1
        .isEnd = 0
        if .i > .nRows
            .isEnd = 1
        else
            .tThis = .rowT'.i'
            .yThis = .rowY'.i'
            .gThis$ = ""
            if .hasGroup = 1
                .gThis$ = .rowGrp'.i'$
            endif
        endif
        # Flush the run whenever the (group, time) key changes or input ends.
        .flush = 0
        if .runCount > 0
            if .isEnd = 1
                .flush = 1
            elsif .tThis <> .runT or .gThis$ <> .runGrp$
                .flush = 1
            endif
        endif
        if .flush = 1
            .aggN = .aggN + 1
            .aggT'.aggN' = .runT
            .aggY'.aggN' = .runSum / .runCount
            if .hasGroup = 1
                .aggGrp'.aggN'$ = .runGrp$
            endif
            if .runCount > 1
                .nCollapsed = .nCollapsed + .runCount - 1
            endif
            .runCount = 0
            .runSum = 0
        endif
        if .isEnd = 0
            # v1.21. An undefined observation is DROPPED here. It used to be
            # carried through as its own aggregate entry, "so the existing
            # gap handling in Step 7 still sees them" — and in doing so it
            # set .runT = undefined while a run was still open. The next row
            # of the SAME time point then saw .tThis <> .runT and flushed,
            # and the flush writes `.aggT = .runT`, which was by then
            # undefined. The mean of that time point was therefore filed at
            # an undefined x and never drawn.
            #
            # Reproduced 7 Aug 2026 against the unmodified v1.20 file:
            # 20 rows, t = 1..5 with four observations each, six values
            # blank. Every one of the five time points contained a blank, so
            # every mean got an undefined time and the LINE CHART CAME OUT
            # COMPLETELY EMPTY — axes, title and subtitle, no data — while
            # the Info window said "6 repeated observations were averaged".
            # @emlDrawTimeSeriesCI, given the identical table, drew its five
            # points correctly, because it drops undefined rows outright
            # instead of carrying them.
            #
            # Dropping is now what this procedure does too, which is also
            # what makes the two agree. Consequence to be aware of: a time
            # point at which EVERY observation is missing no longer produces
            # a gap in the collapsed series — it produces no point, and the
            # line bridges it. The genuinely-ungrouped, one-row-per-time
            # case is untouched: .nCollapsed stays 0 there, the copy-back
            # below does not run, and Step 7 still sees the undefined rows
            # and still gaps at them. The rows dropped here are counted in
            # .nSkippedRows and disclosed.
            .pairOk = 0
            if .tThis <> undefined
                if .yThis <> undefined
                    .pairOk = 1
                endif
            endif
            if .pairOk = 1
                if .runCount = 0
                    .runT = .tThis
                    .runGrp$ = .gThis$
                endif
                .runSum = .runSum + .yThis
                .runCount = .runCount + 1
            endif
        endif
    endfor

    if .nCollapsed > 0
        .nRows = .aggN
        for .i from 1 to .nRows
            .rowT'.i' = .aggT'.i'
            .rowY'.i' = .aggY'.i'
            if .hasGroup = 1
                .rowGrp'.i'$ = .aggGrp'.i'$
            endif
        endfor
    endif

    # Step 4: Axis ranges
    # v1.19 (C 95): the range used to be seeded from row 1 unconditionally.
    # If row 1 was blank or non-numeric the seed was undefined, every later
    # comparison against it was false (all relational tests against undefined
    # are false in Praat), and the axis stayed undefined — the figure then
    # aborted at the first drawing command. Seed from the first VALID
    # observation instead and fold in only valid values.
    .xDataMin = 0
    .xDataMax = 0
    .yDataMin = 0
    .yDataMax = 0
    .rangeSeeded = 0
    .nValidPoints = 0
    for .i from 1 to .nRows
        .tThis = .rowT'.i'
        .yThis = .rowY'.i'
        .pairOk = 0
        if .tThis <> undefined
            if .yThis <> undefined
                .pairOk = 1
            endif
        endif
        if .pairOk = 1
            .nValidPoints = .nValidPoints + 1
            if .rangeSeeded = 0
                .xDataMin = .tThis
                .xDataMax = .tThis
                .yDataMin = .yThis
                .yDataMax = .yThis
                .rangeSeeded = 1
            else
                if .tThis < .xDataMin
                    .xDataMin = .tThis
                endif
                if .tThis > .xDataMax
                    .xDataMax = .tThis
                endif
                if .yThis < .yDataMin
                    .yDataMin = .yThis
                endif
                if .yThis > .yDataMax
                    .yDataMax = .yThis
                endif
            endif
        endif
    endfor

    # No usable observation at all: fall back to a unit axis and say so,
    # rather than handing undefined limits to Axes:.
    if .rangeSeeded = 0
        .xDataMin = 0
        .xDataMax = 1
        .yDataMin = 0
        .yDataMax = 1
        .noDataMsg$ = "NOTE: Time series — no usable (time, value) pair; empty axes drawn."
        appendInfoLine: .noDataMsg$
    endif

    # X-axis: exact data range (no nice-number rounding for time axes)
    if .tMin = 0 and .tMax = 0
        .xMin = .xDataMin
        .xMax = .xDataMax
    else
        .xMin = .tMin
        .xMax = .tMax
    endif

    # Adaptive rounding grid: derive roundTo from a nice step over the data
    # range (the same nice-number logic the gridlines use) so fractional data
    # (proportions, contact quotient, jitter %) is not snapped to a 10-unit grid.
    @emlComputeNiceStep: .yDataMax - (.yDataMin), emlSetAdaptiveTheme.targetTicksY
    .axisRoundTo = emlComputeNiceStep.step
    @emlComputeAxisRange: .yDataMin, .yDataMax, .axisRoundTo, 0
    if .vMin = 0 and .vMax = 0
        .yMin = emlComputeAxisRange.axisMin
        .yMax = emlComputeAxisRange.axisMax
    else
        .yMin = .vMin
        .yMax = .vMax
    endif

    # THE PUBLISHED RESOLVED EXTENT. Read this file's header note on the
    # `axis*` contract before changing it.
    #
    # Every emlDraw* procedure publishes .axisXMin/.axisXMax/.axisYMin/
    # .axisYMax, and they always mean THE RANGE THE AXES WERE ACTUALLY DRAWN
    # AT -- after auto-detection, after nice-number rounding, after the
    # categorical half-step padding. A caller that wants to place an
    # annotation, size a legend, or overlay on a finished figure reads these
    # four and needs to know nothing about which type it just drew.
    #
    # WHY THIS IS NOT AN ALIAS FOR .xMin. In this procedure they happen to be
    # equal, and in @emlDrawScatterPlot they are NOT: there .xMin/.xMax are
    # the procedure's PARAMETERS, carrying what the caller REQUESTED, with
    # (0, 0) meaning auto. So `.xMin` means "resolved" in nine procedures and
    # "requested" in one, and a caller reading it uniformly would silently get
    # 0 for a scatter's auto range instead of a wrong-variable error. That is
    # the failure this contract exists to prevent, and aliasing the two
    # spellings together would have preserved it under a tidier name.
    #
    # The parameters are therefore left alone. Only `axis*` is canonical.
    .axisXMin = .xMin
    .axisXMax = .xMax
    .axisYMin = .yMin
    .axisYMax = .yMax

    # Step 5: Viewport and axes
    @emlSetPanelViewport
    Axes: .xMin, .xMax, .yMin, .yMax
    # World-per-inch on both axes, for @emlDrawMarker (see @emlDrawScatterPlot).
    @emlSetPatternScale: .xMin, .xMax, .yMin, .yMax

    # Marker radius, in inches. v1.24: a time series (and therefore the LINE
    # CHART, which dispatches here) drew bare lines and nothing else, so its
    # only cue was hue and it cycled eight of them silently above eight
    # groups -- D127's shape, in the chart type where the reader has the
    # fewest other clues. A marker at every plotted vertex gives it the same
    # 8 x 3 style space the area marks have. 1.4 mm radius, ~33 pixels
    # across at 300 dpi.
    .markerHalfIn = emlSetAdaptiveTheme.markerSize * 1.4 / 25.4
    if .markerHalfIn < 1.0 / 25.4
        .markerHalfIn = 1.0 / 25.4
    endif

    # Step 6: Gridlines
    # gridMode: 1=Both, 2=Horizontal only, 3=Vertical only, 4=Off
    if .gridMode = 1
        @emlDrawGridlines: .xMin, .xMax, .yMin, .yMax,
        ... emlSetAdaptiveTheme.targetTicksX,
        ... emlSetAdaptiveTheme.targetTicksY,
        ... emlSetAdaptiveTheme.useMinorTicks
    elsif .gridMode = 2
        @emlDrawHorizontalGridlines: .xMin, .xMax, .yMin, .yMax,
        ... emlSetAdaptiveTheme.targetTicksY,
        ... emlSetAdaptiveTheme.useMinorTicks
    elsif .gridMode = 3
        @emlDrawVerticalGridlines: .xMin, .xMax, .yMin, .yMax,
        ... emlSetAdaptiveTheme.targetTicksX,
        ... emlSetAdaptiveTheme.useMinorTicks
    endif

    # Step 7: Draw data
    if .hasGroup = 0
        # Single line
        Colour: emlSetColorPalette.line$[1]
        Line width: emlSetAdaptiveTheme.dataLineWidth
        for .i from 1 to .nRows - 1
            .iN = .i + 1
            # v1.19 (C 96): an undefined endpoint propagated through min/max
            # into Draw line: and aborted the figure. Skip the segment; the
            # gap is the correct rendering of a missing observation.
            .segOk = 0
            if .rowT'.i' <> undefined
                if .rowY'.i' <> undefined
                    if .rowT'.iN' <> undefined
                        if .rowY'.iN' <> undefined
                            .segOk = 1
                        endif
                    endif
                endif
            endif
            if .segOk = 1
                if .rowT'.iN' >= .xMin and .rowT'.i' <= .xMax
                    .cx1 = max (.xMin, min (.xMax, .rowT'.i'))
                    .cy1 = max (.yMin, min (.yMax, .rowY'.i'))
                    .cx2 = max (.xMin, min (.xMax, .rowT'.iN'))
                    .cy2 = max (.yMin, min (.yMax, .rowY'.iN'))
                    Draw line: .cx1, .cy1, .cx2, .cy2
                endif
            endif
        endfor
        # A marker at every vertex that is actually on the panel. Segments
        # are CLAMPED to the axes above, which is right for a line -- it
        # keeps entering and leaving the frame -- but a clamped marker would
        # sit on the axis and claim an observation at a value nobody
        # measured, so an off-panel point gets no marker.
        for .i from 1 to .nRows
            .mOk = 0
            if .rowT'.i' <> undefined
                if .rowY'.i' <> undefined
                    .mOk = 1
                endif
            endif
            if .mOk = 1
                if .rowT'.i' < .xMin
                    .mOk = 0
                endif
            endif
            if .mOk = 1
                if .rowT'.i' > .xMax
                    .mOk = 0
                endif
            endif
            if .mOk = 1
                if .rowY'.i' < .yMin
                    .mOk = 0
                endif
            endif
            if .mOk = 1
                if .rowY'.i' > .yMax
                    .mOk = 0
                endif
            endif
            if .mOk = 1
                @emlDrawMarker: .rowT'.i', .rowY'.i', .markerHalfIn,
                ... emlSetColorPalette.marker[1], emlSetColorPalette.line$[1]
            endif
        endfor
    else
        # One line per group
        for .g from 1 to .nGroups
            Colour: emlSetColorPalette.line$[.g]
            Line width: emlSetAdaptiveTheme.dataLineWidth
            .prevT = 0
            .prevY = 0
            .started = 0
            for .i from 1 to .nRows
                .thisGrp$ = .rowGrp'.i'$
                if .thisGrp$ = .grpLabel$[.g]
                    .thisT = .rowT'.i'
                    .thisY = .rowY'.i'
                    # v1.19 (C 96): only valid points may become a segment
                    # endpoint or the carried-forward previous point.
                    .ptOk = 0
                    if .thisT <> undefined
                        if .thisY <> undefined
                            .ptOk = 1
                        endif
                    endif
                    if .ptOk = 1
                        if .started = 1
                            .cx1 = max (.xMin, min (.xMax, .prevT))
                            .cy1 = max (.yMin, min (.yMax, .prevY))
                            .cx2 = max (.xMin, min (.xMax, .thisT))
                            .cy2 = max (.yMin, min (.yMax, .thisY))
                            Draw line: .cx1, .cy1, .cx2, .cy2
                        endif
                        # Marker at the vertex, only when it is on the panel
                        # (see the ungrouped path for why it is not clamped).
                        .mOk = 1
                        if .thisT < .xMin
                            .mOk = 0
                        endif
                        if .mOk = 1
                            if .thisT > .xMax
                                .mOk = 0
                            endif
                        endif
                        if .mOk = 1
                            if .thisY < .yMin
                                .mOk = 0
                            endif
                        endif
                        if .mOk = 1
                            if .thisY > .yMax
                                .mOk = 0
                            endif
                        endif
                        if .mOk = 1
                            @emlDrawMarker: .thisT, .thisY, .markerHalfIn,
                            ... emlSetColorPalette.marker[.g],
                            ... emlSetColorPalette.line$[.g]
                        endif
                        # Drawing a marker leaves Praat's current colour and
                        # line width alone, but @emlDrawMarker's fallback
                        # does not, so the stroke state is reasserted for the
                        # next segment rather than assumed.
                        Colour: emlSetColorPalette.line$[.g]
                        Line width: emlSetAdaptiveTheme.dataLineWidth
                        .prevT = .thisT
                        .prevY = .thisY
                        .started = 1
                    endif
                endif
            endfor
        endfor

        # Quadrant scoring for adaptive legend placement
        selectObject: .objectId
        .nScanRows = Get number of rows
        .xMidQ = (.xMin + .xMax) / 2
        .yMidQ = (.yMin + .yMax) / 2
        .qTL = 0
        .qTR = 0
        .qBL = 0
        .qBR = 0
        for .qi from 1 to .nScanRows
            selectObject: .objectId
            @eml_readCell: .objectId, .qi, .timeCol$, .cleanTimeObj
            .rx = eml_readCell.value
            @eml_readCell: .objectId, .qi, .valueCol$, .cleanValObj
            .ry = eml_readCell.value
            if .rx <> undefined and .ry <> undefined
                if .ry >= .yMidQ
                    if .rx < .xMidQ
                        .qTL = .qTL + 1
                    else
                        .qTR = .qTR + 1
                    endif
                else
                    if .rx < .xMidQ
                        .qBL = .qBL + 1
                    else
                        .qBR = .qBR + 1
                    endif
                endif
            endif
        endfor
        @emlPlaceElements: .qTL, .qTR, .qBL, .qBR, .xMidQ, 1

        # Legend
        # v1.24: line plus marker, because that is what the series is.
        legendMarkered = 1
        legendMarkerLine = 1
        legendN = .nGroups
        for .g from 1 to .nGroups
            legendColor$[.g] = emlSetColorPalette.line$[.g]
            legendMarker[.g] = emlSetColorPalette.marker[.g]
            @emlSanitizeLabel: .grpLabel$[.g]
            legendLabel$[.g] = emlSanitizeLabel.result$
        endfor
        .legendCorner$ = emlPlaceElements.corner1$
        @emlDrawLegend: .xMin, .xMax, .yMin, .yMax, .legendCorner$,
        ... emlSetAdaptiveTheme.annotSize
    endif

    # Step 7B: Disclosures (v1.21)
    # Two facts a reader cannot recover from the figure: that the line is a
    # MEAN wherever a time point carried more than one observation, and that
    # rows were dropped. Both used to be Info-window-only or absent; the mean
    # note additionally hijacked emlSubtitle$ and drew there unconditionally.
    if .nCollapsed > 0
        @emlDisclose: "Line shows the mean per time point.",
        ... string$ (.nCollapsed) + " repeated observation(s) were averaged. "
        ... + "Use Spaghetti Plot to show individual series, or Time Series "
        ... + "(with CI) to show the spread around each mean."
    endif
    if .nSkippedRows > 0
        @emlDisclose: string$ (.nSkippedRows)
        ... + " row(s) skipped (missing or non-numeric value).", ""
    endif

    # Quadrant scan for the disclosure block's corner. Independent of the
    # legend's scan above, which only exists on the grouped path.
    .dxMid = (.xMin + .xMax) / 2
    .dyMid = (.yMin + .yMax) / 2
    .dTL = 0
    .dTR = 0
    .dBL = 0
    .dBR = 0
    selectObject: .objectId
    .dScanRows = Get number of rows
    for .di from 1 to .dScanRows
        selectObject: .objectId
        @eml_readCell: .objectId, .di, .timeCol$, .cleanTimeObj
        .drx = eml_readCell.value
        @eml_readCell: .objectId, .di, .valueCol$, .cleanValObj
        .dry = eml_readCell.value
        .dOk = 0
        if .drx <> undefined
            if .dry <> undefined
                .dOk = 1
            endif
        endif
        if .dOk = 1
            if .dry >= .dyMid
                if .drx < .dxMid
                    .dTL = .dTL + 1
                else
                    .dTR = .dTR + 1
                endif
            else
                if .drx < .dxMid
                    .dBL = .dBL + 1
                else
                    .dBR = .dBR + 1
                endif
            endif
        endif
    endfor
    # A legend is drawn on the grouped path only; where there is one, the
    # block takes the corner diagonally opposite it.
    @emlDiscloseEnd: .xMin, .xMax, .yMin, .yMax, .dTL, .dTR, .dBL, .dBR,
    ... .legendCorner$

    # Step 8: Axes
    @emlDrawAxes: .xMin, .xMax, .yMin, .yMax, .xLabel$, .yLabel$,
    ... .title$, .vpW, .vpH

    # Step 9: Reset
    Line width: 1.0
    Colour: "Black"
endproc


# ============================================================================
# @emlDrawTimeSeriesCI
# ============================================================================
# Time series with auto-computed confidence interval bands.
# Detects repeated measures per time point and computes mean ± CI using
# the t-distribution. CI level is (1 - annotAlpha) — default 95%.
# ============================================================================
# Requires: @emlInitDrawingDefaults (or manual global initialization).
# Reads globals: emlPanelOriginX, emlPanelOriginY (via @emlSetAdaptiveTheme),
#                annotAlpha (confidence level; default 0.05 = 95% CI).
procedure emlDrawTimeSeriesCI: .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .timeCol$, .valueCol$, .groupCol$, .tMin, .tMax, .vMin, .vMax

    @emlSetAdaptiveTheme: .vpW, .vpH
    @emlSetColorPalette: .colorMode$
    # @emlInitAlphaSprites is idempotent and cheap, but until 6 Aug 2026 the
    # only call was in eml-graphs-form.praat, so this procedure aborted with
    # "Unknown variable: emlInitAlphaSprites.available" for every caller that
    # was not the form. Calling it here makes the procedure self-sufficient;
    # in the form path the initialised flag short-circuits it immediately.
    @emlInitAlphaSprites
    @emlDiscloseBegin: "Time series (with CI)"
    # v1.21: the corner the legend takes, so @emlDiscloseEnd can keep the
    # disclosure box out of it. Empty until a legend is actually drawn.
    .legendCorner$ = ""

    .hasGroup = 0
    .nGroups = 1
    if .groupCol$ <> ""
        @emlCountGroups: .objectId, .groupCol$
        if emlCountGroups.error$ = "" and emlCountGroups.nGroups > 1
            .hasGroup = 1
            .nGroups = emlCountGroups.nGroups
            @emlOptimizePaletteContrast: .nGroups
            for .g from 1 to .nGroups
                .grpLabel$[.g] = emlCountGroups.groupLabel$[.g]
            endfor
        endif
    endif

    # Read all rows
    selectObject: .objectId
    .nRows = Get number of rows
    # Same reader as the analysis. See @emlDrawColumnIsClean.
    @emlDrawColumnIsClean: .objectId, .timeCol$
    .cleanTimeObj = emlDrawColumnIsClean.clean
    @emlDrawColumnIsClean: .objectId, .valueCol$
    .cleanValObj = emlDrawColumnIsClean.clean
    for .i from 1 to .nRows
        selectObject: .objectId
        @eml_readCell: .objectId, .i, .timeCol$, .cleanTimeObj
        .rowT'.i' = eml_readCell.value
        @eml_readCell: .objectId, .i, .valueCol$, .cleanValObj
        .rowY'.i' = eml_readCell.value
        if .hasGroup = 1
            .rowGrp'.i'$ = Get value: .i, .groupCol$
        else
            .rowGrp'.i'$ = "all"
        endif
    endfor

    # Per group: accumulate unique time points, compute mean ± CI
    # Global y range tracking
    .yDataMin = undefined
    .yDataMax = undefined
    .xDataMin = undefined
    .xDataMax = undefined
    .nDroppedRows = 0
    # v1.21: the CI figure collapses repeated observations to a mean at each
    # time point exactly as @emlDrawTimeSeries does, and said nothing about
    # it. .nUsedRows - .nPoints is how many observations that cost.
    .nUsedRows = 0
    .nPoints = 0

    for .g from 1 to .nGroups
        if .hasGroup = 1
            .gLabel$ = .grpLabel$[.g]
        else
            .gLabel$ = "all"
        endif
        .nUT = 0
        for .i from 1 to .nRows
            if .rowGrp'.i'$ = .gLabel$
                .t = .rowT'.i'
                .y = .rowY'.i'
                # v1.19 (C 96): only the value was tested here. A blank or
                # non-numeric TIME cell gave an undefined .t, which never
                # matched an existing unique time (every comparison against
                # undefined is false in Praat), so each such row became its
                # own phantom time point — inflating the reported time-point
                # count and carrying an undefined x into the band and
                # mean-line loops. Nested ifs because and/or do not
                # short-circuit in Praat.
                .rowOk = 0
                if .y <> undefined
                    if .t <> undefined
                        .rowOk = 1
                    endif
                endif
                if .rowOk = 0
                    .nDroppedRows = .nDroppedRows + 1
                else
                    .nUsedRows = .nUsedRows + 1
                    .isNew = 1
                    for .k from 1 to .nUT
                        if abs (.t - .gUT'.g'_'.k') < 0.0001
                            .isNew = 0
                            .gUS'.g'_'.k' = .gUS'.g'_'.k' + .y
                            .gUSS'.g'_'.k' = .gUSS'.g'_'.k' + .y * .y
                            .gUC'.g'_'.k' = .gUC'.g'_'.k' + 1
                        endif
                    endfor
                    if .isNew = 1
                        .nUT = .nUT + 1
                        .k = .nUT
                        .gUT'.g'_'.k' = .t
                        .gUS'.g'_'.k' = .y
                        .gUSS'.g'_'.k' = .y * .y
                        .gUC'.g'_'.k' = 1
                    endif
                endif
            endif
        endfor
        .gNUT'.g' = .nUT
        .nPoints = .nPoints + .nUT

        # Sort unique times (insertion sort)
        for .i from 2 to .nUT
            .keyT = .gUT'.g'_'.i'
            .keyS = .gUS'.g'_'.i'
            .keySS = .gUSS'.g'_'.i'
            .keyC = .gUC'.g'_'.i'
            .j = .i - 1
            .done = 0
            while .j >= 1 and .done = 0
                if .gUT'.g'_'.j' > .keyT
                    .jn = .j + 1
                    .gUT'.g'_'.jn' = .gUT'.g'_'.j'
                    .gUS'.g'_'.jn' = .gUS'.g'_'.j'
                    .gUSS'.g'_'.jn' = .gUSS'.g'_'.j'
                    .gUC'.g'_'.jn' = .gUC'.g'_'.j'
                    .j = .j - 1
                else
                    .done = 1
                endif
            endwhile
            .jn = .j + 1
            .gUT'.g'_'.jn' = .keyT
            .gUS'.g'_'.jn' = .keyS
            .gUSS'.g'_'.jn' = .keySS
            .gUC'.g'_'.jn' = .keyC
        endfor

        # Compute mean, CI for each unique time point
        for .k from 1 to .nUT
            .n = .gUC'.g'_'.k'
            .mean = .gUS'.g'_'.k' / .n
            .gMean'.g'_'.k' = .mean
            if .n >= 2
                .var = (.gUSS'.g'_'.k' - .n * .mean * .mean) / (.n - 1)
                if .var < 0
                    .var = 0
                endif
                .se = sqrt (.var / .n)
                .tCrit = invStudentQ (annotAlpha / 2, .n - 1)
                .gLo'.g'_'.k' = .mean - .tCrit * .se
                .gHi'.g'_'.k' = .mean + .tCrit * .se
            else
                .gLo'.g'_'.k' = .mean
                .gHi'.g'_'.k' = .mean
            endif
            # Track global ranges
            .t = .gUT'.g'_'.k'
            if .xDataMin = undefined
                .xDataMin = .t
                .xDataMax = .t
                .yDataMin = .gLo'.g'_'.k'
                .yDataMax = .gHi'.g'_'.k'
            else
                if .t < .xDataMin
                    .xDataMin = .t
                endif
                if .t > .xDataMax
                    .xDataMax = .t
                endif
                if .gLo'.g'_'.k' < .yDataMin
                    .yDataMin = .gLo'.g'_'.k'
                endif
                if .gHi'.g'_'.k' > .yDataMax
                    .yDataMax = .gHi'.g'_'.k'
                endif
            endif
        endfor
    endfor

    # v1.21: how many observations the mean absorbed. Zero when the table
    # holds one row per (group, time) — the line is then the data itself and
    # there is nothing to disclose.
    .nCollapsed = .nUsedRows - .nPoints

    # D111: the unit-axis fallback was already here but said nothing, so an
    # empty CI figure was the one empty frame in the set that arrived with no
    # explanation at all. Same words as @emlDrawTimeSeries.
    if .xDataMin = undefined
        .xDataMin = 0
        .xDataMax = 1
        .yDataMin = 0
        .yDataMax = 1
        .noDataMsg$ = "NOTE: Time series (with CI) — no usable (time, value) pair; empty axes drawn."
        appendInfoLine: .noDataMsg$
    endif

    # Axis ranges
    # X-axis: exact data range (no nice-number rounding for time axes)
    if .tMin = 0 and .tMax = 0
        .xMin = .xDataMin
        .xMax = .xDataMax
    else
        .xMin = .tMin
        .xMax = .tMax
    endif
    # Adaptive rounding grid: derive roundTo from a nice step over the data
    # range (the same nice-number logic the gridlines use) so fractional data
    # (proportions, contact quotient, jitter %) is not snapped to a 10-unit grid.
    @emlComputeNiceStep: .yDataMax - (.yDataMin), emlSetAdaptiveTheme.targetTicksY
    .axisRoundTo = emlComputeNiceStep.step
    @emlComputeAxisRange: .yDataMin, .yDataMax, .axisRoundTo, 0
    if .vMin = 0 and .vMax = 0
        .yMin = emlComputeAxisRange.axisMin
        .yMax = emlComputeAxisRange.axisMax
    else
        .yMin = .vMin
        .yMax = .vMax
    endif

    # The published resolved extent. See @emlDrawTimeSeries for the contract
    # and for why this is not an alias.
    .axisXMin = .xMin
    .axisXMax = .xMax
    .axisYMin = .yMin
    .axisYMax = .yMax

    # Viewport
    @emlSetPanelViewport
    Axes: .xMin, .xMax, .yMin, .yMax
    # World-per-inch on both axes, for @emlDrawMarker (see @emlDrawScatterPlot).
    @emlSetPatternScale: .xMin, .xMax, .yMin, .yMax

    # Marker radius in inches -- same value and same reasoning as
    # @emlDrawTimeSeries, which this procedure is the CI variant of.
    .markerHalfIn = emlSetAdaptiveTheme.markerSize * 1.4 / 25.4
    if .markerHalfIn < 1.0 / 25.4
        .markerHalfIn = 1.0 / 25.4
    endif

    # Gridlines
    # gridMode: 1=Both, 2=Horizontal only, 3=Vertical only, 4=Off
    if .gridMode = 1
        @emlDrawGridlines: .xMin, .xMax, .yMin, .yMax,
        ... emlSetAdaptiveTheme.targetTicksX,
        ... emlSetAdaptiveTheme.targetTicksY,
        ... emlSetAdaptiveTheme.useMinorTicks
    elsif .gridMode = 2
        @emlDrawHorizontalGridlines: .xMin, .xMax, .yMin, .yMax,
        ... emlSetAdaptiveTheme.targetTicksY,
        ... emlSetAdaptiveTheme.useMinorTicks
    elsif .gridMode = 3
        @emlDrawVerticalGridlines: .xMin, .xMax, .yMin, .yMax,
        ... emlSetAdaptiveTheme.targetTicksX,
        ... emlSetAdaptiveTheme.useMinorTicks
    endif

    # Draw CI bands and mean lines per group
    for .g from 1 to .nGroups
        .nUT = .gNUT'.g'
        .colorIdx = .g

        # CI band (alpha-composited)
        for .k from 1 to .nUT - 1
            .kN = .k + 1
            .x1 = .gUT'.g'_'.k'
            .x2 = .gUT'.g'_'.kN'
            if .x2 >= .xMin and .x1 <= .xMax
                .lo = min (.gLo'.g'_'.k', .gLo'.g'_'.kN')
                .hi = max (.gHi'.g'_'.k', .gHi'.g'_'.kN')
                .dx1 = max (.x1, .xMin)
                .dx2 = min (.x2, .xMax)
                .dLo = max (.lo, .yMin)
                .dHi = min (.hi, .yMax)
                if .dLo < .dHi
                    @emlDrawAlphaRect: .dx1, .dx2, .dLo, .dHi, .colorIdx, .colorMode$, "a30", emlSetColorPalette.fill$[.colorIdx]
                endif
            endif
        endfor

        # Mean line
        Colour: emlSetColorPalette.line$[.colorIdx]
        Line width: emlSetAdaptiveTheme.dataLineWidth
        for .k from 2 to .nUT
            .kp = .k - 1
            .mt1 = .gUT'.g'_'.kp'
            .mt2 = .gUT'.g'_'.k'
            .my1 = .gMean'.g'_'.kp'
            .my2 = .gMean'.g'_'.k'
            if .mt2 >= .xMin and .mt1 <= .xMax
                .my1 = max (.yMin, min (.yMax, .my1))
                .my2 = max (.yMin, min (.yMax, .my2))
                Draw line: max (.mt1, .xMin), .my1,
                ... min (.mt2, .xMax), .my2
            endif
        endfor

        # Marker at every mean point on the panel. Not clamped -- see the
        # same loop in @emlDrawTimeSeries.
        for .k from 1 to .nUT
            .mkT = .gUT'.g'_'.k'
            .mkY = .gMean'.g'_'.k'
            .mOk = 1
            if .mkT = undefined
                .mOk = 0
            endif
            if .mOk = 1
                if .mkY = undefined
                    .mOk = 0
                endif
            endif
            if .mOk = 1
                if .mkT < .xMin
                    .mOk = 0
                endif
            endif
            if .mOk = 1
                if .mkT > .xMax
                    .mOk = 0
                endif
            endif
            if .mOk = 1
                if .mkY < .yMin
                    .mOk = 0
                endif
            endif
            if .mOk = 1
                if .mkY > .yMax
                    .mOk = 0
                endif
            endif
            if .mOk = 1
                @emlDrawMarker: .mkT, .mkY, .markerHalfIn,
                ... emlSetColorPalette.marker[.colorIdx],
                ... emlSetColorPalette.line$[.colorIdx]
            endif
        endfor
    endfor

    # Legend
    if .hasGroup = 1
        selectObject: .objectId
        .nScanRows = Get number of rows
        .xMidQ = (.xMin + .xMax) / 2
        .yMidQ = (.yMin + .yMax) / 2
        .qTL = 0
        .qTR = 0
        .qBL = 0
        .qBR = 0
        for .qi from 1 to .nScanRows
            selectObject: .objectId
            @eml_readCell: .objectId, .qi, .timeCol$, .cleanTimeObj
            .rx = eml_readCell.value
            @eml_readCell: .objectId, .qi, .valueCol$, .cleanValObj
            .ry = eml_readCell.value
            if .rx <> undefined and .ry <> undefined
                if .ry >= .yMidQ
                    if .rx < .xMidQ
                        .qTL = .qTL + 1
                    else
                        .qTR = .qTR + 1
                    endif
                else
                    if .rx < .xMidQ
                        .qBL = .qBL + 1
                    else
                        .qBR = .qBR + 1
                    endif
                endif
            endif
        endfor
        @emlPlaceElements: .qTL, .qTR, .qBL, .qBR, .xMidQ, 1

        # v1.24: line plus marker, as drawn.
        legendMarkered = 1
        legendMarkerLine = 1
        legendN = .nGroups
        for .g from 1 to .nGroups
            legendColor$[.g] = emlSetColorPalette.line$[.g]
            legendMarker[.g] = emlSetColorPalette.marker[.g]
            @emlSanitizeLabel: .grpLabel$[.g]
            legendLabel$[.g] = emlSanitizeLabel.result$
        endfor
        .legendCorner$ = emlPlaceElements.corner1$
        @emlDrawLegend: .xMin, .xMax, .yMin, .yMax, .legendCorner$,
        ... emlSetAdaptiveTheme.annotSize
    endif

    # Info window
    appendInfoLine: "Time Series (with CI): ", .nGroups, " group(s)"
    for .g from 1 to .nGroups
        .nUT = .gNUT'.g'
        if .hasGroup = 1
            appendInfoLine: "  Group: ", .grpLabel$[.g],
            ... " — ", .nUT, " time points"
        else
            appendInfoLine: "  ", .nUT, " time points"
        endif
        .maxN = 0
        for .k from 1 to .nUT
            if .gUC'.g'_'.k' > .maxN
                .maxN = .gUC'.g'_'.k'
            endif
        endfor
        if .maxN <= 1
            appendInfoLine: "  NOTE: No repeated measures detected. CI not computed."
        else
            appendInfoLine: "  Observations per time point: up to ", .maxN
        endif
    endfor
    # v1.21: disclosures.
    # (a) The mean. "Per group: accumulate unique time points, compute
    #     mean ± CI" is the same collapse @emlDrawTimeSeries performs and
    #     discloses; this procedure performed it silently.
    # (b) Dropped rows. v1.19 already counted them, but in this procedure's
    #     own words and indentation ("  NOTE: N row(s) skipped (missing time
    #     or value).") — the count was right and the sentence did not match
    #     the other nine. One wording now, @emlDrawViolinPlot's.
    if .nCollapsed > 0
        @emlDisclose: "Line shows the mean; band shows the "
        ... + fixed$ (100 * (1 - annotAlpha), 0) + "% CI.",
        ... string$ (.nCollapsed) + " repeated observation(s) were averaged "
        ... + "into their time points. Use Spaghetti Plot to show the "
        ... + "individual series behind the mean."
    endif
    if .nDroppedRows > 0
        @emlDisclose: string$ (.nDroppedRows)
        ... + " row(s) skipped (missing or non-numeric value).", ""
    endif

    # Quadrant scan for the disclosure block's corner.
    .dxMid = (.xMin + .xMax) / 2
    .dyMid = (.yMin + .yMax) / 2
    .dTL = 0
    .dTR = 0
    .dBL = 0
    .dBR = 0
    selectObject: .objectId
    .dScanRows = Get number of rows
    for .di from 1 to .dScanRows
        selectObject: .objectId
        @eml_readCell: .objectId, .di, .timeCol$, .cleanTimeObj
        .drx = eml_readCell.value
        @eml_readCell: .objectId, .di, .valueCol$, .cleanValObj
        .dry = eml_readCell.value
        .dOk = 0
        if .drx <> undefined
            if .dry <> undefined
                .dOk = 1
            endif
        endif
        if .dOk = 1
            if .dry >= .dyMid
                if .drx < .dxMid
                    .dTL = .dTL + 1
                else
                    .dTR = .dTR + 1
                endif
            else
                if .drx < .dxMid
                    .dBL = .dBL + 1
                else
                    .dBR = .dBR + 1
                endif
            endif
        endif
    endfor
    @emlDiscloseEnd: .xMin, .xMax, .yMin, .yMax, .dTL, .dTR, .dBL, .dBR,
    ... .legendCorner$

    # Axes
    @emlDrawAxes: .xMin, .xMax, .yMin, .yMax, .xLabel$, .yLabel$,
    ... .title$, .vpW, .vpH

    Line width: 1.0
    Colour: "Black"
endproc


# ============================================================================
# @emlDrawSpaghettiPlot
# ============================================================================
# Individual subject traces across ordinal conditions with optional mean
# overlay. X-axis is categorical (equal-spaced positions in encounter
# order from the Table). Strands drawn muted; mean overlay bold.
# Endpoint dots at every subject × condition intersection.
#
# Arguments:
#   .condCol$  — categorical condition column (encounter order = x order)
#   .valueCol$ — numeric dependent variable
#   .idCol$    — subject/participant identifier column
#   .groupCol$ — optional grouping column ("" = no groups)
#   .showMean  — boolean: draw bold mean overlay
#   .vMin/.vMax — y-axis range (both 0 = auto)
# ============================================================================
# Requires: @emlInitDrawingDefaults (or manual global initialization).
# Reads globals: emlPanelOriginX, emlPanelOriginY (via @emlSetAdaptiveTheme).
procedure emlDrawSpaghettiPlot: .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .condCol$, .valueCol$, .idCol$, .groupCol$, .showMean, .vMin, .vMax
    # The column test runs once, at procedure entry, because the flag is
    # read by loops that a conditional does not always reach. Same reader
    # as the analysis -- see @emlDrawColumnIsClean.
    @emlDrawColumnIsClean: .objectId, .valueCol$
    .cleanValObj = emlDrawColumnIsClean.clean


    @emlSetAdaptiveTheme: .vpW, .vpH
    @emlSetColorPalette: .colorMode$
    # Categorical x-axis labels must exist before @emlDrawCategoricalXAxis
    # renders them. In the form path the pre-dispatch block has already
    # measured and this is a no-op; from anywhere else it is the difference
    # between a figure and an aborted script. Must come before this
    # procedure sets its own Axes: the measurement installs its own.
    @emlEnsureCategoricalLabels: .objectId, .condCol$, .vpW, .vpH
    @emlDiscloseBegin: "Spaghetti plot"
    # v1.21: the corner the legend takes, so @emlDiscloseEnd can keep the
    # disclosure box out of it. Empty until a legend is actually drawn.
    .legendCorner$ = ""

    # ----------------------------------------------------------------
    # Extract unique conditions via single source
    # ----------------------------------------------------------------
    @emlCountGroups: .objectId, .condCol$
    .nCond = emlCountGroups.nGroups
    for .c from 1 to .nCond
        .condLabel$[.c] = emlCountGroups.groupLabel$[.c]
    endfor

    selectObject: .objectId
    .nRows = Get number of rows

    if .nCond < 2
        appendInfoLine: "WARNING: Spaghetti plot requires at least 2 conditions. Found ", .nCond, "."
    endif

    # ----------------------------------------------------------------
    # Groups (optional)
    # ----------------------------------------------------------------
    .hasGroup = 0
    .nGroups = 0
    if .groupCol$ <> ""
        @emlCountGroups: .objectId, .groupCol$
        if emlCountGroups.error$ = "" and emlCountGroups.nGroups > 1
            .hasGroup = 1
            .nGroups = emlCountGroups.nGroups
            @emlOptimizePaletteContrast: .nGroups
            for .g from 1 to .nGroups
                .grpLabel$[.g] = emlCountGroups.groupLabel$[.g]
            endfor
        endif
    endif

    # ----------------------------------------------------------------
    # Read all rows: map condition label → integer x-position,
    # read value, subject ID, and optional group
    # ----------------------------------------------------------------
    # v1.21: count the rows no strand will pass through. Same counter idiom
    # and same wording as @emlDrawViolinPlot.
    .nSkippedRows = 0
    for .i from 1 to .nRows
        selectObject: .objectId
        .thisCond$ = Get value: .i, .condCol$
        # Map to integer position (encounter order)
        .rowX[.i] = 0
        for .c from 1 to .nCond
            if .thisCond$ = .condLabel$[.c]
                .rowX[.i] = .c
            endif
        endfor
        @eml_readCell: .objectId, .i, .valueCol$, .cleanValObj
        .rowY[.i] = eml_readCell.value
        .rowId$[.i] = Get value: .i, .idCol$
        if .hasGroup = 1
            .rowGrp$[.i] = Get value: .i, .groupCol$
        endif
        if .rowY[.i] = undefined
            .nSkippedRows = .nSkippedRows + 1
        endif
    endfor

    # ----------------------------------------------------------------
    # Y-axis range
    # ----------------------------------------------------------------
    # v1.19 (C 95): seeded from row 1 unconditionally, so a blank or
    # non-numeric first row left the range undefined for the whole figure
    # (every later comparison against undefined is false). Seed from the
    # first VALID observation and fold in only valid values.
    .yDataMin = 0
    .yDataMax = 0
    .rangeSeeded = 0
    .nValidPoints = 0
    for .i from 1 to .nRows
        if .rowY[.i] <> undefined
            .nValidPoints = .nValidPoints + 1
            if .rangeSeeded = 0
                .yDataMin = .rowY[.i]
                .yDataMax = .rowY[.i]
                .rangeSeeded = 1
            else
                if .rowY[.i] < .yDataMin
                    .yDataMin = .rowY[.i]
                endif
                if .rowY[.i] > .yDataMax
                    .yDataMax = .rowY[.i]
                endif
            endif
        endif
    endfor
    if .rangeSeeded = 0
        .yDataMin = 0
        .yDataMax = 1
        .noDataMsg$ = "NOTE: Spaghetti plot — no usable value; empty axes drawn."
        appendInfoLine: .noDataMsg$
    endif
    # Adaptive rounding grid: derive roundTo from a nice step over the data
    # range (the same nice-number logic the gridlines use) so fractional data
    # (proportions, contact quotient, jitter %) is not snapped to a 10-unit grid.
    @emlComputeNiceStep: .yDataMax - (.yDataMin), emlSetAdaptiveTheme.targetTicksY
    .axisRoundTo = emlComputeNiceStep.step
    @emlComputeAxisRange: .yDataMin, .yDataMax, .axisRoundTo, 0
    if .vMin = 0 and .vMax = 0
        .yMin = emlComputeAxisRange.axisMin
        .yMax = emlComputeAxisRange.axisMax
    else
        .yMin = .vMin
        .yMax = .vMax
    endif
    .xMin = 0.5
    .xMax = max (1, .nCond) + 0.5   ; clamp: a 0-row table would make left = right

    # The published resolved extent. See @emlDrawTimeSeries for the contract
    # and for why this is not an alias.
    .axisXMin = .xMin
    .axisXMax = .xMax
    .axisYMin = .yMin
    .axisYMax = .yMax

    # ----------------------------------------------------------------
    # Viewport
    # ----------------------------------------------------------------
    @emlSetPanelViewport
    Axes: .xMin, .xMax, .yMin, .yMax
    # World-per-inch on both axes, for @emlDrawMarker (see @emlDrawScatterPlot).
    @emlSetPatternScale: .xMin, .xMax, .yMin, .yMax

    # Gridlines (horizontal only — categorical x-axis)
    # gridMode: 1=Horizontal, 2=Off
    if .gridMode = 1
        @emlDrawHorizontalGridlines: .xMin, .xMax, .yMin, .yMax,
        ... emlSetAdaptiveTheme.targetTicksY,
        ... emlSetAdaptiveTheme.useMinorTicks
    endif

    # ----------------------------------------------------------------
    # Collect unique subject IDs via single source
    # ----------------------------------------------------------------
    @emlCountGroups: .objectId, .idCol$
    .nSubjects = emlCountGroups.nGroups
    for .s from 1 to .nSubjects
        .subjId$[.s] = emlCountGroups.groupLabel$[.s]
    endfor

    # ----------------------------------------------------------------
    # Strand + dot drawing parameters
    # ----------------------------------------------------------------
    .strandWidth = 1.0
    .dotSize = emlSetAdaptiveTheme.markerSize * 1.5
    if .dotSize < 1.0
        .dotSize = 1.0
    endif
    .meanDotSize = emlSetAdaptiveTheme.markerSize * 2.5
    if .meanDotSize < 1.5
        .meanDotSize = 1.5
    endif
    # The same two sizes in INCHES for @emlDrawMarker. Both were millimetre
    # radii for `Paint circle (mm)`; a square and a triangle need a physical
    # size on both axes instead, and inches is what the marker procedure
    # takes. 1.5 mm and 2.5 mm are 35 and 59 pixels across at 300 dpi.
    .dotHalfIn = .dotSize / 25.4
    .meanHalfIn = .meanDotSize / 25.4

    # ----------------------------------------------------------------
    # Draw strands + endpoint dots
    # ----------------------------------------------------------------
    if .hasGroup = 0
        # --- Ungrouped: single muted color ---
        @emlLightenColor: emlSetColorPalette.line$[1], 0.6
        .strandColor$ = emlLightenColor.result$

        for .s from 1 to .nSubjects
            Colour: .strandColor$
            Line width: .strandWidth
            .prevX = 0
            .prevY = 0
            .hasPrev = 0
            for .c from 1 to .nCond
                # Find this subject's value at this condition
                .foundVal = 0
                for .i from 1 to .nRows
                    if .foundVal = 0
                        if .rowId$[.i] = .subjId$[.s] and .rowX[.i] = .c
                            .thisY = .rowY[.i]
                            .foundVal = 1
                        endif
                    endif
                endfor
                # v1.19 (C 96): a found-but-undefined value used to reach
                # Draw line: / Paint circle (mm): and abort the figure. Treat
                # it as a missing observation — the strand skips that
                # condition instead.
                if .foundVal = 1
                    .valOk = 0
                    if .thisY <> undefined
                        .valOk = 1
                    endif
                    .foundVal = .valOk
                endif
                if .foundVal = 1
                    .thisX = .c
                    # Draw connecting line from previous condition
                    if .hasPrev = 1
                        Draw line: .prevX, .prevY, .thisX, .thisY
                    endif
                    # Endpoint dot
                    @emlDrawMarker: .thisX, .thisY, .dotHalfIn,
                    ... emlSetColorPalette.marker[1], .strandColor$
                    .prevX = .thisX
                    .prevY = .thisY
                    .hasPrev = 1
                endif
            endfor
        endfor

        # Mean overlay
        if .showMean = 1
            Colour: emlSetColorPalette.line$[1]
            Line width: emlSetAdaptiveTheme.dataLineWidth
            .prevMeanX = 0
            .prevMeanY = 0
            .hasPrevMean = 0
            for .c from 1 to .nCond
                .sum = 0
                .cnt = 0
                for .i from 1 to .nRows
                    # v1.19 (C 96): an undefined value poisoned the sum, so
                    # the mean came out undefined and aborted the overlay.
                    if .rowX[.i] = .c
                        if .rowY[.i] <> undefined
                            .sum = .sum + .rowY[.i]
                            .cnt = .cnt + 1
                        endif
                    endif
                endfor
                if .cnt > 0
                    .meanY = .sum / .cnt
                    if .hasPrevMean = 1
                        Draw line: .prevMeanX, .prevMeanY, .c, .meanY
                    endif
                    @emlDrawMarker: .c, .meanY, .meanHalfIn,
                    ... emlSetColorPalette.marker[1], emlSetColorPalette.line$[1]
                    .prevMeanX = .c
                    .prevMeanY = .meanY
                    .hasPrevMean = 1
                endif
            endfor
        endif

    else
        # --- Grouped: muted strands per group ---
        for .g from 1 to .nGroups
            @emlLightenColor: emlSetColorPalette.line$[.g], 0.6
            .strandCol$[.g] = emlLightenColor.result$
        endfor

        for .s from 1 to .nSubjects
            # Determine this subject's group from first row match
            .sGrp = 1
            for .i from 1 to .nRows
                if .rowId$[.i] = .subjId$[.s]
                    for .g from 1 to .nGroups
                        if .rowGrp$[.i] = .grpLabel$[.g]
                            .sGrp = .g
                        endif
                    endfor
                endif
            endfor

            Colour: .strandCol$[.sGrp]
            Line width: .strandWidth
            .prevX = 0
            .prevY = 0
            .hasPrev = 0
            for .c from 1 to .nCond
                .foundVal = 0
                for .i from 1 to .nRows
                    if .foundVal = 0
                        if .rowId$[.i] = .subjId$[.s] and .rowX[.i] = .c
                            .thisY = .rowY[.i]
                            .foundVal = 1
                        endif
                    endif
                endfor
                # v1.19 (C 96): same undefined-value guard as the ungrouped
                # strand path above.
                if .foundVal = 1
                    .valOk = 0
                    if .thisY <> undefined
                        .valOk = 1
                    endif
                    .foundVal = .valOk
                endif
                if .foundVal = 1
                    .thisX = .c
                    if .hasPrev = 1
                        Draw line: .prevX, .prevY, .thisX, .thisY
                    endif
                    @emlDrawMarker: .thisX, .thisY, .dotHalfIn,
                    ... emlSetColorPalette.marker[.sGrp], .strandCol$[.sGrp]
                    .prevX = .thisX
                    .prevY = .thisY
                    .hasPrev = 1
                endif
            endfor
        endfor

        # Per-group mean overlay
        if .showMean = 1
            for .g from 1 to .nGroups
                Colour: emlSetColorPalette.line$[.g]
                Line width: emlSetAdaptiveTheme.dataLineWidth
                .prevMeanX = 0
                .prevMeanY = 0
                .hasPrevMean = 0
                for .c from 1 to .nCond
                    .sum = 0
                    .cnt = 0
                    for .i from 1 to .nRows
                        # v1.19 (C 96): undefined values excluded from the
                        # per-group mean (see ungrouped overlay above).
                        if .rowX[.i] = .c and .rowGrp$[.i] = .grpLabel$[.g]
                            if .rowY[.i] <> undefined
                                .sum = .sum + .rowY[.i]
                                .cnt = .cnt + 1
                            endif
                        endif
                    endfor
                    if .cnt > 0
                        .meanY = .sum / .cnt
                        if .hasPrevMean = 1
                            Draw line: .prevMeanX, .prevMeanY, .c, .meanY
                        endif
                        @emlDrawMarker: .c, .meanY, .meanHalfIn,
                        ... emlSetColorPalette.marker[.g], emlSetColorPalette.line$[.g]
                        .prevMeanX = .c
                        .prevMeanY = .meanY
                        .hasPrevMean = 1
                    endif
                endfor
            endfor
        endif

        # Quadrant scoring for adaptive legend placement
        selectObject: .objectId
        .nScanRows = Get number of rows
        .xMidQ = (.xMin + .xMax) / 2
        .yMidQ = (.yMin + .yMax) / 2
        .qTL = 0
        .qTR = 0
        .qBL = 0
        .qBR = 0
        for .qi from 1 to .nScanRows
            selectObject: .objectId
            @eml_readCell: .objectId, .qi, .valueCol$, .cleanValObj
            .ry = eml_readCell.value
            .rc$ = Get value: .qi, .condCol$
            if .ry <> undefined
                # Map condition to x position
                .rcIdx = 0
                for .ci from 1 to .nCond
                    if .rc$ = .condLabel$[.ci]
                        .rcIdx = .ci
                    endif
                endfor
                if .rcIdx > 0
                    if .ry >= .yMidQ
                        if .rcIdx < .xMidQ
                            .qTL = .qTL + 1
                        else
                            .qTR = .qTR + 1
                        endif
                    else
                        if .rcIdx < .xMidQ
                            .qBL = .qBL + 1
                        else
                            .qBR = .qBR + 1
                        endif
                    endif
                endif
            endif
        endfor
        @emlPlaceElements: .qTL, .qTR, .qBL, .qBR, .xMidQ, 1

        # Legend
        # v1.24: strands and mean dots carry the marker shape above eight
        # groups, so the key shows it. legendMarkerLine = 1 -- a spaghetti
        # series IS a connected line with markers on it, and a key of bare
        # points would misdescribe it.
        legendMarkered = 1
        legendMarkerLine = 1
        legendN = .nGroups
        for .g from 1 to .nGroups
            legendColor$[.g] = emlSetColorPalette.line$[.g]
            legendMarker[.g] = emlSetColorPalette.marker[.g]
            @emlSanitizeLabel: .grpLabel$[.g]
            legendLabel$[.g] = emlSanitizeLabel.result$
        endfor
        .legendCorner$ = emlPlaceElements.corner1$
        @emlDrawLegend: .xMin, .xMax, .yMin, .yMax, .legendCorner$,
        ... emlSetAdaptiveTheme.annotSize
    endif

    # ----------------------------------------------------------------
    # Disclosures (v1.21)
    # ----------------------------------------------------------------
    # A spaghetti plot draws the raw observations, so it has nothing to
    # confess about summarising. What it did not draw, it must still say.
    if .nSkippedRows > 0
        @emlDisclose: string$ (.nSkippedRows)
        ... + " row(s) skipped (missing or non-numeric value).", ""
    endif

    .dxMid = (.xMin + .xMax) / 2
    .dyMid = (.yMin + .yMax) / 2
    .dTL = 0
    .dTR = 0
    .dBL = 0
    .dBR = 0
    for .di from 1 to .nRows
        if .rowX[.di] > 0
            if .rowY[.di] <> undefined
                if .rowY[.di] >= .dyMid
                    if .rowX[.di] < .dxMid
                        .dTL = .dTL + 1
                    else
                        .dTR = .dTR + 1
                    endif
                else
                    if .rowX[.di] < .dxMid
                        .dBL = .dBL + 1
                    else
                        .dBR = .dBR + 1
                    endif
                endif
            endif
        endif
    endfor
    @emlDiscloseEnd: .xMin, .xMax, .yMin, .yMax, .dTL, .dTR, .dBL, .dBR,
    ... .legendCorner$

    # ----------------------------------------------------------------
    # Axes — categorical x with condition labels (pre-measured)
    # ----------------------------------------------------------------
    @emlDrawInnerBoxIf
    @emlDrawAlignedMarksLeft: .yMin, .yMax, emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks

    # Condition labels and x-axis label (pre-measured)
    @emlDrawCategoricalXAxis: .nCond, .xMin, .xMax, .yMin, .yMax, .xLabel$
    if emlShowAxisNameY
        Text left: "yes", .yLabel$
    endif

    @emlDrawTitle: .title$, .vpW, .vpH, .xMin, .xMax, .yMin, .yMax

    # ----------------------------------------------------------------
    # Info window report
    # ----------------------------------------------------------------
    @emlReportHeader: "Spaghetti Plot Summary"
    selectObject: .objectId
    .reportTableName$ = selected$ ("Table")
    @emlUnderscoreToSpace: .reportTableName$
    @emlReportLineString: "Table", emlUnderscoreToSpace.result$
    @emlUnderscoreToSpace: .condCol$
    @emlReportLineString: "Condition column", emlUnderscoreToSpace.result$
    @emlUnderscoreToSpace: .valueCol$
    @emlReportLineString: "Value column", emlUnderscoreToSpace.result$
    if .idCol$ <> ""
        @emlUnderscoreToSpace: .idCol$
        @emlReportLineString: "ID column", emlUnderscoreToSpace.result$
    endif
    @emlReportLine: "Conditions", .nCond, 0
    if .nGroups > 0
        @emlReportLine: "Groups", .nGroups, 0
    endif

    for .rc from 1 to .nCond
        @emlReportBlank
        @emlSanitizeLabel: .condLabel$[.rc]
        @emlReportSection: emlSanitizeLabel.result$
        # Extract values for this condition
        selectObject: .objectId
        .rcN = 0
        .rcSum = 0
        .rcData# = zero# (.nRows)
        for .ri from 1 to .nRows
            selectObject: .objectId
            .rCond$ = Get value: .ri, .condCol$
            if .rCond$ = .condLabel$[.rc]
                @eml_readCell: .objectId, .ri, .valueCol$, .cleanValObj
                .rVal = eml_readCell.value
                if .rVal <> undefined
                    .rcN = .rcN + 1
                    .rcData#[.rcN] = .rVal
                    .rcSum = .rcSum + .rVal
                endif
            endif
        endfor
        if .rcN > 0
            .rcMean = .rcSum / .rcN
            # Compute SD
            .rcSS = 0
            for .ri from 1 to .rcN
                .rcDev = .rcData#[.ri] - .rcMean
                .rcSS = .rcSS + .rcDev * .rcDev
            endfor
            if .rcN > 1
                .rcSD = sqrt (.rcSS / (.rcN - 1))
            else
                .rcSD = 0
            endif
            @emlReportLine: "N", .rcN, 0
            @emlReportLine: "Mean", .rcMean, 3
            @emlReportLine: "SD", .rcSD, 3
        endif
    endfor
    @emlReportFooter

    # Reset state
    Colour: "Black"
    Line width: 1.0
    Font size: emlSetAdaptiveTheme.bodySize
endproc


# ----------------------------------------------------------------------------
# @emlDrawBarChart
# Draws a publication-quality grouped bar chart with optional error bars.
# Error mode: 0=none, 1=SE (auto), 2=SD (auto), 3=custom column.
# Source: task spec (17 Feb 2026), adapted for plugin dispatch signature.
# ----------------------------------------------------------------------------
# Requires: @emlInitDrawingDefaults (or manual global initialization).
# Reads globals: emlPanelOriginX, emlPanelOriginY (via @emlSetAdaptiveTheme).
procedure emlDrawBarChart: .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .groupCol$, .valueCol$, .errorMode, .errorCol$, .vMin, .vMax

    # Step 1: Set up theme and palette
    @emlSetAdaptiveTheme: .vpW, .vpH
    @emlSetColorPalette: .colorMode$
    # emlBarData_* is produced by @emlMeasureBarData, which before 6 Aug 2026
    # was called only from the form's pre-dispatch block — so a bar chart drawn
    # from anywhere else died at "Unknown variable: emlBarData_nGroups" with
    # nothing on the canvas. Every argument the measurement needs is already a
    # parameter of this procedure, so it can guarantee its own precondition.
    @emlEnsureBarData: .objectId, .groupCol$, .valueCol$, .errorMode, .errorCol$
    # Categorical x-axis labels must exist before @emlDrawCategoricalXAxis
    # renders them. In the form path the pre-dispatch block has already
    # measured and this is a no-op; from anywhere else it is the difference
    # between a figure and an aborted script. Must come before this
    # procedure sets its own Axes: the measurement installs its own.
    @emlEnsureCategoricalLabels: .objectId, .groupCol$, .vpW, .vpH
    @emlDiscloseBegin: "Bar chart"

    # Sanitize title (axis labels handled at generation)
    @emlSanitizeLabel: .title$
    .title$ = emlSanitizeLabel.result$

    # Step 2: Read pre-computed data from @emlMeasureBarData globals
    .nGroups = emlBarData_nGroups
    @emlOptimizePaletteContrast: .nGroups

    # D111: this procedure had no no-data branch of its own. It survived an
    # empty table only because emlBarData_visibleMin/visibleMax both seed at 0
    # and emlComputeAxisRange happens to widen a zero span — an accident, not a
    # decision, and it left the reader with no note and an axis a fifth shorter
    # than every sibling's empty frame. State the fallback the way the violin
    # family states it: a unit data range, disclosed.
    .nUsableGroups = 0
    for .g from 1 to .nGroups
        if emlBarData_valid[.g] = 1
            .nUsableGroups = .nUsableGroups + 1
        endif
    endfor
    .visibleMin = emlBarData_visibleMin
    .visibleMax = emlBarData_visibleMax
    if .nUsableGroups = 0
        .visibleMin = 0
        .visibleMax = 1
        .noDataMsg$ = "NOTE: Bar chart — no usable value; empty axes drawn."
        appendInfoLine: .noDataMsg$
    endif

    # Step 3: Compute y-axis range (both 0 = auto)
    # Route through emlComputeAxisRange with the tracked data min so all-negative
    # means get a negative yMin instead of being clipped at 0. For non-negative
    # data visibleMin = 0 and emlComputeAxisRange's own non-negative guard keeps
    # yMin at 0 (bars from 0 up), preserving prior behavior.
    if .vMin = 0 and .vMax = 0
        # Adaptive rounding grid: derive roundTo from a nice step over the data
        # range (the same nice-number logic the gridlines use) so fractional data
        # (proportions, contact quotient, jitter %) is not snapped to a 10-unit grid.
        @emlComputeNiceStep: .visibleMax - (.visibleMin), emlSetAdaptiveTheme.targetTicksY
        .axisRoundTo = emlComputeNiceStep.step
        @emlComputeAxisRange: .visibleMin, .visibleMax, .axisRoundTo, 0
        .yMin = emlComputeAxisRange.axisMin
        .yMax = emlComputeAxisRange.axisMax
    else
        .yMin = .vMin
        .yMax = .vMax
    endif

    # Step 4: Set x-axis range (categorical — one position per group)
    .xMin = 0.5
    .xMax = max (1, .nGroups) + 0.5   ; clamp: a 0-row table would make left = right

    # Step 5: Set viewport and axes
    @emlSetPanelViewport
    Axes: .xMin, .xMax, .yMin, .yMax

    # Step 6: Draw horizontal gridlines (if requested)
    # gridMode: 1=Horizontal, 2=Off
    if .gridMode = 1
        @emlDrawHorizontalGridlines: .xMin, .xMax, .yMin, .yMax, emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks
    endif

    # Step 7: Draw bars with error bars (one bar per group, colored by palette)
    .barWidth = 0.6
    .halfBar = .barWidth / 2
    .capWidth = .barWidth * 0.17

    # Bar baseline: 0 clamped into the axis. Decoupled from .yMin so that when
    # yMin is negative (all-negative data) bars still emanate from 0 rather than
    # from the axis floor. For non-negative data .yMin = 0, so .baseline = 0.
    .baseline = 0
    if .baseline < .yMin
        .baseline = .yMin
    endif
    if .baseline > .yMax
        .baseline = .yMax
    endif

    # v1.19: bookkeeping for the two disclosures added below.
    #   .nSkippedBars   — bars whose mean was undefined and could not be drawn
    #   .nSkippedErrors — error bars suppressed because the error was undefined
    #   .nTruncated     — error bars clipped by the axis limits (C 88)
    # Depth of the out-of-range arrowhead that marks a truncated whisker:
    # 2% of the visible y span. No library procedure provides an
    # out-of-range marker, so this proportion is set here deliberately.
    .nSkippedBars = 0
    .skippedBars$ = ""
    .nSkippedErrors = 0
    .nTruncated = 0
    .arrowDrop = (.yMax - .yMin) * 0.02

    for .g from 1 to .nGroups
        .xCenter = .g
        .colorIdx = .g

        # v1.19 (C 96): an undefined mean reaching Paint rectangle: aborted the
        # whole figure. Guard before any drawing command, skip the bar, and
        # record it so the omission is reported rather than silent.
        .meanOk = 0
        if emlBarData_mean[.g] <> undefined
            .meanOk = 1
        endif

        if .meanOk = 0
            .nSkippedBars = .nSkippedBars + 1
            if .skippedBars$ <> ""
                .skippedBars$ = .skippedBars$ + ", "
            endif
            .skippedBars$ = .skippedBars$ + emlBarData_label$[.g]
        else
            # Clamp bar top to axis maximum (TODO-055 fix)
            .barTop = min (emlBarData_mean[.g], .yMax)

            # Filled bar
            Paint rectangle: emlSetColorPalette.fill$[.colorIdx], .xCenter - .halfBar, .xCenter + .halfBar, .baseline, .barTop

            # Bar outline
            Colour: emlSetColorPalette.line$[.colorIdx]
            Line width: emlSetAdaptiveTheme.axisLineWidth
            Draw rectangle: .xCenter - .halfBar, .xCenter + .halfBar, .baseline, .barTop

            # Error bar (if enabled and nonzero)
            # v1.19: undefined error is tested explicitly. Previously the
            # compound test relied on "undefined > 0" being false, which
            # dropped the error bar with no record. Nested ifs because
            # and/or do not short-circuit in Praat.
            .errOk = 0
            if .errorMode > 0
                if emlBarData_error[.g] <> undefined
                    if emlBarData_error[.g] > 0
                        .errOk = 1
                    endif
                else
                    .nSkippedErrors = .nSkippedErrors + 1
                endif
            endif

            if .errOk = 1
                Line width: emlSetAdaptiveTheme.dataLineWidth * 0.7
                .errLow = emlBarData_mean[.g] - emlBarData_error[.g]
                .errHigh = emlBarData_mean[.g] + emlBarData_error[.g]

                # v1.19 (C 88): the clamps below used to truncate a whisker at
                # the axis limit with no visual cue, so a bar could look more
                # precise than it is. Record the clip and mark the clipped end
                # with an outward arrowhead instead of a flat cap.
                .lowClipped = 0
                .highClipped = 0

                # Clamp error bar bottom to yMin
                if .errLow < .yMin
                    .errLow = .yMin
                    .lowClipped = 1
                endif

                # Clamp error bar top to yMax (TODO-055 fix)
                if .errHigh > .yMax
                    .errHigh = .yMax
                    .highClipped = 1
                endif

                if .lowClipped = 1
                    .nTruncated = .nTruncated + 1
                endif
                if .highClipped = 1
                    .nTruncated = .nTruncated + 1
                endif

                Draw line: .xCenter, .errLow, .xCenter, .errHigh

                # Lower terminator: flat cap, or arrowhead if clipped
                if .lowClipped = 1
                    Draw line: .xCenter, .errLow, .xCenter - .capWidth, .errLow + .arrowDrop
                    Draw line: .xCenter, .errLow, .xCenter + .capWidth, .errLow + .arrowDrop
                else
                    Draw line: .xCenter - .capWidth, .errLow, .xCenter + .capWidth, .errLow
                endif

                # Upper terminator: flat cap, or arrowhead if clipped
                if .highClipped = 1
                    Draw line: .xCenter, .errHigh, .xCenter - .capWidth, .errHigh - .arrowDrop
                    Draw line: .xCenter, .errHigh, .xCenter + .capWidth, .errHigh - .arrowDrop
                else
                    Draw line: .xCenter - .capWidth, .errHigh, .xCenter + .capWidth, .errHigh
                endif
            endif
        endif
    endfor

    # Expose axis ranges for annotation bridge
    .axisXMin = 0.5
    .axisXMax = max (1, .nGroups) + 0.5   ; clamp: a 0-row table would make left = right
    .axisYMin = .yMin
    .axisYMax = .yMax

    # Step 8: Draw axes with group labels (manual — no @emlDrawAxes)
    @emlDrawInnerBoxIf
    @emlDrawAlignedMarksLeft: .yMin, .yMax, emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks

    # Group labels and x-axis label (pre-measured)
    @emlDrawCategoricalXAxis: .nGroups, .axisXMin, .axisXMax, .yMin, .yMax, .xLabel$
    if emlShowAxisNameY
        Text left: "yes", .yLabel$
    endif

    # Title
    @emlDrawTitle: .title$, .vpW, .vpH, .xMin, .xMax, .yMin, .yMax

    # Step 8B: Disclosures (v1.21)
    #
    # v1.19 built all of this as one semicolon-joined caption and carried it
    # on emlSubtitle$ — the user's own field, which the graphs form asks for
    # and persists to config. It was saved and restored, so the global was
    # never corrupted, but the drawn figure showed the user's subtitle with
    # " | Error bars: +/-1 SE; 2 truncated at axis limit (arrowheads)"
    # appended, whether or not Annotate was ticked, and nothing in the form
    # could turn it off. The facts were right and the channel was wrong.
    #
    # They are now separate disclosures on the two correct channels. Each is
    # emitted only when it has something to report: "No error bars" was
    # printed on every bar chart drawn without them, which told a reader
    # nothing that the absence of error bars had not already told them.
    #
    # THE BAR IS A MEAN. @emlMeasureBarData divides each group's sum by its
    # count, so every bar is an average of the rows in that group — the one
    # fact a bar chart most reliably hides, and the one this procedure never
    # stated. Disclosed whenever at least one group really was averaged; with
    # a single row per group the bar IS the observation and there is nothing
    # to say.
    .nAveragedGroups = 0
    for .g from 1 to .nGroups
        if emlBarData_count[.g] > 1
            .nAveragedGroups = .nAveragedGroups + 1
        endif
    endfor
    if .nAveragedGroups > 0
        @emlDisclose: "Bars show the group mean, not individual values.",
        ... "Use Violin Plot or Box Plot to show the distribution within "
        ... + "each group."
    endif

    if .errorMode = 1
        @emlDisclose: "Error bars: +/-1 SE.", ""
    elsif .errorMode = 2
        @emlDisclose: "Error bars: +/-1 SD.", ""
    elsif .errorMode = 3
        @emlDisclose: "Error bars: " + .errorCol$ + " (custom).", ""
    endif
    if .nTruncated > 0
        @emlDisclose: string$ (.nTruncated)
        ... + " error bar(s) truncated at the axis limit.",
        ... "The truncated ends carry an outward arrowhead instead of a "
        ... + "flat cap. Widen the value range to show them in full."
    endif
    # v1.22: THESE TWO WERE DEAD CODE UNTIL TODAY. @emlMeasureBarData seeded
    # emlBarData_mean[] and emlBarData_error[] to 0 rather than undefined, so
    # the `<> undefined` guards in the bar loop above never fired,
    # .nSkippedBars and .nSkippedErrors were never non-zero, and neither
    # disclosure could be reached. The consequences were the two silences
    # this release closes: a group with no usable observation drew as a bar
    # of height zero — the same picture a measured zero draws — and a whisker
    # whose error was undefined simply did not appear. The sentinel is fixed
    # at the root in @emlMeasureBarData (v3.23) and both guards now fire.
    if .nSkippedErrors > 0
        @emlDisclose: string$ (.nSkippedErrors)
        ... + " error bar(s) not drawn (error undefined).",
        ... "An error bar is undefined when the group holds a single "
        ... + "observation, or when its custom error cell is missing. A bar "
        ... + "with no whisker is not a bar with zero spread."
    endif
    # The group names are carried in .short$, on purpose: which group is
    # missing is the fact that lets a reader tell "no measurement" from
    # "measured zero", and a bare count does not. The bar is OMITTED, not
    # drawn at zero — a measured zero still draws its outline flat on the
    # baseline, so the two are different marks under the same x-axis label.
    # emlBarData_nInvalidGroups now equals .nSkippedBars by construction and
    # is no longer disclosed separately; the v1.21 line that read
    # "N group(s) shown at zero (no usable observation)" described the defect,
    # not the behaviour, and is gone with it.
    if .nSkippedBars > 0
        @emlDisclose: string$ (.nSkippedBars)
        ... + " bar(s) not drawn (no usable observation): "
        ... + .skippedBars$ + ".",
        ... "Those group names appear on the x-axis with nothing above them. "
        ... + "A bar of height zero is a measured zero, not a missing group."
    endif
    if emlBarData_nSkipped > 0
        @emlDisclose: string$ (emlBarData_nSkipped)
        ... + " row(s) skipped (missing or non-numeric value).", ""
    endif

    # Quadrant occupancy for the disclosure block's corner. A bar is not a
    # point cloud: it fills everything between the baseline and its top, so
    # every bar occupies its bottom quadrant and additionally its top
    # quadrant when it rises past the midline. Scoring only the bar TOPS —
    # the point-cloud idiom the other procedures use — would report the
    # bottom half as free when it is solid ink.
    .dxMid = (.xMin + .xMax) / 2
    .dyMid = (.yMin + .yMax) / 2
    .dTL = 0
    .dTR = 0
    .dBL = 0
    .dBR = 0
    for .g from 1 to .nGroups
        if emlBarData_valid[.g] = 1
            if .g < .dxMid
                .dBL = .dBL + 1
                if emlBarData_mean[.g] >= .dyMid
                    .dTL = .dTL + 1
                endif
            else
                .dBR = .dBR + 1
                if emlBarData_mean[.g] >= .dyMid
                    .dTR = .dTR + 1
                endif
            endif
        endif
    endfor
    # A bar chart draws no legend — the group names are the x-axis.
    @emlDiscloseEnd: .xMin, .xMax, .yMin, .yMax, .dTL, .dTR, .dBL, .dBR, ""

    # Step 9: Reset state
    Colour: "Black"
    Line width: 1.0
    Font size: emlSetAdaptiveTheme.bodySize
endproc

# ----------------------------------------------------------------------------
# @emlDrawViolinPlot
# Draws a publication-quality violin plot with kernel density estimation.
# Source: v1.1 (17 Feb 2026), adapted for plugin dispatch signature.
# v1.1 fixes: bracket notation for string arrays, pre-computed indices.
# Calls @emlDrawViolin from eml-graph-procedures.praat for each group.
# ----------------------------------------------------------------------------
# Requires: @emlInitDrawingDefaults (or manual global initialization).
# Reads globals: emlPanelOriginX, emlPanelOriginY (via @emlSetAdaptiveTheme).
procedure emlDrawViolinPlot: .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .groupCol$, .valueCol$, .vMin, .vMax

    # Step 1: Set up theme and palette
    @emlSetAdaptiveTheme: .vpW, .vpH
    @emlSetColorPalette: .colorMode$
    # Categorical x-axis labels must exist before @emlDrawCategoricalXAxis
    # renders them. In the form path the pre-dispatch block has already
    # measured and this is a no-op; from anywhere else it is the difference
    # between a figure and an aborted script. Must come before this
    # procedure sets its own Axes: the measurement installs its own.
    @emlEnsureCategoricalLabels: .objectId, .groupCol$, .vpW, .vpH
    @emlDiscloseBegin: "Violin plot"

    # Sanitize title (Rule 28J)
    @emlSanitizeLabel: .title$
    .title$ = emlSanitizeLabel.result$

    # Step 2: Extract unique group names via single source
    @emlCountGroups: .objectId, .groupCol$
    .nGroups = emlCountGroups.nGroups
    for .g from 1 to .nGroups
        .grpLabel$[.g] = emlCountGroups.groupLabel$[.g]
    endfor

    selectObject: .objectId
    .nRows = Get number of rows

    @emlOptimizePaletteContrast: .nGroups

    # Step 3: Count observations per group and extract values
    for .g from 1 to .nGroups
        .groupCount'.g' = 0
    endfor

    # v1.19 (C 96): blank or non-numeric cells used to be stored as undefined
    # and then handed to @emlDrawViolin -> @emlPercentile -> sort#, which
    # aborts the whole figure. Store only defined values (the pattern already
    # used by @emlDrawGroupedViolin) and record how many rows were dropped.
    # The same reader the analysis uses. See @emlDrawColumnIsClean for what
    # the lenient one cost.
    @emlDrawColumnIsClean: .objectId, .valueCol$
    .cellsClean = emlDrawColumnIsClean.clean

    .nSkippedRows = 0
    for .i from 1 to .nRows
        selectObject: .objectId
        .thisGroup$ = Get value: .i, .groupCol$
        @eml_readCell: .objectId, .i, .valueCol$, .cellsClean
        .thisVal = eml_readCell.value

        if .thisVal = undefined
            .nSkippedRows = .nSkippedRows + 1
        else
            # Find which group this belongs to
            for .g from 1 to .nGroups
                if .thisGroup$ = .grpLabel$[.g]
                    .groupCount'.g' = .groupCount'.g' + 1
                    .c = .groupCount'.g'
                    .groupData'.g'_'.c' = .thisVal
                endif
            endfor
        endif
    endfor

    # Step 4: Compute y-axis range (both 0 = auto)
    .globalMin = undefined
    .globalMax = undefined
    for .g from 1 to .nGroups
        .n = .groupCount'.g'
        for .k from 1 to .n
            .val = .groupData'.g'_'.k'
            if .globalMin = undefined
                .globalMin = .val
                .globalMax = .val
            else
                if .val < .globalMin
                    .globalMin = .val
                endif
                if .val > .globalMax
                    .globalMax = .val
                endif
            endif
        endfor
    endfor

    # v1.19 (C 96): with no usable value anywhere, .globalMin stayed undefined
    # and the undefined axis limits aborted the figure at Axes:. Fall back to
    # a unit axis, as @emlDrawGroupedViolin already does.
    # D111: the fallback was silent. Say so on the same channel and in the
    # same words as @emlDrawTimeSeries and @emlDrawSpaghettiPlot, so an
    # empty frame reads the same whichever figure produced it.
    if .globalMin = undefined
        .globalMin = 0
        .globalMax = 1
        .noDataMsg$ = "NOTE: Violin plot — no usable value; empty axes drawn."
        appendInfoLine: .noDataMsg$
    endif

    # Extend range by largest per-group KDE bandwidth so violin
    # tails do not hit the axis edge. Silverman: h = 0.9 * SD * n^(-0.2)
    .maxBW = 0
    for .g from 1 to .nGroups
        .n = .groupCount'.g'
        if .n >= 4
            .gMean = 0
            for .k from 1 to .n
                .gMean = .gMean + .groupData'.g'_'.k'
            endfor
            .gMean = .gMean / .n
            .gVar = 0
            for .k from 1 to .n
                .gVar = .gVar + (.groupData'.g'_'.k' - .gMean) ^ 2
            endfor
            .gSD = sqrt (.gVar / (.n - 1))
            .bw = 0.9 * .gSD * .n ^ (-0.2)
            if .bw > .maxBW
                .maxBW = .bw
            endif
        endif
    endfor
    .globalMin = .globalMin - .maxBW
    .globalMax = .globalMax + .maxBW
    # Adaptive rounding grid: derive roundTo from a nice step over the data
    # range (the same nice-number logic the gridlines use) so fractional data
    # (proportions, contact quotient, jitter %) is not snapped to a 10-unit grid.
    @emlComputeNiceStep: .globalMax - (.globalMin), emlSetAdaptiveTheme.targetTicksY
    .axisRoundTo = emlComputeNiceStep.step
    @emlComputeAxisRange: .globalMin, .globalMax, .axisRoundTo, 0
    .autoYMin = emlComputeAxisRange.axisMin
    .autoYMax = emlComputeAxisRange.axisMax

    if .vMin = 0 and .vMax = 0
        .yMin = .autoYMin
        .yMax = .autoYMax
    else
        .yMin = .vMin
        .yMax = .vMax
    endif

    # Step 5: Set x-axis range
    .xMin = 0.5
    .xMax = max (1, .nGroups) + 0.5   ; clamp: a 0-row table would make left = right

    # Step 6: Set viewport and axes
    @emlSetPanelViewport
    Axes: .xMin, .xMax, .yMin, .yMax
    # Physical scale for fill patterns: a 45-degree hatch has to be 45
    # degrees ON THE PAGE, not at whatever angle the two axis ranges imply.
    @emlSetPatternScale: .xMin, .xMax, .yMin, .yMax

    # Step 7: Draw horizontal gridlines (if requested)
    # gridMode: 1=Horizontal, 2=Off
    if .gridMode = 1
        @emlDrawHorizontalGridlines: .xMin, .xMax, .yMin, .yMax, emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks
    endif

    # Step 8: Draw each violin
    # v1.19 (C 96): a group with no usable observation produced a zero-length
    # vector, whose percentiles are undefined and abort the drawing command.
    # Skip that group instead, matching @emlDrawGroupedViolin.
    .nEmptyGroups = 0
    for .g from 1 to .nGroups
        # Build data vector for this group
        .n = .groupCount'.g'
        if .n < 1
            .nEmptyGroups = .nEmptyGroups + 1
        else
            .data# = zero# (.n)
            for .k from 1 to .n
                .data# [.k] = .groupData'.g'_'.k'
            endfor

            # Determine color index (cycle through palette)
            .colorIdx = .g

            @emlDrawViolin: .g, .data#, emlSetColorPalette.fill$[.colorIdx],
            ... emlSetColorPalette.line$[.colorIdx], .yMin, .yMax, 0.35,
            ... emlSetColorPalette.pattern[.colorIdx]
        endif
    endfor

    # Jittered points overlay (controlled by global)
    if variableExists ("prev_violinShowJitter")
        if prev_violinShowJitter = 1
            for .g from 1 to .nGroups
                .n = .groupCount'.g'
                # v1.19 (C 96): skip empty groups here too.
                if .n >= 1
                    jitterData# = zero# (.n)
                    for .k from 1 to .n
                        jitterData#[.k] = .groupData'.g'_'.k'
                    endfor
                    .colorIdx = .g
                    @emlDrawJitteredPoints: .g, emlSetColorPalette.line$[.colorIdx], emlSetAdaptiveTheme.markerSize * 0.5, 0.12
                endif
            endfor
        endif
    endif

    # v1.19 (C 96): report anything the guards above dropped, so a thinner
    # figure is never mistaken for the whole data set.
    # v1.21: the wording and the counter idiom are unchanged — this pair is
    # what the other eight procedures were made to match. What changed is the
    # routing: through @emlDisclose, so the same sentence also reaches the
    # figure when the user ticked Annotate.
    if .nSkippedRows > 0
        @emlDisclose: string$ (.nSkippedRows)
        ... + " row(s) skipped (missing or non-numeric value).", ""
    endif
    if .nEmptyGroups > 0
        @emlDisclose: string$ (.nEmptyGroups)
        ... + " group(s) not drawn (no usable observation).", ""
    endif

    # Expose axis ranges for annotation bridge
    .axisXMin = 0.5
    .axisXMax = max (1, .nGroups) + 0.5   ; clamp: a 0-row table would make left = right
    .axisYMin = .yMin
    .axisYMax = .yMax

    # Quadrant occupancy for the disclosure block's corner (v1.21). A violin
    # is a density, so score the observations that made it.
    .dxMid = (.axisXMin + .axisXMax) / 2
    .dyMid = (.yMin + .yMax) / 2
    .dTL = 0
    .dTR = 0
    .dBL = 0
    .dBR = 0
    for .g from 1 to .nGroups
        .dn = .groupCount'.g'
        for .dk from 1 to .dn
            .dv = .groupData'.g'_'.dk'
            if .dv >= .dyMid
                if .g < .dxMid
                    .dTL = .dTL + 1
                else
                    .dTR = .dTR + 1
                endif
            else
                if .g < .dxMid
                    .dBL = .dBL + 1
                else
                    .dBR = .dBR + 1
                endif
            endif
        endfor
    endfor
    # A violin plot draws no legend — the group names are the x-axis.
    @emlDiscloseEnd: .axisXMin, .axisXMax, .yMin, .yMax,
    ... .dTL, .dTR, .dBL, .dBR, ""

    # Step 9: Draw axes with group labels (manual — no @emlDrawAxes)
    Colour: emlSetAdaptiveTheme.axisColor$
    Line width: emlSetAdaptiveTheme.axisLineWidth

    @emlDrawInnerBoxIf
    @emlDrawAlignedMarksLeft: .yMin, .yMax, emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks

    # Group labels and x-axis label (pre-measured)
    @emlDrawCategoricalXAxis: .nGroups, .axisXMin, .axisXMax, .yMin, .yMax, .xLabel$
    if emlShowAxisNameY
        Text left: "yes", .yLabel$
    endif

    @emlDrawTitle: .title$, .vpW, .vpH, .xMin, .xMax, .yMin, .yMax

    # Step 10: Reset state
    Colour: "Black"
    Line width: 1.0
    Font size: emlSetAdaptiveTheme.bodySize

    ; ---------------------------------------------------------------------
    ; RECORD WORKFLOW. Inert unless a recording is running.
    ;
    ; PLACED IN THE DRAW PROCEDURE, NOT IN THE FORM, and that is the whole
    ; reason the graph round trip can run at all. The form is GUI-only --
    ; every wrapper uses beginPause:, which needs a display -- so a recorder
    ; hooked there could be exercised interactively and never headlessly, and
    ; the check that the emitted script reproduces the figure could never be
    ; automated. The draw procedure has no dialogs, so recording here means
    ; the SAME seam serves the GUI session and the replay.
    ;
    ; It also matches what is emitted: the code line names this procedure,
    ; so the record and the artifact describe one thing.
    ;
    ; This is the FIRST of thirteen draw procedures to be wired, kept
    ; deliberately to one until the round trip proves the pattern -- the same
    ; way @emlRunAnovaAnalysis was the first of thirteen orchestrators.
    ; GUARDED ON EXISTENCE, NOT JUST ON STATE, and that distinction is the
    ; difference between a recordable draw layer and one that REQUIRES the
    ; recorder.
    ;
    ; The first cut called @emlRecordViolin unconditionally, which made
    ; eml-draw-procedures.praat depend on eml-record.praat: seven include
    ; sets had to be amended and the stress suite went 39/39 -> 26/39 with
    ; "Procedure emlRecordInit not found". That is a shipped API break --
    ; every hand-written user script and every PraatGen-generated script that
    ; loads the draw layer would have had to learn a new include, for a
    ; feature it does not use.
    ;
    ; Praat only errors on an undefined procedure when it EXECUTES the call,
    ; so a call inside a false branch costs nothing and raises nothing.
    ; Measured 10 Aug 2026: a guarded @thisProcedureDoesNotExist runs to the
    ; end of the script cleanly.
    ;
    ; emlRecordActive exists only once @emlRecordInit has run, and that
    ; happens when something loaded the recorder and started it. So this
    ; reads: record if a recorder is present AND recording. With no recorder
    ; loaded -- the default, and what every existing caller does -- the draw
    ; layer is exactly what it was before.
    if variableExists ("emlRecordActive")
        if emlRecordActive = 1
            @emlRecordViolin: .objectId, .title$, .xLabel$, .yLabel$,
            ... .vpW, .vpH, .colorMode$, .gridMode, .groupCol$, .valueCol$,
            ... .vMin, .vMax, .nGroups
        endif
    endif
endproc


# ----------------------------------------------------------------------------
# @emlRecordViolin
# The recording half of @emlDrawViolinPlot, kept separate so the draw
# procedure gains one line rather than thirty.
#
# Every argument is passed through at its RESOLVED value. A record saying a
# viewport was "the default" is not reproducible once the default changes; a
# record saying 6 by 4 is.
# ----------------------------------------------------------------------------
procedure emlRecordViolin: .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH,
... .colorMode$, .gridMode, .groupCol$, .valueCol$, .vMin, .vMax, .nGroups
    ; NO `goto` AND NO `label` IN THIS FILE. v27 asserts that as a property of
    ; the whole draw library and it caught this procedure's first draft, which
    ; used the same early-exit shape the recorder uses everywhere else.
    ;
    ; The rule is not stylistic. Praat's goto is unconditional and forward
    ; jumps are unrestricted, so a guard written as `goto <end>` silently
    ; skips every drawing command between it and the label -- which is
    ; precisely how the histogram came to write a blank page. The invariant
    ; is cheap to keep and the alternative was a class of blank-figure bug
    ; that is invisible until someone opens the PNG.
    ; Reached only through the existence-guarded call site above, so the
    ; recorder is loaded and running by the time this runs.
    @emlRecordSource: .objectId

    @emlPhrase: "draw.intent", "Violin plot", .valueCol$, .groupCol$,
    ... string$ (.nGroups), "", ""
    .intent$ = emlPhrase.result$

    ; Stream C: what the figure does not say about itself. A violin is a
    ; kernel density estimate, and the bandwidth is a choice -- a reader
    ; comparing two figures drawn at different bandwidths is comparing
    ; the smoothing as much as the data.
    .caveat$ = "Violin width is a kernel density estimate, not a count."

    ; The axis is recorded as RESOLVED numbers, never as "auto". Auto is
    ; a function of the data, so a re-run on edited data would silently
    ; draw a different axis and the record would not say so.
    .code$ = "@emlDrawViolinPlot: table, """ + .title$ + """, """
    ... + .xLabel$ + """, """ + .yLabel$ + """, " + string$ (.vpW) + ", "
    ... + string$ (.vpH) + ", """ + .colorMode$ + """, "
    ... + string$ (.gridMode) + ", """ + .groupCol$ + """, """
    ... + .valueCol$ + """, " + fixed$ (emlDrawViolinPlot.yMin, 6) + ", "
    ... + fixed$ (emlDrawViolinPlot.yMax, 6)

    .api$ = "In the GUI: EML Graphs..., type Violin Plot,"
    ... + newline$ + "Group column """ + .groupCol$
    ... + """, Value column """ + .valueCol$ + """."

    @emlRecordStep: "draw", .intent$, .caveat$, .code$, .api$

    @emlRecordResult: "Axis resolved to "
    ... + fixed$ (emlDrawViolinPlot.yMin, 4) + " .. "
    ... + fixed$ (emlDrawViolinPlot.yMax, 4) + " over "
    ... + string$ (.nGroups) + " groups."
endproc


# ============================================================================
# @emlDrawScatterPlot
# ============================================================================
# Draws a scatter plot from Table with X and Y columns.
# Optional group column for color-coded points.
# Handles all annotation internally: correlation stats, regression lines,
# formula display, and per-group regression.
#
# Reads globals: scatterDotSize, scatterRegressionLine, scatterShowFormula,
#   scatterShowDots, annotate, annotCorrType$, annotStyle$, annotShowNS,
#   annotCorrType$, annotStyle$, annotAlpha
#
# Arguments:
#   .objectId    — Table object ID
#   .title$      — figure title
#   .xLabel$     — x-axis label
#   .yLabel$     — y-axis label
#   .vpW, .vpH   — viewport dimensions
#   .colorMode$  — "color" or "bw"
#   .gridMode    — 1 = both, 2 = horizontal only, 3 = vertical only, 4 = off
#   .colX$       — x column name
#   .colY$       — y column name
#   .groupCol$   — group column name ("" for no grouping)
#   .xMin, .xMax — axis x range (both 0 = auto)
#   .yMin, .yMax — axis y range (both 0 = auto)
#   .annotate    — 1 = draw annotations, 0 = skip
# ============================================================================
# Requires: @emlInitDrawingDefaults (or manual global initialization).
# Reads globals: emlPanelOriginX, emlPanelOriginY (via @emlSetAdaptiveTheme).
procedure emlDrawScatterPlot: .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .colX$, .colY$, .groupCol$, .xMin, .xMax, .yMin, .yMax, .annotate
    # Step 1: Theme and palette
    @emlSetAdaptiveTheme: .vpW, .vpH
    @emlSetColorPalette: .colorMode$
    # @emlInitAlphaSprites is idempotent and cheap, but until 6 Aug 2026 the
    # only call was in eml-graphs-form.praat, so this procedure aborted with
    # "Unknown variable: emlInitAlphaSprites.available" for every caller that
    # was not the form. Calling it here makes the procedure self-sufficient;
    # in the form path the initialised flag short-circuits it immediately.
    @emlInitAlphaSprites
    # v1.21: @emlDiscloseBegin only records state; it does not clear the
    # annotation block. This procedure clears it itself at Step 7 and renders
    # it itself at the end of each path, so the disclosures added below join
    # the correlation and formula lines in the SAME box rather than opening a
    # second one. That is also why this procedure never calls
    # @emlDiscloseEnd.
    @emlDiscloseBegin: "Scatter plot"

    # Step 2: Extract all data (for axis computation and ungrouped stats)
    selectObject: .objectId
    .nRows = Get number of rows
    .xData# = zero# (.nRows)
    .yData# = zero# (.nRows)
    .nValid = 0

    # Same reader as the analysis. See @emlDrawColumnIsClean.
    @emlDrawColumnIsClean: .objectId, .colX$
    .cleanXObj = emlDrawColumnIsClean.clean
    @emlDrawColumnIsClean: .objectId, .colY$
    .cleanYObj = emlDrawColumnIsClean.clean
    for .i from 1 to .nRows
        selectObject: .objectId
        @eml_readCell: .objectId, .i, .colX$, .cleanXObj
        .xVal = eml_readCell.value
        @eml_readCell: .objectId, .i, .colY$, .cleanYObj
        .yVal = eml_readCell.value
        if .xVal <> undefined and .yVal <> undefined
            .nValid = .nValid + 1
            .xData#[.nValid] = .xVal
            .yData#[.nValid] = .yVal
        endif
    endfor

    if .nValid < 2
        appendInfoLine: "WARNING: Fewer than 2 valid data points for scatter plot."
    endif
    # v1.21: a scatter plot with a hole in it looks exactly like a scatter
    # plot. Count what did not become a dot; disclosed at the end of whichever
    # path runs.
    .nSkippedRows = .nRows - .nValid

    # Trim to valid length (avoids trailing zeros biasing corner selection)
    if .nValid > 0 and .nValid < .nRows
        .xTmp# = zero# (.nValid)
        .yTmp# = zero# (.nValid)
        for .i from 1 to .nValid
            .xTmp#[.i] = .xData#[.i]
            .yTmp#[.i] = .yData#[.i]
        endfor
        .xData# = .xTmp#
        .yData# = .yTmp#
    endif

    # Step 3: Compute data extent and axis ranges
    if .nValid > 0
        .dataXMin = .xData#[1]
        .dataXMax = .xData#[1]
        .dataYMin = .yData#[1]
        .dataYMax = .yData#[1]
        for .i from 2 to .nValid
            if .xData#[.i] < .dataXMin
                .dataXMin = .xData#[.i]
            endif
            if .xData#[.i] > .dataXMax
                .dataXMax = .xData#[.i]
            endif
            if .yData#[.i] < .dataYMin
                .dataYMin = .yData#[.i]
            endif
            if .yData#[.i] > .dataYMax
                .dataYMax = .yData#[.i]
            endif
        endfor
    else
        .dataXMin = 0
        .dataXMax = 1
        .dataYMin = 0
        .dataYMax = 1
    endif

    if .xMin = 0 and .xMax = 0
        # Adaptive rounding grid: derive roundTo from a nice step over the data
        # range (the same nice-number logic the gridlines use) so fractional data
        # (proportions, reaction times, jitter %) is not snapped to the integer grid.
        @emlComputeNiceStep: .dataXMax - .dataXMin, emlSetAdaptiveTheme.targetTicksX
        .xRoundTo = emlComputeNiceStep.step
        @emlComputeAxisRange: .dataXMin, .dataXMax, .xRoundTo, 0
        .axisXMin = emlComputeAxisRange.axisMin
        .axisXMax = emlComputeAxisRange.axisMax
    else
        .axisXMin = .xMin
        .axisXMax = .xMax
    endif

    if .yMin = 0 and .yMax = 0
        # Adaptive rounding grid: derive roundTo from a nice step over the data
        # range (the same nice-number logic the gridlines use) so fractional data
        # (proportions, reaction times, jitter %) is not snapped to the integer grid.
        @emlComputeNiceStep: .dataYMax - .dataYMin, emlSetAdaptiveTheme.targetTicksY
        .yRoundTo = emlComputeNiceStep.step
        @emlComputeAxisRange: .dataYMin, .dataYMax, .yRoundTo, 0
        .axisYMin = emlComputeAxisRange.axisMin
        .axisYMax = emlComputeAxisRange.axisMax
    else
        .axisYMin = .yMin
        .axisYMax = .yMax
    endif

    # Step 4: Set viewport and axes
    @emlSetPanelViewport
    Axes: .axisXMin, .axisXMax, .axisYMin, .axisYMax
    # World-per-inch for the current axes. @emlDrawMarker needs it on BOTH
    # axes or a square comes out as a rectangle stretched by the axis aspect
    # ratio; the alpha-sprite path needed the same numbers and got them from
    # @emlSetAlphaDotGeometry.
    @emlSetPatternScale: .axisXMin, .axisXMax, .axisYMin, .axisYMax

    # Step 5: Gridlines
    # gridMode: 1=Both, 2=Horizontal only, 3=Vertical only, 4=Off
    if .gridMode = 1
        @emlDrawGridlines: .axisXMin, .axisXMax, .axisYMin, .axisYMax, emlSetAdaptiveTheme.targetTicksX, emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks
    elsif .gridMode = 2
        @emlDrawHorizontalGridlines: .axisXMin, .axisXMax, .axisYMin, .axisYMax, emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks
    elsif .gridMode = 3
        @emlDrawVerticalGridlines: .axisXMin, .axisXMax, .axisYMin, .axisYMax, emlSetAdaptiveTheme.targetTicksX, emlSetAdaptiveTheme.useMinorTicks
    endif

    # Step 6: Dot size from global
    if scatterDotSize = 1
        .sizeScale = 0.008
    elsif scatterDotSize = 3
        .sizeScale = 0.025
    else
        .sizeScale = 0.015
    endif
    .markerRadius = emlSetAdaptiveTheme.markerSize * .sizeScale
    .xRange = .axisXMax - .axisXMin
    .radiusWorld = .markerRadius * .xRange
    # The same radius in INCHES, which is what @emlDrawMarker takes -- a
    # square and a triangle need a physical size on both axes, not an x-world
    # one. On a 6 x 4 figure this is 0.035 / 0.065 / 0.108 inches for the
    # three dot sizes, i.e. 21 / 39 / 65 pixels across at 300 dpi.
    .markerHalfIn = .radiusWorld
    if emlPatWorldPerInchX > 0
        .markerHalfIn = .radiusWorld / emlPatWorldPerInchX
    endif

    # Step 6B: Alpha dot geometry (aspect-corrected for circular dots)
    @emlSetAlphaDotGeometry: .axisXMin, .axisXMax, .axisYMin, .axisYMax, emlSetAdaptiveTheme.innerLeft, emlSetAdaptiveTheme.innerRight, emlSetAdaptiveTheme.innerTop, emlSetAdaptiveTheme.innerBottom, .radiusWorld

    # Step 6C: Auto-transparency decision
    # Alpha always on when sprites available — density benefits from transparency
    #
    # v1.24 — THE SPRITE SET IS CIRCLES ONLY. plugin/sprites/ holds 168 dot
    # PNGs, one per (hue, alpha, size); there is no shape axis in the naming
    # scheme and none in emlSetColorPalette.sprite$[], which indexes hue.
    # So on macOS and Windows, where emlInitAlphaSprites.available is 1, the
    # sprite branch would stamp a translucent CIRCLE for every group and the
    # marker shape — the only thing that tells group 9 from group 1 — would
    # never reach the page, on those two platforms only. That is a worse
    # failure than losing transparency, and it is invisible from Linux.
    #
    # Above eight groups the whole figure therefore drops to native markers.
    # Not group-by-group: a scatter with translucent circles for groups 1-8
    # and opaque triangles for 9-24 reads as two different kinds of data.
    # The switch is made in the grouped path, where .nGroups is known.
    .useAlpha = emlInitAlphaSprites.available
    .alphaLevel$ = "a50"
    if scatterRegressionLine = 1
        # More transparent when regression lines present so lines read clearly
        .alphaLevel$ = "a30"
    endif

    # Regression line color (mode-aware)
    if .colorMode$ = "bw"
        .regColor$ = "{0.4, 0.4, 0.4}"
    else
        .regColor$ = "{0.5, 0.3, 0.3}"
    endif

    # Step 7: Initialize annotation block
    annotBlockN = 0

    # Point colour: in B/W mode a lighter ink than the series stroke, so a
    # regression line drawn over a cloud still reads as a line.
    #
    # v1.24: that used to be .fill$, which is a BODY colour meant to be read
    # inside an outline, and the widened grey ramp takes its light end to 0.94
    # -- six hundredths off the white page, invisible as a bare dot with no
    # outline around it. (At the old 0.90 it was barely better.) .lightLine$
    # is the midpoint of the fill and the stroke: 0.79 down to 0.05 across the
    # eight slots, a wider spread than the fills it replaces AND darker at the
    # light end, which is the only end that was ever in question.
    if .colorMode$ = "bw"
        for .c from 1 to 100
            .pointColor$[.c] = emlSetColorPalette.lightLine$[.c]
        endfor
    else
        for .c from 1 to 100
            .pointColor$[.c] = emlSetColorPalette.line$[.c]
        endfor
    endif

    if .groupCol$ = ""
        # ==============================================================
        # UNGROUPED PATH
        # ==============================================================

        # Plot points
        if scatterShowDots = 1
            for .i from 1 to .nValid
                if .useAlpha = 1 and emlInitAlphaSprites.available = 1
                    @emlDrawAlphaDot: .xData#[.i], .yData#[.i], 1, .colorMode$, .alphaLevel$, .pointColor$[1]
                else
                    # Ungrouped: palette slot 1, which is marker 1, a circle.
                    # Written through @emlDrawMarker anyway so the ungrouped
                    # and grouped paths cannot drift apart in dot size.
                    @emlDrawMarker: .xData#[.i], .yData#[.i], .markerHalfIn,
                    ... emlSetColorPalette.marker[1], .pointColor$[1]
                endif
            endfor
        endif

        # Compute correlations and build annotation block
        .havePearson = 0
        .pearsonR = 0

        # Correlation annotations (gated by annotate)
        if .annotate = 1 and .nValid >= 3

            # --- Pearson ---
            .pearsonP = 0
            if annotCorrType$ = "pearson" or annotCorrType$ = "both"
                @emlPearsonCorrelation: .xData#, .yData#, 2
                if emlPearsonCorrelation.error$ = ""
                    .havePearson = 1
                    .pearsonR = emlPearsonCorrelation.r
                    .pearsonP = emlPearsonCorrelation.p

                    # Format p-value per annotation style setting
                    @emlFormatAnnotLabel: .pearsonP, 0, annotStyle$, 0, ""
                    .pText$ = emlFormatAnnotLabel.result$

                    # Annotation block line (Picture)
                    .rSq = .pearsonR * .pearsonR
                    annotBlockN = annotBlockN + 1
                    annotBlockLabel$[annotBlockN] = "r = " + fixed$ (.pearsonR, 3) + ", R² = " + fixed$ (.rSq, 3) + ", " + .pText$
                    annotBlockDraw$[annotBlockN] = "%r = " + fixed$ (.pearsonR, 3) + ", %R² = " + fixed$ (.rSq, 3) + ", " + .pText$
                endif
            endif

            # --- Spearman ---
            .haveSpearman = 0
            .spearmanR = 0
            .spearmanP = 0
            if annotCorrType$ = "spearman" or annotCorrType$ = "both"
                @emlSpearmanCorrelation: .xData#, .yData#, 2
                if emlSpearmanCorrelation.error$ = ""
                    .haveSpearman = 1
                    .spearmanR = emlSpearmanCorrelation.rho
                    .spearmanP = emlSpearmanCorrelation.p

                    @emlFormatAnnotLabel: .spearmanP, 0, annotStyle$, 0, ""
                    .pText$ = emlFormatAnnotLabel.result$

                    annotBlockN = annotBlockN + 1
                    annotBlockLabel$[annotBlockN] = "rs = " + fixed$ (.spearmanR, 3) + ", " + .pText$
                    annotBlockDraw$[annotBlockN] = "%%r%_s = " + fixed$ (.spearmanR, 3) + ", " + .pText$
                endif
            endif
        endif

        # --- Rich Info window output via shared reporters (ungrouped) ---
        # v1.19: .reportedOLS records whether the OLS regression report was
        # actually emitted, so the drawn line can be forced to the same
        # estimator (see the regression-line block below).
        .reportedOLS = 0
        if .annotate = 1 and .nValid >= 3
            selectObject: .objectId
            .tableName$ = selected$ ("Table")
            # Correlation reporter (Analysis = Correlation or Both)
            if (scatterAnalysisType = 1 or scatterAnalysisType = 3) and annotCorrType$ <> ""
                @emlReportCorrelationAnalysis: .tableName$,
                ... .colX$, .colY$, .nValid, annotCorrType$
            endif
            # Regression reporter (Analysis = Regression or Both)
            if scatterAnalysisType >= 2
                @emlLinearRegression: .xData#, .yData#
                if emlLinearRegression.error$ = ""
                    @emlReportRegressionAnalysis: .tableName$,
                    ... .colY$, .colX$, .nValid, 0
                    .reportedOLS = 1
                endif
            endif
        endif

        # --- Regression line (independent of annotate) ---
        if scatterRegressionLine = 1 and .nValid >= 3
            # Choose estimator based on correlation type.
            # v1.19: when the OLS regression report has already been emitted,
            # the drawn line must be the OLS line too — otherwise the figure
            # shows a Theil-Sen fit while the Info window reports OLS
            # coefficients. Reported estimator and drawn estimator are now
            # always identical.
            .useTheilSen = 0
            if annotCorrType$ = "spearman"
                if .reportedOLS = 0
                    .useTheilSen = 1
                endif
            endif
            if .useTheilSen = 1
                # Theil-Sen: robust estimator, coherent with rank-based Spearman
                @emlTheilSen: .xData#, .yData#
                if emlTheilSen.error$ = ""
                    .slope = emlTheilSen.slope
                    .intercept = emlTheilSen.intercept
                    .lineMethod$ = "Theil-Sen"
                else
                    .slope = undefined
                    .lineMethod$ = "error"
                endif
            else
                # OLS: standard for Pearson contexts
                if .havePearson = 0
                    @emlPearsonCorrelation: .xData#, .yData#, 2
                    if emlPearsonCorrelation.error$ = ""
                        .pearsonR = emlPearsonCorrelation.r
                    endif
                endif

                .meanX = mean (.xData#)
                .meanY = mean (.yData#)
                .sdX = stdev (.xData#)
                .sdY = stdev (.yData#)

                if .sdX > 0
                    .slope = .pearsonR * (.sdY / .sdX)
                    .intercept = .meanY - .slope * .meanX
                    .lineMethod$ = "OLS"
                else
                    .slope = undefined
                    .lineMethod$ = "error"
                endif
            endif

            if .slope <> undefined
                @emlDrawRegressionLine: .dataXMin, .dataXMax, .slope, .intercept, .axisYMin, .axisYMax, .regColor$

                # Formula to Info window.
                # v1.19: disclosure is unconditional — the estimator behind
                # the drawn line is always named, including when the
                # regression reporter has fired. Previously this was gated on
                # scatterAnalysisType < 2, suppressing the estimator name in
                # exactly the case where a reported fit was on screen.
                .lineEqn$ = .lineMethod$ + " fitted line: y = "
                ... + fixed$ (.slope, 4) + "x + " + fixed$ (.intercept, 4)
                appendInfoLine: .lineEqn$

                # Formula on graph if requested (independent of annotate)
                # v1.19: on-graph formula is labelled with the estimator.
                if scatterShowFormula = 1
                    annotBlockN = annotBlockN + 1
                    .methodTag$ = .lineMethod$ + ": "
                    if .lineMethod$ = "OLS" and .pearsonR <> undefined
                        .rSqAnnot = .pearsonR * .pearsonR
                        .formulaStr$ = .methodTag$ + "y = " + fixed$ (.slope, 4) + "x + " + fixed$ (.intercept, 4) + "  (R² = " + fixed$ (.rSqAnnot, 3) + ")"
                        annotBlockLabel$[annotBlockN] = .formulaStr$
                        annotBlockDraw$[annotBlockN] = .methodTag$ + "%y = " + fixed$ (.slope, 4) + "%x + " + fixed$ (.intercept, 4) + "  (%R² = " + fixed$ (.rSqAnnot, 3) + ")"
                    else
                        .formulaStr$ = .methodTag$ + "y = " + fixed$ (.slope, 4) + "x + " + fixed$ (.intercept, 4)
                        annotBlockLabel$[annotBlockN] = .formulaStr$
                        annotBlockDraw$[annotBlockN] = .methodTag$ + "%y = " + fixed$ (.slope, 4) + "%x + " + fixed$ (.intercept, 4)
                    endif
                endif
            endif
        endif

        # Disclosure (v1.21) — joins the correlation and formula lines in
        # this path's own block, and only when the user ticked Annotate.
        if .nSkippedRows > 0
            @emlDisclose: string$ (.nSkippedRows)
            ... + " row(s) skipped (missing or non-numeric value).", ""
        endif

        # Draw annotation block
        if annotBlockN > 0
            .xMidQ = (.axisXMin + .axisXMax) / 2
            .yMidQ = (.axisYMin + .axisYMax) / 2
            .qTL = 0
            .qTR = 0
            .qBL = 0
            .qBR = 0
            for .qi from 1 to .nValid
                if .yData#[.qi] >= .yMidQ
                    if .xData#[.qi] < .xMidQ
                        .qTL = .qTL + 1
                    else
                        .qTR = .qTR + 1
                    endif
                else
                    if .xData#[.qi] < .xMidQ
                        .qBL = .qBL + 1
                    else
                        .qBR = .qBR + 1
                    endif
                endif
            endfor
            @emlPlaceElements: .qTL, .qTR, .qBL, .qBR, .xMidQ, 1
            @emlDrawAnnotationBlock: emlPlaceElements.corner1$, .axisXMin, .axisXMax, .axisYMin, .axisYMax, emlSetAdaptiveTheme.annotSize
        endif

    else
        # ==============================================================
        # GROUPED PATH
        # ==============================================================

        @emlCountGroups: .objectId, .groupCol$
        .nGroups = emlCountGroups.nGroups

        # The sprite set has no squares and no triangles (Step 6C). Once the
        # ninth group exists, the shape is carrying information the sprites
        # cannot, so the sprites go.
        if .nGroups > emlSetColorPalette.nHues
            .useAlpha = 0
        endif

        @emlOptimizePaletteContrast: .nGroups

        # Re-read the point colours AFTER the contrast optimisation.
        #
        # 6 Aug 2026. .pointColor$[] is filled near the top of this procedure,
        # before the group count is even known, and @emlOptimizePaletteContrast
        # then OVERWRITES emlSetColorPalette.line$[1..n] with a different
        # ordering. The legend below reads the optimised array; the dots read
        # the stale cache. Every grouped scatter plot therefore shipped a
        # legend that disagreed with its own points. With three groups the
        # optimiser skips sky blue as too close to blue and gives group 3
        # green: the legend said green, the points were sky blue, and a reader
        # matching swatch to cloud had no way to tell.
        #
        # This is not masked by the sprite path. plugin/sprites/ DOES exist
        # (204 tracked PNGs since a31a669; the 6 Aug audit note saying it never
        # has is wrong), but @emlInitAlphaSprites gates on the platform and
        # returns .available = 0 on anything that is not macOS or Windows, so
        # on the machine this is measured on every dot goes through the
        # .pointColor$ fallback. On macOS and Windows it does not, which is
        # why the sprite branch is disabled above eight groups -- see Step 6C.
        if .colorMode$ = "bw"
            for .c from 1 to 100
                .pointColor$[.c] = emlSetColorPalette.lightLine$[.c]
            endfor
        else
            for .c from 1 to 100
                .pointColor$[.c] = emlSetColorPalette.line$[.c]
            endfor
        endif

        # Set up legend (use line$ for visual weight match with dots)
        #
        # v1.24: the key carries the MARKER SHAPE as well as the hue. Above
        # eight groups the hue repeats by construction -- group 9 is group 1's
        # blue -- and until the key showed the shape it said the two were the
        # same series. legendMarkerLine = 0: a scatter is bare points, no
        # connecting line, and the key must not imply one.
        legendMarkered = 1
        legendMarkerLine = 0
        legendN = .nGroups
        for .g from 1 to .nGroups
            .colorIdx = .g
            legendColor$[.g] = emlSetColorPalette.line$[.colorIdx]
            legendMarker[.g] = emlSetColorPalette.marker[.colorIdx]
            @emlSanitizeLabel: emlCountGroups.groupLabel$[.g]
            legendLabel$[.g] = emlSanitizeLabel.result$
        endfor

        # Plot all points (color by group)
        if scatterShowDots = 1
            for .i from 1 to .nRows
                selectObject: .objectId
                @eml_readCell: .objectId, .i, .colX$, .cleanXObj
                .xVal = eml_readCell.value
                @eml_readCell: .objectId, .i, .colY$, .cleanYObj
                .yVal = eml_readCell.value
                if .xVal <> undefined and .yVal <> undefined
                    .grp$ = Get value: .i, .groupCol$
                    .gIdx = 1
                    for .g from 1 to .nGroups
                        if emlCountGroups.groupLabel$[.g] = .grp$
                            .gIdx = .g
                        endif
                    endfor
                    .colorIdx = .gIdx
                    if .useAlpha = 1 and emlInitAlphaSprites.available = 1
                        @emlDrawAlphaDot: .xVal, .yVal, .gIdx, .colorMode$, .alphaLevel$, .pointColor$[.colorIdx]
                    else
                        @emlDrawMarker: .xVal, .yVal, .markerHalfIn,
                        ... emlSetColorPalette.marker[.colorIdx],
                        ... .pointColor$[.colorIdx]
                    endif
                endif
            endfor
        endif

        # Per-group correlations and regression lines
        # Per-group statistics and regression lines
        #
        # v1.22 — THE OVER-CAP BOX. Each group can contribute THREE lines to
        # the annotation block: a Pearson line, a Spearman line (Correlation
        # type = Both) and a fitted-line formula. None of the three went
        # through @emlDisclose, so none of them was subject to its 20-line
        # budget: they were written straight into annotBlockN, and
        # @emlDrawAnnotationBlock renders whatever it is handed. Measured
        # 7 Aug 2026 on eight groups: annotBlockN = 24, and the box ran from
        # the top of the panel, through the x-axis, and off the bottom edge
        # of the figure. Two lines of it were never on the page at all, and
        # the dropped-row disclosure that @emlDisclose tried to add
        # afterwards was refused by the budget and vanished — so the figure
        # that overflowed was also the figure that stopped confessing.
        #
        # The lines are now BUFFERED here and committed to the block after
        # the loop, all or none. All-or-none, rather than "fill to twenty",
        # because a truncated per-group box is worse than no per-group box:
        # it is indistinguishable from a complete one, and a reader counting
        # six group names in the corner of an eight-group figure has no way
        # to know two are missing. When they do not fit, every line is
        # printed to the Info window instead and the figure says so. See the
        # commit site below the loop.
        .pgN = 0
        if .annotate = 1 or scatterRegressionLine = 1

            for .g from 1 to .nGroups
                # Extract this group's x/y data
                .gN = 0
                .gXData# = zero# (.nRows)
                .gYData# = zero# (.nRows)
                for .i from 1 to .nRows
                    selectObject: .objectId
                    .grp$ = Get value: .i, .groupCol$
                    if .grp$ = emlCountGroups.groupLabel$[.g]
                        @eml_readCell: .objectId, .i, .colX$, .cleanXObj
                        .xVal = eml_readCell.value
                        @eml_readCell: .objectId, .i, .colY$, .cleanYObj
                        .yVal = eml_readCell.value
                        if .xVal <> undefined and .yVal <> undefined
                            .gN = .gN + 1
                            .gXData#[.gN] = .xVal
                            .gYData#[.gN] = .yVal
                        endif
                    endif
                endfor

                @emlSanitizeLabel: emlCountGroups.groupLabel$[.g]
                .groupDispLabel$ = emlSanitizeLabel.result$

                if .gN >= 3
                    # Trim vectors
                    .gXTrim# = zero# (.gN)
                    .gYTrim# = zero# (.gN)
                    for .j from 1 to .gN
                        .gXTrim#[.j] = .gXData#[.j]
                        .gYTrim#[.j] = .gYData#[.j]
                    endfor

                    .gHavePearson = 0
                    .gPearsonR = 0

                    # --- Per-group Pearson (annotation) ---
                    if .annotate = 1
                        .gPearsonP = 0
                        if annotCorrType$ = "pearson" or annotCorrType$ = "both"
                            @emlPearsonCorrelation: .gXTrim#, .gYTrim#, 2
                            if emlPearsonCorrelation.error$ = ""
                                .gHavePearson = 1
                                .gPearsonR = emlPearsonCorrelation.r
                                .gPearsonP = emlPearsonCorrelation.p

                                @emlFormatAnnotLabel: .gPearsonP, 0, annotStyle$, 0, ""
                                .pText$ = emlFormatAnnotLabel.result$

                                .pgN = .pgN + 1
                                .pgLabel$[.pgN] = .groupDispLabel$ + ": r = " + fixed$ (.gPearsonR, 3) + ", " + .pText$
                                .pgDraw$[.pgN] = .groupDispLabel$ + ": %r = " + fixed$ (.gPearsonR, 3) + ", " + .pText$
                            endif
                        endif

                        # --- Per-group Spearman (annotation) ---
                        if annotCorrType$ = "spearman" or annotCorrType$ = "both"
                            @emlSpearmanCorrelation: .gXTrim#, .gYTrim#, 2
                            if emlSpearmanCorrelation.error$ = ""
                                .gSpearmanR = emlSpearmanCorrelation.rho
                                .gSpearmanP = emlSpearmanCorrelation.p

                                @emlFormatAnnotLabel: .gSpearmanP, 0, annotStyle$, 0, ""
                                .pText$ = emlFormatAnnotLabel.result$

                                .pgN = .pgN + 1
                                .pgLabel$[.pgN] = .groupDispLabel$ + ": rs = " + fixed$ (.gSpearmanR, 3) + ", " + .pText$
                                .pgDraw$[.pgN] = .groupDispLabel$ + ": %%r%_s = " + fixed$ (.gSpearmanR, 3) + ", " + .pText$
                            endif
                        endif
                    endif

                    # --- Rich Info window output via shared reporters ---
                    # v1.19: .gReportedOLS records whether the OLS regression
                    # report was emitted for this group, so the group's drawn
                    # line can be forced to the same estimator.
                    .gReportedOLS = 0
                    if .annotate = 1
                        selectObject: .objectId
                        .gTableName$ = selected$ ("Table")
                        # Correlation reporter (Analysis = Correlation or Both)
                        if (scatterAnalysisType = 1 or scatterAnalysisType = 3) and annotCorrType$ <> ""
                            @emlReportCorrelationAnalysis: .gTableName$
                            ... + " -- " + .groupDispLabel$,
                            ... .colX$, .colY$, .gN, annotCorrType$
                        endif
                        # Regression reporter (Analysis = Regression or Both)
                        if scatterAnalysisType >= 2
                            @emlLinearRegression: .gXTrim#, .gYTrim#
                            if emlLinearRegression.error$ = ""
                                @emlReportRegressionAnalysis: .gTableName$
                                ... + " -- " + .groupDispLabel$,
                                ... .colY$, .colX$, .gN, 0
                                .gReportedOLS = 1
                            endif
                        endif
                    endif

                    # --- Per-group regression line (independent of annotate) ---
                    if scatterRegressionLine = 1
                        # v1.19: same estimator for reported and drawn — when
                        # the OLS report fired for this group, the drawn line
                        # is OLS too.
                        .gUseTheilSen = 0
                        if annotCorrType$ = "spearman"
                            if .gReportedOLS = 0
                                .gUseTheilSen = 1
                            endif
                        endif
                        .gLineMethod$ = "OLS"
                        if .gUseTheilSen = 1
                            # Theil-Sen for Spearman context
                            .gLineMethod$ = "Theil-Sen"
                            @emlTheilSen: .gXTrim#, .gYTrim#
                            if emlTheilSen.error$ = ""
                                .gSlope = emlTheilSen.slope
                                .gIntercept = emlTheilSen.intercept
                            else
                                .gSlope = undefined
                            endif
                        else
                            # OLS for Pearson context
                            if .gHavePearson = 0
                                @emlPearsonCorrelation: .gXTrim#, .gYTrim#, 2
                                if emlPearsonCorrelation.error$ = ""
                                    .gPearsonR = emlPearsonCorrelation.r
                                endif
                            endif

                            .gMeanX = mean (.gXTrim#)
                            .gMeanY = mean (.gYTrim#)
                            .gSdX = stdev (.gXTrim#)
                            .gSdY = stdev (.gYTrim#)

                            if .gSdX > 0
                                .gSlope = .gPearsonR * (.gSdY / .gSdX)
                                .gIntercept = .gMeanY - .gSlope * .gMeanX
                            else
                                .gSlope = undefined
                            endif
                        endif

                        if .gSlope <> undefined

                            # Data extent for this group
                            .gXMin = .gXTrim#[1]
                            .gXMax = .gXTrim#[1]
                            for .j from 2 to .gN
                                if .gXTrim#[.j] < .gXMin
                                    .gXMin = .gXTrim#[.j]
                                endif
                                if .gXTrim#[.j] > .gXMax
                                    .gXMax = .gXTrim#[.j]
                                endif
                            endfor

                            # Draw in group's palette color
                            .colorIdx = .g
                            @emlDrawRegressionLine: .gXMin, .gXMax, .gSlope, .gIntercept, .axisYMin, .axisYMax, emlSetColorPalette.line$[.colorIdx]

                            # Formula and R² to Info window.
                            # v1.19: disclosure is unconditional — the drawn
                            # line's estimator is always named, including when
                            # the regression reporter has fired. R² is emitted
                            # only for the OLS line; the Theil-Sen line has no
                            # OLS R². Guard on the actual estimator used
                            # (.gLineMethod$), not on annotCorrType$.
                            if .gLineMethod$ = "OLS"
                                .gR2 = .gPearsonR * .gPearsonR
                                .gEqn$ = "  " + .groupDispLabel$ + ": OLS fitted line: y = " + fixed$ (.gSlope, 4) + "x + " + fixed$ (.gIntercept, 4) + "  (R" + "² = " + fixed$ (.gR2, 3) + ")"
                            else
                                .gEqn$ = "  " + .groupDispLabel$ + ": " + .gLineMethod$ + " fitted line: y = " + fixed$ (.gSlope, 4) + "x + " + fixed$ (.gIntercept, 4)
                            endif
                            appendInfoLine: .gEqn$

                            # Formula on graph if requested (independent of annotate)
                            # v1.19: on-graph formula is labelled with the
                            # estimator actually drawn. R² only for OLS.
                            if scatterShowFormula = 1
                                .pgN = .pgN + 1
                                .gMethodTag$ = .gLineMethod$ + ": "
                                if .gLineMethod$ = "OLS"
                                    .gR2Annot = .gPearsonR * .gPearsonR
                                    .pgLabel$[.pgN] = .groupDispLabel$ + ": " + .gMethodTag$ + "y = " + fixed$ (.gSlope, 4) + "x + " + fixed$ (.gIntercept, 4) + "  (R² = " + fixed$ (.gR2Annot, 3) + ")"
                                    .pgDraw$[.pgN] = .groupDispLabel$ + ": " + .gMethodTag$ + "%y = " + fixed$ (.gSlope, 4) + "%x + " + fixed$ (.gIntercept, 4) + "  (%R² = " + fixed$ (.gR2Annot, 3) + ")"
                                else
                                    .pgLabel$[.pgN] = .groupDispLabel$ + ": " + .gMethodTag$ + "y = " + fixed$ (.gSlope, 4) + "x + " + fixed$ (.gIntercept, 4)
                                    .pgDraw$[.pgN] = .groupDispLabel$ + ": " + .gMethodTag$ + "%y = " + fixed$ (.gSlope, 4) + "%x + " + fixed$ (.gIntercept, 4)
                                endif
                            endif
                        endif
                    endif
                else
                    if annotCorrType$ <> "" or scatterRegressionLine = 1
                        appendInfoLine: "  " + .groupDispLabel$ + ": too few points (n = " + string$ (.gN) + ")"
                    endif
                endif
            endfor
        endif

        # v1.22 — COMMIT THE BUFFERED PER-GROUP LINES, ALL OR NONE.
        #
        # The budget is @emlDisclose's 20-line block cap, less whatever is
        # already in the block, less TWO lines held back for the disclosures
        # that follow: the over-cap note itself, and the dropped-row note.
        # Without that reserve an exactly-fitting set of group lines would
        # push the disclosures out of the box, which is how the eight-group
        # figure came to overflow AND fall silent at the same time.
        #
        # 3 lines per group at Correlation type = Both with the formula on,
        # so six groups fit and seven do not. The Info window is never
        # capped, so nothing is lost when they do not: every buffered line is
        # printed there verbatim, in the same order it would have appeared in
        # the box.
        .pgRoom = 20 - annotBlockN - 2
        if .pgRoom < 0
            .pgRoom = 0
        endif
        if .pgN > 0
            if .pgN <= .pgRoom
                for .k from 1 to .pgN
                    annotBlockN = annotBlockN + 1
                    annotBlockLabel$[annotBlockN] = .pgLabel$[.k]
                    annotBlockDraw$[annotBlockN] = .pgDraw$[.k]
                endfor
            else
                @emlDisclose: "Per-group stats (" + string$ (.nGroups)
                ... + " groups): Info window only.",
                ... string$ (.pgN) + " line(s) do not fit the "
                ... + "20-line annotation block, so none were placed on the "
                ... + "figure: a box that tall covers the data it describes, "
                ... + "and a box holding only the first few groups would "
                ... + "look complete. They follow here in full."
                for .k from 1 to .pgN
                    appendInfoLine: "  " + .pgLabel$[.k]
                endfor
            endif
        endif

        # Disclosure (v1.21) — same line, this path's block.
        if .nSkippedRows > 0
            @emlDisclose: string$ (.nSkippedRows)
            ... + " row(s) skipped (missing or non-numeric value).", ""
        endif

        # Place annotation block and legend — adaptive corner selection
        .xMidQ = (.axisXMin + .axisXMax) / 2
        .yMidQ = (.axisYMin + .axisYMax) / 2
        .qTL = 0
        .qTR = 0
        .qBL = 0
        .qBR = 0
        for .qi from 1 to .nValid
            if .yData#[.qi] >= .yMidQ
                if .xData#[.qi] < .xMidQ
                    .qTL = .qTL + 1
                else
                    .qTR = .qTR + 1
                endif
            else
                if .xData#[.qi] < .xMidQ
                    .qBL = .qBL + 1
                else
                    .qBR = .qBR + 1
                endif
            endif
        endfor

        if annotBlockN > 0
            @emlPlaceElements: .qTL, .qTR, .qBL, .qBR, .xMidQ, 2
            @emlDrawAnnotationBlock: emlPlaceElements.corner1$, .axisXMin, .axisXMax, .axisYMin, .axisYMax, emlSetAdaptiveTheme.annotSize
            .legendCorner$ = emlPlaceElements.corner2$
        else
            @emlPlaceElements: .qTL, .qTR, .qBL, .qBR, .xMidQ, 1
            .legendCorner$ = emlPlaceElements.corner1$
        endif
        @emlDrawLegend: .axisXMin, .axisXMax, .axisYMin, .axisYMax, .legendCorner$, emlSetAdaptiveTheme.annotSize
    endif

    # Step 8: Axes
    @emlDrawAxes: .axisXMin, .axisXMax, .axisYMin, .axisYMax, .xLabel$, .yLabel$, .title$, .vpW, .vpH

    # Step 9: Reset state
    Colour: "Black"
    Line width: 1.0
    Font size: emlSetAdaptiveTheme.bodySize
endproc


# ============================================================================
# @emlDrawBoxPlot
# ============================================================================
# Draws a grouped box-and-whisker plot with Tukey whiskers and outlier dots.
# Follows the same data extraction pattern as @emlDrawViolinPlot.
# ============================================================================
# Requires: @emlInitDrawingDefaults (or manual global initialization).
# Reads globals: emlPanelOriginX, emlPanelOriginY (via @emlSetAdaptiveTheme).
procedure emlDrawBoxPlot: .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .groupCol$, .valueCol$, .vMin, .vMax

    # Step 1: Set up theme and palette
    @emlSetAdaptiveTheme: .vpW, .vpH
    @emlSetColorPalette: .colorMode$
    # Categorical x-axis labels must exist before @emlDrawCategoricalXAxis
    # renders them. In the form path the pre-dispatch block has already
    # measured and this is a no-op; from anywhere else it is the difference
    # between a figure and an aborted script. Must come before this
    # procedure sets its own Axes: the measurement installs its own.
    @emlEnsureCategoricalLabels: .objectId, .groupCol$, .vpW, .vpH
    @emlDiscloseBegin: "Box plot"

    @emlSanitizeLabel: .title$
    .title$ = emlSanitizeLabel.result$

    # Step 2: Extract groups and data
    @emlCountGroups: .objectId, .groupCol$
    .nGroups = emlCountGroups.nGroups
    for .g from 1 to .nGroups
        .grpLabel$[.g] = emlCountGroups.groupLabel$[.g]
    endfor

    selectObject: .objectId
    .nRows = Get number of rows

    @emlOptimizePaletteContrast: .nGroups

    # Step 3: Extract per-group values
    for .g from 1 to .nGroups
        .groupCount'.g' = 0
    endfor

    # v1.19 (C 96): blank or non-numeric cells used to be stored as undefined
    # and then handed to @emlDrawBox -> @emlPercentile -> sort#, which aborts
    # the whole figure. Store only defined values (the pattern already used by
    # @emlDrawGroupedBoxPlot) and record how many rows were dropped.
    # The same reader the analysis uses. See @emlDrawColumnIsClean for what
    # the lenient one cost.
    @emlDrawColumnIsClean: .objectId, .valueCol$
    .cellsClean = emlDrawColumnIsClean.clean

    .nSkippedRows = 0
    for .i from 1 to .nRows
        selectObject: .objectId
        .thisGroup$ = Get value: .i, .groupCol$
        @eml_readCell: .objectId, .i, .valueCol$, .cellsClean
        .thisVal = eml_readCell.value

        if .thisVal = undefined
            .nSkippedRows = .nSkippedRows + 1
        else
            for .g from 1 to .nGroups
                if .thisGroup$ = .grpLabel$[.g]
                    .groupCount'.g' = .groupCount'.g' + 1
                    .c = .groupCount'.g'
                    .groupData'.g'_'.c' = .thisVal
                endif
            endfor
        endif
    endfor

    # Step 4: Compute y-axis range (both 0 = auto)
    .globalMin = undefined
    .globalMax = undefined
    for .g from 1 to .nGroups
        .n = .groupCount'.g'
        for .k from 1 to .n
            .val = .groupData'.g'_'.k'
            if .globalMin = undefined
                .globalMin = .val
                .globalMax = .val
            else
                if .val < .globalMin
                    .globalMin = .val
                endif
                if .val > .globalMax
                    .globalMax = .val
                endif
            endif
        endfor
    endfor
    # v1.19 (C 96): with no usable value anywhere, .globalMin stayed undefined
    # and the undefined axis limits aborted the figure at Axes:. Fall back to
    # a unit axis, as @emlDrawGroupedBoxPlot already does.
    # D111: the fallback was silent. Say so on the same channel and in the
    # same words as @emlDrawTimeSeries and @emlDrawSpaghettiPlot, so an
    # empty frame reads the same whichever figure produced it.
    if .globalMin = undefined
        .globalMin = 0
        .globalMax = 1
        .noDataMsg$ = "NOTE: Box plot — no usable value; empty axes drawn."
        appendInfoLine: .noDataMsg$
    endif
    # Adaptive rounding grid: derive roundTo from a nice step over the data
    # range (the same nice-number logic the gridlines use) so fractional data
    # (proportions, contact quotient, jitter %) is not snapped to a 10-unit grid.
    @emlComputeNiceStep: .globalMax - (.globalMin), emlSetAdaptiveTheme.targetTicksY
    .axisRoundTo = emlComputeNiceStep.step
    @emlComputeAxisRange: .globalMin, .globalMax, .axisRoundTo, 0
    .autoYMin = emlComputeAxisRange.axisMin
    .autoYMax = emlComputeAxisRange.axisMax

    if .vMin = 0 and .vMax = 0
        .yMin = .autoYMin
        .yMax = .autoYMax
    else
        .yMin = .vMin
        .yMax = .vMax
    endif

    # Step 5: Set x-axis range
    .xMin = 0.5
    .xMax = max (1, .nGroups) + 0.5   ; clamp: a 0-row table would make left = right

    # Step 6: Set viewport and axes
    @emlSetPanelViewport
    Axes: .xMin, .xMax, .yMin, .yMax
    # Physical scale for fill patterns: a 45-degree hatch has to be 45
    # degrees ON THE PAGE, not at whatever angle the two axis ranges imply.
    @emlSetPatternScale: .xMin, .xMax, .yMin, .yMax

    # Step 7: Draw horizontal gridlines (if requested)
    # gridMode: 1=Horizontal, 2=Off
    if .gridMode = 1
        @emlDrawHorizontalGridlines: .xMin, .xMax, .yMin, .yMax, emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks
    endif

    # Step 8: Draw each box
    # v1.19 (C 96): a group with no usable observation produced a zero-length
    # vector, whose percentiles are undefined and abort the drawing command.
    # Skip that group instead, matching @emlDrawGroupedBoxPlot.
    .nEmptyGroups = 0
    for .g from 1 to .nGroups
        .n = .groupCount'.g'
        if .n < 1
            .nEmptyGroups = .nEmptyGroups + 1
        else
            .data# = zero# (.n)
            for .k from 1 to .n
                .data#[.k] = .groupData'.g'_'.k'
            endfor

            .colorIdx = .g

            @emlDrawBox: .g, .data#, emlSetColorPalette.fill$[.colorIdx],
            ... emlSetColorPalette.line$[.colorIdx], .yMin, .yMax, 0.25,
            ... emlSetColorPalette.pattern[.colorIdx]
        endif
    endfor

    # Step 8B: Jittered points overlay
    if variableExists ("prev_boxShowJitter")
        if prev_boxShowJitter = 1
            for .g from 1 to .nGroups
                .n = .groupCount'.g'
                # v1.19 (C 96): skip empty groups here too.
                if .n >= 1
                    jitterData# = zero# (.n)
                    for .k from 1 to .n
                        jitterData#[.k] = .groupData'.g'_'.k'
                    endfor
                    .colorIdx = .g
                    @emlDrawJitteredPoints: .g, emlSetColorPalette.line$[.colorIdx], emlSetAdaptiveTheme.markerSize * 0.5, 0.12
                endif
            endfor
        endif
    endif

    # v1.19 (C 96): report anything the guards above dropped, so a thinner
    # figure is never mistaken for the whole data set.
    # v1.21: same wording, same counters; routed through @emlDisclose so the
    # sentence also reaches the figure when the user ticked Annotate.
    if .nSkippedRows > 0
        @emlDisclose: string$ (.nSkippedRows)
        ... + " row(s) skipped (missing or non-numeric value).", ""
    endif
    if .nEmptyGroups > 0
        @emlDisclose: string$ (.nEmptyGroups)
        ... + " group(s) not drawn (no usable observation).", ""
    endif

    # Expose axis ranges for annotation bridge
    .axisXMin = 0.5
    .axisXMax = max (1, .nGroups) + 0.5   ; clamp: a 0-row table would make left = right
    .axisYMin = .yMin
    .axisYMax = .yMax

    # Quadrant occupancy for the disclosure block's corner (v1.21).
    .dxMid = (.axisXMin + .axisXMax) / 2
    .dyMid = (.yMin + .yMax) / 2
    .dTL = 0
    .dTR = 0
    .dBL = 0
    .dBR = 0
    for .g from 1 to .nGroups
        .dn = .groupCount'.g'
        for .dk from 1 to .dn
            .dv = .groupData'.g'_'.dk'
            if .dv >= .dyMid
                if .g < .dxMid
                    .dTL = .dTL + 1
                else
                    .dTR = .dTR + 1
                endif
            else
                if .g < .dxMid
                    .dBL = .dBL + 1
                else
                    .dBR = .dBR + 1
                endif
            endif
        endfor
    endfor
    # A box plot draws no legend — the group names are the x-axis.
    @emlDiscloseEnd: .axisXMin, .axisXMax, .yMin, .yMax,
    ... .dTL, .dTR, .dBL, .dBR, ""

    # Step 9: Draw axes with group labels
    @emlDrawInnerBoxIf
    @emlDrawAlignedMarksLeft: .yMin, .yMax, emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks

    # Group labels and x-axis label (pre-measured)
    @emlDrawCategoricalXAxis: .nGroups, .axisXMin, .axisXMax, .yMin, .yMax, .xLabel$
    if emlShowAxisNameY
        Text left: "yes", .yLabel$
    endif

    @emlDrawTitle: .title$, .vpW, .vpH, .xMin, .xMax, .yMin, .yMax

    # Step 10: Reset state
    Colour: "Black"
    Line width: 1.0
    Font size: emlSetAdaptiveTheme.bodySize
endproc


# ============================================================================
# @emlDrawHistogram
# ============================================================================
# Draws a histogram from Table data with optional grouped display.
# Grouped modes (.displayMode): 1 = overlap (alpha-composited bars, one
# panel, legend), 2 = faceted (one vertically stacked panel per group,
# shared x and y axes, group names in the left margin instead of a legend).
# Mode 2 is faceted, not side-by-side: see the branch at Step 9-10.
# Auto-bins via Sturges formula when binCount = 0.
# ============================================================================
# Requires: @emlInitDrawingDefaults (or manual global initialization).
# Reads globals: emlPanelOriginX, emlPanelOriginY (via @emlSetAdaptiveTheme).
procedure emlDrawHistogram: .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .valueCol$, .groupCol$, .binCount, .displayMode, .vMin, .vMax, .freqMax
    # @emlInitAlphaSprites is idempotent and cheap, and this procedure NEEDS
    # it: the overlay path calls @emlDrawAlphaRect, which reads
    # emlInitAlphaSprites.available. Without this, a GROUPED histogram aborts
    # with "Unknown variable: emlInitAlphaSprites.available" for every caller
    # that is not eml-graphs-form.praat -- a user script, a PraatGen
    # companion, or a recorded workflow replaying itself.
    #
    # This is the SAME defect that was fixed in @emlDrawScatterPlot and
    # @emlDrawTimeSeriesCI on 6 Aug 2026; the histogram was missed because
    # every stress case draws it UNGROUPED (hist_baseline passes "" as the
    # group column), and the overlay branch is only reached with more than
    # one group. Found 10 Aug 2026 by harness/determinism/run.sh, which draws
    # every type grouped.
    @emlInitAlphaSprites

    # Step 1: Theme and palette
    @emlSetAdaptiveTheme: .vpW, .vpH
    # Frequency is a count. Declaring the y-axis integral keeps every
    # downstream step — axis bounds, gridlines and tick labels — on whole
    # units, which is what lets the range itself be derived from the data
    # instead of pinned to a literal.
    emlYAxisMinStep = 1
    @emlSetColorPalette: .colorMode$
    @emlDiscloseBegin: "Histogram"
    # v1.21: the corner the legend takes, so @emlDiscloseEnd can keep the
    # disclosure box out of it. Empty until a legend is actually drawn.
    .legendCorner$ = ""

    @emlSanitizeLabel: .title$
    .title$ = emlSanitizeLabel.result$

    # Step 2: Read all data
    selectObject: .objectId
    .nRows = Get number of rows
    .allData# = zero# (.nRows)
    .nValid = 0

    # Same reader as the analysis. See @emlDrawColumnIsClean.
    @emlDrawColumnIsClean: .objectId, .valueCol$
    .cleanValObj = emlDrawColumnIsClean.clean
    for .i from 1 to .nRows
        selectObject: .objectId
        @eml_readCell: .objectId, .i, .valueCol$, .cleanValObj
        .val = eml_readCell.value
        if .val <> undefined
            .nValid = .nValid + 1
            .allData#[.nValid] = .val
        endif
    endfor

    # D111: this branch used to `goto HIST_END`, which jumps past this
    # procedure's OWN Axes: call at Step 8 — so an empty table produced a
    # 1800x1200 PNG of a single colour: no box, no ticks, no title, nothing
    # for the reader to diagnose. Every sibling draws the labelled empty
    # frame instead. Fall back to a unit value axis and continue down the
    # normal path, the same fix @emlDrawViolinPlot took from
    # @emlDrawGroupedViolin at v1.19 (C 96).
    .noData = 0
    if .nValid < 1
        appendInfoLine: "WARNING: No valid data for histogram."
        .noData = 1
    endif

    if .noData = 1
        # zero# (0) has no element 1, so the trim and the seeded range below
        # cannot run at all here. Unit value axis, as the violin family uses.
        .dataMin = 0
        .dataMax = 1
    else
        # Trim to valid
        .trimData# = zero# (.nValid)
        for .i from 1 to .nValid
            .trimData#[.i] = .allData#[.i]
        endfor

        # Step 3: Compute data range
        .dataMin = .trimData#[1]
        .dataMax = .trimData#[1]
        for .i from 2 to .nValid
            if .trimData#[.i] < .dataMin
                .dataMin = .trimData#[.i]
            endif
            if .trimData#[.i] > .dataMax
                .dataMax = .trimData#[.i]
            endif
        endfor
    endif

    # Value axis range
    if .vMin = 0 and .vMax = 0
        .xMin = .dataMin
        .xMax = .dataMax
    else
        .xMin = .vMin
        .xMax = .vMax
    endif

    # Step 4: Compute bins
    if .binCount <= 0
        if .noData = 1
            # Sturges is undefined at n = 0 (log10 (0)), and an undefined
            # .nBins would take out every bin loop below. The empty frame
            # needs a bin count only to keep the axis arithmetic defined,
            # so use the same floor the populated branch clamps to.
            .nBins = 3
        else
            # Sturges formula
            .nBins = ceiling (1 + 3.322 * log10 (.nValid))
            if .nBins < 3
                .nBins = 3
            endif
        endif
    else
        .nBins = .binCount
    endif

    .binWidth = (.xMax - .xMin) / .nBins

    # Guard: zero range
    if .binWidth <= 0
        .binWidth = 1
        .nBins = 1
        .xMax = .xMin + 1
    endif

    # Step 5: Determine grouping
    .hasGroups = 0
    .nGroups = 1
    if .groupCol$ <> ""
        .hasGroups = 1
        @emlCountGroups: .objectId, .groupCol$
        .nGroups = emlCountGroups.nGroups

    endif

    # 1-group edge case: faceting a single group produces viewport
    # mismatch between bar rendering and garnish. Treat as ungrouped.
    if .nGroups = 1
        .hasGroups = 0
        .displayMode = 1
    endif

    if .hasGroups = 1
        @emlOptimizePaletteContrast: .nGroups
    endif

    # Step 6: Count per bin (per group if grouped)
    .maxFreq = 0

    for .g from 1 to .nGroups
        for .b from 1 to .nBins
            .count'.g'_'.b' = 0
        endfor
    endfor

    for .i from 1 to .nRows
        selectObject: .objectId
        @eml_readCell: .objectId, .i, .valueCol$, .cleanValObj
        .val = eml_readCell.value
        if .val <> undefined and .val >= .xMin and .val <= .xMax
            .b = floor ((.val - .xMin) / .binWidth) + 1
            if .b > .nBins
                .b = .nBins
            endif
            if .b < 1
                .b = 1
            endif

            # v1.19: guard on .hasGroups, not .nGroups. .nGroups is
            # seeded to 1 for the ungrouped case, so ".nGroups > 0" was
            # always true and the ungrouped path fell into the group
            # lookup with an empty column name, aborting the figure.
            .gIdx = 1
            if .hasGroups = 1
                .grp$ = Get value: .i, .groupCol$
                for .g from 1 to .nGroups
                    if emlCountGroups.groupLabel$[.g] = .grp$
                        .gIdx = .g
                    endif
                endfor
            endif

            .count'.gIdx'_'.b' = .count'.gIdx'_'.b' + 1
        endif
    endfor

    # Find max frequency
    for .g from 1 to .nGroups
        for .b from 1 to .nBins
            if .count'.g'_'.b' > .maxFreq
                .maxFreq = .count'.g'_'.b'
            endif
        endfor
    endfor

    # Step 7: Y-axis range
    if .freqMax = 0
        # Adaptive rounding grid, floored at one count.
        @emlComputeNiceStep: .maxFreq - (0), emlSetAdaptiveTheme.targetTicksY
        .axisRoundTo = emlComputeNiceStep.step
        if .axisRoundTo < 1
            .axisRoundTo = 1
        endif
        @emlComputeAxisRange: 0, .maxFreq, .axisRoundTo, 0
        .yMin = 0
        .yMax = emlComputeAxisRange.axisMax
    else
        .yMin = 0
        .yMax = .freqMax
    endif

    # Step 8: Set viewport and axes
    @emlSetPanelViewport
    Axes: .xMin, .xMax, .yMin, .yMax

    # Step 9–10: Gridlines and data drawing (branched by display mode)
    if .hasGroups and .displayMode = 2
        # === FACETED (vertically stacked panels, shared x + y axes) ===
        .innerL = emlSetAdaptiveTheme.innerLeft
        .innerR = emlSetAdaptiveTheme.innerRight
        .innerT = emlSetAdaptiveTheme.innerTop
        .innerB = emlSetAdaptiveTheme.innerBottom
        .totalInnerH = .innerB - .innerT
        .panelGap = 0.15
        .panelH = (.totalInnerH - (.nGroups - 1) * .panelGap) / .nGroups

        # Shared y-axis: global max across all groups
        .sharedYMax = 0
        for .g from 1 to .nGroups
            for .b from 1 to .nBins
                if .count'.g'_'.b' > .sharedYMax
                    .sharedYMax = .count'.g'_'.b'
                endif
            endfor
        endfor
        if .freqMax > 0
            .sharedYMax = .freqMax
        elsif .sharedYMax = 0
            .sharedYMax = 1
        else
            # Adaptive rounding grid, floored at one count.
            @emlComputeNiceStep: .sharedYMax - (0), emlSetAdaptiveTheme.targetTicksY
            .axisRoundTo = emlComputeNiceStep.step
            if .axisRoundTo < 1
                .axisRoundTo = 1
            endif
            @emlComputeAxisRange: 0, .sharedYMax, .axisRoundTo, 0
            .sharedYMax = emlComputeAxisRange.axisMax
        endif

        # Per-facet tick count (based on panel height, not full canvas)
        .facetTicksY = max (2, min (7, round (.panelH / 0.5)))

        for .g from 1 to .nGroups
            .panelTop = .innerT + (.g - 1) * (.panelH + .panelGap)
            .panelBot = .panelTop + .panelH

            # Panel viewport and content at annotSize (one tier below body)
            .facetBodySize = emlSetAdaptiveTheme.annotSize
            Font size: .facetBodySize
            Select inner viewport: .innerL, .innerR, .panelTop, .panelBot
            Axes: .xMin, .xMax, 0, .sharedYMax

            # Gridlines (horizontal only — categorical per panel)
            # gridMode: 1=Horizontal, 2=Off
            if .gridMode = 1
                @emlDrawHorizontalGridlines: .xMin, .xMax, 0, .sharedYMax, .facetTicksY, emlSetAdaptiveTheme.useMinorTicks
            endif

            # Bars
            .colorIdx = .g
            for .b from 1 to .nBins
                .barLeft = .xMin + (.b - 1) * .binWidth
                .barRight = .barLeft + .binWidth
                .barTop = .count'.g'_'.b'
                if .barTop > 0
                    .clamped = min (.barTop, .sharedYMax)
                    Paint rectangle: emlSetColorPalette.fill$[.colorIdx], .barLeft, .barRight, 0, .clamped
                    Colour: emlSetColorPalette.line$[.colorIdx]
                    Line width: 0.6
                    Draw rectangle: .barLeft, .barRight, 0, .clamped
                endif
            endfor

            # Panel frame and y-axis (facetBodySize — matches panel viewport)
            Colour: emlSetAdaptiveTheme.axisColor$
            Line width: emlSetAdaptiveTheme.axisLineWidth
            if emlShowInnerBox = 1
                Draw inner box
            endif
            @emlDrawAlignedMarksLeft: 0, .sharedYMax, .facetTicksY, emlSetAdaptiveTheme.useMinorTicks

            # X-axis ticks only on bottom panel (facetBodySize)
            if .g = .nGroups
                @emlDrawAlignedMarksBottom: .xMin, .xMax,
                ... emlSetAdaptiveTheme.targetTicksX, emlSetAdaptiveTheme.useMinorTicks
            endif

            # Group label — left margin, rotated 90° (reading bottom-to-top)
            # Truncate if label exceeds panel height
            Font size: emlSetAdaptiveTheme.bodySize
            Colour: emlSetAdaptiveTheme.textColor$
            @emlSanitizeLabel: emlCountGroups.groupLabel$[.g]
            .panelLabel$ = emlSanitizeLabel.result$

            # Measure text width in inches (becomes vertical extent at 90°)
            # Text width is in x-world-coords; convert to inches via panel width
            .xRange = .xMax - .xMin
            .panelWInches = .innerR - .innerL
            .labelWC = Text width (world coordinates): .panelLabel$
            .labelInches = .labelWC * (.panelWInches / .xRange)
            # Available vertical = panel height × 85%
            .maxLabelInches = .panelH * 0.85
            if .labelInches > .maxLabelInches and .maxLabelInches > 0
                # Convert inch limit back to world coordinates for measurement
                .maxLabelWC = .maxLabelInches * (.xRange / .panelWInches)
                # Truncate with binary search
                .lo = 1
                .hi = length (.panelLabel$)
                .origLabel$ = .panelLabel$
                while .lo < .hi - 1
                    .mid = round ((.lo + .hi) / 2)
                    .tryLabel$ = left$ (.origLabel$, .mid) + "…"
                    .tryW = Text width (world coordinates): .tryLabel$
                    if .tryW <= .maxLabelWC
                        .lo = .mid
                    else
                        .hi = .mid
                    endif
                endwhile
                .panelLabel$ = left$ (.origLabel$, .lo) + "…"
            endif

            Text left: "yes", .panelLabel$
        endfor

        # Full viewport for shared axis labels at bodySize
        Font size: emlSetAdaptiveTheme.bodySize
        Select inner viewport: .innerL, .innerR, .innerT, .innerB
        Axes: .xMin, .xMax, .yMin, .yMax

    else
        # === NON-FACETED (ungrouped or overlap) ===

        # Gridlines
        # gridMode: 1=Both, 2=Horizontal only, 3=Vertical only, 4=Off
        if .gridMode = 1
            @emlDrawGridlines: .xMin, .xMax, .yMin, .yMax, emlSetAdaptiveTheme.targetTicksX, emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks
        elsif .gridMode = 2
            @emlDrawHorizontalGridlines: .xMin, .xMax, .yMin, .yMax, emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks
        elsif .gridMode = 3
            @emlDrawVerticalGridlines: .xMin, .xMax, .yMin, .yMax, emlSetAdaptiveTheme.targetTicksX, emlSetAdaptiveTheme.useMinorTicks
        endif

        # Bars
        if .hasGroups = 0
            # === UNGROUPED ===
            for .b from 1 to .nBins
                .barLeft = .xMin + (.b - 1) * .binWidth
                .barRight = .barLeft + .binWidth
                .barTop = .count1_'.b'

                if .barTop > 0
                    .clamped = min (.barTop, .yMax)
                    Paint rectangle: emlSetColorPalette.fill$[1], .barLeft, .barRight, 0, .clamped
                    Colour: emlSetColorPalette.line$[1]
                    Line width: 0.6
                    Draw rectangle: .barLeft, .barRight, 0, .clamped
                endif
            endfor
        else
            # === OVERLAP (alpha) ===
            for .b from 1 to .nBins
                .barLeft = .xMin + (.b - 1) * .binWidth
                .barRight = .barLeft + .binWidth

                for .g from 1 to .nGroups
                    .barTop = .count'.g'_'.b'
                    .colorIdx = .g

                    if .barTop > 0
                        .clamped = min (.barTop, .yMax)
                        @emlDrawAlphaRect: .barLeft, .barRight, 0, .clamped, .g, .colorMode$, "a50", emlSetColorPalette.fill$[.colorIdx]
                        Colour: emlSetColorPalette.line$[.colorIdx]
                        Line width: 0.5
                        Draw rectangle: .barLeft, .barRight, 0, .clamped
                    endif
                endfor
            endfor
        endif
    endif

    # Step 11: Legend (if grouped — overlap mode only; faceted uses panel labels)
    if .hasGroups and .displayMode <> 2
        # Quadrant scoring from bin counts
        .xMidQ = (.xMin + .xMax) / 2
        .yMidQ = (.yMin + .yMax) / 2
        .qTL = 0
        .qTR = 0
        .qBL = 0
        .qBR = 0
        for .g from 1 to .nGroups
            for .b from 1 to .nBins
                .binCenter = .xMin + (.b - 0.5) * .binWidth
                .binVal = .count'.g'_'.b'
                if .binVal > 0
                    if .binVal >= .yMidQ
                        if .binCenter < .xMidQ
                            .qTL = .qTL + 1
                        else
                            .qTR = .qTR + 1
                        endif
                    else
                        if .binCenter < .xMidQ
                            .qBL = .qBL + 1
                        else
                            .qBR = .qBR + 1
                        endif
                    endif
                endif
            endfor
        endfor
        @emlPlaceElements: .qTL, .qTR, .qBL, .qBR, .xMidQ, 1

        legendN = .nGroups
        for .g from 1 to .nGroups
            .colorIdx = .g
            legendColor$[.g] = emlSetColorPalette.line$[.colorIdx]
            @emlSanitizeLabel: emlCountGroups.groupLabel$[.g]
            legendLabel$[.g] = emlSanitizeLabel.result$
        endfor
        .legendCorner$ = emlPlaceElements.corner1$
        @emlDrawLegend: .xMin, .xMax, .yMin, .yMax, .legendCorner$, emlSetAdaptiveTheme.annotSize
    endif

    # Step 11B: Disclosures (v1.21)
    #
    # Verified 7 Aug 2026 on a 20-row table with 6 undefined values: this
    # procedure printed "Histogram: 10 bins, bin width = 1.8000 / Groups: 1"
    # and nothing else. It drew 14 observations while the reader believed 20,
    # and a histogram gives no way to notice — the bars simply stand shorter.
    #
    # Both branches converge on the same coordinate system before this point:
    # the faceted branch restores the shared inner viewport and Axes: at the
    # end of its loop, and the non-faceted branch never left them.
    if .nRows > .nValid
        @emlDisclose: string$ (.nRows - .nValid)
        ... + " row(s) skipped (missing or non-numeric value).", ""
    endif

    # Quadrant occupancy for the disclosure block's corner. Bars stand on
    # zero, so a bar owns its bottom quadrant outright and its top quadrant
    # only when it rises past the midline.
    .dxMid = (.xMin + .xMax) / 2
    .dyMid = (.yMin + .yMax) / 2
    .dTL = 0
    .dTR = 0
    .dBL = 0
    .dBR = 0
    for .g from 1 to .nGroups
        for .b from 1 to .nBins
            .dv = .count'.g'_'.b'
            if .dv > 0
                .dc = .xMin + (.b - 0.5) * .binWidth
                if .dc < .dxMid
                    .dBL = .dBL + 1
                    if .dv >= .dyMid
                        .dTL = .dTL + 1
                    endif
                else
                    .dBR = .dBR + 1
                    if .dv >= .dyMid
                        .dTR = .dTR + 1
                    endif
                endif
            endif
        endfor
    endfor
    # A legend is drawn in overlap mode only; faceted mode labels its panels
    # in the left margin and ungrouped mode has nothing to label, so
    # .legendCorner$ is still "" in both of those.
    @emlDiscloseEnd: .xMin, .xMax, .yMin, .yMax, .dTL, .dTR, .dBL, .dBR,
    ... .legendCorner$

    # Step 12: Axes
    if .displayMode <> 2
        @emlDrawAxes: .xMin, .xMax, .yMin, .yMax, .xLabel$, .yLabel$, .title$, .vpW, .vpH
    else
        # Faceted: draw title and shared axis labels in full viewport
        Font size: emlSetAdaptiveTheme.bodySize
        @emlSetPanelViewport
        Axes: 0, 1, 0, 1
        @emlSanitizeLabel: .title$
        .title$ = emlSanitizeLabel.result$
        @emlDrawTitle: .title$, .vpW, .vpH, 0, 1, 0, 1
        Colour: emlSetAdaptiveTheme.textColor$
        if .yLabel$ <> ""
            if emlShowAxisNameY
                Text left: "yes", .yLabel$
            endif
        endif
        if .xLabel$ <> ""
            if emlShowAxisNameX
                Text bottom: "yes", .xLabel$
            endif
        endif
    endif

    # Expose axis ranges for annotation bridge
    .axisXMin = .xMin
    .axisXMax = .xMax
    .axisYMin = .yMin
    .axisYMax = .yMax

    # Step 13: Info
    appendInfoLine: "Histogram: " + string$ (.nBins) + " bins, bin width = " + fixed$ (.binWidth, 4)
    if .nGroups > 0
        appendInfoLine: "Groups: " + string$ (.nGroups)
    endif

    # Reset
    Colour: "Black"
    Line width: 1.0
    Font size: emlSetAdaptiveTheme.bodySize

    # The `label HIST_END` that stood here was the landing point of the
    # no-data goto removed at Step 2 (D111). Nothing jumps here any more, and
    # the empty case now reaches this line the same way a populated one does.

    # Release the integral-axis constraint: it is scoped to this figure.
    emlYAxisMinStep = 0
endproc


# ============================================================================
# @emlDrawGroupedViolin
# ============================================================================
# Draws a grouped violin plot: categories on x-axis, sub-groups as
# side-by-side violins within each category.
# Example: 5 songs (categories) x 3 platforms (sub-groups) = 15 violins
# ============================================================================
# Requires: @emlInitDrawingDefaults (or manual global initialization).
# Reads globals: emlPanelOriginX, emlPanelOriginY (via @emlSetAdaptiveTheme).
procedure emlDrawGroupedViolin: .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .catCol$, .subCol$, .valueCol$, .vMin, .vMax

    # Step 1: Theme and palette
    @emlSetAdaptiveTheme: .vpW, .vpH
    @emlSetColorPalette: .colorMode$
    # Categorical x-axis labels must exist before @emlDrawCategoricalXAxis
    # renders them. In the form path the pre-dispatch block has already
    # measured and this is a no-op; from anywhere else it is the difference
    # between a figure and an aborted script. Must come before this
    # procedure sets its own Axes: the measurement installs its own.
    @emlEnsureCategoricalLabels: .objectId, .catCol$, .vpW, .vpH
    @emlDiscloseBegin: "Grouped violin"
    # v1.21: the corner the legend takes, so @emlDiscloseEnd can keep the
    # disclosure box out of it. Empty until a legend is actually drawn.
    .legendCorner$ = ""

    @emlSanitizeLabel: .title$
    .title$ = emlSanitizeLabel.result$

    # Step 2: Extract unique categories via single source
    @emlCountGroups: .objectId, .catCol$
    .nCats = emlCountGroups.nGroups
    for .c from 1 to .nCats
        .cat$[.c] = emlCountGroups.groupLabel$[.c]
    endfor

    # Step 3: Extract unique sub-groups via single source
    @emlCountGroups: .objectId, .subCol$
    .nSubs = emlCountGroups.nGroups
    for .s from 1 to .nSubs
        .sub$[.s] = emlCountGroups.groupLabel$[.s]
    endfor

    # THE PALETTE CEILING. @emlSetColorPalette defines a style as a pair —
    # one of EIGHT hues and one of THREE fill patterns (solid, diagonal
    # hatch, dots) — so it holds 24 sub-group styles that are distinguishable
    # from one another both on the figure and in the legend. Past 24 the pair
    # repeats and a sub-group would be drawn exactly like one already on the
    # figure. The cap is a real limit of the palette, not an arbitrary
    # number.
    #
    # v1.23 raised it from 10 to 24 on the author's ruling: "let's make the
    # boundary in excess of what we think is reasonable... maybe there's some
    # person who wants to do a twenty four participant comparison, and
    # they're gonna make their figure sixty inches wide. Like, we just don't
    # know." Twenty-four sub-violins on a default 6-inch figure are NOT
    # readable — see the rendered evidence in the v29 header — but that is
    # the user's judgement to make on their own figure width, and the drawing
    # code is correct at every count up to 24.
    #
    # The old ceiling was ten because ten fill/line pairs were declared, and
    # that number was WRONG IN BOTH DIRECTIONS: slots 9 and 10 were literal
    # duplicates of 1 and 2, so a ten-sub-group figure already drew two pairs
    # of sub-groups identically and said nothing (D127), while eight genuinely
    # distinct styles were being refused a legitimate eleventh.
    #
    # v1.22: what was wrong before that was the SILENCE. The extraction guard
    # below dropped sub-groups past the cap with no message, while `legendN`
    # was still set to .nSubs, so the legend listed sub-groups that had no
    # violin anywhere on the figure. The count is now carried to Step 10B and
    # disclosed, the legend is capped to what was actually drawn, and the
    # slot geometry below divides the category by the DRAWN count so the
    # remaining violins stay centred instead of leaving a phantom gap.
    .maxSubs = 24
    .nSubsDrawn = min (.nSubs, .maxSubs)
    .nSubsDropped = .nSubs - .nSubsDrawn
    .droppedSubs$ = ""
    for .s from .nSubsDrawn + 1 to .nSubs
        if .droppedSubs$ <> ""
            .droppedSubs$ = .droppedSubs$ + ", "
        endif
        .droppedSubs$ = .droppedSubs$ + .sub$[.s]
    endfor
    .nDroppedSubRows = 0

    selectObject: .objectId
    .nRows = Get number of rows

    @emlOptimizePaletteContrast: .nSubsDrawn

    # Step 4: Extract data per category x sub-group
    for .c from 1 to .nCats
        for .s from 1 to .nSubs
            .cellCount'.c'_'.s' = 0
        endfor
    endfor

    # v1.21: same counter idiom as @emlDrawViolinPlot.
    .nSkippedRows = 0
    # The same reader the analysis uses. See @emlDrawColumnIsClean for what
    # the lenient one cost.
    @emlDrawColumnIsClean: .objectId, .valueCol$
    .cellsClean = emlDrawColumnIsClean.clean

    for .i from 1 to .nRows
        selectObject: .objectId
        .thisCat$ = Get value: .i, .catCol$
        .thisSub$ = Get value: .i, .subCol$
        @eml_readCell: .objectId, .i, .valueCol$, .cellsClean
        .thisVal = eml_readCell.value

        if .thisVal = undefined
            .nSkippedRows = .nSkippedRows + 1
        else
            .cIdx = 0
            for .c from 1 to .nCats
                if .thisCat$ = .cat$[.c]
                    .cIdx = .c
                endif
            endfor
            .sIdx = 0
            for .s from 1 to .nSubs
                if .thisSub$ = .sub$[.s]
                    .sIdx = .s
                endif
            endfor

            # v1.22: the `.sIdx <= .maxSubs` arm is the palette ceiling
            # documented at Step 3. A row that lands past it is counted, so
            # Step 10B can say how much of the table never reached the
            # figure; it used to be discarded in silence.
            if .cIdx > 0 and .sIdx > .nSubsDrawn
                .nDroppedSubRows = .nDroppedSubRows + 1
            endif
            if .cIdx > 0 and .sIdx > 0 and .sIdx <= .nSubsDrawn
                .cellCount'.cIdx'_'.sIdx' = .cellCount'.cIdx'_'.sIdx' + 1
                .k = .cellCount'.cIdx'_'.sIdx'
                .cellData'.cIdx'_'.sIdx'_'.k' = .thisVal
            endif
        endif
    endfor

    # Step 5: Compute global y-axis range
    .globalMin = undefined
    .globalMax = undefined
    for .c from 1 to .nCats
        for .s from 1 to .nSubsDrawn
            .n = .cellCount'.c'_'.s'
            for .k from 1 to .n
                .val = .cellData'.c'_'.s'_'.k'
                if .globalMin = undefined
                    .globalMin = .val
                    .globalMax = .val
                else
                    if .val < .globalMin
                        .globalMin = .val
                    endif
                    if .val > .globalMax
                        .globalMax = .val
                    endif
                endif
            endfor
        endfor
    endfor

    # D111: this is the fallback @emlDrawViolinPlot was told to copy, and it
    # was the silent one. Disclose it in the same words as the rest.
    if .globalMin = undefined
        .globalMin = 0
        .globalMax = 1
        .noDataMsg$ = "NOTE: Grouped violin — no usable value; empty axes drawn."
        appendInfoLine: .noDataMsg$
    endif

    # Extend range by largest per-cell KDE bandwidth (violin tails)
    .maxBW = 0
    for .c from 1 to .nCats
        for .s from 1 to .nSubsDrawn
            .n = .cellCount'.c'_'.s'
            if .n >= 4
                .gMean = 0
                for .k from 1 to .n
                    .gMean = .gMean + .cellData'.c'_'.s'_'.k'
                endfor
                .gMean = .gMean / .n
                .gVar = 0
                for .k from 1 to .n
                    .gVar = .gVar + (.cellData'.c'_'.s'_'.k' - .gMean) ^ 2
                endfor
                .gSD = sqrt (.gVar / (.n - 1))
                .bw = 0.9 * .gSD * .n ^ (-0.2)
                if .bw > .maxBW
                    .maxBW = .bw
                endif
            endif
        endfor
    endfor
    .globalMin = .globalMin - .maxBW
    .globalMax = .globalMax + .maxBW
    # Adaptive rounding grid: derive roundTo from a nice step over the data
    # range (the same nice-number logic the gridlines use) so fractional data
    # (proportions, contact quotient, jitter %) is not snapped to a 10-unit grid.
    @emlComputeNiceStep: .globalMax - (.globalMin), emlSetAdaptiveTheme.targetTicksY
    .axisRoundTo = emlComputeNiceStep.step
    @emlComputeAxisRange: .globalMin, .globalMax, .axisRoundTo, 0
    .autoYMin = emlComputeAxisRange.axisMin
    .autoYMax = emlComputeAxisRange.axisMax

    if .vMin = 0 and .vMax = 0
        .yMin = .autoYMin
        .yMax = .autoYMax
    else
        .yMin = .vMin
        .yMax = .vMax
    endif

    # Step 6: X-axis layout
    .xMin = 0.5
    .xMax = max (1, .nCats) + 0.5   ; clamp: a 0-row table would make left = right

    # Step 7: Set viewport and axes
    @emlSetPanelViewport
    Axes: .xMin, .xMax, .yMin, .yMax
    # Physical scale for fill patterns: a 45-degree hatch has to be 45
    # degrees ON THE PAGE, not at whatever angle the two axis ranges imply.
    @emlSetPatternScale: .xMin, .xMax, .yMin, .yMax

    # Step 8: Gridlines
    # gridMode: 1=Horizontal, 2=Off
    if .gridMode = 1
        @emlDrawHorizontalGridlines: .xMin, .xMax, .yMin, .yMax, emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks
    endif

    # Step 9: Draw grouped violins
    .slotWidth = 0.82
    .spacing = .slotWidth / .nSubsDrawn
    .subViolinWidth = .spacing * 0.4

    for .c from 1 to .nCats
        for .s from 1 to .nSubsDrawn
            .n = .cellCount'.c'_'.s'
            if .n >= 1
                .data# = zero# (.n)
                for .k from 1 to .n
                    .data#[.k] = .cellData'.c'_'.s'_'.k'
                endfor

                # Sub-violin x-center
                .totalGroupWidth = (.nSubsDrawn - 1) * .spacing
                .subCenter = .c - .totalGroupWidth / 2 + (.s - 1) * .spacing

                .colorIdx = .s
                @emlDrawViolin: .subCenter, .data#,
                ... emlSetColorPalette.fill$[.colorIdx],
                ... emlSetColorPalette.line$[.colorIdx], .yMin, .yMax,
                ... .subViolinWidth, emlSetColorPalette.pattern[.colorIdx]
            endif
        endfor
    endfor

    # Step 9B: Jittered points overlay
    if variableExists ("prev_gvShowJitter")
        if prev_gvShowJitter = 1
            for .c from 1 to .nCats
                for .s from 1 to .nSubsDrawn
                    .n = .cellCount'.c'_'.s'
                    if .n >= 1
                        jitterData# = zero# (.n)
                        for .k from 1 to .n
                            jitterData#[.k] = .cellData'.c'_'.s'_'.k'
                        endfor
                        .totalGroupWidth = (.nSubsDrawn - 1) * .spacing
                        .subCenter = .c - .totalGroupWidth / 2 + (.s - 1) * .spacing
                        .colorIdx = .s
                        .jitterW = .subViolinWidth * 0.3
                        @emlDrawJitteredPoints: .subCenter, emlSetColorPalette.line$[.colorIdx], emlSetAdaptiveTheme.markerSize * 0.4, .jitterW
                    endif
                endfor
            endfor
        endif
    endif

    # Step 10: Legend (by sub-group) — adaptive placement
    .xMid = (.xMin + .xMax) / 2
    .yMid = (.yMin + .yMax) / 2
    .qTL = 0
    .qTR = 0
    .qBL = 0
    .qBR = 0
    for .c from 1 to .nCats
        for .s from 1 to .nSubsDrawn
            .n = .cellCount'.c'_'.s'
            for .k from 1 to .n
                .val = .cellData'.c'_'.s'_'.k'
                if .val >= .yMid
                    if .c < .xMid
                        .qTL = .qTL + 1
                    else
                        .qTR = .qTR + 1
                    endif
                else
                    if .c < .xMid
                        .qBL = .qBL + 1
                    else
                        .qBR = .qBR + 1
                    endif
                endif
            endfor
        endfor
    endfor
    @emlPlaceElements: .qTL, .qTR, .qBL, .qBR, .xMid, 1
    legendN = .nSubsDrawn
    # The swatch must carry the FILL PATTERN, not just the hue: sub-groups 1
    # and 9 share a hue and differ only in pattern, so a colour-only legend
    # would print two identical swatches against two different names — the
    # same defect the patterns exist to remove, moved into the key.
    legendPatterned = 1
    for .s from 1 to .nSubsDrawn
        .colorIdx = .s
        legendColor$[.s] = emlSetColorPalette.line$[.colorIdx]
        legendFill$[.s] = emlSetColorPalette.fill$[.colorIdx]
        legendPattern[.s] = emlSetColorPalette.pattern[.colorIdx]
        @emlSanitizeLabel: .sub$[.s]
        legendLabel$[.s] = emlSanitizeLabel.result$
    endfor
    .legendCorner$ = emlPlaceElements.corner1$
    @emlDrawLegend: .xMin, .xMax, .yMin, .yMax, .legendCorner$, emlSetAdaptiveTheme.annotSize

    # Step 10B: Disclosures (v1.21). The legend has taken corner1$;
    # @emlDiscloseEnd is told so and keeps the block out of it.
    if .nSkippedRows > 0
        @emlDisclose: string$ (.nSkippedRows)
        ... + " row(s) skipped (missing or non-numeric value).", ""
    endif
    # v1.22: the palette ceiling, said out loud. See Step 3.
    if .nSubsDropped > 0
        @emlDisclose: string$ (.nSubsDropped)
        ... + " sub-group(s) not drawn (palette holds "
        ... + string$ (.maxSubs) + ").",
        ... "Not drawn: " + .droppedSubs$ + " ("
        ... + string$ (.nDroppedSubRows) + " row(s)). The palette defines "
        ... + string$ (.maxSubs) + " distinguishable styles — 8 hues x 3 "
        ... + "fill patterns (solid, diagonal hatch, dots) — so a further "
        ... + "sub-group would repeat a style already in the legend. Reduce "
        ... + "the sub-group column to " + string$ (.maxSubs) + " levels, or "
        ... + "draw the rest as a second figure."
    endif
    @emlDiscloseEnd: .xMin, .xMax, .yMin, .yMax, .qTL, .qTR, .qBL, .qBR,
    ... .legendCorner$

    # Step 11: Axes with category labels
    @emlDrawInnerBoxIf
    @emlDrawAlignedMarksLeft: .yMin, .yMax, emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks

    # Category labels and x-axis label (pre-measured)
    @emlDrawCategoricalXAxis: .nCats, .xMin, .xMax, .yMin, .yMax, .xLabel$
    if emlShowAxisNameY
        Text left: "yes", .yLabel$
    endif

    @emlDrawTitle: .title$, .vpW, .vpH, .xMin, .xMax, .yMin, .yMax

    # Expose axis ranges
    .axisXMin = .xMin
    .axisXMax = .xMax
    .axisYMin = .yMin
    .axisYMax = .yMax

    # Step 12: Reset state
    Colour: "Black"
    Line width: 1.0
    Font size: emlSetAdaptiveTheme.bodySize
endproc



# ============================================================================
# @emlDrawGroupedBoxPlot
# ============================================================================
# Categories on x-axis, sub-groups as side-by-side boxes per category.
# ============================================================================
# Requires: @emlInitDrawingDefaults (or manual global initialization).
# Reads globals: emlPanelOriginX, emlPanelOriginY (via @emlSetAdaptiveTheme).
procedure emlDrawGroupedBoxPlot: .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .catCol$, .subCol$, .valueCol$, .vMin, .vMax

    @emlSetAdaptiveTheme: .vpW, .vpH
    @emlSetColorPalette: .colorMode$
    # Categorical x-axis labels must exist before @emlDrawCategoricalXAxis
    # renders them. In the form path the pre-dispatch block has already
    # measured and this is a no-op; from anywhere else it is the difference
    # between a figure and an aborted script. Must come before this
    # procedure sets its own Axes: the measurement installs its own.
    @emlEnsureCategoricalLabels: .objectId, .catCol$, .vpW, .vpH
    @emlDiscloseBegin: "Grouped box plot"
    # v1.21: the corner the legend takes, so @emlDiscloseEnd can keep the
    # disclosure box out of it. Empty until a legend is actually drawn.
    .legendCorner$ = ""
    @emlSanitizeLabel: .title$
    .title$ = emlSanitizeLabel.result$

    # Extract unique categories and sub-groups via single source
    @emlCountGroups: .objectId, .catCol$
    .nCats = emlCountGroups.nGroups
    for .c from 1 to .nCats
        .cat$[.c] = emlCountGroups.groupLabel$[.c]
    endfor

    @emlCountGroups: .objectId, .subCol$
    .nSubs = emlCountGroups.nGroups
    for .s from 1 to .nSubs
        .sub$[.s] = emlCountGroups.groupLabel$[.s]
    endfor

    # THE PALETTE CEILING — identical to @emlDrawGroupedViolin's, which
    # carries the full note. @emlSetColorPalette holds 8 hues x 3 fill
    # patterns = 24 distinguishable styles; the twenty-fifth sub-group would
    # be drawn exactly like one already on the figure. v1.23 raised the cap
    # from 10 to 24 (the old ten included two literal duplicates — D127).
    # v1.22 makes the drop audible: the dropped sub-groups are named in a
    # disclosure, the legend no longer advertises them, and the slot geometry
    # divides by the drawn count so the boxes stay centred.
    .maxSubs = 24
    .nSubsDrawn = min (.nSubs, .maxSubs)
    .nSubsDropped = .nSubs - .nSubsDrawn
    .droppedSubs$ = ""
    for .s from .nSubsDrawn + 1 to .nSubs
        if .droppedSubs$ <> ""
            .droppedSubs$ = .droppedSubs$ + ", "
        endif
        .droppedSubs$ = .droppedSubs$ + .sub$[.s]
    endfor
    .nDroppedSubRows = 0

    selectObject: .objectId
    .nRows = Get number of rows

    @emlOptimizePaletteContrast: .nSubsDrawn

    for .c from 1 to .nCats
        for .s from 1 to .nSubs
            .cellCount'.c'_'.s' = 0
        endfor
    endfor
    # v1.21: same counter idiom as @emlDrawBoxPlot.
    .nSkippedRows = 0
    # The same reader the analysis uses. See @emlDrawColumnIsClean for what
    # the lenient one cost.
    @emlDrawColumnIsClean: .objectId, .valueCol$
    .cellsClean = emlDrawColumnIsClean.clean

    for .i from 1 to .nRows
        selectObject: .objectId
        .thisCat$ = Get value: .i, .catCol$
        .thisSub$ = Get value: .i, .subCol$
        @eml_readCell: .objectId, .i, .valueCol$, .cellsClean
        .thisVal = eml_readCell.value
        if .thisVal = undefined
            .nSkippedRows = .nSkippedRows + 1
        else
            .cIdx = 0
            for .c from 1 to .nCats
                if .thisCat$ = .cat$[.c]
                    .cIdx = .c
                endif
            endfor
            .sIdx = 0
            for .s from 1 to .nSubs
                if .thisSub$ = .sub$[.s]
                    .sIdx = .s
                endif
            endfor
            # v1.22: rows past the palette ceiling are counted, not silently
            # discarded. See THE PALETTE CEILING note above, where .maxSubs
            # is set (this procedure has no numbered steps; the equivalent
            # note in @emlDrawGroupedViolin sits at its Step 3).
            if .cIdx > 0 and .sIdx > .nSubsDrawn
                .nDroppedSubRows = .nDroppedSubRows + 1
            endif
            if .cIdx > 0 and .sIdx > 0 and .sIdx <= .nSubsDrawn
                .cellCount'.cIdx'_'.sIdx' = .cellCount'.cIdx'_'.sIdx' + 1
                .k = .cellCount'.cIdx'_'.sIdx'
                .cellData'.cIdx'_'.sIdx'_'.k' = .thisVal
            endif
        endif
    endfor

    .globalMin = undefined
    .globalMax = undefined
    for .c from 1 to .nCats
        for .s from 1 to .nSubsDrawn
            .n = .cellCount'.c'_'.s'
            for .k from 1 to .n
                .val = .cellData'.c'_'.s'_'.k'
                if .globalMin = undefined
                    .globalMin = .val
                    .globalMax = .val
                else
                    if .val < .globalMin
                        .globalMin = .val
                    endif
                    if .val > .globalMax
                        .globalMax = .val
                    endif
                endif
            endfor
        endfor
    endfor
    # D111: this is the fallback @emlDrawBoxPlot was told to copy, and it was
    # the silent one. Disclose it in the same words as the rest.
    if .globalMin = undefined
        .globalMin = 0
        .globalMax = 1
        .noDataMsg$ = "NOTE: Grouped box plot — no usable value; empty axes drawn."
        appendInfoLine: .noDataMsg$
    endif
    # Adaptive rounding grid: derive roundTo from a nice step over the data
    # range (the same nice-number logic the gridlines use) so fractional data
    # (proportions, contact quotient, jitter %) is not snapped to a 10-unit grid.
    @emlComputeNiceStep: .globalMax - (.globalMin), emlSetAdaptiveTheme.targetTicksY
    .axisRoundTo = emlComputeNiceStep.step
    @emlComputeAxisRange: .globalMin, .globalMax, .axisRoundTo, 0
    if .vMin = 0 and .vMax = 0
        .yMin = emlComputeAxisRange.axisMin
        .yMax = emlComputeAxisRange.axisMax
    else
        .yMin = .vMin
        .yMax = .vMax
    endif
    .xMin = 0.5
    .xMax = max (1, .nCats) + 0.5   ; clamp: a 0-row table would make left = right

    @emlSetPanelViewport
    Axes: .xMin, .xMax, .yMin, .yMax
    # Physical scale for fill patterns: a 45-degree hatch has to be 45
    # degrees ON THE PAGE, not at whatever angle the two axis ranges imply.
    @emlSetPatternScale: .xMin, .xMax, .yMin, .yMax
    # gridMode: 1=Horizontal, 2=Off
    if .gridMode = 1
        @emlDrawHorizontalGridlines: .xMin, .xMax, .yMin, .yMax, emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks
    endif

    .slotWidth = 0.82
    .spacing = .slotWidth / .nSubsDrawn
    .subBoxWidth = .spacing * 0.35
    for .c from 1 to .nCats
        for .s from 1 to .nSubsDrawn
            .n = .cellCount'.c'_'.s'
            if .n >= 1
                .data# = zero# (.n)
                for .k from 1 to .n
                    .data#[.k] = .cellData'.c'_'.s'_'.k'
                endfor
                .totalGroupWidth = (.nSubsDrawn - 1) * .spacing
                .subCenter = .c - .totalGroupWidth / 2 + (.s - 1) * .spacing
                .colorIdx = .s
                @emlDrawBox: .subCenter, .data#,
                ... emlSetColorPalette.fill$[.colorIdx],
                ... emlSetColorPalette.line$[.colorIdx], .yMin, .yMax,
                ... .subBoxWidth, emlSetColorPalette.pattern[.colorIdx]
            endif
        endfor
    endfor

    if variableExists ("prev_gbShowJitter")
        if prev_gbShowJitter = 1
            for .c from 1 to .nCats
                for .s from 1 to .nSubsDrawn
                    .n = .cellCount'.c'_'.s'
                    if .n >= 1
                        jitterData# = zero# (.n)
                        for .k from 1 to .n
                            jitterData#[.k] = .cellData'.c'_'.s'_'.k'
                        endfor
                        .totalGroupWidth = (.nSubsDrawn - 1) * .spacing
                        .subCenter = .c - .totalGroupWidth / 2 + (.s - 1) * .spacing
                        .colorIdx = .s
                        @emlDrawJitteredPoints: .subCenter, emlSetColorPalette.line$[.colorIdx], emlSetAdaptiveTheme.markerSize * 0.4, .subBoxWidth * 0.3
                    endif
                endfor
            endfor
        endif
    endif

    # Quadrant scoring for adaptive legend placement
    .xMid = (.xMin + .xMax) / 2
    .yMid = (.yMin + .yMax) / 2
    .qTL = 0
    .qTR = 0
    .qBL = 0
    .qBR = 0
    for .c from 1 to .nCats
        for .s from 1 to .nSubsDrawn
            .n = .cellCount'.c'_'.s'
            for .k from 1 to .n
                .val = .cellData'.c'_'.s'_'.k'
                if .val >= .yMid
                    if .c < .xMid
                        .qTL = .qTL + 1
                    else
                        .qTR = .qTR + 1
                    endif
                else
                    if .c < .xMid
                        .qBL = .qBL + 1
                    else
                        .qBR = .qBR + 1
                    endif
                endif
            endfor
        endfor
    endfor
    @emlPlaceElements: .qTL, .qTR, .qBL, .qBR, .xMid, 1

    legendN = .nSubsDrawn
    # The swatch must carry the FILL PATTERN, not just the hue: sub-groups 1
    # and 9 share a hue and differ only in pattern, so a colour-only legend
    # would print two identical swatches against two different names — the
    # same defect the patterns exist to remove, moved into the key.
    legendPatterned = 1
    for .s from 1 to .nSubsDrawn
        .colorIdx = .s
        legendColor$[.s] = emlSetColorPalette.line$[.colorIdx]
        legendFill$[.s] = emlSetColorPalette.fill$[.colorIdx]
        legendPattern[.s] = emlSetColorPalette.pattern[.colorIdx]
        @emlSanitizeLabel: .sub$[.s]
        legendLabel$[.s] = emlSanitizeLabel.result$
    endfor
    .legendCorner$ = emlPlaceElements.corner1$
    @emlDrawLegend: .xMin, .xMax, .yMin, .yMax, .legendCorner$, emlSetAdaptiveTheme.annotSize

    # Disclosures (v1.21). The legend has taken corner1$; @emlDiscloseEnd is
    # told so and keeps the block out of it.
    if .nSkippedRows > 0
        @emlDisclose: string$ (.nSkippedRows)
        ... + " row(s) skipped (missing or non-numeric value).", ""
    endif
    # v1.22: the palette ceiling, in @emlDrawGroupedViolin's exact wording.
    if .nSubsDropped > 0
        @emlDisclose: string$ (.nSubsDropped)
        ... + " sub-group(s) not drawn (palette holds "
        ... + string$ (.maxSubs) + ").",
        ... "Not drawn: " + .droppedSubs$ + " ("
        ... + string$ (.nDroppedSubRows) + " row(s)). The palette defines "
        ... + string$ (.maxSubs) + " distinguishable styles — 8 hues x 3 "
        ... + "fill patterns (solid, diagonal hatch, dots) — so a further "
        ... + "sub-group would repeat a style already in the legend. Reduce "
        ... + "the sub-group column to " + string$ (.maxSubs) + " levels, or "
        ... + "draw the rest as a second figure."
    endif
    @emlDiscloseEnd: .xMin, .xMax, .yMin, .yMax, .qTL, .qTR, .qBL, .qBR,
    ... .legendCorner$

    @emlDrawInnerBoxIf
    @emlDrawAlignedMarksLeft: .yMin, .yMax, emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks

    # Category labels and x-axis label (pre-measured)
    @emlDrawCategoricalXAxis: .nCats, .xMin, .xMax, .yMin, .yMax, .xLabel$
    if emlShowAxisNameY
        Text left: "yes", .yLabel$
    endif

    @emlDrawTitle: .title$, .vpW, .vpH, .xMin, .xMax, .yMin, .yMax

    .axisXMin = .xMin
    .axisXMax = .xMax
    .axisYMin = .yMin
    .axisYMax = .yMax
    Colour: "Black"
    Line width: 1.0
    Font size: emlSetAdaptiveTheme.bodySize
endproc


# ============================================================================
# @emlDrawLMMForest — fixed-effect coefficient forest plot for a fitted LMM.
# ============================================================================
# Reads emlLMM.* (beta#, nFixedCols, formula$), emlWaldCI.* (lower#, upper#)
# and the coefficient labels emlModelMatrix.colName'.j'$. Call after @emlLMM
# and @emlWaldCI. Draws each fixed effect as a point estimate with its 95%
# confidence interval and a zero reference line (a "forest"/coefficient plot —
# the standard LMM graphic). Rule 28: title, garnish suppressed + manual marks,
# viewport asserted, sanitized labels, buffered axis always including zero.
#
# Takes no arguments — the LMM tool calls it as @emlDrawLMMForest. Unlike the
# other draw procedures it is not reached through the graphs form, so the
# display-toggle globals that form normally sets may be undefined; they are
# seeded here rather than assumed (see the guard below).
# Requires: nothing. Reads globals: emlShow* and colorMode$ if already set.
# ============================================================================
procedure emlDrawLMMForest
    .p = emlLMM.nFixedCols

    # X range from CI bounds, always spanning 0, buffered 12%.
    .xmin = 0
    .xmax = 0
    for .j from 1 to .p
        if emlWaldCI.lower# [.j] < .xmin
            .xmin = emlWaldCI.lower# [.j]
        endif
        if emlWaldCI.upper# [.j] > .xmax
            .xmax = emlWaldCI.upper# [.j]
        endif
    endfor
    .rng = .xmax - .xmin
    if .rng <= 0
        .rng = 1
    endif
    .buf = .rng * 0.12
    .xlo = .xmin - .buf
    .xhi = .xmax + .buf

    # Standard single-figure width; height grows with the coefficient count
    # (fixed chrome allowance + one row pitch per coefficient).
    .figW = 6.5
    .rowPitch = 0.5
    .chromeH = 1.6
    .figH = .chromeH + .rowPitch * .p

    # Display-toggle globals are normally set by the graphs form's UI path
    # (eml-graphs-form.praat) or by @emlInitDrawingDefaults. The LMM tool
    # reaches this procedure through neither, so seed them if absent —
    # @emlDrawAlignedMarksBottom reads emlShowTicksX / emlShowAxisValuesX and
    # Praat raises "Unknown variable" on an undefined global inside an if.
    # Same self-heal idiom as the panel-origin guard in @emlSetAdaptiveTheme.
    if variableExists ("emlShowTicksX") = 0
        @emlInitDrawingDefaults
    endif
    if variableExists ("colorMode$") = 0
        colorMode$ = "color"
    endif

    Erase all

    # Theme prologue (Rule 2): font size is set here, once, before any
    # margin-dependent command. Every other draw procedure in this file opens
    # the same way; without it the figure inherits whatever ambient size the
    # Picture window happens to hold and its margins — and therefore its box,
    # ticks and labels — shift between runs.
    @emlSetAdaptiveTheme: .figW, .figH
    @emlSetColorPalette: colorMode$

    Select outer viewport: 0, .figW, 0, .figH
    Axes: .xlo, .xhi, 0.5, .p + 0.7
    Line width: emlSetAdaptiveTheme.axisLineWidth

    # Zero reference line — subordinate to the data, drawn in the axis colour.
    Colour: emlSetAdaptiveTheme.axisColor$
    Draw line: 0, 0.5, 0, .p + 0.5

    # Interval caps and label offset are fractions of the 1.0 world-unit row
    # pitch, not page constants — they scale with the figure automatically.
    .capHalfHeight = 0.13
    .labelOffsetY = 0.30
    .estMarkerSize = emlSetAdaptiveTheme.markerSize * 2.5
    .seriesColor$ = emlSetColorPalette.line$[1]

    # One row per coefficient (first coefficient at the top)
    Colour: .seriesColor$
    for .j from 1 to .p
        .y = .p - .j + 1
        .lo = emlWaldCI.lower# [.j]
        .hi = emlWaldCI.upper# [.j]
        .est = emlLMM.beta# [.j]
        Line width: emlSetAdaptiveTheme.dataLineWidth
        Draw line: .lo, .y, .hi, .y
        Draw line: .lo, .y - .capHalfHeight, .lo, .y + .capHalfHeight
        Draw line: .hi, .y - .capHalfHeight, .hi, .y + .capHalfHeight
        Paint circle (mm): .seriesColor$, .est, .y, .estMarkerSize
        .raw$ = emlModelMatrix.colName'.j'$
        @emlSanitizeLabel: .raw$
        .lab$ = emlSanitizeLabel.result$
        Colour: emlSetAdaptiveTheme.textColor$
        Text: .xlo, "left", .y + .labelOffsetY, "half", .lab$
        Colour: .seriesColor$
    endfor

    Colour: emlSetAdaptiveTheme.axisColor$
    Line width: emlSetAdaptiveTheme.axisLineWidth
    Draw inner box

    # Rule 1: nice-number ticks. A bare "Marks bottom: 5" would divide the
    # 12%-buffered range into four arbitrary intervals.
    @emlDrawAlignedMarksBottom: .xlo, .xhi,
    ... emlSetAdaptiveTheme.targetTicksX, emlSetAdaptiveTheme.useMinorTicks

    Colour: emlSetAdaptiveTheme.textColor$
    if emlShowAxisNameX
        .xlab$ = "Coefficient estimate (95\%  CI)"
        Text bottom: "yes", .xlab$
    endif
    @emlSanitizeLabel: emlLMM.formula$
    .titl$ = "LMM fixed effects: " + emlSanitizeLabel.result$
    Text top: "yes", .titl$

    # Rule 28I: assert the full outer viewport before any downstream save.
    Select outer viewport: 0, .figW, 0, .figH
endproc
