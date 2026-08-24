#!/usr/bin/env bash
# ============================================================================
# harness/linetree/run.sh — the line chart's question tree, driven through its
# own dialogs
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# THE SUBJECT. The line chart no longer asks how a file is stored; it asks
# what the columns MEAN, and everything else follows from the answer. Which
# page appears next, how many tickboxes it carries, whether it offers an
# interval, whether a right-hand axis is reachable at all, and which of the
# two refusals fires -- all of that is a consequence of one optionmenu and of
# what the plugin found when it looked at the table. None of it is a value a
# procedure returns, so none of it can be tested by calling a procedure.
#
# EVERY LEG BELOW IS THE SHIPPED FORM'S OWN DIALOGS. drive.praat builds a
# table, names the graph type and calls @emlGraphsWorkflow; this file supplies
# keystrokes and photographs what came up. A leg that passed with the dialogs
# deleted would be measuring the harness.
#
# WHAT IS RECORDED, per leg, so that a validator never has to re-run Praat:
#   * the dialog TITLES in the order the form showed them, beside the title
#     the plan expected -- a divergence is visible rather than fatal
#   * the OCR TEXT of every dialog, off the pixels it displayed
#   * the Info window verbatim (the disclosures are text; they are not
#     transcribed from a screenshot)
#   * the figure's PNG, its md5 and its size
#   * the colour census of the figure -- how many distinct chromatic colours,
#     and how much ink in each horizontal band (palette.py)
#   * the form's own variables after the dispatch, written by drive.praat
#
# Run from anywhere:  bash harness/linetree/run.sh [leg ...]
# Output: harness/linetree/out/LINETREE.tsv     case, key, value
#         harness/linetree/out/<leg>_s<n>.png   every dialog, as shown
#         harness/linetree/out/<leg>.png        the figure
#         harness/linetree/out/<leg>_info.txt   the Info window
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
#            https://github.com/embodied-music-lab/PraatGen
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$SCRIPT_DIR/.." && pwd)/_env.sh" || exit 1

SRC="${EML_LT_SRC:-$EML_ROOT}"
OUT="${EML_LT_OUTDIR:-$SCRIPT_DIR/out}"
DRIVE="$SRC/harness/linetree/drive.praat"
SCRIPTLEG="$SRC/harness/linetree/script_refuse.praat"
# DISPLAY :120 AND UP ARE FREE ON THIS IMAGE. A driver that shared :99 with
# whatever else is running would read another run's Picture window as its own
# and photograph another run's dialogs.
DISP="${EML_LT_DISPLAY:-:120}"

mkdir -p "$OUT"
TSV="$OUT/LINETREE.tsv"
# BUILT BESIDE ITSELF AND MOVED INTO PLACE, for the reason
# harness/linestyle/run.sh's header records: a reader must never see a
# half-written artefact, and a run must never leave the previous run's rows
# underneath its own.
TMP="$OUT/.LINETREE.$$.tsv"
: > "$TMP"

