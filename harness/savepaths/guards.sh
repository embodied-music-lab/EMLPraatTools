#!/usr/bin/env bash
# ============================================================================
# savepaths/guards.sh — press SAVE with input the panel is supposed to refuse
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# WHY THIS SITS IN harness/savepaths AND NOT IN A HARNESS OF ITS OWN. The
# thing under test is @emlSavePanel, and harness/savepaths is where the panel
# is pressed. What run.sh cannot do is put HOSTILE input in front of it — its
# presser counts buttons from the end and types nothing, because until now
# nothing needed typing. Two of the three defects below are only reachable
# through a field: a slash has to be typed into Base name, and an unwritable
# folder has to be the one the panel proposes.
#
# WHY A SECOND ENTRY POINT AND NOT MORE LEGS IN run.sh. Two reasons, and the
# second is the load-bearing one:
#
#   1. v48 reads out/ and asserts of EVERY leg it finds that the panel came
#      up, that it reported a completed save, and that files landed. The
#      unwritable leg's whole point is that NO files land, so a leg of that
#      shape written into out/ would fail v48 for being correct. This runs
#      into guards_out/ instead, which v48 does not read and v56 does.
#   2. These legs are three minutes of Xvfb; run.sh's eleven are twenty. The
#      guards are the part most likely to be re-run while something is being
#      changed, and a drive nobody re-runs is a drive that goes stale.
#
# WHAT IT DRIVES
#
#   guards.praat        headless, procedure-level: every character the
#                       sanitiser claims, both shapes of unwritable target,
#                       the receipt's line breaks against the audit's own
#                       overprinted paths, and all four coercion shapes
#                       through @emlWrapperInit. Writes guards_out/GUARDS.tsv.
#   hostilename         GUI: a real analysis, a real Save panel, and
#                       `pre/post:v1*x?"a<b>c|d\e` TYPED into Base name. At
#                       HEAD this died inside the panel with "Cannot create
#                       file ... one of the folders in this file path does not
#                       exist", taking the receipt, the panel's return and the
#                       caller's Done|Save|Draw|New loop with it.
#   unwritable          GUI: the same analysis with HOME on a READ-ONLY
#                       tmpfs, so the folder the panel proposes is the one it
#                       cannot write. At HEAD: "unexpected error 30", same
#                       death. Praat starts perfectly well with a read-only
#                       home — measured — which is what makes this leg need
#                       no typing at all.
#
# THE READ-ONLY FOLDER IS A MOUNT, NOT A chmod. This sandbox runs Praat as
# root, and root ignores permission bits; the audit's own G12 leg recorded
# `chmod 555` as USELESS for exactly this reason and left the finding
# unreproduced. A read-only tmpfs is refused by the kernel for everyone. If
# the mount is unavailable the drive says so in guards_out/RO.txt and v56
# reports that evidence MISSING rather than passing over it.
#
# THE PRESSER IS A SMALLER COUSIN OF run.sh's and deliberately not shared:
# run.sh is being changed by other work, and a shared function is a shared
# blast radius. What IS shared is leg.praat — the same table builder handing
# off to the same shipped wrapper by runScript:, so these legs go through the
# shipped barrel exactly as the other eleven do.
#
# Run from anywhere:  bash harness/savepaths/guards.sh
# Then:               Rscript validate/v56_save_guards.R
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
OUT="$SCRIPT_DIR/guards_out"
WORK="$OUT/work"
PRAAT="${PRAAT:-praat}"

# THE TREE UNDER TEST. Unset it is the shipped plugin; $EML_GUARDS_PLUGIN
# points the drive at a deliberately broken copy, which is how every check in
# v56 was shown red before it was believed. guards.praat's `include` lines are
# relative to ITS OWN folder, so a break test copies guards.praat next to the
# broken tree rather than editing the include.
PLUGIN_ROOT="${EML_GUARDS_PLUGIN:-$REPO}"

rm -rf "$OUT"
mkdir -p "$WORK"

command -v "$PRAAT" >/dev/null || { echo "guards: FAIL — no praat"; exit 1; }

# ---------------------------------------------------------------------------
# THE READ-ONLY TARGET
# ---------------------------------------------------------------------------
RO="$WORK/ro"
mkdir -p "$RO"
if mount -t tmpfs -o ro tmpfs "$RO" 2>/dev/null && ! touch "$RO/probe" 2>/dev/null
then
    echo "$RO" > "$OUT/RO.txt"
