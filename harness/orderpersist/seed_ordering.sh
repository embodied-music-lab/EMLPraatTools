#!/usr/bin/env bash
# ============================================================================
# harness/orderpersist/seed_ordering.sh -- red demonstration for v125,
#                                          ordering-clause half (punch 2.2)
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# Builds a COPY of the shipped plugin with every @emlReportGroupOrderLine
# call site deleted -- the exact regression v125 exists to catch: the
# ordering clause silently disappears from a grouped-comparison report while
# everything else about the report stays correct. v125, run unmodified
# against this copy through $EML_ORDER_SRC, goes red on
# "every grouped-comparison report calls @emlReportGroupOrderLine".
#
# Usage:
#   bash harness/orderpersist/seed_ordering.sh /path/to/out
#   EML_ORDER_SRC=/path/to/out/seed_ordering \
#       Rscript validate/v125_group_order_persistence.R
# ============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUT="${1:-$SCRIPT_DIR/out}/seed_ordering"

rm -rf "$OUT"
mkdir -p "$(dirname "$OUT")"
cp -r "$ROOT/plugin_EML_StatsGraphs" "$OUT"

sed -i '/@emlReportGroupOrderLine: \.groupList\$/d' \
    "$OUT/stats/eml-analysis.praat" \
    "$OUT/graphs/eml-annotation-procedures.praat"

echo "orderpersist: seeded ordering-clause regression at $OUT"
