# ============================================================================
# EML Praat Tools — Plugin Setup
# ============================================================================
# Purpose: Register menu entries and dynamic action buttons for the
#          EML Praat Tools plugin. This file is executed automatically
#          by Praat on startup when the plugin_EML_Praat_Tools folder is placed
#          in the Praat preferences directory.
#
# License: GPL-3.0-or-later
# Version: 1.7
# Date: 8 August 2026
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
#            https://github.com/embodied-music-lab/PraatGen
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
#
# RESEARCH USE DISCLOSURE
# If this script is used in research or publication, disclose AI use
# per your target journal's policy. Suggested language:
#
#   "Praat analysis scripts were developed using the EML PraatGen
#    Scripting Assistant (Howell, Embodied Music Lab) with code
#    generation by Claude (Anthropic). All scripts were reviewed,
#    tested, and validated by Ian Howell."
#
# The script author assumes responsibility for the correctness and
# appropriate application of this code.
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

# Mixed models — NOT REGISTERED. Tabled for end users.
#
# The "Linear mixed model..." menu entry and its "-- eml mixed --" separator
# are removed, and the Post-Hoc separator below is rechained to follow
# "Linear regression..." so the submenu has no gap. scripts/eml-lmm.praat and
# stats/eml-lmm.praat are LEFT IN PLACE and untouched — this hides the entry
# point, it does not delete the module. Restoring it means restoring these
# two lines and rechaining "-- eml posthoc --" back to it.
#
# The module has no test of any kind: 32 procedures in eml-lmm.praat plus the
# 10 in eml-linalg.praat and 8 in eml-optimizer.praat that only it calls, none
# under any oracle (audit/reports/CORRECTION_coverage_2026-08-04.md). Leaving
# a reachable menu entry on an untested mixed-model implementation is the
# thing being removed.
#
# Re-derive those three counts before citing them; they were 31/10/8 here and
# the first was already stale:
#   grep -c "^procedure " plugin/stats/eml-lmm.praat        -> 32
#   grep -c "^procedure " plugin/stats/eml-linalg.praat     -> 10
#   grep -c "^procedure " plugin/stats/eml-optimizer.praat  ->  8

# Post-Hoc
Add menu command: "Objects", "New", "-- eml posthoc --", "Linear regression...", 1, ""
Add menu command: "Objects", "New", "Pairwise comparisons...", "-- eml posthoc --", 1, "scripts/eml-pairwise.praat"

# Graphs
Add menu command: "Objects", "New", "-- eml graphs --", "Pairwise comparisons...", 1, ""
Add menu command: "Objects", "New", "EML Graphs...", "-- eml graphs --", 1, "scripts/eml-graphs.praat"

# Batch voice analysis.
#
# THE VALIDATION BEHIND THE REGISTRATION. This is the one part of the plugin
# that calls Praat's OWN acoustic extraction rather than doing its own
# arithmetic, so the entry rests on 255 checks:
# validate/v52_acoustic_calls.R (nine call sites, canonical parameter sets,
# algorithm-to-purpose routing, live argument order at 6.6.30),
# validate/v53_batch_flow.R (seven driven corpora — the file loop, the failure
# rows, the TextGrid constraint, the STOP sentinel, the output folder, the
# plausibility warnings) and validate/v54_batch_praatgen.R (command signatures
# against the PraatGen corpus), plus validate/v72_batch_registration.R for this
# registration and for the dialog behind it.
#
# AND THE DOOR HAS BEEN OPENED. Everything above is headless or twin-driven:
# harness/batch derives a dialogless twin from the shipped bytes and hash-
# verifies the remainder, which is strong evidence about the LOOP and says
# nothing whatever about the FORM. So harness/batchgui presses this entry
# through the real menu, under Xvfb, and drives the real Batch Voice Analysis
# dialog to a written CSV. That is the difference between registering a door
# and registering a door somebody has walked through.
#
# THE POSITION: after "EML Graphs...", before the data group. It is written
# HERE, in source order — see the note under the demos block for why source
# order is what decides this and the after$ argument is not.
#
# NO ACTION BUTTON, ON ANY OBJECT TYPE, and that is a decision rather than an
# omission. Every other EML entry point is registered on the class it consumes
# — Table, TableOfReal, Matrix, Sound, Pitch, Spectrum, Ltas — because it acts
# on the selection. This one does not read the selection at all: it takes a
# FOLDER of .wav files off disk, and it ignores whatever is in the Objects
# window. PraatGen's BEST_PRACTICES_PLUGIN_ARCHITECTURE §4 shows the legal
# shape for exactly this idea, `Add action command: "Sound", 0, …` for a
# "Batch process..." button, and a button on Sound here would honour that shape
# while telling the user a lie: it would appear because they had selected a
# Sound and would then ignore it. A button that appears for the wrong reason
# misleads a user exactly as much as a button that does nothing.
Add menu command: "Objects", "New", "-- eml batch --", "EML Graphs...", 1, ""
Add menu command: "Objects", "New", "Batch voice analysis...", "-- eml batch --", 1, "scripts/eml-batch-process.praat"

