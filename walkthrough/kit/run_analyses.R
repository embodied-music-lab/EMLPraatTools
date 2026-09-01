# run_analyses.R -- R-side runner for the walkthrough kit.
#
# Reads matrix.tsv (the declaration both runners walk) and executes every row
# in it. This file carries NO list of analyses of its own: the dispatch below
# is keyed by `procedure` name only (17 fixed procedure names, matching the
# 17 Praat orchestrators the declaration references), never by `cell_id`,
# `dataset`, or any other per-row value. Add a row to matrix.tsv -- a new
# cell_id against an existing procedure, or new axis values on an existing
# procedure -- and this file runs it with no code change. (This is
# demonstrated, not just asserted: see the delivery report.)
#
# Every statistic below comes from an installed R package's own function --
# base R (`stats`), rstatix, effectsize, car, afex, multcomp, nortest, coin or
# psych -- never a hand-derived formula. Where a package option had to be
# chosen (which sum-of-squares type, which p-value floor, pooled vs Welch,
# etc.) the choice is the one a statistician would make for that design, and
# is commented at the call site; none was chosen because it made a number
# match Praat's. Six quantities are computed from BOTH rstatix and
# effectsize on purpose -- Cohen's d, rank-biserial r, epsilon-squared,
# eta-squared, Cramer's V, Kendall's W -- because the two packages sometimes
# use different formulas for the "same" named quantity, and reporting both
# (distinguished by the `source` column) is the point of the comparison, not
# a defect to average away.
#
# Emits audit/r_results.tsv in the shared long schema (cell_id, quantity,
# value, source) and one human-readable report per cell into
# results/r_reports/<cell_id>.txt -- including refused and skipped cells, which
# get a short report stating why nothing was computed.
#
# KNOWN, INVESTIGATED DISCREPANCIES against matrix.tsv's `expect` column
# (9 cells: c0375, c0381, c0492-c0494, c0528-c0531): these ARE refused by
# this script even though the matrix marks them `expect=ok`. Traced back to
# the plugin source and confirmed that Praat's OWN implementation also
# refuses on this exact data:
#   - c0375/c0381 (emlRunPairedAnalysis, parametric): rp_r1_rmanova_input and
#     rp_r6_describe_input have paired differences that are bit-exact +10.0
#     for every subject. @emlTTestPaired's own guard (`if .sdDiff = 0`, an
#     EXACT equality test, plugin_EML_StatsGraphs/stats/eml-inferential.praat
#     ~line 364) refuses with "All differences are identical (zero
#     variance)" on this data too.
#   - c0492-c0494 (emlRunNormalityAnalysis): rp_r2_rmanova_input has only 2
#     rows. @emlRunNormalityAnalysis's own guard (`if .nValid < 3`,
#     plugin_EML_StatsGraphs/stats/eml-analysis.praat ~line 3596) sits
#     OUTSIDE the `if .error$ = ""` block that computes descriptives AND
#     Shapiro-Wilk, i.e. Praat refuses the whole cell at n<3, not just the
#     Shapiro-Wilk test.
#   - c0528-c0531 (emlRunRepeatedMeasuresAnalysis): rp_r1_rmanova_input is a
#     perfectly additive design (each condition step is exactly +10 for
#     every subject), so the subject x condition residual is zero.
#     @emlRMAnovaTest refuses this with a documented RELATIVE floor
#     (`.ssErr <= 1e-10 * .ssTot`, plugin_EML_StatsGraphs/stats/
#     eml-analysis.praat ~line 4133) precisely because an exact-zero test is
#     unreliable in Praat's own floating point (its comment there notes the
#     naive residual lands near 1e-16 of ssTot, not at bit-exact zero, on
#     data built exactly this way).
# In all three clusters, this script's refusal matches what Praat's own
# source does on this input -- the matrix's `expect=ok` annotation on these
# 9 cells looks like the thing to fix, not either runner's statistics. Not
# changed here because matrix.tsv is out of this file's scope; see the
# delivery report.

# --- locate this file / self-relative paths ---------------------------------
# Three ways this file's own path gets resolved, tried in order:
#   1. Rscript from a terminal: commandArgs(trailingOnly = FALSE) carries
#      --file=<path>.
#   2. RStudio's Source button (or any source() call, from any cwd): source()
#      evaluates the file in a frame carrying $ofile. RStudio does not source
#      at the top level of the R session -- it wraps the call in its own
#      internal function -- so the source() frame is NOT reliably
#      sys.frames()[[1]]; scanning every frame from the innermost outward
#      and taking the first $ofile found is what actually survives that
#      wrapping.
#   3. Neither resolves (e.g. code pasted into the console): try rstudioapi
#      if it happens to be installed -- never required -- and otherwise stop
#      with a plain-language message. Never fall back to getwd() silently.
emlThisFile <- function() {
    args <- commandArgs(trailingOnly = FALSE)
    fileArg <- sub("^--file=", "", args[grepl("^--file=", args)])
    if (length(fileArg)) return(normalizePath(fileArg))

    for (i in rev(seq_along(sys.frames()))) {
        ofile <- sys.frames()[[i]]$ofile
        if (!is.null(ofile)) return(normalizePath(ofile))
    }

    if (requireNamespace("rstudioapi", quietly = TRUE) &&
        isTRUE(tryCatch(rstudioapi::isAvailable(), error = function(e) FALSE))) {
        ctx <- tryCatch(rstudioapi::getSourceEditorContext(), error = function(e) NULL)
        if (!is.null(ctx) && nzchar(ctx$path)) return(normalizePath(ctx$path))
    }

    stop(
        "run_analyses.R can't find its own location, so it can't find data/ ",
        "or matrix.tsv.\nIn RStudio, use Session > Set Working Directory > ",
        "To Source File Location, then click Source again.",
        call. = FALSE
    )
}
kitDir    <- dirname(emlThisFile())
dataDir   <- file.path(kitDir, "data")
outDir    <- file.path(kitDir, "audit")
resultsDir <- file.path(kitDir, "results")
reportDir  <- file.path(resultsDir, "r_reports")
matrixPath <- file.path(kitDir, "matrix.tsv")
dir.create(outDir, showWarnings = FALSE)
dir.create(resultsDir, showWarnings = FALSE)
# THE REPORT DIRECTORY IS EMPTIED FIRST. Reports are written one file per
# cell and never deleted, so a cell removed from matrix.tsv leaves its old
# report behind. A reader then finds a report for a cell that no longer
# exists, describing a fixture that may no longer exist either, and the kit
# looks out of step with itself. Emptying costs nothing: every cell in the
# current declaration writes its report on this run.
unlink(reportDir, recursive = TRUE)
dir.create(reportDir, showWarnings = FALSE)

# --- packages -----------------------------------------------------------
# rstatix, effectsize, car, afex, multcomp, nortest and coin are all
# installed but unused directly are not loaded (multcomp, nortest, coin have
# no cell in the declaration that calls for what they uniquely offer over
# the others here; loading them costs nothing so they stay listed for the
# record of what was considered). psych is used for Cronbach's alpha /
# leave-one-out influence and for descriptive shape statistics.
# PREFLIGHT. Without this, a missing package fails on whichever library()
# call comes first -- "there is no package called 'rstatix'" -- which names
# one package, not the eight, and does not say what to do about it. Measured
# on a first run against a clean R 4.5.2. Check them all and print the
# install line the README already carries.
.emlNeed <- c("rstatix", "effectsize", "car", "afex",
              "multcomp", "nortest", "coin", "psych")
.emlMissing <- .emlNeed[!vapply(.emlNeed, requireNamespace, logical(1),
                                quietly = TRUE)]
if (length(.emlMissing)) {
    stop("This kit needs ", length(.emlMissing), " package(s) that are not ",
         "installed: ", paste(.emlMissing, collapse = ", "), ".\n",
         "  Run this once, then Source this file again:\n",
         "  install.packages(c(",
         paste0('"', .emlNeed, '"', collapse = ","), "))",
         call. = FALSE)
}

suppressPackageStartupMessages({
    library(rstatix)
    library(effectsize)
    library(car)
    library(afex)      # side effect: sets options(contrasts = ...) globally
    library(multcomp)
    library(nortest)
    library(coin)
    library(psych)
})
# afex's load re-points the GLOBAL `contrasts` option at sum-to-zero coding,
# for its OWN models' benefit. Every other aov()/lm() call in this file
# (one-way ANOVA, two-way ANOVA, simple and grouped regression) must keep
# R's factory default (treatment contrasts) -- afex manages its own model's
# contrasts internally regardless of this global, so resetting it here costs
# afex nothing and protects everything else in this file from a side effect
# of a library() call.
options(contrasts = c("contr.treatment", "contr.poly"))

# =============================================================================
# Matrix reading
# =============================================================================
read_matrix <- function(path) {
    lines <- readLines(path, warn = FALSE)
    lines <- lines[!grepl("^#", lines)]
    read.delim(text = paste(lines, collapse = "\n"), sep = "\t", header = TRUE,
               colClasses = "character", na.strings = character(0), quote = "")
}

# =============================================================================
# Dataset cache, coercion helpers, group ordering, pair naming
# =============================================================================
.dsCache <- new.env()
readDataset <- function(name) {
    if (!exists(name, envir = .dsCache, inherits = FALSE)) {
        path <- file.path(dataDir, paste0(name, ".csv"))
        d <- read.csv(path, stringsAsFactors = FALSE, na.strings = c("NA", "n/a", ""),
                      colClasses = "character", check.names = FALSE)
        assign(name, d, envir = .dsCache)
    }
    get(name, envir = .dsCache, inherits = FALSE)
}
# The comma-decimal conversion that lived here was removed on 27 August 2026
# together with rp_r6_parse_conditions_input, the only fixture that exercised
# it. No fixture in the corpus now carries a comma-decimal cell, and the
# corpus rule in README.md keeps it that way, so the branch was dead. The
# fixture's behaviour assertion lives in validate/, not here.
.localeNumeric <- function(v) {
    suppressWarnings(as.numeric(trimws(as.character(v))))
}
numcol <- function(d, col) .localeNumeric(d[[col]])
chrcol <- function(d, col) trimws(as.character(d[[col]]))

# UNROUNDED p-VALUES. rstatix rounds every p it reports to three
# significant digits -- hard-wired in its internal as_tidy_stat(round.p =
# TRUE, digits = 3), with no user-facing option on t_test/wilcox_test/
# dunn_test. That rounding is a DISPLAY decision and must not reach this
# table, so no p-value below is ever taken from an rstatix column: raw
# p-values come from the corresponding stats:: test and adjusted p-values
# from stats::p.adjust over that raw vector, which is the same family-wise
# procedure rstatix itself applies. rstatix is still used for what it is
# good at here -- enumerating the pairs and supplying estimates -- and the
# `source` column says "stats" on the p rows, honestly naming where the
# number came from.
padjust <- function(p, method) stats::p.adjust(p, method = method)

# SHAPE STATISTICS: WHICH ESTIMATOR "skewness" MEANS.
# psych offers three, selected by `type`, and psych::describe() defaults to
# type = 3 -- the b1/b2 moment ratios, which are the maximum-likelihood
# (biased) estimators. The quantity a report calls "sample skewness" in
# applied work is type = 2: G1 and G2, the estimators SPSS, SAS and Excel
# compute and the ones that are unbiased under normality. That is what the
# shared schema's bare names `skewness` and `kurtosis` are taken to mean
# here, and both are reported as EXCESS kurtosis.
#
# Disclosure, because this option was changed after the two runners were
# first compared: psych's own type = 3 default was what stood here, and the
# switch to type = 2 does make these rows agree with the plugin. The
# argument for it is independent of that -- type 2 is the reporting
# convention, and leaving the name `skewness` attached to whichever
# estimator a package happens to default to is exactly the ambiguity that
# produced the disagreement. psych's default is still emitted, under its
# own names, so the choice is visible rather than buried.
emitShape <- function(cid, x) {
    emit(cid, "skewness", psych::skew(x, type = 2), "psych::skew")
    emit(cid, "kurtosis", psych::kurtosi(x, type = 2), "psych::kurtosi")
    emit(cid, "skewness_b1", psych::skew(x, type = 3), "psych::skew")
    emit(cid, "kurtosis_b2", psych::kurtosi(x, type = 3), "psych::kurtosi")
}

# group_order: "discovery" = order of first appearance in the column (R's
# unique() is stable in that sense); "alphabetical" = sort(). This is
# result-affecting (matrix.tsv's own header explains why: it decides which
# group is subtracted from which), so it is read from the row, never assumed.
orderedLevels <- function(gvec, order) {
    g <- trimws(as.character(gvec))
    g <- g[!is.na(g) & g != ""]
    if (identical(order, "alphabetical")) sort(unique(g)) else unique(g)
}

# PAIR NAMING: "<group1>__<group2>" lowercased, non-alnum runs collapsed to
# one underscore, first-minus-second in group_order's sequence. This is the
# emit-time bookkeeping the brief calls for; every pairwise result below is
# reoriented to this convention before being emitted, regardless of which
# direction the underlying package happened to compute it in.
slug <- function(s) tolower(gsub("[^A-Za-z0-9]+", "_", trimws(s)))
pairLabel <- function(g1, g2) paste0(slug(g1), "__", slug(g2))

# Shared precondition for every grouped procedure (two-group, ANOVA,
# Kruskal-Wallis, pairwise): the group column names its levels BEFORE we know
# whether the data column has anything in them for that level. A level whose
# data cells are all missing/non-numeric would otherwise just vanish from
# unique(g) after NA-filtering -- a whole declared category disappearing
# with no trace. That is worse than a loud, named refusal, so it is a
# refusal here, uniformly, for every grouped procedure -- not a special case
# recognising any one cell. (This is the general rule standing in for
# Praat's own two-step of counting declared groups first and discovering
# emptiness second.)
prepGroupedData <- function(cid, d, colData, colGroup, order) {
    x_full <- numcol(d, colData)
    g_full <- chrcol(d, colGroup)
    blankGroup <- is.na(g_full) | g_full == ""
    x1 <- x_full[!blankGroup]; g1 <- g_full[!blankGroup]
    levs <- orderedLevels(g1, order)
    for (lv in levs) {
        if (sum(g1 == lv & !is.na(x1)) == 0) {
            refuseCell(cid, sprintf(
                "Group '%s' has 0 valid (non-missing, numeric) observations in data column '%s'; a declared group cannot be silently dropped.",
                lv, colData))
            return(NULL)
        }
    }
    keep <- !is.na(x1)
    list(x = x1[keep], g = g1[keep], levs = levs)
}

parseConditions <- function(colspec) {
    parts <- strsplit(colspec, "\\|")[[1]]
    parts[nzchar(trimws(parts))]
}
buildConditionMatrix <- function(d, conds) {
    M <- do.call(cbind, lapply(conds, function(cc) numcol(d, cc)))
    colnames(M) <- conds
    keep <- stats::complete.cases(M)
    list(M = M[keep, , drop = FALSE], nExcluded = sum(!keep), n = sum(keep))
}

`%||%` <- function(a, b) if (is.null(a)) b else a

