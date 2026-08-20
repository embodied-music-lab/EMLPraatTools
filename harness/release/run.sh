#!/usr/bin/env bash
# ============================================================================
# harness/release/run.sh — the release artefact, installed and opened
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# WHAT THIS IS FOR. plugin/dev/tools/build-release.py produces the folder
# Praat installs — plugin_EML_StatsGraphs — and a zip of it, and verifies
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
# FIVE LEGS, and the last is the one that makes the others mean anything:
#
#   unpacked    Static, on the tree the zip produced. Four numbers, all
#               asserted: the folder count against the build record, every
#               mode 0644 or 0755 (the walk starts AT the plugin folder, so
#               the folder's own mode is in the count -- a zip with no entry
#               for its own root leaves that folder at the user's umask),
#               every `include` in every installed .praat resolving to a
#               file that is there, and the builder's own `--verify` re-run
#               against the UNPACKED tree rather than the build directory.
#               The include closure is what makes this leg worth its cost:
#               ONE library file dropped from the artefact leaves the menu
#               present, the walk green and five of the nineteen commands
#               dead on their first line, and no GUI leg can see that.
#
#   quickstart  Headless. plugin/README.md's own 30-second example, run by
#               `praat --run` from a script OUTSIDE the plugin, against the
#               unpacked folder. It reads five files out of the installed
#               tree and prints a t-test. A file at 0600 read from another
#               account is not "the menu looks wrong", it is `include`
#               failing to open a file, and this is the leg that says so. It
#               also needs no window manager, so it fails loudly on a
#               machine where the GUI legs cannot run at all. Its exit
#               status AND its printed line are both asserted: `praat --run`
#               exits 255 on a dead include while still writing nothing, so
#               an unread rc is an unread failure.
#
#   installed   The real thing. Praat --pref-dir=<unpacked>, the Objects
#               window's New menu opened, the EML Stats & Graphs cascade entered, and
#               a fixed keyboard walk to the eighteenth command. It must
#               reach `Pause: Create Demo Table`. A photograph of the open
#               submenu is taken on the way past.
#
#   menu name   THE PHOTOGRAPH IS READ. The walk is Up-then-Right, which is
#               POSITIONAL: it enters whatever cascade sits last in the New
#               menu, whatever that cascade is called. Register the plugin's
#               commands under "NOT THE EML MENU" and the walk still arrives
#               at Create Demo Table, and the only evidence that the user is
#               looking at the EML menu is the picture. So the picture goes
#               through tesseract -- the same instrument v76 uses to read a
#               test name off a rendered figure -- and the label is required
#               on the row the walk HIGHLIGHTED, cropped out and read on its
#               own, not merely somewhere on the screen. The falsifier's
#               photograph is read the same way and must NOT carry it. Two
#               anchors, because one of them is inside the file under test:
#               the reading of the photograph, and the cascade name
#               registered in the INSTALLED setup.praat. Both are compared
#               against $EML_RELEASE_MENU, which lives here.
#
#   broken      THE FALSIFIER. The same zip, unpacked again, with the
#               registration removed from setup.praat. The plugin folder is
#               present and correctly named, every file is readable, and the
#               registration never runs — so the walk must NOT reach Create
#               Demo Table. Without this leg, "we reached the dialog" is a
#               sentence that could hold with the plugin uninstalled, and
#               the install proof would be decorative. Praat is required to
#               be UP in this leg (objects_window=1), so a red here cannot
#               be "Praat did not start" wearing the falsifier's clothes.
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
# reached), menu_broken.png (the same walk with the registration dead),
# MENU_OCR.txt (both readings of menu_installed.png -- the page whole, then
# each highlighted row cropped and read on its own) and QUICKSTART.txt (the
# Info window from the headless leg).
#
# EVERY NUMBER IN THE TSV IS EITHER ASSERTED HERE OR READ BY v79. A scalar
# written by `say` and compared to nothing is decoration, and decoration next
# to a green tick reads as evidence: the mode counter and the quickstart exit
# status were both written and neither was ever looked at, so a run under a
# restrictive umask and a run whose headless leg died at exit 255 both left
# this harness exiting 0. The verdict block at the foot of this file is the
# list; if a `say` is added above and no line down there mentions it, it is
# not a measurement.
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

