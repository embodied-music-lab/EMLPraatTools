# ---------------------------------------------------------------------------
# CROSS-CHECK the hand-implemented Type II and Type III sums of squares against
# car::Anova. Fable's open item 8 in RULING_CONSOLIDATED_KERNELS_20260901:
# the hand-implemented figures must not reach the paper or Josh until a real
# car has confirmed them.
#
# Both fixtures, and the 3x2 case that is the only one able to separate Khuri
# from Type III.
# ---------------------------------------------------------------------------
suppressMessages(library(car))
source("twoway_functions.R")

check <- function(label, d, y, A, B) {
    d[[A]] <- factor(d[[A]]); d[[B]] <- factor(d[[B]])
    f <- as.formula(sprintf("%s ~ %s * %s", y, A, B))

    op <- options(contrasts = c("contr.treatment", "contr.poly"))
    a2 <- car::Anova(lm(f, data = d), type = 2)
    options(op)

    op <- options(contrasts = c("contr.sum", "contr.poly"))
    a3 <- car::Anova(lm(f, data = d), type = 3)
    options(op)

    mine2 <- type2_ss(d, y, A, B); mine3 <- type3_ss(d, y, A, B)
    kh    <- khuri_effects(d, y, A, B)

    car2 <- setNames(a2[["Sum Sq"]], rownames(a2))
    car3 <- setNames(a3[["Sum Sq"]], rownames(a3))
    inter <- paste(A, B, sep = ":")

    rel <- function(a, b) if (is.na(a) || is.na(b) || b == 0) NA else abs(a - b) / abs(b)
    rows <- list(
        c("TypeII  A",  mine2$ssA,  car2[[A]]),
        c("TypeII  B",  mine2$ssB,  car2[[B]]),
        c("TypeII  AB", mine2$ssAB, car2[[inter]]),
        c("TypeIII A",  mine3$ssA,  car3[[A]]),
        c("TypeIII B",  mine3$ssB,  car3[[B]]),
        c("TypeIII AB", mine3$ssAB, car3[[inter]]))

    cat("\n===", label, "===\n")
    worst <- 0
    for (r in rows) {
        mine <- as.numeric(r[2]); theirs <- as.numeric(r[3]); rd <- rel(mine, theirs)
        worst <- max(worst, rd, na.rm = TRUE)
        cat(sprintf("  %-11s mine = %16.8f   car = %16.8f   rel = %.3e  %s\n",
                    r[1], mine, theirs, rd, if (!is.na(rd) && rd < 1e-9) "OK" else "**MISMATCH**"))
    }
    cat(sprintf("  Khuri (not a car type):  A = %.6f  B = %.6f  AB = %.6f\n",
                kh$ssA, kh$ssB, kh$ssAB))
    cat(sprintf("  worst relative difference against car: %.3e -- %s\n",
                worst, if (worst < 1e-9) "CONFIRMED at the standard rule" else "FAILS"))
    invisible(worst)
}

bal <- read.csv("../data/v11_twoway_input.csv", stringsAsFactors = FALSE)
unb <- read.csv("../data/v11_twoway_unbalanced_input.csv", stringsAsFactors = FALSE)
w1 <- check("balanced 2x2 (v11_twoway_input)",             bal, "SPL_dB", "voice_type", "task")
w2 <- check("unbalanced 2x2 (v11_twoway_unbalanced_input)", unb, "SPL_dB", "voice_type", "task")

set.seed(7)
d3 <- do.call(rbind, lapply(list(
  c("A","Sing",4), c("A","Speak",9), c("B","Sing",7),
  c("B","Speak",3), c("C","Sing",5), c("C","Speak",8)),
  function(z) data.frame(g = z[1], t = z[2],
    y = rnorm(as.integer(z[3]), mean = 50 + 10 * match(z[1], c("A","B","C")), sd = 6))))
w3 <- check("unbalanced 3x2 (separates Khuri from Type III)", d3, "y", "g", "t")

pb <- read.delim("../data/peterson_barney_1952.tsv", stringsAsFactors = FALSE)
pb$F0 <- as.numeric(pb$F0)
w4 <- check("Peterson-Barney, F0 by Vowel x Type (10 levels)", pb, "F0", "Vowel", "Type")

cat(sprintf("\nWORST ACROSS ALL FIXTURES: %.3e\n", max(w1, w2, w3, w4)))
