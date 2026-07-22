# ============================================================================
# EML Table Editor
# ============================================================================
# Purpose: Interactive cell editor for Praat Table objects. Provides
#          click-to-navigate cell editing with auto-advance, plus
#          structural operations (add/insert/delete rows and columns,
#          rename columns). Compensates for the read-only TableEditor.
#
# Date: 11 April 2026
# Version: 2.0
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: [Your name here] — created and verified by this individual
#
# RESEARCH USE DISCLOSURE
# If this script is used in research or publication, disclose AI use
# per your target journal's policy. Suggested language:
#
#   "Acoustic analysis scripts were developed using the EML Praat
#    Assistant (Howell, Embodied Music Lab) with code generation
#    by Claude 4.6 Extended Thinking (Anthropic). All scripts were
#    reviewed, tested, and validated by [your name]."
#
# The script author assumes responsibility for the correctness and
# appropriate application of this code.
# ============================================================================

# ── Entry point detection ────────────────────────────────────────────────
# Default "editor" = launched from TableEditor menu (no args).
# Launcher passes "button" = launched from Objects window action button.

form: "EML Table Editor"
    word: "Entry", "editor"
endform

# ── Acquire Table ─────────────────────────────────────────────────────────

# Exit editor environment if launched from TableEditor menu.
# No-op (harmless) when launched from Objects window dynamic button.
nocheck endeditor

nTables = numberOfSelected ("Table")
if nTables <> 1
    exitScript: "Select exactly one Table object."
endif
tableId = selected ("Table")
tableName$ = selected$ ("Table")
displayName$ = replace$ (tableName$, "_", " ", 0)

# ── Initialize loop state ────────────────────────────────────────────────

prevCol = 1
prevRow = 1
prevFind$ = ""
prevReplace$ = ""
prevScope = 1
prevMatch = 1
prevAction = 1

# ── Main loop ────────────────────────────────────────────────────────────

running = 1
while running

    # Refresh dimensions and column names each iteration
    selectObject: tableId
    nRows = Get number of rows
    nCols = Get number of columns

    if nCols < 1
        # Table has no columns — structure-only mode
        beginPause: "EML Table Editor — " + displayName$
            comment: "Table has no columns. Add a column to begin editing."
        clicked = endPause: "Quit", "Add Column", 2, 0

        if clicked = 1
            running = 0
        elsif clicked = 2
            beginPause: "Add Column"
                sentence: "Column name", "newcolumn"
            clicked2 = endPause: "Go Back", "Add", 2, 0
            if clicked2 = 2
                selectObject: tableId
                Append column: column_name$
            endif
        endif

    elsif nRows < 1
        # Table has columns but no rows — structure-only mode
        # Snapshot column names (fix unlabeled columns)
        for iCol from 1 to nCols
            selectObject: tableId
            colName$[iCol] = Get column label: iCol
            if colName$[iCol] = ""
                colName$[iCol] = "Column_" + string$ (iCol)
                selectObject: tableId
                Rename column (by number): iCol, colName$[iCol]
            endif
        endfor

        beginPause: "EML Table Editor — " + displayName$
            comment: displayName$ + ": 0 rows x " + string$ (nCols) + " columns"
            comment: "Table has no rows. Add a row to begin editing."
        clicked = endPause: "Quit", "Edit", 2, 0

        if clicked = 1
            running = 0
        elsif clicked = 2
            @structureDialog
        endif

    else
        # Normal editing mode — table has rows and columns

        # Snapshot column names (fix unlabeled columns)
        for iCol from 1 to nCols
            selectObject: tableId
            colName$[iCol] = Get column label: iCol
            if colName$[iCol] = ""
                colName$[iCol] = "Column_" + string$ (iCol)
                selectObject: tableId
                Rename column (by number): iCol, colName$[iCol]
            endif
        endfor

        # Clamp prev values to valid range
        if prevCol > nCols
            prevCol = nCols
        endif
        if prevRow > nRows
            prevRow = nRows
        endif
        if prevRow < 1
            prevRow = 1
        endif

        # Read current cell value for prepopulation
        selectObject: tableId
        currentValue$ = Get value: prevRow, colName$[prevCol]

        # Main editing dialog
        beginPause: "EML Table Editor — " + displayName$
            comment: displayName$ + ": "
            ... + string$ (nRows) + " rows x "
            ... + string$ (nCols) + " columns"
            optionmenu: "Column", prevCol
                for iCol from 1 to nCols
                    option: colName$[iCol]
                endfor
            optionmenu: "Row", prevRow
                for iRow from 1 to nRows
                    option: string$ (iRow)
                endfor
            sentence: "Value", currentValue$
        clicked = endPause: "Quit", "Read", "Set", "Find...", "Edit", 3, 0

        if clicked = 1
            # Quit
            running = 0

        elsif clicked = 2
            # Read — navigate to selected cell, re-loop to show its value
            prevCol = column
            prevRow = row

        elsif clicked = 3
            # Set — write value to cell, then auto-advance row
            selectObject: tableId
            Set string value: row, colName$[column], value$
            prevCol = column
            prevRow = min (row + 1, nRows)

        elsif clicked = 4
            # Find/Replace sub-dialog
            prevCol = column
            prevRow = row
            @findReplaceDialog

        elsif clicked = 5
            # Structure sub-dialog
            prevCol = column
            prevRow = row
            @structureDialog
        endif
    endif