emitted=0
emit () { printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$TMP"; emitted=$((emitted + 1)); }

LEGS="${*:-subjects4 timeswitch subjects_ci meas2 meas2_rep meas3_refuse none_refuse seven script_refuse long_meas2 long_meas3_refuse long_titled wide_titled rec_subjects4 rec_meas2 rec_long_meas2}"

emit "--run--" praat_version "$("$PRAAT" --version 2>&1 | head -1)"
emit "--run--" source_tree "$SRC"
# THE MACHINE IS PART OF THE EVIDENCE. Every figure comparison below is a
# pixel comparison, and a pixel comparison is a property of the container that
# took it as much as of the plugin: legend widths and glyph metrics move a
# pixel or three between machines for reasons no commit causes. Recording the
# host means a re-drive somewhere else declares itself as a re-baseline rather
# than reading as a regression, and spares the next reader a bisect over a
# cross-machine pixel delta.
emit "--run--" host "$(hostname 2>/dev/null || uname -n)"
emit "--run--" legs_requested "$LEGS"

# ---------------------------------------------------------------------------
# THE STALENESS BINDING. The digest of the two files the tree lives in, code
# only -- comment lines dropped in Praat's comment set -- as they were when
# these legs were driven. A validator recomputes it and refuses a transcript
# taken from a different form, so a rewritten dialog cannot be validated by
# yesterday's screenshots. Comments are dropped so rewrapping a paragraph does
# not demand a GUI re-drive.
# ---------------------------------------------------------------------------
# stats/eml-record.praat IS IN THE LIST BECAUSE THE RECORDER LEGS REPLAY WHAT
# IT WROTE. The two rec_ legs' claim is that a file this source emitted draws
# the same figure again, byte for byte; a transcript carrying that claim beside
# a recorder it was not taken from is exactly the staleness the other three
# digests exist to refuse.
for f in graphs/eml-graphs-form.praat graphs/eml-graph-procedures.praat \
         graphs/eml-draw-procedures.praat stats/eml-record.praat; do
    emit "--run--" "code_sha256_$(basename "$f" .praat)" \
        "$(sed -E '/^[[:space:]]*(#|;|!)/d' "$SRC/plugin_EML_StatsGraphs/$f" \
           | sha256sum | cut -d' ' -f1)"
done

# ---------------------------------------------------------------------------
# DISPLAY, WINDOW MANAGER, COMPOSITOR.
#
# Killed by RECORDED PID and never by name. `pkill -f` matches the driving
# shell's own command line and kills the run with exit 144 (D126), and even
# `pkill -x praat` takes out a Praat some other harness on this machine owns.
#
# THE COMPOSITOR IS NOT OPTIONAL FOR THE INK MEASURE. Without one, the region
# a dialog covers is not repainted and comes back from XGetImage as a black
# rectangle -- which reads as a figure. xcompmgr redirects each window to its
# own pixmap, so the Picture window's own content is what is captured whatever
# is on top of it.
# ---------------------------------------------------------------------------
XVFB_PID=""; WM_PID=""; XC_PID=""; PRAAT_PID=""
cleanup () {
    [[ -n "$PRAAT_PID" ]] && kill -9 "$PRAAT_PID" 2>/dev/null
    [[ -n "$XC_PID"    ]] && kill -9 "$XC_PID"    2>/dev/null
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
    echo "linetree: FAIL — no display on $DISP"; exit 1
fi
DISPLAY="$DISP" matchbox-window-manager -use_titlebar no > "$OUT/wm.log" 2>&1 &
WM_PID=$!
sleep 2
if ! kill -0 "$WM_PID" 2>/dev/null; then
    echo "linetree: FAIL — the window manager did not start:"
    sed 's/^/          /' "$OUT/wm.log"; exit 1
fi
DISPLAY="$DISP" xcompmgr > "$OUT/xc.log" 2>&1 &
XC_PID=$!
sleep 2
emit "--run--" compositor \
    "$(kill -0 "$XC_PID" 2>/dev/null && echo running || echo absent)"

# ---------------------------------------------------------------------------
# WINDOW LOOKUP WALKS _NET_CLIENT_LIST, not `xdotool search`, which matches
# WM_NAME -- unset for any non-Latin-1 title, and every wizard page title in
# this plugin carries an em dash -- and which returns the unmapped husk of
# every dismissed pause dialog forever. GUI_HARNESS_RECIPE §11.
# ---------------------------------------------------------------------------
winlist () {
    DISPLAY="$DISP" xprop -root _NET_CLIENT_LIST 2>/dev/null \
        | sed -n 's/.*# //p' | tr -d ' ' | tr ',' '\n'
}
pausewin_not () {
    # A pause window whose id is NOT the one just dismissed.
    #
    # WHY BY ID AND NOT BY TITLE. harness/axisrefuse waits for a title that
    # differs from the last one, which works there because no two consecutive
    # dialogs share a title. This tree re-presents "Line Chart -- Column
    # Mapping" after the composition refusal and again after each Advanced
    # toggle, so a title comparison would hand back the dialog that is on its
    # way out and every later step would type into a dead window. Praat builds
    # a NEW window per pause and _NET_CLIENT_LIST drops the withdrawn one, so
    # the id is the honest test.
    local id name
    for id in $(winlist); do
        [[ "$id" == 0x* ]] || continue
        [[ "$id" == "$1" ]] && continue
        name=$(DISPLAY="$DISP" xdotool getwindowname "$id" 2>/dev/null)
        if [[ "$name" == Pause:* ]]; then
            printf '%s\t%s\n' "$id" "${name#Pause: }"; return 0
        fi
    done
    return 1
}
namedwin () {
    local id name
    for id in $(winlist); do
        [[ "$id" == 0x* ]] || continue
        name=$(DISPLAY="$DISP" xdotool getwindowname "$id" 2>/dev/null)
        [[ "$name" == "$1" ]] && { printf '%s\n' "$id"; return 0; }
    done
    return 1
}
waitpause () {
    local prev="$1" i line
    for ((i = 0; i < 60; i++)); do
        line=$(pausewin_not "$prev") && { printf '%s\n' "$line"; return 0; }
        sleep 0.5
    done
    return 1
}

# THE INK MEASURE. Fraction of pixels below mid-grey in the Picture window.
ink () {
    local w
    w=$(namedwin "Praat Picture") || { echo "NA"; return; }
    DISPLAY="$DISP" import -window "$w" "$OUT/_ink.png" 2>/dev/null || {
        echo "NA"; return; }
    convert "$OUT/_ink.png" -colorspace gray -threshold 50% \
        -format "%[fx:1-mean]" info: 2>/dev/null || echo "NA"
}

# THE TEXT A DIALOG ACTUALLY DISPLAYED, read off the pixels it displayed it
# in. Upscaled and greyed before tesseract because a 12 px GTK label at 1:1 is
# below the recogniser's comfortable size; --psm 6 treats the crop as a
# uniform block of text, which is what a column of comment labels is.
dialog_text () {
    local wid="$1" tag="$2"
    DISPLAY="$DISP" import -window "$wid" "$OUT/${tag}.png" 2>/dev/null || return 1
    convert "$OUT/${tag}.png" -colorspace gray -resize 300% -sharpen 0x1 \
        "$OUT/_ocr.png" 2>/dev/null || return 1
    tesseract "$OUT/_ocr.png" stdout --psm 6 2>/dev/null \
        | tr -s ' ' | sed 's/[[:space:]]*$//' | grep -v '^$'
}

# ---------------------------------------------------------------------------
# THE PLANS.
#
# A plan is a list of steps, one per dialog, in the order the form shows them:
#
#     <expected title>|<action>,<action>,...
#
#     ocr             record the text this dialog is displaying
#     ink             record the Picture window's dark fraction
#     opt<N>=<k>      widget N is an optionmenu: select option k ABSOLUTELY.
#                     Home then k-1 Down. Measured on this image, Praat
#                     6.6.30 + matchbox: a focused Praat optionmenu takes
#                     Home/End/Up/Down directly, no popup and no mouse.
#                     Absolute rather than relative because the seeded default
#                     is @emlGuessColumnRoles' guess and a plan written
#                     against a guess is a plan that breaks when the guesser
#                     improves.
#     tog<N>          widget N is a boolean: press space
#     tab<N>=<text>   widget N is a text field: select all, type
#     btn<N>          press the Nth button FROM THE END: focus starts at ring
#                     position 0, so N shift+Tabs reach it without entering a
#                     field on the way (harness/tabwalk measured this law)
#
# The expected title is written down so a divergence is visible in the
# transcript; the harness records the title it ACTUALLY met and executes the
# step's actions regardless, so a form that shows the wrong dialog produces a
# wrong transcript rather than a hung run.
#
# WIDGET ORDER ON "Line Chart -- Column Mapping" is built from the table, so
# it differs per leg. Read off eml-graphs-form.praat and restated per plan:
#   shape 1 (n numeric columns beside time, no repeats), role measurements:
#       0 Time column, 1..n Series k, n+1 Line style
#   shape 1, role SUBJECTS, in beginner mode -- one extra field:
#       0 Time column, 1..n Series k, n+1 Y axis label, n+2 Line style
#       Several columns of one measurement name the SUBJECTS, so nothing in
#       the table names the quantity they share and the beginner page has to
#       ask. It is inserted AFTER the tickboxes and BEFORE Line style, so no
#       plan step in this file moved: every opt/tog below addresses a widget
#       at or before the last tickbox, and btnN counts from the END of the
#       ring, which a field in the middle does not shift. Measured rather
#       than assumed -- subjects4, seven and none_refuse were re-driven with
#       the indices unchanged and every dialog matched its planned title.
#   shape 2 (one numeric, one or more text), repeats found, role subjects:
#       0 Time column, 1 Series names come from, 2 Group order,
#       3 Draw the mean and its interval, 4 Line style
#   shape 2, NO repeats, role MEASUREMENTS -- the long-format right-hand axis:
#       0 Time column, 1 Series names come from, 2 Group order, 3 Line style
#       The interval field is absent twice over: this table has one row per
#       (time, level), and intervals are not offered across two scales
#       whatever the storage. So the page is the shape-2 page minus that one
#       field, and every step below addresses widget 0 or 1.
#       No Y axis label here: one numeric column HAS a name in the table, so
#       the axis label composes itself from it.
#
# AND THE THIRTEEN-PAGE GROUPING SWEEP (c74d432) DID NOT REACH ANY OF THEM.
# The line chart's own pages take the grouping in their own file set as a
# later commit, so the sweep's only mark on this walk's line-chart region is
# one added comment row -- the no-erase legend advice beside "Legend
# placement" on the column page. A comment takes no Tab stop. Measured, not
# assumed: the focusable widgets and the endPause button rows of all five
# line-chart pages -- "What the lines are", "Column Mapping", "Time column
# changed", the "Line chart" refusal and "The Right-Hand Axis" -- are
# byte-identical across c74d432, so every opt/tog/btn step below stands as
# written. The one shared page this walk crosses on its way in, "EML Graphs",
# WAS swept; see the long_titled leg for why its tab1 did not move.
#
# BUTTON ROWS:
#   EML Graphs (main)              Quit / Continue          -> Continue = btn1
#   Line Chart -- What the lines are
#                                  Go Back / Quit / Continue-> Continue = btn1
#   Line Chart -- Column Mapping   Go Back / Quit / Advanced|Beginner / Draw
#                                                           -> Draw = btn1,
#                                                              toggle = btn2
#   Line Chart -- The Right-Hand Axis
#                                  Go Back / Draw           -> Draw = btn1
#   Line chart (refusal)           OK                       -> OK = btn1
#   Graph Complete                 Done / Save / Redraw     -> Done = btn3
# ---------------------------------------------------------------------------
plan_of () {
case "$1" in
  # LEG 1 -- subjects, no repeats. Four columns that are one measurement on
  # four singers: four series, one shared y-axis, a key. And the ABSENT arm of
  # the replication fork -- this table has one row per time, so the interval
  # field must not be on the page at all. The OCR of step 3 is the evidence.
  subjects4) cat <<'PLAN'
EML Graphs|ocr,btn1
Line Chart -- What the lines are|ocr,opt0=1,btn1
Line Chart -- Column Mapping|ocr,btn1
Graph Complete|ink,ocr,btn3
PLAN
  ;;
  # LEG 1b -- THE TIME COLUMN IS MOVED ON THE PAGE THAT ASKS FOR IT.
  #
  # Every other control on the column-mapping page is worked out BEFORE the
  # page opens, from the time column it opens with -- how many tickboxes there
  # are and which columns they name, whether the interval field exists, and
  # the observation count printed inside its label. Praat cannot recompose a
  # page in response to a menu on that same page, so choosing a different time
  # column and pressing Draw used to draw a figure whose page had been
  # describing a different question.
  #
  # THE WALK: open the mapping page, set the Time column menu to its second
  # entry (opt0=2), press Draw (btn1). The page must NOT draw. A one-button
  # box has to appear naming both columns, and behind it the mapping page has
  # to come back -- rebuilt, this time against the column just chosen -- with
  # the tick the user did not touch still ticked. Draw from there.
  #
  # WHAT MAKES IT EVIDENCE AND NOT A CLICK-THROUGH: step 4's title is asserted
  # by name, so a build with no guard cannot satisfy the plan -- it goes
  # straight to "Graph Complete" and the walk fails on a window that never
  # appeared. And the second visit to "Line Chart -- Column Mapping" is
  # OCR'd, so the tickbox list it comes back with is read off the photograph
  # rather than assumed.
  timeswitch) cat <<'PLAN'
EML Graphs|ocr,btn1
Line Chart -- What the lines are|ocr,opt0=1,btn1
Line Chart -- Column Mapping|ocr,opt0=2,btn1
Time column changed|ocr,btn1
Line Chart -- Column Mapping|ocr,btn1
Graph Complete|ink,ocr,btn3
PLAN
  ;;
  # LEG 2 -- subjects WITH repeats, offered and accepted. One value column and
  # a speaker column carrying four observations at every (time, speaker).
  #
  # opt1=2 IS THE SECOND ENTRY OF A MENU THAT NOW HOLDS TWO. "Series names
  # come from" is built over the TEXT columns the survey found, with
  # "(none -- one series)" in front of them, so on time/f0/speaker the whole
  # menu is [(none), speaker] and the speaker column is entry 2. It used to be
  # built over EVERY column -- [(none), time, f0, speaker] -- where the same
  # answer was entry 4, and where the seeded default was
  # @emlGuessColumnRoles' guess, which on this table was TIME. The step still
  # selects the speaker column ABSOLUTELY (Home, then k-1 Down) rather than
  # accepting the default, because the subject of this leg is that the user's
  # choice reaches the repeat scan -- not that the default happens to be right.
  #
  # THE ADVANCED TOGGLE IS STILL PRESSED TWICE, and what it measures has
  # changed with the menu. It used to catch the count MOVING -- eight on the
  # page the guesser seeded, four once the speaker column was chosen. The page
  # now opens on the first text column, so the scan is keyed on (time, speaker)
  # from the first presentation and the label says four on all three. What the
  # two round trips pin is that the count does not DRIFT across a
  # re-presentation, and that leaving the column page and coming back does not
  # lose the grouping: three photographs of the same label, all four.
  subjects_ci) cat <<'PLAN'
