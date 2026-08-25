# ============================================================================
# v132 -- the DISCLOSURE / EXPLANATION split, over whole reports
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# THE RULE THIS ENFORCES, in the language batch's own words
# (LANGUAGE_BATCH_2026-08-25.md, revision 3's routing pass):
#
#     A fact a user needs is never carried by a line the toggle can remove.
#
# Every user-facing line in that batch is classified either DISCLOSURE --
# prints on every path, because it states what was or was not computed -- or
# EXPLANATION -- prints only where the explanations routing turns it on.
#
# WHY THIS FILE EXISTS BESIDE v130 AND v131. Those two each prove that ONE
# NAMED SENTENCE appears or disappears where it should: v130 the effect-matrix
# caption, v131 the seven reporters lane 6.2 wired. Both are presence tests on
# a list of sentences their own authors wrote. Neither can see the failure mode
# the split was invented to prevent, which is not "a sentence went missing" but
# "a NUMBER went missing with it" -- a fact that only ever printed on a line
# the toggle removes. That failure is invisible to a check that looks for the
# sentences it already knows about, because the vanished fact is by definition
# not on the list.
#
# SO THIS FILE DOES NOT WORK FROM A LIST. It subtracts the toggle-off report
# from the toggle-on report, mechanically, over nineteen analyses, and
# inspects WHAT THE SUBTRACTION REMOVED -- whatever that turns out to be.
#
# THE TWO SHAPES AN EXPLANATION LEGITIMATELY TAKES, both derived from the
# source rather than assumed:
#
#   * A SUFFIX on a statistic row. @emlReportLine and @emlReportLineString
#     (stats/eml-output.praat) append emlWizardExplain$ after TWO TABS when
#     emlShowExplanations is set. The row, and therefore the number, is
#     printed identically either way; only the suffix comes and goes.
#   * A WHOLE LINE of prose -- the "Why:" headers, @emlPostHocCaution's
#     caution, @emlEffectMatrixCaption's second sentence -- which is absent
#     entirely with the toggle off.
#
# THE ASSERTIONS, per analysis:
#
#   1. NOTHING IS LOST. Every labelled statistic row on the toggle-on leg
#      appears, byte-identical once its two-tab suffix is cut, on the
#      toggle-off leg. A number that only exists with explanations on fails
#      here.
#   2. NOTHING IS GAINED IN REVERSE. Every line of the toggle-off leg appears
#      in the normalised toggle-on leg. A report that says something ONLY
#      when explanations are off (a shortened claim standing in for the
#      removed sentence, which revision 3 forbids by name) fails here.
#   3. NO REMOVABLE LINE IS A LABELLED STATISTIC ROW. This is the sharp form
#      of the rule. The plugin prints every fact as a padded label followed by
#      a value (@emlReportLine's own shape, two-space indent, label padded to
#      20). A line matching that shape which disappears when the toggle goes
#      off IS a fact riding on a removable line, whatever it says.
#   4. THE TOGGLE-OFF LEG CARRIES NO TWO-TAB SUFFIX ANYWHERE. The gate is
#      total, not partial: one reporter that forgot to guard its
#      @emlWizardExplain* call would show up here as a stray suffix.
#
# ANTI-VACUITY. A rig whose legs came back empty, or whose two legs were
# accidentally the same leg, would satisfy every assertion above trivially.
# So: each capture must have a body; each pair must DIFFER; and the file
# prints the total population of removable lines it examined, with the census
# by analysis, so a reader can see the subtraction did work rather than
# take it on trust.
#
# THE NAMED LINES ARE CHECKED TOO (section 2), but as a supplement to the
# mechanical pass above and never as a substitute for it: the two halves of
# language batch item 12 land on opposite sides of the toggle, and item 11's
# caution -- the round's most consequential EXPLANATION line, because it is
# the one that talks ABOUT a number -- is present with explanations on,
# absent with them off, and its omnibus p is on the page either way.
#
# THE RED DEMONSTRATION is harness/routingsplit/break.sh: a scratch copy of
# the plugin in which @emlEffectMatrixCaption's DISCLOSURE sentence is moved
# inside the same `if emlShowExplanations` its EXPLANATION sentence already
# sits in -- one fact, moved behind the toggle, which is the defect class in
# its purest form -- re-driven through this file's own rig via
# $EML_RS_SRC / $EML_RS_OUT.
#
# Base R only. Reads harness/routingsplit's committed output and the plugin
# source; drives nothing itself.
# ============================================================================

