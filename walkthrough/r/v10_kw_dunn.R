# v10 — Kruskal-Wallis with Dunn's post hoc (Holm-adjusted), base R only.
# epsilon-squared, dunn_test, holm_adjust and rank_biserial_indep are LIFTED
# verbatim from validate/helpers.R -- base R has no direct function for
# Dunn's test or epsilon-squared.

d <- read.csv("evidence/csv/v10_kw_dunn_input.csv", stringsAsFactors = FALSE)
d$voice_type <- factor(d$voice_type, levels = c("Soprano", "Mezzo", "Alto"))
g <- split(d$SPL_dB, d$voice_type)
N <- nrow(d)

# --- lifted from helpers.R --------------------------------------------------
epsilon_squared <- function(H, N) H / ((N^2 - 1) / (N + 1))

dunn_test <- function(x, g) {
    ok <- !is.na(x) & !is.na(g)
    x <- x[ok]; g <- factor(g[ok])
    N <- length(x); r <- rank(x)
    tie <- table(r)
    Tc <- sum(tie^3 - tie) / (12 * (N - 1))
    lv <- levels(g)
    Rbar <- tapply(r, g, mean); n <- tapply(r, g, length)
    z <- matrix(NA_real_, length(lv), length(lv), dimnames = list(lv, lv))
    p <- z
    for (i in seq_along(lv)) for (j in seq_along(lv)) {
        if (i == j) next
        se <- sqrt((N * (N + 1) / 12 - Tc) * (1 / n[i] + 1 / n[j]))
        z[i, j] <- (Rbar[i] - Rbar[j]) / se
        p[i, j] <- 2 * pnorm(-abs(z[i, j]))
    }
    list(z = z, p = p, meanrank = Rbar, n = n, levels = lv)
}

holm_adjust <- function(p) {
    m <- length(p); o <- order(p); adj <- numeric(m); run <- 0
    for (i in seq_len(m)) {
        run <- max(run, (m - i + 1) * p[o[i]])
        adj[o[i]] <- min(1, run)
    }
    adj
}

rank_biserial_indep <- function(a, b) {
    U1 <- suppressWarnings(unname(wilcox.test(a, b)$statistic))
    U2 <- length(a) * length(b) - U1
    (U1 - U2) / (length(a) * length(b))
}
# -----------------------------------------------------------------------------

kw <- kruskal.test(SPL_dB ~ voice_type, data = d)
eps2 <- epsilon_squared(unname(kw$statistic), N)

cat("-- Omnibus Test --\n")
cat(sprintf("H                   %.4f\n", unname(kw$statistic)))
cat(sprintf("df                  %d\n", unname(kw$parameter)))
cat(sprintf("Total N             %d\n", N))
cat(sprintf("Groups              %d\n", nlevels(d$voice_type)))
cat(sprintf("p                   %.3g\n", kw$p.value))
cat(sprintf("Epsilon-squared     %.4f\n\n", eps2))

dn <- dunn_test(d$SPL_dB, d$voice_type)
cat("-- Group Mean Ranks --\n")
for (nm in levels(d$voice_type)) {
    cat(sprintf("%-12s N=%-4d MeanRank=%.2f\n", nm, dn$n[nm], dn$meanrank[nm]))
}
cat("\n")

raw <- c(SM = dn$p["Soprano", "Mezzo"],
         SA = dn$p["Soprano", "Alto"],
         MA = dn$p["Mezzo",   "Alto"])
adj <- holm_adjust(raw); names(adj) <- names(raw)

cat("-- Dunn's z-statistics --\n")
print(round(dn$z, 3))
cat("\n-- Dunn's Post-Hoc adjusted p (Holm) --\n")
cat(sprintf("Soprano-Mezzo  %.4g\n", adj[["SM"]]))
cat(sprintf("Soprano-Alto   %.4g\n", adj[["SA"]]))
cat(sprintf("Mezzo-Alto     %.4g\n\n", adj[["MA"]]))

cat("-- Pairwise rank-biserial r --\n")
lv <- levels(d$voice_type)
for (i in seq_along(lv)) for (j in seq_along(lv)) if (i != j) {
    cat(sprintf("%-10s vs %-10s  r = %7.3f\n", lv[i], lv[j], rank_biserial_indep(g[[lv[i]]], g[[lv[j]]])))
}
