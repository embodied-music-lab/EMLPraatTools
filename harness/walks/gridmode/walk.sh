#!/bin/bash
# ============================================================================
# C1 gridline-mode walk — drive the dead-end dialog, then drive its absence
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
#   I=<instance> PLUGIN_SRC=<tree> harness/walks/gridmode/walk.sh <off|horiz> <tag>
#
# Requires a screen of at least 1400x1600 — see `ggeom` in lib.sh. It refuses
# below that rather than running; the advanced Scatter page does not fit on the
# rig's default 1280x900 and what a short screen produces is not a failure, it
# is a pass that reports on a page the walk never reached.
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
#      The menu is shot both closed and with its list dropped, and its rendered
#      value is ALSO written to the log as text (`histogram Gridline mode
#      renders:`) — see the note on evidence below.
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
#
# ---------------------------------------------------------------------------
# 16 AUGUST 2026 — HOW THIS WALK ADDRESSES CONTROLS, AND WHY IT CHANGED
#
# It used to click "widget ordinal 13" on both pages, with a comment naming the
# twelve widgets it had counted past. D11 (14 Aug) made the two group fields
# conditional on the "Use group column" box, which took two widgets off the top
# of the Scatter page, and "Legend placement" was later added below Gridline
# mode, which did not put them back. On 16 August, at the documented geometry,
# `walk.sh off` therefore set **Output DPI** — ordinal 13 today — to "item 4",
# which on a two-option menu lands on its last entry. It wrote `outputDPI: 2`,
# left `gridlineMode:` at the plugin default of 1, printed `accepted: Draw
# proceeded, no error dialog` and exited 0.
#
# The controls are now addressed BY THE LABEL THE RUNNING FORM DRAWS, found by
# OCR of the page at run time, and every set is followed by reading the page
# back: the named control must render what was intended and no other control
# may have moved. `gset` in lib.sh is that; the block above it is the longer
# argument. This is `harness/MENU_MAP.md`'s lesson in a second address space —
# a positional address silently outlives the layout it was measured against.
#
# `GRID_SCATTER_FORCE` exists to break-test that assertion: set it to a wrong
# ordinal and the walk clicks there while still checking the row the label is
# really on, so the failure is the one a stale constant would cause. It is
# empty by default and is not a way to configure the walk.
# ---------------------------------------------------------------------------
set -u
MODE=${1:?off|horiz}
TAG=${2:?tag}
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO=${REPO:-$(cd "$HERE/../../.." && pwd)}
OUT=${OUT:-$REPO/evidence/walks/gridmode}
export REPO OUT
mkdir -p "$OUT"
. "$HERE/../d117/lib.sh"
. "$HERE/lib.sh"

CFG="$PREFS/eml-graphs-config.txt"
LOG="$OUT/${TAG}.log"

case "$MODE" in
    # SCAT_TEXT is what the four-option menu must READ once it is set. It is
    # the assertion, so it is spelled the way the form spells it.
    off)   SCAT_ITEM=4; SCAT_TEXT='^Off' ;;
    horiz) SCAT_ITEM=2; SCAT_TEXT='^Horizontal only' ;;
    *) echo "walk.sh: mode must be off or horiz" >&2; exit 2 ;;
esac

# Menu item numbers in the graph-type list a Table produces. Read off
# @emlBuildFilteredMenu, not guessed: 1 "--- Categorical ---" (divider),
# 2 Violin, 3 Grouped Violin, 4 Box, 5 Grouped Box, 6 Histogram,
# 7 "--- Continuous ---" (divider), 8 Bar, 9 Scatter, 10 Line, 11 Spaghetti.
# These are checked the same way everything else here now is: the Graph type
# menu must READ "Scatter Plot" / "Histogram" afterwards, so a divider added
# to that list fails the walk instead of silently graphing something else.
SCATTER_MENU=9
HISTOGRAM_MENU=6

# Break-test hook. Empty = address the Gridline mode menu by its label, which
# is the only supported way to run this walk. See the header.
GRID_SCATTER_FORCE=${GRID_SCATTER_FORCE:-}

: > "$LOG"
# Everything, including the libraries' diagnostics on stderr, goes to the log.
# The old `say () { ... | tee }` put only the walk's own narration there, so a
# `gbtn` refusal or a `popt` "no optionmenu" was on the terminal and absent
# from the committed evidence — which is where anyone reads it later.
exec > >(tee -a "$LOG") 2>&1
trap 'sleep 1' EXIT
say () { echo "[$TAG] $*"; }
die () { say "WALK FAILED: $*"; exit 1; }
cfgline () { tr '\n' ' ' < "$CFG" 2>/dev/null | sed 's/  */ /g'; }
cfgval () { sed -n "s/^$1: *//p" "$CFG" 2>/dev/null | head -1; }
onpage () { case "$(ptitle)" in *"$1"*) return 0 ;; *) return 1 ;; esac; }

ggeom || exit 2

