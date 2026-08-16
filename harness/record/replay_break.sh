#!/usr/bin/env bash
# ============================================================================
# harness/record/replay_break.sh — nothing is validated until it has been
#                                  broken
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Every break is a COPY of the repository with one deliberate defect. The
# shadow's own replay.sh is driven through $EML_REPLAY_DIR and read by
# validate/v75 through $EML_REPLAY_DIR, $EML_RECORD_PROC_SRC and
# $EML_GRAPHS_FORM_SRC. The working tree is never touched and never has to be,
# which is the point: a break test that edits the tree and puts it back is one
# interrupted run away from committing a defect.
#
# WHAT EACH BREAK IS FOR.
#
#   no_wiring        both calls removed from @emlGraphsDrawWithLegendRoom. THE
#                    DEFECT ITSELF -- the recorder's primitive exists and
#                    nothing calls it, which is the state the audit measured:
#                    the CSV collector rewound between passes and the recorder
#                    did not.
#
#   no_rewind        the mark is taken and never used. Same emitted file as
#                    no_wiring, and it is here to say which of the two calls
#                    is doing the work: a repair that took a mark and left the
#                    rewind out would look, in a diff, like the whole fix.
#
#   rewind_after_draw the rewind moved BELOW @emlGraphsDispatchDraw, so each
#                    pass is discarded after it has been drawn -- including the
#                    last one. Right shape, wrong place. It is also the leg
#                    that FOUND SOMETHING: with the rewind there, the live
#                    selection at rewind time is the recording buffer itself
#                    (@emlRecordStep leaves it selected), the empty-mark branch
#                    replaces that object, and the restore then asked for an
#                    object that had just been removed -- "No object with
#                    number 1", mid-draw. @emlRecordRewind now remaps the
#                    snapshot when it replaces the buffer, and this leg is why.
#
#   rows_only        the rewind restores the buffer's rows and NOT emlRecordN.
#                    The step COUNT stays right and the numbering goes wrong:
#                    the file's only step comes out "# --- Step 2 (draw) ---"
#                    with a block reading "step 2 (draw)", and with an ANOVA in
#                    front of it the figure is step 3 of two. It does NOT
#                    break the axis stamp, which is worth knowing rather than
#                    assuming -- @emlGraphsStampAxisRequest writes emlRecordN +
#                    1 and @emlRecordAxisRequest compares against emlRecordN +
#                    1, so a counter left one too high is still consistent with
#                    itself and this tree still emits the user's own 0.0 / 0.0.
#
#   no_rebuild       the empty-mark branch disabled, leaving the row-removal
#                    loop on its own. This is the trap, not a hypothetical:
#                    Praat refuses to remove a Table's only row and `nocheck`
#                    in front of that refusal is a SKIP, so a figure drawn as
#                    the FIRST thing in a recording keeps its discarded pass
#                    and nothing is reported. It was the first implementation.
#
#   mark_at_zero     the mark always records zero rows. The rewind then throws
#                    away everything that preceded the press as well as the
#                    pass -- the analysis before the figure disappears -- and
#                    every check about the FIGURE stays green. Section 4 is the
#                    only thing that can see it.
#
# THE FIGURE IS MEASURED ON EVERY BREAK, not just the record. LEG_ORIG.png's
# md5 is written into the TSV for each tree, so "this repair is recorded state
# only and reaches nothing on the page" is an artefact rather than a claim.
#
#   Run:  bash harness/record/replay_break.sh [name-substring]
#   Out:  harness/record/replay_out/breaks/BREAKS.tsv  break, red count, the
#                                       original figure's md5, first failure
#         harness/record/replay_out/breaks/break_<name>.v75.log
#
#   A SUBDIRECTORY, because replay.sh clears *.tsv and *.log out of
#   replay_out/ on every run and would take the break record with it.
#
#   $EML_REPLAY_BREAK_WORK moves the shadow trees off the default scratch path.
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
OUT="$HERE/replay_out/breaks"
WORK="${EML_REPLAY_BREAK_WORK:-${TMPDIR:-/tmp}/eml-replay-breaks}"
FILTER="${1:-}"

mkdir -p "$OUT" "$WORK"
TSV="$OUT/BREAKS.tsv"
[ -n "$FILTER" ] || : > "$TSV"

FORM=plugin/graphs/eml-graphs-form.praat
REC=plugin/stats/eml-record.praat

# shadow <name> — a clean copy of the tree at $WORK/<name>, minus the heavy
# output folders. .git is excluded: a break tree is not a repository.
shadow () {
    local n=$1
    rm -rf "${WORK:?}/$n"
    mkdir -p "$WORK/$n"
    tar -c --exclude=.git --exclude=harness/stress_out \
        --exclude=harness/drawlayer/out --exclude=harness/axisspec/out \
        --exclude=harness/formaxis/out --exclude=harness/consumeonce/out \
        --exclude=harness/record/replay_out --exclude=evidence \
        -C "$ROOT" . | tar -x -C "$WORK/$n"
    mkdir -p "$WORK/$n/harness/record/replay_out"
}

