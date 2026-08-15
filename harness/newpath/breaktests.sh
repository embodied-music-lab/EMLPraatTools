#!/usr/bin/env bash
# ============================================================================
# newpath/breaktests.sh — prove v60 bites, one check at a time
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# NOTHING IS VALIDATED UNTIL IT HAS BEEN BROKEN. A check that has only ever
# been seen green is a check that has been seen agree with the world, which is
# not the same as a check that would disagree with a wrong one. Every assertion
# in validate/v60_wrapper_paths.R is aimed at one property; this driver damages
# that property, on a COPY, and requires the named check to go red.
#
# NAMED, not merely counted. "The suite noticed something" is too weak: a
# mutation that broke the file so badly the validator aborted would satisfy it,
# and so would a mutation that happened to trip a neighbouring check while the
# one it was aimed at slept through. So each case declares the phrase of the
# check it is aimed at, and the case passes only when THAT line reads FAIL.
#
# WHAT IS MUTATED. v60 reads two kinds of thing, and both are overridable so
# that nothing in the working tree is touched:
#
#   $EML_PAIRED_FILE / $EML_CHECKDATA_FILE   the two shipped wrappers
#   $EML_NEWPATH_DIR                          the drive's evidence directory
#
# THE STRONGEST BREAK TEST IS NOT HERE, and that is deliberate. It is the whole
# of harness/newpath/run.sh re-driven against the pre-fix wrappers: the New
# after the Draw dead-ends in "Cannot run this analysis", the file check calls
# five files Praat refuses "No import problems found", and thirty of v60's
# forty-nine checks go red at once. That is a ten-minute GUI run and it is done
# by hand from the two sources at the commit before the fix; what is automated
# here is the per-check half, which is what tells you WHICH assertion is load-
# bearing for WHICH property.
#
#     bash harness/newpath/breaktests.sh
# Exit 0 = every case went red where it was aimed.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/../.." && pwd)"
WORK="${TMPDIR:-/tmp}/newpath_break.$$"
PAIRED="$REPO/plugin/scripts/eml-compare-paired.praat"
CHECKD="$REPO/plugin/scripts/eml-check-data.praat"
EVID="$SCRIPT_DIR/out"
V60="$REPO/validate/v60_wrapper_paths.R"

mkdir -p "$WORK"
trap 'rm -rf "$WORK"' EXIT

# BASELINE FIRST. A driver that starts from a red suite proves nothing: every
# case would "pass" on a failure it did not cause.
base=$(Rscript "$V60" 2>&1 | grep -c '^FAIL' || true)
if [[ "$base" -ne 0 ]]; then
    echo "breaktests: REFUSED — v60 is not green to begin with ($base FAIL)."
    echo "            Fix the tree, or re-run the drive, before breaking anything."
    exit 2
fi
echo "breaktests: baseline is green"
echo

# run_case <name> <kind: paired|checkdata|evidence> <mutation-python> <expected-phrase>
#
# The mutation is a python3 fragment with $SRC and $DST bound. It must CHANGE
# the file; a mutation that no longer bites — because the line it edits has
# been renamed — cannot corrupt anything and therefore cannot be detected, so
# it is a failure of this driver rather than a pass of the validator.
pass=0; fail=0
run_case () {
    local name="$1" kind="$2" mut="$3" want="$4"
    local d="$WORK/$name"
    rm -rf "$d"; mkdir -p "$d"

    local src dst
    case "$kind" in
        paired)   src="$PAIRED"; dst="$d/eml-compare-paired.praat" ;;
        checkdata) src="$CHECKD"; dst="$d/eml-check-data.praat" ;;
        evidence) src="$EVID";   dst="$d/out"; cp -r "$src" "$dst" ;;
    esac
    if [[ "$kind" != "evidence" ]]; then cp "$src" "$dst"; fi

    SRC="$src" DST="$dst" python3 -c "$mut" || {
        echo "  $name — DEAD (mutation errored)"; fail=$((fail + 1)); return; }

    if [[ "$kind" != "evidence" ]] && cmp -s "$src" "$dst"; then
        echo "  $name — DEAD (mutation changed nothing; the line it edits has moved)"
        fail=$((fail + 1)); return
    fi

    local out
    case "$kind" in
        paired)    out=$(EML_PAIRED_FILE="$dst" Rscript "$V60" 2>&1) ;;
        checkdata) out=$(EML_CHECKDATA_FILE="$dst" Rscript "$V60" 2>&1) ;;
        evidence)  out=$(EML_NEWPATH_DIR="$dst" Rscript "$V60" 2>&1) ;;
    esac

    if printf '%s\n' "$out" | grep '^FAIL' | grep -qF "$want"; then
        echo "  $name — RED on: $want"
        pass=$((pass + 1))
    else
        echo "  $name — STAYED GREEN (aimed at: $want)"
        printf '%s\n' "$out" | grep '^FAIL' | sed 's/^/      also red: /'
        fail=$((fail + 1))
    fi
}

