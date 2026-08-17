# ============================================================================
# v09 — Compare k groups (ANOVA): orchestrator and Tukey post-hoc
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Covers @emlRunAnovaAnalysis: the ANOVA table it assembles, eta-squared,
# group descriptives, the Tukey HSD matrix, and the pairwise Cohen's d
# matrix. The one-way ANOVA and Tukey primitives already have external
# oracles; what is new here is that the orchestrator fills the right cells.
#
# The matrices are the point. A transposed or mis-indexed post-hoc matrix
# produces entirely correct numbers in the wrong places, and every check
# below reaches its cell through @printed_cell, which resolves the column
# from the matrix's own printed header — so a transposed matrix fails.
# Asserting the set of values would pass a transposition.
#
# EVERY REPORTED VALUE IS READ FROM THE COMMITTED CAPTURE. No number below
# is typed in by hand; see the note at the head of v08.
#
# PROVENANCE — READ THIS BEFORE CITING THIS SCRIPT AS GUI EVIDENCE.
#
# ORIGINALLY DRIVEN 5 August 2026 through the real GUI:
#   New > EML Stats & Graphs > Compare k groups (ANOVA)...
#   Data column SPL_dB, Group column voice_type, Tukey HSD post hoc ON,
#   Group order = Table order.
#
# RE-DRIVEN HEADLESSLY 7 August 2026 for D110, by
# harness/broom_cases/d110_orchestrator_redrive.praat under `praat --run`:
# @emlRunAnovaAnalysis on the same committed input with the same arguments.
# That is the shipping orchestrator the menu calls, on the committed CSV, but
# it is NOT a session someone clicked through. The capture this script reads
# is therefore the same KIND of evidence as v07_r7_axis_info.txt and the v18
# grid, not the same kind as the 5 August GUI captures — see validate/README.md
# §"Two kinds of evidence, and the limit on each".
#
# D110 forced the re-drive: the ANOVA source table's p cell and the Tukey
# matrix moved from fixed$ (p, n) to @emlFormatP's bare APA form, so the
# strings this script reads changed. The re-drive also picked up four
# unrelated changes that had landed in the plugin since 5 August and were
# therefore ABSENT from the committed capture — the report had drifted from
# its evidence:
#   * the Tukey HSD mean-difference / family-wise CI block (D22)
#   * the unconditional Brown-Forsythe equal-spread lines (Ruling 1)
#   * the wizard explanation column, whose default became 1 (D42/D102)
#   * the "p" summary row's bare form with the unrounded value beside it
#     (D9/D28), where the old capture read "p    p < .001"
# None of them changes a number; all of them change what the capture says.
#
# Input:  evidence/csv/v09_anova_tukey_input.csv
# Output: evidence/info/v09_anova_tukey_info.txt
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

d   <- read_input("v09_anova_tukey_input.csv")
cap <- capture("v09_anova_tukey_info.txt")
d$voice_type <- factor(d$voice_type, levels = unique(d$voice_type))
check_true("v09", "table order is Soprano, Mezzo, Alto",
           identical(levels(d$voice_type), c("Soprano", "Mezzo", "Alto")))

fit <- aov(SPL_dB ~ voice_type, data = d)
s   <- summary(fit)[[1]]
ss_b <- s[["Sum Sq"]][1]; ss_w <- s[["Sum Sq"]][2]
df_b <- s[["Df"]][1];     df_w <- s[["Df"]][2]

