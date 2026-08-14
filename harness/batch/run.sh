#!/usr/bin/env bash
# ============================================================================
# harness/batch/run.sh — the batch module driven end to end, seven times
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# WHAT IS UNCOVERED, AND IT IS NOT THE ACOUSTICS. v52 pins every acoustic CALL
# in plugin/scripts/eml-batch-process.praat — the canonical parameter sets, the
# routing of the two pitch algorithms to their two purposes, and, since the
# sandbox reached 6.6.30, the live argument order of all nine. None of that
# says anything about the FLOW around them: the file loop, the failure paths,
# the TextGrid branch, the STOP sentinel, the output folder, the warnings. A
# module can call every command correctly and still pair row 3 with file 4,
# measure the whole file in the branch that was meant to measure one interval,
# or lose an entire overnight batch to one zero-length take. Those are the
# failures this harness exists to make visible, and every one of them is
# invisible to a check that reads the source.
#
# WHY A DERIVED TWIN, AND WHY THAT IS STILL EVIDENCE ABOUT THE SHIPPED FILE.
# Every EML entry point collects its settings with beginPause:/endPause, which
# hard-crashes under `praat --run` — Trace/breakpoint trap, exit 133, no
# display (harness/GUI_HARNESS_RECIPE.md §0). The plugin has no test hook. So
# the two dialog stanzas are CUT OUT MECHANICALLY, by line number, from
# anchors that must be unique or this script refuses to run, and replaced by
# two `include` lines that set exactly the variables the dialogs set. Nothing
# else is touched, and that is not asserted by inspection: the shipped file
# minus those two regions and the twin minus those two include lines are
# hashed, and the hashes must be equal. The excised text is written to
# out/EXCISED.txt so a reader can see what was removed rather than trust that
# it was harmless. Everything below the dialogs — the loop, the branches, the
# sentinel, the table, the CSV — is the shipped bytes, running.
#
# THE SEVEN DRIVES
#
#   A_loop    five files whose alphabetical order is not their creation order,
#             five different F0s. Row order, stem-to-value pairing, and the
#             ruling that the CSV lands in the output folder and never in the
#             corpus.
#   B_errors  two good files around four that cannot be analysed — zero
#             length, corrupt bytes, a TextGrid under a .wav name, and 0.02 s
#             of audio. Every one of the four ABORTED the whole run before
#             14 August 2026.
#   C_free    the same three files with the TextGrid branch OFF, so that
#   C_grid    the same three with it ON have something to differ from.
#   D_stop    twelve files, a foreign STOP.txt already in the output folder,
#             and the sentinel flipped while the run is going.
#   E_folder  one file into an output folder two levels below one that does
#             not exist, with spaces in both names.
#   F_warn    one file per measure, each engineered to land outside its
#             APPENDIX_D §7 band, all six measures on at once.
#
# EVIDENCE, all under out/: BATCH.tsv (the scalar facts), one <case>.csv per
# drive (the shipped module's own output), one <case>.log per drive (the Info
# window, with the scratch path replaced by <WORK> so the artefact is stable
# across machines), and EXCISED.txt. validate/v53_batch_flow.R reads all of it.
#
#   bash harness/batch/run.sh
#   Rscript validate/v53_batch_flow.R
#
# $EML_BATCH_FILE overrides the module under test and $EML_BATCH_DIR the
# evidence folder, so a break test can drive a deliberately damaged copy
# without going near the shipped file. Both are the names v52 already uses.
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

SRC="${EML_BATCH_FILE:-$EML_ROOT/plugin/scripts/eml-batch-process.praat}"
OUT="${EML_BATCH_DIR:-$SCRIPT_DIR/out}"
PREFS="$SCRIPT_DIR/prefs"
WORK="$OUT/work"

if [[ ! -f "$SRC" ]]; then
    echo "batch: FAIL — no module at $SRC" >&2
    exit 1
fi

