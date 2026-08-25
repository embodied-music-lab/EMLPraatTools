#!/usr/bin/env bash
# ============================================================================
# nummiss/run.sh -- drive the native-missing-cell fixture and write the
# capture v123 reads.
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# Produces evidence/info/v123_nummiss_info.txt. Headless:
# @emlCheckNumericColumn raises no dialog, so there is no Xvfb and no window
# manager anywhere in this file.
#
#   bash harness/nummiss/run.sh
#
# STAGING, as harness/directional/run.sh: the driver is copied into out/work
# beside a `plugin` symlink, and the symlink selects the tree under test.
# EML_PLUGIN_DIR points it at a corrupted copy for a break test without
# touching plugin/. EML_NUMMISS_CAPTURE redirects the capture so a break
# test does not have to overwrite the committed one.
#
# Exit 0 = the driver reached its end marker and the capture was written.
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$SCRIPT_DIR/.." && pwd)/_env.sh" || exit 1

PLUG="${EML_PLUGIN_DIR:-$EML_ROOT/plugin}"
CAP="${EML_NUMMISS_CAPTURE:-$EML_ROOT/evidence/info/v123_nummiss_info.txt}"
OUT="$SCRIPT_DIR/out"
PREFS="$SCRIPT_DIR/prefs"
WORK="$OUT/work"
LOG="$OUT/driver.log"

if [[ ! -d "$PLUG" ]]; then
    echo "nummiss: no plugin tree at $PLUG" >&2
    exit 1
fi

mkdir -p "$OUT" "$PREFS"
rm -rf "$WORK"
mkdir -p "$WORK"
ln -s "$PLUG" "$WORK/plugin"
cp "$SCRIPT_DIR/nummiss_drive.praat" "$WORK/nummiss_drive.praat"

rm -f "$LOG"
( cd "$WORK" && env -u DISPLAY \
    EML_NUMMISS_CAPTURE="$CAP" \
    timeout 60 "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" \
    --run nummiss_drive.praat > "$LOG" 2>&1 )
rc=$?

fail=0
if [[ $rc -ne 0 ]]; then
    echo "FAIL: praat exited $rc -- see $LOG"; fail=1
fi
if [[ ! -f "$CAP" ]]; then
    echo "FAIL: no capture at $CAP"; fail=1
else
    grep -q '^V123NUMMISS DONE$' "$CAP" \
        || { echo "FAIL: capture has no end marker -- see $LOG"; fail=1; }
fi

if [[ $fail -eq 0 ]]; then
    echo "nummiss: PASS -- capture written to $CAP"
    echo "  plugin tree: $PLUG"
    exit 0
fi
exit 1
