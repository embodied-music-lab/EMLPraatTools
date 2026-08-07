# ============================================================================
# v22_homogeneity.R -- the three variance-heterogeneity procedures, against
# base R.
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
#     @emlBrownForsythe   Levene's test with MEDIAN centring
#     @emlWelchAnova      Welch's heteroscedastic k-sample F
#     @emlGamesHowell     pairwise Welch post-hoc on the studentized range
#
# Base R only, as the rest of the suite is. Welch's F comes from
# oneway.test(var.equal = FALSE); Brown-Forsythe is an aov on the absolute
# deviations from the group medians; Games-Howell is implemented here from
# ptukey/qtukey, because no base function computes it and a package would put
# this suite outside the reach of a reviewer with a stock R.
#
# THE k = 2 IDENTITY. Welch's k-sample F at k = 2 must equal Welch's t
# squared, on the Welch-Satterthwaite df. That is not a tolerance question
# and not an approximation: it is an algebraic identity that a wrong
# denominator-df formula silently breaks (the textbook form of df2 is 0/0 at
# k = 2). It is asserted here against BOTH the plugin's own @emlTTest and
# R's t.test.
#
#     Rscript validate/v22_homogeneity.R
#
# Input:  harness/homogeneity/out/{manifest.csv,results.csv,refusals.tsv}
#         harness/homogeneity/out/data/<case>.csv
#         (regenerate with harness/homogeneity/homogeneity_cases.praat)
#         Override the directory with EML_HOMOG_DIR.
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

homog_dir <- Sys.getenv("EML_HOMOG_DIR", unset = NA)
if (is.na(homog_dir)) homog_dir <- repo_path("harness", "homogeneity", "out")

man <- read.csv(file.path(homog_dir, "manifest.csv"), stringsAsFactors = FALSE)
res <- read.csv(file.path(homog_dir, "results.csv"), stringsAsFactors = FALSE)
ref <- read.delim(file.path(homog_dir, "refusals.tsv"), sep = "\t",
                  quote = "", stringsAsFactors = FALSE)

