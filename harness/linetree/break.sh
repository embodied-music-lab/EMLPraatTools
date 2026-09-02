#!/usr/bin/env bash
# ============================================================================
# harness/linetree/break.sh — nothing is validated until it has been broken
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Every break is a COPY of the repository under /tmp with ONE deliberate
# defect in it, driven through the copy's own harness by run.sh's $EML_LT_SRC
# and $EML_LT_OUTDIR seams, and scored by running validate/v97_line_tree.R
# against the copy's artefact through $EML_LT_DIR and $EML_LT_SRC. THE WORKING
# TREE IS NEVER EDITED, which is the point: a break test that patches the tree
# and puts it back is one interrupted run away from committing a defect.
#
# EACH DEFECT IS ONE THE QUESTION TREE WAS BUILT TO MAKE IMPOSSIBLE. They are
# not invented failures; every one of them is the state of this form before the
# line-chart change order, before the 19 August repairs, or before the long
# shape reached the right-hand axis -- restored one at a time.
#
#   key_grouped_only   -- D139 PUT BACK. The key is drawn only when the figure
#                         is grouped, which is the test that was there before:
#                         `.drawKey` loses its second-axis arm. The figure that
#                         needs a key most -- one ungrouped series on the left
#                         and a second measurement on the right -- goes out as
#                         two unlabelled lines on two scales.
#
#   right_col_free     -- D138 PUT BACK. The left-hand series stops being "the
#                         one you did not pick": `tsLeftPick = 3 - tsRightPick`
#                         becomes `tsLeftPick = tsRightPick`, so the same
#                         column is drawn on BOTH axes. That is the outcome
#                         D138 names, and it is mutated at the derivation
#                         rather than at the menu ON PURPOSE -- a mutation that
#                         re-opened the menu over every column would bite only
#                         if the plan happened to pick the colliding option,
#                         and a break whose bite depends on a plan's choice
#                         measures the plan.
#
#   no_third_refusal   -- the three-measurement refusal never fires. MEASURED
#                         on the driven copy: the meas3_refuse leg walks EML
#                         Graphs, the meaning question and the column page and
#                         arrives at Graph Complete -- no "Line chart" pause,
#                         no right-hand axis page -- with the Picture window at
#                         ink 0.00545 against its own empty baseline of
#                         0.000704. Three unlike quantities are accepted
#                         without a word and something is drawn for them.
#
#   ci_unconditional   -- the interval offer stops asking anything. The field
#                         is built on every visit, including the table with
#                         exactly one observation per time point, where there
#                         is nothing to average and no interval to draw.
#
#   gate_deaf          -- @emlSecondAxisGate's role refusal deleted, so a
#                         SCRIPTED right-axis request under role = subjects is
#                         honoured. The dialog cannot ask for this; the gate
#                         exists for the callers that have no dialog -- a
#                         recorded script edited by hand, the API export -- and
#                         script_refuse is the leg that stands in for them.
#
#   melt_ceiling_five  -- THE CEILING RESTORED, at the list the melt is fed.
#                         The page still builds one tickbox per numeric column
#                         and still reads all of them back; only the loop that
#                         collects the ticked names into tsSeriesCol$[] is
#                         capped at five. So the SEVEN-column dialog is
#                         unchanged on screen and five series reach the page --
#                         which is the shape the defect had, and which a check
#                         that counted tickboxes in a screenshot would miss.
#
#   name_menu_all_columns -- THE SERIES-NAME MENU BUILT OVER THE WHOLE TABLE
#                         again, which is where it was until 19 August. The
#                         menu's options, its seeded default, the key the
#                         repeat scan uses and the column that groups the draw
#                         all come off tsTxtName$[]; filling that from
#                         colName$[] rather than from the survey's text list
#                         restores every part of the defect at once. On
#                         time/f0/speaker the page then opens proposing to
#                         name the series after the TIME column, and the
#                         interval offer counts the 8 rows a time point has
#                         when it is not grouped instead of the 4 it has when
#                         it is.
#
# WHAT EACH BREAK IS SCORED ON. v97 asserts on all fifteen legs and refuses a
# transcript with fewer, so EVERY break drives the whole harness. A break that
# drove only the leg it expects to move would be scored against a validator
# complaining about the fourteen legs that were not there, and the first
# failing check -- the one this file reports -- would name a missing leg
# rather than the defect.
#
# THAT IS FIFTEEN LEGS AND THREE REPLAYS, thirteen minutes on a repaired tree
# and longer on a broken one, so the drive stage takes an optional leg list:
#
#   EML_LT_BREAK_STAGE=patch bash break.sh <name>
#   EML_LT_BREAK_STAGE=drive EML_LT_BREAK_LEGS="<legs>" bash break.sh <name>
#   ... repeated until every leg is driven ...
#   EML_LT_BREAK_STAGE=score bash break.sh <name>
#
# run.sh carries the legs a batch was not asked to drive over from the
# transcript already in that shadow's own out directory, and REFUSES to carry
# anything over from a transcript taken against different code -- so a batched
# drive produces exactly the artefact one drive would, and cannot be used to
# leave a stale leg in place. The batches the table below was measured with:
#
#   A  subjects4 subjects_ci meas2 meas2_rep script_refuse
#   B  meas3_refuse none_refuse seven long_meas2 long_meas3_refuse
#   C  long_titled wide_titled rec_subjects4 rec_meas2 rec_long_meas2
#
# A BREAK THAT SCORES red=0 IS A HOLE IN v97, NOT A PASS. It is printed as
# such at the console and left in the file as such; the defect is real by
# construction, so a green score means no check looks where it lives.
#
# WHAT THIS FILE MEASURED, 19 August 2026, against v97's 721 checks -- which
# are 721 green on the working tree, before and after this run. Every break
# was driven and scored on this rig on that date; nothing below is recalled.
#
#   pivot_dropped         red=89  first: [long_meas2] and returned by name
#   long_one_series       red=107 first: [long_meas2] and returned by name
#   level_refusal_gone    red=4   first: [long_meas3_refuse] which names the
#                                 column the three came from
#   key_grouped_only      red=13  first: [meas2] and the right-hand series is
#                                 tagged on the figure
#   right_col_free        red=8   first: while a figure with a named value
#                                 column still composes its own
#   no_third_refusal      red=27  first: [meas3_refuse] and returned by name
#   ci_unconditional      red=30  first: [meas2_rep] and the interval was NOT
#                                 offered, because two scales
#   gate_deaf             red=9   first: [script_refuse] and the refused arm
#                                 tags nothing
#   melt_ceiling_five     red=4   first: [seven] the form read all seven back
#   name_menu_all_columns red=100 first: [long_meas2] and returned by name
#   melt_step_dropped     red=19  first: [rec_subjects4] the melted figure
#                                 emitted two steps
#   role_not_emitted      red=9   first: the recorder emits emlSeriesRole$ in
#                                 front of the draw call
#   series_cols_not_lifted red=5  first: [rec_subjects4] the block declares
#                                 seriesCols$ = "S1,S2,S3,S4"
#
# NO BREAK CAME BACK GREEN. Two of them are loud and it is worth saying why:
# pivot_dropped and long_one_series both stop a leg RETURNING rather than
# changing what it draws. With the pivot falsified, pressing Draw on the
# right-hand axis page aborts inside `Get value:` -- the draw layer is handed
# the user's long table and told to read a column called "f0" that is not in
# it -- and with tsLevelMode falsified the right-hand axis page never opens,
# so three plans meet a dialog they have no step for and are killed. Both
# cascade across every check on the three long legs, which is honest: the
# feature is not degraded in those trees, it is absent.
#
# THE QUIET ONES ARE THE INFORMATIVE ONES. level_refusal_gone moves four
# checks and no more: the refusal still fires, with the COLUMN page's wording
# -- "untick columns until two are left", on a page that has one column and no
# tickboxes, naming no column at all. melt_ceiling_five moves the seven-series
# count, its seven hues, their stroke coverage and the static no-cap check.
# series_cols_not_lifted moves five checks and NO figure: its emitted script
# still runs and still replays byte-identically, which is exactly the defect
# -- the block stops being the whole form -- and exactly why section 15's
# by-name checks exist beside the md5.
#
# TWO COUNTS GREW WHEN THE LONG SHAPE LANDED, and they grew for a reason worth
# recording. name_menu_all_columns was 14 and is 100: the series-name menu is
# where a long table's SERIES come from now, not just how they are grouped, so
# defaulting it to the time column stops three legs reaching the right-hand
# axis at all. ci_unconditional was 15 and is 30, and no_third_refusal 26 and
# 27, because the extra field and the missing refusal shift the widget offsets
# and the page count on legs that did not exist before.
#
#   Run:  bash harness/linetree/break.sh [name-substring]
#   Out:  harness/linetree/out/BREAKS.tsv       break, red count, first failure
#         harness/linetree/out/break_<n>.v97.log  the whole score
#         /tmp/eml-linetree-breaks/<n>/         the patched copy and its drive
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
WORK="${TMPDIR:-/tmp}/eml-linetree-breaks"
FILTER="${1:-}"

