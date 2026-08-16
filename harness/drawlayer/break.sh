#!/usr/bin/env bash
# ============================================================================
# harness/drawlayer/break.sh — nothing is validated until it has been broken
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Every break is a COPY of the repository with one deliberate defect, driven
# through $EML_DL_SRC and read by validate/v66 through $EML_DRAW_SRC,
# $EML_DRAWSCRIPTS_SRC and $EML_DRAWLAYER_DIR. The working tree is never
# touched and never has to be, which is the point: a break test that edits the
# tree and puts it back is one interrupted run away from committing a defect.
#
# WHAT EACH BREAK IS FOR. They fall into four groups, and the grouping is the
# argument:
#
#   THE DEFECT ITSELF -- each of the four repairs reverted to HEAD, separately.
#   The split matters: it shows that no check is passing because some other
#   file happens to be right.
#
#   THE MECHANISM RATHER THAN THE TEXT -- a repair that has the right SHAPE and
#   does nothing. The axis-name call made with a constant 0 width; @eml_fixed
#   reduced to a pass-through; a single matrix cell reverted while its
#   neighbours stay fixed.
#
#   THE FIX-SHAPED FIX -- @eml_fixed made to return a zero of the right width
#   for every input, which satisfies every width assertion in v66 §5 and is
#   catastrophically wrong; and the CSV writers rounded to four decimals to
#   "match" the report, which satisfies §5 and §6 and ruins the export.
#
#   THE OVER-SWEEP -- the eighth `Text left`, which is a panel label and not an
#   axis name, routed through the axis-name procedure; and a figure-text
#   fixed$ routed through the Info formatter. Both are repairs that move
#   figures nobody asked to move.
#
#   Run:  bash harness/drawlayer/break.sh [name-substring]
#   Out:  harness/drawlayer/out/BREAKS.tsv    break, red-count, first failure
#         harness/drawlayer/out/break_<name>.v66.log
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ============================================================================
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$HERE/.." && pwd)/_env.sh" || exit 1
ROOT="$EML_ROOT"
OUT="$HERE/out"
WORK="${TMPDIR:-/tmp}/eml-drawlayer-breaks"
FILTER="${1:-}"

mkdir -p "$OUT" "$WORK"
TSV="$OUT/BREAKS.tsv"
[ -n "$FILTER" ] || : > "$TSV"

DRAW=plugin/graphs/eml-draw-procedures.praat
ANNOT=plugin/graphs/eml-annotation-procedures.praat
NORM=plugin/scripts/eml-check-normality.praat
OUTP=plugin/stats/eml-output.praat
# The recorder writes the editable header block ruling 10(b) put the axis in.
# It is not this change's file; a break of somebody else's file belongs in a
# SHADOW, which is what every break below builds.
REC=plugin/stats/eml-record.praat
DRIVE=harness/drawlayer/drawlayer_drive.praat

# shadow <name> — a clean copy of the tree at $WORK/<name>, minus the heavy
# output folders. .git is excluded: a break tree is not a repository.
shadow () {
    local n=$1
    rm -rf "${WORK:?}/$n"
    mkdir -p "$WORK/$n"
    tar -c --exclude=.git --exclude=harness/stress_out \
        --exclude=harness/drawlayer/out --exclude=evidence \
        -C "$ROOT" . | tar -x -C "$WORK/$n"
    mkdir -p "$WORK/$n/harness/drawlayer/out"
}

