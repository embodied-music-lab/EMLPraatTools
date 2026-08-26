# compare.R -- join the two result tables and state, in one number, whether
# the kit is green.
#
# Run it AFTER both runners:
#     Praat:  open RUN_ME_FIRST.praat, click Run        -> out/praat_results.tsv
#     R:      open run_analyses.R, click Source         -> out/r_results.tsv
#     then:   open this file, click Source              -> out/reconciliation.tsv
#
# It reads nothing but those two files and matrix.tsv. It needs no package.
#
# WHAT "GREEN" MEANS HERE. Every row of both tables lands in exactly one of
# four buckets, and the kit is green when the fourth is empty:
#
#   AGREE       matched on (cell_id, quantity) and equal to within the
#               tolerance below.
#   CONTRACT_*  a one-sided row that quantities.tsv accounts for: the
#               quantity belongs to that side alone, or one side reported it
#               as undefined while the other reported a value.
#   DECLARED    a difference or a one-sided row whose cause is written down
#               in DECLARED[] at the bottom of this file, with the reason.
#               Every entry there is a statement someone can check and
#               disagree with -- that is the point of listing them rather
#               than widening the tolerance until the table goes quiet.
#   REFUSAL     both sides refused or skipped the same cell. Wording differs
#               between the two implementations and is not compared; that
#               the same cells refuse IS compared, and is asserted below.
#   UNEXPLAINED anything else. If this is not zero the kit is not green and
#               the run says so in its last line.
#
# AND THE KIT IS GREEN ONLY IF IT ALSO REPORTED EVERYTHING IT OWED. Agreement
# alone was never enough: for 1500 rows this file called a quantity the R side
# computed and the Praat side did not a "one-sided row", looked it up in
# DECLARED[], found a sentence saying the plugin has no such feature, and went
# green. The sentence was wrong -- the plugin computes AND PRINTS the Tukey
# interval -- and nothing in the join could tell a missing feature from a
# runner that never read one, because nothing declared what a run owed.
#
# quantities.tsv now declares that, per procedure, derived from the plugin's
# own Output headers and from what its reporters print. This file expands that
# contract over the 630 cells of matrix.tsv and counts three numbers beside
# the agreement numbers: EXPECTED, REPORTED, MISSING. A missing contracted
# quantity is a FAILURE. It is not a one-sided row and it has no entry in
# DECLARED[] to fall back on -- the contract, not a sentence in this file, is
# what says whether a quantity may legitimately appear on one side only.
#
# THE SEEDED DEMONSTRATION, so the completeness check cannot pass vacuously:
#
#     EML_KIT_BREAK=posthoc_soprano__mezzo_ci_low Rscript compare.R
#
# drops that one contracted quantity from the Praat table before the walk and
# the run must go red on it. A check that never goes red is not a check.
#
# TOLERANCE. Agreement is relative: |a-b| / max(|a|,|b|) < 1e-9, falling back
# to absolute difference below 1e-12 where both values are ~0. That is far
# tighter than any reported result needs and is deliberately not a knob: two
# implementations of the same formula in IEEE double should agree to near
# machine precision, and anything that does not is a difference worth naming.

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
    stop("compare.R can't find its own location.\nIn RStudio: Session > Set ",
         "Working Directory > To Source File Location, then Source again.",
         call. = FALSE)
}
kitDir <- dirname(emlThisFile())
outDir <- file.path(kitDir, "out")

need <- file.path(outDir, c("praat_results.tsv", "r_results.tsv"))
missing <- need[!file.exists(need)]
if (length(missing)) {
    stop("compare.R needs both runners to have run first. Not found:\n  ",
         paste(missing, collapse = "\n  "),
         "\n\nRun RUN_ME_FIRST.praat in Praat and run_analyses.R in RStudio, then Source this again.",
         call. = FALSE)
}

rd <- function(f) read.delim(f, sep = "\t", colClasses = "character",
                             quote = "", comment.char = "")
P <- rd(need[1]); R <- rd(need[2])
mx <- read.delim(file.path(kitDir, "matrix.tsv"), sep = "\t", comment.char = "#",
                 colClasses = "character", quote = "")

# --- THE SEEDED BREAK -------------------------------------------------------
# Naming a quantity in $EML_KIT_BREAK removes every Praat row carrying it,
# before anything below has looked at the table. Nothing else in this file
# knows the variable exists.
breakQ <- Sys.getenv("EML_KIT_BREAK", "")
if (nzchar(breakQ)) {
    nB <- nrow(P)
    P <- P[P$quantity != breakQ, , drop = FALSE]
    cat(sprintf("\n*** SEEDED BREAK: removed %d Praat row(s) with quantity '%s'.\n",
                nB - nrow(P), breakQ))
    cat("*** The completeness lines below must go red. If they do not, they are not measuring anything.\n")
}

# --- THE CONTRACT -----------------------------------------------------------
# quantities.tsv carries a long '#' preamble AND '#' characters inside its
# source column (Praat matrix names end '##'), so the preamble is stripped by
# hand rather than with comment.char, which would truncate those rows mid-line.
qtPath <- file.path(kitDir, "quantities.tsv")
if (!file.exists(qtPath)) {
    stop("compare.R needs quantities.tsv beside it -- the declaration of what each\n",
         "run must report. Without it there is nothing to check completeness against.",
         call. = FALSE)
}
qtLines <- readLines(qtPath, warn = FALSE)
QT <- read.delim(text = qtLines[!startsWith(qtLines, "#")], sep = "\t",
                 colClasses = "character", quote = "", comment.char = "")
