#!/bin/bash
# ---------------------------------------------------------------------------
# FILL-PATTERN DRIVER. Renders the palette's 24 sub-group styles, one figure
# each, and measures them ON THE PIXELS.
#
# Usage:  harness/patterns/run.sh [style-filter]
# Output: harness/patterns/out/<mode>_<shape>_<NN>.png   the figures
#         harness/patterns/out/<mode>_<shape>_<NN>.log   the Praat transcript
#         harness/patterns/out/STYLES.tsv
#             mode shape style hue pattern verdict cropW cropH
#             meanR meanG meanB  sdR sdG sdB  rowR rowG rowB  colR colG colB
#             minR minG minB  maxR maxG maxB
#
# WHY PIXELS. @emlSetColorPalette declared ten fill/line pairs for years while
# slots 9 and 10 were literal duplicates of 1 and 2, and every check that read
# the palette table agreed that there were ten. The only check that would have
# caught it is one that reads the rendered image, so that is what this is.
#
# THE NUMBERS, and what each separates:
#   meanR/G/B  the mark's average colour. Separates HUES.
#   sdC        standard deviation over the crop, PER CHANNEL. ~0 for a solid
#              fill, large for any pattern. Separates SOLID from PATTERNED.
#   rowC       standard deviation of the 32-row mean profile, per channel. A
#              45-degree hatch puts the same amount of ink in every row, so
#              its row profile is nearly flat; a dot grid leaves whole rows
#              empty between dot rows, so its row profile swings. The RATIO
#              row/sd separates HATCH from DOTS and is scale-free.
#   colC       the same along columns, per channel, as a cross-check.
#   minC/maxC  the darkest and lightest value present, per channel. A drawn
#              mark is exactly TWO colours -- its fill and its pattern ink --
#              so this pair DESCRIBES THE MARK COMPLETELY, while the mean is
#              only their weighted average. That matters: on the greyscale
#              ramp a light fill under dark ink and a dark fill under light
#              ink can average to nearly the same grey while looking nothing
#              alike, and a mean-only comparison would call them confusable
#              when a reader would not.
#
# PER CHANNEL, not on a luminance conversion, because the palette contains a
# pair that a luminance conversion loses: Okabe-Ito yellow is fill
# {0.99, 0.97, 0.78} against line {0.95, 0.90, 0.25}, which differ almost
# only in BLUE. Rec.601 luminance weights blue at 0.114, so a grey conversion
# flattened the yellow dot grid to a near-uniform field and mis-classified it
# as a hatch. The channel that actually carries the pattern is chosen in the
# validator.
#
# Each crop rectangle is computed by harness/patterns/style_case.praat itself,
# in world coordinates, and printed as a CROP record -- the shell does not
# guess where the mark is.
#
# validate/v29_figure_disclosure.R reads STYLES.tsv.
# ---------------------------------------------------------------------------
set -u
ROOT=/home/claude/EMLPraatTools
CASE=$ROOT/harness/patterns/style_case.praat
OUT=$ROOT/harness/patterns/out
PRAAT=/home/claude/praat
PREFS=/home/claude/stress/prefs
FILTER="${1:-}"

mkdir -p "$OUT" "$PREFS"
: > "$OUT/STYLES.tsv"
# Clear stale per-style artefacts, so a run that renders fewer cases than the
# last one cannot be measured against the last one's leftovers.
rm -f "$OUT"/*.log "$OUT"/*.png

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

for mode in color bw; do
    for shape in violin box swatch; do
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
            pat=$(sed -n 's/^STYLE .* pattern=\([0-9]*\) .*$/\1/p' \
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

            cw=NA; ch=NA
            mr=NA; mg=NA; mb=NA
            sdR=NA; sdG=NA; sdB=NA
            rwR=NA; rwG=NA; rwB=NA
            clR=NA; clG=NA; clB=NA
            mnR=NA; mnG=NA; mnB=NA
            mxR=NA; mxG=NA; mxB=NA
            if [ "$verdict" = OK ]; then
                set -- $crop
                cx=$2; cy=$3; cw=$4; ch=$5
                if convert "$OUT/$name.png" \
                        -crop "${cw}x${ch}+${cx}+${cy}" +repage \
                        "$TMP/crop.png" 2>/dev/null; then
                    read -r mr mg mb <<< "$(convert "$TMP/crop.png" \
                        -format '%[fx:mean.r] %[fx:mean.g] %[fx:mean.b]' \
                        info: 2>/dev/null)"
                    for chan in R G B; do
                        # ImageMagick prints "-nan" for the standard deviation
                        # of a perfectly uniform region. That is a real zero,
                        # not a failure; it is normalised here so the TSV
                        # carries numbers.
                        read -r s1 s4 s5 <<< "$(convert "$TMP/crop.png" \
                             -channel "$chan" -separate \
                             -format '%[fx:standard_deviation] %[fx:minima] %[fx:maxima]' \
                             info: 2>/dev/null)"
                        s2=$(convert "$TMP/crop.png" -channel "$chan" \
                             -separate -scale 1x32! \
                             -format '%[fx:standard_deviation]' \
                             info: 2>/dev/null)
                        s3=$(convert "$TMP/crop.png" -channel "$chan" \
                             -separate -scale 32x1! \
                             -format '%[fx:standard_deviation]' \
                             info: 2>/dev/null)
                        case "$s1" in *nan*|"") s1=0 ;; esac
                        case "$s2" in *nan*|"") s2=0 ;; esac
                        case "$s3" in *nan*|"") s3=0 ;; esac
                        case "$s4" in *nan*|"") s4=0 ;; esac
                        case "$s5" in *nan*|"") s5=0 ;; esac
                        eval "sd$chan=\$s1"
                        eval "rw$chan=\$s2"
                        eval "cl$chan=\$s3"
                        eval "mn$chan=\$s4"
                        eval "mx$chan=\$s5"
                    done
                else
                    verdict=CROP_FAILED
                fi
            fi

            printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
                "$mode" "$shape" "$style" "${hue:-NA}" "${pat:-NA}" \
                "$verdict" "${cw:-NA}" "${ch:-NA}" \
                "${mr:-NA}" "${mg:-NA}" "${mb:-NA}" \
                "$sdR" "$sdG" "$sdB" "$rwR" "$rwG" "$rwB" \
                "$clR" "$clG" "$clB" "$mnR" "$mnG" "$mnB" \
                "$mxR" "$mxG" "$mxB" >> "$OUT/STYLES.tsv"
        done
    done
done

awk -F"\t" '{ sd = $12; if ($13 > sd) sd = $13; if ($14 > sd) sd = $14;
              rw = $15; if ($16 > rw) rw = $16; if ($17 > rw) rw = $17;
              printf "%-5s %-6s %2s hue=%2s pat=%s %-10s mean=%.3f,%.3f,%.3f sdmax=%.4f rowmax=%.4f ratio=%.3f\n", \
              $1, $2, $3, $4, $5, $6, $9, $10, $11, sd, rw, (sd > 0 ? rw / sd : 0) }' \
    "$OUT/STYLES.tsv"
