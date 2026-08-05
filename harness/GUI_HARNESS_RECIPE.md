# GUI Harness Recipe — driving the EML Praat Tools plugin under Xvfb

Date: 4 August 2026
Purpose: reproducible procedure for launching Praat interactively in the sandbox
and driving plugin menus/dialogs with xdotool. Every element below is
empirically verified in this session unless marked otherwise.

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

## 1. Prerequisites present in the sandbox

| Tool | Path / note |
|---|---|
| Praat full GUI | `/home/claude/praat` (6.6.30) |
| Praat barren | `/home/claude/praat_barren` |
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
lands at 442,444, 524x167).

---

## 2. Launch sequence

```bash
# 2.1 Clean slate — note: pkill -9 -x praat, NEVER pkill -f praat
#     (-f would match and kill the driving shell itself)
pkill -9 -x praat 2>/dev/null; pkill -9 -x Xvfb 2>/dev/null
pkill -9 -f matchbox 2>/dev/null; sleep 1
rm -f /tmp/.X99-lock /tmp/.X11-unix/X99        # stale lock => Xvfb exits 1

# 2.2 Display
Xvfb :99 -screen 0 1400x1000x24 > /home/claude/drive/out/xvfb.log 2>&1 &
sleep 3
export DISPLAY=:99
xdpyinfo | head -3                              # sanity check

# 2.3 Window manager
matchbox-window-manager -use_titlebar no > /home/claude/drive/out/wm.log 2>&1 &
sleep 2
pgrep -f matchbox        # NOT pgrep -x: process names >15 chars never match
```

### 2.4a Interactive / idle Praat — for menu driving

`--new-send <script>` makes Praat **exit when the script completes**, so it
cannot be used to leave Praat interactive. Launch with **no script argument**:

```bash
rm -f /home/claude/drive/prefs/pid /home/claude/drive/prefs/message
#   ^ stale locks => "An instance of Praat that is not me is already running."
#   Do NOT delete the whole pref dir — the plugin lives in it.
cd /home/claude
nohup ./praat --pref-dir=/home/claude/drive/prefs --utf8 \
  > /home/claude/drive/out/idle.log 2>&1 &
sleep 8
```

### 2.4b Script-driven Praat — blocks on `beginPause`, stays alive

```bash
nohup ./praat --new-send --pref-dir=/home/claude/drive/prefs --utf8 \
  /home/claude/drive/scripts/X.praat > /home/claude/drive/out/X.log 2>&1 &
```

---

## 3. Interaction primitives (all verified)

```bash
# Locate windows
xdotool search --name "." getwindowname %@
#   => matchbox / Praat / Praat Objects / Praat Picture / Pause: <title>
W=$(xdotool search --name "^Pause:" | head -1)
xdotool getwindowgeometry $W

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
import -window root /home/claude/drive/out/shot.png
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
| `pgrep -x matchbox-window-manager` empty | name >15 chars | `pgrep -f matchbox` |
| Typed text never lands | no window manager | run matchbox |
| Praat exits right after launch | `--new-send` with a non-blocking script | launch with no script arg |
| "instance ... already running" | stale `pid`/`message` in pref dir | delete just those two files |
| Submenu won't open on hover/click | Praat/matchbox behaviour | `xdotool key Right` |
| exit 124 from `timeout` | modal dialog is up | expected; not a failure |
| Killing own shell | `pkill -f praat` | use `pkill -9 -x praat` |

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
./praat --pref-dir=/home/claude/drive/prefs --utf8 --send script.praat
```

`An instance of Praat that is not me is already running.` on stderr is
**informational, not an error** — the script IS delivered to the running
instance and executed there. Verified 2026-08-05.

This does not replace GUI clicking for wrapper dialogs (`beginPause:` still
renders a real dialog that needs clicks), but it does replace clicking for
*state setup*: `selectObject:`, object creation, cleanup.

### 9.2 Info window as exact text

`/home/claude/drive/scripts/_dumpinfo.praat`:

```praat
writeFileLine: "/home/claude/drive/out/info.txt", info$ ()
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

### 9.4 `windowactivate` does not work under matchbox — use `windowraise`

```
Your windowmanager claims not to support _NET_ACTIVE_WINDOW ...
```

`xdotool windowactivate` and `getactivewindow` both fail. `xdotool windowraise
<id>` works and is what `emlmenu` needs before clicking the menubar. This bites
specifically after the Info window has been raised: Info is 620x400 at 0,0 and
covers the Objects menubar at y=14, so the menu click lands on Info and nothing
happens — silently.

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
