#!/bin/bash
# GUI driving helpers for EML Praat Tools menu exercise.
# Source this: . /home/claude/drive/gui.sh
export DISPLAY=:99
SHOTS=/home/claude/drive/out/shots
mkdir -p "$SHOTS"

# shot <name>  -> full-screen screenshot
shot () { import -window root "$SHOTS/$1.png"; echo "$SHOTS/$1.png"; }

# wins -> list windows
wins () { xdotool search --name "." getwindowname %@ 2>/dev/null; }

# pausewin -> id + geometry of the currently MAPPED Pause window
pausewin () {
  for w in $(xdotool search --name "^Pause:" 2>/dev/null); do
    if xwininfo -id "$w" 2>/dev/null | grep -q "IsViewable"; then
      echo -n "$w "; xdotool getwindowname "$w"
    fi
  done
}

# emlmenu <y> -> open Objects>New>EML Tools and click submenu entry at y
emlmenu () {
  local y="$1"
  local o
  o=$(xdotool search --name "^Praat Objects$" | head -1)
  xdotool windowactivate --sync "$o" 2>/dev/null; sleep 0.6
  xdotool windowfocus "$o" 2>/dev/null
  sleep 1.0
  xdotool mousemove 72 14 click 1; sleep 1.2      # New
  xdotool mousemove 200 447 click 1; sleep 0.8    # highlight EML Tools
  xdotool key --clearmodifiers Right; sleep 1.2   # open submenu
  xdotool mousemove 500 "$y" click 1; sleep 2.5
}

# infoshot <name> -> raise Praat Info and screenshot it
infoshot () {
  local i
  i=$(xdotool search --name "^Praat Info$" | head -1)
  xdotool windowactivate --sync "$i" 2>/dev/null; sleep 1
  import -window root "$SHOTS/$1.png"; echo "$SHOTS/$1.png"
}

# picshot <name> -> raise Praat Picture and screenshot it
picshot () {
  local p
  p=$(xdotool search --name "^Praat Picture$" | head -1)
  xdotool windowactivate --sync "$p" 2>/dev/null; sleep 1
  import -window root "$SHOTS/$1.png"; echo "$SHOTS/$1.png"
}

# objshot <name> -> raise Objects window and screenshot
objshot () {
  local o
  o=$(xdotool search --name "^Praat Objects$" | head -1)
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
PRAAT=/home/claude/praat
PREFS=--pref-dir=/home/claude/drive/prefs
OUT=/home/claude/drive/out

# sendp <script-file>  -> execute a script in the RUNNING GUI instance.
#   "An instance of Praat that is not me is already running." on stderr is
#   informational, not an error: the script IS delivered and executed.
sendp () { ($PRAAT $PREFS --utf8 --send "$1" >/dev/null 2>&1); sleep 1.5; }

# sendl <praat source on stdin> -> same, for inline one-offs
sendl () { cat > "$OUT/_inline.praat"; sendp "$OUT/_inline.praat"; }

# infotext -> dump the Info window verbatim to stdout (exact chars, no OCR)
infotext () {
  sendp /home/claude/drive/scripts/_dumpinfo.praat
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
curpause () {
  local id
  id=$(xdotool getactivewindow 2>/dev/null) || return
  case "$(xdotool getwindowname "$id" 2>/dev/null)" in
    Pause:*) echo "$id" ;;
  esac
}

# curwin -> the active window whatever it is, for typing into a GTK entry.
curwin () { xdotool getactivewindow 2>/dev/null; }

pgeom () { local id=$(curpause); [ -n "$id" ] || { echo "no pause form"; return 1; }; echo "$id $(xdotool getwindowname $id) $(xwininfo -id $id | grep -E 'Absolute upper-left|Width|Height' | tr -d ' \n')"; }

# Praat allows only ONE pause form at a time. Opening a wrapper while a
# completion dialog is still up raises "Praat cannot have more than one
# pause form at a time" and leaves a modal error window grabbing input.
needclear () {
  local p=$(curpause)
  if [ -n "$p" ]; then echo "BLOCKED: pause form open -> $(xdotool getwindowname $p)"; return 1; fi
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
raise () {
  local w tries=0 act cand=""
  for x in $(xdotool search --name "." 2>/dev/null); do
    xwininfo -id "$x" 2>/dev/null | grep -q IsViewable || continue
    if xdotool getwindowname "$x" 2>/dev/null | grep -qE "$1"; then cand="$x"; fi
  done
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

EML_WIZARD=$((467 + EML_YOFF)); EML_DESCRIBE=$((493 + EML_YOFF))
EML_NORMALITY=$((518 + EML_YOFF)); EML_TWOGROUP=$((544 + EML_YOFF))
EML_PAIRED=$((569 + EML_YOFF)); EML_ANOVA=$((594 + EML_YOFF))
EML_KW=$((619 + EML_YOFF)); EML_TWOWAY=$((644 + EML_YOFF))
EML_CORR=$((670 + EML_YOFF)); EML_REGRESS=$((695 + EML_YOFF))
EML_PAIRWISE=$((721 + EML_YOFF))
EML_GRAPHS=$((747 + EML_YOFF)); EML_BATCH=$((773 + EML_YOFF))
EML_DEMO=$((799 + EML_YOFF)); EML_STATSDEMO=$((824 + EML_YOFF))
EML_QUICKSTART=$((850 + EML_YOFF))
EML_MENUBAR_Y=$((34 + EML_YOFF)); EML_TOOLS_Y=$((467 + EML_YOFF))

# eml <y> -> open Objects>New>EML Tools and click the submenu entry at y
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
demo () {
  eml $EML_DEMO
  xdotool mousemove 830 535 click 1; sleep 1.5
  xdotool mousemove 806 $((538 + 29 * ($1 - 1))) click 1; sleep 1.2
  xdotool mousemove 792 581 click 1; sleep 3
  xdotool mousemove 604 581 click 1; sleep 2
}

# livepause -> print id+title of the single mapped Pause window, if any
livepause () {
  for x in $(xdotool search --name "^Pause" 2>/dev/null); do
    xwininfo -id "$x" 2>/dev/null | grep -q IsViewable && \
      echo "$x $(xdotool getwindowname $x)"
  done
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
Save as comma-separated file: "/home/claude/EMLPraatTools/evidence/csv/${lab}_input.csv"
writeFile: "/home/claude/EMLPraatTools/evidence/info/${lab}_info.txt", info\$ ()
CEOF
  sendp "$OUT/_cap.praat"
  local f=/home/claude/EMLPraatTools/evidence/info/"$lab"_info.txt
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
