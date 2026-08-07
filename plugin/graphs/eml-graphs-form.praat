# ============================================================================
# EML Graphs — Form System and Workflow
# ============================================================================
# EML Graphs Plugin
# Author: Ian Howell, Embodied Music Lab, www.embodiedmusiclab.com
# License: Creative Commons Share-Alike
# Version: 2.4
# v2.4: D3b — the graph type registry drops from 14 entries to 13. Type 13,
#       "Time Series (with CI)", lost its form page when CI became a toggle on
#       type 5 (Line Chart); the registry row and its dispatch branches stayed
#       behind, unreachable (typeToMenu[13] was 0) and reading three column
#       variables — ciTimeCol$ / ciValueCol$ / ciGroupCol$ — that nothing ever
#       wrote. Spaghetti Plot moves 14 -> 13; nGraphTypes and all six parallel
#       registry arrays, menuToType[16] and typeToMenu shrink with it.
#       @emlDrawTimeSeriesCI is untouched and still dispatched from type 5.
#       CALLERS: any script setting emlGraphsPresetType = 14 for a spaghetti
#       plot must now set 13.
# v2.3: D18/D65/D32/D60/D108.
#       * D18 + D65 (filename half) — the Draw path's Export Results dialog
#         proposed selected$ ("Table") + "_results" on originalSourceId, which
#         named the transient `pairedLong` reshape on the paired workflow and
#         carried no analysis identity anywhere. New @emlGraphsCSVDefaultName /
#         @emlGraphsCSVRowAnalysis read the source table and the analysis off
#         the CSV buffer that is about to be written, giving the same
#         <table>_<analysis-slug> shape as @emlWrapperExportCSV. D65's other
#         half (Draw exporting a different test family than the analysis that
#         launched it) is a bridge design decision and is untouched.
#       * D32 (remaining half) — declared emlGraphsPresetSubgroupCol$ so a
#         wrapper can name its actual second factor, and consumed it in the
#         Grouped Violin and Grouped Box preset branches ahead of the role
#         guesser. A preset that collides with Category or Value is demoted and
#         the guesser runs as before.
#       * D60 — new @emlGraphsIsPercentageColumn, and the two
#         @emlComputeAxisRange calls here now pass it instead of a literal 0,
#         which is the first time that procedure's .isPercentage branch has
#         ever executed. Detection needs BOTH a percentage-looking name and
#         data inside 0-100.
#       * D108 — the correction preset's string and its dialog index are now
#         derived from one validated index via @emlAdjustMethodName, so they
#         cannot disagree, and an unrecognised preset is reported where it was
#         set. Consuming it on the parametric path is in
#         eml-annotation-procedures.praat, not here.
# v2.2: Item 8 — two further preset-plumbing defects. (a) The spaghetti-plot
#       column-mapping dialog never consumed emlGraphsPresetGroupCol$; it
#       relied on a name heuristic that runs only on the first spaghetti draw
#       of a session, so a later Draw from a stats wrapper silently dropped
#       the requested grouping. Added the spPresetHasGroup / spPresetGroupIdx
#       sentinel, mirroring scatter and histogram. (b) emlGraphsPresetXCol$
#       and emlGraphsPresetYCol$ were cleared only inside the scatter page,
#       so they leaked into the next workflow call whenever the user chose a
#       non-scatter graph type; both are now cleared at workflow end.
# v2.1: Item 8 — histogram column-mapping dialog now honours an incoming
#       group-column preset. The preset seeded histGroupIdx but left
#       "Use group column" unchecked, so histGroupCol$ committed as "" and
#       the grouped-histogram annotation route at the dispatch was silently
#       skipped even though the caller had asked to annotate. Added the
#       histPresetHasGroup sentinel, mirroring scatterPresetHasGroup.
# v2.0: Item 6 — multiple-comparison adjustment is now user-facing instead
#       of a hardcoded "holm". Added an "Adjustment method" optionmenu
#       (Bonferroni / Holm / Benjamini-Hochberg, default Holm) to all six
#       annotate-capable column-mapping dialogs, backed by the shared
#       prev_annotAdjustIdx persistence variable and the @emlAdjustMethodName
#       index-to-string helper. Added the emlGraphsPresetCorrection$ preset
#       global so stats wrappers can carry their own adjustment choice in.
# v1.9: Bar-chart negative-mean support in the annotated (bracket) path —
#       auto-range now floors on emlBarData_visibleMin so all-/mixed-negative
#       means are not clipped at 0 (positive data unchanged via the axis
#       procedure's non-negative guard). Companion to eml-graph-procedures
#       v3.21 / eml-draw-procedures v1.18.
# v1.8: Post-draw dialog "Back" renamed to "Done".
# Date: 11 May 2026
#
# v1.7: emlShowExplanations = 1 set in @emlGraphsWorkflow entry point
#        (explanations on wizard + graphs paths, not wrapper output).
#        Added emlGraphsPresetRegressionLine and emlGraphsPresetCorrType$
#        preset globals — consumed after per-call reset, survive workflow.
# v1.6: Item 22 fix — beginner Draw path no longer resets
#        annotTestType$/annotStyle$ to defaults. These fields are
#        only meaningful when annotate=1 (advanced mode). Resetting
#        them in beginner mode destroyed preset test type on Redraw.
#        Fixed across all 5 form types (bar, violin, box, grouped
#        violin, grouped box).
# v1.5: Scatter group column preset (item 21). Added
#        scatterPresetHasGroup sentinel. Scatter form now consumes
#        emlGraphsPresetGroupCol$ alongside X/Y presets, auto-checks
#        "Use group column" checkbox when a group preset is provided.
#
# v1.4: Scatter preset globals (emlGraphsPresetXCol$, emlGraphsPresetYCol$)
#        added for stats wrapper wiring. Consumed in scatter form section
#        to auto-select X/Y columns from eml-correlate.praat presets.
#
# v1.3: Fix — group_order captures added to all 9 Draw branches (were
#        only in toggle branches). Moved emlGroupSortAlphabetical set
#        before annotation bridge (was after bridge, causing matrix to
#        lag one draw behind graph ordering). Value column moved to
#        first position in Grouped Violin, Grouped Box, and Spaghetti
#        forms. Spaghetti: parenthetical field descriptions, boolean
#        "Use group column" (replaces "(none)" option), spaghetti-
#        specific prev_spGroupSort defaulting to table order. Legend
#        labels sanitized in TimeSeries, TimeSeriesCI, Spaghetti.
#
# v1.2: Fix — group_order captures were in toggle branch (clicked=3)
#        only; Draw branch (else) never committed the user's selection.
#        Added prev_groupSort + config_groupSort captures to all 9
#        Draw branches. Group sort now takes effect and persists on
#        redraw.
#
# v1.1: Bug #14 — Save dialog replaced chooseWriteFile$ with folder +
#        auto-generated filename (Appendix F §S9). Bug #15 — post-save
#        dead end removed; save returns to main post-draw dialog so
#        CSV export remains available after saving. Sub-dialog buttons
#        use "Cancel" (returns to loop). PNG and CSV folder persistence
#        tracked separately (config_lastPNGFolder$, config_lastCSVFolder$).
#        Default folder is Desktop, not plugin directory. Backward-
#        compatible config load (old lastOutputFolder key populates both).
#        Group sort order dropdown on all 9 group-having graph types
#        (Table order / Alphabetical). Config-persisted via groupSort
#        key. Controls @emlCountGroups via emlGroupSortAlphabetical.
#
# Purpose: Interactive form workflow for EML Graphs. Contains the graph type
#          registry, config persistence, context detection, type-specific
#          form dialogs, and the main drawing workflow. Called by eml-graphs.praat
#          (standalone entry), stats wrappers (after convergence), and the
#          wizard (after convergence).
#
# This file provides @emlGraphsWorkflow: .objectId — the single entry point
#          for all interactive graph creation. It is not part of the draw-layer
#          API used by advanced coders or PraatGen.
#
# Dependencies (must be included by the calling script BEFORE this file):
#   ../graphs/eml-graph-procedures.praat
#   ../graphs/eml-annotation-procedures.praat
#   ../graphs/eml-draw-procedures.praat
#   ../stats/eml-core-utilities.praat
#   ../stats/eml-core-descriptive.praat
#   ../stats/eml-extract.praat
#   ../stats/eml-output.praat
#   ../stats/eml-inferential.praat
# ============================================================================

# ============================================================================
# FILE-SCOPE INITIALIZATION
# ============================================================================
# These run at include time. They set up sentinel variables and preset globals.
# No procedure calls, no object operations.

# Workflow sentinel — persistence vars initialized on first workflow call
emlGraphsInitDone = 0

# Preset globals — callers set these before @emlGraphsWorkflow
emlGraphsPresetType = 0
emlGraphsPresetDataCol$ = ""
emlGraphsPresetGroupCol$ = ""
# D32. The bridge carried a category and a value column and had no slot at all
# for a SECOND factor, so a two-way wrapper could not say which column its
# `factor2$` was and the Grouped Violin / Grouped Box pages had to guess. The
# guess is still there as a fallback, but a caller that KNOWS its second factor
# now has somewhere to put it, and what it puts there wins.
emlGraphsPresetSubgroupCol$ = ""
emlGraphsPresetTestType$ = ""
emlGraphsPresetAnnotate = 0
emlGraphsPresetAnalysisType = 0
emlGraphsPresetXCol$ = ""
emlGraphsPresetYCol$ = ""
emlGraphsPresetRegressionLine = 0
emlGraphsPresetCorrType$ = ""
emlGraphsPresetCorrection$ = ""
# Scatter dot presets. 0 / -1 mean "not supplied" — a wrapper that wants the
# figure drawn with a particular dot size or with points hidden sets these,
# and the D103 sentinels below make that choice beat the remembered previous
# dialog value on the second and later scatter of a session.
#
# NOTE (7 Aug 2026): these two are the only preset slots no shipping caller
# writes. Every other emlGraphsPreset* is set by at least one of the stats
# wrappers; these are set ONLY here and in the clear block at the end of
# @emlGraphsWorkflow, so the two reads in PRESET READING never fire in
# practice. That is not a defect and the reads are not dead: the sentinels
# below are exactly what make "unset" safe, so both branches are correctly
# skipped rather than acting on an undefined value. The slot is left wired
# end to end because it is the bridge's only channel for dot appearance —
# the wrapper side is the half that is missing, not this one. Anything that
# changes here must change in the clear block too.
emlGraphsPresetDotSize = 0
emlGraphsPresetShowDots = -1

# D103 — "a preset arrived for this call" sentinels.
#
# The scatter column-mapping page rebuilds its dialog defaults on every pass.
# It used to do that by copying prev_* over whatever the preset bridge had
# just set, so the FIRST scatter in a session honoured the wrapper's preset
# (prev_* was still at its "unset" initializer) and every later one silently
# discarded it in favour of the last dialog's choice. Each sentinel is raised
# only when a preset was actually supplied, and cleared as soon as the page
# consumes it, so a preset wins when present and the remembered value still
# applies when it is absent. Same shape as scatterPresetHasGroup.
scatterPresetHasRegression = 0
scatterPresetHasDotSize = 0
scatterPresetHasDots = 0
scatterPresetHasGroup = 0
histPresetHasGroup = 0
spPresetHasGroup = 0
spPresetGroupIdx = 0

# ============================================================================
# GRAPH TYPE REGISTRY
# ============================================================================

# D3b. The registry used to declare 14 types. Type 13 was "Time Series (with
# CI)", whose form page was folded into type 5 (Line Chart) as a "Show
# confidence interval" toggle — the page went, the registry row stayed, and
# typeToMenu[13] = 0 meant the row could not be reached from the menu at all.
# A registry entry no user can select and no page can fill is a sign pointing
# at a demolished room, so it is gone and Spaghetti Plot has moved up into 13.
# @emlDrawTimeSeriesCI is unaffected: it is still dispatched from type 5.
nGraphTypes = 13

graphTypeName$[1] = "Pitch Contour"
graphTypeName$[2] = "Waveform"
graphTypeName$[3] = "Spectrum"
graphTypeName$[4] = "LTAS"
graphTypeName$[5] = "Line Chart (±CI)"
graphTypeName$[6] = "Bar Chart"
graphTypeName$[7] = "Violin Plot"
graphTypeName$[8] = "Scatter Plot"
graphTypeName$[9] = "Box Plot"
graphTypeName$[10] = "Histogram"
graphTypeName$[11] = "Grouped Violin"
graphTypeName$[12] = "Grouped Box Plot"
graphTypeName$[13] = "Spaghetti Plot"

requiredType$[1] = "Pitch"
requiredType$[2] = "Sound"
requiredType$[3] = "Spectrum"
requiredType$[4] = "Ltas"
requiredType$[5] = "Table"
requiredType$[6] = "Table"
requiredType$[7] = "Table"
requiredType$[8] = "Table"
requiredType$[9] = "Table"
requiredType$[10] = "Table"
requiredType$[11] = "Table"
requiredType$[12] = "Table"
requiredType$[13] = "Table"

defaultXLabel$[1] = "Time (s)"
defaultXLabel$[2] = "Time (s)"
defaultXLabel$[3] = "Frequency (Hz)"
defaultXLabel$[4] = "Frequency (Hz)"
defaultXLabel$[5] = ""
defaultXLabel$[6] = ""
defaultXLabel$[7] = ""
defaultXLabel$[8] = ""
defaultXLabel$[9] = ""
defaultXLabel$[10] = ""
defaultXLabel$[11] = ""
defaultXLabel$[12] = ""
defaultXLabel$[13] = ""

defaultYLabel$[1] = "Frequency (Hz)"
defaultYLabel$[2] = "Amplitude (Pa)"
defaultYLabel$[3] = "Power (dB)"
defaultYLabel$[4] = "Power (dB/Hz)"
defaultYLabel$[5] = ""
defaultYLabel$[6] = ""
defaultYLabel$[7] = ""
defaultYLabel$[8] = ""
defaultYLabel$[9] = ""
defaultYLabel$[10] = ""
defaultYLabel$[11] = ""
defaultYLabel$[12] = ""
defaultYLabel$[13] = ""

hasGridlines[1] = 1
hasGridlines[2] = 1
hasGridlines[3] = 1
hasGridlines[4] = 1
hasGridlines[5] = 1
hasGridlines[6] = 1
hasGridlines[7] = 1
hasGridlines[8] = 1
hasGridlines[9] = 1
hasGridlines[10] = 1
hasGridlines[11] = 1
hasGridlines[12] = 1
hasGridlines[13] = 1

isTableType[1] = 0
isTableType[2] = 0
isTableType[3] = 0
isTableType[4] = 0
isTableType[5] = 1
isTableType[6] = 1
isTableType[7] = 1
isTableType[8] = 1
isTableType[9] = 1
isTableType[10] = 1
isTableType[11] = 1
isTableType[12] = 1
isTableType[13] = 1

# ============================================================================
# MENU ↔ TYPE MAPPING (divider support)
# ============================================================================
# menuToType[menuIdx] → internal type ID (0 = divider)
# typeToMenu[typeId]  → menu index for persistence

nMenuItems = 16

menuLabel$[1] = "--- Acoustic ---"
menuLabel$[2] = "Pitch Contour"
menuLabel$[3] = "Waveform"
menuLabel$[4] = "Spectrum"
menuLabel$[5] = "LTAS"
menuLabel$[6] = "--- Categorical ---"
menuLabel$[7] = "Violin Plot"
menuLabel$[8] = "Grouped Violin"
menuLabel$[9] = "Box Plot"
menuLabel$[10] = "Grouped Box Plot"
menuLabel$[11] = "Histogram"
menuLabel$[12] = "--- Continuous ---"
menuLabel$[13] = "Bar Chart"
menuLabel$[14] = "Scatter Plot"
menuLabel$[15] = "Line Chart (±CI)"
menuLabel$[16] = "Spaghetti Plot"

menuToType[1] = 0
menuToType[2] = 1
menuToType[3] = 2
menuToType[4] = 3
menuToType[5] = 4
menuToType[6] = 0
menuToType[7] = 7
menuToType[8] = 11
menuToType[9] = 9
menuToType[10] = 12
menuToType[11] = 10
menuToType[12] = 0
menuToType[13] = 6
menuToType[14] = 8
menuToType[15] = 5
menuToType[16] = 13

typeToMenu[1] = 2
typeToMenu[2] = 3
typeToMenu[3] = 4
typeToMenu[4] = 5
typeToMenu[5] = 15
typeToMenu[6] = 13
typeToMenu[7] = 7
typeToMenu[8] = 14
typeToMenu[9] = 9
typeToMenu[10] = 11
typeToMenu[11] = 8
typeToMenu[12] = 10
typeToMenu[13] = 16

# ============================================================================
# PROCEDURES — Utilities
# ============================================================================

# ----------------------------------------------------------------------------
# @emlGenerateUniquePath
# Appends ascending integer to filename until path is available.
# Arguments: .path$ (original desired path)
# Outputs: .result$ (available path)
# ----------------------------------------------------------------------------
procedure emlGenerateUniquePath: .path$
    if not fileReadable (.path$)
        .result$ = .path$
    else
        # Split into directory, base, extension
        .lastSlash = rindex (.path$, "/")
        if .lastSlash > 0
            .dir$ = left$ (.path$, .lastSlash)
            .filename$ = mid$ (.path$, .lastSlash + 1, length (.path$) - .lastSlash)
        else
            .dir$ = ""
            .filename$ = .path$
        endif

        .lastDot = rindex (.filename$, ".")
        if .lastDot > 0
            .base$ = left$ (.filename$, .lastDot - 1)
            .ext$ = mid$ (.filename$, .lastDot, length (.filename$) - .lastDot + 1)
        else
            .base$ = .filename$
            .ext$ = ""
        endif

        .counter = 1
        .result$ = .dir$ + .base$ + "_" + string$ (.counter) + .ext$
        while fileReadable (.result$)
            .counter = .counter + 1
            .result$ = .dir$ + .base$ + "_" + string$ (.counter) + .ext$
        endwhile
    endif
endproc

# ----------------------------------------------------------------------------
# @emlPickFromMultiple
# When multiple objects of the same type are selected, present a choice form.
# Arguments: .type$ (object type name)
# Outputs: .result (selected object ID)
# ----------------------------------------------------------------------------
procedure emlPickFromMultiple: .type$
    .n = numberOfSelected (.type$)
    for .i from 1 to .n
        .id[.i] = selected (.type$, .i)
        .name$[.i] = selected$ (.type$, .i)
    endfor

    beginPause: "Multiple " + .type$ + " objects"
        comment: "Which " + .type$ + " object do you want to use?"
        optionmenu: "Object choice", 1
            for .i from 1 to .n
                .displayName$ = .name$[.i]
                option: .displayName$
            endfor
    .clicked = endPause: "Quit", "OK", 2, 1

    if .clicked = 1
        exitScript: ""
    endif

    .result = .id[object_choice]
endproc

# ----------------------------------------------------------------------------
# @emlCleanConvertedTable
# After converting TableOfReal or Matrix → Table, fix "?" placeholders.
# Praat's To Table: "row" writes "?" for empty row/column labels.
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

    # Fix "?" column headers → "Column_N"
    for .iCol from 1 to .nCols
        .colLabel$ = Get column label: .iCol
        if .colLabel$ = "?"
            Rename column (by number): .iCol, "Column_" + string$ (.iCol)
        endif
    endfor

    # Fix "?" cells in the row-label column
    for .iRow from 1 to .nRows
        .cellVal$ = Get value: .iRow, .rowColName$
        if .cellVal$ = "?"
            Set string value: .iRow, .rowColName$, string$ (.iRow)
        endif
    endfor
endproc

# ============================================================================
# PROCEDURES — Config persistence
# ============================================================================

# ----------------------------------------------------------------------------
# @emlLoadConfig
# Reads config file from preferences directory. Populates global config_*
# variables. Handles missing file, partial file, and malformed lines gracefully.
# Arguments: none
# Outputs: populates global config_* variables
# ----------------------------------------------------------------------------
procedure emlLoadConfig
    # Set defaults first — these persist if file missing or key absent
    config_graphType = 1
    config_source = 1
    config_colorMode = 1
    config_width = 6
    config_height = 4
    config_gridlineMode = 1
    config_showInnerBox = 1
    config_showAxisNames = 2
    config_showTicks = 2
    config_showAxisValues = 2
    config_font$ = "Helvetica"
    config_font = 1
    config_outputDPI = 1
    config_xLabel$ = ""
    config_yLabel$ = ""
    config_lastInputFolder$ = ""
    # Default to Desktop; fall back to home directory
    if folderExists (homeDirectory$ + "/Desktop")
        config_lastPNGFolder$ = homeDirectory$ + "/Desktop"
        config_lastCSVFolder$ = homeDirectory$ + "/Desktop"
    else
        config_lastPNGFolder$ = homeDirectory$
        config_lastCSVFolder$ = homeDirectory$
    endif
    config_showAdvanced = 0
    config_subtitle$ = ""
    config_groupSort = 1

    # Build config file path
    .configPath$ = preferencesDirectory$ + "/eml-graphs-config.txt"

    # Check if file exists
    if not fileReadable (.configPath$)
        # No config file — defaults already set
    else
        # Read entire file
        .fileContent$ = readFile$ (.configPath$)

        # Parse line by line
        .remaining$ = .fileContent$

        while length (.remaining$) > 0
            # Find next newline
            .newlinePos = index (.remaining$, newline$)

            if .newlinePos > 0
                .line$ = left$ (.remaining$, .newlinePos - 1)
                .remaining$ = mid$ (.remaining$, .newlinePos + 1, length (.remaining$) - .newlinePos)
            else
                .line$ = .remaining$
                .remaining$ = ""
            endif

            # Skip empty lines
            if length (.line$) > 0
                .colonPos = index (.line$, ":")

                if .colonPos > 1
                    .key$ = left$ (.line$, .colonPos - 1)
                    .afterColon$ = mid$ (.line$, .colonPos + 1, length (.line$) - .colonPos)

                    # Strip leading space
                    if left$ (.afterColon$, 1) = " "
                        .value$ = mid$ (.afterColon$, 2, length (.afterColon$) - 1)
                    else
                        .value$ = .afterColon$
                    endif

                    # Match key to known keys
                    if .key$ = "graphType"
                        config_graphType = number (.value$)
                    elsif .key$ = "source"
                        config_source = number (.value$)
                    elsif .key$ = "colorMode"
                        config_colorMode = number (.value$)
                    elsif .key$ = "width"
                        config_width = number (.value$)
                    elsif .key$ = "height"
                        config_height = number (.value$)
                    elsif .key$ = "gridlineMode"
                        config_gridlineMode = number (.value$)
                    elsif .key$ = "showInnerBox"
                        config_showInnerBox = number (.value$)
                    elsif .key$ = "showTicks"
                        config_showTicks = number (.value$)
                    elsif .key$ = "showAxisValues"
                        config_showAxisValues = number (.value$)
                    elsif .key$ = "showAxisNames"
                        config_showAxisNames = number (.value$)
                    elsif .key$ = "font"
                        config_font$ = .value$
                        config_font = 1
                        if config_font$ = "Times"
                            config_font = 2
                        elsif config_font$ = "Palatino"
                            config_font = 3
                        elsif config_font$ = "Courier"
                            config_font = 4
                        endif
                    elsif .key$ = "outputDPI"
                        config_outputDPI = number (.value$)
                    elsif .key$ = "xLabel"
                        config_xLabel$ = .value$
                    elsif .key$ = "yLabel"
                        config_yLabel$ = .value$
                    elsif .key$ = "lastInputFolder"
                        config_lastInputFolder$ = .value$
                    elsif .key$ = "lastPNGFolder"
                        config_lastPNGFolder$ = .value$
                    elsif .key$ = "lastCSVFolder"
                        config_lastCSVFolder$ = .value$
                    elsif .key$ = "lastOutputFolder"
                        # Backward compat: old key stored full path,
                        # strip filename to get folder only
                        .lastSlash = rindex (.value$, "/")
                        if .lastSlash > 0
                            .value$ = left$ (.value$, .lastSlash - 1)
                        endif
                        config_lastPNGFolder$ = .value$
                        config_lastCSVFolder$ = .value$
                    elsif .key$ = "showAdvanced"
                        config_showAdvanced = number (.value$)
                    elsif .key$ = "subtitle"
                        config_subtitle$ = .value$
                    elsif .key$ = "groupSort"
                        config_groupSort = number (.value$)
                    endif
                endif
            endif
        endwhile
    endif
endproc

# ----------------------------------------------------------------------------
# @emlSaveConfig
# Writes current config_* variables to config file in preferences directory.
# Arguments: none
# Outputs: writes config file to disk
# ----------------------------------------------------------------------------
procedure emlSaveConfig
    .configPath$ = preferencesDirectory$ + "/eml-graphs-config.txt"

    writeFileLine: .configPath$, "graphType: ", config_graphType
    appendFileLine: .configPath$, "source: ", config_source
    appendFileLine: .configPath$, "colorMode: ", config_colorMode
    appendFileLine: .configPath$, "width: ", config_width
    appendFileLine: .configPath$, "height: ", config_height
    appendFileLine: .configPath$, "gridlineMode: ", config_gridlineMode
    appendFileLine: .configPath$, "showInnerBox: ", config_showInnerBox
    appendFileLine: .configPath$, "showAxisNames: ", config_showAxisNames
    appendFileLine: .configPath$, "showTicks: ", config_showTicks
    appendFileLine: .configPath$, "showAxisValues: ", config_showAxisValues
    appendFileLine: .configPath$, "font: ", config_font$
    appendFileLine: .configPath$, "outputDPI: ", config_outputDPI
    appendFileLine: .configPath$, "xLabel: ", config_xLabel$
    appendFileLine: .configPath$, "yLabel: ", config_yLabel$
    appendFileLine: .configPath$, "lastInputFolder: ", config_lastInputFolder$
    appendFileLine: .configPath$, "lastPNGFolder: ", config_lastPNGFolder$
    appendFileLine: .configPath$, "lastCSVFolder: ", config_lastCSVFolder$
    appendFileLine: .configPath$, "showAdvanced: ", config_showAdvanced
    appendFileLine: .configPath$, "subtitle: ", config_subtitle$
    appendFileLine: .configPath$, "groupSort: ", config_groupSort
endproc

# ============================================================================
# PROCEDURES — Context detection
# ============================================================================

