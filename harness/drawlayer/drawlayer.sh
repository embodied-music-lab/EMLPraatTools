#!/usr/bin/env bash
# ============================================================================
# harness/drawlayer/drawlayer.sh — render and measure the draw layer's rulings
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# One Praat process per leg, for the reason harness/stress_graphs.sh gives: a
# Praat script error aborts the script, so a dozen legs in one process report
# one failure and hide eleven. A second of wall clock each buys an independent
# verdict per leg.
#
# NO DISPLAY IS BOUND AND NONE IS NEEDED. DISPLAY is unset for every leg
# rather than merely ignored, which proves the claim as well as relying on it
# and stops a stray connection to whatever interactive instance another
# harness has open. Displays :88, :94, :121 and :180+ were in use by other
# work on 15 August 2026; this rig binds none of them, or any other.
#
# $EML_DL_SRC points every leg at a DIFFERENT COPY of the repository, which is
# how validate/v66's break tests render a deliberately broken library without
# touching the working tree. break.sh builds those copies.
#
# Run from anywhere:  bash harness/drawlayer/drawlayer.sh
# Output: harness/drawlayer/out/DRAWLAYER.tsv   read by validate/v66
#         harness/drawlayer/out/pic_*.png       the figures themselves
#         harness/drawlayer/out/info_*.txt      the Info-window transcripts
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

# The tree under test. Defaults to the tree this script lives in; a break test
# sets EML_DL_SRC to a shadow copy and EML_DL_OUTDIR beside it.
SRC="${EML_DL_SRC:-$EML_ROOT}"
OUT="${EML_DL_OUTDIR:-$SCRIPT_DIR/out}"
PREFS="$OUT/prefs"
DRIVE="$SRC/harness/drawlayer/drawlayer_drive.praat"

mkdir -p "$OUT" "$PREFS"
# info_pergroup.txt is NOT cleared here: it is the GUI leg's capture, written
# by pergroup_gui.sh in a separate run, and deleting another script's evidence
# every time this one starts made validate/v66 silently drop four checks.
rm -f "$OUT"/pic_*.png "$OUT"/emitted.praat 2>/dev/null
for f in degenerate tiny real normality; do
    rm -f "$OUT/info_$f.txt" 2>/dev/null
done
TSV="$OUT/DRAWLAYER.tsv"
: > "$TSV"
printf 'praat_version\t%s\n' "$("$PRAAT" --version 2>&1 | head -1)" >> "$TSV"
printf 'source_tree\t%s\n' "$SRC" >> "$TSV"

run_leg () {
    local leg="$1" aux="${2:-}"
    # STALE LOCK. Only the two files Praat leaves behind are removed, and only
    # from this rig's own scratch pref dir -- never from anyone else's.
    rm -f "$PREFS/pid" "$PREFS/message" 2>/dev/null
    env -u DISPLAY \
        EML_DL_LEG="$leg" EML_DL_OUT="$TSV" \
        EML_DL_PIC="$OUT/pic_$leg.png" \
        EML_DL_AUX="$aux" EML_DL_ROOT="$SRC" \
        timeout 300 "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" --run "$DRIVE" \
        > "$OUT/$leg.log" 2>&1
}

# ---------------------------------------------------------------------------
# RULING 10(a) — RECORD, THEN REPLAY TWICE
# ---------------------------------------------------------------------------
# The emitted script is INCLUDED by the replay legs, not runScript:-ed.
# runScript: opens a fresh scope, so the drawn-extent tracker the emitted file
# updates does not come back out and the caller cannot save the picture at the
# extent it was actually drawn -- measured in harness/record/roundtrip_graph.sh
# before this rig existed. `include` is a textual paste into one scope, which
# is also how a user running the emitted file in Praat experiences it.
run_leg axis_record "$OUT"

# THE LEG MARKER IS RESET FIRST. Everything below belongs to no leg -- the
# shell reads it out of the emitted file, and the two replay processes have no
# leg of their own -- so without this line the validator would look for
# `recorded_axis_args` and find `axis_record.recorded_axis_args`, which is a
# key that does not exist. A validator cannot tell a mis-filed key from a
# harness that never ran.
printf 'leg\t--shell--\n' >> "$TSV"

