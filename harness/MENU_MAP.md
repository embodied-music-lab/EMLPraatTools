# Verified render map — `Objects → New → ⁺EML Tools`

**Current table: §16 August 2026, measured on Praat 6.6.30 (June 30 2026).**
Xvfb 1400x1000x24, matchbox window manager. Source: `evidence/shots/`, and the
16 August drive's own shots.

**ATTRIBUTION** — Framework: EML PraatGen by Ian Howell, Embodied Music Lab —
www.embodiedmusiclab.com. Code generation: Claude (Anthropic). Script author:
Ian Howell — created and verified by this individual.

## Which layout each part of this file is in — READ THIS FIRST

This file holds coordinates measured under **two different window-manager
layouts, 20 px apart**. It used to declare one layout for the whole file in the
line above, which was false from 8 August onwards: a reader who trusted that
header and then used the 8 August table added the 20 px twice.

| Part of this file | Layout | matchbox launched as | relation to `gui.sh` |
|---|---|---|---|
| §Objects window chrome · §Opening the submenu · §Entry coordinates (click x≈500) · §Loading an arbitrary table · §6 August 2026 | **titlebar ON** — menu bar at y=34, `⁺EML Tools` at y=467 | `matchbox-window-manager` (default) | the **base** values in `gui.sh`, *before* `EML_YOFF` is added |
| §8 August 2026 — this table was itself one row short | **titlebar OFF** — menu bar at y=14, `⁺EML Tools` at y=447 | `matchbox-window-manager -use_titlebar no` | superseded — see the 16 August table |
| §15 August 2026 — the recorder group | **titlebar OFF** — menu bar at y=14, `⁺EML Tools` at y=447 | `matchbox-window-manager -use_titlebar no` | superseded — see the 16 August table |
| **§16 August 2026 — the current table** | **titlebar OFF** — menu bar at y=14, `⁺EML Tools` at y=447 | `matchbox-window-manager -use_titlebar no` | the values `gui.sh` **actually clicks**: base + `EML_YOFF` |

**Go to the 16 August section for anything you intend to click.** Everything
above it is kept as the record of how the numbers were arrived at, and three of
those sections are now wrong about what their coordinates open.

`EML_YOFF` in `gui.sh` is exactly this difference. Anchor —
`grep -n 'EML_YOFF=' harness/gui.sh`:

```bash
EML_YOFF=${EML_YOFF:--20}
```

It defaults to **-20**, i.e. the no-titlebar layout, so the 16 August table is
the one that matches what the harness clicks today and the earlier sections are
the base values it adds the offset to. **Do not add 20 to the 8, 15 or 16
August numbers, and do not subtract 20 from them.** The 5 August sections carry
their own note
that the 4 August values were ~20 px high; that was the same 20 px, discovered
from the other side.

### `-use_titlebar no` is NOT a "no chrome" flag

Measured 8 August 2026 on a fresh `Xvfb` + `matchbox-window-manager
-use_titlebar no` + Praat 6.6.30. The flag suppresses chrome on **maximized
top-level windows only**:

| Window | matchbox frame | client | chrome |
|---|---|---|---|
| Praat Objects / Praat Picture | 1400x1000 at 0,0 | 1400x1000 at 0,0 | **none** — zero offset |
| `Pause:` dialog | 532x159 at 434,420 | 524x135 at 438,440 | **20 px titlebar + close box, 4 px borders** |

**Every coordinate in this file is a root-absolute position on the Objects
window or one of its menus**, and the Objects window carries no chrome under the
flag — so none of the numbers below depend on this distinction, in either
layout. Coordinates you derive for a **dialog** while driving from this map do.
For those: `xdotool getwindowgeometry` on that pause dialog reported **442,460**
— the client origin (438,440) with the (+4,+20) frame offset applied a
**second** time, matching neither the frame nor the client. `xwininfo -id
<client>`'s "Absolute upper-left" gives the true 438,440. Never take a dialog
click coordinate from `getwindowgeometry`; use `xwininfo` (which is what `pgeom`
in `gui.sh` reads) or a screenshot.

