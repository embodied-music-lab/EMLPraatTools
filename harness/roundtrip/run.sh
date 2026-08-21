#!/usr/bin/env bash
# ============================================================================
# harness/roundtrip/run.sh — one session, six user actions, one recording,
#                            and what the emitted script says about each
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# THE QUESTION. A user switches recording on, makes a table, opens a CSV,
# fixes a cell, runs an ANOVA, draws a violin and presses Save. What is in the
# file they get? Not "does the recorder work" — harness/record_e2e counts
# which operations reach the buffer — but: of the six things this person did,
# which ones does the emitted script contain, and what does it say about the
# ones it does not?
#
# Nothing in the tree asked that before. harness/record/roundtrip.sh records
# ONE analysis; roundtrip_graph.sh records ONE figure; harness/record_e2e
# drives 38 operations but only operations that already call the recorder.
# The actions a user takes BETWEEN those operations — making the data,
# loading it, editing it — had never been in a recording session at all, and
# whether the emitted script can stand on its own depends entirely on them.
#
# ONE PRAAT PROCESS, because a recording cannot span invocations
# (eml-record-start.praat's own header says so: `praat --run` is a fresh
# process per script). See drive.praat for the route each action takes.
#
# ---------------------------------------------------------------------------
# THE DIALOG PROBLEM, AND THE TWO THINGS THIS HARNESS DOES ABOUT IT
# ---------------------------------------------------------------------------
# `beginPause:` cannot be scripted — under `praat --run` it takes the process
# down with a Trace/breakpoint trap. Four of the six actions live behind one.
#
# (a) THREE OF THEM ARE DRIVEN AS HEADLESS TWINS, by harness/edittable's
#     technique, generalised. Every `beginPause:`…`endPause` region in the
#     driven range is located MECHANICALLY, replaced by a call to a generated
#     `@dlg_<prefix>N` that assigns exactly the variables that stanza's fields
#     would have assigned plus the button pressed, and the shipped file MINUS
#     those regions is hashed against the twin MINUS the injected lines. The
#     hashes are in the TSV; a mismatch fails the run. out/EXCISED_*.txt holds
#     every removed byte. Everything between the dialogs is shipped bytes,
#     running:
#
#       eml-create-demo.praat        1 stanza   (whole file)
#       eml-edit-table.praat        22 stanzas  (whole file)
#       eml-compare-k-groups.praat   2 stanzas  (whole file)
#       eml-output.praat             5 stanzas  (@emlSavePanel only — see below)
#
#     THE RANGE ON eml-output.praat IS NOT A SHORTCUT, IT IS A REFUSAL.
#     That file has a sixth stanza, in @emlErrorDialog, whose region contains
#     TWO `endPause` lines on opposite arms of an `if`. Excising it
#     mechanically would cut through the middle of a conditional and leave a
#     twin that is not the file. The rule this harness applies is therefore
#     "excise the dialogs of the procedure being driven, and refuse any stanza
#     in that range holding more than one endPause" — the refusal is a hard
#     exit, and @emlErrorDialog is simply outside the range and untouched.
#
# (b) THE GRAPHS FORM IS NOT TWINNED, AND THAT IS THE ONE SUBSTITUTION IN
#     THIS RIG. graphs/eml-graphs-form.praat holds 40 stanzas across 10,033
#     lines with the acquire loop, the advanced pages and the post-draw loop
#     built out of them; a tape for that is a harness in its own right. What
#     is driven instead is the form's OWN draw chain — @emlGraphsPublish-
#     AxisRequest, @emlGraphsDrawWithLegendRoom — called at the wrapper's Draw
#     call site with the form's globals set as VALUES. That is exactly what
#     harness/formaxis and harness/record/replay.sh's LEGEND leg do, and for
#     the reason formaxis_drive.praat gives at length: the file is a library
#     (no `form:`, no `beginPause:` at top level), so an include gets every
#     procedure and no dialog, and driving the shipped procedure cannot drift
#     from the shipped procedure the way a transcription of it does.
#
#     SAID PLAINLY: the DRAWING is shipped code. The twenty-odd form globals
#     that a dialog would have filled in are set by this harness, and the
#     wrapper's `elsif clicked = 3` arm — which calls @emlGraphsWorkflow — is
#     bypassed in favour of the draw chain that arm eventually reaches.
#
# ---------------------------------------------------------------------------
# THE STAGE, AND WHY IT IS NOT plugin/scripts
# ---------------------------------------------------------------------------
# `include` resolves relative paths against the folder of the script that was
# RUN (measured again for this rig: a `runScript:`ed child resolves its own
# includes against the CHILD's folder, not the top-level's). harness/record_e2e
# answers that by staging its fixtures INTO plugin/scripts and removing them on
# a trap. This harness does not write into the plugin tree at all — a validator
# running concurrently in this working copy would see those files and report
# them, correctly and confusingly. Instead out/stage is a mirror:
#
#   out/stage/scripts/   a symlink per plugin/scripts/*.praat, plus the twins
#   out/stage/stats/     a symlink per plugin/stats/*.praat, except
#                        eml-output.praat, which is the twin
#   out/stage/graphs     symlink to plugin/graphs
#   out/stage/data       symlink to plugin/data
#   out/stage/sprites    symlink to plugin/sprites
#
# so `include eml-lib.praat` and its `include ../stats/…` chain resolve exactly
# as they do in an installed plugin, and the recorder's lazy phrase load
# (`../data/eml-record-phrases.csv`, relative to the run script's folder)
# resolves too. Whether it actually fired is measured, not assumed:
# emitted_missing_phrases counts `[MISSING PHRASE:` in the artefact.
#
# HOME IS PINNED ABOVE THE REPOSITORY, as in harness/record/replay.sh. The
# renderer rewrites the emitted include root home-relative and this rig points
# it at the working tree, so under the ambient HOME the rewrite cannot fire and
# the emitted header would disagree with its own paths.
#
# ---------------------------------------------------------------------------
# EVIDENCE
# ---------------------------------------------------------------------------
#   out/ROUNDTRIP.tsv   one key/value per line: for each action, whether it
#                       ran and what the emitted script contains for it
#   out/emitted.praat   the recorded script, as the user would receive it
#   out/drive.log       the Info window
#   out/saved/          what the Save press wrote
#   out/data/rt_input.csv   the adversarial input
#   out/EXCISED_*.txt   every byte cut to make each twin
#   out/MAP_*.tsv       the stanza map each twin was cut from
#
# NOT WIRED INTO validate/run_all.R, by instruction. Run it directly:
#
#   bash harness/roundtrip/run.sh
#
# Exit 0 = every twin matched its shipped body and the drive produced an
# emitted script. The CONTENT of that script is reported, not judged: this
# harness measures what the recorder covers, it does not decide what it ought
# to cover.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$SCRIPT_DIR/.." && pwd)/_env.sh" || exit 1