# --- ANOVA table -----------------------------------------------------------
# V4, 6 Aug 2026. "Soprano" matches 5 lines in this capture (the descriptives
# row, plus the header and body rows of the two post-hoc matrices), "Mezzo"
# and "Alto" 3 each. Occurrence 1 is the descriptives row and is what these
# reads want, but nothing said so, and nothing checked it -- a capture whose
# block order changed would have read a matrix row into a mean without a
# murmur. expect_hits states the belief and makes a wrong one fatal.
check("v09", "SS between", printed(cap, "Between", 1), ss_b, tol = 5e-3)
check("v09", "SS within",  printed(cap, "Within", 1), ss_w, tol = 5e-3)
check("v09", "SS total",  printed(cap, "Total", 1), ss_b + ss_w, tol = 1e-2)
check("v09", "df between", printed(cap, "Between", 2), df_b, tol = 0)
check("v09", "df within",  printed(cap, "Within", 2), df_w, tol = 0)
check("v09", "MS between", printed(cap, "Between", 3), ss_b / df_b, tol = 5e-3)
check("v09", "MS within",  printed(cap, "Within", 3), ss_w / df_w, tol = 5e-3)
check("v09", "F (ANOVA table row)", printed(cap, "Between", 4), unname(s[["F value"]][1]), tol = 5e-5)
check("v09", "F (summary line)",     printed(cap, "F"),           unname(s[["F value"]][1]), tol = 5e-5)
# D110. This cell used to print fixed$ (p, 6) — "0.000019", full precision and
# a leading zero, under a column headed "p", in a report that spelled the same
# quantity ".584" further down. It now carries @emlFormatP's bare APA form, so
# the table row FLOORS. The check changed with it: the row is asserted to say
# "< .001" and R is asserted to agree, which is what the string now claims.
#
# The precision is not lost, and that is the point of the pair of checks
# below. @emlReportPWithExact restates the unrounded p beside the floored
# label in the "p" summary row, so the exact value is still IN THE REPORT and
# is still read out of the capture here — it just moved out of the table cell.
# If a future edit floors the summary row too, the second check goes red.
check_floored("v09", "p is floored in the ANOVA table row", cap, "Between",
              unname(s[["Pr(>F)"]][1]), field = 5)
check_floored("v09", "p also floored in the summary line", cap, "p",
              unname(s[["Pr(>F)"]][1]))
exact_field <- printed_str(cap, "p", 2)
check_true("v09", "the floored summary p is followed by a parenthesised exact value",
           grepl("^\\(.*\\)$", exact_field))
check("v09", "and that exact value is R's p to full double precision",
      as.numeric(gsub("[()]", "", exact_field)), unname(s[["Pr(>F)"]][1]),
      tol = 1e-18)

# Total SS must equal between + within. Trivially true in R; the check is
# that the plugin PRINTS a total consistent with the parts it printed.
check("v09", "printed SS total equals printed between + within",
      printed(cap, "Total", 1),
      printed(cap, "Between", 1) + printed(cap, "Within", 1), tol = 1e-9)

# --- effect size -----------------------------------------------------------
# Printed as one field, "eta-squared = 0.4046", so the label is read as a
# string and the number taken off the end. Reading the WHOLE field also
# checks that the plugin still calls it eta-squared and has not silently
# switched to omega-squared or partial eta-squared, which would be a
# different quantity under an unchanged number of decimals.
eta_field <- printed_str(cap, "Effect size")
check_true("v09", "effect size is labelled eta-squared",
           grepl("^eta-squared", eta_field))
check("v09", "eta-squared", as.numeric(sub(".*=\\s*", "", eta_field)),
      ss_b / (ss_b + ss_w), tol = 5e-5)

# --- group descriptives ----------------------------------------------------
g <- split(d$SPL_dB, d$voice_type)
check("v09", "N Soprano", printed(cap, "Soprano", 1, 1, expect_hits = 5), length(g$Soprano), tol = 0)
check("v09", "mean Soprano", printed(cap, "Soprano", 2, 1, expect_hits = 5), mean(g$Soprano), tol = 5e-3)
check("v09", "mean Mezzo", printed(cap, "Mezzo", 2, 1, expect_hits = 3), mean(g$Mezzo), tol = 5e-3)
check("v09", "mean Alto", printed(cap, "Alto", 2, 1, expect_hits = 3), mean(g$Alto), tol = 5e-3)
check("v09", "SD Soprano", printed(cap, "Soprano", 3, 1, expect_hits = 5), sd(g$Soprano), tol = 5e-3)
check("v09", "SD Mezzo", printed(cap, "Mezzo", 3, 1, expect_hits = 3), sd(g$Mezzo), tol = 5e-3)
check("v09", "SD Alto", printed(cap, "Alto", 3, 1, expect_hits = 3), sd(g$Alto), tol = 5e-3)
check("v09", "median Soprano", printed(cap, "Soprano", 4, 1, expect_hits = 5), median(g$Soprano), tol = 5e-3)
check("v09", "median Mezzo", printed(cap, "Mezzo", 4, 1, expect_hits = 3), median(g$Mezzo), tol = 5e-3)
check("v09", "median Alto", printed(cap, "Alto", 4, 1, expect_hits = 3), median(g$Alto), tol = 5e-3)

