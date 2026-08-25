#!/usr/bin/env bash
# ============================================================================
# harness/wizardback/run.sh — every wizard branch driven under the display,
#                             INCLUDING Back-and-return on each page, with the
#                             values chosen before the jump asserted to survive
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# WHY THIS EXISTS. Risk register R3 names one inspection and this file is it:
# "every wizard branch driven end to end under the display harness, including
# Back-and-return on each page with typed values asserted to survive." The
# wizard is one goto-chained file whose historical defect class is exactly
# that — a page re-entered after a jump re-renders with the plugin's guess in
# place of what the user picked — and it has been fixed at least three times.
# v128 checks that invariant by READING THE SOURCE. This file checks it by
# DRIVING THE WIZARD, which is a different question: v128 can only see the
# write-backs that go through @wizardColIdx / @wizardCondSlot, and several of
# the seed variables lane 4 added do not (Group order, Subject column, the
# correlation group column, the normality mode, and every *TestToMenu row).
# A source check cannot see those at all. A driven page shows them.
#
# HOW A "TYPED VALUE SURVIVED" IS ASSERTED, AND WHY NOT OFF THE SCREENSHOT.
# Reading a combo's displayed TEXT back off a PNG needs OCR, and an OCR
# disagreement would be indistinguishable from the defect. So the assertion is
# behavioural and end to end instead:
#
#     set the field to a value that is NOT the wizard's guess
#       -> Continue
#       -> come back to the same page (Back button, or a page's own guard)
#       -> press Continue again WITHOUT TOUCHING THE FIELD
#       -> Run, and read the wizard's own Analysis Plan out of the Info window
#
# The plan names the Data column, the Group column and the Test in force. If
# the value survived the return the plan names what was picked; if the redraw
# reverted to the guess, the SECOND Continue re-reads the guess and the plan
# names that instead. Nothing is inferred from a pixel.
#
# EVERY FIXTURE IS BUILT SO THE GUESS AND THE PICK DIFFER. On fixture_two.csv
# @emlGuessColumnRoles takes the first numeric column, Pitch; the walk picks
# the third column, Loud. A leg that silently lost the pick therefore reports
# "Data column: Pitch", which is a different string, not a subtly different
# number. Group labels are "zeta" and "alpha" IN THAT TABLE ORDER, so table
# order and alphabetical order are opposite and the group-order control's
# survival is readable in the same way.
#
# THE GUI PRIMITIVES ARE NOT REINVENTED HERE. Window discovery, client-area
# geometry, the combo recipe and its settle times, and the page reader are
# harness/coldstart/run.sh + harness/coldstart/page.py, by way of
# harness/posthocgate (whose page_wide.py this file imports rather than
# copies). The measured facts behind each one are documented there. What is
# new here is only the Back step and the survival assertion.
#
# $EML_WB_SRC points the whole rig at a different plugin tree, the same door
# posthocgate's $EML_PHG_SRC opens, so a red demonstration drives THIS file
# unmodified against a seeded tree instead of a rehearsal of it.
#
# Usage:
#   bash harness/wizardback/run.sh              # every leg
#   bash harness/wizardback/run.sh two_group    # one leg by name
#   EML_WB_SRC=/path/to/tree bash harness/wizardback/run.sh
#
# Output:
#   $OUT/<leg>.info.txt   the Info window, decoded, as the user would read it
#   $OUT/<leg>.trail      the page titles the walk met, in order
#   $OUT/<leg>.plan       the Analysis Plan block lifted out of the Info window
#   $OUT/WIZARDBACK.tsv   leg <TAB> key <TAB> value — what a validator reads
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=/dev/null
. "$ROOT/harness/_env.sh" || { echo "wizardback: no Praat; refusing" >&2; exit 2; }

SRC="${EML_WB_SRC:-$ROOT/plugin_EML_StatsGraphs}"
OUT="${EML_WB_OUT:-$SCRIPT_DIR/out}"
ONLY="${1:-}"

# PROVE THE RIG CAN RUN BEFORE CLEARING ANYTHING — harness/coldstart's rule:
# a driver that empties its output folder and only then discovers it has no
# plugin tree has turned a missing dependency into deleted evidence.
[ -d "$SRC/scripts" ] || {
    echo "wizardback: REFUSED — no plugin tree at $SRC. Nothing was cleared." >&2
    exit 2; }
