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

    # Coverage accumulators (Finding 6 / eml_census spirit, section 18 below):
    # each accumulates the refusal CODE a leg actually exercised, recorded as
    # that leg runs -- never a separately hand-maintained list -- so the
    # coverage assertion at the end compares them against the set of codes
    # discovered by scanning @emlSurveyValidateDeclaration's own source.
    positive_leg_codes <- c()
    negative_control_codes <- c()

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
            # from eml-extract.praat and, as of V1.3, @emlRequireColumnPresent
            # / @emlRequireNumericColumn from eml-inferential.praat, in that
            # order -- the same order the real barrel already uses
            # (setup.praat's module list: eml-extract.praat, then
            # eml-inferential.praat, then eml-psychometrics.praat).
            paste0("include ../", stats_dir_rel, "/eml-extract.praat"),
            paste0("include ../", stats_dir_rel, "/eml-inferential.praat"),
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
            '... emlSurveyValidateDeclaration.scaleIsKR20 [3], "|",',
            # Fields 20-24: refusals 11-14 (v129 extension). Same rule:
            # appended after the previous 19 rather than inserted among
            # them. Fields 23-24 carry .error$/.remedy$ VERBATIM (every
            # other field before them is a length or a bare name/number,
            # never the sentence itself, per this file's own header on why
            # wording is never asserted) because the "no message prints
            # --undefined--" leg below needs the actual text to search, not
            # just its length. Neither field, nor any of the fixtures that
            # produce them, ever contains a "|" character, so the fixed
            # "|" splitter used throughout this file stays safe.
            '... emlSurveyValidateDeclaration.badColumn$, "|",',
            '... emlSurveyValidateDeclaration.badFile$, "|",',
            '... emlSurveyValidateDeclaration.badRawValue$, "|",',
            '... emlSurveyValidateDeclaration.error$, "|",',
            '... emlSurveyValidateDeclaration.remedy$, "|",',
            # Fields 25-29 [V1.7 cell ruling]: the disclosure branch's own
            # structured facts, appended after the previous 24 for the same
            # reason as every earlier extension -- nothing above is
            # renumbered. Field 29 carries .disclosure$ VERBATIM, same
            # rule as .error$/.remedy$ above (23-24): a length alone cannot
            # be searched for a specific promise (the "not yet included"
            # whitespace sentence a later leg checks for).
            '... emlSurveyValidateDeclaration.disclosureCount, "|",',
            '... emlSurveyValidateDeclaration.disclosureSpellingCount, "|",',
            '... emlSurveyValidateDeclaration.disclosureItemCount, "|",',
            '... length (emlSurveyValidateDeclaration.disclosure$), "|",',
            '... emlSurveyValidateDeclaration.disclosure$, "|",',
            # Field 30: a constant, non-empty sentinel, NOT a real output.
            # .error$/.remedy$ are BOTH "" on the clean run, and R's
            # strsplit(x, "|", fixed = TRUE) silently drops the trailing
            # field when the string being split ENDS in the delimiter --
            # verified directly: strsplit("a||", "|") returns two elements,
            # not three. Without this sentinel after them, the clean run's
            # line would end "...||" and field 24 (.remedy$) would vanish
            # from fld()'s result on exactly the run this file's own
            # section 3 depends on. The sentinel guarantees the line never
            # ends in the delimiter, so nothing after it is ever dropped.
            '... "END"',
            # [V1.7 cell ruling] a SEPARATE, GUARDED line for the two
            # per-entry disclosure arrays -- .disclosureSpelling$[1] and
            # .disclosureItem$[1] cannot be read unconditionally the way
            # every field above is (CLAUDE.md: reading an unassigned
            # indexed variable HALTS), so this reads element 1 of each
            # ONLY when its own count field (27/28 above) confirms at
            # least one entry exists. Absent from the output entirely on
            # every leg that plants no placeholder -- fld()/str_() below
            # already return NA for a tag that never printed, so no leg
            # needs to special-case its absence.
            'if emlSurveyValidateDeclaration.disclosureSpellingCount > 0',
            '    appendInfoLine: "resdisc|",',
            '    ... emlSurveyValidateDeclaration.disclosureSpelling$[1], "|",',
            '    ... emlSurveyValidateDeclaration.disclosureItem$[1], "|",',
            '    ... "END"',
            'endif'),
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
    ran_ok <- function(out) !any(grepl("^Error", out)) && length(fld(out, "res")) >= 24

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

    # add_data_column -- appends a NEW column to a data CSV's lines, quoted
    # header (matching the committed file's own R-write.csv-style quoting)
    # and one value per data row, defaulting every row to "" (blank, i.e.
    # missing -- exempt from every value-reading refusal) except the
    # 1-based rows named in row_values. Used by refusals 15 (a second
    # column sharing an EXISTING header) and 16 (a column no item
    # declares).
    add_data_column <- function(lines, header, row_values = list()) {
        out <- lines
        out[1] <- paste0(out[1], ',"', header, '"')
        n <- length(out) - 1L
        for (r in seq_len(n)) {
            v <- row_values[[as.character(r)]]
            if (is.null(v)) v <- ""
            out[r + 1L] <- paste0(out[r + 1L], ",", v)
        }
        out
    }

    results <- list()
    results$clean <- out_clean

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
        positive_leg_codes <- c(positive_leg_codes, 1)
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
        positive_leg_codes <- c(positive_leg_codes, 2)
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
        positive_leg_codes <- c(positive_leg_codes, 3)
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
        positive_leg_codes <- c(positive_leg_codes, 4)
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
        positive_leg_codes <- c(positive_leg_codes, 5)
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
        positive_leg_codes <- c(positive_leg_codes, 5)
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
        positive_leg_codes <- c(positive_leg_codes, 6)
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
        positive_leg_codes <- c(positive_leg_codes, 7)
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
        # [V1.7, cell ruling] LEG UPDATED: "Soprano" is not one of
        # @emlRepairClassify's recognised missing-value spellings, so this
        # leg now also asserts the disclosure path stayed silent for it.
        check("v129", "[cell ruling] \"Soprano\" cell: disclosureCount is 0 (not a recognised placeholder)",
              num_(out8, "res", 25), 0, tol = 0)
        positive_leg_codes <- c(positive_leg_codes, 8)
    }

    # --- Defect 8, ALL FIVE @emlAuditColumn KINDS, planted in turn on a
    #     scale item's data column (Finding 1's own closing instruction) --
    #     the fixture above (d8) exercises kind 3, unreadable. The other
    #     four:
    #       kind 1 (empty)       -- NOT a new fixture: the committed file's
    #                               own three planted blanks (row5/Q6,
    #                               row11/Q2, row18/R2) already prove, in
    #                               section 3b above, that this kind alone
    #                               does NOT fire this refusal, because it
    #                               is deliberately excluded (an empty
    #                               respondent cell is ordinary
    #                               missingness, not a wrong column).
    #                               Repeating that assertion here, by
    #                               refusal-8's own code, rather than
    #                               relying on 3b's assertion under a
    #                               different section number, is what
    #                               closes the "every kind" instruction
    #                               without contradicting Finding 1's own
    #                               required exemption.
    #       kind 2 (locale-comma) -- below (d8_locale)
    #       kind 4 (coerced)      -- below (d8_coerced)
    #       kind 5 (leading-dot)  -- below (d8_leaddot)
    # -------------------------------------------------------------------
    check_true("v129",
        "[refusal 8, kind 1] a genuinely empty respondent cell alone does NOT fire refusal 8 (deliberately exempt -- Finding 1's own required exemption, re-asserted at this refusal's own positive-leg site)",
        ran_ok(out_clean) && num_(out_clean, "res", 1) == 0)

    # kind 2, locale-comma: R1 row 2 (Ease, item R1, committed value
    # "71.8") edited to "71,8" -- the exact live proof Finding 1 gives.
    # CSV-quoted ("\"71,8\"") because the raw cell now contains a comma
    # and this file's CSVs are otherwise unquoted data -- Praat's reader
    # strips quotes from a quoted DATA cell (this file's own header
    # comment on the quoted-header quirk, section 0 above), so the
    # quoting is invisible to the column once read and changes nothing
    # about what is being tested.
    data8_locale <- edit_field(clean_data_lines, 2, "R1", "\"71,8\"")
    p8_locale <- write_csv_lines(data8_locale, "d8_locale_data.csv")
    out8_locale <- drive_validate("stats", p8_locale, committed_scales_path,
                                  committed_items_path, "d8-locale")
    results$d8_locale <- out8_locale
    check_true("v129", "[refusal 8, kind 2] probe ran", ran_ok(out8_locale))
    if (ran_ok(out8_locale)) {
        check("v129", "[refusal 8, kind 2] code is 8 (locale-comma cell is unusable, not silently misread as 71)",
              num_(out8_locale, "res", 1), 8, tol = 0)
        check_true("v129", "[refusal 8, kind 2] badItem is \"R1\"",
                   identical(str_(out8_locale, "res", 2), "R1"))
        check_true("v129", "[refusal 8, kind 2] badScale is \"Ease\"",
                   identical(str_(out8_locale, "res", 3), "Ease"))
        check("v129", "[refusal 8, kind 2] badRow is 2",
              num_(out8_locale, "res", 4), 2, tol = 0)
        check_true("v129", "[refusal 8, kind 2] badCellText is \"71,8\"",
                   identical(str_(out8_locale, "res", 17), "71,8"))
        # [V1.7, cell ruling] LEG UPDATED: a locale-comma cell is untouched
        # by the ruling (it is not in the "unreadable" bucket at all --
        # @eml_classifyCell classifies it as its own kind 2), so it never
        # reaches @emlRepairClassify; asserted here directly.
        check("v129", "[cell ruling] locale-comma cell: disclosureCount is 0 (never asked the placeholder question)",
              num_(out8_locale, "res", 25), 0, tol = 0)
        positive_leg_codes <- c(positive_leg_codes, 8)
    }

    # kind 4, coerced (a percent sign): R2 row 5 (Ease, item R2, committed
    # value "95.6") edited to "95.6%". Planted on R2 rather than R1
    # specifically because R2 already carries the committed fixture's own
    # genuine blank cell (row 18) -- @emlAuditColumn's fast path
    # (eml-extract.praat: @eml_strictNumericColumn) short-circuits to
    # "every cell valid" on a column that numericises strictly as a WHOLE
    # via Praat's own "Get all numbers in column:", which "95.6%" alone
    # would still do (Praat's numericiser accepts a trailing percent sign
    # and returns a fraction, verified directly against Praat 6.6.30,
    # exactly the hazard @eml_classifyCell's own header comment names) --
    # skipping the per-cell classification loop entirely and reporting
    # the corrupted column clean. R2's own pre-existing blank forces that
    # fast path to fall through to the per-cell scan on ANY column it
    # sits in (@eml_strictNumericColumn's own pre-scan finds the blank
    # before it ever tries the whole-column numeric probe), so this is
    # the column where kind 4 is actually detectable through
    # @emlAuditColumn's real behavior, not a hand-picked case that dodges
    # a limitation of the classifier this pass is not permitted to touch
    # (eml-extract.praat is out of this lane's boundary).
    data8_coerced <- edit_field(clean_data_lines, 5, "R2", "95.6%")
    p8_coerced <- write_csv_lines(data8_coerced, "d8_coerced_data.csv")
    out8_coerced <- drive_validate("stats", p8_coerced, committed_scales_path,
                                   committed_items_path, "d8-coerced")
    results$d8_coerced <- out8_coerced
    check_true("v129", "[refusal 8, kind 4] probe ran", ran_ok(out8_coerced))
    if (ran_ok(out8_coerced)) {
        check("v129", "[refusal 8, kind 4] code is 8 (a percent-coerced cell is unusable, not silently read as a fraction)",
              num_(out8_coerced, "res", 1), 8, tol = 0)
        check_true("v129", "[refusal 8, kind 4] badItem is \"R2\"",
                   identical(str_(out8_coerced, "res", 2), "R2"))
        check("v129", "[refusal 8, kind 4] badRow is 5",
              num_(out8_coerced, "res", 4), 5, tol = 0)
        check_true("v129", "[refusal 8, kind 4] badCellText is \"95.6%\"",
                   identical(str_(out8_coerced, "res", 17), "95.6%"))
        # [V1.7, cell ruling] LEG UPDATED: a percent-coerced cell is
        # untouched by the ruling (@eml_classifyCell's own kind 4, not the
        # "unreadable" bucket), so it never reaches @emlRepairClassify.
        check("v129", "[cell ruling] percent-coerced cell: disclosureCount is 0 (never asked the placeholder question)",
              num_(out8_coerced, "res", 25), 0, tol = 0)
        positive_leg_codes <- c(positive_leg_codes, 8)
    }

    # kind 5, leading-dot: R1 row 2 (committed value "71.8") edited to
    # ".8" -- Finding 1's own second live proof: "Get value:" reads a bare
    # leading decimal point as `undefined`, so before this fix the row was
    # silently dropped by listwise deletion, indistinguishable from a
    # genuinely missing cell, while refusal was still 0.
    data8_leaddot <- edit_field(clean_data_lines, 2, "R1", ".8")
    p8_leaddot <- write_csv_lines(data8_leaddot, "d8_leaddot_data.csv")
    out8_leaddot <- drive_validate("stats", p8_leaddot, committed_scales_path,
                                   committed_items_path, "d8-leaddot")
    results$d8_leaddot <- out8_leaddot
    check_true("v129", "[refusal 8, kind 5] probe ran", ran_ok(out8_leaddot))
    if (ran_ok(out8_leaddot)) {
        check("v129", "[refusal 8, kind 5] code is 8 (a bare leading-dot cell is unusable, not silently dropped as though missing)",
              num_(out8_leaddot, "res", 1), 8, tol = 0)
        check_true("v129", "[refusal 8, kind 5] badItem is \"R1\"",
                   identical(str_(out8_leaddot, "res", 2), "R1"))
        check("v129", "[refusal 8, kind 5] badRow is 2",
              num_(out8_leaddot, "res", 4), 2, tol = 0)
        check_true("v129", "[refusal 8, kind 5] badCellText is \".8\"",
                   identical(str_(out8_leaddot, "res", 17), ".8"))
        # [Finding 1 fix] LEG RE-UPDATED: ".8" DOES now reach
        # @emlRepairClassify (kind 5 is examined on the same terms as the
        # "unreadable" bucket -- see @eml_scanColumnForPlaceholders's own
        # header), but @emlRepairClassify's OWN verdict for ".8" is kind 2
        # ("bare leading point"), not kind 3, so it is correctly NOT a
        # recognised placeholder either way. disclosureCount stays 0 for
        # the same reason as before Finding 1 -- being asked the question
        # and answering "no" looks identical, from here, to never being
        # asked -- but the demo just below (".", not ".8") is the case
        # where asking and not asking give DIFFERENT answers, which is
        # exactly what Finding 1 was.
        check("v129", "[cell ruling] leading-dot cell: disclosureCount is 0 (asked the placeholder question, correctly answered \"no\")",
              num_(out8_leaddot, "res", 25), 0, tol = 0)
        positive_leg_codes <- c(positive_leg_codes, 8)
    }

    # kind: whitespace-only (V1.6, Fix 3) -- R1 row 2 (committed value
    # "71.8") edited to a single space. Verified live before the fix: none
    # of @eml_strictNumericColumn's own pre-scan spellings ("",
    # "--undefined--", "?") match a bare space, so nothing stops
    # @emlAuditColumn's fast path from reaching Praat's own "Get all
    # numbers in column:", which HALTS the whole script --
    # "Table ""eml_numericProbe"": the cell in row 2 of column ""R1"" is
    # undefined" -- before this refusal, or any other, ever gets a chance
    # to run. This is the positive leg; a bespoke halt-control proving the
    # guard load-bearing (the same shape as Fix 2's own, above) follows
    # with the rest of this refusal's negative controls, below.
    data8_ws <- edit_field(clean_data_lines, 2, "R1", " ")
    p8_ws <- write_csv_lines(data8_ws, "d8_ws_data.csv")
    out8_ws <- drive_validate("stats", p8_ws, committed_scales_path,
                              committed_items_path, "d8-ws")
    results$d8_ws <- out8_ws
    check_true("v129", "[refusal 8, whitespace-only] probe ran (NOT a halt -- this is the exact live crash Fix 3 closes)", ran_ok(out8_ws))
    if (ran_ok(out8_ws)) {
        check("v129", "[refusal 8, whitespace-only] code is 8 (a bare-space respondent cell is refused as an unusable value, not silently treated as ordinary missingness)",
              num_(out8_ws, "res", 1), 8, tol = 0)
        check_true("v129", "[refusal 8, whitespace-only] badItem is \"R1\"",
                   identical(str_(out8_ws, "res", 2), "R1"))
        check_true("v129", "[refusal 8, whitespace-only] badScale is \"Ease\"",
                   identical(str_(out8_ws, "res", 3), "Ease"))
        check("v129", "[refusal 8, whitespace-only] badRow is 2",
              num_(out8_ws, "res", 4), 2, tol = 0)
        check_true("v129", "[refusal 8, whitespace-only] badCellText is a single space (the raw cell, not the empty string a genuinely blank cell would print)",
                   identical(str_(out8_ws, "res", 17), " "))
        # [V1.7, cell ruling] LEG UPDATED: a whitespace-only cell is the
        # one candidate this lane's own ruling text singles out by name
        # ("Whitespace-only cells join branch 1 once a classifier fix
        # lands... Until it lands, keep today's behaviour for
        # whitespace"), so this is the leg that changes -- not deleted,
        # not its refusal-code assertions touched, but now ALSO asserting
        # the disclosure path does NOT fire for it: @emlRepairClassify
        # trims a whitespace-only cell to "" and returns ITS OWN kind 0
        # ("nothing to do"), never kind 3, so it is not a recognised
        # placeholder today and contributes nothing to the disclosure.
        # (None of refusal 8's five pre-existing kind fixtures above --
        # "Soprano", "71,8", "95.6%", ".8", or this single space -- ever
        # planted an actual @emlRepairClassify kind-3 spelling; the three
        # legs immediately below are what actually exercises branches 1
        # and 2 of the ruling, since nothing above them did.)
        check("v129", "[cell ruling] whitespace-only cell: disclosureCount is 0 (not a recognised placeholder today)",
              num_(out8_ws, "res", 25), 0, tol = 0)
        positive_leg_codes <- c(positive_leg_codes, 8)
    }

    # -------------------------------------------------------------------
    # 4a-cell-ruling. THE SUPERSEDING CELL RULING's three required red
    #    demos, each its own leg. Refusal 8's five kind fixtures above
    #    (kind 2 locale, kind 3 "Soprano", kind 4 coerced, kind 5
    #    leading-dot, whitespace-only) are all left exactly as they were:
    #    none of them is a recognised missing-value placeholder, so branch
    #    3 (refuse, now also routing to "Check & repair data") is the
    #    correct, unchanged answer for every one of them, reasserted just
    #    above for the whitespace leg. These three are new.
    # -------------------------------------------------------------------

    # Demo 1 [branch 1 + 2]: a seeded "NA" cell alone. R1 row 2 (Ease,
    # committed value "71.8") edited to "NA" -- one of @emlRepairClassify's
    # own kind-3 spellings (eml-extract.praat:2665), case-insensitive,
    # NOT restated here. Expected: refusal STAYS 0 (the cell is treated as
    # ordinary missingness, exactly like a blank), and the disclosure
    # fires -- one cell, spelling "NA", item "R1".
    data_cr_na <- edit_field(clean_data_lines, 2, "R1", "NA")
    p_cr_na <- write_csv_lines(data_cr_na, "dcr_na_data.csv")
    out_cr_na <- drive_validate("stats", p_cr_na, committed_scales_path,
                                committed_items_path, "cr-na")
    results$cr_na <- out_cr_na
    check_true("v129", "[cell ruling, demo 1: NA] probe ran", ran_ok(out_cr_na))
    if (ran_ok(out_cr_na)) {
        check("v129", "[cell ruling, demo 1: NA] refusal stays 0 (a recognised placeholder is missingness, not a refusal)",
              num_(out_cr_na, "res", 1), 0, tol = 0)
        check("v129", "[cell ruling, demo 1: NA] disclosureCount is 1",
              num_(out_cr_na, "res", 25), 1, tol = 0)
        check("v129", "[cell ruling, demo 1: NA] disclosureSpellingCount is 1",
              num_(out_cr_na, "res", 26), 1, tol = 0)
        check("v129", "[cell ruling, demo 1: NA] disclosureItemCount is 1",
              num_(out_cr_na, "res", 27), 1, tol = 0)
        check_true("v129", "[cell ruling, demo 1: NA] disclosureSpelling[1] is \"NA\"",
                   identical(str_(out_cr_na, "resdisc", 1), "NA"))
        check_true("v129", "[cell ruling, demo 1: NA] disclosureItem[1] is \"R1\"",
                   identical(str_(out_cr_na, "resdisc", 2), "R1"))
        check_true("v129", "[cell ruling, demo 1: NA] disclosure$ is non-empty (the disclosure was actually printed, not just counted)",
                   nzchar(str_(out_cr_na, "res", 29)))
    }

    # Demo 2 [branch 1 + 2, mixed with branch 3]: a seeded "NA" cell (R1
    # row 2) AND a seeded whitespace-only cell (R2 row 5) in the SAME
    # fixture, different items. Proves the ruling's own "ALWAYS PRINTED"
    # requirement literally: the disclosure for the NA placeholder still
    # fires even though this declaration goes on to refuse anyway, for
    # the UNRELATED whitespace-only cell -- because the disclosure pass
    # runs in full, ahead of refusal 8's own cascade, and is never cut
    # short by a `goto`. Expected: refusal is 8 (the whitespace cell,
    # kept refusing per this ruling's own instruction), badItem is "R2",
    # yet disclosureCount is still 1, naming the NA cell in "R1".
    data_cr_mix <- edit_field(clean_data_lines, 2, "R1", "NA")
    data_cr_mix <- edit_field(data_cr_mix, 5, "R2", " ")
    p_cr_mix <- write_csv_lines(data_cr_mix, "dcr_mix_data.csv")
    out_cr_mix <- drive_validate("stats", p_cr_mix, committed_scales_path,
                                 committed_items_path, "cr-mix")
    results$cr_mix <- out_cr_mix
    check_true("v129", "[cell ruling, demo 2: NA + whitespace] probe ran", ran_ok(out_cr_mix))
    if (ran_ok(out_cr_mix)) {
        check("v129", "[cell ruling, demo 2: NA + whitespace] refusal is 8 (the whitespace cell, kept refusing)",
              num_(out_cr_mix, "res", 1), 8, tol = 0)
        check_true("v129", "[cell ruling, demo 2: NA + whitespace] badItem is \"R2\" (the whitespace cell, not the NA one)",
                   identical(str_(out_cr_mix, "res", 2), "R2"))
        check("v129", "[cell ruling, demo 2: NA + whitespace] badRow is 5",
              num_(out_cr_mix, "res", 4), 5, tol = 0)
        check("v129", "[cell ruling, demo 2: NA + whitespace] disclosureCount is STILL 1 -- the NA cell's disclosure fires despite the later whitespace refusal, proving the pass is not cut short by refusal 8's own `goto`",
              num_(out_cr_mix, "res", 25), 1, tol = 0)
        check_true("v129", "[cell ruling, demo 2: NA + whitespace] disclosureItem[1] is \"R1\" (the NA cell's item, not R2's)",
                   identical(str_(out_cr_mix, "resdisc", 2), "R1"))
        check_true("v129", "[cell ruling, demo 2: NA + whitespace] disclosure$ is non-empty (printed despite the run refusing)",
                   nzchar(str_(out_cr_mix, "res", 29)))
    }

    # Demo 3 [branch 3]: a seeded "approx 4" cell -- NOT one of
    # @emlRepairClassify's kind-3 spellings, so it stays genuinely
    # unreadable and refuses exactly as any other unreadable cell always
    # has. R1 row 2 edited to "approx 4".
    data_cr_bad <- edit_field(clean_data_lines, 2, "R1", "approx 4")
    p_cr_bad <- write_csv_lines(data_cr_bad, "dcr_bad_data.csv")
    out_cr_bad <- drive_validate("stats", p_cr_bad, committed_scales_path,
                                 committed_items_path, "cr-bad")
    results$cr_bad <- out_cr_bad
    check_true("v129", "[cell ruling, demo 3: approx 4] probe ran", ran_ok(out_cr_bad))
    if (ran_ok(out_cr_bad)) {
        check("v129", "[cell ruling, demo 3: approx 4] refusal is 8 (genuinely unreadable, not a recognised placeholder)",
              num_(out_cr_bad, "res", 1), 8, tol = 0)
        check_true("v129", "[cell ruling, demo 3: approx 4] badItem is \"R1\"",
                   identical(str_(out_cr_bad, "res", 2), "R1"))
        check("v129", "[cell ruling, demo 3: approx 4] badRow is 2",
              num_(out_cr_bad, "res", 4), 2, tol = 0)
        check_true("v129", "[cell ruling, demo 3: approx 4] badCellText is \"approx 4\"",
                   identical(str_(out_cr_bad, "res", 17), "approx 4"))
        check("v129", "[cell ruling, demo 3: approx 4] disclosureCount is 0 (nothing to disclose -- this cell was never treated as missing)",
              num_(out_cr_bad, "res", 25), 0, tol = 0)
        # Message WORDING is deliberately not asserted here (this file's own
        # header, section 0: only the empty-exactly-when-.refusal-is-0
        # shape is asserted about .error$/.remedy$); the routing sentence
        # is DRAFT, awaiting Ian's approval, like every other message this
        # procedure builds. The refusal code, badItem, badRow and
        # badCellText above are what this demo actually proves.
    }

    # -------------------------------------------------------------------
    # 4d-cell-ruling [Finding 1]: THE AUTHORITY IS THE AUTHORITY -- every
    #    one of @emlRepairClassify's eleven kind-3 spellings (na, n/a,
    #    n.a., nan, null, nil, -, --, ., ?, missing -- eml-extract.praat:
    #    2665, read here, never restated) actually REACHES
    #    @emlRepairClassify from a subscale item's data column and is
    #    judged a recognised placeholder, not just the ten that already
    #    happened to land in @eml_classifyCell's own "unreadable" bucket.
    #
    #    Before the fix, "." collided with @eml_classifyCell's OWN kind-5
    #    "bare leading decimal" recovery (built for ".5") -- a bare "."
    #    parses as "0." under the same probe, which is strictly numeric,
    #    so @eml_classifyCell filed it as kind 5, recoverable, and
    #    @eml_scanColumnForPlaceholders excluded kind 5 from ever asking
    #    @emlRepairClassify at all. The other ten spellings are not
    #    numeric-shaped in any way @eml_classifyCell recognises, so all
    #    ten already reached @emlRepairClassify before this fix; this
    #    section proves that empirically for LIVE VALUES rather than
    #    trusting the count -- one leg per spelling, sweeping the whole
    #    authority list, not a hand-picked sample.
    # -------------------------------------------------------------------
    placeholder_spellings <- c("na", "n/a", "n.a.", "nan", "null", "nil",
                              "-", "--", ".", "?", "missing")
    for (sp in placeholder_spellings) {
        data_sp <- edit_field(clean_data_lines, 2, "R1", sp)
        p_sp <- write_csv_lines(data_sp, paste0("dcr_sp_", gsub("[^A-Za-z0-9]", "_", sp), "_data.csv"))
        out_sp <- drive_validate("stats", p_sp, committed_scales_path,
                                 committed_items_path, paste0("cr-sp-", gsub("[^A-Za-z0-9]", "_", sp)))
        check_true("v129", sprintf("[Finding 1, all-eleven sweep] spelling \"%s\": probe ran", sp),
                   ran_ok(out_sp))
        if (ran_ok(out_sp)) {
            check("v129", sprintf("[Finding 1, all-eleven sweep] spelling \"%s\": refusal stays 0 (reached @emlRepairClassify and was recognised)", sp),
                  num_(out_sp, "res", 1), 0, tol = 0)
            check("v129", sprintf("[Finding 1, all-eleven sweep] spelling \"%s\": disclosureCount is 1", sp),
                  num_(out_sp, "res", 25), 1, tol = 0)
            check_true("v129", sprintf("[Finding 1, all-eleven sweep] spelling \"%s\": disclosureSpelling[1] echoes the trimmed literal", sp),
                       identical(str_(out_sp, "resdisc", 1), sp))
        }
    }

    # Demo 4 [Finding 1, the specific collision]: a bare "." alone, same
    # shape as demo 1 (NA) above, asserting the SAME full set of facts --
    # refusal 0, one disclosed cell, spelling ".", item "R1" -- so a
    # reader can compare this block directly against demo 1's and see
    # they now behave identically, which they did not before the fix
    # (this exact cell used to come back refusal 8, disclosureCount 0).
    data_cr_dot <- edit_field(clean_data_lines, 2, "R1", ".")
    p_cr_dot <- write_csv_lines(data_cr_dot, "dcr_dot_data.csv")
    out_cr_dot <- drive_validate("stats", p_cr_dot, committed_scales_path,
                                 committed_items_path, "cr-dot")
    results$cr_dot <- out_cr_dot
    check_true("v129", "[cell ruling, demo 4: bare \".\"] probe ran", ran_ok(out_cr_dot))
    if (ran_ok(out_cr_dot)) {
        check("v129", "[cell ruling, demo 4: bare \".\"] refusal stays 0 (a recognised placeholder is missingness, not refusal 8 as \"unusable\")",
              num_(out_cr_dot, "res", 1), 0, tol = 0)
        check("v129", "[cell ruling, demo 4: bare \".\"] disclosureCount is 1",
              num_(out_cr_dot, "res", 25), 1, tol = 0)
        check_true("v129", "[cell ruling, demo 4: bare \".\"] disclosureSpelling[1] is \".\"",
                   identical(str_(out_cr_dot, "resdisc", 1), "."))
        check_true("v129", "[cell ruling, demo 4: bare \".\"] disclosureItem[1] is \"R1\"",
                   identical(str_(out_cr_dot, "resdisc", 2), "R1"))
    }

    # -------------------------------------------------------------------
    # NEGATIVE CONTROL for Finding 1: the mutant is the LAST-COMMITTED
    # (pre-fix) eml-psychometrics.praat, read straight from `git show
    # HEAD:...` -- not a hand-rolled regex patch. Finding 1 was two
    # coupled changes (the scan's filter widened to examine kind 5, AND
    # refusal 8's own candidate assembly stopped trusting
    # emlAuditColumn.nLeadingDot once the scan started owning that
    # question); reverting only one half of a coupled fix reproduces a
    # DIFFERENT, not-actually-shipped bug, not the one Finding 1 reported.
    # The committed HEAD is exactly and only the code as it stood when
    # Finding 1 was filed, so driving the probe against it reproduces the
    # reported defect precisely: refusal 8, disclosureCount 0, on a bare
    # ".".
    # -------------------------------------------------------------------
    f1_head_txt <- tryCatch(
        system2("git", c("-C", shQuote(normalizePath(repo_path())), "show",
                         "HEAD:plugin_EML_StatsGraphs/stats/eml-psychometrics.praat"),
               stdout = TRUE, stderr = TRUE),
        error = function(e) character(0))
    check_true("v129", "[Finding 1] the pre-fix committed source was readable from git (negative-control seed)",
               length(f1_head_txt) > 100 && !any(grepl("^fatal:", f1_head_txt)))
    f1_mutdir <- file.path(work, "m_finding1_prefix")
    dir.create(f1_mutdir, showWarnings = FALSE)
    file.symlink(normalizePath(file.path(plug, "stats", "eml-extract.praat")),
                 file.path(f1_mutdir, "eml-extract.praat"))
    file.symlink(normalizePath(file.path(plug, "stats", "eml-inferential.praat")),
                 file.path(f1_mutdir, "eml-inferential.praat"))
    writeLines(f1_head_txt, file.path(f1_mutdir, "eml-psychometrics.praat"))
    out_cr_dot_mut <- drive_validate("m_finding1_prefix", p_cr_dot, committed_scales_path,
                                     committed_items_path, "cr-dot-mut")
    check_true("v129", "[Finding 1] pre-fix mutant probe ran", ran_ok(out_cr_dot_mut))
    if (ran_ok(out_cr_dot_mut)) {
        mut_dot_refusal <- num_(out_cr_dot_mut, "res", 1)
        mut_dot_disclosure <- num_(out_cr_dot_mut, "res", 25)
        if (red_mode) {
            cat("      EML_LANE_RED: running the standard bare-\".\" checks against the\n")
            cat("      pre-fix mutant -- the next two checks are EXPECTED to FAIL.\n")
            check("v129", "[RED] bare \".\": refusal stays 0 (must go red against the pre-fix build)",
                  mut_dot_refusal, 0, tol = 0)
            check("v129", "[RED] bare \".\": disclosureCount is 1 (must go red against the pre-fix build)",
                  mut_dot_disclosure, 1, tol = 0)
        } else {
            check_true("v129", "[Finding 1] pre-fix mutant differs from correct: bare \".\" is refused as unusable (refusal 8, not 0) -- exactly Finding 1's reported defect",
                       identical(mut_dot_refusal, 8))
            check_true("v129", "[Finding 1] pre-fix mutant differs from correct: bare \".\"'s disclosureCount is 0, not 1 -- exactly Finding 1's reported defect",
                       identical(mut_dot_disclosure, 0))
        }
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
        positive_leg_codes <- c(positive_leg_codes, 9)
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
        positive_leg_codes <- c(positive_leg_codes, 10)
    }

    # -------------------------------------------------------------------
    # 4c. FOUR MORE SEEDED-DEFECT FIXTURES -- refusals 11-14, added by a
    #     second adversarial pass that found the class of fault refusals
    #     6-10 closed on the ITEMS file was never closed on the SCALES
    #     file. Same style as sections 4 and 4b: one mutation, derived
    #     from the clean committed lines into tempdir(), never touching
    #     the committed files themselves.
    # -------------------------------------------------------------------

    # --- Defect 11: a required column missing from a declaration file --
    # The scales file's own "type" column dropped entirely (header and
    # every data row) -- the exact shape of a declaration written before
    # V1.2, and the live proof behind this refusal: without it, a bare
    # "Get value:" on the missing column HALTS Praat outright instead of
    # refusing.
    drop_column <- function(lines, col_name) {
        ci <- header_index(lines, col_name)
        stopifnot(length(ci) == 1)
        vapply(lines, function(line) {
            cells <- strsplit(line, ",", fixed = TRUE)[[1]]
            paste(cells[-ci], collapse = ",")
        }, character(1), USE.NAMES = FALSE)
    }
    scales11 <- drop_column(clean_scales_lines, "type")
    p11 <- write_csv_lines(scales11, "d11_scales.csv")
    out11 <- drive_validate("stats", committed_data_path, p11, committed_items_path, "d11")
    results$d11 <- out11
    check_true("v129", "[refusal 11] probe ran", ran_ok(out11))
    if (ran_ok(out11)) {
        check("v129", "[refusal 11] code is 11 (a required column is missing from a declaration file)",
              num_(out11, "res", 1), 11, tol = 0)
        check_true("v129", "[refusal 11] badColumn is \"type\"",
                   identical(str_(out11, "res", 20), "type"))
        check_true("v129", "[refusal 11] badFile is \"survey_scales.csv\"",
                   identical(str_(out11, "res", 21), "survey_scales.csv"))
        positive_leg_codes <- c(positive_leg_codes, 11)
    }

    # --- Defect 12: a subscale's declared min is missing or not numeric -
    # Confidence's declared min replaced with the non-numeric text "one" --
    # Ian's approved probe: "Get value:" returns `undefined` for it, and
    # both refusal 10's ">=" and refusal 2's range check are FALSE against
    # `undefined`, so this validated clean (refusal 0) before refusal 12
    # existed.
    scales12 <- edit_field(clean_scales_lines, 1, "min", "one")
    p12 <- write_csv_lines(scales12, "d12_scales.csv")
    out12 <- drive_validate("stats", committed_data_path, p12, committed_items_path, "d12")
    results$d12 <- out12
    check_true("v129", "[refusal 12] probe ran", ran_ok(out12))
    if (ran_ok(out12)) {
        check("v129", "[refusal 12] code is 12 (declared min/max missing or not numeric)",
              num_(out12, "res", 1), 12, tol = 0)
        check_true("v129", "[refusal 12] badScale is \"Confidence\"",
                   identical(str_(out12, "res", 3), "Confidence"))
        check("v129", "[refusal 12] badScaleRow is 1", num_(out12, "res", 15), 1, tol = 0)
        check_true("v129", "[refusal 12] badColumn is \"min\"",
                   identical(str_(out12, "res", 20), "min"))
        check_true("v129", "[refusal 12] badRawValue is \"one\"",
                   identical(str_(out12, "res", 22), "one"))
        positive_leg_codes <- c(positive_leg_codes, 12)
    }

    # --- Defect 12b: a subscale's declared max is MISSING (blank), not just
    #     non-numeric -- "non-numeric or missing", both named in the
    #     refusal, get their own seeded fixture rather than one standing
    #     in for the other.
    scales12b <- edit_field(clean_scales_lines, 1, "max", "")
    p12b <- write_csv_lines(scales12b, "d12b_scales.csv")
    out12b <- drive_validate("stats", committed_data_path, p12b, committed_items_path, "d12b")
    results$d12b <- out12b
    check_true("v129", "[refusal 12b] probe ran", ran_ok(out12b))
    if (ran_ok(out12b)) {
        check("v129", "[refusal 12b] code is 12 (declared min/max missing or not numeric)",
              num_(out12b, "res", 1), 12, tol = 0)
        check_true("v129", "[refusal 12b] badColumn is \"max\"",
                   identical(str_(out12b, "res", 20), "max"))
        check_true("v129", "[refusal 12b] badRawValue is \"\" (a missing endpoint, not a non-numeric one)",
                   identical(str_(out12b, "res", 22), ""))
        positive_leg_codes <- c(positive_leg_codes, 12)
    }

    # --- Defect 12u: a subscale's declared min is Praat's OWN missing-value
    #     token, "--undefined--", not the empty string and not ordinary
    #     non-numeric text -- Finding 2's own live proof. THE SCHEMA DOC
    #     says the dialog writes both declaration files, and "Save as
    #     comma-separated file" writes exactly this 13-character literal
    #     for a missing cell (CLAUDE.md; this pass's own header), so a
    #     round-tripped declaration can contain it even though no CSV
    #     hand-typed by a person would. Before the fix, `.badRawValue$ =
    #     ""` was false for this literal (it is not the empty string), so
    #     this fixture fell into the "else" branch and printed the bare
    #     internal token into a user-facing sentence.
    #
    #     [V1.6, Fix 1, header defect b] .badRawValue$ ITSELF used to keep
    #     reporting the literal token honestly here (only the SENTENCE was
    #     scrubbed), which is exactly what left the header ("" for an empty
    #     endpoint cell) disagreeing with the code for this fixture. This
    #     round chose to fix the VALUE, not loosen the header: the OUTPUT
    #     is now forced to "" whenever @eml_classifyCell reads the cell as
    #     kind 1 ("--undefined--" included), so a caller reading
    #     .badRawValue$ directly, not just .error$, never sees the token
    #     either.
    scales12u <- edit_field(clean_scales_lines, 1, "min", "--undefined--")
    p12u <- write_csv_lines(scales12u, "d12u_scales.csv")
    out12u <- drive_validate("stats", committed_data_path, p12u, committed_items_path, "d12u")
    results$d12u <- out12u
    check_true("v129", "[refusal 12u] probe ran", ran_ok(out12u))
    if (ran_ok(out12u)) {
        check("v129", "[refusal 12u] code is 12 (declared min/max missing or not numeric) -- parity with defect 12's hand-typed non-numeric text and 12b's hand-typed blank",
              num_(out12u, "res", 1), 12, tol = 0)
        check_true("v129", "[refusal 12u] badColumn is \"min\"",
                   identical(str_(out12u, "res", 20), "min"))
        check_true("v129", "[refusal 12u] badRawValue is \"\" (V1.6: forced to match the header's own claim -- a round-tripped \"--undefined--\" cell is EMPTY, the same as a genuinely blank one, not a piece of text worth naming, on the OUTPUT itself and not merely on the sentence built from it)",
                   identical(str_(out12u, "res", 22), ""))
        check_true("v129", "[refusal 12u] .error$ does NOT contain the bare internal token \"--undefined--\" (Finding 2, closed as a class: the message says the value is empty, it does not print the token)",
                   !grepl("--undefined--", str_(out12u, "res", 23), fixed = TRUE))
        positive_leg_codes <- c(positive_leg_codes, 12)
    }

    # --- Defect 12w [V1.6, Fix 2]: a subscale's declared min is
    #     WHITESPACE-ONLY, not exactly empty and not Praat's own missing-
    #     value token -- a single space in the min cell
    #     ("Confidence, ,5,ordinal"). Before the fix, @eml_strictNumericColumn
    #     (eml-extract.praat)'s own pre-scan recognised only "", "--undefined--"
    #     and "?" as unreadable before its fast path called Praat's own "Get
    #     all numbers in column:", which a whitespace-only cell reached and
    #     HALTED: "Table ...: the cell in row 1 of column ""min"" is
    #     undefined ... cannot get all numbers in column 2" -- proved live,
    #     reproduced against the pre-fix module before writing this leg,
    #     and NOT reachable via refusal 11 or any of defects 12/12b/12u
    #     above (each of those already avoids the exact gap this one lands
    #     in: a raw cell that is non-empty, is not the literal
    #     "--undefined--" token, and is not "?", but trims to nothing).
    scales12w <- edit_field(clean_scales_lines, 1, "min", " ")
    p12w <- write_csv_lines(scales12w, "d12w_scales.csv")
    out12w <- drive_validate("stats", committed_data_path, p12w, committed_items_path, "d12w")
    results$d12w <- out12w
    check_true("v129", "[refusal 12w] probe ran (NOT a halt -- this is the exact live crash Fix 2 closes)", ran_ok(out12w))
    if (ran_ok(out12w)) {
        check("v129", "[refusal 12w] code is 12 (a whitespace-only endpoint is empty, not a number), not a halt",
              num_(out12w, "res", 1), 12, tol = 0)
        check_true("v129", "[refusal 12w] badScale is \"Confidence\"",
                   identical(str_(out12w, "res", 3), "Confidence"))
        check("v129", "[refusal 12w] badScaleRow is 1", num_(out12w, "res", 15), 1, tol = 0)
        check_true("v129", "[refusal 12w] badColumn is \"min\"",
                   identical(str_(out12w, "res", 20), "min"))
        check_true("v129", "[refusal 12w] badRawValue is \"\" (a whitespace-only endpoint is empty, same treatment as a genuinely blank one and as \"--undefined--\", not literal whitespace text)",
                   identical(str_(out12w, "res", 22), ""))
        check_true("v129", "[refusal 12w] .error$ says the endpoint is empty, not a halt message and not the literal whitespace",
                   grepl("empty", str_(out12w, "res", 23), fixed = TRUE))
        positive_leg_codes <- c(positive_leg_codes, 12)
    }

    # --- Defect 13: a scale name declared more than once ----------------
    # Confidence's row duplicated with a DIFFERENT max (1-200 instead of
    # 1-5) immediately after itself -- Ian's approved probe, mirroring
    # refusal 7's own duplicate-item fixture. Planted 99 in Q1 row 3 (the
    # same value and location the negative control in section 5 uses):
    # before refusal 13 existed, refusal 2's resolution loop had no break
    # and no duplicate check, so the LAST matching row (1-200) silently
    # won and 99 validated clean.
    conf_row <- clean_scales_lines[grepl("^Confidence,", clean_scales_lines)]
    stopifnot(length(conf_row) == 1)
    scales13 <- append(clean_scales_lines, "Confidence,1,200,ordinal",
                       after = which(clean_scales_lines == conf_row))
    p13 <- write_csv_lines(scales13, "d13_scales.csv")
    data13 <- edit_field(clean_data_lines, 3, "Q1", "99")
    p13d <- write_csv_lines(data13, "d13_data.csv")
    out13 <- drive_validate("stats", p13d, p13, committed_items_path, "d13")
    results$d13 <- out13
    check_true("v129", "[refusal 13] probe ran", ran_ok(out13))
    if (ran_ok(out13)) {
        check("v129", "[refusal 13] code is 13 (scale name declared more than once), not 0 (was misreported as clean before this refusal existed)",
              num_(out13, "res", 1), 13, tol = 0)
        check_true("v129", "[refusal 13] badScale is \"Confidence\"",
                   identical(str_(out13, "res", 3), "Confidence"))
        check("v129", "[refusal 13] badScaleRow is 2 (the second, duplicated declaration)",
              num_(out13, "res", 15), 2, tol = 0)
        positive_leg_codes <- c(positive_leg_codes, 13)
    }

    # --- Defect 14: a scale name is empty --------------------------------
    # Confidence's name blanked -- unchecked by the same gap as 13: an
    # empty scale name is never matched against a data column the way an
    # item name is (refusal 1), so nothing else in the procedure would
    # ever catch it.
    scales14 <- edit_field(clean_scales_lines, 1, "scale", "")
    p14 <- write_csv_lines(scales14, "d14_scales.csv")
    out14 <- drive_validate("stats", committed_data_path, p14, committed_items_path, "d14")
    results$d14 <- out14
    check_true("v129", "[refusal 14] probe ran", ran_ok(out14))
    if (ran_ok(out14)) {
        check("v129", "[refusal 14] code is 14 (a scale name is empty)",
              num_(out14, "res", 1), 14, tol = 0)
        check("v129", "[refusal 14] badScaleRow is 1", num_(out14, "res", 15), 1, tol = 0)
        check_true("v129", "[refusal 14] badScale is \"\" (the fault IS that the scale has no name)",
                   identical(str_(out14, "res", 3), ""))
        positive_leg_codes <- c(positive_leg_codes, 14)
    }

    # --- Defect 14b: a scale name is WHITESPACE, not exactly empty ------
    # Finding 6's own live proof: `.scaleName$[.s] = ""` tested exact
    # empty, so a scale name of a single space validated clean and
    # declared a live subscale with a whitespace name -- unmatchable by
    # eye and unmatchable by any item's role, which the plan's own
    # relational check (refusal 5) compares by exact string equality too.
    scales14b <- edit_field(clean_scales_lines, 1, "scale", " ")
    p14b <- write_csv_lines(scales14b, "d14b_scales.csv")
    out14b <- drive_validate("stats", committed_data_path, p14b, committed_items_path, "d14b")
    results$d14b <- out14b
    check_true("v129", "[refusal 14b] probe ran", ran_ok(out14b))
    if (ran_ok(out14b)) {
        check("v129", "[refusal 14b] code is 14 (a whitespace-only scale name is empty, not a real name) -- not 0 (was misreported as clean before this fix), and not 5 (item_unknown_scale, misreported as a relational fault rather than the scale's own missing name)",
              num_(out14b, "res", 1), 14, tol = 0)
        check("v129", "[refusal 14b] badScaleRow is 1", num_(out14b, "res", 15), 1, tol = 0)
        positive_leg_codes <- c(positive_leg_codes, 14)
    }

    # --- Defect 14u: a scale name is Praat's OWN missing-value token,
    #     "--undefined--" -- the same round-trip realism as Defect 12u,
    #     applied to the scale-name column instead of an endpoint column.
    #     @eml_normalizeLabel (a trim-only classifier) would NOT have
    #     caught this spelling of "no name" -- only @eml_classifyCell's
    #     kind 1 folds both spellings together, which is why this refusal
    #     is built on that classifier and not the other one.
    scales14u <- edit_field(clean_scales_lines, 1, "scale", "--undefined--")
    p14u <- write_csv_lines(scales14u, "d14u_scales.csv")
    out14u <- drive_validate("stats", committed_data_path, p14u, committed_items_path, "d14u")
    results$d14u <- out14u
    check_true("v129", "[refusal 14u] probe ran", ran_ok(out14u))
    if (ran_ok(out14u)) {
        check("v129", "[refusal 14u] code is 14 (a round-tripped missing-token scale name is empty, not a real name)",
              num_(out14u, "res", 1), 14, tol = 0)
        check("v129", "[refusal 14u] badScaleRow is 1", num_(out14u, "res", 15), 1, tol = 0)
        positive_leg_codes <- c(positive_leg_codes, 14)
    }

    # --- Defect 15 [V1.5, Finding 4a]: two data-table columns share the
    #     same header. A second "Q1" column appended, holding 99 (row 3,
    #     out of Confidence's declared 1-5 range -- refusal 2's question)
    #     and "abc" (row 4, unreadable -- refusal 8's question), every
    #     other row left blank. Proves the exact live escape Finding 4a
    #     demonstrated: before refusal 15 existed, "Get column index:" and
    #     "Get value:" both resolved to the FIRST "Q1" (the clean,
    #     committed column), so this fixture returned refusal 0 -- neither
    #     the 99 nor the "abc" was ever read, because nothing ever reached
    #     the shadowed second column.
    data15 <- add_data_column(clean_data_lines, "Q1",
                              row_values = list(`3` = "99", `4` = "abc"))
    p15d <- write_csv_lines(data15, "d15_data.csv")
    out15 <- drive_validate("stats", p15d, committed_scales_path, committed_items_path, "d15")
    results$d15 <- out15
    check_true("v129", "[refusal 15] probe ran", ran_ok(out15))
    if (ran_ok(out15)) {
        check("v129", "[refusal 15] code is 15 (two data-table columns share a header), not 0 (the shadowed column's 99-out-of-range and \"abc\"-unreadable cells were invisible before this refusal existed) and not 2 or 8 (which never see the shadowed column either)",
              num_(out15, "res", 1), 15, tol = 0)
        check_true("v129", "[refusal 15] badItem is \"Q1\" (the repeated header)",
                   identical(str_(out15, "res", 2), "Q1"))
        positive_leg_codes <- c(positive_leg_codes, 15)
    }

    # --- Defect 16 [V1.5, Finding 4b]: a data-table column is not
    #     declared by any item. A new "Extra" column appended, present in
    #     the data table and named nowhere in survey_items.csv -- neither
    #     scored by a subscale item nor disclosed as deliberately
    #     "grouping" or "ignore". Before this refusal existed, nothing in
    #     the procedure ever looked at the data table's columns from this
    #     direction, so this fixture returned refusal 0.
    data16 <- add_data_column(clean_data_lines, "Extra",
                              row_values = setNames(as.list(rep("5", 24)), as.character(1:24)))
    p16d <- write_csv_lines(data16, "d16_data.csv")
    out16 <- drive_validate("stats", p16d, committed_scales_path, committed_items_path, "d16")
    results$d16 <- out16
    check_true("v129", "[refusal 16] probe ran", ran_ok(out16))
    if (ran_ok(out16)) {
        check("v129", "[refusal 16] code is 16 (a data-table column is not declared by any item), not 0 (the undeclared \"Extra\" column was silently neither scored nor ignored before this refusal existed)",
              num_(out16, "res", 1), 16, tol = 0)
        check_true("v129", "[refusal 16] badItem is \"Extra\" (the undeclared column)",
                   identical(str_(out16, "res", 2), "Extra"))
        positive_leg_codes <- c(positive_leg_codes, 16)
    }

    # -------------------------------------------------------------------
    # 5. NEGATIVE CONTROL -- range check seeded to compare against the
    #    OBSERVED range instead of the DECLARED one.
    # -------------------------------------------------------------------
    mut <- file.path(work, "mutant")
    dir.create(mut, showWarnings = FALSE)
    # The probe now includes eml-extract.praat and eml-inferential.praat
    # before eml-psychometrics.praat (the module's own Dependencies header),
    # so every mutant directory needs a real, unmutated copy of both sitting
    # beside its one mutated file.
    file.symlink(normalizePath(file.path(plug, "stats", "eml-extract.praat")),
                 file.path(mut, "eml-extract.praat"))
    file.symlink(normalizePath(file.path(plug, "stats", "eml-inferential.praat")),
                 file.path(mut, "eml-inferential.praat"))
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
    negative_control_codes <- c(negative_control_codes, 2)

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
    file.symlink(normalizePath(file.path(plug, "stats", "eml-inferential.praat")),
                 file.path(mut2, "eml-inferential.praat"))

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
    # 6b. NEGATIVE CONTROL for refusal 1 -- a required item's column check.
    #    NOT the generic run_negative_control() pattern, for the same reason
    #    refusal 11's control below is bespoke: neutering THIS guard does not
    #    make the module produce a different, well-formed refusal code the
    #    way neutering refusals 3, 4, 5A or 5B does. It disables the ONLY
    #    check standing between an item naming a column the data table
    #    lacks and refusal 2's own loop, several checks later, doing a bare
    #    "Get value: .r, .itemName$[.i]" against that same nonexistent
    #    column -- which HALTS Praat outright (verified live below) rather
    #    than refusing gracefully. Finding 6 named this exact risk: "the
    #    suite surfaces only as an opaque 'probe ran' failure with no
    #    indication of cause" -- so this control asserts the SPECIFIC
    #    outcome (a halt on this seeded defect) and reports it as "refusal 1
    #    is load-bearing against a script abort", not as an unexplained
    #    ran_ok() failure indistinguishable from a driver bug.
    #
    #    THIS control uses its OWN fixture (items1_nc), a PHANTOM item
    #    APPENDED to the clean items file, rather than p1 (refusal 1's own
    #    positive-leg fixture, which RENAMES the real item "Q1" to "Q1x").
    #    V1.5's refusal 16 (Finding 4b) changed what renaming does: once
    #    "Q1" is renamed away, the DATA table's own "Q1" column becomes
    #    undeclared by any item, which is refusal 16's own question -- so
    #    with refusal 1 neutered, p1 no longer reaches refusal 2's crash at
    #    all; refusal 16 (checked well before refusal 2) now catches the
    #    orphaned data column first and refuses gracefully (verified live:
    #    driving p1 against this same neutered-guard mutant now reports
    #    refusal 16, "Column \"Q1\" is not [declared]", not a halt). An
    #    APPENDED phantom item avoids that collision: every real data
    #    column stays declared by its original, untouched item row (so
    #    refusal 16 has nothing to catch), while the phantom item itself
    #    names a column that never existed in the data table at all, which
    #    is refusal 1's question alone.
    # -------------------------------------------------------------------
    items1_nc <- c(clean_items_lines, "PhantomCol,Confidence,0")
    p1_nc <- write_csv_lines(items1_nc, "d1nc_items.csv")
    out1_nc_clean <- drive_validate("stats", committed_data_path, committed_scales_path,
                                    p1_nc, "d1nc-clean")
    check_true("v129",
        "[refusal 1, negative-control fixture] on the UNNEUTERED build, the appended phantom item (naming a column the data table never had) reports refusal 1, not 16 or anything else -- confirms this fixture isolates refusal 1 cleanly, unlike p1 once refusal 16 exists",
        ran_ok(out1_nc_clean) && identical(num_(out1_nc_clean, "res", 1), 1) &&
        identical(str_(out1_nc_clean, "res", 2), "PhantomCol"))

    mut1 <- file.path(work, "mutant1")
    dir.create(mut1, showWarnings = FALSE)
    file.symlink(normalizePath(file.path(plug, "stats", "eml-extract.praat")),
                 file.path(mut1, "eml-extract.praat"))
    file.symlink(normalizePath(file.path(plug, "stats", "eml-inferential.praat")),
                 file.path(mut1, "eml-inferential.praat"))
    src1 <- readLines(file.path(plug, "stats", "eml-psychometrics.praat"))
    src1_txt <- paste(src1, collapse = "\n")
    needle1 <- "        if .colIndex = 0"
    hit1 <- lengths(regmatches(src1_txt, gregexpr(needle1, src1_txt, fixed = TRUE)))
    check_true("v129",
               "[refusal 1] the guard line exists in source, exactly once (negative-control seed site)",
               hit1 == 1)
    mut1_txt <- sub(needle1, "        if 0 = 1", src1_txt, fixed = TRUE)
    writeLines(strsplit(mut1_txt, "\n", fixed = TRUE)[[1]],
               file.path(mut1, "eml-psychometrics.praat"))
    linkdir1 <- file.path(work, "mutant1_link")
    if (!file.exists(linkdir1)) file.symlink(mut1, linkdir1)

    # Driven on the phantom-item fixture (p1_nc, above), NOT p1: with the
    # guard neutered, the loop never catches the phantom item, so its name
    # reaches refusal 2's per-respondent loop unchecked and that loop's
    # bare "Get value:" against the nonexistent "PhantomCol" column aborts
    # the script -- without first being intercepted by refusal 16 (which
    # p1's own renamed-"Q1x" fixture now would be, per the comment above).
    out_mut1 <- drive_validate("mutant1_link", committed_data_path,
                               committed_scales_path, p1_nc, "mutant1")
    negative_control_codes <- c(negative_control_codes, 1)

    if (red_mode) {
        cat("      EML_LANE_RED: running the standard 'refusal 1 fires'\n")
        cat("      check against the neutered-guard build -- the next check is\n")
        cat("      EXPECTED to FAIL (the mutant HALTS rather than reports 1).\n")
        check_true("v129",
            "[RED] refusal 1 probe runs cleanly and reports code 1 on its seeded defect (must go red once the guard is neutered)",
            ran_ok(out_mut1) && identical(num_(out_mut1, "res", 1), 1))
    } else {
        check_true("v129",
            "[refusal 1] guard neutered: the mutant HALTS outright on its own seeded defect instead of refusing gracefully -- refusal 1 is load-bearing against a script abort (without it, refusal 2's later \"Get value:\" on the missing column aborts Praat, exactly as Finding 6 warned, rather than producing any refusal code)",
            !ran_ok(out_mut1))
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
        # Record the code this call exercises AS IT RUNS (eml_claim style) --
        # never a separately hand-maintained list -- so section 18's coverage
        # assertion can compare it against the set discovered from source.
        negative_control_codes <<- c(negative_control_codes, correct_code)
        mutdir <- file.path(work, mut_name)
        dir.create(mutdir, showWarnings = FALSE)
        file.symlink(normalizePath(file.path(plug, "stats", "eml-extract.praat")),
                     file.path(mutdir, "eml-extract.praat"))
        file.symlink(normalizePath(file.path(plug, "stats", "eml-inferential.praat")),
                     file.path(mutdir, "eml-inferential.praat"))
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

    # Refusal 7: duplicate item name. V1.3 refactored this guard onto the
    # shared @eml_findDuplicateName helper (also used by refusal 13's own
    # negative control below) -- the needle moves with it, to
    # "if .jName$ = .iName$" inside that helper, rather than an inline
    # loop in @emlSurveyValidateDeclaration's own body.
    run_negative_control("mutant7",
        "            if .jName$ = .iName$",
        "mutant7", committed_data_path, committed_scales_path, p7, 7)

    # Refusal 9: illegal scale type keyword
    run_negative_control("mutant9",
        "        if .scaleType$[.s] <> .typeKeywordOrdinal$ and .scaleType$[.s] <> .typeKeywordContinuous$",
        "mutant9", committed_data_path, p9, committed_items_path, 9)

    # Refusal 10: declared min not below declared max
    run_negative_control("mutant10",
        "        if .scaleMin[.s] >= .scaleMax[.s]",
        "mutant10", committed_data_path, p10, committed_items_path, 10)

    # Refusal 8: unusable data column on an item resolved to a subscale.
    # V1.4 (Finding 1) restructured the guard from one combined "and" test
    # into an outer "column read cleanly" gate wrapping the per-kind scan
    # -- the needle moves with it, to that outer gate, which is unique in
    # the source (the inner per-kind "if NNN > 0" tests are not: each kind
    # word -- locale, coerced, leading-dot, unreadable -- appears only
    # once each, but neutering just one of the four would still leave the
    # other three able to fire refusal 8 on this fixture's kind-3 defect,
    # which is exactly what this control must NOT permit through).
    run_negative_control("mutant8",
        '            if emlAuditColumn.error$ = ""',
        "mutant8", committed_data_path, committed_scales_path, p8, 8)

    # -------------------------------------------------------------------
    # NEGATIVE CONTROL for Fix 3's whitespace-only-DATA-cell guard -- NOT
    # the generic run_negative_control() pattern, for the same reason as
    # Fix 2's own bespoke control above (and refusal 11's and refusal 1's):
    # neutering this guard does not make the module produce a DIFFERENT,
    # well-formed refusal code -- it reproduces the exact HALT Fix 3's own
    # header describes. @eml_strictNumericColumn's own pre-scan
    # (eml-extract.praat) does not recognise a whitespace-only cell as
    # unreadable, so once this module's own guard is neutered, nothing
    # stops @emlAuditColumn's fast path from calling Praat's "Get all
    # numbers in column:" on it, and Praat itself aborts the script. That
    # crash, not a differing refusal code, IS the proof this guard is
    # load-bearing.
    #
    # Bounded to refusal 8's own block (its opening comment line to
    # refusal 2's, exclusive) -- the same discipline Fix 2's own control
    # above now uses, and section 18b's derive_refusal_codes() applies to
    # @emlSurveyValidateDeclaration's own body (the v105_pitch_parity.R
    # pattern) -- so this needle, which reads textually IDENTICALLY to
    # Fix 2's own guard line ("if eml_findWhitespaceOnlyCell.found = 1",
    # the same shared helper's output tested the same way), can be counted
    # and mutated here without any risk of also touching Fix 2's two
    # occurrences on the scales file, above.
    # -------------------------------------------------------------------
    mut8w <- file.path(work, "mutant8w")
    dir.create(mut8w, showWarnings = FALSE)
    file.symlink(normalizePath(file.path(plug, "stats", "eml-extract.praat")),
                 file.path(mut8w, "eml-extract.praat"))
    file.symlink(normalizePath(file.path(plug, "stats", "eml-inferential.praat")),
                 file.path(mut8w, "eml-inferential.praat"))
    src8w <- readLines(file.path(plug, "stats", "eml-psychometrics.praat"))
    r8_start <- grep("^    # ===== Refusal 8:", src8w)
    r8_next <- grep("^    # ===== Refusal 2:", src8w)
    stopifnot(length(r8_start) == 1L, length(r8_next) == 1L, r8_start < r8_next)
    src8w_txt <- paste(src8w[r8_start:(r8_next - 1L)], collapse = "\n")
    needle8w <- "if eml_findWhitespaceOnlyCell.found = 1"
    hit8w <- lengths(regmatches(src8w_txt, gregexpr(needle8w, src8w_txt, fixed = TRUE)))
    check_true("v129",
               "[Fix 3] the whitespace-only-DATA-cell guard line exists in refusal 8's own source block, exactly once -- negative-control seed site",
               hit8w == 1)
    mut8w_body_txt <- sub(needle8w, "0 = 1", src8w_txt, fixed = TRUE)
    mut8w_full <- src8w
    mut8w_full[r8_start:(r8_next - 1L)] <- strsplit(mut8w_body_txt, "\n", fixed = TRUE)[[1]]
    writeLines(mut8w_full, file.path(mut8w, "eml-psychometrics.praat"))
    linkdir8w <- file.path(work, "mutant8w_link")
    if (!file.exists(linkdir8w)) file.symlink(mut8w, linkdir8w)

    out_mut8w <- drive_validate("mutant8w_link", p8_ws, committed_scales_path,
                                committed_items_path, "mutant8w")
    negative_control_codes <- c(negative_control_codes, 8)

    if (red_mode) {
        cat("      EML_LANE_RED: running the standard 'refusal 8 fires'\n")
        cat("      check against the neutered-guard build -- the next check is\n")
        cat("      EXPECTED to FAIL (the mutant HALTS rather than reports 8).\n")
        check_true("v129",
            "[RED] refusal 8 fires on the whitespace-only-DATA-cell fixture (must go red once Fix 3's guard is neutered)",
            ran_ok(out_mut8w) && identical(num_(out_mut8w, "res", 1), 8))
    } else {
        check_true("v129",
            "[Fix 3] whitespace-only-DATA-cell guard neutered: the mutant HALTS outright on its own seeded defect (a bare space in R1, row 2) instead of refusing gracefully -- the guard is load-bearing against exactly the script abort Fix 3 closes",
            !ran_ok(out_mut8w))
    }

    # -------------------------------------------------------------------
    # TEXT PARITY (Fix 3's cleanup) -- @eml_findWhitespaceOnlyCell's skip
    # condition (eml-psychometrics.praat) restates two of
    # @eml_strictNumericColumn's own three "unreadable" spellings
    # (eml-extract.praat). eml-extract.praat is outside this lane's
    # boundary, so the two cannot be merged into one shared constant; the
    # canon is instead read out of both files by source text and compared,
    # not restructured into one -- the v105_pitch_parity.R pattern. The
    # third spelling ("?") is deliberately NOT restated: @eml_classifyCell
    # never classifies a bare "?" as kind 1 (it is not empty once trimmed,
    # and it is not a number in any locale -- @eml_classifyCell's own kind
    # 3), so a "?" comparison in the skip condition could never change
    # which row is reported and was dead code, removed rather than kept
    # for a false symmetry with the other two.
    # -------------------------------------------------------------------
    extract_canon_line <- grep(
        'if \\.cell\\$ = "" or \\.cell\\$ = "--undefined--" or \\.cell\\$ = "\\?"',
        readLines(file.path(plug, "stats", "eml-extract.praat"), warn = FALSE),
        value = TRUE)
    check_true("v129",
        "[Fix 3 cleanup] @eml_strictNumericColumn's own three-spelling canon line is found, unchanged and exactly once, in eml-extract.praat (this parity check's own anchor)",
        length(extract_canon_line) == 1L)

    skip_line <- grep(
        'if \\.raw\\$ <> "" and \\.raw\\$ <> "--undefined--"',
        readLines(file.path(plug, "stats", "eml-psychometrics.praat"), warn = FALSE),
        value = TRUE)
    check_true("v129",
        "[Fix 3 cleanup] @eml_findWhitespaceOnlyCell's skip condition is found, exactly once, in eml-psychometrics.praat",
        length(skip_line) == 1L)

    extract_tokens <- if (length(extract_canon_line) == 1L) {
        regmatches(extract_canon_line, gregexpr('"[^"]*"', extract_canon_line))[[1]]
    } else character(0)
    skip_tokens <- if (length(skip_line) == 1L) {
        regmatches(skip_line, gregexpr('"[^"]*"', skip_line))[[1]]
    } else character(0)

    check_true("v129",
        "[Fix 3 cleanup] every token @eml_findWhitespaceOnlyCell's skip condition excludes is one @eml_strictNumericColumn's own pre-scan already recognises (the restated pair is a SUBSET of the three-spelling canon, not a fork of it -- catches the canon changing out from under the copy)",
        length(skip_tokens) > 0 && all(skip_tokens %in% extract_tokens))
    check_true("v129",
        "[Fix 3 cleanup] the skip condition restates exactly the two LIVE tokens (\"\" and \"--undefined--\"), not the dead third (\"?\") that @eml_classifyCell already excludes from kind 1 on its own",
        identical(sort(skip_tokens), sort(c('""', '"--undefined--"'))))

    # -------------------------------------------------------------------
    # 11b-11e. NEGATIVE CONTROLS for refusals 3, 4, 5A and 5B -- Finding 6:
    #    these four guards (plus refusal 1, given its own bespoke section 6b
    #    above) had only positive seeded-defect legs, unlike every refusal
    #    from 6 onward. Same generic run_negative_control() pattern as
    #    refusals 6, 7, 9, 10 and 8 above -- each of these four DOES produce
    #    a different, well-formed refusal code once its guard is neutered
    #    (unlike refusal 1 or 11), so the standard mechanism applies
    #    unmodified. Driven on each refusal's own seeded-defect fixture from
    #    section 4 above (p3, p4, p5a, p5b).
    # -------------------------------------------------------------------

    # Refusal 3: a subscale with fewer than two items
    run_negative_control("mutant3",
        "        if .count >= 1 and .count < 2",
        "mutant3", committed_data_path, committed_scales_path, p3, 3)

    # Refusal 4: reversed set on a grouping or ignore column
    run_negative_control("mutant4",
        "        if .itemReversed[.i] = 1",
        "mutant4", committed_data_path, committed_scales_path, p4, 4)

    # Refusal 5, direction A: an item names a scale the scales file lacks
    run_negative_control("mutant5a",
        "            if .matched = 0",
        "mutant5a", committed_data_path, committed_scales_path, p5a, 5)

    # Refusal 5, direction B: a declared scale that no item uses
    run_negative_control("mutant5b",
        "        if .used = 0",
        "mutant5b", committed_data_path, p5b, committed_items_path, 5)

    # -------------------------------------------------------------------
    # 12-16. NEGATIVE CONTROLS for refusals 11-14 -- same pattern as
    #    7-11 above. Refusal 13 shares its guard with refusal 7 (both go
    #    through @eml_findDuplicateName), so its own control below
    #    neuters the SAME needle as mutant7 and is driven on refusal 13's
    #    own fixture -- proving the shared guard is load-bearing for both
    #    callers independently, rather than skipping 13's control as
    #    redundant with 7's.
    # -------------------------------------------------------------------

    # Refusal 11: a required declaration column is missing. NOT the
    # generic run_negative_control() pattern: neutering THIS guard does
    # not make the module produce a different, well-formed refusal code
    # the way neutering refusals 6-10, 12, 13 or 14's guards does. It
    # reproduces the exact HALT Finding 2 described -- the population
    # loop right after this guard reads the very column that is missing
    # with a bare "Get value:", which aborts Praat outright once nothing
    # stops it first. That crash, not a differing refusal code, IS the
    # proof this guard is load-bearing, so it gets its own bespoke block.
    mut11 <- file.path(work, "mutant11")
    dir.create(mut11, showWarnings = FALSE)
    file.symlink(normalizePath(file.path(plug, "stats", "eml-extract.praat")),
                 file.path(mut11, "eml-extract.praat"))
    file.symlink(normalizePath(file.path(plug, "stats", "eml-inferential.praat")),
                 file.path(mut11, "eml-inferential.praat"))
    src11 <- readLines(file.path(plug, "stats", "eml-psychometrics.praat"))
    src11_txt <- paste(src11, collapse = "\n")
    needle11 <- '        if emlRequireColumnPresent.error$ <> ""'
    hit11 <- lengths(regmatches(src11_txt, gregexpr(needle11, src11_txt, fixed = TRUE)))
    check_true("v129",
               "[refusal 11] the guard line exists in source, exactly once (negative-control seed site)",
               hit11 == 1)
    mut11_txt <- sub(needle11, "        if 0 = 1", src11_txt, fixed = TRUE)
    writeLines(strsplit(mut11_txt, "\n", fixed = TRUE)[[1]],
               file.path(mut11, "eml-psychometrics.praat"))
    linkdir11 <- file.path(work, "mutant11_link")
    if (!file.exists(linkdir11)) file.symlink(mut11, linkdir11)

    out_mut11 <- drive_validate("mutant11_link", committed_data_path, p11,
                                committed_items_path, "mutant11")
    negative_control_codes <- c(negative_control_codes, 11)
    if (red_mode) {
        cat("      EML_LANE_RED: running the standard 'refusal 11 fires'\n")
        cat("      check against the neutered-guard build -- the next check is\n")
        cat("      EXPECTED to FAIL (the mutant HALTS rather than reports 11).\n")
        check_true("v129",
            "[RED] refusal 11 probe runs cleanly and reports code 11 on its seeded defect (must go red once the guard is neutered)",
            ran_ok(out_mut11) && identical(num_(out_mut11, "res", 1), 11))
    } else {
        check_true("v129",
            "[refusal 11] guard neutered: the mutant HALTS outright on its own seeded defect instead of refusing gracefully -- proving the guard is load-bearing (without it, Praat crashes exactly as Finding 2 described, rather than producing any refusal code)",
            !ran_ok(out_mut11))
    }

    # Refusal 12: a declared min/max is missing or not numeric
    run_negative_control("mutant12",
        '    if .badEndpointError$ <> ""',
        "mutant12", committed_data_path, p12, committed_items_path, 12)

    # -------------------------------------------------------------------
    # NEGATIVE CONTROL for Fix 2's whitespace-only-endpoint guard -- NOT
    # the generic run_negative_control() pattern, for the same reason as
    # refusal 11's and refusal 1's own bespoke halt-controls above:
    # neutering this guard does not make the module produce a DIFFERENT,
    # well-formed refusal code -- it reproduces the exact HALT Fix 2's own
    # header describes. @eml_strictNumericColumn's own pre-scan
    # (eml-extract.praat) does not recognise a whitespace-only cell as
    # unreadable, so once this module's own guard is neutered, nothing
    # stops the fast path from calling Praat's "Get all numbers in
    # column:" on it, and Praat itself aborts the script. That crash, not
    # a differing refusal code, IS the proof this guard is load-bearing --
    # the identical shape refusal 11's own control uses above.
    #
    # The needle (the guard's own condition line) appears TWICE in source
    # -- once for "min", once for "max", both reading identically -- so
    # this is a bespoke gsub() rather than run_negative_control()'s single
    # sub() by design: neutering only one of the two would still let the
    # other catch this fixture's planted min-cell defect, which is exactly
    # the kind of partial kill this pass's own scope note warns against.
    # -------------------------------------------------------------------
    mut12w <- file.path(work, "mutant12w")
    dir.create(mut12w, showWarnings = FALSE)
    file.symlink(normalizePath(file.path(plug, "stats", "eml-extract.praat")),
                 file.path(mut12w, "eml-extract.praat"))
    file.symlink(normalizePath(file.path(plug, "stats", "eml-inferential.praat")),
                 file.path(mut12w, "eml-inferential.praat"))
    src12w <- readLines(file.path(plug, "stats", "eml-psychometrics.praat"))
    # Bounded to refusal 12's own block (its opening comment line to
    # refusal 15's, exclusive) -- the same "bound the scan" discipline
    # section 18b's derive_refusal_codes() applies to
    # @emlSurveyValidateDeclaration's own body (the v105_pitch_parity.R
    # pattern) -- so Fix 3's guard line for the DATA-column case (added
    # below, in refusal 8's own block, reading textually IDENTICALLY:
    # "if eml_findWhitespaceOnlyCell.found = 1", the same shared helper's
    # output tested the same way) can never be swept into this count or
    # this mutation. Without the bound, a plain whole-file substring count
    # would over-count once Fix 3 exists (its guard line, at deeper
    # indentation, contains this needle as a trailing substring) and the
    # gsub below would silently neuter Fix 3's guard too while claiming to
    # test only Fix 2's.
    r12_start <- grep("^    # ===== Refusal 12:", src12w)
    r12_next <- grep("^    # ===== Refusal 15", src12w)
    stopifnot(length(r12_start) == 1L, length(r12_next) == 1L, r12_start < r12_next)
    src12w_txt <- paste(src12w[r12_start:(r12_next - 1L)], collapse = "\n")
    needle12w <- "    if eml_findWhitespaceOnlyCell.found = 1"
    hit12w <- lengths(regmatches(src12w_txt, gregexpr(needle12w, src12w_txt, fixed = TRUE)))
    check_true("v129",
               "[Fix 2] the whitespace-only-endpoint guard line exists in refusal 12's own source block, exactly twice (min then max) -- negative-control seed site",
               hit12w == 2)
    mut12w_body_txt <- gsub(needle12w, "    if 0 = 1", src12w_txt, fixed = TRUE)
    mut12w_full <- src12w
    mut12w_full[r12_start:(r12_next - 1L)] <- strsplit(mut12w_body_txt, "\n", fixed = TRUE)[[1]]
    writeLines(mut12w_full, file.path(mut12w, "eml-psychometrics.praat"))
    linkdir12w <- file.path(work, "mutant12w_link")
    if (!file.exists(linkdir12w)) file.symlink(mut12w, linkdir12w)

    out_mut12w <- drive_validate("mutant12w_link", committed_data_path, p12w,
                                 committed_items_path, "mutant12w")
    negative_control_codes <- c(negative_control_codes, 12)

    if (red_mode) {
        cat("      EML_LANE_RED: running the standard 'refusal 12 fires'\n")
        cat("      check against the neutered-guard build -- the next check is\n")
        cat("      EXPECTED to FAIL (the mutant HALTS rather than reports 12).\n")
        check_true("v129",
            "[RED] refusal 12 probe runs cleanly and reports code 12 on the whitespace-only-endpoint fixture (must go red once Fix 2's guard is neutered)",
            ran_ok(out_mut12w) && identical(num_(out_mut12w, "res", 1), 12))
    } else {
        check_true("v129",
            "[Fix 2] whitespace-only-endpoint guard neutered: the mutant HALTS outright on its own seeded defect (a bare space in the min cell) instead of refusing gracefully -- the guard is load-bearing against exactly the script abort Fix 2 closes",
            !ran_ok(out_mut12w))
    }

    # Refusal 13: a scale name declared more than once (shared guard with
    # refusal 7 -- see note above)
    run_negative_control("mutant13",
        "            if .jName$ = .iName$",
        "mutant13", p13d, p13, committed_items_path, 13)

    # Refusal 14: a scale name is empty. V1.4 (Finding 6) moved this guard
    # onto @eml_classifyCell's kind (via the .scaleNameKind local) so a
    # whitespace-only or round-tripped "--undefined--" scale name is also
    # caught, not just the exact empty string -- the needle moves with it.
    # ".scaleNameKind" is a name coined for this one call site precisely
    # so this needle stays unique: refusal 12's message-class fix (Finding
    # 2) tests the identical "eml_classifyCell.kind = 1" condition on a
    # different cell a few hundred lines away, and a needle built from
    # that shared text would have matched twice.
    run_negative_control("mutant14",
        '        if .scaleNameKind = 1',
        "mutant14", committed_data_path, p14, committed_items_path, 14)

    # Refusal 15 [V1.5]: two data-table columns share the same header.
    # ".dupDataColFound" is a name coined for this one call site precisely
    # so this needle stays unique from refusal 7's and 13's identically
    # worded "if eml_findDuplicateName.found = 1" guards, which ask the
    # same underlying question of a different table. Neutering it must
    # not merely "differ from 15" by accident of some OTHER guard firing
    # first -- driven on the exact d15 fixture above, where nothing else
    # in the procedure would refuse (the shadowed 99/"abc" cells are never
    # read by anything), so the mutant's own refusal, once neutered, is 0.
    run_negative_control("mutant15",
        '    if .dupDataColFound = 1',
        "mutant15", p15d, committed_scales_path, committed_items_path, 15)

    # Refusal 16 [V1.5]: a data-table column is not declared by any item.
    # ".dataColDeclared" is likewise coined for this one call site so the
    # needle cannot collide with refusal 1's own, differently-worded
    # ".colIndex = 0" guard a few lines above it, which asks the mirror
    # question in the opposite direction. Driven on the d16 fixture above;
    # neutered, nothing else refuses the undeclared "Extra" column either,
    # so the mutant's refusal is 0.
    run_negative_control("mutant16",
        '        if .dataColDeclared = 0',
        "mutant16", p16d, committed_scales_path, committed_items_path, 16)

    # -------------------------------------------------------------------
    # 17. NO REFUSAL MESSAGE MAY PRINT THE INTERNAL TOKEN "--undefined--".
    #    This pass's own header finding (refusal 5 in the header, refusal
    #    12 here): "Get value:" returns `undefined` for a missing or
    #    non-numeric cell, and "string$ (...)" of that prints the literal
    #    token "--undefined--" into what is supposed to be a user-facing
    #    sentence naming the declaration fault, not an internal token. A
    #    second instance (refusal 6's message, printing a non-numeric
    #    `reversed` value) was found and fixed by this same pass, alongside
    #    the two named in the finding. Driven across EVERY leg run above
    #    that produced a real .error$/.remedy$ pair, not just the two
    #    fixtures the finding named -- a regression in any refusal's
    #    message, not only 2's, 6's, 10's or 12's, fails this leg.
    # -------------------------------------------------------------------
    undefined_checked <- 0
    for (nm in names(results)) {
        out <- results[[nm]]
        if (ran_ok(out)) {
            err_txt <- str_(out, "res", 23)
            rem_txt <- str_(out, "res", 24)
            check_true("v129",
                sprintf("[%s] .error$ does not contain the internal token \"--undefined--\"", nm),
                is.na(err_txt) || !grepl("--undefined--", err_txt, fixed = TRUE))
            check_true("v129",
                sprintf("[%s] .remedy$ does not contain the internal token \"--undefined--\"", nm),
                is.na(rem_txt) || !grepl("--undefined--", rem_txt, fixed = TRUE))
            undefined_checked <- undefined_checked + 1
        }
    }
    check_true("v129",
        "the --undefined-- sweep actually checked more than one seeded-defect leg (not vacuously true)",
        undefined_checked >= 10)

    # -------------------------------------------------------------------
    # 18. COVERAGE ASSERTION (eml_census spirit, per Finding 6's closing
    #    instruction) -- every refusal code @emlSurveyValidateDeclaration can
    #    actually emit, discovered FROM ITS OWN SOURCE rather than from a
    #    hand-written list here, must have both a positive seeded-defect leg
    #    and a negative control proving its guard is load-bearing. A refusal
    #    added later without a control -- the exact asymmetry Finding 6 named
    #    for refusals 1, 3, 4, 5A and 5B -- fails this rather than staying
    #    invisible behind every other check passing.
    #
    #    "present" (per eml_census's terms) is the DERIVED set: every
    #    `.refusal = N` assignment found by scanning the procedure's own body
    #    (declaration line to its first endproc after it -- bounded the same
    #    way v105_pitch_parity.R bounds @emlPitchArgsFAC's body -- not a
    #    whole-file grep, so a same-shaped assignment in some other procedure
    #    can never be miscounted as one of THIS procedure's codes), N = 0
    #    excluded since it names "no refusal", not a refusal.
    #
    #    "accounted" is built the eml_claim way, not hand-listed: each
    #    positive leg above appends its own code to positive_leg_codes right
    #    where it runs (sections 4, 4b, 4c), and run_negative_control() (plus
    #    the two bespoke halt-controls, refusals 1 and 11) appends to
    #    negative_control_codes the same way, so a check that stops running
    #    stops claiming its code in the same edit that removed it.
    # -------------------------------------------------------------------
    # -------------------------------------------------------------------
    # 18a. THE LINE-LEVEL EXTRACTOR (Finding 3) -- factored out of
    #    derive_refusal_codes() below so its regex can be proven directly
    #    against synthetic styles, without needing a whole fake procedure
    #    body just to exercise it.
    #
    #    THE DEFECT THIS REPLACES: the old pattern was
    #    "^\\s*\\.refusal\\s*=\\s*[0-9]+\\s*$", anchored to END OF LINE. A
    #    refusal assignment carrying a trailing Praat ";" comment --
    #    ".refusal = 15  ; probe-only code" -- never matched "$" and was
    #    INVISIBLE to the scan. Verified live: ".refusal = 15" alone is
    #    caught (removing it fails 4 checks); the same line with a
    #    trailing comment appended is not caught AT ALL. The failure
    #    direction is the worst kind there is: fewer derived codes means
    #    fewer things eml_census can call orphaned, which means GREEN --
    #    a shrinking derivation makes the census MORE likely to pass, not
    #    less.
    #
    #    THE FIX strips a trailing ";..." comment from each candidate line
    #    before matching, not after -- none of these assignment lines ever
    #    carries a quoted string, so cutting at the first ";" is
    #    unambiguous, and it also means a comment that happens to CONTAIN
    #    a lookalike ".refusal = N" is never double-counted: the comment
    #    text is gone before the regex ever sees it.
    # -------------------------------------------------------------------
    extract_refusal_assignment_codes <- function(body_lines) {
        stripped <- sub(";.*$", "", body_lines)
        asg <- grep("^\\s*\\.refusal\\s*=\\s*[0-9]+\\s*$", stripped, value = TRUE)
        nums <- as.integer(sub("^\\s*\\.refusal\\s*=\\s*([0-9]+)\\s*$", "\\1", asg))
        sort(unique(nums[nums != 0L]))
    }

    # THREE STYLES NOT ANTICIPATED BY THE OLD PATTERN, proven caught by the
    # new one, on a synthetic body (never the real 1-16 codes, so this can
    # never be satisfied by coincidence against the real file):
    #   A. ".refusal = 97  ; probe-only code"     -- spaced trailing comment
    #   B. ".refusal = 98;terse, no space at all" -- comment hugging the digit
    #   C. ".refusal = 99    ;    style C ...      " -- extra internal AND
    #      trailing whitespace, AND a lookalike ".refusal = 5" written
    #      INSIDE the comment text itself, proving the fix strips the
    #      comment before matching rather than merely tolerating trailing
    #      text after the digits (a fix that tolerated trailing text
    #      without stripping it first would double-count the 5).
    # A genuine WHOLE-LINE comment (the shape already live at this
    # procedure's own refusal-9 comment, "; .refusal = 0 for ...") is
    # included too, as a regression guard: the fix must not start
    # matching disabled code just because it now tolerates comments.
    synthetic_body <- c(
        "procedure emlSurveyValidateDeclarationSynthetic",
        "    .refusal = 97  ; probe-only code",
        "    .refusal = 98;terse, no space at all",
        "    .refusal = 99    ;    style C: internal .refusal = 5 lookalike, trailing whitespace too    ",
        "    ; .refusal = 0 for a scale that never reaches this branch",
        "endproc")
    synthetic_codes <- extract_refusal_assignment_codes(synthetic_body)
    check_true("v129",
        "[Finding 3] the fixed extractor catches a spaced trailing-comment refusal (\".refusal = 97  ; ...\")",
        97L %in% synthetic_codes)
    check_true("v129",
        "[Finding 3] the fixed extractor catches a comment hugging the digit with no space (\".refusal = 98;...\")",
        98L %in% synthetic_codes)
    check_true("v129",
        "[Finding 3] the fixed extractor catches extra internal/trailing whitespace AND does not double-count a lookalike assignment written inside the comment (\".refusal = 99 ... .refusal = 5 ...\")",
        99L %in% synthetic_codes && !(5L %in% synthetic_codes))
    check_true("v129",
        "[Finding 3] a genuine whole-line comment (\"; .refusal = 0 ...\") still contributes nothing (regression guard: tolerating trailing comments must not start matching disabled code)",
        !(0L %in% synthetic_codes))
    check_true("v129",
        "[Finding 3] the extractor found exactly the three synthetic codes and nothing else (97, 98, 99)",
        identical(synthetic_codes, c(97L, 98L, 99L)))

    # -------------------------------------------------------------------
    # 18b. THE PROCEDURE-BOUNDED DERIVATION -- bounds the scan to
    #    @emlSurveyValidateDeclaration's own body (declaration line to its
    #    first endproc after it -- bounded the same way v105_pitch_
    #    parity.R bounds @emlPitchArgsFAC's body -- not a whole-file grep,
    #    so a same-shaped assignment in some other procedure can never be
    #    miscounted as one of THIS procedure's codes), then hands the body
    #    to the extractor above. N = 0 is excluded since it names "no
    #    refusal", not a refusal.
    #
    #    LOUD FAILURE ON ZERO, per Finding 3's closing instruction: zero is
    #    the one count that makes eml_census's orphan comparison below
    #    pass VACUOUSLY (nothing derived, so nothing can ever be named an
    #    orphan) -- exactly the silent-shrink failure mode this finding is
    #    about, taken to its limit. A derivation that finds nothing HALTS
    #    the run outright rather than letting the census beneath it look
    #    healthy.
    # -------------------------------------------------------------------
    derive_refusal_codes <- function(path) {
        src <- readLines(path, warn = FALSE)
        decl <- grep("^\\s*procedure\\s+emlSurveyValidateDeclaration\\b", src)
        stopifnot(length(decl) == 1L)
        ends <- grep("^\\s*endproc\\b", src)
        ends <- ends[ends > decl]
        stopifnot(length(ends) >= 1L)
        body <- src[seq.int(decl, ends[1])]
        codes <- extract_refusal_assignment_codes(body)
        if (length(codes) == 0L) {
            stop("v129 derive_refusal_codes(): found ZERO '.refusal = N' ",
                 "assignments in ", path, " -- the derivation itself is ",
                 "broken (regex, procedure bounds, or the file changed out ",
                 "from under it). Refusing to let the coverage census run ",
                 "against an empty derived set, which would pass every ",
                 "orphan/phantom comparison vacuously instead of failing.")
        }
        codes
    }
    psychometrics_path <- file.path(plug, "stats", "eml-psychometrics.praat")
    derived_codes <- derive_refusal_codes(psychometrics_path)

    # THE KNOWN FLOOR, stated ONCE: refusals 1-16 exist as of this round
    # (1-14 from the two prior adversarial passes; 15-16 added this round,
    # Finding 4a/4b). An EQUALITY check, not just a floor, per Finding 3's
    # closing instruction ("a derivation that yields fewer codes ... must
    # go red on its own") -- fewer is exactly the silent-shrink failure
    # this finding is about, and more (a refusal added without updating
    # this one constant in the same commit) is the DRY rule on the same
    # finding's own terms, so both directions go red here rather than only
    # the shrink direction.
    KNOWN_REFUSAL_CODE_COUNT <- 16L
    check("v129",
        sprintf("[Finding 3] the source scan derived exactly the known %d refusal codes (neither fewer -- silent shrinkage -- nor more -- this constant not updated in the same commit)",
                KNOWN_REFUSAL_CODE_COUNT),
        length(derived_codes), KNOWN_REFUSAL_CODE_COUNT, tol = 0)

    eml_census("v129", "refusal code (needs a positive seeded-defect leg)",
               as.character(derived_codes), as.character(positive_leg_codes))
    eml_census("v129", "refusal code (needs a negative control proving its guard is load-bearing)",
               as.character(derived_codes), as.character(negative_control_codes))

    # -------------------------------------------------------------------
    # 19. THE OUTPUT CONTRACT, PROVEN EXHAUSTIVELY (V1.6, Fix 1) -- every
    #    output @emlSurveyValidateDeclaration's own Outputs header documents
    #    must hold a DEFINED value on EVERY refusal path, not just on the one
    #    (refusal 11) a prior round happened to probe. Before Fix 1, FOUR of
    #    the five documented per-scale array outputs (.scaleName$[],
    #    .scaleType$[], .scaleMin[], .scaleMax[]) were assigned only in the
    #    scales-population loop, which sits AFTER refusal 11's own exit --
    #    reading any of them following a refusal-11 return HALTED Praat with
    #    "Undefined indexed variable", verified live on all four before this
    #    round wrote a single line of fix.
    #
    #    BOTH sides of this leg are DERIVED, never hand-written, so a change
    #    on either side is caught rather than silently skipped:
    #      - the OUTPUT list comes from the procedure's own Outputs header
    #        (19a below) -- an output documented later without a seeded
    #        default is swept and caught here, not skipped because this file
    #        never learned its name;
    #      - the REFUSAL list is the SAME `derived_codes` section 18b already
    #        scanned from the procedure's own source -- a refusal added
    #        later is swept here as soon as section 18b's own equality check
    #        (line ~1685 above) is updated to admit it, not two derivations
    #        drifting apart.
    #    Both derivations assert an EXACT floor (18b's KNOWN_REFUSAL_CODE_COUNT
    #    above; 19a's KNOWN_OUTPUT_COUNT below) rather than a minimum, per
    #    Finding 3's own closing instruction: fewer than the known count is
    #    silent shrinkage and goes red on its own, not just when some other
    #    check happens to notice a missing field.
    # -------------------------------------------------------------------

    # -------------------------------------------------------------------
    # 19a. THE OUTPUT LIST, DERIVED FROM THE HEADER. Each documented output
    #    line reads "#   .name[, .name2] - prose..."; .scaleMin[1..nScales],
    #    .scaleMax[1..nScales] share ONE line, so the extractor splits on
    #    "," rather than assuming one name per line -- a naive single-name
    #    regex would silently derive one fewer output than the header
    #    actually documents, which is exactly the shrinkage Finding 3 warns
    #    against, reproduced by the extractor itself rather than by the
    #    source. An index suffix ("[1..nScales]") is stripped after
    #    splitting, not before, so it cannot swallow the comma between two
    #    names on a shared line.
    # -------------------------------------------------------------------
    derive_documented_outputs <- function(path) {
        src <- readLines(path, warn = FALSE)
        starts <- grep("^# Outputs: @emlSurveyValidateDeclaration\\s*$", src)
        stopifnot(length(starts) == 1L)
        ends <- grep("^# Access pattern:", src)
        ends <- ends[ends > starts]
        stopifnot(length(ends) >= 1L)
        body <- src[seq.int(starts[1], ends[1] - 1L)]
        name_pat <- "\\.[A-Za-z0-9_]+\\$?(?:\\[[^]]*\\])?"
        line_pat <- sprintf("^#\\s+(%s(?:\\s*,\\s*%s)*)\\s+-", name_pat, name_pat)
        out <- character(0)
        for (ln in body) {
            m <- regmatches(ln, regexec(line_pat, ln, perl = TRUE))[[1]]
            if (length(m) >= 2 && nzchar(m[2])) {
                toks <- trimws(strsplit(m[2], ",", fixed = TRUE)[[1]])
                toks <- sub("\\[[^]]*\\]$", "", toks)
                out <- c(out, toks)
            }
        }
        out <- unique(out)
        if (length(out) == 0L) {
            stop("v129 derive_documented_outputs(): found ZERO documented ",
                 "outputs in ", path, " -- the derivation itself is broken ",
                 "(regex, header markers, or the file changed out from ",
                 "under it). Refusing to let the exhaustive output-contract ",
                 "sweep run against an empty derived set, which would pass ",
                 "vacuously instead of failing.")
        }
        out
    }

    # THREE STYLES proven caught, on a synthetic header slice -- mirrors
    # 18a's own synthetic-body proof for the refusal-code extractor, applied
    # to this extractor instead:
    #   A. one name per line (the common case)
    #   B. TWO names sharing one line, comma-separated (the actual shape
    #      .scaleMin[1..nScales], .scaleMax[1..nScales] has in the real
    #      header right now -- a single-name extractor would derive only
    #      one of the two and never notice)
    #   C. an indexed array suffix stripped to the bare name
    synthetic_header <- c(
        "# Outputs: @emlSurveyValidateDeclaration",
        "# ============================================================================",
        "#   .fooBar$          - style A: one name per line",
        "#   .alpha[1..n], .beta[1..n] - style B: two names, one line, comma-separated",
        "#   .gamma$[1..n]     - style C: indexed array suffix stripped",
        "# Access pattern:")
    synthetic_outputs <- derive_documented_outputs(local({
        p <- tempfile(fileext = ".praat")
        writeLines(synthetic_header, p)
        p
    }))
    check_true("v129",
        "[Fix 1] the output extractor catches a plain one-name-per-line entry (style A, \".fooBar$\")",
        ".fooBar$" %in% synthetic_outputs)
    check_true("v129",
        "[Fix 1] the output extractor catches BOTH names on a shared, comma-separated line (style B, \".alpha[1..n], .beta[1..n]\") -- not just the first",
        all(c(".alpha", ".beta") %in% synthetic_outputs))
    check_true("v129",
        "[Fix 1] the output extractor strips an indexed array suffix down to the bare name (style C, \".gamma$[1..n]\" -> \".gamma$\")",
        ".gamma$" %in% synthetic_outputs && !(".gamma$[1..n]" %in% synthetic_outputs))
    check_true("v129",
        "[Fix 1] the extractor found exactly the four synthetic names and nothing else",
        setequal(synthetic_outputs, c(".fooBar$", ".alpha", ".beta", ".gamma$")))

    documented_outputs <- derive_documented_outputs(psychometrics_path)
    # is_array_output: a FIXED (never regex) substring test -- "is <name>["
    # present anywhere in the header body -- deliberately avoiding regex
    # metacharacter escaping for names that already contain "." and "$",
    # which is itself a needless source of the exact silent-miss bug this
    # whole leg exists to catch.
    is_array_output <- function(path, name) {
        src <- readLines(path, warn = FALSE)
        starts <- grep("^# Outputs: @emlSurveyValidateDeclaration\\s*$", src)
        ends <- grep("^# Access pattern:", src)
        ends <- ends[ends > starts[1]]
        body <- paste(src[seq.int(starts[1], ends[1] - 1L)], collapse = "\n")
        grepl(paste0(name, "["), body, fixed = TRUE)
    }
    output_is_array <- vapply(documented_outputs, is_array_output,
                              logical(1), path = psychometrics_path)

    # THE KNOWN FLOOR, stated once, same discipline as 18b's
    # KNOWN_REFUSAL_CODE_COUNT: an EQUALITY check, not just a minimum, so a
    # documented output silently dropped from the header (fewer) and an
    # output added to the header without this constant being updated in the
    # same commit (more) both go red here.
    # V1.7 (cell ruling) adds six documented outputs: .disclosureCount,
    # .disclosureSpellingCount, .disclosureItemCount, .disclosureSpelling$,
    # .disclosureItem$, .disclosure$ -- was 26, now 32.
    KNOWN_OUTPUT_COUNT <- 32L
    check("v129",
        sprintf("[Fix 1] the header scan derived exactly the known %d documented outputs (neither fewer -- a definition silently dropped from the header -- nor more -- this constant not updated in the same commit)",
                KNOWN_OUTPUT_COUNT),
        length(documented_outputs), KNOWN_OUTPUT_COUNT, tol = 0)

    # -------------------------------------------------------------------
    # 19b. THE SWEEP -- one probe per refusal code (from `derived_codes`,
    #    18b's own source-derived list), reading EVERY documented output in
    #    a single run. An array output is read at index 1 (every fixture
    #    below declares at least one scale, so index 1 always exists); a
    #    scalar output is read bare. The probe never inspects VALUES here
    #    -- correctness of what each refusal reports is asserted by its own
    #    positive leg above -- it only proves that reading the full
    #    documented set never halts, which is the one thing no leg above
    #    checks for anything but .scaleIsKR20[].
    # -------------------------------------------------------------------
    drive_output_sweep <- function(stats_dir_rel, data_path, scales_path,
                                   items_path, tag, outputs, is_array) {
        probe <- file.path(work, "scripts", paste0("v129-outsweep-", tag, ".praat"))
        esc <- function(p) gsub('"', '""', p)
        read_lines <- vapply(seq_along(outputs), function(i) {
            # outputs[i] already carries its own leading "." (derived
            # straight from the header, e.g. ".error$", ".scaleName$") --
            # concatenated directly onto the namespace prefix, not with a
            # second "." in between.
            expr <- if (is_array[i]) {
                paste0("emlSurveyValidateDeclaration", outputs[i], " [1]")
            } else {
                paste0("emlSurveyValidateDeclaration", outputs[i])
            }
            sprintf('appendInfoLine: "outread|%s|", %s', outputs[i], expr)
        }, character(1))
        writeLines(c(
            paste0("include ../", stats_dir_rel, "/eml-extract.praat"),
            paste0("include ../", stats_dir_rel, "/eml-inferential.praat"),
            paste0("include ../", stats_dir_rel, "/eml-psychometrics.praat"),
            "",
            sprintf('dataT = Read Table from comma-separated file: "%s"', esc(data_path)),
            sprintf('scalesT = Read Table from comma-separated file: "%s"', esc(scales_path)),
            sprintf('itemsT = Read Table from comma-separated file: "%s"', esc(items_path)),
            "",
            "@emlSurveyValidateDeclaration: dataT, scalesT, itemsT",
            'writeInfoLine: "v129-outsweep"',
            read_lines,
            'appendInfoLine: "outread|END|1"'),
            probe)
        suppressWarnings(system2("env",
            c("-u", "DISPLAY", shQuote(praat),
              shQuote(paste0("--pref-dir=", prefs)), "--run", shQuote(probe)),
            stdout = TRUE, stderr = TRUE))
    }
    sweep_ok <- function(out) {
        !any(grepl("^Error", out)) && any(grepl("^outread\\|END\\|1$", out))
    }

    # One seeded fixture per refusal code, reusing the SAME triples each
    # code's own positive leg above already built and proved -- never a
    # fresh mutation, so this leg cannot introduce a fixture bug of its own
    # that the positive-leg checks above did not already catch.
    refusal_fixture_paths <- list(
        `1`  = list(data = committed_data_path, scales = committed_scales_path, items = p1),
        `2`  = list(data = p2d,                 scales = committed_scales_path, items = committed_items_path),
        `3`  = list(data = committed_data_path, scales = committed_scales_path, items = p3),
        `4`  = list(data = committed_data_path, scales = committed_scales_path, items = p4),
        `5`  = list(data = committed_data_path, scales = committed_scales_path, items = p5a),
        `6`  = list(data = committed_data_path, scales = committed_scales_path, items = p6),
        `7`  = list(data = committed_data_path, scales = committed_scales_path, items = p7),
        `8`  = list(data = committed_data_path, scales = committed_scales_path, items = p8),
        `9`  = list(data = committed_data_path, scales = p9,                   items = committed_items_path),
        `10` = list(data = committed_data_path, scales = p10,                  items = committed_items_path),
        `11` = list(data = committed_data_path, scales = p11,                  items = committed_items_path),
        `12` = list(data = committed_data_path, scales = p12w,                 items = committed_items_path),
        `13` = list(data = p13d,                scales = p13,                  items = committed_items_path),
        `14` = list(data = committed_data_path, scales = p14,                  items = committed_items_path),
        `15` = list(data = p15d,                scales = committed_scales_path, items = committed_items_path),
        `16` = list(data = p16d,                scales = committed_scales_path, items = committed_items_path)
    )

    # LOUD FAILURE if a refusal the source derivation found has no
    # registered fixture -- a refusal added later without a fixture entry
    # here is caught as a named gap, not silently skipped because the sweep
    # only knows the sixteen codes that existed when it was written.
    missing_fixture_codes <- setdiff(as.character(derived_codes),
                                     names(refusal_fixture_paths))
    check_true("v129",
        sprintf("[Fix 1] every refusal code the source derivation found (%s) has a registered exhaustive-sweep fixture (missing: %s)",
                paste(derived_codes, collapse = ", "),
                if (length(missing_fixture_codes)) paste(missing_fixture_codes, collapse = ", ") else "none"),
        length(missing_fixture_codes) == 0L)

    swept_codes <- c()
    for (code_chr in names(refusal_fixture_paths)) {
        code <- as.integer(code_chr)
        if (!(code %in% derived_codes)) next
        fx <- refusal_fixture_paths[[code_chr]]
        out_sweep <- drive_output_sweep("stats", fx$data, fx$scales, fx$items,
                                        paste0("sweep", code), documented_outputs,
                                        output_is_array)
        ok <- sweep_ok(out_sweep)
        if (!ok) {
            cat(sprintf("      v129 output-contract sweep [refusal %d] output: %s\n",
                        code, paste(utils::tail(out_sweep, 12), collapse = " / ")))
        }
        check_true("v129",
            sprintf("[Fix 1] refusal %d: every documented output is readable without halting Praat", code),
            ok)
        swept_codes <- c(swept_codes, code)
    }
    # Also the clean (refusal 0) path -- not one of the sixteen refusals,
    # but every documented output is claimed to hold a defined value there
    # too (this procedure's own header: .scaleIsKR20[] etc. are only "moot"
    # once refused, never undefined, on a clean declaration).
    out_sweep_clean <- drive_output_sweep("stats", committed_data_path,
                                          committed_scales_path, committed_items_path,
                                          "sweep-clean", documented_outputs,
                                          output_is_array)
    check_true("v129",
        "[Fix 1] the clean declaration (refusal 0): every documented output is readable without halting Praat",
        sweep_ok(out_sweep_clean))

    check_true("v129",
        "[Fix 1] the exhaustive output-contract sweep actually drove all sixteen derived refusal codes (not vacuously fewer)",
        length(unique(swept_codes)) == length(derived_codes))

    # -------------------------------------------------------------------
    # 19 [Finding 5]: THE PLACEHOLDER PRE-PASS HAS A FAST PATH -- a column
    #    that numericises cleanly as a whole skips the per-cell
    #    @eml_classifyCell loop (and the scratch Table it creates per
    #    cell) entirely, via @eml_strictNumericColumn -- the plugin's own
    #    existing whole-column numeric machinery, called once per column
    #    rather than the O(n) per-cell classification the pre-fix code
    #    always ran.
    #
    #    ASSERTED AS A RELATIVE COMPARISON, not an absolute wall-clock
    #    ceiling: this container's CPU speed is not something this file
    #    controls or should assume, so the claim tested is the one
    #    Finding 5 actually makes -- the fixed build is MEANINGFULLY
    #    FASTER than the pre-fix build on the SAME clean fixture, same
    #    machine, same run -- not "elapsed < N seconds" against a number
    #    that would be a coin flip on a slower CI box. The margin (15%)
    #    is well inside the measured gap (report: 4.917s -> 8.732s on a
    #    1000x12 fixture, this file's own smaller fixture measured at
    #    roughly a 30-40% reduction) so it is not a flake risk in either
    #    direction.
    #
    #    THE MUTANT removes ONLY the fast-path block this fix added from
    #    a COPY of the (already Finding-1-fixed) source -- by LINE RANGE,
    #    located by its own distinctive comment and end marker, never a
    #    hand-typed line count -- leaving Finding 1's kind-5 widening
    #    untouched, so this negative control isolates Finding 5 alone
    #    rather than reverting to the pre-Finding-1 file (as Finding 1's
    #    own negative control above does, for exactly the opposite
    #    reason: THAT one needs the coupled pair reverted together).
    # -------------------------------------------------------------------
    perf_n <- 300
    perf_items <- c("P1", "P2", "P3", "P4", "P5", "P6", "P7", "P8", "P9")
    set.seed(20260826)
    perf_lines <- c(paste(sprintf('"%s"', perf_items), collapse = ","))
    for (r in seq_len(perf_n)) {
        perf_lines <- c(perf_lines, paste(sample(1:5, length(perf_items), replace = TRUE), collapse = ","))
    }
    perf_data_path <- write_csv_lines(perf_lines, "perf_data.csv")
    perf_items_lines <- c("item,role,reversed",
                          paste0(perf_items[1:3], ",PerfA,0"),
                          paste0(perf_items[4:6], ",PerfB,0"),
                          paste0(perf_items[7:9], ",PerfC,0"))
    perf_items_path <- write_csv_lines(perf_items_lines, "perf_items.csv")
    perf_scales_lines <- c("scale,min,max,type",
                           "PerfA,1,5,ordinal", "PerfB,1,5,ordinal", "PerfC,1,5,ordinal")
    perf_scales_path <- write_csv_lines(perf_scales_lines, "perf_scales.csv")

    drive_timed <- function(stats_dir_rel, tag) {
        probe <- file.path(work, "scripts", paste0("v129-perf-", tag, ".praat"))
        esc <- function(p) gsub('"', '""', p)
        writeLines(c(
            paste0("include ../", stats_dir_rel, "/eml-extract.praat"),
            paste0("include ../", stats_dir_rel, "/eml-inferential.praat"),
            paste0("include ../", stats_dir_rel, "/eml-psychometrics.praat"),
            "",
            sprintf('dataT = Read Table from comma-separated file: "%s"', esc(perf_data_path)),
            sprintf('scalesT = Read Table from comma-separated file: "%s"', esc(perf_scales_path)),
            sprintf('itemsT = Read Table from comma-separated file: "%s"', esc(perf_items_path)),
            "t0 = stopwatch",
            "@emlSurveyValidateDeclaration: dataT, scalesT, itemsT",
            "t1 = stopwatch - t0",
            'writeInfoLine: "res|", emlSurveyValidateDeclaration.refusal, "|END"',
            'appendInfoLine: "elapsed|", t1, "|END"'),
            probe)
        suppressWarnings(system2("env",
            c("-u", "DISPLAY", shQuote(praat), shQuote(paste0("--pref-dir=", prefs)),
              "--run", shQuote(probe)), stdout = TRUE, stderr = TRUE))
    }
    elapsed_of <- function(out) {
        row <- grep("^elapsed\\|", out, value = TRUE)
        if (!length(row)) return(NA_real_)
        suppressWarnings(as.numeric(strsplit(row[1], "|", fixed = TRUE)[[1]][2]))
    }

    # Fixed build, driven THREE times (median, not first-run, to absorb
    # one-off scheduling noise) -- same for the mutant below.
    fixed_times <- vapply(1:3, function(i) elapsed_of(drive_timed("stats", paste0("fixed", i))), 1.0)
    check_true("v129", "[Finding 5] fixed-build timing probe produced numeric elapsed values",
               all(is.finite(fixed_times)))
    fixed_median <- stats::median(fixed_times)

    scan_lines <- readLines(file.path(plug, "stats", "eml-psychometrics.praat"))
    fast_start <- grep("^    # FAST PATH, same shape as @emlAuditColumn", scan_lines)
    check_true("v129", "[Finding 5] the fast path's start marker exists in source, exactly once",
               length(fast_start) == 1)
    for_after <- grep("^    for \\.i from 1 to \\.nRows$", scan_lines)
    fast_end <- for_after[for_after > fast_start[1]][1] - 1L
    check_true("v129", "[Finding 5] the fast path's end marker (the per-cell loop it guards) was found after the start",
               length(fast_end) == 1 && !is.na(fast_end) && fast_end > fast_start[1])

    if (length(fast_start) == 1 && length(fast_end) == 1 && !is.na(fast_end) && fast_end > fast_start[1]) {
        perf_mut_lines <- scan_lines[-(fast_start[1]:fast_end)]
        perf_mutdir <- file.path(work, "m_finding5_no_fastpath")
        dir.create(perf_mutdir, showWarnings = FALSE)
        file.symlink(normalizePath(file.path(plug, "stats", "eml-extract.praat")),
                     file.path(perf_mutdir, "eml-extract.praat"))
        file.symlink(normalizePath(file.path(plug, "stats", "eml-inferential.praat")),
                     file.path(perf_mutdir, "eml-inferential.praat"))
        writeLines(perf_mut_lines, file.path(perf_mutdir, "eml-psychometrics.praat"))

        mut_times <- vapply(1:3, function(i) elapsed_of(drive_timed("m_finding5_no_fastpath", paste0("mut", i))), 1.0)
        check_true("v129", "[Finding 5] no-fast-path mutant timing probe produced numeric elapsed values",
                   all(is.finite(mut_times)))
        mut_median <- stats::median(mut_times)

        cat(sprintf("      v129 [Finding 5] timing (n=%d rows, %d columns): fixed median=%.3fs, no-fast-path median=%.3fs\n",
                    perf_n, length(perf_items), fixed_median, mut_median))

        if (red_mode) {
            cat("      EML_LANE_RED: running the standard 'is at least 15% faster' check with the\n")
            cat("      mutant standing in as the shipped build -- the next check is EXPECTED to\n")
            cat("      FAIL: the no-fast-path mutant is not faster than the real fixed build, it\n")
            cat("      is slower.\n")
            check_true("v129", "[RED] the shipped build is at least 15% faster than the fixed build on the same fixture (must go red -- the mutant, standing in for 'shipped', has no fast path and is slower, not faster)",
                       mut_median < fixed_median * 0.85)
        } else {
            check_true("v129", "[Finding 5] the fixed build (with the fast path) is at least 15% faster than the no-fast-path mutant on the same clean fixture",
                       is.finite(fixed_median) && is.finite(mut_median) && fixed_median < mut_median * 0.85)
        }
    }
}

if (!exists("EML_SUITE")) { eml_report("v129 survey declaration conformance"); eml_exit() }
