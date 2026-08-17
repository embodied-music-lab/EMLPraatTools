#!/usr/bin/env bash
# ============================================================================
# recipes/run.sh -- every script on docs/RECIPES.md, run as it ships
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS HARNESS EXISTS. plugin/docs/RECIPES.md documents the direct-kernel
# API: Table -> vectors -> @emlTTest and its relatives, then the orchestrator
# and the exporter on top of them. That surface is what a voice researcher
# writing their own script uses, and prose about an API that nobody runs is a
# guess about an API. The house rule from v50 is the whole design brief here:
# a documented example is a tested example.
#
# THE BYTES THAT SHIP ARE THE BYTES THAT RUN. extract.py lifts each recipe's
# script out of the .md and writes it to out/scripts/ VERBATIM -- the same
# text, byte for byte, that the reader will select and paste. Nothing in this
# tree holds a second copy of a recipe, because a second copy is a copy that
# drifts, and the reader is the one running the version that is wrong.
#
# THE TWO SUBSTITUTIONS, AND NOTHING ELSE. A pasted script has exactly two
# things in it that belong to the reader's machine, and the page says so:
#
#   ~/.praat-dir/plugin_EML_StatsGraphs  ->  the plugin folder in this repo
#   ~/voice_study                        ->  the folder holding the data
#
# run.sh substitutes those two prefixes into a STAGING copy, drives that, and
# then substitutes them back and diffs against the verbatim file. If the
# round trip is not byte-identical, the substitution touched something it
# should not have and the leg fails. That check is why the committed evidence
# can stay free of machine paths without weakening the "verbatim" claim.
#
# HEADLESS ON PURPOSE. No Xvfb, no DISPLAY, no dialogs: plain `praat --run`.
# That is the population, not a convenience -- a user's script runs the same
# way, and a harness that needed a display would be testing the menus again.
#
# ONE PROCESS PER RECIPE. The exporter reads what the most recent analysis
# left in the buffer, so R3 and R4 would contaminate each other in one
# session; and R1's `writeInfoLine` is only the first line of the capture in
# a process where nothing has printed yet.
#
# THE FIXTURES
#   spl_by_group.csv   5 v 5, soprano mean 81 / mezzo mean 90 (committed)
#   pre_post.csv       9 rows, the ninth missing its `post` value (committed)
#   singers.csv        evidence/csv/demo_3groups_input.csv, copied at run
#                      time so the three-group demo data has one source
#   sustained_a.wav    synthesised by make_sound.praat at run time
#
# Each recipe gets its OWN data folder, seeded with all four, so a recipe
# that writes files cannot see a previous recipe's output and the uniquing
# walk in @emlExportResultFiles never fires. A stale folder would make the
# second run of this harness disagree with the first.
#
# Run from anywhere:  bash harness/recipes/run.sh
# Exit 0 = every recipe ran, printed something, and printed no path.
#
# Output: harness/recipes/out/ -- scripts/, EXTRACT.tsv, RESULTS.tsv,
#         FILES.tsv, one <recipe>.out per recipe, and the frames R3/R4 wrote.
#         $EML_RECIPES_DIR overrides the folder.
#
#     bash harness/recipes/run.sh
#     Rscript validate/v81_recipes.R
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

OUT="${EML_RECIPES_DIR:-$SCRIPT_DIR/out}"
PREFS="$SCRIPT_DIR/prefs"
DOC="${EML_RECIPES_DOC:-$EML_ROOT/plugin/docs/RECIPES.md}"
PLUGIN="$EML_ROOT/plugin"
FIX="$SCRIPT_DIR/fixtures"
THREEGROUP="$EML_ROOT/evidence/csv/demo_3groups_input.csv"

INSTALL_TOKEN='~/.praat-dir/plugin_EML_StatsGraphs'
DATA_TOKEN='~/voice_study'

[[ -r "$DOC" ]]        || { echo "FAIL: page missing: $DOC"; exit 1; }
[[ -r "$THREEGROUP" ]] || { echo "FAIL: fixture missing: $THREEGROUP"; exit 1; }

# A CLEAN OUT/ EVERY RUN. R3 and R4 write result files under a base name, and
# @emlExportResultFiles walks the base rather than overwriting -- so a stale
# out/ would make the second run of this harness produce `_1` names and
# disagree with the first for no reason anyone could find.
rm -rf "$OUT"
mkdir -p "$OUT/scripts" "$PREFS"

fail=0
note () { printf '%-4s %s\n' "$1" "$2"; }

# --- lift the scripts out of the page ---------------------------------------
if ! python3 "$SCRIPT_DIR/extract.py" "$DOC" "$OUT/scripts" > "$OUT/EXTRACT.tsv"; then
    echo "FAIL: extraction from $DOC"
    cat "$OUT/EXTRACT.tsv"
    exit 1
fi
RECIPES=()
while IFS=$'\t' read -r r _lines _sha; do
    RECIPES+=("$r")
done < "$OUT/EXTRACT.tsv"
echo "recipes lifted from $(basename "$DOC"): ${RECIPES[*]}"

