#!/usr/bin/env bash
# ============================================================================
# harness/edithook/run.sh — an edit made in the plugin's own editor is a
#                           recorded step, driven
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# WHAT THIS EXISTS TO SEE.
#
# A recording is a claim that the script it produces re-performs the session.
# Until the editor was hooked, one class of user action broke that claim
# without breaking anything a test could see: a cell changed in the plugin's
# own Table editor left no step, so the emitted script read the file from
# disk, ran the analysis on the UNEDITED numbers, and printed results
# different from the ones written into its own comments. Nothing errored.
# harness/roundtrip measured the size of it: a script whose comment said the
# group mean was 94.0121 replayed to 93.89.
#
# So this harness asks two questions of the shipped editor, and the second is
# the one that matters:
#
#   1. Does every path that CHANGES the table emit a step, carrying a
#      sentence a person can read and Praat that re-performs the change?
#      Cases A..G below, one per editor operation, plus the two cases that
#      exist because they are where a naive implementation is wrong: a table
#      with duplicate column labels, and a value with a double quote in it.
#   2. Replayed against the file as it sits on disk — no edit in it — does
#      the emitted script land on the SAME NUMBER the recorded session
#      produced? Case H, with the un-replayed table as the counterfactual.
#
# HOW THE EDITOR IS DRIVEN. It is all dialog: twenty-two `beginPause:` …
# `endPause` stanzas with the editing loop, the find/replace loop and the
# structure menu built out of them, and `beginPause:` hard-crashes under
# `praat --run` (GUI_HARNESS_RECIPE §12.2). harness/edittable/run.sh answered
# that by locating every stanza MECHANICALLY, replacing each with a call to a
# generated `@dlgN` that assigns exactly the variables that stanza's fields
# would have assigned plus the button pressed, and hashing the shipped file
# minus those regions against the twin minus the injected lines. That is the
# technique reused here, unchanged in its essentials: a nested or unterminated
# stanza is fatal rather than repaired, out/EXCISED.txt holds every removed
# byte, and a body that does not hash equal stops the run. Everything between
# the dialogs — the loop, the clamps, the addressing layer, the recording
# calls — is the shipped bytes, running.
#
# WHY THE PLUGIN IS STAGED INSTEAD OF THE TWIN BEING COPIED SOMEWHERE.
# The editor hands each committed change to scripts/eml-record-edit-step.praat
# through `runScript:` with a bare filename, which Praat resolves against the
# folder of the CALLING script; that sidecar in turn includes the recorder by
# `../stats/` and the recorder reads its phrases from `../data/`. A twin
# sitting in a scratch folder resolves none of those. So the stage is a
# symlink farm shaped like the plugin — the arrangement harness/roundtrip
# uses — and the twin is dropped into its scripts/ folder beside the file it
# was cut from. Every byte under the stage is the working copy's.
#
# A RECORDING CANNOT SPAN PRAAT PROCESSES (eml-record-start.praat's header
# says so: `--run` starts a fresh process per script and objects do not
# persist). So each case is ONE process: the driver starts the recording,
# hands the table to the twin through `runScript:` — which gives it its own
# variable scope inside that process, exactly as a menu command gets — and
# flushes afterwards. Case F starts no recording, which is how the guard is
# measured rather than assumed.
#
# EVIDENCE, all under out/:
#   EDITHOOK.tsv     every scalar fact, one per line
#   <case>.log       the driver's Info window: the STEP/CODE dump and the
#                    DLG trace naming every dialog reached, in order
#   <case>_after.csv the table as the shipped code left it
#   <case>_rec.praat the script the recording flushed
#   DIALOGS.tsv      the stanza map the twin was cut from
#   EXCISED.txt      every byte removed to make the twin
#   H_*              the replay leg: the emitted script, the two replays and
#                    the tables they produced
#
#   bash harness/edithook/run.sh
#
# $EML_EDITHOOK_FILE overrides the editor under test and $EML_EDITHOOK_DIR the
# evidence folder, so a break test drives a damaged copy without going near
# the shipped one. Both are the names harness/edittable already uses.
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

PLUG="$EML_ROOT/plugin_EML_StatsGraphs"
SRC="${EML_EDITHOOK_FILE:-$PLUG/scripts/eml-edit-table.praat}"
OUT="${EML_EDITHOOK_DIR:-$SCRIPT_DIR/out}"
PREFS="$SCRIPT_DIR/prefs"
STAGE="$OUT/stage"
WORK="$OUT/work"

