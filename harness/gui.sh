#!/bin/bash
# ============================================================================
# harness/gui.sh — GUI driving helpers for EML Stats & Graphs menu exercise
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Source this: . harness/gui.sh
# Defaults, not mandates: the parallel rig (harness/walks/rig.sh) puts each
# instance on its own display, so a caller that has already set DISPLAY/SHOTS
# keeps them. Bare `. harness/gui.sh` is unchanged — :99 and drive/out/shots.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ============================================================================
export DISPLAY=${DISPLAY:-:99}
EML_ROOT_GUI="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Scratch drive area, outside the repo: it holds a live Praat's preferences,
# Xvfb state and hundreds of screenshots. Overridable with DRIVE=.
DRIVE=${DRIVE:-${TMPDIR:-/tmp}/eml-drive}
SHOTS=${SHOTS:-$DRIVE/out/shots}
mkdir -p "$SHOTS"

# shot <name>  -> full-screen screenshot
shot () { import -window root "$SHOTS/$1.png"; echo "$SHOTS/$1.png"; }

# ---------------------------------------------------------------------------
# Window lookup — enumerate _NET_CLIENT_LIST, NEVER `xdotool search --name`
# ---------------------------------------------------------------------------
# 7 Aug 2026. `xdotool search --name` matches the X property WM_NAME. GTK sets
# WM_NAME only when the title is representable in Latin-1; a title carrying a
# character outside it — the wizard's em dashes — leaves WM_NAME UNSET, with
# only _NET_WM_NAME populated. Verified with xprop on Praat 6.6.30, under both
# openbox (:91) and matchbox (:99):
#
#   $ xprop -id 0x600017 WM_NAME       -> WM_NAME:  not found.
#   $ xprop -id 0x600017 _NET_WM_NAME  -> "Pause: Step 1 \342\200\224 Choose data"
#   $ xdotool search --name '^Pause:'  -> nothing, rc=1
#
# The dialog is on screen and taking clicks; the lookup simply cannot see it,
# which reads as a hung walk rather than as a lookup failure. A UTF-8 locale
# does NOT fix it: no locale can restore a property the toolkit never set.
# An ASCII-titled pause window DOES carry WM_NAME, which is why this stayed
# latent here — this harness drives one page at a time off screenshot anchors.
# Evidence: evidence/walks/gui_harness/before_after.txt
#
# _NET_CLIENT_LIST is the window manager's own list of managed top-levels, and
# both matchbox and openbox maintain it (checked). It also excludes the
# withdrawn husks Praat leaves behind for every dismissed pause dialog, which
# `xdotool search` goes on returning forever.
#
# Same route as harness/walks/d117/lib.sh:pwin — keep the two in step.

# xwins -> decimal ids of every window the WM currently manages.
#   Decimal, not the hex xprop prints, so ids compare equal to what
#   `xdotool getactivewindow` returns (see `raise`).
xwins () {
  local raw w
  # `sed -n 's/.*# //p'`, not `sed 's/.*# //'`. When the atom is absent xprop
  # prints "_NET_CLIENT_LIST:  no such atom on any window." — on STDOUT, exit
  # 0 — and the unanchored substitution passes that sentence straight through
  # as `raw`. It is not empty, so the fallback below never ran; instead the
  # loop at the bottom printf'd `%d` over seven English words and xwins
  # returned SEVEN ZEROS. Every caller then ran `xwininfo -id 0`. Found while
  # closing C7 (the "make the fallback audible" item) — the fallback the
  # comment defends was unreachable, and what happened instead was worse than
  # either branch. `-n ... p` prints only lines that actually matched.
  raw=$(xprop -root _NET_CLIENT_LIST 2>/dev/null | sed -n 's/.*# //p' | tr -d ',')
  if [ -z "$raw" ]; then
    # No EWMH window manager. Nothing else in this harness works without one,
    # but a degraded list beats a silently empty one.
    #
    # C7. This is the one place the banner's "NEVER `xdotool search --name`"
    # is deliberately broken, and it is broken into exactly the failure the
    # banner is about: `xdotool search --name "."` lists only windows that
    # have a WM_NAME at all, so an em-dash-titled pause window never enters
    # the list. `findwin "^Pause:"` then returns nothing while the dialog is
    # on screen and `raise` reports NOWIN — indistinguishable from "no such
    # window", which §11 spends a page explaining is the expensive failure.
    # Keeping the fallback is a judgement call; taking it silently is not.
    echo "WARNING: no _NET_CLIENT_LIST — is a window manager running? Falling" >&2
    echo "         back to WM_NAME search; windows titled with an em dash (every" >&2
    echo "         EML wizard page) will be INVISIBLE to findwin/pausewin/raise." >&2
    xdotool search --name "." 2>/dev/null
    return
  fi
  for w in $raw; do printf '%d\n' "$w" 2>/dev/null; done
}

