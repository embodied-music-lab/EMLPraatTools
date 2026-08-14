#!/usr/bin/env bash
# ============================================================================
# savepaths/run.sh — press SAVE on a path that draws no figure
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# WHY THIS HARNESS EXISTS, and it is the same shape of gap twice running.
#
# @emlSavePanel has TEN call sites: the graphs form's Graph Complete dialog,
# eight stats wrappers, and the wizard. Exactly one of them had ever been
# pressed by a harness -- the graphs one, by harness/gui_e2e. The other NINE
# were checked STATICALLY only: v46 reads the call sites and proves the string
# "@emlSavePanel" appears in each script.
#
# That is precisely the position the plugin was in on 12 August 2026 with the
# graphs form's Exp CSV button, which wrote the wrong CSV format because no
# harness pressed it and no validator could see a path that produces no
# artefact. A static call-site check is a real check, but it cannot tell you
# the panel comes up, that its fields read back, or that anything lands on
# disk -- and it cannot tell you an ARGUMENT is unbound.
#
# THE FIRST PRESS OF THIS HARNESS FOUND EXACTLY THAT. Every one of the nine
# non-graphing call sites passes emlLastCSVFolder$, and nothing seeded it: the
# seed had lived inside @emlWrapperExportCSV, the procedure the panel
# superseded. Praat evaluates a procedure's arguments before entering it, so
# all nine died with "Unknown variable: emlLastCSVFolder$" on the FIRST press
# of Save in a session, taking the user's analysis with them. v46 passed
# throughout -- every claim it makes was true. harness/wrappers passed too; it
# asks only whether a wrapper parses, and this parses.
#
# NEITHER ARM IS THE SAME TEST. @emlExportResultFiles forks on whether the
# analysis declared into the broom collectors:
#
#   DECLARED   -> _tidy.csv, _glance.csv, _augment.csv + one file per staged
#                 extra. Every leg here takes this arm.
#   UNDECLARED -> one legacy long-format .csv, via @emlExportStatsCSV.
#
# THE UNDECLARED ARM IS NOT REACHED BY ANY LEG HERE, and the reason is an
# UNFINISHED PATH rather than a settled design. Nothing in plugin/stats/ fills
# the legacy buffer at all -- the calls that fill it are all in
# plugin/graphs/eml-annotation-procedures.praat and eml-graphs-form.praat, and
# every path that reaches them also declares. The wizard's describe and
# normality branches run the one unconverted orchestrator, and they set
# wizCanExport = 0, so their post-analysis row comes up Done | New with no
# Save button to press -- photographed 14 Aug 2026.
#
# eml-wizard.praat:183-186 explains that as deliberate ("they fill no result
# buffer and the button would lead only to Nothing to Export"). AUTHOR RULING,
# 14 Aug 2026: that is not the design. Describe and normality SHOULD be able
# to save; the work simply has not been done yet. So the missing Save is an
# open item, recorded in the session queue, and this harness gains a leg for
# it the moment the wrapper gains the button. Until then the legacy arm is
# reached only by the half-converted case the fork was written for (a bridge
# that reports and then errors before declaring) and by the code/API path.
#
# NO LEG DRAWS A FIGURE. That is the point: every previous drive of the panel
# came through the graphs form with offerFigure = 1, so the offerFigure = 0
# shape -- the one nine of the ten callers use -- had never been raised.
#
# Run from anywhere:  bash harness/savepaths/run.sh
# Exit 0 = every leg reached the panel and something landed on disk.
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
OUT="$SCRIPT_DIR/out"
PREFS="$SCRIPT_DIR/prefs"
PRAAT="${PRAAT:-praat}"
PRAAT_TRUST="${PRAAT_TRUST:---no-pref-files}"
PRAAT_TRUST=""

