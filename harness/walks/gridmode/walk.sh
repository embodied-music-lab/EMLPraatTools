#!/bin/bash
# ============================================================================
# C1 gridline-mode walk — drive the dead-end dialog, then drive its absence
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
#   I=<instance> PLUGIN_SRC=<tree> harness/walks/gridmode/walk.sh <off|horiz> <tag>
#
# Two dialogs, in the order a user meets them:
#
#   1. Scatter Plot (graph type 8) — a FOUR-option Gridline mode menu:
#      Both / Horizontal only / Vertical only / Off. Set it to `off` (index 4)
#      or `horiz` (index 2), press Draw, then Done. Done is what runs
#      @emlSaveConfig, so `gridlineMode:` lands in
#      <prefs>/eml-graphs-config.txt — on disk, surviving the restart below.
#
#   2. Histogram (graph type 10) — a TWO-option Gridline mode menu:
#      Horizontal / Off. Praat is fully relaunched between the two, so the
#      value is demonstrably read back off the file and not carried in memory.
#      The menu is shot both closed and with its list dropped: closed shows
#      the blank control, dropped shows which item is selected when one is.
#      See the note on `gdrop` in lib.sh — a dropped shot of an UNSET menu
#      highlights the hovered first entry and must not be read as a selection.
#
# On a pre-C1 tree the histogram menu is seeded with the scatter's index.
# `off` gives it 4, out of range for a 2-option menu: Praat draws the control
# blank and then refuses the form — "No option chosen for 'Gridline mode'." —
# with no Draw path off the page. `horiz` gives it 2, in range but meaning
# "Off" in the categorical encoding, so the setting silently inverts. Those
# are C1's two halves.
#
# Shots and config copies land in $OUT (default evidence/walks/gridmode).
# The config file is copied out at each step: the file is the defect's carrier.
# ============================================================================
set -u
MODE=${1:?off|horiz}
TAG=${2:?tag}
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO=${REPO:-$(cd "$HERE/../../.." && pwd)}
OUT=${OUT:-$REPO/evidence/walks/gridmode}
export REPO OUT
. "$HERE/../d117/lib.sh"
. "$HERE/lib.sh"

CFG="$PREFS/eml-graphs-config.txt"
LOG="$OUT/${TAG}.log"

case "$MODE" in
    off)   SCAT_ITEM=4 ;;   # 4-option menu, item 4 = Off
    horiz) SCAT_ITEM=2 ;;   # 4-option menu, item 2 = Horizontal only
    *) echo "walk.sh: mode must be off or horiz" >&2; exit 2 ;;
esac

# Menu item numbers in the graph-type list a Table produces. Read off
# @emlBuildFilteredMenu, not guessed: 1 "--- Categorical ---" (divider),
# 2 Violin, 3 Grouped Violin, 4 Box, 5 Grouped Box, 6 Histogram,
# 7 "--- Continuous ---" (divider), 8 Bar, 9 Scatter, 10 Line, 11 Spaghetti.
SCATTER_MENU=9
HISTOGRAM_MENU=6

# Which optionmenu down the page carries "Gridline mode". @pmenus counts every
# field widget, text entries included, so these are widget ordinals and not
# menu ordinals. Scatter: X col, Y col, Group col, Group order, Correlation,
# Regression, Significance style, Dot size, X max, X min, Y max, Y min,
# GRIDLINE = 13. Histogram: Value col, Group col, Group order, Bin count,
# Display mode, Test type, Adjustment method, Significance style, Alpha,
# Value max, Value min, Freq max, GRIDLINE = 13. Checkboxes ("Use group
# column", "Annotate results on graph") draw no left border and are not
# counted; the two dialogs landing on the same ordinal is a coincidence.
GRID_SCATTER=${GRID_SCATTER:-13}
GRID_HIST=${GRID_HIST:-13}

: > "$LOG"
say () { echo "[$TAG] $*" | tee -a "$LOG"; }
cfgline () { tr '\n' ' ' < "$CFG" 2>/dev/null | sed 's/  */ /g'; }

# ── 1. Scatter Plot, four-option menu ───────────────────────────────────────
# A config carrying only showAdvanced. No gridlineMode line, so the plugin's
# own default (1 = Both) applies and whatever ends up in the file can only
# have come from the dialog below.
printf 'showAdvanced: 1\n' > "$CFG"
say "config before:      $(cfgline)"
glaunch "$HERE/tbl_grid.praat" || exit 1
say "page: $(ptitle)"
popt 1 "$SCATTER_MENU"
gbtn 2 2 4                                  # Quit / Continue
say "page: $(ptitle)"
popt "$GRID_SCATTER" "$SCAT_ITEM"
shot "${TAG}_1_scatter_set" >/dev/null
gdrop "$GRID_SCATTER" "${TAG}_2_scatter_dropped" >/dev/null
gbtn 4 4 8                                  # Go Back / Quit / Beginner / Draw
say "page: $(ptitle)"
gfirst 5                                    # Done — ends the workflow, saves config
gwaitcfg "$CFG" "^gridlineMode:" || exit 1
cp "$CFG" "$OUT/${TAG}_config_after_scatter.txt" 2>/dev/null
say "config after scatter: $(cfgline)"

# ── 2. Histogram, two-option menu, after a full restart ─────────────────────
glaunch "$HERE/tbl_grid.praat" || exit 1
say "page: $(ptitle)"
popt 1 "$HISTOGRAM_MENU"
gbtn 2 2 4
say "page: $(ptitle)"
shot "${TAG}_3_histogram_dialog" >/dev/null
gdrop "$GRID_HIST" "${TAG}_4_histogram_dropped" >/dev/null
gbtn 4 4 8                                  # Draw
say "after Draw: $(ptitle)"
shot "${TAG}_5_after_draw" >/dev/null
if gerr "${TAG}_6_refusal" >/dev/null; then
    say "REFUSED: Praat put up an error dialog instead of drawing"
    say "config now:           $(cfgline)"
else
    say "accepted: Draw proceeded, no error dialog"
    # Finish the workflow so the histogram COMMITS its gridline choice. This
    # is the other half of the round trip: what a two-option dialog writes
    # back into the one canonical key decides what the next four-option
    # dialog will show, and an index-preserving commit inverts it there.
    gfirst 5
    sleep 3
    cp "$CFG" "$OUT/${TAG}_config_after_histogram.txt" 2>/dev/null
    say "config after histogram: $(cfgline)"
fi
