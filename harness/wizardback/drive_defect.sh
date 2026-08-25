#!/usr/bin/env bash
# ============================================================================
# harness/wizardback/drive_defect.sh — the correlation Back-and-return,
#                                       driven and read without OCR
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# ONE SPECIFIC DEFECT, DRIVEN THROUGH THE REAL INTERFACE. B_TEST_PAGE (the
# correlation "Choose test" page) is a goto target: the analysis-error
# dialog's own Back button returns straight to it (`goto B_TEST_PAGE`,
# eml-wizard.praat). This walks that exact path --
#
#     Column select -> Test = "Both Pearson and Spearman" (row 3),
#     Group column = the one real candidate (row 2) -> Run
#     -> analysis errors (fixture_corr_err.csv has ZERO complete X/Y pairs,
#        by construction, so the overall correlation cannot be computed and
#        @emlErrorDialog's "wizard" mode fires unconditionally)
#     -> Back
#     -> read the redrawn page WITHOUT TOUCHING ANYTHING
#
# -- and answers, for each of the page's two dropdowns, "which row is it
# showing now" by two independent, non-destructive reads:
#
#   TEST      re-press Run without touching anything. @wizardReportPlan
#             prints "Test: ..." into the Info window BEFORE the analysis
#             is attempted, on every attempt, error or not -- so the second
#             attempt's own "Test:" line names the row the redraw held,
#             whether or not the second attempt also errors.
#
#   GROUP COLUMN is not named anywhere in the Analysis Plan (the plan's
#             group-column slot is only wired for the two/k-group and
#             paired pages, not correlation) -- so it cannot be read the
#             same way. Instead its popup is opened, photographed, and
#             dismissed with Escape (selected_row.py) -- read, not clicked;
#             nothing about the choice changes by asking.
#
# WHAT THIS PROVES. Before the wizard fix: Test reverts to the normality
# recommendation (row 1 or 2, never 3) and Group column reverts to row 1
# ("(none — overall only)"). After the fix: both read back exactly what was
# chosen (row 3, row 2).
#
# REUSES, RATHER THAN REINVENTS: the boot sequence, wb_geom/wb_pausewin/
# wb_read/wb_press/wb_setcombo/wb_settle/wb_current are copied verbatim from
# harness/wizardback/run.sh (that file is a `while read` driver over a fixed
# LEGS table and is not written to be sourced) so this file can add the one
# thing that table has no room for: a read-only combo query and a 2-button
# (Quit/Back) error-dialog Back press, which run.sh's own 3-button "second
# from the right" convention refuses outright rather than mis-click.
#
# $EML_WB_SRC, same door run.sh opens: point this at a seeded copy to drive
# the SAME script unmodified against the pre-fix tree.
#
# Usage:  bash harness/wizardback/drive_defect.sh
# Output: harness/wizardback/out/defect_drive.tsv
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
. "$ROOT/harness/_env.sh" || { echo "drive_defect: no Praat; refusing" >&2; exit 2; }

SRC="${EML_WB_SRC:-$ROOT/plugin_EML_StatsGraphs}"
OUT="${EML_WB_OUT:-$SCRIPT_DIR/out}"
[ -d "$SRC/scripts" ] || {
    echo "drive_defect: REFUSED — no plugin tree at $SRC" >&2; exit 2; }
for tool in Xvfb xdotool xprop xwininfo import python3 iconv od \
            matchbox-window-manager; do
    command -v "$tool" >/dev/null 2>&1 || {
        echo "drive_defect: REFUSED — '$tool' not on PATH" >&2; exit 2; }
done
mkdir -p "$OUT"
TSV="$OUT/defect_drive.tsv"
printf 'key\tvalue\n' > "$TSV"
emit () { printf '%s\t%s\n' "$1" "$2" >> "$TSV"; }
emit src "$SRC"

XT () { timeout 20 "$@"; }

wb_pausewin () {
    local id nm
    for id in $(XT xprop -root _NET_CLIENT_LIST 2>/dev/null \
                | sed 's/.*# //' | tr -d ' ' | tr ',' ' '); do
        nm=$(XT xprop -id "$id" _NET_WM_NAME 2>/dev/null | sed 's/.*= //')
        case "$nm" in
            *Pause:*) echo "$((id))|$(printf '%b' \
                        "$(printf '%s' "$nm" | sed 's/^"//; s/"$//; s/\\\([0-7][0-7][0-7]\)/\\0\1/g')")"
                      return 0 ;;
        esac
    done
    return 1
}