stopifnot(identical(names(QT),
          c("procedure", "quantity", "scope", "when", "sides", "source", "note")))
if (!all(QT$sides %in% c("both", "praat", "r")))
    stop("quantities.tsv: `sides` must be both | praat | r.", call. = FALSE)
if (!all(QT$scope %in% c("cell", "pair", "level", "item", "row", "term")))
    stop("quantities.tsv: unrecognised `scope`.", call. = FALSE)

slug <- function(x) tolower(gsub("[^A-Za-z0-9]+", "_", trimws(x)))

# `when` is a tiny fixed language on the cell's OWN axes in matrix.tsv, read
# left to right. No eval(): a contract that could run arbitrary code would be
# a second implementation rather than a declaration.
whenHolds <- function(expr, cell) {
    if (!nzchar(expr) || identical(expr, "always")) return(TRUE)
    for (atom in trimws(strsplit(expr, "&", fixed = TRUE)[[1]])) {
        if (grepl("!=", atom, fixed = TRUE)) {
            kv <- strsplit(atom, "!=", fixed = TRUE)[[1]]
            if (identical(unname(cell[[kv[1]]]), kv[2])) return(FALSE)
        } else if (grepl(":", atom, fixed = TRUE)) {
            kv <- strsplit(atom, ":", fixed = TRUE)[[1]]
            if (!(unname(cell[[kv[1]]]) %in% strsplit(kv[2], ",", fixed = TRUE)[[1]]))
                return(FALSE)
        } else if (grepl("=", atom, fixed = TRUE)) {
            kv <- strsplit(atom, "=", fixed = TRUE)[[1]]
            if (!identical(unname(cell[[kv[1]]]), kv[2])) return(FALSE)
        } else {
            stop("quantities.tsv: unreadable `when` atom: ", atom, call. = FALSE)
        }
    }
    TRUE
}

# A template's placeholder becomes a capture group. The templates hold only
# [a-z0-9_<>], asserted here, so no regex escaping is needed and none is done
# silently.
PH <- "<[A-Z]+>"
if (any(grepl("[^a-z0-9_]", gsub(PH, "", QT$quantity))))
    stop("quantities.tsv: a quantity template holds a character this file would\n",
         "have to escape. Keep templates to [a-z0-9_<>].", call. = FALSE)
tmplRegex <- function(tmpl) {
    ph <- regmatches(tmpl, regexpr(PH, tmpl))
    parts <- strsplit(tmpl, ph, fixed = TRUE)[[1]]
    pre <- parts[1]; post <- if (length(parts) > 1) parts[2] else ""
    paste0("^", pre, "(.+?)", post, "$")
}

# Base name: a runner that says "this quantity is undefined here" has REPORTED
# it. A runner that writes no row has not.
baseName <- function(q) sub("_undefined$", "", q)

Pbase <- split(baseName(P$quantity), P$cell_id)
Rbase <- split(baseName(R$quantity), R$cell_id)
obs <- function(cid) unique(c(Pbase[[cid]], Rbase[[cid]]))

# THE INDEX SETS. cell and term come from the declaration alone; so do the
# levels and pairs of the repeated-measures and Friedman doors, whose
# conditions ARE matrix.tsv's col_a. The group labels, surviving row numbers
# and scale items behind the other placeholders are properties of the DATA,
# and are taken as the union of what the two sides emitted -- the one place
# this file reads output to decide what to expect, stated in quantities.tsv's
# header rather than hidden here.
DECLARED_LEVEL_PROCS <- c("emlRunRepeatedMeasuresAnalysis", "emlRunFriedmanAnalysis")
indexSet <- function(scope, cell, tmpl) {
    if (scope == "cell") return("")
    if (scope == "term") {
        a <- slug(cell$col_b); b <- slug(cell$col_c)
        return(c(a, b, paste0(a, "__", b)))
    }
    if (cell$procedure %in% DECLARED_LEVEL_PROCS && scope %in% c("level", "pair")) {
        lv <- slug(strsplit(cell$col_a, "|", fixed = TRUE)[[1]])
        if (scope == "level") return(lv)
        out <- character(0)
        for (i in seq_along(lv)) for (j in seq_along(lv)) if (i < j)
            out <- c(out, paste0(lv[i], "__", lv[j]))
        return(out)
    }
    rx <- tmplRegex(tmpl)
    o <- obs(cell$cell_id)
    m <- regmatches(o, regexec(rx, o))
    unique(vapply(m[lengths(m) > 0], function(z) z[2], ""))
}

