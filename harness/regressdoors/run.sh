#!/usr/bin/env bash
# ============================================================================
# harness/regressdoors/run.sh -- the leg5 Simpson fixture through BOTH
#                                regression doors, driven, not simulated
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS EXISTS, BESIDE harness/regressiongroup.
#
# harness/regressiongroup/probe.praat calls @emlRunGroupedRegression directly:
# it proves the PORT is right. harness/doorcensus/probe.praat calls the
# kernels with the arguments each door is BELIEVED to pass: it proves nothing
# about the doors themselves, and its leg5 branch still carries the pre-port
# comment and emits scope_label = "pooled (group column read, never passed)".
# Neither one presses a button. This one does: it excises the pause stanzas
# out of the shipped door scripts MECHANICALLY, hashes what is left against
# the shipped bytes minus those same stanzas, and runs the rest -- the
# candidate-column scan, the stale-column refusal, the analysis call, the
# report -- exactly as shipped.
#
# The technique is harness/correlgroup/run.sh's, whose header explains it in
# full; the standing rules there (kill by exact name, twin-body hashing,
# unscripted visits press button 1) are followed, not re-derived.
#
# THE FIXTURE is harness/doorcensus/fixtures/leg5_grouped_regression.csv --
# Sol's Simpson exhibit: group A slope +1.984, group B slope -1.985, pooled
# slope -0.0006. A door that drops the group column reports the pooled zero.
#
#   bash harness/regressdoors/run.sh
#
# Evidence, all under out/: REGDOORS.tsv (scalars), <case>.log (Info window).
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$SCRIPT_DIR/.." && pwd)/_env.sh" || exit 1

PLUGIN="$EML_ROOT/plugin"
OUT="${EML_REGDOORS_DIR:-$SCRIPT_DIR/out}"
PREFS="$SCRIPT_DIR/prefs"
WORK="$OUT/work"

