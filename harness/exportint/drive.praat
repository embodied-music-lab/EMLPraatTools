# ============================================================================
# exportint/drive.praat -- EXPORT INTEGRITY: what reaches disk, and what the
# refusal text is allowed to claim.
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS HARNESS EXISTS. The 14 August 2026 audit found four defects that
# share one property: every number on screen was right. NEW-G1-1 exported one
# of three tested columns, and the one it exported was correct to 1e-11.
# NEW-G4-1 exported a residual under broom's name that was not broom's, and
# understated it by a flat 4.4% on a balanced design. NEW-G6-1 diagnosed
# "every subject shows exactly the same pattern" after silently dropping half
# the subjects. NEW-G12-3 buried a refusal in the report and put "Analysis
# complete" on the modal. None of these is a wrong statistic; all of them are
# a wrong CLAIM ABOUT a statistic, and no numeric check can see one.
#
# So the artefact this harness produces is not a table of statistics. It is a
# record of SHAPE and of TEXT: how many rows the tidy frame has against how
# many columns were tested, which augment columns exist, and what an
# orchestrator's .error$ says at the moment it hands control back to a
# wrapper.
#
#     EML_EXPORTINT_OUT=harness/exportint/out \
#         praat --run harness/exportint/drive.praat
#
# NO beginPause ANYWHERE. Every wrapper in plugin/scripts opens with one, and
# `praat --run` hard-crashes on it (Trace/breakpoint trap, exit 133 -- see
# harness/normality/case.praat). This driver therefore calls the SHIPPING
# orchestrators and the SHIPPING export surface directly, which is the layer
# every one of the four defects lives in. The one thing it reproduces rather
# than calls is the check-normality wrapper's per-column FOR LOOP, three
# lines of it; validate/v57_export_integrity.R pins that loop's shape against
# plugin/scripts/eml-check-normality.praat statically, so the reproduction
# cannot drift away from the wrapper without the suite saying so.
#
# THE FIXTURES ARE THE AUDIT'S OWN. fixtures/demo_normality.csv is byte-for-
# byte the fleet fixture the audit drove (fleet_fixtures_demo_normality.csv),
# so the three-file output this writes is comparable with the evidence pack's
# aud51_out_normsave_* files rather than merely similar to them. The redpath
# CSVs are read from validate/redpath, which is where the committed
# degenerate cases already live.
#
# Output (all under $EML_EXPORTINT_OUT):
#   norm/<stem>_tidy.csv     the three-file set, exactly as @emlSavePanel
#   norm/<stem>_glance.csv   would have written it
#   aug/anova1_augment.csv   one-way ANOVA augment frame
#   aug/anova2_augment.csv   two-way ANOVA augment frame
#   info/<case>.txt          the Info window verbatim, per case
#   shape.tsv                case <TAB> key <TAB> value      (no header)
#   refusals.tsv             case <TAB> field <TAB> text     (no header)
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

include ../../plugin/stats/eml-core-utilities.praat
include ../../plugin/stats/eml-core-descriptive.praat
include ../../plugin/stats/eml-extract.praat
include ../../plugin/stats/eml-output.praat
include ../../plugin/stats/eml-inferential.praat
include ../../plugin/stats/eml-result-writer.praat
include ../../plugin/stats/eml-analysis.praat
# The report PRINTERS live in the annotation layer, not the stats layer --
# same include set as harness/normality/case.praat and harness/coltype.
include ../../plugin/graphs/eml-graph-procedures.praat
include ../../plugin/graphs/eml-annotation-procedures.praat
include ../../plugin/graphs/eml-draw-procedures.praat

Text writing preferences: "UTF-8"

outDir$ = environment$ ("EML_EXPORTINT_OUT")
if outDir$ = ""
    outDir$ = "../../harness/exportint/out"
endif
createDirectory: outDir$
createDirectory: outDir$ + "/norm"
createDirectory: outDir$ + "/aug"
createDirectory: outDir$ + "/info"

