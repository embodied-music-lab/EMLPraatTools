#!/usr/bin/env bash
# ============================================================================
# harness/formaxis/break.sh — nothing is validated until it has been broken
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Every break is a COPY of the repository with one deliberate defect, driven
# through $EML_FA_SRC and read by validate/v68 through $EML_FA_GRAPH_SRC,
# $EML_FA_STATS_SRC and $EML_FA_DIR. The working tree is never touched and
# never has to be, which is the point: a break test that edits the tree and
# puts it back is one interrupted run away from committing a defect.
#
# WHAT EACH BREAK IS FOR. They fall into five groups, and the grouping is the
# argument:
#
#   THE DEFECT ITSELF — each of the two repairs reverted to HEAD, separately,
#   so that neither can be passing because the other file happens to be right.
#
#   THE MECHANISM RATHER THAN THE TEXT — the fixed$ site reverted with every
#   word of its paragraph left in place, which is the shape that caught a
#   sibling this week: a check that matched the prose explaining a fix went
#   green on a tree where the fix had been removed.
#
#   THE FIX-SHAPED FIX — a publication that clamps both numbers to the auto
#   sentinel. It satisfies every format assertion, every width assertion and
#   every auto leg in the file, and throws away the range of every user who
#   typed one. This is the break the typed legs exist for.
#
#   THE HALF-DONE PUBLICATION — the minimum published and not the maximum,
#   which is the partial the both-or-neither rule forbids; a goto that skips
#   the whole procedure; and a publication taken AFTER the pass that resolves
#   the axis, which is right in shape, right in both-or-neither, and captures
#   the answer instead of the question.
#
#   THE CHECK THAT MEASURES ITSELF — the bracket-headroom pass emptied to a
#   stub, so the sequence still runs and resolves nothing. A validator built
#   on a hand transcription of that block would be green on this tree, which
#   is exactly how harness/disclosure/probe_formpath.praat came to pass over a
#   clipped statistics box.
#
#   Run:  bash harness/formaxis/break.sh [name-substring]
#   Out:  harness/formaxis/out/BREAKS.tsv    break, red-count, first failure
#         harness/formaxis/out/break_<name>.v68.log
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
#            https://github.com/embodied-music-lab/PraatGen
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ============================================================================
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$HERE/.." && pwd)/_env.sh" || exit 1
ROOT="$EML_ROOT"
OUT="$HERE/out"
WORK="${TMPDIR:-/tmp}/ag2/eml-formaxis-breaks"
FILTER="${1:-}"

mkdir -p "$OUT" "$WORK"
TSV="$OUT/BREAKS.tsv"
[ -n "$FILTER" ] || : > "$TSV"

FORM=plugin/graphs/eml-graphs-form.praat
GRAPH=plugin/graphs/eml-graph-procedures.praat

# shadow <name> — a clean copy of the tree at $WORK/<name>, minus the heavy
# output folders. .git is excluded: a break tree is not a repository.
shadow () {
    local n=$1
    rm -rf "${WORK:?}/$n"
    mkdir -p "$WORK/$n"
    tar -c --exclude=.git --exclude=harness/stress_out \
        --exclude=harness/drawlayer/out --exclude=harness/axisspec/out \
        --exclude=harness/formaxis/out --exclude=harness/record/replay_out \
        --exclude=evidence \
        -C "$ROOT" . | tar -x -C "$WORK/$n"
    mkdir -p "$WORK/$n/harness/formaxis/out"
}

revert () {
    ( cd "$ROOT" && git show "HEAD:$2" ) > "$WORK/$1/$2"
}

run_break () {
    local n=$1
    local o="$WORK/$n/harness/formaxis/out"
    EML_FA_SRC="$WORK/$n" EML_FA_OUTDIR="$o" \
        timeout 1200 bash "$WORK/$n/harness/formaxis/formaxis.sh" \
        > "$o/drive.log" 2>&1
    EML_FA_GRAPH_SRC="$WORK/$n/plugin/graphs" \
    EML_FA_STATS_SRC="$WORK/$n/plugin/stats" \
    EML_FA_DIR="$o" \
        Rscript "$ROOT/validate/v68_form_axis_and_display.R" \
        > "$OUT/break_$n.v68.log" 2>&1
    local red first
    red=$(grep -c '^FAIL' "$OUT/break_$n.v68.log")
    first=$(grep -m1 '^FAIL' "$OUT/break_$n.v68.log" \
            | sed 's/^FAIL  *v68  *//; s/  computed.*//' | cut -c1-92)
    printf '%s\t%s\t%s\n' "$n" "$red" "${first:-<none>}" >> "$TSV"
    printf '  %-26s red=%-4s %s\n' "$n" "$red" "${first:-NOTHING WENT RED}"
}