# winname <id> -> window title. `xdotool getwindowname` prefers _NET_WM_NAME
#   and decodes it; the xprop fallback is for the reverse case (WM_NAME only).
winname () {
  local n
  n=$(xdotool getwindowname "$1" 2>/dev/null)
  [ -n "$n" ] || n=$(xprop -id "$1" _NET_WM_NAME 2>/dev/null \
                     | sed -n 's/^_NET_WM_NAME(UTF8_STRING) = "\(.*\)"$/\1/p')
  printf '%s\n' "$n"
}

# findwin <title-regex> -> ids of every MAPPED managed window whose title matches
findwin () {
  local w
  for w in $(xwins); do
    xwininfo -id "$w" 2>/dev/null | grep -q IsViewable || continue
    winname "$w" | grep -qE "$1" && printf '%s\n' "$w"
  done
  return 0
}

# wins -> "id title" for every managed window
wins () { local w; for w in $(xwins); do echo "$w $(winname "$w")"; done; }

# pausewin -> id + title of the currently MAPPED Pause window
pausewin () {
  local w
  for w in $(findwin "^Pause:"); do echo "$w $(winname "$w")"; done
}

# emlmenu <y> -> open Objects>New>EML Stats & Graphs and click submenu entry at y
emlmenu () {
  local y="$1"
  local o
  o=$(findwin "^Praat Objects$" | head -1)
  xdotool windowactivate --sync "$o" 2>/dev/null; sleep 0.6
  xdotool windowfocus "$o" 2>/dev/null
  sleep 1.0
  xdotool mousemove 72 14 click 1; sleep 1.2      # New
  xdotool mousemove 200 447 click 1; sleep 0.8    # highlight EML Stats & Graphs
  xdotool key --clearmodifiers Right; sleep 1.2   # open submenu
  xdotool mousemove 500 "$y" click 1; sleep 2.5
}

# infoshot <name> -> raise Praat Info and screenshot it
infoshot () {
  local i
  i=$(findwin "^Praat Info$" | head -1)
  xdotool windowactivate --sync "$i" 2>/dev/null; sleep 1
  import -window root "$SHOTS/$1.png"; echo "$SHOTS/$1.png"
}

# picshot <name> -> raise Praat Picture and screenshot it
picshot () {
  local p
  p=$(findwin "^Praat Picture$" | head -1)
  xdotool windowactivate --sync "$p" 2>/dev/null; sleep 1
  import -window root "$SHOTS/$1.png"; echo "$SHOTS/$1.png"
}

# objshot <name> -> raise Objects window and screenshot
objshot () {
  local o
  o=$(findwin "^Praat Objects$" | head -1)
  xdotool windowactivate --sync "$o" 2>/dev/null; sleep 1
  import -window root "$SHOTS/$1.png"; echo "$SHOTS/$1.png"
}

# optsel <x> <y> <n> -> click optionmenu at x,y then pick nth item (1-based)
#   Praat option menus: after click, current item is highlighted. Use Home
#   then Down (n-1) times, then Return.
optsel () {
  xdotool mousemove "$1" "$2" click 1; sleep 1
  xdotool key --clearmodifiers Home; sleep 0.4
  local k=$(( $3 - 1 ))
  for ((j=0;j<k;j++)); do xdotool key --clearmodifiers Down; sleep 0.25; done
  xdotool key --clearmodifiers Return; sleep 0.8
}

# click <x> <y>
click () { xdotool mousemove "$1" "$2" click 1; sleep 2; }

# ---------------------------------------------------------------------------
# 2026-08-05 additions: text-first capture. Screenshots are ~1900 tokens and
# vision-transcribed (error-prone for digits); these are exact and ~30-120.
# ---------------------------------------------------------------------------
PRAAT=${PRAAT:-$(command -v praat_barren || command -v praat)}
PREFS=--pref-dir=$DRIVE/prefs
OUT=$DRIVE/out