# --- drive each one ---------------------------------------------------------
RES="$OUT/RESULTS.tsv"
FILES="$OUT/FILES.tsv"
printf 'recipe\texit\tlines\tsha256\n' > "$RES"
printf 'recipe\tfile\tbytes\n' > "$FILES"

STAGE="$OUT/staged"
WORKROOT="$OUT/work"
mkdir -p "$STAGE"

for r in "${RECIPES[@]}"; do
    verbatim="$OUT/scripts/$r.praat"
    work="$WORKROOT/$r"
    staged="$STAGE/$r.praat"
    mkdir -p "$work"

    # The data folder the pasted script names, seeded for every recipe alike.
    cp "$FIX/spl_by_group.csv" "$FIX/pre_post.csv" "$work/"
    cp "$THREEGROUP" "$work/singers.csv"
    env -u DISPLAY timeout 120 "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" \
        --run "$SCRIPT_DIR/make_sound.praat" "$work/sustained_a.wav" \
        > "$OUT/$r.makesound.log" 2>&1
    if [[ ! -s "$work/sustained_a.wav" ]]; then
        note "$r" "FAIL: fixture sound not written -- see $OUT/$r.makesound.log"
        fail=1
        continue
    fi
    rm -f "$OUT/$r.makesound.log"

    sed -e "s|$INSTALL_TOKEN|$PLUGIN|g" -e "s|$DATA_TOKEN|$work|g" \
        "$verbatim" > "$staged"

    # THE ROUND TRIP. Reverse the two substitutions and demand the original
    # back. A substitution that hit a third thing -- or a recipe that happens
    # to contain the replacement text already -- shows up here rather than as
    # a harness quietly running something the page does not print.
    if ! sed -e "s|$PLUGIN|$INSTALL_TOKEN|g" -e "s|$work|$DATA_TOKEN|g" \
            "$staged" | diff -q - "$verbatim" > /dev/null; then
        note "$r" "FAIL: the staged script does not reverse to the page's text"
        fail=1
        continue
    fi

    env -u DISPLAY timeout 300 "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" \
        --run "$staged" > "$OUT/$r.out" 2>&1
    rc=$?

    lines=$(wc -l < "$OUT/$r.out" | tr -d ' ')
    sha=$(sha256sum "$OUT/$r.out" | cut -d' ' -f1)
    printf '%s\t%d\t%d\t%s\n' "$r" "$rc" "$lines" "$sha" >> "$RES"

    if [[ $rc -ne 0 ]]; then
        note "$r" "FAIL: praat exited $rc -- see $OUT/$r.out"
        fail=1
    elif [[ ! -s "$OUT/$r.out" ]]; then
        note "$r" "FAIL: printed nothing"
        fail=1
    else
        note "$r" "ran (exit 0, $lines line(s))"
    fi

    # NO MACHINE PATHS IN A PINNED CAPTURE. If a recipe ever prints an
    # absolute path, the committed capture stops being reproducible on any
    # other machine and v81 becomes a check on this container. Caught here,
    # where the fix is to change the recipe, rather than six months later.
    if grep -qF "$EML_ROOT" "$OUT/$r.out" || grep -qF "$WORKROOT" "$OUT/$r.out"; then
        note "$r" "FAIL: the capture contains a machine path"
        fail=1
    fi

    # What the recipe wrote, if it wrote anything, flattened under the
    # recipe name so out/ stays one directory the way api_export's does.
    if [[ -d "$work/results" ]]; then
        while IFS= read -r f; do
            b="$(basename "$f")"
            printf '%s\t%s\t%s\n' "$r" "$b" "$(wc -c < "$f" | tr -d ' ')" >> "$FILES"
            cp "$f" "$OUT/$r.$b"
        done < <(find "$work/results" -maxdepth 1 -type f | sort)
    fi
done

rm -rf "$STAGE" "$WORKROOT"

n_files=$(( $(wc -l < "$FILES") - 1 ))
echo
echo "captures: ${#RECIPES[@]}  ->  $RES"
echo "files written by the recipes: $n_files  ->  $FILES"

# --- the verdicts this driver can make for itself ---------------------------
# THE VALIDATOR IS validate/v81_recipes.R and it makes the detailed claims --
# every printed number against base R, and every capture against the page.
# What is checked here is only what would make the artefact meaningless.
if [[ ${#RECIPES[@]} -lt 5 ]]; then
    note "----" "FAIL: only ${#RECIPES[@]} recipe(s) lifted; the page has more"
    fail=1
fi
for r in "${RECIPES[@]}"; do
    [[ -s "$OUT/scripts/$r.praat" ]] || { note "$r" "FAIL: empty script"; fail=1; }
done

if [[ $fail -eq 0 ]]; then
    echo "recipes: PASS -- ${#RECIPES[@]} recipes, $n_files exported file(s)"
    echo "  next: Rscript validate/v81_recipes.R"
    exit 0
fi
echo "recipes: FAIL"
exit 1
