# ============================================================================
# v28_column_type_guard.R -- the column-type guard, D113; the column-presence
#                            guard, D116; the library-layer silence, D125.
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# THE DEFECT. Driven through the GUI on 7 August 2026: the two-way ANOVA
# accepted `singer` -- a column of subject identifiers, "Singer_1",
# "Singer_2" -- as the MEASUREMENT column, and printed a full ANOVA table
# with an empty error string. On the committed evidence/csv/dump_demo_twoway
# table the same input yields F = 132.92, p = 6.9e-15 for voice_type.
#
# THE MECHANISM, confirmed headlessly before anything was changed. Praat has
# two ways of reading a Table column and they disagree:
#
#   Get value: row, col            returns UNDEFINED for a text cell. Every
#                                  row-wise reader in the plugin drops those
#                                  rows, so the row-wise paths were never
#                                  wrong -- only mute about why.
#   Get all numbers in column:     numericises the column AS A WHOLE, and if
#   Report two-way anova:          any cell is not strictly numeric it
#                                  silently substitutes each row's
#                                  ALPHABETICAL RANK. "Soprano_1" .. becomes
#                                  13, 17, 18, 19, 20 ... and the ANOVA runs
#                                  on the sort order of the singers' names.
#
# So the two-way ANOVA was computing a real F on a real quantity: the
# alphabetical position of a subject identifier. Nothing downstream can tell
# that number from a sound pressure level.
#
# THE FIX under test is @emlRequireNumericColumn (stats/eml-inferential.praat),
# called by every orchestrator in stats/eml-analysis.praat that takes a column
# of measurements. It delegates the whole verdict to @emlAuditColumn, the
# classifier introduced for D96, so there is exactly one place in the plugin
# that decides what a cell is.
#
# ---------------------------------------------------------------------------
# THE MIXED-COLUMN RULING, and why it is not uniform
# ---------------------------------------------------------------------------
# A column of numbers containing SOME unusable cells DROPS-AND-DISCLOSES
# everywhere except the two-way ANOVA, where it REFUSES.
#
# Drop-and-disclose is the house convention, settled 21 July (FIX_NOTES C1/C2)
# and restated for D96 and for red-path R6 in v07: analyse the rows that
# parse, state how many were excluded and why. It is not reopened here. A
# guard that refused a 200-row column over one typo would be a worse tool
# than the one it replaced, and v07 already asserts that behaviour.
#
# The two-way ANOVA cannot honour it. Every other test reaches its data
# through a row-wise reader and can leave a row out; the two-way goes through
# Praat's `Report two-way anova:`, which numericises the whole column in one
# call. There is no per-row drop available -- one bad cell replaces all 36
# values with ranks -- so the choice there is between refusing and reporting
# a number computed from a sort order. It refuses. That asymmetry is a
# property of the mechanism, not a lapse in uniformity, and this script
# asserts BOTH halves of it so it cannot be "tidied up" in either direction
# without a failing check.
#
# Confirmed for the record: one "n/a" in row 3 of the 48-row committed
# two-way input changes Praat's reported voice_type F from a real value to
# 0.7356 on ranks. A single cell, the whole result.
#
# ---------------------------------------------------------------------------
# D116 -- THE MISSING COLUMN, and why it is in this file
# ---------------------------------------------------------------------------
# The mirror image of D113, found on 7 August 2026 by reading the r04 case
# this script had been PINNING since the day before. When the data column was
# not in the table at all, two orchestrators refused by describing what the
# absence had done to the groups:
#
#   two-group        Each group needs at least 2 observations.
#                    Group "G1": n=0, group "G2": n=0
#   Kruskal-Wallis   Group "H3" has 0 observations. Every group needs at
#                    least 1.
#
# Both true; both send the reader to inspect a grouping variable that is
# perfectly fine. D113's guard says in so many words "This is a type error,
# not missing data" precisely so a type error is not read as missing data;
# this is the same class of harm running the other way.
#
# Driving the LIBRARY layer (harness/colmissing) rather than only the twelve
# orchestrators turned up three more of the same shape and two worse ones:
#
#   @emlDunnTest     Group "H3" has 0 observations ...
#   @emlScheffe      0 observations across 3 groups leave no within-groups
#                    degrees of freedom ...          (about the design)
#   @emlPairwiseT           NOTHING. Empty error$, a matrix of undefined.
#   @emlPairwiseWilcoxon    NOTHING. Empty error$, a matrix of undefined.
#
# The last two are D113a surviving one layer below the orchestrator that was
# patched for it: yesterday's fix went into @emlRunPairwiseAnalysis, so the
# menu path refused and every script calling @emlPairwiseT directly -- the
# documented, supported use of eml-lib-stats.praat -- still got silence.
#
# THE FIX under test is @emlRequireColumnPresent (stats/eml-inferential.praat),
# which is the thirteen two-line copies of "Data column not found: " that the
# other tests already carried, collected into one procedure and then called
# by the five that carried none. The wording is unchanged, which is what
# makes the collection safe: v22 and the r04 block below assert it verbatim
# and both were written before the procedure existed.
#
# PRESENCE AND EMPTINESS ARE DIFFERENT REFUSALS, asserted separately below
# (r04 against r02, n01 against n02). A column that is not in the table and a
# column that is in the table and blank have different causes and different
# remedies -- name a different column, versus fill in the data -- and the
# plugin says so: "Data column not found: y" against 'Data column "y" holds
# no numbers. 36 cell(s) are empty (row 1 first). Treated as missing data.'
# Collapsing them would put this script back where it started, pinning a
# message that names the wrong thing.
#
# ---------------------------------------------------------------------------
# D125 -- THE SILENCE D116 LEFT, and what closing it changed here
# ---------------------------------------------------------------------------
# D116 gave @emlPairwiseT and @emlPairwiseWilcoxon a PRESENCE guard, which is
# why n01 became a refusal. It did not give them a TYPE guard, so a column
# that was in the table and entirely blank still left both with an empty
# error$ and a matrix of undefined -- and this file PINNED that, as silence,
# with a comment saying the pin should be replaced by a verbatim one the day
# someone closed it. This is that day.
#
# It was pinned rather than filed as a wrong answer because it was not one.
# No number was produced: every cell of the matrix was undefined, so nothing
# could be mistaken for a result, and the menu path could not reach it at all
# -- @emlRunPairwiseAnalysis refuses on the same table first (r02). What was
# missing was a verdict. A direct caller, which is what eml-lib-stats.praat
# exists to support, could not distinguish "this table cannot be analysed"
# from "here are your comparisons" without inspecting the matrix itself.
#
# Both now call @emlRequireNumericColumn with .strict = 0, immediately after
# the presence check, and refuse in @emlAuditColumn's words. Two consequences
# for this file, both deliberate:
#
#   - the n02 loop covers all ELEVEN sites. The SILENT_ON_EMPTY exemption
#     list is gone rather than shortened; an exemption list is what let this
#     sit here looking asserted.
#   - the refusal is pinned to the SAME string as @emlTwoWayAnova's, so the
#     three guarded tests are checked to agree with each other rather than
#     pinned three times independently.
#
# The check count is unchanged at 613: the four silence checks each of the
# two sites carried are replaced by the three n02 refusal checks the other
# nine already had, plus one verbatim pin. The green path (PART 4, g01) is
# untouched and still recomputes both pairwise tests against base R, which
# is what stops this guard from being satisfiable by refusing everything.
#
#     Rscript validate/v28_column_type_guard.R
#
# Input:  harness/coltype/out/{manifest.csv,results.csv,refusals.tsv}
#         harness/coltype/out/data/<case>.csv
#         (regenerate with harness/coltype/coltype_cases.praat)
#         Override the directory with EML_COLTYPE_DIR.
#
#         harness/colmissing/out/{manifest.csv,results.csv,refusals.tsv}
#         (regenerate with harness/colmissing/colmissing_cases.praat)
#         Override the directory with EML_COLMISSING_DIR.
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