want () {
    local n="$1"
    [ -z "$FILTER" ] && return 0
    case "$n" in *"$FILTER"*) return 0 ;; *) return 1 ;; esac
}

# ---------------------------------------------------------------------------
# 1. THE DEFECT ITSELF, one file at a time
# ---------------------------------------------------------------------------
if want head_form; then
    shadow head_form
    revert head_form "$FORM"
    run_break head_form
fi

if want head_graph; then
    shadow head_graph
    revert head_graph "$GRAPH"
    run_break head_graph
fi

# ---------------------------------------------------------------------------
# 2. THE MECHANISM RATHER THAN THE TEXT
#
# The clamp site reverted to fixed$ with the whole paragraph above it left in
# place — including the sentences that name @eml_fixed. A check that greps the
# file without stripping comments finds "@eml_fixed" and calls the repair
# present.
# ---------------------------------------------------------------------------
if want prose_only; then
    shadow prose_only
    python3 - "$WORK/prose_only/$GRAPH" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = """        @eml_fixed: .w, 2
        .panelStr$ = eml_fixed.result$
        @eml_fixed: .fontSize, 1
        .fontStr$ = eml_fixed.result$
        appendInfoLine: "NOTE: legend labels were shortened with an ellipsis",
        ... " — the widest one does not fit a ",
        ... .panelStr$, " inch panel at ", .fontStr$,"""
new = """        appendInfoLine: "NOTE: legend labels were shortened with an ellipsis",
        ... " — the widest one does not fit a ",
        ... fixed$ (.w, 2), " inch panel at ", fixed$ (.fontSize, 1),"""
assert old in s, "prose_only anchor not found"
open(p, "w", encoding="utf-8").write(s.replace(old, new))
PY
    run_break prose_only
fi

# ---------------------------------------------------------------------------
# 3. THE FIX-SHAPED FIX
#
# A publication of exactly the right shape — one procedure, one call site,
# both names on every branch, no goto, published before both passes — that
# clamps both numbers to the auto sentinel. Every auto leg passes. Every
# format check passes. Every width check passes. The typed legs are the only
# thing in the file that can tell.
# ---------------------------------------------------------------------------
if want clamp_zero; then
    shadow clamp_zero
    python3 - "$WORK/clamp_zero/$FORM" <<'PY'
import re, sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
i = s.index("procedure emlGraphsPublishAxisRequest")
j = s.index("endproc", i)
body = s[i:j]
new = re.sub(r"= (freqMin|ampMin|powerMin|valueMin|freqMax|ampMax|powerMax|valueMax)",
             "= 0", body)
assert new != body
open(p, "w", encoding="utf-8").write(s[:i] + new + s[j:])
PY
    run_break clamp_zero
fi

# ---------------------------------------------------------------------------
# 4. THE HALF-DONE PUBLICATION
# ---------------------------------------------------------------------------
# 4a. The minimum published and not the maximum. @emlRecordAxisRequest takes
# the pair as a pair, so this does not produce half a range — it produces the
# fallback, silently, on every figure.
if want partial_min; then
    shadow partial_min
    python3 - "$WORK/partial_min/$FORM" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
i = s.index("procedure emlGraphsPublishAxisRequest")
j = s.index("endproc", i)
body = s[i:j]
new = "\n".join(l for l in body.split("\n")
                if "emlGraphsAxisYReqMax =" not in l)
assert new != body
open(p, "w", encoding="utf-8").write(s[:i] + new + s[j:])
PY
    run_break partial_min
fi

# 4b. A goto at the top of the procedure. The procedure is still there, still
# called once, still writes both names on four branches — and never runs one
# of them. This is the shape a "guard" acquires when somebody adds one.
if want pub_goto; then
    shadow pub_goto
    python3 - "$WORK/pub_goto/$FORM" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = "procedure emlGraphsPublishAxisRequest\n"
