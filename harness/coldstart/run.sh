#!/usr/bin/env bash
# ============================================================================
# harness/coldstart/run.sh — every door, opened from the state a first-time
#                            user is actually in: NOTHING SELECTED
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# WHY THIS EXISTS, and it came from a real crash.
#
# Start the wizard with no table selected, choose Compare, answer that the
# same people were measured more than once, press Continue. Praat raised
# "Unknown variable" over the form that had just been answered, and the
# script stopped. Fourteen wizard pages print the selected table's name; with
# nothing selected the wizard invents example data, but it invents it at the
# point the chosen branch needs columns, which on that branch is AFTER a page
# that has already printed the name. The page did not render blank — it
# ERRORED, over a form that looked like it was working.
#
# THE GAP UNDER IT IS THE POINT. Every check in this tree that reads a dialog
# reads it as TEXT, and every harness that drives one drives it WITH a table
# selected. Nothing drove any entry point from the empty state. That is not
# one bug; it is a quadrant, and the wizard is fifteen branches wide inside
# it.
#
# WHAT A LEG IS. One Praat process, one fresh X display, one fresh
# preferences folder, an EMPTY Objects window, and one door pushed open. The
# leg then answers pages according to its plan and stops, and what is
# recorded is the sequence of page titles it saw plus whatever Praat wrote to
# stderr.
#
# WHY THE PAGES ARE REAL PAGES AND NOT A MODEL OF THEM. `praat --run` refuses
# to build a pause window at all — GTK aborts with "Can't create a
# GtkStyleContext without a display connection", with or without Xvfb, because
# --run is batch mode and batch mode has no GUI. So a headless transform of
# the source into "answers without dialogs" would be a model of the wizard,
# not the wizard. What runs here instead is an ordinary GUI Praat under Xvfb
# with the command SENT INTO IT — which is what pressing the menu item does —
# and the pause windows are the ones the user gets, driven by XTEST clicks.
#
# An uncaught Praat error arrives between "PRAAT ERROR MESSAGE:" and
# "(END OF PRAAT ERROR MESSAGE)", and the GUI instance stays up. That is the
# whole reason for `--send` into a live instance over `--new-send`: --new-send
# takes the instance down with the script, so a command that answers the cold
# start by printing a sentence and finishing leaves nothing to ask afterwards
# — no Info window, no object list, only an exit code — and "it exited" is not
# evidence that it did the right thing.
#
# IT ARRIVES ON THE RECEIVING INSTANCE'S STDERR, NOT THE SENDER'S, and this
# file said the opposite until 24 August 2026. `--send` delivers the script
# and returns; the instance that RUNS it is the one that reports on it. Every
# error grep below therefore read a file the error never reached, and `error`
# — the one verdict this family was built to produce — could not fire: a
# wrapper that died over its own form came back as `stalled`. Both streams now
# go to $OUT/<leg>.log, the instance's and the sender's, so the greps read the
# place the error is. Found by seed_violation.sh, which is what a red
# demonstration is for.
#
# THE VERDICTS:
#
#   refused   the door showed the PLUGIN'S OWN refusal — @emlErrorDialog in
#             "entry" mode, titled "Cannot start this tool" (or "Cannot run
#             this analysis"), or the table editor's own "Cannot Open the
#             Table Editor". Honest: it names what to select and changes
#             nothing.
#   example   the door went to its own example-data path AND came out the
#             other side. The wizard's is a page titled "No table selected"
#             offering "Create Demo"; a leg that answers it and then reaches a
#             column-selection page has proved the branch survives the empty
#             state. `example_offer` is the weaker cousin: offered, not taken.
#   page      a dialog of the command's own opened and wanted no table.
#   spoke     no dialog, no error, and something in the Info window. The
#             recorder's three controls answer the cold start this way.
#   error     Praat stopped. "PRAAT ERROR MESSAGE" in the leg's log. This is
#             the failure the family exists to catch.
#   stalled / exited
#             nothing appeared and nothing was said. Failures too, reported as
#             themselves rather than folded into `error`, because the two need
#             different fixes.
#
# HOW A PAGE IS ANSWERED. Two primitives, both measured on Praat 6.6.30 under
# Xvfb + matchbox on 24 August 2026:
#
#   * The buttons are the bottom row and the LAST one named in `endPause:` is
#     the rightmost, so pressing Continue / Run / OK is pressing the last
#     button. WHERE that button is, is MEASURED off the page rather than
#     predicted — see page.py. The first version of this driver predicted it
#     at (W-45, H-36) from the wizard's front page, where the row happens to
#     fill the window; on the 719px-wide observation-type page the row stops
#     at x=500 and that click landed on nothing. The walk then reported a
#     working branch as stalled, which is the expensive kind of wrong.
#   * An optionmenu is a GTK combo whose drop arrow is a dark glyph in the
#     14px band ending 12px from the right edge, and NOTHING ELSE in a Praat
#     pause window puts dark pixels there. Scanning that band down the
#     window's own image finds every combo on the page, in order, without
#     knowing anything about the page. Selection is then click-the-arrow,
#     Home, Down x (n-1), Return — the recipe harness/gui.sh has carried since
#     5 August.
#
# WHAT MUST NOT BE DONE WHILE A COMBO IS OPEN: take a screenshot. The popup
# holds a pointer grab, and `import` and `xwininfo -tree` block on it until
# the harness times out. Cost the first hour of building this. Every capture
# here happens between actions, never during one.
#
# THE TREE IS A VARIABLE, $EML_COLDSTART_SRC, for the same reason
# validate/v98_field_names.R has $EML_DIALOG_SRC: the red demonstration is a
# COPY of the shipped plugin with one violation seeded into it, driven by this
# file unmodified, so what goes red is this harness rather than a rehearsal of
# it. See seed_violation.sh.
#
# Usage:  bash harness/coldstart/run.sh [leg ...]
#         EML_COLDSTART_SRC=/path/to/a/plugin/tree  bash .../run.sh [leg ...]
#         EML_COLDSTART_OUT=/path/to/out            (default: ./out)
#         EML_COLDSTART_DISPLAY_BASE=120            (default: 80) — the X
#                display numbers this run may claim start just above it. Move
#                it if another harness in this tree is driving a GUI at the
#                same time; the allocator skips live servers either way.
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
. "$ROOT/harness/_env.sh" || { echo "coldstart: no Praat; refusing" >&2; exit 2; }

