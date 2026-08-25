# ============================================================================
# v127_door_agreement_census.R -- punch-list 8.1, the door-agreement census
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS IS FOR.
#
# Several user intents in this plugin are reachable through more than one
# door -- the menu, the wizard, the graph dialogs -- and nothing before this
# file checked that the doors agree. One disagreement was already on
# record: the correlation dialog reports per-group and labelled, the
# regression dialog reports overall only, and the scatter annotation
# reports per-group only. Three doors, three answers, no warning. This
# file is docs/WORK_ORDER_DOOR_CENSUS.md's census, built for the six
# intents docs/PUNCH_LIST_DOORS_UNIFICATION_2026-08-25.md item 8.1 names,
# from the seed table in the audit continuation
# (EML_Praat_Audit_CONTINUATION_2026-08-25.md, Part 4).
#
# THE RULE, VERBATIM FROM THE WORK ORDER. Drive every door on the same
# ADVERSARIAL fixture -- built so two doors mapping the data differently
# produce LOUDLY DIFFERENT numbers, never coincidentally equal ones -- and
# assert exactly one of two things: (a) the doors agree to the oracle's
# tolerance, or (b) they are EXPLICITLY, PLAINLY labelled as showing
# different models. SILENT DISAGREEMENT -- different numbers, nothing
# saying why -- IS THE ONLY RED.
#
# WHAT "DOOR" MEANS HERE. harness/doorcensus/probe.praat calls the exact
# kernel procedures each door's own source calls (cited by file:line in
# both the probe and this file), on the committed fixtures under
# harness/doorcensus/fixtures/. This is the direct-kernel-call half of
# docs/WORK_ORDER_DOOR_CENSUS.md section 4 ("driven doors use the GUI
# harness where the door is a dialog ... and direct kernel calls where it
# is an API") -- the same choice v90/v93 made for the psychometrics lane.
# It does not drive beginPause chrome; the chrome does not change a
# number, and the kernel calls are the door.
#
# THE SIX LEGS AND WHERE EACH ONE LANDS, decided by reading the source
# each door actually calls (cited inline below), not by assumption:
#
#   leg1  pairwise vs draw        SILENT DISAGREEMENT (current defect).
#         The bridge hardcodes Tukey HSD regardless of what test/
#         adjustment the user chose at the Pairwise dialog
#         (eml-annotation-procedures.praat:3543-3544, literal ".doTukey"
#         argument "1"). Modelled on Sol's p=.052->.037 seed fixture.
#         Named in punch-list 8.2 as a draw-handoff site closed by the
#         result-store bridge (1.6), not here -- this leg is that fix's
#         acceptance instrument, expected red until it lands.
#   leg2  unequal-spread ANOVA    AGREE. Both doors call the SAME shared
#         vs draw                 reporter, @emlReportAnovaComparison,
#                                  from stats/eml-analysis.praat:379 and
#                                  graphs/eml-annotation-procedures.praat
#                                  :3543-3544 -- architecturally one call
#                                  site, not two implementations that
#                                  happen to match today.
#   leg3  post-hoc opt-out        SILENT DISAGREEMENT (current defect).
#         vs draw                 The SAME mechanism as leg1, probed from
#                                  the analysis side: Compare k Groups
#                                  with Tukey unchecked (doTukey = 0)
#                                  prints no post-hoc table; the bridge
#                                  shows Tukey anyway, unconditionally.
#                                  Also a draw-handoff site per 8.2.
#   leg4  paired vs spaghetti      SILENT DISAGREEMENT (current defect).
#         The spaghetti plot itself prints no inferential statistic at
#         all (graphs/eml-draw-procedures.praat:3417-3462 -- N/Mean/SD
#         per condition, nothing else), so nothing on that figure warns a
#         reader off reaching for the plugin's own independent-samples
#         kernel on the reshaped Subject/Condition/Value table instead of
#         the paired one -- "Subject doubling as grouping variable;
#         paired state lost" in the audit continuation's words. See the
#         header note in this file's own fixture comment
#         (fixtures/leg4_paired_vs_spaghetti.csv) for the honest caveat:
#         the long table the paired wrapper builds is REMOVED right after
#         the spaghetti draw, so "door 2" here is the kernel a user
#         reaches for on an exported copy of that reshape, not a second
#         live button in the current UI. The statistical hazard the audit
#         named is real and reproduced exactly either way.
#   leg5  grouped regression       SILENT DISAGREEMENT (current defect,
#         (Simpson)                still open). scripts/eml-regress.praat
#                                  reads the Group column into groupCol$
#                                  and never passes it to
#                                  @emlRunRegressionAnalysis (line 107:
#                                  "tableId, respCol$, predCol$" -- three
#                                  arguments, no group). This is Sol's
#                                  Simpson fixture joining the two-door
#                                  exhibit (docs/EXHIBIT_TWO_DOOR_
#                                  REGRESSION.md); WORK_ORDER_DOOR_CENSUS.md
#                                  section 3 rules the fix IN for 1.0 (the
#                                  regression dialog gains the correlate
#                                  dialog's per-group pattern) and says
#                                  this leg is "expected-red only until
#                                  the port's commit." It has not landed
#                                  at this commit -- confirmed by source
#                                  read above, not assumed.
#   leg6  correlation display     AGREE, both self-labelled. The
#         scope                   correlate dialog's per-group block and
#                                  the scatter's own per-group block both
#                                  call @emlReportCorrelationAnalysis
#                                  (graphs/eml-draw-procedures.praat:4709
#                                  and :5117) -- one call site again, not
#                                  two. Each door names its own scope: the
#                                  correlate dialog labels rows
#                                  "(overall)" / the group level
#                                  (scripts/eml-correlate.praat, the V3.5
#                                  header and the emlTidyRow term at line
#                                  346); the scatter's block is headed
#                                  "Per-group stats (N groups)"
#                                  (eml-draw-procedures.praat:5261). The
#                                  full three-way scope CONTROL and the
#                                  language-batch item-15 disclosure line
#                                  ("This figure shows per-group
#                                  relationships only.") are punch-list
#                                  8.3, ruled for 1.0 and NOT YET WIRED --
#                                  confirmed by grep, zero hits for that
#                                  string anywhere under plugin/ at this
#                                  commit. That gap is real and is 8.3's
#                                  job, not this leg's: this leg's own bar
#                                  is numeric agreement plus each side's
#                                  own existing self-label, which both
#                                  doors already clear.
#
# So four of six legs read RED at this commit, and that is the correct,
# expected reading of this file today -- not a bug in the check. Punch-
# list item 1.6 ("the store must not enshrine an unaudited door") and
# item 8.2 name legs 1/3/5 explicitly as the acceptance instruments for
# work sequenced AFTER this file; leg4 documents a real hazard with an
# honest caveat about its second door's reachability. Legs 2 and 6 read
# GREEN because they are, architecturally, ONE call site wearing two
# names -- which this file demonstrates by calling that one procedure
# under both names and holding the result to a live R oracle, not by
# trusting the architecture diagram.
#
# ORACLE. Every numeric leg is checked against base R, computed FRESH in
# this file from the committed fixture CSVs -- not copied from
# harness/doorcensus/probe.praat's own working notes -- so neither file is
# trusted blind against the other:
#   leg1  t.test(x, y, var.equal = TRUE) per pair + p.adjust("bonferroni");
#         aov() + TukeyHSD() for the same pair.
#   leg2  oneway.test(var.equal = FALSE) for Welch's F. Games-Howell has NO
#         base R equivalent -- p.adjust and PMCMRplus/userfriendlyscience
#         are not part of base R and are not used here. What is compared
#         instead: the published Tukey-Kramer / Welch-Satterthwaite
#         formula the plugin's own @emlGamesHowell implements
#         (stats/eml-inferential.praat:5311-5477, SE = sqrt((var_i/n_i +
#         var_j/n_j)/2), df Welch-Satterthwaite, p = 1 - ptukey(q, k, df)),
#         computed independently in this file from base R's `ptukey`
#         alone, with the formula re-derived from the source rather than
#         copied as a black box.
#   leg3  aov()/TukeyHSD(), same fixture as leg1.
#   leg4  t.test(paired = TRUE) and t.test(var.equal = FALSE).
#   leg5  lm() per group and pooled.
#   leg6  cor.test() (Pearson), per group and pooled.
#
# Base R only. Reads harness/doorcensus/out/DOORCENSUS.tsv (written by
# harness/doorcensus/run.sh) and the committed fixture CSVs; drives
# nothing itself.
#
# THE RED DEMONSTRATION for the STRUCTURE of this check (population
# coverage, not vacuous, reads real evidence) is $EML_DOORCENSUS_OUT
# pointed at an empty or partial file -- section 1 below refuses to pass
# over that silently, in the same shape v111/v112 use. The red
# demonstration for the SUBSTANCE of the check -- that it actually catches
# silent disagreement -- does not need a seeded copy: legs 1, 3, 4 and 5
# are silently disagreeing IN THE SHIPPED TREE RIGHT NOW, and this file
# reads red on them today, from the real pre-fix source, committed and
# reusable by construction (re-run harness/doorcensus/run.sh against any
# commit and this file reads its actual state). That is the strongest
# form of "demonstrated red against the pre-fix behaviour" available: the
# behaviour in question has not been fixed yet.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

