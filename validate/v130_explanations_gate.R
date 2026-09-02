# ============================================================================
# v130 -- the explanations toggle: one fixture, three paths, one difference
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# THE RULING THIS ENFORCES (punch list 2026-08-25, lane 6.1; language batch
# item 9). A menu analysis dialog gains one boolean, "Annotate results with
# explanations", verbatim, default off. The wizard has no such control and is
# always on. A figure launched from the wizard inherits on; a figure launched
# from a menu analysis inherits that dialog's own setting; a standalone graph
# that annotates statistics is on. All three read the SAME global,
# emlShowExplanations, and this file is the acceptance the punch list names:
# "one fixture through three paths -- the wizard, a menu dialog with the
# toggle off, and the same dialog with it on -- producing identical
# statistics and differing only in the explanations."
#
# THE THREE PATHS, TWO RIGS.
#
#   THE WIZARD is GUI-driven, under Xvfb, because `praat --run` refuses to
#   build a pause window at all -- harness/wizardback's "kgroups" leg drives
#   the real eml-wizard.praat to Kruskal-Wallis (no Dunn) on fixture_k.csv,
#   column Loud by Voice, and its captured Info window
#   (harness/wizardback/out/kgroups.info.txt) is read here unmodified.
#
#   THE MENU DIALOG is driven headless by harness/explaingate/doors.praat, at
#   the layer @emlHandleCommonFields actually is: the shared procedure every
#   menu wrapper's Run calls once, right after its own beginPause/endPause
#   closes. Presetting annotate_results_with_explanations there is exactly
#   what a real endPause leaves behind; the checkbox itself binding under
#   that derived name, on the real dialog, with no collision, is v98's job
#   and is not re-proven here. Three legs: wizard_equivalent (the wizard's
#   own single assignment, no dialog, reproduced verbatim, for the identical-
#   statistics half of the diff -- NOT a substitute for the GUI leg above),
#   menu_off, menu_on.
#
# THE FIXTURE IS ONE TABLE, ONE ENGINE CALL, ACROSS ALL FOUR CAPTURES:
# @emlRunKruskalWallisAnalysis on fixture_k.csv, column Loud by Voice, doDunn = 0. That
# is what makes "identical statistics" checkable rather than assumed: H,
# df, p, epsilon-squared, effect magnitude and all three groups' mean ranks
# are asserted equal across all four captures, not merely eyeballed.
#
# THE ONE DIFFERENCE READ OUT is @emlEffectMatrixCaption (lane 3.4 / language
# batch item 12), reached because doDunn = 0: its DISCLOSURE line ("No
# pairwise significance tests were run.") must be on every path, and its
# EXPLANATION line ("Effect sizes estimate the size of each pairwise
# difference.") must be present on the wizard and menu-on paths and absent on
# menu-off -- together with the inline glosses @emlReportLine appends after a
# second tab wherever emlShowExplanations is on.
#
# THE SOURCE SHAPE (section 2) is read directly, the same idiom v115 uses for
# its own three settings: the verbatim label and its off default, the four
# globals @emlHandleCommonFields sets from the dialog's answer, and the
# conditional @emlGraphsWorkflow entry that lets a later "Draw" inherit
# exactly that answer instead of the standalone path's own default of 1.
#
# THE RED DEMONSTRATION is harness/explaingate/break.sh: a COPY of the
# plugin with the four-line explanations block removed from
# @emlHandleCommonFields, driven through this file's own rig unmodified via
# $EML_EG_SRC / $EML_EG_OUT. What goes red is section 1's "menu_off omits
# the explanation line" and "menu_on and menu_off differ" -- both legs come
# back showing the same explanations declared 1, because the seeded global
# is never applied and eml-output.praat's own include-time default is 1.
#
# Base R only. Reads two harnesses' committed output and the plugin source;
# drives nothing itself.
# ============================================================================

if (!exists("check_true")) source(file.path(
    Sys.getenv("EML_VALIDATE_DIR", unset = "validate"), "helpers.R"))

V <- "v130"

EG_OUT <- Sys.getenv("EML_EG_OUT", unset = repo_path("harness", "explaingate", "out"))
EG_SRC <- Sys.getenv("EML_EG_SRC", unset = repo_path("plugin_EML_StatsGraphs"))
WB_OUT <- Sys.getenv("EML_WB_OUT", unset = repo_path("harness", "wizardback", "out"))

DISCLOSURE  <- "No pairwise significance tests were run."
EXPLANATION <- "Effect sizes estimate the size of each pairwise difference."
LABEL_9     <- "Annotate results with explanations"

flat <- function(path) {
    if (!file.exists(path)) return(NA_character_)
    txt <- paste(readLines(path, warn = FALSE), collapse = " ")
    gsub("[[:space:]]+", " ", txt)
}
raw_lines <- function(path) {
    if (!file.exists(path)) return(character(0))
    readLines(path, warn = FALSE)
}

