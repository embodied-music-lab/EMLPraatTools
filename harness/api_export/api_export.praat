# ---------------------------------------------------------------------------
# api_export.praat -- @emlExportResultFiles driven as a CODE/API caller
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS DRIVES, AND WHY IT IS NOT THE SAVE PANEL. @emlSavePanel is a
# dialog: it asks for a folder, it calls createFolder: on the answer, and it
# only ever calls the exporter when it has already established that there is
# something to export (emlCSV_n > 0 or emlResult_declared = 1). Every one of
# those preconditions is the PANEL's, not the exporter's, and a user's own
# Praat script calling @emlExportResultFiles directly satisfies none of them.
# harness/savepaths presses the button; this file calls the procedure.
#
# ONE LEG PER PROCESS. Each leg is launched by run.sh as its own `praat --run`,
# because the single most interesting leg -- `fresh` -- is only meaningful in
# a session where NOTHING has run. Sharing a process would set
# emlResult_declared and emlCSV_n before the leg that exists to find out what
# happens when neither is set.
#
# THE INCLUDE LIST IS THE RECORDER'S LIST, not a barrel. Praat resolves a
# relative `include` inside an included file against the TOP-LEVEL script's
# folder, so plugin/scripts/eml-lib.praat only works for a script that sits in
# plugin/scripts/. Measured again 14 Aug 2026 on 6.6.30; the same rule is
# written up in @emlRecordEmit's LIBRARY block, which is where this list comes
# from. A driver that loaded a barrel would be testing a configuration no user
# script outside the plugin folder can have.
#
# The paths below are written from THIS file's folder because this file is the
# one Praat runs. plugin/docs/API_EXPORT.md shows the same list home-relative, which
# is what a user's own script wants; harness/api_export/doc_example.praat
# carries that spelling verbatim and run.sh drives it.
#
# Outputs, per leg, into the folder it is handed:
#   <leg>.outputs.tsv   one key<TAB>value line per output of the procedure
#   plus whatever @emlExportResultFiles actually wrote
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ---------------------------------------------------------------------------
form: "API export leg"
    sentence: "Leg", ""
    sentence: "Data", ""
    sentence: "Out", ""
endform

include ../../plugin/stats/eml-core-utilities.praat
include ../../plugin/stats/eml-core-descriptive.praat
include ../../plugin/stats/eml-extract.praat
include ../../plugin/stats/eml-output.praat
include ../../plugin/stats/eml-inferential.praat
include ../../plugin/stats/eml-result-writer.praat
include ../../plugin/stats/eml-record.praat
include ../../plugin/graphs/eml-graph-procedures.praat
include ../../plugin/graphs/eml-annotation-procedures.praat
include ../../plugin/graphs/eml-draw-procedures.praat
include ../../plugin/stats/eml-analysis.praat

