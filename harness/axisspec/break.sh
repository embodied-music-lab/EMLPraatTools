#!/usr/bin/env bash
# ============================================================================
# harness/axisspec/break.sh — nothing is validated until it has been broken
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Every break is a COPY of the repository with one deliberate defect, driven
# through $EML_AS_SRC and read by validate/v67 through $EML_AXIS_DRAW_SRC,
# $EML_AXIS_REC_SRC and $EML_AXISSPEC_DIR. The working tree is never touched
# and never has to be, which is the point: a break test that edits the tree
# and puts it back is one interrupted run away from committing a defect.
#
# WHAT EACH BREAK IS FOR. They fall into five groups, and the grouping is the
# argument:
#
#   THE DEFECT ITSELF — each of the two repairs reverted to HEAD, separately,
#   so that neither can be passing because the other file happens to be right.
#
#   THE MECHANISM RATHER THAN THE TEXT — a repair with the right SHAPE that
#   does nothing. The stem branch left intact, every word of its prose left in
#   place, and one comparison changed so it can never run. The recorder's
#   request call left in place with its answer discarded.
#
#   THE FIX-SHAPED FIX — a stem of exactly the right shape at the wrong
#   height, because the obvious dB formula is not the one Praat draws; and a
#   stem drawn to the full height of the frame, which puts ink inside every
#   frame and satisfies every "did it draw" check ever written.
#
#   THE OVER-DRAW — a mark invented for a window that holds no bin at all, and
#   a mark drawn for a bin that is below the axis floor. Both are figures that
#   claim something the data does not say, in the same direction the original
#   defect did.
#
#   THE HALF-DONE LIFT — a block that gathers every axis into perfect
#   declarations while the steps below keep their own literals (which is the
#   trap this whole ruling turns on); the sentinel hardcoded so a typed range
#   is thrown away; the pair identity taken on the minimum alone so an auto
#   figure and a zero-floor figure share one variable; zero treated as absent
#   the way an empty column name is; and one entry of the hand-maintained map
#   misspelled, which lifts nothing and says nothing.
#
#   Run:  bash harness/axisspec/break.sh [name-substring]
#   Out:  harness/axisspec/out/BREAKS.tsv    break, red-count, first failure
#         harness/axisspec/out/break_<name>.v67.log
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
WORK="${TMPDIR:-/tmp}/eml-axisspec-breaks"
FILTER="${1:-}"

mkdir -p "$OUT" "$WORK"
TSV="$OUT/BREAKS.tsv"
[ -n "$FILTER" ] || : > "$TSV"

DRAW=plugin/graphs/eml-draw-procedures.praat
REC=plugin/stats/eml-record.praat

# shadow <name> — a clean copy of the tree at $WORK/<name>, minus the heavy
# output folders. .git is excluded: a break tree is not a repository.
shadow () {
    local n=$1
    rm -rf "${WORK:?}/$n"
    mkdir -p "$WORK/$n"
    tar -c --exclude=.git --exclude=harness/stress_out \
        --exclude=harness/drawlayer/out --exclude=harness/axisspec/out \
        --exclude=harness/record/replay_out --exclude=evidence \
        -C "$ROOT" . | tar -x -C "$WORK/$n"
    mkdir -p "$WORK/$n/harness/axisspec/out"
}

revert () {
    ( cd "$ROOT" && git show "HEAD:$2" ) > "$WORK/$1/$2"
}

