# ===========================================================================
# v132 -- the Stage 2 REPORT LAYER (scripts/eml-survey.praat +
#         @emlSurveySubscaleDisclosure, stats/eml-psychometrics.praat V1.9)
# ===========================================================================
# Drives the report layer LIVE on the committed declaration fixtures
# (evidence/csv/lane_survey_declared_{data,scales,items}.csv and
# harness/survey/fixtures/small_data.csv) and on defect-fixtures derived
# from them into tempdir() -- no broken fixture is committed.
#
# ASSERTED: structure and numbers, never wording. Every DRAFT sentence this
# file's own header says is "awaiting Ian's approval" stays unread here
# except through the LIVE VALUE of its own @emlSurveyReportLanguage
# fragment variable -- e.g. section 4 below asks "does the item-rest line
# contain the CURRENT text of emlSurveyReportLanguage.msgItemRestFlagA$",
# never a literal string typed into this file, so a wording edit in
# eml-survey.praat can never make this file disagree with itself.
#
#   1. STRUCTURE, every subscale, both the 24-respondent declared fixture
#      and the 3-respondent small_data.csv fixture (8 subscale instances):
#      every one of the "always" line-builders (@eml_survey_lineAlpha,
#      ...ItemDeleted, ...Influence, ...N, ...Reversed, ...Type,
#      ...ItemRest, ...Score) returns non-empty text, AND
#      @emlSurveyBuildSubscaleReport's assembled .text$ contains that exact
#      text verbatim (the door's assembly is not silently dropping or
#      reordering a piece a sub-builder produced).
#   2. THE REVERSED-ITEMS LINE PRINTS EVEN WHEN NOTHING IS REVERSED:
#      Knowledge (0 reversed items, both fixtures) gets a non-empty,
#      "no items reversed"-flavoured line (checked by CONTENT MATCHING THE
#      LIVE .msgReversedNone$ VARIABLE, never a literal), exactly the same
#      as Confidence/Anxiety/Ease (which do have a reversed item) get a
#      line built from .msgReversedSomeA$/.msgReversedSomeB$ instead.
#   3. THE KR-20 LINE fires exactly on Knowledge (the one declared subscale
#      whose range spans exactly two values) in both fixtures, and on no
#      other subscale in either -- checked against
#      emlSurveyScoreScales.subIsKR20[], never re-derived from min/max here.
#   4. THE ITEM-REST FLAG fires on every item whose item-rest correlation
#      is strictly below zero and ONLY those -- checked against every item
#      of every subscale in BOTH fixtures (28 items total), cross-referenced
#      against R's own cor() on the reverse-scored data. small_data.csv's
#      Knowledge subscale (B1, B2) is a genuine, un-seeded negative-item-
#      rest case (verified independently against R below); every other
#      item in both fixtures is non-negative and unflagged.
#   5. A REFUSING SUBSCALE DOES NOT SUPPRESS THE OTHERS: small_data.csv's
#      Confidence subscale refuses (n=2 after listwise deletion, below
#      @emlCronbachAlpha's n>=3 floor); Anxiety/Knowledge/Ease in the SAME
#      run still print full, unrefused blocks, and Confidence's OWN other
#      blocks (n/exclusions, reversed items, item-rest all "n/a", scale
#      score) still print despite its alpha/influence kernels refusing.
#   6. LEAVE-ONE-OUT INFLUENCE CARRIES ORIGINAL ROW NUMBERS: the 24-
#      respondent fixture has one blank cell in each of Confidence (row
#      11), Anxiety (row 5) and Ease (row 18) -- Knowledge has none. For
#      each of the three, the SET of row numbers the influence block
#      prints is asserted to be exactly {1..24} minus the excluded row
#      (never the excluded row itself, i.e. never a post-deletion position
#      standing in for it), and Knowledge's set is exactly {1..24}.
#   7. THE CSV EXPORT (@emlSurveyExportCSV) carries item_rest AND
#      item_total as raw values for every item, cross-checked against
#      evidence/oracle/lane_survey_oracle_values.csv for item_rest and
#      against an independent R recomputation for item_total; and carries
#      the three declaration file PATHS the door was given, verbatim (the
#      provenance rule).
#   8. THE PLACEHOLDER DISCLOSURE, scoped per subscale
#      (@emlSurveySubscaleDisclosure): a seeded "NA" cell in Ease's own
#      item (R1, row 2) makes ONLY Ease's disclosure block fire, naming
#      that one item and spelling; Confidence/Anxiety/Knowledge's own
#      disclosure blocks stay silent in the SAME run.
#   9. THE REFUSAL-ROUTING DEMO AT THE DOOR: a seeded "approx 4" cell (not
#      a recognised placeholder) makes @emlSurveyRunReport print NO
#      subscale report at all and echo Stage 1's own refusal, which names
#      "Check & repair data" by the same command name and menu location
#      refusal 8 itself already uses (structure: the routing phrase is
#      present; wording is v129's business, not asserted twice here).
#  10. FIVE SEEDED-DEFECT RED DEMOS, one per structural claim above that a
#      single-fixture positive leg cannot, on its own, prove would have
#      been CAUGHT if broken: dropping a block, suppressing the always-on
#      reversed line, inverting the item-rest flag's sign test, aborting
#      the report loop on a refusal, and printing a post-deletion loop
#      position instead of an original row number. Each lives in its own
#      scratch directory with REAL symlinks to every untouched dependency
#      beside its one mutated file (never editing a committed file). In
#      NORMAL mode this file only proves each seed is real (the mutant's
#      output differs from the correct build's); under EML_LANE_RED=1 the
#      SAME structural assertion sections 1/2/4/5/6 above are re-run
#      against the mutant build in place of the clean one and are expected
#      to FAIL, by name.
#
# NOT registered in validate/run_all.R: lane work, per the lane boundary.
# ===========================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