# ----------------------------------------------------------------------------
# @emlDetectContext
# Examines current selection in the Objects window and sets advisory defaults.
# Arguments: none
# Outputs: contextGraphType, contextObjectId, contextObjectName$,
#          contextNCols, contextColName$[1..n] (for Tables),
#          contextObjectType$ (string name of detected type for menu filtering),
#          contextOriginalSourceId (object for Draw Another re-selection)
# ----------------------------------------------------------------------------
procedure emlDetectContext
    contextGraphType = 0
    contextObjectId = 0
    contextObjectName$ = ""
    contextNCols = 0
    contextObjectType$ = ""
    contextOriginalSourceId = 0

    # Check each recognized type in priority order
    if numberOfSelected ("Pitch") = 1
        contextGraphType = 1
        contextObjectId = selected ("Pitch")
        contextObjectName$ = selected$ ("Pitch")
        contextObjectType$ = "Pitch"
    elsif numberOfSelected ("Sound") = 1
        contextGraphType = 2
        contextObjectId = selected ("Sound")
        contextObjectName$ = selected$ ("Sound")
        contextObjectType$ = "Sound"
    elsif numberOfSelected ("Spectrum") = 1
        contextGraphType = 3
        contextObjectId = selected ("Spectrum")
        contextObjectName$ = selected$ ("Spectrum")
        contextObjectType$ = "Spectrum"
    elsif numberOfSelected ("Ltas") = 1
        contextGraphType = 4
        contextObjectId = selected ("Ltas")
        contextObjectName$ = selected$ ("Ltas")
        contextObjectType$ = "Ltas"
    elsif numberOfSelected ("Table") = 1
        contextGraphType = 7
        contextObjectId = selected ("Table")
        contextObjectName$ = selected$ ("Table")
        contextObjectType$ = "Table"
    elsif numberOfSelected ("TableOfReal") = 1
        # Convert TableOfReal → Table; Table persists as the working object
        .torId = selected ("TableOfReal")
        contextObjectName$ = selected$ ("TableOfReal")
        contextObjectType$ = "TableOfReal"
        selectObject: .torId
        contextObjectId = To Table: "row"
        @emlCleanConvertedTable: contextObjectId
        contextGraphType = 7
        appendInfoLine: "NOTE: TableOfReal """ + contextObjectName$ + """ converted to Table for graphing."
    elsif numberOfSelected ("Matrix") = 1
        # Convert Matrix → TableOfReal → Table; Table persists as the working object
        .matId = selected ("Matrix")
        contextObjectName$ = selected$ ("Matrix")
        contextObjectType$ = "Matrix"
        selectObject: .matId
        .tempTorId = To TableOfReal
        contextObjectId = To Table: "row"
        removeObject: .tempTorId
        @emlCleanConvertedTable: contextObjectId
        contextGraphType = 7
        appendInfoLine: "NOTE: Matrix """ + contextObjectName$ + """ converted to Table for graphing."
    endif

    # For all types, originalSourceId = the working object (including converted Tables)
    contextOriginalSourceId = contextObjectId

    # Snapshot column names for Table-type objects
    if (contextObjectType$ = "Table" or contextObjectType$ = "TableOfReal"
    ... or contextObjectType$ = "Matrix") and contextObjectId > 0
        selectObject: contextObjectId
        contextNCols = Get number of columns
        for .i from 1 to contextNCols
            contextColName$[.i] = Get column label: .i
        endfor
    endif
endproc

# ----------------------------------------------------------------------------
# @emlBuildFilteredMenu
# Builds filtered menu arrays based on which graph types are reachable from
# the currently detected context object type. Dividers are included only if
# at least one item in their category is valid.
# Arguments: none (reads contextObjectType$, menuLabel$[], menuToType[], nMenuItems)
# Outputs: filteredMenuLabel$[], filteredMenuToType[], filteredTypeToMenu[],
#          filteredNMenuItems
# ----------------------------------------------------------------------------
procedure emlBuildFilteredMenu
    # Step 1: Determine which internal types (1–13) are valid
    for .iType from 1 to nGraphTypes
        .typeValid[.iType] = 0
    endfor

    if contextObjectType$ = ""
        # Nothing selected — all types valid
        for .iType from 1 to nGraphTypes
            .typeValid[.iType] = 1
        endfor
    elsif contextObjectType$ = "Pitch"
        .typeValid[1] = 1
    elsif contextObjectType$ = "Sound"
        .typeValid[1] = 1
        .typeValid[2] = 1
        .typeValid[3] = 1
        .typeValid[4] = 1
    elsif contextObjectType$ = "Spectrum"
        .typeValid[1] = 1
        .typeValid[2] = 1
        .typeValid[3] = 1
        .typeValid[4] = 1
    elsif contextObjectType$ = "Ltas"
        .typeValid[4] = 1
    elsif contextObjectType$ = "Table" or contextObjectType$ = "TableOfReal" or contextObjectType$ = "Matrix"
        for .iType from 5 to nGraphTypes
            .typeValid[.iType] = 1
        endfor
    endif

    # Step 2: Build filtered menu with divider lookahead
    # A divider is included only if at least one item after it (before the
    # next divider or end of list) maps to a valid type.
    filteredNMenuItems = 0

    .iMenu = 1
    while .iMenu <= nMenuItems
        if menuToType[.iMenu] = 0
            # This is a divider — check if any following items are valid
            .dividerIdx = .iMenu
            .hasValidChild = 0
            .nextMenu = .iMenu + 1
            while .nextMenu <= nMenuItems and .hasValidChild = 0
                if menuToType[.nextMenu] = 0
                    # Hit next divider — stop scanning
                    .nextMenu = nMenuItems + 1
                else
                    if .typeValid[menuToType[.nextMenu]]
                        .hasValidChild = 1
                    endif
                    .nextMenu = .nextMenu + 1
                endif
            endwhile

            if .hasValidChild
                filteredNMenuItems = filteredNMenuItems + 1
                filteredMenuLabel$[filteredNMenuItems] = menuLabel$[.dividerIdx]
                filteredMenuToType[filteredNMenuItems] = 0
            endif
        else
            # Regular item — include if type is valid
            if .typeValid[menuToType[.iMenu]]
                filteredNMenuItems = filteredNMenuItems + 1
                filteredMenuLabel$[filteredNMenuItems] = menuLabel$[.iMenu]
                filteredMenuToType[filteredNMenuItems] = menuToType[.iMenu]
            endif
        endif
        .iMenu = .iMenu + 1
    endwhile

    # Step 3: Build reverse lookup (typeId → filtered menu index)
    for .iType from 1 to nGraphTypes
        filteredTypeToMenu[.iType] = 0
    endfor
    for .iFiltered from 1 to filteredNMenuItems
        if filteredMenuToType[.iFiltered] > 0
            filteredTypeToMenu[filteredMenuToType[.iFiltered]] = .iFiltered
        endif
    endfor
endproc


# ============================================================================
# ADJUSTMENT-METHOD LOOKUP
# ============================================================================
# Maps the "Adjustment method (nonparametric post-hoc only)" optionmenu index
# used by every annotate-capable column-mapping dialog onto the string that
# @emlBridgeGroupComparison expects in annotCorrectionMethod$. Index 2 (Holm)
# is the default everywhere.
#
# D25. The control is consumed ONLY on the nonparametric (Dunn) post-hoc path.
# A parametric k >= 3 comparison annotates with Tukey, which carries its own
# correction, so the setting is inert there. Praat cannot grey a field out
# conditionally inside a single form — the whole form is built before the user
# touches anything — so the field NAME carries the condition instead. The
# parenthesised part is stripped by Praat when it derives the variable name,
# so the value still arrives as adjustment_method and no call site changes.
#
# Arguments:
#   .idx — 1 = Bonferroni, 2 = Holm, 3 = Benjamini-Hochberg
# Outputs:
#   .name$ — "bonferroni", "holm", or "bh"
# ============================================================================
procedure emlAdjustMethodName: .idx
    if .idx = 1
        .name$ = "bonferroni"
    elsif .idx = 3
        .name$ = "bh"
    else
        .name$ = "holm"
    endif
endproc


# ============================================================================
# CSV EXPORT FILENAME
# ============================================================================
# D18 + D65 (filename half). The Draw path proposed
# selected$ ("Table") + "_results" on originalSourceId. Two things were wrong
# with that.
#
# D18: originalSourceId is the object the graph was drawn from, which for the
# paired workflow is the `pairedLong` wide-to-long reshape the wrapper builds
# for the spaghetti plot. The user never created it, never named it and never
# sees it again — so the deliverable was named after a transient the user
# cannot connect to anything, while the rows INSIDE the file correctly said
# `demo_paired`. The name now comes from the same place the body does.
#
# D65 (filename half): "_results" carries no analysis identity, so three
# different analyses on one table proposed one name and arrived as
# `t_results.csv`, `_1.csv`, `_2.csv` — distinguishable only by opening them.
# The wrapper side (@emlWrapperExportCSV, stats/eml-output.praat) was fixed to
# <table>_<analysis-slug>; this is the same convention with the same slug
# rules, so the two export routes cannot drift.
#
# Both halves are read off the CSV buffer rather than off the drawing state on
# purpose: the filename then describes the bytes that are about to be written,
# whatever produced them. When the buffer is empty or unparseable the old
# <table>_results shape is still produced, from the caller's fallback name.
#
# NOT FIXED HERE — D65's other half. D65 also reports that the Draw path can
# export a DIFFERENT test family than the analysis the user launched (drawing
# after "Pairwise comparisons" exported ANOVA/Tukey rows, because the draw
# bridge re-runs its own test and overwrites the buffer). Naming the file after
# the buffer makes that visible instead of hiding it behind the table name, but
# it does not fix it. Which result should win — the wrapper's analysis or the
# figure's annotation — is a design decision about the bridge, not a naming
# question, and is deliberately left alone here.
#
# Arguments:
#   .fallbackTable$ — table name to use when the buffer carries none
# Outputs:
#   .result$ — proposed file name, without extension
# ============================================================================
procedure emlGraphsCSVDefaultName: .fallbackTable$
    .table$ = .fallbackTable$
    if variableExists ("emlCSV_table$")
        if emlCSV_table$ <> ""
            .table$ = emlCSV_table$
        endif
    endif

    .analysis$ = ""
    if variableExists ("emlCSV_n")
        if emlCSV_n > 0
            @emlGraphsCSVRowAnalysis: emlCSV_row$ [1]
            .analysis$ = emlGraphsCSVRowAnalysis.result$
        endif
    endif

    # Same slug rules as @emlWrapperExportCSV, deliberately duplicated rather
    # than shared: that procedure also opens a dialog, and this one must not.
    .slug$ = replace$ (.analysis$, " ", "_", 0)
    .slug$ = replace$ (.slug$, "/", "-", 0)
    .slug$ = replace$ (.slug$, "'", "", 0)

    if .slug$ = ""
        .result$ = .table$ + "_results"
    else
        .result$ = .table$ + "_" + .slug$
    endif
endproc


# ============================================================================
# @emlGraphsCSVRowAnalysis
# ============================================================================
# Second field of one buffered CSV row — the `analysis` column of
# table,analysis,term,term_type,field,value.
#
# The row is written by @eml_csvAppend, which quotes a field only when it
# contains a comma, a double quote or a newline, so most rows split on plain
# commas. Most is not all: a user's table can legitimately be named with a
# comma in it, which would quote field 1 and shift every later field if this
# counted commas naively. So it walks the row honouring RFC 4180 quoting,
# including the "" escape for a literal quote.
#
# Arguments:
#   .row$ — one row from emlCSV_row$[]
# Outputs:
#   .result$ — the unquoted analysis field, or "" if the row has fewer than
#              two fields
# ============================================================================
procedure emlGraphsCSVRowAnalysis: .row$
    .result$ = ""
    .len = length (.row$)
    .i = 1
    .field = 1
    .inQuote = 0
    .cur$ = ""
    .done = 0
    while .i <= .len and .done = 0
        .ch$ = mid$ (.row$, .i, 1)
        if .inQuote = 1
            if .ch$ = """"
                if mid$ (.row$, .i + 1, 1) = """"
                    ; doubled quote inside a quoted field = one literal quote
                    .cur$ = .cur$ + """"
                    .i = .i + 1
                else
                    .inQuote = 0
                endif
            else
                .cur$ = .cur$ + .ch$
            endif
        elsif .ch$ = """" and .cur$ = ""
            .inQuote = 1
        elsif .ch$ = ","
            if .field = 2
                .result$ = .cur$
                .done = 1
            endif
            .field = .field + 1
            .cur$ = ""
        else
            .cur$ = .cur$ + .ch$
        endif
        .i = .i + 1
    endwhile
    ; Row ended while still inside field 2 — take what was collected.
    if .done = 0 and .field = 2
        .result$ = .cur$
    endif
endproc


# ============================================================================
# PERCENTAGE-COLUMN DETECTION
# ============================================================================
# D60. @emlComputeAxisRange has taken an .isPercentage argument since it was
# written, and clamps the axis to 0-100 (or 0-1 for proportions) when it is
# raised — Rule 28E. Every call site in the repository passed a literal 0, so
# the branch had never once executed and a `_pct` column with a ceiling of
# exactly 100.0 was still given Rule 28F's generic +-10% buffer: an axis
# running 40-110, ten points past a physically impossible value and cropping
# the bottom 40 points of the actual scale.
#
# Detection deliberately requires BOTH tests to pass:
#
#   * the NAME suggests a percentage (`_pct`, `percent`, `%`) — necessary,
#     because 0-100 data is extremely common in acoustics (SPL in dB, F0 in a
#     narrow band, age, contact quotient x 100) and clamping all of it to a
#     0-100 axis would wreck far more figures than D60 fixes; and
#   * the DATA actually lies in 0-100 — necessary, because a name is only a
#     hint. `pct_change` legitimately goes negative, and a column called
#     `percent_of_baseline` can run past 200. Either would be silently
#     truncated by a name-only rule, which is a worse failure than the one
#     being fixed: a clipped axis hides data, a buffered axis only wastes ink.
#
# Data in 0-1 is left to @emlComputeAxisRange, which reads dataMax <= 1 as a
# proportion and clamps to 0-1 instead.
#
# REACH. This is applied at the two @emlComputeAxisRange call sites in THIS
# file — the annotated bar / violin / box auto-range. The other 15 sites are in
# files this pass does not own and still pass a literal 0:
# graphs/eml-draw-procedures.praat 233, 332, 822, 1175, 1451, 1853, 2197, 2412,
# 2426, 3100, 3370, 3413, 3786, 4022 and scripts/eml-stats-demo.praat 309, 312,
# 398. Note in particular 2426, the scatter Y axis — that is the site the D60
# report was actually written from (a `_pct` column drawn 40-110), so D60's
# observed figure is NOT fixed by this change; the mechanism it said was dead
# is simply no longer dead. Those sites cannot call this procedure as it
# stands: eml-draw-procedures.praat is included without this file by the stress
# harness, so a shared detector has to live in eml-graph-procedures.praat
# beside @emlComputeAxisRange itself.
#
# Arguments:
#   .tableId  — Table to inspect
#   .colName$ — column name
# Outputs:
#   .result — 1 when the column should get a percentage axis, else 0
# ============================================================================
procedure emlGraphsIsPercentageColumn: .tableId, .colName$
    .result = 0
    .nameHit = 0
    if .colName$ <> ""
        if index_caseInsensitive (.colName$, "pct") > 0
            .nameHit = 1
        endif
        if index_caseInsensitive (.colName$, "percent") > 0
            .nameHit = 1
        endif
        if index (.colName$, "%") > 0
            .nameHit = 1
        endif
    endif

    if .nameHit = 1
        @emlCheckNumericColumn: .tableId, .colName$
        if emlCheckNumericColumn.isNumeric = 1
            selectObject: .tableId
            .lo = Get minimum: .colName$
            .hi = Get maximum: .colName$
            if .lo <> undefined and .hi <> undefined
                if .lo >= 0 and .hi <= 100
                    .result = 1
                endif
            endif
        endif
    endif
endproc


# ============================================================================
# DEFAULT FIGURE TITLE
# ============================================================================
# D43 / D89 (Rule 28A). The figure used to be drawn with no title at all
# whenever the Title field was left blank, which is the out-of-box case on
# every path: the plugin knew the table name and every mapped column and put
# none of it on the figure, so a reader given the PNG alone could not tell
# what was measured or on what.
#
# WHY IT IS COMPOSED HERE AND NOT IN THE FORM. The Title field lives on the
# FIRST page of the dialog — above the graph-type menu and two pages above the
# column mapping — so at the moment Praat builds that field there is nothing
# to compose from. Praat forms are built in one pass; a field cannot read a
# value the user has not been shown yet. The title is therefore composed at
# draw time, where every mapped column name is known, and written back into
# prev_title$ so that from the SECOND invocation onwards the Title field opens
# pre-filled with the composed text and the user can edit or clear it.
#
# The caller keeps prev_autoTitle$ = this procedure's last result. A title
# equal to that string is one the user accepted rather than wrote, so it is
# recomposed from the current mapping instead of being carried over stale when
# the graph type or the columns change.
#
# Column names go through @emlCapitalizeLabel / @emlSanitizeLabel, so an
# underscore in a column name becomes a space rather than a Praat subscript
# marker and a "%" cannot turn the rest of the title italic. A title the user
# typed never reaches this procedure and is never rewritten.
#
# Reads main-scope state: graph_type, objectId and the per-type column-name
# variables. Only the branch for the live graph type is evaluated, so the
# variables belonging to other types need not exist.
#
# Outputs:
#   .result$ — composed title, or "" when there is nothing to say
# ============================================================================
procedure emlComposeGraphTitle
    .result$ = ""
    .source$ = ""
    .value$ = ""
    .x$ = ""
    .sub$ = ""

    if objectId > 0
        selectObject: objectId
        .full$ = selected$ ()
        ; "Table demo_twoway" -> "demo_twoway"; works for Sound/Pitch/Ltas too
        .space = index (.full$, " ")
        if .space > 0
            .source$ = right$ (.full$, length (.full$) - .space)
        else
            .source$ = .full$
        endif
        @emlSanitizeLabel: .source$
        .source$ = emlSanitizeLabel.result$
    endif

    if graph_type <= 4
        ; Acoustic objects have no column mapping — name the object and the view
        if .source$ <> ""
            .result$ = graphTypeName$[graph_type] + ": " + .source$
        endif
        goto COMPOSE_TITLE_DONE
    endif

    if graph_type = 5
        .value$ = valueColName$
        .x$ = timeColName$
        .sub$ = groupColName$
    elsif graph_type = 6 or graph_type = 7 or graph_type = 9
        .value$ = valueColName$
        .x$ = groupColName$
    elsif graph_type = 8
        .value$ = scatterYCol$
        .x$ = scatterXCol$
        .sub$ = scatterGroupCol$
    elsif graph_type = 10
        .value$ = histValueCol$
        .sub$ = histGroupCol$
    elsif graph_type = 11
        .value$ = gvValueCol$
        .x$ = gvCatCol$
        .sub$ = gvSubCol$
    elsif graph_type = 12
        .value$ = gbValueCol$
        .x$ = gbCatCol$
        .sub$ = gbSubCol$
    elsif graph_type = 13
        .value$ = spValueCol$
        .x$ = spCondCol$
        .sub$ = spGroupCol$
    endif

    ; A subgroup that repeats the x column says nothing twice
    if .sub$ = .x$
        .sub$ = ""
    endif

    if .value$ = ""
        ; Nothing mapped yet — fall back to naming the source
        if .source$ <> ""
            .result$ = graphTypeName$[graph_type] + ": " + .source$
        endif
        goto COMPOSE_TITLE_DONE
    endif

    @emlCapitalizeLabel: .value$
    .result$ = emlCapitalizeLabel.result$

    if graph_type = 10
        .result$ = "Distribution of " + .result$
    endif

    if .x$ <> ""
        @emlSanitizeLabel: .x$
        if graph_type = 5
            .result$ = .result$ + " over " + emlSanitizeLabel.result$
        elsif graph_type = 8
            .result$ = .result$ + " vs " + emlSanitizeLabel.result$
        else
            .result$ = .result$ + " by " + emlSanitizeLabel.result$
        endif
    endif

    if .sub$ <> ""
        @emlSanitizeLabel: .sub$
        if .x$ = ""
            .result$ = .result$ + " by " + emlSanitizeLabel.result$
        else
            .result$ = .result$ + " and " + emlSanitizeLabel.result$
        endif
    endif

    if .source$ <> ""
        .result$ = .result$ + " (" + .source$ + ")"
    endif

    label COMPOSE_TITLE_DONE
    if objectId > 0
        selectObject: objectId
    endif
endproc


# ============================================================================
# WORKFLOW — Main interactive graph creation loop
# ============================================================================
# WARNING: This procedure reads and writes main-body scope variables
# (objectId, nCols, colName$[], annotate, config_*, prev_*, context*).
# Callers must not depend on these variables' values after return.
#
# Arguments:
#   .objectId — object to graph (Table/Pitch/Sound/etc). When > 0, the
#               workflow selects it and detects context. When 0 (standalone),
#               context detection examines the current Objects window selection.
# ============================================================================
procedure emlGraphsWorkflow: .objectId

    # Enable explanations in the graphs/drawing path.
    #
    # D102. This gate is global. Raising it here and walking away made every
    # LATER analysis report in the same session verbose, so report content was
    # order-dependent: the same test printed different text depending on
    # whether a figure had been drawn first. The bottom of this procedure now
    # calls @emlResetExplanations, which puts the gate back to the default
    # declared in stats/eml-output.praat — deliberately the declared default
    # and not a literal 0, so this file cannot drift from that declaration the
    # way the original hardcoded pair did. Whatever the calling wrapper does
    # after Draw returns, it sees the same gate it would have seen without the
    # Draw. The "Quit" buttons inside the form call exitScript, which ends the
    # script and its entire variable scope, so they need no reset of their own.
    emlShowExplanations = 1

    # =================================================================
    # 1. IDEMPOTENT SETUP (every call)
    # =================================================================
    @emlInitAlphaSprites
    @emlLoadConfig

    # =================================================================
    # 2. SENTINEL-GUARDED PERSISTENCE (first call only)
    # =================================================================
    # These variables remember user choices across "Redraw" cycles
    # AND across multiple workflow calls from the same script session
    # (e.g., stats wrapper -> Draw Figure -> Done -> Draw Figure again).
    # They must initialize once, then persist.
    #
    if emlGraphsInitDone = 0

# Column mapping persistence (0 = use auto-detect, >0 = reuse previous selection)
prev_tsTimeIdx = 0
prev_tsDataFormat = 0
prev_tsShowCI = 0
prev_tsSeries1Idx = 0
prev_tsSeries2Idx = 0
prev_groupSort = config_groupSort
prev_tsSeries3Idx = 0
prev_tsSeries4Idx = 0
prev_tsSeries5Idx = 0
prev_tsValueIdx = 0
prev_tsGroupIdx = 0
prev_barGroupIdx = 0
prev_barValueIdx = 0
prev_barErrorIdx = 0
prev_violinGroupIdx = 0
prev_violinValueIdx = 0
prev_scatterXIdx = 0
prev_scatterYIdx = 0
prev_scatterGroupIdx = 0
prev_scatterDotSize = 0
prev_scatterRegressionLine = -1
prev_scatterShowFormula = -1
prev_scatterShowDots = -1
prev_scatterUseGroup = -1

# Box plot persistence
prev_boxGroupIdx = 0
prev_boxValueIdx = 0
prev_box_valueMin = 0
prev_box_valueMax = 0
prev_boxShowJitter = 0

# Histogram persistence
prev_histValueIdx = 0
prev_histGroupIdx = 0
prev_histUseGroup = -1
prev_histBinCount = 0
prev_histDisplayMode = 1
prev_hist_valueMin = 0
prev_hist_valueMax = 0
prev_hist_freqMax = 0

# Grouped violin persistence
prev_gvCatIdx = 0
prev_gvSubIdx = 0
prev_gvValueIdx = 0
prev_gv_valueMin = 0
prev_gv_valueMax = 0
prev_gvShowJitter = 0
prev_gvAnnotTestType = 1
prev_gvAnnotStyle = 1

# Grouped box plot persistence
prev_gbCatIdx = 0
prev_gbSubIdx = 0
prev_gbValueIdx = 0
prev_gb_valueMin = 0
prev_gb_valueMax = 0
prev_gbShowJitter = 0
prev_gbAnnotTestType = 1
prev_gbAnnotStyle = 1

# Spaghetti plot persistence
prev_spCondIdx = 0
prev_spValueIdx = 0
prev_spSubjectIdx = 0
prev_spGroupIdx = 0
prev_spUseGroup = 0
prev_spGroupSort = 1
prev_sp_valueMin = 0
prev_sp_valueMax = 0
prev_spShowMean = -1

# Histogram stats persistence
prev_histAnnotTestType = 1
prev_histAnnotStyle = 1

# Multiple-comparison adjustment persistence (shared by every
# annotate-capable dialog). 1 = Bonferroni, 2 = Holm, 3 = Benjamini-Hochberg.
prev_annotAdjustIdx = 2

# Violin jitter persistence
prev_violinShowJitter = 0


# Range persistence (per graph type, retained across "Draw Another")
lastDrawnGraphType = 0
prev_title$ = ""
# D43 / D89. The last title @emlComposeGraphTitle produced. prev_title$ holds
# what the Title field will show next time; prev_autoTitle$ records whether
# that text was composed for the user or typed by them, which is the only way
# to tell an accepted auto-title (recompose from the new mapping) from a
# deliberate one (leave it alone).
prev_autoTitle$ = ""
prev_subtitle$ = ""
prev_f0_timeMin = 0
prev_f0_timeMax = 0
prev_f0_freqMin = 0
prev_f0_freqMax = 0
prev_f0_yUnit = 1
prev_f0_pitchFloor = 50
prev_f0_pitchCeiling = 400
prev_wav_timeMin = 0
prev_wav_timeMax = 0
prev_wav_ampMin = 0
prev_wav_ampMax = 0
prev_spec_freqMin = 0
prev_spec_freqMax = 0
prev_spec_powerMin = 0
prev_spec_powerMax = 0
prev_ltas_freqMin = 0
prev_ltas_freqMax = 0
prev_ltas_powerMin = 0
prev_ltas_powerMax = 0
prev_ltas_showCurve = 1
prev_ltas_showBars = 0
prev_ltas_showPoles = 0
prev_ltas_showSpeckles = 0
prev_ts_timeMin = 0
prev_ts_timeMax = 0
prev_ts_valueMin = 0
prev_ts_valueMax = 0
prev_bar_valueMin = 0
prev_bar_valueMax = 0
prev_violin_valueMin = 0
prev_violin_valueMax = 0
prev_scatter_xMin = 0
prev_scatter_xMax = 0
prev_scatter_yMin = 0
prev_scatter_yMax = 0

        emlGraphsInitDone = 1
    endif

    # =================================================================
    # 3. PER-CALL RESET (every call — fresh defaults before presets)
    # =================================================================

    # Loop control
    keepGoing = 1
    loadedObjectId = 0
    tsMeltTableId = 0
    objectId = 0

# Annotation config (reset per workflow call; persists across Redraw)
# Default OFF — annotation is opt-in. Stats wrapper presets override below.
annotate = 0
annotTestType$ = "parametric"
annotCorrType$ = "pearson"
annotStyle$ = "p-value"
annotShowNS = 0
annotShowEffect = 0
annotAlpha = 0.05
annotCorrectionMethod$ = "holm"
annotLayoutMode = 1

# Scatter plot column names (initialized to prevent undefined errors)
scatterXCol$ = ""
scatterYCol$ = ""
scatterGroupCol$ = ""
scatterXMin = 0
scatterXMax = 0
scatterDotSize = 2
scatterRegressionLine = 0
scatterAnalysisType = 0
scatterShowFormula = 0
scatterShowDots = 1

    # =================================================================
    # CONTEXT DETECTION
    # =================================================================
    # When .objectId > 0, select it so @emlDetectContext finds it.
    # When .objectId = 0 (standalone), detect whatever the user
    # has selected in the Objects window.
    #
    if .objectId > 0
        selectObject: .objectId
    endif
    @emlDetectContext
    @emlBuildFilteredMenu
    originalSourceId = contextOriginalSourceId

    # =================================================================
    # PRESET READING
    # =================================================================
    # Presets override context/config defaults. The main form still
    # shows — user can adjust title, dimensions, or switch graph types.
    # Presets accelerate the workflow, not bypass it.
    #
    if emlGraphsPresetType > 0
        graphTypeDefault = emlGraphsPresetType
    elsif contextGraphType > 0
        graphTypeDefault = contextGraphType
    else
        graphTypeDefault = config_graphType
    endif

    if emlGraphsPresetAnnotate > 0
        annotate = 1
        if emlGraphsPresetTestType$ <> ""
            annotTestType$ = emlGraphsPresetTestType$
        endif
    endif

    # D103. Every preset that lands in a scatter dialog default also raises its
    # sentinel. Without it the scatter page overwrote these three lines from
    # prev_* further down and the wrapper's request was lost on every call
    # after the first.
    if emlGraphsPresetAnalysisType > 0
        scatterAnalysisType = emlGraphsPresetAnalysisType
        annotate = 1
        if scatterAnalysisType >= 2
            scatterRegressionLine = 1
            scatterShowFormula = 1
            scatterPresetHasRegression = 1
        endif
        emlGraphsPresetAnalysisType = 0
    endif

    if emlGraphsPresetRegressionLine > 0
        scatterRegressionLine = 1
        scatterShowFormula = 1
        scatterPresetHasRegression = 1
        emlGraphsPresetRegressionLine = 0
    endif

    if emlGraphsPresetDotSize > 0
        scatterDotSize = emlGraphsPresetDotSize
        scatterPresetHasDotSize = 1
        emlGraphsPresetDotSize = 0
    endif

    if emlGraphsPresetShowDots >= 0
        scatterShowDots = emlGraphsPresetShowDots
        scatterPresetHasDots = 1
        emlGraphsPresetShowDots = -1
    endif

    if emlGraphsPresetCorrType$ <> ""
        annotCorrType$ = emlGraphsPresetCorrType$
        emlGraphsPresetCorrType$ = ""
    endif

    # Multiple-comparison adjustment carried in from a stats wrapper.
    # Also seeds the dialog default so the Advanced form shows the method
    # the calling test actually used.
    #
    # D108. annotCorrectionMethod$ is the ONLY channel this value has:
    # @emlBridgeGroupComparison does not take it as an argument, it reads the
    # global (eml-annotation-procedures.praat:1808). So the job here is to make
    # sure the global is well defined by the time the bridge runs, on BOTH test
    # paths — the bridge resolves .correction$ before it branches on test type,
    # so a parametric run has the wrapper's method in hand exactly as a
    # nonparametric one does.
    #
    # Two things used to make that only accidentally true:
    #
    #   * the string and the dialog index were derived separately, so an
    #     unrecognised preset set annotCorrectionMethod$ to the unrecognised
    #     string but prev_annotAdjustIdx to Holm. In Advanced mode the form
    #     then committed Holm over it silently; in Beginner mode the bad string
    #     survived to the bridge, which warned and fell back. Same preset, two
    #     behaviours, neither announced at the point the caller made the
    #     mistake. Both now come from one validated index via
    #     @emlAdjustMethodName, which is the same lookup the six column-mapping
    #     pages commit through — they cannot disagree any more.
    #   * an unrecognised value was never reported to the caller. It is now,
    #     here, where the preset was set, rather than later from inside the
    #     annotation layer.
    #
    # What is NOT fixed here, because it is not in this file: on the parametric
    # k >= 3 path the consuming side still ignores the value. The Tukey branch
    # of @emlBridgeGroupComparison (eml-annotation-procedures.praat:2151+)
    # never reads .correction$ — only the Dunn branch does. Delivering the
    # method is this file's half of D108; using it, or saying in the figure
    # that Tukey carries its own correction instead, is a change to
    # eml-annotation-procedures.praat, which this pass does not own.
    if emlGraphsPresetCorrection$ <> ""
        .presetAdjustIdx = 0
        if emlGraphsPresetCorrection$ = "bonferroni"
            .presetAdjustIdx = 1
        elsif emlGraphsPresetCorrection$ = "holm"
            .presetAdjustIdx = 2
        elsif emlGraphsPresetCorrection$ = "bh"
            .presetAdjustIdx = 3
        endif
        if .presetAdjustIdx = 0
            appendInfoLine: "NOTE: unrecognised emlGraphsPresetCorrection$ '"
            ... + emlGraphsPresetCorrection$ + "' — using holm."
            .presetAdjustIdx = 2
        endif
        @emlAdjustMethodName: .presetAdjustIdx
        annotCorrectionMethod$ = emlAdjustMethodName.name$
        prev_annotAdjustIdx = .presetAdjustIdx
        emlGraphsPresetCorrection$ = ""
    endif

    # Column presets are consumed by the type-specific forms.
    # They check emlGraphsPresetGroupCol$, emlGraphsPresetDataCol$ and
    # (two-factor pages only) emlGraphsPresetSubgroupCol$ to override
    # auto-detection defaults, then clear them so subsequent Redraw
    # iterations use prev_* persistence instead.

repeat

    # =================================================================
    # MAIN FORM + ACQUIRE OBJECT LOOP
    # (allows "Go Back" from object dialog to restart main form)
    # =================================================================

    allFormsDone = 0
    repeat

    # Clean up any auto-created intermediate object from previous pass
    if loadedObjectId > 0
        removeObject: loadedObjectId
        loadedObjectId = 0
        if originalSourceId > 0
            selectObject: originalSourceId
        endif
    endif
    if tsMeltTableId > 0
        removeObject: tsMeltTableId
        tsMeltTableId = 0
    endif
    objectId = 0

    # Re-detect context and rebuild filtered menu on each pass
    # (handles Go Back after user changes selection in Objects window)
    @emlDetectContext
    @emlBuildFilteredMenu

    acquireDone = 0
    repeat

    # =================================================================
    # MAIN FORM (with beginner/advanced toggle)
    # =================================================================

    # Initialize display settings from config (form will override if fields shown)
    gridline_mode = config_gridlineMode
    emlShowInnerBox = config_showInnerBox
    @emlExpandAxisControls
    emlFont$ = config_font$
    emlSubtitle$ = config_subtitle$
    output_DPI = config_outputDPI

    # Convert stored type to menu index for form default
    if graphTypeDefault >= 1 and graphTypeDefault <= nGraphTypes
        if filteredTypeToMenu[graphTypeDefault] > 0
            menuDefault = filteredTypeToMenu[graphTypeDefault]
        else
            # Stored type not in filtered menu — find first non-divider
            menuDefault = 1
            for iScan from 1 to filteredNMenuItems
                if filteredMenuToType[iScan] > 0
                    menuDefault = iScan
                    iScan = filteredNMenuItems
                endif
            endfor
        endif
    else
        # No valid stored type — find first non-divider
        menuDefault = 1
        for iScan from 1 to filteredNMenuItems
            if filteredMenuToType[iScan] > 0
                menuDefault = iScan
                iScan = filteredNMenuItems
            endif
        endfor
    endif

    # Main form — graph type selection and global settings
    mainFormDone = 0
    repeat
        beginPause: "EML Graphs"
            optionmenu: "Graph type", menuDefault
                for iMenu from 1 to filteredNMenuItems
                    option: filteredMenuLabel$[iMenu]
                endfor
            sentence: "Title (blank = auto from table and columns)", prev_title$
            sentence: "Subtitle", prev_subtitle$
            optionmenu: "Color mode", config_colorMode
                option: "Color"
                option: "Black and White"
            positive: "Figure width (inches)", string$ (config_width)
            positive: "Figure height (inches)", string$ (config_height)
        clicked = endPause: "Quit", "Continue", 2, 1

        if clicked = 1
            @emlSaveConfig
            exitScript: ""
        endif

        # Remap menu index to internal type
        menuDefault = graph_type
        graph_type = filteredMenuToType[graph_type]

        if graph_type = 0
            # Divider selected — re-show form with prompt
            beginPause: "Please select a graph type."
                comment: "The item you selected is a category header."
                comment: "Please choose a graph type from the list."
            endPause: "OK", 1, 0
        else
            mainFormDone = 1
        endif
    until mainFormDone = 1

    # Capture form values
    graphTypeDefault = graph_type
    prev_title$ = title$
    prev_subtitle$ = subtitle$
    emlSubtitle$ = subtitle$
    config_subtitle$ = subtitle$

    # Initialize advanced fields from config (page 2 will override if shown)
    gridline_mode = config_gridlineMode
    emlShowInnerBox = config_showInnerBox
    @emlExpandAxisControls
    emlFont$ = config_font$
    emlSubtitle$ = config_subtitle$
    output_DPI = config_outputDPI
    x_axis_label$ = ""
    y_axis_label$ = ""

    # Derive color mode string for drawing procedures
    if color_mode = 1
        colorMode$ = "color"
    else
        colorMode$ = "bw"
    endif

    # Update config from form values
    config_graphType = graph_type
    config_colorMode = color_mode
    config_width = figure_width
    config_height = figure_height

    # =================================================================
    # ACQUIRE OBJECT
    # =================================================================

    targetType$ = requiredType$[graph_type]
    acquireDone = 1

    if contextObjectId > 0 and (contextGraphType = graph_type or (isTableType[graph_type] and isTableType[contextGraphType]))
        # Context detection already found the right object
        # (for table types, any table-type graph can use the same Table)
        objectId = contextObjectId
    else
        # Check current selection
        nTarget = numberOfSelected (targetType$)

        if nTarget = 1
            objectId = selected (targetType$)
        elsif nTarget > 1
            @emlPickFromMultiple: targetType$
            objectId = emlPickFromMultiple.result
        else
            # Nothing of the right type selected
            # U6: Try auto-creating from Sound if possible
            if numberOfSelected ("Sound") = 1
                soundForConvert = selected ("Sound")
                selectObject: soundForConvert
                if targetType$ = "Pitch"
                    pitchTop = prev_f0_pitchCeiling * 2
                    objectId = To Pitch (filtered autocorrelation): 0, prev_f0_pitchFloor, pitchTop, 15, "yes", 0.03, 0.09, 0.50, 0.055, 0.35, 0.14
                    loadedObjectId = objectId
                elsif targetType$ = "Spectrum"
                    objectId = To Spectrum: "yes"
                    loadedObjectId = objectId
                elsif targetType$ = "Ltas"
                    objectId = To Ltas: 100
                    loadedObjectId = objectId
                endif
            elsif numberOfSelected ("Spectrum") = 1
                spectrumForConvert = selected ("Spectrum")
                selectObject: spectrumForConvert
                if targetType$ = "Ltas"
                    objectId = To Ltas (1-to-1)
                    loadedObjectId = objectId
                elsif targetType$ = "Sound"
                    objectId = To Sound
                    loadedObjectId = objectId
                elsif targetType$ = "Pitch"
                    # Two-step: Spectrum → Sound → Pitch
                    tempSoundId = To Sound
                    selectObject: tempSoundId
                    pitchTop = prev_f0_pitchCeiling * 2
                    objectId = To Pitch (filtered autocorrelation): 0, prev_f0_pitchFloor, pitchTop, 15, "yes", 0.03, 0.09, 0.50, 0.055, 0.35, 0.14
                    removeObject: tempSoundId
                    loadedObjectId = objectId
                endif
            elsif numberOfSelected ("TableOfReal") = 1
                # Auto-convert TableOfReal → Table (persists as working object)
                torForConvert = selected ("TableOfReal")
                selectObject: torForConvert
                objectId = To Table: "row"
                @emlCleanConvertedTable: objectId
                appendInfoLine: "NOTE: TableOfReal converted to Table for graphing."
            elsif numberOfSelected ("Matrix") = 1
                # Auto-convert Matrix → TableOfReal → Table (persists as working object)
                matForConvert = selected ("Matrix")
                selectObject: matForConvert
                tempTorId = To TableOfReal
                objectId = To Table: "row"
                removeObject: tempTorId
                @emlCleanConvertedTable: objectId
                appendInfoLine: "NOTE: Matrix converted to Table for graphing."
            endif

            if objectId = 0
            # Still no object — offer to load or select
            beginPause: "No " + targetType$ + " selected"
                comment: "Select a " + targetType$ + " in the Objects window,"
                comment: "or load one from a file."
                infile: "Load from file", config_lastInputFolder$
            clicked = endPause: "Quit", "Go Back", "Selected", "Load file", 3, 1

            if clicked = 1
                @emlSaveConfig
                exitScript: ""
            elsif clicked = 2
                # Go Back — restart from main form
                acquireDone = 0
            elsif clicked = 3
                # Re-check selection after user may have clicked
                nTarget = numberOfSelected (targetType$)
                if nTarget < 1
                    exitScript: "No " + targetType$ + " object selected."
                endif
                objectId = selected (targetType$)
            elsif clicked = 4
                if load_from_file$ = ""
                    exitScript: "No file specified."
                endif
                objectId = Read from file: load_from_file$
                loadedObjectId = objectId
                config_lastInputFolder$ = load_from_file$
            endif
            endif
        endif
    endif

    until acquireDone = 1

    # For Table types, snapshot column names
    if isTableType[graph_type]
        selectObject: objectId
        nCols = Get number of columns
        if nCols < 1
            exitScript: "Table has no columns."
        endif
        nRows = Get number of rows
        if nRows < 1
            exitScript: "Table has no rows."
        endif
        for iCol from 1 to nCols
            colName$[iCol] = Get column label: iCol
        endfor
    endif


    # =================================================================
    # TYPE-SPECIFIC FORM (with Go Back + Advanced toggle)
    # =================================================================

    # Initialize range variables (0/0 = auto per pair)
    timeMin = 0
    timeMax = 0
    freqMin = 0
    freqMax = 0
    powerMin = 0
    powerMax = 0
    ampMin = 0
    ampMax = 0
    valueMin = 0
    valueMax = 0

    # Initialize column name variables (for Table types)
    timeColName$ = ""
    valueColName$ = ""
    lowerColName$ = ""
    upperColName$ = ""
    groupColName$ = ""
    errorColName$ = ""
    errorBarMode = 0
    histValueCol$ = ""
    histGroupCol$ = ""
    gbCatCol$ = ""
    gbSubCol$ = ""
    gbValueCol$ = ""
    ; D3b: ciTimeCol$ / ciValueCol$ / ciGroupCol$ went with the old type 13.
    ; They were only ever cleared here and read by that type's dispatch, never
    ; written, so the CI draw call they fed was passing three empty strings.
    ; Type 5's toggle uses timeColName$ / valueColName$ / groupColName$.
    spCondCol$ = ""
    spValueCol$ = ""
    spSubjectCol$ = ""
    spGroupCol$ = ""
    spShowMean = 1

    # Shared tmp variables — initialized from config before graph type
    # branching. Ensures valid defaults exist on first pass regardless
    # of which graph type is selected. Per-type sections may override
    # graph-specific tmp vars but inherit these shared ones.
    tmpGridMode = config_gridlineMode
    tmpShowInnerBox = config_showInnerBox
    tmpShowAxisNames = config_showAxisNames
    tmpShowTicks = config_showTicks
    tmpShowAxisValues = config_showAxisValues
    tmpFont = config_font
    tmpDPI = config_outputDPI

    if graph_type = 1
        # =============================================================
        # Pitch Contour — Page 2
        # =============================================================

        # Initialize tmp vars from persistence or defaults
        if lastDrawnGraphType = 1
            tmpTMin$ = string$ (prev_f0_timeMin)
            tmpTMax$ = string$ (prev_f0_timeMax)
            tmpFMin$ = string$ (prev_f0_freqMin)
            tmpFMax$ = string$ (prev_f0_freqMax)
            tmpYUnit = prev_f0_yUnit
        else
            tmpTMin$ = "0"
            tmpTMax$ = "0"
            tmpFMin$ = "0"
            tmpFMax$ = "0"
            tmpYUnit = 1
        endif
        tmpXLabel$ = ""
        tmpYLabel$ = ""
        tmpPitchFloor$ = string$ (prev_f0_pitchFloor)
        tmpPitchCeiling$ = string$ (prev_f0_pitchCeiling)

        f0FormDone = 0
        repeat
            if config_showAdvanced
                toggleLabel$ = "Beginner"
            else
                toggleLabel$ = "Advanced"
            endif

            beginPause: "Pitch Contour Settings"
                comment: "⏱️ Time range (both 0 = auto)"
                real: "Time minimum", tmpTMin$
                real: "Time maximum", tmpTMax$
                comment: "📐 Frequency range (both 0 = auto)"
                real: "Frequency maximum", tmpFMax$
                real: "Frequency minimum", tmpFMin$
                optionmenu: "Y axis unit", tmpYUnit
                    option: "Hertz"
                    option: "Semitones re 440 Hz"
                if loadedObjectId > 0
                    comment: "🎵 Pitch analysis (auto-converted from Sound)"
                    comment: "Ceiling is doubled internally for the analysis algorithm."
                    real: "Pitch floor (Hz)", tmpPitchFloor$
                    real: "Pitch ceiling (Hz)", tmpPitchCeiling$
                endif
                if config_showAdvanced
                    optionmenu: "Gridline mode", tmpGridMode
                        option: "Both"
                        option: "Horizontal only"
                        option: "Vertical only"
                        option: "Off"
                    optionmenu: "Output DPI", tmpDPI
                        option: "300 dpi"
                        option: "600 dpi"
                    boolean: "Show inner box", tmpShowInnerBox
                    optionmenu: "Show axis names", tmpShowAxisNames
                        option: "None"
                        option: "Both"
                        option: "X only"
                        option: "Y only"
                    optionmenu: "Show ticks", tmpShowTicks
                        option: "None"
                        option: "Both"
                        option: "X only"
                        option: "Y only"
                    optionmenu: "Show axis values", tmpShowAxisValues
                        option: "None"
                        option: "Both"
                        option: "X only"
                        option: "Y only"
                    optionmenu: "Font", tmpFont
                        option: "Helvetica"
                        option: "Times"
                        option: "Palatino"
                        option: "Courier"
                    comment: "🏷️ Axis labels"
                    comment: "Formatting: %italic · #bold · ^super · underscore = subscript · \% plus a space prints %"
                    sentence: "X axis label", tmpXLabel$
                    sentence: "Y axis label", tmpYLabel$
                endif
            clicked = endPause: "Go Back", "Quit", toggleLabel$, "Draw", 4, 1

            if clicked = 1
                # Go Back — exit form, allFormsDone stays 0
                f0FormDone = 1
            elsif clicked = 2
                @emlSaveConfig
                exitScript: ""
            elsif clicked = 3
                # Toggle — preserve beginner field values
                tmpTMin$ = string$ (time_minimum)
                tmpTMax$ = string$ (time_maximum)
                tmpFMin$ = string$ (frequency_minimum)
                tmpFMax$ = string$ (frequency_maximum)
                tmpYUnit = y_axis_unit
                if loadedObjectId > 0
                    tmpPitchFloor$ = string$ (pitch_floor)
                    tmpPitchCeiling$ = string$ (pitch_ceiling)
                endif
                if config_showAdvanced
                    tmpGridMode = gridline_mode
                    tmpShowInnerBox = show_inner_box
                    tmpShowAxisNames = show_axis_names
                    tmpShowTicks = show_ticks
                    tmpShowAxisValues = show_axis_values
                    tmpFont = font
                    tmpDPI = output_DPI
                    tmpXLabel$ = x_axis_label$
                    tmpYLabel$ = y_axis_label$
                    # Toggling TO beginner: reset advanced-only fields
                    tmpGridMode = config_gridlineMode
                    tmpShowInnerBox = config_showInnerBox
                    tmpShowAxisNames = config_showAxisNames
                    tmpShowTicks = config_showTicks
                    tmpShowAxisValues = config_showAxisValues
                    tmpFont = config_font
                    tmpDPI = config_outputDPI
                    tmpXLabel$ = ""
                    tmpYLabel$ = ""
                endif
                config_showAdvanced = 1 - config_showAdvanced
            else
                # Draw — capture values and exit
                f0FormDone = 1
                allFormsDone = 1

                timeMin = time_minimum
                timeMax = time_maximum
                freqMin = frequency_minimum
                freqMax = frequency_maximum
                prev_f0_timeMin = timeMin
                prev_f0_timeMax = timeMax
                prev_f0_freqMin = freqMin
                prev_f0_freqMax = freqMax

                # Capture unit selection (always on beginner page)
                f0YUnit = y_axis_unit
                tmpYUnit = f0YUnit
                prev_f0_yUnit = f0YUnit

                # Capture pitch analysis fields (always visible when auto-converted)
                if loadedObjectId > 0
                    tmpPitchFloor$ = string$ (pitch_floor)
                    tmpPitchCeiling$ = string$ (pitch_ceiling)
                endif

                # Capture advanced values from form or tmp
                if config_showAdvanced
                    tmpGridMode = gridline_mode
                    tmpShowInnerBox = show_inner_box
                    tmpShowAxisNames = show_axis_names
                    tmpShowTicks = show_ticks
                    tmpShowAxisValues = show_axis_values
                    tmpFont = font
                    tmpDPI = output_DPI
                    tmpXLabel$ = x_axis_label$
                    tmpYLabel$ = y_axis_label$
                    config_gridlineMode = gridline_mode
                    emlShowInnerBox = show_inner_box
                    emlFont$ = font$
                    config_showInnerBox = show_inner_box
                    config_showAxisNames = show_axis_names
                    config_showTicks = show_ticks
                    config_showAxisValues = show_axis_values
                    @emlExpandAxisControls
                    config_font$ = font$
                    config_font = font
                    config_outputDPI = output_DPI
                endif

                # Pitch analysis: capture and re-convert if changed
                newFloor = number (tmpPitchFloor$)
                newCeiling = number (tmpPitchCeiling$)
                if loadedObjectId > 0 and (newFloor <> prev_f0_pitchFloor or newCeiling <> prev_f0_pitchCeiling)
                    # User changed pitch range — re-convert from source
                    selectObject: loadedObjectId
                    Remove
                    pitchTop = newCeiling * 2
                    selectObject: originalSourceId
                    sourceType$ = selected$ ()
                    if startsWith (sourceType$, "Sound")
                        objectId = To Pitch (filtered autocorrelation): 0, newFloor, pitchTop, 15, "yes", 0.03, 0.09, 0.50, 0.055, 0.35, 0.14
                    else
                        # Spectrum source — two-step conversion
                        tmpSnd = To Sound
                        selectObject: tmpSnd
                        objectId = To Pitch (filtered autocorrelation): 0, newFloor, pitchTop, 15, "yes", 0.03, 0.09, 0.50, 0.055, 0.35, 0.14
                        removeObject: tmpSnd
                    endif
                    loadedObjectId = objectId
                endif
                prev_f0_pitchFloor = newFloor
                prev_f0_pitchCeiling = newCeiling
                gridline_mode = tmpGridMode
                output_DPI = tmpDPI
                x_axis_label$ = tmpXLabel$
                y_axis_label$ = tmpYLabel$
                if x_axis_label$ = ""
                    x_axis_label$ = defaultXLabel$[1]
                endif
                if y_axis_label$ = ""
                    if f0YUnit = 2
                        y_axis_label$ = "Semitones re: A440 Hz"
                    else
                        y_axis_label$ = defaultYLabel$[1]
                    endif
                endif
            endif
        until f0FormDone = 1

    elsif graph_type = 2
        # =============================================================
        # Waveform — Page 2
        # =============================================================

        if lastDrawnGraphType = 2
            tmpTMin$ = string$ (prev_wav_timeMin)
            tmpTMax$ = string$ (prev_wav_timeMax)
            tmpAMin$ = string$ (prev_wav_ampMin)
            tmpAMax$ = string$ (prev_wav_ampMax)
        else
            tmpTMin$ = "0"
            tmpTMax$ = "0"
            tmpAMin$ = "0"
            tmpAMax$ = "0"
        endif
        tmpXLabel$ = ""
        tmpYLabel$ = ""

        wavFormDone = 0
        repeat
            if config_showAdvanced
                toggleLabel$ = "Beginner"
            else
                toggleLabel$ = "Advanced"
            endif

            beginPause: "Waveform Settings"
                comment: "⏱️ Time range (both 0 = auto)"
                real: "Time minimum", tmpTMin$
                real: "Time maximum", tmpTMax$
                comment: "📐 Amplitude range (both 0 = auto)"
                real: "Amplitude maximum", tmpAMax$
                real: "Amplitude minimum", tmpAMin$
                if config_showAdvanced
                    optionmenu: "Gridline mode", tmpGridMode
                        option: "Both"
                        option: "Horizontal only"
                        option: "Vertical only"
                        option: "Off"
                    optionmenu: "Output DPI", tmpDPI
                        option: "300 dpi"
                        option: "600 dpi"
                    boolean: "Show inner box", tmpShowInnerBox
                    optionmenu: "Show axis names", tmpShowAxisNames
                        option: "None"
                        option: "Both"
                        option: "X only"
                        option: "Y only"
                    optionmenu: "Show ticks", tmpShowTicks
                        option: "None"
                        option: "Both"
                        option: "X only"
                        option: "Y only"
                    optionmenu: "Show axis values", tmpShowAxisValues
                        option: "None"
                        option: "Both"
                        option: "X only"
                        option: "Y only"
                    optionmenu: "Font", tmpFont
                        option: "Helvetica"
                        option: "Times"
                        option: "Palatino"
                        option: "Courier"
                    comment: "🏷️ Axis labels"
                    comment: "Formatting: %italic · #bold · ^super · underscore = subscript · \% plus a space prints %"
                    sentence: "X axis label", tmpXLabel$
                    sentence: "Y axis label", tmpYLabel$
                endif
            clicked = endPause: "Go Back", "Quit", toggleLabel$, "Draw", 4, 1

            if clicked = 1
                wavFormDone = 1
            elsif clicked = 2
                @emlSaveConfig
                exitScript: ""
            elsif clicked = 3
                tmpTMin$ = string$ (time_minimum)
                tmpTMax$ = string$ (time_maximum)
                tmpAMin$ = string$ (amplitude_minimum)
                tmpAMax$ = string$ (amplitude_maximum)
                if config_showAdvanced
                    tmpGridMode = gridline_mode
                    tmpShowInnerBox = show_inner_box
                    tmpShowAxisNames = show_axis_names
                    tmpShowTicks = show_ticks
                    tmpShowAxisValues = show_axis_values
                    tmpFont = font
                    tmpDPI = output_DPI
                    tmpXLabel$ = x_axis_label$
                    tmpYLabel$ = y_axis_label$
                    # Toggling TO beginner: reset advanced-only fields
                    tmpGridMode = config_gridlineMode
                    tmpShowInnerBox = config_showInnerBox
                    tmpShowAxisNames = config_showAxisNames
                    tmpShowTicks = config_showTicks
                    tmpShowAxisValues = config_showAxisValues
                    tmpFont = config_font
                    tmpDPI = config_outputDPI
                    tmpXLabel$ = ""
                    tmpYLabel$ = ""
                endif
                config_showAdvanced = 1 - config_showAdvanced
            else
                wavFormDone = 1
                allFormsDone = 1

                timeMin = time_minimum
                timeMax = time_maximum
                ampMin = amplitude_minimum
                ampMax = amplitude_maximum
                prev_wav_timeMin = timeMin
                prev_wav_timeMax = timeMax
                prev_wav_ampMin = ampMin
                prev_wav_ampMax = ampMax

                if config_showAdvanced
                    tmpGridMode = gridline_mode
                    tmpShowInnerBox = show_inner_box
                    tmpShowAxisNames = show_axis_names
                    tmpShowTicks = show_ticks
                    tmpShowAxisValues = show_axis_values
                    tmpFont = font
                    tmpDPI = output_DPI
                    tmpXLabel$ = x_axis_label$
                    tmpYLabel$ = y_axis_label$
                    config_gridlineMode = gridline_mode
                    emlShowInnerBox = show_inner_box
                    emlFont$ = font$
                    config_showInnerBox = show_inner_box
                    config_showAxisNames = show_axis_names
                    config_showTicks = show_ticks
                    config_showAxisValues = show_axis_values
                    @emlExpandAxisControls
                    config_font$ = font$
                    config_font = font
                    config_outputDPI = output_DPI
                endif
                gridline_mode = tmpGridMode
                output_DPI = tmpDPI
                x_axis_label$ = tmpXLabel$
                y_axis_label$ = tmpYLabel$
                if x_axis_label$ = ""
                    x_axis_label$ = defaultXLabel$[2]
                endif
                if y_axis_label$ = ""
                    y_axis_label$ = defaultYLabel$[2]
                endif
            endif
        until wavFormDone = 1

    elsif graph_type = 3
        # =============================================================
        # Spectrum — Page 2
        # =============================================================

        if lastDrawnGraphType = 3
            tmpFMin$ = string$ (prev_spec_freqMin)
            tmpFMax$ = string$ (prev_spec_freqMax)
            tmpPMin$ = string$ (prev_spec_powerMin)
            tmpPMax$ = string$ (prev_spec_powerMax)
        else
            tmpFMin$ = "0"
            tmpFMax$ = "0"
            tmpPMin$ = "0"
            tmpPMax$ = "0"
        endif
        tmpXLabel$ = ""
        tmpYLabel$ = ""

        specFormDone = 0
        repeat
            if config_showAdvanced
                toggleLabel$ = "Beginner"
            else
                toggleLabel$ = "Advanced"
            endif

            beginPause: "Spectrum Settings"
                comment: "📐 Frequency range (both 0 = auto)"
                real: "Frequency minimum", tmpFMin$
                real: "Frequency maximum", tmpFMax$
                comment: "📐 Power range (both 0 = auto)"
                real: "Power maximum", tmpPMax$
                real: "Power minimum", tmpPMin$
                if config_showAdvanced
                    optionmenu: "Gridline mode", tmpGridMode
                        option: "Both"
                        option: "Horizontal only"
                        option: "Vertical only"
                        option: "Off"
                    optionmenu: "Output DPI", tmpDPI
                        option: "300 dpi"
                        option: "600 dpi"
                    boolean: "Show inner box", tmpShowInnerBox
                    optionmenu: "Show axis names", tmpShowAxisNames
                        option: "None"
                        option: "Both"
                        option: "X only"
                        option: "Y only"
                    optionmenu: "Show ticks", tmpShowTicks
                        option: "None"
                        option: "Both"
                        option: "X only"
                        option: "Y only"
                    optionmenu: "Show axis values", tmpShowAxisValues
                        option: "None"
                        option: "Both"
                        option: "X only"
                        option: "Y only"
                    optionmenu: "Font", tmpFont
                        option: "Helvetica"
                        option: "Times"
                        option: "Palatino"
                        option: "Courier"
                    comment: "🏷️ Axis labels"
                    comment: "Formatting: %italic · #bold · ^super · underscore = subscript · \% plus a space prints %"
                    sentence: "X axis label", tmpXLabel$
                    sentence: "Y axis label", tmpYLabel$
                endif
            clicked = endPause: "Go Back", "Quit", toggleLabel$, "Draw", 4, 1

            if clicked = 1
                specFormDone = 1
            elsif clicked = 2
                @emlSaveConfig
                exitScript: ""
            elsif clicked = 3
                tmpFMin$ = string$ (frequency_minimum)
                tmpFMax$ = string$ (frequency_maximum)
                tmpPMin$ = string$ (power_minimum)
                tmpPMax$ = string$ (power_maximum)
                if config_showAdvanced
                    tmpGridMode = gridline_mode
                    tmpShowInnerBox = show_inner_box
                    tmpShowAxisNames = show_axis_names
                    tmpShowTicks = show_ticks
                    tmpShowAxisValues = show_axis_values
                    tmpFont = font
                    tmpDPI = output_DPI
                    tmpXLabel$ = x_axis_label$
                    tmpYLabel$ = y_axis_label$
                    # Toggling TO beginner: reset advanced-only fields
                    tmpGridMode = config_gridlineMode
                    tmpShowInnerBox = config_showInnerBox
                    tmpShowAxisNames = config_showAxisNames
                    tmpShowTicks = config_showTicks
                    tmpShowAxisValues = config_showAxisValues
                    tmpFont = config_font
                    tmpDPI = config_outputDPI
                    tmpXLabel$ = ""
                    tmpYLabel$ = ""
                endif
                config_showAdvanced = 1 - config_showAdvanced
            else
                specFormDone = 1
                allFormsDone = 1

                freqMin = frequency_minimum
                freqMax = frequency_maximum
                powerMin = power_minimum
                powerMax = power_maximum
                prev_spec_freqMin = freqMin
                prev_spec_freqMax = freqMax
                prev_spec_powerMin = powerMin
                prev_spec_powerMax = powerMax

                if config_showAdvanced
                    tmpGridMode = gridline_mode
                    tmpShowInnerBox = show_inner_box
                    tmpShowAxisNames = show_axis_names
                    tmpShowTicks = show_ticks
                    tmpShowAxisValues = show_axis_values
                    tmpFont = font
                    tmpDPI = output_DPI
                    tmpXLabel$ = x_axis_label$
                    tmpYLabel$ = y_axis_label$
                    config_gridlineMode = gridline_mode
                    emlShowInnerBox = show_inner_box
                    emlFont$ = font$
                    config_showInnerBox = show_inner_box
                    config_showAxisNames = show_axis_names
                    config_showTicks = show_ticks
                    config_showAxisValues = show_axis_values
                    @emlExpandAxisControls
                    config_font$ = font$
                    config_font = font
                    config_outputDPI = output_DPI
                endif
                gridline_mode = tmpGridMode
                output_DPI = tmpDPI
                x_axis_label$ = tmpXLabel$
                y_axis_label$ = tmpYLabel$
                if x_axis_label$ = ""
                    x_axis_label$ = defaultXLabel$[3]
                endif
                if y_axis_label$ = ""
                    y_axis_label$ = defaultYLabel$[3]
                endif
            endif
        until specFormDone = 1

    elsif graph_type = 4
        # =============================================================
        # LTAS — Page 2
        # =============================================================

        if lastDrawnGraphType = 4
            tmpFMin$ = string$ (prev_ltas_freqMin)
            tmpFMax$ = string$ (prev_ltas_freqMax)
            tmpPMin$ = string$ (prev_ltas_powerMin)
            tmpPMax$ = string$ (prev_ltas_powerMax)
            tmpShowCurve = prev_ltas_showCurve
            tmpShowBars = prev_ltas_showBars
            tmpShowPoles = prev_ltas_showPoles
            tmpShowSpeckles = prev_ltas_showSpeckles
        else
            tmpFMin$ = "0"
            tmpFMax$ = "0"
            tmpPMin$ = "0"
            tmpPMax$ = "0"
            tmpShowCurve = 1
            tmpShowBars = 0
            tmpShowPoles = 0
            tmpShowSpeckles = 0
        endif
        tmpXLabel$ = ""
        tmpYLabel$ = ""

        ltasFormDone = 0
        repeat
            if config_showAdvanced
                toggleLabel$ = "Beginner"
            else
                toggleLabel$ = "Advanced"
            endif

            beginPause: "LTAS Settings"
                comment: "📐 Frequency range (both 0 = auto)"
                real: "Frequency minimum", tmpFMin$
                real: "Frequency maximum", tmpFMax$
                comment: "📐 Power range (both 0 = auto)"
                real: "Power maximum", tmpPMax$
                real: "Power minimum", tmpPMin$
                if config_showAdvanced
                    optionmenu: "Gridline mode", tmpGridMode
                        option: "Both"
                        option: "Horizontal only"
                        option: "Vertical only"
                        option: "Off"
                    optionmenu: "Output DPI", tmpDPI
                        option: "300 dpi"
                        option: "600 dpi"
                    boolean: "Show inner box", tmpShowInnerBox
                    optionmenu: "Show axis names", tmpShowAxisNames
                        option: "None"
                        option: "Both"
                        option: "X only"
                        option: "Y only"
                    optionmenu: "Show ticks", tmpShowTicks
                        option: "None"
                        option: "Both"
                        option: "X only"
                        option: "Y only"
                    optionmenu: "Show axis values", tmpShowAxisValues
                        option: "None"
                        option: "Both"
                        option: "X only"
                        option: "Y only"
                    optionmenu: "Font", tmpFont
                        option: "Helvetica"
                        option: "Times"
                        option: "Palatino"
                        option: "Courier"
                    comment: "🎨 Drawing methods"
                    boolean: "Show curve", tmpShowCurve
                    boolean: "Show bars", tmpShowBars
                    boolean: "Show poles", tmpShowPoles
                    boolean: "Show speckles", tmpShowSpeckles
                    comment: "🏷️ Axis labels"
                    comment: "Formatting: %italic · #bold · ^super · underscore = subscript · \% plus a space prints %"
                    sentence: "X axis label", tmpXLabel$
                    sentence: "Y axis label", tmpYLabel$
                endif
            clicked = endPause: "Go Back", "Quit", toggleLabel$, "Draw", 4, 1

            if clicked = 1
                ltasFormDone = 1
            elsif clicked = 2
                @emlSaveConfig
                exitScript: ""
            elsif clicked = 3
                tmpFMin$ = string$ (frequency_minimum)
                tmpFMax$ = string$ (frequency_maximum)
                tmpPMin$ = string$ (power_minimum)
                tmpPMax$ = string$ (power_maximum)
                if config_showAdvanced
                    tmpGridMode = gridline_mode
                    tmpShowInnerBox = show_inner_box
                    tmpShowAxisNames = show_axis_names
                    tmpShowTicks = show_ticks
                    tmpShowAxisValues = show_axis_values
                    tmpFont = font
                    tmpDPI = output_DPI
                    tmpXLabel$ = x_axis_label$
                    tmpYLabel$ = y_axis_label$
                    tmpShowCurve = show_curve
                    tmpShowBars = show_bars
                    tmpShowPoles = show_poles
                    tmpShowSpeckles = show_speckles
                    # Toggling TO beginner: reset advanced-only fields
                    tmpGridMode = config_gridlineMode
                    tmpShowInnerBox = config_showInnerBox
                    tmpShowAxisNames = config_showAxisNames
                    tmpShowTicks = config_showTicks
                    tmpShowAxisValues = config_showAxisValues
                    tmpFont = config_font
                    tmpDPI = config_outputDPI
                    tmpXLabel$ = ""
                    tmpYLabel$ = ""
                    tmpShowCurve = 1
                    tmpShowBars = 0
                    tmpShowPoles = 0
                    tmpShowSpeckles = 0
                endif
                config_showAdvanced = 1 - config_showAdvanced
            else
                ltasFormDone = 1
                allFormsDone = 1

                freqMin = frequency_minimum
                freqMax = frequency_maximum
                powerMin = power_minimum
                powerMax = power_maximum
                prev_ltas_freqMin = freqMin
                prev_ltas_freqMax = freqMax
                prev_ltas_powerMin = powerMin
                prev_ltas_powerMax = powerMax

                if config_showAdvanced
                    tmpGridMode = gridline_mode
                    tmpShowInnerBox = show_inner_box
                    tmpShowAxisNames = show_axis_names
                    tmpShowTicks = show_ticks
                    tmpShowAxisValues = show_axis_values
                    tmpFont = font
                    tmpDPI = output_DPI
                    tmpXLabel$ = x_axis_label$
                    tmpYLabel$ = y_axis_label$
                    tmpShowCurve = show_curve
                    tmpShowBars = show_bars
                    tmpShowPoles = show_poles
                    tmpShowSpeckles = show_speckles
                    config_gridlineMode = gridline_mode
                    emlShowInnerBox = show_inner_box
                    emlFont$ = font$
                    config_showInnerBox = show_inner_box
                    config_showAxisNames = show_axis_names
                    config_showTicks = show_ticks
                    config_showAxisValues = show_axis_values
                    @emlExpandAxisControls
                    config_font$ = font$
                    config_font = font
                    config_outputDPI = output_DPI
                endif
                # Capture method selections (beginner defaults to Curve only)
                ltasShowCurve = tmpShowCurve
                ltasShowBars = tmpShowBars
                ltasShowPoles = tmpShowPoles
                ltasShowSpeckles = tmpShowSpeckles
                # Persist for next loop
                prev_ltas_showCurve = ltasShowCurve
                prev_ltas_showBars = ltasShowBars
                prev_ltas_showPoles = ltasShowPoles
                prev_ltas_showSpeckles = ltasShowSpeckles
                gridline_mode = tmpGridMode
                output_DPI = tmpDPI
                x_axis_label$ = tmpXLabel$
                y_axis_label$ = tmpYLabel$
                if x_axis_label$ = ""
                    x_axis_label$ = defaultXLabel$[4]
                endif
                if y_axis_label$ = ""
                    y_axis_label$ = defaultYLabel$[4]
                endif
            endif
        until ltasFormDone = 1

    elsif graph_type = 5
        # =============================================================
        # Time Series — Page 2 (format selection + column mapping)
        # =============================================================
        #
        # D3b. This page absorbed the old type 13, "Time Series (with CI)",
        # whose registry row has now gone. The only trace a user could follow
        # to it is the toggle below, so the toggle's label carries the retired
        # type's name: "Show confidence interval (Time Series with CI)".
        # Praat drops a TRAILING parenthesised part when it derives the form
        # variable name (same trick as "Adjustment method (nonparametric
        # post-hoc only)" further down), so the value still arrives as
        # show_confidence_interval and the two read sites below are unchanged.
        # Do not move the parentheses into the middle of the label.

        # --- Auto-detect column defaults ---
        tsTimeIdx = 1
        tsSeries1Idx = min (2, nCols)
        tsSeries2Idx = 1
        tsSeries3Idx = 1
        tsSeries4Idx = 1
        tsSeries5Idx = 1
        tsValueIdx = min (2, nCols)
        tsGroupIdx = 1

        if prev_tsTimeIdx > 0
            tsTimeIdx = prev_tsTimeIdx
            tsSeries1Idx = prev_tsSeries1Idx
            tsSeries2Idx = prev_tsSeries2Idx
            tsSeries3Idx = prev_tsSeries3Idx
            tsSeries4Idx = prev_tsSeries4Idx
            tsSeries5Idx = prev_tsSeries5Idx
            tsValueIdx = prev_tsValueIdx
            tsGroupIdx = prev_tsGroupIdx
            # Guard against 0 indices from cross-format persistence
            if tsSeries1Idx < 1
                tsSeries1Idx = min (2, nCols)
            endif
            if tsValueIdx < 1
                tsValueIdx = min (2, nCols)
            endif
            if tsGroupIdx < 1
                tsGroupIdx = 1
            endif
        else
            # Pass 1: keyword matching
            # Column-role defaults come from @emlGuessColumnRoles, the same
            # weighted guesser the wizard and every stats wrapper already use.
            # This site used to carry its own three-keyword copy of it; see the
            # note at the top of this file. Only non-zero guesses overwrite the
            # positional defaults set above, so an undetected role still falls
            # back exactly as before.
            @emlGuessColumnRoles: objectId
            if emlGuessColumnRoles.timeIdx > 0
                tsTimeIdx = emlGuessColumnRoles.timeIdx
            endif
            if emlGuessColumnRoles.dataIdx > 0
                tsSeries1Idx = emlGuessColumnRoles.dataIdx
            endif
            if emlGuessColumnRoles.dataIdx > 0
                tsValueIdx = emlGuessColumnRoles.dataIdx
            endif
            if emlGuessColumnRoles.groupIdx > 0
                tsGroupIdx = emlGuessColumnRoles.groupIdx + 1
            endif
            # Pass 2: verify time column is numeric; fallback to first numeric
            @emlCheckNumericColumn: objectId, colName$[tsTimeIdx]
            if emlCheckNumericColumn.isNumeric = 0
                tsTimeIdx = 0
                for iCol from 1 to nCols
                    if tsTimeIdx = 0
                        @emlCheckNumericColumn: objectId, colName$[iCol]
                        if emlCheckNumericColumn.isNumeric = 1
                            tsTimeIdx = iCol
                        endif
                    endif
                endfor
                if tsTimeIdx = 0
                    tsTimeIdx = 1
                endif
            endif
            # Verify value/series 1 column is numeric; fallback to first numeric != time
            @emlCheckNumericColumn: objectId, colName$[tsSeries1Idx]
            if emlCheckNumericColumn.isNumeric = 0
                tsSeries1Idx = 0
                for iCol from 1 to nCols
                    if tsSeries1Idx = 0 and iCol <> tsTimeIdx
                        @emlCheckNumericColumn: objectId, colName$[iCol]
                        if emlCheckNumericColumn.isNumeric = 1
                            tsSeries1Idx = iCol
                        endif
                    endif
                endfor
                if tsSeries1Idx = 0
                    tsSeries1Idx = min (2, nCols)
                endif
                tsValueIdx = tsSeries1Idx
            endif
        endif

        # Initialize tmp vars for advanced fields
        if lastDrawnGraphType = 5
            tmpTMin$ = string$ (prev_ts_timeMin)
            tmpTMax$ = string$ (prev_ts_timeMax)
            tmpVMin$ = string$ (prev_ts_valueMin)
            tmpVMax$ = string$ (prev_ts_valueMax)
        else
            tmpTMin$ = "0"
            tmpTMax$ = "0"
            tmpVMin$ = "0"
            tmpVMax$ = "0"
        endif
        tmpXLabel$ = ""
        tmpYLabel$ = ""

        # Default format from previous pass or 1 (wide)
        if prev_tsDataFormat > 0
            tsDataFormat = prev_tsDataFormat
        else
            tsDataFormat = 1
        endif
        tsShowCI = prev_tsShowCI

        tsFormatDone = 0
        repeat
            # --- Format selection ---
            beginPause: "Line Chart -- Data Format"
                comment: "How is your data organized?"
                comment: ""
                comment: "Wide: each series is a separate column (e.g., time, F1, F2)"
                comment: "Long: one value column with a group identifier"
                optionmenu: "Data format", tsDataFormat
                    option: "Wide (multiple columns)"
                    option: "Long (value + group)"
            clicked = endPause: "Go Back", "Quit", "Continue", 3, 1

            if clicked = 1
                # Go Back to main form
                tsFormatDone = 1
            elsif clicked = 2
                @emlSaveConfig
                exitScript: ""
            else
                tsDataFormat = data_format

                # --- Column mapping form ---
                tsFormDone = 0
                repeat
                    if config_showAdvanced
                        tsToggleLabel$ = "Beginner"
                    else
                        tsToggleLabel$ = "Advanced"
                    endif

                    beginPause: "Line Chart -- Column Mapping"
                        comment: "📋 Select columns from your Table."
                        optionmenu: "Time column", tsTimeIdx
                            for iCol from 1 to nCols
                                option: colName$[iCol]
                            endfor
                        if tsDataFormat = 1
                            optionmenu: "Series 1", tsSeries1Idx
                                for iCol from 1 to nCols
                                    option: colName$[iCol]
                                endfor
                            optionmenu: "Series 2", tsSeries2Idx
                                option: "(none)"
                                for iCol from 1 to nCols
                                    option: colName$[iCol]
                                endfor
                            optionmenu: "Series 3", tsSeries3Idx
                                option: "(none)"
                                for iCol from 1 to nCols
                                    option: colName$[iCol]
                                endfor
                            optionmenu: "Series 4", tsSeries4Idx
                                option: "(none)"
                                for iCol from 1 to nCols
                                    option: colName$[iCol]
                                endfor
                            optionmenu: "Series 5", tsSeries5Idx
                                option: "(none)"
                                for iCol from 1 to nCols
                                    option: colName$[iCol]
                                endfor
                            boolean: "Show confidence interval (Time Series with CI)", tsShowCI
                        else
                            optionmenu: "Value column", tsValueIdx
                                for iCol from 1 to nCols
                                    option: colName$[iCol]
                                endfor
                            optionmenu: "Group column", tsGroupIdx
                                option: "(none)"
                                for iCol from 1 to nCols
                                    option: colName$[iCol]
                                endfor
                            optionmenu: "Group order", prev_groupSort
                                option: "Table order"
                                option: "Alphabetical"
                            boolean: "Show confidence interval (Time Series with CI)", tsShowCI
                        endif
                        if config_showAdvanced
                            comment: "📐 X-axis range (both 0 = auto)"
                            real: "Time minimum", tmpTMin$
                            real: "Time maximum", tmpTMax$
                            comment: "📐 Y-axis range (both 0 = auto)"
                            real: "Value maximum", tmpVMax$
                            real: "Value minimum", tmpVMin$
                            optionmenu: "Gridline mode", tmpGridMode
                                option: "Both"
                                option: "Horizontal only"
                                option: "Vertical only"
                                option: "Off"
                            optionmenu: "Output DPI", tmpDPI
                                option: "300 dpi"
                                option: "600 dpi"
                            boolean: "Show inner box", tmpShowInnerBox
                            optionmenu: "Show axis names", tmpShowAxisNames
                                option: "None"
                                option: "Both"
                                option: "X only"
                                option: "Y only"
                            optionmenu: "Show ticks", tmpShowTicks
                                option: "None"
                                option: "Both"
                                option: "X only"
                                option: "Y only"
                            optionmenu: "Show axis values", tmpShowAxisValues
                                option: "None"
                                option: "Both"
                                option: "X only"
                                option: "Y only"
                            optionmenu: "Font", tmpFont
                                option: "Helvetica"
                                option: "Times"
                                option: "Palatino"
                                option: "Courier"
                            comment: "🏷️ Axis labels (blank = auto from column)"
                            comment: "Formatting: %italic · #bold · ^super · underscore = subscript · \% plus a space prints %"
                            sentence: "X axis label", tmpXLabel$
                            sentence: "Y axis label", tmpYLabel$
                        endif
                    clicked = endPause: "Go Back", "Quit", tsToggleLabel$, "Draw", 4, 1

                    if clicked = 1
                        # Go Back to format question
                        tsFormDone = 1
                    elsif clicked = 2
                        @emlSaveConfig
                        exitScript: ""
                    elsif clicked = 3
                        # Toggle — preserve beginner field values
                        tsTimeIdx = time_column
                        if tsDataFormat = 1
                            tsSeries1Idx = series_1
                            tsSeries2Idx = series_2
                            tsSeries3Idx = series_3
                            tsSeries4Idx = series_4
                            tsSeries5Idx = series_5
                            tsShowCI = show_confidence_interval
                        else
                            tsValueIdx = value_column
                            tsGroupIdx = group_column
                            prev_groupSort = group_order
                            config_groupSort = group_order
                            tsShowCI = show_confidence_interval
                        endif
                        if config_showAdvanced
                            tmpTMin$ = string$ (time_minimum)
                            tmpTMax$ = string$ (time_maximum)
                            tmpVMin$ = string$ (value_minimum)
                            tmpVMax$ = string$ (value_maximum)
                            tmpGridMode = gridline_mode
                            tmpShowInnerBox = show_inner_box
                            tmpShowAxisNames = show_axis_names
                            tmpShowTicks = show_ticks
                            tmpShowAxisValues = show_axis_values
                            tmpFont = font
                            tmpDPI = output_DPI
                            tmpXLabel$ = x_axis_label$
                            tmpYLabel$ = y_axis_label$
                            # Toggling TO beginner: reset advanced-only fields
                            tmpTMin$ = "0"
                            tmpTMax$ = "0"
                            tmpVMin$ = "0"
                            tmpVMax$ = "0"
                            tmpGridMode = config_gridlineMode
                            tmpShowInnerBox = config_showInnerBox
                            tmpShowAxisNames = config_showAxisNames
                            tmpShowTicks = config_showTicks
                            tmpShowAxisValues = config_showAxisValues
                            tmpFont = config_font
                            tmpDPI = config_outputDPI
                            tmpXLabel$ = ""
                            tmpYLabel$ = ""
                        endif
                        config_showAdvanced = 1 - config_showAdvanced
                    else
                        # Draw — capture values and exit
                        tsFormDone = 1
                        tsFormatDone = 1
                        allFormsDone = 1

                        # Capture advanced from form or tmp
                        if config_showAdvanced
                            tmpTMin$ = string$ (time_minimum)
                            tmpTMax$ = string$ (time_maximum)
                            tmpVMin$ = string$ (value_minimum)
                            tmpVMax$ = string$ (value_maximum)
                            tmpGridMode = gridline_mode
                            tmpShowInnerBox = show_inner_box
                            tmpShowAxisNames = show_axis_names
                            tmpShowTicks = show_ticks
                            tmpShowAxisValues = show_axis_values
                            tmpFont = font
                            tmpDPI = output_DPI
                            tmpXLabel$ = x_axis_label$
                            tmpYLabel$ = y_axis_label$
                            config_gridlineMode = gridline_mode
                            emlShowInnerBox = show_inner_box
                            emlFont$ = font$
                            config_showInnerBox = show_inner_box
                            config_showAxisNames = show_axis_names
                            config_showTicks = show_ticks
                            config_showAxisValues = show_axis_values
                            @emlExpandAxisControls
                            config_font$ = font$
                            config_font = font
                            config_outputDPI = output_DPI
                        endif
                        gridline_mode = tmpGridMode
                        output_DPI = tmpDPI

                        # Column names — format-dependent
                        timeColName$ = time_column$
                        tsNSeries = 1
                        if tsDataFormat = 1
                            # Wide format — count series and melt
                            tsNSeries = 1
                            tsSeriesCol$[1] = series_1$
                            if series_2$ <> "(none)"
                                tsNSeries = tsNSeries + 1
                                tsSeriesCol$[tsNSeries] = series_2$
                            endif
                            if series_3$ <> "(none)"
                                tsNSeries = tsNSeries + 1
                                tsSeriesCol$[tsNSeries] = series_3$
                            endif
                            if series_4$ <> "(none)"
                                tsNSeries = tsNSeries + 1
                                tsSeriesCol$[tsNSeries] = series_4$
                            endif
                            if series_5$ <> "(none)"
                                tsNSeries = tsNSeries + 1
                                tsSeriesCol$[tsNSeries] = series_5$
                            endif
                            if tsNSeries >= 2
                                # Melt to long format
                                selectObject: objectId
                                nDataRows = Get number of rows
                                nMeltRows = nDataRows * tsNSeries
                                tsMeltTableId = Create Table with column names: "eml_melt",
                                ... nMeltRows, timeColName$ + " eml_series eml_value"
                                meltRow = 0
                                for iSeries from 1 to tsNSeries
                                    for iRow from 1 to nDataRows
                                        meltRow = meltRow + 1
                                        selectObject: objectId
                                        val$ = Get value: iRow, timeColName$
                                        timeVal = number (val$)
                                        val$ = Get value: iRow, tsSeriesCol$[iSeries]
                                        dataVal = number (val$)
                                        selectObject: tsMeltTableId
                                        Set numeric value: meltRow, timeColName$, timeVal
                                        Set string value: meltRow, "eml_series", tsSeriesCol$[iSeries]
                                        Set numeric value: meltRow, "eml_value", dataVal
                                    endfor
                                endfor
                                tsOrigObjectId = objectId
                                objectId = tsMeltTableId
                                valueColName$ = "eml_value"
                                groupColName$ = "eml_series"
                            else
                                # Single series in wide mode
                                valueColName$ = series_1$
                                groupColName$ = ""
                            endif
                            # Save wide-format persistence
                            prev_tsSeries1Idx = series_1
                            prev_tsSeries2Idx = series_2
                            prev_tsSeries3Idx = series_3
                            prev_tsSeries4Idx = series_4
                            prev_tsSeries5Idx = series_5
                            tsShowCI = show_confidence_interval
                        else
                            # Long format
                            valueColName$ = value_column$
                            if group_column$ = "(none)"
                                groupColName$ = ""
                            else
                                groupColName$ = group_column$
                            endif
                            # Save long-format persistence
                            prev_tsValueIdx = value_column
                            prev_tsGroupIdx = group_column
                            prev_groupSort = group_order
                            config_groupSort = group_order
                            tsShowCI = show_confidence_interval
                        endif

                        prev_tsTimeIdx = time_column
                        prev_tsDataFormat = tsDataFormat
                        prev_tsShowCI = tsShowCI

                        timeMin = number (tmpTMin$)
                        timeMax = number (tmpTMax$)
                        valueMin = number (tmpVMin$)
                        valueMax = number (tmpVMax$)
                        prev_ts_timeMin = timeMin
                        prev_ts_timeMax = timeMax
                        prev_ts_valueMin = valueMin
                        prev_ts_valueMax = valueMax

                        # Axis labels
                        x_axis_label$ = tmpXLabel$
                        y_axis_label$ = tmpYLabel$
                        if x_axis_label$ = ""
                            @emlCapitalizeLabel: timeColName$
                            x_axis_label$ = emlCapitalizeLabel.result$
                        endif
                        if y_axis_label$ = ""
                            if tsDataFormat = 1 and tsNSeries >= 2
                                y_axis_label$ = ""
                            else
                                @emlCapitalizeLabel: valueColName$
                                y_axis_label$ = emlCapitalizeLabel.result$
                            endif
                        endif

                        # Validate numeric columns
                        @emlCheckNumericColumn: objectId, timeColName$
                        if emlCheckNumericColumn.isNumeric = 0
                            beginPause: "Column Error"
                                comment: """" + timeColName$ + """ does not contain numeric data."
                                comment: "Please select a numeric column for the time axis."
                            endPause: "OK", 1, 0
                            tsFormDone = 0
                            tsFormatDone = 0
                            allFormsDone = 0
                        else
                            @emlCheckNumericColumn: objectId, valueColName$
                            if emlCheckNumericColumn.isNumeric = 0
                                beginPause: "Column Error"
                                    comment: """" + valueColName$ + """ does not contain numeric data."
                                    comment: "Please select a numeric column for the value axis."
                                endPause: "OK", 1, 0
                                tsFormDone = 0
                                tsFormatDone = 0
                                allFormsDone = 0
                            endif
                        endif
                    endif
                until tsFormDone = 1
            endif
        until tsFormatDone = 1

    elsif graph_type = 6
        # =============================================================
        # Bar Chart — Page 2 (column mapping)
        # =============================================================

        # --- Auto-detect column defaults ---
        barGroupIdx = 1
        barValueIdx = min (2, nCols)
        barErrorIdx = 3

        if emlGraphsPresetGroupCol$ <> ""
            for .iPreset from 1 to nCols
                if colName$[.iPreset] = emlGraphsPresetGroupCol$
                    barGroupIdx = .iPreset
                endif
                if colName$[.iPreset] = emlGraphsPresetDataCol$
                    barValueIdx = .iPreset
                endif
            endfor
            # Consumed — clear so Redraw uses prev_* persistence
            emlGraphsPresetGroupCol$ = ""
            emlGraphsPresetDataCol$ = ""
        elsif prev_barGroupIdx > 0
            barGroupIdx = prev_barGroupIdx
            barValueIdx = prev_barValueIdx
            barErrorIdx = prev_barErrorIdx
        else
            # Pass 1: keyword matching
            # Column-role defaults come from @emlGuessColumnRoles, the same
            # weighted guesser the wizard and every stats wrapper already use.
            # This site used to carry its own three-keyword copy of it; see the
            # note at the top of this file. Only non-zero guesses overwrite the
            # positional defaults set above, so an undetected role still falls
            # back exactly as before.
            @emlGuessColumnRoles: objectId
            if emlGuessColumnRoles.groupIdx > 0
                barGroupIdx = emlGuessColumnRoles.groupIdx
            endif
            if emlGuessColumnRoles.dataIdx > 0
                barValueIdx = emlGuessColumnRoles.dataIdx
            endif
            for iCol from 1 to nCols
                testCol$ = colName$[iCol]
                if index_caseInsensitive (testCol$, "error") > 0 or index_caseInsensitive (testCol$, "sd") > 0 or index_caseInsensitive (testCol$, "se") > 0
                    barErrorIdx = iCol + 3
                endif
            endfor
            # Pass 2: verify value column is numeric; fallback to first numeric
            @emlCheckNumericColumn: objectId, colName$[barValueIdx]
            if emlCheckNumericColumn.isNumeric = 0
                barValueIdx = 0
                for iCol from 1 to nCols
                    if barValueIdx = 0 and iCol <> barGroupIdx
                        @emlCheckNumericColumn: objectId, colName$[iCol]
                        if emlCheckNumericColumn.isNumeric = 1
                            barValueIdx = iCol
                        endif
                    endif
                endfor
                if barValueIdx = 0
                    barValueIdx = min (2, nCols)
                endif
            endif
        endif

        # Initialize tmp vars for advanced fields
        if lastDrawnGraphType = 6
            tmpVMin$ = string$ (prev_bar_valueMin)
            tmpVMax$ = string$ (prev_bar_valueMax)
        else
            tmpVMin$ = "0"
            tmpVMax$ = "0"
        endif
        if config_gridlineMode = 2
            tmpGridMode = 2
        else
            tmpGridMode = 1
        endif
        tmpDPI = config_outputDPI
        tmpXLabel$ = ""
        tmpYLabel$ = ""
        tmpBarTestType = 1
        if annotTestType$ = "nonparametric"
            tmpBarTestType = 2
        endif
        tmpBarAnnotStyle = 1
        if annotStyle$ = "stars"
            tmpBarAnnotStyle = 2
        elsif annotStyle$ = "both"
            tmpBarAnnotStyle = 3
        endif

        barFormDone = 0
        repeat
            if config_showAdvanced
                barToggleLabel$ = "Beginner"
            else
                barToggleLabel$ = "Advanced"
            endif

            beginPause: "Bar Chart -- Column Mapping"
                comment: "📋 Select columns from your Table."
                optionmenu: "Value column", barValueIdx
                    for iCol from 1 to nCols
                        option: colName$[iCol]
                    endfor
                optionmenu: "Error bars", barErrorIdx
                    option: "(none)"
                    option: "SE (auto)"
                    option: "SD (auto)"
                    for iCol from 1 to nCols
                        option: colName$[iCol]
                    endfor
                optionmenu: "Group column", barGroupIdx
                    for iCol from 1 to nCols
                        option: colName$[iCol]
                    endfor
                optionmenu: "Group order", prev_groupSort
                    option: "Table order"
                    option: "Alphabetical"
                if config_showAdvanced
                    boolean: "Annotate results on graph", annotate
                    optionmenu: "Test type", tmpBarTestType
                        option: "Parametric"
                        option: "Nonparametric"
                    optionmenu: "Adjustment method (nonparametric post-hoc only)", prev_annotAdjustIdx
                        option: "Bonferroni"
                        option: "Holm"
                        option: "Benjamini-Hochberg"
                    optionmenu: "Significance style", tmpBarAnnotStyle
                        option: "p-value"
                        option: "stars"
                        option: "both"
                    boolean: "Show nonsignificant", annotShowNS
                    boolean: "Show effect sizes", annotShowEffect
                    optionmenu: "Annotation layout", annotLayoutMode
                        option: "Auto"
                        option: "Annotate"
                        option: "Matrix"
                    real: "Alpha", string$ (annotAlpha)
                    comment: "📐 Y-axis range (both 0 = auto)"
                    real: "Value maximum", tmpVMax$
                    real: "Value minimum", tmpVMin$
                    optionmenu: "Gridline mode", tmpGridMode
                        option: "Horizontal"
                        option: "Off"
                    optionmenu: "Output DPI", tmpDPI
                        option: "300 dpi"
                        option: "600 dpi"
                    boolean: "Show inner box", tmpShowInnerBox
                    optionmenu: "Show axis names", tmpShowAxisNames
                        option: "None"
                        option: "Both"
                        option: "X only"
                        option: "Y only"
                    optionmenu: "Show ticks", tmpShowTicks
                        option: "None"
                        option: "Both"
                        option: "X only"
                        option: "Y only"
                    optionmenu: "Show axis values", tmpShowAxisValues
                        option: "None"
                        option: "Both"
                        option: "X only"
                        option: "Y only"
                    optionmenu: "Font", tmpFont
                        option: "Helvetica"
                        option: "Times"
                        option: "Palatino"
                        option: "Courier"
                    comment: "🏷️ Axis labels (blank = auto from column)"
                    comment: "Formatting: %italic · #bold · ^super · underscore = subscript · \% plus a space prints %"
                    sentence: "X axis label", tmpXLabel$
                    sentence: "Y axis label", tmpYLabel$
                endif
            clicked = endPause: "Go Back", "Quit", barToggleLabel$, "Draw", 4, 1

            if clicked = 1
                barFormDone = 1
            elsif clicked = 2
                @emlSaveConfig
                exitScript: ""
            elsif clicked = 3
                barGroupIdx = group_column
                prev_groupSort = group_order
                config_groupSort = group_order
                barValueIdx = value_column
                barErrorIdx = error_bars
                if config_showAdvanced
                    # Toggling TO beginner: save advanced state
                    prev_adv_bar_annotate = annotate_results_on_graph
                    prev_adv_bar_annotShowNS = show_nonsignificant
                    prev_adv_bar_annotShowEffect = show_effect_sizes
                    prev_adv_bar_annotAlpha = alpha
                    prev_adv_bar_annotLayoutMode = annotation_layout
                    prev_adv_bar_testType = test_type
                    prev_adv_bar_annotStyle = significance_style
                    prev_annotAdjustIdx = adjustment_method
                    prev_adv_bar_VMin$ = string$ (value_minimum)
                    prev_adv_bar_VMax$ = string$ (value_maximum)
                    prev_adv_bar_gridMode = gridline_mode
                    prev_adv_bar_showInnerBox = show_inner_box
                    prev_adv_bar_showAxisNames = show_axis_names
                    prev_adv_bar_showTicks = show_ticks
                    prev_adv_bar_showAxisValues = show_axis_values
                    prev_adv_bar_font = font
                    prev_adv_bar_DPI = output_DPI
                    prev_adv_bar_XLabel$ = x_axis_label$
                    prev_adv_bar_YLabel$ = y_axis_label$
                    # Reset to beginner defaults
                    annotate = 0
                    annotShowNS = 0
                    annotShowEffect = 0
                    annotLayoutMode = 1
                    tmpBarTestType = 1
                    tmpBarAnnotStyle = 1
                    tmpVMin$ = "0"
                    tmpVMax$ = "0"
                    tmpGridMode = config_gridlineMode
                    tmpShowInnerBox = config_showInnerBox
                    tmpShowAxisNames = config_showAxisNames
                    tmpShowTicks = config_showTicks
                    tmpShowAxisValues = config_showAxisValues
                    tmpFont = config_font
                    tmpDPI = config_outputDPI
                    tmpXLabel$ = ""
                    tmpYLabel$ = ""
                else
                    # Toggling TO advanced: restore saved state
                    if variableExists ("prev_adv_bar_annotate")
                        annotate = prev_adv_bar_annotate
                        annotShowNS = prev_adv_bar_annotShowNS
                        annotShowEffect = prev_adv_bar_annotShowEffect
                        annotAlpha = prev_adv_bar_annotAlpha
                        annotLayoutMode = prev_adv_bar_annotLayoutMode
                        tmpBarTestType = prev_adv_bar_testType
                        tmpBarAnnotStyle = prev_adv_bar_annotStyle
                        tmpVMin$ = prev_adv_bar_VMin$
                        tmpVMax$ = prev_adv_bar_VMax$
                        tmpGridMode = prev_adv_bar_gridMode
                        tmpShowInnerBox = prev_adv_bar_showInnerBox
                        tmpShowAxisNames = prev_adv_bar_showAxisNames
                        tmpShowTicks = prev_adv_bar_showTicks
                        tmpShowAxisValues = prev_adv_bar_showAxisValues
                        tmpFont = prev_adv_bar_font
                        tmpDPI = prev_adv_bar_DPI
                        tmpXLabel$ = prev_adv_bar_XLabel$
                        tmpYLabel$ = prev_adv_bar_YLabel$
                    endif
                endif
                config_showAdvanced = 1 - config_showAdvanced
            else
                barFormDone = 1
                allFormsDone = 1

                if config_showAdvanced
                    tmpVMin$ = string$ (value_minimum)
                    tmpVMax$ = string$ (value_maximum)
                    tmpGridMode = gridline_mode
                    tmpShowInnerBox = show_inner_box
                    tmpShowAxisNames = show_axis_names
                    tmpShowTicks = show_ticks
                    tmpShowAxisValues = show_axis_values
                    tmpFont = font
                    tmpDPI = output_DPI
                    tmpXLabel$ = x_axis_label$
                    tmpYLabel$ = y_axis_label$
                    config_gridlineMode = gridline_mode
                    emlShowInnerBox = show_inner_box
                    emlFont$ = font$
                    config_showInnerBox = show_inner_box
                    config_showAxisNames = show_axis_names
                    config_showTicks = show_ticks
                    config_showAxisValues = show_axis_values
                    @emlExpandAxisControls
                    config_font$ = font$
                    config_font = font
                    config_outputDPI = output_DPI
                    annotate = annotate_results_on_graph
                    annotShowNS = show_nonsignificant
                    annotShowEffect = show_effect_sizes
                    annotAlpha = alpha
                    annotLayoutMode = annotation_layout
                    @emlAdjustMethodName: adjustment_method
                    annotCorrectionMethod$ = emlAdjustMethodName.name$
                    prev_annotAdjustIdx = adjustment_method
                    if test_type = 2
                        annotTestType$ = "nonparametric"
                    else
                        annotTestType$ = "parametric"
                    endif
                    if significance_style = 2
                        annotStyle$ = "stars"
                    elsif significance_style = 3
                        annotStyle$ = "both"
                    else
                        annotStyle$ = "p-value"
                    endif
                else
                    # Beginner defaults: reset all advanced-only fields
                    annotate = 0
                    annotShowNS = 0
                    annotShowEffect = 0
                    annotLayoutMode = 1
                    # annotTestType$ preserved — only meaningful when annotate=1
                    # annotStyle$ preserved — only meaningful when annotate=1
                endif
                gridline_mode = tmpGridMode
                output_DPI = tmpDPI

                groupColName$ = group_column$
                valueColName$ = value_column$

                # Error bars dropdown: 1=(none), 2=SE, 3=SD, 4+=custom column
                errorBarMode = 0
                errorColName$ = ""
                if error_bars = 2
                    errorBarMode = 1
                elsif error_bars = 3
                    errorBarMode = 2
                elsif error_bars >= 4
                    errorBarMode = 3
                    errorColName$ = error_bars$
                endif

                prev_barGroupIdx = group_column
                prev_groupSort = group_order
                config_groupSort = group_order
                prev_barValueIdx = value_column
                prev_barErrorIdx = error_bars

                valueMin = number (tmpVMin$)
                valueMax = number (tmpVMax$)
                prev_bar_valueMin = valueMin
                prev_bar_valueMax = valueMax

                x_axis_label$ = tmpXLabel$
                y_axis_label$ = tmpYLabel$
                if x_axis_label$ = ""
                    @emlCapitalizeLabel: groupColName$
                    x_axis_label$ = emlCapitalizeLabel.result$
                endif
                if y_axis_label$ = ""
                    @emlCapitalizeLabel: valueColName$
                    y_axis_label$ = emlCapitalizeLabel.result$
                endif

                # Validate numeric columns
                @emlCheckNumericColumn: objectId, valueColName$
                if emlCheckNumericColumn.isNumeric = 0
                    beginPause: "Column Error"
                        comment: """" + valueColName$ + """ does not contain numeric data."
                        comment: "Please select a numeric column for the value axis."
                    endPause: "OK", 1, 0
                    barFormDone = 0
                    allFormsDone = 0
                elsif errorBarMode = 3
                    @emlCheckNumericColumn: objectId, errorColName$
                    if emlCheckNumericColumn.isNumeric = 0
                        beginPause: "Column Error"
                            comment: """" + errorColName$ + """ does not contain numeric data."
                            comment: "Please select a numeric column for error bars, or choose (none)."
                        endPause: "OK", 1, 0
                        barFormDone = 0
                        allFormsDone = 0
                    endif
                endif
            endif
        until barFormDone = 1

    elsif graph_type = 7
        # =============================================================
        # Violin Plot — Page 2 (column mapping)
        # =============================================================

        # --- Auto-detect column defaults ---
        violinGroupIdx = 1
        violinValueIdx = min (2, nCols)

        if emlGraphsPresetGroupCol$ <> ""
            for .iPreset from 1 to nCols
                if colName$[.iPreset] = emlGraphsPresetGroupCol$
                    violinGroupIdx = .iPreset
                endif
                if colName$[.iPreset] = emlGraphsPresetDataCol$
                    violinValueIdx = .iPreset
                endif
            endfor
            # Consumed — clear so Redraw uses prev_* persistence
            emlGraphsPresetGroupCol$ = ""
            emlGraphsPresetDataCol$ = ""
        elsif prev_violinGroupIdx > 0
            violinGroupIdx = prev_violinGroupIdx
            violinValueIdx = prev_violinValueIdx
        else
            # Pass 1: keyword matching
            # Column-role defaults come from @emlGuessColumnRoles, the same
            # weighted guesser the wizard and every stats wrapper already use.
            # This site used to carry its own three-keyword copy of it; see the
            # note at the top of this file. Only non-zero guesses overwrite the
            # positional defaults set above, so an undetected role still falls
            # back exactly as before.
            @emlGuessColumnRoles: objectId
            if emlGuessColumnRoles.groupIdx > 0
                violinGroupIdx = emlGuessColumnRoles.groupIdx
            endif
            if emlGuessColumnRoles.dataIdx > 0
                violinValueIdx = emlGuessColumnRoles.dataIdx
            endif
            # Pass 2: verify value column is numeric; fallback to first numeric
            @emlCheckNumericColumn: objectId, colName$[violinValueIdx]
            if emlCheckNumericColumn.isNumeric = 0
                violinValueIdx = 0
                for iCol from 1 to nCols
                    if violinValueIdx = 0 and iCol <> violinGroupIdx
                        @emlCheckNumericColumn: objectId, colName$[iCol]
                        if emlCheckNumericColumn.isNumeric = 1
                            violinValueIdx = iCol
                        endif
                    endif
                endfor
                if violinValueIdx = 0
                    violinValueIdx = min (2, nCols)
                endif
            endif
        endif

        # Initialize tmp vars for advanced fields
        if lastDrawnGraphType = 7
            tmpVMin$ = string$ (prev_violin_valueMin)
            tmpVMax$ = string$ (prev_violin_valueMax)
        else
            tmpVMin$ = "0"
            tmpVMax$ = "0"
        endif
        if config_gridlineMode = 2
            tmpGridMode = 2
        else
            tmpGridMode = 1
        endif
        tmpDPI = config_outputDPI
        tmpXLabel$ = ""
        tmpYLabel$ = ""
        tmpViolinTestType = 1
        if annotTestType$ = "nonparametric"
            tmpViolinTestType = 2
        endif
        tmpViolinAnnotStyle = 1
        if annotStyle$ = "stars"
            tmpViolinAnnotStyle = 2
        elsif annotStyle$ = "both"
            tmpViolinAnnotStyle = 3
        endif

        violinFormDone = 0
        repeat
            if config_showAdvanced
                violinToggleLabel$ = "Beginner"
            else
                violinToggleLabel$ = "Advanced"
            endif

            beginPause: "Violin Plot -- Column Mapping"
                comment: "📋 Select columns from your Table."
                optionmenu: "Value column", violinValueIdx
                    for iCol from 1 to nCols
                        option: colName$[iCol]
                    endfor
                optionmenu: "Group column", violinGroupIdx
                    for iCol from 1 to nCols
                        option: colName$[iCol]
                    endfor
                optionmenu: "Group order", prev_groupSort
                    option: "Table order"
                    option: "Alphabetical"
                if config_showAdvanced
                    boolean: "Annotate results on graph", annotate
                    optionmenu: "Test type", tmpViolinTestType
                        option: "Parametric"
                        option: "Nonparametric"
                    optionmenu: "Adjustment method (nonparametric post-hoc only)", prev_annotAdjustIdx
                        option: "Bonferroni"
                        option: "Holm"
                        option: "Benjamini-Hochberg"
                    optionmenu: "Significance style", tmpViolinAnnotStyle
                        option: "p-value"
                        option: "stars"
                        option: "both"
                    boolean: "Show nonsignificant", annotShowNS
                    boolean: "Show effect sizes", annotShowEffect
                    optionmenu: "Annotation layout", annotLayoutMode
                        option: "Auto"
                        option: "Annotate"
                        option: "Matrix"
                    real: "Alpha", string$ (annotAlpha)
                    boolean: "Show jittered points", prev_violinShowJitter
                    comment: "📐 Y-axis range (both 0 = auto)"
                    real: "Value maximum", tmpVMax$
                    real: "Value minimum", tmpVMin$
                    optionmenu: "Gridline mode", tmpGridMode
                        option: "Horizontal"
                        option: "Off"
                    optionmenu: "Output DPI", tmpDPI
                        option: "300 dpi"
                        option: "600 dpi"
                    boolean: "Show inner box", tmpShowInnerBox
                    optionmenu: "Show axis names", tmpShowAxisNames
                        option: "None"
                        option: "Both"
                        option: "X only"
                        option: "Y only"
                    optionmenu: "Show ticks", tmpShowTicks
                        option: "None"
                        option: "Both"
                        option: "X only"
                        option: "Y only"
                    optionmenu: "Show axis values", tmpShowAxisValues
                        option: "None"
                        option: "Both"
                        option: "X only"
                        option: "Y only"
                    optionmenu: "Font", tmpFont
                        option: "Helvetica"
                        option: "Times"
                        option: "Palatino"
                        option: "Courier"
                    comment: "🏷️ Axis labels (blank = auto from column)"
                    comment: "Formatting: %italic · #bold · ^super · underscore = subscript · \% plus a space prints %"
                    sentence: "X axis label", tmpXLabel$
                    sentence: "Y axis label", tmpYLabel$
                endif
            clicked = endPause: "Go Back", "Quit", violinToggleLabel$, "Draw", 4, 1

            if clicked = 1
                violinFormDone = 1
            elsif clicked = 2
                @emlSaveConfig
                exitScript: ""
            elsif clicked = 3
                violinGroupIdx = group_column
                prev_groupSort = group_order
                config_groupSort = group_order
                violinValueIdx = value_column
                if config_showAdvanced
                    # Toggling TO beginner: save advanced state
                    prev_adv_vio_annotate = annotate_results_on_graph
                    prev_adv_vio_annotShowNS = show_nonsignificant
                    prev_adv_vio_annotShowEffect = show_effect_sizes
                    prev_adv_vio_annotAlpha = alpha
                    prev_adv_vio_annotLayoutMode = annotation_layout
                    prev_adv_vio_testType = test_type
                    prev_adv_vio_annotStyle = significance_style
                    prev_annotAdjustIdx = adjustment_method
                    prev_adv_vio_showJitter = show_jittered_points
                    prev_adv_vio_VMin$ = string$ (value_minimum)
                    prev_adv_vio_VMax$ = string$ (value_maximum)
                    prev_adv_vio_gridMode = gridline_mode
                    prev_adv_vio_showInnerBox = show_inner_box
                    prev_adv_vio_showAxisNames = show_axis_names
                    prev_adv_vio_showTicks = show_ticks
                    prev_adv_vio_showAxisValues = show_axis_values
                    prev_adv_vio_font = font
                    prev_adv_vio_DPI = output_DPI
                    prev_adv_vio_XLabel$ = x_axis_label$
                    prev_adv_vio_YLabel$ = y_axis_label$
                    # Reset to beginner defaults
                    annotate = 0
                    annotShowNS = 0
                    annotShowEffect = 0
                    annotLayoutMode = 1
                    prev_violinShowJitter = 0
                    tmpViolinTestType = 1
                    tmpViolinAnnotStyle = 1
                    tmpVMin$ = "0"
                    tmpVMax$ = "0"
                    tmpGridMode = config_gridlineMode
                    tmpShowInnerBox = config_showInnerBox
                    tmpShowAxisNames = config_showAxisNames
                    tmpShowTicks = config_showTicks
                    tmpShowAxisValues = config_showAxisValues
                    tmpFont = config_font
                    tmpDPI = config_outputDPI
                    tmpXLabel$ = ""
                    tmpYLabel$ = ""
                else
                    # Toggling TO advanced: restore saved state
                    if variableExists ("prev_adv_vio_annotate")
                        annotate = prev_adv_vio_annotate
                        annotShowNS = prev_adv_vio_annotShowNS
                        annotShowEffect = prev_adv_vio_annotShowEffect
                        annotAlpha = prev_adv_vio_annotAlpha
                        annotLayoutMode = prev_adv_vio_annotLayoutMode
                        tmpViolinTestType = prev_adv_vio_testType
                        tmpViolinAnnotStyle = prev_adv_vio_annotStyle
                        prev_violinShowJitter = prev_adv_vio_showJitter
                        tmpVMin$ = prev_adv_vio_VMin$
                        tmpVMax$ = prev_adv_vio_VMax$
                        tmpGridMode = prev_adv_vio_gridMode
                        tmpShowInnerBox = prev_adv_vio_showInnerBox
                        tmpShowAxisNames = prev_adv_vio_showAxisNames
                        tmpShowTicks = prev_adv_vio_showTicks
                        tmpShowAxisValues = prev_adv_vio_showAxisValues
                        tmpFont = prev_adv_vio_font
                        tmpDPI = prev_adv_vio_DPI
                        tmpXLabel$ = prev_adv_vio_XLabel$
                        tmpYLabel$ = prev_adv_vio_YLabel$
                    endif
                endif
                config_showAdvanced = 1 - config_showAdvanced
            else
                violinFormDone = 1
                allFormsDone = 1

                if config_showAdvanced
                    tmpVMin$ = string$ (value_minimum)
                    tmpVMax$ = string$ (value_maximum)
                    tmpGridMode = gridline_mode
                    tmpShowInnerBox = show_inner_box
                    tmpShowAxisNames = show_axis_names
                    tmpShowTicks = show_ticks
                    tmpShowAxisValues = show_axis_values
                    tmpFont = font
                    tmpDPI = output_DPI
                    tmpXLabel$ = x_axis_label$
                    tmpYLabel$ = y_axis_label$
                    config_gridlineMode = gridline_mode
                    emlShowInnerBox = show_inner_box
                    emlFont$ = font$
                    config_showInnerBox = show_inner_box
                    config_showAxisNames = show_axis_names
                    config_showTicks = show_ticks
                    config_showAxisValues = show_axis_values
                    @emlExpandAxisControls
                    config_font$ = font$
                    config_font = font
                    config_outputDPI = output_DPI
                    annotate = annotate_results_on_graph
                    annotShowNS = show_nonsignificant
                    annotShowEffect = show_effect_sizes
                    annotAlpha = alpha
                    annotLayoutMode = annotation_layout
                    prev_violinShowJitter = show_jittered_points
                    @emlAdjustMethodName: adjustment_method
                    annotCorrectionMethod$ = emlAdjustMethodName.name$
                    prev_annotAdjustIdx = adjustment_method
                    if test_type = 2
                        annotTestType$ = "nonparametric"
                    else
                        annotTestType$ = "parametric"
                    endif
                    if significance_style = 2
                        annotStyle$ = "stars"
                    elsif significance_style = 3
                        annotStyle$ = "both"
                    else
                        annotStyle$ = "p-value"
                    endif
                else
                    # Beginner defaults: reset all advanced-only fields
                    annotate = 0
                    annotShowNS = 0
                    annotShowEffect = 0
                    annotLayoutMode = 1
                    prev_violinShowJitter = 0
                    # annotTestType$ preserved — only meaningful when annotate=1
                    # annotStyle$ preserved — only meaningful when annotate=1
                endif
                gridline_mode = tmpGridMode
                output_DPI = tmpDPI

                groupColName$ = group_column$
                valueColName$ = value_column$

                prev_violinGroupIdx = group_column
                prev_groupSort = group_order
                config_groupSort = group_order
                prev_violinValueIdx = value_column

                valueMin = number (tmpVMin$)
                valueMax = number (tmpVMax$)
                prev_violin_valueMin = valueMin
                prev_violin_valueMax = valueMax

                x_axis_label$ = tmpXLabel$
                y_axis_label$ = tmpYLabel$
                if x_axis_label$ = ""
                    @emlCapitalizeLabel: groupColName$
                    x_axis_label$ = emlCapitalizeLabel.result$
                endif
                if y_axis_label$ = ""
                    @emlCapitalizeLabel: valueColName$
                    y_axis_label$ = emlCapitalizeLabel.result$
                endif

                # Validate numeric columns
                @emlCheckNumericColumn: objectId, valueColName$
                if emlCheckNumericColumn.isNumeric = 0
                    beginPause: "Column Error"
                        comment: """" + valueColName$ + """ does not contain numeric data."
                        comment: "Please select a numeric column for the value axis."
                    endPause: "OK", 1, 0
                    violinFormDone = 0
                    allFormsDone = 0
                endif
            endif
        until violinFormDone = 1

    elsif graph_type = 8
        # =============================================================
        # Scatter Plot — Page 2 (column mapping)
        # =============================================================

        # --- Auto-detect column defaults ---
        scatterXIdx = 1
        scatterYIdx = min (2, nCols)
        scatterGroupIdx = 1

        # --- Preset consumption (from stats wrappers) ---
        if emlGraphsPresetXCol$ <> ""
            for .iPreset from 1 to nCols
                if colName$[.iPreset] = emlGraphsPresetXCol$
                    scatterXIdx = .iPreset
                endif
                if colName$[.iPreset] = emlGraphsPresetYCol$
                    scatterYIdx = .iPreset
                endif
                if emlGraphsPresetGroupCol$ <> ""
                    if colName$[.iPreset] = emlGraphsPresetGroupCol$
                        scatterGroupIdx = .iPreset
                        scatterPresetHasGroup = 1
                    endif
                endif
            endfor
            emlGraphsPresetXCol$ = ""
            emlGraphsPresetYCol$ = ""
            emlGraphsPresetGroupCol$ = ""
        elsif prev_scatterXIdx > 0
            scatterXIdx = prev_scatterXIdx
            scatterYIdx = prev_scatterYIdx
            scatterGroupIdx = prev_scatterGroupIdx
        else
            # Pass 1: keyword matching
            # Column-role defaults come from @emlGuessColumnRoles, the same
            # weighted guesser the wizard and every stats wrapper already use.
            # This site used to carry its own three-keyword copy of it; see the
            # note at the top of this file. Only non-zero guesses overwrite the
            # positional defaults set above, so an undetected role still falls
            # back exactly as before.
            @emlGuessColumnRoles: objectId
            if emlGuessColumnRoles.dataIdx > 0
                scatterXIdx = emlGuessColumnRoles.dataIdx
            endif
            if emlGuessColumnRoles.dataIdx2 > 0
                scatterYIdx = emlGuessColumnRoles.dataIdx2
            endif
            if emlGuessColumnRoles.groupIdx > 0
                scatterGroupIdx = emlGuessColumnRoles.groupIdx
            endif
            # Pass 2: verify X column is numeric; fallback to first numeric
            @emlCheckNumericColumn: objectId, colName$[scatterXIdx]
            if emlCheckNumericColumn.isNumeric = 0
                scatterXIdx = 0
                for iCol from 1 to nCols
                    if scatterXIdx = 0
                        @emlCheckNumericColumn: objectId, colName$[iCol]
                        if emlCheckNumericColumn.isNumeric = 1
                            scatterXIdx = iCol
                        endif
                    endif
                endfor
                if scatterXIdx = 0
                    scatterXIdx = 1
                endif
            endif
            # Verify Y column is numeric; fallback to first numeric != X
            @emlCheckNumericColumn: objectId, colName$[scatterYIdx]
            if emlCheckNumericColumn.isNumeric = 0
                scatterYIdx = 0
                for iCol from 1 to nCols
                    if scatterYIdx = 0 and iCol <> scatterXIdx
                        @emlCheckNumericColumn: objectId, colName$[iCol]
                        if emlCheckNumericColumn.isNumeric = 1
                            scatterYIdx = iCol
                        endif
                    endif
                endfor
                if scatterYIdx = 0
                    scatterYIdx = min (2, nCols)
                endif
            endif
        endif

        # Initialize tmp vars for advanced fields
        if lastDrawnGraphType = 8
            tmpXMin$ = string$ (prev_scatter_xMin)
            tmpXMax$ = string$ (prev_scatter_xMax)
            tmpYMin$ = string$ (prev_scatter_yMin)
            tmpYMax$ = string$ (prev_scatter_yMax)
        else
            tmpXMin$ = "0"
            tmpXMax$ = "0"
            tmpYMin$ = "0"
            tmpYMax$ = "0"
        endif
        tmpXLabel$ = ""
        tmpYLabel$ = ""

        # Correlation method defaults (1=None, 2=Pearson, 3=Spearman, 4=Both)
        if annotCorrType$ = "both"
            tmpCorrType = 4
        elsif annotCorrType$ = "spearman"
            tmpCorrType = 3
        elsif annotCorrType$ = "pearson"
            tmpCorrType = 2
        else
            tmpCorrType = 1
        endif
        tmpAnnotStyle = 1
        if annotStyle$ = "stars"
            tmpAnnotStyle = 2
        elsif annotStyle$ = "both"
            tmpAnnotStyle = 3
        endif

        # Regression defaults (1=None, 2=Line, 3=Formula, 4=Both)
        #
        # D103. Preset first, remembered value second. The restore below used
        # to run unconditionally and therefore ran AFTER the preset bridge had
        # already set scatterRegressionLine / scatterShowFormula, so the second
        # and every later scatter of a session threw the calling wrapper's
        # preset away and re-used the last dialog's choice instead. The
        # sentinel is consumed here, so a Redraw goes back to the remembered
        # value — which is what the user last chose in this very dialog.
        if scatterPresetHasRegression
            scatterPresetHasRegression = 0
        else
            if prev_scatterRegressionLine >= 0
                scatterRegressionLine = prev_scatterRegressionLine
            endif
            if prev_scatterShowFormula >= 0
                scatterShowFormula = prev_scatterShowFormula
            endif
        endif
        if scatterRegressionLine = 1 and scatterShowFormula = 1
            tmpRegression = 4
        elsif scatterShowFormula = 1
            tmpRegression = 3
        elsif scatterRegressionLine = 1
            tmpRegression = 2
        else
            tmpRegression = 1
        endif

        # Scatter-specific controls — same preset-beats-remembered rule (D103)
        if scatterPresetHasDotSize
            scatterPresetHasDotSize = 0
        elsif prev_scatterDotSize > 0
            scatterDotSize = prev_scatterDotSize
        endif
        tmpDotSize = scatterDotSize
        if scatterPresetHasDots
            scatterPresetHasDots = 0
        elsif prev_scatterShowDots >= 0
            scatterShowDots = prev_scatterShowDots
        endif
        tmpShowDots = scatterShowDots

        # Use group column persistence
        tmpUseGroup = 0
        if scatterPresetHasGroup
            tmpUseGroup = 1
            scatterPresetHasGroup = 0
        elsif prev_scatterUseGroup >= 0
            tmpUseGroup = prev_scatterUseGroup
        endif

        scatterFormDone = 0
        repeat
            if config_showAdvanced
                scatterToggleLabel$ = "Beginner"
            else
                scatterToggleLabel$ = "Advanced"
            endif

            beginPause: "Scatter Plot -- Column Mapping"
                comment: "📋 Select columns from your Table."
                optionmenu: "X column", scatterXIdx
                    for iCol from 1 to nCols
                        option: colName$[iCol]
                    endfor
                optionmenu: "Y column", scatterYIdx
                    for iCol from 1 to nCols
                        option: colName$[iCol]
                    endfor
                boolean: "Use group column", tmpUseGroup
                optionmenu: "Group column", scatterGroupIdx
                    for iCol from 1 to nCols
                        option: colName$[iCol]
                    endfor
                optionmenu: "Group order", prev_groupSort
                    option: "Table order"
                    option: "Alphabetical"
                if config_showAdvanced
                    comment: "─────────────────────────────────────"
                    comment: "📊 Analysis"
                    optionmenu: "Correlation method", tmpCorrType
                        option: "None"
                        option: "Pearson"
                        option: "Spearman"
                        option: "Both"
                    optionmenu: "Regression", tmpRegression
                        option: "None"
                        option: "Regression line"
                        option: "Formula"
                        option: "Both"
                    optionmenu: "Significance style", tmpAnnotStyle
                        option: "p-value"
                        option: "stars"
                        option: "both"
                    boolean: "Show data points", tmpShowDots
                    optionmenu: "Dot size", tmpDotSize
                        option: "Small"
                        option: "Medium"
                        option: "Large"
                    comment: "📐 Axis ranges (both 0 = auto)"
                    real: "X maximum", tmpXMax$
                    real: "X minimum", tmpXMin$
                    real: "Y maximum", tmpYMax$
                    real: "Y minimum", tmpYMin$
                    comment: "─────────────────────────────────────"
                    comment: "🎨 Layout"
                    optionmenu: "Gridline mode", tmpGridMode
                        option: "Both"
                        option: "Horizontal only"
                        option: "Vertical only"
                        option: "Off"
                    optionmenu: "Output DPI", tmpDPI
                        option: "300 dpi"
                        option: "600 dpi"
                    boolean: "Show inner box", tmpShowInnerBox
                    optionmenu: "Show axis names", tmpShowAxisNames
                        option: "None"
                        option: "Both"
                        option: "X only"
                        option: "Y only"
                    optionmenu: "Show ticks", tmpShowTicks
                        option: "None"
                        option: "Both"
                        option: "X only"
                        option: "Y only"
                    optionmenu: "Show axis values", tmpShowAxisValues
                        option: "None"
                        option: "Both"
                        option: "X only"
                        option: "Y only"
                    optionmenu: "Font", tmpFont
                        option: "Helvetica"
                        option: "Times"
                        option: "Palatino"
                        option: "Courier"
                    comment: "🏷️ Axis labels (blank = auto from column)"
                    comment: "Formatting: %italic · #bold · ^super · underscore = subscript · \% plus a space prints %"
                    sentence: "X axis label", tmpXLabel$
                    sentence: "Y axis label", tmpYLabel$
                endif
            clicked = endPause: "Go Back", "Quit", scatterToggleLabel$, "Draw", 4, 1

            if clicked = 1
                scatterFormDone = 1
            elsif clicked = 2
                @emlSaveConfig
                exitScript: ""
            elsif clicked = 3
                scatterXIdx = x_column
                scatterYIdx = y_column
                scatterGroupIdx = group_column
                prev_groupSort = group_order
                config_groupSort = group_order
                tmpUseGroup = use_group_column
                if config_showAdvanced
                    # Toggling TO beginner: save advanced state
                    prev_adv_sca_corrType = correlation_method
                    prev_adv_sca_annotStyle = significance_style
                    prev_adv_sca_regressionLine = regression
                    prev_adv_sca_showDots = show_data_points
                    prev_adv_sca_dotSize = dot_size
                    prev_adv_sca_XMin$ = string$ (x_minimum)
                    prev_adv_sca_XMax$ = string$ (x_maximum)
                    prev_adv_sca_YMin$ = string$ (y_minimum)
                    prev_adv_sca_YMax$ = string$ (y_maximum)
                    prev_adv_sca_gridMode = gridline_mode
                    prev_adv_sca_showInnerBox = show_inner_box
                    prev_adv_sca_showAxisNames = show_axis_names
                    prev_adv_sca_showTicks = show_ticks
                    prev_adv_sca_showAxisValues = show_axis_values
                    prev_adv_sca_font = font
                    prev_adv_sca_DPI = output_DPI
                    prev_adv_sca_XLabel$ = x_axis_label$
                    prev_adv_sca_YLabel$ = y_axis_label$
                    # Reset to beginner defaults
                    tmpCorrType = 1
                    tmpRegression = 1
                    tmpAnnotStyle = 1
                    tmpShowDots = 1
                    tmpDotSize = 2
                    tmpXMin$ = "0"
                    tmpXMax$ = "0"
                    tmpYMin$ = "0"
                    tmpYMax$ = "0"
                    tmpGridMode = config_gridlineMode
                    tmpShowInnerBox = config_showInnerBox
                    tmpShowAxisNames = config_showAxisNames
                    tmpShowTicks = config_showTicks
                    tmpShowAxisValues = config_showAxisValues
                    tmpFont = config_font
                    tmpDPI = config_outputDPI
                    tmpXLabel$ = ""
                    tmpYLabel$ = ""
                else
                    # Toggling TO advanced: restore saved state
                    if variableExists ("prev_adv_sca_corrType")
                        tmpCorrType = prev_adv_sca_corrType
                        tmpAnnotStyle = prev_adv_sca_annotStyle
                        tmpRegression = prev_adv_sca_regressionLine
                        tmpShowDots = prev_adv_sca_showDots
                        tmpDotSize = prev_adv_sca_dotSize
                        tmpXMin$ = prev_adv_sca_XMin$
                        tmpXMax$ = prev_adv_sca_XMax$
                        tmpYMin$ = prev_adv_sca_YMin$
                        tmpYMax$ = prev_adv_sca_YMax$
                        tmpGridMode = prev_adv_sca_gridMode
                        tmpShowInnerBox = prev_adv_sca_showInnerBox
                        tmpShowAxisNames = prev_adv_sca_showAxisNames
                        tmpShowTicks = prev_adv_sca_showTicks
                        tmpShowAxisValues = prev_adv_sca_showAxisValues
                        tmpFont = prev_adv_sca_font
                        tmpDPI = prev_adv_sca_DPI
                        tmpXLabel$ = prev_adv_sca_XLabel$
                        tmpYLabel$ = prev_adv_sca_YLabel$
                    endif
                endif
                config_showAdvanced = 1 - config_showAdvanced
            else
                scatterFormDone = 1
                allFormsDone = 1

                if config_showAdvanced
                    tmpXMin$ = string$ (x_minimum)
                    tmpXMax$ = string$ (x_maximum)
                    tmpYMin$ = string$ (y_minimum)
                    tmpYMax$ = string$ (y_maximum)
                    tmpGridMode = gridline_mode
                    tmpShowInnerBox = show_inner_box
                    tmpShowAxisNames = show_axis_names
                    tmpShowTicks = show_ticks
                    tmpShowAxisValues = show_axis_values
                    tmpFont = font
                    tmpDPI = output_DPI
                    tmpXLabel$ = x_axis_label$
                    tmpYLabel$ = y_axis_label$
                    config_gridlineMode = gridline_mode
                    emlShowInnerBox = show_inner_box
                    emlFont$ = font$
                    config_showInnerBox = show_inner_box
                    config_showAxisNames = show_axis_names
                    config_showTicks = show_ticks
                    config_showAxisValues = show_axis_values
                    @emlExpandAxisControls
                    config_font$ = font$
                    config_font = font
                    config_outputDPI = output_DPI
                    # Derive analysis type from correlation + regression choices
                    # correlation_method: 1=None, 2=Pearson, 3=Spearman, 4=Both
                    # regression: 1=None, 2=Line, 3=Formula, 4=Both
                    if correlation_method > 1 and regression > 1
                        scatterAnalysisType = 3
                        annotate = 1
                    elsif correlation_method > 1
                        scatterAnalysisType = 1
                        annotate = 1
                    elsif regression > 1
                        scatterAnalysisType = 2
                        annotate = 1
                    else
                        scatterAnalysisType = 0
                        annotate = 0
                    endif
                    # Correlation type
                    if correlation_method = 4
                        annotCorrType$ = "both"
                    elsif correlation_method = 3
                        annotCorrType$ = "spearman"
                    elsif correlation_method = 2
                        annotCorrType$ = "pearson"
                    else
                        annotCorrType$ = ""
                    endif
                    # Regression line and formula
                    if regression = 2 or regression = 4
                        scatterRegressionLine = 1
                    else
                        scatterRegressionLine = 0
                    endif
                    if regression = 3 or regression = 4
                        scatterShowFormula = 1
                    else
                        scatterShowFormula = 0
                    endif
                    if significance_style = 2
                        annotStyle$ = "stars"
                    elsif significance_style = 3
                        annotStyle$ = "both"
                    else
                        annotStyle$ = "p-value"
                    endif
                    scatterShowDots = show_data_points
                    scatterDotSize = dot_size
                else
                    # Beginner defaults: no annotation, reset all advanced-only fields
                    annotate = 0
                    scatterAnalysisType = 0
                    annotCorrType$ = "pearson"
                    annotStyle$ = "p-value"
                    scatterRegressionLine = 0
                    scatterShowFormula = 0
                    scatterShowDots = 1
                    scatterDotSize = 2
                endif
                gridline_mode = tmpGridMode
                output_DPI = tmpDPI

                # Persist scatter-specific controls
                prev_scatterDotSize = scatterDotSize
                prev_scatterRegressionLine = scatterRegressionLine
                prev_scatterShowFormula = scatterShowFormula
                prev_scatterShowDots = scatterShowDots
                prev_scatterUseGroup = use_group_column

                scatterXCol$ = x_column$
                scatterYCol$ = y_column$
                if use_group_column = 1
                    scatterGroupCol$ = group_column$
                else
                    scatterGroupCol$ = ""
                endif

                prev_scatterXIdx = x_column
                prev_scatterYIdx = y_column
                prev_scatterGroupIdx = group_column
                prev_groupSort = group_order
                config_groupSort = group_order

                valueMin = number (tmpYMin$)
                valueMax = number (tmpYMax$)
                scatterXMin = number (tmpXMin$)
                scatterXMax = number (tmpXMax$)
                prev_scatter_xMin = scatterXMin
                prev_scatter_xMax = scatterXMax
                prev_scatter_yMin = valueMin
                prev_scatter_yMax = valueMax

                x_axis_label$ = tmpXLabel$
                y_axis_label$ = tmpYLabel$
                if x_axis_label$ = ""
                    @emlCapitalizeLabel: scatterXCol$
                    x_axis_label$ = emlCapitalizeLabel.result$
                endif
                if y_axis_label$ = ""
                    @emlCapitalizeLabel: scatterYCol$
                    y_axis_label$ = emlCapitalizeLabel.result$
                endif

                # Validate numeric columns
                @emlCheckNumericColumn: objectId, scatterXCol$
                if emlCheckNumericColumn.isNumeric = 0
                    beginPause: "Column Error"
                        comment: """" + scatterXCol$ + """ does not contain numeric data."
                        comment: "Please select numeric columns for X and Y axes."
                    endPause: "OK", 1, 0
                    scatterFormDone = 0
                    allFormsDone = 0
                else
                    @emlCheckNumericColumn: objectId, scatterYCol$
                    if emlCheckNumericColumn.isNumeric = 0
                        beginPause: "Column Error"
                            comment: """" + scatterYCol$ + """ does not contain numeric data."
                            comment: "Please select numeric columns for X and Y axes."
                        endPause: "OK", 1, 0
                        scatterFormDone = 0
                        allFormsDone = 0
                    endif
                endif
            endif
        until scatterFormDone = 1

    elsif graph_type = 9
        # =============================================================
        # Box Plot — Page 2 (column mapping)
        # =============================================================

        boxGroupIdx = 1
        boxValueIdx = min (2, nCols)

        if emlGraphsPresetGroupCol$ <> ""
            for .iPreset from 1 to nCols
                if colName$[.iPreset] = emlGraphsPresetGroupCol$
                    boxGroupIdx = .iPreset
                endif
                if colName$[.iPreset] = emlGraphsPresetDataCol$
                    boxValueIdx = .iPreset
                endif
            endfor
            # Consumed — clear so Redraw uses prev_* persistence
            emlGraphsPresetGroupCol$ = ""
            emlGraphsPresetDataCol$ = ""
        elsif prev_boxGroupIdx > 0
            boxGroupIdx = prev_boxGroupIdx
            boxValueIdx = prev_boxValueIdx
        else
            # Column-role defaults come from @emlGuessColumnRoles, the same
            # weighted guesser the wizard and every stats wrapper already use.
            # This site used to carry its own three-keyword copy of it; see the
            # note at the top of this file. Only non-zero guesses overwrite the
            # positional defaults set above, so an undetected role still falls
            # back exactly as before.
            @emlGuessColumnRoles: objectId
            if emlGuessColumnRoles.groupIdx > 0
                boxGroupIdx = emlGuessColumnRoles.groupIdx
            endif
            if emlGuessColumnRoles.dataIdx > 0
                boxValueIdx = emlGuessColumnRoles.dataIdx
            endif
            @emlCheckNumericColumn: objectId, colName$[boxValueIdx]
            if emlCheckNumericColumn.isNumeric = 0
                boxValueIdx = 0
                for iCol from 1 to nCols
                    if boxValueIdx = 0 and iCol <> boxGroupIdx
                        @emlCheckNumericColumn: objectId, colName$[iCol]
                        if emlCheckNumericColumn.isNumeric = 1
                            boxValueIdx = iCol
                        endif
                    endif
                endfor
                if boxValueIdx = 0
                    boxValueIdx = min (2, nCols)
                endif
            endif
        endif

        if lastDrawnGraphType = 9
            tmpVMin$ = string$ (prev_box_valueMin)
            tmpVMax$ = string$ (prev_box_valueMax)
        else
            tmpVMin$ = "0"
            tmpVMax$ = "0"
        endif
        if config_gridlineMode = 2
            tmpGridMode = 2
        else
            tmpGridMode = 1
        endif
        tmpDPI = config_outputDPI
        tmpXLabel$ = ""
        tmpYLabel$ = ""
        tmpBoxTestType = 1
        if annotTestType$ = "nonparametric"
            tmpBoxTestType = 2
        endif
        tmpBoxAnnotStyle = 1
        if annotStyle$ = "stars"
            tmpBoxAnnotStyle = 2
        elsif annotStyle$ = "both"
            tmpBoxAnnotStyle = 3
        endif

        boxFormDone = 0
        repeat
            if config_showAdvanced
                boxToggleLabel$ = "Beginner"
            else
                boxToggleLabel$ = "Advanced"
            endif

            beginPause: "Box Plot -- Column Mapping"
                comment: "📋 Select columns from your Table."
                optionmenu: "Value column", boxValueIdx
                    for iCol from 1 to nCols
                        option: colName$[iCol]
                    endfor
                optionmenu: "Group column", boxGroupIdx
                    for iCol from 1 to nCols
                        option: colName$[iCol]
                    endfor
                optionmenu: "Group order", prev_groupSort
                    option: "Table order"
                    option: "Alphabetical"
                if config_showAdvanced
                    boolean: "Annotate results on graph", annotate
                    optionmenu: "Test type", tmpBoxTestType
                        option: "Parametric"
                        option: "Nonparametric"
                    optionmenu: "Adjustment method (nonparametric post-hoc only)", prev_annotAdjustIdx
                        option: "Bonferroni"
                        option: "Holm"
                        option: "Benjamini-Hochberg"
                    optionmenu: "Significance style", tmpBoxAnnotStyle
                        option: "p-value"
                        option: "stars"
                        option: "both"
                    boolean: "Show nonsignificant", annotShowNS
                    boolean: "Show effect sizes", annotShowEffect
                    optionmenu: "Annotation layout", annotLayoutMode
                        option: "Auto"
                        option: "Annotate"
                        option: "Matrix"
                    real: "Alpha", string$ (annotAlpha)
                    boolean: "Show jittered points", prev_boxShowJitter
                    comment: "📐 Y-axis range (both 0 = auto)"
                    real: "Value maximum", tmpVMax$
                    real: "Value minimum", tmpVMin$
                    optionmenu: "Gridline mode", tmpGridMode
                        option: "Horizontal"
                        option: "Off"
                    optionmenu: "Output DPI", tmpDPI
                        option: "300 dpi"
                        option: "600 dpi"
                    boolean: "Show inner box", tmpShowInnerBox
                    optionmenu: "Show axis names", tmpShowAxisNames
                        option: "None"
                        option: "Both"
                        option: "X only"
                        option: "Y only"
                    optionmenu: "Show ticks", tmpShowTicks
                        option: "None"
                        option: "Both"
                        option: "X only"
                        option: "Y only"
                    optionmenu: "Show axis values", tmpShowAxisValues
                        option: "None"
                        option: "Both"
                        option: "X only"
                        option: "Y only"
                    optionmenu: "Font", tmpFont
                        option: "Helvetica"
                        option: "Times"
                        option: "Palatino"
                        option: "Courier"
                    comment: "🏷️ Axis labels (blank = auto from column)"
                    comment: "Formatting: %italic · #bold · ^super · underscore = subscript · \% plus a space prints %"
                    sentence: "X axis label", tmpXLabel$
                    sentence: "Y axis label", tmpYLabel$
                endif
            clicked = endPause: "Go Back", "Quit", boxToggleLabel$, "Draw", 4, 1

            if clicked = 1
                boxFormDone = 1
            elsif clicked = 2
                @emlSaveConfig
                exitScript: ""
            elsif clicked = 3
                boxGroupIdx = group_column
                prev_groupSort = group_order
                config_groupSort = group_order
                boxValueIdx = value_column
                if config_showAdvanced
                    # Toggling TO beginner: save advanced state
                    prev_adv_box_annotate = annotate_results_on_graph
                    prev_adv_box_annotShowNS = show_nonsignificant
                    prev_adv_box_annotShowEffect = show_effect_sizes
                    prev_adv_box_annotAlpha = alpha
                    prev_adv_box_annotLayoutMode = annotation_layout
                    prev_adv_box_testType = test_type
                    prev_adv_box_annotStyle = significance_style
                    prev_annotAdjustIdx = adjustment_method
                    prev_adv_box_showJitter = show_jittered_points
                    prev_adv_box_VMin$ = string$ (value_minimum)
                    prev_adv_box_VMax$ = string$ (value_maximum)
                    prev_adv_box_gridMode = gridline_mode
                    prev_adv_box_showInnerBox = show_inner_box
                    prev_adv_box_showAxisNames = show_axis_names
                    prev_adv_box_showTicks = show_ticks
                    prev_adv_box_showAxisValues = show_axis_values
                    prev_adv_box_font = font
                    prev_adv_box_DPI = output_DPI
                    prev_adv_box_XLabel$ = x_axis_label$
                    prev_adv_box_YLabel$ = y_axis_label$
                    # Reset to beginner defaults
                    annotate = 0
                    annotShowNS = 0
                    annotShowEffect = 0
                    annotLayoutMode = 1
                    prev_boxShowJitter = 0
                    tmpBoxTestType = 1
                    tmpBoxAnnotStyle = 1
                    tmpVMin$ = "0"
                    tmpVMax$ = "0"
                    tmpGridMode = config_gridlineMode
                    tmpShowInnerBox = config_showInnerBox
                    tmpShowAxisNames = config_showAxisNames
                    tmpShowTicks = config_showTicks
                    tmpShowAxisValues = config_showAxisValues
                    tmpFont = config_font
                    tmpDPI = config_outputDPI
                    tmpXLabel$ = ""
                    tmpYLabel$ = ""
                else
                    # Toggling TO advanced: restore saved state
                    if variableExists ("prev_adv_box_annotate")
                        annotate = prev_adv_box_annotate
                        annotShowNS = prev_adv_box_annotShowNS
                        annotShowEffect = prev_adv_box_annotShowEffect
                        annotAlpha = prev_adv_box_annotAlpha
                        annotLayoutMode = prev_adv_box_annotLayoutMode
                        tmpBoxTestType = prev_adv_box_testType
                        tmpBoxAnnotStyle = prev_adv_box_annotStyle
                        prev_boxShowJitter = prev_adv_box_showJitter
                        tmpVMin$ = prev_adv_box_VMin$
                        tmpVMax$ = prev_adv_box_VMax$
                        tmpGridMode = prev_adv_box_gridMode
                        tmpShowInnerBox = prev_adv_box_showInnerBox
                        tmpShowAxisNames = prev_adv_box_showAxisNames
                        tmpShowTicks = prev_adv_box_showTicks
                        tmpShowAxisValues = prev_adv_box_showAxisValues
                        tmpFont = prev_adv_box_font
                        tmpDPI = prev_adv_box_DPI
                        tmpXLabel$ = prev_adv_box_XLabel$
                        tmpYLabel$ = prev_adv_box_YLabel$
                    endif
                endif
                config_showAdvanced = 1 - config_showAdvanced
            else
                boxFormDone = 1
                allFormsDone = 1

                if config_showAdvanced
                    tmpVMin$ = string$ (value_minimum)
                    tmpVMax$ = string$ (value_maximum)
                    tmpGridMode = gridline_mode
                    tmpShowInnerBox = show_inner_box
                    tmpShowAxisNames = show_axis_names
                    tmpShowTicks = show_ticks
                    tmpShowAxisValues = show_axis_values
                    tmpFont = font
                    tmpDPI = output_DPI
                    tmpXLabel$ = x_axis_label$
                    tmpYLabel$ = y_axis_label$
                    config_gridlineMode = gridline_mode
                    emlShowInnerBox = show_inner_box
                    emlFont$ = font$
                    config_showInnerBox = show_inner_box
                    config_showAxisNames = show_axis_names
                    config_showTicks = show_ticks
                    config_showAxisValues = show_axis_values
                    @emlExpandAxisControls
                    config_font$ = font$
                    config_font = font
                    config_outputDPI = output_DPI
                    annotate = annotate_results_on_graph
                    annotShowNS = show_nonsignificant
                    annotShowEffect = show_effect_sizes
                    annotAlpha = alpha
                    annotLayoutMode = annotation_layout
                    prev_boxShowJitter = show_jittered_points
                    @emlAdjustMethodName: adjustment_method
                    annotCorrectionMethod$ = emlAdjustMethodName.name$
                    prev_annotAdjustIdx = adjustment_method
                    if test_type = 2
                        annotTestType$ = "nonparametric"
                    else
                        annotTestType$ = "parametric"
                    endif
                    if significance_style = 2
                        annotStyle$ = "stars"
                    elsif significance_style = 3
                        annotStyle$ = "both"
                    else
                        annotStyle$ = "p-value"
                    endif
                else
                    annotate = 0
                    annotShowNS = 0
                    annotShowEffect = 0
                    annotLayoutMode = 1
                    prev_boxShowJitter = 0
                    # annotTestType$ preserved — only meaningful when annotate=1
                    # annotStyle$ preserved — only meaningful when annotate=1
                endif
                gridline_mode = tmpGridMode
                output_DPI = tmpDPI

                groupColName$ = group_column$
                valueColName$ = value_column$

                prev_boxGroupIdx = group_column
                prev_groupSort = group_order
                config_groupSort = group_order
                prev_boxValueIdx = value_column

                valueMin = number (tmpVMin$)
                valueMax = number (tmpVMax$)
                prev_box_valueMin = valueMin
                prev_box_valueMax = valueMax

                x_axis_label$ = tmpXLabel$
                y_axis_label$ = tmpYLabel$
                if x_axis_label$ = ""
                    @emlCapitalizeLabel: groupColName$
                    x_axis_label$ = emlCapitalizeLabel.result$
                endif
                if y_axis_label$ = ""
                    @emlCapitalizeLabel: valueColName$
                    y_axis_label$ = emlCapitalizeLabel.result$
                endif

                @emlCheckNumericColumn: objectId, valueColName$
                if emlCheckNumericColumn.isNumeric = 0
                    beginPause: "Column Error"
                        comment: """" + valueColName$ + """ does not contain numeric data."
                        comment: "Please select a numeric column for the value axis."
                    endPause: "OK", 1, 0
                    boxFormDone = 0
                    allFormsDone = 0
                endif
            endif
        until boxFormDone = 1

    elsif graph_type = 10
        # =============================================================
        # Histogram — Page 2 (column mapping)
        # =============================================================

        histValueIdx = 1
        histGroupIdx = 1

        if emlGraphsPresetGroupCol$ <> ""
            for .iPreset from 1 to nCols
                if colName$[.iPreset] = emlGraphsPresetGroupCol$
                    histGroupIdx = .iPreset
                    # The caller supplied a group column, so the dialog must
                    # open with "Use group column" already checked. Without
                    # this the index is seeded but the box stays clear,
                    # histGroupCol$ commits as "", and the grouped-histogram
                    # annotation route is silently skipped.
                    histPresetHasGroup = 1
                endif
                if colName$[.iPreset] = emlGraphsPresetDataCol$
                    histValueIdx = .iPreset
                endif
            endfor
            # Consumed — clear so Redraw uses prev_* persistence
            emlGraphsPresetGroupCol$ = ""
            emlGraphsPresetDataCol$ = ""
        elsif prev_histValueIdx > 0
            histValueIdx = prev_histValueIdx
            histGroupIdx = prev_histGroupIdx
        else
            # Column-role defaults come from @emlGuessColumnRoles, the same
            # weighted guesser the wizard and every stats wrapper already use.
            # This site used to carry its own three-keyword copy of it; see the
            # note at the top of this file. Only non-zero guesses overwrite the
            # positional defaults set above, so an undetected role still falls
            # back exactly as before.
            @emlGuessColumnRoles: objectId
            if emlGuessColumnRoles.dataIdx > 0
                histValueIdx = emlGuessColumnRoles.dataIdx
            endif
            if emlGuessColumnRoles.groupIdx > 0
                histGroupIdx = emlGuessColumnRoles.groupIdx
            endif
            @emlCheckNumericColumn: objectId, colName$[histValueIdx]
            if emlCheckNumericColumn.isNumeric = 0
                histValueIdx = 0
                for iCol from 1 to nCols
                    if histValueIdx = 0
                        @emlCheckNumericColumn: objectId, colName$[iCol]
                        if emlCheckNumericColumn.isNumeric = 1
                            histValueIdx = iCol
                        endif
                    endif
                endfor
                if histValueIdx = 0
                    histValueIdx = 1
                endif
            endif
        endif

        if lastDrawnGraphType = 10
            tmpVMin$ = string$ (prev_hist_valueMin)
            tmpVMax$ = string$ (prev_hist_valueMax)
            tmpFreqMax$ = string$ (prev_hist_freqMax)
        else
            tmpVMin$ = "0"
            tmpVMax$ = "0"
            tmpFreqMax$ = "0"
        endif
        tmpXLabel$ = ""
        tmpYLabel$ = ""
        tmpBinCount = prev_histBinCount
        tmpDisplayMode = prev_histDisplayMode
        if tmpDisplayMode < 1
            tmpDisplayMode = 1
        endif
        tmpUseGroup = 0
        if histPresetHasGroup
            tmpUseGroup = 1
            histPresetHasGroup = 0
        elsif prev_histUseGroup >= 0
            tmpUseGroup = prev_histUseGroup
        endif

        histFormDone = 0
        repeat
            if config_showAdvanced
                histToggleLabel$ = "Beginner"
            else
                histToggleLabel$ = "Advanced"
            endif

            beginPause: "Histogram -- Column Mapping"
                comment: "📋 Select columns from your Table."
                optionmenu: "Value column", histValueIdx
                    for iCol from 1 to nCols
                        option: colName$[iCol]
                    endfor
                boolean: "Use group column", tmpUseGroup
                optionmenu: "Group column", histGroupIdx
                    for iCol from 1 to nCols
                        option: colName$[iCol]
                    endfor
                optionmenu: "Group order", prev_groupSort
                    option: "Table order"
                    option: "Alphabetical"
                if config_showAdvanced
                    comment: "📊 Binning"
                    integer: "Bin count (0 = auto)", string$ (tmpBinCount)
                    comment: "📊 Grouped display"
                    optionmenu: "Display mode", tmpDisplayMode
                        option: "Overlap (transparent)"
                        option: "Faceted (stacked panels)"
                    boolean: "Annotate results on graph", annotate
                    optionmenu: "Test type", prev_histAnnotTestType
                        option: "Parametric"
                        option: "Nonparametric"
                    optionmenu: "Adjustment method (nonparametric post-hoc only)", prev_annotAdjustIdx
                        option: "Bonferroni"
                        option: "Holm"
                        option: "Benjamini-Hochberg"
                    optionmenu: "Significance style", prev_histAnnotStyle
                        option: "p-value"
                        option: "stars"
                        option: "both"
                    boolean: "Show nonsignificant", annotShowNS
                    boolean: "Show effect sizes", annotShowEffect
                    real: "Alpha", string$ (annotAlpha)
                    comment: "📐 Axis ranges (both 0 = auto)"
                    real: "Value maximum", tmpVMax$
                    real: "Value minimum", tmpVMin$
                    real: "Frequency maximum (0 = auto)", tmpFreqMax$
                    optionmenu: "Gridline mode", tmpGridMode
                        option: "Horizontal"
                        option: "Off"
                    optionmenu: "Output DPI", tmpDPI
                        option: "300 dpi"
                        option: "600 dpi"
                    boolean: "Show inner box", tmpShowInnerBox
                    optionmenu: "Show axis names", tmpShowAxisNames
                        option: "None"
                        option: "Both"
                        option: "X only"
                        option: "Y only"
                    optionmenu: "Show ticks", tmpShowTicks
                        option: "None"
                        option: "Both"
                        option: "X only"
                        option: "Y only"
                    optionmenu: "Show axis values", tmpShowAxisValues
                        option: "None"
                        option: "Both"
                        option: "X only"
                        option: "Y only"
                    optionmenu: "Font", tmpFont
                        option: "Helvetica"
                        option: "Times"
                        option: "Palatino"
                        option: "Courier"
                    comment: "🏷️ Axis labels (blank = auto from column)"
                    comment: "Formatting: %italic · #bold · ^super · underscore = subscript · \% plus a space prints %"
                    sentence: "X axis label", tmpXLabel$
                    sentence: "Y axis label", tmpYLabel$
                endif
            clicked = endPause: "Go Back", "Quit", histToggleLabel$, "Draw", 4, 1

            if clicked = 1
                histFormDone = 1
            elsif clicked = 2
                @emlSaveConfig
                exitScript: ""
            elsif clicked = 3
                histValueIdx = value_column
                histGroupIdx = group_column
                prev_groupSort = group_order
                config_groupSort = group_order
                tmpUseGroup = use_group_column
                if config_showAdvanced
                    # Toggling TO beginner: save advanced state
                    prev_adv_his_binCount = bin_count
                    prev_adv_his_displayMode = display_mode
                    prev_adv_his_annotate = annotate_results_on_graph
                    prev_adv_his_annotShowNS = show_nonsignificant
                    prev_adv_his_annotShowEffect = show_effect_sizes
                    prev_adv_his_annotAlpha = alpha
                    prev_adv_his_testType = test_type
                    prev_adv_his_annotStyle = significance_style
                    prev_annotAdjustIdx = adjustment_method
                    prev_adv_his_VMin$ = string$ (value_minimum)
                    prev_adv_his_VMax$ = string$ (value_maximum)
                    prev_adv_his_freqMax$ = string$ (frequency_maximum)
                    prev_adv_his_gridMode = gridline_mode
                    prev_adv_his_showInnerBox = show_inner_box
                    prev_adv_his_showAxisNames = show_axis_names
                    prev_adv_his_showTicks = show_ticks
                    prev_adv_his_showAxisValues = show_axis_values
                    prev_adv_his_font = font
                    prev_adv_his_DPI = output_DPI
                    prev_adv_his_XLabel$ = x_axis_label$
                    prev_adv_his_YLabel$ = y_axis_label$
                    # Reset to beginner defaults
                    tmpBinCount = 0
                    tmpDisplayMode = 1
                    tmpVMin$ = "0"
                    tmpVMax$ = "0"
                    tmpFreqMax$ = "0"
                    tmpGridMode = config_gridlineMode
                    tmpShowInnerBox = config_showInnerBox
                    tmpShowAxisNames = config_showAxisNames
                    tmpShowTicks = config_showTicks
                    tmpShowAxisValues = config_showAxisValues
                    tmpFont = config_font
                    tmpDPI = config_outputDPI
                    tmpXLabel$ = ""
                    tmpYLabel$ = ""
                    annotate = 0
                    annotShowNS = 0
                    annotShowEffect = 0
                    annotLayoutMode = 3
                    prev_histAnnotTestType = 1
                    prev_histAnnotStyle = 1
                else
                    # Toggling TO advanced: restore saved state
                    if variableExists ("prev_adv_his_annotate")
                        tmpBinCount = prev_adv_his_binCount
                        tmpDisplayMode = prev_adv_his_displayMode
                        annotate = prev_adv_his_annotate
                        annotShowNS = prev_adv_his_annotShowNS
                        annotShowEffect = prev_adv_his_annotShowEffect
                        annotAlpha = prev_adv_his_annotAlpha
                        prev_histAnnotTestType = prev_adv_his_testType
                        prev_histAnnotStyle = prev_adv_his_annotStyle
                        tmpVMin$ = prev_adv_his_VMin$
                        tmpVMax$ = prev_adv_his_VMax$
                        tmpFreqMax$ = prev_adv_his_freqMax$
                        tmpGridMode = prev_adv_his_gridMode
                        tmpShowInnerBox = prev_adv_his_showInnerBox
                        tmpShowAxisNames = prev_adv_his_showAxisNames
                        tmpShowTicks = prev_adv_his_showTicks
                        tmpShowAxisValues = prev_adv_his_showAxisValues
                        tmpFont = prev_adv_his_font
                        tmpDPI = prev_adv_his_DPI
                        tmpXLabel$ = prev_adv_his_XLabel$
                        tmpYLabel$ = prev_adv_his_YLabel$
                    endif
                endif
                config_showAdvanced = 1 - config_showAdvanced
            else
                histFormDone = 1
                allFormsDone = 1

                histValueCol$ = value_column$
                if use_group_column = 1
                    histGroupCol$ = group_column$
                else
                    histGroupCol$ = ""
                endif

                if config_showAdvanced
                    histBinCount = bin_count
                    histDisplayMode = display_mode
                    tmpVMin$ = string$ (value_minimum)
                    tmpVMax$ = string$ (value_maximum)
                    tmpFreqMax$ = string$ (frequency_maximum)
                    tmpGridMode = gridline_mode
                    tmpShowInnerBox = show_inner_box
                    tmpShowAxisNames = show_axis_names
                    tmpShowTicks = show_ticks
                    tmpShowAxisValues = show_axis_values
                    tmpFont = font
                    tmpDPI = output_DPI
                    tmpXLabel$ = x_axis_label$
                    tmpYLabel$ = y_axis_label$
                    config_gridlineMode = gridline_mode
                    emlShowInnerBox = show_inner_box
                    emlFont$ = font$
                    config_showInnerBox = show_inner_box
                    config_showAxisNames = show_axis_names
                    config_showTicks = show_ticks
                    config_showAxisValues = show_axis_values
                    @emlExpandAxisControls
                    config_font$ = font$
                    config_font = font
                    config_outputDPI = output_DPI
                    annotate = annotate_results_on_graph
                    annotShowNS = show_nonsignificant
                    annotShowEffect = show_effect_sizes
                    annotAlpha = alpha
                    annotLayoutMode = 3
                    prev_histAnnotTestType = test_type
                    prev_histAnnotStyle = significance_style
                    @emlAdjustMethodName: adjustment_method
                    annotCorrectionMethod$ = emlAdjustMethodName.name$
                    prev_annotAdjustIdx = adjustment_method
                    if test_type = 2
                        annotTestType$ = "nonparametric"
                    else
                        annotTestType$ = "parametric"
                    endif
                    if significance_style = 2
                        annotStyle$ = "stars"
                    elsif significance_style = 3
                        annotStyle$ = "both"
                    else
                        annotStyle$ = "p-value"
                    endif
                else
                    histBinCount = 0
                    histDisplayMode = 1
                    annotate = 0
                    annotShowNS = 0
                    annotShowEffect = 0
                    annotLayoutMode = 3
                endif
                gridline_mode = tmpGridMode
                output_DPI = tmpDPI

                # Guard: negative bin count
                if histBinCount < 0
                    histBinCount = 0
                endif

                prev_histValueIdx = value_column
                prev_histGroupIdx = group_column
                prev_groupSort = group_order
                config_groupSort = group_order
                prev_histUseGroup = use_group_column
                prev_histBinCount = histBinCount
                prev_histDisplayMode = histDisplayMode

                valueMin = number (tmpVMin$)
                valueMax = number (tmpVMax$)
                histFreqMax = number (tmpFreqMax$)
                prev_hist_valueMin = valueMin
                prev_hist_valueMax = valueMax
                prev_hist_freqMax = histFreqMax

                x_axis_label$ = tmpXLabel$
                y_axis_label$ = tmpYLabel$
                if x_axis_label$ = ""
                    @emlCapitalizeLabel: histValueCol$
                    x_axis_label$ = emlCapitalizeLabel.result$
                endif
                if y_axis_label$ = ""
                    # Faceted with groups: group names serve as per-panel
                    # labels, so "Frequency" is superfluous. Leave blank.
                    if histDisplayMode <> 2 or histGroupCol$ = ""
                        y_axis_label$ = "Frequency"
                    endif
                endif

                @emlCheckNumericColumn: objectId, histValueCol$
                if emlCheckNumericColumn.isNumeric = 0
                    beginPause: "Column Error"
                        comment: """" + histValueCol$ + """ does not contain numeric data."
                        comment: "Please select a numeric column."
                    endPause: "OK", 1, 0
                    histFormDone = 0
                    allFormsDone = 0
                endif
            endif
        until histFormDone = 1

    elsif graph_type = 11
        # =============================================================
        # Grouped Violin — Page 2 (column mapping)
        # =============================================================

        gvCatIdx = 1
        gvSubIdx = min (2, nCols)
        gvValueIdx = min (3, nCols)

        if emlGraphsPresetGroupCol$ <> ""
            .gvSubFromPreset = 0
            for .iPreset from 1 to nCols
                if colName$[.iPreset] = emlGraphsPresetGroupCol$
                    gvCatIdx = .iPreset
                endif
                if colName$[.iPreset] = emlGraphsPresetDataCol$
                    gvValueIdx = .iPreset
                endif
                # D32 (remaining half). A caller that knows its second factor
                # says so here. The guesser below is a fallback for callers
                # that do not, and must not be allowed to overrule a caller
                # that does — a wrapper reading its own form knows the answer
                # the keyword scorer is only estimating.
                if emlGraphsPresetSubgroupCol$ <> ""
                    if colName$[.iPreset] = emlGraphsPresetSubgroupCol$
                        gvSubIdx = .iPreset
                        .gvSubFromPreset = 1
                    endif
                endif
            endfor

            # A preset subgroup that lands on the Category or the Value column
            # is not usable — it would reproduce the very collision D32
            # describes — so it is demoted back to "no preset" and the guesser
            # below gets its turn after all.
            if .gvSubFromPreset = 1
                if gvSubIdx = gvCatIdx or gvSubIdx = gvValueIdx
                    .gvSubFromPreset = 0
                endif
            endif

            # D107 (D32 in this branch). The preset bridge carries a category
            # and a value column and had no slot for the SECOND factor, so
            # gvSubIdx used to keep the positional initializer min (2, nCols)
            # here. On demo_twoway (subject, voice_type, task, SPL_dB) that is
            # voice_type — the column the preset had just assigned to Category
            # — so the two-way wrapper's out-of-box figure opened with Category
            # and Subgroup pointing at the same column and drew a single-factor
            # plot with `task` absent entirely. The D32 role-guessing fix went
            # into the else-branch below and NOT into this one, which is the
            # branch the two-way wrapper actually takes. Same guesser, run here
            # too, with a collision guard so it cannot re-suggest a column the
            # preset already claimed.
            #
            # Skipped entirely when emlGraphsPresetSubgroupCol$ named a usable
            # column: guessing is what you do when nobody told you.
            if .gvSubFromPreset = 0
                @emlGuessColumnRoles: objectId
                .gvSubGuess = emlGuessColumnRoles.factor2Idx
                if .gvSubGuess = gvCatIdx or .gvSubGuess = gvValueIdx
                    .gvSubGuess = emlGuessColumnRoles.factor1Idx
                endif
                if .gvSubGuess > 0 and .gvSubGuess <> gvCatIdx and .gvSubGuess <> gvValueIdx
                    gvSubIdx = .gvSubGuess
                endif
                if gvSubIdx = gvCatIdx or gvSubIdx = gvValueIdx
                    # Still colliding: take the first CATEGORICAL column that is
                    # neither Category nor Value and is not the subject/ID column.
                    # min (2, nCols) is a column-order accident — it is what put a
                    # 48-level identifier one sort order away from becoming the
                    # subgroup — so the fallback tests the data, not the position.
                    .gvSubFound = 0
                    for .iSub from 1 to nCols
                        if .iSub <> gvCatIdx and .iSub <> gvValueIdx and .iSub <> emlGuessColumnRoles.subjectIdx and .gvSubFound = 0
                            @emlCheckNumericColumn: objectId, colName$[.iSub]
                            if emlCheckNumericColumn.isNumeric = 0
                                gvSubIdx = .iSub
                                .gvSubFound = 1
                            endif
                        endif
                    endfor
                endif
            endif

            # Consumed — clear so Redraw uses prev_* persistence
            emlGraphsPresetGroupCol$ = ""
            emlGraphsPresetDataCol$ = ""
            emlGraphsPresetSubgroupCol$ = ""
        elsif prev_gvCatIdx > 0
            gvCatIdx = prev_gvCatIdx
            gvSubIdx = prev_gvSubIdx
            gvValueIdx = prev_gvValueIdx
        else
            # Column-role defaults come from @emlGuessColumnRoles, the same
            # weighted guesser the wizard and every stats wrapper already use.
            # This site used to carry its own three-keyword copy of it; see the
            # note at the top of this file. Only non-zero guesses overwrite the
            # positional defaults set above, so an undetected role still falls
            # back exactly as before.
            @emlGuessColumnRoles: objectId
            if emlGuessColumnRoles.factor1Idx > 0
                gvCatIdx = emlGuessColumnRoles.factor1Idx
            endif
            if emlGuessColumnRoles.factor2Idx > 0
                gvSubIdx = emlGuessColumnRoles.factor2Idx
            endif
            if emlGuessColumnRoles.dataIdx > 0
                gvValueIdx = emlGuessColumnRoles.dataIdx
            endif
            @emlCheckNumericColumn: objectId, colName$[gvValueIdx]
            if emlCheckNumericColumn.isNumeric = 0
                gvValueIdx = 0
                for iCol from 1 to nCols
                    if gvValueIdx = 0 and iCol <> gvCatIdx and iCol <> gvSubIdx
                        @emlCheckNumericColumn: objectId, colName$[iCol]
                        if emlCheckNumericColumn.isNumeric = 1
                            gvValueIdx = iCol
                        endif
                    endif
                endfor
                if gvValueIdx = 0
                    gvValueIdx = min (3, nCols)
                endif
            endif
        endif

        if lastDrawnGraphType = 11
            tmpVMin$ = string$ (prev_gv_valueMin)
            tmpVMax$ = string$ (prev_gv_valueMax)
        else
            tmpVMin$ = "0"
            tmpVMax$ = "0"
        endif
        tmpXLabel$ = ""
        tmpYLabel$ = ""

        gvFormDone = 0
        repeat
            if config_showAdvanced
                gvToggleLabel$ = "Beginner"
            else
                gvToggleLabel$ = "Advanced"
            endif

            beginPause: "Grouped Violin -- Column Mapping"
                comment: "📋 Select columns from your Table."
                optionmenu: "Value column", gvValueIdx
                    for iCol from 1 to nCols
                        option: colName$[iCol]
                    endfor
                optionmenu: "Category column", gvCatIdx
                    for iCol from 1 to nCols
                        option: colName$[iCol]
                    endfor
                optionmenu: "Subgroup column", gvSubIdx
                    for iCol from 1 to nCols
                        option: colName$[iCol]
                    endfor
                optionmenu: "Group order", prev_groupSort
                    option: "Table order"
                    option: "Alphabetical"
                if config_showAdvanced
                    boolean: "Annotate results on graph", annotate
                    optionmenu: "Test type", prev_gvAnnotTestType
                        option: "Parametric"
                        option: "Nonparametric"
                    optionmenu: "Adjustment method (nonparametric post-hoc only)", prev_annotAdjustIdx
                        option: "Bonferroni"
                        option: "Holm"
                        option: "Benjamini-Hochberg"
                    optionmenu: "Significance style", prev_gvAnnotStyle
                        option: "p-value"
                        option: "stars"
                        option: "both"
                    boolean: "Show nonsignificant", annotShowNS
                    boolean: "Show effect sizes", annotShowEffect
                    real: "Alpha", string$ (annotAlpha)
                    boolean: "Show jittered points", prev_gvShowJitter
                    comment: "📐 Y-axis range (both 0 = auto)"
                    real: "Value maximum", tmpVMax$
                    real: "Value minimum", tmpVMin$
                    optionmenu: "Gridline mode", tmpGridMode
                        option: "Horizontal"
                        option: "Off"
                    optionmenu: "Output DPI", tmpDPI
                        option: "300 dpi"
                        option: "600 dpi"
                    boolean: "Show inner box", tmpShowInnerBox
                    optionmenu: "Show axis names", tmpShowAxisNames
                        option: "None"
                        option: "Both"
                        option: "X only"
                        option: "Y only"
                    optionmenu: "Show ticks", tmpShowTicks
                        option: "None"
                        option: "Both"
                        option: "X only"
                        option: "Y only"
                    optionmenu: "Show axis values", tmpShowAxisValues
                        option: "None"
                        option: "Both"
                        option: "X only"
                        option: "Y only"
                    optionmenu: "Font", tmpFont
                        option: "Helvetica"
                        option: "Times"
                        option: "Palatino"
                        option: "Courier"
                    comment: "🏷️ Axis labels (blank = auto from column)"
                    comment: "Formatting: %italic · #bold · ^super · underscore = subscript · \% plus a space prints %"
                    sentence: "X axis label", tmpXLabel$
                    sentence: "Y axis label", tmpYLabel$
                endif
            clicked = endPause: "Go Back", "Quit", gvToggleLabel$, "Draw", 4, 1

            if clicked = 1
                gvFormDone = 1
            elsif clicked = 2
                @emlSaveConfig
                exitScript: ""
            elsif clicked = 3
                gvCatIdx = category_column
                gvSubIdx = subgroup_column
                prev_groupSort = group_order
                config_groupSort = group_order
                gvValueIdx = value_column
                if config_showAdvanced
                    # Toggling TO beginner: save advanced state
                    prev_adv_gv_annotate = annotate_results_on_graph
                    prev_adv_gv_annotShowNS = show_nonsignificant
                    prev_adv_gv_annotShowEffect = show_effect_sizes
                    prev_adv_gv_annotAlpha = alpha
                    prev_adv_gv_testType = test_type
                    prev_adv_gv_annotStyle = significance_style
                    prev_annotAdjustIdx = adjustment_method
                    prev_adv_gv_showJitter = show_jittered_points
                    prev_adv_gv_VMin$ = string$ (value_minimum)
                    prev_adv_gv_VMax$ = string$ (value_maximum)
                    prev_adv_gv_gridMode = gridline_mode
                    prev_adv_gv_showInnerBox = show_inner_box
                    prev_adv_gv_showAxisNames = show_axis_names
                    prev_adv_gv_showTicks = show_ticks
                    prev_adv_gv_showAxisValues = show_axis_values
                    prev_adv_gv_font = font
                    prev_adv_gv_DPI = output_DPI
                    prev_adv_gv_XLabel$ = x_axis_label$
                    prev_adv_gv_YLabel$ = y_axis_label$
                    # Reset to beginner defaults
                    prev_gvShowJitter = 0
                    annotate = 0
                    annotShowNS = 0
                    annotShowEffect = 0
                    annotLayoutMode = 3
                    prev_gvAnnotTestType = 1
                    prev_gvAnnotStyle = 1
                    tmpVMin$ = "0"
                    tmpVMax$ = "0"
                    tmpGridMode = config_gridlineMode
                    tmpShowInnerBox = config_showInnerBox
                    tmpShowAxisNames = config_showAxisNames
                    tmpShowTicks = config_showTicks
                    tmpShowAxisValues = config_showAxisValues
                    tmpFont = config_font
                    tmpDPI = config_outputDPI
                    tmpXLabel$ = ""
                    tmpYLabel$ = ""
                else
                    # Toggling TO advanced: restore saved state
                    if variableExists ("prev_adv_gv_annotate")
                        annotate = prev_adv_gv_annotate
                        annotShowNS = prev_adv_gv_annotShowNS
                        annotShowEffect = prev_adv_gv_annotShowEffect
                        annotAlpha = prev_adv_gv_annotAlpha
                        prev_gvAnnotTestType = prev_adv_gv_testType
                        prev_gvAnnotStyle = prev_adv_gv_annotStyle
                        prev_gvShowJitter = prev_adv_gv_showJitter
                        tmpVMin$ = prev_adv_gv_VMin$
                        tmpVMax$ = prev_adv_gv_VMax$
                        tmpGridMode = prev_adv_gv_gridMode
                        tmpShowInnerBox = prev_adv_gv_showInnerBox
                        tmpShowAxisNames = prev_adv_gv_showAxisNames
                        tmpShowTicks = prev_adv_gv_showTicks
                        tmpShowAxisValues = prev_adv_gv_showAxisValues
                        tmpFont = prev_adv_gv_font
                        tmpDPI = prev_adv_gv_DPI
                        tmpXLabel$ = prev_adv_gv_XLabel$
                        tmpYLabel$ = prev_adv_gv_YLabel$
                    endif
                endif
                config_showAdvanced = 1 - config_showAdvanced
            else
                gvFormDone = 1
                allFormsDone = 1

                gvCatCol$ = category_column$
                gvSubCol$ = subgroup_column$
                gvValueCol$ = value_column$

                if config_showAdvanced
                    tmpVMin$ = string$ (value_minimum)
                    tmpVMax$ = string$ (value_maximum)
                    tmpGridMode = gridline_mode
                    tmpShowInnerBox = show_inner_box
                    tmpShowAxisNames = show_axis_names
                    tmpShowTicks = show_ticks
                    tmpShowAxisValues = show_axis_values
                    tmpFont = font
                    tmpDPI = output_DPI
                    tmpXLabel$ = x_axis_label$
                    tmpYLabel$ = y_axis_label$
                    config_gridlineMode = gridline_mode
                    emlShowInnerBox = show_inner_box
                    emlFont$ = font$
                    config_showInnerBox = show_inner_box
                    config_showAxisNames = show_axis_names
                    config_showTicks = show_ticks
                    config_showAxisValues = show_axis_values
                    @emlExpandAxisControls
                    config_font$ = font$
                    config_font = font
                    config_outputDPI = output_DPI
                    prev_gvShowJitter = show_jittered_points
                    annotate = annotate_results_on_graph
                    annotShowNS = show_nonsignificant
                    annotShowEffect = show_effect_sizes
                    annotAlpha = alpha
                    annotLayoutMode = 3
                    prev_gvAnnotTestType = test_type
                    prev_gvAnnotStyle = significance_style
                    @emlAdjustMethodName: adjustment_method
                    annotCorrectionMethod$ = emlAdjustMethodName.name$
                    prev_annotAdjustIdx = adjustment_method
                    if test_type = 2
                        annotTestType$ = "nonparametric"
                    else
                        annotTestType$ = "parametric"
                    endif
                    if significance_style = 2
                        annotStyle$ = "stars"
                    elsif significance_style = 3
                        annotStyle$ = "both"
                    else
                        annotStyle$ = "p-value"
                    endif
                else
                    prev_gvShowJitter = 0
                    annotate = 0
                    annotShowNS = 0
                    annotShowEffect = 0
                    annotLayoutMode = 3
                    # annotTestType$ preserved — only meaningful when annotate=1
                    # annotStyle$ preserved — only meaningful when annotate=1
                endif
                gridline_mode = tmpGridMode
                output_DPI = tmpDPI

                prev_gvCatIdx = category_column
                prev_gvSubIdx = subgroup_column
                prev_groupSort = group_order
                config_groupSort = group_order
                prev_gvValueIdx = value_column

                valueMin = number (tmpVMin$)
                valueMax = number (tmpVMax$)
                prev_gv_valueMin = valueMin
                prev_gv_valueMax = valueMax

                x_axis_label$ = tmpXLabel$
                y_axis_label$ = tmpYLabel$
                if x_axis_label$ = ""
                    @emlCapitalizeLabel: gvCatCol$
                    x_axis_label$ = emlCapitalizeLabel.result$
                endif
                if y_axis_label$ = ""
                    @emlCapitalizeLabel: gvValueCol$
                    y_axis_label$ = emlCapitalizeLabel.result$
                endif

                @emlCheckNumericColumn: objectId, gvValueCol$
                if emlCheckNumericColumn.isNumeric = 0
                    beginPause: "Column Error"
                        comment: """" + gvValueCol$ + """ does not contain numeric data."
                        comment: "Please select a numeric column for the value axis."
                    endPause: "OK", 1, 0
                    gvFormDone = 0
                    allFormsDone = 0
                endif
            endif
        until gvFormDone = 1

    elsif graph_type = 12
        # =============================================================
        # Grouped Box Plot — Page 2 (column mapping)
        # =============================================================

        gbCatIdx = 1
        gbSubIdx = min (2, nCols)
        gbValueIdx = min (3, nCols)

        if emlGraphsPresetGroupCol$ <> ""
            .gbSubPreset = 0
            for .iPreset from 1 to nCols
                if colName$[.iPreset] = emlGraphsPresetGroupCol$
                    gbCatIdx = .iPreset
                endif
                if colName$[.iPreset] = emlGraphsPresetDataCol$
                    gbValueIdx = .iPreset
                endif
                # D32. Grouped Box takes a second factor for exactly the same
                # reason Grouped Violin does, and had the same silent
                # min (2, nCols) positional default. A caller that names its
                # second factor is honoured here too; anything that collides
                # with Category or Value is ignored rather than drawn.
                if emlGraphsPresetSubgroupCol$ <> ""
                    if colName$[.iPreset] = emlGraphsPresetSubgroupCol$
                        .gbSubPreset = .iPreset
                    endif
                endif
            endfor
            if .gbSubPreset > 0 and .gbSubPreset <> gbCatIdx and .gbSubPreset <> gbValueIdx
                gbSubIdx = .gbSubPreset
            endif
            # Consumed — clear so Redraw uses prev_* persistence
            emlGraphsPresetGroupCol$ = ""
            emlGraphsPresetDataCol$ = ""
            emlGraphsPresetSubgroupCol$ = ""
        elsif prev_gbCatIdx > 0
            gbCatIdx = prev_gbCatIdx
            gbSubIdx = prev_gbSubIdx
            gbValueIdx = prev_gbValueIdx
        else
            # Column-role defaults come from @emlGuessColumnRoles, the same
            # weighted guesser the wizard and every stats wrapper already use.
            # This site used to carry its own three-keyword copy of it; see the
            # note at the top of this file. Only non-zero guesses overwrite the
            # positional defaults set above, so an undetected role still falls
            # back exactly as before.
            @emlGuessColumnRoles: objectId
            if emlGuessColumnRoles.factor1Idx > 0
                gbCatIdx = emlGuessColumnRoles.factor1Idx
            endif
            if emlGuessColumnRoles.factor2Idx > 0
                gbSubIdx = emlGuessColumnRoles.factor2Idx
            endif
            if emlGuessColumnRoles.dataIdx > 0
                gbValueIdx = emlGuessColumnRoles.dataIdx
            endif
            @emlCheckNumericColumn: objectId, colName$[gbValueIdx]
            if emlCheckNumericColumn.isNumeric = 0
                gbValueIdx = 0
                for iCol from 1 to nCols
                    if gbValueIdx = 0 and iCol <> gbCatIdx and iCol <> gbSubIdx
                        @emlCheckNumericColumn: objectId, colName$[iCol]
                        if emlCheckNumericColumn.isNumeric = 1
                            gbValueIdx = iCol
                        endif
                    endif
                endfor
                if gbValueIdx = 0
                    gbValueIdx = min (3, nCols)
                endif
            endif
        endif

        if lastDrawnGraphType = 12
            tmpVMin$ = string$ (prev_gb_valueMin)
            tmpVMax$ = string$ (prev_gb_valueMax)
        else
            tmpVMin$ = "0"
            tmpVMax$ = "0"
        endif
        tmpXLabel$ = ""
        tmpYLabel$ = ""

        gbFormDone = 0
        repeat
            if config_showAdvanced
                gbToggleLabel$ = "Beginner"
            else
                gbToggleLabel$ = "Advanced"
            endif

            beginPause: "Grouped Box Plot -- Column Mapping"
                comment: "📋 Select columns from your Table."
                optionmenu: "Value column", gbValueIdx
                    for iCol from 1 to nCols
                        option: colName$[iCol]
                    endfor
                optionmenu: "Category column", gbCatIdx
                    for iCol from 1 to nCols
                        option: colName$[iCol]
                    endfor
                optionmenu: "Subgroup column", gbSubIdx
                    for iCol from 1 to nCols
                        option: colName$[iCol]
                    endfor
                optionmenu: "Group order", prev_groupSort
                    option: "Table order"
                    option: "Alphabetical"
                if config_showAdvanced
                    boolean: "Annotate results on graph", annotate
                    optionmenu: "Test type", prev_gbAnnotTestType
                        option: "Parametric"
                        option: "Nonparametric"
                    optionmenu: "Adjustment method (nonparametric post-hoc only)", prev_annotAdjustIdx
                        option: "Bonferroni"
                        option: "Holm"
                        option: "Benjamini-Hochberg"
                    optionmenu: "Significance style", prev_gbAnnotStyle
                        option: "p-value"
                        option: "stars"
                        option: "both"
                    boolean: "Show nonsignificant", annotShowNS
                    boolean: "Show effect sizes", annotShowEffect
                    real: "Alpha", string$ (annotAlpha)
                    boolean: "Show jittered points", prev_gbShowJitter
                    comment: "📐 Y-axis range (both 0 = auto)"
                    real: "Value maximum", tmpVMax$
                    real: "Value minimum", tmpVMin$
                    optionmenu: "Gridline mode", tmpGridMode
                        option: "Horizontal"
                        option: "Off"
                    optionmenu: "Output DPI", tmpDPI
                        option: "300 dpi"
                        option: "600 dpi"
                    boolean: "Show inner box", tmpShowInnerBox
                    optionmenu: "Show axis names", tmpShowAxisNames
                        option: "None"
                        option: "Both"
                        option: "X only"
                        option: "Y only"
                    optionmenu: "Show ticks", tmpShowTicks
                        option: "None"
                        option: "Both"
                        option: "X only"
                        option: "Y only"
                    optionmenu: "Show axis values", tmpShowAxisValues
                        option: "None"
                        option: "Both"
                        option: "X only"
                        option: "Y only"
                    optionmenu: "Font", tmpFont
                        option: "Helvetica"
                        option: "Times"
                        option: "Palatino"
                        option: "Courier"
                    comment: "🏷️ Axis labels (blank = auto from column)"
                    comment: "Formatting: %italic · #bold · ^super · underscore = subscript · \% plus a space prints %"
                    sentence: "X axis label", tmpXLabel$
                    sentence: "Y axis label", tmpYLabel$
                endif
            clicked = endPause: "Go Back", "Quit", gbToggleLabel$, "Draw", 4, 1

            if clicked = 1
                gbFormDone = 1
            elsif clicked = 2
                @emlSaveConfig
                exitScript: ""
            elsif clicked = 3
                gbCatIdx = category_column
                gbSubIdx = subgroup_column
                prev_groupSort = group_order
                config_groupSort = group_order
                gbValueIdx = value_column
                if config_showAdvanced
                    # Toggling TO beginner: save advanced state
                    prev_adv_gb_annotate = annotate_results_on_graph
                    prev_adv_gb_annotShowNS = show_nonsignificant
                    prev_adv_gb_annotShowEffect = show_effect_sizes
                    prev_adv_gb_annotAlpha = alpha
                    prev_adv_gbTestType = test_type
                    prev_adv_gbAnnotStyle = significance_style
                    prev_annotAdjustIdx = adjustment_method
                    prev_adv_gbShowJitter = show_jittered_points
                    prev_adv_gb_VMin$ = string$ (value_minimum)
                    prev_adv_gb_VMax$ = string$ (value_maximum)
                    prev_adv_gb_gridMode = gridline_mode
                    prev_adv_gb_showInnerBox = show_inner_box
                    prev_adv_gb_showAxisNames = show_axis_names
                    prev_adv_gb_showTicks = show_ticks
                    prev_adv_gb_showAxisValues = show_axis_values
                    prev_adv_gb_font = font
                    prev_adv_gb_DPI = output_DPI
                    prev_adv_gb_XLabel$ = x_axis_label$
                    prev_adv_gb_YLabel$ = y_axis_label$
                    # Reset to beginner defaults
                    prev_gbShowJitter = 0
                    annotate = 0
                    annotShowNS = 0
                    annotShowEffect = 0
                    annotLayoutMode = 3
                    prev_gbAnnotTestType = 1
                    prev_gbAnnotStyle = 1
                    tmpVMin$ = "0"
                    tmpVMax$ = "0"
                    tmpGridMode = config_gridlineMode
                    tmpShowInnerBox = config_showInnerBox
                    tmpShowAxisNames = config_showAxisNames
                    tmpShowTicks = config_showTicks
                    tmpShowAxisValues = config_showAxisValues
                    tmpFont = config_font
                    tmpDPI = config_outputDPI
                    tmpXLabel$ = ""
                    tmpYLabel$ = ""
                else
                    # Toggling TO advanced: restore saved state
                    if variableExists ("prev_adv_gb_annotate")
                        annotate = prev_adv_gb_annotate
                        annotShowNS = prev_adv_gb_annotShowNS
                        annotShowEffect = prev_adv_gb_annotShowEffect
                        annotAlpha = prev_adv_gb_annotAlpha
                        prev_gbAnnotTestType = prev_adv_gbTestType
                        prev_gbAnnotStyle = prev_adv_gbAnnotStyle
                        prev_gbShowJitter = prev_adv_gbShowJitter
                        tmpVMin$ = prev_adv_gb_VMin$
                        tmpVMax$ = prev_adv_gb_VMax$
                        tmpGridMode = prev_adv_gb_gridMode
                        tmpShowInnerBox = prev_adv_gb_showInnerBox
                        tmpShowAxisNames = prev_adv_gb_showAxisNames
                        tmpShowTicks = prev_adv_gb_showTicks
                        tmpShowAxisValues = prev_adv_gb_showAxisValues
                        tmpFont = prev_adv_gb_font
                        tmpDPI = prev_adv_gb_DPI
                        tmpXLabel$ = prev_adv_gb_XLabel$
                        tmpYLabel$ = prev_adv_gb_YLabel$
                    endif
                endif
                config_showAdvanced = 1 - config_showAdvanced
            else
                gbFormDone = 1
                allFormsDone = 1
                gbCatCol$ = category_column$
                gbSubCol$ = subgroup_column$
                gbValueCol$ = value_column$
                if config_showAdvanced
                    tmpVMin$ = string$ (value_minimum)
                    tmpVMax$ = string$ (value_maximum)
                    tmpGridMode = gridline_mode
                    tmpShowInnerBox = show_inner_box
                    tmpShowAxisNames = show_axis_names
                    tmpShowTicks = show_ticks
                    tmpShowAxisValues = show_axis_values
                    tmpFont = font
                    tmpDPI = output_DPI
                    tmpXLabel$ = x_axis_label$
                    tmpYLabel$ = y_axis_label$
                    config_gridlineMode = gridline_mode
                    emlShowInnerBox = show_inner_box
                    emlFont$ = font$
                    config_showInnerBox = show_inner_box
                    config_showAxisNames = show_axis_names
                    config_showTicks = show_ticks
                    config_showAxisValues = show_axis_values
                    @emlExpandAxisControls
                    config_font$ = font$
                    config_font = font
                    config_outputDPI = output_DPI
                    prev_gbShowJitter = show_jittered_points
                    annotate = annotate_results_on_graph
                    annotShowNS = show_nonsignificant
                    annotShowEffect = show_effect_sizes
                    annotAlpha = alpha
                    annotLayoutMode = 3
                    prev_gbAnnotTestType = test_type
                    prev_gbAnnotStyle = significance_style
                    @emlAdjustMethodName: adjustment_method
                    annotCorrectionMethod$ = emlAdjustMethodName.name$
                    prev_annotAdjustIdx = adjustment_method
                    if test_type = 2
                        annotTestType$ = "nonparametric"
                    else
                        annotTestType$ = "parametric"
                    endif
                    if significance_style = 2
                        annotStyle$ = "stars"
                    elsif significance_style = 3
                        annotStyle$ = "both"
                    else
                        annotStyle$ = "p-value"
                    endif
                else
                    prev_gbShowJitter = 0
                    annotate = 0
                    annotShowNS = 0
                    annotShowEffect = 0
                    annotLayoutMode = 3
                    # annotTestType$ preserved — only meaningful when annotate=1
                    # annotStyle$ preserved — only meaningful when annotate=1
                endif
                gridline_mode = tmpGridMode
                output_DPI = tmpDPI
                prev_gbCatIdx = category_column
                prev_gbSubIdx = subgroup_column
                prev_groupSort = group_order
                config_groupSort = group_order
                prev_gbValueIdx = value_column
                valueMin = number (tmpVMin$)
                valueMax = number (tmpVMax$)
                prev_gb_valueMin = valueMin
                prev_gb_valueMax = valueMax
                x_axis_label$ = tmpXLabel$
                y_axis_label$ = tmpYLabel$
                if x_axis_label$ = ""
                    @emlCapitalizeLabel: gbCatCol$
                    x_axis_label$ = emlCapitalizeLabel.result$
                endif
                if y_axis_label$ = ""
                    @emlCapitalizeLabel: gbValueCol$
                    y_axis_label$ = emlCapitalizeLabel.result$
                endif
                @emlCheckNumericColumn: objectId, gbValueCol$
                if emlCheckNumericColumn.isNumeric = 0
                    beginPause: "Column Error"
                        comment: """" + gbValueCol$ + """ does not contain numeric data."
                    endPause: "OK", 1, 0
                    gbFormDone = 0
                    allFormsDone = 0
                endif
            endif
        until gbFormDone = 1


    elsif graph_type = 13
        # =============================================================
        # Spaghetti Plot — Page 2 (column mapping)
        # =============================================================

        spCondIdx = 1
        spValueIdx = min (2, nCols)
        spSubjectIdx = min (3, nCols)
        spGroupIdx = 1
        tmpUseGroup = 0

        # A caller-supplied group column must win over both the prev_*
        # persistence branch and the name heuristic below. Without this the
        # spaghetti page ignored emlGraphsPresetGroupCol$ entirely: the
        # heuristic runs only on the first spaghetti draw of a session, so a
        # later Draw from a stats wrapper silently dropped the requested
        # grouping.
        if emlGraphsPresetGroupCol$ <> ""
            for .iPreset from 1 to nCols
                if colName$[.iPreset] = emlGraphsPresetGroupCol$
                    spPresetGroupIdx = .iPreset
                    spPresetHasGroup = 1
                endif
            endfor
            # Consumed — clear so Redraw uses prev_* persistence
            emlGraphsPresetGroupCol$ = ""
        endif

        if prev_spCondIdx > 0
            spCondIdx = prev_spCondIdx
            spValueIdx = prev_spValueIdx
            spSubjectIdx = prev_spSubjectIdx
            spGroupIdx = prev_spGroupIdx
            if prev_spUseGroup >= 0
                tmpUseGroup = prev_spUseGroup
            endif
        else
            # Column-role defaults come from @emlGuessColumnRoles, the same
            # weighted guesser the wizard and every stats wrapper already use.
            # This site used to carry its own three-keyword copy of it; see the
            # note at the top of this file. Only non-zero guesses overwrite the
            # positional defaults set above, so an undetected role still falls
            # back exactly as before.
            @emlGuessColumnRoles: objectId
            if emlGuessColumnRoles.groupIdx > 0
                spCondIdx = emlGuessColumnRoles.groupIdx
            endif
            if emlGuessColumnRoles.dataIdx > 0
                spValueIdx = emlGuessColumnRoles.dataIdx
            endif
            if emlGuessColumnRoles.subjectIdx > 0
                spSubjectIdx = emlGuessColumnRoles.subjectIdx
            endif
            if emlGuessColumnRoles.factor2Idx > 0
                spGroupIdx = emlGuessColumnRoles.factor2Idx
            endif
            if emlGuessColumnRoles.factor2Idx > 0
                tmpUseGroup = 1
            endif
            # Value column must be numeric
            @emlCheckNumericColumn: objectId, colName$[spValueIdx]
            if emlCheckNumericColumn.isNumeric = 0
                spValueIdx = 0
                for iCol from 1 to nCols
                    if spValueIdx = 0 and iCol <> spCondIdx
                        @emlCheckNumericColumn: objectId, colName$[iCol]
                        if emlCheckNumericColumn.isNumeric = 1
                            spValueIdx = iCol
                        endif
                    endif
                endfor
                if spValueIdx = 0
                    spValueIdx = min (2, nCols)
                endif
            endif
        endif

        if spPresetHasGroup
            spGroupIdx = spPresetGroupIdx
            tmpUseGroup = 1
            spPresetHasGroup = 0
        endif

        if lastDrawnGraphType = 13
            tmpVMin$ = string$ (prev_sp_valueMin)
            tmpVMax$ = string$ (prev_sp_valueMax)
        else
            tmpVMin$ = "0"
            tmpVMax$ = "0"
        endif
        tmpXLabel$ = ""
        tmpYLabel$ = ""
        if prev_spShowMean < 0
            tmpShowMean = 1
        else
            tmpShowMean = prev_spShowMean
        endif

        spFormDone = 0
        repeat
            if config_showAdvanced
                spToggleLabel$ = "Beginner"
            else
                spToggleLabel$ = "Advanced"
            endif

            beginPause: "Spaghetti Plot -- Column Mapping"
                comment: "📋 Select columns from your Table."
                optionmenu: "Value column (Y-axis)", spValueIdx
                    for iCol from 1 to nCols
                        option: colName$[iCol]
                    endfor
                optionmenu: "Condition column (X-axis)", spCondIdx
                    for iCol from 1 to nCols
                        option: colName$[iCol]
                    endfor
                optionmenu: "Subject column (participant ID)", spSubjectIdx
                    for iCol from 1 to nCols
                        option: colName$[iCol]
                    endfor
                boolean: "Use group column", tmpUseGroup
                optionmenu: "Group column (colors lines)", spGroupIdx
                    for iCol from 1 to nCols
                        option: colName$[iCol]
                    endfor
                optionmenu: "Group order", prev_spGroupSort
                    option: "Table order"
                    option: "Alphabetical"
                boolean: "Show mean overlay", tmpShowMean
                if config_showAdvanced
                    comment: "📐 Y-axis range (both 0 = auto)"
                    real: "Value maximum", tmpVMax$
                    real: "Value minimum", tmpVMin$
                    optionmenu: "Gridline mode", tmpGridMode
                        option: "Horizontal"
                        option: "Off"
                    optionmenu: "Output DPI", tmpDPI
                        option: "300 dpi"
                        option: "600 dpi"
                    boolean: "Show inner box", tmpShowInnerBox
                    optionmenu: "Show axis names", tmpShowAxisNames
                        option: "None"
                        option: "Both"
                        option: "X only"
                        option: "Y only"
                    optionmenu: "Show ticks", tmpShowTicks
                        option: "None"
                        option: "Both"
                        option: "X only"
                        option: "Y only"
                    optionmenu: "Show axis values", tmpShowAxisValues
                        option: "None"
                        option: "Both"
                        option: "X only"
                        option: "Y only"
                    optionmenu: "Font", tmpFont
                        option: "Helvetica"
                        option: "Times"
                        option: "Palatino"
                        option: "Courier"
                    comment: "🏷️ Axis labels (blank = auto from column)"
                    comment: "Formatting: %italic · #bold · ^super · underscore = subscript · \% plus a space prints %"
                    sentence: "X axis label", tmpXLabel$
                    sentence: "Y axis label", tmpYLabel$
                endif
            clicked = endPause: "Go Back", "Quit", spToggleLabel$, "Draw", 4, 1

            if clicked = 1
                spFormDone = 1
            elsif clicked = 2
                @emlSaveConfig
                exitScript: ""
            elsif clicked = 3
                spCondIdx = condition_column
                spValueIdx = value_column
                spSubjectIdx = subject_column
                spGroupIdx = group_column
                tmpUseGroup = use_group_column
                prev_spGroupSort = group_order
                config_groupSort = group_order
                tmpShowMean = show_mean_overlay
                if config_showAdvanced
                    tmpVMin$ = "0"
                    tmpVMax$ = "0"
                    tmpGridMode = config_gridlineMode
                    tmpShowInnerBox = config_showInnerBox
                    tmpShowAxisNames = config_showAxisNames
                    tmpShowTicks = config_showTicks
                    tmpShowAxisValues = config_showAxisValues
                    tmpFont = config_font
                    tmpDPI = config_outputDPI
                    tmpXLabel$ = ""
                    tmpYLabel$ = ""
                endif
                config_showAdvanced = 1 - config_showAdvanced
            else
                spFormDone = 1
                allFormsDone = 1
                if config_showAdvanced
                    tmpVMin$ = string$ (value_minimum)
                    tmpVMax$ = string$ (value_maximum)
                    tmpGridMode = gridline_mode
                    tmpShowInnerBox = show_inner_box
                    tmpShowAxisNames = show_axis_names
                    tmpShowTicks = show_ticks
                    tmpShowAxisValues = show_axis_values
                    tmpFont = font
                    tmpDPI = output_DPI
                    tmpXLabel$ = x_axis_label$
                    tmpYLabel$ = y_axis_label$
                    config_gridlineMode = gridline_mode
                    emlShowInnerBox = show_inner_box
                    emlFont$ = font$
                    config_showInnerBox = show_inner_box
                    config_showAxisNames = show_axis_names
                    config_showTicks = show_ticks
                    config_showAxisValues = show_axis_values
                    @emlExpandAxisControls
                    config_font$ = font$
                    config_font = font
                    config_outputDPI = output_DPI
                endif
                gridline_mode = tmpGridMode
                output_DPI = tmpDPI
                spCondCol$ = condition_column$
                spValueCol$ = value_column$
                spSubjectCol$ = subject_column$
                if use_group_column = 0
                    spGroupCol$ = ""
                else
                    spGroupCol$ = group_column$
                endif
                spShowMean = show_mean_overlay
                prev_spCondIdx = condition_column
                prev_spValueIdx = value_column
                prev_spGroupSort = group_order
                config_groupSort = group_order
                prev_spSubjectIdx = subject_column
                prev_spGroupIdx = group_column
                prev_spUseGroup = use_group_column
                prev_spShowMean = show_mean_overlay
                valueMin = number (tmpVMin$)
                valueMax = number (tmpVMax$)
                prev_sp_valueMin = valueMin
                prev_sp_valueMax = valueMax
                x_axis_label$ = tmpXLabel$
                y_axis_label$ = tmpYLabel$
                if x_axis_label$ = ""
                    @emlCapitalizeLabel: spCondCol$
                    x_axis_label$ = emlCapitalizeLabel.result$
                endif
                if y_axis_label$ = ""
                    @emlCapitalizeLabel: spValueCol$
                    y_axis_label$ = emlCapitalizeLabel.result$
                endif
                # Only value column needs numeric validation
                @emlCheckNumericColumn: objectId, spValueCol$
                if emlCheckNumericColumn.isNumeric = 0
                    beginPause: "Column Error"
                        comment: """" + spValueCol$ + """ does not contain numeric data."
                    endPause: "OK", 1, 0
                    spFormDone = 0
                    allFormsDone = 0
                endif
            endif
        until spFormDone = 1
    endif

    until allFormsDone = 1

    # =================================================================
    # RANGE VALIDATION (swap if user entered max < min)
    # =================================================================
    # Both-zero = auto, skip validation. Otherwise swap and warn.

    if not (timeMin = 0 and timeMax = 0)
        if timeMax < timeMin
            tmpSwap = timeMin
            timeMin = timeMax
            timeMax = tmpSwap
        endif
    endif
    if not (freqMin = 0 and freqMax = 0)
        if freqMax < freqMin
            tmpSwap = freqMin
            freqMin = freqMax
            freqMax = tmpSwap
        endif
    endif
    if not (powerMin = 0 and powerMax = 0)
        if powerMax < powerMin
            tmpSwap = powerMin
            powerMin = powerMax
            powerMax = tmpSwap
        endif
    endif
    if not (ampMin = 0 and ampMax = 0)
        if ampMax < ampMin
            tmpSwap = ampMin
            ampMin = ampMax
            ampMax = tmpSwap
        endif
    endif
    if not (valueMin = 0 and valueMax = 0)
        if valueMax < valueMin
            tmpSwap = valueMin
            valueMin = valueMax
            valueMax = tmpSwap
        endif
    endif
    if variableExists ("scatterXMin")
        if not (scatterXMin = 0 and scatterXMax = 0)
            if scatterXMax < scatterXMin
                tmpSwap = scatterXMin
                scatterXMin = scatterXMax
                scatterXMax = tmpSwap
            endif
        endif
    endif

    # =================================================================
    # Set group sort order before any procedure calls @emlCountGroups.
    # Must precede annotation bridge, measurement, and draw dispatch.
    # =================================================================
    emlGroupSortAlphabetical = config_groupSort - 1

    # =================================================================
    # ANNOTATION BRIDGE (run stats before drawing)
    # =================================================================

    # Beginner mode: force all display elements on regardless of config.
    # Advanced mode users control these via form; beginner users always
    # get the full figure with sensible defaults.
    # Write to rendering globals (eml*), not config_* — preserves saved
    # advanced preferences for when the user switches back.
    if config_showAdvanced = 0
        gridline_mode = 1
        emlShowInnerBox = 1
        emlShowAxisNameX = 1
        emlShowAxisNameY = 1
        emlShowTicksX = 1
        emlShowTicksY = 1
        emlShowAxisValuesX = 1
        emlShowAxisValuesY = 1
    endif

    # Set up theme globals for headroom computation (idempotent —
    # drawing procedures call this again with the same arguments)
    @emlSetAdaptiveTheme: figure_width, figure_height

    @emlClearAnnotations

    # Force Matrix layout for graph types where brackets are inappropriate:
    # histogram (10), grouped violin (11), grouped box (12)
    if graph_type = 10 or graph_type = 11 or graph_type = 12
        annotLayoutMode = 3
    endif

    # D108. Every @emlBridgeGroupComparison call below delivers the
    # multiple-comparison method through the annotCorrectionMethod$ global, not
    # through the argument list — the bridge has no parameter for it. That
    # global is live here for both values of annotTestType$: it is seeded from
    # emlGraphsPresetCorrection$ during preset reading and re-committed
    # unconditionally (not only when test_type = 2) by each column-mapping
    # page, so a wrapper's parametric run reaches the bridge carrying its
    # method just as a nonparametric one does. Whether the parametric branch
    # then uses it is decided in eml-annotation-procedures.praat.
    if (graph_type = 6 or graph_type = 7 or graph_type = 9) and annotate = 1
        # Bar chart / Violin / Box plot: run group comparison bridge
        @emlBridgeGroupComparison: objectId, valueColName$, groupColName$, annotAlpha, annotStyle$, annotShowNS, annotShowEffect, annotTestType$, annotLayoutMode
        if emlBridgeGroupComparison.error$ <> ""
            appendInfoLine: "NOTE: Annotation skipped — " + emlBridgeGroupComparison.error$
        else
            @emlReportBridgeStats: objectId, valueColName$, groupColName$
        endif
    elsif graph_type = 11 and annotate = 1
        # Grouped Violin: compare sub-groups (pooled across categories)
        @emlBridgeGroupComparison: objectId, gvValueCol$, gvSubCol$, annotAlpha, annotStyle$, annotShowNS, annotShowEffect, annotTestType$, annotLayoutMode
        if emlBridgeGroupComparison.error$ <> ""
            appendInfoLine: "NOTE: Annotation skipped — " + emlBridgeGroupComparison.error$
        else
            emlBridgeGroupComparison.omnibus$ = emlBridgeGroupComparison.omnibus$ + " (pooled)"
            annotMatrixOmnibus$ = annotMatrixOmnibus$ + " (pooled)"
            @emlReportBridgeStats: objectId, gvValueCol$, gvSubCol$
        endif
    elsif graph_type = 10 and annotate = 1 and histGroupCol$ <> ""
        # Histogram: group comparison (matrix only, no brackets)
        @emlBridgeGroupComparison: objectId, histValueCol$, histGroupCol$, annotAlpha, annotStyle$, annotShowNS, annotShowEffect, annotTestType$, annotLayoutMode
        if emlBridgeGroupComparison.error$ <> ""
            appendInfoLine: "NOTE: Annotation skipped — " + emlBridgeGroupComparison.error$
        else
            @emlReportBridgeStats: objectId, histValueCol$, histGroupCol$
        endif
    elsif graph_type = 12 and annotate = 1
        # Grouped Box Plot: compare sub-groups (pooled across categories)
        @emlBridgeGroupComparison: objectId, gbValueCol$, gbSubCol$, annotAlpha, annotStyle$, annotShowNS, annotShowEffect, annotTestType$, annotLayoutMode
        if emlBridgeGroupComparison.error$ <> ""
            appendInfoLine: "NOTE: Annotation skipped — " + emlBridgeGroupComparison.error$
        else
            emlBridgeGroupComparison.omnibus$ = emlBridgeGroupComparison.omnibus$ + " (pooled)"
            annotMatrixOmnibus$ = annotMatrixOmnibus$ + " (pooled)"
            @emlReportBridgeStats: objectId, gbValueCol$, gbSubCol$
        endif
    endif
    # Scatter annotation is handled entirely within @emlDrawScatterPlot
    # to support "Both" correlation type and per-group regression.

    # =================================================================
    # PRE-DISPATCH: compute headroom for bar/violin annotations
    # =================================================================

    # Bar chart: pre-compute aggregated data (used by both headroom
    # and draw procedure). Must run unconditionally for bar charts.
    if graph_type = 6
        @emlMeasureBarData: objectId, groupColName$, valueColName$, errorBarMode, errorColName$
    endif

    # Save actual data maximum for bracket positioning (brackets should
    # start just above the tallest data element, not at the axis ceiling)
    dataYMax_forAnnotation = valueMax

    if (graph_type = 6 or graph_type = 7 or graph_type = 9) and annotate = 1 and annotBracketN > 0

        # Compute visible data maximum for bracket positioning.
        # Bar chart: max(groupMean + groupError). Violin/Box: raw data max.
        selectObject: objectId
        if graph_type = 6
            visibleDataMax = emlBarData_visibleMax
            visibleDataMin = emlBarData_visibleMin
        else
            # Violin/Box: visible extent = raw data extent
            visibleDataMax = Get maximum: valueColName$
            visibleDataMin = Get minimum: valueColName$
        endif

        if visibleDataMax <> undefined and visibleDataMax > 0
            dataYMax_forAnnotation = visibleDataMax
        endif

        # When auto-range (both 0), compute axis range from the visible extent.
        # For bar charts use the tracked data minimum so all-/mixed-negative
        # means get a negative floor instead of being clipped at 0 in the
        # annotated (bracket) path; emlComputeAxisRange's own non-negative guard
        # keeps the floor at 0 for non-negative data, so positive bars are
        # unchanged.
        if valueMin = 0 and valueMax = 0
            # D60. Ask once, here, whether this is a percentage scale, and hand
            # the answer to @emlComputeAxisRange instead of the literal 0 both
            # call sites used to pass. @emlGraphsIsPercentageColumn reselects
            # objectId, so it must run before the range calls rather than
            # inside them.
            @emlGraphsIsPercentageColumn: objectId, valueColName$
            .axisIsPct = emlGraphsIsPercentageColumn.result
            selectObject: objectId
            if graph_type = 6
                # Adaptive rounding grid: derive roundTo from a nice step over the data
                # range (the same nice-number logic the gridlines use) so fractional data
                # (proportions, contact quotient, jitter %) is not snapped to a 10-unit grid.
                @emlComputeNiceStep: emlBarData_visibleMax - (emlBarData_visibleMin), emlSetAdaptiveTheme.targetTicksY
                .axisRoundTo = emlComputeNiceStep.step
                @emlComputeAxisRange: emlBarData_visibleMin, emlBarData_visibleMax, .axisRoundTo, .axisIsPct
                valueMin = emlComputeAxisRange.axisMin
                valueMax = emlComputeAxisRange.axisMax
            elsif visibleDataMax <> undefined
                # Violin and box marks do not emanate from zero, so the floor
                # comes from the data like every other continuous axis. Passing
                # a literal 0 here pinned the axis to the origin whenever
                # brackets were drawn, so the same figure had a data-derived
                # range without annotation and a zero-floored one with it.
                # emlComputeAxisRange's own non-negative guard still keeps the
                # floor at 0 for data that does not go below it.
                @emlComputeNiceStep: visibleDataMax - (visibleDataMin), emlSetAdaptiveTheme.targetTicksY
                .axisRoundTo = emlComputeNiceStep.step
                @emlComputeAxisRange: visibleDataMin, visibleDataMax, .axisRoundTo, .axisIsPct
                valueMin = emlComputeAxisRange.axisMin
                valueMax = emlComputeAxisRange.axisMax
            endif
        endif

        annotDataRange = valueMax - valueMin
        @emlComputeAnnotationHeadroom: annotDataRange, emlSetAdaptiveTheme.annotSize
        if emlComputeAnnotationHeadroom.overflow = 1
            appendInfoLine: "NOTE: Viewport too small for bracket annotations — suppressing brackets."
            annotBracketN = 0
        else
            valueMax = valueMax + emlComputeAnnotationHeadroom.headroom
        endif
    endif

    # =================================================================
    # PRE-DISPATCH: categorical label measurement (Phase 1)
    # =================================================================
    # Measure rotation/truncation/overhang BEFORE draw dispatch.
    # Draw procedures read pre-computed state — they never measure.

    graphLabelRotated = 0
    graphOverhangInches = 0
    graphActualVerticalInches = 0
    graphNCatLabels = 0

    # Map graph type to its category column
    catMeasureCol$ = ""
    if graph_type = 6 or graph_type = 7 or graph_type = 9
        catMeasureCol$ = groupColName$
    elsif graph_type = 11
        catMeasureCol$ = gvCatCol$
    elsif graph_type = 12
        catMeasureCol$ = gbCatCol$
    elsif graph_type = 13
        catMeasureCol$ = spCondCol$
    endif

    if catMeasureCol$ <> ""
        @emlMeasureCategoricalLabels: objectId, catMeasureCol$, figure_width, figure_height
        graphNCatLabels = emlMeasureCategoricalLabels.nLabels
        graphLabelRotated = emlFitCategoricalLabels.rotated
        graphOverhangInches = emlFitCategoricalLabels.overhangInches
        graphActualVerticalInches = emlFitCategoricalLabels.actualVerticalInches
    endif

    # =================================================================
    # PRE-DISPATCH: matrix panel measurement
    # =================================================================

    matrixPanelHeight = 0
    if annotate = 1 and annotMatrixN > 0
        # Estimate panel viewport for measurement (may be adjusted by panel)
        mFontInch = emlSetAdaptiveTheme.matrixSize / 72
        mEstHeight = mFontInch * (6 + annotMatrixN * 2.5)
        if mEstHeight < 1.0
            mEstHeight = 1.0
        endif
        @emlMeasureMatrixLayout: 0, figure_width, figure_height, figure_height + mEstHeight, emlSetAdaptiveTheme.matrixSize
        if emlMatrixLayout_suppressed = 0
            matrixPanelHeight = emlMatrixLayout_yMax
            if matrixPanelHeight < 1.0
                matrixPanelHeight = 1.0
            endif
        else
            if annotMatrixN >= 2
                appendInfoLine: "NOTE: Viewport too narrow for comparison matrix — panel suppressed."
            endif
        endif
    endif
    # Gap between graph bottom and matrix panel top
    # Base separation + actual rotated label overhang (responsive)
    if matrixPanelHeight > 0
        matrixGap = emlSetAdaptiveTheme.bodyInch * 1.0 + graphOverhangInches
    else
        matrixGap = 0
    endif
    totalCanvasHeight = figure_height + matrixGap + matrixPanelHeight

    # =================================================================
    # PRE-DISPATCH: default title (D43 / D89)
    # =================================================================
    # Last possible moment before the title is measured and drawn, and the
    # first moment at which the column mapping exists. See the header on
    # @emlComposeGraphTitle for why it cannot be done in the form itself.
    # Blank means "auto"; a title the user typed is left exactly as typed.
    @emlComposeGraphTitle
    if title$ = "" or title$ = prev_autoTitle$
        title$ = emlComposeGraphTitle.result$
    endif
    prev_autoTitle$ = emlComposeGraphTitle.result$
    # Pre-fill the Title field for the next pass through the form, so a Redraw
    # shows the composed title as editable text rather than an empty box.
    prev_title$ = title$

    # =================================================================
    # PRE-DISPATCH: universal frame measurement
    # =================================================================
    @emlMeasureGraphLayout: figure_width, figure_height, title$, x_axis_label$, y_axis_label$

    # =================================================================
    # DISPATCH (DRAW)
    # =================================================================

    Erase all
    @emlResetDrawnExtent
    Select outer viewport: 0, figure_width, 0, totalCanvasHeight

    if graph_type = 1
        @emlDrawF0Contour: objectId, title$, x_axis_label$, y_axis_label$, figure_width, figure_height, colorMode$, gridline_mode, timeMin, timeMax, freqMin, freqMax, f0YUnit

    elsif graph_type = 2
        @emlDrawWaveform: objectId, title$, x_axis_label$, y_axis_label$, figure_width, figure_height, colorMode$, gridline_mode, timeMin, timeMax, ampMin, ampMax

    elsif graph_type = 3
        @emlDrawSpectrum: objectId, title$, x_axis_label$, y_axis_label$, figure_width, figure_height, colorMode$, gridline_mode, freqMin, freqMax, powerMin, powerMax

    elsif graph_type = 4
        @emlDrawLTAS: objectId, title$, x_axis_label$, y_axis_label$, figure_width, figure_height, colorMode$, gridline_mode, freqMin, freqMax, powerMin, powerMax, ltasShowCurve, ltasShowBars, ltasShowPoles, ltasShowSpeckles

    elsif graph_type = 5
        if tsShowCI = 1
            @emlDrawTimeSeriesCI: objectId, title$, x_axis_label$, y_axis_label$, figure_width, figure_height, colorMode$, gridline_mode, timeColName$, valueColName$, groupColName$, timeMin, timeMax, valueMin, valueMax
        else
            @emlDrawTimeSeries: objectId, title$, x_axis_label$, y_axis_label$, figure_width, figure_height, colorMode$, gridline_mode, timeColName$, valueColName$, groupColName$, timeMin, timeMax, valueMin, valueMax
        endif

    elsif graph_type = 6
        @emlDrawBarChart: objectId, title$, x_axis_label$, y_axis_label$, figure_width, figure_height, colorMode$, gridline_mode, groupColName$, valueColName$, errorBarMode, errorColName$, valueMin, valueMax

    elsif graph_type = 7
        @emlDrawViolinPlot: objectId, title$, x_axis_label$, y_axis_label$, figure_width, figure_height, colorMode$, gridline_mode, groupColName$, valueColName$, valueMin, valueMax

    elsif graph_type = 8
        @emlDrawScatterPlot: objectId, title$, x_axis_label$, y_axis_label$, figure_width, figure_height, colorMode$, gridline_mode, scatterXCol$, scatterYCol$, scatterGroupCol$, scatterXMin, scatterXMax, valueMin, valueMax, annotate

    elsif graph_type = 9
        @emlDrawBoxPlot: objectId, title$, x_axis_label$, y_axis_label$, figure_width, figure_height, colorMode$, gridline_mode, groupColName$, valueColName$, valueMin, valueMax

    elsif graph_type = 10
        @emlDrawHistogram: objectId, title$, x_axis_label$, y_axis_label$, figure_width, figure_height, colorMode$, gridline_mode, histValueCol$, histGroupCol$, histBinCount, histDisplayMode, valueMin, valueMax, histFreqMax

    elsif graph_type = 11
        @emlDrawGroupedViolin: objectId, title$, x_axis_label$, y_axis_label$, figure_width, figure_height, colorMode$, gridline_mode, gvCatCol$, gvSubCol$, gvValueCol$, valueMin, valueMax

    elsif graph_type = 12
        @emlDrawGroupedBoxPlot: objectId, title$, x_axis_label$, y_axis_label$, figure_width, figure_height, colorMode$, gridline_mode, gbCatCol$, gbSubCol$, gbValueCol$, valueMin, valueMax

    elsif graph_type = 13
        @emlDrawSpaghettiPlot: objectId, title$, x_axis_label$, y_axis_label$, figure_width, figure_height, colorMode$, gridline_mode, spCondCol$, spValueCol$, spSubjectCol$, spGroupCol$, spShowMean, valueMin, valueMax
    endif

    # =================================================================
    # POST-DISPATCH: draw annotations
    # =================================================================
    # The drawing procedure has drawn data, gridlines, and axes in a
    # single coordinate system (including any headroom). We now draw
    # brackets or text in that same coordinate system, then render
    # the comparison matrix panel below the plot if needed.

    if annotate = 1
        # --- Read axis ranges from the procedure that just ran ---
        annotXMin = 0
        annotXMax = 1
        annotYMin = valueMin
        annotYMax = valueMax
        if graph_type = 6
            annotXMin = emlDrawBarChart.axisXMin
            annotXMax = emlDrawBarChart.axisXMax
        elsif graph_type = 7
            annotXMin = emlDrawViolinPlot.axisXMin
            annotXMax = emlDrawViolinPlot.axisXMax
        elsif graph_type = 9
            annotXMin = emlDrawBoxPlot.axisXMin
            annotXMax = emlDrawBoxPlot.axisXMax
        elsif graph_type = 11
            annotXMin = emlDrawGroupedViolin.axisXMin
            annotXMax = emlDrawGroupedViolin.axisXMax
            annotYMin = emlDrawGroupedViolin.axisYMin
            annotYMax = emlDrawGroupedViolin.axisYMax
        elsif graph_type = 12
            annotXMin = emlDrawGroupedBoxPlot.axisXMin
            annotXMax = emlDrawGroupedBoxPlot.axisXMax
            annotYMin = emlDrawGroupedBoxPlot.axisYMin
            annotYMax = emlDrawGroupedBoxPlot.axisYMax
        endif

        # --- BRACKET ANNOTATIONS (nGroups <= 3, no matrix) ---
        if annotBracketN > 0 or (annotTextN > 0 and annotMatrixN = 0)
            annotYRange = valueMax - valueMin

            # Route omnibus to corner block (only when NO matrix panel —
            # matrix panel renders its own omnibus as the title line)
            if annotTextN > 0
                annotBlockN = annotBlockN + 1
                annotBlockLabel$[annotBlockN] = annotTextLabel$[1]
                annotBlockDraw$[annotBlockN] = annotTextLabel$[1]
                annotTextN = 0
            endif

            # Draw brackets
            if annotBracketN > 0
                @emlDrawAnnotations: annotXMin, annotXMax, dataYMax_forAnnotation, annotYRange, "{0.3, 0.3, 0.3}", emlSetAdaptiveTheme.annotSize
            endif

            # Draw omnibus in bottom-right (clear of bracket headroom)
            if annotBlockN > 0
                if annotBracketN > 0
                    omnibusCorner$ = "bottom-right"
                else
                    omnibusCorner$ = "top-right"
                endif
                @emlDrawAnnotationBlock: omnibusCorner$, annotXMin, annotXMax, valueMin, valueMax, emlSetAdaptiveTheme.annotSize
            endif
        endif

        # --- MATRIX PANEL (nGroups >= 4, or type 11) ---
        if annotMatrixN > 0 and matrixPanelHeight > 0
            # Draw panel below the plot — match graph inner box width
            @emlDrawMatrixPanel: 0, figure_width, figure_height + matrixGap, totalCanvasHeight, emlSetAdaptiveTheme.matrixSize, colorMode$
        endif
    endif

    # Assert full viewport so save captures entire figure + panel
    @emlAssertFullViewport

    # Clean up melt table if created (wide-format time series)
    if tsMeltTableId > 0
        removeObject: tsMeltTableId
        objectId = tsOrigObjectId
        tsMeltTableId = 0
    endif

    # Track which graph type was drawn for range persistence
    lastDrawnGraphType = graph_type

    # =================================================================
    # POST-DRAW OPTIONS
    # =================================================================

    postDrawDone = 0
    repeat
        beginPause: "Graph Complete"
            comment: "📊 Graph has been drawn in the Picture window."
            comment: "What would you like to do?"
        # --- Conditional button set ---
        if emlCSV_n > 0
            clicked = endPause: "Done", "Save", "Exp CSV", "Redraw", 4, 0
        else
            clicked = endPause: "Done", "Save", "Redraw", 3, 0
            # Normalize: no Exp CSV, shift Redraw (3->4)
            if clicked = 3
                clicked = 4
            endif
        endif

        if clicked = 1
            # Done — exit loop
            keepGoing = 0
            postDrawDone = 1

        elsif clicked = 2
            # Save to file
            # Auto-generate filename from table name + graph type
            saveAutoName$ = contextObjectName$
            ... + "_" + graphTypeName$[graph_type]
            # Strip parenthetical content
            saveParenIdx = index (saveAutoName$, "(")
            if saveParenIdx > 1
                saveAutoName$ = left$ (saveAutoName$, saveParenIdx - 1)
            endif
            # Replace spaces and trim trailing underscores
            saveAutoName$ = replace$ (saveAutoName$, " ", "_", 0)
            while endsWith (saveAutoName$, "_")
                saveAutoName$ = left$ (saveAutoName$, length (saveAutoName$) - 1)
            endwhile
            # Default folder from last save or home directory
            if config_lastPNGFolder$ <> ""
                saveDefaultFolder$ = config_lastPNGFolder$
            else
                saveDefaultFolder$ = defaultDirectory$
            endif
            beginPause: "Save Figure"
                folder: "Output folder", saveDefaultFolder$
                word: "File name", saveAutoName$
            saveClicked = endPause: "Go Back", "Save", 2, 1
            if saveClicked = 2
                # Strip trailing slash from folder path
                while endsWith (output_folder$, "/")
                    output_folder$ = left$ (output_folder$, length (output_folder$) - 1)
                endwhile
                outputPath$ = output_folder$ + "/" + file_name$ + ".png"

                # Non-destructive check
                if fileReadable (outputPath$)
                    @emlGenerateUniquePath: outputPath$
                    outputPath$ = emlGenerateUniquePath.result$
                endif

                @emlAssertFullViewport
                if output_DPI = 1
                    Save as 300-dpi PNG file: outputPath$
                else
                    Save as 600-dpi PNG file: outputPath$
                endif
                config_lastPNGFolder$ = output_folder$

                appendInfoLine: ""
                appendInfoLine: "Saved to: " + outputPath$

                beginPause: "Save Complete"
                    comment: "Saved to: " + outputPath$
                endPause: "OK", 1, 0
            endif
            # Go Back or save complete — loop continues to main dialog

        elsif clicked = 3
            # Exp CSV (only shown when emlCSV_n > 0, i.e. stats
            # results exist in the buffer — from bridge or wrapper)
            # Use originalSourceId — always the Table, even if user
            # switched to an acoustic graph type during this workflow.
            selectObject: originalSourceId
            # D18 + D65 (filename half). originalSourceId is only the fallback
            # now: for the paired workflow it is the `pairedLong` intermediate,
            # not the table the user named. @emlGraphsCSVDefaultName prefers the
            # source table the CSV rows themselves carry, and appends the
            # analysis slug so two analyses on one table cannot propose one
            # name. See the procedure header for what it deliberately does NOT
            # fix (D65's test-family half).
            @emlGraphsCSVDefaultName: selected$ ("Table")
            csvDefaultName$ = emlGraphsCSVDefaultName.result$
            beginPause: "Export Results"
                folder: "Output folder", config_lastCSVFolder$
                word: "File name", csvDefaultName$
            csvClicked = endPause: "Go Back", "Save", 2, 1
            if csvClicked = 2
                # Strip trailing slash from folder path
                while endsWith (output_folder$, "/")
                    output_folder$ = left$ (output_folder$, length (output_folder$) - 1)
                endwhile
                csvPath$ = output_folder$ + "/" + file_name$ + ".csv"
                if fileReadable (csvPath$)
                    @emlGenerateUniquePath: csvPath$
                    csvPath$ = emlGenerateUniquePath.result$
                endif
                @emlExportStatsCSV: csvPath$
                config_lastCSVFolder$ = output_folder$
                if emlExportStatsCSV.success
                    beginPause: "Export Complete"
                        comment: "Saved to: " + emlExportStatsCSV.actualPath$
                    endPause: "OK", 1, 0
                else
                    beginPause: "Export Failed"
                        comment: "Could not write CSV file."
                    endPause: "OK", 1, 0
                endif
            endif
            # Stay in post-draw loop (don't set postDrawDone)

        elsif clicked = 4
            # Redraw
            keepGoing = 1
            # Clear context lock so user can switch graph types freely
            contextGraphType = 0
            contextObjectId = 0
            # Remove auto-created object and restore original source
            if loadedObjectId > 0
                selectObject: loadedObjectId
                Remove
                loadedObjectId = 0
            endif
            if originalSourceId > 0
                selectObject: originalSourceId
                @emlDetectContext
                @emlBuildFilteredMenu
            endif
            postDrawDone = 1
        endif

    until postDrawDone = 1