rm -rf "$WORK"; mkdir -p "$OUT" "$PREFS" "$WORK"
rm -f "$OUT"/*.log "$OUT/REGDOORS.tsv"
TSV="$OUT/REGDOORS.tsv"; : > "$TSV"
say () { printf '%s\t%s\n' "$1" "$2" >> "$TSV"; }
say praat_version "$("$PRAAT" --version 2>&1 | head -1)"

TREE="$WORK/plugin"; mkdir -p "$TREE"; cp -R "$PLUGIN"/. "$TREE"/ 2>/dev/null

# ---------------------------------------------------------------------------
# THE FIXTURE, read from the committed CSV -- not retyped.
# ---------------------------------------------------------------------------
FIXCSV="$EML_ROOT/harness/doorcensus/fixtures/leg5_grouped_regression.csv"
[[ -f "$FIXCSV" ]] || { echo "regressdoors: FAIL - missing $FIXCSV" >&2; exit 1; }
FIXTURE="$WORK/fixture.praat"
{
    NR=$(grep -cE '^[0-9]' "$FIXCSV")
    echo "Create Table with column names: \"leg5\", $NR, \"x y group\""
    echo 'tableId = selected ("Table")'
    r=0
    while IFS=, read -r x y g; do
        [[ "$x" =~ ^[0-9] ]] || continue
        r=$((r+1))
        echo "selectObject: tableId"
        echo "Set numeric value: $r, \"x\", $x"
        echo "Set numeric value: $r, \"y\", $y"
        echo "Set string value: $r, \"group\", \"$g\""
    done < "$FIXCSV"
    echo 'selectObject: tableId'
} > "$FIXTURE"
say fixture_rows "$(grep -c 'Set string value' "$FIXTURE")"
say fixture_csv_sha "$(sha256sum < "$FIXCSV" | cut -d' ' -f1)"

# ---------------------------------------------------------------------------
# BUILD A HEADLESS TWIN OF ONE DOOR SCRIPT
# ---------------------------------------------------------------------------
build_twin () {                      # build_twin <door-basename> <include-anchor>
    DOOR="$1"; ANCHOR="$2"
    SRC="$PLUGIN/scripts/$DOOR"
    [[ -f "$SRC" ]] || { echo "regressdoors: FAIL - missing $SRC" >&2; exit 1; }
    MAP="$WORK/${DOOR%.praat}_dialogs.tsv"
    awk '
    function indent(s,   t) { t = s; sub(/[^ \t].*/, "", t); return length(t) }
    /^[ \t]*beginPause: /{
        if (inb) { printf "regressdoors: FAIL - nested beginPause at line %d\n", NR > "/dev/stderr"; exit 2 }
        inb = 1; start = NR; bi = indent($0)
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
        inb = 0; next
    }
    END{
        if (inb) { printf "regressdoors: FAIL - unterminated beginPause at %d\n", start > "/dev/stderr"; exit 2 }
        if (idx == 0) { print "regressdoors: FAIL - no pause stanzas" > "/dev/stderr"; exit 2 }
    }' "$SRC" > "$MAP" || exit 1

    N_STANZA=$(wc -l < "$MAP")
    say "${DOOR%.praat}_stanza_count" "$N_STANZA"
    unset KEY_OF_IDX IDX_OF_KEY OCC S_START S_END S_BI S_EI S_TGT
    declare -gA KEY_OF_IDX=() IDX_OF_KEY=() OCC=()
    declare -ga S_START=() S_END=() S_BI=() S_EI=() S_TGT=()
    while IFS=$'\t' read -r idx st en bi ei tgt title; do
        slug=$(printf '%s' "$title" | tr '[:upper:]' '[:lower:]' \
               | sed -E 's/[^a-z0-9]+/_/g; s/^_+//; s/_+$//')
        [[ -z "$slug" ]] && slug="untitled"
        OCC[$slug]=$(( ${OCC[$slug]:-0} + 1 ))
        key="${slug}#${OCC[$slug]}"
        KEY_OF_IDX[$idx]="$key"; IDX_OF_KEY[$key]="$idx"
        S_START[$idx]="$st"; S_END[$idx]="$en"; S_BI[$idx]="$bi"
        S_EI[$idx]="$ei"; S_TGT[$idx]="$tgt"
    done < "$MAP"

    TWIN="$TREE/scripts/$DOOR"
    {
        prev=0
        for i in $(seq 1 "$N_STANZA"); do
            st=${S_START[$i]}; en=${S_END[$i]}
            (( st > prev )) || { echo "regressdoors: FAIL - stanza $i out of order" >&2; exit 1; }
            sed -n "$((prev + 1)),$((st - 1))p" "$SRC"
            printf '%*s@dlg%d\n' "${S_BI[$i]}" "" "$i"
            [[ "${S_TGT[$i]}" != "-" ]] && printf '%*s%s = dlg_clicked\n' "${S_EI[$i]}" "" "${S_TGT[$i]}"
            prev=$en
        done
        sed -n "$((prev + 1)),\$p" "$SRC"
    } > "$WORK/${DOOR}.base" || exit 1

    awk -v anchor="$ANCHOR" 'NR==1{done=0} {print} !done && $0==anchor{print "include _dlg.praat"; done=1}' \
        "$WORK/${DOOR}.base" > "$TWIN"
    grep -qx 'include _dlg.praat' "$TWIN" || {
        echo "regressdoors: FAIL - anchor '$ANCHOR' not found in $DOOR" >&2; exit 1; }

    DELSED="$WORK/${DOOR}.del.sed"; : > "$DELSED"
    for i in $(seq 1 "$N_STANZA"); do
        printf '%d,%dd\n' "${S_START[$i]}" "${S_END[$i]}" >> "$DELSED"
    done
    sed -f "$DELSED" "$SRC" > "$WORK/${DOOR}.body_shipped"
    grep -vxE '[ \t]*@dlg[0-9]+|[ \t]*[A-Za-z_.][A-Za-z_0-9.]* = dlg_clicked|include _dlg\.praat' \
        "$TWIN" > "$WORK/${DOOR}.body_twin"
    a=$(sha256sum < "$WORK/${DOOR}.body_shipped" | cut -d' ' -f1)
    b=$(sha256sum < "$WORK/${DOOR}.body_twin" | cut -d' ' -f1)
    say "${DOOR%.praat}_body_identical" "$([[ "$a" == "$b" ]] && echo 1 || echo 0)"
    if [[ "$a" != "$b" ]]; then
        echo "regressdoors: FAIL - twin body differs from shipped body ($DOOR)" >&2
        diff "$WORK/${DOOR}.body_shipped" "$WORK/${DOOR}.body_twin" | head -20 >&2
        exit 1
    fi
    say "${DOOR%.praat}_file_sha" "$(sha256sum < "$SRC" | cut -d' ' -f1)"
}

