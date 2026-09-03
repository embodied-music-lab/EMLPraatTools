# ===========================================================================
# verify-survey-lane.R — external verification of every numeric literal in
# test-psychometrics.praat and test-categorical.praat
# ===========================================================================
# Recomputes each reference value with R (psych::alpha, chisq.test,
# prop.test) and exits non-zero on any disagreement beyond half a unit
# in the literal's last printed decimal. Run:
#     Rscript verify-survey-lane.R
# Requires the psych package (r-cran-psych) for the alpha block.
# ===========================================================================

fails <- 0L

# Feldt (1965): the interval on alpha from the F distribution on
# (n - 1, (n - 1)(k - 1)) df, at any two-sided level. At conf = 0.95 this
# is the .025 / .975 pair every reference states, and psych::alpha's
# fixed-level output below is asserted against it.
base_feldt <- function(a, n, k, conf) {
    df1 <- n - 1; df2 <- (n - 1) * (k - 1); tl <- (1 - conf) / 2
    c(1 - (1 - a) * stats::qf(1 - tl, df1, df2),
      1 - (1 - a) * stats::qf(tl, df1, df2))
}

expect <- function(what, literal, computed, tol = 5e-11) {
    ok <- is.finite(computed) && abs(literal - computed) <= tol
    cat(sprintf("%-4s  %-58s  literal=%.10f  R=%.10f\n",
                if (ok) "PASS" else "FAIL", what, literal, computed))
    if (!ok) fails <<- fails + 1L
    invisible(ok)
}

# --- test-psychometrics.praat -------------------------------------------

if (!requireNamespace("psych", quietly = TRUE)) {
    cat("FAIL  psych is not installed; the alpha literals cannot be verified\n")
    fails <- fails + 1L
} else {
    d <- matrix(c(2,3,3,3,2, 4,4,3,4,4, 3,4,4,3,3, 5,5,4,5,5, 1,2,2,1,2,
                  4,3,3,4,4, 2,2,3,2,2, 5,4,5,5,4, 3,3,3,3,4, 4,5,4,4,5),
                ncol = 5, byrow = TRUE)
    a <- suppressWarnings(psych::alpha(as.data.frame(d),
                                       check.keys = FALSE, warnings = FALSE))
    expect("alpha (10x5 clean)", 0.9491763761, a$total$raw_alpha)
    expect("Feldt CI lower", 0.8733351023, a$feldt$lower.ci[[1]])
    expect("Feldt CI upper", 0.9855775272, a$feldt$upper.ci[[1]])

    # psych::alpha fixes its own level, so the general form is pinned
    # against psych's numbers at 0.95 here; the 0.99 literals below then
    # rest on a function psych has vouched for at the level it does report.
    f95 <- base_feldt(a$total$raw_alpha, nrow(d), ncol(d), 0.95)
    expect("Feldt general form vs psych at 0.95, lower",
           f95[1], a$feldt$lower.ci[[1]])
    expect("Feldt general form vs psych at 0.95, upper",
           f95[2], a$feldt$upper.ci[[1]])
    drop_lit <- c(0.9209039548, 0.9375000000, 0.9580922322,
                  0.9237002026, 0.9393183707)
    for (j in 1:5) {
        expect(sprintf("alpha-if-deleted, item %d", j),
               drop_lit[j], a$alpha.drop$raw_alpha[j])
    }

    dm <- d; dm[2, 2] <- NA
    am <- suppressWarnings(psych::alpha(as.data.frame(dm[complete.cases(dm), ]),
                                        check.keys = FALSE, warnings = FALSE))
    expect("alpha after listwise deletion", 0.9528130672, am$total$raw_alpha)

    a2 <- suppressWarnings(psych::alpha(as.data.frame(d[, 1:2]),
                                        check.keys = FALSE, warnings = FALSE))
    expect("2-item alpha", 0.8823529412, a2$total$raw_alpha)
}

# --- test-psychometrics.praat: @emlAlphaInfluence (base R, no packages) --

base_alpha <- function(cc) {
    k <- ncol(cc)
    C <- stats::cov(cc)
    (k / (k - 1)) * (1 - sum(diag(C)) / sum(C))
}
d <- matrix(c(2,3,3,3,2, 4,4,3,4,4, 3,4,4,3,3, 5,5,4,5,5, 1,2,2,1,2,
              4,3,3,4,4, 2,2,3,2,2, 5,4,5,5,4, 3,3,3,3,4, 4,5,4,4,5),
            ncol = 5, byrow = TRUE)
full <- base_alpha(d)

# --- the Feldt interval at a level psych::alpha does not offer ------------
# The general form, in base R, so the 0.99 literals are verifiable on a
# stock installation. The block above pins this same function against
# psych's own 0.95 numbers whenever psych is present, which is what stops
# it being a restatement of the plugin's arithmetic.
f99 <- base_feldt(full, nrow(d), ncol(d), 0.99)
expect("Feldt 0.99 lower", 0.8324624444, f99[1])
expect("Feldt 0.99 upper", 0.9908495094, f99[2])
aw <- vapply(1:10, function(i) base_alpha(d[-i, , drop = FALSE]), numeric(1))
dl <- aw - full
expect("influence alphaFull", 0.9491763761, full)
expect("alpha without respondent 1", 0.9519787645, aw[1])
expect("delta for respondent 1", 0.0028023884, dl[1])
expect("alpha without respondent 10", 0.9487500000, aw[10])
expect("largest absolute delta", 0.0214143364, max(abs(dl)))
expect("its respondent", 5, which.max(abs(dl)), tol = 0)