ROOT="$EML_ROOT"
PLUG="${EML_ROUNDTRIP_PLUGIN:-$ROOT/plugin}"
OUT="${EML_ROUNDTRIP_DIR:-$SCRIPT_DIR/out}"
PREFS="$SCRIPT_DIR/prefs"
STAGE="$OUT/stage"
WORK="$OUT/work"

rm -rf "$OUT"
mkdir -p "$OUT" "$PREFS" "$STAGE/scripts" "$STAGE/stats" "$WORK" \
         "$OUT/saved" "$OUT/data"

TSV="$OUT/ROUNDTRIP.tsv"
: > "$TSV"
say () { printf '%s\t%s\n' "$1" "$2" >> "$TSV"; }

die () { echo "roundtrip: FAIL — $*" >&2; exit 1; }

say praat_version   "$("$PRAAT" --version 2>&1 | head -1)"
say plugin_root     "$PLUG"
say harness_root    "$SCRIPT_DIR"
say record_stamp    "21 August 2026, 00:00:00"

# ===========================================================================
# 1. THE STAGE
# ===========================================================================
for f in "$PLUG"/scripts/*.praat; do
    ln -s "$f" "$STAGE/scripts/$(basename "$f")"
done
for f in "$PLUG"/stats/*.praat; do
    ln -s "$f" "$STAGE/stats/$(basename "$f")"
done
ln -s "$PLUG/graphs"  "$STAGE/graphs"
ln -s "$PLUG/data"    "$STAGE/data"
ln -s "$PLUG/sprites" "$STAGE/sprites"
say stage_scripts_linked "$(find "$STAGE/scripts" -maxdepth 1 -name '*.praat' | wc -l)"
say stage_stats_linked   "$(find "$STAGE/stats"   -maxdepth 1 -name '*.praat' | wc -l)"

# ===========================================================================
# 2. THE EXCISION — harness/edittable's technique, generalised
# ===========================================================================
# map_stanzas <src> <mapfile> [<from> <to>]
# One row per beginPause…endPause region: idx, start, end, begin-indent,
# end-indent, assignment target (or -), first quoted literal of the title.
# Fatal on a nested or unterminated stanza, and fatal on a region holding more
# than one endPause — see the note on @emlErrorDialog in the header.
map_stanzas () {
    local src="$1" mapf="$2" from="${3:-1}" to="${4:-999999}"
    awk -v FROM="$from" -v TO="$to" '
    function indent(s,   t) { t = s; sub(/[^ \t].*/, "", t); return length(t) }
    NR < FROM || NR > TO { next }
    /^[ \t]*beginPause: /{
        if (inb) { printf "nested beginPause at line %d\n", NR > "/dev/stderr"; exit 2 }
        inb = 1; start = NR; bi = indent($0); nend = 0
        title = ""
        if (match($0, /"[^"]*"/)) title = substr($0, RSTART + 1, RLENGTH - 2)
        next
    }
    inb && /endPause/{
        idx++
        tgt = "-"
        if (match($0, /^[ \t]*[A-Za-z_.][A-Za-z_0-9.]*[ \t]*=[ \t]*endPause/)) {
            tgt = $0; sub(/^[ \t]*/, "", tgt); sub(/[ \t]*=.*/, "", tgt)
        }
        printf "%d\t%d\t%d\t%d\t%d\t%s\t%s\n", idx, start, NR, bi, indent($0), tgt, title
        inb = 0
        next
    }
    END{
        if (inb) { printf "unterminated beginPause at line %d\n", start > "/dev/stderr"; exit 2 }
        if (idx == 0) { print "no pause stanzas found" > "/dev/stderr"; exit 2 }
    }
    ' "$src" > "$mapf" || return 1
    # A SECOND endPause INSIDE A REGION would mean the region boundaries are a
    # guess. Counted here rather than trusted: the awk above closes a stanza on
    # the FIRST endPause, so a region with two would silently be cut short.
    local st en n
    while IFS=$'\t' read -r _ st en _ _ _ _; do
        n=$(sed -n "${st},${en}p" "$src" | grep -c 'endPause')
        (( n == 1 )) || {
            echo "region $st-$en of $src holds $n endPause lines" >&2
            return 1
        }
    done < "$mapf"
    return 0
}

