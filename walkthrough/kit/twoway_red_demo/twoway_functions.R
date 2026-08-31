# ============================================================================
# twoway_functions.R -- shared, dependency-free two-way ANOVA computations
# for the red demo (mailbox/to-opus/WORK_ORDER_TWOWAY_KERNEL_2026-08-31.md).
# Sourced by khuri_vs_direct_red_demo.R (the fixture-based demonstration)
# and peterson_barney_canonical_check.R (the Peterson-Barney canonical
# check, once Ian's export lands). Needs only base R -- no packages,
# because `car` is not installed in this environment (verified:
# install.packages("car") fails, and there is no network access to CRAN
# either) and neither script should block on that.
#
# All four functions require a COMPLETE design (every A x B cell non-empty).
# That is true of every fixture and of the Peterson-Barney table (30 cells,
# all populated); none of these functions handles missing cells.
# ============================================================================

fmt <- function(x, d = 4) formatC(x, digits = d, format = "f")

# ----------------------------------------------------------------------------
# Khuri (1998) unweighted-means method: effect sums of squares, computed
# directly from unweighted cell/marginal means -- the equations the work
# order specifies and the plugin's planned kernel targets.
#   n_h = rs / sum(1/n_ij)
#   SS_A  = n_h * s * sum_i (ybar_i. - ybar..)^2         [unweighted means]
#   SS_B  = n_h * r * sum_j (ybar_.j - ybar..)^2
#   SS_AB = n_h * sum_ij (ybar_ij - ybar_i. - ybar_.j + ybar..)^2
# where ybar_i., ybar_.j, ybar.. are UNWEIGHTED averages of the cell means
# (each cell counted once, regardless of n_ij). Also returns the "wrong"
# Total (SS_T centered on the UNWEIGHTED grand mean, i.e. the mean of the
# cell means) -- this is what Praat's built-in subtracts the effect sums
# from to recover Error.
# ----------------------------------------------------------------------------
khuri_effects <- function(d, y, A, B) {
    d[[A]] <- factor(d[[A]]); d[[B]] <- factor(d[[B]])
    levA <- levels(d[[A]]); levB <- levels(d[[B]])
    r <- length(levA); s <- length(levB)

    cellN <- matrix(NA_real_, r, s, dimnames = list(levA, levB))
    cellMean <- matrix(NA_real_, r, s, dimnames = list(levA, levB))
    for (i in seq_along(levA)) for (j in seq_along(levB)) {
        sub <- d[[y]][d[[A]] == levA[i] & d[[B]] == levB[j]]
        cellN[i, j] <- length(sub)
        cellMean[i, j] <- mean(sub)
    }
    if (!all(cellN >= 1)) {
        stop("khuri_effects: design has an empty A x B cell; Khuri's ",
             "unweighted-means method (and this implementation) needs ",
             "every cell non-empty. Empty cells: ",
             paste(which(cellN == 0, arr.ind = TRUE), collapse = ", "))
    }

    n_h <- (r * s) / sum(1 / cellN)

    rowMean <- rowMeans(cellMean)   # unweighted: mean of s cell means
    colMean <- colMeans(cellMean)   # unweighted: mean of r cell means
    grandU  <- mean(cellMean)       # unweighted: mean of all rs cell means

    ssA  <- n_h * s * sum((rowMean - grandU)^2)
    ssB  <- n_h * r * sum((colMean - grandU)^2)
    ssAB <- n_h * sum(sapply(seq_along(levA), function(i)
              sapply(seq_along(levB), function(j)
                (cellMean[i, j] - rowMean[i] - colMean[j] + grandU)^2)))

    dfA <- r - 1; dfB <- s - 1; dfAB <- dfA * dfB

    ssT_unweighted <- sum((d[[y]] - grandU)^2)
    dfT <- nrow(d) - 1

    list(r = r, s = s, rs = r * s, n_h = n_h, levA = levA, levB = levB,
         cellN = cellN, cellMean = cellMean, grandU = grandU,
         ssA = ssA, ssB = ssB, ssAB = ssAB, dfA = dfA, dfB = dfB, dfAB = dfAB,
         ssT_unweighted = ssT_unweighted, dfT = dfT)
}

# ----------------------------------------------------------------------------
# Correct direct computation. SS_E pooled within-cell; Total about the
# ordinary observation-weighted grand mean.
#   SS_E = sum_ijk (y_ijk - ybar_ij)^2 = sum(y^2) - sum_ij T_ij^2/n_ij
#   df_E = N - rs; MS_E = SS_E/df_E
#   SS_T = sum(y^2) - T^2/N  (about the weighted grand mean)
# Implemented via centred sums (numerically equivalent, avoids catastrophic
# cancellation in the sum(y^2) - T^2/N form on data far from zero).
# ----------------------------------------------------------------------------
direct_residual_total <- function(d, y, A, B) {
    d[[A]] <- factor(d[[A]]); d[[B]] <- factor(d[[B]])
    r <- nlevels(d[[A]]); s <- nlevels(d[[B]])
    N <- nrow(d)
    grandW <- mean(d[[y]])
    cellMean <- ave(d[[y]], d[[A]], d[[B]])
    ssE <- sum((d[[y]] - cellMean)^2)
    dfE <- N - r * s
    ssT <- sum((d[[y]] - grandW)^2)
    dfT <- N - 1
    list(ssE = ssE, dfE = dfE, msE = ssE / dfE, ssT = ssT, dfT = dfT,
         grandW = grandW, N = N)
}

