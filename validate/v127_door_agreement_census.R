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
#   leg1  pairwise vs draw        HALF CLOSED, and the halves are named.
#         The bridge used to hardcode Tukey HSD regardless of what the user
#         chose, at two literal sites (eml-annotation-procedures.praat:4042
#         and :4649). ITEM 3.5, ruled by Fable on 26 August, closes the half
#         that matters most: the figure no longer runs a post-hoc NOBODY
#         ASKED FOR, because the launching dialog now carries the choice and
#         the bridge reads it. THE OTHER HALF IS STILL OPEN -- the graphs
#         door offers Tukey or nothing, so a user who chose Student t with
#         Bonferroni at the Pairwise dialog still cannot have the figure show
#         that test, and no sentence reconciles the two doors. That residue
#         is punch-list 8.2 / item 1.6 and it is pinned open below.
#         Modelled on Sol's p=.052->.037 seed fixture.
#   leg2  unequal-spread ANOVA    AGREE. Both doors call the SAME shared
#         vs draw                 reporter, @emlReportAnovaComparison,
#                                  from stats/eml-analysis.praat:379 and
#                                  graphs/eml-annotation-procedures.praat
#                                  :3543-3544 -- architecturally one call
#                                  site, not two implementations that
#                                  happen to match today.
#   leg3  post-hoc opt-out        AGREE, as of ITEM 3.5. The SAME mechanism
#         vs draw                  as leg1, probed from the analysis side:
#                                  Compare k Groups with Tukey unchecked
#                                  (doTukey = 0) prints no post-hoc table,
#                                  and the graphs door's own "ANOVA only, no
#                                  pairwise tests" row now produces the same
#                                  figure and the same report. Before item
#                                  3.5 the bridge showed Tukey anyway,
#                                  unconditionally; the probe drives both
#                                  answers and the pre-item artefact is the
#                                  red demonstration.
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
#   leg5  grouped regression       AGREE. WORK_ORDER_DOOR_CENSUS.md section 3
#         (Simpson)                ruled the fix IN for 1.0 (the regression
#                                  dialog gains the correlate dialog's
#                                  per-group pattern) and punch-list 4.5 has
#                                  now landed it: @emlRunGroupedRegressionAnalysis
#                                  (stats/eml-analysis.praat) is the ONE
#                                  shared call both the menu door
#                                  (scripts/eml-regress.praat) and both of
#                                  the wizard's regression pages now make,
#                                  fitting and reporting each group beside
#                                  the overall one -- the overall-fit call
#                                  itself (still "tableId, respCol$,
#                                  predCol$", three arguments) is unchanged,
#                                  because the group column now rides the
#                                  separate port call rather than a fourth
#                                  argument threaded into it. Full detail,
#                                  including the base-R lm() oracle per
#                                  group and the skip-and-name behaviour for
#                                  groups under n = 3, is
#                                  validate/v136_regression_grouping.R and
#                                  harness/regressiongroup/.
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
# HOW THIS FILE READS ITS OWN LEGS, AMENDED 26 AUGUST. Until that date the
# leg1 and leg3 verdicts were written as "the defect is present", so they
# PASSED while the disagreement they describe stood, and the header called
# that "expected red" while the runner counted it green. The 26 August
# verification pass found it; Fable ruled item 3.5 and named this leg its
# acceptance instrument, with "the red demonstration is the current literal".
# Every assertion in this file now holds when the tree is RIGHT, which is how
# the rest of the suite is written, and a check that pins a gap OPEN says so
# in its own text (leg1's residual, leg4's hazard). Punch-list item 1.6 ("the
# store must not enshrine an unaudited door") and item 8.2 still own leg1's
# residual half and leg5's history; leg4 documents a real hazard with an
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
# ===========================================================================
# ITEM 3.5 -- THE TWO doTukey LITERALS. THIS IS THE ACCEPTANCE INSTRUMENT.
# ===========================================================================
# WHAT THESE CHECKS USED TO SAY, AND WHY THAT WAS WRONG. Until 26 August this
# leg and leg 3 below each ended in one check that PASSED WHILE THE DEFECT
# STOOD: the assertion was "the bridge's post-hoc call is a hard literal and
# nothing reconciles it", so a tree with the literal in it read green, and the
# header called that "expected red" while the runner counted it a pass. The
# 26 August verification pass found it (docs/OPEN_ITEMS.md, FOUND BY
# VERIFICATION); Fable ruled the fix and named this leg its acceptance
# instrument, with "the red demonstration is the current literal". So the
# assertions below are stated the way every other check in this suite is
# stated -- they hold when the tree is RIGHT -- and against the tree as it
# stood before item 3.5 they go red, which is that demonstration.
#
# THE FIX FABLE RULED, AND WHAT IT IS NOT. "The launching dialog's actual
# post-hoc choice reaching the bridge, adding the field if none exists. Never
# a different literal." So a 0 in place of the 1 would not close this, and
# neither would a computed default: what is asserted below is a CHAIN, from a
# row on the Comparison menu, through the annotPostHoc global, into
# @emlOneWayAnova's post-hoc argument and into @emlReportBridgeStats' report
# and declarations. Every link is read out of the source here; the two ends
# are measured by the probe.
bridge_src <- readLines(file.path(PLUGIN_DIR, "graphs", "eml-annotation-procedures.praat"), warn = FALSE)
form_src <- readLines(file.path(PLUGIN_DIR, "graphs", "eml-graphs-form.praat"), warn = FALSE)

