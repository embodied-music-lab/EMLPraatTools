# ============================================================================
# lib_sweep.praat -- shared helpers for the headless sweep tiers.
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# Nothing here computes a statistic. These procedures build tables, record
# pass/fail lines, and print a ledger, so a sweep script is nothing but the
# cases it is testing.
# ============================================================================

sweepPass = 0
sweepFail = 0
sweepLog$ = ""

# ---------------------------------------------------------------------------
# @sweepMakeGroups: .nGroups, .n#, .mean#, .sd, .decimals
#   Build a two-column Table (value, grp) with the requested per-group sizes
#   and means. .decimals >= 0 rounds every value, which is how ties are
#   manufactured on demand: .decimals = 0 on sd = 1 data produces heavy ties.
#   .decimals = -1 leaves full precision (no ties).
# Result: .tableId
# ---------------------------------------------------------------------------
procedure sweepMakeGroups: .nGroups, .n#, .mean#, .sd, .decimals
    .total = 0
    for .g from 1 to .nGroups
        .total = .total + .n# [.g]
    endfor
    .tableId = Create Table with column names: "sweep", .total, "value grp"
    .r = 0
    for .g from 1 to .nGroups
        for .i from 1 to .n# [.g]
            .r = .r + 1
            .v = .mean# [.g] + randomGauss (0, .sd)
            if .decimals >= 0
                .v = round (.v * 10 ^ .decimals) / 10 ^ .decimals
            endif
            selectObject: .tableId
            Set numeric value: .r, "value", .v
            Set string value: .r, "grp", "G" + string$ (.g)
        endfor
    endfor
endproc

# ---------------------------------------------------------------------------
# @sweepTransform: .tableId, .col$, .add, .mul
#   value := .mul * value + .add, in place. Used for the equivariance cases.
# ---------------------------------------------------------------------------
procedure sweepTransform: .tableId, .col$, .add, .mul
    selectObject: .tableId
    .nr = Get number of rows
    for .r from 1 to .nr
        .v = Get value: .r, .col$
        Set numeric value: .r, .col$, .mul * .v + .add
    endfor
endproc

# ---------------------------------------------------------------------------
# @sweepNear: .id$, .what$, .a, .b, .tol
#   A property assertion. Both sides must be defined; undefined is a failure,
#   never a skip, because "the procedure returned nothing" is exactly the
#   outcome a silent regression produces.
# ---------------------------------------------------------------------------
procedure sweepNear: .id$, .what$, .a, .b, .tol
    if .a = undefined or .b = undefined
        @sweep_record: 0, .id$, .what$, "undefined (a=" + string$ (.a)
        ... + " b=" + string$ (.b) + ")"
    elsif abs (.a - .b) <= .tol
        @sweep_record: 1, .id$, .what$, string$ (.a) + " ~ " + string$ (.b)
    else
        @sweep_record: 0, .id$, .what$, string$ (.a) + " != " + string$ (.b)
        ... + "  (diff " + string$ (abs (.a - .b)) + " > tol " + string$ (.tol) + ")"
    endif
endproc

# ---------------------------------------------------------------------------
# @sweepRefuses: .id$, .what$, .error$, .mustMention$
#   The error-path assertion. The procedure must have refused, AND its message
#   must name the thing that was wrong -- a bare "error" passes nothing here,
#   because an unhelpful refusal is a defect in its own right (D99).
# ---------------------------------------------------------------------------
procedure sweepRefuses: .id$, .what$, .error$, .mustMention$
    if .error$ = ""
        @sweep_record: 0, .id$, .what$, "did NOT refuse"
    elsif .mustMention$ <> "" and index (.error$, .mustMention$) = 0
        @sweep_record: 0, .id$, .what$, "refused but did not mention """
        ... + .mustMention$ + """: " + .error$
    else
        @sweep_record: 1, .id$, .what$, "refused: " + .error$
    endif
endproc

# ---------------------------------------------------------------------------
# @sweepComputes: .id$, .what$, .error$, .value
#   The mirror of the above: a case that must NOT refuse.
# ---------------------------------------------------------------------------
procedure sweepComputes: .id$, .what$, .error$, .value
    if .error$ <> ""
        @sweep_record: 0, .id$, .what$, "refused: " + .error$
    elsif .value = undefined
        @sweep_record: 0, .id$, .what$, "no error but value undefined"
    else
        @sweep_record: 1, .id$, .what$, string$ (.value)
    endif
endproc

procedure sweep_record: .ok, .id$, .what$, .detail$
    if .ok
        sweepPass = sweepPass + 1
        .tag$ = "PASS"
    else
        sweepFail = sweepFail + 1
        .tag$ = "FAIL"
    endif
    sweepLog$ = sweepLog$ + .tag$ + "  " + .id$ + "  " + .what$
    ... + "  |  " + .detail$ + newline$
endproc

procedure sweepReport: .title$
    appendInfoLine: ""
    appendInfoLine: "=== " + .title$ + " ==="
    appendInfoLine: sweepLog$
    appendInfoLine: string$ (sweepPass + sweepFail) + " properties, "
    ... + string$ (sweepPass) + " passed, " + string$ (sweepFail) + " FAILED"
endproc
