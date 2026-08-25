#!/usr/bin/env bash
# ============================================================================
# harness/posthocgate/run.sh — every door, on a fixture whose omnibus is not
#                              significant and whose post-hoc was chosen
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# WHY THIS EXISTS. Punch list lane 3 rules that a post-hoc the user chose runs
# on every door, whatever the omnibus says, and that when the omnibus is not
# significant the report says so in one line. Before the ruling four sites
# disagreed with it, and three of the four took the post-hoc AWAY — silently,
# with the user's choice still showing on the dialog behind them. Silence is
# not something a check can read out of a number: it has to be driven, and
# what it produced has to be recorded.
#
# THE FIXTURE IS BUILT SO THAT SILENCE IS VISIBLE.
# fixture_kgroups.csv gives one-way ANOVA F(2, 21) = 2.346, p = .120 and
# Kruskal-Wallis H(2) = 3.515, p = .173 — both above .05 and above .01, so
# every gate that ever existed here is CLOSED on it — while Soprano vs Alto is
# separated far enough that Tukey (p = .101), Dunn and Scheffe all have
# something to print. A door that ran the post-hoc and a door that swallowed
# it therefore differ in whole blocks of report text and in whether the figure
# carries any bracket at all.
#
# TWO KINDS OF LEG, and they answer different questions:
#
#   HEADLESS (doors.praat, `praat --run`, one process per leg) — the menu
#   doors and the graph bridge, driven at their orchestrators, one captured
#   report per leg in out/<leg>.txt. This is the same kind of evidence as
#   harness/broom_cases: the shipping procedure on the committed fixture, not
#   a session someone clicked through.
#
#   GUI (the wizard) — `praat --run` REFUSES to build a pause window at all,
#   so the wizard cannot be driven headlessly and a headless transform of it
#   would be a model of the wizard rather than the wizard. What runs here is
#   an ordinary GUI Praat under Xvfb with the fixture table selected and the
#   wizard command sent into it, its pages answered by XTEST clicks, and its
#   Info window read back out of the live instance afterwards. Every measured
#   fact about how a Praat pause window is clicked comes from
#   harness/coldstart/run.sh and harness/coldstart/page.py, which are the
#   files to change if the theme or the toolkit ever moves. page_wide.py
#   IMPORTS coldstart's reader rather than copying it, and overrides one
#   measurement — see its header for the page that forced that.
#
# $EML_PHG_SRC points the whole rig at a DIFFERENT plugin tree, which is how
# the red demonstration is run: a worktree of the pre-fix commit is driven by
# this file unmodified, so what goes red is this harness rather than a
# rehearsal of it. Same idiom as $EML_COLDSTART_SRC.
#
# Usage:
#   bash harness/posthocgate/run.sh                 # every leg
#   bash harness/posthocgate/run.sh headless        # skip the GUI leg
#   EML_PHG_SRC=/path/to/tree EML_PHG_OUT=/path/out bash .../run.sh
#
# Output:
#   $OUT/<leg>.txt         one captured report per headless leg
#   $OUT/wizard_scheffe.info.txt   the wizard's Info window, as the user sees it
#   $OUT/wizard_scheffe.trail      the page titles the wizard walk met, in order
#   $OUT/POSTHOCGATE.tsv   leg <TAB> key <TAB> value — what v122 reads
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
. "$ROOT/harness/_env.sh" || { echo "posthocgate: no Praat; refusing" >&2; exit 2; }

SRC="${EML_PHG_SRC:-$ROOT/plugin_EML_StatsGraphs}"
OUT="${EML_PHG_OUT:-$SCRIPT_DIR/out}"
MODE="${1:-all}"

# THE RIG PROVES IT CAN RUN BEFORE IT CLEARS ANYTHING — harness/coldstart's
# rule, for the reason given there: a driver that empties its output folder and
# then finds it has no plugin tree has turned a missing dependency into deleted
# evidence.
[ -d "$SRC/scripts" ] || {
    echo "posthocgate: REFUSED — no plugin tree at $SRC. Nothing was cleared." >&2
    exit 2; }