# sendp <script-file>  -> execute a script in the RUNNING GUI instance.
#   "An instance of Praat that is not me is already running." on stderr is
#   informational, not an error: the script IS delivered and executed.
sendp () { ($PRAAT $PREFS --utf8 --send "$1" >/dev/null 2>&1); sleep 1.5; }

# sendl <praat source on stdin> -> same, for inline one-offs
sendl () { cat > "$OUT/_inline.praat"; sendp "$OUT/_inline.praat"; }

# infotext -> dump the Info window verbatim to stdout (exact chars, no OCR)
#
# C8. It takes NO argument and never has. It used to ignore one silently and
# still exit 0, so `infotext out/x.txt && wc -l out/x.txt` reported success
# and then read a file nothing had written. Refusing is one line and moves
# the failure to the call that is wrong. The recipe used to describe this as
# "exits 1"; it exited 0, which is why it was worth changing rather than
# documenting.
infotext () {
  if [ $# -gt 0 ]; then
    echo "infotext takes no argument; use a shell redirect: infotext > $1" >&2
    return 2
  fi
  sendp $DRIVE/scripts/_dumpinfo.praat
  # Praat writes UTF-16 on Linux even under --utf8; normalise before reading.
  if file -b "$OUT/info.txt" | grep -q "UTF-16"; then
    iconv -f UTF-16 -t UTF-8 "$OUT/info.txt"
  else
    cat "$OUT/info.txt"
  fi
}

# picsave <name> -> save Picture window to PNG via Praat itself (no window
#   chrome, no screen scraping), then emit a trimmed, downscaled copy that is
#   cheap to read. Returns the path to read.
picsave () {
  local n="$1"
  printf 'Select outer viewport: 0, 12, 0, 12\nSave as 300-dpi PNG file: "%s/pic_%s_full.png"\n' "$OUT" "$n" > "$OUT/_picsave.praat"
  sendp "$OUT/_picsave.praat"
  convert "$OUT/pic_${n}_full.png" -trim +repage -resize 900x900\> "$OUT/pic_${n}.png" 2>/dev/null
  echo "$OUT/pic_${n}.png"
}

# objlist -> Objects window contents as text (id + name per line)
objlist () {
  cat > "$OUT/_objlist.praat" << 'PEOF'
writeInfoLine: "OBJECTS"
select all
n = numberOfSelected ()
for i from 1 to n
    appendInfoLine: selected (i), tab$, selected$ (i)
endfor
PEOF
  sendp "$OUT/_objlist.praat"; infotext
}

# pick <name-substring> -> select the single object whose name contains it
pick () {
  printf 'select all\nn = numberOfSelected ()\nid = 0\nfor i from 1 to n\n    nm$ = selected$ (i)\n    if index (nm$, "%s") > 0\n        id = selected (i)\n    endif\nendfor\nselectObject: id\nwriteInfoLine: "selected ", id, " ", selected$ (1)\n' "$1" > "$OUT/_pick.praat"
  sendp "$OUT/_pick.praat"; infotext
}

clearinfo () { printf 'writeInfoLine: ""\n' > "$OUT/_clr.praat"; sendp "$OUT/_clr.praat"; }

# Praat creates a NEW pause window per dialog — never reuse a cached id.
#
# 5 Aug 2026: the old implementation searched by name and filtered on
# IsViewable. That fails twice over. Praat leaves every dismissed pause
# window in the X tree, unmapped and still carrying its old name, so the
# search returns a growing list of dead ids; and the LIVE dialog is
# frequently absent from `xdotool search` results altogether while plainly
# visible and accepting clicks. `getactivewindow` returns it every time.
#
# 7 Aug 2026: the "absent from search results" half of that is now explained —
# see the _NET_WM_NAME note at the top of this file. `getactivewindow` is kept
# as the first route because it is one round trip; the client-list fallback is
# there for the withdrawn-husk problem, so that a dismissed pause window that
# still answers to its old name cannot be mistaken for the live one.
#
# C2. This comment used to add "but it fails outright under matchbox
# ('windowmanager claims not to support _NET_ACTIVE_WINDOW', §9.4 of the
# recipe)" — five lines below "getactivewindow returns it every time", in the
# same comment block, citing a recipe section that was itself wrong. matchbox
# advertises _NET_ACTIVE_WINDOW; measured again 7 Aug on a fresh
# `Xvfb :99` + `matchbox-window-manager -use_titlebar no` with a pause dialog
# up, `windowactivate --sync` returned 0 and `getactivewindow` returned the
# dialog. The fallback stays; its justification does not.
curpause () {
  local id
  id=$(xdotool getactivewindow 2>/dev/null)
  if [ -n "$id" ]; then
    case "$(winname "$id")" in
      Pause:*) echo "$id"; return 0 ;;
    esac
  fi
  findwin "^Pause:" | tail -1
}

