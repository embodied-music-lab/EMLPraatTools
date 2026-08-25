#!/usr/bin/env bash
# ============================================================================
# harness/normalitycoverage/seed_standalone.sh -- red demonstration for v126,
#                                                 standalone checker half
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# Builds a COPY of the shipped plugin with the standalone checker's coverage
# guard collapsed: the unconditional "no group in this column shows a strong
# departure" line is made to print regardless of whether every group was
# assessed -- the exact pre-5.1 regression, printing a generalisation over a
# group the run never examined. v126, run unmodified against this copy
# through $EML_NORMCOV_SRC, goes red on the STANDALONE structural checks.
#
# Usage:
#   bash harness/normalitycoverage/seed_standalone.sh /path/to/out
#   EML_NORMCOV_SRC=/path/to/out/seed_standalone \
#       Rscript validate/v126_normality_coverage.R
# ============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUT="${1:-$SCRIPT_DIR/out}/seed_standalone"

rm -rf "$OUT"
mkdir -p "$(dirname "$OUT")"
cp -r "$ROOT/plugin_EML_StatsGraphs" "$OUT"

F="$OUT/scripts/eml-check-normality.praat"
python3 - "$F" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()

old = '''            if .allGroupsOK
                if .nAssessed < emlCountGroups.nGroups
                    # COVERAGE was incomplete: at least one group was too
                    # small to test and never examined. "no group ... shows
                    # a strong departure" is a claim about every group in
                    # the column; this loop did not examine all of them, so
                    # that claim is false about the data in front of the
                    # reader. Language batch item 13, verbatim.
                    appendInfoLine: "  Summary: No strong departure in the"
                    ... + " groups large enough to test (",
                    ... .nAssessed, " of ", emlCountGroups.nGroups,
                    ... " assessed)."
                else
                    appendInfoLine: "  Summary: no group in this column shows a"
                    ... + " strong departure"
                endif
            else'''
new = '''            if .allGroupsOK
                appendInfoLine: "  Summary: no group in this column shows a"
                ... + " strong departure"
            else'''
assert old in s, "coverage guard block not found verbatim -- has it moved?"
s = s.replace(old, new, 1)
open(p, 'w').write(s)
PY

echo "normalitycoverage: seeded standalone-checker regression at $OUT"
