# ---------------------------------------------------------------------------
# Do the stats bridge and the graph bridge exclude the same rows?
#
# They do not, and this probe is the measurement rather than the argument.
#
# THE QUESTION. @emlBridgeGroupComparison computes an ANOVA or Kruskal-Wallis
# and hands the form an omnibus line, which the form then draws onto a figure
# produced by @emlDrawViolinPlot. If the two disagree about which rows are
# usable, the number printed on the figure describes a different data set from
# the one the figure shows -- and nothing in either layer would say so, because
# each is internally consistent.
#
# THE TWO READERS.
#   · STATS: @eml_readCell, via @emlExtractColumn / @eml_getGroupData. STRICT.
#     A cell is kept only if it is exactly the number it looks like. Written
#     that way deliberately (D96): Praat coerces "1,5" to 1, so a European
#     decimal comma did not drop a row, it put a DIFFERENT NUMBER into the
#     mean with nothing anywhere in the report to say so.
#   · GRAPH: number (Get value: row, col$), in every draw procedure's row
#     filter. LENIENT -- Praat's own numericiser, which is the exact filter
#     D96 removed from the stats path for being insufficient.
#
# The fixture below puts one awkward cell per row and asks all three readers
# (including @emlGraphsColumnExtent, the axis-extent helper) what they see.
#
# Run: praat --run probe_exclusion_parity.praat
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
#            https://github.com/embodied-music-lab/PraatGen
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ---------------------------------------------------------------------------
include ../stress_cases/_prelude.praat
include ../../plugin/graphs/eml-graphs-form.praat

Create Table with column names: "ex", 0, "grp v"
procedure add: .g$, .s$
    Append row
    .r = Get number of rows
    Set string value: .r, "grp", .g$
    Set string value: .r, "v", .s$
endproc
@add: "A", "10"
@add: "A", "20"
@add: "A", "1,5"
@add: "A", "30%"
@add: "A", ""
@add: "A", ".5"
@add: "A", "abc"
@add: "B", "11"
@add: "B", "21"
; A value with NO group label. Neither layer names what happens to it.
@add: "", "99"
tid = selected ("Table")

appendInfoLine: "EXCL header row raw stats graph extent"
for r to 10
    selectObject: tid
    .raw$ = Get value: r, "v"
    .lenient = number (.raw$)
    @eml_readCell: tid, r, "v", 0
    .strict = eml_readCell.value
    .l$ = "undef"
    if .lenient <> undefined
        .l$ = string$ (.lenient)
    endif
    .s$ = "undef"
    if .strict <> undefined
        .s$ = string$ (.strict)
    endif
    .agree$ = "same"
    if .l$ <> .s$
        .agree$ = "DIFFER"
    endif
    appendInfoLine: "EXCL cell ", r, " '", .raw$, "' strict=", .s$,
    ... " lenient=", .l$, " ", .agree$
endfor

; --- the consequence, on the same table -------------------------------------
@eml_getGroupData: tid, "v", "grp", "A"
appendInfoLine: "EXCL statsA n=", eml_getGroupData.n,
... " excluded=", eml_getGroupData.nExcluded

@emlClearAnnotations
Erase all
@emlDrawViolinPlot: tid, "Exclusion parity", "Group", "Value", 6, 4,
... "color", 1, "grp", "v", 0, 0
appendInfoLine: "EXCL figure skipped=", emlDrawViolinPlot.nSkippedRows,
... " axis=", emlDrawViolinPlot.axisYMin, "..", emlDrawViolinPlot.axisYMax

@emlCountGroups: tid, "grp"
appendInfoLine: "EXCL groups n=", emlCountGroups.nGroups,
... " (a blank group label is counted as a category)"

@emlGraphsColumnExtent: tid, "v"
appendInfoLine: "EXCL extent n=", emlGraphsColumnExtent.n,
... " min=", emlGraphsColumnExtent.min, " max=", emlGraphsColumnExtent.max

; --- what a GRAPHS user is now told, and was not before 11 Aug 2026 ---------
; This is the report @emlWrapperInit has printed on every stats wrapper since
; the C96 work. @emlGraphsWorkflow never called it, so the same user drawing
; the same column saw nothing. Printed verbatim -- one wording, not two.
appendInfoLine: ""
@emlCheckDataScheme: tid
if emlCheckDataScheme.report$ = ""
    appendInfoLine: "EXCL datacheck: (clean)"
else
    appendInfoLine: emlCheckDataScheme.report$
endif
