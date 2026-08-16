#!/usr/bin/env bash
# ============================================================================
# harness/batchgui/run.sh — the batch module's REAL dialog, pressed
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# WHY THIS EXISTS, AND WHY THE 255 CHECKS ALREADY ON THIS MODULE DO NOT COVER
# IT. v52 pins every acoustic call argument by argument and proves the live
# argument order at 6.6.30. v53 drives seven corpora through the loop, the
# failure paths, the TextGrid branch, the sentinel, the output folder and the
# warnings. v54 checks every command signature against the PraatGen corpus.
# Not one of them has pressed a button. harness/batch reaches the loop by
# CUTTING THE TWO DIALOG STANZAS OUT — mechanically, by line number, with the
# remainder hash-verified against the shipped file — precisely because
# beginPause:/endPause: hard-crashes under `praat --run` (Trace/breakpoint
# trap, exit 133; GUI_HARNESS_RECIPE §0). So the strongest evidence in the tree
# about this module is evidence gathered with its form removed.
#
# THAT IS THE SHAPE OF EVERY DEFECT THIS PROJECT HAS FOUND TWICE. The graphs
# form's Exp CSV button wrote the wrong format because no harness pressed it.
# Nine of @emlSavePanel's ten callers died on the first press of Save with
# "Unknown variable: emlLastCSVFolder$" while v46 passed, because v46 read call
# sites and harness/wrappers asked only whether the script parsed. A form is
# not covered by evidence collected without it.
#
# AND THE ENTRY IS NEW. Batch voice analysis was unregistered on 6 August 2026
# for want of coverage and registered again on 16 August by author ruling. A
# menu entry that has never been clicked is the audit's severity-2 "dead door"
# exactly: the promise is made in setup.praat and nothing has ever checked that
# the door opens. This harness clicks it.
#
# WHAT IT DRIVES, in one Praat session per leg, under Xvfb with a real window
# manager, through the real menu:
#
#   menu_before   plugin/setup.praat with the two batch registration lines cut
#                 out, and the SAME keystrokes. The submenu's thirteenth item
#                 is then a different command, so this leg must reach a
#                 different dialog. It is what makes the leg below falsifiable:
#                 without it, "we reached Batch Voice Analysis" is a claim that
#                 could hold with the entry anywhere in the menu, or with the
#                 keystroke count silently wrong.
#   menu_after    the shipped setup.praat, same keystrokes, must reach
#                 "Batch Voice Analysis".
#   drive         the same again, and then the form is FILLED — a folder typed
#                 into the Sound folder field, all six measure boxes ticked,
#                 highest expected F0 set to 300 — Run pressed, the Batch range
#                 dialog's Run pressed, and the run carried to its CSV.
#
# THE POSITION PIN IS THE KEYSTROKE COUNT. The submenu is entered and Down is
# pressed a fixed number of times. GTK skips separators in keyboard navigation,
# so that count is the item's ORDINAL among the commands — 13 of 18. If the
# entry moves, the keystrokes land on its neighbour and the leg reaches a
# dialog with the wrong title, which fails. Nothing here reads menu text: GTK
# menu items carry no X window of their own and no property to query, so the
# only honest machine-readable fact about a menu item's position is which
# command a fixed walk arrives at. The photographs are for a human.
#
# THE INFO WINDOW COMES BACK AS TEXT, via `praat --send grab.praat` into the
# live session (see grab.praat). A screenshot of the warnings would be evidence
# no validator could read, and the two APPENDIX_D §7 guards this leg exists to
# exercise produce nothing else — no column, no cell, no file.
#
# EVIDENCE, all under out/: BATCHGUI.tsv (the scalar facts), INFO.txt (the Info
# window as UTF-8), RESULTS.csv (the module's own output, copied), and five
# PNGs — the submenu with and without the entry, the dialog as it opens, the
# dialog as filled, and the Info window at the end.
#
#   bash harness/batchgui/run.sh
#   Rscript validate/v72_batch_registration.R
#
# $EML_SETUP_FILE overrides the registration under test, $EML_BATCH_FILE the
# module, and $EML_BATCHGUI_DIR the evidence folder — so a break test drives a
# deliberately damaged copy without going near the shipped files. The first two
# are the names v52 and v59 already use.
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
PRAAT="${PRAAT:-/usr/bin/praat}"