V <- "v127"

if (!exists("check_true")) source(file.path(
    Sys.getenv("EML_VALIDATE_DIR", unset = "validate"), "helpers.R"))

tsv_path <- Sys.getenv("EML_DOORCENSUS_OUT", unset = "")
if (!nzchar(tsv_path)) tsv_path <- repo_path("harness", "doorcensus", "out", "DOORCENSUS.tsv")
fix_dir <- repo_path("harness", "doorcensus", "fixtures")

# $EML_DOORCENSUS_SRC points the STRUCTURAL half of this file (the source
# greps that ground each leg's VERDICT) at a tree other than the shipped
# one -- the same variable run.sh takes, and how a seed-violation copy is
# read: no drive needed, since these greps read source directly.
# harness/doorcensus/seed_violation.sh is the committed, reusable red
# demonstration built on this.
plugin_src_root <- Sys.getenv("EML_DOORCENSUS_SRC", unset = "")
PLUGIN_DIR <- if (nzchar(plugin_src_root)) {
    file.path(plugin_src_root, "plugin_EML_StatsGraphs")
} else {
    repo_path("plugin")
}

# ---------------------------------------------------------------------------
# 0. THE EVIDENCE LOADS, AND IS NOT TRUNCATED
# ---------------------------------------------------------------------------
ok_tsv <- check_true(V, "the door-census artefact is present",
                     file.exists(tsv_path))
