#!/usr/bin/env bash
# ============================================================================
# harness/_env.sh — one place that answers "where am I" and "which Praat"
# ============================================================================
# Sourced by every harness driver. Sets, and exports:
#
#   EML_ROOT    the repository root, resolved from THIS FILE's location
#   PRAAT       a Praat binary at or above the plugin's supported floor
#   PRAAT_TRUST "--FULL-TRUST" on Praat 7.x, empty otherwise
#
# WHY THIS EXISTS.
#
# Until 10 August 2026 every driver in this tree opened with
#
#     ROOT=/home/claude/EMLPraatTools
#     PRAAT=/home/claude/praat
#
# which is correct on exactly one machine. Thirty files carried that path.
# The consequence is not that a copy of the repo fails loudly somewhere else
# — it is worse than that. `harness/stress_cases/_prelude.praat` included the
# plugin by absolute path, so a copy of the repo rendered anywhere else
# silently loaded the ORIGINAL tree's plugin and produced figures that looked
# entirely correct while describing a build nobody asked about. That was hit
# for real, trying to render a shadow build, and the only symptom was that a
# revert appeared not to take effect.
#
# It also means the audit cannot be reproduced by the person it is being
# handed to, which is the whole point of handing it over.
#
# THE VERSION CHECK IS HERE FOR THE SAME REASON THE TEST SUITES HAVE ONE.
# On 10 August a full session of verification ran on Praat 6.4.06, because a
# bare `praat` resolved to /usr/bin/praat rather than the supported build.
# Everything passed and the re-run passed identically, so nothing was wrong —
# which is precisely why it needed a guard. A green suite on an unsupported
# build is not evidence, it only looks like evidence.
#
# Resolution order for PRAAT, first match wins:
#   1. $PRAAT, if already set          — an explicit override always wins
#   2. $EML_ROOT/../praat              — the development symlink
#   3. praat_barren, then praat, on PATH
# Whatever is chosen is then version-checked, and a binary below 6.6.30 is
# REFUSED rather than warned about.
# ============================================================================

# Guard against double-sourcing: a driver that sources this and then calls
# another driver would otherwise re-resolve and re-print.
if [[ -n "${EML_ENV_LOADED:-}" ]]; then
    return 0 2>/dev/null || true
fi
EML_ENV_LOADED=1

_eml_env_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EML_ROOT="$(cd "$_eml_env_dir/.." && pwd)"
export EML_ROOT

# ---- the binary ------------------------------------------------------------
_eml_min_version=6630

if [[ -z "${PRAAT:-}" ]]; then
    for _cand in "$EML_ROOT/../praat" "$(command -v praat_barren 2>/dev/null)" \
                 "$(command -v praat 2>/dev/null)"; do
        if [[ -n "$_cand" && -x "$_cand" ]]; then
            PRAAT="$(cd "$(dirname "$_cand")" && pwd)/$(basename "$_cand")"
            break
        fi
    done
fi

if [[ -z "${PRAAT:-}" || ! -x "${PRAAT}" ]]; then
    echo "harness/_env.sh: no Praat binary found." >&2
    echo "  Looked at: \$PRAAT, $EML_ROOT/../praat, praat_barren, praat" >&2
    echo "  Set PRAAT=/path/to/praat and re-run." >&2
    return 1 2>/dev/null || exit 1
fi

# "Praat 6.6.30 (June 30 2026)" -> 6630 ; "Praat 7.0 (...)" -> 7000
_eml_ver_str="$("$PRAAT" --version 2>&1 | head -1)"
_eml_ver_num="$(printf '%s' "$_eml_ver_str" \
    | sed -E 's/^Praat ([0-9]+)\.([0-9]+)(\.([0-9]+))?.*/\1 \2 \4/')"
read -r _v1 _v2 _v3 <<< "$_eml_ver_num"
# Leading zeros: Praat writes 6.6.06, and bash arithmetic reads a leading
# zero as OCTAL, so 6.4.08 would abort with "value too great for base".
# Stripped rather than risked.
_v1=$((10#${_v1:-0})); _v2=$((10#${_v2:-0})); _v3=$((10#${_v3:-0}))
if [[ -z "$_eml_ver_num" || "$_eml_ver_num" = "$_eml_ver_str" ]]; then
    echo "harness/_env.sh: could not parse a version from:" >&2
    echo "  $_eml_ver_str" >&2
    echo "  Refusing rather than guessing. Set PRAAT= explicitly." >&2
    return 1 2>/dev/null || exit 1
fi
_eml_ver=$(( _v1 * 1000 + _v2 * 100 + _v3 ))

if (( _eml_ver < _eml_min_version )); then
    echo "harness/_env.sh: REFUSED — unsupported Praat." >&2
    echo "  $PRAAT" >&2
    echo "  $_eml_ver_str  (parsed as $_eml_ver)" >&2
    echo "  The plugin requires 6.6.30 ($_eml_min_version) or later;" >&2
    echo "  setup.praat refuses to load it below that, so a result from" >&2
    echo "  this build would describe a plugin no user can run." >&2
    echo "  Set PRAAT=/path/to/a/supported/praat and re-run." >&2
    return 1 2>/dev/null || exit 1
fi

export PRAAT

# ---- Praat 7 trust ---------------------------------------------------------
# Praat 7 refuses file writes from a script without this. 6.x does not know
# the flag, so it cannot simply be passed always.
PRAAT_TRUST=""
if (( _v1 >= 7 )); then
    PRAAT_TRUST="--FULL-TRUST"
fi
export PRAAT_TRUST

unset _eml_env_dir _eml_min_version _eml_ver_str _eml_ver_num _cand \
      _v1 _v2 _v3 _eml_ver
