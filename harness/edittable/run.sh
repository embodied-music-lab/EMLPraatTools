#!/usr/bin/env bash
# ============================================================================
# harness/edittable/run.sh — the Table editor's column addressing, driven
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# WHAT THIS EXISTS TO SEE, AND WHY NOTHING ELSE COULD SEE IT.
#
# plugin/scripts/eml-edit-table.praat is the only EML entry point that WRITES
# to a user's table. Every other module reads a table and produces a report, a
# figure or a new object; this one mutates the thing the user has been typing
# into all afternoon. That asymmetry is the whole reason this harness is a
# separate tree from harness/tabwalk, which walks the editor's menus and asks
# whether they open.
#
# The defect it was built for is invisible to every check the repository had.
# Praat's Table API addresses columns BY LABEL — `Remove column: name$`,
# `Get value: row, name$`, `Set string value: row, name$, v$` — and labels are
# not unique. Praat itself will happily make them non-unique: `Rename column
# (by number)`, `Append column` and `Insert column` all accept a name that a
# sibling column already carries (measured, 6.6.30, 15 Aug 2026), and a CSV
# read from disk can arrive with duplicates already in it. The editor's menus
# are POSITIONAL — an optionmenu returns the index the user clicked — and
# before 15 Aug 2026 every operation threw that index away and passed the
# label string. With two columns called "colA", picking the second one and
# pressing Delete deleted the first one's data. No warning, no undo, and the
# resulting table is a perfectly well-formed CSV that says the wrong thing.
#
# A source-reading check cannot see this: `Remove column: column_to_delete$`
# is a correct call to a real command with a real argument. A menu-walking
# check cannot see it either: every dialog opens, every button responds, and
# the operation completes. The only thing that shows it is a table with two
# columns of the same name and different CONTENTS, operated on through the
# shipped code, and then read back. That is what every case below is.
#
# WHY A DERIVED TWIN, AND WHY IT IS STILL EVIDENCE ABOUT THE SHIPPED FILE.
#
# `beginPause:` cannot be scripted — under `praat --run` it takes the process
# down with a Trace/breakpoint trap (harness/GUI_HARNESS_RECIPE.md §0), and
# this script is ALL dialog: twenty pause stanzas, with the editing loop, the
# find/replace loop and the structure menu built out of
# them. harness/batch/run.sh met the same wall and answered it by excising its
# two dialog stanzas by line number from anchors that must be unique, then
# hashing the shipped file minus those regions against the twin minus its
# injected lines. That is the pattern used here, generalised from two stanzas
# to all of them: every `beginPause:` … `endPause` region is located
# MECHANICALLY (a nested or unterminated stanza is fatal, not repaired),
# replaced by a call to a generated `@dlgN` that assigns exactly the variables
# that stanza's fields would have assigned plus the button that was pressed,
# and the two bodies are hashed and must match. out/EXCISED.txt holds every
# removed byte so a reader can check that what went is dialog and nothing
# else. Everything between the dialogs — the loop, the clamps, the column-name
# snapshot, the addressing, the structure branches — is the shipped bytes,
# running.
#
# THE ONE THING THE TWIN CANNOT SEE is the WORDING inside a stanza, because
# the wording is the part that was cut. So the refusal messages are checked
# from out/EXCISED.txt, statically, by validate/v55_editor_addressing.R, while
# the BEHAVIOUR around them — that the refusal fired, that nothing was deleted,
# that the loop came back rather than dying — is measured here. Both halves
# are needed and neither substitutes for the other; a refusal with perfect
# prose that does not stop the delete is the defect, and a silent refusal that
# does stop it is a bug report waiting to happen.
#
# THE ELEVEN DRIVES. Nine of them fail differently before 15 Aug 2026; the
# last two exercise paths that did not exist before it.
#
#   A_rename_dup   rename column 3 to the name column 2 already carries.
#                  BEFORE: succeeds silently, and the table now has two
#                  columns called colA. AFTER: refused, table untouched.
#   B_delete_dup   a table that ARRIVES with duplicate labels (what a CSV
#                  hands you). Pick menu entry 3 — the B-data column — and
#                  press Delete. BEFORE: the A-data column dies. This is the
#                  verifier's case, byte for byte against their CSVs.
#   C_cell_dup     read and then write a cell in menu entry 3 of the same
#                  table. BEFORE: reads and writes entry 2.
#   D_repall_dup   Replace All scoped to menu entry 3. BEFORE: rewrites
#                  entry 2 and reports the count as if it had worked.
#   E_onecol       Delete Column on a one-column table. Praat forbids a
#                  zero-column Table (measured: `Create Table without column
#                  names: "t", 3, 0` is refused), so the guard's `< 1` can
#                  never fire and the call reaches Praat's hard "cannot
#                  remove my only column". BEFORE: the session dies and the
#                  read-only TableEditor is left open behind it.
#   F_add_dup      Add column at end, naming it after an existing column.
#   G_insert_dup   Insert column at position, same.
#   H_plain        the ordinary table, no duplicates anywhere: read, set,
#                  rename, insert, delete. The regression arm — the fix
#                  renames columns to a private sentinel and back, and this
#                  is what proves the sentinel never survives the operation
#                  and the ordinary path still does what it did.
#   I_findnav      Find on a duplicate table, checking that the row/column
#                  the search reports is the one the search actually read.
#   J_rename_back  the recovery arm: refuse a name, press Back, and check
#                  that the form comes back holding the user's column and
#                  the text they typed, then finish the rename properly.
#   K_autolabel    an unlabeled column whose invented name — "Column_3" — is
#                  already taken by column 1. The snapshot that exists to
#                  make a table addressable was the third way to make it
#                  ambiguous.
#
# EVIDENCE, all under out/: EDIT.tsv (every scalar fact), <case>.csv (the
# table as the shipped code left it), <case>.log (the Info window, including
# the DLG trace naming every dialog reached in order), DIALOGS.tsv (the stanza
# map the twin was cut from) and EXCISED.txt. v55 reads all of it.
#
#   bash harness/edittable/run.sh
#   Rscript validate/v55_editor_addressing.R
#
# $EML_EDITTABLE_FILE overrides the file under test and $EML_EDITTABLE_DIR the
# evidence folder, so a break test drives a deliberately damaged copy — or the
# pre-fix file straight out of `git show` — without going near the shipped
# one. Both are the names harness/batch already uses.
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