wb_geom () {
    XT xwininfo -id "$1" 2>/dev/null | awk '
        /Absolute upper-left X/ { x = $4 }
        /Absolute upper-left Y/ { y = $4 }
        /^  Width:/  { w = $2 }
        /^  Height:/ { h = $2 }
        END { if (w == "") exit 1; print x, y, w, h }'
}

PAGEPY="$SCRIPT_DIR/page_wb.py"
wb_read () {
    WB_COMBOS=""; WB_BUTTONS=""
    XT import -window "$1" "$2" 2>/dev/null || return 1
    local line
    while IFS= read -r line; do
        case "$line" in
            combos*)  WB_COMBOS="${line#combos}" ;;
            buttons*) WB_BUTTONS="${line#buttons}" ;;
        esac
    done < <(timeout 30 python3 "$PAGEPY" "$2" 2>/dev/null)
    [ -n "$WB_BUTTONS" ]
}

wb_press () {
    local X Y W H
    read -r X Y W H < <(wb_geom "$1") || return 1
    XT xdotool mousemove $((X + $2)) $((Y + H - 36)) click 1
    sleep 1
}

wb_settle () {
    local old="$1" log="$2" t p
    for ((t = 0; t < 40; t++)); do
        sleep 0.5
        grep -q "PRAAT ERROR MESSAGE" "$log" 2>/dev/null && { echo ""; return 0; }
        p=$(wb_pausewin) || continue
        [ "${p%%|*}" = "$old" ] && continue
        echo "$p"; return 0
    done
    echo ""
    return 0
}

wb_current () {
    local p t
    for ((t = 0; t < 30; t++)); do
        p=$(wb_pausewin) && { echo "$p"; return 0; }
        sleep 0.5
    done
    return 1
}

# wb_setcombo — same recipe as run.sh (tried offsets, popup-diff row click),
# copied because run.sh is a driver script, not a library.
wb_setcombo () {
    local X Y W H t px py rows _wbx
    read -r X Y W H < <(wb_geom "$1") || return 1
    for _wbx in 19 32 45; do
        XT import -window root "$4.c$5.png" 2>/dev/null
        XT xdotool mousemove $((X + W - _wbx)) $((Y + $2)) click 1
        sleep 1.5
        XT import -window root "$4.o$5.png" 2>/dev/null
        rows=$(timeout 30 python3 "$SCRIPT_DIR/popup.py" "$4.c$5.png" "$4.o$5.png" 2>/dev/null)
        [ "${rows%% *}" = "rows" ] && { WB_HIT_X="$_wbx"; break; }
    done
    if [ "${rows%% *}" != "rows" ]; then
        WB_NO_POPUP="$5"; return 0
    fi
    read -r _ px rest <<< "$rows"
    read -r -a WB_ROWS <<< "$rest"
    WB_LAST_ROWS="${#WB_ROWS[@]}"
    if [ "${#WB_ROWS[@]}" -lt "$3" ]; then
        WB_SHORT_POPUP="${#WB_ROWS[@]}"; return 0
    fi
    py="${WB_ROWS[$(( $3 - 1 ))]}"
    XT xdotool mousemove "$px" "$py" click 1
    sleep 1
    for ((t = 0; t < 24; t++)); do
        if wb_read "$1" "$4" 2>/dev/null; then
            read -r -a WB_YS <<< "$WB_COMBOS"
            [ "${#WB_YS[@]}" -ge "${WB_EXPECT_COMBOS:-1}" ] && return 0
        fi
        sleep 0.5
    done
    WB_POPUP_STUCK=1
    return 0
}

# wb_readcombo — READ-ONLY: open the combo's popup, photograph it, ESCAPE
# it shut (no row clicked, nothing selected changes), and report which row
# selected_row.py says is already highlighted. Same tried-offset recipe as
# wb_setcombo, because the arrow position is the same unknown either way.
wb_readcombo () {
    local X Y W H t px _wbx rows sel
    read -r X Y W H < <(wb_geom "$1") || return 1
    WB_SEL=""
    for _wbx in 19 32 45; do
        XT import -window root "$4.rc$5.png" 2>/dev/null
        XT xdotool mousemove $((X + W - _wbx)) $((Y + $2)) click 1
        sleep 1.5
        XT import -window root "$4.ro$5.png" 2>/dev/null
        rows=$(timeout 30 python3 "$SCRIPT_DIR/popup.py" "$4.rc$5.png" "$4.ro$5.png" 2>/dev/null)
        if [ "${rows%% *}" = "rows" ]; then
            sel=$(timeout 30 python3 "$SCRIPT_DIR/selected_row.py" "$4.rc$5.png" "$4.ro$5.png" 2>/dev/null)
            XT xdotool key Escape
            sleep 1
            WB_SEL="$sel"
            WB_READ_ROWS="$rows"
            return 0
        fi
    done
    WB_NO_POPUP_READ=1
    return 0
}

