# ============================================================================
# EML Stats & Graphs — Check & repair data
# ============================================================================
# Purpose: Tell the user, in advance and in specific terms, which of their
#          cells will be excluded from an analysis and why — and offer to
#          repair the cases where the intended value is unambiguous.
#
# Date: 6 August 2026
# Version: 1.1
# V1.1: file mode checked two things and reported on all of them.
#        A CSV whose rows do not all carry the header's number of fields came
#        back as "No import problems found", and Praat's own reader then
#        refused the same file outright with "Row 3 incomplete" — the tool
#        whose whole job is to say a file will not import said it would. Row
#        lengths are now scanned (@emlCheckFileRowLengths), and the clean
#        verdict enumerates the checks it is the verdict OF rather than
#        speaking for the file as a whole.
#        Choosing Table mode with no Table selected refuses
#        through a raw exitScript, which Praat dresses in "Script exited.
#        Script ... not completed. Command ... not executed." That refusal
#        now comes through @emlErrorDialog like every other one, and Back
#        returns to the mode choice instead of ending the session.
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

include eml-lib-stats.praat

# ── Mode ────────────────────────────────────────────────────────────────────

nTables = numberOfSelected ("Table")

# THE MODE CHOICE IS A LOOP, because one of the two modes can be refused.
#
#
# Table mode with no Table selected must not end in
#
#     exitScript: "Please select exactly one Table object, then run this again."
#
# which Praat presents as its own error window with "Script exited. Script
# .../eml-check-data.praat not completed. Command "Check & repair data..." not
# executed." underneath — three lines of interpreter stack for one sentence of
# user-facing refusal, and the session over. @emlErrorDialog is the plugin's
# one refusal surface and it offers Back; there is somewhere to go back TO
# here, because file mode is still open, so the choice is re-asked rather than
# thrown away. The seed carries the user's own answer forward on the way round,
# The way every wrapper form does as of that change.
selCheck = if nTables = 1 then 1 else 2 fi
mode = 0
repeat
    beginPause: "EML — Check & repair data"
        comment: "What would you like to check?"
        if nTables = 1
            comment: "A Table is selected, so it can be audited and repaired."
        else
            comment: "No single Table is selected. File mode is still available."
        endif
        optionmenu: "Check", selCheck
            option: "The selected Table (audit and repair cells)"
            option: "A CSV file on disk (before Praat reads it)"
        comment: "A file is checked for problems that cannot be detected"
        comment: "afterwards — a double quote inside a field is removed by"
        comment: "Praat's reader without warning, and a row of the wrong"
        comment: "length stops the read before any Table exists."
    clicked = endPause: "Quit", "Continue", 2, 1
    if clicked = 1
        exitScript: ""
    endif

    selCheck = check
    mode = check
    if mode = 1 and nTables <> 1
        @emlErrorDialog: "Table mode audits a Table in the object list, and "
        ... + "no single Table is selected. A running script cannot change "
        ... + "the selection for you.", "", "menu"
        if not emlErrorDialog.back
            exitScript: ""
        endif
        mode = 0
    endif
until mode > 0

if mode = 2
    goto FILE_MODE
endif

# ============================================================================
# TABLE MODE
# ============================================================================

tableId = selected ("Table")
tableName$ = selected$ ("Table")

; Header quotes first: a column named `"value"` makes every later report
; talk about a column the user cannot address. This is the one place the
; repair is reported even when it finds nothing, since finding nothing is
; itself the answer this tool exists to give.
@emlStripHeaderQuotes: tableId

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

if emlStripHeaderQuotes.nStripped > 0
    appendInfoLine: "COLUMN NAMES — repaired"
    appendInfoLine: string$ (emlStripHeaderQuotes.nStripped)
    ... + " column name(s) arrived wrapped in double quotes:"
    appendInfo: emlStripHeaderQuotes.report$
    appendInfoLine: "Praat strips quotes from data cells but not from header"
    appendInfoLine: "cells, so these columns could not be addressed by name."
    appendInfoLine: "R's write.csv() quotes headers by default, which is the"
    appendInfoLine: "usual way a table arrives in this state. Corrected."
    appendInfoLine: ""
