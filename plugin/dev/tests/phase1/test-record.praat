# ============================================================================
# EML Praat Tools — test: record workflow foundation
# ============================================================================
# Covers @emlRecordBegin/Step/Result/Source/Flush, @emlPhrase, and the
# renderer. No wrapper is touched and no GUI is needed.
#
# WHAT CHANGED ON 9 AUG 2026, AND WHY THE OLD ASSERTIONS ARE GONE.
#
# The first cut carried a path registry: every path the session touched was
# registered, given a form-variable name by role, and resolved from a token
# into a `form:` block at flush, so the emitted file could be re-run anywhere
# by pressing OK. Roughly a third of this file tested that.
#
# It was machinery in service of the emission level. Emitting wrapper-level
# `runScript:` calls meant the file had to bootstrap itself — find the
# plugin, read the input, name the outputs — and each of those needed a path.
# Emitting at the API level instead (an `include` block, and whatever object
# the user has selected) removes the requirement rather than meeting it, and
# it is also the only form that RUNS: a wrapper cannot be called headless
# because every wrapper uses `beginPause:`.
#
# So the path assertions are replaced by include-block assertions, and one
# new assertion covers what the registry was really protecting — that the
# record states WHICH object it describes.
#
# The §8.10 assertions that survive are still here: every buffer row has a
# non-empty code slot; a missing phrase key is marked, not silent; the file
# Praat writes is a file Praat parses. The pure-ASCII assertion is
# deliberately absent — see the header of eml-record.praat.
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

@ok: "the include block's root is resolved, not blank",
... emlRecordPluginRoot$ <> ""

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

# --- source provenance ------------------------------------------------------
; What the path registry was really protecting. "Whatever is selected" gives
; a reader no way to check that the right thing was selected, so the record
; names the object by name and shape.
Create Table with column names: "probeTable", 0, "a b"
Append row
probeId = selected ("Table")
@emlRecordSource: probeId
@eq$: "source object name recorded", emlRecordHeaderInput$, "probeTable"
@ok: "source shape recorded",
... emlRecordHeaderRows = 1 and emlRecordHeaderCols = 2
removeObject: probeId

@emlRecordHeader: "demo_3groups_input.csv", 45, 4, "9 August 2026, 13:18"

# --- steps ------------------------------------------------------------------
@emlPhrase: "read.intent", "the table", "", "", "", "", ""
@emlRecordStep: "analysis", emlPhrase.result$, "",
... "table = selected (""Table"")", ""

; COMPOSITION. Praat procedure locals are one namespace per PROCEDURE, not
; per call, so the first result must be captured before the second call or it
; is overwritten. Written the wrong way round, step 2 renders narrated
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
... "@emlRunAnovaAnalysis: table, ""SPL_dB"", ""voice_type"", 1",
... "In the GUI: New > EML Tools > Compare k groups (ANOVA)..."
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

@ok: "an include block is emitted", index (body$, "include ") > 0
@ok: "the include block is headed as the one thing to edit",
... index (body$, "edit this block and nothing else") > 0
@ok: "the barrel trap is stated, not left to be discovered",
... index (body$, "barrel eml-lib-stats.praat will NOT work") > 0
@ok: "no form block is emitted any more",
... index (body$, "form: ""Recorded workflow") = 0
@ok: "the file takes whatever Table is selected",
... index (body$, "table = selected (""Table"")") > 0
@ok: "the recorded object is named for the reader",
... index (body$, "Recorded against: demo_3groups_input.csv") > 0

; ASSERTION 2, in its new form. The old one checked that every path used in
; the body was declared in the form block above it. There is no form block,
; and the equivalent property is that the procedure the body calls lives in a
; file the include block loads.
@ok: "ASSERTION 2 — the procedure the body calls is in the included tree",
... index (body$, "eml-analysis.praat") > 0
... and index (body$, "@emlRunAnovaAnalysis") > 0

@ok: "a refusal step is visually distinct",
... index (body$, "--- Step 3 (refusal) ---") > 0
@ok: "the codeless refusal is a comment, not a blank",
... index (body$, "; (nothing executed at this step") > 0

@ok: "Stream A text landed in a comment, not in code",
... index (body$, "# F(2, 42) = 14.2687") > 0
@ok: "the GUI route is recorded as a comment",
... index (body$, "# In the GUI: New > EML Tools") > 0

; The blank-line discipline: the line before an executable call must be
; empty, and so must the line after it.
runIdx = index (body$, "@emlRunAnovaAnalysis: table")
before$ = left$ (body$, runIdx - 1)
@ok: "a blank line precedes the executable block",
... right$ (before$, 2) = newline$ + newline$

; The composition trap, asserted rather than trusted to the note.
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
@ok: "emitted file exists", fileReadable (outPath$)

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
