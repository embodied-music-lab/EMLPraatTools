# ============================================================================
# EML Stats : R Verification — Inferential Statistics (Batch 6)
# ============================================================================
# Independent verification of reference values for test-inferential-batch6.praat
# Date: 4 March 2026
#
# Run in RStudio or R console. Compare output against scipy values in
# the test file comments and handoff document §7.
#
# ATTRIBUTION
# Framework: EML Praat Assistant by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# ============================================================================

cat("============================================================\n")
cat("BATCH 6 R VERIFICATION\n")
cat("============================================================\n\n")

# ------------------------------------------------------------------
# Section 1: One-way ANOVA — Test Sets 1–3
# ------------------------------------------------------------------

cat("── Test Set 1: One-way, 3 groups, clear effect ──\n\n")

g1 <- c(23, 25, 27, 22, 26)
g2 <- c(30, 33, 29, 31, 34)
g3 <- c(18, 20, 22, 19, 17)

df1 <- data.frame(
  value = c(g1, g2, g3),
  group = factor(rep(c("Group1", "Group2", "Group3"), each = 5))
)

fit1 <- aov(value ~ group, data = df1)
s1 <- summary(fit1)
cat("ANOVA Table:\n")
print(s1)
cat(sprintf("F = %.10f\n", s1[[1]]$`F value`[1]))
cat(sprintf("p = %.10f\n", s1[[1]]$`Pr(>F)`[1]))
cat(sprintf("SS_between = %.4f, SS_within = %.4f\n",
            s1[[1]]$`Sum Sq`[1], s1[[1]]$`Sum Sq`[2]))
cat(sprintf("df: between=%d, within=%d\n",
            s1[[1]]$Df[1], s1[[1]]$Df[2]))
cat(sprintf("MS_between = %.4f, MS_within = %.4f\n\n",
            s1[[1]]$`Mean Sq`[1], s1[[1]]$`Mean Sq`[2]))

cat("Tukey HSD:\n")
tukey1 <- TukeyHSD(fit1)
print(tukey1)
cat("\n")


cat("── Test Set 2: One-way, 3 groups, no effect ──\n\n")

g1b <- c(10, 11, 12, 10.5, 11.5)
g2b <- c(10.5, 11, 11.5, 10, 12)
g3b <- c(11, 10.5, 11.5, 10, 12)

df2 <- data.frame(
  value = c(g1b, g2b, g3b),
  group = factor(rep(c("Group1", "Group2", "Group3"), each = 5))
)

fit2 <- aov(value ~ group, data = df2)
s2 <- summary(fit2)
print(s2)
cat(sprintf("F = %.10f\n", s2[[1]]$`F value`[1]))
cat(sprintf("p = %.10f\n\n", s2[[1]]$`Pr(>F)`[1]))


cat("── Test Set 3: One-way, 2 groups ──\n\n")

g1c <- c(5, 7, 9, 6, 8)
g2c <- c(10, 12, 11, 13, 14)

df3 <- data.frame(
  value = c(g1c, g2c),
  group = factor(rep(c("Group1", "Group2"), each = 5))
)

fit3 <- aov(value ~ group, data = df3)
s3 <- summary(fit3)
print(s3)
cat(sprintf("F = %.10f\n", s3[[1]]$`F value`[1]))
cat(sprintf("p = %.10f\n\n", s3[[1]]$`Pr(>F)`[1]))


# ------------------------------------------------------------------
# Section 2: Two-way ANOVA — Test Sets 4–5
# ------------------------------------------------------------------

cat("── Test Set 4: Two-way 2x2, no interaction ──\n\n")

df4 <- data.frame(
  value = c(10, 12, 11, 13, 14,   # Control-Male
            15, 14, 16, 13, 17,   # Control-Female
            20, 22, 19, 21, 23,   # Drug-Male
            25, 27, 24, 26, 28),  # Drug-Female
  Treatment = factor(rep(c("Control", "Drug"), each = 10)),
  Sex = factor(rep(rep(c("Male", "Female"), each = 5), 2))
)

fit4 <- aov(value ~ Treatment * Sex, data = df4)
s4 <- summary(fit4)
cat("ANOVA Table:\n")
print(s4)
cat("\n")


cat("── Test Set 5: Two-way 2x2, with interaction ──\n\n")

df5 <- data.frame(
  value = c(10, 12, 11, 13, 9,   # A-Male
            20, 22, 21, 23, 19,   # A-Female
            18, 20, 19, 21, 17,   # B-Male
            19, 21, 20, 22, 18),  # B-Female
  FactorA = factor(rep(c("A", "B"), each = 10)),
  FactorB = factor(rep(rep(c("Male", "Female"), each = 5), 2))
)

fit5 <- aov(value ~ FactorA * FactorB, data = df5)
s5 <- summary(fit5)
cat("ANOVA Table:\n")
print(s5)
cat("\n")


# ------------------------------------------------------------------
# Section 3: Tukey HSD — Test Sets 6–7
# ------------------------------------------------------------------

cat("── Test Set 6: Tukey standalone, 4 groups ──\n\n")

df6 <- data.frame(
  value = c(5, 6, 7, 5.5, 6.5,       # Group1
            8, 9, 10, 8.5, 9.5,       # Group2
            5.5, 6, 7.5, 6, 5,        # Group3
            12, 13, 14, 12.5, 13.5),  # Group4
  group = factor(rep(c("Group1", "Group2", "Group3", "Group4"), each = 5))
)

fit6 <- aov(value ~ group, data = df6)
s6 <- summary(fit6)
cat("ANOVA Table:\n")
print(s6)
cat(sprintf("F = %.4f\n", s6[[1]]$`F value`[1]))
cat(sprintf("p = %.10f\n\n", s6[[1]]$`Pr(>F)`[1]))

cat("Tukey HSD:\n")
tukey6 <- TukeyHSD(fit6)
print(tukey6)
cat("\n")


cat("── Test Set 7: Tukey chaining (same data as Test Set 1) ──\n\n")

cat("Tukey HSD (from Test Set 1 fit):\n")
cat("Already printed above in Test Set 1.\n")
cat("Key p-values:\n")
cat(sprintf("  Group2-Group1: %e\n", tukey1$group["Group2-Group1", "p adj"]))
cat(sprintf("  Group3-Group1: %e\n", tukey1$group["Group3-Group1", "p adj"]))
cat(sprintf("  Group3-Group2: %e\n", tukey1$group["Group3-Group2", "p adj"]))
cat("\n")


cat("============================================================\n")
cat("END OF VERIFICATION\n")
cat("============================================================\n")
