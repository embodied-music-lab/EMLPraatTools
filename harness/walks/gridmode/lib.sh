#!/bin/bash
# ============================================================================
# Gridmode walk library — geometry helpers d117/lib.sh does not cover
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Sourced AFTER harness/walks/d117/lib.sh. That library drives the wizard,
# whose pages are uniform; the graph dialogs are not, and these are the
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
# and, from 16 August 2026, the rendered-state group — see the block above
# `gscreen` near the bottom of this file for why they exist:
#
#   ggeom    refuse to run at a screen size this walk's pages do not fit on
#   gsnap    OCR every field widget on the page: ordinal, label, rendered value
#   gfind    the ordinal of the widget whose LABEL says what you meant
#   gset     set a control BY NAME and prove afterwards that it, and only it,
#            now reads what was intended
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

# ===========================================================================
# RENDERED-STATE ADDRESSING — added 16 August 2026
# ===========================================================================
# WHAT WENT WRONG. `walk.sh` addressed the Gridline mode menu as "widget
# ordinal 13", with a comment naming the twelve widgets it counted past. Two
# changes to `plugin/graphs/eml-graphs-form.praat` landed after that count was
# taken. D11 (14 Aug) made "Group column" and "Group order" exist only when
# "Use group column" is ticked, which removed two widgets from the top of the
# Scatter page; "Legend placement" was added below Gridline mode, which did
# not move it back. Gridline mode is now ordinal **11** and ordinal 13 is
# **Output DPI**.
#
# Nothing failed. Driven at the documented geometry on 16 August, `walk.sh off`
# set Output DPI — a two-option menu — to "item 4", which lands on its last
# entry, and wrote `outputDPI: 2` where the previous run wrote 1. Gridline mode
# was never touched, so `gridlineMode:` kept the plugin default of 1 (Both)
# while the walk printed `accepted: Draw proceeded, no error dialog` and exited
# 0. A walk that reports success while setting a different control than the one
# it names is worse than a walk that fails: its evidence is filed, cited and
# believed.
#
# This is the failure `harness/MENU_MAP.md` documents three times over for menu
# entries — "a stale menu constant does not error, it clicks whatever moved
# into its place" — arriving in a second address space. The remedy is the same
# one: address the thing by something the running program renders, and read the
# rendering back.
#
# HOW. A Praat pause form draws every field's label in the column left of the
# widget and, for an optionmenu, the current option's text inside it. Both are
# on screen, and tesseract reads them off a crop reliably at this size (the
# labels are 11 px sans; upscaling 2x before OCR is what makes it reliable).
# So:
#
#   · `gfind "Gridline mode"` returns the ordinal the label is actually at,
#     this run, on this page, in this tree — no constant to go stale;
#   · `gset` snapshots every widget's rendered value, sets one, snapshots
#     again, and refuses unless the named control now reads what was intended
#     AND no other control moved. The second half is what catches Output DPI:
#     the intent "set Gridline mode to Off" is violated as much by silently
#     changing the DPI as by leaving the gridlines alone.
#
# WHAT THIS DOES NOT FIX. OCR is a reading of pixels, so it inherits the
# screen: a page clipped by a short screen has widgets that cannot be read
# because they are not drawn. That is `ggeom`'s job, below, and it is a refusal
# rather than a warning for the same reason — at 1280x900 the advanced Scatter
# page's button row is off the bottom of the screen, `gbtn` finds no buttons,
# and every step after it operates on a page that never advanced.

# --- geometry ---------------------------------------------------------------
# The advanced Scatter page asked for 1065 px before the 15 August row trim and
# 999 px after it (measured; see the §6 note in eml-graphs-form.praat), plus
# window chrome and the ~560 px openbox offsets the page down by on this rig.
# 1400x1600 is the size the committed evidence was taken at and the size named
# in evidence/walks/gridmode/README.md; it is required, not advisory.
GRIDMODE_MIN_W=${GRIDMODE_MIN_W:-1400}
GRIDMODE_MIN_H=${GRIDMODE_MIN_H:-1600}