SRC="${EML_COLDSTART_SRC:-$ROOT/plugin_EML_StatsGraphs}"
OUT="${EML_COLDSTART_OUT:-$SCRIPT_DIR/out}"
LEGS_TSV="$SCRIPT_DIR/legs.tsv"

# THE RIG PROVES IT CAN RUN BEFORE IT CLEARS ANYTHING. A driver that empties
# its output folder and then discovers it has no Praat, no Xvfb or no plugin
# tree has turned a missing dependency into deleted evidence — the failure
# harness/... hit on 20 August and the reason `a1dd9e4` exists. Nothing below
# writes or removes a file until all four of these have resolved.
for tool in Xvfb xdotool xprop xwininfo import python3 iconv od; do
    command -v "$tool" >/dev/null 2>&1 || {
        echo "coldstart: REFUSED — '$tool' not on PATH. Nothing was cleared." >&2
        exit 2; }
done
[ -d "$SRC/scripts" ] || {
    echo "coldstart: REFUSED — no plugin tree at $SRC. Nothing was cleared." >&2
    exit 2; }
[ -f "$LEGS_TSV" ] || {
    echo "coldstart: REFUSED — no leg table at $LEGS_TSV. Nothing was cleared." >&2
    exit 2; }

mkdir -p "$OUT"
TSV="$OUT/COLDSTART.tsv"

WANT="${*:-}"

# A SUBSET DRIVE REPLACES ONLY ITS OWN LEGS, for the reason
# harness/dispatch/run.sh gives: truncating on every run means a one-leg drive
# erases the rest, the validator reports them missing, and the reader cannot
# tell "this leg aborted" from "this leg was not run".
if [ -f "$TSV" ] && [ -n "$WANT" ]; then
    keep="$(mktemp)"
    awk -F'\t' -v legs="$WANT" '
        BEGIN { n = split(legs, a, " "); for (i = 1; i <= n; i++) drop[a[i]] = 1 }
        NR == 1 { print; next }
        !($1 in drop) { print }
    ' "$TSV" > "$keep"
    mv "$keep" "$TSV"
else
    printf 'leg\tkey\tvalue\n' > "$TSV"
fi

