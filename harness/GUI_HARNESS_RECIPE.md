# GUI Harness Recipe — driving the EML Praat Tools plugin under Xvfb

Date: 4 August 2026
Purpose: reproducible procedure for launching Praat interactively in the sandbox
and driving plugin menus/dialogs with xdotool. Every element below is
empirically verified in this session unless marked otherwise.

---

## Standing rule — kill by exact process NAME, never by command line

**Every `pkill`/`pgrep` in this harness uses `-x` (exact process name). None
uses `-f` (full command line).** `-f` matches the pattern against every
process's *entire* command line — including the driving shell's own, which
contains the string precisely because it is running the command. The kill then
takes out the shell that issued it. This has fired: a teardown using
`pkill -9 -f matchbox` died with **exit 144** (128+16, SIGTERM) — finding D126.

| Target | Use | Never |
|---|---|---|
| Praat | `pkill -9 -x praat` | `pkill -f praat` |
| Xvfb | `pkill -9 -x Xvfb` | `pkill -f Xvfb` |
| matchbox WM | `pkill -9 -x matchbox-window` | `pkill -f matchbox` |

`matchbox-window` is not a typo. `-x` matches `/proc/<pid>/comm`, which Linux
truncates to **15 characters**, so `matchbox-window-manager` is carried as
`matchbox-window`. The untruncated name does not merely miss — `pgrep` refuses
it outright.

Verified 8 August 2026 on this image (`Xvfb :77` + matchbox):

```
$ pgrep -a -f matchbox
14794 /bin/bash -c ... eval '... matchbox ...'      <- THE DRIVING SHELL
15885 matchbox-window-manager -use_titlebar no
$ pgrep -a -x matchbox-window
15885 matchbox-window-manager -use_titlebar no      <- the WM, and nothing else
$ ps -o comm= -p 15885
matchbox-window
$ pgrep -x matchbox-window-manager
pgrep: pattern that searches for process name longer than 15 characters will
result in zero matches
```

The same holds for Praat: `pgrep -f praat` returned the driving shell alongside
Praat; `pgrep -x praat` returned Praat alone.

**One step narrower when anything else is running.** `-x` fixes the self-kill,
but `pkill -9 -x praat` still kills *every* Praat on the machine, including one
another display or another agent's stress run owns — observed on 8 Aug 2026,
when a `harness/stress_cases/` run appeared under `pgrep -x praat` mid-teardown.
Where a driver knows its own pid, kill that pid: `harness/walks/rig.sh:45`
carries this rule, and `walks/d117/lib.sh:37` and `walks/d93/drive.sh:3` kill by
recorded pid for exactly this reason. Whole-name `pkill -9 -x praat` is for a
sandbox you are alone in.

Stated here once. The sections below apply the rule and do not re-derive it.

---

## 0. Why this exists

`beginPause:` hard-crashes under `praat --run` (Praat 6.6.30, Linux):
`Trace/breakpoint trap`, exit 133 (SIGTRAP), mid-script. Every EML wrapper
uses `beginPause:`/`endPause` rather than `form:`, so:

- `runScript: "path", arg1, ...` positional-argument driving does NOT apply.
- There is no headless/test hook anywhere in `scripts/`, `stats/`, `graphs/`
  (grep `batchMode|testMode|EML_TEST|noninteractive|nonInteractive` → 0 hits).

GUI + synthetic input is therefore the only route to end-to-end exercise.

---

## 0. Two variables, because this file used to hardcode one machine

Every path below was written as `/home/claude/...` — the home directory of the
sandbox the recipe was first derived in. On any other machine every command in
this document was wrong, silently: `cd /home/claude` fails, and the steps after
it run in whatever directory the reader happened to be in.

The rest of the tree already solved this. `harness/_env.sh` resolves `EML_ROOT`
from its own location and `PRAAT` from `$PRAAT`, then `PATH`, then the common
install locations, and REFUSES a Praat below the plugin's 6.6.30 floor. This
file now uses the same two names, plus one of its own for scratch:

```bash
source harness/_env.sh            # sets EML_ROOT and PRAAT
export EML_DRIVE="${EML_DRIVE:-$EML_ROOT/harness/drive}"
mkdir -p "$EML_DRIVE"/{prefs,out,scripts}
```

`EML_DRIVE` is scratch only — preference directory, screenshots, transcripts.
Nothing in `validate/` reads it. Give it its own directory rather than sharing
one with another harness, so a concurrent run cannot collide over Praat's
preferences file.

