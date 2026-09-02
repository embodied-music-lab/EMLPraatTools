#!/usr/bin/env bash
# ============================================================================
# harness/settingspub/break.sh -- what a replay answers when the settings do
# not reach it
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# THE RIG NEXT DOOR MEASURES A REPAIRED TREE, AND A GREEN MEASUREMENT ON A
# REPAIRED TREE IS NOT EVIDENCE THAT THE REPAIR IS LOAD-BEARING. This one
# builds a copy of the plugin with @emlRecordCaptureStats' call removed from
# @emlRecordStep -- the whole of the change, and nothing else -- and drives
# the same twelve legs against it.
#
# THE COPY IS A COPY. Nothing here edits the working tree and puts it back: a
# rig that did is one interrupted run away from committing the defect it was
# built to demonstrate.
#
# WHAT IT SHOWS. Every emitted script comes out with none of the three
# settings in it, and every replay answers with the seed
# @emlInitializeDrawingDefaults writes rather than with the session's choice:
#
#   the correction     bonferroni recorded, holm replayed
#   the alpha          .01 recorded, 95% intervals replayed
#   the group order    alphabetical recorded, discovery replayed, and every
#                      difference comes back with the opposite sign
#
# Run from anywhere:  bash harness/settingspub/break.sh
# Output: harness/settingspub/out/break/SETTINGSPUB.tsv
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

WORK="$(mktemp -d "${TMPDIR:-/tmp}/settingspub-break-XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
OUT="$SCRIPT_DIR/out/break"
rm -rf "$OUT"
mkdir -p "$OUT"

# The smallest tree the drive can run out of: the plugin, the folder name the
# includes are written against, and this rig's own two files.
mkdir -p "$WORK/harness/settingspub"
cp -r "$EML_ROOT/plugin_EML_StatsGraphs" "$WORK/plugin_EML_StatsGraphs"
ln -s plugin_EML_StatsGraphs "$WORK/plugin"
cp "$EML_ROOT/harness/_env.sh" "$WORK/harness/_env.sh"
cp "$SCRIPT_DIR/settingspub_drive.praat" "$WORK/harness/settingspub/"
cp "$SCRIPT_DIR/settingspub.sh" "$WORK/harness/settingspub/"

REC="$WORK/plugin_EML_StatsGraphs/stats/eml-record.praat"
python3 - "$REC" <<'PY'
import io, sys
p = sys.argv[1]
s = io.open(p, encoding="utf-8").read()
mark = '    if .kind$ = "analysis" or .kind$ = "draw"\n' \
       '        @emlRecordCaptureStats\n' \
       '        .codeOut$ = emlRecordCaptureStats.out$ + .codeOut$\n' \
       '    endif\n'
if mark not in s:
    sys.exit("break.sh: the call to remove is not in @emlRecordStep -- this "
             "script names the shape it reverts, so a rename is a failure "
             "here rather than a break test that quietly does nothing.")
io.open(p, "w", encoding="utf-8").write(s.replace(mark, "", 1))
PY
[[ $? -eq 0 ]] || exit 1

PRAAT="$PRAAT" EML_SP_SRC="$WORK" EML_SP_OUTDIR="$OUT" \
    bash "$WORK/harness/settingspub/settingspub.sh" || exit 1

echo "break: the settings each emitted script carries"
grep -c '_settingline' "$OUT/SETTINGSPUB.tsv" | sed 's/^/break: settingline rows /'
grep -E '_(session|replay)_(ci|sign)|_replay_adjust|_(session|replay)_p1' \
    "$OUT/SETTINGSPUB.tsv"

# AND THE CHECK IS RUN AGAINST IT, because a break test that only prints
# numbers leaves a reader to judge whether the validator would have caught
# them. It is pointed at the shadow tree's sources and the shadow tree's
# evidence, so nothing here reads the working tree.
echo "break: validate/v115 against the shadow tree"
EML_SP_DIR="$OUT" \
EML_SP_STATS_SRC="$WORK/plugin_EML_StatsGraphs/stats" \
EML_SP_GRAPH_SRC="$WORK/plugin_EML_StatsGraphs/graphs" \
    Rscript "$EML_ROOT/validate/v115_settings_publication.R" 2>&1 \
    | grep -E '^FAIL|checks,' | sed 's/^/break: /'
exit 0
