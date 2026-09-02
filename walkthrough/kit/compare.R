# compare.R -- join the two result tables and state, in one number, whether
# the kit is green.
#
# Run it AFTER both runners:
#     Praat:  open RUN_ME_FIRST.praat, click Run        -> audit/praat_results.tsv
#     R:      open run_analyses.R, click Source         -> audit/r_results.tsv
#     then:   open this file, click Source              -> results/reconciliation.tsv,
#                                                          results/SUMMARY.md and friends
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
auditDir <- file.path(kitDir, "audit")
# TWO OUTPUT DIRECTORIES, SPLIT BY AUDIENCE. audit/ is the working record:
# the two long tables the runners emit and this file consumes, the per-cell
# reports from both sides, and VERDICT.txt (the invariant check, teed to the
# console below) -- everything results/ is derived from, with this file's
# own header as the column definitions (audit/README.md says so in one
# line). results/ holds what a person opens first: reconciliation.tsv (the
# full row-by-row join) and, from the GENERATION step below, SUMMARY.md and
# the rest of the generated tables.
dir.create(auditDir, showWarnings = FALSE)
resultsDir <- file.path(kitDir, "results")
dir.create(resultsDir, showWarnings = FALSE)

# lre() -- REUSED, never rewritten, from validate/lre.R (the same function
# validate/v19_nist_strd.R scores the plugin's NIST cells with). kitDir is
# walkthrough/kit; the repo root is two levels up.
source(file.path(dirname(dirname(kitDir)), "validate", "lre.R"))

need <- file.path(auditDir, c("praat_results.tsv", "r_results.tsv"))
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

# --- HONOURING THE ROW FILTER ------------------------------------------------
# Both runners now accept a comma-separated procedure filter (RUN_ME_FIRST.praat's
# emlKitProcFilter$, run_analyses.R's EML_KIT_PROC_FILTER) and, on a filtered
# run, write ZERO rows for a skipped cell -- not a refusal, not a value, no row
# of any kind. compare.R is handed no filter string of its own and does not
# need one: a cell with no row on EITHER side was never driven by either
# runner, and reporting its contracted quantities as MISSING would be reporting
# on a row nobody ran. A cell driven on only ONE side is left alone -- the two
# runners are meant to share one filter, so a one-sided gap there is not
# filtering, it is exactly the kind of thing MISSING/UNMATCHED exists to catch.
nMxTotal <- nrow(mx)
neverDriven <- setdiff(mx$cell_id, union(unique(P$cell_id), unique(R$cell_id)))
isFilteredRun <- length(neverDriven) > 0
if (isFilteredRun) {
    excludedProcs <- sort(unique(mx$procedure[mx$cell_id %in% neverDriven]))
    mx <- mx[!(mx$cell_id %in% neverDriven), , drop = FALSE]
    cat(sprintf("\n*** FILTERED RUN: %d of %d matrix.tsv cells were never driven by either runner.\n",
                length(neverDriven), nMxTotal))
    cat(sprintf("*** excluded procedure(s): %s\n", paste(excludedProcs, collapse = ", ")))
    cat(sprintf("*** Reporting only on the %d driven cells (procedure(s): %s).\n",
                nrow(mx), paste(sort(unique(mx$procedure)), collapse = ", ")))
}

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
#
# RETIRED 2026-08-27, per docs/RULING_BARE_RUN_2026-08-27.md (Fable with Ian).
# The whole list below is retired -- every entry that used to live here is
# commented out under RETIRED_DECLARED_2026_08_27 further down, INPUT TO
# NOTHING. This is the bare run: DECLARED is empty, every row compares, and
# the residue is measured fresh rather than read off the old excuses. The
# mechanism itself (the list structure, matching, bucketing, the balance
# invariant) is unchanged and still works on zero entries -- an empty list
# simply means every previously-declared row now falls to UNEXPLAINED or
# CONTRACT_*, which is the point.
# ---------------------------------------------------------------------------
DECLARED <- list(
    # REBUILT 2026-08-27 from the fresh run, not copied from the retired list.
    # Every clause below matched a family in that run and carries the number
    # measured there. A family whose bound the fresh run exceeds is NOT here:
    # an exceeded bound is a finding, not a bound to raise.

    list(q = "^posthoc_.*_diff_wilcoxest(_undefined)?$", where = "r",
         id = "D-WILCOXEST",
         why = paste("DOCUMENTED ABSENCE, R-side, under the",
                     "definition-over-implementation rule. The plugin computes the",
                     "DEFINITIONAL Hodges-Lehmann median of the pairwise differences, and",
                     "that quantity is already compared under posthoc_*_diff. R's",
                     "*_diff_wilcoxest field is the estimate wilcox.test returns from its",
                     "own uniroot search over the shifted statistic -- an artifact of how",
                     "that function locates the estimate, not a second definition of it. It",
                     "has no plugin counterpart to compare against. R keeps emitting it, and",
                     "this clause is the disclosure that it was seen and accounted for",
                     "rather than dropped. Ordered by the bare-run adjudication, 26 August;",
                     "the measured family is 261 rows including the graded variants and the",
                     "_undefined markers.")),

    list(q = "^posthoc_.*_padj$", where = "diff", id = "D-PTUKEY",
         maxrel = 5e-3, vmax = 1e-9,
         why = paste("EXTREME-TAIL QUADRATURE, DIAGNOSED 27 AUGUST 2026, AND",
                     "ENVIRONMENT-DEPENDENT. Both sides evaluate the studentised range",
                     "distribution. The statistic itself is identical: at cell c0069, pair",
                     "paired__perfect, q = 14.123877432410683 on the run machine and",
                     "14.12387743241068350 in the reference container -- the same number.",
                     "Only the CDF evaluation differs, so the spread is in ptukey's",
                     "quadrature and nowhere else.",
                     "It also depends on the Praat build. Against R's",
                     "5.6645799162424737e-12, the container returns 5.66435787e-12",
                     "(3.9e-5 relative) and the run machine returns 5.671796365902537e-12",
                     "(1.27e-3). The bound is 5e-3, set above the wider of the two rather",
                     "than tuned to either, and asserted below.",
                     "SCOPED to padj < 1e-9 by vmax. This clause speaks only for the",
                     "extreme tail, where quadrature error is largest and the absolute",
                     "difference is nil. A padj disagreement anywhere else is not covered",
                     "and stays unexplained.")),

    list(q = "^posthoc_.*_padj$", where = "diff", id = "D-PTUKEY-MID",
         maxrel = 1e-5, vmin = 1e-9, vmax = 1e-5,
         why = paste("TIER 2 OF THE ptukey QUADRATURE FAMILY, ruled 27 August 2026.",
                     "Same diagnosis as D-PTUKEY: the studentised range statistic is",
                     "bit-identical across Praat builds -- q = 14.123877432410683 on the",
                     "run machine and 14.12387743241068350 in the reference container --",
                     "and the spread lies entirely in the CDF evaluation, which is",
                     "build-dependent.",
                     "Scoped to 1e-9 <= padj < 1e-5, where the measured worst relative",
                     "disagreement is 8.3e-7. The bound is 1e-5: about twelve times that,",
                     "which is headroom for a third Praat build nobody here has measured,",
                     "and still five hundred times tighter than the far-tail bound.",
                     "Above padj 1e-5 no clause applies and the kit default governs,",
                     "which this run shows it holds. A run exceeding either tier is a",
                     "finding routed back, never a raise.")),

    list(q = "^(task|voice_type)(__(task|voice_type))?_(ss|ms|f|p|partial_eta_squared)$",
         where = "diff", id = "D-TWOWAY-PRECISION",
         proc = "emlRunTwoWayAnalysis", maxrel = 2e-8,
         why = paste("PRECISION CEILING, NOT A DISAGREEMENT.",
                     "@emlRunTwoWayAnalysis does not compute the two-way ANOVA: it parses",
                     "the text of Praat's own 'Report two-way anova', which prints SS to",
                     "about nine significant digits. Every quantity derived from those sums",
                     "inherits that ceiling. Measured worst relative disagreement in this",
                     "run: 1.223e-8, against the 2e-8 bound this clause has carried since",
                     "26 August. The bound is asserted below, not assumed.")),

    list(q = "^refuse_reason$", where = "diff", id = "D-WORDING",
         why = paste("Refusal wording differs between implementations. That the SET of cells",
                     "that refuse is the same one is asserted separately, three ways at once",
                     "(declared in matrix.tsv, actually refused by Praat, actually refused by",
                     "R): 20 cells refuse on all three and match. Four more (c0075, c0156,",
                     "c0564, c0565) refuse in Praat only -- R produced no rows for them at",
                     "all, not a computed answer -- and are surfaced as an open asymmetry,",
                     "not silently waived here or resolved as a difference this clause",
                     "covers.")),

    list(q = "^alpha_if_deleted_.*_undefined$", where = "praat", id = "D-ALPHA2ITEM",
         why = paste("Alpha-if-item-deleted on a two-item scale would leave one item, for",
                     "which alpha is undefined. The plugin emits the undefined marker; the R",
                     "side does not attempt the quantity at k = 2. Same statement, two",
                     "spellings.")),

    list(q = "^delta_(max|row_[0-9]+)$", where = "diff", id = "D-ALPHADROP",
         proc = "emlAlphaInfluence",
         why = paste("Leave-one-out alpha on the n = 3 fixture reaches a two-respondent",
                     "submatrix in which one item has no variance. psych::alpha deletes that",
                     "item and computes on k = 3; the plugin keeps it and computes on k = 4.",
                     "Different scale definitions, hence different alpha. Ruled by Fable as",
                     "a divergence with the derivation carried as provenance."))
)