if (!exists("check_true")) source(file.path(
    Sys.getenv("EML_VALIDATE_DIR", unset = "validate"), "helpers.R"))

V <- "v132"

RS_OUT <- Sys.getenv("EML_RS_OUT", unset = repo_path("harness", "routingsplit", "out"))
RS_SRC <- Sys.getenv("EML_RS_SRC", unset = repo_path("plugin_EML_StatsGraphs"))

ANALYSES <- c("twogroup_both", "twogroup_welch", "twogroup_mwu",
              "anova_tukey", "anova_only", "kw_dunn", "kw_only",
              "pairwise_welch", "pairwise_wilcoxon", "correlation_both",
              "regression", "descriptive", "normality", "paired_both",
              "rmanova", "friedman",
              "caution_anova", "caution_kw", "caution_pairwise")

DISCLOSURE_12 <- "No pairwise significance tests were run."
EXPLANATION_12 <- "Effect sizes estimate the size of each pairwise difference."
CAUTION_11_A <- "The overall test did not reach significance at the .05 level;"
CAUTION_11_B <- "interpret individual pairwise results with caution."

raw_lines <- function(path) {
    if (!file.exists(path)) return(character(0))
    readLines(path, warn = FALSE)
}

# The rig's own banner and the report's wall-clock line are not part of what
# the toggle controls: the banner names the leg (so it legitimately differs)
# and the clock ticks between two sequential Praat launches.
drop_noise <- function(x) {
    x <- x[!grepl("^== (LEG|END)", x)]
    x[!grepl("^\\s*[A-Za-z]{3} [A-Za-z]{3} +[0-9]+ [0-9:]+ [0-9]{4}\\s*$", x)]
}

# @emlReportLine's shape: two-space indent, a label, then the value after the
# padding that label was given. Two or more spaces between them is what makes
# it a ROW rather than a sentence -- prose has single spaces.
STAT_ROW <- "^  \\S.*?[ ]{2,}[-+0-9.]"

# Cut the two-tab explanation suffix @emlReportLine appends, leaving the row
# exactly as the toggle-off leg prints it.
cut_suffix <- function(x) sub("\t\t.*$", "", x)

n_removable_total <- 0L
n_rows_total <- 0L
census <- character(0)

# ===========================================================================
# 1. THE MECHANICAL PASS
# ===========================================================================
for (a in ANALYSES) {
    p_off <- file.path(RS_OUT, paste0(a, "_off.txt"))
    p_on  <- file.path(RS_OUT, paste0(a, "_on.txt"))
    have <- file.exists(p_off) && file.exists(p_on)
    check_true(V, sprintf("%s: both legs are on disk", a), have)
    if (!have) next

    off_raw <- raw_lines(p_off); on_raw <- raw_lines(p_on)
    check_true(V, sprintf("%s: the toggle-off leg ran to completion", a),
               any(grepl(paste0("^== END ", a, "_off =="), off_raw)))
    check_true(V, sprintf("%s: the toggle-on leg ran to completion", a),
               any(grepl(paste0("^== END ", a, "_on =="), on_raw)))

    off <- drop_noise(off_raw); on <- drop_noise(on_raw)
    check_true(V, sprintf("%s: both captures have a report body, not just a banner (%d / %d lines)",
                          a, length(off), length(on)),
               length(off) > 5 && length(on) > 5)

    # ANTI-VACUITY: the two legs must actually differ, or the pair proves
    # nothing about a toggle.
    check_true(V, sprintf("%s: the two legs are not identical -- the toggle did something", a),
               !identical(off, on))

    # 4. THE GATE IS TOTAL.
    stray <- off[grepl("\t\t", off, fixed = TRUE)]
    check_true(V,
        sprintf("%s: the toggle-off leg carries no two-tab explanation suffix anywhere (%d stray)",
                a, length(stray)),
        length(stray) == 0)

    on_cut <- cut_suffix(on)

    # 1. NOTHING IS LOST -- every statistic row printed with explanations on
    #    is printed identically with them off.
    # A row's VALUE must render identically too, not merely be present -- this
    # is what catches a number that came out differently on the two legs.
    # The count is reported, and the corpus-level floor below is where the
    # anti-vacuity lives: the repeated-measures and Friedman reporters compose
    # sentences rather than padded rows, so a per-analysis floor here would be
    # wrong for them and would have to be special-cased, which is how a check
    # starts describing its fixtures instead of its rule.
    on_rows <- unique(on_cut[grepl(STAT_ROW, on_cut)])
    n_rows_total <- n_rows_total + length(on_rows)
    lost <- setdiff(on_rows, off)
    check_true(V,
        sprintf("%s: every labelled statistic row survives the toggle going off, value and all (%d row(s), %d lost%s)",
                a, length(on_rows), length(lost),
                if (length(lost)) paste0(": ", paste(trimws(head(lost, 3)), collapse = " | ")) else ""),
        length(lost) == 0)

    # 2. NOTHING IS GAINED IN REVERSE -- no line exists only when the toggle
    #    is off (revision 3 forbids a shortened stand-in for a removed line).
    only_off <- setdiff(off, on_cut)
    check_true(V,
        sprintf("%s: no line appears ONLY when explanations are off (%d%s)",
                a, length(only_off),
                if (length(only_off)) paste0(": ", paste(trimws(head(only_off, 3)), collapse = " | ")) else ""),
        length(only_off) == 0)

    # 3. NO REMOVABLE LINE IS A LABELLED STATISTIC ROW.
    removable <- setdiff(on_cut, off)
    n_removable_total <- n_removable_total + length(removable)
    census <- c(census, sprintf("      %-18s %d removable line(s)%s", a,
                                length(removable),
                                if (length(removable))
                                    paste0("\n", paste(sprintf("        - %s", trimws(removable)),
                                                       collapse = "\n"))
                                else ""))
    bad <- removable[grepl(STAT_ROW, removable)]
    check_true(V,
        sprintf("%s: no line the toggle removes is a labelled statistic row (%d removable, %d of them rows%s)",
                a, length(removable), length(bad),
                if (length(bad)) paste0(": ", paste(trimws(head(bad, 3)), collapse = " | ")) else ""),
        length(bad) == 0)
}

