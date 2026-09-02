# ---------------------------------------------------------------------------
# graphseams/driver_kw_adv.praat — the standalone annotated Kruskal-Wallis draw
# ---------------------------------------------------------------------------
# THIS IS THE LEG THAT MEETS THE CRASH, AND THE REASON IT IS A SEPARATE LEG IS
# WORTH THE PARAGRAPH, because the first version of this harness had one KW leg
# and its break test PASSED.
#
# NEW-G9-1 is "Unknown variable: emlKruskalWallis.rMatrix##", fired from
# @emlReportKWComparison on the significant branch, where .doDunn = 1 makes the
# reporter skip its own fallback compute and read a matrix it believes an
# orchestrator left for it. stats/eml-analysis.praat DOES leave one --
# @emlRunKruskalWallisAnalysis copies it out of @emlDunnTest one line after the call. So a
# leg that runs the wrapper's analysis before handing over to the form has
# already populated the global, and the bridge's failure to populate it is
# INVISIBLE: driven 15 Aug 2026 with the bridge's copy deleted, that leg
# completed all six dialogs, saved a figure, and wrote a report with all three
# rank-biserial values in it. A drive that cannot fail is not evidence.
#
# The audit's own reproduction is the STANDALONE journey and says so: "Table
# with 3 groups (significant KW) -> EML Graphs -> Violin -> advanced ->
# Annotate ON -> Test type = Nonparametric -> Draw". Nothing has run. The
# graphs bridge is the only thing that ever calls @emlKruskalWallis in that
# session, and if it does not declare the matrix, nobody has.
#
# SO THIS LEG RUNS NO ANALYSIS. The presets carry only what a user's choices
# carry: the graph type, the two columns, and -- through the annotate preset
# and the test type -- the state the advanced dialog opens in. run.sh seeds
# `showAdvanced: 1` into the config, which is what an advanced page looks like
# to a user who has ever pressed the toggle, and is the only way to reach the
# advanced page without spending a dialog on the toggle itself.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ---------------------------------------------------------------------------
include ../stress_cases/_prelude.praat
include ../../plugin/stats/eml-result-writer.praat
include ../../plugin/stats/eml-record.praat
include ../../plugin/stats/eml-analysis.praat
include ../../plugin/graphs/eml-graphs-form.praat

table = Read Table from comma-separated file: "fixtures/demo_3groups.csv"
tableId = selected ("Table")
appendInfoLine: "SEAMS kwadv begin tableId=", tableId

emlGraphsPresetType = 7
emlGraphsPresetDataCol$ = "SPL_dB"
emlGraphsPresetGroupCol$ = "voice_type"
emlGraphsPresetTestType$ = "nonparametric"
emlGraphsPresetAnnotate = 1
emlGraphsPresetCorrection$ = "holm"

@emlGraphsWorkflow: tableId

appendInfoLine: "SEAMS kwadv end"