EML Graphs|ocr,btn1
Line Chart -- What the lines are|ocr,opt0=1,btn1
Line Chart -- Column Mapping|ocr,opt1=2,btn2
Line Chart -- Column Mapping|ocr,btn2
Line Chart -- Column Mapping|ocr,tog3,btn1
Graph Complete|ink,ocr,btn3
PLAN
  ;;
  # LEG 3 -- two unlike measurements. Hertz and a fraction: the right-hand
  # axis page is reached, and only from here. The key must carry
  # "(right axis)" on the second entry.
  meas2) cat <<'PLAN'
EML Graphs|ocr,btn1
Line Chart -- What the lines are|ocr,opt0=2,btn1
Line Chart -- Column Mapping|ocr,btn1
Line Chart -- The Right-Hand Axis|ocr,btn1
Graph Complete|ink,ocr,btn3
PLAN
  ;;
  # LEG 4 -- two unlike measurements WITH repeats. The row of the dispatch
  # table that gets means and no band. The column page must not offer the
  # interval -- ruling 3, intervals are not offered across two scales -- and
  # the form must disclose the count it found rather than leaving the reader
  # to infer that the line is a mean.
  meas2_rep) cat <<'PLAN'
EML Graphs|ocr,btn1
Line Chart -- What the lines are|ocr,opt0=2,btn1
Line Chart -- Column Mapping|ocr,btn1
Line Chart -- The Right-Hand Axis|ocr,btn1
Graph Complete|ink,ocr,btn3
PLAN
  ;;
  # LEG 5 -- three unlike measurements: the composition refusal. The message
  # has to name the two controls that do the job -- "Erase page first" and a
  # panel origin -- and the ink measure has to show that nothing was drawn
  # while it was on screen.
  #
  # AND THEN THE PAGE IT SENDS THE USER BACK TO IS USED. Untick the third
  # column, press Draw, and the same visit reaches the right-hand axis page.
  # A refusal that left the form in an unusable state would pass a test that
  # stopped at the message.
  meas3_refuse) cat <<'PLAN'
EML Graphs|ocr,btn1
Line Chart -- What the lines are|ocr,opt0=2,btn1
Line Chart -- Column Mapping|ocr,btn1
Line chart|ocr,ink,btn1
Line Chart -- Column Mapping|ocr,tog3,btn1
Line Chart -- The Right-Hand Axis|ocr,btn1
Graph Complete|ink,ocr,btn3
PLAN
  ;;
  # THE OTHER REFUSAL -- nothing ticked. Not a dispatch row and not a fork,
  # but it is the second of the two messages the tree can put on screen, and
  # it is the one a user meets by unticking one column too many. It is driven
  # here so that both refusals are photographed by the same rig, and so that
  # the wrapped-comment layout is exercised on a second, shorter message.
  # The same page then draws a one-series figure: one measurement is one
  # series, with no right-hand axis and no key.
  none_refuse) cat <<'PLAN'
EML Graphs|ocr,btn1
Line Chart -- What the lines are|ocr,opt0=1,btn1
Line Chart -- Column Mapping|ocr,tog1,tog2,btn1
Line chart|ocr,ink,btn1
Line Chart -- Column Mapping|ocr,tog1,btn1
Graph Complete|ink,ocr,btn3
PLAN
  ;;
  # THE TWO RECORDER LEGS -- the same two figures as subjects4 and meas2,
  # driven identically, with the recorder RUNNING. drive.praat calls
  # @emlRecordBegin before the workflow and @emlRecordFlush after Done, so
  # what lands in out/<leg>_emitted.praat is what a user gets from Start
  # recording ... Stop recording around one press of Draw.
  #
  # WHY THESE TWO AND NOT THE OTHER SIX. They are the two figures whose draw
  # call names an object or a column the emitted script cannot reach on its
  # own. rec_subjects4 melts four columns into a private `eml_melt` Table
  # which the form REMOVES before it returns, so the recorded call names an
  # object that does not exist by the time the file is written, let alone
  # replayed. rec_meas2 keeps the user's own Table but puts a second column
  # on a right-hand axis, which is not an argument of @emlDrawTimeSeries but
  # a set of globals -- the class @emlRecordCaptureSeriesPens exists for.
  #
  # THE PLANS ARE COPIES OF subjects4 AND meas2 ON PURPOSE. If the walk
  # differed, a divergence between the session's figure and the replay's
  # could be a difference in the walk rather than in the recorder. Identical
  # walks make the session PNG of subjects4 and of rec_subjects4 comparable
  # too, which is a second, free statement: turning the recorder on does not
  # change the picture.
  rec_subjects4) cat <<'PLAN'
EML Graphs|ocr,btn1
Line Chart -- What the lines are|ocr,opt0=1,btn1
Line Chart -- Column Mapping|ocr,btn1
Graph Complete|ink,ocr,btn3
PLAN
  ;;
  rec_meas2) cat <<'PLAN'
