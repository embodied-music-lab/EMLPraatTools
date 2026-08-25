# ============================================================================
# eml-lib-graphs.praat — the graphing stack.
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# The graphing layer calls into the statistics layer, so this is not usable on
# its own: include eml-lib.praat, which pulls both in the right order. This
# file exists so the graph file list is written down exactly once.
#
# Paths are relative to the CALLING script's directory — see the note in
# eml-lib-stats.praat.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
#            https://github.com/embodied-music-lab/PraatGen
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
#
# RESEARCH USE DISCLOSURE
# If this script is used in research or publication, disclose AI use
# per your target journal's policy. Suggested language:
#
#   "Praat analysis scripts were developed using the EML PraatGen
#    Scripting Assistant (Howell, Embodied Music Lab) with code
#    generation by Claude (Anthropic). All scripts were reviewed,
#    tested, and validated by Ian Howell."
#
# The script author assumes responsibility for the correctness and
# appropriate application of this code.
# ============================================================================

include ../graphs/eml-graph-procedures.praat
include ../graphs/eml-annotation-procedures.praat
; THE RECORD LAYER IS NOT INCLUDED HERE, AND THAT IS THE FIX FOR A DEFECT
; THAT KILLED FIFTEEN MENU ENTRY POINTS.
;
; It is not, though @emlDrawViolinPlot calls
; @emlRecordViolin so the procedures must exist. That reasoning is obsolete:
; the draw layer's record hooks are guarded with variableExists ("emlRecordActive")
; and Praat only errors on an undefined procedure when it EXECUTES the call,
; so an absent recorder costs nothing.
;
; And the include was not merely redundant. eml-lib.praat loads
; eml-lib-stats.praat -- which includes eml-record.praat -- and then this
; file, so the recorder was pasted in TWICE. `include` is a textual paste,
; and eml-record.praat contains `label` statements, so the second paste
; produced:
;
;     Error: Duplicate label "END_RECORD_SOURCE" on lines 29445 and 13332.
;     Script ".../scripts/eml-graphs.praat" not completed.
;
; Every wrapper that loads the barrel died at PARSE time -- 15 of them,
; including EML Graphs, the wizard, and every analysis. Found 11 Aug 2026 by
; driving the plugin's own menu under Xvfb, which is the first time anything
; had loaded the barrel: every harness includes the individual files.
;
; eml-lib-stats.praat still says "Including the same file twice is harmless".
; That is TRUE only for a file with no labels in it. See harness/wrappers/.
include ../graphs/eml-draw-procedures.praat
include ../graphs/eml-graphs-form.praat