# p.adjust.method names, matrix's spelling -> R's spelling. "BH" is the same
# procedure as "fdr" in p.adjust(); BH is the name most stats texts use for
# it, so that's what is passed.
.adjMap <- c(bonferroni = "bonferroni", holm = "holm", bh = "BH", none = "none")

# ALPHA FOR THE PAIRWISE/RM/FRIEDMAN INTERVAL WORK (26 Aug 2026 items 2-5).
# matrix.tsv carries no alpha column (confirmed against its own column list,
# `conf` is survey-lane only) -- every analysis-lane cell runs at the
# plugin's own default, which is 0.05 unless a caller sets the global
# emlAlpha (plugin_EML_StatsGraphs/stats/eml-analysis.praat ~line 1601,
# "... otherwise .05"; RUN_ME_FIRST.praat never sets emlAlpha). Fixed here
# for the same reason, not re-derived per row.
EML_ALPHA <- 0.05

# A CORRECTION'S PER-PAIR LEVEL, WHERE ONE EXISTS. Bonferroni is the only
# adjustment among bonferroni/holm/bh that defines a per-pair simultaneous
# confidence level (1 - alpha/m, m = the number of pairs in THIS row's
# family); Holm and BH define none (docs/RULING_INTERVALS_2026-08-26.md).
# Where no level is defined this returns the plain, non-simultaneous
# 1 - alpha -- the same "a real, un-adjusted bound reported honestly under
# the same name" convention quantities.tsv documents for those rows.
pairLevel <- function(adjust, m) {
    if (identical(adjust, "bonferroni")) 1 - EML_ALPHA / m else 1 - EML_ALPHA
}

# =============================================================================
# OPTIONAL ROW FILTER -- same shape, same default as RUN_ME_FIRST.praat's
# emlKitProcFilter$ / @emlKitRowSelected (CLAUDE.md, "Scope of work units": a
# change drives only the rows it touches, not a re-run of everything). LEAVE
# THIS EMPTY for the unchanged, full 630-cell run.
#
# TO USE: set the EML_KIT_PROC_FILTER environment variable (or edit the
# default below directly) to one or more matrix.tsv "procedure" column
# values, comma-separated, e.g.
#     EML_KIT_PROC_FILTER=emlRunPairwiseAnalysis,emlRunRepeatedMeasuresAnalysis
# Only rows whose procedure field exactly matches an entry in this list are
# run; every other row is skipped outright before dispatch -- not refused,
# not counted, no result row and no report file of any kind -- mirroring
# @emlKitRowSelected exactly: empty filter -> every row selected, so an
# empty filter reproduces the unfiltered 630-cell run exactly.
# =============================================================================
emlKitProcFilter <- Sys.getenv("EML_KIT_PROC_FILTER", unset = "")
emlKitRowSelected <- function(proc) {
    if (!nzchar(emlKitProcFilter)) return(TRUE)
    proc %in% strsplit(emlKitProcFilter, ",", fixed = TRUE)[[1]]
}

# =============================================================================
# Results accumulator and per-cell report writer
# =============================================================================
RESULTS <- new.env()
RESULTS$rows <- vector("list", 0)

# value: full precision, unrounded, unformatted. %.17g is the shortest
# format that round-trips an IEEE double exactly, so the TSV carries the
# number the package computed rather than a rendering of it. (%.15g stood
# here first and silently truncated; that is a DISPLAY difference and had
# no business reaching the comparison table.)
emit <- function(cell_id, quantity, value, source) {
    if (length(value) != 1 || is.na(suppressWarnings(as.numeric(value))) ||
        is.nan(suppressWarnings(as.numeric(value))) || is.infinite(suppressWarnings(as.numeric(value)))) {
        # A NON-FINITE VALUE IS NOT A REASON TO WRITE NOTHING. Dropping
        # NA/NaN/Inf on the floor is a silent fallback: the quantity then
        # looks like one this runner never attempted, which is
        # indistinguishable in the join from a coverage hole. Emit an
        # explicit marker instead, so the comparison can tell "computed,
        # came out undefined" from "never computed".
        RESULTS$rows[[length(RESULTS$rows) + 1]] <<- list(
            cell_id = cell_id, quantity = paste0(quantity, "_undefined"),
            value = "1", source = source)
        return(invisible(NULL))
    }
    value <- as.numeric(value)
    RESULTS$rows[[length(RESULTS$rows) + 1]] <<- list(
        cell_id = cell_id, quantity = quantity, value = sprintf("%.17g", value), source = source)
}
emitText <- function(cell_id, quantity, text, source = "r") {
    RESULTS$rows[[length(RESULTS$rows) + 1]] <<- list(
        cell_id = cell_id, quantity = quantity, value = as.character(text), source = source)
}
# composePMethod -- item 22 of the language batch (Fable's ruling, 27
# August 2026): "p method" is text, not a number a tolerance question
# applies to, so it rides through emitText/agree()'s existing text-valued
# path (compare.R's "text-valued on both sides" branch already does exact
# string identity, same as refuse_reason). "exact" bare, else the method
# name plus EVERY reason that ruled the exact branch out, comma-separated,
# fixed order, no precedence -- reproduced here from independently-derived
# facts about the DATA (ties, sample size, zero differences), never from
# reading a package's own internal decision (wilcox.test's $method text
# does not even name its branch for Spearman -- see v147's own header note
# on this) -- mirroring the composition the plugin's own kernels build.
composePMethod <- function(method, reasons) {
    reasons <- reasons[nzchar(reasons)]
    if (identical(method, "exact")) return("exact")
    if (length(reasons) == 0) return(method)
    paste0(method, " (", paste(reasons, collapse = ", "), ")")
}
refuseCell <- function(cell_id, reason) {
    emitText(cell_id, "refused", "1", source = "r::refuseCell")
    emitText(cell_id, "refuse_reason", reason, source = "r::refuseCell")
    # One report per cell, no exceptions: a refused cell still gets its
    # results/r_reports/<cell_id>.txt, stating plainly that nothing was
    # computed and why, rather than leaving that cell with no file at all.
    writeReport(cell_id, c(sprintf("REFUSED: %s", reason)))
}
skipCell <- function(cell_id, reason) {
    emitText(cell_id, "skipped", "1", source = "r::skipCell")
    emitText(cell_id, "skip_reason", reason, source = "r::skipCell")
}
writeReport <- function(cell_id, lines) {
    writeLines(lines, file.path(reportDir, paste0(cell_id, ".txt")))
}
flushResults <- function(path) {
    n <- length(RESULTS$rows)
    df <- if (n == 0) {
        data.frame(cell_id = character(), quantity = character(), value = character(), source = character())
    } else {
        data.frame(cell_id = vapply(RESULTS$rows, `[[`, "", "cell_id"),
                   quantity = vapply(RESULTS$rows, `[[`, "", "quantity"),
                   value = vapply(RESULTS$rows, `[[`, "", "value"),
                   source = vapply(RESULTS$rows, `[[`, "", "source"),
                   stringsAsFactors = FALSE)
    }
    write.table(df, path, sep = "\t", quote = FALSE, row.names = FALSE)
}

# =============================================================================
# emlRunTwoGroupAnalysis -- independent two-group comparison
#   test:      parametric (t-test) / nonparametric (Mann-Whitney U) / both
#   equal_var: 1 = Student's pooled-variance t (var.equal=TRUE)
#              0 = Welch's t (var.equal=FALSE), R's own default
#   group_order: which level is "group1" -- see orderedLevels() above
# Cohen's d and Hedges' g: effectsize::cohens_d/hedges_g on the raw vectors
# (pooled_sd=TRUE, the classical definition) -- direct vector order already
# gives first-minus-second, no reorientation needed. Also computed via
# rstatix::cohens_d on a 2-level factor built with levels=c(group1,group2),
# which empirically follows the same first-minus-second convention (verified
# against known cases before relying on it here). Both rows are emitted
# (quantity "cohens_d", source "effectsize" and "rstatix") because Cohen's d
# is one of the six quantities the brief calls out as computed from both
# packages on purpose.
# rank_biserial: effectsize::rank_biserial (Cureton/King&Minium formula) and
# rstatix::wilcox_effsize (Z/sqrt(N), a DIFFERENT published formula for a
# quantity both packages call effect size r for Mann-Whitney) -- both
# emitted under "rank_biserial", not reconciled; this is one of the six.
# =============================================================================
process_two_group <- function(row) {
    cid <- row$cell_id
    d <- readDataset(row$dataset)
    prep <- prepGroupedData(cid, d, row$col_a, row$col_b, row$group_order)
    if (is.null(prep)) return(invisible())
    x <- prep$x; g <- prep$g; levs <- prep$levs
    if (length(levs) != 2) {
        refuseCell(cid, sprintf("Group column '%s' has %d group(s) after excluding blanks; this test compares exactly 2.",
                                 row$col_b, length(levs)))
        return(invisible())
    }
    g1 <- levs[1]; g2 <- levs[2]
    v1 <- x[g == g1]; v2 <- x[g == g2]
    if (length(v1) < 2 || length(v2) < 2) {
        refuseCell(cid, sprintf("Each group needs at least 2 observations. Group '%s': n=%d, group '%s': n=%d",
                                 g1, length(v1), g2, length(v2)))
        return(invisible())
    }
    lines <- c(sprintf("Two-group comparison -- %s by %s", row$col_a, row$col_b),
               sprintf("group_order=%s  group1=%s  group2=%s", row$group_order, g1, g2), "")
    emit(cid, "n", length(v1) + length(v2), "base::length")
    emit(cid, "n_group1", length(v1), "base::length"); emit(cid, "n_group2", length(v2), "base::length")
    emit(cid, "mean_group1", mean(v1), "stats::mean"); emit(cid, "mean_group2", mean(v2), "stats::mean")
    emit(cid, "sd_group1", sd(v1), "stats::sd"); emit(cid, "sd_group2", sd(v2), "stats::sd")
    emit(cid, "median_group1", median(v1), "stats::median"); emit(cid, "median_group2", median(v2), "stats::median")
    emit(cid, "mean_diff", mean(v1) - mean(v2), "stats::mean")
    lines <- c(lines,
               sprintf("%s: n=%d mean=%.4f sd=%.4f median=%.4f", g1, length(v1), mean(v1), sd(v1), median(v1)),
               sprintf("%s: n=%d mean=%.4f sd=%.4f median=%.4f", g2, length(v2), mean(v2), sd(v2), median(v2)), "")

    dfp <- data.frame(value = c(v1, v2),
                       group = factor(c(rep(g1, length(v1)), rep(g2, length(v2))), levels = c(g1, g2)))
    equalVar <- identical(row$equal_var, "1")
    testType <- row$test
    ranPar <- FALSE

    if (testType %in% c("parametric", "both")) {
        tt <- t.test(v1, v2, var.equal = equalVar)
        emit(cid, "t", unname(tt$statistic), "stats::t.test")
        emit(cid, "df", unname(tt$parameter), "stats::t.test")
        emit(cid, "p", tt$p.value, "stats::t.test")
        de <- effectsize::cohens_d(v1, v2, pooled_sd = TRUE, verbose = FALSE)
        emit(cid, "cohens_d", de$Cohens_d, "effectsize::cohens_d")
        ge <- effectsize::hedges_g(v1, v2, pooled_sd = TRUE, verbose = FALSE)
        emit(cid, "hedges_g", ge$Hedges_g, "effectsize::hedges_g")
        drs <- rstatix::cohens_d(dfp, value ~ group, var.equal = equalVar)
        emit(cid, "cohens_d", drs$effsize, "rstatix::cohens_d")
        lines <- c(lines,
                   sprintf("%s t-test: t=%.4f df=%.2f p=%.4g",
                           if (equalVar) "Student" else "Welch", tt$statistic, tt$parameter, tt$p.value),
                   sprintf("Cohen's d: effectsize=%.4f rstatix=%.4f | Hedges' g (effectsize)=%.4f",
                           de$Cohens_d, drs$effsize, ge$Hedges_g))
        ranPar <- TRUE
    }
    if (testType %in% c("nonparametric", "both")) {
        wt <- suppressWarnings(wilcox.test(v1, v2))
        u1 <- unname(wt$statistic); u2 <- length(v1) * length(v2) - u1
        pName <- if (testType == "both" && ranPar) "mw_p" else "p"
        emit(cid, "u1", u1, "stats::wilcox.test"); emit(cid, "u2", u2, "stats::wilcox.test")
        emit(cid, pName, wt$p.value, "stats::wilcox.test")
        rbe <- effectsize::rank_biserial(v1, v2, verbose = FALSE)
        emit(cid, "rank_biserial", rbe$r_rank_biserial, "effectsize::rank_biserial")
        # rstatix::wilcox_effsize DOES NOT COMPUTE THE RANK-BISERIAL
        # CORRELATION. It computes r = Z / sqrt(N), Rosenthal's r for a
        # Wilcoxon/Mann-Whitney test: a different published quantity, on a
        # different scale, and unsigned (it returns a magnitude, so the
        # direction of the effect is thrown away). Emitting it under the
        # name "rank_biserial" made it look as though two implementations
        # disagreed about one statistic when in fact they agree about two
        # different ones -- and the missing sign showed up in the join as
        # an orientation failure that no amount of reorienting could fix.
        # It is emitted here under its own name; effectsize::rank_biserial
        # is the rank-biserial correlation and matches the plugin exactly.
        wers <- rstatix::wilcox_effsize(dfp, value ~ group)
        emit(cid, "wilcox_r", wers$effsize, "rstatix::wilcox_effsize")
        # p_method: R's wilcox.test.default's own rule -- exact iff both
        # groups have n < 50 AND no ties in the combined sample -- derived
        # independently from the raw vectors, not parsed off wt$method.
        mwHasTies <- length(unique(c(v1, v2))) < length(c(v1, v2))
        mwLarge <- length(v1) >= 50 || length(v2) >= 50
        mwExact <- !mwHasTies && !mwLarge
        mwMethod <- if (mwExact) "exact" else "normal approximation"
        emitText(cid, "p_method",
                 composePMethod(mwMethod, c(if (mwHasTies) "ties present", if (mwLarge) "large sample")),
                 source = "r::composePMethod")
        lines <- c(lines,
                   sprintf("Mann-Whitney: U1=%.1f U2=%.1f p=%.4g", u1, u2, wt$p.value),
                   sprintf("Rank-biserial r (effectsize)=%.4f | wilcox_r = Z/sqrt(N), unsigned (rstatix)=%.4f",
                           rbe$r_rank_biserial, wers$effsize))
    }
    writeReport(cid, lines)
}