Paste that block once per session and every command below works as written.

---

## 1. Prerequisites present in the sandbox

| Tool | Path / note |
|---|---|
| Praat full GUI | `$PRAAT` (6.6.30 or later; `harness/_env.sh` resolves and version-checks it) |
| Praat barren | `praat_barren` — **ABSENT on the current image** (8 Aug 2026: only `praat6630` and `praat7000` are present, with `praat` symlinked to `praat6630`). Used by the static-review and stress harnesses; install before following any step that names it |
| Xvfb | present |
| **matchbox-window-manager** | `/usr/bin/matchbox-window-manager` — **REQUIRED** |
| xdotool | present |
| ImageMagick `import` | present |
| PulseAudio | ABSENT — `apt-get install -y pulseaudio` only if a path plays audio |

### The window-manager finding (critical)

Bare Xvfb has **no window manager**. Without one:

- `xdotool windowactivate` fails: *"Your windowmanager claims not to support
  _NET_ACTIVE_WINDOW"*
- GTK text entries never receive click-to-focus, so typed input never lands.

`matchbox-window-manager -use_titlebar no` fixes both. With it:
`windowactivate --sync` and `windowfocus --sync` succeed, `getwindowfocus`
returns the dialog id, and typing lands. Matchbox maximizes top-level windows
(Praat Objects becomes 1400x1000 at 0,0) and centers dialogs (a Pause window
lands at 442,444, 524x167 — the size varies per dialog; see §9.5).

**`-use_titlebar no` does not mean "no window chrome".** It suppresses chrome
on the maximized top-level windows only. Every `beginPause:` dialog is still
drawn with a 20 px titlebar, a close box and 4 px borders, and
`xdotool getwindowgeometry` mis-reports the dialog origin as a result.
Measured under §10, *"matchbox must run with `-use_titlebar no`"*.

---

## 2. Launch sequence

```bash
# 2.1 Clean slate — exact NAME only, no -f anywhere (see "Standing rule" above)
pkill -9 -x praat 2>/dev/null; pkill -9 -x Xvfb 2>/dev/null
pkill -9 -x matchbox-window 2>/dev/null; sleep 1
rm -f /tmp/.X99-lock /tmp/.X11-unix/X99        # stale lock => Xvfb exits 1

# 2.2 Display
Xvfb :99 -screen 0 1400x1000x24 > $EML_DRIVE/out/xvfb.log 2>&1 &
sleep 3
export DISPLAY=:99
xdpyinfo | head -3                              # sanity check

# 2.3 Window manager
matchbox-window-manager -use_titlebar no > $EML_DRIVE/out/wm.log 2>&1 &
sleep 2
pgrep -x matchbox-window # 15-char comm; -f would also match this shell
```

### 2.4a Interactive / idle Praat — for menu driving

`--new-send <script>` makes Praat **exit when the script completes**, so it
cannot be used to leave Praat interactive. Launch with **no script argument**:

```bash
rm -f $EML_DRIVE/prefs/pid $EML_DRIVE/prefs/message
#   ^ stale locks => "An instance of Praat that is not me is already running."
#   Do NOT delete the whole pref dir — the plugin lives in it.
nohup "$PRAAT" --pref-dir="$EML_DRIVE/prefs" --utf8 \
  > $EML_DRIVE/out/idle.log 2>&1 &
sleep 8
```

### 2.4b Script-driven Praat — blocks on `beginPause`, stays alive

```bash
nohup "$PRAAT" --new-send --pref-dir=$EML_DRIVE/prefs --utf8 \
  $EML_DRIVE/scripts/X.praat > $EML_DRIVE/out/X.log 2>&1 &
```

---

## 3. Interaction primitives (all verified)

```bash
# Locate windows — do NOT use `xdotool search --name`; see §4 and §11.
#   `wins` / `findwin <regex>` / `pausewin` in gui.sh walk _NET_CLIENT_LIST.
wins
#   => Praat Objects / Praat Picture / Praat Info / Pause: <title>
W=$(pausewin | cut -d' ' -f1)
xwininfo -id $W        # geometry: "Absolute upper-left" is the CLIENT origin

# Focus (works ONLY with a WM running)
xdotool windowactivate --sync $W

# Buttons, combo boxes, entry fields: absolute coordinates
xdotool mousemove X Y click 1

# Text entry: click the field, select-all, type
xdotool key --clearmodifiers ctrl+a
xdotool type --clearmodifiers --delay 60 "7.25"

# optionmenu: click the combo, then arrow + Return
xdotool key --clearmodifiers Down ; xdotool key --clearmodifiers Return

# Open a highlighted SUBMENU — hover and click do NOT work under matchbox
xdotool key --clearmodifiers Right

# Screenshot
import -window root $EML_DRIVE/out/shot.png
```

