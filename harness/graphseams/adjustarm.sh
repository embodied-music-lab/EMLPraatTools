#!/usr/bin/env bash
# ============================================================================
# graphseams/adjustarm.sh — the Adjustment menu, driven on both arms
# ============================================================================
# D5 / RULING 1a, 15 August 2026. The parametric arm no longer offers the
# "Adjustment method" optionmenu, because Tukey's p is already family-wise and
# stacking Holm or Bonferroni on top of it would double-correct. The Dunn arm
# keeps the menu, because it reads it.
#
# TWO LEGS THAT DIFFER IN ONE SEEDED VALUE. Same graph type, same table, same
# columns, same advanced mode, same presets, same driver file — only
# $EML_ADJUST_ARM changes. A pair like that is the only arrangement in which
# a difference in the dialog can be attributed to the arm; two separately
# written legs would leave every difference arguable, which is the failure
# harness/gui_adv's header records about its own first version.
#
# THREE WITNESSES, AND THEY ARE DELIBERATELY OF DIFFERENT KINDS:
#
#   adjustOffered   THE GATE ITSELF, read out of the form after the last
#                   commit. 1 on the nonparametric arm, 0 on the parametric
#                   one. It is the value that decided whether
#                   adjustment_method was read back, so it is the closest
#                   thing to the behaviour under test — and on its own it is
#                   also the weakest, because it is exactly what a fix that
#                   set the flag and left the field on the screen would still
#                   report correctly.
#
#   DIALOG HEIGHT   THE SCREEN, in pixels, of the Column Mapping page. It is
#                   measured from the window manager and knows nothing about
#                   the variable above. A parametric dialog the same height
#                   as a nonparametric one has the same number of rows on it,
#                   whatever the flag says. This is the witness that closes
#                   the "flag set, widget still there" hole.
#
#   annotCorrection THE CONSEQUENCE. On the parametric arm the page must not
#                   write annotCorrectionMethod$ at all, so it must still be
#                   the file-scope default. A page that wrote it — even to
#                   the same value — is still reading a field that was not on
#                   the screen, which in Praat returns the last dialog's stale
#                   value rather than failing.
#
# AND A SCREENSHOT OF EACH DIALOG, because a person should be able to look.
#
# DISPLAY :121. harness/graphseams/run.sh owns :94 and this rig deliberately
# does not share it: run.sh regenerates SEAMS.tsv, which v61's existing checks
# read, and a rig that can only be run by running that one is a rig nobody
# runs during a break test. :88, :89, :91, :92, :93, :94 and :180+ are taken
# by savepaths, newpath, gui_e2e, tabwalk, gui_adv, graphseams and others.
#
# KILLING. By RECORDED PID only. `pkill -f praat` matches the driving shell's
# own command line and kills it (D126), and even `pkill -x praat` takes out
# whatever another agent is running.
#
# Run from anywhere:  bash harness/graphseams/adjustarm.sh
# Exit 0 = both legs completed and ADJUSTARM.tsv was written. It is not a
# pass/fail rig; validate/v61_graphs_seams.R decides.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$SCRIPT_DIR/.." && pwd)/_env.sh" || exit 1
OUT="${EML_ADJUST_OUT:-$SCRIPT_DIR/adjust_out}"
mkdir -p "$OUT"
rm -f "$OUT"/*.tsv "$OUT"/*.log "$OUT"/*.png "$OUT"/*.txt 2>/dev/null

DISP=":121"
XVFB_PID=""; WM_PID=""; PRAAT_PID=""
cleanup() {
    [[ -n "$PRAAT_PID" ]] && kill -9 "$PRAAT_PID" 2>/dev/null
    [[ -n "$WM_PID"    ]] && kill -9 "$WM_PID"    2>/dev/null
    [[ -n "$XVFB_PID"  ]] && kill -9 "$XVFB_PID"  2>/dev/null
    rm -f "/tmp/.X${DISP#:}-lock" "/tmp/.X11-unix/X${DISP#:}" 2>/dev/null
}
trap cleanup EXIT

rm -f "/tmp/.X${DISP#:}-lock" "/tmp/.X11-unix/X${DISP#:}" 2>/dev/null
# 1400x1400: TALLER THAN run.sh's SCREEN, ON PURPOSE. run.sh is 1000px
# because the audit's dialog-clipping finding is about a 1000px display and a
# taller screen would hide it. This rig measures the OPPOSITE thing — whether
# one arm's dialog has a row the other does not — and a window manager clamps
# a dialog to the screen, so on a 1000px screen both arms would report the
# same clamped height and the height witness would be dead. The clipping
# finding stays where it is measured; this rig needs the unclamped number.
Xvfb "$DISP" -screen 0 1400x1400x24 > "$OUT/xvfb.log" 2>&1 &
XVFB_PID=$!
sleep 3
if ! DISPLAY="$DISP" xdpyinfo >/dev/null 2>&1; then
    echo "adjustarm: FAIL — no display on $DISP"; exit 1
fi
DISPLAY="$DISP" matchbox-window-manager -use_titlebar no > "$OUT/wm.log" 2>&1 &
WM_PID=$!
sleep 2
if ! kill -0 "$WM_PID" 2>/dev/null; then
    echo "adjustarm: FAIL — the window manager did not start:"
    sed 's/^/          /' "$OUT/wm.log"; exit 1
fi

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

# NO SCREEN COORDINATES, and the button is counted from the END. Focus starts
# at ring position 0, so ONE shift+Tab wraps to the last widget, which is the
# last button; N presses the Nth button from the end. harness/tabwalk measured
# that on every button-row shape in the plugin, and a FORWARD count cannot
# work because a folder: field is a GtkTextView and eats Tab as a literal.
# The counts come from the endPause: lists in eml-graphs-form.praat:
#   ... Column Mapping   GoBack Quit <toggle> Draw  -> Draw 1
#   Graph Complete       Done Save Redraw           -> Redraw 1, Save 2, Done 3
#   Save                 GoBack Save                -> Save 1
#   Saved                OK                         -> OK   1
run_arm () {
    local arm="$1"
    local prefs="$SCRIPT_DIR/prefs_adj_$arm"
    local home="$OUT/home_$arm"
    local tsv="$OUT/DIALOGS_$arm.tsv"
    rm -rf "$prefs" "$home"; mkdir -p "$prefs" "$home"
    : > "$tsv"
    # A stale instance lock reads as a harness bug; ONLY these two are removed.
    rm -f "$prefs/pid" "$prefs/message" 2>/dev/null
    # ADVANCED FROM THE CONFIG, not from the toggle. Pressing the toggle would
    # put the page on the RESTORE arm rather than the plain advanced page, and
    # the restore arm re-seeds the test type from a stash — so the leg would
    # no longer be testing the arm it seeded.
    printf 'showAdvanced: 1\n' > "$prefs/eml-graphs-config.txt"

    ( cd "$SCRIPT_DIR" && DISPLAY="$DISP" EML_SEAMS_OUT="$OUT" \
        EML_ADJUST_ARM="$arm" HOME="$home" \
        "$PRAAT" $PRAAT_TRUST --pref-dir="$prefs" --utf8 --new-send \
        driver_adjust.praat > "$OUT/driver_$arm.log" 2>&1 ) &
    PRAAT_PID=$!
    sleep 10

    local step=0 gcVisit=0 cmVisit=0 line wid title rev label geom
    while [[ $step -lt 25 ]]; do
        line=$(pauseinfo) || break
        wid=${line%%$'\t'*}
        title=${line#*$'\t'}
        step=$((step + 1))
        rev=1; label="?"
        case "$title" in
            *"Column Mapping"*|*"Settings")
                cmVisit=$((cmVisit + 1)); rev=1; label="Draw" ;;
            *"Data Format"*)   rev=1; label="Continue" ;;
            *"EML Graphs"*)    rev=1; label="Continue" ;;
            *"Graph Complete"*)
                gcVisit=$((gcVisit + 1))
                if [[ $gcVisit -eq 1 ]]; then rev=2; label="Save"
                else rev=3; label="Done"; fi ;;
            "Save")            rev=1; label="Save" ;;
            *"Saved"*)         rev=1; label="OK" ;;
            *"Nothing saved"*) rev=1; label="OK" ;;
            *"Column Error"*)  rev=1; label="OK" ;;
            *)                 rev=1; label="LAST" ;;
        esac
        geom=$(DISPLAY="$DISP" xdotool getwindowgeometry --shell "$wid" 2>/dev/null \
               | sed -n 's/^HEIGHT=//p')
        printf '%d\t%s\t%s\t%d\t%s\n' "$step" "$title" "$label" "$rev" "${geom:-0}" >> "$tsv"
        if [[ "$label" == "Draw" && $cmVisit -eq 1 ]]; then
            DISPLAY="$DISP" import -window "$wid" "$OUT/DIALOG_$arm.png" 2>/dev/null
        fi
        DISPLAY="$DISP" xdotool windowactivate --sync "$wid" 2>/dev/null
        sleep 1
        DISPLAY="$DISP" xdotool key --clearmodifiers --repeat "$rev" shift+Tab 2>/dev/null
        sleep 1
        DISPLAY="$DISP" xdotool key --clearmodifiers Return 2>/dev/null
        sleep 6
    done
    kill -9 "$PRAAT_PID" 2>/dev/null
    PRAAT_PID=""
    sleep 1
    echo "  arm $arm: $step dialogs"
}

ARMS="${EML_ADJUST_ARMS:-nonparametric parametric}"
echo "adjustarm: driving [$ARMS] on $DISP"
for a in $ARMS; do run_arm "$a"; done

TSV="$OUT/ADJUSTARM.tsv"
: > "$TSV"
kv () { printf '%s\t%s\n' "$1" "$2" >> "$TSV"; }
kv praat_version "$("$PRAAT" --version 2>&1 | head -1)"

for a in $ARMS; do
    R="$OUT/ADJUST_$a.txt"
    if [[ -f "$R" ]]; then
        # ENCODING IS DETECTED, NOT ASSUMED, and that is not fussiness: the
        # first version of this rig assumed UTF-16 because the panel's SAVED
        # REPORT is UTF-16 under --utf8, ran `iconv -f UTF-16` over a receipt
        # Praat had written as plain ASCII, and got a file of CJK. iconv
        # SUCCEEDED -- every byte pair is a valid code point -- so the `||`
        # fallback never fired and all four values came out empty. A check
        # reading them would have gone red for a reason that had nothing to do
        # with the plugin. Praat writes ASCII when every character is ASCII
        # and UTF-16 with a BOM otherwise, so the BOM is what is tested.
        if [[ "$(head -c2 "$R" | od -An -tx1 | tr -d ' ')" == "fffe" \
           || "$(head -c2 "$R" | od -An -tx1 | tr -d ' ')" == "feff" ]]; then
            iconv -f UTF-16 -t UTF-8 "$R" > "$OUT/receipt_$a.txt" 2>/dev/null \
                || cp "$R" "$OUT/receipt_$a.txt"
        else
            cp "$R" "$OUT/receipt_$a.txt"
        fi
        kv "${a}_offered"    "$(sed -n 's/^adjustOffered=//p' "$OUT/receipt_$a.txt" | head -1 | tr -d '\r')"
        kv "${a}_correction" "$(sed -n 's/^correction=//p'    "$OUT/receipt_$a.txt" | head -1 | tr -d '\r')"
        kv "${a}_testtype"   "$(sed -n 's/^testType=//p'      "$OUT/receipt_$a.txt" | head -1 | tr -d '\r')"
        kv "${a}_annotate"   "$(sed -n 's/^annotate=//p'      "$OUT/receipt_$a.txt" | head -1 | tr -d '\r')"
    else
        kv "${a}_offered" ""; kv "${a}_correction" ""
        kv "${a}_testtype" ""; kv "${a}_annotate" ""
    fi
    # THE COLUMN MAPPING PAGE'S HEIGHT. First visit only: a redraw re-enters
    # the same page and a second measurement of the same window would look
    # like corroboration while being the same observation twice.
    kv "${a}_dialog_height" \
        "$(awk -F'\t' '$2 ~ /Column Mapping/ {print $5; exit}' "$OUT/DIALOGS_$a.tsv" 2>/dev/null)"
    kv "${a}_dialogs" "$(wc -l < "$OUT/DIALOGS_$a.tsv" 2>/dev/null)"
    kv "${a}_unknown_variable" \
        "$(grep -c 'Unknown variable' "$OUT/driver_$a.log" 2>/dev/null | head -1)"
    kv "${a}_pngs" \
        "$(find "$OUT/home_$a" -maxdepth 2 -name '*.png' 2>/dev/null | wc -l)"
done

echo "adjustarm: wrote $TSV"
sed 's/^/  /' "$TSV"
exit 0