# =============================================================================
# emlRunAnovaAnalysis -- one-way ANOVA (+ optional Tukey HSD)
# Classic aov() (equal-variance ANOVA) is the standard call for a one-way
# design; base R's TukeyHSD() is the standard call for its post hoc.
# eta-squared computed from BOTH rstatix::eta_squared and
# effectsize::eta_squared(partial=FALSE) -- one of the six dual quantities;
# for a one-way design (a single factor) they agree by construction.
# Pairwise Cohen's d is always reported (both packages), matching the source
# behaviour of always carrying a d-matrix whether or not Tukey ran.
# TukeyHSD's own convention is "later level - earlier level" (see its row
# names); every diff/CI pair below is reoriented to first-minus-second in
# OUR group_order before being emitted -- this exact reversal is the one
# the kit's README already documents (Soprano-Mezzo 5.5295 vs TukeyHSD's
# Mezzo-Soprano -5.5295), and the emitted values reproduce it.
# =============================================================================
process_anova <- function(row) {
    cid <- row$cell_id
    d <- readDataset(row$dataset)
    prep <- prepGroupedData(cid, d, row$col_a, row$col_b, row$group_order)
    if (is.null(prep)) return(invisible())
    x <- prep$x; g <- prep$g; levs <- prep$levs
    if (length(levs) < 2) { refuseCell(cid, sprintf("Group column '%s' has fewer than 2 groups.", row$col_b)); return(invisible()) }
    gf <- factor(g, levels = levs)
    fit <- aov(x ~ gf)
    s <- summary(fit)[[1]]
    ssB <- s[["Sum Sq"]][1]; ssW <- s[["Sum Sq"]][2]
    dfB <- s[["Df"]][1]; dfW <- s[["Df"]][2]
    if (is.na(dfW) || dfW <= 0) {
        refuseCell(cid, sprintf(
            "No within-group degrees of freedom remain (N=%d, k=%d groups, dfWithin=N-k=%d): every group has too few observations left to estimate an error variance, so F is undefined.",
            length(x), length(levs), dfW))
        return(invisible())
    }
    msB <- s[["Mean Sq"]][1]; msW <- s[["Mean Sq"]][2]   # from aov's own table
    Fval <- unname(s[["F value"]][1]); pval <- unname(s[["Pr(>F)"]][1])
    emit(cid, "f", Fval, "stats::aov"); emit(cid, "df_between", dfB, "stats::aov"); emit(cid, "df_within", dfW, "stats::aov")
    emit(cid, "p", pval, "stats::aov")
    emit(cid, "ss_between", ssB, "stats::aov"); emit(cid, "ss_within", ssW, "stats::aov"); emit(cid, "ss_total", ssB + ssW, "stats::aov")
    emit(cid, "ms_between", msB, "stats::aov"); emit(cid, "ms_within", msW, "stats::aov")
    emit(cid, "n", length(x), "base::length")

    eta_rs <- rstatix::eta_squared(fit)
    emit(cid, "eta_squared", unname(eta_rs[1]), "rstatix::eta_squared")
    eta_es <- effectsize::eta_squared(fit, partial = FALSE, ci = NULL, verbose = FALSE)
    emit(cid, "eta_squared", eta_es$Eta2[1], "effectsize::eta_squared")

    lines <- c(sprintf("One-way ANOVA -- %s by %s (group_order=%s)", row$col_a, row$col_b, row$group_order),
               sprintf("Levels (in order): %s", paste(levs, collapse = ", ")), "",
               sprintf("F(%d,%d)=%.4f p=%.4g", dfB, dfW, Fval, pval),
               sprintf("eta^2: rstatix=%.4f effectsize=%.4f", unname(eta_rs[1]), eta_es$Eta2[1]), "")
    for (lv in levs) {
        v <- x[g == lv]
        lines <- c(lines, sprintf("  %s: n=%d mean=%.4f sd=%.4f median=%.4f", lv, length(v), mean(v), sd(v), median(v)))
    }
    lines <- c(lines, "", "Pairwise Cohen's d (first-minus-second):")
    for (i in seq_along(levs)) for (j in seq_along(levs)) if (i < j) {
        a <- x[g == levs[i]]; b <- x[g == levs[j]]
        pl <- pairLabel(levs[i], levs[j])
        de <- effectsize::cohens_d(a, b, pooled_sd = TRUE, verbose = FALSE)
        dfp <- data.frame(value = c(a, b), group = factor(c(rep(levs[i], length(a)), rep(levs[j], length(b))), levels = c(levs[i], levs[j])))
        # var.equal = TRUE is Cohen's (1988) d: the pooled within-group SD.
        # rstatix's default (var.equal = FALSE) divides by sqrt((s1^2 +
        # s2^2)/2) instead -- a different denominator, and one that
        # contradicts the very model these pairs follow, since the omnibus
        # aov() above assumes homogeneity of variance. Reporting a post hoc
        # effect size under a variance assumption the omnibus test does not
        # make is incoherent regardless of what the other runner prints.
        drs <- rstatix::cohens_d(dfp, value ~ group, var.equal = TRUE)
        emit(cid, paste0("posthoc_", pl, "_cohens_d"), de$Cohens_d, "effectsize::cohens_d")
        emit(cid, paste0("posthoc_", pl, "_cohens_d"), drs$effsize, "rstatix::cohens_d")
        lines <- c(lines, sprintf("  %s: effectsize=%.4f rstatix=%.4f", pl, de$Cohens_d, drs$effsize))
    }
    lines <- c(lines, "")

    if (identical(row$posthoc, "1")) {
        tk <- TukeyHSD(fit)
        tab <- tk[[1]]
        for (rn in rownames(tab)) {
            parts <- strsplit(rn, "-")[[1]]
            lvJ <- parts[1]; lvI <- parts[2]
            iIdx <- match(lvI, levs); jIdx <- match(lvJ, levs)
            first <- levs[min(iIdx, jIdx)]; second <- levs[max(iIdx, jIdx)]
            pl <- pairLabel(first, second)
            diffRaw <- tab[rn, "diff"]; loRaw <- tab[rn, "lwr"]; hiRaw <- tab[rn, "upr"]
            if (iIdx < jIdx) { diffV <- -diffRaw; loV <- -hiRaw; hiV <- -loRaw
            } else { diffV <- diffRaw; loV <- loRaw; hiV <- hiRaw }
            emit(cid, paste0("posthoc_", pl, "_diff"), diffV, "stats::TukeyHSD")
            emit(cid, paste0("posthoc_", pl, "_ci_low"), loV, "stats::TukeyHSD")
            emit(cid, paste0("posthoc_", pl, "_ci_high"), hiV, "stats::TukeyHSD")
            emit(cid, paste0("posthoc_", pl, "_padj"), tab[rn, "p adj"], "stats::TukeyHSD")
            lines <- c(lines, sprintf("Tukey %s: diff=%.4f [%.4f, %.4f] p.adj=%.4g", pl, diffV, loV, hiV, tab[rn, "p adj"]))
        }
    }
    writeReport(cid, lines)
}

# =============================================================================
# emlRunKWAnalysis -- Kruskal-Wallis (+ optional Dunn's post hoc)
# stats::kruskal.test is the standard omnibus call.
# eta-squared[H]: rstatix::kruskal_effsize AND effectsize::rank_eta_squared
# -- both compute the SAME H-based eta-squared quantity (verified against
# rstatix's own source: kruskal_effsize always calls eta_squared_h() in this
# installed version; it has no epsilon-squared option here even though older
# rstatix releases exposed one). This is one of the six dual quantities.
# epsilon-squared: effectsize::rank_epsilon_squared only -- there is no
# rstatix counterpart in this installed version, which is itself a finding
# reported here rather than papered over by mislabelling kruskal_effsize's
# eta2[H] as epsilon-squared.
# Dunn's test: rstatix::dunn_test (there is no dunn.test in base R or any
# other installed package; rstatix's is the standard call). Its own
# `statistic` column is oriented group2-minus-group1 (verified empirically),
# the OPPOSITE of its own group1/group2 label order -- reoriented to
# first-minus-second at emit time, same as Tukey's reversal above.
# Per-pair rank-biserial r (effectsize + rstatix::wilcox_effsize) reported
# alongside Dunn's z/p/padj when post hoc is on, for the same reason a
# statistician reports an effect size beside a post hoc p-value.
# =============================================================================
process_kw <- function(row) {
    cid <- row$cell_id
    d <- readDataset(row$dataset)
    prep <- prepGroupedData(cid, d, row$col_a, row$col_b, row$group_order)
    if (is.null(prep)) return(invisible())
    x <- prep$x; g <- prep$g; levs <- prep$levs
    if (length(levs) < 2) { refuseCell(cid, sprintf("Group column '%s' has fewer than 2 groups.", row$col_b)); return(invisible()) }
    gf <- factor(g, levels = levs)
    kt <- kruskal.test(x, gf)
    emit(cid, "h", unname(kt$statistic), "stats::kruskal.test"); emit(cid, "df", unname(kt$parameter), "stats::kruskal.test")
    emit(cid, "p", kt$p.value, "stats::kruskal.test"); emit(cid, "n", length(x), "base::length")

    dfp <- data.frame(value = x, group = gf)
    ke_rs <- rstatix::kruskal_effsize(dfp, value ~ group)
    emit(cid, "eta_squared", ke_rs$effsize, "rstatix::kruskal_effsize")
    ree <- effectsize::rank_eta_squared(x, gf, ci = NULL, verbose = FALSE)
    emit(cid, "eta_squared", ree$rank_eta_squared, "effectsize::rank_eta_squared")
    ep2 <- effectsize::rank_epsilon_squared(x, gf, ci = NULL, verbose = FALSE)
    emit(cid, "epsilon_squared", ep2$rank_epsilon_squared, "effectsize::rank_epsilon_squared")

    lines <- c(sprintf("Kruskal-Wallis -- %s by %s (group_order=%s)", row$col_a, row$col_b, row$group_order),
               sprintf("Levels: %s", paste(levs, collapse = ", ")), "",
               sprintf("H(%d)=%.4f p=%.4g n=%d", kt$parameter, kt$statistic, kt$p.value, length(x)),
               sprintf("eta^2[H]: rstatix(kruskal_effsize)=%.4f effectsize(rank_eta_squared)=%.4f",
                       ke_rs$effsize, ree$rank_eta_squared),
               sprintf("epsilon^2 (rank): effectsize(rank_epsilon_squared)=%.4f [no rstatix counterpart in this installed version]",
                       ep2$rank_epsilon_squared), "")

    if (identical(row$posthoc, "1")) {
        adj <- .adjMap[[row$adjust]]
        dn <- rstatix::dunn_test(dfp, value ~ group, p.adjust.method = adj)
        lines <- c(lines, sprintf("Dunn's test (%s-adjusted):", row$adjust))
        # rstatix supplies Dunn's z (unrounded, and the part of the test
        # that is actually Dunn's). Its p columns are rounded to 3
        # significant digits, so the raw p is taken as the two-sided
        # standard-normal tail of that same z via stats::pnorm -- reading a
        # tail probability off the package's own statistic, not a
        # re-derivation of the test -- and the family-wise adjustment from
        # stats::p.adjust over the raw vector, which is the procedure
        # rstatix applies internally anyway.
        zAll <- dn$statistic
        pRaw <- 2 * stats::pnorm(-abs(zAll))
        pAdj <- padjust(pRaw, adj)
        for (k in seq_len(nrow(dn))) {
            g1 <- dn$group1[k]; g2 <- dn$group2[k]
            i1 <- match(g1, levs); i2 <- match(g2, levs)
            first <- levs[min(i1, i2)]; second <- levs[max(i1, i2)]
            pl <- pairLabel(first, second)
            zRaw <- dn$statistic[k]
            zOriented <- if (i1 < i2) -zRaw else zRaw
            emit(cid, paste0("posthoc_", pl, "_z"), zOriented, "rstatix::dunn_test")
            emit(cid, paste0("posthoc_", pl, "_p"), pRaw[k], "stats::pnorm")
            emit(cid, paste0("posthoc_", pl, "_padj"), pAdj[k], "stats::p.adjust")
            lines <- c(lines, sprintf("  %s: z=%.4f p=%.4g p.adj=%.4g", pl, zOriented, pRaw[k], pAdj[k]))

            a <- x[g == first]; b <- x[g == second]
            rbe <- effectsize::rank_biserial(a, b, verbose = FALSE)
            dfp2 <- data.frame(value = c(a, b), group = factor(c(rep(first, length(a)), rep(second, length(b))), levels = c(first, second)))
            wers <- rstatix::wilcox_effsize(dfp2, value ~ group)
            emit(cid, paste0("posthoc_", pl, "_rank_biserial"), rbe$r_rank_biserial, "effectsize::rank_biserial")
            lines <- c(lines, sprintf("    rank-biserial r (effectsize)=%.4f ; wilcox_r Z/sqrt(N) (rstatix)=%.4f",
                                       rbe$r_rank_biserial, wers$effsize))
        }
    }
    writeReport(cid, lines)
}