ct_dir <- Sys.getenv("EML_COLTYPE_DIR", unset = NA)
if (is.na(ct_dir)) ct_dir <- repo_path("harness", "coltype", "out")

man <- read.csv(file.path(ct_dir, "manifest.csv"), stringsAsFactors = FALSE)
res <- read.csv(file.path(ct_dir, "results.csv"), stringsAsFactors = FALSE)
ref <- read.delim(file.path(ct_dir, "refusals.tsv"), sep = "\t",
                  quote = "", stringsAsFactors = FALSE)

# The twelve orchestrators under test, in the order they are driven.
TESTS <- c("twogroup", "anova", "kw", "pairwise", "twoway", "paired",
           "correlation", "descriptive", "regression", "normality",
           "rm", "friedman")

# ---------------------------------------------------------------------------
# Reading the long results frame. A missing row is a hard stop, not a skip:
# "the plugin did not report this" is exactly the failure a silently
# shrinking harness produces (the v22 rule).
# ---------------------------------------------------------------------------
reported <- function(case, test, stat) {
  hit <- res$value[res$case == case & res$test == test & res$statistic == stat]
  if (length(hit) != 1L)
    stop(sprintf("v28: expected exactly 1 row for %s/%s/%s, found %d",
                 case, test, stat, length(hit)))
  hit
}
has_row <- function(case, test, stat)
  any(res$case == case & res$test == test & res$statistic == stat)
refused <- function(case, test) has_row(case, test, "refused")
message_of <- function(case, test) {
  hit <- ref$error[ref$case == case & ref$test == test]
  if (length(hit) != 1L) NA_character_ else hit
}

expect_refusal <- function(case, test, expected) {
  got <- message_of(case, test)
  check_true("v28", sprintf("%s/%s refuses with the exact message", case, test),
             identical(got, expected))
  if (!identical(got, expected))
    cat(sprintf("v28 refusal mismatch %s/%s\n  expected: %s\n  got     : %s\n",
                case, test, expected,
                if (is.na(got)) "<no refusal>" else got))
}

# chk_logp -- for p-values far below 1. `check` takes an ABSOLUTE tolerance,
# and at p = 1e-43 any tolerance loose enough to absorb a last-bit difference
# (1e-12, say) also absorbs the entire value, so the check would pass against
# zero and assert nothing. Comparing log10(p) keeps a tight tolerance
# meaningful at any magnitude: 1e-9 on the log is agreement to nine
# significant figures of the exponent-and-mantissa together.
chk_logp <- function(family, what, rep_v, comp_v) {
  check_true("v28", paste(what, "is a positive p-value on both sides"),
             is.finite(rep_v) && is.finite(comp_v) && rep_v > 0 && comp_v > 0)
  chk(family, paste(what, "(log10)"), log10(rep_v), log10(comp_v), 1e-9)
}

RELERR <- new.env(parent = emptyenv()); RELERR$rows <- list()
chk <- function(family, what, rep_v, comp_v, tol) {
  if (is.finite(rep_v) && is.finite(comp_v)) {
    denom <- max(abs(comp_v), .Machine$double.xmin)
    RELERR$rows[[length(RELERR$rows) + 1L]] <-
      data.frame(family = family, rel = abs(rep_v - comp_v) / denom)
  }
  check("v28", what, rep_v, comp_v, tol = tol)
}

# ---------------------------------------------------------------------------
# Loading a case's table. Every measurement column is read as TEXT and
# converted here, so that the mixed case ("n/a" in row 3) arrives in R the
# same way it arrives in Praat -- as a literal that has to be judged.
# ---------------------------------------------------------------------------
load_case <- function(cs) {
  d <- read.csv(file.path(ct_dir, "data", paste0(cs, ".csv")),
                colClasses = "character", stringsAsFactors = FALSE)
  for (nm in c("y", "x", "c2", "c3"))
    if (nm %in% names(d)) d[[nm]] <- suppressWarnings(as.numeric(d[[nm]]))
  d$grp  <- factor(d$grp,  levels = sort(unique(d$grp)))
  d$f2   <- factor(d$f2,   levels = sort(unique(d$f2)))
  d$grp3 <- factor(d$grp3, levels = sort(unique(d$grp3)))
  d
}

# Complete-case subsets, matching what each orchestrator analyses.
ok_y   <- function(d) d[!is.na(d$y), , drop = FALSE]
ok_yx  <- function(d) d[!is.na(d$y) & !is.na(d$x), , drop = FALSE]
ok_cnd <- function(d) d[!is.na(d$y) & !is.na(d$c2) & !is.na(d$c3), ,
                        drop = FALSE]

# Welch pairwise t with Holm adjustment, in the plugin's i<j order over
# alphabetically sorted labels.
pairwise_welch_holm <- function(x, g) {
  lv <- levels(g); k <- length(lv)
  out <- NULL
  for (i in seq_len(k - 1L)) for (j in (i + 1L):k) {
    tt <- t.test(x[g == lv[i]], x[g == lv[j]], var.equal = FALSE)
    out <- rbind(out, data.frame(pair = paste0(lv[i], "-", lv[j]),
                                 t = unname(tt$statistic),
                                 p = unname(tt$p.value),
                                 stringsAsFactors = FALSE))
  }
  out$adj <- p.adjust(out$p, method = "holm")
  out
}

# ===========================================================================
# PART 1 -- THE GREEN PATH.
#
# The load-bearing half. A guard that refused everything would satisfy any
# amount of red-path assertion, so every one of the twelve orchestrators is
# driven on a clean numeric column and every statistic it produced is
# recomputed here in base R. If the guard has narrowed what the plugin will
# analyse, these fail.
# ===========================================================================

