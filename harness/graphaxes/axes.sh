#!/usr/bin/env bash
# ============================================================================
# harness/graphaxes/axes.sh — render the four axis and annotation findings
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# One Praat process per leg, for the reason harness/stress_graphs.sh gives:
# a Praat script error aborts the script, so five legs in one process report
# one failure and hide four. A second here buys an independent verdict.
#
# NO DISPLAY IS BOUND AND NONE IS NEEDED. DISPLAY is unset for every leg
# rather than merely ignored, which proves the claim as well as relying on it
# — and stops a stray connection to whatever interactive instance another
# harness has open. The one part of this work that DOES need a display, the
# stereo dialog, is in stereo.sh and says so.
#
# $EML_GRAPHS_SRC points the drive at a different copy of plugin/graphs, which
# is how validate/v62's break tests render a deliberately broken library
# without touching the tree.
#
# Run from anywhere:  bash harness/graphaxes/axes.sh
# Output: harness/graphaxes/out/AXES.tsv   read by validate/v62
#         harness/graphaxes/out/pic_*.png  the figures themselves
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

OUT="${EML_AXES_OUTDIR:-$SCRIPT_DIR/out}"
PREFS="$SCRIPT_DIR/prefs"
DRIVE="${EML_GRAPHS_DRIVE:-$SCRIPT_DIR/axes_drive.praat}"

mkdir -p "$OUT" "$PREFS"
TSV="$OUT/AXES.tsv"
: > "$TSV"
printf 'praat_version\t%s\n' "$("$PRAAT" --version 2>&1 | head -1)" >> "$TSV"

for leg in steady ramp2 ticks clip collide \
           margin_st margin_db margin_plain margin_panel margin_cat ticklabel \
           coerce onebin twobin; do
    rm -f "$PREFS/pid" "$PREFS/message" 2>/dev/null
    env -u DISPLAY \
        EML_AXES_LEG="$leg" EML_AXES_OUT="$TSV" \
        EML_AXES_PIC="$OUT/pic_$leg.png" \
        "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" --run "$DRIVE" \
        > "$OUT/$leg.log" 2>&1
done

# ---------------------------------------------------------------------------
# THE GAP, IN PIXELS, OFF THE PAGE ITSELF — RULING 7
# ---------------------------------------------------------------------------
# No Praat script can read back a pixel, and the ruling is about pixels: "no
# collision between the y-axis name and its tick labels". So the verdict is
# taken from the rendered PNG, and it is taken the same way for the figure
# that is supposed to have moved and the figure that is supposed not to have.
#
# HOW IT WORKS, because a one-liner that measures the wrong thing is worse
# than no measurement. `-resize x1!` collapses the image to a single row of
# column MEANS after thresholding, so each output pixel is "how much ink is in
# this column" — the frame's own left edge, being a full-height line, is the
# darkest column in the left half of the picture and is found by taking the
# minimum. Everything to the LEFT of it is margin: the rotated axis name
# first, then the tick numbers. The gap asserted on is the white space between
# the END of the first ink run and the START of the second.
#
# ImageMagick rather than Python: harness/stress_graphs.sh already depends on
# `convert` for its blank-frame verdict, and a second image toolchain is a
# second thing that can be missing on a reviewer's machine. Cross-checked on
# the same six figures against an independent PIL/numpy reading, 15 Aug 2026 —
# same frame column, same runs, same gap, to the pixel.
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

# WHERE THE LEFTMOST INK OF THE MARGIN STARTS. Same column profile; the first
# ink column of the whole picture. Zero means the axis name is touching the
# edge of the saved image, which is what a cut name looks like.
margin_name_left () {
    convert "$1" -colorspace Gray -threshold 78% -resize x1! txt:- 2>/dev/null \
    | awk -F'[,:( ]+' '/^[0-9]/ {print $1, $4}' \
    | awk '{ if ($2 < 255 && !seen) { print $1; seen = 1 } }'
}

