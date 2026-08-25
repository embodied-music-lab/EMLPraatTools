# ============================================================================
# v131 -- the explanations toggle reaches the reporters 6.2 wires up
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# THE DEFECT THIS CLOSES (punch list 2026-08-25, lane 6.2). v130 proved the
# explanations toggle works end to end for @emlRunKWAnalysis, because that
# orchestrator's shared reporter already routed its glosses through
# @emlEffectMatrixCaption. It did not prove anything about the reporters
# that had NO such routing before this round: @emlReportPairwiseComparison's
# four test arms (Welch, Student, Scheffe, Wilcoxon), the repeated-measures
# ANOVA and Friedman orchestrators, and @emlReportDescriptiveAnalysis. Before
# this round's edit, emlShowExplanations was never read at any of those
# seven sites -- the wizard's flag was a no-op for its own reports there,
# same as the punch list states of the whole file.
#
# THE FIXTURE, TWO TABLES, TWO RIGS.
#   harness/explainwiring/doors.praat drives seven measures (four pairwise
#   arms, RM-ANOVA, Friedman, descriptive) x three legs each (wizard,
#   menu_off, menu_on) -- twenty-one captures, via run.sh. wizard reproduces
#   the wizard's own single assignment (emlShowExplanations = 1, no
#   dialog); menu_off/menu_on go through the real @emlHandleCommonFields,
#   the same layer v130's menu legs use.
#
# WHAT IS CHECKED, PER MEASURE:
#   * menu_on carries at least one line neither the wizard-off state nor
#     menu_off carries (an explanation) -- read generically, not by
#     hardcoding each measure's exact sentence, so this check does not
#     silently stop matching if a sentence's wording is later revised as
#     long as SOME explanation still routes through emlShowExplanations.
#   * menu_off carries NONE of the sentences this file DOES know verbatim
#     (the ones authored in this round, reused from existing helper text).
#   * every numeric/statistic line is byte-identical between wizard,
#     menu_off and menu_on once the known explanation lines are stripped --
#     the toggle must change explanatory text and nothing else.
#
# THE SOURCE SHAPE (section 2) confirms each of the seven sites actually
# reads emlShowExplanations, by anchor, in stats/eml-analysis.praat and
# stats/eml-output.praat -- so a future edit that deletes the guard (rather
# than the sentence) is still caught even if the sentence text moves.
#
# THE RED DEMONSTRATION is harness/explainwiring/break.sh: a scratch copy of
# the plugin with stats/eml-analysis.praat and stats/eml-output.praat
# reverted to HEAD (i.e. before this round's wiring), re-driven through this
# file's own rig. Every "explanation present on menu_on, absent on menu_off"
# check below goes red on that copy, because menu_on and menu_off come back
# byte-identical -- see break.sh's own summary.
#
# Base R only. Reads harness/explainwiring's committed output and the
# plugin source; drives nothing itself.
# ============================================================================

if (!exists("check_true")) source(file.path(
    Sys.getenv("EML_VALIDATE_DIR", unset = "validate"), "helpers.R"))

V <- "v131"

EW_OUT <- Sys.getenv("EML_EW_OUT", unset = repo_path("harness", "explainwiring", "out"))
EW_SRC <- Sys.getenv("EML_EW_SRC", unset = repo_path("plugin_EML_StatsGraphs"))

MEASURES <- c("pairwise_welch", "pairwise_student", "pairwise_scheffe",
              "pairwise_wilcoxon", "rmanova", "friedman", "descriptive")

