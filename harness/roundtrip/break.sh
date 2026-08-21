#!/usr/bin/env bash
# ============================================================================
# harness/roundtrip/break.sh — a harness whose checks have never been seen to
#                              fail is not evidence
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Every break is a COPY of one recorder file with one deliberate defect in it,
# driven through $EML_ROUNDTRIP_FILE and read by validate/v110 through
# $EML_ROUNDTRIP_DIR. The working tree is never touched and never has to be,
# which is the point: a break test that edits the tree and puts it back is one
# interrupted run away from committing a defect. Everything not named in the
# override is the shipped file, so each run isolates one claim.
#
# WHAT EACH BREAK IS FOR, and they are chosen so that no two of them go red on
# the same set of checks — a break that reddens everything says only that the
# suite noticed something.
#
#   no_edit_step     scripts/eml-record-edit-step.praat stops recording the
#                    step. THE DEFECT THE ORIGINAL DEMONSTRATION FOUND, put
#                    back: the session analyses 4242 and the emitted file says
#                    nothing about the cell, so a colleague running it against
#                    the CSV as sent gets 100 in row 1, an F five orders of
#                    magnitude away, a different figure, and no warning
#                    anywhere. It is the one defect in this list that a reader
#                    of the emitted file cannot see.
#
#   no_convert_step  @emlRecordConvert stops recording. Nothing about the
#                    numbers or the figure moves — the conversion is the last
#                    action in the session and no step depends on it — so the
#                    ONLY thing that can see it is the vocabulary census:
#                    `convert` is a kind the recorder can express and the file
#                    no longer carries. This is the break that says section 3
#                    is load-bearing rather than decorative.
#
#   never_erase      the draw step's page statement is emitted with
#                    eraseFirst = 0 instead of the value the session drew
#                    with. On an empty page that is the same picture, so the
#                    colleague's leg stays byte-identical and every check on
#                    it stays green. The HOSTILE leg, which has a drawing on
#                    the page before the script runs, comes back with that
#                    drawing still under the figure. This is the break that
#                    proves the hostile leg is doing work no ordinary replay
#                    can do.
#
#   no_provenance    the analysis step stops emitting @emlReportContext. The
#                    numbers, the figure and the five result files are
#                    untouched; what changes is one line of one report, which
#                    goes back to claiming the analysis came from a dialog
#                    that was not open. The narrowest break here, and it is
#                    here because a report is a document somebody quotes.
#
#   Run:  bash harness/roundtrip/break.sh [name-substring]
#   Out:  harness/roundtrip/breaks/BREAKS.tsv       break, red count, first red
#         harness/roundtrip/breaks/<name>.v110.log  the whole report
#         harness/roundtrip/breaks/<name>/          that break's own out/
#
#   A SUBDIRECTORY OF ITS OWN, because run.sh clears out/ on every run and
#   would take the break record with it.
#
#   $EML_ROUNDTRIP_BREAK_WORK moves the damaged copies off the default path.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ============================================================================
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$HERE/.." && pwd)/_env.sh" || exit 1
ROOT="$EML_ROOT"
OUT="$HERE/breaks"
WORK="${EML_ROUNDTRIP_BREAK_WORK:-${TMPDIR:-/tmp}/eml-roundtrip-breaks}"
FILTER="${1:-}"

mkdir -p "$OUT" "$WORK"
TSV="$OUT/BREAKS.tsv"
[[ -n "$FILTER" ]] || : > "$TSV"

REC="$ROOT/plugin/stats/eml-record.praat"
EDT="$ROOT/plugin/scripts/eml-record-edit-step.praat"