for tool in Xvfb xdotool xprop xwininfo import python3 iconv od \
            matchbox-window-manager; do
    command -v "$tool" >/dev/null 2>&1 || {
        echo "wizardback: REFUSED — '$tool' not on PATH. Nothing was cleared." >&2
        exit 2; }
done
PAGEPY="$SCRIPT_DIR/page_wb.py"
[ -f "$PAGEPY" ] || {
    echo "wizardback: REFUSED — no page reader at $PAGEPY. Nothing was cleared." >&2
    exit 2; }

mkdir -p "$OUT"
TSV="$OUT/WIZARDBACK.tsv"
if [ -z "$ONLY" ]; then
    printf 'leg\tkey\tvalue\n' > "$TSV"
fi
emit () { printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$TSV"; }
[ -z "$ONLY" ] && { emit rig src "$SRC"
                    emit rig praat "$("$PRAAT" --version 2>&1 | head -1)"; }

# ---------------------------------------------------------------------------
# THE LEGS
# ---------------------------------------------------------------------------
# One line per leg:   name | fixture | plan
#
# A plan is semicolon-separated STEPS, one per page the walk meets, in order.
# A step is  <combo-ops>@<button>  where
#
#   combo-ops   n:v[,n:v...]   set the n-th optionmenu on the page to its v-th
#                              row, or "-" to touch nothing on this page
#   button      C              the LAST button (Continue / Run / OK)
#               B              the SECOND button, which on every wizard page
#                              that has three is "Back"
#
# A step of "-@C" is the load-bearing one: it is the page re-entered after the
# jump, continued from WITHOUT TOUCHING ANYTHING. Whatever the plan reports
# afterwards is what that redraw was holding.
LEGS="
two_group|fixture_two.csv|1:1@C;1:1@C;1:1@C;1:3@C;-@B;-@C;1:7@C
two_group_order|fixture_two.csv|1:1@C;1:1@C;1:1@C;1:3@C;1:1,2:2@C;-@C;1:7@C
kgroups|fixture_k.csv|1:1@C;1:1@C;1:2@C;1:3@C;-@B;-@C;1:2@C
paired|fixture_paired.csv|1:1@C;1:2@C;1:1@C;1:3,2:2@C;-@B;-@C;1:6@C
correlation|fixture_corr.csv|1:2@C;1:1@C;1:2,2:1@C;-@B;-@C;1:3,2:2@C
normality_group|fixture_two.csv|1:3@C;1:3@C;1:3@C;-@B;-@C;1:2,2:1@C
"

XT () { timeout 20 "$@"; }

wb_pausewin () {
    local id nm
    for id in $(XT xprop -root _NET_CLIENT_LIST 2>/dev/null \
                | sed 's/.*# //' | tr -d ' ' | tr ',' ' '); do
        nm=$(XT xprop -id "$id" _NET_WM_NAME 2>/dev/null | sed 's/.*= //')
        case "$nm" in
            *Pause:*) echo "$((id))|$(printf '%b' \
                        "$(printf '%s' "$nm" | sed 's/^"//; s/"$//; s/\\\([0-7][0-7][0-7]\)/\\0\1/g')")"
                      return 0 ;;
        esac
    done
    return 1
}

wb_geom () {
    XT xwininfo -id "$1" 2>/dev/null | awk '
        /Absolute upper-left X/ { x = $4 }
        /Absolute upper-left Y/ { y = $4 }
        /^  Width:/  { w = $2 }
        /^  Height:/ { h = $2 }
        END { if (w == "") exit 1; print x, y, w, h }'
}

wb_read () {
    WB_COMBOS=""; WB_BUTTONS=""
    XT import -window "$1" "$2" 2>/dev/null || return 1
    local line
    while IFS= read -r line; do
        case "$line" in
            combos*)  WB_COMBOS="${line#combos}" ;;
            buttons*) WB_BUTTONS="${line#buttons}" ;;
        esac
    done < <(timeout 30 python3 "$PAGEPY" "$2" 2>/dev/null)
    [ -n "$WB_BUTTONS" ]
}