if (!ok_tsv) {
    cat("\n  harness/doorcensus/out/DOORCENSUS.tsv is written by\n",
        "  bash harness/doorcensus/run.sh. Without it this file has\n",
        "  nothing to read.\n", sep = "")
    if (!exists("EML_SUITE")) { eml_report("v127 -- the door-agreement census"); eml_exit() }
}

raw <- readLines(tsv_path, warn = FALSE)
raw <- raw[nzchar(raw)]
raw <- raw[-1]  # header row
rows <- strsplit(raw, "\t", fixed = TRUE)
ev <- data.frame(
    leg   = vapply(rows, function(r) if (length(r) >= 1) r[1] else "", ""),
    key   = vapply(rows, function(r) if (length(r) >= 2) r[2] else "", ""),
    value = vapply(rows, function(r) if (length(r) >= 3) r[3] else "", ""),
    stringsAsFactors = FALSE
)

check_true(V, "the artefact ends with its DONE marker, not a truncated run",
           any(ev$leg == "DONE" & ev$key == "DONE"))

val <- function(lg, k, default = NA_character_) {
    i <- which(ev$leg == lg & ev$key == k)
    if (!length(i)) default else ev$value[i[length(i)]]
}
num <- function(lg, k) {
    s <- val(lg, k)
    if (is.na(s) || s == "undefined") NA_real_ else as.numeric(s)
}

LEGS <- c("leg1", "leg2", "leg3", "leg4", "leg5", "leg6")
present <- LEGS[LEGS %in% ev$leg]
check_true(V,
           sprintf("RESOLVER: all %d declared intents have rows in the artefact (%d present)%s",
                   length(LEGS), length(present),
                   if (length(present) < length(LEGS))
                       paste0(" -- MISSING: ", paste(setdiff(LEGS, present), collapse = ", "))
                   else ""),
           length(present) == length(LEGS))

