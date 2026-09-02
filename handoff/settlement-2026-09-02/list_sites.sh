#!/usr/bin/env bash
# Print every current site of the six retired names, and what the scope file
# says to do about each. Run from anywhere; paths resolve to the repo root.
#
# THE SCOPE COMES FROM RENAME_SCOPE.tsv AND IS NOT RESTATED HERE. Before that
# file existed this script, v159, the inventory grep and the work order each
# carried their own copy of the exemption set, and they disagreed: the
# inventory's grep searched four extensions and missed sixteen shell scripts.
# RULING_RENAME_SCOPE_2026-09-02.md orders the scope stated once.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 1

SCOPE="RENAME_SCOPE.tsv"
[ -f "$SCOPE" ] || { echo "missing $SCOPE — the scope is defined there" >&2; exit 1; }

# disposition_for <path> — first matching row wins; unmatched is RENAME.
disposition_for() {
    local p="$1" pat disp
    while IFS=$'\t' read -r pat disp _; do
        case "$pat" in ''|'#'*|pattern) continue ;; esac
        [ -z "$pat" ] && continue
        case "$p" in *"$pat"*) printf '%s' "$disp"; return ;; esac
    done < "$SCOPE"
    printf 'RENAME'
}

NAMES=$(awk -F'|' 'NR>0' /dev/null; echo "emlRunKWAnalysis emlRunGroupedRegression emlBridgeGroupComparison emlGraphsMeltSeries emlGraphsPivotSeries emlInitDrawingDefaults")

declare -A COUNT
total_rename=0
for n in $NAMES; do
    echo "=== ${n}"
    while IFS= read -r f; do
        [ -z "$f" ] && continue
        rel="${f#./}"
        d="$(disposition_for "$rel")"
        COUNT[$d]=$(( ${COUNT[$d]:-0} + 1 ))
        [ "$d" = "RENAME" ] && { echo "    $rel"; total_rename=$((total_rename+1)); }
    done < <(grep -rl "\b${n}\b" . --exclude-dir=.git 2>/dev/null)
    echo
done

echo "files to RENAME (the work): ${total_rename}"
echo "by disposition, across all six names:"
for d in RENAME REGENERATE UNTOUCHED OUT_OF_SCOPE; do
    printf '  %-14s %s\n' "$d" "${COUNT[$d]:-0}"
done
echo
echo "Dispositions come from RENAME_SCOPE.tsv. REGENERATE files are rebuilt by"
echo "their generators after the rename, never hand-edited. UNTOUCHED and"
echo "OUT_OF_SCOPE files keep their words."
