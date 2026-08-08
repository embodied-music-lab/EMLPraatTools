# Re-drive the two k-group orchestrator captures that D110 changes.
#
# D110 moved the one-way ANOVA source-table p cell and the Tukey and Dunn
# post-hoc matrices from fixed$ (p, n) to @emlFormatP's bare APA form. Those
# strings are read by validate/v09 and validate/v10 out of captures that were
# produced by a GUI session on 5 August 2026, so the captures have to be
# re-made from the shipping code before the checks can be updated.
#
# THIS IS NOT A CLICK-DRIVEN RUN. It calls the same orchestrators the menu
# calls, on the same committed inputs, under praat --run. What it costs is the
# click-through provenance the 5 August captures had; validate/README.md
# §"What a green run does and does not establish" is the statement of that
# distinction, and the headers of v09 and v10 now say which kind of evidence
# each capture is.
#
# Same include reasoning as anova_showboth_drive.praat: NOT the eml-lib
# barrel, because Praat resolves a relative include against the TOP-LEVEL
# script's directory and the barrel's paths are written from plugin/scripts/.
include ../../plugin/stats/eml-core-utilities.praat
include ../../plugin/stats/eml-core-descriptive.praat
include ../../plugin/stats/eml-extract.praat
include ../../plugin/stats/eml-output.praat
include ../../plugin/stats/eml-inferential.praat
include ../../plugin/stats/eml-result-writer.praat
include ../../plugin/stats/eml-analysis.praat
include ../../plugin/graphs/eml-graph-procedures.praat
include ../../plugin/graphs/eml-annotation-procedures.praat

Text writing preferences: "UTF-8"

outDir$ = environment$ ("EML_OUT_DIR")
if outDir$ = ""
    outDir$ = "../../evidence/info"
endif
createDirectory: outDir$

csvDir$ = environment$ ("EML_CSV_DIR")
if csvDir$ = ""
    csvDir$ = "../../evidence/csv"
endif

nDriven = 0

; --- v09: one-way ANOVA with Tukey HSD ------------------------------------
; clearinfo before EVERY capture: info$() returns the CUMULATIVE Info window,
; so without it the second file silently carries the first run as well.
clearinfo
tid = Read Table from comma-separated file: csvDir$ + "/v09_anova_tukey_input.csv"
@emlRunAnovaAnalysis: tid, "SPL_dB", "voice_type", 1
writeFile: outDir$ + "/v09_anova_tukey_info.txt", info$ ()
nDriven += 1
removeObject: tid

; --- v10: Kruskal-Wallis with Dunn post-hoc, Holm-adjusted -----------------
; Same table as v09 (the two committed CSVs are byte-identical), which is what
; lets v10 re-check the group sizes and the rank ordering against v09.
clearinfo
tid = Read Table from comma-separated file: csvDir$ + "/v10_kw_dunn_input.csv"
@emlRunKWAnalysis: tid, "SPL_dB", "voice_type", 1, "holm"
writeFile: outDir$ + "/v10_kw_dunn_info.txt", info$ ()
nDriven += 1
removeObject: tid

writeInfoLine: "captures written: ", nDriven
appendInfoLine: outDir$ + "/v09_anova_tukey_info.txt"
appendInfoLine: outDir$ + "/v10_kw_dunn_info.txt"
