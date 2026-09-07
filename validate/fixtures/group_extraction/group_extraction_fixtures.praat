# ============================================================================
# validate/fixtures/group_extraction/group_extraction_fixtures.praat
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# Fixture set for the group-extraction equivalence probe
# (validate/group_extraction_probe.praat, driven by validate/
# v164_group_extraction_equivalence.R). Eight small Tables, one per
# adversarial case @eml_getGroupData's coming rewrite (walk the table once,
# scatter into per-group vectors, no per-group subset Table) must reproduce
# EXACTLY as the current implementation (build a subset Table via
# @eml_groupSubset, then extract).
#
# PURE PRAAT, NO `include`s. This file only issues bare Table object
# commands (Create Table / Append row / Set string value), so it carries no
# dependency on eml-extract.praat or any other plugin file and loads
# identically regardless of which extractor the wrapper script includes
# alongside it -- the same fixtures serve as the oracle-capture run against
# the CURRENT extractor today and, unchanged, the rewrite's own equivalence
# run once it lands.
#
# Every "value" cell is written with `Set string value:`, even where it
# looks like a plain number, deliberately -- the blank and non-numeric cases
# need string cells anyway, and using the same command everywhere means
# every fixture is built by the same code path rather than two.
#
# Output (globals, procedure gxf_buildFixtures):
#   gxf_n                 - number of fixtures
#   gxf_name$[i]           - short fixture id (used as the oracle TSV key)
#   gxf_desc$[i]           - one-line description of the case, for the log
#   gxf_tableId[i]         - the built Table's object id
#   gxf_groupCol$[i]       - the factor column name on that table
#   gxf_queryDataCol$[i]   - the data column name the probe PASSES to
#                            @eml_getGroupData. Equal to the table's real
#                            numeric column ("value") for every fixture
#                            except gx07_missing_column, where it is a name
#                            the table does NOT have -- that substitution IS
#                            the fixture for "a request for a column name
#                            that does not exist".
# ============================================================================

procedure gxf_addRow: .tid, .value$, .group$
    selectObject: .tid
    Append row
    .r = Get number of rows
    Set string value: .r, "value", .value$
    Set string value: .r, "group", .group$
endproc

procedure gxf_registerFixture: .name$, .desc$, .tid, .groupCol$, .queryDataCol$
    gxf_n = gxf_n + 1
    gxf_name$[gxf_n] = .name$
    gxf_desc$[gxf_n] = .desc$
    gxf_tableId[gxf_n] = .tid
    gxf_groupCol$[gxf_n] = .groupCol$
    gxf_queryDataCol$[gxf_n] = .queryDataCol$
endproc

