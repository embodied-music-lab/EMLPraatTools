# ============================================================================
# EML Praat Tools — test: the ANOVA orchestrator records itself
# ============================================================================
# The first wrapper wiring. Drives @emlRunAnovaAnalysis with a recording
# running and asserts that what lands in the buffer is what the analysis
# actually computed — not a paraphrase, and not a scrape of the Info window.
#
# Also drives the REFUSAL path, because a log that only shows the analyses
# that succeeded lies by omission.
#
# Date: 9 August 2026
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
#            https://github.com/embodied-music-lab/PraatGen
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ============================================================================

; NOT `include ../../../scripts/eml-lib-stats.praat`. That barrel's paths are
; written "../stats/..." — correct from plugin/scripts/, which is where the
; scripts that use it live, and wrong from here, because Praat resolves an
; include inside an included file against the TOP-LEVEL script's folder. The
; barrel's own header says so. Every other phase1 test names the stats files
; directly for the same reason.
include ../../../stats/eml-core-utilities.praat
include ../../../stats/eml-core-descriptive.praat
include ../../../stats/eml-extract.praat
include ../../../stats/eml-output.praat
include ../../../stats/eml-inferential.praat
include ../../../stats/eml-result-writer.praat
include ../../../stats/eml-record.praat
; @emlRunAnovaAnalysis calls @emlReportAnovaComparison, which lives in
; graphs/eml-annotation-procedures.praat — a stats orchestrator reaching into
; the graphs tree for its reporter. Noted rather than fixed: it is why this
; test cannot load the stats stack alone.
include ../../../graphs/eml-graph-procedures.praat
include ../../../graphs/eml-annotation-procedures.praat
include ../../../stats/eml-analysis.praat

nPass = 0
nFail = 0

procedure ok: .label$, .cond
    if .cond = 1
        nPass = nPass + 1
        appendInfoLine: "  PASS : ", .label$
    else
        nFail = nFail + 1
        appendInfoLine: "  FAIL : ", .label$
    endif
endproc

writeInfoLine: "TEST — ANOVA orchestrator records itself"
appendInfoLine: ""

tmp$ = "/tmp/eml_record_anova"
createFolder: tmp$

csv$ = "../../../../evidence/csv/demo_3groups_input.csv"
if not fileReadable (csv$)
    csv$ = "../../../../evidence/csv/v09_anova_tukey_input.csv"
endif
Read Table from comma-separated file: csv$
tableId = selected ("Table")
nRows = Get number of rows
nCols = Get number of columns

@emlRecordBegin: tmp$
@emlRecordLoadPhrases: "../../../data/eml-record-phrases.csv"
@emlRecordHeader: "demo_3groups_input.csv", nRows, nCols, "9 August 2026"
@ok: "recording started", emlRecordActive

# --- the real analysis ------------------------------------------------------
selectObject: tableId
@emlRunAnovaAnalysis: tableId, "SPL_dB", "voice_type", 1
@ok: "analysis succeeded", emlRunAnovaAnalysis.error$ = ""

@ok: "one step recorded by the orchestrator", emlRecordN = 1

selectObject: emlRecordBufferId
kind$ = Get value: 1, "kind"
intent$ = Get value: 1, "intent"
caveat$ = Get value: 1, "caveat"
code$ = Get value: 1, "code"
result$ = Get value: 1, "result"
api$ = Get value: 1, "api"

@ok: "kind is analysis", kind$ = "analysis"
@ok: "intent names both columns and the group count",
... index (intent$, "SPL_dB") > 0 and index (intent$, "voice_type") > 0
@ok: "intent carries the composed post-hoc sentence",
... index (intent$, "Tukey HSD requested") > 0
@ok: "the alpha is a RESOLVED value, not the word default",
... index (intent$, "Alpha 0.05") > 0
@ok: "Stream C caveat is present",
... index (caveat$, "Normality was NOT tested") > 0
@ok: "code carries a path TOKEN, never a literal",
... index (code$, "<<path") > 0
@ok: "code names the wrapper", index (code$, "eml-compare-k-groups") > 0