fixDir$ = "../../harness/exportint/fixtures"
redDir$ = "../../validate/redpath"

shape$ = ""
refuse$ = ""

procedure shape: .case$, .key$, .value$
    shape$ = shape$ + .case$ + tab$ + .key$ + tab$ + .value$ + newline$
endproc

procedure refusal: .case$, .field$, .text$
    ; Newlines would split one refusal across two TSV rows and the reader
    ; would score half a message. The refusal text is a paragraph by design
    ; (the gold-standard modal wraps it), so this is not hypothetical.
    .flat$ = replace$ (.text$, newline$, " ", 0)
    .flat$ = replace$ (.flat$, tab$, " ", 0)
    refuse$ = refuse$ + .case$ + tab$ + .field$ + tab$ + .flat$ + newline$
endproc

procedure saveInfo: .case$
    .txt$ = info$ ()
    writeFile: outDir$ + "/info/" + .case$ + ".txt", .txt$
endproc

; Alphabetical group order, so a group index here is the index R's factor()
; gives. Same reason as harness/coltype and harness/normality.
emlGroupSortAlphabetical = 1

# ---------------------------------------------------------------------------
# CASE A -- multi-column normality, saved once. NEW-G1-1.
# ---------------------------------------------------------------------------
# This is the "Check normality (all columns)" journey: ONE press of Run, one
# pass over every numeric column, then ONE press of Save. The wrapper's loop
# is reproduced here because its first statement is beginPause.
writeInfo: ""
Read Table from comma-separated file: fixDir$ + "/demo_normality.csv"
normId = selected ("Table")
Rename: "demo_normality"

nCols = Get number of columns
nNumeric = 0
for iCol from 1 to nCols
    .cn$ = Get column label: iCol
    @emlCheckNumericColumn: normId, .cn$
    if emlCheckNumericColumn.isNumeric
        nNumeric = nNumeric + 1
        numCol$ [nNumeric] = .cn$
    endif
endfor
@shape: "normsave", "columns_tested", string$ (nNumeric)
; The column NAMES, not just the count. Two counts can agree by coincidence
; -- one column dropped and one duplicated is a wash -- and a count cannot
; say WHICH column fell out of the export. Same argument as @eml_census.
colList$ = numCol$ [1]
for iSel from 2 to nNumeric
    colList$ = colList$ + "," + numCol$ [iSel]
endfor
@shape: "normsave", "columns_named", colList$

for iSel from 1 to nNumeric
    selectObject: normId
    @emlRunNormalityAnalysis: normId, numCol$ [iSel], "both"
    if emlRunNormalityAnalysis.error$ <> ""
        @refusal: "normsave", "column_error", emlRunNormalityAnalysis.error$
    endif
endfor

@shape: "normsave", "declared", string$ (emlResult_declared)
@emlExportResultFiles: outDir$ + "/norm", "demo_normality_normality"
@shape: "normsave", "files_written", string$ (emlExportResultFiles.nWritten)
@shape: "normsave", "skipped", replace$ (emlExportResultFiles.skipped$,
    ... newline$, " | ", 0)
@saveInfo: "normsave"
selectObject: normId
Remove

# ---------------------------------------------------------------------------
# CASE B -- one-way ANOVA augment. NEW-G4-1, group arm.
# ---------------------------------------------------------------------------
writeInfo: ""
Read Table from comma-separated file: fixDir$ + "/demo_3groups.csv"
anova1Id = selected ("Table")
Rename: "demo_3groups"
@emlRunAnovaAnalysis: anova1Id, "SPL_dB", "voice_type", 1
@refusal: "anova1", "error", emlRunAnovaAnalysis.error$
@emlResultWrite: outDir$ + "/aug", "anova1"
@shape: "anova1", "files_written", string$ (emlResultWrite.written)
@saveInfo: "anova1"
selectObject: anova1Id
Remove