run_break () {
    # TWO STATEMENTS, NOT ONE. `local n=$1 o="$WORK/$n/..."` expands every
    # word before it assigns any of them, so $n is still unset when $o is
    # built — and under `set -u` that is an abort before the first break runs.
    local n=$1
    local o="$WORK/$n/harness/axisspec/out"
    EML_AS_SRC="$WORK/$n" EML_AS_OUTDIR="$o" \
        timeout 1200 bash "$WORK/$n/harness/axisspec/axisspec.sh" \
        > "$o/drive.log" 2>&1
    EML_AXIS_DRAW_SRC="$WORK/$n/plugin/graphs" \
    EML_AXIS_REC_SRC="$WORK/$n/plugin/stats" \
    EML_AXISSPEC_DIR="$o" \
        Rscript "$ROOT/validate/v67_axis_and_spectrum.R" \
        > "$OUT/break_$n.v67.log" 2>&1
    local red first
    red=$(grep -c '^FAIL' "$OUT/break_$n.v67.log")
    first=$(grep -m1 '^FAIL' "$OUT/break_$n.v67.log" \
            | sed 's/^FAIL  *v67  *//; s/  computed.*//' | cut -c1-92)
    printf '%s\t%s\t%s\n' "$n" "$red" "${first:-<none>}" >> "$TSV"
    printf '  %-28s red=%-4s %s\n' "$n" "$red" "${first:-NOTHING WENT RED}"
}

want () {
    local n="$1"
    [ -z "$FILTER" ] && return 0
    case "$n" in *"$FILTER"*) return 0 ;; *) return 1 ;; esac
}

py () { python3 - "$1" ; }

# ---------------------------------------------------------------------------
# 1. THE DEFECT ITSELF, one repair at a time
# ---------------------------------------------------------------------------
if want head_spectrum; then
    shadow head_spectrum
    python3 - "$WORK/head_spectrum/$DRAW" <<'PY'
import sys, re
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
i = s.index('    .nBins = Get number of bins')
j = s.index('    # Draw axes\n    @emlDrawAxes: .freqMin, .freqMax, .powerMin', i)
s = s[:i] + '    Draw: .freqMin, .freqMax, .powerMin, .powerMax, "no"\n\n' + s[j:]
open(p, 'w', encoding='utf-8').write(s)
PY
    run_break head_spectrum
fi

if want head_recorder; then
    shadow head_recorder
    revert head_recorder "$REC"
    run_break head_recorder
fi

# ---------------------------------------------------------------------------
# 2. THE MECHANISM RATHER THAN THE TEXT
# ---------------------------------------------------------------------------
# EVERY WORD OF THE PROSE AND EVERY LINE OF THE STEM LEFT IN PLACE, and one
# comparison changed so the branch can never run: two-or-more becomes
# one-or-more, so a single bin falls back into Praat's `Draw:` and draws
# nothing. This is the break a static check that greps unstripped source
# passes, because the repair is still described in full immediately above it.
if want stem_branch_unreachable; then
    shadow stem_branch_unreachable
    python3 - "$WORK/stem_branch_unreachable/$DRAW" <<'PY'
import sys
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
old = '    if .binsInRange >= 2\n'
assert s.count(old) == 1
open(p, 'w', encoding='utf-8').write(
    s.replace(old, '    if .binsInRange >= 1\n'))
PY
    run_break stem_branch_unreachable
fi

# The request is asked for and the answer is thrown away. Both counts of call
# sites still pass; every recorder still records the form's resolution as
# though the user had typed it.
if want request_answer_discarded; then
    shadow request_answer_discarded
    python3 - "$WORK/request_answer_discarded/$DRAW" <<'PY'
import sys, re
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
s = re.sub(r'\n[ ]+\.[A-Za-z]+ = emlRecordAxisRequest\.(min|max)', '', s)
open(p, 'w', encoding='utf-8').write(s)
PY
    run_break request_answer_discarded
fi

# ---------------------------------------------------------------------------
# 3. THE FIX-SHAPED FIX
# ---------------------------------------------------------------------------
# THE OBVIOUS dB FORMULA. 10*log10 ((re^2+im^2)/4e-10) is what anyone would
# write, it is what harness/drawlayer's own probe uses to report the peak, and
# it is NOT what Praat's `Draw:` plots — it is 10.32 dB low on this fixture.
# The stem has exactly the right shape, stands at exactly the right frequency,
# and is 96 image rows short. If this does not go red, section 2's row check
# is decoration.
if want naive_db; then
    shadow naive_db
    python3 - "$WORK/naive_db/$DRAW" <<'PY'
