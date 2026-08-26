#!/usr/bin/env bash
# ============================================================================
# harness/corrscope/run.sh -- drive the scatter scope probe, RED then GREEN
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# Runs harness/corrscope/probe.praat against the shipped tree and writes
# out/CORRSCOPE.tsv. With --red it runs the SAME probe against the tree as
# it stood at HEAD (git show), before item 8.3's drawing-layer change, and
# writes out/CORRSCOPE_RED.tsv instead -- the demonstration that the three
# scopes were indistinguishable before this item, committed and reusable
# rather than pasted into a chat and thrown away. See probe.praat's own
# header for what "indistinguishable" means here.
#
#   bash harness/corrscope/run.sh          # GREEN: shipped tree
#   bash harness/corrscope/run.sh --red    # RED: tree at HEAD (pre-8.3)
#   Rscript validate/v137_correlation_scope.R
#
# $EML_CORRSCOPE_OUT overrides the evidence path.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$SCRIPT_DIR/.." && pwd)/_env.sh" || exit 1

MODE="${1:-}"
OUT_DIR="$SCRIPT_DIR/out"
mkdir -p "$OUT_DIR"

if [[ "$MODE" == "--red" ]]; then
    # The pre-8.3 draw-procedures file, straight out of git, in a private
    # work copy -- never the shipped tree, which stays untouched. Laid out
    # at harness/corrscope's own depth (work_red/harness/corrscope/probe.praat,
    # plugin at work_red/plugin) so probe.praat's relative includes
    # (../../plugin/...) resolve unedited -- the same twin-tree discipline
    # harness/correlgroup and harness/regressiongroup use.
    WORK="$OUT_DIR/work_red"
    rm -rf "$WORK"
    mkdir -p "$WORK/plugin" "$WORK/harness/corrscope"
    cp -R "$EML_ROOT/plugin_EML_StatsGraphs"/. "$WORK/plugin"/
    if ! git -C "$EML_ROOT" show HEAD:plugin_EML_StatsGraphs/graphs/eml-draw-procedures.praat \
        > "$WORK/plugin/graphs/eml-draw-procedures.praat" 2>"$WORK/git_err.txt"; then
        echo "corrscope --red: could not read HEAD's eml-draw-procedures.praat" >&2
        cat "$WORK/git_err.txt" >&2
        exit 1
    fi
    cp "$SCRIPT_DIR/probe.praat" "$WORK/harness/corrscope/probe.praat"
    OUT_TSV="$OUT_DIR/CORRSCOPE_RED.tsv"
    rm -f "$OUT_TSV"
    ( cd "$WORK/harness/corrscope" && env -u DISPLAY EML_CORRSCOPE_OUT="$OUT_TSV" \
        timeout 120 "$PRAAT" $PRAAT_TRUST --run "probe.praat" \
        > "$OUT_DIR/RED_RUN.log" 2>&1 )
    rc=$?
    if [[ $rc -ne 0 || ! -s "$OUT_TSV" ]]; then
        echo "corrscope --red: praat exited $rc; see $OUT_DIR/RED_RUN.log" >&2
        exit 1
    fi
    echo "corrscope --red: wrote $OUT_TSV ($(wc -l < "$OUT_TSV") lines)"
    exit 0
fi

OUT_TSV="${EML_CORRSCOPE_OUT:-$OUT_DIR/CORRSCOPE.tsv}"
rm -f "$OUT_TSV"
( cd "$SCRIPT_DIR" && env -u DISPLAY EML_CORRSCOPE_OUT="$OUT_TSV" \
    timeout 120 "$PRAAT" $PRAAT_TRUST --run "probe.praat" \
    > "$OUT_DIR/RUN.log" 2>&1 )
rc=$?
if [[ $rc -ne 0 || ! -s "$OUT_TSV" ]]; then
    echo "corrscope: praat exited $rc; see $OUT_DIR/RUN.log" >&2
    tail -20 "$OUT_DIR/RUN.log" >&2
    exit 1
fi
echo "corrscope: wrote $OUT_TSV ($(wc -l < "$OUT_TSV") lines)"