# ---------------------------------------------------------------------------
# THE ERROR DIALOG, REPLACED WHOLE (a refusal must not stall the run)
# ---------------------------------------------------------------------------
stub_errdlg () {
    ERRSRC="$PLUGIN/stats/eml-output.praat"
    EB=$(awk '/^procedure emlErrorDialog: /{print NR; exit}' "$ERRSRC")
    EE=$(awk -v s="$EB" 'NR>s && /^endproc$/{print NR; exit}' "$ERRSRC")
    [[ -n "$EB" && -n "$EE" && "$EE" -gt "$EB" ]] || {
        echo "regressdoors: FAIL - could not bound @emlErrorDialog" >&2; exit 1; }
    {
        sed -n "1,$((EB - 1))p" "$ERRSRC"
        cat <<'STUB'
procedure emlErrorDialog: .msg$, .remedy$, .mode$
    appendInfoLine: "ERRMSG|", .msg$
    .clicked = 1
    .back = 0
endproc
STUB
        sed -n "$((EE + 1)),\$p" "$ERRSRC"
    } > "$TREE/stats/eml-output.praat"
    sed "${EB},${EE}d" "$ERRSRC" > "$WORK/errbody_shipped"
    sed "${EB},$((EB + 4))d" "$TREE/stats/eml-output.praat" > "$WORK/errbody_twin"
    x=$(sha256sum < "$WORK/errbody_shipped" | cut -d' ' -f1)
    y=$(sha256sum < "$WORK/errbody_twin" | cut -d' ' -f1)
    say errdlg_body_identical "$([[ "$x" == "$y" ]] && echo 1 || echo 0)"
    [[ "$x" == "$y" ]] || { echo "regressdoors: FAIL - eml-output.praat outside the stub is not shipped" >&2; exit 1; }
}

declare -A TAPE=() MAXVISIT=()
tape_reset () { TAPE=(); MAXVISIT=(); }
tape () {                       # tape <key> <visit> <praat line>...
    local key="$1" visit="$2"; shift 2
    local idx="${IDX_OF_KEY[$key]:-}"
    [[ -n "$idx" ]] || { echo "regressdoors: FAIL - no dialog keyed '$key'" >&2
                         echo "  known: ${!IDX_OF_KEY[*]}" >&2; exit 1; }
    local body="" l
    for l in "$@"; do body+="        $l"$'\n'; done
    TAPE["$idx,$visit"]="$body"
    (( visit > ${MAXVISIT[$idx]:-0} )) && MAXVISIT[$idx]=$visit
    return 0
}
emit_dlg () {
    local dir="$1"
    local f="$1/_dlg.praat"
    local i v
    {
        echo "# Generated by harness/regressdoors/run.sh. Not part of the plugin."
        echo "dlgBudget = 0"
        for i in $(seq 1 "$N_STANZA"); do echo "dlgV$i = 0"; done
        for i in $(seq 1 "$N_STANZA"); do
            echo ""
            echo "procedure dlg$i"
            echo "    dlgBudget = dlgBudget + 1"
            echo "    if dlgBudget > 200"
            echo "        exitScript: \"TWIN: dialog budget exceeded\""
            echo "    endif"
            echo "    dlgV$i = dlgV$i + 1"
            echo "    dlg_clicked = 1"
            local first=1
            for v in $(seq 1 "${MAXVISIT[$i]:-0}"); do
                [[ -z "${TAPE[$i,$v]:-}" ]] && continue
                if (( first )); then echo "    if dlgV$i = $v"; first=0
                else echo "    elsif dlgV$i = $v"; fi
                printf '%s' "${TAPE[$i,$v]}"
            done
            (( first )) || echo "    endif"
            echo "    appendInfoLine: \"DLG|$i|${KEY_OF_IDX[$i]}|visit=\", dlgV$i, \"|clicked=\", dlg_clicked"
            echo "endproc"
        done
    } > "$f"
}

run_case () {                   # run_case <name> <door-basename>
    local name="$1"
    local door="$2"
    local dir="$WORK/$name"
    mkdir -p "$dir"; cp -R "$TREE"/. "$dir"/
    emit_dlg "$dir/scripts"
    {
        echo "# Case $name."
        cat "$FIXTURE"
        echo "appendInfoLine: \"CASE handoff\""
        echo "selectObject: tableId"
        echo "runScript: \"scripts/$door\""
        echo "appendInfoLine: \"CASE returned\""
    } > "$dir/case.praat"
    ( env -u DISPLAY timeout 240 "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" \
        --run "$dir/case.praat" > "$dir/run.log" 2>&1 )
    local rc=$?
    say "${name}_exit" "$rc"
    sed "s|$WORK|<WORK>|g" "$dir/run.log" > "$OUT/$name.log"
    say "${name}_returned" "$(grep -c '^CASE returned$' "$dir/run.log")"
    say "${name}_dlg_trace" "$(grep -o 'DLG|[0-9]*|[^|]*|' "$dir/run.log" | cut -d'|' -f3 | paste -sd, -)"
    say "${name}_errmsgs" "$(grep -c '^ERRMSG|' "$dir/run.log")"
    say "${name}_errmsg_first" "$(grep -m1 '^ERRMSG|' "$dir/run.log" | tr '\t' ' ')"
    say "${name}_stderr_head" "$(grep -m1 '^Error' "$dir/run.log" | tr '\t' ' ')"
}

