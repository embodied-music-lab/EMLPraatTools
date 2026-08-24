# Praat facts

Things Praat itself does, each with the measurement it rests on and the
version it was measured on. Nothing here is about the plugin's own logic;
it is all about the interpreter, the toolkit and the GUI underneath it.

These entries exist because each one has cost this project hours twice. A
fact that lives only in a session transcript gets re-derived by the next
person writing a rig, and re-deriving fact 1 means watching Praat abort and
assuming the plugin is at fault.

Where an entry restates something the PraatGen knowledge base carries,
PraatGen governs. Facts 3, 4 and 5 are candidates to relay upstream: the
PKB's `COMMANDS_Table.txt` and APPENDIX_C carry neither the history
functions nor `Debug`, so nothing there contradicts them.

**Every entry names what was measured, on which build, and what a rig
should do about it.** An entry that cannot say all three does not belong
here.

The rig-facing half of facts 1 to 4 — the exit codes a driver sees in its
own log, and the call to make instead — is in
`harness/GUI_HARNESS_RECIPE.md` §12.

---

## 1. The stop-recording commands abort Praat when called from a script under `--run`

Both of them, by two different routes.

### Measured, Praat 6.6.30, Linux, 21 August 2026

A probe staged inside `plugin/scripts/` so that the barrel's relative
includes resolve — includes `eml-lib.praat`, runs `eml-record-start.praat`
through `runScript:`, puts one step in the buffer with `@emlRecordStep`,
then reaches the stop command the way a menu would:

```praat
include eml-lib.praat
runScript: "eml-record-start.praat"
@emlRecordStep: "analysis", "probe step", "", "; probe", ""
runScript: "eml-record-save.praat"      ; or eml-record-open.praat
appendInfoLine: "RETURNED (no crash)"
```

| command | `praat --run`, no DISPLAY | `praat --run`, DISPLAY set | `--send` to a live GUI instance |
|---|---|---|---|
| `Stop recording and save...` | Trace/breakpoint trap, exit **133** | Trace/breakpoint trap, exit **133** | renders `Pause: Stop recording and save`, blocks |
| `Stop recording and open` | Aborted, exit **134** | Aborted, exit **134** | completes; ScriptEditor window appears |

`Stop recording and save...` dies at its `beginPause:` with the toolkit
error of fact 2. `Stop recording and open` dies further in, at its own
`Read from file: openPath$`, and Praat prints its own crash banner:

```
Crashing bug: Praat will crash. Please notify the authors ...
No sequential unique ID for class Script (selectObject).
Script line 58743 not performed or completed:
« Read from file: openPath$ »
```

The `RETURNED (no crash)` line printed on neither run.

Note which variable moves and which does not. Adding a display changes
nothing; changing `--run` for a live GUI instance changes everything. The
crash belongs to batch mode, not to headlessness.

### What a rig should do

Call what the wrappers call underneath:

```praat
@emlRecordFlush: outPath$      ; writes the script
@emlRecordDiscard              ; ends the recording
```

`@emlRecordFlush` writes and leaves the recording running; ending it is
`@emlRecordDiscard`. Together they are the whole of what the menu command
does minus its dialog and its editor. `harness/roundtrip/drive.praat`
states this in its own header and takes that route; `harness/record_e2e/`
and `harness/vecfig/record_drive.praat` flush the same way.

A rig that wants to exercise the *shipped wrapper* rather than the
procedures underneath has one route and it is not `--run`: send the script
to a live GUI instance and click the dialog.

---

## 2. `beginPause:` cannot be reached from `praat --run`, display or no display

The save panel is the case that bites, because it sits at the end of every
analysis path and a rig reaches it before it reaches anything else
interesting.

### Measured, Praat 6.6.30, Linux, 21 August 2026

`@emlSavePanel: 0, "probe", "/tmp"` after a descriptive analysis, run twice
from the same probe file:

| launch | result |
|---|---|
| `praat --run`, no DISPLAY | Trace/breakpoint trap, exit **133** |
| `praat --run`, DISPLAY=:81 with Xvfb and matchbox up | Trace/breakpoint trap, exit **133** |

Identical output on both, ending:

```
(process:23300): Gtk-CRITICAL **: _gtk_css_lookup_resolve: assertion ... failed
(process:23300): GLib-GObject-CRITICAL **: g_object_set_data_full: assertion 'G_IS_OBJECT (object)' failed
(process:23300): Gtk-ERROR **: Can't create a GtkStyleContext without a display connection
```

