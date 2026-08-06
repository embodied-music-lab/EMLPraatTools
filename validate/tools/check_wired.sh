#!/usr/bin/env bash
# ============================================================================
# check_wired.sh -- a fix that no shipping script can reach is not a fix.
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# On 6 August 2026 sixteen findings were marked RESOLVED against code that no
# user could execute: eml-result-writer.praat was written, validated by 93
# checks, and included by nothing except a test harness. This script exists so
# that cannot happen silently again.
#
# It reports every module under plugin/stats/ and plugin/graphs/ that no
# script under plugin/scripts/ can reach, following the eml-lib*.praat
# barrels. Exit 1 if any module is unreachable.
# ============================================================================
set -u
cd "$(git rev-parse --show-toplevel)"

# Flatten what plugin/scripts/ actually loads, expanding the barrels.
reachable=$(mktemp)
expand() {
    local f=$1
    grep '^include ' "$f" 2>/dev/null | sed 's/^include //' | while read -r inc; do
        local t="plugin/scripts/$inc"
        t=$(realpath -m --relative-to=. "$t")
        echo "$t" >> "$reachable"
        case "$(basename "$t")" in eml-lib*) expand "$t" ;; esac
    done
}
for s in plugin/scripts/*.praat; do
    case "$(basename "$s")" in eml-lib*) continue ;; esac
    expand "$s"
done
sort -u "$reachable" -o "$reachable"

fail=0
for m in plugin/stats/*.praat plugin/graphs/*.praat; do
    if ! grep -qx "$m" "$reachable"; then
        echo "UNREACHABLE  $m  -- no script under plugin/scripts/ loads it"
        fail=1
    fi
done
rm -f "$reachable"

if [ $fail -eq 0 ]; then
    echo "all stats/ and graphs/ modules are reachable from plugin/scripts/"
fi
exit $fail