### Verification probe (`drive/scripts/probe2.praat`)

Exercises all three primitives at once. Confirmed output:

```
start 6.6.30
clicked=2
pick_one=3 pick_one$=gamma
some_number=7.25
DONE
```

`clicked=2` = button click; `pick_one=3/gamma` = optionmenu (default was 2);
`some_number=7.25` = typed text replacing the 3.5 default.

Rule 20 derivation confirmed empirically by this probe:
`"Pick one"` → `pick_one`/`pick_one$`; `"Some number"` → `some_number`;
`"Clear Info window"` → `clear_Info_window`.

---

## 4. Gotchas index

| Symptom | Cause | Fix |
|---|---|---|
| Xvfb exits 1 | stale `/tmp/.X99-lock` | `rm -f /tmp/.X99-lock /tmp/.X11-unix/X99` |
| `pgrep -x matchbox-window-manager` refuses ("longer than 15 characters") | `-x` matches `/proc/<pid>/comm`, truncated to 15 chars | `pgrep -x matchbox-window` — the truncated name. **Not** `-f`; see Standing rule |
| Typed text never lands | no window manager | run matchbox |
| Praat exits right after launch | `--new-send` with a non-blocking script | launch with no script arg |
| "instance ... already running" | stale `pid`/`message` in pref dir | delete just those two files |
| Submenu won't open on hover/click | Praat/matchbox behaviour | `xdotool key Right` |
| exit 124 from `timeout` | modal dialog is up | expected; not a failure |
| Killing own shell (exit 143/144 from a teardown) | any `pkill -f <pattern>` — `-f` matches the driving shell's own command line | kill by exact name: `pkill -9 -x praat` / `-x Xvfb` / `-x matchbox-window`. See Standing rule |
| `xdotool search --name` finds nothing, but the window is on screen | title is not Latin-1 (wizard pages use em dashes) so GTK sets **only `_NET_WM_NAME`**, never `WM_NAME` — which is all `search` reads | use `findwin`/`pausewin` in `gui.sh` (enumerate `_NET_CLIENT_LIST`, read the name with `xdotool getwindowname`). A UTF-8 locale does **not** help |
| `xdotool search --name "^Pause:"` returns a growing list of ids | Praat leaves every dismissed pause window in the tree, unmapped, still named | filter on `IsViewable`; `_NET_CLIENT_LIST` already excludes them |
| `xwins` prints a column of `0`s and every later call fails | no window manager: `xprop -root _NET_CLIENT_LIST` prints "no such atom on any window." **on stdout, exit 0**, and an unanchored `sed 's/.*# //'` passes that sentence through as if it were a window list | fixed 7 Aug in `gui.sh`, `walks/d117/lib.sh` and `walks/gridmode/lib.sh` — `sed -n 's/.*# //p'`. `xwins` now warns on stderr and falls back. If you see the warning, start matchbox or openbox |
| `windowactivate` fails with "claims not to support `_NET_ACTIVE_WINDOW`" | **no window manager** — not matchbox. matchbox advertises it (§9.4) | run matchbox; do not switch to `windowraise` |

---

## 5. Field inventory conclusion

`@emlWrapperCommonFields` (`stats/eml-output.praat`) contributes only:

```praat
comment: "--- Options ---"
boolean: "Clear Info window", 0
```

Combined with the per-wrapper inventories, **no EML wrapper dialog contains a
typed-input field** — every field is `optionmenu` or `boolean`. Text entry is
available but not required for wrapper driving. (It IS required for
`eml-batch-process` folder paths and for the Table editor.)

---

## 9. Text-first capture (added 2026-08-05) — supersedes screenshot reading

Screenshots of the Info window are ~1,900 tokens each and are *transcribed by
vision*, which can silently misread a digit in a p-value. For an audit whose
first criterion is accuracy that is the wrong instrument. Use the exact-text
route instead.

### 9.1 Sending a script to the RUNNING GUI instance

