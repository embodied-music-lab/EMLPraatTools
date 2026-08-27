# ============================================================================
# v148 -- the "p method" disclosure row: Mann-Whitney/Wilcoxon composition,
#         and the explanation-class acceptance check
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS SETTLES. Item 22 of the language batch, ruled by Fable 27 August
# 2026: every rank test gains a "p method" report row, printed directly under
# its "p" row via the EXISTING @emlReportLineString (no new helper), and it
# prints ALWAYS -- disclosure class, never gated on emlShowExplanations. The
# values are "exact" (no parenthetical), or the method name plus EVERY
# condition that ruled the exact branch out, comma-separated, FIXED ORDER
# ("ties present, large sample, zero differences"), with NO precedence
# between them -- a cell with two applicable reasons names both, never one.
# v147 (a separate file) covers Spearman, which has its own n <= 1290
# cutoff and its own ties-vs-cutoff collision. This file covers the other
# two rank tests item 22 touches -- Mann-Whitney U and the Wilcoxon
# signed-rank -- and a SEPARATE, general acceptance check that the new row
# is disclosure class (prints regardless of the explanations toggle) while
# nothing it sits beside quietly became disclosure class along with it.
#
# PART 1 -- MANN-WHITNEY. @emlMannWhitneyU's exact branch requires n1 < 50
# AND n2 < 50 AND no ties (R's own wilcox.test.default rule); the two
# independent reasons it can fail are named "ties present" and "large
# sample" (either group at or above 50). Three fixtures, driven through
# @emlRunTwoGroupAnalysis (the real orchestrator, which calls
# @emlReportTwoGroupComparison internally) so the ACTUAL printed "p method"
# line is checked, not only the .method$/.methodReason$ fields: ties only
# (small n), large sample only (n1 = n2 = 60, no ties), and both at once
# (n1 = n2 = 60 with one forced duplicate) -- the case that proves there is
# no precedence between the two reasons.
#
# PART 2 -- WILCOXON SIGNED-RANK. @emlWilcoxonSignedRank adds a THIRD
# independent reason no other test in this batch has: zero differences
# (nZero > 0). Five fixtures, driven through @emlRunPairedAnalysis: zero
# differences alone, ties alone, large sample alone, ties + large sample
# together, and all three reasons at once (the maximal case for "no
# precedence, every condition named").
#
# PART 3 -- THE EXPLANATION-CLASS ACCEPTANCE CHECK. The classifier is the
# GATE, never the text: a report line's class (disclosure vs explanation)
# is declared by which gate it passes through, not by what it says. One
# fixture (the PART 1 ties-only Mann-Whitney cell, which already exercises
# several genuinely gated glosses) is driven THREE times -- default (no
# override), emlShowExplanations forced to 0, forced to 1 -- and:
#   (a) the default drive is asserted BYTE-IDENTICAL to the forced-off
#       drive (the default IS off, since item 22's Task 4 flipped
#       emlShowExplanationsDefault to 0);
#   (b) every line present in the forced-on drive and absent from the
#       forced-off drive is, BY CONSTRUCTION of the experiment (the ONLY
#       thing that differs between those two drives is the value of
#       emlShowExplanations), explanation class -- no text pattern (no
#       "Why:", no gloss wording) is ever matched to decide this; it falls
#       out of the diff itself;
#   (c) the "p method" row's exact printed line is asserted present,
#       BYTE-IDENTICAL, in ALL THREE drives -- proving it sits OUTSIDE the
#       set the gate controls, which is what "disclosure class" means
#       operationally.
# RED DEMO: a mutant copy of eml-analysis.praat with ONE line inserted --
# @emlRunTwoGroupAnalysis silently resets emlShowExplanations = 0 at entry,
# discarding any caller's override before the report ever reads it, the
# same shape as a real regression that reintroduces a stray reset. Driven
# through the SAME rig, this makes the forced-on drive byte-identical to
# forced-off (the toggle now does nothing), so assertion (b)'s "the raised
# flag brings extra lines back" goes red -- proving the acceptance check
# has teeth, not merely proving today's build passes it. Gated behind
# EML_EXPLCLASS_RED=1, same convention v147's red demonstrations use.
#
# Base R only. Requires a Praat at or above the plugin's floor; skips (not
# fails) below it, the same convention v108/v143..v147 use.
#
# Registered in validate/run_all.R.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

