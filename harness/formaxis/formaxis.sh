#!/usr/bin/env bash
# ============================================================================
# harness/formaxis/formaxis.sh — drive the graphs form's axis publication and
# the legend panel's Info-window formatter
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# RULING 10(b), FORM HALF. The recorded axis must be the range the USER asked
# for, and (0, 0) is the auto sentinel the dialog names on its own face. The
# graphs form converts auto into explicit on two paths before the draw the
# recorder records, so it publishes the untouched request as
# emlGraphsAxisYReqMin / emlGraphsAxisYReqMax and neither pass overwrites it.
#
# RULING ON fixed$. Nothing in an active process reaches the Info window
# through fixed$, which is not a fixed-precision formatter.
#
# One Praat process per leg: a Praat script error aborts the script, so a
# dozen legs in one process report one failure and hide eleven.
#
# NO DISPLAY IS BOUND AND NONE IS NEEDED. DISPLAY is unset for every leg
# rather than merely ignored, which proves the claim as well as relying on it
# and stops a stray connection to whatever interactive instance another
# harness has open.
#
# $EML_FA_SRC points every leg at a DIFFERENT COPY of the repository, which is
# how validate/v68's break tests render a deliberately broken library without
# touching the working tree. break.sh builds those copies.
#
# Run from anywhere:  bash harness/formaxis/formaxis.sh
# Output: harness/formaxis/out/FORMAXIS.tsv    read by validate/v68
#         harness/formaxis/out/<leg>/emitted.praat   the recorded scripts
#         harness/formaxis/out/pic_*.png        the figures themselves
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
#            https://github.com/embodied-music-lab/PraatGen
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$SCRIPT_DIR/.." && pwd)/_env.sh" || exit 1

SRC="${EML_FA_SRC:-$EML_ROOT}"
OUT="${EML_FA_OUTDIR:-$SCRIPT_DIR/out}"
PREFS="$OUT/prefs"
DRIVE="$SRC/harness/formaxis/formaxis_drive.praat"

REC_LEGS="bracket_auto bracket_typed legend_auto legend_typed noform"
BARE_LEGS="pairs clamp_min clamp_real formatter"

