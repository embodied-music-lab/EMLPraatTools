# ============================================================================
# v128 — the wizard flow invariant (punch list 4.9 / risk register R3)
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# THE BUG CLASS. `scripts/eml-wizard.praat` is one sequential, goto-chained
# file. A page's dialog fields are seeded from "*Default" variables (column
# indices) or from the `a3kSel[]` array (repeated-measures condition slots).
# The FIRST time a page renders, those seeds are a guess -- built from
# @emlGuessColumnRoles or a fixed initial fill. Every SUBSEQUENT time the
# SAME page renders -- because a downstream page's "Back" button, or this
# page's own validation guard, does `goto <thisLabel>` -- those seed
# variables must instead hold what the user actually picked last time,
# or the redraw shows the guess again with no sign that anything typed was
# lost. This is not hypothetical: three of the wizard's own pages carry a
# comment recording exactly this defect, found and fixed (lines 858-863,
# 1228-1231, 1506-1508 as read against the tree this file was written
# against -- see the SEEDED VIOLATION section below for how this check
# proves it would have caught each one).
#
# THE FIX, already idiomatic in every page that gets it right: after the
# page's own `endPause`, before any code path that can `goto` back to this
# SAME label, write the user's answer back into the seed variable the
# optionmenu was constructed from -- by whatever means turns the answer back
# into a POSITION, column name through a name->index round trip:
#
#   @wizardColIdx: someColumnName$      # column optionmenus (*Default vars)
#   someDefault = wizardColIdx.idx
#
#   @wizardCondSlot: someConditionName$ # A3K condition slots (a3kSel[n])
#   a3kSel[n] = wizardCondSlot.idx
#
#   @wizardCorrGrpIdx: someGroupName$   # correlation group column
#   wizCorrGrpSelIdx = wizardCorrGrpIdx.idx
#
# or a flat menu whose row already IS its own seed, needing no name
# translation at all -- a direct copy of the answer back into the seed:
#
#   wizGroupOrderDefault = group_order  # Group order, Test (correlation), ...
#
# THE INVARIANT THIS FILE CHECKS: for every label in the wizard that (a) is
# a jump target BY WAY OF A LATER SELF-GOTO -- some `goto` AFTER the label's
# own line names it, meaning code below the label can re-enter it, as
# distinct from a `goto` BEFORE the label that only ever reaches it once,
# forward, in the ordinary top-to-bottom walk (see "WHY 'LATER'" below) --
# and (b) owns a dialog field bound to a variable the PAGE ITSELF SEEDS --
# see "DERIVING THE PRESERVED-VARIABLE SET" below for what that means and
# how it is read from the file rather than listed -- the write-back for
# that variable must appear STRICTLY BETWEEN the label and the earliest
# later `goto` that names the SAME label. A write-back appearing after that
# earliest self-goto is provably too late: the goto fires before the
# write-back ever runs, so the redraw it triggers still holds the stale
# seed.
#
# WHY "LATER": THE HOLE THIS CLOSED (measured 25 Aug 2026). A label some
# EARLIER goto jumps down to (a dispatch, e.g. "if x = 3 goto LATER_LABEL")
# is a jump target by the plain English of that word, but it is reached
# that way EXACTLY ONCE per run -- nothing re-enters it, so there is no
# "next render" for a stale seed to leak into and the invariant has nothing
# to assert. The version of this file that counted ANY goto (earlier or
# later) as making a label a target still only CHECKED labels with a LATER
# one (the violation loop needs a window to look inside, and a forward-only
# target has none), so its banner COUNTED a forward-only label as examined
# while never actually examining it -- C_NORM_GROUP, reached only by the
# normality page's forward dispatch, was inside the "12" the old banner
# printed and outside every violation check that ran. An overstated
# anti-vacuity count is the exact failure the anti-vacuity check exists to
# rule out, so "target" now means "reachable by a LATER goto", full stop --
# the same test the violation loop always needed, now the same test the
# count uses too. A forward-only label is simply not part of this
# invariant, which is correct: it cannot go stale because it never redraws.
#
# WHAT THIS FILE DOES NOT CLAIM. It is a SOURCE check, in the same spirit as
# v98: it proves ordering from line position, not from a Praat interpreter.
# It does not evaluate `if` conditions, so a preserve step that is reachable
# on paper but dead in every real run would still satisfy it (none exist in
# the tree today; see the shipped-tree audit below). And it only asserts the
# invariant for labels that actually own a preservable field -- a label
# whose page seeds nothing (e.g. a formula sentence field, or a fixed-choice
# optionmenu that is meant to reset to a literal every time rather than
# persist) is outside the invariant's reach by construction, not by a
# hand-written exemption. THE STRUCTURAL REWRITE OF THE WIZARD'S FLOW
# ITSELF IS OUT OF THIS ROUND (punch list 4.9's own words) -- this file is a
# guard against regression in the goto-chained structure as it stands, not
# a redesign of that structure.
#
# ---------------------------------------------------------------------------
# DERIVING THE LABEL SET AND THE PRESERVED-VARIABLE SET, RATHER THAN LISTING
# EITHER -- both read from the source on every run, so a page lane 4 adds
# this afternoon is examined by construction and never falls out of scope
# through staleness of a hand-written list.
#
#   labels             every line matching `label NAME` outside a comment.
#   goto targets       every `goto NAME` AFTER that label's own line, outside
#                       a comment (see "WHY 'LATER'" above); NAME is a jump
#                       target iff some later goto names it.
#   seeded variable     THE WIDENED RULE (closes the second hole measured
#                       25 Aug 2026 -- ten dropdown-bound variables on
#                       jump-target pages, six of them added that same
#                       morning, sat outside the old rule entirely, because
#                       that rule only recognised a write-back that read
#                       `= wizardColIdx.idx` or `= wizardCondSlot.idx`
#                       literally. @wizardCorrGrpIdx above is a THIRD such
#                       procedure and would have been a third name to add to
#                       that literal list -- forever one step behind
#                       whatever procedure the next page's author reaches
#                       for. So the rule no longer names a procedure at
#                       all: a variable is SEEDED if it is bound by some
#                       `optionmenu:` line ANYWHERE in the file, AND is the
#                       LHS of some plain assignment `VAR = <expr>` (outside
#                       a comment, at the START of its line, so a guard like
#                       `if VAR = 3` never counts) whose right-hand side is
#                       not a bare literal (a number or a quoted string).
#                       A literal RHS is a page choosing to RESET the field
#                       every time it renders (e.g. `normDefault = 1` before
#                       B_NORM_PAGE's own first visit) -- exactly the
#                       "meant to reset rather than persist" case the
#                       original comment above carved out, and it stays
#                       carved out under the wider rule for the same
#                       reason. Any OTHER right-hand side -- a round-trip
#                       procedure's `.idx` output, a raw form answer copied
#                       straight across (`wizGroupOrderDefault = group_order`,
#                       `normDefault = test`), a loop's running index -- is
#                       the page computing what to show FROM something the
#                       user (or the data) supplied, which is a write-back
#                       by construction, whatever computed it. VAR keeps its
#                       own `[n]` subscript where present, so `a3kSel[1]`
#                       through `a3kSel[6]` are six distinct seeded
#                       variables, matching the six condition slots, not one
#                       array name asserted once.
#   preservable field   an `optionmenu: "...", VAR` line whose VAR is a
#                       seeded variable, found within a label's own page
#                       span (its label line up to the next label).
#
# A comment line (line whose trimmed text starts with "#") is excluded from
# every regex above; a real Praat comment runs to end of line and this file
# has three at exactly the sites the write-back was once missing (see the
# header above), which would otherwise fabricate a phantom self-goto or a
# phantom write-back and either produce a false FAIL or a false PASS.
#
# Base R only. No packages.
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