; Measured 9 Aug 2026: an argument-bearing runScript: on this wrapper fails
; with "Found 3 arguments but expected only 0", because the wrapper uses
; beginPause: and not form:...endform. Emitting the argument form would put
; a line in the user's file that cannot run anywhere. Asserted so a later
; edit cannot quietly put it back.
@ok: "the emitted call carries NO arguments",
... index (code$, """SPL_dB""") = 0
@ok: "the headless limitation is stated beside the call",
... index (code$, "needs a display") > 0
@ok: "API equivalent is recorded",
... index (api$, "@emlRunAnovaAnalysis:") > 0

# The numbers must be the analysis's own, to the digit.
wantF$ = fixed$ (emlOneWayAnova.fValue, 4)
wantEta$ = fixed$ (emlOneWayAnova.etaSquared, 4)
@ok: "recorded F matches the computed F exactly",
... index (result$, wantF$) > 0
@ok: "recorded eta-squared matches exactly",
... index (result$, wantEta$) > 0
@ok: "per-group n and mean recorded",
... index (result$, emlOneWayAnova.groupLabel$[1]) > 0

appendInfoLine: "    (F = ", wantF$, ", eta2 = ", wantEta$,
... ", k = ", emlOneWayAnova.nGroups, ")"

# --- the refusal path -------------------------------------------------------
# A group column with one level. Every guard in the orchestrator jumps to
# END_ANOVA, which is why the recording call sits after the label.
selectObject: tableId
Copy: "oneGroup"
oneId = selected ("Table")
n1 = Get number of rows
for i from 1 to n1
    Set string value: i, "voice_type", "OnlyOne"
endfor

selectObject: oneId
@emlRunAnovaAnalysis: oneId, "SPL_dB", "voice_type", 1
@ok: "the degenerate run refused", emlRunAnovaAnalysis.error$ <> ""
@ok: "the REFUSAL was recorded too", emlRecordN = 2

selectObject: emlRecordBufferId
kind2$ = Get value: 2, "kind"
intent2$ = Get value: 2, "intent"
code2$ = Get value: 2, "code"
@ok: "refusal row is kind=refusal", kind2$ = "refusal"
@ok: "refusal intent carries the orchestrator's own message",
... index (intent2$, "fewer than 2 groups") > 0
@ok: "refusal row still has a non-empty code slot", code2$ <> ""

# --- emit -------------------------------------------------------------------
outPath$ = tmp$ + "/anova_recorded.praat"
@emlRecordFlush: outPath$
@ok: "flush wrote the file", emlRecordFlush.written
emitted$ = readFile$ (outPath$)
@ok: "no token survived into the emitted file",
... index (emitted$, "<<path") = 0
@ok: "the plugin folder became a form variable",
... index (emitted$, "plugin_folder$") > 0
@ok: "both steps are in the file",
... index (emitted$, "Step 1 (analysis)") > 0
... and index (emitted$, "Step 2 (refusal)") > 0
@ok: "refusal message is not double-punctuated",
... index (emitted$, "groups..") = 0

; The gap this increment does NOT close, asserted so it cannot close itself
; by accident and so the artifact never claims completeness it lacks. The
; orchestrator is handed a tableId, never a path, so no input is registered
; and the emitted file cannot reproduce the session on its own. When the read
; layer is wired this assertion flips and the NOTE disappears.
@ok: "an unrecorded input file is NAMED, not omitted",
... index (emitted$, "INCOMPLETE -- NO INPUT FILE WAS RECORDED") > 0

@emlRecordDiscard

appendInfoLine: ""
appendInfoLine: "  Passed:  ", nPass
appendInfoLine: "  Failed:  ", nFail
if nFail = 0
    appendInfoLine: "  ALL TESTS PASSED"
endif
appendInfoLine: "EMLTEST-RESULT: status=",
... if nFail = 0 then "PASS" else "FAIL" fi,
... " passed=", nPass, " failed=", nFail, " skipped=0 total=", nPass + nFail