; ---------------------------------------------------------------------------
; @legReport: .tag$ -- write the procedure's seven outputs, plus a marker.
;
; READ OFF THE PROCEDURE, EVERY ONE OF THEM. The header of
; @emlExportResultFiles documents .declared, .success, .nWritten, .fileList$,
; .skipped$, .actualPath$ and .reason$, and a harness that recorded only the
; interesting ones would let a future edit quietly stop setting the others.
; fileList$ and skipped$ are newline-separated, so they are emitted as one
; line per entry under a repeated key rather than embedded in a TSV cell.
; ---------------------------------------------------------------------------
procedure legReport: .tag$
    .p$ = out$ + "/" + leg$ + ".outputs.tsv"
    .t$ = "leg" + tab$ + leg$ + newline$
    .t$ = .t$ + "phase" + tab$ + .tag$ + newline$
    .t$ = .t$ + "declared" + tab$ + string$ (emlExportResultFiles.declared)
    ... + newline$
    .t$ = .t$ + "success" + tab$ + string$ (emlExportResultFiles.success)
    ... + newline$
    .t$ = .t$ + "nWritten" + tab$ + string$ (emlExportResultFiles.nWritten)
    ... + newline$
    .t$ = .t$ + "reason" + tab$ + emlExportResultFiles.reason$ + newline$
    .t$ = .t$ + "actualPath" + tab$
    ... + replace$ (emlExportResultFiles.actualPath$, out$ + "/", "", 0)
    ... + newline$

    .rest$ = emlExportResultFiles.fileList$
    while index (.rest$, newline$) > 0
        .nl = index (.rest$, newline$)
        .one$ = left$ (.rest$, .nl - 1)
        if .one$ <> ""
            .t$ = .t$ + "file" + tab$ + replace$ (.one$, out$ + "/", "", 0)
            ... + newline$
        endif
        .rest$ = right$ (.rest$, length (.rest$) - .nl)
    endwhile
    if .rest$ <> ""
        .t$ = .t$ + "file" + tab$ + replace$ (.rest$, out$ + "/", "", 0)
        ... + newline$
    endif

    .rest$ = emlExportResultFiles.skipped$
    while index (.rest$, newline$) > 0
        .nl = index (.rest$, newline$)
        .one$ = left$ (.rest$, .nl - 1)
        if .one$ <> ""
            .t$ = .t$ + "skipped" + tab$ + .one$ + newline$
        endif
        .rest$ = right$ (.rest$, length (.rest$) - .nl)
    endwhile
    if .rest$ <> ""
        .t$ = .t$ + "skipped" + tab$ + .rest$ + newline$
    endif

    ; APPENDED, NOT WRITTEN. The `collide` leg calls the exporter twice and
    ; both calls have to survive into the artefact; a writeFile: here would
    ; leave only the second and the collision would be invisible.
    appendFile: .p$, .t$
endproc


; ---------------------------------------------------------------------------
; THE LEGS
; ---------------------------------------------------------------------------

if leg$ = "declared"
    ; A DECLARED ANALYSIS. One-way ANOVA with Tukey stages two extra frames
    ; on top of tidy/glance/augment, so this is the widest set the exporter
    ; can produce and the only leg that exercises the extras loop.
    data = Read Table from comma-separated file: data$
    @emlRunAnovaAnalysis: data, "SPL_dB", "voice_type", 1
    @emlExportResultFiles: out$, "anova_spl"
    @legReport: "first"

elsif leg$ = "collide"
    ; THE SAME EXPORT, TWICE, INTO THE SAME FOLDER UNDER THE SAME BASE.
    ; The exporter uniques the BASE once, against the tidy frame, and every
    ; frame in the set then carries the walked base -- so the second call must
    ; produce a complete second SET, not a mixture of new frame 1 and old
    ; frames 2 and 3. Nothing but a second call can show that.
    data = Read Table from comma-separated file: data$
    @emlRunAnovaAnalysis: data, "SPL_dB", "voice_type", 1
    @emlExportResultFiles: out$, "twice"
    @legReport: "first"
    @emlExportResultFiles: out$, "twice"
    @legReport: "second"

elsif leg$ = "loop"
    ; THE BATCH PATTERN plugin/docs/API_EXPORT.md ends on. Two columns, one analysis
    ; and one export each. The claim being checked is that the collectors are
    ; REFILLED by each analysis rather than accumulated: the second export must
    ; describe vibrato_rate_Hz and not both columns, and each must land under
    ; its own base rather than colliding onto a walked one.
    data = Read Table from comma-separated file: data$
    column$ [1] = "SPL_dB"
    column$ [2] = "vibrato_rate_Hz"
    for i from 1 to 2
        selectObject: data
        @emlRunAnovaAnalysis: data, column$ [i], "voice_type", 1
        @emlExportResultFiles: out$, "loop_" + column$ [i]
        @legReport: "column" + string$ (i)
    endfor

