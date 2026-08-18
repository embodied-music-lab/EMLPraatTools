#!/usr/bin/env bash
# ============================================================================
# harness/secondaxis/run.sh — the second vertical axis and the pens, driven
# ============================================================================
# Every case is one press of Draw through @emlGraphsDrawWithLegendRoom, the
# graphs form's own dispatch loop, with the request globals set to what the
# follow-up pause would have set them to. One praat process per case: a Praat
# script error aborts the script, so a single process running every case
# reports one failure and hides the rest.
#
# Run from anywhere:  bash harness/secondaxis/run.sh [case-substring]
#
# THE FILTER IS FOR DEBUGGING ONE CASE AND LEAVES A PARTIAL ARTEFACT. The TSV
# is rewritten from scratch on every run; validate/v95 censuses the cases it
# finds against the ones it asserts on and goes red on the difference.
#
# Output: harness/secondaxis/out/<case>.png, <case>.log
#         harness/secondaxis/out/SECONDAXIS.tsv   case, key, value
# Exit 0 = every case drew and saved.
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$SCRIPT_DIR/.." && pwd)/_env.sh" || exit 1
OUT="${EML_SECONDAXIS_DIR:-$SCRIPT_DIR/out}"
PREFS="$SCRIPT_DIR/prefs"
FILTER="${1:-}"
mkdir -p "$OUT" "$PREFS"
TSV="$OUT/SECONDAXIS.tsv"
: > "$TSV"