green_case <- function(cs) {
  d <- load_case(cs)
  lab <- sprintf("%s [%s]", cs, man$kind[man$case == cs])

  # --- 1. two-group, Welch --------------------------------------------------
  check_true("v28", paste(lab, "two-group ran"), !refused(cs, "twogroup"))
  if (!refused(cs, "twogroup")) {
    dd <- ok_y(d)
    a <- dd$y[dd$grp == levels(dd$grp)[1]]
    b <- dd$y[dd$grp == levels(dd$grp)[2]]
    tt <- t.test(a, b, var.equal = FALSE)
    chk("twogroup.n", paste(lab, "two-group n1"),
        reported(cs, "twogroup", "n1"), length(a), 0)
    chk("twogroup.n", paste(lab, "two-group n2"),
        reported(cs, "twogroup", "n2"), length(b), 0)
    chk("twogroup.mean", paste(lab, "two-group mean 1"),
        reported(cs, "twogroup", "mean1"), mean(a), 1e-9)
    chk("twogroup.mean", paste(lab, "two-group mean 2"),
        reported(cs, "twogroup", "mean2"), mean(b), 1e-9)
    chk("twogroup.t", paste(lab, "two-group Welch t"),
        reported(cs, "twogroup", "t"), unname(tt$statistic), 1e-9)
    chk("twogroup.df", paste(lab, "two-group Welch df"),
        reported(cs, "twogroup", "df"), unname(tt$parameter), 1e-9)
    chk("twogroup.p", paste(lab, "two-group Welch p"),
        reported(cs, "twogroup", "p.value"), tt$p.value, 1e-12)
    check_true("v28", paste(lab, "two-group printed a report"),
               reported(cs, "twogroup", "output.chars") > 0)
  }

  # --- 2. one-way ANOVA -----------------------------------------------------
  check_true("v28", paste(lab, "one-way ANOVA ran"), !refused(cs, "anova"))
  if (!refused(cs, "anova")) {
    dd <- ok_y(d)
    s <- summary(aov(y ~ grp3, data = dd))[[1]]
    chk("anova.F", paste(lab, "ANOVA F"),
        reported(cs, "anova", "statistic"), s[["F value"]][1], 1e-9)
    chk("anova.p", paste(lab, "ANOVA p"),
        reported(cs, "anova", "p.value"), s[["Pr(>F)"]][1], 1e-12)
    chk("anova.df", paste(lab, "ANOVA df1"),
        reported(cs, "anova", "df1"), s[["Df"]][1], 0)
    chk("anova.df", paste(lab, "ANOVA df2"),
        reported(cs, "anova", "df2"), s[["Df"]][2], 0)
    chk("anova.ss", paste(lab, "ANOVA SS between"),
        reported(cs, "anova", "ss.between"), s[["Sum Sq"]][1], 1e-8)
    chk("anova.ss", paste(lab, "ANOVA SS within"),
        reported(cs, "anova", "ss.within"), s[["Sum Sq"]][2], 1e-8)
    for (lv in levels(dd$grp3))
      chk("anova.n", paste(lab, "ANOVA group n", lv),
          reported(cs, "anova", paste0("n:", lv)), sum(dd$grp3 == lv), 0)
    check_true("v28", paste(lab, "one-way ANOVA printed a report"),
               reported(cs, "anova", "output.chars") > 0)
  }

  # --- 3. Kruskal-Wallis ----------------------------------------------------
  check_true("v28", paste(lab, "Kruskal-Wallis ran"), !refused(cs, "kw"))
  if (!refused(cs, "kw")) {
    dd <- ok_y(d)
    kwt <- kruskal.test(y ~ grp3, data = dd)
    chk("kw.H", paste(lab, "KW H (tie-corrected)"),
        reported(cs, "kw", "statistic"), unname(kwt$statistic), 1e-9)
    chk("kw.p", paste(lab, "KW p"),
        reported(cs, "kw", "p.value"), kwt$p.value, 1e-12)
    chk("kw.df", paste(lab, "KW df"),
        reported(cs, "kw", "df"), unname(kwt$parameter), 0)
    chk("kw.n", paste(lab, "KW N"), reported(cs, "kw", "n"), nrow(dd), 0)
    check_true("v28", paste(lab, "Kruskal-Wallis printed a report"),
               reported(cs, "kw", "output.chars") > 0)
  }

  # --- 4. pairwise Welch, Holm ---------------------------------------------
  check_true("v28", paste(lab, "pairwise ran"), !refused(cs, "pairwise"))
  if (!refused(cs, "pairwise")) {
    dd <- ok_y(d)
    pw <- pairwise_welch_holm(dd$y, dd$grp3)
    for (r in seq_len(nrow(pw))) {
      chk("pairwise.t", paste(lab, "pairwise t", pw$pair[r]),
          reported(cs, "pairwise", paste0("t:", pw$pair[r])), pw$t[r], 1e-9)
      chk("pairwise.p", paste(lab, "pairwise Holm-adjusted p", pw$pair[r]),
          reported(cs, "pairwise", paste0("adj.p.value:", pw$pair[r])),
          pw$adj[r], 1e-10)
    }
    check_true("v28", paste(lab, "pairwise printed a report"),
               reported(cs, "pairwise", "output.chars") > 0)
  }

  # --- 6. paired t ----------------------------------------------------------
  check_true("v28", paste(lab, "paired ran"), !refused(cs, "paired"))
  if (!refused(cs, "paired")) {
    dd <- ok_yx(d)
    tt <- t.test(dd$y, dd$x, paired = TRUE)
    chk("paired.n", paste(lab, "paired n"),
        reported(cs, "paired", "n"), nrow(dd), 0)
    chk("paired.n", paste(lab, "paired n excluded"),
        reported(cs, "paired", "n.excluded"), nrow(d) - nrow(dd), 0)
    chk("paired.t", paste(lab, "paired t"),
        reported(cs, "paired", "statistic"), unname(tt$statistic), 1e-8)
    chk("paired.df", paste(lab, "paired df"),
        reported(cs, "paired", "df"), unname(tt$parameter), 0)
    chk_logp("paired.p", paste(lab, "paired p"),
             reported(cs, "paired", "p.value"), tt$p.value)
    check_true("v28", paste(lab, "paired printed a report"),
               reported(cs, "paired", "output.chars") > 0)
  }

  # --- 7. correlation -------------------------------------------------------
  check_true("v28", paste(lab, "correlation ran"), !refused(cs, "correlation"))
  if (!refused(cs, "correlation")) {
    dd <- ok_yx(d)
    ctp <- cor.test(dd$y, dd$x, method = "pearson")
    chk("corr.n", paste(lab, "correlation n"),
        reported(cs, "correlation", "n"), nrow(dd), 0)
    chk("corr.n", paste(lab, "correlation n excluded"),
        reported(cs, "correlation", "n.excluded"), nrow(d) - nrow(dd), 0)
    chk("corr.r", paste(lab, "Pearson r"),
        reported(cs, "correlation", "estimate"), unname(ctp$estimate), 1e-10)
    chk("corr.p", paste(lab, "Pearson p"),
        reported(cs, "correlation", "p.value"), ctp$p.value, 1e-12)
    # Reported under its OWN name, not the Pearson one. v1.2 item 3 was the
    # bug where Spearman's rank r was printed as Pearson's; asserting rho
    # here keeps that fix honest on this path too.
    chk("corr.rho", paste(lab, "Spearman rho"),
        reported(cs, "correlation", "rho"),
        unname(cor(dd$y, dd$x, method = "spearman")), 1e-10)
    check_true("v28", paste(lab, "correlation printed a report"),
               reported(cs, "correlation", "output.chars") > 0)
  }

  # --- 8. descriptive -------------------------------------------------------
  check_true("v28", paste(lab, "descriptive ran"), !refused(cs, "descriptive"))
  if (!refused(cs, "descriptive")) {
    dd <- ok_y(d)
    chk("desc.n", paste(lab, "descriptive n"),
        reported(cs, "descriptive", "n"), nrow(dd), 0)
    chk("desc.n", paste(lab, "descriptive n excluded"),
        reported(cs, "descriptive", "n.excluded"), nrow(d) - nrow(dd), 0)
    chk("desc.mean", paste(lab, "descriptive mean"),
        reported(cs, "descriptive", "mean"), mean(dd$y), 1e-10)
    chk("desc.sd", paste(lab, "descriptive SD"),
        reported(cs, "descriptive", "sd"), sd(dd$y), 1e-10)
    chk("desc.median", paste(lab, "descriptive median"),
        reported(cs, "descriptive", "median"), median(dd$y), 1e-10)
    check_true("v28", paste(lab, "descriptive printed a report"),
               reported(cs, "descriptive", "output.chars") > 0)
  }

  # --- 9. regression --------------------------------------------------------
  check_true("v28", paste(lab, "regression ran"), !refused(cs, "regression"))
  if (!refused(cs, "regression")) {
    dd <- ok_yx(d)
    fit <- lm(y ~ x, data = dd); sm <- summary(fit)
    chk("reg.n", paste(lab, "regression n"),
        reported(cs, "regression", "n"), nrow(dd), 0)
    chk("reg.coef", paste(lab, "regression slope"),
        reported(cs, "regression", "slope"), unname(coef(fit)[2]), 1e-9)
    chk("reg.coef", paste(lab, "regression intercept"),
        reported(cs, "regression", "intercept"), unname(coef(fit)[1]), 1e-8)
    chk("reg.r2", paste(lab, "regression R-squared"),
        reported(cs, "regression", "r.squared"), sm$r.squared, 1e-10)
    chk("reg.p", paste(lab, "regression p for the slope"),
        reported(cs, "regression", "p.value"),
        unname(sm$coefficients[2, 4]), 1e-12)
    check_true("v28", paste(lab, "regression printed a report"),
               reported(cs, "regression", "output.chars") > 0)
  }

  # --- 10. normality --------------------------------------------------------
  check_true("v28", paste(lab, "normality ran"), !refused(cs, "normality"))
  if (!refused(cs, "normality")) {
    dd <- ok_y(d)
    sw <- shapiro.test(dd$y)
    chk("norm.n", paste(lab, "normality n"),
        reported(cs, "normality", "n"), nrow(dd), 0)
    # The plugin implements Shapiro-Wilk itself (Royston's approximation);
    # v15 pins it at 5e-5 against shapiro.test and the same tolerance is
    # used here, so this check cannot be the loosest thing in the suite.
    chk("norm.W", paste(lab, "Shapiro-Wilk W"),
        reported(cs, "normality", "statistic"), unname(sw$statistic), 5e-5)
    chk("norm.p", paste(lab, "Shapiro-Wilk p"),
        reported(cs, "normality", "p.value"), sw$p.value, 5e-4)
    check_true("v28", paste(lab, "normality printed a report"),
               reported(cs, "normality", "output.chars") > 0)
  }

  # --- 11. repeated measures ------------------------------------------------
  check_true("v28", paste(lab, "repeated measures ran"), !refused(cs, "rm"))
  if (!refused(cs, "rm")) {
    dd <- ok_cnd(d)
    Y <- as.matrix(dd[, c("y", "c2", "c3")])
    rr <- rm_anova(Y)
    chk("rm.n", paste(lab, "RM n"), reported(cs, "rm", "n"), nrow(Y), 0)
    chk("rm.n", paste(lab, "RM k"), reported(cs, "rm", "k"), ncol(Y), 0)
    chk("rm.n", paste(lab, "RM n excluded"),
        reported(cs, "rm", "n.excluded"), nrow(d) - nrow(Y), 0)
    chk("rm.F", paste(lab, "RM F"),
        reported(cs, "rm", "statistic"), rr$F, 1e-8)
    chk("rm.df", paste(lab, "RM df1"), reported(cs, "rm", "df1"), rr$df1, 0)
    chk("rm.df", paste(lab, "RM df2"), reported(cs, "rm", "df2"), rr$df2, 0)
    chk_logp("rm.p", paste(lab, "RM p"),
             reported(cs, "rm", "p.value"), rr$p)
    chk("rm.gg", paste(lab, "RM Greenhouse-Geisser epsilon"),
        reported(cs, "rm", "gg.epsilon"), rr$gg, 1e-9)
    check_true("v28", paste(lab, "repeated measures printed a report"),
               reported(cs, "rm", "output.chars") > 0)
  }

  # --- 12. Friedman ---------------------------------------------------------
  check_true("v28", paste(lab, "Friedman ran"), !refused(cs, "friedman"))
  if (!refused(cs, "friedman")) {
    dd <- ok_cnd(d)
    Y <- as.matrix(dd[, c("y", "c2", "c3")])
    ft <- friedman.test(Y)
    chk("fried.n", paste(lab, "Friedman n"),
        reported(cs, "friedman", "n"), nrow(Y), 0)
    chk("fried.n", paste(lab, "Friedman k"),
        reported(cs, "friedman", "k"), ncol(Y), 0)
    chk("fried.chisq", paste(lab, "Friedman chi-square"),
        reported(cs, "friedman", "statistic"), unname(ft$statistic), 1e-9)
    chk("fried.df", paste(lab, "Friedman df"),
        reported(cs, "friedman", "df"), unname(ft$parameter), 0)
    chk_logp("fried.p", paste(lab, "Friedman p"),
             reported(cs, "friedman", "p.value"), ft$p.value)
    check_true("v28", paste(lab, "Friedman printed a report"),
               reported(cs, "friedman", "output.chars") > 0)
  }
}

