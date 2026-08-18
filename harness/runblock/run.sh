#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# runblock/run.sh -- drive the recorder over sessions of KNOWN RUN STRUCTURE
#                    and replay what it emitted
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
#   bash harness/runblock/run.sh
#
# WHAT THIS RIG IS FOR. The editable block at the top of a recorded script
# names its variables by RUN -- one pass through a GUI form and the save that
# belongs to it. Run 1's grouping column is groupCol$, run 2's is groupCol2$,
# and it is groupCol2$ whether or not run 1 had a grouping column and whether
# or not the two name the same column. Every case below is a session whose
# run structure is fixed by the driver, so the block it produces can be
# compared against the names the ruling says it must have -- exactly those
# names, with exactly those runs, and no others.
#
# WHY THE RUN STRUCTURE IS DECLARED AND NOT DETECTED. A driver is a script
# scope, and a script scope is only half a run boundary: a wrapper's `New` and
# the graphs form's `Redraw` are second passes inside ONE scope. So each case
# body marks its own boundaries with @emlRecordNewRun exactly where a form
# would, and the case is then a session whose run count this file knows and
# validate/v87 can assert against.
#
# `callsite` IS THE ONE CASE THAT DOES NOT DO THAT, and it is here because a
# driver standing in for a form proves the naming and proves nothing about the
# form. It never calls @emlRecordNewRun. It calls @emlHandleCommonFields --
# the procedure every menu wrapper runs once per press of Run, inside its own
# `repeat ... until allDone` loop -- twice in one script scope, which is what
# a wrapper's `New` button does. Two runs come back or the boundary is not
# where the plugin says it is.
#
# WHAT IS COMPARED, AND WHY IT IS `cmp`. Every draw step is replayed ALONE --
# the emitted file carries no `Erase all` between steps, so running it whole
# superimposes every figure on one picture -- into a 300-dpi PNG, and compared
# byte for byte with the PNG the recording itself drew. None of these figures
# jitters, so nothing needs seeding and no threshold is needed: a replayed
# figure is the same file or it is a defect.
#
# THE TWO EDIT LEGS ARE THE POINT OF THE WHOLE BLOCK. `sametable` changes ONE
# line -- data2$ -- and requires run 2 to move to the twin table and run 1 to
# stay exactly where it was drawn. `axisedit` changes ONE line -- run 1's
# axisYMax -- on two runs that were drawn on the SAME typed axis literals, and
# requires run 1 to move and run 2 not to. Neither edit is available at all if
# the two runs share a variable, which is what makes them measurements of the
# ruling rather than of the file's spelling.
#
# THE HEAD BASELINE. `single` -- one draw and the save that belongs to it -- is
# driven twice: once against the tree under test and once against a plugin
# built with `git archive HEAD`. The two blocks are kept side by side so
# validate/v87 can require that the ordinary one-pass session is unchanged.
# The HEAD build is deliberately NOT redirected by EML_RUNBLOCK_SRC: it is the
# baseline, and a baseline that moves with the break test measures nothing.
#
# Environment:
#   EML_RUNBLOCK_SRC   plugin directory to drive       (default: ROOT/plugin)
#   EML_RUNBLOCK_OUT   where artefacts go              (default: HERE/out)
#
# Output: out/<case>/emitted.praat          the recorded script
#         out/<case>/ORIG_step<N>.png       what the recording drew
#         out/<case>/REPLAY_step<N>.png     what the emitted script draws
#         out/<case>/RESULT.tsv             key<TAB>value, read by v87
#         out/head_single/emitted.praat     the same one-pass session at HEAD
#         out/RUNBLOCK.tsv                  every case's keys in one file
#         out/BREAKS.tsv, out/breaks/       written by break.sh, kept by this
#                                           script rather than rebuilt
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ---------------------------------------------------------------------------
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
SRC="${EML_RUNBLOCK_SRC:-$ROOT/plugin}"
OUT="${EML_RUNBLOCK_OUT:-$HERE/out}"
PRAAT=/usr/bin/praat
PREFS="$OUT/prefs"