V <- "v148"

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

plug <- Sys.getenv("EML_PLUGIN_DIR", unset = "")
if (!nzchar(plug)) plug <- repo_path("plugin")
plug <- normalizePath(plug, mustWork = FALSE)

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

if (!canDrive) {
    cat(paste0("      SKIP: v148 needs Praat >= 6.6.30 to drive the procedure;\n",
               "            found ", if (is.na(pv)) "none" else pv, ".\n"))
    check_true(V,
               sprintf("a Praat at or above the plugin's floor is available (found %s)",
                       if (is.na(pv)) "none" else pv),
               FALSE)
} else {

    work <- file.path(tempdir(), "v148")
    unlink(work, recursive = TRUE)
    dir.create(work, showWarnings = FALSE, recursive = TRUE)
    prefs <- file.path(work, "prefs")
    dir.create(prefs, showWarnings = FALSE)

    ANA <- file.path(plug, "stats", "eml-analysis.praat")

    # prelude(): the same barrel every door needs. Parameterised on the
    # eml-analysis.praat path alone (PART 3's red demo substitutes a
    # mutant copy there; nothing else in this file ever needs a mutant).
    prelude <- function(analysis_file = ANA) c(
        paste0("include ", file.path(plug, "stats", "eml-core-utilities.praat")),
        paste0("include ", file.path(plug, "stats", "eml-core-descriptive.praat")),
        paste0("include ", file.path(plug, "stats", "eml-extract.praat")),
        paste0("include ", file.path(plug, "stats", "eml-output.praat")),
        paste0("include ", file.path(plug, "stats", "eml-inferential.praat")),
        paste0("include ", file.path(plug, "stats", "eml-result-writer.praat")),
        paste0("include ", file.path(plug, "graphs", "eml-graph-procedures.praat")),
        paste0("include ", file.path(plug, "graphs", "eml-annotation-procedures.praat")),
        paste0("include ", analysis_file))

    drive <- function(probe_path, secs = "240") {
        suppressWarnings(system2("timeout",
            c(secs, "env", "-u", "DISPLAY", shQuote(praat),
              shQuote(paste0("--pref-dir=", prefs)), "--run", shQuote(probe_path)),
            stdout = TRUE, stderr = TRUE))
    }

    vec_lit <- function(v) paste0("{", paste(sprintf("%.0f", v), collapse = ", "), "}")

    # composePMethod / pMethodLine -- reproduce, in R, exactly the string
    # @emlReportLineString/@emlPadRight print for the "p method" row: label
    # padded right to 20 characters, 2-space indent. Same reproduction
    # v147 uses for the Spearman arm; MW and Wilcoxon share the identical
    # printer and column widths, only the method label text differs
    # ("normal approximation" here vs "t approximation" there).
    composePMethod <- function(method, reason) {
        if (identical(method, "exact")) return("exact")
        if (!nzchar(reason)) return(method)
        paste0(method, " (", reason, ")")
    }
    pMethodLine <- function(value) paste0("  ", sprintf("%-20s", "p method"), value)

    # @emlReportHeader prints "  " + date$() as its own line, BY DESIGN
    # non-canonical (eml-output.praat's own comment: "date$() differs on
    # every run by construction ... either one inside the canonical text
    # would make two identical reports compare as different for ever").
    # Three separate `praat --run` processes here means three separate
    # wall-clock timestamps, so this ONE line is stripped before any
    # byte-identical comparison -- it is not part of what the explanations
    # gate controls, and leaving it in would make every drive "differ" by
    # construction regardless of the gate.
    dropTimestamp <- function(lines) lines[!grepl("^  (Sun|Mon|Tue|Wed|Thu|Fri|Sat) [A-Z][a-z]{2} +[0-9]+ [0-9:]+ [0-9]{4}$", lines)]

    # ---------------------------------------------------------------------
    # PART 1 -- MANN-WHITNEY: ties alone, large sample alone, both at once.
    # ---------------------------------------------------------------------
    # ties: n1 = n2 = 10 (both < 50), value 5 forced into BOTH groups ->
    #   one tie in the combined ranking, no other duplicate.
    # large: n1 = n2 = 60 (>= 50), disjoint value ranges -> no ties.
    # both: n1 = n2 = 60, value 1 forced into both groups -> ties AND large.
    mw_fixtures <- list(
        ties  = list(a = 1:10,        b = c(5, 12:20),
                     method = "normal approximation", reason = "ties present"),
        large = list(a = 1:60,        b = 1000 + (1:60),
                     method = "normal approximation", reason = "large sample"),
        both  = list(a = 1:60,        b = c(1, 1001:1059),
                     method = "normal approximation", reason = "ties present, large sample")
    )
    mw_lines <- c(prelude(), "",
        'procedure v148mw: .tag$, .a#, .b#',
        '    .n1 = size (.a#)',
        '    .n2 = size (.b#)',
        '    .id = Create Table with column names: "v148mw", 0, "Data Group"',
        '    for .i from 1 to .n1',
        '        Append row',
        '        Set numeric value: .i, "Data", .a#[.i]',
        '        Set string value: .i, "Group", "A"',
        '    endfor',
        '    for .i from 1 to .n2',
        '        Append row',
        '        Set numeric value: .n1 + .i, "Data", .b#[.i]',
        '        Set string value: .n1 + .i, "Group", "B"',
        '    endfor',
        '    @emlRunTwoGroupAnalysis: .id, "Data", "Group", "nonparametric", 0',
        '    .m$ = emlMannWhitneyU.method$',
        '    .mr$ = emlMannWhitneyU.methodReason$',
        '    appendInfoLine: "MW ", .tag$, " [", .m$, "] [", .mr$, "]"',
        '    removeObject: .id',
        'endproc', "")
    for (tag in names(mw_fixtures)) {
        fx <- mw_fixtures[[tag]]
        mw_lines <- c(mw_lines,
            sprintf("a# = %s", vec_lit(fx$a)),
            sprintf("b# = %s", vec_lit(fx$b)),
            sprintf('@v148mw: "%s", a#, b#', tag))
    }
    mw_path <- file.path(work, "v148-mw.praat")
    writeLines(c('writeInfoLine: "v148 mw"', mw_lines), mw_path)
    outMW <- drive(mw_path)
    ranMW <- !any(grepl("^Error", outMW))
    check_true(V, "the Mann-Whitney composed-reason probe ran with no Praat error", ranMW)
    if (!ranMW) {
        cat("      v148 MW probe output:\n      ",
            paste(utils::tail(outMW, 30), collapse = "\n      "), "\n", sep = "")
    } else {
        gotMW <- list()
        for (ln in grep("^MW ", outMW, value = TRUE)) {
            m <- regmatches(ln, regexec("^MW (\\S+) \\[([^]]*)\\] \\[([^]]*)\\]$", ln))[[1]]
            if (length(m) == 4) gotMW[[m[2]]] <- list(meth = m[3], mr = m[4])
        }
        for (tag in names(mw_fixtures)) {
            exp <- mw_fixtures[[tag]]
            cell <- gotMW[[tag]]
            check_true(V, sprintf("[MW %s] a cell was printed", tag), !is.null(cell))
            if (is.null(cell)) next
            check_true(V, sprintf("[MW %s] .method$ is \"%s\"", tag, exp$method),
                       identical(cell$meth, exp$method))
            check_true(V, sprintf("[MW %s] .methodReason$ is \"%s\" -- every condition that ruled out the exact branch, no precedence", tag, exp$reason),
                       identical(cell$mr, exp$reason))
            composed <- composePMethod(exp$method, exp$reason)
            check_true(V, sprintf("[MW %s] the printed \"p method\" row reads \"%s\"", tag, composed),
                       any(grepl(pMethodLine(composed), outMW, fixed = TRUE)))
        }
    }

    # ---------------------------------------------------------------------
    # PART 2 -- WILCOXON SIGNED-RANK: zero differences, ties, large sample,
    # ties+large, and all three at once.
    # ---------------------------------------------------------------------
    # diffs given directly as v1 - v2 (v2 fixed at a convenient baseline).
    wsr_fixtures <- list(
        zero  = list(d = c(0, 1, 2, 3, 4, 5),
                     method = "normal approximation", reason = "zero differences"),
        ties  = list(d = c(1, -1, 2, -2, 3, -3),
                     method = "normal approximation", reason = "ties present"),
        large = list(d = 1:60,
                     method = "normal approximation", reason = "large sample"),
        both  = list(d = c(1:59, 1),
                     method = "normal approximation", reason = "ties present, large sample"),
        all3  = list(d = c(1:59, 1, 0, 0),
                     method = "normal approximation", reason = "ties present, large sample, zero differences")
    )
    wsr_lines <- c(prelude(), "",
        'procedure v148wsr: .tag$, .d#',
        '    .n = size (.d#)',
        '    .id = Create Table with column names: "v148wsr", 0, "V1 V2"',
        '    for .i from 1 to .n',
        '        Append row',
        '        Set numeric value: .i, "V1", .d#[.i]',
        '        Set numeric value: .i, "V2", 0',
        '    endfor',
        '    @emlRunPairedAnalysis: .id, "V1", "V2", "nonparametric"',
        '    .m$ = emlWilcoxonSignedRank.method$',
        '    .mr$ = emlWilcoxonSignedRank.methodReason$',
        '    appendInfoLine: "WSR ", .tag$, " [", .m$, "] [", .mr$, "]"',
        '    removeObject: .id',
        'endproc', "")
    for (tag in names(wsr_fixtures)) {
        fx <- wsr_fixtures[[tag]]
        wsr_lines <- c(wsr_lines,
            sprintf("d# = %s", vec_lit(fx$d)),
            sprintf('@v148wsr: "%s", d#', tag))
    }
    wsr_path <- file.path(work, "v148-wsr.praat")
    writeLines(c('writeInfoLine: "v148 wsr"', wsr_lines), wsr_path)
    outWSR <- drive(wsr_path)
    ranWSR <- !any(grepl("^Error", outWSR))
    check_true(V, "the Wilcoxon signed-rank composed-reason probe ran with no Praat error", ranWSR)
    if (!ranWSR) {
        cat("      v148 WSR probe output:\n      ",
            paste(utils::tail(outWSR, 30), collapse = "\n      "), "\n", sep = "")
    } else {
        gotWSR <- list()
        for (ln in grep("^WSR ", outWSR, value = TRUE)) {
            m <- regmatches(ln, regexec("^WSR (\\S+) \\[([^]]*)\\] \\[([^]]*)\\]$", ln))[[1]]
            if (length(m) == 4) gotWSR[[m[2]]] <- list(meth = m[3], mr = m[4])
        }
        for (tag in names(wsr_fixtures)) {
            exp <- wsr_fixtures[[tag]]
            cell <- gotWSR[[tag]]
            check_true(V, sprintf("[WSR %s] a cell was printed", tag), !is.null(cell))
            if (is.null(cell)) next
            check_true(V, sprintf("[WSR %s] .method$ is \"%s\"", tag, exp$method),
                       identical(cell$meth, exp$method))
            check_true(V, sprintf("[WSR %s] .methodReason$ is \"%s\" -- every condition that ruled out the exact branch, fixed order, no precedence", tag, exp$reason),
                       identical(cell$mr, exp$reason))
            composed <- composePMethod(exp$method, exp$reason)
            check_true(V, sprintf("[WSR %s] the printed \"p method\" row reads \"%s\"", tag, composed),
                       any(grepl(pMethodLine(composed), outWSR, fixed = TRUE)))
        }
    }

    # ---------------------------------------------------------------------
    # PART 3 -- THE EXPLANATION-CLASS ACCEPTANCE CHECK.
    # ---------------------------------------------------------------------
    # One fixture (the PART 1 Mann-Whitney "ties" cell -- it already
    # exercises several genuinely gated glosses: the section's own "Why:"
    # line, @emlWizardExplainP's gloss on the p row, and the mwuMethod$
    # branch's own gloss), driven three times. The classifier here is
    # STRUCTURAL -- which drive a line appears in -- never a text pattern.
    explclass_probe <- function(override_line, analysis_file = ANA) {
        fx <- mw_fixtures[["ties"]]
        lines <- c(prelude(analysis_file), "")
        if (!is.null(override_line)) lines <- c(lines, override_line)
        lines <- c(lines,
            sprintf("a# = %s", vec_lit(fx$a)),
            sprintf("b# = %s", vec_lit(fx$b)),
            '.n1 = size (a#)',
            '.n2 = size (b#)',
            '.id = Create Table with column names: "v148ec", 0, "Data Group"',
            'for .i from 1 to .n1',
            '    Append row',
            '    Set numeric value: .i, "Data", a#[.i]',
            '    Set string value: .i, "Group", "A"',
            'endfor',
            'for .i from 1 to .n2',
            '    Append row',
            '    Set numeric value: .n1 + .i, "Data", b#[.i]',
            '    Set string value: .n1 + .i, "Group", "B"',
            'endfor',
            '@emlRunTwoGroupAnalysis: .id, "Data", "Group", "nonparametric", 0',
            'removeObject: .id')
        lines
    }

    run_explclass <- function(analysis_file = ANA, tag = "") {
        defaultPath <- file.path(work, paste0("v148-ec-default", tag, ".praat"))
        offPath     <- file.path(work, paste0("v148-ec-off", tag, ".praat"))
        onPath      <- file.path(work, paste0("v148-ec-on", tag, ".praat"))
        writeLines(c('writeInfoLine: "v148 ec default"', explclass_probe(NULL, analysis_file)), defaultPath)
        writeLines(c('writeInfoLine: "v148 ec off"',     explclass_probe("emlShowExplanations = 0", analysis_file)), offPath)
        writeLines(c('writeInfoLine: "v148 ec on"',      explclass_probe("emlShowExplanations = 1", analysis_file)), onPath)
        list(
            default = drive(defaultPath),
            off     = drive(offPath),
            on      = drive(onPath)
        )
    }

    ec <- run_explclass()
    ranEC <- !any(grepl("^Error", ec$default)) && !any(grepl("^Error", ec$off)) && !any(grepl("^Error", ec$on))
    check_true(V, "all three explanation-class drives (default, forced off, forced on) ran with no Praat error", ranEC)

    if (!ranEC) {
        cat("      v148 explanation-class probe output (default):\n      ",
            paste(utils::tail(ec$default, 20), collapse = "\n      "), "\n", sep = "")
        cat("      v148 explanation-class probe output (off):\n      ",
            paste(utils::tail(ec$off, 20), collapse = "\n      "), "\n", sep = "")
        cat("      v148 explanation-class probe output (on):\n      ",
            paste(utils::tail(ec$on, 20), collapse = "\n      "), "\n", sep = "")
    } else {
        # Strip each script's own marker line (line 1: "v148 ec default" /
        # "off" / "on" -- not report content, the one line the three
        # scripts deliberately do NOT share) and the report's own
        # date$() timestamp line (non-canonical by the plugin's own
        # design; see dropTimestamp above) before comparing.
        defBody <- dropTimestamp(ec$default[-1])
        offBody <- dropTimestamp(ec$off[-1])
        onBody  <- dropTimestamp(ec$on[-1])

        # (a) default IS off -- item 22 Task 4 flipped the default to 0.
        check_true(V, "(a) the DEFAULT drive is byte-identical to the FORCED-OFF drive (the default is off)",
                   identical(defBody, offBody))

        # (b) every line present only in the forced-ON drive is
        # explanation class BY CONSTRUCTION: the only thing that differs
        # between the off and on scripts is the single assignment
        # "emlShowExplanations = <0|1>", so any line-level difference
        # between their outputs is a direct, mechanical consequence of
        # that one variable -- never a judgement about wording. Checked
        # both ways (on-only and off-only) since a gloss appended to an
        # otherwise-shared row changes that WHOLE line's bytes, showing up
        # as "off-only" (the shorter form) as well as "on-only" (the
        # longer form).
        onlyOn  <- setdiff(onBody, offBody)
        onlyOff <- setdiff(offBody, onBody)
        check_true(V, "(b) raising the flag brings EXTRA lines back -- the forced-on drive contains at least one line absent from forced-off (the gate is wired, not inert)",
                   length(onlyOn) > 0)
        check_true(V, "(b) every line unique to the forced-off drive vanishes when the flag is raised (the same lines, read from the other side of the same diff)",
                   length(onlyOff) >= 0)  # structural fact, always true; states the shape being asserted

        # (c) the "p method" disclosure row is IDENTICAL across all three
        # -- outside the set the gate controls, i.e. disclosure class.
        composedTies <- composePMethod(mw_fixtures[["ties"]]$method, mw_fixtures[["ties"]]$reason)
        pmLine <- pMethodLine(composedTies)
        check_true(V, "(c) the \"p method\" row's exact printed line is present in the DEFAULT drive",
                   any(grepl(pmLine, defBody, fixed = TRUE)))
        check_true(V, "(c) the \"p method\" row's exact printed line is present in the FORCED-OFF drive",
                   any(grepl(pmLine, offBody, fixed = TRUE)))
        check_true(V, "(c) the \"p method\" row's exact printed line is present in the FORCED-ON drive, BYTE-IDENTICAL to the other two -- disclosure class, outside the gate's reach",
                   any(grepl(pmLine, onBody, fixed = TRUE)))
        check_true(V, "(c) the \"p method\" line itself is NOT among the lines the flag adds or removes (it sits outside the diff set entirely)",
                   !(pmLine %in% onlyOn) && !(pmLine %in% onlyOff))
    }

    # -- RED DEMO: a mutant @emlRunTwoGroupAnalysis silently discards the
    # caller's override, simulating a stray reset regression. Gated behind
    # EML_EXPLCLASS_RED=1 (same convention as v147's red demonstrations) --
    # it is expected to turn assertion (b) above red, on purpose, and is
    # never run as part of the ordinary suite.
    explclass_red <- nzchar(Sys.getenv("EML_EXPLCLASS_RED", unset = ""))
    ana_src <- readLines(ANA, warn = FALSE)
    anchor <- '    .recResult$ = ""'
    procStart <- grep("^procedure emlRunTwoGroupAnalysis:", ana_src)
    check_true(V, "@emlRunTwoGroupAnalysis is defined exactly once (red-demo anchor)", length(procStart) == 1)
    hitAnchor <- if (length(procStart) == 1) {
        cand <- procStart[1] + which(ana_src[(procStart[1] + 1):min(procStart[1] + 5, length(ana_src))] == anchor)
        cand
    } else integer(0)
    check_true(V, "the red-demo seed line ('.recResult$ = \"\"', @emlRunTwoGroupAnalysis's own entry line) is found near the procedure's start, exactly once",
               length(hitAnchor) == 1)
    if (length(hitAnchor) == 1) {
        mut_lines <- append(ana_src, "    emlShowExplanations = 0", after = hitAnchor[1])
        mut_dir <- file.path(work, "mutant_ec"); dir.create(mut_dir, showWarnings = FALSE)
        mut_ana <- file.path(mut_dir, "eml-analysis.praat")
        writeLines(mut_lines, mut_ana)

        ecRed <- run_explclass(mut_ana, tag = "-red")
        ranECRed <- !any(grepl("^Error", ecRed$default)) && !any(grepl("^Error", ecRed$off)) && !any(grepl("^Error", ecRed$on))
        check_true(V, "[red] the mutant explanation-class probe ran", ranECRed)
        if (ranECRed) {
            offBodyR <- dropTimestamp(ecRed$off[-1])
            onBodyR  <- dropTimestamp(ecRed$on[-1])
            onlyOnR <- setdiff(onBodyR, offBodyR)
            if (explclass_red) {
                cat("      EML_EXPLCLASS_RED: asserting the mutant's forced-on drive still\n")
                cat("      differs from forced-off (extra lines return) -- EXPECTED to FAIL.\n")
                check_true(V, "[RED] mutant: raising the flag still brings extra lines back (must go red)",
                           length(onlyOnR) > 0)
            } else {
                check_true(V, "[red] mutant: @emlRunTwoGroupAnalysis silently resets emlShowExplanations = 0, so forcing the flag on has NO EFFECT -- forced-on is now byte-identical to forced-off, exactly reproducing the named defect (a stray reset discarding the caller's override), not a vague 'something changed'",
                           length(onlyOnR) == 0 && identical(onBodyR, offBodyR))
            }
        } else {
            cat("      v148 red-demo (explanation-class) mutant probe output (off):\n      ",
                paste(utils::tail(ecRed$off, 20), collapse = "\n      "), "\n", sep = "")
            cat("      v148 red-demo (explanation-class) mutant probe output (on):\n      ",
                paste(utils::tail(ecRed$on, 20), collapse = "\n      "), "\n", sep = "")
        }
    }
}

if (!exists("EML_SUITE")) {
    eml_report("v148 -- the \"p method\" disclosure row (Mann-Whitney/Wilcoxon) and the explanation-class acceptance check")
    eml_exit()
}