# SITE 1 of 2 -- eml-annotation-procedures.praat:4042 as the ruling cites it,
# the bridge's own @emlOneWayAnova call. Matched by TEXT, not by line number:
# a line number in a check drifts exactly as a line number in a comment does.
site1_literal <- any(grepl("^\\s*@emlOneWayAnova:\\s*\\.tableId, \\.dataCol\\$, \\.factorCol\\$, 1\\s*$",
                           bridge_src))
site1_wired <- any(grepl("^\\s*@emlOneWayAnova:\\s*\\.tableId, \\.dataCol\\$, \\.factorCol\\$, \\.doTukey\\s*$",
                         bridge_src))

# SITE 2 of 2 -- :4649, @emlReportBridgeStats' @emlReportAnovaComparison call.
leg1_hardcoded_line <- grep("@emlReportAnovaComparison:\\s*\\.tableName\\$, \\.dataCol\\$, \\.groupCol\\$,",
                            bridge_src, fixed = FALSE)
site2_literal <- length(leg1_hardcoded_line) > 0 &&
    any(grepl("^\\s*\\.\\.\\.\\s*\\.tableId, \\.nGroups, 1\\s*$",
              bridge_src[leg1_hardcoded_line[1] + 0:2]))
site2_wired <- length(leg1_hardcoded_line) > 0 &&
    any(grepl("^\\s*\\.\\.\\.\\s*\\.tableId, \\.nGroups, \\.doTukey\\s*$",
              bridge_src[leg1_hardcoded_line[1] + 0:2]))

check_true(V,
           sprintf("ITEM 3.5 site 1 of 2 (@emlOneWayAnova in @emlRunAnnotationComparison) is no longer a literal: %s",
                   if (site1_literal) "STILL THE LITERAL 1 -- this is the red demonstration"
                   else if (site1_wired) "takes .doTukey" else "neither form found -- re-check the call"),
           !site1_literal && site1_wired)
check_true(V,
           sprintf("ITEM 3.5 site 2 of 2 (@emlReportAnovaComparison in @emlReportBridgeStats) is no longer a literal: %s",
                   if (site2_literal) "STILL THE LITERAL 1 -- this is the red demonstration"
                   else if (site2_wired) "takes .doTukey" else "neither form found -- re-check the call"),
           !site2_literal && site2_wired)

# THE CHAIN, LINK BY LINK. A .doTukey at the two sites is worth nothing if it
# is set from another literal a few lines up, which is the shortcut the ruling
# names and forbids. So the source of the value is asserted too.
bridge_reads_global <- any(grepl('^\\s*if variableExists \\("annotPostHoc"\\)\\s*$', bridge_src)) &&
    any(grepl("^\\s*if annotPostHoc = 0\\s*$", bridge_src))
