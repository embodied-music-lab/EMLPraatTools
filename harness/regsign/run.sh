#!/usr/bin/env bash
# ============================================================================
# regsign/run.sh -- drive the negative-slope regression fixture and write the
# capture v13's new sign-agreement fixture reads.
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# Produces evidence/info/v13_regression_neg_info.txt from evidence/csv/
# v13_regression_neg_input.csv. Headless: @emlRunRegressionAnalysis raises no
# dialog, so there is no Xvfb and no window manager anywhere in this file.
#
#   bash harness/regsign/run.sh
#
# STAGING, as harness/directional/run.sh: the driver is copied into out/work
# beside a `plugin` symlink, and the symlink selects the tree under test.
# EML_PLUGIN_DIR points it at a corrupted copy for a break test without
# touching plugin/. EML_REGSIGN_CAPTURE redirects the capture so a break test
# does not have to overwrite the committed one.
#
# Exit 0 = the driver reached its end marker and the capture was written.
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$SCRIPT_DIR/.." && pwd)/_env.sh" || exit 1

PLUG="${EML_PLUGIN_DIR:-$EML_ROOT/plugin}"
CAP="${EML_REGSIGN_CAPTURE:-$EML_ROOT/evidence/info/v13_regression_neg_info.txt}"
FIX="${EML_REGSIGN_FIXTURE:-$EML_ROOT/evidence/csv/v13_regression_neg_input.csv}"
OUT="$SCRIPT_DIR/out"
PREFS="$SCRIPT_DIR/prefs"
WORK="$OUT/work"
LOG="$OUT/driver.log"

if [[ ! -d "$PLUG" ]]; then
    echo "regsign: no plugin tree at $PLUG" >&2
    exit 1
fi
if [[ ! -f "$FIX" ]]; then
    echo "regsign: no fixture at $FIX" >&2
    exit 1
fi

mkdir -p "$OUT" "$PREFS"
rm -rf "$WORK"
mkdir -p "$WORK"
ln -s "$PLUG" "$WORK/plugin"
cp "$SCRIPT_DIR/regsign_drive.praat" "$WORK/regsign_drive.praat"

rm -f "$LOG"
( cd "$WORK" && env -u DISPLAY \
    EML_REGSIGN_CAPTURE="$CAP" EML_REGSIGN_FIXTURE="$FIX" \
    timeout 120 "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" \
    --run regsign_drive.praat > "$LOG" 2>&1 )
rc=$?

fail=0
if [[ $rc -ne 0 ]]; then
    echo "FAIL: praat exited $rc -- see $LOG"; fail=1
fi
if [[ ! -f "$CAP" ]]; then
    echo "FAIL: no capture at $CAP"; fail=1
else
    grep -q '^V13NEG DONE$' "$CAP" \
        || { echo "FAIL: capture has no end marker -- see $LOG"; fail=1; }
fi

if [[ $fail -eq 0 ]]; then
    echo "regsign: PASS -- capture written to $CAP"
    echo "  plugin tree: $PLUG"
    exit 0
fi
exit 1
