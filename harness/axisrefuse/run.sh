#!/usr/bin/env bash
# ============================================================================
# harness/axisrefuse/run.sh — drive the graphs form's axis pairs through the
# real dialogs and record what the form did
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# THE SUBJECT. An axis pair whose maximum is below its minimum is refused: the
# form puts the conflict on screen, draws nothing, and comes back. This rig
# submits such a pair on every axis the form has, through the field whose
# label the refusal quotes, and records three things per leg — the sequence of
# dialog titles the form actually showed, the text the refusal actually
# displayed, and whether there was ink in the Picture window at the moment of
# the refusal.
#
# WHY IT DRIVES THE GUI RATHER THAN CALLING THE PROCEDURES. The refusal is not
# a value a procedure returns; it is a dialog that appears INSTEAD OF a
# figure, and the thing under test is the "instead of". A probe that called
# @emlGraphsCheckAxisRanges and then decided for itself whether to draw would
# be testing its own decision. Every dialog below is the shipped form's, and
# the only thing this file supplies is keystrokes.
#
# THE FIELD IS ADDRESSED BY TAB COUNT FROM THE PAGE'S FIRST WIDGET, and the
# counts are listed against the source beside each leg. A wrong count is not a
# silent pass: the refusal quotes the label of the pair it refused, so typing
# into the wrong field either produces a refusal naming a different axis or
# produces no refusal at all, and either one moves the recorded transcript
# away from what the validator asserts.
#
# THE INK MEASURE IS THE FRACTION OF DARK PIXELS in the Praat Picture window.
# A COMPOSITOR IS REQUIRED for it to mean anything: without one, the region a
# dialog covers is not repainted and comes back from XGetImage as a black
# rectangle, which reads as a figure. xcompmgr redirects each window to its
# own pixmap, so the Picture window's own content is what is captured whatever
# is on top of it. The empty-window reading is recorded per leg rather than
# assumed, so the validator compares a refusal against that leg's own baseline
# rather than against a number written down here.
#
# Run from anywhere:  bash harness/axisrefuse/run.sh
# Output: harness/axisrefuse/out/AXISREFUSE.tsv   read by validate/v84
#         harness/axisrefuse/out/<leg>_s<n>.png   every dialog, as shown
#
# $EML_AR_SRC points the legs at a DIFFERENT COPY of the repository, which is
# how validate/v84's break tests drive a deliberately broken form without
# touching the working tree. break.sh builds those copies.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
#            https://github.com/embodied-music-lab/PraatGen
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$SCRIPT_DIR/.." && pwd)/_env.sh" || exit 1

SRC="${EML_AR_SRC:-$EML_ROOT}"
OUT="${EML_AR_OUTDIR:-$SCRIPT_DIR/out}"
DRIVE="$SRC/harness/axisrefuse/drive.praat"
DISP="${EML_AR_DISPLAY:-:86}"

