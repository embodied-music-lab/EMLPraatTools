# ============================================================================
# v63_coercion_parity.R -- one Matrix, three doors, one table
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS FILE EXISTS. The plugin coerces a Matrix or a TableOfReal into a
# Table in three separate places, written by three separate hands, and on
# 15 August 2026 they disagreed about what the manufactured row-label column
# should contain:
#
#     scripts/eml-describe-table.praat  @emlDescribeCoerceSelection   r1..rn
#     stats/eml-output.praat            @emlWrapperInit               empty
#     graphs/eml-graph-procedures.praat @emlCleanConvertedTable       1..n
#
# So the same Matrix produced a different table depending on which menu item
# the user pressed. None of the three was broken in a way that raises -- each
# one is internally consistent, each one opens its dialog, and a validator
# pointed at any one of them goes green. The disagreement is only visible
# from above all three, which is what this file is.
#
# WHY r1..rn IS THE ONE. AUTHOR RULING, 14 August 2026, on the conversion
# side of NEW-G12-1. A column of bare integers is a column of numbers: the
# five-row numeric sniff in every wrapper classifies 1..n as a measurement,
# so it lands in every column picker in the plugin looking like data, and a
# user can select it and get a regression on row order. "r1" is not a number
# in any locale. An EMPTY column is not that hazard but it is its own -- a
# named column with nothing in it, which the user has to guess the meaning of
# and which reads as data loss. Neither has a failure symptom; both open the
# dialog; that is exactly why the convention needs a check rather than a
# convention.
#
# AND THE DUPLICATE HEADERS, which is not a naming quarrel but the S1
# severity-1 mechanism arriving by another route. `To Table: "row"` writes the
# literal "?" as the header of every column its source did not name -- every
# column of a Matrix, and every column of a TableOfReal that nothing labelled,
# which includes every TableOfReal made by `To TableOfReal`. The wrapper's
# column menu then reads
#
#     row, ?, ?, ?
#
# and every name-addressed read in this plugin -- `Get value: r, name$` -- is
# answered by Praat with the FIRST column of that name. The second and third
# are unreachable. Selecting one of them does not fail: it silently analyses
# the first one's data, under the second one's heading, and no output in the
# plugin names a column by index, so there is nothing for the user to notice.
#
# WHAT IS DRIVEN, AND WHAT IS READ. @emlWrapperInit cannot be lifted out of
# its file the way v59 lifts @emlDescribeCoerceSelection -- it is a procedure
# in a 3,000-line module that the whole stats layer includes -- so it is
# driven by including the shipped module and calling it, which means the bytes
# under test are the shipped bytes. @emlCleanConvertedTable is driven the same
# way out of the graphs layer. @emlDescribeCoerceSelection is lifted verbatim
# between its `procedure` and `endproc` lines, as v59 does, because its file's
# body opens a dialog.
#
# THE PROBE RUNS IN A SANDBOX OF SYMLINKS, not in plugin/scripts: Praat
# resolves a relative include against the top-level script's folder, and a
# validator that writes scratch files into the tree it is measuring has
# started changing that tree.
#
#     Rscript validate/v63_coercion_parity.R
#
# NOT A MEMBER OF validate/run_all.R's list, for v59's reason: it LAUNCHES
# PRAAT, where every file in that list is arithmetic over committed evidence
# and needs no binary at all. Run it on any change to a coercion.
#
# Input: the plugin source, driven live. $EML_PLUGIN_DIR overrides the tree
#        under test, for break tests. $PRAAT overrides the binary.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

plug <- Sys.getenv("EML_PLUGIN_DIR", unset = "")
if (!nzchar(plug)) plug <- repo_path("plugin")

# ---------------------------------------------------------------------------
# 1. THE BINARY -- same floor and the same refusal as harness/_env.sh
# ---------------------------------------------------------------------------
praat <- Sys.getenv("PRAAT", unset = "")
if (!nzchar(praat)) {
    for (cand in c(repo_path("..", "praat"), Sys.which("praat_barren"),
                   Sys.which("praat"))) {
        if (nzchar(cand) && file.exists(cand)) { praat <- cand; break }
    }
}
pv <- NA_character_
pvnum <- 0
if (nzchar(praat) && file.exists(praat)) {
    pv <- suppressWarnings(system2(praat, "--version", stdout = TRUE,
                                   stderr = TRUE))[1]
    m <- regmatches(pv, regexpr("[0-9]+\\.[0-9]+\\.[0-9]+", pv))
    if (length(m)) {
        p <- as.integer(strsplit(m, ".", fixed = TRUE)[[1]])
        pvnum <- p[1] * 1000 + p[2] * 100 + p[3]
    }
}
canDrive <- pvnum >= 6630

