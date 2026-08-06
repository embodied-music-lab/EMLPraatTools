# ============================================================================
# eml-lib-lmm.praat — everything, including the mixed-model layer.
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
#     include eml-lib-lmm.praat
#
# Only the Stats Wizard and the LMM script need this. The mixed-model module
# is tabled for end users by author ruling of 4 August 2026; the code is here
# and loadable, it is simply not reachable from the menu.
#
# Paths are relative to the CALLING script's directory — see the note in
# eml-lib-stats.praat.
# ============================================================================

include eml-lib-stats.praat
include ../stats/eml-linalg.praat
include ../stats/eml-optimizer.praat
include ../stats/eml-lmm.praat
include ../stats/eml-analysis.praat
include eml-lib-graphs.praat