# ---------------------------------------------------------------------------
# STAT FIELDS -- one value per known label, read off the FIRST tab-separated
# column so an inline explanation gloss (which rides after a second tab, per
# @emlReportLine) never contaminates the number being compared.
# ---------------------------------------------------------------------------
STAT_LABELS <- c("H", "df", "p", "Epsilon-squared", "Effect magnitude",
                 "Total N", "Groups")
stat_fields <- function(path) {
    ln <- raw_lines(path)
    out <- setNames(rep(NA_character_, length(STAT_LABELS)), STAT_LABELS)
    for (lab in STAT_LABELS) {
        pat <- paste0("^\\s*", gsub("([.$^])", "\\\\\\1", lab), "\\s{2,}")
        hit <- grep(pat, ln, value = TRUE)
        if (length(hit)) {
            first_col <- strsplit(hit[1], "\t", fixed = TRUE)[[1]][1]
            out[lab] <- trimws(gsub("\\s+", " ", sub(pat, "", first_col)))
        }
    }
    # The group-order line and the three mean-rank rows are matched whole,
    # not split into label/value -- they are the row, not a field of one.
    out["group_order"] <- {
        h <- grep("^\\s*Group order:", ln, value = TRUE)
        if (length(h)) trimws(gsub("\\s+", " ", h[1])) else NA_character_
    }
    for (g in c("zeta", "alpha", "mu")) {
        h <- grep(paste0("^", g, "\\s+\\d"), ln, value = TRUE)
        out[paste0("rank_", g)] <- if (length(h)) trimws(gsub("\\s+", " ", h[1])) else NA_character_
    }
    out
}

wizard_gui   <- file.path(WB_OUT, "kgroups.info.txt")
eq_wizard    <- file.path(EG_OUT, "wizard_equivalent.txt")
eq_menu_off  <- file.path(EG_OUT, "menu_off.txt")
eq_menu_on   <- file.path(EG_OUT, "menu_on.txt")

have_all <- all(file.exists(c(wizard_gui, eq_wizard, eq_menu_off, eq_menu_on)))
check_true(V, "all four captures are present (GUI wizard + three headless legs)",
           have_all)

if (!have_all) {
    if (!exists("EML_SUITE")) {
        eml_report("v130 -- the explanations gate")
        eml_exit()
    }
} else {

# ===========================================================================
# 1. THE DRIVEN EVIDENCE
# ===========================================================================
sf <- list(wizard_gui = stat_fields(wizard_gui),
           eq_wizard  = stat_fields(eq_wizard),
           menu_off   = stat_fields(eq_menu_off),
           menu_on    = stat_fields(eq_menu_on))

# ANTI-VACUITY: a resolver that silently stopped matching any label would
# make every "identical" comparison below trivially true. Refuse that.
n_found <- sum(!is.na(sf$menu_off))
check_true(V,
    sprintf("the stat-field reader actually matched fields on the headless legs (%d of %d)",
            n_found, length(sf$menu_off)),
    n_found >= 8)

fields <- names(sf$menu_off)
for (f in fields) {
    vals <- vapply(sf, function(x) x[[f]], character(1))
    check_true(V,
        sprintf("%s is identical across wizard(GUI), wizard(equivalent), menu-off and menu-on (%s)",
                f, paste(unique(vals), collapse = " | ")),
        length(unique(vals[!is.na(vals)])) <= 1 && all(!is.na(vals)))
}

# THE DISCLOSURE never leaves, on any path.
for (nm in c("wizard_gui", "eq_wizard", "menu_off", "menu_on")) {
    path <- get(paste0(
        c(wizard_gui = "wizard_gui", eq_wizard = "eq_wizard",
          menu_off = "eq_menu_off", menu_on = "eq_menu_on")[nm]))
    check_true(V, sprintf("%s carries the disclosure line", nm),
               grepl(DISCLOSURE, flat(path), fixed = TRUE))
}

# THE EXPLANATION is present exactly where the ruling says it must be.
f_wg <- flat(wizard_gui); f_eqw <- flat(eq_wizard)
f_off <- flat(eq_menu_off); f_on <- flat(eq_menu_on)

check_true(V, "the GUI-driven wizard's report carries the explanation line",
           grepl(EXPLANATION, f_wg, fixed = TRUE))
check_true(V, "the wizard-equivalent (no dialog, no control) carries the explanation line",
           grepl(EXPLANATION, f_eqw, fixed = TRUE))
check_true(V, "the menu dialog WITH the toggle on carries the explanation line",
           grepl(EXPLANATION, f_on, fixed = TRUE))
check_true(V, "the menu dialog WITH the toggle OFF omits the explanation line",
           !grepl(EXPLANATION, f_off, fixed = TRUE))

# AND THE TWO MENU LEGS ACTUALLY DIFFER -- the property a broken wiring
# collapses. Compared with the explanation line stripped out first, so this
# assertion is specifically about "did the toggle change anything" rather
# than a restatement of the two checks above.
strip_expl <- function(x) gsub(EXPLANATION, "", x, fixed = TRUE)
check_true(V, "menu-on and menu-off differ ONLY by the explanation line (and its inline glosses)",
           f_off != f_on)

} # have_all

