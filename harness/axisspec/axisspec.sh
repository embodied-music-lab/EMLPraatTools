#!/usr/bin/env bash
# ============================================================================
# harness/axisspec/axisspec.sh — render and measure the two 16 August rulings
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# RULING A  "Draw what you can."  A Spectrum whose frequency window holds
#           exactly ONE bin drew a titled, labelled, gridded, tick-marked
#           frame with zero ink inside it. The bin not drawn held the peak of
#           the tone. It is now drawn as a stem to the frame floor.
#
# RULING B  (10b) The recorded axis belongs in the editable header block, as
#           axisYMin / axisYMax, reading 0.0 and 0.0 when the user chose auto.
#
# One Praat process per leg, for the reason harness/stress_graphs.sh gives: a
# Praat script error aborts the script, so a dozen legs in one process report
# one failure and hide eleven.
#
# NO DISPLAY IS BOUND AND NONE IS NEEDED. DISPLAY is unset for every leg
# rather than merely ignored, which proves the claim as well as relying on it
# and stops a stray connection to whatever interactive instance another
# harness has open.
#
# $EML_AS_SRC points every leg at a DIFFERENT COPY of the repository, which is
# how validate/v67's break tests render a deliberately broken library without
# touching the working tree. break.sh builds those copies.
#
# Run from anywhere:  bash harness/axisspec/axisspec.sh
# Output: harness/axisspec/out/AXISSPEC.tsv   read by validate/v67
#         harness/axisspec/out/pic_*.png      the figures themselves
#         harness/axisspec/out/rec_*/emitted.praat   the recorded scripts
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

SRC="${EML_AS_SRC:-$EML_ROOT}"
OUT="${EML_AS_OUTDIR:-$SCRIPT_DIR/out}"
PREFS="$OUT/prefs"
DRIVE="$SRC/harness/axisspec/axisspec_drive.praat"

mkdir -p "$OUT" "$PREFS"
rm -f "$OUT"/pic_*.png "$OUT"/replay_*.praat 2>/dev/null
rm -rf "$OUT"/rec_auto "$OUT"/rec_two "$OUT"/rec_form "$OUT"/rec_noform \
       "$OUT"/rec_pairs 2>/dev/null
TSV="$OUT/AXISSPEC.tsv"
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
        EML_AS_LEG="$leg" EML_AS_OUT="$TSV" \
        EML_AS_PIC="$OUT/pic_$leg.png" \
        EML_AS_AUX="$aux" EML_AS_ROOT="$SRC" \
        timeout 300 "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" --run "$DRIVE" \
        > "$OUT/$leg.log" 2>&1
}

# ---------------------------------------------------------------------------
# RULING A
# ---------------------------------------------------------------------------
for leg in onebin twobin zerobin onebin_long onebin_below dbcheck \
           ltas_curve ltas_bars; do
    run_leg "$leg"
done

# ---------------------------------------------------------------------------
# RULING B — record, then read the block, then EDIT the block and run it
# ---------------------------------------------------------------------------
for leg in rec_auto rec_two rec_form rec_noform rec_pairs; do
    mkdir -p "$OUT/$leg"
    run_leg "$leg" "$OUT/$leg"
done
run_leg native_edited
run_leg native_recorded

# THE LEG MARKER IS RESET FIRST. Everything below belongs to no leg — the
# shell reads it out of the emitted files and out of the PNGs — so without
# this line the validator would look for `block_auto_min` and find
# `native_recorded.block_auto_min`, which is a key that does not exist. A
# validator cannot tell a mis-filed key from a harness that never ran.
printf 'leg\t--shell--\n' >> "$TSV"

# ---------------------------------------------------------------------------
# WHAT THE EMITTED FILES SAY.
#
# Read out of the file a user would run, never out of a variable inside the
# process that wrote it. `block_of` stops at the first blank line after the
# block's own heading, so a later step's code can never be mistaken for a
# declaration.
# ---------------------------------------------------------------------------
block_of () {
    [[ -s "$1" ]] || return 0
    sed -n '/^# Name your data objects/,/^$/p' "$1"
}

