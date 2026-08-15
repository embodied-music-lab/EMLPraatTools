#!/usr/bin/env bash
# ============================================================================
# exportint/breaktest.sh -- prove v57 bites.
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# NOTHING IS VALIDATED UNTIL IT HAS BEEN BROKEN. Every section of
# validate/v57_export_integrity.R is run here against a deliberately corrupted
# copy of the thing it reads, and a section that stays green under its own
# corruption is reported as DEAD -- the same rule and the same reasoning as
# validate/mutation/mutate_drive.sh, which does this for the committed
# evidence rather than for the source.
#
# PREFLIGHT, and it is not decoration. @mutate compares the file before and
# after and ABORTS the case if nothing changed. A substitution whose pattern
# has drifted corrupts nothing, so it can never be detected, so a green v57
# under it means nothing at all -- and it reads exactly like a passing case.
# That is mutate_drive.sh's "absent pattern = failure" rule, and this script
# earned it the same way: the first run of case s8 reported RED-by-omission
# because a `perl -0p` pattern had a literal that no longer existed.
#
# A BROKEN SCRIPT IS NOT A BROKEN CHECK. Where a source case could make the
# .praat file fail to PARSE, the mutation is narrowed until it does not: a
# drive that dies produces no artefact, v57 stops at its "was the drive run"
# gate, and the case would report RED having exercised nothing below line one.
# Cases that cannot avoid it are run source-only, against the repository's own
# committed artefact, and say so.
#
# The corruption is applied to a COPY under $TMPDIR, never to the repository:
# each case builds a scratch tree carrying plugin/, harness/exportint/ and
# validate/redpath at their real relative depths, because a .praat file's
# relative includes rebase against THAT FILE's folder and a flattened copy
# would fail to parse rather than fail to check.
#
#     bash harness/exportint/breaktest.sh
#
# Exit 0 = every case went RED. Exit 1 = at least one case is DEAD or unbuilt.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/../.." && pwd)"
WORK="${TMPDIR:-/tmp}/exportint_break"
PRAAT="${PRAAT:-praat}"
OUT="$REPO/harness/exportint/out"

rm -rf "$WORK"; mkdir -p "$WORK"
FAILED=0

base=$(cd "$REPO" && Rscript validate/v57_export_integrity.R 2>&1 | tail -1)
echo "BASELINE  $base"
case "$base" in
    *", 0 FAILED"*) ;;
    *) echo "breaktest: FAIL -- baseline is not green; stopping"; exit 1 ;;
esac

newtree () {   # newtree <name>  -> echoes the tree root
    local t="$WORK/$1"
    rm -rf "$t"; mkdir -p "$t/validate" "$t/harness"
    cp -r "$REPO/plugin" "$t/plugin"
    cp -r "$REPO/harness/exportint" "$t/harness/exportint"
    rm -rf "$t/harness/exportint/out"
    cp -r "$REPO/validate/redpath" "$t/validate/redpath"
    printf '%s' "$t"
}

# mutate <file> <perl-expr> -- and prove it did something.
mutate () {
    local f="$1" expr="$2"
    local before after
    before=$(md5sum "$f" | cut -d' ' -f1)
    perl -0pi -e "$expr" "$f"
    after=$(md5sum "$f" | cut -d' ' -f1)
    if [[ "$before" == "$after" ]]; then
        echo "UNBUILT  $(basename "$f") -- the pattern matched nothing"
        FAILED=1
        return 1
    fi
    return 0
}

report () {   # report <name> <kind> <last-line>
    local name="$1" kind="$2" line="$3"
    case "$line" in
        *", 0 FAILED"*) echo "DEAD   $kind $name -- v57 stayed green"; FAILED=1 ;;
        *FAILED*)       echo "RED    $kind $name -- $line" ;;
        *)              echo "DEAD   $kind $name -- v57 did not report ($line)"; FAILED=1 ;;
    esac
}

runv57 () {   # runv57 <plugin-dir> <exportint-dir>
    (cd "$REPO" && EML_PLUGIN_DIR="$1" EML_EXPORTINT_DIR="$2" \
        Rscript validate/v57_export_integrity.R 2>&1 | tail -1)
}

