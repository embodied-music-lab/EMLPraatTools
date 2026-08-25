# ============================================================================
# v122 — a post-hoc the user chose runs, and the report says what it means
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# THE RULING THIS ENFORCES. Punch list 2026-08-25, lane 3: post-hocs are never
# gated on the omnibus, on any door; the "if ANOVA significant" clauses come
# off the wizard's rows; a post-hoc that ran under a quiet omnibus carries one
# cautionary line; and an effect-size matrix printed with the post-hoc off
# carries one caption. The wording of both lines is language batch items 11
# and 12 and is asserted here VERBATIM, because both were approved as text.
#
# WHY A PRESENCE CHECK IS THE POINT, AND WHY IT HAD TO BE DRIVEN. The defect
# this lane closes did not produce a wrong number. It produced NOTHING: the
# user picked "Scheffe" on the wizard's post-hoc menu, the plan printed
# "Post-hoc: Scheffe if ANOVA significant", the ANOVA came back at p = .12,
# and the report ended without a Scheffe table and without a word about why.
# No arithmetic check in this suite could see that, because the arithmetic
# that was missing was never performed. What sees it is a fixture driven
# through every door with the output recorded, which is harness/posthocgate.
#
# WHAT THE FIXTURE IS FOR. harness/posthocgate/fixture_kgroups.csv gives
# one-way ANOVA F(2, 21) = 2.346, p = .120 and Kruskal-Wallis H(2) = 3.515,
# p = .173 — above .05 AND above .01, so every gate that ever stood here is
# closed on it — while Soprano vs Alto is far enough apart that Tukey, Dunn
# and Scheffe all have something to print. Presence and absence are therefore
# a property of the POLICY, not of the data being too flat to say anything.
#
# THE ORACLE. The p-values the post-hoc tables carry are checked against R's
# own aov / TukeyHSD / kruskal.test on the same committed fixture, so this
# file cannot pass by finding a table full of anything at all. Base R only.
#
# TWO HALVES, and the second is the ratchet:
#
#   1. DRIVEN. harness/posthocgate/out/*.txt — one captured report per door,
#      plus the wizard's own Info window read out of a live GUI instance
#      under Xvfb. Post-hoc present, caution present, caption present, level
#      in force honoured at .05 and at .01.
#   2. STATIC. No omnibus gate anywhere in the shipping tree. The population
#      is derived by reading every call to a post-hoc, pairwise or
#      effect-size-matrix producer together with the `if` conditions
#      enclosing it, and it must be EMPTY. The sites that legitimately test a
#      p-value near one of these calls are named individually with the reason,
#      so this check is a list that can shrink and not a pattern that can be
#      quietly widened.
#
# ANTI-VACUOUS. Every section counts what it examined and asserts the count,
# so a rig that produced no artefacts, or a reader that matched nothing, is a
# FAIL rather than a silent pass.
#
# $EML_PHG_OUT points this file at another set of artefacts, which is how the
# red demonstration is read: the same rig driven against a worktree of the
# pre-fix commit writes there, and every check below goes red against it.
# $EML_PHG_SRC does the same for the source half.
#
# Input:  harness/posthocgate/out/*.txt, POSTHOCGATE.tsv, fixture_kgroups.csv
# Source: plugin_EML_StatsGraphs/{scripts,stats,graphs}
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

V <- "v122"

OUT <- Sys.getenv("EML_PHG_OUT", unset = repo_path("harness", "posthocgate", "out"))
SRC <- Sys.getenv("EML_PHG_SRC", unset = repo_path("plugin_EML_StatsGraphs"))
FIX <- repo_path("harness", "posthocgate", "fixture_kgroups.csv")
FIXSIG <- repo_path("harness", "posthocgate", "fixture_kgroups_sig.csv")

# The approved strings, once. Every assertion below reads these rather than
# spelling the sentence again, so an amendment to the language batch changes
# one place in this file and shows up in every check at once.
CAUTION_05 <- paste("The overall test did not reach significance at the .05",
                    "level; interpret individual pairwise results with caution.")
CAUTION_01 <- sub("\\.05", ".01", CAUTION_05)
CAPTION_DISCLOSURE  <- "No pairwise significance tests were run."
CAPTION_EXPLANATION <- "Effect sizes estimate the size of each pairwise difference."