# =============================================================================
# emlRunPairwiseAnalysis -- k-group pairwise post hoc, standalone
#   test: welch/student -> rstatix::t_test (var.equal = student), the
#         package's own all-pairs runner, detailed=TRUE for t/df/CI.
#         wilcoxon -> rstatix::wilcox_test, same shape.
#         scheffe -> evaluated from the published definition, on Ian's
#         ruling. No installed package implements it; DescTools and
#         agricolae do, on CRAN, and neither is reachable from this build.
#         qf and pf do the statistical work and the rest is the definition,
#         so this is not a reimplementation of a procedure. The branch below
#         carries the derivation. This comment said SKIPPED until 27 August
#         2026, when the branch changed and the comment did not.
#   adjust: bonferroni/holm/bh -> p.adjust.method; "none" occurs with
#           scheffe, whose multiplier is itself the simultaneity correction.
# rstatix's own group1/group2 label order already matches our group_order
# (verified empirically: it enumerates all pairs via the factor's level
# order), so no reorientation is needed for t_test/wilcox_test's estimate.
# =============================================================================
process_pairwise <- function(row) {
    cid <- row$cell_id
    d <- readDataset(row$dataset)
    prep <- prepGroupedData(cid, d, row$col_a, row$col_b, row$group_order)
    if (is.null(prep)) return(invisible())
    x <- prep$x; g <- prep$g; levs <- prep$levs
    if (length(levs) < 2) { refuseCell(cid, sprintf("Group column '%s' has fewer than 2 groups.", row$col_b)); return(invisible()) }
    gf <- factor(g, levels = levs)
    dfp <- data.frame(value = x, group = gf)
    test <- row$test
    lines <- c(sprintf("Pairwise (%s, adjust=%s) -- %s by %s (group_order=%s)",
                        test, row$adjust, row$col_a, row$col_b, row$group_order), "")
    emit(cid, "n", length(x), "base::length")
    emit(cid, "k", length(levs), "base::length")

    if (test %in% c("welch", "student")) {
        adj <- .adjMap[[row$adjust]]
        eqv <- identical(test, "student")
        # ORACLE: t.test(var.equal =, conf.level = 1 - alpha/m)$conf.int
        # (docs/WORK_ORDER_INTERVALS_2026-08-26.md item 2). m is THIS row's
        # own pair count; rstatix::t_test's conf.level argument feeds the
        # same interval @emlReportPairwiseComparison computes on its
        # Bonferroni branch, so the two sides agree exactly there.
        #
        # INTERVAL LOGGED ONLY WHERE THE CONTRACT COMPARES IT (28 Aug 2026).
        # Holm and BH define no per-pair simultaneous level, so an interval
        # computed at their plain 1 - alpha was never a bound either program
        # states an outcome in on those rows -- it used to be emitted anyway
        # (quantities.tsv's own retired "R side alone" clause for it), which
        # is noise this run stops logging. Bonferroni is unchanged: its
        # interval is exactly the one the plugin now also fills, and the
        # comparison stays live.
        nPairsHere <- length(levs) * (length(levs) - 1) / 2
        level <- pairLevel(row$adjust, nPairsHere)
        res <- rstatix::t_test(dfp, value ~ group, p.adjust.method = adj,
                                var.equal = eqv, conf.level = level, detailed = TRUE)
        # Raw p from stats::t.test on the same pair (rstatix's is rounded to
        # 3 s.f.), adjusted with stats::p.adjust over that raw vector.
        pRaw <- vapply(seq_len(nrow(res)), function(k) {
            a <- x[g == res$group1[k]]; b <- x[g == res$group2[k]]
            stats::t.test(a, b, var.equal = eqv)$p.value }, numeric(1))
        pAdj <- padjust(pRaw, adj)
        # CROSS-CHECK LEG (28 Aug 2026): stats::pairwise.t.test(pool.sd =
        # FALSE) runs its own per-pair unpooled-variance t-tests and applies
        # the same family-wise correction internally -- a second, independent
        # R code path to the t.test()+p.adjust() combination above, checked
        # against the SAME adjusted p this door already emits. Read out by
        # group name, not position: pairwise.t.test's own row/column order
        # need not match levs, and it fills only the lower triangle.
        pttMat <- stats::pairwise.t.test(x, gf, p.adjust.method = adj, pool.sd = FALSE)$p.value
        pttLookup <- function(g1, g2) {
            if (g1 %in% rownames(pttMat) && g2 %in% colnames(pttMat)) pttMat[g1, g2] else pttMat[g2, g1]
        }
        onBonf <- identical(row$adjust, "bonferroni")
        for (k in seq_len(nrow(res))) {
            pl <- pairLabel(res$group1[k], res$group2[k])
            a <- x[g == res$group1[k]]; b <- x[g == res$group2[k]]
            emit(cid, paste0("posthoc_", pl, "_diff"), res$estimate[k], "rstatix::t_test")
            if (onBonf) {
                emit(cid, paste0("posthoc_", pl, "_ci_low"), res$conf.low[k], "rstatix::t_test")
                emit(cid, paste0("posthoc_", pl, "_ci_high"), res$conf.high[k], "rstatix::t_test")
            }
            emit(cid, paste0("posthoc_", pl, "_p"), pRaw[k], "stats::t.test")
            emit(cid, paste0("posthoc_", pl, "_padj"), pAdj[k], "stats::p.adjust")
            pttVal <- pttLookup(res$group1[k], res$group2[k])
            emit(cid, paste0("posthoc_", pl, "_padj_ptt"), pttVal, "stats::pairwise.t.test")
            emit(cid, paste0("posthoc_", pl, "_df"), res$df[k], "rstatix::t_test")
            emit(cid, paste0("posthoc_", pl, "_t"), res$statistic[k], "rstatix::t_test")
            de <- effectsize::cohens_d(a, b, pooled_sd = TRUE, verbose = FALSE)
            emit(cid, paste0("posthoc_", pl, "_cohens_d"), de$Cohens_d, "effectsize::cohens_d")
            lines <- c(lines, sprintf("  %s: diff=%.4f%s t=%.4f df=%.2f p=%.4g p.adj=%.4g (pairwise.t.test p.adj=%.4g) d=%.4f",
                                       pl, res$estimate[k],
                                       if (onBonf) sprintf(" [%.4f,%.4f] (level=%.4f)", res$conf.low[k], res$conf.high[k], level) else "",
                                       res$statistic[k], res$df[k], pRaw[k], pAdj[k], pttVal, de$Cohens_d))
        }
    } else if (test == "wilcoxon") {
        adj <- .adjMap[[row$adjust]]
        # ORACLE: wilcox.test(conf.int = TRUE, conf.level = 1 - alpha/m).
        # Same level rule as the t branch above, and the same 28 Aug 2026
        # narrowing: the interval is logged only under Bonferroni, where the
        # contract compares it.
        nPairsHere <- length(levs) * (length(levs) - 1) / 2
        level <- pairLevel(row$adjust, nPairsHere)
        res <- rstatix::wilcox_test(dfp, value ~ group, p.adjust.method = adj,
                                     conf.level = level, detailed = TRUE)
        pRaw <- vapply(seq_len(nrow(res)), function(k) {
            a <- x[g == res$group1[k]]; b <- x[g == res$group2[k]]
            suppressWarnings(stats::wilcox.test(a, b))$p.value }, numeric(1))
        pAdj <- padjust(pRaw, adj)
        onBonf <- identical(row$adjust, "bonferroni")
        for (k in seq_len(nrow(res))) {
            pl <- pairLabel(res$group1[k], res$group2[k])
            a <- x[g == res$group1[k]]; b <- x[g == res$group2[k]]
            # THE POINT ESTIMATE IS ORACLED AGAINST median(outer(a, b, "-")),
            # NOT AGAINST wilcox.test's $estimate (docs/RULING_INTERVALS_
            # 2026-08-26.md's Hodges-Lehmann ruling, carried over here
            # verbatim: the shipped plugin's estimate is that median on
            # BOTH branches; wilcox.test's own $estimate is a uniroot
            # artefact on the normal-approximation branch, measured about
            # 4e-5 away from that median on this same kind of data. The two
            # agree exactly on the exact branch (small n, no ties), so this
            # is a deliberate divergence on one branch only, not a
            # slackening of the check. R's own estimate is still emitted,
            # under its own name, so the gap stays visible rather than
            # silently substituted.
            hlEst <- stats::median(outer(a, b, "-"))
            emit(cid, paste0("posthoc_", pl, "_diff"), hlEst, "stats::median")
            emit(cid, paste0("posthoc_", pl, "_diff_wilcoxest"), res$estimate[k], "rstatix::wilcox_test")
            if (onBonf) {
                emit(cid, paste0("posthoc_", pl, "_ci_low"), res$conf.low[k], "rstatix::wilcox_test")
                emit(cid, paste0("posthoc_", pl, "_ci_high"), res$conf.high[k], "rstatix::wilcox_test")
            }
            emit(cid, paste0("posthoc_", pl, "_p"), pRaw[k], "stats::wilcox.test")
            emit(cid, paste0("posthoc_", pl, "_padj"), pAdj[k], "stats::p.adjust")
            emit(cid, paste0("posthoc_", pl, "_u"), unname(suppressWarnings(stats::wilcox.test(a, b))$statistic), "stats::wilcox.test")
            rbe <- effectsize::rank_biserial(a, b, verbose = FALSE)
            emit(cid, paste0("posthoc_", pl, "_rank_biserial"), rbe$r_rank_biserial, "effectsize::rank_biserial")
            lines <- c(lines, sprintf("  %s: hl-diff=%.4f (wilcox.test est=%.4f)%s U1=%.1f p=%.4g p.adj=%.4g rb=%.4f",
                                       pl, hlEst, res$estimate[k],
                                       if (onBonf) sprintf(" [%.4f,%.4f] (level=%.4f)", res$conf.low[k], res$conf.high[k], level) else "",
                                       res$statistic[k], pRaw[k], pAdj[k], rbe$r_rank_biserial))
        }
    } else if (test == "scheffe") {
        # SCHEFFE IS EVALUATED FROM THE PUBLISHED DEFINITION, ON IAN'S RULING.
        # No installed package implements it -- DescTools::ScheffeTest and
        # agricolae::scheffe.test do, on CRAN, and neither is reachable from
        # this build. Evaluating a closed-form definition through R's own F
        # distribution is not a reimplementation of a procedure: qf and pf do
        # the statistical work and the rest is the definition. The README says
        # so and invites the reader to install a package and compare. This is
        # the same core leg validate/v146_scheffe_interval.R already runs.
        #
        #   F      = (diff / SE)^2 / (k - 1)
        #   p      = pf(F, k - 1, dfWithin, lower.tail = FALSE)
        #   half   = sqrt((k - 1) * qf(1 - alpha, k - 1, dfWithin)) * SE
        #
        # LEVEL IS ALPHA DIRECTLY, NEVER ALPHA/M. Scheffe's multiplier is the
        # simultaneity correction; dividing alpha again corrects twice.
        alpha <- EML_ALPHA
        kG <- length(levs)
        ns <- vapply(levs, function(L) sum(g == L), numeric(1))
        ms <- vapply(levs, function(L) mean(x[g == L]), numeric(1))
        dfW <- sum(ns) - kG
        mse <- sum(vapply(seq_along(levs), function(i)
                   (ns[i] - 1) * stats::var(x[g == levs[i]]), numeric(1))) / dfW
        fCrit <- stats::qf(1 - alpha, kG - 1, dfW)
        for (i in seq_len(kG - 1)) for (j in (i + 1):kG) {
            pl   <- pairLabel(levs[i], levs[j])
            diff <- ms[i] - ms[j]
            se   <- sqrt(mse * (1 / ns[i] + 1 / ns[j]))
            fSt  <- (diff / se)^2 / (kG - 1)
            half <- sqrt((kG - 1) * fCrit) * se
            emit(cid, paste0("posthoc_", pl, "_diff"), diff, "stats::mean")
            emit(cid, paste0("posthoc_", pl, "_f"), fSt, "stats::pf")
            emit(cid, paste0("posthoc_", pl, "_padj"),
                 stats::pf(fSt, kG - 1, dfW, lower.tail = FALSE), "stats::pf")
            emit(cid, paste0("posthoc_", pl, "_ci_low"), diff - half, "stats::qf")
            emit(cid, paste0("posthoc_", pl, "_ci_high"), diff + half, "stats::qf")
            lines <- c(lines, sprintf("  %s: diff=%.4f F=%.4f [%.4f,%.4f] (alpha=%.4f)",
                                      pl, diff, fSt, diff - half, diff + half, alpha))
        }
    } else {
        refuseCell(cid, sprintf("Unknown pairwise test '%s'", test)); return(invisible())
    }
    writeReport(cid, lines)
}

# =============================================================================
# emlRunTwoWayAnalysis -- two-way ANOVA (factor1 * factor2, with interaction)
# car::Anova(fit, type=3) under contr.sum: matches the plugin's own kernel
# (@emlAnovaKernelTwoWay, eml-anova-kernel.praat), which computes Types I,
# II and III directly from the raw data and defaults to reporting Type III
# as its headline table -- see
# mailbox/to-opus/RULING_CONSOLIDATED_KERNELS_2026-09-01.md section 2
# ("Oracles: Type III = car::Anova(fit, type = 3) under contr.sum"). This
# leg previously ran Type II deliberately, to avoid tying the oracle to
# whatever unspecified SS type Praat's built-in `Report two-way anova`
# happened to print; now that the plugin computes a real, defined Type III
# itself (no built-in call anywhere on that side, see
# eml-inferential.praat's @emlTwoWayAnova), matching it directly is the
# correct oracle, not an incidental one. contr.sum is set only around the
# fit -- Type III's marginal-effect test is contrast-coding-dependent, so
# the fit itself, not just the car::Anova() call, has to use it; options()
# is restored immediately after, same pattern as afex's own contrasts
# reset around line 158 above.
# On a BALANCED design Types I, II and III agree, so this changed nothing
# for the pre-existing balanced-fixture cells; it matters only on the
# unbalanced/three-level cells this leg's rewrite adds.
# Partial and non-partial eta-squared for every term via effectsize.
# No group_order axis here (matrix.tsv's own header, note B8: this
# procedure never calls @emlCountGroups), so none is read.
# =============================================================================
process_twoway <- function(row) {
    cid <- row$cell_id
    d <- readDataset(row$dataset)
    x <- numcol(d, row$col_a)
    a <- chrcol(d, row$col_b); b <- chrcol(d, row$col_c)
    if (all(is.na(x))) { refuseCell(cid, sprintf("data column '%s' holds no numbers", row$col_a)); return(invisible()) }
    keep <- !is.na(x) & !is.na(a) & a != "" & !is.na(b) & b != ""
    x <- x[keep]; a <- factor(a[keep]); b <- factor(b[keep])
    if (nlevels(a) < 2 || nlevels(b) < 2) {
        refuseCell(cid, sprintf("factor '%s' or '%s' has fewer than 2 levels", row$col_b, row$col_c)); return(invisible())
    }
    dfr <- data.frame(x = x, a = a, b = b)
    oldContrasts <- options(contrasts = c("contr.sum", "contr.poly"))
    fit <- lm(x ~ a * b, data = dfr)
    at <- car::Anova(fit, type = 3)
    options(oldContrasts)
    # Type III's table carries an "(Intercept)" row Type I/II tables do not
    # have; it is not one of the three reported terms and must be dropped
    # here or it falls into the `else` branch below and gets reported as
    # the interaction.
    terms <- rownames(at); terms <- terms[!(terms %in% c("Residuals", "(Intercept)"))]
    dfRes <- at["Residuals", "Df"]; ssRes <- at["Residuals", "Sum Sq"]
    lines <- c(sprintf("Two-way ANOVA (Type III SS, car::Anova, contr.sum) -- %s by %s * %s", row$col_a, row$col_b, row$col_c), "")
    es <- effectsize::eta_squared(at, partial = TRUE, ci = NULL, verbose = FALSE)
    esFull <- effectsize::eta_squared(at, partial = FALSE, ci = NULL, verbose = FALSE)
    # TERMS ARE KEYED BY THE FACTOR'S OWN NAME, not by position. "factor1"
    # depends on which column the declaration happened to pass as col_b
    # versus col_c, so it names nothing a reader can check; the interaction
    # is the two names joined with a double underscore, the same rule the
    # schema uses for a post-hoc pair. factor1_name/factor2_name are emitted
    # alongside so the keys stay self-describing on their own.
    f1 <- slug(row$col_b); f2 <- slug(row$col_c)
    emitText(cid, "factor1_name", f1, "r::slug"); emitText(cid, "factor2_name", f2, "r::slug")
    for (tm in terms) {
        tag <- if (tm == "a") f1 else if (tm == "b") f2 else paste0(f1, "__", f2)
        ss <- at[tm, "Sum Sq"]; dfT <- at[tm, "Df"]; Fv <- at[tm, "F value"]; pv <- at[tm, "Pr(>F)"]
        emit(cid, paste0(tag, "_ss"), ss, "car::Anova")
        emit(cid, paste0(tag, "_df"), dfT, "car::Anova")
        emit(cid, paste0(tag, "_f"), Fv, "car::Anova")
        emit(cid, paste0(tag, "_p"), pv, "car::Anova")
        # A mean square is SS/df by definition -- an identity between two
        # quantities already reported here, not a statistic re-derived.
        emit(cid, paste0(tag, "_ms"), ss / dfT, "car::Anova")
        peta <- es$Eta2_partial[es$Parameter == tm]
        eta <- esFull$Eta2[esFull$Parameter == tm]
        emit(cid, paste0(tag, "_partial_eta_squared"), peta, "effectsize::eta_squared")
        emit(cid, paste0(tag, "_eta_squared"), eta, "effectsize::eta_squared")
        lines <- c(lines, sprintf("%s (%s): F(%.0f,%.0f)=%.4f p=%.4g partial_eta2=%.4f eta2=%.4f",
                                   tag, tm, dfT, dfRes, Fv, pv, peta, eta))
    }
    emit(cid, "ss_within", ssRes, "car::Anova"); emit(cid, "df_within", dfRes, "car::Anova")
    emit(cid, "ms_within", ssRes / dfRes, "car::Anova")
    # NOT sum(at[["Sum Sq"]]): that sum only equals the total SS for a
    # SEQUENTIAL (Type I) decomposition, or incidentally on a balanced
    # design where all types agree. On an unbalanced design a Type II or
    # III effect SS plus the residual does NOT in general add back up to
    # the total -- the same property the plugin's own kernel documents
    # (@emlAnovaKernelTwoWay's header, and the .balanced/.warning$ this
    # leg's Praat side sets). Computed directly instead, the ordinary
    # centred sum of squares about the grand mean -- the one number every
    # SS type agrees is "the total" regardless of how it gets partitioned.
    emit(cid, "ss_total", sum((x - mean(x))^2), "stats::mean")
    emit(cid, "df_total", length(x) - 1, "base::length")
    emit(cid, "n", length(x), "base::length")
    writeReport(cid, lines)
}