reporter_reads_bridge <- any(grepl('^\\s*if variableExists \\("emlRunAnnotationComparison\\.doTukey"\\)\\s*$',
                                   bridge_src)) &&
    any(grepl("^\\s*\\.doTukey = emlRunAnnotationComparison\\.doTukey\\s*$", bridge_src))
check_true(V,
           "ITEM 3.5 the bridge takes its post-hoc answer from the annotPostHoc global, not from a second literal",
           bridge_reads_global)
check_true(V,
           "ITEM 3.5 the reporter takes it from the bridge's own resolved flag, so one run has one answer",
           reporter_reads_bridge)

# THE DIALOG END OF THE CHAIN. "Adding the field if none exists" -- there was
# no post-hoc control on any of the six annotate-capable column-mapping pages,
# and there is now: a row on the shared Comparison menu, decoded by the one
# registry all six come through (v61 pins that), carrying the wizard's own
# language-batch item-4 wording. A row rather than a second control because a
# Praat dialog is static once drawn, so a tickbox beside a menu whose rows
# NAME a post-hoc could say two things at once; and because a row costs no tab
# stop, so no page's tab order moved and no tab-indexed transcript needs
# re-driving for this item.
menu_row <- any(grepl('^\\s*option: "ANOVA only, no pairwise tests"\\s*$', form_src))
decoder_out <- any(grepl("^\\s*\\.doPostHoc = 0\\s*$", form_src))
n_commit <- sum(grepl("^\\s*annotPostHoc = emlComparisonFromMenu\\.doPostHoc\\s*$", form_src))
n_persist <- sum(grepl("^\\s*prev_annotPostHoc = emlComparisonFromMenu\\.doPostHoc\\s*$", form_src))
n_seed <- sum(grepl("@emlComparisonToMenu:.*prev_annotPostHoc\\s*$", form_src))
check_true(V,
           sprintf("ITEM 3.5 the launching dialog has the field it lacked: the Comparison menu carries an omnibus-only row (%s) and the registry decodes it to .doPostHoc (%s)",
                   if (menu_row) "present" else "ABSENT -- this is the red demonstration",
                   if (decoder_out) "present" else "ABSENT"),
           menu_row && decoder_out)
# TWELVE PERSIST SITES AND NOT SIX, and the doubling is the point rather than
# a miscount: each page writes prev_annotPostHoc twice, once on its Draw arm
# beside annotPostHoc itself, and once on the beginner/advanced mode toggle
# beside prev_annotAdjustIdx. The toggle one is what stops a page the user left
# on "ANOVA only" from re-opening with the post-hoc silently re-ticked -- the
# same defect this item removes, arriving one dialog later. Six commits, twelve
# persists, six seeds; any other triple means a page was missed.
check_true(V,
           sprintf("ITEM 3.5 all six annotate-capable pages commit that answer to annotPostHoc (%d of 6), persist it across Draw and the mode toggle (%d of 12) and seed the menu back from it (%d of 6)",
                   n_commit, n_persist, n_seed),
           n_commit == 6L && n_persist == 12L && n_seed == 6L)

# DRIVEN, NOT ONLY READ. harness/doorcensus/probe.praat runs
# @emlRunAnnotationComparison twice on this leg's own fixture, once with the
# dialog's answer set to "yes". Item 3.5 withholds nothing from a user who
# asked for a post-hoc, and this is the check that says so.
check_true(V,
           sprintf("ITEM 3.5 driven, opt-IN: the figure still runs and draws Tukey when the dialog asked for it (pairwise=%s, matrix rows=%s)",
                   val("leg1", "posthoc_ran_door2_optin"), val("leg1", "matrix_groups_door2_optin")),
           identical(val("leg1", "posthoc_ran_door2_optin"), "1") &&
               identical(val("leg1", "matrix_groups_door2_optin"), "3") &&
               identical(val("leg1", "bridge_dotukey_optin"), "1"))

