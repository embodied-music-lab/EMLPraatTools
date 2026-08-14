# ---------------------------------------------------------------------------
# SAVE PATHS -- one leg: build a table, hand it to a SHIPPED wrapper.
#
# This file does NOT transcribe any wrapper. It creates a table of the shape
# the wrapper expects, selects it, and hands control over with runScript:, so
# every dialog after that point -- the entry form, the analysis, the
# post-analysis loop, the Save button, the panel -- is the code a user runs.
#
# WHY runScript: AND NOT include. Two measurements, both on Praat 6.6.30,
# 14 August 2026:
#
#   1. `include` is a textual paste with no guard. A wrapper's first line is
#      `include eml-lib.praat`, so including one from here would land the
#      whole plugin a second time and Praat would refuse at PARSE time with
#      "Duplicate label" -- the defect harness/wrappers exists for.
#   2. runScript: RE-BASES relative includes against the CALLED script's
#      folder. So `include eml-lib.praat` inside the wrapper resolves to
#      plugin/scripts/eml-lib.praat exactly as it does from the menu.
#
# The second point is why this harness is stronger than harness/gui_e2e, which
# lists the barrel's files by hand and must be kept in step with it. Here the
# composition under test IS the shipped barrel, so an include that goes
# missing from eml-lib.praat fails this run.
#
# THE OBJECT SELECTION SURVIVES runScript: -- the object list is global, so
# the Table created here is the Table @emlWrapperInit finds. Also measured.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ---------------------------------------------------------------------------

wrapper$ = environment$ ("EML_WRAPPER")
recipe$ = environment$ ("EML_RECIPE")
if recipe$ = ""
    recipe$ = "twogroup"
endif

writeInfoLine: "LEG begin"
appendInfoLine: "LEG recipe=", recipe$
appendInfoLine: "LEG wrapper=", wrapper$

# THE TABLE SHAPES. Each is the smallest table whose column-role guess the
# wrapper resolves without help, so the entry form comes up already pointed at
# the right columns and Run is the only press the entry page needs. The value
# columns carry "_pct" for the same reason gui_e2e's does: the auto-derived
# label contains a "%", the character that used to vanish from a title.
if recipe$ = "twogroup"
    Create Table with column names: "save_demo", 0, "group jitter_pct"
    for g to 2
        for k to 14
            Append row
            row = Get number of rows
            Set string value: row, "group", "G" + string$ (g)
            Set numeric value: row, "jitter_pct", 0.6 + g * 1.2 + (k mod 5) * 0.15
        endfor
    endfor

elsif recipe$ = "kgroup"
    Create Table with column names: "save_demo", 0, "group jitter_pct"
    for g to 3
        for k to 12
            Append row
            row = Get number of rows
            Set string value: row, "group", "G" + string$ (g)
            Set numeric value: row, "jitter_pct", 0.6 + g * 0.9 + (k mod 5) * 0.17
        endfor
    endfor

elsif recipe$ = "paired"
    # WIDE, not long: the paired wrapper reshapes internally, and D18's other
    # half was about the name that reshape proposed.
    Create Table with column names: "save_demo", 0, "before_pct after_pct"
    for k to 18
        Append row
        row = Get number of rows
        Set numeric value: row, "before_pct", 2.0 + (k mod 6) * 0.2
        Set numeric value: row, "after_pct", 2.9 + (k mod 5) * 0.22
    endfor

elsif recipe$ = "twoway"
    Create Table with column names: "save_demo", 0, "sex register jitter_pct"
    for a to 2
        for b to 2
            for k to 7
                Append row
                row = Get number of rows
                Set string value: row, "sex", "S" + string$ (a)
                Set string value: row, "register", "R" + string$ (b)
                Set numeric value: row, "jitter_pct",
                ... 1.0 + a * 0.7 + b * 0.4 + (k mod 4) * 0.18
            endfor
        endfor
    endfor

else
    # xy -- two numeric columns with a real relationship, so a correlation and
    # a regression both have something to report rather than refusing.
    Create Table with column names: "save_demo", 0, "f0_hz jitter_pct"
    for k to 26
        Append row
        row = Get number of rows
        Set numeric value: row, "f0_hz", 110 + k * 3.5
        Set numeric value: row, "jitter_pct", 0.8 + k * 0.06 + (k mod 4) * 0.09
    endfor
endif

tableId = selected ("Table")
appendInfoLine: "LEG tableId=", tableId
appendInfoLine: "LEG rows=", do ("Get number of rows")

selectObject: tableId
runScript: wrapper$

appendInfoLine: "LEG end"