# curwin -> the active window whatever it is, for typing into a GTK entry.
curwin () { xdotool getactivewindow 2>/dev/null; }

pgeom () { local id=$(curpause); [ -n "$id" ] || { echo "no pause form"; return 1; }; echo "$id $(winname $id) $(xwininfo -id $id | grep -E 'Absolute upper-left|Width|Height' | tr -d ' \n')"; }

# Praat allows only ONE pause form at a time. Opening a wrapper while a
# completion dialog is still up raises "Praat cannot have more than one
# pause form at a time" and leaves a modal error window grabbing input.
needclear () {
  local p=$(curpause)
  if [ -n "$p" ]; then echo "BLOCKED: pause form open -> $(winname $p)"; return 1; fi
  return 0
}

# Type into a GTK entry inside a pause dialog.
# xdotool windowraise is NOT enough under matchbox: without windowfocus the
# entry takes the click (caret shows) but receives no key events, so the field
# stays empty and the script silently proceeds with the default. Verified
# 5 Aug 2026 on the EML Graphs Title field.
#   typein <winid> <x> <y> <text>
typein () {
  local id="$1" x="$2" y="$3"; shift 3
  xdotool windowraise "$id"; sleep 0.6
  xdotool windowfocus "$id"; sleep 0.6
  xdotool mousemove "$x" "$y"; sleep 0.4; xdotool click 1; sleep 0.6
  xdotool type --delay 100 "$*"; sleep 1.0
}

# raise <name-regex> -> raise a window and CONFIRM it is active before returning.
# Returns 1 if it could not be confirmed, so callers never click blind.
#
# Matches against `xdotool getwindowname`, NOT `xdotool search --name`. The two
# read different properties: search reads WM_NAME, getwindowname prefers
# _NET_WM_NAME, and for Praat's script editor they differ — WM_NAME is just
# "Script" while the visible title carries the path in curly quotes. Searching
# on the visible title silently found nothing.
#
# 7 Aug 2026: matching on getwindowname was right, but the ENUMERATION was
# still `xdotool search --name "."`, which only lists windows that have a
# WM_NAME at all — so a pause window titled with an em dash never entered the
# loop to be matched. `findwin` enumerates _NET_CLIENT_LIST instead.
raise () {
  local w tries=0 act cand=""
  cand=$(findwin "$1" | tail -1)
  w="$cand"
  [ -z "$w" ] && { echo "NOWIN"; return 1; }
  while [ $tries -lt 6 ]; do
    xdotool windowraise "$w" 2>/dev/null
    xdotool windowactivate "$w" 2>/dev/null
    xdotool windowfocus "$w" 2>/dev/null
    sleep 0.8
    act=$(xdotool getactivewindow 2>/dev/null)
    if [ "$act" = "$w" ]; then echo "$w $(xdotool getwindowgeometry $w | tr '\n' ' ')"; return 0; fi
    tries=$((tries+1))
  done
  echo "NOTRAISED $w (active=$act)"; return 1
}

# --- Orchestrator drive helpers (5 August 2026) -----------------------------
# Submenu entry y coordinates, verified: see harness/MENU_MAP.md
# Updated 5 Aug 2026 after the LMM entry was tabled: everything from
# Pairwise comparisons down moved up by one row (26px).
# EML_YOFF exists because these coordinates are not a property of the
# plugin. They are a property of how the window manager places the Objects
# window, and that changed between two sessions on the same machine: on
# 6 August every entry sat exactly 20px higher than on 5 August, with the
# menu bar at y=14 instead of y=34. Rather than rewrite sixteen numbers and
# lose the record of which layout they were measured in, the base values
# below stay as measured on 5 August and the offset carries the difference.
# Recalibrate by opening the submenu and reading the entry positions off a
# screenshot; see harness/MENU_MAP.md.
EML_YOFF=${EML_YOFF:--20}