The message names a display, and the display is a red herring: the second
run had one. `praat --run` does not start the toolkit at all, so there is no
connection for the style context to be made against and no `DISPLAY` value
can supply one.

This is the same wall every `beginPause:` in the plugin presents, and every
EML wrapper uses `beginPause:` rather than `form:`. Thirteen wrappers, one
wall.

### What a rig should do

One of two things, and the choice is not stylistic:

- **Drive the real dialog.** Launch an interactive instance with no script
  argument, send state-setup scripts to it with `--send`, and click the
  dialog with xdotool. `harness/GUI_HARNESS_RECIPE.md` §2.4a and §9.1 are
  the procedure.
- **Excise the dialog.** Locate each `beginPause:`…`endPause` region
  mechanically, replace it with a generated procedure that assigns exactly
  the variables that stanza's fields would assign plus the button pressed,
  and hash the shipped file minus those regions against the twin minus the
  injected lines. `harness/edittable/` established the technique and
  `harness/roundtrip/run.sh` generalises it across four files.

What a rig must not do is add Xvfb to a `--run` driver and expect the pause
to render.

---

## 3. Praat's command history is not reachable from a script

There is no script-context `Clear history` and no history accessor in the
formula language. The history is a human-facing feature reached through
**Edit > Paste history** in a script window.

### Measured by Ian Howell, 20 August 2026, Praat 6.6.30 and 7.0.01

In a plain script and again inside a script run from a ScriptEditor, on
both builds. No context reached it.

### Re-measured here, Praat 6.6.30, Linux, 21 August 2026

Two of those contexts are reproducible in the sandbox and both agree. Under
`praat --run`:

```
Clear history      -> Error: Command “Clear history” not available for current selection.
h$ = history$ ()   -> Error: Unknown function «history$» in formula.
x$ = historyLines$ () -> Error: Unknown function «historyLines$» in formula.
```

Sent to a live GUI instance with `--send`, the instance's own stderr
carries the identical two errors:

```
PRAAT ERROR MESSAGE:
Command “Clear history” not available for current selection.
...
PRAAT ERROR MESSAGE:
Unknown function «history$» in formula.
```

So the refusal is not an artefact of batch mode. The ScriptEditor context
and the 7.0.01 build rest on Ian's measurement; this image carries 6.6.30
alone.

### What a rig should do

Stop planning around it. A design that harvests Praat's history to learn
what a user did — in a rig or in the plugin — has no mechanism to run on.
Fact 5 is why that matters: the history holds exactly the thing the
plugin's own recorder cannot see, and it is unreachable from code.

---

## 4. Tracing switches on from a script, and says nothing about a hand edit

`Debug: 1, 0` switches Praat's tracing on and `Debug: 0, 0` switches it
off, from an ordinary script, with no dialog and no display.

### Measured, Praat 6.6.30, Linux, 21 August 2026 — and by Ian on macOS

The toggle:

```praat
Debug: 1, 0
Create Table with column names: "traceprobe", 2, "a"
Debug: 0, 0
```

Script completes, exit 0, both under `praat --run` and sent to a live GUI
instance. The trace lands in a file named `tracing` in the preferences
directory in force — `/root/.praat-dir/tracing` for a default launch,
`<pref-dir>/tracing` under `--pref-dir=`. It is truncated at each switch-on
and stamped:

```
Melder_setTracing (melder_debug.cpp:282): switch tracing on in Praat version 6.6.30 at Fri Aug 21 03:30:43 2026
```

Three script lines produced 26 trace lines under `--run` and 101 in the GUI
instance. What they hold, for a script, is interpreter dispatch and object
construction:

```
Interpreter_resume (Interpreter.cpp:2355): going to handle line 3: Create Table with column names: "traceprobe", 2, "a"
NEW1_Table_createWithColumnNames (praat_Stat.cpp:238): args 0x85d1a60
Thing_newFromClass (Thing.cpp:52): created Table
```

### And what it does not hold, measured by Ian Howell, 20 August 2026

For a hand edit committed in Praat's own TableEditor, on Linux 6.6.30 and
on macOS, the trace shows **only glyph-painting calls**. No command
dispatch, no cell coordinates, no values. The edit is invisible to the
facility that traces everything a script does.

That asymmetry follows from the trace above rather than contradicting it:
the lines that name a command are `Interpreter_resume` lines, and an editor
action never goes through the interpreter.