```bash
"$PRAAT" --pref-dir="$EML_DRIVE/prefs" --utf8 --send script.praat
```

`An instance of Praat that is not me is already running.` on stderr is
**informational, not an error** — the script IS delivered to the running
instance and executed there. Verified 2026-08-05.

This does not replace GUI clicking for wrapper dialogs (`beginPause:` still
renders a real dialog that needs clicks), but it does replace clicking for
*state setup*: `selectObject:`, object creation, cleanup.

### 9.2 Info window as exact text

`$EML_DRIVE/scripts/_dumpinfo.praat`:

```praat
writeFileLine: "$EML_DRIVE/out/info.txt", info$ ()
```

`info$ ()` returns the full Info window contents. Dumping it does not clear or
alter the window. Wrapped as `infotext` in `gui.sh`.

**Encoding gotcha:** Praat writes this file as **UTF-16** on Linux even when
launched with `--utf8`. `infotext` sniffs with `file -b` and pipes through
`iconv -f UTF-16 -t UTF-8`. Without that step the output arrives as
space-separated characters with a BOM.

### 9.3 Picture window as PNG from Praat itself

`picsave <name>` sends `Select outer viewport: 0, 12, 0, 12` +
`Save as 300-dpi PNG file:`, then `convert -trim +repage -resize 900x900\>`.
No window chrome, no screen scraping. Caveat: it does reset the outer viewport
selection — harmless because every EML draw procedure sets its own viewport,
but do not run it *between* two halves of a multi-panel draw.

### 9.4 Raise the Objects window before clicking its menubar

After the Info window has been raised, Info is 620x400 at 0,0 and covers the
Objects menubar at y=14, so a menu click lands on Info and nothing happens —
silently. Bring the Objects window forward first, with the same two calls
everything else in this document uses:

```bash
xdotool windowactivate --sync $id
xdotool windowfocus $id
```

**WITHDRAWN, C2, 7 Aug 2026.** This section used to be headed *"`windowactivate`
does not work under matchbox — use `windowraise`"* and to claim, over the error
string `Your windowmanager claims not to support _NET_ACTIVE_WINDOW`, that
"`xdotool windowactivate` and `getactivewindow` both fail" and that
`windowraise` "is what `emlmenu` needs".

Every part of that was wrong, and it contradicted §1, §3 and §10 of this same
document — four sections, three mutually exclusive instructions for one
primitive. That error string belongs to **no window manager at all**, which is
§1's finding; matchbox advertises `_NET_ACTIVE_WINDOW`. Re-measured on a fresh
`Xvfb :99` + `matchbox-window-manager -use_titlebar no` + Praat 6.6.30, this
sandbox, with a pause dialog up:

```
$ xprop -root _NET_SUPPORTED | tr ',' '\n' | grep -i active_window
 _NET_ACTIVE_WINDOW
$ xdotool windowactivate --sync 0x40000f ; echo rc=$?
rc=0
$ xdotool getactivewindow                               -> 4194319  (= 0x40000f)
$ xdotool windowfocus 0x40000f ; xdotool getwindowfocus -> 4194319
```

`gui.sh:raise` additionally *confirms* with `getactivewindow` and returns
`NOTRAISED` if it does not match; driven on the same display it returned
`4194319 Window 4194319 Position: 382,410 Geometry: 524x135`.

Following the withdrawn advice would have cost more than a wasted call.
`gui.sh:typein`'s own verified note records that with `windowraise` alone "the
entry takes the click (caret shows) but receives no key events, so the field
stays empty and the script silently proceeds with the default" — silent wrong
data, the D126 family. And `emlmenu` does not use `windowraise`; it uses
`windowactivate --sync` then `windowfocus`, and `grep -n windowraise
harness/gui.sh` returns only `typein` and `raise`, in both of which it is
*followed* by `windowfocus`.

See §10, *"`xdotool windowraise` is not enough under matchbox"*, which has had
the right answer all along.

### 9.5 Window geometry is NOT stable across relaunches

matchbox placed the `Create Demo Table` pause dialog at **0,0** on the
2026-08-05 relaunch; the pre-relaunch coordinates (optionmenu 830,535 /
Create 793,581) were dead. Do not trust cached dialog coordinates across a
Praat restart. Cheap re-establishment: `xwininfo -id <pausewin>` for geometry,
then ONE window-scoped `import -window <id>` (a 639x219 dialog is ~250 tokens,
vs ~1,900 for a root capture).

