#!/bin/bash
# ============================================================================
# D117 walk library — per-instance GUI primitives for the parallel rig
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# harness/gui.sh is single-instance (DISPLAY=:99, one pref dir). This is the
# same primitives parameterised by rig instance, so three walks can run at
# once against harness/walks/rig.sh instances 1..3 (:91 :92 :93).
#
# Anchors are read off `import -window root` output and clicked RAW — see the
# rig.sh header, item 2: the plan's ~26px Y correction applies only to
# coordinates derived from `xdotool getwindowgeometry`.
#
# Usage:  I=1 . harness/walks/d117/lib.sh
# ============================================================================

: "${I:?set I to the rig instance number}"
export DISPLAY=":9$I"
# The wizard's page titles contain em dashes. Under the default C locale
# xdotool/xwininfo cannot decode WM_NAME and the window becomes invisible to
# `xdotool search` — the page is on screen but nothing can find it, which
# looks exactly like a hung walk. A UTF-8 locale is not cosmetic here.
export LC_ALL=${LC_ALL:-C.UTF-8}
export LANG=${LANG:-C.UTF-8}
# Scratch GUI rig. Outside the repo on purpose -- it holds a running
# Praat's preferences and Xvfb state, none of which belongs in version
# control. Overridable with RIG=.
RIG=${RIG:-${TMPDIR:-/tmp}/eml-rig}
PREFS="$RIG/prefs_$I"
PRAAT=${PRAAT:-$(command -v praat_barren || command -v praat)}
REPO=${REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}
# PLUGIN_SRC lets one instance run a DIFFERENT plugin tree — used to drive the
# pre-fix wizard alongside the fixed one and capture the differential.
PLUGIN_SRC=${PLUGIN_SRC:-$REPO/plugin}
OUT=${OUT:-$REPO/evidence/walks/d117}
mkdir -p "$OUT"

# launch <script> — relaunch THIS instance running <script>. Kills only the
# praat holding this DISPLAY (never `pkill -x praat`, which would take the
# other two walks with it), and clears pid/message first: a stale pid makes
# the relaunch forward to the dead process and exit.
launch () {
    local s=$1
    for pid in $(pgrep -x praat); do
        tr '\0' '\n' < "/proc/$pid/environ" 2>/dev/null \
            | grep -qx "DISPLAY=$DISPLAY" && kill "$pid" 2>/dev/null
    done
    sleep 1
    rm -f "$PREFS/pid" "$PREFS/message"
    ln -sfn "$PLUGIN_SRC" "$PREFS/plugin_EML_StatsGraphs"
    DISPLAY=$DISPLAY HOME=$PREFS setsid nohup "$PRAAT" --new-send \
        --pref-dir="$PREFS" --utf8 "$s" > "$RIG/log/d117_$I.log" 2>&1 &
    sleep 7
}

shot ()  { import -window root "$OUT/$1.png" >/dev/null 2>&1; echo "$OUT/$1.png"; }
wins ()  { xdotool search --name . getwindowname %@ 2>/dev/null | sort -u; }
click () { xdotool mousemove "$1" "$2" click 1; sleep "${3:-2}"; }

# optsel <x> <y> <n> — click the optionmenu at x,y, then pick the nth item.
# Home first so the walk does not depend on where the menu currently sits.
optsel () {
    xdotool mousemove "$1" "$2" click 1; sleep 1
    xdotool key --clearmodifiers Home; sleep 0.4
    local k=$(( $3 - 1 )) j
    for ((j=0;j<k;j++)); do xdotool key --clearmodifiers Down; sleep 0.25; done
    xdotool key --clearmodifiers Return; sleep 1
}

# infodump <file> — the Info window verbatim, no OCR. Only safe when Praat is
# idle (no modal pause open); Praat services --send messages between scripts.
infodump () {
    local f=$1
    cat > "$PREFS/_dump.praat" <<PEOF
writeFile: "$PREFS/info.txt", info\$ ()
PEOF
    ( DISPLAY=$DISPLAY HOME=$PREFS "$PRAAT" --pref-dir="$PREFS" --utf8 \
        --send "$PREFS/_dump.praat" >/dev/null 2>&1 )
    sleep 2
    if file -b "$PREFS/info.txt" 2>/dev/null | grep -q "UTF-16"; then
        iconv -f UTF-16 -t UTF-8 "$PREFS/info.txt" > "$f"
    else
        cp "$PREFS/info.txt" "$f" 2>/dev/null
    fi
}

# ── Geometry-relative clicking ──────────────────────────────────────────────
#
# Absolute anchors do not survive a page change: a Praat pause window is
# re-centred for every page, so its left edge moves with the widest page seen
# (an error dialog shifts it by ~190 px and every anchor after it is wrong).
# What IS stable across pages, measured on this rig:
#
#   · the button row sits 36 px above the window's bottom edge;
#   · button centres sit at fixed offsets from the LEFT edge, independent of
#     window width — 4 buttons at +56 +192 +319 +444, 3 at +56 +224 +413,
#     2 (the error dialog's Quit/Back) at +224 +413;
#   · every field widget spans at least +267..+502 from the left edge, so
#     +350 is inside all of them whatever the label width. Field ROWS are not
#     predictable — see @pmenus.
#
# Positions come from `xwininfo -id`, whose "Absolute upper-left" is the
# painted client origin — the ~26 px correction in the walk plan applies only
# to `xdotool getwindowgeometry`, which reports the frame (rig.sh header, 2).

