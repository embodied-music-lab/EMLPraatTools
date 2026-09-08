# ============================================================================
# validate/fixtures/vectors_to_table/vectors_to_table_fixtures.praat
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# Fixture set for @emlVectorsToTable / @emlToTable (plugin_EML_StatsGraphs/
# graphs/eml-graph-procedures.praat), driven by validate/
# vectors_to_table_fixtures_probe.praat and graded against validate/
# vectors_to_table_oracle.tsv. Six cases, one per KIT FIXTURE ROW the B11
# wave order names: equal lengths, unequal lengths (padding), a string
# vector, a missing name, a names/labels count mismatch, and an empty names
# vector -- matched in shape to validate/fixtures/group_extraction/
# group_extraction_fixtures.praat, the most recent fixture set of this kind.
#
# PURE PRAAT, NO `include`s. Every fixture is script-level vector literals
# and the two lists @emlVectorsToTable itself takes (.names$#, .labels$#) --
# nothing here depends on the procedure under test, or on any Table object,
# so this file loads identically whether the probe that follows it is
# checking today's implementation or a future one.
#
# THE NAME LISTS CANNOT LIVE IN AN ARRAY (Praat has no vector-of-vectors), so
# each fixture's `.names$#` / `.labels$#` are stored the same way
# @emlVectorsToTable stores ITS OWN materialised columns: as indexed locals,
# `vttf_names'i'$#` / `vttf_labels'i'$#`, spliced by the fixture's own index.
#
# Output (globals, procedure vttf_buildFixtures):
#   vttf_n                  - number of fixtures
#   vttf_name$[i]            - short fixture id (the oracle TSV key)
#   vttf_desc$[i]            - one-line description, for the log
#   vttf_expectRefuse[i]     - 1 if this fixture must come back .ok = 0
#   vttf_names'i'$#          - the .names$# to pass @emlVectorsToTable
#   vttf_labels'i'$#         - the .labels$# to pass alongside it
# ============================================================================

procedure vttf_registerFixture: .name$, .desc$, .expectRefuse
    vttf_n = vttf_n + 1
    vttf_name$[vttf_n] = .name$
    vttf_desc$[vttf_n] = .desc$
    vttf_expectRefuse[vttf_n] = .expectRefuse
endproc

procedure vttf_buildFixtures
    vttf_n = 0

    # ---- 1. vtt01_equal_lengths ------------------------------------------
    # Two numeric vectors, same length, default (sigil-stripped) labels.
    # The plain case every other fixture is a departure from.
    vtt01_patient# = { 101, 102, 103 }
    vtt01_age# = { 30, 40, 50 }
    vttf_names1$# = { "vtt01_patient#", "vtt01_age#" }
    vttf_labels1$# = empty$# (0)
    @vttf_registerFixture: "vtt01_equal_lengths",
        ... "two numeric vectors, equal length, default labels", 0

    # ---- 2. vtt02_unequal_lengths ----------------------------------------
    # "short#" is 2 long, "long#" is 4 -- exercises padding, .lengths# and
    # the per-column .warning$ sentence, not a refusal.
    vtt02_short# = { 1, 2 }
    vtt02_long# = { 10, 20, 30, 40 }
    vttf_names2$# = { "vtt02_short#", "vtt02_long#" }
    vttf_labels2$# = empty$# (0)
    @vttf_registerFixture: "vtt02_unequal_lengths",
        ... "two numeric vectors of different length -- the short one is padded", 0

    # ---- 3. vtt03_string_vector -------------------------------------------
    # A `$#` name beside a numeric one, with explicit labels -- exercises
    # the TEXT-column path and the labels$# override in the same fixture.
    vtt03_cond$# = { "control", "treated", "treated" }
    vtt03_score# = { 1.5, 2.5, 3.5 }
    vttf_names3$# = { "vtt03_cond$#", "vtt03_score#" }
    vttf_labels3$# = { "Condition", "Score" }
    @vttf_registerFixture: "vtt03_string_vector",
        ... "a $# name beside a numeric one, with explicit labels", 0

    # ---- 4. vtt04_missing_name ---------------------------------------------
    # The second name is not a script-level vector at all. Must refuse,
    # naming the missing vector, and build nothing (.tableId = 0).
    vtt04_patient# = { 1, 2, 3 }
    vttf_names4$# = { "vtt04_patient#", "vtt04_nonexistent#" }
    vttf_labels4$# = empty$# (0)
    @vttf_registerFixture: "vtt04_missing_name",
        ... "the second name is not a script-level vector", 1

    # ---- 5. vtt05_count_mismatch --------------------------------------------
    # Two names, one label. Must refuse before any name is even checked for
    # existence -- the count mismatch is reported first.
    vtt05_patient# = { 1, 2, 3 }
    vtt05_age# = { 30, 40, 50 }
    vttf_names5$# = { "vtt05_patient#", "vtt05_age#" }
    vttf_labels5$# = { "OnlyOneLabel" }
    @vttf_registerFixture: "vtt05_count_mismatch",
        ... ".names$# has 2 entries, .labels$# has 1", 1

    # ---- 6. vtt06_empty_names -------------------------------------------------
    # Zero names in, zero columns out -- not a refusal. .tableId stays 0
    # because there is nothing to build.
    vttf_names6$# = empty$# (0)
    vttf_labels6$# = empty$# (0)
    @vttf_registerFixture: "vtt06_empty_names",
        ... "an empty .names$# -- nothing to build, not a refusal", 0

endproc