home="$OUT/work/defect_drive"
log="$OUT/defect_drive.log"
rm -rf "$home"; mkdir -p "$home/prefs"

dn=""
for ((cand = ${EML_WB_DISPLAY_BASE:-210} + 61; cand <= ${EML_WB_DISPLAY_BASE:-210} + 90; cand++)); do
    probe=":$cand"
    DISPLAY="$probe" timeout 5 xdpyinfo >/dev/null 2>&1 && continue
    [ -e "/tmp/.X11-unix/X$cand" ] && continue
    dn="$probe"; break
done
[ -n "$dn" ] || { emit state rig_unreachable; echo "no display"; exit 0; }
disp="$dn"
emit display "$disp"

Xvfb "$disp" -screen 0 1400x1100x24 >"$home/xvfb.log" 2>&1 &
xvfb_pid=$!
ready=0
for ((t = 0; t < 60; t++)); do
    if DISPLAY="$disp" xdpyinfo >/dev/null 2>&1; then
        ready=$((ready + 1)); [ "$ready" -ge 2 ] && break
    else ready=0; fi
    sleep 0.5
done

wm_up=0
for ((attempt = 1; attempt <= 3; attempt++)); do
    DISPLAY="$disp" matchbox-window-manager -use_titlebar no >>"$home/wm.log" 2>&1 &
    wm_pid=$!
    for ((t = 0; t < 40; t++)); do
        DISPLAY="$disp" xprop -root _NET_SUPPORTED >/dev/null 2>&1 && { wm_up=1; break; }
        kill -0 "$wm_pid" 2>/dev/null || break
        sleep 0.5
    done
    [ "$wm_up" = 1 ] && break
    kill -9 "$wm_pid" >/dev/null 2>&1; sleep 1
done
if [ "$wm_up" != 1 ]; then
    emit state rig_unreachable
    kill -9 "$wm_pid" "$xvfb_pid" >/dev/null 2>&1; exit 0
fi

HOME="$home" DISPLAY="$disp" "$PRAAT" --pref-dir="$home/prefs" --utf8 \
    $PRAAT_TRUST >"$log" 2>&1 &
gui_pid=$!
export DISPLAY="$disp"

objwin=0
for ((t = 0; t < 80; t++)); do
    for id0 in $(XT xprop -root _NET_CLIENT_LIST 2>/dev/null \
                 | sed 's/.*# //' | tr -d ' ' | tr ',' ' '); do
        nm0=$(XT xprop -id "$id0" _NET_WM_NAME 2>/dev/null | sed 's/.*= //')
        case "$nm0" in *"Praat Objects"*) objwin=1; break ;; esac
    done
    [ "$objwin" = 1 ] && break
    sleep 0.25
done

printf 'writeFile: "%s/ping.txt", "ok"\n' "$home" > "$home/ping.praat"
rm -f "$home/ping.txt"
listening=0
for ((t = 0; t < 4; t++)); do
    HOME="$home" DISPLAY="$disp" timeout 15 "$PRAAT" \
        --pref-dir="$home/prefs" --utf8 $PRAAT_TRUST \
        --send "$home/ping.praat" >/dev/null 2>&1
    if [ -s "$home/ping.txt" ] && kill -0 "$gui_pid" 2>/dev/null; then
        listening=1; break
    fi
    rm -f "$home/ping.txt"
    kill -0 "$gui_pid" 2>/dev/null || break
    sleep 1
done
emit listening "$listening"
if [ "$listening" != 1 ]; then
    emit state rig_unreachable
    kill -9 "$gui_pid" "$wm_pid" "$xvfb_pid" >/dev/null 2>&1; exit 0
fi

printf 'tbl = Read Table from comma-separated file: "%s"\nselectObject: tbl\n' \
    "$SCRIPT_DIR/fixture_corr_err.csv" > "$home/setup.praat"
HOME="$home" DISPLAY="$disp" timeout 30 "$PRAAT" \
    --pref-dir="$home/prefs" --utf8 $PRAAT_TRUST \
    --send "$home/setup.praat" >>"$log" 2>&1
sleep 1

