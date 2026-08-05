# Verified render map — `Objects → New → ⁺EML Tools`

Date: 4 August 2026. Praat 6.6.30, Xvfb :99 1400x1000, matchbox WM.
Source: screenshot `/home/claude/drive/out/menu_emltools3.png`.

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

- Maximized 1400x1000 at 0,0.
- Menu bar: `Praat  New  Open  Save(greyed)  Help`. `New` is at (72,14).
- Bottom-left buttons `Rename… / Copy… / Inspect / Info / Remove` all greyed.
- Plugin-added items render with a superscript "+" prefix: `⁺EML Tools`,
  `⁺Stats Wizard...` etc.

## Opening the submenu

`⁺EML Tools` is the LAST item in the `New` menu, at y=447.
Hover does not open it; click only highlights. Press `Right`.
The submenu spans x≈373–677; click at x≈500.

## Entry coordinates (click x≈500)

| y | Entry | Script |
|---|---|---|
| 447 | ⁺Stats Wizard... | eml-wizard.praat |
| | ─── separator ─── | |
| 473 | ⁺Describe Table column... | eml-describe-table.praat |
| 498 | ⁺Check normality (all columns)... | eml-check-normality.praat |
| | ─── separator ─── | |
| 524 | ⁺Compare two groups... | eml-compare-groups.praat |
| 549 | ⁺Compare paired/repeated... | eml-compare-paired.praat |
| 574 | ⁺Compare k groups (ANOVA)... | eml-compare-k-groups.praat |
| 599 | ⁺Compare k groups (Kruskal-Wallis)... | eml-compare-kw.praat |
| 624 | ⁺Compare two-way (ANOVA)... | eml-compare-twoway.praat |
| | ─── separator ─── | |
| 650 | ⁺Correlate two columns... | eml-correlate.praat |
| 675 | ⁺Linear regression... | eml-regress.praat |
| | ─── separator ─── | |
| 701 | ⁺Linear mixed model... | eml-lmm.praat — **TABLED, SKIP** |
| | ─── separator ─── | |
| 727 | ⁺Pairwise comparisons... | eml-pairwise.praat |
| | ─── separator ─── | |
| 753 | ⁺EML Graphs... | eml-graphs.praat |
| | ─── separator ─── | |
| 779 | ⁺Batch voice analysis... | eml-batch-process.praat |
| | ─── separator ─── | |
| 805 | ⁺Create Demo Table... | eml-create-demo.praat |
| 830 | ⁺Run Stats Demo | eml-stats-demo.praat |
| | ─── separator ─── | |
| 856 | ⁺EML Stats Quick Start | eml-quick-start.praat |

17 runnable entries. `Run Stats Demo` and `EML Stats Quick Start` carry no
trailing `...` — no dialog, they run immediately.

"EML Interactive Tutorial" is correctly ABSENT (unregistered at setup.praat
v1.4 because its include target `tutorial/eml-demo-procedures.praat` is not
shipped).

---

## Table object action buttons (mapped 5 Aug 2026)

With exactly one Table selected, the right-hand action column renders at
**x ≈ 1277**, nine buttons spanning **y 404–684** (≈35 px pitch). The tabled
`EML: Linear mixed model...` sits in this column at y=579 — **SKIP it**, same
author ruling as menu y=701.

Click x=1277 and derive the y from a live screenshot; do not trust these
absolutes across sessions (see GUI_HARNESS_RECIPE.md §10 — dialog and button
absolutes drift both between and within sessions).

## Remaining surface (not yet mapped)

- Table, 1 selected → 9 action buttons: geometry above, but only
  `EML: Linear mixed model...` identified by label. The other eight still need
  a labelled screenshot; two should be spot-driven.
- TableEditor → Edit menu → `EML: Edit Table...`
- Sound / Pitch / Spectrum / Ltas → `EML Graphs...` (4)
- TableOfReal → 6 buttons (auto-convert path via `@emlWrapperInit`)
- Matrix → 5 buttons (auto-convert path, incl. "row" column-name collision check)
