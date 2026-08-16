#!/usr/bin/env bash
# ============================================================================
# harness/release/run.sh — the release artefact, installed and opened
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# WHAT THIS IS FOR. plugin/dev/tools/build-release.py produces the folder
# Praat installs — plugin_EML_Praat_Tools — and a zip of it, and verifies
# every mode in what it built. All of that is a statement about a directory.
# It says nothing whatever about whether Praat, given that directory, comes
# up with an EML menu on it, and a packaging step that has never been
# installed is the same shape of claim as a menu entry that has never been
# clicked (harness/batchgui, and the audit's severity-2 dead doors).
#
# So this harness takes THE ZIP — not the build directory, and not the
# repository — unpacks it into a scratch preferences directory exactly as a
# user would, and starts Praat against it under Xvfb.
#
# THREE LEGS, and the third is the one that makes the first two mean
# anything:
#
#   quickstart  Headless. plugin/README.md's own 30-second example, run by
#               `praat --run` from a script OUTSIDE the plugin, against the
#               unpacked folder. It reads five files out of the installed
#               tree and prints a t-test. This is the leg that would go red
#               on finding P1 read from another account: a file at 0600 is
#               not "the menu looks wrong", it is `include` failing to open
#               a file. It also needs no window manager, so it fails loudly
#               on a machine where the GUI legs cannot run at all.
#
#   installed   The real thing. Praat --pref-dir=<unpacked>, the Objects
#               window's New menu opened, the EML Tools cascade entered, and
#               a fixed keyboard walk to the eighteenth command. It must
#               reach `Pause: Create Demo Table`. A photograph of the open
#               submenu is taken on the way past, for a human.
#
#   broken      THE FALSIFIER. The same zip, unpacked again, with ONE LINE
#               inserted at the top of setup.praat that Praat cannot parse.
#               The plugin folder is present and correctly named, every file
#               is readable, and the registration never runs — so the walk
#               must NOT reach Create Demo Table. Without this leg, "we
#               reached the dialog" is a sentence that could hold with the
#               plugin uninstalled, and the install proof would be
#               decorative. Praat is required to be UP in this leg
#               (objects_window=1), so a red here cannot be "Praat did not
#               start" wearing the falsifier's clothes.
#
# WHY A KEYBOARD WALK RATHER THAN READING THE MENU. GTK menu items have no X
# window of their own and no queryable property, so nothing can read the text
# of a menu item. The machine-readable fact about a menu item is which dialog
# a fixed walk arrives at. Up-then-Right enters the cascade without depending
# on how many commands Praat's own New menu carries; GTK skips separators
# during keyboard navigation, so the count is the ORDINAL AMONG COMMANDS —
# 18 of 18, Create Demo Table. Same route as harness/batchgui/run.sh and
# `emlitem` in harness/gui.sh; keep the three in step.
#
#   bash harness/release/run.sh
#   Rscript validate/v79_release_artefact.R
#
# Evidence, all under out/: RELEASE_INSTALL.tsv (the scalar facts),
# menu_installed.png (the submenu, open), dialog_installed.png (the dialog it
# reached), menu_broken.png (the same walk with the registration dead) and
# QUICKSTART.txt (the Info window from the headless leg).
#
# Scratch — the unpacked trees, the build, Xvfb and Praat's logs — lives
# outside the repository under $TMPDIR, as in harness/walks/rig.sh and
# harness/gui.sh. $EML_RELEASE_WORK moves it, $EML_RELEASE_OUT the evidence
# folder, $EML_RELEASE_DISPLAY the display.
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
BUILDER="$REPO/plugin/dev/tools/build-release.py"

OUT="${EML_RELEASE_OUT:-$SCRIPT_DIR/out}"
WORK="${EML_RELEASE_WORK:-${TMPDIR:-/tmp}/eml-release-harness}"
DISP="${EML_RELEASE_DISPLAY:-:90}"

# The submenu's eighteenth command. Stale here means this harness walks to
# the neighbour and says so by reaching the wrong dialog — it does not fail
# silently, which is the whole reason the walk is the assertion.
ORDINAL="${EML_RELEASE_ORDINAL:-18}"
WANT_TITLE="${EML_RELEASE_TITLE:-Create Demo Table}"

