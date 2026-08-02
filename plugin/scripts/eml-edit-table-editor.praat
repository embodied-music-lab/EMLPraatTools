# ============================================================================
# EML Table Editor — Editor Menu Wrapper
# ============================================================================
# Purpose: Thin wrapper for the TableEditor Edit menu entry. Passes the
#          "editor" argument to suppress the form dialog in the main
#          script. The TableEditor is already open in this path.
#
# Date: 11 April 2026
# Version: 2.1
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: [Your name here] — created and verified by this individual
# ============================================================================

# INTENTIONAL DEFENSIVE nocheck (policy): exit any editor scripting context
# cleanly whether or not one is active / still open. Correct use of nocheck for
# editor teardown — do not replace with an existence check.
# nocheck guards exactly ONE command — the one it prefixes. It does not open a
# conditional block. This line is safe because it IS a single command.
nocheck endeditor
runScript: "eml-edit-table.praat", "editor"