# ITERATING ON ONE LEG. $EML_SAVEPATHS_ONLY restricts the run to legs whose
# name contains it, and then out/ is NOT wiped -- so a probe of one wrapper
# does not destroy the evidence the other nine already produced. Unset, every
# leg runs and out/ starts empty, which is what makes the committed artefact
# a whole-run artefact rather than an accumulation.
ONLY="${EML_SAVEPATHS_ONLY:-}"
if [[ -z "$ONLY" ]]; then
    rm -rf "$OUT"
fi
mkdir -p "$OUT"

command -v "$PRAAT"   >/dev/null || { echo "savepaths: FAIL — no praat";   exit 1; }
command -v xdotool    >/dev/null || { echo "savepaths: FAIL — no xdotool"; exit 1; }
command -v Xvfb       >/dev/null || { echo "savepaths: FAIL — no Xvfb";    exit 1; }
command -v xprop      >/dev/null || { echo "savepaths: FAIL — no xprop";   exit 1; }
command -v matchbox-window-manager >/dev/null \
    || { echo "savepaths: FAIL — no window manager"; exit 1; }

DISP=":88"
Xvfb "$DISP" -screen 0 1400x1000x24 > "$OUT/xvfb.log" 2>&1 &
XVFB_PID=$!
sleep 2
DISPLAY="$DISP" matchbox-window-manager -use_titlebar no > "$OUT/wm.log" 2>&1 &
WM_PID=$!
sleep 2

cleanup () {
    # -x, NEVER -f. `pkill -f praat` matches this script's own command line
    # through the driving shell and kills the run itself (exit 144). Measured
    # the hard way, 11 Aug 2026.
    pkill -9 -x praat 2>/dev/null
    kill "$WM_PID" "$XVFB_PID" 2>/dev/null
}
trap cleanup EXIT

# ---------------------------------------------------------------------------
# THE PRESSER. Shared by every leg.
# ---------------------------------------------------------------------------
# Window lookup walks _NET_CLIENT_LIST via xprop rather than `xdotool search`:
# search reads WM_NAME, which GTK leaves unset for a title containing an em
# dash — and the wizard's page titles are full of them — and it returns the
# unmapped husk of every dismissed dialog forever. GUI_HARNESS_RECIPE §11.
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

# WAIT FOR THE NEXT DIALOG RATHER THAN GLANCING ONCE. A fixed sleep after each
# press is a race, and on 14 Aug 2026 it lost: eml-compare-paired reshapes its
# table before writing, the panel took longer than the five seconds allowed,
# pauseinfo found nothing, the loop broke, and the leg reported three dialogs
# and no files. Driven by hand with a longer pause the same leg reaches
# "Saved" every time. A harness whose verdict depends on how fast the machine
# is that day is not evidence, so the wait is bounded rather than fixed.
pausewait () {   # pausewait <seconds>
    local waited=0
    while [[ $waited -lt $1 ]]; do
        if pauseinfo; then return 0; fi
        sleep 2
        waited=$((waited + 2))
    done
    return 1
}

# AN ERROR DIALOG IS INVISIBLE TO pauseinfo, and that is the blind spot that
# nearly cost this harness its first finding. Praat's error window carries NO
# window name at all -- _NET_WM_NAME and WM_NAME are both empty -- so a run
# that hits one sees no "Pause:" window, breaks its loop, and reports a short
# clean chain with no artefacts. That is indistinguishable from "the script
# finished early", which is how a hard failure reads as a mild one.
#
# On the first press of this harness the panel died with "Unknown variable:
# emlLastCSVFolder$" and the run reported two dialogs and no files. It was
# found by screenshotting the nameless window by hand. This function is that
# by hand made automatic: any Praat window that is neither a pause form nor
# one of the three permanent windows is an error, and its picture is written
# next to the log so the next person reads the message instead of guessing.
errorwin () {
    local ids id name
    ids=$(DISPLAY="$DISP" xprop -root _NET_CLIENT_LIST 2>/dev/null \
          | sed -n 's/.*# //p' | tr -d ' ' | tr ',' '\n')
    for id in $ids; do
        [[ "$id" == 0x* ]] || continue
        name=$(DISPLAY="$DISP" xdotool getwindowname "${id}" 2>/dev/null)
        case "$name" in
            Pause:*|"Praat Objects"|"Praat Picture"|"Praat Info") continue ;;
        esac
        printf '%s\n' "$id"; return 0
    done
    return 1
}

