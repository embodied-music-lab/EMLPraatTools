#!/usr/bin/env bash
# ============================================================================
# harness/correlgroup/run.sh — the correlation dialog's grouping menu, driven
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# WHAT THIS EXISTS TO SEE.
#
# Praat has to know a menu's options before it can draw the page. The
# correlation wrapper therefore builds its list of candidate grouping columns
# BEFORE the dialog opens, from the X and Y of the previous pass — and X and Y
# are chosen on that same page. So the list the user is looking at can be the
# wrong list: a column excluded because it was X last time is offered again,
# and a column that has just BECOME X is still on the menu.
#
# Picking that column runs a correlation of a variable against itself, split
# by itself. It does not error. It produces a report, with per-group blocks,
# and every number in it is an artefact of the grouping. That is the shape of
# defect this repository keeps finding: no crash, no red test, a plausible
# answer that is wrong. The guard added 20 Aug refuses exactly that
# combination and rebuilds the list on the way back.
#
# A SOURCE-READING CHECK CANNOT SEE IT. `grpName$ [group_column - 1]` is a
# correct index into a real array. The parse check cannot see it either: the
# file parses whether or not the guard is there. The only thing that shows it
# is pressing the buttons in that order and reading what came out.
#
# ---------------------------------------------------------------------------
# HOW A DIALOG SCRIPT IS DRIVEN WITHOUT A DISPLAY
# ---------------------------------------------------------------------------
# `beginPause:` cannot be scripted — under `praat --run` it takes the process
# down with a Trace/breakpoint trap (harness/GUI_HARNESS_RECIPE.md §0). The
# pattern is harness/edittable/run.sh's: cut every `beginPause:`…`endPause`
# region out MECHANICALLY, replace it with a generated procedure that assigns
# exactly the variables that region's fields would have assigned plus the
# button pressed, and hash the shipped file minus those regions against the
# twin minus the injected lines. Everything between the dialogs — the
# candidate scan, the guard, the analysis — is the shipped bytes, running.
#
# THIS DRIVE NEEDS ONE THING THAT ONE DID NOT, and it is the reason the two
# harnesses are not one file yet. The refusal the guard raises is not drawn by
# the wrapper. It is drawn by @emlErrorDialog in stats/eml-output.praat, which
# the wrapper reaches through `include eml-lib.praat`. Two consequences:
#
#   1. A procedure CANNOT be stubbed by redefining it. Measured on 6.6.30
#      today: a second `procedure foo` warns "Duplicate procedure ... it is
#      unpredictable which of the two definitions will be chosen" and the
#      probe took the FIRST. So the shipped definition has to be replaced in
#      place, in a copy, not shadowed.
#
#   2. @emlErrorDialog cannot be cut the way a wrapper stanza is cut. Its one
#      `beginPause:` has TWO `endPause` lines, one per mode, inside an
#      `if`/`else` — so "cut from beginPause to the first endPause" removes
#      the `if` and leaves the `else`, and "cut to the last" removes the
#      assignment the caller reads. The whole PROCEDURE is replaced instead,
#      between its `procedure` line and its `endproc`, by a stub that records
#      what it was asked to say and takes its answer from the tape. The rest
#      of eml-output.praat is hashed against the shipped file, so the claim
#      is exact: that file as shipped, with its refusal dialog answered here.
#
# The wording inside the refusal is the one thing a stub cannot check, so it
# is read statically out of out/EXCISED_ERRDLG.txt by
# validate/v102_correlate_grouping.R, exactly as v55 reads the editor's.
#
# EVIDENCE, all under out/: CORREL.tsv (every scalar fact), <case>.log (the
# Info window, with the DLG trace and the PROBE lines), EXCISED.txt and
# EXCISED_ERRDLG.txt.
#
#   bash harness/correlgroup/run.sh
#   Rscript validate/v102_correlate_grouping.R
#
# $EML_CORREL_FILE overrides the wrapper under test and $EML_CORREL_DIR the
# evidence folder, so a break test drives the pre-guard file straight out of
# `git show` without going near the shipped one.
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

PLUGIN="$EML_ROOT/plugin"
SRC="${EML_CORREL_FILE:-$PLUGIN/scripts/eml-correlate.praat}"
ERRSRC="$PLUGIN/stats/eml-output.praat"
OUT="${EML_CORREL_DIR:-$SCRIPT_DIR/out}"
PREFS="$SCRIPT_DIR/prefs"
WORK="$OUT/work"