[ -f "$SCRIPT_DIR/fixture_kgroups.csv" ] || {
    echo "posthocgate: REFUSED — no fixture. Nothing was cleared." >&2; exit 2; }
if [ "$MODE" != "headless" ]; then
    for tool in Xvfb xdotool xprop xwininfo import python3 iconv od \
                matchbox-window-manager; do
        command -v "$tool" >/dev/null 2>&1 || {
            echo "posthocgate: REFUSED — '$tool' not on PATH. Nothing was cleared." >&2
            exit 2; }
    done
fi

mkdir -p "$OUT"
TSV="$OUT/POSTHOCGATE.tsv"
printf 'leg\tkey\tvalue\n' > "$TSV"
emit () { printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$TSV"; }

emit rig src "$SRC"
emit rig praat "$("$PRAAT" --version 2>&1 | head -1)"

# ---------------------------------------------------------------------------
# HEADLESS LEGS
# ---------------------------------------------------------------------------
# The alpha column is the point of the two _a01 legs: the caution line names
# the level in force, and a literal .05 in the code would survive alpha = .01
# unchanged. Driving both is what makes that a measurement.
HEADLESS_LEGS="
anova_tukey                 .
anova_notukey               .
kw_dunn                     .
kw_nodunn                   .
pairwise_scheffe            .
pairwise_welch_bh           .
wizard_scheffe_dispatch     .
rm_posthoc                  .
friedman_posthoc            .
bridge_kw_matrix            .
bridge_kw_brackets          .
bridge_anova_brackets       .
bridge_anova_matrix         .
anova_tukey                 0.01
kw_dunn                     0.01
anova_tukey_sig              .
kw_dunn_sig                  .
"

# doors.praat resolves the plugin by relative path from its own folder. A run
# against ANOTHER tree gets a generated copy whose includes are absolute, so
# the red demonstration drives this file unmodified against the pre-fix
# worktree instead of a rehearsal of it.
DOORS="$SCRIPT_DIR/doors.praat"
if [ "$SRC" != "$ROOT/plugin_EML_StatsGraphs" ]; then
    sed "s|\.\./\.\./plugin/|$SRC/|g" "$SCRIPT_DIR/doors.praat" > "$OUT/doors_src.praat"
    DOORS="$OUT/doors_src.praat"
    # AND THE FIXTURES GO WITH IT. Praat resolves a runtime file path against
    # the SCRIPT'"'"'s folder, not the working directory, so the generated copy
    # would look for the fixture beside itself and refuse. Measured, first run
    # of the red demonstration: fifteen legs, every one of them "Cannot open
    # file", which is a rig failure that could have been read as the pre-fix
    # tree refusing the fixture.
    cp "$SCRIPT_DIR"/fixture_*.csv "$OUT/"
fi

run_headless () {
    local leg alpha name rc
    while read -r leg alpha; do
        [ -n "$leg" ] || continue
        name="$leg"
        [ "$alpha" = "." ] || name="${leg}_alpha$(printf '%s' "$alpha" | tr -d '.')"
        ( cd "$SCRIPT_DIR" && \
          EML_PHG_LEG="$leg" \
          EML_PHG_ALPHA="$([ "$alpha" = "." ] && echo "" || echo "$alpha")" \
          timeout 180 "$PRAAT" $PRAAT_TRUST --run "$DOORS" \
          > "$OUT/$name.txt" 2>&1 )
        rc=$?
        emit "$name" "returned" "$rc"
        emit "$name" "alpha" "$alpha"
        if grep -q "^== END " "$OUT/$name.txt" 2>/dev/null; then
            emit "$name" "complete" "1"
        else
            emit "$name" "complete" "0"
        fi
        printf '  %-28s rc=%-3s %s lines\n' "$name" "$rc" \
               "$(wc -l < "$OUT/$name.txt")"
    done <<< "$(printf '%s\n' "$HEADLESS_LEGS" | sed '/^[[:space:]]*$/d')"
}

if [ "${EML_PHG_SKIP_HEADLESS:-0}" != "1" ]; then
    echo "posthocgate: headless legs (src = $SRC)"
    run_headless
fi

[ "$MODE" = "headless" ] && { echo "posthocgate: headless only, as asked."; exit 0; }

# ---------------------------------------------------------------------------
# THE WIZARD LEG
# ---------------------------------------------------------------------------
# The plan, one step per page, answering the branch this lane is about:
#
#   EML Stats Wizard                 Research goal   = 1  Compare
#   Compare — Observation type       Observation     = 1  different groups
#   Compare independent — Design     Group design    = 2  three or more
#   Three+ groups — Select columns   answered by its own seeds — see below
#   Three or More Groups — Test      Test            = 3  Scheffe row
#
# and then Run. The Scheffe row is the row that carried "if ANOVA significant"
# in its own label, and it is the row whose post-hoc the pre-fix wizard threw
# away on this fixture.
#
# THE COLUMN PAGE IS LEFT ON ITS OWN SEEDS, AND THAT IS A MEASUREMENT, NOT A
# SHORTCUT. Driving its two optionmenus with the click-Home-Down-Return recipe
# leaves the first menu's popup holding a pointer grab on this GTK build — the
# captured page shows it as a black rectangle over the Data column row — and
# the next click lands in the popup instead of on Continue, so the walk stops
# one page short. Measured three times, at 1.2s and at 2s of settle; it is not
# a race. What the page is seeded with is @wizardPrepareTable's column-role
# guess, and on this fixture (one numeric column, one text column) that guess
# is F0_Hz by voice_type — which is what the leg wants. It is not ASSUMED to
# be: v122 reads the columns back out of the report the run produced and
# fails if they are not those two, so a seed that ever changes shows up as a
# red check rather than as a leg quietly measuring the wrong analysis.
WIZ_LEG="wizard_scheffe"
WIZ_PLAN="1:1;1:1;1:2;-;1:3"

XT () { timeout 20 "$@"; }

# Every primitive below is harness/coldstart/run.sh's, and the measured facts
# behind them are documented there: the pause window is found through
# _NET_CLIENT_LIST (GTK leaves WM_NAME unset for a title with an em dash, and
# every wizard page title has one), the geometry is xwininfo's client area
# (matchbox's frame is 4 across and 20 down, and mixing the two puts every
# click on the wrong button), the buttons and combos are READ off the page by
# page.py rather than predicted, and nothing is captured while a combo popup is
# open because the popup holds a pointer grab.
ph_pausewin () {
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

ph_geom () {
    XT xwininfo -id "$1" 2>/dev/null | awk '
        /Absolute upper-left X/ { x = $4 }
        /Absolute upper-left Y/ { y = $4 }
        /^  Width:/  { w = $2 }
        /^  Height:/ { h = $2 }
        END { if (w == "") exit 1; print x, y, w, h }'
}

ph_read () {
    PH_COMBOS=""; PH_BUTTONS=""
    XT import -window "$1" "$2" 2>/dev/null || return 1
    local line
    while IFS= read -r line; do
        case "$line" in
            combos*)  PH_COMBOS="${line#combos}" ;;
            buttons*) PH_BUTTONS="${line#buttons}" ;;
        esac
    done < <(timeout 30 python3 "$SCRIPT_DIR/page_wide.py" "$2" 2>/dev/null)
    [ -n "$PH_BUTTONS" ]
}