# The report wraps at 68 columns, so a sentence arrives as two lines with
# leading indent. Comparison is therefore against the whole capture with its
# whitespace collapsed — the wording is asserted, the wrapping is not.
flat <- function(path) {
    if (!file.exists(path)) return(NA_character_)
    txt <- paste(readLines(path, warn = FALSE), collapse = " ")
    gsub("[[:space:]]+", " ", txt)
}

legs <- list()
leg_files <- c("anova_tukey", "anova_notukey", "kw_dunn", "kw_nodunn",
               "pairwise_scheffe", "pairwise_welch_bh",
               "wizard_scheffe_dispatch", "rm_posthoc", "friedman_posthoc",
               "bridge_kw_matrix", "bridge_kw_brackets",
               "bridge_anova_brackets", "bridge_anova_matrix",
               "anova_tukey_alpha001", "kw_dunn_alpha001",
               "anova_tukey_sig", "kw_dunn_sig")
for (nm in leg_files) legs[[nm]] <- flat(file.path(OUT, paste0(nm, ".txt")))
wizard <- flat(file.path(OUT, "wizard_scheffe.info.txt"))

# ---------------------------------------------------------------------------
# 0. The rig ran, and every leg it claims completed did complete
# ---------------------------------------------------------------------------
present <- vapply(legs, function(x) !is.na(x), logical(1))
check_true(V, sprintf("every headless leg produced a capture (%d of %d)",
                      sum(present), length(present)),
           all(present))
check_true(V, "the wizard leg produced an Info-window capture",
           !is.na(wizard))
complete <- vapply(legs, function(x) !is.na(x) && grepl("== END ", x, fixed = TRUE),
                   logical(1))
check_true(V, sprintf("every headless leg reached its own end marker (%d)",
                      sum(complete)),
           all(complete))

tsvp <- file.path(OUT, "POSTHOCGATE.tsv")
check_true(V, "the rig's TSV is present", file.exists(tsvp))
if (file.exists(tsvp)) {
    tsv <- read.delim(tsvp, stringsAsFactors = FALSE, quote = "")
    check_true(V, "the rig recorded a returned status of 0 for every headless leg",
               all(tsv$value[tsv$key == "returned"] == "0"))
    check_true(V, "the wizard leg walked its pages rather than failing the rig",
               any(tsv$key == "state" & tsv$value == "walked"))
    check_true(V, "the wizard leg raised no Praat error",
               any(tsv$key == "praat_error" & tsv$value == "0"))
    trail <- tsv$value[tsv$leg == "wizard_scheffe" & tsv$key == "trail"]
    check_true(V, "the wizard walk reached the k-group test page",
               length(trail) == 1L && grepl("Three or More Groups", trail))
    check_true(V, "and came out the other side at the analysis-complete page",
               length(trail) == 1L && grepl("Analysis complete", trail))
}

# ---------------------------------------------------------------------------
# 1. THE ACCEPTANCE, as the punch list words it: non-significant omnibus,
#    post-hoc chosen -> the post-hoc table AND the caution line
# ---------------------------------------------------------------------------
# The wizard first, because the wizard is where the defect was.
check_true(V, "WIZARD: the plan names the post-hoc the user chose",
           !is.na(wizard) && grepl("Post-hoc: Scheffe, all pairs", wizard))
check_true(V, "WIZARD: the plan value carries no gating clause",
           !is.na(wizard) && !grepl("if ANOVA significant", wizard))
check_true(V, "WIZARD: the ANOVA it ran is the non-significant one (p = .120)",
           !is.na(wizard) && grepl("F 2.3460", wizard))
check_true(V, "WIZARD: the post-hoc RAN — the Scheffe report is in the window",
           !is.na(wizard) && grepl("Scheffe Post-Hoc Comparisons", wizard))
check_true(V, "WIZARD: and its per-pair table is there, not just its header",
           !is.na(wizard) && grepl("Alto vs Soprano", wizard))
check_true(V, "WIZARD: the caution line is present, verbatim",
           !is.na(wizard) && grepl(CAUTION_05, wizard, fixed = TRUE))
