# ============================================================================
# EML Praat Tools — Check & repair data
# ============================================================================
# Purpose: Tell the user, in advance and in specific terms, which of their
#          cells will be excluded from an analysis and why — and offer to
#          repair the cases where the intended value is unambiguous.
#
# Date: 6 August 2026
# Version: 1.0
#
# WHY THIS EXISTS
#
# The classification has been correct for a while: @emlAuditColumn knows a
# decimal comma from a type error from a percent coercion, and names the first
# offending row and its literal contents. What was missing was a moment at
# which the user is told. A cell of "1,5" was excluded silently and the only
# visible symptom was an n smaller than expected.
#
# TWO SEPARATE CHECKS, BECAUSE THE DAMAGE HAPPENS AT TWO DIFFERENT MOMENTS
#
# A Table already in the object list can be audited cell by cell, and most of
# what is found can be repaired.
#
# A double quote inside a field cannot. Praat's CSV reader discards RFC 4180
# doubled-quote escapes, so "Mezzo ""dramatic""" arrives as Mezzo dramatic
# with no error and nothing left in the Table to detect. Worse, in some
# positions it does not lose the quotes quietly but breaks the read outright
# with "Row N incomplete". Either way the only place to catch it is the file,
# before Praat reads it — hence the file mode below.
#
# WHAT IS REPAIRED, AND WHAT IS DELIBERATELY NOT
#
# Repairable, because the intended value is unambiguous:
#   1,5   -> 1.5    or 1,234 -> 1234, decided PER COLUMN. Praat has no
#                   thousands separator: number("1,234") is 1, and one comma
#                   anywhere in a column makes Praat's own column queries
#                   return alphabetical ranks instead of values. So no comma
#                   cell is safe and "leave it" is not the conservative
#                   choice. @emlCommaColumnMode reads the whole column and
#                   decides from the evidence in it; a column whose only
#                   comma cells are of the form n,nnn stays ambiguous and is
#                   reported rather than repaired.
#   .5    -> 0.5    a bare leading point; Praat reads it as undefined.
#   n/a   -> empty  placeholders become genuinely missing, so complete-case
#                   exclusion is honest rather than a type error.
#
# Offered but OFF by default, because the intent is ambiguous:
#   30%   -> 0.3    or 30, depending entirely on what the column means. Praat
#                   currently reads "30%" as 0.3 and passes it silently, which
#                   is the most dangerous case here: it is not excluded, it is
#                   accepted as a different number.
#
# Never repaired: anything requiring a judgement about the study. A cell of
# "approx 4" is a type error and stays one.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
# ============================================================================

include eml-lib-stats.praat

# ── Mode ────────────────────────────────────────────────────────────────────

nTables = numberOfSelected ("Table")

beginPause: "EML — Check & repair data"
    comment: "What would you like to check?"
    if nTables = 1
        comment: "A Table is selected, so it can be audited and repaired."
    else
        comment: "No single Table is selected. File mode is still available."
    endif
    optionmenu: "Check", if nTables = 1 then 1 else 2 fi
        option: "The selected Table (audit and repair cells)"
        option: "A CSV file on disk (before Praat reads it)"
    comment: "A file is checked for problems that cannot be detected"
    comment: "afterwards — a double quote inside a field is removed by"
    comment: "Praat's reader without warning."
clicked = endPause: "Quit", "Continue", 2, 1
if clicked = 1
    exitScript: ""
endif

if check = 2
    goto FILE_MODE
endif

# ============================================================================
# TABLE MODE
# ============================================================================

if nTables <> 1
    exitScript: "Please select exactly one Table object, then run this again."
endif
tableId = selected ("Table")
tableName$ = selected$ ("Table")

@emlCheckDataScheme: tableId

if emlCheckDataScheme.report$ = ""
    writeInfoLine: "DATA CHECK — ", tableName$
    appendInfoLine: ""
    appendInfoLine: "No problems found. Every cell in every column is either "
    ... + "a clean number,"
    appendInfoLine: "genuine text, or genuinely empty."
    exitScript: ""
