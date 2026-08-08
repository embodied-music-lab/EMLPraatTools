# ============================================================================
# v10 — Compare k groups (Kruskal-Wallis): orchestrator and Dunn post-hoc
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Covers @emlRunKWAnalysis: the omnibus H, epsilon-squared, the mean-rank
# table, and three matrices — Dunn adjusted p, Dunn z, and pairwise
# rank-biserial r.
#
# Two things here R has no direct function for, both implemented from their
# standard definitions in helpers.R and open to dispute:
#   * Dunn's test — Dunn (1964), tie-corrected, as scikit-posthocs computes
#     it. The plugin's own suite checks its Dunn against scikit-posthocs;
#     this is an independent third path in base R.
#   * epsilon-squared — H / ((N^2 - 1)/(N + 1)).
#
# EVERY REPORTED VALUE IS READ FROM THE COMMITTED CAPTURE; see the note at
# the head of v08.
#
# Run on the SAME table as v09. That is deliberate: the parametric and rank
# routes must agree about the data even where they disagree about the test,
# so this script re-checks the group sizes and the rank ordering against v09's
# mean ordering.
#
# PROVENANCE — READ THIS BEFORE CITING THIS SCRIPT AS GUI EVIDENCE.
#
# ORIGINALLY DRIVEN 5 August 2026 through the real GUI:
#   New > EML Tools > Compare k groups (Kruskal-Wallis)...
#   Data column SPL_dB, Group column voice_type, Group order = Table order.
#
# RE-DRIVEN HEADLESSLY 7 August 2026 for D110, by
# harness/broom_cases/d110_orchestrator_redrive.praat under `praat --run`:
# @emlRunKWAnalysis on the same committed input with the same arguments
# (Dunn ON, Holm adjustment). That is the shipping orchestrator the menu
# calls, on the committed CSV, but it is NOT a session someone clicked
# through. The capture this script reads is therefore the same KIND of
# evidence as v07_r7_axis_info.txt and the v18 grid, not the same kind as the
# 5 August GUI captures — see validate/README.md §"Two kinds of evidence".
#
# D110 forced the re-drive: the Dunn matrix moved from fixed$ (p, 4) to
# @emlFormatP's bare APA form. The re-drive also picked up two unrelated
# changes that had landed in the plugin since 5 August and were therefore
# absent from the committed capture — the wizard explanation column, whose
# default became 1 (D42/D102), and the "p" row's bare form with the unrounded
# value beside it (D9/D28), where the old capture read "p    p < .001".
# Neither changes a number; both change what the capture says.
#
# Input:  evidence/csv/v10_kw_dunn_input.csv
# Output: evidence/info/v10_kw_dunn_info.txt
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

d   <- read_input("v10_kw_dunn_input.csv")
cap <- capture("v10_kw_dunn_info.txt")
d$voice_type <- factor(d$voice_type, levels = unique(d$voice_type))
g <- split(d$SPL_dB, d$voice_type)
N <- nrow(d)

# --- omnibus ---------------------------------------------------------------
kw <- kruskal.test(SPL_dB ~ voice_type, data = d)
# V4, 6 Aug 2026. "Soprano" matches 7 lines here, "Mezzo" and "Alto" 4 each --
# Kruskal-Wallis prints three matrices, not two. See the note in v09.
check("v10", "H",  printed(cap, "H"), unname(kw$statistic), tol = 5e-5)
check("v10", "df", printed(cap, "df"), unname(kw$parameter), tol = 0)
check("v10", "total N", printed(cap, "Total N"), N, tol = 0)
check("v10", "groups", printed(cap, "Groups"), nlevels(d$voice_type), tol = 0)
check_floored("v10", "omnibus p", cap, "p", unname(kw$p.value))

# --- effect size -----------------------------------------------------------
check("v10", "epsilon-squared", printed(cap, "Epsilon-squared"),
      epsilon_squared(unname(kw$statistic), N), tol = 5e-5)