# ---------------------------------------------------------------------------
# 2. THE THREE DOORS ARE STILL THREE DOORS
# ---------------------------------------------------------------------------
# Read statically first, so a run that cannot launch Praat still says whether
# the population this file is about has changed underneath it. A fourth
# coercion appearing is the event that would make everything below incomplete
# while leaving it green.
srcInit  <- file.path(plug, "stats", "eml-output.praat")
srcDesc  <- file.path(plug, "scripts", "eml-describe-table.praat")
srcClean <- file.path(plug, "graphs", "eml-graph-procedures.praat")
have <- file.exists(c(srcInit, srcDesc, srcClean))
check_true("v63", "all three coercion sources are present", all(have))

if (all(have)) {
    ini <- readLines(srcInit, warn = FALSE)
    des <- readLines(srcDesc, warn = FALSE)
    cln <- readLines(srcClean, warn = FALSE)
    check_true("v63", "@emlWrapperInit is where the stats coercion lives",
               any(grepl("^procedure emlWrapperInit: ", ini)))
    check_true("v63", "@emlDescribeCoerceSelection is where the describe coercion lives",
               any(grepl("^procedure emlDescribeCoerceSelection\\s*$", des)))
    check_true("v63", "@emlCleanConvertedTable is where the graphs coercion lives",
               any(grepl("^procedure emlCleanConvertedTable: ", cln)))
    # THE CENSUS. `To Table: "row"` is the line that manufactures the column
    # this file is about, so counting it counts the doors: two arms in
    # @emlWrapperInit, two in @emlDescribeCoerceSelection, two in
    # @emlConvertForGraph. Comment lines are excluded -- every one of these
    # three files also DESCRIBES the command, and a census that counts prose
    # is a census that changes when somebody edits a comment. A seventh site
    # is a deliberate change to this number, not a silent addition, which is
    # the only way a fourth convention gets caught before it ships.
    .code <- function(x) x[!grepl("^\\s*[#;]", x)]
    nDoors <- sum(grepl('To Table: "row"',
                        c(.code(ini), .code(des), .code(cln)), fixed = TRUE))
    check_true("v63",
               sprintf("the coercion is performed at six sites across three procedures (%d)",
                       nDoors),
               nDoors == 6)
}

