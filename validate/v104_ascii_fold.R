# ============================================================================
# v104_ascii_fold.R -- the file that landed is readable, byte by byte
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS FILE IS ABOUT. Praat 6.6.30's default output encoding is
# "try ASCII, then UTF-16" and the "try" is decided per FILE. One non-ASCII
# character anywhere in the content and the WHOLE file is written UTF-16BE with
# a byte-order mark -- measured in this container with a fresh pref-dir, and
# written up at the top of harness/asciifold/run.sh with the byte counts. A
# _results.csv that differs from a good one by one Greek letter in one group
# label is not a slightly odd CSV. It is a file read.csv, pandas, Excel and
# this repository's own validate/ scripts all treat as binary, produced by a
# run that succeeded and warned about nothing.
#
# @emlAsciiFold guards that, at the two places text becomes bytes:
# @emlReportToFile folds the report body, @eml_csvQuote folds each cell. Until
# harness/asciifold existed, no check in this tree drove one non-ASCII
# character through either of them.
#
# WHY THE POPULATION IS FILES ON DISK AND NOT THE PROCEDURE. The failure mode
# is not "the fold maps the wrong character" -- it is "the fold is not
# reached". A unit test of @emlAsciiFold stays green on a build with both call
# sites deleted, while every file the plugin writes turns to UTF-16. So this
# file never calls the fold. It opens what the SAVERS wrote and reads the
# bytes, with readBin, which is the only way to see a NUL: read.csv and
# readLines both mangle or refuse a UTF-16 file rather than describing it.
#
# THREE QUESTIONS PER FILE, and the third is the one that is easy to leave out.
#
#   1. Is every byte ASCII?          -- did the fold run at all
#   2. Is there a BOM or a NUL byte? -- this is what the damage LOOKS like to
#      the tools that meet it; a file can be all-ASCII by accident of content
#      and still carry a mark, and asserting both is what distinguishes
#      "folded" from "happened not to contain anything"
#   3. Did the meaning survive?      -- a fold that replaced every non-ASCII
#      character with "" would pass 1 and 2 perfectly and would silently empty
#      a user's group labels. So the substitutions are enumerated: chi^2 for
#      the chi-square symbol, +/- for plus-minus, a straight quote for a curly
#      one, "?" for the one character with no sensible transliteration -- and
#      the report's LINE and TAB structure, because the sweep is written
#      [^\x01-\x7F] rather than "printable" precisely so 0x09 and 0x0A survive.
#
# THE CSV IS READ WITH read.csv AND NOT WITH grep. "Readable" is not a property
# of the bytes, it is a property of what a reader gets back, and the cell that
# proves it is the one whose curly quotes the fold turns into STRAIGHT quotes:
# folded after the quote test, that cell reaches disk as a bare " inside an
# unquoted field, and read.csv returns `singer said it felt easy` with the
# quotes silently dropped and reports no error. The byte checks cannot see
# that. Only the round trip can.
#
# THE PIN AT SECTION 6 IS A KNOWN DEFECT, NOT A PREFERENCE. The accented-vowel
# rules are written as regex classes containing both cases and replacing with
# the lowercase letter, so "Ténor Éric" folds to "Tenor eric" and a table named
# "Étude" folds to "etude". The meaning survives and the file opens, which is
# the whole point of the fold, but the capital is gone. It is pinned to the
# measured string here, the way D15 is pinned in v06: when eml-output.praat
# learns the uppercase classes, this check goes red and names itself, which is
# the only way a wart gets fixed rather than forgotten.
#
# WHAT IS DELIBERATELY NOT ASSERTED. harness/asciifold's `broom` leg drives
# @emlResultWrite, the three-file exporter, which quotes through @eml_rwQuote --
# a second RFC 4180 routine that does not fold -- and its frames land UTF-16
# today. That is recorded in out/WITNESS.tsv and reported here as an attested
# measurement, not as a pass or a fail, because the fix belongs to
# stats/eml-result-writer.praat and a validator that failed on it would be
# failing on a defect it is not the check for.
#
# Run:  Rscript validate/v104_ascii_fold.R
# Reads: harness/asciifold/out  ($EML_ASCIIFOLD_DIR overrides, which is how the
#        no-fold build is judged).
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

