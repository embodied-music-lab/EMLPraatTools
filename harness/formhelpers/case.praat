# ---------------------------------------------------------------------------
# THE FORM'S OWN HELPERS, DRIVEN.
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Three procedures live in eml-graphs-form.praat, are called only from inside
# it, and had no test of any kind.
#
# @emlGenerateUniquePath IS THE NON-DESTRUCTIVE-SAVE PROMISE. Every save in
# the plugin goes through it — the figure, the separately-saved legend, the
# CSV export, and the recorded workflow script. Its whole job is that an
# existing file is never silently overwritten. If it regressed, the plugin
# would quietly destroy a user's previous figure, and the first person to
# find out would be the user.
#
# @emlGraphsCSVDefaultName builds the suggested filename for a CSV export
# from whatever analysis is on the clipboard, with its own slug rules —
# deliberately duplicated from @emlWrapperExportCSV rather than shared,
# because that one opens a dialog and this one must not.
#
# @emlGraphsCSVRowAnalysis is the RFC 4180 field-2 reader underneath it. It
# walks the row honouring quoting because a user's table may legitimately
# contain a comma in its name, which quotes field 1 and shifts every later
# field for any reader that counts commas naively.
#
# Neither needs a display, a dialog or a figure. They were untested because
# they sit in a file whose other 7000 lines do need all three.
#
# Output: one CASE line per case, read by run.sh:
#     CASE <label> kind=<uniq|csv|row> result=<value> exists=<0|1|NA>
# ---------------------------------------------------------------------------
include ../../plugin/stats/eml-core-utilities.praat
include ../../plugin/stats/eml-core-descriptive.praat
include ../../plugin/stats/eml-extract.praat
include ../../plugin/stats/eml-output.praat
include ../../plugin/stats/eml-inferential.praat
include ../../plugin/graphs/eml-graph-procedures.praat
include ../../plugin/graphs/eml-annotation-procedures.praat
include ../../plugin/graphs/eml-draw-procedures.praat
include ../../plugin/graphs/eml-graphs-form.praat

dir$ = "out/scratch"
createFolder: dir$

procedure touch: .path$
    writeFileLine: .path$, "x"
endproc

procedure uniq: .label$, .path$
    @emlGenerateUniquePath: .path$
    .full$ = emlGenerateUniquePath.result$
    # THE PROMISE ITSELF, asserted where the answer is still a real path:
    # whatever comes back must not already be on disk. Measured here rather
    # than inferred downstream, because the validator never sees this tree.
    .exists = 0
    if fileReadable (.full$)
        .exists = 1
    endif
    # The RESULT IS REPORTED AS A BARE FILENAME, not the full path, so the
    # artefact does not carry this machine's directory layout into git.
    .r$ = .full$
    .slash = rindex (.r$, "/")
    if .slash > 0
        .r$ = mid$ (.r$, .slash + 1, length (.r$) - .slash)
    endif
    appendInfoLine: "CASE ", .label$, " kind=uniq result=", .r$,
    ... " exists=", .exists
endproc

; --- 1. NOTHING THERE: the path is returned untouched. The control; without
;        it, a procedure that always appended _1 would pass everything below.
@uniq: "free", dir$ + "/fig.png"

; --- 2. ONE COLLISION -> _1
@touch: dir$ + "/taken.png"
@uniq: "collide1", dir$ + "/taken.png"

; --- 3. THE COUNTER WALKS. _1 exists too, so the answer is _2. This is the
;        loop, and a procedure that only ever tried _1 would return a name
;        that also exists — the exact failure the promise forbids.
@touch: dir$ + "/walk.png"
@touch: dir$ + "/walk_1.png"
@uniq: "collide2", dir$ + "/walk.png"

; --- 4. THREE DEEP, so the loop is shown to iterate rather than to have one
;        hard-coded fallback.
@touch: dir$ + "/deep.png"
@touch: dir$ + "/deep_1.png"
@touch: dir$ + "/deep_2.png"
@uniq: "collide3", dir$ + "/deep.png"

; --- 5. NO EXTENSION. The suffix must land at the end of the name, not
;        before a dot that is not there.
@touch: dir$ + "/noext"
@uniq: "noext", dir$ + "/noext"

