#!/usr/bin/env bash
# ============================================================================
# asciifold/run.sh -- non-ASCII text driven through the shipped save path
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# THE DEFECT THIS EXISTS FOR IS TOTAL, SILENT, AND HAS NO ERROR MESSAGE.
#
# Measured on Praat 6.6.30 in this container, 20 Aug 2026, with a fresh
# pref-dir -- so this is the DEFAULT, not a setting anyone chose. Praat writes
# TextEncoding.outputEncoding: "try ASCII, then UTF-16", and the "try" is
# per FILE, not per character:
#
#     writeFileLine: "plain.txt",  "abc plain ascii only"   -> ASCII text, 21 bytes
#     writeFileLine: "onerule.txt", "===" + U+2550 + "==="  -> UTF-16BE, BOM fe ff, 7 NUL bytes
#     writeFileLine: "curly.txt",  "he said " + U+201C ...  -> UTF-16BE, BOM fe ff, 12 NUL bytes
#     writeFileLine: "emoji.txt",  "group " + U+1F3A4 ...   -> UTF-16BE, BOM fe ff, 11 NUL bytes
#
# and the append case is worse than the write case, because it is retroactive:
#
#     appendFileLine: "append.txt", "first line ascii"      -> file is ASCII here
#     appendFileLine: "append.txt", "second has " + U+00B0  -> the WHOLE file, first line
#                                                              included, is rewritten UTF-16BE
#
# ONE character. Not the line, not the cell -- the file. A _results.csv that
# computed everything correctly and differs from a good one by a single Greek
# letter in a single group label is read by R's read.csv, by pandas, by Excel
# and by this repository's own validate/ scripts as binary. Nothing warns. The
# user's run succeeded and their export is unopenable.
#
# @emlAsciiFold in stats/eml-output.praat is the guard, and it is placed at the
# two points where text becomes bytes: @emlReportToFile folds the report body
# before writeFileLine:, and @eml_csvQuote folds each cell BEFORE the RFC 4180
# quote test. Until this harness existed, nothing anywhere drove a single
# non-ASCII character through either of them. The fold was covered by reading.
#
# WHY THE ASSERTIONS ARE ABOUT BYTES ON DISK AND NOT ABOUT THE PROCEDURE.
# @emlAsciiFold is trivially testable in isolation and testing it in isolation
# proves nothing that matters: the failure mode is not "the fold maps the wrong
# character", it is "the fold is not reached". Delete both call sites and a
# unit test of the procedure stays green while every file the plugin writes
# turns to UTF-16. So every leg here calls a SAVER -- @emlReportToFile,
# @emlExportStatsCSV, @emlSaveInfoToFile -- and validate/v104 opens what landed
# and reads its bytes.
#
# THE THREE THINGS v104 ASKS OF EACH FILE
#   1. every byte is ASCII                      -- the fold ran at all
#   2. no byte-order mark and no NUL byte        -- what a UTF-16 file looks
#      like to a tool expecting UTF-8, which is how the damage is actually met
#   3. the meaning survived                      -- "chi^2", not a blank; the
#      report still has its eight lines and its tab stops; the CSV still reads
#      back through read.csv with the curly-quoted cell intact
#
# Point 3 is not decoration. A fold that replaced everything with "" would pass
# points 1 and 2 perfectly and would silently empty a user's group labels.
#
# THE WITNESS LEG IS NOT A VERDICT. `broom` drives @emlResultWrite, the
# three-file exporter, which quotes through @eml_rwQuote -- a SECOND RFC 4180
# routine that does not fold. Its frames land as UTF-16 today. That is recorded
# in out/WITNESS.tsv and printed, and this harness does not fail on it, because
# the fix belongs to stats/eml-result-writer.praat and not to this file. The
# measurement is kept so the gap is a number rather than an opinion.
#
# DRIVING A DIFFERENT TREE. $EML_ASCIIFOLD_TREE names the plugin folder to
# drive; it defaults to $EML_ROOT/plugin. drive.praat carries __EML_TREE__ in
# its include lines and is staged with that substituted, because Praat cannot
# take a variable in an `include`. That is what let this harness be shown red:
# copy the plugin to /tmp, delete the two @emlAsciiFold call sites in the copy,
# point $EML_ASCIIFOLD_TREE at it, and every byte check fails.
#
# Run from anywhere:  bash harness/asciifold/run.sh
# Exit 0 = every leg ran and left the files v104 needs to judge.
#
# Output: harness/asciifold/out/ -- $EML_ASCIIFOLD_DIR overrides the folder.
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

OUT="${EML_ASCIIFOLD_DIR:-$SCRIPT_DIR/out}"
TREE="${EML_ASCIIFOLD_TREE:-$EML_ROOT/plugin}"
PREFS="$SCRIPT_DIR/prefs"

for f in stats/eml-core-utilities.praat stats/eml-output.praat \
         stats/eml-result-writer.praat; do
    [[ -r "$TREE/$f" ]] || { echo "asciifold: FAIL -- not a plugin tree: $TREE/$f"; exit 1; }
done

# A CLEAN OUT/ EVERY RUN. @emlReportToFile uniques its path against what is
# already on disk, so a stale report.txt would make this run land as
# report_1.txt -- and a byte check reading report.txt would then be reading the
# PREVIOUS build's file. Against the no-fold copy that is not a hypothetical:
# it would read the folded file from the good run and report a pass.
rm -rf "$OUT"
mkdir -p "$OUT" "$PREFS"