# Data
# Placed after the analyses rather than before them because it is most often
# reached AFTER a result looks wrong -- "why is n only 38?" -- even though the
# best time to run it is before. It works with or without a Table selected:
# without one it offers file mode, which is the only way to catch a problem
# Praat's CSV reader destroys on the way in.
Add menu command: "Objects", "New", "-- eml data --", "EML Graphs...", 1, ""
Add menu command: "Objects", "New", "Check & repair data...", "-- eml data --", 1, "scripts/eml-check-data.praat"

# ── RECORD A WORKFLOW AS A SCRIPT ─────────────────────────────────────────
#
# TWO COMMANDS, AND NO CHECKBOX ANYWHERE. The obvious alternative was a
# "record this" boolean on every analysis dialog, and it is wrong twice
# over. It models the wrong scope: the recorder accumulates a SEQUENCE --
# begin, N steps across different operations, one file -- so a per-analysis
# boolean cannot express "record these four analyses and this figure into
# one script", which is the whole point. And it would cost a row on twenty
# dialogs, several of which are already the tallest the plugin draws, with
# no scrollbar under them.
#
# These two cost two lines here and nothing on any dialog. Recording is
# discovered by @emlRecordInit, which every entry point already runs.
Add menu command: "Objects", "New", "-- eml record --", "Check & repair data...", 1, ""
# THREE COMMANDS, EACH NAMED FOR WHAT IT DOES.
# 'Stop recording and open' writes a review copy into a folder the plugin owns
# and raises it in a ScriptEditor; 'Stop recording and save' asks where to put
# it. Both end the session, which is why neither carries a tickbox asking.
Add menu command: "Objects", "New", "Record script", "-- eml record --", 1, "scripts/eml-record-start.praat"
Add menu command: "Objects", "New", "Stop recording and open", "Record script", 1, "scripts/eml-record-open.praat"
Add menu command: "Objects", "New", "Stop recording and save...", "Record script", 1, "scripts/eml-record-save.praat"

