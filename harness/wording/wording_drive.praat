# Drive the five reports whose wording the statistical-wording pass changed,
# headlessly, with the explanation column ON, so the sentences a user reads
# can be read here rather than described.
#
#   1. one-way ANOVA          (F gloss, p gloss, eta-squared gloss)
#   2. two-way ANOVA          (all three partial eta-squareds, interaction
#                              caveat)
#   3. Kruskal-Wallis         (H gloss, epsilon-squared gloss)
#   4. independent t test     (t gloss, Cohen's d, rank-biserial note path)
#   5. normality              (the shared Recommendation block)
#
# The standalone normality WRAPPER is a GUI script and is driven separately;
# what runs here is the orchestrator and reporter it calls.

# The barrel's own includes are relative to the TOP-LEVEL script's folder,
# which is this one, so the leaf files are named directly -- the pattern every
# other harness case uses. Order follows eml-lib-stats.praat then
# eml-lib-graphs.praat. eml-record.praat is loaded exactly once: it contains
# `label` statements and a second textual paste is a duplicate-label parse
# error.
include ../../plugin_EML_StatsGraphs/stats/eml-core-utilities.praat
include ../../plugin_EML_StatsGraphs/stats/eml-core-descriptive.praat
include ../../plugin_EML_StatsGraphs/stats/eml-extract.praat
include ../../plugin_EML_StatsGraphs/stats/eml-output.praat
include ../../plugin_EML_StatsGraphs/stats/eml-inferential.praat
include ../../plugin_EML_StatsGraphs/stats/eml-result-writer.praat
include ../../plugin_EML_StatsGraphs/stats/eml-record.praat
include ../../plugin_EML_StatsGraphs/stats/eml-analysis.praat
include ../../plugin_EML_StatsGraphs/graphs/eml-graph-procedures.praat
include ../../plugin_EML_StatsGraphs/graphs/eml-annotation-procedures.praat

outDir$ = environment$ ("EML_OUT")
if outDir$ = ""
    outDir$ = "."
endif
createDirectory: outDir$

emlShowExplanations = 1

# ── 1. one-way ANOVA ────────────────────────────────────────────────────────
writeInfoLine: ""
oneway = Read Table from comma-separated file: environment$ ("EML_ONEWAY")
onewayName$ = selected$ ("Table")
@emlRunAnovaAnalysis: oneway, "SPL_dB", "voice_type", 1
writeFile: outDir$ + "/01_oneway.txt", info$ ()

# ── 2. two-way ANOVA ────────────────────────────────────────────────────────
writeInfoLine: ""
twoway = Read Table from comma-separated file: environment$ ("EML_TWOWAY")
twowayName$ = selected$ ("Table")
@emlRunTwoWayAnalysis: twoway, "SPL_dB", "voice_type", "task"
writeFile: outDir$ + "/02_twoway.txt", info$ ()

# ── 3. Kruskal-Wallis ───────────────────────────────────────────────────────
writeInfoLine: ""
selectObject: oneway
@emlRunKruskalWallisAnalysis: oneway, "SPL_dB", "voice_type", 1, "holm"
writeFile: outDir$ + "/03_kruskal.txt", info$ ()

# ── 4. independent t test ───────────────────────────────────────────────────
writeInfoLine: ""
tt = Read Table from comma-separated file: environment$ ("EML_TWOGROUP")
ttName$ = selected$ ("Table")
@emlRunTwoGroupAnalysis: tt, "F0_Hz", "group", "both", 0
writeFile: outDir$ + "/04_ttest.txt", info$ ()

# ── 5. normality ────────────────────────────────────────────────────────────
writeInfoLine: ""
selectObject: oneway
@emlRunNormalityAnalysis: oneway, "SPL_dB", "both"
writeFile: outDir$ + "/05_normality.txt", info$ ()

writeInfoLine: "WORDING DRIVE OK"
