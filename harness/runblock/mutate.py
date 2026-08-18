# ---------------------------------------------------------------------------
# runblock/mutate.py -- put one defect back into a COPY of the plugin
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
#   python3 mutate.py <break> <plugin-copy>
#
# NOTHING IS VALIDATED UNTIL A CHECK HAS BEEN SEEN TO FAIL. Each break below
# is the smallest edit that puts back one part of the old naming -- the part
# the ruling replaced -- so that validate/v87 can be watched going red on it
# and the red can be attributed to that part and not to a broken tree.
#
# THE EDITS ARE EXACT TEXT, and every one of them is required to match once.
# A break that silently matched nothing would drive a healthy tree and report
# a green v87 as though the check were worthless.
#
#   value_dedup       the column slot keyed on (role, LITERAL) again, which
#                     is the defect the ruling names: a column called "n" in
#                     two different tables collapsing into one variable.
#   first_use_number  the ending numbered by FIRST USE OF THE ROLE across the
#                     whole session instead of by the run -- the first slot of
#                     a role bare, the second 2, the third 3, whatever run
#                     they came from. A role that only run 2 used then comes
#                     back unsuffixed, and a run holding two answers for one
#                     role comes back claiming to be two runs.
#   data_by_source    the object variables keyed on the OBJECT again, so two
#                     passes over one table share data1$ -- the case the
#                     ruling names in as many words, and the one the retarget
#                     leg exists to drive.
#   suffix_run_one    run 1 numbered like every other run, so the block opens
#                     at valueCol1$.
#   shared_axis       the axis pair matched across runs again, so two figures
#                     drawn on the same range share one pair and one
#                     resolved-value note.
#   drop_format_run   the run taken off ONE field -- the figure format -- and
#                     nothing else, which is the shape of a rule that grew a
#                     per-field exception.
#   boundary_outside_loop
#                     the graphs form's AND the wizard's boundary calls lifted
#                     OUT of their pass loops to just above them, so each
#                     marks the first pass and no other and every session
#                     comes back as one run. This one damages files no driver
#                     here executes -- both need dialogs -- which is why v87
#                     reads those calls' positions out of the source and why
#                     break.sh points its source reader at the damaged copy.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ---------------------------------------------------------------------------
import sys, os

name, tree = sys.argv[1], sys.argv[2]
REC = os.path.join(tree, "stats", "eml-record.praat")
FORM = os.path.join(tree, "graphs", "eml-graphs-form.praat")
WIZ = os.path.join(tree, "scripts", "eml-wizard.praat")

COL_SEARCH = """                                    if .varBase$[.k] = .b$
                                        if .varRun[.k] = .run
                                            .sameRun = .sameRun + 1
                                            if .varLit$[.k] = .lit$
                                                .slot = .k
                                            endif
                                        endif
                                    endif
"""

AX_SEARCH = """                                    if .axBase$[.k] = .aBase$
                                        if .axRun[.k] = .run
                                            .aSame = .aSame + 1
                                            if .axMinLit$[.k] = .aMinOut$
                                                if .axMaxLit$[.k] = .aMaxOut$
                                                    .aSlot = .k
                                                endif
                                            endif
                                        endif
                                    endif
"""

FMT_SEARCH = """                                    if .fmtBase$[.k] = .fBase$
                                        if .fmtRun[.k] = .run
                                            .fSame = .fSame + 1
                                            if .fmtLit$[.k] = .fLit$
                                                .fSlot = .k
                                            endif
                                        endif
                                    endif
"""

SUFFIX_BODY = """    .number$ = string$ (.run)
    if .already > 0
        .letter$ = mid$ ("bcdefghijklmnopqrstuvwxyz", .already, 1)
        ; THE ALPHABET RUNS OUT AT TWENTY-SIX ANSWERS IN ONE PASS, and past
        ; it mid$ returns "" -- which would be a SECOND VARIABLE WITH THE
        ; FIRST ONE'S NAME rather than a cosmetic problem. Past z the answer
        ; is numbered.
        if .letter$ = ""
            .letter$ = "_" + string$ (.already + 1)
        endif
        .number$ = .number$ + .letter$
    endif
"""

SRC_SEARCH = """            for .k from 1 to .n
                if .run[.k] = .srcRun
                    .sameRun = .sameRun + 1
                    if .name$[.k] = .src$
                        .seen = .k
                    endif
                endif
            endfor
"""