# ---------------------------------------------------------------------------
# CASE C -- two-way ANOVA augment, the BALANCED demo the audit measured on.
# ---------------------------------------------------------------------------
writeInfo: ""
Read Table from comma-separated file: fixDir$ + "/demo_twoway.csv"
anova2Id = selected ("Table")
Rename: "demo_twoway"
@emlRunTwoWayAnalysis: anova2Id, "SPL_dB", "voice_type", "task"
@refusal: "anova2", "error", emlRunTwoWayAnalysis.error$
@emlResultWrite: outDir$ + "/aug", "anova2"
@shape: "anova2", "files_written", string$ (emlResultWrite.written)
@saveInfo: "anova2"
selectObject: anova2Id
Remove

# ---------------------------------------------------------------------------
# CASE D -- repeated measures on incomplete cases. NEW-G6-1.
# ---------------------------------------------------------------------------
# r1_incomplete_cases.csv: 8 rows, 4 of them complete, and the 4 complete
# ones happen to be exactly base + 0 / + 10 / + 20. So the omnibus refuses
# with the D97 zero-residual diagnosis -- computed over 4 subjects, described
# as "every subject".
writeInfo: ""
Read Table from comma-separated file: redDir$ + "/r1_incomplete_cases.csv"
rmId = selected ("Table")
Rename: "r1_incomplete"
@emlRunRepeatedMeasuresAnalysis: rmId, "singer",
    ... "SPL_soft|SPL_medium|SPL_loud", 1, "holm"
@refusal: "rm_incomplete", "error", emlRunRepeatedMeasuresAnalysis.error$
@refusal: "rm_incomplete", "remedy", emlRunRepeatedMeasuresAnalysis.remedy$
@saveInfo: "rm_incomplete"
selectObject: rmId
Remove

# CASE D2 -- Friedman, same table, same exclusion.
writeInfo: ""
Read Table from comma-separated file: redDir$ + "/r1_incomplete_cases.csv"
frId = selected ("Table")
Rename: "r1_incomplete_fr"
@emlRunFriedmanAnalysis: frId, "singer",
    ... "SPL_soft|SPL_medium|SPL_loud", 1, "holm"
@refusal: "friedman_incomplete", "error", emlRunFriedmanAnalysis.error$
@saveInfo: "friedman_incomplete"
selectObject: frId
Remove

# CASE D3 -- the extractor's own refusal, with an exclusion behind it.
# Two complete rows are needed; this table leaves one.
writeInfo: ""
Create Table with column names: "r1_thin", 0, "a b"
for k to 4
    Append row
    row = Get number of rows
    if k = 1
        Set numeric value: row, "a", 1
        Set numeric value: row, "b", 2
    else
        Set numeric value: row, "a", k
        Set string value: row, "b", ""
    endif
endfor
thinId = selected ("Table")
@emlRunRepeatedMeasuresAnalysis: thinId, "subject", "a|b", 0, "holm"
@refusal: "rm_thin", "error", emlRunRepeatedMeasuresAnalysis.error$
@saveInfo: "rm_thin"
selectObject: thinId
Remove

# CASE D4 -- an RM refusal with NOTHING excluded, so the disclosure checks
# have their opposite direction. r3_zero_variance.csv is complete: every row
# has every condition. The refusal must therefore carry no exclusion note at
# all -- a disclosure that appears unconditionally discloses nothing.
writeInfo: ""
Read Table from comma-separated file: redDir$ + "/r3_zero_variance.csv"
rmcId = selected ("Table")
Rename: "r3_complete"
@emlRunRepeatedMeasuresAnalysis: rmcId, "singer",
    ... "SPL_soft|SPL_medium|SPL_loud", 0, "holm"
@refusal: "rm_complete", "error", emlRunRepeatedMeasuresAnalysis.error$
@saveInfo: "rm_complete"
selectObject: rmcId
Remove

