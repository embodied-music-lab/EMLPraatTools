# ---------------------------------------------------------------------------
# asciifold/drive.praat -- non-ASCII text pushed through the SHIPPED savers
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS DRIVES. @emlAsciiFold has exactly two call sites and both of them
# are on the way to disk: @emlReportToFile folds the whole report before
# writeFileLine:, and @eml_csvQuote folds every cell before it decides whether
# that cell needs quoting. This file does not call @emlAsciiFold. It calls the
# two SAVERS, with content of the kind the plugin and a voice researcher's own
# table actually contain, and lets the fold be reached the way a user reaches
# it -- because a check that called the fold directly would still pass on a
# build where nobody calls it, which is the whole failure being guarded.
#
# WHY THE CONTENT LOOKS LIKE THAT. Every character below comes from one of two
# places. The box rules, the middle dot, "chi^2", "eta^2", the plus-minus, the
# comparison signs and the Greek are what @emlReportHeader, @emlReportSection
# and the effect-size formatters put on the screen; they reach the file on
# essentially every save. The accented vowels, the curly quotes and the emoji
# come from the USER's side -- a group label typed in German or French, a note
# pasted out of a word processor with smart quotes on, a take name with an
# emoji in it. Praat rewrites the ENTIRE file as UTF-16 the moment one of them
# survives to writeFileLine:, so the difference between this content folding
# and not folding is the difference between a CSV and a file R, pandas and
# Excel report as binary.
#
# THE TREE IS SUBSTITUTED, NOT RELATIVE. Praat cannot take a variable in an
# `include`, so run.sh seds __EML_TREE__ to an absolute plugin folder and runs
# the staged copy. That is what lets the same driver be pointed at a build with
# the two call sites deleted, which is how this harness was shown red.
#
# ONE LEG PER PROCESS, launched by run.sh. The legs write into different
# writers and a leg that aborts must not take the evidence of the others with
# it.
#
# LEGS
#   report   @emlReportToFile      -- a report body carrying every class
#   csv      @emlExportStatsCSV    -- cells folded upstream of RFC 4180 quoting
#   info     @emlSaveInfoToFile    -- the Info window saved verbatim to disk
#   broom    @emlResultWrite       -- WITNESS ONLY, not a pass/fail leg; see
#                                     run.sh's WITNESS block for why
#
# Outputs, per leg, into the folder it is handed:
#   <leg>.outputs.tsv   key<TAB>value, one per line, ending in a DONE marker
#   plus whatever the saver actually wrote
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ---------------------------------------------------------------------------
form: "ASCII fold leg"
    sentence: "Leg", ""
    sentence: "Out", ""
endform

include __EML_TREE__/stats/eml-core-utilities.praat
include __EML_TREE__/stats/eml-output.praat
include __EML_TREE__/stats/eml-result-writer.praat

; ---------------------------------------------------------------------------
; @hostile -- the one body of text every leg is built from.
;
; Held in ONE place so the report leg and the Info leg cannot drift apart and
; so validate/v104 can be written against a fixed, enumerated set of
; substitutions rather than against whatever a leg happened to contain.
;
; A TAB IS IN HERE ON PURPOSE. The sweep at the end of @emlAsciiFold is
; written [^\x01-\x7F] rather than "printable", so tab (0x09) and newline
; (0x0A) fall inside the kept class and the file keeps its lines and its
; columns. Written as "printable" instead, this line would come back as one
; run of text with the group names welded together, and no byte-level check
; would notice because the result would still be perfectly good ASCII.
; ---------------------------------------------------------------------------
procedure hostile
    .text$ = "════════════════════════════════" + newline$
    ... + "EML Stats — Réanalyse · Sopranos" + newline$
    ... + "χ²(2) = 6.41, p ≤ .05, η² = 0.31" + newline$
    ... + "F0 220–440 Hz, ±3 dB, tilt −6°, σ = 1.2" + newline$
    ... + "Singer said “it felt easy”, then ‘open’." + newline$
    ... + "Groups:" + tab$ + "Mezzo Über" + tab$ + "Ténor Éric" + tab$
    ... + "Niño" + newline$
    ... + "Take 🎤 3 → best; ρ ≈ .48, ȳ = 3.1" + newline$
    ... + "────────────────────────────────"
    .nLines = 8
endproc

