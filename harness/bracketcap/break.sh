#!/usr/bin/env bash
# ============================================================================
# harness/bracketcap/break.sh — nothing is validated until it has been broken
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Every break is a COPY of the repository carrying one deliberate defect,
# driven through $EML_BC_SRC and read by validate/v69 through $EML_ANNOT_SRC
# and $EML_BRACKETCAP_DIR. The working tree is never touched and never has to
# be, which is the point: a break test that edits the tree and puts it back is
# one interrupted run away from committing a defect.
#
# WHAT EACH BREAK IS FOR. They fall into four groups, and the grouping is the
# argument rather than a filing convention:
#
#   THE DEFECT ITSELF — the whole repair reverted to HEAD, and separately the
#   call site removed while the procedure stays. The split matters: a
#   procedure that exists and is never called leaves every sentence in the
#   file for a text search to find.
#
#   THE MECHANISM RATHER THAN THE TEXT — the extent report deleted, so the
#   caption is drawn correctly and then cropped off the export; the viewport
#   restore deleted, so everything drawn after the caption lands in the
#   caption's band; one arm repaired and the other left silent. All three
#   produce a caption that is composed correctly.
#
#   THE FIX-SHAPED FIX — the caption clamped to a blank of the right shape,
#   which satisfies every assertion about width, placement, band geometry and
#   the two-arm asymmetry and discloses nothing; the correction hardcoded to
#   "holm", which is right on one third of the menu; one generic sentence
#   serving both arms, which is what the ruling forbids; and — the sharpest
#   one — the fit logic removed while the procedure goes on REPORTING that it
#   fits, so the only thing left that can fail is the ink measured on the
#   right-hand edge of the picture.
#
#   THE OVER-SWEEP — a caption on the two-group arms, where there is no
#   post-hoc and no family and the sentence would be a claim about a
#   correction that never happened.
#
#   Run:  bash harness/bracketcap/break.sh [name-substring]
#   Out:  harness/bracketcap/out/BREAKS.tsv        break, red-count, first fail
#         harness/bracketcap/out/break_<name>.v69.log
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ============================================================================
set -u

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../_env.sh" || exit 1
ROOT="$EML_ROOT"
OUT="$ROOT/harness/bracketcap/out"
WORK="${EML_BC_WORK:-/tmp/ag3/breaks}"
TSV="$OUT/BREAKS.tsv"
FILTER="${1:-}"
ANNOT=plugin/graphs/eml-annotation-procedures.praat

mkdir -p "$OUT" "$WORK"
[ -z "$FILTER" ] && : > "$TSV"

# shadow <name> — a clean copy of the tree at $WORK/<name>, minus the heavy
# output folders. .git is excluded: a break tree is not a repository.
shadow () {
    local n=$1
    rm -rf "${WORK:?}/$n"
    mkdir -p "$WORK/$n"
    tar -c --exclude=.git --exclude=harness/stress_out \
        --exclude=harness/bracketcap/out --exclude=evidence \
        -C "$ROOT" . | tar -x -C "$WORK/$n"
    mkdir -p "$WORK/$n/harness/bracketcap/out"
}

# run_break <name> — drive the shadow and score validate/v69 against it.
run_break () {
    # TWO STATEMENTS, NOT ONE. `local n=$1 o="$WORK/$n/..."` expands every word
    # before it assigns any of them, so $n is still unset when $o is built —
    # and under `set -u` that is an abort before the first break runs.
    local n=$1
    local o="$WORK/$n/harness/bracketcap/out"
    EML_BC_SRC="$WORK/$n" EML_BC_OUTDIR="$o" \
        timeout 900 bash "$WORK/$n/harness/bracketcap/bracketcap.sh" \
        > "$o/drive.log" 2>&1
    EML_ANNOT_SRC="$WORK/$n/$ANNOT" EML_BRACKETCAP_DIR="$o" \
        Rscript "$ROOT/validate/v69_bracket_disclosure.R" \
        > "$OUT/break_$n.v69.log" 2>&1
    local red first
    red=$(grep -c '^FAIL' "$OUT/break_$n.v69.log")
    first=$(grep -m1 '^FAIL' "$OUT/break_$n.v69.log" \
            | sed 's/^FAIL  *v69  *//; s/  computed.*//' | cut -c1-88)
    printf '%s\t%s\t%s\n' "$n" "$red" "${first:-<none>}" >> "$TSV"
    printf '  %-26s red=%-4s %s\n' "$n" "$red" "${first:-NOTHING WENT RED}"
}

want () {
    local n="$1"
    [ -z "$FILTER" ] && return 0
    case "$n" in *"$FILTER"*) return 0 ;; *) return 1 ;; esac
}