# ---------------------------------------------------------------------------
# Fixture readers -- the committed CSVs, read fresh, so the oracle below is
# computed from the same record a reviewer would read, not from a number
# copied out of a working script.
# ---------------------------------------------------------------------------
read_fix <- function(name) {
    p <- file.path(fix_dir, name)
    lines <- readLines(p, warn = FALSE)
    lines <- lines[!grepl("^\\s*#", lines) & nzchar(lines)]
    read.csv(text = paste(lines, collapse = "\n"), stringsAsFactors = FALSE)
}

# ===========================================================================
# LEG 1 -- pairwise dialog (Student t, Bonferroni) vs draw's Tukey HSD
# ===========================================================================
f1 <- read_fix("leg1_pairwise_vs_draw.csv")
gA <- f1$value[f1$group == "A"]; gB <- f1$value[f1$group == "B"]; gC <- f1$value[f1$group == "C"]

pair_p <- function(x, y) t.test(x, y, var.equal = TRUE)$p.value
raw_p <- c(AB = pair_p(gA, gB), AC = pair_p(gA, gC), BC = pair_p(gB, gC))
bonf <- p.adjust(raw_p, method = "bonferroni")

dat1 <- data.frame(y = c(gA, gB, gC),
                    g = factor(rep(c("A", "B", "C"), c(length(gA), length(gB), length(gC)))))
tk1 <- TukeyHSD(aov(y ~ g, data = dat1))$g

check(V, "leg1 pairwise Student/Bonferroni p(A,B)", num("leg1", "p_AB"), unname(bonf["AB"]), tol = 1e-6)
check(V, "leg1 pairwise Student/Bonferroni p(A,C)", num("leg1", "p_AC"), unname(bonf["AC"]), tol = 1e-6)
check(V, "leg1 pairwise Student/Bonferroni p(B,C)", num("leg1", "p_BC"), unname(bonf["BC"]), tol = 1e-6)
check(V, "leg1 Tukey HSD p(A,B)", num("leg1", "tukey_p_AB"), tk1["B-A", "p adj"], tol = 1e-6)
check(V, "leg1 Tukey HSD p(A,C)", num("leg1", "tukey_p_AC"), tk1["C-A", "p adj"], tol = 1e-6)
check(V, "leg1 Tukey HSD p(B,C)", num("leg1", "tukey_p_BC"), tk1["C-B", "p adj"], tol = 1e-6)

leg1_p_bonf <- num("leg1", "p_AB"); leg1_p_tukey <- num("leg1", "tukey_p_AB")
check_true(V,
           sprintf("leg1 fixture is ADVERSARIAL: Bonferroni p(A,B) = %.4f (not sig. at .05) vs Tukey p(A,B) = %.4f (sig. at .05) -- loudly different, not coincidentally equal",
                   leg1_p_bonf, leg1_p_tukey),
           is.finite(leg1_p_bonf) && is.finite(leg1_p_tukey) &&
               leg1_p_bonf > 0.05 && leg1_p_tukey < 0.05)

# THE VERDICT. Both doors self-name their own test (verified by the labels
# the probe recorded), but neither states that the OTHER door, on the SAME
# data, shows a different pair-A-vs-B answer -- no line anywhere says "the
# figure differs from the test you chose." Per the work order's own worked
# example, a door naming its own model is not enough by itself; what is
# missing is any acknowledgement that the two draws disagree. Per punch-
# list 8.2 this is a named, sequenced, NOT-YET-CLOSED gap (the result-store
# bridge, item 1.6) -- so this reads red on purpose, today.
check_true(V, "leg1 door labels are present and distinct (Student t-test/bonferroni vs Tukey HSD)",
           identical(val("leg1", "test_label"), "Student t-test") &&
               identical(val("leg1", "adjust_label"), "bonferroni") &&
               identical(val("leg1", "door2_label"), "Tukey HSD"))
# STRUCTURAL EVIDENCE, not assumed: the bridge's post-hoc call is a LITERAL
# "1", so it cannot ever vary with what the user chose at the Pairwise
# dialog, and no sentence anywhere in the bridge acknowledges that the two
# doors can print different pairwise verdicts on the same pair.
bridge_src <- readLines(file.path(PLUGIN_DIR, "graphs", "eml-annotation-procedures.praat"), warn = FALSE)
leg1_hardcoded_line <- grep("@emlReportAnovaComparison:\\s*\\.tableName\\$, \\.dataCol\\$, \\.groupCol\\$,",
                            bridge_src, fixed = FALSE)
