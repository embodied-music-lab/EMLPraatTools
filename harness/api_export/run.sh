#!/usr/bin/env bash
# ============================================================================
# api_export/run.sh -- @emlExportResultFiles called as CODE, not clicked
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS HARNESS EXISTS. @emlExportResultFiles is the plugin's export
# implementation and it has two callers inside the plugin -- @emlSavePanel and
# the graphs form -- both of which are dialogs. It has a third caller the
# plugin cannot see: a voice researcher's own Praat script. The procedure's own
# header says so, and says why it matters:
#
#     "this procedure is also the CODE/API export path -- dialog-free,
#      callable from a user's own script -- and there the first call in a
#      fresh session has nothing set. The guard existed because that case is
#      real, and it was the one case the guard could not survive."
#
# That guard was fixed on 14 Aug 2026 and NOTHING drove the case it was fixed
# for. harness/savepaths presses Save, which means every one of its legs
# arrives at the exporter through a panel that has already established there
# is something to export and has already called createFolder:. An API caller
# has neither of those. v46 is static and reads the source. So the whole API
# surface -- the fork, the collision walk, the empty return, the folder
# precondition -- was covered by reading.
#
# HEADLESS ON PURPOSE. No Xvfb, no DISPLAY, no dialogs: plain `praat --run`.
# That is not a convenience, it is the population. A user's script runs the
# same way, and a harness that needed a display would be testing the panel
# again.
#
# ONE PROCESS PER LEG. The `fresh` leg only means anything in a session where
# no orchestrator has run, so the legs cannot share a Praat.
#
# LEGS
#   declared   one-way ANOVA with Tukey -> five broom frames
#   collide    the same export twice under one base -> two complete sets
#   partial    normality -> two frames and a populated .skipped$
#   loop       the batch pattern -- two columns, two analyses, two exports
#   legacy     @emlRunDescriptiveAnalysis -> one long-format file
#   fresh      nothing ran at all -> declared=0 nWritten=0 reason=empty
#   nofolder   the folder was never created -> Praat's own error, no output
#   example    docs/API_EXPORT.md's script, run verbatim from a user folder
#
# Run from anywhere:  bash harness/api_export/run.sh
# Exit 0 = every leg behaved as recorded above.
#
# Output: harness/api_export/out/ -- ARTEFACTS.tsv (name<TAB>bytes) plus every
#         file the legs wrote. $EML_API_EXPORT_DIR overrides the folder.
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

OUT="${EML_API_EXPORT_DIR:-$SCRIPT_DIR/out}"
PREFS="$SCRIPT_DIR/prefs"
DATA="$EML_ROOT/evidence/csv/demo_3groups_input.csv"

[[ -r "$DATA" ]] || { echo "FAIL: fixture missing: $DATA"; exit 1; }

# A CLEAN OUT/ EVERY RUN. The collision leg's whole subject is what happens
# when a file is already there, so a stale out/ would make the FIRST call of
# that leg collide too and the artefact would describe the previous run.
rm -rf "$OUT"
mkdir -p "$OUT" "$PREFS"

fail=0
note () { printf '%-10s %s\n' "$1" "$2"; }

run_leg () {
    local leg="$1" want_exit="$2"
    local log="$OUT/$leg.log"
    env -u DISPLAY timeout 300 "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" \
        --run "$SCRIPT_DIR/api_export.praat" "$leg" "$DATA" "$OUT" \
        > "$log" 2>&1
    local rc=$?
    if [[ "$rc" -ne "$want_exit" ]]; then
        note "$leg" "FAIL: praat exited $rc, expected $want_exit -- see $log"
        fail=1
        return
    fi
    note "$leg" "ran (exit $rc)"
}

# --- the six legs the driver owns -------------------------------------------
for leg in declared collide partial loop legacy fresh nofolder; do
    run_leg "$leg" 0
done