# revert <tree> <path> <ref> — put one file back to <ref> inside a shadow tree.
#
# THE REF IS NAMED AND IT IS NEVER "HEAD". This helper took no ref until 16
# August 2026 and always reverted to HEAD, which was right on the day it was
# written and stopped being right the moment the repairs were committed: from
# 0e0c0fa onwards, "revert to HEAD" put the FIXED file back and the break went
# silently green. break_head_info_fixed ran red=0 -- NOTHING WENT RED -- and
# had been doing so since the commit that made this rig's whole subject true.
#
# That is the moving-reference trap in its purest form: a break test anchored
# on a name that follows the repair can only stop working, and it stops
# working by passing. So every revert now names the commit BEFORE the repair
# it is undoing, which is a fact about history and cannot drift.
revert () {
    local ref="${3:?revert needs an explicit commit; HEAD moves and the break goes vacuous}"
    ( cd "$ROOT" && git show "$ref:$2" ) > "$WORK/$1/$2"
    # A revert that changed nothing is not a break. Say so loudly here rather
    # than letting the validator report a clean run.
    if ( cd "$ROOT" && git show "$ref:$2" ) | cmp -s - "$ROOT/$2"; then
        printf '  %-26s !! REVERT IS A NO-OP: %s at %s equals the working tree\n' \
            "$1" "$2" "$ref"
    fi
}

# run_break <name> — drive the shadow and score validate/v66 against it.
run_break () {
    # TWO STATEMENTS, NOT ONE. `local n=$1 o="$WORK/$n/..."` expands every
    # word before it assigns any of them, so $n is still unset when $o is
    # built -- and under `set -u` that is an abort before the first break runs.
    local n=$1
    local o="$WORK/$n/harness/drawlayer/out"
    EML_DL_SRC="$WORK/$n" EML_DL_OUTDIR="$o" \
        timeout 900 bash "$WORK/$n/harness/drawlayer/drawlayer.sh" \
        > "$o/drive.log" 2>&1
    # The GUI capture is carried across unless the break is about it: the
    # per-group leg needs an X server and re-driving it for every break would
    # cost more than it proves. A break that IS about that branch replaces the
    # file; see break_head_normality.
    [ -f "$OUT/info_pergroup.txt" ] && cp "$OUT/info_pergroup.txt" "$o/" 2>/dev/null
    EML_DRAW_SRC="$WORK/$n/plugin/graphs" \
    EML_DRAWSCRIPTS_SRC="$WORK/$n/plugin/scripts" \
    EML_DRAWLAYER_DIR="$o" \
        Rscript "$ROOT/validate/v66_draw_layer.R" \
        > "$OUT/break_$n.v66.log" 2>&1
    local red first
    red=$(grep -c '^FAIL' "$OUT/break_$n.v66.log")
    first=$(grep -m1 '^FAIL' "$OUT/break_$n.v66.log" \
            | sed 's/^FAIL  *v66  *//; s/  computed.*//' | cut -c1-90)
    printf '%s\t%s\t%s\n' "$n" "$red" "${first:-<none>}" >> "$TSV"
    printf '  %-26s red=%-4s %s\n' "$n" "$red" "${first:-NOTHING WENT RED}"
}

want () {
    local n="$1"
    [ -z "$FILTER" ] && return 0
    case "$n" in *"$FILTER"*) return 0 ;; *) return 1 ;; esac
}

# ---------------------------------------------------------------------------
# 1. THE DEFECT ITSELF, one repair at a time
# ---------------------------------------------------------------------------
if want head_violin_recorder; then
    shadow head_violin_recorder
    python3 - "$WORK/head_violin_recorder/$DRAW" <<'PY'
import sys, re
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
s = s.replace('''    ... + .valueCol$ + """, " + string$ (.vMin) + ", "
    ... + string$ (.vMax)''','''    ... + .valueCol$ + """, " + fixed$ (emlDrawViolinPlot.yMin, 6) + ", "
    ... + fixed$ (emlDrawViolinPlot.yMax, 6)''')
open(p, 'w', encoding='utf-8').write(s)
PY
    run_break head_violin_recorder
fi

if want head_seven_sites; then
    shadow head_seven_sites
    python3 - "$WORK/head_seven_sites/$DRAW" <<'PY'
import sys, re
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
s = re.sub(r'@emlDrawAxisNameLeft: \.yLabel\$,\s*\n\s*\.\.\.[^\n]*\n',
           'Text left: "yes", .yLabel$\n', s)