for t in Xvfb xdotool xprop xwininfo import matchbox-window-manager unzip \
         python3 iconv; do
    command -v "$t" >/dev/null || { echo "release: FAIL — no $t" >&2; exit 1; }
done
[[ -x "$PRAAT"   ]] || { echo "release: FAIL — no praat at $PRAAT" >&2; exit 1; }
[[ -f "$BUILDER" ]] || { echo "release: FAIL — no $BUILDER" >&2; exit 1; }

# THE FLOOR IS ASSERTED, NOT ASSUMED — the v52 rule. A green install on a
# build below the plugin's own floor is not evidence about the plugin; below
# 6.6.30 setup.praat refuses to register anything at all, which would make
# the falsifier and the positive leg agree for a reason that has nothing to
# do with packaging.
PV="$("$PRAAT" --version 2>&1 | head -1)"
PVN="$(printf '%s' "$PV" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
PVI=$(awk -F. '{printf "%d", $1*1000 + $2*100 + $3}' <<< "${PVN:-0.0.0}")
if [[ "$PVI" -lt 6630 ]]; then
    echo "release: FAIL — $PV is below the plugin's 6.6.30 floor." >&2
    exit 1
fi

rm -rf "$WORK"
mkdir -p "$WORK" "$OUT"
rm -f "$OUT"/*.png "$OUT"/*.tsv "$OUT"/*.txt

TSV="$OUT/RELEASE_INSTALL.tsv"
: > "$TSV"
say () { printf '%s\t%s\n' "$1" "$2" >> "$TSV"; }

say praat_version "$PV"

# ---------------------------------------------------------------------------
# 1. BUILD, AND TAKE THE NAME FROM THE BUILD RATHER THAN FROM HERE
# ---------------------------------------------------------------------------
# This file does not contain the string plugin_EML_Praat_Tools and must not.
# The builder reads the install name out of stats/eml-record.praat and writes
# it into RELEASE.tsv; everything below uses that. A harness carrying its own
# copy of the name could pass against an artefact built under a different one.
python3 "$BUILDER" --out "$WORK/dist" > "$WORK/build.log" 2>&1
BUILD_RC=$?
say build_rc "$BUILD_RC"
if [[ "$BUILD_RC" -ne 0 ]]; then
    echo "release: FAIL — the build did not verify:" >&2
    cat "$WORK/build.log" >&2
    exit 1
fi

REC="$WORK/dist/RELEASE.tsv"
NAME=$(awk -F'\t' '$1=="name"{print $2}' "$REC")
ZIP="$WORK/dist/$(awk -F'\t' '$1=="zip"{print $2}' "$REC")"
say name "$NAME"
say artefact_sha256 "$(awk -F'\t' '$1=="artefact_sha256"{print $2}' "$REC")"
say zip_sha256 "$(awk -F'\t' '$1=="zip_sha256"{print $2}' "$REC")"
[[ -f "$ZIP" ]] || { echo "release: FAIL — no zip at $ZIP" >&2; exit 1; }

# ---------------------------------------------------------------------------
# 2. INSTALL — FROM THE ZIP, WHICH IS WHAT A USER DOWNLOADS
# ---------------------------------------------------------------------------
install_zip () {   # install_zip <prefsdir>
    rm -rf "$1"; mkdir -p "$1"
    ( cd "$1" && unzip -q "$ZIP" )
}

PREFS_OK="$WORK/prefs_installed"
PREFS_BAD="$WORK/prefs_broken"
install_zip "$PREFS_OK"
install_zip "$PREFS_BAD"

[[ -d "$PREFS_OK/$NAME" ]] || {
    echo "release: FAIL — the zip did not unpack a $NAME folder" >&2; exit 1; }

# $EML_SETUP_FILE REPLACES THE REGISTRATION IN THE INSTALLED TREE — the same
# override name v52, v59 and v72 already use, so one break test drives every
# harness and validator that reads the same file. It exists so that "the
# plugin is installed and the menu does not appear" can be produced on
# demand, without going near the shipped file. Unset in a real run.
if [[ -n "${EML_SETUP_FILE:-}" ]]; then
    cp "$EML_SETUP_FILE" "$PREFS_OK/$NAME/setup.praat"
    chmod 0644 "$PREFS_OK/$NAME/setup.praat"
fi
say setup_under_test "${EML_SETUP_FILE:-shipped}"

# THE SETUP DIGEST IS THE STALENESS HANDLE, and it is taken from the tree
# that was actually installed rather than from the build record, so an
# override cannot leave a digest behind claiming the shipped file was driven.
# What decides whether a menu appears is setup.praat, so v79 compares this
# against the shipped file and goes red when the registration has changed
# since anybody last installed the artefact and looked. Tying the staleness
# to the WHOLE artefact digest would make every edit anywhere in the plugin
# demand a GUI re-drive.
say setup_sha256 "$(sha256sum "$PREFS_OK/$NAME/setup.praat" | cut -d' ' -f1)"
say unpacked_folder "$(basename "$PREFS_OK/$NAME")"
say unpacked_files "$(find "$PREFS_OK/$NAME" -type f | wc -l)"
say unpacked_modes_other_than_0644_0755 \
   "$(find "$PREFS_OK/$NAME" \! -perm 0644 \! -perm 0755 | wc -l)"

# THE DAMAGE. Two shapes, because they fail differently and a check that
# only survives one of them is only half a check. $EML_RELEASE_DAMAGE picks.
#
#   syntax      (default) One line at the top that Praat cannot parse:
#               `Add menu command:` with one argument. setup.praat dies on
#               line 1, not a single registration runs, and Praat puts up a
#               modal error naming the plugin. The plugin is installed,
#               correctly named and fully readable, and there is no menu.
#
#   unregister  Every `Add menu command: "Objects", "New", ...` line cut, and
#               nothing else. setup.praat PARSES, Praat comes up clean with
#               no error dialog at all, the New menu opens normally — and the
#               EML Tools cascade is not in it. This is the sharper
#               falsifier: it proves the walk discriminates rather than
#               merely being blocked by a modal, which is all the syntax
#               variant can show.
BROKEN_SETUP="$PREFS_BAD/$NAME/setup.praat"
DAMAGE="${EML_RELEASE_DAMAGE:-syntax}"
case "$DAMAGE" in
  syntax)
    printf '%s\n' 'Add menu command: "Objects"' > "$WORK/_hdr"
    cat "$WORK/_hdr" "$BROKEN_SETUP" > "$WORK/_bad" ;;
  unregister)
    grep -v -E '^Add menu command: "Objects", "New"' "$BROKEN_SETUP" \
        > "$WORK/_bad" ;;
  *) echo "release: FAIL — unknown EML_RELEASE_DAMAGE=$DAMAGE" >&2; exit 1 ;;
esac
mv "$WORK/_bad" "$BROKEN_SETUP"
chmod 0644 "$BROKEN_SETUP"
say broken_damage "$DAMAGE"
say broken_setup_lines_cut \
   "$(( $(wc -l < "$PREFS_OK/$NAME/setup.praat") - $(wc -l < "$BROKEN_SETUP") ))"
say broken_setup_first_line "$(head -1 "$BROKEN_SETUP")"

# ---------------------------------------------------------------------------
# 3. LEG quickstart — HEADLESS, AND IT READS THE INSTALLED FILES
# ---------------------------------------------------------------------------
# plugin/README.md's Quick Start, verbatim except for the last line writing
# the Info window to a file so this is text rather than a photograph, and run
# from a script OUTSIDE the plugin folder. `include` accepts a leading ~
# (measured here on 6.6.30, and on 6.4.06 and 7.0 per the note in
# stats/eml-record.praat), and HOME is pointed at the pref dir so the tilde
# resolves to the folder the plugin was unpacked into.
cat > "$WORK/quickstart.praat" << QEOF
include ~/$NAME/stats/eml-core-utilities.praat
include ~/$NAME/stats/eml-core-descriptive.praat
include ~/$NAME/stats/eml-extract.praat
include ~/$NAME/stats/eml-output.praat
include ~/$NAME/stats/eml-inferential.praat

trained# = {195, 210, 188, 203, 197, 215, 192, 208}
untrained# = {165, 172, 158, 180, 163, 170, 155, 168}

@emlTTest: trained#, untrained#, 2, 0
@emlFormatP: emlTTest.p
appendInfoLine: "t(", fixed\$(emlTTest.df, 1), ") = ",
... fixed\$(emlTTest.t, 2), ", ", emlFormatP.formatted\$
writeFile: "$WORK/quickstart.out", info\$ ()
QEOF

HOME="$PREFS_OK" "$PRAAT" --pref-dir="$WORK/prefs_qs" --run \
    "$WORK/quickstart.praat" > "$WORK/quickstart.log" 2>&1
say quickstart_rc "$?"
if [[ -f "$WORK/quickstart.out" ]]; then
    if file -b "$WORK/quickstart.out" | grep -q UTF-16; then
        iconv -f UTF-16 -t UTF-8 "$WORK/quickstart.out" > "$OUT/QUICKSTART.txt"
    else
        cp "$WORK/quickstart.out" "$OUT/QUICKSTART.txt"
    fi
    say quickstart_line "$(tr -d '\r' < "$OUT/QUICKSTART.txt" | head -1)"
else
    cp "$WORK/quickstart.log" "$OUT/QUICKSTART.txt"
    say quickstart_line ""
fi

# ---------------------------------------------------------------------------
# 4. THE DISPLAY
# ---------------------------------------------------------------------------
rm -f "/tmp/.X${DISP#:}-lock" "/tmp/.X11-unix/X${DISP#:}"
Xvfb "$DISP" -screen 0 1400x1100x24 > "$WORK/xvfb.log" 2>&1 &
XVFB_PID=$!
sleep 3
DISPLAY="$DISP" matchbox-window-manager -use_titlebar no > "$WORK/wm.log" 2>&1 &
WM_PID=$!
sleep 2

cleanup () {
    # -x, NEVER -f. `pkill -f praat` matches this script's own command line
    # through the driving shell and kills the run itself (exit 144).
    pkill -9 -x praat 2>/dev/null
    kill "$WM_PID" "$XVFB_PID" 2>/dev/null
}
trap cleanup EXIT

# ---------------------------------------------------------------------------
# 5. WINDOW LOOKUP — _NET_CLIENT_LIST, never `xdotool search --name`
# ---------------------------------------------------------------------------
# search reads WM_NAME, which GTK leaves unset for any title carrying a
# character outside Latin-1, and it returns the unmapped husk of every
# dismissed dialog forever. GUI_HARNESS_RECIPE §11.
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
pausewin () { winlist | awk -F'\t' '$2 ~ /^Pause: / {print substr($2, 8); exit}'; }
pausewait () {
    local waited=0 hit
    while [[ $waited -lt $1 ]]; do
        hit=$(pausewin); [[ -n "$hit" ]] && { printf '%s\n' "$hit"; return 0; }
        sleep 2; waited=$((waited + 2))
    done
    return 1
}

# The client origin is xwininfo's "Absolute upper-left", NOT xdotool's
# getwindowgeometry Position: under matchbox the two disagree by the frame
# inset, and a click 4 px right and 20 px low lands in the gap between two
# widgets, where nothing happens and nothing errors.
origin () {
    DISPLAY="$DISP" xwininfo -id "$1" \
        | awk '/Absolute upper-left X/{x=$NF} /Absolute upper-left Y/{y=$NF}
               END{print x, y}'
}
clickin () {
    local o; o=$(origin "$1")
    DISPLAY="$DISP" xdotool mousemove $(( ${o% *} + $2 )) $(( ${o#* } + $3 )) \
        click --clearmodifiers 1 2>/dev/null
    sleep 1
}

start_praat () {   # start_praat <prefdir>
    rm -f "$1/pid" "$1/message" 2>/dev/null
    ( DISPLAY="$DISP" HOME="$1" "$PRAAT" --pref-dir="$1" --utf8 \
        > "$WORK/praat_$(basename "$1").log" 2>&1 ) &
    sleep 12
}
stop_praat () { pkill -9 -x praat 2>/dev/null; sleep 3; }

walk_to_entry () {   # walk_to_entry <menu-shot> -> leaves a dialog, maybe
    local shot="$1" objw
    objw=$(winid_by_name "Praat Objects")
    [[ -n "$objw" ]] || return 1
    DISPLAY="$DISP" xdotool windowactivate --sync "$objw" 2>/dev/null
    sleep 1
    clickin "$objw" 72 14          # the "New" menubar label
    sleep 2
    DISPLAY="$DISP" xdotool key --clearmodifiers Up;    sleep 1
    DISPLAY="$DISP" xdotool key --clearmodifiers Right; sleep 2
    DISPLAY="$DISP" import -window root "$shot" 2>/dev/null
    if [[ "$ORDINAL" -gt 1 ]]; then
        DISPLAY="$DISP" xdotool key --clearmodifiers \
            --repeat $((ORDINAL - 1)) --delay 120 Down
    fi
    sleep 1
    DISPLAY="$DISP" xdotool key --clearmodifiers Return
    sleep 4
}

# ---------------------------------------------------------------------------
# LEG installed
# ---------------------------------------------------------------------------
start_praat "$PREFS_OK"
OBJ_OK=$([[ -n "$(winid_by_name "Praat Objects")" ]] && echo 1 || echo 0)
say installed_objects_window "$OBJ_OK"
walk_to_entry "$OUT/menu_installed.png"
TITLE_OK=$(pausewait 30) || TITLE_OK=""
if [[ -z "$TITLE_OK" ]]; then
    # One retry, then it stands. An empty title is not "the wrong dialog", it
    # is NO EVIDENCE, and read carelessly it looks like the falsifier passing.
    stop_praat; start_praat "$PREFS_OK"
    walk_to_entry "$OUT/menu_installed.png"
    TITLE_OK=$(pausewait 30) || TITLE_OK=""
fi
say installed_dialog_title "$TITLE_OK"
DISPLAY="$DISP" import -window root "$OUT/dialog_installed.png" 2>/dev/null
say installed_windows "$(winlist | cut -f2 | paste -sd'|' -)"
stop_praat

# ---------------------------------------------------------------------------
# LEG broken
# ---------------------------------------------------------------------------
start_praat "$PREFS_BAD"
OBJ_BAD=$([[ -n "$(winid_by_name "Praat Objects")" ]] && echo 1 || echo 0)
say broken_objects_window "$OBJ_BAD"
walk_to_entry "$OUT/menu_broken.png"
TITLE_BAD=$(pausewait 12) || TITLE_BAD=""
say broken_dialog_title "$TITLE_BAD"
say broken_windows "$(winlist | cut -f2 | paste -sd'|' -)"
stop_praat

# ---------------------------------------------------------------------------
# 6. THE VERDICT, WRITTEN DOWN AS WELL AS EXITED
# ---------------------------------------------------------------------------
MENU_PRESENT=0
[[ "$TITLE_OK" == "$WANT_TITLE" ]] && MENU_PRESENT=1
say want_dialog_title "$WANT_TITLE"
say menu_ordinal "$ORDINAL"
say menu_present "$MENU_PRESENT"
FALSIFIED=0
[[ "$TITLE_BAD" != "$WANT_TITLE" ]] && FALSIFIED=1
say falsifier_ok "$FALSIFIED"
say completed 1

echo "--- $TSV ---"
cat "$TSV"

rc=0
[[ "$OBJ_OK" -eq 1 ]] || { echo "release: FAIL — Praat did not come up on the installed tree" >&2; rc=1; }
[[ "$OBJ_BAD" -eq 1 ]] || { echo "release: FAIL — Praat did not come up on the broken tree, so the falsifier proves nothing" >&2; rc=1; }
[[ "$MENU_PRESENT" -eq 1 ]] || { echo "release: FAIL — the walk reached '$TITLE_OK', wanted '$WANT_TITLE'" >&2; rc=1; }
[[ "$FALSIFIED" -eq 1 ]] || { echo "release: FAIL — the walk reached '$WANT_TITLE' with the registration dead; the install proof is decorative" >&2; rc=1; }
exit $rc