af <- Sys.getenv("EML_ASCIIFOLD_DIR", unset = "")
if (!nzchar(af)) af <- repo_path(file.path("harness", "asciifold", "out"))

# ---------------------------------------------------------------------------
# raw_bytes -- the file as bytes, or NULL.
#
# NEVER readLines OR read.csv FOR THIS. Both are the tools whose behaviour on a
# UTF-16 file is the defect: readLines returns the whole file as one unreadable
# element, read.csv either errors or returns a single garbage column, and in
# neither case can the caller ask "was there a NUL". readBin with what="raw"
# reports the file, not an interpretation of it.
# ---------------------------------------------------------------------------
raw_bytes <- function(p) {
    if (!file.exists(p)) return(NULL)
    n <- file.info(p)$size
    if (!is.finite(n) || n <= 0) return(NULL)
    readBin(p, what = "raw", n = n)
}

# ---------------------------------------------------------------------------
# outputs -- one leg's key/value evidence file, as a named character vector.
#
# The driver appends these line by line as it goes, so a leg that died halfway
# still has the keys it got to. A missing key therefore MEANS something and is
# not treated as an empty string.
# ---------------------------------------------------------------------------
outputs <- function(leg) {
    p <- file.path(af, paste0(leg, ".outputs.tsv"))
    if (!file.exists(p)) return(character(0))
    ln <- readLines(p, warn = FALSE)
    ln <- ln[nzchar(ln)]
    kv <- strsplit(ln, "\t", fixed = TRUE)
    kv <- Filter(function(x) length(x) >= 1, kv)
    setNames(vapply(kv, function(x) if (length(x) > 1) x[2] else "", ""),
             vapply(kv, `[`, "", 1))
}

# ---------------------------------------------------------------------------
# ascii_verdicts -- the three byte-level questions, asked of one file.
#
# ASKED AS THREE CHECKS AND NOT AS ONE. "The file is clean" collapses three
# different failures into one line, and they fail for different reasons and get
# fixed in different places: a non-ASCII byte says the fold did not run, a NUL
# says Praat re-encoded, a BOM says so even when the rest happens to look fine.
# When this goes red the point is to know WHICH.
# ---------------------------------------------------------------------------
ascii_verdicts <- function(tag, p) {
    b <- raw_bytes(p)
    if (is.null(b)) {
        check_true("v104", sprintf("%s: the saver wrote a non-empty file", tag), FALSE)
        return(invisible(FALSE))
    }
    check_true("v104", sprintf("%s: the saver wrote a non-empty file", tag), TRUE)

    nonascii <- sum(as.integer(b) > 127L)
    check("v104", sprintf("%s: bytes outside ASCII", tag),
          0, nonascii, tol = 0)

    nul <- sum(b == as.raw(0))
    check("v104", sprintf("%s: NUL bytes (a UTF-16 file, to a UTF-8 reader)", tag),
          0, nul, tol = 0)

    # BOTH BOMS. UTF-16BE is what 6.6.30 wrote in every probe, but a build or a
    # platform that chose LE would produce an equally unreadable file and an
    # LE-only check would call it clean.
    bom <- length(b) >= 2 &&
           ((b[1] == as.raw(0xFE) && b[2] == as.raw(0xFF)) ||
            (b[1] == as.raw(0xFF) && b[2] == as.raw(0xFE)))
    check_true("v104", sprintf("%s: no UTF-16 byte-order mark", tag), !bom)

    # AND THE UTF-8 BOM, which is a different animal and still wrong here: it is
    # all-ASCII-legal by byte value in no sense -- ef bb bf are all above 127 --
    # but naming it separately is what turns "three odd bytes" into a diagnosis.
    bom8 <- length(b) >= 3 && b[1] == as.raw(0xEF) &&
            b[2] == as.raw(0xBB) && b[3] == as.raw(0xBF)
    check_true("v104", sprintf("%s: no UTF-8 byte-order mark", tag), !bom8)

    invisible(nonascii == 0 && nul == 0 && !bom && !bom8)
}