# ---------------------------------------------------------------------------
# THE PAIRED WRAPPER
# ---------------------------------------------------------------------------
echo "paired wrapper:"

# The obvious one: take the rebind away entirely.
run_case rebind_removed paired '
import os
s=open(os.environ["DST"]).read()
s=s.replace("    @emlTableColumnNames: tableId\n    nCols = emlTableColumnNames.nCols\n","",1)
open(os.environ["DST"],"w").write(s)
' "re-reads the user's table's column names on every pass"

# THE ONE THAT MATTERS MOST. The rebind still exists — it has merely been
# hoisted out of the loop, which is what the defect was. A check that asked
# only whether the wrapper ever reads its column names would sleep through
# this, and @emlWrapperInit reads them before the loop in any case.
run_case rebind_hoisted paired '
import os
s=open(os.environ["DST"]).read()
s=s.replace("    @emlTableColumnNames: tableId\n    nCols = emlTableColumnNames.nCols\n","",1)
s=s.replace("allDone = 0\nrepeat\n","@emlTableColumnNames: tableId\nnCols = emlTableColumnNames.nCols\nallDone = 0\nrepeat\n",1)
open(os.environ["DST"],"w").write(s)
' "re-reads the user's table's column names on every pass"

run_case ncols_stale paired '
import os
s=open(os.environ["DST"]).read()
s=s.replace("    nCols = emlTableColumnNames.nCols\n","",1)
open(os.environ["DST"],"w").write(s)
' "refreshes nCols from the same read"

run_case form_menus_rewired paired '
import os
s=open(os.environ["DST"]).read()
s=s.replace("option: emlTableColumnNames.name$ [iCol]","option: \"col\" + string$ (iCol)")
open(os.environ["DST"],"w").write(s)
' "column menus are built from the array that rebind fills"

run_case reshape_named_literal paired '
import os
s=open(os.environ["DST"]).read()
s=s.replace("longName$ = tableName$ + \"_long\"\n","")
s=s.replace("Create Table with column names: longName$,","Create Table with column names: \"pairedLong\",")
open(os.environ["DST"],"w").write(s)
' "reshape is named from the user's table, not from a literal"

run_case reshape_name_not_from_table paired '
import os
s=open(os.environ["DST"]).read()
s=s.replace("longName$ = tableName$ + \"_long\"","longName$ = \"pairedLong\"")
open(os.environ["DST"],"w").write(s)
' "the name it is built from is the user's table name"

run_case reshape_absent paired '
import os
s=open(os.environ["DST"]).read()
s=s.replace("Create Table with column names:","Create Table with names:")
open(os.environ["DST"],"w").write(s)
' "the paired wrapper creates its reshape table"

# THE REFUTED FINDING. Someone "tidying up a hardcoded column name" removes
# the preset; the grouped spaghetti plot silently stops being grouped.
run_case d15_group_preset_removed paired '
import os
s=open(os.environ["DST"]).read()
s=s.replace("emlGraphsPresetGroupCol$ = \"Group\"","emlGraphsPresetGroupCol$ = groupCol$")
open(os.environ["DST"],"w").write(s)
' "Group\" preset targeting the wrapper's own reshape is left alone"

run_case entry_form_renamed paired '
import os
s=open(os.environ["DST"]).read()
s=s.replace("beginPause: \"Compare Paired Observations\"","beginPause: \"Compare Paired\"")
open(os.environ["DST"],"w").write(s)
' "entry form and its enclosing repeat are both found"

run_case source_missing paired '
import os
os.remove(os.environ["DST"])
' "the paired wrapper is present"

# ---------------------------------------------------------------------------
# CHECK & REPAIR
# ---------------------------------------------------------------------------
echo
echo "check & repair wrapper:"