SRC="${EML_EDITTABLE_FILE:-$EML_ROOT/plugin/scripts/eml-edit-table.praat}"
OUT="${EML_EDITTABLE_DIR:-$SCRIPT_DIR/out}"
PREFS="$SCRIPT_DIR/prefs"
WORK="$OUT/work"

if [[ ! -f "$SRC" ]]; then
    echo "edittable: FAIL — no editor at $SRC" >&2
    exit 1
fi

# The work tree is rebuilt from nothing every run, for the reason
# harness/batch/run.sh gives: a table left over from a previous case changes
# what the next case is measuring without changing a line of code.
rm -rf "$WORK"
mkdir -p "$OUT" "$PREFS" "$WORK"
rm -f "$OUT"/*.csv "$OUT"/*.log "$OUT/EDIT.tsv" "$OUT/EXCISED.txt" \
      "$OUT/DIALOGS.tsv"

TSV="$OUT/EDIT.tsv"
: > "$TSV"
say () { printf '%s\t%s\n' "$1" "$2" >> "$TSV"; }

say praat_version "$("$PRAAT" --version 2>&1 | head -1)"
say file_under_test "$(basename "$SRC")"
say file_sha "$(sha256sum < "$SRC" | cut -d' ' -f1)"
say shipped_total_lines "$(wc -l < "$SRC")"

# ---------------------------------------------------------------------------
# 1. LOCATE EVERY PAUSE STANZA
# ---------------------------------------------------------------------------
# MECHANICAL, AND FATAL WHEN IT IS UNSURE. A stanza that opens inside another
# stanza, or one that never closes, means the region boundaries are guesses —
# and a guessed boundary cuts a piece of the editor's FLOW out of the thing
# under test, after which every case below passes over code no user runs.
MAP="$OUT/DIALOGS.tsv"
awk '
function indent(s,   t) { t = s; sub(/[^ \t].*/, "", t); return length(t) }
/^[ \t]*beginPause: /{
    if (inb) { printf "edittable: FAIL - nested beginPause at line %d\n", NR > "/dev/stderr"; exit 2 }
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
    inb = 0
    next
}
END{
    if (inb) { printf "edittable: FAIL - unterminated beginPause at line %d\n", start > "/dev/stderr"; exit 2 }
    if (idx == 0) { print "edittable: FAIL - no pause stanzas found" > "/dev/stderr"; exit 2 }
}
' "$SRC" > "$MAP" || exit 1

