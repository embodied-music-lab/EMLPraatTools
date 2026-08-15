#!/usr/bin/env bash
# ============================================================================
# harness/graphaxes/break.sh — show every v62 check RED on purpose
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# NOTHING IS VALIDATED UNTIL IT HAS BEEN BROKEN. A check that has only ever
# been green is a check nobody has read: it may be asserting something true of
# every possible build, or matching a comment instead of a call, or reading a
# stale evidence file. The only way to know a check has teeth is to make the
# thing it guards wrong and watch it fail.
#
# THIS IS NOT A HYPOTHETICAL WORRY IN THIS FILE'S OWN HISTORY. v62's static
# check for the form call site passed on its first break attempt, because the
# reader was matching the whole file and the paragraph EXPLAINING the call
# site contains its name. The check now strips Praat comments before matching,
# and the case below proves it.
#
# This script builds a SHADOW TREE in /tmp — plugin/stats symlinked,
# plugin/graphs copied — damages one thing in the copy, re-drives whichever
# harnesses that damage could reach, and runs validate/v62 against it through
# $EML_GRAPHS_SRC. The repository is never modified and never needs reverting.
#
# THREE MODES, and the reason is honesty about cost. A damage to a static
# string cannot change a rendered figure, so re-rendering one would only add
# minutes and a chance of confusing a harness flake with a break. Each case
# declares the widest scope its damage can reach and is re-driven to exactly
# that depth:
#
#   gui     re-drive the Xvfb stereo legs AND the headless axis legs
#   axes    re-drive the axis legs only; reuse the good stereo evidence
#   static  reuse both; the damage is a string the validator reads directly
#
# ONE DAMAGE PER CASE, and each names the check it is meant to kill. A case
# that fails to go red is a FINDING ABOUT THE CHECK, not about the damage: it
# means the check was passing for a reason other than the one it claims.
#
# THE SHADOW COPIES plugin/scripts AS WELL AS plugin/graphs, since 15 Aug
# 2026: ruling 5's repair lives in the graphs library and is REACHED by the
# describe wrapper, so one of v62's checks reads that wrapper and one break
# case damages it. A symlink would have put the damage in the real tree.
#
# Usage:  bash harness/graphaxes/break.sh [case-substring]
# Output: harness/graphaxes/out/BREAKS.tsv   case, mode, went-red, n failed
#         harness/graphaxes/out/break_<case>.v62.log   the red run itself
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUT="$SCRIPT_DIR/out"
BRK="/tmp/eml_v62_break"
FILTER="${1:-}"
mkdir -p "$OUT"
RESULTS="$OUT/BREAKS.tsv"

if [[ -z "$FILTER" ]]; then
    : > "$RESULTS"
    printf 'case\tmode\twent_red\tn_failed\tdamage\n' >> "$RESULTS"
fi

# The good evidence both harnesses produced, which every case starts from.
for f in AXES.tsv STEREO.tsv; do
    [[ -s "$OUT/$f" ]] || { echo "break: FAIL — $OUT/$f missing. Run axes.sh and stereo.sh first."; exit 1; }
done

build_shadow () {
    rm -rf "$BRK"
    mkdir -p "$BRK/plugin" "$BRK/harness/graphaxes/out"
    ln -s "$REPO/plugin/stats"   "$BRK/plugin/stats"
    ln -s "$REPO/plugin/sprites" "$BRK/plugin/sprites"
    cp -r "$REPO/plugin/graphs"  "$BRK/plugin/graphs"
    # plugin/scripts is COPIED rather than symlinked because one check reads
    # it: that the describe wrapper still routes its header repair through
    # @emlCleanConvertedTable. A symlink would put the damage in the real tree.
    cp -r "$REPO/plugin/scripts" "$BRK/plugin/scripts"
    cp "$REPO/harness/graphaxes/axes_drive.praat"   "$BRK/harness/graphaxes/"
    cp "$REPO/harness/graphaxes/stereo_drive.praat" "$BRK/harness/graphaxes/"
    cp "$OUT/AXES.tsv"   "$BRK/harness/graphaxes/out/AXES.tsv"
    cp "$OUT/STEREO.tsv" "$BRK/harness/graphaxes/out/STEREO.tsv"
}