# --- RETIRED_DECLARED_2026_08_27 -- input to nothing ------------------------
# Kept verbatim, for reference only, so nobody has to reconstruct what used
# to be here. NOT read by any code above: DECLARED is the empty list() bound
# above this comment block, and R never evaluates a comment. Do not restore
# an entry from here because it "looks right" -- the ruling requires the new
# rule set to be written from the fresh measurement, not from this list.
#
# DECLARED_RETIRED <- list(
#     list(q = "^hedges_g$", where = "diff", id = "D-HEDGES",
#          why = paste("Hedges' g bias correction: the plugin uses the APPROXIMATE factor",
#                      "J = 1 - 3/(4*df-1); effectsize uses the EXACT J = gamma(df/2) /",
#                      "(sqrt(df/2)*gamma((df-1)/2)). Hedges (1981) gives the exact form and",
#                      "presents the other as an approximation for hand computation. The exact",
#                      "form is the published definition and Praat has lnGamma, so the plugin",
#                      "could compute it. Relative difference ~2e-5. THIS IS A PLUGIN DEFECT,",
#                      "not a tolerance question.")),
#     list(q = "^(spearman_p|p)$", where = "diff", id = "D-SPEARMAN", proc = "emlRunCorrelationAnalysis",
#          why = paste("Spearman's p: the plugin computes the large-sample t-approximation on",
#                      "n-2 df; stats::cor.test returns the EXACT permutation p for small n",
#                      "without ties (AS89 otherwise). Different p for the same null, most",
#                      "visibly at rho=1 where the exact p is 2/n! and the approximation goes",
#                      "to ~0. Both runners also emit spearman_p_asymptotic, and those AGREE --",
#                      "which is what pins this to the choice of tail and not to arithmetic.")),
#     list(q = "^spearman_p$", where = "r", id = "D-SPEARMAN",
#          why = "The exact Spearman p has no plugin counterpart; see D-SPEARMAN."),
#     list(q = "^spearman_(t|df)$", where = "praat", id = "D-SPEARMAN",
#          why = "t and df are intrinsic to the plugin's t-approximation; cor.test reports S instead."),
#     list(q = "^spearman_s$", where = "r", id = "D-SPEARMAN",
#          why = "cor.test's S statistic is intrinsic to its exact method; the plugin reports t/df instead."),
#     list(q = "^posthoc_.*_(ci_low|ci_high)$", where = "r", id = "D-NOCI",
#          why = paste("NO POST-HOC CONFIDENCE INTERVAL. None of @emlTukeyHSD, @emlDunnTest,",
#                      "@emlPairwiseT, @emlPairwiseWilcoxon or @emlScheffe returns an interval;",
#                      "each gives a statistic, a p and an effect size. Reporting a comparison",
#                      "without an interval for the estimate is against current reporting",
#                      "guidance. THIS IS A PLUGIN GAP and the largest single one in this table.")),
#     list(q = "^posthoc_.*_diff$", where = "r", id = "D-NODIFF",
#          why = paste("@emlRunPairwiseAnalysis sets .stDiffMat to @emlPublishAbsentMatrix for",
#                      "its t and Wilcoxon arms -- the mean difference is deliberately marked",
#                      "absent, not merely unextracted. So the plugin reports whether a pair",
#                      "differs and by how much in SD units, but not by how much in the data's",
#                      "own units. A plugin gap, and a documented one.")),
#     list(q = "^posthoc_.*_q$", where = "praat", id = "D-TUKEYQ",
#          why = "Tukey's studentised range q; stats::TukeyHSD does not expose it."),
#     list(q = "^posthoc_.*_(padj|p|f|diff)$", where = "praat", id = "D-SCHEFFE",
#          test = "scheffe",
#          why = paste("Scheffe's test: no installed R package implements it (checked across",
#                      "rstatix, effectsize, car, afex, multcomp, nortest, coin, psych and base",
#                      "stats; multcomp::glht's adjusted() has no Scheffe option). The R side",
#                      "emits skipped/skip_reason for these cells rather than hand-deriving the",
#                      "Scheffe F. An R-side capability gap, declared as one.")),
#     list(q = "^(skipped|skip_reason)$", where = "r", id = "D-SCHEFFE",
#          why = "The R side's declared skip on the Scheffe cells; see D-SCHEFFE."),
#     list(q = "^n_undefined$", where = "praat", id = "D-PAIRWISE-N",
#          why = paste("@emlRunPairwiseAnalysis lists .stN in its own Outputs header, initialises",
#                      "it to undefined and never assigns it, so the procedure cannot report the",
#                      "sample size it analysed. The runner emits n_undefined rather than",
#                      "silently writing no row. THIS IS A PLUGIN DEFECT.")),
#     list(q = "^n$", where = "r", id = "D-PAIRWISE-N", proc = "emlRunPairwiseAnalysis",
#          why = "The R counterpart of the n the plugin cannot report; see D-PAIRWISE-N."),
#     list(q = "^eta_squared$", where = "r", id = "D-KW-ETA",
#          why = paste("Kruskal-Wallis eta-squared[H]. The plugin reports epsilon-squared only",
#                      "(and that value AGREES). A DOCUMENTED ABSENCE, not a coverage gap: per",
#                      "docs/RULING_KIT_DELTAS_2026-08-26.md, this is a decided non-quantity --",
#                      "epsilon-squared is the plugin's stated choice of KW effect size, cited",
#                      "here rather than left as an unexplained one-sided row.")),
#     list(q = "^(skewness_b1|kurtosis_b2)(_undefined)?$", where = "r", id = "D-SHAPE",
#          why = paste("psych::describe's OWN default estimator (type 3, the b1/b2 moment",
#                      "ratios), emitted alongside the type-2 G1/G2 that `skewness` and",
#                      "`kurtosis` carry on both sides. Present so the estimator choice is",
#                      "visible in the data rather than only in a comment.")),
#     list(q = "^wilcox_r$", where = "r", id = "D-WILCOXR",
#          why = paste("rstatix::wilcox_effsize's r = Z/sqrt(N) (Rosenthal's r), which is NOT",
#                      "the rank-biserial correlation and has no plugin counterpart. It was",
#                      "originally emitted under the name rank_biserial on the R side, which",
#                      "made two different statistics look like one disagreement.")),
#     list(q = "^cramers_v_(yates|bias_corrected)$", where = "r", id = "D-CRAMER",
#          why = paste("The two packages' own DEFAULTS, kept under names that say what they",
#                      "are: rstatix::cramer_v defaults to Yates-corrected, effectsize::cramers_v",
#                      "to Bergsma's bias-corrected V. The bare `cramers_v` on both sides is the",
#                      "plain uncorrected V and AGREES. Yates corrects a test, not an effect",
#                      "size, which is why the axis is not carried into V.")),
#     list(q = "^gg_(p|epsilon)(_undefined)?$", where = "both", id = "D-GG",
#          why = paste("Greenhouse-Geisser. At k=2 there is one within-subject df and sphericity",
#                      "is trivial, so the R side does not report a correction; the plugin falls",
#                      "back to the epsilon lower bound 1/(k-1) and reports one. Where afex",
#                      "cannot compute GG at all it returns epsilon=NA while still printing",
#                      "Pr(>F[GG]) as 0 -- a sentinel, not a p-value, and not emitted.")),
#     list(q = "^(mean|median|sd|sem|variance|skewness|kurtosis|skewness_b1|kurtosis_b2|q1|q3|iqr|ci_low|ci_high|n|p|w_statistic)(_undefined)?$",
#          where = "both", id = "D-PARSE", dataset = "rp_r6_parse_conditions_input",
#          why = paste("LOCALE PARSING. This fixture holds the cell \"73,4\". Praat's own",
#                      "number() primitive reads that as 73 -- it stops at the comma and drops",
#                      "the fraction. @emlRunNormalityAnalysis accepts the cell on that basis",
#                      "and reports n=4 with the wrong value; @emlRunDescriptiveAnalysis",
#                      "rejects the same cell and reports n=3. So two procedures disagree with",
#                      "each other about one cell in one column, and neither reads it as 73.4.",
#                      "The R side applies the documented rule (a single comma is a decimal",
#                      "point) and reads 73.4. THIS IS A PLUGIN DEFECT, in two parts, and the",
#                      "kit does not tune it away.")),
#     list(q = "^(ci_low|ci_high)$", where = "praat", id = "D-CONSTCI",
#          why = paste("95% CI of the mean on a column with zero variance. The plugin returns",
#                      "the degenerate interval [mean, mean]; stats::t.test refuses ('data are",
#                      "essentially constant') and the R side reports every other descriptive",
#                      "and omits only the interval. Both are defensible.")),
#     list(q = "^(.*_ss|.*_ms|.*_f|.*_p|.*_partial_eta_squared)$", where = "diff",
#          id = "D-TWOWAY-PRECISION", proc = "emlRunTwoWayAnalysis", maxrel = 2e-8,
#          why = paste("PRECISION CEILING, NOT A DISAGREEMENT. @emlRunTwoWayAnalysis does not",
#                      "compute the two-way ANOVA: it parses the text of Praat's own built-in",
#                      "'Report two-way anova', which prints SS to about nine significant",
#                      "digits (1092.1626 for 1092.162604968245). Every quantity derived from",
#                      "those sums -- F, p, MS, the partial eta-squareds -- inherits that",
#                      "ceiling, on all 18 rows this pattern reaches (2 cells x 9 quantities).",
#                      "NAMED PER-PROCEDURE TOLERANCE, per docs/RULING_KIT_DELTAS_2026-08-26.md:",
#                      "measured relative disagreement on this table tops out at ~1.22e-8",
#                      "(voice_type_p); the bound is set at 2e-8, headroom above that measured",
#                      "ceiling rather than tuned to it exactly, and is ASSERTED below, not",
#                      "assumed. This procedure structurally CANNOT agree to machine precision",
#                      "the way every other one here does -- the reason is the parsed report's",
#                      "own printed precision, not this comparison's tolerance.")),
#     list(q = "^delta_(max|row_[0-9]+)$", where = "diff", id = "D-ALPHADROP",
#          why = paste("Leave-one-out alpha on an n=3 fixture reaches a 2-respondent submatrix",
#                      "in which one item has no variance. psych::alpha deletes that item (it",
#                      "warns) and computes alpha on k=3; the plugin keeps it and computes on",
#                      "k=4. Different scale definitions, hence different alpha. A degenerate",
#                      "corner, reported rather than resolved.")),
#     list(q = "^posthoc_.*_padj$", where = "diff", id = "D-PTUKEY", maxrel = 1e-4,
#          why = paste("Tukey adjusted p in the far tail. Both sides evaluate the studentised",
#                      "range distribution; the two numerical implementations differ by ~4e-5",
#                      "relative at p = 5.7e-12. Same definition, different quadrature. Bounded",
#                      "by maxrel below, and the bound is asserted, not assumed.")),
#     list(q = "^(chi_square|p|kendalls_w)$", where = "praat", id = "D-FRIEDMAN-DEGEN",
#          proc = "emlRunFriedmanAnalysis",
#          why = paste("Friedman on data where every subject gives identical values across",
#                      "all conditions: every rank is tied, and the statistic is 0/0. The",
#                      "plugin reports chi-square = 0, p = 1, W = 0 -- a defensible reading",
#                      "of 'no evidence of any difference'. stats::friedman.test returns NaN",
#                      "and the R side emits the _undefined markers instead. Both are honest;",
#                      "they are different conventions for the same degenerate input.")),
#     list(q = "^(chi_square|p|kendalls_w|posthoc_.*)_undefined$", where = "r",
#          id = "D-FRIEDMAN-DEGEN", proc = "emlRunFriedmanAnalysis",
#          why = "The R side of the same degenerate Friedman cell; see D-FRIEDMAN-DEGEN."),
#     list(q = "^alpha_if_deleted_.*_undefined$", where = "praat", id = "D-ALPHA2ITEM",
#          why = paste("Alpha-if-item-deleted on a two-item scale would leave one item, for",
#                      "which alpha is undefined. The plugin emits the undefined marker; the R",
#                      "side does not attempt the quantity at k=2. Same statement, two spellings.")),
#     list(q = "^.*_eta_squared$", where = "r", id = "D-TWOWAY-ETA",
#          proc = "emlRunTwoWayAnalysis",
#          why = paste("Non-partial eta-squared per term. The plugin reports partial eta-squared",
#                      "only (and those AGREE). A coverage gap, not an error.")),
#     list(q = "^refuse_reason$", where = "diff", id = "D-WORDING",
#          why = "Refusal wording differs between implementations; that the same cells refuse is asserted separately."),
#     list(q = "^(n_excluded|overall_adj_r_squared|sd_group1|sd_group2|mean_group1|mean_group2|median_group1|median_group2|mean_diff|n)$",
#          where = "r", id = "D-MINOR",
#          why = paste("Quantities the R side reports on cells where the plugin either has no",
#                      "output for them (@emlRunPairedAnalysis exposes no excluded-row count;",
#                      "@emlRunGroupedRegressionAnalysis exposes no adjusted R-squared) or refused the",
#                      "cell outright (the nine expect=ok cells listed in the README)."))
# )

# ---------------------------------------------------------------------------
key <- function(d) paste(d$cell_id, d$quantity, sep = "\r")
P$key <- key(P); R$key <- key(R)
procOf <- setNames(mx$procedure, mx$cell_id)
testOf <- setNames(mx$test, mx$cell_id)
dsOf   <- setNames(mx$dataset, mx$cell_id)

# ---------------------------------------------------------------------------
# THREE STUDIES (Ian's ruling, docs/MEMO_TO_FABLE_TIERS_2026-08-28.md; the
# NIST criterion itself, mailbox/to-fable/MEMO_NIST_CRITERION_SHAPE_2026-08-31.md):
#   options  the plugin's own option space, oracled against R packages.
#   sweep    the designed shape grid, oracled against base R exactly like
#            any other cell -- it shares the machinery below untouched.
#   nist     NIST StRD certified datasets. NO R ORACLE FOR PASS/FAIL: a nist
#            cell's plugin value is judged against nist_certified.tsv's
#            published constant directly, never against R's own value, so a
#            nist row is split out of P/R here, before the Praat-vs-R
#            contract machinery below ever sees it -- otherwise every
#            contracted "both" quantity on a nist cell would read as R
#            having missed it, when the absence from that machinery is by
#            design. run_analyses.R DOES now run these cells (base R via
#            aov(), the same computation every other ANOVA cell gets) --
#            Rnist keeps that column so THE NIST STUDY block, further down,
#            can use base R's own distance from the certified constant as
#            the yardstick the plugin is allowed to trail by SLACK digits.
#            Pnist keeps the raw Praat rows the plugin is actually scored on.
# ---------------------------------------------------------------------------
if (!"study" %in% names(mx))
    stop("matrix.tsv needs a trailing `study` column (options | sweep | nist) -- ",
         "see docs/MEMO_TO_FABLE_TIERS_2026-08-28.md.", call. = FALSE)
badStudy <- setdiff(unique(mx$study), c("options", "sweep", "nist"))
if (length(badStudy))
    stop("matrix.tsv: unrecognised study value(s): ", paste(badStudy, collapse = ", "), call. = FALSE)
studyOf <- setNames(mx$study, mx$cell_id)

nistCells  <- mx$cell_id[mx$study == "nist"]
Pnist      <- P[P$cell_id %in% nistCells, , drop = FALSE]
Rnist      <- R[R$cell_id %in% nistCells, , drop = FALSE]
P          <- P[!(P$cell_id %in% nistCells), , drop = FALSE]
R          <- R[!(R$cell_id %in% nistCells), , drop = FALSE]
mxContract <- mx[!(mx$cell_id %in% nistCells), , drop = FALSE]