# HOW WIDE THE LEFTMOST INK RUN IS — the rotated axis name's own thickness,
# and the reading that says the name is ALL THERE.
#
# WHY THE COLUMN ABOVE IS NOT ENOUGH, MEASURED RATHER THAN ARGUED. A first-ink
# column is answered by whatever the scan reaches first: the tick numbers, the
# frame, the title. It is not a measurement of the axis name, and it moves the
# WRONG WAY for the defect it is written about — with the clamp removed the
# small panel's name is not merely sliced, part of it is gone, and a name that
# is clipped away entirely leaves the tick numbers as the leftmost ink and a
# reading that looks HEALTHIER than a correct figure's. The run is what
# noticed: on clamp_removed, 16 August 2026, margin_panel's name ran 29 px
# intact and 17 px cut, while its gap GREW from 7 px to 13.
#
# The same reader as harness/drawlayer/drawlayer.sh's name_run_width, and
# deliberately the same: v66 §3 and v69 §4 measure the axis name and the
# bracket caption this way, and one answer to this trap in the repository is
# worth more than three that have to be compared.
margin_name_run () {
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

if command -v convert >/dev/null 2>&1; then
    for leg in margin_st margin_db margin_plain margin_panel margin_cat; do
        if [[ -s "$OUT/pic_$leg.png" ]]; then
            printf '%s_gap_px\t%s\n' "$leg" "$(margin_gap "$OUT/pic_$leg.png")" \
                >> "$TSV"
            # AND WHERE THE NAME'S OWN INK STARTS. Praat saves the selected
            # outer viewport and nothing outside it, so a name pushed past the
            # panel edge comes back sliced -- and a slice shows up here as ink
            # in column 0. Reported for every margin figure, shifted or not.
            printf '%s_name_left_px\t%s\n' "$leg" \
                "$(margin_name_left "$OUT/pic_$leg.png")" >> "$TSV"
            # AND HOW WIDE THAT INK RUNS, which is the reading that can only be
            # answered by the name itself. See margin_name_run above.
            printf '%s_name_run_px\t%s\n' "$leg" \
                "$(margin_name_run "$OUT/pic_$leg.png")" >> "$TSV"
            # AND THE PICTURE'S OWN WIDTH, so the inch-to-pixel scale the
            # displacement check needs is the harness's own resolution rather
            # than a dpi assumed here. A rig re-driven at another resolution
            # turns that check red instead of quietly rescaling every
            # displacement measured under it.
            printf '%s_width_px\t%s\n' "$leg" \
                "$(convert "$OUT/pic_$leg.png" -format '%w' info: 2>/dev/null)" \
                >> "$TSV"
        fi
    done
    # RULING 8c, measured the same way: how much ink is inside the frame of
    # the one-bin spectrum. The crop is the plot interior of a 6x4 figure at
    # 300 dpi -- the theme's own margins, 0.84" left and right, 0.39" top and
    # 0.5" bottom, taken in and rounded inwards so no frame line is counted as
    # data. A non-zero count means something was drawn; zero means the frame
    # is empty. The first version of this crop took the middle half of the
    # picture and reported the CONTROL as empty too, because the two-bin trace
    # runs along the top tenth of the frame -- a measurement that agrees with
    # the finding for the wrong reason is how a harness stops being evidence.
    if [[ -s "$OUT/pic_onebin.png" ]]; then
        printf 'onebin_interior_ink\t%s\n' \
            "$(convert "$OUT/pic_onebin.png" -crop 1280x920+260+125 +repage \
               -colorspace Gray -threshold 78% \
               -format '%[fx:int(w*h*(1-mean))]' info: 2>/dev/null)" >> "$TSV"
    fi
    # AND THE SAME FIGURE WITH TWO BINS IN RANGE, which is the control: if the
    # two-bin draw were empty as well the finding would be about something
    # else entirely, and the count below is what says it is not.
    if [[ -s "$OUT/pic_twobin.png" ]]; then
        printf 'twobin_interior_ink\t%s\n' \
            "$(convert "$OUT/pic_twobin.png" -crop 1280x920+260+125 +repage \
               -colorspace Gray -threshold 78% \
               -format '%[fx:int(w*h*(1-mean))]' info: 2>/dev/null)" >> "$TSV"
    fi
else
    printf 'margin_measurement\tno convert(1) on PATH\n' >> "$TSV"
fi

echo "axes: wrote $TSV"
grep -c . "$TSV" | sed 's/^/axes: rows /'
exit 0