# ---------------------------------------------------------------------------
# DECLARED DIFFERENCES. Each entry names a quantity pattern, which side it
# appears on, and why. `where` is "diff" (matched but unequal), "praat" (only
# the Praat table has it) or "r" (only the R table has it).
# ---------------------------------------------------------------------------
DECLARED <- list(
    list(q = "^hedges_g$", where = "diff", id = "D-HEDGES",
         why = paste("Hedges' g bias correction: the plugin uses the APPROXIMATE factor",
                     "J = 1 - 3/(4*df-1); effectsize uses the EXACT J = gamma(df/2) /",
                     "(sqrt(df/2)*gamma((df-1)/2)). Hedges (1981) gives the exact form and",
                     "presents the other as an approximation for hand computation. The exact",
                     "form is the published definition and Praat has lnGamma, so the plugin",
                     "could compute it. Relative difference ~2e-5. THIS IS A PLUGIN DEFECT,",
                     "not a tolerance question.")),
    list(q = "^(spearman_p|p)$", where = "diff", id = "D-SPEARMAN", proc = "emlRunCorrelationAnalysis",
         why = paste("Spearman's p: the plugin computes the large-sample t-approximation on",
                     "n-2 df; stats::cor.test returns the EXACT permutation p for small n",
                     "without ties (AS89 otherwise). Different p for the same null, most",
                     "visibly at rho=1 where the exact p is 2/n! and the approximation goes",
                     "to ~0. Both runners also emit spearman_p_asymptotic, and those AGREE --",
                     "which is what pins this to the choice of tail and not to arithmetic.")),
    list(q = "^spearman_p$", where = "r", id = "D-SPEARMAN",
         why = "The exact Spearman p has no plugin counterpart; see D-SPEARMAN."),
    list(q = "^spearman_(t|df)$", where = "praat", id = "D-SPEARMAN",
         why = "t and df are intrinsic to the plugin's t-approximation; cor.test reports S instead."),
    list(q = "^spearman_s$", where = "r", id = "D-SPEARMAN",
         why = "cor.test's S statistic is intrinsic to its exact method; the plugin reports t/df instead."),
    list(q = "^posthoc_.*_(ci_low|ci_high)$", where = "r", id = "D-NOCI",
         why = paste("NO POST-HOC CONFIDENCE INTERVAL. None of @emlTukeyHSD, @emlDunnTest,",
                     "@emlPairwiseT, @emlPairwiseWilcoxon or @emlScheffe returns an interval;",
                     "each gives a statistic, a p and an effect size. Reporting a comparison",
                     "without an interval for the estimate is against current reporting",
                     "guidance. THIS IS A PLUGIN GAP and the largest single one in this table.")),
    list(q = "^posthoc_.*_diff$", where = "r", id = "D-NODIFF",
         why = paste("@emlRunPairwiseAnalysis sets .stDiffMat to @emlPublishAbsentMatrix for",
                     "its t and Wilcoxon arms -- the mean difference is deliberately marked",
                     "absent, not merely unextracted. So the plugin reports whether a pair",
                     "differs and by how much in SD units, but not by how much in the data's",
                     "own units. A plugin gap, and a documented one.")),
    list(q = "^posthoc_.*_q$", where = "praat", id = "D-TUKEYQ",
         why = "Tukey's studentised range q; stats::TukeyHSD does not expose it."),
    list(q = "^posthoc_.*_(padj|p|f|diff)$", where = "praat", id = "D-SCHEFFE",
         test = "scheffe",
         why = paste("Scheffe's test: no installed R package implements it (checked across",
                     "rstatix, effectsize, car, afex, multcomp, nortest, coin, psych and base",
                     "stats; multcomp::glht's adjusted() has no Scheffe option). The R side",
                     "emits skipped/skip_reason for these cells rather than hand-deriving the",
                     "Scheffe F. An R-side capability gap, declared as one.")),
    list(q = "^(skipped|skip_reason)$", where = "r", id = "D-SCHEFFE",
         why = "The R side's declared skip on the Scheffe cells; see D-SCHEFFE."),
    list(q = "^n_undefined$", where = "praat", id = "D-PAIRWISE-N",
         why = paste("@emlRunPairwiseAnalysis lists .stN in its own Outputs header, initialises",
                     "it to undefined and never assigns it, so the procedure cannot report the",
                     "sample size it analysed. The runner emits n_undefined rather than",
                     "silently writing no row. THIS IS A PLUGIN DEFECT.")),
    list(q = "^n$", where = "r", id = "D-PAIRWISE-N", proc = "emlRunPairwiseAnalysis",
         why = "The R counterpart of the n the plugin cannot report; see D-PAIRWISE-N."),
    list(q = "^eta_squared$", where = "r", id = "D-KW-ETA",
         why = paste("Kruskal-Wallis eta-squared[H]. The plugin reports epsilon-squared only",
                     "(and that value AGREES). A DOCUMENTED ABSENCE, not a coverage gap: per",
                     "docs/RULING_KIT_DELTAS_2026-08-26.md, this is a decided non-quantity --",
                     "epsilon-squared is the plugin's stated choice of KW effect size, cited",
                     "here rather than left as an unexplained one-sided row.")),
    list(q = "^(skewness_b1|kurtosis_b2)(_undefined)?$", where = "r", id = "D-SHAPE",
         why = paste("psych::describe's OWN default estimator (type 3, the b1/b2 moment",
                     "ratios), emitted alongside the type-2 G1/G2 that `skewness` and",
                     "`kurtosis` carry on both sides. Present so the estimator choice is",
                     "visible in the data rather than only in a comment.")),
    list(q = "^wilcox_r$", where = "r", id = "D-WILCOXR",
         why = paste("rstatix::wilcox_effsize's r = Z/sqrt(N) (Rosenthal's r), which is NOT",
                     "the rank-biserial correlation and has no plugin counterpart. It was",
                     "originally emitted under the name rank_biserial on the R side, which",
                     "made two different statistics look like one disagreement.")),
    list(q = "^cramers_v_(yates|bias_corrected)$", where = "r", id = "D-CRAMER",
         why = paste("The two packages' own DEFAULTS, kept under names that say what they",
                     "are: rstatix::cramer_v defaults to Yates-corrected, effectsize::cramers_v",
                     "to Bergsma's bias-corrected V. The bare `cramers_v` on both sides is the",
                     "plain uncorrected V and AGREES. Yates corrects a test, not an effect",
                     "size, which is why the axis is not carried into V.")),
    list(q = "^gg_(p|epsilon)(_undefined)?$", where = "both", id = "D-GG",
         why = paste("Greenhouse-Geisser. At k=2 there is one within-subject df and sphericity",
                     "is trivial, so the R side does not report a correction; the plugin falls",
                     "back to the epsilon lower bound 1/(k-1) and reports one. Where afex",
                     "cannot compute GG at all it returns epsilon=NA while still printing",
                     "Pr(>F[GG]) as 0 -- a sentinel, not a p-value, and not emitted.")),
    list(q = "^(mean|median|sd|sem|variance|skewness|kurtosis|skewness_b1|kurtosis_b2|q1|q3|iqr|ci_low|ci_high|n|p|w_statistic)(_undefined)?$",
         where = "both", id = "D-PARSE", dataset = "rp_r6_parse_conditions_input",
         why = paste("LOCALE PARSING. This fixture holds the cell \"73,4\". Praat's own",
                     "number() primitive reads that as 73 -- it stops at the comma and drops",
                     "the fraction. @emlRunNormalityAnalysis accepts the cell on that basis",
                     "and reports n=4 with the wrong value; @emlRunDescriptiveAnalysis",
                     "rejects the same cell and reports n=3. So two procedures disagree with",
                     "each other about one cell in one column, and neither reads it as 73.4.",
                     "The R side applies the documented rule (a single comma is a decimal",
                     "point) and reads 73.4. THIS IS A PLUGIN DEFECT, in two parts, and the",
                     "kit does not tune it away.")),
    list(q = "^(ci_low|ci_high)$", where = "praat", id = "D-CONSTCI",
         why = paste("95% CI of the mean on a column with zero variance. The plugin returns",
                     "the degenerate interval [mean, mean]; stats::t.test refuses ('data are",
                     "essentially constant') and the R side reports every other descriptive",
                     "and omits only the interval. Both are defensible.")),
    list(q = "^(.*_ss|.*_ms|.*_f|.*_p|.*_partial_eta_squared)$", where = "diff",
         id = "D-TWOWAY-PRECISION", proc = "emlRunTwoWayAnalysis", maxrel = 2e-8,
         why = paste("PRECISION CEILING, NOT A DISAGREEMENT. @emlRunTwoWayAnalysis does not",
                     "compute the two-way ANOVA: it parses the text of Praat's own built-in",
                     "'Report two-way anova', which prints SS to about nine significant",
                     "digits (1092.1626 for 1092.162604968245). Every quantity derived from",
                     "those sums -- F, p, MS, the partial eta-squareds -- inherits that",
                     "ceiling, on all 18 rows this pattern reaches (2 cells x 9 quantities).",
                     "NAMED PER-PROCEDURE TOLERANCE, per docs/RULING_KIT_DELTAS_2026-08-26.md:",
                     "measured relative disagreement on this table tops out at ~1.22e-8",
                     "(voice_type_p); the bound is set at 2e-8, headroom above that measured",
                     "ceiling rather than tuned to it exactly, and is ASSERTED below, not",
                     "assumed. This procedure structurally CANNOT agree to machine precision",
                     "the way every other one here does -- the reason is the parsed report's",
                     "own printed precision, not this comparison's tolerance.")),
    list(q = "^delta_(max|row_[0-9]+)$", where = "diff", id = "D-ALPHADROP",
         why = paste("Leave-one-out alpha on an n=3 fixture reaches a 2-respondent submatrix",
                     "in which one item has no variance. psych::alpha deletes that item (it",
                     "warns) and computes alpha on k=3; the plugin keeps it and computes on",
                     "k=4. Different scale definitions, hence different alpha. A degenerate",
                     "corner, reported rather than resolved.")),
    list(q = "^posthoc_.*_padj$", where = "diff", id = "D-PTUKEY", maxrel = 1e-4,
         why = paste("Tukey adjusted p in the far tail. Both sides evaluate the studentised",
                     "range distribution; the two numerical implementations differ by ~4e-5",
                     "relative at p = 5.7e-12. Same definition, different quadrature. Bounded",
                     "by maxrel below, and the bound is asserted, not assumed.")),
    list(q = "^(chi_square|p|kendalls_w)$", where = "praat", id = "D-FRIEDMAN-DEGEN",
         proc = "emlRunFriedmanAnalysis",
         why = paste("Friedman on data where every subject gives identical values across",
                     "all conditions: every rank is tied, and the statistic is 0/0. The",
                     "plugin reports chi-square = 0, p = 1, W = 0 -- a defensible reading",
                     "of 'no evidence of any difference'. stats::friedman.test returns NaN",
                     "and the R side emits the _undefined markers instead. Both are honest;",
                     "they are different conventions for the same degenerate input.")),
    list(q = "^(chi_square|p|kendalls_w|posthoc_.*)_undefined$", where = "r",
         id = "D-FRIEDMAN-DEGEN", proc = "emlRunFriedmanAnalysis",
         why = "The R side of the same degenerate Friedman cell; see D-FRIEDMAN-DEGEN."),
    list(q = "^alpha_if_deleted_.*_undefined$", where = "praat", id = "D-ALPHA2ITEM",
         why = paste("Alpha-if-item-deleted on a two-item scale would leave one item, for",
                     "which alpha is undefined. The plugin emits the undefined marker; the R",
                     "side does not attempt the quantity at k=2. Same statement, two spellings.")),
    list(q = "^.*_eta_squared$", where = "r", id = "D-TWOWAY-ETA",
         proc = "emlRunTwoWayAnalysis",
         why = paste("Non-partial eta-squared per term. The plugin reports partial eta-squared",
                     "only (and those AGREE). A coverage gap, not an error.")),
    list(q = "^refuse_reason$", where = "diff", id = "D-WORDING",
         why = "Refusal wording differs between implementations; that the same cells refuse is asserted separately."),
    list(q = "^(n_excluded|overall_adj_r_squared|sd_group1|sd_group2|mean_group1|mean_group2|median_group1|median_group2|mean_diff|n)$",
         where = "r", id = "D-MINOR",
         why = paste("Quantities the R side reports on cells where the plugin either has no",
                     "output for them (@emlRunPairedAnalysis exposes no excluded-row count;",
                     "@emlRunGroupedRegression exposes no adjusted R-squared) or refused the",
                     "cell outright (the nine expect=ok cells listed in the README)."))
)

