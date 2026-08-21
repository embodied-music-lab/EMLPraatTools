# ============================================================================
# inject_collision.praat — the rows a procedure puts on somebody else's page,
# and the two ways they go wrong there
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# THIS SCRIPT IS A SEEDED VIOLATION. Nothing includes it and it is not part of
# the plugin. validate/v98_field_names.R reads it and must report TWO
# collisions and ONE illegal label in it; harness/labellaw/inject.sh renders
# it under Xvfb and reads the damage back out of Praat.
#
# WHAT IT DEMONSTRATES, and why a check that reads only the text between
# beginPause and endPause cannot see it.
#
# A `form:` block is a declaration Praat reads whole. A beginPause block is
# ORDINARY CODE, executed top to bottom, so a procedure called from inside one
# emits its field rows INTO THAT DIALOG. The rows appear on the caller's page,
# in the caller's namespace, under names derived from labels written in
# another file — which is exactly what the plugin does: @emlWrapperCommonFields
# lives in stats/eml-output.praat, ten wrapper dialogs call it, and eleven
# sites read the `clear_Info_window` it binds.
#
# So the page below has FIVE rows, and only two of them are written between
# beginPause and endPause.
#
#   left Value (bottom/top)   111     written here
#   right Value (bottom/top)  222     written here
#   left Value (left/right)   333     from @seededCommonRows
#   right Value (left/right)  444     from @seededCommonRows
#   left Y-limits             5       from @seededCommonRows
#
# TWO SEPARATE FAILURES, one page:
#
#   1. THE SAME-NOUN COLLISION, arriving by call. The parenthetical is not
#      part of the derived name, so rows 1 and 3 are one `left_Value` and rows
#      2 and 4 are one `right_Value`. Praat draws all four, binds the last of
#      each, and discards 111 and 222 without a word.
#   2. THE ARITHMETIC TRAP, arriving by call. Row 5 binds `left_Y-limits`,
#      which no script can write. With the bystanders below in scope, the line
#      that means to read that box returns 1 - 100 = -99.
#
# The bystanders are the ordinary kind — a page carries a dozen of each.
#
# HOW THE FIVE ROWS ACTUALLY LOOK, measured by rendering this file under Xvfb
# (harness/labellaw/inject.sh keeps the screenshot and the OCR): a `left X` and
# a `right X` field PAIR into one displayed row of two boxes carrying the LEFT
# field's remainder only, and the pairing word is dropped from the display even
# where a field has no partner. So the page shows three lines of boxes —
# "Value (bottom/top)", "Value (left/right)", "Y-limits" — for five fields and
# five variables. The display distinguishes the two Value rows by their
# parentheticals; the namespace does not distinguish them at all.
#
# THE LAST ARGUMENT OF endPause IS THE CANCEL BUTTON, and it is 0 here on
# purpose. Naming the Draw button as the cancel button makes Praat discard the
# form: no field binds, and the script that reads one stops with "Unknown
# variable" before it can measure anything.
# ============================================================================

limits = 100
left_Y = 1

beginPause: "Seeded violation: rows a procedure puts on the page"
	comment: "📐 Axes (both 0 = auto)"
	real: "left Value (bottom/top)", "111"
	real: "right Value (bottom/top)", "222"
	@seededCommonRows
clicked = endPause: "Quit", "Draw", 2, 0

# preferencesDirectory$ follows --pref-dir, so the driver names the directory
# and the fixture stays a fixture rather than a template with a path in it.
out$ = preferencesDirectory$ + "/inject_collision.out"
writeFileLine: out$, "clicked=", clicked
appendFileLine: out$, "left_Value=", left_Value
appendFileLine: out$, "right_Value=", right_Value
# The typed value IS stored. `bound` says so; `read` says what the code that
# asks for it gets instead.
appendFileLine: out$, "bound=", variableExists ("left_Y-limits")
appendFileLine: out$, "read=", left_Y-limits
appendFileLine: out$, "INJECT DONE"

# ────────────────────────────────────────────────────────────────────────────
# The rows written somewhere else. Praat resolves the call at run time, so
# nothing about the block above says these are coming.
# ────────────────────────────────────────────────────────────────────────────
procedure seededCommonRows
	comment: ""
	real: "left Value (left/right)", "333"
	real: "right Value (left/right)", "444"
	real: "left Y-limits", "5"
endproc