run_case rowscan_not_called checkdata '
import os
s=open(os.environ["DST"]).read()
s=s.replace("@emlCheckFileRowLengths: path$\n","",1)
open(os.environ["DST"],"w").write(s)
' "file mode scans row lengths"

run_case rowscan_not_defined checkdata '
import os
s=open(os.environ["DST"]).read()
s=s.replace("procedure emlCheckFileRowLengths: .path$","procedure emlSomethingElse: .path$")
open(os.environ["DST"],"w").write(s)
' "row-length scan is defined, not merely called"

# The scan reading the file with the TABLE reader would work on every file
# except the ones this exists for -- it would inherit the refusal it is
# supposed to predict.
run_case scan_uses_table_reader checkdata '
import os
s=open(os.environ["DST"]).read()
s=s.replace(".strId = Read Strings from raw text file: .path$",".strId = Read Table from comma-separated file: .path$")
open(os.environ["DST"],"w").write(s)
' "reads the file as TEXT"

run_case quoted_commas_counted checkdata '
import os
s=open(os.environ["DST"]).read()
s=s.replace("    .bare$ = replace_regex$ (.line$, \"\"\"[^\"\"]*\"\"\", \"\", 0)","    .bare$ = .line$")
open(os.environ["DST"],"w").write(s)
' "comma inside a quoted field is not counted as a separator"

run_case quote_parity_gone checkdata '
import os
s=open(os.environ["DST"]).read()
s=s.replace("procedure emlCsvQuoteParity: .line$","procedure emlCsvParityGone: .line$")
open(os.environ["DST"],"w").write(s)
' "quoted field spanning a newline is joined"

# THE FINDING ITSELF, restored: the wide sentence over the narrow check.
run_case old_verdict_restored checkdata '
import os
s=open(os.environ["DST"]).read()
s=s.replace("appendInfoLine: \"Nothing found by the three checks this mode makes:\"","appendInfoLine: \"No import problems found. No doubled-quote escapes.\"")
open(os.environ["DST"],"w").write(s)
' "No import problems found\" verdict is gone from the code"

run_case verdict_counts_dropped checkdata '
import os
s=open(os.environ["DST"]).read()
s=s.replace("emlCheckFileRowLengths.nDataRows,","1,")
s=s.replace("emlCheckFileRowLengths.headerFields, \" field(s),\"","1, \" field(s),\"")
open(os.environ["DST"],"w").write(s)
' "reports the row count and field count it actually established"

run_case disclaimer_dropped checkdata '
import os
s=open(os.environ["DST"]).read()
s=s.replace("and it is not a \"\n    ... + \"verdict on the\"","and that is all.\"")
open(os.environ["DST"],"w").write(s)
' "disclaims the thing it did NOT check"

# NEW-G12-4 restored: the raw refusal with Praat's stack under it.
run_case raw_exit_restored checkdata '
import os
s=open(os.environ["DST"]).read()
s=s.replace("        @emlErrorDialog: \"Table mode audits a Table in the object list, and \"","        exitScript: \"Please select exactly one Table object, then run this again.\"\n        @emlNeverReached: \"Table mode audits a Table in the object list, and \"")
open(os.environ["DST"],"w").write(s)
' "no raw exitScript refusal remains"

run_case errordialog_removed checkdata '
import os
s=open(os.environ["DST"]).read()
s=s.replace("@emlErrorDialog:","@emlNotTheDialog:")
s=s.replace("emlErrorDialog.back","emlNotTheDialog.back")
open(os.environ["DST"],"w").write(s)
' "refusal goes through @emlErrorDialog"

# ---------------------------------------------------------------------------
# THE DRIVE
# ---------------------------------------------------------------------------
echo
echo "the drive's evidence:"

run_case drive_absent evidence '
import os, shutil
shutil.rmtree(os.environ["DST"]); os.makedirs(os.environ["DST"])
' "the drive was run"

run_case new_never_pressed evidence '
import os
p=os.path.join(os.environ["DST"],"DIALOGS.tsv")
rows=[l for l in open(p).read().splitlines() if l]
rows=[r.replace("\tNew\t","\tDone\t") for r in rows]
open(p,"w").write("\n".join(rows)+"\n")
' "pressed Draw, and then pressed New after it"

run_case new_opened_something_else evidence '
import os
p=os.path.join(os.environ["DST"],"DIALOGS.tsv")
rows=[l.split("\t") for l in open(p).read().splitlines() if l]
for r in rows:
    if r[0]=="10": r[1]="EML Graphs"