Full measurement: `harness/GUI_HARNESS_RECIPE.md`, the section headed
``### matchbox must run with `-use_titlebar no` — but it is not a "no chrome" flag``.

---

## Correction to an earlier structural claim

setup.praat chains each entry's 4th argument ("after command") to the previous
entry's title with depth 1. Read as source, that *looks* like a deeply nested
cascade, and I previously recorded that as a usability defect.

**That reading is DISPROVEN.** The submenu renders **FLAT**, as a single list
with horizontal separator rules between groups — exactly as intended. Do not
report nesting as a finding.

---

## Objects window chrome (no objects loaded) — **titlebar ON layout**

Measured 5 August 2026 (re-measured; the 4 August values were ~20px high).
Subtract 20 from every y here for the `-use_titlebar no` layout `gui.sh`
defaults to.

- The window is 1392x976 at 8,40 — the matchbox titlebar takes the top rows,
  so **everything sits ~20px lower than the 4 August map recorded**. That map
  was taken without a titlebar and its y coordinates no longer work. Corrected
  by re-driving on 5 August 2026.
- Menu bar: `Praat  New  Open  Save(greyed)  Help`. `New` is at **(76,34)**.
- Bottom-left buttons `Rename… / Copy… / Inspect / Info / Remove` all greyed.
- Plugin-added items render with a superscript "+" prefix: `⁺EML Tools`,
  `⁺Stats Wizard...` etc.
- With one Table loaded, the first object row is at y=87 and the second at
  y=110.

## Opening the submenu — **titlebar ON layout**

`⁺EML Tools` is the LAST item in the `New` menu, at **y=467**.
Hover does not open it; click only highlights. Press `Right`.
The submenu spans x≈380–680; click at x≈500.

## Entry coordinates (click x≈500) — **titlebar ON layout, and one row stale**

These are the 5 August base values, kept because they are what the `gui.sh`
`EML_*` constants are literally written as (`EML_WIZARD=$((467 + EML_YOFF))`
and so on). They predate the fourteenth entry — see §8 August below for the
current table, which is the layout the harness actually clicks.

| y | Entry | Script |
|---|---|---|
| 467 | ⁺Stats Wizard... | eml-wizard.praat |
| | ─── separator ─── | |
| 493 | ⁺Describe Table column... | eml-describe-table.praat |
| 518 | ⁺Check normality (all columns)... | eml-check-normality.praat |
| | ─── separator ─── | |
| 544 | ⁺Compare two groups... | eml-compare-groups.praat |
| 569 | ⁺Compare paired/repeated... | eml-compare-paired.praat |
| 594 | ⁺Compare k groups (ANOVA)... | eml-compare-k-groups.praat |
| 619 | ⁺Compare k groups (Kruskal-Wallis)... | eml-compare-kw.praat |
| 644 | ⁺Compare two-way (ANOVA)... | eml-compare-twoway.praat |
| | ─── separator ─── | |
| 670 | ⁺Correlate two columns... | eml-correlate.praat |
| 695 | ⁺Linear regression... | eml-regress.praat |
| | ─── separator ─── | |
| 721 | ⁺Pairwise comparisons... | eml-pairwise.praat |
| | ─── separator ─── | |
| 747 | ⁺EML Graphs... | eml-graphs.praat |
| | ─── separator ─── | |
| 773 | ⁺Batch voice analysis... | eml-batch-process.praat |
| | ─── separator ─── | |
| 799 | ⁺Create Demo Table... | eml-create-demo.praat |
| 824 | ⁺Run Stats Demo | eml-stats-demo.praat — **REDO PENDING, SKIP** |
| | ─── separator ─── | |
| 850 | ⁺EML Stats Quick Start | eml-quick-start.praat |

**Linear mixed model was removed from the submenu on 5 August 2026** by
author ruling. Everything from *Pairwise comparisons* down therefore moved up
by one row (26px) from the coordinates recorded earlier that day. The module
files are still present; only the entry point is gone.

---

## Window identification — the trap that costs the most time

`xdotool search --name "^Pause"` returns **dead, unmapped windows** from
earlier in the session alongside the live one. Clicking coordinates derived
from a dead window sends the click to whatever is actually on top, which is
usually the Info window, and nothing appears to happen.

