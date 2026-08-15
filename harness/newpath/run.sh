#!/usr/bin/env bash
# ============================================================================
# newpath/run.sh — press the buttons that come AFTER a result
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# WHY THIS HARNESS EXISTS, and both halves of it are the same shape of gap.
#
# A wrapper's journey does not end at "Analysis complete". That dialog offers
# Save, Draw and New, and New offers to start again. Every harness in this tree
# stops before or at the first of those: harness/gui_e2e drives the graphs form,
# harness/savepaths presses Save. NOTHING had ever pressed New, and nothing had
# ever pressed New AFTER a Draw.
#
# On 14 August 2026 that was found by hand on eml-compare-paired.praat. The
# spaghetti plot is drawn from a wide->long reshape the wrapper builds, and the
# graph layer reads that reshape's column names -- into the same shared array
# the entry form is rebuilt from. So New came back offering Subject, Condition
# and Value, the reshape's ROLE names, on a reshape that had already been
# removed; Run died with "Column not found: Condition"; Back returned to the
# same form. Only quitting Praat recovered. The analysis before it was
# numerically perfect and every export was correct, which is why nothing that
# reads numbers or files could have seen it.
#
# The second leg is the same thing said about a file. eml-check-data.praat's
# file mode answers one question -- will Praat's reader accept this CSV -- and
# it answered "No import problems found" on a CSV whose rows are of unequal
# width, which Praat's reader refuses outright. A check that says a file is
# clean is worth exactly what its coverage is worth, so this leg drives eight
# purpose-built files through the shipped dialog and, separately and headlessly,
# asks PRAAT'S OWN READER what it does with the same eight. The two answers
# have to agree; validate/v60_wrapper_paths.R is where they are compared.
#
# WHAT THIS PRODUCES, all under out/:
#   DIALOGS.tsv        the paired leg's dialog chain, in order, with the button
#                      pressed on each. The chain IS the finding: a New that
#                      dead-ends shows up as "Cannot run this analysis" where a
#                      third "Analysis complete" belongs.
#   NEWFORM.png/.txt   the entry form as New reopened it, and its OCR. The
#                      picture is what a person reads; the OCR is what a
#                      validator can assert on.
#   PAIRED_INFO.txt    the Info window at the end of the leg — two analyses
#                      when New worked, one when it did not.
#   PAIRED_OBJECTS.txt the object list at the end, which is where a reshape
#                      that failed to be removed would show up.
#   FIGURE_TITLE.txt   OCR of the saved figure, where the reshape's name used
#                      to appear in the automatic title.
#   ARTEFACTS.tsv      what the Save panel wrote, by filename — which is where
#                      the reshape's name used to appear in the save stem.
#   READER.tsv         Praat's own reader on each case file: OK or REFUSED,
#                      and the message. Ground truth, established rather than
#                      assumed.
#   FILECHECK.tsv      one line per case: what the shipped file mode said.
#   verdict_*.txt      the full report for each case.
#
# Run from anywhere:  bash harness/newpath/run.sh
#   $EML_NEWPATH_ONLY=paired|filecheck|reader  restricts the run.
# Exit 0 = every leg reached the end of its chain.
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
OUT="$SCRIPT_DIR/out"
PREFS="$SCRIPT_DIR/prefs"
CASES="$SCRIPT_DIR/cases"
WRAPDIR="$EML_ROOT/plugin/scripts"
ONLY="${EML_NEWPATH_ONLY:-}"

# SCRATCH LIVES UNDER out/work/, EVIDENCE LIVES UNDER out/. The X server's
# log, the window manager's log, the generated reader probe and every leg's
# driver log are diagnostics, not artefacts, and a directory that mixes the
# two is a directory nobody can tell has gone stale. One line of .gitignore
# covers the lot.
mkdir -p "$OUT" "$OUT/work" "$PREFS" "$CASES"

for t in Xvfb xdotool xprop matchbox-window-manager import tesseract; do
    command -v "$t" >/dev/null || { echo "newpath: FAIL — no $t"; exit 1; }
done

