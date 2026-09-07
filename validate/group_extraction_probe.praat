# ============================================================================
# validate/group_extraction_probe.praat
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# EQUIVALENCE PROBE for @eml_getGroupData (plugin_EML_StatsGraphs/stats/
# eml-extract.praat), captured BEFORE the group-extraction rewrite lands, so
# it fixes the CURRENT (subset-table) implementation as the oracle. Once the
# rewrite (walk the table once, scatter into per-group vectors, no per-group
# subset Table) is in place, this same file -- unchanged -- is run again and
# its output diffed against the committed oracle: agreement is the proof of
# equivalence; any disagreement is the rewrite behaving differently from
# today, whatever the reason.
#
# WHAT IT DOES NOT REIMPLEMENT. Group discovery and order come from the
# plugin's OWN @emlCountGroups (eml-extract.praat) -- not a hand-rolled scan
# of the group column -- so normalised-label comparison ("Male"/"male"/
# "MALE" as one group; "Alpha"/" Alpha"/"Alpha " as one group) is settled by
# the plugin's own @eml_normalizeLabel, exactly as @eml_getGroupData and
# @eml_groupSubset settle it internally. Nothing here re-derives what counts
# as "the same label" or "a strictly numeric cell" -- see
# plugin_EML_StatsGraphs/stats/eml-extract.praat's own @eml_normalizeLabel
# and @eml_strictNumericColumn. This file's only job is to WALK what
# @emlCountGroups discovered, CALL @eml_getGroupData once per group, and
# RECORD what came back.
#
# THIS FILE ISSUES NO `include`s of its own -- it assumes the caller has
# already included:
#   1. plugin_EML_StatsGraphs/stats/eml-extract.praat  (the module under test)
#   2. validate/fixtures/group_extraction/group_extraction_fixtures.praat
# before including this file, so the same three-line wrapper works
# unmodified against the current extractor and, later, its rewrite -- only
# the first include's path ever needs to change. validate/
# v164_group_extraction_equivalence.R and validate/tools/
# group_extraction_runner.R build that wrapper; see either for the exact
# include order.
#
# OUTPUT FORMAT. One TSV, long form, one row per (fixture, group, field):
#
#     fixture  group_index  group_label  field  value
#
# `field` is one of:
#   vector       the extracted values, in order, joined by ";", each printed
#                fixed to 10 decimal places (every fixture value here is a
#                short literal decimal, so this is lossless -- it is not a
#                claim about arbitrary data). Empty string for zero rows.
#   group_order  this group's 1-based position in @emlCountGroups' discovery
#                order for this fixture (encounter order; the plugin's
#                default -- see emlGroupSortAlphabetical, left at its
#                eml-extract.praat default of 0 by not touching it here).
#   skipped      @eml_getGroupData's .nExcluded (rows in the group whose
#                data cell was not strictly numeric: blank, non-numeric
#                text, or the other kinds @eml_strictNumericColumn's fast
#                path rules out).
#   error        @eml_getGroupData's .error$ ("" on success).
#   note         @eml_getGroupData's .note$ -- the remedy text
#                (@emlAuditColumn's sentences), "" when nothing to report.
#
# A fixture whose GROUP COLUMN cannot even be found would make
# @emlCountGroups itself return zero groups with .error$ set; none of the
# eight fixtures here does that (gx07 exercises a missing DATA column
# instead, which @eml_getGroupData itself must report), so that path is not
# separately recorded per-group here.
#
# Usage (from the wrapper the R harness builds):
#   gxf_outTsv$ = "/path/to/output.tsv"
#   include .../eml-extract.praat
#   include .../group_extraction_fixtures.praat
#   include .../group_extraction_probe.praat
#   @gxf_runProbe: gxf_outTsv$
# ============================================================================

procedure gxf_tsvHeader: .path$
    deleteFile: .path$
    appendFileLine: .path$, "fixture", tab$, "group_index", tab$, "group_label", tab$, "field", tab$, "value"
endproc

procedure gxf_writeField: .path$, .fixture$, .idx, .label$, .field$, .value$
    appendFileLine: .path$, .fixture$, tab$, string$ (.idx), tab$, .label$, tab$, .field$, tab$, .value$
endproc

procedure gxf_vectorText: .data#
    .n = size (.data#)
    .text$ = ""
    for .k from 1 to .n
        if .k > 1
            .text$ = .text$ + ";"
        endif
        .text$ = .text$ + fixed$ (.data# [.k], 10)
    endfor
endproc

procedure gxf_runProbe: .outTsv$
    @gxf_buildFixtures
    @gxf_tsvHeader: .outTsv$

    for .f from 1 to gxf_n
        .fname$ = gxf_name$[.f]
        .tid = gxf_tableId[.f]
        .groupCol$ = gxf_groupCol$[.f]
        .queryDataCol$ = gxf_queryDataCol$[.f]

        # Group discovery and order: the plugin's OWN @emlCountGroups, not a
        # reimplementation. Its .groupLabel$[g] is the first-seen RAW
        # spelling for the g-th normalised group, in encounter order -- the
        # same raw spelling @eml_groupSubset's own normalising pass would
        # match against every other spelling of that group.
        selectObject: .tid
        @emlCountGroups: .tid, .groupCol$

        for .g from 1 to emlCountGroups.nGroups
            .label$ = emlCountGroups.groupLabel$[.g]

            @eml_getGroupData: .tid, .queryDataCol$, .groupCol$, .label$

            @gxf_vectorText: eml_getGroupData.data#
            @gxf_writeField: .outTsv$, .fname$, .g, .label$, "vector", gxf_vectorText.text$
            @gxf_writeField: .outTsv$, .fname$, .g, .label$, "group_order", string$ (.g)
            @gxf_writeField: .outTsv$, .fname$, .g, .label$, "skipped", string$ (eml_getGroupData.nExcluded)
            @gxf_writeField: .outTsv$, .fname$, .g, .label$, "error", eml_getGroupData.error$
            @gxf_writeField: .outTsv$, .fname$, .g, .label$, "note", eml_getGroupData.note$
        endfor
    endfor
endproc