SETUP="${EML_SETUP_FILE:-$REPO/plugin/setup.praat}"
MODULE="${EML_BATCH_FILE:-$REPO/plugin/scripts/eml-batch-process.praat}"
OUT="${EML_BATCHGUI_DIR:-$SCRIPT_DIR/out}"
WORK="$OUT/work"

# THE DISPLAY IS THIS HARNESS'S OWN. Six other harnesses in this tree take
# :88, :99 and friends; two runs sharing a display steal each other's windows
# and the failure reads as a missing dialog rather than as a collision.
DISP="${EML_BATCHGUI_DISPLAY:-:146}"

for t in Xvfb xdotool xprop xwininfo import matchbox-window-manager iconv; do
    command -v "$t" >/dev/null || { echo "batchgui: FAIL — no $t" >&2; exit 1; }
done
[[ -x "$PRAAT" ]] || { echo "batchgui: FAIL — no praat at $PRAAT" >&2; exit 1; }
[[ -f "$SETUP"  ]] || { echo "batchgui: FAIL — no setup at $SETUP" >&2; exit 1; }
[[ -f "$MODULE" ]] || { echo "batchgui: FAIL — no module at $MODULE" >&2; exit 1; }

# THE FLOOR IS ASSERTED, NOT ASSUMED. A green drive on a build below the
# plugin's own floor is not evidence about the plugin (the v52 rule), and two
# of the pitch commands this module calls do not exist below 6.6.30 at all.
PV="$("$PRAAT" --version 2>&1 | head -1)"
PVN="$(printf '%s' "$PV" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
PVI=$(awk -F. '{printf "%d", $1*1000 + $2*100 + $3}' <<< "${PVN:-0.0.0}")
if [[ "$PVI" -lt 6630 ]]; then
    echo "batchgui: FAIL — $PV is below the plugin's 6.6.30 floor." >&2
    exit 1
fi

