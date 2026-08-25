#!/usr/bin/env bash
# ============================================================================
# harness/orderpersist/seed_persist.sh -- red demonstration for v125,
#                                         session-only persistence half
#                                         (punch 2.3)
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# Builds a COPY of the shipped plugin with the pre-fix config-file carryover
# restored: a "groupSort" key re-added to both @emlLoadConfig and
# @emlSaveConfig, and the session-only sessionGroupSort restore deleted from
# @emlGraphsWorkflow. v125, run unmodified against this copy through
# $EML_ORDER_SRC, goes red on all four persistence checks.
#
# Usage:
#   bash harness/orderpersist/seed_persist.sh /path/to/out
#   EML_ORDER_SRC=/path/to/out/seed_persist \
#       Rscript validate/v125_group_order_persistence.R
# ============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUT="${1:-$SCRIPT_DIR/out}/seed_persist"

rm -rf "$OUT"
mkdir -p "$(dirname "$OUT")"
cp -r "$ROOT/plugin_EML_StatsGraphs" "$OUT"

F="$OUT/graphs/eml-graphs-form.praat"
python3 - "$F" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()

marker = '                    ; NO "groupSort" KEY, ON PURPOSE.'
inject_load = ('                    elsif .key$ = "groupSort"\n'
               '        @emlConfigFlag: .value$\n'
               '        config_groupSort = emlConfigFlag.v\n')
assert marker in s, "load marker not found -- has emlLoadConfig moved?"
s = s.replace(marker, inject_load + marker, 1)

save_marker = '    ; GROUP ORDER IS NOT WRITTEN HERE.'
inject_save = '    appendFileLine: .configPath$, "groupSort: ", config_groupSort\n'
assert save_marker in s, "save marker not found -- has emlSaveConfig moved?"
s = s.replace(save_marker, inject_save + save_marker, 1)

restore_block = ('    if variableExists ("sessionGroupSort")\n'
                  '        config_groupSort = sessionGroupSort\n'
                  '    endif\n')
assert restore_block in s, "restore block not found verbatim -- has it moved?"
s = s.replace(restore_block, '', 1)

open(p, 'w').write(s)
PY

echo "orderpersist: seeded config-carryover regression at $OUT"