mkdir -p "$OUT" "$WORK"
TSV="$OUT/BREAKS.tsv"
# TRUNCATED ONLY ON A FULL RUN. The filter argument exists so one break can be
# re-driven on its own -- each drive is seven minutes, so they are run one at a
# time -- and a filtered run that wiped the file would leave a BREAKS.tsv
# holding a single row and looking like a complete result.
[ -n "$FILTER" ] || : > "$TSV"

FORM=plugin_EML_StatsGraphs/graphs/eml-graphs-form.praat
GRAPH=plugin_EML_StatsGraphs/graphs/eml-graph-procedures.praat
DRAW=plugin_EML_StatsGraphs/graphs/eml-draw-procedures.praat
RECORD=plugin_EML_StatsGraphs/stats/eml-record.praat

# ---------------------------------------------------------------------------
# THE STAGE SEAM. $EML_LT_BREAK_STAGE = all (default) | patch | drive | score.
#
# WHY IT EXISTS. One break is a full drive of the harness -- ten legs and four
# replays -- and a BROKEN tree drives slower than a repaired one by
# construction, because a defect that removes a dialog spends run.sh's
# waitpause ceiling on every plan step that no longer matches. That is eight
# to fifteen minutes, and it is longer than some environments will let a
# single command run.
#
# The three stages are the three things this file does, and they are already
# separate in the code: patch a copy, drive it, score it. Splitting them costs
# nothing -- the shadow tree is on disk between stages and the drive's exit
# status is written beside its transcript -- and it means a break can be
# driven under a ceiling that a whole run would not fit under.
#
# `all` IS THE DEFAULT AND IS WHAT THE TABLE AT THE TOP WAS MEASURED WITH. A
# staged run and a whole run do exactly the same three things in the same
# order; nothing here is conditional on the stage except which of them happen.
# ---------------------------------------------------------------------------
STAGE="${EML_LT_BREAK_STAGE:-all}"
case "$STAGE" in
  all|patch|drive|score) ;;
  *) printf 'break.sh: EML_LT_BREAK_STAGE=%s is not one of all/patch/drive/score.\n' \
        "$STAGE" >&2; exit 1 ;;