# run_case <name> <gui|axes|static> <damage-command run inside the shadow>
run_case () {
    local name="$1" mode="$2" damage="$3"
    if [[ -n "$FILTER" && "$name" != *"$FILTER"* ]]; then return 0; fi
    build_shadow
    ( cd "$BRK" && eval "$damage" ) || { echo "break: $name — damage failed"; return 1; }

    if [[ "$mode" == "gui" || "$mode" == "axes" ]]; then
        EML_AXES_OUTDIR="$BRK/harness/graphaxes/out" \
        EML_GRAPHS_DRIVE="$BRK/harness/graphaxes/axes_drive.praat" \
            bash "$REPO/harness/graphaxes/axes.sh" \
            > "$OUT/break_$name.axes.log" 2>&1
    fi
    if [[ "$mode" == "gui" ]]; then
        EML_STEREO_OUTDIR="$BRK/harness/graphaxes/out" \
        EML_STEREO_DRIVE="$BRK/harness/graphaxes/stereo_drive.praat" \
            bash "$REPO/harness/graphaxes/stereo.sh" \
            > "$OUT/break_$name.stereo.log" 2>&1
    fi

    local log="$OUT/break_$name.v62.log"
    EML_GRAPHS_SRC="$BRK/plugin/graphs" \
    EML_SCRIPTS_SRC="$BRK/plugin/scripts" \
    EML_AXES_DIR="$BRK/harness/graphaxes/out" \
    EML_STEREO_DIR="$BRK/harness/graphaxes/out" \
        Rscript "$REPO/validate/v62_graphs_axes_channels.R" > "$log" 2>&1

    # `grep -c` EXITS 1 WHEN THE COUNT IS ZERO, so `$(grep -c ... || echo 0)`
    # produces the two-line string "0\n0" on exactly the runs that matter --
    # the ones where a case failed to go red -- and the arithmetic test below
    # then errors out instead of reporting them. Counted with awk, which has
    # no such exit convention.
    local failed red
    failed=$(awk '/^FAIL/ {n++} END {print n+0}' "$log" 2>/dev/null)
    failed=${failed:-0}
    if [[ "$failed" -gt 0 ]]; then red=1; else red=0; fi
    printf '%s\t%s\t%s\t%s\t%s\n' "$name" "$mode" "$red" "$failed" "$damage" \
        >> "$RESULTS"
    printf '%-28s %-6s red=%s  failed=%s\n' "$name" "$mode" "$red" "$failed"
}

S=plugin/graphs
G="$S/eml-graph-procedures.praat"
D="$S/eml-draw-procedures.praat"
A="$S/eml-annotation-procedures.praat"
F="$S/eml-graphs-form.praat"
T="plugin/scripts/eml-describe-table.praat"

# ===========================================================================
# THE EVIDENCE ITSELF. A validator that cannot tell "green" from "no evidence"
# is the worst kind, so the absence of each input is a case.
# ===========================================================================
run_case sources_missing        static "rm -f $S/*.praat"
run_case stereo_evidence_gone   static "rm -f harness/graphaxes/out/STEREO.tsv"
run_case axes_evidence_gone     static "rm -f harness/graphaxes/out/AXES.tsv"
run_case wrong_praat_version    static \
  "sed -i 's/^praat_version\t.*/praat_version\tPraat 6.4.06 (January 2024)/' harness/graphaxes/out/AXES.tsv"

# ===========================================================================
# THE STEREO GATE
# ===========================================================================
run_case gate_form_removed      gui \
  "sed -i 's|^    @emlGraphsChannelGate: objectId, \"waveform\"|    # gate removed|' $F"
run_case gate_form_comment_only gui \
  "sed -i 's|^    @emlGraphsChannelGate: objectId, \"waveform\"|    # @emlGraphsChannelGate: objectId, \"waveform\"|' $F"
run_case gate_pitch_removed     gui \
  "sed -i 's|^            @emlGraphsChannelGate: .sourceId, \"pitch track\"|            # gate removed|' $G"
run_case original_deleted       gui \
  "sed -i 's|^    emlChannelKeepOriginal = 1\$|    emlChannelKeepOriginal = 0|' $G"
run_case core_bypassed          static \
  "sed -i 's|^    @emlApplyChannelChoice: .soundId, channel_handling\$|    .resultId = .soundId|' $G"
run_case choice_labels_changed  gui \
  "sed -i 's|.choice\$ = \"Left channel only\"|.choice\$ = \"Channel A\"|' $G"