ph_press () {
    local X Y W H
    read -r X Y W H < <(ph_geom "$1") || return 1
    XT xdotool mousemove $((X + $2)) $((Y + H - 36)) click 1
    sleep 1
}

ph_setcombo () {
    local X Y W H k j
    read -r X Y W H < <(ph_geom "$1") || return 1
    XT xdotool mousemove $((X + W - 19)) $((Y + $2)) click 1
    sleep 1.2
    XT xdotool key --clearmodifiers Home; sleep 0.4
    k=$(( $3 - 1 ))
    for ((j = 0; j < k; j++)); do XT xdotool key --clearmodifiers Down; sleep 0.3; done
    XT xdotool key --clearmodifiers Return
    # TWO SECONDS, NOT ONE. Measured on this rig, 25 Aug 2026: with 1.2s the
    # SECOND combo on the column page was still holding its pointer grab when
    # the walk pressed Continue, so the click dismissed the popup instead of
    # pressing the button, no new page ever appeared, and the leg stopped one
    # page short of the analysis it exists to read. The captured page shows
    # the open popup as a black rectangle — which is the same grab
    # harness/coldstart warns never to capture through.
    sleep 2
}

ph_settle () {
    local old="$1" log="$2" t p
    for ((t = 0; t < 40; t++)); do
        sleep 0.5
        grep -q "PRAAT ERROR MESSAGE" "$log" 2>/dev/null && { echo ""; return 0; }
        p=$(ph_pausewin) || continue
        [ "${p%%|*}" = "$old" ] && continue
        echo "$p"; return 0
    done
    echo ""
    return 0
}