Verified dialog coordinates for `Create Demo Table` at origin 0,0:
optionmenu (450,137), Undo (56,183), Quit (223,183), Create (413,183).

### 9.6 Processes need `setsid nohup ... < /dev/null &`

Xvfb, matchbox and Praat launched with a bare `&` are killed when the driving
shell call returns. Xvfb dying is the silent one — Praat then fails to start
with no message in its own log, and `pgrep -x praat` is simply empty.

---

## 10. Traps carried forward (added 2026-08-05)

These were each hit at least once and cost real time. They are not in the
gotchas table above because they are behaviours to design around rather than
symptoms with a one-line fix.

### matchbox must run with `-use_titlebar no` — but it is not a "no chrome" flag

With titlebars on, matchbox adds ~20px of chrome above every **top-level**
window and **every mapped coordinate in `MENU_MAP.md` shifts down by that
amount.** The map, and every dialog absolute recorded in the findings log,
assume the flag is set. Launch:

```bash
setsid matchbox-window-manager -use_titlebar no < /dev/null &
```

**D126, corrected 8 August 2026 — the flag does NOT suppress chrome on
dialogs.** This document previously read as though `-use_titlebar no` removed
window chrome outright. Observation contradicts that. Re-measured on a fresh
`Xvfb :77` + `matchbox-window-manager -use_titlebar no` + Praat 6.6.30, this
image, with a `beginPause:` dialog up:

| Window | matchbox frame | client | chrome |
|---|---|---|---|
| Praat Objects / Praat Picture | 1400x1000 at 0,0 | 1400x1000 at 0,0 | **none** — zero offset |
| `Pause:` dialog | 532x159 at 434,420 | 524x135 at 438,440 | **20 px titlebar + close box, and 4 px borders** |

The dialog titlebar is real, not a phantom of the frame arithmetic: cropped
from a root screenshot and read at 300% it showed the title text and a ✖ close
box at the right edge. `audit/DRIVE_FINDINGS_2026-08-04.md:44-52` recorded the
same titlebar independently, and was right.

The consequence that costs time: for that dialog `xdotool getwindowgeometry`
reported **442,460** — the client origin (438,440) with the (+4,+20) frame
offset applied a *second* time. It matches neither the frame nor the client.
`xwininfo -id <client>`'s "Absolute upper-left" gives the true 438,440. **Never
derive dialog click coordinates from `getwindowgeometry`**; use `xwininfo`
(which is what `pgeom` in `gui.sh` reads) or a screenshot — §9.5.

### matchbox must be restarted with `setsid ... < /dev/null &`

A plain backgrounded restart issued in the *same* bash call as a `pkill` dies
with exit 144 (128+16, SIGTERM) — it inherits the process group being killed.
`setsid` detaches it. Redirecting stdin from `/dev/null` stops it stalling on
a terminal read.

### Never trust a cached dialog absolute across a restart

Praat re-places its pause windows on each launch, and the offsets drift by a
few pixels — the Compare Paired dialog was at 438,290 in one session and
442,310 in the next, and 438,451 later the same day. Arithmetic from a cached
origin silently clicks the wrong control.

**Always:** `pgeom` for the current origin, screenshot, crop at that origin,
*read the crop*, and derive button absolutes from what you see. The crop is
cheap; a mis-click that dismisses a dialog is not.

### `xdotool windowraise` is not enough under matchbox

Raising a window does not give it input focus, so clicks and keystrokes go to
whatever had focus before. The reliable sequence before *any* click or type:

```bash
xdotool windowactivate --sync $id
xdotool windowfocus $id
```

This section is correct and has been since it was written. §9.4 used to say
the opposite of it, in the same document; that claim is now withdrawn, with
the measurement, under §9.4.

**C6, 7 Aug 2026.** This section also carried "`emlmenu` in `gui.sh` still uses
`windowraise` — known latent bug, unfixed." It does not and has not for some
time; `emlmenu` opens with `windowactivate --sync` then `windowfocus`, and
`grep -n windowraise harness/gui.sh` returns only `typein` and `raise`, in
both of which it is *followed* by `windowfocus`. The sentence is struck — a
false open-defect record costs the next reader a re-derivation.

### Shell cwd does not persist between Bash tool calls

`import`/`convert` failed with "unable to open image `out/shots/x4_raw.png'"
purely because a previous `cd` had not carried over. Either use absolute
paths or prefix every call with `cd $EML_DRIVE &&`. Do not assume the
directory you were in one call ago.