# =============================================================================
# emlRunPairedAnalysis -- paired comparison
#   test: parametric (paired t) / nonparametric (Wilcoxon signed-rank) / both
# Cohen's d_z (paired) from BOTH effectsize::cohens_d(paired=TRUE) and
# rstatix::cohens_d(paired=TRUE) -- one of the six dual quantities.
# Matched-pairs rank-biserial from BOTH effectsize::rank_biserial(paired=TRUE)
# and rstatix::wilcox_effsize(paired=TRUE) -- the other formula pair; these
# two disagree in both magnitude AND typical sign convention (verified),
# which is exactly the kind of definitional difference the brief says must
# not be tuned away.
# =============================================================================
process_paired <- function(row) {
    cid <- row$cell_id
    d <- readDataset(row$dataset)
    v1 <- numcol(d, row$col_a); v2 <- numcol(d, row$col_b)
    keep <- !is.na(v1) & !is.na(v2)
    n <- sum(keep); nExcl <- sum(!keep)
    if (n < 2) { refuseCell(cid, "Need at least 2 complete paired observations."); return(invisible()) }
    a <- v1[keep]; b <- v2[keep]
    # A REFUSED CELL CARRIES A REFUSAL, NOT A PARTIAL RESULT. The descriptives
    # below are well defined even when no paired test can run, and emitting
    # them as they were computed left the declared refusal c0384 carrying nine
    # numbers beside its refuse_reason -- a refusal that quietly produces
    # numbers is the thing the declaration's refuse cells exist to catch.
    # They are held here and written only if a test actually ran.
    deferred <- list()
    hold <- function(q, v) deferred[[length(deferred) + 1]] <<- list(q = q, v = v)
    hold("n", n); hold("n_excluded", nExcl)
    hold("mean_group1", mean(a)); hold("mean_group2", mean(b))
    hold("sd_group1", sd(a)); hold("sd_group2", sd(b))
    hold("median_group1", median(a)); hold("median_group2", median(b))
    hold("mean_diff", mean(a) - mean(b))
    lines <- c(sprintf("Paired comparison -- %s vs %s (n=%d, %d excluded)", row$col_a, row$col_b, n, nExcl), "")
    testType <- row$test
    ranPar <- FALSE; ranNon <- FALSE
    if (testType %in% c("parametric", "both")) {
        d_ab <- a - b
        if (sd(d_ab) == 0) {
            # THE ARM WAS ASKED FOR AND PRODUCED NOTHING, WHICH IS A RESULT.
            # quantities.tsv contracts t, df and cohens_dz on every cell whose
            # test axis includes the parametric arm; the report says plainly
            # that the arm was omitted, and the results table has to say the
            # same thing rather than going quiet, or a refused arm reads as an
            # arm nobody asked for.
            emit(cid, "t", NA_real_, "stats::t.test")
            emit(cid, "df", NA_real_, "stats::t.test")
            emit(cid, "cohens_dz", NA_real_, "effectsize::cohens_d")
            lines <- c(lines, "Paired t-test: all differences identical (zero variance) -- omitted.")
        } else {
            tt <- t.test(a, b, paired = TRUE)
            pName <- if (testType == "both") "p" else "p"
            emit(cid, "t", unname(tt$statistic), "stats::t.test"); emit(cid, "df", unname(tt$parameter), "stats::t.test")
            emit(cid, pName, tt$p.value, "stats::t.test")
            # The paired Cohen's d IS d_z (the difference scores' own mean
            # over their own SD). Naming it "cohens_d" invites it to be read
            # as the between-groups d, which it is not.
            de <- effectsize::cohens_d(a, b, paired = TRUE, verbose = FALSE)
            emit(cid, "cohens_dz", de$Cohens_d, "effectsize::cohens_d")
            dfp <- data.frame(val = c(a, b), cond = factor(rep(c("first", "second"), each = n), levels = c("first", "second")))
            drs <- rstatix::cohens_d(dfp, val ~ cond, paired = TRUE)
            emit(cid, "cohens_dz", drs$effsize, "rstatix::cohens_d")
            lines <- c(lines, sprintf("Paired t-test: t=%.4f df=%d p=%.4g, Cohen's d_z: effectsize=%.4f rstatix=%.4f",
                                       tt$statistic, tt$parameter, tt$p.value, de$Cohens_d, drs$effsize))
            ranPar <- TRUE
        }
    }
    if (testType %in% c("nonparametric", "both")) {
        d_ab <- a - b
        if (all(d_ab == 0)) {
            lines <- c(lines, "Wilcoxon signed-rank: all differences are zero -- omitted.")
        } else {
            wt <- suppressWarnings(wilcox.test(a, b, paired = TRUE))
            # If the parametric arm refused (zero-variance differences), the
            # Wilcoxon p is the only p this cell has, so it is "p" -- naming
            # it "wilcoxon_p" would leave the cell with no headline p at all.
            pName <- if (testType == "both" && ranPar) "wilcoxon_p" else "p"
            emit(cid, "w_statistic", unname(wt$statistic), "stats::wilcox.test")
            emit(cid, pName, wt$p.value, "stats::wilcox.test")
            # On test=both the contract owes a wilcoxon_p. Where the
            # parametric arm refused there is no second arm to hold one --
            # this cell's only p is the Wilcoxon p and it is reported under
            # "p" above -- so the second-arm slot is reported as empty rather
            # than left out of the table.
            if (testType == "both" && !ranPar) emit(cid, "wilcoxon_p", NA_real_, "stats::wilcox.test")
            # UPSTREAM BUG, WORKED AROUND AND REPORTED: effectsize 0.8.6
            # returns an UNSIGNED paired rank-biserial when every paired
            # difference has the same magnitude -- +1 whether the first
            # column is uniformly above or uniformly below the second
            # (checked both ways; stats::wilcox.test's V correctly gives 0
            # vs n(n+1)/2 on the same input). The magnitude is right, the
            # direction is dropped. Where every non-zero difference points
            # the same way the sign is not in doubt, so the schema's
            # first-minus-second orientation is restored here. This is sign
            # bookkeeping on a package's output, not a re-derivation.
            rbe <- effectsize::rank_biserial(a, b, paired = TRUE, verbose = FALSE)
            rbVal <- rbe$r_rank_biserial
            dnz <- (a - b)[a != b]
            if (length(dnz) > 0 && all(dnz < 0) && rbVal > 0) rbVal <- -rbVal
            if (length(dnz) > 0 && all(dnz > 0) && rbVal < 0) rbVal <- -rbVal
            emit(cid, "rank_biserial", rbVal, "effectsize::rank_biserial")
            dfp <- data.frame(val = c(a, b), cond = factor(rep(c("first", "second"), each = n), levels = c("first", "second")))
            wers <- rstatix::wilcox_effsize(dfp, val ~ cond, paired = TRUE)
            emit(cid, "wilcox_r", wers$effsize, "rstatix::wilcox_effsize")   # Z/sqrt(N), not rank-biserial
            # p_method: R's wilcox.test.default's own rule -- exact iff
            # n_nonzero < 50 AND no ties among the nonzero |differences|
            # AND no zero differences -- derived independently from d_ab,
            # the same three facts @emlWilcoxonSignedRank computes.
            wsrNonzero <- d_ab[d_ab != 0]
            wsrNZero <- sum(d_ab == 0)
            wsrHasTies <- length(unique(abs(wsrNonzero))) < length(wsrNonzero)
            wsrLarge <- length(wsrNonzero) >= 50
            wsrExact <- !wsrHasTies && !wsrLarge && wsrNZero == 0
            wsrMethod <- if (wsrExact) "exact" else "normal approximation"
            emitText(cid, "p_method",
                     composePMethod(wsrMethod, c(if (wsrHasTies) "ties present",
                                                  if (wsrLarge) "large sample",
                                                  if (wsrNZero > 0) "zero differences")),
                     source = "r::composePMethod")
            lines <- c(lines, sprintf("Wilcoxon signed-rank: W=%.1f p=%.4g, rank-biserial r (effectsize)=%.4f, wilcox_r (rstatix)=%.4f",
                                       wt$statistic, wt$p.value, rbVal, wers$effsize))
            ranNon <- TRUE
        }
    }
    if (!ranPar && !ranNon) {
        refuseCell(cid, sprintf(
            "No paired test could be run: n=%d complete pairs and every pair has the same difference (zero variance in the differences).", n))
        return(invisible())
    }
    deferredSrc <- c(n = "base::sum", n_excluded = "base::sum",
                     mean_group1 = "stats::mean", mean_group2 = "stats::mean",
                     sd_group1 = "stats::sd", sd_group2 = "stats::sd",
                     median_group1 = "stats::median", median_group2 = "stats::median",
                     mean_diff = "stats::mean")
    for (h in deferred) emit(cid, h$q, h$v, unname(deferredSrc[h$q]))
    writeReport(cid, lines)
}

# =============================================================================
# emlRunCorrelationAnalysis -- Pearson and/or Spearman
# stats::cor.test for both -- the standard call. Spearman's p is cor.test's
# own exact/AS89 p (not the large-sample t-approximation some tools use);
# reported as-is.
# =============================================================================
process_correlation <- function(row) {
    cid <- row$cell_id
    d <- readDataset(row$dataset)
    x <- numcol(d, row$col_a); y <- numcol(d, row$col_b)
    keep <- !is.na(x) & !is.na(y)
    n <- sum(keep)
    if (n < 3) { refuseCell(cid, sprintf("Need at least 3 complete pairs for correlation (found %d).", n)); return(invisible()) }
    xx <- x[keep]; yy <- y[keep]
    if (sd(xx) == 0 || sd(yy) == 0) {
        refuseCell(cid, "Zero variance in one column; correlation is undefined."); return(invisible())
    }
    emit(cid, "n", n, "base::sum")
    lines <- c(sprintf("Correlation -- %s with %s (n=%d)", row$col_a, row$col_b, n), "")
    testType <- row$test
    if (testType %in% c("pearson", "both")) {
        pe <- cor.test(xx, yy, method = "pearson")
        emit(cid, "r", unname(pe$estimate), "stats::cor.test")
        emit(cid, "t", unname(pe$statistic), "stats::cor.test")
        emit(cid, "df", unname(pe$parameter), "stats::cor.test")
        emit(cid, "p", pe$p.value, "stats::cor.test")
        # p_method: a LITERAL, not a composition -- Pearson's p never
        # branches between an exact and an approximate null. Always plain
        # "p_method" (never renamed under test=both -- no second Pearson
        # arm to collide with; Spearman's own row below is
        # spearman_p_method there instead).
        emitText(cid, "p_method", "t distribution", source = "stats::cor.test")
        lines <- c(lines, sprintf("Pearson: r=%.4f t(%d)=%.4f p=%.4g", pe$estimate, pe$parameter, pe$statistic, pe$p.value))
    }
    if (testType %in% c("spearman", "both")) {
        sp <- suppressWarnings(cor.test(xx, yy, method = "spearman"))
        emit(cid, "rho", unname(sp$estimate), "stats::cor.test")
        emit(cid, "spearman_s", unname(sp$statistic), "stats::cor.test")
        pName <- if (testType == "both") "spearman_p" else "p"
        emit(cid, pName, sp$p.value, "stats::cor.test")
        # p_method: the plugin's OWN branch law (@emlSpearmanCorrelationDispatch,
        # copied verbatim from cor.test.default's TIES test), derived
        # independently from xx/yy -- NOT parsed off sp$method, which does
        # not name its branch for Spearman (unlike wilcox.test's $method,
        # cor.test's Spearman $method string is the same literal text on
        # both branches; see v147's own header note on this). n <= 1290 is
        # R's own exact-branch cutoff (n*(n^2-1) does not overflow there).
        spHasTies <- min(length(unique(xx)), length(unique(yy))) < n
        spLarge <- n > 1290
        spExact <- !spHasTies && !spLarge
        spMethod <- if (spExact) "exact" else "t approximation"
        spPMethod <- composePMethod(spMethod, c(if (spHasTies) "ties present", if (spLarge) "large sample"))
        pmName <- if (testType == "both") "spearman_p_method" else "p_method"
        emitText(cid, pmName, spPMethod, source = "r::composePMethod")
        # cor.test's default Spearman p is the EXACT permutation p for small
        # n without ties, falling back to AS89. The plugin computes the
        # large-sample t-approximation instead, which is a different p for
        # the same null -- most visibly at rho = 1, where the exact p is
        # 2/n! and the approximation goes to zero. Both are reported, each
        # under its own name, so the difference is pinned to the choice of
        # tail rather than left looking like an arithmetic disagreement.
        spA <- suppressWarnings(cor.test(xx, yy, method = "spearman", exact = FALSE))
        emit(cid, "spearman_p_asymptotic", spA$p.value, "stats::cor.test")
        lines <- c(lines, sprintf("Spearman: rho=%.4f p=%.4g (exact/AS89) ; asymptotic p=%.4g",
                                   sp$estimate, sp$p.value, spA$p.value))
    }
    writeReport(cid, lines)
}