# The plugin also calls this a "large effect". Epsilon-squared uses the
# same 0.01 / 0.06 / 0.14 benchmarks as eta-squared; 0.42 is large under any
# of them, so the label is checked as a threshold claim, not a lookup.
check_true("v10", "epsilon-squared exceeds the large-effect benchmark",
           epsilon_squared(unname(kw$statistic), N) > 0.14)
check_true("v10", "and the plugin labels it a large effect",
           printed_str(cap, "Effect magnitude") == "large effect")

# --- mean ranks ------------------------------------------------------------
dn <- dunn_test(d$SPL_dB, d$voice_type)
check("v10", "mean rank Soprano", printed(cap, "Soprano", 2, 1, expect_hits = 7), unname(dn$meanrank["Soprano"]), tol = 5e-3)
check("v10", "mean rank Mezzo",   printed(cap, "Mezzo", 2, 1, expect_hits = 4), unname(dn$meanrank["Mezzo"]),   tol = 5e-3)
check("v10", "mean rank Alto",    printed(cap, "Alto", 2, 1, expect_hits = 4), unname(dn$meanrank["Alto"]),    tol = 5e-3)
check("v10", "N per group is 15", printed(cap, "Soprano", 1, 1, expect_hits = 7), unname(dn$n["Soprano"]), tol = 0)

# Mean ranks must sum to N(N+1)/2 when weighted by group size. This catches
# a wrapper that ranked within groups instead of across the whole column —
# a mistake that leaves each individual mean rank plausible.
check("v10", "weighted mean ranks sum to N(N+1)/2",
      N * (N + 1) / 2, sum(dn$meanrank * dn$n), tol = 1e-9)

# The rank ordering must match the mean ordering established in v09
# (Soprano > Mezzo > Alto). Same data, two orchestrators.
check_true("v10", "rank order matches the mean order from v09",
           dn$meanrank["Soprano"] > dn$meanrank["Mezzo"] &&
           dn$meanrank["Mezzo"]   > dn$meanrank["Alto"])

# --- Dunn z ----------------------------------------------------------------
check("v10", "Dunn z Soprano-Mezzo", printed_cell(cap, "Dunn's z-statistics", "Soprano", "Mezzo"), dn$z["Soprano", "Mezzo"], tol = 5e-4)
check("v10", "Dunn z Soprano-Alto", printed_cell(cap, "Dunn's z-statistics", "Soprano", "Alto"), dn$z["Soprano", "Alto"], tol = 5e-4)
check("v10", "Dunn z Mezzo-Alto", printed_cell(cap, "Dunn's z-statistics", "Mezzo", "Alto"), dn$z["Mezzo", "Alto"], tol = 5e-4)
check("v10", "Dunn z Mezzo-Soprano", printed_cell(cap, "Dunn's z-statistics", "Mezzo", "Soprano"), dn$z["Mezzo", "Soprano"], tol = 5e-4)
check("v10", "Dunn z Alto-Soprano", printed_cell(cap, "Dunn's z-statistics", "Alto", "Soprano"), dn$z["Alto", "Soprano"], tol = 5e-4)
check("v10", "Dunn z Alto-Mezzo", printed_cell(cap, "Dunn's z-statistics", "Alto", "Mezzo"), dn$z["Alto", "Mezzo"], tol = 5e-4)
check("v10", "printed Dunn z matrix is antisymmetric",
      printed_cell(cap, "Dunn's z-statistics", "Soprano", "Mezzo"),
      -printed_cell(cap, "Dunn's z-statistics", "Mezzo", "Soprano"), tol = 1e-12)

# --- Dunn adjusted p (Holm over the three unique pairs) --------------------
raw <- c(SM = dn$p["Soprano", "Mezzo"],
         SA = dn$p["Soprano", "Alto"],
         MA = dn$p["Mezzo",   "Alto"])
