#!/usr/bin/env bash
# ============================================================================
# labellaw/inject.sh — Praat on the record about the rows a procedure puts on
# somebody else's dialog page
# ============================================================================
# validate/v98_field_names.R follows a procedure call made inside a dialog
# block and audits the field rows the procedure contributes, because those
# rows render on the caller's page and land in the caller's namespace. That is
# a claim about Praat, so it is measured here rather than reasoned about.
#
# WHY THIS ONE NEEDS A DISPLAY AND run.sh DOES NOT. `beginPause:` aborts under
# `praat --run` with a Trace/breakpoint trap (6.6.30, Linux — harness/
# GUI_HARNESS_RECIPE.md §0), and a `form:` block cannot be the demonstration:
# a form is a declaration Praat reads whole, so a procedure call inside one
# emits nothing. Injection only exists in the block that needs a click. So
# this driver renders the page under Xvfb, reads the rendered rows back as
# TEXT, presses the default button, and reads the bound variables out of the
# file the fixture writes.
#
# WHAT IS MEASURED, from validate/fixtures/dialog_labels/inject_collision.praat:
#
#   THE INJECTED ROWS ARE ON THE PAGE. Read off the rendered dialog by OCR,
#       which is why the assertion below is on the row LABELS and not on a
#       pixel count. A `left X` and a `right X` field pair into ONE displayed
#       row of two boxes showing the LEFT field's remainder only, and the
#       pairing word is dropped even from an unpaired field, so five fields
#       show as three lines: "Value (bottom/top)" and "Value (left/right)"
#       — one written in the block, one contributed by the call — and
#       "Y-limits", also contributed by the call.
#   left_Value=333, right_Value=444 — the injected rows collided with the two
#       written in the block and bound last. The 111 and 222 the first pair
#       carried are gone, with no error.
#   bound=1, read=-99 — the injected "left Y-limits" row stored its 5 under a
#       name no script can write, and the line that asks for it gets the
#       bystanders' arithmetic instead.
#
# EVERY PROCESS THIS SCRIPT STARTS IS KILLED BY ITS OWN RECORDED PID, and the
# display number is its own. `pkill -x praat` would take out a Praat another
# agent is driving on another display; `pkill -f` would take out this shell.
# See the standing rule at the top of GUI_HARNESS_RECIPE.md.
#
# Run from anywhere:  bash harness/labellaw/inject.sh
# Exit 0 = the page rendered the injected rows and bound them as ruled.
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$SCRIPT_DIR/.." && pwd)/_env.sh" || exit 1
FIX="$EML_ROOT/validate/fixtures/dialog_labels/inject_collision.praat"
OUT="${EML_LABELLAW_DIR:-$SCRIPT_DIR/out}"
# Its own preference directory, under the one .gitignore already excludes,
# so this run cannot collide with run.sh's Praat over a prefs5 file and
# nothing here lands in the repository.
PREFS="$SCRIPT_DIR/prefs/gui"
DISP="${EML_LABELLAW_DISPLAY:-:91}"
mkdir -p "$OUT" "$PREFS"
rm -f "$PREFS/inject_collision.out" "$PREFS/pid" "$PREFS/message"
rm -f "$OUT/inject.log" "$OUT/INJECT.tsv" "$OUT/inject_page.txt"

XVFB_PID=""; WM_PID=""; PRAAT_PID=""
cleanup () {
    for p in "$PRAAT_PID" "$WM_PID" "$XVFB_PID"; do
        [[ -n "$p" ]] && kill -9 "$p" 2>/dev/null
    done
    wait 2>/dev/null
    # A killed Xvfb leaves its lock behind, and the next run reads that lock
    # as somebody else's display and refuses. The lock is removed only when
    # this run is the one that created it.
    if [[ -n "$XVFB_PID" ]]; then
        rm -f "/tmp/.X${DISP#:}-lock" "/tmp/.X11-unix/X${DISP#:}"
    fi
}
trap cleanup EXIT

# A display this driver does not own is a display it must not take over: a
# stale lock here means somebody else is on :91, and starting anyway would
# either fail or land two rigs on one screen.
if [[ -e "/tmp/.X${DISP#:}-lock" ]]; then
    echo "inject: display $DISP is already in use — set EML_LABELLAW_DISPLAY" >&2
    exit 1
fi

Xvfb "$DISP" -screen 0 1400x1000x24 > "$OUT/inject_xvfb.log" 2>&1 &
XVFB_PID=$!
sleep 3
export DISPLAY="$DISP"
xdpyinfo > /dev/null 2>&1 || { echo "inject: no display on $DISP" >&2; exit 1; }