for f in "$SRC" "$ERRSRC"; do
    [[ -f "$f" ]] || { echo "correlgroup: FAIL — missing $f" >&2; exit 1; }
done

rm -rf "$WORK"
mkdir -p "$OUT" "$PREFS" "$WORK"
rm -f "$OUT"/*.log "$OUT/CORREL.tsv" "$OUT/EXCISED.txt" \
      "$OUT/EXCISED_ERRDLG.txt" "$OUT/DIALOGS.tsv"

TSV="$OUT/CORREL.tsv"
: > "$TSV"
say () { printf '%s\t%s\n' "$1" "$2" >> "$TSV"; }

say praat_version "$("$PRAAT" --version 2>&1 | head -1)"
say file_under_test "$(basename "$SRC")"
say file_sha "$(sha256sum < "$SRC" | cut -d' ' -f1)"
say errdlg_file_sha "$(sha256sum < "$ERRSRC" | cut -d' ' -f1)"

# ---------------------------------------------------------------------------
# 1. THE PLUGIN TREE IS COPIED, NOT POINTED AT
# ---------------------------------------------------------------------------
# `include` resolves against the folder of the script that was RUN, so the
# twin has to sit where the wrapper sits, beside a full plugin. Copying also
# means the shipped tree cannot be touched by anything below, which is the
# property harness/edittable relies on and the reason a shadow build was able
# to render silently once.
TREE="$WORK/plugin"
mkdir -p "$TREE"
cp -R "$PLUGIN"/. "$TREE"/ 2>/dev/null

# ---------------------------------------------------------------------------
# 2. LOCATE THE WRAPPER'S PAUSE STANZAS
# ---------------------------------------------------------------------------
# MECHANICAL, AND FATAL WHEN IT IS UNSURE. A nested or unterminated stanza
# means the boundaries are guesses, and a guessed boundary cuts part of the
# wrapper's FLOW out of the thing under test. A stanza with more than one
# `endPause` is refused for the same reason — that is the shape @emlErrorDialog
# has, and it is handled by whole-procedure replacement below, not by cutting.
MAP="$OUT/DIALOGS.tsv"
awk '
function indent(s,   t) { t = s; sub(/[^ \t].*/, "", t); return length(t) }
/^[ \t]*beginPause: /{
    if (inb) { printf "correlgroup: FAIL - nested beginPause at line %d\n", NR > "/dev/stderr"; exit 2 }
    inb = 1; start = NR; bi = indent($0); seen = 0
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
    if (inb) { printf "correlgroup: FAIL - unterminated beginPause at line %d\n", start > "/dev/stderr"; exit 2 }
    if (idx == 0) { print "correlgroup: FAIL - no pause stanzas found" > "/dev/stderr"; exit 2 }
}
' "$SRC" > "$MAP" || exit 1

N_STANZA=$(wc -l < "$MAP")
say stanza_count "$N_STANZA"

declare -A KEY_OF_IDX=() IDX_OF_KEY=() OCC=()
declare -a S_START=() S_END=() S_BI=() S_EI=() S_TGT=()
while IFS=$'\t' read -r idx st en bi ei tgt title; do
    slug=$(printf '%s' "$title" | tr '[:upper:]' '[:lower:]' \
           | sed -E 's/[^a-z0-9]+/_/g; s/^_+//; s/_+$//')
    [[ -z "$slug" ]] && slug="untitled"
    OCC[$slug]=$(( ${OCC[$slug]:-0} + 1 ))
    key="${slug}#${OCC[$slug]}"
    KEY_OF_IDX[$idx]="$key"; IDX_OF_KEY[$key]="$idx"
    S_START[$idx]="$st"; S_END[$idx]="$en"
    S_BI[$idx]="$bi"; S_EI[$idx]="$ei"; S_TGT[$idx]="$tgt"
done < "$MAP"

for i in $(seq 1 "$N_STANZA"); do
    say "stanza_${i}_key" "${KEY_OF_IDX[$i]}"
done

