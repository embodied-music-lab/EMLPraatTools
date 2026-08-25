#!/usr/bin/env bash
# ============================================================================
# harness/normalitycoverage/seed_standalone_evidence.sh -- red demonstration
#     for v126's EVIDENCE-reading assertions (section 2)
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS EXISTS SEPARATELY FROM seed_standalone.sh. That script seeds the
# SOURCE regression and is what v126's STATIC checks (section 1) go red
# against. Section 2 reads a committed artefact
# (harness/normality/out/pergroup/p01_groups_grouped.txt) rather than driving
# anything -- by design, since that branch is inline GUI-only code
# (pergroup.sh's own header explains why `praat --run` cannot reach it) and
# re-driving it against a seeded tree would mean replicating the whole rig
# (rig.sh, d117/lib.sh, the fixture CSV, a live Xvfb instance) for one file.
#
# What this script produces instead is the artefact seed_standalone.sh's
# regression WOULD have written, derived MECHANICALLY from the real captured
# evidence: the only change seed_standalone.sh makes is collapsing the
# `if .nAssessed < ... else` guard around the Summary line, so the coverage-
# qualified sentence is replaced by the unconditional one and nothing else in
# the Info window moves -- same groups, same W, same p, same skip line. That
# substitution is applied here with sed, not retyped by hand, so this file
# cannot drift from what the real evidence says everywhere but the one line
# the seeded source changes.
#
# Usage:
#   bash harness/normalitycoverage/seed_standalone_evidence.sh
#   EML_NORMCOV_EVIDENCE=harness/normalitycoverage/out/seed_standalone_evidence \
#       Rscript validate/v126_normality_coverage.R
# ============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SRC="$ROOT/harness/normality/out/pergroup"
OUT="$SCRIPT_DIR/out/seed_standalone_evidence"

mkdir -p "$OUT"
for f in "$SRC"/*_grouped.txt "$SRC"/*_overall.txt; do
    [ -f "$f" ] || continue
    sed 's/Summary: No strong departure in the groups large enough to test ([0-9]* of [0-9]* assessed)\./Summary: no group in this column shows a strong departure/' \
        "$f" > "$OUT/$(basename "$f")"
done

echo "normalitycoverage: seeded evidence (collapsed-guard Summary line) at $OUT"
