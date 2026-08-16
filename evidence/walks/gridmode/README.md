# C1 — the gridline-mode dead-end dialog, driven

**Re-driven 16 August 2026.** Everything in this directory except this file and
`manifest.csv` is the output of that drive; the four `*.log` files and the seven
`*_config_*.txt` files are new, and all eleven `prefix_*.png` came back
**byte-identical** to the 8 August captures they replace. What changed and why
is under "The 16 August re-drive" below — the short version is that the walk had
been addressing the wrong control since 14 August and reporting success.

Four runs of `harness/walks/gridmode/walk.sh`, two graph dialogs each, on the
parallel rig (`GEOM=1400x1600x24`, Praat 6.6.30, Xvfb + openbox). The pre-fix
runs drove the **whole `plugin/` tree at `236b915`**, extracted with `git
archive 236b915 plugin`; the fixed runs drove the working tree. (The 8 August
runs swapped in only `eml-graphs-form.praat` at that revision. A whole-tree
checkout is what is reproducible now: the rest of the plugin has moved 23,000
lines since, so a tree that is one old file inside a new plugin is not a
revision of anything.)

Each run: draw a **Scatter Plot** (four-option Gridline mode) in Advanced mode
with a chosen gridline setting, finish the workflow so the config is written,
**relaunch Praat**, then open a **Histogram** (two-option Gridline mode). The
relaunch is the point — the value crosses the two dialogs on disk, in
`<prefs>/eml-graphs-config.txt`, which is why the pre-fix failure survives a
restart.

| run | scatter set to | `gridlineMode:` written | histogram menu renders | Draw |
|---|---|---|---|---|
| `prefix_off` | Off | 4 | **blank** | **REFUSED** |
| `fixed_off` | Off | 4 | Off | accepted |
| `prefix_horiz` | Horizontal only | 2 | **Off** | accepted |
| `fixed_horiz` | Horizontal only | 2 | Horizontal | accepted |

Row 1 is C1's first half: an `optionmenu` whose default index exceeds its
option count draws empty and Praat then refuses the form, so the page has no
Draw path out of it. Row 3 is C1's second half: index 2 is in range on the
two-option menu, so nothing complains — it just means "Off" there, and the
user who asked for horizontal gridlines gets none.

**The fourth column is now in the logs, not only in the screenshots.** The walk
OCRs the closed control and writes it out:

```
$ grep 'renders:' *.log
fixed_horiz.log:[fixed_horiz] histogram Gridline mode renders: "Horizontal" (widget ordinal 10)
fixed_off.log:[fixed_off] histogram Gridline mode renders: "off" (widget ordinal 10)
prefix_horiz.log:[prefix_horiz] histogram Gridline mode renders: "off" (widget ordinal 13)
prefix_off.log:[prefix_off] histogram Gridline mode renders: "" (widget ordinal 13)
```

`validate/v31_gridmode.R` asserts those four lines, so the table above is
checked rather than illustrated. (Case is folded on both sides: tesseract
returns "Off" as "off" on this font at this size, which is measured, not
tolerated — see the note in `harness/walks/gridmode/lib.sh:gfind`.)

## The 16 August re-drive — why this evidence was replaced

The committed evidence did not reproduce, for two stacked reasons, neither of
them caused by any change made in the week before. A counterfactual against
`0fdc21e^`'s plugin gives the identical wrong result.

**1. The geometry was documented and not enforced.** `GEOM=1400x1600x24` is
required: the advanced Scatter page asks for ~999 px of fields, and at the rig's
default 1280x900 the window manager clamps it and the Go Back / Quit / Beginner
/ Draw row is off the bottom of the screen. `gbtn` then found **zero** buttons,
the page never advanced, and the walk went on reporting on pages it had not
reached. The walk now refuses below 1400x1600 (`ggeom`) with a message that
names the measured size, the required size and the rig command.

**2. At the right geometry it set the wrong controls and exited 0.** `walk.sh`
addressed Gridline mode as "widget ordinal 13". D11 (14 Aug) made the two group
fields conditional on the "Use group column" checkbox, which took two widgets
off the top of the Scatter page; Gridline mode is now ordinal **11** and ordinal
13 is **Output DPI**. So `walk.sh off` set Output DPI — a two-option menu — to
"item 4", landing on its last entry:

```
gridlineMode: 1      (the plugin default: Both. Never touched.)
outputDPI:    2      (600 dpi. Never asked for.)
```

and printed `accepted: Draw proceeded, no error dialog`, and exited 0.

This is `harness/MENU_MAP.md`'s lesson in a second address space. A positional
address silently outlives the layout it was measured against; it does not fail,
it operates on whatever moved into its place. The remedy is the same one that
closed the menu drift: **the control is found by the label the running form
draws, and the page is read back after every set.** `gset` in
`harness/walks/gridmode/lib.sh` refuses unless the named control renders what
was intended AND no other control on the page moved — the second half is what
catches Output DPI, because "set Gridline mode to Off" is violated as much by
silently changing the DPI as by leaving the gridlines alone.

The two trees prove the point between them in a single run: the pre-fix tree
predates D11, so its Gridline mode really is at ordinal 13, and the working
tree's is at 11. The same walk drove both correctly and logged which ordinal it
used each time. `v31` asserts both numbers.

## Note 1 — reading `*_4_histogram_dropped.png`

These are screenshots with the list open. GTK places the SELECTED item under
the pointer, so in `fixed_off` "Off" sits on the Gridline mode row and in
`fixed_horiz` "Horizontal" does. In `prefix_off` there is no selected item, so
the list is placed top-aligned instead and the first entry lands under the
pointer and takes the pointer's highlight. **That highlight is hover, not
selection** — do not read `prefix_off_4` as "Horizontal was selected". The
evidence that the control is unset is `prefix_off_3_histogram_dialog.png`
(closed and blank), `prefix_off_6_refusal.png` (Praat saying so), and now the
`renders: ""` line in `prefix_off.log`, which is the unambiguous one.

## Note 2 — why the error dialog is in its own file

Praat's message window sets no usable `_NET_WM_NAME` and is placed centred,
which on this rig puts it under the Praat Objects window; `windowactivate
--sync` returns 0 and does not lift it. `gerr` in
`harness/walks/gridmode/lib.sh` moves it to (30, 60) before shooting, so
`prefix_off_6_refusal.png` is the same dialog as the one partly visible behind
the Objects window in `prefix_off_5_after_draw.png`.

## Reproducing

The pre-fix tree is a checkout, not a hand-assembled directory:

```bash
mkdir -p /tmp/gridmode_prefix
git archive 236b915 plugin | tar -x -C /tmp/gridmode_prefix

GEOM=1400x1600x24 harness/walks/rig.sh up 2
I=1 PLUGIN_SRC=/tmp/gridmode_prefix/plugin harness/walks/gridmode/walk.sh off   prefix_off
I=2                                        harness/walks/gridmode/walk.sh off   fixed_off
I=1 PLUGIN_SRC=/tmp/gridmode_prefix/plugin harness/walks/gridmode/walk.sh horiz prefix_horiz
I=2                                        harness/walks/gridmode/walk.sh horiz fixed_horiz
harness/walks/rig.sh down

praat --run harness/walks/gridmode/truth.praat > evidence/walks/gridmode/truth_table.csv
```

The 16 August drive ran all four on one instance (`I=4`, `:94`, same geometry)
rather than two in parallel; the walk relaunches Praat itself and does not care.
Drop `GEOM=` and the walk refuses rather than running — that is the fix for
problem 1 above, and it is the reason to run it that way rather than a caveat
about it.

Each leg takes about 100 s. It is slower than it was: reading a page back costs
one screenshot and ~40 OCR crops per snapshot, and there are two snapshots per
`gset`. That is the price of the addressing being checked.

To see the assertion fail — it is not a check until you have watched it go red:

```bash
GRID_SCATTER_FORCE=13 harness/walks/gridmode/walk.sh off breaktest
```

`GRID_SCATTER_FORCE` clicks a widget ordinal you name while still checking the
row the label is really on, so it reproduces exactly what a stale constant does.
It exits 1 and prints the control, the intended value and the rendered one.

`validate/v31_gridmode.R` asserts the committed halves of this that can be
asserted from files — the rendered values above, the widget ordinals each tree
used, the config values (including that Output DPI stayed at 1), the driver
logs, and the source-level invariants that stop the defect being reintroduced by
a new graph type.