red_mode <- nzchar(Sys.getenv("EML_LANE_RED", unset = ""))

plug <- Sys.getenv("EML_PLUGIN_DIR", unset = "")
if (!nzchar(plug)) plug <- repo_path("plugin")

# ---------------------------------------------------------------------------
# 0. THE BINARY -- same floor and discovery as v129/v130/v131
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
    cat(paste0("      SKIP: v132 needs Praat >= 6.6.30 to drive the module;\n",
               "            found ", if (is.na(pv)) "none" else pv, ".\n"))
    check_true("v132",
               sprintf("a Praat at or above the plugin's floor is available (found %s)",
                       if (is.na(pv)) "none" else pv),
               FALSE)
} else {

    statsdir <- file.path(plug, "stats")
    scriptsdir <- file.path(plug, "scripts")
    csvdir <- repo_path("evidence", "csv")

    # -------------------------------------------------------------------
    # 1. Sandbox: scratch outside the tree being measured
    # -------------------------------------------------------------------
    work <- file.path(tempdir(), "v132")
    unlink(work, recursive = TRUE)
    dir.create(file.path(work, "scripts"), showWarnings = FALSE, recursive = TRUE)
    dir.create(file.path(work, "csv"), showWarnings = FALSE, recursive = TRUE)
    prefs <- file.path(work, "prefs")
    dir.create(prefs, showWarnings = FALSE)
    unlink(file.path(prefs, c("pid", "message")))

    clean_dir <- file.path(work, "clean")
    dir.create(clean_dir, showWarnings = FALSE, recursive = TRUE)
    link_deps <- function(dirpath, psych_path = NULL, survey_path = NULL) {
        dir.create(dirpath, recursive = TRUE, showWarnings = FALSE)
        for (f in c("eml-core-utilities.praat", "eml-extract.praat",
                    "eml-inferential.praat", "eml-analysis.praat",
                    "eml-output.praat")) {
            file.symlink(normalizePath(file.path(statsdir, f)),
                         file.path(dirpath, f))
        }
        if (is.null(psych_path)) {
            file.symlink(normalizePath(file.path(statsdir, "eml-psychometrics.praat")),
                         file.path(dirpath, "eml-psychometrics.praat"))
        } else {
            file.copy(psych_path, file.path(dirpath, "eml-psychometrics.praat"))
        }
        if (is.null(survey_path)) {
            file.symlink(normalizePath(file.path(scriptsdir, "eml-survey.praat")),
                         file.path(dirpath, "eml-survey.praat"))
        } else {
            file.copy(survey_path, file.path(dirpath, "eml-survey.praat"))
        }
    }
    link_deps(clean_dir)

    committed_data_path   <- file.path(csvdir, "lane_survey_declared_data.csv")
    committed_scales_path <- file.path(csvdir, "lane_survey_declared_scales.csv")
    committed_items_path  <- file.path(csvdir, "lane_survey_declared_items.csv")
    small_data_path        <- repo_path("harness", "survey", "fixtures", "small_data.csv")

    clean_data_lines <- readLines(committed_data_path, warn = FALSE)

    header_index <- function(lines, col_name) {
        hdr <- strsplit(lines[1], ",", fixed = TRUE)[[1]]
        which(gsub('"', "", hdr) == col_name)
    }
    edit_field <- function(lines, row_1based, col_name, new_value) {
        ci <- header_index(lines, col_name)
        stopifnot(length(ci) == 1)
        cells <- strsplit(lines[row_1based + 1L], ",", fixed = TRUE)[[1]]
        cells[ci] <- new_value
        lines[row_1based + 1L] <- paste(cells, collapse = ",")
        lines
    }
    write_csv_lines <- function(lines, name) {
        p <- file.path(work, "csv", name)
        writeLines(lines, p)
        p
    }
    esc <- function(p) gsub('"', '""', p)

    # -------------------------------------------------------------------
    # 2. THE DRIVER -- builds a probe against one stats/scripts directory
    #    (the clean symlinked one, or a mutant), one data fixture, and
    #    dumps a rich tagged report of the report layer's raw facts:
    #    per-subscale line-builder presence + containment in the
    #    assembled text, per-item item-rest/flag/reversed, per-respondent
    #    ORIGINAL row numbers from the influence block, KR-20 and
    #    disclosure presence, and the door's own top-level behaviour.
    # -------------------------------------------------------------------
    drive_report <- function(dirlabel, data_path, scales_path, items_path, tag,
                             also_door = FALSE, csv_export = FALSE) {
        probe <- file.path(work, "scripts", paste0("v132-", tag, ".praat"))
        csv_path <- file.path(work, "csv", paste0("export-", tag, ".csv"))
        lines <- c(
            paste0("include ../", dirlabel, "/eml-core-utilities.praat"),
            paste0("include ../", dirlabel, "/eml-extract.praat"),
            paste0("include ../", dirlabel, "/eml-inferential.praat"),
            paste0("include ../", dirlabel, "/eml-analysis.praat"),
            paste0("include ../", dirlabel, "/eml-output.praat"),
            paste0("include ../", dirlabel, "/eml-psychometrics.praat"),
            paste0("include ../", dirlabel, "/eml-survey.praat"),
            "",
            sprintf('dataT = Read Table from comma-separated file: "%s"', esc(data_path)),
            sprintf('scalesT = Read Table from comma-separated file: "%s"', esc(scales_path)),
            sprintf('itemsT = Read Table from comma-separated file: "%s"', esc(items_path)),
            "",
            "@emlSurveyValidateDeclaration: dataT, scalesT, itemsT",
            'writeInfoLine: "refusal|", emlSurveyValidateDeclaration.refusal, "|END"',
            "if emlSurveyValidateDeclaration.refusal = 0",
            "    @emlSurveyScoreScales: dataT",
            "    for s from 1 to emlSurveyScoreScales.nScales",
            '        name$ = emlSurveyValidateDeclaration.scaleName$[s]',
            "        @emlSurveyBuildSubscaleReport: dataT, s",
            '        text$ = emlSurveyBuildSubscaleReport.text$',
            "        @eml_survey_lineAlpha: s",
            "        @eml_survey_lineItemDeleted: s",
            "        @eml_survey_lineInfluence: s",
            "        lastOrigRow = -1",
            '        if emlSurveyScoreScales.subInfluenceError$[s] = ""',
            "            lastOrigRow = eml_survey_lineInfluence.origRow",
            "        endif",
            "        @eml_survey_lineN: s",
            "        @eml_survey_lineReversed: s",
            "        @eml_survey_lineType: s",
            "        @eml_survey_lineKR20: s",
            "        @eml_survey_lineItemRest: s",
            "        @eml_survey_lineDisclosure: dataT, s",
            "        @eml_survey_lineScore: s",
            '        appendInfoLine: "BLK|", s, "|", name$, "|",',
            '        ... length (eml_survey_lineAlpha.line$) > 0, "|",',
            '        ... length (eml_survey_lineItemDeleted.line$) > 0, "|",',
            '        ... length (eml_survey_lineInfluence.line$) > 0, "|",',
            '        ... length (eml_survey_lineN.line$) > 0, "|",',
            '        ... length (eml_survey_lineReversed.line$) > 0, "|",',
            '        ... length (eml_survey_lineType.line$) > 0, "|",',
            '        ... length (eml_survey_lineItemRest.line$) > 0, "|",',
            '        ... length (eml_survey_lineScore.line$) > 0, "|",',
            '        ... eml_survey_lineKR20.present, "|",',
            '        ... emlSurveyScoreScales.subIsKR20[s], "|",',
            '        ... eml_survey_lineReversed.n, "|",',
            '        ... eml_survey_lineDisclosure.present, "|",',
            '        ... emlSurveySubscaleDisclosure.count, "|",',
            '        ... emlSurveySubscaleDisclosure.cellCount, "|",',
            '        ... (index (text$, eml_survey_lineAlpha.line$) > 0), "|",',
            '        ... (index (text$, eml_survey_lineItemDeleted.line$) > 0), "|",',
            '        ... (index (text$, eml_survey_lineInfluence.line$) > 0), "|",',
            '        ... (index (text$, eml_survey_lineN.line$) > 0), "|",',
            '        ... (index (text$, eml_survey_lineReversed.line$) > 0), "|",',
            '        ... (index (text$, eml_survey_lineType.line$) > 0), "|",',
            '        ... (index (text$, eml_survey_lineItemRest.line$) > 0), "|",',
            '        ... (index (text$, eml_survey_lineScore.line$) > 0), "|",',
            '        ... (index (eml_survey_lineReversed.line$,',
            '        ... emlSurveyReportLanguage.msgReversedNone$) > 0), "|",',
            # Field 23: the ORIGINAL row number @eml_survey_lineInfluence
            # ITSELF (not emlSurveyScoreScales read directly) last placed
            # into its own .origRow while building .line$ -- i.e. the
            # report layer's own procedure, exercised on its own mutated
            # or unmutated body, rather than a value read straight out of
            # the untouched computational layer. Meaningful only when the
            # influence kernel did not refuse (the loop that sets it never
            # runs otherwise); "-1" (a value no real row number can be)
            # when it refused, so a caller need not guard every read.
            "        ... lastOrigRow, \"|\",",
            '        ... "END"',
            "        if emlSurveySubscaleDisclosure.count > 0",
            '            appendInfoLine: "DISCITEM|", s, "|",',
            '            ... emlSurveySubscaleDisclosure.item$[1], "|",',
            '            ... emlSurveySubscaleDisclosure.spelling$[1], "|END"',
            "        endif",
            "        for j from 1 to emlSurveyScoreScales.subK[s]",
            "            origIdx = emlSurveyScoreScales.subItemOrigIdx[s,j]",
            '            iname$ = emlSurveyValidateDeclaration.itemName$[origIdx]',
            '            hasFlagText = 0',
            "            if emlSurveyScoreScales.subItemFlag[s,j] = 1",
            '                hasFlagText = index (eml_survey_lineItemRest.line$,',
            '                ... emlSurveyReportLanguage.msgItemRestFlagA$) > 0',
            "            endif",
            '            appendInfoLine: "ITEM|", s, "|", j, "|", iname$, "|",',
            '            ... emlSurveyScoreScales.subItemRest[s,j], "|",',
            '            ... emlSurveyScoreScales.subItemTotal[s,j], "|",',
            '            ... emlSurveyScoreScales.subItemFlag[s,j], "|",',
            '            ... hasFlagText, "|END"',
            "        endfor",
            "        if emlSurveyScoreScales.subInfluenceError$[s] = \"\"",
            "            for r from 1 to emlSurveyScoreScales.subN[s]",
            '                appendInfoLine: "INFLROW|", s, "|",',
            '                ... emlSurveyScoreScales.subRowIndex[s,r], "|END"',
            "            endfor",
            "        endif",
            "    endfor",
            if (csv_export) sprintf(
                '    @emlSurveyExportCSV: dataT, "%s", "%s", "%s", "%s"',
                esc(data_path), esc(items_path), esc(scales_path), esc(csv_path)
            ) else NULL,
            "endif"
        )
        if (also_door) {
            lines <- c(lines,
                sprintf('doorDataPath$ = "%s"', esc(data_path)),
                sprintf('doorItemsPath$ = "%s"', esc(items_path)),
                sprintf('doorScalesPath$ = "%s"', esc(scales_path)),
                'appendInfoLine: "DOORSTART"',
                '@emlSurveyRunReport: doorDataPath$, doorItemsPath$, doorScalesPath$, ""',
                'appendInfoLine: "DOOREND"')
        }
        writeLines(lines, probe)
        out <- suppressWarnings(system2("env",
            c("-u", "DISPLAY", shQuote(praat),
              shQuote(paste0("--pref-dir=", prefs)), "--run", shQuote(probe)),
            stdout = TRUE, stderr = TRUE))
        attr(out, "csv_path") <- csv_path
        out
    }

    fld <- function(out, tag) {
        p <- sprintf("^%s\\|", tag)
        h <- grep(p, out, value = TRUE)
        if (!length(h)) return(character(0))
        strsplit(sub(p, "", h[1]), "|", fixed = TRUE)[[1]]
    }
    fld_all <- function(out, tag) {
        p <- sprintf("^%s\\|", tag)
        h <- grep(p, out, value = TRUE)
        lapply(h, function(x) strsplit(sub(p, "", x), "|", fixed = TRUE)[[1]])
    }
    str_ <- function(fs, i) if (length(fs) < i) NA_character_ else fs[i]
    num_ <- function(fs, i) {
        v <- str_(fs, i)
        if (is.na(v) || identical(v, "--undefined--")) return(NA_real_)
        suppressWarnings(as.numeric(v))
    }
    ran_ok <- function(out) !any(grepl("^Error", out)) && length(fld(out, "refusal")) >= 1

    # -------------------------------------------------------------------
    # 3. CLEAN STRUCTURAL DRIVE, both fixtures
    # -------------------------------------------------------------------
    scale_names <- c("Confidence", "Anxiety", "Knowledge", "Ease")
    excluded_row <- c(Confidence = 11L, Anxiety = 5L, Knowledge = NA_integer_, Ease = 18L)

    run_structure <- function(dirlabel, data_path, tag, expect_excluded, drive_out = NULL,
                              total_rows = 24, skip_influence = character(0)) {
        if (is.null(drive_out)) {
            drive_out <- drive_report(dirlabel, data_path, committed_scales_path,
                                      committed_items_path, tag)
        }
        blk <- fld_all(drive_out, "BLK")
        for (row in blk) {
            s <- as.integer(row[1]); name <- row[2]
            get <- function(i) row[3 + i]  # fields after s,name start at index 3
            # Field order after s,name (0-based offsets into the BLK payload):
            # 0 alphaLen 1 itemDelLen 2 inflLen 3 nLen 4 reversedLen 5 typeLen
            # 6 itemRestLen 7 scoreLen 8 kr20Present 9 subIsKR20 10 reversedN
            # 11 discPresent 12 discCount 13 discCellCount
            # 14..21 containment (alpha,itemDel,infl,n,reversed,type,itemRest,score)
            # 22 reversedNoneMatch
            always <- c("alpha" = get(0), "itemDel" = get(1), "infl" = get(2),
                       "n" = get(3), "reversed" = get(4), "type" = get(5),
                       "itemRest" = get(6), "score" = get(7))
            for (nm in names(always)) {
                check_true("v132", sprintf("[%s] subscale %s: %s line is non-empty", tag, name, nm),
                           identical(always[[nm]], "1"))
            }
            contains <- c("alpha" = get(14), "itemDel" = get(15), "infl" = get(16),
                          "n" = get(17), "reversed" = get(18), "type" = get(19),
                          "itemRest" = get(20), "score" = get(21))
            for (nm in names(contains)) {
                check_true("v132", sprintf("[%s] subscale %s: assembled report text contains the %s block verbatim", tag, name, nm),
                           identical(contains[[nm]], "1"))
            }
            check("v132", sprintf("[%s] subscale %s: KR-20 line presence matches subIsKR20", tag, name),
                  as.numeric(get(8)), as.numeric(get(9)), tol = 0)
            expect_kr20 <- if (identical(name, "Knowledge")) 1 else 0
            check("v132", sprintf("[%s] subscale %s: KR-20 line fires exactly when expected", tag, name),
                  as.numeric(get(8)), expect_kr20, tol = 0)
            check_true("v132", sprintf("[%s] subscale %s: reversed-items line prints even when reversedN is 0", tag, name),
                       identical(always[["reversed"]], "1"))
            if (identical(name, "Knowledge")) {
                check_true("v132", sprintf("[%s] Knowledge: reversedN is 0 and the line matches the live msgReversedNone$ fragment", tag),
                           identical(get(10), "0") && identical(get(22), "1"))
            } else {
                check_true("v132", sprintf("[%s] %s: reversedN is > 0 (has a genuinely reversed item)", tag, name),
                           as.numeric(get(10)) > 0)
            }
        }
        # Influence original-row-number set, per subscale (skipped for a
        # subscale whose influence kernel refuses outright -- there is no
        # row-set to check a mapping on).
        infl <- fld_all(drive_out, "INFLROW")
        for (nm in scale_names) {
            if (nm %in% skip_influence) next
            s <- match(nm, scale_names)
            rows <- sort(as.integer(vapply(infl, function(r) if (as.integer(r[1]) == s) r[2] else NA_character_,
                                          character(1))))
            rows <- rows[!is.na(rows)]
            expect_excl <- expect_excluded[[nm]]
            full <- seq_len(total_rows)
            expect_set <- if (is.na(expect_excl)) full else setdiff(full, expect_excl)
            check_true("v132", sprintf("[%s] %s: influence prints exactly the ORIGINAL row numbers %s (never the excluded row, never a post-deletion position standing in for it)",
                                       tag, nm, if (is.na(expect_excl)) sprintf("1..%d", total_rows) else paste0("1..", total_rows, " minus ", expect_excl)),
                       identical(rows, as.integer(expect_set)))
        }
        drive_out
    }

    if (identical(basename(committed_data_path), "lane_survey_declared_data.csv")) {
        # canary: confirm the three planted blanks this section relies on are
        # still genuinely blank in the committed fixture (same three v129
        # itself already confirms independently for the SAME reason).
        chk <- vapply(list(c(11, "Q2"), c(5, "Q6"), c(18, "R2")), function(loc) {
            i <- as.integer(loc[1]) + 1L
            raw <- strsplit(clean_data_lines[i], ",", fixed = TRUE)[[1]]
            ci <- header_index(clean_data_lines, loc[2])
            length(ci) == 1 && (length(raw) < ci || !nzchar(trimws(raw[ci])))
        }, logical(1))
        check_true("v132", "the three planted missing cells this section relies on (row11/Q2, row5/Q6, row18/R2) are genuinely blank in the committed fixture",
                   all(chk))
    }

    out_main <- run_structure("clean", committed_data_path, "main", excluded_row)
    check_true("v132", "[main] probe ran cleanly", ran_ok(out_main))
    check("v132", "[main] refusal is 0", num_(fld(out_main, "refusal"), 1), 0, tol = 0)

    # small_data.csv's own listwise exclusion is Confidence row 1 (blank Q1),
    # but Confidence's kernels REFUSE outright (n=2 < 3), so there is no
    # influence block to check an original-row SET against for it; the other
    # three subscales have no missing cell in this 3-row fixture at all, so
    # their own influence sets are simply {1,2,3}.
    small_excluded <- c(Confidence = NA_integer_, Anxiety = NA_integer_,
                        Knowledge = NA_integer_, Ease = NA_integer_)
    out_small_raw <- run_structure("clean", small_data_path, "small", small_excluded,
                                   total_rows = 3, skip_influence = "Confidence")
    check_true("v132", "[small] probe ran cleanly", ran_ok(out_small_raw))
    check("v132", "[small] refusal is 0 (the declaration itself is sound; only Confidence's KERNEL refuses downstream)",
          num_(fld(out_small_raw, "refusal"), 1), 0, tol = 0)

    blk_small <- fld_all(out_small_raw, "BLK")
    check_true("v132", "[small] all 4 subscales produced a BLK row (none suppressed by Confidence's refusal)",
               length(blk_small) == 4)

    # -------------------------------------------------------------------
    # 4. ITEM-REST FLAG: fires on negative and only negative, cross-checked
    #    against R's own cor() on the reverse-scored data, across BOTH
    #    fixtures (28 items total: 4 subscales x (4+3+3+3) items x 2 fixtures
    #    minus Confidence's 4 n/a items in the small fixture).
    # -------------------------------------------------------------------
    check_items <- function(tag, out, data_path) {
        d <- read.csv(data_path, stringsAsFactors = FALSE, check.names = FALSE)
        scales <- read.csv(committed_scales_path, stringsAsFactors = FALSE)
        items  <- read.csv(committed_items_path, stringsAsFactors = FALSE)
        its <- fld_all(out, "ITEM")
        any_neg_seen <- FALSE
        for (row in its) {
            s <- as.integer(row[1]); j <- as.integer(row[2]); iname <- row[3]
            rest_p <- num_(row, 4); flag_p <- suppressWarnings(as.integer(row[6]))
            hasFlagText <- identical(row[7], "1")
            if (is.na(rest_p)) next  # n/a item (too few complete cases) -- covered by [small] Confidence
            scaleName <- scale_names[s]
            itemNames <- items$item[items$role == scaleName]
            mat <- d[, itemNames, drop = FALSE]
            for (nm2 in itemNames) {
                if (items$reversed[items$item == nm2] == 1) {
                    r2 <- scales[scales$scale == scaleName, ]
                    mat[[nm2]] <- r2$min + r2$max - mat[[nm2]]
                }
            }
            total <- rowSums(mat)
            rest_vec <- total - mat[[iname]]
            r_computed <- suppressWarnings(cor(mat[[iname]], rest_vec,
                                              use = "complete.obs"))
            check("v132", sprintf("[%s] item-rest for %s (subscale %s, item %d) matches independent R recomputation",
                                 tag, iname, scaleName, j),
                  rest_p, r_computed, tol = 1e-6)
            expect_flag <- if (is.na(r_computed)) NA else as.integer(r_computed < 0)
            if (!is.na(expect_flag)) {
                check("v132", sprintf("[%s] item-rest flag for %s (subscale %s) is 1 iff r < 0 (r = %.6f)",
                                     tag, iname, scaleName, r_computed),
                      flag_p, expect_flag, tol = 0)
                if (expect_flag == 1) {
                    any_neg_seen <- TRUE
                    check_true("v132", sprintf("[%s] item-rest line for %s carries the LIVE evidence-flag fragment (never a literal copy of it) when flagged",
                                              tag, iname),
                               hasFlagText)
                } else {
                    check_true("v132", sprintf("[%s] item-rest line for %s does NOT carry the flag fragment when r >= 0",
                                              tag, iname),
                               !hasFlagText)
                }
            }
        }
        any_neg_seen
    }
    check_items("main", out_main, committed_data_path)
    saw_negative <- check_items("small", out_small_raw, small_data_path)
    check_true("v132", "at least one genuinely negative item-rest correlation was observed across the two fixtures (the flag's positive case is exercised on real, un-mutated data, not asserted vacuously)",
               isTRUE(saw_negative))

    # -------------------------------------------------------------------
    # 5. PLACEHOLDER DISCLOSURE, scoped per subscale: seed "NA" onto
    #    Ease's own item R1, row 2 (the same cell v129's own demo 1 uses).
    # -------------------------------------------------------------------
    data_na <- edit_field(clean_data_lines, 2, "R1", "NA")
    p_na <- write_csv_lines(data_na, "na_data.csv")
    out_na <- drive_report("clean", p_na, committed_scales_path, committed_items_path, "na")
    check_true("v132", "[disclosure demo] probe ran cleanly", ran_ok(out_na))
    check("v132", "[disclosure demo] refusal stays 0 (a recognised placeholder is missingness, not a refusal)",
          num_(fld(out_na, "refusal"), 1), 0, tol = 0)
    blk_na <- fld_all(out_na, "BLK")
    disc_na <- fld_all(out_na, "DISCITEM")
    for (row in blk_na) {
        s <- as.integer(row[1]); name <- row[2]
        present <- row[3 + 11]
        expect_present <- if (identical(name, "Ease")) "1" else "0"
        check_true("v132", sprintf("[disclosure demo] subscale %s: per-subscale disclosure presence is %s as expected",
                                  name, expect_present),
                   identical(present, expect_present))
    }
    check_true("v132", "[disclosure demo] exactly one subscale (Ease) reported a DISCITEM row",
               length(disc_na) == 1 && disc_na[[1]][1] == "4")
    if (length(disc_na) == 1) {
        check_true("v132", "[disclosure demo] Ease's disclosed item is \"R1\"",
                   identical(disc_na[[1]][2], "R1"))
        check_true("v132", "[disclosure demo] Ease's disclosed spelling is \"NA\"",
                   identical(disc_na[[1]][3], "NA"))
    }

    # -------------------------------------------------------------------
    # 6. THE DOOR-LEVEL REFUSAL-ROUTING DEMO: a seeded "approx 4" cell (NOT
    #    a recognised placeholder) refuses at the door, printing no
    #    subscale report and echoing Stage 1's own routing sentence.
    # -------------------------------------------------------------------
    data_bad <- edit_field(clean_data_lines, 2, "R1", "approx 4")
    p_bad <- write_csv_lines(data_bad, "bad_data.csv")
    door_probe <- file.path(work, "scripts", "v132-door-bad.praat")
    writeLines(c(
        "include ../clean/eml-core-utilities.praat",
        "include ../clean/eml-extract.praat",
        "include ../clean/eml-inferential.praat",
        "include ../clean/eml-analysis.praat",
        "include ../clean/eml-output.praat",
        "include ../clean/eml-psychometrics.praat",
        "include ../clean/eml-survey.praat",
        "",
        'writeInfoLine: "DOORSTART"',
        sprintf('@emlSurveyRunReport: "%s", "%s", "%s", ""',
               esc(p_bad), esc(committed_items_path), esc(committed_scales_path)),
        'appendInfoLine: "DOOREND"'),
        door_probe)
    out_bad <- suppressWarnings(system2("env",
        c("-u", "DISPLAY", shQuote(praat), shQuote(paste0("--pref-dir=", prefs)),
          "--run", shQuote(door_probe)), stdout = TRUE, stderr = TRUE))
    check_true("v132", "[refusal-routing demo] door probe ran without a Praat error",
               !any(grepl("^Error", out_bad)))
    check_true("v132", "[refusal-routing demo] no subscale report was printed (no \"--- Subscale:\" line)",
               !any(grepl("^--- Subscale:", out_bad)))
    check_true("v132", "[refusal-routing demo] the door echoes the routing phrase naming \"Check & repair data\" by command name",
               any(grepl("Check & repair data", out_bad, fixed = TRUE)))
    check_true("v132", "[refusal-routing demo] the door echoes the routing phrase naming the menu location",
               any(grepl("Objects > New > EML Stats & Graphs > Check & repair data",
                        out_bad, fixed = TRUE)))

    # -------------------------------------------------------------------
    # 7. THE CSV EXPORT: item_rest / item_total as raw values, and
    #    provenance-by-path.
    # -------------------------------------------------------------------
    out_export <- drive_report("clean", committed_data_path, committed_scales_path,
                               committed_items_path, "export", csv_export = TRUE)
    check_true("v132", "[csv export] probe ran cleanly", ran_ok(out_export))
    csv_path <- attr(out_export, "csv_path")
    check_true("v132", "[csv export] the export file was written", file.exists(csv_path))
    if (file.exists(csv_path)) {
        exp <- read.csv(csv_path, stringsAsFactors = FALSE)
        oracle_path <- repo_path("validate", "oracle", "lane_survey_oracle_values.csv")
        oracle <- read.csv(oracle_path, header = FALSE,
                           col.names = c("key", "value", "tol"),
                           stringsAsFactors = FALSE)
        get_oracle <- function(key) oracle$value[oracle$key == key][1]

        item_probes <- list(
            c("Confidence", "Q1"), c("Anxiety", "Q5"),
            c("Knowledge", "B1"), c("Ease", "R1")
        )
        for (ip in item_probes) {
            scaleName <- ip[1]; item <- ip[2]
            r_row <- exp[exp$term == item & exp$field == "item_rest", ]
            t_row <- exp[exp$term == item & exp$field == "item_total", ]
            check_true("v132", sprintf("[csv export] %s (%s): item_rest row is present", item, scaleName),
                       nrow(r_row) == 1)
            check_true("v132", sprintf("[csv export] %s (%s): item_total row is present", item, scaleName),
                       nrow(t_row) == 1)
            if (nrow(r_row) == 1) {
                okey <- sprintf("declared_%s_itemrest_%s", scaleName, item)
                oval <- suppressWarnings(as.numeric(get_oracle(okey)))
                if (!is.na(oval)) {
                    check("v132", sprintf("[csv export] %s (%s): item_rest matches the committed oracle", item, scaleName),
                          suppressWarnings(as.numeric(r_row$value[1])), oval, tol = 1e-8)
                }
            }
            if (nrow(t_row) == 1) {
                check_true("v132", sprintf("[csv export] %s (%s): item_total is a finite raw number",
                                          item, scaleName),
                           is.finite(suppressWarnings(as.numeric(t_row$value[1]))))
            }
        }
        prov <- list(items_file = committed_items_path, scales_file = committed_scales_path,
                    data_file = committed_data_path)
        for (fld_name in names(prov)) {
            row <- exp[exp$field == fld_name, ]
            check_true("v132", sprintf("[csv export] provenance row \"%s\" is present and cites the file BY PATH", fld_name),
                       nrow(row) == 1 && identical(row$value[1], prov[[fld_name]]))
        }
    }

    # -------------------------------------------------------------------
    # 8. RED-MODE MUTANTS -- five seeded defects, each isolating one
    #    structural claim above. REAL symlinks to every untouched
    #    dependency sit beside each mutant's one edited file.
    # -------------------------------------------------------------------
    survey_src <- readLines(file.path(scriptsdir, "eml-survey.praat"), warn = FALSE)
    psych_src  <- readLines(file.path(statsdir, "eml-psychometrics.praat"), warn = FALSE)

    mutate_survey <- function(needle, replacement, must_change = TRUE) {
        txt <- paste(survey_src, collapse = "\n")
        stopifnot(grepl(needle, txt, fixed = TRUE))
        new_txt <- sub(needle, replacement, txt, fixed = TRUE)
        if (must_change) stopifnot(!identical(new_txt, txt))
        p <- tempfile(fileext = ".praat")
        writeLines(new_txt, p)
        p
    }
    mutate_psych <- function(needle, replacement) {
        txt <- paste(psych_src, collapse = "\n")
        stopifnot(grepl(needle, txt, fixed = TRUE))
        new_txt <- sub(needle, replacement, txt, fixed = TRUE)
        stopifnot(!identical(new_txt, txt))
        p <- tempfile(fileext = ".praat")
        writeLines(new_txt, p)
        p
    }

    # M1: drop_block -- the "n / exclusions:" append vanishes from the
    # assembled report for EVERY subscale. Isolates claim 1 (every
    # promised line is present for every subscale).
    m1_path <- mutate_survey(
        '    @eml_survey_lineN: .s\n    .text$ = .text$ + newline$ + "n / exclusions: " + eml_survey_lineN.line$\n\n',
        "\n")
    m1_dir <- file.path(work, "m1_drop_block")
    link_deps(m1_dir, survey_path = m1_path)

    # M2: reversed_suppress -- the reversed-items line is only appended
    # when something IS reversed. Isolates claim 2.
    m2_path <- mutate_survey(
        '    @eml_survey_lineReversed: .s\n    .text$ = .text$ + newline$ + "Reversed items: " + eml_survey_lineReversed.line$\n',
        '    @eml_survey_lineReversed: .s\n    if eml_survey_lineReversed.n > 0\n        .text$ = .text$ + newline$ + "Reversed items: " + eml_survey_lineReversed.line$\n    endif\n')
    m2_dir <- file.path(work, "m2_reversed_suppress")
    link_deps(m2_dir, survey_path = m2_path)

    # M3: flag_invert -- the item-rest flag fires on r > 0 instead of
    # r < 0, in @emlSurveyScoreScales itself. Isolates claim 4.
    m3_path <- mutate_psych(
        "                    if emlPearsonCorrelation.r < 0\n                        .subItemFlag[.s,.j] = 1\n",
        "                    if emlPearsonCorrelation.r > 0\n                        .subItemFlag[.s,.j] = 1\n")
    m3_dir <- file.path(work, "m3_flag_invert")
    link_deps(m3_dir, psych_path = m3_path)

    # M4: loop_abort -- the report loop stops after the first subscale
    # whose alpha kernel refused, suppressing every later subscale in the
    # same run. Isolates claim 5.
    m4_path <- mutate_survey(
        '        for .s from 1 to emlSurveyScoreScales.nScales\n            @emlSurveyReportSubscale: .dataTableId, .s\n        endfor\n',
        '        .stopped = 0\n        for .s from 1 to emlSurveyScoreScales.nScales\n            if .stopped = 0\n                @emlSurveyReportSubscale: .dataTableId, .s\n                if emlSurveyScoreScales.subAlphaError$[.s] <> ""\n                    .stopped = 1\n                endif\n            endif\n        endfor\n')
    m4_dir <- file.path(work, "m4_loop_abort")
    link_deps(m4_dir, survey_path = m4_path)

    # M5: orig_row -- the influence block prints the post-deletion loop
    # position instead of the original row number. Isolates claim 6.
    m5_path <- mutate_survey(
        '            .origRow = emlSurveyScoreScales.subRowIndex[.s, .r]\n',
        "            .origRow = .r\n")
    m5_dir <- file.path(work, "m5_orig_row")
    link_deps(m5_dir, survey_path = m5_path)

    # M4 has to be exercised through the DOOR (@emlSurveyRunReport) itself,
    # never the probe's own per-subscale dump loop -- that loop calls
    # @emlSurveyBuildSubscaleReport directly and never touches the report
    # LOOP @emlSurveyRunReport owns, which is the one M4 mutates. Counted
    # by the number of "--- Subscale:" banner lines the door itself prints.
    door_subscale_count <- function(dirlabel, data_path) {
        out <- drive_report(dirlabel, data_path, committed_scales_path,
                            committed_items_path, paste0("door-", dirlabel),
                            also_door = TRUE)
        sum(grepl("^--- Subscale:", out))
    }

    if (!red_mode) {
        # Prove each seed is real: the mutant's behaviour DIFFERS from the
        # correct build's, on the exact case the mutation targets.

        # M1: "n / exclusions" must vanish from the ASSEMBLED report text
        # for every subscale (field 17 = CONTAINS, not field 3 = the
        # standalone builder's own non-empty check -- @eml_survey_lineN
        # itself is untouched by M1, only the ASSEMBLY call site is, so
        # only the containment field can see this mutation).
        out_m1 <- drive_report("m1_drop_block", committed_data_path, committed_scales_path,
                               committed_items_path, "m1")
        blk_m1 <- fld_all(out_m1, "BLK")
        contains_n_m1 <- vapply(blk_m1, function(r) r[3 + 17], character(1))
        check_true("v132", "[M1 seed] mutant differs from correct: the assembled report no longer contains the n/exclusions block, for every subscale (correct build: contains it)",
                   length(blk_m1) == 4 && all(contains_n_m1 == "0"))

        # M2: same reasoning -- @eml_survey_lineReversed itself still
        # returns non-empty text standalone; only Knowledge's ASSEMBLED
        # text (field 18) stops containing it.
        out_m2 <- drive_report("m2_reversed_suppress", committed_data_path, committed_scales_path,
                               committed_items_path, "m2")
        blk_m2 <- fld_all(out_m2, "BLK")
        know_m2 <- blk_m2[[which(vapply(blk_m2, function(r) r[2] == "Knowledge", logical(1)))]]
        check_true("v132", "[M2 seed] mutant differs from correct: Knowledge's ASSEMBLED report no longer contains its reversed-items line (correct build: contains the \"none reversed\" line)",
                   identical(know_m2[3 + 18], "0"))

        out_m3 <- drive_report("m3_flag_invert", small_data_path, committed_scales_path,
                               committed_items_path, "m3")
        its_m3 <- fld_all(out_m3, "ITEM")
        b1_m3 <- its_m3[[which(vapply(its_m3, function(r) r[1] == "3" && r[3] == "B1", logical(1)))]]
        check_true("v132", "[M3 seed] mutant differs from correct: Knowledge's B1 (a genuinely negative item-rest item) is now UNFLAGGED (correct build: flagged)",
                   identical(b1_m3[6], "0"))

        # M4: only the DOOR's own subscale count sees this mutation.
        n_m4 <- door_subscale_count("m4_loop_abort", small_data_path)
        check_true("v132", "[M4 seed] mutant differs from correct: the door prints only 1 subscale after Confidence's refusal (correct build: all 4)",
                   n_m4 == 1)

        # M5: eml_survey_lineInfluence's OWN last-placed .origRow (field
        # 26), not emlSurveyScoreScales.subRowIndex[] read directly --
        # M5 mutates only the report-layer procedure, not the value it
        # reads from. Anxiety's excluded row is 5 (not the last row), so
        # the LAST surviving respondent's original row is 24 under
        # correct code and 23 (the loop position) under the mutant.
        out_m5 <- drive_report("m5_orig_row", committed_data_path, committed_scales_path,
                               committed_items_path, "m5")
        blk_m5 <- fld_all(out_m5, "BLK")
        anx_m5 <- blk_m5[[which(vapply(blk_m5, function(r) r[2] == "Anxiety", logical(1)))]]
        check_true("v132", "[M5 seed] mutant differs from correct: Anxiety's influence line now reports original row 23 for its last respondent, not 24 (a post-deletion position standing in for the original row)",
                   identical(anx_m5[3 + 23], "23"))
    } else {
        # RED MODE: re-run the real structural assertions against each
        # mutant build and watch them fail, by name.
        out_m1 <- drive_report("m1_drop_block", committed_data_path, committed_scales_path,
                               committed_items_path, "m1red")
        blk_m1 <- fld_all(out_m1, "BLK")
        for (row in blk_m1) {
            check_true("v132", sprintf("[RED, M1] subscale %s: assembled report text contains the n block verbatim", row[2]),
                       identical(row[3 + 17], "1"))
        }

        out_m2 <- drive_report("m2_reversed_suppress", committed_data_path, committed_scales_path,
                               committed_items_path, "m2red")
        blk_m2 <- fld_all(out_m2, "BLK")
        for (row in blk_m2) {
            check_true("v132", sprintf("[RED, M2] subscale %s: assembled report text contains the reversed block verbatim (prints even when nothing is reversed)", row[2]),
                       identical(row[3 + 18], "1"))
        }

        out_m3 <- drive_report("m3_flag_invert", small_data_path, committed_scales_path,
                               committed_items_path, "m3red")
        check_items("RED, M3", out_m3, small_data_path)

        n_m4 <- door_subscale_count("m4_loop_abort", small_data_path)
        check_true("v132", "[RED, M4] a refusing subscale does not suppress the others (the door prints all 4 subscales)",
                   n_m4 == 4)

        out_m5 <- drive_report("m5_orig_row", committed_data_path, committed_scales_path,
                               committed_items_path, "m5red")
        blk_m5 <- fld_all(out_m5, "BLK")
        anx_m5 <- blk_m5[[which(vapply(blk_m5, function(r) r[2] == "Anxiety", logical(1)))]]
        check_true("v132", "[RED, M5] Anxiety's influence line reports original row 24 for its last respondent (not a post-deletion position)",
                   identical(anx_m5[3 + 23], "24"))
    }

    eml_report("v132 -- survey report layer")
    eml_exit()
}