# ===========================================================================
# CASE 1 -- THE MENU DOOR: scripts/eml-regress.praat
# ===========================================================================
# Predictor x, response y, Group column "group" (menu position 2: the list
# is "(none)" plus the FILTERED candidates, and "group" is the only column
# that survives the filter once x and y are the two being regressed).
# ===========================================================================
stub_errdlg
build_twin "eml-regress.praat" "include eml-lib.praat"
say menu_dialog_keys "$(for i in $(seq 1 "$N_STANZA"); do printf '%s ' "${KEY_OF_IDX[$i]}"; done)"
tape_reset
tape "simple_linear_regression#1" 1 \
    'predictor_column = 1' 'predictor_column$ = "x"' \
    'response_column = 2'  'response_column$ = "y"' \
    'group_column = 2' \
    'clear_Info_window = 0' 'annotate_results_with_explanations = 0' \
    'dlg_clicked = 2'
tape "analysis_complete#1" 1 'dlg_clicked = 1'
run_case "menu_grouped" "eml-regress.praat"

# ===========================================================================
# CASE 2 -- THE WIZARD DOOR: scripts/eml-wizard.praat, page B_REG_COLUMNS
# ===========================================================================
build_twin "eml-wizard.praat" "include eml-lib-lmm.praat"
say wizard_dialog_keys "$(for i in $(seq 1 "$N_STANZA"); do printf '%s ' "${KEY_OF_IDX[$i]}"; done)"
tape_reset
# Q1_GOAL: "Examine a relationship" is option 2; Continue is button 2.
tape "eml_stats_wizard#1" 1 'research_goal = 2' 'dlg_clicked = 2'
# B1_RELATIONSHIP: "Regression (both continuous)" is option 2; Continue = 3.
tape "relationship_what_type#1" 1 'relationship_type = 2' 'dlg_clicked = 3'
# B_REG_COLUMNS: x -> predictor, y -> response, "group" -> the one candidate
# that survives the filter (menu position 2). Run is button 3.
tape "regression_select_columns#1" 1 \
    'predictor_column = 1' 'predictor_column$ = "x"' \
    'response_column = 2'  'response_column$ = "y"' \
    'group_column = 2' 'clear_Info_window = 0' \
    'dlg_clicked = 3'
for k in analysis_complete#1 analysis_complete#2 analysis_complete#3 analysis_complete#4; do
    tape "$k" 1 'dlg_clicked = 1'
done
run_case "wizard_grouped" "eml-wizard.praat"

# ===========================================================================
# CASE 3 -- THE DRAWN LINES, same fixture, same group column
# ===========================================================================
( cd "$SCRIPT_DIR" && env -u DISPLAY timeout 180 "$PRAAT" $PRAAT_TRUST \
    --pref-dir="$PREFS" --run "$SCRIPT_DIR/draw_probe.praat" ) \
    > "$OUT/draw_probe.log" 2>&1
say draw_probe_exit "$?"

# ---------------------------------------------------------------------------
# WHAT CAME OUT -- reported vs drawn, per group, both doors
# ---------------------------------------------------------------------------
eqn () {                        # eqn <logfile> <group>  -> reported equation
    awk -v g="$2" '
        /^  Table  /            { grp = ($0 ~ ("group = " g "$") || $0 ~ ("-- " g "$")) }
        grp && /^  Equation /   { sub(/^  Equation  */, ""); print; exit }' "$1"
}
for c in menu_grouped wizard_grouped; do
    for g in A B; do
        say "${c}_reported_eqn_${g}" "$(eqn "$OUT/$c.log" "$g")"
    done
    say "${c}_pooled_eqn" "$(awk '/^  N  *20$/{n=1} n && /^  Equation /{sub(/^  Equation  */,""); print; exit}' "$OUT/$c.log")"
    say "${c}_group_blocks" "$(grep -c 'EML Stats : Regression by group' "$OUT/$c.log")"
    say "${c}_groups_analysed" "$(awk '/^  Analysed /{print $2; exit}' "$OUT/$c.log")"
done
for g in A B; do
    say "drawn_line_${g}" "$(grep -m1 "^  $g: OLS fitted line: " "$OUT/draw_probe.log" | sed 's/^  //')"
    say "draw_probe_reported_eqn_${g}" "$(eqn "$OUT/draw_probe.log" "$g")"
done

echo "regressdoors: wrote $TSV"
