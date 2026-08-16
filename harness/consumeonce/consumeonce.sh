#!/usr/bin/env bash
# ============================================================================
# harness/consumeonce/consumeonce.sh — drive the consume-once axis publication
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# AUTHOR RULING A, CHANGE ORDER 7, 16 AUGUST 2026. Praat cannot unset a
# variable, so the graphs form's axis publication lived for the whole process
# and every recorded draw after the first press inherited it. The publication
# now carries a STEP STAMP; @emlRecordAxisRequest accepts the pair only when
# the stamp names the step being recorded, and zeroes the stamp on the way
# out. This rig drives the scenario the defect needs and no other rig in this
# tree performs: TWO DRAWS IN ONE PRAAT PROCESS, the first through the form
# and the second not.
#
# One Praat process per leg, for the reason harness/stress_graphs.sh gives: a
# Praat script error aborts the script, so eight legs in one process report
# one failure and hide seven.
#
# NO DISPLAY IS BOUND AND NONE IS NEEDED. The draw procedures call no
# beginPause:, which is what lets these figures be rendered with no X server;
# DISPLAY is unset for every leg rather than merely ignored, so the claim is
# proved rather than relied on, and no stray connection is made to whatever
# interactive instance another harness has open.
#
# $EML_CO_SRC points every leg at a DIFFERENT COPY of the repository, which is
# how validate/v74's break test renders a deliberately reverted library
# without touching the working tree. $EML_CO_OUTDIR moves the evidence with
# it. A break test that edits the repository and puts it back is one
# interrupted run away from committing a defect.
#
# Run from anywhere:  bash harness/consumeonce/consumeonce.sh
# Output: harness/consumeonce/out/CONSUMEONCE.tsv     read by validate/v74
#         harness/consumeonce/out/<leg>/emitted.praat the recorded scripts
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$SCRIPT_DIR/.." && pwd)/_env.sh" || exit 1

SRC="${EML_CO_SRC:-$EML_ROOT}"
OUT="${EML_CO_OUTDIR:-$SCRIPT_DIR/out}"
PREFS="$OUT/prefs"
DRIVE="$SRC/harness/consumeonce/consumeonce_drive.praat"

REC_LEGS="form_then_qq bridge_then_qq form_then_violin stamp_live \
          stamp_stale pair_unstamped qq_alone"
BARE_LEGS="stamp_types"

mkdir -p "$OUT" "$PREFS"
rm -f "$OUT"/*.log 2>/dev/null
for leg in $REC_LEGS $BARE_LEGS; do rm -rf "${OUT:?}/$leg"; done
TSV="$OUT/CONSUMEONCE.tsv"
: > "$TSV"
printf 'praat_version\t%s\n' "$("$PRAAT" --version 2>&1 | head -1)" >> "$TSV"
printf 'source_tree\t%s\n' "$SRC" >> "$TSV"

run_leg () {
    local leg="$1" aux="${2:-}"
    # STALE LOCK. Only the two files Praat leaves behind are removed, and only
    # from this rig's own scratch pref dir — never from anyone else's, and
    # never the preferences directory itself.
    rm -f "$PREFS/pid" "$PREFS/message" 2>/dev/null
    printf 'leg\t%s\n' "$leg" >> "$TSV"
    env -u DISPLAY \
        EML_CO_LEG="$leg" EML_CO_OUT="$TSV" \
        EML_CO_AUX="$aux" EML_CO_ROOT="$SRC" \
        timeout 300 "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" --run "$DRIVE" \
        > "$OUT/$leg.log" 2>&1
    printf '%s_exit\t%s\n' "$leg" "$?" >> "$TSV"
}

for leg in $REC_LEGS; do
    mkdir -p "$OUT/$leg"
    run_leg "$leg" "$OUT/$leg"
done
for leg in $BARE_LEGS; do
    run_leg "$leg"
done

# THE LEG MARKER IS RESET FIRST. Everything below belongs to no leg — the
# shell reads it out of the emitted files — so without this line the validator
# would look for `form_then_qq_steps` and find `stamp_types.form_then_qq_steps`,
# which is a key that does not exist. A validator cannot tell a mis-filed key
# from a harness that never ran.
printf 'leg\t--shell--\n' >> "$TSV"

emit_kv () { printf '%s\t%s\n' "$1" "$2" >> "$TSV"; }

# ---------------------------------------------------------------------------
# WHAT THE EMITTED FILES SAY.
#
# Read out of the file a user would run, never out of a variable inside the
# process that wrote it. `block_of` stops at the first blank line after the
# block's own heading, so a later step's code can never be mistaken for a
# declaration.
#
# THE DECLARATION IS READ WITH ITS COMMENT ATTACHED, because the comment is
# what names the STEP each declaration belongs to — "step 2 (draw)" — and on
# the two-figure legs that is the only thing in the file that says which
# figure a range was recorded for. A validator that read the values alone
# could not tell 0.0 recorded for the Q-Q plot from 0.0 recorded for the
# violin.
# ---------------------------------------------------------------------------
block_of () {
    [[ -s "$1" ]] || return 0
    sed -n '/^# Name your data objects/,/^$/p' "$1"
}

for leg in $REC_LEGS; do
    f="$OUT/$leg/emitted.praat"
    if [[ ! -s "$f" ]]; then
        emit_kv "${leg}_emitted" "<none>"
        continue
    fi
    emit_kv "${leg}_emitted" "yes"
    while IFS= read -r ln; do
        emit_kv "${leg}_blockline" "$ln"
    done < <(block_of "$f" | grep -E '^axis[A-Za-z]*(Min|Max)[0-9]* *=')
    # HOW MANY STEPS, AND OF WHAT KIND. The two-figure legs must emit exactly
    # two draw steps; a leg that silently recorded one would make "the second
    # step declares the sentinel" a claim about a step that does not exist.
    emit_kv "${leg}_steps" "$(grep -c '^# --- Step ' "$f")"
    while IFS= read -r ln; do
        emit_kv "${leg}_stepline" "$ln"
    done < <(grep -E '^# --- Step ' "$f")
    # The axis slots in each recorded draw call, matched on the call's own
    # name so a literal in some other argument — a viewport, a grid mode — is
    # never counted as an axis.
    # EVERY violin call, in order, not just the first: form_then_violin
    # records two of them and the SECOND is the one the leak would show in.
    # `grep -m1` would have answered both questions with the first figure.
    while IFS= read -r ln; do
        emit_kv "${leg}_violin_call" "$(printf '%s' "$ln" | sed 's/.*valueCol\$, //')"
    done < <(grep '^@emlDrawViolinPlot: data' "$f")
    while IFS= read -r ln; do
        emit_kv "${leg}_scatter_call" "$ln"
    done < <(grep '^@emlDrawScatterPlot: data' "$f")
done

echo "consumeonce: wrote $TSV"
grep -c . "$TSV" | sed 's/^/consumeonce: rows /'
exit 0
