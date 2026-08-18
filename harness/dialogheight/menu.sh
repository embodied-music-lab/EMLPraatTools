#!/usr/bin/env bash
# ============================================================================
# harness/dialogheight/menu.sh — every menu entry's dialog, measured
# ============================================================================
# THE SAME QUESTION AS run.sh, ASKED OF THE MENU RATHER THAN OF THE GRAPHS
# FORM. run.sh drives the graphs workflow directly, which is the only way to
# put a column-mapping page into its tallest configuration. This one walks the
# real New > EML Stats & Graphs submenu, one command per Praat session, and
# measures whatever dialogs that command opens -- so the wizard, the batch
# form and the eleven stats wrappers are measured through the door a user goes
# through.
#
# THE POSITION PIN IS THE KEYSTROKE COUNT, exactly as harness/batchgui/run.sh
# established it: click "New", Up (wraps to the plugin's cascade header),
# Right (opens the cascade on its first item), Down x (ordinal - 1), Return.
# GTK skips separators during keyboard navigation, so the count is the
# command's ordinal among COMMANDS. The dialog title is recorded beside the
# ordinal, so a walk that lands on the neighbour says so rather than passing.
#
# A TABLE IS SELECTED FIRST, through `praat --send` into the live session,
# because eleven of these commands refuse without one and an error dialog is
# not the dialog being measured.
#
# 1400x2000, for the reason in run.sh's header: a window manager clamps a
# window to its display, so only a screen taller than any dialog gives the
# unclamped height.
#
#   bash harness/dialogheight/menu.sh [ordinal ...]
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$(cd "$SCRIPT_DIR/.." && pwd)/_env.sh" || exit 1

OUT="${EML_DH_MENU_OUT:-$SCRIPT_DIR/out/menu}"
WORK="$OUT/work"
mkdir -p "$OUT" "$WORK"

DISP="${EML_DH_MENU_DISPLAY:-:152}"
SCREEN_W=1400
SCREEN_H=2000
STEPS="${EML_DH_STEPS:-4}"
SEED_CSV="${EML_DH_SEED_CSV:-$SCRIPT_DIR/fixtures/demo_2factor.csv}"
# Clicks to make INSIDE a page before its last button is pressed, as
# "step:x,y" separated by spaces. The wizard's tall pages are behind a
# checkbox that defaults off (prevCheckNorm = 0), so the only way to reach
# them is to tick it -- a click, since a checkbox is not a button.
CLICKS="${EML_DH_CLICKS:-}"

ORDINALS="${*:-1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18}"

XVFB_PID=""; WM_PID=""
cleanup () {
    pkill -9 -x praat 2>/dev/null
    [[ -n "$WM_PID"   ]] && kill -9 "$WM_PID"   2>/dev/null
    [[ -n "$XVFB_PID" ]] && kill -9 "$XVFB_PID" 2>/dev/null
    rm -f "/tmp/.X${DISP#:}-lock" "/tmp/.X11-unix/X${DISP#:}" 2>/dev/null
}
trap cleanup EXIT

# The plugin tree, copied (never symlinked) into a pref dir of this rig's own.
PREFS="$WORK/prefs"
if [[ ! -d "$PREFS/plugin_EML_StatsGraphs" ]]; then
    rm -rf "$PREFS"; mkdir -p "$PREFS"
    cp -r "$REPO/plugin" "$PREFS/plugin_EML_StatsGraphs"
fi
printf 'showAdvanced: 1\n' > "$PREFS/eml-graphs-config.txt"

# THE PATH IS BAKED IN, NOT READ FROM THE ENVIRONMENT. `--send` hands the
# script to the ALREADY-RUNNING instance, which was started without this
# variable, so environment$ () returns "" there and the relative path resolves
# against the script's own folder -- which is a directory, and Praat's error
# for that ("this is a folder, not a file") never reaches this rig's output.
cat > "$WORK/seed.praat" <<EOF
# Put a Table in the Objects list and leave it selected. Eleven of the
# commands under test refuse without one, and a refusal dialog is not the
# dialog being measured.
t = Read Table from comma-separated file: "$SEED_CSV"
selectObject: t
EOF