# EVERYTHING THIS RIG WRITES IS REBUILT, EXCEPT THE RED-WATCH EVIDENCE.
# out/breaks and out/BREAKS.tsv are written by break.sh and are the record of
# each check having been SEEN to fail; a re-drive that deleted them would
# leave the validator claiming a break test it could no longer show.
mkdir -p "$OUT"
find "$OUT" -mindepth 1 -maxdepth 1 \
    ! -name breaks ! -name BREAKS.tsv -exec rm -rf {} +
mkdir -p "$OUT" "$PREFS"

# One Praat per script. --pref-dir keeps the driving user's own Praat
# preferences out of it, and the timeout keeps a stuck Praat from taking the
# rig with it.
run_praat () {  # run_praat <script> <log>
    ( cd "$ROOT" && HOME="$(dirname "$ROOT")" timeout 300 "$PRAAT" \
        --pref-dir="$PREFS" --run "$1" >>"$2" 2>&1 )
}

includes () {   # includes <plugindir>
    local p="$1"
    for f in stats/eml-core-utilities stats/eml-core-descriptive \
             stats/eml-extract stats/eml-output stats/eml-inferential \
             stats/eml-result-writer stats/eml-record \
             graphs/eml-graph-procedures graphs/eml-annotation-procedures \
             graphs/eml-draw-procedures stats/eml-analysis ; do
        echo "include $p/$f.praat"
    done
}

# ---------------------------------------------------------------------------
# RECORD ONE CASE.  The case body is include-free; the preamble below is what
# a menu command would have around it, and @@D@@ in the body is the case's own
# output directory.
# ---------------------------------------------------------------------------
record_case () {    # record_case <case> <plugindir> <destdir>
    local case="$1" plug="$2" d="$3"
    local c="$HERE/cases/$case"
    mkdir -p "$d"
    {
        includes "$plug"
        echo 'Text writing preferences: "UTF-8"'
        echo '@emlInitDrawingDefaults'
        echo '@emlClearAnnotations'
        echo '@emlRecordInit'
        echo "emlRecordPluginRoot\$ = \"$plug\""
        echo '@emlRecordBegin: ""'
        echo "emlRecordPluginRoot\$ = \"$plug\""
        echo "@emlRecordLoadPhrases: \"$plug/data/eml-record-phrases.csv\""
        echo "include $c/fixture.praat"
        sed "s#@@D@@#$d#g" "$c/body.praat"
        echo "@emlRecordFlush: \"$d/emitted.praat\""
        echo '@emlRecordDiscard'
        # THE REFERENCE FIGURES ARE DRAWN AFTER THE DISCARD, so they are not
        # steps. They are what an edited block is supposed to come back as.
        if [ -f "$c/ref.praat" ]; then
            sed "s#@@D@@#$d#g" "$c/ref.praat"
        fi
    } > "$d/record.praat"
    : > "$d/record.log"
    run_praat "$d/record.praat" "$d/record.log"
}

# ---------------------------------------------------------------------------
# CUT AN EMITTED SCRIPT AT ITS OWN STEP HEADINGS. Everything above the first
# heading is the prefix -- the include block and the editable block -- and
# each heading to the next is one step's body.
# ---------------------------------------------------------------------------
split_emitted () {  # split_emitted <emitted> <cutdir>
    python3 "$HERE/split.py" "$1" "$2"
}

replay_step () {    # replay_step <cut> <fixture> <stepN> <png> <log>
    local cut="$1" fix="$2" n="$3" png="$4" log="$5"
    local s="$cut/replay_step_$n.praat"
    cat "$cut/prefix.praat" > "$s"
    cat "$fix" >> "$s"
    echo 'Erase all' >> "$s"
    cat "$cut/step_$n.body" >> "$s"
    echo '@emlAssertFullViewport' >> "$s"
    echo "Save as 300-dpi PNG file: \"$png\"" >> "$s"
    run_praat "$s" "$log"
}

replay_run () {     # replay_run <cut> <fixture> <tag> <log> <stepN>...
    local cut="$1" fix="$2" tag="$3" log="$4"; shift 4
    local s="$cut/replay_run_$tag.praat"
    cat "$cut/prefix.praat" > "$s"
    cat "$fix" >> "$s"
    echo 'Erase all' >> "$s"
    local n
    for n in "$@"; do cat "$cut/step_$n.body" >> "$s"; done
    run_praat "$s" "$log"
}

emit () {   # emit <case> <key> <value>
    printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$OUT/RUNBLOCK.tsv"
}

