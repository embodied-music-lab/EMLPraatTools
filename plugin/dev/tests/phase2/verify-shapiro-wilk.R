# ============================================================================
# R Verification Script for @emlShapiroWilk
# Generates reference values to compare against Praat implementation
# ============================================================================

cat("Shapiro-Wilk Reference Values (R)\n")
cat("==================================\n\n")

# Test 1: n=5, normal-ish
d1 <- c(2.3, 1.8, 2.5, 2.1, 2.0)
r1 <- shapiro.test(d1)
cat(sprintf("Test 1 (n=5): W = %.10f, p = %.10f\n", r1$statistic, r1$p.value))

# Test 2: n=3, edge
d2 <- c(1.0, 2.0, 3.0)
r2 <- shapiro.test(d2)
cat(sprintf("Test 2 (n=3): W = %.10f, p = %.10f\n", r2$statistic, r2$p.value))

# Test 3: n=4
d3 <- c(3.1, 4.2, 3.8, 4.5)
r3 <- shapiro.test(d3)
cat(sprintf("Test 3 (n=4): W = %.10f, p = %.10f\n", r3$statistic, r3$p.value))

# Test 4: n=10
d4 <- c(107.45, 97.93, 109.72, 122.85, 96.49, 96.49, 123.69, 111.51, 92.96, 108.14)
r4 <- shapiro.test(d4)
cat(sprintf("Test 4 (n=10): W = %.10f, p = %.10f\n", r4$statistic, r4$p.value))

# Test 5: n=20, uniform
d5 <- c(8.86, 0.78, 9.8, 2.48, 7.53, 5.27, 9.08, 8.84, 0.89, 5.17,
        3.44, 2.12, 3.61, 2.71, 7.62, 4.78, 0.99, 2.75, 7.94, 5.14)
r5 <- shapiro.test(d5)
cat(sprintf("Test 5 (n=20): W = %.10f, p = %.10f\n", r5$statistic, r5$p.value))

# Test 6: n=30, normal
set.seed(123)
d6 <- round(rnorm(30, 50, 10), 2)
r6 <- shapiro.test(d6)
cat(sprintf("Test 6 (n=30 normal): W = %.10f, p = %.10f\n", r6$statistic, r6$p.value))
cat(sprintf("  data: %s\n", paste(d6, collapse=", ")))

# Test 7: n=30, skewed
set.seed(456)
d7 <- round(rexp(30, 1/5), 2)
r7 <- shapiro.test(d7)
cat(sprintf("Test 7 (n=30 skewed): W = %.10f, p = %.10f\n", r7$statistic, r7$p.value))

# Test 8: n=100, normal
set.seed(789)
d8 <- round(rnorm(100, 0, 1), 4)
r8 <- shapiro.test(d8)
cat(sprintf("Test 8 (n=100): W = %.10f, p = %.10f\n", r8$statistic, r8$p.value))

cat("\nNote: R and Python random seeds produce different sequences.\n")
cat("Compare W and p values against Praat implementation outputs.\n")