EML Graphs|ocr,btn1
Line Chart -- What the lines are|ocr,opt0=2,btn1
Line Chart -- Column Mapping|ocr,btn1
Line Chart -- The Right-Hand Axis|ocr,btn1
Graph Complete|ink,ocr,btn3
PLAN
  ;;
  # THE TWO LONG-SHAPE LEGS. The right-hand axis reached from a table that
  # stores its two measurements as one value column beside a name column,
  # which is the shape every EML stats tool emits.
  #
  # long_meas2 IS DRIVEN WITH THE SAME KEYSTROKES AS meas2 AND THAT IS THE
  # CLAIM. Same answer to the meaning question, the column page accepted as
  # it opens, the right-hand axis page accepted as it opens. The fixture holds
  # the numbers data_meas2.praat holds, so if meaning and storage are really
  # independent the two PNGs are the same file -- which is what v97 section 16
  # asks for, in bytes.
  long_meas2) cat <<'PLAN'
EML Graphs|ocr,btn1
Line Chart -- What the lines are|ocr,opt0=2,btn1
Line Chart -- Column Mapping|ocr,btn1
Line Chart -- The Right-Hand Axis|ocr,btn1
Graph Complete|ink,ocr,btn3
PLAN
  ;;
  # THE IDENTITY PAIR. The same twenty-four time points and the same two
  # arithmetic expressions, stored two ways, drawn with the same keystrokes,
  # under a title that is typed rather than composed.
  #
  # WHY THE TITLE IS TYPED, AND IT IS THE ONLY DIFFERENCE THESE TWO LEGS TAKE
  # OUT OF THE COMPARISON. A blank Title field composes one, and the composed
  # title ends in the name of the table the figure was drawn from -- "(lt
  # meas2)" against "(lt longmeas2)". That is correct on both sides and it is
  # not a difference in the figure; it is a difference in the fixtures' names.
  # Measured before this pair existed: long_meas2 and meas2 differed in 9223
  # pixels and every one of them was in rows 54 to 97 of 1200, the title line,
  # with the axis pair agreeing to seventeen significant digits and the colour
  # census agreeing exactly. Typing the same title into both removes the one
  # legitimate difference and leaves the claim as a claim about the data.
  #
  # THE TITLE FIELD IS WIDGET 1 ON THE MAIN PAGE. Read off
  # eml-graphs-form.praat rather than off this transcript's photograph of
  # the page, because the photograph is one commit stale and the page has
  # been regrouped since. Focusable order, all nine:
  #       0 Graph type, 1 Title, 2 Subtitle, 3 Color mode,
  #       4 left Figure size, 5 right Figure size, 6 Erase page first,
  #       7 left Panel origin, 8 right Panel origin
  #
  # c74d432 REGROUPED THIS PAGE AND MOVED NOTHING. The sweep put every row
  # under a named group -- a "🖼️ Figure" comment above Graph type and a
  # "📄 Page" comment above Erase -- and renamed two pairs into Praat's
  # left/right paired-row idiom (Figure width/height -> left/right Figure
  # size, Panel origin x/y -> left/right Panel origin). A comment row takes
  # no Tab stop, and a paired row still takes ONE STOP PER BOX -- both boxes
  # are real entry fields and Praat only shares the row and the label. So
  # the count is nine before and nine after, in the same order, and tab1 is
  # the Title on both revisions. Derived from the source on both sides of
  # the commit, not assumed.
  long_titled) cat <<'PLAN'
EML Graphs|ocr,tab1=Two measurements,btn1
Line Chart -- What the lines are|ocr,opt0=2,btn1
Line Chart -- Column Mapping|ocr,btn1
Line Chart -- The Right-Hand Axis|ocr,btn1
Graph Complete|ink,ocr,btn3
PLAN
  ;;
  wide_titled) cat <<'PLAN'
EML Graphs|ocr,tab1=Two measurements,btn1
Line Chart -- What the lines are|ocr,opt0=2,btn1
Line Chart -- Column Mapping|ocr,btn1
Line Chart -- The Right-Hand Axis|ocr,btn1
Graph Complete|ink,ocr,btn3
PLAN
  ;;
  # THREE LEVELS -- the composition refusal, worded for levels. There is no
  # tickbox to untick on this page, so the message cannot tell the user to
  # untick one and the way out this leg then takes is the one the message
  # names: set the series-name menu back to "(none - one series)" and draw the
  # measurement column on its own. A refusal that left the page unusable would
  # pass a test that stopped at the message.
  long_meas3_refuse) cat <<'PLAN'
EML Graphs|ocr,btn1
Line Chart -- What the lines are|ocr,opt0=2,btn1
Line Chart -- Column Mapping|ocr,btn1
Line chart|ocr,ink,btn1
Line Chart -- Column Mapping|ocr,opt1=1,btn1
Graph Complete|ink,ocr,btn3
PLAN
  ;;
  # THE THIRD RECORDER LEG. long_meas2 with the recorder running: what it
  # emits has to rebuild the PIVOT, for the same reason rec_subjects4's file
  # has to rebuild the melt -- the two-column table the draw layer was handed
  # is made by this pass and removed by it, so a recorded call that named it
  # would name an object nobody has.
  rec_long_meas2) cat <<'PLAN'
EML Graphs|ocr,btn1
Line Chart -- What the lines are|ocr,opt0=2,btn1
Line Chart -- Column Mapping|ocr,btn1
Line Chart -- The Right-Hand Axis|ocr,btn1
Graph Complete|ink,ocr,btn3
PLAN
  ;;
  # LEG 8 -- seven numeric columns. The page this replaces could name five.
  # Seven tickboxes have to be built, read back through 'name$' substitution,
  # and seven series have to reach the page -- which palette.py counts by
  # colour and by band rather than by trusting tsNSeries.
  seven) cat <<'PLAN'
EML Graphs|ocr,btn1
Line Chart -- What the lines are|ocr,opt0=1,btn1
Line Chart -- Column Mapping|ocr,btn1
Graph Complete|ink,ocr,btn3
PLAN
  ;;
esac
}

# ---------------------------------------------------------------------------
# THE FIGURE, MEASURED. Called once per leg on the PNG drive.praat saved.
# ---------------------------------------------------------------------------
measure_png () {
    local leg="$1" png="$2" tag="$3"
    [[ -s "$png" ]] || { emit "$leg" "${tag}_png" "MISSING"; return; }
    emit "$leg" "${tag}_png_md5" "$(md5sum "$png" | cut -d' ' -f1)"
    emit "$leg" "${tag}_png_bytes" "$(stat -c %s "$png")"
    while IFS=$'\t' read -r k v; do
        [[ -n "$k" ]] && emit "$leg" "${tag}_$k" "$v"
    done < <(python3 "$SCRIPT_DIR/palette.py" "$png" 2>/dev/null)
    # THE FIGURE'S OWN TEXT. The key's entries, the axis names and the
    # on-figure disclosure are drawn as glyphs; this reads them back off the
    # picture, which is where the claim "the key says (right axis)" lives.
    convert "$png" -colorspace gray -resize 60% "$OUT/_fig_ocr.png" 2>/dev/null
    tesseract "$OUT/_fig_ocr.png" stdout --psm 6 2>/dev/null \
        | tr -s ' ' | sed 's/[[:space:]]*$//' | grep -v '^$' \
        > "$OUT/${leg}_${tag}_figtext.txt"
    while IFS= read -r l; do
        emit "$leg" "${tag}_figtext" "$l"
    done < "$OUT/${leg}_${tag}_figtext.txt"
}