# THE BINARY COMES FROM harness/_env.sh, LIKE EVERY OTHER DRIVER'S.
# This file used to default to /usr/bin/praat on its own. That is the exact
# resolution _env.sh was written to remove: a bare system Praat can be any
# version, and a walk that installs the plugin and reads a menu off a
# screenshot is meaningless on a build whose setup.praat refuses to load it —
# while still producing a full, plausible, green transcript. _env.sh refuses
# anything below 6.6.30 instead of warning about it, and $PRAAT still
# overrides, so nothing that worked before stops working.
source "$(cd "$SCRIPT_DIR/.." && pwd)/_env.sh" || exit 1

REPO="$EML_ROOT"
BUILDER="$REPO/plugin/dev/tools/build-release.py"

OUT="${EML_RELEASE_OUT:-$SCRIPT_DIR/out}"
WORK="${EML_RELEASE_WORK:-${TMPDIR:-/tmp}/eml-release-harness}"
DISP="${EML_RELEASE_DISPLAY:-:90}"

# The submenu's eighteenth command. Stale here means this harness walks to
# the neighbour and says so by reaching the wrong dialog — it does not fail
# silently, which is the whole reason the walk is the assertion.
ORDINAL="${EML_RELEASE_ORDINAL:-18}"
WANT_TITLE="${EML_RELEASE_TITLE:-Create Demo Table}"

# THE CASCADE'S LABEL. Held here rather than read out of setup.praat, because
# setup.praat is the file under test: a harness that took the expected name
# from the thing it is checking would agree with any rename, which is the
# whole of what the positional walk cannot see.
WANT_MENU="${EML_RELEASE_MENU:-EML Stats & Graphs}"

for t in Xvfb xdotool xprop xwininfo import matchbox-window-manager unzip \
         python3 iconv tesseract; do
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
# This file does not contain the string plugin_EML_StatsGraphs and must not.
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
#
# IT IS A DIGEST OF THE CODE, NOT OF THE FILE. Whole-line comments -- a line
# whose first non-blank character is "#", ";" or "!", which is Praat's comment
# set -- are stripped before the digest is taken. The argument is the one in
# the paragraph above, applied one level down: an alarm that fires on every
# comment fix to setup.praat is an alarm that demands a GUI re-drive for a
# typo, and an alarm that expensive gets silenced. Nothing a comment says can
# change which menu appears or where a command points, so nothing a comment
# says can invalidate the walk. A trailing ";" comment after a statement is
# NOT stripped: that leaves the statement line in the digest, which is the
# conservative direction. v79 restates this recipe and must stay in step.
eml_code_sha256 () { sed -E '/^[[:space:]]*[#;!]/d' "$1" | sha256sum | cut -d' ' -f1; }
say setup_sha256 "$(eml_code_sha256 "$PREFS_OK/$NAME/setup.praat")"
say unpacked_folder "$(basename "$PREFS_OK/$NAME")"
UNPACKED_FILES="$(find "$PREFS_OK/$NAME" -type f | wc -l)"
RECORD_FILES="$(awk -F'\t' '$1=="files"{print $2}' "$REC")"
say unpacked_files "$UNPACKED_FILES"
say record_files "$RECORD_FILES"

# THE MODE COUNT STARTS AT THE PLUGIN FOLDER, not inside it. `find <dir>`
# tests <dir> itself, and the plugin folder is the one entry in an installed
# tree whose mode is decided by the UNPACKING account rather than by the zip
# — a zip carrying no entry for its own top level leaves unzip to create that
# folder under the user's umask, so on `umask 077` the plugin installs 0700
# and all of its files become unreadable to every other account at once.
MODES_BAD="$(find "$PREFS_OK/$NAME" \! -perm 0644 \! -perm 0755 | wc -l)"
say unpacked_modes_other_than_0644_0755 "$MODES_BAD"

