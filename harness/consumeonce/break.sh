#!/usr/bin/env bash
# ============================================================================
# harness/consumeonce/break.sh — nothing is validated until it has been broken
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Every break is a COPY of the repository with one deliberate defect, driven
# through $EML_CO_SRC and read by validate/v74 through $EML_CO_GRAPH_SRC,
# $EML_CO_STATS_SRC and $EML_CO_DIR. The working tree is never touched and
# never has to be, which is the point: a break test that edits the tree and
# puts it back is one interrupted run away from committing a defect.
#
# WHAT EACH BREAK IS FOR.
#
#   head_record      the reader reverted to HEAD — the pair preferred whenever
#                    it EXISTS. THE DEFECT ITSELF: the form still publishes and
#                    still stamps, and the Q-Q figure still inherits the form's
#                    range, because nothing consumes the publication.
#
#   head_form        the form reverted to HEAD — no stamp published at all,
#                    with the new reader in place. The opposite failure and the
#                    one a partial merge produces: every form figure is refused
#                    its own user's range and ruling 10(b) is undone in silence.
#
#   exists_only      the reader asks whether a stamp EXISTS instead of whether
#                    it names this step. It is the repair somebody writes who
#                    has read the word "stamp" and not the ruling, and it
#                    reintroduces the leak exactly.
#
#   no_consume       the stamp is validated and never reset. On this rig the
#                    RECORDED ranges stay right, because the stamp goes stale
#                    on its own the moment the step number moves — so the only
#                    thing that can see it is section 6, which reads the stamp
#                    out of the running process. That is what section 6 is for.
#
#   stamp_at_publish the re-take in @emlGraphsDispatchDraw removed, so the
#                    stamp is taken where the pair is published. Right in
#                    shape, wrong on the ruling's headline case: the annotation
#                    bridge records a step in between, so the annotated figure
#                    is refused its own range.
#
#   stamp_one_branch the stamp moved INSIDE the first branch of the type chain,
#                    so twelve of the thirteen graph types publish a pair with
#                    no stamp. The recorded ranges are unaffected — dispatch
#                    stamps them anyway — and the both-or-neither invariant is
#                    gone. Section 7 is the only thing that can see it, and
#                    that is the honest size of section 7's claim.
#
#   Run:  bash harness/consumeonce/break.sh [name-substring]
#   Out:  harness/consumeonce/out/BREAKS.tsv   break, red-count, first failure
#         harness/consumeonce/out/break_<name>.v74.log
#
#   $EML_CO_BREAK_WORK moves the shadow trees off the default scratch path.
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
WORK="${EML_CO_BREAK_WORK:-${TMPDIR:-/tmp}/eml-consumeonce-breaks}"
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
    mkdir -p "$WORK/$n/harness/consumeonce/out"
}

revert () {
    ( cd "$ROOT" && git show "HEAD:$2" ) > "$WORK/$1/$2"
}

run_break () {
    local n=$1
    local o="$WORK/$n/harness/consumeonce/out"
    EML_CO_SRC="$WORK/$n" EML_CO_OUTDIR="$o" \
        timeout 1200 bash "$WORK/$n/harness/consumeonce/consumeonce.sh" \
        > "$o/drive.log" 2>&1
    EML_CO_GRAPH_SRC="$WORK/$n/plugin/graphs" \
    EML_CO_STATS_SRC="$WORK/$n/plugin/stats" \
    EML_CO_DIR="$o" \
        Rscript "$ROOT/validate/v74_axis_consume_once.R" \
        > "$OUT/break_$n.v74.log" 2>&1
    local red first
    red=$(grep -c '^FAIL' "$OUT/break_$n.v74.log")
    first=$(grep -m1 '^FAIL' "$OUT/break_$n.v74.log" \
            | sed 's/^FAIL  *v74  *//; s/  computed.*//' | cut -c1-92)
    printf '%s\t%s\t%s\n' "$n" "$red" "${first:-<none>}" >> "$TSV"
    printf '  %-18s red=%-4s %s\n' "$n" "$red" "${first:-NOTHING WENT RED}"
}

want () {
    local n="$1"
    [ -z "$FILTER" ] && return 0
    case "$n" in *"$FILTER"*) return 0 ;; *) return 1 ;; esac
}

# ---------------------------------------------------------------------------
# 1. THE DEFECT ITSELF, one file at a time, so that neither repair can be
#    passing because the other file happens to be right.
# ---------------------------------------------------------------------------
if want head_record; then
    shadow head_record
    revert head_record "$REC"
    run_break head_record
fi

if want head_form; then
    shadow head_form
    revert head_form "$FORM"
    run_break head_form
fi

# ---------------------------------------------------------------------------
# 2. THE REPAIRS THAT LOOK RIGHT
# ---------------------------------------------------------------------------
if want exists_only; then
    shadow exists_only
    python3 - "$WORK/exists_only/$REC" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = """        if emlGraphsAxisYReqStep = .step
            .stampMatched = 1
        endif"""
new = """        .stampMatched = 1"""
assert old in s, "exists_only anchor not found"
open(p, "w", encoding="utf-8").write(s.replace(old, new, 1))
PY
    run_break exists_only
fi

if want no_consume; then
    shadow no_consume
    python3 - "$WORK/no_consume/$REC" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = """        emlGraphsAxisYReqStep = 0
    endif

    ; Nested rather than `and`-ed"""
new = """    endif

    ; Nested rather than `and`-ed"""
assert old in s, "no_consume anchor not found"
open(p, "w", encoding="utf-8").write(s.replace(old, new, 1))
PY
    run_break no_consume
fi

if want stamp_at_publish; then
    shadow stamp_at_publish
    python3 - "$WORK/stamp_at_publish/$FORM" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
i = s.index("procedure emlGraphsDispatchDraw")
j = s.index("    Erase all", i)
assert "@emlGraphsStampAxisRequest" in s[i:j], "stamp_at_publish anchor not found"
open(p, "w", encoding="utf-8").write(
    s[:i] + s[i:j].replace("    @emlGraphsStampAxisRequest\n", "") + s[j:])
PY
    run_break stamp_at_publish
fi

# ---------------------------------------------------------------------------
# 3. THE FORGOTTEN TYPE — the stamp moved inside the first branch of the type
#    chain, so twelve of thirteen types publish a pair with no stamp.
# ---------------------------------------------------------------------------
if want stamp_one_branch; then
    shadow stamp_one_branch
    python3 - "$WORK/stamp_one_branch/$FORM" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
i = s.index("procedure emlGraphsPublishAxisRequest")
j = s.index("endproc", i)
body = s[i:j]
assert "    @emlGraphsStampAxisRequest\n" in body, "stamp_one_branch anchor not found"
body = body.replace("    @emlGraphsStampAxisRequest\n", "")
body = body.replace("""        emlGraphsAxisYReqMax = freqMax
""", """        emlGraphsAxisYReqMax = freqMax
        @emlGraphsStampAxisRequest
""")
open(p, "w", encoding="utf-8").write(s[:i] + body + s[j:])
PY
    run_break stamp_one_branch
fi

echo
echo "consumeonce/break.sh: $TSV"
cat "$TSV"
exit 0