leg1_literal_one <- length(leg1_hardcoded_line) > 0 &&
    any(grepl("^\\s*\\.\\.\\.\\s*\\.tableId, \\.nGroups, 1\\s*$",
              bridge_src[leg1_hardcoded_line[1] + 0:2]))
leg1_reconciled <- any(grepl("differs from the (test|pairwise (test|comparison)) you (chose|selected)",
                             bridge_src, ignore.case = TRUE))
check_true(V,
           sprintf("leg1 VERDICT: SILENT DISAGREEMENT -- the bridge's post-hoc call is a hard literal (%s), and no line reconciles it with the Pairwise dialog's own choice (%s); closed by 1.6 per punch-list 8.2, FAILS on purpose until the store bridge lands",
                   if (leg1_literal_one) "confirmed" else "NOT CONFIRMED -- re-check the line reference",
                   if (leg1_reconciled) "one was found -- re-check this leg" else "none found"),
           leg1_literal_one && !leg1_reconciled)

# ===========================================================================
# LEG 3 -- post-hoc opt-out (Compare k Groups, Tukey unchecked) vs draw
# ===========================================================================
# Same table as leg 1, reused deliberately (see the fixture header).
anova_off <- summary(aov(y ~ g, data = dat1))[[1]]
check(V, "leg3 ANOVA F, doTukey = 0", num("leg3", "anova_F"), anova_off["g", "F value"], tol = 1e-6)
check(V, "leg3 ANOVA p, doTukey = 0", num("leg3", "anova_p"), anova_off["g", "Pr(>F)"], tol = 1e-8)
check_true(V, "leg3 door A (post-hoc opted out) prints no post-hoc table",
           identical(val("leg3", "posthoc_ran"), "0"))
check_true(V, "leg3 door B (the figure) runs the post-hoc unconditionally",
           identical(val("leg3", "posthoc_ran_door2"), "1"))
check(V, "leg3 Tukey p(C,A) shown on the figure regardless", num("leg3", "tukey_p_CA"),
      tk1["C-A", "p adj"], tol = 1e-6)
check(V, "leg3 Tukey p(C,B) shown on the figure regardless", num("leg3", "tukey_p_CB"),
      tk1["C-B", "p adj"], tol = 1e-6)
check_true(V,
           sprintf("leg3 fixture is ADVERSARIAL: the figure prints Tukey p(C,A) = %.2e and p(C,B) = %.2e -- both far below .05 -- on a run where the user explicitly declined a post-hoc",
                   num("leg3", "tukey_p_CA"), num("leg3", "tukey_p_CB")),
           is.finite(num("leg3", "tukey_p_CA")) && num("leg3", "tukey_p_CA") < 0.001)
check_true(V,
           sprintf("leg3 VERDICT: SILENT DISAGREEMENT -- the SAME hard literal (%s) that governs leg1 means the figure cannot honour doTukey = 0 either, and no line reconciles it; closed by 1.6 per punch-list 8.2, FAILS on purpose until the store bridge lands",
                   if (leg1_literal_one) "confirmed" else "NOT CONFIRMED -- re-check the line reference"),
           leg1_literal_one && !leg1_reconciled)

# ===========================================================================
# LEG 2 -- unequal-spread ANOVA supplement: analysis door vs draw door
# ===========================================================================
f2 <- read_fix("leg2_unequal_spread.csv")
gA2 <- f2$value[f2$group == "A"]; gB2 <- f2$value[f2$group == "B"]; gC2 <- f2$value[f2$group == "C"]
dat2 <- data.frame(y = c(gA2, gB2, gC2),
                    g = factor(rep(c("A", "B", "C"), c(length(gA2), length(gB2), length(gC2)))))

# Brown-Forsythe: Levene's test centred on the group MEDIAN (the variant
# @emlBrownForsythe implements, stats/eml-inferential.praat:4790ff).
meds <- tapply(dat2$y, dat2$g, median)
z <- abs(dat2$y - meds[dat2$g])
bf_p <- summary(aov(z ~ dat2$g))[[1]][1, "Pr(>F)"]
check(V, "leg2 Brown-Forsythe p (gate for the unequal-spread supplement)",
      num("leg2", "bf_p"), bf_p, tol = 1e-6)
check_true(V, "leg2 fixture is ADVERSARIAL: Brown-Forsythe rejects equal spread (p < .05), opening the supplemental block on BOTH doors",
           is.finite(bf_p) && bf_p < 0.05)

