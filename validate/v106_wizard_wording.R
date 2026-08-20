# ============================================================================
# v106 — the wizard's two design questions say CONDITIONS and WITHIN-SUBJECT
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Two strings in scripts/eml-wizard.praat decide which test a user runs, and
# both of them used to name the design after something the design is not.
# Ruled 20 August 2026 (docs/ADDENDUM_WORDING_AND_ROADMAP.md, item 1):
#
#   A1, observation type   "Yes — same people, repeated (paired)"
#                       -> "Yes — same people, measured more than once
#                          (within-subject)"
#   A3, the k gate         "How many repeated measurements per subject?"
#                       -> "Under how many conditions was each subject
#                          measured?"
#
# WHY EACH ONE IS A DEFECT AND NOT A PREFERENCE.
#
# A1 IS A FORK, AND "PAIRED" NAMES ONLY ONE SIDE OF IT. "Paired" is the proper
# name of exactly one test, the paired t-test, and that test exists only at
# k = 2. But the option carrying that word is the one that leads to BOTH the
# k = 2 branch and the three-or-more branch (RM-ANOVA / Friedman). A user with
# four conditions reads "paired", correctly concludes that their data are not
# paired, and takes the only other option on the page — different groups,
# independent. Nothing refuses them: a between-subjects test runs on
# within-subject data, prints an F and a p, and is wrong in the direction
# nobody audits, because the subject-to-subject variance it leaves in the
# error term is exactly the variance the repeated design was built to remove.
# That is a plausible number in a thesis, not an error dialog.
#
# A3 COUNTS CONDITIONS, AND "MEASUREMENTS" COUNTS COLUMNS. The k things on
# that page are levels of the within-subject factor — SPSS's term, and what
# the plugin's wide format already encodes: one measurement taken under k
# circumstances. "How many repeated measurements per subject" reads just as
# naturally as "how many different quantities did you measure", which is a
# plotting question, and a user who reads it that way answers "three or more"
# for F0, SPL and jitter and is handed an RM-ANOVA computed across Hz,
# decibels and percent as though they were one measurement. The author of the
# plugin read it that way, which is the whole argument for changing it.
#
# WHAT THIS FILE ASSERTS, AND THE ONE THING IT DELIBERATELY DOES NOT.
#
# The ruling sets a standing rule for pins on dialog text: assert THE VALUE
# LINES — the option labels, which are what the user's answer actually is —
# and assert THAT A GLOSS IS PRESENT, never the gloss's wording. A pin on
# explanatory prose makes every later clarification a red run, and a suite
# that goes red for improvements gets its assertions deleted rather than its
# prose improved. So section 3 counts the A3 page's explanatory comments and
# says nothing whatever about what they say.
#
# The two question strings themselves are pinned by their exact text, because
# they are not gloss: they are the question the answer answers, and the ruling
# names them verbatim.
#
# WHY NOTHING ELSE IN THE TREE WOULD HAVE CAUGHT THIS. No validator reads the
# wizard's dialog PROSE. v98 and v99 read the wizard's field lines, but a
# field's derived variable name comes from the field LABEL ("Observation
# type", "Conditions"), which neither change touches, and an `option:` line
# does not derive a name at all — so both files are green on either wording,
# by construction. The GUI walks address pages by title and press by button
# position, and the titles are unchanged. Demonstrated red against
# git show HEAD:plugin_EML_StatsGraphs/scripts/eml-wizard.praat.
#
# Base R only. No packages.
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

V <- "v106"

# EML_WIZARD_SRC lets the red demonstration point this file at a copy of the
# pre-fix wizard (git show HEAD:... > /tmp/...) without editing anything here.
# Unset, it reads the shipped script through the plugin/ symlink, which is the
# path the rest of the suite uses.
src <- Sys.getenv("EML_WIZARD_SRC", unset = "")
if (!nzchar(src)) src <- repo_path("plugin", "scripts", "eml-wizard.praat")
if (!file.exists(src)) stop("wizard not found: ", src)
wiz <- readLines(src, warn = FALSE)