# make_twin <src> <mapfile> <dst> <prefix> <tape-basename> <excised-out>
# The twin: each region replaced by `@dlg_<prefix>N` at the beginPause's
# indent, plus `<target> = dlg_clicked_<prefix>` at the endPause's indent when
# the stanza assigned one. The tape is included after `endform` when the file
# has a form block (the first point a top-level statement is legal) and at the
# very top when it has none.
make_twin () {
    local src="$1" mapf="$2" dst="$3" pfx="$4" tape="$5" excised="$6"
    local base="$WORK/${pfx}_base.praat"
    : > "$base"
    local prev=0 i=0 st en bi ei tgt title
    while IFS=$'\t' read -r i st en bi ei tgt title; do
        (( st > prev )) || { echo "stanza $i out of order in $src" >&2; return 1; }
        awk -v a=$((prev + 1)) -v b=$((st - 1)) 'NR>=a && NR<=b' "$src" >> "$base"
        printf '%*s@dlg_%s%d\n' "$bi" "" "$pfx" "$i" >> "$base"
        if [[ "$tgt" != "-" ]]; then
            printf '%*s%s = dlg_clicked_%s\n' "$ei" "" "$tgt" "$pfx" >> "$base"
        fi
        prev=$en
    done < "$mapf"
    awk -v a=$((prev + 1)) 'NR>=a' "$src" >> "$base"

    if grep -qx 'endform' "$base"; then
        awk -v t="$tape" 'NR==1{d=0} {print} !d && /^endform$/{print "include " t; d=1}' \
            "$base" > "$dst"
    else
        { echo "include $tape"; cat "$base"; } > "$dst"
    fi

    {
        echo "# Cut from $(basename "$src") to make the headless twin $(basename "$dst")."
        echo "# Every beginPause:/endPause region in the driven range, in file order."
        while IFS=$'\t' read -r i st en _ _ _ title; do
            echo "# --- stanza $i  ($title)  lines $st-$en"
            sed -n "${st},${en}p" "$src"
        done < "$mapf"
    } > "$excised"

    # THE PROOF. Shipped minus the regions, against twin minus the injections.
    local delsed="$WORK/${pfx}_del.sed"
    : > "$delsed"
    while IFS=$'\t' read -r _ st en _ _ _ _; do
        printf '%d,%dd\n' "$st" "$en" >> "$delsed"
    done < "$mapf"
    sed -f "$delsed" "$src" > "$WORK/${pfx}_body_shipped.txt"
    grep -vxE "[ \t]*@dlg_${pfx}[0-9]+|[ \t]*[A-Za-z_.][A-Za-z_0-9.]* = dlg_clicked_${pfx}|include ${tape//./\\.}" \
        "$dst" > "$WORK/${pfx}_body_twin.txt"

    local a b
    a=$(sha256sum < "$WORK/${pfx}_body_shipped.txt" | cut -d' ' -f1)
    b=$(sha256sum < "$WORK/${pfx}_body_twin.txt" | cut -d' ' -f1)
    say "twin_${pfx}_source"          "$(basename "$src")"
    say "twin_${pfx}_source_sha"      "$(sha256sum < "$src" | cut -d' ' -f1)"
    say "twin_${pfx}_stanzas"         "$(wc -l < "$mapf")"
    say "twin_${pfx}_body_sha_shipped" "$a"
    say "twin_${pfx}_body_sha_twin"    "$b"
    say "twin_${pfx}_body_identical"   "$([[ "$a" == "$b" ]] && echo 1 || echo 0)"
    [[ "$a" == "$b" ]] || { diff "$WORK/${pfx}_body_shipped.txt" "$WORK/${pfx}_body_twin.txt" | head -20 >&2; return 1; }
    return 0
}

# emit_tape <prefix> <dstfile> <n-stanzas>   — reads TAPE[] / MAXVISIT[]
declare -A TAPE=() MAXVISIT=()
tape () {                     # tape <prefix> <idx> <visit> <line>...
    local pfx="$1" idx="$2" visit="$3"; shift 3
    local body="" l
    for l in "$@"; do body+="        $l"$'\n'; done
    TAPE["$pfx,$idx,$visit"]="$body"
    if (( visit > ${MAXVISIT["$pfx,$idx"]:-0} )); then MAXVISIT["$pfx,$idx"]=$visit; fi
}
emit_tape () {
    local pfx="$1" dst="$2" n="$3" i v first
    {
        echo "# Generated by harness/roundtrip/run.sh. Not part of the plugin."
        echo "# One procedure per excised dialog of the '$pfx' twin."
        echo "dlgBudget_$pfx = 0"
        for i in $(seq 1 "$n"); do echo "dlgV_$pfx$i = 0"; done
        for i in $(seq 1 "$n"); do
            echo ""
            echo "procedure dlg_$pfx$i"
            echo "    dlgBudget_$pfx = dlgBudget_$pfx + 1"
            echo "    if dlgBudget_$pfx > 200"
            echo "        exitScript: \"TWIN $pfx: dialog budget exceeded\""
            echo "    endif"
            echo "    dlgV_$pfx$i = dlgV_$pfx$i + 1"
            # EVERY UNSCRIPTED VISIT PRESSES BUTTON 1, which on all four of
            # these files is Quit / Go Back / Cancel / OK — so a drive that
            # walks somewhere it did not plan for unwinds instead of looping,
            # and the DLG trace in the log shows exactly where it went.
            echo "    dlg_clicked_$pfx = 1"
            first=1
            for v in $(seq 1 "${MAXVISIT["$pfx,$i"]:-0}"); do
                [[ -z "${TAPE["$pfx,$i,$v"]:-}" ]] && continue
                if (( first )); then echo "    if dlgV_$pfx$i = $v"; first=0
                else echo "    elsif dlgV_$pfx$i = $v"; fi
                printf '%s' "${TAPE["$pfx,$i,$v"]}"
            done
            (( first )) || echo "    endif"
            echo "    appendInfoLine: \"DLG|$pfx|$i|visit=\", dlgV_$pfx$i, \"|clicked=\", dlg_clicked_$pfx"
            echo "endproc"
        done
    } > "$dst"
}