# ── 1. Scatter Plot, four-option menu ───────────────────────────────────────
# A config carrying only showAdvanced. No gridlineMode line, so the plugin's
# own default (1 = Both) applies and whatever ends up in the file can only
# have come from the dialog below.
printf 'showAdvanced: 1\n' > "$CFG"
say "config before:      $(cfgline)"
glaunch "$HERE/tbl_grid.praat" || die "Praat never reached its first page"
say "page: $(ptitle)"
gset "Graph type" "$SCATTER_MENU" "Scatter Plot" "Graph type" \
    || die "could not set the graph type to Scatter Plot"
gbtn 2 2 4 || die "could not press Continue on [$(ptitle)]"
say "page: $(ptitle)"
onpage "Scatter Plot" || die "expected the Scatter Plot page, got [$(ptitle)]"

gset "Gridline mode" "$SCAT_ITEM" "$SCAT_TEXT" \
     "Gridline mode (Scatter Plot, four-option menu)" "$GRID_SCATTER_FORCE" \
    || die "the Scatter page does not render Gridline mode as the walk set it"
say "scatter Gridline mode set at widget ordinal $GSET_ORDINAL, renders as intended"

shot "${TAG}_1_scatter_set" >/dev/null
gdrop "$GSET_ORDINAL" "${TAG}_2_scatter_dropped" >/dev/null \
    || die "could not drop the Scatter Gridline mode list"
gbtn 4 4 8 || die "could not press Draw on [$(ptitle)]"  # Go Back/Quit/Beginner/Draw
say "page: $(ptitle)"
onpage "Graph Complete" || die "Draw on the Scatter page did not reach Graph Complete — got [$(ptitle)]"
gfirst 5 || die "could not press Done"      # Done — ends the workflow, saves config
gwaitcfg "$CFG" "^gridlineMode:" || die "the workflow never wrote gridlineMode: to $CFG"
cp "$CFG" "$OUT/${TAG}_config_after_scatter.txt" 2>/dev/null
say "config after scatter: $(cfgline)"

# The committed half of the same assertion. The rendered check above proves the
# dialog showed the right thing; this proves the workflow persisted it. They
# fail apart: on 16 August the rendered value was never set at all and this key
# held the plugin default, which is what four months of evidence recorded.
scat_written=$(cfgval gridlineMode)
[ "$scat_written" = "$SCAT_ITEM" ] || die \
    "gridlineMode: the Scatter page committed $scat_written, the walk set option $SCAT_ITEM ($MODE)"

# ── 2. Histogram, two-option menu, after a full restart ─────────────────────
glaunch "$HERE/tbl_grid.praat" || die "Praat never reached its first page (2nd launch)"
say "page: $(ptitle)"
gset "Graph type" "$HISTOGRAM_MENU" "Histogram" "Graph type" \
    || die "could not set the graph type to Histogram"
gbtn 2 2 4 || die "could not press Continue on [$(ptitle)]"
say "page: $(ptitle)"
onpage "Histogram" || die "expected the Histogram page, got [$(ptitle)]"
shot "${TAG}_3_histogram_dialog" >/dev/null

# The histogram's Gridline mode is NOT set by the walk — it is seeded off the
# config the scatter wrote, and what it seeds to is the whole subject. So it is
# read rather than asserted: what it should read differs by tree, and a walk
# that knew which tree it was driving would not be a differential.
#
# Reading it as TEXT is new on 16 August. Until then this fact lived only in
# `*_4_histogram_dropped.png`, and the README had to spend a paragraph warning
# that a dropped shot of an unset menu looks like a selection. The closed
# control is unambiguous: blank is blank. validate/v31_gridmode.R asserts these
# four lines, so the table in README.md is now checked and not just illustrated.
hsnap=$(gsnap) || die "could not read the Histogram page"
GRID_HIST=$(gfind "$hsnap" "Gridline mode") || die "no Gridline mode menu on the Histogram page"
hgrid=$(printf '%s\n' "$hsnap" | awk -F'\t' -v k="$GRID_HIST" '$1 == k {print $3}')
say "histogram Gridline mode renders: \"$hgrid\" (widget ordinal $GRID_HIST)"

gdrop "$GRID_HIST" "${TAG}_4_histogram_dropped" >/dev/null \
    || die "could not drop the Histogram Gridline mode list"
gbtn 4 4 8 || die "could not press Draw on [$(ptitle)]"      # Draw
say "after Draw: $(ptitle)"
shot "${TAG}_5_after_draw" >/dev/null
if gerr "${TAG}_6_refusal" >/dev/null; then
    say "REFUSED: Praat put up an error dialog instead of drawing"
    say "config now:           $(cfgline)"
else
    say "accepted: Draw proceeded, no error dialog"
    onpage "Graph Complete" || die \
        "no error dialog, but the page is [$(ptitle)] and not Graph Complete"
    # Finish the workflow so the histogram COMMITS its gridline choice. This
    # is the other half of the round trip: what a two-option dialog writes
    # back into the one canonical key decides what the next four-option
    # dialog will show, and an index-preserving commit inverts it there.
    gfirst 5 || die "could not press Done on the Graph Complete page"
    sleep 3
    cp "$CFG" "$OUT/${TAG}_config_after_histogram.txt" 2>/dev/null
    say "config after histogram: $(cfgline)"
fi
say "walk complete"