s = re.sub(r'@emlDrawAxisNameLeft: \.yLabel\$, emlDrawAlignedMarksLeft\.maxWideLabelMM,\s*\n\s*\.\.\.[^\n]*\n',
           'Text left: "yes", .yLabel$\n', s)
open(p, 'w', encoding='utf-8').write(s)
PY
    run_break head_seven_sites
fi

if want head_info_fixed; then
    shadow head_info_fixed
    # 0e0c0fa is the commit that routed 69 raw fixed$ calls through
    # @eml_fixed in this file; its parent is the last tree that still had the
    # defect. Pinned by sha, not by HEAD -- see revert().
    revert head_info_fixed "$ANNOT" 0e0c0fa~1
    run_break head_info_fixed
fi

if want head_posthoc_label; then
    shadow head_posthoc_label
    python3 - "$WORK/head_posthoc_label/$ANNOT" <<'PY'
import sys
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
s = s.replace('annotMatrixPosthoc$ = "Tukey HSD (already family-wise)"',
              'annotMatrixPosthoc$ = "Tukey HSD"')
open(p, 'w', encoding='utf-8').write(s)
PY
    run_break head_posthoc_label
fi

# ---------------------------------------------------------------------------
# 2. THE MECHANISM RATHER THAN THE TEXT
# ---------------------------------------------------------------------------
# A partial repair. Six of the seven sites left alone and the violin reverted:
# the call count still looks healthy to a careless check, and one procedure
# still collides.
if want six_of_seven; then
    shadow six_of_seven
    python3 - "$WORK/six_of_seven/$DRAW" <<'PY'
import sys, re
p = sys.argv[1]; lines = open(p, encoding='utf-8').read().split('\n')
hits = [i for i, l in enumerate(lines)
        if l.strip().startswith('@emlDrawAxisNameLeft: .yLabel$, emlDrawAlignedMarksLeft')]
i = hits[2]                      # the violin's own site, third of the seven
ind = lines[i][:len(lines[i]) - len(lines[i].lstrip())]
lines[i:i+2] = [ind + 'Text left: "yes", .yLabel$']
open(p, 'w', encoding='utf-8').write('\n'.join(lines))
PY
    run_break six_of_seven
fi

# The call is there and does nothing: a constant 0 in place of the measured
# label width. Every static check that counts call sites passes.
if want axis_name_zero_width; then
    shadow axis_name_zero_width
    python3 - "$WORK/axis_name_zero_width/$DRAW" <<'PY'
import sys
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
s = s.replace('@emlDrawAxisNameLeft: .yLabel$, emlDrawAlignedMarksLeft.maxWideLabelMM,',
              '@emlDrawAxisNameLeft: .yLabel$, 0,')
open(p, 'w', encoding='utf-8').write(s)
PY
    run_break axis_name_zero_width
fi

# The sentinel is passed through and the resolved numbers are DROPPED from the
# note. The replay is correct and the record no longer says what the axis was.
if want recorder_drops_note; then
    shadow recorder_drops_note
    python3 - "$WORK/recorder_drops_note/$DRAW" <<'PY'
import sys
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
s = s.replace('''    @emlRecordResult: "Axis resolved to "
    ... + fixed$ (emlDrawViolinPlot.yMin, 4) + " .. "
    ... + fixed$ (emlDrawViolinPlot.yMax, 4) + " over "
    ... + string$ (.nGroups) + " groups."''','''    @emlRecordResult: "Axis over "
    ... + string$ (.nGroups) + " groups."''')
open(p, 'w', encoding='utf-8').write(s)
PY
    run_break recorder_drops_note
fi

# One cell of one matrix reverted, with every other call site left repaired.
# Per-cell resolution: the failure has to say WHICH table it is in.
if want one_cell_reverted; then
    shadow one_cell_reverted
    python3 - "$WORK/one_cell_reverted/$ANNOT" <<'PY'