Always filter on viewability — and do not enumerate with `xdotool search
--name`, which is what the snippet here used to do. `search` reads `WM_NAME`,
which GTK leaves unset on any title that is not Latin-1, so every wizard page
(they all carry em dashes) was invisible to it: the loop above would have
found *nothing* on exactly the dialogs this file is about. See §11 of
`GUI_HARNESS_RECIPE.md`, and the banner at the top of `gui.sh`, which forbids
it in as many words. `_NET_CLIENT_LIST` is the window manager's own list, and
it already excludes the dead husks:

```bash
for x in $(xprop -root _NET_CLIENT_LIST | sed -n 's/.*# //p' | tr -d ','); do
    xwininfo -id "$x" | grep -q IsViewable \
        && echo "LIVE $x $(xdotool getwindowname $x)"
done
```

`gui.sh` wraps that as `livepause`. `gui.sh` also provides `raise
<name-regex>`, which raises a window and then **confirms it is the active
window** before returning, retrying up to six times and failing loudly rather
than letting the caller click blind.

Once you have the live id, read its position with `xwininfo`, not
`xdotool getwindowgeometry` — a pause dialog keeps its chrome even under
`-use_titlebar no`, and `getwindowgeometry` double-applies the (+4,+20) frame
offset on exactly these windows. See the chrome note at the top of this file.

## Loading an arbitrary table — **titlebar ON layout**

`Open > Read Table from comma-separated file...` at (262,189) opens a GTK
file chooser. `ctrl+l` then typing the absolute path is far more reliable
than navigating the tree. This is the route for the `validate/redpath/`
tables.

(262,189) is on the Objects window, so subtract 20 from the y for the
`-use_titlebar no` layout. The file chooser it opens is a **dialog**: take its
coordinates from `xwininfo`, never from `getwindowgeometry` — see the chrome
note at the top of this file.

---

## 6 August 2026 — three entries tabled, one moved — **titlebar ON (base) layout**

Batch voice analysis, Run Stats Demo and EML Stats Quick Start were removed
from the submenu by author ruling (see setup.praat for what was removed and
how to restore it).

**Create Demo Table moved up into Batch's old slot**, from 799 to 773 in base
coordinates. That is the trap this file exists to prevent: a stale constant
does not fail, it clicks whatever moved into its place. `EML_BATCH`,
`EML_STATSDEMO` and `EML_QUICKSTART` are kept in gui.sh as comments beside
the entries they addressed, so restoring a menu entry and restoring its
coordinate are visibly the same job.

## 8 August 2026 — this table was itself one row short — **titlebar OFF layout**

The submenu has **fourteen** entries, not thirteen: "Check & repair data..."
was added after EML Graphs and pushed Create Demo Table down a row. Anchor in
`setup.praat` —
`grep -n 'Check & repair data' plugin/setup.praat`:

```praat
Add menu command: "Objects", "New", "Check & repair data...", "-- eml data --", 1, "scripts/eml-check-data.praat"
```

`gui.sh` was updated for that — `EML_CHECKDATA` at base 773, `EML_DEMO` at base
799 — and this table was not. It listed thirteen entries and gave **Create Demo
Table as 753, which is now Check & repair data**. Anyone driving the menu from
this file rather than from `gui.sh` launched the wrong script, and, exactly as
the paragraph above says, the mis-click does not fail: it opens a real dialog
belonging to something else.

Re-measured 8 August by opening the submenu on `Xvfb :99` +
`matchbox-window-manager -use_titlebar no` (menubar at y=14, `⁺EML Tools` at
y=447 — the `EML_YOFF = -20` layout) and reading entry positions off the
screenshot. **These are the offset-applied numbers, not base values: they are
what `gui.sh` clicks with its default `EML_YOFF=-20`. Do not add the offset
again.**