### What a rig should do

Use tracing to find out what a *script* did — which dispatch ran, which
object was constructed, where an argument went. Do not build anything that
expects to learn what a *person* did in an editor from it. Read
`<pref-dir>/tracing` rather than stdout, and switch tracing off in the same
script that switched it on: the file is truncated on the next switch-on, so
a leftover `Debug: 1, 0` costs the next run its evidence.

---

## 5. The TableEditor's edits reach the history; the plugin's edits do not

### Measured by Ian Howell, 20–21 August 2026, Praat 6.6.30

A cell changed by hand in Praat's native TableEditor enters Praat's command
history in replayable syntax:

```praat
Set numeric value: 1, "Speaker", 1.5
```

The same cell changed through the plugin's edit-table wrapper enters the
history as a bare invocation, with every command the script ran inside it
invisible:

```praat
runScript: "...eml-edit-table.praat"
```

### Why this is the argument for the plugin's own recorder

The two capture mechanisms are exact complements, and neither is a subset
of the other:

| what happened | Praat's history | the plugin's recorder |
|---|---|---|
| hand edit in the TableEditor | replayable line | nothing |
| plugin analysis, figure, save | opaque `runScript:` | the full annotated step |

`docs/RECORDER_ROUNDTRIP_FINDINGS.md` measures the recorder's side of that
table: it reproduces analysis, figures and saved output byte for byte, and
says nothing about a hand edit to the data. Praat's history covers exactly
that gap — and fact 3 says no code can read it.

So the plugin's recorder is not a re-implementation of something Praat
already offers. It records the half Praat's history reduces to one opaque
line, and the half it cannot record is the half a script cannot reach
anyway.

### What a rig should do

Treat a recorded script as a statement about the plugin's operations and
about nothing else. A rig that stages a hand edit — as
`harness/roundtrip/` does, writing the cell directly — is testing the
script, not the editor, and should say so in its own header.

---

## 6. A pause dialog's height is a sum over its rows, and a comment row is not a constant

Measured 24 August 2026 on Praat 6.6.30 (June 30 2026), Linux, under
`Xvfb :N -screen 0 1400x2400x24` with `matchbox-window-manager
-use_titlebar no`, reading `xdotool getwindowgeometry --shell` on the
`Pause: <title>` window. Synthetic dialogs of known composition, one row
type at a time and then mixed.

    height_px = 76
              + 22 * comment rows
              + 32 * (optionmenu rows + boolean rows)
              + 37 * (real + positive + sentence + PAIRED rows)

A paired row -- two adjacent numeric or sentence fields whose labels begin
`left ` and `right ` -- is ONE row of two boxes and costs 37, and it widens
the dialog from 524 px to 560 px. The 76 px of chrome does not depend on
the BUTTON COUNT: measured identical at one, two, three and four buttons.

**A comment row is 22 px or 37 px, and which one is not a matter of
character count.** Two things were measured to move it:

  - the LAST row of a dialog, when it is a comment, is always 37;
  - some comment TEXTS cost 37 in a non-last position and others 22.
    Ninety `x` characters cost 22. `one shared vertical axis.` costs 37 and
    `shared vertical axis` costs 22. `Same measurement:` costs 27. It
    tracks the text's rendered extent, not its length.

**WHAT A RIG SHOULD DO ABOUT IT.** Do not read a row count back out of a
height. Take the census from the source -- it is exact, and it is what the
ruling's per-page counts are about -- and use the height as a CONSISTENCY
CHECK on it: predict the delta between two versions of one page and see the
render agree. Done that way it is precise. The line chart's grouping change
predicted −15 (a shortened heading) +22 (📊 Analysis) −22 (two 📐 headings
merged to one) −37 (two label rows paired into one) +22 (🎛️ Layout) = −30,
and the page measured 817 px before and 787 px after; the beginner branch
predicted +66 −15 = +51 and measured 347 px before and 398 px after.

**AND A COMMENT WIDER THAN ITS DIALOG OVERPRINTS THE ROW BELOW IT.** GTK
wraps the comment onto a second line; Praat has allotted the row one line's
advance; the overflow is drawn on top of the next row's label. The dialog's
width comes from its widest row, and on a column-mapping page the rows are
built from the user's own column names -- so the same page overprints on one
table and not on another. Photographed on six pages, and filed in
`docs/OPEN_ITEMS.md` under section B.