# ---- the four twins -------------------------------------------------------
S_DEMO="$PLUG/scripts/eml-create-demo.praat"
S_EDIT="$PLUG/scripts/eml-edit-table.praat"
S_ANOVA="$PLUG/scripts/eml-compare-k-groups.praat"
S_OUT="$PLUG/stats/eml-output.praat"

map_stanzas "$S_DEMO"  "$OUT/MAP_dmo.tsv" || die "stanza map: eml-create-demo.praat"
map_stanzas "$S_EDIT"  "$OUT/MAP_edt.tsv" || die "stanza map: eml-edit-table.praat"
map_stanzas "$S_ANOVA" "$OUT/MAP_anv.tsv" || die "stanza map: eml-compare-k-groups.praat"

# @emlSavePanel's line range, found by name rather than pinned by number.
SP_FROM=$(grep -n '^procedure emlSavePanel:' "$S_OUT" | head -1 | cut -d: -f1)
[[ -n "$SP_FROM" ]] || die "no @emlSavePanel in $(basename "$S_OUT")"
SP_TO=$(awk -v a="$SP_FROM" 'NR>a && /^endproc/{print NR; exit}' "$S_OUT")
[[ -n "$SP_TO" ]] || die "@emlSavePanel has no endproc"
say savepanel_range "${SP_FROM}-${SP_TO}"
map_stanzas "$S_OUT" "$OUT/MAP_out.tsv" "$SP_FROM" "$SP_TO" || die "stanza map: @emlSavePanel"

# The stanza titles go in the artefact, so a shift in any of these files is
# visible in the diff rather than silently retaping a different dialog.
for p in dmo edt anv out; do
    while IFS=$'\t' read -r i st en _ _ _ title; do
        say "stanza_${p}_${i}" "${st}-${en}|${title}"
    done < "$OUT/MAP_${p}.tsv"
done

# THE TAPE ASSERTS WHAT IT IS TAPING. An index is a fragile handle; a title is
# the thing a reader recognises. If either moves, this stops rather than
# driving the wrong dialog.
expect_title () {  # expect_title <prefix> <idx> <title>
    local got
    got=$(awk -F'\t' -v i="$2" '$1==i{print $7}' "$OUT/MAP_$1.tsv")
    [[ "$got" == "$3" ]] || die "stanza $1/$2 is '$got', expected '$3'"
}
expect_title dmo 1 "Create Demo Table"
expect_title edt 4 "EML Table Editor — "
expect_title anv 1 "Compare k Groups (ANOVA)"
expect_title anv 2 "Analysis complete"
expect_title out 4 "Saved"

# ===========================================================================
# 3. THE ADVERSARIAL INPUT
# ===========================================================================
# Three cohorts whose f0 columns do not overlap, and integers throughout, so
# every number downstream is checkable by hand. The editor writes 4242 into
# row 1: cohort alpha's mean moves 103.5 -> 621.25 and its SD 2.449 -> 1464.8,
# which is not a value any other arrangement of these steps lands on.
CSV="$OUT/data/rt_input.csv"
{
    echo "speaker,cohort,f0_Hz"
    for i in $(seq 1 8); do printf 'A%02d,alpha,%d\n'   "$i" $((99 + i)); done
    for i in $(seq 1 8); do printf 'B%02d,bravo,%d\n'   "$i" $((299 + i)); done
    for i in $(seq 1 8); do printf 'C%02d,charlie,%d\n' "$i" $((899 + i)); done
} > "$CSV"
say input_csv        "$CSV"
say input_csv_sha    "$(sha256sum < "$CSV" | cut -d' ' -f1)"
say input_csv_rows   "$(( $(wc -l < "$CSV") - 1 ))"
say edit_target_cell "row 1, column f0_Hz"
say edit_new_value   "4242"

# ===========================================================================
# 4. THE TAPES
# ===========================================================================
# ---- create_demo: pick "Three groups (N=45) — ANOVA / Kruskal-Wallis" ------
tape dmo 1 1 \
    'demo_type = 2' \
    'dlg_clicked_dmo = 2'

# ---- edit_cell: column 3 (f0_Hz), row 1, write 4242, then Quit ------------
# Button 3 on this stanza is Set. The stale-value guard refuses a write only
# when the Value box still holds the SEEDED text after the menus moved; 4242
# is not what row 1 held, so the write goes through on the first press — which
# is the ordinary one-press path, not a special case.
tape edt 4 1 \
    'column = 3' \
    'row = 1' \
    'value$ = "4242"' \
    'dlg_clicked_edt = 3'
tape edt 4 2 \
    'dlg_clicked_edt = 1'

# ---- analysis: f0_Hz by cohort, Tukey on, table order, keep the Info window
tape anv 1 1 \
    'data_column$ = "f0_Hz"' \
    'group_column$ = "cohort"' \
    'tukey_HSD_post_hoc = 1' \
    'group_order = 1' \
    'clear_Info_window = 0' \
    'dlg_clicked_anv = 2'