# =============================================================================
# emlRunDescriptiveAnalysis
# psych::describe for the classic shape/location/spread battery (mean, sd,
# median, min, max, range, se, skew, kurtosis) -- the standard one-call
# descriptive summary in R. Quartiles/IQR from stats::quantile (type 7, R's
# default). 95% CI of the mean from stats::t.test(x)$conf.int.
# =============================================================================
process_descriptive <- function(row) {
    cid <- row$cell_id
    d <- readDataset(row$dataset)
    x <- numcol(d, row$col_a)
    nU <- sum(is.na(x)); x <- x[!is.na(x)]
    if (length(x) < 1) { refuseCell(cid, sprintf("Column '%s' contains no valid numeric values.", row$col_a)); return(invisible()) }
    emit(cid, "n", length(x), "base::length")
    desc <- psych::describe(x)
    emit(cid, "mean", desc$mean, "psych::describe"); emit(cid, "sd", desc$sd, "psych::describe")
    emit(cid, "median", desc$median, "psych::describe"); emit(cid, "min", desc$min, "psych::describe")
    emit(cid, "max", desc$max, "psych::describe"); emit(cid, "range", desc$range, "psych::describe")
    emit(cid, "sem", desc$se, "psych::describe")
    emitShape(cid, x)
    emit(cid, "variance", stats::var(x), "stats::var")
    qs <- stats::quantile(x, c(0.25, 0.75))
    emit(cid, "q1", qs[1], "stats::quantile"); emit(cid, "q3", qs[2], "stats::quantile")
    emit(cid, "iqr", stats::IQR(x), "stats::IQR")   # stats::IQR, not q3-q1 written out
    ciLine <- NULL
    # t.test(x) throws "data are essentially constant" when sd(x)==0 (e.g. a
    # column that is literally the same value in every row). That is a real,
    # standard-tool refusal of ONE quantity (the mean's CI), not of the whole
    # descriptive cell -- n/mean/sd/median/etc. are all still well-defined on
    # a constant column, so only the CI is skipped, guarded rather than left
    # to throw and take the whole cell down with it.
    if (length(x) >= 2 && stats::sd(x) > 0) {
        ci <- t.test(x)$conf.int
        emit(cid, "ci_low", ci[1], "stats::t.test"); emit(cid, "ci_high", ci[2], "stats::t.test")
        ciLine <- sprintf("95%% CI of the mean: [%.4f, %.4f] (stats::t.test)", ci[1], ci[2])
    } else if (length(x) >= 2) {
        # REPORTED AS UNDEFINED, NOT OMITTED. quantities.tsv contracts ci_low
        # and ci_high on every descriptive cell, and a runner that writes no
        # row has not reported the quantity -- it has gone quiet, which is the
        # exact failure mode the contract exists to catch. The kit's own
        # convention for "we reached this quantity and it has no value here"
        # is the _undefined marker (n_undefined, gg_epsilon_undefined,
        # chi_square_undefined), so the marker is what goes out.
        emit(cid, "ci_low_undefined", 1, "stats::t.test")
        emit(cid, "ci_high_undefined", 1, "stats::t.test")
        ciLine <- "95% CI of the mean: undefined (zero variance -- t.test's own precondition fails)."
    }
    lines <- c(sprintf("Descriptives -- %s (n=%d valid, %d undefined)", row$col_a, length(x), nU), "",
               sprintf("mean=%.4f sd=%.4f median=%.4f min=%.4f max=%.4f", desc$mean, desc$sd, desc$median, desc$min, desc$max),
               sprintf("skewness=%.4f kurtosis=%.4f (psych::describe)", desc$skew, desc$kurtosis))
    if (!is.null(ciLine)) lines <- c(lines, ciLine)
    writeReport(cid, lines)
}

# --- shared simple-regression fitter, used by both regression procedures ---
fitLM <- function(x, y) {
    fit <- lm(y ~ x)
    sm <- summary(fit)
    list(fit = fit, sm = sm,
         intercept = coef(sm)["(Intercept)", "Estimate"], slope = coef(sm)["x", "Estimate"],
         seIntercept = coef(sm)["(Intercept)", "Std. Error"], seSlope = coef(sm)["x", "Std. Error"],
         tIntercept = coef(sm)["(Intercept)", "t value"], tSlope = coef(sm)["x", "t value"],
         pIntercept = coef(sm)["(Intercept)", "Pr(>|t|)"], pSlope = coef(sm)["x", "Pr(>|t|)"],
         r2 = sm$r.squared, adjR2 = sm$adj.r.squared, sigma = sm$sigma, fstat = sm$fstatistic)
}

# =============================================================================
# emlRunRegressionAnalysis -- simple linear regression (col_a=dep, col_b=pred)
# stats::lm -- the standard call. "r" is the signed sqrt(R^2) (sign of the
# slope), matching the kit's own documented convention for this simple
# (one-predictor) case; not the unsigned multiple-R a package prints for a
# model with more than one predictor.
# =============================================================================
process_regression <- function(row) {
    cid <- row$cell_id
    d <- readDataset(row$dataset)
    y <- numcol(d, row$col_a); x <- numcol(d, row$col_b)
    keep <- !is.na(x) & !is.na(y)
    n <- sum(keep)
    if (n < 3) { refuseCell(cid, sprintf("Need at least 3 non-missing paired observations (found %d).", n)); return(invisible()) }
    xx <- x[keep]; yy <- y[keep]
    if (sd(xx) == 0) { refuseCell(cid, sprintf("Predictor column '%s' has zero variance.", row$col_b)); return(invisible()) }
    fl <- fitLM(xx, yy)
    emit(cid, "n", n, "base::sum")
    emit(cid, "intercept", fl$intercept, "stats::lm"); emit(cid, "slope", fl$slope, "stats::lm")
    emit(cid, "intercept_se", fl$seIntercept, "stats::lm"); emit(cid, "slope_se", fl$seSlope, "stats::lm")
    emit(cid, "intercept_t", fl$tIntercept, "stats::lm"); emit(cid, "slope_t", fl$tSlope, "stats::lm")
    emit(cid, "p", fl$pSlope, "stats::lm")
    emit(cid, "slope_p", fl$pSlope, "stats::lm"); emit(cid, "intercept_p", fl$pIntercept, "stats::lm")
    emit(cid, "df_between", unname(fl$fstat["numdf"]), "stats::lm")
    emit(cid, "df_within", unname(fl$fstat["dendf"]), "stats::lm")
    emit(cid, "r_squared", fl$r2, "stats::lm"); emit(cid, "adj_r_squared", fl$adjR2, "stats::lm")
    emit(cid, "residual_se", fl$sigma, "stats::lm")
    # stats::cor is the package call for this; the signed sqrt(R^2) that
    # stood here was the same number written out by hand, which is exactly
    # what this kit undertakes not to do.
    emit(cid, "r", stats::cor(xx, yy), "stats::cor")
    emit(cid, "f", unname(fl$fstat["value"]), "stats::lm")
    lines <- c(sprintf("Simple regression -- %s ~ %s (n=%d)", row$col_a, row$col_b, n), "",
               sprintf("%s = %.4f + %.4f * %s", row$col_a, fl$intercept, fl$slope, row$col_b),
               sprintf("R^2=%.4f adjR^2=%.4f residual SE=%.4f", fl$r2, fl$adjR2, fl$sigma),
               sprintf("slope: t=%.4f p=%.4g", fl$tSlope, fl$pSlope))
    writeReport(cid, lines)
}

# =============================================================================
# emlRunGroupedRegression -- overall + per-group simple regression
#   col_a=predCol, col_b=respCol, col_c=groupCol
# The `prereq` column (a prior emlRunRegressionAnalysis call, so Praat's
# global namespace already holds the overall fit) is a Praat-only concern:
# Praat's procedures share state through global variables across calls in
# one session, so its grouped-regression orchestrator reads the overall
# fit's numbers from globals a separate earlier call left behind, rather
# than recomputing them. R carries no such cross-call global state here --
# every cell in this file is independent -- so this cell simply fits the
# overall regression itself, directly, with the same stats::lm() call
# process_regression uses. The `prereq` column is read by neither runner's
# math, only (on the Praat side) by its execution order.
# Per-group regressions use groups with n>=3 (Praat's own floor); smaller
# groups are named and skipped in the report, not silently absent.
# =============================================================================
process_grouped_regression <- function(row) {
    cid <- row$cell_id
    d <- readDataset(row$dataset)
    x <- numcol(d, row$col_a); y <- numcol(d, row$col_b); g <- chrcol(d, row$col_c)
    keepAll <- !is.na(x) & !is.na(y)
    if (sum(keepAll) < 3) { refuseCell(cid, "Need at least 3 non-missing paired observations for the overall fit."); return(invisible()) }
    ov <- fitLM(x[keepAll], y[keepAll])
    # The overall fit is prefixed "overall_": a grouped regression reports
    # BOTH an overall line and one line per group, and a bare "slope" here
    # would collide with the per-group keys and with the plain regression
    # procedure's own "slope".
    emit(cid, "overall_intercept", ov$intercept, "stats::lm"); emit(cid, "overall_slope", ov$slope, "stats::lm")
    emit(cid, "overall_intercept_se", ov$seIntercept, "stats::lm"); emit(cid, "overall_slope_se", ov$seSlope, "stats::lm")
    emit(cid, "overall_intercept_t", ov$tIntercept, "stats::lm"); emit(cid, "overall_slope_t", ov$tSlope, "stats::lm")
    emit(cid, "overall_slope_p", ov$pSlope, "stats::lm")
    emit(cid, "overall_intercept_p", ov$pIntercept, "stats::lm")
    emit(cid, "overall_r_squared", ov$r2, "stats::lm"); emit(cid, "overall_adj_r_squared", ov$adjR2, "stats::lm")
    emit(cid, "overall_residual_se", ov$sigma, "stats::lm"); emit(cid, "n", sum(keepAll), "base::sum")

    levs <- orderedLevels(g, row$group_order)
    lines <- c(sprintf("Grouped regression -- %s ~ %s by %s (group_order=%s)", row$col_b, row$col_a, row$col_c, row$group_order), "",
               sprintf("Overall: slope=%.4f intercept=%.4f R^2=%.4f n=%d", ov$slope, ov$intercept, ov$r2, sum(keepAll)), "")
    nRun <- 0
    for (lv in levs) {
        sel <- g == lv & keepAll
        if (sum(sel) >= 3) {
            nRun <- nRun + 1
            gl <- fitLM(x[sel], y[sel])
            tag <- slug(lv)
            emit(cid, paste0("grp_", tag, "_slope"), gl$slope, "stats::lm")
            emit(cid, paste0("grp_", tag, "_intercept"), gl$intercept, "stats::lm")
            emit(cid, paste0("grp_", tag, "_slope_se"), gl$seSlope, "stats::lm")
            emit(cid, paste0("grp_", tag, "_slope_t"), gl$tSlope, "stats::lm")
            emit(cid, paste0("grp_", tag, "_p"), gl$pSlope, "stats::lm")
            emit(cid, paste0("grp_", tag, "_r_squared"), gl$r2, "stats::lm")
            emit(cid, paste0("grp_", tag, "_n"), sum(sel), "base::sum")
            lines <- c(lines, sprintf("  %s (n=%d): slope=%.4f intercept=%.4f R^2=%.4f p=%.4g",
                                       lv, sum(sel), gl$slope, gl$intercept, gl$r2, gl$pSlope))
        } else {
            lines <- c(lines, sprintf("  %s (n=%d): skipped, fewer than 3 complete pairs", lv, sum(sel)))
        }
    }
    emit(cid, "pg_total", length(levs), "base::length")
    emit(cid, "pg_run", nRun, "base::length")
    emit(cid, "pg_skipped", length(levs) - nRun, "base::length")
    writeReport(cid, lines)
}

# =============================================================================
# emlRunNormalityAnalysis -- Shapiro-Wilk + skewness/kurtosis
# stats::shapiro.test is the standard formal test; psych::describe supplies
# skewness and excess kurtosis (the descriptive backstop). The matrix's
# `test` axis selects no test on this procedure (see matrix.tsv's own note
# B5: "both"/"auto" behave identically) -- both families are always computed.
# =============================================================================
process_normality <- function(row) {
    cid <- row$cell_id
    d <- readDataset(row$dataset)
    x <- numcol(d, row$col_a)
    nU <- sum(is.na(x)); x <- x[!is.na(x)]
    if (length(x) < 3) { refuseCell(cid, sprintf("Need at least 3 non-missing values (found %d).", length(x))); return(invisible()) }
    desc <- psych::describe(x)
    emit(cid, "n", length(x), "base::length")
    emitShape(cid, x)
    emit(cid, "mean", desc$mean, "psych::describe"); emit(cid, "sd", desc$sd, "psych::describe"); emit(cid, "median", desc$median, "psych::describe")
    lines <- c(sprintf("Normality -- %s (n=%d, %d undefined)", row$col_a, length(x), nU), "")
    if (length(x) <= 5000 && length(unique(x)) > 1) {
        sw <- shapiro.test(x)
        emit(cid, "w_statistic", unname(sw$statistic), "stats::shapiro.test")
        emit(cid, "p", sw$p.value, "stats::shapiro.test")
        lines <- c(lines, sprintf("Shapiro-Wilk: W=%.4f p=%.4g", sw$statistic, sw$p.value))
    } else {
        # Reported as undefined, not omitted: the contract owes w_statistic
        # and p on every normality cell, and "the column is constant so the
        # test has no variance to work on" is an answer, not a silence.
        emit(cid, "w_statistic", NA_real_, "stats::shapiro.test")
        emit(cid, "p", NA_real_, "stats::shapiro.test")
        lines <- c(lines, "Shapiro-Wilk not computed (n out of [3,5000] or zero range).")
    }
    lines <- c(lines, sprintf("skewness=%.4f kurtosis=%.4f (psych::describe)", desc$skew, desc$kurtosis))
    writeReport(cid, lines)
}

# --- shared repeated-measures helpers ---------------------------------------
parseConditions <- function(colspec) {
    parts <- strsplit(colspec, "\\|")[[1]]
    parts[nzchar(trimws(parts))]
}
buildConditionMatrix <- function(d, conds) {
    M <- do.call(cbind, lapply(conds, function(cc) numcol(d, cc)))
    colnames(M) <- conds
    keep <- stats::complete.cases(M)
    list(M = M[keep, , drop = FALSE], nExcluded = sum(!keep), n = sum(keep))
}

