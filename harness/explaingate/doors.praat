# ============================================================================
# harness/explaingate/doors.praat — the explanations toggle, at the analysis
#                                    layer, headless
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# WHAT THIS DRIVES. Punch list 6.1: a menu analysis dialog's own toggle
# ("Annotate results with explanations", language batch item 9, default off)
# reaches the SAME emlShowExplanations gate the wizard sets unconditionally.
# This file drives the menu HALF of the acceptance fixture — the wizard half
# is GUI-driven, under Xvfb, by harness/wizardback (`praat --run` refuses to
# build a pause window at all, so the wizard cannot be driven here) — and it
# drives it at the layer @emlHandleCommonFields actually is: the shared
# procedure EVERY menu wrapper calls once per Run, right after its own
# beginPause/endPause block closes and before the orchestrator call that is
# about to read emlShowExplanations. Presetting clear_Info_window and
# annotate_results_with_explanations here is exactly what Praat's own form
# derivation leaves behind after a real endPause; the dialog GUI itself is
# out of scope for a headless run in the same way it is for every other
# doors.praat in this tree (posthocgate's is the precedent) — v98 already
# proves the field binds and renders under its derived name, on the real
# dialog, under the real character law.
#
# ONE FIXTURE, THE SAME ONE harness/wizardback's "kgroups" leg drives through
# the real wizard: fixture_k.csv, column Loud by Voice, Kruskal-Wallis with
# NO Dunn (doDunn = 0) — the exact call
# @emlRunKruskalWallisAnalysis: id, "Loud", "Voice", 0, "holm"
# the wizard's own dispatch makes for that row, so the STATISTICS half of the
# acceptance ("identical statistics") is not merely similar, it is the same
# engine call on the same table with the same doDunn/adjustment arguments.
#
# THE EXPLANATION HALF THAT ALREADY EXISTS TO READ. With doDunn = 0 the
# report reaches @emlEffectMatrixCaption (lane 3.4 / language batch item 12),
# whose first line ("No pairwise significance tests were run.") is a
# DISCLOSURE and prints on every leg, and whose second line ("Effect sizes
# estimate the size of each pairwise difference.") is an EXPLANATION and
# prints only where emlShowExplanations is on. That is the one line this
# file's validator (v130) diffs the three legs on.
#
# ONE LEG PER PROCESS, chosen by $EML_EG_LEG, report to stdout — same shape
# as posthocgate/doors.praat, for the same reason (one captured report per
# process, nothing else in it).
#
# Usage (run.sh does this):
#   cd harness/explaingate
#   EML_EG_LEG=menu_off praat --run doors.praat > out/menu_off.txt
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
    exitScript: "explaingate: EML_EG_LEG is not set."
endif

; Table order, so the group order (and every number) matches the GUI-driven
; wizard leg, which never touched the group-order control either.
emlGroupSortAlphabetical = 0

appendInfoLine: "== LEG ", leg$, " =="

tableId = Read Table from comma-separated file: "fixture_k.csv"

if leg$ = "wizard_equivalent"
    ; THE WIZARD'S OWN LINE, VERBATIM (eml-wizard.praat's top: "Wizard mode:
    ; enable third-column explanations"). No dialog, no @emlHandleCommonFields
    ; — the wizard has no control, and this leg proves the SAME orchestrator
    ; call under that SAME single assignment reproduces the GUI-driven
    ; wizard leg's numbers. The wizard leg itself is
    ; harness/wizardback's "kgroups" (GUI, under Xvfb); this is not a
    ; replacement for that evidence, it is the other half of the diff.
    emlShowExplanations = 1
    @emlRunKruskalWallisAnalysis: tableId, "Loud", "Voice", 0, "holm"

elsif leg$ = "menu_off"
    clear_Info_window = 0
    annotate_results_with_explanations = 0
    @emlHandleCommonFields
    @emlRunKruskalWallisAnalysis: tableId, "Loud", "Voice", 0, "holm"

elsif leg$ = "menu_on"
    clear_Info_window = 0
    annotate_results_with_explanations = 1
    @emlHandleCommonFields
    @emlRunKruskalWallisAnalysis: tableId, "Loud", "Voice", 0, "holm"

else
    exitScript: "explaingate: unknown leg '", leg$, "'"
endif

appendInfoLine: "== END ", leg$, " =="
