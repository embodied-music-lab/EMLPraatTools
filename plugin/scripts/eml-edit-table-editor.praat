# ============================================================================
# EML Table Editor — Editor Menu Wrapper
# ============================================================================
# Purpose: Thin wrapper for the TableEditor Edit menu entry. Passes the
#          "editor" argument to suppress the form dialog in the main
#          script. The TableEditor is already open in this path.
#
# Date: 11 April 2026
# Version: 2.0
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: [Your name here] — created and verified by this individual
# ============================================================================

nocheck endeditor
runScript: "eml-edit-table.praat", "editor"