else
    appendInfoLine: "COLUMN NAMES — ok (no stray quotes)"
    appendInfoLine: ""
endif

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
# ROW LENGTHS — what Praat's reader actually refuses a file for
# ============================================================================
# @emlCsvFieldCount, @emlCsvQuoteParity, @emlCheckFileRowLengths
#
# WHY THIS EXISTS. File mode checked doubled-quote escapes and the header's
# delimiter, and then announced "No import problems found" — a verdict about
# the FILE — on a CSV that Praat's own reader refuses to open. The gap was not
# that the check was wrong; it was that the check was narrow and the sentence
# was wide.
#
# WHAT THE READER DOES, MEASURED ON 6.6.30 rather than assumed. `Read Table
# from comma-separated file` takes the header's field count as the column
# count and then pulls exactly that many fields per row out of ONE CONTINUOUS
# stream in which a newline terminates a field. Three consequences, each
# observed on a purpose-built file:
#
#   TOO FEW FIELDS   The row meets the end of its line early and the read
#                    stops: "Row 3 incomplete", or "Last row incomplete" when
#                    it is the final row. NO Table is produced at all. A blank
#                    or whitespace-only line in the middle of the file lands
#                    here too — it is a row of one empty field.
#
#   TOO MANY FIELDS  The surplus is left in the stream, so the NEXT row starts
#                    mid-line and runs out early: the file is refused, and the
#                    reported row number is the row after the offending one.
#                    On the FINAL row there is no next row, so the surplus is
#                    silently discarded and the read succeeds — data lost with
#                    no error, which is the worse of the two outcomes.
#
#   NO DATA ROWS     A header and nothing under it is refused with "No rows".
#
# Trailing blank lines are the one raggedness the reader forgives, so they are
# not counted as rows here either.
#
# WHY IT LIVES BESIDE ITS CALLER rather than next to @emlCheckSourceFile in
# stats/eml-extract.praat. The defect was a verdict that claimed more than the
# scan behind it checked, and that is what a scan and a verdict in different
# files invite. These two change together or the same finding comes back.
#
# Arguments:
#   .path$ — path to the CSV file
#
# Output:
#   .checked       — 1 if the file was read as text and had at least a header
#   .headerFields  — fields on the header line
#   .nDataRows     — data rows, trailing blank lines excluded
#   .nShort/.nLong — rows carrying fewer / more fields than the header
#   .longLastOnly  — 1 when every over-long row is the final one (the silent
#                    arm), 0 when at least one is not (the refusing arm)
#   .report$       — "" when every row matches; otherwise a printable block
# ============================================================================

# A comma inside a quoted field is not a separator. Quoted spans are removed
# whole and the commas are counted in what is left, which also disposes of
# RFC 4180 doubled-quote escapes: "Mezzo ""dram""" reduces to nothing in three
# bites and leaves no comma behind either way.
procedure emlCsvFieldCount: .line$
    .bare$ = replace_regex$ (.line$, """[^""]*""", "", 0)
    .n = length (.bare$) - length (replace$ (.bare$, ",", "", 0)) + 1
endproc