# ----------------------------------------------------------------------------
# Type II SS via RSS differences (car::Anova(fit, type=2) reduces to exactly
# this for a two-factor model with an interaction: each main effect is
# tested after the OTHER main effect but WITHOUT the interaction in the
# model; the interaction -- the highest-order term -- gets the same SS
# under Type I (last), Type II and Type III).
# ----------------------------------------------------------------------------
type2_ss <- function(d, y, A, B) {
    f <- as.formula(paste(y, "~", A, "*", B))
    fit_full <- lm(f, data = d)
    fit_ab   <- lm(as.formula(paste(y, "~", A, "+", B)), data = d)
    fit_a    <- lm(as.formula(paste(y, "~", A)), data = d)
    fit_b    <- lm(as.formula(paste(y, "~", B)), data = d)
    RSS <- function(fit) sum(resid(fit)^2)
    ssA  <- RSS(fit_b) - RSS(fit_ab)
    ssB  <- RSS(fit_a) - RSS(fit_ab)
    ssAB <- RSS(fit_ab) - RSS(fit_full)
    list(ssA = ssA, ssB = ssB, ssAB = ssAB,
         dfA = fit_a$rank - 1, dfB = fit_b$rank - 1,
         dfAB = (fit_full$rank - fit_ab$rank),
         ssE = RSS(fit_full), dfE = fit_full$df.residual)
}

# ----------------------------------------------------------------------------
# Type III SS with sum-to-zero contrasts, via a Wald quadratic form:
#   Vsub = vcov(fit3)[term_cols, term_cols] = MSE * (X'X)^-1_sub
#   Wald  = beta_term' Vsub^-1 beta_term = beta_term' [(X'X)^-1_sub]^-1 beta_term / MSE
#   SS_III(term) = Wald * MSE
# This is the standard general-linear-hypothesis definition of Type III SS
# (what SAS/car compute for a full-rank model) -- implemented directly
# because `car` is not installed here (see the note printed by
# khuri_vs_direct_red_demo.R).
# ----------------------------------------------------------------------------
type3_ss <- function(d, y, A, B) {
    f <- as.formula(paste(y, "~", A, "*", B))
    fit3 <- lm(f, data = d, contrasts = setNames(list(contr.sum, contr.sum), c(A, B)))
    V <- vcov(fit3)
    mse <- sum(resid(fit3)^2) / fit3$df.residual
    asgn <- attr(model.matrix(fit3), "assign")
    termlabs <- attr(terms(fit3), "term.labels")
    out <- list()
    for (k in seq_along(termlabs)) {
        idx <- which(asgn == k)
        beta <- coef(fit3)[idx]
        Vsub <- V[idx, idx, drop = FALSE]
        wald <- as.numeric(t(beta) %*% solve(Vsub) %*% beta)
        out[[termlabs[k]]] <- list(ss = wald * mse, df = length(idx))
    }
    names(out) <- c("A", "B", "AB")
    list(ssA = out$A$ss, ssB = out$B$ss, ssAB = out$AB$ss,
         dfA = out$A$df, dfB = out$B$df, dfAB = out$AB$df,
         ssE = sum(resid(fit3)^2), dfE = fit3$df.residual)
}

# ----------------------------------------------------------------------------
# Both full two-way tables (Praat's wrong subtraction method, and the
# correct direct method) for one dataset, plus the divergence summary.
# Returns a list; does not print. Callers print what they need.
# ----------------------------------------------------------------------------
twoway_both_tables <- function(d, y, A, B) {
    kh <- khuri_effects(d, y, A, B)
    dr <- direct_residual_total(d, y, A, B)

    ssE_wrong <- kh$ssT_unweighted - kh$ssA - kh$ssB - kh$ssAB
    dfE_wrong <- kh$dfT - kh$dfA - kh$dfB - kh$dfAB
    msE_wrong <- ssE_wrong / dfE_wrong
    fA_wrong  <- (kh$ssA / kh$dfA) / msE_wrong
    fB_wrong  <- (kh$ssB / kh$dfB) / msE_wrong
    fAB_wrong <- (kh$ssAB / kh$dfAB) / msE_wrong
    pA_wrong  <- pf(fA_wrong,  kh$dfA,  dfE_wrong, lower.tail = FALSE)
    pB_wrong  <- pf(fB_wrong,  kh$dfB,  dfE_wrong, lower.tail = FALSE)
    pAB_wrong <- pf(fAB_wrong, kh$dfAB, dfE_wrong, lower.tail = FALSE)

    msE_ok <- dr$msE
    fA_ok  <- (kh$ssA / kh$dfA) / msE_ok
    fB_ok  <- (kh$ssB / kh$dfB) / msE_ok
    fAB_ok <- (kh$ssAB / kh$dfAB) / msE_ok
    pA_ok  <- pf(fA_ok,  kh$dfA,  dr$dfE, lower.tail = FALSE)
    pB_ok  <- pf(fB_ok,  kh$dfB,  dr$dfE, lower.tail = FALSE)
    pAB_ok <- pf(fAB_ok, kh$dfAB, dr$dfE, lower.tail = FALSE)

    list(kh = kh, dr = dr,
         wrong = list(ssE = ssE_wrong, dfE = dfE_wrong, msE = msE_wrong,
                      fA = fA_wrong, fB = fB_wrong, fAB = fAB_wrong,
                      pA = pA_wrong, pB = pB_wrong, pAB = pAB_wrong,
                      ssT = kh$ssT_unweighted, dfT = kh$dfT),
         correct = list(ssE = dr$ssE, dfE = dr$dfE, msE = msE_ok,
                        fA = fA_ok, fB = fB_ok, fAB = fAB_ok,
                        pA = pA_ok, pB = pB_ok, pAB = pAB_ok,
                        ssT = dr$ssT, dfT = dr$dfT))
}