# ---------------------------------------------------------------------------
key <- function(d) paste(d$cell_id, d$quantity, sep = "\r")
P$key <- key(P); R$key <- key(R)
procOf <- setNames(mx$procedure, mx$cell_id)
testOf <- setNames(mx$test, mx$cell_id)
dsOf   <- setNames(mx$dataset, mx$cell_id)

# ---------------------------------------------------------------------------
# EXPANDING THE CONTRACT OVER THE 630 CELLS.
# One pass. For every cell, every clause of its procedure whose `when` holds,
# expanded over that clause's index set. The result is the flat list of
# (cell_id, quantity, sides) this run owes.
# ---------------------------------------------------------------------------
expCell <- character(0); expQty <- character(0); expSides <- character(0)
QTbyProc <- split(seq_len(nrow(QT)), QT$procedure)
for (ci in seq_len(nrow(mx))) {
    cell <- mx[ci, ]
    idxs <- QTbyProc[[cell$procedure]]
    if (is.null(idxs)) next
    for (qi in idxs) {
        if (!whenHolds(QT$when[qi], cell)) next
        tmpl <- QT$quantity[qi]
        if (QT$scope[qi] == "cell") {
            names <- tmpl
        } else {
            ix <- indexSet(QT$scope[qi], cell, tmpl)
            if (!length(ix)) next
            ph <- regmatches(tmpl, regexpr(PH, tmpl))
            names <- vapply(ix, function(k) sub(ph, k, tmpl, fixed = TRUE), "")
        }
        expCell  <- c(expCell,  rep(cell$cell_id, length(names)))
        expQty   <- c(expQty,   names)
        expSides <- c(expSides, rep(QT$sides[qi], length(names)))
    }
}
EXP <- data.frame(cell_id = expCell, quantity = expQty, sides = expSides,
                  stringsAsFactors = FALSE)
