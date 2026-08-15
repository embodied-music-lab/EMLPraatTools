# ============================================================================
# v59_entry_points.R -- every registered button opens its dialog
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS FILE EXISTS. A registration in setup.praat is a promise. The button
# is drawn because an object of that type is selected, so pressing it must at
# minimum reach the dialog it advertises. On 14 August 2026 eight of the
# eleven TableOfReal/Matrix registrations broke that promise -- and they broke
# it BEFORE the dialog, in native Praat error text, which is the worst place
# for a plugin to fail because none of the plugin's own error machinery is
# reached:
#
#     Error: Table "eml_numericProbe": the cell in row 1 of column "row"
#     is undefined.
#
# THE MECHANISM, because the shape of it is why nothing saw it. Praat's
# `To Table: "row"` writes the literal "?" into the row-label column for every
# row whose label is empty. A Matrix has no row labels at all, so every row of
# a converted Matrix gets one. @eml_strictNumericColumn
# (stats/eml-extract.praat:878) scans a column for "" and "--undefined--"
# before it runs the un-nocheck'd `Get all numbers in column:`; "?" is neither
# string, so the scan passes the column and the read raises. A TableOfReal the
# user LABELLED converts to real labels and works perfectly. That qualifier --
# same button, same script, same code path, opposite outcome depending on
# whether the user happened to name their rows -- is why this survived a green
# suite, a green harness and a live audit leg that drove the labelled case.
#
# WHAT COULD NOT HAVE CAUGHT IT, and every one of these is a check that exists
# and is doing its own job correctly:
#
#   * harness/wrappers/run.sh runs every script in plugin/scripts with NOTHING
#     SELECTED and asks only whether it parses. A wrapper that refuses for
#     want of an object has parsed, which is all that harness asks -- so a
#     wrapper that dies on a Matrix and one that dies on nothing at all are
#     indistinguishable to it. Its population is FILES.
#   * v46 reads call sites. An entry point that never reaches the call has no
#     call site to read.
#   * harness/savepaths presses Save on every caller of @emlSavePanel. A path
#     that dies three procedures before the panel is not a caller, so it is
#     outside that population by construction.
#   * v49 enumerates wrappers that run an orchestrator and asks which of them
#     offer a Save. It missed the describe wrapper's missing Save (D12) for a
#     reason worth writing down: its filter is
#     `any(grepl("@emlRun[A-Za-z]+Analysis:", ...))`, and
#     eml-describe-table.praat did its own arithmetic and called
#     @emlReportDescriptiveAnalysis, which does not match that pattern. The
#     one wrapper with no Save was the one wrapper the population excluded.
#     Not a bug in v49 -- a population that could not contain the defect.
#   * validate/coverage.R compares rendered cases against claimed cases per
#     artefact. A button that dies before its dialog renders no artefact.
#
# So the population is not files, not call sites, not artefacts and not
# terminal branches. It is REGISTRATIONS -- the (object type, script) pairs
# setup.praat writes -- which is exactly the set all of those exclude, and
# exactly the set the user sees as buttons. This file reads them out of
# setup.praat rather than listing them here, so a registration added tomorrow
# is in the population tomorrow.
#
# AND IT DRIVES THEM. A static read of setup.praat would have said all eleven
# were fine, because the defect is not in setup.praat -- it is four procedures
# downstream, in whichever of the FOUR different coercions that script happens
# to use. So each registration is run against a real object of its registered
# type under a real Praat, and the verdict is Praat's own exit status.
#
# THE ORACLE, and why it works without a display. `beginPause:` cannot open a
# window in a headless run: Praat traps (SIGTRAP, exit 133) the moment it
# tries. That trap is the signal this file wants. Reaching it means the script
# ran, coerced the object, built its form and asked for the window -- the
# dialog was reached. A script that dies earlier exits 255 with "Error:" on
# stdout, and one that never asks for a window exits 0. So:
#
#     exit 133, no "Error:"   -> the dialog was reached          PASS
#     "Error:" anywhere       -> it died before the dialog       FAIL
#     exit 0                  -> it finished without asking      FAIL
#
# This is the same trap harness/wrappers/run.sh documents and deliberately
# ignores; here it is the measurement rather than the noise.
#
# TWO STATES FOR TableOfReal, NOT ONE. Labelled and unlabelled are driven as
# separate cases because they were the two sides of the defect. A file that
# drove one TableOfReal would have a 50% chance of being the file that missed
# this, and which half it got would be an accident of how the fixture was
# written.
#
#     Rscript validate/v59_entry_points.R
#
# Not a member of validate/run_all.R's list: it LAUNCHES PRAAT, thirty times,
# where every file in that list is arithmetic over committed evidence and
# needs no binary at all. Run it on its own -- it takes about five seconds --
# and run it on any change to setup.praat, to a wrapper's entry block, or to
# a coercion.
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
setup <- file.path(plug, "setup.praat")

