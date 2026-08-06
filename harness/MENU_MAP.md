# Verified render map — `Objects → New → ⁺EML Tools`

Date: 5 August 2026 (coordinates re-measured; 4 August values were ~20px high).
Praat 6.6.30, Xvfb :99 1400x1000x24, matchbox WM with titlebar.
Source: `evidence/shots/` — re-driven during the D93 fix.

---

## Correction to an earlier structural claim

setup.praat chains each entry's 4th argument ("after command") to the previous
entry's title with depth 1. Read as source, that *looks* like a deeply nested
cascade, and I previously recorded that as a usability defect.

**That reading is DISPROVEN.** The submenu renders **FLAT**, as a single list
with horizontal separator rules between groups — exactly as intended. Do not
report nesting as a finding.

---

## Objects window chrome (no objects loaded)

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

## Opening the submenu

`⁺EML Tools` is the LAST item in the `New` menu, at **y=467**.
Hover does not open it; click only highlights. Press `Right`.
The submenu spans x≈380–680; click at x≈500.

## Entry coordinates (click x≈500)

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

Always filter on viewability:

```bash
for x in $(xdotool search --name "^Pause" 2>/dev/null); do
    xwininfo -id "$x" | grep -q IsViewable && echo "LIVE $x $(xdotool getwindowname $x)"
done
```

`gui.sh` provides `raise <name-regex>`, which raises a window and then
**confirms it is the active window** before returning, retrying up to six
times and failing loudly rather than letting the caller click blind.

## Loading an arbitrary table

`Open > Read Table from comma-separated file...` at (262,189) opens a GTK
file chooser. `ctrl+l` then typing the absolute path is far more reliable
than navigating the tree. This is the route for the `validate/redpath/`
tables.

---

## 6 August 2026 — three entries tabled, one moved

Batch voice analysis, Run Stats Demo and EML Stats Quick Start were removed
from the submenu by author ruling (see setup.praat for what was removed and
how to restore it). The submenu is now thirteen entries ending at Create
Demo Table.

**Create Demo Table moved up into Batch's old slot**, from 799 to 773 in base
coordinates. That is the trap this file exists to prevent: a stale constant
does not fail, it clicks whatever moved into its place. `EML_BATCH`,
`EML_STATSDEMO` and `EML_QUICKSTART` are kept in gui.sh as comments beside
the entries they addressed, so restoring a menu entry and restoring its
coordinate are visibly the same job.

Measured positions in this session's layout (`EML_YOFF = -20`):

| Entry | y |
|---|---:|
| Stats Wizard | 447 |
| Describe Table column | 473 |
| Check normality | 498 |
| Compare two groups | 524 |
| Compare paired/repeated | 549 |
| Compare k groups (ANOVA) | 574 |
| Compare k groups (Kruskal-Wallis) | 599 |
| Compare two-way (ANOVA) | 624 |
| Correlate two columns | 650 |
| Linear regression | 675 |
| Pairwise comparisons | 701 |
| EML Graphs | 727 |
| Create Demo Table | 753 |

Verified against `evidence/shots/menu_after_tabling_2026-08-06.png`, which is
the submenu open. Recalibrate the same way: open it, screenshot, read the
positions off the image. Never infer them from a diff of setup.praat — the
separators are menu entries too and they do not all take the same height.
