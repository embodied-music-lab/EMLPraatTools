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
# ============================================================================

include ../graphs/eml-graph-procedures.praat
include ../graphs/eml-annotation-procedures.praat
include ../graphs/eml-draw-procedures.praat
include ../graphs/eml-graphs-form.praat