EMITTED="$OUT/emitted.praat"
if [[ -s "$EMITTED" ]]; then
    # WHAT THE RECORDED CALL SAYS IN THE AXIS SLOTS. Read out of the file a
    # user would run, not out of a variable inside the process that wrote it.
    axis_args="$(grep -m1 '^@emlDrawViolinPlot: data' "$EMITTED" \
                 | sed 's/.*valueCol\$, //')"
    printf 'recorded_axis_args\t%s\n' "$axis_args" >> "$TSV"
    # AND WHAT THE COMMENT BESIDE IT SAYS. The resolved numbers are not lost;
    # they move from the call to the note, and both halves are asserted.
    printf 'recorded_result_note\t%s\n' \
        "$(grep -m1 '^# Axis resolved' "$EMITTED" | sed 's/^# //')" >> "$TSV"

    for arm in same wide; do
        case "$arm" in
            same) base=200;  spread=80  ;;
            wide) base=1100; spread=400 ;;
        esac
        cat > "$OUT/replay_$arm.praat" <<PRAAT
t = Create Table with column names: "narrow", 0, "grp val"
st = 20260815
r = 0
for g from 1 to 3
    for k from 1 to 20
        st = (1103515245 * st + 12345) mod 2147483648
        r = r + 1
        Append row
        Set string value: r, "grp", "G" + string\$ (g)
        Set numeric value: r, "val",
        ... $base + g * $spread * 0.235 + (st / 2147483648 - 0.5) * $spread
    endfor
endfor
Erase all
include $EMITTED
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
    printf 'recorded_axis_args\t<no emitted script>\n' >> "$TSV"
fi

# THE EXPLICIT ARM, in its own record folder so the two emitted scripts cannot
# overwrite one another.
mkdir -p "$OUT/explicit"
rm -f "$OUT/explicit/emitted.praat"
run_leg axis_record_explicit "$OUT/explicit"
printf 'leg\t--shell--\n' >> "$TSV"
if [[ -s "$OUT/explicit/emitted.praat" ]]; then
    printf 'recorded_axis_args_explicit\t%s\n' \
        "$(grep -m1 '^@emlDrawViolinPlot: data' "$OUT/explicit/emitted.praat" \
           | sed 's/.*valueCol\$, //')" >> "$TSV"
else
    printf 'recorded_axis_args_explicit\t<no emitted script>\n' >> "$TSV"
fi

run_leg axis_native_wide

for leg in name_violin name_box name_bar name_gviolin name_gbox \
           name_spaghetti name_hist name_plain; do
    run_leg "$leg"
done

for leg in posthoc_tukey posthoc_dunn; do
    run_leg "$leg"
done

# THE INFO TRANSCRIPT IS THE LEG'S OWN STDOUT, not a file the script wrote.
# `appendFile: ..., info$ ()` writes in Praat's text-output encoding, which is
# UTF-16 here, and a validator reading it with readLines() gets a file of NULs
# -- tried on 15 August 2026 and it read as an empty report, which is the same
# thing a broken build produces. stdout is UTF-8 on every platform.
for leg in info_degenerate info_tiny info_real info_normality; do
    run_leg "$leg"
    cp "$OUT/$leg.log" "$OUT/info_${leg#info_}.txt"
done

for leg in onebin twobin; do
    run_leg "$leg"
done