check_true("v59", "setup.praat was read", file.exists(setup))
if (!file.exists(setup)) {
    if (!exists("EML_SUITE")) { eml_report("v59 entry points"); eml_exit() }
    stop("v59: no setup.praat")
}

st <- readLines(setup, warn = FALSE)

# ---------------------------------------------------------------------------
# 1. THE REGISTRATIONS, READ OUT OF THE FILE THAT MAKES THEM
# ---------------------------------------------------------------------------
# Commented-out lines are excluded -- the tabled batch and quick-start entries
# sit in this file as comments by standing author ruling and are not promises
# to anybody. Cascade headers and separators carry an empty script and are not
# entry points either.
live <- st[!grepl("^\\s*[#;]", st)]

.field <- function(ln) {
    # Every argument of these two commands is either a quoted string or a
    # bare number, so the quoted strings in order ARE the string arguments in
    # order. Nothing in this file's arguments contains an escaped quote.
    regmatches(ln, gregexpr('"[^"]*"', ln))[[1]]
}

acts <- live[grepl("^\\s*Add action command:", live)]
mens <- live[grepl("^\\s*Add menu command:", live)]

# Add action command: class1$, n1, class2$, n2, class3$, n3, title$, after$,
#                     depth, script$   -> strings are class1, class2, class3,
#                                         title, after, script
reg <- do.call(rbind, lapply(acts, function(ln) {
    f <- gsub('"', "", .field(ln))
    if (length(f) < 6) return(NULL)
    data.frame(kind = "action", class = f[1], title = f[4],
               script = f[6], stringsAsFactors = FALSE)
}))

# Add menu command: window$, menu$, title$, after$, depth, script$
menu <- do.call(rbind, lapply(mens, function(ln) {
    f <- gsub('"', "", .field(ln))
    if (length(f) < 5) return(NULL)
    data.frame(kind = "menu", class = f[1], title = f[3],
               script = f[5], stringsAsFactors = FALSE)
}))
# A setup.praat that registers NOTHING is the loudest possible version of the
# failure this file exists for, so it must produce a red check rather than an
# R error: do.call(rbind, list()) is NULL, and nrow(NULL) is NULL, which
# reaches sprintf as character(0) and takes the whole run down.
.frame0 <- function(x) {
    if (is.null(x)) data.frame(kind = character(0), class = character(0),
                               title = character(0), script = character(0),
                               stringsAsFactors = FALSE) else x
}
reg <- .frame0(reg)
menu <- .frame0(menu)
menu <- menu[nzchar(menu$script), , drop = FALSE]

check_true("v59", sprintf("setup.praat registers action buttons (%d)", nrow(reg)),
           nrow(reg) >= 20)
check_true("v59", sprintf("setup.praat registers menu commands with scripts (%d)",
                          nrow(menu)),
           nrow(menu) >= 10)

# THE POPULATION THIS FILE WAS WRITTEN FOR, pinned by name and by count. If a
# TableOfReal or Matrix button is quietly dropped, the honest way to do it is
# to change this number on purpose.
tm <- reg[reg$class %in% c("TableOfReal", "Matrix"), , drop = FALSE]
check_true("v59",
           sprintf("the TableOfReal/Matrix population is eleven (%d: %d + %d)",
                   nrow(tm), sum(tm$class == "TableOfReal"),
                   sum(tm$class == "Matrix")),
           nrow(tm) == 11 && sum(tm$class == "TableOfReal") == 6 &&
               sum(tm$class == "Matrix") == 5)

# ---------------------------------------------------------------------------
# 2. NO REGISTRATION POINTS AT A FILE THAT IS NOT THERE
# ---------------------------------------------------------------------------
# This is the cheapest possible dead door and the plugin has shipped one: the
# interactive tutorial was registered at v1.3 with an include of a directory
# that does not exist, and it took until v1.4 to unregister it. A path that
# does not resolve is a button that does nothing at all.
allreg <- rbind(reg, menu)
missing <- allreg$script[!file.exists(file.path(plug, allreg$script))]
check_true("v59",
           sprintf("every registered script exists (%s)",
                   if (length(missing)) paste(unique(missing), collapse = ", ")
                   else sprintf("%d paths", nrow(allreg))),
           length(missing) == 0)