# ---------------------------------------------------------------------------
# 15 AUGUST 2026 — HISTORY. Superseded by the 16 August block below, which is
# where the live values are. Kept because it is the record of the same failure
# happening one menu change earlier, and because the block below is shorter for
# being able to point at it.
#
# Re-measured 15 August on Praat 6.6.30, Xvfb 1400x1000x24, matchbox
# -use_titlebar no. Every base value was (measured y) + 20, and every one of
# them was then PROVED by clicking it and reading the window that appeared;
# that evidence table is in harness/MENU_MAP.md under the 15 August heading.
#
# WHAT WAS WRONG. The 13 August menu re-chain added a recorder group --
# "Record script", "Stop recording and open", "Stop recording and save..." --
# after "Check & repair data...", which pushed Create Demo Table down three
# rows. EML_DEMO was not moved, so it went on clicking base 799, which is now
# **Record script**. It did not fail. It started a recording, and every drive
# that called `demo` afterwards ran inside a recording nobody asked for. The
# 14 August audit lost a phantom recording to it before its fleet launched.
# That is the failure mode this whole file's comments keep warning about: a
# stale menu constant does not error, it clicks whatever moved into its place.
#
# Twelve of the fourteen surviving constants were right to within 1 px. They
# were rewritten anyway to the values that were actually proved, so that the
# map, this file and the pixels are one number rather than three near ones.
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# RE-MEASURED AGAIN 16 AUGUST 2026, same rig, after Batch voice analysis was
# registered. Praat 6.6.30, Xvfb :150 1400x1000x24, matchbox
# -use_titlebar no. Every entry below was read off the ink profile of a fresh
# submenu screenshot AND THEN PROVED BY CLICKING IT; the readback table is in
# harness/MENU_MAP.md under the 16 August heading, and every superseded value
# was ALSO clicked, to show what it opens now. Nothing here is arithmetic on a
# row pitch — the pitch on this menu is 24, 25 AND 26 px depending on whether a
# separator sits between two rows, so "shift everything by 25" is a guess that
# happens to be right eleven times out of seventeen.
#
# WHAT WAS WRONG. "Batch voice analysis..." was registered again on 16 August
# (setup.praat lines 179-180, chained after "EML Graphs..."), and it renders
# ABOVE "Check & repair data...". That inserted one row at position 13 and
# pushed the five entries below it down one row each. The constants were not
# moved, so every one of them addressed the row ABOVE its entry:
#
#   EML_CHECKDATA  clicked 753 -> Pause: Batch Voice Analysis
#   EML_RECORD     clicked 779 -> Pause: EML — Check & repair data
#   EML_RECORD_OPEN clicked 804 -> Info: "EML: recording started."
#   EML_RECORD_SAVE clicked 829 -> Info: "EML: nothing has been recorded yet."
#   EML_DEMO       clicked 854 -> Pause: Nothing recorded yet
#
# Not one of them failed. EML_RECORD_OPEN is the 15 August failure repeating
# exactly: it silently STARTS A RECORDING and returns, and every drive after it
# runs inside a recording nobody asked for.
#
# The first twelve entries are unchanged — the new row lands below EML Graphs,
# so nothing above it moved. EML_GRAPHS was re-driven anyway (753's neighbour
# above) and still opens `Pause: EML Graphs`.
#
# EACH LINE CARRIES BOTH ADDRESSES: the pixel y this file clicks, and the
# entry's ORDINAL among the submenu's commands, which is what `emlitem` walks.
# They are two encodings of one fact and they are on one line so that a menu
# change updates them together. See `emlitem` below for why the ordinal is the
# route to prefer.
# ---------------------------------------------------------------------------
EML_WIZARD=$((467 + EML_YOFF));      EML_N_WIZARD=1
EML_DESCRIBE=$((492 + EML_YOFF));    EML_N_DESCRIBE=2
EML_NORMALITY=$((518 + EML_YOFF));   EML_N_NORMALITY=3
EML_TWOGROUP=$((545 + EML_YOFF));    EML_N_TWOGROUP=4
EML_PAIRED=$((569 + EML_YOFF));      EML_N_PAIRED=5
EML_ANOVA=$((594 + EML_YOFF));       EML_N_ANOVA=6
EML_KW=$((619 + EML_YOFF));          EML_N_KW=7
EML_TWOWAY=$((644 + EML_YOFF));      EML_N_TWOWAY=8
EML_CORR=$((669 + EML_YOFF));        EML_N_CORR=9
EML_REGRESS=$((696 + EML_YOFF));     EML_N_REGRESS=10
EML_PAIRWISE=$((722 + EML_YOFF));    EML_N_PAIRWISE=11
EML_GRAPHS=$((747 + EML_YOFF));      EML_N_GRAPHS=12
# 16 Aug: Batch voice analysis registered again, ABOVE Check & repair data.
# Its base value is 773, which is the number the 6 August tabling comment used
# to carry as history — the entry has come back to the slot it was removed
# from. It is a live constant now, measured, not un-commented.
EML_BATCH=$((773 + EML_YOFF));       EML_N_BATCH=13
EML_CHECKDATA=$((799 + EML_YOFF));   EML_N_CHECKDATA=14   # was 773
EML_RECORD=$((825 + EML_YOFF));      EML_N_RECORD=15      # was 799
EML_RECORD_OPEN=$((850 + EML_YOFF)); EML_N_RECORD_OPEN=16 # was 824
EML_RECORD_SAVE=$((875 + EML_YOFF)); EML_N_RECORD_SAVE=17 # was 849
EML_DEMO=$((900 + EML_YOFF));        EML_N_DEMO=18        # was 874
# Tabled 6 Aug and still tabled. THE NUMBERS BELOW ARE HISTORY, NOT
# COORDINATES: they are where those entries sat in the 6 August menu, and both
# now address a different row — in the 16 August menu base 824 is Record script
# and base 850 is Stop recording and open. Restoring either entry means
# re-measuring and re-numbering the ordinals below it, not un-commenting.
# EML_STATSDEMO=$((824 + EML_YOFF))   # tabled 6 Aug — 824 is now Record script
# EML_QUICKSTART=$((850 + EML_YOFF))  # tabled 6 Aug — 850 is now Stop recording and open
EML_MENUBAR_Y=$((34 + EML_YOFF)); EML_TOOLS_Y=$((467 + EML_YOFF))