# --- c01: the clean numeric column ------------------------------------------
check("v28", "c01 is the 36-row design", 36,
      man$n_rows[man$case == "c01"], tol = 0)
green_case("c01")

# The two-way is checked separately, because it is the one test whose mixed
# behaviour differs and the two cases must not share a code path here either.
{
  d <- load_case("c01")
  cells <- table(d$grp, d$f2)
  check_true("v28", "c01 two-way design is 2 x 2", all(dim(cells) == c(2, 2)))
  # Balance is asserted before anything is compared: on an UNBALANCED design
  # Type I and Type III sums of squares differ and aov() would be the wrong
  # comparison. This is v11's discipline, applied here.
  check_true("v28", "c01 two-way design is balanced, 9 per cell",
             all(cells == 9))
  check_true("v28", "c01 two-way ran", !refused("c01", "twoway"))

  s <- summary(aov(y ~ grp * f2, data = d))[[1]]
  chk("twoway.ss", "c01 two-way SS grp",
      reported("c01", "twoway", "ss:A"), s[["Sum Sq"]][1], 1e-8)
  chk("twoway.ss", "c01 two-way SS f2",
      reported("c01", "twoway", "ss:B"), s[["Sum Sq"]][2], 1e-8)
  chk("twoway.ss", "c01 two-way SS interaction",
      reported("c01", "twoway", "ss:AB"), s[["Sum Sq"]][3], 1e-8)
  chk("twoway.ss", "c01 two-way SS error",
      reported("c01", "twoway", "ss.error"), s[["Sum Sq"]][4], 1e-8)
  chk("twoway.df", "c01 two-way df error",
      reported("c01", "twoway", "df.error"), s[["Df"]][4], 0)
  chk("twoway.F", "c01 two-way F grp",
      reported("c01", "twoway", "statistic:A"), s[["F value"]][1], 1e-8)
  chk("twoway.F", "c01 two-way F f2",
      reported("c01", "twoway", "statistic:B"), s[["F value"]][2], 1e-8)
  chk("twoway.F", "c01 two-way F interaction",
      reported("c01", "twoway", "statistic:AB"), s[["F value"]][3], 1e-8)
  chk("twoway.p", "c01 two-way p grp",
      reported("c01", "twoway", "p.value:A"), s[["Pr(>F)"]][1], 1e-11)
  chk("twoway.p", "c01 two-way p f2",
      reported("c01", "twoway", "p.value:B"), s[["Pr(>F)"]][2], 1e-11)
  chk("twoway.p", "c01 two-way p interaction",
      reported("c01", "twoway", "p.value:AB"), s[["Pr(>F)"]][3], 1e-11)
  check_true("v28", "c01 two-way printed a report",
             reported("c01", "twoway", "output.chars") > 0)
}

