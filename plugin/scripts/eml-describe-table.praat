# ============================================================================
# EML Praat Tools — Describe Table Column
# ============================================================================
# Purpose: Descriptive statistics for one numeric column of a Table.
#          Reports n, mean, SD, SEM, median, Q1/Q3/IQR, range,
#          skewness, kurtosis, and 95% CI via the Info window, and offers
#          the same Save step every other wrapper offers.
# Date: 15 August 2026
# Version: 2.0
#
# v2.0 — three changes, one file. The
#        Matrix/TableOfReal pathways are to be MADE OPERABLE, not
#        unregistered. "Dead doors are worse than absent features — they
#        teach users the plugin crashes."
#
#   1. THE TABLE-ONLY REFUSAL IS GONE. setup.praat registers
#      "EML: Describe column..." on Table, TableOfReal AND Matrix, and this
#      file answered two of those three with
#
#          exitScript: "Please select exactly one Table object..."
#
#      on its own line 36 — its own refusal, written before the shared
#      coercion existed, and reached BEFORE @emlWrapperInit, which is where
#      every sibling wrapper gets its TableOfReal and Matrix support. Two
#      registered buttons that could never open their dialog. The refusal is
#      replaced by @emlDescribeCoerceSelection + @emlWrapperInit: 1, so this
#      wrapper now enters through the same door as the other eight and a
#      selection this plugin cannot use is refused ONCE, in the shared place,
#      with the shared wording.
#
#   2. DEFAULT ROW LABELS AT CONVERSION TIME (mechanism). Praat's
#      `To Table: "row"` writes the literal "?" into the row-label column for
#      every row whose label is empty — which is EVERY row of a Matrix, and
#      every row of a TableOfReal the user never labelled. "?" is Praat's
#      rendering of undefined, and downstream @eml_strictNumericColumn
#      (stats/eml-extract.praat:878) scans only for "" and "--undefined--"
#      before it runs the un-nocheck'd `Get all numbers in column:`, so the
#      probe raises natively:
#
#          Table "eml_numericProbe": the cell in row 1 of column "row"
#          is undefined.
#
#      That is why a LABELLED TableOfReal has always worked and an unlabelled
#      one has always died — the qualifier that hid this for months. The
#      coercion below fills those cells with r1..rn before anything reads
#      them. They are labels, not data: "r1" is not numeric, so the row
#      column is classified as a label column and stays out of this dialog's
#      column menu, which is what it is.
#
#      SCOPE. This is the conversion side, and it is applied
#      HERE because this wrapper owns its own coercion step. The other six
#      TableOfReal/Matrix registrations convert inside @emlWrapperInit
#      (stats/eml-output.praat:1405-1439), which still writes "?" — the same
#      three lines belong there, and until they land those six still die on
#      the probe. validate/v59_entry_points.R enumerates all eleven and says
#      which.
#
#   3. THE NAME IS UNAMBIGUOUS BEFORE ANYTHING CAN FAIL. The
#      converted Table must not inherit the source object's name, or a crash
#      that beat the cleanup left "Table coercetor" sitting beside
#      "TableOfReal coercetor" and the user's next selection was a coin
#      flip. Renaming cannot be done in a cleanup handler — the whole point
#      is that the cleanup does not run. It is done at CREATION, on the line
#      after the conversion, before any procedure that can raise is called,
#      so the object is unambiguous even when the session dies one line
#      later.
#
#   4. THE MISSING EXPORT STEP. This was the only wrapper with no Save
#      button, no Clear-Info field and no completion dialog: results appeared
#      only if the Info window happened to be visible, and stacked under
#      whatever was already there. Every path
#      through every approach must reach the export step. It now runs the
#      shipped orchestrator @emlRunDescriptiveAnalysis — which fills the
#      legacy CSV buffer, and which this file was already duplicating — and
#      ends on a Done | Save | New page, the same row the wizard's own
#      single-column Describe page uses (eml-wizard.praat:1950). No Draw:
#      the wizard's describe page does not offer one either, and inventing a
#      figure type for it is a design decision, not a defect fix.
#
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

# eml-lib-stats.praat was enough while this file did its own arithmetic and
# printed its own report. It is not enough now: @emlRunDescriptiveAnalysis
# lives in stats/eml-analysis.praat and @emlCleanConvertedTable in the graphs
# layer, and eml-lib.praat is the one include that carries both — the same
# line every other analysis wrapper opens with.
include eml-lib.praat

# ── Coercion: TableOfReal and Matrix reach this wrapper too ────────────────