esac
stage_do () { [ "$STAGE" = all ] && return 0; [ "$STAGE" = "$1" ] && return 0; return 1; }

# ---------------------------------------------------------------------------
# shadow <name> — a clean copy of the tree at $WORK/<name>, minus the heavy
# output folders. A break tree is not a repository and does not need to be.
# ---------------------------------------------------------------------------
shadow () {
    local n=$1
    stage_do patch || return 0
    rm -rf "${WORK:?}/$n"
    mkdir -p "$WORK/$n"
    tar -c --exclude=.git --exclude=evidence --exclude=harness/stress_out \
        --exclude=harness/linetree/out --exclude=harness/linestyle/out \
        --exclude=harness/secondaxis/out --exclude=harness/compose/out \
        --exclude=harness/legend/out --exclude=harness/axisrefuse/out \
        -C "$ROOT" . | tar -x -C "$WORK/$n"
    mkdir -p "$WORK/$n/harness/linetree/out"
}

# ---------------------------------------------------------------------------
# edit <name> <relative path> <<'PY' — one deliberate defect, applied by a
# python3 heredoc that ASSERTS ITS ANCHOR IS PRESENT BEFORE IT EDITS.
#
# A MUTATION THAT CHANGES NOTHING IS NOT A MUTATION. A sed that silently
# matched nothing leaves the break driving the CORRECT tree, and the green
# score that comes back is a green score for the repair -- the exact failure a
# break test exists to prevent. The assert stops the run; the digest check
# after it catches an edit that matched and wrote the same bytes back.
# ---------------------------------------------------------------------------
edit () {
    local n=$1 rel=$2
    # THE HEREDOC IS READ AND DISCARDED WHEN THIS IS NOT THE PATCH STAGE, which
    # is what a plain return does: the caller's `<<'PY'` is already attached to
    # this invocation's stdin, so nothing leaks into the next command.
    stage_do patch || return 0
    local f="$WORK/$n/$rel"
    local before after
    before=$(sha256sum "$f" | cut -d' ' -f1)
    python3 - "$f" || {
        printf 'BREAK %s: the anchor for %s was not found.\n' "$n" "$rel" >&2
        printf 'The mutation did not apply, so this run would measure the\n' >&2
        printf 'REPAIRED tree and report it as a break. Refusing.\n' >&2
        exit 1
    }
    after=$(sha256sum "$f" | cut -d' ' -f1)
    if [ "$before" = "$after" ]; then
        printf 'BREAK %s: %s is byte-identical after the edit. Not a break.\n' \
            "$n" "$rel" >&2
        exit 1
    fi
}