# ---- draw, at the wrapper's Draw call site, then Save ---------------------
# THE FORM'S GLOBALS, WRITTEN OUT AS VALUES, then the form's OWN draw chain.
# See the header: this is the one substitution in the rig — the dialog is
# replaced, the drawing is not. graph_type 7 is the violin;
# @emlGraphsDispatchDraw reads groupColName$ / valueColName$ / valueMin /
# valueMax for it. valueMin = valueMax = 0 is the auto sentinel.
#
# @emlInitDrawingDefaults IS PART OF THE SUBSTITUTION, NOT AN EXTRA. MEASURED:
# without it the wrapper dies at "Unknown variable: emlSubtitle$" inside
# @emlDrawViolinPlot — because emlSubtitle$ is one of the globals the FORM
# assigns (eml-graphs-form.praat:3701, 3839, 3853, from config_subtitle$ /
# subtitle$), and the form's dialog layer is what this tape stands in for.
# It is the documented entry point for a standalone caller and every harness
# prelude in this tree calls it.
tape anv 2 1 \
    '@emlInitDrawingDefaults' \
    'emlSubtitle$ = ""' \
    'graph_type = 7' \
    'objectId = tableId' \
    'title$ = "f0 by cohort"' \
    'x_axis_label$ = "Cohort"' \
    'y_axis_label$ = "f0 (Hz)"' \
    'figure_width = 6' \
    'figure_height = 4' \
    'colorMode$ = "color"' \
    'gridline_mode = 1' \
    'groupColName$ = "cohort"' \
    'valueColName$ = "f0_Hz"' \
    'valueMin = 0' \
    'valueMax = 0' \
    'histFreqMax = 0' \
    'tsShowCI = 0' \
    'matrixGap = 0' \
    'matrixPanelHeight = 0' \
    'totalCanvasHeight = figure_height' \
    'config_legendPlacement = 1' \
    'config_showAdvanced = 1' \
    'config_groupSort = 1' \
    'emlGroupSortAlphabetical = 0' \
    'annotate = 0' \
    'dataYMax_forAnnotation = 0' \
    '@emlClearAnnotations' \
    'Erase all' \
    '@emlGraphsPublishAxisRequest' \
    'random_initializeWithSeedUnsafelyButPredictably (20260821)' \
    '@emlGraphsDrawWithLegendRoom' \
    '@emlAssertFullViewport' \
    'appendInfoLine: "RT|draw|1|passes=", legendRoomPass, "|ymin=", fixed$ (valueMin, 6), "|ymax=", fixed$ (valueMax, 6)' \
    'appendInfoLine: "RT|drawn_extent|", fixed$ (emlDrawnMinX, 4), "|", fixed$ (emlDrawnMaxX, 4), "|", fixed$ (emlDrawnMinY, 4), "|", fixed$ (emlDrawnMaxY, 4)' \
    'dlg_clicked_anv = 2'
tape anv 2 2 \
    'appendInfoLine: "RT|wrapper_done|1"' \
    'dlg_clicked_anv = 1'

# ---- save: the panel, everything ticked, into out/saved -------------------
# Field variables lowercase the FIRST character of the label only, which is why
# it is figure_PNG and not figure_png. base_name$ is pinned so the artefact is
# diffable — the panel proposes stem + @emlFileStamp, which is a wall clock.
tape out 1 1 \
    'figure_PNG = 1' \
    'also_EPS = 0' \
    'also_PDF = 0' \
    'results_CSV = 1' \
    'report_from_the_Info_window = 1' \
    "folder\$ = \"$OUT/saved\"" \
    'base_name$ = "rt_roundtrip"' \
    'dlg_clicked_out = 2'

N_DMO=$(wc -l < "$OUT/MAP_dmo.tsv")
N_EDT=$(wc -l < "$OUT/MAP_edt.tsv")
N_ANV=$(wc -l < "$OUT/MAP_anv.tsv")
N_OUT=$(wc -l < "$OUT/MAP_out.tsv")

emit_tape dmo "$STAGE/scripts/_rt_tape_dmo.praat" "$N_DMO"
emit_tape edt "$STAGE/scripts/_rt_tape_edt.praat" "$N_EDT"
emit_tape anv "$STAGE/scripts/_rt_tape_anv.praat" "$N_ANV"
emit_tape out "$STAGE/scripts/_rt_tape_out.praat" "$N_OUT"

make_twin "$S_DEMO"  "$OUT/MAP_dmo.tsv" "$STAGE/scripts/_rt_create_demo.praat" \
          dmo _rt_tape_dmo.praat "$OUT/EXCISED_dmo.txt" || die "twin: create-demo"
make_twin "$S_EDIT"  "$OUT/MAP_edt.tsv" "$STAGE/scripts/_rt_edit_table.praat" \
          edt _rt_tape_edt.praat "$OUT/EXCISED_edt.txt" || die "twin: edit-table"
make_twin "$S_ANOVA" "$OUT/MAP_anv.tsv" "$STAGE/scripts/_rt_compare_k.praat" \
          anv _rt_tape_anv.praat "$OUT/EXCISED_anv.txt" || die "twin: compare-k-groups"

# The eml-output twin REPLACES the symlink in the staged stats folder, so
# `include ../stats/eml-output.praat` — the shipped line in eml-lib-stats —
# picks it up with nothing else edited anywhere.
rm -f "$STAGE/stats/eml-output.praat"
make_twin "$S_OUT" "$OUT/MAP_out.tsv" "$STAGE/stats/eml-output.praat" \
          out _rt_tape_out.praat "$OUT/EXCISED_out.txt" || die "twin: eml-output"

cp "$SCRIPT_DIR/drive.praat" "$STAGE/scripts/_rt_drive.praat"

# ===========================================================================
# 5. THE DRIVE
# ===========================================================================
LOG="$OUT/drive.log"
: > "$LOG"

( cd "$STAGE/scripts" && env -u DISPLAY \
    HOME="$(dirname "$ROOT")" \
    EML_RT_OUT="$OUT" \
    EML_RT_CSV="$CSV" \
    EML_RT_PLUGIN="$PLUG" \
    EML_RECORD_STAMP="21 August 2026, 00:00:00" \
    timeout 600 "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" \
    --run _rt_drive.praat > "$LOG" 2>&1 )
RC=$?
say drive_exit "$RC"

# Praat writes UTF-16 the moment the text is not pure ASCII, and a recorded
# workflow is a file a user opens and commits. Normalised the way
# harness/record_e2e and harness/record/roundtrip.sh already do.
EMIT="$OUT/emitted.praat"
if [[ -f "$EMIT" ]] && file "$EMIT" | grep -q UTF-16; then
    iconv -f UTF-16 -t UTF-8 "$EMIT" -o "$EMIT.u8" && mv "$EMIT.u8" "$EMIT"