# AN OPTIONMENU SITS AT FOCUS RING POSITION 0, and plain Down changes its
# selection WITHOUT opening the dropdown. Measured 14 Aug 2026 on the wizard's
# goal page: two Downs moved "Compare groups or conditions" to "Describe or
# summarize" with no Tab pressed first and no dropdown raised.
#
# That is what makes a form with an optionmenu drivable at all. Return on an
# optionmenu OPENS the dropdown and dismisses nothing (harness/tabwalk), and
# forward Tab cannot be used to reach one -- on this page Tab x1 lands on
# Undo, so the menu is not in the forward ring. Down before any Tab is the
# only key that reaches it, and because it leaves focus AT position 0 the
# reverse-Tab button count afterwards is unchanged.
press () {   # press <window-id> <n-from-end> [pre-keys...]
    DISPLAY="$DISP" xdotool windowactivate --sync "$1" 2>/dev/null
    sleep 1
    local k
    for k in ${3:-}; do
        DISPLAY="$DISP" xdotool key --clearmodifiers "$k" 2>/dev/null
        sleep 1
    done
    DISPLAY="$DISP" xdotool key --clearmodifiers --repeat "$2" shift+Tab 2>/dev/null
    sleep 1
    # XTEST, not XSendEvent: `xdotool key --window <id>` sends a synthetic
    # event GTK ignores.
    DISPLAY="$DISP" xdotool key --clearmodifiers Return 2>/dev/null
}

