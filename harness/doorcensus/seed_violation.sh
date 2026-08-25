#!/usr/bin/env bash
# ============================================================================
# harness/doorcensus/seed_violation.sh -- the committed red demonstration
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS PROVES.
#
# validate/v127_door_agreement_census.R reads GREEN today because it
# correctly names four of six legs SILENT DISAGREEMENT -- a true reading of
# the shipped tree, not an all-clear. That "green" is itself the thing a
# reader has to trust, so this script demonstrates that the check is
# CAPABLE of going red: it makes a COPY of the plugin with the regression
# dialog's call site changed to pass a group column --
# scripts/eml-regress.praat's @emlRunRegressionAnalysis call gains a
# fourth argument -- which is exactly what landing the per-group port
# (WORK_ORDER_DOOR_CENSUS.md section 3) will look like from this file's
# point of view: the leg5 structural check
# ("the regression dialog's own call carries tableId/respCol$/predCol$
# only, no group column") stops being true, and the check goes red on
# purpose, because the LEDGER in v127 still says leg5 is SILENT and no one
# has updated it to AGREE. That is the ratchet v111/v112 use, run here:
# a fix landing without its ledger row being updated is exactly the
# failure this file exists to catch.
#
# $EML_DOORCENSUS_SRC is the same variable harness/doorcensus/run.sh and
# validate/v127's structural greps both take, so pointing it at the seeded
# copy is the one thing this script does.
#
#   bash harness/doorcensus/seed_violation.sh
#   EML_DOORCENSUS_SRC=<the path it prints> Rscript validate/v127_door_agreement_census.R
#
# What goes red is v127's own leg5 assertion, over a COPY; nothing here
# touches the shipped tree.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../_env.sh"

SEED_ROOT="${EML_DOORCENSUS_SEED_DIR:-$(mktemp -d)}"
DEST="$SEED_ROOT/plugin_EML_StatsGraphs"
rm -rf "$DEST"
mkdir -p "$DEST"
cp -R "$EML_ROOT/plugin_EML_StatsGraphs/." "$DEST/"

TARGET="$DEST/scripts/eml-regress.praat"
if ! grep -q '@emlRunRegressionAnalysis: tableId, respCol\$, predCol\$' "$TARGET"; then
    echo "seed_violation.sh: the call site this seed edits has moved;" >&2
    echo "  re-derive the seed against the current line before trusting it." >&2
    exit 1
fi

# THE SEEDED VIOLATION: exactly one line, adding the group column the
# dialog already reads (groupCol$) to the analysis call -- the shape the
# real per-group port is expected to take.
sed -i \
    's/@emlRunRegressionAnalysis: tableId, respCol\$, predCol\$/@emlRunRegressionAnalysis: tableId, respCol$, predCol$, groupCol$/' \
    "$TARGET"

if ! grep -q '@emlRunRegressionAnalysis: tableId, respCol\$, predCol\$, groupCol\$' "$TARGET"; then
    echo "seed_violation.sh: the sed did not take; nothing was seeded." >&2
    exit 1
fi

echo "seed_violation.sh: seeded a copy at $SEED_ROOT"
echo "  EML_DOORCENSUS_SRC=$SEED_ROOT Rscript validate/v127_door_agreement_census.R"
echo "  expected: leg5's VERDICT check goes red -- the source no longer"
echo "  matches this file's declared ledger row for it."
