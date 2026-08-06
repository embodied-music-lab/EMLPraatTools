# ============================================================================
# eml-lib.praat — one include to rule them all.
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
#     include eml-lib.praat
#
# Statistics, orchestrators and graphing, in the order the modules expect.
# This is what a menu script wants unless it needs the mixed-model layer, in
# which case it wants eml-lib-lmm.praat.
#
# Expands to exactly the ten-line block it replaces, in the same order, so
# swapping to it cannot change behaviour. Paths are relative to the CALLING
# script's directory — see the note in eml-lib-stats.praat.
# ============================================================================

include eml-lib-stats.praat
include ../stats/eml-analysis.praat
include eml-lib-graphs.praat