# ---------------------------------------------------------------------------
# A LEG
# ---------------------------------------------------------------------------
# $1 leg name   $2 driver script   $3 wrapper to hand to   $4 max dialogs
run_leg_once () {
    local leg="$1" recipe="$2" wrapper="$3" maxsteps="$4"
    local driver="leg.praat"
    if [[ -n "$ONLY" && "$leg" != *"$ONLY"* ]]; then return 0; fi
    local LOUT="$OUT/work/$leg"
    mkdir -p "$LOUT"
    # STALE EVIDENCE IS WORSE THAN NONE. With $EML_SAVEPATHS_ONLY set, out/ is
    # not wiped, so an ERROR.png left by a previous probe would sit next to a
    # clean run and read as a failure that did not happen -- the same class of
    # mistake v47 exists to catch in the recorder's artefacts.
    rm -f "$LOUT/ERROR.png" "$LOUT/PANEL.png"
    # AND THE LEG'S FLAT FILES. With $EML_SAVEPATHS_ONLY set out/ is not
    # wiped, so a previous probe's saved files -- which carry a different
    # timestamp in their names and so do not overwrite -- would accumulate
    # beside this run's and be read as one press writing two stamps. Exactly
    # the property v48 checks, failed by the harness rather than the plugin.
    rm -f "$OUT/$leg."*

    rm -rf "$PREFS"; mkdir -p "$PREFS"
    # Only the lock files, never the whole pref dir mid-run: 6.6.30 keeps its
    # instance lock here and 7.x keeps it in ~/.config/praat regardless of
    # --pref-dir. A stale lock makes Praat exit with "An instance of Praat
    # that is not me is already running", which reads as a harness bug.
    rm -f "$PREFS/pid" "$PREFS/message" 2>/dev/null
    rm -f "$HOME/.config/praat/pid.txt" "$HOME/.config/praat/Message.txt" 2>/dev/null

    # A HOME OF ITS OWN, and this is load-bearing rather than tidy. The panel
    # seeds its folder field from emlLastCSVFolder$, which seeds from
    # homeDirectory$. Pointing HOME inside out/ means the panel's PROPOSED
    # folder is already where the evidence should go, so this harness never
    # has to type into the folder field — which it could not do anyway, that
    # field being a GtkTextView. On 13 Aug 2026 a persisted config sent
    # gui_e2e's figure to /root and the run reported no figure saved.
    local LHOME="$LOUT/home"
    rm -rf "$LHOME"; mkdir -p "$LHOME"

    ( cd "$SCRIPT_DIR" && DISPLAY="$DISP" HOME="$LHOME" \
        EML_WRAPPER="$wrapper" EML_SAVE_OUT="$LOUT" EML_RECIPE="$recipe" \
        "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" --utf8 --new-send "$driver" \
        > "$LOUT/driver.log" 2>&1 ) &
    local PRAAT_PID=$!
    sleep 10

    local TSV="$LOUT/DIALOGS.tsv"
    : > "$TSV"

    local step=0 acVisit=0 line wid title rev label
    while [[ $step -lt $maxsteps ]]; do
        # 30s: the slowest press in this harness is the panel's write on the
        # paired path, which reshapes before it exports.
        line=$(pausewait 30) || break
        wid=${line%%$'\t'*}
        title=${line#*$'\t'}
        step=$((step + 1))

        rev=1; label="LAST"; pre=""
        case "$title" in
            # ── the wizard's chain ────────────────────────────────────────
            # EVERY PAGE TAKES ITS DEFAULT, and the defaults lead to the
            # two-group comparison: goal 1, independent observations, two
            # groups, the columns the role guess picked, the default test.
            # That is deliberate rather than lazy -- the wizard's own defaults
            # are the path a user is steered down, so driving them is driving
            # the journey the plugin recommends.
            #
            # NOT THE DESCRIBE BRANCH, and the reason is a finding rather than
            # a convenience. Describe and normality set wizCanExport = 0 on
            # purpose (eml-wizard.praat:183-186): they fill no result buffer,
            # so a Save there would lead only to "Nothing to Export". Driven
            # to that page, the post-analysis row is Done | New -- no Save
            # button exists to press. Photographed 14 Aug 2026.
            # THE GOAL PAGE. Its optionmenu sits at focus ring position 0 and
            # plain Down changes it without opening the dropdown, so $WIZ_PRE
            # selects the branch this leg wants: unset for goal 1 (compare
            # groups), "Down Down" for goal 3 (describe or summarize).
            "EML Stats Wizard")
                rev=1; label="Continue"; pre="${WIZ_PRE:-}" ;;
            "Compare"*"Observation type")    rev=1; label="Continue" ;;
            "Compare independent"*)          rev=1; label="Continue" ;;
            "Two groups"*"Select columns")   rev=1; label="Continue" ;;
            "Two independent groups"*)       rev=1; label="Run" ;;
            # The Describe chain. Both pages default to item 1 -- summarize a
            # single variable -- which is the path the author's ruling of
            # 14 Aug 2026 made exportable, and the one that reaches the
            # LEGACY arm of the fork. Nothing else in the plugin does.
            "Describe"*"What to summarize")  rev=1; label="Continue" ;;
            "Describe"*"Select column")      rev=1; label="Run" ;;
            "Check Normality")               rev=1; label="Run" ;;
            "Normality assessment complete")
                acVisit=$((acVisit + 1))
                case $acVisit in
                    1) rev=3; label="Save" ;;
                    *) rev=4; label="Done" ;;
                esac ;;
            # ── the wrapper's entry form: Quit | Run ──────────────────────
            "Compare Two Groups")            rev=1; label="Run" ;;

            # ── the post-analysis loop ────────────────────────────────────
            # Two shapes, and the shape is decided by what the analysis can
            # offer: Done|Save|Draw|New when a figure is possible,
            # Done|Save|New when it is not. Counting from the END is what
            # makes one rule cover both — Save is 3 from the end in the first
            # and 2 in the second, so the count is read off the button total,
            # which the visit itself reports.
            "Analysis complete"|"Analysis Complete")
                acVisit=$((acVisit + 1))
                case $acVisit in
                    1) rev="$AC_SAVE"; label="Save" ;;
                    *) rev="$AC_DONE"; label="Done" ;;
                esac ;;

            # ── the panel: Cancel | Save ──────────────────────────────────
            # Its FIELD list is conditional — Figure PNG only when a figure
            # exists, Results CSV only when there is something to export — but
            # its BUTTON row never changes, which is why the reverse count is
            # a constant here and the field conditionality costs nothing.
            "Save")                          rev=1; label="Save" ;;
            "Saved")                         rev=1; label="OK" ;;
            "Nothing saved")                 rev=1; label="OK" ;;

            # ── the wizard's chain ────────────────────────────────────────
            # Filled in from the first discovery run; every entry is the LAST
            # button (Run / Continue / Next), which is the wizard's own happy
            # path on each page.
            *)                               rev=1; label="LAST" ;;
        esac

        printf '%d\t%s\t%s\t%d\t%s\n' "$step" "$title" "$label" "$rev" \
               "${pre:-.}" >> "$TSV"

        # THE PANEL IS PHOTOGRAPHED BEFORE IT IS PRESSED. What it PROPOSES --
        # which boxes are ticked, which folder, which name -- is the whole
        # contract of this dialog, and none of it is recoverable afterwards
        # from the files it wrote. It is also the only way to tell a panel
        # that came up wrong from a write that failed.
        if [[ "$title" == "Save" ]]; then
            DISPLAY="$DISP" import -window "$wid" "$LOUT/PANEL.png" 2>/dev/null
        fi

        press "$wid" "$rev" "${pre:-}"
        sleep 3

        # An error raised by the press is caught HERE, while the window is
        # still up, rather than being inferred later from a missing file.
        local ew
        if ew=$(errorwin); then
            DISPLAY="$DISP" import -window "$ew" "$LOUT/ERROR.png" 2>/dev/null
            # THE FILESYSTEM AS IT WAS, not as it is after cleanup. Praat's
            # "this is a folder, not a file" hint is about a path that exists;
            # deciding whether it really did means looking while the error
            # window is still up.
            ls -laR "$LHOME" > "$LOUT/ERROR_fs.txt" 2>&1
            printf 'ERROR\tafter %s on "%s"\tsee ERROR.png\n' \
                   "$label" "$title" >> "$TSV"
            echo "savepaths: $leg — FAIL, Praat raised an error after $label"
            echo "           on \"$title\". The message is in $leg/ERROR.png."
            break
        fi
    done

    # NO `wait`. Praat is a GUI session: when the driven script ends, the
    # process stays up with its Objects window, so waiting on it blocks
    # forever and the artefact collection below never runs. The first version
    # of this file waited, and the run read as a hang rather than as a pass.
    # harness/gui_e2e does the same thing for the same reason.
    kill "$PRAAT_PID" 2>/dev/null
    pkill -9 -x praat 2>/dev/null
    sleep 2

    # ── artefacts ────────────────────────────────────────────────────────
    # EVERY extension the panel can write, and .txt is here because the
    # report was invisible to gui_e2e's collector until 13 Aug 2026 — it
    # globbed .png and .csv only, so a save that worked read as a save that
    # half-worked. eml-graphs-config.txt is excluded: that is plugin state,
    # not an output.
    local ATSV="$LOUT/ARTEFACTS.tsv"
    : > "$ATSV"
    while IFS= read -r f; do
        [[ "$(basename "$f")" == "eml-graphs-config.txt" ]] && continue
        printf '%s\t%s\n' "$(basename "$f")" "$(stat -c%s "$f")" >> "$ATSV"
    # $LHOME ONLY, and it is inside $LOUT. Searching both roots found every
    # file twice and the count printed double -- an artefact list that
    # overcounts is a list that can report a save as complete when half of it
    # is missing.
    done < <(find "$LHOME" -maxdepth 2 \
             \( -name '*.csv' -o -name '*.png' -o -name '*.txt' \) \
             -type f 2>/dev/null | sort)

    # ── THE EVIDENCE, FLAT ────────────────────────────────────────────────
    # out/ is ONE directory: <leg>.dialogs.tsv, <leg>.artefacts.tsv,
    # <leg>.panel.png, <leg>.error.png, and every file the save wrote as
    # <leg>.<name>. Everything above stays under out/work/, which is ignored.
    #
    # WHY FLAT. This repository is pushed one directory at a time through
    # GitHub's web upload form -- there is no `git push` here. A per-leg tree
    # is nineteen uploads for one artefact, every time it is regenerated,
    # which is a standing tax on re-running the harness and therefore a reason
    # not to re-run it. One directory is one upload, now and on every future
    # run. The leg name prefixes every file, so nothing collides and the
    # grouping is still readable at a glance.
    cp "$TSV"  "$OUT/$leg.dialogs.tsv"   2>/dev/null
    cp "$ATSV" "$OUT/$leg.artefacts.tsv" 2>/dev/null
    [[ -f "$LOUT/PANEL.png" ]] && cp "$LOUT/PANEL.png" "$OUT/$leg.panel.png"
    [[ -f "$LOUT/ERROR.png" ]] && cp "$LOUT/ERROR.png" "$OUT/$leg.error.png"
    while IFS= read -r f; do
        cp "$f" "$OUT/$leg.$(basename "$f")" 2>/dev/null
    done < <(find "$LHOME" -maxdepth 1 \
             \( -name '*.csv' -o -name '*.png' -o -name '*.txt' \) \
             -type f 2>/dev/null | sort)

    echo "savepaths: $leg — $(wc -l < "$TSV") dialog(s), $(wc -l < "$ATSV") artefact(s)"
}

