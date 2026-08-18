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
    union=$(sed -n 's/^UNION //p' "$OUT/$name.log" | tail -1)
    if [ -s "$OUT/$name.png" ]; then
        if grep -qiE "^Error|not completed" "$OUT/$name.log"; then
            verdict=DREW_THEN_FAILED; fail=1
        else
            verdict=OK
        fi
    else
        verdict=NO_FIGURE; fail=1
    fi
    px=$(identify -format "%wx%h" "$OUT/$name.png" 2>/dev/null)
    printf '%s\t%s\t%s\t%s\n' "$name" "$verdict" "$px" "$union" >> "$TSV"
done

awk -F"\t" '{printf "%-16s %-18s %-14s %s\n", $1, $2, $3, $4}' "$TSV"
[ $fail -eq 0 ] && echo "compose: PASS" && exit 0
echo "compose: FAIL"
exit 1
