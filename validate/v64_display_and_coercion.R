# ============================================================================
# v64_display_and_coercion.R -- what the Info window is allowed to print
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS FILE EXISTS. On 15 August 2026 the Describe path, driven on a
# Matrix that had been coerced to a Table, printed
#
#     Skewness            -0.0000000000000001
#
# into the Info window (the auditor's leg2_mx_describe.info.txt), from a line
# of source that reads `fixed$ (.value, 4)` and could not look more innocent.
# AUTHOR RULING, 15 August 2026: no raw double may reach the Info window.
# Statistics print at fixed four decimals and p in APA style; full precision
# belongs to the CSV export, which is the artefact a reader is meant to
# compute from. The report is for reading.
#
# THE DEFECT IS IN THE FORMATTER, NOT IN THE STATISTIC, and that distinction
# is the whole reason this file is a display validator rather than a numeric
# one. The skewness of a symmetric column is zero, and floating-point
# arithmetic lands a few ulps away from zero rather than on it -- which is
# correct, and which every statistics package does. What was wrong was
# printing those ulps. Nothing in this file asserts a VALUE; the plugin's
# numbers were right before this change and are byte-for-byte the same after
# it. What is asserted is the WIDTH of a printed field.
#
# WHAT THE MECHANISM ACTUALLY IS, and it is not skewness and not Describe and
# not the Matrix route. Praat's fixed$ does not format to the precision it is
# given. It formats to the LARGER of that precision and however many decimals
# are needed to show one significant digit -- so it is a MINIMUM-significance
# formatter wearing a fixed-precision name. Measured on the binary under test
# in section 2 below, rather than quoted from a manual:
#
#     fixed$ (-1e-16, 4)  ->  "-0.0000000000000001"    17 decimals, not 4
#     fixed$ (0.0004,  2)  ->  "0.0004"                 4 decimals, not 2
#     fixed$ (0.6,     0)  ->  "0.6"                    1 decimal, not 0
#     fixed$ (0,       4)  ->  "0"                      0 decimals, not 4
#
# Every rounded number this plugin prints went through that call. So the leak
# was never one line: it was one line PER STATISTIC THAT CAN SIT NEAR ZERO,
# which in a statistics tool is most of them -- the t of two identical means,
# a Cohen's d of no difference, a confidence bound on a null result, a
# residual mean, an eta-squared of nothing. The repair is a single formatter,
# @eml_fixed, and section 1 pins that it is the ONLY caller of fixed$ left in
# the module, because one unrouted call site is how the second one arrives.
#
# The last row above is the same defect with its sign reversed and is worth
# stating separately: an exact zero prints as a bare "0" in a column of
# "1.2910"-shaped neighbours, so the one number a reader most wants to
# recognise at a glance is the only one that does not line up.
#
# WHAT COULD NOT HAVE CAUGHT IT, AND WHY.
#
#   - THE NUMERIC VALIDATORS. v01-v22 recompute each statistic in R and
#     compare to the printed value with `check(reported, computed, tol)`.
#     Reading "-0.0000000000000001" as a number gives -1e-16, and
#     abs(-1e-16 - 0) is comfortably inside every tolerance in the tree. The
#     printed string is WRONG and the printed VALUE is RIGHT, so a validator
#     that parses before it compares is blind to this class by construction.
#     That is not a gap in those files; it is what they are for.
#
#   - v57_export_integrity.R AND THE CSV CHECKS. They read the exported files,
#     where full precision is not merely allowed but required. A check that
#     the CSV carries 17 digits and a check that the report carries 4 are
#     opposite assertions over two artefacts, and only the second one is here.
#
#   - ANY RED PATH. Nothing fails. No error, no warning, no refusal, no
#     modal. The wrapper opens, runs, prints and offers to save. The only
#     symptom is a reader's eye.
#
#   - A GOLDEN-FILE DIFF OF THE COMMITTED EVIDENCE. It would have shown the
#     string -- evidence/info/rp_r6_describe_info.txt line 156 carries
#     "Skewness 0.000000000000004" today -- but no validator reads that file,
#     and a golden file only says "this changed", never "this was always
#     wrong". The leak was IN the committed evidence, undetected, which is the
#     strongest argument available for asserting the shape rather than
#     freezing the bytes.
#
# ALSO HERE: TWO COERCION FINDINGS THAT ARE NOT PARITY FINDINGS.
# v63_coercion_parity.R is about one Matrix seen through three doors, so it
# owns the source-index numbering of Column_<n> (ruling 5) and the
# one-source-one-Table property (ruling 8a) -- both are per-door facts that
# only mean anything compared across doors. Ruling 3 is not. It is a single
# path's export vocabulary, it touches no coercion, and it is MEASURED here
# rather than asserted for the reason section 4 gives at length: its repair
# lives in two files this change does not own.
#
#     Rscript validate/v64_display_and_coercion.R
#
# NOT A MEMBER of validate/run_all.R's list -- that file is not this change's
# to edit, and v64 launches Praat. Run it directly, and run it on any change
# to a report line, a formatter or a coercion.
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
# 0. THE BINARY -- same floor and the same refusal as harness/_env.sh and v63
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

