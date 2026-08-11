#!/usr/bin/env bash
# ============================================================================
# parity/run.sh — does the figure exclude the rows the analysis excludes?
# ============================================================================
# Renders seven draw procedures over a clean and a dirty fixture and writes
# harness/parity/out/PARITY.tsv:
#
#     name  dirty  figureSkipped  statsExcluded  MATCH|MISMATCH
#
# validate/v33_exclusion_parity.R asserts on that file. Both numbers are
# produced by the plugin's own procedures -- see case.praat for why neither
# is recomputed on the R side.
#
# Run from anywhere:  bash harness/parity/run.sh
# Exit 0 = every row MATCHed.
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$SCRIPT_DIR/.." && pwd)/_env.sh" || exit 1
OUT="$SCRIPT_DIR/out"
PREFS="$SCRIPT_DIR/prefs"
mkdir -p "$OUT" "$PREFS"
TSV="$OUT/PARITY.tsv"
rm -f "$TSV"

( cd "$SCRIPT_DIR" && EML_PARITY_TSV="$TSV" timeout 300 "$PRAAT" $PRAAT_TRUST \
    --pref-dir="$PREFS" --run case.praat >"$OUT/parity.log" 2>&1 )

if [[ ! -f "$TSV" ]]; then
    echo "parity: FAIL — no TSV produced"
    tail -20 "$OUT/parity.log"
    exit 1
fi

printf '%-11s %-6s %-9s %-9s %s\n' name dirty figure stats verdict
awk -F'\t' '{printf "%-11s %-6s %-9s %-9s %s\n", $1, $2, $3, $4, $5}' "$TSV"

bad=$(awk -F'\t' '$5 != "MATCH"' "$TSV" | wc -l)
rows=$(wc -l < "$TSV")
# The dirty half must actually exclude something, or the whole file is a
# comparison of zero against zero and would pass with both readers broken.
dirtyzero=$(awk -F'\t' '$2 == 1 && $3 == 0' "$TSV" | wc -l)
# ...and the dirty half must EXIST. Without this the file passed while the
# case script aborted before the dirty pass ever ran: zero dirty rows means
# zero dirty rows with nothing excluded, which read as success. Caught on the
# first run of this harness, 11 Aug 2026.
dirtyrows=$(awk -F'\t' '$2 == 1' "$TSV" | wc -l)

echo
if [[ "$bad" -eq 0 && "$dirtyzero" -eq 0 && "$dirtyrows" -gt 0 ]]; then
    echo "parity: PASS — $rows/$rows agree, and the dirty half excludes rows"
    echo "        (Praat $("$PRAAT" --version 2>&1 | head -1))"
    exit 0
fi
[[ "$bad" -gt 0 ]] && echo "parity: FAIL — $bad of $rows disagree"
[[ "$dirtyzero" -gt 0 ]] && echo "parity: FAIL — $dirtyzero dirty case(s) excluded nothing;" \
    "the fixture is not exercising the readers"
[[ "$dirtyrows" -eq 0 ]] && echo "parity: FAIL — no dirty cases at all; the case script" \
    "did not reach the dirty pass. See out/parity.log."
exit 1