[[ -f "$SRC" ]] || { echo "edithook: FAIL — no editor at $SRC" >&2; exit 1; }

rm -rf "$OUT"
mkdir -p "$OUT" "$PREFS" "$WORK" "$STAGE/scripts" "$STAGE/stats"

TSV="$OUT/EDITHOOK.tsv"
: > "$TSV"
say () { printf '%s\t%s\n' "$1" "$2" >> "$TSV"; }
die () { echo "edithook: FAIL — $*" >&2; exit 1; }

say praat_version    "$("$PRAAT" --version 2>&1 | head -1)"
say file_under_test  "$(basename "$SRC")"
say file_sha         "$(sha256sum < "$SRC" | cut -d' ' -f1)"
say file_is_shipped  "$([[ "$SRC" == "$PLUG/scripts/eml-edit-table.praat" ]] && echo 1 || echo 0)"
say sidecar_sha      "$(sha256sum < "$PLUG/scripts/eml-record-edit-step.praat" | cut -d' ' -f1)"
say phrases_sha      "$(sha256sum < "$PLUG/data/eml-record-phrases.csv" | cut -d' ' -f1)"

# ---------------------------------------------------------------------------
# 1. THE STAGE
# ---------------------------------------------------------------------------
for f in "$PLUG"/scripts/*.praat; do ln -s "$f" "$STAGE/scripts/$(basename "$f")"; done
for f in "$PLUG"/stats/*.praat;   do ln -s "$f" "$STAGE/stats/$(basename "$f")";   done
ln -s "$PLUG/graphs"  "$STAGE/graphs"
ln -s "$PLUG/data"    "$STAGE/data"
ln -s "$PLUG/sprites" "$STAGE/sprites"
say stage_scripts_linked "$(find "$STAGE/scripts" -maxdepth 1 -name '*.praat' | wc -l)"

# ---------------------------------------------------------------------------
# 2. LOCATE EVERY PAUSE STANZA — mechanical, and fatal when unsure
# ---------------------------------------------------------------------------
MAP="$OUT/DIALOGS.tsv"
awk '
function indent(s,   t) { t = s; sub(/[^ \t].*/, "", t); return length(t) }
/^[ \t]*beginPause: /{
    if (inb) { printf "edithook: FAIL - nested beginPause at line %d\n", NR > "/dev/stderr"; exit 2 }
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
    if (inb) { printf "edithook: FAIL - unterminated beginPause at line %d\n", start > "/dev/stderr"; exit 2 }
    if (idx == 0) { print "edithook: FAIL - no pause stanzas found" > "/dev/stderr"; exit 2 }
}
' "$SRC" > "$MAP" || exit 1

# A SECOND endPause INSIDE A REGION means the boundaries are a guess.
while IFS=$'\t' read -r _ st en _ _ _ _; do
    n=$(sed -n "${st},${en}p" "$SRC" | grep -c 'endPause')
    (( n == 1 )) || die "region $st-$en holds $n endPause lines"
done < "$MAP"

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
for i in $(seq 1 "$N_STANZA"); do say "stanza_${i}_key" "${KEY_OF_IDX[$i]}"; done

# ---------------------------------------------------------------------------
# 3. DERIVE THE HEADLESS TWIN, AND PROVE IT IS THE EDITOR
# ---------------------------------------------------------------------------
TWIN="$STAGE/scripts/edithook_twin.praat"
{
    prev=0
    for i in $(seq 1 "$N_STANZA"); do
        st=${S_START[$i]}; en=${S_END[$i]}
        (( st > prev )) || die "stanza $i out of order"
        sed -n "$((prev + 1)),$((st - 1))p" "$SRC"
        printf '%*s@dlg%d\n' "${S_BI[$i]}" "" "$i"
        if [[ "${S_TGT[$i]}" != "-" ]]; then
            printf '%*s%s = dlg_clicked\n' "${S_EI[$i]}" "" "${S_TGT[$i]}"
        fi
        prev=$en
    done
    sed -n "$((prev + 1)),\$p" "$SRC"
} > "$WORK/twin_base.praat" || exit 1