drive () {    # drive <tree>  -> out dir, or "" if the drive died
    local t="$1"
    ( cd "$t/harness/exportint" && \
      EML_EXPORTINT_OUT="$t/out" "$PRAAT" --run drive.praat ) >"$t/drive.log" 2>&1
    if [[ ! -f "$t/out/shape.tsv" ]]; then
        echo "UNBUILT  drive died under this mutation; see $t/drive.log" >&2
        FAILED=1
    fi
    printf '%s' "$t/out"
}

ANA=plugin/stats/eml-analysis.praat

# ---------------------------------------------------------------------------
# SOURCE CASES -- corrupt the plugin, re-drive, run v57 against both
# ---------------------------------------------------------------------------

# S1  NEW-G1-1 reverted: clear the collectors at entry unconditionally, which
#     is what the code said before 15 Aug 2026.
t=$(newtree s1_init_at_entry)
mutate "$t/$ANA" 's/    if \.accumulate = 0\n        \@emlCSVInit\n    endif/    \@emlCSVInit/g' &&
{ o=$(drive "$t"); report s1_init_at_entry SOURCE "$(runv57 "$t/plugin" "$o")"; }

# S2  The press boundary removed: every call accumulates, so two single-column
#     wizard presses merge into one frame.
t=$(newtree s2_no_press_boundary)
mutate "$t/$ANA" 's/    \.accumulate = 0\n    if \.testType\$ <> "single"/    .accumulate = 1\n    if 1 = 0/' &&
{ o=$(drive "$t"); report s2_no_press_boundary SOURCE "$(runv57 "$t/plugin" "$o")"; }

# S3  NEW-G4-1 reverted on the one-way arm: back to resid / sigma.
t=$(newtree s3_oneway_resid_over_sigma)
mutate "$t/$ANA" 's/                \.std = \(\.v - \.fit\) \/ \(\.sigma \* sqrt \(1 - \.hat\)\)/                .std = (.v - .fit) \/ .sigma/' &&
{ o=$(drive "$t"); report s3_oneway_resid_over_sigma SOURCE "$(runv57 "$t/plugin" "$o")"; }

# S4  NEW-G4-1 reverted on the two-way arm. Only the divisor changes, so the
#     file still parses and the case exercises the value rather than the gate.
t=$(newtree s4_twoway_resid_over_sigma)
mutate "$t/$ANA" 's/                \.\.\. \/ \(\.sigma \* sqrt \(1 - \.hat\)\)/                ... \/ .sigma/' &&
{ o=$(drive "$t"); report s4_twoway_resid_over_sigma SOURCE "$(runv57 "$t/plugin" "$o")"; }

# S4b The leverage column stops being emitted, while .std.resid stays right.
t=$(newtree s4b_no_hat_emitted)
mutate "$t/$ANA" 's/            \@emlAugmentNum: "\.hat", \.r, \.hat\n//g' &&
{ o=$(drive "$t"); report s4b_no_hat_emitted SOURCE "$(runv57 "$t/plugin" "$o")"; }

# S5  NEW-G6-1 reverted: the RM refusal drops its exclusion disclosure.
t=$(newtree s5_rm_no_disclosure)
mutate "$t/$ANA" 's/        \@eml_completeCaseDisclosure: \.n \+ \.nExcluded, \.n, \.nExcluded,\n        \.\.\. emlExtractConditionMatrix\.parseNote\$\n        if eml_completeCaseDisclosure\.note\$ <> ""\n            \.error\$ = \.error\$ \+ " " \+ eml_completeCaseDisclosure\.note\$\n        endif\n        goto END_RM/        goto END_RM/' &&
{ o=$(drive "$t"); report s5_rm_no_disclosure SOURCE "$(runv57 "$t/plugin" "$o")"; }

# S6  The disclosure fires unconditionally -- the failure mode that makes a
#     disclosure worthless. Only the complete-case direction can see this.
t=$(newtree s6_disclosure_always)
mutate "$t/$ANA" 's/procedure eml_completeCaseDisclosure: \.nRows, \.n, \.nExcluded, \.parseNote\$\n    \.note\$ = ""\n    if \.nExcluded > 0/procedure eml_completeCaseDisclosure: .nRows, .n, .nExcluded, .parseNote\$\n    .note\$ = ""\n    if 1 = 1/' &&
{ o=$(drive "$t"); report s6_disclosure_always SOURCE "$(runv57 "$t/plugin" "$o")"; }