import sys
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
s = s.replace('''                @eml_fixed: .dVal, 3
                .cellText$ = eml_fixed.result$''','''                .cellText$ = fixed$ (.dVal, 3)''')
open(p, 'w', encoding='utf-8').write(s)
PY
    run_break one_cell_reverted
fi

# @eml_fixed reduced to a pass-through to fixed$, with every call site left in
# place. This is the defect back with the repair's shape intact.
if want formatter_passthrough; then
    shadow formatter_passthrough
    python3 - "$WORK/formatter_passthrough/$OUTP" <<'PY'
import sys, re
p = sys.argv[1]; lines = open(p, encoding='utf-8').read().split('\n')
i = next(k for k, l in enumerate(lines) if l.startswith('procedure eml_fixed:'))
j = next(k for k in range(i, len(lines)) if lines[k].startswith('endproc'))
lines[i:j+1] = ['procedure eml_fixed: .value, .decimals',
                '    .result$ = fixed$ (.value, .decimals)',
                'endproc']
open(p, 'w', encoding='utf-8').write('\n'.join(lines))
PY
    run_break formatter_passthrough
fi

# ---------------------------------------------------------------------------
# 3. THE FIX-SHAPED FIX
# ---------------------------------------------------------------------------
# A formatter that returns a zero of the right width for EVERYTHING passes
# every width assertion in v66 §5 and is catastrophically wrong. If this one
# does not go red in §6, §6 is decoration.
if want formatter_clamps_zero; then
    shadow formatter_clamps_zero
    python3 - "$WORK/formatter_clamps_zero/$OUTP" <<'PY'
import sys
p = sys.argv[1]; lines = open(p, encoding='utf-8').read().split('\n')
i = next(k for k, l in enumerate(lines) if l.startswith('procedure eml_fixed:'))
j = next(k for k in range(i, len(lines)) if lines[k].startswith('endproc'))
lines[i:j+1] = ['procedure eml_fixed: .value, .decimals',
                '    .result$ = "0"',
                '    if .decimals > 0',
                '        .result$ = .result$ + "."',
                '        for .i from 1 to .decimals',
                '            .result$ = .result$ + "0"',
                '        endfor',
                '    endif',
                'endproc']
open(p, 'w', encoding='utf-8').write('\n'.join(lines))
PY
    run_break formatter_clamps_zero
fi

# The other one: the EXPORT rounded to four decimals to "match" the report.
# Nothing in the report changes, so §5 and §6 stay green and §7 must catch it.
if want csv_rounds_data; then
    shadow csv_rounds_data
    python3 - "$WORK/csv_rounds_data/$OUTP" <<'PY'
import sys
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
s = s.replace('''procedure emlCSVAdd: .analysis$, .term$, .field$, .value
    if .value <> undefined
        @eml_csvAppend: .analysis$, .term$, .field$, string$ (.value)''','''procedure emlCSVAdd: .analysis$, .term$, .field$, .value
    if .value <> undefined
        @eml_csvAppend: .analysis$, .term$, .field$, fixed$ (.value, 4)''')
open(p, 'w', encoding='utf-8').write(s)
PY
    run_break csv_rounds_data
fi

# ---------------------------------------------------------------------------
# 4. THE OVER-SWEEP
# ---------------------------------------------------------------------------
# The eighth `Text left` is a PANEL LABEL, not an axis name. Routing it through
# the axis-name procedure moves a label that has no tick numbers to collide
# with, and is the shape a "finish the job" sweep takes.
if want panel_label_swept; then
    shadow panel_label_swept
    python3 - "$WORK/panel_label_swept/$DRAW" <<'PY'
import sys
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
s = s.replace('Text left: "yes", .panelLabel$',
              '@emlDrawAxisNameLeft: .panelLabel$, emlDrawAlignedMarksLeft.maxWideLabelMM, .xMin, .xMax, 0, .sharedYMax')
open(p, 'w', encoding='utf-8').write(s)
PY
    run_break panel_label_swept