import sys
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
old = '.binDb = 10 * log10 (2 * .binWidth * .binPower / 4e-10)'
assert old in s
open(p, 'w', encoding='utf-8').write(
    s.replace(old, '.binDb = 10 * log10 (.binPower / 4e-10)'))
PY
    run_break naive_db
fi

# A STEM TO THE TOP OF THE FRAME, whatever the bin holds. Ink inside every
# frame, a mark at the right frequency, a foot on the floor — and it says
# nothing about the data. This is what "draw what you can" becomes if the
# value is not carried.
if want stem_full_height; then
    shadow stem_full_height
    python3 - "$WORK/stem_full_height/$DRAW" <<'PY'
import sys
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
old = 'Draw line: .binFreq, .powerMin, .binFreq, .binDb'
assert old in s
open(p, 'w', encoding='utf-8').write(
    s.replace(old, 'Draw line: .binFreq, .powerMin, .binFreq, .powerMax'))
PY
    run_break stem_full_height
fi

# THE STEM AT THE MIDDLE OF THE WINDOW. Simpler than the right answer — it
# needs no bin query at all — and 420 px away from it on this fixture. Every
# ink check, every height check and every foot check still passes.
if want stem_at_window_centre; then
    shadow stem_at_window_centre
    python3 - "$WORK/stem_at_window_centre/$DRAW" <<'PY'
import sys
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
old = '.binFreq = Get frequency from bin number: .binLo'
assert old in s
open(p, 'w', encoding='utf-8').write(
    s.replace(old, '.binFreq = (.freqMin + .freqMax) / 2'))
PY
    run_break stem_at_window_centre
fi

# ---------------------------------------------------------------------------
# 4. THE OVER-DRAW
# ---------------------------------------------------------------------------
# A MARK FOR A WINDOW THAT HOLDS NO BIN. The ruling says zero bins stays empty
# because there is genuinely nothing to draw; this is the "surely we can put
# something there" repair, and it is a figure that claims data it does not
# have.
if want zerobin_invents_a_mark; then
    shadow zerobin_invents_a_mark
    python3 - "$WORK/zerobin_invents_a_mark/$DRAW" <<'PY'
import sys
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
old = '    elsif .binsInRange = 1\n'
assert s.count(old) == 1
s = s.replace(old, '    elsif .binsInRange <= 1\n')
# THE MARK HAS TO LAND INSIDE THE WINDOW OR THE BREAK PROVES NOTHING. The
# first cut of this break took the nearest bin, whose frequency is OUTSIDE the
# zero-bin window by construction -- so Praat clipped the stem away and the
# interior ink stayed 0. The check looked green against a tree that was
# drawing an invented mark; it was only the static check that noticed. The
# nearest bin's VALUE is now drawn at the middle of the window, which is what
# a "surely we can put something there" repair would actually do.
old2 = '        .binFreq = Get frequency from bin number: .binLo'
assert old2 in s
s = s.replace(old2,
              '        if .binLo > .nBins\n'
              '            .binLo = .nBins\n'
              '        endif\n'
              '        .binFreq = (.freqMin + .freqMax) / 2')
s = s.replace('        .binRe = Get real value in bin: .binLo',
              '        if .binLo > .nBins\n'
              '            .binLo = .nBins\n'
              '        endif\n'
              '        .binRe = Get real value in bin: .binLo')
open(p, 'w', encoding='utf-8').write(s)
PY
    run_break zerobin_invents_a_mark
fi

# A BIN BELOW THE AXIS FLOOR, DRAWN ANYWAY. Praat's own `Draw:` does not plot
# a point off the paper; a stem that does is a figure asserting a level the
# user's own axis says is out of view.
if want below_floor_drawn; then
    shadow below_floor_drawn
    python3 - "$WORK/below_floor_drawn/$DRAW" <<'PY'
import sys
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
old = ('        if .binDb > .powerMin\n'
       '            Draw line: .binFreq, .powerMin, .binFreq, .binDb\n'
       '            .oneBinDrawn = 1\n'
       '        endif')
