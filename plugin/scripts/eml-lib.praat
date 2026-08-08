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
include ../stats/eml-analysis.praat
include eml-lib-graphs.praat