else
    # NAMED, NOT SKIPPED. A drive that quietly drops the only case that
    # reproduces a severity-2 finding reports a clean run over an untested
    # guard, which is worse than a red line.
    : > "$OUT/RO.txt"
    echo "guards: WARNING — no read-only mount available; NEW-G12-5 evidence" \
         "will be reported MISSING by v56"
fi
RO_PATH="$(cat "$OUT/RO.txt")"

cleanup_ro () {
    [[ -n "${RO_PATH:-}" ]] && umount "$RO" 2>/dev/null
}

# ---------------------------------------------------------------------------
# PART 1 — the headless drive
# ---------------------------------------------------------------------------
# guards.praat includes the stats modules by relative path, so it must be run
# from a folder that sits two levels under the tree being tested. For the
# shipped tree that is this folder; for a break test it is a copy of this
# folder placed inside the broken tree.
GP_DIR="$SCRIPT_DIR"
if [[ "$PLUGIN_ROOT" != "$REPO" ]]; then
    GP_DIR="$PLUGIN_ROOT/harness/savepaths"
    mkdir -p "$GP_DIR"
    cp "$SCRIPT_DIR/guards.praat" "$GP_DIR/guards.praat"
fi

HPREFS="$WORK/prefs_headless"
rm -rf "$HPREFS"; mkdir -p "$HPREFS"
rm -f "$HPREFS/pid" "$HPREFS/message" 2>/dev/null
( cd "$GP_DIR" && EML_GUARDS_OUT="$OUT" EML_GUARDS_RO="$RO_PATH" \
    "$PRAAT" --pref-dir="$HPREFS" --run guards.praat \
    > "$OUT/guards_headless.log" 2>&1 )
HRC=$?
echo "guards: headless drive exit $HRC, $(wc -l < "$OUT/GUARDS.tsv" 2>/dev/null || echo 0) measurement(s)"

# ---------------------------------------------------------------------------
# PART 2 — the two GUI legs
# ---------------------------------------------------------------------------
for tool in xdotool Xvfb xprop matchbox-window-manager import; do
    command -v "$tool" >/dev/null || {
        echo "guards: GUI legs SKIPPED — no $tool"
        cleanup_ro
        exit 0
    }
done

# :86 rather than run.sh's :88, so the two drives can run at once. Several
# agents share this machine and a display number is a global.
DISP=":86"
Xvfb "$DISP" -screen 0 1400x1000x24 > "$WORK/xvfb.log" 2>&1 &
XVFB_PID=$!
sleep 2
DISPLAY="$DISP" matchbox-window-manager -use_titlebar no > "$WORK/wm.log" 2>&1 &
WM_PID=$!
sleep 2

cleanup () {
    # -x, NEVER -f. `pkill -f praat` matches this script's own command line
    # through the driving shell and kills the run itself.
    pkill -9 -x praat 2>/dev/null
    kill "$WM_PID" "$XVFB_PID" 2>/dev/null
    cleanup_ro
}
trap cleanup EXIT

# Window lookup walks _NET_CLIENT_LIST via xprop rather than `xdotool search`,
# for the reasons GUI_HARNESS_RECIPE §11 gives: search reads WM_NAME, which
# GTK leaves unset for titles containing an em dash, and it returns the
# unmapped husk of every dismissed dialog forever.
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

pausewait () {
    local waited=0
    while [[ $waited -lt $1 ]]; do
        if pauseinfo; then return 0; fi
        sleep 2
        waited=$((waited + 2))
    done
    return 1
}

# AN ERROR DIALOG IS INVISIBLE TO pauseinfo — Praat's error window carries no
# window name at all — so a run that hits one otherwise reports a short clean
# chain and no files, and a hard failure reads as a mild one. That is exactly
# how both defects in this file presented before they were found.
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

press () {   # press <window-id> <n-from-end>
    DISPLAY="$DISP" xdotool windowactivate --sync "$1" 2>/dev/null
    sleep 1
    DISPLAY="$DISP" xdotool key --clearmodifiers --repeat "$2" shift+Tab 2>/dev/null
    sleep 1
    # XTEST, not XSendEvent: `xdotool key --window <id>` sends a synthetic
    # event GTK ignores.
    DISPLAY="$DISP" xdotool key --clearmodifiers Return 2>/dev/null
}