; --- 6. A DOTTED NAME. Only the LAST dot is the extension: "my.data.csv"
;        must become "my.data_1.csv", not "my_1.data.csv".
@touch: dir$ + "/my.data.csv"
@uniq: "dotted", dir$ + "/my.data.csv"

; --- 7. A LEADING-DOT NAME with no extension after it. rindex finds the dot
;        at position 1, so left$(name, 0) makes the base EMPTY and the whole
;        name becomes the extension — the answer is "_1.hidden". Cosmetically
;        odd and recorded here as the boundary it is; the promise still holds,
;        which is the property the validator asserts. Unreachable from the
;        plugin, whose save dialogs never offer a bare-extension name.
@touch: dir$ + "/.hidden"
@uniq: "dotfile", dir$ + "/.hidden"

# --- @emlGraphsCSVDefaultName ---------------------------------------------
procedure csvname: .label$, .fallback$
    @emlGraphsCSVDefaultName: .fallback$
    appendInfoLine: "CASE ", .label$, " kind=csv result=",
    ... emlGraphsCSVDefaultName.result$, " exists=NA"
endproc

; --- 8. NO CLIPBOARD AT ALL: the fallback table name plus "_results". Runs
;        before emlCSV_table$ is ever declared, so it also drives the
;        variableExists guard on its false arm — the state a fresh session is
;        actually in.
@csvname: "csv_fallback", "voiceA"

; --- 9. A table name on the clipboard overrides the caller's fallback, but
;        with no rows there is still no analysis to slug.
emlCSV_table$ = "fromClipboard"
emlCSV_n = 0
@csvname: "csv_clipboard", "voiceA"

; --- 10. WITH AN ANALYSIS the name carries its slug. The row is the CSV
;         buffer's own shape — table,analysis,term,term_type,field,value —
;         so the analysis is FIELD 2, not field 1.
emlCSV_n = 1
emlCSV_row$ [1] = "vt,One-way ANOVA,F,statistic,value,4.21"
@csvname: "csv_analysis", "voiceA"

; --- 11. THE SLUG RULES, which exist so that an analysis name can never put
;         a path separator into a filename. Spaces become underscores,
;         slashes become hyphens, apostrophes are dropped.
emlCSV_row$ [1] = "vt,Cohen's d / one-way,d,effect,value,0.8"
@csvname: "csv_slug", "voiceA"

; --- 12. A MALFORMED ROW with no comma at all must not crash and must fall
;         back to the "_results" shape rather than slugging the whole row
;         into the filename.
emlCSV_row$ [1] = "OnlyOneField"
@csvname: "csv_shortrow", "voiceA"

# --- @emlGraphsCSVRowAnalysis ---------------------------------------------
# Probed DIRECTLY as well, because csv_clipboard and csv_shortrow produce the
# identical filename by two different routes — no analysis versus an analysis
# the parser failed to read. Only the parser's own output tells them apart.
procedure csvrow: .label$, .row$
    @emlGraphsCSVRowAnalysis: .row$
    appendInfoLine: "CASE ", .label$, " kind=row result=",
    ... emlGraphsCSVRowAnalysis.result$, " exists=NA"
endproc

; --- 13. THE PLAIN CASE.
@csvrow: "row_plain", "vt,One-way ANOVA,F,statistic,value,4.21"

; --- 14. FIELD 1 QUOTED AND CONTAINING A COMMA. This is the reason the
;         parser is not a splitter: counting commas returns " take 2" here.
@csvrow: "row_quotedtable", """vt, take 2"",Pearson r,r,statistic,value,0.07"

; --- 15. THE "" ESCAPE inside a quoted field 2 — one literal quote, and the
;         field does not end at it.
@csvrow: "row_escaped", "vt,""say """"ah"""" test"",F,statistic,value,1.0"

; --- 16. THE ROW ENDS INSIDE FIELD 2, with no trailing comma. Separate code
;         from the loop's exit: the tail block after the while.
@csvrow: "row_tail", "vt,Pearson r"

; --- 17. FEWER THAN TWO FIELDS -> empty, which is what makes csv_shortrow
;         fall back rather than slug.
@csvrow: "row_short", "OnlyOneField"

appendInfoLine: "FORMHELPERS DONE"