ID <- "v128"

# ---------------------------------------------------------------------------
# wizard_path -- the shipped file, or a copy pointed at by EML_DIALOG_SRC,
# the same door v98 / v113 / v116 / v117 already use for their red
# demonstrations. EML_DIALOG_SRC names a plugin ROOT (it holds a `scripts/`
# subdirectory); this file reads exactly one file under it.
# ---------------------------------------------------------------------------
wizard_path <- function() {
    root <- Sys.getenv("EML_DIALOG_SRC", unset = "")
    if (!nzchar(root)) root <- repo_path("plugin_EML_StatsGraphs")
    p <- file.path(root, "scripts", "eml-wizard.praat")
    if (!file.exists(p)) stop("wizard script not found: ", p)
    p
}

is_comment <- function(line) grepl("^\\s*#", line)

LABEL_RE   <- "^\\s*label\\s+([A-Za-z][A-Za-z0-9_]*)\\s*$"
GOTO_RE    <- "\\bgoto\\s+([A-Za-z][A-Za-z0-9_]*)\\b"
OPTIONMENU_RE <- "optionmenu:\\s*\"[^\"]*\"\\s*,\\s*([A-Za-z_][A-Za-z0-9_]*(\\[[0-9]+\\])?)"

# A plain assignment, anchored to the START of the line so a guard such as
# `if VAR = 3` (which has "if " before VAR) never matches. VAR keeps its own
# `[n]` subscript. Group 3 is the whole right-hand side, trimmed later --
# whether IT is a bare literal is what separates a page's own RESET
# (`normDefault = 1`) from a page's WRITE-BACK (everything else: a round-trip
# procedure's `.idx`, a raw answer copied across, a loop's running index).
ASSIGN_RE  <- "^\\s*([A-Za-z_][A-Za-z0-9_]*(\\[[0-9]+\\])?)\\s*=\\s*(.+?)\\s*$"
LITERAL_RE <- "^(-?[0-9]+(\\.[0-9]+)?|\"[^\"]*\")$"

