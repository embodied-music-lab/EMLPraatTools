#!/usr/bin/env bash
# ============================================================================
# harness/normality/site3_drive.sh -- red/green demonstration for punch list
#                                     9.1, SITE 3 (Shapiro-Wilk printed as
#                                     undefined in the standalone checker's
#                                     per-group mode)
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# scripts/eml-check-normality.praat's per-group branch is inline in a wrapper
# whose first statement is `beginPause:`, which `praat --run` cannot open at
# all (harness/normality/pergroup.sh's own header, confirmed again here).
# This drives a REAL GUI instance instead, self-contained and NOT through
# harness/walks/rig.sh's shared instances 1-3 or its $REPO/plugin symlink --
# five lanes run this turn, and this script must not disturb any of them. It
# brings up its own throwaway instance (default :98) with its own prefs dir.
#
# pergroup_case.praat's `runScript: "../../plugin/scripts/eml-check-normality
# .praat"` is written relative to ITS OWN location (Praat resolves `include`/
# `runScript` against the TOP-LEVEL script's folder), so the red half places
# a COPY of it -- byte-identical, not rewritten -- two directories below a
# `plugin` symlink pointed at the reverted tree, mirroring the real
# repo layout closely enough for that one relative path to resolve into the
# seed instead. The green half runs the committed file in place.
#
# The fixture is the r03_identical case already committed by
# harness/normality/case.praat / run.sh (10 rows, all 7.5 -- zero range) with
# its grp column "All" in every row, so per-group mode analyses ONE group of
# n = 10 >= 3 -- assessed, not skipped -- and Shapiro-Wilk errors on it
# ("All values identical (zero range)", stats/eml-core-descriptive.praat).
#
#     bash harness/normality/site3_drive.sh green   # real plugin, fixed
#     bash harness/normality/site3_drive.sh red     # fix_9_1_site3.patch
#                                                    # reverse-applied
#
# Output: harness/normality/out/site3/{green,red}.txt (committed).
# ============================================================================
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
source "$REPO/harness/_env.sh"

MODE="${1:?usage: site3_drive.sh red|green}"
CSV="$HERE/out/data/r03_identical.csv"
[ -s "$CSV" ] || { echo "site3_drive.sh: $CSV missing -- run harness/normality/run.sh first" >&2; exit 2; }

CLEANUP=""
case "$MODE" in
    green)
        CASE_SCRIPT="$HERE/pergroup_case.praat"
        ;;
    red)
        T="$(mktemp -d)"
        CLEANUP="$T"
        cp -r "$REPO/plugin_EML_StatsGraphs" "$T/plugin_EML_StatsGraphs"
        ln -s plugin_EML_StatsGraphs "$T/plugin"
        (cd "$T" && git apply -R --unsafe-paths -p1 "$HERE/fix_9_1_site3.patch") || {
            echo "site3_drive.sh: fix_9_1_site3.patch did not reverse-apply cleanly." >&2
            echo "  The source has drifted from what this patch describes -- re-derive it." >&2
            rm -rf "$T"
            exit 3
        }
        mkdir -p "$T/harness/normality"
        cp "$HERE/pergroup_case.praat" "$T/harness/normality/pergroup_case.praat"
        CASE_SCRIPT="$T/harness/normality/pergroup_case.praat"
        ;;
    *) echo "usage: site3_drive.sh red|green" >&2; exit 2 ;;
esac
cleanup () { [ -n "$CLEANUP" ] && rm -rf "$CLEANUP"; }
trap cleanup EXIT

I=${I:-8}
D=":9$I"
RIG="${TMPDIR:-/tmp}/eml-rig-site3"
GEOM=1280x900x24
mkdir -p "$RIG/log"
PREFS="$RIG/prefs_$I"
mkdir -p "$PREFS"
rm -f "/tmp/.X9$I-lock" "/tmp/.X11-unix/X9$I" "$PREFS/pid" "$PREFS/message"

echo "site3_drive.sh: bringing up throwaway instance $I ($D), case script=$CASE_SCRIPT"
setsid nohup Xvfb "$D" -screen 0 "$GEOM" > "$RIG/log/xvfb_$I.log" 2>&1 &
sleep 2
DISPLAY=$D setsid nohup openbox  > "$RIG/log/wm_$I.log" 2>&1 &
DISPLAY=$D setsid nohup xcompmgr > "$RIG/log/xc_$I.log" 2>&1 &
sleep 1

teardown () {
    # Kill only processes bound to THIS instance's own DISPLAY -- never a
    # bare `pkill -x`/`pkill -f praat|openbox|Xvfb`, which would take every
    # concurrent lane's own GUI instance with it. openbox/xcompmgr/praat were
    # launched with DISPLAY=$D in their own environ; Xvfb takes the display
    # as an argv token instead, so it is matched on cmdline.
    local pid
    for name in praat openbox xcompmgr; do
        for pid in $(pgrep -x "$name" 2>/dev/null); do
            tr '\0' '\n' < "/proc/$pid/environ" 2>/dev/null \
                | grep -qx "DISPLAY=$D" && kill "$pid" 2>/dev/null || true
        done
    done
    for pid in $(pgrep -x Xvfb 2>/dev/null); do
        tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null \
            | grep -qw -- "$D" && kill "$pid" 2>/dev/null || true
    done
    cleanup
}
trap teardown EXIT

export I RIG REPO
export PLUGIN_SRC="$REPO/plugin"   # only consulted by lib.sh's own launch();
                                    # irrelevant here since CASE_SCRIPT's own
                                    # runScript path is what actually resolves.
export OUT="$HERE/out/pergroup_site3"
mkdir -p "$OUT"
export EML_NORM_CSV="$CSV"
# shellcheck source=/dev/null
. "$REPO/harness/walks/d117/lib.sh"

launch "$CASE_SCRIPT"

t=$(ptitle)
if [ "$t" != "Pause: Check Normality" ]; then
    echo "site3_drive.sh ($MODE): NO_DIALOG (got [$t])" >&2
    exit 1
fi
# Group column menu: 1 = "(none - overall only)", 2 = "grp" (the table's
# first column). r03_identical.csv is "grp,y" -- same layout pergroup.sh
# documents for its own cases.
popt 1 2 1
pbtn 3 3 4

t=$(ptitle)
if [ "$t" != "Pause: Normality assessment complete" ]; then
    echo "site3_drive.sh ($MODE): WRONG_PAGE (got [$t])" >&2
    exit 1
fi

mkdir -p "$HERE/out/site3"
infodump "$HERE/out/site3/$MODE.txt"
pbtn 2 4 3

bytes=$(wc -c < "$HERE/out/site3/$MODE.txt" 2>/dev/null || echo 0)
echo "site3_drive.sh ($MODE): wrote $HERE/out/site3/$MODE.txt ($bytes bytes)"