new = "procedure emlGraphsPublishAxisRequest\n    goto PUBLISH_AXIS_DONE\n"
assert old in s
s = s.replace(old, new, 1)
i = s.index("procedure emlGraphsPublishAxisRequest")
j = s.index("endproc", i)
s = s[:j] + "    label PUBLISH_AXIS_DONE\n" + s[j:]
open(p, "w", encoding="utf-8").write(s)
PY
    run_break pub_goto
fi

# 4c. The publication taken AFTER the pass that resolves the axis. Right
# shape, right pair, both or neither, one call site — and it captures the
# answer rather than the question. This is the break the ORDER check exists
# for, and the values follow it.
if want publish_late; then
    shadow publish_late
    python3 - "$WORK/publish_late/$FORM" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
call = "    @emlGraphsPublishAxisRequest\n"
assert s.count(call) == 1
s = s.replace(call, "", 1)
anchor = "    @emlGraphsPreDispatchHeadroom\n"
assert s.count(anchor) == 1
s = s.replace(anchor, anchor + call, 1)
open(p, "w", encoding="utf-8").write(s)
PY
    run_break publish_late
fi

# 4d. Published early AND republished inside the resolving pass, which is the
# regression a later edit to the headroom block would produce.
if want republish; then
    shadow republish
    python3 - "$WORK/republish/$FORM" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = "        annotDataRange = valueMax - valueMin\n"
assert old in s
new = ("        emlGraphsAxisYReqMin = valueMin\n"
       "        emlGraphsAxisYReqMax = valueMax\n" + old)
open(p, "w", encoding="utf-8").write(s.replace(old, new, 1))
PY
    run_break republish
fi

# ---------------------------------------------------------------------------
# 5. THE WRONG PAIR
#
# One entry of the hand-maintained map pointed at the wrong dialog. The
# waveform publishes valueMin/valueMax, which on a Sound is a range the
# amplitude dialog never showed and which nothing raises about: every number
# involved is a plausible double. Only the `pairs` leg can see it.
# ---------------------------------------------------------------------------
if want wrong_pair; then
    shadow wrong_pair
    python3 - "$WORK/wrong_pair/$FORM" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = ("        emlGraphsAxisYReqMin = ampMin\n"
       "        emlGraphsAxisYReqMax = ampMax\n")
assert old in s
new = ("        emlGraphsAxisYReqMin = valueMin\n"
       "        emlGraphsAxisYReqMax = valueMax\n")
open(p, "w", encoding="utf-8").write(s.replace(old, new, 1))
PY
    run_break wrong_pair
fi

# ---------------------------------------------------------------------------
# 6. THE CHECK THAT MEASURES ITSELF
#
# @emlGraphsPreDispatchHeadroom emptied to a stub. The sequence still runs,
# every stage is still called, nothing resolves. A validator built on a hand
# transcription of that block would be green here — which is precisely how
# harness/disclosure/probe_formpath.praat came to pass over a statistics box
# that was being clipped off the figure.
# ---------------------------------------------------------------------------
if want headroom_stub; then
    shadow headroom_stub
    python3 - "$WORK/headroom_stub/$FORM" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
i = s.index("procedure emlGraphsPreDispatchHeadroom")
j = s.index("\nendproc", i)
stub = ("procedure emlGraphsPreDispatchHeadroom\n"
        "    dataYMax_forAnnotation = valueMax\n"
        "    if graph_type = 6\n"
        "        @emlMeasureBarData: objectId, groupColName$, valueColName$,"
        " errorBarMode, errorColName$\n"
        "    endif")
open(p, "w", encoding="utf-8").write(s[:i] + stub + s[j:])
PY
    run_break headroom_stub
fi

# ---------------------------------------------------------------------------
# 7. THE PRECISION CHANGE
#
# @eml_fixed at the right site with the wrong precision. The formatter is
# correct, the hoist is correct, the source checks are all satisfied — and the
# sentence a user reads changes. Only the verbatim note assertions can tell.
# ---------------------------------------------------------------------------
if want precision_one; then
    shadow precision_one
    python3 - "$WORK/precision_one/$GRAPH" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = "        @eml_fixed: .w, 2\n"