emit_kv () { printf '%s\t%s\n' "$1" "$2" >> "$TSV"; }

for leg in rec_auto rec_two rec_form rec_noform rec_pairs; do
    f="$OUT/$leg/emitted.praat"
    if [[ ! -s "$f" ]]; then
        emit_kv "${leg}_emitted" "<none>"
        continue
    fi
    emit_kv "${leg}_emitted" "yes"
    # Every declaration line in the block, one key per line, in order.
    while IFS= read -r ln; do
        emit_kv "${leg}_blockline" "$ln"
    done < <(block_of "$f" | grep -E '^(axis[A-Za-z]*(Min|Max)[0-9]*) *=')
    # And every axis slot still holding a bare number below the block, which
    # is the measurement that says the lift actually happened. A draw call is
    # matched on its own name so that a literal in some OTHER argument — a
    # viewport, a grid mode, a bin count — is not counted as an axis.
    emit_kv "${leg}_violin_call" \
        "$(grep -m1 '^@emlDrawViolinPlot: data' "$f" | sed 's/.*valueCol\$, //')"
    emit_kv "${leg}_box_call" \
        "$(grep -m1 '^@emlDrawBoxPlot: data' "$f" | sed 's/.*valueCol\$, //')"
    emit_kv "${leg}_bar_call" \
        "$(grep -m1 '^@emlDrawBarChart: data' "$f" | sed 's/.*, "", //')"
    emit_kv "${leg}_spectrum_call" \
        "$(grep -m1 '^@emlDrawSpectrum: data' "$f" | sed 's/^.*"Power (dB)", //')"
    emit_kv "${leg}_block_promise" \
        "$(grep -c 'names an object, a column or an axis' "$f")"
done

# ---------------------------------------------------------------------------
# THE DRIVE. EDIT THE BLOCK, RUN THE FILE, LOOK AT THE FIGURE.
#
# A renderer that gathers every axis into a perfect block and leaves the steps
# below reading their own literals passes every static assertion anybody would
# think to write — the variables are there, spelled right, with the right
# values — and is worth exactly nothing, because editing them changes nothing.
# So the block is edited on exactly two lines and NOTHING else in the file is
# touched, and both halves are measured: how many lines changed, and whether
# any of them was below the first step separator.
# ---------------------------------------------------------------------------
EMITTED="$OUT/rec_auto/emitted.praat"
EDITED="$OUT/rec_auto/edited.praat"
if [[ -s "$EMITTED" ]]; then
    sed -e 's/^axisYMin\( *\)= 0\.0/axisYMin\1= 120/' \
        -e 's/^axisYMax\( *\)= 0\.0/axisYMax\1= 500/' \
        "$EMITTED" > "$EDITED"
    emit_kv "edit_lines_changed" "$(diff "$EMITTED" "$EDITED" | grep -c '^< ')"
    # Below the block: everything from the first step separator on. An edit
    # down there would make the drive prove nothing about the block.
    firststep="$(grep -n '^# --- Step ' "$EMITTED" | head -1 | cut -d: -f1)"
    if [[ -n "$firststep" ]]; then
        emit_kv "edit_below_block" \
            "$(diff <(tail -n +"$firststep" "$EMITTED") \
                    <(tail -n +"$firststep" "$EDITED") | grep -c '^< ')"
    else
        emit_kv "edit_below_block" "-1"
    fi

    for arm in same edited; do
        case "$arm" in
            same)   script="$EMITTED" ;;
            edited) script="$EDITED"  ;;
        esac
        # THE EMITTED SCRIPT IS INCLUDED, NOT runScript:-ed. runScript: opens
        # a fresh scope, so the drawn-extent tracker the emitted file updates
        # does not come back out and the caller cannot save the picture at the
        # extent it was actually drawn — measured in
        # harness/record/roundtrip_graph.sh before this rig existed. `include`
        # is a textual paste into one scope, which is also how a user running
        # the emitted file in Praat experiences it.
        # THE FIXTURE IS REBUILT HERE, in the replay's own process, because
        # the emitted script selects its objects by NAME through the block —
        # which is the whole contract — and a name resolves to nothing in a
        # fresh Praat. It is the same linear congruential sequence the drive
        # writes, for the same reason: an unseeded generator makes a
        # byte-for-byte comparison between two processes meaningless.
        cat > "$OUT/replay_$arm.praat" <<PRAAT