# ---------------------------------------------------------------------------
# EXPANDING THE CONTRACT OVER THE 630 CELLS.
# One pass. For every cell, every clause of its procedure whose `when` holds,
# expanded over that clause's index set. The result is the flat list of
# (cell_id, quantity, sides) this run owes.
# ---------------------------------------------------------------------------
expCell <- character(0); expQty <- character(0); expSides <- character(0)
expNote <- character(0)
QTbyProc <- split(seq_len(nrow(QT)), QT$procedure)
for (ci in seq_len(nrow(mxContract))) {
    cell <- mxContract[ci, ]
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
        expNote  <- c(expNote,  rep(QT$note[qi], length(names)))
    }
}
EXP <- data.frame(cell_id = expCell, quantity = expQty, sides = expSides,
                  note = expNote, stringsAsFactors = FALSE)
EXP <- EXP[!duplicated(paste(EXP$cell_id, EXP$quantity, sep = "\r")), , drop = FALSE]
sidesOf <- setNames(EXP$sides, paste(EXP$cell_id, EXP$quantity, sep = "\r"))
# THE CLAUSE'S OWN NOTE, KEYED THE SAME WAY. Without this a CONTRACT row
# reaches the reconciliation with enforcement "no rule found" and an empty
# reason, which is exactly the absence the file exists to prevent -- and it
# is the largest family in the table, so it is the first thing a reader
# meets. The reason a contract row is one-sided is written in
# quantities.tsv; it belongs in the row.
noteOf <- setNames(EXP$note, paste(EXP$cell_id, EXP$quantity, sep = "\r"))

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
contractNote <- function(cell, quantity) {
    n <- noteOf[paste(cell, baseName(quantity), sep = "\r")]
    if (is.na(n)) "" else unname(n)
}
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
# VALUE SCOPE. A clause may name the magnitude range it speaks for: `vmax` is
# the largest magnitude it covers, `vmin` the smallest. A quadrature spread
# that is real at p ~ 1e-12 says nothing about the same quantity at p ~ 0.05,
# and one bound wide enough for the far tail would excuse a genuine
# disagreement in the body. Scopes let one family carry tiers, each bound
# sitting close to what it governs.
#
# Selection walks DECLARED in order and skips a clause whose pattern matches
# but whose scope does not, so a later tier gets its turn. A row matching no
# tier's scope stays unexplained -- that is the point, not a gap.
inScope <- function(r, value) {
    if (is.null(r$vmin) && is.null(r$vmax)) return(TRUE)
    if (is.null(value) || is.na(value)) return(TRUE)
    if (!is.null(r$vmax) && value >= r$vmax) return(FALSE)
    if (!is.null(r$vmin) && value <  r$vmin) return(FALSE)
    TRUE
}
declaredFor <- function(cell, quantity, side, value = NULL) {
    for (r in DECLARED) {
        if (matches(r, cell, quantity, side) && inScope(r, value)) return(r)
    }
    NULL
}

num <- function(x) suppressWarnings(as.numeric(x))
agree <- function(a, b) {
    if (is.na(a) || is.na(b)) return(FALSE)
    d <- abs(a - b); s <- max(abs(a), abs(b))
    if (s < 1e-12) d < 1e-12 else (d / s) < 1e-9
}

rows <- list(); add <- function(...) rows[[length(rows) + 1]] <<- list(...)
# AGREEMENTS ARE ROWS TOO. The loop below only ever called add() on a
# difference or a one-sided row -- an agreement was counted (nAgree) and
# dropped. results/agreements_all.tsv (the generation step, further down)
# needs the actual values, so every agreement is now also kept, in its own
# list, at the point it is found.
agreeRows <- list(); addAgree <- function(...) agreeRows[[length(agreeRows) + 1]] <<- list(...)
nAgree <- 0L; nDeclared <- 0L; nUnexplained <- 0L; nCompared <- 0L; maxRelSeen <- list()
# Split for the balance invariant below: a DECLARED row reached via the
# both-sides comparison loop (values present on both sides, differing by a
# documented/bounded amount) is TOLERANCE-BOUNDED; a DECLARED row reached via
# oneSided() (the quantity is absent from one side, and DECLARED[] says why)
# is DOCUMENTED-ABSENT, same as a CONTRACT_ONLY_* row. nDeclared itself stays
# their sum, for the existing summary line below.
nDeclaredDiff <- 0L; nDeclaredOneSided <- 0L