# The explanation sentences this round actually added, reused verbatim from
# existing helper text (see the source comments at each site). Read here
# only to (a) confirm they are the thing making menu_on differ, not some
# unrelated noise, and (b) assert menu_off never carries them -- the
# generic "some line differs" check above already carries the main defence
# against a future wording change silently defeating this file.
KNOWN_EXPLANATIONS <- c(
    "Compares means of two independent groups (robust to unequal variances).",
    "Compares means of two independent groups (assumes equal variances).",
    "Compares distributions of two independent groups without assuming normality.",
    "Statistically significant",
    "Not statistically significant",
    "Approximately symmetric", "Slight right skew", "Slight left skew",
    "Substantial right skew", "Substantial left skew",
    "Near-normal peakedness", "Heavy-tailed", "Light-tailed"
)

raw_lines <- function(path) {
    if (!file.exists(path)) return(character(0))
    readLines(path, warn = FALSE)
}
strip_known <- function(lines) {
    hit <- rep(FALSE, length(lines))
    for (pat in KNOWN_EXPLANATIONS) hit <- hit | grepl(pat, lines, fixed = TRUE)
    # Two shapes carry a known explanation: a whole line that IS the
    # explanation (the "  Why: ..." blocks), dropped entirely; and a stat
    # row @emlReportLine appended one to after a second tab (Skewness,
    # Kurtosis) -- there the row itself must survive, with only the
    # explanation suffix cut, or a stat row would look ABSENT on the legs
    # that have an explanation and PRESENT on the ones that don't, which is
    # backwards from what this check is trying to say.
    out <- ifelse(hit & grepl("\t", lines, fixed = TRUE),
                   sub("\t\t.*$", "", lines),
                   lines)
    out[!(hit & !grepl("\t", lines, fixed = TRUE))]
}
# The leg banner and the report's own "date printed" line are not part of
# what the toggle controls, and they legitimately differ (leg name) or
# drift (wall clock) run to run.
strip_noise <- function(lines) {
    lines <- lines[!grepl("^== (LEG|END)", lines)]
    lines <- lines[!grepl("^\\s*[A-Za-z]{3} [A-Za-z]{3} +[0-9]+ [0-9:]+ [0-9]{4}\\s*$", lines)]
    # @emlReportContext's "from: ..." line records whether the run came
    # through a menu wrapper's @emlHandleCommonFields or not -- true of
    # every menu leg regardless of the explanations toggle, and absent on
    # the wizard leg because this rig's "wizard" state never calls
    # @emlHandleCommonFields at all (the real wizard sets its own context
    # elsewhere). Pre-existing, unrelated to 6.2, and identical between
    # menu_off and menu_on -- so it is noise for THIS file's purpose, not a
    # difference the explanations toggle produced.
    lines <- lines[!grepl("^\\s*from: ", lines)]
    lines
}

paths <- function(measure) {
    setNames(
        file.path(EW_OUT, paste0(measure, c("_wizard.txt", "_menu_off.txt", "_menu_on.txt"))),
        c("wizard", "menu_off", "menu_on"))
}

have_any <- any(file.exists(unlist(lapply(MEASURES, function(m) paths(m)))))
check_true(V, "at least one harness/explainwiring capture is present", have_any)