# ---------------------------------------------------------------------------
# 1. THE DEFECT ITSELF
# ---------------------------------------------------------------------------
# The whole repair reverted. This is the state the ruling describes: a bracket
# figure with six brackets, six stars and no statement anywhere on it about
# which test drew them or what was done about multiplicity.
if want head_revert; then
    shadow head_revert
    ( cd "$ROOT" && git show "HEAD:$ANNOT" ) > "$WORK/head_revert/$ANNOT"
    run_break head_revert
fi

# The procedure survives, its sixty-line header survives, every sentence it
# draws survives — and it is never called. A check that greps the file for the
# strings passes; a check that reads the picture cannot.
if want no_call_site; then
    shadow no_call_site
    python3 - "$WORK/no_call_site/$ANNOT" <<'PY'
import sys
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
s = s.replace(
    "        @emlDrawBracketCaption: .fontSize, .xMin, .xMax, .axYMin, .axYMax\n",
    "        annotCaptionSuppressed = 1\n")
open(p, 'w', encoding='utf-8').write(s)
PY
    run_break no_call_site
fi

# ---------------------------------------------------------------------------
# 2. THE MECHANISM RATHER THAN THE TEXT
# ---------------------------------------------------------------------------
# The band is drawn and never reported to the extent tracker, so
# @emlAssertFullViewport selects the figure box and the caption is cropped off
# the export. EVERY NUMBER THE DRIVE EMITS IS IDENTICAL to a correct build --
# the width, the size, the line count, the band in inches, cap_drawn = 1 --
# because all of them are taken before the save. Only the file can tell.
if want no_extent; then
    shadow no_extent
    python3 - "$WORK/no_extent/$ANNOT" <<'PY'
import sys
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
s = s.replace("    @emlExpandDrawnExtent: .left, .right, .top, .bottom\n", "")
open(p, 'w', encoding='utf-8').write(s)
PY
    run_break no_extent
fi

# The caption leaves the viewport on its own band. Anything the caller draws
# afterwards -- the axes, the omnibus box -- lands in a strip below the plot.
if want no_restore; then
    shadow no_restore
    python3 - "$WORK/no_restore/$ANNOT" <<'PY'
import sys
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
s = s.replace("""    @emlSetPanelViewport
    Axes: .axXMin, .axXMax, .axYMin, .axYMax
    Font size: emlSetAdaptiveTheme.bodySize
""", "")
open(p, 'w', encoding='utf-8').write(s)
PY
    run_break no_restore
fi

# HALF THE REPAIR. The parametric arm discloses and the nonparametric arm --
# the one that actually HAS a correction to disclose, and the only one where
# the user's choice can change the numbers -- stays silent. A check that asked
# only "does a bracket figure carry a caption" would be satisfied by the
# Tukey leg.
if want one_arm_only; then
    shadow one_arm_only
    python3 - "$WORK/one_arm_only/$ANNOT" <<'PY'
import sys
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
s = s.replace('''                        annotBracketPosthoc$ = "Pairwise comparisons: Dunn's test"
                        annotBracketAdjust$ = "adjustment for multiple "
                        ... + "comparisons: " + .correction$''',
              '''                        annotBracketPosthoc$ = ""
                        annotBracketAdjust$ = ""''')
open(p, 'w', encoding='utf-8').write(s)
PY
    run_break one_arm_only
fi

# ---------------------------------------------------------------------------
# 3. THE FIX-SHAPED FIX
# ---------------------------------------------------------------------------
# A caption of blanks. It is non-empty, so it draws; it is narrow, so it fits;
# the band has the right geometry, the export grows, the two arms differ, and
# the picture says nothing at all. This is the local form of clamping every
# number to a zero of the right width, and only a check on the WORDS -- and on
# ink inside the band -- can see it.
if want caption_blank; then
    shadow caption_blank
    python3 - "$WORK/caption_blank/$ANNOT" <<'PY'
import sys
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
s = s.replace('annotBracketPosthoc$ = "Pairwise comparisons: Tukey HSD"',
              'annotBracketPosthoc$ = " "')
s = s.replace('''                annotBracketAdjust$ = "already family-wise; no further "
                ... + "adjustment applied"''',
              '''                annotBracketAdjust$ = "  "''')
s = s.replace('''annotBracketPosthoc$ = "Pairwise comparisons: Dunn's test"''',
              '''annotBracketPosthoc$ = " "''')
s = s.replace('''                        annotBracketAdjust$ = "adjustment for multiple "
                        ... + "comparisons: " + .correction$''',
              '''                        annotBracketAdjust$ = "  "''')
open(p, 'w', encoding='utf-8').write(s)
PY
    run_break caption_blank
fi

# The correction hardcoded. Right on holm, wrong on bonferroni and on bh, and
# indistinguishable from correct on any figure driven with the default. Every
# assertion about presence, shape, fit, placement and asymmetry passes.
if want hardcode_holm; then
    shadow hardcode_holm
    python3 - "$WORK/hardcode_holm/$ANNOT" <<'PY'
import sys
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
s = s.replace('''                        ... + "comparisons: " + .correction$''',
              '''                        ... + "comparisons: holm"''')