Text writing preferences: "UTF-8"
t = Create Table with column names: "vt", 0, "grp val"
st = 20260816
r = 0
for g from 1 to 3
    for k from 1 to 20
        st = (1103515245 * st + 12345) mod 2147483648
        r = r + 1
        Append row
        Set string value: r, "grp", "G" + string\$ (g)
        Set numeric value: r, "val",
        ... 200 + g * 80 * 0.235 + (st / 2147483648 - 0.5) * 80
    endfor
endfor
Erase all
include $script
@emlAssertFullViewport
Save as 300-dpi PNG file: "$OUT/pic_replay_$arm.png"
appendFileLine: "$TSV", "replay_${arm}_min", tab\$,
... fixed\$ (emlDrawViolinPlot.yMin, 4)
appendFileLine: "$TSV", "replay_${arm}_max", tab\$,
... fixed\$ (emlDrawViolinPlot.yMax, 4)
PRAAT
        rm -f "$PREFS/pid" "$PREFS/message" 2>/dev/null
        env -u DISPLAY timeout 300 "$PRAAT" $PRAAT_TRUST \
            --pref-dir="$PREFS" --run "$OUT/replay_$arm.praat" \
            > "$OUT/replay_$arm.log" 2>&1
    done
else
    emit_kv "edit_lines_changed" "-1"
fi

# ---------------------------------------------------------------------------
# THE PICTURES.
# ---------------------------------------------------------------------------
# HOW MUCH INK IS INSIDE THE FRAME. The crop is the plot interior of a 6x4
# figure at 300 dpi — the theme's margins taken in and rounded INWARDS, so no
# frame line is counted as data. Zero means a fully furnished, completely
# empty frame. This is deliberately the SAME crop harness/drawlayer uses, so
# that the two rigs' ink numbers are comparable.
#
# THIS IS THE MEASUREMENT AND THE FILE SIZE IS NOT. The empty one-bin spectrum
# on the short fixture weighs 48,870 bytes: a threshold of "bigger than
# nothing", or of 20 KB, or of 40 KB, passes it, because a figure with a box,
# ticks, a title and two axis names is a large PNG whether or not anything was
# plotted in it. The byte counts are recorded beside the ink so the trap is on
# the record rather than in somebody's memory.
interior_ink () {
    convert "$1" -crop 1280x920+260+125 +repage -colorspace Gray \
        -threshold 78% -format '%[fx:int(w*h*(1-mean))]' info: 2>/dev/null
}

# THE TOPMOST INKED ROW INSIDE THE FRAME, which is how the stem's HEIGHT is
# checked against Praat's own arithmetic without trusting any geometry.
#
# The one-bin window and the two-bin window both contain bin 187, and bin 187
# is the peak of the tone in both. In the two-bin figure Praat's own `Draw:`
# puts a polyline vertex at that bin's value; in the one-bin figure this
# plugin puts the tip of a stem there. If the dB conversion is Praat's, the
# two land on the same image row. If it is the naive power formula the two are
# 10.32 dB apart, which on this axis is 96 rows.
#
# The threshold is 85% and not 78%: a one-pixel-wide vertical line is lighter
# after anti-aliasing than a steep polyline segment, and a threshold tight
# enough to drop the stem's tip would report the stem as SHORTER than it is —
# a check biased in the direction of the thing it is looking for.
top_ink_row () {
    convert "$1" -crop 1280x920+260+125 +repage -colorspace Gray \
        -threshold 85% txt:- 2>/dev/null \
    | awk -F'[,:]' 'NR > 1 && $0 ~ /#000000/ { print $2; exit }'
}

