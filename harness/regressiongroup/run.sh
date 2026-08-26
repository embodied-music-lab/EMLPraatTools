#!/usr/bin/env bash
# ============================================================================
# harness/regressiongroup/run.sh -- drive the per-group regression probe
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# Runs harness/regressiongroup/probe.praat and leaves REGGROUP.tsv beside it.
# The probe needs no display -- it calls @emlRunGroupedRegression directly
# (stats/eml-analysis.praat), the same call both eml-regress.praat and
# eml-wizard.praat now make, on a fixed fixture; it draws nothing and opens
# no dialog. See probe.praat's own header for what the fixture is and why.
#
#   $EML_REGGROUP_OUT   artefact to write   (default: out/REGGROUP.tsv)
#
# validate/v135_regression_grouping.R reads that path.
#
#   bash harness/regressiongroup/run.sh
#   Rscript validate/v135_regression_grouping.R
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

OUT="${EML_REGGROUP_OUT:-$SCRIPT_DIR/out/REGGROUP.tsv}"
mkdir -p "$(dirname "$OUT")"

EML_REGGROUP_OUT="$OUT" "$PRAAT" $PRAAT_TRUST --run "$SCRIPT_DIR/probe.praat"
rc=$?
if [ $rc -ne 0 ]; then
    echo "regressiongroup/run.sh: praat exited $rc" >&2
    exit $rc
fi
echo "regressiongroup/run.sh: wrote $OUT ($(wc -l < "$OUT") lines)"