# THE BUILDER'S OWN --verify, RE-RUN ON THE UNPACKED TREE. The build verifies
# what it built; this verifies what came out of the zip, which is a different
# tree produced by a different program (unzip) on a different day. It is also
# the only leg that can see a folder name the artefact's own recorder
# disagrees with, because everything else here takes the name from the build
# record and installs under it, so build and check cannot disagree.
python3 "$BUILDER" --verify "$PREFS_OK/$NAME" > "$WORK/verify_installed.log" 2>&1
VERIFY_RC=$?
say installed_verify_rc "$VERIFY_RC"
say installed_verify_line \
   "$(grep -m1 -E '^\s+\S' "$WORK/verify_installed.log" | sed 's/^ *//' | cut -c1-120)"

# EVERY `include` IN THE INSTALLED TREE RESOLVES. This is the leg no GUI walk
# can stand in for. The walk enters ONE command of nineteen, and the command
# it enters — Create Demo Table — is the only script in scripts/ with no
# include lines at all, so it is precisely the item a missing library file
# cannot break. Drop stats/eml-lib-stats.praat from the artefact and the menu
# is still there, the cascade still opens, the walk still reaches its dialog,
# and five of the nineteen commands die on their first line with "Cannot open
# file". Praat resolves `include` against the INCLUDING script's own folder,
# which is what makes this checkable without running anything.
DANGLING="$(python3 - "$PREFS_OK/$NAME" 2>"$WORK/includes.log" <<'PYEOF'
import os, re, sys
root = sys.argv[1]
inc = re.compile(r'^\s*include\s+(\S.*?)\s*$')
seen = bad = 0
for dirpath, _dirs, files in os.walk(root):
    for fn in files:
        if not fn.endswith('.praat'):
            continue
        src = os.path.join(dirpath, fn)
        with open(src, 'rb') as fh:
            text = fh.read().decode('utf-8', 'replace')
        for line in text.splitlines():
            m = inc.match(line)
            if not m:
                continue
            seen += 1
            target = os.path.normpath(os.path.join(dirpath, m.group(1)))
            if not os.path.isfile(target):
                bad += 1
                print("{}: include {}".format(
                    os.path.relpath(src, root), m.group(1)), file=sys.stderr)
print("{} {}".format(seen, bad))
PYEOF
)"
say installed_include_lines "${DANGLING% *}"
say installed_includes_dangling "${DANGLING#* }"
say installed_includes_first_dangling \
   "$(head -1 "$WORK/includes.log" 2>/dev/null)"

# THE SECOND STALENESS HANDLE. setup_sha256 above covers the registration —
# whether a menu appears at all. It does not cover the DIALOG the walk
# arrives at, which is drawn by whichever script that registration points
# the wanted command at. The two files together are exactly what the GUI
# legs' claim rests on, and they are what v79 re-derives from the shipped
# tree before it reads a word of the GUI evidence. Digesting the whole
# artefact instead would make every edit anywhere in the plugin demand a GUI
# re-drive.
SETUP_OK="$PREFS_OK/$NAME/setup.praat"
TARGET_REL="$(grep -E "^Add menu command: \"Objects\", \"New\", \"$WANT_TITLE" \
              "$SETUP_OK" | head -1 | sed 's/.*"\([^"]*\)"[^"]*$/\1/')"
say installed_target_script "$TARGET_REL"
say installed_target_sha256 \
   "$(eml_code_sha256 "$PREFS_OK/$NAME/$TARGET_REL" 2>/dev/null)"

# THE CASCADE'S NAME AS THE INSTALLED TREE REGISTERS IT. One of the two
# anchors on the menu's identity; the other is the OCR of the photograph,
# below. This one is a read of the file under test and cannot stand alone —
# it says what setup.praat asked for, not what Praat rendered.
say installed_menu_registrations \
   "$(grep -cE "^Add menu command: .*\"$WANT_MENU\"" "$SETUP_OK")"