legs <- c("report", "csv", "info")

# ---------------------------------------------------------------------------
# 1. THE HARNESS RAN, AND RAN ALL OF IT
# ---------------------------------------------------------------------------
# A leg that never started leaves no outputs.tsv, and every check below it
# would then be asserting about a file that was never written -- which fails,
# but fails with the wrong story. This section makes the missing leg the
# headline.
for (leg in c(legs, "broom")) {
    o <- outputs(leg)
    check_true("v104", sprintf("%s: the leg reached the end of the driver", leg),
               isTRUE(unname(o["DONE"]) == leg))
}

# ---------------------------------------------------------------------------
# 2. THE REPORT WRITER -- @emlReportToFile
# ---------------------------------------------------------------------------
o <- outputs("report")
rp <- unname(o["path"])
check_true("v104", "report: the writer reported success", isTRUE(o["success"] == "1"))
check_true("v104", "report: the writer reported it had folded something",
           isTRUE(o["folded"] == "1"))
if (is.na(rp) || !nzchar(rp)) {
    check_true("v104", "report: the writer named the file it wrote", FALSE); FALSE
} else {
    check_true("v104", "report: the writer named the file it wrote", TRUE)
    ascii_verdicts("report", rp)
}

if (!is.na(rp) && file.exists(rp)) {
    txt <- readLines(rp, warn = FALSE)
    body <- paste(txt, collapse = "\n")

    # --- the substitutions, one check each -------------------------------
    # ENUMERATED, NOT SPOT-CHECKED. Each row is a class of character that
    # reaches a saved file by a different route, and each is asserted by the
    # ASCII it must have become. A single "does it contain chi^2" would pass on
    # a fold that had lost every other rule.
    subs <- list(
        c("box rule (U+2550) became =",        "================================"),
        c("light rule (U+2500) became -",      "--------------------------------"),
        c("em dash (U+2014) became --",        "EML Stats -- Reanalyse"),
        c("middle dot (U+00B7) became -",      "Reanalyse - Sopranos"),
        c("chi-square (U+03C7 U+00B2) became chi^2", "chi^2(2) = 6.41"),
        c("less-or-equal (U+2264) became <=",  "p <= .05"),
        c("eta-square (U+03B7 U+00B2) became eta^2", "eta^2 = 0.31"),
        c("en dash (U+2013) became -",         "F0 220-440 Hz"),
        c("plus-minus (U+00B1) became +/-",    "+/-3 dB"),
        c("minus (U+2212) became -",           "tilt -6"),
        c("degree (U+00B0) became ' deg'",     "-6 deg,"),
        c("sigma (U+03C3) became sigma",       "sigma = 1.2"),
        c("curly double quotes became straight", "said \"it felt easy\""),
        c("curly single quotes became straight", "then 'open'."),
        c("right arrow (U+2192) became ->",    "3 -> best"),
        c("rho (U+03C1) became rho",           "rho ~ .48"),
        c("almost-equal (U+2248) became ~",    "~ .48"),
        c("y-bar (U+0233) became y-bar",       "y-bar = 3.1")
    )
    for (s in subs) {
        check_true("v104", paste0("report: ", s[1]),
                   grepl(s[2], body, fixed = TRUE))
    }

    # --- the unmappable one ----------------------------------------------
    # AN EMOJI HAS NO TRANSLITERATION and must become "?" -- readable as "a
    # character was here", which is what the reader needs, rather than a blank,
    # which reads as a field the user left empty.
    check_true("v104", "report: the emoji became a visible ?",
               grepl("Take ? 3 -> best", body, fixed = TRUE))
    # EXACTLY ONE "?", and this is the check that says the named rules fired
    # BEFORE the sweep. Ordered the other way round, every character above
    # would also be "?" -- still ASCII, still no NUL, still passing every byte
    # check in section 2, and completely useless to read.
    check("v104", "report: '?' appears once and only once",
          1, length(gregexpr("?", body, fixed = TRUE)[[1]]), tol = 0)

    # --- the structure ----------------------------------------------------
    # THE LINES. writeFileLine: adds one trailing newline, the driver wrote
    # eight lines, and @emlReportToFile appends a blank line and the disclosure
    # note when it folded: 8 + 1 blank + 1 note = 10. A sweep written
    # "printable" instead of [^\x01-\x7F] would eat the newlines and hand back
    # one long line of perfectly good ASCII.
    check("v104", "report: line structure survived the fold",
          10, length(txt), tol = 0)
    # THE TABS. Same argument, different control character: the group row is
    # tab-separated and must still be.
    check("v104", "report: the tab stops in the group row survived",
          3, length(gregexpr("\t", txt[6], fixed = TRUE)[[1]]), tol = 0)

    # --- the disclosure ---------------------------------------------------
    # A READER COMPARING THIS FILE WITH THE INFO WINDOW sees "chi^2" where the
    # window said the symbol, and has to be told why. The note is the shipped
    # user-facing sentence and is asserted here so an edit that drops it is a
    # failure rather than a quiet loss.
    check_true("v104", "report: the fold disclosed itself in plain English",
               any(grepl("outside plain ASCII were replaced", txt, fixed = TRUE)))
    check_true("v104", "report: the disclosure says where the original is",
               any(grepl("The Info window shows the original.", txt, fixed = TRUE)))
}