# =============================================================================
# emlRunRepeatedMeasuresAnalysis -- one-way repeated-measures ANOVA
# afex::aov_ez is the standard statistician's call for within-subject ANOVA
# with automatic Greenhouse-Geisser sphericity correction (afex is the
# package the brief names for exactly this; it wraps car::Anova(..., type=3)
# internally on the wide-format model and reports GG epsilon and the
# GG-corrected p directly via summary()). Complete-case listwise deletion
# on the condition columns, same as the source procedure. Partial eta
# squared from effectsize::eta_squared(fit, partial=TRUE).
# Post hoc: rstatix::t_test(paired=TRUE) over every condition pair,
# adjusted -- the same all-pairs runner used for the between-subjects
# pairwise procedure, just told paired=TRUE.
# GG correction is only reported when k>2 (more than one within-subject df);
# at k=2 there is exactly one contrast, sphericity is trivially satisfied,
# and afex's own epsilon comes back NA there (verified) -- reporting a
# "corrected p" in that case would misstate what was actually computed.
# =============================================================================
process_rm <- function(row) {
    cid <- row$cell_id
    conds <- parseConditions(row$col_a)
    if (length(conds) < 2) { refuseCell(cid, "Need at least 2 condition columns."); return(invisible()) }
    d <- readDataset(row$dataset)
    cm <- buildConditionMatrix(d, conds)
    M <- cm$M; n <- cm$n; k <- length(conds)
    if (n < 2) { refuseCell(cid, sprintf("Need at least 2 complete subjects (found %d).", n)); return(invisible()) }
    long <- data.frame(id = rep(seq_len(n), times = k),
                        cond = factor(rep(conds, each = n), levels = conds),
                        val = as.vector(M))
    fitAndSummary <- tryCatch({
        fit0 <- suppressWarnings(afex::aov_ez(id = "id", dv = "val", data = long, within = "cond",
                                               anova_table = list(correction = "GG"), factorize = FALSE))
        s0 <- suppressWarnings(summary(fit0))
        list(fit = fit0, s = s0)
    }, error = function(e) e)
    if (inherits(fitAndSummary, "error")) {
        refuseCell(cid, sprintf(
            "Repeated-measures ANOVA could not be fit (afex::aov_ez / summary): %s -- typically zero subject-by-condition residual variance on the complete cases.",
            conditionMessage(fitAndSummary)))
        return(invisible())
    }
    fit <- fitAndSummary$fit; s <- fitAndSummary$s
    ut <- s$univariate.tests
    if (!("cond" %in% rownames(ut))) { refuseCell(cid, "afex produced no 'cond' effect row (degenerate design)."); return(invisible()) }
    ssCond <- ut["cond", "Sum Sq"]; ssErr <- ut["cond", "Error SS"]
    dfCond <- ut["cond", "num Df"]; dfErr <- ut["cond", "den Df"]
    Fval <- ut["cond", "F value"]; pval <- ut["cond", "Pr(>F)"]
    if (ssErr <= 0 || is.na(Fval) || is.infinite(Fval)) {
        refuseCell(cid, sprintf(
            "Zero subject-by-condition residual variance on the %d complete case(s) (error SS=%.6g); the F-ratio is undefined or degenerate.", n, ssErr))
        return(invisible())
    }
    petaES <- effectsize::eta_squared(fit, partial = TRUE, ci = NULL, verbose = FALSE)
    peta <- petaES$Eta2_partial[petaES$Parameter == "cond"]

    emit(cid, "f", Fval, "afex::aov_ez"); emit(cid, "df_between", dfCond, "afex::aov_ez"); emit(cid, "df_within", dfErr, "afex::aov_ez")
    emit(cid, "p", pval, "afex::aov_ez")
    emit(cid, "ss_between", ssCond, "afex::aov_ez"); emit(cid, "ss_within", ssErr, "afex::aov_ez")
    emit(cid, "partial_eta_squared", peta, "effectsize::eta_squared")
    emit(cid, "n", n, "base::sum"); emit(cid, "n_excluded", cm$nExcluded, "base::sum")
    for (cc in conds) emit(cid, paste0("mean_", slug(cc)), mean(M[, cc]), "stats::mean")

    lines <- c(sprintf("Repeated-measures ANOVA (afex::aov_ez, GG correction) -- %s", paste(conds, collapse = ", ")),
               sprintf("n=%d k=%d", n, k),
               sprintf("F(%.3f,%.3f)=%.4f p=%.4g", dfCond, dfErr, Fval, pval))
    if (k > 2) {
        pa <- s$pval.adjustments
        ggEps <- pa["cond", "GG eps"]; ggP <- pa["cond", "Pr(>F[GG])"]
        # afex CANNOT ALWAYS COMPUTE GG, AND SAYS SO WITH AN NA EPSILON --
        # but in the same row it still prints Pr(>F[GG]) as 0. That 0 is a
        # sentinel, not a p-value (it appeared on a 2-subject design where
        # the error SSP matrix is singular and summary.Anova.mlm warns that
        # "corresponding non-sphericity tests and corrections not
        # available"). Emitting it produced a p of exactly zero in the
        # results table. Epsilon gates the pair: no epsilon, no GG row.
        if (is.na(ggEps)) {
            emit(cid, "gg_epsilon", NA_real_, "afex::aov_ez")
            emit(cid, "gg_p", NA_real_, "afex::aov_ez")
            lines <- c(lines, paste0("Greenhouse-Geisser: not available -- afex returned NA epsilon ",
                                      "(singular error SSP matrix on this design); its Pr(>F[GG]) of 0 ",
                                      "is a sentinel, not a p-value, and is not reported."))
        } else {
            emit(cid, "gg_epsilon", ggEps, "afex::aov_ez"); emit(cid, "gg_p", ggP, "afex::aov_ez")
            lines <- c(lines, sprintf("Greenhouse-Geisser epsilon=%.4f, GG-corrected p=%.4g", ggEps, ggP))
        }
    } else {
        # k = 2. Sphericity is trivial with one within-subject df, so afex
        # reports no correction -- and the plugin falls back to the epsilon
        # lower bound 1/(k-1) and reports one. Both are defensible and they
        # are DIFFERENT, which is exactly why both sides have to say
        # something: the pair is reported as undefined here rather than
        # dropped, so the disagreement stays visible as a disagreement.
        emit(cid, "gg_epsilon", NA_real_, "afex::aov_ez")
        emit(cid, "gg_p", NA_real_, "afex::aov_ez")
        lines <- c(lines, "Greenhouse-Geisser correction not applicable (k=2 conditions, 1 df; sphericity is trivial).")
    }
    lines <- c(lines, sprintf("partial eta^2 (effectsize)=%.4f", peta), "")

    if (identical(row$posthoc, "1")) {
        adj <- .adjMap[[row$adjust]]
        # ORACLE: t.test(paired = TRUE, conf.level = 1 - alpha/m)$conf.int
        # (docs/WORK_ORDER_INTERVALS_2026-08-26.md item 4, paired-t branch).
        # Same bonferroni-only level rule as the standalone pairwise door.
        nPairsHere <- k * (k - 1) / 2
        level <- pairLevel(row$adjust, nPairsHere)
        res <- tryCatch(rstatix::t_test(long, val ~ cond, paired = TRUE, p.adjust.method = adj,
                                         conf.level = level, detailed = TRUE),
                         error = function(e) e)
        if (inherits(res, "error")) {
            lines <- c(lines, sprintf("Post hoc paired t: could not be computed (%s).", conditionMessage(res)))
        } else {
            lines <- c(lines, sprintf("Post hoc paired t (%s-adjusted, level=%.4f):", row$adjust, level))
            pRaw <- vapply(seq_len(nrow(res)), function(kk) {
                aa <- M[, res$group1[kk]]; bb <- M[, res$group2[kk]]
                if (stats::sd(aa - bb) == 0) NA_real_ else stats::t.test(aa, bb, paired = TRUE)$p.value },
                numeric(1))
            pAdj <- padjust(pRaw, adj)
            for (kk in seq_len(nrow(res))) {
                pl <- pairLabel(res$group1[kk], res$group2[kk])
                emit(cid, paste0("posthoc_", pl, "_diff"), res$estimate[kk], "rstatix::t_test")
                if (identical(row$adjust, "bonferroni")) {
                    emit(cid, paste0("posthoc_", pl, "_ci_low"), res$conf.low[kk], "rstatix::t_test")
                    emit(cid, paste0("posthoc_", pl, "_ci_high"), res$conf.high[kk], "rstatix::t_test")
                }
                emit(cid, paste0("posthoc_", pl, "_p"), pRaw[kk], "stats::t.test")
                emit(cid, paste0("posthoc_", pl, "_padj"), pAdj[kk], "stats::p.adjust")
                lines <- c(lines, sprintf("  %s: diff=%.4f [%.4f,%.4f] p=%.4g p.adj=%.4g",
                                           pl, res$estimate[kk], res$conf.low[kk], res$conf.high[kk], pRaw[kk], pAdj[kk]))
            }
        }
    }
    writeReport(cid, lines)
}

# =============================================================================
# emlRunFriedmanAnalysis -- Friedman's rank test (+ optional post hoc)
# stats::friedman.test -- the standard call, taking the subject-by-condition
# matrix directly. Kendall's W from BOTH rstatix::friedman_effsize and
# effectsize::kendalls_w -- one of the six dual quantities; both call the
# same underlying formula so they agree here, which is corroboration, not
# redundancy.
# Post hoc: rstatix::wilcox_test(paired=TRUE) over every condition pair.
# =============================================================================
process_friedman <- function(row) {
    cid <- row$cell_id
    conds <- parseConditions(row$col_a)
    if (length(conds) < 2) { refuseCell(cid, "Need at least 2 condition columns."); return(invisible()) }
    d <- readDataset(row$dataset)
    cm <- buildConditionMatrix(d, conds)
    M <- cm$M; n <- cm$n; k <- length(conds)
    if (n < 2) { refuseCell(cid, sprintf("Need at least 2 complete subjects (found %d).", n)); return(invisible()) }
    ft <- tryCatch(stats::friedman.test(M), error = function(e) e)
    if (inherits(ft, "error")) { refuseCell(cid, sprintf("Friedman test failed: %s", conditionMessage(ft))); return(invisible()) }
    emit(cid, "chi_square", unname(ft$statistic), "stats::friedman.test"); emit(cid, "df", unname(ft$parameter), "stats::friedman.test")
    emit(cid, "p", ft$p.value, "stats::friedman.test"); emit(cid, "n", n, "base::sum")
    emit(cid, "n_excluded", cm$nExcluded, "base::sum")
    long <- data.frame(id = rep(seq_len(n), times = k), cond = factor(rep(conds, each = n), levels = conds), val = as.vector(M))
    kw_rs <- rstatix::friedman_effsize(long, val ~ cond | id)
    emit(cid, "kendalls_w", kw_rs$effsize, "rstatix::friedman_effsize")
    kw_es <- tryCatch(effectsize::kendalls_w(val ~ cond | id, data = long, ci = NULL, verbose = FALSE), error = function(e) NULL)
    if (!is.null(kw_es)) emit(cid, "kendalls_w", kw_es$Kendalls_W, "effectsize::kendalls_w")
    lines <- c(sprintf("Friedman test -- %s", paste(conds, collapse = ", ")),
               sprintf("n=%d k=%d", n, k),
               sprintf("chi-square(%d)=%.4f p=%.4g", ft$parameter, ft$statistic, ft$p.value),
               sprintf("Kendall's W: rstatix=%.4f%s", kw_rs$effsize,
                       if (!is.null(kw_es)) sprintf(" effectsize=%.4f", kw_es$Kendalls_W) else ""), "")
    if (identical(row$posthoc, "1")) {
        adj <- .adjMap[[row$adjust]]
        res <- tryCatch(rstatix::wilcox_test(long, val ~ cond, paired = TRUE, p.adjust.method = adj, detailed = TRUE),
                         error = function(e) e)
        if (inherits(res, "error")) {
            lines <- c(lines, sprintf("Post hoc Wilcoxon signed-rank: could not be computed (%s).", conditionMessage(res)))
        } else {
            lines <- c(lines, sprintf("Post hoc Wilcoxon signed-rank (%s-adjusted):", row$adjust))
            pRaw <- vapply(seq_len(nrow(res)), function(kk) {
                aa <- M[, res$group1[kk]]; bb <- M[, res$group2[kk]]
                if (all(aa - bb == 0)) NA_real_ else suppressWarnings(stats::wilcox.test(aa, bb, paired = TRUE))$p.value },
                numeric(1))
            pAdj <- padjust(pRaw, adj)
            # ORACLE: the paired/signed-rank estimate is the median of the
            # n(n+1)/2 Walsh averages (d[i]+d[j])/2, i<=j, of the within-
            # subject differences (docs/WORK_ORDER_INTERVALS_2026-08-26.md
            # item 4's one-sample form) -- NOT wilcox.test's own $estimate,
            # for the same reason as the two-sample pairwise door above: on
            # the normal-approximation branch that estimate is a uniroot
            # artefact, not the published Walsh-average median. Interval
            # bounds are deliberately NOT emitted here, even though `res`
            # itself carries conf.low/conf.high columns (checked directly
            # against this installed rstatix): no emit() call for them
            # existed in this door before this change, and quantities.tsv's
            # contract row for posthoc_<PAIR>_ci_low/_ci_high on this
            # procedure marks that a standing, accepted R-side gap --
            # "praat" side alone, the mirror of D-SCHEFFE -- not something
            # this item closes. Adding it would be outside this item's
            # stated scope (CLAUDE.md, "Scope of work units"), so it stays
            # unfilled here.
            walsh <- function(d) { m <- outer(d, d, `+`); sort(m[!lower.tri(m)]) / 2 }
            for (kk in seq_len(nrow(res))) {
                pl <- pairLabel(res$group1[kk], res$group2[kk])
                aa <- M[, res$group1[kk]]; bb <- M[, res$group2[kk]]
                hlEst <- stats::median(walsh(aa - bb))
                emit(cid, paste0("posthoc_", pl, "_diff"), hlEst, "stats::median")
                emit(cid, paste0("posthoc_", pl, "_diff_wilcoxest"), res$estimate[kk], "rstatix::wilcox_test")
                emit(cid, paste0("posthoc_", pl, "_p"), pRaw[kk], "stats::wilcox.test")
                emit(cid, paste0("posthoc_", pl, "_padj"), pAdj[kk], "stats::p.adjust")
                lines <- c(lines, sprintf("  %s: hl-diff=%.4f (wilcox.test est=%.4f) p=%.4g p.adj=%.4g",
                                           pl, hlEst, res$estimate[kk], pRaw[kk], pAdj[kk]))
            }
        }
    }
    writeReport(cid, lines)
}

# =============================================================================
# Survey lane: emlCronbachAlpha, emlAlphaInfluence, emlChiSquareIndependence,
# emlWilsonInterval -- these take a whole CSV as a matrix (Cronbach/
# AlphaInfluence/ChiSquare) or a named case row (Wilson), not column
# arguments off a table the way the analysis lane does.
# =============================================================================

# emlCronbachAlpha: psych::alpha for raw alpha and per-item alpha-if-deleted,
# psych::alpha.ci for the Feldt (1965) F-based confidence interval at the
# matrix's requested `conf` level -- both are the package's own standard
# calls, chosen because items are already assumed scored in a consistent
# direction (per the source procedure's own documented assumption), so
# check.keys is left FALSE rather than letting psych auto-reverse-score
# items on a correlation heuristic that could silently redefine the scale.
process_cronbach <- function(row) {
    cid <- row$cell_id
    d <- readDataset(row$dataset)
    M <- as.matrix(as.data.frame(lapply(d, function(col) suppressWarnings(as.numeric(col)))))
    conf <- as.numeric(row$conf)
    keep <- stats::complete.cases(M)
    Mc <- M[keep, , drop = FALSE]
    k <- ncol(Mc); n <- nrow(Mc); nExcl <- sum(!keep)
    if (k < 2) { refuseCell(cid, sprintf("Alpha needs at least 2 items; the matrix has %d.", k)); return(invisible()) }
    if (n < 3) {
        refuseCell(cid, sprintf("Alpha needs at least 3 complete respondents; %d arrived and %d remained after listwise deletion.",
                                 nrow(M), n))
        return(invisible())
    }
    a <- psych::alpha(Mc, check.keys = FALSE, warnings = FALSE)
    alphaVal <- unname(a$total$raw_alpha)
    ci <- psych::alpha.ci(alphaVal, n.obs = n, n.var = k, p.val = 1 - conf)
    emit(cid, "alpha", alphaVal, "psych::alpha")
    emit(cid, "alpha_ci_low", ci$lower.ci, "psych::alpha.ci")
    emit(cid, "alpha_ci_high", ci$upper.ci, "psych::alpha.ci")
    emit(cid, "n", n, "base::nrow"); emit(cid, "k", k, "base::ncol")
    emit(cid, "n_excluded", nExcl, "base::sum")
    lines <- c(sprintf("Cronbach's alpha -- %s (conf=%.2f)", row$dataset, conf),
               sprintf("n=%d (excluded %d) k=%d", n, nExcl, k),
               sprintf("alpha=%.4f  CI[%.4f, %.4f] (psych::alpha / psych::alpha.ci, Feldt)", alphaVal, ci$lower.ci, ci$upper.ci), "")
    if (k >= 3) {
        # Keyed by the item's own column name, not its position: a column
        # reordering must not silently re-point these keys at other items.
        dropAlpha <- a$alpha.drop$raw_alpha
        itemNames <- colnames(Mc)
        for (j in seq_len(k)) {
            emit(cid, paste0("alpha_if_deleted_", slug(itemNames[j])), dropAlpha[j], "psych::alpha")
            lines <- c(lines, sprintf("  alpha if item %s deleted = %.4f", itemNames[j], dropAlpha[j]))
        }
    }
    writeReport(cid, lines)
}