# ---------------------------------------------------------------------------
# 3. THE LIVE DRIVE
# ---------------------------------------------------------------------------
if (!canDrive) {
    cat(sprintf(paste0("      NOTE v63: LIVE EVIDENCE MISSING.\n",
                       "            Praat here is %s; the plugin floors at 6.6.30\n",
                       "            (plugin/setup.praat), and a drive below the floor\n",
                       "            is not evidence. Static checks above still hold.\n"),
                if (is.na(pv)) "not found" else pv))
    check_true("v63",
               sprintf("a Praat at or above the plugin's floor is available (found %s)",
                       if (is.na(pv)) "none" else pv),
               FALSE)
} else {
    work <- file.path(tempdir(), "v63")
    unlink(work, recursive = TRUE)
    dir.create(file.path(work, "scripts"), showWarnings = FALSE, recursive = TRUE)
    prefs <- file.path(work, "prefs")
    dir.create(prefs, showWarnings = FALSE)
    # A stale lock from a crashed run makes the next Praat refuse to start,
    # and a refusal at startup would read here as a coercion that produced
    # nothing. Only these two files, and only in this scratch folder.
    unlink(file.path(prefs, c("pid", "message")))

    for (d in c("stats", "graphs")) {
        tgt <- file.path(work, d)
        if (!file.exists(tgt)) file.symlink(normalizePath(file.path(plug, d)), tgt)
    }
    for (f in list.files(file.path(plug, "scripts"), pattern = "^eml-lib.*\\.praat$")) {
        tgt <- file.path(work, "scripts", f)
        if (!file.exists(tgt))
            file.symlink(normalizePath(file.path(plug, "scripts", f)), tgt)
    }

    # @emlDescribeCoerceSelection, lifted verbatim -- nothing retyped.
    des <- readLines(srcDesc, warn = FALSE)
    i0 <- grep("^procedure emlDescribeCoerceSelection\\s*$", des)
    i1 <- grep("^endproc", des)
    i1 <- if (length(i0)) i1[i1 > i0[1]][1] else NA
    lifted <- length(i0) == 1 && !is.na(i1)
    check_true("v63", "the describe coercion could be lifted from its wrapper", lifted)
    if (lifted) writeLines(des[i0[1]:i1], file.path(work, "scripts", "v63-coerce.praat"))

    probe <- file.path(work, "scripts", "v63-probe.praat")
    writeLines(c(
        'include eml-lib.praat',
        'include v63-coerce.praat',
        '',
        '# Report the shape of whatever table a door produced. The row-label',
        '# column is read by INDEX, never by the name "row": a collision',
        '# rename can have moved it, and reading the literal would then read',
        '# the user data column instead -- which is the bug next door.',
        'procedure shape: .tag$, .t',
        '    selectObject: .t',
        '    appendInfoLine: .tag$, "|NAME|", selected$ ("Table")',
        '    .nc = Get number of columns',
        '    .nr = Get number of rows',
        '    for .i from 1 to .nc',
        '        selectObject: .t',
        '        .lab$ = Get column label: .i',
        '        appendInfoLine: .tag$, "|COL|", .lab$',
        '    endfor',
        '    for .r from 1 to .nr',
        '        selectObject: .t',
        '        .lab$ = Get column label: 1',
        '        .cell$ = Get value: .r, .lab$',
        '        appendInfoLine: .tag$, "|LABEL|", .cell$',
        '    endfor',
        'endproc',
        '',
        'procedure mkMatrix: .name$',
        '    Create simple Matrix: .name$, 4, 3, "row * 10 + col"',
        'endproc',
        'procedure mkToR: .name$, .labelled',
        '    Create simple Matrix: .name$, 4, 3, "row * 10 + col"',
        '    To TableOfReal',
        '    removeObject: "Matrix " + .name$',
        '    if .labelled',
        '        for .i from 1 to 4',
        '            Set row label (index): .i, "s" + string$ (.i)',
        '        endfor',
        '    endif',
        'endproc',
        '',
        'writeInfoLine: "v63 probe"',
        '',
        '# --- door 1: @emlWrapperInit, the nine stats wrappers ---------------',
        '@mkMatrix: "v63a"',
        '@emlWrapperInit: 1',
        '@shape: "init_matrix", emlWrapperInit.tableId',
        'removeObject: emlWrapperInit.tableId',
        'removeObject: "Matrix v63a"',
        '',
        '@mkToR: "v63b", 0',
        '@emlWrapperInit: 1',
        '@shape: "init_tor", emlWrapperInit.tableId',
        'removeObject: emlWrapperInit.tableId',
        'removeObject: "TableOfReal v63b"',
        '',
        '@mkToR: "v63c", 1',
        '@emlWrapperInit: 1',
        '@shape: "init_labelled", emlWrapperInit.tableId',
        'removeObject: emlWrapperInit.tableId',
        'removeObject: "TableOfReal v63c"',
        '',
        '# --- door 2: @emlDescribeCoerceSelection, the describe wrapper ------',
        '@mkMatrix: "v63d"',
        '@emlDescribeCoerceSelection',
        '@shape: "desc_matrix", emlDescribeCoerceSelection.tableId',
        'removeObject: emlDescribeCoerceSelection.tableId',
        'removeObject: "Matrix v63d"',
        '',
        '# --- door 3: @emlCleanConvertedTable, the graphing layer ------------',
        '# Called the way the graph coercion calls it: on a raw conversion.',
        '@mkMatrix: "v63e"',
        'tmpTor = To TableOfReal',
        'cleanId = To Table: "row"',
        'removeObject: tmpTor',
        '@emlCleanConvertedTable: cleanId',
        '@shape: "clean_matrix", cleanId'), probe)

    out <- suppressWarnings(system2("env",
        c("-u", "DISPLAY", shQuote(praat),
          shQuote(paste0("--pref-dir=", prefs)), "--run", shQuote(probe)),
        stdout = TRUE, stderr = TRUE))

    got <- function(tag, field) {
        p <- sprintf("^%s\\|%s\\|", tag, field)
        sub(p, "", grep(p, out, value = TRUE))
    }
    ran <- !any(grepl("^Error", out)) && length(got("clean_matrix", "NAME")) == 1
    if (!ran) cat(sprintf("      v63 probe output: %s\n",
                          paste(utils::tail(out, 6), collapse = " / ")))
    check_true("v63", "the coercion probe ran through all three doors", ran)

    if (ran) {
        # -- 3a. THE ROW-LABEL COLUMN, ONE CONVENTION -----------------------
        # Asserted per door rather than by comparing the doors to each other:
        # three doors that agree on 1..n would satisfy a parity check and be
        # wrong together, which is how the regression arm and the ANOVA arm
        # of .std.resid came to disagree for a month (v20).
        for (tag in c("init_matrix", "init_tor", "desc_matrix")) {
            lab <- got(tag, "LABEL")
            check_true("v63",
                       sprintf("%s: the manufactured row labels are r1..rn (%s)",
                               tag, paste(lab, collapse = ",")),
                       identical(lab, paste0("r", 1:4)))
            check_true("v63",
                       sprintf("%s: and they do not read as numbers", tag),
                       length(lab) > 0 &&
                       all(is.na(suppressWarnings(as.numeric(lab)))))
        }

        # -- 3b. A LABEL THE USER SUPPLIED IS NEVER OVERWRITTEN -------------
        lab <- got("init_labelled", "LABEL")
        check_true("v63",
                   sprintf("init_labelled: a labelled TableOfReal keeps every label it had (%s)",
                           paste(lab, collapse = ",")),
                   identical(lab, paste0("s", 1:4)))

        # -- 3c. NO TWO COLUMNS SHARE A NAME, BY ANY DOOR -------------------
        # The S1 mechanism: Praat answers a name-addressed read with the
        # first column of that name, so a duplicate is not a cosmetic defect,
        # it is a silent wrong-column read with no symptom.
        for (tag in c("init_matrix", "init_tor", "init_labelled",
                      "desc_matrix", "clean_matrix")) {
            cols <- got(tag, "COL")
            check_true("v63",
                       sprintf("%s: no duplicate or unnamed column (%s)",
                               tag, paste(cols, collapse = ",")),
                       length(cols) > 0 && !any(duplicated(cols)) &&
                       !any(cols == "?") && !any(cols == ""))
        }

        # -- 3d. THE CONVERTED TABLE DOES NOT SHADOW ITS SOURCE -------------
        # NEW-G12-2. The rename must happen at creation: a cleanup handler is
        # skipped by exactly the event it is written for. Checked on both
        # arms of @emlWrapperInit, which is where the six unfixed
        # registrations were.
        for (tag in c("init_matrix", "init_tor", "init_labelled", "desc_matrix")) {
            nm <- got(tag, "NAME")
            check_true("v63",
                       sprintf("%s: the converted Table is renamed at creation (%s)",
                               tag, paste(nm, collapse = ",")),
                       length(nm) == 1 && grepl("^eml_converted_", nm))
        }

        # -- 3e. THE GRAPHS DOOR, MEASURED AND REPORTED ---------------------
        # plugin/graphs/ is outside this change's scope and belongs to another
        # hand, so the third convention is MEASURED here and printed, and it
        # is deliberately not asserted either way. Two things it must not be:
        # a passing check (that is pinning a defect as a contract, which is
        # what v20's .std.resid assertion did for a month), or silence (which
        # is how the three conventions grew in the first place). What it is
        # instead is a stated divergence with the exact repair beside it, so
        # the run itself carries the routing note.
        clab <- got("clean_matrix", "LABEL")
        agrees <- identical(clab, paste0("r", 1:4))
        if (!agrees) {
            cat(sprintf(paste0(
                "      NOTE v63: THE GRAPHS DOOR STILL DISAGREES.\n",
                "            @emlCleanConvertedTable fills the row-label column\n",
                "            with %s -- bare row numbers, the one form that\n",
                "            reads as a measurement to every numeric filter in\n",
                "            the plugin. The other two doors now write r1..rn.\n",
                "            REPAIR: in plugin/graphs/eml-graph-procedures.praat,\n",
                "            @emlCleanConvertedTable's \"?\"-cell pass writes\n",
                "            `string$ (.iRow)`; it must write \"r\" + string$ (.iRow),\n",
                "            and its condition must accept the empty string as\n",
                "            well as \"?\" so it composes with a caller that has\n",
                "            already normalised. Then this note goes away and the\n",
                "            check below can be asserted for all three doors.\n"),
                paste(clab, collapse = ",")))
        }
        attest("v63",
               sprintf("the graphs door's row-label convention was measured: %s",
                       paste(clab, collapse = ",")),
               "driven live through @emlCleanConvertedTable; not asserted -- plugin/graphs/ is out of scope for this change")
        check_true("v63",
                   sprintf("clean_matrix: whatever the graphs door writes, it is written for every row (%s)",
                           paste(clab, collapse = ",")),
                   length(clab) == 4 && !any(clab == "?") && !any(clab == ""))
    }
}

if (!exists("EML_SUITE")) {
    eml_report("v63 coercion parity: one Matrix, three doors, one table")
    eml_exit()
}
