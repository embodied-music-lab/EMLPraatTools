# ---------------------------------------------------------------------------
# NORECORD -- the plugin driven with the recorder NOT LOADED.
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS EXISTS TO CATCH. The workflow recorder is OPTIONAL BY DESIGN. A
# hand-written user script, a PraatGen companion file, or anything that
# includes the stats and graphs files directly rather than through the shipped
# barrel gets the analyses and the figures without it. Every capture hook is
# therefore written to be inert when the recorder is ABSENT -- guarded on
# variableExists ("emlRecordLoaded"), not on recording state -- because Praat
# only errors on an undefined procedure when it EXECUTES the call.
#
# That contract was broken twice on 12 Aug 2026 and neither break was visible
# to any harness:
#
#   - the twelve analysis capture hooks were added UNGUARDED, so
#     eml-analysis.praat could no longer be loaded without eml-record.praat.
#     Found only when plugin/dev/tests/phase2 died with
#     Procedure "emlRecordAnalysisStep" not found;
#   - @emlRunAnovaAnalysis called @emlRecordAnova unconditionally, and that
#     procedure opens with @emlRecordInit, so the ANOVA path required the
#     recorder too. The violin hook's own comment had already named this
#     failure mode a shipped API break, in this repository, two days earlier.
#
# EVERY BARREL INCLUDES THE RECORDER, so nothing that loads a barrel can see
# either one -- which is why every existing harness missed both. This file
# does not load a barrel. It includes the individual files, exactly as a user
# script does, and drives the same 27 operations harness/record_e2e drives
# from the same fixture.praat and the same op.praat, so the two populations
# cannot drift apart.
#
# Output: one OPDONE line per operation, read by run.sh.
# ---------------------------------------------------------------------------
include ../../plugin/stats/eml-core-utilities.praat
include ../../plugin/stats/eml-core-descriptive.praat
include ../../plugin/stats/eml-extract.praat
include ../../plugin/stats/eml-output.praat
include ../../plugin/stats/eml-inferential.praat
include ../../plugin/stats/eml-result-writer.praat
include ../../plugin/graphs/eml-graph-procedures.praat
include ../../plugin/graphs/eml-annotation-procedures.praat
include ../../plugin/graphs/eml-draw-procedures.praat
include ../../plugin/stats/eml-analysis.praat

; THE RECORDER IS NOT INCLUDED ABOVE, AND THAT IS THE WHOLE POINT. A guard on
; emlRecordLoaded only means anything in a process where nothing set it, so
; this driver refuses rather than reporting a pass it did not earn.
if variableExists ("emlRecordLoaded")
    exitScript: "NORECORD: the recorder was loaded. This run proves nothing."
endif

include fixture.praat

for k from 1 to nOps
    ; `nocheck` so one casualty does not hide the other twenty-six: the
    ; verdict comes from op.praat's own OPDONE marker, and the point of this
    ; harness is the FULL list of what broke, not the first thing that did.
    nocheck runScript: "op.praat", op$[k]
    appendInfoLine: "OP name=", op$[k], " k=", k, " nOps=", nOps
endfor

appendInfoLine: "NORECORD DONE nOps=", nOps