# ===========================================================================
# PART 2 -- THE MIXED COLUMN.
#
# m01 is c01 with row 3 of "y" replaced by the literal "n/a". Eleven of the
# twelve must still run, on 35 rows, and say so. The twelfth must refuse.
# ===========================================================================

{
  d0 <- load_case("c01"); dm <- load_case("m01")
  check_true("v28", "m01 differs from c01 in exactly one cell of y",
             sum(is.na(dm$y)) == 1L && sum(is.na(d0$y)) == 0L &&
             identical(dm$y[-3], d0$y[-3]))
  check_true("v28", "m01 leaves x, c2 and c3 clean, so only y can refuse",
             !any(is.na(dm$x)) && !any(is.na(dm$c2)) && !any(is.na(dm$c3)))
}

green_case("m01")

# The disclosure, not merely the survival: every path that dropped a row has
# to say it dropped one. A silent 35 is the failure this convention exists
# to prevent.
check("v28", "m01 paired discloses 1 excluded row",
      reported("m01", "paired", "n.excluded"), 1, tol = 0)
check("v28", "m01 correlation discloses 1 excluded row",
      reported("m01", "correlation", "n.excluded"), 1, tol = 0)
check("v28", "m01 descriptive discloses 1 excluded row",
      reported("m01", "descriptive", "n.excluded"), 1, tol = 0)
check("v28", "m01 repeated measures discloses 1 excluded row",
      reported("m01", "rm", "n.excluded"), 1, tol = 0)
check("v28", "m01 one-way ANOVA analyses 35 of 36 rows",
      reported("m01", "anova", "df1") + reported("m01", "anova", "df2") + 1,
      35, tol = 0)
check("v28", "m01 Kruskal-Wallis analyses 35 of 36 rows",
      reported("m01", "kw", "n"), 35, tol = 0)

# ...and the exception. Stated as its own pair of checks so that making the
# two-way drop-and-disclose, or making the other eleven refuse, both fail.
STRICT_TAIL <- paste0(
  "This test reads the column as a whole, so one unusable cell replaces ",
  "every value with its alphabetical rank; the unusable rows cannot be ",
  "dropped individually here. 1 cell(s) are not numeric in any locale ",
  "(row 3: n/a). This is a type error, not missing data.")

check_true("v28", "m01 two-way REFUSES a mixed column", refused("m01", "twoway"))
expect_refusal("m01", "twoway",
               paste0('Data column "y" is not numeric in every row. ',
                      STRICT_TAIL))
check("v28", "m01 two-way printed nothing at all",
      reported("m01", "twoway", "output.chars"), 0, tol = 0)

for (tst in setdiff(TESTS, "twoway"))
  check_true("v28", paste("m01", tst, "does NOT refuse a mixed column"),
             !refused("m01", tst))

# ===========================================================================
# PART 3 -- THE RED PATHS.
#
# Asserted verbatim. A refusal that does not name the offending column and
# state the diagnosis is a defect in its own right (D99), so the words are
# the thing under test, not the fact that something was refused.
#
# The uniformity claim is checkable because every orchestrator is pointed at
# the SAME column, "y": the twelve messages must therefore differ only in
# the role word.
# ===========================================================================

ROLE <- c(twogroup = "Data column", anova = "Data column", kw = "Data column",
          pairwise = "Data column", twoway = "Data column",
          paired = "First column", correlation = "X column",
          descriptive = "Data column", regression = "Dependent column",
          normality = "Data column", rm = "Condition column",
          friedman = "Condition column")

red_case <- function(cs, tail) {
  lab <- man$kind[man$case == cs]
  for (tst in TESTS) {
    check_true("v28", sprintf("%s [%s] %s refuses", cs, lab, tst),
               refused(cs, tst))
    expect_refusal(cs, tst,
                   paste0(ROLE[[tst]], ' "y" holds no numbers. ', tail))
    check("v28", sprintf("%s [%s] %s printed nothing at all", cs, lab, tst),
          reported(cs, tst, "output.chars"), 0, tol = 0)
  }
}

# --- r01: a column of subject identifiers. The reported defect. -------------
red_case("r01", paste0("36 cell(s) are not numeric in any locale ",
                       "(row 1: Singer_1). This is a type error, not ",
                       "missing data."))
{
  d <- read.csv(file.path(ct_dir, "data", "r01.csv"), colClasses = "character")
  check_true("v28", "r01 y really is 36 identifiers, none of them numeric",
             nrow(d) == 36L &&
             all(is.na(suppressWarnings(as.numeric(d$y)))) &&
             d$y[1] == "Singer_1")
  # The heart of it: sorting those identifiers gives a perfectly good vector
  # of numbers, which is what Praat handed the ANOVA. R can show that the
  # ranks exist and are not constant -- i.e. that there WAS something for
  # the old code to compute an F from.
  check_true("v28", "the alphabetical ranks of those identifiers vary",
             length(unique(rank(d$y))) > 1L)
}

