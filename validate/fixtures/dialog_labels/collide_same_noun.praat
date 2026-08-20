# ============================================================================
# collide_same_noun.praat — two ranges, one noun: the collision that renders
# clean and throws away what the user typed
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# THIS SCRIPT IS A SEEDED VIOLATION. Nothing includes it and it is not part of
# the plugin. It exists so that validate/v98_field_names.R has a file that its
# uniqueness rule MUST come out red on, and so that harness/labellaw/run.sh
# can put Praat itself on the record about what happens when the rule is
# broken. If a future edit to v98 stops flagging this file, the rule has been
# weakened, and the check that reads this file says so instead of going quiet.
#
# WHAT IT DEMONSTRATES. Praat derives a field's variable name from the label
# by cutting the label at the first "(", so the parenthetical is not part of
# the name. Two fields whose labels differ only inside the parentheses
# therefore derive ONE name. Praat does not complain: it draws both rows, with
# their full labels, and binds the LAST one. The first row's value is
# discarded with no error, no warning and nothing on screen to see.
#
# MEASURED, Praat 6.6.30, headless (--run passes the four values as
# arguments): left_Value = 333 and right_Value = 444. The 111 and 222 the
# first pair of boxes carried are gone.
#
# The fix, per docs/RULING_DIALOG_LABELS_v3.md, is never to disambiguate two
# ranges by orientation. A second range is renamed by QUANTITY — Value versus
# Frequency, X versus Y, or the noun "Second axis" — because the quantity is
# part of the derived name and the parenthetical never is.
#
#   praat --run collide_same_noun.praat 111 222 333 444
# ============================================================================

form: "Seeded violation: two ranges, one noun"
	real: "left Value (bottom/top)", "111"
	real: "right Value (bottom/top)", "222"
	real: "left Value (left/right)", "333"
	real: "right Value (left/right)", "444"
endform

# Both pairs of boxes were filled. Only one pair survives, and the code has no
# way of asking for the other: there is one left_Value in scope, not two.
writeInfoLine: "left_Value=", left_Value
appendInfoLine: "right_Value=", right_Value
appendInfoLine: "COLLIDE DONE"