RUN1_BARE = """    .suffix$ = .number$
    if .run = 1
        if .already = 0
            .suffix$ = ""
        endif
    endif
"""

FMT_NAME = """                                    .fmtName$[.nFmt] = .fBase$
                                    ... + emlRecordRunSuffix.suffix$ + "$"
"""

# Each break is a list of (file, before, after) with an exact-once match.
BREAKS = {
    # The run guard removed from the column slot search: the key is
    # (role, literal) again and the suffix counts distinct literals.
    "value_dedup": [(REC, COL_SEARCH,
        COL_SEARCH.replace("if .varRun[.k] = .run", "if 1 = 1"))],

    # The slot stays per run; the COUNT that chooses the suffix stops being
    # per run, so the ending is a first-use ordinal instead of the run.
    "first_use_number": [
        (REC, COL_SEARCH, """                                    if .varBase$[.k] = .b$
                                        .sameRun = .sameRun + 1
                                        if .varRun[.k] = .run
                                            if .varLit$[.k] = .lit$
                                                .slot = .k
                                            endif
                                        endif
                                    endif
"""),
        (REC, AX_SEARCH, """                                    if .axBase$[.k] = .aBase$
                                        .aSame = .aSame + 1
                                        if .axRun[.k] = .run
                                            if .axMinLit$[.k] = .aMinOut$
                                                if .axMaxLit$[.k] = .aMaxOut$
                                                    .aSlot = .k
                                                endif
                                            endif
                                        endif
                                    endif
"""),
        (REC, FMT_SEARCH, """                                    if .fmtBase$[.k] = .fBase$
                                        .fSame = .fSame + 1
                                        if .fmtRun[.k] = .run
                                            if .fmtLit$[.k] = .fLit$
                                                .fSlot = .k
                                            endif
                                        endif
                                    endif
"""),
        # ... and the ending itself counted rather than named: slot 1 bare,
        # slot 2 "2", slot 3 "3", whatever run each came from.
        (REC, SUFFIX_BODY, """    .number$ = string$ (.already + 1)
"""),
        (REC, RUN1_BARE, """    .suffix$ = .number$
    if .already = 0
        if .already = 0
            .suffix$ = ""
        endif
    endif
"""),
    ],

    # Run 1 spelled like every other run.
    "suffix_run_one": [(REC, RUN1_BARE, "    .suffix$ = .number$\n")],

    # The axis pair matched across runs again.
    "shared_axis": [(REC, AX_SEARCH,
        AX_SEARCH.replace("if .axRun[.k] = .run", "if 1 = 1"))],

    # One field loses its run and the rest keep theirs.
    "drop_format_run": [(REC, FMT_NAME,
        """                                    .fmtName$[.nFmt] = .fBase$
                                    ... + "" + "$"
""")],

    # The object variables keyed on the object again rather than on the run.
    "data_by_source": [(REC, SRC_SEARCH, """            for .k from 1 to .n
                if 1 = 1
                    .sameRun = .sameRun + 1
                    if .name$[.k] = .src$
                        .seen = .k
                    endif
                endif
            endfor
""")],

    # Both pass loops' boundary calls lifted OUT to just above the loop --
    # each then marks the first pass and no other. The anchors are each
    # loop's own opening line and the guarded call inside it.
    "boundary_outside_loop": [
        (FORM, """\nrepeat\n""", """\nif variableExists ("emlRecordLoaded")
    @emlRecordNewRun
endif
repeat\n"""),
        (FORM, """    if variableExists ("emlRecordLoaded")
        @emlRecordNewRun
    endif
""", ""),
        (WIZ, """runAgain = 1
while runAgain = 1
""", """runAgain = 1
if variableExists ("emlRecordLoaded")
    @emlRecordNewRun
endif
while runAgain = 1
"""),
        (WIZ, """if variableExists ("emlRecordLoaded")
    @emlRecordNewRun
endif

wizCanDraw = 0
""", """wizCanDraw = 0
"""),
    ],
}

if name not in BREAKS:
    sys.exit("unknown break: " + name)

for path, before, after in BREAKS[name]:
    src = open(path, encoding="utf-8").read()
    n = src.count(before)
    if n != 1:
        sys.exit("break %s: anchor matched %d times in %s (expected 1)"
                 % (name, n, path))
    open(path, "w", encoding="utf-8").write(src.replace(before, after))

print("break %s applied" % name)