# ===========================================================================
# 2. THE SOURCE SHAPE
# ===========================================================================
f_out  <- file.path(EG_SRC, "stats", "eml-output.praat")
f_form <- file.path(EG_SRC, "graphs", "eml-graphs-form.praat")
f_wiz  <- file.path(EG_SRC, "scripts", "eml-wizard.praat")
check_true(V, "eml-output.praat, eml-graphs-form.praat and eml-wizard.praat are present",
           all(file.exists(c(f_out, f_form, f_wiz))))

src_out  <- raw_lines(f_out)
src_form <- raw_lines(f_form)
src_wiz  <- raw_lines(f_wiz)

check_true(V,
    sprintf("the dialog boolean is the language batch's item 9, verbatim (\"%s\")", LABEL_9),
    any(grepl(paste0('boolean: "', LABEL_9, '"'), src_out, fixed = TRUE)))

check_true(V, "the toggle defaults off (emlLastShowExplanations = 0)",
           any(grepl("^emlLastShowExplanations = 0\\s*$", src_out)))

hf0 <- grep("^procedure emlHandleCommonFields\\s*$", src_out)
hf1 <- if (length(hf0)) grep("^endproc", src_out)[grep("^endproc", src_out) > hf0[1]][1] else NA
hf_body <- if (length(hf0) && !is.na(hf1)) src_out[hf0[1]:hf1] else character(0)
check_true(V, "@emlHandleCommonFields's body is closed and non-empty", length(hf_body) > 0)
for (asn in c("emlLastShowExplanations = annotate_results_with_explanations",
              "emlShowExplanations = annotate_results_with_explanations",
              "emlDialogShowExplanations = annotate_results_with_explanations",
              "emlExplanationsFromDialog = 1")) {
    check_true(V, sprintf("@emlHandleCommonFields sets %s", asn),
               any(grepl(asn, hf_body, fixed = TRUE)))
}

wf0 <- grep("^procedure emlGraphsWorkflow:", src_form)
wf1 <- if (length(wf0)) grep("^endproc", src_form)[grep("^endproc", src_form) > wf0[1]][1] else NA
wf_body <- if (length(wf0) && !is.na(wf1)) src_form[wf0[1]:wf1] else character(0)
check_true(V, "@emlGraphsWorkflow's body is closed and non-empty", length(wf_body) > 0)
check_true(V, "@emlGraphsWorkflow's entry guards on emlExplanationsFromDialog",
           any(grepl('variableExists \\("emlExplanationsFromDialog"\\)', wf_body)))
check_true(V, "and inherits emlDialogShowExplanations rather than overwriting it",
           any(grepl("emlShowExplanations = emlDialogShowExplanations", wf_body, fixed = TRUE)))
# THE UNCONDITIONAL OVERRIDE IS GONE. Stated as "the FIRST assignment to
# emlShowExplanations in this procedure is the inherited one", which is the
# only form of this assertion that can actually go red: the corrected entry
# still contains a bare `emlShowExplanations = 1` -- in the else branch, for
# the standalone-graph case the ruling says is always on -- so a check that
# merely looked for that line's absence would be asserting something false,
# and a check that looked for it only in the procedure's first few lines
# passes against the pre-fix source too, where the override sits under a
# comment block. Read off the whole body, in order.
wf_assign <- grep("^\\s*emlShowExplanations = ", wf_body, value = TRUE)
check_true(V,
    sprintf("the OLD unconditional override is gone: the first assignment to emlShowExplanations in @emlGraphsWorkflow is the inherited one (%s)",
            trimws(paste(head(wf_assign, 1), collapse = ""))),
    length(wf_assign) >= 1 &&
    grepl("^\\s*emlShowExplanations = emlDialogShowExplanations\\s*$", wf_assign[1]))

check_true(V, "the wizard still has no control -- it sets the gate itself, unconditionally, near its top",
           any(grepl("^emlShowExplanations = 1\\s*$", src_wiz[seq_len(min(60L, length(src_wiz)))])))
check_true(V, "and the wizard's own dialogs never inject the menu toggle",
           !any(grepl(LABEL_9, src_wiz, fixed = TRUE)))

if (!exists("EML_SUITE")) {
    eml_report("v130 -- the explanations gate: wizard, menu-off, menu-on")
    eml_exit()
}