# ---------------------------------------------------------------------------
# 3. THE BINARY
# ---------------------------------------------------------------------------
# Same floor and the same refusal as harness/_env.sh. A green live drive on a
# build below the plugin's own floor is not evidence, and this file says so
# rather than passing quietly -- the v52 rule.
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
# 4. FIXTURES -- one real object per registered type
# ---------------------------------------------------------------------------
# The Table fixture carries a grouping column and two numeric columns so that
# every wrapper registered on Table has columns to guess roles from; a
# one-column table would refuse for a reason that has nothing to do with what
# is being measured here.
fixture <- c(
'procedure mk: .kind$',
'    if .kind$ = "Table"',
'        Create Table with column names: "v59src", 12, "grp value value2"',
'        for .i from 1 to 12',
'            if .i <= 6',
'                Set string value: .i, "grp", "A"',
'            else',
'                Set string value: .i, "grp", "B"',
'            endif',
'            Set numeric value: .i, "value", 10 + .i',
'            Set numeric value: .i, "value2", 3 + .i * 1.7',
'        endfor',
'    elsif .kind$ = "TableOfReal"',
'        Create simple Matrix: "v59src", 12, 3, "row * 10 + col * 1.5"',
'        To TableOfReal',
'        removeObject: "Matrix v59src"',
'    elsif .kind$ = "TableOfReal (row labels)"',
'        Create simple Matrix: "v59src", 12, 3, "row * 10 + col * 1.5"',
'        To TableOfReal',
'        removeObject: "Matrix v59src"',
'        for .i from 1 to 12',
'            Set row label (index): .i, "s" + string$ (.i)',
'        endfor',
'    elsif .kind$ = "Matrix"',
'        Create simple Matrix: "v59src", 12, 3, "row * 10 + col * 1.5"',
'    elsif .kind$ = "Sound"',
'        Create Sound from formula: "v59src", 1, 0, 1, 44100, "0.5*sin(2*pi*220*x)"',
'    elsif .kind$ = "Pitch"',
'        Create Sound from formula: "v59src", 1, 0, 1, 44100, "0.5*sin(2*pi*220*x)"',
'        To Pitch: 0.01, 75, 600',
'        removeObject: "Sound v59src"',
'    elsif .kind$ = "Spectrum"',
'        Create Sound from formula: "v59src", 1, 0, 1, 44100, "0.5*sin(2*pi*220*x)"',
'        To Spectrum: "yes"',
'        removeObject: "Sound v59src"',
'    elsif .kind$ = "Ltas"',
'        Create Sound from formula: "v59src", 1, 0, 1, 44100, "0.5*sin(2*pi*220*x)"',
'        To Ltas: 100',
'        removeObject: "Sound v59src"',
'    else',
'        exitScript: "v59: no fixture for " + .kind$',
'    endif',
'endproc')

# A TableOfReal is driven in BOTH states. Everything else has one.
states <- function(cls) {
    if (identical(cls, "TableOfReal")) c("TableOfReal", "TableOfReal (row labels)")
    else cls
}

# THE ONE EXEMPTION, NAMED RATHER THAN TOLERATED BY SILENCE. The table editor
# opens a TableEditor window, and Praat refuses to open any editor in a
# headless run -- "Cannot edit a Table from batch", its own message, raised by
# Praat and not by the plugin. That refusal is itself the evidence the script
# got all the way to the editor call, so it is asserted rather than skipped:
# any OTHER error from that registration is a failure.
exempt_msg <- "Cannot edit a Table from batch"