; ---------------------------------------------------------------------------
; @emit: .key$, .value$ -- append one line to this leg's outputs.tsv.
;
; APPENDED, NEVER ASSEMBLED IN MEMORY AND WRITTEN AT THE END. A leg that dies
; halfway through the saver must still leave behind what it managed to record,
; because "which key was the last one written" is the only thing that says
; where it died. The DONE marker at the bottom is what distinguishes a leg
; that finished from a leg that stopped.
;
; THE OUTPUTS FILE IS ITSELF PLAIN ASCII, deliberately: it carries file PATHS
; and counts and never the hostile text, so the evidence file cannot become
; UTF-16 and take the whole verdict with it.
; ---------------------------------------------------------------------------
procedure emit: .key$, .value$
    appendFileLine: out$ + "/" + leg$ + ".outputs.tsv", .key$, tab$, .value$
endproc

deleteFile: out$ + "/" + leg$ + ".outputs.tsv"
@emit: "leg", leg$

if leg$ = "report"
    @hostile
    @emlReportToFile: out$ + "/report.txt", hostile.text$
    @emit: "success", string$ (emlReportToFile.success)
    @emit: "path", emlReportToFile.actualPath$
    @emit: "folded", string$ (emlReportToFile.folded)
    @emit: "inLines", string$ (hostile.nLines)

elsif leg$ = "csv"
    ; A REAL BUFFER THROUGH THE REAL ACCUMULATOR. @emlCSVAddStr and @emlCSVAdd
    ; are what every orchestrator calls; going straight to @eml_csvQuote would
    ; skip the table name and the term type, which are cells too and are the
    ; ones a user's own table name lands in.
    @emlCSVInit
    @emlCSVSetTable: "Étude · Sopranos"
    @emlCSVTermType: "group"
    ; The curly-quote cell is the load-bearing one. The fold TURNS a curly
    ; quote into a straight quote, so a build that folded after the quote test
    ; would leave a bare " inside an unquoted field, and R reads that cell back
    ; with the quotes silently dropped and reports no error at all.
    @emlCSVAddStr: "descriptives", "Mezzo Über", "note",
    ... "singer said “it felt easy”"
    ; This one already contains a comma, so it must be quoted whatever the fold
    ; does -- it is the control for the cell above.
    @emlCSVAddStr: "descriptives", "Ténor Éric", "range", "220–440 Hz, ±3 dB"
    @emlCSVAddStr: "descriptives", "χ² block", "symbol", "χ² and η²"
    @emlCSVAddStr: "descriptives", "Niño", "mic", "take 🎤 3 at 20°C"
    @emlCSVAdd: "descriptives", "Mezzo Über", "mean", 220.5
    @emlExportStatsCSV: out$ + "/stats.csv"
    @emit: "success", string$ (emlExportStatsCSV.success)
    @emit: "path", emlExportStatsCSV.actualPath$
    @emit: "reason", emlExportStatsCSV.reason$
    @emit: "rows", string$ (emlCSV_n)

elsif leg$ = "info"
    ; THE INFO WINDOW IS NOT FOLDED and must not be -- on screen "χ²" and the
    ; box rules are the better rendering and nothing parses them. What has to
    ; be plain is the FILE, and @emlSaveInfoToFile reaches disk through
    ; @emlReportToFile, so this leg is the proof that the save button on the
    ; Info window is covered by the same fold as the report writer.
    @hostile
    @emlClearInfo
    appendInfoLine: hostile.text$
    @emlSaveInfoToFile: out$ + "/info.txt"
    @emit: "success", string$ (emlSaveInfoToFile.success)
    @emit: "path", emlSaveInfoToFile.actualPath$
    @emit: "inLines", string$ (hostile.nLines)

elsif leg$ = "broom"
    ; WITNESS, NOT A VERDICT. @emlResultWrite is the three-file broom exporter
    ; and it quotes through @eml_rwQuote, which is a separate RFC 4180 routine
    ; that does NOT fold. Driving it here records what actually lands on disk
    ; so the gap is measured rather than argued about; run.sh does not fail on
    ; it and validate/v104 does not assert on its bytes.
    @emlCSVInit
    @emlResultBegin: "Étude · Sopranos", "anova"
    @emlTidyRow: "Mezzo Über"
    @emlTidyNum: "estimate", 220.5
    @emlTidyStr: "method", "χ² test at 20°"
    @emlGlanceStr: "method", "take 🎤 3"
    @emlResultWrite: out$ , "broom"
    @emit: "written", string$ (emlResultWrite.written)
    @emit: "files", replace$ (emlResultWrite.files$, newline$, " ", 0)

else
    @emit: "error", "unknown leg"
    exitScript: "asciifold/drive.praat: unknown leg " + leg$
endif

@emit: "DONE", leg$
writeInfoLine: "ASCIIFOLD DONE leg=", leg$
