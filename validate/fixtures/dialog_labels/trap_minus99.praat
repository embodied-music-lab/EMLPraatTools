# ============================================================================
# trap_minus99.praat — one hyphen in a label, and the code silently reads a
# subtraction instead of the user's number
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# THIS SCRIPT IS A SEEDED VIOLATION. Nothing includes it and it is not part of
# the plugin. validate/v98_field_names.R must flag it; harness/labellaw/run.sh
# runs it under Praat so the pathology is measured rather than asserted.
#
# WHAT IT DEMONSTRATES, and this is the reason the character law exists.
#
# Praat does NOT truncate a field label at the first odd character. It cuts
# the label at the first "(", turns spaces into underscores, and KEEPS
# EVERYTHING ELSE VERBATIM. So the label "left Y-limits" really does bind a
# variable, and the variable's name really is `left_Y-limits`, hyphen and all
# — a name no script can ever write down, because the moment it is written the
# parser reads it as `left_Y` minus `limits`.
#
# That is the whole trap. A name that cannot be referenced would be harmless
# if referencing it raised "Unknown variable": the wrapper would stop, the
# user would see something, somebody would fix it. What actually happens is
# that the two halves of the unreachable name are ORDINARY IDENTIFIERS, and a
# dialog page has plenty of both in scope. Here `limits` is 100 and `left_Y`
# is 1 — bystanders, the kind any page carries — so the user types 5, and the
# code that means to read their 5 gets 1 - 100 = -99. No error. No warning.
# A figure drawn to a range nobody asked for.
#
# MEASURED, Praat 6.6.30, headless (--run passes the typed value as an
# argument): variableExists("left_Y-limits") is 1 — the value IS stored — and
# `left_Y-limits` evaluates to -99.
#
# The fix, per docs/RULING_DIALOG_LABELS_v3.md: before the parenthetical a
# field label carries letters, digits and spaces only. Everything decorative,
# including anything that wants a hyphen, slash or middle dot, lives inside
# the parenthetical, which Praat has already thrown away by then.
#
#   praat --run trap_minus99.praat 5
# ============================================================================

form: "Seeded violation: a hyphen in a field label"
	real: "left Y-limits", "5"
endform

# THE BYSTANDERS. Neither is contrived: `limits` and `left_Y` are the sort of
# names a drawing page defines a dozen of. They are what turns an unreachable
# variable into a wrong number instead of an error.
limits = 100
left_Y = 1

# The value the user typed is in scope under a name that cannot be written.
appendInfo: ""
writeInfoLine: "bound=", variableExists ("left_Y-limits")
# This line MEANS "the number from the Y-limits box". It IS "left_Y minus
# limits". Praat cannot tell the difference, and neither can a reader.
appendInfoLine: "read=", left_Y-limits
appendInfoLine: "TRAP DONE"