# The plan's own field values, read through the same whitespace collapse
# everything else here uses — the report pads these columns.
check_true(V, "WIZARD: it analysed the fixture's own columns",
           !is.na(wizard) && grepl("Data column: F0 Hz", wizard, fixed = TRUE) &&
           grepl("Group column: voice type", wizard, fixed = TRUE))

# The same claim at the engine, on every door that runs an omnibus and a
# post-hoc together.
door_caution <- c(anova_tukey = "Tukey HSD Pairwise Comparisons",
                  kw_dunn = "Dunn's Post-Hoc",
                  bridge_anova_matrix = "Tukey HSD Pairwise Comparisons",
                  bridge_kw_matrix = "Dunn's Post-Hoc",
                  rm_posthoc = "Post-hoc pairwise",
                  friedman_posthoc = "Post-hoc pairwise",
                  wizard_scheffe_dispatch = "Scheffe Post-Hoc Comparisons")
for (nm in names(door_caution)) {
    txt <- legs[[nm]]
    check_true(V, sprintf("%s: the post-hoc table is present", nm),
               !is.na(txt) && grepl(door_caution[[nm]], txt, fixed = TRUE))
    check_true(V, sprintf("%s: the caution line is present, verbatim", nm),
               !is.na(txt) && grepl(CAUTION_05, txt, fixed = TRUE))
}
check_true(V, sprintf("the caution was asserted on every door that runs one (%d)",
                      length(door_caution)),
           length(door_caution) == 7L)

# ---------------------------------------------------------------------------
# 1b. THE HOLE THIS CLOSES: a SIGNIFICANT omnibus, so the caution must be
#     ABSENT. Every leg above uses fixture_kgroups.csv, whose omnibus never
#     clears .05 -- so until this section, nothing in this file ever
#     asserted the caution's ABSENCE, only its presence. A regression that
#     printed the caution after every post-hoc, gated or not, would have
#     left this file green at its old count. fixture_kgroups_sig.csv gives
#     one-way ANOVA p = 1.34e-7 and Kruskal-Wallis p = 1.23e-4 -- both far
#     below .05 AND .01 -- while still separating every pair enough for
#     Tukey and Dunn to have something to print, so presence-of-table and
#     absence-of-caution are tested on the same kind of report as the rest
#     of this file, not on a degenerate one.
#
# THE RULING ITSELF IS UNCHANGED HERE: 3.1 already means the post-hoc runs
# whether the omnibus is significant or not. What this section adds is the
# other arm of 3.3 -- "when the omnibus is not significant ... adds" implies
# it is NOT added when the omnibus IS significant, and until now nothing
# exercised a fixture where that mattered.
sig_caution <- c(anova_tukey_sig = "Tukey HSD Pairwise Comparisons",
                 kw_dunn_sig = "Dunn's Post-Hoc")
for (nm in names(sig_caution)) {
    txt <- legs[[nm]]
    check_true(V, sprintf("%s: the post-hoc table is present (never gated, per 3.1)", nm),
               !is.na(txt) && grepl(sig_caution[[nm]], txt, fixed = TRUE))
    check_true(V, sprintf("%s: the caution line is ABSENT -- the omnibus WAS significant", nm),
               !is.na(txt) && !grepl(CAUTION_05, txt, fixed = TRUE) &&
               !grepl(CAUTION_01, txt, fixed = TRUE))
}
check_true(V, sprintf("the absence was asserted on every door driven against the significant fixture (%d)",
                      length(sig_caution)),
           length(sig_caution) == 2L)

# THE ORACLE, on the significant fixture, so presence-of-table is a claim
# about the right numbers and not merely about some table appearing.
dsig <- read.csv(FIXSIG, stringsAsFactors = FALSE)
dsig$voice_type <- factor(dsig$voice_type, levels = unique(dsig$voice_type))
fitsig <- aov(F0_Hz ~ voice_type, data = dsig)
aovpsig <- summary(fitsig)[[1]][["Pr(>F)"]][1]
kwsig <- kruskal.test(F0_Hz ~ voice_type, data = dsig)
check_true(V, "the significant fixture's ANOVA omnibus clears .05 AND .01 (the premise)",
           aovpsig < 0.01)
check_true(V, "and its Kruskal-Wallis omnibus does too",
           kwsig$p.value < 0.01)
