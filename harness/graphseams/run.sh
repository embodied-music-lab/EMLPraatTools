#!/usr/bin/env bash
# ============================================================================
# graphseams/run.sh — the graphs form's seams, driven through its own dialogs
# ============================================================================
# THREE LEGS, THREE PRAAT INSTANCES, one display. Each leg is a whole session
# from the main form to teardown, and each exists because ONE of the 14 August
# audit's graphs findings cannot be seen any other way:
#
#   A1 kwadv    THE CRASH (S6 / NEW-G9-1). A STANDALONE annotated nonparametric
#               draw on three groups, in advanced mode, with nothing run
#               before it -- which is the audit's own reproduction and, as
#               driver_kw_adv.praat's header records, the only shape of it that
#               can fail. A leg that runs the wrapper's analysis first has the
#               pairwise matrix already declared by that orchestrator and the
#               bridge's omission is invisible. The fixture is three
#               well-separated groups because the crash fires only on the
#               SIGNIFICANT branch.
#
#   A2 kw       D7. The same wrapper's handover, but the user presses Draw on
#               the BEGINNER page: before the fix the preset was zeroed at
#               every beginner commit, so the default journey drew a
#               significant result unannotated. The separator is the same
#               integer v51 uses: how many analysis sections the saved report
#               contains. The driver's own orchestrator writes one. The
#               annotation bridge writes a second, and can only do so if
#               annotate survived the beginner commit.
#
#   B  scatter  Three Draws in one session, one export (NEW-G8-3). The
#               separator is the ROW COUNT of the results CSV: one block if
#               the collector is reset per press, three if it is not. No
#               wrapper analysis runs first -- see the driver's header.
#               This leg also photographs and MEASURES the advanced scatter
#               dialog, which the audit could only get past by keyboard
#               because its button row falls off a 1000px display.
#
#   C  legend   A beginner scatter, saved, with `legendPlacement: 4` already
#               in the pref dir -- what quitting an advanced session with
#               "Separate figure" leaves behind (D8). The separator is a file
#               that should not exist: <stem>_legend.png.
#
# NO SCREEN COORDINATES, and the button is counted from the END. Focus starts
# at ring position 0, so ONE shift+Tab wraps to the last widget, which is the
# last button; N presses the Nth button from the end. harness/tabwalk measured
# that on every button-row shape in the plugin, and harness/gui_adv's header
# records why a FORWARD count cannot work (a folder: field is a GtkTextView
# and eats Tab as a literal character). The counts here come from the
# endPause: lists in eml-graphs-form.praat:
#
#   EML Graphs             Quit Continue                 -> Continue is 1
#   ... Column Mapping     GoBack Quit <toggle> Draw     -> Draw 1, toggle 2
#   Save Figure / Save     GoBack Save                   -> Save     is 1
#   Saved / Column Error   OK                            -> OK       is 1
#   Graph Complete         Done Save Redraw              -> Redraw 1, Save 2,
#                                                           Done 3
#
# KILLING. By RECORDED PID, never by name: `pkill -f praat` matches the
# driving shell's own command line and kills it (D126), and even
# `pkill -x praat` takes out whatever another agent is running. A display of
# this harness's own for the same reason -- :88, :89, :91, :92 and :93 are
# taken by savepaths, newpath, gui_e2e, tabwalk and gui_adv.
#
# Run from anywhere:  bash harness/graphseams/run.sh
# Exit 0 = every leg completed and every seam artefact was written.
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$SCRIPT_DIR/.." && pwd)/_env.sh" || exit 1
OUT="$SCRIPT_DIR/out"
mkdir -p "$OUT"
rm -rf "$OUT"/*.tsv "$OUT"/*.log "$OUT"/*.png "$OUT"/*.txt "$OUT"/home_* 2>/dev/null

DISP=":94"
XVFB_PID=""
WM_PID=""
PRAAT_PID=""
# RETRIES, as the other harnesses keep them (savepaths, newpath): one line per
# attempt that had to be made again, so a flake is recorded rather than
# absorbed. This rig has needed none -- four legs, five runs, no retry -- and
# the file is written empty rather than not written, because an absent file and
# a clean run are not the same statement.
RETRIES="$OUT/RETRIES.tsv"
: > "$RETRIES"
_retry () { printf '%s\t%s\n' "$1" "$2" >> "$RETRIES"; }

cleanup() {
    [[ -n "$PRAAT_PID" ]] && kill -9 "$PRAAT_PID" 2>/dev/null
    [[ -n "$WM_PID"    ]] && kill -9 "$WM_PID"    2>/dev/null
    [[ -n "$XVFB_PID"  ]] && kill -9 "$XVFB_PID"  2>/dev/null
    rm -f "/tmp/.X${DISP#:}-lock" "/tmp/.X11-unix/X${DISP#:}" 2>/dev/null
}
trap cleanup EXIT

rm -f "/tmp/.X${DISP#:}-lock" "/tmp/.X11-unix/X${DISP#:}" 2>/dev/null
# 1000 PIXELS TALL, ON PURPOSE. The audit's dialog-clipping finding is about a
# 1000px display; a taller virtual screen would hide it, and the geometry this
# harness records would describe a screen nobody has.
Xvfb "$DISP" -screen 0 1400x1000x24 > "$OUT/xvfb.log" 2>&1 &
XVFB_PID=$!
sleep 3
if ! DISPLAY="$DISP" xdpyinfo >/dev/null 2>&1; then
    echo "graphseams: FAIL — no display on $DISP"; exit 1
fi
DISPLAY="$DISP" matchbox-window-manager -use_titlebar no > "$OUT/wm.log" 2>&1 &
WM_PID=$!
sleep 2
if ! kill -0 "$WM_PID" 2>/dev/null; then
    echo "graphseams: FAIL — the window manager did not start:"
    sed 's/^/          /' "$OUT/wm.log"
    exit 1
fi

pauseinfo () {
    local ids id name
    ids=$(DISPLAY="$DISP" xprop -root _NET_CLIENT_LIST 2>/dev/null \
          | sed -n 's/.*# //p' | tr -d ' ' | tr ',' '\n')
    for id in $ids; do
        [[ "$id" == 0x* ]] || continue
        name=$(DISPLAY="$DISP" xdotool getwindowname "${id}" 2>/dev/null)
        if [[ "$name" == Pause:* ]]; then
            printf '%s\t%s\n' "$id" "${name#Pause: }"; return 0
        fi
    done
    return 1
}

# ---------------------------------------------------------------------------
# run_leg <name> <driver.praat> <config-seed-or-"">
# ---------------------------------------------------------------------------
# Every leg gets its own pref dir and its own HOME. The pref dir because the
# saved config decides which mode the form opens in and where it points its
# folder fields -- gui_adv lost a whole run to a config that said /root. The
# HOME because with no saved folder the panel falls back to a home-relative
# path, so pointing HOME inside out/ is what makes the artefacts findable and
# keeps the run from scattering files into the real home directory.
run_leg () {
    local leg="$1" drv="$2" seed="$3"
    local prefs="$SCRIPT_DIR/prefs_$leg"
    local home="$OUT/home_$leg"
    local tsv="$OUT/DIALOGS_$leg.tsv"
    rm -rf "$prefs" "$home"; mkdir -p "$prefs" "$home"
    : > "$tsv"
    # A stale instance lock reads as a harness bug; only these two are removed.
    rm -f "$prefs/pid" "$prefs/message" 2>/dev/null
    rm -f "$HOME/.config/praat/pid.txt" "$HOME/.config/praat/Message.txt" 2>/dev/null
    if [[ -n "$seed" ]]; then
        printf '%s\n' "$seed" > "$prefs/eml-graphs-config.txt"
        cp "$prefs/eml-graphs-config.txt" "$OUT/seeded_config_$leg.txt"
    fi

    ( cd "$SCRIPT_DIR" && DISPLAY="$DISP" EML_SEAMS_OUT="$OUT" HOME="$home" \
        "$PRAAT" $PRAAT_TRUST --pref-dir="$prefs" --utf8 --new-send "$drv" \
        > "$OUT/driver_$leg.log" 2>&1 ) &
    PRAAT_PID=$!
    sleep 10

    local gcVisit=0 cmVisit=0 step=0 line wid title rev label
    local maxsteps=30
    while [[ $step -lt $maxsteps ]]; do
        line=$(pauseinfo) || break
        wid=${line%%$'\t'*}
        title=${line#*$'\t'}
        step=$((step + 1))
        rev=1; label="?"
        case "$title" in
            *"Column Mapping"*|*"Settings")
                cmVisit=$((cmVisit + 1))
                if [[ "$leg" == "scatter" && $cmVisit -eq 1 ]]; then
                    rev=2; label="Advanced"
                else
                    rev=1; label="Draw"
                fi ;;
            *"Data Format"*)   rev=1; label="Continue" ;;
            *"EML Graphs"*)    rev=1; label="Continue" ;;
            *"Graph Complete"*)
                gcVisit=$((gcVisit + 1))
                # Leg B redraws twice before it saves: three figures, one
                # export. Everywhere else the first Graph Complete saves.
                if [[ "$leg" == "scatter" && $gcVisit -le 2 ]]; then
                    rev=1; label="Redraw"
                elif [[ $gcVisit -eq 1 || ( "$leg" == "scatter" && $gcVisit -eq 3 ) ]]; then
                    rev=2; label="Save"
                else
                    rev=3; label="Done"
                fi ;;
            "Save")            rev=1; label="Save" ;;
            *"Saved"*)         rev=1; label="OK" ;;
            *"Nothing saved"*) rev=1; label="OK" ;;
            *"Column Error"*)  rev=1; label="OK" ;;
            *)                 rev=1; label="LAST" ;;
        esac

        # THE GEOMETRY IS THE DIALOG-HEIGHT FINDING, and it is recorded for
        # every dialog rather than only the one under suspicion: a check that
        # only measures the window it expects to be too tall cannot notice a
        # different one becoming so.
        geom=$(DISPLAY="$DISP" xdotool getwindowgeometry --shell "$wid" 2>/dev/null \
               | sed -n 's/^HEIGHT=//p')
        printf '%d\t%s\t%s\t%d\t%s\n' "$step" "$title" "$label" "$rev" "${geom:-0}" >> "$tsv"

        if [[ "$leg" == "scatter" && "$label" == "Draw" && $cmVisit -eq 2 ]]; then
            DISPLAY="$DISP" import -window "$wid" "$OUT/SCATTER_ADVANCED.png" 2>/dev/null
        fi

        DISPLAY="$DISP" xdotool windowactivate --sync "$wid" 2>/dev/null
        sleep 1
        DISPLAY="$DISP" xdotool key --clearmodifiers --repeat "$rev" shift+Tab 2>/dev/null
        sleep 1
        DISPLAY="$DISP" xdotool key --clearmodifiers Return 2>/dev/null
        sleep 6
    done

    # WHAT THE LEG LEFT ON DISK.
    local art="$OUT/ARTEFACTS_$leg.tsv"
    : > "$art"
    while IFS= read -r f; do
        [[ -e "$f" ]] || continue
        [[ "$(basename "$f")" == "eml-graphs-config.txt" ]] && continue
        printf '%s\t%s\n' "$(basename "$f")" "$(stat -c%s "$f")" >> "$art"
    done < <(find "$home" -maxdepth 2 \
                  \( -name '*.png' -o -name '*.csv' -o -name '*.txt' \) 2>/dev/null | sort)

    kill -9 "$PRAAT_PID" 2>/dev/null
    PRAAT_PID=""
    sleep 1
    if [[ $step -eq 0 ]]; then
        _retry "$leg" "no dialog was ever raised"
    fi
    echo "  leg $leg: $step dialogs"
}

# ONE LEG AT A TIME, WHEN THAT IS WHAT IS BEING ASKED. $EML_SEAMS_LEGS names a
# subset; unset means all four. It exists for BREAK TESTS: showing a check red
# means running the whole rig against a deliberately broken copy of the plugin,
# and three of the four legs are irrelevant to any one break. Nothing about a
# leg changes when it is run alone -- each already brings up its own Praat, its
# own pref dir and its own HOME.
LEGS="${EML_SEAMS_LEGS:-kwadv kw scatter legend}"
_want () { [[ " $LEGS " == *" $1 "* ]]; }

echo "graphseams: driving [$LEGS] on $DISP"
# ADVANCED FROM THE CONFIG, not from the toggle. @emlLoadConfig reads
# showAdvanced, and pressing the toggle instead would spend a dialog and, more
# to the point, would put this leg on the restore arm rather than on the plain
# advanced page the audit drove.
_want kwadv && run_leg kwadv   driver_kw_adv.praat  "showAdvanced: 1"
_want kw && run_leg kw      driver.praat         ""
_want scatter && run_leg scatter driver_scatter.praat ""
# THE POISONED CONFIG. showAdvanced 0 so the leg draws in BEGINNER mode --
# which is the whole point -- and legendPlacement 4, "Separate figure".
_want legend && run_leg legend  driver_legend.praat  "showAdvanced: 0
legendPlacement: 4"

# ---------------------------------------------------------------------------
# THE SEAM EVIDENCE, counted here rather than left for a validator to dig out
# ---------------------------------------------------------------------------
# The saved Info report is UTF-16 (Praat writes it that way under --utf8), so
# a validator reading it as text finds nothing. It is converted once, here.
SEAMS="$OUT/SEAMS.tsv"
: > "$SEAMS"

# --- leg A1: the crash ------------------------------------------------------
RPTA=$(ls "$OUT"/home_kwadv/*_report.txt 2>/dev/null | head -1)
if [[ -n "$RPTA" ]]; then
    iconv -f UTF-16 -t UTF-8 "$RPTA" 2>/dev/null > "$OUT/report_kwadv.utf8.txt" \
        || cp "$RPTA" "$OUT/report_kwadv.utf8.txt"
    # THE MATRIX IS THE CRASH SITE. Its heading is printed one line before the
    # read that used to abort, so the heading alone proves nothing -- the
    # audit's screenshot has it, above an error dialog. The VALUES are the
    # proof, and they are independently known: scipy puts the three
    # rank-biserial r at 0.5822, 0.7867 and 0.4400 (audit g9.verify.md), which
    # the reporter prints to three places.
    printf 'kwadv_rb_values\t%s\n' \
        "$(grep -oE '0\.(582|787|440)' "$OUT/report_kwadv.utf8.txt" | sort -u | tr '\n' ' ')" >> "$SEAMS"
    printf 'kwadv_rb_matrix_rows\t%s\n' \
        "$(grep -cE '^(Soprano|Mezzo|Alto) +(---|-?0\.[0-9]{3})' "$OUT/report_kwadv.utf8.txt")" >> "$SEAMS"
    printf 'kwadv_report_bytes\t%s\n' "$(wc -c < "$OUT/report_kwadv.utf8.txt")" >> "$SEAMS"
    # THE OMNIBUS, WRITTEN DOWN. The crash fires only on the significant branch,
    # so a leg whose fixture drifted above alpha would pass every check below
    # while testing the branch that never had the defect. The reporter prints
    # the raw double in parentheses beside its APA form.
    printf 'kwadv_omnibus_p\t%s\n' \
        "$(sed -n 's/^ *p  *< \.001  *(\([0-9.e-]*\)).*/\1/p' "$OUT/report_kwadv.utf8.txt" | head -1)" >> "$SEAMS"