if (!have_any) {
    if (!exists("EML_SUITE")) {
        eml_report("v131 -- explanation wiring reaches the reporters 6.2 added")
        eml_exit()
    }
} else {

for (measure in MEASURES) {
    p <- paths(measure)
    have_all <- all(file.exists(p))
    check_true(V, sprintf("%s: all three legs (wizard, menu_off, menu_on) are present", measure),
               have_all)
    if (!have_all) next

    lines <- lapply(p, raw_lines)

    # ANTI-VACUITY: a leg that failed silently and produced only the banner
    # would make every "identical once stripped" check trivially true.
    for (nm in names(lines)) {
        check_true(V, sprintf("%s (%s): the capture has report body, not just the banner", measure, nm),
                   length(lines[[nm]]) > 2)
    }

    known_present <- vapply(lines, function(x) any(vapply(KNOWN_EXPLANATIONS, function(pat)
        any(grepl(pat, x, fixed = TRUE)), logical(1))), logical(1))

    check_true(V, sprintf("%s: menu_off carries none of the known explanation sentences", measure),
               isTRUE(!known_present[["menu_off"]]))
    check_true(V, sprintf("%s: menu_on carries at least one explanation sentence", measure),
               isTRUE(known_present[["menu_on"]]))
    check_true(V, sprintf("%s: wizard carries at least one explanation sentence", measure),
               isTRUE(known_present[["wizard"]]))

    # The generic defence: SOME line differs between menu_off and menu_on,
    # full stop -- not contingent on this file's own KNOWN_EXPLANATIONS list
    # naming the right sentence.
    check_true(V, sprintf("%s: menu_on and menu_off are not byte-identical", measure),
               !identical(strip_noise(lines$menu_off), strip_noise(lines$menu_on)))

    # And once the known explanation lines and banner/timestamp noise are
    # stripped from all three, they agree -- the toggle changed explanatory
    # text and nothing else.
    stripped <- lapply(lines, function(x) strip_known(strip_noise(x)))
    check_true(V, sprintf("%s: wizard, menu_off and menu_on report identical statistics once explanations are stripped", measure),
               identical(stripped$wizard, stripped$menu_off) &&
               identical(stripped$menu_off, stripped$menu_on))
}

} # have_any

# ===========================================================================
# 2. THE SOURCE SHAPE -- each of the seven sites reads emlShowExplanations,
#    by anchor, so a future edit that deletes the guard (leaving the
#    sentence itself untouched) still goes red here even if the wording
#    of the sentence moves.
# ===========================================================================
f_analysis <- file.path(EW_SRC, "stats", "eml-analysis.praat")
f_output   <- file.path(EW_SRC, "stats", "eml-output.praat")
check_true(V, "eml-analysis.praat and eml-output.praat are present",
           all(file.exists(c(f_analysis, f_output))))

src_a <- raw_lines(f_analysis)
src_o <- raw_lines(f_output)

# One anchor per site: a comment or line unique to the block this round
# added, immediately followed (within a few lines) by a read of
# emlShowExplanations.
anchor_gated <- function(src, anchor_pattern, window = 12) {
    hit <- grep(anchor_pattern, src)
    if (!length(hit)) return(FALSE)
    for (h in hit) {
        seg <- src[h:min(h + window, length(src))]
        if (any(grepl("emlShowExplanations", seg, fixed = TRUE))) return(TRUE)
    }
    FALSE
}

check_true(V, "pairwise Welch/Student block reads emlShowExplanations (punch list 6.2 anchor)",
    anchor_gated(src_a, "Welch/Student branch \\(punch list 6\\.2\\)"))
check_true(V, "pairwise Wilcoxon block reads emlShowExplanations (punch list 6.2 anchor)",
    anchor_gated(src_a, "Mann-Whitney branch \\(punch list 6\\.2\\)"))
check_true(V, "pairwise Scheffe block reads emlShowExplanations (punch list 6.2 anchor)",
    anchor_gated(src_a, "Student branch \\(punch list 6\\.2\\) -- Scheffe"))
check_true(V, "repeated-measures ANOVA's F/p line reads emlShowExplanations (punch list 6.2 anchor)",
    anchor_gated(src_a, "EXPLANATION \\(punch list 6\\.2\\), reusing @emlWizardExplainP"))
check_true(V, "Friedman's chi-square/p line reads emlShowExplanations (punch list 6.2 anchor)",
    anchor_gated(src_a, "EXPLANATION \\(punch list 6\\.2\\), @emlWizardExplainP reused"))
check_true(V, "descriptive statistics' skewness/kurtosis rows read emlShowExplanations (punch list 6.2 anchor)",
    anchor_gated(src_o, "EXPLANATION \\(punch list 6\\.2\\): @emlWizardExplainSkewness"))

if (!exists("EML_SUITE")) {
    eml_report("v131 -- explanation wiring reaches the reporters 6.2 added")
    eml_exit()
}