tuksig <- TukeyHSD(fitsig)$voice_type
check(V, "Tukey p, Soprano vs Mezzo -- the one pair on this fixture that does not floor at APA's .001, so it is the pair worth matching exactly",
      0.012, round(unname(tuksig["Soprano-Mezzo", "p adj"]), 3), tol = 5e-4)
check_true(V, "and the ANOVA report printed that same p in its Tukey matrix",
           !is.na(legs$anova_tukey_sig) &&
           grepl("Soprano < .001 .012 ---", legs$anova_tukey_sig, fixed = TRUE))
check_true(V, "the two floored pairs print APA's < .001 rather than a fabricated exact value",
           !is.na(legs$anova_tukey_sig) &&
           grepl("Alto --- < .001 < .001", legs$anova_tukey_sig, fixed = TRUE))

# ---------------------------------------------------------------------------
# 2. THE LEVEL IS THE ALPHA IN FORCE, not a literal
# ---------------------------------------------------------------------------
# Same fixture, same doors, alpha moved to .01. A hardcoded .05 in the
# sentence survives this unchanged, which is the whole reason the leg exists.
for (nm in c("anova_tukey_alpha001", "kw_dunn_alpha001")) {
    txt <- legs[[nm]]
    check_true(V, sprintf("%s: the caution names the .01 level", nm),
               !is.na(txt) && grepl(CAUTION_01, txt, fixed = TRUE))
    check_true(V, sprintf("%s: and does not name .05", nm),
               !is.na(txt) && !grepl(CAUTION_05, txt, fixed = TRUE))
    check_true(V, sprintf("%s: the post-hoc still ran at the stricter level", nm),
               !is.na(txt) && (grepl("Tukey HSD Pairwise", txt) ||
                               grepl("Dunn's Post-Hoc", txt)))
}

# ---------------------------------------------------------------------------
# 3. THE EFFECT-SIZE CAPTION, with the post-hoc off
# ---------------------------------------------------------------------------
for (nm in c("anova_notukey", "kw_nodunn")) {
    txt <- legs[[nm]]
    check_true(V, sprintf("%s: the pairwise effect-size matrix still prints", nm),
               !is.na(txt) && grepl("Pairwise Effect Sizes", txt))
    check_true(V, sprintf("%s: the disclosure half of the caption is present, verbatim", nm),
               !is.na(txt) && grepl(CAPTION_DISCLOSURE, txt, fixed = TRUE))
    check_true(V, sprintf("%s: the explanation half is present, verbatim", nm),
               !is.na(txt) && grepl(CAPTION_EXPLANATION, txt, fixed = TRUE))
    # 3.4's standing rule. With no post-hoc there is no adjusted p, and an
    # uncorrected pairwise p must not appear in its place.
    check_true(V, sprintf("%s: no pairwise p-value column is printed", nm),
               !is.na(txt) && !grepl("p (raw)", txt, fixed = TRUE) &&
               !grepl("p (adj)", txt, fixed = TRUE))
}
# And the caption is NOT printed where a post-hoc did run: the sentence would
# be false, and a false disclosure is worse than none.
for (nm in c("anova_tukey", "kw_dunn")) {
    check_true(V, sprintf("%s: no 'no pairwise tests' caption where the post-hoc ran", nm),
               !is.na(legs[[nm]]) &&
               !grepl(CAPTION_DISCLOSURE, legs[[nm]], fixed = TRUE))
}
# The wizard's two-call shape is the case that makes that rule bite: its
# omnibus report has no Tukey, and its post-hoc arrives in the NEXT report.
check_true(V, "WIZARD: the caption is absent, because a pairwise table follows",
           !is.na(wizard) && !grepl(CAPTION_DISCLOSURE, wizard, fixed = TRUE))
check_true(V, "and the engine leg that mirrors the wizard's dispatch agrees",
           !is.na(legs$wizard_scheffe_dispatch) &&
           !grepl(CAPTION_DISCLOSURE, legs$wizard_scheffe_dispatch, fixed = TRUE))