EXP <- EXP[!duplicated(paste(EXP$cell_id, EXP$quantity, sep = "\r")), , drop = FALSE]
sidesOf <- setNames(EXP$sides, paste(EXP$cell_id, EXP$quantity, sep = "\r"))

# A REFUSAL DISCHARGES THE CONTRACT FOR THAT SIDE ON THAT CELL, and nothing
# else does. A run that refused reported completely: it said why it computed
# nothing. A run that computed and then went quiet about a quantity did not.
refusedP <- unique(P$cell_id[P$quantity %in% c("refused", "skipped")])
refusedR <- unique(R$cell_id[R$quantity %in% c("refused", "skipped")])

hasP <- function(cid, q) q %in% Pbase[[cid]]
hasR <- function(cid, q) q %in% Rbase[[cid]]

nExpected <- 0L; nReported <- 0L; nWaived <- 0L
missRows <- list(); missByProc <- integer(0); missByQty <- integer(0)
for (i in seq_len(nrow(EXP))) {
    cid <- EXP$cell_id[i]; q <- EXP$quantity[i]; sd <- EXP$sides[i]
    for (side in if (sd == "both") c("praat", "r") else sd) {
        if (side == "praat" && cid %in% refusedP) { nWaived <- nWaived + 1L; next }
        if (side == "r"     && cid %in% refusedR) { nWaived <- nWaived + 1L; next }
        nExpected <- nExpected + 1L
        got <- if (side == "praat") hasP(cid, q) else hasR(cid, q)
        if (got) { nReported <- nReported + 1L; next }
        pr <- procOf[[cid]]
        missByProc[pr] <- (if (is.na(missByProc[pr])) 0L else missByProc[pr]) + 1L
        missByQty[q]   <- (if (is.na(missByQty[q]))   0L else missByQty[q])   + 1L
        missRows[[length(missRows) + 1L]] <- list(
            bucket = paste0("MISSING_", toupper(side)), id = "CONTRACT",
            cell_id = cid, quantity = q, praat = "", r = "",
            source = paste0(pr, " / contracted sides=", sd))
    }
}
nMissing <- length(missRows)

