# ============================================================================
# C1 — the gridline-mode translation, exhaustively, as a table
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
#   praat --run harness/walks/gridmode/truth.praat > evidence/walks/gridmode/truth_table.csv
#
# Every (graph type, canonical value) pair the plugin can be in, through
# @emlGridModeToMenu and straight back through @emlGridModeFromMenu. The GUI
# walk beside this file shows the two dialogs a user actually meets; this
# shows that the other 50 combinations behave the same way, which no
# reasonable number of walks would.
#
# Columns:
#   type       internal graph type id, 1..nGraphTypes
#   style      gridModeStyle[type] — 4 or 2, the option count of its menu
#   canonical  what is on disk: 1 Both, 2 Horizontal only, 3 Vertical only,
#              4 Off
#   menu       the option index that dialog's optionmenu is seeded with
#   back       what that index commits back as, canonical again
#
# The three properties v31_gridmode.R reads off this:
#   · menu is always within 1..style          (no blank optionmenu, ever)
#   · back is always within 1..4              (nothing illegal reaches disk)
#   · on a 2-option type, canonical 2 and 4 survive the round trip unchanged
#     (Horizontal only stays horizontal, Off stays off — the half the old
#     three-site clamp got backwards)
# ============================================================================

include ../../../plugin/graphs/eml-graphs-form.praat

writeInfoLine: "type,style,canonical,menu,back"
for gtype from 1 to nGraphTypes
    for canon from 1 to 4
        @emlGridModeToMenu: gtype, canon
        .m = emlGridModeToMenu.menu
        @emlGridModeFromMenu: gtype, .m
        appendInfoLine: gtype, ",", gridModeStyle[gtype], ",", canon, ",",
            ... .m, ",", emlGridModeFromMenu.canonical
    endfor
endfor