# ---------------------------------------------------------------------------
# 4. THE FIGURE, not just the report
# ---------------------------------------------------------------------------
# On the graph door the post-hoc reaches the user as brackets. The pre-fix
# tree drew none of them on this fixture — bracketN = 0 on both arms — and the
# matrix layout was worse than empty: it filled every cell with the
# non-significant marker for pairs Dunn had never been asked about.
bracket_n <- function(txt) {
    if (is.na(txt)) return(NA_integer_)
    m <- regmatches(txt, regexpr("ANNOT bracketN=[0-9]+", txt))
    if (!length(m)) return(NA_integer_)
    as.integer(sub("ANNOT bracketN=", "", m))
}
for (nm in c("bridge_kw_brackets", "bridge_anova_brackets")) {
    check_true(V, sprintf("%s: the figure carries one bracket per pair (3)", nm),
               identical(bracket_n(legs[[nm]]), 3L))
}
check_true(V, "bridge_kw_matrix: no cell is the fabricated n.s. marker",
           !is.na(legs$bridge_kw_matrix) &&
           !grepl("ANNOT cell 1-2 = n.s.", legs$bridge_kw_matrix, fixed = TRUE))
check_true(V, "bridge_kw_matrix: the cells carry Dunn's own adjusted p",
           !is.na(legs$bridge_kw_matrix) &&
           grepl("ANNOT cell 1-3 = p = .183", legs$bridge_kw_matrix, fixed = TRUE))
check_true(V, "bridge_kw_matrix: and the report carries Dunn's table",
           !is.na(legs$bridge_kw_matrix) &&
           grepl("Dunn's Post-Hoc", legs$bridge_kw_matrix, fixed = TRUE))

# ---------------------------------------------------------------------------
# 5. THE ORACLE — the tables that appeared carry the right numbers
# ---------------------------------------------------------------------------
# Presence is the lane's claim; correctness is what makes presence worth
# having. Every value below is recomputed in base R from the committed
# fixture and matched against the string the plugin printed.
d <- read.csv(FIX, stringsAsFactors = FALSE)
d$voice_type <- factor(d$voice_type, levels = unique(d$voice_type))
fit <- aov(F0_Hz ~ voice_type, data = d)
aovp <- summary(fit)[[1]][["Pr(>F)"]][1]
tuk  <- TukeyHSD(fit)$voice_type
kw   <- kruskal.test(F0_Hz ~ voice_type, data = d)

check(V, "the fixture's ANOVA p, as the report printed it",
      0.120, round(aovp, 3), tol = 5e-4)
check_true(V, "the fixture's omnibus is NOT significant at .05 (the premise)",
           aovp > 0.05)
check_true(V, "nor at .01, so the alpha leg tests the same premise",
           aovp > 0.01)
check_true(V, "the Kruskal-Wallis omnibus is not significant either",
           kw$p.value > 0.05)
# Soprano vs Alto: the pair the post-hoc exists to report on this fixture.
check(V, "Tukey p for Soprano vs Alto, as the ANOVA report printed it",
      0.101, round(unname(tuk["Soprano-Alto", "p adj"]), 3), tol = 5e-4)
check_true(V, "the ANOVA report printed that p in its Tukey matrix",
           !is.na(legs$anova_tukey) && grepl(" .101 ", legs$anova_tukey, fixed = TRUE))
check_true(V, "and the figure's bracket for that pair carries the same p",
           !is.na(legs$bridge_anova_brackets) &&
           grepl("bracket 1-3 p=0.1007", legs$bridge_anova_brackets, fixed = TRUE))
# The uncorrected pair is BELOW .05 — which is exactly why an uncorrected
# pairwise p is never printed and why the caution line is worth its space.
# Uncorrected here means the pooled-SD pairwise t every one of these post-hocs
# is built on (R's pairwise.t.test with no adjustment), not a two-sample t on
# the pair alone: the pooled version is the one whose p a bare-LSD post-hoc
# would print, and it is the smaller of the two (.042 against .052).
raw <- pairwise.t.test(d$F0_Hz, d$voice_type, p.adjust.method = "none")$p.value
raw_sa <- raw["Soprano", "Alto"]
check(V, "the same pair uncorrected, pooled SD", 0.042, round(raw_sa, 3), tol = 5e-4)
check_true(V, "which would read as significant while the omnibus does not",
           raw_sa < 0.05 && aovp > 0.05)