# ---------------------------------------------------------------------------
# 3. THE WRAPPER TWIN
# ---------------------------------------------------------------------------
TWIN="$TREE/scripts/$(basename "$SRC")"
{
    prev=0
    for i in $(seq 1 "$N_STANZA"); do
        st=${S_START[$i]}; en=${S_END[$i]}
        if (( st <= prev )); then
            echo "correlgroup: FAIL — stanza $i out of order" >&2; exit 1
        fi
        sed -n "$((prev + 1)),$((st - 1))p" "$SRC"
        printf '%*s@dlg%d\n' "${S_BI[$i]}" "" "$i"
        if [[ "${S_TGT[$i]}" != "-" ]]; then
            printf '%*s%s = dlg_clicked\n' "${S_EI[$i]}" "" "${S_TGT[$i]}"
        fi
        prev=$en
    done
    sed -n "$((prev + 1)),\$p" "$SRC"
} > "$WORK/twin_base.praat" || exit 1

# The tape is included immediately after the wrapper's own include line, which
# is the first point at which a top-level statement here is legal. Praat
# flattens every include into one script, so one tape file serves both the
# wrapper's generated procedures and the error-dialog stub.
awk 'NR==1{done=0} {print} !done && /^include eml-lib\.praat$/{print "include _dlg.praat"; done=1}' \
    "$WORK/twin_base.praat" > "$TWIN"
if ! grep -qx 'include _dlg.praat' "$TWIN"; then
    echo "correlgroup: FAIL — the wrapper's 'include eml-lib.praat' line moved;" >&2
    echo "       the tape has nowhere to go in." >&2
    exit 1
fi

{
    echo "# Cut from $(basename "$SRC") to make the headless twin."
    for i in $(seq 1 "$N_STANZA"); do
        echo "# --- stanza $i  (${KEY_OF_IDX[$i]})  lines ${S_START[$i]}-${S_END[$i]}"
        sed -n "${S_START[$i]},${S_END[$i]}p" "$SRC"
    done
} > "$OUT/EXCISED.txt"

DELSED="$WORK/del.sed"
: > "$DELSED"
for i in $(seq 1 "$N_STANZA"); do
    printf '%d,%dd\n' "${S_START[$i]}" "${S_END[$i]}" >> "$DELSED"
done
sed -f "$DELSED" "$SRC" > "$WORK/body_shipped.txt"
grep -vxE '[ \t]*@dlg[0-9]+|[ \t]*[A-Za-z_.][A-Za-z_0-9.]* = dlg_clicked|include _dlg\.praat' \
    "$TWIN" > "$WORK/body_twin.txt"

sha_shipped=$(sha256sum < "$WORK/body_shipped.txt" | cut -d' ' -f1)
sha_twin=$(sha256sum < "$WORK/body_twin.txt" | cut -d' ' -f1)
say twin_body_sha_shipped "$sha_shipped"
say twin_body_sha_twin "$sha_twin"
say twin_body_identical "$([[ "$sha_shipped" == "$sha_twin" ]] && echo 1 || echo 0)"

if [[ "$sha_shipped" != "$sha_twin" ]]; then
    echo "correlgroup: FAIL — twin body differs from shipped body." >&2
    diff "$WORK/body_shipped.txt" "$WORK/body_twin.txt" | head -20 >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# 4. THE ERROR DIALOG, REPLACED WHOLE
# ---------------------------------------------------------------------------
# Bounds are the `procedure emlErrorDialog:` line and the first `endproc` at
# column zero after it. Both are asserted to exist and to be in that order; a
# rename or a reflow stops the run rather than silently replacing the wrong
# span.
EB=$(awk '/^procedure emlErrorDialog: /{print NR; exit}' "$ERRSRC")
EE=$(awk -v s="$EB" 'NR>s && /^endproc$/{print NR; exit}' "$ERRSRC")
if [[ -z "$EB" || -z "$EE" ]] || (( EE <= EB )); then
    echo "correlgroup: FAIL — could not bound @emlErrorDialog in $ERRSRC" >&2
    exit 1
fi
say errdlg_lines "$EB-$EE"
sed -n "${EB},${EE}p" "$ERRSRC" > "$OUT/EXCISED_ERRDLG.txt"

ERRTWIN="$TREE/stats/eml-output.praat"
{
    sed -n "1,$((EB - 1))p" "$ERRSRC"
    cat <<'STUB'
procedure emlErrorDialog: .msg$, .remedy$, .mode$
    @errdlg: .msg$, .remedy$, .mode$
    .clicked = errdlg.clicked
    .back = errdlg.back
endproc
STUB
    sed -n "$((EE + 1)),\$p" "$ERRSRC"
} > "$ERRTWIN"