open(p,"w").write("\n".join("\t".join(r) for r in rows)+"\n")
' "New reopened the wrapper's own entry form"

run_case run_dead_ends evidence '
import os
p=os.path.join(os.environ["DST"],"DIALOGS.tsv")
rows=[l.split("\t") for l in open(p).read().splitlines() if l]
for r in rows:
    if r[0]=="11": r[1]="Cannot run this analysis"
open(p,"w").write("\n".join("\t".join(r) for r in rows)+"\n")
' "Run on that form reached an analysis instead of dead-ending"

run_case form_offers_role_names evidence '
import os
p=os.path.join(os.environ["DST"],"NEWFORM.txt")
s=open(p).read().replace("jitter_pre","Condition").replace("jitter_post","Value")
open(p,"w").write(s)
' "reopened form offers the user's own columns"

run_case form_photo_missing evidence '
import os
os.remove(os.path.join(os.environ["DST"],"NEWFORM.txt"))
' "reopened form was photographed and read"

run_case second_analysis_missing evidence '
import os
p=os.path.join(os.environ["DST"],"PAIRED_INFO.txt")
lines=open(p).read().splitlines()
cut=[i for i,l in enumerate(lines) if "EML Stats : Paired Comparison" in l][1]
open(p,"w").write("\n".join(lines[:cut-2])+"\n")
' "two paired analyses ran in one session"

run_case reshape_left_behind evidence '
import os
p=os.path.join(os.environ["DST"],"PAIRED_OBJECTS.txt")
open(p,"a").write("Table np_paired_long\n")
' "reshape was removed and only the user"

run_case stem_names_internal evidence '
import os
p=os.path.join(os.environ["DST"],"ARTEFACTS.tsv")
s=open(p).read().replace("np_paired_long","pairedLong")
open(p,"w").write(s)
' "figure save stem names the user's table"

run_case title_names_internal evidence '
import os
p=os.path.join(os.environ["DST"],"FIGURE_TITLE.txt")
open(p,"a").write("Jitter by Condition and Subject (pairedLong)\n")
' "automatic title does not name the wrapper's internals"

run_case refused_file_called_clean evidence '
import os
p=os.path.join(os.environ["DST"],"FILECHECK.tsv")
rows=[l.split("\t") for l in open(p).read().splitlines() if l]
for r in rows:
    if r[0]=="02_short_middle.csv": r[1]="CLEAN"
open(p,"w").write("\n".join("\t".join(r) for r in rows)+"\n")
' "every file Praat's reader refuses is flagged"

run_case silent_truncation_missed evidence '
import os
p=os.path.join(os.environ["DST"],"FILECHECK.tsv")
rows=[l.split("\t") for l in open(p).read().splitlines() if l]
for r in rows:
    if r[0]=="05_long_last.csv": r[1]="CLEAN"
open(p,"w").write("\n".join("\t".join(r) for r in rows)+"\n")
' "surplus fields on the final row are flagged"

run_case false_alarm_on_clean evidence '
import os
p=os.path.join(os.environ["DST"],"FILECHECK.tsv")
rows=[l.split("\t") for l in open(p).read().splitlines() if l]
for r in rows:
    if r[0]=="01_clean.csv": r[1]="FLAGGED"
open(p,"w").write("\n".join("\t".join(r) for r in rows)+"\n")
' "01_clean.csv reads cleanly and is reported clean"

run_case false_alarm_on_quoted evidence '
import os
p=os.path.join(os.environ["DST"],"FILECHECK.tsv")
rows=[l.split("\t") for l in open(p).read().splitlines() if l]
for r in rows:
    if r[0]=="07_quoted_ok.csv": r[1]="FLAGGED"
open(p,"w").write("\n".join("\t".join(r) for r in rows)+"\n")
' "07_quoted_ok.csv reads cleanly and is reported clean"

run_case populations_disagree evidence '
import os
p=os.path.join(os.environ["DST"],"FILECHECK.tsv")
rows=[l for l in open(p).read().splitlines() if l and not l.startswith("08_")]
open(p,"w").write("\n".join(rows)+"\n")
' "reader probe and the drive covered the same cases"