new = ('        if .binDb < .powerMin\n'
       '            .binDb = .powerMin + (.powerMax - .powerMin) * 0.02\n'
       '        endif\n'
       '        Draw line: .binFreq, .powerMin, .binFreq, .binDb\n'
       '        .oneBinDrawn = 1')
assert old in s
open(p, 'w', encoding='utf-8').write(s.replace(old, new))
PY
    run_break below_floor_drawn
fi

# ---------------------------------------------------------------------------
# 5. THE HALF-DONE LIFT
# ---------------------------------------------------------------------------
# THE BLOCK THAT IS DECORATION. Every declaration gathered, spelled right,
# with the right values and the right notes — and the steps below still
# reading their own literals. This is the trap the whole ruling turns on and
# the one that passes every static check anybody would think to write.
if want block_is_decoration; then
    shadow block_is_decoration
    python3 - "$WORK/block_is_decoration/$REC" <<'PY'
import sys
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
old = ('                                .newArg$[.aMinPos] = .aMinLead$\n'
       '                                ... + .axMinName$[.aSlot]\n'
       '                                .newArg$[.aMaxPos] = .aMaxLead$\n'
       '                                ... + .axMaxName$[.aSlot]\n')
assert old in s
open(p, 'w', encoding='utf-8').write(s.replace(old, ''))
PY
    run_break block_is_decoration
fi

# THE MIRROR OF THE REPAIR: the sentinel HARDCODED, so a range the user typed
# is thrown away. Every check on the auto arm still passes.
if want hardcode_auto; then
    shadow hardcode_auto
    python3 - "$WORK/hardcode_auto/$REC" <<'PY'
import sys
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
old = ('                                if .aAuto = 1\n'
       '                                    .aMinOut$ = "0.0"\n'
       '                                    .aMaxOut$ = "0.0"\n'
       '                                endif')
new = ('                                .aMinOut$ = "0.0"\n'
       '                                .aMaxOut$ = "0.0"')
assert old in s
open(p, 'w', encoding='utf-8').write(s.replace(old, new))
PY
    run_break hardcode_auto
fi

# THE PAIR TAKEN APART. Identity on the minimum alone, which is ruling 9's
# column rule copied without the one thing that had to change: an AUTO figure
# and a figure with a typed floor of zero then share one axisYMin, and editing
# it silently redraws the other.
if want pair_split; then
    shadow pair_split
    python3 - "$WORK/pair_split/$REC" <<'PY'
import sys
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
old = ('                                        if .axMinLit$[.k] = .aMinOut$\n'
       '                                            if .axMaxLit$[.k] = .aMaxOut$\n'
       '                                                .aSlot = .k\n'
       '                                            endif\n'
       '                                        endif')
new = ('                                        if .axMinLit$[.k] = .aMinOut$\n'
       '                                            .aSlot = .k\n'
       '                                        endif')
assert old in s
open(p, 'w', encoding='utf-8').write(s.replace(old, new))
PY
    run_break pair_split
fi

# ZERO TREATED AS ABSENT, which is the column path's guard copied onto the
# numeric one. (0, 0) is the one value this ruling exists to preserve, so the
# auto figures keep their literals and the defect returns from the other side.
if want zero_is_absent; then
    shadow zero_is_absent
    python3 - "$WORK/zero_is_absent/$REC" <<'PY'
import sys
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
old = '                            if .aIsNum = 1\n'
assert s.count(old) == 1
new = '                            if .aIsNum = 1 and number (.aMinLit$) <> 0\n'
open(p, 'w', encoding='utf-8').write(s.replace(old, new))
PY
    run_break zero_is_absent
fi

# THE RESOLVED NOTE DROPPED. The block says 0.0 and 0.0 and never says what
# that came out as, so the only way to find out what to type instead is to run
# the file and look — which is the half of the ruling a "0.0 is enough" repair
# quietly loses.
if want note_dropped; then
    shadow note_dropped
    python3 - "$WORK/note_dropped/$REC" <<'PY'