adj <- holm_adjust(raw)
names(adj) <- names(raw)
# D110. The matrix printed fixed$ (p, 4) — "0.0047" — and these tolerances
# were 5e-5, half of that last decimal place. The cells now carry
# @emlFormatP's bare APA form at three decimals (".005"), so the tolerance is
# 5e-4 on the same rule: half of the last place the plugin actually prints.
# Nothing was loosened to make a red check green — the printed precision
# changed and the tolerance follows it. The form itself is asserted below, so
# a silent return to four decimals under a 5e-4 tolerance would not pass
# unnoticed.
check("v10", "Dunn adj p Soprano-Mezzo", printed_cell(cap, "Dunn's Post-Hoc", "Soprano", "Mezzo"), adj[["SM"]], tol = 5e-4)
check("v10", "Dunn adj p Mezzo-Alto",    printed_cell(cap, "Dunn's Post-Hoc", "Mezzo", "Alto"), adj[["MA"]], tol = 5e-4)
check_true("v10", "the Dunn matrix uses the bare APA form (no leading zero)",
           grepl("^\\.[0-9]{3}$",
                 printed_cell(cap, "Dunn's Post-Hoc", "Soprano", "Mezzo", as_string = TRUE)))
check_true("v10", "Dunn adj p Soprano-Alto is floored in the matrix",
           grepl("<", printed_cell(cap, "Dunn's Post-Hoc", "Soprano", "Alto", as_string = TRUE)))
check_true("v10", "and R agrees it is below .001", adj[["SA"]] < 0.001)

# Holm must be monotone in the raw ordering. A naive step-down that forgets
# the running maximum breaks exactly here.
check_true("v10", "Holm adjustment is monotone in the raw p ordering",
           !is.unsorted(adj[order(raw)]))

# Holm must never reduce a p-value.
check_true("v10", "Holm never decreases a p-value", all(adj >= raw - 1e-12))

# Cross-check against base R's own Holm, which is an independent path.
check("v10", "Holm agrees with p.adjust(method = holm)",
      max(abs(adj - p.adjust(raw, "holm"))), 0, tol = 1e-12)

# --- pairwise rank-biserial ------------------------------------------------
# Same directed convention as v08; see helpers.R.
check("v10", "r Soprano vs Mezzo", printed_cell(cap, "rank-biserial", "Soprano", "Mezzo"),
      rank_biserial_indep(g$Soprano, g$Mezzo), tol = 5e-4)
check("v10", "r Soprano vs Alto", printed_cell(cap, "rank-biserial", "Soprano", "Alto"),
      rank_biserial_indep(g$Soprano, g$Alto), tol = 5e-4)
check("v10", "r Mezzo vs Alto", printed_cell(cap, "rank-biserial", "Mezzo", "Alto"),
      rank_biserial_indep(g$Mezzo, g$Alto), tol = 5e-4)
check("v10", "r Mezzo vs Soprano", printed_cell(cap, "rank-biserial", "Mezzo", "Soprano"),
      rank_biserial_indep(g$Mezzo, g$Soprano), tol = 5e-4)
check("v10", "printed rank-biserial matrix is antisymmetric",
      printed_cell(cap, "rank-biserial", "Soprano", "Mezzo"),
      -printed_cell(cap, "rank-biserial", "Mezzo", "Soprano"), tol = 1e-12)

# The three post-hoc matrices must tell one story: the pair with the largest
# |z| must also carry the largest |r| and the smallest adjusted p.
check_true("v10", "the three post-hoc matrices rank the pairs identically",
           which.max(abs(c(dn$z["Soprano","Mezzo"], dn$z["Soprano","Alto"],
                           dn$z["Mezzo","Alto"]))) ==
           which.max(abs(c(rank_biserial_indep(g$Soprano, g$Mezzo),
                           rank_biserial_indep(g$Soprano, g$Alto),
                           rank_biserial_indep(g$Mezzo,   g$Alto)))) &&
           which.min(adj) ==
           which.max(abs(c(dn$z["Soprano","Mezzo"], dn$z["Soprano","Alto"],
                           dn$z["Mezzo","Alto"]))))

if (!exists("EML_SUITE")) { eml_report("v10 Kruskal-Wallis + Dunn"); eml_exit() }