# --- r02: every cell empty. Genuinely missing, not mistyped -- and the -----
# message says so, using @emlAuditColumn's own empty-cell sentence rather
# than calling it a type error.
red_case("r02", "36 cell(s) are empty (row 1 first). Treated as missing data.")

# --- r03: every cell a European decimal comma ------------------------------
# The one that would corrupt rather than drop: Praat's lenient reader turns
# "1,5" into 1. The refusal must therefore NOT read as a type error, and must
# tell the user their numbers are recoverable.
red_case("r03", paste0("36 cell(s) use a comma where a decimal point ",
                       "belongs (row 1: 1,5). Praat reads these as a ",
                       "different number, so they are excluded rather than ",
                       "guessed at. Replace the commas with points to use ",
                       "these values."))
for (tst in TESTS)
  check_true("v28", paste("r03", tst, "does not misdiagnose a comma as a type error"),
             !grepl("type error", message_of("r03", tst), fixed = TRUE))

# --- r04: the column is not in the table -----------------------------------
# The TYPE guard must not preempt the not-found messages: a column that is
# not there has no type to diagnose. Every orchestrator must still refuse,
# and none of them may produce the type-error wording.
for (tst in TESTS) {
  check_true("v28", paste("r04", tst, "still refuses a missing column"),
             refused("r04", tst))
  check("v28", paste("r04", tst, "printed nothing at all"),
        reported("r04", tst, "output.chars"), 0, tol = 0)
  check_true("v28", paste("r04", tst, "keeps its own not-found wording"),
             !grepl("holds no numbers", message_of("r04", tst), fixed = TRUE))
}

# ---------------------------------------------------------------------------
# D116. Refusing is not enough: the refusal has to be ABOUT THE COLUMN.
#
# Every one of the twelve must name the column it could not find, and none
# may reach for the groups, the group sizes or the degrees of freedom
# instead -- which is exactly what two of them did. The wrong-thing test is
# a search for the VOCABULARY of the old messages rather than another
# verbatim pin, because a verbatim pin is what let both of these sit in this
# file for a day looking asserted. Any new way of blaming the grouping
# variable trips it too.
# ---------------------------------------------------------------------------
BLAME_GROUPS <- "observation|[Gg]roup|degrees of freedom"
for (tst in TESTS) {
  msg <- message_of("r04", tst)
  check_true("v28", paste("r04", tst, "names the missing column"),
             !is.na(msg) &&
               (grepl(": y$", msg) || grepl('"y"', msg, fixed = TRUE)))
  check_true("v28", paste("r04", tst, "says the word column"),
             !is.na(msg) && grepl("olumn", msg, fixed = TRUE))
  check_true("v28", paste("r04", tst, "does not blame the groups"),
             !is.na(msg) && !grepl(BLAME_GROUPS, msg))
}

# The two that were wrong, pinned to their new words. These two lines REPLACE
# pins that read
#   twogroup   Each group needs at least 2 observations. Group "G1": n=0, ...
#   kw         Group "H3" has 0 observations. Every group needs at least 1.
# The new wording is @emlOneWayAnova's, unchanged since before either defect:
# the fix moved a guard, it did not invent a sentence.
expect_refusal("r04", "twogroup", "Data column not found: y")
expect_refusal("r04", "kw",       "Data column not found: y")

# The n-per-group refusal is NOT retired. It is the right thing to say when
# the column is present and a group really is too small -- the D93 wizard
# walk has it on record for a group of one -- so it must still be there to
# be said. Only its reachability by a MISSING column has been removed.
check_true("v28",
           "the two-group n-per-group refusal still exists for real small groups",
           any(grepl("Each group needs at least 2 observations",
                     readLines(repo_path("plugin", "stats", "eml-analysis.praat"),
                               warn = FALSE), fixed = TRUE)))

# ---------------------------------------------------------------------------
# r02 versus r04 -- emptiness is not absence.
#
# The pair of refusals that must NOT converge. r02's column is in the table
# and blank; r04's is not in the table. Same twelve entry points, same column
# name, two different faults with two different remedies -- fill in the data,
# versus name a different column. A single "column unusable" message would
# be shorter and would put this script back where it started.
# ---------------------------------------------------------------------------
for (tst in TESTS) {
  m_empty <- message_of("r02", tst)
  m_gone  <- message_of("r04", tst)
  check_true("v28", paste(tst, "distinguishes an empty column from an absent one"),
             !is.na(m_empty) && !is.na(m_gone) && !identical(m_empty, m_gone))
  check_true("v28", paste(tst, "tells the empty-column user it is missing data"),
             !is.na(m_empty) &&
               grepl("Treated as missing data.", m_empty, fixed = TRUE))
  check_true("v28", paste(tst, "does not tell the empty-column user it is absent"),
             !is.na(m_empty) && !grepl("not found", m_empty, fixed = TRUE))
  check("v28", paste("r02", tst, "printed nothing at all"),
        reported("r02", tst, "output.chars"), 0, tol = 0)
}

# --- r05: text in the SECOND column of a two-column test --------------------
# Three orchestrators take a PAIR of measurement columns, and each therefore
# has two call sites. Every case above puts the bad column first, so without
# this case the role words "Second column", "Y column" and "Predictor column"
# would never be produced and a slip at one of those three second call sites
# -- the wrong role, the wrong variable, or a missing call -- would go unseen.
{
  tail05 <- paste0("36 cell(s) are not numeric in any locale (row 1: Take_1). ",
                   "This is a type error, not missing data.")
  second <- c(paired = "Second column", correlation = "Y column",
              regression = "Predictor column")
  for (tst in names(second)) {
    check_true("v28", paste("r05", tst, "refuses on its SECOND column"),
               refused("r05", tst))
    expect_refusal("r05", tst,
                   paste0(second[[tst]], ' "x" holds no numbers. ', tail05))
    check("v28", paste("r05", tst, "printed nothing at all"),
          reported("r05", tst, "output.chars"), 0, tol = 0)
  }
  # ...and the other nine never look at "x", so the guard must leave them
  # alone. A guard that refused whenever ANY column in the table were
  # unusable would fail here, and would be useless on real data.
  for (tst in setdiff(TESTS, names(second)))
    check_true("v28",
               paste("r05", tst, "is unaffected by a bad column it never reads"),
               !refused("r05", tst))
}

# D113a, found by this harness rather than by the GUI walk. @emlRunPairwise-
# Analysis had NO data-column guard and neither does @emlPairwiseT: pointed
# at a column that is not in the table it returned an empty error$ and printed
# a full comparison matrix of "n/a" -- the two-way defect's shape, one degree
# less dangerous only because the cells read n/a rather than plausible
# numbers. It now refuses in @emlOneWayAnova's wording.
expect_refusal("r04", "pairwise", "Data column not found: y")
expect_refusal("r04", "anova",    "Data column not found: y")
expect_refusal("r04", "twoway",   "Data column not found: y")

