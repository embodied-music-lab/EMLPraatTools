#!/usr/bin/env bash
# ============================================================================
# harness/graphaxes/stereo.sh — is the stereo channel choice REACHABLE?
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# WHY THIS HARNESS EXISTS, and it is the whole point of the ruling it serves.
#
# @emlHandleStereo, @emlCheckChannels and @emlApplyChannelChoice have been in
# graphs/eml-graph-procedures.praat since v3.18. They are correct. They are
# documented. They have unit-shaped behaviour anyone could read off the page.
# And until 15 August 2026 NOTHING CALLED THEM — not the graphs form, not the
# conversion procedure, not a wrapper, not a harness. A static check that the
# three procedures exist would have been green every single day of that, which
# is exactly why existence is not what this harness measures.
#
# It measures whether a stereo Sound can reach a figure WITHOUT being asked.
# The verdict is a window: a Praat pause dialog either appears on the display
# before the figure's object is made, or it does not. Delete the call site and
# the dialog stops appearing while every other check in the tree stays green —
# which is the failure this file is built to catch, and is what the break test
# in validate/v62 does on purpose.
#
# THE FIXTURE IS CHOSEN SO THE WRONG ANSWER IS UNMISTAKABLE. 220 Hz in the
# left channel and 330 Hz in the right. Praat's silent mixdown of those two
# has a fundamental of 110 Hz — an F0 present in NEITHER channel and in
# nothing anybody sang. A pitch track near 110 is the defect with a number on
# it; 220 or 330 is a channel a user chose.
#
# DISPLAY :94, AND WHY IT IS WRITTEN DOWN. Other harnesses in this tree hold
# :88 (savepaths) and :91, and a wave of agents on 14 August killed each
# other's X servers and each other's Praat processes with broad pkills. The
# cleanup here kills exactly one Xvfb — the one whose pid this script started
# — and uses `pkill -9 -x praat`, never `-f`, which matches this script's own
# command line through the driving shell and takes the run down with it.
#
# Run from anywhere:  bash harness/graphaxes/stereo.sh
# Output: harness/graphaxes/out/STEREO.tsv     read by validate/v62
#         harness/graphaxes/out/shots/*.png    the dialog, as it appeared
# Exit 0 = every leg completed.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$SCRIPT_DIR/.." && pwd)/_env.sh" || exit 1
# $EML_STEREO_OUTDIR and $EML_STEREO_DRIVE let validate/v62's break tests
# drive a deliberately damaged copy of the library into a scratch TSV without
# touching this tree. Same shape as harness/graphaxes/axes.sh.
OUT="${EML_STEREO_OUTDIR:-$SCRIPT_DIR/out}"
SHOTS="$OUT/shots"
DRIVE="${EML_STEREO_DRIVE:-$SCRIPT_DIR/stereo_drive.praat}"
PREFS="$SCRIPT_DIR/prefs_stereo"

command -v xdotool >/dev/null || { echo "stereo: FAIL — no xdotool"; exit 1; }
command -v Xvfb    >/dev/null || { echo "stereo: FAIL — no Xvfb";    exit 1; }
command -v xprop   >/dev/null || { echo "stereo: FAIL — no xprop";   exit 1; }
command -v import  >/dev/null || { echo "stereo: FAIL — no import";  exit 1; }

rm -rf "$PREFS"
mkdir -p "$OUT" "$SHOTS" "$PREFS"
TSV="$OUT/STEREO.tsv"
: > "$TSV"

# A DISPLAY NOBODY ELSE IS ON, CHOSEN AT RUN TIME AND WRITTEN DOWN. A fixed
# number is a collision waiting to happen: :88 is savepaths, :90 and :91 were
# live while this was written, and on the first run of this harness a fixed
# :94 was ALSO bound by another instance -- so `pausewin` found that
# instance's "Violin Plot -- Column Mapping" and this script pressed Return
# on somebody else's dialog. Two harnesses driving one X server is not a
# flaky test, it is two harnesses corrupting each other's evidence.
#
# The socket in /tmp/.X11-unix is the authority for "in use"; the first free
# number at or above 180 is taken, and the number is recorded in the TSV so
# the run can be reproduced.
DISP=""
for n in $(seq 180 199); do
    if [[ ! -e "/tmp/.X11-unix/X$n" ]]; then DISP=":$n"; break; fi
done
if [[ -z "$DISP" ]]; then
    echo "stereo: FAIL — no free display between :180 and :199"; exit 1
