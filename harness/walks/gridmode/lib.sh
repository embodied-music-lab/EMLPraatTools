#!/bin/bash
# ============================================================================
# Gridmode walk library — geometry helpers d117/lib.sh does not cover
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Sourced AFTER harness/walks/d117/lib.sh. That library drives the wizard,
# whose pages are uniform; the graph dialogs are not, and these are the five
# primitives the difference costs.
#
#   glaunch  relaunch that waits for the old instance to actually die
#   gbtnrow  find the bottom button row by looking at it
#   gbtn     click endPause button k of total, counted from the RIGHT
#   gfirst   click the leftmost button (pages whose button count varies)
#   gerr     surface Praat's error dialog, which hides under the Objects window
#   gwaitcfg wait for the config file rather than assume it was flushed
#   gdrop    screenshot an optionmenu with its list OPEN
#
# On `gbtn` specifically. d117/lib.sh's `pbtn` uses fixed offsets from the
# window's left edge (4 buttons at +56 +192 +319 +444). Those were measured on
# the wizard, and a Praat button is as wide as its LABEL, so they do not
# transfer: on the Scatter Plot page (Undo / Go Back / Quit / Beginner / Draw)
# the real centres are +56 +182 +273 +372 +461, and pbtn's fourth offset lands
# 17 px inside the Draw button purely by luck of how wide "Beginner" is. One
# longer label anywhere in the row and the click hits the gap between two
# buttons, the page does not advance, and the walk reports whatever the NEXT
# step happens to find — a false negative.
#
# Praat draws each button as a face the same grey as the page (240 vs 239)
# with a one-pixel mid-grey border (~200) on each side. Faces are invisible;
# borders are not. Scan the row, pair the borders, and the buttons are the
# pairs. Praat's own Undo/Revert button is prepended on pages that have
# reversible fields and absent on pages that do not, so the row's LEFT end is
# not a fixed reference and `gbtn` counts from the right.
#
# On `gdrop`. It shoots the menu with its list open, which is what makes
# "Horizontal is selected" and "Off is selected" legible — GTK places the
# SELECTED item under the pointer, so the highlighted row is the current
# value. That is what the meaning-preservation half of C1 turns on.
#
# It is NOT the evidence for the blank half, and must not be read as such:
# with nothing selected GTK has no item to place under the pointer, so it
# top-aligns the list instead and the FIRST entry lands under the cursor and
# takes the pointer's hover highlight. `prefix_off_4_histogram_dropped.png`
# therefore looks like "Horizontal is selected" when the control is in fact
# unset. The blank is shown by the CLOSED dialog shot and proved by the
# refusal `gerr` captures. Escape closes the list without selecting, which the
# pre-fix run confirms: the refusal still fired afterwards.
# ============================================================================

# glaunch <script> — `launch` that verifies the old instance is actually gone
# and that the new one actually reached its first page.
#
# d117/lib.sh's `launch` sends TERM and sleeps 1. That is enough between
# wizard pages; it is not enough here, because this walk leaves the previous
# instance sitting on a MODAL pause dialog and a Praat blocked in a modal
# event loop does not always service TERM inside a second. The relaunch then
# starts while the old process still owns the display, and the walk's next
# step finds no pause window, reports "no optionmenu 1 on []", and carries on
# doing nothing to a page that is not there — every later step a false
# negative. So: TERM, wait for the pid to leave, KILL if it will not, and only
# then launch. Then confirm a Pause window exists before returning.
glaunch () {
    local s=$1 pid t
    for pid in $(pgrep -x praat); do
        # 2>/dev/null on the read: with several walks in flight a pid can
        # exit between pgrep and here, and the resulting "No such file" is
        # noise that reads like a rig fault.
        tr '\0' '\n' < "/proc/$pid/environ" 2>/dev/null \
            | grep -qx "DISPLAY=$DISPLAY" || continue
        kill "$pid" 2>/dev/null
        for t in 1 2 3 4 5 6 7 8 9 10; do
            kill -0 "$pid" 2>/dev/null || break
            sleep 1
        done
        kill -0 "$pid" 2>/dev/null && kill -9 "$pid" 2>/dev/null
    done
    sleep 1
    rm -f "$PREFS/pid" "$PREFS/message"
    ln -sfn "$PLUGIN_SRC" "$PREFS/plugin_EML_Praat_Tools"
    DISPLAY=$DISPLAY HOME=$PREFS setsid nohup "$PRAAT" --new-send \
        --pref-dir="$PREFS" --utf8 "$s" > "$RIG/log/gridmode_$I.log" 2>&1 &
    for t in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
        sleep 1
        [ -n "$(pwin)" ] && return 0
    done
    echo "glaunch: no Pause window 15 s after launching $s" >&2
    return 1
}