di <- d; di[2, 2] <- NA; di[4, 3] <- NA
keep <- complete.cases(di)
cc <- di[keep, , drop = FALSE]
fulli <- base_alpha(cc)
awi <- vapply(seq_len(nrow(cc)), function(i)
    base_alpha(cc[-i, , drop = FALSE]), numeric(1))
expect("influence alphaFull after deletion", 0.9458111702, fulli)
expect("survivor 3 maps to original row 5", 5, which(keep)[3], tol = 0)
expect("survivor 8 maps to original row 10", 10, which(keep)[8], tol = 0)
expect("dominant delta at original row 5", 5,
       which(keep)[which.max(abs(awi - fulli))], tol = 0)

# --- conditioning: the same literals must hold under a large offset -----

doff <- d + 1e8
fullo <- base_alpha(doff)
awo <- vapply(1:10, function(i) base_alpha(doff[-i, , drop = FALSE]),
              numeric(1))
expect("offset alpha equals the clean literal", 0.9491763761, fullo)
expect("offset largest absolute delta unchanged", 0.0214143364,
       max(abs(awo - fullo)))
expect("offset dominant respondent unchanged", 5,
       which.max(abs(awo - fullo)), tol = 0)

# --- test-categorical.praat: chi-square ---------------------------------

t1 <- matrix(c(20, 10, 15, 25), 2, 2)
rc <- suppressWarnings(chisq.test(t1, correct = TRUE))
ru <- suppressWarnings(chisq.test(t1, correct = FALSE))
expect("2x2 corrected chi-square", 4.7250000000, unname(rc$statistic))
expect("2x2 corrected p", 0.0297271833, rc$p.value)
expect("2x2 uncorrected chi-square", 5.8333333333, unname(ru$statistic))
expect("2x2 uncorrected p", 0.0157252998, ru$p.value)
expect("2x2 Cramér's V (uncorrected)", 0.2886751346,
       sqrt(unname(ru$statistic) / (sum(t1) * (min(dim(t1)) - 1))))

s <- matrix(c(3, 2, 1, 4), 2, 2)
rs <- suppressWarnings(chisq.test(s, correct = TRUE))
expect("sparse corrected chi-square", 0.4166666667, unname(rs$statistic))
expect("sparse corrected p", 0.5186050164, rs$p.value)
expect("sparse smallest expected", 2, min(rs$expected), tol = 0)
expect("sparse cells below 5", 4, sum(rs$expected < 5), tol = 0)

b <- matrix(c(12, 9, 7, 8, 11, 13, 14, 5, 10, 6, 15, 10), 3, 4)
rb <- suppressWarnings(chisq.test(b))
expect("3x4 chi-square", 10.6870232798, unname(rb$statistic))
expect("3x4 df", 6, unname(rb$parameter), tol = 0)
expect("3x4 p", 0.0985445284, rb$p.value)
expect("3x4 Cramér's V", 0.2110195812,
       sqrt(unname(rb$statistic) / (sum(b) * (min(dim(b)) - 1))))

z <- matrix(c(10, 5, 0, 8), 2, 2)
rz <- suppressWarnings(chisq.test(z, correct = FALSE))
expect("zero-cell chi-square", 9.4358974359, unname(rz$statistic))
expect("zero-cell V", 0.6405126152,
       sqrt(unname(rz$statistic) / (sum(z) * (min(dim(z)) - 1))))

# --- test-categorical.praat: Wilson -------------------------------------

wl <- function(x, n, cl) prop.test(x, n, conf.level = cl,
                                   correct = FALSE)$conf.int
ci <- wl(17, 20, 0.95)
expect("Wilson central lower", 0.6395811353, ci[1])
expect("Wilson central upper", 0.9476312541, ci[2])
ci <- wl(3, 5, 0.95)
expect("Wilson n=5 lower", 0.2307242813, ci[1])
expect("Wilson n=5 upper", 0.8823792258, ci[2])
ci <- suppressWarnings(wl(950, 1000, 0.99))
expect("Wilson n=1000 99% lower", 0.9290930273, ci[1])
expect("Wilson n=1000 99% upper", 0.9649749243, ci[2])
ci <- suppressWarnings(wl(0, 10, 0.95))
expect("Wilson x=0 lower is 0", 0, ci[1], tol = 0)
expect("Wilson x=0 upper", 0.2775327999, ci[2])
ci <- suppressWarnings(wl(10, 10, 0.95))
expect("Wilson x=n lower", 0.7224672001, ci[1])
expect("Wilson x=n upper is 1", 1, ci[2], tol = 0)

cat(sprintf("\n%s: %d literal(s) failed verification\n",
            if (fails == 0L) "ALL LITERALS VERIFIED" else "FAILURE", fails))
if (fails > 0L) quit(status = 1)
