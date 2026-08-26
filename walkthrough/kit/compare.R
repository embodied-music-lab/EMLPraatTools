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
                     "(and that value AGREES). Both are standard; reporting only one is a",
                     "coverage gap, not an error.")),
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
         id = "D-TWOWAY-PRECISION", proc = "emlRunTwoWayAnalysis", maxrel = 1e-7,
         why = paste("PRECISION CEILING, NOT A DISAGREEMENT. @emlRunTwoWayAnalysis does not",
                     "compute the two-way ANOVA: it parses the text of Praat's own built-in",
                     "'Report two-way anova', which prints SS to about nine significant",
                     "digits (1092.1626 for 1092.162604968245). Every quantity derived from",
                     "those sums inherits the ceiling. The two sides agree to ~1e-8 relative,",
                     "bounded and asserted below, but this procedure structurally CANNOT",
                     "agree to machine precision the way every other one here does.")),
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
nAgree <- 0L; nDeclared <- 0L; nUnexplained <- 0L; maxRelSeen <- list()

both <- intersect(P$key, R$key)
Pl <- split(seq_len(nrow(P)), P$key); Rl <- split(seq_len(nrow(R)), R$key)
for (k in both) {
    pi <- Pl[[k]][1]; cell <- P$cell_id[pi]; q <- P$quantity[pi]
    pv <- num(P$value[pi])
    for (ri in Rl[[k]]) {
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
oneSided <- function(keys, tbl, side) {
    for (k in keys) {
        i <- if (side == "praat") Pl[[k]][1] else Rl[[k]][1]
        cell <- tbl$cell_id[i]; q <- tbl$quantity[i]
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

# --- the refusal assertion: same cells refuse, whatever the wording ---------
refP <- sort(unique(P$cell_id[P$quantity %in% c("refused", "skipped")]))
refR <- sort(unique(R$cell_id[R$quantity %in% c("refused", "skipped")]))
declaredRefuse <- sort(mx$cell_id[mx$expect == "refuse"])
missP <- setdiff(declaredRefuse, refP); missR <- setdiff(declaredRefuse, refR)

out <- do.call(rbind, lapply(rows, function(r) as.data.frame(r, stringsAsFactors = FALSE)))
if (is.null(out)) out <- data.frame(bucket = character(), id = character(),
    cell_id = character(), quantity = character(), praat = character(),
    r = character(), source = character())
write.table(out, file.path(outDir, "reconciliation.tsv"), sep = "\t",
            quote = FALSE, row.names = FALSE)

cat("\n=========================================================\n")
cat("  EML kit -- reconciliation of the two result tables\n")
cat("=========================================================\n")
cat(sprintf("cells declared in matrix.tsv : %d\n", nrow(mx)))
cat(sprintf("rows, Praat table            : %d\n", nrow(P)))
cat(sprintf("rows, R table                : %d\n", nrow(R)))
cat(sprintf("value comparisons made       : %d\n", nAgree + nDeclared + nUnexplained -
            sum(grepl("ONLY|UNMATCHED", vapply(rows, function(r) r$bucket, "")))))
cat(sprintf("\n  AGREE       %6d   (relative difference < 1e-9)\n", nAgree))
cat(sprintf("  DECLARED    %6d   (differences and one-sided rows with a written reason)\n", nDeclared))
cat(sprintf("  UNEXPLAINED %6d\n", nUnexplained))
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
if (nUnexplained == 0) {
    cat("  GREEN. Every row is accounted for.\n")
} else {
    cat(sprintf("  NOT GREEN: %d unexplained row(s). See out/reconciliation.tsv,\n", nUnexplained))
    cat("  bucket UNEXPLAINED / UNMATCHED_PRAAT / UNMATCHED_R.\n")
}
cat("---------------------------------------------------------\n")
cat(sprintf("full detail: %s\n\n", file.path(outDir, "reconciliation.tsv")))