procedure gxf_buildFixtures
    gxf_n = 0

    # ---- 1. gx01_blank_cell -------------------------------------------
    # One row's data cell is empty. Group A has 3 rows, one blank; group B
    # is clean. Proves the blank is dropped (counted in "skipped"), not
    # coerced to 0 and not silently kept.
    .t = Create Table with column names: "gx01", 0, "value group"
    @gxf_addRow: .t, "10.0", "A"
    @gxf_addRow: .t, "",     "A"
    @gxf_addRow: .t, "12.0", "A"
    @gxf_addRow: .t, "5.0",  "B"
    @gxf_addRow: .t, "6.0",  "B"
    @gxf_registerFixture: "gx01_blank_cell",
        ... "one blank data cell in an otherwise clean group",
        ... .t, "group", "value"

    # ---- 2. gx02_nonnumeric_text ---------------------------------------
    # One row's data cell is text that is not a number in any locale.
    .t = Create Table with column names: "gx02", 0, "value group"
    @gxf_addRow: .t, "1.5",  "A"
    @gxf_addRow: .t, "abc",  "A"
    @gxf_addRow: .t, "2.5",  "A"
    @gxf_addRow: .t, "3.0",  "B"
    @gxf_registerFixture: "gx02_nonnumeric_text",
        ... "one data cell holds non-numeric text",
        ... .t, "group", "value"

    # ---- 3. gx03_whitespace_labels --------------------------------------
    # "Alpha", " Alpha" (leading space) and "Alpha " (trailing space) are
    # three spellings of the same group; "Beta" is a genuinely distinct
    # second group, so the fixture cannot pass by accidentally merging
    # everything into one group.
    .t = Create Table with column names: "gx03", 0, "value group"
    @gxf_addRow: .t, "1", "Alpha"
    @gxf_addRow: .t, "2", " Alpha"
    @gxf_addRow: .t, "3", "Alpha "
    @gxf_addRow: .t, "4", "Beta"
    @gxf_addRow: .t, "5", "Beta"
    @gxf_registerFixture: "gx03_whitespace_labels",
        ... "group labels differing only in leading/trailing whitespace",
        ... .t, "group", "value"

    # ---- 4. gx04_case_labels ---------------------------------------------
    # "Male", "male" and "MALE" are three spellings of one group; "Female"
    # is a genuinely distinct second group.
    .t = Create Table with column names: "gx04", 0, "value group"
    @gxf_addRow: .t, "10", "Male"
    @gxf_addRow: .t, "20", "male"
    @gxf_addRow: .t, "30", "MALE"
    @gxf_addRow: .t, "40", "Female"
    @gxf_registerFixture: "gx04_case_labels",
        ... "group labels differing only in letter case",
        ... .t, "group", "value"

    # ---- 5. gx05_singleton_group ------------------------------------------
    # "Solo" has exactly one row; "Many" has three, so the singleton case
    # sits next to an ordinary one in the same table.
    .t = Create Table with column names: "gx05", 0, "value group"
    @gxf_addRow: .t, "100", "Solo"
    @gxf_addRow: .t, "1",   "Many"
    @gxf_addRow: .t, "2",   "Many"
    @gxf_addRow: .t, "3",   "Many"
    @gxf_registerFixture: "gx05_singleton_group",
        ... "a group with exactly one row, beside a normal-sized one",
        ... .t, "group", "value"

    # ---- 6. gx06_single_group_table ---------------------------------------
    # Every row carries the same group label -- nothing to split.
    .t = Create Table with column names: "gx06", 0, "value group"
    @gxf_addRow: .t, "1", "Only"
    @gxf_addRow: .t, "2", "Only"
    @gxf_addRow: .t, "3", "Only"
    @gxf_registerFixture: "gx06_single_group_table",
        ... "a table with exactly one distinct group",
        ... .t, "group", "value"

    # ---- 7. gx07_missing_column --------------------------------------------
    # An ordinary two-group table -- the fixture is not in the table's
    # shape, it is in what the probe below ASKS for: gxf_queryDataCol$ names
    # a column this table does not have ("notacolumn"), so every call
    # against it must return @eml_getGroupData's "Column not found" path.
    .t = Create Table with column names: "gx07", 0, "value group"
    @gxf_addRow: .t, "1", "X"
    @gxf_addRow: .t, "2", "X"
    @gxf_addRow: .t, "3", "Y"
    @gxf_registerFixture: "gx07_missing_column",
        ... "the requested data column does not exist on the table",
        ... .t, "group", "notacolumn"

    # ---- 8. gx08_numeric_looking_labels ------------------------------------
    # Group labels "1", "2", "3" look like numbers but are factor levels,
    # not measurements -- @eml_getGroupData must match them as text.
    .t = Create Table with column names: "gx08", 0, "value group"
    @gxf_addRow: .t, "11", "1"
    @gxf_addRow: .t, "12", "1"
    @gxf_addRow: .t, "21", "2"
    @gxf_addRow: .t, "31", "3"
    @gxf_registerFixture: "gx08_numeric_looking_labels",
        ... "factor labels that look numeric (""1"", ""2"", ""3"")",
        ... .t, "group", "value"

endproc
