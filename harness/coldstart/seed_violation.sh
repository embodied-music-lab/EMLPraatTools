#!/usr/bin/env bash
# ============================================================================
# harness/coldstart/seed_violation.sh — the red demonstration for v111
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# WHAT THIS PROVES, and why a check without it is not finished.
#
# validate/v111_cold_start_census.R is a census: every assertion in it reads
# "for every leg in the evidence ...". Every one of those is TRUE of a file
# with no legs in it, so the check's characteristic failure is not a wrong
# answer — it is a green run over an artefact that says nothing. v111 answers
# half of that itself, with a resolver gate that fails on an empty or partial
# walk and prints how many entry points it covered. This file answers the
# other half: it shows the check going RED when the plugin actually does the
# thing the check forbids.
#
# NOTHING IN THE SHIPPED TREE IS TOUCHED. The plugin is COPIED, the violation
# is seeded into the copy, and run.sh is pointed at the copy with
# $EML_COLDSTART_SRC — the variable it already takes for exactly this. v111 is
# pointed at the copy's evidence with $EML_COLDSTART_OUT, the same variable
# run.sh writes to. So both ends follow one setting, run.sh and v111 are used
# UNMODIFIED, and what goes red is the check rather than a rehearsal of it.
#
# THE VIOLATION IS THE REAL ONE. Ian's crash was a wrapper reaching for the
# selection before the guard that refuses an empty selection had run: with
# nothing selected Praat raises over a form the user has just answered, and
# the script stops. Seeded here as one line inserted into
# scripts/eml-describe-table.praat immediately BEFORE
# @emlDescribeCoerceSelection — its guard — so the copy asks the Objects
# window for a row count that no selected object can supply:
#
#     emlSeedRows = Get number of rows
#
# Written as a statement with the result assigned, because in Praat a command
# is a statement and not an expression; `if (Get number of rows) > 0` would
# fail to compile for a different reason and prove something else.
#
# Only the legs the seed can reach are re-driven. run.sh's subset mode
# replaces those legs' rows and leaves the rest of the artefact alone, which
# is what makes a one-leg demonstration honest: every other verdict in the
# file is the real drive's, so the red that appears is the seeded leg's and
# nothing else has been disturbed to produce it.
#
# Usage:  bash harness/coldstart/seed_violation.sh
#         EML_COLDSTART_SEED_DIR=/somewhere  bash .../seed_violation.sh
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

SEED_DIR="${EML_COLDSTART_SEED_DIR:-/tmp/eml-coldstart-seed}"
SEED_TREE="$SEED_DIR/plugin_EML_StatsGraphs"
SEED_OUT="$SEED_DIR/out"
TARGET="scripts/eml-describe-table.praat"
LEG="e_describe"

# THE REAL EVIDENCE HAS TO EXIST FIRST. The seeded artefact is a COPY of it
# with one leg re-driven, so that the other thirty-four verdicts in the file
# are the genuine drive's. Without that, a red result would only show that
# v111 dislikes a nearly empty file — which its resolver gate already says.
[ -f "$SCRIPT_DIR/out/COLDSTART.tsv" ] || {
    echo "seed_violation: REFUSED — no real drive at $SCRIPT_DIR/out/COLDSTART.tsv." >&2
    echo "  Run: bash harness/coldstart/run.sh" >&2
    exit 2; }

rm -rf "$SEED_DIR"
mkdir -p "$SEED_DIR"
cp -a "$ROOT/plugin_EML_StatsGraphs" "$SEED_TREE"
cp -a "$SCRIPT_DIR/out" "$SEED_OUT"

# ---- seed it ---------------------------------------------------------------
# Anchored on the GUARD, not on a line number. A line number in a seeding
# script is a silent no-op the first time the file above it grows: the copy
# stays clean, the drive comes back green, and the demonstration reports that
# the check cannot be made to fail.
GUARD='@emlDescribeCoerceSelection'
grep -q "^$GUARD" "$SEED_TREE/$TARGET" || {
    echo "seed_violation: REFUSED — '$GUARD' is no longer the first guard in" >&2
    echo "  $TARGET. Re-anchor this script rather than seeding nothing." >&2
    exit 2; }

python3 - "$SEED_TREE/$TARGET" "$GUARD" <<'PY'
import io, sys
path, guard = sys.argv[1], sys.argv[2]
lines = io.open(path, encoding='utf-8').read().split('\n')
for i, ln in enumerate(lines):
    if ln.startswith(guard):
        lines.insert(i, '; --- SEEDED VIOLATION (harness/coldstart/seed_violation.sh) ---')
        lines.insert(i + 1, 'emlSeedRows = Get number of rows')
        break
else:
    sys.exit('guard vanished between the check and the edit')
io.open(path, 'w', encoding='utf-8').write('\n'.join(lines))
PY

echo "seed_violation: seeded '$TARGET' in $SEED_TREE"
sed -n "/SEEDED VIOLATION/,+1p" "$SEED_TREE/$TARGET" | sed 's/^/    /'
echo

# ---- drive the seeded tree, with run.sh UNMODIFIED -------------------------
# A display base well clear of the shipped drive's, so a demonstration run
# started while something else is driving does not have to wait for it.
EML_COLDSTART_SRC="$SEED_TREE" \
EML_COLDSTART_OUT="$SEED_OUT" \
EML_COLDSTART_DISPLAY_BASE="${EML_COLDSTART_DISPLAY_BASE:-180}" \
    bash "$SCRIPT_DIR/run.sh" "$LEG"
rc=$?
[ "$rc" -eq 0 ] || { echo "seed_violation: the seeded drive failed (rc=$rc)" >&2; exit "$rc"; }

echo
echo "seed_violation: the seeded leg recorded:"
awk -F'\t' -v leg="$LEG" '$1 == leg { printf "    %-10s %s\n", $2, $3 }' \
    "$SEED_OUT/COLDSTART.tsv"
echo
echo "Now read that artefact with v111, unmodified:"
echo
echo "    EML_COLDSTART_OUT=$SEED_OUT Rscript validate/v111_cold_start_census.R"
echo