N_STANZA=$(wc -l < "$MAP")
say stanza_count "$N_STANZA"

# Symbolic keys, so a case tape names a dialog rather than a line number: the
# first quoted literal of the title, slugged, plus an occurrence counter for
# the titles that repeat (three "EML Table Editor", two "Add Column").
declare -A KEY_OF_IDX=() IDX_OF_KEY=() SLUG_OF_IDX=() OCC=()
declare -a S_START=() S_END=() S_BI=() S_EI=() S_TGT=()
while IFS=$'\t' read -r idx st en bi ei tgt title; do
    slug=$(printf '%s' "$title" | tr '[:upper:]' '[:lower:]' \
           | sed -E 's/[^a-z0-9]+/_/g; s/^_+//; s/_+$//')
    [[ -z "$slug" ]] && slug="untitled"
    OCC[$slug]=$(( ${OCC[$slug]:-0} + 1 ))
    key="${slug}#${OCC[$slug]}"
    KEY_OF_IDX[$idx]="$key"; IDX_OF_KEY[$key]="$idx"; SLUG_OF_IDX[$idx]="$slug"
    S_START[$idx]="$st"; S_END[$idx]="$en"
    S_BI[$idx]="$bi"; S_EI[$idx]="$ei"; S_TGT[$idx]="$tgt"
done < "$MAP"

# The map itself is committed evidence: v55 asserts the editor still has the
# dialogs it is supposed to have, in the order it is supposed to have them.
for i in $(seq 1 "$N_STANZA"); do
    say "stanza_${i}_key" "${KEY_OF_IDX[$i]}"
done

