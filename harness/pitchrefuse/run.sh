#!/usr/bin/env bash
# ============================================================================
# harness/pitchrefuse/run.sh — drive the graphs form's pitch floor/ceiling
# pair through the real dialogs and record what the form did
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# THE SUBJECT. The pitch floor/ceiling pair is not an axis — it sets the
# search range the pitch-analysis algorithm hunts within — but a ceiling
# below its floor is the same order-reversal mistake the axis pairs already
# refuse, and now the form refuses it too: the conflict goes on screen, on a
# dialog titled "Pitch analysis", and nothing is drawn. This rig submits a
# reversed pair through the exact field the refusal quotes, and a correct
# pair through the same field, and records the sequence of dialog titles the
# form actually showed and the text the refusal actually displayed, read
# back off the pixels it displayed it in.
#
# Modelled on harness/axisrefuse/run.sh — same instrument, same reasoning
# for why it drives the GUI rather than calling the procedure directly (the
# refusal is a dialog that appears INSTEAD OF a figure, and the "instead of"
# is the thing under test). See that file's header for the fuller argument;
# this one does not repeat it.
#
# Run from anywhere:  bash harness/pitchrefuse/run.sh
# Output: harness/pitchrefuse/out/PITCHREFUSE.tsv
#         harness/pitchrefuse/out/<leg>_s<n>.png   every dialog, as shown
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

SRC="${EML_PR_SRC:-$EML_ROOT}"
OUT="${EML_PR_OUTDIR:-$SCRIPT_DIR/out}"
DRIVE="$SRC/harness/pitchrefuse/drive.praat"
DISP="${EML_PR_DISPLAY:-:87}"

mkdir -p "$OUT"
rm -f "$OUT"/*.png "$OUT"/*.log "$OUT"/*.txt 2>/dev/null
TSV="$OUT/PITCHREFUSE.tsv"
: > "$TSV"

emit () { printf '%s\t%s\n' "$1" "$2" >> "$TSV"; }

emit "praat_version" "$("$PRAAT" --version 2>&1 | head -1)"
emit "source_tree" "$SRC"
emit "host" "$(hostname 2>/dev/null || uname -n)"

FORM="$SRC/plugin/graphs/eml-graphs-form.praat"
emit "form_code_sha256" \
    "$(sed -E '/^[[:space:]]*(#|;|!)/d' "$FORM" | sha256sum | cut -d' ' -f1)"

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
    echo "pitchrefuse: FAIL — no display on $DISP"; exit 1
fi

DISPLAY="$DISP" matchbox-window-manager -use_titlebar no > "$OUT/wm.log" 2>&1 &
WM_PID=$!
sleep 2
if ! kill -0 "$WM_PID" 2>/dev/null; then
    echo "pitchrefuse: FAIL — the window manager did not start:"
    sed 's/^/          /' "$OUT/wm.log"; exit 1
fi

DISPLAY="$DISP" xcompmgr > "$OUT/xc.log" 2>&1 &
XC_PID=$!
sleep 2
emit "compositor" "$(kill -0 "$XC_PID" 2>/dev/null && echo running || echo absent)"

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

ink () {
    local w
    w=$(namedwin "Praat Picture") || { echo "NA"; return; }
    DISPLAY="$DISP" import -window "$w" "$OUT/_ink.png" 2>/dev/null || {
        echo "NA"; return; }
    convert "$OUT/_ink.png" -colorspace gray -threshold 50% \
        -format "%[fx:1-mean]" info: 2>/dev/null || echo "NA"
}

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
# FIELD ORDER on "Pitch Contour Settings", BEGINNER, Sound source (so the
# pitch pair is built): read off harness/axisrefuse/run.sh's own field-order
# comment, which is the census this rig trusts rather than re-deriving —
#     0 Time minimum  1 Time maximum  2 Frequency minimum  3 Frequency maximum
#     4 Y axis unit   5 Pitch floor   6 Pitch ceiling      7 Line style
# so tab5 reaches Pitch floor and tab6 reaches Pitch ceiling from the page's
# first widget, in the same left-then-right order every paired row uses.
# ---------------------------------------------------------------------------
LEGS="${EML_PR_LEGS:-pitch_range_reversed pitch_range_ok}"

plan_of () {
case "$1" in
  # THE REVERSED PAIR. Floor 500, ceiling 100 — the pair a user who typed the
  # two numbers backwards submits. Corrected to 75 .. 400 on the resubmit,
  # which is also the CONTROL half of this leg: it proves the correction
  # draws rather than refusing forever.
  pitch_range_reversed) cat <<'PLAN'
EML Graphs|btn1
Pitch Contour Settings|tab5=500,tab6=100,btn1
Pitch analysis|ocr,ink,btn1
EML Graphs|btn1
Pitch Contour Settings|tab5=75,tab6=400,btn1
Graph Complete|ink,btn3
PLAN
  ;;
  # THE CONTROL LEG, DRIVEN ON ITS OWN. A correct pair (floor 60, ceiling
  # 350) must draw on the FIRST submission, with no "Pitch analysis" dialog
  # in between — proving the refusal does not fire on an ordinary pair.
  pitch_range_ok) cat <<'PLAN'
EML Graphs|btn1
Pitch Contour Settings|tab5=60,tab6=350,btn1
Graph Complete|ink,btn3
PLAN
  ;;
esac
}

run_leg () {
    local leg="$1" prefs="$OUT/prefs_$leg" home="$OUT/home_$leg"
    rm -rf "$prefs" "$home"; mkdir -p "$prefs" "$home"
    printf 'showAdvanced: 0\n' > "$prefs/eml-graphs-config.txt"
    rm -f "$prefs/pid" "$prefs/message" 2>/dev/null

    emit "leg" "$leg"
    ( cd "$SCRIPT_DIR" && exec env DISPLAY="$DISP" HOME="$home" \
        EML_PR_LEG="$leg" EML_PR_OUT="$TSV" \
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
    for ((i = 0; i < 30; i++)); do
        [[ -z "$(winlist | tr -d '[:space:]')" ]] && break
        sleep 1
    done
    emit "${leg}_display_clear" \
        "$([[ -z "$(winlist | tr -d '[:space:]')" ]] && echo yes || echo no)"
    rm -rf "$prefs" "$home"
}

for leg in $LEGS; do
    run_leg "$leg"
done

emit "leg" "--shell--"
emit "legs_driven" "$(echo $LEGS | wc -w)"
rm -f "$OUT/_ink.png" "$OUT/_ocr.png"
echo "pitchrefuse: wrote $TSV ($(wc -l < "$TSV") lines)"