# ---------------------------------------------------------------------------
# THE CASE FILES, written here rather than committed as fixtures
# ---------------------------------------------------------------------------
# Every byte of them is visible in this file, which matters more than usual:
# the property under test is a count of comma-separated fields per line, and a
# fixture whose exact bytes live somewhere else is a fixture whose meaning has
# to be taken on trust. printf, not a here-document, so trailing newlines and
# their absence are explicit.
#
# The numbering is the drive order. The GUI leg types these paths into the file
# chooser one at a time and the headless reader probe walks the same sorted
# list, so the two evidence files line up row for row.
rm -f "$CASES"/*.csv
printf 'subject,group,F0_Hz\nS1,Soprano,220.5\nS2,Alto,180.9\nS3,Alto,175.4\n'   > "$CASES/01_clean.csv"
printf 'subject,group,F0_Hz\nS1,Soprano,220.5\nS2,Alto\nS3,Alto,175.4\n'         > "$CASES/02_short_middle.csv"
printf 'subject,group,F0_Hz\nS1,Soprano,220.5\nS2,Alto,180.9\nS3,Alto\n'         > "$CASES/03_short_last.csv"
printf 'subject,group,F0_Hz\nS1,Soprano,220.5,9\nS2,Alto,180.9\nS3,Alto,175.4\n' > "$CASES/04_long_middle.csv"
printf 'subject,group,F0_Hz\nS1,Soprano,220.5\nS2,Alto,180.9\nS3,Alto,175.4,9\n' > "$CASES/05_long_last.csv"
printf 'subject,group,F0_Hz\nS1,Soprano,220.5\n\nS3,Alto,175.4\n'                > "$CASES/06_blank_middle.csv"
printf 'subject,group,F0_Hz\nS1,"Soprano, lyric",220.5\nS2,"Alto\ndramatic",180.9\n' > "$CASES/07_quoted_ok.csv"
printf 'subject,group,F0_Hz\n'                                                   > "$CASES/08_header_only.csv"

# ---------------------------------------------------------------------------
# GROUND TRUTH: what Praat's own reader does with each case
# ---------------------------------------------------------------------------
# ESTABLISHED, NOT ASSUMED, and the distinction earned its keep. The rule
# implemented in the plugin — every data row carries the header's field count,
# surplus on the FINAL row being discarded silently instead of refused — was
# read off THIS probe over a battery of twenty files, not off documentation and
# not off memory. Two of its three arms are undocumented behaviour.
#
# One Praat per file rather than a loop inside one script: `nocheck` does not
# bind the variable of a failed assignment, so a refusal inside a loop cannot
# be caught and the second case would run with the first case's object id.
run_reader () {
    echo "newpath: reader — Praat's own CSV reader on each case"
    local RTSV="$OUT/READER.tsv"
    : > "$RTSV"
    local probe="$OUT/work/reader_probe.praat"
    cat > "$probe" <<'PRAAT'
f$ = environment$ ("EML_NEWPATH_CSV")
tid = Read Table from comma-separated file: f$
nr = Get number of rows
nc = Get number of columns
writeInfoLine: "OK rows=", nr, " cols=", nc
PRAAT
    local f nm log verdict msg
    for f in "$CASES"/*.csv; do
        nm="$(basename "$f")"
        log="$OUT/work/reader_$nm.log"
        mkdir -p "$OUT/work"
        ( EML_NEWPATH_CSV="$f" timeout 60 env -u DISPLAY "$PRAAT" $PRAAT_TRUST \
            --pref-dir="$PREFS" --run "$probe" > "$log" 2>&1 ) 2>/dev/null
        if grep -q '^OK ' "$log"; then
            verdict="OK"
            msg="$(head -1 "$log")"
        else
            verdict="REFUSED"
            msg="$(head -1 "$log")"
        fi
        printf '%s\t%s\t%s\n' "$nm" "$verdict" "$msg" >> "$RTSV"
        printf '  %-24s %s\n' "$nm" "$verdict: $msg"
    done
}

# ---------------------------------------------------------------------------
# THE DISPLAY
# ---------------------------------------------------------------------------
DISP=":89"
XVFB_PID=0; WM_PID=0; PRAAT_PID=0

start_display () {
    Xvfb "$DISP" -screen 0 1400x1000x24 > "$OUT/work/xvfb.log" 2>&1 &
    XVFB_PID=$!
    sleep 2
    DISPLAY="$DISP" matchbox-window-manager -use_titlebar no > "$OUT/work/wm.log" 2>&1 &
    WM_PID=$!
    sleep 2
}

# BY PID, NEVER BY PATTERN. `pkill -f praat` matches this script's own command
# line through the driving shell and kills the run itself — measured the hard
# way, 11 Aug 2026, exit 144. `pkill -x praat` does not do that, but it kills
# every OTHER Praat on the machine too, which on a shared sandbox means killing
# somebody else's drive mid-form; this run lost a Praat that way while it was
# being written, and the symptom was a chain that simply stopped.
#
# So the process is found by the one thing on its command line that belongs to
# THIS run — its scratch pref dir — and killed by the pid that comes back.
# $PRAAT_PID is the subshell's, which is not always Praat's: bash execs the
# child in place only when the subshell holds a single simple command, and this
# one holds a `cd &&` compound. Both are killed.
kill_leg () {
    local pids
    pids=$(pgrep -f -- "--pref-dir=$PREFS" 2>/dev/null)
    if [[ -n "$pids" ]]; then kill -9 $pids 2>/dev/null; fi
    if [[ "$PRAAT_PID" != 0 ]]; then kill -9 "$PRAAT_PID" 2>/dev/null; fi
    PRAAT_PID=0
    return 0
}

cleanup () {
    kill_leg
    [[ "$WM_PID" != 0 ]] && kill "$WM_PID" 2>/dev/null
    [[ "$XVFB_PID" != 0 ]] && kill "$XVFB_PID" 2>/dev/null
    return 0
}
trap cleanup EXIT

# Window lookup walks _NET_CLIENT_LIST via xprop rather than `xdotool search`:
# search reads WM_NAME, which GTK leaves unset for a title containing an em
# dash, and it returns the unmapped husk of every dismissed dialog forever.
# GUI_HARNESS_RECIPE §11.
winlist () {
    local ids id name
    ids=$(DISPLAY="$DISP" xprop -root _NET_CLIENT_LIST 2>/dev/null \
          | sed -n 's/.*# //p' | tr -d ' ' | tr ',' '\n')
    for id in $ids; do
        [[ "$id" == 0x* ]] || continue
        name=$(DISPLAY="$DISP" xdotool getwindowname "${id}" 2>/dev/null)
        printf '%s\t%s\n' "$id" "$name"
    done
}

# ANY window that is not one of the three permanent ones is something the run
# has to act on: a pause form, a GTK file chooser, or a Praat error window with
# no name at all. Treating "no pause window" as "the chain ended" is how a hard
# failure reads as a mild one — harness/savepaths records the same lesson.
nextwin () {
    winlist | grep -v -E $'\t(Praat Objects|Praat Picture|Praat Info)$' | head -1
}

nextwait () {   # nextwait <seconds>
    local waited=0 line
    while [[ $waited -lt $1 ]]; do
        line=$(nextwin)
        if [[ -n "$line" ]]; then printf '%s\n' "$line"; return 0; fi
        sleep 2
        waited=$((waited + 2))
    done
    return 1
}

# XTEST, not XSendEvent: `xdotool key --window <id>` sends a synthetic event
# GTK ignores. Buttons are counted from the END of the form because that is the
# only count that is stable — a form's leading fields change with the data, its
# button row does not.
press () {   # press <window-id> <n-from-end>
    DISPLAY="$DISP" xdotool windowactivate --sync "$1" 2>/dev/null
    sleep 1
    DISPLAY="$DISP" xdotool key --clearmodifiers --repeat "$2" shift+Tab 2>/dev/null
    sleep 1
    DISPLAY="$DISP" xdotool key --clearmodifiers Return 2>/dev/null
}

# The GTK file chooser has no button row worth counting. Ctrl+L raises its
# location bar, which takes a full path and Return opens it.
typepath () {   # typepath <window-id> <path>
    DISPLAY="$DISP" xdotool windowactivate --sync "$1" 2>/dev/null
    sleep 1
    DISPLAY="$DISP" xdotool key --clearmodifiers ctrl+l 2>/dev/null
    sleep 1
    DISPLAY="$DISP" xdotool type --clearmodifiers --delay 30 "$2"
    sleep 1
    DISPLAY="$DISP" xdotool key --clearmodifiers Return 2>/dev/null
}

# ---------------------------------------------------------------------------
# LEG A — paired: Run, Draw, then New
# ---------------------------------------------------------------------------
run_paired () {
    echo "newpath: paired — Run, Draw, New, Run"
    local LOUT="$OUT/work/paired"
    rm -rf "$LOUT"; mkdir -p "$LOUT"
    rm -f "$OUT/DIALOGS.tsv" "$OUT/NEWFORM.png" "$OUT/NEWFORM.txt" \
          "$OUT/PAIRED_INFO.txt" "$OUT/PAIRED_OBJECTS.txt" \
          "$OUT/ARTEFACTS.tsv" "$OUT/FIGURE_TITLE.txt" "$OUT/paired.error.png"

    # Only the lock files, never the whole pref dir mid-run: 6.6.30 keeps its
    # instance lock here, and a stale lock makes Praat exit with "An instance
    # of Praat that is not me is already running", which reads as a harness bug.
    rm -rf "$PREFS"; mkdir -p "$PREFS"
    rm -f "$PREFS/pid" "$PREFS/message" 2>/dev/null

    # A HOME OF ITS OWN, and it is load-bearing rather than tidy: the Save
    # panel seeds its folder from homeDirectory$, so pointing HOME inside out/
    # means the panel's PROPOSED folder is already where the evidence goes.
    # That field is a GtkTextView and cannot be typed into.
    local LHOME="$LOUT/home"
    rm -rf "$LHOME"; mkdir -p "$LHOME"

    ( cd "$SCRIPT_DIR" && DISPLAY="$DISP" HOME="$LHOME" \
        EML_NEWPATH_LEG="paired" EML_NEWPATH_OUT="$OUT" \
        EML_NEWPATH_WRAPDIR="$WRAPDIR" \
        "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" --utf8 --new-send "leg.praat" \
        > "$LOUT/driver.log" 2>&1 ) &
    PRAAT_PID=$!
    sleep 10

    local TSV="$OUT/DIALOGS.tsv"
    : > "$TSV"

    local step=0 acVisit=0 gcVisit=0 entryVisit=0 line wid title rev label
    while [[ $step -lt 20 ]]; do
        line=$(nextwait 40) || break
        wid=${line%%$'\t'*}
        title=${line#*$'\t'}
        step=$((step + 1))

        rev=1; label="LAST"
        case "$title" in
            # The entry form: Quit | Run.
            "Pause: Compare Paired Observations")
                entryVisit=$((entryVisit + 1))
                rev=1; label="Run"
                # THE SECOND VISIT IS THE FINDING. It is the form "New"
                # reopened, and what its column menus OFFER is the whole
                # question — which is not recoverable afterwards from
                # anything the run leaves on disk, so it is photographed
                # before it is pressed.
                if [[ $entryVisit -eq 2 ]]; then
                    DISPLAY="$DISP" import -window "$wid" "$OUT/NEWFORM.png" 2>/dev/null
                    tesseract "$OUT/NEWFORM.png" "${OUT}/NEWFORM" 2>/dev/null
                fi ;;
            # Done | Save | Draw | New.
            "Pause: Analysis complete"|"Pause: Analysis Complete")
                acVisit=$((acVisit + 1))
                case $acVisit in
                    1) rev=2; label="Draw" ;;
                    2) rev=1; label="New" ;;
                    *) rev=4; label="Done" ;;
                esac ;;
            "Pause: EML Graphs")                 rev=1; label="Continue" ;;
            *"Column Mapping"*|*"Settings")      rev=1; label="Draw" ;;
            *"Data Format"*)                     rev=1; label="Continue" ;;
            # Done | Save | Redraw.
            *"Graph Complete"*)
                gcVisit=$((gcVisit + 1))
                case $gcVisit in
                    1) rev=2; label="Save" ;;
                    *) rev=3; label="Done" ;;
                esac ;;
            "Pause: Save")                       rev=1; label="Save" ;;
            "Pause: Saved")                      rev=1; label="OK" ;;
            "Pause: Nothing saved")              rev=1; label="OK" ;;
            # THE DEAD END, when it is there. Quit is 2 from the end on the
            # plugin's error dialog (Quit | Back); pressing it ends the
            # wrapper cleanly, so the leg still writes its evidence instead
            # of being killed mid-form.
            "Pause: Cannot run this analysis")   rev=2; label="Quit" ;;
        esac

        printf '%d\t%s\t%s\t%d\n' "$step" "${title#Pause: }" "$label" "$rev" >> "$TSV"
        press "$wid" "$rev"
        sleep 4
    done

    sleep 4
    kill_leg
    sleep 2

    # ── artefacts ────────────────────────────────────────────────────────
    # The Save panel's filenames are the second half of the name leak: the
    # figure used to be saved under the reshape's name, which is a deliverable
    # named after a transient the user never created.
    local ATSV="$OUT/ARTEFACTS.tsv"
    : > "$ATSV"
    while IFS= read -r f; do
        [[ "$(basename "$f")" == "eml-graphs-config.txt" ]] && continue
        printf '%s\t%s\n' "$(basename "$f")" "$(stat -c%s "$f")" >> "$ATSV"
    done < <(find "$LHOME" -maxdepth 2 \
             \( -name '*.csv' -o -name '*.png' -o -name '*.txt' \) \
             -type f 2>/dev/null | sort)

    # THE TITLE IS ON THE FIGURE, nowhere else. It is composed at draw time
    # from the drawn object's name and never written to any file, so the only
    # place to read it is the pixels.
    local fig
    fig=$(find "$LHOME" -maxdepth 2 -name '*.png' -type f 2>/dev/null | sort | head -1)
    if [[ -n "$fig" ]]; then
        cp "$fig" "$OUT/FIGURE.png"
        tesseract "$OUT/FIGURE.png" "${OUT}/FIGURE_TITLE" 2>/dev/null
    fi

    echo "newpath: paired — $(wc -l < "$TSV") dialog(s), $(wc -l < "$ATSV") artefact(s)"
}

# ---------------------------------------------------------------------------
# LEG B — filecheck: eight CSVs through the shipped file mode
# ---------------------------------------------------------------------------
run_filecheck () {
    echo "newpath: filecheck — eight CSVs through Check & repair, file mode"
    local LOUT="$OUT/work/filecheck"
    rm -rf "$LOUT"; mkdir -p "$LOUT"
    rm -f "$OUT/FILECHECK.tsv"

    rm -rf "$PREFS"; mkdir -p "$PREFS"
    rm -f "$PREFS/pid" "$PREFS/message" 2>/dev/null

    local LHOME="$LOUT/home"
    rm -rf "$LHOME"; mkdir -p "$LHOME"

    # The drive order the chooser is typed in. `sort` here and Praat's
    # `Create Strings as file list` inside leg.praat both walk the directory in
    # name order, which is why the case files are numbered: the two lists must
    # be the same list or every verdict is filed under the wrong case.
    # ONLY THE OUTSTANDING CASES, by exactly the rule leg.praat applies on the
    # other side of the pipe: a case whose verdict is already on disk has
    # already been driven. Both lists are built from the same directory in the
    # same name order, so the path this shell types is the path the wrapper's
    # chooser is waiting for.
    local -a caseList allCases
    mapfile -t allCases < <(find "$CASES" -maxdepth 1 -name '*.csv' | sort)
    caseList=()
    local c
    for c in "${allCases[@]}"; do
        [[ -s "$OUT/verdict_$(basename "$c").txt" ]] || caseList+=("$c")
    done
    if [[ ${#caseList[@]} -eq 0 ]]; then
        echo "newpath: filecheck — every case already driven"
    fi

    ( cd "$SCRIPT_DIR" && DISPLAY="$DISP" HOME="$LHOME" \
        EML_NEWPATH_LEG="filecheck" EML_NEWPATH_OUT="$OUT" \
        EML_NEWPATH_WRAPDIR="$WRAPDIR" EML_NEWPATH_CASES="$CASES" \
        "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" --utf8 --new-send "leg.praat" \
        > "$LOUT/driver.log" 2>&1 ) &
    PRAAT_PID=$!
    sleep 10

    local DTSV="$OUT/FILECHECK_DIALOGS.tsv"
    : > "$DTSV"
    local step=0 chooser=0 line wid title
    while [[ $step -lt 40 ]]; do
        line=$(nextwait 40) || break
        wid=${line%%$'\t'*}
        title=${line#*$'\t'}
        step=$((step + 1))
        if [[ "$title" == *"Choose the CSV file"* ]]; then
            chooser=$((chooser + 1))
            # MORE CHOOSERS THAN CASES means the two lists have come apart,
            # which is the one failure this leg must not absorb: it would file
            # a verdict under the wrong case and the mismatch would read as a
            # plugin defect. Stop instead.
            if [[ $chooser -gt ${#caseList[@]} ]]; then
                printf '%d\t%s\tUNEXPECTED CHOOSER\n' "$step" "$title" >> "$DTSV"
                break
            fi
            printf '%d\t%s\t%s\n' "$step" "$title" "${caseList[$((chooser - 1))]}" >> "$DTSV"
            typepath "$wid" "${caseList[$((chooser - 1))]}"
        else
            printf '%d\t%s\t%s\n' "$step" "${title#Pause: }" "Continue" >> "$DTSV"
            press "$wid" 1
        fi
        sleep 4
    done

    sleep 4
    kill_leg
    sleep 2

    # ── one line per case ────────────────────────────────────────────────
    # The classification is read off the report's own words rather than off a
    # guess about what it meant to say. FLAGGED means the report named a
    # row-length problem; CLEAN means it gave its enumerated clean verdict;
    # OTHER means it said something else, which is a case this harness does
    # not understand and must not quietly file as either.
    local FTSV="$OUT/FILECHECK.tsv"
    : > "$FTSV"
    local nm v txt
    for f in "${allCases[@]}"; do
        nm="$(basename "$f")"
        txt="$OUT/verdict_${nm}.txt"
        if [[ ! -f "$txt" ]]; then
            v="MISSING"
        elif grep -q "ROW LENGTHS" "$txt"; then
            v="FLAGGED"
        elif grep -q "Nothing found by the three checks" "$txt"; then
            v="CLEAN"
        elif grep -q "No import problems found" "$txt"; then
            v="CLEAN_OLD"
        else
            v="OTHER"
        fi
        printf '%s\t%s\n' "$nm" "$v" >> "$FTSV"
        printf '  %-24s %s\n' "$nm" "$v"
    done

    echo "newpath: filecheck — $(wc -l < "$DTSV") dialog(s), $(wc -l < "$FTSV") case(s)"
}

# ---------------------------------------------------------------------------
# RETRIES, RECORDED
# ---------------------------------------------------------------------------
# A GUI leg here can lose its Praat mid-chain. It is not the plugin and it is
# not the drive: the process dies with SIGKILL, which nothing in this script
# sends and nothing in Praat raises. On a shared sandbox `pkill -9 -x praat`
# from any other run takes this one with it, and that is the reading the
# evidence supports — the same chain, driven again unchanged, completes.
#
# A leg is COMPLETE when the thing only leg.praat can write is on disk: the
# Info window it dumps after runScript: returns. A chain that stops early
# leaves the dialog log and no dump, which is exactly the shape a killed
# process leaves and NOT the shape a defect leaves — a defect finishes the
# chain and writes a dump that says the wrong thing.
#
# Retrying silently would be worse than not retrying: the run would go green
# and a real regression would need two consecutive failures to show. So every
# retry is written down, and a leg that never completes is a failure.
retry_leg () {   # retry_leg <name> <function> <completion-marker>
    local name="$1" fn="$2" marker="$3" attempt=1
    while [[ $attempt -le 6 ]]; do
        "$fn"
        if [[ -s "$marker" ]]; then
            [[ $attempt -gt 1 ]] && printf '%s\tattempt %d\n' "$name" "$attempt" \
                >> "$OUT/RETRIES.tsv"
            return 0
        fi
        echo "newpath: $name — chain did not complete on attempt $attempt"
        printf '%s\tattempt %d incomplete\n' "$name" "$attempt" >> "$OUT/RETRIES.tsv"
        attempt=$((attempt + 1))
        sleep 5
    done
    echo "newpath: $name — FAIL, six attempts and no completed chain."
    return 1
}

rc=0
if [[ -z "$ONLY" || "$ONLY" == "reader" ]]; then
    run_reader
fi
if [[ -z "$ONLY" || "$ONLY" == "paired" || "$ONLY" == "filecheck" ]]; then
    : > "$OUT/RETRIES.tsv"
    # THE VERDICTS ARE CLEARED HERE, ONCE, and not inside the leg. The leg
    # resumes across attempts by reading which verdicts are already on disk, so
    # a leg that cleared them would never resume; a run that never cleared them
    # would report a verdict from a previous build as if this one had produced
    # it, which is the stale-evidence failure v47 exists to catch.
    if [[ -z "$ONLY" || "$ONLY" == "filecheck" ]]; then
        rm -f "$OUT"/verdict_*.txt
    fi
    start_display
    if [[ -z "$ONLY" || "$ONLY" == "paired" ]]; then
        retry_leg "paired" run_paired "$OUT/PAIRED_INFO.txt" || rc=1
    fi
    if [[ -z "$ONLY" || "$ONLY" == "filecheck" ]]; then
        retry_leg "filecheck" run_filecheck \
            "$OUT/verdict_08_header_only.csv.txt" || rc=1
    fi
fi

echo
echo "newpath: evidence in $OUT"
echo "         (Praat $("$PRAAT" --version 2>&1 | head -1))"
exit $rc