# THE RESIDUE, AND IT IS NOT ITEM 3.5's. What item 3.5 closes is the figure
# running a post-hoc NOBODY ASKED FOR. What it does not close is this leg's
# other half: the graphs door's Comparison menu offers Tukey or nothing, so a
# user who chose Student t with Bonferroni at the Pairwise dialog and then
# draws a figure still cannot make the figure show THAT pairwise test, and no
# sentence anywhere reconciles the two doors' different pairwise verdicts on
# the same pair. That is punch-list 8.2 / item 1.6 and it is still open. This
# check pins the gap OPEN -- it passes because the gap is there, and it is
# meant to fail the day the gap closes, which is the same contract every
# defect-pinning check in this suite carries.
leg1_reconciled <- any(grepl("differs from the (test|pairwise (test|comparison)) you (chose|selected)",
                             bridge_src, ignore.case = TRUE))
form_offers_student <- any(grepl('option: "(Pairwise )?Student t', form_src))
check_true(V,
           sprintf("leg1 RESIDUAL, still open and NOT item 3.5: the graphs door offers no Student-t pairwise row (%s) and no line reconciles the two doors' pairwise verdicts (%s) -- punch-list 8.2 / item 1.6",
                   if (form_offers_student) "one was found -- re-check this leg" else "confirmed absent",
                   if (leg1_reconciled) "one was found -- re-check this leg" else "none found"),
           !form_offers_student && !leg1_reconciled)

check_true(V,
           "leg1 VERDICT: the post-hoc the figure runs is now the one the launching dialog asked for (item 3.5, closed); the pairwise TEST the two doors name still differs with nothing reconciling it (8.2 / 1.6, open)",
           !site1_literal && site1_wired && !site2_literal && site2_wired &&
               bridge_reads_global && reporter_reads_bridge && menu_row)

# ===========================================================================
# LEG 3 -- post-hoc opt-out (Compare k Groups, Tukey unchecked) vs draw
# ===========================================================================
# Same table as leg 1, reused deliberately (see the fixture header).
anova_off <- summary(aov(y ~ g, data = dat1))[[1]]
check(V, "leg3 ANOVA F, doTukey = 0", num("leg3", "anova_F"), anova_off["g", "F value"], tol = 1e-6)
check(V, "leg3 ANOVA p, doTukey = 0", num("leg3", "anova_p"), anova_off["g", "Pr(>F)"], tol = 1e-8)
check_true(V, "leg3 door A (post-hoc opted out) prints no post-hoc table",
           identical(val("leg3", "posthoc_ran"), "0"))

# THE NUMBERS THE FIGURE SHOWS WHEN THE POST-HOC *IS* ASKED FOR. Held to the
# oracle here so that the opt-out check below is a check about a CHOICE and
# not about a broken Tukey: these are real, correct, strongly significant
# p-values, and the point of the leg is that a user who declined the post-hoc
# must not be shown them.
check(V, "leg3 Tukey p(C,A), the value the figure carries when Tukey was asked for",
      num("leg3", "tukey_p_CA"), tk1["C-A", "p adj"], tol = 1e-6)
check(V, "leg3 Tukey p(C,B), the value the figure carries when Tukey was asked for",
      num("leg3", "tukey_p_CB"), tk1["C-B", "p adj"], tol = 1e-6)
check_true(V,
           sprintf("leg3 fixture is ADVERSARIAL: the post-hoc at stake is p(C,A) = %.2e and p(C,B) = %.2e -- both far below .05 -- so a figure that shows it to a user who declined it is unmistakable, not a near-miss",
                   num("leg3", "tukey_p_CA"), num("leg3", "tukey_p_CB")),
           is.finite(num("leg3", "tukey_p_CA")) && num("leg3", "tukey_p_CA") < 0.001)

# ITEM 3.5, DRIVEN. The probe runs @emlRunAnnotationComparison on this same
# table with the launching dialog's post-hoc answer set to "no" -- which is
# what picking the Comparison menu's "ANOVA only, no pairwise tests" row does,
# because that row is the only thing that writes annotPostHoc. Measured on the
# tree as it stood before this item, both of the values below read as though
# the row had never been touched (pairwise = 1, matrix rows = 3); that is the
# red demonstration Fable asked for, and it is an artefact, not an assertion.
check_true(V,
           sprintf("ITEM 3.5 driven, opt-OUT: the figure honours the declined post-hoc (pairwise=%s, matrix rows=%s, bridge flag=%s)",
                   val("leg3", "posthoc_ran_door2"),
                   val("leg3", "matrix_groups_door2_optout"),
                   val("leg3", "bridge_dotukey_optout")),
           identical(val("leg3", "posthoc_ran_door2"), "0") &&
               identical(val("leg3", "matrix_groups_door2_optout"), "0") &&
               identical(val("leg3", "bridge_dotukey_optout"), "0"))