# THE CENSUS, PRINTED. A reader sees the size of the population each
# assertion above ran over, per analysis, rather than a bare PASS.
cat("      v132: removable-line census (lines present with explanations on,\n")
cat("            absent with them off, per analysis):\n")
cat(paste(census, collapse = "\n"), "\n", sep = "")

# THE FLOOR IS DERIVED, NOT A LITERAL: one removable line per analysis is the
# weakest statement a rig that had stopped subtracting could not satisfy, and
# it rises by itself when an analysis joins ANALYSES.
check_true(V,
    sprintf("the subtraction found at least one removable line per analysis (%d over %d)",
            n_removable_total, length(ANALYSES)),
    n_removable_total >= length(ANALYSES))
check_true(V,
    sprintf("and the corpus of labelled statistic rows compared is a real one (%d rows)",
            n_rows_total),
    n_rows_total >= 10 * length(ANALYSES) / 2)

# ===========================================================================
# 2. THE NAMED LINES, ON THE SIDES THE LANGUAGE BATCH PUTS THEM
# ===========================================================================
# Item 12: the caption splits, one half each side of the toggle. Both legs of
# the two analyses that reach it (post-hoc off, so the effect matrix is the
# only pairwise thing on the page).
for (a in c("anova_only", "kw_only")) {
    off <- raw_lines(file.path(RS_OUT, paste0(a, "_off.txt")))
    on  <- raw_lines(file.path(RS_OUT, paste0(a, "_on.txt")))
    check_true(V, sprintf("%s: item 12's DISCLOSURE prints with explanations OFF", a),
               any(grepl(DISCLOSURE_12, off, fixed = TRUE)))
    check_true(V, sprintf("%s: item 12's DISCLOSURE prints with explanations ON too", a),
               any(grepl(DISCLOSURE_12, on, fixed = TRUE)))
    check_true(V, sprintf("%s: item 12's EXPLANATION is absent with explanations OFF", a),
               !any(grepl(EXPLANATION_12, off, fixed = TRUE)))
    check_true(V, sprintf("%s: item 12's EXPLANATION prints with explanations ON", a),
               any(grepl(EXPLANATION_12, on, fixed = TRUE)))
}

