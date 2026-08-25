# ============================================================================
# v30 — D117: the wizard reports the analysis the USER configured, after an
#       analysis error has sent them back to the form
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# The claim is about GUI state across an error return, so it cannot be checked
# headlessly end to end. What CAN be checked, and is what actually matters, is
# the consequence: the wizard's error dialog says "Nothing has been lost", the
# user presses Run on the page it returns them to WITHOUT touching a field,
# and the Info window must then name their own columns.
#
# Before D117 it did not. The page re-rendered from @wizardPrepareTable's
# column guess, so pressing Run ran a DIFFERENT model and printed a second,
# different Analysis Plan beside the user's own — two plans in one Info
# window, no warning, the second one presented exactly like the first.
#
# The four captures are the same two walks driven twice, once against the
# fixed wizard and once against the wizard as it stood at 19a8d6c, on the
# parallel GUI rig (harness/walks/d117/). In each walk the user selects
# columns the guess would not have chosen, presses Run, gets an analysis
# error, presses Back, and presses Run again untouched:
#
#   pressrun_regression_FIXED_info.txt    singer -> vibrato rate Hz
#   pressrun_regression_PREFIX_info.txt   ... guess is jitter pct -> SPL dB
#   pressrun_twofactor_FIXED_info.txt     singer, style x sex
#   pressrun_twofactor_PREFIX_info.txt    ... guess is SPL dB, sex x style
#
# The PREFIX pair is not decoration. Without it a passing FIXED capture proves
# only that the walk reached the page; the pair is what shows the walk was
# capable of catching the defect, because against the old code it did.
#
# Base R only. No packages.
#
# NOT wired into run_all.R — the captures are GUI-driven, and the suite is
# reproducible from committed inputs by design.

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

walk_capture <- function(name) {
    p <- repo_path("evidence", "walks", "d117", name)
    if (!file.exists(p)) stop("capture not found: ", p)
    readLines(p, warn = FALSE)
}

# ---------------------------------------------------------------------------
# plans — every "EML Stats Wizard - Analysis Plan" block in a capture, as a
# list of named character vectors (label -> value).
#
# Praat pads the label and separates it from the value with a run of spaces,
# so two-or-more spaces is the separator; a single space inside a label
# ("Data column") is part of the label.
# ---------------------------------------------------------------------------
plans <- function(cap) {
    starts <- grep("EML Stats Wizard .* Analysis Plan", cap)
    lapply(starts, function(s) {
        # a plan block runs to the "Running analysis..." banner that follows
        stop_at <- grep("Running analysis", cap)
        stop_at <- stop_at[stop_at > s]
        e <- if (length(stop_at)) stop_at[1] else length(cap)
        body <- cap[s:e]
        body <- body[grepl("^\\s+\\S.*:\\s{2,}\\S", body)]
        lab <- trimws(sub("^\\s*([^:]+):\\s{2,}.*$", "\\1", body))
        val <- trimws(sub("^\\s*[^:]+:\\s{2,}(.*)$", "\\1", body))
        stats::setNames(val, lab)
    })
}

# columns_of — the column fields of one plan, in the order the plan prints
# them. The regression plan labels them Column 1 / Column 2; the two-factor
# plan labels them Data column / Group column. Both are "what was analysed".
columns_of <- function(p) {
    keys <- c("Column 1", "Column 2", "Data column", "Group column")
    unname(p[intersect(keys, names(p))])
}

reg_fixed  <- walk_capture("pressrun_regression_FIXED_info.txt")
reg_prefix <- walk_capture("pressrun_regression_PREFIX_info.txt")
two_fixed  <- walk_capture("pressrun_twofactor_FIXED_info.txt")
two_prefix <- walk_capture("pressrun_twofactor_PREFIX_info.txt")

# What the user selected on the form, in each walk. These are the walk's own
# inputs (harness/walks/d117/walk.sh), not something read back out of the
# capture, so an assertion against them is a real assertion.
user_reg <- c("singer", "vibrato rate Hz")
user_two <- c("singer", "style × sex")

# The guess @wizardPrepareTable makes on each of these tables, transcribed
# from the first render of the page (evidence/walks/d117/*_before.png).
guess_reg <- c("jitter pct", "SPL dB")
guess_two <- c("SPL dB", "sex × style")


# ---- 1. both walks reached the state the finding is about -----------------
#
# Two Analysis Plans in one Info window: one from the Run that failed, one
# from the Run pressed after the error return. If a capture has fewer than
# two, the walk did not exercise the return and nothing below means anything.

for (nm in c("regression", "twofactor")) {
    for (tree in c("FIXED", "PREFIX")) {
        cap <- get(paste0(substr(nm, 1, 3), "_", tolower(tree)))
        check_true("v30", sprintf("%s/%s capture holds 2 Analysis Plans",
                                  nm, tree),
                   length(plans(cap)) == 2L)
    }
}

