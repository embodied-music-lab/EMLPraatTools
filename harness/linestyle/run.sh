#!/usr/bin/env bash
# ============================================================================
# harness/linestyle/run.sh — the four pens, driven and photographed
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Every case is one or more presses of Draw through the graphs form's own
# dispatch, with the per-type line-style variable set to what its dialog would
# have set it to and the request published and cleared exactly as the form
# publishes and clears it. One praat process per case: a Praat script error
# aborts the script, so a single process running every case reports one
# failure and hides the rest.
#
# Run from anywhere:  bash harness/linestyle/run.sh [case-substring]
#
# THE FILTER IS FOR DEBUGGING ONE CASE AND LEAVES A PARTIAL ARTEFACT. The TSV
# is rewritten from scratch on every run; validate/v96 censuses the cases it
# finds against the ones it asserts on and goes red on the difference.
#
# Output: harness/linestyle/out/<case>.png, <case>.log
#         harness/linestyle/out/LINESTYLE.tsv    case, key, value
# Exit 0 = every case drew and saved.
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
OUT="${EML_LINESTYLE_DIR:-$SCRIPT_DIR/out}"
PREFS="$SCRIPT_DIR/prefs"
FILTER="${1:-}"
mkdir -p "$OUT" "$PREFS"
TSV="$OUT/LINESTYLE.tsv"

# ============================================================================
# THE ARTEFACT IS BUILT BESIDE ITSELF AND MOVED INTO PLACE, AND THE ROWS ARE
# COUNTED ON THE WAY OUT
# ============================================================================
# WHY, MEASURED. On 18 August 2026 a full run of this driver left a
# LINESTYLE.tsv holding 854 rows with 610 distinct (case, key) pairs in it:
# whole fragments of one case's rows sitting inside another's, every duplicate
# an exact copy of a row that was also somewhere else. Nothing in the file
# DISAGREED with itself -- no (case, key) pair carried two different values --
# but validate/v96 reads one measurement by name and treats two answers as
# none, so a run in that state reports missing measurements rather than the
# figures it had just made.
#
# WHAT IS NOT CLAIMED HERE IS THE CAUSE. Tested on its own, on the same
# filesystem and the same directory, `: > file` truncates and three hundred
# appends in a loop arrive as three hundred lines; nothing in the loop below
# writes twice. The mechanism was not run to ground, and this comment does not
# invent one.
#
# WHAT IS DONE ABOUT IT IS WORTH DOING WHATEVER THE CAUSE. Every row goes to a
# private file named for this process; that file is MOVED over the destination
# in one step when the run is finished, so a reader never sees a half-written
# artefact and never sees the previous run's rows under this one's. And the
# driver COUNTS what it emitted and compares that with what is on the disk. A
# run whose artefact does not hold the number of rows the run emitted says so,
# loudly, and exits non-zero -- because a driver that hands a scrambled file to
# a validator quietly is worse than one that fails.
TMP="$OUT/.LINESTYLE.$$.tsv"
: > "$TMP"

fail=0
emitted=0
emit () {
    printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$TMP"
    emitted=$((emitted + 1))
}

# HOW MANY PIXELS OF ONE EXACT COLOUR, the same grep harness/secondaxis
# measures the palette slots with: ImageMagick's txt: form writes one line per
# pixel with the hex on it, so no image library and no numeric tolerance.
inkpx () { convert "$1" txt:- 2>/dev/null | grep -c "$2"; }

# HOW MANY MUTED-BLUE PIXELS, ANYWHERE ON THE PAGE. The spaghetti plot draws
# its strands through @emlLightenColor at 0.6, which puts slot one's blue at
# about (153, 199, 224) -- LIGHTER than the 50% grey every other ink
# measurement in this tree thresholds at, so a dark-pixel count cannot see a
# strand at all. Light and clearly blue is what a strand is and what nothing
# else on that figure is: the mean overlay is the same hue but dark, the frame
# and the text are neutral, and the gridlines are neutral.
#
# The triple is pulled out with sed rather than split on commas -- the txt:
# line begins "1499,0:", so a comma split reads the pixel's COORDINATES as its
# colour, which is the trap harness/secondaxis/run.sh records hitting.
mutedpx () {
    convert "$1" txt:- 2>/dev/null \
    | sed -n 's/.*srgb(\([0-9]*\),\([0-9]*\),\([0-9]*\)).*/\1 \2 \3/p' \
    | awk '{ if ($1 > 110 && $3 - $1 > 40) n++ } END { print n+0 }'
}

