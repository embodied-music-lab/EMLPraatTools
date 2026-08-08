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

include eml-lib-stats.praat
include ../stats/eml-linalg.praat
include ../stats/eml-optimizer.praat
include ../stats/eml-lmm.praat
include ../stats/eml-analysis.praat
include eml-lib-graphs.praat