# ---------------------------------------------------------------------------
# run_break <name> — drive the copy's own harness and score v97 on it.
#
# THE DISPLAY IS NOT THE WORKING TREE'S. run.sh defaults to :120, which is the
# number the committed transcript was driven on; a break that shared it would
# read a re-drive's dialogs as its own.
#
# PRAAT IS PASSED THROUGH RATHER THAN RE-RESOLVED, for the reason
# harness/linetree/break.sh's predecessor recorded: the copy's _env.sh resolves
# from ITS OWN location, so the search falls through to whatever `praat` is on
# PATH, and the comparison would be between two builds rather than two forms.
# ---------------------------------------------------------------------------
run_break () {
    local n=$1
    local o="$WORK/$n/harness/linetree/out"
    mkdir -p "$o"
    # THE CEILING IS 900 SECONDS AND NOT THE REPAIRED TREE'S SIX MINUTES. A
    # BROKEN drive takes longer by construction: a defect that removes a dialog
    # or adds a field spends run.sh's 30-second waitpause ceiling on every plan
    # step that no longer matches. Measured on this rig: ci_unconditional, whose
    # extra field shifts the widget offsets the toggling legs count from the
    # end, was still driving at 500 seconds with two legs to go. A ceiling that
    # cuts a break off mid-run leaves NO transcript, which is scored below as no
    # result rather than as a red -- correct, but not a measurement of anything.
    # WHICH LEGS THIS INVOCATION DRIVES. Empty means all fifteen, which is
    # what a whole run does and what the table at the top was measured with.
    #
    # WHY IT IS A SEAM. A full drive of a BROKEN tree is fifteen legs and can
    # run past twenty minutes -- a defect that removes a dialog spends
    # run.sh's waitpause ceiling on every plan step that no longer matches --
    # and some environments will not let one command run that long. run.sh
    # carries the legs it was not asked to drive over from the transcript
    # already in this shadow's own out directory, and refuses to carry
    # anything over from a transcript taken against different code, so
    # driving a break in batches produces exactly the artefact one drive
    # would. The FIRST batch must start from an empty out directory, which
    # the patch stage guarantees.
    local drove
    if stage_do drive; then
        PRAAT="$PRAAT" EML_LT_SRC="$WORK/$n" EML_LT_OUTDIR="$o" \
            EML_LT_DISPLAY="${EML_LT_DISPLAY:-:121}" \
            timeout "${EML_LT_BREAK_TIMEOUT:-1200}" \
            bash "$WORK/$n/harness/linetree/run.sh" ${EML_LT_BREAK_LEGS:-} \
            > "$o/drive.log" 2>&1
        drove=$?
        # THE EXIT STATUS OUTLIVES THE STAGE, because the score stage reports
        # it and may run in a different shell.
        printf '%s\n' "$drove" > "$o/drive.status"
    fi
    stage_do score || return
    drove=$(cat "$o/drive.status" 2>/dev/null || echo "?")
    if [ ! -s "$o/LINETREE.tsv" ]; then
        # NO TRANSCRIPT IS NOT A SCORE. v97 would report one red -- "the
        # line-tree harness has been driven" -- and that number would sit in
        # the results file looking like a measurement of the defect.
        printf '%s\t%s\t%s\n' "$n" "NO-DRIVE" \
            "run.sh left no transcript (exit $drove); see $o/drive.log" >> "$TSV"
        printf '  %-18s !! NO TRANSCRIPT (exit %s) -- not scored\n' "$n" "$drove"
        return
    fi
    EML_VALIDATE_DIR="$ROOT/validate" \
    EML_LT_DIR="$o" EML_LT_SRC="$WORK/$n" \
        Rscript "$ROOT/validate/v97_line_tree.R" \
        > "$OUT/break_$n.v97.log" 2>&1
    local red first
    red=$(grep -c '^FAIL' "$OUT/break_$n.v97.log")
    first=$(grep -m1 '^FAIL' "$OUT/break_$n.v97.log" \
            | sed 's/^FAIL[[:space:]]*v97[[:space:]]*//; s/[[:space:]]*computed=.*$//' \
            | cut -c1-120)
    [ -n "$first" ] || first="(nothing went red)"
    # ONE ROW PER BREAK, however this file was reached. The truncation above
    # only happens on a full run, so re-driving one break appends beside the
    # row it replaces, and a file that can hold the same break twice can hold a
    # stale count beside a fresh one and read as a complete run.
    if [ -f "$TSV" ]; then
        grep -v "^$n	" "$TSV" > "$TSV.new" 2>/dev/null || : > "$TSV.new"
        mv "$TSV.new" "$TSV"
    fi
    printf '%s\t%s\t%s\n' "$n" "$red" "$first" >> "$TSV"
    printf '  %-18s red=%-4s %s\n' "$n" "$red" "$first"
    if [ "$red" -eq 0 ]; then
        printf '  %-18s !! THIS BREAK IS INVISIBLE TO v97. The defect is real\n' "$n"
        printf '  %-18s !! by construction, so no check looks where it lives.\n' ""
    fi
}