# emlitem <ordinal> -> open Objects>New>EML Stats & Graphs and select the ordinal'th
#   COMMAND of the submenu by keyboard. PREFER THIS OVER `eml <y>`.
#
# Click "New", then Up, then Right, then Down x (n-1), then Return.
#
# Up FIRST, and it is not decoration: it wraps to the LAST item of the New
# menu, which is where Praat puts a plugin's cascade header, so the walk does
# not depend on how many commands Praat's own New menu carries — a number that
# moves between Praat versions and has nothing to do with this plugin. Right
# opens the cascade and selects its first item, which is why the repeat count
# is n-1 and not n. GTK skips separators during keyboard navigation, so n
# counts COMMANDS and the nine "-- eml ... --" rules are invisible to it.
#
# WHAT THIS FIXES AND WHAT IT DOES NOT. Same route as harness/batchgui/run.sh,
# adopted here on 16 August 2026 and proved by driving all eighteen ordinals on
# this rig (readbacks in MENU_MAP.md, §16 August, ordinal column). It is immune
# to the three things that have forced every recalibration of the pixel table:
# the row pitch (24/25/26 px, separator-dependent), EML_YOFF (the 20 px the
# whole table moved on 6 August when the titlebar went away), and where the
# window manager puts the Objects window. It is NOT immune to the menu being
# REORDERED: today's regression moved Check & repair data from ordinal 13 to
# 14 exactly as it moved it from y 753 to 779, and a stale ordinal is just as
# silent as a stale coordinate — it opens the neighbour. This route carries
# less state, not less obligation to re-measure.
emlitem () {
  local n="$1"
  raise "^Praat Objects$" >/dev/null || return 1
  xdotool mousemove 76 $EML_MENUBAR_Y click 1; sleep 1.5
  xdotool key --clearmodifiers Up;    sleep 1.0
  xdotool key --clearmodifiers Right; sleep 1.5
  [ "$n" -gt 1 ] && xdotool key --clearmodifiers --repeat $((n - 1)) --delay 120 Down
  sleep 1
  xdotool key --clearmodifiers Return; sleep 3
}

