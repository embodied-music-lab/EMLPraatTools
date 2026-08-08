# ============================================================================
# EML Graphs — Main Script (Entry Point)
# ============================================================================
# EML Graphs Plugin
# License: GPL-3.0-or-later
# Version: 3.0
# Date: 4 April 2026
#
# Purpose: Entry point for the standalone EML Graphs tool. All logic lives
#          in eml-graphs-form.praat (workflow, forms, config, context) and
#          the draw-layer files (eml-graph-procedures.praat,
#          eml-draw-procedures.praat, eml-annotation-procedures.praat).
#
# This file is the standalone entry point only. Stats wrappers and the
# wizard call @emlGraphsWorkflow directly via their own includes.
#
# v3.0:  File split — form system and workflow extracted to
#         eml-graphs-form.praat. This file becomes a thin entry point.
#         See HANDOFF_CONVERGENCE_STEPS5-6_04_APR_2026.md for design.
# v2.44: Line Chart CI toggle, Pitch Contour rename, dead code cleanup.
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


include eml-lib.praat

@emlGraphsWorkflow: 0
