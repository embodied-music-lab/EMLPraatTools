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
# Output: out/<type>_a.png  out/<type>_b.png   the two renders
#         out/<type>_a.log  out/<type>_b.log   the two Praat transcripts
#         out/DETERMINISM.tsv                  the evidence v37 reads
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

# ---------------------------------------------------------------------------
# THE MACHINE-READABLE ARTEFACT, beside the human table below.
#
#     out/DETERMINISM.tsv    one row per type, five fields, no header:
#         name  verdict  bytesA  bytesB  diffPx
#
#     verdict   STABLE | VARIES | NO_FIGURE
#     bytesA/B  size of each pass's PNG; NA when that file is missing
#     diffPx    ImageMagick `compare -metric AE` when the two files differ
#               and `compare` is installed; NA when it is not; 0 when the
#               two files are identical
#
# Until 12 August 2026 the verdict existed only as a line of printed text and
# nothing read it, which made this the one harness in the tree whose result
# was the harness reporting on itself -- audit/GRAPHING_PUSH_REMAINING.md §18.
# validate/v37_determinism.R reads this file, and re-compares the two PNGs on
# disk itself rather than believing the verdict column.
#
# TRUNCATED AT THE START OF A RUN, and the PNGs and logs go with it. A stale
# <type>_b.png left by a previous run, compared against a fresh <type>_a.png,
# is a verdict about two different runs presented as a verdict about one.
# Same reason harness/legend/run.sh clears its output directory.
# ---------------------------------------------------------------------------
TSV="$OUT/DETERMINISM.tsv"
: > "$TSV"
rm -f "$OUT"/*.png "$OUT"/*.log

# emit_row NAME VERDICT BYTESA BYTESB DIFFPX
#
# The only printf in this file that writes to the TSV -- a second one is how a
# column count drifts. The stdout table below is separate and stays as it was.
emit_row () {
    printf '%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" "$5" >> "$TSV"
}

# bytes_of FILE — the file's size, or NA when it is not there.
bytes_of () {
    if [[ -f "$1" ]]; then stat -c%s "$1"; else printf 'NA'; fi
}

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
        # A HEADER LINE, WRITTEN BEFORE THE RUN, AND IT IS NOT DECORATION.
        # Two of the ten types -- box and violin -- print nothing at all, so
        # their transcripts were ZERO BYTES, and an empty file cannot tell
        # "this pass produced no output" apart from "this pass never ran".
        # validate/v37 treats a missing log as a failure, which is right, and
        # could not distinguish the two states without this. The header makes
        # every transcript self-describing and non-empty.
        #
        # It also has to be here for a duller reason worth writing down: an
        # empty file cannot be uploaded through GitHub's web upload form,
        # which is how this repository is pushed, so a zero-byte artefact
        # could never reach the remote that v37 needs it on.
        printf '# determinism type=%s (%d) pass=%s -- Praat output follows\n' \
            "$nm" "$i" "$pass" > "$OUT/${nm}_${pass}.log"
        ( cd "$SCRIPT_DIR" && EML_OUT="$p" timeout 300 "$PRAAT" $PRAAT_TRUST \
            --pref-dir="$PREFS" --run case.praat "$i" \
            >>"$OUT/${nm}_${pass}.log" 2>&1 )
    done

    if [[ ! -f "$a" || ! -f "$b" ]]; then
        printf '%-12s %-10s %s\n' "$nm" "NO_FIGURE" \
            "$(tail -2 "$OUT/${nm}_a.log" | tr '\n' ' ' | cut -c1-70)"
        emit_row "$nm" "NO_FIGURE" "$(bytes_of "$a")" "$(bytes_of "$b")" "NA"
        fail=$((fail + 1))
        continue
    fi

    sa=$(stat -c%s "$a")
    sb=$(stat -c%s "$b")
    if cmp -s "$a" "$b"; then
        printf '%-12s %-10s %s\n' "$nm" "STABLE" "$sa"
        emit_row "$nm" "STABLE" "$sa" "$sb" "0"
        continue
    fi

    # They differ. `compare` is optional -- it is not installed everywhere and
    # the verdict does not depend on it -- so the count is NA rather than 0
    # when it is absent. 0 means measured and equal, which two files that
    # failed `cmp` should never be; NA means not measured.
    d="NA"
    if command -v compare >/dev/null 2>&1; then
        px=$(compare -metric AE "$a" "$b" null: 2>&1 || true)
        px="${px%% *}"
        if [[ "$px" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
            d="$px"
        fi
    fi
    note=""
    [[ "$d" != "NA" ]] && note="  differing px: $d"
    printf '%-12s %-10s %s\n' "$nm" "VARIES" "$sa vs $sb$note"
    emit_row "$nm" "VARIES" "$sa" "$sb" "$d"
    fail=$((fail + 1))
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