endif

# Count what is repairable, per condition, across the whole table.
@emlTableColumnNames: tableId
nCols = emlTableColumnNames.nCols

nComma = 0
nDot = 0
nPlaceholder = 0
nPercent = 0

selectObject: tableId
nRows = Get number of rows

nCommaAmbig = 0
for iCol from 1 to nCols
    col$ = emlTableColumnNames.name$ [iCol]
    @emlCommaColumnMode: tableId, col$
    commaMode [iCol] = emlCommaColumnMode.mode
    commaWhy$ [iCol] = emlCommaColumnMode.why$
    for iRow from 1 to nRows
        selectObject: tableId
        raw$ = Get value: iRow, col$
        @emlRepairClassify: raw$
        if emlRepairClassify.kind = 1
            if commaMode [iCol] = 3
                nCommaAmbig = nCommaAmbig + 1
            else
                nComma = nComma + 1
            endif
        elsif emlRepairClassify.kind = 2
            nDot = nDot + 1
        elsif emlRepairClassify.kind = 3
            nPlaceholder = nPlaceholder + 1
        elsif emlRepairClassify.kind = 4
            nPercent = nPercent + 1
        endif
    endfor
endfor

writeInfoLine: "DATA CHECK — ", tableName$
appendInfoLine: ""
appendInfoLine: emlCheckDataScheme.report$