elsif leg$ = "partial"
    ; A DECLARED ANALYSIS THAT PRODUCES ONLY TWO OF THE THREE FRAMES.
    ; Normality has no per-observation quantity, so @emlResultWrite writes no
    ; augment file and says so in .skipped$. That output is documented and is
    ; the only one an ANOVA leg can never exercise: a missing file and a
    ; failed export look identical on disk, and .skipped$ is the whole of the
    ; difference.
    data = Read Table from comma-separated file: data$
    @emlRunNormalityAnalysis: data, "SPL_dB", "both"
    @emlExportResultFiles: out$, "normality_spl"
    @legReport: "first"

elsif leg$ = "legacy"
    ; AN ANALYSIS THAT DOES NOT DECLARE. @emlRunDescriptiveAnalysis fills the
    ; single-file legacy buffer instead (14 Aug 2026) and is the only shipped
    ; orchestrator that does, so it is the only way to reach the `else` branch
    ; of the fork from a real analysis.
    data = Read Table from comma-separated file: data$
    @emlRunDescriptiveAnalysis: data, "SPL_dB"
    @emlExportResultFiles: out$, "describe_spl"
    @legReport: "first"

elsif leg$ = "fresh"
    ; NOTHING RAN. This is the case the nested-if guard in the exporter exists
    ; for and the case a GUI caller cannot reach: no orchestrator, so no
    ; @emlCSVInit, so emlResult_declared is not merely 0 but ABSENT. It must
    ; report an empty export and return, not abort.
    if variableExists ("emlResult_declared")
        exitScript: "FRESH: emlResult_declared was already set. "
        ... + "This leg proves nothing."
    endif
    @emlExportResultFiles: out$, "nothing_declared"
    @legReport: "first"

elsif leg$ = "nofolder"
    ; THE FOLDER MUST ALREADY EXIST, and this leg is the proof rather than the
    ; assertion. @emlSavePanel calls createFolder: on the folder the user typed
    ; before it calls the exporter (eml-output.praat, "THE FOLDER IS MADE, NOT
    ; ASSUMED"); @emlExportResultFiles contains no createFolder: of its own, so
    ; an API caller who skips it loses the whole script to Praat's own error at
    ; the first write -- with no output of the procedure to inspect, because
    ; control never returns.
    ;
    ; `nocheck` IS THE HARNESS SWALLOWING THAT ERROR, not the plugin
    ; surviving it. Without it this leg would take the run down, which is
    ; exactly the user-facing behaviour being recorded here.
    ;
    ; AND THE OUTPUTS ARE NOT MERELY WRONG, THEY ARE ABSENT. Measured
    ; 14 Aug 2026 on 6.6.30: after the swallowed abort,
    ; emlExportResultFiles.declared is "Unknown variable" -- Praat discards a
    ; procedure's locals when it unwinds -- so @legReport cannot run here and
    ; a caller has nothing at all to branch on. That is the finding, so it is
    ; what this leg records.
    data = Read Table from comma-separated file: data$
    @emlRunAnovaAnalysis: data, "SPL_dB", "voice_type", 1
    target$ = out$ + "/never_created"
    nocheck @emlExportResultFiles: target$, "anova_spl"
    readable = 0
    if variableExists ("emlExportResultFiles.declared")
        readable = 1
    endif
    exists = 0
    if fileReadable (target$ + "/anova_spl_tidy.csv")
        exists = 1
    endif
    appendFile: out$ + "/" + leg$ + ".outputs.tsv",
    ... "leg" + tab$ + leg$ + newline$
    ... + "phase" + tab$ + "first" + newline$
    ... + "aborted" + tab$ + "1" + newline$
    ... + "outputsReadable" + tab$ + string$ (readable) + newline$
    ... + "tidyFileExists" + tab$ + string$ (exists) + newline$

else
    exitScript: "api_export.praat: unknown leg """ + leg$ + """."
endif

appendInfoLine: "APIEXPORT DONE leg=", leg$