both <- intersect(P$key, R$key)
Pl <- split(seq_len(nrow(P)), P$key); Rl <- split(seq_len(nrow(R)), R$key)
for (k in both) {
    pi <- Pl[[k]][1]; cell <- P$cell_id[pi]; q <- P$quantity[pi]
    pv <- num(P$value[pi])
    # A "both" key with MORE THAN ONE Praat row is not accommodated by the
    # single representative pi above (only the first is ever compared). That
    # would be exactly the failure the balance invariant exists to catch --
    # a row silently unaccounted for -- so any extra Praat row for this key is
    # surfaced explicitly rather than dropped. Not expected in practice (no
    # cell_id+quantity pair is meant to repeat on the Praat side); asserted
    # here, not assumed.
    if (length(Pl[[k]]) > 1) for (pi2 in Pl[[k]][-1]) {
        nUnexplained <- nUnexplained + 1L
        add(bucket = "UNEXPLAINED", id = "", cell_id = cell, quantity = q,
            praat = P$value[pi2], r = "",
            source = "duplicate (cell_id,quantity) key on the Praat side; only the first row is ever paired against R")
    }
    for (ri in Rl[[k]]) {
        nCompared <- nCompared + 1L
        rv <- num(R$value[ri]); src <- R$source[ri]
        if (is.na(pv) && is.na(rv)) {
            # text-valued on both sides (refuse_reason and friends)
            if (identical(P$value[pi], R$value[ri])) {
                nAgree <- nAgree + 1L
                addAgree(cell_id = cell, quantity = q, praat = P$value[pi], r = R$value[ri])
                next
            }
        } else if (agree(pv, rv)) {
            nAgree <- nAgree + 1L
            addAgree(cell_id = cell, quantity = q, praat = P$value[pi], r = R$value[ri])
            next
        }
        .mag <- if (!is.na(pv) && !is.na(rv)) max(abs(pv), abs(rv)) else NA_real_
        rule <- declaredFor(cell, q, "diff", .mag)
        if (!is.null(rule)) {
            if (!is.null(rule$maxrel) && !is.na(pv) && !is.na(rv)) {
                rel <- abs(pv - rv) / max(abs(pv), abs(rv))
                maxRelSeen[[rule$id]] <- max(c(maxRelSeen[[rule$id]], rel))
            }
            nDeclaredDiff <- nDeclaredDiff + 1L; nDeclared <- nDeclared + 1L
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
# `idxs` walks EVERY row on the owning side for this key, not just the first.
# A one-sided key that repeats (the runner wrote the same cell_id+quantity
# more than once) used to have its extra rows silently skipped here -- unlike
# the both-sides loop above, which already looped over every R row, this one
# took only the first index and never reconsidered the rest. That is precisely
# a row falling out of all three categories: not compared (it never reached
# the both-sides loop, its key is one-sided by construction), not declared,
# not contracted, not unexplained -- just absent from reconciliation.tsv.
# Fixed by classifying each duplicate row on its own, same as any other row.
oneSided <- function(keys, tbl, side) {
    for (k in keys) for (i in (if (side == "praat") Pl[[k]] else Rl[[k]])) {
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
            nDeclaredOneSided <<- nDeclaredOneSided + 1L; nDeclared <<- nDeclared + 1L
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

# -----------------------------------------------------------------------
# THE REFUSAL ASSERTION: SET EQUALITY, NOT A ONE-WAY WAIVER. Refusal wording
# differs between implementations by design (D-WORDING); the SET of cells
# that refuse does not get that latitude -- it is asserted to be identical
# across three sources: what matrix.tsv declares, what Praat actually did,
# and what R actually did. Five ways for that to fail, each reported and
# each counted on its own, because a cell can land in more than one of them
# at once and each is a distinct defect:
#   missP / missR       -- matrix.tsv declares refuse=1 here, but that side
#                           computed a real answer instead (the ORIGINAL,
#                           one-directional check this block used to be)
#   undeclaredP/R        -- a side refused a cell matrix.tsv never declared
#                           expect=refuse for (the hole the one-directional
#                           check could not see: a side going quiet on
#                           something nobody wrote down)
#   asymRefuse            -- exactly one side refused a cell the other side
#                           did not, regardless of what matrix.tsv says --
#                           the two implementations disagree about whether
#                           the cell can be analysed at all, which is a
#                           finding for Fable, not a thing this file resolves
# A green run has all five empty. See mailbox/to-opus/
# WORK_ORDER_NIST_UNIFICATION_2026-08-31.md, item 3.
# -----------------------------------------------------------------------
# STALENESS FIRST. A results file can carry cell_ids the matrix no longer
# contains -- the file was written against an older matrix and never
# regenerated. Those rows are not evidence about the plugin; they are evidence
# that the file is old. They must not enter the refusal arithmetic, because a
# cell that exists on one side only BECAUSE ITS FILE IS STALE would otherwise
# read as the two implementations disagreeing about whether it can be analysed
# -- a real finding manufactured out of a housekeeping failure. They are
# reported under their own heading and they fail the run on their own, so the
# authoritative run cannot happen on top of a stale file.
matrixCells <- unique(mx$cell_id)
staleP <- sort(setdiff(unique(P$cell_id), matrixCells))
staleR <- sort(setdiff(unique(R$cell_id), matrixCells))
staleCells <- sort(union(staleP, staleR))
nStaleCells <- length(staleCells)

refP <- sort(setdiff(unique(P$cell_id[P$quantity %in% c("refused", "skipped")]), staleCells))
refR <- sort(setdiff(unique(R$cell_id[R$quantity %in% c("refused", "skipped")]), staleCells))
declaredRefuse <- sort(mx$cell_id[mx$expect == "refuse"])
missP <- setdiff(declaredRefuse, refP); missR <- setdiff(declaredRefuse, refR)
undeclaredP <- setdiff(refP, declaredRefuse)
undeclaredR <- setdiff(refR, declaredRefuse)
asymRefuse  <- sort(union(setdiff(refP, refR), setdiff(refR, refP)))
matchedRefuse <- sort(intersect(intersect(refP, refR), declaredRefuse))

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
flatten1v <- function(x) gsub("[\t\r\n]+", " ", as.character(x))
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

# ---------------------------------------------------------------------------
# THE NIST STUDY (mailbox/to-fable/MEMO_NIST_CRITERION_SHAPE_2026-08-31.md).
# ONE RULE, TWO SHAPES, mirroring validate/v19_nist_strd.R exactly -- lre()
# itself is sourced from validate/lre.R above and never reimplemented here:
#
#   df.between, df.within   EXACT INTEGERS. Pass is `==` against the
#            certified integer. This branch never calls lre() or agree() --
#            there is no shared code path from here into the LRE branch
#            below, so the relative-error rule is unreachable for df BY
#            CONSTRUCTION, not merely skipped by a guard.
#   every other certified quantity, residual.sd included:
#            plugin_lre = lre(plugin value, certified); r_lre = lre(base R's
#            value, certified) -- base R now runs every nist cell too (moved
#            into process_anova via run_analyses.R, task 2), so Rnist carries
#            it. The plugin passes when plugin_lre is no more than SLACK
#            digits below r_lre. No separate residual-SD assertion: residual
#            SD is sqrt(ms_within), scored by the SAME rule as every other
#            quantity here, off the ms_within values both sides already
#            report -- not a new check invented for it.
#
# The quantity name -> (label prefix, field) map mirrors validate/
# v19_nist_strd.R's own `cv()` -- label is matched by PREFIX ("Between"/
# "Within"), because NIST names the ANOVA rows per dataset ("Between
# Instrument", "Between Treatment", ...); "Certified R-Squared" and
# "Standard Deviation" are matched exactly. A disagreeing or missing row is
# added to `rows` under bucket NIST_DISAGREE / NIST_MISSING_PRAAT --
# alongside, never mixed into, the options/sweep buckets above -- so
# reconciliation.tsv carries one file, one `study` column, and the balance
# invariant below can still be asked of each study on its own. Its ledger
# columns for a nist row are digits_praat / digits_r / min_required_digits /
# digit_margin / status -- NOT the raw-error-ratio praat/r columns the
# options/sweep buckets use, because a raw ratio is exactly the rule this
# study does not apply. On the exact-integer branch digits_praat/digits_r
# hold the two compared integers themselves (there is no digit count to
# report, because lre() never ran), and min_required_digits/digit_margin are
# blank.
# ---------------------------------------------------------------------------
NIST_SLACK <- 1.0   # significant digits the plugin may trail base R by (validate/v19_nist_strd.R's SLACK)
NIST_MAP <- list(
    df_between   = list(prefix = "Between", field = 1L, kind = "int"),
    ss_between   = list(prefix = "Between", field = 2L, kind = "lre"),
    ms_between   = list(prefix = "Between", field = 3L, kind = "lre"),
    f            = list(prefix = "Between", field = 4L, kind = "lre"),
    df_within    = list(prefix = "Within",  field = 1L, kind = "int"),
    ss_within    = list(prefix = "Within",  field = 2L, kind = "lre"),
    ms_within    = list(prefix = "Within",  field = 3L, kind = "lre"),
    eta_squared  = list(prefix = "Certified R-Squared", field = 1L, exact = TRUE, kind = "lre"),
    residual_sd  = list(prefix = "Standard Deviation",  field = 1L, exact = TRUE, kind = "lre",
                        deriveFrom = "ms_within")
)
bareNistName <- function(ds) sub("_input$", "", sub("^nist_", "", ds))

nNistExpected <- 0L; nNistAgree <- 0L; nNistDisagree <- 0L; nNistMissingPraat <- 0L
nistAgreeRows <- list()   # cell_id-tagged, so agreement_by_procedure.tsv can count per (procedure, cellSet)
if (length(nistCells)) {
    nistCertPath <- file.path(kitDir, "nist_certified.tsv")
    if (!file.exists(nistCertPath))
        stop("compare.R needs nist_certified.tsv beside it for the nist study -- the ",
             "published NIST StRD constants each nist-study Praat cell is compared ",
             "against.", call. = FALSE)
    ncLines <- readLines(nistCertPath, warn = FALSE)
    NC <- read.delim(text = ncLines[!startsWith(ncLines, "#")], sep = "\t",
                     colClasses = "character", quote = "")
    PnistVal <- setNames(Pnist$value, paste(Pnist$cell_id, Pnist$quantity, sep = "\r"))
    RnistVal <- setNames(Rnist$value, paste(Rnist$cell_id, Rnist$quantity, sep = "\r"))
    nistValOf <- function(tbl, cid, qty) {
        # tbl is a NAMED CHARACTER VECTOR (setNames(...$value, ...)), not a
        # list: `[[` on a name that is not present errors ("subscript out of
        # bounds") rather than returning NULL, so presence is checked first.
        k <- paste(cid, qty, sep = "\r")
        if (!(k %in% names(tbl))) return(NA_character_)
        unname(tbl[[k]])
    }
    for (cid in nistCells) {
        ds <- bareNistName(unname(dsOf[[cid]]))
        for (q in names(NIST_MAP)) {
            spec <- NIST_MAP[[q]]
            crow <- if (isTRUE(spec$exact))
                NC[NC$dataset == ds & NC$label == spec$prefix & NC$field == as.character(spec$field), ]
            else
                NC[NC$dataset == ds & startsWith(NC$label, spec$prefix) & NC$field == as.character(spec$field), ]
            if (nrow(crow) != 1L) next   # this dataset's SOURCES.txt did not certify this field
            nNistExpected <- nNistExpected + 1L
            cv <- num(crow$certified[1])
            certSrc <- sprintf("nist_certified.tsv / %s field %d", spec$prefix, spec$field)

            # residual_sd has no Output of its own on either side: it is
            # derived from ms_within (sqrt), the quantity both sides DO
            # report -- not a new assertion, just this quantity read off an
            # existing one before the same LRE rule below scores it.
            srcQty <- if (!is.null(spec$deriveFrom)) spec$deriveFrom else q
            pvChr <- nistValOf(PnistVal, cid, srcQty)
            rvChr <- nistValOf(RnistVal, cid, srcQty)
            pvRaw <- num(pvChr); rvRaw <- num(rvChr)
            pv <- if (!is.null(spec$deriveFrom)) (if (is.na(pvRaw)) NA_real_ else sqrt(pvRaw)) else pvRaw
            rv <- if (!is.null(spec$deriveFrom)) (if (is.na(rvRaw)) NA_real_ else sqrt(rvRaw)) else rvRaw

            if (is.na(pvChr) || is.na(pv)) {
                nNistMissingPraat <- nNistMissingPraat + 1L
                add(bucket = "NIST_MISSING_PRAAT", id = "", cell_id = cid, quantity = q,
                    digits_praat = "", digits_r = "", min_required_digits = "", digit_margin = "",
                    status = "MISSING_PRAAT", source = certSrc)
                next
            }

            if (identical(spec$kind, "int")) {
                pass <- isTRUE(pv == cv)
                if (pass) {
                    nNistAgree <- nNistAgree + 1L
                    nistAgreeRows[[length(nistAgreeRows) + 1L]] <- list(cell_id = cid, quantity = q)
                } else {
                    nNistDisagree <- nNistDisagree + 1L
                    add(bucket = "NIST_DISAGREE", id = "", cell_id = cid, quantity = q,
                        digits_praat = as.character(pv), digits_r = as.character(rv),
                        min_required_digits = "", digit_margin = "",
                        status = "FAIL (exact-integer df)", source = certSrc)
                }
                next
            }

            # LRE RULE, everything else. plugin_lre/r_lre are absolute LRE
            # against the certified constant; the pass criterion compares
            # them to each other (base R as the yardstick), never a raw
            # error ratio.
            plugin_lre <- lre(pv, cv)
            r_lre      <- lre(rv, cv)
            minReq     <- if (is.finite(r_lre)) r_lre - NIST_SLACK else NA_real_
            margin     <- if (is.finite(plugin_lre) && is.finite(minReq)) plugin_lre - minReq else NA_real_
            pass       <- is.finite(plugin_lre) && is.finite(minReq) && plugin_lre >= minReq
            if (pass) {
                nNistAgree <- nNistAgree + 1L
                nistAgreeRows[[length(nistAgreeRows) + 1L]] <- list(cell_id = cid, quantity = q)
            } else {
                nNistDisagree <- nNistDisagree + 1L
                add(bucket = "NIST_DISAGREE", id = "", cell_id = cid, quantity = q,
                    digits_praat = sprintf("%.2f", plugin_lre),
                    digits_r = sprintf("%.2f", r_lre),
                    min_required_digits = if (is.finite(minReq)) sprintf("%.2f", minReq) else "",
                    digit_margin = if (is.finite(margin)) sprintf("%.2f", margin) else "",
                    status = "FAIL (LRE below base R - SLACK)", source = certSrc)
            }
        }
    }
}
nNistCompared <- nNistAgree + nNistDisagree
nNistBalances <- (nNistCompared + nNistMissingPraat) == nNistExpected

# UNION-FILLED RBIND. options/sweep rows carry (bucket, id, cell_id,
# quantity, praat, r, source); nist rows carry (bucket, id, cell_id,
# quantity, digits_praat, digits_r, min_required_digits, digit_margin,
# status, source) instead -- a nist row has no raw-error-ratio praat/r pair
# to show, so it does not carry one. base rbind() on data.frames refuses
# mismatched columns, so the union of every row's names is taken first and
# any column absent on a given row is filled "" (never NA -- matching this
# file's own convention, e.g. id="" on every non-CONTRACT row) rather than
# widening every options/sweep add() call to name five nist-only columns it
# has nothing to put in.
out <- if (length(rows)) {
    # base::names, explicitly: the contract-expansion loop above this point
    # assigns a top-level `names <- tmpl` (this file is a script, not a
    # function, so that reassigns the GLOBAL `names`). `names(r)` in call
    # position still finds the base function regardless, but a BARE `names`
    # passed as lapply's FUN argument is evaluated as an ordinary variable
    # and would pick up that shadowed character vector instead.
    allNames <- unique(unlist(lapply(rows, base::names)))
    do.call(rbind, lapply(rows, function(r) {
        r[setdiff(allNames, base::names(r))] <- ""
        as.data.frame(r[allNames], stringsAsFactors = FALSE)
    }))
} else NULL
if (is.null(out)) out <- data.frame(bucket = character(), id = character(),
    cell_id = character(), quantity = character(), praat = character(),
    r = character(), source = character())
if (nrow(out)) {
    ann <- lapply(out$id, enforcementFor)
    out$enforcement <- vapply(ann, function(a) a$enf, character(1))
    # A CONTRACT ROW IS NOT AN UNRULED ROW. Its reason lives in
    # quantities.tsv, so it is written in here rather than left to the reader
    # to go and find. Without this the largest family in the file reads
    # "no rule found" with an empty reason.
    out$why         <- vapply(ann, function(a) a$why, character(1))
    isC <- out$id == "CONTRACT"
    if (any(isC)) {
        out$enforcement[isC] <- paste0(
            "CONTRACT CLAUSE: quantities.tsv declares this quantity for ",
            ifelse(grepl("_ONLY_PRAAT$", out$bucket[isC]), "the plugin only",
            ifelse(grepl("_ONLY_R$", out$bucket[isC]), "R only",
                   "both sides")),
            "; one-sidedness here is declared, not missing")
        out$why[isC] <- flatten1v(mapply(contractNote,
                                         out$cell_id[isC], out$quantity[isC]))
    }
} else {
    out$enforcement <- character(); out$why <- character()
}
out$study <- if (nrow(out)) unname(studyOf[out$cell_id]) else character(0)
write.table(out, file.path(resultsDir, "reconciliation.tsv"), sep = "\t",
            quote = FALSE, row.names = FALSE)

# THE VERDICT IS WRITTEN AS WELL AS PRINTED. Everything below reaches both
# the console and audit/VERDICT.txt -- the working record, not the reader
# summary; a person reads results/SUMMARY.md, generated below FROM this
# verdict's own numbers (task 8's re-derivation), and this file is what a
# maintainer opens to check the presentation against the measurement. A
# verdict that exists only in a console is gone when the window closes,
# cannot be attached to an email, and cannot be diffed against the next run.
# split = TRUE tees rather than diverts, so the console still shows it live.
# on.exit closes the sink even if something below fails, which otherwise
# leaves the session silently redirected.
.verdictPath <- file.path(auditDir, "VERDICT.txt")
# CAPTURED, NOT SINKED. sink(split = TRUE) writes an EMPTY file under
# RStudio: RStudio replaces the console connection, so the split copy has
# nowhere to go and only the console sees the output. Measured on
# RStudio 4.5.2 -- the file was created at 0 bytes while the console showed
# the whole verdict. capture.output() diverts to a text connection instead,
# which RStudio does not intercept, so the same lines reach both the file and
# the console on every front end.
.emlReport <- capture.output({

cat("\n=========================================================\n")
cat("  EML kit -- reconciliation of the two result tables\n")
cat("=========================================================\n")
cat(sprintf("cells declared in matrix.tsv : %d\n", nrow(mx)))
cat(sprintf("rows, Praat table            : %d\n", nrow(P)))
cat(sprintf("rows, R table                : %d\n", nrow(R)))
cat(sprintf("value comparisons made       : %d\n", nCompared))
cat(sprintf("\n  AGREE       %6d   (relative difference < 1e-9, or absolute < 1e-12 near zero)\n", nAgree))
cat(sprintf("  CONTRACT    %6d   (one-sided rows quantities.tsv accounts for)\n", nContract))
cat(sprintf("  DECLARED    %6d   (differences and one-sided rows with a written reason)\n", nDeclared))
cat(sprintf("  UNEXPLAINED %6d\n", nUnexplained))

# ---------------------------------------------------------------------------
# THE COMPLETENESS LINE, BESIDE THE AGREEMENT LINE.
# ---------------------------------------------------------------------------
cat("\n--- completeness against quantities.tsv ---\n")
cat(sprintf("  contract clauses read        : %d over %d procedures\n",
            nrow(QT), length(unique(QT$procedure))))
cat(sprintf("  contracted quantities, expanded over the %d cells (options+sweep; nist has no contract) : %d\n",
            nrow(mxContract), nrow(EXP)))
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
if (isFilteredRun)
    cat(sprintf("  (filtered run: walking only the %d driven procedure(s); the reverse\n",
                length(unique(mx$procedure))))
if (isFilteredRun)
    cat("   ratchet -- a governed procedure this run never drove -- is suspended below.)\n")
members <- sort(unique(mx$procedure))
governed <- sort(unique(QT$procedure))
kitFail <- 0L
if (!length(members)) {
    cat("  RED: the walk found zero procedures in matrix.tsv. Nothing was graded.\n")
    kitFail <- kitFail + 1L
} else {
    onlyMatrix <- setdiff(members, governed)
    onlyContract <- if (isFilteredRun) character(0) else setdiff(governed, members)
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
cat("\n--- results-file freshness ---\n")
if (nStaleCells == 0) {
    cat("  every cell_id in both results files exists in matrix.tsv\n")
} else {
    cat(sprintf("  STALE: %d cell_id(s) appear in a results file but not in matrix.tsv\n", nStaleCells))
    cat(sprintf("    Praat-only: %s\n", if (length(staleP)) paste(staleP, collapse = ", ") else "none"))
    cat(sprintf("    R-only:     %s\n", if (length(staleR)) paste(staleR, collapse = ", ") else "none"))
    cat("  These rows were written against an older matrix. They are excluded from the\n")
    cat("  refusal arithmetic so they cannot masquerade as an implementation disagreement,\n")
    cat("  and they fail the run: regenerate the results files before the authoritative run.\n")
}

cat("\n--- refusals: three-way set equality (declared, Praat, R) ---\n")
cat(sprintf("  matrix.tsv declares %d cells expect=refuse\n", length(declaredRefuse)))
cat(sprintf("  Praat refused/skipped %d cells; R refused/skipped %d\n", length(refP), length(refR)))
cat(sprintf("  matched (declared = Praat = R, all three agree): %d cell(s)\n", length(matchedRefuse)))
.reportRefuseSet <- function(label, ids) {
    cat(sprintf("  %s %d %s\n", label, length(ids),
                if (length(ids)) paste0("(", paste(ids, collapse = ", "), ")") else ""))
}
.reportRefuseSet("declared refusals missing from Praat:      ", missP)
.reportRefuseSet("declared refusals missing from R:           ", missR)
.reportRefuseSet("Praat refusals not declared in matrix.tsv:  ", undeclaredP)
.reportRefuseSet("R refusals not declared in matrix.tsv:      ", undeclaredR)
.reportRefuseSet("asymmetric (exactly one side refused):      ", asymRefuse)
# A refusal-set failure is a CELL-level defect. nUnexplained is a ROW-level
# counter and the balance invariant checks it against a row total, so adding
# cell counts to it corrupts an accounting identity rather than reporting a
# defect. The five sets get their own counter, deduplicated (a cell can appear
# in more than one set at once and is still one defective cell), and that
# counter fails the run on its own without touching the row arithmetic.
nRefuseSetFail <- length(unique(c(missP, missR, undeclaredP, undeclaredR, asymRefuse)))
if (length(asymRefuse))
    cat(sprintf(paste0("  NOT RESOLVED: the %d asymmetric cell(s) above are a disagreement between the\n",
                        "  two implementations about whether the cell can be analysed at all. This run\n",
                        "  does not decide that question -- it only refuses to stay quiet about it.\n"),
                length(asymRefuse)))

# ---------------------------------------------------------------------------
# THE BALANCE INVARIANT -- Fable's ruling, verbatim: "the contract's arithmetic
# (compared + documented-absent + tolerance-bounded = total) must balance at
# every commit, so a row can never silently fall out of all three categories."
#
#   compared            AGREE                                    -- nAgree
#   documented-absent    CONTRACT_* (contract says one side only)
#                        + DECLARED_ONLY_* (DECLARED[] says one side only) -- nContract + nDeclaredOneSided
#   tolerance-bounded    DECLARED (both sides present, differ by a written,
#                        and where named, BOUNDED amount)         -- nDeclaredDiff
#
# `total` is computed a SECOND, INDEPENDENT way -- not by summing buckets, but
# by counting PHYSICAL ROWS in the two result tables directly: nrow(P) +
# nrow(R), less length(both) once for every (cell_id, quantity) key shared by
# both sides. That subtraction is not a fudge; it falls out of how the
# both-sides loop above is written on purpose: for a shared key, EVERY R row
# is compared (the inner loop walks all of Rl[[k]]), but only ONE
# representative Praat row stands in for the Praat side, because the whole
# point of that loop, for a key like cohens_d (compared against BOTH
# effectsize and rstatix under the same quantity name -- see run_analyses.R's
# own comment on it), is one Praat value checked against every R source, not
# a row-for-row pairing. So a shared key with m R-rows contributes m events,
# not m+1 -- one fewer than its physical row count -- and subtracting
# length(both) once accounts for exactly that, for every shared key at once.
# Every row that is NOT so accounted (a one-sided key's row, or a SECOND
# Praat row on an otherwise-shared key, which the loop above does not
# similarly fold in and instead surfaces on its own) is walked by exactly one
# of the loops above and lands in exactly one bucket -- so under normal
# operation the two totals are the same number arrived at two different ways.
# This is the check that would have caught D-NOCI: a DECLARED[] entry that
# quietly recategorised "R has this, Praat does not" from compared to
# documented-absent, on a claim (the plugin has no such output) nobody
# re-tested once the plugin grew the output. A row that escapes
# classification now shows up as a gap in this arithmetic, not as silence.
# ---------------------------------------------------------------------------
compared         <- nAgree
documentedAbsent <- nContract + nDeclaredOneSided
toleranceBounded <- nDeclaredDiff
sumThree         <- compared + documentedAbsent + toleranceBounded
totalRows        <- nrow(P) + nrow(R) - length(both)
balanceGap       <- totalRows - (sumThree + nUnexplained)
balances         <- balanceGap == 0

cat("\n--- the balance invariant: compared + documented-absent + tolerance-bounded = total ---\n")
cat(sprintf("  compared            (AGREE)                                    %6d\n", compared))
cat(sprintf("  documented-absent   (CONTRACT one-sided + DECLARED one-sided)  %6d\n", documentedAbsent))
cat(sprintf("  tolerance-bounded   (DECLARED, both sides present, differ)     %6d\n", toleranceBounded))
cat(  "  -----------------------------------------------------------------------\n")
cat(sprintf("  sum of the three                                               %6d\n", sumThree))
cat(sprintf("  + UNEXPLAINED (outside all three)                              %6d\n", nUnexplained))
cat(sprintf("  = %6d   vs. total rows in play (nrow(P) + nrow(R) - shared keys): %6d\n",
            sumThree + nUnexplained, totalRows))
if (balances) {
    cat("  balance: HOLDS -- every observed key landed in exactly one category.\n")
} else {
    cat(sprintf("  balance: FAILS -- gap of %d key(s); something fell out of (or was double-counted\n",
                abs(balanceGap)))
    cat("  across) all three categories. See results/reconciliation.tsv.\n")
}

# ---------------------------------------------------------------------------
# THE BALANCE INVARIANT, SPLIT PER STUDY AND IN TOTAL (Ian's ruling,
# docs/MEMO_TO_FABLE_TIERS_2026-08-28.md). The block just above already IS
# options + sweep combined (P/R had the nist cells split out of them well
# before it ran); this restates it per study, so a row cannot escape by being
# filed under the wrong one, and adds the nist study's own accounting, which
# has no Praat-vs-R contract to balance against -- only "did every
# certified field this run owed get compared", which is asked directly.
# ---------------------------------------------------------------------------
studySubBalance <- function(studyName) {
    # %in%, not == : a stale audit/praat_results.tsv can still carry a
    # cell_id matrix.tsv has since retired ("never reused, never renumbered
    # in place" -- matrix.tsv's own header). studyOf[] is then NA for it, and
    # NA == studyName is NA, not FALSE -- which both mis-subsets a data frame
    # (an NA logical index inserts a phantom all-NA row rather than
    # excluding it) and poisons sum() on any bucket vector it touches. %in%
    # never returns NA, so an orphaned cell_id is excluded from every study,
    # exactly as it should be, rather than corrupting all of them.
    Pt <- P[unname(studyOf[P$cell_id]) %in% studyName, , drop = FALSE]
    Rt <- R[unname(studyOf[R$cell_id]) %in% studyName, , drop = FALSE]
    sharedT <- length(intersect(Pt$key, Rt$key))
    totT <- nrow(Pt) + nrow(Rt) - sharedT
    agT  <- sum(unname(studyOf[vapply(agreeRows, `[[`, "", "cell_id")]) %in% studyName)
    ctT  <- sum(out$bucket %in% c("CONTRACT_ONLY_PRAAT", "CONTRACT_ONLY_R", "CONTRACT_UNDEFINED",
                                   "CONTRACT_MISSING_PARTNER") & out$study %in% studyName)
    dOST <- sum(out$bucket %in% c("DECLARED_ONLY_PRAAT", "DECLARED_ONLY_R") & out$study %in% studyName)
    dDT  <- sum(out$bucket == "DECLARED" & out$study %in% studyName)
    uxT  <- sum(out$bucket %in% c("UNEXPLAINED", "UNMATCHED_PRAAT", "UNMATCHED_R") & out$study %in% studyName)
    sumT <- agT + ctT + dOST + dDT
    gapT <- totT - (sumT + uxT)
    list(agree = agT, docAbsent = ctT + dOST, tolBounded = dDT, unexplained = uxT,
         total = totT, gap = gapT, balances = gapT == 0)
}
cat("\n--- the balance invariant, per study (each study's own compared + documented-absent + tolerance-bounded = total) ---\n")
studyBal <- list()
for (tn in c("options", "sweep")) {
    b <- studySubBalance(tn); studyBal[[tn]] <- b
    cat(sprintf("  %-8s compared=%-6d documented-absent=%-6d tolerance-bounded=%-6d unexplained=%-6d  total=%-6d  %s\n",
                tn, b$agree, b$docAbsent, b$tolBounded, b$unexplained, b$total,
                if (b$balances) "HOLDS" else sprintf("FAILS (gap %d)", b$gap)))
}
cat(sprintf("  %-8s (no R oracle) certified-fields-expected=%-6d compared=%-6d missing-from-praat=%-6d  %s\n",
            "nist", nNistExpected, nNistCompared, nNistMissingPraat,
            if (nNistBalances) "HOLDS" else "FAILS"))
if (nNistDisagree)
    cat(sprintf("    of the %d compared, %d disagree with the certified constant beyond tolerance -- bucket NIST_DISAGREE.\n",
                nNistCompared, nNistDisagree))
allStudiesBalance <- studyBal[["options"]]$balances && studyBal[["sweep"]]$balances && nNistBalances
cat(sprintf("\n  TOTAL, all three studies: %d cells (options %d, sweep %d, nist %d) -- %s\n",
            nrow(mx), sum(mx$study == "options"), sum(mx$study == "sweep"), sum(mx$study == "nist"),
            if (allStudiesBalance) "every study's balance HOLDS" else "at least one study's balance FAILS"))

cat("\n---------------------------------------------------------\n")
if (nUnexplained == 0 && nRefuseSetFail == 0 && nStaleCells == 0 && nMissing == 0 && nViolation == 0 && kitFail == 0 && balances &&
    allStudiesBalance && nNistDisagree == 0) {
    cat("  GREEN. Every row is accounted for AND every contracted quantity arrived, across all three studies.\n")
} else {
    cat("  NOT GREEN.\n")
    if (nUnexplained)
        cat(sprintf("    %d unexplained row(s)  -- bucket UNEXPLAINED / UNMATCHED_PRAAT / UNMATCHED_R.\n", nUnexplained))
    if (nStaleCells)
        cat(sprintf("    %d stale cell_id(s) in a results file -- regenerate the file; see freshness above.\n", nStaleCells))
    if (nRefuseSetFail)
        cat(sprintf("    %d cell(s) where the declared, Praat and R refusal sets disagree -- see refusals above.\n", nRefuseSetFail))
    if (nMissing)
        cat(sprintf("    %d contracted quantit(ies) MISSING -- bucket MISSING_PRAAT / MISSING_R.\n", nMissing))
    if (nViolation)
        cat(sprintf("    %d contract violation(s) -- bucket CONTRACT_VIOLATION_*.\n", nViolation))
    if (kitFail)
        cat(sprintf("    %d standing-kit failure(s) -- see the per-procedure walk above.\n", kitFail))
    if (!balances)
        cat(sprintf("    balance invariant FAILS -- gap of %d key(s); see 'the balance invariant' above.\n",
                    abs(balanceGap)))
    if (!allStudiesBalance)
        cat("    at least one study's OWN balance invariant FAILS -- see 'the balance invariant, per study' above.\n")
    if (nNistDisagree)
        cat(sprintf("    %d nist-study value(s) disagree with the certified constant beyond tolerance -- bucket NIST_DISAGREE.\n",
                    nNistDisagree))
    cat("  See results/reconciliation.tsv.\n")
    cat("  A run that compares fewer quantities than the contract requires is not green,\n")
    cat("  however well the ones present agree.\n")
}
cat("---------------------------------------------------------\n")
cat(sprintf("full detail: %s\n", file.path(resultsDir, "reconciliation.tsv")))
cat(sprintf("this verdict: %s\n\n", .verdictPath))

})
writeLines(.emlReport, .verdictPath)
cat(.emlReport, sep = "\n")
cat("\n")

# =============================================================================
# GENERATION -- results/SUMMARY.md, coverage.md, exceptions.tsv,
# agreement_by_procedure.tsv, agreements_all.tsv, disagreements_all.tsv.
#
# Family prose comes from results_templates/reader_sentences.md, never
# string-built here (Ian's ruling, 28 Aug 2026). This block only: reads that
# file, maps each row of `out` (and, for coverage, the raw P/R tables) to the
# clause that speaks for it, and fills the numbers from the live run. A
# declared family with no matching section in reader_sentences.md is a HARD
# ERROR -- generation stops rather than printing a reason nobody wrote.
# =============================================================================

# --- 1. PARSE THE READER SENTENCES, VERBATIM -------------------------------
.readerSentencesPath <- file.path(kitDir, "results_templates", "reader_sentences.md")
.parseReaderSentences <- function(path) {
    lines <- readLines(path, warn = FALSE)
    out <- list(); cur <- NULL; buf <- character(0)
    flush <- function() {
        if (!is.null(cur)) {
            body <- paste(buf, collapse = " ")
            body <- trimws(body)
            # Drop the leading "Rows: ~N." (or "Rows: N.") sentence -- the
            # live count is filled in by the generator, never read from here.
            body <- sub("^Rows:\\s*~?[0-9,]+\\.\\s*", "", body)
            out[[cur]] <<- body
        }
    }
    for (ln in lines) {
        if (grepl("^## ", ln)) {
            flush()
            cur <- trimws(sub("^## ", "", ln))
            buf <- character(0)
        } else if (!is.null(cur) && !grepl("^---\\s*$", ln)) {
            buf <- c(buf, ln)
        }
    }
    flush()
    out
}
READER <- .parseReaderSentences(.readerSentencesPath)

# --- 2. DECLARED-ID -> CLAUSE (the seven ids DECLARED[] carries today) ------
ID_TO_CLAUSE <- c(
    "D-WILCOXEST"        = "r-shift-estimate",
    "D-PTUKEY"           = "tukey-tail-quadrature",
    "D-PTUKEY-MID"       = "tukey-tail-quadrature",
    "D-TWOWAY-PRECISION" = "two-way-precision",
    "D-WORDING"          = "refusal-wording",
    "D-ALPHA2ITEM"       = "alpha-two-item-scale",
    "D-ALPHADROP"        = "alpha-three-person-sample"
)

# --- 3. CONTRACT (procedure, quantity) -> CLAUSE ----------------------------
# Keyed by the procedure and quantity pattern that identifies a contract row
# in quantities.tsv, per reader_sentences.md's own header note: "contract
# clauses key by the procedure and quantity pattern... because every
# contract row shares the single id CONTRACT." Matched in order; first hit
# wins. `bucketExclude`, where set, keeps a rule from claiming a row that
# belongs to a DIFFERENT one-sided story sharing the same quantity name (the
# Scheffe posthoc CI, PRAAT-side-only, is not the same story as the
# Holm/BH-vs-Bonferroni interval scope, even though both are named
# posthoc_<PAIR>_ci_low on the same procedure).
CONTRACT_CLAUSE_RULES <- list(
    list(proc = "emlRunAnovaAnalysis",  re = "^posthoc_.*_q$",              clause = "studentised-range-statistic"),
    list(proc = "emlRunKruskalWallisAnalysis",     re = "^eta_squared$",               clause = "rank-test-effect-size"),
    list(proc = c("emlRunNormalityAnalysis", "emlRunDescriptiveAnalysis"),
                                         re = "^(skewness_b1|kurtosis_b2)$", clause = "extra-shape-statistics"),
    list(proc = "emlRunCorrelationAnalysis", re = "^spearman_(t|df|s)$",    clause = "correlation-intermediates"),
    list(proc = "emlRunCorrelationAnalysis", re = "^spearman_p$",           clause = "spearman-p-naming"),
    list(proc = "emlRunRepeatedMeasuresAnalysis", re = "^gg_(epsilon|p)$",  clause = "sphericity-correction"),
    list(proc = "emlRunPairedAnalysis", re = "^n_excluded$",                clause = "paired-excluded-rows"),
    list(proc = "emlRunTwoGroupAnalysis", re = "^wilcox_r$",                clause = "rosenthal-r"),
    list(proc = "emlRunPairedAnalysis", re = "^wilcox_r$",                  clause = "second-rank-effect-size"),
    list(proc = "emlChiSquareIndependence", re = "^cramers_v_(yates|bias_corrected)$", clause = "cramers-v-corrected"),
    list(proc = "emlRunFriedmanAnalysis", re = "^posthoc_.*_ci_(low|high)$", clause = "hl-interval-scope"),
    list(proc = "emlRunPairwiseAnalysis", re = "^posthoc_.*_ci_(low|high)$", clause = "pairwise-interval-scope",
         bucketExclude = "^CONTRACT_ONLY_PRAAT$"),   # excludes the Scheffe-arm CI -- see the collision note below
    list(proc = "emlRunPairwiseAnalysis", re = "^posthoc_.*_padj_ptt$",    clause = "pairwise-oracle-cross-check"),
    list(proc = "emlRunPairedAnalysis", re = "^(t|df|cohens_dz)$",          clause = "paired-parametric-absent"),
    list(proc = "emlRunFriedmanAnalysis", re = "^kendalls_w$",              clause = "kendalls-w-derived"),
    list(proc = "emlRunFriedmanAnalysis", re = "^(chi_square|p)$",          clause = "friedman-all-identical"),
    list(proc = "emlRunTwoWayAnalysis", re = "_eta_squared$",               clause = "two-way-eta-squared-gap"),
    list(proc = "emlRunGroupedRegressionAnalysis", re = "^overall_adj_r_squared$",  clause = "grouped-regression-adjusted-r2"),
    list(proc = "emlRunDescriptiveAnalysis", re = "^ci_(low|high)$",        clause = "constant-column-mean-interval"),
    list(proc = "emlCronbachAlpha",     re = "^alpha_if_deleted_",          clause = "alpha-two-item-scale")
)

# --- 4. THE LOOKUP, AND THE HARD ERROR --------------------------------------
.missingClauses <- list()
readerClauseFor <- function(bucket, id, procedure, quantity, study) {
    if (nzchar(id) && id != "CONTRACT") {
        cl <- unname(ID_TO_CLAUSE[id])
        if (is.na(cl) || !length(cl)) return(NA_character_)
        return(cl)
    }
    if (!identical(id, "CONTRACT")) return(NA_character_)   # UNEXPLAINED / UNMATCHED_* -- not a documented clause
    bq <- sub("_undefined$", "", quantity)
    for (r in CONTRACT_CLAUSE_RULES) {
        if (!is.null(r$proc) && !(procedure %in% r$proc)) next
        if (!grepl(r$re, bq)) next
        if (!is.null(r$bucketExclude) && grepl(r$bucketExclude, bucket)) next
        return(r$clause)
    }
    # THE SWEEP/NIST FALLBACK. No CONTRACT_CLAUSE_RULES entry names every one
    # of the sweep grid's own ANOVA/Kruskal-Wallis quantities individually --
    # there is no per-quantity story to tell, because the cause is the same
    # for all of them (the plugin side of that cell was not run in this
    # pass, not a per-quantity difference) -- and the nist study carries no
    # contract at all (mxContract's own comment). A CONTRACT_MISSING_PARTNER
    # row on either study still needs a reader sentence before generation can
    # proceed; the honest one is the study's own, not an invented
    # per-quantity one.
    if (identical(bucket, "CONTRACT_MISSING_PARTNER") && study %in% c("sweep", "nist"))
        return(study)
    NA_character_
}

if (nrow(out)) {
    out$procedure <- unname(procOf[out$cell_id])
    out$clause <- mapply(readerClauseFor, out$bucket, out$id, out$procedure, out$quantity, out$study)
    docBuckets <- c("DECLARED", "DECLARED_ONLY_PRAAT", "DECLARED_ONLY_R",
                     "CONTRACT_ONLY_PRAAT", "CONTRACT_ONLY_R", "CONTRACT_UNDEFINED",
                     "CONTRACT_MISSING_PARTNER")
    isDoc <- out$bucket %in% docBuckets
    missIdx <- which(isDoc & is.na(out$clause))
    if (length(missIdx)) {
        miss <- unique(data.frame(bucket = out$bucket[missIdx], id = out$id[missIdx],
                                   procedure = out$procedure[missIdx], quantity = sub("_undefined$", "", out$quantity[missIdx])))
        stop(sprintf(paste0(
            "GENERATION HARD ERROR: %d documented row(s) match no reader sentence in\n",
            "results_templates/reader_sentences.md. Every declared family (a DECLARED[]\n",
            "id, or a CONTRACT procedure+quantity pattern) needs a clause there before\n",
            "generation can write results/. Unmapped (procedure, quantity, bucket):\n\n%s\n"),
            nrow(miss),
            paste(sprintf("  %-32s %-40s %s", miss$procedure, miss$quantity, miss$bucket), collapse = "\n")),
            call. = FALSE)
    }
    # NOT ifelse(is.na(out$clause), "", unlist(READER[out$clause])): subsetting
    # a list by a character vector containing NA yields NULL at those
    # positions, and unlist() SILENTLY DROPS NULL entries rather than keeping
    # a placeholder -- shortening the vector so ifelse's recycling shifts
    # every reader sentence after the first NA onto the wrong row. Found by
    # the generate-then-verify leg (28 Aug 2026, item 8) exactly as designed:
    # a fresh disk re-count of disagreements_all.tsv's reason column disagreed
    # with the family counts SUMMARY.md's own bullets stated.
    out$reader <- vapply(out$clause, function(cl) if (is.na(cl)) "" else unname(READER[[cl]]), character(1))
} else {
    out$procedure <- character(); out$clause <- character(); out$reader <- character()
}

# --- 5. SMALL SHARED HELPERS -------------------------------------------------
tsvWrite <- function(df, name) write.table(df, file.path(resultsDir, name),
                                            sep = "\t", quote = FALSE, row.names = FALSE, na = "")
relDiff <- function(a, b) {
    a <- num(a); b <- num(b)
    ifelse(is.na(a) | is.na(b), NA_real_,
           ifelse(pmax(abs(a), abs(b)) < 1e-12, 0, abs(a - b) / pmax(abs(a), abs(b))))
}
# A readable procedure label, derived mechanically from the @eml identifier
# (no hand-maintained map): strip the "eml"/"Run" scaffolding, split the
# remaining CamelCase into words. Coarser than a hand-written label, but it
# cannot drift, because there is nothing to keep in sync.
humanProc <- function(p) {
    s <- sub("^emlRun", "", p); s <- sub("^eml", "", s)
    s <- gsub("([a-z0-9])([A-Z])", "\\1 \\2", s)
    s <- gsub("([A-Z]+)([A-Z][a-z])", "\\1 \\2", s)
    trimws(s)
}
# No package needed for this either (compare.R's own promise): a small
# title-caser in place of tools::toTitleCase.
titleCase <- function(s) {
    w <- strsplit(s, " ")[[1]]
    w <- ifelse(nchar(w) > 0, paste0(toupper(substr(w, 1, 1)), substr(w, 2, nchar(w))), w)
    paste(w, collapse = " ")
}

# --- 6. exceptions.tsv -- the numeric DECLARED-diff rows, in full ----------
excIdx <- which(out$bucket == "DECLARED" & !is.na(num(out$praat)) & !is.na(num(out$r)))
EXC <- data.frame(
    analysis = out$cell_id[excIdx], quantity = out$quantity[excIdx],
    plugin_value = out$praat[excIdx], r_value = out$r[excIdx],
    relative_difference = sprintf("%.2e", relDiff(out$praat[excIdx], out$r[excIdx])),
    reason = out$reader[excIdx], study = out$study[excIdx])
EXC <- EXC[order(EXC$analysis, EXC$quantity), ]
tsvWrite(EXC, "exceptions.tsv")

# --- 6b. refusals.tsv -- matched refusals reported as EVIDENCE, not silence.
# exceptions.tsv's columns (analysis/quantity/plugin_value/r_value/
# relative_difference) are shaped for a NUMERIC disagreement on one quantity;
# a matched refusal is a per-CELL fact (declared, Praat and R all agree the
# cell cannot be analysed) with two prose reasons, not two numbers, so it
# gets its own file rather than a numeric column stretched to fit. One row
# per cell in matchedRefuse (declared expect=refuse, and both sides actually
# refused -- the refusal assertion above, restated as evidence a reader can
# see rather than a count they have to trust). The wording itself is
# EXPECTED to differ (D-WORDING); the `reason` column carries that same
# reader sentence, reused verbatim rather than invented, so this file needs
# no new entry in reader_sentences.md.
reasonP <- setNames(P$value[P$quantity == "refuse_reason"], P$cell_id[P$quantity == "refuse_reason"])
reasonR <- setNames(R$value[R$quantity == "refuse_reason"], R$cell_id[R$quantity == "refuse_reason"])
expectOf <- setNames(mx$expect, mx$cell_id)
datasetOf <- setNames(mx$dataset, mx$cell_id)
REF <- data.frame(
    cell_id            = matchedRefuse,
    procedure           = unname(procOf[matchedRefuse]),
    dataset             = unname(datasetOf[matchedRefuse]),
    declared_expect     = unname(expectOf[matchedRefuse]),
    praat_refused       = "yes",
    r_refused           = "yes",
    praat_reason        = unname(reasonP[matchedRefuse]),
    r_reason            = unname(reasonR[matchedRefuse]),
    reason              = READER[["refusal-wording"]],
    study               = unname(studyOf[matchedRefuse]),
    stringsAsFactors = FALSE)
REF <- REF[order(REF$cell_id), ]
tsvWrite(REF, "refusals.tsv")

# --- 7. disagreements_all.tsv -- every non-agreement, in full --------------
kindOf <- function(bucket, id) {
    ifelse(bucket == "DECLARED" & id == "D-WORDING", "wording differs (both refuse)",
    ifelse(bucket == "DECLARED", "values differ (documented)",
    ifelse(bucket %in% c("CONTRACT_ONLY_PRAAT", "DECLARED_ONLY_PRAAT"), "reported by plugin only (documented)",
    ifelse(bucket %in% c("CONTRACT_ONLY_R", "DECLARED_ONLY_R"), "reported by R only (documented)",
    ifelse(bucket == "CONTRACT_UNDEFINED", "undefined marker, one side (documented)",
    ifelse(bucket == "CONTRACT_MISSING_PARTNER", "both sides: no value defined (documented)",
    ifelse(bucket == "NIST_DISAGREE", "differs from the NIST certified value beyond tolerance",
    ifelse(bucket == "NIST_MISSING_PRAAT", "certified field not reported by the plugin",
    "NOT DOCUMENTED -- see enforcement/why in reconciliation.tsv"))))))))
}
DIS <- data.frame(
    analysis = out$cell_id, quantity = out$quantity,
    plugin_value = out$praat, r_value = out$r,
    relative_difference = ifelse(!is.na(num(out$praat)) & !is.na(num(out$r)),
                                  sprintf("%.2e", relDiff(out$praat, out$r)), ""),
    kind = kindOf(out$bucket, out$id),
    reason = out$reader, study = out$study)
DIS <- DIS[order(DIS$analysis, DIS$quantity), ]
tsvWrite(DIS, "disagreements_all.tsv")

# --- 8. agreements_all.tsv -- every plain agreement, in full ---------------
# No worked example covered this file; its schema mirrors disagreements_all.tsv
# minus the columns an agreement has no use for (kind, reason -- an agreement
# needs no documentation).
AGR <- if (length(agreeRows)) {
    a <- do.call(rbind, lapply(agreeRows, function(r) as.data.frame(r, stringsAsFactors = FALSE)))
    data.frame(analysis = a$cell_id, quantity = a$quantity,
               plugin_value = a$praat, r_value = a$r,
               relative_difference = ifelse(!is.na(num(a$praat)) & !is.na(num(a$r)),
                                             sprintf("%.2e", relDiff(a$praat, a$r)), ""))
} else data.frame(analysis = character(), quantity = character(), plugin_value = character(),
                   r_value = character(), relative_difference = character())
AGR <- AGR[order(AGR$analysis, AGR$quantity), ]
tsvWrite(AGR, "agreements_all.tsv")

# --- 9. agreement_by_procedure.tsv ------------------------------------------
# `quantities_compared` = agreeing + differing_documented + any unexplained
# both-sides mismatch (there is none in a green run, but an ongoing one must
# still show up in the denominator, not vanish from it).
oneSidedDocBuckets <- c("CONTRACT_ONLY_PRAAT", "CONTRACT_ONLY_R", "CONTRACT_UNDEFINED",
                         "CONTRACT_MISSING_PARTNER", "DECLARED_ONLY_PRAAT", "DECLARED_ONLY_R")
agreeCellId <- vapply(agreeRows, function(r) r$cell_id, "")
agreeProc <- unname(procOf[agreeCellId])
mxPosthoc <- setNames(if ("posthoc" %in% names(mx)) mx$posthoc else rep("", nrow(mx)), mx$cell_id)
nistAgreeCellId <- vapply(nistAgreeRows, function(r) r$cell_id, "")
buildAgreementRow <- function(procName, cellSet, posthocLabel, studyLabel) {
    # The nist study has no DECLARED/CONTRACT bucket -- NIST_DISAGREE and
    # NIST_MISSING_PRAAT stand in for "differing" and "one-sided" there, so a
    # (procedure, study) row reads the same shape whichever study it is.
    isNist <- identical(studyLabel, "nist")
    nAgr  <- if (isNist) sum(nistAgreeCellId %in% cellSet) else sum(agreeProc == procName & agreeCellId %in% cellSet)
    nDiff <- sum(out$bucket %in% c("DECLARED", "NIST_DISAGREE") & out$procedure == procName & out$cell_id %in% cellSet)
    nUnex <- sum(out$bucket == "UNEXPLAINED" & out$procedure == procName & out$cell_id %in% cellSet)
    nOne  <- sum(out$bucket %in% c(oneSidedDocBuckets, "NIST_MISSING_PRAAT") & out$procedure == procName & out$cell_id %in% cellSet)
    nComp <- nAgr + nDiff + nUnex
    data.frame(procedure = humanProc(procName), post_hoc = posthocLabel,
               quantities_compared = nComp, agreeing = nAgr, differing_documented = nDiff,
               one_sided_documented = nOne,
               percent_agreement_of_compared = if (nComp) sprintf("%.2f%%", 100 * nAgr / nComp) else "n/a",
               study = studyLabel)
}
ABP <- list()
for (procName in sort(unique(mx$procedure))) {
    for (studyLabel in sort(unique(mx$study[mx$procedure == procName]))) {
        cellsAll <- mx$cell_id[mx$procedure == procName & mx$study == studyLabel]
        ABP[[length(ABP) + 1]] <- buildAgreementRow(procName, cellsAll, "", studyLabel)
        ph <- mxPosthoc[cellsAll]
        for (v in sort(unique(ph[nzchar(ph)]))) {
            ABP[[length(ABP) + 1]] <- buildAgreementRow(procName, cellsAll[ph == v], v, studyLabel)
        }
    }
}
ABP <- do.call(rbind, ABP)
tsvWrite(ABP, "agreement_by_procedure.tsv")

# --- 10. coverage.md -- derived from the run, no fixture --------------------
# Procedures and options: matrix.tsv. The R-function column: the distinct
# `source` values observed on that procedure's R rows -- never a hand-
# maintained map (Ian's ruling, 28 Aug 2026; docs/QUESTIONS_FOR_FABLE_OPEN_
# 2026-08-27.md, question 2/3/5). This is the "cheaper middle": the R side
# names the specific function; the Praat side (task 3) names only the
# procedure, so it contributes nothing new here beyond what "Praat procedure"
# already shows -- a known, disclosed coarseness, not an oversight.
optionCols <- setdiff(names(mx), c("cell_id", "lane", "procedure", "dataset", "col_a", "col_b", "col_c",
                                    "prereq", "expect", "note", "study"))
covLines <- c("# What the kit tests, procedure by procedure", "",
              "One row per plugin procedure: the Praat procedure name, the R functions",
              "the kit compares it against, the options the live run exercises, and how",
              "many analyses cover it. Option lists and analysis counts come from",
              "`matrix.tsv`; the R functions are the distinct `source` values this run's",
              "`audit/r_results.tsv` recorded for that procedure's cells -- not a",
              "hand-maintained map, so a procedure that stops calling a function stops",
              "listing it here on the next run.", "",
              "| Procedure | Praat procedure | Compared against (R functions) | Options exercised | Analyses |",
              "|---|---|---|---|---|")
for (procName in sort(unique(mx$procedure))) {
    cells <- mx$cell_id[mx$procedure == procName]
    rFuncs <- sort(unique(R$source[R$cell_id %in% cells]))
    optParts <- character(0)
    for (oc in optionCols) {
        vals <- unique(mx[[oc]][mx$cell_id %in% cells])
        vals <- vals[nzchar(vals)]
        if (length(vals) > 1) optParts <- c(optParts, sprintf("%s: %s", oc, paste(sort(vals), collapse = ", ")))
    }
    optTxt <- if (length(optParts)) paste(optParts, collapse = "; ") else "—"
    covLines <- c(covLines, sprintf("| %s | `@%s` | %s | %s | %d |",
        humanProc(procName), procName,
        paste(sprintf("`%s`", rFuncs), collapse = ", "), optTxt, length(cells)))
}
covLines <- c(covLines, "", sprintf(
    "Totals: %d procedures, %d analyses. Each analysis contributes every",
    length(unique(mx$procedure)), nrow(mx)))
covLines <- c(covLines, sprintf(
    "quantity both programs report; the live run compared %d quantities.", nCompared))
writeLines(covLines, file.path(resultsDir, "coverage.md"))

# --- 11. SUMMARY.md ----------------------------------------------------------
# Prose per family is the reader sentence, verbatim; only the counts and
# worst-case numbers are filled from the run. Same rule for the three study
# sections below: their prose comes from results_templates/study_sections.md,
# never string-built here (Ian's ruling, docs/MEMO_TO_FABLE_TIERS_2026-08-28.md).
famCounts <- if (nrow(out)) sort(table(out$clause[!is.na(out$clause)]), decreasing = TRUE) else integer(0)
overallGreen <- nUnexplained == 0 && nRefuseSetFail == 0 && nStaleCells == 0 && nMissing == 0 && nViolation == 0 && balances &&
    allStudiesBalance && nNistDisagree == 0
sumLines <- c(sprintf("# Validation summary — EML Stats & Graphs against R"), "",
    sprintf("Run %s. Verdict: **%s**.", format(Sys.Date(), "%d %B %Y"),
            if (overallGreen)
                "green — every quantity accounted for, across all three studies" else "NOT GREEN — see results/reconciliation.tsv"),
    "",
    "## What was compared", "",
    # nrow(mxContract), not nrow(mx): this sentence is specifically about the
    # options + sweep studies, the two run through BOTH Praat and R -- the nist
    # study (no R oracle) gets its own section below, with its own count.
    sprintf("The kit ran %d analyses through %d of the plugin's statistical procedures (the options and sweep studies), and ran the same %d analyses in R. It then compared %d numerical results.",
            nrow(mxContract), length(unique(mxContract$procedure)), nrow(mxContract), nCompared),
    "",
    sprintf("**%d of %d agree** to at least nine significant digits (values at machine zero are compared absolutely, below 1e-12). The rest are listed in full in `exceptions.tsv` and `disagreements_all.tsv`, one row each, with the reason beside the numbers. There are no unexplained differences: an accounting identity inside the comparison proves every quantity from both programs landed in exactly one category (the balance invariant in `audit/VERDICT.txt`), and the run fails loudly if one ever doesn't.",
            nAgree, nCompared),
    "",
    "## The documented differences, in plain terms", "")
for (nm in names(famCounts)) {
    txt <- READER[[nm]]
    if (is.null(txt)) next
    title <- titleCase(gsub("-", " ", nm))
    sumLines <- c(sumLines, sprintf("**%s (%d).** %s", title, famCounts[[nm]], txt), "")
}

# --- 11b. THREE STUDIES, ONE SECTION EACH ------------------------------------
.studySecPath <- file.path(kitDir, "results_templates", "study_sections.md")
STUDYSEC <- .parseReaderSentences(.studySecPath)
agreeStudyVec <- unname(studyOf[agreeCellId])
nCompStudy  <- function(tn) sum(agreeStudyVec %in% tn) +
    sum(out$bucket == "DECLARED" & out$study %in% tn) + sum(out$bucket == "UNEXPLAINED" & out$study %in% tn)
nAgreeStudy <- function(tn) sum(agreeStudyVec %in% tn)
studySection <- function(studyName, title, nCells) {
    txt <- STUDYSEC[[studyName]]
    if (is.null(txt))
        stop(sprintf(paste0(
            "GENERATION HARD ERROR: no '## %s' section in ",
            "results_templates/study_sections.md -- every study needs its question ",
            "and oracle stated there before generation can write SUMMARY.md."),
            studyName), call. = FALSE)
    countLine <- if (identical(studyName, "nist"))
        sprintf("**Count.** %d cells, %d certified fields compared, %d agree, %d disagree beyond tolerance.",
                nCells, nNistCompared, nNistAgree, nNistDisagree)
    else
        sprintf("**Count.** %d cells, %d numerical comparisons, %d agree.",
                nCells, nCompStudy(studyName), nAgreeStudy(studyName))
    c(sprintf("### %s", title), "", txt, "", countLine, "")
}
sumLines <- c(sumLines, "## The three studies", "",
    "Three bodies of evidence, three different questions, one verdict: green requires all three fully accounted for (the balance invariant in `audit/VERDICT.txt`, run per study and in total).", "",
    studySection("options", "The options study", sum(mx$study == "options")),
    studySection("sweep",   "The sweep study",   sum(mx$study == "sweep")),
    studySection("nist",    "The NIST study",    sum(mx$study == "nist")))

sumLines <- c(sumLines, "## Run it yourself", "",
    "1. Open `RUN_ME_FIRST.praat` in Praat and run it.",
    "2. Source `run_analyses.R` in R.",
    "3. Source `compare.R`. It prints this verdict and rewrites this folder.", "",
    "The full row-by-row working record, including the two raw result tables",
    "and `VERDICT.txt`, is in `audit/`; every per-analysis report from both",
    "programs is in `results/praat_reports/` and `results/r_reports/`.")
writeLines(sumLines, file.path(resultsDir, "SUMMARY.md"))

cat(sprintf("\ncompare.R: generation wrote SUMMARY.md, coverage.md, exceptions.tsv (%d rows),\n", nrow(EXC)))
cat(sprintf("  refusals.tsv (%d rows), agreement_by_procedure.tsv (%d rows), agreements_all.tsv (%d rows),\n",
            nrow(REF), nrow(ABP), nrow(AGR)))
cat(sprintf("  disagreements_all.tsv (%d rows) to %s\n", nrow(DIS), resultsDir))

# =============================================================================
# VALIDATE LEG 1 -- READER-SENTENCE MEMBERSHIP (ruled 28 Aug 2026, item 6).
# Replaces vocabulary matching for reason columns: a reason string in a
# results/ file is not scanned for suspicious words (that check passed
# "DOCUMENTED ABSENCE, R-side, under the definition-over-implementation
# rule..." because it contains none of a short word list -- see
# docs/QUESTIONS_FOR_FABLE_OPEN_2026-08-27.md, item 1). Instead every reason
# string is checked, byte for byte, against the sentences READER[] parsed
# out of results_templates/reader_sentences.md -- the exact set generation
# draws from. Anything else is red, no matter what words it does or does not
# contain.
# =============================================================================
readerSentenceSet <- unique(unname(unlist(READER)))

# What "the reason string" is, per file kind:
#   - a .tsv with a "reason" column: every distinct non-empty cell in it
#   - SUMMARY.md: the prose that follows each "**Title (N).** " family bullet
extractReasonStrings <- function(path) {
    if (grepl("\\.tsv$", path)) {
        d <- utils::read.delim(path, sep = "\t", colClasses = "character",
                                quote = "", na.strings = NULL, check.names = FALSE)
        if (!"reason" %in% names(d)) return(character(0))
        unique(d$reason[nzchar(d$reason)])
    } else {
        lines <- readLines(path, warn = FALSE)
        hit <- grep("^\\*\\*.+\\([0-9]+\\)\\.\\*\\* ", lines, value = TRUE)
        unique(sub("^\\*\\*.+\\([0-9]+\\)\\.\\*\\* ", "", hit))
    }
}
checkReasonMembership <- function(files) {
    bad <- list()
    for (f in files) {
        if (!file.exists(f)) next
        for (r in extractReasonStrings(f)) {
            if (!(r %in% readerSentenceSet))
                bad[[length(bad) + 1]] <- list(file = basename(f), reason = r)
        }
    }
    bad
}
.membershipFiles <- file.path(resultsDir, c("exceptions.tsv", "refusals.tsv", "disagreements_all.tsv", "SUMMARY.md"))
.membershipBad <- checkReasonMembership(.membershipFiles)
if (length(.membershipBad)) {
    cat("\n--- READER-SENTENCE MEMBERSHIP: RED ---\n")
    for (b in .membershipBad) cat(sprintf("  %s: %s\n", b$file, substr(b$reason, 1, 100)))
    stop(sprintf(
        "READER-SENTENCE MEMBERSHIP: %d reason string(s) do not byte-match a sentence in results_templates/reader_sentences.md.",
        length(.membershipBad)), call. = FALSE)
} else {
    cat(sprintf(
        "\nREADER-SENTENCE MEMBERSHIP: PASS -- every reason string in exceptions.tsv, refusals.tsv,\n  disagreements_all.tsv and SUMMARY.md byte-matches a sentence in results_templates/reader_sentences.md.\n"))
}

# =============================================================================
# VALIDATE LEG 2 -- GENERATE-THEN-VERIFY (ruled 28 Aug 2026, item 8). Re-read
# every file this run wrote OFF DISK -- not the in-memory `out`/`agreeRows`
# that built them -- and re-derive SUMMARY.md's filled numbers independently:
# agree count, family counts, and the three bounded DECLARED worst cases. The
# presentation can never drift from what was actually measured and written;
# if it does, this leg is what catches it.
# =============================================================================
.reread <- function(name, dir = resultsDir) utils::read.delim(file.path(dir, name), sep = "\t",
    colClasses = "character", quote = "", na.strings = NULL, check.names = FALSE)
.diskAgreeN   <- nrow(.reread("agreements_all.tsv"))
.diskDis      <- .reread("disagreements_all.tsv")
# "compared" means both sides had a value to compare: agreements, plus the
# both-sides-present DECLARED rows, numeric ("values differ (documented)")
# or textual ("wording differs (both refuse)"). disagreements_all.tsv also
# carries one-sided CONTRACT/DECLARED rows and UNMATCHED/UNEXPLAINED rows
# that were never a value-vs-value comparison at all -- those must not be
# added (cross-checked against nCompared itself: 10792 + 34 + 15 = 10841).
.diskCompared <- .diskAgreeN + sum(.diskDis$kind %in%
    c("values differ (documented)", "wording differs (both refuse)"))
.summaryTxt   <- readLines(file.path(resultsDir, "SUMMARY.md"), warn = FALSE)
.gtv <- character(0)

# 1. agree / compared, re-tallied from the two files actually written.
if (!any(grepl(sprintf("**%d of %d agree**", .diskAgreeN, .diskCompared), .summaryTxt, fixed = TRUE)))
    .gtv <- c(.gtv, sprintf(
        "agree/compared: SUMMARY.md does not state %d of %d, the fresh disk re-count from agreements_all.tsv + disagreements_all.tsv",
        .diskAgreeN, .diskCompared))

# 2. family counts, re-tallied straight from disagreements_all.tsv's own reason column.
.diskFamCounts <- table(.diskDis$reason[nzchar(.diskDis$reason)])
for (nm in names(READER)) {
    n <- unname(.diskFamCounts[READER[[nm]]])
    if (is.na(n)) next   # zero disk rows for this clause this run -- nothing to assert
    title <- titleCase(gsub("-", " ", nm))
    if (!any(grepl(sprintf("**%s (%d).**", title, n), .summaryTxt, fixed = TRUE)))
        .gtv <- c(.gtv, sprintf(
            "family '%s': disk re-count of disagreements_all.tsv gives %d, not stated verbatim in SUMMARY.md", nm, n))
}

# 3. worst cases: the bounded DECLARED rules, re-derived from reconciliation.tsv
#    on disk and cross-checked against the HOLDS/EXCEEDED line audit/VERDICT.txt
#    already printed earlier in this same run.
.diskRecon  <- .reread("reconciliation.tsv")
.verdictTxt <- readLines(.verdictPath, warn = FALSE)
for (rule in DECLARED) {
    if (is.null(rule$maxrel)) next
    rr <- .diskRecon[.diskRecon$id == rule$id, ]
    if (!nrow(rr)) next
    worst <- suppressWarnings(max(relDiff(rr$praat, rr$r), na.rm = TRUE))
    if (!is.finite(worst)) next
    freshVerdict <- if (worst <= rule$maxrel) "HOLDS" else "EXCEEDED"
    expectLine <- sprintf("%s bound: observed max relative difference %.3g, declared limit %.3g -- %s",
                          rule$id, worst, rule$maxrel, freshVerdict)
    if (!any(grepl(expectLine, .verdictTxt, fixed = TRUE)))
        .gtv <- c(.gtv, sprintf(
            "%s: disk re-derivation gives \"%s\", not a line audit/VERDICT.txt printed", rule$id, expectLine))
}

if (length(.gtv)) {
    cat("\n--- GENERATE-THEN-VERIFY: RED ---\n")
    cat(paste0("  ", .gtv, collapse = "\n"), "\n")
    stop(sprintf(
        "GENERATE-THEN-VERIFY: %d mismatch(es) between the generated files and a fresh re-derivation from disk.",
        length(.gtv)), call. = FALSE)
} else {
    cat(sprintf(
        "GENERATE-THEN-VERIFY: PASS -- agree count, %d family count(s) and %d bounded worst-case(s) all match a fresh re-read from disk.\n",
        length(names(READER)), sum(vapply(DECLARED, function(r) !is.null(r$maxrel), logical(1)))))
}

# =============================================================================
# VALIDATE LEG 3 -- WORDLIST, SECOND NET (ruled 28 Aug 2026, item 7). Applies
# only to the prose documents (SUMMARY.md, coverage.md, README.md) -- leg 1
# above already pins every reason string in the .tsv files and in SUMMARY.md's
# family bullets to a committed sentence; this net exists for prose that leg
# 1 does not reach (README.md is hand-written, never built from READER[]) and
# for anything that could slip into SUMMARY.md/coverage.md outside a family
# bullet. Committed fixture, widened per Fable's answer to
# docs/QUESTIONS_FOR_FABLE_OPEN_2026-08-27.md item 1 beyond the two literal
# words the original list caught.
#
# COLLISION (found running this leg against the real files, not decided --
# see the final report): this fixture, applied literally to all three named
# files, is permanently red against CURRENT content that task 5 and the
# kit's own README require to exist. coverage.md's "Praat procedure" column
# is SPECIFIED (worked example, fable-handoff-2026-08-27/coverage.md) to
# read `@emlRunDescriptiveAnalysis` etc. -- exactly what /@eml\w+/ exists to
# catch. And README.md's own job, unlike SUMMARY.md's, is to teach a
# technical reader what DECLARED/enforcement/D-PTUKEY mean -- it uses this
# vocabulary in real prose sentences, not as a leaked working-paper voice.
# Implemented here exactly as specified, un-narrowed, so the collision is
# visible rather than quietly designed around.
# =============================================================================
WORDLIST_LITERALS <- c("bucket", "enforcement", "DECLARED", "CONTRACT",
                        "vmax", "vmin", "maxrel", "quantities.tsv")
WORDLIST_PATTERNS <- c("@eml\\w+", "D-[A-Z]")

# ENUMERATED EXEMPTIONS. Each names one file and one pattern, with its reason.
# Never a broadened regex: widening a pattern deletes the rule everywhere,
# while an entry here is scoped, visible, and reported when it stops matching.
# Rule-scope defect on Fable's side, fixed 28 August 2026 by narrowing rather
# than by suppressing hits.
WORDLIST_EXEMPT <- list(
    list(file = "coverage.md", pattern = "@eml\\w+",
         why = paste("coverage.md's identifier column prints the Praat",
                     "procedure name by design; that column is the file's",
                     "purpose, not a leak of working-paper voice."))
)
.exemptUnused <- character(0)

checkWordlist <- function(path) {
    if (!file.exists(path)) return(character(0))
    lines <- readLines(path, warn = FALSE)
    hits <- character(0)
    for (w in WORDLIST_LITERALS) {
        m <- which(grepl(w, lines, fixed = TRUE))
        if (length(m)) hits <- c(hits, sprintf("%s: literal \"%s\" on line %d", basename(path), w, m[1]))
    }
    for (p in WORDLIST_PATTERNS) {
        ex <- Filter(function(e) identical(e$file, basename(path)) &&
                                 identical(e$pattern, p), WORDLIST_EXEMPT)
        m <- which(grepl(p, lines, perl = TRUE))
        if (length(ex)) {
            # An exemption matching nothing has outlived its need.
            if (!length(m)) .exemptUnused <<- c(.exemptUnused,
                sprintf("%s: exemption for /%s/ matched nothing", basename(path), p))
            next
        }
        if (length(m)) hits <- c(hits, sprintf("%s: pattern /%s/ on line %d", basename(path), p, m[1]))
    }
    hits
}
.wordlistFiles <- c(file.path(resultsDir, c("SUMMARY.md", "coverage.md")),
                     file.path(kitDir, "README.md"))
.wordlistHits <- unlist(lapply(.wordlistFiles, checkWordlist))
if (length(.exemptUnused)) {
    cat("\n--- WORDLIST exemptions that matched nothing ---\n")
    cat(paste0("  ", .exemptUnused, collapse = "\n"), "\n")
}
if (length(.wordlistHits)) {
    cat("\n--- WORDLIST (prose documents): RED ---\n")
    cat(paste0("  ", .wordlistHits, collapse = "\n"), "\n")
    stop(sprintf(
        "WORDLIST: %d working-paper term(s) found in a reader-facing prose document (SUMMARY.md, coverage.md or README.md).",
        length(.wordlistHits)), call. = FALSE)
} else {
    cat("WORDLIST (prose documents): PASS -- SUMMARY.md, coverage.md and README.md carry none of the working-paper vocabulary.\n")
}