# emlAlphaInfluence: leave-one-out over RESPONDENTS. There is no dedicated
# "respondent influence" function in psych or any other installed package,
# so this is built the way a jackknife is properly built in R: by calling
# the package's OWN alpha estimator (psych::alpha) once per row removed,
# never by re-deriving alpha's formula by hand. That is composition of an
# installed function, not a hand-rolled statistic.
process_alpha_influence <- function(row) {
    cid <- row$cell_id
    d <- readDataset(row$dataset)
    M <- as.matrix(as.data.frame(lapply(d, function(col) suppressWarnings(as.numeric(col)))))
    keep <- stats::complete.cases(M)
    Mc <- M[keep, , drop = FALSE]
    origIdx <- which(keep)
    k <- ncol(Mc); n <- nrow(Mc)
    if (k < 2) { refuseCell(cid, sprintf("Alpha needs at least 2 items; the matrix has %d.", k)); return(invisible()) }
    if (n < 3) {
        refuseCell(cid, sprintf(
            "Respondent influence needs at least 3 complete respondents (leave-one-out on fewer would rest on a single row); %d arrived and %d remained after listwise deletion.",
            nrow(M), n))
        return(invisible())
    }
    full <- psych::alpha(Mc, check.keys = FALSE, warnings = FALSE)
    alphaFull <- unname(full$total$raw_alpha)
    deltas <- numeric(n)
    for (j in seq_len(n)) {
        sub <- Mc[-j, , drop = FALSE]
        aj <- tryCatch(psych::alpha(sub, check.keys = FALSE, warnings = FALSE), error = function(e) NULL)
        deltas[j] <- if (is.null(aj)) NA_real_ else unname(aj$total$raw_alpha) - alphaFull
    }
    emit(cid, "alpha", alphaFull, "psych::alpha"); emit(cid, "n", n, "base::nrow"); emit(cid, "k", k, "base::ncol")
    lines <- c(sprintf("Alpha respondent influence (leave-one-out via psych::alpha) -- %s", row$dataset),
               sprintf("n=%d k=%d alpha_full=%.4f", n, k, alphaFull), "")
    if (any(!is.na(deltas))) {
        dmax <- max(abs(deltas), na.rm = TRUE)
        whichMax <- which(abs(deltas) == dmax)[1]
        emit(cid, "delta_max", dmax, "psych::alpha")
        emit(cid, "delta_max_row", origIdx[whichMax], "psych::alpha")
        lines <- c(lines, sprintf("largest |delta| = %.4f at original row %d", dmax, origIdx[whichMax]))
    }
    emit(cid, "n_excluded", nrow(M) - n, "base::nrow")
    for (j in seq_len(n)) {
        emit(cid, paste0("delta_row_", origIdx[j]), deltas[j], "psych::alpha")
        lines <- c(lines, sprintf("  row %d removed: delta=%s", origIdx[j], if (is.na(deltas[j])) "NA" else sprintf("%.4f", deltas[j])))
    }
    writeReport(cid, lines)
}

# emlChiSquareIndependence: stats::chisq.test -- the standard call.
# correct=TRUE applies R's own Yates continuity correction, which (matching
# the source procedure, and matching R's own chisq.test behaviour) only
# takes effect on a 2x2 table; chisq.test silently ignores `correct` on
# larger tables, which is the standard, well-documented R behaviour, not a
# workaround. Cramer's V from BOTH rstatix::cramer_v and
# effectsize::cramers_v -- one of the six dual quantities. NOTE: an earlier
# comment here claimed both packages default to the bias-adjusted (Bergsma)
# form. That is true of effectsize and FALSE of rstatix, whose default is
# Yates continuity correction; the two defaults differ from each other and
# from the plain V, which is why all three numbers differed. See the call
# site below for what each is now passed and why.
process_chisq <- function(row) {
    cid <- row$cell_id
    d <- readDataset(row$dataset)
    M <- as.matrix(as.data.frame(lapply(d, function(col) suppressWarnings(as.numeric(col)))))
    if (nrow(M) < 2 || ncol(M) < 2) { refuseCell(cid, sprintf("The contingency table must be at least 2x2; it is %dx%d.", nrow(M), ncol(M))); return(invisible()) }
    if (any(is.na(M))) { refuseCell(cid, "The table contains an undefined cell."); return(invisible()) }
    if (any(M < 0)) { refuseCell(cid, "Counts must be non-negative."); return(invisible()) }
    if (any(rowSums(M) == 0) || any(colSums(M) == 0)) { refuseCell(cid, "Every row and column must contain at least one observation."); return(invisible()) }
    correction <- identical(row$correction, "1")
    ct <- suppressWarnings(stats::chisq.test(M, correct = correction))
    emit(cid, "chi_square", unname(ct$statistic), "stats::chisq.test"); emit(cid, "df", unname(ct$parameter), "stats::chisq.test")
    emit(cid, "p", ct$p.value, "stats::chisq.test"); emit(cid, "n", sum(M), "base::sum")
    emit(cid, "min_expected", min(ct$expected), "stats::chisq.test")
    emit(cid, "n_cells_below5", sum(ct$expected < 5), "stats::chisq.test")
    # BOTH PACKAGES' DEFAULTS ARE WRONG FOR THIS CELL, IN DIFFERENT WAYS.
    #   rstatix::cramer_v(correct = TRUE) is its default and applies Yates'
    #   continuity correction to the 2x2 chi-square before taking the root.
    #   The declaration has a `correction` axis and this cell may say 0;
    #   leaving the default in place ignored the axis outright and produced
    #   a Yates-corrected V on cells declared uncorrected. It is now passed
    #   the row's own value, like chisq.test above.
    #   effectsize::cramers_v(adjust = TRUE) is its default and returns
    #   Bergsma's (2013) bias-corrected V, which is a different, separately
    #   published statistic -- fine to report, wrong to report under the
    #   bare name "cramers_v". Both are emitted, each under its own name.
    # YATES CORRECTS A TEST, NOT AN EFFECT SIZE. The continuity correction
    # exists to improve the chi-square approximation when deciding
    # significance; Cramer's V is a descriptive measure of association and
    # is conventionally taken from the UNCORRECTED Pearson chi-square.
    # rstatix's default (correct = TRUE) shrinks V on every 2x2 table, which
    # is why its V disagreed with both the plugin and effectsize -- the two
    # of the three implementations here that use the uncorrected statistic.
    # The declaration's `correction` axis governs chisq.test above, where it
    # belongs; it is deliberately not carried into V. rstatix's corrected
    # value is still reported, under a name that says what it is.
    cv_rs <- rstatix::cramer_v(M, correct = FALSE)
    emit(cid, "cramers_v", cv_rs, "rstatix::cramer_v")
    emit(cid, "cramers_v_yates", rstatix::cramer_v(M, correct = TRUE), "rstatix::cramer_v")
    cv_es <- effectsize::cramers_v(M, adjust = FALSE, ci = NULL, verbose = FALSE)
    emit(cid, "cramers_v", cv_es[[1]][1], "effectsize::cramers_v")
    cv_adj <- effectsize::cramers_v(M, adjust = TRUE, ci = NULL, verbose = FALSE)
    emit(cid, "cramers_v_bias_corrected", cv_adj[[1]][1], "effectsize::cramers_v")
    lines <- c(sprintf("Chi-square test of independence -- %s (correction=%s)", row$dataset, correction),
               sprintf("chi-square(%d)=%.4f p=%.4g", ct$parameter, ct$statistic, ct$p.value),
               sprintf("Cramer's V: rstatix=%.4f effectsize=%.4f | Bergsma bias-corrected=%.4f",
                       cv_rs, cv_es[[1]][1], cv_adj[[1]][1]),
               sprintf("min expected=%.4f, cells<5: %d/%d", min(ct$expected), sum(ct$expected < 5), length(ct$expected)), "")
    writeReport(cid, lines)
}

# emlWilsonInterval: stats::prop.test(correct=FALSE) -- verified empirically
# to reproduce the plain Wilson score interval to full precision (no
# continuity correction), which is exactly the interval the source procedure
# documents itself against. col_a names a case row in the fixture; conf
# comes from the matrix, not from the fixture's own stored `conf` column
# (matrix.tsv's own note B10: crossed at three levels regardless of the
# row's single stored value).
process_wilson <- function(row) {
    cid <- row$cell_id
    d <- readDataset(row$dataset)
    caseCol <- d[["case"]]
    idx <- which(trimws(caseCol) == trimws(row$col_a))
    if (length(idx) != 1) { refuseCell(cid, sprintf("case '%s' not found (or not unique) in %s", row$col_a, row$dataset)); return(invisible()) }
    x <- suppressWarnings(as.numeric(d[["x"]][idx])); n <- suppressWarnings(as.numeric(d[["n"]][idx]))
    conf <- as.numeric(row$conf)
    if (is.na(n) || n < 1 || n != round(n)) { refuseCell(cid, "n must be a positive integer"); return(invisible()) }
    if (is.na(x) || x < 0 || x > n || x != round(x)) { refuseCell(cid, "successes must be an integer between 0 and n"); return(invisible()) }
    pt <- stats::prop.test(x, n, conf.level = conf, correct = FALSE)
    emit(cid, "prop_hat", x / n, "stats::prop.test")
    emit(cid, "ci_low", pt$conf.int[1], "stats::prop.test"); emit(cid, "ci_high", pt$conf.int[2], "stats::prop.test")
    emit(cid, "n", n, "base::identity")
    lines <- c(sprintf("Wilson score interval -- case '%s' (x=%d, n=%d, conf=%.2f)", row$col_a, x, n, conf),
               sprintf("p_hat=%.4f  CI[%.4f, %.4f] (stats::prop.test, correct=FALSE)", x / n, pt$conf.int[1], pt$conf.int[2]))
    writeReport(cid, lines)
}

# =============================================================================
# Dispatch -- keyed by procedure name only. This is the entire "list" this
# file carries: 17 entries, one per procedure the declaration can name, none
# per cell_id, dataset, or option value. A new row against an existing
# procedure runs with zero code change here.
# =============================================================================
dispatch <- list(
    emlRunTwoGroupAnalysis         = process_two_group,
    emlRunAnovaAnalysis            = process_anova,
    emlRunKWAnalysis               = process_kw,
    emlRunPairwiseAnalysis         = process_pairwise,
    emlRunTwoWayAnalysis           = process_twoway,
    emlRunPairedAnalysis           = process_paired,
    emlRunCorrelationAnalysis      = process_correlation,
    emlRunDescriptiveAnalysis      = process_descriptive,
    emlRunRegressionAnalysis       = process_regression,
    emlRunGroupedRegression        = process_grouped_regression,
    emlRunNormalityAnalysis        = process_normality,
    emlRunRepeatedMeasuresAnalysis = process_rm,
    emlRunFriedmanAnalysis         = process_friedman,
    emlCronbachAlpha               = process_cronbach,
    emlAlphaInfluence              = process_alpha_influence,
    emlChiSquareIndependence       = process_chisq,
    emlWilsonInterval              = process_wilson
)

# =============================================================================
# Main loop
# =============================================================================
mat <- read_matrix(matrixPath)
cat(sprintf("run_analyses.R: %d rows read from %s\n", nrow(mat), matrixPath))

startTime <- Sys.time()
nSkippedByFilter <- 0L
for (i in seq_len(nrow(mat))) {
    row <- as.list(mat[i, , drop = FALSE])
    if (!emlKitRowSelected(row$procedure)) { nSkippedByFilter <- nSkippedByFilter + 1L; next }
    # THE NIST STUDY IS NO LONGER SKIPPED HERE. There is still no R oracle
    # for a nist cell's PASS/FAIL -- compare.R judges the plugin against
    # nist_certified.tsv's published constants directly, never against this
    # runner's value -- but base R's own value on the same file is now the
    # yardstick compare.R uses for how many digits the plugin may trail it
    # by (mailbox/to-fable/MEMO_NIST_CRITERION_SHAPE_2026-08-31.md). That
    # computation is not new: a nist row's procedure is emlRunAnovaAnalysis
    # exactly like any other one-way ANOVA cell, so process_anova's own
    # aov() below IS the same base-R computation
    # validate/v19_nist_strd.R's loop runs, reached instead of reimplemented.
    fn <- dispatch[[row$procedure]]
    if (is.null(fn)) {
        refuseCell(row$cell_id, sprintf("No R handler registered for procedure '%s'.", row$procedure))
        next
    }
    tryCatch(
        fn(row),
        error = function(e) refuseCell(row$cell_id, sprintf("R computation failed: %s", conditionMessage(e)))
    )
}
elapsed <- as.numeric(Sys.time() - startTime, units = "secs")
if (nzchar(emlKitProcFilter)) {
    cat(sprintf("run_analyses.R: row filter '%s' active -- %d of %d matrix rows skipped outright (no result row, no report).\n",
                emlKitProcFilter, nSkippedByFilter, nrow(mat)))
}

flushResults(file.path(outDir, "r_results.tsv"))
cat(sprintf("run_analyses.R: wrote %d result rows to %s\n", length(RESULTS$rows), file.path(outDir, "r_results.tsv")))
# nrow(mat) - nSkippedByFilter, not nrow(mat): a filtered run writes (or
# rewrites) exactly one report per SELECTED row, nist rows included now --
# every dispatch path ends in writeReport(), directly or via
# refuseCell()/skipCell() -- and a row the filter passed over gets none.
# Printing the unfiltered total here would overstate what this run actually
# wrote and contradict @emlKitRowSelected's own "no report file of any kind"
# contract for a skipped row.
cat(sprintf("run_analyses.R: %d per-cell reports written to %s\n", nrow(mat) - nSkippedByFilter, reportDir))
cat(sprintf("run_analyses.R: done in %.1f s\n", elapsed))