# Item 11: the caution line. EXPLANATION-routed, so it must vanish with the
# toggle off -- and the omnibus p it talks about must not vanish with it.
for (a in c("caution_anova", "caution_kw")) {
    off <- raw_lines(file.path(RS_OUT, paste0(a, "_off.txt")))
    on  <- raw_lines(file.path(RS_OUT, paste0(a, "_on.txt")))
    check_true(V, sprintf("%s: item 11's caution prints with explanations ON, verbatim", a),
               any(grepl(CAUTION_11_A, on, fixed = TRUE)) &&
               any(grepl(CAUTION_11_B, on, fixed = TRUE)))
    check_true(V, sprintf("%s: item 11's caution is absent with explanations OFF", a),
               !any(grepl(CAUTION_11_B, off, fixed = TRUE)))
    # THE FACT THE CAUTION TALKS ABOUT. The omnibus did not reach alpha; that
    # p is a labelled row and must be on the page whether or not the sentence
    # explaining it is.
    p_off <- grep("^  p +[.0-9<]", off, value = TRUE)
    check_true(V,
        sprintf("%s: the omnibus p the caution is about is on the page with explanations OFF (%s)",
                a, paste(trimws(head(p_off, 1)), collapse = "")),
        length(p_off) >= 1)
}

# The caution is a FUNCTION OF THE RESULT, not of the toggle: a significant
# omnibus must not print it even with explanations on. Without this, a
# caution wired to print unconditionally would satisfy every check above.
sig_on <- raw_lines(file.path(RS_OUT, "anova_tukey_on.txt"))
check_true(V,
    "a SIGNIFICANT omnibus prints no caution even with explanations on",
    !any(grepl(CAUTION_11_B, sig_on, fixed = TRUE)))

# ===========================================================================
# 3. THE SOURCE SHAPE OF THE SPLIT ITSELF
# ===========================================================================
f_analysis <- file.path(RS_SRC, "stats", "eml-analysis.praat")
src_a <- raw_lines(f_analysis)
check_true(V, "stats/eml-analysis.praat is present", length(src_a) > 0)

cap0 <- grep("^procedure emlEffectMatrixCaption\\s*$", src_a)
cap1 <- if (length(cap0)) grep("^endproc", src_a)[grep("^endproc", src_a) > cap0[1]][1] else NA
cap <- if (length(cap0) && !is.na(cap1)) src_a[cap0[1]:cap1] else character(0)
check_true(V, "@emlEffectMatrixCaption's body is closed and non-empty", length(cap) > 0)

i_disc <- grep(DISCLOSURE_12, cap, fixed = TRUE)
i_gate <- grep("^\\s*if emlShowExplanations\\s*$", cap)
check_true(V,
    "@emlEffectMatrixCaption's DISCLOSURE sentence stands OUTSIDE the explanations gate",
    length(i_disc) == 1 && length(i_gate) == 1 && i_disc < i_gate)
# The EXPLANATION sentence is written across a Praat line continuation, so it
# is matched on its leading fragment rather than as a whole -- the whole
# sentence is asserted on the DRIVEN output above, which is where it matters.
check_true(V,
    "and its EXPLANATION sentence stands inside it",
    {
        i_expl <- grep("Effect sizes estimate the size of each pairwise",
                       cap, fixed = TRUE)
        length(i_expl) == 1 && length(i_gate) == 1 && i_expl > i_gate
    })

# ===========================================================================
# 4. RISK R1 -- THE SETTINGS-PERMUTATION DRIVE
# ===========================================================================
# RISK_REGISTER_2026-08-25.md, R1: the whole-house pass "includes a
# settings-permutation drive -- same data, every display setting toggled
# between draws -- asserting zero reprints."
#
# THE REPRINT ITSELF CANNOT BE ASSERTED, and saying so is part of the
# inspection rather than a gap in it: no result store exists in this plugin.
# `reprint`, "Data changed since this analysis was last run" and any stored
# report text appear nowhere in plugin_EML_StatsGraphs; docs/OPEN_ITEMS.md
# records the same. Zero reprints out of zero reprint machinery is not
# evidence of anything.
#
# WHAT IS ASSERTED INSTEAD is the property that decision will rest on. Punch
# item 1.2's canonical form is the report "rendered with explanation-routed
# lines suppressed", which in this plugin is the report rendered with
# emlShowExplanations = 0. So across a permutation of the display setting and
# the two identity settings (item 1.4: alpha and group sort), on one fixture
# through one orchestrator: the canonical rendering must not move when only
# the DISPLAY setting moves. It cannot, in one direction, by construction --
# it IS the explanations-off leg -- so what is checked is the substantive
# half: that the explanations-off leg is the SAME report under both toggle
# settings' identity conditions, and that every labelled statistic row is
# identical across the display toggle within each identity cell.
PERM_CELLS <- as.vector(outer(
    outer(c("expl0", "expl1"), c("sort0", "sort1"), paste, sep = "_"),
    c("alpha05", "alpha01"), paste, sep = "_"))