# Buttons are pressed by their READ x-centre and a y taken from the bottom of
# the client area, exactly as posthocgate does it. Nothing here predicts a
# coordinate.
wb_press () {
    local X Y W H
    read -r X Y W H < <(wb_geom "$1") || return 1
    XT xdotool mousemove $((X + $2)) $((Y + H - 36)) click 1
    sleep 1
}

# SETTING ONE OPTIONMENU: OPEN IT, PHOTOGRAPH IT, CLICK THE ROW.
#
# The keyboard recipe every other rig here uses — click, Home, Down x n, Return
# — was photographed keystroke by keystroke on this build and does not do what
# it looks like it does. Two measurements, both on the wizard's two-group
# column page, 25 Aug 2026:
#
#   Return does not commit. It RE-OPENS the popup with the wanted row
#   highlighted, and there it stays; the next click lands inside the popup
#   instead of on Continue and the walk silently spends the rest of its plan
#   on a page it already answered. harness/posthocgate records this as a
#   "pointer grab" and works around it by leaving that page on its seeds.
#
#   And the arrows only ever reach the FIRST optionmenu on a page. Set Data
#   column to row 3 (correct), then run the identical recipe on the Group
#   column asking for row 2: what moves is DATA COLUMN, to row 2. Clicking a
#   second optionmenu opens and closes its popup without taking keyboard
#   focus. A rig that has to answer two column menus on one page cannot use
#   the keyboard at all.
#
# So the popup is opened and the ROW IS CLICKED. popup.py finds the rows by
# diffing a root capture taken with the popup shut against one taken with it
# open — `import -window <id>` is refused during the grab but `import -window
# root` answers, measured in the same session — and reports their centres in
# order. Nothing predicts a row height, an item count or a popup origin.
#
# ONE LIMIT, MEASURED AND NOT PAPERED OVER. On a menu long enough that GTK has
# to reposition the popup to fit the screen, the bands and the items stop
# lining up: the k-group test page's 15-row menu came back as 16 bands and the
# row that got clicked was not the row asked for. Short menus — every column
# list, every two- and three-row control, the seven-row two-group test menu —
# are exact. A leg whose assertion rides on a long menu must read the choice
# back out of the report rather than trust the click, and the k-group leg below
# does exactly that: it asserts the COLUMN it set, not the test row.
#
# Then the grab's release is OBSERVED rather than waited out: page_wide.py
# counts the optionmenu arrows, an open popup covers them, so re-reading until
# the count is back to what the page had BEFORE the click is a direct sighting
# that nothing holds the pointer. WB_EXPECT_COMBOS is that count, set by the
# caller from its own first read. A page that never comes back is recorded as
# popup_stuck rather than pressed on blindly.
wb_setcombo () {
    local X Y W H t px py rows _wbx
    read -r X Y W H < <(wb_geom "$1") || return 1
    # WHERE TO CLICK IS TRIED AND CHECKED, NOT ASSUMED.
    #
    # Every other rig here clicks the drop arrow at x = W - 19, which is right
    # on pages whose optionmenus are stretched to the window. THE WIZARD'S
    # COLUMN PAGES ARE NOT SUCH PAGES: page_wide.py's own header records that
    # on the narrow select-columns page (524 px) the combos "stop 12 to 40
    # pixels short of the right edge" — which is why that file widened its
    # READING band. The CLICK was never widened to match, so at W - 19 it lands
    # on bare page background, no popup opens, and a walk that assumes it did
    # answers nothing while reporting a clean run. Measured here: the research
    # goal, observation, design and test pages open 6, 2, 3 and 7 rows at
    # W - 19; the two-column page opens ZERO, twice.
    #
    # So the offsets are TRIED IN ORDER and each attempt is judged by whether
    # a popup actually appeared. A miss clicks bare background in the window's
    # right-hand strip, where no wizard page puts a control.
    for _wbx in 19 32 45; do
        XT import -window root "$4.c$5.png" 2>/dev/null
        XT xdotool mousemove $((X + W - _wbx)) $((Y + $2)) click 1
        sleep 1.5
        XT import -window root "$4.o$5.png" 2>/dev/null
        rows=$(timeout 30 python3 "$SCRIPT_DIR/popup.py" "$4.c$5.png" "$4.o$5.png" 2>/dev/null)
        [ "${rows%% *}" = "rows" ] && { WB_HIT_X="$_wbx"; break; }
    done
    if [ "${rows%% *}" != "rows" ]; then
        # The popup never opened, or the two shots were identical. Recorded,
        # so a page that was never answered is not read as a page that took
        # the default.
        WB_NO_POPUP="$5"
        return 0
    fi
    read -r _ px rest <<< "$rows"
    read -r -a WB_ROWS <<< "$rest"
    WB_LAST_ROWS="${#WB_ROWS[@]}"
    if [ "${#WB_ROWS[@]}" -lt "$3" ]; then
        WB_SHORT_POPUP="${#WB_ROWS[@]}"
        return 0
    fi
    py="${WB_ROWS[$(( $3 - 1 ))]}"
    XT xdotool mousemove "$px" "$py" click 1
    sleep 1
    for ((t = 0; t < 24; t++)); do
        if wb_read "$1" "$4" 2>/dev/null; then
            read -r -a WB_YS <<< "$WB_COMBOS"
            [ "${#WB_YS[@]}" -ge "${WB_EXPECT_COMBOS:-1}" ] && return 0
        fi
        sleep 0.5
    done
    WB_POPUP_STUCK=1
    return 0
}