want () { [ -z "$FILTER" ] && return 0; case "$1" in *"$FILTER"*) return 0 ;; esac; return 1; }

# ---------------------------------------------------------------------------
# 1. D139 PUT BACK — THE KEY ONLY ON A GROUPED FIGURE
# ---------------------------------------------------------------------------
if want key_grouped_only; then
    shadow key_grouped_only
    edit key_grouped_only "$DRAW" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
anchor = ("    .drawKey = 0\n"
          "    if .hasGroup = 1\n"
          "        .drawKey = 1\n"
          "    endif\n"
          "    if .secondOn = 1\n"
          "        .drawKey = 1\n"
          "    endif\n")
assert s.count(anchor) == 1, "key_grouped_only anchor: %d" % s.count(anchor)
new = ("    .drawKey = 0\n"
       "    if .hasGroup = 1\n"
       "        .drawKey = 1\n"
       "    endif\n")
open(p, "w", encoding="utf-8").write(s.replace(anchor, new, 1))
PY
    run_break key_grouped_only
fi

# ---------------------------------------------------------------------------
# 2. D138 PUT BACK — THE SAME COLUMN ON BOTH AXES
# ---------------------------------------------------------------------------
if want right_col_free; then
    shadow right_col_free
    edit right_col_free "$FORM" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
anchor = "                                        tsLeftPick = 3 - tsRightPick\n"
assert s.count(anchor) == 1, "right_col_free anchor: %d" % s.count(anchor)
new = "                                        tsLeftPick = tsRightPick\n"
open(p, "w", encoding="utf-8").write(s.replace(anchor, new, 1))
PY
    run_break right_col_free
fi

# ---------------------------------------------------------------------------
# 3. THE THIRD MEASUREMENT ACCEPTED WITHOUT COMPLAINT
# ---------------------------------------------------------------------------
# The condition is falsified rather than the block deleted, so every word of
# the refusal -- the paragraph explaining it and the message itself -- stays in
# the file. A check that greps the source for the sentence reads it and calls
# the refusal present; only a driven leg can tell that it never appears.
if want no_third_refusal; then
    shadow no_third_refusal
    edit no_third_refusal "$FORM" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
anchor = "                            elsif tsSeriesRole = 2 and tsNSeries >= 3\n"
assert s.count(anchor) == 1, "no_third_refusal anchor: %d" % s.count(anchor)
new = "                            elsif 1 = 0\n"
open(p, "w", encoding="utf-8").write(s.replace(anchor, new, 1))
PY
    run_break no_third_refusal
fi

# ---------------------------------------------------------------------------
# 4. THE INTERVAL OFFERED WHERE THERE IS NOTHING TO AVERAGE
# ---------------------------------------------------------------------------
# tsCIOffer is set to 1 outright, which is both halves of the offer: the field
# is built on every visit AND read back on every press. Falsifying only the
# `if tsCIOffer = 1` in front of the `boolean:` would put the field on screen
# and leave its answer unread, which is a second defect on top of this one.
if want ci_unconditional; then
    shadow ci_unconditional
    edit ci_unconditional "$FORM" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
anchor = ("                    tsCIOffer = 0\n"
          "                    if tsRepeatsFound = 1\n"
          "                        if tsSeriesRole = 1\n"
          "                            tsCIOffer = 1\n"
          "                        endif\n"
          "                    endif\n")