@emlDescribeCoerceSelection
@emlWrapperInit: 1
tableId = emlWrapperInit.tableId
tableName$ = emlWrapperInit.tableName$
nCols = emlWrapperInit.nCols
displayTable$ = replace$ (tableName$, "_", " ", 0)

# ── Filter to numeric columns ──────────────────────────────────────────────
#
# Unchanged in substance: a column counts as numeric if its first non-empty
# cell in the first five rows reads as a number. It is also what keeps the
# converted row-label column out of the menu — "r1" is not a number in any
# locale, so the labels this wrapper's own coercion writes classify as
# labels, which is the whole reason they are written as r1..rn rather than
# as bare row numbers.

selectObject: tableId
nRows = Get number of rows
nNumericCols = 0
for iCol from 1 to nCols
    .colName$ = emlTableColumnNames.name$ [iCol]
    .isNumeric = 0
    for iRow from 1 to min (nRows, 5)
        selectObject: tableId
        .val$ = Get value: iRow, .colName$
        if .val$ <> "" and .val$ <> "--undefined--"
            if number (.val$) <> undefined
                .isNumeric = 1
            endif
            iRow = nRows + 1
        endif
    endfor
    if .isNumeric
        nNumericCols = nNumericCols + 1
        numericCol$ [nNumericCols] = .colName$
    endif
endfor