rm -f "/tmp/.X${DISP#:}-lock" "/tmp/.X11-unix/X${DISP#:}" 2>/dev/null
Xvfb "$DISP" -screen 0 "${SCREEN_W}x${SCREEN_H}x24" > "$WORK/xvfb.log" 2>&1 &
XVFB_PID=$!
sleep 3
DISPLAY="$DISP" xdpyinfo >/dev/null 2>&1 || { echo "menu: FAIL — no display"; exit 1; }
DISPLAY="$DISP" matchbox-window-manager -use_titlebar no > "$WORK/wm.log" 2>&1 &
WM_PID=$!
sleep 2

TSV="$OUT/MENU_HEIGHTS.tsv"
if [[ "${EML_DH_APPEND:-0}" != "1" || ! -s "$TSV" ]]; then
    : > "$TSV"
    printf 'ordinal\tstep\tdialog\twidth\theight\tscreen_h\tclamped\n' >> "$TSV"
fi

winlist () {
    local ids id name
    ids=$(DISPLAY="$DISP" xprop -root _NET_CLIENT_LIST 2>/dev/null \
          | sed -n 's/.*# //p' | tr -d ' ' | tr ',' '\n')
    for id in $ids; do
        [[ "$id" == 0x* ]] || continue
        DISPLAY="$DISP" xwininfo -id "$id" 2>/dev/null | grep -q IsViewable || continue
        name=$(DISPLAY="$DISP" xdotool getwindowname "$id" 2>/dev/null)
        printf '%s\t%s\n' "$id" "$name"
    done
}
winid_by_name () { winlist | awk -F'\t' -v n="$1" '$2==n {print $1; exit}'; }
pausewin () { winlist | awk -F'\t' '$2 ~ /^Pause: / {print $1 "\t" substr($2, 8); exit}'; }
# The client origin is xwininfo's Absolute upper-left, NOT xdotool's Position:
# under matchbox the two differ by the frame inset (batchgui/run.sh, 16 Aug).
origin () {
    DISPLAY="$DISP" xwininfo -id "$1" \
        | awk '/Absolute upper-left X/{x=$NF} /Absolute upper-left Y/{y=$NF} END{print x, y}'
}