fi

# A figure-text fixed$ routed through the Info formatter: the matrix cell that
# @emlMeasureMatrixLayout measures and @emlDrawMatrixPanel then draws.
if want figure_text_swept; then
    shadow figure_text_swept
    python3 - "$WORK/figure_text_swept/$ANNOT" <<'PY'
import sys
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
s = s.replace('''                        .dText$ = fixed$ (.absD, 2)''','''                        @eml_fixed: .absD, 2
                        .dText$ = eml_fixed.result$''')
open(p, 'w', encoding='utf-8').write(s)
PY
    run_break figure_text_swept
fi

# One claim covering both arms, which is what ruling 1b rules out by name.
if want posthoc_both_arms; then
    shadow posthoc_both_arms
    python3 - "$WORK/posthoc_both_arms/$ANNOT" <<'PY'
import sys
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
s = s.replace('''                        annotMatrixPosthoc$ = "Dunn's test ("
                        ... + .correction$ + ")"''','''                        annotMatrixPosthoc$ = "Dunn's test (already family-wise)"''')
open(p, 'w', encoding='utf-8').write(s)
PY
    run_break posthoc_both_arms
fi

# A disclosure that is true and too wide for the canvas is not a disclosure.
if want subtitle_overflows; then
    shadow subtitle_overflows
    python3 - "$WORK/subtitle_overflows/$ANNOT" <<'PY'
import sys
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
s = s.replace('annotMatrixPosthoc$ = "Tukey HSD (already family-wise)"',
              'annotMatrixPosthoc$ = "Tukey HSD (already family-wise over the whole set of pairwise comparisons, from the studentized range distribution, so no further adjustment was applied)"')
open(p, 'w', encoding='utf-8').write(s)
PY
    run_break subtitle_overflows
fi

# THE PROBE ITSELF. Ruling 8c's facts are only worth printing if the fixture
# really is one bin, so the fixture claim is broken on purpose.
if want onebin_probe_wrong; then
    shadow onebin_probe_wrong
    python3 - "$WORK/onebin_probe_wrong/harness/drawlayer/drawlayer_drive.praat" <<'PY'
import sys
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
s = s.replace('        lo = 999.90\n        hi = 1000.10', '        lo = 999.40\n        hi = 1000.90')
open(p, 'w', encoding='utf-8').write(s)
PY
    run_break onebin_probe_wrong
fi

# The mirror of the repair: the sentinel HARDCODED, so a typed axis range is
# thrown away. Every check on the auto arm still passes.
if want recorder_hardcodes_auto; then
    shadow recorder_hardcodes_auto
    python3 - "$WORK/recorder_hardcodes_auto/$DRAW" <<'PY2'
import sys
p = sys.argv[1]
s = open(p, encoding='utf-8').read()
old = ('    ... + .valueCol$ + """, " + string$ (.vMin) + ", "\n'
       '    ... + string$ (.vMax)')
new = '    ... + .valueCol$ + """, 0, 0"'
assert old in s
open(p, 'w', encoding='utf-8').write(s.replace(old, new))
PY2
    run_break recorder_hardcodes_auto
fi

# THE SHIFT UNCLAMPED AND TEN TIMES TOO BIG, which is how "no collision" gets
# solved by moving the axis name off the figure. Praat saves the selected outer
# viewport and nothing outside it, so the name comes back sliced -- and the
# slice is ink in column 0. The broken file is eml-graph-procedures.praat,
# which this change does not own; a SHADOW is where a break of somebody else's
# file belongs.
if want shift_off_the_page; then
    shadow shift_off_the_page
    python3 - "$WORK/shift_off_the_page/plugin/graphs/eml-graph-procedures.praat" <<'PY2'
import sys
p = sys.argv[1]
s = open(p, encoding='utf-8').read()
old = ('            .shiftInch = (.needMM - .allowMM) / 25.4\n'
       '            if .shiftInch > .roomInch\n'
       '                .shiftInch = .roomInch\n'
       '                .clamped = 1\n'
       '            endif')