# ---------------------------------------------------------------------------
# 5. THE DRIVE
# ---------------------------------------------------------------------------
if (canDrive) {
    work <- file.path(tempdir(), "v59")
    dir.create(work, showWarnings = FALSE, recursive = TRUE)
    prefs <- file.path(work, "prefs")
    dir.create(prefs, showWarnings = FALSE)
    # A stale lock from a crashed run makes the next Praat refuse to start,
    # and a refusal at startup would read here as a dead entry point.
    unlink(file.path(prefs, c("pid", "message")))
    writeLines(fixture, file.path(work, "fixture.praat"))

    drive <- function(kind, script) {
        run <- file.path(work, "run.praat")
        writeLines(c(sprintf('include %s', file.path(work, "fixture.praat")),
                     sprintf('@mk: "%s"', kind),
                     sprintf('runScript: "%s"', file.path(plug, script))), run)
        out <- suppressWarnings(system2("env",
            c("-u", "DISPLAY", shQuote(praat),
              shQuote(paste0("--pref-dir=", prefs)), "--run", shQuote(run)),
            stdout = TRUE, stderr = TRUE))
        status <- attr(out, "status")
        if (is.null(status)) status <- 0L
        list(status = status, out = paste(out, collapse = "\n"))
    }

    cases <- do.call(rbind, lapply(seq_len(nrow(reg)), function(i) {
        do.call(rbind, lapply(states(reg$class[i]), function(s) {
            data.frame(class = reg$class[i], state = s, title = reg$title[i],
                       script = reg$script[i], stringsAsFactors = FALSE)
        }))
    }))
    if (is.null(cases)) cases <- data.frame(class = character(0),
        state = character(0), title = character(0), script = character(0),
        stringsAsFactors = FALSE)

    check_true("v59",
               sprintf("the drive covers every registration in both TableOfReal states (%d cases)",
                       nrow(cases)),
               nrow(cases) == nrow(reg) + sum(reg$class == "TableOfReal"))

    for (i in seq_len(nrow(cases))) {
        cs <- cases[i, ]
        r <- drive(cs$state, cs$script)
        died <- grepl("(^|\n)Error", r$out)
        label <- sprintf("%s on %s reaches its dialog", cs$title, cs$state)

        if (identical(basename(cs$script), "eml-edit-table-launch.praat")) {
            # The named exemption: it must fail with Praat's OWN editor
            # refusal and nothing else.
            check_true("v59",
                       sprintf("%s on %s reaches the editor (headless refusal only)",
                               cs$title, cs$state),
                       grepl(exempt_msg, r$out, fixed = TRUE))
            next
        }

        why <- ""
        if (died) {
            why <- sub("^.*?(Error[^\n]*).*$", "\\1", r$out)
            why <- substr(why, 1, 110)
        } else if (r$status != 133) {
            why <- sprintf("exit %s without asking for a dialog", r$status)
        }
        check_true("v59",
                   if (nzchar(why)) paste0(label, " -- ", why) else label,
                   !died && identical(as.integer(r$status), 133L))
    }
} else {
    # THE HONEST GAP. Reported as missing evidence, not passed over -- a
    # validator that goes green over an undriven population is worse than one
    # that says it could not drive it.
    cat(sprintf(paste0("      NOTE v59: LIVE EVIDENCE MISSING for %d registrations.\n",
                       "            Praat here is %s; the plugin floors at 6.6.30\n",
                       "            (plugin/setup.praat), and a drive below the floor\n",
                       "            is not evidence. Static checks above still hold.\n"),
                nrow(reg), if (is.na(pv)) "not found" else pv))
    check_true("v59",
               sprintf("a Praat at or above the plugin's floor is available (found %s)",
                       if (is.na(pv)) "none" else pv),
               FALSE)
}

# ---------------------------------------------------------------------------
# 6. THE CONVERSION CONTRACT
# ---------------------------------------------------------------------------
# Reaching the dialog is the promise; this is the promise behind it. AUTHOR
# RULING, 14 August 2026, on the conversion side of the coercion work: default
# row labels r1..rn at conversion time. That is a NAMING decision and it has
# no failure symptom of its own -- a converted table whose label column holds
# bare row numbers opens exactly the same dialog, and the only consequence is
# that a meaningless 1..n column sits in every column menu in the plugin
# looking like a measurement. Nothing above would notice, which is precisely
# why it needs a check of its own.
#
# THE BYTES UNDER TEST ARE THE SHIPPED BYTES. @emlDescribeCoerceSelection is
# lifted verbatim out of the shipped wrapper, between its `procedure` and
# `endproc` lines, and included into a probe. The wrapper cannot be included
# whole -- its body opens a dialog -- but nothing is retyped here, so a change
# to the shipped procedure is a change to what this section runs.
#
# THE PROBE RUNS IN A SANDBOX, NOT IN plugin/scripts. Praat resolves a
# relative include against the TOP-LEVEL script's folder, so a probe that
# says `include eml-lib.praat` has to sit beside it -- and writing scratch
# files into the tree under test is how a validator starts changing the thing
# it is measuring. The sandbox is a folder of symlinks with the same shape.
haveProc <- FALSE
if (canDrive) {
    wrap <- file.path(plug, "scripts", "eml-describe-table.praat")
    wl <- if (file.exists(wrap)) readLines(wrap, warn = FALSE) else character(0)
    i0 <- grep("^procedure emlDescribeCoerceSelection\\s*$", wl)
    i1 <- grep("^endproc", wl)
    i1 <- if (length(i0)) i1[i1 > i0[1]][1] else NA
    haveProc <- length(i0) == 1 && !is.na(i1)
    check_true("v59", "the describe wrapper carries its coercion procedure",
               haveProc)
}

