# ============================================================================
# EML Praat Tools — Plugin Setup
# ============================================================================
# Purpose: Register menu entries and dynamic action buttons for the
#          EML Praat Tools plugin. This file is executed automatically
#          by Praat on startup when the plugin_EML_Praat_Tools folder is placed
#          in the Praat preferences directory.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
#            https://github.com/embodied-music-lab/PraatGen
# Code generation: Claude (Anthropic)
#
# License: GPL-3.0-or-later
# Version: 1.4
# v1.4: Item 4 — unregistered the "EML Interactive Tutorial" menu entry.
#       scripts/eml-tutorial.praat includes tutorial/eml-demo-procedures.praat,
#       a directory that does not exist in the plugin, so the menu item was
#       live but dead. No tutorial content invented.
# v1.3: Added TableOfReal and Matrix action buttons for stats tools
#       (Describe, Compare, Correlate, Regression, Wizard).
# Date: 2 August 2026
# ============================================================================

# ── Minimum Praat version ──────────────────────────────────────────────────
#
# The plugin targets Praat 6.6.30 and later. That is not an arbitrary line:
# 6.6.30 is the version every capture under evidence/info/ was produced on, so
# the supported floor and the validation evidence are the same build. Praat
# 7.0 is also tested (macOS).
#
# Below the floor the plugin does not degrade gracefully, it fails at a
# random point mid-analysis on whichever newer built-in it reaches first, with
# an error naming a function rather than a version. Refusing at load time and
# saying so is the whole point of this block.

emlMinPraatVersion = 6630

if praatVersion < emlMinPraatVersion
    writeInfoLine: "EML Praat Tools requires Praat 6.6.30 or later."
    appendInfoLine: "This is Praat ", praatVersion$, "."
    appendInfoLine: ""
    appendInfoLine: "The plugin has NOT been loaded. Update Praat from praat.org"
    appendInfoLine: "and restart; no menu items were registered."
    exitScript ()
endif

# ── Fixed menu: Objects → New → EML Tools cascade ──────────────────────────

# Cascade header (no script = submenu title)
Add menu command: "Objects", "New", "EML Tools", "", 0, ""
Add menu command: "Objects", "New", "Stats Wizard...", "EML Tools", 1, "scripts/eml-wizard.praat"

# Describe
Add menu command: "Objects", "New", "-- eml describe --", "EML Tools", 1, ""
Add menu command: "Objects", "New", "Describe Table column...", "-- eml describe --", 1, "scripts/eml-describe-table.praat"
Add menu command: "Objects", "New", "Check normality (all columns)...", "Describe Table column...", 1, "scripts/eml-check-normality.praat"

# Compare
Add menu command: "Objects", "New", "-- eml compare --", "Check normality (all columns)...", 1, ""
Add menu command: "Objects", "New", "Compare two groups...", "-- eml compare --", 1, "scripts/eml-compare-groups.praat"
Add menu command: "Objects", "New", "Compare paired/repeated...", "Compare two groups...", 1, "scripts/eml-compare-paired.praat"
Add menu command: "Objects", "New", "Compare k groups (ANOVA)...", "Compare paired/repeated...", 1, "scripts/eml-compare-k-groups.praat"
Add menu command: "Objects", "New", "Compare k groups (Kruskal-Wallis)...", "Compare k groups (ANOVA)...", 1, "scripts/eml-compare-kw.praat"
Add menu command: "Objects", "New", "Compare two-way (ANOVA)...", "Compare k groups (Kruskal-Wallis)...", 1, "scripts/eml-compare-twoway.praat"

# Correlate
Add menu command: "Objects", "New", "-- eml correlate --", "Compare two-way (ANOVA)...", 1, ""
Add menu command: "Objects", "New", "Correlate two columns...", "-- eml correlate --", 1, "scripts/eml-correlate.praat"
Add menu command: "Objects", "New", "Linear regression...", "Correlate two columns...", 1, "scripts/eml-regress.praat"