# WHAT THE CONTRACT SAYS ABOUT A ONE-SIDED ROW. Consulted BEFORE DECLARED[]:
# where the contract governs a quantity, the contract decides, and a sentence
# in DECLARED[] cannot overrule it.
contractVerdict <- function(cell, quantity, side) {
    base <- baseName(quantity)
    sd <- sidesOf[paste(cell, base, sep = "\r")]
    if (is.na(sd)) return(NULL)
    sd <- unname(sd)
    other <- if (side == "praat") "r" else "praat"
    if (identical(sd, side)) return(list(b = paste0("CONTRACT_ONLY_", toupper(side)), fail = FALSE))
    if (identical(sd, "both")) {
        otherHas <- if (other == "praat") hasP(cell, base) else hasR(cell, base)
        if (otherHas) return(list(b = "CONTRACT_UNDEFINED", fail = FALSE))
        return(list(b = "CONTRACT_MISSING_PARTNER", fail = FALSE))  # counted once, above
    }
    list(b = paste0("CONTRACT_VIOLATION_", toupper(side)), fail = TRUE)
}

matches <- function(rule, cell, quantity, side) {
    if (!grepl(rule$q, quantity)) return(FALSE)
    if (!(rule$where %in% c("both", side))) return(FALSE)
    if (!is.null(rule$proc)    && !identical(procOf[[cell]], rule$proc))    return(FALSE)
    if (!is.null(rule$test)    && !identical(testOf[[cell]], rule$test))    return(FALSE)
    if (!is.null(rule$dataset) && !identical(dsOf[[cell]],   rule$dataset)) return(FALSE)
    TRUE
}
declaredFor <- function(cell, quantity, side) {
    for (r in DECLARED) if (matches(r, cell, quantity, side)) return(r)
    NULL
}

num <- function(x) suppressWarnings(as.numeric(x))
agree <- function(a, b) {
    if (is.na(a) || is.na(b)) return(FALSE)
    d <- abs(a - b); s <- max(abs(a), abs(b))
    if (s < 1e-12) d < 1e-12 else (d / s) < 1e-9
}

rows <- list(); add <- function(...) rows[[length(rows) + 1]] <<- list(...)
nAgree <- 0L; nDeclared <- 0L; nUnexplained <- 0L; nCompared <- 0L; maxRelSeen <- list()

both <- intersect(P$key, R$key)
Pl <- split(seq_len(nrow(P)), P$key); Rl <- split(seq_len(nrow(R)), R$key)
for (k in both) {
    pi <- Pl[[k]][1]; cell <- P$cell_id[pi]; q <- P$quantity[pi]
    pv <- num(P$value[pi])
    for (ri in Rl[[k]]) {
        nCompared <- nCompared + 1L
        rv <- num(R$value[ri]); src <- R$source[ri]
        if (is.na(pv) && is.na(rv)) {
            # text-valued on both sides (refuse_reason and friends)
            if (identical(P$value[pi], R$value[ri])) { nAgree <- nAgree + 1L; next }
        } else if (agree(pv, rv)) { nAgree <- nAgree + 1L; next }
        rule <- declaredFor(cell, q, "diff")
        if (!is.null(rule)) {
            if (!is.null(rule$maxrel) && !is.na(pv) && !is.na(rv)) {
                rel <- abs(pv - rv) / max(abs(pv), abs(rv))
                maxRelSeen[[rule$id]] <- max(c(maxRelSeen[[rule$id]], rel))
            }
            nDeclared <- nDeclared + 1L
            add(bucket = "DECLARED", id = rule$id, cell_id = cell, quantity = q,
                praat = P$value[pi], r = R$value[ri], source = src)
        } else {
            nUnexplained <- nUnexplained + 1L
            add(bucket = "UNEXPLAINED", id = "", cell_id = cell, quantity = q,
                praat = P$value[pi], r = R$value[ri], source = src)
        }
    }
}
nContract <- 0L; nViolation <- 0L
oneSided <- function(keys, tbl, side) {
    for (k in keys) {
        i <- if (side == "praat") Pl[[k]][1] else Rl[[k]][1]
        cell <- tbl$cell_id[i]; q <- tbl$quantity[i]
        cv <- contractVerdict(cell, q, side)
        if (!is.null(cv)) {
            nContract <<- nContract + 1L
            if (cv$fail) nViolation <<- nViolation + 1L
            add(bucket = cv$b, id = "CONTRACT", cell_id = cell, quantity = q,
                praat = if (side == "praat") tbl$value[i] else "",
                r = if (side == "r") tbl$value[i] else "", source = tbl$source[i])
            next
        }
        rule <- declaredFor(cell, q, side)
        if (!is.null(rule)) {
            nDeclared <<- nDeclared + 1L
            add(bucket = paste0("DECLARED_ONLY_", toupper(side)), id = rule$id,
                cell_id = cell, quantity = q,
                praat = if (side == "praat") tbl$value[i] else "",
                r = if (side == "r") tbl$value[i] else "", source = tbl$source[i])
        } else {
            nUnexplained <<- nUnexplained + 1L
            add(bucket = paste0("UNMATCHED_", toupper(side)), id = "",
                cell_id = cell, quantity = q,
                praat = if (side == "praat") tbl$value[i] else "",
                r = if (side == "r") tbl$value[i] else "", source = tbl$source[i])
        }
    }
}
oneSided(setdiff(P$key, R$key), P, "praat")
oneSided(setdiff(R$key, P$key), R, "r")
for (m in missRows) rows[[length(rows) + 1L]] <- m