# ---------------------------------------------------------------------------
# THE INFO WINDOW, VERBATIM. Praat writes it as UTF-16 on Linux even under
# --utf8, but not always -- so it is sniffed rather than blindly converted. A
# blind `iconv -f UTF-16` on ASCII emits nothing AND EXITS 0, which reads as
# an empty Info window rather than as a bad conversion.
# ---------------------------------------------------------------------------
emit_info () {
    local leg="$1" f="$2"
    [[ -s "$f" ]] || { emit "$leg" info_lines 0; return; }
    local plain="$OUT/${leg}_info.txt"
    if file -b "$f" | grep -q "UTF-16"; then
        iconv -f UTF-16 -t UTF-8 "$f" > "$plain"
    else
        cp "$f" "$plain"
    fi
    local n=0
    while IFS= read -r l; do
        [[ -z "${l//[[:space:]]/}" ]] && continue
        emit "$leg" info "$l"; n=$((n + 1))
    done < "$plain"
    emit "$leg" info_lines "$n"
}

# ---------------------------------------------------------------------------
# WHAT THE FORM'S OWN VARIABLES SAID, FOLDED IN.
#
# drive.praat writes its report to a file of its own rather than appending to
# the transcript directly. ONE PROCESS WRITES THE TSV. Two writers appending
# to one file is how harness/linestyle ended up with 854 rows carrying 610
# distinct pairs, and the count check at the bottom of this driver cannot
# distinguish "Praat wrote rows" from "rows were duplicated" if Praat is also
# a writer.
# ---------------------------------------------------------------------------
fold_vars () {
    local leg="$1" f="$OUT/${leg}_vars.tsv"
    if [[ ! -s "$f" ]]; then
        emit "$leg" vars_written no
        return
    fi
    local n=0 k v who
    while IFS=$'\t' read -r who k v; do
        [[ -n "$k" ]] || continue
        emit "$leg" "$k" "$v"; n=$((n + 1))
    done < "$f"
    emit "$leg" vars_written "$n"
}

# ---------------------------------------------------------------------------
# ONE GUI LEG.
# ---------------------------------------------------------------------------
run_gui_leg () {
    local leg="$1" prefs="$OUT/prefs_$leg" home="$OUT/home_$leg"
    rm -rf "$prefs" "$home"; mkdir -p "$prefs" "$home"
    # BEGINNER MODE, WRITTEN DOWN RATHER THAN ASSUMED. Advanced is a saved
    # preference; a leg whose widget indices are counted for the beginner page
    # would silently type into the wrong field if the preference file said
    # otherwise.
    printf 'showAdvanced: 0\n' > "$prefs/eml-graphs-config.txt"
    rm -f "$prefs/pid" "$prefs/message" 2>/dev/null
    rm -f "$OUT/$leg.png" "$OUT/${leg}_info_raw.txt" "$OUT/${leg}_vars.tsv"
    # THE RECORDER IS ASKED FOR BY NAME, by this driver, and not by the leg's
    # own script: drive.praat records if and only if EML_LT_REC is non-empty,
    # so the six legs that must run with no recording running cannot acquire
    # one by accident.
    local recpath=""
    case "$leg" in rec_*) recpath="$OUT/${leg}_emitted.praat" ;; esac
    rm -f "$recpath" 2>/dev/null

    emit "$leg" leg_started 1
    # `exec env` AND NOT A PLAIN SUBSHELL: without exec, $! is the SUBSHELL's
    # pid, killing it leaves Praat running with its windows on the display,
    # and the next leg reads the previous leg's Picture window as its own
    # empty baseline.
    ( cd "$SCRIPT_DIR" && exec env DISPLAY="$DISP" HOME="$home" \
        EML_LT_LEG="$leg" EML_LT_OUT="$OUT/${leg}_vars.tsv" \
        EML_LT_PNG="$OUT/$leg.png" EML_LT_INFO="$OUT/${leg}_info_raw.txt" \
        EML_LT_REC="$recpath" EML_LT_RECDIR="$OUT" \
        "$PRAAT" $PRAAT_TRUST --pref-dir="$prefs" --utf8 --new-send "$DRIVE" \
        > "$OUT/$leg.log" 2>&1 ) &
    PRAAT_PID=$!
    sleep 10

    emit "$leg" ink_empty "$(ink)"

    local n=0 prev="" line wid title step want acts act
    while IFS= read -r step; do
        n=$((n + 1))
        want="${step%%|*}"
        acts="${step#*|}"
        line=$(waitpause "$prev") || {
            emit "$leg" "s${n}_title" "<none>"
            emit "$leg" "s${n}_want" "$want"
            break
        }
        wid="${line%%$'\t'*}"
        title="${line#*$'\t'}"
        emit "$leg" "s${n}_title" "$title"
        emit "$leg" "s${n}_want" "$want"
        DISPLAY="$DISP" import -window "$wid" "$OUT/${leg}_s${n}.png" 2>/dev/null

        # FOCUS IS TRACKED, NOT RE-ESTABLISHED. Activating a window that is
        # already active raises no focus event, so a second action in one step
        # does NOT start from widget 0 -- it starts wherever the previous one
        # left the caret. `pos` is the widget the caret is on, 0 at the top of
        # every step, and every action moves relative to it.
        DISPLAY="$DISP" xdotool windowactivate --sync "$wid" 2>/dev/null
        DISPLAY="$DISP" xdotool windowfocus "$wid" 2>/dev/null
        sleep 1
        local pos=0
        IFS=',' read -ra act <<< "$acts"
        local a
        for a in "${act[@]}"; do
            case "$a" in
              opt*=*)
                local nw="${a%%=*}"; nw="${nw#opt}"
                local k="${a#*=}"
                local fwd=$(( nw - pos ))
                [[ "$fwd" -gt 0 ]] && \
                    DISPLAY="$DISP" xdotool key --clearmodifiers --repeat "$fwd" Tab
                pos="$nw"; sleep 0.6
                DISPLAY="$DISP" xdotool key --clearmodifiers Home; sleep 0.4
                if [[ "$k" -gt 1 ]]; then
                    DISPLAY="$DISP" xdotool key --clearmodifiers \
                        --repeat $((k - 1)) Down
                fi
                sleep 0.6
                DISPLAY="$DISP" import -window "$wid" \
                    "$OUT/${leg}_s${n}_set.png" 2>/dev/null
                ;;
              tog*)
                local nw="${a#tog}"
                local fwd=$(( nw - pos ))
                [[ "$fwd" -gt 0 ]] && \
                    DISPLAY="$DISP" xdotool key --clearmodifiers --repeat "$fwd" Tab
                pos="$nw"; sleep 0.6
                DISPLAY="$DISP" xdotool key --clearmodifiers space
                sleep 0.6
                DISPLAY="$DISP" import -window "$wid" \
                    "$OUT/${leg}_s${n}_set.png" 2>/dev/null
                ;;
              tab*=*)
                local nw="${a%%=*}"; nw="${nw#tab}"
                local txt="${a#*=}"
                local fwd=$(( nw - pos ))
                [[ "$fwd" -gt 0 ]] && \
                    DISPLAY="$DISP" xdotool key --clearmodifiers --repeat "$fwd" Tab
                pos="$nw"; sleep 0.6
                DISPLAY="$DISP" xdotool key --clearmodifiers ctrl+a
                DISPLAY="$DISP" xdotool type --clearmodifiers --delay 60 "$txt"
                sleep 0.6
                ;;
              ocr)
                dialog_text "$wid" "${leg}_s${n}_shown" \
                    > "$OUT/${leg}_s${n}_shown.txt"
                while IFS= read -r l; do
                    emit "$leg" "s${n}_shown" "$l"
                done < "$OUT/${leg}_s${n}_shown.txt"
                ;;
              ink)
                emit "$leg" "s${n}_ink" "$(ink)"
                ;;
              btn*)
                # THE Nth BUTTON FROM THE END, FROM WHEREVER THE CARET IS.
                # Walking back pos + N from position `pos` reaches the same
                # widget N shift+Tabs from position 0 would, because the ring
                # wraps. Never Return on a field: Praat presses the DEFAULT
                # button then, not the focused one, so a wrong count would not
                # fail -- it would silently press something else.
                local nb="${a#btn}"
                DISPLAY="$DISP" xdotool key --clearmodifiers \
                    --repeat $(( pos + nb )) shift+Tab
                pos=0; sleep 1
                DISPLAY="$DISP" xdotool key --clearmodifiers Return
                sleep 3
                ;;
            esac
        done
        prev="$wid"
    done < <(plan_of "$leg")

    emit "$leg" steps "$n"
    # PRESSING Done ENDS THE SCRIPT AND --new-send ENDS PRAAT WITH IT, but the
    # process takes a moment to go, and drive.praat writes its report, its
    # figure and its Info dump in between -- an 1800x1200 300-dpi save is not
    # instant.
    #
    # THE WAIT IS ON THE ARTEFACTS, NOT ON THE CLOCK. A fixed sleep long
    # enough for the slowest leg is dead time on every other one, and a fixed
    # sleep too short reads a half-written PNG. What this waits for is the
    # thing that means "the leg is done": leg_returned in the report file --
    # which drive.praat writes only after @emlGraphsWorkflow comes back -- and
    # a figure on disk. Either the process goes first, or those appear.
    #
    # MEASURED, AND IT IS WHY `exited` IS RECORDED RATHER THAN ASSERTED ON:
    # on this image Praat does NOT quit when a --new-send script ends. Waiting
    # forty-five seconds after every artefact was already on disk changed
    # nothing except the run time. `exited` is a fact in the transcript;
    # leg_returned is what says the workflow finished.
    local i
    for ((i = 0; i < 40; i++)); do
        kill -0 "$PRAAT_PID" 2>/dev/null || break
        if [[ -s "$OUT/${leg}_vars.tsv" ]] \
           && grep -q "leg_returned" "$OUT/${leg}_vars.tsv" \
           && [[ -s "$OUT/$leg.png" ]]; then
            sleep 2; break
        fi
        sleep 1
    done
    emit "$leg" wait_seconds "$i"
    if kill -0 "$PRAAT_PID" 2>/dev/null; then
        # WHAT IS STILL ON SCREEN WHEN A LEG DOES NOT EXIT. A Praat that is
        # merely slow to quit shows Objects and Picture; a Praat stuck on an
        # eighth dialog nobody planned for shows a Pause window, and the two
        # are indistinguishable from the exit status alone. Recorded before
        # the kill, because after it there is nothing to look at.
        local w nm names=""
        for w in $(winlist); do
            [[ "$w" == 0x* ]] || continue
            nm=$(DISPLAY="$DISP" xdotool getwindowname "$w" 2>/dev/null)
            names="$names[$nm]"
        done
        emit "$leg" windows_at_exit "${names:-none}"
        emit "$leg" exited no
        kill -9 "$PRAAT_PID" 2>/dev/null
    else
        emit "$leg" exited yes
    fi
    PRAAT_PID=""
    fold_vars "$leg"
    measure_png "$leg" "$OUT/$leg.png" fig
    emit_info "$leg" "$OUT/${leg}_info_raw.txt"
    # THE NEXT LEG MUST NOT MEET THIS LEG'S WINDOWS. A stale pause window on
    # the shared display is indistinguishable from the next leg's first
    # dialog, and the next leg would type into a dead form and hang -- which
    # reads as a defect in the form rather than as a dirty display.
    for ((i = 0; i < 30; i++)); do
        [[ -z "$(winlist | tr -d '[:space:]')" ]] && break
        sleep 1
    done
    emit "$leg" display_clear \
        "$([[ -z "$(winlist | tr -d '[:space:]')" ]] && echo yes || echo no)"
    rm -rf "$prefs" "$home"
}

