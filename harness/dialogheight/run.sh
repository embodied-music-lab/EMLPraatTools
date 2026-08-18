#!/usr/bin/env bash
# ============================================================================
# harness/dialogheight/run.sh — how tall is each dialog, really
# ============================================================================
# THE SCREEN IS DELIBERATELY TALLER THAN ANY SCREEN A USER HAS. A window
# manager clamps a window to the display it is on, so a dialog measured on a
# 1000 px screen reports 1000 px whatever its content asks for -- which is the
# one number that cannot be compared against 768, 900 and 1080. This rig runs
# 1400x2000 so that every measurement is the UNCLAMPED height, and it records
# the screen height beside each measurement so a clamped reading would be
# visible as equality rather than passing as a result.
#
# ONE PRAAT SESSION PER GRAPH TYPE, driven by keystroke only (no screen
# coordinates): focus starts at ring position 0, so ONE shift+Tab wraps to the
# last widget, which is the last button. On the "EML Graphs" page and on the
# Line Chart "Data Format" page the last button is Continue, so one press
# advances. On a Column Mapping page the last button is Draw -- which is where
# this rig STOPS, because it wants the dialog, not the figure.
#
# ADVANCED MODE COMES FROM THE PREF DIR, not from the toggle button: the
# toggle enters the page on its RESTORE arm, which re-seeds fields from a
# stash and is therefore a different page. graphseams/adjustarm.sh made the
# same choice for the same reason.
#
# KILLING. `pkill -9 -x praat`, never `-f`: the -f form matches this script's
# own command line through the driving shell and kills the run (D126).
#
#   bash harness/dialogheight/run.sh [type ...]
#   EML_DH_MODE=beginner bash harness/dialogheight/run.sh
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$SCRIPT_DIR/.." && pwd)/_env.sh" || exit 1

MODE="${EML_DH_MODE:-advanced}"
OUT="${EML_DH_OUT:-$SCRIPT_DIR/out/$MODE}"
mkdir -p "$OUT"

DISP="${EML_DH_DISPLAY:-:151}"
SCREEN_W="${EML_DH_W:-1400}"
SCREEN_H="${EML_DH_H:-2000}"

TYPES="${*:-1 2 3 4 5 6 7 8 9 10 11 12 13}"

XVFB_PID=""; WM_PID=""
cleanup () {
    pkill -9 -x praat 2>/dev/null
    [[ -n "$WM_PID"   ]] && kill -9 "$WM_PID"   2>/dev/null
    [[ -n "$XVFB_PID" ]] && kill -9 "$XVFB_PID" 2>/dev/null
    rm -f "/tmp/.X${DISP#:}-lock" "/tmp/.X11-unix/X${DISP#:}" 2>/dev/null
}
trap cleanup EXIT

rm -f "/tmp/.X${DISP#:}-lock" "/tmp/.X11-unix/X${DISP#:}" 2>/dev/null
Xvfb "$DISP" -screen 0 "${SCREEN_W}x${SCREEN_H}x24" > "$OUT/xvfb.log" 2>&1 &
XVFB_PID=$!
sleep 3
DISPLAY="$DISP" xdpyinfo >/dev/null 2>&1 || { echo "dialogheight: FAIL — no display"; exit 1; }
DISPLAY="$DISP" matchbox-window-manager -use_titlebar no > "$OUT/wm.log" 2>&1 &
WM_PID=$!
sleep 2

TSV="$OUT/HEIGHTS.tsv"
# APPEND, when asked. Ten minutes is the cap on one of these runs, so the
# thirteen types are driven in batches; a truncating rig would leave only the
# last batch's numbers in the file it is supposed to be the record of.
if [[ "${EML_DH_APPEND:-0}" != "1" || ! -s "$TSV" ]]; then
    : > "$TSV"
    printf 'type\tmode\tdialog\twidth\theight\tscreen_h\tclamped\n' >> "$TSV"
fi

