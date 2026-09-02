#!/usr/bin/env bash
# Print every current site of the six retired names, excluding the record
# directories and the generated harness output. Run from the repository root.
set -u
cd "$(dirname "$0")/../.." || exit 1

NAMES="emlRunKWAnalysis emlRunGroupedRegression emlBridgeGroupComparison
       emlGraphsMeltSeries emlGraphsPivotSeries emlInitDrawingDefaults"

total=0
for n in $NAMES; do
    files=$(grep -rl "\b${n}\b" . \
              --exclude-dir=.git --exclude-dir=mailbox --exclude-dir=audit \
              --exclude-dir=handoff 2>/dev/null \
            | grep -v '/out/\|/replay_out/\|/stress_out/\|/qq_out/')
    n_files=$(printf '%s\n' "$files" | grep -c . || true)
    echo "=== ${n} — ${n_files} file(s)"
    printf '%s\n' "$files" | grep . | sed 's|^\./|    |'
    total=$((total + n_files))
    echo
done
echo "total file-touches: ${total}"
echo
echo "generated directories to regenerate rather than edit:"
grep -rl "emlRunKWAnalysis\|emlBridgeGroupComparison\|emlInitDrawingDefaults" . \
     --exclude-dir=.git 2>/dev/null \
  | grep '/out/\|/replay_out/\|/stress_out/\|/qq_out/' \
  | awk -F/ '{print "    "$2"/"$3}' | sort -u