new = '            .shiftInch = (.needMM - .allowMM) / 25.4 * 10'
assert old in s
open(p, 'w', encoding='utf-8').write(s.replace(old, new))
PY2
    run_break shift_off_the_page
fi

# ---------------------------------------------------------------------------
# 5. THE ONE BREAK THAT NEEDS A DISPLAY
# ---------------------------------------------------------------------------
# The per-group branch of the normality wrapper reverted to HEAD, and driven
# through the GUI rig the same way the green run is. It is separate from the
# rest because it costs an X server and about a minute: every other break
# inherits the green capture, which is honest only because THIS one proves the
# section can go red at all.
if want head_normality; then
    shadow head_normality
    # dfdb72f is the commit that swept the wrapper's per-group branch; its
    # parent is the last tree that still printed raw doubles there.
    revert head_normality "$NORM" dfdb72f~1
    o="$WORK/head_normality/harness/drawlayer/out"
    EML_DL_SRC="$WORK/head_normality" EML_DL_OUTDIR="$o" \
        timeout 900 bash "$WORK/head_normality/harness/drawlayer/drawlayer.sh" \
        > "$o/drive.log" 2>&1
    # The shadow's own pergroup_gui.sh, so REPO -- and therefore PLUGIN_SRC and
    # the wrapper runScript: reaches -- is the broken tree.
    EML_DL_OUTDIR="$o" I=7 \
        timeout 600 bash "$WORK/head_normality/harness/drawlayer/pergroup_gui.sh" \
        > "$o/pergroup.log" 2>&1
    EML_DRAW_SRC="$WORK/head_normality/plugin/graphs" \
    EML_DRAWSCRIPTS_SRC="$WORK/head_normality/plugin/scripts" \
    EML_DRAWLAYER_DIR="$o" \
        Rscript "$ROOT/validate/v66_draw_layer.R" \
        > "$OUT/break_head_normality.v66.log" 2>&1
    red=$(grep -c '^FAIL' "$OUT/break_head_normality.v66.log")
    first=$(grep -m1 '^FAIL' "$OUT/break_head_normality.v66.log" \
            | sed 's/^FAIL  *v66  *//; s/  computed.*//' | cut -c1-90)
    printf '%s\t%s\t%s\n' head_normality "$red" "${first:-<none>}" >> "$TSV"
    printf '  %-26s red=%-4s %s\n' head_normality "$red" "${first:-NOTHING WENT RED}"
fi


# ---------------------------------------------------------------------------
# 6. RULING 10(b) — THE AXIS THAT NOW LIVES IN THE HEADER BLOCK
# ---------------------------------------------------------------------------
# §2 of validate/v66 used to assert the LITERAL in the recorded call: "0, 0" on
# the auto arm and "150, 400" on the explicit one. Ruling 10(b) moved the
# number into the editable block at the top of the emitted script and left the
# call REFERENCING it, so both assertions were superseded and were replaced by
# a pair that follows the value through: the call must read the variables, and
# the block must hold the number. Three breaks, one for each way that pair can
# be defeated, and the first of them is the reason it is a pair at all.

# THE COMMENT SAYS "AUTO", THE NUMBER SAYS 160. The block is seeded with the
# RESOLUTION instead of the request, and the prose beside it -- "AUTO (both 0 =
# computed from the data)" -- is left exactly as it was. A check that read the
# gloss, or a harness that took the value with a greedy `sed 's/.*= //'` and
# landed in the sentence, stays green through this. It is the comment trap in
# its live form.
if want axis_block_holds_resolution; then
    shadow axis_block_holds_resolution
    python3 - "$WORK/axis_block_holds_resolution/$REC" <<'PY2'
import sys
p = sys.argv[1]
s = open(p, encoding='utf-8').read()
old = ('            ... + .axMinLit$[.k] + "   ; " + emlRecordAxisGloss.gloss$\n'
       '            ... + " -- AUTO (both 0 = computed from the data) -- "')