pauseinfo () {
    local ids id name
    ids=$(DISPLAY="$DISP" xprop -root _NET_CLIENT_LIST 2>/dev/null \
          | sed -n 's/.*# //p' | tr -d ' ' | tr ',' '\n')
    for id in $ids; do
        [[ "$id" == 0x* ]] || continue
        DISPLAY="$DISP" xwininfo -id "$id" 2>/dev/null | grep -q IsViewable || continue
        name=$(DISPLAY="$DISP" xdotool getwindowname "$id" 2>/dev/null)
        if [[ "$name" == Pause:* ]]; then
            printf '%s\t%s\n' "$id" "${name#Pause: }"; return 0
        fi
    done
    return 1
}

run_type () {
    local t="$1"
    local prefs="$SCRIPT_DIR/work/prefs_$t" home="$SCRIPT_DIR/work/home_$t"
    rm -rf "$prefs" "$home"; mkdir -p "$prefs" "$home"
    if [[ "$MODE" == "advanced" ]]; then
        printf 'showAdvanced: 1\n' > "$prefs/eml-graphs-config.txt"
    else
        printf 'showAdvanced: 0\n' > "$prefs/eml-graphs-config.txt"
    fi
    rm -f "$prefs/pid" "$prefs/message" 2>/dev/null

    ( cd "$SCRIPT_DIR" && DISPLAY="$DISP" HOME="$home" \
        EML_DH_TYPE="$t" EML_DH_NONPAR="${EML_DH_NONPAR:-1}" \
        "$PRAAT" $PRAAT_TRUST --pref-dir="$prefs" --utf8 --new-send \
        driver.praat > "$OUT/driver_$t.log" 2>&1 ) &
    local pid=$!

    local waited=0 line=""
    while [[ $waited -lt 40 ]]; do
        line=$(pauseinfo) && break
        sleep 2; waited=$((waited+2))
    done
    if [[ -z "$line" ]]; then
        printf '%s\t%s\t%s\t\t\t%s\tNO-DIALOG\n' "$t" "$MODE" "(none reached)" "$SCREEN_H" >> "$TSV"
        pkill -9 -x praat 2>/dev/null; sleep 2; return
    fi

    local step=0 wid title geom w h clamp safe
    while [[ $step -lt 6 ]]; do
        line=$(pauseinfo) || break
        wid=${line%%$'\t'*}; title=${line#*$'\t'}
        step=$((step+1))
        geom=$(DISPLAY="$DISP" xdotool getwindowgeometry --shell "$wid" 2>/dev/null)
        w=$(sed -n 's/^WIDTH=//p'  <<< "$geom")
        h=$(sed -n 's/^HEIGHT=//p' <<< "$geom")
        clamp=no
        [[ -n "$h" && "$h" -ge "$SCREEN_H" ]] && clamp=YES
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
            "$t" "$MODE" "$title" "${w:-?}" "${h:-?}" "$SCREEN_H" "$clamp" >> "$TSV"
        safe=$(tr -c 'A-Za-z0-9' '_' <<< "$title" | sed 's/__*/_/g;s/_$//')
        DISPLAY="$DISP" import -window "$wid" "$OUT/t${t}_${step}_${safe}.png" 2>/dev/null
        # A page whose last button is Draw is the page this rig wanted.
        case "$title" in
            *"Column Mapping"*|*"Settings") break ;;
        esac
        DISPLAY="$DISP" xdotool windowactivate --sync "$wid" 2>/dev/null; sleep 1
        DISPLAY="$DISP" xdotool key --clearmodifiers shift+Tab 2>/dev/null; sleep 1
        DISPLAY="$DISP" xdotool key --clearmodifiers Return 2>/dev/null; sleep 5
    done
    pkill -9 -x praat 2>/dev/null
    sleep 2
}

echo "dialogheight: mode=$MODE screen=${SCREEN_W}x${SCREEN_H} types=[$TYPES]"
for t in $TYPES; do
    echo "  type $t"
    run_type "$t"
done
column -t -s$'\t' "$TSV"
echo "dialogheight: wrote $TSV"