# Every literal below is ASCII on purpose: the wizard is UTF-8 and carries em
# dashes on these very lines, and a pattern that included one would be
# comparing this file's encoding against that file's rather than comparing the
# strings. Matching on the ASCII remainder is the same assertion without the
# encoding question. useBytes keeps it that way under any locale.
has <- function(pat) any(grepl(pat, wiz, fixed = TRUE, useBytes = TRUE))
count <- function(pat) sum(grepl(pat, wiz, fixed = TRUE, useBytes = TRUE))

# ---------------------------------------------------------------------------
# 1. THE NEW WORDING IS THERE
# ---------------------------------------------------------------------------
check_true(V, "A1 offers the within-subject option, once",
           count('option: "Yes ') == 1L &&
           count('same people, measured more than once (within-subject)"') == 1L)
check_true(V, "A3 asks under how many CONDITIONS each subject was measured, once",
           count('comment: "Under how many conditions was each subject measured?"') == 1L)

# ---------------------------------------------------------------------------
# 2. THE OLD WORDING IS GONE — anywhere in the file, not just on those pages
# ---------------------------------------------------------------------------
# A `comment:` or `option:` prefix is not required here. If either sentence
# reappears in a heredoc, a help page or a second copy of the branch, this
# file has to see it: the defect was the words reaching the user, not the line
# they were written on.
check_true(V, "the old \"repeated (paired)\" option label is gone",
           !has("same people, repeated (paired)"))
check_true(V, "the old \"repeated measurements per subject\" question is gone",
           !has("How many repeated measurements per subject?"))

# ---------------------------------------------------------------------------
# 3. THE VALUE LINES ARE UNTOUCHED, AND A GLOSS IS PRESENT
# ---------------------------------------------------------------------------
# The ruling changed the QUESTIONS and left the answers alone. The A1 and A3
# option labels are what the user's choice is; the wizard reads them
# positionally (obsType = observation_type, then `if conditions = 2`), so an
# option inserted, dropped or reordered silently re-routes the branch. They
# are pinned in order, by exact text.
#
# "Paired" stays on the k = 2 option, and that is the point of the ruling
# rather than an exception to it: there the word is the name of the test being
# offered, not a claim about the design.
a1 <- grep('optionmenu: "Observation type"', wiz)
a3 <- grep('optionmenu: "Conditions"', wiz)
check_true(V, "A1 and A3 each open exactly one option menu",
           length(a1) == 1L && length(a3) == 1L)

opts_after <- function(i, n) {
    lines <- wiz[(i + 1L):(i + n)]
    m <- regmatches(lines, regexec('^\\s*option:\\s*"(.*)"\\s*$', lines))
    vapply(m, function(x) if (length(x) == 2L) x[2] else NA_character_, "")
}
check_true(V, "A1's two value lines, in order: independent then within-subject",
           identical(opts_after(a1, 2L),
                     c("No — different groups (independent)",
                       "Yes — same people, measured more than once (within-subject)")))
check_true(V, "A3's two value lines are unchanged, and keep \"paired\" at k = 2",
           identical(opts_after(a3, 2L),
                     c("Two (paired t-test / Wilcoxon)",
                       "Three or more (RM-ANOVA / Friedman)")))

# GLOSS PRESENCE ONLY. The A3 page explains the wide format under its option
# menu. That explanation must exist — without it the page asks for a number
# and never says what shape the table has to be in — but its WORDING is not
# this file's business, per the ruling. So: at least one comment line with
# something on it, between the option menu and the endPause, and no assertion
# about what it says.
gate_end <- a3 + which(grepl("^\\s*clicked = endPause", wiz[(a3 + 1L):length(wiz)]))[1]
gloss <- wiz[(a3 + 3L):(gate_end - 1L)]
gloss <- gloss[grepl('^\\s*comment:\\s*"[^"]', gloss)]
check_true(V, "the A3 page still carries a gloss under its options (presence, not wording)",
           length(gloss) >= 1L)

if (!exists("EML_SUITE")) {
    eml_report("v106 wizard wording: conditions, and within-subject rather than paired")
    eml_exit()
}
