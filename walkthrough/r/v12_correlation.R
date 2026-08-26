# v12 — Pearson and Spearman correlation, base R only.
# t_from_r is the plugin's own large-sample approximation formula for the
# Spearman t/df line (see the note in validate/v12_correlation_orchestrator.R);
# it is not a helpers.R function, just algebra, reproduced here for parity.

d <- read.csv("evidence/csv/v12_correlation_input.csv", stringsAsFactors = FALSE)
x <- d$speaking_F0_Hz
y <- d$singing_F0_Hz
n <- length(x)

t_from_r <- function(r, n) r * sqrt((n - 2) / (1 - r^2))

cat(sprintf("N                   %d\n\n", n))

pe <- cor.test(x, y, method = "pearson")
cat("-- Pearson Correlation --\n")
cat(sprintf("r                   %.4f\n", unname(pe$estimate)))
cat(sprintf("t                   %.3f\n", unname(pe$statistic)))
cat(sprintf("df                  %d\n", unname(pe$parameter)))
cat(sprintf("p                   %.3g\n\n", pe$p.value))

sp <- suppressWarnings(cor.test(x, y, method = "spearman"))
rho <- unname(sp$estimate)
t_s <- t_from_r(rho, n)
p_s <- 2 * pt(-abs(t_s), n - 2)
cat("-- Spearman Correlation --\n")
cat(sprintf("rho                 %.4f\n", rho))
cat(sprintf("t (approx, from rho) %.3f\n", t_s))
cat(sprintf("df                  %d\n", n - 2))
cat(sprintf("p (approx, from t)  %.3g\n", p_s))
cat(sprintf("p (exact, cor.test) %.3g   [cor.test's own S-statistic exact/AS89 p; NOT what's shown above]\n", sp$p.value))