# ggeom — refuse unless $DISPLAY is at least GRIDMODE_MIN_W x GRIDMODE_MIN_H.
ggeom () {
    local dims w h
    dims=$(xdpyinfo 2>/dev/null | awk '/^  dimensions:/ {print $2; exit}')
    if [ -z "$dims" ]; then
        echo "ggeom: cannot read the screen size of DISPLAY=$DISPLAY — is Xvfb up?" >&2
        return 1
    fi
    w=${dims%%x*}; h=${dims##*x}
    if [ "$w" -ge "$GRIDMODE_MIN_W" ] && [ "$h" -ge "$GRIDMODE_MIN_H" ]; then
        return 0
    fi
    cat >&2 <<EOM
ggeom: REFUSING TO RUN — DISPLAY=$DISPLAY is ${w}x${h}, this walk needs at
       least ${GRIDMODE_MIN_W}x${GRIDMODE_MIN_H}.

       The advanced Scatter Plot page is the tallest dialog in the plugin
       (~999 px of fields). On a screen this short the window manager clamps
       it and the Go Back / Quit / Beginner / Draw row is off the bottom:
       \`gbtn\` then finds zero buttons, the page never advances, and every
       later step reports on a page it never reached. The rig default of
       1280x900 is one of the sizes this happens at.

       Bring the rig up at the size the evidence was taken at:

           GEOM=${GRIDMODE_MIN_W}x${GRIDMODE_MIN_H}x24 harness/walks/rig.sh up 2

       Overriding GRIDMODE_MIN_W / GRIDMODE_MIN_H is possible and is not a fix.
EOM
    return 1
}

# --- reading the rendered page ----------------------------------------------
# Field-widget geometry on a Praat pause page, measured on this rig
# (1400x1600, openbox, Praat 6.6.30) and stated relative to the CLIENT origin
# `pgeo` reports, so it does not depend on where the page is placed:
#
#   · the label column runs from about +5 to +260 and is right-aligned
#     against the widget, so a wide crop is safe and a narrow one is not;
#   · the widget's 1 px left border is at +266 — the column `pmenus` scans;
#   · an optionmenu draws its current option's text from about +272, and the
#     little ▾ at the widget's right edge, which OCR reads as a stray "v" and
#     which the callers below therefore never anchor on.
#
# Crops are taken from ONE screenshot per snapshot rather than one per widget:
# nineteen `import` calls of a 1400x1600 root window is slower than the OCR is,
# and a row read from a different frame than its neighbour is not a snapshot.
GRIDMODE_LBL_X=${GRIDMODE_LBL_X:-5};    GRIDMODE_LBL_W=${GRIDMODE_LBL_W:-255}
GRIDMODE_VAL_X=${GRIDMODE_VAL_X:-272};  GRIDMODE_VAL_W=${GRIDMODE_VAL_W:-220}

# gscreen <file> — one screenshot of the whole screen
gscreen () { import -window root "$1" 2>/dev/null; }

# gocr <file> <x> <y> <w> <h> — OCR one crop as a single line of text.
#   --psm 7 = "one text line", which is what a label and an option both are.
#   2x upscale before OCR: at native size tesseract drops the leading capital
#   of about one label in four on this font. Measured, not assumed.
gocr () {
    convert "$1" -crop "${4}x${5}+${2}+${3}" +repage -colorspace Gray \
            -resize 200% png:- 2>/dev/null \
    | tesseract stdin stdout --psm 7 2>/dev/null \
    | tr -d '\r' | tr '\n' ' ' | sed 's/  */ /g; s/^ *//; s/ *$//'
}

# gsnap — "<ordinal>\t<label>\t<rendered value>" for every field widget on the
#   page, top to bottom. The ordinal is `pmenus`' ordinal, so it is the same
#   number `popt` and `gdrop` take.
#
# The label crop takes in whatever sits immediately above the widget, so a
# label can arrive prefixed with the tail of a `comment:` line — "🎨 Layout"
# reads as "oO " in front of "Gridline mode:". Callers match on a SUBSTRING for
# that reason; anchoring the regex at ^ will not work and is not meant to.
gsnap () {
    local g x y w h cy k=0 lbl val png
    g=$(pgeo); set -- $g; x=$1; y=$2; w=$3; h=$4
    [ "$w" -gt 0 ] || { echo "gsnap: no mapped Pause page" >&2; return 1; }
    png=$(mktemp "${TMPDIR:-/tmp}/gsnap_XXXXXX.png") || return 1
    gscreen "$png" || { rm -f "$png"; return 1; }
    for cy in $(pmenus); do
        k=$((k + 1))
        lbl=$(gocr "$png" $((x + GRIDMODE_LBL_X)) $((cy - 12)) "$GRIDMODE_LBL_W" 24)
        # The ▾ at an optionmenu's right edge OCRs as a trailing "v", so an
        # optionmenu with NO selection reads "v" rather than "". That matters:
        # the blank control is what C1's first half IS, and a log line saying
        # `renders: "v"` reads like a value. Strip a trailing standalone v —
        # never a word-final one, so a column named "conv" survives.
        val=$(gocr "$png" $((x + GRIDMODE_VAL_X)) $((cy - 11)) "$GRIDMODE_VAL_W" 22 \
              | sed 's/[[:space:]][vV]$//; s/^[vV]$//')
        printf '%d\t%s\t%s\n' "$k" "$lbl" "$val"
    done
    rm -f "$png"
}

# gfind <snapshot> <label-regex> — the ordinal of the one widget whose label
#   matches. Refuses on zero matches and on more than one, printing the whole
#   page so the failure names what IS there rather than only what is not.
#
# Matching is CASE-INSENSITIVE, here and in `gset`'s value check, and that is
# measured rather than defensive: on this font at this size tesseract returns
# the Scatter page's "Off" as "off" — a two-letter word with no ascender beside
# it gives the classifier nothing to set the cap height against. Every option
# these callers distinguish differs by more than case ("Off" / "Horizontal
# only" / "Horizontal" / "Both" / "300 dpi" / "600 dpi"), so folding case costs
# no discrimination. Do not "fix" it by anchoring on the capital.
gfind () {
    local snap=$1 re=$2 hits n
    hits=$(printf '%s\n' "$snap" | while IFS=$'\t' read -r k lbl val; do
               printf '%s' "$lbl" | grep -qiE "$re" && printf '%s\n' "$k"
           done)
    n=$(printf '%s\n' "$hits" | grep -c '[0-9]')
    if [ "$n" -eq 1 ]; then printf '%s\n' "$hits"; return 0; fi
    {
        if [ "$n" -eq 0 ]; then
            echo "gfind: no widget on [$(ptitle)] has a label matching /$re/"
        else
            echo "gfind: $n widgets on [$(ptitle)] match /$re/ — ambiguous: $hits"
        fi
        echo "       the page renders these field widgets:"
        printf '%s\n' "$snap" | sed 's/^/         /'
    } >&2
    return 1
}

# gset <label-regex> <option-index> <expected-regex> <name> [forced-ordinal]
#
#   Set the optionmenu whose label matches <label-regex> to its <option-index>'th
#   entry, then PROVE it: the named control must render something matching
#   <expected-regex>, and no other widget on the page may have changed at all.
#
#   Returns 1 and prints the control's name, the intended value and the
#   rendered value if either half fails. <name> is what a reader of the log
#   should see; it is not used to find anything.
#
#   <forced-ordinal>, if non-empty, is clicked INSTEAD of the ordinal the label
#   was found at. It exists so the assertion can be break-tested against a
#   deliberately wrong address without editing this file — the check still runs
#   against the row the label is really on, which is the point. Nothing in the
#   walk passes a non-empty value by default.
#
#   Leaves the discovered ordinal in $GSET_ORDINAL, so a caller that wants to
#   `gdrop` the same widget does not pay for a second page snapshot. It is set
#   as soon as the label is found, i.e. it holds a usable value even on the
#   failure returns below.
GSET_ORDINAL=""
gset () {
    local re=$1 item=$2 want=$3 name=$4 force=${5:-}
    local before after k kf lbl val moved

    GSET_ORDINAL=""
    before=$(gsnap) || return 1
    k=$(gfind "$before" "$re") || return 1
    GSET_ORDINAL=$k
    lbl=$(printf '%s\n' "$before" | awk -F'\t' -v k="$k" '$1 == k {print $2}')
    kf=$k
    if [ -n "$force" ] && [ "$force" != "$k" ]; then
        kf=$force
        echo "gset: FORCED — clicking widget ordinal $kf; \"$name\" renders at ordinal $k" >&2
    fi

    popt "$kf" "$item" || return 1
    after=$(gsnap) || return 1
    val=$(printf '%s\n' "$after" | awk -F'\t' -v k="$k" '$1 == k {print $3}')

    if ! printf '%s' "$val" | grep -qiE "$want"; then
        {
            echo "gset: RENDERED STATE DOES NOT MATCH INTENT"
            echo "  page:      [$(ptitle)]"
            echo "  control:   $name — widget ordinal $k, label reads \"$lbl\""
            echo "  intended:  option $item, which must render as /$want/"
            echo "  rendered:  \"$val\""
            [ "$kf" != "$k" ] && echo "  clicked:   widget ordinal $kf, not $k"
            echo "  the page renders these field widgets:"
            printf '%s\n' "$after" | sed 's/^/    /'
        } >&2
        return 1
    fi

    # Nothing else moved. Setting one control and silently moving another is
    # the half of this defect that the config file recorded and the walk did
    # not: `outputDPI` went 1 -> 2 for four months of evidence.
    moved=$(awk -F'\t' -v k="$k" '
        NR == FNR { was[$1] = $3; lab[$1] = $2; next }
        $1 != k && $3 != was[$1] {
            printf "    ordinal %s (%s): was \"%s\", now \"%s\"\n", $1, lab[$1], was[$1], $3
        }' <(printf '%s\n' "$before") <(printf '%s\n' "$after"))
    if [ -n "$moved" ]; then
        {
            echo "gset: SETTING \"$name\" ALSO MOVED CONTROLS IT DOES NOT NAME"
            echo "  page:      [$(ptitle)]"
            echo "  control:   $name — widget ordinal $k, now reads \"$val\" as intended"
            echo "  clicked:   widget ordinal $kf"
            echo "  collateral:"
            printf '%s\n' "$moved"
        } >&2
        return 1
    fi
    return 0
}