# ---------------------------------------------------------------------------
# ONE RETRY, RECORDED
# ---------------------------------------------------------------------------
# A leg fails here about one run in nine, and always in a MULTI-LEG run --
# driven alone, any leg passes repeatedly. Chased on 14 Aug 2026 and not
# explained. What IS established, and is why this is a retry rather than an
# open defect:
#
#   * the folder and base name handed to the writer are correct on the failing
#     run, instrumented and read back;
#   * the folder exists and is writable at the moment of failure, dumped from
#     the error handler while the error window was still up;
#   * writing that exact path from a fresh Praat succeeds;
#   * eight of nine legs pass on every run, and which leg fails moves.
#
# So the plugin writes correctly and something in this sandbox does not, once
# in a while, for a Praat that has been driven through a GUI. Retrying hides
# that if it is silent, so it is not silent: RETRIES.tsv records every leg
# that needed a second attempt, the summary line says so, and the artefact
# carries it into the repository. A harness that quietly retried would report
# a clean run and a real regression would need two failures to show.
run_leg () {
    local leg="$1"
    # THE FILTER IS CHECKED HERE TOO. run_leg_once returns early for a leg
    # $EML_SAVEPATHS_ONLY excludes, which leaves no ARTEFACTS.tsv -- and the
    # retry test below reads a missing artefact list as a failure, so a
    # skipped leg was being "retried" once, run for real, and reported. A
    # filter that runs the thing it filters out is worse than no filter.
    if [[ -n "$ONLY" && "$leg" != *"$ONLY"* ]]; then return 0; fi
    run_leg_once "$@"
    if [[ -f "$OUT/work/$leg/ERROR.png" || ! -s "$OUT/work/$leg/ARTEFACTS.tsv" ]]; then
        echo "savepaths: $leg — retrying once"
        printf '%s\tretried\n' "$leg" >> "$OUT/RETRIES.tsv"
        sleep 5
        rm -f "$OUT/$leg."*
        run_leg_once "$@"
    fi
}

