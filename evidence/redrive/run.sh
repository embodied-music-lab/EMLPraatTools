#!/usr/bin/env bash
# ============================================================================
# evidence/redrive/run.sh — retake the two hand-taken captures under evidence/info
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
#     bash evidence/redrive/run.sh            # both
#     bash evidence/redrive/run.sh wizard_rm3 # one
#
# PRAAT is resolved and version-gated by harness/_env.sh, which refuses
# anything below 6.6.30 — a capture taken on an unsupported build is not
# evidence, it only looks like evidence.
#
# The prefs directory is per-run and under $TMPDIR, not the user's, so a
# retake cannot inherit or leave behind Info-window state or a stale lock.
#
# REPRODUCIBILITY, STATED HONESTLY. wizard_rm3 is byte-reproducible: nothing
# in it carries a clock. rp_r6_describe is not — @emlReportHeader stamps the
# run time, so exactly one line differs between any two retakes. Nothing
# asserts on that line; the point is recorded here so a diff of one line is
# read as the clock rather than as a change in the plugin.
# ============================================================================
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$HERE/../../harness/_env.sh"

PREFS="$(mktemp -d "${TMPDIR:-/tmp}/eml_redrive_prefs.XXXXXX")"
trap 'rm -rf "$PREFS"' EXIT

# @wizardReportPlan lives in plugin/scripts/eml-wizard.praat, whose top level
# is the wizard's beginPause loop; beginPause hard-crashes under --run, so the
# file cannot be included. The PROCEDURES section is lifted out here, from the
# shipping source, on every run — never kept as a copy that can drift.
marker=$(grep -n '^# PROCEDURES$' "$EML_ROOT/plugin/scripts/eml-wizard.praat" | cut -d: -f1)
if [[ -z "$marker" ]]; then
    echo "redrive: no '# PROCEDURES' marker in eml-wizard.praat — refusing to guess." >&2
    exit 1
fi
awk -v m="$((marker - 1))" 'NR >= m' \
    "$EML_ROOT/plugin/scripts/eml-wizard.praat" > "$HERE/wizard_procs.generated.praat"

run_one() {
    echo "redrive: $1"
    ( cd "$HERE" && "$PRAAT" ${PRAAT_TRUST:+$PRAAT_TRUST} \
        --pref-dir="$PREFS" --run "$1.praat" >/dev/null )
}

case "${1:-all}" in
    all)              run_one wizard_rm3; run_one rp_r6_describe ;;
    wizard_rm3)       run_one wizard_rm3 ;;
    rp_r6_describe)   run_one rp_r6_describe ;;
    *) echo "redrive: unknown leg '$1'" >&2; exit 1 ;;
esac

rm -f "$HERE/wizard_procs.generated.praat"
echo "redrive: done"
