# ---------------------------------------------------------------------------
# WHY THIS FILE EXISTS.
#
# Khuri's unweighted-means effect sums and Type III sums of squares coincide
# for a factor with exactly TWO levels. Every two-way fixture in this kit --
# v11_twoway_input.csv and the new v11_twoway_unbalanced_input.csv alike -- is
# 2x2, so no fixture here can tell the two methods apart. The unbalanced
# fixture exposes the error-term bug and still cannot expose this.
#
# This script uses a 3 x 2 unbalanced design, which can. It is the smallest
# case that separates the method the plugin currently inherits from Praat's
# built-in (Khuri unweighted) from the method the plugin's own comments claim
# it computes (Type III), and from the method the kit's R oracle actually
# computes (Type II, car::Anova type = 2).
#
# The three answers differ by whole percent, not by 1e-8. That is a
# methodological disagreement, not a precision ceiling, and no tolerance
# clause should ever be written to absorb it.
# ---------------------------------------------------------------------------

source("twoway_functions.R")
set.seed(7)
# 3-level x 2-level, unbalanced
d <- do.call(rbind, lapply(list(
  c("A","Sing",4), c("A","Speak",9), c("B","Sing",7),
  c("B","Speak",3), c("C","Sing",5),  c("C","Speak",8)),
  function(z) data.frame(g=z[1], t=z[2],
    y=rnorm(as.integer(z[3]), mean=50+10*match(z[1],c("A","B","C")), sd=6))))
d$g <- factor(d$g); d$t <- factor(d$t)
k  <- khuri_effects(d, "y", "g", "t")
t2 <- type2_ss(d, "y", "g", "t")
t3 <- type3_ss(d, "y", "g", "t")
cat(sprintf("cells n: %s   N=%d\n", paste(as.vector(table(d$g,d$t)), collapse=","), nrow(d)))
for (nm in c("ssA","ssB","ssAB")) cat(sprintf("%-5s Khuri=%12.4f  TypeIII=%12.4f  TypeII=%12.4f   Khuri vs III: %7.3f%%\n",
  nm, k[[nm]], t3[[nm]], t2[[nm]], 100*abs(k[[nm]]-t3[[nm]])/t3[[nm]]))