perm_path <- function(cell) file.path(RS_OUT, paste0("perm_", cell, ".txt"))
have_perm <- all(file.exists(vapply(PERM_CELLS, perm_path, character(1))))
check_true(V, sprintf("all %d permutation cells are on disk", length(PERM_CELLS)),
           have_perm)

if (have_perm) {
    for (cell in PERM_CELLS)
        check_true(V, sprintf("permutation cell %s ran to completion", cell),
                   any(grepl(paste0("^== END ", cell, " =="),
                             raw_lines(perm_path(cell)))))

    n_perm_rows <- 0L
    for (sort in c("sort0", "sort1")) {
        for (al in c("alpha05", "alpha01")) {
            off <- drop_noise(raw_lines(perm_path(paste("expl0", sort, al, sep = "_"))))
            on  <- drop_noise(raw_lines(perm_path(paste("expl1", sort, al, sep = "_"))))
            rows_off <- off[grepl(STAT_ROW, off)]
            rows_on  <- cut_suffix(on)[grepl(STAT_ROW, cut_suffix(on))]
            n_perm_rows <- n_perm_rows + length(rows_off)
            check_true(V,
                sprintf("R1 %s/%s: every labelled statistic row is identical across the display toggle (%d rows)",
                        sort, al, length(rows_off)),
                length(rows_off) > 0 && identical(rows_off, rows_on))
        }
    }
    check_true(V,
        sprintf("R1: the permutation compared a real corpus of rows (%d)", n_perm_rows),
        n_perm_rows >= 4 * 5)

    # THE IDENTITY SETTINGS DO MOVE TEXT, which is why item 1.4 compares them
    # as identity rather than as text. Asserted so that a future change which
    # accidentally made group order invisible in the report would be caught
    # here rather than read as an improvement.
    a <- drop_noise(raw_lines(perm_path("expl0_sort0_alpha05")))
    b <- drop_noise(raw_lines(perm_path("expl0_sort1_alpha05")))
    check_true(V,
        "R1: group sort DOES move the canonical text (identity, not display -- item 1.4)",
        !identical(a, b))

    # WHAT THE DRIVE MEASURED, recorded rather than asserted: the canonical
    # rendering cannot be produced by post-processing the explanations-ON
    # text, because half the explanations are whole lines carrying no marker
    # that separates them from a disclosure line. This is the design
    # constraint the store's canonical comparison inherits.
    on_cut_all <- cut_suffix(drop_noise(raw_lines(perm_path("expl1_sort0_alpha05"))))
    residual <- setdiff(on_cut_all, drop_noise(raw_lines(perm_path("expl0_sort0_alpha05"))))
    attest(V, "cutting the two-tab suffixes does not canonicalise a report",
        sprintf(paste("On expl1_sort0_alpha05, cutting every two-tab explanation",
                      "suffix still leaves %d line(s) the explanations-off",
                      "rendering does not have: %s. They carry no marker",
                      "distinguishing them from a disclosure line, so punch item",
                      "1.2's canonical form has to be produced by RENDERING with",
                      "emlShowExplanations = 0, not by filtering the rendered",
                      "text. Recorded here because the store's canonical",
                      "comparison is not built yet and this is the constraint it",
                      "inherits."),
                length(residual),
                paste(sprintf("\"%s\"", trimws(residual)), collapse = "; ")))

    attest(V, "R1's zero-reprint assertion has no machinery to run against",
        paste("No result store exists in plugin_EML_StatsGraphs: no stored",
              "report text, no canonical rendering, and neither `reprint` nor",
              "\"Data changed since this analysis was last run\" occurs in any",
              "shipped .praat file. The permutation above measures the property",
              "the reprint decision will rest on; the reprint count itself",
              "cannot be measured until punch item 1.2's canonical comparison",
              "and 1.6's write site land."))
}

if (!exists("EML_SUITE")) {
    eml_report("v132 -- the DISCLOSURE / EXPLANATION split, over whole reports")
    eml_exit()
}