# ---------------------------------------------------------------------------
# THE ONE LEG WITH NO DIALOG. A right-hand axis asked for by a SCRIPT on a
# figure whose series are the same measurement -- the request the question
# tree cannot produce, which is exactly why the gate has to refuse it. Run
# with DISPLAY unset, which also proves this leg needs no X server.
# ---------------------------------------------------------------------------
run_script_leg () {
    local leg=script_refuse prefs="$OUT/prefs_$leg"
    rm -rf "$prefs"; mkdir -p "$prefs"
    rm -f "$OUT/$leg.png" "$OUT/${leg}_honoured.png" "$OUT/${leg}_vars.tsv"
    emit "$leg" leg_started 1
    ( cd "$SCRIPT_DIR" && env -u DISPLAY \
        EML_LT_LEG="$leg" EML_LT_OUT="$OUT/${leg}_vars.tsv" \
        EML_LT_PNG="$OUT/$leg.png" EML_LT_PNG2="$OUT/${leg}_honoured.png" \
        EML_LT_INFO="$OUT/${leg}_info_raw.txt" \
        timeout 300 "$PRAAT" $PRAAT_TRUST --pref-dir="$prefs" \
        --run "$SCRIPTLEG" > "$OUT/$leg.log" 2>&1 )
    emit "$leg" exit_code "$?"
    fold_vars "$leg"
    measure_png "$leg" "$OUT/$leg.png" fig
    measure_png "$leg" "$OUT/${leg}_honoured.png" honoured
    emit_info "$leg" "$OUT/${leg}_info_raw.txt"
    rm -rf "$prefs"
}

for leg in $LEGS; do
    echo "  -- $leg"
    if [[ "$leg" == "script_refuse" ]]; then
        run_script_leg
    else
        run_gui_leg "$leg"
    fi
done