srcOut <- file.path(plug, "stats", "eml-output.praat")
srcAna <- file.path(plug, "stats", "eml-analysis.praat")
srcWri <- file.path(plug, "stats", "eml-result-writer.praat")

# ---------------------------------------------------------------------------
# 1. ONE DOOR TO fixed$ -- read statically, so this holds without a binary
# ---------------------------------------------------------------------------
# A formatter with one caller can be fixed once. A formatter with fourteen
# callers is a convention, and a convention is what this defect already was:
# every one of those fourteen sites was written by somebody who believed
# fixed$ meant fixed. So the shape of the repair is itself the thing to pin --
# not "the skewness line is routed" but "nothing in this module calls fixed$
# except the formatter". A new report line added next month inherits the fix
# by having nowhere else to go.
#
# Comment and semicolon lines are excluded because this file's own subject is
# discussed at length in that module's prose, and a census that counts prose
# is a census that moves when somebody edits a comment. That is v63's rule for
# its `To Table: "row"` door count, and it is here for the same reason.
check_true("v64", "stats/eml-output.praat is present", file.exists(srcOut))

if (file.exists(srcOut)) {
    out <- readLines(srcOut, warn = FALSE)
    code <- out[!grepl("^\\s*[#;]", out)]
    check_true("v64", "@eml_fixed is where the fixed-width formatter lives",
               any(grepl("^procedure eml_fixed: ", code)))

    i0 <- grep("^procedure eml_fixed: ", code)
    i1 <- if (length(i0)) grep("^endproc", code)[grep("^endproc", code) > i0[1]][1]
          else NA_integer_
    inside <- if (length(i0) == 1 && !is.na(i1)) i0[1]:i1 else integer(0)
    hits <- grep("fixed\\$\\s*\\(", code)
    outside <- setdiff(hits, inside)
    check_true("v64",
               sprintf("every fixed$ call in the module is inside @eml_fixed (%d inside, %d outside)",
                       length(intersect(hits, inside)), length(outside)),
               length(inside) > 0 && length(outside) == 0)
    if (length(outside)) {
        cat("      NOTE v64: fixed$ called outside @eml_fixed at:\n")
        for (ln in outside) cat(sprintf("            %s\n", trimws(code[ln])))
    }
    # AND THE ROW PRINTER USES IT. The census above would still pass if
    # @emlReportLine stopped printing numbers altogether, so the one call site
    # every statistic in the report goes through is named explicitly.
    j0 <- grep("^procedure emlReportLine: ", code)
    j1 <- if (length(j0)) grep("^endproc", code)[grep("^endproc", code) > j0[1]][1]
          else NA_integer_
    body <- if (length(j0) == 1 && !is.na(j1)) code[j0[1]:j1] else character(0)
    check_true("v64",
               "@emlReportLine formats its value through @eml_fixed",
               any(grepl("@eml_fixed:", body)))
}

