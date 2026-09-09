# ============================================================================
# evidence/redrive/kit_cleandata_other_doors.praat — drive the ONE level-2
# fixture each for the seven "other" doors that sit on the shared
# refuse-or-repair gate but were not named individually in
# ANSWER_DATA_CLEANING_ESTIMATE_PART1: normality, Kruskal-Wallis, two-way,
# paired, repeated measures, survey items (reliability) and survey counts
# (categorical). No level-1 fixture here -- the repair itself is proved once,
# in the extraction layer (test-extract.praat D96) and in the four named
# doors' own level-1 fixtures.
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Every table below carries exactly one genuinely unreadable cell ("??"),
# which @eml_cleanVerdict classifies kind 6 regardless of column mode -- it
# is refused under the SAME complete-case convention as before this ruling,
# in every one of these doors. None of these procedures use beginPause:, so
# this runs under `praat --run` with no X server, the same way
# kit_cleandata_named_doors.praat does for the four named doors.
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
include ../../plugin/stats/eml-psychometrics.praat
include ../../plugin/stats/eml-studentized-range.praat
include ../../plugin/stats/eml-anova-kernel.praat
include ../../plugin/stats/eml-wilcoxon-interval.praat
include ../../plugin/stats/eml-inferential.praat
include ../../plugin/stats/eml-categorical.praat
include ../../plugin/stats/eml-result-writer.praat
include ../../plugin/graphs/eml-annotation-procedures.praat
include ../../plugin/stats/eml-analysis.praat

Text writing preferences: "UTF-8"
emlShowExplanations = 0
emlWizardExplain$ = ""

# --- Kruskal-Wallis ---------------------------------------------------------
writeInfo: ""
t = Read Table from comma-separated file: "../csv/kit_cleandata_l2_kruskal_input.csv"
@emlRunKruskalWallisAnalysis: t, "value", "group", 0, "holm"
text$ = info$ ()
if left$ (text$, 1) = newline$
    text$ = right$ (text$, length (text$) - 1)
endif
writeFile: "../info/kit_cleandata_l2_kruskal_info.txt", text$
removeObject: t

# --- Two-way ANOVA (strict=1 data column: refuses the WHOLE analysis) ------
writeInfo: ""
t = Read Table from comma-separated file: "../csv/kit_cleandata_l2_twoway_input.csv"
@emlRunTwoWayAnalysis: t, "value", "f1", "f2", 3
text$ = info$ () + newline$ + newline$
... + "emlRunTwoWayAnalysis.error$ = """ + emlRunTwoWayAnalysis.error$ + """"
if left$ (text$, 1) = newline$
    text$ = right$ (text$, length (text$) - 1)
endif
writeFile: "../info/kit_cleandata_l2_twoway_info.txt", text$
removeObject: t

# --- Normality ---------------------------------------------------------
writeInfo: ""
t = Read Table from comma-separated file: "../csv/kit_cleandata_l2_normality_input.csv"
@emlRunNormalityAnalysis: t, "value", "single"
text$ = info$ ()
if left$ (text$, 1) = newline$
    text$ = right$ (text$, length (text$) - 1)
endif
writeFile: "../info/kit_cleandata_l2_normality_info.txt", text$
removeObject: t

# --- Paired ------------------------------------------------------------
writeInfo: ""
t = Read Table from comma-separated file: "../csv/kit_cleandata_l2_paired_input.csv"
@emlRunPairedAnalysis: t, "pre", "post", "both"
text$ = info$ ()
if left$ (text$, 1) = newline$
    text$ = right$ (text$, length (text$) - 1)
endif
writeFile: "../info/kit_cleandata_l2_paired_info.txt", text$
removeObject: t

# --- Reliability (survey items, Cronbach's alpha) ---------------------------
writeInfo: ""
t = Read Table from comma-separated file: "../csv/kit_cleandata_l2_reliability_input.csv"
items$# = { "item1", "item2", "item3" }
@emlRunReliabilityAnalysis: t, items$#, 0.95, 0
text$ = info$ () + newline$ + newline$
... + "emlRunReliabilityAnalysis.error$ = """ + emlRunReliabilityAnalysis.error$ + """"
if left$ (text$, 1) = newline$
    text$ = right$ (text$, length (text$) - 1)
endif
writeFile: "../info/kit_cleandata_l2_reliability_info.txt", text$
removeObject: t

# --- Categorical (survey counts, strict=1 count column) --------------------
writeInfo: ""
t = Read Table from comma-separated file: "../csv/kit_cleandata_l2_categorical_input.csv"
@emlRunCategoricalAnalysis: t, "rowvar", "colvar", "count", 1
text$ = info$ () + newline$ + newline$
... + "emlRunCategoricalAnalysis.error$ = """ + emlRunCategoricalAnalysis.error$ + """"
if left$ (text$, 1) = newline$
    text$ = right$ (text$, length (text$) - 1)
endif
writeFile: "../info/kit_cleandata_l2_categorical_info.txt", text$
removeObject: t

# --- Repeated measures (wide format) ----------------------------------------
writeInfo: ""
t = Read Table from comma-separated file: "../csv/kit_cleandata_l2_rm_input.csv"
conds$# = { "soft", "medium", "loud" }
@emlRunRepeatedMeasuresAnalysis: t, "wide", "", conds$#, "", "", 0, "holm"
text$ = info$ () + newline$ + newline$
... + "emlRunRepeatedMeasuresAnalysis.error$ = """
... + emlRunRepeatedMeasuresAnalysis.error$ + """"
if left$ (text$, 1) = newline$
    text$ = right$ (text$, length (text$) - 1)
endif
writeFile: "../info/kit_cleandata_l2_rm_info.txt", text$
removeObject: t

appendInfoLine: "kit_cleandata_other_doors: done"