run_ordinal () {
    local n="$1"
    local home="$WORK/home"
    rm -rf "$home"; mkdir -p "$home"
    rm -f "$PREFS/pid" "$PREFS/message" 2>/dev/null

    ( DISPLAY="$DISP" HOME="$home" "$PRAAT" $PRAAT_TRUST \
        --pref-dir="$PREFS" --utf8 > "$WORK/praat_$n.log" 2>&1 ) &
    sleep 12

    DISPLAY="$DISP" HOME="$home" \
        timeout 30 "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" --utf8 \
        --send "$WORK/seed.praat" > "$WORK/seed_$n.log" 2>&1
    sleep 4

    local objw; objw=$(winid_by_name "Praat Objects")
    if [[ -z "$objw" ]]; then
        printf '%s\t0\t(no Objects window)\t\t\t%s\tNO-WINDOW\n' "$n" "$SCREEN_H" >> "$TSV"
        pkill -9 -x praat 2>/dev/null; sleep 2; return
    fi
    DISPLAY="$DISP" xdotool windowactivate --sync "$objw" 2>/dev/null; sleep 1
    local o; o=$(origin "$objw")
    DISPLAY="$DISP" xdotool mousemove $(( ${o% *} + 72 )) $(( ${o#* } + 14 )) \
        click --clearmodifiers 1 2>/dev/null
    sleep 2
    DISPLAY="$DISP" xdotool key --clearmodifiers Up;    sleep 1
    DISPLAY="$DISP" xdotool key --clearmodifiers Right; sleep 2
    if [[ "$n" -gt 1 ]]; then
        DISPLAY="$DISP" xdotool key --clearmodifiers --repeat $((n - 1)) --delay 120 Down
    fi
    sleep 1
    DISPLAY="$DISP" import -window root "$OUT/menu_${n}.png" 2>/dev/null
    DISPLAY="$DISP" xdotool key --clearmodifiers Return
    sleep 6

    local waited=0 line=""
    while [[ $waited -lt 30 ]]; do
        line=$(pausewin) && [[ -n "$line" ]] && break
        sleep 2; waited=$((waited+2))
    done
    if [[ -z "$line" ]]; then
        printf '%s\t0\t(no dialog)\t\t\t%s\tNO-DIALOG\n' "$n" "$SCREEN_H" >> "$TSV"
        pkill -9 -x praat 2>/dev/null; sleep 3; return
    fi

    local step=0 wid title geom w h clamp safe
    while [[ $step -lt $STEPS ]]; do
        line=$(pausewin); [[ -n "$line" ]] || break
        wid=${line%%$'\t'*}; title=${line#*$'\t'}
        step=$((step+1))
        geom=$(DISPLAY="$DISP" xdotool getwindowgeometry --shell "$wid" 2>/dev/null)
        w=$(sed -n 's/^WIDTH=//p'  <<< "$geom")
        h=$(sed -n 's/^HEIGHT=//p' <<< "$geom")
        clamp=no
        [[ -n "$h" && "$h" -ge "$SCREEN_H" ]] && clamp=YES
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
            "$n" "$step" "$title" "${w:-?}" "${h:-?}" "$SCREEN_H" "$clamp" >> "$TSV"
        safe=$(tr -c 'A-Za-z0-9' '_' <<< "$title" | sed 's/__*/_/g;s/_$//')
        DISPLAY="$DISP" import -window "$wid" "$OUT/m${n}_${step}_${safe}.png" 2>/dev/null
        DISPLAY="$DISP" xdotool windowactivate --sync "$wid" 2>/dev/null; sleep 1
        local c cs cx cy wo clicked_here=0
        for c in $CLICKS; do
            [[ "${c%%:*}" == "$step" ]] || continue
            clicked_here=1
            cs=${c#*:}; cx=${cs%,*}; cy=${cs#*,}
            wo=$(origin "$wid")
            DISPLAY="$DISP" xdotool mousemove $(( ${wo% *} + cx )) $(( ${wo#* } + cy )) \
                click --clearmodifiers 1 2>/dev/null
            sleep 1
            DISPLAY="$DISP" import -window "$wid" "$OUT/m${n}_${step}_clicked.png" 2>/dev/null
        done
        # Press the LAST button (one shift+Tab wraps to it) and see where the
        # next page is. On most pages that is Continue / OK / Run.
        #
        # NOT AFTER A CLICK. The shift+Tab law holds only from ring position
        # 0: a click leaves focus ON THE WIDGET CLICKED, so one shift+Tab
        # walks BACKWARDS one field instead of wrapping to the last button,
        # and Return then does nothing visible. The page simply re-appeared,
        # which reads as "the wizard refused" rather than as "the harness
        # pressed the wrong thing". So a step that clicks must click its
        # button too, and $CLICKS carries that press.
        if [[ $clicked_here -eq 1 ]]; then
            sleep 6
        else
            DISPLAY="$DISP" xdotool key --clearmodifiers shift+Tab 2>/dev/null; sleep 1
            DISPLAY="$DISP" xdotool key --clearmodifiers Return 2>/dev/null; sleep 6
        fi
    done
    pkill -9 -x praat 2>/dev/null
    sleep 3
}

echo "menu: screen=${SCREEN_W}x${SCREEN_H} ordinals=[$ORDINALS] steps=$STEPS"
for n in $ORDINALS; do
    echo "  ordinal $n"
    run_ordinal "$n"
done
awk -F'\t' '{printf "%-4s %-3s %-44s %-6s %-6s %s\n",$1,$2,$3,$4,$5,$7}' "$TSV"
echo "menu: wrote $TSV"
