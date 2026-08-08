# C1 — the gridline-mode dead-end dialog, driven

Four runs of `harness/walks/gridmode/walk.sh`, two graph dialogs each, on the
parallel rig (`harness/walks/rig.sh up 2`, `GEOM=1400x1600x24`, Praat 6.6.30,
Xvfb + openbox). Instance 1 ran a tree whose `plugin/graphs/eml-graphs-form.praat`
is `236b915` verbatim (`/home/claude/rig/plugin_prefix`, built with
`git show HEAD:...`); instance 2 ran the working tree. Everything else in both
trees is identical.

Each run: draw a **Scatter Plot** (four-option Gridline mode) in Advanced mode
with a chosen gridline setting, finish the workflow so the config is written,
**relaunch Praat**, then open a **Histogram** (two-option Gridline mode). The
relaunch is the point — the value crosses the two dialogs on disk, in
`<prefs>/eml-graphs-config.txt`, which is why the pre-fix failure survives a
restart.

| run | scatter set to | `gridlineMode:` written | histogram menu shows | Draw |
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

## Note 1 — reading `*_4_histogram_dropped.png`

These are screenshots with the list open. GTK places the SELECTED item under
the pointer, so in `fixed_off` "Off" sits on the Gridline mode row and in
`fixed_horiz` "Horizontal" does. In `prefix_off` there is no selected item, so
the list is placed top-aligned instead and the first entry lands under the
pointer and takes the pointer's highlight. **That highlight is hover, not
selection** — do not read `prefix_off_4` as "Horizontal was selected". The
evidence that the control is unset is `prefix_off_3_histogram_dialog.png`
(closed and blank) and `prefix_off_6_refusal.png` (Praat saying so).

## Note 2 — why the error dialog is in its own file

Praat's message window sets no usable `_NET_WM_NAME` and is placed centred,
which on this rig puts it under the Praat Objects window; `windowactivate
--sync` returns 0 and does not lift it. `gerr` in
`harness/walks/gridmode/lib.sh` moves it to (30, 60) before shooting, so
`prefix_off_6_refusal.png` is the same dialog as the one partly visible behind
the Objects window in `prefix_off_5_after_draw.png`.

## Reproducing

```
GEOM=1400x1600x24 harness/walks/rig.sh up 2
I=1 PLUGIN_SRC=<pre-fix tree> harness/walks/gridmode/walk.sh off   prefix_off
I=2                           harness/walks/gridmode/walk.sh off   fixed_off
I=1 PLUGIN_SRC=<pre-fix tree> harness/walks/gridmode/walk.sh horiz prefix_horiz
I=2                           harness/walks/gridmode/walk.sh horiz fixed_horiz
harness/walks/rig.sh down
```

`validate/v31_gridmode.R` asserts the committed halves of this that can be
asserted from files — the config values, the driver logs, and the source-level
invariants that stop the defect being reintroduced by a new graph type.