run_case keepmode_not_asked     static \
  "sed -i '/^procedure emlGraphsChannelGate:/,/^endproc\$/ s|^    emlChannelKeepOriginal = 1\$|    emlChannelKeepOriginal = 0|' $G"
run_case dialog_option_renamed  static \
  "sed -i '/^procedure emlGraphsChannelGate:/,/^endproc\$/ s|option: \"Right channel only\"|option: \"Channel B\"|' $G"
run_case dialog_suppressed      gui \
  "sed -i 's|^    beginPause: \"Stereo Sound|    if 0 = 1\\n    beginPause: \"Stereo Sound|' $G; sed -i 's|^    .clicked = endPause: \"Quit\", \"Continue\", 2, 0\$|    .clicked = endPause: \"Quit\", \"Continue\", 2, 0\\n    endif\\n    channel_handling = 1|' $G"
run_case channels_swapped       gui \
  "sed -i 's|^            .resultId = Extract one channel: 1\$|            .resultId = Extract one channel: 2|' $G; sed -i 's|^            .resultId = Extract one channel: 2\$|            .resultId = Extract one channel: 1|2' $G"
run_case mix_is_actually_left   gui \
  "sed -i '0,/^            .resultId = Convert to mono\$/s//            .resultId = Extract one channel: 1/' $G"
run_case right_is_actually_left gui \
  "sed -i 's|^            .resultId = Extract one channel: 2\$|            .resultId = Extract one channel: 1|' $G"
run_case conversion_noop        gui \
  "sed -i 's|^            .resultId = Convert to mono\$|            .resultId = Copy: \"same\"|' $G"
run_case ungated_number_faked   static \
  "sed -i 's/^ungated_mean_f0\t.*/ungated_mean_f0\t220.0000/' harness/graphaxes/out/STEREO.tsv"

# ===========================================================================
# THE AXIS
# ===========================================================================
run_case span_floor_removed     axes \
  "sed -i 's|^        .spanFloorSemitones = 0.1\$|        .spanFloorSemitones = 0|' $D"
run_case span_floor_too_wide    axes \
  "sed -i 's|^        .spanFloorSemitones = 0.1\$|        .spanFloorSemitones = 6|' $D"
run_case span_floor_renamed     static \
  "sed -i 's|.spanFloorSemitones|.floorSt|g' $D"
run_case tick_precision_off     axes \
  "sed -i 's|^                if .intDigits + .decimals > 4\$|                if .intDigits + .decimals > 99|' $G"
run_case tick_precision_always  axes \
  "sed -i 's|^        if .decimals > 0\$|        if .decimals > -1|' $G; sed -i 's|^                if .intDigits + .decimals > 4\$|                if .intDigits + .decimals > 0|' $G"
run_case tick_decimals_flat     axes \
  "sed -i 's|^        .decimals = -.stepMag\$|        .decimals = 0|' $G"
run_case tick_proc_renamed      static \
  "sed -i 's|emlTickPrecision|emlTickPrec2|g' $G"
run_case tick_callers_removed   static \
  "sed -i 's|^    @emlTickPrecision: |    # @emlTickPrecision: |' $G"

# ===========================================================================
# THE CLIP AND THE ONE-SIDED RANGE
# ===========================================================================
run_case clip_removed           axes \
  "sed -i 's|^    emlFrameKnown = 1\$|    emlFrameKnown = 0|' $G"
# THE MOST IMPORTANT BREAK IN THIS FILE. The clip must change the PICTURE and
# nothing else. This damage is the plausible mistake a careless fix would make
# -- clamping the data into the frame the user typed instead of declining to
# draw what falls outside it -- and it changes the correlation on the clipped
# draw only. If v62 cannot see that, then this whole change is free to become
# a silent recomputation, which would be far worse than the defect it repairs.
run_case clip_clamps_data       axes \
  "sed -i 's|^        .axisXMin = .xMin\$|        .axisXMin = .xMin\\n        for .ci from 1 to .nValid\\n            if .xData#[.ci] < .xMin\\n                .xData#[.ci] = .xMin\\n            endif\\n        endfor|' $D"
run_case clip_filters_stats     axes \
  "sed -i 's|^        if .xVal <> undefined and .yVal <> undefined\$|        if .xVal <> undefined and .yVal <> undefined and .xVal >= 100 and .xVal <= 300|' $D"
run_case clip_always_on         axes \
  "sed -i 's|^    emlFrameXMin = min (.xMin, .xMax)\$|    emlFrameXMin = min (.xMin, .xMax) + (.xMax - .xMin) * 0.3|' $G"
