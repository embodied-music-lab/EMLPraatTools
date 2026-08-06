# Prove no cross-contamination between converted and unconverted paths, and
# between converted paths with different shapes.
#
# The failure this exists to catch, demonstrated 6 Aug 2026 before the entry
# guard was added: an orchestrator that fails its guards reaches `goto END_*`
# without ever calling @emlCSVInit, so the PREVIOUS analysis's declaration
# flag and collectors survive and the export writes them under the new
# analysis's name.
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
inDir$ = "../../evidence/csv/"
out$ = ""
nFail = 0

procedure expect: .what$, .got, .want
    if .got = .want
        out$ = out$ + "PASS  " + .what$ + newline$
    else
        out$ = out$ + "FAIL  " + .what$ + "  got " + string$ (.got)
        ... + " want " + string$ (.want) + newline$
        nFail = nFail + 1
    endif
endproc

# 1. A converted path declares.
t = Read Table from comma-separated file: inDir$ + "v09_anova_tukey_input.csv"
@emlRunAnovaAnalysis: t, "SPL_dB", "voice_type", 1
@expect: "converted path declares", emlResult_declared, 1
nTidyAfterAnova = emlTidy_nRows
removeObject: t

# 2. A path that FAILS ITS GUARDS must clear the flag, even though it never
#    reaches @emlCSVInit. This is the exact 6 Aug failure.
t = Read Table from comma-separated file: inDir$ + "demo_rm3_input.csv"
@emlRunRepeatedMeasuresAnalysis: t, "", "only_one_column", 1, "holm"
@expect: "guard-failing path clears the flag", emlResult_declared, 0
removeObject: t

# 3. An UNCONVERTED analysis after a converted one must not inherit.
t = Read Table from comma-separated file: inDir$ + "v09_anova_tukey_input.csv"
@emlRunAnovaAnalysis: t, "SPL_dB", "voice_type", 1
removeObject: t
t = Read Table from comma-separated file: inDir$ + "demo_3groups_input.csv"
@emlRunDescriptiveAnalysis: t, "SPL_dB"
@expect: "unconverted path does not inherit the flag", emlResult_declared, 0
removeObject: t

# 4. Two converted paths in a row: the second's frames must be its own, not
#    the first's. A two-way ANOVA declares 4 tidy rows; a correlation declares
#    2. If the collector leaked, the count would be wrong.
t = Read Table from comma-separated file: inDir$ + "v11_twoway_input.csv"
@emlRunTwoWayAnalysis: t, "SPL_dB", "voice_type", "task"
@expect: "two-way declares 4 tidy rows", emlTidy_nRows, 4
removeObject: t
t = Read Table from comma-separated file: inDir$ + "v12_correlation_input.csv"
@emlRunCorrelationAnalysis: t, "speaking_F0_Hz", "singing_F0_Hz", "both"
@expect: "correlation then declares 2, not 4 or 6", emlTidy_nRows, 2
@expect: "correlation writes no augment rows", emlAugment_nRows, 0
removeObject: t

# 5. Staged extras must not survive into a path that stages none.
t = Read Table from comma-separated file: inDir$ + "v09_anova_tukey_input.csv"
@emlRunAnovaAnalysis: t, "SPL_dB", "voice_type", 1
removeObject: t
hadExtras = (emlResult_extra1$ <> "")
t = Read Table from comma-separated file: inDir$ + "v15_normality_input.csv"
@emlRunNormalityAnalysis: t, "F0_Hz", "both"
@expect: "ANOVA had staged extras", hadExtras, 1
@expect: "normality clears the staged extras", (emlResult_extra1$ <> ""), 0
removeObject: t

writeInfoLine: out$
appendInfoLine: nFail, " failures"