# The same proof as the wrapper's, on the other file: everything OUTSIDE the
# replaced procedure is the shipped bytes.
sed "${EB},${EE}d" "$ERRSRC" > "$WORK/errbody_shipped.txt"
sed "${EB},$((EB + 4))d" "$ERRTWIN" > "$WORK/errbody_twin.txt"
esha_shipped=$(sha256sum < "$WORK/errbody_shipped.txt" | cut -d' ' -f1)
esha_twin=$(sha256sum < "$WORK/errbody_twin.txt" | cut -d' ' -f1)
say errdlg_body_identical \
    "$([[ "$esha_shipped" == "$esha_twin" ]] && echo 1 || echo 0)"
if [[ "$esha_shipped" != "$esha_twin" ]]; then
    echo "correlgroup: FAIL — eml-output.praat outside the stub is not shipped." >&2
    diff "$WORK/errbody_shipped.txt" "$WORK/errbody_twin.txt" | head -20 >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# 5. THE TAPE
# ---------------------------------------------------------------------------
# A case is a list of raw Praat lines filed under (dialog, visit number),
# pasted verbatim into the generated procedure. EVERY UNSCRIPTED VISIT PRESSES
# BUTTON 1 — Quit on the main form, Done on the post-analysis form, Quit on
# the refusal — so a case that walks somewhere it did not plan for unwinds
# instead of looping, and the DLG trace shows where it went. The refusal is
# keyed `errdlg` and is taped like any other dialog.
declare -A TAPE=() MAXVISIT=()
ERRKEY="errdlg"

tape_reset () { TAPE=(); MAXVISIT=(); }

tape () {                     # tape <key> <visit> <praat line> [<praat line>...]
    local key="$1" visit="$2"; shift 2
    local idx
    if [[ "$key" == "$ERRKEY" ]]; then
        idx="E"
    else
        idx="${IDX_OF_KEY[$key]:-}"
        if [[ -z "$idx" ]]; then
            echo "correlgroup: FAIL — no dialog keyed '$key' in $(basename "$SRC")" >&2
            echo "       known keys: ${!IDX_OF_KEY[*]} $ERRKEY" >&2
            exit 1
        fi
    fi
    local body="" l
    for l in "$@"; do body+="        $l"$'\n'; done
    TAPE["$idx,$visit"]="$body"
    if (( visit > ${MAXVISIT[$idx]:-0} )); then MAXVISIT[$idx]=$visit; fi
}

emit_dlg () {                 # emit_dlg <dir>
    local dir="$1" f="$1/_dlg.praat" i v
    {
        echo "# Generated by harness/correlgroup/run.sh. Not part of the plugin."
        echo "dlgBudget = 0"
        for i in $(seq 1 "$N_STANZA"); do echo "dlgV$i = 0"; done
        echo "dlgVE = 0"
        for i in $(seq 1 "$N_STANZA") E; do
            echo ""
            if [[ "$i" == "E" ]]; then
                echo "procedure errdlg: .msg\$, .remedy\$, .mode\$"
            else
                echo "procedure dlg$i"
            fi
            echo "    dlgBudget = dlgBudget + 1"
            echo "    if dlgBudget > 200"
            echo "        exitScript: \"TWIN: dialog budget exceeded\""
            echo "    endif"
            echo "    dlgV$i = dlgV$i + 1"
            echo "    dlg_clicked = 1"
            if [[ "$i" == "E" ]]; then
                echo "    appendInfoLine: \"ERRMSG|\", .msg\$"
            fi
            local first=1
            for v in $(seq 1 "${MAXVISIT[$i]:-0}"); do
                [[ -z "${TAPE[$i,$v]:-}" ]] && continue
                if (( first )); then
                    echo "    if dlgV$i = $v"; first=0
                else
                    echo "    elsif dlgV$i = $v"
                fi
                printf '%s' "${TAPE[$i,$v]}"
            done
            (( first )) || echo "    endif"
            if [[ "$i" == "E" ]]; then
                echo "    .clicked = dlg_clicked"
                echo "    .back = (dlg_clicked = 2)"
                echo "    appendInfoLine: \"DLG|E|errdlg|visit=\", dlgVE, \"|clicked=\", dlg_clicked"
            else
                echo "    appendInfoLine: \"DLG|$i|${KEY_OF_IDX[$i]}|visit=\", dlgV$i, \"|clicked=\", dlg_clicked"
            fi
            echo "endproc"
        done
    } > "$f"
}

