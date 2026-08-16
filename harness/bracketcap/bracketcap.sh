#!/usr/bin/env bash
# ============================================================================
# harness/bracketcap/bracketcap.sh — render the bracket layout and READ THE
#                                    CAPTION BACK OFF THE PICTURE
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Eight legs, one Praat process each, because a Praat script error aborts the
# script: eight legs in one process report one failure and hide seven.
#
# AUTHOR RULING C, 16 August 2026, added mw_two and changed what welch_two is
# for. Both two-group arms of @emlBridgeGroupComparison now name their test --
# in the caption band AND in the corner box -- so welch_two is no longer the
# leg that proves a caption correctly declines, and mw_two is its
# nonparametric twin so that neither two-group arm can be repaired alone.
# validate/v76 reads both.
#
# WHAT THIS ADDS THAT THE PRAAT DRIVE CANNOT. bracketcap_drive.praat emits
# what the plugin BELIEVES about the caption — the strings it composed, the
# size it settled on, the width against the room. Every one of those numbers
# is emitted identically by a build whose caption is drawn perfectly and then
# cropped off the export, because the crop happens in the SAVE, after the last
# number is taken. So this script does three things to the file on disk that
# no Praat variable can do:
#
#   OCR. tesseract reads the caption band back as text. The author's
#   instruction was to prove it by drawing both arms and reading the words off
#   the picture, not out of the source, and this is that step. It is the only
#   evidence that survives a fix which composes the right sentence and renders
#   a different one, or none.
#
#   THE INK BOX, ON BOTH SIDES. Clipping is what a caption that is too wide
#   actually does: it renders, and its tail is not in the file. The words that
#   survive are the ones at the START of the line, so the first ink in the
#   band sits exactly where a correct caption's first ink sits — a check
#   anchored there moves the WRONG WAY for the defect it is meant to catch,
#   and would be greenest on the worst case. Both edges are measured, and the
#   verdict is the distance from the ink to the image edge on the RIGHT as
#   well as the left.
#
#   INK AT ALL, IN THE BAND. A caption band with a correct height and nothing
#   in it produces a taller PNG and a bigger file, and a size threshold reads
#   a bigger file as more evidence. Ink is counted inside the band's own rows.
#
# Output: harness/bracketcap/out/<leg>.png      the figure
#         harness/bracketcap/out/<leg>.kv       key<TAB>value from Praat
#         harness/bracketcap/out/<leg>.log      the process transcript
#         harness/bracketcap/out/<leg>.ocr      the OCR of the caption band
#         harness/bracketcap/out/BRACKETCAP.tsv one row per leg, read by v69
#
# The shadow-tree overrides exist for harness/bracketcap/break.sh: EML_BC_SRC
# points the drive at a COPY of the repository carrying one deliberate defect,
# EML_BC_OUTDIR sends its artefacts somewhere the working tree never sees.
# Neither is set in normal use.
#
#   Run:  bash harness/bracketcap/bracketcap.sh [leg-name-substring]
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ============================================================================
set -u

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../_env.sh" || exit 1
ROOT="${EML_BC_SRC:-$EML_ROOT}"
DRIVE="$ROOT/harness/bracketcap/bracketcap_drive.praat"
OUT="${EML_BC_OUTDIR:-$ROOT/harness/bracketcap/out}"
PREFS="$ROOT/harness/bracketcap/prefs"
FILTER="${1:-}"
TSV="$OUT/BRACKETCAP.tsv"

mkdir -p "$OUT" "$PREFS"