# eml <y> -> open Objects>New>EML Stats & Graphs and click the submenu entry at y.
#   Kept because callers outside this file pass the EML_* pixel constants, and
#   because a pixel is what a screenshot can be checked against. For new code
#   use `emlitem $EML_N_<entry>`, which does not depend on the layout at all.
eml () {
  raise "^Praat Objects$" >/dev/null || return 1
  xdotool mousemove 76 $EML_MENUBAR_Y click 1; sleep 1.2
  xdotool mousemove 200 $EML_TOOLS_Y click 1; sleep 0.8
  xdotool key --clearmodifiers Right; sleep 1.2
  xdotool mousemove 500 "$1" click 1; sleep 3
}

# demo <n>  -> Create Demo Table, pick option n (1..7), Create, then Quit
#   1 Two groups(40)  2 Three groups(45)  3 Paired(20)  4 Correlation(30)
#   5 Regression(25)  6 Two-way(48)       7 Normality(40)
#
# 16 Aug 2026: switched from `eml $EML_DEMO` to the keyboard walk. This is the
# helper that the 15 August incident actually damaged — a stale EML_DEMO made
# `demo` start a recording instead of creating a table — and it is the one call
# site inside this file, so it is the one that stops depending on the pitch.
demo () {
  emlitem $EML_N_DEMO
  xdotool mousemove 830 535 click 1; sleep 1.5
  xdotool mousemove 806 $((538 + 29 * ($1 - 1))) click 1; sleep 1.2
  xdotool mousemove 792 581 click 1; sleep 3
  xdotool mousemove 604 581 click 1; sleep 2
}

# livepause -> print id+title of the single mapped Pause window, if any
livepause () {
  local x
  for x in $(findwin "^Pause"); do echo "$x $(winname "$x")"; done
}

# capture <label> -> save the selected Table and the Info text under evidence/
#
# 6 August: this used to raise a script editor holding cap/capture.praat and
# press ctrl+R. Two things broke that. `raise` cannot focus the editor while
# a pause form is modal, and the wrapper's repeat loop re-opens its form the
# moment a run finishes — so the editor is unreachable at exactly the moment
# there is something to capture. Sending the same script through sendpraat
# needs no focus at all, and info$() read this way returns the LIVE Info
# window (verified: after `clearinfo` it returns exactly one newline).
#
# Call it with the analysed Table still selected and the form quit. Do NOT
# call `pick` first: pick writes its own line into the Info window, which
# would then be the first line of the capture.
# capture <label> [table-name-substring]
# The table is found BY NAME, not by selection state. Relying on selection
# cost an hour on 6 August: a wrapper leaves its table selected, but any
# stray click in the Objects list, and every `pick`, changes that, and the
# failure mode is a one-byte capture rather than an error.
capture () {
  local lab="$1"
  local want="${2:-}"
  cat > "$OUT/_cap.praat" << CEOF
Text writing preferences: "UTF-8"
want\$ = "${want}"
tid = 0
select all
n = numberOfSelected ()
for i from 1 to n
    nm\$ = selected\$ (i)
    if left\$ (nm\$, 6) = "Table " and (want\$ = "" or index (nm\$, want\$) > 0)
        tid = selected (i)
    endif
endfor
selectObject: tid
Save as comma-separated file: "$EML_ROOT_GUI/evidence/csv/${lab}_input.csv"
writeFile: "$EML_ROOT_GUI/evidence/info/${lab}_info.txt", info\$ ()
CEOF
  sendp "$OUT/_cap.praat"
  local f=$EML_ROOT_GUI/evidence/info/"$lab"_info.txt
  [ -f "$f" ] || { echo "CAPTURE FAILED: $lab"; return 1; }
  if file "$f" | grep -q UTF-16; then
    iconv -f UTF-16 -t UTF-8 "$f" -o "$f".u8 && mv "$f".u8 "$f"
  fi
  wc -c < "$f" | sed "s|^|captured $lab: |;s|$| bytes|"
}

# clearinfo -> Praat Info window > Edit > Erase. Needed before running a
# wrapper that has no "Clear Info window" checkbox, so info$() is exactly
# one analysis. Praat is blocked while a pause form is up, so call this
# BEFORE opening the wrapper, never during.
# Clearing by Info > Edit > Erase was tried and abandoned on 6 August: the
# click lands, the menu closes, and info$() still returns the old text. The
# sendpraat route is deterministic and verified — after it, info$() is
# exactly one newline. Praat is BLOCKED while a pause form is up, so this
# must be called BEFORE opening a wrapper, never during one.
clearinfo () {
  printf 'writeInfoLine: ""\n' > "$OUT/_clr.praat"
  sendp "$OUT/_clr.praat"
}
