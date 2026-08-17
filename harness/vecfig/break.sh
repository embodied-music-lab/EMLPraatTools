#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# vecfig/break.sh -- watch v86 go red
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
#   bash harness/vecfig/break.sh
#
# NOTHING IS VALIDATED UNTIL A CHECK TESTS IT AND HAS BEEN SEEN TO FAIL. Each
# break below removes one part of the vector-figure work from a COPY of
# plugin/stats, drives the whole harness against that copy, and runs
# validate/v86 against the result. The working tree is never edited, so an
# interrupted break test cannot leave the repair reverted.
#
#   no_landed_check     the vector arms count a file because the Save command
#                       was issued, instead of because the file arrived. This
#                       is the silent failure the whole feature is against.
#   no_alternatives     the message keeps every other sentence and loses the
#                       paragraph that names PNG, EPS and PDF and says what to
#                       do next.
#   no_png_check        the PNG's landed check is deleted and its count made
#                       unconditional -- the case no drive on a machine where
#                       PNG works can see.
#   pdf_box_on_windows  the PDF tickbox offered on every host, including the
#                       one whose Praat is documented not to have the command.
#   png_only_message    the redirect back to closing on the PNG, which tells a
#                       user who asked for vector that their raster is safe.
#   recorder_own_save   @emlRecordReplaySave writing its own PNG again, so a
#                       recorded EPS replays as a PNG and says nothing.
#   shared_format_var   the per-save suffix flattened, so two saves with
#                       different choices collide on one variable.
#
# THE LAST TWO DAMAGE eml-record.praat AND THE OTHERS eml-output.praat, which
# is why mutate.py names the file for each break rather than being handed one.
#
# Output: out/BREAKS.tsv, one row per break with the red count.
# ---------------------------------------------------------------------------
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
BOUT="$HERE/out/breaks"
BTSV="$HERE/out/BREAKS.tsv"

mkdir -p "$BOUT"
printf 'break\tchecks\tfailed\n' > "$BTSV"

run_break() {
    local name="$1"
    local tree="$BOUT/$name/stats"
    rm -rf "$BOUT/$name"
    mkdir -p "$BOUT/$name"
    cp -r "$ROOT/plugin/stats" "$tree"

    python3 "$HERE/mutate.py" "$name" "$tree" || return 1

    EML_VECFIG_SRC="$tree" EML_VECFIG_OUT="$BOUT/$name/out" \
        bash "$HERE/run.sh" > "$BOUT/$name/run.log" 2>&1

    # BOTH SOURCES ARE POINTED AT THE DAMAGED COPY, or a break in the
    # recorder would be validated against the working tree's healthy one and
    # every source check would pass over it.
    local log="$BOUT/$name/v86.log"
    EML_VECFIG_DIR="$BOUT/$name/out" EML_VECFIG_FILE="$tree/eml-output.praat" \
        EML_VECFIG_RECORD_FILE="$tree/eml-record.praat" \
        Rscript "$ROOT/validate/v86_vector_figure_export.R" > "$log" 2>&1
    local line
    line="$(grep -E '^[0-9]+ checks' "$log" | tail -1)"
    local checks failed
    checks="$(echo "$line" | awk '{print $1}')"
    failed="$(echo "$line" | awk '{print $5}')"
    printf '%s\t%s\t%s\n' "$name" "${checks:-0}" "${failed:-0}" >> "$BTSV"
    # The damaged tree and its scratch go; the v86 log stays, because the log
    # is the evidence and the tree is reproducible from mutate.py.
    rm -rf "$tree" "$BOUT/$name/out/work"
    echo "== $name: $line"
    grep '^FAIL' "$log" | head -40
    echo
}

run_break no_landed_check
run_break no_alternatives
run_break no_png_check
run_break pdf_box_on_windows
run_break png_only_message
run_break recorder_own_save
run_break shared_format_var

echo "vecfig/break: summary"
cat "$BTSV"