# ===========================================================================
# PART 4 -- THE LIBRARY LAYER (D116).
#
# Everything above drives orchestrators. This part drives the eleven
# table-taking tests in stats/eml-inferential.praat directly, because that is
# where D116 actually lived and because two of them -- @emlPairwiseT and
# @emlPairwiseWilcoxon -- proved that fixing an orchestrator does not fix the
# test underneath it. They proved it twice: D116 fixed the missing column
# here and left the blank one, which is D125 below. eml-lib-stats.praat loads
# this file with no orchestrator at all, so "call the test straight" is a
# supported path, not a corner.
#
# Same three obligations as above, in the same order: the green path still
# computes the right numbers; the missing column is refused BY NAME; the
# empty column is refused differently. And nothing may print.
# ===========================================================================

cm_dir <- Sys.getenv("EML_COLMISSING_DIR", unset = NA)
if (is.na(cm_dir)) cm_dir <- repo_path("harness", "colmissing", "out")

cm_res <- read.csv(file.path(cm_dir, "results.csv"), stringsAsFactors = FALSE)
cm_ref <- read.delim(file.path(cm_dir, "refusals.tsv"), sep = "\t",
                     quote = "", stringsAsFactors = FALSE)

SITES <- c("tukey", "anova", "twoway", "kw", "dunn", "pairwiset",
           "pairwisew", "scheffe", "bf", "welch", "gh")

cm_reported <- function(case, site, stat) {
  hit <- cm_res$value[cm_res$case == case & cm_res$site == site &
                        cm_res$statistic == stat]
  if (length(hit) != 1L)
    stop(sprintf("v28: expected exactly 1 colmissing row for %s/%s/%s, found %d",
                 case, site, stat, length(hit)))
  hit
}
cm_refused <- function(case, site)
  any(cm_res$case == case & cm_res$site == site & cm_res$statistic == "refused")
cm_message <- function(case, site) {
  hit <- cm_ref$error[cm_ref$case == case & cm_ref$site == site]
  if (length(hit) != 1L) NA_character_ else hit
}
cm_expect <- function(case, site, expected) {
  got <- cm_message(case, site)
  check_true("v28", sprintf("%s/%s refuses with the exact message", case, site),
             identical(got, expected))
  if (!identical(got, expected))
    cat(sprintf("v28 colmissing refusal mismatch %s/%s\n  expected: %s\n  got     : %s\n",
                case, site, expected,
                if (is.na(got)) "<no refusal>" else got))
}

# --- g01: the green path. The load-bearing half of PART 4 ------------------
# @emlRequireColumnPresent is now the first thing eleven tests do. If it were
# wrong in either direction -- refusing a column that is there, or selecting
# the wrong object and leaving the table unselected for the reader that
# follows -- these are what fail.
{
  gd <- read.csv(file.path(cm_dir, "data", "g01.csv"), stringsAsFactors = FALSE)
  gd$grp3 <- factor(gd$grp3, levels = sort(unique(gd$grp3)))
  gd$f2   <- factor(gd$f2,   levels = sort(unique(gd$f2)))
  check_true("v28", "g01 is 36 rows, 3 groups, all numeric",
             nrow(gd) == 36L && nlevels(gd$grp3) == 3L && !any(is.na(gd$y)))
  check_true("v28", "g01 two-way design is balanced, 6 per cell",
             all(table(gd$grp3, gd$f2) == 6))

  for (site in SITES)
    check_true("v28", paste("g01", site, "ran"), !cm_refused("g01", site))

  # one-way ANOVA
  s1 <- summary(aov(y ~ grp3, data = gd))[[1]]
  chk("lib.anova.F", "library ANOVA F",
      cm_reported("g01", "anova", "statistic"), s1[["F value"]][1], 1e-9)
  chk("lib.anova.p", "library ANOVA p",
      cm_reported("g01", "anova", "p.value"), s1[["Pr(>F)"]][1], 1e-12)
  chk("lib.anova.df", "library ANOVA df1",
      cm_reported("g01", "anova", "df1"), s1[["Df"]][1], 0)
  chk("lib.anova.df", "library ANOVA df2",
      cm_reported("g01", "anova", "df2"), s1[["Df"]][2], 0)

  # two-way ANOVA, balanced so aov()'s Type I equals the plugin's Type III
  s2 <- summary(aov(y ~ grp3 * f2, data = gd))[[1]]
  chk("lib.twoway.F", "library two-way F grp3",
      cm_reported("g01", "twoway", "statistic:A"), s2[["F value"]][1], 1e-7)
  chk("lib.twoway.F", "library two-way F f2",
      cm_reported("g01", "twoway", "statistic:B"), s2[["F value"]][2], 1e-7)
  chk("lib.twoway.ss", "library two-way SS error",
      cm_reported("g01", "twoway", "ss.error"), s2[["Sum Sq"]][4], 1e-8)

  # Kruskal-Wallis
  k1 <- kruskal.test(y ~ grp3, data = gd)
  chk("lib.kw.H", "library KW H", cm_reported("g01", "kw", "statistic"),
      unname(k1$statistic), 1e-9)
  chk("lib.kw.p", "library KW p", cm_reported("g01", "kw", "p.value"),
      k1$p.value, 1e-12)
  chk("lib.kw.n", "library KW N", cm_reported("g01", "kw", "n"), nrow(gd), 0)

  # pairwise Welch t, Holm -- the two tests that used to say nothing at all
  pw <- pairwise_welch_holm(gd$y, gd$grp3)
  for (r in seq_len(nrow(pw))) {
    idx <- c("p:1-2", "p:1-3", "p:2-3")[r]
    tdx <- c("t:1-2", NA, NA)[r]
    chk("lib.pairwiset.p", paste("library pairwise Holm p", pw$pair[r]),
        cm_reported("g01", "pairwiset", idx), pw$adj[r], 1e-10)
    if (!is.na(tdx))
      chk("lib.pairwiset.t", paste("library pairwise t", pw$pair[r]),
          cm_reported("g01", "pairwiset", tdx), pw$t[r], 1e-9)
  }

  # Welch ANOVA -- one of the six whose inline check was folded into the
  # shared guard. If that fold changed anything, its arithmetic moves.
  w1 <- oneway.test(y ~ grp3, data = gd, var.equal = FALSE)
  chk("lib.welch.F", "library Welch ANOVA F",
      cm_reported("g01", "welch", "statistic"), unname(w1$statistic), 1e-9)
  chk("lib.welch.df", "library Welch ANOVA df2",
      cm_reported("g01", "welch", "df2"), unname(w1$parameter[2]), 1e-9)
  chk("lib.welch.p", "library Welch ANOVA p",
      cm_reported("g01", "welch", "p.value"), w1$p.value, 1e-12)

  # Scheffe's MSE is the one-way within-groups mean square, by construction.
  chk("lib.scheffe.mse", "library Scheffe MSE",
      cm_reported("g01", "scheffe", "mse"),
      s1[["Sum Sq"]][2] / s1[["Df"]][2], 1e-9)

  # Only the two-way prints, and it prints Praat's own report. Everything
  # else in this file is a computation, and a computation that writes to the
  # Info window has stolen it from whoever called it.
  for (site in setdiff(SITES, "twoway"))
    check("v28", paste("g01", site, "printed nothing"),
          cm_reported("g01", site, "output.chars"), 0, tol = 0)
  check_true("v28", "g01 two-way printed Praat's report",
             cm_reported("g01", "twoway", "output.chars") > 0)
}

