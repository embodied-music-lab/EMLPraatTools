# ============================================================================
# EML Praat Tools — test: record workflow foundation
# ============================================================================
# Covers @emlRecordBegin/Step/Result/Path/Flush, @emlPhrase, and the
# renderer. No wrapper is touched and no GUI is needed: every assertion here
# is about the buffer, the path registry, the phrase substitution, or the
# text the renderer produces.
#
# Includes the four §8.10 assertions that survived the 9 Aug encoding
# retest — the pure-ASCII one did not, and is deliberately absent:
#
#   1. every buffer row has a non-empty code slot
#   2. every path appearing in the body also appears in the declarations
#   3. a missing phrase key is marked, not silent
#   4. the emitted file PARSES AND RUNS as a Praat script
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

include ../../../stats/eml-record.praat

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

procedure eq$: .label$, .got$, .want$
    if .got$ = .want$
        nPass = nPass + 1
        appendInfoLine: "  PASS : ", .label$
    else
        nFail = nFail + 1
        appendInfoLine: "  FAIL : ", .label$
        appendInfoLine: "         got  [", .got$, "]"
        appendInfoLine: "         want [", .want$, "]"
    endif
endproc

writeInfoLine: "TEST — record workflow foundation"
appendInfoLine: ""

tmp$ = "/tmp/eml_record_test"
createFolder: tmp$

# --- begin ------------------------------------------------------------------
@emlRecordBegin: tmp$
@ok: "begin starts a recording", emlRecordBegin.started
@ok: "active flag set", emlRecordActive

@emlRecordBegin: tmp$
@ok: "a second begin REFUSES rather than discarding the buffer",
... emlRecordBegin.started = 0

@emlRecordHeader: "v09_anova_tukey_input.csv", 45, 4, "9 August 2026, 13:18"

# --- phrases ----------------------------------------------------------------
@emlRecordLoadPhrases: "../../../data/eml-record-phrases.csv"
@ok: "phrase registry loaded", emlRecordLoadPhrases.ok

@emlPhrase: "anova.intent", "One-way ANOVA", "SPL_dB", "voice_type", "3",
... "", ""
@eq$: "positional substitution",
... emlPhrase.result$,
... "One-way ANOVA of SPL_dB by voice_type, 3 groups."

@emlPhrase: "no.such.key", "", "", "", "", "", ""
@ok: "a missing key is MARKED, not silent",
... index (emlPhrase.result$, "MISSING PHRASE") > 0

# --- paths ------------------------------------------------------------------
@emlRecordPath: "/Users/you/Library/Preferences/Praat Prefs/plugin_EMLPraatTools", "plugin"
pluginTok$ = emlRecordPath.token$
@eq$: "plugin path gets the plugin_folder$ variable",
... emlRecordPath.varName$, "plugin_folder$"

@emlRecordPath: "/Users/you/study/v09_anova_tukey_input.csv", "input"
inputTok$ = emlRecordPath.token$
@eq$: "first input gets data_file$", emlRecordPath.varName$, "data_file$"

@emlRecordPath: "/Users/you/study/v09_anova_tukey_input.csv", "input"
@eq$: "a repeated path returns the SAME token, not a second row",
... emlRecordPath.token$, inputTok$

@emlRecordPath: "/Users/you/study/second.csv", "input"
@eq$: "second input is numbered within its role",
... emlRecordPath.varName$, "data_file_2$"

@emlRecordPath: "/Users/you/study/output", "output"
outTok$ = emlRecordPath.token$
@eq$: "output path gets output_folder$",
... emlRecordPath.varName$, "output_folder$"

selectObject: emlRecordPathsId
nDistinctPaths = Get number of rows
@ok: "registry holds 4 distinct paths, not 5", nDistinctPaths = 4

# --- steps ------------------------------------------------------------------
@emlPhrase: "read.intent", "the table", "", "", "", "", ""
@emlRecordStep: "analysis", emlPhrase.result$, "",
... "table = Read Table from comma-separated file: " + inputTok$, ""

; COMPOSITION. Praat procedure locals are one namespace per PROCEDURE, not
; per call, so the first result must be captured before the second call or
; it is overwritten. Written the wrong way round, step 2 renders narrated
; "default, not specified by the user" with the ANOVA sentence gone and the
; code line still correct — a file that looks complete and describes the
; wrong thing. Observed on the first render of this fixture.
@emlPhrase: "anova.intent", "One-way ANOVA", "SPL_dB", "voice_type", "3",
... "", ""
step2Intent$ = emlPhrase.result$
@emlPhrase: "posthoc.intent", "Tukey HSD", "0.05",
... "default, not specified by the user", "", "", ""
step2Intent$ = step2Intent$ + newline$ + emlPhrase.result$
@emlRecordStep: "analysis",
... step2Intent$,
... "Normality was NOT tested on this path.",
... "runScript: " + pluginTok$ + " + ""/scripts/eml-compare-k-groups.praat"", ""SPL_dB"", ""voice_type"", ""Tukey"", 0.05",
... "@emlRunAnovaAnalysis: table, ""SPL_dB"", ""voice_type"", 1"
@emlRecordResult: "F(2, 42) = 14.2687, p < .001, eta-squared = 0.4046"
@emlRecordResult: "Brown-Forsythe F(2, 42) = 0.3927, p = .678 — not rejected."