# ---------------------------------------------------------------------------
# audit_wizard -- the whole check, over one wizard source file. Returns the
# per-label classification and the violation list; the fixtures below run
# this exact function on a seeded copy, so a rule that stops firing on the
# shipped tree stops firing on the seeded violation too.
# ---------------------------------------------------------------------------
audit_wizard <- function(path) {
    raw <- readLines(path, warn = FALSE)
    n <- length(raw)
    code <- !is_comment(raw)

    # Labels, in file order.
    lab_hit <- code & grepl(LABEL_RE, raw)
    lab_line <- which(lab_hit)
    lab_name <- sub(LABEL_RE, "\\1", raw[lab_line])
    if (any(duplicated(lab_name)))
        stop("duplicate label name(s) in wizard source: ",
             paste(unique(lab_name[duplicated(lab_name)]), collapse = ", "))

    # Every real (non-comment) `goto NAME`, with its line number.
    goto_hit  <- code & grepl(GOTO_RE, raw)
    goto_line <- which(goto_hit)
    goto_name <- sub(paste0(".*", GOTO_RE, ".*"), "\\1", raw[goto_line])

    # Every real optionmenu field, with its bound variable and line number.
    om_hit  <- code & grepl(OPTIONMENU_RE, raw)
    om_line <- which(om_hit)
    om_var  <- sub(paste0(".*", OPTIONMENU_RE, ".*"), "\\1", raw[om_line])
    dropdown_vars <- unique(om_var)

    # Every real plain assignment, with its variable, line number and
    # whether its right-hand side is a bare literal (a page's own RESET,
    # never a write-back). A variable is SEEDED -- inside this invariant --
    # when it is bound by SOME optionmenu above, AND is the LHS of at least
    # one non-literal assignment somewhere in the file: the page seeds it
    # from something computed, whatever computed it, not by a name this file
    # has to know in advance. See "seeded variable" in the header comment.
    asn_hit  <- code & grepl(ASSIGN_RE, raw)
    asn_line <- which(asn_hit)
    asn_var  <- sub(ASSIGN_RE, "\\1", raw[asn_line])
    asn_rhs  <- sub(ASSIGN_RE, "\\3", raw[asn_line])
    asn_literal <- grepl(LITERAL_RE, trimws(asn_rhs))

    # Every real write-back assignment, with its variable and line number --
    # a non-literal assignment to a variable some optionmenu also binds.
    pres_hit  <- asn_hit
    pres_hit[asn_hit] <- (!asn_literal) & (asn_var %in% dropdown_vars)
    pres_line <- which(pres_hit)
    pres_var  <- asn_var[asn_line %in% pres_line]

    preserved_vars <- unique(pres_var)

    n_lab <- length(lab_line)
    page_end <- c(lab_line[-1] - 1L, n)  # next label's line minus one, or EOF

    results <- vector("list", n_lab)
    for (i in seq_len(n_lab)) {
        nm <- lab_name[i]; ln <- lab_line[i]; pe <- page_end[i]

        # A "target" is a label some LATER goto names -- code below it that
        # can send execution back up to re-render it. A goto that only
        # reaches it from ABOVE (a forward dispatch) reaches it exactly
        # once and gives it no "next render" to go stale on, so it is not a
        # target of THIS invariant (see "WHY 'LATER'" in the header).
        self_goto <- goto_line[goto_name == nm & goto_line != ln]
        later_goto <- self_goto[self_goto > ln]
        is_target <- length(later_goto) > 0L
        first_self_goto <- if (is_target) min(later_goto) else NA_integer_

        # Preservable fields -- and so the violation check itself -- are
        # only ever computed for an actual target: the count and the
        # examination are the SAME test, so a banner that says N pages
        # carry a preservable field means N pages were actually walked for
        # violations, not N-minus-however-many were only counted.
        preservable <- character(0)
        violations <- character(0)
        if (is_target) {
            page_om_vars <- unique(om_var[om_line >= ln & om_line <= pe])
            preservable <- page_om_vars[page_om_vars %in% preserved_vars]
            for (v in preservable) {
                ok_lines <- pres_line[pres_var == v & pres_line > ln &
                                       pres_line < first_self_goto]
                if (length(ok_lines) == 0L)
                    violations <- c(violations, v)
            }
        }

        results[[i]] <- list(
            name = nm, line = ln, is_target = is_target,
            first_self_goto = first_self_goto,
            preservable = preservable,
            violations = violations
        )
    }

    list(n_lines = n, n_labels = n_lab, results = results,
         n_targets = sum(vapply(results, function(r) r$is_target, logical(1))),
         n_asserted = sum(vapply(results, function(r) length(r$preservable) > 0, logical(1))))
}