# ---------------------------------------------------------------------------
# Pulling numbers out of the long results frame. A missing row is a hard
# stop, not a skip: "the plugin did not report this" is exactly the failure a
# silently shrinking harness produces.
# ---------------------------------------------------------------------------
reported <- function(case, test, stat) {
  hit <- res$value[res$case == case & res$test == test & res$statistic == stat]
  if (length(hit) != 1L)
    stop(sprintf("v22: expected exactly 1 row for %s/%s/%s, found %d",
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

# Relative error, accumulated so the run can state its own agreement rather
# than leaving it to be inferred from a pass count.
RELERR <- new.env(parent = emptyenv()); RELERR$rows <- list()
chk <- function(family, what, rep_v, comp_v, tol) {
  if (is.finite(rep_v) && is.finite(comp_v)) {
    denom <- max(abs(comp_v), .Machine$double.xmin)
    RELERR$rows[[length(RELERR$rows) + 1L]] <-
      data.frame(family = family, rel = abs(rep_v - comp_v) / denom)
  }
  check("v22", what, rep_v, comp_v, tol = tol)
}

# ---------------------------------------------------------------------------
# Games-Howell, from the definition. Returns one row per unordered pair, in
# the same i<j order over alphabetically sorted group labels that the plugin
# emits.
# ---------------------------------------------------------------------------
games_howell <- function(x, g, alpha = 0.05) {
  g  <- factor(g, levels = sort(unique(as.character(g))))
  n  <- tapply(x, g, length)
  m  <- tapply(x, g, mean)
  v  <- tapply(x, g, var)
  k  <- nlevels(g)
  out <- NULL
  for (i in seq_len(k - 1L)) for (j in (i + 1L):k) {
    vi <- v[i] / n[i]; vj <- v[j] / n[j]
    se <- sqrt((vi + vj) / 2)
    q  <- abs(m[i] - m[j]) / se
    df <- (vi + vj)^2 / (vi^2 / (n[i] - 1) + vj^2 / (n[j] - 1))
    out <- rbind(out, data.frame(
      pair     = paste0(levels(g)[i], "-", levels(g)[j]),
      estimate = unname(m[i] - m[j]),
      se       = unname(se),
      q        = unname(q),
      df       = unname(df),
      p        = unname(ptukey(q, k, df, lower.tail = FALSE)),
      qcrit    = unname(qtukey(1 - alpha, k, df)),
      stringsAsFactors = FALSE))
  }
  out
}

# Brown-Forsythe: a one-way ANOVA on |x - median(group)|.
brown_forsythe <- function(x, g) {
  g <- factor(g, levels = sort(unique(as.character(g))))
  z <- abs(x - ave(x, g, FUN = median))
  a <- anova(lm(z ~ g))
  list(f = a[["F value"]][1], p = a[["Pr(>F)"]][1],
       df1 = a[["Df"]][1], df2 = a[["Df"]][2],
       ssb = a[["Sum Sq"]][1], ssw = a[["Sum Sq"]][2],
       med = tapply(x, g, median), meandev = tapply(z, g, mean))
}

# ---------------------------------------------------------------------------
# THE GREEN PATHS
# ---------------------------------------------------------------------------
green <- c("c01", "c02", "c03", "c04", "c05", "c06", "c07", "c08", "c09")

for (cs in green) {
  lab <- sprintf("%s [%s]", cs, man$shape[man$case == cs])
  d <- read.csv(file.path(homog_dir, "data", paste0(cs, ".csv")),
                stringsAsFactors = FALSE)
  d$grp <- factor(d$grp, levels = sort(unique(d$grp)))
  k <- nlevels(d$grp)

  # ---- Brown-Forsythe ------------------------------------------------------
  check_true("v22", paste(lab, "Brown-Forsythe did not refuse"), !refused(cs, "bf"))
  if (!refused(cs, "bf")) {
    bf <- brown_forsythe(d$value, d$grp)
    chk("bf.F", paste(lab, "BF F"), reported(cs, "bf", "statistic"), bf$f, 1e-9)
    chk("bf.p", paste(lab, "BF p"), reported(cs, "bf", "p.value"),   bf$p, 1e-12)
    chk("bf.df", paste(lab, "BF df1"), reported(cs, "bf", "df1"), bf$df1, 0)
    chk("bf.df", paste(lab, "BF df2"), reported(cs, "bf", "df2"), bf$df2, 0)
    chk("bf.ss", paste(lab, "BF SS between"),
        reported(cs, "bf", "ss.between"), bf$ssb, 1e-9)
    chk("bf.ss", paste(lab, "BF SS within"),
        reported(cs, "bf", "ss.within"), bf$ssw, 1e-9)
    # The medians themselves, so that a mean-centred implementation cannot
    # pass by coincidence on symmetric data (c08 is the case that bites).
    for (lv in levels(d$grp)) {
      chk("bf.median", paste(lab, "BF median", lv),
          reported(cs, "bf", paste0("median:", lv)), unname(bf$med[lv]), 1e-9)
      chk("bf.meandev", paste(lab, "BF mean |dev|", lv),
          reported(cs, "bf", paste0("meandev:", lv)), unname(bf$meandev[lv]), 1e-9)
    }
  }

  # ---- Welch's F -----------------------------------------------------------
  # c09 has a flat group; oneway.test would divide by that zero variance too,
  # so R is not asked to. The refusal is asserted in the red-path block.
  if (!refused(cs, "welch")) {
    w <- oneway.test(value ~ grp, data = d, var.equal = FALSE)
    chk("welch.F", paste(lab, "Welch F"),
        reported(cs, "welch", "statistic"), unname(w$statistic), 1e-9)
    chk("welch.p", paste(lab, "Welch p"),
        reported(cs, "welch", "p.value"), w$p.value, 1e-12)
    chk("welch.df", paste(lab, "Welch df1"),
        reported(cs, "welch", "df1"), unname(w$parameter[1]), 0)
    chk("welch.df", paste(lab, "Welch df2"),
        reported(cs, "welch", "df2"), unname(w$parameter[2]), 1e-9)
    for (lv in levels(d$grp))
      chk("welch.var", paste(lab, "Welch group variance", lv),
          reported(cs, "welch", paste0("var:", lv)),
          unname(tapply(d$value, d$grp, var)[lv]), 1e-9)

    # ---- k = 2: F must be Welch t squared --------------------------------
    if (k == 2L) {
      a <- d$value[d$grp == levels(d$grp)[1]]
      b <- d$value[d$grp == levels(d$grp)[2]]
      tt <- t.test(a, b, var.equal = FALSE)
      chk("k2.identity", paste(lab, "Welch F = t.test t^2"),
          reported(cs, "welch", "statistic"), unname(tt$statistic)^2, 1e-9)
      chk("k2.identity", paste(lab, "Welch df2 = t.test df"),
          reported(cs, "welch", "df2"), unname(tt$parameter), 1e-9)
      chk("k2.identity", paste(lab, "Welch p = t.test p"),
          reported(cs, "welch", "p.value"), tt$p.value, 1e-12)
      # And against the plugin's OWN Welch t, so the identity is checked
      # inside Praat as well as across the language boundary.
      chk("k2.identity", paste(lab, "Welch F = @emlTTest t^2 (plugin)"),
          reported(cs, "welch", "statistic"), reported(cs, "welcht", "t")^2, 1e-9)
      chk("k2.identity", paste(lab, "Welch df2 = @emlTTest df (plugin)"),
          reported(cs, "welch", "df2"), reported(cs, "welcht", "df"), 1e-9)
    }
  }

  # ---- Games-Howell --------------------------------------------------------
  check_true("v22", paste(lab, "Games-Howell did not refuse"), !refused(cs, "gh"))
  if (!refused(cs, "gh")) {
    gh <- games_howell(d$value, d$grp, alpha = 0.05)
    check("v22", paste(lab, "GH pair count"),
          reported(cs, "gh", "n.pairs"), k * (k - 1) / 2, tol = 0)
    check("v22", paste(lab, "GH undefined count"),
          reported(cs, "gh", "n.undefined"), 0, tol = 0)
    for (r in seq_len(nrow(gh))) {
      pr <- gh$pair[r]
      chk("gh.estimate", paste(lab, "GH estimate", pr),
          reported(cs, "gh", paste0("estimate:", pr)), gh$estimate[r], 1e-9)
      chk("gh.se", paste(lab, "GH se", pr),
          reported(cs, "gh", paste0("se:", pr)), gh$se[r], 1e-9)
      chk("gh.q", paste(lab, "GH q", pr),
          reported(cs, "gh", paste0("q:", pr)), gh$q[r], 1e-9)
      chk("gh.df", paste(lab, "GH Welch-Satterthwaite df", pr),
          reported(cs, "gh", paste0("df:", pr)), gh$df[r], 1e-9)
      chk("gh.p", paste(lab, "GH adj p", pr),
          reported(cs, "gh", paste0("adj.p.value:", pr)), gh$p[r], 1e-7)
      chk("gh.qcrit", paste(lab, "GH critical q", pr),
          reported(cs, "gh", paste0("q.crit:", pr)), gh$qcrit[r], 1e-6)
    }
    # The pooled names exist for shape compatibility with @emlTukeyHSD and
    # must be undefined, not quietly carrying a number that would read as a
    # pooled MSE Games-Howell never computed.
    check_true("v22", paste(lab, "GH .msWithin is undefined"),
               is.na(reported(cs, "gh", "ms.within")))
    check_true("v22", paste(lab, "GH .dfWithin is undefined"),
               is.na(reported(cs, "gh", "df.within")))
    check_true("v22", paste(lab, "GH .qCritical is undefined"),
               is.na(reported(cs, "gh", "q.critical")))
  }
}

# The +1e6 offset case must reproduce the un-offset case exactly in F and p:
# all three statistics are location invariant, so any difference is
# cancellation, not statistics. c01 and c07 are the same design; the data
# differ (separate draws), so what is checked is that R and Praat agree on
# c07 to the SAME tolerance they agree on c01 -- already done above -- plus
# that the offset has not cost the plugin its digits relative to R.
c07 <- read.csv(file.path(homog_dir, "data", "c07.csv"), stringsAsFactors = FALSE)
c07$grp <- factor(c07$grp)
w07 <- oneway.test(value ~ grp, data = c07, var.equal = FALSE)
w07s <- oneway.test(I(value - 1e6) ~ grp, data = c07, var.equal = FALSE)
check("v22", "c07 Welch F is location invariant in R (control)",
      unname(w07$statistic), unname(w07s$statistic), tol = 1e-9)
check("v22", "c07 plugin Welch F matches the de-offset fit",
      reported("c07", "welch", "statistic"), unname(w07s$statistic), tol = 1e-9)

# ---------------------------------------------------------------------------
# THE RED PATHS
#
# Asserted verbatim. A refusal that does not name the offending group is a
# defect in its own right (D99), so the message text is the thing under test,
# not merely the fact that something was refused.
# ---------------------------------------------------------------------------
expect_refusal <- function(case, test, expected) {
  got <- message_of(case, test)
  check_true("v22", sprintf("%s/%s refuses with the named-group message",
                            case, test),
             identical(got, expected))
  if (!identical(got, expected))
    cat(sprintf("v22 refusal mismatch %s/%s\n  expected: %s\n  got     : %s\n",
                case, test, expected, if (is.na(got)) "<no refusal>" else got))
}

singleton3 <- paste0('1 of 3 groups in "grp" have fewer than 2 observations: ',
                     '"G3". Every group needs at least 2.')
allthree   <- paste0('3 of 3 groups in "grp" have fewer than 2 observations: ',
                     '"G1", "G2", "G3". Every group needs at least 2.')
identifier <- paste0('Group column "grp" has 9 groups for 9 rows - one per ',
                     'row. This is an identifier column, not a grouping column.')
flat_tail  <- paste0('. Welch\'s F weights each group by n/variance, which is ',
                     'undefined when every observation in a group is identical.')

# r01 singleton group -- all three refuse, naming G3.
expect_refusal("r01", "bf",    singleton3)
expect_refusal("r01", "welch", singleton3)
expect_refusal("r01", "gh",    singleton3)

# r02 one flat group among varying ones. Welch refuses (its weight is n/0);
# Brown-Forsythe and Games-Howell must NOT -- a group with no spread is a
# datum about variance, which is precisely what these tests are asking about.
expect_refusal("r02", "welch",
               paste0('1 of 3 groups in "grp" have zero variance: "G3"', flat_tail))
check_true("v22", "r02 Brown-Forsythe does not refuse a flat group",
           !refused("r02", "bf"))
check_true("v22", "r02 Games-Howell does not refuse a flat group",
           !refused("r02", "gh"))
{
  d <- read.csv(file.path(homog_dir, "data", "r02.csv"), stringsAsFactors = FALSE)
  d$grp <- factor(d$grp)
  bf <- brown_forsythe(d$value, d$grp)
  chk("bf.F", "r02 BF F (flat group present)",
      reported("r02", "bf", "statistic"), bf$f, 1e-9)
  chk("bf.p", "r02 BF p (flat group present)",
      reported("r02", "bf", "p.value"), bf$p, 1e-12)
  gh <- games_howell(d$value, d$grp)
  for (r in seq_len(nrow(gh)))
    chk("gh.p", paste("r02 GH adj p", gh$pair[r]),
        reported("r02", "gh", paste0("adj.p.value:", gh$pair[r])), gh$p[r], 1e-7)
  check("v22", "r02 GH undefined count", reported("r02", "gh", "n.undefined"),
        0, tol = 0)
}

# c09 k = 2 with one flat group: same rule at the smallest k.
expect_refusal("c09", "welch",
               paste0('1 of 2 groups in "grp" have zero variance: "G2"', flat_tail))

# r03 identifier column -- one group per row.
expect_refusal("r03", "bf",    identifier)
expect_refusal("r03", "welch", identifier)
expect_refusal("r03", "gh",    identifier)

# r04 a single group. BF and Welch echo @emlOneWayAnova's wording; Games-Howell
# echoes @emlTukeyHSD's, since it is the post-hoc's counterpart.
expect_refusal("r04", "bf",
               'Group column "grp" has 1 group. This test compares 2 or more.')
expect_refusal("r04", "welch",
               'Group column "grp" has 1 group. This test compares 2 or more.')
expect_refusal("r04", "gh",
               'This test compares 2 or more groups; the group column "grp" has 1.')

# r05 every observation identical.
expect_refusal("r05", "welch",
               paste0('3 of 3 groups in "grp" have zero variance: "G1", "G2", ',
                      '"G3"', flat_tail))
check_true("v22", "r05 Brown-Forsythe does not refuse all-constant data",
           !refused("r05", "bf"))
check_true("v22", "r05 BF F is undefined, not 1",
           is.na(reported("r05", "bf", "statistic")))
check_true("v22", "r05 BF p is undefined, not 1",
           is.na(reported("r05", "bf", "p.value")))
check_true("v22", "r05 BF discloses the zero MS-within",
           identical(message_of("r05", "bf.warning"),
                     paste0("Within-groups mean square of the absolute ",
                            "deviations is zero (every observation is the ",
                            "same distance from its group median); F and p ",
                            "are undefined")))
check_true("v22", "r05 Games-Howell does not refuse all-constant data",
           !refused("r05", "gh"))
check("v22", "r05 GH counts all 3 comparisons undefined",
      reported("r05", "gh", "n.undefined"), 3, tol = 0)
for (pr in c("G1-G2", "G1-G3", "G2-G3")) {
  check_true("v22", paste("r05 GH q undefined, not 0, for", pr),
             is.na(reported("r05", "gh", paste0("q:", pr))))
  check_true("v22", paste("r05 GH adj p undefined, not 1, for", pr),
             is.na(reported("r05", "gh", paste0("adj.p.value:", pr))))
}
check_true("v22", "r05 GH discloses the undefined comparisons",
           identical(message_of("r05", "gh.warning"),
                     paste0("3 of 3 comparisons have an undefined q (both ",
                            "groups have zero variance, so the pairwise ",
                            "standard error is zero); their p-values are ",
                            "undefined, not 1")))

# r06 non-numeric data column. @eml_getGroupData drops the unusable rows, so
# this presents as every group having too few observations -- the same shape
# @emlOneWayAnova produces, which is the point: one diagnosis, not three.
expect_refusal("r06", "bf",    allthree)
expect_refusal("r06", "welch", allthree)
expect_refusal("r06", "gh",    allthree)

# r07 fewer than 3 rows.
expect_refusal("r07", "bf",    "Need at least 3 observations, got 2.")
expect_refusal("r07", "welch", "Need at least 3 observations, got 2.")
expect_refusal("r07", "gh",
               "This test needs at least 3 observations; the table has 2.")

# r08 the data column is not there.
expect_refusal("r08", "bf",    "Data column not found: value")
expect_refusal("r08", "welch", "Data column not found: value")
expect_refusal("r08", "gh",    "Data column not found: value")

# ---------------------------------------------------------------------------
# Measured agreement, printed so the run states it rather than implying it.
# ---------------------------------------------------------------------------
if (length(RELERR$rows)) {
  rel <- do.call(rbind, RELERR$rows)
  agg <- aggregate(rel ~ family, data = rel, FUN = max)
  agg <- agg[order(-agg$rel), ]
  cat("\nv22 maximum RELATIVE error vs base R, by statistic:\n")
  for (i in seq_len(nrow(agg)))
    cat(sprintf("  %-14s %8.2e   (n = %d)\n", agg$family[i], agg$rel[i],
                sum(rel$family == agg$family[i])))
  cat("\n")
}

if (!exists("EML_SUITE")) { eml_report("v22 homogeneity of variance"); eml_exit() }