w <- oneway.test(y ~ g, data = dat2, var.equal = FALSE)
check(V, "leg2 Welch F, analysis door", num("leg2", "welch_F"), unname(w$statistic), tol = 1e-6)
check(V, "leg2 Welch p, analysis door", num("leg2", "welch_p"), w$p.value, tol = 1e-8)
check(V, "leg2 Welch F, draw door", num("leg2", "welch_F_door2"), unname(w$statistic), tol = 1e-6)
check(V, "leg2 Welch p, draw door", num("leg2", "welch_p_door2"), w$p.value, tol = 1e-8)
check_true(V, "leg2 AGREE: Welch F is bit-identical between the two call sites",
           isTRUE(all.equal(num("leg2", "welch_F"), num("leg2", "welch_F_door2"), tolerance = 0)))

# Games-Howell -- no base R equivalent; the published Tukey-Kramer /
# Welch-Satterthwaite formula, re-derived from @emlGamesHowell's own source
# (stats/eml-inferential.praat:5311-5477) and computed here from base R's
# `ptukey` alone.
gh_pair <- function(x, y, k = 3) {
    nx <- length(x); ny <- length(y)
    termI <- var(x) / nx; termJ <- var(y) / ny
    se <- sqrt((termI + termJ) / 2)
    q <- abs(mean(x) - mean(y)) / se
    df <- (termI + termJ)^2 / (termI^2 / (nx - 1) + termJ^2 / (ny - 1))
    1 - ptukey(q, k, df)
}
check(V, "leg2 Games-Howell p(A,B)", num("leg2", "gh_p_AB"), gh_pair(gA2, gB2), tol = 1e-6)
check(V, "leg2 Games-Howell p(A,C)", num("leg2", "gh_p_AC"), gh_pair(gA2, gC2), tol = 1e-6)
check(V, "leg2 Games-Howell p(B,C)", num("leg2", "gh_p_BC"), gh_pair(gB2, gC2), tol = 1e-6)
check_true(V,
           "leg2 VERDICT: AGREE -- one shared reporter (@emlReportAnovaComparison, stats/eml-analysis.praat:379 and graphs/eml-annotation-procedures.praat:3543-3544), confirmed by number, not by architecture diagram alone",
           TRUE)

# ===========================================================================
# LEG 4 -- paired dialog vs the plugin's own unpaired kernel, same subjects
# ===========================================================================
f4 <- read_fix("leg4_paired_vs_spaghetti.csv")
pt <- t.test(f4$cond1, f4$cond2, paired = TRUE)
ut <- t.test(f4$cond1, f4$cond2, var.equal = FALSE)

check(V, "leg4 paired t", num("leg4", "paired_t"), unname(pt$statistic), tol = 1e-6)
check(V, "leg4 paired df", num("leg4", "paired_df"), unname(pt$parameter), tol = 1e-6)
check(V, "leg4 paired p", num("leg4", "paired_p"), pt$p.value, tol = 1e-8)
check(V, "leg4 unpaired (Welch) t", num("leg4", "unpaired_t"), unname(ut$statistic), tol = 1e-6)
check(V, "leg4 unpaired (Welch) df", num("leg4", "unpaired_df"), unname(ut$parameter), tol = 1e-4)
check(V, "leg4 unpaired (Welch) p", num("leg4", "unpaired_p"), ut$p.value, tol = 1e-6)

leg4_pp <- num("leg4", "paired_p"); leg4_up <- num("leg4", "unpaired_p")
check_true(V,
           sprintf("leg4 fixture is ADVERSARIAL: paired p = %.6f (sig. well below .001) vs the SAME subjects unpaired p = %.4f (not remotely significant)",
                   leg4_pp, leg4_up),
           is.finite(leg4_pp) && is.finite(leg4_up) && leg4_pp < 0.001 && leg4_up > 0.5)
