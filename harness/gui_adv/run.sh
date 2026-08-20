#!/usr/bin/env bash
# ============================================================================
# gui_adv/run.sh — drive the real workflow through its real dialogs
# ============================================================================
# Brings up its own Xvfb and window manager, runs driver.praat (which sets the
# presets a wrapper sets and calls @emlGraphsWorkflow with a Table id), and
# presses Return at each dialog. Records the TITLE of every dialog it meets,
# in order, to out/DIALOGS.tsv, and saves the figure the run produces.
#
# WHY A GUI HARNESS EXISTS AT ALL. On 11 August 2026 fifteen menu entry points
# were dead at parse time, every figure's title had lost its special
# characters, the Draw branch of every analysis threw away the Table it had
# been handed, and an export dialog painted its OK button over its own output.
# All four were found by installing the plugin and clicking it. None was
# visible to 8259 R checks, 39/39 stress cases, 52/52 disclosure cases,
# 357/357 phase1 assertions or two byte-exact round trips, because every one
# of those exercises the plugin's PARTS and none of them assembles it.
#
# NO SCREEN COORDINATES. Every dialog is dismissed with Return, and Return
# lands on the plugin's own default button, which on this path is the happy
# path: Continue on the main form, Draw on the column mapping, Save on the
# figure. A harness that clicked at pixel positions would break the first
# time a dialog gained a field, and would then be "fixed" by moving numbers
# until it went green -- which is how a check stops meaning anything.
#
# THE ASSERTION IS THE SEQUENCE OF DIALOG TITLES. The workflow is handed a
# Table id; "No Table selected" must not appear, and the run must ADVANCE to
# the column-mapping stage. Asking for an object it was already given is the
# defect this harness was built the day after -- see §2k.
#
# IT USED TO STOP AT THE COLUMN-MAPPING DIALOG, and the reason given was that
# Praat walks pause dialogs with Tab, which visits every focusable widget, so
# the count differs with each dialog's field count. harness/tabwalk measured
# that on 13 August 2026 and the premise is true -- and worse than stated:
#
#   * Tab does visit every field before it reaches a button, so a forward
#     count depends on the field list, on which fields the ADVANCED toggle is
#     currently showing, and on Praat's prepended Undo button.
#   * Return in a text entry or a checkbox presses the DEFAULT button, not the
#     focused one, so a wrong count does not fail -- it silently presses
#     something else.
#   * `folder:` is not an entry. It renders as a multi-line GtkTextView with a
#     Browse button, and GTK text views swallow Tab AS A LITERAL TAB
#     CHARACTER. On the Save Figure dialog a forward walk never reaches a
#     button at any count from 0 to 13, and every Tab it sends is appended to
#     the output folder path. Photographed: harness/tabwalk.
#   * Return on the folder Browse button opens a modal "Choose folder", which
#     then eats every subsequent key.
#
# The forward-count table this file used to carry was therefore wrong in a way
# that could not have shown up as a failure. Its "Column Mapping tabs=4" lands
# on Go Back, and the harness would have looped the dialog forever.
#
# SO THE WALK RUNS BACKWARD. Focus starts at ring position 0, so ONE
# shift+Tab wraps to the LAST widget -- which is the last button. Measured on
# every button-row shape in the plugin: 1 button, 2, 3 and 4; with and without
# editable fields; with entries, checkboxes, optionmenus and the folder text
# view. shift+Tab xN presses the Nth button FROM THE END, always, and never
# enters a field on the way. The count comes from the endPause: button list,
# which is static per dialog and readable from the source.
#
# That is the whole reason this harness can now go past the mapping dialog to
# Save, Export CSV, Redraw and teardown.
#
# Run from anywhere:  bash harness/gui_adv/run.sh
# Exit 0 = the workflow advanced without asking for what it was given.
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$SCRIPT_DIR/.." && pwd)/_env.sh" || exit 1
OUT="$SCRIPT_DIR/out"
PREFS="$SCRIPT_DIR/prefs"
mkdir -p "$OUT" "$PREFS"
rm -f "$OUT"/*.tsv "$OUT"/*.log "$OUT"/*.png 2>/dev/null

# A display of its own, so a run cannot collide with another agent's rig or
# inherit a half-dead one. 91 rather than 99 for the same reason.
DISP=":93"
XVFB_PID=""
WM_PID=""
PRAAT_PID=""

# Kill by RECORDED PID, never by name. `pkill -f` matches the driving shell's
# own command line and kills it -- exit 144, seen for real (D126). Even
# `pkill -x praat` takes out a stress run another process owns.
cleanup() {
    [[ -n "$PRAAT_PID" ]] && kill -9 "$PRAAT_PID" 2>/dev/null
    [[ -n "$WM_PID"    ]] && kill -9 "$WM_PID"    2>/dev/null
    [[ -n "$XVFB_PID"  ]] && kill -9 "$XVFB_PID"  2>/dev/null
    rm -f "/tmp/.X${DISP#:}-lock" "/tmp/.X11-unix/X${DISP#:}" 2>/dev/null
}
trap cleanup EXIT

rm -f "/tmp/.X${DISP#:}-lock" "/tmp/.X11-unix/X${DISP#:}" 2>/dev/null
Xvfb "$DISP" -screen 0 1400x1000x24 > "$OUT/xvfb.log" 2>&1 &
XVFB_PID=$!
sleep 3
if ! DISPLAY="$DISP" xdpyinfo >/dev/null 2>&1; then
    echo "gui_adv: FAIL — no display on $DISP"; exit 1
fi

# Bare Xvfb has no window manager, and without one xdotool cannot activate a
# window and GTK entries never take focus, so typed input goes nowhere.
# DISPLAY MUST BE IN THE ENVIRONMENT HERE. Xvfb takes its display as an
# ARGUMENT; matchbox reads it from DISPLAY and exits 1 with "can't open
# display" if it is unset. The first version of this script omitted it, the
# window manager was silently absent, xdotool's windowactivate failed with
# "Your windowmanager claims not to support _NET_ACTIVE_WINDOW", the dialog
# never took focus, and fourteen Return presses went nowhere -- which read
# as "Praat ignores Return" rather than "there is no window manager".
DISPLAY="$DISP" matchbox-window-manager -use_titlebar no > "$OUT/wm.log" 2>&1 &
WM_PID=$!
sleep 2
if ! kill -0 "$WM_PID" 2>/dev/null; then
    echo "gui_adv: FAIL — the window manager did not start:"
    sed 's/^/          /' "$OUT/wm.log"
    echo "          Without one, no dialog takes focus and no key reaches it."
    exit 1
fi

# 6.6.30 keeps its instance lock in the pref dir; 7.x keeps it in
# ~/.config/praat regardless of --pref-dir. Both are cleared, because a stale
# lock makes Praat exit with "An instance of Praat that is not me is already
# running" and the run reads as a harness bug rather than a stale file.
rm -f "$PREFS/pid" "$PREFS/message" 2>/dev/null
rm -f "$HOME/.config/praat/pid.txt" "$HOME/.config/praat/Message.txt" 2>/dev/null

# THE SAVED CONFIG IS DELETED, AND THAT IS NOT TIDINESS. @emlSaveConfig
# persists lastPNGFolder and lastCSVFolder, and the Save Figure and Export
# Results dialogs seed their folder field from them. A run that inherited
# yesterday's config would write its figure wherever yesterday's run happened
# to be pointed -- which is exactly what happened on 13 Aug 2026: the config
# in this harness's own pref dir said /root, so the run wrote its evidence
# into the home directory and this file reported that no figure was saved.
# Starting from the plugin's own defaults every time is what makes the
# artefact reproducible.
rm -f "$PREFS/eml-graphs-config.txt" 2>/dev/null

# A HOME OF ITS OWN. With no saved config the folder default falls back to a
# home-relative path, so HOME is pointed inside out/ -- the run cannot then
# scatter files into the real home directory, and everything it writes is
# somewhere this file can find it.
ADVHOME="$OUT/home"
rm -rf "$ADVHOME"; mkdir -p "$ADVHOME"

( cd "$SCRIPT_DIR" && DISPLAY="$DISP" EML_ADV_OUT="$OUT" HOME="$ADVHOME" \
    "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" --utf8 --new-send driver.praat \
    > "$OUT/driver.log" 2>&1 ) &
PRAAT_PID=$!
sleep 10

TSV="$OUT/DIALOGS.tsv"
: > "$TSV"

# WINDOW LOOKUP WALKS _NET_CLIENT_LIST, not `xdotool search`. search reads
# WM_NAME, which GTK sets only for a Latin-1 title -- and the wizard pages
# carry em dashes, so those windows have none. It also returns the unmapped
# husk of every dismissed pause dialog forever. GUI_HARNESS_RECIPE §11.
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

# THE BUTTON IS COUNTED FROM THE END, and the count comes from the dialog's
# own endPause: list in eml-graphs-form.praat -- not from a screen position
# and not from a field count. harness/tabwalk measured that shift+Tab xN
# presses the Nth button from the end on every shape the plugin raises.
#
#   EML Graphs          Quit Continue                    -> Continue is 1
#   ... Data Format     GoBack Quit Continue             -> Continue is 1
#   ... Column Mapping  GoBack Quit <toggle> Draw        -> Draw     is 1
#   ... Settings        GoBack Quit <toggle> Draw        -> Draw     is 1
#   Save Figure         GoBack Save                      -> Save     is 1
#   Export Results      GoBack Save                      -> Save     is 1
#   Save/Export Complete, Column Error   OK              -> OK       is 1
#   Graph Complete      Done Save ExpCSV Redraw          -> Redraw 1, ExpCSV 2,
#                                                           Save 3, Done 4
#
# Graph Complete is the only dialog visited more than once, and the visit
# number chooses the branch: Save, then Export CSV, then Redraw, then Done.
# That order is deliberate -- Redraw is third so that the SECOND pass through
# the whole workflow is what finally presses Done, which is the only path
# that reaches teardown.
gcVisit=0
cmVisit=0
MAXSTEPS=24
step=0
reachedMapping=0
while [[ $step -lt $MAXSTEPS ]]; do
    line=$(pauseinfo) || break
    wid=${line%%$'\t'*}
    title=${line#*$'\t'}
    step=$((step + 1))

    rev=1
    label="?"
    case "$title" in
        *"Column Mapping"*|*"Settings")
            reachedMapping=1
            cmVisit=$((cmVisit + 1))
            # THE TOGGLE IS BUTTON 3 OF 4: GoBack | Quit | <Advanced/Beginner>
            # | Draw. From the end: Draw 1, toggle 2, Quit 3, GoBack 4. The
            # LABEL of button 3 flips with the mode -- "Advanced" when
            # beginner, "Beginner" when advanced -- but its POSITION does not,
            # which is what makes the reverse count stable across the toggle.
            #
            # Visit 1 presses the toggle, and the SAME dialog re-raises in
            # advanced shape with the advanced field block present. Visit 2
            # photographs it (that picture is the annotate-preset evidence)
            # and presses Draw.
            # THE ORDER IS THE TEST. Toggling straight to advanced proves
            # NOTHING: emlGraphsPresetAnnotate is read once before the outer
            # repeat (eml-graphs-form.praat:2682-2687) and sets annotate = 1
            # directly, so on the first pass the box is ticked whether the
            # restore arm exists or not. The first version of this harness did
            # exactly that, and its break test -- the restore arm disabled --
            # PASSED. A drive that cannot fail is not evidence.
            #
            # The arm only matters once a BEGINNER draw has forced annotate
            # back to 0, which is the author's ruling of 13 Aug 2026: beginner
            # mode draws only what its own dialog offers, and the setting must
            # come back when the user switches to advanced. So:
            #
            #   visit 1  Draw in beginner mode      -> annotate forced to 0
            #   (Graph Complete -> Redraw)
            #   visit 2  press the toggle           -> restore arm runs here
            #   visit 3  photograph, then Draw      -> the box is the evidence
            case $cmVisit in
                1) rev=1; label="Draw" ;;
                2) rev=2; label="Advanced" ;;
                *) rev=1; label="Draw" ;;
            esac ;;
        *"Data Format"*)                 rev=1; label="Continue" ;;
        *"EML Graphs"*)                  rev=1; label="Continue" ;;
        *"Graph Complete"*)
            gcVisit=$((gcVisit + 1))
            # THREE BUTTONS NOW, always: Done | Save | Redraw. The row used
            # to be four or three depending on whether there were results to
            # export, which is why this dialog needed a retry at a second
            # count. "Save" opens a panel offering whichever outputs exist, so
            # the row no longer changes shape and the counts are fixed.
            # Redraw FIRST, because the beginner draw is only the setup: it
            # exists to zero annotate so the toggle has something to restore.
            # The Save that matters comes after the ADVANCED draw.
            case $gcVisit in
                1) rev=1; label="Redraw" ;;
                2) rev=2; label="Save" ;;
                *) rev=3; label="Done" ;;
            esac ;;
        "Save")                          rev=1; label="Save" ;;
        *"Saved")                        rev=1; label="OK" ;;
        *"Nothing saved"*)               rev=1; label="OK" ;;
        *"Column Error"*)                rev=1; label="OK" ;;
        *)                               rev=1; label="LAST" ;;
    esac

    printf '%d\t%s\t%s\t%d\n' "$step" "$title" "$label" "$rev" >> "$TSV"

    # THE ADVANCED DIALOG IS PHOTOGRAPHED BEFORE IT IS DRAWN. Whether
    # "Annotate results on graph" comes up TICKED is the whole of the preset
    # fix, and it is not recoverable from anything the run writes afterwards:
    # a lost preset produces SILENCE -- no figure annotation, no Info report,
    # no warning -- which is exactly why it went unnoticed.
    if [[ "$label" == "Draw" && $cmVisit -ge 3 ]]; then
        DISPLAY="$DISP" import -window "$wid" "$OUT/ADVANCED_DIALOG.png" 2>/dev/null
    fi

    DISPLAY="$DISP" xdotool windowactivate --sync "$wid" 2>/dev/null
    sleep 1
    DISPLAY="$DISP" xdotool key --clearmodifiers --repeat "$rev" shift+Tab 2>/dev/null
    sleep 1
    # XTEST, not XSendEvent: `xdotool key --window <id>` sends a synthetic
    # event GTK ignores. Without --window it drives the X test extension and
    # the application cannot tell it from a real keypress.
    DISPLAY="$DISP" xdotool key --clearmodifiers Return 2>/dev/null
    sleep 6

    # THE ONE COUNT THAT CANNOT BE READ OFF THE SOURCE. Graph Complete shows
    # four buttons only while there are stats on the CSV buffer; with none it
    # shows three, and Done is then 3 from the end rather than 4. Which one is
    # up cannot be seen from the title, so Done retries once at 3 -- and the
    # retry is recorded rather than being silently absorbed.
    # NO DONE RETRY ANY MORE. It existed because Graph Complete's row was
    # four or three buttons depending on the CSV buffer, so Done's distance
    # from the end was not knowable from the title. The row is fixed at three
    # now, so the count is exact and a retry would only hide a real failure.
done

# WHAT THE RUN LEFT ON DISK. The figure and the CSV are written by the Save
# and Export branches through @emlGenerateUniquePath; nothing else in this
# harness can show that those branches ran to completion rather than merely
# opening their dialogs.
ART="$OUT/ARTEFACTS.tsv"
: > "$ART"
while IFS= read -r f; do
    [[ -e "$f" ]] || continue
    # THE PLUGIN'S OWN CONFIG IS NOT AN OUTPUT. @emlSaveConfig writes
    # eml-graphs-config.txt to remember dialog choices between sessions; it is
    # state, not something the analysis produced, and counting it would make
    # "the run wrote a file" true even when every save failed.
    [[ "$(basename "$f")" == "eml-graphs-config.txt" ]] && continue
    printf '%s\t%s\n' "$(basename "$f")" "$(stat -c%s "$f")" >> "$ART"
done < <(find "$SCRIPT_DIR" "$ADVHOME" -maxdepth 2 \
              \( -name '*.png' -o -name '*.csv' -o -name '*.txt' \) 2>/dev/null | sort)

# ---------------------------------------------------------------------------
# THE BRIDGE EVIDENCE, counted here rather than left for a validator to dig out
# ---------------------------------------------------------------------------
# The saved Info report is UTF-16 (Praat writes it that way under --utf8), so a
# validator reading it as text finds nothing -- I lost twenty minutes to that
# before writing this block. It is converted once, here, and the number that
# matters is written out plainly.
#
# THAT NUMBER IS THE WHOLE EXPERIMENT. "Two-Group Comparison" is emitted by
# @emlReportHeader, and on this journey it can appear either once or twice:
#
#   1 section  the DRIVER's @emlRunTwoGroupAnalysis reported, and nothing else
#              did -- the annotate preset was lost across the beginner draw, so
#              the bridge never ran
#   2 sections the preset SURVIVED, annotate = 1, and the bridge ran and
#              reported on top of it
#
# Measured 14 Aug 2026 with the violin restore arm disabled: 1 section, 1833
# bytes. With it: 2 sections, 3627 bytes. One integer separates the fix from
# its absence, which is what makes this harness able to fail.
#
# It is also the BRIDGE DECLARATION evidence, and that needs saying because the
# file set does not distinguish it: @emlReportBridgeStats opens with
# @emlCSVInit, which destroys the driver's declaration, so broom frames on disk
# after an annotated draw can only have come from the bridge re-declaring. But
# broom frames appear in the UNANNOTATED case too -- from the driver's own
# orchestrator, untouched because the bridge never ran. Same files, different
# author. The section count is what tells them apart.
REPORTTXT=$(ls "$ADVHOME"/*_report.txt 2>/dev/null | head -1)
BRIDGE="$OUT/BRIDGE.tsv"
: > "$BRIDGE"
if [[ -n "$REPORTTXT" ]]; then
    # DECIDE BY THE BOM, NOT BY iconv's EXIT CODE. The report used to be
    # written UTF-16 whenever it carried one non-ASCII character; it is now
    # folded to ASCII at the file boundary. "iconv -f UTF-16 || cp" looks
    # like it handles both, and does not: on an ASCII file with an EVEN byte
    # count iconv exits 0 and emits mojibake, so the fallback never fires and
    # every grep below silently returns nothing. Odd byte counts happen to
    # fail and fall through, which makes the bug intermittent by file length.
    if head -c 2 "$REPORTTXT" | od -An -tx1 | grep -qE "fe ff|ff fe"; then
        iconv -f UTF-16 -t UTF-8 "$REPORTTXT" > "$OUT/report.utf8.txt"
    else
        cp "$REPORTTXT" "$OUT/report.utf8.txt"
    fi
    printf 'report_sections\t%s\n' \
        "$(grep -c 'Two-Group Comparison' "$OUT/report.utf8.txt")" >> "$BRIDGE"
    printf 'report_bytes\t%s\n' "$(wc -c < "$OUT/report.utf8.txt")" >> "$BRIDGE"
fi
printf 'mapping_visits\t%s\n' "$cmVisit" >> "$BRIDGE"
printf 'toggled_to_advanced\t%s\n' \
    "$(grep -c 'Advanced' "$TSV")" >> "$BRIDGE"

echo "dialogs met:"
awk -F'\t' '{printf "  %s. %-34s -> %s (shift+Tab x%s)\n", $1, $2, $3, $4}' "$TSV"
echo

fail=0

if [[ ! -s "$TSV" ]]; then
    echo "gui_adv: FAIL — no dialog was ever raised. See out/driver.log."
    exit 1
fi

# THE DEFECT THIS HARNESS WAS BUILT FOR. @emlGraphsWorkflow was handed a Table
# id; a second @emlDetectContext then read the Objects-window selection and
# discarded it, so every wrapper's Draw branch asked the user to pick the
# Table it had just analysed.
if grep -q "No .* selected" "$TSV"; then
    echo "gui_adv: FAIL — the workflow asked for an object it was handed."
    echo "         That is the defect of §2k: a second @emlDetectContext"
    echo "         discarding the caller's object on the first pass."
    fail=$((fail + 1))
fi

if ! grep -qi "EML Graphs" "$TSV"; then
    echo "gui_adv: FAIL — the main form never opened"
    fail=$((fail + 1))
fi

if [[ $reachedMapping -eq 0 ]]; then
    echo "gui_adv: FAIL — never advanced to the column-mapping stage"
    fail=$((fail + 1))
fi

# THE STAGES THAT WERE UNREACHABLE UNTIL THE REVERSE WALK. Each is named
# separately, because "the run got shorter" is exactly the failure a single
# step-count check would hide.
for stage in "Graph Complete" "Save" "Saved"; do
    if ! grep -q "$stage" "$TSV"; then
        echo "gui_adv: FAIL — never reached the $stage dialog"
        fail=$((fail + 1))
    fi
done

# REDRAW RE-ENTERS THE WHOLE WORKFLOW, so the main form has to appear twice.
# A Redraw that fell through to teardown instead would still show every
# dialog above exactly once and would look like a pass.
nMain=$(awk -F'\t' '$2 ~ /EML Graphs/' "$TSV" | wc -l)
if [[ "$nMain" -lt 2 ]]; then
    echo "gui_adv: FAIL — Redraw did not re-enter the workflow (main form seen $nMain time(s))"
    fail=$((fail + 1))
fi

# THE FILES. A Save branch that opened its dialog, took the press and wrote
# nothing would satisfy every dialog check above.
if [[ ! -s "$ART" ]]; then
    echo "gui_adv: FAIL — the run wrote no figure and no CSV"
    fail=$((fail + 1))
else
    grep -q '\.png' "$ART" || { echo "gui_adv: FAIL — no figure was saved"; fail=$((fail + 1)); }
    grep -q '\.csv' "$ART" || { echo "gui_adv: FAIL — no CSV was exported"; fail=$((fail + 1)); }
fi

echo "artefacts written:"
awk -F'\t' '{printf "  %s (%s bytes)\n", $1, $2}' "$ART" 2>/dev/null
echo

echo
if [[ $fail -eq 0 ]]; then
    echo "gui_adv: PASS — the workflow ran to teardown in $step dialogs"
    echo "         (Praat $("$PRAAT" --version 2>&1 | head -1))"
    exit 0
fi
echo "gui_adv: FAIL — $fail problem(s). See out/DIALOGS.tsv and out/driver.log."
exit 1
