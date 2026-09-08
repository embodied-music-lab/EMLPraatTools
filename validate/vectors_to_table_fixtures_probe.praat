# ============================================================================
# validate/vectors_to_table_fixtures_probe.praat
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# KIT FIXTURE RUNNER for @emlVectorsToTable (plugin_EML_StatsGraphs/graphs/
# eml-graph-procedures.praat). Walks every fixture validate/fixtures/
# vectors_to_table/vectors_to_table_fixtures.praat registers, calls
# @emlVectorsToTable once per fixture, and RECORDS what came back -- it does
# not decide what the right answer is; validate/vectors_to_table_oracle.tsv
# is the committed record of a verified run, and a later run that disagrees
# with it is the thing to investigate. Same division of labour as
# validate/group_extraction_probe.praat over validate/fixtures/
# group_extraction/, which this file's shape is copied from.
#
# THIS FILE ISSUES NO `include`s of its own -- it assumes the caller has
# already included:
#   1. plugin_EML_StatsGraphs/graphs/eml-graph-procedures.praat
#      (@emlVectorsToTable and @emlToTable live there)
#   2. validate/fixtures/vectors_to_table/vectors_to_table_fixtures.praat
# before including this file. Run via the committed wrapper:
#
#   /usr/local/bin/praat6630 --run validate/tools/run_vectors_to_table_probe.praat
#
# OUTPUT FORMAT. One TSV, long form, one row per (fixture, field):
#
#     fixture  field  value
#
# `field` is one of:
#   ok            emlVectorsToTable.ok (0 or 1)
#   expectRefuse  the fixture's own declared expectation (0 or 1) -- a row
#                 where `ok` and `1 - expectRefuse` disagree is the probe
#                 catching its own fixture wrong, not just the procedure
#   tableId_gt0   1 if .tableId > 0 (an object was actually built), else 0 --
#                 the object id itself is never recorded: it is
#                 session-dependent and not a fact about the procedure
#   nRows         .nRows
#   nCols         .nCols
#   lengths       .lengths#, joined by ";", each an integer (every fixture
#                 vector here is a short literal, so this is exact)
#   warning       .warning$ ("" when nothing was padded)
#   error         .error$ ("" on success)
#   cell_<label>  present only when .tableId > 0: one row per (row,column)
#                 cell actually written, keyed "cell_<column label>_<row>",
#                 valued exactly as `Get value:` reads it back (a padded
#                 numeric cell therefore reads "--undefined--", a padded
#                 text cell reads "") -- the same left-to-right,
#                 top-to-bottom order @emlVectorsToTable itself fills in.
# ============================================================================

procedure vttp_tsvHeader: .path$
    deleteFile: .path$
    appendFileLine: .path$, "fixture", tab$, "field", tab$, "value"
endproc

procedure vttp_writeField: .path$, .fixture$, .field$, .value$
    appendFileLine: .path$, .fixture$, tab$, .field$, tab$, .value$
endproc

procedure vttp_lengthsText: .lengths#
    .n = size (.lengths#)
    .text$ = ""
    for .k from 1 to .n
        if .k > 1
            .text$ = .text$ + ";"
        endif
        .text$ = .text$ + string$ (.lengths# [.k])
    endfor
endproc

procedure vttp_runProbe: .outTsv$
    @vttf_buildFixtures
    @vttp_tsvHeader: .outTsv$

    for .f from 1 to vttf_n
        .fname$ = vttf_name$[.f]

        if .f = 1
            @emlVectorsToTable: vttf_names1$#, vttf_labels1$#
        elsif .f = 2
            @emlVectorsToTable: vttf_names2$#, vttf_labels2$#
        elsif .f = 3
            @emlVectorsToTable: vttf_names3$#, vttf_labels3$#
        elsif .f = 4
            @emlVectorsToTable: vttf_names4$#, vttf_labels4$#
        elsif .f = 5
            @emlVectorsToTable: vttf_names5$#, vttf_labels5$#
        elsif .f = 6
            @emlVectorsToTable: vttf_names6$#, vttf_labels6$#
        endif

        @vttp_writeField: .outTsv$, .fname$, "ok", string$ (emlVectorsToTable.ok)
        @vttp_writeField: .outTsv$, .fname$, "expectRefuse", string$ (vttf_expectRefuse[.f])
        .tableIdGt0 = (emlVectorsToTable.tableId > 0)
        @vttp_writeField: .outTsv$, .fname$, "tableId_gt0", string$ (.tableIdGt0)
        @vttp_writeField: .outTsv$, .fname$, "nRows", string$ (emlVectorsToTable.nRows)
        @vttp_writeField: .outTsv$, .fname$, "nCols", string$ (emlVectorsToTable.nCols)
        @vttp_lengthsText: emlVectorsToTable.lengths#
        @vttp_writeField: .outTsv$, .fname$, "lengths", vttp_lengthsText.text$
        @vttp_writeField: .outTsv$, .fname$, "warning", emlVectorsToTable.warning$
        @vttp_writeField: .outTsv$, .fname$, "error", emlVectorsToTable.error$

        if emlVectorsToTable.tableId > 0
            selectObject: emlVectorsToTable.tableId
            .nr = Get number of rows
            .nc = Get number of columns
            for .c to .nc
                .colLabel$ = Get column label: .c
                for .r to .nr
                    .cellVal$ = Get value: .r, .colLabel$
                    @vttp_writeField: .outTsv$, .fname$,
                        ... "cell_" + .colLabel$ + "_" + string$ (.r), .cellVal$
                endfor
            endfor
            removeObject: emlVectorsToTable.tableId
        endif
    endfor
endproc


# `include` is a literal, top-level, parse-time directive in Praat -- not
# subject to the interpreter's own variable interpolation and not legal
# inside an `if` (confirmed against 6.6.30: a conditional `include` fails
# with "Unknown variable: include" before the condition is ever evaluated).
# So this file, like group_extraction_probe.praat before it, issues no
# `include` of its own: validate/tools/run_vectors_to_table_probe.praat is
# the tiny top-level wrapper that includes the module under test, this
# file's fixture builder, and this file itself, in that order, then calls
# @vttp_runProbe -- the same three-file wrapper shape validate/tools/
# group_extraction_runner.R builds for the group-extraction probe, kept here
# as a committed .praat file rather than R-generated text because no R-side
# equivalence check reads this probe's output.
