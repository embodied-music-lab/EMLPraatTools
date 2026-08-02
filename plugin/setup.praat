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
# Code generation: Claude (Anthropic)
#
# License: Creative Commons Share-Alike
# Version: 1.3
# v1.3: Added TableOfReal and Matrix action buttons for stats tools
#       (Describe, Compare, Correlate, Regression, Wizard).
# Date: 11 April 2026
# ============================================================================

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

# Mixed models
Add menu command: "Objects", "New", "-- eml mixed --", "Linear regression...", 1, ""
Add menu command: "Objects", "New", "Linear mixed model...", "-- eml mixed --", 1, "scripts/eml-lmm.praat"

# Post-Hoc
Add menu command: "Objects", "New", "-- eml posthoc --", "Linear mixed model...", 1, ""
Add menu command: "Objects", "New", "Pairwise comparisons...", "-- eml posthoc --", 1, "scripts/eml-pairwise.praat"

# Graphs
Add menu command: "Objects", "New", "-- eml graphs --", "Pairwise comparisons...", 1, ""
Add menu command: "Objects", "New", "EML Graphs...", "-- eml graphs --", 1, "scripts/eml-graphs.praat"

# Batch
Add menu command: "Objects", "New", "-- eml batch --", "EML Graphs...", 1, ""
Add menu command: "Objects", "New", "Batch voice analysis...", "-- eml batch --", 1, "scripts/eml-batch-process.praat"

# Demos
Add menu command: "Objects", "New", "-- eml demos --", "Batch voice analysis...", 1, ""
Add menu command: "Objects", "New", "Create Demo Table...", "-- eml demos --", 1, "scripts/eml-create-demo.praat"
Add menu command: "Objects", "New", "Run Stats Demo", "Create Demo Table...", 1, "scripts/eml-stats-demo.praat"

# Help
Add menu command: "Objects", "New", "-- eml help --", "Run Stats Demo", 1, ""
Add menu command: "Objects", "New", "EML Stats Quick Start", "-- eml help --", 1, "scripts/eml-quick-start.praat"
Add menu command: "Objects", "New", "EML Interactive Tutorial", "EML Stats Quick Start", 1, "scripts/eml-tutorial.praat"

# ── Dynamic action buttons: appear when 1 Table is selected ────────────────

Add action command: "Table", 1, "", 0, "", 0, "EML: Describe column...", "", 0, "scripts/eml-describe-table.praat"
Add action command: "Table", 1, "", 0, "", 0, "EML: Check normality...", "", 0, "scripts/eml-check-normality.praat"
Add action command: "Table", 1, "", 0, "", 0, "EML: Compare groups...", "", 0, "scripts/eml-compare-groups.praat"
Add action command: "Table", 1, "", 0, "", 0, "EML: Correlate columns...", "", 0, "scripts/eml-correlate.praat"
Add action command: "Table", 1, "", 0, "", 0, "EML: Linear regression...", "", 0, "scripts/eml-regress.praat"
Add action command: "Table", 1, "", 0, "", 0, "EML: Linear mixed model...", "", 0, "scripts/eml-lmm.praat"
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
