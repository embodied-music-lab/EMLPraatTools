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
; The draw layer records itself (@emlDrawViolinPlot calls
; @emlRecordViolin), so it depends on the record layer. Inert unless a
; recording is running, but the procedures must EXIST.
include ../stats/eml-record.praat
include ../graphs/eml-draw-procedures.praat
include ../graphs/eml-graphs-form.praat
