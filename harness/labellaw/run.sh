#!/usr/bin/env bash
# ============================================================================
# labellaw/run.sh — Praat itself, on the record about what a bad field label
# does to a user's number
# ============================================================================
# validate/v98_field_names.R states the derivation law and enforces it by
# reading source. This driver is the other half: it RUNS the two seeded
# violations under the supported Praat and reads the damage out of the Info
# window, so the law in v98's header is a measurement and not a memory. If a
# future Praat changes the derivation, this goes red and the rule gets
# revisited; nothing in a source check could notice that.
#
# The two scripts live in validate/fixtures/dialog_labels, next to the
# validator that reads them, and nothing in the plugin includes them.
#
#   collide_same_noun.praat  Four range boxes, two derived names. Praat draws
#                            all four rows and binds the LAST pair. Expected:
#                            left_Value=333, right_Value=444 — the 111 and
#                            222 typed into the first two boxes are gone,
#                            with no error and nothing on screen to see.
#
#   trap_minus99.praat       One box labelled "left Y-limits". The value is
#                            stored under the name `left_Y-limits`, which no
#                            script can write: written down it is `left_Y`
#                            minus `limits`. With those two ordinary
#                            bystanders in scope the line that means to read
#                            the user's 5 returns -99. Expected: bound=1,
#                            read=-99.
#
# NO DISPLAY IS NEEDED and none is used. `praat --run` takes a form's values
# from the command line, which is exactly the point: the pathology is in the
# binding, not in the drawing, so it can be measured with the GUI out of the
# way. The third fixture, branch_collision.praat, uses beginPause and so
# needs a click; it is checked in source by v98 and deliberately not run.
#
# Run from anywhere:  bash harness/labellaw/run.sh
# Exit 0 = both scripts produced exactly the damage the ruling recorded.
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$SCRIPT_DIR/.." && pwd)/_env.sh" || exit 1
FIX="$EML_ROOT/validate/fixtures/dialog_labels"
OUT="${EML_LABELLAW_DIR:-$SCRIPT_DIR/out}"
PREFS="$SCRIPT_DIR/prefs"
mkdir -p "$OUT" "$PREFS"
TSV="$OUT/LABELLAW.tsv"
rm -f "$OUT"/*.log "$TSV"

run_fixture () {
    local name="$1"; shift
    env -u DISPLAY timeout 60 "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" \
        --run "$FIX/$name" "$@" > "$OUT/${name%.praat}.log" 2>&1
}

run_fixture collide_same_noun.praat 111 222 333 444
run_fixture trap_minus99.praat 5

: > "$TSV"
{
    sed -n 's/^\(left_Value\|right_Value\)=\(.*\)$/\1\t\2/p' \
        "$OUT/collide_same_noun.log"
    sed -n 's/^\(bound\|read\)=\(.*\)$/\1\t\2/p' "$OUT/trap_minus99.log"
} >> "$TSV"

printf '%-14s %s\n' measurement value
awk -F"\t" '{printf "%-14s %s\n", $1, $2}' "$TSV"
echo

want () {
    local key="$1" expect="$2"
    local got
    got=$(awk -F"\t" -v k="$key" '$1 == k {print $2}' "$TSV")
    if [[ "$got" != "$expect" ]]; then
        echo "FAIL: $key was \"$got\", the ruling measured \"$expect\""
        return 1
    fi
    return 0
}

fail=0
# THE DISCARDED PAIR. If left_Value ever comes back 111, Praat has started
# binding the FIRST field of a colliding pair rather than the last -- still a
# collision, still a lost value, and v98's account of which one survives
# would need rewriting.
want left_Value  333 || fail=1
want right_Value 444 || fail=1
# THE ARITHMETIC TRAP. bound=1 says the user's number really is stored;
# read=-99 says what the code that asks for it gets instead.
want bound 1   || fail=1
want read  -99 || fail=1
grep -q "^COLLIDE DONE$" "$OUT/collide_same_noun.log" \
    || { echo "FAIL: collide_same_noun.praat did not finish -- see $OUT"; fail=1; }
grep -q "^TRAP DONE$" "$OUT/trap_minus99.log" \
    || { echo "FAIL: trap_minus99.praat did not finish -- see $OUT"; fail=1; }

if [[ $fail -eq 0 ]]; then
    echo "labellaw: PASS -- 4 measurements, both seeded violations behaved as ruled"
    exit 0
fi
exit 1