# ---------------------------------------------------------------------------
# 6. ONE DRIVE
# ---------------------------------------------------------------------------
run_case () {                 # run_case <name>
    local name="$1"
    local dir="$WORK/$name"
    mkdir -p "$dir"
    cp -R "$TREE"/. "$dir"/
    emit_dlg "$dir/scripts"
    {
        echo "# Fixture + hand-off for case $name."
        cat "$FIXTURE"
        echo "appendInfoLine: \"CASE handoff\""
        echo "selectObject: tableId"
        echo "runScript: \"scripts/$(basename "$SRC")\""
        echo "appendInfoLine: \"CASE returned\""
        echo "appendInfoLine: \"CASE done\""
    } > "$dir/case.praat"

    ( env -u DISPLAY timeout 180 "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" \
        --run "$dir/case.praat" > "$dir/run.log" 2>&1 )
    local rc=$?
    say "${name}_exit" "$rc"
    sed "s|$WORK|<WORK>|g" "$dir/run.log" > "$OUT/$name.log"
    say "${name}_returned" "$(grep -c '^CASE returned$' "$dir/run.log")"
    say "${name}_dlg_trace" \
        "$(grep -o 'DLG|[A-Z0-9]*|[^|]*|' "$dir/run.log" | cut -d'|' -f3 | paste -sd, -)"
    # Did a correlation report actually print? The report's own header line is
    # the witness, counted rather than searched for, because "was a grouped
    # analysis run" is precisely the question the guard answers.
    say "${name}_reports" "$(grep -c 'EML Stats : Correlation Analysis' "$dir/run.log")"
    say "${name}_grouped_blocks" "$(grep -c 'EML Stats : Correlation by ' "$dir/run.log")"
    say "${name}_grouped_by" "$(grep -o 'EML Stats : Correlation by .*' "$dir/run.log" | sed 's/^EML Stats : Correlation by //' | paste -sd, -)"
    say "${name}_errmsgs" "$(grep -c '^ERRMSG|' "$dir/run.log")"
    say "${name}_errmsg_first" "$(grep -m1 '^ERRMSG|' "$dir/run.log" | tr '\t' ' ')"
    say "${name}_stderr_head" "$(grep -m1 '^Error' "$dir/run.log" | tr '\t' ' ')"
}

# ---------------------------------------------------------------------------
# 7. THE FIXTURE
# ---------------------------------------------------------------------------
# Nine rows, and every column's eligibility as a grouping column is decided by
# arithmetic the wrapper does rather than by anything asserted here: the
# ceiling is min(12, max(2, floor(9/3))) = 3 distinct levels.
#
#   subj  nine distinct labels   -> over the ceiling, never offered
#   dose  three levels, NUMERIC  -> offered, and legal as X or Y. This is the
#                                   column the defect needs: something that
#                                   can be on the grouping menu one pass and
#                                   bound to X the next.
#   site  two levels             -> offered, and the column that proves the
#                                   list was REBUILT after a refusal
#   x, y  nine distinct numbers  -> over the ceiling, never offered
FIXTURE="$WORK/fixture.praat"
cat > "$FIXTURE" <<'EOF'
Create Table with column names: "t", 9, "subj dose site x y"
tableId = selected ("Table")
for r to 9
    selectObject: tableId
    Set string value: r, "subj", "S" + string$ (r)
    Set numeric value: r, "dose", (r mod 3) + 1
    Set string value: r, "site", if r <= 5 then "north" else "south" fi
    Set numeric value: r, "x", r * 1.7 + 0.3
    Set numeric value: r, "y", r * 2.1 - 0.4 + (r mod 2) * 0.6
endfor
selectObject: tableId
EOF

# ---------------------------------------------------------------------------
# 8. THE CASES
# ---------------------------------------------------------------------------
K_MAIN="correlate_two_columns#1"
K_DONE="analysis_complete#1"