# A RENAMED LEG MUST NOT LEAVE ITS OLD ARTEFACT BEHIND. Measured on
# harness/disclosure 7 Aug 2026: gviolin11 became gviolin25 and the validator
# went on reading the previous run's log and passing. Only cleared on a full
# run, so a filtered re-run of one leg does not destroy the other six.
if [ -z "$FILTER" ]; then
    rm -f "$OUT"/*.png "$OUT"/*.kv "$OUT"/*.log "$OUT"/*.ocr
    : > "$TSV"
fi

kv () {  # kv <file> <key>  -> value, or empty
    awk -F'\t' -v k="$2" '$1 == k { print $2; exit }' "$1" 2>/dev/null
}

for leg in tukey dunn_holm dunn_bonferroni dunn_bh narrow welch_two mw_two ns_omnibus; do
    [ -n "$FILTER" ] && case "$leg" in *"$FILTER"*) ;; *) continue ;; esac
    KVF="$OUT/$leg.kv"
    PNG="$OUT/$leg.png"
    rm -f "$KVF" "$PNG" "$OUT/$leg.ocr"

    # DISPLAY deliberately unset: proves the path needs no X server, and stops
    # an X server that happens to exist from changing a verdict.
    env -u DISPLAY EML_BC_LEG="$leg" EML_BC_OUT="$KVF" EML_BC_PIC="$PNG" \
        "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" --run "$DRIVE" \
        > "$OUT/$leg.log" 2>&1

    if [ ! -s "$PNG" ]; then
        verdict=NO_FIGURE
    elif grep -qiE "^Error|not completed|Unknown variable" "$OUT/$leg.log"; then
        verdict=DREW_THEN_FAILED
    else
        verdict=OK
    fi

    # --- read the caption band off the file ---------------------------------
    # The saved image is the EXTENT box, not the figure box, so the inches ->
    # pixels scale is taken from the extent the drive emitted and the pixel
    # height the file actually has. Deriving it from a hardcoded 300 dpi would
    # be a second opinion that can disagree with the file.
    ocr="" ; ink=0 ; inkl=-1 ; inkr=-1 ; imgw=0 ; imgh=0
    if [ -s "$PNG" ]; then
        read -r imgw imgh < <(identify -format "%w %h" "$PNG" 2>/dev/null)
        python3 "$ROOT/harness/bracketcap/band.py" \
            "$PNG" "$(kv "$KVF" extent_min_y_in)" "$(kv "$KVF" extent_max_y_in)" \
            "$(kv "$KVF" cap_top_in)" "$(kv "$KVF" cap_bottom_in)" \
            "$OUT/$leg.band.png" > "$OUT/$leg.band.txt" 2>"$OUT/$leg.band.err"
        ink=$(sed -n 's/^ink_px\t//p'    "$OUT/$leg.band.txt")
        inkl=$(sed -n 's/^ink_left\t//p'  "$OUT/$leg.band.txt")
        inkr=$(sed -n 's/^ink_right\t//p' "$OUT/$leg.band.txt")
        if [ -s "$OUT/$leg.band.png" ]; then
            # -psm 6: a block of text. The caption may be one line or two and
            # 7 (single line) drops the second.
            ocr=$(tesseract "$OUT/$leg.band.png" - --psm 6 2>/dev/null \
                  | tr '\n' ' ' | tr -s ' ' | sed 's/^ *//; s/ *$//')
            printf '%s\n' "$ocr" > "$OUT/$leg.ocr"
        fi

        # THE FIGURE ABOVE THE BAND, READ SEPARATELY. A caption must be
        # ADDITIVE: it may not cost the figure anything it already carried.
        # The way it can is the viewport -- this procedure moves the world to
        # draw its band, and whatever the caller draws next lands in that band
        # if the world is not put back. Measured 16 Aug 2026 against a copy
        # with the restore deleted: the caption was perfect, the plot was
        # perfect, and the omnibus box -- "One-way ANOVA: F(3, 44) = 559.05,
        # p < .001" -- was simply not on the figure. Nothing in the band tells
        # you that; the band was exactly right. So the region ABOVE the band
        # is OCR'd too, and v69 asserts the omnibus line survived.
        band_top=$(sed -n 's/^band_top_px\t//p' "$OUT/$leg.band.txt")
        [ -z "${band_top:-}" ] && band_top=-1
        [ "$band_top" -le 0 ] && band_top="$imgh"
        convert "$PNG" -crop "${imgw}x${band_top}+0+0" +repage \
            -colorspace gray -resize 200% "$OUT/$leg.fig.png" 2>/dev/null
        tesseract "$OUT/$leg.fig.png" - --psm 6 2>/dev/null \
            | tr '\n' ' ' | tr -s ' ' | sed 's/^ *//; s/ *$//' \
            > "$OUT/$leg.fig.ocr"
    fi

    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$leg" "$verdict" \
        "$(kv "$KVF" bracket_n)" "$(kv "$KVF" cap_ran)" \
        "$(kv "$KVF" cap_drawn)" "$(kv "$KVF" cap_lines)" \
        "$(kv "$KVF" cap_width_mm)" "$(kv "$KVF" cap_avail_mm)" \
        "${imgw:-0}" "${imgh:-0}" \
        "${ink:-0}" "${inkl:--1}" "${inkr:--1}" \
        "${ocr:-}" >> "$TSV"

    printf '  %-16s %-16s brackets=%-2s drawn=%-2s lines=%-2s ink=%-6s [%s]\n' \
        "$leg" "$verdict" "$(kv "$KVF" bracket_n)" "$(kv "$KVF" cap_drawn)" \
        "$(kv "$KVF" cap_lines)" "${ink:-0}" "${ocr:0:70}"
done