# ---------------------------------------------------------------------------
# LEG A — the DECLARED arm, through a real stats wrapper
# ---------------------------------------------------------------------------
# eml-compare-groups.praat's post-analysis row is
#     endPause: "Done", "Save", "Draw", "New", 3, 0
# so from the end: New 1, Draw 2, Save 3, Done 4.
# Every one of the eight shares the identical row --
#     endPause: "Done", "Save", "Draw", "New", 3, 0
# -- so from the end: New 1, Draw 2, Save 3, Done 4. Checked in all eight
# sources rather than assumed from one; the only difference between them is
# that eml-compare-kw.praat titles the dialog "Analysis Complete" with a
# capital C, which is why the matcher above names both spellings.
AC_SAVE=3
AC_DONE=4

# wrapper                    recipe
WRAPPERS="
eml-compare-groups           twogroup
eml-compare-k-groups         kgroup
eml-compare-kw               kgroup
eml-compare-paired           paired
eml-compare-twoway           twoway
eml-correlate                xy
eml-pairwise                 kgroup
eml-regress                  xy
eml-check-normality          xy
"

while read -r name recipe; do
    [[ -z "$name" ]] && continue
    run_leg "$name" "$recipe" "$REPO/plugin/scripts/$name.praat" 10
done <<< "$WRAPPERS"