say want_menu "$WANT_MENU"

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
#               EML Stats & Graphs cascade is not in it. This is the sharper
#               falsifier: it proves the walk discriminates rather than
#               merely being blocked by a modal, which is all the syntax
#               variant can show.
#
# `unregister` IS THE DEFAULT because it is the sharper of the two: syntax
# only shows that a modal error dialog blocks a keyboard walk, which any
# modal would do. unregister leaves Praat perfectly healthy and asks whether
# the walk can tell an EML-less New menu from an EML one.
BROKEN_SETUP="$PREFS_BAD/$NAME/setup.praat"
DAMAGE="${EML_RELEASE_DAMAGE:-unregister}"
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
QS_RC=$?
say quickstart_rc "$QS_RC"
if [[ -f "$WORK/quickstart.out" ]]; then
    if file -b "$WORK/quickstart.out" | grep -q UTF-16; then
        iconv -f UTF-16 -t UTF-8 "$WORK/quickstart.out" > "$OUT/QUICKSTART.txt"
    else
        cp "$WORK/quickstart.out" "$OUT/QUICKSTART.txt"
    fi
    QS_LINE="$(tr -d '\r' < "$OUT/QUICKSTART.txt" | head -1)"
else
    cp "$WORK/quickstart.log" "$OUT/QUICKSTART.txt"
    QS_LINE=""
fi
say quickstart_line "$QS_LINE"
# THE SHAPE OF THE LINE, not only its presence. A t-test that printed
# "t(undefined) = --" would satisfy a non-empty test, and an rc of 0 with an
# empty Info window would satisfy the rc test; the two together are what say
# the installed tree computed something.
QS_OK=0
[[ "$QS_RC" -eq 0 ]] && \
    grep -qE '^t\(-?[0-9.]+\) = -?[0-9.]+, p' <<< "$QS_LINE" && QS_OK=1
say quickstart_ok "$QS_OK"

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
# LEG menu name — THE PHOTOGRAPH, READ
# ---------------------------------------------------------------------------
# GTK menu items have no X window and no queryable property, so the walk can
# only report which DIALOG it arrived at, and Up-then-Right arrives at
# whatever cascade is last in the New menu whatever it is called. The label
# exists in exactly one machine-readable place: the pixels. tesseract, as in
# v76.
#
# READ TWICE, AND THE SECOND READING IS THE ONE THAT ANSWERS THE QUESTION.
# tesseract's page segmentation DROPS THE SELECTED ROW -- white text on the
# GTK selection blue is a block its layout analyser treats as an image -- and
# the selected row is the only one whose identity this leg is claiming. A
# whole-page pass returns the twenty rows nobody asked about and a line of
# noise where the answer is. So validate/tools/menu_label_ocr.py reads the
# page whole, which is the transcript a human reads, and then crops every
# band painted in the selection colour and reads each on its own, where the
# row comes out clean. Both readings go into MENU_OCR.txt, so a reader with
# no tesseract -- CI, for one -- has the same two the drive had.
#
# THE FALSIFIER IS READ THE SAME WAY, and that is what makes this more than a
# spell-check. With the registration cut, the highlighted row on the same
# screen at the same geometry is a DIFFERENT cascade; broken_menu_label_row
# is that reading, and it must not carry the plugin's label.
#
# MEASURED, Praat 6.6.30 under Xvfb at 1400x1100: a trailing glyph can be
# lost where the submenu arrow abuts it. So the comparison drops
# non-alphanumerics, folds case, and accepts the wanted label MINUS its last
# character. That tolerance is one character wide and is not what decides the
# check: "NOT THE EML MENU" normalises to NOTTHEEMLMENU, which contains no
# prefix of the wanted label.
OCRPY="$REPO/validate/tools/menu_label_ocr.py"
python3 "$OCRPY" "$OUT/menu_installed.png" > "$OUT/MENU_OCR.txt" 2>"$WORK/ocr.log" \
    || { echo "release: FAIL — could not read the submenu photograph: $(cat "$WORK/ocr.log")" >&2; exit 1; }