else
    printf 'kwadv_rb_values\t\n' >> "$SEAMS"
    printf 'kwadv_rb_matrix_rows\t0\n' >> "$SEAMS"
    printf 'kwadv_report_bytes\t0\n' >> "$SEAMS"
    printf 'kwadv_omnibus_p\t\n' >> "$SEAMS"
fi
printf 'kwadv_artefacts\t%s\n' \
    "$(wc -l < "$OUT/ARTEFACTS_kwadv.tsv" 2>/dev/null)" >> "$SEAMS"
printf 'kwadv_dialogs\t%s\n' \
    "$(wc -l < "$OUT/DIALOGS_kwadv.tsv" 2>/dev/null)" >> "$SEAMS"
printf 'kwadv_unknown_variable\t%s\n' \
    "$(grep -c 'Unknown variable' "$OUT/driver_kwadv.log" 2>/dev/null | head -1)" >> "$SEAMS"

# --- leg A2: the report ------------------------------------------------------
RPT=$(ls "$OUT"/home_kw/*_report.txt 2>/dev/null | head -1)
if [[ -n "$RPT" ]]; then
    iconv -f UTF-16 -t UTF-8 "$RPT" 2>/dev/null > "$OUT/report_kw.utf8.txt" \
        || cp "$RPT" "$OUT/report_kw.utf8.txt"
    # "EML Stats : Kruskal-Wallis H Test" is @emlReportHeader's banner, and on
    # this journey it can appear once or twice. ONCE means the driver's own
    # orchestrator reported and nothing else did -- the annotate preset died at
    # the beginner commit, so the bridge never ran (D7). TWICE means it
    # survived and the bridge reported on top. One integer, exactly as v51.
    printf 'kw_report_sections\t%s\n' \
        "$(grep -c 'Kruskal-Wallis H Test' "$OUT/report_kw.utf8.txt")" >> "$SEAMS"
    printf 'kw_report_bytes\t%s\n' "$(wc -c < "$OUT/report_kw.utf8.txt")" >> "$SEAMS"
    # THE MATRIX IS THE CRASH SITE. Its heading is printed one line before the
    # read that used to abort, so the heading alone proves nothing -- the
    # audit's screenshot has it, above an error dialog. The VALUES are the
    # proof, and they are independently known: scipy puts the three
    # rank-biserial r at 0.5822, 0.7867 and 0.4400 (audit g9.verify.md), which
    # the reporter prints to three places.
    printf 'kw_rb_matrix_rows\t%s\n' \
        "$(grep -cE '^(Soprano|Mezzo|Alto) +(---|-?0\.[0-9]{3})' "$OUT/report_kw.utf8.txt")" >> "$SEAMS"
    printf 'kw_rb_values\t%s\n' \
        "$(grep -oE '0\.(582|787|440)' "$OUT/report_kw.utf8.txt" | sort -u | tr '\n' ' ')" >> "$SEAMS"
fi
printf 'kw_unknown_variable\t%s\n' \
    "$(grep -c 'Unknown variable' "$OUT/driver_kw.log" 2>/dev/null | head -1)" >> "$SEAMS"
# THE OMNIBUS, WRITTEN DOWN. The crash fires only on the significant branch,
# so a leg whose fixture drifted into non-significance would pass every check
# below while testing the branch that never had the defect. The driver prints
# the p it computed into the Info window before the handover; it is carried
# out here so the validator can refuse a vacuous run rather than bless it.
printf 'kw_omnibus_p\t%s\n' \
    "$(sed -n 's/^SEAMS omnibus p=//p' "$OUT/report_kw.utf8.txt" 2>/dev/null | head -1)" >> "$SEAMS"
printf 'kw_artefacts\t%s\n' \
    "$(wc -l < "$OUT/ARTEFACTS_kw.tsv" 2>/dev/null)" >> "$SEAMS"
printf 'kw_tidy\t%s\n' \
    "$(grep -c '_tidy\.csv' "$OUT/ARTEFACTS_kw.tsv" 2>/dev/null | head -1)" >> "$SEAMS"

# --- leg B: the export ------------------------------------------------------
# ONE ANALYSIS, HOWEVER MANY DRAWS. The legacy results CSV is one row per
# (term, field) pair, so its length is a multiple of the block size and the
# multiple is the number of presses whose rows survived.
CSV=$(ls "$OUT"/home_scatter/*.csv 2>/dev/null | grep -v '_tidy\.csv$' \
      | grep -v '_glance\.csv$' | head -1)
if [[ -n "$CSV" ]]; then
    printf 'scatter_csv_name\t%s\n' "$(basename "$CSV")" >> "$SEAMS"
    printf 'scatter_csv_rows\t%s\n' "$(( $(wc -l < "$CSV") - 1 ))" >> "$SEAMS"
    # How many times the same (table, analysis, term, field) key appears. One
    # press writes each exactly once; N presses write each N times, and the
    # values are identical, which is why row count alone could be argued with
    # and this cannot. THE TABLE FIELD IS IN THE KEY because the per-group
    # reports carry "<table> -- <group>" there and are three different
    # analyses, not three copies of one -- a key without it counts a correct
    # grouped scatter as duplicated. Measured 15 Aug 2026: with the key right,
    # three presses of a grouped scatter gave 2, which was the legend-room
    # second pass reporting again, and is why the rewind exists.
    printf 'scatter_max_dupe\t%s\n' \
        "$(tail -n +2 "$CSV" | cut -d, -f1,2,3,5 | sort | uniq -c \
           | awk '{print $1}' | sort -rn | head -1)" >> "$SEAMS"
fi
printf 'scatter_draws\t%s\n' \
    "$(grep -c 'Redraw' "$OUT/DIALOGS_scatter.tsv" 2>/dev/null | head -1)" >> "$SEAMS"
printf 'scatter_adv_dialog_height\t%s\n' \
    "$(awk -F'\t' '$2 ~ /Column Mapping/ && $3 == "Draw" {print $5; exit}' \
       "$OUT/DIALOGS_scatter.tsv" 2>/dev/null)" >> "$SEAMS"
printf 'screen_height\t%s\n' \
    "$(DISPLAY="$DISP" xdpyinfo | sed -n 's/.*dimensions: *[0-9]*x\([0-9]*\).*/\1/p' | head -1)" >> "$SEAMS"

# --- leg D: the headless repro, WHICH THIS SCRIPT USED TO DELETE -------------
# repro_kw.praat drives the annotation bridge's nonparametric arm directly, no
# display, and writes out/repro_kw.info.txt beside the stdout and stderr
# captures. All three are committed evidence: they are the crash site read
# without an X server, which is what a reviewer on another machine has.
#
# It was driven BY HAND. Nothing in this file ran it -- while line 71 above
# deletes "$OUT"/*.txt on every run, which includes all three. So the harness
# wiped committed evidence it could not regenerate, and the copies in the tree
# survived only because nobody re-ran the rig in the same checkout. Found
# 17 Aug 2026 by validate/tools/redrive_census.sh, which scored them MISSING:
# a re-drive in a fresh copy produced no such files at all.
#
# The leg is here rather than the deletion being narrowed, because evidence a
# harness cannot rebuild is not evidence -- it is a file that used to be true.
# Headless, so it needs no display and cannot collide with :94 above.
(
    cd "$SCRIPT_DIR" && EML_KW_OUT="$OUT" \
        "$PRAAT" $PRAAT_TRUST --run repro_kw.praat
) > "$OUT/repro_kw.stdout.txt" 2> "$OUT/repro_kw.stderr.txt"
printf 'repro_kw_rc\t%s\n' "$?" >> "$SEAMS"
printf 'repro_kw_reached_end\t%s\n' \
    "$(grep -c 'REPRO_REACHED_END' "$OUT/repro_kw.stdout.txt" 2>/dev/null | head -1)" >> "$SEAMS"

# --- leg C: the legend file --------------------------------------------------
printf 'legend_files\t%s\n' \
    "$(grep -c '_legend\.png' "$OUT/ARTEFACTS_legend.tsv" 2>/dev/null | head -1)" >> "$SEAMS"
printf 'legend_pngs\t%s\n' \
    "$(grep -c '\.png' "$OUT/ARTEFACTS_legend.tsv" 2>/dev/null | head -1)" >> "$SEAMS"
printf 'legend_config_seed\t%s\n' \
    "$(tr '\n' ' ' < "$OUT/seeded_config_legend.txt" 2>/dev/null)" >> "$SEAMS"

echo
echo "seams recorded:"
sed 's/^/  /' "$SEAMS"
echo

fail=0
for leg in $LEGS; do
    if [[ ! -s "$OUT/DIALOGS_$leg.tsv" ]]; then
        echo "graphseams: FAIL — leg $leg raised no dialog. See out/driver_$leg.log."
        fail=$((fail + 1))
    fi
done
# AN UNDEFINED VARIABLE IS RECORDED, NOT SWALLOWED. It is reported here for a
# human reading the run, and it is the validator that decides whether it is a
# failure -- on the kwadv leg it is exactly the finding under test, and a
# harness that exited non-zero on its own evidence could not be used to
# demonstrate the break.
if grep -q "Unknown variable" "$OUT"/driver_*.log 2>/dev/null; then
    echo "graphseams: NOTE — a leg died on an undefined variable:"
    grep -h "Unknown variable" -A 2 "$OUT"/driver_*.log | sed 's/^/          /'
fi

if [[ $fail -eq 0 ]]; then
    echo "graphseams: PASS — four legs completed; evidence in out/SEAMS.tsv"
    echo "            (Praat $("$PRAAT" --version 2>&1 | head -1))"
else
    echo "graphseams: $fail failure(s). The validator reads out/ either way."
fi
exit 0