assert old in s
open(p, "w", encoding="utf-8").write(s.replace(old, "        @eml_fixed: .w, 1\n", 1))
PY
    run_break precision_one
fi


# ---------------------------------------------------------------------------
# 8. THE PUBLICATION THAT ESCAPES THE FORM
#
# The two globals initialised at FILE SCOPE, beside the array initialisation
# the form's top level already carries. It is a natural-looking edit and it is
# the worst one available: every headless caller that includes the form file —
# the API export, the batch module, a harness, a user script — now has both
# globals in scope, so @emlRecordAxisRequest prefers a form's answer for a
# draw no form was involved in. Only the no-form leg can see it.
# ---------------------------------------------------------------------------
if want publish_at_load; then
    shadow publish_at_load
    python3 - "$WORK/publish_at_load/$FORM" <<'PYX'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
assert "procedure emlGraphsPublishAxisRequest\n" in s
open(p, "w", encoding="utf-8").write(
    "emlGraphsAxisYReqMin = 0\nemlGraphsAxisYReqMax = 0\n" + s)
PYX
    run_break publish_at_load
fi

# ---------------------------------------------------------------------------
# 9. THE OTHER PASS REPUBLISHING
#
# `republish` above puts the write inside the bracket path. This one puts it
# inside the legend path, in the branch that widens the axis — the two sites
# fail independently, and a check that read only one of them would be green on
# half the figures in the plugin.
# ---------------------------------------------------------------------------
if want republish_legend; then
    shadow republish_legend
    python3 - "$WORK/republish_legend/$FORM" <<'PYX'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = ("                    valueMin = emlLegendHeadroomAfterDraw.yMin\n"
       "                    valueMax = emlLegendHeadroomAfterDraw.yMax\n")
assert old in s
new = old + ("                    emlGraphsAxisYReqMin = valueMin\n"
             "                    emlGraphsAxisYReqMax = valueMax\n")
open(p, "w", encoding="utf-8").write(s.replace(old, new, 1))
PYX
    run_break republish_legend
fi

# ---------------------------------------------------------------------------
# 10. THE FORMATTER, UNDONE THREE WAYS
# ---------------------------------------------------------------------------
# 10a. One of the FORM's own Info-window sites put back on fixed$. That file
# was swept clean on 15 August; this is the regression that undoes it, and the
# count is the only thing that notices.
if want form_fixed_back; then
    shadow form_fixed_back
    python3 - "$WORK/form_fixed_back/$FORM" <<'PYX'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = ("            @eml_fixed: emlComputeAnnotationHeadroom.legendGranted, 2\n"
       "            .gotStr$ = eml_fixed.result$\n")
assert old in s
new = ("            .gotStr$ = fixed$ "
       "(emlComputeAnnotationHeadroom.legendGranted, 2)\n")
open(p, "w", encoding="utf-8").write(s.replace(old, new, 1))
PYX
    run_break form_fixed_back
fi

# 10b. A SECOND implementation of the formatter, local to the graphs file. The
# clamp site still calls @eml_fixed, every other source check above is
# satisfied, and the plugin now has two things to keep right.
if want second_formatter; then
    shadow second_formatter
    python3 - "$WORK/second_formatter/$GRAPH" <<'PYX'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
dup = ("procedure eml_fixed: .value, .decimals\n"
       "    .result$ = fixed$ (.value, .decimals)\n"
       "endproc\n\n")
open(p, "w", encoding="utf-8").write(dup + s)
PYX
    run_break second_formatter
fi

# 10c. @eml_fixed neutered to a pass-through, in the file that owns it. Every
# source check is green — the site calls it, the hoist is right, there is one
# implementation — and the escalation it exists to prevent is back. Only the
# formatter measurements see it, which is what those rows are for.
if want emlfixed_neutered; then
    shadow emlfixed_neutered
    python3 - "$WORK/emlfixed_neutered/plugin/stats/eml-output.praat" <<'PYX'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
i = s.index("procedure eml_fixed: .value, .decimals")
j = s.index("\nendproc", i)
stub = ("procedure eml_fixed: .value, .decimals\n"
        "    .result$ = fixed$ (.value, .decimals)")