# ---------------------------------------------------------------------------
# CASE E -- paired comparison on zero-variance data. NEW-G12-3.
# ---------------------------------------------------------------------------
# r3_zero_variance.csv: every value is 80. Both families of test refuse. The
# question this case answers is what the ORCHESTRATOR tells the wrapper --
# an empty .error$ is what put "Analysis complete" over a refusal.
writeInfo: ""
Read Table from comma-separated file: redDir$ + "/r3_zero_variance.csv"
zvId = selected ("Table")
Rename: "r3zerovar"
@emlRunPairedAnalysis: zvId, "SPL_soft", "SPL_medium", "both"
@refusal: "paired_zerovar", "error", emlRunPairedAnalysis.error$
@refusal: "paired_zerovar", "remedy", emlRunPairedAnalysis.remedy$
@shape: "paired_zerovar", "declared", string$ (emlResult_declared)
@saveInfo: "paired_zerovar"
selectObject: zvId
Remove

# CASE E2 -- the parametric family alone, on the same data.
writeInfo: ""
Read Table from comma-separated file: redDir$ + "/r3_zero_variance.csv"
zv2Id = selected ("Table")
Rename: "r3zerovar_p"
@emlRunPairedAnalysis: zv2Id, "SPL_soft", "SPL_medium", "parametric"
@refusal: "paired_zerovar_param", "error", emlRunPairedAnalysis.error$
@saveInfo: "paired_zerovar_param"
selectObject: zv2Id
Remove

# CASE E3 -- a HEALTHY paired run, so the refusal checks have their
# opposite direction. A check that only ever sees the failing case cannot
# tell "refuses correctly" from "refuses always".
writeInfo: ""
Create Table with column names: "paired_ok", 0, "before_pct after_pct"
for k to 12
    Append row
    row = Get number of rows
    Set numeric value: row, "before_pct", 2.0 + (k mod 5) * 0.2
    Set numeric value: row, "after_pct", 2.9 + (k mod 4) * 0.22
endfor
okId = selected ("Table")
@emlRunPairedAnalysis: okId, "before_pct", "after_pct", "both"
@refusal: "paired_ok", "error", emlRunPairedAnalysis.error$
@shape: "paired_ok", "declared", string$ (emlResult_declared)
@saveInfo: "paired_ok"
selectObject: okId
Remove

# CASE A2 -- a SINGLE-column normality press on the same table, so the
# accumulation checks have their opposite direction too: one column tested
# must still write exactly one tidy row.
writeInfo: ""
Read Table from comma-separated file: fixDir$ + "/demo_normality.csv"
norm1Id = selected ("Table")
Rename: "demo_normality_one"
@emlRunNormalityAnalysis: norm1Id, "F0_Hz", "single"
@shape: "normsave_one", "columns_tested", "1"
@emlExportResultFiles: outDir$ + "/norm", "demo_normality_one_normality"
@shape: "normsave_one", "files_written",
    ... string$ (emlExportResultFiles.nWritten)
@saveInfo: "normsave_one"
selectObject: norm1Id
Remove

# CASE A3 -- two consecutive SINGLE-column presses on the same table, the
# wizard's shape. Each press is its own analysis and must not inherit the
# previous one's row: the fix for NEW-G1-1 accumulates within a press, and
# this is the case that says where a press ends.
writeInfo: ""
Read Table from comma-separated file: fixDir$ + "/demo_normality.csv"
norm2Id = selected ("Table")
Rename: "demo_normality_two"
@emlRunNormalityAnalysis: norm2Id, "F0_Hz", "single"
@emlRunNormalityAnalysis: norm2Id, "jitter_pct", "single"
@emlExportResultFiles: outDir$ + "/norm", "demo_normality_wizard2_normality"
@shape: "normsave_wizard2", "columns_tested", "1"
@shape: "normsave_wizard2", "files_written",
    ... string$ (emlExportResultFiles.nWritten)
@saveInfo: "normsave_wizard2"
selectObject: norm2Id
Remove

writeFile: outDir$ + "/shape.tsv", shape$
writeFile: outDir$ + "/refusals.tsv", refuse$
writeInfoLine: "exportint: done"
