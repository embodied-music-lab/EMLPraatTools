#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# runblock/break.sh -- watch v87 go red
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
#   bash harness/runblock/run.sh      # first: the healthy artefacts
#   bash harness/runblock/break.sh    # then: watch each check fail
#
# ORDER MATTERS ONE WAY ONLY. run.sh rebuilds out/ but leaves out/breaks and
# out/BREAKS.tsv alone, so a re-drive does not delete the red-watch evidence;
# this script reads out/ as it stands for the fingerprint break, so run.sh
# has to have produced it at least once.
#
# NOTHING IS VALIDATED UNTIL A CHECK HAS BEEN SEEN TO FAIL. Each break puts
# ONE part of the old naming back into a COPY of the plugin, drives the whole
# runblock harness against that copy, and runs validate/v87 against what it
# emitted. The working tree is never edited, so an interrupted break test
# cannot leave a defect behind.
#
# WHAT IS AND IS NOT REDIRECTED. EML_RUNBLOCK_SRC points the DRIVE at the
# damaged copy. The HEAD baseline inside run.sh is built by `git archive HEAD`
# and is deliberately left alone: it is the "unchanged from today" side of the
# single-run comparison, and a baseline that moved with the break would make
# that check unable to fail.
#
# Output: out/BREAKS.tsv, one row per break with the red count, and
#         out/breaks/<name>/v87.log with the failures named.
# ---------------------------------------------------------------------------
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
BOUT="$HERE/out/breaks"
BTSV="$HERE/out/BREAKS.tsv"

mkdir -p "$BOUT"
printf 'break\tchecks\tfailed\n' > "$BTSV"

run_break () {
    local name="$1"
    local tree="$BOUT/$name/plugin"
    rm -rf "$BOUT/$name"
    mkdir -p "$BOUT/$name"
    cp -r "$ROOT/plugin" "$tree"

    python3 "$HERE/mutate.py" "$name" "$tree" || return 1

    EML_RUNBLOCK_SRC="$tree" EML_RUNBLOCK_OUT="$BOUT/$name/out" \
        bash "$HERE/run.sh" > "$BOUT/$name/run.log" 2>&1

    # THE SOURCE READER IS POINTED AT THE DAMAGED COPY TOO. v87 reads two
    # boundary call sites out of the source, because the graphs form and the
    # wizard need dialogs and no headless driver reaches them; a break in one
    # of those files would otherwise be validated against the working tree's
    # healthy one and pass over itself. The staleness fingerprint is NOT
    # redirected -- it compares the transcript with the working tree, which
    # the break never touches, so it stays green throughout and a break's red
    # count is about the naming.
    local log="$BOUT/$name/v87.log"
    EML_RUNBLOCK_DIR="$BOUT/$name/out" EML_RUNBLOCK_PLUGIN="$tree" \
        Rscript "$ROOT/validate/v87_run_scoped_block.R" > "$log" 2>&1
    local line checks failed
    line="$(grep -E '^[0-9]+ checks' "$log" | tail -1)"
    checks="$(echo "$line" | awk '{print $1}')"
    failed="$(echo "$line" | awk '{print $5}')"
    printf '%s\t%s\t%s\n' "$name" "${checks:-0}" "${failed:-0}" >> "$BTSV"
    # THE DAMAGED TREE AND THE FIGURES GO; THE TRANSCRIPT AND THE BLOCKS STAY.
    # A v87 log says which check went red; the emitted blocks and the file-set
    # census say what the damage actually looked like, which is the part a
    # reader of BREAKS.tsv cannot reconstruct from the count.
    cp "$BOUT/$name/out/RUNBLOCK.tsv" "$BOUT/$name/RUNBLOCK.tsv" 2>/dev/null
    for cs in "$BOUT/$name/out"/*/emitted.praat; do
        [ -f "$cs" ] || continue
        d="$(basename "$(dirname "$cs")")"
        sed -n '/^# Name your data/,/^# (Titles/p' "$cs" \
            > "$BOUT/$name/block_$d.txt"
    done
    rm -rf "$tree" "$BOUT/$name/out"
    echo "== $name: $line"
    grep '^FAIL' "$log" | head -60
    echo
}

# ---------------------------------------------------------------------------
# THE FINGERPRINT BREAK. Nothing is mutated: the transcript's record of which
# recorder these blocks were driven against is doctored, which is what a stale
# committed artefact looks like from the validator's side -- blocks that no
# longer describe the code in the tree. Everything else in the file is
# untouched and still green, so the red is the guard and nothing else.
# ---------------------------------------------------------------------------
stale_break () {
    local name="stale_fingerprint"
    rm -rf "$BOUT/$name"; mkdir -p "$BOUT/$name"
    # THE COPY GOES OUTSIDE out/, because out/breaks IS out/ -- copying a
    # directory into its own subtree silently drops most of it, and the
    # dropped half looked exactly like two more checks going red.
    local scratch
    scratch="$(mktemp -d)"
    cp -r "$HERE/out/." "$scratch/" 2>/dev/null
    rm -rf "$scratch/breaks" "$scratch/prefs" "$scratch/head_tree"
    sed -i 's/^meta\trecord_sha\t.*/meta\trecord_sha\t0000000000000000/' \
        "$scratch/RUNBLOCK.tsv"
    local log="$BOUT/$name/v87.log"
    EML_RUNBLOCK_DIR="$scratch" \
        Rscript "$ROOT/validate/v87_run_scoped_block.R" > "$log" 2>&1
    local line checks failed
    line="$(grep -E '^[0-9]+ checks' "$log" | tail -1)"
    checks="$(echo "$line" | awk '{print $1}')"
    failed="$(echo "$line" | awk '{print $5}')"
    printf '%s\t%s\t%s\n' "$name" "${checks:-0}" "${failed:-0}" >> "$BTSV"
    rm -rf "$scratch"
    echo "== $name: $line"
    grep '^FAIL' "$log" | head -10
    echo
}

run_break value_dedup
run_break first_use_number
run_break suffix_run_one
run_break shared_axis
run_break drop_format_run
run_break data_by_source
run_break boundary_outside_loop
stale_break

echo "runblock/break: summary"
cat "$BTSV"
