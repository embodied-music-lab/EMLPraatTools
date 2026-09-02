# ============================================================================
# harness/explainwiring/doors.praat — punch list 6.2, the reporters
#                                      @emlHandleCommonFields did not reach
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# WHAT THIS DRIVES. Punch list 6.2: explanation calls join the ORCHESTRATOR
# reporters in stats/eml-analysis.praat (and, for the descriptive path,
# stats/eml-output.praat) that emlShowExplanations previously never reached:
# @emlReportPairwiseComparison (all four test arms: Welch, Student, Scheffe,
# Wilcoxon), @emlRunRepeatedMeasuresAnalysis, @emlRunFriedmanAnalysis, and
# @emlReportDescriptiveAnalysis. harness/explaingate already covers
# @emlRunKruskalWallisAnalysis via @emlEffectMatrixCaption; this rig covers the sites
# that were the actual gap.
#
# SAME IDIOM AS harness/explaingate/doors.praat: one leg per process, chosen
# by $EML_EG_LEG, so nothing but that leg's own appendInfoLine calls reach
# the captured file. wizard_equivalent reproduces the wizard's own single
# assignment (emlShowExplanations = 1, no dialog); menu_off / menu_on
# reproduce a menu wrapper's Run through the real @emlHandleCommonFields.
#
# Usage (run.sh does this):
#   cd harness/explainwiring
#   EML_EG_LEG=pairwise_welch_menu_on praat --run doors.praat > out/....txt
# ============================================================================

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

leg$ = environment$ ("EML_EG_LEG")
if leg$ = ""
    exitScript: "explainwiring: EML_EG_LEG is not set."
endif

emlGroupSortAlphabetical = 0

appendInfoLine: "== LEG ", leg$, " =="

; ----------------------------------------------------------------------------
; Explanations state, decoded from the leg name's trailing word — same three
; states harness/explaingate exercises, at these newly-wired sites instead.
; ----------------------------------------------------------------------------
if endsWith (leg$, "_wizard")
    emlShowExplanations = 1
elsif endsWith (leg$, "_menu_off")
    clear_Info_window = 0
    annotate_results_with_explanations = 0
    @emlHandleCommonFields
elsif endsWith (leg$, "_menu_on")
    clear_Info_window = 0
    annotate_results_with_explanations = 1
    @emlHandleCommonFields
else
    exitScript: "explainwiring: unrecognised leg '", leg$, "'"
endif

if startsWith (leg$, "pairwise_welch")
    tableId = Read Table from comma-separated file: "fixture_k.csv"
    @emlRunPairwiseAnalysis: tableId, "Loud", "Voice", "welch", "holm"

elsif startsWith (leg$, "pairwise_student")
    tableId = Read Table from comma-separated file: "fixture_k.csv"
    @emlRunPairwiseAnalysis: tableId, "Loud", "Voice", "student", "holm"

elsif startsWith (leg$, "pairwise_scheffe")
    tableId = Read Table from comma-separated file: "fixture_k.csv"
    @emlRunPairwiseAnalysis: tableId, "Loud", "Voice", "scheffe", "holm"

elsif startsWith (leg$, "pairwise_wilcoxon")
    tableId = Read Table from comma-separated file: "fixture_k.csv"
    @emlRunPairwiseAnalysis: tableId, "Loud", "Voice", "wilcoxon", "holm"

elsif startsWith (leg$, "rmanova")
    tableId = Read Table from comma-separated file: "fixture_rm.csv"
    @emlRunRepeatedMeasuresAnalysis: tableId, "Subject", "pre|mid|post", 0, "holm"

elsif startsWith (leg$, "friedman")
    tableId = Read Table from comma-separated file: "fixture_rm.csv"
    @emlRunFriedmanAnalysis: tableId, "Subject", "pre|mid|post", 0, "holm"

elsif startsWith (leg$, "descriptive")
    tableId = Read Table from comma-separated file: "fixture_k.csv"
    @emlRunDescriptiveAnalysis: tableId, "Loud"

else
    exitScript: "explainwiring: unrecognised leg '", leg$, "'"
endif

appendInfoLine: "== END ", leg$, " =="