# COMPARE AND RECORD THE ANSWER AS A WORD, not as an exit status, so the TSV
# says which way it went and a missing file cannot read as a pass.
cmp_key () {    # cmp_key <case> <key> <a> <b>
    local case="$1" key="$2" a="$3" b="$4"
    if [ ! -s "$a" ] || [ ! -s "$b" ]; then
        emit "$case" "$key" "MISSING"
    elif cmp -s "$a" "$b"; then
        emit "$case" "$key" "IDENTICAL"
    else
        emit "$case" "$key" "DIFFERS"
    fi
}

printf 'case\tkey\tvalue\n' > "$OUT/RUNBLOCK.tsv"

# WHICH RECORDER THESE ARTEFACTS DESCRIBE. The emitted blocks below are
# committed and read back by validate/v87 long after this run, and a committed
# artefact goes on saying what it said after the code stops doing it. So the
# recorder's own fingerprint is written into the transcript and v87 compares it
# with the file in the tree it is validating: edit eml-record.praat without
# re-driving this harness and v87 says so instead of passing on yesterday's
# answer. It is the WORKING TREE's copy that is fingerprinted, not
# EML_RUNBLOCK_SRC's, because the break rig damages a copy and leaves the tree
# alone -- so a break shows up as the naming failing, never as a stale rig.
emit meta record_sha \
    "$(sha256sum "$ROOT/plugin/stats/eml-record.praat" | cut -c1-16)"

# ---------------------------------------------------------------------------
# THE CASES
# ---------------------------------------------------------------------------
for case in twotables onlyrun2 three single sametable twosaves saveruns \
            axisedit callsite ; do
    d="$OUT/$case"
    c="$HERE/cases/$case"
    echo "== $case"
    record_case "$case" "$SRC" "$d"
    if [ ! -s "$d/emitted.praat" ]; then
        emit "$case" "recorded" "0"
        echo "   NO EMITTED FILE -- see $d/record.log"
        continue
    fi
    emit "$case" "recorded" "1"
    split_emitted "$d/emitted.praat" "$d/cut" > "$d/steps.txt"
    : > "$d/replay.log"
    while read -r n kind; do
        emit "$case" "step${n}_kind" "$kind"
        if [ "$kind" = "draw" ]; then
            replay_step "$d/cut" "$c/fixture.praat" "$n" \
                "$d/REPLAY_step$n.png" "$d/replay.log"
            cmp_key "$case" "step${n}_replay" \
                "$d/REPLAY_step$n.png" "$d/ORIG_step$n.png"
        fi
    done < "$d/steps.txt"
    emit "$case" "replay_aborts" \
        "$(grep -c 'not performed or completed' "$d/replay.log")"
    emit "$case" "record_aborts" \
        "$(grep -c 'not performed or completed' "$d/record.log")"
    # Whole runs, for the cases that saved: a save step needs a figure on the
    # page, so its own run's steps are replayed together.
    if [ -f "$c/runs.txt" ]; then
        while read -r tag steps; do
            replay_run "$d/cut" "$c/fixture.praat" "$tag" \
                "$d/replay.log" $steps
        done < "$c/runs.txt"
        # WHAT EACH SAVE ACTUALLY WROTE. The recording never ran the panel --
        # it recorded the call -- so everything in these folders was written
        # by the REPLAY, reading its own save's format variable. A save that
        # replayed another save's choice shows up here as the wrong set of
        # extensions, which no reading of the emitted text can tell you.
        for sd in "$d"/saved*; do
            [ -d "$sd" ] || continue
            emit "$case" "$(basename "$sd")_exts" \
                "$(ls "$sd" | sed -n 's/.*\.\([a-z]*\)$/\1/p' | sort -u \
                   | tr '\n' ',' | sed 's/,$//')"
        done
    fi
done