HOME="$home" DISPLAY="$disp" timeout 30 "$PRAAT" \
    --pref-dir="$home/prefs" --utf8 $PRAAT_TRUST \
    --send "$SRC/scripts/eml-wizard.praat" >>"$log" 2>&1

for ((t = 0; t < 40; t++)); do
    wb_pausewin >/dev/null && break
    grep -q "PRAAT ERROR MESSAGE" "$log" 2>/dev/null && break
    sleep 0.5
done

# ---------------------------------------------------------------------------
# Steps 0-2: Goal -> Relationship -> Column select, plain "-@C"-style walk.
# ---------------------------------------------------------------------------
step_plain () {
    # $1 = combo ops ("n:v,n:v" or "-"), $2 = which button ("last" or "back2")
    local p id title ys bx nth val op oplist
    p=$(wb_current) || { emit state stuck_step; exit 0; }
    id="${p%%|*}"; title="${p#*|}"
    emit "page_${STEPN}" "$title"
    wb_read "$id" "$home/page$STEPN.png" || { emit read_fail "step$STEPN"; exit 0; }
    read -r -a ys <<< "$WB_COMBOS"
    read -r -a bx <<< "$WB_BUTTONS"
    if [ -n "$1" ] && [ "$1" != "-" ]; then
        IFS=',' read -r -a oplist <<< "$1"
        WB_EXPECT_COMBOS="${#ys[@]}"
        for op in "${oplist[@]}"; do
            nth="${op%%:*}"; val="${op##*:}"
            wb_setcombo "$id" "${ys[$((nth - 1))]}" "$val" "$home/page$STEPN.png" "$nth"
            emit "step${STEPN}_combo${nth}_rows" "${WB_LAST_ROWS:-0} (wanted $val)"
        done
        wb_read "$id" "$home/page$STEPN.png" >/dev/null 2>&1
        read -r -a bx <<< "$WB_BUTTONS"
    fi
    emit "step${STEPN}_buttons" "${#bx[@]}"
    if [ "$2" = "last" ]; then
        wb_press "$id" "${bx[$(( ${#bx[@]} - 1 ))]}"
    elif [ "$2" = "back3" ]; then
        wb_press "$id" "${bx[$(( ${#bx[@]} - 2 ))]}"
    elif [ "$2" = "back2" ]; then
        wb_press "$id" "${bx[$(( ${#bx[@]} - 1 ))]}"
    fi
    wb_settle "$id" "$log" >/dev/null
    STEPN=$((STEPN + 1))
}

STEPN=0
step_plain "1:2" last          # Q1_GOAL: Research goal = "Examine a relationship"
step_plain "1:1" last          # B1_RELATIONSHIP: Relationship type = Correlation
step_plain "1:1,2:2" last      # B_NORM_PAGE: Column 1 = X, Column 2 = Y

# ---------------------------------------------------------------------------
# B_TEST_PAGE: Test = row 3 ("Both Pearson and Spearman"),
#              Group column = row 2 (the one real candidate, "Cohort").
# Button pressed is the LAST one ("Run") -- triggers the analysis error.
# ---------------------------------------------------------------------------
p=$(wb_current) || { emit state stuck_test_page; exit 0; }
id="${p%%|*}"; title="${p#*|}"
emit "page_${STEPN}" "$title"
wb_read "$id" "$home/page$STEPN.png" || { emit read_fail "step$STEPN"; exit 0; }
read -r -a ys <<< "$WB_COMBOS"
read -r -a bx <<< "$WB_BUTTONS"
emit "test_page_combos" "${#ys[@]}"
emit "test_page_buttons" "${#bx[@]}"
WB_EXPECT_COMBOS="${#ys[@]}"
wb_setcombo "$id" "${ys[0]}" 3 "$home/page$STEPN.png" 1
emit "chose_test_rows" "${WB_LAST_ROWS:-0}"
wb_read "$id" "$home/page$STEPN.png" >/dev/null 2>&1
read -r -a ys <<< "$WB_COMBOS"
wb_setcombo "$id" "${ys[1]}" 2 "$home/page$STEPN.png" 2
emit "chose_group_rows" "${WB_LAST_ROWS:-0}"
wb_read "$id" "$home/page$STEPN.png" >/dev/null 2>&1
read -r -a bx <<< "$WB_BUTTONS"
wb_press "$id" "${bx[$(( ${#bx[@]} - 1 ))]}"     # Run
wb_settle "$id" "$log" >/dev/null
STEPN=$((STEPN + 1))