# THE WORK TREE IS REBUILT FROM NOTHING EVERY RUN. A corpus left over from a
# previous run changes what "five files" means, and a results CSV left in an
# output folder changes which name the collision walk picks — both would move
# an answer without changing a line of code. harness/formhelpers/run.sh clears
# its scratch for the same reason.
rm -rf "$WORK"
mkdir -p "$OUT" "$PREFS" "$WORK"
rm -f "$OUT"/*.csv "$OUT"/*.log "$OUT/BATCH.tsv" "$OUT/EXCISED.txt"

TSV="$OUT/BATCH.tsv"
: > "$TSV"
say () { printf '%s\t%s\n' "$1" "$2" >> "$TSV"; }

say praat_version "$("$PRAAT" --version 2>&1 | head -1)"
say module_under_test "$(basename "$SRC")"

# ---------------------------------------------------------------------------
# 1. DERIVE THE HEADLESS TWIN
# ---------------------------------------------------------------------------
# ANCHORED ON EXACT WHOLE LINES, AND UNIQUE OR NOTHING. A fuzzy anchor that
# matched the wrong line would silently cut a piece of the flow out of the
# thing under test and every check below would then be passing over a module
# no user runs. So each anchor is counted, and a count other than one is fatal.
anchor_once () {   # anchor_once <regex> -> line number, or die
    local n
    n=$(grep -c -E "$1" "$SRC")
    if [[ "$n" -ne 1 ]]; then
        echo "batch: FAIL — dialog anchor /$1/ matched $n lines, expected 1." >&2
        echo "       The twin cannot be derived safely. Fix the anchor, do" >&2
        echo "       not loosen it." >&2
        exit 1
    fi
    grep -n -E "$1" "$SRC" | cut -d: -f1
}

d1_pause=$(anchor_once '^ {4}beginPause: "Batch Voice Analysis"$')
d1_end=$(anchor_once '^until clicked <> 2$')
d2_start=$(anchor_once '^beginPause: "Batch range"$')
d2_click=$(anchor_once '^clicked = endPause: "Quit", "Run", 2, 0$')

# The settings dialog sits inside a repeat/until, because of the Standard
# button. The repeat is the last one before the beginPause.
d1_start=$(awk -v p="$d1_pause" 'NR<p && /^repeat$/{n=NR} END{print n}' "$SRC")
# The range dialog's Quit branch ends at the first endif after the endPause.
d2_end=$(awk -v c="$d2_click" 'NR>c && /^endif$/{print NR; exit}' "$SRC")

for v in d1_start d1_end d2_start d2_end; do
    if [[ -z "${!v}" || "${!v}" -eq 0 ]]; then
        echo "batch: FAIL — could not locate $v in $SRC" >&2
        exit 1
    fi
done
if ! (( d1_start < d1_end && d1_end < d2_start && d2_start < d2_end )); then
    echo "batch: FAIL — dialog regions out of order: $d1_start-$d1_end, $d2_start-$d2_end" >&2
    exit 1
fi

TWIN="$WORK/twin.praat"
{
    sed -n "1,$((d1_start - 1))p" "$SRC"
    echo 'include _params.praat'
    sed -n "$((d1_end + 1)),$((d2_start - 1))p" "$SRC"
    echo 'include _range.praat'
    sed -n "$((d2_end + 1)),\$p" "$SRC"
} > "$TWIN"

{
    echo "# Cut from $(basename "$SRC") to make the headless twin."
    echo "# Region 1: lines $d1_start-$d1_end (settings dialog)"
    sed -n "${d1_start},${d1_end}p" "$SRC"
    echo "# Region 2: lines $d2_start-$d2_end (batch range dialog)"
    sed -n "${d2_start},${d2_end}p" "$SRC"
} > "$OUT/EXCISED.txt"

sed -e "${d2_start},${d2_end}d" -e "${d1_start},${d1_end}d" "$SRC" > "$WORK/body_shipped.txt"
grep -v -x -e 'include _params.praat' -e 'include _range.praat' \
    "$TWIN" > "$WORK/body_twin.txt"
sha_shipped=$(sha256sum < "$WORK/body_shipped.txt" | cut -d' ' -f1)
sha_twin=$(sha256sum < "$WORK/body_twin.txt" | cut -d' ' -f1)

say twin_excised_lines "$(( (d1_end - d1_start + 1) + (d2_end - d2_start + 1) ))"
say twin_injected_lines 2
say twin_body_sha_shipped "$sha_shipped"
say twin_body_sha_twin "$sha_twin"
if [[ "$sha_shipped" == "$sha_twin" ]]; then
    say twin_body_identical 1
else
    say twin_body_identical 0
fi
say shipped_total_lines "$(wc -l < "$SRC")"

# ---------------------------------------------------------------------------
# 2. THE CORPORA
# ---------------------------------------------------------------------------
env -u DISPLAY EML_BATCH_WORK="$WORK" timeout 300 "$PRAAT" $PRAAT_TRUST \
    --pref-dir="$PREFS" --run "$SCRIPT_DIR/fixtures.praat" \
    > "$WORK/fixtures.log" 2>&1
if ! grep -q "FIXTURES OK" "$WORK/fixtures.log"; then
    echo "batch: FAIL — fixtures did not build. See $WORK/fixtures.log" >&2
    cat "$WORK/fixtures.log" >&2
    exit 1
fi

# The two failures Praat cannot author. A file of no bytes at all is what a
# stopped interface leaves behind; a file of text under a .wav name is what a
# mis-extended export leaves behind.
: > "$WORK/B_in/b02_zero.wav"
printf 'this is not audio, it is a note to self\n' > "$WORK/B_in/b06_corrupt.wav"
say fixtures_ok 1

# ---------------------------------------------------------------------------
# 3. ONE DRIVE
# ---------------------------------------------------------------------------
# Each case gets its own folder holding a copy of the twin and its two include
# files, because `include` resolves against the folder of the script that was
# RUN — the trap harness/acoustic/drive.praat fell into. Its own folder also
# means the seven cases cannot see each other's output.
CASE_EXIT=0
run_case () {                      # run_case <name>   (params already written)
    local name="$1"
    local dir="$WORK/$name"
    cp "$TWIN" "$dir/twin.praat"
    ( env -u DISPLAY timeout 600 "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" \
        --run "$dir/twin.praat" > "$dir/run.log" 2>&1 )
    CASE_EXIT=$?
    say "${name}_exit" "$CASE_EXIT"
}

# A case's Info window becomes committed evidence, so the scratch path — which
# is different on every machine and in every override — is replaced by a token.
harvest () {                       # harvest <name> <output folder>
    local name="$1" outdir="$2"
    sed "s|$WORK|<WORK>|g" "$WORK/$name/run.log" > "$OUT/$name.log"
    local csv
    csv=$(find "$outdir" -maxdepth 1 -name '*.csv' | sort | head -1)
    if [[ -n "$csv" ]]; then
        cp "$csv" "$OUT/$name.csv"
        say "${name}_csv_name" "$(basename "$csv")"
        say "${name}_csv_rows" "$(( $(wc -l < "$csv") - 1 ))"
    else
        say "${name}_csv_name" ""
        say "${name}_csv_rows" -1
    fi
    say "${name}_completed" "$(grep -c '^COMPLETE$' "$WORK/$name/run.log")"
}

# The settings block every case shares. Written as a here-doc rather than a
# generated string so that a reader can see the variable names are the ones
# Praat derives from the dialog labels — output_folder$ from "Output folder",
# hNR from "HNR", clear_Info_window from "Clear Info window". Rule 20, and the
# rule that cost eml-output.praat a silent no-op save on 13 August 2026.
write_params () {   # write_params <dir> <in> <out> <F0> <int> <jit> <shim> <hnr> <cpps> <hef> <useTG> <tgdir> <tier> <label>
    mkdir -p "$1"
    cat > "$1/_params.praat" <<EOF
# Written by harness/batch/run.sh. These are the values the settings dialog
# would have returned; nothing else about the module is changed.
sound_folder\$ = "$2"
file_extension\$ = "wav"
channel_handling = 1
channel_handling\$ = "Mix to mono"
output_folder\$ = "$3"
mean_F0 = $4
mean_intensity = $5
jitter = $6
shimmer = $7
hNR = $8
cPPS = $9
highest_expected_F0 = ${10}
use_TextGrids = ${11}
textGrid_folder\$ = "${12}"
tier_number = ${13}
target_label\$ = "${14}"
clear_Info_window = 0
EOF
    # The range dialog's own defaults: the whole list, every time. nFiles is in
    # scope at the point this is included, exactly as it is for the `natural:`
    # field whose default is string$ (nFiles).
    cat > "$1/_range.praat" <<'EOF'
start_from_file = 1
end_at_file = nFiles
EOF
}

STAMP="$(date +%F)"
say date_stamp "$STAMP"

# ---------------------------------------------------------------------------
# A_loop — N in, N out, in order, each row's value matching its own stem
# ---------------------------------------------------------------------------
write_params "$WORK/A_loop" "$WORK/A_in" "$WORK/A_out" 1 1 1 1 1 1 500 0 "" 1 "V"
run_case A_loop
harvest A_loop "$WORK/A_out"
# THE RULING OF 14 AUGUST 2026, MEASURED RATHER THAN READ. Nothing this script
# writes may land in the corpus. Counted, not eyeballed: any csv, any STOP file.
say A_loop_input_folder_csv "$(find "$WORK/A_in" -maxdepth 1 -name '*.csv' | wc -l)"
say A_loop_input_folder_stop "$(find "$WORK/A_in" -maxdepth 1 -name 'STOP*' | wc -l)"
say A_loop_output_folder_csv "$(find "$WORK/A_out" -maxdepth 1 -name '*.csv' | wc -l)"
say A_loop_sentinel_exists "$([[ -f "$WORK/A_out/STOP.txt" ]] && echo 1 || echo 0)"
say A_loop_sentinel_first_line "$(head -1 "$WORK/A_out/STOP.txt" 2>/dev/null)"
say A_loop_expected_csv_name "A_in_results_${STAMP}.csv"

# ---------------------------------------------------------------------------
# B_errors — four ways to fail, two good files that must survive them
# ---------------------------------------------------------------------------
write_params "$WORK/B_errors" "$WORK/B_in" "$WORK/B_out" 1 1 1 1 1 1 500 0 "" 1 "V"
run_case B_errors
harvest B_errors "$WORK/B_out"
say B_errors_input_files "$(find "$WORK/B_in" -maxdepth 1 -name '*.wav' | wc -l)"

# ---------------------------------------------------------------------------
# C_free / C_grid — the same corpus with the TextGrid branch off and on
# ---------------------------------------------------------------------------
write_params "$WORK/C_free" "$WORK/C_in" "$WORK/C_free_out" 1 1 0 0 0 0 500 0 "" 1 "V"
run_case C_free
harvest C_free "$WORK/C_free_out"

write_params "$WORK/C_grid" "$WORK/C_in" "$WORK/C_grid_out" 1 1 0 0 0 0 500 \
    1 "$WORK/C_tg" 1 "V"
run_case C_grid
harvest C_grid "$WORK/C_grid_out"

# ---------------------------------------------------------------------------
# D_stop — a foreign STOP.txt, and the real sentinel flipped mid-run
# ---------------------------------------------------------------------------
# THE FOREIGN FILE IS THE ONE THE PROCEDURE'S OWN HEADER DESCRIBES: a file a
# human wrote, whose first line BEGINS with the word stop. The first draft of
# @emlSentinelIsOurs tested the first WORD and destroyed exactly this file.
mkdir -p "$WORK/D_out"
cat > "$WORK/D_out/STOP.txt" <<'EOF'
Stop list for this study
the, a, an, of
EOF
foreign_before=$(sha256sum < "$WORK/D_out/STOP.txt" | cut -d' ' -f1)
say D_stop_foreign_sha_before "$foreign_before"

write_params "$WORK/D_stop" "$WORK/D_in" "$WORK/D_out" 1 1 1 1 1 1 500 0 "" 1 "V"
cp "$TWIN" "$WORK/D_stop/twin.praat"

# THE STOP IS WRITTEN BY A SECOND PROCESS WHILE THE FIRST IS STILL WORKING,
# which is the only way this can be tested at all: the sentinel is read at the
# top of each iteration, so a file that already said STOP before the run began
# would be overwritten with RUN by @emlInitSentinel and prove nothing.
#
# THE POLLER WATCHES THE INFO WINDOW, WITH A DEADLINE. Praat's stdout is block
# buffered into a file, so the progress lines may not appear until the process
# exits; the deadline is what makes the case work anyway. Twelve files with all
# six measures is far more work than the delay, so the run is still going
# either way — and the assertion in v53 is "it stopped before the end", not
# "it stopped at file 4", because a timing-derived row count is not a fact
# about the module.
( env -u DISPLAY timeout 600 "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" \
    --run "$WORK/D_stop/twin.praat" > "$WORK/D_stop/run.log" 2>&1 ) &
praat_pid=$!
armed=""
for _ in $(seq 1 24); do           # 24 x 0.25 s = 6 s, several files' worth
    sleep 0.25
    if grep -q '^\[3/12\]' "$WORK/D_stop/run.log" 2>/dev/null; then
        armed=poll
        break
    fi
done
if [[ -z "$armed" ]]; then armed=deadline; fi
if [[ -f "$WORK/D_out/STOP_2.txt" ]]; then
    printf 'STOP\n' > "$WORK/D_out/STOP_2.txt"
    say D_stop_flipped "$armed"
else
    say D_stop_flipped "no-sentinel"
fi
wait "$praat_pid"
CASE_EXIT=$?
say D_stop_exit "$CASE_EXIT"
harvest D_stop "$WORK/D_out"
say D_stop_input_files "$(find "$WORK/D_in" -maxdepth 1 -name '*.wav' | wc -l)"
say D_stop_foreign_sha_after "$(sha256sum < "$WORK/D_out/STOP.txt" | cut -d' ' -f1)"
say D_stop_sentinel_2_exists "$([[ -f "$WORK/D_out/STOP_2.txt" ]] && echo 1 || echo 0)"
say D_stop_sentinel_2_first_line "$(head -1 "$WORK/D_out/STOP_2.txt" 2>/dev/null)"
say D_stop_stopped_line "$(grep -c 'STOPPED BY USER' "$WORK/D_stop/run.log")"

# ---------------------------------------------------------------------------
# E_folder — an output folder two levels below one that does not exist
# ---------------------------------------------------------------------------
# Spaces in both names, because "~/Documents/Study A/run 1" is what a user
# types into that field, and createFolder: is mkdir, not mkdir -p.
E_OUT="$WORK/E out/Study A/run 1"
write_params "$WORK/E_folder" "$WORK/E_in" "$E_OUT" 1 1 0 0 0 0 500 0 "" 1 "V"
run_case E_folder
harvest E_folder "$E_OUT"
say E_folder_created "$([[ -d "$E_OUT" ]] && echo 1 || echo 0)"
say E_folder_sentinel_exists "$([[ -f "$E_OUT/STOP.txt" ]] && echo 1 || echo 0)"
say E_folder_input_folder_writes \
    "$(find "$WORK/E_in" -maxdepth 1 -type f ! -name '*.wav' | wc -l)"

# ---------------------------------------------------------------------------
# F_warn — one out-of-band measure per file, six measures on, run must finish
# ---------------------------------------------------------------------------
write_params "$WORK/F_warn" "$WORK/F_in" "$WORK/F_out" 1 1 1 1 1 1 900 0 "" 1 "V"
run_case F_warn
harvest F_warn "$WORK/F_out"
say F_warn_exitscript "$(grep -c 'exitScript' "$WORK/F_warn/run.log")"
say F_warn_warning_lines "$(grep -c 'WARNING:' "$WORK/F_warn/run.log")"

# ---------------------------------------------------------------------------
# 4. REPORT
# ---------------------------------------------------------------------------
say completed 1

printf '%-10s %-6s %-6s %s\n' case exit rows csv
for c in A_loop B_errors C_free C_grid D_stop E_folder F_warn; do
    printf '%-10s %-6s %-6s %s\n' "$c" \
        "$(awk -F'\t' -v k="${c}_exit" '$1==k{print $2}' "$TSV")" \
        "$(awk -F'\t' -v k="${c}_csv_rows" '$1==k{print $2}' "$TSV")" \
        "$(awk -F'\t' -v k="${c}_csv_name" '$1==k{print $2}' "$TSV")"
done
echo
echo "twin body identical to shipped body: $(awk -F'\t' '$1=="twin_body_identical"{print $2}' "$TSV")"
echo "evidence: $OUT/BATCH.tsv and $(ls "$OUT"/*.csv 2>/dev/null | wc -l) csv, $(ls "$OUT"/*.log 2>/dev/null | wc -l) log"
echo
echo "Now run: Rscript validate/v53_batch_flow.R"