# ---------------------------------------------------------------------------
# 3. THE CSV WRITER -- @emlExportStatsCSV through @eml_csvQuote
# ---------------------------------------------------------------------------
o <- outputs("csv")
cp <- unname(o["path"])
check_true("v104", "csv: the writer reported success", isTRUE(o["success"] == "1"))
check_true("v104", "csv: the writer reported five rows", isTRUE(o["rows"] == "5"))
if (is.na(cp) || !nzchar(cp)) {
    check_true("v104", "csv: the writer named the file it wrote", FALSE); FALSE
} else {
    check_true("v104", "csv: the writer named the file it wrote", TRUE)
    ascii_verdicts("csv", cp)
}

# THE ROUND TRIP, RUN WHATEVER THE BYTES SAID. It is tempting to skip this
# when the byte checks have already failed, and it would be wrong: "readable"
# is not a property of the bytes, it is what a reader gets back, and the two
# are not the same claim. MEASURED on the no-fold build, 20 Aug 2026:
# read.csv on the UTF-16 file does NOT abort. It warns about embedded nulls and
# returns a 5x1 data frame whose single column is named "X..", every value NA.
# That is the user's experience of this defect -- not an error they can act on
# but a frame that is silently the wrong shape -- so it is asserted here rather
# than skipped. tryCatch is kept because an abort is possible on other inputs
# and a validator that dies describes nothing; suppressWarnings keeps six
# embedded-null warnings from burying the verdict lines.
dcsv <- tryCatch(suppressWarnings(read.csv(cp, stringsAsFactors = FALSE)),
                 error = function(e) NULL)