# ---- 2. the first plan is the user's, in all four -------------------------
#
# Unconditional: the first Run happens before any error return, so this holds
# with or without the fix. It pins the walk's inputs to the capture.

check_true("v30", "regression/FIXED  plan 1 names the user's columns",
           identical(columns_of(plans(reg_fixed)[[1]]),  user_reg))
check_true("v30", "regression/PREFIX plan 1 names the user's columns",
           identical(columns_of(plans(reg_prefix)[[1]]), user_reg))
check_true("v30", "twofactor/FIXED   plan 1 names the user's columns",
           identical(columns_of(plans(two_fixed)[[1]]),  user_two))
check_true("v30", "twofactor/PREFIX  plan 1 names the user's columns",
           identical(columns_of(plans(two_prefix)[[1]]), user_two))

# ---- 3. THE FINDING: plan 2, after the error return -----------------------
#
# Fixed: Run pressed untouched reports the user's own analysis again.
# Pre-fix: it reports the column guess instead — a different analysis, with
# nothing in the Info window to say the selection changed.

check_true("v30", "regression/FIXED  plan 2 still names the user's columns",
           identical(columns_of(plans(reg_fixed)[[2]]), user_reg))
check_true("v30", "twofactor/FIXED   plan 2 still names the user's columns",
           identical(columns_of(plans(two_fixed)[[2]]), user_two))

check_true("v30", "regression/PREFIX plan 2 named the guess (defect present)",
           identical(columns_of(plans(reg_prefix)[[2]]), guess_reg))
check_true("v30", "twofactor/PREFIX  plan 2 named the guess (defect present)",
           identical(columns_of(plans(two_prefix)[[2]]), guess_two))

# ---- 4. the guess and the user's choice really are distinguishable --------
#
# If they coincided, every check above would pass for the wrong reason.

check_true("v30", "regression walk: guess differs from user's selection",
           !identical(guess_reg, user_reg))
check_true("v30", "twofactor walk: guess differs from user's selection",
           !identical(guess_two, user_two))

# ---- 5. no plan in a FIXED capture names a guessed column -----------------
#
# Stronger and shape-independent: whatever the plan count, nothing the fixed
# wizard reported mentions a column the user did not choose. Written this way
# so that a future page which reports its columns under some third pair of
# labels is still covered, as long as columns_of() knows the labels.

fixed_all <- function(cap) unlist(lapply(plans(cap), columns_of))
check_true("v30", "regression/FIXED  reports no guessed column anywhere",
           !any(fixed_all(reg_fixed) %in% setdiff(guess_reg, user_reg)))
check_true("v30", "twofactor/FIXED   reports no guessed column anywhere",
           !any(fixed_all(two_fixed) %in% setdiff(guess_two, user_two)))

# ---- 6. and the pre-fix run did not merely misreport — it RAN -------------
#
# The distinction that makes this a finding rather than a cosmetic one. In the
# pre-fix captures a full results block follows the second plan: the wizard
# computed and reported an analysis nobody asked for. In the fixed captures
# the second Run fails on the user's own selection, exactly as the first did,
# so no results block appears at all.

ran <- function(cap) any(grepl("^\\s+EML Stats : ", cap))
check_true("v30", "regression/PREFIX ran an analysis after the return",
           ran(reg_prefix))
check_true("v30", "twofactor/PREFIX  ran an analysis after the return",
           ran(two_prefix))
check_true("v30", "regression/FIXED  ran no analysis after the return",
           !ran(reg_fixed))
check_true("v30", "twofactor/FIXED   ran no analysis after the return",
           !ran(two_fixed))


# ---- 7. one idiom, not nine copies ---------------------------------------
#
# The fix is a single procedure, @wizardColIdx, called wherever a column
# optionmenu has to be re-seeded. This guards the thing that has bitten this
# project three times: a correction propagated by hand that stops partway.
# If someone re-introduces the inline loop, this fails while every behavioural
# check above still passes.

wiz <- readLines(repo_path("plugin", "scripts", "eml-wizard.praat"),
                 warn = FALSE)
check_true("v30", "@wizardColIdx is defined exactly once",
           sum(grepl("^procedure wizardColIdx:", wiz)) == 1L)
check_true("v30", "no hand-written column-index loop survives in the wizard",
           !any(grepl("^\\s*if emlTableColumnNames\\.name\\$\\[iCol\\] =", wiz)))
# One call per column optionmenu that has to survive a return: two groups (2),
# three-or-more groups (2), two-factor (3), paired (2), regression (2),
# correlation (2), describe one column (1), predict (2), normality: one
# column (1), normality: one column by group (1) = 18. An exact count is the
# point — a page that loses its call is what this is here to catch.
check_true("v30", "one call per column menu on all ten pages (18)",
           sum(grepl("^\\s*@wizardColIdx:", wiz)) == 18L)

if (!exists("EML_SUITE")) { eml_report("v30 wizard form state across an error return (D117)"); eml_exit() }