# --- the documented example, run verbatim from a user's own folder ----------
# STAGED, NOT COPIED INTO THE PLUGIN. The point of this leg is the folder a
# user's script actually lives in -- outside the plugin tree -- because that is
# the one place plugin/scripts/eml-lib.praat cannot be included from. Two
# substitutions and no others: the install path the recorder's emitted scripts
# already tell a user to edit, and the two paths a user types for themselves.
USERDIR="$OUT/user_folder"
mkdir -p "$USERDIR"
sed -e "s|~/.praat-dir/plugin_EML_Praat_Tools|$EML_ROOT/plugin|g" \
    -e "s|__EML_DATA__|$DATA|g" \
    -e "s|__EML_OUT__|$OUT/example|g" \
    "$SCRIPT_DIR/doc_example.praat" > "$USERDIR/my_analysis.praat"

env -u DISPLAY timeout 300 "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" \
    --run "$USERDIR/my_analysis.praat" > "$OUT/example.log" 2>&1
rc=$?
if [[ $rc -ne 0 ]]; then
    note "example" "FAIL: the documented example did not run (exit $rc) -- see $OUT/example.log"
    fail=1
else
    note "example" "ran (exit 0)"
fi

# The example's own frames land in out/example/; flatten them under the leg
# name so ARTEFACTS.tsv stays one list of one directory, the way
# harness/savepaths writes its evidence.
if [[ -d "$OUT/example" ]]; then
    for f in "$OUT/example"/*; do
        [[ -e "$f" ]] || continue
        mv "$f" "$OUT/example.$(basename "$f")"
    done
    rmdir "$OUT/example" 2>/dev/null
fi
rm -rf "$USERDIR"
# The example's include block is the one docs/API_EXPORT.md prints. Keep the
# staged, path-substituted copy out of the artefact so ARTEFACTS.tsv lists
# results rather than scaffolding.

# --- the manifest -----------------------------------------------------------
# EVERY FILE IN out/, INCLUDING THE LOGS AND THE outputs.tsv FILES. A manifest
# that listed only the CSVs would let a leg lose its report and still look
# complete, which is the failure mode v50's coverage check is built on.
MAN="$OUT/ARTEFACTS.tsv"
: > "$MAN"
while IFS= read -r f; do
    b="$(basename "$f")"
    [[ "$b" == "ARTEFACTS.tsv" ]] && continue
    printf '%s\t%s\n' "$b" "$(wc -c < "$f" | tr -d ' ')" >> "$MAN"
done < <(find "$OUT" -maxdepth 1 -type f | sort)

n_art=$(wc -l < "$MAN")
echo
echo "artefacts written: $n_art  ->  $MAN"

# --- the verdicts this harness can make for itself --------------------------
# THE VALIDATOR IS validate/v50_api_export.R and it makes the detailed claims.
# What is checked here is only what would make the artefact meaningless: a leg
# that produced no report at all, and the two markers that say the driver
# reached the end of the script rather than dying quietly in the middle.
for leg in declared collide partial loop legacy fresh nofolder; do
    [[ -s "$OUT/$leg.outputs.tsv" ]] \
        || { note "$leg" "FAIL: no outputs.tsv"; fail=1; }
    grep -q "^APIEXPORT DONE leg=$leg\$" "$OUT/$leg.log" \
        || { note "$leg" "FAIL: driver did not reach the end -- see $OUT/$leg.log"; fail=1; }
done
grep -q "^APIEXPORT DONE leg=example\$" "$OUT/example.log" \
    || { note "example" "FAIL: the example did not reach the end"; fail=1; }

# THE PROOF THAT `fresh` MEANT ANYTHING. A leg that found emlResult_declared
# already set refuses rather than reporting a pass it did not earn.
grep -q "^FRESH: emlResult_declared was already set" "$OUT/fresh.log" \
    && { note "fresh" "FAIL: the session was not fresh"; fail=1; }

if [[ $fail -eq 0 ]]; then
    echo "api_export: PASS -- eight legs, $n_art artefacts"
    echo "  next: Rscript validate/v50_api_export.R"
    exit 0
fi
echo "api_export: FAIL"
exit 1
