#!/usr/bin/env bash
# ============================================================================
# harness/normalitycoverage/seed_wizard.sh -- red demonstration for v126,
#                                             wizard half (@wizardNormCheck)
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# Builds a COPY of the shipped plugin with @wizardNormCheck's coverage line
# and qualified recommendation deleted, and the skip case folded into the
# unconditional "parametric reasonable" recommendation -- the wizard-side
# twin of the standalone regression seed_standalone.sh builds. v126, run
# unmodified against this copy through $EML_NORMCOV_SRC, goes red on the
# WIZARD structural checks.
#
# Usage:
#   bash harness/normalitycoverage/seed_wizard.sh /path/to/out
#   EML_NORMCOV_SRC=/path/to/out/seed_wizard \
#       Rscript validate/v126_normality_coverage.R
# ============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUT="${1:-$SCRIPT_DIR/out}/seed_wizard"

rm -rf "$OUT"
mkdir -p "$(dirname "$OUT")"
cp -r "$ROOT/plugin_EML_StatsGraphs" "$OUT"

F="$OUT/scripts/eml-wizard.praat"
python3 - "$F" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()

old_cov = '''            if .nGroupsIncomplete
                appendInfoLine: "  Assessed ", .nAssessed, " of ",
                ... emlCountGroups.nGroups, " groups; ", .skipList$, "."
                appendInfoLine: ""
            endif'''
assert old_cov in s, "coverage print block not found verbatim -- has it moved?"
s = s.replace(old_cov, "", 1)

old_rec = '''        if .mode$ = "group" and .nGroupsIncomplete
            # Coverage was incomplete: the recommendation says so rather
            # than generalising over a group it never tested. Language
            # batch item 13, verbatim.
            appendInfoLine: "  Recommendation: parametric test is "
            ... + "reasonable, based on the groups large enough to test."
        else
            appendInfoLine: "  Recommendation: parametric test is "
            ... + "reasonable"
        endif'''
new_rec = '''        appendInfoLine: "  Recommendation: parametric test is "
        ... + "reasonable"'''
assert old_rec in s, "recommendation block not found verbatim -- has it moved?"
s = s.replace(old_rec, new_rec, 1)

open(p, 'w').write(s)
PY

echo "normalitycoverage: seeded wizard regression at $OUT"