rm -rf "$WORK"
mkdir -p "$OUT" "$WORK"
rm -f "$OUT"/*.png "$OUT"/*.tsv "$OUT"/*.txt "$OUT"/*.csv

TSV="$OUT/BATCHGUI.tsv"
: > "$TSV"
say () { printf '%s\t%s\n' "$1" "$2" >> "$TSV"; }

say praat_version "$PV"
say setup_under_test "$(basename "$SETUP")"
say module_under_test "$(basename "$MODULE")"

# ---------------------------------------------------------------------------
# 1. THE TWO PLUGIN TREES
# ---------------------------------------------------------------------------
# A plugin is a folder named plugin_<Name> in the preferences directory
# (BEST_PRACTICES_PLUGIN_ARCHITECTURE §1), so each leg gets a pref dir of its
# own with the plugin copied into it. Copied, not symlinked: the "before" tree
# has a DIFFERENT setup.praat, and a symlink would edit the repository.
#
# THE "BEFORE" TREE IS DERIVED MECHANICALLY AND THE COUNT IS FATAL. Cutting
# the wrong line would give a leg that reaches a different dialog for a reason
# that has nothing to do with the registration, and the whole point of the
# before/after pair is that exactly one thing differs between them.
stage () {   # stage <dir> <setup-file>
    local dir="$1" setupsrc="$2"
    rm -rf "$dir"; mkdir -p "$dir"
    cp -r "$REPO/plugin" "$dir/plugin_EML_Praat_Tools"
    cp "$setupsrc" "$dir/plugin_EML_Praat_Tools/setup.praat"
    cp "$MODULE" "$dir/plugin_EML_Praat_Tools/scripts/eml-batch-process.praat"
}

BATCH_RE='^Add menu command: "Objects", "New", ("-- eml batch --"|"Batch voice analysis\.\.\.")'
nbatch=$(grep -c -E "$BATCH_RE" "$SETUP")
say setup_batch_lines "$nbatch"
if [[ "$nbatch" -ne 2 ]]; then
    echo "batchgui: FAIL — $SETUP has $nbatch live batch registration lines," >&2
    echo "          expected 2 (the separator and the command). The before/" >&2
    echo "          after pair cannot be derived from it." >&2
    exit 1
fi
grep -v -E "$BATCH_RE" "$SETUP" > "$WORK/setup_before.praat"
say setup_before_removed \
    "$(( $(wc -l < "$SETUP") - $(wc -l < "$WORK/setup_before.praat") ))"

stage "$WORK/prefs_after"  "$SETUP"
stage "$WORK/prefs_before" "$WORK/setup_before.praat"

# ---------------------------------------------------------------------------
# 2. THE CORPUS
# ---------------------------------------------------------------------------
CORPUS="$WORK/corpus"
mkdir -p "$CORPUS"
EML_BATCHGUI_CORPUS="$CORPUS" "$PRAAT" --run "$SCRIPT_DIR/fixtures.praat" \
    > "$WORK/fixtures.log" 2>&1
nwav=$(find "$CORPUS" -name '*.wav' | wc -l)
say fixtures_wav "$nwav"
if [[ "$nwav" -ne 3 ]]; then
    echo "batchgui: FAIL — fixtures produced $nwav wav files, expected 3" >&2
    cat "$WORK/fixtures.log" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# 3. THE DISPLAY
# ---------------------------------------------------------------------------
Xvfb "$DISP" -screen 0 1400x1100x24 > "$WORK/xvfb.log" 2>&1 &
XVFB_PID=$!
sleep 3
DISPLAY="$DISP" matchbox-window-manager -use_titlebar no > "$WORK/wm.log" 2>&1 &
WM_PID=$!
sleep 2

cleanup () {
    # -x, NEVER -f. `pkill -f praat` matches this script's own command line
    # through the driving shell and kills the run itself (exit 144). Measured
    # the hard way on 11 August 2026 and written into GUI_HARNESS_RECIPE.
    pkill -9 -x praat 2>/dev/null
    kill "$WM_PID" "$XVFB_PID" 2>/dev/null
}
trap cleanup EXIT

# ---------------------------------------------------------------------------
# 4. WINDOW LOOKUP
# ---------------------------------------------------------------------------
# _NET_CLIENT_LIST via xprop, not `xdotool search`: search reads WM_NAME, which
# GTK leaves unset for titles carrying an em dash, and it returns the unmapped
# husk of every dismissed dialog forever. GUI_HARNESS_RECIPE §11.
winlist () {
    local ids id name
    ids=$(DISPLAY="$DISP" xprop -root _NET_CLIENT_LIST 2>/dev/null \
          | sed -n 's/.*# //p' | tr -d ' ' | tr ',' '\n')
    for id in $ids; do
        [[ "$id" == 0x* ]] || continue
        name=$(DISPLAY="$DISP" xdotool getwindowname "$id" 2>/dev/null)
        printf '%s\t%s\n' "$id" "$name"
    done
}
winid_by_name () { winlist | awk -F'\t' -v n="$1" '$2==n {print $1; exit}'; }
pausewin () {   # -> id<TAB>title of the first Pause: window, if any
    winlist | awk -F'\t' '$2 ~ /^Pause: / {print $1 "\t" substr($2, 8); exit}'
}
pausewait () {  # pausewait <seconds>
    local waited=0 hit
    while [[ $waited -lt $1 ]]; do
        hit=$(pausewin); [[ -n "$hit" ]] && { printf '%s\n' "$hit"; return 0; }
        sleep 2; waited=$((waited + 2))
    done
    return 1
}

# THE CLIENT ORIGIN IS xwininfo's "Absolute upper-left", NOT xdotool's
# getwindowgeometry Position. Measured on 16 August 2026 and it cost an hour:
# under matchbox the two disagree by exactly the frame inset (4, 20), because
# xdotool reports the frame's position translated by the client's offset within
# it while xwininfo reports where the client actually is. Clicking with
# xdotool's numbers put every press 4 px right and 20 px low — which on a form
# of 32 px rows lands in the gap between two checkboxes, so nothing happened,
# no error was raised, and the dialog simply sat there looking untouched. That
# reads as "the harness cannot drive this form" rather than as an offset.
origin () {   # origin <window-id> -> "X Y"
    DISPLAY="$DISP" xwininfo -id "$1" \
        | awk '/Absolute upper-left X/{x=$NF} /Absolute upper-left Y/{y=$NF}
               END{print x, y}'
}
clickin () {  # clickin <window-id> <in-window-x> <in-window-y>
    local o; o=$(origin "$1")
    DISPLAY="$DISP" xdotool mousemove $(( ${o% *} + $2 )) $(( ${o#* } + $3 )) \
        click --clearmodifiers 1 2>/dev/null
    sleep 1
}

# ---------------------------------------------------------------------------
# 5. THE MENU WALK
# ---------------------------------------------------------------------------
# CLICK "New", THEN Up, THEN Right, THEN Down x N, THEN Return.
#
# Up FIRST, and it is not decoration. It wraps to the LAST item of the New
# menu, which is where Praat puts a plugin's cascade header, so this walk does
# not depend on how many commands Praat's own New menu carries — a number that
# moves between Praat versions and is nothing to do with this plugin. Right
# opens the cascade and selects its first item.
#
# N IS THE ORDINAL MINUS ONE, because Right has already selected item 1. GTK
# skips separators during keyboard navigation, so N counts COMMANDS and the
# nine "-- eml … --" rules are invisible to it — which is the same reason the
# rules' text is invisible to the user.
MENU_ORDINAL="${EML_BATCHGUI_ORDINAL:-13}"
say menu_ordinal "$MENU_ORDINAL"

walk_to_entry () {   # walk_to_entry -> presses the menu path, leaves a dialog
    local objw; objw=$(winid_by_name "Praat Objects")
    [[ -n "$objw" ]] || return 1
    DISPLAY="$DISP" xdotool windowactivate --sync "$objw" 2>/dev/null
    sleep 1
    clickin "$objw" 72 14          # the "New" menubar label
    sleep 2
    DISPLAY="$DISP" xdotool key --clearmodifiers Up;    sleep 1
    DISPLAY="$DISP" xdotool key --clearmodifiers Right; sleep 2
    if [[ "$MENU_ORDINAL" -gt 1 ]]; then
        DISPLAY="$DISP" xdotool key --clearmodifiers \
            --repeat $((MENU_ORDINAL - 1)) --delay 120 Down
    fi
    sleep 1
    DISPLAY="$DISP" import -window root "$SHOT" 2>/dev/null
    DISPLAY="$DISP" xdotool key --clearmodifiers Return
    sleep 4
}

start_praat () {   # start_praat <prefdir> <home>
    rm -f "$1/pid" "$1/message" 2>/dev/null
    rm -f "$2/.config/praat/pid.txt" "$2/.config/praat/Message.txt" 2>/dev/null
    ( DISPLAY="$DISP" HOME="$2" "$PRAAT" --pref-dir="$1" --utf8 \
        > "$WORK/praat_$(basename "$1").log" 2>&1 ) &
    sleep 12
}
stop_praat () { pkill -9 -x praat 2>/dev/null; sleep 3; }

# ---------------------------------------------------------------------------
# LEG A — menu_before: the same walk with the registration removed
# ---------------------------------------------------------------------------
# THE FALSIFIER. Everything below reports which dialog a fixed walk reached,
# and a walk that reached the right dialog by accident would report the same.
# With the two registration lines cut, item 13 of the submenu is a different
# command, so this leg MUST reach a different title — and if it reaches "Batch
# Voice Analysis" anyway, the after leg proves nothing and the run says so.
HOME_BEFORE="$WORK/home_before"; mkdir -p "$HOME_BEFORE"
SHOT="$OUT/menu_before.png"
start_praat "$WORK/prefs_before" "$HOME_BEFORE"
walk_to_entry
# 30 SECONDS, AND A SECOND WALK IF THAT FAILS. The command at ordinal 13 with
# the batch entry gone is Check & repair data, whose wrapper reads and probes
# before it raises anything; on the first version of this leg a 10 s wait lost
# that race about one run in three and recorded an EMPTY title. An empty title
# is the most dangerous value this variable can take — it is not "the walk
# reached the wrong dialog", it is "no evidence", and read carelessly it looks
# like the falsifier passing. So it is retried once and then made fatal below.
hit=$(pausewait 30) || hit=$'\t'
if [[ -z "${hit#*$'\t'}" ]]; then
    stop_praat
    start_praat "$WORK/prefs_before" "$HOME_BEFORE"
    walk_to_entry
    hit=$(pausewait 30) || hit=$'\t'
fi
BEFORE_TITLE="${hit#*$'\t'}"
say menu_before_title "$BEFORE_TITLE"
stop_praat

if [[ -z "$BEFORE_TITLE" ]]; then
    say completed 0
    echo "batchgui: FAIL — the before-leg walk reached no dialog at all, so" >&2
    echo "          nothing here can distinguish a correct walk from a lucky" >&2
    echo "          one. See out/menu_before.png." >&2
    exit 1
fi
if [[ "$BEFORE_TITLE" == "Batch Voice Analysis" ]]; then
    say completed 0
    echo "batchgui: FAIL — the walk reached the batch dialog with the two" >&2
    echo "          registration lines REMOVED. Either the cut missed, or the" >&2
    echo "          entry is registered somewhere else as well. Every claim" >&2
    echo "          this harness makes about position is void until that is" >&2
    echo "          explained." >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# LEG B — menu_after: the shipped registration, and then the whole run
# ---------------------------------------------------------------------------
HOME_AFTER="$WORK/home_after"; mkdir -p "$HOME_AFTER"
SHOT="$OUT/menu_after.png"
start_praat "$WORK/prefs_after" "$HOME_AFTER"
walk_to_entry

hit=$(pausewait 20) || hit=$'\t'
DIALOG_ID="${hit%%$'\t'*}"
DIALOG_TITLE="${hit#*$'\t'}"
say menu_after_title "$DIALOG_TITLE"

if [[ "$DIALOG_TITLE" != "Batch Voice Analysis" ]]; then
    say drive_reached_dialog 0
    say completed 0
    echo "batchgui: FAIL — the walk reached \"$DIALOG_TITLE\", not the batch dialog." >&2
    echo "          out/menu_after.png shows the submenu as it was." >&2
    stop_praat
    exit 1
fi
say drive_reached_dialog 1

# ── the form as it opens, before anything is typed ───────────────────────
# WHAT IT PROPOSES IS THE CONTRACT. The output folder's pre-filled default is
# an author ruling of 14 August 2026 — home, in a named folder, never the
# corpus — and it is not recoverable afterwards from any file the run writes.
DISPLAY="$DISP" import -window "$DIALOG_ID" "$OUT/dialog_blank.png" 2>/dev/null

# ── fill it ──────────────────────────────────────────────────────────────
# THE IN-WINDOW OFFSETS ARE A PIN ON THE FORM'S LAYOUT, and deliberately so.
# They were read off dialog_blank.png, and if a field is added, removed or
# reordered the presses land elsewhere — which shows up as a wrong column set
# in the CSV, not as a silent pass, because the six measure boxes decide the
# six measure columns and the header is checked.
#
# TYPED, NOT BROWSED. The Sound folder field has a Browse button beside it and
# a GTK file chooser is a second window to drive; the field itself takes
# keystrokes, measured here on 16 August 2026, so the shorter path is the one
# with fewer moving parts. ctrl+a first because the field may not be empty.
clickin "$DIALOG_ID" 250 95
DISPLAY="$DISP" xdotool key --clearmodifiers ctrl+a; sleep 1
DISPLAY="$DISP" xdotool type --clearmodifiers --delay 30 "$CORPUS"; sleep 1
for y in 435 467 499 531; do clickin "$DIALOG_ID" 278 "$y"; done
clickin "$DIALOG_ID" 384 592
DISPLAY="$DISP" xdotool key --clearmodifiers ctrl+a; sleep 1
DISPLAY="$DISP" xdotool type --clearmodifiers --delay 30 "300"; sleep 1
DISPLAY="$DISP" import -window "$DIALOG_ID" "$OUT/dialog_filled.png" 2>/dev/null

# Run is the last button of "Quit | Standard | Run".
clickin "$DIALOG_ID" 444 938
sleep 6

# ── the batch range dialog ───────────────────────────────────────────────
hit=$(pausewait 20) || hit=$'\t'
RANGE_ID="${hit%%$'\t'*}"
say range_title "${hit#*$'\t'}"
if [[ "${hit#*$'\t'}" == "Batch range" ]]; then
    DISPLAY="$DISP" import -window "$RANGE_ID" "$OUT/range.png" 2>/dev/null
    clickin "$RANGE_ID" 415 151      # Run, of "Quit | Run"
fi

# ── wait for the run to finish ───────────────────────────────────────────
# THE INFO WINDOW APPEARING IS NOT THE END OF THE RUN — it is raised by the
# first appendInfoLine:, which happens before a single file is read. So the
# wait is for the CSV, and it is bounded rather than fixed: a fixed sleep is a
# race that the slowest machine of the week loses, and a lost race here reads
# as "the module wrote nothing".
waited=0
while [[ $waited -lt 120 ]]; do
    found=$(find "$HOME_AFTER" -name '*_results_*.csv' -type f 2>/dev/null | head -1)
    [[ -n "$found" ]] && break
    sleep 5; waited=$((waited + 5))
done
say drive_wait_seconds "$waited"

# ── the Info window, as text and as a picture ────────────────────────────
sleep 5
INFOW=$(winid_by_name "Praat Info")
if [[ -n "$INFOW" ]]; then
    DISPLAY="$DISP" import -window "$INFOW" "$OUT/info.png" 2>/dev/null
fi
say info_window_present "$([[ -n "$INFOW" ]] && echo 1 || echo 0)"

DISPLAY="$DISP" HOME="$HOME_AFTER" \
    timeout 60 "$PRAAT" --pref-dir="$WORK/prefs_after" --utf8 \
    --send "$SCRIPT_DIR/grab.praat" "$WORK/INFO.raw" > "$WORK/grab.log" 2>&1
# --send IS FIRE AND FORGET. It hands the script to the running instance and
# exits — it does not wait for it to finish, and it reports success either
# way. The first version tested for the file on the next line and never found
# it: the write landed about a second later, so every run reported no Info
# evidence while the file sat in work/ being overwritten by the next run's
# rm -rf. A harness that misses its own artefact by a second reads exactly
# like a harness whose artefact was never produced.
gwait=0
while [[ $gwait -lt 30 && ! -s "$WORK/INFO.raw" ]]; do
    sleep 2; gwait=$((gwait + 2))
done
say info_grab_seconds "$gwait"
# APPENDIX_F's file-output rule, live: the module's warnings carry em dashes,
# so Praat wrote this file as UTF-16 whatever --utf8 said. Converted here
# rather than papered over, and the BOM is tested rather than assumed so that
# a future ASCII-only build does not get mangled by an unconditional iconv.
if [[ -f "$WORK/INFO.raw" ]]; then
    if [[ "$(head -c2 "$WORK/INFO.raw" | od -An -tx1 | tr -d ' ')" == "feff" ]]; then
        iconv -f UTF-16 -t UTF-8 "$WORK/INFO.raw" > "$OUT/INFO.txt" 2>/dev/null
        say info_encoding utf16
    else
        cp "$WORK/INFO.raw" "$OUT/INFO.txt"
        say info_encoding utf8
    fi
fi
stop_praat

# ---------------------------------------------------------------------------
# 6. THE FACTS
# ---------------------------------------------------------------------------
csv=$(find "$HOME_AFTER" -name '*_results_*.csv' -type f 2>/dev/null | head -1)
if [[ -n "$csv" ]]; then
    cp "$csv" "$OUT/RESULTS.csv"
    say csv_name "$(basename "$csv")"
    say csv_rows "$(( $(wc -l < "$csv") - 1 ))"
    say csv_header "$(head -1 "$csv")"
    # THE OUTPUT FOLDER IS THE ONE THE FORM PROPOSED, which is the 14 August
    # ruling: the results land in the user's designated folder and never in
    # the corpus. Recorded as the folder's name, not as a boolean, so a wrong
    # answer says where it went.
    say csv_folder "$(basename "$(dirname "$csv")")"
fi
# NOTHING WAS WRITTEN INTO THE CORPUS. The ruling's other half, and the only
# way to check it is to look at the folder of recordings afterwards.
say corpus_extra_files \
    "$(find "$CORPUS" -type f ! -name '*.wav' 2>/dev/null | wc -l)"

if [[ -f "$OUT/INFO.txt" ]]; then
    say info_lines "$(wc -l < "$OUT/INFO.txt")"
    say info_warning_lines "$(grep -c 'WARNING:' "$OUT/INFO.txt")"
    say summary_warnings \
        "$(sed -n 's/^Warnings: *\([0-9][0-9]*\).*/\1/p' "$OUT/INFO.txt" | head -1)"
    say summary_processed \
        "$(sed -n 's/^Files processed: *\([0-9][0-9]*\).*/\1/p' "$OUT/INFO.txt" | head -1)"
    say summary_rows \
        "$(sed -n 's/^Data rows: *\([0-9][0-9]*\).*/\1/p' "$OUT/INFO.txt" | head -1)"
    # THE FOUR OUTCOMES OF THE RANGE GUARD, one line each, matched on the
    # MEASURE AND THE LIMIT rather than on the whole sentence — re-wording a
    # warning must not fail the suite, dropping one must.
    has () { grep -qE "$2" "$OUT/INFO.txt" && say "$1" 1 || say "$1" 0; }
    has warn_rcc_floor \
        'WARNING: minimum F0 .* within 10% of the 75 Hz floor of the raw-cross-correlation pitch range'
    has warn_fac_floor \
        'WARNING: minimum F0 .* within 10% of the 50 Hz floor of the filtered-autocorrelation pitch range'
    has warn_cpps_ceiling \
        'WARNING: maximum F0 .* within 10% of the 330 Hz ceiling of the CPPS peak search window'
    has warn_cpps_floor \
        'WARNING: minimum F0 .* within 10% of the 60 Hz floor of the CPPS peak search window'
    has warn_stated \
        'WARNING: measured F0 reached .* above the stated highest expected F0 of 300 Hz'
    has warn_stated_names_derived \
        'That value set the pitch top \(800 Hz\) and the pitch ceiling \(600 Hz\)'
fi

say completed 1
echo
printf 'batchgui: walk of %d reached "%s" (before: "%s")\n' \
       "$MENU_ORDINAL" "$DIALOG_TITLE" \
       "$(awk -F'\t' '$1=="menu_before_title"{print $2}' "$TSV")"
printf 'batchgui: evidence in %s\n' "$OUT"
echo
echo "Now run: Rscript validate/v72_batch_registration.R"