# A FRESH PREF DIR, and the point is what it does NOT contain. The encoding
# behaviour this harness is about is Praat's DEFAULT, so seeding a prefs5 with
# an outputEncoding line would make the run describe a configuration rather
# than the one a user gets out of the box.
rm -rf "$PREFS"; mkdir -p "$PREFS"

# --- stage the driver against the tree under test ---------------------------
# The staged copy lives in out/ and is kept, not deleted: when a leg fails it
# is the exact text Praat ran, includes and all.
DRIVER="$OUT/drive.staged.praat"
sed -e "s|__EML_TREE__|$TREE|g" "$SCRIPT_DIR/drive.praat" > "$DRIVER"
grep -q "__EML_TREE__" "$DRIVER" \
    && { echo "asciifold: FAIL -- tree placeholder not substituted"; exit 1; }

fail=0
note () { printf '%-8s %s\n' "$1" "$2"; }

run_leg () {
    local leg="$1"
    local log="$OUT/$leg.log"
    env -u DISPLAY timeout 300 "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" \
        --run "$DRIVER" "$leg" "$OUT" > "$log" 2>&1
    local rc=$?
    # THE EXIT CODE IS NOT ENOUGH ON ITS OWN. A leg whose saver aborts leaves a
    # partial outputs.tsv and Praat can still exit 0 in some abort paths, so the
    # DONE marker written as the last line of the driver is what says the leg
    # reached the end.
    if [[ $rc -ne 0 ]]; then
        note "$leg" "FAIL: praat exited $rc -- see $log"; fail=1; return
    fi
    if ! grep -q "^DONE	$leg\$" "$OUT/$leg.outputs.tsv" 2>/dev/null; then
        note "$leg" "FAIL: leg did not reach the end -- see $log"; fail=1; return
    fi
    note "$leg" "ran"
}

for leg in report csv info broom; do
    run_leg "$leg"
done

# --- the byte census --------------------------------------------------------
# WRITTEN BY THE HARNESS, READ BY v104 AS A CROSS-CHECK, not as the evidence.
# v104 opens the files itself with readBin, because a census the harness
# computed and the validator merely re-printed could agree with itself while
# both were wrong about the file. What this table is for is the human reading
# the run: it says in four columns which file went to UTF-16 and which did not.
CENSUS="$OUT/BYTES.tsv"
printf 'name\tbytes\tbom\tnul\tnonascii\n' > "$CENSUS"
while IFS= read -r f; do
    b="$(basename "$f")"
    case "$b" in BYTES.tsv|WITNESS.tsv|*.log|drive.staged.praat) continue ;; esac
    size="$(wc -c < "$f" | tr -d ' ')"
    bom="$(head -c 2 "$f" | od -An -tx1 | tr -d ' \n')"
    nul="$(tr -d -c '\000' < "$f" | wc -c | tr -d ' ')"
    # LC_ALL=C so the class is BYTES and not the locale's idea of a character:
    # under a UTF-8 locale `tr` folds a multi-byte sequence to one unit and the
    # count stops being a count of bytes outside ASCII.
    non="$(LC_ALL=C tr -d -c '\200-\377' < "$f" | wc -c | tr -d ' ')"
    printf '%s\t%s\t%s\t%s\t%s\n' "$b" "$size" "$bom" "$nul" "$non" >> "$CENSUS"
done < <(find "$OUT" -maxdepth 1 -type f | sort)

# --- the witness, separated from the verdict --------------------------------
WIT="$OUT/WITNESS.tsv"
printf 'name\tbytes\tbom\tnul\tnonascii\n' > "$WIT"
grep -E '^broom_' "$CENSUS" >> "$WIT"
nbad=$(awk -F'\t' 'NR>1 && $5 > 0' "$WIT" | wc -l | tr -d ' ')
if [[ "$nbad" -gt 0 ]]; then
    echo
    echo "NOTE: $nbad of the three-file broom frames left non-ASCII bytes on disk."
    echo "      @emlResultWrite quotes through @eml_rwQuote, which does not fold."
    echo "      Recorded in $WIT. Not a failure of this harness -- the fix belongs"
    echo "      to stats/eml-result-writer.praat."
fi

# --- what this harness can judge for itself ---------------------------------
# ONLY WHAT WOULD MAKE THE ARTEFACT MEANINGLESS. The detailed claims -- the
# substitutions, the line and tab structure, the read.csv round trip -- are
# validate/v104_ascii_fold.R's, because they need a CSV reader. What is checked
# here is that the three judged legs produced a file at all; a missing file is
# the one state in which v104's checks would have nothing to disagree with.
for leg in report csv info; do
    p="$(awk -F'\t' -v k=path '$1==k {print $2}' "$OUT/$leg.outputs.tsv" 2>/dev/null)"
    [[ -n "$p" && -s "$p" ]] \
        || { note "$leg" "FAIL: saver wrote no file -- see $OUT/$leg.log"; fail=1; }
done

n_art=$(( $(wc -l < "$CENSUS") - 1 ))
echo
echo "files measured: $n_art  ->  $CENSUS"

if [[ $fail -eq 0 ]]; then
    echo "asciifold: PASS -- four legs, $n_art files measured"
    echo "  tree: $TREE"
    echo "  next: Rscript validate/v104_ascii_fold.R"
    exit 0
fi
echo "asciifold: FAIL"
exit 1
