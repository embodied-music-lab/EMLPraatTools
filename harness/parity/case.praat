# ---------------------------------------------------------------------------
# EXCLUSION PARITY. Does the figure exclude the rows the analysis excludes?
#
# One number against one number, per draw procedure, emitted to a TSV that
# validate/v33_exclusion_parity.R asserts on.
#
#   figureSkipped   the procedure's own .nSkippedRows, the count it discloses
#                   to the user ("N row(s) skipped (missing or non-numeric
#                   value)")
#   statsExcluded   @emlExtractColumn.nUndefined on the same column -- the
#                   count the analysis layer would exclude from the same data
#
# THESE WERE NOT EQUAL UNTIL 11 AUGUST 2026. The draw layer read cells with
# Praat's own numericiser and the stats layer with @eml_readCell, so `1,5` was
# dropped by an ANOVA and plotted as 1, and `30%` was dropped and plotted as
# 0.3. See §2d of audit/GRAPHING_PUSH_REMAINING.md. Both numbers are computed
# HERE, by the plugin's own procedures, so this file and its validator check
# a RELATIONSHIP and never re-implement either reader -- an R-side copy of the
# classification rules would drift and would then be checking itself.
#
# COVERAGE. The seven procedures that publish .nSkippedRows. Six of them count
# "the value column was not readable", which is exactly what
# @emlExtractColumn.nUndefined counts on that column, so the comparison is
# like for like.
#
# @emlDrawTimeSeries and @emlDrawScatterPlot are NOT like for like and are
# emitted with a paired reference instead: both count a row out when EITHER of
# two numeric columns fails, so the reference is @emlExtractPairedColumns,
# which applies row-wise complete-case deletion across the pair. Comparing
# either against a single-column count would fail for a correct reason and
# tell nobody anything.
#
# Two fixtures per procedure:
#   clean   nothing to exclude. Both numbers must be 0. This is the half that
#           catches a reader which drops everything.
#   dirty   one of each awkward kind. Both numbers must be equal AND > 0.
#           A parity check that only ever compares 0 to 0 is not a check.
#
# Run: bash harness/parity/run.sh
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
#            https://github.com/embodied-music-lab/PraatGen
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ---------------------------------------------------------------------------
include ../stress_cases/_prelude.praat

outPath$ = environment$ ("EML_PARITY_TSV")
if outPath$ = ""
    outPath$ = "PARITY.tsv"
endif
deleteFile: outPath$

# The awkward cells, one of each kind @emlAuditColumn classifies. `.5` and
# `abc` are rejected by BOTH readers and are here as controls: if they ever
# start diverging the fixture says so. `1,5` and `30%` are the two that
# actually diverged.
procedure buildTable: .dirty
    Create Table with column names: "par", 0, "grp sub id cond t x v"
    .row = 0
    for .g from 1 to 3
        for .k from 1 to 6
            .row = .row + 1
            Append row
            Set string value: .row, "grp", "G" + string$ (.g)
            Set string value: .row, "sub", "P" + string$ ((.k mod 2) + 1)
            Set string value: .row, "id", "S" + string$ (.k)
            Set string value: .row, "cond", "C" + string$ (.k)
            Set numeric value: .row, "t", .k
            Set numeric value: .row, "x", 10 + .g * 3 + .k
            Set numeric value: .row, "v", 200 + .g * 4 + .k
        endfor
    endfor
    if .dirty = 1
        Set string value: 3, "v", "1,5"
        Set string value: 7, "v", "30%"
        Set string value: 11, "v", ""
        Set string value: 14, "v", ".5"
        Set string value: 17, "v", "abc"
        ; the paired procedures need a dirty x as well, so the pair-wise
        ; reference has something to delete that the value column does not.
        Set string value: 5, "x", "2,5"
    endif
    tid = selected ("Table")
endproc

procedure emit: .name$, .figure, .stats
    .ok$ = "MISMATCH"
    if .figure = .stats
        .ok$ = "MATCH"
    endif
    appendFileLine: outPath$, .name$, tab$, dirtyFlag, tab$,
    ... .figure, tab$, .stats, tab$, .ok$
endproc

for dirtyFlag from 0 to 1
    # ---- single value column: violin, box, gviolin, gbox, spaghetti -------
    @buildTable: dirtyFlag
    @emlExtractColumn: tid, "v"
    refV = emlExtractColumn.nUndefined

    Erase all
    @emlDrawViolinPlot: tid, "p", "G", "V", 6, 4, "color", 1, "grp", "v", 0, 0
    @emit: "violin", emlDrawViolinPlot.nSkippedRows, refV

    Erase all
    @emlDrawBoxPlot: tid, "p", "G", "V", 6, 4, "color", 1, "grp", "v", 0, 0
    @emit: "box", emlDrawBoxPlot.nSkippedRows, refV

    Erase all
    @emlDrawGroupedViolin: tid, "p", "G", "V", 6, 4, "color", 1,
    ... "grp", "sub", "v", 0, 0
    @emit: "gviolin", emlDrawGroupedViolin.nSkippedRows, refV

    Erase all
    @emlDrawGroupedBoxPlot: tid, "p", "G", "V", 6, 4, "color", 1,
    ... "grp", "sub", "v", 0, 0
    @emit: "gbox", emlDrawGroupedBoxPlot.nSkippedRows, refV

    Erase all
    @emlDrawSpaghettiPlot: tid, "p", "C", "V", 6, 4, "color", 1,
    ... "cond", "v", "id", "grp", 1, 0, 0
    @emit: "spaghetti", emlDrawSpaghettiPlot.nSkippedRows, refV

    # ---- two numeric columns: the reference is the PAIRED reader ----------
    # @emlDrawTimeSeries counts a row out when the time OR the value column
    # fails; @emlDrawScatterPlot when x OR y does. That is row-wise
    # complete-case deletion across a pair, which is what
    # @emlExtractPairedColumns does and what a single-column count does not.
    @emlExtractPairedColumns: tid, "t", "v"
    refTV = emlExtractPairedColumns.nExcludedRows
    Erase all
    @emlDrawTimeSeries: tid, "p", "T", "V", 6, 4, "color", 1,
    ... "t", "v", "grp", 0, 0, 0, 0
    @emit: "ts", emlDrawTimeSeries.nSkippedRows, refTV

    @emlExtractPairedColumns: tid, "x", "v"
    refXV = emlExtractPairedColumns.nExcludedRows
    Erase all
    @emlDrawScatterPlot: tid, "p", "X", "V", 6, 4, "color", 1,
    ... "x", "v", "grp", 0, 0, 0, 0, 0
    @emit: "scatter", emlDrawScatterPlot.nSkippedRows, refXV

    selectObject: tid
    Remove
endfor

appendInfoLine: "PARITY written to ", outPath$