awk 'NR==1{done=0} {print} !done && /^endform$/{print "include _edithook_dlg.praat"; done=1}' \
    "$WORK/twin_base.praat" > "$TWIN"

{
    echo "# Cut from $(basename "$SRC") to make the headless twin."
    for i in $(seq 1 "$N_STANZA"); do
        echo "# --- stanza $i  (${KEY_OF_IDX[$i]})  lines ${S_START[$i]}-${S_END[$i]}"
        sed -n "${S_START[$i]},${S_END[$i]}p" "$SRC"
    done
} > "$OUT/EXCISED.txt"

DELSED="$WORK/del.sed"; : > "$DELSED"
for i in $(seq 1 "$N_STANZA"); do
    printf '%d,%dd\n' "${S_START[$i]}" "${S_END[$i]}" >> "$DELSED"
done
sed -f "$DELSED" "$SRC" > "$WORK/body_shipped.txt"
grep -vxE '[ \t]*@dlg[0-9]+|[ \t]*[A-Za-z_.][A-Za-z_0-9.]* = dlg_clicked|include _edithook_dlg\.praat' \
    "$TWIN" > "$WORK/body_twin.txt"
a=$(sha256sum < "$WORK/body_shipped.txt" | cut -d' ' -f1)
b=$(sha256sum < "$WORK/body_twin.txt" | cut -d' ' -f1)
say twin_body_sha_shipped "$a"
say twin_body_sha_twin    "$b"
say twin_body_identical   "$([[ "$a" == "$b" ]] && echo 1 || echo 0)"
[[ "$a" == "$b" ]] || { diff "$WORK/body_shipped.txt" "$WORK/body_twin.txt" | head -20 >&2; die "twin body differs from shipped body"; }

