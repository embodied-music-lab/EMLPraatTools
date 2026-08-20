# ============================================================================
# EML Table Editor
# ============================================================================
# Purpose: Interactive cell editor for Praat Table objects. Provides
#          click-to-navigate cell editing with auto-advance, plus
#          structural operations (add/insert/delete rows and columns,
#          rename columns). Compensates for the read-only TableEditor.
#
# Date: 15 August 2026
# Version: 2.2
#
# COLUMN ADDRESSING — READ THIS BEFORE CHANGING A COLUMN OPERATION.
#
# Praat's Table API addresses columns BY LABEL: `Remove column: name$`,
# `Get value: row, name$`, `Set string value: row, name$, v$`. This editor's
# menus address them BY POSITION — an optionmenu hands back the index of the
# entry the user clicked. Those two are the same thing only while every label
# in the table is unique, and nothing in Praat enforces that. Measured on
# 6.6.30, 15 August 2026: `Rename column (by number)`, `Append column` and
# `Insert column` all accept a name a sibling column already carries, and a
# CSV read from disk can arrive with duplicates already in it.
#
# Until 15 August 2026 every operation here threw the index away and passed
# the label. With two columns named "colA", picking the second one and
# pressing Delete deleted the FIRST one — silently, with no undo, leaving a
# perfectly well-formed table that says the wrong thing. Cell read, cell
# write, Find and Replace All were all blind to the second duplicate in the
# same way.
#
# The fix has two layers and needs both:
#
#   PREVENTION — @labelInUse gates Rename, Add and Insert, so the duplicate
#   state cannot be created from this editor at all.
#
#   CONTAINMENT — @cellRead, @cellWrite and @columnRemove take an INDEX, not
#   a name, because prevention cannot help a table that already had
#   duplicates when it was opened. Praat 6.6.30 has no positional form of
#   those three commands (checked against pkb/COMMANDS_Table.txt and settled
#   by running every plausible spelling: "Remove column (by number)",
#   "(index)", "(by index)", "Get value (by number)", "Set string value
#   (by number)" are all "not available for current selection"). The one
#   positional command Table does have is `Rename column (by number)`, so
#   @colLock uses it to give the target column a private, provably unused
#   name for the length of one operation and puts the original name back
#   afterwards. @colLock does nothing at all when `Get column index` already
#   resolves the label to the requested index — which is every table without
#   duplicates — so the ordinary case costs one query and mutates nothing.
#
# Anything that reads or writes a cell, or removes a column, must go through
# those three procedures. Adding a bare `Get value:`/`Set string value:`/
# `Remove column:` back into a menu path reopens the defect.
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

# ── Entry point detection ────────────────────────────────────────────────
# Default "editor" = launched from TableEditor menu (no args).
# Launcher passes "button" = launched from Objects window action button.

form: "EML Table Editor"
    word: "Entry", "editor"
endform

# ── Acquire Table ─────────────────────────────────────────────────────────

# Exit editor environment if launched from TableEditor menu.
# No-op (harmless) when launched from Objects window dynamic button.
# INTENTIONAL DEFENSIVE nocheck (policy): correct use for editor teardown —
# do not replace with an existence check (the M4 audit recommendation to do so
# is rejected; nocheck is the intended mechanism).
# nocheck guards exactly ONE command — the one it prefixes. It does not open a
# conditional block. This line is safe because it IS a single command.
nocheck endeditor