new = ('            ... + .resMin$ + "   ; " + emlRecordAxisGloss.gloss$\n'
       '            ... + " -- AUTO (both 0 = computed from the data) -- "')
assert old in s
s = s.replace(old, new)
old2 = ('                ... + .axMaxLit$[.k] + "   ; on the recorded data it resolved"')
new2 = ('                ... + .resMax$ + "   ; on the recorded data it resolved"')
assert old2 in s
open(p, 'w', encoding='utf-8').write(s.replace(old2, new2))
PY2
    run_break axis_block_holds_resolution
fi

# THE OTHER HALF. The block is written correctly and the STEP ignores it: the
# lifting that rewrites the call's axis slots into the two variable names is
# removed, so the call carries its own literal again exactly as it did before
# ruling 10(b). Every value check on the block stays green; the reference
# checks are the only thing standing between this and a header block that is
# decoration.
if want axis_step_ignores_block; then
    shadow axis_step_ignores_block
    python3 - "$WORK/axis_step_ignores_block/$REC" <<'PY2'
import sys
p = sys.argv[1]
s = open(p, encoding='utf-8').read()
old = ('                                .newArg$[.aMinPos] = .aMinLead$\n'
       '                                ... + .axMinName$[.aSlot]\n'
       '                                .newArg$[.aMaxPos] = .aMaxLead$\n'
       '                                ... + .axMaxName$[.aSlot]\n')
assert old in s
open(p, 'w', encoding='utf-8').write(s.replace(old, ''))
PY2
    run_break axis_step_ignores_block
fi

# THE FIX-SHAPED FIX ON THIS SIDE. Every axis declared as a zero -- the exact
# shape @eml_fixed's clamp takes in §3, moved from a WIDTH to a VALUE. It has
# the right variable, in the right block, referenced by the right step, and it
# throws away every range a user ever typed. The auto arm cannot see it,
# because on the auto arm zero is the right answer; only a check on an arm
# whose value is NOT zero can tell the two apart, which is what the explicit
# arm is for.
if want axis_block_clamped_zero; then
    shadow axis_block_clamped_zero
    python3 - "$WORK/axis_block_clamped_zero/$REC" <<'PY2'
import sys
p = sys.argv[1]
s = open(p, encoding='utf-8').read()
old = ('                                .aMinOut$ = .aMinLit$\n'
       '                                .aMaxOut$ = .aMaxLit$\n'
       '                                if .aAuto = 1\n'
       '                                    .aMinOut$ = "0.0"\n'
       '                                    .aMaxOut$ = "0.0"\n'
       '                                endif\n')
new = ('                                .aMinOut$ = "0.0"\n'
       '                                .aMaxOut$ = "0.0"\n')
assert old in s
open(p, 'w', encoding='utf-8').write(s.replace(old, new))
PY2
    run_break axis_block_clamped_zero
fi

# ---------------------------------------------------------------------------
# 7. RULING 8c AT THE SECOND SITE — THE ONE-BIN LTAS CURVE
# ---------------------------------------------------------------------------
# Five breaks, and between them they cover the defect, the fix that has the
# right shape and the wrong value, the remedy that was ruled out, the repair
# that reaches too far, and the fixture the whole section rests on.

# THE DEFECT ITSELF, put back: the bare `Draw: ... "Curve"` with no bin count in
# front of it. This is the figure the finding was made on -- 46,360 bytes of
# fully furnished frame with zero ink in it.
if want head_ltas_curve; then
    shadow head_ltas_curve
    python3 - "$WORK/head_ltas_curve/$DRAW" <<'PY2'
import sys
p = sys.argv[1]
lines = open(p, encoding='utf-8').read().split('\n')
i = lines.index('        .curveNBins = Get number of bins')
j = next(k for k in range(i, len(lines)) if lines[k] == '    endif')
lines[i:j] = ['        Draw: .freqMin, .freqMax, .powerMin, .powerMax, "no", "Curve"']
open(p, 'w', encoding='utf-8').write('\n'.join(lines))
PY2
    run_break head_ltas_curve
