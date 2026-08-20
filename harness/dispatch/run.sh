#!/usr/bin/env bash
# ============================================================================
# harness/dispatch/run.sh — drive every figure type through the form's dispatch
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# ONE PRAAT PROCESS PER LEG. An abort kills the process, so a single process
# looping over types would stop at the first failure and say nothing about the
# rest. A leg that aborts leaves no `returned` row, and that absence IS the
# report -- which is why this file never treats a missing row as "skipped".
#
# Usage: bash harness/dispatch/run.sh [leg ...]
#        legs are type numbers, optionally suffixed _rec for a recorded run.
# ============================================================================
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUT="$SCRIPT_DIR/out"
mkdir -p "$OUT"

# shellcheck source=/dev/null
[ -f "$ROOT/harness/_env.sh" ] && . "$ROOT/harness/_env.sh"
PRAAT="${PRAAT:-praat}"

LEGS="${*:-1 2 3 4 5 6 7 8 9 10 11 12 13 5_rec 7_rec 8_rec}"

TSV="$OUT/DISPATCH.tsv"
# A SUBSET DRIVE REPLACES ONLY ITS OWN LEGS. Truncating the file on every run
# means a one-leg drive erases the other fifteen, the validator reports them
# missing, and the reader cannot tell "this leg aborted" from "this leg was
# not run" -- which is the one distinction this harness exists to make.
if [ -f "$TSV" ]; then
    # awk, not grep: in a basic grep pattern "\t" is the letter t, so a filter
    # written that way matches nothing, the old rows survive alongside the new
    # ones, and the validator reads whichever it finds first -- which is how a
    # mutation demonstration can come out green against a mutated tree.
    keep="$(mktemp)"
    awk -F'\t' -v legs="$LEGS" '
        BEGIN { n = split(legs, a, " "); for (i = 1; i <= n; i++) drop[a[i]] = 1 }
        NR == 1 { print; next }
        !($1 in drop) { print }
    ' "$TSV" > "$keep"
    mv "$keep" "$TSV"
else
    printf 'leg\tkey\tvalue\n' > "$TSV"
fi

rc_all=0
for leg in $LEGS; do
    echo "  -- $leg"
    rm -f "$OUT/$leg.png"
    home="$(mktemp -d)"
    (
        cd "$SCRIPT_DIR" && \
        EML_DP_LEG="$leg" \
        EML_DP_OUT="$TSV" \
        EML_DP_PNG="$OUT/$leg.png" \
        EML_DP_ROOT="$ROOT" \
        HOME="$home" \
        xvfb-run -a "$PRAAT" --pref-dir="$home/prefs" --utf8 --run drive.praat \
            > "$OUT/$leg.log" 2>&1
    )
    rc=$?
    rm -rf "$home"
    if ! grep -q "^${leg}	returned	1$" "$TSV"; then
        echo "     LEG DID NOT RETURN (rc=$rc) -- see out/$leg.log"
        printf '%s\treturned\t0\n' "$leg" >> "$TSV"
        rc_all=1
    fi
done

echo "dispatch: $(grep -c . "$TSV") rows in $TSV"
exit $rc_all