# A NINTH FIXTURE THAT NOTHING ASSERTS ON. Every check above still passes,
# correctly, about the eight it was written for. The census is the only thing
# in the file that can say the population changed.
run_case ninth_case_unwatched evidence '
import os
r=os.path.join(os.environ["DST"],"READER.tsv")
f=os.path.join(os.environ["DST"],"FILECHECK.tsv")
open(r,"a").write("09_new_fixture.csv\tOK\tOK rows=3 cols=3\n")
open(f,"a").write("09_new_fixture.csv\tCLEAN\n")
' "every CSV case is accounted for by some check"

run_case printed_verdict_overclaims evidence '
import os
p=os.path.join(os.environ["DST"],"verdict_01_clean.csv.txt")
open(p,"w").write("FILE CHECK\n\nNo import problems found. No doubled-quote escapes, and the header\nis comma-delimited.\n")
' "printed clean verdict enumerates the row-length check"

# ---------------------------------------------------------------------------
# THE DISCRIMINATING PAIRS
# ---------------------------------------------------------------------------
# Several checks come in twos that a coarse mutation breaks together: the old
# verdict restored turns both the ban and the enumeration red, so neither has
# been shown to carry its own weight. Each case below is built to break exactly
# ONE of a pair and leave its neighbour green, which is the only way to know
# the pair is two checks rather than one written twice.
echo
echo "discriminating pairs:"

run_case checkdata_source_missing checkdata '
import os
os.remove(os.environ["DST"])
' "the check & repair wrapper is present"

run_case pairedlong_reintroduced paired '
import os
s=open(os.environ["DST"]).read()
s=s.replace("longName$ = tableName$ + \"_long\"","longName$ = tableName$ + \"_pairedLong\"")
open(os.environ["DST"],"w").write(s)
' "internal name \"pairedLong\" is gone from the code"

run_case verdict_not_enumerated checkdata '
import os
s=open(os.environ["DST"]).read()
s=s.replace("Nothing found by the three checks this mode makes:","This file looks fine.")
open(os.environ["DST"],"w").write(s)
' "clean verdict names the checks it is the verdict of"

run_case refusal_later_in_chain evidence '
import os
p=os.path.join(os.environ["DST"],"DIALOGS.tsv")
open(p,"a").write("12\tCannot run this analysis\tQuit\t2\n")
' "no refusal dialog anywhere after the Draw"

run_case form_offers_both evidence '
import os
p=os.path.join(os.environ["DST"],"NEWFORM.txt")
open(p,"a").write("Condition\n")
' "offers none of the reshape"

run_case second_analysis_other_table evidence '
import os
p=os.path.join(os.environ["DST"],"PAIRED_INFO.txt")
lines=open(p).read().splitlines()
seen=0
for i,l in enumerate(lines):
    if l.rstrip()=="  Table               np paired":
        seen+=1
        if seen==2: lines[i]="  Table               np paired long"
open(p,"w").write("\n".join(lines)+"\n")
' "both analyses were run on the user's table"

run_case printed_verdict_adds_old_phrase evidence '
import os
p=os.path.join(os.environ["DST"],"verdict_01_clean.csv.txt")
open(p,"a").write("No import problems found.\n")
' "printed verdict does not claim the file is problem-free"

run_case info_capture_missing evidence '
import os
os.remove(os.path.join(os.environ["DST"],"PAIRED_INFO.txt"))
' "Info window was captured at the end of the leg"

run_case objects_capture_missing evidence '
import os
os.remove(os.path.join(os.environ["DST"],"PAIRED_OBJECTS.txt"))
' "object list was captured at the end of the leg"

run_case artefacts_missing evidence '
import os
os.remove(os.path.join(os.environ["DST"],"ARTEFACTS.tsv"))
' "the Save panel wrote something"

run_case figure_missing evidence '
import os
os.remove(os.path.join(os.environ["DST"],"FIGURE_TITLE.txt"))
' "the figure was saved and read back"

run_case verdict_capture_missing evidence '
import os
os.remove(os.path.join(os.environ["DST"],"verdict_01_clean.csv.txt"))
' "clean case's report was captured"

run_case case_read_but_not_rendered evidence '
import os
for f in ("READER.tsv","FILECHECK.tsv"):
    p=os.path.join(os.environ["DST"],f)
    rows=[l for l in open(p).read().splitlines() if l and not l.startswith("05_long_last")]
    open(p,"w").write("\n".join(rows)+"\n")
' "every CSV case a check reads was actually rendered"

echo
echo "breaktests: $pass case(s) went red where aimed, $fail did not."
[[ $fail -eq 0 ]] || exit 1
exit 0