matchbox-window-manager -use_titlebar no > "$OUT/inject_wm.log" 2>&1 &
WM_PID=$!
sleep 2

nohup "$PRAAT" --new-send --pref-dir="$PREFS" --utf8 "$FIX" \
    > "$OUT/inject.log" 2>&1 &
PRAAT_PID=$!

# The dialog is modal and Praat blocks in it, so the wait is for the window to
# appear rather than for the process to finish.
WIN=""
for _ in $(seq 1 30); do
    sleep 1
    for w in $(xprop -root _NET_CLIENT_LIST 2>/dev/null \
               | sed -n 's/.*# //p' | tr -d ','); do
        id=$(printf '%d' "$w" 2>/dev/null) || continue
        xwininfo -id "$id" 2>/dev/null | grep -q IsViewable || continue
        case "$(xdotool getwindowname "$id" 2>/dev/null)" in
            Pause:*) WIN="$id"; break ;;
        esac
    done
    [[ -n "$WIN" ]] && break
done
if [[ -z "$WIN" ]]; then
    echo "FAIL: no pause window appeared — see $OUT/inject.log"
    exit 1
fi

# THE PAGE AS TEXT. A screenshot is kept because a person will want to look at
# it, but the assertion is made on the OCR, so that "the row is on the page"
# is a string this script compared rather than a picture somebody read.
import -window "$WIN" "$OUT/inject_page.png" 2>/dev/null
tesseract "$OUT/inject_page.png" "$OUT/inject_page" > /dev/null 2>&1
PAGE="$OUT/inject_page.txt"
[[ -f "$PAGE" ]] || { echo "FAIL: OCR produced nothing"; exit 1; }

echo "--- the page as rendered -----------------------------------------------"
sed '/^[[:space:]]*$/d' "$PAGE"
echo "------------------------------------------------------------------------"

fail=0
row () {
    local pat="$1" origin="$2"
    if grep -qi -- "$pat" "$PAGE"; then
        printf 'row present  %-28s %s\n' "$pat" "$origin"
    else
        printf 'FAIL: row %-24s (%s) is not on the rendered page\n' "$pat" "$origin"
        fail=1
    fi
}
row "bottom/top"  "written in the block"
row "left/right"  "contributed by @seededCommonRows"
# OCR reads the hyphen of "Y-limits" unreliably at this size; the row is
# asserted on the part of the label that survives every reading of it.
row "limits"      "contributed by @seededCommonRows"

xdotool windowactivate --sync "$WIN"
sleep 1
xdotool key --clearmodifiers Return
for _ in $(seq 1 20); do
    [[ -f "$PREFS/inject_collision.out" ]] && break
    sleep 1
done
RES="$PREFS/inject_collision.out"
if [[ ! -f "$RES" ]]; then
    echo "FAIL: the fixture never wrote its result — see $OUT/inject.log"
    exit 1
fi

sed -n 's/^\([a-zA-Z_]*\)=\(.*\)$/\1\t\2/p' "$RES" > "$OUT/INJECT.tsv"
echo
printf '%-14s %s\n' measurement value
awk -F"\t" '{printf "%-14s %s\n", $1, $2}' "$OUT/INJECT.tsv"
echo

want () {
    local key="$1" expect="$2" got
    got=$(awk -F"\t" -v k="$key" '$1 == k {print $2}' "$OUT/INJECT.tsv")
    if [[ "$got" != "$expect" ]]; then
        echo "FAIL: $key was \"$got\", the ruling measured \"$expect\""
        return 1
    fi
    return 0
}

# THE INJECTED ROWS BOUND LAST. 333 and 444 are the defaults of the two rows
# @seededCommonRows contributes; reading them back out of left_Value and
# right_Value is what proves those rows shared the caller's namespace and
# overwrote the 111 and 222 written in the block.
want left_Value  333 || fail=1
want right_Value 444 || fail=1
# THE ARITHMETIC TRAP, ARRIVING BY CALL.
want bound 1   || fail=1
want read  -99 || fail=1
grep -q "^INJECT DONE$" "$RES" \
    || { echo "FAIL: inject_collision.praat did not finish — see $RES"; fail=1; }

if [[ $fail -eq 0 ]]; then
    echo "labellaw/inject: PASS — 5 rows rendered, 3 of them contributed by a"
    echo "                 procedure call, and bound into the caller's namespace"
    exit 0
fi
exit 1