# ---------------------------------------------------------------------------
# THE REPLAY. The two rec_ legs emitted a script each; this runs them and
# compares the picture with the one the session drew.
# ---------------------------------------------------------------------------
# WHY IT IS DONE HERE AND NOT AS ANOTHER LEG: the emitted file is an input
# that does not exist until the recorded leg has run, and it needs the two
# mechanical edits no Praat script can make to itself, which
# harness/linestyle/run.sh and harness/secondaxis/run.sh both spell out -- the
# library include paths point at an INSTALLED plugin (~/.praat-dir/...) and
# are pointed at this repository instead, and the object the workflow ran on
# has to be in the Objects window before the step that selects it.
#
# PRAAT WRITES UTF-16 WHEN THE TEXT NEEDS IT AND ASCII WHEN IT DOES NOT.
# rec_subjects4's figure title carries a "+/-" sign, so its emitted file comes
# back UTF-16BE; rec_meas2's is plain ASCII. `file` is asked rather than
# guessed, for the reason emit_info gives above: a blind `iconv -f UTF-16` on
# ASCII emits nothing AND EXITS 0.
#
# EACH SCRIPT IS RUN TWICE, and the second run is not a retry.
#
#   <leg>_replay.png  the file EXACTLY AS EMITTED. This is what a user gets.
#   <leg>_tuned.png   the same file with the two axis numbers typed into the
#                     editable block.
#
# THE TUNED RUN EXISTS BECAUSE OF RULING 10(b), and the gap it measures is
# not a defect in this feature. The block carries the axis the user ASKED for
# -- 0 and 0 for auto -- so that a workflow retargeted at next month's data
# gets next month's frame; the resolved range is a COMMENT beside it. A
# legend-bearing figure is drawn twice by @emlGraphsDrawWithLegendRoom, which
# measures the legend and redraws on a widened axis, and that loop is the
# FORM's -- an emitted script draws once. So a plain replay comes back on the
# un-widened axis, exactly as harness/record's LEG_LEGEND records for the
# grouped violin. Both numbers are in the transcript rather than left for
# someone to discover, and the tuned run is where "byte for byte" is claimed.
# ---------------------------------------------------------------------------
replay_leg () {
    local leg="$1" data="$2"
    local rec="$OUT/${leg}_emitted.praat"
    if [[ ! -s "$rec" ]]; then
        emit "$leg" replay_verdict NO_SCRIPT
        return
    fi
    emit "$leg" emitted_bytes "$(stat -c %s "$rec")"
    emit "$leg" emitted_encoding \
        "$(file -b "$rec" | grep -q "UTF-16" && echo utf16 || echo ascii)"

    local u8="$OUT/${leg}_emitted.utf8.praat"
    if file -b "$rec" | grep -q "UTF-16"; then
        python3 -c "import sys;
d = open(sys.argv[1], 'rb').read()
open(sys.argv[2], 'w', encoding='utf-8').write(d.decode('utf-16', errors='ignore'))" \
            "$rec" "$u8"
    else
        cp "$rec" "$u8"
    fi

    # WHAT THE EMITTED FILE SAYS, read by a validator without locating it.
    # One row per step header, so "the melt is a step of its own, and it is a
    # convert step, and it comes before the draw" is three facts about three
    # rows rather than a grep in R.
    while IFS= read -r l; do
        emit "$leg" emitted_step "$l"
    done < <(grep -E '^# --- Step [0-9]+ \(' "$u8")
    # One row per declaration in the editable block. The block is every line
    # from the manifest comment to the first step separator that is spelled
    # `name = value   ; note`.
    while IFS= read -r l; do
        local k v
        k=$(printf '%s' "$l" | sed -E 's/^([A-Za-z0-9_]+\$?)[[:space:]]*=.*/\1/')
        v=$(printf '%s' "$l" | sed -E 's/^[A-Za-z0-9_]+\$?[[:space:]]*=[[:space:]]*//; s/[[:space:]]*;.*$//')
        emit "$leg" "block_$k" "$v"
    done < <(grep -E '^[A-Za-z][A-Za-z0-9_]*\$?[[:space:]]*=' "$u8")
    # The lines of the emitted file that CALL something, so a check can ask
    # for the melt call by name and in order.
    while IFS= read -r l; do
        emit "$leg" emitted_call "$(printf '%s' "$l" | sed 's/[[:space:]]*$//')"
    done < <(grep -E '^@eml' "$u8")

    # ---- the two mechanical edits -------------------------------------
    local rep="$OUT/${leg}_replay.praat"
    sed "s|~/.praat-dir/plugin_EML_StatsGraphs|$SRC/plugin_EML_StatsGraphs|g" \
        "$u8" > "$rep.tmp"
    awk -v datafile="$SCRIPT_DIR/$data" '
        { print }
        /^@emlClearAnnotations$/ && !done {
            while ((getline line < datafile) > 0) print line
            done = 1
        }' "$rep.tmp" > "$rep"
    rm -f "$rep.tmp"
    emit "$leg" replay_include_rewritten \
        "$(grep -c "^include $SRC/plugin_EML_StatsGraphs" "$rep")"
    # THE SAME RECTANGLE, SAID OUT LOUD. The session saved the plugin's own
    # extent union (@emlAssertFullViewport); a bare save writes whatever
    # viewport was last selected, which is the inner panel. The figure is
    # 6 x 4 at the origin in both.
    printf 'Select outer viewport: 0, 6, 0, 4\n' >> "$rep"
    printf 'Save as 300-dpi PNG file: "%s"\n' "$OUT/${leg}_replay.png" >> "$rep"

    # ---- the tuned copy, the block edited and nothing else -------------
    local tuned="$OUT/${leg}_tuned.praat"
    local amin amax
    amin=$(awk -F'\t' -v c="$leg" '$1==c && $2=="axis_y_min" {print $3}' "$TMP" | tail -1)
    amax=$(awk -F'\t' -v c="$leg" '$1==c && $2=="axis_y_max" {print $3}' "$TMP" | tail -1)
    if [[ -n "$amin" && -n "$amax" ]]; then
        # THE NUMBER MATCHED INCLUDES e AND +: Praat's string$ falls back to
        # exponential notation on small magnitudes, and a pattern that only
        # took digits and a dot would rewrite "5" and leave "e-05" behind,
        # which parses as a different number rather than as a syntax error.
        sed -E "s/^(axisYMin[[:space:]]*=[[:space:]]*)[-+0-9.eE]+/\1$amin/;
                s/^(axisYMax[[:space:]]*=[[:space:]]*)[-+0-9.eE]+/\1$amax/" \
            "$rep" > "$tuned"
        sed -i "s|${leg}_replay.png|${leg}_tuned.png|" "$tuned"
        emit "$leg" tuned_axis "$amin $amax"
    else
        emit "$leg" tuned_axis NA
    fi

    rm -rf "$OUT/prefs_replay" "$OUT/home_replay"
    mkdir -p "$OUT/prefs_replay" "$OUT/home_replay"
    local which
    for which in replay tuned; do
        local script="$OUT/${leg}_${which}.praat"
        local png="$OUT/${leg}_${which}.png"
        [[ -s "$script" ]] || { emit "$leg" "${which}_verdict" NO_SCRIPT; continue; }
        rm -f "$png"
        # ---- WHY THE REPLAY RUNS IN A GUI PRAAT AND NOT A BATCH ONE -------
        # Every other replay in this repository -- harness/linestyle,
        # harness/secondaxis -- runs `--run` with DISPLAY unset, because the
        # figure it compares against was ALSO drawn by `--run`. This one is
        # not: the recording is made through the form's dialogs, so the
        # session's PNG came out of a GUI Praat, and comparing it with a batch
        # replay measures the renderer rather than the recorder.
        #
        # MEASURED, 19 August 2026, and it is a three-pixel fact with a
        # byte-sized consequence. The legend box is sized from the width of
        # its widest entry, and a GUI Praat and a batch Praat return slightly
        # different text widths: the box's left border lands at x = 436 in one
        # and x = 439 in the other, at 300 dpi. Nothing else on the page
        # moves. The tuned replay run with `--run` differed from the session
        # in 690 pixels, all of them that one border; run with `--new-send`
        # under this same Xvfb it is BYTE-IDENTICAL --
        # 290d24858462fcc7f6c755361e618939 both sides.
        #
        # So the replay is driven the way the leg was, and the claim that
        # survives is the strong one. A batch replay is still a runnable
        # script -- proving that is what harness/linestyle is for -- and
        # nothing here needs a window manager: only an X server, for the
        # font metrics.
        #
        # --new-send DOES NOT EXIT when its script ends (recorded in
        # run_gui_leg above and re-measured here), so this waits on the
        # ARTEFACT and then kills the process by its own pid.
        ( cd "$SCRIPT_DIR" && exec env DISPLAY="$DISP" HOME="$OUT/home_replay" \
            "$PRAAT" $PRAAT_TRUST --pref-dir="$OUT/prefs_replay" --utf8 \
            --new-send "$script" > "$OUT/${leg}_${which}.log" 2>&1 ) &
        local rpid=$! ri
        for ((ri = 0; ri < 90; ri++)); do
            [[ -s "$png" ]] && { sleep 2; break; }
            kill -0 "$rpid" 2>/dev/null || break
            sleep 1
        done
        emit "$leg" "${which}_wait" "$ri"
        kill -9 "$rpid" 2>/dev/null
        wait "$rpid" 2>/dev/null
        if [[ -s "$png" ]]; then
            emit "$leg" "${which}_verdict" OK
            emit "$leg" "${which}_png_md5" "$(md5sum "$png" | cut -d' ' -f1)"
            emit "$leg" "${which}_png_px" \
                "$(identify -format '%wx%h' "$png" 2>/dev/null)"
        else
            emit "$leg" "${which}_verdict" NO_FIGURE
        fi
        # THE FIRST ERROR LINE, VERBATIM. A replay that cannot run says why,
        # and the sentence it says is the claim -- "No object with name
        # Table eml_melt" is the whole of the defect this leg was built for,
        # and a check that only counted a missing PNG could not tell it from
        # a missing Praat.
        emit "$leg" "${which}_error" \
            "$(grep -m1 -E '^(Error|Script line)' "$OUT/${leg}_${which}.log" \
               | sed 's/[[:space:]]*$//')"
        # A DISPLAY THAT STILL HOLDS THE REPLAY'S WINDOWS IS THE NEXT
        # REPLAY'S PROBLEM. The same rule the legs above follow.
        local wi
        for ((wi = 0; wi < 30; wi++)); do
            [[ -z "$(winlist | tr -d '[:space:]')" ]] && break
            sleep 1
        done
    done
    rm -rf "$OUT/prefs_replay" "$OUT/home_replay"
}