emit () { printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$TSV"; }

# WHERE THE X DISPLAYS ARE TAKEN FROM, and which of them are ours to clear.
# $EML_COLDSTART_DISPLAY_BASE moves the whole run out of the way of a
# neighbour without editing this file. CS_MINE records every display number
# this run has claimed, so a socket left behind by our own `kill -9` teardown
# can be reclaimed while a stranger's is left alone. See the allocation block
# in run_leg for why that distinction is not fussiness.
DISPLAY_BASE="${EML_COLDSTART_DISPLAY_BASE:-80}"
declare -A CS_MINE=()

# ---------------------------------------------------------------------------
# X primitives. Every one is bounded by `timeout`, because the failure mode of
# a GUI harness is not a wrong answer, it is a wait with no end.
# ---------------------------------------------------------------------------
XT () { timeout 20 "$@"; }

# cs_pausewin -> "<decimal id>|<title>" for the pause window, if one is up.
#
# _NET_CLIENT_LIST, never `xdotool search --name`: GTK leaves WM_NAME UNSET
# when the title carries a character outside Latin-1, and the wizard's page
# titles are full of em dashes. A search-based lookup finds nothing and the
# walk reads as hung rather than as a lookup failure. Same route as
# harness/gui.sh:findwin — keep the two in step.
cs_pausewin () {
    local id nm
    for id in $(XT xprop -root _NET_CLIENT_LIST 2>/dev/null \
                | sed 's/.*# //' | tr -d ' ' | tr ',' ' '); do
        nm=$(XT xprop -id "$id" _NET_WM_NAME 2>/dev/null | sed 's/.*= //')
        case "$nm" in
            # xprop prints a UTF-8 title as octal escapes, so an em dash
            # arrives as \342\200\224 and every page title in the wizard has
            # one. Rewritten to \0342... so printf %b will fold them back;
            # otherwise the trail this harness records is unreadable exactly
            # where it matters most.
            *Pause:*) echo "$((id))|$(printf '%b' \
                        "$(printf '%s' "$nm" | sed 's/^"//; s/"$//; s/\\\([0-7][0-7][0-7]\)/\\0\1/g')")"
                      return 0 ;;
        esac
    done
    return 1
}

# cs_geom <id> -> X Y W H of the CLIENT area, absolute.
#
# xwininfo's "Absolute upper-left", not `xdotool getwindowgeometry`: under
# matchbox the two differ by the frame (measured: 4 across, 20 down), and
# `import -window <id>` captures the client area. Mixing the two puts every
# click 20px high, which on the wizard's first page is the difference between
# Continue and Quit — measured, by pressing Quit three times in a row while
# believing the walk had advanced.
cs_geom () {
    XT xwininfo -id "$1" 2>/dev/null | awk '
        /Absolute upper-left X/ { x = $4 }
        /Absolute upper-left Y/ { y = $4 }
        /^  Width:/  { w = $2 }
        /^  Height:/ { h = $2 }
        END { if (w == "") exit 1; print x, y, w, h }'
}

# cs_read <id> <png> — capture the page and read its controls.
# Sets CS_COMBOS and CS_BUTTONS (window-relative, in order). See page.py for
# what is measured, and why none of it is predicted from the window size.
cs_read () {
    CS_COMBOS=""; CS_BUTTONS=""
    XT import -window "$1" "$2" 2>/dev/null || return 1
    local line
    while IFS= read -r line; do
        case "$line" in
            combos*)  CS_COMBOS="${line#combos}" ;;
            buttons*) CS_BUTTONS="${line#buttons}" ;;
        esac
    done < <(timeout 30 python3 "$SCRIPT_DIR/page.py" "$2" 2>/dev/null)
    [ -n "$CS_BUTTONS" ]
}

# cs_press <id> <button-x> — click one button of the bottom row.
cs_press () {
    local X Y W H
    read -r X Y W H < <(cs_geom "$1") || return 1
    XT xdotool mousemove $((X + $2)) $((Y + H - 36)) click 1
    sleep 1
}

# cs_setcombo <id> <combo-y> <option-number>
# Click the arrow, then Home / Down x (n-1) / Return — the recipe
# harness/gui.sh has carried since 5 August. NO CAPTURE between the click and
# the Return: the popup holds a pointer grab and every capture tool blocks on
# it until this harness times out.
cs_setcombo () {
    local X Y W H k j
    read -r X Y W H < <(cs_geom "$1") || return 1
    XT xdotool mousemove $((X + W - 19)) $((Y + $2)) click 1
    sleep 1.2
    XT xdotool key --clearmodifiers Home; sleep 0.4
    k=$(( $3 - 1 ))
    for ((j = 0; j < k; j++)); do XT xdotool key --clearmodifiers Down; sleep 0.3; done
    XT xdotool key --clearmodifiers Return
    sleep 1.2
}

# cs_settle <old-id> <log> -> waits for the page to change, for Praat to
# raise an error, or for the clock to run out. Echoes the new "<id>|<title>",
# or "".
#
# IT DOES NOT WATCH THE SENDER. `praat --send` hands the script to the running
# instance and RETURNS — it does not stay attached for the length of the
# script — so "the sender has exited" says nothing about whether the dialog is
# up yet. Keying on it is what made this harness flaky: two refusals out of
# thirty-five came back as `stalled` on one run and `refused` on the next,
# which is the failure mode that teaches a reader to re-run until the red goes
# away.
cs_settle () {
    local old="$1" log="$2" t p
    for ((t = 0; t < 40; t++)); do
        sleep 0.5
        grep -q "PRAAT ERROR MESSAGE" "$log" 2>/dev/null && { echo ""; return 0; }
        p=$(cs_pausewin) || continue
        [ "${p%%|*}" = "$old" ] && continue
        echo "$p"; return 0
    done
    echo ""
    return 0
}