open(p, "w", encoding="utf-8").write(s[:i] + stub + s[j:])
PYX
    run_break emlfixed_neutered
fi

# ---------------------------------------------------------------------------
# 11. THE RETIRED SITE PUT BACK
#
# @emlCheckPlausibility was DELETED on 16 August 2026 with zero callers, and
# its three raw fixed$ calls went with it. Until then this slot wired the dead
# procedure up, because while the body existed the honest pin was on the
# CALLER COUNT. The body is gone, so that edit would now call a procedure that
# does not exist — a Praat run-time error, which is a broken rig rather than a
# measured red.
#
# TURNED AROUND, and turned around onto the failure the deletion actually
# risks: someone finds the procedure in git history, reads it as a feature
# that went missing, and pastes it back. That is what this shadow does — the
# v3.31 body, verbatim, at the tombstone, and NOTHING ELSE CHANGED. No caller
# is added, so a pin that had stayed on the caller count would be green on
# this tree with three raw fixed$ calls sitting back in the file.
#
# The body is taken from git rather than retyped: `git show HEAD:<graph>` is
# the file as it stood before the deletion, and awk lifts the procedure out of
# it. If this deletion is ever committed, HEAD moves past it and the awk range
# comes back empty — hence the `[ -s ]` guard, which fails the break loudly
# instead of running an unmodified shadow and reporting zero red as success.
# The replacement for that day is a stored copy of the body beside this file.
# ---------------------------------------------------------------------------
if want plausibility_readded; then
    shadow plausibility_readded
    BODY="$WORK/plausibility_readded/.plausibility_body.praat"
    ( cd "$ROOT" && git show "HEAD:$GRAPH" ) \
        | awk '/^procedure emlCheckPlausibility:/,/^endproc$/' > "$BODY"
    if [ ! -s "$BODY" ]; then
        echo "  plausibility_readded: SKIPPED — HEAD no longer carries the" \
             "procedure; store the body beside break.sh and read it from there"
    else
        python3 - "$WORK/plausibility_readded/$GRAPH" "$BODY" <<'PYX'
import sys
p, b = sys.argv[1], sys.argv[2]
lines = open(p, encoding="utf-8").read().splitlines(True)
body = open(b, encoding="utf-8").read()
anchor = [i for i, ln in enumerate(lines)
          if ln.startswith("# @emlCheckPlausibility WAS HERE")]
assert len(anchor) == 1, "tombstone not found once — was the site rewritten?"
# past the tombstone's closing rule, so the body lands as code and not inside
# the comment block that explains why it is not there
rule = [i for i, ln in enumerate(lines)
        if i > anchor[0] and ln.startswith("# ----")]
assert rule, "tombstone has no closing rule"
at = rule[0] + 1
open(p, "w", encoding="utf-8").writelines(lines[:at] + [body] + lines[at:])
PYX
        rm -f "$BODY"
        run_break plausibility_readded
    fi
fi


# ---------------------------------------------------------------------------
# 12. THE LEGEND PASS ITSELF
#
# `headroom_stub` empties the bracket pass; these two do the same work on the
# other one. A stub that stops widening the axis leaves the legend sitting on
# the data with nothing said, and a second call site would make the ordering
# check above answer about the wrong line.
# ---------------------------------------------------------------------------
if want legendroom_stub; then
    shadow legendroom_stub
    python3 - "$WORK/legendroom_stub/$FORM" <<'PYX'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = ("                    valueMin = emlLegendHeadroomAfterDraw.yMin\n"
       "                    valueMax = emlLegendHeadroomAfterDraw.yMax\n")
assert old in s
open(p, "w", encoding="utf-8").write(s.replace(old, "", 1))
PYX
    run_break legendroom_stub
fi

if want legendroom_twice; then
    shadow legendroom_twice
    python3 - "$WORK/legendroom_twice/$FORM" <<'PYX'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
call = "    @emlGraphsDrawWithLegendRoom\n"
assert s.count(call) == 1
open(p, "w", encoding="utf-8").write(s.replace(call, call + call, 1))
PYX
    run_break legendroom_twice
fi

echo
echo "BREAKS.tsv:"
column -t -s $'\t' "$TSV" 2>/dev/null || cat "$TSV"