open(p, 'w', encoding='utf-8').write(s)
PY
    run_break hardcode_holm
fi

# ONE SENTENCE SERVING BOTH ARMS, which is precisely what the ruling forbids.
# It is true-ish on neither: Tukey applies no adjustment, and Dunn's applies
# whatever the user picked and controls nothing by itself. Both figures carry
# a caption, both fit, both have ink, and the disclosure is worthless.
if want one_sentence; then
    shadow one_sentence
    python3 - "$WORK/one_sentence/$ANNOT" <<'PY'
import sys
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
s = s.replace('annotBracketPosthoc$ = "Pairwise comparisons: Tukey HSD"',
              'annotBracketPosthoc$ = "Pairwise comparisons"')
s = s.replace('''                annotBracketAdjust$ = "already family-wise; no further "
                ... + "adjustment applied"''',
              '''                annotBracketAdjust$ = "corrected for multiplicity"''')
s = s.replace('''annotBracketPosthoc$ = "Pairwise comparisons: Dunn's test"''',
              '''annotBracketPosthoc$ = "Pairwise comparisons"''')
s = s.replace('''                        annotBracketAdjust$ = "adjustment for multiple "
                        ... + "comparisons: " + .correction$''',
              '''                        annotBracketAdjust$ = "corrected for multiplicity"''')
open(p, 'w', encoding='utf-8').write(s)
PY
    run_break one_sentence
fi

# THE FIRST-INK TRAP, BUILT ON PURPOSE. The shrink and the wrap are removed so
# the narrow figure's caption overruns the canvas and its tail is not in the
# file -- AND the procedure goes on reporting a width that fits, so every
# emitted measurement says the caption is fine. The opening words render
# exactly where a correct caption's opening words render, so ink_left is
# unchanged and a check anchored there is greenest on the worst case. The only
# thing left that can fail is the rightmost inked column against the image
# width.
if want clip_and_lie; then
    shadow clip_and_lie
    python3 - "$WORK/clip_and_lie/$ANNOT" <<'PY'
import sys, re
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
i = s.index('procedure emlDrawBracketCaption:')
j = s.index('\nendproc', i)
body = s[i:j]
# Everything from the first fit test to the line-height computation goes: no
# shrink, no wrap, one line at the annotation size whatever it measures.
a = body.index('    if .widthMM > .availMM')
b = body.index('    .lineInch =')
body = body[:a] + body[b:]
# ...and the reported width is replaced by one that fits, so nothing the drive
# emits can disagree with a correct build.
body = body.replace('    .drawn = 1\n', '    .drawn = 1\n    .widthMM = .availMM * 0.5\n')
s = s[:i] + body + s[j:]
open(p, 'w', encoding='utf-8').write(s)
PY
    run_break clip_and_lie
fi

# ---------------------------------------------------------------------------
# 4. THE OVER-SWEEP
# ---------------------------------------------------------------------------
# A caption on the two-group arms. Two groups is one comparison: no post-hoc
# ran, there is no family, and nothing was adjusted, so the sentence is a
# claim about a correction that never happened. A repair that moves figures
# nobody asked to move is a defect of its own.
if want two_group_caption; then
    shadow two_group_caption
    python3 - "$WORK/two_group_caption/$ANNOT" <<'PY'
import sys
p = sys.argv[1]
lines = open(p, encoding='utf-8').read().split('\n')

# LINE-WISE AND ASSIGNMENT-ONLY. A plain string split matches the GUARD in
# @emlDrawBracketCaption -- `if annotBracketPosthoc$ = "" or ...` -- as well
# as the three assignments, which is one occurrence too many and silently
# rewrites the wrong site. The three assignments, in file order, are
# @emlClearAnnotations, the Mann-Whitney arm and the Welch arm; only the last
# two are the two-group arms this break is about.
def sites(var):
    return [i for i, l in enumerate(lines)
            if l.strip() == var + ' = ""']

sp = sites('annotBracketPosthoc$')
sa = sites('annotBracketAdjust$')
assert len(sp) == 3, sp
assert len(sa) == 3, sa
for i, txt in ((sp[1], 'Pairwise comparisons: Mann-Whitney U'),
               (sp[2], 'Pairwise comparisons: Welch t-test')):
    ind = lines[i][:len(lines[i]) - len(lines[i].lstrip())]
    lines[i] = ind + 'annotBracketPosthoc$ = "%s"' % txt
for i in (sa[1], sa[2]):
    ind = lines[i][:len(lines[i]) - len(lines[i].lstrip())]
    lines[i] = ind + 'annotBracketAdjust$ = "no adjustment applied"'
open(p, 'w', encoding='utf-8').write('\n'.join(lines))
PY
    run_break two_group_caption
fi

echo
echo "BREAKS.tsv:"
awk -F'\t' '{printf "  %-26s red=%-4s %s\n", $1, $2, $3}' "$TSV"