fi

# ===========================================================================
# 6. WHAT HAPPENED IN THE SESSION
# ===========================================================================
rt () { sed -n "s/^RT|$1|//p" "$LOG" | head -1; }

say record_started        "$(rt record_started)"
say dlg_trace             "$(grep -o '^DLG|[a-z]*|[0-9]*' "$LOG" | sed 's/^DLG|//' | paste -sd, -)"

# --- 1 create_demo ---------------------------------------------------------
IFS='|' read -r A_DEMO_RAN A_DEMO_ROWS A_DEMO_COLS <<< "$(rt create_demo)"
say action1_create_demo_ran   "${A_DEMO_RAN:-0}"
say action1_create_demo_table "demo_3groups"
say action1_create_demo_rows  "${A_DEMO_ROWS:--1}"
say action1_create_demo_cols  "${A_DEMO_COLS:--1}"
say action1_steps_in_buffer_after "$(sed -n 's/^RT|steps_after|create_demo|//p' "$LOG" | head -1)"

# --- 2 load_file -----------------------------------------------------------
IFS='|' read -r A_LOAD_RAN A_LOAD_ROWS A_LOAD_COLS A_LOAD_NAME <<< "$(rt load_file)"
say action2_load_file_ran     "${A_LOAD_RAN:-0}"
say action2_load_file_object  "${A_LOAD_NAME:-<none>}"
say action2_load_file_rows    "${A_LOAD_ROWS:--1}"
say action2_load_file_cols    "${A_LOAD_COLS:--1}"
say action2_steps_in_buffer_after "$(sed -n 's/^RT|steps_after|load_file|//p' "$LOG" | head -1)"

# --- 3 edit_cell -----------------------------------------------------------
IFS='|' read -r A_EDIT_RAN A_EDIT_AFTER <<< "$(rt edit_cell)"
say action3_edit_cell_ran     "${A_EDIT_RAN:-0}"
say action3_edit_cell_before  "$(rt cell_before)"
say action3_edit_cell_after   "${A_EDIT_AFTER:-<none>}"
say action3_table_mean_after  "$(rt table_mean_after_edit)"
say action3_steps_in_buffer_after "$(sed -n 's/^RT|steps_after|edit_cell|//p' "$LOG" | head -1)"

# --- 4 analysis ------------------------------------------------------------
# The numbers are read out of the Info window the wrapper wrote, because that
# is the report the user is looking at when they press Save. The ANOVA table's
# Between row carries SS, df, MS, F and p in one line.
say action4_analysis_ran   "$(grep -c 'EML Stats : One-Way ANOVA' "$LOG")"
say action4_anova_between  "$(grep -m1 '^Between' "$LOG" | tr -s ' \t' ' ')"
say action4_anova_within   "$(grep -m1 '^Within'  "$LOG" | tr -s ' \t' ' ')"
say action4_group_means    "$(grep -oE '[a-z]+: n = [0-9]+, mean = [0-9.]+' "$EMIT" 2>/dev/null | sed 's/$/;/' | tr -d '\n')"
say action4_report_context "$(grep -m1 '^  from:' "$LOG" | sed 's/^ *//')"

# --- 5 draw ----------------------------------------------------------------
IFS='|' read -r _ A_DRAW_PASSES A_DRAW_YMIN A_DRAW_YMAX <<< "$(rt draw)"
say action5_draw_ran           "$(grep -c '^RT|draw|' "$LOG")"
say action5_draw_type          "violin (graph_type 7), f0_Hz by cohort"
say action5_draw_legend_passes "${A_DRAW_PASSES#passes=}"
# THE REQUEST, NOT THE RESOLUTION. valueMin/valueMax are the form's y-range
# REQUEST and 0/0 is the auto sentinel; the axis the figure actually got is in
# the emitted block's resolved-range note, read below.
say action5_axis_request_min   "${A_DRAW_YMIN#ymin=}"
say action5_axis_request_max   "${A_DRAW_YMAX#ymax=}"
say action5_drawn_extent       "$(rt drawn_extent)"

# --- 6 save ----------------------------------------------------------------
say action6_files_written   "$(find "$OUT/saved" -type f | wc -l)"
say action6_file_list       "$(find "$OUT/saved" -type f -printf '%f\n' | sort | paste -sd, -)"
say action6_png_bytes       "$(stat -c%s "$OUT/saved"/*.png 2>/dev/null | head -1 || echo 0)"
say action6_steps_in_buffer_after "$(sed -n 's/^RT|steps_after|analysis_draw_save|//p' "$LOG" | head -1)"

IFS='|' read -r F_WRITTEN F_PATH <<< "$(rt flush)"
say flush_written "${F_WRITTEN:-0}"
say discard       "$(rt discard)"