import sys
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
old = '    Set string value: .row, "axis", .minText$ + " " + .maxText$'
assert old in s
open(p, 'w', encoding='utf-8').write(
    s.replace(old, '    Set string value: .row, "axis", ""'))
PY
    run_break note_dropped
fi

# ONE ENTRY OF THE HAND-MAINTAINED MAP MISSPELLED. It never matches, lifts
# nothing, and is invisible: the emitted spectrum step keeps its literals
# under a block that promises otherwise. This is v58 section 8's lesson, and
# the reason the census in section 1b runs in both directions.
if want map_typo; then
    shadow map_typo
    python3 - "$WORK/map_typo/$REC" <<'PY'
import sys
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
old = 'elsif .axisProc$ = "emlDrawSpectrum"'
assert old in s
open(p, 'w', encoding='utf-8').write(
    s.replace(old, 'elsif .axisProc$ = "emlDrawSpectra"'))
PY
    run_break map_typo
fi

# THE SLOT NUMBERS OFF BY ONE. The entry names the right procedure and points
# one argument to the left, so the violin's VALUE COLUMN is lifted into
# axisYMin. The map still censuses clean by name; only the signature check and
# the drive notice.
if want wrong_slot; then
    shadow wrong_slot
    python3 - "$WORK/wrong_slot/$REC" <<'PY'
import sys
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
old = ('    elsif .axisProc$ = "emlDrawViolinPlot"\n'
       '        ; ...,groupCol,valueCol,vMin,vMax\n'
       '        .axisSpec$ = "11 12 axisY"')
new = ('    elsif .axisProc$ = "emlDrawViolinPlot"\n'
       '        ; ...,groupCol,valueCol,vMin,vMax\n'
       '        .axisSpec$ = "10 11 axisY"')
assert old in s
open(p, 'w', encoding='utf-8').write(s.replace(old, new))
PY
    run_break wrong_slot
fi

# THE FALLBACK REMOVED. Preferring a global that may not exist is an abort for
# every caller that never ran the form — the API export, the batch module,
# every harness in this tree. The `variableExists` pair is not a courtesy and
# this is what says so.
if want no_fallback; then
    shadow no_fallback
    python3 - "$WORK/no_fallback/$REC" <<'PY'
import sys
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
old = ('    .min = .fbMin\n'
       '    .max = .fbMax\n'
       '    .fromForm = 0\n'
       '    if variableExists ("emlGraphsAxisYReqMin")\n'
       '        if variableExists ("emlGraphsAxisYReqMax")\n'
       '            .min = emlGraphsAxisYReqMin\n'
       '            .max = emlGraphsAxisYReqMax\n'
       '            .fromForm = 1\n'
       '        endif\n'
       '    endif')
new = ('    .min = emlGraphsAxisYReqMin\n'
       '    .max = emlGraphsAxisYReqMax\n'
       '    .fromForm = 1')
assert old in s
open(p, 'w', encoding='utf-8').write(s.replace(old, new))
PY
    run_break no_fallback
fi

# THE GLOBALS IGNORED. The other side of the contract: the recorder works only
# from its arguments, so an annotated or legend-bearing figure — where the
# form has already resolved the axis — records the resolution as though the
# user had typed it. This is ruling 10(a)'s defect, arriving by a path 10(a)
# did not close.
if want globals_ignored; then
    shadow globals_ignored
    python3 - "$WORK/globals_ignored/$REC" <<'PY'
import sys
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
old = ('    if variableExists ("emlGraphsAxisYReqMin")\n'
       '        if variableExists ("emlGraphsAxisYReqMax")\n'
       '            .min = emlGraphsAxisYReqMin\n'
       '            .max = emlGraphsAxisYReqMax\n'
       '            .fromForm = 1\n'
       '        endif\n'
       '    endif')
assert old in s
open(p, 'w', encoding='utf-8').write(s.replace(old, ''))
PY
    run_break globals_ignored
fi

echo "breaks: wrote $TSV"
exit 0