# S7  NEW-G12-3 reverted: the paired path stops refusing and returns success.
t=$(newtree s7_paired_no_refusal)
mutate "$t/$ANA" 's/    if \.ranSomething = 0\n/    if 1 = 0\n/' &&
{ o=$(drive "$t"); report s7_paired_no_refusal SOURCE "$(runv57 "$t/plugin" "$o")"; }

# S8  The refusal keeps refusing but loses the n it was decided on. The gold
#     standard is CONTENT, not the fact of a modal, so this must bite too.
t=$(newtree s8_refusal_loses_n)
mutate "$t/$ANA" 's/""" give n = " \+ string\$ \(\.n\)\n        \.\.\. \+ " complete pairs, and every one of those pairs has the same "/""" cannot be compared. Every one of those pairs has the same "/' &&
{ o=$(drive "$t"); report s8_refusal_loses_n SOURCE "$(runv57 "$t/plugin" "$o")"; }

# S9  The wrapper stops looping over columns -- the pin that keeps the
#     harness's reproduction honest. Source-only: no plugin behaviour changes.
t=$(newtree s9_wrapper_loop_gone)
mutate "$t/plugin/scripts/eml-check-normality.praat" \
    's/for iSel from 1 to nNumericCols/for iSel from 1 to 1/' &&
report s9_wrapper_loop_gone SOURCE "$(runv57 "$t/plugin" "$OUT")"

# S10 The wrapper starts clearing the collectors itself. Source-only.
t=$(newtree s10_wrapper_clears)
mutate "$t/plugin/scripts/eml-check-normality.praat" \
    's/    for iSel from 1 to nNumericCols/    \@emlCSVInit\n    for iSel from 1 to nNumericCols/' &&
report s10_wrapper_clears SOURCE "$(runv57 "$t/plugin" "$OUT")"

# S11 The paired wrapper stops routing .error$ to the shared refusal dialog.
#     Source-only: the orchestrator is untouched, so the artefact would not
#     move even if this were driven -- which is exactly the point. A wrapper
#     that swallows a correct refusal shows up nowhere else.
t=$(newtree s11_wrapper_no_dialog)
mutate "$t/plugin/scripts/eml-compare-paired.praat" \
    's/\@emlErrorDialog: emlRunPairedAnalysis\.error\$/\@emlNotADialog: emlRunPairedAnalysis.error\$/' &&
report s11_wrapper_no_dialog SOURCE "$(runv57 "$t/plugin" "$OUT")"

# S12 .hat is dropped from the augment whitelist. Source-only, deliberately:
#     driving it makes @eml_vocabCheck exitScript at the emission site, which
#     kills the drive and proves only that the writer is loud on EMIT. The
#     silent drop the audit warned about happens at WRITE, to a column nobody
#     emitted a check for -- so what has to be pinned is the vocabulary text.
t=$(newtree s12_vocab_drops_hat)
mutate "$t/plugin/stats/eml-result-writer.praat" \
    's/emlVocabAugment\$ = "\.fitted \.se\.fit \.resid \.std\.resid \.hat \.cooksd \.rank"/emlVocabAugment\$ = ".fitted .se.fit .resid .std.resid .cooksd .rank"/' &&
report s12_vocab_drops_hat SOURCE "$(runv57 "$t/plugin" "$OUT")"

# S13 The press test goes back to branching on the migration flag, which v46
#     forbids in this file. v57 says so first, with the reason attached.
t=$(newtree s13_press_reads_declared)
mutate "$t/$ANA" 's/        \.stillOurs = 0\n/        .stillOurs = 0\n        \; emlResult_declared\n/' &&
report s13_press_reads_declared SOURCE "$(runv57 "$t/plugin" "$OUT")"

