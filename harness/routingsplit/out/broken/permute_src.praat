# ============================================================================
# harness/routingsplit/permute.praat — the settings-permutation drive that
#                                       risk R1 asks for
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# WHAT R1 ASKS FOR. RISK_REGISTER_2026-08-25.md, R1: "the whole-house pass
# runs ONLY after every text-changing lane has landed, and includes a
# settings-permutation drive — same data, every display setting toggled
# between draws — asserting zero reprints."
#
# WHAT CAN BE ASSERTED TODAY, AND WHAT CANNOT. The reprint itself cannot: no
# result store exists in the plugin (docs/OPEN_ITEMS.md says so in as many
# words; `reprint` and "Data changed since this analysis was last run" appear
# nowhere in plugin_EML_StatsGraphs). There is no stored report text and no
# canonical rendering to compare against, so "zero reprints" has nothing to
# count. Counting nothing and calling it zero would be the worst possible
# outcome of this inspection.
#
# SO THIS RIG MEASURES THE PROPERTY THE REPRINT DECISION WILL REST ON, which
# is available now and is the half that this round's lanes put at risk:
#
#     Does the canonical rendering of a report depend on a DISPLAY setting?
#
# Punch item 1.2's canonical form is the report "rendered with explanation-
# routed lines suppressed" — which, in this plugin, is exactly the report
# rendered with emlShowExplanations = 0. Item 1.4's identity settings (alpha,
# correction method, group sort order) are compared as identity and not as
# text, so a canonical difference across THOSE is a legitimate re-run rather
# than a false reprint; a canonical difference across the display toggle
# alone would be the false reprint R1 names.
#
# THE PERMUTATION, one leg per cell, chosen by $EML_RS_PERM:
#
#     expl   in {0, 1}   the display setting  — must NOT move canonical text
#     sort   in {0, 1}   table order / alphabetical (identity, item 1.4)
#     alpha  in {0.05, 0.01}                   (identity, item 1.4)
#
# Eight cells, on ONE fixture through ONE orchestrator with one post-hoc, so
# every difference between two cells is attributable to the settings and to
# nothing else. fixture_flat.csv is used because its omnibus does not reach
# either alpha, which puts @emlPostHocCaution's alpha-in-force line on the
# page — the one line in the round whose text is a function of BOTH a display
# setting and an identity setting at once, and therefore the sharpest cell in
# the permutation.
#
# THE LEG NAME IS expl<0|1>_sort<0|1>_alpha<05|01>.
#
# Usage (permute.sh does this):
#   EML_RS_PERM=expl0_sort0_alpha05 praat --run permute.praat
# ============================================================================

include /tmp/tmp.VgCsCpy7la/plugin_EML_StatsGraphs/stats/eml-core-utilities.praat
include /tmp/tmp.VgCsCpy7la/plugin_EML_StatsGraphs/stats/eml-core-descriptive.praat
include /tmp/tmp.VgCsCpy7la/plugin_EML_StatsGraphs/stats/eml-extract.praat
include /tmp/tmp.VgCsCpy7la/plugin_EML_StatsGraphs/stats/eml-output.praat
include /tmp/tmp.VgCsCpy7la/plugin_EML_StatsGraphs/stats/eml-inferential.praat
include /tmp/tmp.VgCsCpy7la/plugin_EML_StatsGraphs/stats/eml-result-writer.praat
include /tmp/tmp.VgCsCpy7la/plugin_EML_StatsGraphs/stats/eml-analysis.praat
include /tmp/tmp.VgCsCpy7la/plugin_EML_StatsGraphs/graphs/eml-graph-procedures.praat
include /tmp/tmp.VgCsCpy7la/plugin_EML_StatsGraphs/graphs/eml-annotation-procedures.praat

Text writing preferences: "UTF-8"

cell$ = environment$ ("EML_RS_PERM")
if cell$ = ""
    exitScript: "routingsplit/permute: EML_RS_PERM is not set."
endif

appendInfoLine: "== LEG ", cell$, " =="

; --- the display setting, through the real menu door -----------------------
clear_Info_window = 0
if index (cell$, "expl1") > 0
    annotate_results_with_explanations = 1
elsif index (cell$, "expl0") > 0
    annotate_results_with_explanations = 0
else
    exitScript: "routingsplit/permute: cell '", cell$, "' names no expl state."
endif

; --- the two identity settings --------------------------------------------
if index (cell$, "sort1") > 0
    emlGroupSortAlphabetical = 1
elsif index (cell$, "sort0") > 0
    emlGroupSortAlphabetical = 0
else
    exitScript: "routingsplit/permute: cell '", cell$, "' names no sort state."
endif

if index (cell$, "alpha01") > 0
    emlAlpha = 0.01
elsif index (cell$, "alpha05") > 0
    emlAlpha = 0.05
else
    exitScript: "routingsplit/permute: cell '", cell$, "' names no alpha."
endif

@emlHandleCommonFields

tableId = Read Table from comma-separated file: "fixture_flat.csv"
@emlRunAnovaAnalysis: tableId, "Loud", "Voice", 1

appendInfoLine: "== END ", cell$, " =="