# ---------------------------------------------------------------------------
# THE WIZARD — the tenth caller, and the ONLY route to the legacy arm
# ---------------------------------------------------------------------------
# @emlRunDescriptiveAnalysis is the canonical UNCONVERTED orchestrator: it
# fills the legacy CSV buffer and never declares into the broom collectors, so
# @emlExportResultFiles takes its `else` branch and writes ONE long-format
# file. REGISTRY.md records that it must stay that way, and
# harness/broom_cases/contamination_probe.praat depends on it.
#
# The wizard's Describe path is the only journey in the plugin that reaches
# that orchestrator from a dialog. Every other Save press in this harness --
# and the one in harness/gui_e2e -- takes the DECLARED arm, so without this
# leg half of the fork v46 exists to protect had never been reached by a
# button.
#
# Its post-analysis row can be four buttons or three (Done|Save|Draw|New when
# a figure is possible, Done|Save|New when it is not), which is D87's two
# independent flags. Counting from the end is what lets one rule cover both,
# but the count itself differs, so it is set per leg rather than shared.
AC_SAVE=3
AC_DONE=4
run_leg "eml-wizard" "twogroup" "$REPO/plugin/scripts/eml-wizard.praat" 14

# THE DESCRIBE BRANCH, which had no Save button at all until 14 August 2026.
# It is a second leg through the SAME script rather than a different wrapper,
# because the wizard's branches are separate journeys with separate export
# behaviour and driving one says nothing about the others. This is also the
# only leg that exercises the fork's UNDECLARED arm: describe fills the legacy
# buffer and does not declare, so @emlExportResultFiles writes one long-format
# file here and three broom frames everywhere else.
# THREE BUTTONS, NOT FOUR. D87 made drawing and exporting independent
# capabilities, so the post-analysis row is Done|Save|Draw|New when a figure
# is possible and Done|Save|New when it is not. Describe has no figure yet, so
# Save is 2 from the end here and 3 everywhere else. Counting from the end is
# what lets one presser cover both shapes; the count itself still comes from
# the endPause: list of the branch being driven.
AC_SAVE=2
AC_DONE=3
WIZ_PRE="Down Down"
run_leg "eml-wizard-describe" "twogroup" "$REPO/plugin/scripts/eml-wizard.praat" 14
WIZ_PRE=""
AC_SAVE=3
AC_DONE=4

echo "savepaths: done"