# ---------------------------------------------------------------------------
# The error dialog: "Quit", "Back" -- TWO buttons. Back is the LAST one, not
# "second from the right" (run.sh's 3-button convention would refuse this
# page outright rather than mis-click it).
# ---------------------------------------------------------------------------
p=$(wb_current) || { emit state no_error_dialog; exit 0; }
id="${p%%|*}"; title="${p#*|}"
emit "error_dialog_title" "$title"
wb_read "$id" "$home/errdlg.png" || { emit read_fail "errdlg"; exit 0; }
read -r -a bx <<< "$WB_BUTTONS"
emit "error_dialog_buttons" "${#bx[@]}"
if [ "${#bx[@]}" -lt 2 ]; then
    emit state back_impossible_on_error
    kill -9 "$gui_pid" "$wm_pid" "$xvfb_pid" >/dev/null 2>&1
    exit 0
fi
wb_press "$id" "${bx[$(( ${#bx[@]} - 1 ))]}"    # Back (last of exactly 2)
wb_settle "$id" "$log" >/dev/null

# ---------------------------------------------------------------------------
# Back at B_TEST_PAGE (the self-goto landed here). Read BOTH combos
# read-only, nothing clicked that changes a value.
# ---------------------------------------------------------------------------
p=$(wb_current) || { emit state no_redraw; exit 0; }
id="${p%%|*}"; title="${p#*|}"
emit "redraw_title" "$title"
wb_read "$id" "$home/redraw.png" || { emit read_fail "redraw"; exit 0; }
read -r -a ys <<< "$WB_COMBOS"
read -r -a bx <<< "$WB_BUTTONS"
emit "redraw_combos" "${#ys[@]}"
emit "redraw_buttons" "${#bx[@]}"

wb_readcombo "$id" "${ys[0]}" 3 "$home/redraw.png" 1
emit "redraw_test_selected_row" "${WB_SEL:-none}"
emit "redraw_test_popup_rows" "${WB_READ_ROWS:-none}"
wb_read "$id" "$home/redraw.png" >/dev/null 2>&1
read -r -a ys <<< "$WB_COMBOS"
wb_readcombo "$id" "${ys[1]}" 2 "$home/redraw.png" 2
emit "redraw_group_selected_row" "${WB_SEL:-none}"
emit "redraw_group_popup_rows" "${WB_READ_ROWS:-none}"

# ---------------------------------------------------------------------------
# Cross-check: press Run again WITHOUT touching anything. @wizardReportPlan
# prints "Test: ..." before the (still-failing, same data) analysis is
# attempted, so the Info window's LAST "Test:" line names the row this
# redraw actually dispatched with.
# ---------------------------------------------------------------------------
wb_read "$id" "$home/redraw2.png" >/dev/null 2>&1
read -r -a bx <<< "$WB_BUTTONS"
wb_press "$id" "${bx[$(( ${#bx[@]} - 1 ))]}"     # Run, untouched
wb_settle "$id" "$log" >/dev/null
p=$(wb_current) || true
emit "after_rerun_title" "${p#*|}"

rm -f "$home/objects.txt"
sed "s|@OUT@|$home/objects.txt|" "$ROOT/harness/coldstart/probe_objects.praat" \
    > "$home/probe.praat"
HOME="$home" DISPLAY="$disp" timeout 30 "$PRAAT" \
    --pref-dir="$home/prefs" --utf8 $PRAAT_TRUST \
    --send "$home/probe.praat" >/dev/null 2>&1
for ((t = 0; t < 40; t++)); do [ -s "$home/objects.txt" ] && break; sleep 0.5; done
if [ -s "$home/objects.txt" ]; then
    case "$(head -c2 "$home/objects.txt" | od -An -tx1 | tr -d ' ')" in
        feff|fffe) iconv -f UTF-16 -t UTF-8 "$home/objects.txt" \
                       > "$OUT/defect_drive.info.txt" 2>/dev/null \
                   || cp "$home/objects.txt" "$OUT/defect_drive.info.txt" ;;
        *)         cp "$home/objects.txt" "$OUT/defect_drive.info.txt" ;;
    esac
    emit "info_bytes" "$(wc -c < "$OUT/defect_drive.info.txt")"
    emit "test_lines" "$(grep -n 'Test:' "$OUT/defect_drive.info.txt" | tr '\n' ';')"
else
    emit state no_info
fi

kill -9 "$gui_pid" "$wm_pid" "$xvfb_pid" >/dev/null 2>&1
wait "$gui_pid" "$wm_pid" "$xvfb_pid" 2>/dev/null
echo "drive_defect: wrote $TSV"
cat "$TSV"