# ---------------------------------------------------------------------------
# THE GAP, IN PIXELS, OFF THE PAGE ITSELF — RULING 7
# ---------------------------------------------------------------------------
# No Praat script can read back a pixel and the ruling is about pixels, so the
# verdict is taken from the rendered PNG, the same way for the figure that is
# supposed to have moved and the figure that is supposed not to have.
#
# HOW IT WORKS, because a one-liner that measures the wrong thing is worse
# than no measurement. `-resize x1!` collapses the image to a single row of
# column MEANS after thresholding, so each output pixel is "how much ink is in
# this column". The frame's own left edge, being a full-height line, is the
# darkest column in the left half of the picture and is found by taking the
# minimum. Everything to the LEFT of it is margin: the rotated axis name
# first, then the tick numbers. The gap reported is the white space between
# the END of the first ink run and the START of the second.
#
# Cross-checked against an independent PIL/numpy reading on the violin leg,
# 15 August 2026: same frame column, same runs, same gap, to the pixel. This
# is deliberately the SAME method harness/graphaxes/axes.sh uses on the
# @emlDrawAxes side of the same ruling -- two rigs measuring one requirement
# with two different rulers would produce numbers nobody could compare.
margin_gap () {
    convert "$1" -colorspace Gray -threshold 78% -resize x1! txt:- 2>/dev/null \
    | awk -F'[,:( ]+' '/^[0-9]/ {print $1, $4}' \
    | awk '
        { col[NR-1] = $2; n = NR }
        END {
            best = 256; fl = -1
            for (i = 0; i < n / 2; i++) if (col[i] < best) { best = col[i]; fl = i }
            inrun = 0; nr = 0
            for (i = 0; i < fl; i++) {
                if (col[i] < 255) { if (!inrun) { s = i; inrun = 1 }; e = i }
                else if (inrun)   { nr++; rs[nr] = s; re[nr] = e; inrun = 0 }
            }
            if (inrun) { nr++; rs[nr] = s; re[nr] = e }
            if (nr >= 2) print rs[2] - re[1] - 1; else print -1
        }'
}

# WHERE THE LEFTMOST INK OF THE PICTURE IS. Praat saves the outer viewport
# @emlAssertFullViewport selects and nothing outside it, so an axis name
# pushed past the panel's own edge comes back SLICED down its length -- and a
# slice shows up here as ink in column 0.
first_ink_col () {
    convert "$1" -colorspace Gray -threshold 78% -resize x1! txt:- 2>/dev/null \
    | awk -F'[,:( ]+' '/^[0-9]/ {print $1, $4}' \
    | awk '{ if ($2 < 255 && !seen) { print $1; seen = 1 } }'
}

# HOW WIDE THE LEFTMOST INK RUN IS — the rotated axis name's own thickness.
#
# "First ink is not in column 0" is the obvious test for "nothing was pushed
# off the page" and it is not enough, measured: with the shift unclamped and
# ten times too big, the name is not SLICED, it is clipped away almost
# entirely, and what is left of it starts further RIGHT than the intact name
# did. First-ink went from 67 to 121 -- the wrong way for a check that reads
# "0 means cut". The name's run went from 37 px wide to 10, which is the
# measurement that noticed.
name_run_width () {
    convert "$1" -colorspace Gray -threshold 78% -resize x1! txt:- 2>/dev/null \
    | awk -F'[,:( ]+' '/^[0-9]/ {print $1, $4}' \
    | awk '
        { col[NR-1] = $2; n = NR }
        END {
            best = 256; fl = -1
            for (i = 0; i < n / 2; i++) if (col[i] < best) { best = col[i]; fl = i }
            for (i = 0; i < fl; i++) {
                if (col[i] < 255) { if (s == "") s = i; e = i }
                else if (s != "") { print e - s + 1; exit }
            }
            if (s == "") print -1
        }'
}

# HOW MUCH INK IS INSIDE THE FRAME. The crop is the plot interior of a 6x4
# figure at 300 dpi -- the theme's margins taken in and rounded INWARDS, so no
# frame line is counted as data. Zero means a fully furnished, completely
# empty frame.
#
# THIS IS THE MEASUREMENT AND THE FILE SIZE IS NOT. The frozen-axis violin
# weighs 43 KB and the empty one-bin spectrum 53 KB: a size threshold passes
# both, because a figure with a box, ticks, group names, a title and two axis
# names is a large PNG whether or not anything was plotted in it.
interior_ink () {
    convert "$1" -crop 1280x920+260+125 +repage -colorspace Gray \
        -threshold 78% -format '%[fx:int(w*h*(1-mean))]' info: 2>/dev/null
}

