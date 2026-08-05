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
| 721 | ⁺Linear mixed model... | eml-lmm.praat — **TABLED, SKIP** |
| | ─── separator ─── | |
| 747 | ⁺Pairwise comparisons... | eml-pairwise.praat |
| | ─── separator ─── | |
| 773 | ⁺EML Graphs... | eml-graphs.praat |
| | ─── separator ─── | |
| 799 | ⁺Batch voice analysis... | eml-batch-process.praat |
| | ─── separator ─── | |
| 825 | ⁺Create Demo Table... | eml-create-demo.praat |
| 850 | ⁺Run Stats Demo | eml-stats-demo.praat — **REDO PENDING, SKIP** |
| | ─── separator ─── | |
| 876 | ⁺EML Stats Quick Start | eml-quick-start.praat |

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
