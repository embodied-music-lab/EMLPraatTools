# ===========================================================================
# v129 -- @emlSurveyValidateDeclaration conformance vs the plan's five
#         refusals (survey-stats lane, Stage 1)
# ===========================================================================
# Drives @emlSurveyValidateDeclaration (plugin/stats/eml-psychometrics.praat)
# LIVE on the committed declaration fixtures (evidence/csv/
# lane_survey_declared_{data,scales,items}.csv) and on five seeded defects,
# each DERIVED from those same committed files into tempdir() -- no broken
# fixture is committed to evidence/csv/.
#
# Asserted throughout: the refusal CODE (0-5) and the NAMED item, scale, or
# respondent row the refusal implicates. Never the sentence text -- the
# language section of SURVEY_MODULE_PLAN_2026-08-25.md is not yet approved
# by Ian and the wording will change; a check pinned to it would break on
# every wording edit for a reason that has nothing to do with correctness.
# The only thing asserted about .error$ / .remedy$ text is that .error$ is
# empty exactly when .refusal is 0, and non-empty otherwise (the contract's
# shape, not its words).
#
# A PRAAT CSV QUIRK, now resolved at the read path: "Read Table from
# comma-separated file..." does NOT strip quote characters from a quoted
# HEADER field, even though it DOES strip them from quoted DATA cells. The
# committed lane_survey_declared_data.csv has every column name quoted
# (R's write.csv default: "Q1","Q2",...), so Praat reads its column labels
# as the literal 4-character string "Q1" (quotes included) and "Get
# column index: "Q1"" returns 0 against it -- unless something strips the
# quotes first. @emlSurveyValidateDeclaration (plugin/stats/
# eml-psychometrics.praat) now calls the plugin's existing
# @emlStripHeaderQuotes (plugin/stats/eml-extract.praat) on all three
# declaration tables before any column lookup, so this driver needs no
# workaround any more: every "clean declaration" leg below drives the
# THREE COMMITTED FILES DIRECTLY, unmodified, byte for byte -- including
# the quoted header on lane_survey_declared_data.csv exactly as committed.
# Only the five seeded-defect fixtures (and the negative-control mutants)
# derive scratch copies in tempdir(), and only where the defect itself
# requires editing a field. Verified directly against Praat 6.6.30:
#   col1label|"Q1"        <- quoted header, read as-is by Table object...
#   colindexQ1|0           <- ...so "Get column index: "Q1"" cannot find it
# which is exactly why the stripping call has to run before that lookup,
# and section 6 below proves it is load-bearing by removing it and
# watching the same committed file refuse.
#
# Negative control: a scratch copy of the module with the range check's
# declared-range read (.sMin = .scaleMin[.s] / .sMax = .scaleMax[.s])
# replaced by the column's OBSERVED min/max, scanned by hand skipping any
# undefined cell (NOT "Get minimum:"/"Get maximum:" -- those two halt
# outright, rather than compute, on a column holding a missing cell,
# verified directly against Praat 6.6.30 against Q2, which legitimately
# has one in the committed fixture; a real "observed range" implementation
# has to skip missing values the same way this mutation does, so the
# mutation is what a builder would plausibly write, not a strawman chosen
# to dodge the crash). It is driven on a fresh out-of-range fixture (Q1,
# declared range 1-5, planted at 99). Because the observed min/max is
# scanned FROM the very column the planted value sits in, the planted
# value can never fall outside its own column's observed range no matter
# how extreme it is -- the mutant refuses nothing. The run asserts the
# mutant's refusal DIFFERS from the correct refusal (2). Set EML_LANE_RED=1
# to instead run the standard "refusal fires" check against the defective
# build and watch it go red (exit status 1).
#
# NOT registered in validate/run_all.R: this is lane work; the merging
# session registers it after the release round closes.
# ===========================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

red_mode <- nzchar(Sys.getenv("EML_LANE_RED", unset = ""))

plug <- Sys.getenv("EML_PLUGIN_DIR", unset = "")
if (!nzchar(plug)) plug <- repo_path("plugin")

# ---------------------------------------------------------------------------
# 0. THE BINARY -- same floor and the same discovery as v90/v93
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