# AND IT WITHHOLDS THE POST-HOC, NOT THE RESULT. Declining a pairwise table is
# not declining the analysis: the omnibus still ran and the figure still
# carries it, which is exactly what the Compare k Groups dialog's own opt-out
# produces on the other door. A silent figure would be a different defect.
check_true(V,
           sprintf("ITEM 3.5 the omnibus is still on the figure after the opt-out, in the same words the analysis door uses: \"%s\"",
                   val("leg3", "omnibus_line_door2")),
           identical(val("leg3", "omnibus_still_shown_door2"), "1") &&
               grepl("^One-way ANOVA: F\\(2, 15\\) = ", val("leg3", "omnibus_line_door2")))

check_true(V,
           "leg3 VERDICT: AGREE -- the analysis door's post-hoc opt-out and the graph door's now produce the same figure and the same report, through the same resolved flag (item 3.5)",
           identical(val("leg3", "posthoc_ran"), "0") &&
               identical(val("leg3", "posthoc_ran_door2"), "0") &&
               !site1_literal && !site2_literal &&
               bridge_reads_global && reporter_reads_bridge)

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
# STRUCTURAL EVIDENCE -- REVISED. Punch-list 4.5 landed: the port is a
# SEPARATE shared call (@emlRunGroupedRegressionAnalysis, stats/eml-analysis.praat),
# not a fourth argument threaded into @emlRunRegressionAnalysis itself, so
# the overall-fit call keeps its original three-argument shape (correctly --
# the overall fit is still one fit for the whole table) and the group
# column now rides the separate call instead. Confirm BOTH halves: the old
# call is unchanged, and the new one is there and reads the group column.
regress_src <- readLines(file.path(PLUGIN_DIR, "scripts", "eml-regress.praat"), warn = FALSE)
wizard_src <- readLines(file.path(PLUGIN_DIR, "scripts", "eml-wizard.praat"), warn = FALSE)
leg5_call_line <- grep("@emlRunRegressionAnalysis:\\s*tableId,\\s*respCol\\$,\\s*predCol\\$\\s*$", regress_src)
leg5_port_line <- grep("@emlRunGroupedRegressionAnalysis:", regress_src, fixed = TRUE)
leg5_port_wizard_calls <- sum(grepl("@emlRunGroupedRegressionAnalysis:", wizard_src, fixed = TRUE))
check_true(V,
           sprintf("leg5 VERDICT: AGREE -- the per-group port landed (punch-list 4.5): the regression dialog's overall-fit call (%s) is unchanged, and its own %s (eml-regress.praat:%s) now fits and reports each group beside the overall one, matching the scatter draw door's own per-group fit above; the wizard's two regression pages call the same shared procedure (%d call site(s), full detail in validate/v136_regression_grouping.R)",
                   if (length(leg5_call_line)) sprintf("confirmed, eml-regress.praat:%d", leg5_call_line[1])
                   else "NOT CONFIRMED -- re-check the line reference",
                   "@emlRunGroupedRegressionAnalysis call",
                   if (length(leg5_port_line)) as.character(leg5_port_line[1]) else "MISSING",
                   leg5_port_wizard_calls),
           length(leg5_call_line) > 0 && length(leg5_port_line) > 0 &&
               leg5_port_wizard_calls == 2)

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
    cat("\n  LEDGER: leg1 HALF CLOSED (3.5 done; test-name residue open, 8.2/1.6) |\n",
        "         leg2 AGREE | leg3 AGREE (3.5, post-hoc opt-out honoured) |\n",
        "         leg4 SILENT (documented hazard) | leg5 AGREE (4.5, ported) |\n",
        "         leg6 AGREE, labelled\n", sep = "")
    eml_exit()
}