run_wizard () {
    local leg="$WIZ_LEG" plan="$WIZ_PLAN"
    local disp home log trail step id title p n_steps nth val
    log="$OUT/$leg.log"
    home="$OUT/work/$leg"
    rm -rf "$home"; mkdir -p "$home/prefs"

    # A display claimed by PROBING, never by arithmetic — harness/coldstart's
    # rule, and for its reason: computing one and clearing its lock deletes a
    # neighbouring harness's socket out from under it.
    local dn probe
    disp=""
    for ((dn = ${EML_PHG_DISPLAY_BASE:-140} + 1; dn <= ${EML_PHG_DISPLAY_BASE:-140} + 60; dn++)); do
        probe=":$dn"
        DISPLAY="$probe" timeout 5 xdpyinfo >/dev/null 2>&1 && continue
        [ -e "/tmp/.X11-unix/X$dn" ] && continue
        disp="$probe"
        break
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
        kill -9 "$wm_pid" "$xvfb_pid" >/dev/null 2>&1
        return 0
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
    # the instance we started gave it — coldstart's measurement: a SIGUSR1 that
    # lands before Praat installs its handler KILLS the instance, and the
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
        kill -9 "$gui_pid" "$wm_pid" "$xvfb_pid" >/dev/null 2>&1
        return 0
    fi

    # THE FIXTURE IS SELECTED BEFORE THE WIZARD IS ASKED ANYTHING. The wizard
    # reads the selected Table; with nothing selected it invents example data
    # and the leg would be measuring the demo table instead of the fixture.
    printf 'tbl = Read Table from comma-separated file: "%s"\nselectObject: tbl\n' \
        "$SCRIPT_DIR/fixture_kgroups.csv" > "$home/setup.praat"
    HOME="$home" DISPLAY="$disp" timeout 30 "$PRAAT" \
        --pref-dir="$home/prefs" --utf8 $PRAAT_TRUST \
        --send "$home/setup.praat" >>"$log" 2>&1
    sleep 1

    HOME="$home" DISPLAY="$disp" timeout 30 "$PRAAT" \
        --pref-dir="$home/prefs" --utf8 $PRAAT_TRUST \
        --send "$SRC/scripts/eml-wizard.praat" >>"$log" 2>&1

    for ((t = 0; t < 40; t++)); do
        ph_pausewin >/dev/null && break
        grep -q "PRAAT ERROR MESSAGE" "$log" 2>/dev/null && break
        sleep 0.5
    done

    trail=""
    n_steps=0
    local IFSOLD="$IFS"
    IFS=';' read -r -a steps <<< "$plan"
    IFS="$IFSOLD"
    for step in "${steps[@]}"; do
        p=$(ph_pausewin) || break
        id="${p%%|*}"; title="${p#*|}"
        trail="${trail:+$trail > }$title"
        ph_read "$id" "$home/page$n_steps.png" || { emit "$leg" "read_fail" "step$n_steps"; break; }
        read -r -a ys <<< "$PH_COMBOS"
        read -r -a bx <<< "$PH_BUTTONS"
        if [ -n "$step" ] && [ "$step" != "-" ]; then
            local IFS2="$IFS"; IFS=',' read -r -a ops <<< "$step"; IFS="$IFS2"
            for op in "${ops[@]}"; do
                nth="${op%%:*}"; val="${op##*:}"
                if [ "${#ys[@]}" -lt "$nth" ]; then
                    emit "$leg" "plan_miss" "step$n_steps wanted combo $nth, page has ${#ys[@]}"
                    continue
                fi
                ph_setcombo "$id" "${ys[$((nth - 1))]}" "$val"
                sleep 0.8
            done
            sleep 1
            ph_read "$id" "$home/page$n_steps.png" >/dev/null 2>&1
            read -r -a bx <<< "$PH_BUTTONS"
        fi
        [ "${#bx[@]}" -gt 0 ] || { emit "$leg" "no_button" "step$n_steps"; break; }
        ph_press "$id" "${bx[$(( ${#bx[@]} - 1 ))]}"
        n_steps=$((n_steps + 1))
        p=$(ph_settle "$id" "$log")
        [ -n "$p" ] || break
    done
    p=$(ph_pausewin) && trail="${trail:+$trail > }${p#*|}"
    emit "$leg" "steps" "$n_steps"
    emit "$leg" "trail" "$trail"
    printf '%s\n' "$trail" > "$OUT/$leg.trail"

    # WHAT THE INSTANCE SAYS, ASKED OF THE INSTANCE. Decoded first: Praat
    # writes the whole file UTF-16BE the moment one character leaves ASCII,
    # and this report is full of them.
    rm -f "$home/objects.txt"
    sed "s|@OUT@|$home/objects.txt|" "$ROOT/harness/coldstart/probe_objects.praat" \
        > "$home/probe.praat"
    HOME="$home" DISPLAY="$disp" timeout 30 "$PRAAT" \
        --pref-dir="$home/prefs" --utf8 $PRAAT_TRUST \
        --send "$home/probe.praat" >/dev/null 2>&1
    # WAITED FOR, NOT RACED. `--send` delivers the script and RETURNS; the
    # instance writes the file a moment later, in its own event loop. The
    # first version of this line asked immediately and recorded `no_info`
    # against a probe whose 5,336 bytes landed a second afterwards.
    for ((t = 0; t < 40; t++)); do
        [ -s "$home/objects.txt" ] && break
        sleep 0.5
    done
    if [ -s "$home/objects.txt" ]; then
        case "$(head -c2 "$home/objects.txt" | od -An -tx1 | tr -d ' ')" in
            feff|fffe) iconv -f UTF-16 -t UTF-8 "$home/objects.txt" \
                           > "$OUT/$leg.info.txt" 2>/dev/null \
                       || cp "$home/objects.txt" "$OUT/$leg.info.txt" ;;
            *)         cp "$home/objects.txt" "$OUT/$leg.info.txt" ;;
        esac
        emit "$leg" "info_bytes" "$(wc -c < "$OUT/$leg.info.txt")"
        emit "$leg" "state" "walked"
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
    printf '  %-28s %s\n' "$leg" "$trail"
}

echo "posthocgate: wizard leg"
run_wizard

echo "posthocgate: wrote $TSV"