# ---------------------------------------------------------------------------
# THE HEAD BASELINE for the one-pass session.
# ---------------------------------------------------------------------------
echo "== head_single"
HEADTREE="$OUT/head_tree"
mkdir -p "$HEADTREE"
# THE PATHSPEC IS THE REAL FOLDER. `plugin` beside it is a symlink to
# plugin_EML_StatsGraphs, and a git pathspec does not go through one: `git
# archive HEAD plugin` exports the 22-byte link and nothing else, so the tar
# would unpack a dangling name and this leg would record nothing while
# exiting 0. Filesystem paths resolve through the symlink; git's do not.
( cd "$ROOT" && git archive HEAD plugin_EML_StatsGraphs ) | tar -x -C "$HEADTREE"
if [ -f "$HEADTREE/plugin_EML_StatsGraphs/stats/eml-record.praat" ]; then
    record_case single "$HEADTREE/plugin_EML_StatsGraphs" "$OUT/head_single"
    if [ -s "$OUT/head_single/emitted.praat" ]; then
        emit head_single recorded 1
    else
        emit head_single recorded 0
    fi
else
    emit head_single recorded 0
fi

# ---------------------------------------------------------------------------
# THE EDIT LEGS
# ---------------------------------------------------------------------------
echo "== sametable retarget"
d="$OUT/sametable"; c="$HERE/cases/sametable"
if [ -s "$d/emitted.praat" ]; then
    cp -r "$d/cut" "$d/cut_edit"
    before="$(md5sum < "$d/cut_edit/prefix.praat")"
    sed -i 's/^data2\$ = "Table one"/data2$ = "Table twin"/' \
        "$d/cut_edit/prefix.praat"
    after="$(md5sum < "$d/cut_edit/prefix.praat")"
    # HOW MANY LINES THE EDIT TOUCHED, counted rather than claimed: a sed that
    # matched nothing and a sed that rewrote the file both have to be visible.
    emit sametable edit_lines_changed \
        "$(diff <(cat "$d/cut/prefix.praat") <(cat "$d/cut_edit/prefix.praat") \
            | grep -c '^>')"
    : > "$d/edit_replay.log"
    for n in 1 2; do
        replay_step "$d/cut_edit" "$c/fixture.praat" "$n" \
            "$d/EDIT_step$n.png" "$d/edit_replay.log"
    done
    cmp_key sametable edit_run1_vs_orig "$d/EDIT_step1.png" "$d/ORIG_step1.png"
    cmp_key sametable edit_run2_vs_orig "$d/EDIT_step2.png" "$d/ORIG_step2.png"
    cmp_key sametable edit_run2_vs_twin "$d/EDIT_step2.png" "$d/REF_twin.png"
    emit sametable edit_aborts \
        "$(grep -c 'not performed or completed' "$d/edit_replay.log")"
fi

echo "== axisedit run-1 axis edit"
d="$OUT/axisedit"; c="$HERE/cases/axisedit"
if [ -s "$d/emitted.praat" ]; then
    cp -r "$d/cut" "$d/cut_edit"
    # RUN 1'S CEILING ONLY. The line is matched on the variable name at the
    # start of the line, so axisYMax2 cannot be hit by accident.
    sed -i -E 's/^axisYMax([[:space:]]+)= 30/axisYMax\1= 60/' \
        "$d/cut_edit/prefix.praat"
    emit axisedit edit_lines_changed \
        "$(diff <(cat "$d/cut/prefix.praat") <(cat "$d/cut_edit/prefix.praat") \
            | grep -c '^>')"
    : > "$d/edit_replay.log"
    for n in 1 2; do
        replay_step "$d/cut_edit" "$c/fixture.praat" "$n" \
            "$d/EDIT_step$n.png" "$d/edit_replay.log"
    done
    cmp_key axisedit edit_run1_vs_orig "$d/EDIT_step1.png" "$d/ORIG_step1.png"
    cmp_key axisedit edit_run1_vs_wide "$d/EDIT_step1.png" "$d/REF_wide.png"
    cmp_key axisedit edit_run2_vs_orig "$d/EDIT_step2.png" "$d/ORIG_step2.png"
    emit axisedit edit_aborts \
        "$(grep -c 'not performed or completed' "$d/edit_replay.log")"
fi

# THE HEAD BUILD AND THE PRAAT PREFERENCES GO. The first is 4 MB of a tree
# git already has and can rebuild in a second; the second is Praat's own
# scratch. What stays is what v87 reads and what a reader would want to see:
# the emitted scripts, the figures, and the transcript.
rm -rf "$HEADTREE" "$PREFS"

echo "runblock: done"
cut -f1,2,3 "$OUT/RUNBLOCK.tsv"