# --- the refusal assertion: same cells refuse, whatever the wording ---------
refP <- sort(unique(P$cell_id[P$quantity %in% c("refused", "skipped")]))
refR <- sort(unique(R$cell_id[R$quantity %in% c("refused", "skipped")]))
declaredRefuse <- sort(mx$cell_id[mx$expect == "refuse"])
missP <- setdiff(declaredRefuse, refP); missR <- setdiff(declaredRefuse, refR)

# ---------------------------------------------------------------------------
# ANNOTATE EVERY ROW WITH ITS RULE'S REASON AND WHETHER THAT REASON IS
# ENFORCED. A prose reason is an argument; a bound is an argument plus a
# tripwire that can detect its own obsolescence. A reader of this file should
# not have to open compare.R to tell the two apart.
# ---------------------------------------------------------------------------
ruleById <- function(theId) {
    for (rule in DECLARED) if (identical(rule$id, theId)) return(rule)
    NULL
}
flatten1 <- function(x) gsub("[\t\r\n]+", " ", paste(x, collapse = " "))
enforcementFor <- function(theId) {
    if (!nzchar(theId)) return(list(enf = "", why = ""))
    rule <- ruleById(theId)
    if (is.null(rule)) return(list(enf = "no rule found", why = ""))
    why <- flatten1(rule$why)
    if (is.null(rule$maxrel)) {
        return(list(enf = "PROSE ONLY -- no numeric bound is enforced; this reason cannot detect its own drift", why = why))
    }
    seen <- if (is.null(maxRelSeen[[theId]])) NA_real_ else maxRelSeen[[theId]]
    verdict <- if (!is.na(seen) && seen <= rule$maxrel) "HOLDS" else "EXCEEDED"
    list(enf = sprintf("BOUND ENFORCED: observed max relative difference %.3g, declared limit %.3g -- %s",
                       seen, rule$maxrel, verdict),
         why = why)
}

out <- do.call(rbind, lapply(rows, function(r) as.data.frame(r, stringsAsFactors = FALSE)))
if (is.null(out)) out <- data.frame(bucket = character(), id = character(),
    cell_id = character(), quantity = character(), praat = character(),
    r = character(), source = character())
if (nrow(out)) {
    ann <- lapply(out$id, enforcementFor)
    out$enforcement <- vapply(ann, function(a) a$enf, character(1))
    out$why         <- vapply(ann, function(a) a$why, character(1))
} else {
    out$enforcement <- character(); out$why <- character()
}
write.table(out, file.path(outDir, "reconciliation.tsv"), sep = "\t",
            quote = FALSE, row.names = FALSE)

cat("\n=========================================================\n")
cat("  EML kit -- reconciliation of the two result tables\n")
cat("=========================================================\n")
cat(sprintf("cells declared in matrix.tsv : %d\n", nrow(mx)))
cat(sprintf("rows, Praat table            : %d\n", nrow(P)))
cat(sprintf("rows, R table                : %d\n", nrow(R)))
cat(sprintf("value comparisons made       : %d\n", nCompared))
cat(sprintf("\n  AGREE       %6d   (relative difference < 1e-9)\n", nAgree))
cat(sprintf("  CONTRACT    %6d   (one-sided rows quantities.tsv accounts for)\n", nContract))
cat(sprintf("  DECLARED    %6d   (differences and one-sided rows with a written reason)\n", nDeclared))
cat(sprintf("  UNEXPLAINED %6d\n", nUnexplained))

# ---------------------------------------------------------------------------
# THE COMPLETENESS LINE, BESIDE THE AGREEMENT LINE.
# ---------------------------------------------------------------------------
cat("\n--- completeness against quantities.tsv ---\n")
cat(sprintf("  contract clauses read        : %d over %d procedures\n",
            nrow(QT), length(unique(QT$procedure))))
cat(sprintf("  contracted quantities, expanded over the %d cells : %d\n",
            nrow(mx), nrow(EXP)))
cat(sprintf("  EXPECTED  %6d   (a `both` clause is expected of each runner)\n", nExpected))
cat(sprintf("  REPORTED  %6d\n", nReported))
cat(sprintf("  MISSING   %6d\n", nMissing))
cat(sprintf("  waived    %6d   (the side refused the cell; a refusal reports completely)\n", nWaived))
if (nMissing) {
    cat("\n  missing, by procedure:\n")
    for (nm in names(sort(missByProc, decreasing = TRUE)))
        cat(sprintf("    %-34s %5d\n", nm, missByProc[[nm]]))
    cat("\n  missing, by quantity (top 12):\n")
    for (nm in head(names(sort(missByQty, decreasing = TRUE)), 12))
        cat(sprintf("    %-44s %5d\n", nm, missByQty[[nm]]))
}
if (nViolation) {
    cat(sprintf("\n  CONTRACT VIOLATIONS %d: a runner reported a quantity the contract\n", nViolation))
    cat("  assigns to the other side alone. See bucket CONTRACT_VIOLATION_* .\n")
}

