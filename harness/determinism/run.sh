#!/usr/bin/env bash
# ============================================================================
# determinism/run.sh — does each draw procedure produce the same picture twice?
# ============================================================================
# For each of the ten Table-consuming draw procedures, render the SAME seeded
# fixture in two separate Praat processes and compare the PNGs byte for byte.
#
# THE QUESTION THIS ANSWERS, and why the stress suite cannot answer it. 22 of
# the 39 stress cases call randomGauss with no seed, so no two runs of one
# case are comparable and nothing in the suite would notice a draw procedure
# that began producing a different correct-looking figure. v27 survives that
# by asserting inequalities and never values -- which is the right design for
# what v27 checks, and leaves this unchecked.
#
# A type that FAILS here has no reproducible baseline. That is not necessarily
# a bug in the figure; it means every check built on that figure is weaker
# than it appears, and it has to be known before anyone reads a diff of two
# renders as a regression.
#
# Two PROCESSES rather than two draws in one, deliberately: a generator seeded
# once at the top of a script would give the second draw different numbers,
# and that would be measuring the fixture rather than the procedure.
#
# Run from anywhere:  bash harness/determinism/run.sh [type-number]
# Exit 0 = every type rendered identically twice.
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$SCRIPT_DIR/.." && pwd)/_env.sh" || exit 1
OUT="$SCRIPT_DIR/out"
PREFS="$SCRIPT_DIR/prefs"
mkdir -p "$OUT" "$PREFS"

NAMES=(_ ts tsci spaghetti bar violin box gviolin gbox scatter histogram)
ONLY="${1:-}"

printf '%-12s %-10s %s\n' "type" "verdict" "bytes"
fail=0
ran=0

for i in $(seq 1 10); do
    nm="${NAMES[$i]}"
    if [[ -n "$ONLY" && "$ONLY" != "$nm" && "$ONLY" != "$i" ]]; then
        continue
    fi
    ran=$((ran + 1))
    a="$OUT/${nm}_a.png"
    b="$OUT/${nm}_b.png"
    rm -f "$a" "$b"

    for pass in a b; do
        p="$OUT/${nm}_${pass}.png"
        ( cd "$SCRIPT_DIR" && EML_OUT="$p" timeout 300 "$PRAAT" $PRAAT_TRUST \
            --pref-dir="$PREFS" --run case.praat "$i" \
            >"$OUT/${nm}_${pass}.log" 2>&1 )
    done

    if [[ ! -f "$a" || ! -f "$b" ]]; then
        printf '%-12s %-10s %s\n' "$nm" "NO_FIGURE" \
            "$(tail -2 "$OUT/${nm}_a.log" | tr '\n' ' ' | cut -c1-70)"
        fail=$((fail + 1))
        continue
    fi

    sa=$(stat -c%s "$a")
    if cmp -s "$a" "$b"; then
        printf '%-12s %-10s %s\n' "$nm" "STABLE" "$sa"
    else
        sb=$(stat -c%s "$b")
        d=""
        if command -v compare >/dev/null 2>&1; then
            d=$(compare -metric AE "$a" "$b" null: 2>&1 || true)
            d="  differing px: $d"
        fi
        printf '%-12s %-10s %s\n' "$nm" "VARIES" "$sa vs $sb$d"
        fail=$((fail + 1))
    fi
done

echo
if [[ $fail -eq 0 ]]; then
    echo "determinism: PASS — $ran/$ran types render identically twice"
    echo "             (Praat $("$PRAAT" --version 2>&1 | head -1))"
    exit 0
fi
echo "determinism: $fail of $ran types do NOT render identically twice"
echo "             A type listed VARIES has no reproducible baseline; see"
echo "             audit/GRAPHING_PUSH_REMAINING.md \$14."
exit 1