# gbtnrow — "x1 x2 x3 ..." absolute centres of every button in the bottom row
#
# A single scan line through the button row does NOT work: label glyphs are
# antialiased and throw pixels all over the 185..215 border band, so a row scan
# finds "borders" inside the word "Redraw". What separates a border from a
# glyph is that the border is a 1 px column running the FULL height of the
# button and a glyph is not. So the scan takes a 21 px tall band centred on the
# row and keeps only columns that are border-grey for at least 19 of those 21
# pixels. Text tops out around 8.
gbtnrow () {
    local g x y w h
    g=$(pgeo); set -- $g; x=$1; y=$2; w=$3; h=$4
    [ "$w" -gt 0 ] || return 1
    import -window root -crop "${w}x21+${x}+$(( y + h - 36 - 10 ))" +repage png:- 2>/dev/null \
    | convert - -colorspace Gray -depth 8 txt:- \
    | awk -v left="$x" '
        NR>1 {
            split($0, f, ":"); split(f[1], c, ",")
            v = $0; sub(/.*gray\(/, "", v); sub(/\).*/, "", v)
            if (v + 0 >= 185 && v + 0 <= 215) { hit[c[1]] += 1 }
            if (c[1] + 0 > maxx) maxx = c[1] + 0
        }
        END {
            for (col = 0; col <= maxx; col++) {
                if (hit[col] >= 19) b[n++] = col
            }
            # Pair borders left to right; a pair 40..200 px apart is a button.
            i = 0
            while (i < n - 1) {
                wdt = b[i+1] - b[i]
                if (wdt >= 40 && wdt <= 200) {
                    printf "%d ", left + int((b[i] + b[i+1]) / 2)
                    i += 2
                } else {
                    i += 1
                }
            }
            printf "\n"
        }'
}

# gbtn <k> <total> [sleep] — click endPause button k of total.
#
# Indexed from the RIGHT, not the left. Praat adds its own Undo/Revert button
# to the left of the row on pages that have reversible fields and omits it on
# pages that do not — "Graph Complete" has three buttons and no Undo, the
# Scatter Plot page has four and an Undo. The endPause buttons are always the
# rightmost `total` of whatever is there, so counting from the right is the
# only stable index. Refuses rather than guesses if the row it found is
# shorter than the caller says: a mis-click here does not raise an error, it
# advances to a different page, and the walk then reports on the wrong dialog.
gbtn () {
    local k=$1 total=$2 nap=${3:-3} row n cx g
    row=$(gbtnrow)
    n=$(echo "$row" | wc -w)
    if [ "$n" -lt "$total" ]; then
        echo "gbtn: page [$(ptitle)] shows $n buttons, caller expected $total [$row]" >&2
        return 1
    fi
    cx=$(echo "$row" | cut -d' ' -f"$(( n - total + k ))")
    [ -n "$cx" ] || { echo "gbtn: no button $k/$total in [$row]" >&2; return 1; }
    g=$(pgeo); set -- $g
    xdotool mousemove "$cx" $(( $2 + $4 - 36 )) click 1
    sleep "$nap"
}