# A SENTINEL, SO THE VALIDATOR CAN TELL A LEG'S KEYS FROM THE SHELL'S.
# Every key Praat writes belongs to whichever leg was running; every key
# written below belongs to no leg. The reader scopes keys by the last `leg`
# row it saw, so without this line the image measurements would all be filed
# under "twobin" and looked up under names that do not exist -- which reads
# to a validator exactly like a harness that never ran.
printf 'leg\t--shell--\n' >> "$TSV"

if command -v convert >/dev/null 2>&1; then
    for leg in name_violin name_box name_bar name_gviolin name_gbox \
               name_spaghetti name_hist name_plain; do
        [[ -s "$OUT/pic_$leg.png" ]] || continue
        printf '%s_gap_px\t%s\n' "$leg" "$(margin_gap "$OUT/pic_$leg.png")" >> "$TSV"
        printf '%s_first_ink_px\t%s\n' "$leg" \
            "$(first_ink_col "$OUT/pic_$leg.png")" >> "$TSV"
        printf '%s_name_run_px\t%s\n' "$leg" \
            "$(name_run_width "$OUT/pic_$leg.png")" >> "$TSV"
    done
    for leg in replay_same replay_wide axis_native_wide onebin twobin; do
        [[ -s "$OUT/pic_$leg.png" ]] || continue
        printf '%s_interior_ink\t%s\n' "$leg" \
            "$(interior_ink "$OUT/pic_$leg.png")" >> "$TSV"
        printf '%s_bytes\t%s\n' "$leg" \
            "$(stat -c%s "$OUT/pic_$leg.png")" >> "$TSV"
    done
    # THE TWO BYTE-FOR-BYTE VERDICTS. A retargeted replay must be the figure a
    # native draw produces, and a same-data replay must be the figure that was
    # recorded -- the second is what says the first was not bought by making
    # every replay ignore its arguments.
    if [[ -s "$OUT/pic_replay_wide.png" && -s "$OUT/pic_axis_native_wide.png" ]]; then
        if cmp -s "$OUT/pic_replay_wide.png" "$OUT/pic_axis_native_wide.png"; then
            printf 'replay_wide_matches_native\tyes\n' >> "$TSV"
        else
            printf 'replay_wide_matches_native\tno\n' >> "$TSV"
        fi
    fi
    if [[ -s "$OUT/pic_replay_same.png" && -s "$OUT/pic_axis_record.png" ]]; then
        if cmp -s "$OUT/pic_replay_same.png" "$OUT/pic_axis_record.png"; then
            printf 'replay_same_matches_record\tyes\n' >> "$TSV"
        else
            printf 'replay_same_matches_record\tno\n' >> "$TSV"
        fi
    fi
    # THE POST-HOC SUBTITLE, MEASURED AS INK. A disclosure that is correct and
    # runs off the canvas is not a disclosure.
    for leg in posthoc_tukey posthoc_dunn; do
        [[ -s "$OUT/pic_$leg.png" ]] || continue
        printf '%s_first_ink_px\t%s\n' "$leg" \
            "$(first_ink_col "$OUT/pic_$leg.png")" >> "$TSV"
        printf '%s_width_px\t%s\n' "$leg" \
            "$(convert "$OUT/pic_$leg.png" -format '%w' info:)" >> "$TSV"
        printf '%s_last_ink_px\t%s\n' "$leg" \
            "$(convert "$OUT/pic_$leg.png" -colorspace Gray -threshold 78% \
               -resize x1! txt:- 2>/dev/null \
               | awk -F'[,:( ]+' '/^[0-9]/ {print $1, $4}' \
               | awk '{ if ($2 < 255) last = $1 } END { print last }')" >> "$TSV"
    done
else
    printf 'image_measurement\tno convert(1) on PATH\n' >> "$TSV"
fi

echo "drawlayer: wrote $TSV"
grep -c . "$TSV" | sed 's/^/drawlayer: rows /'
exit 0