# Mixed models — TABLED, 5 August 2026, by author ruling.
#
# The "Linear mixed model..." menu entry and its "-- eml mixed --" separator
# are removed, and the Post-Hoc separator below is rechained to follow
# "Linear regression..." so the submenu has no gap. scripts/eml-lmm.praat and
# stats/eml-lmm.praat are LEFT IN PLACE and untouched — this hides the entry
# point, it does not delete the module. Restoring it means restoring these
# two lines and rechaining "-- eml posthoc --" back to it.
#
# The module has no test of any kind: 31 procedures in eml-lmm.praat plus the
# 10 in eml-linalg.praat and 8 in eml-optimizer.praat that only it calls, none
# under any oracle (audit/reports/CORRECTION_coverage_2026-08-04.md). Leaving
# a reachable menu entry on an untested mixed-model implementation is the
# thing being removed.

# Post-Hoc
Add menu command: "Objects", "New", "-- eml posthoc --", "Linear regression...", 1, ""
Add menu command: "Objects", "New", "Pairwise comparisons...", "-- eml posthoc --", 1, "scripts/eml-pairwise.praat"

# Graphs
Add menu command: "Objects", "New", "-- eml graphs --", "Pairwise comparisons...", 1, ""
Add menu command: "Objects", "New", "EML Graphs...", "-- eml graphs --", 1, "scripts/eml-graphs.praat"

# Data
# Placed after the analyses rather than before them because it is most often
# reached AFTER a result looks wrong -- "why is n only 38?" -- even though the
# best time to run it is before. It works with or without a Table selected:
# without one it offers file mode, which is the only way to catch a problem
# Praat's CSV reader destroys on the way in.
Add menu command: "Objects", "New", "-- eml data --", "EML Graphs...", 1, ""
Add menu command: "Objects", "New", "Check & repair data...", "-- eml data --", 1, "scripts/eml-check-data.praat"

# ── TABLED, 6 August 2026, by author ruling ───────────────────────────────
#
# Batch voice analysis, EML Stats Quick Start and the interactive tutorial
# are disconnected from end users for now. Same treatment as linear mixed
# models on 5 August: NOTHING IS DELETED. scripts/eml-batch-process.praat,
# scripts/eml-quick-start.praat and scripts/eml-tutorial.praat are all
# intact and untouched; only their menu registrations are removed.
#
# Why each:
#
#   Batch voice analysis   Never driven, and it is the one part of the
#                          plugin that calls Praat's OWN acoustic extraction
#                          — pitch, formants, intensity, harmonicity —
#                          rather than doing its own arithmetic. That is a
#                          separate correctness surface from the statistics
#                          and has no validation of any kind. To be covered.
#
#   EML Stats Quick Start  Never driven; content not reviewed.
#
#   Interactive tutorial   Was already unregistered at v1.4 because
#                          tutorial/eml-demo-procedures.praat is not shipped,
#                          so the entry was live and the script could never
#                          run. That include is still neutralised and
#                          harness/check_includes.py still reports its 23
#                          unresolved calls as a KNOWN state.
#
# Run Stats Demo is ALSO removed: the author has said it needs a complete
# redo, and a demo that misrepresents the tools is worse than no demo.
# Create Demo Table stays — it builds the tables the rest of the plugin is
# exercised with, and it is the most-driven wrapper in the audit.
#
# TO RESTORE any of these: uncomment its line below and re-chain the
# separator above it. The chain is positional — each entry names the one
# before it — so restoring out of order silently reorders the menu.
#
# Add menu command: "Objects", "New", "-- eml batch --", "EML Graphs...", 1, ""
# Add menu command: "Objects", "New", "Batch voice analysis...", "-- eml batch --", 1, "scripts/eml-batch-process.praat"
# Add menu command: "Objects", "New", "Run Stats Demo", "Create Demo Table...", 1, "scripts/eml-stats-demo.praat"
# Add menu command: "Objects", "New", "-- eml help --", "Run Stats Demo", 1, ""
# Add menu command: "Objects", "New", "EML Stats Quick Start", "-- eml help --", 1, "scripts/eml-quick-start.praat"