assert s.count(anchor) == 1, "ci_unconditional anchor: %d" % s.count(anchor)
new = "                    tsCIOffer = 1\n"
open(p, "w", encoding="utf-8").write(s.replace(anchor, new, 1))
PY
    run_break ci_unconditional
fi

# ---------------------------------------------------------------------------
# 5. THE GATE THAT NO LONGER HEARS WHAT THE SERIES MEAN
# ---------------------------------------------------------------------------
if want gate_deaf; then
    shadow gate_deaf
    edit gate_deaf "$GRAPH" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
anchor = ("    .roleRefused = 0\n"
          "    if .asked = 1\n"
          "        if variableExists (\"emlSeriesRole$\")\n"
          "            if emlSeriesRole$ = \"subjects\"\n"
          "                .roleRefused = 1\n"
          "            endif\n"
          "        endif\n"
          "    endif\n")
assert s.count(anchor) == 1, "gate_deaf anchor: %d" % s.count(anchor)
new = "    .roleRefused = 0\n"
open(p, "w", encoding="utf-8").write(s.replace(anchor, new, 1))
PY
    run_break gate_deaf
fi

# ---------------------------------------------------------------------------
# 6. THE CEILING RESTORED, AT THE LIST THE MELT IS FED
# ---------------------------------------------------------------------------
if want melt_ceiling_five; then
    shadow melt_ceiling_five
    edit melt_ceiling_five "$FORM" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
# THE COLLECTING LOOP AND NOT ONE OF THE OTHER THREE. `for iN from 1 to
# tsNNum` appears four times on this page -- building the names, seeding the
# ticks, building the tickboxes, reading them back -- and the one that decides
# how many series reach the melt is the one directly above `if tsTick[iN] = 1`.
anchor = ("                        if tsShape = 1\n"
          "                            for iN from 1 to tsNNum\n"
          "                                if tsTick[iN] = 1\n")
assert s.count(anchor) == 1, "melt_ceiling_five anchor: %d" % s.count(anchor)
new = ("                        if tsShape = 1\n"
       "                            for iN from 1 to min (5, tsNNum)\n"
       "                                if tsTick[iN] = 1\n")
open(p, "w", encoding="utf-8").write(s.replace(anchor, new, 1))
PY
    run_break melt_ceiling_five
fi

# ---------------------------------------------------------------------------
# 7. THE SERIES-NAME MENU BUILT OVER EVERY COLUMN AGAIN
# ---------------------------------------------------------------------------
# THE DEFECT THIS RESTORES IS NOT "AN UNTIDY MENU". "Series names come from"
# used to be built over the whole table and seeded from @emlGuessColumnRoles,
# whose answer on a time/f0/speaker table is the TIME column. So the shape-2
# page opened proposing to name each series after the horizontal axis; the
# repeat scan keyed itself on that proposal, and the interval offer counted 8
# observations a point where the grouping the user wants has 4. Nothing on the
# page refuses it and nothing can: naming the series after the time column is
# a legal answer to the wrong question, and the number in the interval label
# -- the one number on that page a user would check -- agreed with it.
#
# MUTATED AT THE LIST, NOT AT THE MENU. tsTxtName$[] is what the option loop
# iterates, what the default's arithmetic indexes, what the repeat scan keys
# on, and what becomes groupColName$ at the draw. Filling it from colName$[]
# rather than from the survey's text columns puts every column back on the
# menu AND keeps all four of those in agreement -- which is what the defect
# looked like. Falsifying only the option loop would leave a menu offering
# columns whose choice indexed a different list, which is a second defect.
if want name_menu_all_columns; then
    shadow name_menu_all_columns
    edit name_menu_all_columns "$FORM" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
anchor = ("                    tsNNum = emlLineTreeColumns.nNumeric\n"
          "                    tsNTxt = emlLineTreeColumns.nText\n"
          "                    for iN from 1 to tsNNum\n"
          "                        tsNumName$[iN] = emlLineTreeColumns.numericName'iN'$\n"
          "                    endfor\n"
          "                    for iT from 1 to tsNTxt\n"
          "                        tsTxtName$[iT] = emlLineTreeColumns.textName'iT'$\n"
          "                    endfor\n")
