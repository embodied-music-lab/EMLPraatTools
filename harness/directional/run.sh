#!/usr/bin/env bash
# ============================================================================
# directional/run.sh — drive the sign-reversal matrix and write the capture
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Produces evidence/info/v73_directional_info.txt from evidence/csv/
# v73_directional_input.csv, which validate/v73_directional_p.R then reads.
# Headless: none of the procedures driven here raises a dialog, so there is
# no Xvfb and no window manager anywhere in this file.
#
#   bash harness/directional/run.sh
#
# STAGING, AND WHY IT IS NOT COSMETIC. Praat resolves `include` at parse time,
# against the directory of the TOP-LEVEL script, and the path cannot be a
# variable. A driver that included ../../plugin/... would therefore be welded
# to one tree, and a break test — the only thing that makes this validator
# evidence rather than decoration — would have to edit the shipping plugin in
# place. So the driver is copied into out/work beside a symlink named
# `plugin`, and the symlink is what selects the tree:
#
#   EML_PLUGIN_DIR=/tmp/scratch/broken_plugin bash harness/directional/run.sh
#
# runs the identical driver against a corrupted copy and touches nothing under
# plugin/. EML_V73_CAPTURE redirects the capture so a break test does not have
# to overwrite the committed one.
#
# Exit 0 = the driver reached its end marker and the capture was written.
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$SCRIPT_DIR/.." && pwd)/_env.sh" || exit 1

PLUG="${EML_PLUGIN_DIR:-$EML_ROOT/plugin}"
CAP="${EML_V73_CAPTURE:-$EML_ROOT/evidence/info/v73_directional_info.txt}"
FIX="${EML_V73_FIXTURE:-$EML_ROOT/evidence/csv/v73_directional_input.csv}"
OUT="$SCRIPT_DIR/out"
PREFS="$SCRIPT_DIR/prefs"
WORK="$OUT/work"
LOG="$OUT/driver.log"

if [[ ! -d "$PLUG" ]]; then
    echo "directional: no plugin tree at $PLUG" >&2
    exit 1
fi
if [[ ! -f "$FIX" ]]; then
    echo "directional: no fixture at $FIX" >&2
    exit 1
fi

mkdir -p "$OUT" "$PREFS"
# The work tree is rebuilt every run. A leftover `plugin` link from a break
# test is the one piece of state that could make a later run describe a tree
# nobody selected — which is finding D-shadow-build in harness/_env.sh's
# header, and it cost a session.
rm -rf "$WORK"
mkdir -p "$WORK"
ln -s "$PLUG" "$WORK/plugin"
cp "$SCRIPT_DIR/directional_drive.praat" "$WORK/directional_drive.praat"

rm -f "$LOG"
( cd "$WORK" && env -u DISPLAY \
    EML_V73_CAPTURE="$CAP" EML_V73_FIXTURE="$FIX" \
    timeout 120 "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" \
    --run directional_drive.praat > "$LOG" 2>&1 )
rc=$?

fail=0
if [[ $rc -ne 0 ]]; then
    echo "FAIL: praat exited $rc — see $LOG"; fail=1
fi
if [[ ! -f "$CAP" ]]; then
    echo "FAIL: no capture at $CAP"; fail=1
else
    # The end marker, not merely a non-empty file. Praat writes the capture
    # with one writeFile: at the very end, so a driver that aborted halfway
    # leaves NO file at all — but a driver that aborted on the LAST family
    # after someone moved the writeFile: earlier would leave a short one, and
    # a short capture makes v73 halt on a missing label rather than fail on a
    # number. Checked here so the harness names it first.
    grep -q '^V73 DIRECTIONAL DONE$' "$CAP" \
        || { echo "FAIL: capture has no end marker — see $LOG"; fail=1; }
fi

if [[ $fail -eq 0 ]]; then
    n=$(grep -c '  ' "$CAP")
    echo "directional: PASS — $n labelled lines in $CAP"
    echo "  plugin tree: $PLUG"
    exit 0
fi
exit 1
