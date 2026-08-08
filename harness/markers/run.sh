#!/bin/bash
# ---------------------------------------------------------------------------
# POINT-MARKER DRIVER. Renders the palette's 24 point-marker styles, one
# figure each, and measures them ON THE PIXELS.
#
# Usage:  harness/markers/run.sh [style-filter]
# Output: harness/markers/out/<mode>_<shape>_<NN>.png   the figures
#         harness/markers/out/<mode>_<shape>_<NN>.log   the Praat transcript
#         harness/markers/out/MARKERS.tsv
#             mode shape style hue marker verdict cropW cropH
#             ink meanR meanG meanB  minR minG minB
#             row01..row16   col01..col16
#         harness/markers/out/FLOOR.tsv
#             px style marker verdict  row01..row16
#         harness/markers/out/look_<chart>_<mode>_<N>.png
#             real figures at 8 / 16 / 24 groups, for a human to look at
#         harness/markers/out/LOOKS.tsv     chart mode n verdict bytes
#
# WHY PIXELS, AND WHY NOT AREA. harness/patterns/run.sh separates fill
# patterns with a standard deviation, which works because a solid fill has
# none and a hatch has plenty. That will not separate SHAPES: the square is
# sized for equal area with the circle on purpose, so within a fixed crop the
# two put exactly the same amount of ink on the page and every summary of
# "how much ink" calls them identical. What differs is WHERE the ink is.
#
# So the measurement is a PROFILE. The crop -- a square centred on the marker,
# wide enough for all three shapes, computed by the Praat case in world
# coordinates -- is reduced to a binary ink mask (anything not within 5% of
# white is ink), then averaged to 16 rows and, separately, to 16 columns.
# Each number is the fraction of that row (or column) covered by ink.
#
#   circle    rows taper from a wide middle to nothing at both ends
#   square    rows are FLAT across the shape's height and zero outside it
#   triangle  rows ramp: widest at the base, nothing at the apex
#
# Those are three different functions, not three different totals, and the
# validator classifies on the shape of the profile. Fed two slots that differ
# only in hue it separates them on colour; fed two that differ only in shape
# it separates them on the profile; that is the whole 24.
#
# The mask is taken on LUMINANCE ONLY because it is a presence test, not a
# colour test -- the palest thing any of these charts draws is the B/W light
# ink at 0.79, well inside the 5% band. Colour is measured separately, from
# the mean of the crop's three channels, and the validator uses both.
#
# validate/v29_figure_disclosure.R reads MARKERS.tsv and LOOKS.tsv.
# ---------------------------------------------------------------------------
set -u
ROOT=/home/claude/EMLPraatTools
CASE=$ROOT/harness/markers/marker_case.praat
LOOK=$ROOT/harness/markers/look_case.praat
OUT=$ROOT/harness/markers/out
PRAAT=/home/claude/praat
PREFS=/home/claude/stress/prefs
FILTER="${1:-}"