# gfirst [sleep] — click the LEFTMOST button in the row.
#
# For "Graph Complete", whose button count is not knowable in advance: it is
# `endPause: "Done", "Save", "Exp CSV", "Redraw"` when the drawing buffered
# CSV rows and `endPause: "Done", "Save", "Redraw"` when it did not
# (eml-graphs-form.praat, POST-DRAW OPTIONS). A scatter plot runs a
# correlation and buffers rows; a histogram does not — so the same walk step
# meets four buttons on one page and three on the next, and `gbtn 1 3` on the
# four-button version counts from the right and presses Save. That mis-click
# opens a file dialog and leaves the workflow unfinished, so @emlSaveConfig
# never runs and the config file the next step reads is stale — which reads
# exactly like "the plugin did not persist the setting".
#
# Safe here only because the page has no fields and therefore no Undo button.
gfirst () {
    local nap=${1:-3} row cx g
    row=$(gbtnrow)
    cx=$(echo "$row" | cut -d' ' -f1)
    [ -n "$cx" ] || { echo "gfirst: no buttons on [$(ptitle)]" >&2; return 1; }
    g=$(pgeo); set -- $g
    xdotool mousemove "$cx" $(( $2 + $4 - 36 )) click 1
    sleep "$nap"
}

# gwaitcfg <file> <pattern> [tries] — wait until <file> matches <pattern>.
# The config file is this walk's evidence; reading it before the workflow has
# flushed it is how a walk reports "not persisted" about a value that was.
gwaitcfg () {
    local f=$1 pat=$2 tries=${3:-15} t
    for t in $(seq 1 "$tries"); do
        grep -q "$pat" "$f" 2>/dev/null && return 0
        sleep 1
    done
    echo "gwaitcfg: $f never matched /$pat/ after ${tries}s" >&2
    return 1
}

# gerr <name> — screenshot Praat's error dialog if one is up; 1 if none is.
#
# Praat's message window sets neither WM_NAME nor a usable _NET_WM_NAME — it
# enumerates with an empty name — so it is found by elimination: the viewable
# client that is not an application window and not a Pause page. It is also
# placed centred, which on this rig is directly under the Objects window, and
# neither `windowactivate --sync` (which succeeds, rc 0) nor `windowraise`
# lifts it above a window openbox is keeping on top. Moving it into empty
# screen is what actually makes it readable in a still.
gerr () {
    local name=$1 w n hit=""
    # sed -n ... p — see the note on harness/gui.sh:xwins. The unanchored form
    # turns xprop's "no such atom" sentence into a fake window list.
    for w in $(xprop -root _NET_CLIENT_LIST 2>/dev/null | sed -n 's/.*# //p' | tr -d ','); do
        n=$(xprop -id "$w" _NET_WM_NAME 2>/dev/null \
            | sed 's/^_NET_WM_NAME(UTF8_STRING) = "//; s/"$//')
        case "$n" in
            Praat*|Pause:*) continue ;;
        esac
        xwininfo -id "$w" 2>/dev/null | grep -q IsViewable && hit=$w
    done
    [ -n "$hit" ] || return 1
    xdotool windowmove "$hit" 30 60; sleep 1
    xdotool windowactivate --sync "$hit" 2>/dev/null; sleep 1
    shot "$name"
}

# gdrop <k> <name> — open the kth optionmenu, screenshot it, close it again
gdrop () {
    local k=$1 name=$2 g cx cy
    g=$(pgeo); set -- $g
    cx=$(( $1 + 350 ))
    cy=$(pmenus | sed -n "${k}p")
    [ -n "$cy" ] || { echo "gdrop: no optionmenu $k on [$(ptitle)]" >&2; return 1; }
    xdotool mousemove "$cx" "$cy" click 1; sleep 1.5
    shot "$name"
    xdotool key --clearmodifiers Escape; sleep 1
}