mkdir -p "$OUT"
rm -f "$OUT"/*.png "$OUT"/*.log "$OUT"/*.txt 2>/dev/null
TSV="$OUT/AXISREFUSE.tsv"
: > "$TSV"

emit () { printf '%s\t%s\n' "$1" "$2" >> "$TSV"; }

emit "praat_version" "$("$PRAAT" --version 2>&1 | head -1)"
emit "source_tree" "$SRC"

# ---------------------------------------------------------------------------
# THE STALENESS BINDING. The digest of the form's CODE — comment lines
# dropped, in Praat's comment set — as it was when these legs were driven.
# validate/v84 recomputes it from the working tree and refuses a transcript
# taken from a different form. Comments are dropped so that rewrapping a
# paragraph does not demand a GUI re-drive; a trailing `; ...` after a
# statement is left alone, which keeps the statement in the digest.
# ---------------------------------------------------------------------------
FORM="$SRC/plugin/graphs/eml-graphs-form.praat"
emit "form_code_sha256" \
    "$(sed -E '/^[[:space:]]*(#|;|!)/d' "$FORM" | sha256sum | cut -d' ' -f1)"

# ---------------------------------------------------------------------------
# DISPLAY, WINDOW MANAGER, COMPOSITOR.
#
# Killed by RECORDED PID and never by name: `pkill -f` matches the driving
# shell's own command line and kills it (D126), and even `pkill -x praat`
# takes out a run some other harness owns.
# ---------------------------------------------------------------------------
XVFB_PID=""; WM_PID=""; XC_PID=""; PRAAT_PID=""
cleanup () {
    [[ -n "$PRAAT_PID" ]] && kill -9 "$PRAAT_PID" 2>/dev/null
    [[ -n "$XC_PID"    ]] && kill -9 "$XC_PID"    2>/dev/null
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
    echo "axisrefuse: FAIL — no display on $DISP"; exit 1
fi

# Without a window manager xdotool cannot activate a window, no dialog takes
# focus, and every keystroke goes nowhere — which reads as "the form ignores
# Return" rather than "there is no window manager". GUI_HARNESS_RECIPE §1.
DISPLAY="$DISP" matchbox-window-manager -use_titlebar no > "$OUT/wm.log" 2>&1 &
WM_PID=$!
sleep 2
if ! kill -0 "$WM_PID" 2>/dev/null; then
    echo "axisrefuse: FAIL — the window manager did not start:"
    sed 's/^/          /' "$OUT/wm.log"; exit 1
fi

DISPLAY="$DISP" xcompmgr > "$OUT/xc.log" 2>&1 &
XC_PID=$!
sleep 2
emit "compositor" "$(kill -0 "$XC_PID" 2>/dev/null && echo running || echo absent)"

# ---------------------------------------------------------------------------
# WINDOW LOOKUP WALKS _NET_CLIENT_LIST, not `xdotool search`, which matches
# WM_NAME (unset for any non-Latin-1 title) and returns the unmapped husk of
# every dismissed pause dialog forever. GUI_HARNESS_RECIPE §11.
# ---------------------------------------------------------------------------
winlist () {
    DISPLAY="$DISP" xprop -root _NET_CLIENT_LIST 2>/dev/null \
        | sed -n 's/.*# //p' | tr -d ' ' | tr ',' '\n'
}
pausewin () {
    local id name
    for id in $(winlist); do
        [[ "$id" == 0x* ]] || continue
        name=$(DISPLAY="$DISP" xdotool getwindowname "$id" 2>/dev/null)
        if [[ "$name" == Pause:* ]]; then
            printf '%s\t%s\n' "$id" "${name#Pause: }"; return 0
        fi
    done
    return 1
}
namedwin () {
    local id name
    for id in $(winlist); do
        [[ "$id" == 0x* ]] || continue
        name=$(DISPLAY="$DISP" xdotool getwindowname "$id" 2>/dev/null)
        [[ "$name" == "$1" ]] && { printf '%s\n' "$id"; return 0; }
    done
    return 1
}
# Wait for a pause window whose title differs from the one just dismissed.
# Praat leaves the old window in the tree for a moment, so "a pause window
# exists" is not the same question as "the next dialog is up".
waitpause () {
    local prev="$1" i line
    for ((i = 0; i < 40; i++)); do
        line=$(pausewin) && {
            [[ "${line#*$'\t'}" != "$prev" ]] && { printf '%s\n' "$line"; return 0; }
        }
        sleep 0.5
    done
    return 1
}

# THE INK MEASURE. Fraction of pixels below mid-grey in the Picture window.
ink () {
    local w
    w=$(namedwin "Praat Picture") || { echo "NA"; return; }
    DISPLAY="$DISP" import -window "$w" "$OUT/_ink.png" 2>/dev/null || {
        echo "NA"; return; }
    convert "$OUT/_ink.png" -colorspace gray -threshold 50% \
        -format "%[fx:1-mean]" info: 2>/dev/null || echo "NA"
}

# THE TEXT A DIALOG ACTUALLY DISPLAYED, read off the pixels it displayed it
# in. Upscaled and greyed before tesseract because a 12 px GTK label at 1:1 is
# below the recogniser's comfortable size; --psm 6 treats the crop as a
# uniform block of text, which is what a column of comment labels is.
dialog_text () {
    local wid="$1" tag="$2"
    DISPLAY="$DISP" import -window "$wid" "$OUT/${tag}.png" 2>/dev/null || return 1
    convert "$OUT/${tag}.png" -colorspace gray -resize 300% -sharpen 0x1 \
        "$OUT/_ocr.png" 2>/dev/null || return 1
    tesseract "$OUT/_ocr.png" stdout --psm 6 2>/dev/null \
        | tr -s ' ' | sed 's/[[:space:]]*$//' | grep -v '^$'
}

# ---------------------------------------------------------------------------
# THE LEGS.
#
# A plan is a list of steps, one per dialog, in the order the form shows them:
#
#     <expected title>|<action>,<action>,...
#
#     tab<N>=<text>   activate the window (which returns focus to the page's
#                     first widget), press Tab N times, select all, type
#     ocr             record the text this dialog is displaying
#     ink             record the Picture window's dark fraction
#     btn<N>          press the Nth button FROM THE END: focus starts at ring
#                     position 0, so N shift+Tabs reach it without entering a
#                     field on the way (harness/tabwalk measured this law)
#
# The expected title is written down so a divergence is visible in the
# transcript; the harness records the title it ACTUALLY met and executes the
# step's actions regardless, so a form that shows the wrong dialog produces a
# wrong transcript rather than a hung run.
#
# FIELD ORDER, read off plugin/graphs/eml-graphs-form.praat:
#
#   EVERY RANGE IS ONE ROW OF TWO BOXES, and the tab ring visits the LEFT box
#   then the RIGHT one -- so a pair is always (minimum, maximum) in that
#   order, whatever order the two used to be stacked in. The second pair on
#   the acoustic pages used to be stacked maximum-above-minimum, which is why
#   these indices read as though two of them are swapped against the older
#   note: they are, and the pairing is what swapped them.
#
#   Pitch Contour Settings (Sound source, so the pitch fields are present)
#     0 Time minimum  1 Time maximum  2 Frequency minimum  3 Frequency maximum
#     4 Y axis unit   5 Pitch floor   6 Pitch ceiling
#   Waveform Settings
#     0 Time minimum  1 Time maximum  2 Amplitude minimum  3 Amplitude maximum
#   Spectrum Settings
#     0 Frequency minimum  1 Frequency maximum  2 Power minimum
#     3 Power maximum
#   Box Plot -- Column Mapping, ADVANCED, parametric (so the adjustment
#   optionmenu is a comment rather than a field)
#     0 Value column  1 Group column  2 Group order  3 Annotate
#     4 Test type     5 Significance style  6 Show nonsignificant
#     7 Show effect sizes  8 Annotation layout  9 Alpha
#     10 Show jittered points  11 Value minimum  12 Value maximum
#   Scatter Plot -- Column Mapping, ADVANCED, no group column
#     0 X column  1 Y column  2 Use group column  3 Correlation method
#     4 Regression  5 Significance style  6 Show data points  7 Dot size
#     8 X minimum  9 X maximum  10 Y minimum  11 Y maximum
#
# BUTTON ROWS: the type pages are Go Back / Quit / <toggle> / Draw, so Draw is
# btn1. The main form is Quit / Continue, so Continue is btn1. The refusal is
# OK alone, btn1. The post-draw dialog is Done / Save / Redraw, so Done is
# btn3 and Redraw is btn1.
# ---------------------------------------------------------------------------
LEGS="${EML_AR_LEGS:-pitch_time pitch_freq wave_amp spec_power box_value scatter_xy box_bound}"

plan_of () {
case "$1" in
  # A FLOOR ON TIME. Minimum 0.3 with the maximum left at its 0 default: the
  # pair a user asking for a floor submits, and the pair a user who typed the
  # two numbers the wrong way round submits. Corrected to 0.3 .. 0.8.
  pitch_time) cat <<'PLAN'
EML Graphs|btn1
Pitch Contour Settings|tab0=0.3,btn1
Axis range|ocr,ink,btn1
EML Graphs|btn1
Pitch Contour Settings|tab1=0.8,btn1
Graph Complete|ink,btn3
PLAN
  ;;
  # THE SAME PAGE, THE OTHER PAIR. Frequency minimum 300, maximum 0.
  pitch_freq) cat <<'PLAN'
EML Graphs|btn1
Pitch Contour Settings|tab2=300,btn1
Axis range|ocr,ink,btn1
EML Graphs|btn1
Pitch Contour Settings|tab3=500,btn1
Graph Complete|ink,btn3
PLAN
  ;;
  wave_amp) cat <<'PLAN'
EML Graphs|btn1
Waveform Settings|tab2=0.2,btn1
Axis range|ocr,ink,btn1
EML Graphs|btn1
Waveform Settings|tab3=0.9,btn1
Graph Complete|ink,btn3
PLAN
  ;;
  spec_power) cat <<'PLAN'
EML Graphs|btn1
Spectrum Settings|tab2=20,btn1
Axis range|ocr,ink,btn1
EML Graphs|btn1
Spectrum Settings|tab3=60,btn1
Graph Complete|ink,btn3
PLAN
  ;;
  box_value) cat <<'PLAN'
EML Graphs|btn1
Box Plot -- Column Mapping|tab11=300,btn1
Axis range|ocr,ink,btn1
EML Graphs|btn1
Box Plot -- Column Mapping|tab12=400,btn1
Graph Complete|ink,btn3
PLAN
  ;;
  # BOTH PAIRS ON ONE PAGE, REVERSED TOGETHER. The scatter is the only page
  # with two, it is the page that labels the value pair "Y", and a page with
  # two conflicts must name both at once rather than one per round trip.
  scatter_xy) cat <<'PLAN'
EML Graphs|btn1
Scatter Plot -- Column Mapping|tab8=300,tab10=5,btn1
Axis range|ocr,ink,btn1
EML Graphs|btn1
Scatter Plot -- Column Mapping|tab9=400,tab11=400,btn1
Graph Complete|ink,btn3
PLAN
  ;;
  # THE CONTROL, AND IT IS NOT A FORMALITY. 0 is the auto sentinel AND a
  # legitimate bound, so this leg draws twice with no refusal in between:
  # once on (0, 0), which is auto, and once on (0, 400), which is the full
  # range from zero to four hundred. A "fix" that read 0 as absent would
  # refuse the second one.
  box_bound) cat <<'PLAN'
EML Graphs|btn1
Box Plot -- Column Mapping|btn1
Graph Complete|ink,btn1
EML Graphs|btn1
Box Plot -- Column Mapping|tab12=400,btn1
Graph Complete|ink,btn3
PLAN
  ;;
esac
}

# Advanced mode is a saved preference, not a dialog default, so the legs whose
# pair lives on an advanced page get a config file that says so. Written per
# leg into that leg's own preferences folder.
advanced_of () {
    case "$1" in box_value|scatter_xy|box_bound) echo 1 ;; *) echo 0 ;; esac
}

run_leg () {
    local leg="$1" prefs="$OUT/prefs_$leg" home="$OUT/home_$leg"
    rm -rf "$prefs" "$home"; mkdir -p "$prefs" "$home"
    printf 'showAdvanced: %s\n' "$(advanced_of "$leg")" \
        > "$prefs/eml-graphs-config.txt"
    rm -f "$prefs/pid" "$prefs/message" 2>/dev/null

    emit "leg" "$leg"
    # `exec env` AND NOT A PLAIN SUBSHELL. Without exec, $! is the SUBSHELL's
    # pid; killing it leaves Praat running, its windows on the display, and
    # the next leg reading the previous leg's Picture window as its own empty
    # baseline. That produced a transcript in which every leg's ink was equal
    # to every other leg's and the ink check could not fail.
    ( cd "$SCRIPT_DIR" && exec env DISPLAY="$DISP" HOME="$home" \
        EML_AR_LEG="$leg" EML_AR_OUT="$TSV" \
        "$PRAAT" $PRAAT_TRUST --pref-dir="$prefs" --utf8 --new-send "$DRIVE" \
        > "$OUT/$leg.log" 2>&1 ) &
    PRAAT_PID=$!
    sleep 9

    emit "${leg}_ink_empty" "$(ink)"

    local n=0 prev="" line wid title step want acts act
    while IFS= read -r step; do
        n=$((n + 1))
        want="${step%%|*}"
        acts="${step#*|}"
        line=$(waitpause "$prev") || {
            emit "${leg}_s${n}_title" "<none>"
            emit "${leg}_s${n}_want" "$want"
            break
        }
        wid="${line%%$'\t'*}"
        title="${line#*$'\t'}"
        emit "${leg}_s${n}_title" "$title"
        emit "${leg}_s${n}_want" "$want"
        DISPLAY="$DISP" import -window "$wid" "$OUT/${leg}_s${n}.png" 2>/dev/null

        # FOCUS IS TRACKED, NOT RE-ESTABLISHED. Activating a window that is
        # already active raises no focus event, so a second `tab<N>` in one
        # step does NOT start from widget 0 — it starts wherever the first one
        # left the caret. Counting from a position this loop knows is exact;
        # re-activating and hoping is what left the scatter's Y minimum at 0
        # while its X minimum took the value, on a page where the refusal then
        # named one pair instead of two. `pos` is the widget the caret is on,
        # 0 at the top of every step, and both actions move relative to it.
        DISPLAY="$DISP" xdotool windowactivate --sync "$wid" 2>/dev/null
        DISPLAY="$DISP" xdotool windowfocus "$wid" 2>/dev/null
        sleep 1
        local pos=0
        IFS=',' read -ra act <<< "$acts"
        local a
        for a in "${act[@]}"; do
            case "$a" in
              tab*=*)
                local nt="${a%%=*}"; nt="${nt#tab}"
                local txt="${a#*=}"
                local step_fwd=$(( nt - pos ))
                [[ "$step_fwd" -gt 0 ]] && \
                    DISPLAY="$DISP" xdotool key --clearmodifiers --repeat "$step_fwd" Tab
                pos="$nt"
                sleep 1
                DISPLAY="$DISP" xdotool key --clearmodifiers ctrl+a
                DISPLAY="$DISP" xdotool type --clearmodifiers --delay 60 "$txt"
                sleep 1
                DISPLAY="$DISP" import -window "$wid" \
                    "$OUT/${leg}_s${n}_typed.png" 2>/dev/null
                ;;
              ocr)
                dialog_text "$wid" "${leg}_s${n}_shown" \
                    > "$OUT/${leg}_s${n}_shown.txt"
                while IFS= read -r l; do
                    emit "${leg}_s${n}_shown" "$l"
                done < "$OUT/${leg}_s${n}_shown.txt"
                ;;
              ink)
                emit "${leg}_s${n}_ink" "$(ink)"
                ;;
              btn*)
                # THE Nth BUTTON FROM THE END, FROM WHEREVER THE CARET IS.
                # Walking back N from ring position 0 reaches it; walking back
                # pos + N from position `pos` reaches the same widget, because
                # the ring wraps. Never Return on a field: Praat presses the
                # DEFAULT button then, not the focused one, so a wrong count
                # would not fail — it would silently press something else.
                local nb="${a#btn}"
                local back=$(( pos + nb ))
                DISPLAY="$DISP" xdotool key --clearmodifiers --repeat "$back" shift+Tab
                pos=0
                sleep 1
                DISPLAY="$DISP" xdotool key --clearmodifiers Return
                sleep 3
                ;;
            esac
        done
        prev="$title"
    done < <(plan_of "$leg")

    emit "${leg}_steps" "$n"
    # PRESSING Done ENDS THE SCRIPT AND --new-send ENDS PRAAT WITH IT, but the
    # process takes a moment to go. Recorded either way; the validator reads
    # leg_returned for whether the workflow finished, which is the question.
    local i
    for ((i = 0; i < 10; i++)); do
        kill -0 "$PRAAT_PID" 2>/dev/null || break
        sleep 1
    done
    if kill -0 "$PRAAT_PID" 2>/dev/null; then
        emit "${leg}_exited" "no"
        kill -9 "$PRAAT_PID" 2>/dev/null
    else
        emit "${leg}_exited" "yes"
    fi
    PRAAT_PID=""
    # THE NEXT LEG MUST NOT MEET THIS LEG'S WINDOWS. A stale pause window on
    # the shared display is indistinguishable from the next leg's first
    # dialog, and the next leg would then type into a dead form and hang —
    # which reads as a defect in the form rather than as a dirty display.
    for ((i = 0; i < 30; i++)); do
        [[ -z "$(winlist | tr -d '[:space:]')" ]] && break
        sleep 1
    done
    emit "${leg}_display_clear" \
        "$([[ -z "$(winlist | tr -d '[:space:]')" ]] && echo yes || echo no)"
    # THE SCRATCH PREFERENCE AND HOME FOLDERS GO. They exist only so a leg
    # cannot inherit, or disturb, anyone's Praat preferences; nothing reads
    # them afterwards and a committed one is a running Praat's state in
    # version control.
    rm -rf "$prefs" "$home"
}

for leg in $LEGS; do
    run_leg "$leg"
done

emit "leg" "--shell--"
emit "legs_driven" "$(echo $LEGS | wc -w)"
rm -f "$OUT/_ink.png" "$OUT/_ocr.png"
echo "axisrefuse: wrote $TSV ($(wc -l < "$TSV") lines)"