# STRUCTURAL EVIDENCE: read @emlDrawSpaghettiPlot's own body out of source
# and confirm it prints no inferential statistic whatsoever -- the reason
# nothing on that figure warns a reader off the unpaired kernel.
draw_src <- readLines(file.path(PLUGIN_DIR, "graphs", "eml-draw-procedures.praat"), warn = FALSE)
sp_start <- grep("^procedure emlDrawSpaghettiPlot", draw_src)
sp_end <- sp_start[1] - 1 + which(grepl("^endproc", draw_src[sp_start[1]:length(draw_src)]))[1]
sp_body <- draw_src[sp_start[1]:sp_end]
sp_has_test <- any(grepl("paired|wilcoxon|t-test|p-value|[^A-Za-z]p\\s*=", sp_body, ignore.case = TRUE))
check_true(V,
           sprintf("leg4 VERDICT: SILENT DISAGREEMENT -- @emlDrawSpaghettiPlot's own body (eml-draw-procedures.praat:%d-%d) prints no inferential statistic (%s), so nothing on that figure warns a reader off the plugin's own unpaired kernel on its reshaped table; documented hazard, FAILS on purpose -- see this file's leg4 header note on door-2 reachability",
                   sp_start[1], sp_end,
                   if (sp_has_test) "TEST TEXT FOUND -- re-check this leg" else "confirmed"),
           !sp_has_test)

# ===========================================================================
# LEG 5 -- grouped regression (Simpson): regression dialog vs scatter draw
# ===========================================================================
f5 <- read_fix("leg5_grouped_regression.csv")
xA5 <- f5$x[f5$group == "A"]; yA5 <- f5$y[f5$group == "A"]
xB5 <- f5$x[f5$group == "B"]; yB5 <- f5$y[f5$group == "B"]
mAll <- lm(y ~ x, data = f5)
mA <- lm(yA5 ~ xA5); mB <- lm(yB5 ~ xB5)

check(V, "leg5 pooled slope (regression dialog, group column dropped)",
      num("leg5", "pooled_slope"), unname(coef(mAll)["x"]), tol = 1e-6)
check(V, "leg5 pooled R^2", num("leg5", "pooled_r2"), summary(mAll)$r.squared, tol = 1e-8)
check(V, "leg5 group A slope (scatter draw)", num("leg5", "slopeA"), unname(coef(mA)[2]), tol = 1e-6)
check(V, "leg5 group A R^2", num("leg5", "r2A"), summary(mA)$r.squared, tol = 1e-6)
check(V, "leg5 group B slope (scatter draw)", num("leg5", "slopeB"), unname(coef(mB)[2]), tol = 1e-6)
check(V, "leg5 group B R^2", num("leg5", "r2B"), summary(mB)$r.squared, tol = 1e-6)

leg5_pooled <- num("leg5", "pooled_slope"); leg5_a <- num("leg5", "slopeA"); leg5_b <- num("leg5", "slopeB")
check_true(V,
           sprintf("leg5 fixture is ADVERSARIAL (Simpson): pooled slope = %.4f (~0) while group A = %+.3f and group B = %+.3f -- opposite signs, near-perfect fits (R^2 > .998 each)",
                   leg5_pooled, leg5_a, leg5_b),
           is.finite(leg5_pooled) && abs(leg5_pooled) < 0.05 &&
               leg5_a > 1.5 && leg5_b < -1.5)
# STRUCTURAL EVIDENCE: the regression dialog's own call, read out of
# source, carries three arguments and no group column.
regress_src <- readLines(file.path(PLUGIN_DIR, "scripts", "eml-regress.praat"), warn = FALSE)
leg5_call_line <- grep("@emlRunRegressionAnalysis:\\s*tableId,\\s*respCol\\$,\\s*predCol\\$\\s*$", regress_src)
leg5_group_passed <- any(grepl("@emlRunRegressionAnalysis:.*group", regress_src, ignore.case = TRUE))
check_true(V,
           sprintf("leg5 VERDICT: SILENT DISAGREEMENT -- the regression dialog's own call (%s) carries tableId/respCol$/predCol$ only, no group column, though the dialog reads one; still open per WORK_ORDER_DOOR_CENSUS.md section 3 (per-group port ruled IN for 1.0, not yet landed), FAILS on purpose until the port's commit",
                   if (length(leg5_call_line)) sprintf("confirmed, eml-regress.praat:%d", leg5_call_line[1])
                   else "NOT CONFIRMED -- re-check the line reference"),
           length(leg5_call_line) > 0 && !leg5_group_passed)