# An odd number of quotes on a line means a quoted field is still open, so the
# next line is a continuation of this row rather than a row of its own. Praat's
# reader handles that case — measured — and a row-length check that did not
# would report a clean file as ragged.
procedure emlCsvQuoteParity: .line$
    .odd = (length (.line$) - length (replace$ (.line$, """", "", 0))) mod 2
endproc

procedure emlCheckFileRowLengths: .path$
    .checked = 0
    .headerFields = 0
    .nDataRows = 0
    .nShort = 0
    .nLong = 0
    .firstShortRow = 0
    .firstShortN = 0
    .firstLongRow = 0
    .firstLongN = 0
    .longLastOnly = 1
    .report$ = ""

    if not fileReadable (.path$)
        goto ROW_LENGTHS_DONE
    endif

    # Read as TEXT, never as a Table: the whole point is to answer a question
    # about a file the Table reader may refuse. `Read Strings from raw text
    # file` strips a UTF-8 BOM and CRLF line endings, both measured, so the
    # counts below are of fields and not of stray bytes.
    .strId = Read Strings from raw text file: .path$
    selectObject: .strId
    .nLines = Get number of strings

    .lastLine = .nLines
    .trimming = 1
    while .trimming = 1 and .lastLine > 0
        selectObject: .strId
        .probe$ = Get string: .lastLine
        if replace_regex$ (.probe$, "^[ \t]+|[ \t]+$", "", 0) = ""
            .lastLine = .lastLine - 1
        else
            .trimming = 0
        endif
    endwhile

    if .lastLine < 1
        removeObject: .strId
        goto ROW_LENGTHS_DONE
    endif

    .checked = 1
    .i = 1
    .row = 0
    while .i <= .lastLine
        selectObject: .strId
        .logical$ = Get string: .i
        @emlCsvQuoteParity: .logical$
        .guard = 0
        while emlCsvQuoteParity.odd = 1 and .i < .lastLine and .guard < 100000
            .guard = .guard + 1
            .i = .i + 1
            selectObject: .strId
            .cont$ = Get string: .i
            .logical$ = .logical$ + " " + .cont$
            @emlCsvQuoteParity: .logical$
        endwhile

        @emlCsvFieldCount: .logical$
        .fields = emlCsvFieldCount.n

        if .row = 0 and .headerFields = 0
            .headerFields = .fields
        else
            .nDataRows = .nDataRows + 1
            if .fields < .headerFields
                .nShort = .nShort + 1
                if .firstShortRow = 0
                    .firstShortRow = .nDataRows
                    .firstShortN = .fields
                endif
            elsif .fields > .headerFields
                .nLong = .nLong + 1
                if .firstLongRow = 0
                    .firstLongRow = .nDataRows
                    .firstLongN = .fields
                endif
                if .i < .lastLine
                    .longLastOnly = 0
                endif
            endif
        endif
        .row = .row + 1
        .i = .i + 1
    endwhile

    removeObject: .strId

    # EVERY ARM OPENS WITH "ROW LENGTHS", including the one that is not about
    # a width at all. The banner is what the report is FILED under — by a
    # reader scanning the Info window and by validate/v60_wrapper_paths.R
    # reading the same text — so an arm that dropped it went out unlabelled
    # and was classified as something the harness did not recognise.
    if .nDataRows = 0
        .report$ = "ROW LENGTHS — this file has a header line and nothing"
        ... + " under it." + newline$
        ... + "  Praat's reader refuses it with ""No rows"" and produces"
        ... + " no Table at all." + newline$
        goto ROW_LENGTHS_DONE
    endif

    if .nShort > 0
        .report$ = .report$
        ... + "  " + string$ (.nShort) + " data row(s) carry FEWER fields"
        ... + " than the header's " + string$ (.headerFields) + "." + newline$
        ... + "  The first is data row " + string$ (.firstShortRow)
        ... + ", with " + string$ (.firstShortN) + " field(s)." + newline$
        ... + "  Praat's reader takes exactly " + string$ (.headerFields)
        ... + " fields per row and stops" + newline$
        ... + "  the read when a row ends early: ""Row N incomplete"", or"
        ... + " ""Last row" + newline$
        ... + "  incomplete"" on the final row. NO Table is produced, so"
        ... + " there is nothing" + newline$
        ... + "  left to repair afterwards. A value that is genuinely"
        ... + " missing must still" + newline$
        ... + "  occupy its field — write a,,c, not a,c. A blank line"
        ... + " inside the file" + newline$
        ... + "  counts as a short row for the same reason." + newline$
    endif

    if .nLong > 0
        .report$ = .report$
        ... + "  " + string$ (.nLong) + " data row(s) carry MORE fields than"
        ... + " the header's " + string$ (.headerFields) + "." + newline$
        ... + "  The first is data row " + string$ (.firstLongRow) + ", with "
        ... + string$ (.firstLongN) + " field(s). Usually an unquoted" + newline$
        ... + "  comma inside a value, which splits one field into two."
        ... + newline$
        if .longLastOnly = 1
            .report$ = .report$
            ... + "  It is the LAST row, and there the surplus is discarded"
            ... + " silently: the" + newline$
            ... + "  read succeeds and the extra values are simply gone."
            ... + newline$
        else
            .report$ = .report$
            ... + "  The surplus is left in the stream, so the following row"
            ... + " starts" + newline$
            ... + "  mid-line and runs out early — the read is refused, and"
            ... + " the row" + newline$
            ... + "  number Praat names is the row AFTER the one at fault."
            ... + newline$
        endif
    endif

    if .report$ <> ""
        .report$ = "ROW LENGTHS — the rows are not all the same width:"
        ... + newline$ + .report$
    endif

    label ROW_LENGTHS_DONE
endproc


# ============================================================================
# FILE MODE
# ============================================================================

label FILE_MODE

path$ = chooseReadFile$: "Choose the CSV file to check"
if path$ = ""
    exitScript: ""
endif

@emlCheckSourceFile: path$
@emlCheckFileRowLengths: path$

writeInfoLine: "FILE CHECK — ", path$
appendInfoLine: ""
if emlCheckFileRowLengths.checked = 0
    # Not a clean verdict and not a dirty one: the file could not be read as
    # text at all, so nothing below was established. Saying so is the only
    # honest thing available.
    appendInfoLine: "This file could not be read as text, so nothing was "
    ... + "checked. It may have"
    appendInfoLine: "been moved or renamed since it was chosen."
elsif emlCheckSourceFile.report$ = "" and emlCheckFileRowLengths.report$ = ""
    # THE VERDICT NAMES ITS OWN CHECKS. "No import problems
    # found", which is a statement about the file; what had been established
    # was a statement about two checks, and a third class of problem — rows of
    # unequal width — went straight past it into a read Praat refused.
    #
    appendInfoLine: "Nothing found by the three checks this mode makes:"
    appendInfoLine: "  - no doubled-quote escapes inside quoted fields;"
    appendInfoLine: "  - the header is comma-delimited, not semicolon-"
    ... + "delimited;"
    appendInfoLine: "  - every one of the ", emlCheckFileRowLengths.nDataRows,
    ... " data row(s) carries the header's ",
    ... emlCheckFileRowLengths.headerFields, " field(s),"
    appendInfoLine: "    which is what Praat's reader refuses a file for."
    appendInfoLine: ""
    appendInfoLine: "That is the whole of what was checked, and it is not a "
    ... + "verdict on the"
    appendInfoLine: "CONTENTS. This mode reads the file as text and answers "
    ... + "one question: will"
    appendInfoLine: "Praat's reader accept it. Once it is a Table, run this "
    ... + "again in Table mode"
    appendInfoLine: "to audit the cell contents."
else
    if emlCheckSourceFile.report$ <> ""
        appendInfoLine: emlCheckSourceFile.report$
    endif
    if emlCheckFileRowLengths.report$ <> ""
        appendInfoLine: emlCheckFileRowLengths.report$
    endif
    appendInfoLine: "Fix the file and re-import."
    if emlCheckSourceFile.nIssues > 0
        appendInfoLine: "The quoting and delimiter problems above cannot be "
        ... + "repaired after the read"
        appendInfoLine: "— Praat leaves no trace of them in the Table."
    endif
    if emlCheckFileRowLengths.nShort > 0
    ... or (emlCheckFileRowLengths.nLong > 0
    ... and emlCheckFileRowLengths.longLastOnly = 0)
    ... or emlCheckFileRowLengths.nDataRows = 0
        appendInfoLine: "The row-length problem stops the read outright: "
        ... + "there will be no Table to repair."
    endif
endif