# ---------------------------------------------------------------------------
# 6. THE RATCHET — no omnibus gate survives anywhere in the shipping tree
# ---------------------------------------------------------------------------
# Derived, not spot-checked: every line in the shipping tree that calls a
# post-hoc, pairwise or effect-size producer is read together with the `if`
# conditions enclosing it, and any condition that mentions an omnibus p is a
# finding. The four the punch list removed are named so that a reader can see
# this list is a ratchet and not a fresh guess:
#
#   scripts/eml-wizard.praat          emlOneWayAnova.p < 0.05  (two calls)
#   graphs/eml-annotation-procedures  .pOmnibus < .alpha       (Dunn, figure)
#   graphs/eml-annotation-procedures  .pOmnibus < .alpha       (Tukey, figure)
#   graphs/eml-annotation-procedures  emlKruskalWallis.p < ... (bridge report)
producers <- paste0("@(emlDunnTest|emlTukeyHSD|emlGamesHowell|emlScheffe|",
                    "emlPairwiseT|emlPairwiseWilcoxon|emlRunPairwiseAnalysis|",
                    "emlRMPostHoc|emlCohenD|emlRankBiserialR|",
                    "emlReportPairwiseComparison|emlReportKWComparison|",
                    "emlReportAnovaComparison)\\b")
omnibus_p <- paste0("(emlOneWayAnova|emlKruskalWallis|emlFriedmanTest|",
                    "emlRMAnovaTest|emlWelchAnova|emlTwoWayAnova)\\.p",
                    "|\\bpOmnibus\\b|\\bomnibusP\\b")

src_files <- c(
    file.path(SRC, "scripts", list.files(file.path(SRC, "scripts"), pattern = "\\.praat$")),
    file.path(SRC, "stats",   list.files(file.path(SRC, "stats"),   pattern = "\\.praat$")),
    file.path(SRC, "graphs",  list.files(file.path(SRC, "graphs"),  pattern = "\\.praat$")))
src_files <- src_files[file.exists(src_files)]

findings <- character(0)
n_calls <- 0L
n_lines <- 0L
for (f in src_files) {
    lines <- readLines(f, warn = FALSE)
    n_lines <- n_lines + length(lines)
    stack <- character(0)
    for (i in seq_along(lines)) {
        s <- trimws(lines[i])
        if (grepl("^[#;]", s)) next
        if (grepl("^endif\\b", s)) {
            if (length(stack)) stack <- stack[-length(stack)]
        } else if (grepl("^if\\s", s)) {
            stack <- c(stack, s)
        } else if (grepl("^elsif\\s", s)) {
            if (length(stack)) stack[length(stack)] <- s
        }
        if (grepl(producers, s) && !grepl("^procedure\\b", s)) {
            n_calls <- n_calls + 1L
            bad <- stack[grepl(omnibus_p, stack)]
            if (length(bad)) {
                findings <- c(findings,
                              sprintf("%s:%d under `%s`", basename(f), i, bad[1]))
            }
        }
    }
}
check_true(V, sprintf("the sweep read the whole shipping tree (%d files, %d lines)",
                      length(src_files), n_lines),
           length(src_files) >= 25L && n_lines > 20000L)
check_true(V, sprintf("and found the post-hoc call sites it was pointed at (%d)",
                      n_calls),
           n_calls >= 15L)
check_true(V, sprintf("NO post-hoc, pairwise or effect-size call is under an omnibus p (%d found)",
                      length(findings)),
           length(findings) == 0L)
if (length(findings)) for (x in findings) cat("        v122 GATE: ", x, "\n", sep = "")

# The hardcoded level disappears with the gate it belonged to: the wizard
# collects no alpha and must contain no significance threshold of its own.
wiz <- readLines(file.path(SRC, "scripts", "eml-wizard.praat"), warn = FALSE)
wiz_code <- wiz[!grepl("^\\s*[#;]", wiz)]
# CONDITIONS, not prose. The wizard's normality section still PRINTS
# "(p < 0.05)" inside two message strings; those are Shapiro-Wilk report text
# and belong to the normality lane, not to this one. What must not exist is a
# BRANCH taken on a hardcoded significance level.
wiz_cond <- wiz_code[grepl("^\\s*(if|elsif)\\s", wiz_code)]
check_true(V, sprintf("no branch in the wizard tests a hardcoded .05 (%d conditions read)",
                      length(wiz_cond)),
           length(wiz_cond) > 40L && !any(grepl("<\\s*0\\.05", wiz_cond)))
