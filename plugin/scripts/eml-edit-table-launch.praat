# ============================================================================
# EML Table Editor — Launcher (Objects window)
# ============================================================================
# Purpose: Opens the Table editor window, then launches the main editor
#          script. This wrapper exists because View & Edit opens a
#          duplicate window if the editor is already open. The TableEditor
#          menu entry points to eml-edit-table.praat directly (editor
#          already open).
#
# Date: 11 April 2026
# Version: 2.0
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

nTables = numberOfSelected ("Table")
if nTables <> 1
    exitScript: "Select exactly one Table object."
endif
View & Edit
runScript: "eml-edit-table.praat", "button"