if (!canDrive) {
    cat(paste0("      SKIP: v129 needs Praat >= 6.6.30 to drive the module;\n",
               "            found ", if (is.na(pv)) "none" else pv, ".\n"))
    check_true("v129",
               sprintf("a Praat at or above the plugin's floor is available (found %s)",
                       if (is.na(pv)) "none" else pv),
               FALSE)
} else {

    # -------------------------------------------------------------------
    # 1. Sandbox: scratch outside the tree being measured
    # -------------------------------------------------------------------
    work <- file.path(tempdir(), "v129")
    unlink(work, recursive = TRUE)
    dir.create(file.path(work, "scripts"), showWarnings = FALSE, recursive = TRUE)
    dir.create(file.path(work, "csv"), showWarnings = FALSE, recursive = TRUE)
    prefs <- file.path(work, "prefs")
    dir.create(prefs, showWarnings = FALSE)
    unlink(file.path(prefs, c("pid", "message")))
    tgt <- file.path(work, "stats")
    if (!file.exists(tgt)) file.symlink(normalizePath(file.path(plug, "stats")), tgt)

    csvdir <- repo_path("evidence", "csv")

    # THE COMMITTED PATHS -- driven directly, never copied, for every leg
    # that does not need a planted defect.
    committed_data_path   <- file.path(csvdir, "lane_survey_declared_data.csv")
    committed_scales_path <- file.path(csvdir, "lane_survey_declared_scales.csv")
    committed_items_path  <- file.path(csvdir, "lane_survey_declared_items.csv")

    # -- Read the three committed files as plain text lines too, so a
    # defect fixture can be seeded by editing LINES and writing a NEW file
    # to tempdir(), never by editing the committed file itself. These are
    # read verbatim -- no de-quoting -- because the module under test now
    # does its own quote-stripping; a defect fixture derived from the
    # header-quoted committed data.csv exercises the same header the real
    # file ships with.
    clean_data_lines   <- readLines(committed_data_path, warn = FALSE)
    clean_scales_lines <- readLines(committed_scales_path, warn = FALSE)
    clean_items_lines  <- readLines(committed_items_path, warn = FALSE)

    # Column lookup for editing a data line by NAME, tolerant of a quoted
    # header cell -- this is bookkeeping inside the R driver only, not a
    # stand-in for Praat's own (now-fixed) header handling.
    header_index <- function(lines, col_name) {
        hdr <- strsplit(lines[1], ",", fixed = TRUE)[[1]]
        which(gsub('"', "", hdr) == col_name)
    }

    write_csv_lines <- function(lines, name) {
        p <- file.path(work, "csv", name)
        writeLines(lines, p)
        p
    }

    # -------------------------------------------------------------------
    # 2. The driver: writes a probe script reading three CSV paths as
    #    Tables and calling @emlSurveyValidateDeclaration once.
    # -------------------------------------------------------------------
    drive_validate <- function(stats_dir_rel, data_path, scales_path, items_path, tag) {
        probe <- file.path(work, "scripts", paste0("v129-", tag, ".praat"))
        esc <- function(p) gsub('"', '""', p)
        writeLines(c(
            # eml-psychometrics.praat's own header (Dependencies) now says
            # @emlSurveyValidateDeclaration requires @emlStripHeaderQuotes
            # from eml-extract.praat and must be included after it -- the
            # same order every real barrel already uses (eml-record.praat's
            # generated barrel, setup.praat's module list).
            paste0("include ../", stats_dir_rel, "/eml-extract.praat"),
            paste0("include ../", stats_dir_rel, "/eml-psychometrics.praat"),
            "",
            sprintf('dataT = Read Table from comma-separated file: "%s"', esc(data_path)),
            sprintf('scalesT = Read Table from comma-separated file: "%s"', esc(scales_path)),
            sprintf('itemsT = Read Table from comma-separated file: "%s"', esc(items_path)),
            "",
            "@emlSurveyValidateDeclaration: dataT, scalesT, itemsT",
            'writeInfoLine: "v129"',
            'appendInfoLine: "res|", emlSurveyValidateDeclaration.refusal, "|",',
            '... emlSurveyValidateDeclaration.badItem$, "|",',
            '... emlSurveyValidateDeclaration.badScale$, "|",',
            '... emlSurveyValidateDeclaration.badRow, "|",',
            '... emlSurveyValidateDeclaration.badValue, "|",',
            '... emlSurveyValidateDeclaration.badMin, "|",',
            '... emlSurveyValidateDeclaration.badMax, "|",',
            '... emlSurveyValidateDeclaration.scaleItemCount, "|",',
            '... emlSurveyValidateDeclaration.badRole$, "|",',
            '... emlSurveyValidateDeclaration.badDirection$, "|",',
            '... length (emlSurveyValidateDeclaration.error$), "|",',
            '... length (emlSurveyValidateDeclaration.remedy$), "|",',
            # Fields 13-19: refusals 6-10 (v129 extension). Appended after
            # the original 12 rather than inserted among them, so every
            # existing str_()/num_() index above keeps meaning exactly what
            # it meant before this extension.
            '... emlSurveyValidateDeclaration.badReversedValue, "|",',
            '... emlSurveyValidateDeclaration.badItemRow, "|",',
            '... emlSurveyValidateDeclaration.badScaleRow, "|",',
            '... emlSurveyValidateDeclaration.badTypeValue$, "|",',
            '... emlSurveyValidateDeclaration.badCellText$, "|",',
            '... emlSurveyValidateDeclaration.scaleIsKR20 [1], "|",',
            '... emlSurveyValidateDeclaration.scaleIsKR20 [3]'),
            probe)
        suppressWarnings(system2("env",
            c("-u", "DISPLAY", shQuote(praat),
              shQuote(paste0("--pref-dir=", prefs)), "--run", shQuote(probe)),
            stdout = TRUE, stderr = TRUE))
    }

    fld <- function(out, tag) {
        p <- sprintf("^%s\\|", tag)
        h <- grep(p, out, value = TRUE)
        if (!length(h)) return(character(0))
        strsplit(sub(p, "", h[1]), "|", fixed = TRUE)[[1]]
    }
    str_ <- function(out, tag, i) {
        f <- fld(out, tag)
        if (length(f) < i) return(NA_character_)
        f[i]
    }
    num_ <- function(out, tag, i) {
        v <- str_(out, tag, i)
        if (is.na(v) || identical(v, "--undefined--")) return(NA_real_)
        suppressWarnings(as.numeric(v))
    }
    ran_ok <- function(out) !any(grepl("^Error", out)) && length(fld(out, "res")) >= 19

    # -------------------------------------------------------------------
    # 3. THE CLEAN DECLARATION -- driven DIRECTLY against the three
    #    committed files, unmodified, byte for byte. This is the leg
    #    whose earlier absence hid the header-quoting defect: an older
    #    version of this driver de-quoted the data header into a tempdir
    #    copy before every leg, including this one, and so reported 38/38
    #    green against a file that was not the one actually committed.
    #    First, a canary: confirm the committed file this leg is about to
    #    drive still HAS its quoted header, so a future re-export of the
    #    fixture that happened to drop the quoting could not silently turn
    #    this into a leg that tests nothing.
    # -------------------------------------------------------------------
    check_true("v129",
        "sanity: the committed data CSV's header row is still quoted (so this leg exercises the real header-quoting defect, not an accidental non-case)",
        grepl('^"Q1"', clean_data_lines[1]))

    out_clean <- drive_validate("stats", committed_data_path, committed_scales_path,
                                committed_items_path, "clean")
    check_true("v129", "the clean-declaration probe ran, against the committed files unmodified", ran_ok(out_clean))
    if (!ran_ok(out_clean)) {
        cat(sprintf("      v129 clean probe output: %s\n",
                    paste(utils::tail(out_clean, 10), collapse = " / ")))
    } else {
        check("v129", "clean declaration on the committed (quoted-header) files: refusal code is 0",
              num_(out_clean, "res", 1), 0, tol = 0)
        check("v129", "clean declaration on the committed files: error length is 0 (error$ empty)",
              num_(out_clean, "res", 11), 0, tol = 0)
        check("v129", "clean declaration on the committed files: remedy length is 0 (remedy$ empty)",
              num_(out_clean, "res", 12), 0, tol = 0)
        # The KR-20 naming condition (v129 extension, refusals 6-10 work):
        # "declared range spans exactly two values, max = min + 1",
        # exposed once by the module rather than re-derived here. Confidence
        # (declared 1-5) is not two-valued; Knowledge (declared 0-1, the
        # committed fixture's own binary-range subscale) is.
        check("v129", "scaleIsKR20[Confidence] is 0 (declared range 1-5 is not two-valued)",
              num_(out_clean, "res", 18), 0, tol = 0)
        check("v129", "scaleIsKR20[Knowledge] is 1 (declared range 0-1 spans exactly two values)",
              num_(out_clean, "res", 19), 1, tol = 0)
    }

    # -------------------------------------------------------------------
    # 3b. MISSING CELL DOES NOT TRIGGER REFUSAL 2 -- its own leg.
    # The committed fixture already carries three deliberate missing
    # cells, each inside its subscale's declared range (row 5/Q6, row
    # 11/Q2, row 18/R2). This is not incidental to the clean-declaration
    # check above: it is the specific claim that a MISSING cell is exempt
    # from the out-of-range refusal, asserted on its own rather than
    # folded silently into "the clean run refused nothing".
    # -------------------------------------------------------------------
    miss_locations <- list(c(row = 5, col = "Q6"), c(row = 11, col = "Q2"),
                          c(row = 18, col = "R2"))
    miss_confirmed <- vapply(miss_locations, function(loc) {
        i <- as.integer(loc[["row"]]) + 1L  # +1 for the header line
        raw <- strsplit(clean_data_lines[i], ",", fixed = TRUE)[[1]]
        ci <- header_index(clean_data_lines, loc[["col"]])
        length(ci) == 1 && (length(raw) < ci || !nzchar(trimws(raw[ci])))
    }, logical(1))
    check_true("v129", "the three planted missing cells (row5/Q6, row11/Q2, row18/R2) are genuinely blank in the committed fixture",
               all(miss_confirmed))
    check_true("v129", "missing cells did not make refusal 2 fire on the clean run (refusal is 0, not 2)",
               ran_ok(out_clean) && num_(out_clean, "res", 1) == 0)

    # -------------------------------------------------------------------
    # 4. FIVE SEEDED-DEFECT FIXTURES, each derived from the clean lines
    #    above and written fresh into tempdir(). One mutation per fixture.
    # -------------------------------------------------------------------
    edit_field <- function(lines, row_1based, col_name, new_value) {
        ci <- header_index(lines, col_name)
        stopifnot(length(ci) == 1)
        cells <- strsplit(lines[row_1based + 1L], ",", fixed = TRUE)[[1]]
        cells[ci] <- new_value
        lines[row_1based + 1L] <- paste(cells, collapse = ",")
        lines
    }

    results <- list()

    # --- Defect 1: item names a column the data table lacks ------------
    items1 <- clean_items_lines
    items1[grepl("^Q1,", items1)] <- sub("^Q1,", "Q1x,", items1[grepl("^Q1,", items1)])
    p1 <- write_csv_lines(items1, "d1_items.csv")
    out1 <- drive_validate("stats", committed_data_path, committed_scales_path, p1, "d1")
    results$d1 <- out1
    check_true("v129", "[refusal 1] probe ran", ran_ok(out1))
    if (ran_ok(out1)) {
        check("v129", "[refusal 1] code is 1 (item names a column the data lacks)",
              num_(out1, "res", 1), 1, tol = 0)
        check_true("v129", "[refusal 1] badItem is the renamed item \"Q1x\"",
                   identical(str_(out1, "res", 2), "Q1x"))
    }

    # --- Defect 2: a value outside its subscale's declared range -------
    # Row 5, item Q2 (role Confidence, declared range 1-5): planted 9.
    # Row 5 is chosen because its ONLY existing blank is Q6 (Anxiety), so
    # this does not collide with a planted missing cell.
    data2 <- edit_field(clean_data_lines, 5, "Q2", "9")
    p2d <- write_csv_lines(data2, "d2_data.csv")
    out2 <- drive_validate("stats", p2d, committed_scales_path, committed_items_path, "d2")
    results$d2 <- out2
    check_true("v129", "[refusal 2] probe ran", ran_ok(out2))
    if (ran_ok(out2)) {
        check("v129", "[refusal 2] code is 2 (value outside declared range)",
              num_(out2, "res", 1), 2, tol = 0)
        check("v129", "[refusal 2] badRow is 5", num_(out2, "res", 4), 5, tol = 0)
        check_true("v129", "[refusal 2] badItem is \"Q2\"",
                   identical(str_(out2, "res", 2), "Q2"))
        check_true("v129", "[refusal 2] badScale is \"Confidence\"",
                   identical(str_(out2, "res", 3), "Confidence"))
        check("v129", "[refusal 2] badValue is 9", num_(out2, "res", 5), 9, tol = 0)
        check("v129", "[refusal 2] badMin is 1", num_(out2, "res", 6), 1, tol = 0)
        check("v129", "[refusal 2] badMax is 5", num_(out2, "res", 7), 5, tol = 0)
    }

    # --- Defect 3: a subscale with fewer than two items -----------------
    # Knowledge's B2 and B3 reassigned to "ignore", leaving B1 alone.
    items3 <- clean_items_lines
    items3[grepl("^B2,", items3)] <- "B2,ignore,0"
    items3[grepl("^B3,", items3)] <- "B3,ignore,0"
    p3 <- write_csv_lines(items3, "d3_items.csv")
    out3 <- drive_validate("stats", committed_data_path, committed_scales_path, p3, "d3")
    results$d3 <- out3
    check_true("v129", "[refusal 3] probe ran", ran_ok(out3))
    if (ran_ok(out3)) {
        check("v129", "[refusal 3] code is 3 (subscale with fewer than two items)",
              num_(out3, "res", 1), 3, tol = 0)
        check_true("v129", "[refusal 3] badScale is \"Knowledge\"",
                   identical(str_(out3, "res", 3), "Knowledge"))
        check("v129", "[refusal 3] scaleItemCount is 1", num_(out3, "res", 8), 1, tol = 0)
    }

    # --- Defect 4: reversed set on a grouping/ignore column -------------
    items4 <- clean_items_lines
    items4[grepl("^Voice,", items4)] <- "Voice,grouping,1"
    p4 <- write_csv_lines(items4, "d4_items.csv")
    out4 <- drive_validate("stats", committed_data_path, committed_scales_path, p4, "d4")
    results$d4 <- out4
    check_true("v129", "[refusal 4] probe ran", ran_ok(out4))
    if (ran_ok(out4)) {
        check("v129", "[refusal 4] code is 4 (reversed set on grouping/ignore)",
              num_(out4, "res", 1), 4, tol = 0)
        check_true("v129", "[refusal 4] badItem is \"Voice\"",
                   identical(str_(out4, "res", 2), "Voice"))
        check_true("v129", "[refusal 4] badRole is \"grouping\"",
                   identical(str_(out4, "res", 9), "grouping"))
    }

    # --- Defect 5, direction A: item names a scale the scales file lacks
    items5a <- clean_items_lines
    items5a[grepl("^Q1,", items5a)] <- "Q1,Confidenc,0"
    p5a <- write_csv_lines(items5a, "d5a_items.csv")
    out5a <- drive_validate("stats", committed_data_path, committed_scales_path, p5a, "d5a")
    results$d5a <- out5a
    check_true("v129", "[refusal 5A] probe ran", ran_ok(out5a))
    if (ran_ok(out5a)) {
        check("v129", "[refusal 5A] code is 5 (item names an unknown scale)",
              num_(out5a, "res", 1), 5, tol = 0)
        check_true("v129", "[refusal 5A] badItem is \"Q1\"",
                   identical(str_(out5a, "res", 2), "Q1"))
        check_true("v129", "[refusal 5A] badScale is \"Confidenc\"",
                   identical(str_(out5a, "res", 3), "Confidenc"))
        check_true("v129", "[refusal 5A] badDirection is \"item_unknown_scale\"",
                   identical(str_(out5a, "res", 10), "item_unknown_scale"))
    }

    # --- Defect 5, direction B: a declared scale no item uses -----------
    scales5b <- c(clean_scales_lines, "Motivation,1,5,ordinal")
    p5b <- write_csv_lines(scales5b, "d5b_scales.csv")
    out5b <- drive_validate("stats", committed_data_path, p5b, committed_items_path, "d5b")
    results$d5b <- out5b
    check_true("v129", "[refusal 5B] probe ran", ran_ok(out5b))
    if (ran_ok(out5b)) {
        check("v129", "[refusal 5B] code is 5 (a declared scale no item uses)",
              num_(out5b, "res", 1), 5, tol = 0)
        check_true("v129", "[refusal 5B] badScale is \"Motivation\"",
                   identical(str_(out5b, "res", 3), "Motivation"))
        check_true("v129", "[refusal 5B] badDirection is \"scale_unused\"",
                   identical(str_(out5b, "res", 10), "scale_unused"))
    }

    # -------------------------------------------------------------------
    # 4b. FIVE MORE SEEDED-DEFECT FIXTURES -- refusals 6-10, added by the
    #     verification pass (6, 7, 8, 9 probed as holes; 10 a contract
    #     repair to refusal 2, flagged as such). Same style as section 4:
    #     one mutation, derived from the clean committed lines into
    #     tempdir(), never touching the committed files themselves.
    # -------------------------------------------------------------------

    # --- Defect 6: reversed holds a value other than 0 or 1 -------------
    # Q3 is the fixture's own reverse-worded Confidence item (reversed=1
    # in the committed file); planting 2 in its place is the exact probe
    # Ian approved (Confidence's alpha would silently drop from 0.900 to
    # -0.177 with Q3 forward-scored and no disclosure, if this refusal did
    # not exist).
    items6 <- edit_field(clean_items_lines, 3, "reversed", "2")
    p6 <- write_csv_lines(items6, "d6_items.csv")
    out6 <- drive_validate("stats", committed_data_path, committed_scales_path, p6, "d6")
    results$d6 <- out6
    check_true("v129", "[refusal 6] probe ran", ran_ok(out6))
    if (ran_ok(out6)) {
        check("v129", "[refusal 6] code is 6 (reversed is not 0 or 1)",
              num_(out6, "res", 1), 6, tol = 0)
        check_true("v129", "[refusal 6] badItem is \"Q3\"",
                   identical(str_(out6, "res", 2), "Q3"))
        check("v129", "[refusal 6] badReversedValue is 2",
              num_(out6, "res", 13), 2, tol = 0)
    }

    # --- Defect 7: an item name declared more than once -----------------
    # Q1's row duplicated verbatim, immediately after itself.
    q1_row <- clean_items_lines[grepl("^Q1,", clean_items_lines)]
    stopifnot(length(q1_row) == 1)
    items7 <- append(clean_items_lines, q1_row,
                     after = which(clean_items_lines == q1_row))
    p7 <- write_csv_lines(items7, "d7_items.csv")
    out7 <- drive_validate("stats", committed_data_path, committed_scales_path, p7, "d7")
    results$d7 <- out7
    check_true("v129", "[refusal 7] probe ran", ran_ok(out7))
    if (ran_ok(out7)) {
        check("v129", "[refusal 7] code is 7 (item name declared more than once)",
              num_(out7, "res", 1), 7, tol = 0)
        check_true("v129", "[refusal 7] badItem is \"Q1\"",
                   identical(str_(out7, "res", 2), "Q1"))
        check("v129", "[refusal 7] badItemRow is 2 (the second, duplicated declaration)",
              num_(out7, "res", 14), 2, tol = 0)
    }

    # --- Defect 8: an item resolved to a subscale has a non-numeric data
    #     column ---------------------------------------------------------
    # Voice reassigned from "grouping" (where its text values "Soprano" /
    # "Alto" / ... are legitimate) to "Confidence" -- Ian's approved probe.
    items8 <- clean_items_lines
    items8[grepl("^Voice,", items8)] <- "Voice,Confidence,0"
    p8 <- write_csv_lines(items8, "d8_items.csv")
    out8 <- drive_validate("stats", committed_data_path, committed_scales_path, p8, "d8")
    results$d8 <- out8
    check_true("v129", "[refusal 8] probe ran", ran_ok(out8))
    if (ran_ok(out8)) {
        check("v129", "[refusal 8] code is 8 (item resolved to a subscale is non-numeric)",
              num_(out8, "res", 1), 8, tol = 0)
        check_true("v129", "[refusal 8] badItem is \"Voice\"",
                   identical(str_(out8, "res", 2), "Voice"))
        check_true("v129", "[refusal 8] badScale is \"Confidence\"",
                   identical(str_(out8, "res", 3), "Confidence"))
        check("v129", "[refusal 8] badRow is 1 (first respondent, \"Soprano\")",
              num_(out8, "res", 4), 1, tol = 0)
        check_true("v129", "[refusal 8] badCellText is \"Soprano\"",
                   identical(str_(out8, "res", 17), "Soprano"))
    }

    # --- Defect 9: a scale type that is neither ordinal nor continuous --
    scales9 <- clean_scales_lines
    scales9[grepl("^Confidence,", scales9)] <- "Confidence,1,5,banana"
    p9 <- write_csv_lines(scales9, "d9_scales.csv")
    out9 <- drive_validate("stats", committed_data_path, p9, committed_items_path, "d9")
    results$d9 <- out9
    check_true("v129", "[refusal 9] probe ran", ran_ok(out9))
    if (ran_ok(out9)) {
        check("v129", "[refusal 9] code is 9 (scale type is neither ordinal nor continuous)",
              num_(out9, "res", 1), 9, tol = 0)
        check_true("v129", "[refusal 9] badScale is \"Confidence\"",
                   identical(str_(out9, "res", 3), "Confidence"))
        check_true("v129", "[refusal 9] badTypeValue is \"banana\"",
                   identical(str_(out9, "res", 16), "banana"))
    }

    # --- Defect 10 [CONTRACT REPAIR -- Ian's to veto]: a declared minimum
    #     not below its declared maximum -----------------------------------
    # Confidence's endpoints transposed. Before this refusal existed, this
    # fixture reached refusal 2 instead, naming a RESPONDENT ROW with a
    # remedy to check that row's data -- the exact misdirection this
    # refusal exists to prevent.
    scales10 <- clean_scales_lines
    scales10[grepl("^Confidence,", scales10)] <- "Confidence,5,1,ordinal"
    p10 <- write_csv_lines(scales10, "d10_scales.csv")
    out10 <- drive_validate("stats", committed_data_path, p10, committed_items_path, "d10")
    results$d10 <- out10
    check_true("v129", "[refusal 10] probe ran", ran_ok(out10))
    if (ran_ok(out10)) {
        check("v129", "[refusal 10] code is 10 (declared min not below declared max), not 2 (was misreported as a bad respondent row before this repair)",
              num_(out10, "res", 1), 10, tol = 0)
        check_true("v129", "[refusal 10] badScale is \"Confidence\"",
                   identical(str_(out10, "res", 3), "Confidence"))
        check("v129", "[refusal 10] badMin is 5", num_(out10, "res", 6), 5, tol = 0)
        check("v129", "[refusal 10] badMax is 1", num_(out10, "res", 7), 1, tol = 0)
    }

    # -------------------------------------------------------------------
    # 5. NEGATIVE CONTROL -- range check seeded to compare against the
    #    OBSERVED range instead of the DECLARED one.
    # -------------------------------------------------------------------
    mut <- file.path(work, "mutant")
    dir.create(mut, showWarnings = FALSE)
    # The probe now includes eml-extract.praat before eml-psychometrics.praat
    # (the module's own Dependencies header), so every mutant directory needs
    # a real, unmutated eml-extract.praat sitting beside its one mutated file.
    file.symlink(normalizePath(file.path(plug, "stats", "eml-extract.praat")),
                 file.path(mut, "eml-extract.praat"))
    src <- readLines(file.path(plug, "stats", "eml-psychometrics.praat"))
    needle <- paste(
        "                .sMin = .scaleMin[.s]",
        "                .sMax = .scaleMax[.s]", sep = "\n")
    # A manual skip-undefined scan, not "Get minimum:"/"Get maximum:" --
    # those two halt outright on a column holding a missing cell (verified
    # directly against Praat 6.6.30: "cannot compute minimum of column"),
    # and Q2 legitimately has one missing cell in the committed fixture
    # regardless of which item is under test. Any real "observed range"
    # implementation has to skip missing values the same way, so this is
    # the mutation a builder would actually plausibly write, not a
    # strawman chosen to dodge the crash.
    replacement <- paste(
        "                .sMin = undefined",
        "                .sMax = undefined",
        "                selectObject: .dataTableId",
        "                for .obsRow from 1 to .nData",
        "                    .obsVal = Get value: .obsRow, .itemName$[.i]",
        "                    if .obsVal <> undefined",
        "                        if .sMin = undefined or .obsVal < .sMin",
        "                            .sMin = .obsVal",
        "                        endif",
        "                        if .sMax = undefined or .obsVal > .sMax",
        "                            .sMax = .obsVal",
        "                        endif",
        "                    endif",
        "                endfor", sep = "\n")
    src_txt <- paste(src, collapse = "\n")
    hit <- lengths(regmatches(src_txt, gregexpr(needle, src_txt, fixed = TRUE)))
    check_true("v129", "the negative-control seed site (declared-range read) exists in source",
               hit == 1)
    mut_txt <- sub(needle, replacement, src_txt, fixed = TRUE)
    mut_src <- strsplit(mut_txt, "\n", fixed = TRUE)[[1]]
    writeLines(mut_src, file.path(mut, "eml-psychometrics.praat"))
    tgt2 <- file.path(work, "mutant_link")
    if (!file.exists(tgt2)) file.symlink(mut, tgt2)

    # Drive the mutant on a FRESH out-of-range fixture, deliberately NOT
    # reusing p2d (row 5, Q2 = 9): "Get minimum:"/"Get maximum:" refuse to
    # run on a column that holds an undefined cell (verified directly
    # against Praat 6.6.30 -- it halts with "cannot compute minimum of
    # column", not a wrong number), and Q2 has one planted missing value
    # at row 11 (the declared fixture's own missing-cell case, section 3b
    # above). The mutant leg instead plants its out-of-range value in Q1
    # (Confidence, declared range 1-5, no missing cells anywhere in the
    # column): row 3, value 99. The observed maximum of the mutated Q1
    # column then includes the planted 99 itself, so the mutant can never
    # see 99 as out of range no matter how extreme it is.
    data_mut <- edit_field(clean_data_lines, 3, "Q1", "99")
    p_mut_data <- write_csv_lines(data_mut, "dmut_data.csv")

    out_correct_mut <- drive_validate("stats", p_mut_data, committed_scales_path,
                                      committed_items_path, "mutant-fixture-on-correct-code")
    check_true("v129", "the correct code refuses the mutant fixture's planted value (sanity: refusal 2, row 3, Q1)",
               ran_ok(out_correct_mut) && num_(out_correct_mut, "res", 1) == 2 &&
               num_(out_correct_mut, "res", 4) == 3 &&
               identical(str_(out_correct_mut, "res", 2), "Q1"))

    out_mut <- drive_validate("mutant_link", p_mut_data, committed_scales_path,
                              committed_items_path, "mutant")
    check_true("v129", "the mutant probe ran", ran_ok(out_mut))
    if (!ran_ok(out_mut)) {
        cat(sprintf("      v129 mutant probe output: %s\n",
                    paste(out_mut, collapse = " / ")))
    }
    mut_refusal <- if (ran_ok(out_mut)) num_(out_mut, "res", 1) else NA_real_

    if (red_mode) {
        cat("      EML_LANE_RED: running the standard 'refusal 2 fires' check\n")
        cat("      against the defective build -- the next check is EXPECTED\n")
        cat("      to FAIL.\n")
        check("v129", "[RED] refusal fires on the planted out-of-range value (must go red)",
              mut_refusal, 2, tol = 0)
    } else {
        check("v129",
              "seeded observed-range defect: mutant's refusal DIFFERS from the correct code 2 (proves the leg can fail)",
              mut_refusal, 2, tol = 0, expect = "differ")
    }

    # -------------------------------------------------------------------
    # 6. NEGATIVE CONTROL 2 -- the @emlStripHeaderQuotes calls removed.
    #    Proves section 3's clean result on the committed (quoted-header)
    #    files is not an accident of this driver: a scratch copy of the
    #    module with the three normalization calls deleted must REFUSE the
    #    very same committed data.csv that section 3 shows validating
    #    clean. Same mutant-copy pattern as section 5 (v90's model), and
    #    the same EML_LANE_RED=1 switch.
    # -------------------------------------------------------------------
    mut2 <- file.path(work, "mutant2")
    dir.create(mut2, showWarnings = FALSE)
    file.symlink(normalizePath(file.path(plug, "stats", "eml-extract.praat")),
                 file.path(mut2, "eml-extract.praat"))

    src2 <- readLines(file.path(plug, "stats", "eml-psychometrics.praat"))
    strip_needle <- paste(
        "    @emlStripHeaderQuotes: .itemsTableId",
        "    @emlStripHeaderQuotes: .scalesTableId",
        "    @emlStripHeaderQuotes: .dataTableId", sep = "\n")
    src2_txt <- paste(src2, collapse = "\n")
    hit2 <- lengths(regmatches(src2_txt, gregexpr(strip_needle, src2_txt, fixed = TRUE)))
    check_true("v129",
               "the @emlStripHeaderQuotes call site (three calls, one per declaration table) exists in source, exactly once",
               hit2 == 1)
    mut2_txt <- sub(strip_needle,
        "    ; [v129 mutant: @emlStripHeaderQuotes calls removed]",
        src2_txt, fixed = TRUE)
    mut2_src <- strsplit(mut2_txt, "\n", fixed = TRUE)[[1]]
    writeLines(mut2_src, file.path(mut2, "eml-psychometrics.praat"))
    tgt3 <- file.path(work, "mutant2_link")
    if (!file.exists(tgt3)) file.symlink(mut2, tgt3)

    # Drive the mutant on the COMMITTED (quoted-header) data CSV directly --
    # the exact file section 3 shows validating clean on the real code.
    out_mut2 <- drive_validate("mutant2_link", committed_data_path,
                               committed_scales_path, committed_items_path,
                               "mutant2")
    check_true("v129", "the strip-removed mutant probe ran", ran_ok(out_mut2))
    if (!ran_ok(out_mut2)) {
        cat(sprintf("      v129 mutant2 probe output: %s\n",
                    paste(out_mut2, collapse = " / ")))
    }
    mut2_refusal <- if (ran_ok(out_mut2)) num_(out_mut2, "res", 1) else NA_real_

    if (red_mode) {
        cat("      EML_LANE_RED: running the standard 'clean declaration' check\n")
        cat("      against the strip-removed build -- the next check is EXPECTED\n")
        cat("      to FAIL.\n")
        check("v129", "[RED] clean committed declaration refusal is 0 (must go red once the @emlStripHeaderQuotes calls are removed)",
              mut2_refusal, 0, tol = 0)
    } else {
        check("v129",
              "quote-stripping removed: mutant's refusal on the committed (quoted-header) files DIFFERS from the correct code 0 (proves the @emlStripHeaderQuotes calls are load-bearing)",
              mut2_refusal, 0, tol = 0, expect = "differ")
    }

    # -------------------------------------------------------------------
    # 7-11. NEGATIVE CONTROLS for refusals 6-10 -- one per new refusal,
    #    same mutant-copy pattern as sections 5 and 6 (v90's model): the
    #    ONE guard line that decides that refusal is neutered to "if 0 = 1"
    #    (never true, syntactically identical shape, so this is a targeted
    #    kill of the guard rather than a deletion that would also break
    #    parsing), driven on that refusal's OWN seeded-defect fixture from
    #    section 4b above, and the run asserts the mutant's refusal DIFFERS
    #    from the correct code -- or, under EML_LANE_RED=1, asserts the
    #    standard "refusal fires" check and watches it go red.
    # -------------------------------------------------------------------
    run_negative_control <- function(mut_name, needle, tag, defect_data,
                                     defect_scales, defect_items, correct_code) {
        mutdir <- file.path(work, mut_name)
        dir.create(mutdir, showWarnings = FALSE)
        file.symlink(normalizePath(file.path(plug, "stats", "eml-extract.praat")),
                     file.path(mutdir, "eml-extract.praat"))
        srcN <- readLines(file.path(plug, "stats", "eml-psychometrics.praat"))
        srcN_txt <- paste(srcN, collapse = "\n")
        hitN <- lengths(regmatches(srcN_txt, gregexpr(needle, srcN_txt, fixed = TRUE)))
        check_true("v129",
                   sprintf("[refusal %d] the guard line exists in source, exactly once (negative-control seed site)",
                           correct_code),
                   hitN == 1)
        replacement <- sub("^( *)if .*$", "\\1if 0 = 1", needle)
        mutN_txt <- sub(needle, replacement, srcN_txt, fixed = TRUE)
        mutN_src <- strsplit(mutN_txt, "\n", fixed = TRUE)[[1]]
        writeLines(mutN_src, file.path(mutdir, "eml-psychometrics.praat"))
        linkdir <- file.path(work, paste0(mut_name, "_link"))
        if (!file.exists(linkdir)) file.symlink(mutdir, linkdir)

        out_mutN <- drive_validate(paste0(mut_name, "_link"), defect_data,
                                   defect_scales, defect_items, tag)
        check_true("v129", sprintf("[refusal %d] neutered-guard mutant probe ran", correct_code),
                   ran_ok(out_mutN))
        if (!ran_ok(out_mutN)) {
            cat(sprintf("      v129 %s probe output: %s\n", tag,
                        paste(utils::tail(out_mutN, 10), collapse = " / ")))
        }
        mutN_refusal <- if (ran_ok(out_mutN)) num_(out_mutN, "res", 1) else NA_real_

        if (red_mode) {
            cat(sprintf("      EML_LANE_RED: running the standard 'refusal %d fires' check\n",
                        correct_code))
            cat("      against the neutered-guard build -- the next check is EXPECTED\n")
            cat("      to FAIL.\n")
            check("v129",
                  sprintf("[RED] refusal %d fires on its seeded defect (must go red once its guard is neutered)",
                          correct_code),
                  mutN_refusal, correct_code, tol = 0)
        } else {
            check("v129",
                  sprintf("[refusal %d] guard neutered: mutant's refusal on the seeded defect DIFFERS from the correct code %d (proves the guard is load-bearing)",
                          correct_code, correct_code),
                  mutN_refusal, correct_code, tol = 0, expect = "differ")
        }
    }

    # Refusal 6: reversed <> 0 and <> 1
    run_negative_control("mutant6",
        "        if .itemReversed[.i] <> .reversedValueFalse and .itemReversed[.i] <> .reversedValueTrue",
        "mutant6", committed_data_path, committed_scales_path, p6, 6)

    # Refusal 7: duplicate item name
    run_negative_control("mutant7",
        "            if .itemName$[.j] = .itemName$[.i]",
        "mutant7", committed_data_path, committed_scales_path, p7, 7)

    # Refusal 9: illegal scale type keyword
    run_negative_control("mutant9",
        "        if .scaleType$[.s] <> .typeKeywordOrdinal$ and .scaleType$[.s] <> .typeKeywordContinuous$",
        "mutant9", committed_data_path, p9, committed_items_path, 9)

    # Refusal 10: declared min not below declared max
    run_negative_control("mutant10",
        "        if .scaleMin[.s] >= .scaleMax[.s]",
        "mutant10", committed_data_path, p10, committed_items_path, 10)

    # Refusal 8: non-numeric data column on an item resolved to a subscale
    run_negative_control("mutant8",
        '            if emlAuditColumn.error$ = "" and emlAuditColumn.nUnreadable > 0',
        "mutant8", committed_data_path, committed_scales_path, p8, 8)
}

if (!exists("EML_SUITE")) { eml_report("v129 survey declaration conformance"); eml_exit() }