# TYPING INTO Base name, and the count is measured rather than assumed.
# Driven by hand on 15 Aug 2026 against the real panel: from the form's
# initial focus, shift+Tab lands on Save (1), Cancel (2), Undo (3) and the
# Base name entry (4). The entry's text arrives pre-selected, so typing
# REPLACES it — checked by screenshot rather than inferred, because a count
# that is one out appends to the folder field instead and the leg would still
# look like it worked.
type_base () {   # type_base <window-id> <text>
    DISPLAY="$DISP" xdotool windowactivate --sync "$1" 2>/dev/null
    sleep 1
    DISPLAY="$DISP" xdotool key --clearmodifiers --repeat 4 shift+Tab 2>/dev/null
    sleep 1
    DISPLAY="$DISP" xdotool key --clearmodifiers ctrl+a 2>/dev/null
    DISPLAY="$DISP" xdotool type --clearmodifiers "$2"
    sleep 1
}

# ---------------------------------------------------------------------------
# A LEG
# ---------------------------------------------------------------------------
# $1 leg name   $2 HOME for the run   $3 base name to type ("" = leave it)
run_guard_leg () {
    local leg="$1" lhome="$2" typebase="$3"
    local LOUT="$WORK/$leg"
    mkdir -p "$LOUT"
    local PREFS="$LOUT/prefs"
    rm -rf "$PREFS"; mkdir -p "$PREFS"
    # Only the lock files, never the whole pref dir mid-run: a stale lock
    # makes Praat exit with "An instance of Praat that is not me is already
    # running", which reads as a harness bug.
    rm -f "$PREFS/pid" "$PREFS/message" 2>/dev/null

    local TSV="$LOUT/DIALOGS.tsv"
    : > "$TSV"

    ( cd "$SCRIPT_DIR" && DISPLAY="$DISP" HOME="$lhome" \
        EML_WRAPPER="$PLUGIN_ROOT/plugin/scripts/eml-compare-groups.praat" \
        EML_SAVE_OUT="$LOUT" EML_RECIPE="twogroup" \
        "$PRAAT" --pref-dir="$PREFS" --utf8 --new-send leg.praat \
        > "$LOUT/driver.log" 2>&1 ) &
    local PRAAT_PID=$!
    sleep 10

    local step=0 acVisit=0 line wid title rev label
    while [[ $step -lt 10 ]]; do
        line=$(pausewait 30) || break
        wid=${line%%$'\t'*}
        title=${line#*$'\t'}
        step=$((step + 1))

        rev=1; label="LAST"
        case "$title" in
            "Compare Two Groups")  rev=1; label="Run" ;;
            "Analysis complete"|"Analysis Complete")
                acVisit=$((acVisit + 1))
                case $acVisit in
                    1) rev=3; label="Save" ;;
                    *) rev=4; label="Done" ;;
                esac ;;
            "Save")                rev=1; label="Save" ;;
            "Saved")               rev=1; label="OK" ;;
            "Nothing saved")       rev=1; label="OK" ;;
            # THE GUARD'S OWN DIALOG. Its presence in this column is the
            # finding: at HEAD there was no dialog here at all, only Praat's
            # error window and a dead session.
            "Cannot save there")   rev=1; label="OK" ;;
            *)                     rev=1; label="LAST" ;;
        esac

        printf '%d\t%s\t%s\t%d\n' "$step" "$title" "$label" "$rev" >> "$TSV"

        # THE PANEL AND THE RECEIPT ARE BOTH PHOTOGRAPHED. What the panel
        # PROPOSES is not recoverable afterwards from the files it wrote, and
        # the receipt is a defect whose only symptom is ink: the overprint
        # cannot be read out of any file, so the picture IS the evidence.
        if [[ "$title" == "Save" ]]; then
            DISPLAY="$DISP" import -window "$wid" "$LOUT/PANEL.png" 2>/dev/null
            if [[ -n "$typebase" ]]; then
                type_base "$wid" "$typebase"
                printf '%d\ttyped\t%s\t0\n' "$step" "$typebase" >> "$TSV"
                DISPLAY="$DISP" import -window "$wid" "$LOUT/TYPED.png" 2>/dev/null
                DISPLAY="$DISP" xdotool key --clearmodifiers Return 2>/dev/null
                sleep 3
                local ew2
                if ew2=$(errorwin); then
                    DISPLAY="$DISP" import -window "$ew2" "$LOUT/ERROR.png" 2>/dev/null
                    printf 'ERROR\tafter typing into "%s"\tsee ERROR.png\t0\n' \
                           "$title" >> "$TSV"
                    break
                fi
                continue
            fi
        fi
        if [[ "$title" == "Saved" ]]; then
            DISPLAY="$DISP" import -window "$wid" "$LOUT/RECEIPT.png" 2>/dev/null
        fi
        if [[ "$title" == "Cannot save there" ]]; then
            DISPLAY="$DISP" import -window "$wid" "$LOUT/REFUSAL.png" 2>/dev/null
        fi

        press "$wid" "$rev"
        sleep 3

        local ew
        if ew=$(errorwin); then
            DISPLAY="$DISP" import -window "$ew" "$LOUT/ERROR.png" 2>/dev/null
            printf 'ERROR\tafter %s on "%s"\tsee ERROR.png\t0\n' \
                   "$label" "$title" >> "$TSV"
            echo "guards: $leg — Praat raised an error after $label on \"$title\""
            break
        fi
    done

    # NO `wait`. Praat is a GUI session: when the driven script ends the
    # process stays up with its Objects window, so waiting on it blocks
    # forever and the collection below never runs.
    kill "$PRAAT_PID" 2>/dev/null
    pkill -9 -x praat 2>/dev/null
    sleep 2

    local ATSV="$LOUT/ARTEFACTS.tsv"
    : > "$ATSV"
    while IFS= read -r f; do
        [[ "$(basename "$f")" == "eml-graphs-config.txt" ]] && continue
        printf '%s\t%s\n' "$(basename "$f")" "$(stat -c%s "$f")" >> "$ATSV"
    done < <(find "$lhome" -maxdepth 2 \
             \( -name '*.csv' -o -name '*.png' -o -name '*.txt' \) \
             -type f 2>/dev/null | sort)

    cp "$TSV"  "$OUT/$leg.dialogs.tsv"   2>/dev/null
    cp "$ATSV" "$OUT/$leg.artefacts.tsv" 2>/dev/null
    for shot in PANEL TYPED RECEIPT REFUSAL ERROR; do
        [[ -f "$LOUT/$shot.png" ]] && \
            cp "$LOUT/$shot.png" "$OUT/$leg.$(echo "$shot" | tr 'A-Z' 'a-z').png"
    done
    echo "guards: $leg — $(wc -l < "$TSV") dialog(s), $(wc -l < "$ATSV") artefact(s)"
}