bottom_ink_row () {
    convert "$1" -crop 1280x920+260+125 +repage -colorspace Gray \
        -threshold 85% txt:- 2>/dev/null \
    | awk -F'[,:]' 'NR > 1 && $0 ~ /#000000/ { r = $2 } END { print r }'
}

# THE LEFTMOST AND RIGHTMOST INKED COLUMNS INSIDE THE FRAME. Used two ways:
# on the two-bin figure they are the two bins Praat drew, which calibrates the
# panel's x mapping from Praat's own output; on the one-bin figure they are
# the stem, whose width says it is a stem and whose position says it is at the
# BIN's frequency and not at the middle of the window. Those two differ by
# 420 px on this fixture, so a stem drawn at the window centre — the obvious
# wrong implementation, and the one that needs no bin query at all — is not a
# near miss.
ink_cols () {
    convert "$1" -crop 1280x920+260+125 +repage -colorspace Gray \
        -threshold 85% txt:- 2>/dev/null \
    | awk -F'[,:]' 'NR > 1 && $0 ~ /#000000/ { print $1 }' \
    | sort -n | awk 'NR == 1 { f = $1 } { l = $1 } END { print f, l }'
}

if command -v convert >/dev/null 2>&1; then
    for leg in onebin twobin zerobin onebin_long onebin_below \
               ltas_curve ltas_bars \
               rec_auto native_edited native_recorded \
               replay_same replay_edited; do
        [[ -s "$OUT/pic_$leg.png" ]] || continue
        emit_kv "${leg}_interior_ink" "$(interior_ink "$OUT/pic_$leg.png")"
        emit_kv "${leg}_bytes" "$(stat -c%s "$OUT/pic_$leg.png")"
    done
    for leg in onebin twobin onebin_long; do
        [[ -s "$OUT/pic_$leg.png" ]] || continue
        emit_kv "${leg}_top_row" "$(top_ink_row "$OUT/pic_$leg.png")"
        emit_kv "${leg}_bottom_row" "$(bottom_ink_row "$OUT/pic_$leg.png")"
        read -r c1 c2 <<< "$(ink_cols "$OUT/pic_$leg.png")"
        emit_kv "${leg}_col_first" "${c1:--1}"
        emit_kv "${leg}_col_last" "${c2:--1}"
    done

    # THE TWO BYTE-FOR-BYTE VERDICTS, AND THEY ARE A PAIR ON PURPOSE.
    #
    # An EDITED block must produce the figure a native draw produces at the
    # edited axis. A file whose block is decorative would instead reproduce
    # the recorded figure — so the second comparison is made too, and it must
    # come out NO. One of these alone can be satisfied by a replay that
    # ignores its arguments entirely.
    for pair in "replay_edited:native_edited:edited_matches_native" \
                "replay_edited:rec_auto:edited_matches_recorded" \
                "replay_same:rec_auto:same_matches_recorded" \
                "native_recorded:rec_auto:native_auto_matches_recorded"; do
        a="${pair%%:*}"; rest="${pair#*:}"; b="${rest%%:*}"; key="${rest#*:}"
        if [[ -s "$OUT/pic_$a.png" && -s "$OUT/pic_$b.png" ]]; then
            if cmp -s "$OUT/pic_$a.png" "$OUT/pic_$b.png"; then
                emit_kv "$key" "yes"
            else
                emit_kv "$key" "no"
            fi
        else
            emit_kv "$key" "<missing>"
        fi
    done
else
    emit_kv "image_measurement" "no convert(1) on PATH"
fi

echo "axisspec: wrote $TSV"
grep -c . "$TSV" | sed 's/^/axisspec: rows /'
exit 0