assert s.count(anchor) == 1, "name_menu_all_columns anchor: %d" % s.count(anchor)
new = ("                    tsNNum = emlLineTreeColumns.nNumeric\n"
       "                    tsNTxt = nCols\n"
       "                    for iN from 1 to tsNNum\n"
       "                        tsNumName$[iN] = emlLineTreeColumns.numericName'iN'$\n"
       "                    endfor\n"
       "                    for iT from 1 to tsNTxt\n"
       "                        tsTxtName$[iT] = colName$[iT]\n"
       "                    endfor\n")
open(p, "w", encoding="utf-8").write(s.replace(anchor, new, 1))
PY
    run_break name_menu_all_columns
fi

# ---------------------------------------------------------------------------
# 8. THE MELT STOPS BEING A STEP -- the recorder is not told about it
# ---------------------------------------------------------------------------
# THE STATE OF THE TREE ON THE MORNING OF 19 AUGUST, restored. The form melts
# and says nothing to the recorder, so the only thing the recorder sees is the
# draw -- on the melt table, which the form removes moments later. The emitted
# file's manifest goes back to naming `Table eml_melt`, and replaying it stops
# at « Error: No object with name "Table eml_melt". » with no figure at all.
#
# THE @emlRecordConvert CALL IS THE ANCHOR AND NOTHING ELSE MOVES. The melt
# still happens, the figure the session draws is unchanged, and the eight
# non-recording legs are untouched: what is broken is the WRITING DOWN, which
# is exactly the thing section 15 is about and the thing nothing measured
# before it existed.
if want melt_step_dropped; then
    shadow melt_step_dropped
    edit melt_step_dropped "$FORM" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
head = "                                if variableExists (\"emlRecordLoaded\")\n"
mark = "                                        tsMeltCode$ = \"@emlReshapeSeriesLong: data, \"\"\"\n"
assert s.count(mark) == 1, "melt_step_dropped mark: %d" % s.count(mark)
start = s.rindex(head, 0, s.index(mark))
tailmark = ("                                    endif\n"
            "                                endif\n"
            "\n"
            "                                objectId = tsMeltTableId\n")
end = s.index(tailmark, start)
new = "                                objectId = tsMeltTableId\n"
open(p, "w", encoding="utf-8").write(s[:start] + new + s[end + len(tailmark):])
PY
    run_break melt_step_dropped
fi

# ---------------------------------------------------------------------------
# 9. seriesRole$ IS NOT EMITTED -- the meaning does not reach the file
# ---------------------------------------------------------------------------
# @emlRecordCaptureSeriesPens stops writing emlSeriesRole$ in front of the
# draw call, so the emitted block loses the line SPEC section 8 puts first and
# the replayed step runs with whatever role the process happens to hold.
#
# WHY IT IS BROKEN IN THE RECORDER AND NOT IN THE FORM. The form still SETS
# emlSeriesRole$ -- @emlSecondAxisGate reads it, and breaking that is what the
# gate_deaf break already does. This one breaks only the carrying, which is
# the recorder's own job and the one nothing looked at.
if want role_not_emitted; then
    shadow role_not_emitted
    edit role_not_emitted "$RECORD" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
anchor = ("    if variableExists (\"emlSeriesRole$\")\n"
          "        if emlSeriesRole$ <> \"\"\n"
          "            .out$ = .out$ + \"emlSeriesRole$ = \"\"\" + emlSeriesRole$ + \"\"\"\"\n"
          "            ... + newline$\n"
          "        endif\n"
          "    endif\n")
assert s.count(anchor) == 1, "role_not_emitted anchor: %d" % s.count(anchor)
open(p, "w", encoding="utf-8").write(s.replace(anchor, "", 1))
PY
    run_break role_not_emitted
fi

# ---------------------------------------------------------------------------
# 10. THE MELT'S COLUMNS ARE NOT LIFTED -- the block stops being the whole form
# ---------------------------------------------------------------------------
# @emlRecordColumnSpec loses its entry for @emlReshapeSeriesLong, so the melt
# step keeps its two literals inline. THE FILE STILL RUNS AND THE REPLAY IS
# STILL BYTE-IDENTICAL -- which is the point of this break, and why it is
# worth having beside the other two. The defect is not in what is drawn; it is
# that seriesCols$ and the melt's time column are no longer in the editable
# block, so the block's promise -- "nothing below this names an object, a
# column or an axis range" -- is false, and a user retargeting the workflow
# edits timeCol$ at the top and gets a melt still keyed on last month's.
#
# A break that only a PNG could see would be invisible here. That is what
# section 15's by-name checks are for.
if want series_cols_not_lifted; then
    shadow series_cols_not_lifted
    edit series_cols_not_lifted "$RECORD" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