# ---------------------------------------------------------------------------
# G_stale — THE DEFECT. Run once on x/y, press New, move X onto "dose", and
# pick "dose" as the grouping column — which the menu is still offering,
# because it was built when X was "x".
# ---------------------------------------------------------------------------
# Pre-guard this correlates dose against y, split by dose, and prints it. The
# guard refuses instead. The third visit's probe prints the rebuilt candidate
# list: with X now "dose", the only remaining candidate is "site" — which is
# what "coming back rebuilds the list" has to mean to be worth saying.
tape_reset
tape "$K_MAIN" 1 'column_X$ = "x"' 'column_Y$ = "y"' 'group_column = 1' \
                 'test = 1' 'clear_Info_window = 0' \
                 'dlg_clicked = 2'
tape "$K_DONE" 1 'dlg_clicked = 4'
tape "$K_MAIN" 2 'appendInfoLine: "PROBE|list2|n=", grpN, "|1=", grpName$ [1], "|2=", grpName$ [2]' \
                 'column_X$ = "dose"' 'column_Y$ = "y"' 'group_column = 2' \
                 'test = 1' 'clear_Info_window = 0' \
                 'dlg_clicked = 2'
tape "$ERRKEY" 1 'dlg_clicked = 2'
tape "$K_MAIN" 3 'appendInfoLine: "PROBE|list3|n=", grpN, "|1=", grpName$ [1]' \
                 'dlg_clicked = 1'
run_case G_stale

# ---------------------------------------------------------------------------
# H_legit — the regression arm. The same grouping column, chosen without
# moving X onto it, must run on the first press and print its groups.
# ---------------------------------------------------------------------------
tape_reset
tape "$K_MAIN" 1 'column_X$ = "x"' 'column_Y$ = "y"' 'group_column = 1' \
                 'test = 1' 'clear_Info_window = 0' \
                 'dlg_clicked = 2'
tape "$K_DONE" 1 'dlg_clicked = 4'
tape "$K_MAIN" 2 'column_X$ = "x"' 'column_Y$ = "y"' 'group_column = 2' \
                 'test = 1' 'clear_Info_window = 0' \
                 'dlg_clicked = 2'
tape "$K_DONE" 2 'dlg_clicked = 1'
run_case H_legit

# ---------------------------------------------------------------------------
# K_movedok — the guard must not charge an ordinary change of X a press.
# X moves from "x" to "subj"... no: X moves to a column that is NOT the one
# chosen as the group. Grouping by "site" while X moves onto "dose" is legal
# and must run on the first press, with no refusal in the trace.
# ---------------------------------------------------------------------------
tape_reset
tape "$K_MAIN" 1 'column_X$ = "x"' 'column_Y$ = "y"' 'group_column = 1' \
                 'test = 1' 'clear_Info_window = 0' \
                 'dlg_clicked = 2'
tape "$K_DONE" 1 'dlg_clicked = 4'
tape "$K_MAIN" 2 'column_X$ = "dose"' 'column_Y$ = "y"' 'group_column = 3' \
                 'test = 1' 'clear_Info_window = 0' \
                 'dlg_clicked = 2'
tape "$K_DONE" 2 'dlg_clicked = 1'
run_case K_movedok

# ---------------------------------------------------------------------------
# 9. REPORT
# ---------------------------------------------------------------------------
say completed 1

printf '%-12s %-5s %-8s %-8s %s\n' case exit reports grouped refusals
for c in G_stale H_legit K_movedok; do
    printf '%-12s %-5s %-8s %-8s %s\n' "$c" \
        "$(awk -F'\t' -v k="${c}_exit" '$1==k{print $2}' "$TSV")" \
        "$(awk -F'\t' -v k="${c}_reports" '$1==k{print $2}' "$TSV")" \
        "$(awk -F'\t' -v k="${c}_grouped_blocks" '$1==k{print $2}' "$TSV")" \
        "$(awk -F'\t' -v k="${c}_errmsgs" '$1==k{print $2}' "$TSV")"
done
echo
echo "stanzas: $N_STANZA   wrapper body identical: $(awk -F'\t' '$1=="twin_body_identical"{print $2}' "$TSV")   output body identical: $(awk -F'\t' '$1=="errdlg_body_identical"{print $2}' "$TSV")"
echo "evidence: $OUT/CORREL.tsv, $(ls "$OUT"/*.log 2>/dev/null | wc -l) log"
echo
echo "Now run: Rscript validate/v102_correlate_grouping.R"
