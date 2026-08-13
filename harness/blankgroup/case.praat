# ---------------------------------------------------------------------------
# BLANK GROUP CELLS — the fixture the tree did not have.
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Four cases, chosen so that the count alone distinguishes right from wrong:
#
#   clean         3 real groups, no blanks           -> 3 groups, 0 blank
#   oneblank      3 real groups + one "" cell        -> 3 groups, 1 blank
#   whitespace    3 real groups + one "   " cell     -> 3 groups, 1 blank
#                 (whitespace normalises to empty, so it must NOT become a
#                 fourth group NOR a separate blank category)
#   twogroupblank 2 real groups + one "" cell        -> 2 groups, 1 blank
#                 This is the case with teeth: @emlRunTwoGroupAnalysis
#                 refuses at k > 2 and routes the user to ANOVA, so before
#                 the fix a single blank cell made the t-test unavailable on
#                 a genuine two-group table.
#
# Output: one CASE line per case, read by run.sh.
# ---------------------------------------------------------------------------
include ../../plugin/stats/eml-core-utilities.praat
include ../../plugin/stats/eml-core-descriptive.praat
include ../../plugin/stats/eml-extract.praat

procedure build: .name$, .nReal, .blank$
    Create Table with column names: .name$, 0, "y g"
    for .i from 1 to 9
        Append row
        .r = Get number of rows
        Set numeric value: .r, "y", 60 + .i
        if .nReal = 3
            Set string value: .r, "g",
            ... if .i mod 3 = 0 then "a" else if .i mod 3 = 1 then "b" else "c" fi fi
        else
            Set string value: .r, "g", if .i mod 2 = 0 then "a" else "b" fi
        endif
    endfor
    if .blank$ <> "none"
        Append row
        .r = Get number of rows
        Set numeric value: .r, "y", 99
        Set string value: .r, "g", if .blank$ = "empty" then "" else "   " fi
    endif
    .id = selected ("Table")
endproc

procedure run: .name$, .nReal, .blank$
    @build: .name$, .nReal, .blank$
    @emlCountGroups: build.id, "g"
    .labels$ = ""
    for .k from 1 to emlCountGroups.nGroups
        if .labels$ <> ""
            .labels$ = .labels$ + ","
        endif
        .labels$ = .labels$ + emlCountGroups.groupLabel$[.k]
    endfor
    appendInfoLine: "CASE ", .name$, " nGroups=", emlCountGroups.nGroups,
    ... " nBlank=", emlCountGroups.nBlankRows, " labels=", .labels$
endproc

@run: "clean", 3, "none"
@run: "oneblank", 3, "empty"
@run: "whitespace", 3, "spaces"
@run: "twogroupblank", 2, "empty"

appendInfoLine: "BLANKGROUP DONE"