# ---------------------------------------------------------------------------
# One leg.
# ---------------------------------------------------------------------------
run_leg () {
    local leg="$1" entry="$2" plan="$3"
    local disp home log trail step id title p n_steps combo_ys nth val
    log="$OUT/$leg.log"
    home="$OUT/work/$leg"
    rm -rf "$home"; mkdir -p "$home/prefs"

    # A display per leg, so two legs never share an Objects window — and one
    # that is CLAIMED BY PROBING rather than computed from the leg's position.
    #
    # THE ARITHMETIC VERSION WAS DESTRUCTIVE TO OTHER RIGS, and the comment it
    # carried was wrong about its own arithmetic. It read
    #
    #     disp=":$((80 + LEG_N))"        # :80 upward — the walk rigs use :91/:99
    #     rm -f "/tmp/.X${disp#:}-lock" "/tmp/.X11-unix/X${disp#:}"
    #
    # but this population is thirty-five legs, so :80 upward is :81 to :115 —
    # which CONTAINS :91 and :99, the two it names as taken. Worse than the
    # collision is the line under it: the lock and the socket are removed
    # unconditionally, so a leg landing on a display another harness is
    # currently using deletes that harness's socket out from under it.
    #
    # Hit for real, 24 August 2026, on the first full drive of this file:
    # harness/axisrefuse was driving Praat on :86 in the same tree, leg 6 was
    # about to take :86, and the drive was stopped one leg short of removing
    # its socket. The neighbour would have failed in a way that looked like
    # its own bug.
    #
    # So: walk upward from the base and take the first display that has NO
    # LIVE SERVER. `xdpyinfo` answering is the test — a lock file alone proves
    # nothing, since a leg torn down with `kill -9` leaves one behind and that
    # stale lock is exactly what the removal below is for. A lock with a live
    # server behind it belongs to somebody else and is never touched.
    local dn probe
    disp=""
    for ((dn = DISPLAY_BASE + 1; dn <= DISPLAY_BASE + 200; dn++)); do
        probe=":$dn"
        DISPLAY="$probe" timeout 5 xdpyinfo >/dev/null 2>&1 && continue
        [ -e "/tmp/.X11-unix/X$dn" ] && [ -z "${CS_MINE[$dn]:-}" ] && {
            # A socket with no server answering is stale IF it is ours to
            # clear. One we have never used may belong to a neighbour that is
            # merely slow to answer, so it is skipped rather than deleted.
            continue
        }
        rm -f "/tmp/.X$dn-lock" "/tmp/.X11-unix/X$dn" 2>/dev/null
        CS_MINE[$dn]=1
        disp="$probe"
        break
    done
    if [ -z "$disp" ]; then
        emit "$leg" "listening" "0"
        emit "$leg" "entry" "$entry"
        emit "$leg" "steps" "0"
        emit "$leg" "trail" ""
        emit "$leg" "final" "<none>"
        emit "$leg" "state" "rig_unreachable"
        emit "$leg" "objects" "n/a"
        emit "$leg" "info"   "<none>"
        emit "$leg" "display" "<none>"
        emit "$leg" "returned" "1"
        printf '  %-22s %-12s %s\n' "$leg" "rig_unreachable" "no free X display"
        return 0
    fi
    emit "$leg" "display" "$disp"
    Xvfb "$disp" -screen 0 1400x1100x24 >"$home/xvfb.log" 2>&1 &
    local xvfb_pid=$!

    # WAITED FOR, NOT SLEPT AT. The first version slept two seconds and then
    # one and a half, and on a loaded box that was sometimes not enough: five
    # of thirty-five legs came back with an empty trail, every one of them
    # green on a re-run. A flaky rig is worse than no rig — it teaches the
    # reader to re-run until the red goes away, which is the habit that hides
    # the next real failure.
    # CONFIRMED TWICE, half a second apart, before anything else connects.
    # A single `xdpyinfo` that answers means the server accepted ONE
    # connection; it is not a promise about the next one, and the next one is
    # the window manager. Matchbox that loses that race exits at once — see
    # the block below, which then has to notice and restart it. Two
    # confirmations cost half a second per leg and remove the race rather than
    # recovering from it.
    local t ready=0
    for ((t = 0; t < 60; t++)); do
        if DISPLAY="$disp" xdpyinfo >/dev/null 2>&1; then
            ready=$((ready + 1))
            [ "$ready" -ge 2 ] && break
        else
            ready=0
        fi
        sleep 0.5
    done
    # THE WINDOW MANAGER IS STARTED UNTIL IT IS ACTUALLY THERE, and a leg
    # whose manager never came up is refused rather than driven.
    #
    # `xdpyinfo` answering means the server is accepting connections; it does
    # not mean the NEXT client will get one, and matchbox that loses the race
    # exits immediately with
    #
    #     matchbox: can't open display! check your DISPLAY variable.
    #
    # in its log and nothing anywhere else. THE CONSEQUENCE IS NOT A MISSING
    # WINDOW MANAGER, IT IS A SILENTLY BLIND HARNESS: cs_pausewin reads the
    # window list out of _NET_CLIENT_LIST, which is a property the WINDOW
    # MANAGER publishes, so with no manager the root window has no list, every
    # lookup comes back empty, and the leg records `stalled` — nothing ever
    # appeared — while the dialog it was sent to open is sitting on the
    # display in front of it.
    #
    # Measured, 24 August 2026: w_within_k, three times running, on three
    # different display numbers. Its wizard opened every time. The old loop
    # below waited for _NET_SUPPORTED and then CARRIED ON WHETHER OR NOT IT
    # ARRIVED, which is what turned a dead window manager into a verdict about
    # the plugin.
    local wm_pid="" wm_up=0 attempt
    for ((attempt = 1; attempt <= 3; attempt++)); do
        DISPLAY="$disp" matchbox-window-manager -use_titlebar no \
            >>"$home/wm.log" 2>&1 &
        wm_pid=$!
        for ((t = 0; t < 40; t++)); do
            DISPLAY="$disp" xprop -root _NET_SUPPORTED >/dev/null 2>&1 && { wm_up=1; break; }
            kill -0 "$wm_pid" 2>/dev/null || break
            sleep 0.5
        done
        [ "$wm_up" = 1 ] && break
        kill -9 "$wm_pid" >/dev/null 2>&1
        sleep 1
    done
    if [ "$wm_up" != 1 ]; then
        emit "$leg" "listening" "0"
        emit "$leg" "entry"   "$entry"
        emit "$leg" "steps"   "0"
        emit "$leg" "trail"   ""
        emit "$leg" "final"   "<none>"
        emit "$leg" "state"   "rig_unreachable"
        emit "$leg" "objects" "n/a"
        emit "$leg" "info"    "<none>"
        emit "$leg" "returned" "1"
        printf '  %-22s %-12s %s\n' "$leg" "rig_unreachable" \
               "no window manager on $disp after 3 attempts"
        kill -9 "$wm_pid" "$xvfb_pid" >/dev/null 2>&1
        return 0
    fi

    # A LIVE, IDLE INSTANCE, AND THE COMMAND SENT INTO IT — which is what a
    # menu press is. `--new-send` runs the script while Praat is still
    # starting up, and takes the whole instance down with it when the script
    # ends, so a command that finishes without a dialog leaves nothing to ask
    # about: no Info window, no object list, just an exit code. `--send` into
    # an instance that is already up leaves the instance standing whatever the
    # script does — including after an error — and the error still arrives on
    # the SENDER's stderr as "PRAAT ERROR MESSAGE", so nothing is lost.
    #
    # NOTHING SELECTED IS THE FIXTURE, and it is the one fixture this family
    # has. A fresh instance's Objects window is empty, so the fixture is the
    # absence of a setup step rather than a file — which is exactly why no
    # existing harness had it: every other rig starts by creating a table.
    # THE INSTANCE'S OWN STDERR IS THE LEG'S LOG, and this is the fix for the
    # one verdict this whole family exists to produce.
    #
    # The header of this file used to say that an uncaught Praat error
    # "arrives on the SENDER's stderr". It does not. `--send` hands the script
    # to the RECEIVING instance, and the receiving instance is what runs it, so
    # the error text — "PRAAT ERROR MESSAGE:", the failing line, the script
    # that did not complete — is written to the stderr of the Praat started
    # here, while the sender exits quietly having delivered its message.
    #
    # Every `grep PRAAT ERROR MESSAGE` in this file was therefore reading a
    # file the error never reaches, and `state = error` — the verdict this
    # family was built to catch Ian's crash with — COULD NOT FIRE. A wrapper
    # that died over its form was recorded as `stalled`: nothing appeared, no
    # reason given, indistinguishable from the rig failing to drive.
    #
    # Found on 24 August 2026 by seed_violation.sh, which is exactly what a
    # red demonstration is for: the seeded wrapper died with a textbook Praat
    # error and the harness reported "nothing happened".
    #
    # Both streams now land in one file — the instance's, opened here, and the
    # sender's, appended below — so the greps are reading the place the error
    # actually is, and a reader of $OUT/<leg>.log sees the whole leg.
    HOME="$home" DISPLAY="$disp" "$PRAAT" --pref-dir="$home/prefs" --utf8 \
        $PRAAT_TRUST >"$log" 2>&1 &
    local gui_pid=$!
    export DISPLAY="$disp"

    # THE INSTANCE IS PINGED UNTIL IT ANSWERS, and this is the fix for the
    # last of the flakiness. `praat --send` delivers through Praat's own
    # message file plus an X event; an instance whose windows are up but which
    # has not finished starting DROPS the message, with no error anywhere --
    # the sender exits 0 and nothing ever opens. Measured: two or three legs
    # in every thirty-five, never the same ones twice, reported as `stalled`
    # against commands that refuse perfectly well.
    #
    # A window on screen is therefore not proof that the instance is
    # listening. A round trip is: a one-line script whose only job is to write
    # a file, sent again until the file appears. Nothing about it touches the
    # Objects window or the Info window, so the cold-start fixture is exactly
    # as empty afterwards as before.
    # AND IT IS NOT PINGED UNTIL ITS OBJECTS WINDOW IS MAPPED. This is the
    # OTHER half of the fix and it is the half that was missing.
    #
    # `praat --send` delivers by writing a message file and then raising
    # SIGUSR1 at the pid named in it. Praat installs its handler for that
    # signal LATE in start-up — after the process exists, after the pref
    # directory is read, and after the sender can already find the pid. A
    # SIGUSR1 that lands before the handler is installed is not ignored and is
    # not dropped: the DEFAULT disposition of SIGUSR1 is to terminate the
    # process, so the ping KILLS the instance it is pinging.
    #
    # What made that invisible is what happened next. With the instance dead,
    # the sender finds no one to send to and runs the script ITSELF, in a
    # transient process — and ping.txt appears. The gate below therefore
    # recorded `listening 1` about an instance that had been dead since the
    # first ping, the entry command was then sent to a stale channel and
    # answered "Cannot send message. The program may have crashed.", nothing
    # ever opened, and the leg was recorded as `exited` against a command that
    # had never been asked anything.
    #
    # MEASURED, 24 August 2026, this rig, 3 trials pinging with no wait:
    # 2 of 3 came back `listening=1` with the instance DEAD and zero windows
    # on the display. Waiting for the Objects window first: 5 of 5 alive.
    # Those two `exited` legs in three are not a plugin fact; they are this.
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

    printf 'writeFile: "%s/ping.txt", "ok"\n' "$home" > "$home/ping.praat"
    rm -f "$home/ping.txt"
    local listening=0
    for ((t = 0; t < 4; t++)); do
        # IN THE FOREGROUND, UNDER `timeout`, AND NEVER kill -9'd. A sender
        # killed with -9 leaves Praat's message channel in a state the NEXT
        # sender reports as "Cannot send message. The program may have
        # crashed." — measured, on the run that introduced the ping: six legs
        # lost their command that way and were recorded as `exited` against
        # commands that had never been asked anything. `timeout` ends a hung
        # sender with SIGTERM, which the channel survives.
        HOME="$home" DISPLAY="$disp" timeout 15 "$PRAAT" \
            --pref-dir="$home/prefs" --utf8 $PRAAT_TRUST \
            --send "$home/ping.praat" >/dev/null 2>&1
        # THE ANSWER ONLY COUNTS IF THE INSTANCE WE STARTED GAVE IT. A
        # transient sender that ran the script itself writes exactly the same
        # ping.txt as the live instance would, so the file alone cannot tell
        # "it is listening" from "it is dead and something else answered" —
        # which is the false positive described above. `kill -0` on the pid we
        # started is what separates them, and it is asked on every attempt
        # rather than once at the end, so a ping that kills the instance is
        # recorded as the rig fault it is instead of being retried into a
        # green.
        if [ -s "$home/ping.txt" ] && kill -0 "$gui_pid" 2>/dev/null; then
            listening=1; break
        fi
        rm -f "$home/ping.txt"
        kill -0 "$gui_pid" 2>/dev/null || break
        sleep 1
    done
    emit "$leg" "listening" "$listening"

    # THE COMMAND ITSELF, sent the same way. Backgrounded, and its stderr is
    # the leg's log: that is where "PRAAT ERROR MESSAGE" arrives if the
    # command dies. The sender returns as soon as the instance has taken the
    # script, so its exit says nothing about whether a dialog is up — see
    # cs_settle.
    (
        cd "$SRC/scripts" && \
        HOME="$home" DISPLAY="$disp" "$PRAAT" --pref-dir="$home/prefs" \
            --utf8 $PRAAT_TRUST --send "$SRC/scripts/$entry" >>"$log" 2>&1
    ) &
    local praat_pid=$!

    trail=""
    id=""
    p=""
    for ((t = 0; t < 40; t++)); do
        sleep 0.5
        p=$(cs_pausewin) && break
        grep -q "PRAAT ERROR MESSAGE" "$log" 2>/dev/null && break
    done

    if [ -n "$p" ]; then
        id="${p%%|*}"; title="${p#*|}"; trail="$title"
    fi

    # Walk the plan. Empty step = answer nothing, press the last button.
    n_steps=0
    if [ -n "$plan" ] && [ "$plan" != "." ]; then
        local IFSOLD="$IFS"
        IFS=';' read -r -a steps <<< "$plan"
        IFS="$IFSOLD"
        for step in "${steps[@]}"; do
            [ -n "$id" ] || break
            pgrep -x praat >/dev/null 2>&1 || break
            # "-" is a page answered by pressing its last button and nothing
            # else. Written as a character rather than as an empty field
            # because a trailing ";" in a TSV cell is invisible to a reader
            # and to `git diff`, and this plan's LAST step is usually exactly
            # that page — the wizard's "No table selected / Create Demo".
            if ! cs_read "$id" "$home/page$n_steps.png"; then
                emit "$leg" "read_fail" "step$n_steps could not read the page"
                break
            fi
            local ys=($CS_COMBOS) bx=($CS_BUTTONS)
            if [ -n "$step" ] && [ "$step" != "-" ]; then
                local IFS2="$IFS"; IFS=',' read -r -a ops <<< "$step"; IFS="$IFS2"
                local op
                for op in "${ops[@]}"; do
                    nth="${op%%=*}"; nth="${nth#s}"; val="${op#*=}"
                    if [ "${#ys[@]}" -lt "$nth" ]; then
                        # A PLAN THAT MISSES ITS CONTROL IS RECORDED, NOT
                        # SHRUGGED OFF. If the page no longer has the
                        # optionmenu this leg was written against, the leg is
                        # no longer walking the branch it names, and a silent
                        # skip would leave it green while walking somewhere
                        # else entirely.
                        emit "$leg" "plan_miss" \
                             "step$n_steps wanted combo $nth, page has ${#ys[@]}"
                        continue
                    fi
                    cs_setcombo "$id" "${ys[$((nth - 1))]}" "$val"
                done
            fi
            [ "${#bx[@]}" -gt 0 ] || { emit "$leg" "no_button" "step$n_steps"; break; }
            cs_press "$id" "${bx[$(( ${#bx[@]} - 1 ))]}"
            n_steps=$((n_steps + 1))
            p=$(cs_settle "$id" "$log")
            if [ -z "$p" ]; then id=""; break; fi
            id="${p%%|*}"; title="${p#*|}"
            trail="$trail > $title"
        done
    fi

    # ---- settle, then look ------------------------------------------------
    # A FIXED BUDGET, NOT THE SENDER'S LIFETIME. `--send` returns as soon as
    # the instance has taken the script, so the sender is usually gone before
    # the first dialog is on screen. Waiting on it is what made two refusals
    # out of thirty-five report `stalled` on one run and `refused` on the
    # next.
    for ((t = 0; t < 30; t++)); do
        cs_pausewin >/dev/null && break
        grep -q "PRAAT ERROR MESSAGE" "$log" 2>/dev/null && break
        sleep 0.5
    done

    # ---- what the instance says, asked of the instance ---------------------
    # Asked BEFORE the verdict, and asked of the live GUI rather than inferred
    # from a window title: "a page rendered" and "the data behind it exists"
    # are different claims and this family is about the second one. The
    # instance is still standing whatever the command did, which is the whole
    # reason the command is sent into a running Praat rather than launched
    # with --new-send.
    local objs="n/a" infotxt=""
    if kill -0 "$gui_pid" 2>/dev/null; then
        rm -f "$home/objects.txt"
        sed "s|@OUT@|$home/objects.txt|" "$SCRIPT_DIR/probe_objects.praat" \
            > "$home/probe.praat"
        HOME="$home" DISPLAY="$disp" timeout 30 "$PRAAT" \
            --pref-dir="$home/prefs" --utf8 $PRAAT_TRUST \
            --send "$home/probe.praat" >/dev/null 2>&1
        # DECODED BEFORE IT IS READ, because Praat chooses the encoding and
        # this file is one Praat is entitled to write as UTF-16.
        #
        # `writeFile:` emits UTF-8 only while every character is ASCII; one
        # character outside it and Praat writes the WHOLE file UTF-16BE with a
        # BOM — the rule CLAUDE.md states, met here for real. What this probe
        # returns is the Info window, and the Info window is the plugin's own
        # prose: `Recorded — anything you do through an EML command` carries an
        # em dash, so the recorder's three legs are exactly the ones whose
        # probe output is UTF-16BE.
        #
        # To `sed` that file is bytes with NULs interleaved: `^== INFO ==$`
        # cannot match, both halves come back empty or mangled, and the leg
        # falls through to `exited` — reported against commands whose Info
        # text this probe had successfully read and handed over. Measured: the
        # probe returned the full recorder banner and both Tables, and run.sh
        # discarded it.
        #
        # `-s` is not enough on its own either: a BOM alone is 2 bytes.
        if [ -s "$home/objects.txt" ]; then
            local otxt="$home/objects.utf8.txt"
            case "$(head -c2 "$home/objects.txt" | od -An -tx1 | tr -d ' ')" in
                feff|fffe) iconv -f UTF-16 -t UTF-8 "$home/objects.txt" \
                               > "$otxt" 2>/dev/null || cp "$home/objects.txt" "$otxt" ;;
                *)          cp "$home/objects.txt" "$otxt" ;;
            esac
            objs=$(sed -n '1,/^== INFO ==$/p' "$otxt" \
                   | grep -v '^== INFO ==$' | tr '\n' '/' | sed 's|/*$||')
            infotxt=$(sed -n '/^== INFO ==$/,$p' "$otxt" | tail -n +2 \
                      | tr '\n' ' ' | sed 's/  */ /g; s/^ *//; s/ *$//')
            # CAPPED FOR THE TSV, AND ONLY FOR THE TSV. The recorder's banner
            # is two thousand characters of user-facing prose; the whole of it
            # sits in $home/objects.utf8.txt for anyone who wants it, and what
            # the row needs to carry is that the command SPOKE and the opening
            # of what it said. An uncapped cell turns one row of this file
            # into a screenful and makes every other row unreadable.
            [ "${#infotxt}" -gt 400 ] && infotxt="${infotxt:0:400}..."
        fi
    fi

    # ---- the verdict -------------------------------------------------------
    # ASKED AGAIN, FROM SCRATCH. The walk's own `id` is only what the last
    # step managed to see; a page that took longer to appear than cs_settle
    # waited is still on screen now, and reporting `stalled` on the strength
    # of a stale variable would blame the plugin for the harness's impatience.
    local final="" state=""
    p=$(cs_pausewin) && { id="${p%%|*}"; final="${p#*|}"; }
    if [ -n "$final" ]; then
        XT import -window "$id" "$OUT/$leg.png" 2>/dev/null
    fi
    if [ "$listening" != "1" ]; then
        # THE RIG'S OWN FAILURE, NAMED AS THE RIG'S. If the instance never
        # answered the ping, the command was never delivered and this leg has
        # measured nothing about the plugin. Reporting that as `stalled` would
        # put a rig fault in the plugin's column, which is the mistake that
        # cost 20 August.
        state="rig_unreachable"
    elif grep -q "PRAAT ERROR MESSAGE" "$log" 2>/dev/null; then
        state="error"
    elif [ -n "$final" ]; then
        case "$final" in
            *"Cannot start this tool"*|*"Cannot run this analysis"*|*"Cannot Open the Table Editor"*)
                state="refused" ;;
            # THE OFFER AND THE PATH ARE DIFFERENT CLAIMS. A leg still sitting
            # on "No table selected" has been OFFERED example data and has not
            # been given any; a leg that answered that page and reached
            # another one has walked the example-data path all the way to a
            # page that needs columns, which is where Ian's crash was.
            *"No table selected"*) state="example_offer" ;;
            *) case "$trail" in
                   *"No table selected"*) state="example" ;;
                   *) state="page" ;;
               esac ;;
        esac
    elif [ -n "$infotxt" ]; then
        # NO DIALOG, NO ERROR, AND SOMETHING SAID. Three commands answer the
        # cold start this way — the recorder's own controls print a sentence
        # and finish — and "the process ended" is not on its own evidence that
        # they did the right thing. The sentence is.
        state="spoke"
    elif kill -0 "$gui_pid" 2>/dev/null; then
        state="stalled"
    else
        state="exited"
    fi

    emit "$leg" "entry"   "$entry"
    emit "$leg" "steps"   "$n_steps"
    emit "$leg" "trail"   "$trail"
    emit "$leg" "final"   "${final:-<none>}"
    emit "$leg" "state"   "$state"
    emit "$leg" "objects" "${objs:-<none>}"
    emit "$leg" "info"    "${infotxt:-<none>}"
    emit "$leg" "returned" "1"

    printf '  %-22s %-12s %s\n' "$leg" "$state" \
           "${trail:-$(printf '%.90s' "$infotxt")}"

    kill -9 "$praat_pid" "$gui_pid" "$wm_pid" "$xvfb_pid" >/dev/null 2>&1
    wait "$praat_pid" "$gui_pid" 2>/dev/null
    unset DISPLAY
    sleep 1
}

# ---------------------------------------------------------------------------
LEG_N=0
ran=0
while IFS=$'\t' read -r leg entry plan kind note; do
    case "$leg" in ''|'#'*|leg) continue ;; esac
    LEG_N=$((LEG_N + 1))
    if [ -n "$WANT" ]; then
        case " $WANT " in *" $leg "*) ;; *) continue ;; esac
    fi
    run_leg "$leg" "$entry" "$plan"
    ran=$((ran + 1))
done < "$LEGS_TSV"

echo "coldstart: $ran leg(s) driven against $SRC -> $TSV"
[ "$ran" -gt 0 ] || { echo "coldstart: drove nothing." >&2; exit 1; }
exit 0