mkdir -p "$OUT" "$PREFS"
rm -f "$OUT"/pic_*.png "$OUT"/*.log 2>/dev/null
for leg in $REC_LEGS; do rm -rf "${OUT:?}/$leg"; done
TSV="$OUT/FORMAXIS.tsv"
: > "$TSV"
printf 'praat_version\t%s\n' "$("$PRAAT" --version 2>&1 | head -1)" >> "$TSV"
printf 'source_tree\t%s\n' "$SRC" >> "$TSV"

run_leg () {
    local leg="$1" aux="${2:-}"
    # STALE LOCK. Only the two files Praat leaves behind are removed, and only
    # from this rig's own scratch pref dir — never from anyone else's.
    rm -f "$PREFS/pid" "$PREFS/message" 2>/dev/null
    printf 'leg\t%s\n' "$leg" >> "$TSV"
    env -u DISPLAY \
        EML_FA_LEG="$leg" EML_FA_OUT="$TSV" \
        EML_FA_PIC="$OUT/pic_$leg.png" \
        EML_FA_AUX="$aux" EML_FA_ROOT="$SRC" \
        timeout 300 "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" --run "$DRIVE" \
        > "$OUT/$leg.log" 2>&1
}

for leg in $REC_LEGS; do
    mkdir -p "$OUT/$leg"
    run_leg "$leg" "$OUT/$leg"
done
for leg in $BARE_LEGS; do
    run_leg "$leg"
done

# THE LEG MARKER IS RESET FIRST. Everything below belongs to no leg — the
# shell reads it out of the emitted files and out of the logs — so without
# this line the validator would look for `bracket_auto_blockline` under the
# last leg that ran, which is a key that does not exist. A validator cannot
# tell a mis-filed key from a harness that never ran.
printf 'leg\t--shell--\n' >> "$TSV"

emit_kv () { printf '%s\t%s\n' "$1" "$2" >> "$TSV"; }

# ---------------------------------------------------------------------------
# WHAT THE EMITTED FILES SAY.
#
# Read out of the file a user would run, never out of a variable inside the
# process that wrote it. `block_of` stops at the first blank line after the
# block's own heading, so a later step's code can never be mistaken for a
# declaration — which is the parse the ruling turns on: an emitted file that
# gathered every axis into a perfect block while the steps below kept their
# own literals would satisfy any grep of the whole file.
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
    # The draw call is matched on its own name, and only the arguments AFTER
    # the value column are kept, so a literal in some other argument — a
    # viewport, a grid mode, a bin count — cannot be counted as an axis.
    emit_kv "${leg}_violin_call" \
        "$(grep -m1 '^@emlDrawViolinPlot: data' "$f" | sed 's/.*valueCol\$, //')"
    emit_kv "${leg}_gviolin_call" \
        "$(grep -m1 '^@emlDrawGroupedViolin: data' "$f" | sed 's/.*valueCol\$, //')"
    # The resolved range, which Ruling 10(b) asks be kept as a note beside the
    # 0.0 rather than thrown away.
    emit_kv "${leg}_resolved_note" \
        "$(grep -m1 -E '^(# on the recorded data it resolved to|axisYMax .*resolved)' "$f" \
           | sed 's/^# on the recorded data it resolved to //')"
    emit_kv "${leg}_auto_marked" \
        "$(grep -c 'AUTO (both 0 = computed from the data)' "$f")"
done

# ---------------------------------------------------------------------------
# THE NOTE THE LEGEND PANEL PRINTED, out of the leg's own transcript.
# ---------------------------------------------------------------------------
for leg in clamp_min clamp_real; do
    emit_kv "${leg}_note" \
        "$(grep -m1 'shortened with an ellipsis' "$OUT/$leg.log" | tr -d '\r')"
done

# ---------------------------------------------------------------------------
# STATIC READING OF THE TWO OWNED FILES, WITH COMMENTS STRIPPED.
#
# Comments are stripped FIRST and that is not tidiness. A sibling check this
# week matched the prose explaining a fix rather than the fix, and went green
# on a tree where the code had been reverted and the paragraph left behind —
# and this repository's house style puts a long paragraph above every repair,
# so the failure mode is guaranteed rather than merely possible. Praat comment
# forms are `#`, `;` and `!` at the start of a line; a trailing `; ...` on a
# code line is left alone, because stripping it would need to know about
# string literals.
# ---------------------------------------------------------------------------
strip_comments () {
    sed -E 's/^[[:space:]]*(#|;|!).*$//' "$1"
}

FORM="$SRC/plugin/graphs/eml-graphs-form.praat"
GRAPH="$SRC/plugin/graphs/eml-graph-procedures.praat"

strip_comments "$FORM"  > "$OUT/form.code"
strip_comments "$GRAPH" > "$OUT/graph.code"

emit_kv "code_publish_proc" \
    "$(grep -c '^procedure emlGraphsPublishAxisRequest$' "$OUT/form.code")"
emit_kv "code_publish_calls" \
    "$(grep -c '@emlGraphsPublishAxisRequest' "$OUT/form.code")"
emit_kv "code_reqmin_writes" \
    "$(grep -cE '^[[:space:]]*emlGraphsAxisYReqMin[[:space:]]*=' "$OUT/form.code")"
emit_kv "code_reqmax_writes" \
    "$(grep -cE '^[[:space:]]*emlGraphsAxisYReqMax[[:space:]]*=' "$OUT/form.code")"
# ORDER. The publication has to happen before both conversion sites, and the
# call sites are unique names, so line numbers in the stripped file answer it.
# The line numbers below are `tail -1` of a grep, so each of the three names
# has to have exactly ONE call site for that to be the call site rather than
# the last of several. Counted here so the ordering check cannot be answered
# about the wrong call.
emit_kv "code_headroom_calls" \
    "$(grep -c '@emlGraphsPreDispatchHeadroom' "$OUT/form.code")"
emit_kv "code_legendroom_calls" \
    "$(grep -c '@emlGraphsDrawWithLegendRoom' "$OUT/form.code")"
emit_kv "line_publish_call" \
    "$(grep -n '@emlGraphsPublishAxisRequest' "$OUT/form.code" | tail -1 | cut -d: -f1)"
emit_kv "line_headroom_call" \
    "$(grep -n '@emlGraphsPreDispatchHeadroom' "$OUT/form.code" | tail -1 | cut -d: -f1)"
emit_kv "line_legendroom_call" \
    "$(grep -n '@emlGraphsDrawWithLegendRoom' "$OUT/form.code" | tail -1 | cut -d: -f1)"
# fixed$ CALLS THAT REACH THE INFO WINDOW. Counted per file, on stripped code.
emit_kv "code_form_fixed" "$(grep -c 'fixed\$ *(' "$OUT/form.code")"
emit_kv "code_graph_fixed" "$(grep -c 'fixed\$ *(' "$OUT/graph.code")"
emit_kv "code_graph_eml_fixed" "$(grep -c '@eml_fixed:' "$OUT/graph.code")"
# THE ONE REMAINING Info-window site in eml-graph-procedures.praat: the
# ellipsis NOTE, which is active on every draw that carries a legend.
emit_kv "code_clamp_fixed" \
    "$(awk '/^ *if \.clamped = 1$/,/^ *endif$/' "$OUT/graph.code" \
       | grep -c 'fixed\$ *(')"
emit_kv "code_clamp_emlfixed" \
    "$(awk '/^ *if \.clamped = 1$/,/^ *endif$/' "$OUT/graph.code" \
       | grep -c '@eml_fixed:')"
# THE SECOND Info-window site WAS @emlCheckPlausibility, RETIRED 16 AUGUST
# 2026 with zero callers (see the tombstone in eml-graph-procedures.praat).
# What was a caller COUNT is now an EXISTENCE count, in both directions,
# because a pin that dies with the body it guarded cannot catch the body
# coming back. Both are read across the whole plugin, not just this file, so
# a re-introduction into any file is visible:
#
#   _defs     `procedure emlCheckPlausibility` declarations. Read off the
#             SHIPPED SOURCES rather than $OUT/graph.code, which is only the
#             one file, and off unstripped text with the anchor doing the
#             comment filtering — a commented-out definition does not define.
#   _callers  non-comment mentions of the name. The tombstone and the
#             changelog entry mention it on comment lines, which the -v
#             filter drops; the moment the name appears on a code line
#             anywhere in the plugin this goes to 1 or more.
emit_kv "code_plausibility_defs" \
    "$(grep -rhE '^[[:space:]]*procedure emlCheckPlausibility' \
       "$SRC/plugin" --include=*.praat | wc -l)"
emit_kv "code_plausibility_callers" \
    "$(grep -rh 'emlCheckPlausibility' "$SRC/plugin" --include=*.praat \
       | grep -cv '^ *[#;!]')"

echo "formaxis: wrote $TSV ($(wc -l < "$TSV") lines)"