anchor = ("    elsif .proc$ = \"emlReshapeSeriesLong\"\n"
          "        .spec$ = \"2=timeCol 3=seriesCols\"\n")
assert s.count(anchor) == 1, "series_cols_not_lifted anchor: %d" % s.count(anchor)
new = ("    elsif .proc$ = \"emlReshapeSeriesLong\"\n"
       "        .spec$ = \"\"\n")
open(p, "w", encoding="utf-8").write(s.replace(anchor, new, 1))
PY
    run_break series_cols_not_lifted
fi

# ---------------------------------------------------------------------------
# 11. THE PIVOT DROPPED -- the long table reaches the draw layer unspread
# ---------------------------------------------------------------------------
# The question tree still concludes everything it concludes: the answer is
# "different measurements", the levels are counted, the right-hand axis page is
# shown and answered, valueColName$ and tsSecondColName$ are set to the two
# LEVEL names. Only the transform is falsified, so the drawing layer is handed
# the user's own long table and told to read a column called "f0" that is not
# in it.
#
# WHY THE CONDITION AND NOT THE CALL. Deleting @emlReshapeSeriesWide would be a
# parse error the moment the branch ran; falsifying the guard leaves every line
# of the pivot, its recording and its cleanup in the file, so a check that
# greps the source for the call reads it and calls the pivot present. Only a
# driven leg can tell that the table was never spread.
if want pivot_dropped; then
    shadow pivot_dropped
    edit pivot_dropped "$FORM" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
anchor = "                                if allFormsDone = 1 and tsLevelMode = 1\n"
assert s.count(anchor) == 1, "pivot_dropped anchor: %d" % s.count(anchor)
new = "                                if 1 = 0\n"
open(p, "w", encoding="utf-8").write(s.replace(anchor, new, 1))
PY
    run_break pivot_dropped
fi

# ---------------------------------------------------------------------------
# 12. THE LEVEL REFUSAL REMOVED -- three levels get the column page's message
# ---------------------------------------------------------------------------
# The branch that refuses three LEVELS is falsified, so three stacked
# measurements fall through to the branch that refuses three COLUMNS. A refusal
# still appears, which is what makes this break worth having: the count is
# right and the advice is not. The message tells the user to "untick columns
# until two are left" on a page that has one column and no tickboxes, and names
# no column at all -- so a reader cannot tell where the three came from.
#
# A REFUSAL NOBODY CAN ACT ON READS AS ADVICE WHILE BEING NONE, which is the
# argument the wrapped-comment repair already makes on this same dialog. A
# check that only asked whether a refusal appeared would pass this.
if want level_refusal_gone; then
    shadow level_refusal_gone
    edit level_refusal_gone "$FORM" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
anchor = "                            if tsLevelMode = 1 and tsNSeries >= 3\n"
assert s.count(anchor) == 1, "level_refusal_gone anchor: %d" % s.count(anchor)
new = "                            if 1 = 0\n"
open(p, "w", encoding="utf-8").write(s.replace(anchor, new, 1))
PY
    run_break level_refusal_gone
fi

# ---------------------------------------------------------------------------
# 13. THE LONG BRANCH FALLS BACK TO ONE SERIES -- the state before the pivot
# ---------------------------------------------------------------------------
# THIS IS THE DEFECT THE PIVOT WAS BUILT FOR, RESTORED. tsLevelMode never turns
# on, so "different measurements" on a long table counts NUMERIC COLUMNS as it
# did before 19 August, finds one, and draws it as a single series grouped by
# the name column: every level on one shared vertical axis, no right-hand axis
# page, and -- on the three-level fixture -- three unlike quantities normalised
# onto one scale without a word, which is exactly the figure the wide path
# refuses to draw.
#
# MEASURED ON THE UNPATCHED FORM, 19 August 2026, before any of this was built:
# long_meas2 walked EML Graphs, the meaning question and the column page and
# arrived at Graph Complete. No right-hand axis page and no refusal.
if want long_one_series; then
    shadow long_one_series
    edit long_one_series "$FORM" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
anchor = "                                if emlCountGroups.nGroups >= 2\n"
assert s.count(anchor) == 1, "long_one_series anchor: %d" % s.count(anchor)
new = "                                if 1 = 0\n"
open(p, "w", encoding="utf-8").write(s.replace(anchor, new, 1))
PY
    run_break long_one_series
fi

echo "BREAKS.tsv:"
cat "$TSV"