# ===========================================================================
# 7. WHAT THE EMITTED SCRIPT CONTAINS
# ===========================================================================
if [[ -f "$EMIT" ]]; then
    say emitted_exists 1
    say emitted_bytes  "$(stat -c%s "$EMIT")"
    say emitted_lines  "$(wc -l < "$EMIT")"
    say emitted_sha    "$(sha256sum < "$EMIT" | cut -d' ' -f1)"
    say emitted_step_headings "$(grep -cE '^# --- Step [0-9]+ ' "$EMIT")"
    say emitted_step_kinds    "$(sed -n 's/^# --- Step [0-9]* (\([a-z]*\)) ---$/\1/p' "$EMIT" | paste -sd, -)"
    say emitted_missing_phrases "$(grep -c 'MISSING PHRASE' "$EMIT")"
    say emitted_include_root  "$(sed -n 's|^include \(.*\)/stats/eml-core-utilities\.praat$|\1|p' "$EMIT" | head -1)"
    say emitted_input_line    "$(grep -m1 '^# *Input' "$EMIT" | sed 's/^[[:space:]]*//' | tr '\t' ' ')"
    say emitted_selectobject  "$(grep -m1 '^selectObject:' "$EMIT" | tr '\t' ' ')"

    # ONE KEY PER ACTION: does the emitted script contain anything that would
    # REPRODUCE it? The greps are for the API-level call each action would have
    # to make, not for a word in a comment.
    say emitted_has_create_demo "$(grep -cE 'Create Table with column names|demo_3groups|eml-create-demo' "$EMIT")"
    say emitted_has_load_file   "$(grep -cE 'Read Table from comma-separated file|Read from file|rt_input\.csv' "$EMIT")"
    say emitted_has_edit_cell   "$(grep -cE 'Set string value|Set numeric value|@cellWrite|4242' "$EMIT")"
    say emitted_has_analysis    "$(grep -cE '^@emlRunAnovaAnalysis' "$EMIT")"
    say emitted_has_draw        "$(grep -cE '^@emlDrawViolinPlot' "$EMIT")"
    say emitted_has_save        "$(grep -cE '^@emlRecordReplaySave|@emlSavePanel' "$EMIT")"

    say emitted_analysis_line "$(grep -m1 -E '^@emlRunAnovaAnalysis' "$EMIT" | tr '\t' ' ')"
    say emitted_draw_line     "$(grep -m1 -E '^@emlDrawViolinPlot' "$EMIT" | tr '\t' ' ')"
    say emitted_save_line     "$(grep -m1 -E '^@emlRecordReplaySave' "$EMIT" | tr '\t' ' ')"
    say emitted_block_vars    "$(grep -cE '^[a-zA-Z_][a-zA-Z0-9_]*\$? *= ' "$EMIT")"
    say emitted_data_decl     "$(grep -m1 '^data1\$' "$EMIT" | tr '\t' ' ')"
    say emitted_axis_note     "$(sed -n 's/^# Axis resolved to //p' "$EMIT" | head -1)"
    say emitted_axis_block    "$(grep -m1 '^axisYMax' "$EMIT" | tr '\t' ' ')"
    say emitted_folder_line   "$(grep -m1 '^outputFolder\$' "$EMIT" | tr '\t' ' ')"
    say emitted_first_step_body "$(awk '/^# --- Step 1 /{f=1;next} f&&NF{print;exit}' "$EMIT")"

    # WHAT A REPLAY WOULD NEED THAT THE FILE DOES NOT CARRY, read off the
    # file rather than asserted. Three questions, each answered by whether
    # the emitted script contains the step: does it build its own table, does
    # it open its own file, does it reproduce the edit? The key is a statement
    # about the FILE, not about this harness, so it is composed from what the
    # file has and not from what this harness knows it drove.
    rt_need=""
    grep -qE '^# --- Step [0-9]+ \(create\) ---' "$EMIT" \
        || rt_need="${rt_need}builds no table; "
    grep -qE '^# --- Step [0-9]+ \(read\) ---' "$EMIT" \
        || rt_need="${rt_need}opens no file; "
    grep -qE '4242' "$EMIT" \
        || rt_need="${rt_need}carries no cell edit; "
    if [ -z "$rt_need" ]; then
        say emitted_replay_precondition "none -- the file builds, opens and edits its own data"
    else
        say emitted_replay_precondition \
            "${rt_need}whatever it does not supply must be open, under the name the block gives, before a replay"
    fi
else
    say emitted_exists 0
    for k in emitted_bytes emitted_lines emitted_step_headings; do say "$k" 0; done
fi

# ---- ONE LINE PER ACTION, IN WORDS ----------------------------------------
# The six keys the question was actually about. A count is easy to misread as
# "the harness could not find it"; these say what is there.
emitted_for () {   # emitted_for <key> <grep-ere>
    local hit
    hit=$(grep -m1 -E "$2" "$EMIT" 2>/dev/null | sed 's/^[[:space:]]*//' | tr '\t' ' ')
    say "$1" "${hit:-<nothing>}"
}
emitted_for action1_emitted '@emlDemoTable|Create Table with column names|demo_3groups|eml-create-demo'
emitted_for action2_emitted '@emlRecordReplayRead|Read Table from comma-separated file|Read from file|rt_input\.csv'
emitted_for action3_emitted 'Set string value|Set numeric value|@cellWrite|4242'
emitted_for action4_emitted '^@emlRunAnovaAnalysis'
emitted_for action5_emitted '^@emlDrawViolinPlot'
emitted_for action6_emitted '^@emlRecordReplaySave'

# ===========================================================================
# 8. THE REPLAY — what the emitted script does when it is run
# ===========================================================================
# THE ADVERSARIAL DATA EARNS ITS KEEP HERE. The emitted file re-selects
# "Table rt_input" by name and never creates, loads or edits it, so a replay
# has to start by loading the CSV — and the CSV on disk does NOT carry the
# hand edit, because the edit was made in the Objects window and nothing
# recorded it. If the two ANOVAs agree, either the edit did nothing or the
# recorder captured it; they cannot agree by coincidence, because 4242 in a
# column of 100..107 moves cohort alpha's mean by 518.
#
# ONE LINE OF THE EMITTED FILE IS EDITED and it is the one the file itself
# invites a reader to edit: outputFolder$, so the replay's outputs land beside
# the session's rather than on top of them. Same move as the RETARGET and
# TUNED legs in harness/record/replay.sh, and the edited copy is kept.
REPLAY_DIR="$OUT/replay"
mkdir -p "$REPLAY_DIR/saved"
REPLAY_EMIT="$WORK/replay_emitted.praat"
if [[ -f "$EMIT" ]]; then
    sed "s|^outputFolder\$ = \".*\"|outputFolder\$ = \"$REPLAY_DIR/saved\"|" \
        "$EMIT" > "$REPLAY_EMIT"
    say replay_edit_lines "$(diff "$EMIT" "$REPLAY_EMIT" | grep -c '^[<>]')"

    cat > "$WORK/replay.praat" <<PRAAT