# ── TABLED — not registered ───────────────────────────────────────────────
#
# EML Stats Quick Start and the interactive tutorial are disconnected from end
# users for now. Same treatment as linear mixed models: NOTHING IS DELETED. scripts/eml-quick-start.praat and scripts/eml-tutorial.praat are
# both intact and untouched; only their menu registrations are removed.
#
# Batch voice analysis is NOT on this list: it is registered above, under its
# own note, with the validation that entry rests on.
#
# Why each of these:
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
# exercised with, and it is the most-driven wrapper in the tree.
#
# TO RESTORE any of these: uncomment its line below and PUT THE LINE WHERE THE
# ENTRY IS TO APPEAR.
#
# WHAT DECIDES THE ORDER, MEASURED RATHER THAN REASONED. It is the SOURCE
# ORDER of the lines in this file, not the after$ anchor: on Praat 6.6.30 an
# anchor resolves the first time it is used and is inert afterwards. Both
# "-- eml data --" and "-- eml demos --" name "EML Graphs...", and if the
# anchor decided, the demos group would render between EML Graphs and Check &
# repair data. It does not — photographed under Xvfb
# (harness/batchgui/out/menu_before.png), Create Demo Table renders LAST, at
# the foot of the submenu, which is where its line sits in this file.
#
# THAT MATTERS FOR RESTORING AN ENTRY: bringing a commented line back to life
# WHERE IT SITS IN THIS BLOCK would put it at the end of the submenu whatever
# its after$ says. Write it where the entry is to appear — the batch entry's
# two lines sit up beside "EML Graphs...", the position its after$ names, and
# the result is photographed (harness/batchgui/out/menu_after.png) rather than
# assumed.
#
# AND THE SEPARATOR TEXT IS NEVER SEEN BY A USER. "-- eml batch --" reads like
# a heading in this file and renders as a plain horizontal rule with no text at
# all — same photographs, every one of the nine. The label is a comment to the
# next reader of this file; what a voice researcher actually sees is the
# GROUPING the rule makes. Naming one of them better is a change to this file's
# legibility and to nothing on screen.
#
# Add menu command: "Objects", "New", "Run Stats Demo", "Create Demo Table...", 1, "scripts/eml-stats-demo.praat"
# Add menu command: "Objects", "New", "-- eml help --", "Run Stats Demo", 1, ""
# Add menu command: "Objects", "New", "EML Stats Quick Start", "-- eml help --", 1, "scripts/eml-quick-start.praat"

# Demos — Create Demo Table only. Its after$ names "EML Graphs...", which is
# also where the batch separator sits, and this group does not render there
# regardless: it renders last, where these two lines sit. See the measured
# note above.
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
#
# ELEVEN REGISTRATIONS — six on TableOfReal, five on Matrix. A registration is
# a PROMISE: the button is there, so the dialog opens. Eight of these eleven
# depend on a coercion that has to be finished before the dialog appears, and
# finishing it is the answer rather than taking the buttons away. Dead doors
# are worse than absent features; they teach users that the plugin crashes.
#
# WHAT EACH ONE DOES WITH THE OBJECT IT IS REGISTERED ON, and this is the
# whole reason the failure was uneven — there is no single coercion, there
# are four:
#
#   scripts/eml-describe-table.praat  its own @emlDescribeCoerceSelection,
#                                     then @emlWrapperInit. Defaults empty
#                                     row labels to r1..rn
#                                     and names the converted Table
#                                     eml_converted_<source> before anything
#                                     that can raise runs.
#   scripts/eml-compare-groups.praat  @emlWrapperInit, stats/eml-output.praat
#   scripts/eml-correlate.praat       :1405-1439. Converts, but leaves the
#   scripts/eml-regress.praat         row-label column full of Praat's "?"
#                                     placeholders, which the numeric probe
#                                     in stats/eml-extract.praat:878 does not
#                                     recognise as empty — so an UNLABELLED
#                                     TableOfReal and every Matrix die
#                                     natively before the dialog opens. A
#                                     LABELLED TableOfReal has always worked,
#                                     which is the qualifier that hid this.
#   scripts/eml-graphs.praat          @emlConvertForGraph, which already calls
#                                     @emlCleanConvertedTable — the reason
#                                     these two never crashed.
#   scripts/eml-wizard.praat          its own To Table: "Group" at :145, and
#                                     it runs no numeric probe at entry.
#
# Four coercions for one conversion is the finding under the finding. Nothing
# is re-chained here to paper over it: the enumeration that holds these
# eleven honest is validate/v59_entry_points.R, which drives every one of
# them against a real object of every type it is registered on — including a
# TableOfReal both with and without row labels — and fails on any that does
# not reach its dialog.

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