| Entry | y | `gui.sh` constant |
|---|---:|---|
| Stats Wizard | 447 | `EML_WIZARD` |
| Describe Table column | 472 | `EML_DESCRIBE` |
| Check normality | 498 | `EML_NORMALITY` |
| Compare two groups | 525 | `EML_TWOGROUP` |
| Compare paired/repeated | 549 | `EML_PAIRED` |
| Compare k groups (ANOVA) | 574 | `EML_ANOVA` |
| Compare k groups (Kruskal-Wallis) | 599 | `EML_KW` |
| Compare two-way (ANOVA) | 624 | `EML_TWOWAY` |
| Correlate two columns | 649 | `EML_CORR` |
| Linear regression | 677 | `EML_REGRESS` |
| Pairwise comparisons | 702 | `EML_PAIRWISE` |
| EML Graphs | 727 | `EML_GRAPHS` |
| **Check & repair data** | **753** | `EML_CHECKDATA` |
| Create Demo Table | 778 | `EML_DEMO` |

Every `gui.sh` constant agrees with the measurement to within 2 px (glyph
ascender/descender differences move the measured text centre; the row pitch
is 25–26 px and the buttons are ~24 px tall, so 2 px is well inside target).

Evidence: `evidence/shots/menu_fourteen_entries_2026-08-08.png`, the submenu
open with all fourteen entries visible. The 6 August shot,
`evidence/shots/menu_after_tabling_2026-08-06.png`, is still the record for
the tabling and predates Check & repair data.

Recalibrate the same way: open it, screenshot, read the positions off the
image. Never infer them from a diff of setup.praat — the separators are menu
entries too and they do not all take the same height. And when you do,
recalibrate **`gui.sh` and this table together**: the two disagreeing is what
this section is a record of.

---

## 15 August 2026 — the recorder group, and the row `EML_DEMO` was clicking

**Measured 15 August 2026. Praat 6.6.30 (June 30 2026), Xvfb 1400x1000x24,
`matchbox-window-manager -use_titlebar no`, Objects window 1400x1000 at 0,0.
These are the offset-applied numbers — what `gui.sh` clicks with its default
`EML_YOFF=-20`. Do not add the offset again.**

The 13 August menu re-chain put a recorder group into `setup.praat` —
`-- eml record --`, then *Record script*, *Stop recording and open*, *Stop
recording and save...* — chained after *Check & repair data...*. That pushed
**Create Demo Table down three rows**, from 778 to 854, and `EML_DEMO` was left
at 779.

**779 is now *Record script*.** The consequence is the one this file exists to
prevent, in its purest form: nothing failed. `EML_DEMO` opened a real command,
which started a recording and returned, and every subsequent drive ran inside a
recording nobody had asked for. The 14 August audit lost a phantom recording to
it before its fleet had launched, and only noticed because the recorder
announced itself in the Info window.

The submenu now has **seventeen** entries. Every y below was read off the
screenshot as the text-band centre of its row, and then **proved by clicking
it** and recording the window that appeared:

| Entry | y | `gui.sh` constant | Proved by |
|---|---:|---|---|
| Stats Wizard... | 447 | `EML_WIZARD` | `Pause: EML Stats Wizard` |
| Describe Table column... | 472 | `EML_DESCRIBE` | `Pause: Describe Table Column` |
| Check normality (all columns)... | 498 | `EML_NORMALITY` | `Pause: Check Normality` |
| Compare two groups... | 525 | `EML_TWOGROUP` | `Pause: Compare Two Groups` |
| Compare paired/repeated... | 549 | `EML_PAIRED` | `Pause: Compare Paired Observations` |
| Compare k groups (ANOVA)... | 574 | `EML_ANOVA` | `Pause: Compare k Groups (ANOVA)` |
| Compare k groups (Kruskal-Wallis)... | 599 | `EML_KW` | `Pause: Compare K Groups (Kruskal-Wallis)` |
| Compare two-way (ANOVA)... | 624 | `EML_TWOWAY` | `Pause: Two-Way ANOVA` |
| Correlate two columns... | 649 | `EML_CORR` | `Pause: Correlate Two Columns` |
| Linear regression... | 676 | `EML_REGRESS` | `Pause: Simple Linear Regression` |
| Pairwise comparisons... | 702 | `EML_PAIRWISE` | `Pause: Pairwise Comparisons` |
| EML Graphs... | 727 | `EML_GRAPHS` | `Pause: EML Graphs` |
| Check & repair data... | 753 | `EML_CHECKDATA` | `Pause: EML — Check & repair data` |
| **Record script** | **779** | `EML_RECORD` *(new)* | Info window: `EML: recording started.`; pressed again, `Pause: Already recording` — *"A recording is already in progress with 0 step(s)"* |
| **Stop recording and open** | **804** | `EML_RECORD_OPEN` *(new)* | with a real analysis in the buffer, a script editor opened on `.../eml-recorded-scripts/eml-recorded-Sat_Aug_15_040533_2026.praat` |
| **Stop recording and save...** | **829** | `EML_RECORD_SAVE` *(new)* | `Pause: Nothing recorded yet` — *"The recording is running but no analysis has been captured yet, so there is nothing to save."* |
| **Create Demo Table...** | **854** | `EML_DEMO` *(was 779)* | `Pause: Create Demo Table` |