if (canDrive && haveProc) {
    probeDir <- file.path(work, "sandbox", "scripts")
    dir.create(probeDir, showWarnings = FALSE, recursive = TRUE)
    for (d in c("stats", "graphs")) {
        tgt <- file.path(work, "sandbox", d)
        if (!file.exists(tgt))
            file.symlink(normalizePath(file.path(plug, d)), tgt)
    }
    for (f in list.files(file.path(plug, "scripts"), pattern = "^eml-lib.*\\.praat$")) {
        tgt <- file.path(probeDir, f)
        if (!file.exists(tgt))
            file.symlink(normalizePath(file.path(plug, "scripts", f)), tgt)
    }
    writeLines(wl[i0[1]:i1], file.path(probeDir, "v59-coerce.praat"))
    probe <- file.path(probeDir, "v59-probe.praat")
    writeLines(c(
        'include eml-lib.praat',
        'include v59-coerce.praat',
        'procedure dump: .tag$',
        '    @emlDescribeCoerceSelection',
        '    .t = emlDescribeCoerceSelection.tableId',
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
        'writeInfoLine: "v59 probe"',
        'Create simple Matrix: "v59src", 4, 3, "row * 10 + col"',
        '@dump: "matrix"',
        'Create simple Matrix: "v59src2", 4, 3, "row * 10 + col"',
        'To TableOfReal',
        'removeObject: "Matrix v59src2"',
        'for .i from 1 to 4',
        '    Set row label (index): .i, "s" + string$ (.i)',
        'endfor',
        '@dump: "labelled"'), probe)

    out <- suppressWarnings(system2("env",
        c("-u", "DISPLAY", shQuote(praat),
          shQuote(paste0("--pref-dir=", prefs)), "--run", shQuote(probe)),
        stdout = TRUE, stderr = TRUE))
    unlink(file.path(work, "sandbox"), recursive = TRUE)

    got <- function(tag, field) {
        p <- sprintf("^%s\\|%s\\|", tag, field)
        sub(p, "", grep(p, out, value = TRUE))
    }

    check_true("v59", "the conversion probe ran",
               !any(grepl("^Error", out)) && length(got("matrix", "NAME")) == 1)

    # (a) DEFAULT ROW LABELS, r1..rn, on the type that never has any.
    mlab <- got("matrix", "LABEL")
    check_true("v59",
               sprintf("a converted Matrix gets default row labels r1..rn (%s)",
                       paste(mlab, collapse = ",")),
               identical(mlab, paste0("r", 1:4)))

    # (b) AND THEY ARE LABELS, NOT DATA. The reason r1..rn was ruled rather
    # than 1..n: a bare row number reads as a measurement to every numeric
    # filter in the plugin and lands in every column menu as though it were
    # one.
    check_true("v59",
               "the default labels do not read as numbers",
               length(mlab) > 0 && all(is.na(suppressWarnings(as.numeric(mlab)))))

    # (c) A LABEL THE USER SUPPLIED IS NEVER OVERWRITTEN.
    llab <- got("labelled", "LABEL")
    check_true("v59",
               sprintf("a labelled TableOfReal keeps every label it had (%s)",
                       paste(llab, collapse = ",")),
               identical(llab, paste0("s", 1:4)))

    # (d) NO TWO COLUMNS SHARE A NAME. A Matrix arrives with every data column
    # called "?", and the editor family of defects (S1, severity 1) is what
    # duplicate column labels cost: every name-addressed read in this plugin
    # hits the FIRST match, so the second and third "?" are unreachable and a
    # user picking one of them silently analyses another column's data.
    mcol <- got("matrix", "COL")
    check_true("v59",
               sprintf("the converted Table has no duplicate column names (%s)",
                       paste(mcol, collapse = ",")),
               length(mcol) > 0 && !any(duplicated(mcol)) && !any(mcol == "?"))

    # (e) THE CONVERTED TABLE IS NOT NAMED AFTER ITS SOURCE. NEW-G12-2: a
    # native error anywhere downstream leaves the object list with two
    # entries of the same name and no cleanup handler ever runs, so the user's
    # next selection is a coin flip. The only placement that survives the
    # crash it exists for is at creation, which is what is asserted here.
    mname <- got("matrix", "NAME")
    check_true("v59",
               sprintf("the converted Table does not shadow its source's name (%s)",
                       paste(mname, collapse = ",")),
               length(mname) == 1 && mname != "v59src" &&
                   grepl("^eml_converted_", mname))
}

if (!exists("EML_SUITE")) {
    eml_report("v59 entry points: every registered button opens its dialog")
    eml_exit()
}