### Praat allows exactly one pause form at a time

`needclear` exists for this. If a pause form is open, opening a wrapper does
nothing and the failure is silent. Dialogs also *cascade* — dismissing
`Export Complete` drops you back to `Analysis complete`, which is still a
pause form. Drain the whole stack before starting the next wrapper.

### Each dialog is a NEW pause window — never cache the window id

`curpause` re-searches and filters on `IsViewable` for exactly this reason. A
cached id from the previous dialog will still resolve and `windowactivate`
will succeed against a destroyed window, so the failure is silent.

### `infotext` takes no argument

`infotext <path>` prints to stdout and **does not create the file.** Use
argument-less `infotext` with a shell redirect:

```bash
infotext > out/w5_run_info.txt
```

**C8, 7 Aug 2026 — corrected, and the function now refuses.** This used to say
`infotext <path>` "prints to stdout, **exits 1**, and does not create the
file". The "does not create the file" half was right; "exits 1" was wrong —
it exited **0**, which is the worse case and the reason to care. A caller
written as `infotext out/x.txt && wc -l out/x.txt` saw success and then read a
file that was never written; an exit 1 would have stopped it. `infotext` now
rejects an argument outright and returns 2, so the mistake is loud at the
first call rather than latent in the second.

### Blind `iconv -f UTF-16` is unsafe

Praat writes UTF-16 on Linux even under `--utf8`, but not always — the CSV
exports come out ASCII. `iconv -f UTF-16` on ASCII input emits nothing **and
exits 0**, so the file silently reads as empty. Sniff first:

```bash
file -b "$f" | grep -q "UTF-16" && iconv -f UTF-16 -t UTF-8 "$f" || cat "$f"
```

### Crop before reading, and magnify before ruling on a glyph

A full 1400x1000 screenshot costs ~1,900 tokens to read and invites
transcription error. A 524x218 dialog crop costs a fraction of that and is
exact. For anything turning on a single character — an eaten underscore, a
decimal place — crop tight and `-resize 800%` before reading. D79 is only
visible at 800%.

For dialogs taller than ~500px, capture in two halves rather than one
downscaled image; detail is lost in the resize.

### `-trim` before a percentage `-crop` changes the geometry

Trim first and the percentages refer to the trimmed extent, not the original.
Crop by absolute pixels.

### Rule 5E violations in `--send` probes fail silently

A query command nested inside a function call in a probe script produces no
output and no error over `--send`. If a probe returns nothing, suspect the
probe before suspecting the plugin.

---

## 11. Window lookup: `_NET_WM_NAME`, not `WM_NAME` (added 2026-08-07)

`xdotool search --name` matches **`WM_NAME`**. GTK sets `WM_NAME` only when the
title is representable in Latin-1. Every EML wizard page title carries an em
dash, so those windows have **no `WM_NAME` at all** — only `_NET_WM_NAME`.
Verified on Praat 6.6.30 under both matchbox and openbox:

```
$ xprop -id 0x600017 WM_NAME        -> WM_NAME:  not found.
$ xprop -id 0x600017 _NET_WM_NAME   -> "Pause: Step 1 \342\200\224 Choose data"
$ xdotool search --name '^Pause:'   -> (nothing, rc=1)
```

The dialog is on screen and taking clicks; only the lookup is blind. It reads
as a **hung walk**, not as a lookup failure — that is what makes it expensive.
An ASCII-titled pause window *does* carry `WM_NAME`, so a probe written with a
plain title will not reproduce it.

A UTF-8 locale does **not** fix this. `LC_ALL=C.UTF-8` repairs `xwininfo`'s
*display* of the title, but no locale can restore a property the toolkit never
set. (`harness/walks/d117/lib.sh` sets `LC_ALL` for the display half; the
lookup half is `_NET_CLIENT_LIST`.)

Use `xwins` / `winname` / `findwin` / `pausewin` in `gui.sh`, which walk
`_NET_CLIENT_LIST` — the window manager's own list of managed top-levels, kept
by matchbox and openbox alike. It also excludes the withdrawn husks Praat
leaves behind for every dismissed pause dialog, which `xdotool search` returns
forever. `harness/walks/d117/lib.sh:pwin` is the same route; keep them in step.

Evidence: `evidence/walks/gui_harness/` (`before_after.txt`, `walk_log.txt`,
`walk_page1..3.png`, `manifest.csv`).