nTables = numberOfSelected ("Table")
if nTables <> 1
    # THE EDITOR'S HALF. A raw `exitScript:` with a message is
    # rendered by Praat as its own error window with "Script exited. ...
    # Command ... not executed." underneath — the interpreter's stack shown
    # to a user whose only mistake was selecting two objects. It goes through
    # a dialog of the same shape as @emlErrorDialog's, LOCAL to this file,
    # for the reason set out above @refuseColumnName: this script has never
    # included eml-lib.praat, and pulling in some 26,000 lines of statistics
    # and graphing to reach one refusal dialog is a worse trade than a
    # forty-line local copy. See @refuseSelection.
    @refuseSelection: nTables
    exitScript: ""
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
            @autoLabel: iCol
            colName$[iCol] = autoLabel.name$
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
            @autoLabel: iCol
            colName$[iCol] = autoLabel.name$
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
        @cellRead: prevRow, prevCol
        currentValue$ = cellRead.value$

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
            #
            # THE STALE-VALUE GUARD — READ BEFORE REMOVING IT.
            #
            # A Praat dialog is static: the Value box is filled once, from the
            # cell prevRow/prevCol named when the page was BUILT, and cannot
            # follow the Column and Row menus while the page is open. So a user
            # who picks a different cell and presses Set is looking at the
            # previous cell's contents, and the write would put them into the
            # new cell — silently, with no undo, in a table that stays
            # perfectly well-formed while saying the wrong thing.
            #
            # An untouched box is the whole signal. If the text differs from
            # what was seeded, the user typed it and means it, wherever the
            # menus now point — that write goes through unchanged, so entering
            # a value into a freshly chosen cell still takes one press. Only
            # the unedited box on a moved selection is refused, and the refusal
            # navigates: the next pass shows the chosen cell's real contents.
            if (column <> prevCol or row <> prevRow) and value$ = currentValue$
                beginPause: "Nothing was written"
                    comment: "You chose a different cell without changing the"
                    comment: "Value box, so it still held the previous cell's"
                    comment: "contents. Nothing was written."
                    comment: ""
                    comment: "The box now shows what is in "
                    ... + colName$[column] + ", row " + string$ (row) + "."
                    comment: "Change it and press Set to write."
                endPause: "OK", 1, 0
                prevCol = column
                prevRow = row
            else
                @cellWrite: row, column, value$
                prevCol = column
                prevRow = min (row + 1, nRows)
            endif

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
# INTENTIONAL DEFENSIVE nocheck (policy): the user may have already closed the
# editor window by hand, in which case addressing it (editor:) and Close would
# error. nocheck suppresses that so the script exits cleanly either way. This is
# the correct use of nocheck for editor teardown — do not "fix" it to a bare
# Close or an existence check.
#
# CRITICAL (verified Praat 6.6.30, 2 Aug 2026): "nocheck editor:" suppresses the
# error of the OPENER ONLY — it does NOT skip the block. With no editor open,
# execution still falls into the body and runs it in the object-window context,
# where editor commands are unavailable. This teardown survives only because its
# single inner command is ALSO guarded. Any command added inside this block must
# carry its own nocheck, or the script aborts on exactly the closed-window case
# this guard exists to tolerate.
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
            @autoLabel: .iCol
            colName$[.iCol] = autoLabel.name$
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
                            @cellRead: .checkRow, .checkCol
                            .cellVal$ = cellRead.value$
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
                            @cellRead: .checkRow, .scopeCol
                            .cellVal$ = cellRead.value$
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
                        @cellRead: prevRow, prevCol
                        .cellVal$ = cellRead.value$
                        if match_type = 1
                            .newVal$ = replace$ (.cellVal$, find_text$, replace_with$, 0)
                        else
                            .newVal$ = replace_with$
                        endif
                        @cellWrite: prevRow, prevCol, .newVal$
                        beginPause: "Rep Nxt"
                            comment: "Replaced at column """ + .displayCol$ + """, row " + string$ (prevRow) + "."
                            comment: "New value: " + .newVal$
                        endPause: "OK", 1, 0
                    else
                        @cellRead: prevRow, prevCol
                        .foundVal$ = cellRead.value$
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
                        @cellRead: .iRow, .iCol
                        .cellVal$ = cellRead.value$
                        if match_type = 1
                            if index (.cellVal$, find_text$) > 0
                                .newVal$ = replace$ (.cellVal$, find_text$, replace_with$, 0)
                                @cellWrite: .iRow, .iCol, .newVal$
                                .count = .count + 1
                            endif
                        else
                            if .cellVal$ = find_text$
                                @cellWrite: .iRow, .iCol, replace_with$
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
            # THE NAME IS CHECKED BEFORE THE COLUMN EXISTS. `Append column`
            # accepts a name a sibling already carries (measured, 6.6.30), and
            # the table it leaves behind is the one the Delete defect lives in.
            .pending$ = "newcolumn"
            .again = 1
            while .again
                .again = 0
                beginPause: "Add Column"
                    sentence: "Column name", .pending$
                .clicked2 = endPause: "Go Back", "Add", 2, 0
                if .clicked2 = 2
                    .pending$ = column_name$
                    @labelInUse: column_name$, 0
                    if column_name$ = ""
                        @refuseColumnName: "added", "", 0, 0
                        .again = refuseColumnName.back
                    elsif labelInUse.found
                        @refuseColumnName: "added", column_name$,
                        ... labelInUse.at, labelInUse.total
                        .again = refuseColumnName.back
                    else
                        selectObject: tableId
                        Append column: column_name$
                        nCols = nCols + 1
                    endif
                endif
            endwhile

        elsif action = 5
            # Insert column at position
            .pending$ = "newcolumn"
            .again = 1
            while .again
                .again = 0
                beginPause: "Insert Column"
                    comment: "Table has " + string$ (.nCols) + " columns."
                    natural: "At position", prevCol
                    sentence: "Column name", .pending$
                .clicked2 = endPause: "Go Back", "Insert", 2, 0
                if .clicked2 = 2
                    .pending$ = column_name$
                    .pos = min (at_position, .nCols + 1)
                    @labelInUse: column_name$, 0
                    if column_name$ = ""
                        @refuseColumnName: "inserted", "", 0, 0
                        .again = refuseColumnName.back
                    elsif labelInUse.found
                        @refuseColumnName: "inserted", column_name$,
                        ... labelInUse.at, labelInUse.total
                        .again = refuseColumnName.back
                    else
                        selectObject: tableId
                        Insert column: .pos, column_name$
                        nCols = nCols + 1
                        prevCol = .pos
                    endif
                endif
            endwhile

        elsif action = 6
            # Delete column
            # THE BOUND IS <= 1, NOT < 1. Praat refuses to hold a Table with
            # no columns at all — `Create Table without column names: "t", 3,
            # 0` is rejected as a non-positive count, and `Remove column` on a
            # one-column table raises "cannot remove my only column" and takes
            # the whole session down with it, leaving the read-only
            # TableEditor open behind a dialog that is gone. `< 1`
            # therefore guarded a state that cannot occur and let the state
            # that can occur straight through.
            if .nCols <= 1
                @refuseLastColumn: .nCols
            else
                # Refresh column names for the optionmenu
                for .iCol from 1 to .nCols
                    @autoLabel: .iCol
                    .colLabel$[.iCol] = autoLabel.name$
                endfor
                beginPause: "Delete Column"
                    optionmenu: "Column to delete", prevCol
                        for .iCol from 1 to .nCols
                            option: .colLabel$[.iCol]
                        endfor
                .clicked2 = endPause: "Go Back", "Delete", 2, 0
                if .clicked2 = 2
                    # BY INDEX. The optionmenu's numeric variable is the entry
                    # the user clicked; column_to_delete$ is only its label,
                    # and a label is not an address.
                    @columnRemove: column_to_delete
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
                # THE UNIQUENESS CHECK IS THE PREVENTION LAYER. Before
                # 15 August 2026 the only validation here was non-empty, so
                # renaming a column to a name its neighbour already carried
                # silently produced the duplicate state that made Delete
                # Column destroy the wrong column's data.
                .pending$ = ""
                .again = 1
                while .again
                    .again = 0
                    # Refresh column names for the optionmenu
                    for .iCol from 1 to .nCols
                        @autoLabel: .iCol
                        .colLabel$[.iCol] = autoLabel.name$
                    endfor
                    beginPause: "Rename Column"
                        optionmenu: "Column to rename", prevCol
                            for .iCol from 1 to .nCols
                                option: .colLabel$[.iCol]
                            endfor
                        sentence: "New name", .pending$
                    .clicked2 = endPause: "Go Back", "Rename", 2, 0
                    if .clicked2 = 2
                        # Both selections are kept for the re-display, so a
                        # refusal costs the user a name and not their place.
                        prevCol = column_to_rename
                        .pending$ = new_name$
                        @labelInUse: new_name$, column_to_rename
                        if new_name$ = ""
                            @refuseColumnName: "renamed", "", 0, 0
                            .again = refuseColumnName.back
                        elsif labelInUse.found
                            @refuseColumnName: "renamed", new_name$,
                            ... labelInUse.at, labelInUse.total
                            .again = refuseColumnName.back
                        else
                            selectObject: tableId
                            Rename column (by number): column_to_rename,
                            ... new_name$
                        endif
                    endif
                endwhile
            endif
        endif
    endif
endproc

# ============================================================================
# PROCEDURES: column addressing
# ============================================================================
# Every read, write and removal in this script goes through this section.
# See the COLUMN ADDRESSING note in the file header for why: Praat 6.6.30
# addresses Table columns by label, this editor's menus address them by
# position, and the two agree only while labels are unique.
# ============================================================================

# ────────────────────────────────────────────────────────────────────────────
# @labelInUse: .name$, .exceptIdx
#
# Is .name$ already carried by a column other than .exceptIdx?
# Pass .exceptIdx = 0 when the column does not exist yet (Add, Insert), and
# the index being renamed when it does (Rename) — otherwise renaming a column
# to the name it already has would refuse itself.
#
# Returns:
#   .found — 1 if some other column carries the name, 0 if not.
#   .at    — the index of the first such column, 0 when .found = 0.
#   .total — the table's column count, so a caller can say "column 2 of 4"
#            without asking again.
# ────────────────────────────────────────────────────────────────────────────
procedure labelInUse: .name$, .exceptIdx
    selectObject: tableId
    .total = Get number of columns
    .found = 0
    .at = 0
    for .k from 1 to .total
        if .found = 0 and .k <> .exceptIdx
            selectObject: tableId
            .lab$ = Get column label: .k
            if .lab$ = .name$
                .found = 1
                .at = .k
            endif
        endif
    endfor
endproc


# ────────────────────────────────────────────────────────────────────────────
# @autoLabel: .idx
#
# Give column .idx a usable label if it has none, and hand back whatever its
# label now is. An unlabeled column cannot be shown in an optionmenu and
# cannot be addressed by name at all, so the editor has always named them
# Column_<n> on sight. It now checks that the name it invents is FREE before
# using it: a table whose column 3 is unlabeled and whose column 1 is already
# called "Column_3" would otherwise have been handed a duplicate by the very
# code that exists to make the table addressable.
#
# Returns:
#   .name$ — the column's label, guaranteed non-empty.
# ────────────────────────────────────────────────────────────────────────────
procedure autoLabel: .idx
    selectObject: tableId
    .name$ = Get column label: .idx
    if .name$ = ""
        .stem$ = "Column_" + string$ (.idx)
        .try$ = .stem$
        .suffix = 1
        @labelInUse: .try$, .idx
        while labelInUse.found
            .suffix = .suffix + 1
            .try$ = .stem$ + "_" + string$ (.suffix)
            @labelInUse: .try$, .idx
        endwhile
        .name$ = .try$
        selectObject: tableId
        Rename column (by number): .idx, .name$
    endif
endproc


# ────────────────────────────────────────────────────────────────────────────
# @colLock: .idx  /  @colUnlock
#
# Make column .idx reachable by name for the length of one operation.
#
# `Get column index: label$` returns the FIRST column carrying that label. If
# that is already .idx then a name-addressed command will land on .idx and
# nothing needs to happen — which is every table with unique labels, so the
# ordinary case costs one query and does not touch the object.
#
# When it is not .idx, the column is unreachable by name, and the only
# positional command Table has is `Rename column (by number)`. So the column
# is given a private name that @labelInUse has just proved no column holds,
# the caller does its work by that name, and @colUnlock puts the original
# back. The window between the two is a single Praat command with no dialog
# in it, which is what keeps the sentinel from ever being something a user
# can see.
#
# @colUnlock is not called after a removal: there is nothing left to rename.
#
# Returns (colLock):
#   .name$   — the name to address the column by, for this operation only.
#   .orig$   — the label to restore.
#   .engaged — 1 if a rename happened and @colUnlock is required.
# ────────────────────────────────────────────────────────────────────────────
procedure colLock: .idx
    selectObject: tableId
    .orig$ = Get column label: .idx
    selectObject: tableId
    .first = Get column index: .orig$
    if .first = .idx
        .engaged = 0
        .name$ = .orig$
    else
        .engaged = 1
        .stem$ = "eml_col_lock"
        .try$ = .stem$
        .suffix = 1
        @labelInUse: .try$, .idx
        while labelInUse.found
            .suffix = .suffix + 1
            .try$ = .stem$ + "_" + string$ (.suffix)
            @labelInUse: .try$, .idx
        endwhile
        .name$ = .try$
        selectObject: tableId
        Rename column (by number): .idx, .name$
    endif
endproc

procedure colUnlock
    if colLock.engaged
        selectObject: tableId
        Rename column (by number): colLock.idx, colLock.orig$
        colLock.engaged = 0
    endif
endproc


# ────────────────────────────────────────────────────────────────────────────
# @cellRead: .row, .idx      → .value$
# @cellWrite: .row, .idx, .value$
# @columnRemove: .idx
#
# The three operations the editor performs on a table, all taking the column
# INDEX the user's menu selection produced. Nothing else in this file may call
# `Get value:`, `Set string value:` or `Remove column:` directly.
# ────────────────────────────────────────────────────────────────────────────
procedure cellRead: .row, .idx
    @colLock: .idx
    selectObject: tableId
    .value$ = Get value: .row, colLock.name$
    @colUnlock
endproc

procedure cellWrite: .row, .idx, .value$
    @colLock: .idx
    selectObject: tableId
    Set string value: .row, colLock.name$, .value$
    @colUnlock
endproc

procedure columnRemove: .idx
    @colLock: .idx
    selectObject: tableId
    Remove column: colLock.name$
    colLock.engaged = 0
endproc


# ============================================================================
# PROCEDURES: refusals
# ============================================================================
# These follow the shape of @emlErrorDialog and the singleton-group refusal in
# plugin/stats/eml-inferential.praat — name the thing, give the number, state
# the rule, keep the user's selections, offer Back and Quit — but they are
# local to this script rather than calls into it. eml-edit-table.praat has
# never included eml-lib.praat, and adding the include to reach one dialog
# would load the whole statistics and graphing barrel (some 26,000 lines) into
# a cell editor. If the author would rather these went through @emlErrorDialog
# itself, that is a one-line include and three call changes.
#
# Comments are hand-broken under 60 characters and no comment concatenates a
# variable of unknown length onto a label — APPENDIX_F S0-WRAP: an over-long
# comment wraps into the line below it and corrupts everything under it. User
# column names are therefore truncated by @ellipsize and given a line of
# their own.
# ============================================================================

# ────────────────────────────────────────────────────────────────────────────
# @refuseSelection: .nTables
#
# The editor was opened with something other than exactly one Table selected.
# This is the entry refusal, so it happens before any form exists and there
# is nothing to go Back to: one button, and the script stops after it.
#
# Same shape as @emlErrorDialog's "entry" mode in stats/eml-output.praat --
# name what happened, say what to select, offer one way out -- and
# deliberately NOT a call into it, for the reason given at the head of this
# section. If the author would rather the two were one dialog, the editor
# needs eml-lib.praat and that is a decision about what a cell editor loads,
# not a defect fix.
#
# Comments are hand-broken under 60 characters: APPENDIX_F S0-WRAP.
# ────────────────────────────────────────────────────────────────────────────
procedure refuseSelection: .nTables
    beginPause: "Cannot Open the Table Editor"
        comment: "⚠  The editor did not open."
        comment: "──────────────────────────────────────────────"
        if .nTables = 0
            comment: "No Table object is selected."
        else
            comment: "There are " + string$ (.nTables) + " Table objects"
            comment: "selected, and the editor edits one at a time."
        endif
        comment: ""
        comment: "The editor works on a single Table, because every"
        comment: "cell it writes has to belong to a table it can"
        comment: "name without ambiguity."
        comment: "──────────────────────────────────────────────"
        comment: "Nothing has been changed."
        comment: ""
        comment: "Click OK, select exactly one Table in the"
        comment: "Objects window, then open the editor again."
    .clicked = endPause: "OK", 1, 0
endproc


procedure ellipsize: .s$, .max
    if length (.s$) <= .max
        .out$ = .s$
    else
        .out$ = left$ (.s$, .max - 1) + "…"
    endif
endproc


# ────────────────────────────────────────────────────────────────────────────
# @refuseColumnName: .verb$, .name$, .at, .total
#
# The name a user typed cannot be used. Two reasons reach here: the name is
# empty, or another column already carries it. Pass .name$ = "" for the empty
# case; .at and .total are the offending column's index and the table's column
# count, and are ignored when .name$ is empty.
#
# .verb$ is the past participle of what did not happen — "renamed", "added",
# "inserted" — so the headline names the operation the user actually pressed.
#
# Returns:
#   .back — 1 to re-display the form with the user's selections kept, 0 if
#           the user quit. On Quit the editor's main loop is ended here, so a
#           caller only needs .back to decide whether to loop.
# ────────────────────────────────────────────────────────────────────────────
procedure refuseColumnName: .verb$, .name$, .at, .total
    @ellipsize: .name$, 40
    .shown$ = ellipsize.out$

    beginPause: "Cannot Use That Column Name"
        comment: "⚠  The column was not " + .verb$ + "."
        comment: "──────────────────────────────────────────────"
        if .name$ = ""
            comment: "A column name cannot be empty."
            comment: ""
            comment: "Every column has to be nameable, because Praat"
            comment: "addresses table columns by name."
        else
            comment: "This table already has a column named:"
            comment: "        " + .shown$
            comment: ""
            comment: "It is column " + string$ (.at) + " of "
            ... + string$ (.total) + "."
            comment: ""
            comment: "Two columns with the same name cannot be told"
            comment: "apart. Praat's own table commands address a"
            comment: "column by its name and always find the first"
            comment: "one, so the second becomes unreachable — and"
            comment: "deleting it would delete the first instead."
        endif
        comment: "──────────────────────────────────────────────"
        comment: "Column names must be unique within a table."
        comment: ""
        comment: "Your selections are kept. Click Back to choose"
        comment: "another name, or Quit to leave the editor."
    .clicked = endPause: "Quit", "Back", 2, 0
    .back = (.clicked = 2)
    if not .back
        running = 0
    endif
endproc


# ────────────────────────────────────────────────────────────────────────────
# @refuseLastColumn: .nCols
#
# Delete Column was pressed on a table that has nothing to spare. Praat will
# not hold a Table with zero columns — it rejects the creation outright, and
# `Remove column` on a one-column table raises "cannot remove my only column",
# which under a script is fatal: the run dies mid-dialog and leaves the
# read-only TableEditor open with no way back into it. This dialog is what
# stands between the user and that.
#
# Returns:
#   .back — 1 to return to the editor, 0 if the user quit. On Quit the main
#           loop is ended here.
# ────────────────────────────────────────────────────────────────────────────
procedure refuseLastColumn: .nCols
    selectObject: tableId
    .only$ = ""
    if .nCols = 1
        @autoLabel: 1
        @ellipsize: autoLabel.name$, 40
        .only$ = ellipsize.out$
    endif

    beginPause: "Cannot Delete Column"
        comment: "⚠  The column was not deleted."
        comment: "──────────────────────────────────────────────"
        if .nCols = 1
            comment: "This table has one column left:"
            comment: "        " + .only$
        else
            comment: "This table has no columns."
        endif
        comment: ""
        comment: "A Praat table must always have at least one"
        comment: "column. Deleting the last one would leave a"
        comment: "table Praat cannot hold, and the attempt ends"
        comment: "the editing session outright."
        comment: "──────────────────────────────────────────────"
        comment: "To empty the table, delete its rows instead."
        comment: "To replace this column, add the new one first,"
        comment: "then delete this one."
        comment: ""
        comment: "Nothing has changed. Click Back to return to"
        comment: "the editor, or Quit to leave it."
    .clicked = endPause: "Quit", "Back", 2, 0
    .back = (.clicked = 2)
    if not .back
        running = 0
    endif
endproc
