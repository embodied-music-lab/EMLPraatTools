#!/usr/bin/env bash
# ============================================================================
# gui_e2e/run.sh — drive the real workflow through its real dialogs
# ============================================================================
# Brings up its own Xvfb and window manager, runs driver.praat (which sets the
# presets a wrapper sets and calls @emlGraphsWorkflow with a Table id), and
# presses Return at each dialog. Records the TITLE of every dialog it meets,
# in order, to out/DIALOGS.tsv, and saves the figure the run produces.
#
# WHY A GUI HARNESS EXISTS AT ALL. On 11 August 2026 fifteen menu entry points
# were dead at parse time, every figure's title had lost its special
# characters, the Draw branch of every analysis threw away the Table it had
# been handed, and an export dialog painted its OK button over its own output.
# All four were found by installing the plugin and clicking it. None was
# visible to 8259 R checks, 39/39 stress cases, 52/52 disclosure cases,
# 357/357 phase1 assertions or two byte-exact round trips, because every one
# of those exercises the plugin's PARTS and none of them assembles it.
#
# NO SCREEN COORDINATES. Every dialog is dismissed with Return, and Return
# lands on the plugin's own default button, which on this path is the happy
# path: Continue on the main form, Draw on the column mapping, Save on the
# figure. A harness that clicked at pixel positions would break the first
# time a dialog gained a field, and would then be "fixed" by moving numbers
# until it went green -- which is how a check stops meaning anything.
#
# THE ASSERTION IS THE SEQUENCE OF DIALOG TITLES. The workflow is handed a
# Table id; "No Table selected" must not appear, and the run must ADVANCE to
# the column-mapping stage. Asking for an object it was already given is the
# defect this harness was built the day after -- see §2k.
#
# WHERE IT STOPS, AND WHY IT STOPS THERE. At the column-mapping dialog. Going
# deeper means pressing a specific button in each dialog, and Praat's pause
# dialogs are walked with Tab -- which visits every focusable widget, not just
# the buttons, so the count differs with each dialog's field count. That is
# solvable and it is a different piece of work; guessing the counts until a
# run went green would produce a harness that clicks something plausible and
# reports success, which is the failure mode this whole file exists to end.
#
# The figure itself is not left unchecked: harness/determinism, harness/stress
# and v34 all assert on rendered output. What only this harness can see is
# whether the shipped workflow ADVANCES when a wrapper hands it a Table.
#
# Run from anywhere:  bash harness/gui_e2e/run.sh
# Exit 0 = the workflow advanced without asking for what it was given.
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$SCRIPT_DIR/.." && pwd)/_env.sh" || exit 1
OUT="$SCRIPT_DIR/out"
PREFS="$SCRIPT_DIR/prefs"
mkdir -p "$OUT" "$PREFS"
rm -f "$OUT"/*.tsv "$OUT"/*.log "$OUT"/*.png 2>/dev/null

# A display of its own, so a run cannot collide with another agent's rig or
# inherit a half-dead one. 91 rather than 99 for the same reason.
DISP=":91"
XVFB_PID=""
WM_PID=""
PRAAT_PID=""

# Kill by RECORDED PID, never by name. `pkill -f` matches the driving shell's
# own command line and kills it -- exit 144, seen for real (D126). Even
# `pkill -x praat` takes out a stress run another process owns.
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
    echo "gui_e2e: FAIL — no display on $DISP"; exit 1
fi

# Bare Xvfb has no window manager, and without one xdotool cannot activate a
# window and GTK entries never take focus, so typed input goes nowhere.
# DISPLAY MUST BE IN THE ENVIRONMENT HERE. Xvfb takes its display as an
# ARGUMENT; matchbox reads it from DISPLAY and exits 1 with "can't open
# display" if it is unset. The first version of this script omitted it, the
# window manager was silently absent, xdotool's windowactivate failed with
# "Your windowmanager claims not to support _NET_ACTIVE_WINDOW", the dialog
# never took focus, and fourteen Return presses went nowhere -- which read
# as "Praat ignores Return" rather than "there is no window manager".
DISPLAY="$DISP" matchbox-window-manager -use_titlebar no > "$OUT/wm.log" 2>&1 &
WM_PID=$!
sleep 2
if ! kill -0 "$WM_PID" 2>/dev/null; then
    echo "gui_e2e: FAIL — the window manager did not start:"
    sed 's/^/          /' "$OUT/wm.log"
    echo "          Without one, no dialog takes focus and no key reaches it."
    exit 1
fi

# 6.6.30 keeps its instance lock in the pref dir; 7.x keeps it in
# ~/.config/praat regardless of --pref-dir. Both are cleared, because a stale
# lock makes Praat exit with "An instance of Praat that is not me is already
# running" and the run reads as a harness bug rather than a stale file.
rm -f "$PREFS/pid" "$PREFS/message" 2>/dev/null
rm -f "$HOME/.config/praat/pid.txt" "$HOME/.config/praat/Message.txt" 2>/dev/null

( cd "$SCRIPT_DIR" && DISPLAY="$DISP" EML_E2E_OUT="$OUT" \
    "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" --utf8 --new-send driver.praat \
    > "$OUT/driver.log" 2>&1 ) &
PRAAT_PID=$!
sleep 10

TSV="$OUT/DIALOGS.tsv"
: > "$TSV"

# Walk the dialogs. The bound is generous but finite: a workflow that starts
# looping would otherwise hang the suite rather than fail it.
# Bounded, and small: this harness walks two stages, not a whole session. A
# workflow that started looping would otherwise hang the suite rather than
# fail it.
MAXSTEPS=6
step=0
reachedMapping=0
while [[ $step -lt $MAXSTEPS ]]; do
    title=$(DISPLAY="$DISP" xdotool search --onlyvisible --name "^Pause" \
                getwindowname %@ 2>/dev/null | head -1)
    [[ -z "$title" ]] && break
    step=$((step + 1))
    printf '%d\t%s\n' "$step" "${title#Pause: }" >> "$TSV"
    # Column mapping is the goal. Stop here rather than press a button whose
    # index this harness does not reliably know.
    if [[ "$title" == *"Column Mapping"* ]]; then
        reachedMapping=1
        break
    fi
    wid=$(DISPLAY="$DISP" xdotool search --onlyvisible --name "^Pause" | head -1)
    DISPLAY="$DISP" xdotool windowactivate --sync "$wid" 2>/dev/null
    sleep 1

    # WHICH BUTTON, BY NAME, PRESSED WITH TAB AND Return.
    #
    # Two measured facts drive this. Return alone presses BUTTON 1, not the
    # dialog's default button -- the first version of this harness assumed the
    # default and sat on "EML Graphs" fourteen times pressing Undo. And Tab
    # walks the button row exactly: Tab x0 -> button 1, x1 -> 2, x2 -> 3,
    # x3 -> wraps to 1. So Tab x(N-1) then Return presses button N, with no
    # screen coordinates anywhere.
    #
    # The index differs per dialog because Praat prepends an Undo button to
    # any pause that has editable fields. The mapping is written out rather
    # than computed: if a dialog gains a button, this harness clicks the wrong
    # one and the SEQUENCE assertion below fails loudly, which is the outcome
    # wanted. A computed guess would click something plausible and pass.
    tabs=0
    case "$title" in
        *"Column Mapping"*)  tabs=4 ;;   # Undo GoBack Quit Advanced [Draw]
        *"EML Graphs"*)      tabs=2 ;;   # Undo Quit [Continue]
        *"Graph Complete"*)  tabs=1 ;;   # Done [Save] ExpCSV Redraw
        *"Save Figure"*)     tabs=2 ;;   # Undo GoBack [Save]
        *)                   tabs=0 ;;   # unknown: press button 1 and let the
                                         # sequence assertion report it
    esac
    if [[ $tabs -gt 0 ]]; then
        DISPLAY="$DISP" xdotool key --clearmodifiers --repeat "$tabs" Tab 2>/dev/null
        sleep 1
    fi
    # XTEST, not XSendEvent: `xdotool key --window <id>` sends a synthetic
    # event that GTK ignores. Without --window it drives the X test extension
    # and the application cannot tell it from a real keypress.
    DISPLAY="$DISP" xdotool key --clearmodifiers Return 2>/dev/null
    sleep 5
done

echo "dialogs met:"
awk -F'\t' '{printf "  %s. %s\n", $1, $2}' "$TSV"
echo

fail=0

if [[ ! -s "$TSV" ]]; then
    echo "gui_e2e: FAIL — no dialog was ever raised. See out/driver.log."
    exit 1
fi

# THE DEFECT THIS HARNESS WAS BUILT FOR. @emlGraphsWorkflow was handed a Table
# id; a second @emlDetectContext then read the Objects-window selection and
# discarded it, so every wrapper's Draw branch asked the user to pick the
# Table it had just analysed.
if grep -q "No .* selected" "$TSV"; then
    echo "gui_e2e: FAIL — the workflow asked for an object it was handed."
    echo "         That is the defect of §2k: a second @emlDetectContext"
    echo "         discarding the caller's object on the first pass."
    fail=$((fail + 1))
fi

if ! grep -qi "EML Graphs" "$TSV"; then
    echo "gui_e2e: FAIL — the main form never opened"
    fail=$((fail + 1))
fi

if [[ $reachedMapping -eq 0 ]]; then
    echo "gui_e2e: FAIL — never advanced to the column-mapping stage"
    fail=$((fail + 1))
fi

echo
if [[ $fail -eq 0 ]]; then
    echo "gui_e2e: PASS — the workflow advanced to column mapping in $step dialogs"
    echo "         (Praat $("$PRAAT" --version 2>&1 | head -1))"
    exit 0
fi
echo "gui_e2e: FAIL — $fail problem(s). See out/DIALOGS.tsv and out/driver.log."
exit 1