if nNumericCols = 0
    # ROUTED THROUGH THE PLUGIN'S ERROR SURFACE, for the reason
    # given at @emlErrorDialog's "entry" mode: a raw `exitScript:` with a
    # message is shown by Praat as an interpreter stack, and this refusal is
    # reachable by a user who has simply selected a table of labels.
    @emlErrorDialog: "Descriptive statistics need a numeric column, and "
    ... + "none of the " + string$ (nCols) + " column(s) in """
    ... + displayTable$ + """ reads as numbers.", "", "entry"
    exitScript: ""
endif

# ── Main loop ──────────────────────────────────────────────────────────────

# Carried across the loop so "New" reopens on the column just described
# Rather than resetting to the first one. (the same reason every other
# wrapper keeps its answers.)
selCol = 1

allDone = 0
repeat

    beginPause: "Describe Table Column"
        comment: "📋 Table: " + displayTable$ + " (" + string$ (nNumericCols)
        ... + " numeric columns, " + string$ (nRows) + " rows)"
        comment: "─────────────────────────────────────"
        optionmenu: "Column", selCol
        for iCol from 1 to nNumericCols
            option: numericCol$ [iCol]
        endfor
        @emlWrapperCommonFields
    clicked = endPause: "Quit", "Run", 2, 0
    if clicked = 1
        allDone = 1
    endif

    if not allDone

    dataColumn$ = column$
    selCol = column
    @emlHandleCommonFields

    # ── Run analysis ───────────────────────────────────────────────────────
    #
    # The report body, the column extraction and the missing-data note used
    # to live here as a second copy of what stats/eml-analysis.praat already
    # does. The v1.0 note above the old @emlReportDescriptiveAnalysis call
    # made half this argument for the report alone; the rest of the copy is
    # retired the same way. The orchestrator also fills the legacy CSV buffer
    # (@emlCSVAddDescriptiveRow) and records a workflow step, neither of
    # which this file did — which is why it had nothing to Save.

    selectObject: tableId
    @emlRunDescriptiveAnalysis: tableId, dataColumn$
    if emlRunDescriptiveAnalysis.error$ <> ""
        # An error must not strand the user on a form the error has
        # just ruled out. Present it with guidance, and honour Quit.
        @emlErrorDialog: emlRunDescriptiveAnalysis.error$,
        ... emlRunDescriptiveAnalysis.remedy$, "menu"
        if not emlErrorDialog.back
            allDone = 1
        endif
    else

        # ── Post-analysis loop ─────────────────────────────────────────────

        runAgain = 0
        repeat
            beginPause: "Analysis complete"
                comment: "📊 Results are in the Info window."
            clicked = endPause: "Done", "Save", "New", 3, 0

            if clicked = 1
                allDone = 1
            elsif clicked = 2
                # 0 = there is no figure here; nothing has been drawn at the
                # end of a descriptive pass.
                @emlSavePanel: 0, tableName$ + "_describe",
                ... emlLastCSVFolder$
                if emlSavePanel.cancelled = 0
                    emlLastCSVFolder$ = emlSavePanel.folder$
                endif
            elsif clicked = 3
                runAgain = 1
            endif
        until allDone or runAgain
    endif

    endif
until allDone


# ============================================================================
# @emlDescribeCoerceSelection
# ============================================================================
# Turn a selected TableOfReal or Matrix into a Table this wrapper can read,
# and leave the Table selected so @emlWrapperInit sees exactly what it sees
# when the user selected a Table in the first place.
#
# WHY IT IS HERE AND NOT IN @emlWrapperInit. It should be in @emlWrapperInit,
# and the three lines that matter — the r1..rn default — belong there for the
# other six TableOfReal/Matrix registrations too. This file cannot reach into
# stats/eml-output.praat, so it does the conversion itself and then hands a
# Table to the shared init, which is the nearest thing to routing through it.
# When the default lands in @emlWrapperInit this procedure collapses to
# nothing and should be deleted rather than left as a second copy.
#
# ANYTHING ELSE IS LEFT ALONE ON PURPOSE. A selection that is not exactly one
# Table, one TableOfReal or one Matrix is not refused here — it is passed
# through untouched so that @emlWrapperInit issues the one refusal the whole
# plugin issues. Two wordings for one condition is how this wrapper acquired
# its own refusal in the first place.
#
# Arguments: none (reads the current selection)
# Outputs:   .converted   1 if a conversion happened
#            .tableId     the resulting Table (0 if nothing was converted)
#            .sourceType$ "TableOfReal" or "Matrix" when .converted = 1
# ============================================================================
procedure emlDescribeCoerceSelection
    .converted = 0
    .tableId = 0
    .sourceType$ = ""
    .sourceName$ = ""

    .nTables = numberOfSelected ("Table")
    .nToR = numberOfSelected ("TableOfReal")
    .nMatrix = numberOfSelected ("Matrix")

    if .nTables = 0 and .nToR = 1 and .nMatrix = 0
        .sourceType$ = "TableOfReal"
        .sourceName$ = selected$ ("TableOfReal")
        .sourceId = selected ("TableOfReal")
        selectObject: .sourceId
        .tableId = To Table: "row"
        .converted = 1

    elsif .nTables = 0 and .nToR = 0 and .nMatrix = 1
        # A Matrix has no row labels at all, so its route to a Table runs
        # through a TableOfReal that has none either. The intermediate is
        # removed on this side of the conversion; the Table persists, because
        # the user's session goes on using it.
        .sourceType$ = "Matrix"
        .sourceName$ = selected$ ("Matrix")
        .sourceId = selected ("Matrix")
        selectObject: .sourceId
        .tempTorId = To TableOfReal
        .tableId = To Table: "row"
        removeObject: .tempTorId
        .converted = 1
    endif

    if .converted
        # NAME IT FIRST. Unnamed, the converted Table carries the
        # source object's name, and a native error anywhere below this line
        # would leave two identically named objects in the list with no
        # cleanup handler ever running. Renaming at creation is the only
        # placement that survives the crash it exists for. Praat replaces
        # spaces with underscores, so the result is a legal object name for
        # any source name.
        selectObject: .tableId
        Rename: "eml_converted_" + .sourceName$

        # THE AUTHOR'S DEFAULT ROW LABELS. Written BEFORE
        # @emlCleanConvertedTable, which would otherwise fill the same cells
        # with bare row numbers — numeric strings, which would put a
        # meaningless 1..n column into every column menu in the plugin as
        # though it were a measurement. r1..rn reads as a label everywhere.
        # Only "?" cells are touched: a TableOfReal the user did label keeps
        # every label it has, including a partially labelled one.
        selectObject: .tableId
        .nRows = Get number of rows
        .nDefaulted = 0
        for .iRow from 1 to .nRows
            selectObject: .tableId
            .cell$ = Get value: .iRow, "row"
            if .cell$ = "?" or .cell$ = ""
                Set string value: .iRow, "row", "r" + string$ (.iRow)
                .nDefaulted = .nDefaulted + 1
            endif
        endfor

        # The rest of the repair is the shared one. It renames the row-label
        # column when a data column is also called "row", and it renames "?"
        # column headers to Column_N — which a Matrix always needs, because
        # every one of its columns arrives called "?" and a table with three
        # identically named columns is the duplicate-label hazard of S1 by
        # another route. Its own "?"-cell pass finds nothing left to do.
        @emlCleanConvertedTable: .tableId

        selectObject: .tableId
        appendInfoLine: "Converted ", .sourceType$, " """, .sourceName$,
        ... """ to Table """, selected$ ("Table"), """."
        if .nDefaulted > 0
            appendInfoLine: "  ", .nDefaulted, " unlabelled row(s) were given "
            ... + "default labels r1..r", .nRows, " in column ""row""."
        endif
        appendInfoLine: ""
    endif
endproc
