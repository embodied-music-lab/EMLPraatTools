#!/usr/bin/env bash
# ============================================================================
# harness/compose/run.sh — page composition, driven
# ============================================================================
# Every case is one or more presses of Draw through the graphs form's own
# dispatch, with the page controls set to the values a user would type. One
# praat process per case: a Praat script error aborts the script, so a single
# process running every case reports one failure and hides the rest.
#
# Run from anywhere:  bash harness/compose/run.sh [case-substring]
#
# THE FILTER IS FOR DEBUGGING ONE CASE AND LEAVES A PARTIAL ARTEFACT. The TSV
# is rewritten from scratch on every run, so a filtered run publishes a file
# describing one case. validate/v94 censuses the cases it finds against the
# ones it asserts on and goes red on the difference rather than quietly
# checking less -- but the fix is to re-run without a filter before believing
# anything, not to read the red.
# Output: harness/compose/out/<case>.png, <case>.log
#         harness/compose/out/COMPOSE.tsv   case, verdict, union w x h
# Exit 0 = every case drew and saved.
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$SCRIPT_DIR/.." && pwd)/_env.sh" || exit 1
OUT="${EML_COMPOSE_DIR:-$SCRIPT_DIR/out}"
PREFS="$SCRIPT_DIR/prefs"
FILTER="${1:-}"
mkdir -p "$OUT" "$PREFS"
TSV="$OUT/COMPOSE.tsv"
: > "$TSV"

fail=0
# ONE ROW PER MEASUREMENT: case, key, value. The same shape harness/runblock
# and harness/vecfig write, and for the same reason -- a validator reads a key
# by name rather than by column position, so adding a measurement cannot
# silently shift what an older check was reading.
emit () { printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$TSV"; }

for f in "$SCRIPT_DIR"/*.praat; do
    name=$(basename "$f" .praat)
    [ "$name" = "fixture" ] && continue
    [ -n "$FILTER" ] && case "$name" in *"$FILTER"*) ;; *) continue ;; esac
    rm -f "$OUT/$name.png"
    # DISPLAY deliberately unset: proves the case needs no X server, and stops
    # a stray connection to an interactive instance.
    ( cd "$SCRIPT_DIR" && env -u DISPLAY EML_OUT="$OUT/$name.png" \
        timeout 300 "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" --run "$f" \
        > "$OUT/$name.log" 2>&1 )
    if [ -s "$OUT/$name.png" ]; then
        if grep -qiE "^Error|not completed" "$OUT/$name.log"; then
            verdict=DREW_THEN_FAILED; fail=1
        else
            verdict=OK
        fi
    else
        verdict=NO_FIGURE; fail=1
    fi
    emit "$name" verdict "$verdict"
    # HOW MANY PRESSES OF DRAW THE CASE MADE. One PANEL line per press,
    # printed by the fixture's @composePanel after the draw returns.
    emit "$name" presses "$(grep -c '^PANEL ' "$OUT/$name.log")"
    # THE UNION, as the plugin's own extent tracker holds it at save time.
    set -- $(sed -n 's/^UNION //p' "$OUT/$name.log" | tail -1)
    emit "$name" union_x0 "${1:-}" ; emit "$name" union_x1 "${2:-}"
    emit "$name" union_y0 "${3:-}" ; emit "$name" union_y1 "${4:-}"
    # THE PARKED SEPARATE LEGEND's band, when the case made one.
    set -- $(sed -n 's/^PARK //p' "$OUT/$name.log" | tail -1)
    if [ -n "${1:-}" ]; then
        emit "$name" park_y0 "$1" ; emit "$name" park_y1 "${2:-}"
    fi
    if [ -s "$OUT/$name.png" ]; then
        emit "$name" png_px "$(identify -format '%wx%h' "$OUT/$name.png" 2>/dev/null)"
        emit "$name" png_md5 "$(md5sum "$OUT/$name.png" | cut -d' ' -f1)"
    fi
done

awk -F"\t" '{printf "%-18s %-10s %s\n", $1, $2, $3}' "$TSV"
[ $fail -eq 0 ] && echo "compose: PASS" && exit 0
echo "compose: FAIL"
exit 1