# Generated by harness/roundtrip/run.sh. The emitted workflow, replayed from
# the CSV alone — which is all a colleague who was sent the file would have.
Read Table from comma-separated file: "$CSV"
rp = selected ("Table")
selectObject: rp
rpCell\$ = Get value: 1, "f0_Hz"
appendInfoLine: "RP|cell|", rpCell\$
include $REPLAY_EMIT
appendInfoLine: "RP|done|1"
PRAAT
    ( cd "$WORK" && env -u DISPLAY HOME="$(dirname "$ROOT")" \
        timeout 300 "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" \
        --run "$WORK/replay.praat" > "$OUT/replay.log" 2>&1 )
    say replay_exit       "$?"
    say replay_reached_end "$(grep -c '^RP|done|1$' "$OUT/replay.log")"
    say replay_cell_row1  "$(sed -n 's/^RP|cell|//p' "$OUT/replay.log" | head -1)"
    say replay_anova_between "$(grep -m1 '^Between' "$OUT/replay.log" | tr -s ' \t' ' ')"
    say replay_files_written "$(find "$REPLAY_DIR/saved" -type f | wc -l)"
    say replay_file_list  "$(find "$REPLAY_DIR/saved" -type f -printf '%f\n' | sed 's/_[0-9]\{8\}_[0-9]\{6\}//' | sort | paste -sd, -)"
    R_F=$(grep -m1 '^Between' "$OUT/replay.log" | tr -s ' \t' ' ' | cut -d' ' -f5)
    S_F=$(grep -m1 '^Between' "$LOG"            | tr -s ' \t' ' ' | cut -d' ' -f5)
    say session_F "$S_F"
    say replay_F  "$R_F"
    say replay_matches_session_F "$([[ -n "$R_F" && "$R_F" == "$S_F" ]] && echo 1 || echo 0)"
    # AND THE PICTURE, for the same reason: the 4242 cell is visible in the
    # session's violin as a tail to 5000 and absent from the replay's.
    say session_png_md5 "$(md5sum "$OUT/saved"/rt_roundtrip.png 2>/dev/null | cut -d' ' -f1)"
    say replay_png_md5  "$(md5sum "$REPLAY_DIR/saved"/*.png 2>/dev/null | head -1 | cut -d' ' -f1)"
else
    say replay_exit -1
fi

# ===========================================================================
# 9. VERDICT — mechanism only. Coverage is reported, never asserted.
# ===========================================================================
fail=0
for p in dmo edt anv out; do
    [[ "$(awk -F'\t' -v k="twin_${p}_body_identical" '$1==k{print $2}' "$TSV")" == "1" ]] \
        || { echo "FAIL: twin $p differs from its shipped body"; fail=1; }
done
[[ "$(rt record_started)" == "1" ]] || { echo "FAIL: the recording did not start"; fail=1; }
[[ "${F_WRITTEN:-0}" == "1" ]]     || { echo "FAIL: no script was written"; fail=1; }
[[ -f "$EMIT" ]]                   || { echo "FAIL: no emitted script at $EMIT"; fail=1; }
grep -q '^RT|end|ok$' "$LOG"       || { echo "FAIL: the drive did not reach its end — see $LOG"; fail=1; }

echo
printf '%-34s %s\n' "action" "ran / emitted"
printf '%-34s %s\n' "1 create_demo" "$(awk -F'\t' '$1=="action1_create_demo_ran"{print $2}' "$TSV") / $(awk -F'\t' '$1=="emitted_has_create_demo"{print $2}' "$TSV")"
printf '%-34s %s\n' "2 load_file"   "$(awk -F'\t' '$1=="action2_load_file_ran"{print $2}' "$TSV") / $(awk -F'\t' '$1=="emitted_has_load_file"{print $2}' "$TSV")"
printf '%-34s %s\n' "3 edit_cell"   "$(awk -F'\t' '$1=="action3_edit_cell_ran"{print $2}' "$TSV") / $(awk -F'\t' '$1=="emitted_has_edit_cell"{print $2}' "$TSV")"
printf '%-34s %s\n' "4 analysis"    "$(awk -F'\t' '$1=="action4_analysis_ran"{print $2}' "$TSV") / $(awk -F'\t' '$1=="emitted_has_analysis"{print $2}' "$TSV")"
printf '%-34s %s\n' "5 draw"        "$(awk -F'\t' '$1=="action5_draw_ran"{print $2}' "$TSV") / $(awk -F'\t' '$1=="emitted_has_draw"{print $2}' "$TSV")"
printf '%-34s %s\n' "6 save"        "$(awk -F'\t' '$1=="action6_files_written"{print $2}' "$TSV") / $(awk -F'\t' '$1=="emitted_has_save"{print $2}' "$TSV")"
echo
printf '%-34s %s\n' "session   ANOVA F" "$(awk -F'\t' '$1=="session_F"{print $2}' "$TSV")"
printf '%-34s %s\n' "replayed  ANOVA F" "$(awk -F'\t' '$1=="replay_F"{print $2}' "$TSV")  (the emitted file carries no cell edit)"
echo
echo "emitted steps : $(awk -F'\t' '$1=="emitted_step_kinds"{print $2}' "$TSV")"
echo "emitted script: $EMIT"
echo "transcript    : $TSV"

if [[ $fail -eq 0 ]]; then
    echo "roundtrip: PASS — one session, six actions, one emitted script"
    exit 0
fi
exit 1