# --- Tukey HSD -------------------------------------------------------------
tk <- TukeyHSD(fit)$voice_type
tp <- function(x, y) {
    nm <- rownames(tk)
    i <- which(nm == paste0(x, "-", y)); if (length(i)) return(tk[i, "p adj"])
    i <- which(nm == paste0(y, "-", x)); tk[i, "p adj"]
}
# D110. The matrix printed fixed$ (p, 4) — "0.0018" — and these tolerances
# were 5e-5, half of that last decimal place. The cells now carry
# @emlFormatP's bare APA form, which is THREE decimals (".002"), so the
# tolerance is 5e-4 on the same reasoning: half of the last place the plugin
# actually prints. This is a coarser printed value, not a looser check —
# 5e-4 is exactly as tight as the new format allows, and a wrong number is
# still caught. printed_cell reads ".002" through as.numeric, which parses a
# bare leading point.
check("v09", "Tukey p Soprano-Mezzo", printed_cell(cap, "Tukey HSD", "Soprano", "Mezzo"), tp("Soprano", "Mezzo"), tol = 5e-4)
check("v09", "Tukey p Mezzo-Alto",    printed_cell(cap, "Tukey HSD", "Mezzo", "Alto"),    tp("Mezzo", "Alto"), tol = 5e-4)
check_true("v09", "the Tukey matrix uses the bare APA form (no leading zero)",
           grepl("^\\.[0-9]{3}$",
                 printed_cell(cap, "Tukey HSD", "Soprano", "Mezzo", as_string = TRUE)))
check_true("v09", "Tukey p Soprano-Alto is floored in the matrix",
           grepl("<", printed_cell(cap, "Tukey HSD", "Soprano", "Alto", as_string = TRUE)))
check_true("v09", "and R agrees it is below .001", tp("Soprano", "Alto") < 0.001)

# The matrix is symmetric on screen. If the orchestrator filled only one
# triangle and mirrored the wrong index, this is where it shows.
check("v09", "Tukey matrix is symmetric as printed: [S,M] = [M,S]",
      printed_cell(cap, "Tukey HSD", "Soprano", "Mezzo"),
      printed_cell(cap, "Tukey HSD", "Mezzo", "Soprano"), tol = 1e-12)
check("v09", "Tukey matrix is symmetric as printed: [M,A] = [A,M]",
      printed_cell(cap, "Tukey HSD", "Mezzo", "Alto"),
      printed_cell(cap, "Tukey HSD", "Alto", "Mezzo"), tol = 1e-12)