format_violation <- function(r) {
    sprintf("label %s (line %d): %s never re-preserved before its own goto (first at line %d)",
            r$name, r$line, paste(r$violations, collapse = ", "), r$first_self_goto)
}

# ===========================================================================
# THE SHIPPED-TREE AUDIT
# ===========================================================================
shipped_path <- wizard_path()
shipped <- audit_wizard(shipped_path)

cat(sprintf("\n%s: %d lines, %d labels derived, %d are goto targets, %d carry a preservable field.\n",
           basename(shipped_path), shipped$n_lines, shipped$n_labels,
           shipped$n_targets, shipped$n_asserted))

# ANTI-VACUITY: a check that examined nothing passes everything. The wizard
# has had double digits of labels since before this file existed; a floor of
# 15 is comfortably under the true count and only trips if the walk itself
# broke (label regex stopped matching, wrong file resolved, etc).
check_true(ID, sprintf("the label walk examined a plausible number of labels (%d, floor 15)",
                       shipped$n_labels),
           shipped$n_labels >= 15L)
check_true(ID, "at least one label is a goto target",
           shipped$n_targets > 0L)
check_true(ID, "at least one goto-target label carries a preservable field",
           shipped$n_asserted > 0L)

shipped_violations <- Filter(function(r) length(r$violations) > 0L, shipped$results)
for (r in shipped_violations) cat("VIOLATION: ", format_violation(r), "\n", sep = "")

check_true(ID, sprintf("every goto-target label's preservable field(s) are re-preserved before that label's own goto (0 of %d violate)",
                       shipped$n_asserted),
           length(shipped_violations) == 0L)

# ===========================================================================
# THE SEEDED VIOLATION (mutation standard, per the punch list's own words:
# "Red demo: remove one preserve step.")
# ===========================================================================
# A check that always finds "preserved" is as unfalsifiable as one that
# never looks. So a copy of the wizard is seeded by deleting exactly one
# write-back line this check currently finds correctly placed, and the same
# audit_wizard() is re-run against the copy through EML_DIALOG_SRC -- the
# same door v98/v113/v116/v117 use -- unmodified.
#
# TARGET: A2A_NORM_PAGE's `dataDefault = wizardColIdx.idx` write-back (the
# two-group column-select page). On the shipped tree this line sits between
# the label and the page's own first self-goto (the "Back" path from
# A2A_TEST_PAGE and the page's own guards), so PASS. Deleting it removes the
# only write-back for `dataDefault` in that page's span -- `dataDefault` is
# reassigned by @wizardColIdx on three OTHER pages (A2B_NORM_PAGE,
# A2C_TWOFACTOR, C_SINGLE), each outside A2A_NORM_PAGE's own line span, so
# none of them can accidentally satisfy this page's requirement and mask
# the seeded defect.
# ===========================================================================
TARGET_LABEL <- "A2A_NORM_PAGE"
TARGET_VAR   <- "dataDefault"