for f in "$SCRIPT_DIR"/*.praat; do
    name=$(basename "$f" .praat)
    # The two files that are not cases: the shared fixture and the objects it
    # builds, split out so a replay could rebuild them without loading the
    # plugin twice.
    case "$name" in fixture|data) continue ;; esac
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
    # WHAT THE PRESS ASKED FOR, printed by the fixture's @lsReport from the
    # plugin's own @emlLineStyleName rather than restated by this driver.
    for key in STYLE STYLENAME TYPE; do
        emit "$name" "$(echo "$key" | tr 'A-Z' 'a-z')" \
            "$(sed -n "s/^$key //p" "$OUT/$name.log" | tail -1)"
    done
    if [ -s "$OUT/$name.png" ]; then
        emit "$name" png_px "$(identify -format '%wx%h' "$OUT/$name.png" 2>/dev/null)"
        emit "$name" png_md5 "$(md5sum "$OUT/$name.png" | cut -d' ' -f1)"
        # Slot one of the colour palette by its exact hex: "the series is
        # still the series" while its pen changes.
        emit "$name" ink_slot1_px "$(inkpx "$OUT/$name.png" '#0073B3')"
        emit "$name" muted_px "$(mutedpx "$OUT/$name.png")"
        # THE RUN STRUCTURE ALONG THE STROKE, and the frame's own edges. See
        # stroke.py: a count of pixels cannot tell Dashed from Dashed-dotted,
        # and a leaked pen shows up on the frame rather than on the series.
        # A page with four panels on it has no single frame spanning half the
        # image, and stroke.py says so in one row rather than in a row of NAs.
        # Its exit status is not a driver failure: the case still drew.
        python3 "$SCRIPT_DIR/stroke.py" "$OUT/$name.png" \
            > "$OUT/$name.stroke" 2>"$OUT/$name.stroke.err" || true
        while IFS=$'\t' read -r k v; do
            [ -n "$k" ] && emit "$name" "$k" "$v"
        done < "$OUT/$name.stroke"
    fi
    printf '  %-26s %s\n' "$name" "$verdict"
done

# ============================================================================
# THE DETAIL STRIP -- the four pens at 100%, one above the other
# ============================================================================
# WHY IT EXISTS. fourstyles.png is the four-panel page, and it is the right
# artefact for the record: four presses of Draw, laid out by the page
# composition, each panel labelled with the option that drew it. But a reader
# looking at that page scaled to fit a screen is looking at a quarter-size
# copy, and at quarter size a dash and a dash-dot are the same grey line. The
# strip is the SAME FOUR FILES, cropped to one stretch of stroke at full
# resolution and stacked in menu order -- Solid, Dotted, Dashed,
# Dashed-dotted. Nothing is redrawn for it and nothing is scaled.
if [ -s "$OUT/ts_solid.png" ]; then
    det=""
    for s in solid dotted dashed dashdot; do
        convert "$OUT/ts_$s.png" -crop 760x150+420+560 +repage \
            "$OUT/_detail_$s.png" 2>/dev/null && det="$det $OUT/_detail_$s.png"
    done
    # shellcheck disable=SC2086
    montage $det -tile 1x4 -geometry +6+6 -background gray70 \
        "$OUT/PENS_DETAIL.png" 2>/dev/null
    rm -f "$OUT"/_detail_*.png
    [ -s "$OUT/PENS_DETAIL.png" ] && \
        emit detail png_md5 "$(md5sum "$OUT/PENS_DETAIL.png" | cut -d' ' -f1)"
    [ -s "$OUT/PENS_DETAIL.png" ] && \
        emit detail png_px "$(identify -format '%wx%h' "$OUT/PENS_DETAIL.png")"
fi

# ============================================================================
# THE REPLAY. recorded_wave emitted a script; this runs it and compares the
# picture with the one the session drew.
# ============================================================================
# WHY IT IS DONE HERE AND NOT AS ANOTHER CASE: the emitted file is an input
# that does not exist until the recorded case has run, and it needs two
# mechanical edits no Praat script can make to itself -- the library include
# paths point at an INSTALLED plugin (~/.praat-dir/...) and are pointed at
# this repository instead, and the objects the workflow ran on have to be in
# the Objects window before the step that selects them.
#
# A BYTE-IDENTICAL PNG IS THE CLAIM. The pen is not an argument of
# @emlDrawWaveform; if the recorder had not carried it, the replay would draw
# a solid waveform and the file would differ.
REC="$OUT/recorded_script.praat"
if [ -s "$REC" ]; then
    REP="$OUT/replay_script.praat"
    sed "s|~/.praat-dir/plugin_EML_StatsGraphs|$EML_ROOT/plugin_EML_StatsGraphs|g" \
        "$REC" > "$REP.tmp"
    awk -v datafile="$SCRIPT_DIR/data.praat" '
        { print }
        /^@emlClearAnnotations$/ && !done {
            while ((getline line < datafile) > 0) print line
            done = 1
        }' "$REP.tmp" > "$REP"
    rm -f "$REP.tmp"
    # THE SAME RECTANGLE, SAID OUT LOUD. The recorded session saved the
    # plugin's own extent union (@emlAssertFullViewport); a bare save writes
    # whatever viewport was last selected, which is the inner panel.
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
    done < <(grep -E '^(lineStyle|eraseFirst)[ ]*=' "$REC")
fi

# THE MOVE, AND THE COUNT THAT MAKES IT CHECKABLE.
mv -f "$TMP" "$TSV"
written=$(wc -l < "$TSV")
echo "LINESTYLE.tsv: $written rows"
if [ "$written" != "$emitted" ]; then
    echo "linestyle: FAIL -- the driver emitted $emitted rows and the file holds $written."
    echo "           The artefact is not what this run measured. Do not read it."
    fail=1
fi
[ $fail -eq 0 ] && echo "linestyle: PASS" || echo "linestyle: FAIL"
exit $fail