# ---------------------------------------------------------------------------
# LEG hostilename — NEW-G2-1
# ---------------------------------------------------------------------------
# Every character the sanitiser claims, in one name, typed into the field a
# user types into. "/" alone reproduces the finding on this filesystem; the
# rest are here because the panel's contract is cross-platform and a name is
# a thing users carry between machines.
HN_HOME="$WORK/home_hostile"
rm -rf "$HN_HOME"; mkdir -p "$HN_HOME"
run_guard_leg "hostilename" "$HN_HOME" 'pre/post:v1*x?"a<b>c|d\e'

# ---------------------------------------------------------------------------
# LEG plainname — the regression guard, and the receipt's photograph
# ---------------------------------------------------------------------------
# THE SAME JOURNEY WITH NOTHING TYPED. Two things only this leg can settle.
# First, that the guards cost the ordinary path nothing: the proposed name is
# taken as offered, the folder is the proposed one, and the save completes as
# it did before. Second, the receipt itself — this is the leg whose paths are
# the long ones (out/work/plainname/home is 70-odd characters before a file
# name), so its RECEIPT.png is the picture that used to show three paths in
# five lines of overlapping ink and now shows each path wrapped, once.
# harness/savepaths photographs the Save panel and never photographed this
# one, which is why five sightings of the same fault were filed separately.
PN_HOME="$WORK/home_plain"
rm -rf "$PN_HOME"; mkdir -p "$PN_HOME"
run_guard_leg "plainname" "$PN_HOME" ""

# ---------------------------------------------------------------------------
# LEG unwritable — NEW-G12-5
# ---------------------------------------------------------------------------
# HOME is the read-only mount, so emlLastCSVFolder$ seeds from it and the
# panel PROPOSES the folder it cannot write. Nothing is typed: the defect is
# reached by the default.
if [[ -n "$RO_PATH" ]]; then
    run_guard_leg "unwritable" "$RO_PATH" ""
else
    echo "guards: unwritable — SKIPPED, no read-only mount"
fi

echo "guards: done"