run_case user_range_widened     axes \
  "sed -i 's|^        .axisXMin = .xMin\$|        .axisXMin = .xMin - 5|' $D"
run_case clip_frame_calls_gone  static \
  "sed -i 's|^    @emlPointInFrame: |    # @emlPointInFrame: |' $G"
run_case disclosure_removed     axes \
  "sed -i 's|^        @emlDisclose: .short\$, .advice\$\$|        # disclosure removed|' $D"
run_case disclosure_wording     static \
  "sed -i 's|a minimum on its own is read as a maximum|see the manual|' $D"

# ===========================================================================
# THE ANNOTATION PANEL
# ===========================================================================
run_case collision_bypassed     axes \
  "sed -i 's|^    if emlCollideN < 1\$|    if emlCollideN < 999999|' $A"
run_case collision_ignores_hits axes \
  "sed -i 's|^        if .hit\[.c\] < .hit\[.best\]\$|        if 0 = 1|' $A"
run_case placebox_renamed       static \
  "sed -i 's|emlPlaceAnnotationBox|emlPlaceBox2|g' $A"
run_case placebox_callers_gone  static \
  "sed -i 's|@emlPlaceAnnotationBox:|@emlPlaceElements:|' $D"
run_case measure_mode_gone      static \
  "sed -i 's|emlAnnotBlockMeasureOnly = 1|emlAnnotBlockMeasureOnly = 3|' $A"
run_case overlap_notice_gone    static \
  "sed -i 's|the annotation panel covers|the panel sits at|' $D"

# ===========================================================================
# THE GLOSSES
# ===========================================================================
run_case mwu_gloss_reverted     static \
  "sed -i 's|emlWizardExplain\$ = \"U: how often.*|emlWizardExplain\$ = \"Sum of ranks: measures how much one group tends to exceed the other\"|' $A"
run_case mwu_gloss_vague        static \
  "sed -i 's|, out of n1 x n2 possible pairs||' $A"
run_case wilcoxon_plus_damaged  static \
  "sed -i 's|Sum of ranks for positive differences|U for positive differences|g' $A"
run_case wilcoxon_minus_damaged static \
  "sed -i 's|Sum of ranks for negative differences|U for negative differences|g' $A"

# ===========================================================================
# THE AXIS NAME AND ITS TICK LABELS — AUTHOR RULING 7
# ===========================================================================
# BOTH DIRECTIONS, and the second is the one worth having. A guard that never
# fires leaves the collision; a guard that always fires moves every figure in
# the plugin, and would pass any check written only against the crowded ones.
run_case axisname_never_shifts  axes \
  "sed -i 's|^        if .needMM > .allowMM\$|        if .needMM > 99999|' $G"
run_case axisname_trigger_wide  axes \
  "sed -i 's|^    .wideChars = 6\$|    .wideChars = 0|' $G"
# THE MOST IMPORTANT BREAK OF RULING 7, and it is the fix's own worst case: a
# shift applied to EVERY figure. It clears the collision on both crowded
# figures and satisfies any check written only against them, while moving the
# axis name on all 39 stress figures. margin_plain is the check that sees it.
run_case axisname_shifts_all    axes \
  "sed -i '/^procedure emlDrawAxisNameLeft:/,/^endproc\$/ s|^    .shiftInch = 0\$|    .shiftInch = 0.1|' $G"
run_case axisname_bare_textleft axes \
  "sed -i 's|^        @emlDrawAxisNameLeft: .yLabel\$, .yWideLabelMM,\$|        Text left: \"yes\", .yLabel\$\n        # was:|' $G"
run_case axisname_allowance_big axes \
  "sed -i 's|^        .allowMM = 0.982 \* emlSetAdaptiveTheme.bodySize\$|        .allowMM = 9.82 * emlSetAdaptiveTheme.bodySize|' $G"
run_case axisname_no_clearance  axes \
  "sed -i 's|^        .needMM = .wideLabelMM + .clearMM\$|        .needMM = .wideLabelMM|' $G"
# THE CLAMP REMOVED. Without it the small-panel figure's axis name is pushed
# past the panel's own left edge, and Praat's save -- which covers the selected
# outer viewport and nothing else -- returns it sliced. Caught by the first-ink
# column, not by the gap: the gap gets BIGGER as the name goes off the page.
run_case clamp_removed          axes \
  "sed -i 's|^            if .shiftInch > .roomInch\$|            if 0 = 1|' $G"