# --- Tukey mean differences and family-wise CIs ----------------------------
# This block (D22) landed in the plugin after the 5 August GUI drive, so it
# was absent from the old capture and unchecked anywhere in the suite. The
# D110 re-drive brought twelve numbers into committed evidence; they are
# checked here rather than left sitting in a capture that nothing reads.
#
# The rows read "Soprano − Mezzo   5.5295   [1.8896, 9.1694]" and the
# separator is U+2212 MINUS SIGN, not a hyphen, so the row is matched on the
# group names rather than on the dash. TukeyHSD gives the same three
# quantities; the plugin builds its half-width from qCritical and MS_within
# instead, which is what makes this an independent path rather than a restatement.
tci <- function(x, y) {
    nm <- rownames(tk)
    i <- which(nm == paste0(x, "-", y))
    if (length(i)) return(tk[i, c("diff", "lwr", "upr")])
    i <- which(nm == paste0(y, "-", x))
    -tk[i, c("diff", "upr", "lwr")]          # reversed pair: negate and swap
}
tci_row <- function(x, y) {
    ln <- grep(paste0("^", x, "\\s+\\S+\\s+", y, "\\s"), trimws(cap$lines),
               value = TRUE)
    stopifnot(length(ln) == 1)
    as.numeric(regmatches(ln, gregexpr("-?[0-9]+\\.[0-9]+", ln))[[1]])
}
for (pr in list(c("Soprano", "Mezzo"), c("Soprano", "Alto"), c("Mezzo", "Alto"))) {
    got <- tci_row(pr[1], pr[2]); want <- unname(tci(pr[1], pr[2]))
    lab <- paste(pr[1], "vs", pr[2])
    check("v09", paste("Tukey mean difference", lab),  got[1], want[1], tol = 5e-5)
    check("v09", paste("Tukey CI lower", lab),         got[2], want[2], tol = 5e-5)
    check("v09", paste("Tukey CI upper", lab),         got[3], want[3], tol = 5e-5)
    check_true("v09", paste("printed CI brackets the printed difference,", lab),
               got[2] <= got[1] && got[1] <= got[3])
}

# --- pairwise Cohen's d ----------------------------------------------------
# The printed matrix is antisymmetric: cell [i,j] = -cell [j,i]. That is a
# statement about which group was passed first, and it is exactly the
# property a mis-ordered call would break.
check("v09", "d Soprano vs Mezzo", printed_cell(cap, "Pairwise Effect Sizes", "Soprano", "Mezzo"), cohens_d(g$Soprano, g$Mezzo), tol = 5e-4)
check("v09", "d Soprano vs Alto", printed_cell(cap, "Pairwise Effect Sizes", "Soprano", "Alto"), cohens_d(g$Soprano, g$Alto), tol = 5e-4)
check("v09", "d Mezzo vs Alto", printed_cell(cap, "Pairwise Effect Sizes", "Mezzo", "Alto"), cohens_d(g$Mezzo, g$Alto), tol = 5e-4)
check("v09", "d Mezzo vs Soprano", printed_cell(cap, "Pairwise Effect Sizes", "Mezzo", "Soprano"), cohens_d(g$Mezzo, g$Soprano), tol = 5e-4)
check("v09", "d Alto vs Soprano", printed_cell(cap, "Pairwise Effect Sizes", "Alto", "Soprano"), cohens_d(g$Alto, g$Soprano), tol = 5e-4)
check("v09", "d Alto vs Mezzo", printed_cell(cap, "Pairwise Effect Sizes", "Alto", "Mezzo"), cohens_d(g$Alto, g$Mezzo), tol = 5e-4)
check("v09", "printed Cohen's d matrix is antisymmetric",
      printed_cell(cap, "Pairwise Effect Sizes", "Soprano", "Mezzo"),
      -printed_cell(cap, "Pairwise Effect Sizes", "Mezzo", "Soprano"), tol = 1e-12)

# --- cross-check the omnibus against an independent path -------------------
# aov() and a hand-rolled sums-of-squares decomposition must agree, so the
# ANOVA row above is not resting on a single R idiom.
gm <- mean(d$SPL_dB)
ss_b2 <- sum(sapply(g, function(v) length(v) * (mean(v) - gm)^2))
ss_w2 <- sum(sapply(g, function(v) sum((v - mean(v))^2)))
check("v09", "SS between, hand-rolled", ss_b, ss_b2, tol = 1e-9)
check("v09", "SS within, hand-rolled",  ss_w, ss_w2, tol = 1e-9)

if (!exists("EML_SUITE")) { eml_report("v09 ANOVA + Tukey orchestrator"); eml_exit() }