fi
printf 'display	%s
' "$DISP" >> "$TSV"
Xvfb "$DISP" -screen 0 1400x1000x24 > "$OUT/xvfb.log" 2>&1 &
XVFB_PID=$!
sleep 2
if command -v matchbox-window-manager >/dev/null; then
    DISPLAY="$DISP" matchbox-window-manager -use_titlebar no \
        > "$OUT/wm.log" 2>&1 &
    WM_PID=$!
    sleep 2
else
    WM_PID=""
fi

PRAAT_PID=""
cleanup () {
    # -x, NEVER -f: `pkill -f praat` matches this script's own command line
    # through the driving shell and kills the run itself. And the Praat that
    # is killed is the one THIS script started, found by its own pid, so a
    # concurrent harness in another instance is left alone.
    [[ -n "$PRAAT_PID" ]] && kill -9 "$PRAAT_PID" 2>/dev/null
    [[ -n "$WM_PID" ]] && kill "$WM_PID" 2>/dev/null
    kill "$XVFB_PID" 2>/dev/null
}
trap cleanup EXIT

# Window lookup walks _NET_CLIENT_LIST via xprop, not `xdotool search`, which
# reads WM_NAME — left unset by GTK for a title containing an em dash, and
# this dialog's title contains one. GUI_HARNESS_RECIPE §11.
#
# AND IT CHECKS WHOSE WINDOW IT IS. _NET_WM_PID is compared against the pid
# this script started, so a Praat belonging to anything else on the same
# display is invisible here even if one ever shares it again. Without that
# check this harness pressed Return on another instance's dialog and then
# reported the other instance's window title as its own evidence.
pausewin () {
    local ids id name wpid
    ids=$(DISPLAY="$DISP" xprop -root _NET_CLIENT_LIST 2>/dev/null \
          | sed -n 's/.*# //p' | tr -d ' ' | tr ',' '\n')
    for id in $ids; do
        [[ "$id" == 0x* ]] || continue
        wpid=$(DISPLAY="$DISP" xprop -id "$id" _NET_WM_PID 2>/dev/null \
               | sed -n 's/.*= *//p')
        [[ -n "$PRAAT_PID" && -n "$wpid" && "$wpid" != "$PRAAT_PID" ]] \
            && continue
        name=$(DISPLAY="$DISP" xdotool getwindowname "${id}" 2>/dev/null)
        if [[ "$name" == Pause:* ]]; then
            printf '%s\t%s\n' "$id" "${name#Pause: }"; return 0
        fi
    done
    return 1
}

