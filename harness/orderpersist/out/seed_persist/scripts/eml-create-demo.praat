# ============================================================================
# EML Stats & Graphs — Create Demo Tables
# ============================================================================
# Purpose: Generate synthetic voice-science Tables for testing EML Stats & Graphs
#          and tutorials. Creates realistic data with known properties.
#          One demo table per wizard analysis path.
# Date: 21 August 2026
# Version: 3.0
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
#
# WHAT THIS FILE HOLDS: the dialog, the seed, and the record. The seven
# builders live in stats/eml-demo-tables.praat as @emlDemoTable, so that a
# recorded workflow can rebuild the table it was recorded on by calling the
# same procedure this dialog calls. A `beginPause:` script refuses arguments
# — measured, Praat 6.6.30: `runScript: "child.praat", 5` on one answers
# "Found 1 arguments but expected only 0" — so a recorded script cannot
# replay this file, and one procedure called from both places is the only
# arrangement in which the dialog and the replay cannot drift apart.
# ============================================================================
include eml-lib.praat

beginPause: "Create Demo Table"
    comment: "Select the type of demo data to generate."
    comment: "Each table is designed for a specific analysis path."
    comment: ""
    optionmenu: "Demo type", 1
        option: "Two groups (N=40) — t-test / Mann-Whitney"
        option: "Three groups (N=45) — ANOVA / Kruskal-Wallis"
        option: "Paired measures (N=20) — paired t-test / Wilcoxon"
        option: "Correlation (N=30) — Pearson / Spearman"
        option: "Regression (N=25) — simple linear regression"
        option: "Two-way design (N=48) — two-way ANOVA"
        option: "Normality check (N=40) — normal vs skewed"
clicked = endPause: "Quit", "Create", 2, 0
if clicked = 1
    exitScript: ""
endif

# ────────────────────────────────────────────────────────────────────────────
# THE SEED IS MINTED HERE AND APPLIED THERE.
#
# Every builder draws from randomGauss or randomUniform, so two presses of
# Create give two different tables — which is what a user wants and what makes
# a recording of one press unreproducible unless the seed is written down.
#
# So the seed is drawn once, passed in, and handed to the recorder alongside
# the call. A recorded script carries it as a literal and rebuilds the table
# this press produced; a user who wants fresh data presses Create again and
# gets a fresh seed.
#
# IT IS DRAWN FROM PRAAT'S OWN STREAM rather than from the clock, so a test
# rig that seeded the stream before invoking this file gets the same demo
# table every run — the property harness/roundtrip depends on, and the only
# way to have it without this file knowing a rig exists.
# ────────────────────────────────────────────────────────────────────────────
demoSeed = randomInteger (100000, 2147483647)

@emlDemoTable: demo_type, demoSeed

if emlDemoTable.tableId = 0
    writeInfoLine: emlDemoTable.description$
    exitScript: ""
endif

tableId = emlDemoTable.tableId
description$ = emlDemoTable.description$

# ────────────────────────────────────────────────────────────────────────────
# THE RECORD. A table coming into existence is a step like any other, and it
# is the step that lets an emitted script say where its data came from instead
# of instructing the reader to have it open already. Guarded on the recorder
# being loaded for the reason every other hook in the plugin is: a companion
# script that includes only part of the library must not die on a procedure
# that is not there.
#
# THE CODE IT RECORDS IS THE CALL THIS SCRIPT JUST MADE, seed and all, so the
# replay builds the same table rather than a differently-random one.
# ────────────────────────────────────────────────────────────────────────────
if variableExists ("emlRecordLoaded")
    @emlPhrase: "create.seeded", string$ (demoSeed), "", "", "", "", ""
    @emlRecordCreateStep: tableId, emlDemoTable.name$,
        ... emlDemoTable.summary$, emlPhrase.result$,
        ... "@emlDemoTable: " + string$ (demo_type) + ", "
        ... + string$ (demoSeed),
        ... "In the GUI: New > EML Stats & Graphs > Create demo table..., "
        ... + "Demo type option " + string$ (demo_type) + "."
endif

selectObject: tableId
writeInfoLine: "Created demo Table: ", selected$ ("Table")
appendInfoLine: ""
appendInfoLine: description$
appendInfoLine: ""
appendInfoLine: "Seed: ", demoSeed, " — the same seed rebuilds this table."
appendInfoLine: ""
appendInfoLine: "Select the Table and use the EML Stats & Graphs menu or Wizard."