run_case marks_measure_removed  axes \
  "sed -i 's|^                @emlTickLabelWidth: .yPos, .tickExplicit, .tickDecimals\$|                # measurement removed|' $G"
run_case maxwide_seed_removed   axes \
  "sed -i 's|^    .maxWideLabelMM = 0\$|    # seed removed|' $G"
# THE PREDICTOR'S WINDOW. Modelling the exponent forms is the mistake that
# looks like an improvement: it makes the guard "more complete" and moves
# violin_hugevalues, a figure that is correct today.
run_case ticklabel_models_expo  axes \
  "sed -i 's|^        elsif .mag >= 0.001 and .mag < 10000\$|        elsif .mag >= 0|' $G"
run_case ticklabel_explicit_off axes \
  "sed -i 's|^        .text\$ = fixed\$ (.value, .decimals)\$|        .text\$ = \"\"|' $G"

# ===========================================================================
# Column_k HOLDS SOURCE COLUMN k — AUTHOR RULING 5
# ===========================================================================
run_case colnum_by_position     axes \
  "sed -i 's|^    for .iCol from .insertedCols + 1 to .nCols\$|    for .iCol from 1 to .nCols|' $G; sed -i 's|^            ... \"Column_\" + string\$ (.iCol - .insertedCols)\$|            ... \"Column_\" + string\$ (.iCol)|' $G"
run_case colnum_offset_zero     axes \
  "sed -i 's|^    .insertedCols = 1\$|    .insertedCols = 0|' $G"
run_case rowlabel_bare_integers axes \
  "sed -i 's|^            Set string value: .iRow, .rowColName\$, \"r\" + string\$ (.iRow)\$|            Set string value: .iRow, .rowColName\$, string\$ (.iRow)|' $G"
run_case describe_bypasses_shared static \
  "sed -i 's|^        @emlCleanConvertedTable: .tableId\$|        # shared repair bypassed|' $T"
# THE SECOND DOOR INVENTING ITS OWN NAME. One repair, two doors, is the whole
# reason the live evidence at door 3 is allowed to stand for door 2 as well --
# so a rename appearing in the wrapper is a change to that argument and not a
# detail.
run_case describe_names_its_own   static \
  "sed -i 's|^        .nDefaulted = 0\$|        .nDefaulted = 0\n        Rename column (by number): 2, \"Column_\" + string\\$ (2)|' $T"

# ===========================================================================
# ONE PRESS, ONE DERIVED SOUND — AUTHOR RULING 8b
# ===========================================================================
# THE DAMAGE LEAVES THE GATE RUNNING ON PURPOSE. Deleting the call alone
# strands the line that reads its result and the whole leg dies at "Unknown
# variable" -- which is red, but red for want of evidence rather than because
# the accumulation was seen. Neutralising the read as well makes the shadow
# behave exactly as the plugin did before this ruling: three presses, three
# Sounds, one name.
run_case stale_drop_removed     gui \
  "sed -i 's|^    @emlDropStaleChannelSounds: .name\$\$|    # drop removed|' $G; sed -i 's|^    .nStale = emlDropStaleChannelSounds.nDropped\$|    .nStale = 0|' $G"
run_case derived_not_renamed    gui \
  "sed -i 's|^        Rename: \"eml_\" + selected\$ (\"Sound\")\$|        # rename removed|' $G"
run_case drop_matches_user_name static \
  "sed -i 's|\\.cand\\$ = \"eml_\" + .sourceName\\$|.cand\\$ = .sourceName\\$|g' $G"

# ===========================================================================
# THE ONE-BIN SPECTRUM — RULING 8c's PROBE, WHICH MUST STAY A PROBE
# ===========================================================================
# Nothing here asserts the defect is fixed; what is asserted is that the
# measurement still measures. Break the draw and the two-bin control stops
# drawing, and the note about the empty frame would be about the draw path
# instead of about the bin count.
run_case spectrum_draw_removed  axes \
  "sed -i 's|^    Draw: .freqMin, .freqMax, .powerMin, .powerMax, \"no\"\$|    # draw removed|' $D"

echo
echo "break: results in $RESULTS"
awk -F'\t' 'NR>1 && $3 != 1 {print "  NOT RED: " $1}' "$RESULTS"
exit 0
