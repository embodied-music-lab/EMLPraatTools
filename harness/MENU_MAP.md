# Verified render map — `Objects → New → ⁺EML Tools`

Praat 6.6.30, Xvfb :99 1400x1000x24, matchbox window manager.
Source: `evidence/shots/`.

## Which layout each part of this file is in — READ THIS FIRST

This file holds coordinates measured under **two different window-manager
layouts, 20 px apart**. It used to declare one layout for the whole file in the
line above, which was false from 8 August onwards: a reader who trusted that
header and then used the 8 August table added the 20 px twice.

| Part of this file | Layout | matchbox launched as | relation to `gui.sh` |
|---|---|---|---|
| §Objects window chrome · §Opening the submenu · §Entry coordinates (click x≈500) · §Loading an arbitrary table · §6 August 2026 | **titlebar ON** — menu bar at y=34, `⁺EML Tools` at y=467 | `matchbox-window-manager` (default) | the **base** values in `gui.sh`, *before* `EML_YOFF` is added |
| §8 August 2026 — this table was itself one row short | **titlebar OFF** — menu bar at y=14, `⁺EML Tools` at y=447 | `matchbox-window-manager -use_titlebar no` | the values `gui.sh` **actually clicks**: base + `EML_YOFF` |

`EML_YOFF` in `gui.sh` is exactly this difference. Anchor —
`grep -n 'EML_YOFF=' harness/gui.sh`:

```bash
EML_YOFF=${EML_YOFF:--20}
```

It defaults to **-20**, i.e. the no-titlebar layout, so the 8 August table is
the one that matches what the harness clicks today and the earlier sections are
the base values it adds the offset to. **Do not add 20 to the 8 August numbers,
and do not subtract 20 from them.** The 5 August sections carry their own note
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