# ---------------------------------------------------------------------------
# One leg. $1 = leg name, $2 = seconds to wait for a dialog.
#
# THE WAIT IS BOUNDED, NOT FIXED. A leg that is supposed to raise no dialog
# (mono_silent) has to be given the same chance to raise one as a leg that is
# supposed to — otherwise "no dialog" only means "not yet", and the check that
# mono recordings are left alone would pass on a slow machine for the wrong
# reason. Both kinds of leg wait the same number of seconds.
# ---------------------------------------------------------------------------
# $4 = HOW MANY DIALOGS TO ANSWER, default one. The repeat leg for ruling 8b
# raises three from one process, and a presser that answered only the first
# would leave the other two on screen and the leg would be killed on the
# timeout -- which reads as "the gate hung", not as "the cleanup is missing".
runleg () {
    local leg="$1" wait="$2" waited=0 seen=0 info wid title
    local presses="${4:-1}" answered=0
    # A STALE LOCK reads as a harness bug: Praat exits with "An instance of
    # Praat that is not me is already running". Only these two files are
    # removed, and only from this harness's own scratch pref dir.
    rm -f "$PREFS/pid" "$PREFS/message" 2>/dev/null

    # --new-send AND NOT --run. `--run` is Praat's console mode: it has no
    # GUI at all, so a beginPause: in it dies inside GTK with "Can't create a
    # GtkStyleContext without a display connection" whether or not a display
    # is there. A dialog can only be driven from the windowed build, which is
    # what --new-send starts. Measured 15 Aug 2026: the first version of this
    # harness used --run, reported dialog_seen 0 on every leg, and would have
    # read as "the gate is still unwired".
    EML_STEREO_LEG="$leg" EML_STEREO_OUT="$TSV" \
        DISPLAY="$DISP" "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" \
        --utf8 --new-send "$DRIVE" \
        > "$OUT/$leg.log" 2>&1 &
    PRAAT_PID=$!
    sleep 6

    while [[ $waited -lt $wait && $answered -lt $presses ]]; do
        if info=$(pausewin); then
            wid=$(printf '%s' "$info" | cut -f1)
            title=$(printf '%s' "$info" | cut -f2)
            seen=1
            # The title is recorded once. A repeat leg raises the same dialog
            # three times and three identical rows would only make the TSV
            # ambiguous about which press each belonged to.
            if [[ $answered -eq 0 ]]; then
                printf '%s\t%s\n' "${leg}_dialog_title" "$title" >> "$TSV"
            fi
            if [[ $answered -eq 0 ]]; then
                DISPLAY="$DISP" import -window "$wid" \
                    "$SHOTS/${leg}_dialog.png" 2>/dev/null
            fi
            # THE PRESS. XTEST through an ACTIVATED window, never
            # `xdotool key --window <id>`: that sends a synthetic event GTK
            # ignores, which is why the first two runs of this harness saw
            # the dialog, pressed nothing, and hung. harness/savepaths'
            # presser and GUI_HARNESS_RECIPE say the same thing.
            #
            # $3 is a pre-key. Down, sent before any Tab, moves the
            # optionmenu one option on and leaves focus where it was, so the
            # reverse-Tab count to the buttons is unchanged. That is how the
            # LEFT CHANNEL arm is driven: the leg that takes it must come
            # back with 220 Hz, not the 110 Hz of the mixdown, which is the
            # whole claim -- that the user's answer reaches the number.
            DISPLAY="$DISP" xdotool windowactivate --sync "$wid" 2>/dev/null
            sleep 1
            if [[ -n "${3:-}" ]]; then
                DISPLAY="$DISP" xdotool key --clearmodifiers "$3" 2>/dev/null
                sleep 1
            fi
            # One shift+Tab from the top reaches the LAST button, Continue.
            DISPLAY="$DISP" xdotool key --clearmodifiers shift+Tab 2>/dev/null
            sleep 1
            DISPLAY="$DISP" xdotool key --clearmodifiers Return 2>/dev/null
            sleep 3
            answered=$((answered + 1))
            continue
        fi
        # The process finishing without a dialog is a legitimate outcome for
        # some legs and the defect for others. Either way, stop waiting.
        kill -0 "$PRAAT_PID" 2>/dev/null || break
        sleep 1
        waited=$((waited + 1))
    done

    printf '%s\t%s\n' "${leg}_dialog_seen" "$seen" >> "$TSV"
    printf '%s\t%s\n' "${leg}_dialogs_answered" "$answered" >> "$TSV"

    # BOUNDED, THEN KILLED BY PID. The script ends with `Quit`, and when that
    # works the process is gone within a second or two. When it does not --
    # a Praat error raises a window with no name at all and the process sits
    # there forever -- an unbounded `wait` turns a failed leg into a hung
    # harness, which is the one outcome that tells nobody anything. Twenty
    # seconds, then kill THIS pid; never a pattern, never -f.
    local gone=0 waitedq=0
    while [[ $waitedq -lt 20 ]]; do
        if ! kill -0 "$PRAAT_PID" 2>/dev/null; then gone=1; break; fi
        sleep 1
        waitedq=$((waitedq + 1))
    done
    printf '%s\t%s\n' "${leg}_exited_cleanly" "$gone" >> "$TSV"
    [[ $gone -eq 0 ]] && kill -9 "$PRAAT_PID" 2>/dev/null
    wait "$PRAAT_PID" 2>/dev/null
    PRAAT_PID=""
}

# gate_waveform takes the dialog's own default (Mix to mono).
# gate_pitch presses Down first, which selects LEFT CHANNEL ONLY.
runleg gate_waveform 25
runleg gate_pitch    25 Down
runleg mono_silent   25
# RULING 8b: three presses of the gate on one stereo Sound, three dialogs
# answered with the default (Mix to mono), and the object list counted after
# each. No pre-key, so every press makes the same choice -- which is the
# accumulating case, and the one a user hits by drawing three figures from one
# recording.
runleg gate_repeat   45 "" 3

# The two legs that need no display at all: what the plugin used to do, and
# what each of the three choices does. Run headless so they cannot be blamed
# on the X server.
for leg in ungated choices; do
    env -u DISPLAY EML_STEREO_LEG="$leg" EML_STEREO_OUT="$TSV" \
        "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" \
        --run "$DRIVE" > "$OUT/$leg.log" 2>&1
done

echo "stereo: wrote $TSV"
grep -c . "$TSV" | sed 's/^/stereo: rows /'
exit 0