for leg in $LEGS; do
    case "$leg" in
      rec_subjects4) replay_leg rec_subjects4 data_subjects4.praat ;;
      rec_meas2)     replay_leg rec_meas2     data_meas2.praat ;;
      rec_long_meas2) replay_leg rec_long_meas2 data_longmeas2.praat ;;
    esac
done

emit "--run--" legs_driven "$(echo $LEGS | wc -w)"

# ---------------------------------------------------------------------------
# A SUBSET RUN KEEPS THE LEGS IT DID NOT DRIVE, AND ONLY IF THEY DESCRIBE THE
# SAME FORM.
#
# WHY THIS EXISTS. The full list is fifteen legs and three replays and takes
# something over twenty minutes; some environments will not let one command
# run that long, and break.sh's own stage seam was added for the same reason.
# Without this, driving the tree in batches means the last batch's transcript
# holds only the last batch's legs, and v97 -- which asserts on every leg and
# refuses a transcript with fewer -- reports fourteen missing legs rather than
# anything about the plugin.
#
# THE DIGESTS ARE THE GUARD, and they are the same four digests the staleness
# binding at the top of this file writes. Rows are carried over ONLY when the
# transcript already on disk was taken against byte-identical code; anything
# else is refused out loud, because a transcript mixing two forms' legs under
# one digest is precisely the lie that binding exists to prevent. Carrying a
# leg over is therefore never a way to avoid re-driving a leg the change
# touched -- edit the form and every batch has to be driven again.
#
# WHICH LEGS CAME FROM WHERE IS WRITTEN DOWN. legs_requested names what this
# invocation drove and legs_carried names what it inherited, so a reader of
# the transcript can always tell the difference.
# ---------------------------------------------------------------------------
FULL="subjects4 subjects_ci meas2 meas2_rep meas3_refuse none_refuse seven script_refuse long_meas2 long_meas3_refuse long_titled wide_titled rec_subjects4 rec_meas2 rec_long_meas2"
carried=""
if [[ -s "$TSV" ]]; then
    for leg in $FULL; do
        driven=no
        for d in $LEGS; do [[ "$d" == "$leg" ]] && driven=yes; done
        [[ "$driven" == yes ]] && continue
        awk -F'\t' -v l="$leg" '$1==l { found = 1 } END { exit !found }' \
            "$TSV" || continue
        carried="$carried $leg"
    done
fi
if [[ -n "$carried" ]]; then
    stale=""
    for f in graphs/eml-graphs-form.praat graphs/eml-graph-procedures.praat \
             graphs/eml-draw-procedures.praat stats/eml-record.praat; do
        k="code_sha256_$(basename "$f" .praat)"
        now=$(sed -E '/^[[:space:]]*(#|;|!)/d' "$SRC/plugin_EML_StatsGraphs/$f" \
              | sha256sum | cut -d' ' -f1)
        was=$(awk -F'\t' -v k="$k" '$1=="--run--" && $2==k {print $3}' "$TSV" | tail -1)
        [[ "$now" == "$was" ]] || stale="$stale $k"
    done
    if [[ -n "$stale" ]]; then
        echo "linetree: FAIL — this run drove [$LEGS] and would have carried"
        echo "          [$carried ] over from the transcript already on disk,"
        echo "          but that transcript describes a different form:"
        echo "         $stale"
        echo "          Re-drive every leg, or delete $TSV."
        rm -f "$TMP"; exit 1
    fi
    while IFS= read -r row; do
        printf '%s\n' "$row" >> "$TMP"
        emitted=$((emitted + 1))
    done < <(awk -F'\t' -v legs="$carried" '
        BEGIN { n = split(legs, a, " "); for (i = 1; i <= n; i++) keep[a[i]] = 1 }
        keep[$1]' "$TSV")
    emit "--run--" legs_carried "${carried# }"
else
    emit "--run--" legs_carried "none"
fi

# ---------------------------------------------------------------------------
# THE TWO SHAPES, COMPARED AS FILES.
#
# THE CLAIM WORTH PINNING ABOVE ALL THE OTHERS IN THIS DIRECTORY: the same
# numbers under the same names draw the same figure whether the table holds
# its two measurements side by side or stacked in one column. Everything else
# here -- which page appeared, what it offered, what the form's variables said
# afterwards -- is evidence about the route. This is the destination.
#
# TWO PAIRS, AND THEY ARE NOT THE SAME STATEMENT.
#
#   titled   long_titled vs wide_titled. Both legs typed the SAME title, so
#            nothing about the figure is allowed to differ and the verdict has
#            to be IDENTICAL, in bytes.
#   auto     long_meas2 vs meas2. Neither typed anything, so each figure
#            composed its own title and each title correctly names the table
#            it was drawn from -- "(lt longmeas2)" and "(lt meas2)". These two
#            files CANNOT be identical and the point of measuring them is to
#            say exactly how they are not: how many pixels, and in which rows.
#
# THE ROWS ARE WHY THIS PAIR IS WORTH KEEPING. A pair that differs only in the
# title line differs only in the caption; a pair that differs anywhere below it
# differs in the data, and the two are indistinguishable from a verdict alone.
#
# THE COMPARISON IS DONE HERE AND NOT IN THE VALIDATOR because a validator in R
# has no image reader it can rely on, and because the harness is where
# measurement belongs in this tree -- v97 asserts on rows, it does not open
# files. Filed under "--pairs--" rather than under a leg: it is a statement
# ABOUT two legs and belongs to neither.
#
# RUN AFTER THE CARRY-OVER, so that a batched drive compares the figures on
# disk whichever batch produced them.
# ---------------------------------------------------------------------------
compare_pair () {
    local tag="$1" a="$OUT/$2.png" b="$OUT/$3.png"
    emit "--pairs--" "${tag}_a" "$2"
    emit "--pairs--" "${tag}_b" "$3"
    while IFS=$'\t' read -r k v; do
        [[ -n "$k" ]] && emit "--pairs--" "${tag}_$k" "$v"
    done < <(python3 "$SCRIPT_DIR/pngdiff.py" "$a" "$b" 2>/dev/null)
}
compare_pair titled long_titled wide_titled
compare_pair auto   long_meas2  meas2

rm -f "$OUT/_ink.png" "$OUT/_ocr.png" "$OUT/_fig_ocr.png"
mv "$TMP" "$TSV"
disk=$(wc -l < "$TSV")
echo "linetree: wrote $TSV ($disk rows, $((emitted)) emitted)"
if [[ "$disk" -ne "$emitted" ]]; then
    echo "linetree: FAIL — artefact holds $disk rows, run emitted $emitted"
    exit 1
fi