mkdir -p "$OUT" "$PREFS"
: > "$OUT/MARKERS.tsv"
: > "$OUT/LOOKS.tsv"
# Clear stale per-style artefacts, so a run that renders fewer cases than the
# last one cannot be measured against the last one's leftovers.
rm -f "$OUT"/*.log "$OUT"/*.png

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# profile <img> <geometry>   -> 16 space-separated ink fractions, 0..1
profile () {
    convert "$1" -colorspace Gray -negate -threshold 5% \
        -scale "$2" -depth 8 txt:- 2>/dev/null |
    awk -F'gray\\(' '/gray\(/ { split($2, a, ")"); printf "%.4f ", a[1] / 255 }'
}

for mode in color bw; do
    for shape in point key keyline; do
        for style in $(seq 1 24); do
            [ -n "$FILTER" ] && [ "$FILTER" != "$style" ] && continue
            name=$(printf '%s_%s_%02d' "$mode" "$shape" "$style")
            rm -f "$OUT/$name.png"
            # DISPLAY deliberately unset: proves the case needs no X server.
            env -u DISPLAY EML_OUT="$OUT/$name.png" EML_MODE="$mode" \
                EML_SHAPE="$shape" EML_STYLE="$style" \
                "$PRAAT" --pref-dir="$PREFS" --run "$CASE" \
                > "$OUT/$name.log" 2>&1

            hue=$(sed -n 's/^STYLE .* hue=\([0-9]*\) .*$/\1/p' \
                  "$OUT/$name.log" | head -1)
            mk=$(sed -n 's/^STYLE .* marker=\([0-9]*\) .*$/\1/p' \
                 "$OUT/$name.log" | head -1)
            crop=$(grep '^CROP ' "$OUT/$name.log" | head -1)

            verdict=OK
            if [ ! -s "$OUT/$name.png" ]; then
                verdict=NO_FIGURE
            elif grep -qiE "^Error|not completed|Unknown variable" \
                    "$OUT/$name.log"; then
                verdict=DREW_THEN_FAILED
            elif [ -z "$crop" ]; then
                verdict=NO_CROP
            fi

            cw=NA; ch=NA; ink=NA; mr=NA; mg=NA; mb=NA
            mnR=NA; mnG=NA; mnB=NA
            rows=""; cols=""
            if [ "$verdict" = OK ]; then
                set -- $crop
                cx=$2; cy=$3; cw=$4; ch=$5
                if convert "$OUT/$name.png" \
                        -crop "${cw}x${ch}+${cx}+${cy}" +repage \
                        "$TMP/crop.png" 2>/dev/null; then
                    read -r mr mg mb <<< "$(convert "$TMP/crop.png" \
                        -format '%[fx:mean.r] %[fx:mean.g] %[fx:mean.b]' \
                        info: 2>/dev/null)"
                    ink=$(convert "$TMP/crop.png" -colorspace Gray -negate \
                        -threshold 5% -format '%[fx:mean]' info: 2>/dev/null)
                    # The MARKER'S OWN COLOUR, per channel. The crop is the
                    # marker on white, so the darkest value each channel
                    # reaches IS the marker -- exact, where the mean is the
                    # marker diluted by however much background the crop
                    # happens to contain.
                    for chan in R G B; do
                        v=$(convert "$TMP/crop.png" -channel "$chan" \
                            -separate -format '%[fx:minima]' info: 2>/dev/null)
                        case "$v" in *nan*|"") v=0 ;; esac
                        eval "mn$chan=\$v"
                    done
                    rows=$(profile "$TMP/crop.png" '1x16!')
                    cols=$(profile "$TMP/crop.png" '16x1!')
                    if [ -z "$rows" ] || [ -z "$cols" ]; then
                        verdict=PROFILE_FAILED
                    fi
                else
                    verdict=CROP_FAILED
                fi
            fi
            if [ "$verdict" != OK ]; then
                rows=$(for i in $(seq 16); do printf 'NA '; done)
                cols=$rows
            fi

            printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s' \
                "$mode" "$shape" "$style" "${hue:-NA}" "${mk:-NA}" \
                "$verdict" "${cw:-NA}" "${ch:-NA}" \
                "${ink:-NA}" "${mr:-NA}" "${mg:-NA}" "${mb:-NA}" \
                "${mnR:-NA}" "${mnG:-NA}" "${mnB:-NA}" \
                >> "$OUT/MARKERS.tsv"
            for v in $rows $cols; do printf '\t%s' "$v" >> "$OUT/MARKERS.tsv"; done
            printf '\n' >> "$OUT/MARKERS.tsv"
        done
    done
done

# ---------------------------------------------------------------------------
# THE SIZE LADDER. One circle, one square, one triangle at each of eight
# marker widths in device pixels, so the question "how small can a triangle
# get before it stops being a triangle" is answered by measurement instead of
# by assertion. A marker `px` pixels across has radius px/600 inches at
# 300 dpi. The smallest marker any of the four chart types actually asks for
# is @emlDrawScatterPlot's small dot, which is 21 pixels across on a 6 x 4
# figure; the ladder goes well below it on purpose.
# ---------------------------------------------------------------------------
: > "$OUT/FLOOR.tsv"
if [ -z "$FILTER" ]; then
    for px in 5 6 8 10 12 16 22 30; do
        half=$(awk -v p="$px" 'BEGIN { printf "%.6f", p / 600 }')
        for style in 1 9 17; do
            name=$(printf 'floor_%03d_%02d' "$px" "$style")
            rm -f "$OUT/$name.png"
            env -u DISPLAY EML_OUT="$OUT/$name.png" EML_MODE=color \
                EML_SHAPE=floor EML_STYLE="$style" EML_HALFIN="$half" \
                "$PRAAT" --pref-dir="$PREFS" --run "$CASE" \
                > "$OUT/$name.log" 2>&1
            mk=$(sed -n 's/^STYLE .* marker=\([0-9]*\) .*$/\1/p' \
                 "$OUT/$name.log" | head -1)
            crop=$(grep '^CROP ' "$OUT/$name.log" | head -1)
            verdict=OK
            if [ ! -s "$OUT/$name.png" ]; then
                verdict=NO_FIGURE
            elif grep -qiE "^Error|not completed|Unknown variable" \
                    "$OUT/$name.log"; then
                verdict=DREW_THEN_FAILED
            elif [ -z "$crop" ]; then
                verdict=NO_CROP
            fi
            rows=""
            if [ "$verdict" = OK ]; then
                set -- $crop
                if convert "$OUT/$name.png" -crop "$4x$5+$2+$3" +repage \
                        "$TMP/floor.png" 2>/dev/null; then
                    rows=$(profile "$TMP/floor.png" '1x16!')
                else
                    verdict=CROP_FAILED
                fi
            fi
            [ -z "$rows" ] && rows=$(for i in $(seq 16); do printf 'NA '; done)
            printf '%s\t%s\t%s\t%s' \
                "$px" "$style" "${mk:-NA}" "$verdict" >> "$OUT/FLOOR.tsv"
            for v in $rows; do printf '\t%s' "$v" >> "$OUT/FLOOR.tsv"; done
            printf '\n' >> "$OUT/FLOOR.tsv"
        done
    done
fi

# ---------------------------------------------------------------------------
# The look cases. Real figures, 12 x 7 inches, for a human to inspect and for
# the validator to confirm were produced at all.
# ---------------------------------------------------------------------------
if [ -z "$FILTER" ]; then
    for chart in scatter spaghetti; do
        for mode in color bw; do
            for n in 8 16 24; do
                name=$(printf 'look_%s_%s_%02d' "$chart" "$mode" "$n")
                rm -f "$OUT/$name.png"
                env -u DISPLAY EML_OUT="$OUT/$name.png" EML_MODE="$mode" \
                    EML_CHART="$chart" EML_NGROUPS="$n" \
                    "$PRAAT" --pref-dir="$PREFS" --run "$LOOK" \
                    > "$OUT/$name.log" 2>&1
                verdict=OK
                if [ ! -s "$OUT/$name.png" ]; then
                    verdict=NO_FIGURE
                elif grep -qiE "^Error|not completed|Unknown variable" \
                        "$OUT/$name.log"; then
                    verdict=DREW_THEN_FAILED
                fi
                bytes=$(stat -c%s "$OUT/$name.png" 2>/dev/null || echo 0)
                printf '%s\t%s\t%s\t%s\t%s\n' \
                    "$chart" "$mode" "$n" "$verdict" "$bytes" \
                    >> "$OUT/LOOKS.tsv"
            done
        done
    done
fi

awk -F"\t" '{ printf "%-5s %-7s %2s hue=%2s mk=%s %-10s ink=%.3f mean=%.3f,%.3f,%.3f\n", \
              $1, $2, $3, $4, $5, $6, $9, $10, $11, $12 }' \
    "$OUT/MARKERS.tsv"