# damage <name> <source-file> <tag> -> prints the path of the damaged copy
#
# PYTHON STRING SURGERY RATHER THAN sed, and the edit is REFUSED LOUDLY if the
# text it is anchored on has drifted. A break that silently edited nothing
# would drive the undamaged recorder and report a green break test, which is
# the one outcome this whole file exists to prevent.
damage () {
    local name="$1" src="$2" tag="$3"
    local d="$WORK/$name"
    mkdir -p "$d"
    local dst="$d/$(basename "$src")"
    python3 - "$src" "$dst" "$tag" <<'PY'
import sys
src, dst, tag = sys.argv[1], sys.argv[2], sys.argv[3]
s = open(src, encoding="utf-8").read()
orig = s

if tag == "no_edit_step":
    s = s.replace('\n@emlRecordStep: "edit", emlPhrase.result$',
                  '\ngoto END_RECORD_EDIT_STEP\n@emlRecordStep: "edit", emlPhrase.result$')
elif tag == "no_convert_step":
    s = s.replace('\n    @emlRecordStep: "convert",',
                  '\n    goto END_RECORD_CONVERT\n    @emlRecordStep: "convert",')
elif tag == "never_erase":
    s = s.replace('.out$ = "emlEraseFirst = " + string$ (emlEraseFirst) + newline$',
                  '.out$ = "emlEraseFirst = " + "0" + newline$')
elif tag == "no_provenance":
    s = s.replace('            .text$ = .text$ + "@emlReportContext: " + .q$ + .prov$ + .q$',
                  '            .text$ = .text$ + "; provenance not emitted"')
else:
    sys.exit("unknown break tag: " + tag)

if s == orig:
    sys.exit("BREAK DID NOT APPLY (%s in %s) -- the anchor text has moved" % (tag, src))
open(dst, "w", encoding="utf-8").write(s)
PY
    [[ -f "$dst" ]] || { echo "break $name: could not damage $(basename "$src")" >&2; return 1; }
    printf '%s' "$dst"
}

run_break () {
    local name="$1" override="$2"
    local o="$OUT/$name"
    rm -rf "$o"; mkdir -p "$o"
    EML_ROUNDTRIP_FILE="$override" EML_ROUNDTRIP_DIR="$o" \
        timeout 1200 bash "$HERE/run.sh" > "$o/run.log" 2>&1
    local drc=$?
    EML_ROUNDTRIP_DIR="$o" \
        Rscript "$ROOT/validate/v110_roundtrip_replay.R" \
        > "$OUT/$name.v110.log" 2>&1
    local red first
    red=$(grep -c '^FAIL' "$OUT/$name.v110.log")
    first=$(grep -m1 '^FAIL' "$OUT/$name.v110.log" \
            | sed 's/^FAIL  *v110  *//; s/  computed.*//; s/  reported.*//' | cut -c1-96)
    printf '%s\t%s\t%s\t%s\n' "$name" "$red" "$drc" "${first:-<none>}" >> "$TSV"
    printf '  %-16s red=%-4s drive_rc=%-3s %s\n' "$name" "$red" "$drc" \
        "${first:-NOTHING WENT RED}"
    # The reds themselves, one line each, so the record says WHICH claims fell
    # rather than how many.
    grep '^FAIL' "$OUT/$name.v110.log" \
        | sed 's/^FAIL  *v110  *//; s/  computed.*//; s/  reported.*//' \
        | sed 's/^/      · /' | cut -c1-100
}

want () {
    [[ -z "$FILTER" ]] && return 0
    case "$1" in *"$FILTER"*) return 0 ;; *) return 1 ;; esac
}

echo "roundtrip break: damaged copies under $WORK"

# THE CONTROL RUN COMES FIRST, and it is not a formality. A break test whose
# UNDAMAGED run is red is measuring something else entirely, and every "red"
# below it would be that same something.
if want shipped; then
    run_break shipped ""
fi

if want no_edit_step; then
    f="$(damage no_edit_step "$EDT" no_edit_step)" && run_break no_edit_step "$f"
fi

if want no_convert_step; then
    f="$(damage no_convert_step "$REC" no_convert_step)" && run_break no_convert_step "$f"
fi

if want never_erase; then
    f="$(damage never_erase "$REC" never_erase)" && run_break never_erase "$f"
fi

if want no_provenance; then
    f="$(damage no_provenance "$REC" no_provenance)" && run_break no_provenance "$f"
fi

echo
echo "record: $TSV"
