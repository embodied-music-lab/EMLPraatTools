#!/usr/bin/env bash
# ============================================================================
# tabwalk/run.sh — measure where Tab goes in a Praat pause dialog
# ============================================================================
# harness/gui_e2e/run.sh states two incompatible laws for this and measures
# neither: its header says Tab "visits every focusable widget, not just the
# buttons", its case table says Tab "walks the button row exactly". The four
# tab counts written into that table have never been exercised, because the
# harness stops before reaching a dialog that needs one. This settles it.
#
# ONE DIALOG PER PRESS. Each k in the sweep gets a fresh dialog: a press that
# lands on Revert leaves the dialog open, a press that lands on a button
# closes it, so a single instance can answer for exactly one k.
#
# THE TWO OUTCOMES ARE BOTH DATA. CLOSED with a clicked value says the press
# reached button <n>. NOCLOSE says the press reached a widget that does not
# dismiss -- which on a Praat pause form means Revert, and Revert existing is
# the whole reason the counts differ between dialogs.
#
# Run from anywhere:  bash harness/tabwalk/run.sh
# Exit 0 = every case in the sweep was driven and recorded.
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$SCRIPT_DIR/.." && pwd)/_env.sh" || exit 1
OUT="${EML_TABWALK_DIR:-$SCRIPT_DIR/out}"
PREFS="$SCRIPT_DIR/prefs"
mkdir -p "$OUT" "$PREFS"
RAW="$OUT/RAW.txt"
TSV="$OUT/TABWALK.tsv"
rm -f "$RAW" "$TSV" "$OUT"/*.log 2>/dev/null

# A display of its own. 92, because gui_e2e owns 91 and a shared display
# means one run's stray Return lands in the other run's dialog.
DISP=":92"
XVFB_PID=""; WM_PID=""; PRAAT_PID=""

# Kill by RECORDED PID, never by name. `pkill -f` matches the driving shell's
# own command line and kills it -- exit 144, seen for real (D126). Even
# `pkill -x praat` takes out a run another process owns.
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
if ! DISPLAY="$DISP" xdpyinfo >/dev/null 2>&1; then
    echo "tabwalk: FAIL — no display on $DISP"; exit 1
fi

# Without a window manager xdotool cannot activate a window, no dialog takes
# focus, and every keystroke goes nowhere -- which reads as "Praat ignores
# Tab" rather than "there is no window manager". See GUI_HARNESS_RECIPE §1.
DISPLAY="$DISP" matchbox-window-manager -use_titlebar no > "$OUT/wm.log" 2>&1 &
WM_PID=$!
sleep 2
if ! kill -0 "$WM_PID" 2>/dev/null; then
    echo "tabwalk: FAIL — the window manager did not start:"
    sed 's/^/          /' "$OUT/wm.log"
    exit 1
fi

# A stale lock makes Praat exit with "An instance of Praat that is not me is
# already running", which reads as a harness bug. Only these two files --
# never the whole pref dir, the plugin lives in it.
rm -f "$PREFS/pid" "$PREFS/message" 2>/dev/null
rm -f "$HOME/.config/praat/pid.txt" "$HOME/.config/praat/Message.txt" 2>/dev/null

( cd "$SCRIPT_DIR" && DISPLAY="$DISP" EML_TABWALK_OUT="$RAW" \
    "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" --utf8 --new-send case.praat \
    > "$OUT/driver.log" 2>&1 ) &
PRAAT_PID=$!
sleep 8

# WINDOW LOOKUP WALKS _NET_CLIENT_LIST, not `xdotool search`. search matches
# WM_NAME, which GTK sets only for a Latin-1 title, and it returns the
# unmapped husk of every dismissed pause dialog forever. The WM's own list of
# managed top-levels has neither problem. GUI_HARNESS_RECIPE §11.
pausetitle () {
    local ids id name
    ids=$(DISPLAY="$DISP" xprop -root _NET_CLIENT_LIST 2>/dev/null \
          | sed -n 's/.*# //p' | tr -d ' ' | tr ',' '\n')
    for id in $ids; do
        [[ "$id" == 0x* ]] || continue
        name=$(DISPLAY="$DISP" xdotool getwindowname "${id}" 2>/dev/null)
        # Praat titles every pause window "Pause: <title>". The prefix is
        # stripped here so the rest of this file reads the case id directly.
        if [[ "$name" == *TABWALK* ]]; then
            printf '%s\t%s\n' "$id" "${name#Pause: }"; return 0
        fi
    done
    return 1
}

# A WINDOW THAT IS NOT PRAAT'S OWN AND NOT THE PAUSE FORM. Return on a
# `folder:` field opens a GTK "Choose folder" chooser, which is modal: the
# pause form stays up and every later key goes to the chooser, not to the
# dialog. The first version of this sweep read that as NOCLOSE and then spent
# eight recovery presses driving a file browser -- so the chooser is detected
# and named rather than being allowed to look like a Revert press.
childwin () {
    local ids id name
    ids=$(DISPLAY="$DISP" xprop -root _NET_CLIENT_LIST 2>/dev/null \
          | sed -n 's/.*# //p' | tr -d ' ' | tr ',' '\n')
    for id in $ids; do
        [[ "$id" == 0x* ]] || continue
        name=$(DISPLAY="$DISP" xdotool getwindowname "${id}" 2>/dev/null)
        case "$name" in
            "Praat Objects"|"Praat Picture"|"Praat Info"|*TABWALK*|"") ;;
            *) printf '%s\n' "$name"; return 0 ;;
        esac
    done
    return 1
}

: > "$TSV"
MAXSTEPS=60
step=0
while [[ $step -lt $MAXSTEPS ]]; do
    line=$(pausetitle) || break
    wid=${line%%$'\t'*}
    title=${line#*$'\t'}
    id=${title#TABWALK }
    step=$((step + 1))
    # `_k<n>` walks forward with Tab, `_r<n>` backward with shift+Tab. The
    # reverse walk is the one the real workflow needs: focus starts at ring
    # position 0, so one shift+Tab reaches the LAST button without passing
    # through a single field.
    if [[ "$id" == *_r* ]]; then walkkey="shift+Tab"; k=${id##*_r}
    else                         walkkey="Tab";       k=${id##*_k}
    fi

    DISPLAY="$DISP" xdotool windowactivate --sync "$wid" 2>/dev/null
    sleep 1
    if [[ "$k" -gt 0 ]]; then
        DISPLAY="$DISP" xdotool key --clearmodifiers --repeat "$k" "$walkkey" 2>/dev/null
        sleep 1
    fi
    # XTEST, not XSendEvent: `xdotool key --window <id>` sends a synthetic
    # event GTK ignores. Without --window it drives the X test extension and
    # the application cannot tell it from a real keypress.
    DISPLAY="$DISP" xdotool key --clearmodifiers Return 2>/dev/null
    sleep 2

    detail="-"
    child=$(childwin) || child=""
    now=$(pausetitle 2>/dev/null | cut -f2-)
    if [[ -n "$child" ]]; then
        outcome="CHOOSER"
        detail="$child"
    elif [[ "$now" == "$title" ]]; then
        outcome="NOCLOSE"
    else
        outcome="CLOSED"
    fi

    # RECOVERY, so the sweep continues to the next case. Escape first, which
    # dismisses a chooser without choosing anything; then one extra Tab at a
    # time. Praat writes a RESULT line for whichever press finally closes the
    # dialog, so the validator ignores the clicked value of every case whose
    # outcome is not CLOSED and asserts on the outcome instead.
    if [[ "$outcome" != "CLOSED" ]]; then
        # THE TAB COUNT GROWS, and re-activating the window resets focus to
        # widget 0 first. A recovery that pressed Tab ONCE each round looked
        # right and never terminated on the folder2 shape: Escape returns
        # focus to widget 0, one Tab reaches the folder entry, and Return in
        # that entry re-opens the chooser -- the same three keys forever.
        # Sweeping j upward walks past the widget that traps, whatever it is.
        for j in 1 2 3 4 5 6 7 8 9 10 11 12; do
            if childwin >/dev/null; then
                DISPLAY="$DISP" xdotool key --clearmodifiers Escape 2>/dev/null
                sleep 1
            fi
            DISPLAY="$DISP" xdotool windowactivate --sync "$wid" 2>/dev/null
            DISPLAY="$DISP" xdotool key --clearmodifiers --repeat "$j" Tab 2>/dev/null
            DISPLAY="$DISP" xdotool key --clearmodifiers Return 2>/dev/null
            sleep 1
            now=$(pausetitle 2>/dev/null | cut -f2-)
            [[ "$now" != "$title" ]] && break
        done
        # LAST RESORT, AND IT IS THE ONE THAT WORKS ON folder2. Escape on a
        # pause form presses button 1; Escape on the chooser dismisses it
        # without choosing. Measured 13 Aug 2026: on the folder shape the Tab
        # sweep above never terminates, because focus resets to widget 0 on
        # re-activation and one Tab lands back on the folder entry, whose
        # Return re-opens the chooser. Two Escapes clear both.
        now=$(pausetitle 2>/dev/null | cut -f2-)
        if [[ "$now" == "$title" ]]; then
            if childwin >/dev/null; then
                DISPLAY="$DISP" xdotool key --clearmodifiers Escape 2>/dev/null
                sleep 1
            fi
            DISPLAY="$DISP" xdotool windowactivate --sync "$wid" 2>/dev/null
            DISPLAY="$DISP" xdotool key --clearmodifiers Escape 2>/dev/null
            sleep 2
        fi
    fi
    printf '%s\t%s\t%s\t%s\n' "$id" "$k" "$outcome" "$detail" >> "$TSV"

    # A case that could not be got past would otherwise burn the step bound
    # and fill the artefact with copies of itself -- which is what a stuck
    # walk looked like before the growing recovery above.
    if [[ "${lastid:-}" == "$id" ]]; then
        echo "tabwalk: FAIL — stuck on $id; recovery never dismissed it"
        break
    fi
    lastid="$id"
done

# Join the shell's outcome to Praat's own clicked value, keyed on the case id.
JOINED="$OUT/TABWALK_JOINED.tsv"
awk -F'\t' '
    FNR == NR {
        if ($0 ~ /^RESULT /) {
            split($0, a, " ")
            id = a[2]
            sub(/^clicked=/, "", a[3])
            if (!(id in seen)) { clicked[id] = a[3]; seen[id] = 1 }
        }
        next
    }
    { printf "%s\t%s\t%s\t%s\t%s\n", $1, $2, $3, $4, ($3 == "CLOSED" && ($1 in clicked) ? clicked[$1] : "NA") }
' "$RAW" "$TSV" > "$JOINED"

printf '%-17s %-3s %-8s %-15s %s\n' case k outcome detail clicked
awk -F'\t' '{printf "%-17s %-3s %-8s %-15s %s\n", $1, $2, $3, $4, $5}' "$JOINED"
echo

nCases=$(wc -l < "$JOINED")
fail=0
[[ "$nCases" -eq 44 ]] || { echo "FAIL: expected 44 cases, got $nCases"; fail=1; }
grep -q "^TABWALK DONE$" "$RAW" \
    || { echo "FAIL: the driver did not finish — see $OUT/driver.log"; fail=1; }
# A sweep in which nothing ever closed, or everything closed, measured
# nothing: the first means no key reached the dialog, the second means Tab
# was never the variable.
awk -F'\t' '$3 == "CLOSED"' "$JOINED" | grep -q . \
    || { echo "FAIL: no press ever closed a dialog — no key is reaching it"; fail=1; }

if [[ $fail -eq 0 ]]; then
    echo "tabwalk: PASS — $nCases cases driven"
    exit 0
fi
exit 1