The last four rows are the correction. The first thirteen were already right,
twelve of them to within 1 px; `gui.sh` was rewritten to the proved values
anyway, so that the map, the constants and the pixels are one number rather
than three near ones. The rows that moved by a pixel are Describe Table column
(493→492 base), Compare two groups (544→545), Correlate (670→669), Linear
regression (695→696) and Pairwise (721→722) — glyph descenders move a measured
text centre, and the button is ~24 px tall, so none of them was ever a
mis-click. They are corrected because a map whose numbers are *nearly* the
constants invites the reader to decide which one is authoritative.

Evidence: `evidence/shots/menu_seventeen_entries_2026-08-15.png`, the submenu
open with all seventeen entries visible. Re-running the ink profile on that
committed file reproduces the y column above exactly, so the table can be
checked without re-driving anything. The 8 August shot,
`evidence/shots/menu_fourteen_entries_2026-08-08.png`, remains the record for
the state before the recorder group.

**Method notes for whoever re-measures next.**

- Read the row centres off the screenshot arithmetically rather than by eye:
  take the ink profile of the submenu column (x 380–670 in this layout) and
  take each contiguous dark band of more than three rows as one entry. Doing it
  by eye is how the 8 August table came out one entry short.
- **Do not dismiss a pause form with `Escape`.** Escape *stops* the form, and
  the wrapper then runs on past it and raises `Unknown variable ... This
  happened after you stopped the pause form` in an **untitled** Praat error
  box. That box is not in `_NET_CLIENT_LIST` — matchbox never manages it — so
  `findwin`, `pausewin` and `livepause` cannot see it, while it is modal enough
  that the next menu entry silently does nothing. Four entries read as "opens
  nothing" during this measurement for exactly that reason before the box was
  found on a screenshot. Dismiss it by clicking its OK, located from the
  screenshot rather than assumed.
- Two entries do not open a dialog at all on the happy path: *Record script*
  reports into the **Info window**, and *Stop recording and open* opens a
  **script editor**, whose window title is the script's path in curly quotes.
  A proof loop that only watches for `^Pause` will call both of them dead.

---

## 16 August 2026 — Batch voice analysis registered, and the five rows below it

**Measured 16 August 2026. Praat 6.6.30 (June 30 2026), Xvfb :150
1400x1000x24, `matchbox-window-manager -use_titlebar no`, Objects window
1400x1000 at 0,0. These are the offset-applied numbers — what `gui.sh` clicks
with its default `EML_YOFF=-20`. Do not add the offset again.**

`Batch voice analysis...` was registered again on 16 August (author ruling;
`plugin/setup.praat` lines 179–180, chained after `EML Graphs...`) and it
renders **ABOVE** `Check & repair data...`. The submenu now has **eighteen**
entries. One row was inserted at position 13, so the five entries below it each
moved down one row and **five `gui.sh` constants each addressed the row above
their entry**.

Nothing failed, again. This is the third time in nine days, and the shape is
identical each time: a stale menu constant opens whatever moved into its place.

### The five that were wrong, and what each one actually opened

Each superseded value was clicked on this rig before it was replaced. A
coordinate retired without a readback is a guess about what it used to do.

