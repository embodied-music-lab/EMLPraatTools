# Drive the SHIPPING one-way ANOVA orchestrator twice on the SAME committed
# input, changing only the data column, and save both Info windows.
#
# Ruling 1 is a CONDITIONAL behaviour, so one capture cannot demonstrate it.
# It takes two, from the same file, differing in nothing a reader has to take
# on trust:
#
#   SPL_dB           Brown-Forsythe p = .678  ->  block ABSENT
#   vibrato_rate_Hz  Brown-Forsythe p = .030  ->  block PRESENT
#
# The absent case is the load-bearing one. It is what "never replace, never
# auto-switch" means operationally: on data that does not trip the check, a
# run must look exactly as it did before this feature existed, apart from the
# two equal-spread lines. v25 asserts the absence by name.
#
# Same include reasoning as anova_shipping_drive.praat: NOT the eml-lib
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

fixture$ = environment$ ("EML_FIXTURE")
if fixture$ = ""
    fixture$ = "../../evidence/csv/v09_anova_tukey_input.csv"
endif

nDriven = 0

; --- Case 1: equal spreads. The conditional block must NOT appear. ---------
; clearinfo, not just a fresh writeFile: info$() returns the CUMULATIVE Info
; window, so without this the second capture contains the first run as well.
; Found the hard way -- the "absent" assertion below would still have passed
; and the "present" capture would have carried two ANOVAs under one header.
clearinfo
tid = Read Table from comma-separated file: fixture$
@emlRunAnovaAnalysis: tid, "SPL_dB", "voice_type", 1
writeFile: outDir$ + "/v25_showboth_absent_info.txt", info$ ()
nDriven += 1
removeObject: tid

; --- Case 2: unequal spreads. The conditional block must appear. -----------
; Same file, same group column, same Tukey setting. Only the data column
; differs, so nothing else can explain a difference between the two captures.
clearinfo
tid = Read Table from comma-separated file: fixture$
@emlRunAnovaAnalysis: tid, "vibrato_rate_Hz", "voice_type", 1
writeFile: outDir$ + "/v25_showboth_present_info.txt", info$ ()
nDriven += 1
removeObject: tid

writeInfoLine: "captures written: ", nDriven
appendInfoLine: outDir$ + "/v25_showboth_absent_info.txt"
appendInfoLine: outDir$ + "/v25_showboth_present_info.txt"