# Demos — Create Demo Table only. It now chains directly to EML Graphs,
# where the batch separator and entry used to sit.
Add menu command: "Objects", "New", "-- eml demos --", "EML Graphs...", 1, ""
Add menu command: "Objects", "New", "Create Demo Table...", "-- eml demos --", 1, "scripts/eml-create-demo.praat"

# ── Dynamic action buttons: appear when 1 Table is selected ────────────────

Add action command: "Table", 1, "", 0, "", 0, "EML: Describe column...", "", 0, "scripts/eml-describe-table.praat"
Add action command: "Table", 1, "", 0, "", 0, "EML: Check normality...", "", 0, "scripts/eml-check-normality.praat"
Add action command: "Table", 1, "", 0, "", 0, "EML: Compare groups...", "", 0, "scripts/eml-compare-groups.praat"
Add action command: "Table", 1, "", 0, "", 0, "EML: Correlate columns...", "", 0, "scripts/eml-correlate.praat"
Add action command: "Table", 1, "", 0, "", 0, "EML: Linear regression...", "", 0, "scripts/eml-regress.praat"
# TABLED with the menu entry above: the Objects-window button for LMM.
Add action command: "Table", 1, "", 0, "", 0, "EML Graphs...", "", 0, "scripts/eml-graphs.praat"
Add action command: "Table", 1, "", 0, "", 0, "EML: Edit Table...", "", 0, "scripts/eml-edit-table-launch.praat"
Add action command: "Table", 1, "", 0, "", 0, "EML: Stats Wizard...", "", 0, "scripts/eml-wizard.praat"

# ── Editor menu: appears in TableEditor Edit menu ─────────────────────────

Add menu command: "TableEditor", "Edit", "EML: Edit Table...", "", 0, "scripts/eml-edit-table-editor.praat"

# ── Dynamic action buttons: appear when 1 object of these types is selected ─

Add action command: "Sound", 1, "", 0, "", 0, "EML Graphs...", "", 0, "scripts/eml-graphs.praat"
Add action command: "Pitch", 1, "", 0, "", 0, "EML Graphs...", "", 0, "scripts/eml-graphs.praat"
Add action command: "Spectrum", 1, "", 0, "", 0, "EML Graphs...", "", 0, "scripts/eml-graphs.praat"
Add action command: "Ltas", 1, "", 0, "", 0, "EML Graphs...", "", 0, "scripts/eml-graphs.praat"

# ── Dynamic action buttons: TableOfReal and Matrix (auto-convert to Table) ──

Add action command: "TableOfReal", 1, "", 0, "", 0, "EML: Describe column...", "", 0, "scripts/eml-describe-table.praat"
Add action command: "TableOfReal", 1, "", 0, "", 0, "EML: Compare groups...", "", 0, "scripts/eml-compare-groups.praat"
Add action command: "TableOfReal", 1, "", 0, "", 0, "EML: Correlate columns...", "", 0, "scripts/eml-correlate.praat"
Add action command: "TableOfReal", 1, "", 0, "", 0, "EML: Linear regression...", "", 0, "scripts/eml-regress.praat"
Add action command: "TableOfReal", 1, "", 0, "", 0, "EML Graphs...", "", 0, "scripts/eml-graphs.praat"
Add action command: "TableOfReal", 1, "", 0, "", 0, "EML: Stats Wizard...", "", 0, "scripts/eml-wizard.praat"

Add action command: "Matrix", 1, "", 0, "", 0, "EML: Describe column...", "", 0, "scripts/eml-describe-table.praat"
Add action command: "Matrix", 1, "", 0, "", 0, "EML: Compare groups...", "", 0, "scripts/eml-compare-groups.praat"
Add action command: "Matrix", 1, "", 0, "", 0, "EML: Correlate columns...", "", 0, "scripts/eml-correlate.praat"
Add action command: "Matrix", 1, "", 0, "", 0, "EML: Linear regression...", "", 0, "scripts/eml-regress.praat"
Add action command: "Matrix", 1, "", 0, "", 0, "EML Graphs...", "", 0, "scripts/eml-graphs.praat"