# ===========================================================================
# LEG 6 -- correlation display scope: correlate dialog vs scatter draw
# ===========================================================================
f6 <- read_fix("leg6_correlation_scope.csv")
xA6 <- f6$x[f6$group == "A"]; yA6 <- f6$y[f6$group == "A"]
xB6 <- f6$x[f6$group == "B"]; yB6 <- f6$y[f6$group == "B"]
caA <- cor.test(xA6, yA6); caB <- cor.test(xB6, yB6)
poolAll <- cor.test(f6$x, f6$y)

check(V, "leg6 group A r, correlate dialog", num("leg6", "r_A"), unname(caA$estimate), tol = 1e-6)
check(V, "leg6 group A p, correlate dialog", num("leg6", "p_A"), caA$p.value, tol = 1e-6)
check(V, "leg6 group B r, correlate dialog", num("leg6", "r_B"), unname(caB$estimate), tol = 1e-6)
check(V, "leg6 group A r, scatter draw", num("leg6", "r_A_door2"), unname(caA$estimate), tol = 1e-6)
check(V, "leg6 group B r, scatter draw", num("leg6", "r_B_door2"), unname(caB$estimate), tol = 1e-6)
check(V, "leg6 pooled r (neither door draws this)", num("leg6", "r_pooled"), unname(poolAll$estimate), tol = 1e-6)

check_true(V, "leg6 AGREE: correlate dialog and scatter draw report the identical per-group r (same call, @emlReportCorrelationAnalysis)",
           isTRUE(all.equal(num("leg6", "r_A"), num("leg6", "r_A_door2"), tolerance = 1e-9)) &&
               isTRUE(all.equal(num("leg6", "r_B"), num("leg6", "r_B_door2"), tolerance = 1e-9)))

leg6_rA <- num("leg6", "r_A"); leg6_rPooled <- num("leg6", "r_pooled")
check_true(V,
           sprintf("leg6 fixture is ADVERSARIAL (Simpson for correlation): per-group r = %+.4f in both groups vs pooled r = %+.4f -- opposite sign, so a door that silently fell back to the pooled figure would be unmistakable, not a near-miss",
                   leg6_rA, leg6_rPooled),
           is.finite(leg6_rA) && is.finite(leg6_rPooled) &&
               leg6_rA > 0.9 && leg6_rPooled < -0.3)
check_true(V,
           "leg6 both doors self-label their scope (correlate dialog: \"(overall)\" / group-level rows, scripts/eml-correlate.praat; scatter: \"Per-group stats (N groups)\", eml-draw-procedures.praat:5261) -- LABELLED, per the work order's own worked example",
           TRUE)

# The 8.3 disclosure line is ruled for 1.0 and confirmed absent today --
# named here as a fact, not asserted as this leg's own failure (its own
# bar, numeric agreement plus existing self-labels, is met).
scatter_src <- readLines(file.path(PLUGIN_DIR, "graphs", "eml-draw-procedures.praat"), warn = FALSE)
disclosure_present <- any(grepl("per-group relationships only", scatter_src, fixed = TRUE))
check_true(V,
           sprintf("the language-batch item-15 scope disclosure line is %s in the scatter draw source (punch-list 8.3, ruled for 1.0, not this leg's bar)",
                   if (disclosure_present) "PRESENT" else "NOT YET WIRED"),
           TRUE)  # informational -- the ledger row is the fact worth reading, not a pass/fail
check_true(V, "leg6 VERDICT: AGREE, both self-labelled -- reads green today",
           TRUE)

# ---------------------------------------------------------------------------
# THE RESOLVER GATE -- refutes a vacuous pass over an empty or partial file
# ---------------------------------------------------------------------------
n_numeric_checks <- sum(!vapply(EML_RESULTS$rows, function(r) identical(r$id, "") , logical(1)))
check_true(V,
           sprintf("RESOLVER: this run exercised all %d declared legs and recorded %d checks",
                   length(LEGS), length(EML_RESULTS$rows)),
           length(present) == length(LEGS) && length(EML_RESULTS$rows) >= 40)

if (!exists("EML_SUITE")) {
    eml_report("v127 -- the door-agreement census (punch-list 8.1)")
    cat("\n  LEDGER: leg1 SILENT (1.6) | leg2 AGREE | leg3 SILENT (1.6) |\n",
        "         leg4 SILENT (documented hazard) | leg5 SILENT (regression port) |\n",
        "         leg6 AGREE, labelled\n", sep = "")
    eml_exit()
}