# ---------------------------------------------------------------------------
# 2. DERIVE THE HEADLESS TWIN
# ---------------------------------------------------------------------------
TWIN="$WORK/twin.praat"
{
    prev=0
    for i in $(seq 1 "$N_STANZA"); do
        st=${S_START[$i]}; en=${S_END[$i]}
        if (( st <= prev )); then
            echo "edittable: FAIL — stanza $i out of order" >&2; exit 1
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

# The tape file is included immediately after `endform`, which is the first
# point at which a top-level statement in this script is legal.
awk 'NR==1{done=0} {print} !done && /^endform$/{print "include _dlg.praat"; done=1}' \
    "$WORK/twin_base.praat" > "$TWIN"

{
    echo "# Cut from $(basename "$SRC") to make the headless twin."
    echo "# Every beginPause:/endPause region, in file order."
    for i in $(seq 1 "$N_STANZA"); do
        echo "# --- stanza $i  (${KEY_OF_IDX[$i]})  lines ${S_START[$i]}-${S_END[$i]}"
        sed -n "${S_START[$i]},${S_END[$i]}p" "$SRC"
    done
} > "$OUT/EXCISED.txt"

# THE PROOF. Shipped minus the stanza regions, against twin minus the lines
# the harness put in. Anything else that differs is a twin that is not the
# editor, and v55 refuses the whole run on it.
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
say twin_excised_lines "$(( $(wc -l < "$SRC") - $(wc -l < "$WORK/body_shipped.txt") ))"

if [[ "$sha_shipped" != "$sha_twin" ]]; then
    echo "edittable: FAIL — twin body differs from shipped body." >&2
    diff "$WORK/body_shipped.txt" "$WORK/body_twin.txt" | head -20 >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# 3. THE TAPE
# ---------------------------------------------------------------------------
# A case is a list of raw Praat lines, filed under (dialog, visit number). The
# lines are pasted verbatim into the generated `@dlgN`, so a tape entry can
# assign a field variable, press a button (`dlg_clicked = 3`), or print a
# probe of a variable the shipped code has just computed. Nothing is
# translated on the way in, which means a reader of a case below is reading
# what the twin runs.
#
# EVERY UNSCRIPTED VISIT PRESSES BUTTON 1. On this editor button 1 is Quit or
# Go Back or OK on all nineteen stanzas, so a case that walks somewhere it did
# not plan for unwinds instead of looping — and the DLG trace in the log shows
# exactly where it went. A budget of 300 dialog visits catches the rest.
declare -A TAPE=() MAXVISIT=()

tape_reset () { TAPE=(); MAXVISIT=(); }

tape () {                     # tape <key> <visit> <praat line> [<praat line>...]
    local key="$1" visit="$2"; shift 2
    local idx="${IDX_OF_KEY[$key]:-}"
    if [[ -z "$idx" ]]; then
        echo "edittable: FAIL — no dialog keyed '$key' in $(basename "$SRC")" >&2
        echo "       known keys: ${!IDX_OF_KEY[*]}" >&2
        exit 1
    fi
    local body=""
    local l
    for l in "$@"; do body+="        $l"$'\n'; done
    TAPE["$idx,$visit"]="$body"
    if (( visit > ${MAXVISIT[$idx]:-0} )); then MAXVISIT[$idx]=$visit; fi
}

emit_dlg () {                 # emit_dlg <case dir>
    local dir="$1" f="$1/_dlg.praat" i v
    {
        echo "# Generated by harness/edittable/run.sh. Not part of the plugin."
        echo "dlgBudget = 0"
        for i in $(seq 1 "$N_STANZA"); do echo "dlgV$i = 0"; done
        for i in $(seq 1 "$N_STANZA"); do
            echo ""
            echo "procedure dlg$i"
            echo "    dlgBudget = dlgBudget + 1"
            echo "    if dlgBudget > 300"
            echo "        exitScript: \"TWIN: dialog budget exceeded\""
            echo "    endif"
            echo "    dlgV$i = dlgV$i + 1"
            echo "    dlg_clicked = 1"
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
            echo "    appendInfoLine: \"DLG|$i|${KEY_OF_IDX[$i]}|visit=\", dlgV$i, \"|clicked=\", dlg_clicked"
            echo "endproc"
        done
    } > "$f"
}

# ---------------------------------------------------------------------------
# 4. ONE DRIVE
# ---------------------------------------------------------------------------
# Each case gets its own folder holding a copy of the twin, its generated tape
# and its fixture, because `include` and `runScript:` both resolve against the
# folder of the script that was RUN. Its own folder also means nine cases
# cannot see each other's tables.
run_case () {                 # run_case <name> <fixture praat body file>
    local name="$1" fixture="$2"
    local dir="$WORK/$name"
    mkdir -p "$dir"
    cp "$TWIN" "$dir/twin.praat"
    emit_dlg "$dir"
    {
        echo "# Fixture + hand-off for case $name."
        cat "$fixture"
        echo "selectObject: tableId"
        echo "Save as comma-separated file: \"$dir/before.csv\""
        echo "appendInfoLine: \"CASE handoff\""
        echo "selectObject: tableId"
        echo "runScript: \"twin.praat\", \"editor\""
        echo "appendInfoLine: \"CASE returned\""
        echo "selectObject: tableId"
        echo "Save as comma-separated file: \"$dir/after.csv\""
        echo "appendInfoLine: \"CASE labels|\", do\$ (\"Get column label...\", 1)"
        echo "appendInfoLine: \"CASE ncols|\", do (\"Get number of columns\")"
        echo "appendInfoLine: \"CASE done\""
    } > "$dir/case.praat"

    ( env -u DISPLAY timeout 120 "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" \
        --run "$dir/case.praat" > "$dir/run.log" 2>&1 )
    local rc=$?
    say "${name}_exit" "$rc"
    sed "s|$WORK|<WORK>|g" "$dir/run.log" > "$OUT/$name.log"
    if [[ -f "$dir/after.csv" ]]; then
        cp "$dir/after.csv" "$OUT/$name.csv"
        say "${name}_after_header" "$(head -1 "$dir/after.csv")"
        say "${name}_after_row1" "$(sed -n '2p' "$dir/after.csv")"
        say "${name}_after_ncols" "$(head -1 "$dir/after.csv" | awk -F, '{print NF}')"
    else
        say "${name}_after_header" "-"
        say "${name}_after_row1" "-"
        say "${name}_after_ncols" -1
    fi
    say "${name}_returned" "$(grep -c '^CASE returned$' "$dir/run.log")"
    say "${name}_dlg_trace" \
        "$(grep -o 'DLG|[0-9]*|[^|]*|' "$dir/run.log" | cut -d'|' -f3 | paste -sd, -)"
    say "${name}_stderr_head" "$(grep -m1 '^Error' "$dir/run.log" | tr '\t' ' ')"
}

# The fixtures. Two shapes only, and the duplicate one is built the way a CSV
# hands it over — the labels are made identical BEFORE the editor ever sees
# the table, so the containment layer is tested on its own and does not
# depend on the prevention layer having a hole in it.
FIX="$WORK/fixtures"
mkdir -p "$FIX"

cat > "$FIX/plain.praat" <<'EOF'
Create Table with column names: "t", 3, "id colA colB"
tableId = selected ("Table")
for r to 3
    selectObject: tableId
    Set string value: r, "id", "S" + string$ (r)
    Set string value: r, "colA", "A" + string$ (r)
    Set string value: r, "colB", "B" + string$ (r)
endfor
EOF

cat > "$FIX/dup.praat" <<'EOF'
Create Table with column names: "t", 3, "id colA colB"
tableId = selected ("Table")
for r to 3
    selectObject: tableId
    Set string value: r, "id", "S" + string$ (r)
    Set string value: r, "colA", "A" + string$ (r)
    Set string value: r, "colB", "B" + string$ (r)
endfor
# The duplicate arrives with the data, exactly as a CSV would deliver it.
selectObject: tableId
Rename column (by number): 3, "colA"
EOF

cat > "$FIX/blank.praat" <<'EOF'
Create Table with column names: "t", 3, "Column_3 b c"
tableId = selected ("Table")
for r to 3
    selectObject: tableId
    Set string value: r, "Column_3", "P" + string$ (r)
    Set string value: r, "b", "Q" + string$ (r)
    Set string value: r, "c", "R" + string$ (r)
endfor
# Column 3 loses its label, and the name the editor would invent for it is
# already taken by column 1.
selectObject: tableId
Rename column (by number): 3, ""
EOF

cat > "$FIX/onecol.praat" <<'EOF'
Create Table with column names: "t", 3, "only"
tableId = selected ("Table")
for r to 3
    selectObject: tableId
    Set string value: r, "only", "V" + string$ (r)
endfor
EOF

# Shorthands for the three dialogs every structural case walks through.
K_MAIN="eml_table_editor#3"
K_STRUCT="table_structure#1"
K_DELCOL="delete_column#1"
K_RENCOL="rename_column#1"
K_ADDCOL="add_column#2"
K_INSCOL="insert_column#1"
K_FR="find_replace#1"

# ---------------------------------------------------------------------------
# A_rename_dup — the enabler. Rename column 3 to column 2's name.
# ---------------------------------------------------------------------------
tape_reset
tape "$K_MAIN"   1 'column = 1' 'row = 1' 'value$ = ""' 'dlg_clicked = 5'
tape "$K_STRUCT" 1 'action = 7' 'dlg_clicked = 2'
tape "$K_RENCOL" 1 'column_to_rename = 3' 'column_to_rename$ = "colB"' \
                   'new_name$ = "colA"' 'dlg_clicked = 2'
tape "$K_MAIN"   2 'dlg_clicked = 1'
run_case A_rename_dup "$FIX/plain.praat"

# ---------------------------------------------------------------------------
# B_delete_dup — THE SEVERITY 1. Menu entry 3 selected; entry 3 must die.
# ---------------------------------------------------------------------------
# The verifier's case. Their evidence: after the rename the table reads
# id,colA,colA / S1,A1,B1 ; after deleting "the second dup" it read
# id,colA / S1,B1 — the A-data column, which is not the one that was picked.
tape_reset
tape "$K_MAIN"   1 'column = 1' 'row = 1' 'value$ = ""' 'dlg_clicked = 5'
tape "$K_STRUCT" 1 'action = 6' 'dlg_clicked = 2'
tape "$K_DELCOL" 1 'column_to_delete = 3' 'column_to_delete$ = "colA"' \
                   'dlg_clicked = 2'
tape "$K_MAIN"   2 'dlg_clicked = 1'
run_case B_delete_dup "$FIX/dup.praat"

# ---------------------------------------------------------------------------
# C_cell_dup — read then write a cell in menu entry 3.
# ---------------------------------------------------------------------------
# The Read press is what makes the probe meaningful: the shipped code fetches
# the cell for prepopulation at the TOP of the next loop turn, into
# currentValue$, and the tape prints that variable before pressing anything.
tape_reset
tape "$K_MAIN" 1 'column = 3' 'row = 2' 'value$ = ""' 'dlg_clicked = 2'
tape "$K_MAIN" 2 'appendInfoLine: "PROBE|read|", currentValue$' \
                 'column = 3' 'row = 2' 'value$ = "WROTE"' 'dlg_clicked = 3'
tape "$K_MAIN" 3 'dlg_clicked = 1'
run_case C_cell_dup "$FIX/dup.praat"

# ---------------------------------------------------------------------------
# D_repall_dup — Replace All scoped to menu entry 3.
# ---------------------------------------------------------------------------
# Scope 1 is "All columns", so column k is scope k+1: entry 3 is scope 4.
# "B" is present only in the B-data column, so a run that reports one or more
# replacements has read the column it was pointed at; a run that reports zero
# has read the other one. Both numbers are visible in the table afterwards.
tape_reset
tape "$K_MAIN" 1 'column = 1' 'row = 1' 'value$ = ""' 'dlg_clicked = 4'
tape "$K_FR"   1 'find_text$ = "B"' 'replace_with$ = "Z"' 'scope = 4' \
                 'match_type = 1' 'dlg_clicked = 5'
tape "$K_FR"   2 'dlg_clicked = 1'
tape "$K_MAIN" 2 'dlg_clicked = 1'
run_case D_repall_dup "$FIX/dup.praat"

# ---------------------------------------------------------------------------
# E_onecol — Delete Column with one column left.
# ---------------------------------------------------------------------------
# The refusal is pressed BACK, not Quit, because the claim being tested is
# that the editor survives the refusal — before 15 Aug 2026 this path did not
# return at all, it took the process with it. The trace has to show the main
# editing dialog again after the refusal or the case has proved nothing.
tape_reset
tape "$K_MAIN"   1 'column = 1' 'row = 1' 'value$ = ""' 'dlg_clicked = 5'
tape "$K_STRUCT" 1 'action = 6' 'dlg_clicked = 2'
tape "$K_DELCOL" 1 'column_to_delete = 1' 'column_to_delete$ = "only"' \
                   'dlg_clicked = 2'
tape "cannot_delete_column#1" 1 'dlg_clicked = 2'
tape "$K_MAIN"   2 'dlg_clicked = 1'
run_case E_onecol "$FIX/onecol.praat"

# ---------------------------------------------------------------------------
# F_add_dup / G_insert_dup — the other two ways to make a duplicate.
# ---------------------------------------------------------------------------
tape_reset
tape "$K_MAIN"   1 'column = 1' 'row = 1' 'value$ = ""' 'dlg_clicked = 5'
tape "$K_STRUCT" 1 'action = 4' 'dlg_clicked = 2'
tape "$K_ADDCOL" 1 'column_name$ = "colA"' 'dlg_clicked = 2'
tape "$K_MAIN"   2 'dlg_clicked = 1'
run_case F_add_dup "$FIX/plain.praat"

tape_reset
tape "$K_MAIN"   1 'column = 1' 'row = 1' 'value$ = ""' 'dlg_clicked = 5'
tape "$K_STRUCT" 1 'action = 5' 'dlg_clicked = 2'
tape "$K_INSCOL" 1 'at_position = 2' 'column_name$ = "colB"' 'dlg_clicked = 2'
tape "$K_MAIN"   2 'dlg_clicked = 1'
run_case G_insert_dup "$FIX/plain.praat"

# ---------------------------------------------------------------------------
# H_plain — the regression arm. No duplicates anywhere.
# ---------------------------------------------------------------------------
# The fix operates a column by renaming it to a private sentinel, doing the
# work by that name and renaming it back. If the restore is ever skipped, or
# the sentinel collides with something, this case is where it shows: the
# header afterwards must read exactly id,newB and the values must be the ones
# that were written.
tape_reset
tape "$K_MAIN"   1 'column = 3' 'row = 1' 'value$ = "B1x"' 'dlg_clicked = 3'
tape "$K_MAIN"   2 'column = 1' 'row = 1' 'value$ = ""' 'dlg_clicked = 5'
tape "$K_STRUCT" 1 'action = 7' 'dlg_clicked = 2'
tape "$K_RENCOL" 1 'column_to_rename = 3' 'column_to_rename$ = "colB"' \
                   'new_name$ = "newB"' 'dlg_clicked = 2'
tape "$K_MAIN"   3 'column = 1' 'row = 1' 'value$ = ""' 'dlg_clicked = 5'
tape "$K_STRUCT" 2 'action = 6' 'dlg_clicked = 2'
tape "$K_DELCOL" 1 'column_to_delete = 2' 'column_to_delete$ = "colA"' \
                   'dlg_clicked = 2'
tape "$K_MAIN"   4 'dlg_clicked = 1'
run_case H_plain "$FIX/plain.praat"

# ---------------------------------------------------------------------------
# I_findnav — Find on a duplicate table: does it report where it looked?
# ---------------------------------------------------------------------------
# "B2" exists only in menu entry 3. Find must land on row 2 of entry 3; the
# Found modal's tape prints prevCol and prevRow, which the shipped code has
# just set, so the navigation state is measured rather than inferred.
tape_reset
tape "$K_MAIN" 1 'column = 1' 'row = 1' 'value$ = ""' 'dlg_clicked = 4'
tape "$K_FR"   1 'find_text$ = "B2"' 'replace_with$ = ""' 'scope = 1' \
                 'match_type = 2' 'dlg_clicked = 2'
tape "found#1" 1 'appendInfoLine: "PROBE|found|col=", prevCol, "|row=", prevRow'
tape "find#1"  1 'appendInfoLine: "PROBE|nomatch|1"'
tape "$K_FR"   2 'dlg_clicked = 1'
tape "$K_MAIN" 2 'dlg_clicked = 1'
run_case I_findnav "$FIX/dup.praat"

# ---------------------------------------------------------------------------
# J_rename_back — refuse, press Back, and finish the job.
# ---------------------------------------------------------------------------
# A refusal that loses the user's place is its own defect. The probe on the
# second visit prints the two things the re-displayed form is built from —
# prevCol, which is the optionmenu's default, and structureDialog.pending$,
# which is the text field's — so "your selections are kept" is a measurement
# and not a promise in a comment.
tape_reset
tape "$K_MAIN"   1 'column = 1' 'row = 1' 'value$ = ""' 'dlg_clicked = 5'
tape "$K_STRUCT" 1 'action = 7' 'dlg_clicked = 2'
tape "$K_RENCOL" 1 'column_to_rename = 3' 'column_to_rename$ = "colB"' \
                   'new_name$ = "colA"' 'dlg_clicked = 2'
tape "cannot_use_that_column_name#1" 1 'dlg_clicked = 2'
tape "$K_RENCOL" 2 \
    'appendInfoLine: "PROBE|kept|col=", prevCol, "|name=", structureDialog.pending$' \
    'column_to_rename = 3' 'column_to_rename$ = "colB"' \
    'new_name$ = "colC"' 'dlg_clicked = 2'
tape "$K_MAIN"   2 'dlg_clicked = 1'
run_case J_rename_back "$FIX/plain.praat"

# ---------------------------------------------------------------------------
# K_autolabel — the editor's own invented name must not be a duplicate either.
# ---------------------------------------------------------------------------
# Column 3 has no label, and column 1 is already called "Column_3". The
# snapshot that makes unlabeled columns addressable used to name column 3
# "Column_3" unconditionally, so the code whose whole job is to make the table
# addressable was the third way to make it ambiguous. Nothing is pressed here
# beyond opening and quitting: the naming happens on sight.
tape_reset
tape "$K_MAIN" 1 'dlg_clicked = 1'
run_case K_autolabel "$FIX/blank.praat"

# ---------------------------------------------------------------------------
# 5. REPORT
# ---------------------------------------------------------------------------
say completed 1

printf '%-14s %-5s %-6s %s\n' case exit ncols header
for c in A_rename_dup B_delete_dup C_cell_dup D_repall_dup E_onecol \
         F_add_dup G_insert_dup H_plain I_findnav J_rename_back K_autolabel; do
    printf '%-14s %-5s %-6s %s\n' "$c" \
        "$(awk -F'\t' -v k="${c}_exit" '$1==k{print $2}' "$TSV")" \
        "$(awk -F'\t' -v k="${c}_after_ncols" '$1==k{print $2}' "$TSV")" \
        "$(awk -F'\t' -v k="${c}_after_header" '$1==k{print $2}' "$TSV")"
done
echo
echo "stanzas: $N_STANZA   twin body identical to shipped body: $(awk -F'\t' '$1=="twin_body_identical"{print $2}' "$TSV")"
echo "evidence: $OUT/EDIT.tsv, $(ls "$OUT"/*.csv 2>/dev/null | wc -l) csv, $(ls "$OUT"/*.log 2>/dev/null | wc -l) log"
echo
echo "Now run: Rscript validate/v55_editor_addressing.R"
