# ============================================================================
# branch_collision.praat — one derived name on one rendered branch, and the
# lookalike that is legal
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# THIS SCRIPT IS A SEEDED VIOLATION AND IS NEVER EXECUTED. Nothing includes
# it, and it cannot be run headlessly: a beginPause block needs a display and
# a click, which is exactly why the rule it exercises has to be checked in the
# source rather than by driving it. validate/v98_field_names.R reads this file
# and must report TWO collisions in it and must NOT report the third pair.
#
# WHY A DIALOG PAGE NEEDS A NARROWER RULE THAN "NO TWO FIELDS IN THIS BLOCK".
# A form written with conditionals is several pages sharing one block. Two
# fields in opposite branches of one `if` never appear together, so they may
# share a derived name and the tree does that on purpose. Two fields that DO
# appear together may not — whichever renders last silently wins, and the
# other box's value is discarded. So the question the check has to answer is
# not "are these in the same block" but "can these render on the same page".
#
# THE THREE PAIRS BELOW, in the order the check reports them:
#
#   1. left_Value twice inside ONE branch. They render one above the other on
#      the same page. The second wins; the first box's number is lost.
#   2. axis_label$ once at the top of the block and once inside a branch.
#      Nothing excludes them: whenever the branch renders, the top-level row
#      renders too, so this is the same loss as (1) with the two rows further
#      apart, which is the version that survives review.
#   3. left_Value in the `if` branch and left_Value in the `else` branch.
#      LEGAL, and it must stay legal: one `if`, two branches, so the two rows
#      can never be on screen together. A check that flagged this would push
#      the tree towards renaming fields that were never in conflict.
# ============================================================================

mode = 1

beginPause: "Seeded violation: two rows, one derived name, one page"
	comment: "📐 Axes (both 0 = auto)"
	sentence: "Axis label", "auto"
	if mode = 1
		real: "left Value (bottom/top)", "0"
		real: "left Value (left/right)", "0"
		sentence: "Axis label (blank = auto)", "auto"
	else
		real: "left Value (bottom/top)", "0"
	endif
clicked = endPause: "Quit", "Draw", 2, 2