fi

# THE FIX-SHAPED FIX. The stem is drawn, in the right branch, by the same
# statement, from the frame floor -- to the TOP OF THE PANEL instead of to the
# bin's value. The source still reads `Draw line: .curveFreq, .powerMin,
# .curveFreq, .curveVal`, so every static check passes; the figure has more ink
# than the correct one, so every ink count passes. Only the pixel row can tell,
# and if this one does not go red the height measurement is decoration.
if want ltas_stem_to_the_top; then
    shadow ltas_stem_to_the_top
    python3 - "$WORK/ltas_stem_to_the_top/$DRAW" <<'PY2'
import sys
p = sys.argv[1]
s = open(p, encoding='utf-8').read()
old = ('                if .curveVal > .powerMax\n'
       '                    .curveVal = .powerMax\n'
       '                endif\n')
new = ('                .curveVal = .powerMax\n'
       '                if .curveVal > .powerMax\n'
       '                    .curveVal = .powerMax\n'
       '                endif\n')
assert old in s
open(p, 'w', encoding='utf-8').write(s.replace(old, new, 1))
PY2
    run_break ltas_stem_to_the_top
fi

# THE REMEDY THAT WAS RULED OUT. The one-bin Curve falls back to Praat's own
# "Bars" style. It draws -- more ink than the stem, in fact -- and it hands the
# Bars layer to a user who switched Bars off and draws the bin twice for a user
# who switched both on. The static check that exactly one `Draw:` in this
# procedure may name "Bars" is what stands in its way.
if want ltas_curve_becomes_bars; then
    shadow ltas_curve_becomes_bars
    python3 - "$WORK/ltas_curve_becomes_bars/$DRAW" <<'PY2'
import sys
p = sys.argv[1]
s = open(p, encoding='utf-8').read()
old = '                    Draw line: .curveFreq, .powerMin, .curveFreq, .curveVal'
new = '                    Draw: .freqMin, .freqMax, .powerMin, .powerMax, "no", "Bars"'
assert old in s
open(p, 'w', encoding='utf-8').write(s.replace(old, new, 1))
PY2
    run_break ltas_curve_becomes_bars
fi

# THE OVER-SWEEP. The stem branch widened to take the two-bin case as well,
# which is the shape "make the degenerate path the normal path" takes. Every
# one-bin measurement stays green and a figure nobody asked to move has moved
# -- and moved figures are what the byte-identical stress set exists to catch.
if want ltas_stem_takes_two; then
    shadow ltas_stem_takes_two
    python3 - "$WORK/ltas_stem_takes_two/$DRAW" <<'PY2'
import sys
p = sys.argv[1]
s = open(p, encoding='utf-8').read()
old = ('        if .curveBins >= 2\n')
new = ('        if .curveBins >= 3\n')
assert old in s
open(p, 'w', encoding='utf-8').write(s.replace(old, new, 1))
PY2
    run_break ltas_stem_takes_two
fi

# THE PROBE ITSELF, the way break_onebin_probe_wrong does it for the spectrum.
# Everything in §8b rests on the claim that the window holds ONE bin; widen it
# and the whole section would be measuring the ordinary path and calling it
# green.
if want ltas_probe_wrong; then
    shadow ltas_probe_wrong
    python3 - "$WORK/ltas_probe_wrong/$DRIVE" <<'PY2'
import sys
p = sys.argv[1]
s = open(p, encoding='utf-8').read()
old = '    else\n        hi = 1100\n    endif\n'
new = '    else\n        hi = 1200\n    endif\n'
assert old in s
open(p, 'w', encoding='utf-8').write(s.replace(old, new, 1))
PY2
    run_break ltas_probe_wrong
fi

echo "breaks: wrote $TSV"
exit 0
