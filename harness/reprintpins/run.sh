#!/usr/bin/env bash
# ============================================================================
# harness/reprintpins/run.sh -- drive the reprint-pins probe, capture stdout
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
#   harness/reprintpins/run.sh          drive the tree this file sits in
#   EML_RP_OUT=<dir> ... run.sh         write the artefact somewhere else
#
# THE TRANSCRIPT IS THE EVIDENCE, alongside REPRINTPINS.tsv. Praat has no way
# for a script to read its own Info window back as text, so the only place
# the report bodies exist is the process's own stdout -- captured here,
# verbatim, exit status and all, so validate/v140 can tell a completed run
# from an aborted one rather than trusting a TSV a crashed process never
# finished writing.
#
# Praat resolves through harness/_env.sh; there is no bare praat on PATH.
# ============================================================================
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$here/../_env.sh"

out="${EML_RP_OUT:-$here/out}"
mkdir -p "$out"
rm -f "$out/transcript.txt" "$out/REPRINTPINS.tsv"

"$PRAAT" $PRAAT_TRUST --run "$here/probe.praat" "$out" > "$out/transcript.txt" 2>&1
status=$?
echo "$status" > "$out/exit_status.txt"
echo "wrote $out/transcript.txt (exit $status) and $out/REPRINTPINS.tsv"
exit 0