if (TRUE) {
    d <- dcsv
    if (is.null(d)) {
        check_true("v104", "csv: read.csv could open the file", FALSE)
    } else {
        check_true("v104", "csv: read.csv could open the file", TRUE)
        check("v104", "csv: rows read back", 5, nrow(d), tol = 0)
        check("v104", "csv: columns read back", 6, ncol(d), tol = 0)
        check_true("v104", "csv: the shipped header survived unchanged",
                   identical(names(d),
                             c("table", "analysis", "term", "term_type",
                               "field", "value")))

        # THE CELL THIS WHOLE PLACEMENT ARGUMENT IS ABOUT. The driver wrote
        # curly quotes; the fold turns them into straight ones; @eml_csvQuote
        # folds FIRST, so the quote test sees them and the cell is quoted and
        # doubled. Folded after the test, this comes back without its quotes
        # and read.csv reports nothing wrong.
        check_true("v104", "csv: the curly-quoted cell round-tripped with its quotes",
                   identical(d$value[1], "singer said \"it felt easy\""))
        # THE CONTROL. This cell contained a comma before any folding, so it
        # was going to be quoted either way; if it round-trips and the one
        # above does not, the fault is the fold's placement and not the quoter.
        check_true("v104", "csv: the comma cell round-tripped as one field",
                   identical(d$value[2], "220-440 Hz, +/-3 dB"))

        check_true("v104", "csv: chi-square and eta-square became chi^2 and eta^2",
                   identical(d$value[3], "chi^2 and eta^2"))
        check_true("v104", "csv: the emoji cell became a visible ?, not a blank",
                   identical(d$value[4], "take ? 3 at 20 degC"))
        check_true("v104", "csv: the numeric cell was untouched",
                   identical(d$value[5], "220.5"))
        # NO CELL WAS EMPTIED. The one way to pass every byte check and still
        # destroy the export is to fold non-ASCII to nothing, and every value
        # the driver wrote was non-empty.
        # length() IS PART OF THE CLAIM. On a frame that came back the wrong
        # shape d$value is NULL, and sum(!nzchar(trimws(NULL))) is 0 -- this
        # check would pass, vacuously, on the exact file it exists to condemn.
        check("v104", "csv: cells emptied by the fold", 0,
              if (length(d$value) == 5L) sum(!nzchar(trimws(d$value))) else -1,
              tol = 0)

        # AND NO NOTE WAS APPENDED. @emlReportToFile adds a line of English
        # when it folded; on a .csv that line is not a disclosure, it is a
        # malformed row, and every reader reports it as one. The suppression is
        # by extension, so this is the check that it holds.
        last <- tail(readLines(cp, warn = FALSE), 1)
        check_true("v104", "csv: no disclosure prose was appended to the CSV",
                   !grepl("outside plain ASCII", last, fixed = TRUE))
        check("v104", "csv: the file is exactly header plus five data rows",
              6, length(readLines(cp, warn = FALSE)), tol = 0)
    }
}

# ---------------------------------------------------------------------------
# 4. THE INFO-WINDOW SAVER -- @emlSaveInfoToFile
# ---------------------------------------------------------------------------
# A SEPARATE ENTRY POINT, not a duplicate of section 2. @emlSaveInfoToFile
# takes info$ () -- the screen text, which is deliberately NOT folded, box
# rules and Greek and all -- and hands it to @emlReportToFile. It is the one
# path where the unfolded text is guaranteed to be the input, so it is the one
# that proves the fold sits at the writer rather than at the reporters.
o <- outputs("info")
ip <- unname(o["path"])
check_true("v104", "info: the saver reported success", isTRUE(o["success"] == "1"))
if (is.na(ip) || !nzchar(ip)) {
    check_true("v104", "info: the saver named the file it wrote", FALSE)
} else {
    check_true("v104", "info: the saver named the file it wrote", TRUE)
    ascii_verdicts("info", ip)
    itxt <- paste(readLines(ip, warn = FALSE), collapse = "\n")
    check_true("v104", "info: the Info window's chi-square reached disk as chi^2",
               grepl("chi^2(2) = 6.41", itxt, fixed = TRUE))
    check_true("v104", "info: the Info window's curly quotes reached disk straight",
               grepl("said \"it felt easy\"", itxt, fixed = TRUE))
}

# ---------------------------------------------------------------------------
# 5. THE HARNESS'S OWN BYTE CENSUS AGREES WITH THIS FILE
# ---------------------------------------------------------------------------
# TWO INDEPENDENT MEASUREMENTS OF THE SAME BYTES, one by `tr`/`od` in the shell
# and one by readBin here. They can only disagree if one of them is reading a
# different file than it thinks -- which is exactly what a stale out/ produces,
# and stale evidence reads as a pass.
cen <- file.path(af, "BYTES.tsv")
if (file.exists(cen)) {
    b <- read.delim(cen, stringsAsFactors = FALSE, colClasses = "character")
    for (leg in legs) {
        p <- unname(outputs(leg)["path"])
        if (is.na(p) || !nzchar(p)) next
        row <- b[b$name == basename(p), , drop = FALSE]
        check_true("v104", sprintf("%s: the harness census lists the file", leg),
                   nrow(row) == 1)
        if (nrow(row) == 1) {
            check("v104", sprintf("%s: shell and R agree on the byte count", leg),
                  as.numeric(row$bytes[1]), length(raw_bytes(p)), tol = 0)
            check("v104", sprintf("%s: shell and R agree there is no non-ASCII", leg),
                  as.numeric(row$nonascii[1]), 0, tol = 0)
        }
    }
} else {
    check_true("v104", "the harness wrote its byte census", FALSE)
}

