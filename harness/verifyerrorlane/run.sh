#!/usr/bin/env bash
# ============================================================================
# harness/verifyerrorlane/run.sh -- does a real failure name its own cause?
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# Punch list 9.2/9.3 are measured by a lint (validate/v134). A lint going
# green proves the SHAPE of a call site. This asks the other question -- break
# two swept sites FOR REAL and read what comes out.
#
# probe2.praat is the file that matters: it drives the real orchestrators
# (@emlRunTwoGroupAnalysis, @emlRunAnovaAnalysis, @emlRunKWAnalysis) and the
# graph bridge (@emlBridgeGroupComparison) with (a) a column that does not
# exist and (b) a data column holding one non-numeric cell.
# probe.praat drives the two-group door end to end plus, for the record, the
# annotation-layer reporters called directly -- see its own header for why
# that last one is not a finding.
# getgroup_probe.praat settles a contradiction between two comments in
# @emlRunTwoGroupAnalysis about what @eml_getGroupData does with a missing
# column.
#
#   bash harness/verifyerrorlane/run.sh
#
# Evidence: out/<case>.txt, one per case, the Info window verbatim.
# ============================================================================
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$SCRIPT_DIR/.." && pwd)/_env.sh" || exit 1
cd "$SCRIPT_DIR"
mkdir -p out

for c in anova_missing anova_nonnumeric kw_missing kw_groupmissing \
         audit_nonnumeric bridge_missing bridge_nonnumeric; do
    EML_VERIFYERR_CASE="$c" "$PRAAT" $PRAAT_TRUST --run probe2.praat \
        > "out/$c.txt" 2>&1
    printf '%-20s %s\n' "$c" "$(grep -m1 -E 'error=\[|bridge error=\[' "out/$c.txt")"
done

EML_VERIFYERR_OUT=out "$PRAAT" $PRAAT_TRUST --run probe.praat > out/console.txt 2>&1
"$PRAAT" $PRAAT_TRUST --run getgroup_probe.praat > out/getgroupdata.txt 2>&1
echo "verifyerrorlane: wrote out/"