# ---------------------------------------------------------------------------
# 2. THE LIVE DRIVE
# ---------------------------------------------------------------------------
if (!canDrive) {
    cat(sprintf(paste0("      NOTE v64: LIVE EVIDENCE MISSING.\n",
                       "            Praat here is %s; the plugin floors at 6.6.30\n",
                       "            (plugin/setup.praat), and a drive below the floor\n",
                       "            is not evidence -- least of all for this file,\n",
                       "            whose subject is one binary's formatter.\n",
                       "            Static checks above still hold.\n"),
                if (is.na(pv)) "not found" else pv))
    check_true("v64",
               sprintf("a Praat at or above the plugin's floor is available (found %s)",
                       if (is.na(pv)) "none" else pv),
               FALSE)
} else {
    work <- file.path(tempdir(), "v64")
    unlink(work, recursive = TRUE)
    dir.create(file.path(work, "scripts"), showWarnings = FALSE, recursive = TRUE)
    dir.create(file.path(work, "out"), showWarnings = FALSE, recursive = TRUE)
    prefs <- file.path(work, "prefs")
    dir.create(prefs, showWarnings = FALSE)
    # A stale lock from a crashed run makes the next Praat refuse to start, and
    # a refusal at startup reads here as a report that printed nothing. Only
    # these two files, and only in this scratch folder.
    unlink(file.path(prefs, c("pid", "message")))

    # THE SANDBOX IS SYMLINKS, as v63's is: Praat resolves a relative include
    # against the TOP-LEVEL script's folder, and a validator that writes its
    # scratch into the tree it is measuring has started changing that tree.
    for (d in c("stats", "graphs")) {
        tgt <- file.path(work, d)
        if (!file.exists(tgt)) file.symlink(normalizePath(file.path(plug, d)), tgt)
    }
    for (f in list.files(file.path(plug, "scripts"), pattern = "^eml-lib.*\\.praat$")) {
        tgt <- file.path(work, "scripts", f)
        if (!file.exists(tgt))
            file.symlink(normalizePath(file.path(plug, "scripts", f)), tgt)
    }

    probe <- file.path(work, "scripts", "v64-probe.praat")
    writeLines(c(
        'include eml-lib.praat',
        'outDir$ = "../out"',
        '',
        '# --- 2a. PRAAT\'S OWN fixed$, MEASURED ON THIS BINARY ---------------',
        '# The premise of the whole file, driven rather than remembered. If a',
        '# future Praat fixes this itself, these lines say so and the repair',
        '# above becomes belt and braces rather than load-bearing -- which is',
        '# a fact worth having stated, not discovered.',
        'writeInfoLine: "v64 probe"',
        'appendInfoLine: "raw|tiny4|", fixed$ (-1e-16, 4)',
        'appendInfoLine: "raw|small2|", fixed$ (0.0004, 2)',
        'appendInfoLine: "raw|sixth0|", fixed$ (0.6, 0)',
        'appendInfoLine: "raw|zero4|", fixed$ (0, 4)',
        '',
        '# --- 2b. @eml_fixed OVER A CASE GRID -------------------------------',
        '# Each case is `value decimals expected`. The grid is chosen so that',
        '# no single wrong implementation passes all of it: clamping',
        '# everything to zero fails sixth0 and round_up; passing fixed$',
        '# through fails tiny4, small2 and exact_zero4; rounding without the',
        '# zero case fails exact_zero4 and tiny4.',
        'procedure ef: .tag$, .v, .d',
        '    @eml_fixed: .v, .d',
        '    appendInfoLine: "ef|", .tag$, "|", eml_fixed.result$',
        'endproc',
        '@ef: "tiny4", -1e-16, 4',
        '@ef: "tiny_pos4", 1e-16, 4',
        '@ef: "exact_zero4", 0, 4',
        '@ef: "exact_zero0", 0, 0',
        '@ef: "small2", 0.0004, 2',
        '@ef: "sixth0", 0.6, 0',
        '@ef: "round_up", 0.99999, 4',
        '@ef: "ordinary4", 1234.56789, 4',
        '@ef: "ordinary2", -1.2345, 2',
        '@ef: "integer0", 42, 0',
        '@ef: "undef4", undefined, 4',
        '@ef: "neg_small4", -0.00004, 4',
        '@ef: "half_up4", 0.00006, 4',
        '',
        '# --- 2c. THE REPORTED LEAK, END TO END -----------------------------',
        '# The auditor\'s journey: a Matrix, coerced by a door, described. The',
        '# column is symmetric, so its skewness is zero and the arithmetic',
        '# lands a few ulps off zero -- which is the input that produced',
        '# -0.0000000000000001 in leg2_mx_describe.info.txt.',
        'Create simple Matrix: "v64mx", 5, 2, "row * 0.1 + col"',
        '@emlWrapperInit: 1',
        'v64t = emlWrapperInit.tableId',
        'clearinfo',
        '@emlRunDescriptiveAnalysis: v64t, "Column_1"',
        'v64report$ = info$ ()',
        'writeInfoLine: "v64 probe resumed"',
        'appendInfoLine: "report|BEGIN|"',
        'appendInfo: v64report$',
        'appendInfoLine: "report|END|"',
        '',
        '# The skewness really is a non-zero double underneath -- otherwise',
        '# the printed 0.0000 would be proving nothing at all.',
        'appendInfoLine: "underlying|skewness|", string$ (emlDescribe.skewness)',
        'removeObject: v64t',
        'removeObject: "Matrix v64mx"',
        '',
        '# --- 2d. RULING 3: DOES THE MULTI-COLUMN EXPORT KEEP SHAPE? --------',
        '# Two columns tested in one press, then exported, then the tidy file',
        '# read back off disk. Measured, not asserted -- see section 4.',
        'Create Table with column names: "v64norm", 8, "a b"',
        'v64tab = selected ("Table")',
        'for r from 1 to 8',
        '    Set numeric value: r, "a", r * r',
        '    Set numeric value: r, "b", 10 - r',
        'endfor',
        '@emlRunNormalityAnalysis: v64tab, "a", "both"',
        '@emlRunNormalityAnalysis: v64tab, "b", "both"',
        '@emlExportResultFiles: outDir$, "v64_multi"',
        'appendInfoLine: "export|multi_written|", emlExportResultFiles.nWritten',
        '@emlRunNormalityAnalysis: v64tab, "a", "single"',
        '@emlExportResultFiles: outDir$, "v64_single"',
        'appendInfoLine: "export|single_written|", emlExportResultFiles.nWritten',
        '',
        '# --- 2e. THE SWEEP, OVER EVERY WRAPPER THAT PRINTS -----------------',
        '# One statistic near zero is one line. The claim under test is that',
        '# the ESCAPE is closed, so a report is driven out of several',
        '# orchestrators on data engineered to put zeros in them -- two',
        '# identical groups (t = 0, d = 0, CI on zero), and a perfectly',
        '# symmetric column.',
        'Create Table with column names: "v64flat", 8, "grp val"',
        'v64flatId = selected ("Table")',
        'for r from 1 to 8',
        '    if r <= 4',
        '        Set string value: r, "grp", "A"',
        '        Set numeric value: r, "val", r',
        '    else',
        '        Set string value: r, "grp", "B"',
        '        Set numeric value: r, "val", r - 4',
        '    endif',
        'endfor',
        'clearinfo',
        '@emlRunTwoGroupAnalysis: v64flatId, "val", "grp", "auto", 0.95',
        'v64two$ = info$ ()',
        'clearinfo',
        '@emlRunNormalityAnalysis: v64flatId, "val", "both"',
        'v64norm$ = info$ ()',
        'writeInfoLine: "v64 probe resumed 2"',
        'appendInfoLine: "sweep|BEGIN|twogroup"',
        'appendInfo: v64two$',
        'appendInfoLine: "sweep|END|twogroup"',
        'appendInfoLine: "sweep|BEGIN|normality"',
        'appendInfo: v64norm$',
        'appendInfoLine: "sweep|END|normality"'), probe)

    outTxt <- suppressWarnings(system2("env",
        c("-u", "DISPLAY", shQuote(praat),
          shQuote(paste0("--pref-dir=", prefs)), "--run", shQuote(probe)),
        stdout = TRUE, stderr = TRUE))

    got <- function(tag, field) {
        p <- sprintf("^%s\\|%s\\|", tag, field)
        sub(p, "", grep(p, outTxt, value = TRUE))
    }
    block <- function(kind, name) {
        b <- grep(sprintf("^%s\\|BEGIN\\|%s$", kind, name), outTxt)
        e <- grep(sprintf("^%s\\|END\\|%s$", kind, name), outTxt)
        if (!length(b) || !length(e)) return(character(0))
        if (e[1] - b[1] < 2) return(character(0))
        outTxt[(b[1] + 1):(e[1] - 1)]
    }
    ran <- !any(grepl("^Error", outTxt)) && length(got("raw", "tiny4")) == 1
    if (!ran) cat(sprintf("      v64 probe output: %s\n",
                          paste(utils::tail(outTxt, 8), collapse = " / ")))
    check_true("v64", "the display probe ran", ran)

    if (ran) {
        # -- 2a. THE PREMISE IS TRUE OF THIS BINARY -------------------------
        raw <- c(tiny4 = got("raw", "tiny4"), small2 = got("raw", "small2"),
                 sixth0 = got("raw", "sixth0"), zero4 = got("raw", "zero4"))
        decs <- function(s) ifelse(grepl("\\.", s), nchar(sub("^.*\\.", "", s)), 0L)
        check_true("v64",
                   sprintf("Praat's fixed$ ignores the precision it is given near zero (%s)",
                           paste(sprintf("%s=%s", names(raw), raw), collapse = " ")),
                   decs(raw[["tiny4"]]) > 4 && decs(raw[["small2"]]) > 2 &&
                   decs(raw[["sixth0"]]) > 0 && decs(raw[["zero4"]]) < 4)

        # -- 2b. @eml_fixed GIVES EXACTLY THE WIDTH IT IS ASKED FOR ---------
        # The expectations are written out rather than recomputed in R,
        # because recomputing them in R would be re-implementing the thing
        # under test and the two implementations would agree about a shared
        # misunderstanding. sprintf("%.4f", -1e-16) is "-0.0000" in C, sign
        # and all -- which is exactly the answer this ruling does not want.
        grid <- list(
            tiny4       = "0.0000",
            tiny_pos4   = "0.0000",
            exact_zero4 = "0.0000",
            exact_zero0 = "0",
            small2      = "0.00",
            sixth0      = "1",
            round_up    = "1.0000",
            ordinary4   = "1234.5679",
            ordinary2   = "-1.23",
            integer0    = "42",
            undef4      = "--undefined--",
            neg_small4  = "0.0000",
            half_up4    = "0.0001")
        for (nm in names(grid)) {
            gotv <- got("ef", nm)
            check_true("v64",
                       sprintf("@eml_fixed %s -> %s (got %s)", nm, grid[[nm]],
                               if (length(gotv)) paste(gotv, collapse = "/") else "nothing"),
                       length(gotv) == 1 && identical(gotv, grid[[nm]]))
        }
        # SAID AS A PROPERTY AS WELL AS A TABLE. The grid pins thirteen
        # answers; this pins the rule they are instances of, so a fourteenth
        # case added later cannot quietly be the one exception.
        widths <- c(tiny4 = 4, tiny_pos4 = 4, exact_zero4 = 4, exact_zero0 = 0,
                    small2 = 2, sixth0 = 0, round_up = 4, ordinary4 = 4,
                    ordinary2 = 2, integer0 = 0, neg_small4 = 4, half_up4 = 4)
        obs <- vapply(names(widths), function(n) {
            g <- got("ef", n); if (length(g) == 1) decs(g) else -1L
        }, integer(1))
        check_true("v64",
                   sprintf("every finite case printed exactly the decimals it asked for (%s)",
                           paste(sprintf("%s:%d", names(obs), obs), collapse = " ")),
                   all(obs == widths))
        # AND NO MINUS SIGN IN FRONT OF NOTHING. "-0.0000" is a printed
        # negative zero: it tells a reader the value is negative and then
        # shows them zero, which is worse than either answer alone.
        negzero <- vapply(names(grid), function(n) {
            g <- got("ef", n)
            length(g) == 1 && grepl("^-0(\\.0*)?$", g)
        }, logical(1))
        check_true("v64",
                   sprintf("no case printed a negative zero (%s)",
                           paste(names(negzero)[negzero], collapse = ",")),
                   !any(negzero))

        # -- 2c. THE REPORTED LEAK IS GONE, AND WAS REAL --------------------
        # Read directly rather than through block(): the Describe capture is
        # the one that carries no case name after BEGIN, because there is
        # only ever one of it.
        rep <- {
            b <- grep("^report\\|BEGIN\\|$", outTxt)
            e <- grep("^report\\|END\\|$", outTxt)
            if (length(b) && length(e) && e[1] > b[1] + 1)
                outTxt[(b[1] + 1):(e[1] - 1)] else character(0)
        }
        check_true("v64", sprintf("the Describe report was captured (%d lines)",
                                  length(rep)),
                   length(rep) > 10)
        under <- got("underlying", "skewness")
        check_true("v64",
                   sprintf("the case is a real one: the underlying skewness is a non-zero double (%s)",
                           paste(under, collapse = "")),
                   length(under) == 1 &&
                   !is.na(suppressWarnings(as.numeric(under))) &&
                   as.numeric(under) != 0)
        # THE VALUE IS THE FIRST TAB-SEPARATED CELL OF THE ROW, not the rest
        # of the line. @emlReportLine (stats/eml-output.praat) appends
        # emlWizardExplain$ after TWO TABS when emlShowExplanations is set,
        # so a row that has gained a plain-language gloss reads
        # "Skewness<pad>0.0000\t\tApproximately symmetric ...". Reading the
        # whole remainder would make this file assert about the gloss and not
        # about the formatter -- and this file is about the formatter.
        # v130's own stat reader splits at the same place, for the same
        # reason. THE GLOSS IS STILL CHECKED, on the line below: if one is
        # present it must be in its own cell, because a gloss that ran into
        # the value cell would be the defect this split assumes away.
        skewLine <- grep("^\\s*Skewness\\s", rep, value = TRUE)
        skewCells <- if (length(skewLine))
            strsplit(skewLine[1], "\t", fixed = TRUE)[[1]] else character(0)
        skewVal <- if (length(skewCells))
            trimws(sub("^\\s*Skewness\\s+", "", skewCells[1])) else character(0)
        check_true("v64",
                   sprintf("the Skewness row's value stands in its own tab cell (%d cell(s))",
                           length(skewCells)),
                   length(skewCells) >= 1 &&
                   !grepl("[A-Za-z]", sub("^\\s*Skewness\\s+", "", skewCells[1])))
        check_true("v64",
                   sprintf("the Skewness row prints at exactly four decimals (%s)",
                           paste(skewVal, collapse = "|")),
                   length(skewVal) == 1 && grepl("^-?[0-9]+\\.[0-9]{4}$", skewVal))
        check_true("v64",
                   sprintf("and it is the zero it should be, not a rounding of noise (%s)",
                           paste(skewVal, collapse = "|")),
                   identical(skewVal, "0.0000"))

        # THE WHOLE REPORT, NOT THE ONE ROW. This is the assertion that would
        # have caught the defect wherever it surfaced first, and the one that
        # keeps catching it when the next near-zero statistic is added.
        # Four is the house maximum: N rows print at 0 and statistics at 4,
        # and nothing is entitled to more.
        toolong <- function(lines) {
            m <- regmatches(lines, gregexpr("[0-9]+\\.[0-9]+", lines))
            bad <- character(0)
            for (i in seq_along(m)) {
                d <- nchar(sub("^.*\\.", "", m[[i]]))
                if (length(d) && any(d > 4)) bad <- c(bad, trimws(lines[i]))
            }
            bad
        }
        badRep <- toolong(rep)
        if (length(badRep))
            cat(sprintf("      NOTE v64: report line(s) past four decimals:\n%s\n",
                        paste("           ", badRep, collapse = "\n")))
        check_true("v64",
                   sprintf("no line of the Describe report carries more than four decimals (%d offender(s))",
                           length(badRep)),
                   length(badRep) == 0)

        # -- 2e. THE SAME CLAIM OVER OTHER WRAPPERS -------------------------
        # Named separately so a failure says WHICH report leaked. The
        # two-group case is two identical groups, which is where a t, a d and
        # a confidence bound are all zero at once.
        for (nm in c("twogroup", "normality")) {
            b <- block("sweep", nm)
            check_true("v64", sprintf("the %s report was captured (%d lines)",
                                      nm, length(b)),
                       length(b) > 5)
            bad <- toolong(b)
            if (length(bad))
                cat(sprintf("      NOTE v64: %s line(s) past four decimals:\n%s\n",
                            nm, paste("           ", bad, collapse = "\n")))
            check_true("v64",
                       sprintf("no line of the %s report carries more than four decimals (%d offender(s))",
                               nm, length(bad)),
                       length(bad) == 0)
        }

        # -- 3. RULING 3, MEASURED --------------------------------------
        # See section 4 of the header. Driven, printed, not asserted.
        tidyMulti <- file.path(work, "out", "v64_multi_tidy.csv")
        glanceOne <- file.path(work, "out", "v64_single_glance.csv")
        check_true("v64",
                   sprintf("the multi-column normality export wrote its tidy frame (%s)",
                           basename(tidyMulti)),
                   file.exists(tidyMulti))
        check_true("v64",
                   sprintf("the single-column normality export wrote its glance frame (%s)",
                           basename(glanceOne)),
                   file.exists(glanceOne))
        if (file.exists(tidyMulti) && file.exists(glanceOne)) {
            tm <- read.csv(tidyMulti, stringsAsFactors = FALSE,
                           check.names = FALSE)
            g1 <- read.csv(glanceOne, stringsAsFactors = FALSE,
                           check.names = FALSE)
            hasT <- all(c("skewness", "kurtosis") %in% names(tm))
            hasG <- all(c("skewness", "kurtosis") %in% names(g1))
            # WHAT IS ASSERTED: the asymmetry EXISTS AND IS THE ONE REPORTED.
            # This is not a pin on the defect -- it is a pin on the premise of
            # ruling 3, so if somebody "fixes" it by DELETING skewness from
            # glance, this line goes red and says the wrong repair was made.
            check_true("v64",
                       sprintf("single-column normality exports skewness and kurtosis (glance: %s)",
                               paste(names(g1), collapse = ",")),
                       hasG)
            if (!hasT) {
                cat(sprintf(paste0(
                    "      NOTE v64: RULING 3 IS NOT IMPLEMENTED.\n",
                    "            The multi-column normality tidy frame carries %s.\n",
                    "            Single-column carries skewness and kurtosis in\n",
                    "            glance; multi-column loses them entirely, which is\n",
                    "            the asymmetry the ruling is about -- the shape\n",
                    "            statistics for column 2 exist nowhere in any file.\n",
                    "            REPAIR, and it needs BOTH halves or it ships a file\n",
                    "            with only `term` and `method` in it:\n",
                    "            (1) plugin/stats/eml-result-writer.praat:109 --\n",
                    "                emlVocabTidy$ is a WHITELIST walked by\n",
                    "                @eml_orderedCols, and a column not in it is\n",
                    "                dropped from the written file WITHOUT COMMENT.\n",
                    "                Add `skewness kurtosis` to it. Position matters:\n",
                    "                the vocabulary IS the column order, so they go\n",
                    "                beside the other descriptive additions rather\n",
                    "                than before `term`.\n",
                    "            (2) plugin/stats/eml-analysis.praat:4481-4492 --\n",
                    "                @emlDeclareNormalityResult's per-column tidy loop\n",
                    "                emits statistic/p.value/method and nothing else.\n",
                    "                Add @emlTidyNum: \"skewness\", emlNorm_skew [.i]\n",
                    "                and the same for emlNorm_kurt [.i], INSIDE the\n",
                    "                loop and OUTSIDE the Shapiro-Wilk error branch:\n",
                    "                the shape statistics are still the answer on a\n",
                    "                column whose W is out of range, which is what\n",
                    "                that branch's own comment says.\n",
                    "            Neither file is this change's to edit. The check\n",
                    "            below asserts only that the export is well formed,\n",
                    "            so that it stays green either way and this note is\n",
                    "            what carries the finding.\n"),
                    paste(names(tm), collapse = ", ")))
            }
            attest("v64",
                   sprintf("ruling 3 measured: multi-column tidy carries [%s]; single-column glance carries [%s]",
                           paste(names(tm), collapse = ","),
                           paste(names(g1), collapse = ",")),
                   "driven live and read off disk; not asserted -- the repair is in eml-result-writer.praat and eml-analysis.praat, out of scope for this change")
            # ASSERTED EITHER WAY: whatever the vocabulary decides to carry,
            # the file is one row per column tested and the identifying column
            # is there. That is the property a silent whitelist drop destroys,
            # and it is the one that failed the first time somebody tried this
            # (a file containing `term` and `method` and nothing else).
            check_true("v64",
                       sprintf("the multi-column tidy frame is one row per column tested (%d rows)",
                               nrow(tm)),
                       nrow(tm) == 2)
            check_true("v64",
                       sprintf("it names the columns it tested (%s)",
                               paste(utils::head(names(tm), 3), collapse = ",")),
                       "term" %in% names(tm) &&
                       identical(sort(as.character(tm$term)), c("a", "b")))
            check_true("v64",
                       sprintf("and it carries the test as well as the label (%s)",
                               paste(names(tm), collapse = ",")),
                       any(c("statistic", "p.value") %in% names(tm)))
        }
    }
}

if (!exists("EML_SUITE")) {
    eml_report("v64 display and coercion: what the Info window may print")
    eml_exit()
}