# ---------------------------------------------------------------------------
# THE STANDING KIT.
#
# POPULATION DERIVED, NOT WRITTEN DOWN. The members are the procedures
# matrix.tsv actually runs, read out of matrix.tsv. No list of procedures is
# typed in this file, so a procedure added to the matrix is graded on the next
# run without anyone editing here.
#
# ONE PROPERTY PER MEMBER. Every procedure gets exactly one assertion: every
# contracted quantity every cell of that procedure owed was reported.
#
# THE RATCHET, BOTH DIRECTIONS. The derived population is compared to the
# procedures quantities.tsv governs by SET EQUALITY -- a procedure the matrix
# runs with no contract clause is red (it would be graded on nothing), and a
# clause for a procedure no cell runs is ALSO red (it grades nothing and would
# rot unnoticed).
#
# A FAILURE IF IT WALKED ZERO MEMBERS, checked before any per-member
# assertion, so a matrix that stopped parsing cannot read as all-clear.
# ---------------------------------------------------------------------------
cat("\n--- the standing kit: one property per procedure ---\n")
members <- sort(unique(mx$procedure))
governed <- sort(unique(QT$procedure))
kitFail <- 0L
if (!length(members)) {
    cat("  RED: the walk found zero procedures in matrix.tsv. Nothing was graded.\n")
    kitFail <- kitFail + 1L
} else {
    onlyMatrix <- setdiff(members, governed)
    onlyContract <- setdiff(governed, members)
    if (length(onlyMatrix)) {
        cat(sprintf("  RED: %d procedure(s) run by matrix.tsv with no clause in quantities.tsv: %s\n",
                    length(onlyMatrix), paste(onlyMatrix, collapse = ", ")))
        kitFail <- kitFail + length(onlyMatrix)
    }
    if (length(onlyContract)) {
        cat(sprintf("  RED: %d clause procedure(s) no cell runs: %s\n",
                    length(onlyContract), paste(onlyContract, collapse = ", ")))
        kitFail <- kitFail + length(onlyContract)
    }
    for (pr in members) {
        m <- if (is.na(missByProc[pr])) 0L else missByProc[[pr]]
        nCl <- sum(QT$procedure == pr)
        cat(sprintf("  %-34s %s  %2d clause(s), %d missing\n",
                    pr, if (m == 0L) "complete" else "RED     ", nCl, m))
        if (m != 0L) kitFail <- kitFail + 1L
    }
    cat(sprintf("  walked %d procedures.\n", length(members)))
}
cat("\n--- declared, by cause ---\n")
tb <- table(vapply(rows, function(r) r$id, ""))
tb <- tb[names(tb) != ""]
for (nm in names(sort(tb, decreasing = TRUE))) {
    why <- NULL; for (r in DECLARED) if (identical(r$id, nm)) { why <- r$why; break }
    cat(sprintf("  %-14s %5d  %s\n", nm, tb[[nm]], substr(why, 1, 68)))
}
for (nm in names(maxRelSeen)) {
    rule <- NULL; for (r in DECLARED) if (identical(r$id, nm)) { rule <- r; break }
    ok <- maxRelSeen[[nm]] <= rule$maxrel
    cat(sprintf("\n  %s bound: observed max relative difference %.3g, declared limit %.3g -- %s\n",
                nm, maxRelSeen[[nm]], rule$maxrel, if (ok) "HOLDS" else "EXCEEDED"))
    if (!ok) nUnexplained <- nUnexplained + 1L
}
cat("\n--- refusals ---\n")
cat(sprintf("  matrix.tsv declares %d cells expect=refuse\n", length(declaredRefuse)))
cat(sprintf("  Praat refused/skipped %d cells; R refused/skipped %d\n", length(refP), length(refR)))
cat(sprintf("  declared refusals missed by Praat: %d %s\n", length(missP),
            if (length(missP)) paste0("(", paste(missP, collapse = ", "), ")") else ""))
cat(sprintf("  declared refusals missed by R:     %d %s\n", length(missR),
            if (length(missR)) paste0("(", paste(missR, collapse = ", "), ")") else ""))
if (length(missP) || length(missR)) nUnexplained <- nUnexplained + length(missP) + length(missR)

cat("\n---------------------------------------------------------\n")
if (nUnexplained == 0 && nMissing == 0 && nViolation == 0 && kitFail == 0) {
    cat("  GREEN. Every row is accounted for AND every contracted quantity arrived.\n")
} else {
    cat("  NOT GREEN.\n")
    if (nUnexplained)
        cat(sprintf("    %d unexplained row(s)  -- bucket UNEXPLAINED / UNMATCHED_PRAAT / UNMATCHED_R.\n", nUnexplained))
    if (nMissing)
        cat(sprintf("    %d contracted quantit(ies) MISSING -- bucket MISSING_PRAAT / MISSING_R.\n", nMissing))
    if (nViolation)
        cat(sprintf("    %d contract violation(s) -- bucket CONTRACT_VIOLATION_*.\n", nViolation))
    if (kitFail)
        cat(sprintf("    %d standing-kit failure(s) -- see the per-procedure walk above.\n", kitFail))
    cat("  See out/reconciliation.tsv.\n")
    cat("  A run that compares fewer quantities than the contract requires is not green,\n")
    cat("  however well the ones present agree.\n")
}
cat("---------------------------------------------------------\n")
cat(sprintf("full detail: %s\n\n", file.path(outDir, "reconciliation.tsv")))