wb_settle () {
    local old="$1" log="$2" t p
    for ((t = 0; t < 40; t++)); do
        sleep 0.5
        grep -q "PRAAT ERROR MESSAGE" "$log" 2>/dev/null && { echo ""; return 0; }
        p=$(wb_pausewin) || continue
        [ "${p%%|*}" = "$old" ] && continue
        echo "$p"; return 0
    done
    echo ""
    return 0
}

# A page RE-ENTERED looks identical to the page you left: same window id is
# possible, same title certainly. wb_settle above returns "" when the id does
# not change, so a Back that lands on a NEW window is seen, and a guard that
# re-shows the SAME window is handled by re-reading rather than by waiting.
wb_current () {
    local p t
    for ((t = 0; t < 30; t++)); do
        p=$(wb_pausewin) && { echo "$p"; return 0; }
        sleep 0.5
    done
    return 1
}

run_leg () {
    local leg="$1" fixture="$2" plan="$3"
    local disp home log trail step id title p n_steps nth val ops op btn
    log="$OUT/$leg.log"
    home="$OUT/work/$leg"
    rm -rf "$home"; mkdir -p "$home/prefs"

    # A display claimed by PROBING, never by arithmetic — coldstart's rule,
    # and for its reason: computing one and clearing its lock deletes a
    # neighbouring harness's socket out from under it.
    local dn probe
    disp=""
    for ((dn = ${EML_WB_DISPLAY_BASE:-210} + 1; dn <= ${EML_WB_DISPLAY_BASE:-210} + 60; dn++)); do
        probe=":$dn"
        DISPLAY="$probe" timeout 5 xdpyinfo >/dev/null 2>&1 && continue
        [ -e "/tmp/.X11-unix/X$dn" ] && continue
        disp="$probe"; break
    done
    [ -n "$disp" ] || { emit "$leg" "state" "rig_unreachable"; return 0; }
    emit "$leg" "display" "$disp"

    Xvfb "$disp" -screen 0 1400x1100x24 >"$home/xvfb.log" 2>&1 &
    local xvfb_pid=$!
    local t ready=0
    for ((t = 0; t < 60; t++)); do
        if DISPLAY="$disp" xdpyinfo >/dev/null 2>&1; then
            ready=$((ready + 1)); [ "$ready" -ge 2 ] && break
        else ready=0; fi
        sleep 0.5
    done
    local wm_pid="" wm_up=0 attempt
    for ((attempt = 1; attempt <= 3; attempt++)); do
        DISPLAY="$disp" matchbox-window-manager -use_titlebar no >>"$home/wm.log" 2>&1 &
        wm_pid=$!
        for ((t = 0; t < 40; t++)); do
            DISPLAY="$disp" xprop -root _NET_SUPPORTED >/dev/null 2>&1 && { wm_up=1; break; }
            kill -0 "$wm_pid" 2>/dev/null || break
            sleep 0.5
        done
        [ "$wm_up" = 1 ] && break
        kill -9 "$wm_pid" >/dev/null 2>&1; sleep 1
    done
    if [ "$wm_up" != 1 ]; then
        emit "$leg" "state" "rig_unreachable"
        kill -9 "$wm_pid" "$xvfb_pid" >/dev/null 2>&1; return 0
    fi

    HOME="$home" DISPLAY="$disp" "$PRAAT" --pref-dir="$home/prefs" --utf8 \
        $PRAAT_TRUST >"$log" 2>&1 &
    local gui_pid=$!
    export DISPLAY="$disp"

    local objwin=0 id0 nm0
    for ((t = 0; t < 80; t++)); do
        for id0 in $(XT xprop -root _NET_CLIENT_LIST 2>/dev/null \
                     | sed 's/.*# //' | tr -d ' ' | tr ',' ' '); do
            nm0=$(XT xprop -id "$id0" _NET_WM_NAME 2>/dev/null | sed 's/.*= //')
            case "$nm0" in *"Praat Objects"*) objwin=1; break ;; esac
        done
        [ "$objwin" = 1 ] && break
        sleep 0.25
    done

    # The instance is pinged until it answers, and the answer only counts if
    # the instance we started gave it — coldstart's measurement: a SIGUSR1
    # that lands before Praat installs its handler KILLS the instance, and the
    # sender then runs the script itself, so the ping file alone cannot tell
    # "listening" from "dead, and something else answered".
    printf 'writeFile: "%s/ping.txt", "ok"\n' "$home" > "$home/ping.praat"
    rm -f "$home/ping.txt"
    local listening=0
    for ((t = 0; t < 4; t++)); do
        HOME="$home" DISPLAY="$disp" timeout 15 "$PRAAT" \
            --pref-dir="$home/prefs" --utf8 $PRAAT_TRUST \
            --send "$home/ping.praat" >/dev/null 2>&1
        if [ -s "$home/ping.txt" ] && kill -0 "$gui_pid" 2>/dev/null; then
            listening=1; break
        fi
        rm -f "$home/ping.txt"
        kill -0 "$gui_pid" 2>/dev/null || break
        sleep 1
    done
    emit "$leg" "listening" "$listening"
    if [ "$listening" != 1 ]; then
        emit "$leg" "state" "rig_unreachable"
        kill -9 "$gui_pid" "$wm_pid" "$xvfb_pid" >/dev/null 2>&1; return 0
    fi

    # THE FIXTURE IS SELECTED BEFORE THE WIZARD IS ASKED ANYTHING. With
    # nothing selected the wizard invents its own example table and the leg
    # would be measuring the demo data instead of the fixture.
    printf 'tbl = Read Table from comma-separated file: "%s"\nselectObject: tbl\n' \
        "$SCRIPT_DIR/$fixture" > "$home/setup.praat"
    HOME="$home" DISPLAY="$disp" timeout 30 "$PRAAT" \
        --pref-dir="$home/prefs" --utf8 $PRAAT_TRUST \
        --send "$home/setup.praat" >>"$log" 2>&1
    sleep 1

    HOME="$home" DISPLAY="$disp" timeout 30 "$PRAAT" \
        --pref-dir="$home/prefs" --utf8 $PRAAT_TRUST \
        --send "$SRC/scripts/eml-wizard.praat" >>"$log" 2>&1

    for ((t = 0; t < 40; t++)); do
        wb_pausewin >/dev/null && break
        grep -q "PRAAT ERROR MESSAGE" "$log" 2>/dev/null && break
        sleep 0.5
    done

    trail=""; n_steps=0
    local IFSOLD="$IFS" steps ys bx
    IFS=';' read -r -a steps <<< "$plan"
    IFS="$IFSOLD"
    for step in "${steps[@]}"; do
        p=$(wb_current) || break
        id="${p%%|*}"; title="${p#*|}"
        btn="${step##*@}"; ops="${step%@*}"
        trail="${trail:+$trail > }${title}[${btn}]"
        wb_read "$id" "$home/page$n_steps.png" || { emit "$leg" "read_fail" "step$n_steps"; break; }
        read -r -a ys <<< "$WB_COMBOS"
        read -r -a bx <<< "$WB_BUTTONS"
        if [ -n "$ops" ] && [ "$ops" != "-" ]; then
            local IFS2="$IFS"; IFS=',' read -r -a oplist <<< "$ops"; IFS="$IFS2"
            WB_EXPECT_COMBOS="${#ys[@]}"; WB_POPUP_STUCK=0; WB_NO_POPUP=0; WB_SHORT_POPUP=""; WB_LAST_ROWS=""; WB_HIT_X=""
            for op in "${oplist[@]}"; do
                nth="${op%%:*}"; val="${op##*:}"
                if [ "${#ys[@]}" -lt "$nth" ]; then
                    emit "$leg" "plan_miss" "step$n_steps wanted combo $nth, page has ${#ys[@]}"
                    continue
                fi
                WB_LAST_ROWS=""; WB_HIT_X=""
                wb_setcombo "$id" "${ys[$((nth - 1))]}" "$val" "$home/page$n_steps.png" "$nth"
                emit "$leg" "step${n_steps}_combo${nth}_rows" "${WB_LAST_ROWS:-0} (wanted $val, arrow at W-${WB_HIT_X:-?})"
                sleep 0.5
            done
            [ "${WB_POPUP_STUCK:-0}" = 1 ] && emit "$leg" "popup_stuck" "step$n_steps"
            [ "${WB_NO_POPUP:-0}" != 0 ]    && emit "$leg" "no_popup"     "step$n_steps combo ${WB_NO_POPUP}"
            [ -n "${WB_SHORT_POPUP:-}" ]    && emit "$leg" "short_popup"  "step$n_steps had ${WB_SHORT_POPUP} row(s)"
            wb_read "$id" "$home/page$n_steps.png" >/dev/null 2>&1
            read -r -a bx <<< "$WB_BUTTONS"
        fi
        [ "${#bx[@]}" -gt 0 ] || { emit "$leg" "no_button" "step$n_steps"; break; }
        emit "$leg" "step${n_steps}_page" "$title"
        emit "$leg" "step${n_steps}_combos" "${#ys[@]}"
        emit "$leg" "step${n_steps}_buttons" "${#bx[@]}"
        if [ "$btn" = "B" ]; then
            # BACK IS SECOND FROM THE RIGHT, NOT SECOND FROM THE LEFT, and
            # the difference is the whole leg. Praat puts an UNDO button of
            # its own at the left of every pause window that has fields, so a
            # row the script writes as "Quit", "Back", "Continue" is PAINTED
            # as  Undo | Quit | Back | Continue  — four buttons, photographed
            # here on this rig's first drive. Counting from the left put the
            # Back press on Quit: the wizard exited, the Info window came back
            # 29 bytes long, and the leg reported a clean five-step walk.
            # Counting from the right is stable whether Undo is there or not.
            #
            # Fewer than three read buttons means the page has no Back at all
            # — recorded rather than clicked, so a mis-specified plan shows up
            # as a red leg instead of as a click on something else.
            if [ "${#bx[@]}" -lt 3 ]; then
                emit "$leg" "back_impossible" "step$n_steps has ${#bx[@]} button(s)"
                break
            fi
            wb_press "$id" "${bx[$(( ${#bx[@]} - 2 ))]}"
        else
            wb_press "$id" "${bx[$(( ${#bx[@]} - 1 ))]}"
        fi
        n_steps=$((n_steps + 1))
        # A re-entered page can reuse the same window, so a settle that only
        # watches for a NEW id would time out on exactly the step this rig is
        # about. Give it its chance, then fall through to wb_current.
        wb_settle "$id" "$log" >/dev/null
    done
    p=$(wb_pausewin) && trail="${trail:+$trail > }${p#*|}"
    emit "$leg" "steps" "$n_steps"
    emit "$leg" "planned_steps" "${#steps[@]}"
    emit "$leg" "trail" "$trail"
    printf '%s\n' "$trail" > "$OUT/$leg.trail"

    # WHAT THE INSTANCE SAYS, ASKED OF THE INSTANCE, and decoded: Praat writes
    # the whole file UTF-16BE the moment one character leaves ASCII, and this
    # report is full of them.
    rm -f "$home/objects.txt"
    sed "s|@OUT@|$home/objects.txt|" "$ROOT/harness/coldstart/probe_objects.praat" \
        > "$home/probe.praat"
    HOME="$home" DISPLAY="$disp" timeout 30 "$PRAAT" \
        --pref-dir="$home/prefs" --utf8 $PRAAT_TRUST \
        --send "$home/probe.praat" >/dev/null 2>&1
    # WAITED FOR, NOT RACED — `--send` delivers and returns; the instance
    # writes the file a moment later, in its own event loop.
    for ((t = 0; t < 40; t++)); do [ -s "$home/objects.txt" ] && break; sleep 0.5; done
    if [ -s "$home/objects.txt" ]; then
        case "$(head -c2 "$home/objects.txt" | od -An -tx1 | tr -d ' ')" in
            feff|fffe) iconv -f UTF-16 -t UTF-8 "$home/objects.txt" \
                           > "$OUT/$leg.info.txt" 2>/dev/null \
                       || cp "$home/objects.txt" "$OUT/$leg.info.txt" ;;
            *)         cp "$home/objects.txt" "$OUT/$leg.info.txt" ;;
        esac
        emit "$leg" "info_bytes" "$(wc -c < "$OUT/$leg.info.txt")"
        emit "$leg" "state" "walked"
        # The Analysis Plan block, lifted whole. This is the readback: it names
        # the Data column, the Group column and the Test the wizard ACTUALLY
        # dispatched, so a value that did not survive the return is a different
        # string here, not a subtly different number.
        awk '/EML Stats Wizard . Analysis Plan/,/Running analysis/' \
            "$OUT/$leg.info.txt" > "$OUT/$leg.plan"
        emit "$leg" "plan_lines" "$(wc -l < "$OUT/$leg.plan")"
        while IFS= read -r line; do
            case "$line" in
                *"Data column:"*)  emit "$leg" "plan_data"  "$(printf '%s' "${line#*Data column:}"  | sed 's/^ *//; s/ *$//')" ;;
                *"Group column:"*) emit "$leg" "plan_group" "$(printf '%s' "${line#*Group column:}" | sed 's/^ *//; s/ *$//')" ;;
                *"Column 1:"*)     emit "$leg" "plan_col1"  "$(printf '%s' "${line#*Column 1:}"     | sed 's/^ *//; s/ *$//')" ;;
                *"Column 2:"*)     emit "$leg" "plan_col2"  "$(printf '%s' "${line#*Column 2:}"     | sed 's/^ *//; s/ *$//')" ;;
                *"Test:"*)         emit "$leg" "plan_test"  "$(printf '%s' "${line#*Test:}"         | sed 's/^ *//; s/ *$//')" ;;
            esac
        done < "$OUT/$leg.plan"
        # The order the groups are named in the RESULT is how the group-order
        # control is read back: fixture_two.csv lists zeta before alpha, so
        # table order and alphabetical order are opposite.
        emit "$leg" "first_group" \
             "$(grep -oE '\b(zeta|alpha|east|west|north|south)\b' "$OUT/$leg.info.txt" | head -1)"
    else
        emit "$leg" "state" "no_info"
    fi
    if grep -q "PRAAT ERROR MESSAGE" "$log" 2>/dev/null; then
        emit "$leg" "praat_error" "1"
    else
        emit "$leg" "praat_error" "0"
    fi

    kill -9 "$gui_pid" "$wm_pid" "$xvfb_pid" >/dev/null 2>&1
    wait "$gui_pid" "$wm_pid" "$xvfb_pid" 2>/dev/null
    printf '  %-20s %s\n' "$leg" "$trail"
}

echo "wizardback: src = $SRC"
while IFS='|' read -r nm fx pl; do
    [ -n "$nm" ] || continue
    [ -z "$ONLY" ] || [ "$ONLY" = "$nm" ] || continue
    run_leg "$nm" "$fx" "$pl"
done <<< "$(printf '%s\n' "$LEGS" | sed '/^[[:space:]]*$/d')"

echo "wizardback: wrote $TSV"
