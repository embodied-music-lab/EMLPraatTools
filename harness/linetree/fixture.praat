# ============================================================================
# harness/linetree/fixture.praat — the library, the tables, and nothing else
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# THE INCLUDE LIST IS THE FORM'S, exactly as harness/linestyle/fixture.praat
# does it and for the same reason: the question tree lives in
# eml-graphs-form.praat, it reads @emlLineTreeColumns and @emlLineTreeRepeats
# out of eml-graph-procedures.praat, and the figure it presses Draw on is
# drawn by eml-draw-procedures.praat. A probe that loaded only one of those
# would be exercising a stack no user has.
#
# PATHS ARE RELATIVE, so a copy of this repository drives its own plugin. The
# copy this file sits in is the one under test; there is no absolute path
# anywhere in this directory.
#
# EVERY DATA FIXTURE IS BUILT ON EVERY LEG. Praat's `include` is a parse-time
# splice, not a runtime call, so a leg cannot include the one table it wants.
# All eight are created and drive.praat selects one. The cost is seven unused
# Tables in the Objects window; the alternative is eight near-identical drive
# scripts, which is eight places for a fixture to drift.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
#            https://github.com/embodied-music-lab/PraatGen
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ============================================================================
include ../../plugin_EML_StatsGraphs/stats/eml-core-utilities.praat
include ../../plugin_EML_StatsGraphs/stats/eml-core-descriptive.praat
include ../../plugin_EML_StatsGraphs/stats/eml-extract.praat
include ../../plugin_EML_StatsGraphs/stats/eml-output.praat
include ../../plugin_EML_StatsGraphs/stats/eml-inferential.praat
include ../../plugin_EML_StatsGraphs/stats/eml-result-writer.praat
include ../../plugin_EML_StatsGraphs/stats/eml-record.praat
include ../../plugin_EML_StatsGraphs/graphs/eml-graph-procedures.praat
include ../../plugin_EML_StatsGraphs/graphs/eml-annotation-procedures.praat
include ../../plugin_EML_StatsGraphs/graphs/eml-draw-procedures.praat
include ../../plugin_EML_StatsGraphs/graphs/eml-graphs-form.praat

@emlInitDrawingDefaults

ltLeg$ = environment$ ("EML_LT_LEG")
ltOut$ = environment$ ("EML_LT_OUT")
ltPng$ = environment$ ("EML_LT_PNG")
ltInfo$ = environment$ ("EML_LT_INFO")
# WHERE THE RECORDER'S SCRIPT GOES, and the folder its crash mirror goes in.
# Empty on the six legs that drive with no recording running.
ltRec$ = environment$ ("EML_LT_REC")
ltRecDir$ = environment$ ("EML_LT_RECDIR")

# ---------------------------------------------------------------------------
# @ltEmit -- one (case, key, value) row. The leg name is supplied here rather
# than by every call site, so a row cannot be filed under the wrong leg.
# ---------------------------------------------------------------------------
procedure ltEmit: .key$, .value$
    if ltOut$ <> ""
        appendFileLine: ltOut$, ltLeg$, tab$, .key$, tab$, .value$
    endif
endproc

include data_subjects4.praat
include data_grouprep.praat
include data_meas2.praat
include data_meas2rep.praat
include data_meas3.praat
include data_seven.praat
include data_longmeas2.praat
include data_longmeas3.praat