| Constant | old y | **old y opened** | new y | **new y opened** |
|---|---:|---|---:|---|
| `EML_CHECKDATA` | 753 | `Pause: Batch Voice Analysis` | **779** | `Pause: EML — Check & repair data` |
| `EML_RECORD` | 779 | `Pause: EML — Check & repair data` | **805** | Info: `EML: recording started.` |
| `EML_RECORD_OPEN` | 804 | Info: `EML: recording started.` | **830** | Info: `EML: nothing has been recorded yet.` / `The recording is still running.` |
| `EML_RECORD_SAVE` | 829 | Info: `EML: nothing has been recorded yet.` | **855** | `Pause: Nothing recorded yet` |
| `EML_DEMO` | 854 | `Pause: Nothing recorded yet` | **880** | `Pause: Create Demo Table` |

`EML_RECORD_OPEN` at 804 is the 15 August failure repeating exactly: it starts
a recording and returns, so every drive after it runs inside a recording nobody
asked for. `EML_DEMO` is the constant that was damaged the same way last time.

**THE ROW PITCH IS NOT 25.** Shifting these five by 25 would have put
`EML_CHECKDATA` on 778, `EML_RECORD` on 804 and `EML_DEMO` on 879. Two of those
land in the right band and one does not: measured, the pitch on this menu is
**26 px across a separator and 25 px within a group**, and `EML Graphs → Batch`
and `Batch → Check & repair` are both separator gaps. Arithmetic on an assumed
pitch is what this section exists to forbid.

### The full table — every row proved by clicking it

`EML_BATCH` is **new**. Its base value, 773, is the number the 6 August tabling
comment in `gui.sh` carried as *history* — the entry has come back to the slot
it was removed from. It is live and measured, not un-commented.

The **Ordinal** column is the entry's position among the submenu's *commands*
(GTK skips separators in keyboard navigation). It is what `gui.sh:emlitem` and
`harness/batchgui/run.sh` walk, and every one of the eighteen was driven and
read back independently of the pixel column.

| Entry | y | Ordinal | `gui.sh` constant | Proved by |
|---|---:|---:|---|---|
| Stats Wizard... | 447 | 1 | `EML_WIZARD` | `Pause: EML Stats Wizard` |
| Describe Table column... | 472 | 2 | `EML_DESCRIBE` | `Pause: Describe Table Column` |
| Check normality (all columns)... | 498 | 3 | `EML_NORMALITY` | `Pause: Check Normality` |
| Compare two groups... | 525 | 4 | `EML_TWOGROUP` | `Pause: Compare Two Groups` |
| Compare paired/repeated... | 549 | 5 | `EML_PAIRED` | `Pause: Compare Paired Observations` |
| Compare k groups (ANOVA)... | 574 | 6 | `EML_ANOVA` | `Pause: Compare k Groups (ANOVA)` |
| Compare k groups (Kruskal-Wallis)... | 599 | 7 | `EML_KW` | `Pause: Compare K Groups (Kruskal-Wallis)` |
| Compare two-way (ANOVA)... | 624 | 8 | `EML_TWOWAY` | `Pause: Two-Way ANOVA` |
| Correlate two columns... | 649 | 9 | `EML_CORR` | `Pause: Correlate Two Columns` |
| Linear regression... | 676 | 10 | `EML_REGRESS` | `Pause: Simple Linear Regression` |
| Pairwise comparisons... | 702 | 11 | `EML_PAIRWISE` | `Pause: Pairwise Comparisons` |
| EML Graphs... | 727 | 12 | `EML_GRAPHS` | `Pause: EML Graphs` |
| **Batch voice analysis...** | **753** | **13** | `EML_BATCH` *(new)* | `Pause: Batch Voice Analysis` |
| **Check & repair data...** | **779** | **14** | `EML_CHECKDATA` *(was 753)* | `Pause: EML — Check & repair data` |
| **Record script** | **805** | **15** | `EML_RECORD` *(was 779)* | Info: `EML: recording started.` |
| **Stop recording and open** | **830** | **16** | `EML_RECORD_OPEN` *(was 804)* | Info: `EML: nothing has been recorded yet.` with a recording live; `EML: nothing is being recorded.` without one |
| **Stop recording and save...** | **855** | **17** | `EML_RECORD_SAVE` *(was 829)* | `Pause: Nothing recorded yet` with a recording live; Info: `EML: no recording is in progress.` without one |
| **Create Demo Table...** | **880** | **18** | `EML_DEMO` *(was 854)* | `Pause: Create Demo Table` |

