# ============================================================================
# v49_every_path_exports.R -- every analysis a user can run can be saved
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS FILE EXISTS. AUTHOR RULING, 14 August 2026: every path through
# every approach must reach the export step. Until that day three did not --
# the wizard's Describe (single column), Describe by group, and Check
# normality -- and the way they failed is the point of this file rather than
# the fact that they failed.
#
# They did not fail loudly. eml-wizard.praat gates its post-analysis button
# row on two flags, wizCanDraw and wizCanExport, and a branch that never sets
# wizCanExport simply comes up with no Save button. There is no error, no
# empty file, no "Nothing to Export" -- the button is absent, and an absent
# button looks like a decision. It was even written down as one: a comment
# said those branches "deliberately do not" set the flag "because they fill no
# result buffer". That sentence was TRUE about the code and FALSE about the
# intent, and once written it made the gap invisible to reading.
#
# NOTHING COULD HAVE CAUGHT IT, and each reason is closed here:
#
#   * harness/savepaths presses Save on every caller of @emlSavePanel. A
#     branch with no Save button is not a caller, so it is outside that
#     harness's population BY CONSTRUCTION -- the same shape as the graphs
#     form's Exp CSV button being outside v20/v21's.
#   * v46 reads call sites of the panel. A branch that never reaches one has
#     no call site to read.
#   * coverage.R compares rendered cases against claimed cases per artefact.
#     A path that offers no export produces no artefact at all.
#
# So the population is neither call sites nor artefacts. It is the set of
# TERMINAL BRANCHES -- every place the wizard finishes an analysis and hands
# the user to the post-analysis page -- and that is a property of the source,
# which is what this file reads.
#
#     Rscript validate/v49_every_path_exports.R
#
# Input: the plugin source. $EML_PLUGIN_DIR overrides, for break tests.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

plug <- Sys.getenv("EML_PLUGIN_DIR", unset = "")
if (!nzchar(plug)) plug <- repo_path("plugin")

wiz <- file.path(plug, "scripts", "eml-wizard.praat")
check_true("v49", "the wizard was read", file.exists(wiz))
if (!file.exists(wiz)) {
    if (!exists("EML_SUITE")) { eml_report("v49 every path exports"); eml_exit() }
}

w <- readLines(wiz, warn = FALSE)
code <- !grepl("^\\s*[#;]", w)

# ---------------------------------------------------------------------------
# 1. EVERY TERMINAL BRANCH SETS wizCanExport
# ---------------------------------------------------------------------------
# A terminal branch is one that jumps to WIZ_WHAT_NEXT -- the post-analysis
# page. Enumerated from the source rather than listed here, so a branch added
# tomorrow is in the population tomorrow.
jumps <- which(code & grepl("goto\\s+WIZ_WHAT_NEXT", w))
check_true("v49", sprintf("the wizard has terminal branches (%d)", length(jumps)),
           length(jumps) >= 6)

# For each jump, look back for the nearest wizCanExport assignment and the
# nearest label. A branch that set it to 1 is fine; one whose nearest setting
# is the file-level `wizCanExport = 0` initialiser reaches the page with no
# Save button.
sets <- which(code & grepl("wizCanExport\\s*=", w))
lab  <- which(code & grepl("^\\s*label\\s+", w))

.nearest <- function(i, xs) { p <- xs[xs < i]; if (length(p)) max(p) else NA }

bad <- character(0)
for (j in jumps) {
    s <- .nearest(j, sets)
    l <- .nearest(j, lab)
    lname <- if (is.na(l)) "?" else trimws(sub("^\\s*label\\s+", "", w[l]))
    val <- if (is.na(s)) "never" else trimws(sub(".*wizCanExport\\s*=\\s*", "", w[s]))
    # The LMM page is the one branch allowed to reach the page without an
    # export, and it is named rather than tolerated by silence: mixed models
    # are TABLED by standing author ruling and the route into them is
    # disconnected, so no user reaches it. If the module is ever reconnected
    # this check must be updated deliberately.
    if (!grepl("LMM", lname, ignore.case = TRUE) && !identical(val, "1"))
        bad <- c(bad, sprintf("line %d (after label %s): wizCanExport = %s",
                              j, lname, val))
}
check_true("v49",
           sprintf("every wizard branch that finishes an analysis can export (%s)",
                   if (length(bad)) paste(bad, collapse = "; ") else "all do"),
           length(bad) == 0)