# --- n01: the data column is not in the table ------------------------------
# All eleven, one sentence, naming the column. Five of them said something
# else or nothing before D116.
for (site in SITES) {
  check_true("v28", paste("n01", site, "refuses a missing data column"),
             cm_refused("n01", site))
  cm_expect("n01", site, "Data column not found: y")
  check("v28", paste("n01", site, "printed nothing at all"),
        cm_reported("n01", site, "output.chars"), 0, tol = 0)
}

# Named individually so a reader of a failing run sees WHICH defect came
# back, and so deleting the loop above cannot quietly take these with it.
cm_expect("n01", "kw",        "Data column not found: y")   # was: Group "H3" has 0 observations
cm_expect("n01", "dunn",      "Data column not found: y")   # was: Group "H3" has 0 observations
cm_expect("n01", "scheffe",   "Data column not found: y")   # was: no within-groups df
cm_expect("n01", "pairwiset", "Data column not found: y")   # was: NOTHING
cm_expect("n01", "pairwisew", "Data column not found: y")   # was: NOTHING

# --- n02: the data column is there and every cell is empty -----------------
# The distinction, at the library layer. n02 must not produce n01's sentence:
# these columns exist, and telling their owner they do not would be a new
# instance of the defect being fixed.
#
# All eleven now refuse. Two of them did not until D125, and the loop below
# covers all eleven rather than excusing those two: the exemption list that
# used to sit here is the thing that has to be gone, not merely shortened.
for (site in SITES) {
  m <- cm_message("n02", site)
  check_true("v28", paste("n02", site, "refuses an empty data column"),
             cm_refused("n02", site))
  check_true("v28", paste("n02", site, "does not call an empty column absent"),
             !is.na(m) && !grepl("not found", m, fixed = TRUE))
  check_true("v28", paste("n02", site, "differs from the missing-column refusal"),
             !identical(m, cm_message("n01", site)))
}
for (site in SITES)
  check("v28", paste("n02", site, "printed nothing at all"),
        cm_reported("n02", site, "output.chars"), 0, tol = 0)

# --- D125: the gap this file used to pin AS SILENT -------------------------
#
# Until 8 August these two were pinned as producing nothing: an empty error$
# and a matrix of undefined on an all-blank column. That pin was honest --
# no number was ever produced, so it was a gap and not a wrong answer, and
# the menu path could not reach it because @emlRunPairwiseAnalysis refuses
# on the same table first (r02 above). It was still a gap, for the reason
# the rest of PART 4 exists: a script that calls @emlPairwiseT straight,
# which is what eml-lib-stats.praat is for, got no verdict at all and no way
# to tell a refusal from a computation.
#
# The pin is now the refusal, verbatim, and it is deliberately the SAME
# sentence @emlTwoWayAnova gives for the same column -- the comparison this
# file used to make in a comment ("what the other ten would say if it were
# widened") is now made in the assertion. Both tests go through
# @emlRequireNumericColumn, so a drift in either would have to be a drift in
# @emlAuditColumn's wording, which r02 pins at the orchestrator layer.
#
# These two lines are what fails if the guard is ever removed again.
EMPTY_NONUMBERS <- paste0('Data column "y" holds no numbers. 36 cell(s) are ',
                          'empty (row 1 first). Treated as missing data.')
cm_expect("n02", "pairwiset", EMPTY_NONUMBERS)   # was: NOTHING (silent gap)
cm_expect("n02", "pairwisew", EMPTY_NONUMBERS)   # was: NOTHING (silent gap)

# Pinned verbatim, and honestly labelled. THREE of the eleven now carry the
# D113 type guard at this layer -- @emlTwoWayAnova from D113 itself, and the
# two pairwise tests from D125 above -- so the remaining eight still describe
# an all-blank column in terms of the group sizes it produces. That is a
# weaker diagnosis than the orchestrators give for the same table (r02 above:
# 'Data column "y" holds no numbers. 36 cell(s) are empty ...'), and it is
# pinned here rather than quietly fixed because widening the type guard to
# the whole library is D113's decision to reopen, not D125's to make in
# passing: D125 closed a SILENCE, which is a gap of a different kind from a
# refusal that names the wrong thing, and the eight below do refuse and do
# say something true. Pinned, they are visible; a later run that improves
# them will fail here and say so.
#
# Note what these eight are NOT. None of them produces a number from an
# all-blank column -- they refuse, and the "printed nothing at all" checks
# above hold for every one of the eleven.
EMPTY_SMALL <- paste0('3 of 3 groups in "grp3" have fewer than 2 observations: ',
                      '"H1", "H2", "H3". Every group needs at least 2.')
EMPTY_NODF <- paste0("0 observations across 3 groups leave no within-groups ",
                     "degrees of freedom. There must be more observations ",
                     "than groups.")
cm_expect("n02", "anova",   EMPTY_SMALL)
cm_expect("n02", "bf",      EMPTY_SMALL)
cm_expect("n02", "welch",   EMPTY_SMALL)
cm_expect("n02", "gh",      EMPTY_SMALL)
cm_expect("n02", "tukey",   EMPTY_NODF)
cm_expect("n02", "scheffe", EMPTY_NODF)
cm_expect("n02", "kw",
          'Group "H3" has 0 observations. Every group needs at least 1.')
cm_expect("n02", "dunn",
          'Group "H3" has 0 observations. Every group needs at least 1.')
# ...and the three that DO carry the type guard say the same sentence as one
# another. Asserted against the identical string the two pairwise pins use
# above, so "the guard gives one wording" is checked rather than asserted
# three times independently.
cm_expect("n02", "twoway", EMPTY_NONUMBERS)

# ---------------------------------------------------------------------------
# Measured agreement, printed so the run states it rather than implying it.
# ---------------------------------------------------------------------------
if (length(RELERR$rows)) {
  rel <- do.call(rbind, RELERR$rows)
  agg <- aggregate(rel ~ family, data = rel, FUN = max)
  agg <- agg[order(-agg$rel), ]
  cat("\nv28 maximum RELATIVE error vs base R, by statistic:\n")
  for (i in seq_len(nrow(agg)))
    cat(sprintf("  %-16s %8.2e   (n = %d)\n", agg$family[i], agg$rel[i],
                sum(rel$family == agg$family[i])))
  cat("\n")
}

if (!exists("EML_SUITE")) { eml_report("v28 column-type guard"); eml_exit() }