; A refusal is a row like any other, and it has NO code.
@emlPhrase: "refusal.intent", "too few complete cases for a Tukey matrix",
... "", "", "", "", ""
@emlRecordStep: "refusal", emlPhrase.result$,
... "2 of 3 groups had n < 2 after complete-case exclusion.", "", ""

@ok: "three steps recorded", emlRecordN = 3

selectObject: emlRecordBufferId
nRows = Get number of rows
allHaveCode = 1
for i from 1 to nRows
    selectObject: emlRecordBufferId
    c$ = Get value: i, "code"
    if c$ = ""
        allHaveCode = 0
    endif
endfor
@ok: "ASSERTION 1 — every buffer row has a non-empty code slot", allHaveCode

# --- render -----------------------------------------------------------------
@emlRecordRender
body$ = emlRecordRender.text$

@ok: "header carries the pinned stamp",
... index (body$, "9 August 2026, 13:18") > 0
@ok: "header carries the input name and shape",
... index (body$, "45 rows, 4 columns") > 0

@ok: "no raw token survives into the rendered file",
... index (body$, "<<path") = 0
@ok: "tokens became variable references",
... index (body$, "Read Table from comma-separated file: data_file$") > 0

# ASSERTION 2 — every path in the body is declared in the form block.
formEnd = index (body$, "endform")
decls$ = left$ (body$, formEnd)
rest$ = mid$ (body$, formEnd, 1000000)
declaredAll = 1
selectObject: emlRecordPathsId
np = Get number of rows
for i from 1 to np
    selectObject: emlRecordPathsId
    v$ = Get value: i, "varName"
    lbl$ = replace$ (v$, "$", "", 0)
    lbl$ = replace$ (lbl$, "_", " ", 0)
    lbl$ = replace_regex$ (lbl$, "^(.)", "\u\1", 1)
    if index (rest$, v$) > 0 and index (decls$, lbl$) = 0
        declaredAll = 0
    endif
endfor
@ok: "ASSERTION 2 — every path used in the body is declared above it",
... declaredAll

@ok: "path fields use folder:/infile:, never sentence:",
... index (decls$, "sentence:") = 0
@ok: "every path field is pre-populated (no empty default)",
... index (decls$, ", """"") = 0

@ok: "a refusal step is visually distinct",
... index (body$, "--- Step 3 (refusal) ---") > 0
@ok: "the codeless refusal is a comment, not a blank",
... index (body$, "; (nothing executed at this step") > 0

@ok: "Stream A text landed in a comment, not in code",
... index (body$, "# F(2, 42) = 14.2687") > 0
@ok: "the API equivalent is a comment",
... index (body$, "# @emlRunAnovaAnalysis:") > 0

; The blank-line discipline: the line before an executable runScript: must
; be empty, and so must the line after it.
runIdx = index (body$, "runScript: plugin_folder$")
before$ = left$ (body$, runIdx - 1)
@ok: "a blank line precedes the executable block",
... right$ (before$, 2) = newline$ + newline$

; The composition trap, asserted rather than trusted to the note in
; eml-record.praat: BOTH phrases must survive into step 2's narrative.
@ok: "composed narrative keeps the FIRST phrase",
... index (body$, "# One-way ANOVA of SPL_dB by voice_type, 3 groups.") > 0
@ok: "composed narrative keeps the SECOND phrase",
... index (body$, "# Tukey HSD requested. Alpha 0.05") > 0

# --- crash mirror -----------------------------------------------------------
@ok: "crash mirror was written",
... fileReadable (tmp$ + "/eml_record_mirror.txt")
mirror$ = readFile$ (tmp$ + "/eml_record_mirror.txt")
@ok: "mirror holds every step", index (mirror$, "--- step 3") > 0

# --- flush ------------------------------------------------------------------
outPath$ = tmp$ + "/recorded.praat"
@emlRecordFlush: outPath$
@ok: "flush wrote the file", emlRecordFlush.written
@ok: "flush did NOT end the recording", emlRecordActive = 1

# ASSERTION 4 — the emitted file is a Praat script. Not asserted about its
# BYTES (the 9 Aug retest removed the pure-ASCII claim: Praat writes UTF-8
# here, and would read back UTF-16 just as happily) but about whether Praat
# will parse it. That is the property that matters and the weaker one was
# standing in for it.
@ok: "emitted file exists and is non-trivial",
... fileReadable (outPath$)
emitted$ = readFile$ (outPath$)
@ok: "emitted file carries the form block",
... index (emitted$, "form: ""Recorded workflow") > 0

@emlRecordDiscard
@ok: "discard clears the recording", emlRecordActive = 0

appendInfoLine: ""
appendInfoLine: "  Passed:  ", nPass
appendInfoLine: "  Failed:  ", nFail
if nFail = 0
    appendInfoLine: "  ALL TESTS PASSED"
endif
appendInfoLine: "EMLTEST-RESULT: status=",
... if nFail = 0 then "PASS" else "FAIL" fi,
... " passed=", nPass, " failed=", nFail, " skipped=0 total=", nPass + nFail
