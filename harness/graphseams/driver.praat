# ---------------------------------------------------------------------------
# graphseams/driver.praat — the Kruskal-Wallis wrapper's own handover, driven
# ---------------------------------------------------------------------------
# WHAT THIS DRIVE IS FOR. The 14 August 2026 audit's only crash reachable from
# a default journey: an annotated nonparametric draw on three or more groups
# died with
#
#     Unknown variable: emlKruskalWallis.rMatrix##
#
# and it fired ONLY when the omnibus was significant, because that is the
# branch on which @emlBridgeGroupComparison runs Dunn's test and
# @emlReportKWComparison therefore stops computing the pairwise rank-biserial
# matrix for itself and reads the one "the orchestrator guarantees". The
# graphs bridge is a second orchestrator and guaranteed nothing. The whole
# graphs session went with it: no figure, no pause form, a truncated report,
# and a Praat error telling the user to change something in a window that no
# longer existed.
#
# SO THE TABLE HERE IS NOT ARBITRARY. Three groups, well separated, so the
# Kruskal-Wallis omnibus lands far below alpha and the significant branch is
# the one taken. A table that failed to reach significance would run the
# other branch, produce a perfectly clean figure, and prove nothing -- the
# same shape of empty experiment harness/gui_adv records for its own first
# version. The fixture is the audit's own demo_3groups (SPL_dB by voice_type,
# H(2) = 16.6245, p = 0.000245), copied into fixtures/ so this drive does not
# depend on a sandbox that died with the audit session.
#
# THE PRESETS ARE COPIED FROM eml-compare-kw.praat, its "Draw" branch, line
# for line. That wrapper is what a user reaches this crash through.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ---------------------------------------------------------------------------
# THE SHIPPED BARREL'S SET, IN THE BARREL'S ORDER. eml-lib.praat cannot be
# included from here -- a relative path inside an included file resolves
# against the TOP-LEVEL script's folder -- so the list is kept in step with
# eml-lib-stats.praat and eml-lib-graphs.praat by hand, exactly as
# harness/gui_adv/driver.praat does.
include ../stress_cases/_prelude.praat
include ../../plugin/stats/eml-result-writer.praat
include ../../plugin/stats/eml-record.praat
include ../../plugin/stats/eml-analysis.praat
include ../../plugin/graphs/eml-graphs-form.praat

outDir$ = environment$ ("EML_SEAMS_OUT")
if outDir$ = ""
    outDir$ = "."
endif

table = Read Table from comma-separated file: "fixtures/demo_3groups.csv"
tableId = selected ("Table")
appendInfoLine: "SEAMS begin tableId=", tableId

# THE ANALYSIS RUNS FIRST, because that is what the wrapper does: the CSV
# buffer it fills is what the Save panel later offers, and the report section
# it prints is the baseline the bridge's own section is counted against.
selectObject: tableId
@emlRunKWAnalysis: tableId, "SPL_dB", "voice_type", 1, "holm"
appendInfoLine: "SEAMS analysis error=[", emlRunKWAnalysis.error$, "]"
appendInfoLine: "SEAMS omnibus p=", emlKruskalWallis.p
appendInfoLine: "SEAMS csvRows=", emlCSV_n

# Exactly what eml-compare-kw.praat sets before it hands over.
emlGraphsPresetType = 7
emlGraphsPresetDataCol$ = "SPL_dB"
emlGraphsPresetGroupCol$ = "voice_type"
emlGraphsPresetTestType$ = "nonparametric"
emlGraphsPresetAnnotate = 1
emlGraphsPresetCorrection$ = "holm"

@emlGraphsWorkflow: tableId

appendInfoLine: "SEAMS end"
