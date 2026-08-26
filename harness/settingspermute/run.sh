#!/usr/bin/env bash
# ============================================================================
# harness/settingspermute/run.sh -- drive R1's settings-permutation probe
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
#   harness/settingspermute/run.sh          drive the tree this file sits in
#   EML_SPM_OUT=<dir> ... run.sh            write the artefact somewhere else
#
# Captures the whole process's stdout to a transcript, same reason
# harness/reprintpins/run.sh does: a script abort must be read honestly
# rather than papered over by a probe that keeps writing partial rows.
#
# Praat resolves through harness/_env.sh; there is no bare praat on PATH.
# ============================================================================
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$here/../_env.sh"

out="${EML_SPM_OUT:-$here/out}"
mkdir -p "$out"
rm -f "$out/transcript.txt" "$out/SETTINGSPERMUTE.tsv"

"$PRAAT" $PRAAT_TRUST --run "$here/probe.praat" "$out" > "$out/transcript.txt" 2>&1
status=$?
echo "$status" > "$out/exit_status.txt"
echo "wrote $out/transcript.txt (exit $status) and $out/SETTINGSPERMUTE.tsv"
exit 0