# ocr_seen <file> <label> <whole|row>
ocr_seen () {
    python3 - "$1" "$2" "$3" <<'PYEOF'
import re, sys
MARKER = "---- highlighted rows, cropped and read separately ----"
txt = open(sys.argv[1], encoding='utf-8', errors='replace').read()
whole, _, row = txt.partition(MARKER)
norm = lambda s: re.sub(r'[^A-Za-z0-9]', '', s).upper()
hay = norm(whole if sys.argv[3] == 'whole' else row)
want = norm(sys.argv[2])
print(1 if want and want[:-1] in hay else 0)
PYEOF
}
# installed_menu_label_seen is the HIGHLIGHTED-ROW reading. The whole-page
# reading is in MENU_OCR.txt above the marker for a human to read; it cannot
# tell the cascade the walk ENTERED from any other row on the screen, so it
# is not what the record claims.
MENU_ROW=$(ocr_seen "$OUT/MENU_OCR.txt" "$WANT_MENU" row)
say installed_menu_ocr_lines "$(grep -c . "$OUT/MENU_OCR.txt")"
say installed_menu_label_seen "$MENU_ROW"

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

# THE FALSIFIER'S OWN HIGHLIGHTED ROW, READ. The walk is POSITIONAL: Up then
# Right enters whatever cascade is last in the New menu. With the plugin's
# registrations cut, that is some cascade of Praat's own, and reading its
# label is what separates "the walk found the EML menu" from "the walk found
# a menu". Same reading, same screen geometry, opposite answer.
python3 "$OCRPY" "$OUT/menu_broken.png" > "$WORK/BROKEN_OCR.txt" 2>>"$WORK/ocr.log" \
    || { echo "release: FAIL — could not read the falsifier photograph" >&2; exit 1; }
BROKEN_ROW=$(ocr_seen "$WORK/BROKEN_OCR.txt" "$WANT_MENU" row)
say broken_menu_label_row "$BROKEN_ROW"
say completed 1

echo "--- $TSV ---"
cat "$TSV"

# EVERY SCALAR ABOVE IS ASSERTED HERE. Ten lines, and the four that were
# added on 16 August 2026 are the four that were being written and not read.
rc=0
fail () { echo "release: FAIL — $1" >&2; rc=1; }

# --- the unpacked tree ---
[[ "$UNPACKED_FILES" -eq "$RECORD_FILES" ]] || \
    fail "the zip unpacked $UNPACKED_FILES files; the build recorded $RECORD_FILES"
[[ "$MODES_BAD" -eq 0 ]] || \
    fail "$MODES_BAD entries in the installed tree are neither 0644 nor 0755 — $(find "$PREFS_OK/$NAME" \! -perm 0644 \! -perm 0755 | head -1)"
[[ "$VERIFY_RC" -eq 0 ]] || \
    fail "the builder refuses the tree the zip produced: $(sed -n '2p' "$WORK/verify_installed.log")"
[[ "${DANGLING#* }" -eq 0 ]] || \
    fail "${DANGLING#* } include line(s) in the installed tree name a file that is not there — $(head -1 "$WORK/includes.log")"
[[ -n "$TARGET_REL" && -f "$PREFS_OK/$NAME/$TARGET_REL" ]] || \
    fail "the installed setup.praat points '$WANT_TITLE' at '$TARGET_REL', which is not in the artefact"

# --- headless ---
[[ "$QS_OK" -eq 1 ]] || \
    fail "the headless quickstart exited $QS_RC and printed '$QS_LINE'"

# --- the GUI legs ---
[[ "$OBJ_OK" -eq 1 ]] || fail "Praat did not come up on the installed tree"
[[ "$OBJ_BAD" -eq 1 ]] || fail "Praat did not come up on the broken tree, so the falsifier proves nothing"
[[ "$MENU_PRESENT" -eq 1 ]] || fail "the walk reached '$TITLE_OK', wanted '$WANT_TITLE'"
[[ "$FALSIFIED" -eq 1 ]] || fail "the walk reached '$WANT_TITLE' with the registration dead; the install proof is decorative"

# --- the menu's identity, which the walk is positional about ---
[[ "$MENU_ROW" -eq 1 ]] || \
    fail "'$WANT_MENU' is not on the highlighted row of the open submenu photograph; the walk entered the last cascade in the New menu and that cascade is called something else"
[[ "$BROKEN_ROW" -eq 0 ]] || \
    fail "'$WANT_MENU' is on the highlighted row with the registration cut, so the reading is not reading the row"
grep -qE "^Add menu command: .*\"$WANT_MENU\"" "$SETUP_OK" || \
    fail "the installed setup.praat registers nothing under '$WANT_MENU'"

exit $rc