fail=0
emit () { printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$TSV"; }

# HOW MANY PIXELS OF ONE EXACT COLOUR. ImageMagick's txt: form writes one
# line per pixel with the hex on it, so the count is a grep -- no image
# library, no numeric tolerance, and the same tool every other harness in this
# tree measures with.
inkpx () { convert "$1" txt:- 2>/dev/null | grep -c "$2"; }

# HOW MANY REDDISH PIXELS IN A REGION. Not an exact colour: an anti-aliased
# red stroke lays down a spread of pinks, and the question here is whether ANY
# red reached the region at all. r clearly above both g and b is that
# question, and it cannot be answered by a grep for one hex.
# HOW MANY RED PIXELS IN A REGION. Not an exact colour: an anti-aliased red
# stroke lays down a spread of pinks, and the question is whether ANY red
# reached the region. The triple is pulled out with sed rather than split on
# commas -- the txt: line begins "1499,0:", so a comma split reads the pixel's
# COORDINATES as its colour, which is how this measurement first came back
# saying every figure was red.
#
# A HANDFUL OF RED PIXELS IS NOT INK. Text is drawn with subpixel
# anti-aliasing, so a black glyph carries coloured fringes: measured, the
# right margin of the probe holds 21 red pixels off the tick numbers and the
# axis name against 800 on the stroke inside the plot. The validator compares
# the two rather than requiring a zero that no rendered text can give.
redpx () {
    convert "$1" -crop "$2" +repage txt:- 2>/dev/null \
    | sed -n 's/.*srgb(\([0-9]*\),\([0-9]*\),\([0-9]*\)).*/\1 \2 \3/p' \
    | awk '{ if ($1 > 150 && $2 < 80 && $3 < 80) n++ } END { print n+0 }'
}

for f in "$SCRIPT_DIR"/*.praat; do
    name=$(basename "$f" .praat)
    # THE THREE FILES THAT ARE NOT CASES: the shared fixture, the table it
    # builds (split out so the replay can rebuild it without loading the
    # plugin twice), and the GUI driver, which gui_pause.sh runs under a
    # display of its own.
    case "$name" in fixture|data|gui_driver) continue ;; esac
    [ -n "$FILTER" ] && case "$name" in *"$FILTER"*) ;; *) continue ;; esac
    rm -f "$OUT/$name.png"
    # DISPLAY deliberately unset: proves the case needs no X server, and stops
    # a stray connection to an interactive instance.
    ( cd "$SCRIPT_DIR" && env -u DISPLAY EML_OUT="$OUT/$name.png" \
        timeout 300 "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" --run "$f" \
        > "$OUT/$name.log" 2>&1 )
    if [ -s "$OUT/$name.png" ]; then
        if grep -qiE "^Error|not completed" "$OUT/$name.log"; then
            verdict=DREW_THEN_FAILED; fail=1
        else
            verdict=OK
        fi
    else
        verdict=NO_FIGURE; fail=1
    fi
    emit "$name" verdict "$verdict"
    # WHAT THE DRAW RESOLVED, read from the draw procedure's own published
    # names by the fixture's @secondReport rather than recomputed here.
    for key in SECONDON RIGHTSLOT; do
        emit "$name" "$(echo "$key" | tr 'A-Z' 'a-z')" \
            "$(sed -n "s/^$key //p" "$OUT/$name.log" | tail -1)"
    done
    set -- $(sed -n 's/^LEFT //p' "$OUT/$name.log" | tail -1)
    emit "$name" left_min "${1:-}" ; emit "$name" left_max "${2:-}"
    set -- $(sed -n 's/^RIGHT //p' "$OUT/$name.log" | tail -1)
    emit "$name" right_min "${1:-}" ; emit "$name" right_max "${2:-}"
    emit "$name" left_ink "$(sed -n 's/^LEFTINK //p' "$OUT/$name.log" | tail -1)"
    emit "$name" right_ink "$(sed -n 's/^RIGHTINK //p' "$OUT/$name.log" | tail -1)"
    # THE REFUSAL, VERBATIM. One line, so a validator can quote the sentence
    # the user reads rather than a paraphrase of it.
    emit "$name" refusal "$(sed -n 's/^NOTE: a second right-hand y-axis was requested and refused. //p' "$OUT/$name.log" | tail -1)"
    emit "$name" note_lines "$(grep -c '^NOTE: ' "$OUT/$name.log")"
    if [ -s "$OUT/$name.png" ]; then
        emit "$name" png_px "$(identify -format '%wx%h' "$OUT/$name.png" 2>/dev/null)"
        emit "$name" png_md5 "$(md5sum "$OUT/$name.png" | cut -d' ' -f1)"
        # THE INK, COUNTED OFF THE RENDERED PIXELS. Slot one and slot two of
        # the colour palette, by their exact hex, so that "the second series
        # took slot two" is a statement about the image rather than about a
        # variable the same code set. A dashed or dotted series lays down
        # fewer pixels than a solid one of the same length, which is how the
        # pens are measured too.
        emit "$name" ink_slot1_px "$(inkpx "$OUT/$name.png" '#0073B3')"
        emit "$name" ink_slot2_px "$(inkpx "$OUT/$name.png" '#E69E00')"
        # RED, INSIDE THE PLOT AND IN THE RIGHT MARGIN, for the margin-ink
        # probe: the question is whether a coloured pen reaches the margin
        # commands at all. Counted for every case because a region that
        # should hold no red in one case should hold none in any of them.
        emit "$name" red_plot_px "$(redpx "$OUT/$name.png" '1350x1200+150+0')"
        emit "$name" red_margin_px "$(redpx "$OUT/$name.png" '280x1200+1520+0')"
    fi
done

# ============================================================================
# THE REPLAY. The recorded case emitted a script; this runs it and compares
# the picture with the one the session drew.
# ============================================================================
# WHY IT IS DONE HERE AND NOT AS ANOTHER CASE: the emitted file is an input
# that does not exist until the recorded case has run, and it needs two
# mechanical edits no Praat script can make to itself -- the library include
# paths point at an INSTALLED plugin (~/.praat-dir/...) and are pointed at
# this repository instead, and the data the workflow ran on has to be in the
# Objects window before the step that selects it.
#
# A BYTE-IDENTICAL PNG IS THE CLAIM. The emitted script carries the second
# axis in its editable block; if the block or the step were wrong, the replay
# would draw one axis, or a solid line, and the file would differ.
REC="$OUT/recorded_script.praat"
if [ -s "$REC" ]; then
    REP="$OUT/replay_script.praat"
    sed "s|~/.praat-dir/plugin_EML_StatsGraphs|$EML_ROOT/plugin_EML_StatsGraphs|g" \
        "$REC" > "$REP.tmp"
    # The data, inserted where the library has just been loaded and before
    # anything selects it.
    awk -v datafile="$SCRIPT_DIR/data.praat" '
        { print }
        /^@emlClearAnnotations$/ && !done {
            while ((getline line < datafile) > 0) print line
            done = 1
        }' "$REP.tmp" > "$REP"
    rm -f "$REP.tmp"
    # THE SAME RECTANGLE, SAID OUT LOUD. The recorded session saved the
    # plugin's own extent union (@emlAssertFullViewport); a bare save writes
    # whatever viewport was last selected, which is the inner panel. The
    # figure is 6 x 4 at the origin in both, so naming it makes the two files
    # comparable byte for byte instead of comparable in spirit.
    printf 'Select outer viewport: 0, 6, 0, 4\n' >> "$REP"
    printf 'Save as 300-dpi PNG file: "%s"\n' "$OUT/replay.png" >> "$REP"
    rm -f "$OUT/replay.png"
    ( cd "$SCRIPT_DIR" && env -u DISPLAY timeout 300 "$PRAAT" $PRAAT_TRUST \
        --pref-dir="$PREFS" --run "$REP" > "$OUT/replay.log" 2>&1 )
    if [ -s "$OUT/replay.png" ]; then
        emit replay verdict OK
        emit replay png_md5 "$(md5sum "$OUT/replay.png" | cut -d' ' -f1)"
        emit replay png_px "$(identify -format '%wx%h' "$OUT/replay.png" 2>/dev/null)"
    else
        emit replay verdict NO_FIGURE; fail=1
    fi
    # WHAT THE BLOCK DECLARED, one row per variable, so a validator reads the
    # emitted block by name instead of grepping a file it has to locate.
    while IFS= read -r line; do
        key=$(printf '%s' "$line" | sed -E 's/^([A-Za-z0-9_$]+)[ ]*=.*/\1/')
        val=$(printf '%s' "$line" | sed -E 's/^[A-Za-z0-9_$]+[ ]*=[ ]*//; s/[ ]*;.*$//')
        emit block "$key" "$val"
    done < <(grep -E '^(lineStyle|secondAxis[A-Za-z]*\$?)[ ]*=' "$REC")
fi

awk -F"\t" '{printf "%-20s %-12s %s\n", $1, $2, $3}' "$TSV"
[ $fail -eq 0 ] && echo "secondaxis: PASS" && exit 0
echo "secondaxis: FAIL"
exit 1