check_true(V, "the wizard's post-hoc rows carry no gating clause",
           !any(grepl("if ANOVA significant", wiz_code)))
check_true(V, "the Scheffe row names its test and its scope, verbatim",
           any(grepl('option: "Scheffe, all pairs (conservative)"', wiz_code, fixed = TRUE)))
check_true(V, "the pairwise-Welch row names its test and its adjustment, verbatim",
           any(grepl('option: "Pairwise Welch t, Benjamini-Hochberg (less strict)"',
                     wiz_code, fixed = TRUE)))
check_true(V, "the k-group page no longer promises the gate in prose",
           !any(grepl("If the overall test is significant", wiz_code)))
check_true(V, "and carries the approved paragraph in its place",
           any(grepl("Pairwise comparisons run when you choose them", wiz_code, fixed = TRUE)))

# ---------------------------------------------------------------------------
# 7. THE CANON IS STATED ONCE
# ---------------------------------------------------------------------------
# Both sentences live in one procedure each, and every door calls it. A second
# copy anywhere is how two doors start saying almost the same thing.
# CODE ONLY. Both sentences are QUOTED in the comments that explain them,
# which is the right place for them and not a second copy of the canon.
all_src <- unlist(lapply(src_files, readLines, warn = FALSE))
all_code <- all_src[!grepl("^\\s*[#;]", all_src)]
n_caution <- sum(grepl("did not reach significance", all_code))
n_caption <- sum(grepl("No pairwise significance tests were run", all_code))
check_true(V, sprintf("the caution sentence is written once (%d)", n_caution),
           n_caution == 1L)
check_true(V, sprintf("the caption sentence is written once (%d)", n_caption),
           n_caption == 1L)
ana <- readLines(file.path(SRC, "stats", "eml-analysis.praat"), warn = FALSE)
check_true(V, "@emlPostHocCaution exists, once",
           sum(grepl("^procedure emlPostHocCaution\\b", ana)) == 1L)
check_true(V, "@emlEffectMatrixCaption exists, once",
           sum(grepl("^procedure emlEffectMatrixCaption\\s*$", ana)) == 1L)
# The level is taken from the alpha in force. A literal in the sentence is the
# defect this replaced, so the procedure must reach @emlReportAlpha and must
# not spell a level of its own.
cau0 <- grep("^procedure emlPostHocCaution\\b", ana)
cau1 <- if (length(cau0)) grep("^endproc", ana)[grep("^endproc", ana) > cau0[1]][1] else NA
body <- if (length(cau0) && !is.na(cau1)) ana[cau0[1]:cau1] else character(0)
body <- body[!grepl("^\\s*[#;]", body)]
check_true(V, sprintf("@emlPostHocCaution's body was located (%d code lines)",
                      length(body)),
           length(body) > 8L)
check_true(V, "it takes the level from @emlReportAlpha",
           any(grepl("@emlReportAlpha", body, fixed = TRUE)))
check_true(V, "and spells no level of its own",
           !any(grepl("0\\.05|0\\.01|\\.05 level|5% level", body)))
check_true(V, "the caution is routed as an EXPLANATION (language batch item 11)",
           any(grepl("emlShowExplanations", body, fixed = TRUE)))
# The caption's DISCLOSURE half must NOT be behind the toggle. Asserted
# structurally: the disclosure line comes before the `if emlShowExplanations`
# inside the procedure.
cap0 <- grep("^procedure emlEffectMatrixCaption\\s*$", ana)
cap1 <- if (length(cap0)) grep("^endproc", ana)[grep("^endproc", ana) > cap0[1]][1] else NA
cbody <- if (length(cap0) && !is.na(cap1)) ana[cap0[1]:cap1] else character(0)
i_disc <- which(grepl("No pairwise significance tests were run", cbody))[1]
i_gate <- which(grepl("if emlShowExplanations", cbody))[1]
check_true(V, "the caption's disclosure half is printed before any explanations gate",
           !is.na(i_disc) && !is.na(i_gate) && i_disc < i_gate)

if (!exists("EML_SUITE")) {
    eml_report("v122 post-hocs are never gated on the omnibus")
    eml_exit()
}