# edit <tree> <file> <python-expression-on-text>
# The edits are python string surgery rather than sed, because three of them
# move a line rather than delete it and one of them has to be refused loudly
# if the text it is anchored on has drifted. A break that silently edited
# NOTHING would run the unbroken tree and report a green break test, which is
# the one outcome this whole file exists to prevent.
edit () {
    local tree=$1 file=$2 py=$3
    python3 - "$WORK/$tree/$file" "$py" <<'PY'
import sys
path, tag = sys.argv[1], sys.argv[2]
s = open(path, encoding="utf-8").read()
orig = s

if tag == "drop_mark":
    s = s.replace("\n    @emlRecordMark\n", "\n")
elif tag == "drop_rewind":
    s = s.replace("\n        @emlRecordRewind\n", "\n")
elif tag == "rewind_after_draw":
    s = s.replace("        @emlRecordRewind\n\n        @emlGraphsDispatchDraw\n",
                  "\n        @emlGraphsDispatchDraw\n        @emlRecordRewind\n")
elif tag == "rows_only":
    s = s.replace("\n            emlRecordN = emlRecordMark_n\n", "\n")
elif tag == "no_rebuild":
    s = s.replace("            if emlRecordMark_rows = 0\n",
                  "            if emlRecordMark_rows = -99\n")
elif tag == "mark_at_zero":
    s = s.replace("            emlRecordMark_rows = Get number of rows\n",
                  "            emlRecordMark_rows = 0\n")
else:
    sys.exit("unknown break tag: " + tag)

if s == orig:
    sys.exit("BREAK DID NOT APPLY (%s in %s) -- the anchor text has moved"
             % (tag, path))
open(path, "w", encoding="utf-8").write(s)
PY
}

run_break () {
    local n=$1
    local o="$WORK/$n/harness/record/replay_out"
    EML_REPLAY_DIR="$o" \
        timeout 1800 bash "$WORK/$n/harness/record/replay.sh" \
        > "$o/drive.log" 2>&1
    EML_REPLAY_DIR="$o" \
    EML_RECORD_PROC_SRC="$WORK/$n/$REC" \
    EML_GRAPHS_FORM_SRC="$WORK/$n/$FORM" \
        Rscript "$ROOT/validate/v75_legend_single_step.R" \
        > "$OUT/break_$n.v75.log" 2>&1
    local red first md5
    red=$(grep -c '^FAIL' "$OUT/break_$n.v75.log")
    first=$(grep -m1 '^FAIL' "$OUT/break_$n.v75.log" \
            | sed 's/^FAIL  *v75  *//; s/  computed.*//' | cut -c1-92)
    if [ -f "$o/LEG_ORIG.png" ]; then
        md5=$(md5sum "$o/LEG_ORIG.png" | cut -d' ' -f1)
    else
        md5="<none>"
    fi
    printf '%s\t%s\t%s\t%s\n' "$n" "$red" "$md5" "${first:-<none>}" >> "$TSV"
    printf '  %-18s red=%-4s fig=%s  %s\n' "$n" "$red" "${md5:0:8}" \
        "${first:-NOTHING WENT RED}"
}

want () {
    local n="$1"
    [ -z "$FILTER" ] && return 0
    case "$n" in *"$FILTER"*) return 0 ;; *) return 1 ;; esac
}

echo "replay_break: shadows under $WORK"

if want no_wiring; then
    shadow no_wiring
    edit no_wiring "$FORM" drop_mark
    edit no_wiring "$FORM" drop_rewind
    run_break no_wiring
fi

if want no_rewind; then
    shadow no_rewind
    edit no_rewind "$FORM" drop_rewind
    run_break no_rewind
fi

if want rewind_after_draw; then
    shadow rewind_after_draw
    edit rewind_after_draw "$FORM" rewind_after_draw
    run_break rewind_after_draw
fi

if want rows_only; then
    shadow rows_only
    edit rows_only "$REC" rows_only
    run_break rows_only
fi

if want no_rebuild; then
    shadow no_rebuild
    edit no_rebuild "$REC" no_rebuild
    run_break no_rebuild
fi

if want mark_at_zero; then
    shadow mark_at_zero
    edit mark_at_zero "$REC" mark_at_zero
    run_break mark_at_zero
fi

echo
echo "replay_break: $TSV"
column -t -s$'\t' "$TSV" 2>/dev/null || cat "$TSV"
exit 0