# ---------------------------------------------------------------------------
# ARTEFACT CASES -- corrupt the drive's own output only
# ---------------------------------------------------------------------------
artefact () {   # artefact <name> <shell-body operating on $A>
    local name="$1"; shift
    local A="$WORK/$name"
    rm -rf "$A"; cp -r "$OUT" "$A"
    local before after
    before=$(find "$A" -type f -exec md5sum {} + | sort | md5sum)
    ( A="$A"; eval "$@" )
    after=$(find "$A" -type f -exec md5sum {} + | sort | md5sum)
    if [[ "$before" == "$after" ]]; then
        echo "UNBUILT  $name -- the corruption changed nothing"; FAILED=1; return
    fi
    report "$name" ARTEFACT "$(runv57 "$REPO/plugin" "$A")"
}

# A1  A tidy row is deleted after the fact: the row count and the column count
#     disagree, which is the assertion the audit asked for by name.
artefact a1_tidy_row_deleted \
    'grep -v "^shimmer_pct," "$A/norm/demo_normality_normality_tidy.csv" > "$A/t" && mv "$A/t" "$A/norm/demo_normality_normality_tidy.csv"'

# A2  The count matches but the SET does not: one column exported twice and
#     another not at all. This is what defeats a count-only check.
artefact a2_column_duplicated \
    'perl -pi -e "s/^shimmer_pct,/F0_Hz,/" "$A/norm/demo_normality_normality_tidy.csv"'

# A3  Three rows, one column's numbers: the pairing broken while the shape
#     stays perfect.
artefact a3_pairing_scrambled \
    'perl -pi -e "s/^F0_Hz,[^,]+,[^,]+,/F0_Hz,0.9741217400116039,0.48099074318990653,/" "$A/norm/demo_normality_normality_tidy.csv"'

# A4  The multi-model glance goes back to carrying one unattributed statistic.
artefact a4_glance_unattributed \
    'printf "statistic,p.value,nobs,method\n0.97412174,0.48099074,40,Shapiro-Wilk normality test\n" > "$A/norm/demo_normality_normality_glance.csv"'

# A5  The single-column press starts accumulating too.
artefact a5_single_press_grows \
    'cat "$A/norm/demo_normality_normality_tidy.csv" > "$A/norm/demo_normality_one_normality_tidy.csv"'

# A6  A case disappears from the drive -- the census direction.
artefact a6_case_missing \
    'grep -v "^rm_complete	" "$A/refusals.tsv" > "$A/t" && mv "$A/t" "$A/refusals.tsv"'

# A7  A case appears that no check reads -- the other census direction.
artefact a7_phantom_case \
    'printf "brand_new_case\terror\tsomething\n" >> "$A/refusals.tsv"'

# A8  The drive was never run at all.
mkdir -p "$WORK/a8_no_drive"
report a8_no_drive ARTEFACT "$(runv57 "$REPO/plugin" "$WORK/a8_no_drive")"

# A9  The refusal keeps its shape but loses the columns it names.
artefact a9_refusal_loses_columns \
    'perl -pi -e "s/SPL_soft/the first column/g; s/SPL_medium/the second column/g" "$A/refusals.tsv"'

# A10 The zero-variance path declares a result again, so Save would offer a
#     half-analysis even though the modal refused.
artefact a10_refusal_still_declares \
    'perl -pi -e "s/^paired_zerovar\tdeclared\t0/paired_zerovar\tdeclared\t1/" "$A/shape.tsv"'

# A11 The augment loses .hat while every value it still carries stays right.
artefact a11_augment_hat_stripped \
    'perl -F, -lane "\$i=0; \$i++ until \$F[\$i] eq \".hat\" or \$i>20;" -e "" "$A/aug/anova1_augment.csv" ; python3 - "$A/aug/anova1_augment.csv" <<PY
import csv,sys
p=sys.argv[1]
rows=list(csv.reader(open(p)))
i=rows[0].index(".hat")
for r in rows: del r[i]
csv.writer(open(p,"w"),lineterminator="\n").writerows(rows)
PY'

echo
if [[ $FAILED -eq 0 ]]; then
    echo "breaktest: every case went RED"
else
    echo "breaktest: at least one case is DEAD or UNBUILT -- see above"
fi
exit $FAILED
