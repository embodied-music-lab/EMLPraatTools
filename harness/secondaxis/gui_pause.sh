#!/usr/bin/env bash
# ============================================================================
# harness/secondaxis/gui_pause.sh — the second-axis dialogs, photographed
# ============================================================================
# Brings up its own Xvfb and window manager, runs gui_driver.praat, presses
# Return at every dialog, and SCREENSHOTS each one before dismissing it. The
# shape and the rules are harness/gui_e2e/run.sh's -- its header is where they
# are argued; only the two things this run is about are new:
#
#   RUN A (EML_SECOND_COL=5, a text column) is the refusal. The follow-up page
#   comes up, Draw is pressed, the reason is shown, OK is pressed, and THE
#   SAME PAGE COMES BACK with the user's choices still in it. Four
#   photographs, and the third and the fifth are the same dialog.
#
#   RUN B (EML_SECOND_COL=3, the contact quotient) is the same journey with a
#   column that passes, all the way to the figure.
#
# Run from anywhere:  bash harness/secondaxis/gui_pause.sh
# Output: out/gui/<run>_<n>_<title>.png, out/gui/GUIPAUSE.tsv
# Exit 0 = both runs reached the dialogs they were driven to.
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$SCRIPT_DIR/.." && pwd)/_env.sh" || exit 1
# The driver's own relative includes resolve against the folder Praat is
# started from, so this script runs from there. Every path below is absolute.
cd "$SCRIPT_DIR" || exit 1
OUT="$SCRIPT_DIR/out/gui"
PREFS="$SCRIPT_DIR/prefs_gui"
mkdir -p "$OUT" "$PREFS"
rm -f "$OUT"/*.png "$OUT"/*.log "$OUT"/*.tsv 2>/dev/null
TSV="$OUT/GUIPAUSE.tsv"
: > "$TSV"

DISP=":93"
XVFB_PID=""; WM_PID=""; PRAAT_PID=""
# Kill by RECORDED PID, never by name: `pkill -f` matches this shell's own
# command line and kills it (D126), and `pkill -x praat` takes out any other
# Praat on the machine.
cleanup() {
    [[ -n "$PRAAT_PID" ]] && kill -9 "$PRAAT_PID" 2>/dev/null
    [[ -n "$WM_PID"    ]] && kill -9 "$WM_PID"    2>/dev/null
    [[ -n "$XVFB_PID"  ]] && kill -9 "$XVFB_PID"  2>/dev/null
    rm -f "/tmp/.X${DISP#:}-lock" "/tmp/.X11-unix/X${DISP#:}" 2>/dev/null
}
trap cleanup EXIT

rm -f "/tmp/.X${DISP#:}-lock" "/tmp/.X11-unix/X${DISP#:}" 2>/dev/null
Xvfb "$DISP" -screen 0 1400x1000x24 > "$OUT/xvfb.log" 2>&1 &
XVFB_PID=$!
sleep 3
DISPLAY="$DISP" xdpyinfo >/dev/null 2>&1 || { echo "gui_pause: FAIL no display"; exit 1; }
DISPLAY="$DISP" matchbox-window-manager -use_titlebar no > "$OUT/wm.log" 2>&1 &
WM_PID=$!
sleep 2
kill -0 "$WM_PID" 2>/dev/null || { echo "gui_pause: FAIL no window manager"; exit 1; }

# The window lookup walks _NET_CLIENT_LIST rather than `xdotool search`, which
# reads WM_NAME and misses every title with an em dash in it.
pauseinfo () {
    local ids id name
    ids=$(DISPLAY="$DISP" xprop -root _NET_CLIENT_LIST 2>/dev/null \
          | sed -n 's/.*# //p' | tr -d ' ' | tr ',' '\n')
    for id in $ids; do
        [[ "$id" == 0x* ]] || continue
        name=$(DISPLAY="$DISP" xdotool getwindowname "${id}" 2>/dev/null)
        if [[ "$name" == Pause:* ]]; then
            printf '%s\t%s\n' "$id" "${name#Pause: }"; return 0
        fi
    done
    return 1
}

fail=0
drive () {
    local run="$1" col="$2" maxsteps="$3" tick="${4:-yes}" pick="${5:-no}"
    rm -f "$PREFS/pid" "$PREFS/message" 2>/dev/null
    rm -f "$HOME/.config/praat/pid.txt" "$HOME/.config/praat/Message.txt" 2>/dev/null
    rm -f "$PREFS/eml-graphs-config.txt" 2>/dev/null
    local RHOME="$OUT/home_$run"
    rm -rf "$RHOME"; mkdir -p "$RHOME"

    # NOT IN A SUBSHELL, AND THAT IS NOT A STYLE CHOICE. `( ... ) &` makes
    # $! the SUBSHELL's pid; killing it leaves Praat itself running, with its
    # dialogs still on the display. Measured here: the first run's Praat
    # survived its kill, the second run's window lookup found the first run's
    # pause windows, and the two drives interleaved into one nonsense
    # transcript. `env VAR=... praat &` makes $! the process this script has
    # to be able to kill.
    env DISPLAY="$DISP" EML_SECOND_COL="$col" HOME="$RHOME" \
        EML_GUI_FIGURE="$OUT/${run}_figure.png" \
        "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" --utf8 --new-send gui_driver.praat \
        > "$OUT/${run}_driver.log" 2>&1 &
    PRAAT_PID=$!
    sleep 10

    local step=0 line wid title slug
    while [[ $step -lt $maxsteps ]]; do
        line=$(pauseinfo) || break
        wid=${line%%$'\t'*}
        title=${line#*$'\t'}
        step=$((step + 1))
        slug=$(printf '%s' "$title" | tr -c 'A-Za-z0-9' '_' | sed 's/__*/_/g; s/^_//; s/_$//')
        DISPLAY="$DISP" xdotool windowactivate --sync "$wid" 2>/dev/null
        sleep 1
        # THE PHOTOGRAPH IS TAKEN BEFORE THE KEY, so the artefact is the
        # dialog as the user meets it and not as it is leaving.
        DISPLAY="$DISP" import -window "$wid" "$OUT/${run}_$(printf '%02d' $step)_${slug}.png" 2>/dev/null
        printf '%s\t%d\t%s\n' "$run" "$step" "$title" >> "$TSV"
        # THE BUTTON IS COUNTED FROM THE END, harness/tabwalk's law: focus
        # starts at ring position 0, so ONE shift+Tab wraps to the LAST
        # widget, which is the last button, and N presses the Nth from the
        # end -- never entering a field on the way. The forward button is the
        # last one on every page of this journey:
        #
        #   EML Graphs                 Quit Continue                -> 1
        #   Line Chart -- Data Format  GoBack Quit Continue         -> 1
        #   ... Column Mapping         GoBack Quit <toggle> Draw    -> 1
        #   ... Second Dataset ...     GoBack Draw                  -> 1
        #   Second dataset (refusal)   OK                           -> 1
        #   Graph Complete             Done Save Redraw             -> Done 3
        local rev=1
        case "$title" in
            *"Graph Complete"*) rev=3 ;;
        esac
        # THE ONE PLACE A KEY GOES SOMEWHERE OTHER THAN A BUTTON: the tickbox
        # that asks for the second dataset. It is the LAST FIELD on the
        # column-mapping page, so it sits SIX back from the end -- Draw, the
        # Advanced toggle, Quit, Go Back, Praat's own prepended Undo, then the
        # box -- and `space` ticks it. Five lands on Undo: photographed on the
        # first attempt, which is why the button row is counted from a
        # screenshot rather than from the endPause: list alone. The photograph above was taken before this, so a second
        # one is taken after, and it is the evidence that the control is a
        # real control and not a seeded variable.
        #
        # Return then presses the DEFAULT button rather than the focused
        # widget, which is Draw: harness/tabwalk measured that a Return in a
        # checkbox does not toggle it.
        # THE OTHER PLACE A KEY LEAVES THE BUTTON ROW: choosing a different
        # right-hand column on the follow-up page. The combo is the FIRST
        # field, so it is eight back from the end -- Draw, Go Back, Undo, then
        # the line style, the label, the maximum, the minimum, and the combo
        # -- and one Down moves the selection from the seeded column to the
        # next one in the table. The refusal run does not do this, which is
        # how it ends up asking for a column it cannot have.
        if [[ "$title" == *"Second Dataset"* && "$pick" == "yes" ]]; then
            DISPLAY="$DISP" xdotool key --clearmodifiers --repeat 8 shift+Tab 2>/dev/null
            sleep 1
            DISPLAY="$DISP" xdotool key --clearmodifiers Down 2>/dev/null
            sleep 1
            DISPLAY="$DISP" import -window "$wid" "$OUT/${run}_$(printf '%02d' $step)_${slug}_picked.png" 2>/dev/null
            # TWO RETURNS, AND THE FIRST ONE IS NOT THE BUTTON. GTK opens the
            # combo as a grab popup that is not in _NET_CLIENT_LIST, so the
            # first Return closes the popup on the highlighted item and the
            # second presses the dialog's default button, which is Draw.
            # Measured: with one Return the page was photographed three times
            # before the figure appeared.
            DISPLAY="$DISP" xdotool key --clearmodifiers Return 2>/dev/null
            sleep 2
            DISPLAY="$DISP" xdotool key --clearmodifiers Return 2>/dev/null
            sleep 6
            pick=no
            continue
        fi
        if [[ "$title" == *"Column Mapping"* && "$tick" == "yes" ]]; then
            DISPLAY="$DISP" xdotool key --clearmodifiers --repeat 6 shift+Tab 2>/dev/null
            sleep 1
            DISPLAY="$DISP" xdotool key --clearmodifiers space 2>/dev/null
            sleep 1
            DISPLAY="$DISP" import -window "$wid" "$OUT/${run}_$(printf '%02d' $step)_${slug}_ticked.png" 2>/dev/null
            DISPLAY="$DISP" xdotool key --clearmodifiers Return 2>/dev/null
            sleep 5
            continue
        fi
        DISPLAY="$DISP" xdotool key --clearmodifiers --repeat "$rev" shift+Tab 2>/dev/null
        sleep 1
        # XTEST, not XSendEvent: `xdotool key --window <id>` sends a synthetic
        # event GTK ignores.
        DISPLAY="$DISP" xdotool key --clearmodifiers Return 2>/dev/null
        sleep 5
    done
    printf '%s\tsteps\t%d\n' "$run" "$step" >> "$TSV"
    kill -9 "$PRAAT_PID" 2>/dev/null
    PRAAT_PID=""
    # AND WAIT UNTIL THE DISPLAY IS EMPTY AGAIN. A dead process's windows
    # leave _NET_CLIENT_LIST when the server reaps them, not when the kill
    # returns, and the next run's first lookup would otherwise find one.
    local waited=0
    while pauseinfo >/dev/null 2>&1; do
        sleep 1
        waited=$((waited + 1))
        [[ $waited -gt 20 ]] && break
    done
    sleep 2
}

# THE REFUSAL RUN: the tickbox is ticked on the page itself, the follow-up
# page comes up with the column it was left at -- which is the same column the
# left-hand axis is already drawing -- Draw is pressed, the reason is read, OK
# is pressed, and THE SAME PAGE COMES BACK. Six dialogs, of which the fourth
# and the sixth are the same one.
drive refuse 5 6

# THE ACCEPTING RUN: the same journey with one Down press on the follow-up
# page's column menu, which moves it off the primary's column and onto the
# contact quotient. It goes through to the figure, and the figure it saves was
# drawn by the dialogs rather than by a probe setting globals.
drive accept 3 6 yes yes

awk -F"\t" '{printf "%-8s %-6s %s\n", $1, $2, $3}' "$TSV"
[ $fail -eq 0 ] && echo "gui_pause: PASS" && exit 0
echo "gui_pause: FAIL"
exit 1