# THE TABLED BRANCH IS STILL TABLED. If somebody reconnects mixed models
# without giving them an export, the exemption above would hide it -- so the
# exemption is only valid while the route really is disconnected.
setup <- file.path(plug, "setup.praat")
if (file.exists(setup)) {
    st <- readLines(setup, warn = FALSE)
    st <- st[!grepl("^\\s*[#;]", st)]
    check_true("v49", "mixed models are still disconnected from the menu",
               !any(grepl("[Ll]inear mixed model", st)))
}

# ---------------------------------------------------------------------------
# 2. EVERY DESCRIBE PATH FILLS A BUFFER
# ---------------------------------------------------------------------------
# Setting the flag is not the same as having something to export: the panel
# offers a CSV only when emlCSV_n > 0 or the analysis declared. Both describe
# paths fill the LEGACY buffer -- the tidy vocabulary is a whitelist and would
# drop every statistic they produce -- so what is checked is that each one
# calls the shared row builder.
ana <- file.path(plug, "stats", "eml-analysis.praat")
if (file.exists(ana)) {
    a <- readLines(ana, warn = FALSE)
    a <- a[!grepl("^\\s*[#;]", a)]
    check_true("v49", "the descriptive row builder exists",
               any(grepl("^procedure emlCSVAddDescriptiveRow", a)))
    check_true("v49", "the descriptive orchestrator fills the legacy buffer",
               any(grepl("@emlCSVAddDescriptiveRow", a)))
    # AND STAYS UNCONVERTED in the broom sense, which is what
    # harness/broom_cases/contamination_probe.praat depends on: it uses this
    # orchestrator as the canonical path that must NOT inherit a previous
    # analysis's declaration.
    body <- a[cumsum(grepl("^procedure emlRunDescriptiveAnalysis", a)) == 1]
    body <- body[cumsum(grepl("^endproc", body)) == 0]
    check_true("v49", "and it does not declare into the broom collectors",
               !any(grepl("@emlResultBegin|@emlDeclare", body)))
}
check_true("v49", "describe by group fills the legacy buffer too",
           any(grepl("@emlCSVAddDescriptiveRow", w[code])))

# ---------------------------------------------------------------------------
# 3. NORMALITY RUNS THE SHIPPED ORCHESTRATOR
# ---------------------------------------------------------------------------
# The standalone normality page used to call @wizardNormCheck -- the wizard's
# own pre-check diagnostic, which exists to feed a recommendation into a
# test-choice page and declares nothing. @emlRunNormalityAnalysis reports the
# same test AND calls @emlDeclareNormalityResult, which had been correct and
# unreached from here all along. Pinned so the page cannot drift back onto the
# local copy, which is the DRY failure that caused this.
check_true("v49", "the standalone normality page runs the shipped orchestrator",
           any(grepl("@emlRunNormalityAnalysis", w[code])))

# ---------------------------------------------------------------------------
# 4. EVERY STATS WRAPPER OFFERS A SAVE
# ---------------------------------------------------------------------------
# The same property one layer out. A wrapper whose post-analysis row lost its
# Save button would be invisible to harness/savepaths for the same reason the
# wizard's describe page was: not a caller, so not in the population.
scr <- list.files(file.path(plug, "scripts"), pattern = "^eml-.*\\.praat$",
                  full.names = TRUE)
noSave <- character(0)
nAnalysis <- 0
for (p in scr) {
    x <- readLines(p, warn = FALSE)
    xc <- x[!grepl("^\\s*[#;]", x)]
    # A wrapper is a script that runs an orchestrator and offers a
    # post-analysis page. Menu shims and libraries are neither.
    if (!any(grepl("@emlRun[A-Za-z]+Analysis:", xc))) next
    nAnalysis <- nAnalysis + 1
    # eml-lmm.praat is exempt for the same standing ruling as the wizard's
    # LMM page: mixed models are TABLED and the menu entry is not registered,
    # so no user reaches it. Named, not tolerated by silence -- the
    # disconnection is checked above.
    if (grepl("eml-lmm", basename(p))) next
    if (!any(grepl("@emlSavePanel:", xc)))
        noSave <- c(noSave, basename(p))
}
check_true("v49", sprintf("the plugin has analysis wrappers (%d)", nAnalysis),
           nAnalysis >= 9)
check_true("v49",
           sprintf("every analysis wrapper offers a Save (%s)",
                   if (length(noSave)) paste(noSave, collapse = ", ") else "all do"),
           length(noSave) == 0)

if (!exists("EML_SUITE")) {
    eml_report("v49 every path exports: no analysis a user can run is unsaveable")
    eml_exit()
}