The first twelve rows are unchanged from 15 August — the new entry lands below
`EML Graphs...`, so nothing above it moved. `EML_GRAPHS` (753's neighbour
above) was re-driven anyway rather than assumed, and still opens `Pause: EML
Graphs`.

Evidence: `evidence/shots/menu_eighteen_entries_2026-08-16.png`, the submenu
open with all eighteen entries visible. Re-running the ink profile on that
committed file reproduces the y column above exactly:

```bash
# contiguous dark row-bands of the submenu column, x 390..670
python3 - "$PWD/evidence/shots/menu_eighteen_entries_2026-08-16.png" <<'PY'
import sys
from PIL import Image
im = Image.open(sys.argv[1]).convert("L"); px = im.load(); w, h = im.size
rows = [any(px[x, y] < 128 for x in range(390, 670)) for y in range(h)]
start = None
for y in range(h + 1):
    if y < h and rows[y]:
        if start is None: start = y
    elif start is not None:
        if y - start > 3: print((start + y - 1) // 2, end=" ")
        start = None
print()
PY
# -> 447 472 498 525 549 574 599 624 649 676 702 727 753 779 805 830 855 880
```

The 15 August shot, `menu_seventeen_entries_2026-08-15.png`, remains the record
for the state before Batch voice analysis was registered.

### The keyboard walk, and what it does and does not fix

`gui.sh` gained `emlitem <ordinal>` on 16 August, and `demo` — the one helper
in that file that drives a menu entry — now uses it. The route is
`harness/batchgui/run.sh`'s, unchanged: click `New`, `Up` (wraps to the last
item of the New menu, which is where Praat puts a plugin's cascade header, so
the walk does not depend on how many commands Praat's own New menu carries),
`Right` (opens the cascade and selects item 1), `Down` × (n−1), `Return`.

**It is immune to** the row pitch (24/25/26 px, separator-dependent), to
`EML_YOFF` — the 20 px the entire table moved on 6 August when the titlebar
went away — and to where the window manager puts the Objects window. Those
three between them account for every recalibration this file records that was
*not* a menu change.

**It is not immune to the menu being reordered.** Today's regression moved
`Check & repair data` from ordinal 13 to 14 exactly as it moved it from y 753
to y 779, and a stale ordinal opens the neighbour just as silently as a stale
coordinate does. `harness/batchgui/run.sh` is the demonstration: its whole
before/after pair exists because ordinal 13 means a different command depending
on whether the batch entry is registered.

So the walk carries **less state, not less obligation to re-measure**. Both
addresses are on one line per entry in `gui.sh` for that reason — a menu change
updates them together, or it has not been done.

**Method notes for whoever re-measures next.** The 15 August notes above still
apply in full — read the row centres off the ink profile rather than by eye,
never dismiss a pause form with `Escape`, and remember that *Record script*,
*Stop recording and open* and *Stop recording and save...* report into the
**Info window** rather than opening a `Pause:` window on some paths. Two more
from this pass:

- **Drive each entry from a fresh Praat.** The recorder entries are stateful
  and one probe changes what the next one reports. Every readback above came
  from an instance started for it, except the three that deliberately share a
  session because the recording had to be live to tell the two "Stop
  recording" wrappers apart.
- **The no-Table guard makes ordinals 2–11 indistinguishable.** Walked with an
  empty Objects window, every one of them answers `Pause: Cannot start this
  tool` — a real dialog, from the right wrapper, that identifies nothing. Load
  a Table first. That readback is the "opens a real dialog belonging to
  something else" failure wearing its most convincing disguise: it is not even
  the wrong dialog, it is the right dialog saying nothing.