# pwin — window id of the mapped Pause window.
#
# NOT via `xdotool search --name`: Praat's pause windows set only
# _NET_WM_NAME, never WM_NAME, and this xdotool matches WM_NAME. Every page
# after the first is therefore invisible to `xdotool search` — the page is on
# screen and nothing can find it, which reads as a hung walk rather than as a
# lookup failure. `harness/gui.sh:pausewin` has the same latent bug; it never
# bit because that harness drives one page at a time from screenshot anchors.
# _NET_CLIENT_LIST + _NET_WM_NAME is what the window manager itself uses.
#
# `sed -n 's/.*# //p'`, not `sed 's/.*# //'`: with no window manager xprop
# prints "_NET_CLIENT_LIST:  no such atom on any window." on stdout, exit 0,
# and the unanchored form passes that sentence through as if it were a window
# list. Same one-character fix as harness/gui.sh:xwins, where it was returning
# seven zeros; fixed in both together rather than in the one that was noticed.
pwin () {
    local w n last=""
    for w in $(xprop -root _NET_CLIENT_LIST 2>/dev/null | sed -n 's/.*# //p' | tr -d ','); do
        n=$(xprop -id "$w" _NET_WM_NAME 2>/dev/null \
            | sed 's/^_NET_WM_NAME(UTF8_STRING) = "//; s/"$//')
        case "$n" in
            Pause:*) xwininfo -id "$w" 2>/dev/null | grep -q "IsViewable" \
                     && last=$w ;;
        esac
    done
    echo "$last"
}

# ptitle — name of the mapped Pause window
ptitle () {
    local w; w=$(pwin); [ -n "$w" ] || return
    xprop -id "$w" _NET_WM_NAME 2>/dev/null \
        | sed 's/^_NET_WM_NAME(UTF8_STRING) = "//; s/"$//'
}

# pgeo — "X Y W H" of the mapped Pause window's client area
pgeo () {
    local w; w=$(pwin); [ -n "$w" ] || { echo "0 0 0 0"; return 1; }
    xwininfo -id "$w" | awk '
        /Absolute upper-left X/ {x=$NF}
        /Absolute upper-left Y/ {y=$NF}
        /^  Width:/  {ww=$NF}
        /^  Height:/ {hh=$NF}
        END {print x, y, ww, hh}'
}

# pbtn <n> <total> [sleep] — click button n of total in the bottom button row
pbtn () {
    local n=$1 tot=$2 nap=${3:-3} row dx g
    case "$tot" in
        4) row="56 192 319 444" ;;
        3) row="56 224 413" ;;
        2) row="224 413" ;;
        *) echo "pbtn: unsupported button count $tot" >&2; return 1 ;;
    esac
    dx=$(echo "$row" | cut -d' ' -f"$n")
    g=$(pgeo); set -- $g
    xdotool mousemove $(( $1 + dx )) $(( $2 + $4 - 36 )) click 1
    sleep "$nap"
}

# pmenus — absolute Y centre of every optionmenu on the page, top to bottom.
#
# NOT computed from a field stride: Praat lays comments and fields out in
# document order, so "fields are N px apart" holds only on pages with no
# comment between them. It is false on the correlation and paired pages, and
# a walk built on it silently sets the wrong field and then reports that the
# guard did not fire — a false NEGATIVE, the expensive kind.
#
# Not the drop-down triangle either: that sits at the widget's RIGHT edge,
# which moves with the label width. The LEFT edge does not — every field
# widget starts at +266 from the window's left edge and draws a 1 px border
# there, mid-grey (~205) against a near-white page (~246). Scan that one
# pixel column; each run of border-grey is one widget.
pmenus () {
    local g x y w h
    g=$(pgeo); set -- $g; x=$1; y=$2; w=$3; h=$4
    [ "$w" -gt 0 ] || return 1
    import -window root -crop "1x${h}+$((x+266))+${y}" +repage png:- 2>/dev/null \
    | convert - -colorspace Gray -depth 8 txt:- \
    | awk -v top="$y" '
        NR>1 {
            split($0, f, ":"); split(f[1], c, ",")
            v = $0; sub(/.*gray\(/, "", v); sub(/\).*/, "", v)
            if (v + 0 > 150 && v + 0 < 232) {
                if (start == "") start = c[2]
                last = c[2]
            } else if (start != "") {
                if (last - start >= 12) print top + int((start + last) / 2)
                start = ""
            }
        }
        END { if (start != "" && last - start >= 12) print top + int((start+last)/2) }'
}

# popt <k> <item> [sleep] — set the k'th optionmenu on the page (1 = topmost)
# to the item'th entry of its list.
popt () {
    local k=$1 item=$2 nap=${3:-1} g cx cy j
    g=$(pgeo); set -- $g
    cx=$(( $1 + 350 ))
    cy=$(pmenus | sed -n "${k}p")
    [ -n "$cy" ] || { echo "popt: no optionmenu $k on [$(ptitle)]" >&2; return 1; }
    xdotool mousemove "$cx" "$cy" click 1; sleep 1
    xdotool key --clearmodifiers Home; sleep 0.4
    for ((j=1;j<item;j++)); do xdotool key --clearmodifiers Down; sleep 0.25; done
    xdotool key --clearmodifiers Return; sleep "$nap"
}