seed_root <- file.path(tempdir(), "v128_seeded_wizard")
unlink(seed_root, recursive = TRUE)
dir.create(file.path(seed_root, "scripts"), recursive = TRUE, showWarnings = FALSE)
seed_target <- file.path(seed_root, "scripts", "eml-wizard.praat")
file.copy(shipped_path, seed_target, overwrite = TRUE)

sl <- readLines(seed_target, warn = FALSE)
lab_ln <- which(grepl(LABEL_RE, sl) & sub(LABEL_RE, "\\1", sl) == TARGET_LABEL &
                !is_comment(sl))
seed_ok <- FALSE
if (length(lab_ln) == 1L) {
    # The write-back line for TARGET_VAR nearest after the label (the one
    # this page's PASS currently rests on) -- a non-literal assignment, the
    # same test audit_wizard() itself uses to tell a write-back from a reset.
    sl_code <- !is_comment(sl)
    sl_asn  <- sl_code & grepl(ASSIGN_RE, sl)
    sl_var  <- sub(ASSIGN_RE, "\\1", sl)
    sl_rhs  <- sub(ASSIGN_RE, "\\3", sl)
    sl_lit  <- grepl(LITERAL_RE, trimws(sl_rhs))
    cand <- which(sl_asn & !sl_lit & sl_var == TARGET_VAR)
    cand <- cand[cand > lab_ln]
    if (length(cand)) {
        victim <- min(cand)
        sl[victim] <- paste0("# SEEDED-OUT ", sl[victim])
        writeLines(sl, seed_target)
        seed_ok <- TRUE
    }
}
check_true(ID, sprintf("the seeded copy's %s write-back for %s was found and removed (%s)",
                       TARGET_LABEL, TARGET_VAR, if (seed_ok) "ok" else "NOT FOUND -- source moved underneath this check"),
           seed_ok)

old_src <- Sys.getenv("EML_DIALOG_SRC", unset = NA)
Sys.setenv(EML_DIALOG_SRC = seed_root)
seeded <- audit_wizard(wizard_path())
if (is.na(old_src)) Sys.unsetenv("EML_DIALOG_SRC") else
    Sys.setenv(EML_DIALOG_SRC = old_src)

check_true(ID, "EML_DIALOG_SRC pointed the same audit at the seeded copy (same label count)",
           seeded$n_labels == shipped$n_labels)

seed_violations <- Filter(function(r) length(r$violations) > 0L, seeded$results)
target_seed_v <- Filter(function(r) r$name == TARGET_LABEL, seed_violations)

if (length(target_seed_v) == 1L)
    cat(sprintf("\nSEEDED VIOLATION, CAUGHT:\n  %s\n",
               format_violation(target_seed_v[[1]])))

check_true(ID, sprintf("%s's preservable field %s is undisclosed-before-goto -- RED -- on the seeded copy",
                       TARGET_LABEL, TARGET_VAR),
           length(target_seed_v) == 1L &&
               TARGET_VAR %in% target_seed_v[[1]]$violations)

# Nothing ELSE should have gone red: the seed touched one line in one page.
other_shipped <- setdiff(vapply(shipped_violations, function(r) r$name, character(1)), TARGET_LABEL)
other_seeded  <- setdiff(vapply(seed_violations, function(r) r$name, character(1)), TARGET_LABEL)
check_true(ID, "no OTHER label's classification changed under the single-line seed",
           setequal(other_shipped, other_seeded))

unlink(seed_root, recursive = TRUE)

if (!exists("EML_SUITE")) {
    eml_report("v128 the wizard flow invariant"); eml_exit()
}