# ---------------------------------------------------------------------------
# 4. THE TAPE
# ---------------------------------------------------------------------------
# A case is a list of raw Praat lines filed under (dialog, visit). The lines
# are pasted verbatim into the generated `@dlgN`, so a reader of a case below
# is reading what the twin runs. EVERY UNSCRIPTED VISIT PRESSES BUTTON 1 —
# Quit or Go Back or OK on all twenty-two stanzas — so a case that walks
# somewhere it did not plan for unwinds instead of looping, and the DLG trace
# in the log shows where it went. A budget of 200 visits catches the rest.
declare -A TAPE=() MAXVISIT=()
tape_reset () { TAPE=(); MAXVISIT=(); }
tape () {                     # tape <key> <visit> <praat line>...
    local key="$1" visit="$2"; shift 2
    local idx="${IDX_OF_KEY[$key]:-}"
    [[ -n "$idx" ]] || die "no dialog keyed '$key'; known: ${!IDX_OF_KEY[*]}"
    local body="" l
    for l in "$@"; do body+="        $l"$'\n'; done
    TAPE["$idx,$visit"]="$body"
    (( visit > ${MAXVISIT[$idx]:-0} )) && MAXVISIT[$idx]=$visit
    return 0
}
emit_dlg () {
    local f="$STAGE/scripts/_edithook_dlg.praat" i v
    {
        echo "# Generated by harness/edithook/run.sh. Not part of the plugin."
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

# ---------------------------------------------------------------------------
# 5. ONE DRIVE
# ---------------------------------------------------------------------------
# run_case <name> <fixture-body-file> <record 0|1>
run_case () {
    local name="$1" fixture="$2" record="$3"
    emit_dlg
    local drv="$STAGE/scripts/_edithook_case.praat"
    {
        echo "# Driver for case $name. Generated by harness/edithook/run.sh."
        echo "include ../stats/eml-record.praat"
        # THE RECORDING IS STARTED THROUGH THE SHIPPED WRAPPER, IN ITS OWN
        # SCOPE, and that is not decoration. @emlRecordFlush refuses when
        # emlRecordN is 0, and emlRecordN is only re-read from the buffer by
        # the re-attach in @emlRecordInit -- which runs when the calling
        # scope has no buffer id of its own. A driver that called
        # @emlRecordBegin itself would hold a buffer id and a step count of
        # zero while the sidecar filled the buffer from another scope, and
        # would flush nothing. A user never meets that: Start recording is
        # its own menu command and the save is another. So is this.
        # It also puts the wrapper's start message in the case log, which is
        # where out/START_MESSAGE.txt is cut from.
        if [[ "$record" == "1" ]]; then
            echo "runScript: \"eml-record-start.praat\""
        fi
        cat "$fixture"
        echo "selectObject: tableId"
        echo "Save as comma-separated file: \"$OUT/${name}_before.csv\""
        echo "appendInfoLine: \"CASE handoff\""
        echo "selectObject: tableId"
        echo "runScript: \"edithook_twin.praat\", \"editor\""
        echo "appendInfoLine: \"CASE returned\""
        echo "selectObject: tableId"
        echo "Save as comma-separated file: \"$OUT/${name}_after.csv\""
        # THE BUFFER, DUMPED ROW BY ROW. The emitted script is rendered
        # afterwards; this is the recorder's own state, before any rendering
        # can hide or invent a thing.
        echo "nSteps = 0"
        echo "nocheck selectObject: \"Table emlRecording_DO_NOT_REMOVE\""
        echo "if numberOfSelected () = 1"
        echo "    bufId = selected (\"Table\")"
        echo "    nSteps = Get number of rows"
        echo "    for i to nSteps"
        echo "        selectObject: bufId"
        echo "        k\$ = Get value: i, \"kind\""
        echo "        it\$ = Get value: i, \"intent\""
        echo "        cd\$ = Get value: i, \"code\""
        echo "        sr\$ = Get value: i, \"source\""
        echo "        appendInfoLine: \"STEP|\", i, \"|\", k\$, \"|\", sr\$, \"|\", it\$"
        echo "        appendInfoLine: \"CODE<<<\""
        echo "        appendInfoLine: cd\$"
        echo "        appendInfoLine: \"CODE>>>\""
        echo "    endfor"
        echo "endif"
        echo "appendInfoLine: \"CASE steps|\", nSteps"
        if [[ "$record" == "1" ]]; then
            echo "@emlRecordFlush: \"$OUT/${name}_rec.praat\""
        fi
        echo "appendInfoLine: \"CASE done\""
    } > "$drv"

    ( env -u DISPLAY EML_RECORD_STAMP="21 August 2026, 00:00:00" \
        timeout 180 "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" \
        --run "$drv" > "$WORK/$name.log" 2>&1 )
    local rc=$?
    say "${name}_exit" "$rc"
    sed "s|$OUT|<OUT>|g; s|$PLUG|<PLUG>|g" "$WORK/$name.log" > "$OUT/$name.log"
    say "${name}_returned" "$(grep -c '^CASE returned$' "$WORK/$name.log")"
    say "${name}_steps"    "$(sed -n 's/^CASE steps|//p' "$WORK/$name.log" | tail -1)"
    say "${name}_dlg_trace" \
        "$(grep -o 'DLG|[0-9]*|[^|]*|' "$WORK/$name.log" | cut -d'|' -f3 | paste -sd, -)"
    say "${name}_error" "$(grep -m1 -E '^(Error|Praat:)' "$WORK/$name.log" | tr '\t' ' ')"
    local s
    while IFS= read -r s; do
        say "${name}_intent" "$(printf '%s' "$s" | cut -d'|' -f4-)"
    done < <(grep '^STEP|' "$WORK/$name.log")
    awk '/^CODE<<</{f=1;next} /^CODE>>>/{f=0;next} f' "$WORK/$name.log" \
        | sed 's/^/CODE /' > "$OUT/${name}_code.txt"
    say "${name}_code_lines" "$(grep -c . "$OUT/${name}_code.txt")"
}

FIX="$WORK/fixtures"; mkdir -p "$FIX"

cat > "$FIX/plain.praat" <<'EOF'
Create Table with column names: "demo", 3, "id f0"
tableId = selected ("Table")
for r to 3
    selectObject: tableId
    Set string value: r, "id", "S" + string$ (r)
    Set string value: r, "f0", "10" + string$ (r)
endfor
EOF

cat > "$FIX/dup.praat" <<'EOF'
Create Table with column names: "demo", 3, "id colA colB"
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

cat > "$FIX/unlabeled.praat" <<'EOF'
Create Table without column names: "demo", 2, 2
tableId = selected ("Table")
EOF

cat > "$FIX/repeats.praat" <<'EOF'
Create Table with column names: "demo", 3, "id tag"
tableId = selected ("Table")
for r to 3
    selectObject: tableId
    Set string value: r, "id", "S" + string$ (r)
    Set string value: r, "tag", "keep"
endfor
EOF

# ---- A_set: one cell, through the main dialog ------------------------------
tape_reset
tape 'eml_table_editor#3' 1 'column = 2' 'row = 1' 'value$ = "4242"' 'dlg_clicked = 3'
tape 'eml_table_editor#3' 2 'column = 1' 'row = 1' 'value$ = ""' 'dlg_clicked = 1'
run_case A_set "$FIX/plain.praat" 1

# ---- B_structure: every structural operation, one per pass -----------------
tape_reset
for v in 1 2 3 4 5 6 7; do
    tape 'eml_table_editor#3' "$v" 'column = 1' 'row = 1' 'value$ = ""' 'dlg_clicked = 5'
done
tape 'eml_table_editor#3' 8 'column = 1' 'row = 1' 'value$ = ""' 'dlg_clicked = 1'
tape 'table_structure#1' 1 'action = 1' 'dlg_clicked = 2'
tape 'table_structure#1' 2 'action = 2' 'dlg_clicked = 2'
tape 'insert_row#1'      1 'after_row = 1' 'dlg_clicked = 2'
tape 'table_structure#1' 3 'action = 3' 'dlg_clicked = 2'
tape 'delete_row#1'      1 'row_number = 2' 'dlg_clicked = 2'
tape 'table_structure#1' 4 'action = 4' 'dlg_clicked = 2'
tape 'add_column#2'      1 'column_name$ = "added"' 'dlg_clicked = 2'
tape 'table_structure#1' 5 'action = 5' 'dlg_clicked = 2'
tape 'insert_column#1'   1 'at_position = 2' 'column_name$ = "inserted"' 'dlg_clicked = 2'
tape 'table_structure#1' 6 'action = 7' 'dlg_clicked = 2'
tape 'rename_column#1'   1 'column_to_rename = 2' 'new_name$ = "renamed"' 'dlg_clicked = 2'
tape 'table_structure#1' 7 'action = 6' 'dlg_clicked = 2'
tape 'delete_column#1'   1 'column_to_delete = 2' 'dlg_clicked = 2'
run_case B_structure "$FIX/plain.praat" 1

# ---- C_repall: Replace All across all columns ------------------------------
tape_reset
tape 'eml_table_editor#3' 1 'column = 1' 'row = 1' 'value$ = ""' 'dlg_clicked = 4'
tape 'eml_table_editor#3' 2 'column = 1' 'row = 1' 'value$ = ""' 'dlg_clicked = 1'
tape 'find_replace#1' 1 'find_text$ = "keep"' 'replace_with$ = "drop"' \
     'scope = 1' 'match_type = 1' 'dlg_clicked = 5'
tape 'find_replace#1' 2 'find_text$ = "keep"' 'replace_with$ = "drop"' \
     'scope = 1' 'match_type = 1' 'dlg_clicked = 1'
run_case C_repall "$FIX/repeats.praat" 1

# ---- D_dup: a cell in the SECOND column called colA ------------------------
tape_reset
tape 'eml_table_editor#3' 1 'column = 3' 'row = 1' 'value$ = "ZZZ"' 'dlg_clicked = 3'
tape 'eml_table_editor#3' 2 'column = 1' 'row = 1' 'value$ = ""' 'dlg_clicked = 1'
run_case D_dup "$FIX/dup.praat" 1

# ---- E_autoname: columns the table arrived without names for ---------------
tape_reset
tape 'eml_table_editor#3' 1 'column = 1' 'row = 1' 'value$ = "named"' 'dlg_clicked = 3'
tape 'eml_table_editor#3' 2 'column = 1' 'row = 1' 'value$ = ""' 'dlg_clicked = 1'
run_case E_autoname "$FIX/unlabeled.praat" 1

# ---- F_norecord: the same edit with no recording running -------------------
tape_reset
tape 'eml_table_editor#3' 1 'column = 2' 'row = 1' 'value$ = "4242"' 'dlg_clicked = 3'
tape 'eml_table_editor#3' 2 'column = 1' 'row = 1' 'value$ = ""' 'dlg_clicked = 1'
run_case F_norecord "$FIX/plain.praat" 0

# ---- G_quote: a value with a double quote in it ----------------------------
tape_reset
tape 'eml_table_editor#3' 1 'column = 2' 'row = 1' 'value$ = "he said ""hi"""' \
     'dlg_clicked = 3'
tape 'eml_table_editor#3' 2 'column = 1' 'row = 1' 'value$ = ""' 'dlg_clicked = 1'
run_case G_quote "$FIX/plain.praat" 1

# ---- the start message, cut from a case log as its own artefact ----------
# PIECE 1's evidence. The wrapper writes it with `writeInfoLine:`, which
# CLEARS the Info window, so it is always the head of a recording case's log:
# everything after it appends. Cut at the driver's first marker.
sed -n '1,/^CASE handoff$/p' "$OUT/A_set.log" | sed '$d' > "$OUT/START_MESSAGE.txt"
say start_message_lines "$(wc -l < "$OUT/START_MESSAGE.txt")"
say start_message_sha   "$(sha256sum < "$OUT/START_MESSAGE.txt" | cut -d' ' -f1)"
for probe in "Recorded" "Not recorded" "Paste history" "EML: Edit Table..." \
             "script of your own"; do
    key=$(printf '%s' "$probe" | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]')
    say "start_message_has_$key" \
        "$(grep -cF -- "$probe" "$OUT/START_MESSAGE.txt")"
done

# ===========================================================================
# 6. CASE H — THE REPLAY, WHICH IS THE WHOLE POINT
# ===========================================================================
# One session: open a CSV, change one cell in the editor, run an ANOVA on the
# result, save the recording. Then replay that recording in a FRESH Praat
# against the CSV as it sits on disk — no edit in it — and ask whether the
# numbers come back the same.
#
# THE COUNTERFACTUAL IS RUN TOO, and it is the same file with the edit step's
# executable lines removed: the script a recorder that did not hook the editor
# would have produced. Three tables and three means come out of this, and the
# claim is only worth something because the third one differs.
H_IN="$OUT/H_input.csv"
{
    echo "group,f0_Hz"
    echo "A,100"; echo "A,90"; echo "A,95"; echo "A,91"
    echo "B,120"; echo "B,118"; echo "B,125"; echo "B,117"
    echo "C,210"; echo "C,205"; echo "C,208"; echo "C,201"
} > "$H_IN"
say H_input_sha "$(sha256sum < "$H_IN" | cut -d' ' -f1)"

tape_reset
tape 'eml_table_editor#3' 1 'column = 2' 'row = 1' 'value$ = "4242"' 'dlg_clicked = 3'
tape 'eml_table_editor#3' 2 'column = 1' 'row = 1' 'value$ = ""' 'dlg_clicked = 1'
emit_dlg

# ---- the recording session ------------------------------------------------
cat > "$STAGE/scripts/_edithook_H_record.praat" <<EOF
# Case H, the recorded session. Generated by harness/edithook/run.sh.
include eml-lib.praat

# THE INCLUDE BLOCK IS POINTED AT THE STAGE BEFORE ANYTHING READS IT.
# @emlRecordBegin ran inside the wrapper's scope and stamped the meta with a
# root derived from preferencesDirectory\$ — this harness's throwaway prefs
# folder, which no one can include. @emlRecordInit fills this variable from
# the meta only \`if not variableExists\`, so setting it first wins.
emlRecordPluginRoot\$ = "$STAGE"

runScript: "eml-record-start.praat"

# PRAAT'S OWN OPEN. setup.praat registers no reader of its own, so this is
# the only route a user has to a table on disk.
Read Table from comma-separated file: "$H_IN"
tableId = selected ("Table")
appendInfoLine: "H opened|", selected\$ ()

selectObject: tableId
runScript: "edithook_twin.praat", "editor"
appendInfoLine: "H edited"

selectObject: tableId
Save as comma-separated file: "$OUT/H_session_table.csv"

@emlRunAnovaAnalysis: tableId, "f0_Hz", "group", 0
appendInfoLine: "H session groupA mean|", fixed\$ (emlOneWayAnova.groupMean[1], 4)
appendInfoLine: "H session F|", fixed\$ (emlOneWayAnova.fValue, 4)

@emlRecordFlush: "$OUT/H_emitted.praat"
appendInfoLine: "H flushed|", emlRecordFlush.written
EOF

( env -u DISPLAY EML_RECORD_STAMP="21 August 2026, 00:00:00" \
    timeout 300 "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" \
    --run "$STAGE/scripts/_edithook_H_record.praat" > "$WORK/H_record.log" 2>&1 )
say H_record_exit $?
sed "s|$OUT|<OUT>|g; s|$STAGE|<STAGE>|g" "$WORK/H_record.log" > "$OUT/H_record.log"
say H_flushed        "$(sed -n 's/^H flushed|//p' "$WORK/H_record.log" | tail -1)"
say H_session_meanA  "$(sed -n 's/^H session groupA mean|//p' "$WORK/H_record.log" | tail -1)"
say H_session_F      "$(sed -n 's/^H session F|//p' "$WORK/H_record.log" | tail -1)"
say H_emitted_steps  "$(grep -c '^# --- Step ' "$OUT/H_emitted.praat" 2>/dev/null || echo 0)"
say H_emitted_edit_line \
    "$(grep -m1 '^Set string value:' "$OUT/H_emitted.praat" 2>/dev/null)"

# ---- the naive twin: the same file with the edit step's code removed ------
if [[ -f "$OUT/H_emitted.praat" ]]; then
    grep -v '^Set string value:' "$OUT/H_emitted.praat" > "$OUT/H_naive.praat"
    say H_naive_removed_lines \
        "$(( $(wc -l < "$OUT/H_emitted.praat") - $(wc -l < "$OUT/H_naive.praat") ))"
fi

# ---- replay <label> <script> ---------------------------------------------
# The wrapper supplies the data the way the emitted file's own PRECONDITION
# block instructs: open, named, and straight off the disk with no edit in it.
replay () {
    local label="$1" script="$2"
    cat > "$STAGE/scripts/_edithook_replay_$label.praat" <<EOF
Read Table from comma-separated file: "$H_IN"
appendInfoLine: "REPLAY opened|", selected\$ ()
runScript: "$script"
nocheck selectObject: "Table H_input"
if numberOfSelected () = 1
    Save as comma-separated file: "$OUT/H_${label}_table.csv"
    .a = Extract rows where column (text): "group", "is equal to", "A"
    .m = Get mean: "f0_Hz"
    appendInfoLine: "REPLAY groupA mean|", fixed\$ (.m, 4)
else
    appendInfoLine: "REPLAY groupA mean|NO TABLE"
endif
EOF
    ( env -u DISPLAY timeout 300 "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" \
        --run "$STAGE/scripts/_edithook_replay_$label.praat" \
        > "$WORK/H_$label.log" 2>&1 )
    say "H_${label}_exit" $?
    sed "s|$OUT|<OUT>|g; s|$STAGE|<STAGE>|g" "$WORK/H_$label.log" > "$OUT/H_$label.log"
    say "H_${label}_meanA" "$(sed -n 's/^REPLAY groupA mean|//p' "$WORK/H_$label.log" | tail -1)"
    say "H_${label}_error" "$(grep -m1 -E '^(Error|Praat:)' "$WORK/H_$label.log" | tr '\t' ' ')"
}

replay replay "$OUT/H_emitted.praat"
replay naive  "$OUT/H_naive.praat"

# ---- the three tables, compared ------------------------------------------
cmp_say () {                  # cmp_say <key> <a> <b>
    if [[ -f "$2" && -f "$3" ]] && cmp -s "$2" "$3"; then say "$1" 1; else say "$1" 0; fi
}
cmp_say H_replay_table_matches_session "$OUT/H_session_table.csv" "$OUT/H_replay_table.csv"
cmp_say H_naive_table_matches_session  "$OUT/H_session_table.csv" "$OUT/H_naive_table.csv"
cmp_say H_naive_table_matches_input    "$H_IN"                    "$OUT/H_naive_table.csv"

say cases_run 8

# ===========================================================================
# 7. THE ASSERTIONS
# ===========================================================================
# THIS HARNESS CHECKS ITSELF RATHER THAN LEAVING EVIDENCE FOR SOMEBODY TO
# READ. Every other harness in this tree pairs with a numbered file in
# validate/, and this one should acquire that pair; until it does, an
# unasserted artefact folder is a harness that cannot fail, and a harness that
# cannot fail is decoration. Each line below names the fact and the case it
# came from, so a red run says which drive stopped agreeing.
FAILED=0
val () { sed -n "s/^$1\t//p" "$TSV" | tail -1; }
must () {                     # must <label> <got> <want>
    if [[ "$2" == "$3" ]]; then
        printf 'ok    %-52s %s\n' "$1" "$2"
    else
        printf 'FAIL  %-52s got [%s] want [%s]\n' "$1" "$2" "$3"
        FAILED=$((FAILED + 1))
    fi
}
must_ne () {                  # must_ne <label> <got> <not>
    if [[ "$2" != "$3" && -n "$2" ]]; then
        printf 'ok    %-52s %s (not %s)\n' "$1" "$2" "$3"
    else
        printf 'FAIL  %-52s got [%s], which must differ from [%s]\n' "$1" "$2" "$3"
        FAILED=$((FAILED + 1))
    fi
}
echo
echo "edithook assertions"
echo "-------------------"

must "twin is the shipped editor"        "$(val twin_body_identical)" 1
for c in A_set B_structure C_repall D_dup E_autoname F_norecord G_quote; do
    must "$c ran to the end"             "$(val ${c}_exit)" 0
    must "$c raised nothing"             "$(val ${c}_error)" ""
    must "$c returned from the editor"   "$(val ${c}_returned)" 1
done

must "A_set records one step"            "$(val A_set_steps)" 1
must "A_set emits the Set that replays it" \
     "$(cat "$OUT/A_set_code.txt")" 'CODE Set string value: 1, "f0", "4242"'
must "B_structure records seven steps"   "$(val B_structure_steps)" 7
must "B_structure emits seven commands"  "$(val B_structure_code_lines)" 7
must "C_repall records one step"         "$(val C_repall_steps)" 1
must "C_repall emits one Set per cell"   "$(val C_repall_code_lines)" 3
must "E_autoname records both names and the edit" "$(val E_autoname_steps)" 3
must "G_quote doubles the quote in the literal" \
     "$(cat "$OUT/G_quote_code.txt")" \
     'CODE Set string value: 1, "f0", "he said ""hi"""'

# The duplicate-label case: the emitted code must carry @colLock's rename
# pair, because without it a replay writes into the FIRST column called colA.
must "D_dup records one step"            "$(val D_dup_steps)" 1
must "D_dup emits the lock, the write and the restore" \
     "$(cat "$OUT/D_dup_code.txt")" \
     'CODE Rename column (by number): 3, "eml_col_lock"
CODE Set string value: 1, "eml_col_lock", "ZZZ"
CODE Rename column (by number): 3, "colA"'

# The guard: with no recording running the editor changes the table in
# exactly the same way and writes nothing down.
must "F_norecord records nothing"        "$(val F_norecord_steps)" 0
if cmp -s "$OUT/A_set_after.csv" "$OUT/F_norecord_after.csv"; then
    must "F_norecord edits the table identically" 1 1
else
    must "F_norecord edits the table identically" 0 1
fi

# The start message.
must "start message names what is recorded"     "$(val start_message_has_recorded)" 1
must "start message names what is not"          "$(val start_message_has_notrecorded)" 1
must "start message names the recovery route"   "$(val start_message_has_pastehistory)" 1
must "start message names the editor to use"    "$(val start_message_has_emledittable)" 2
must "start message names the foreign script"   "$(val start_message_has_scriptofyourown)" 1

# The replay.
must "H flushed a script"                "$(val H_flushed)" 1
must "H recorded read, edit and analysis" "$(val H_emitted_steps)" 3
must "H emitted the edit as an executable line" \
     "$(val H_emitted_edit_line)" 'Set string value: 1, "f0_Hz", "4242"'
must "H replay reaches the recorded mean" \
     "$(val H_replay_meanA)" "$(val H_session_meanA)"
must "H replay rebuilds the recorded table" "$(val H_replay_table_matches_session)" 1
must_ne "H without the edit step lands elsewhere" \
     "$(val H_naive_meanA)" "$(val H_session_meanA)"
must "H without the edit step leaves the file's own numbers" \
     "$(val H_naive_table_matches_input)" 1

echo
if (( FAILED == 0 )); then
    echo "edithook: PASS — evidence in $OUT"
    exit 0
fi
echo "edithook: FAIL — $FAILED assertion(s). Evidence in $OUT"
exit 1