endwhile

# ── Close TableEditor if launched from Objects window button ──────────────

if entry$ = "button"
    nocheck editor: "Table " + tableName$
    nocheck Close
endif

# ============================================================================
# PROCEDURE: Find/Replace sub-dialog
# ============================================================================

procedure findReplaceDialog

    .running = 1
    while .running

        selectObject: tableId
        .nRows = Get number of rows
        .nCols = Get number of columns

        # Refresh column names
        for .iCol from 1 to .nCols
            selectObject: tableId
            colName$[.iCol] = Get column label: .iCol
            if colName$[.iCol] = ""
                colName$[.iCol] = "Column_" + string$ (.iCol)
                selectObject: tableId
                Rename column (by number): .iCol, colName$[.iCol]
            endif
        endfor

        beginPause: "Find / Replace"
            sentence: "Find text", prevFind$
            sentence: "Replace with", prevReplace$
            optionmenu: "Scope", prevScope
                option: "All columns"
                for .iCol from 1 to .nCols
                    option: colName$[.iCol]
                endfor
            optionmenu: "Match type", prevMatch
                option: "Contains"
                option: "Exact"
        .clicked = endPause: "Go Back", "Find", "Fnd Nxt", "Rep Nxt", "Rep All", 3, 0

        if .clicked = 1
            .running = 0
        elsif find_text$ = ""
            # Empty search — stay in dialog
        else
            # Save state for repopulation
            prevFind$ = find_text$
            prevReplace$ = replace_with$
            prevScope = scope
            prevMatch = match_type

            if .clicked >= 2 and .clicked <= 4
                .found = 0

                if .clicked = 2
                    .startRow = 1
                    .startCol = 1
                else
                    .startRow = prevRow
                    .startCol = prevCol
                endif

                if scope = 1
                    .totalCells = .nRows * .nCols
                    for .offset from 1 to .totalCells
                        if .found = 0
                            if .clicked = 2
                                .linearIdx = (.offset - 1) mod .totalCells
                            else
                                .linearIdx = ((.startRow - 1) * .nCols + (.startCol - 1) + .offset) mod .totalCells
                            endif
                            .checkRow = (.linearIdx div .nCols) + 1
                            .checkCol = (.linearIdx mod .nCols) + 1
                            selectObject: tableId
                            .cellVal$ = Get value: .checkRow, colName$[.checkCol]
                            if match_type = 1
                                if index (.cellVal$, find_text$) > 0
                                    .found = 1
                                    prevRow = .checkRow
                                    prevCol = .checkCol
                                endif
                            else
                                if .cellVal$ = find_text$
                                    .found = 1
                                    prevRow = .checkRow
                                    prevCol = .checkCol
                                endif
                            endif
                        endif
                    endfor
                else
                    .scopeCol = scope - 1
                    for .offset from 1 to .nRows
                        if .found = 0
                            if .clicked = 2
                                .checkRow = ((.offset - 1) mod .nRows) + 1
                            else
                                .checkRow = ((.startRow - 1 + .offset) mod .nRows) + 1
                            endif
                            selectObject: tableId
                            .cellVal$ = Get value: .checkRow, colName$[.scopeCol]
                            if match_type = 1
                                if index (.cellVal$, find_text$) > 0
                                    .found = 1
                                    prevRow = .checkRow
                                    prevCol = .scopeCol
                                endif
                            else
                                if .cellVal$ = find_text$
                                    .found = 1
                                    prevRow = .checkRow
                                    prevCol = .scopeCol
                                endif
                            endif
                        endif
                    endfor
                endif

                if .found = 0
                    beginPause: "Find"
                        comment: "No match found for """ + find_text$ + """."
                    endPause: "OK", 1, 0
                else
                    .displayCol$ = replace$ (colName$[prevCol], "_", " ", 0)
                    if .clicked = 4
                        selectObject: tableId
                        .cellVal$ = Get value: prevRow, colName$[prevCol]
                        if match_type = 1
                            .newVal$ = replace$ (.cellVal$, find_text$, replace_with$, 0)
                        else
                            .newVal$ = replace_with$
                        endif
                        selectObject: tableId
                        Set string value: prevRow, colName$[prevCol], .newVal$
                        beginPause: "Rep Nxt"
                            comment: "Replaced at column """ + .displayCol$ + """, row " + string$ (prevRow) + "."
                            comment: "New value: " + .newVal$
                        endPause: "OK", 1, 0
                    else
                        selectObject: tableId
                        .foundVal$ = Get value: prevRow, colName$[prevCol]
                        beginPause: "Found"
                            comment: "Column: " + .displayCol$ + ",  Row: " + string$ (prevRow)
                            comment: "Value: " + .foundVal$
                        endPause: "OK", 1, 0
                    endif
                endif

            elsif .clicked = 5
                .count = 0

                if scope = 1
                    .colStart = 1
                    .colEnd = .nCols
                else
                    .colStart = scope - 1
                    .colEnd = scope - 1
                endif

                for .iCol from .colStart to .colEnd
                    for .iRow from 1 to .nRows
                        selectObject: tableId
                        .cellVal$ = Get value: .iRow, colName$[.iCol]
                        if match_type = 1
                            if index (.cellVal$, find_text$) > 0
                                .newVal$ = replace$ (.cellVal$, find_text$, replace_with$, 0)
                                selectObject: tableId
                                Set string value: .iRow, colName$[.iCol], .newVal$
                                .count = .count + 1
                            endif
                        else
                            if .cellVal$ = find_text$
                                selectObject: tableId
                                Set string value: .iRow, colName$[.iCol], replace_with$
                                .count = .count + 1
                            endif
                        endif
                    endfor
                endfor

                beginPause: "Rep All"
                    comment: "Replaced " + string$ (.count) + " cell(s)."
                endPause: "OK", 1, 0
            endif
        endif
    endwhile
endproc

# ============================================================================
# PROCEDURE: Structure sub-dialog
# ============================================================================

procedure structureDialog

    selectObject: tableId
    .nRows = Get number of rows
    .nCols = Get number of columns

    beginPause: "Table Structure"
        comment: displayName$ + ": "
        ... + string$ (.nRows) + " rows x "
        ... + string$ (.nCols) + " columns"
        optionmenu: "Action", prevAction
            option: "Add row at end"
            option: "Insert row after..."
            option: "Delete row..."
            option: "Add column at end..."
            option: "Insert column at..."
            option: "Delete column..."
            option: "Rename column..."
    .clicked = endPause: "Go Back", "Next", 2, 0

    if .clicked = 2
        prevAction = action

        if action = 1
            # Add row at end
            selectObject: tableId
            Append row
            nRows = nRows + 1
            prevRow = nRows

        elsif action = 2
            # Insert row after position
            beginPause: "Insert Row"
                comment: "Table has " + string$ (.nRows) + " rows."
                natural: "After row", prevRow
            .clicked2 = endPause: "Go Back", "Insert", 2, 0
            if .clicked2 = 2
                .pos = min (after_row, .nRows)
                selectObject: tableId
                Insert row: .pos + 1
                nRows = nRows + 1
                prevRow = .pos + 1
            endif

        elsif action = 3
            # Delete row
            if .nRows < 1
                beginPause: "Cannot Delete"
                    comment: "Table has no rows to delete."
                endPause: "OK", 1, 0
            else
                beginPause: "Delete Row"
                    comment: "Table has " + string$ (.nRows) + " rows."
                    natural: "Row number", prevRow
                .clicked2 = endPause: "Go Back", "Delete", 2, 0
                if .clicked2 = 2
                    .target = min (row_number, .nRows)
                    selectObject: tableId
                    Remove row: .target
                    nRows = nRows - 1
                    if prevRow > nRows and nRows > 0
                        prevRow = nRows
                    endif
                endif
            endif

        elsif action = 4
            # Add column at end
            beginPause: "Add Column"
                sentence: "Column name", "newcolumn"
            .clicked2 = endPause: "Go Back", "Add", 2, 0
            if .clicked2 = 2
                selectObject: tableId
                Append column: column_name$
                nCols = nCols + 1
            endif

        elsif action = 5
            # Insert column at position
            beginPause: "Insert Column"
                comment: "Table has " + string$ (.nCols) + " columns."
                natural: "At position", prevCol
                sentence: "Column name", "newcolumn"
            .clicked2 = endPause: "Go Back", "Insert", 2, 0
            if .clicked2 = 2
                .pos = min (at_position, .nCols + 1)
                selectObject: tableId
                Insert column: .pos, column_name$
                nCols = nCols + 1
                prevCol = .pos
            endif

        elsif action = 6
            # Delete column
            if .nCols < 1
                beginPause: "Cannot Delete"
                    comment: "Table has no columns to delete."
                endPause: "OK", 1, 0
            else
                # Refresh column names for the optionmenu
                for .iCol from 1 to .nCols
                    selectObject: tableId
                    .colLabel$[.iCol] = Get column label: .iCol
                    if .colLabel$[.iCol] = ""
                        .colLabel$[.iCol] = "Column_" + string$ (.iCol)
                        selectObject: tableId
                        Rename column (by number): .iCol, .colLabel$[.iCol]
                    endif
                endfor
                beginPause: "Delete Column"
                    optionmenu: "Column to delete", prevCol
                        for .iCol from 1 to .nCols
                            option: .colLabel$[.iCol]
                        endfor
                .clicked2 = endPause: "Go Back", "Delete", 2, 0
                if .clicked2 = 2
                    selectObject: tableId
                    Remove column: column_to_delete$
                    nCols = nCols - 1
                    if prevCol > nCols and nCols > 0
                        prevCol = nCols
                    endif
                endif
            endif

        elsif action = 7
            # Rename column
            if .nCols < 1
                beginPause: "Cannot Rename"
                    comment: "Table has no columns to rename."
                endPause: "OK", 1, 0
            else
                # Refresh column names for the optionmenu
                for .iCol from 1 to .nCols
                    selectObject: tableId
                    .colLabel$[.iCol] = Get column label: .iCol
                    if .colLabel$[.iCol] = ""
                        .colLabel$[.iCol] = "Column_" + string$ (.iCol)
                        selectObject: tableId
                        Rename column (by number): .iCol, .colLabel$[.iCol]
                    endif
                endfor
                beginPause: "Rename Column"
                    optionmenu: "Column to rename", prevCol
                        for .iCol from 1 to .nCols
                            option: .colLabel$[.iCol]
                        endfor
                    sentence: "New name", ""
                .clicked2 = endPause: "Go Back", "Rename", 2, 0
                if .clicked2 = 2
                    if new_name$ <> ""
                        selectObject: tableId
                        Rename column (by number): column_to_rename, new_name$
                    endif
                endif
            endif
        endif
    endif
endproc