until keepGoing = 0

    # --- Save config ---
    @emlSaveConfig

    # --- Cleanup ---
    if loadedObjectId > 0
        selectObject: loadedObjectId
        Remove
    endif

    # --- Clear presets ---
    # X/Y are cleared here as well as in the scatter page: they are consumed
    # only by scatter, so a caller that seeded them and then had the user pick
    # a non-scatter graph type left them set for the next workflow call.
    emlGraphsPresetType = 0
    emlGraphsPresetDataCol$ = ""
    emlGraphsPresetGroupCol$ = ""
    emlGraphsPresetSubgroupCol$ = ""
    emlGraphsPresetTestType$ = ""
    emlGraphsPresetAnnotate = 0
    emlGraphsPresetXCol$ = ""
    emlGraphsPresetYCol$ = ""
    emlGraphsPresetRegressionLine = 0
    emlGraphsPresetAnalysisType = 0
    emlGraphsPresetCorrType$ = ""
    emlGraphsPresetCorrection$ = ""
    emlGraphsPresetDotSize = 0
    emlGraphsPresetShowDots = -1

    # --- D103: clear the scatter preset sentinels ---
    # These say "a wrapper supplied this setting for THIS call". Leaving one
    # set would make the next call's dialog defaults ignore the user's own
    # remembered choice, which is the mirror image of the bug they fix.
    scatterPresetHasRegression = 0
    scatterPresetHasDotSize = 0
    scatterPresetHasDots = 0
    scatterPresetHasGroup = 0

    # --- D102: restore the explanation gate ---
    # Raised at the top of this procedure for the graphs path only. It is a
    # global, so leaving it raised made every later analysis report in the
    # session verbose and made report content depend on draw order. The gate
    # goes back to the default declared in stats/eml-output.praat, not to a
    # literal written out here.
    @emlResetExplanations
endproc
