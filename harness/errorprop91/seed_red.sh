#!/usr/bin/env bash
# ============================================================================
# harness/errorprop91/seed_red.sh -- red demonstration for punch list 9.1,
#                                     sites 1, 2 and 4
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# Builds a COPY of the plugin with fixes_9_1.patch reverse-applied (`git
# apply -R`), then drives harness/errorprop91/driver.praat -- byte-identical
# to the committed one, not a rewritten copy -- against that reverted tree.
# driver.praat's own include lines ("../../plugin/stats/...") are written
# relative to ITS OWN location, so this script places a copy of the driver
# at the same relative depth inside the temp tree (temp/harness/errorprop91/
# driver.praat, temp/plugin -> temp/plugin_EML_StatsGraphs) rather than
# templating any path into the script.
#
#     bash harness/errorprop91/seed_red.sh
#
# Output: harness/errorprop91/out/red/report.txt (committed).
# ============================================================================
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
source "$REPO/harness/_env.sh"

T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT

cp -r "$REPO/plugin_EML_StatsGraphs" "$T/plugin_EML_StatsGraphs"
ln -s plugin_EML_StatsGraphs "$T/plugin"

PATCH="$HERE/fixes_9_1.patch"
(cd "$T" && git apply -R --unsafe-paths -p1 "$PATCH") || {
    echo "seed_red.sh: fixes_9_1.patch did not reverse-apply cleanly." >&2
    echo "  Either the source has drifted from what this patch describes," >&2
    echo "  or the fix in the working tree is not the one the patch names." >&2
    echo "  Re-derive the patch (git diff, pre-commit) before trusting a red run." >&2
    exit 3
}

mkdir -p "$T/harness/errorprop91/out/red"
cp "$HERE/driver.praat" "$T/harness/errorprop91/driver.praat"

OUT_REL="${1:-out/red}"
mkdir -p "$T/harness/errorprop91/$OUT_REL"
(cd "$T" && EML_ERRORPROP91_OUT="$OUT_REL" \
    "$PRAAT" $PRAAT_TRUST --run "harness/errorprop91/driver.praat")

mkdir -p "$HERE/out/red"
cp "$T/harness/errorprop91/$OUT_REL/report.txt" "$HERE/out/red/report.txt"
echo "wrote $HERE/out/red/report.txt (from the reverted tree)"