if nCommaAmbig > 0
    appendInfoLine: ""
    appendInfoLine: "COMMA CELLS THAT CANNOT BE READ EITHER WAY: ",
    ... nCommaAmbig
    for iCol from 1 to nCols
        if commaMode [iCol] = 3
            appendInfoLine: "  Column """,
            ... emlTableColumnNames.name$ [iCol], """: ", commaWhy$ [iCol],
            ... "."
        endif
    endfor
    appendInfoLine: "  Praat reads a comma cell by truncating at the comma, "
    ... + "so 1,234 becomes 1 —"
    appendInfoLine: "  there is no thousands-separator reading to fall back "
    ... + "on. These cells are"
    appendInfoLine: "  excluded from analysis. Edit them by hand, or re-"
    ... + "export with an English"
    appendInfoLine: "  (United States) locale."
endif

if nComma + nDot + nPlaceholder + nPercent = 0
    appendInfoLine: "None of these can be repaired automatically — each "
    ... + "needs a decision"
    appendInfoLine: "about what the value was meant to be."
    exitScript: ""
endif

# "1 cells" reads as a bug in the tool even when the number is right.
procedure plural: .n, .word$
    .s$ = string$ (.n) + " " + .word$
    if .n <> 1
        .s$ = .s$ + "s"
    endif
endproc

beginPause: "Repair — " + tableName$
    @plural: nComma + nDot + nPlaceholder + nPercent, "cell"
    comment: "Found " + plural.s$ + " that can be repaired. The full report is in the"
    comment: "Info window. Choose which repairs to apply:"
    if nComma > 0
        @plural: nComma, "cell"
        boolean: "Repair comma cells (" + plural.s$ + ")", 1
    endif
    if nDot > 0
        @plural: nDot, "cell"
        boolean: "Leading zero on bare points (" + plural.s$ + ")", 1
    endif
    if nPlaceholder > 0
        @plural: nPlaceholder, "cell"
        boolean: "Placeholders to empty (" + plural.s$ + ")", 1
    endif
    if nPercent > 0
        comment: "─────────────────────────────────────────"
        @plural: nPercent, "percent cell"
        comment: "Praat reads " + plural.s$ + " as a PROPORTION: 30% becomes 0.3,"
        comment: "silently. If the column means 30, this is already wrong."
        optionmenu: "Percent cells", 1
            option: "Leave them (Praat will read 30% as 0.3)"
            option: "Convert to a proportion (30% becomes 0.3)"
            option: "Convert to a plain number (30% becomes 30)"
    endif
    comment: "─────────────────────────────────────────"
    optionmenu: "Apply to", 1
        option: "A copy, leaving the original untouched"
        option: "This Table, in place"
clicked = endPause: "Cancel", "Repair", 2, 1
if clicked = 1
    exitScript: ""
endif

doComma = 0
doDot = 0
doPlaceholder = 0
if nComma > 0
    doComma = repair_comma_cells
endif
if nDot > 0
    doDot = leading_zero_on_bare_points
endif
if nPlaceholder > 0
    doPlaceholder = placeholders_to_empty
endif
pctMode = 1
if nPercent > 0
    pctMode = percent_cells
endif

workId = tableId
workName$ = tableName$
if apply_to = 1
    selectObject: tableId
    workId = Copy: tableName$ + "_repaired"
    workName$ = tableName$ + "_repaired"
endif

nFixed = 0
for iCol from 1 to nCols
    col$ = emlTableColumnNames.name$ [iCol]
    for iRow from 1 to nRows
        selectObject: workId
        raw$ = Get value: iRow, col$
        @emlRepairClassify: raw$
        k = emlRepairClassify.kind
        new$ = ""
        act = 0
        if k = 1 and doComma = 1 and commaMode [iCol] = 1
            # decimal comma
            new$ = replace$ (emlRepairClassify.fixed$, ",", ".", 0)
            act = 1
        elsif k = 1 and doComma = 1 and commaMode [iCol] = 2
            # digit grouping
            new$ = replace$ (emlRepairClassify.fixed$, ",", "", 0)
            act = 1
        elsif k = 2 and doDot = 1
            new$ = emlRepairClassify.fixed$
            act = 1
        elsif k = 3 and doPlaceholder = 1
            new$ = ""
            act = 1
        elsif k = 4 and pctMode > 1
            .num = number (replace$ (emlRepairClassify.fixed$, "%", "", 0))
            if pctMode = 2
                new$ = string$ (.num / 100)
            else
                new$ = string$ (.num)
            endif
            act = 1
        endif
        if act = 1
            selectObject: workId
            Set string value: iRow, col$, new$
            nFixed = nFixed + 1
        endif
    endfor
endfor

selectObject: workId
@emlCheckDataScheme: workId

appendInfoLine: ""
appendInfoLine: "REPAIRED — ", workName$
@plural: nFixed, "cell"
appendInfoLine: "  ", plural.s$, " changed."
if apply_to = 1
    appendInfoLine: "  Written to a new Table; """, tableName$,
    ... """ is unchanged."
else
    appendInfoLine: "  Applied in place."
endif
appendInfoLine: ""
if emlCheckDataScheme.report$ = ""
    appendInfoLine: "Every remaining cell is a clean number, genuine text, "
    ... + "or genuinely empty."
else
    appendInfoLine: "Still outstanding — each of these needs a decision "
    ... + "about the study,"
    appendInfoLine: "not a transformation:"
    appendInfoLine: ""
    appendInfoLine: emlCheckDataScheme.report$
endif

selectObject: workId
exitScript: ""

# ============================================================================
# FILE MODE
# ============================================================================

label FILE_MODE

path$ = chooseReadFile$: "Choose the CSV file to check"
if path$ = ""
    exitScript: ""
endif

@emlCheckSourceFile: path$

writeInfoLine: "FILE CHECK — ", path$
appendInfoLine: ""
if emlCheckSourceFile.report$ = ""
    appendInfoLine: "No import problems found. No doubled-quote escapes, "
    ... + "and the header"
    appendInfoLine: "is comma-delimited."
    appendInfoLine: ""
    appendInfoLine: "This checks how the file will be READ. Once it is a "
    ... + "Table, run this"
    appendInfoLine: "again in Table mode to audit the cell contents."
else
    appendInfoLine: emlCheckSourceFile.report$
    appendInfoLine: "Fix the file and re-import. These problems cannot be "
    ... + "repaired after"
    appendInfoLine: "the read — Praat leaves no trace of them in the Table."
endif