# ---------------------------------------------------------------------------
# 6. THE PIN -- uppercase accented letters lose their case
# ---------------------------------------------------------------------------
# The accented rules in @emlAsciiFold are regex classes holding both cases and
# replacing with the LOWERCASE letter, so a German or French group label comes
# back de-capitalised: "Ténor Éric" -> "Tenor eric", table "Étude" -> "etude".
# The file opens and the name is still recognisable, which is the fold doing
# its job; the capital is still gone, which is a fidelity loss a user will see
# in every row of their export.
#
# PINNED TO THE MEASURED STRING rather than written the way it ought to be, for
# the reason v06 pins D15: a check that asserts the desired behaviour of an
# unfixed defect is red from the day it is written and gets muted. This one is
# green, and goes red the moment eml-output.praat gains the uppercase classes --
# at which point the fix has arrived and this section is updated to "Tenor Eric"
# in the same edit.
if (TRUE) {
    d <- dcsv
    if (!is.null(d)) {
        check_true("v104",
                   "PIN: accented capitals fold to lowercase (E-acute -> e) [defect]",
                   identical(d$term[2], "Tenor eric") &&
                   identical(d$table[1], "etude - Sopranos"))
        # The lowercase side is not a defect and must keep working; separated so
        # the pin above can be deleted without taking this with it.
        check_true("v104", "lowercase accented vowels fold to their base letter",
                   identical(d$term[4], "Nino"))
    }
}

# ---------------------------------------------------------------------------
# 7. THE WITNESS -- the three-file broom exporter does NOT fold
# ---------------------------------------------------------------------------
# ATTESTED, NOT ASSERTED. @emlResultWrite quotes through @eml_rwQuote, a second
# RFC 4180 routine with no fold in it, so tidy/glance/augment land UTF-16 the
# moment a group label carries an accent. Recorded here as a measurement so the
# gap has a number attached to it and cannot be argued about; failing on it
# would be this file failing on a defect in a procedure it is not the check
# for. The fix belongs in stats/eml-result-writer.praat.
wit <- file.path(af, "WITNESS.tsv")
if (file.exists(wit)) {
    w <- tryCatch(read.delim(wit, stringsAsFactors = FALSE,
                             colClasses = "character"),
                  error = function(e) NULL)
    if (!is.null(w) && nrow(w) > 0) {
        cat("\n-- WITNESS: the broom three-file exporter, measured not asserted --\n")
        for (i in seq_len(nrow(w))) {
            cat(sprintf("   %-22s %6s bytes  bom=%-6s nul=%-4s non-ascii=%s\n",
                        w$name[i], w$bytes[i], w$bom[i], w$nul[i], w$nonascii[i]))
        }
        cat("   @eml_rwQuote does not call @emlAsciiFold; see docs/OPEN_ITEMS.md\n")
    }
}
# The one thing that IS asserted about the witness: that it was taken. A
# measurement that quietly stops being made is how a known gap becomes an
# unknown one.
check_true("v104", "witness: the broom frames were measured and recorded",
           file.exists(wit) && length(readLines(wit, warn = FALSE)) > 1)

# ---------------------------------------------------------------------------
# 8. COVERAGE ACCOUNTING
# ---------------------------------------------------------------------------
# The population is the leg list read off the artefact folder, not the vector
# this file loops over, so a leg added to the harness and to nothing else
# surfaces as an orphan instead of passing silently.
present_legs <- sub("\\.outputs\\.tsv$", "",
                    basename(Sys.glob(file.path(af, "*.outputs.tsv"))))
eml_census("v104", "asciifold leg",
           present = present_legs,
           accounted = c(legs, "broom"))
eml_claim("v104", "asciifold", present_legs)

if (!exists("EML_SUITE")) {
    eml_report("v104 ascii fold: what lands on disk is plain, readable ASCII")
    eml_exit()
}
