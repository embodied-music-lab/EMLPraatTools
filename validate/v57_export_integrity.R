# ============================================================================
# v57_export_integrity.R -- what reaches disk, and what a refusal may claim
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS FILE EXISTS. The 14 August 2026 audit recomputed more than 150
# statistics across every shipping path and found zero mismatches. Its
# headline is that the engine is right. Its findings are all of the other
# kind: four places where a correct number was surrounded by an incorrect
# claim about itself.
#
#   NEW-G1-1  Check normality tests every numeric column in one press and the
#             dialog says so. Save wrote a tidy frame with ONE data row -- the
#             last column -- and a glance row with no identifier on it at all.
#             The report carried all three columns, so the Info window and the
#             CSV disagreed and only the CSV was wrong. The exported row was
#             correct to 1e-11 against scipy, which is precisely why nobody
#             noticed: there was nothing wrong to see, only something absent.
#             Mechanism: the orchestrator ran @emlCSVInit at its own entry and
#             the wrapper called it once per column, so every pass wiped the
#             pass before it. Same init-discipline family as D66. The rule the
#             audit asked for, and the rule this file holds: INIT ONCE PER
#             PRESS, ACCUMULATE PER LOOP.
#
#   NEW-G4-1  The ANOVA augment frames emitted `.std.resid`, which is broom's
#             name for rstandard() -- e_i / (s * sqrt(1 - h_i)) -- carrying
#             e_i / s, with no leverage term. A flat 4.4% understatement on
#             the balanced two-way demo (1 / sqrt(1 - 1/12) = 1.044466) and a
#             per-observation one on anything unbalanced. D58 had corrected
#             exactly this in the regression arm, through @emlOLSInfluence,
#             and the two ANOVA arms were left behind.
#
#   NEW-G6-1  Repeated measures drops a row unless every condition cell is
#             present. On validate/redpath/r1_incomplete_cases.csv that is
#             four rows of eight, and the D97 refusal then told the user "every
#             subject shows exactly the same pattern across conditions" -- a
#             statement about a population half of which had been removed
#             without a word. The exclusion note existed; it printed on the
#             SUCCESS path, below results the refusal never reaches.
#
#   NEW-G12-3 Paired comparison on zero-variance data ran no test at all and
#             reported "Analysis complete", with Save, Draw and New under it.
#             The sentence saying nothing had run was six lines up the Info
#             window, prefixed "Paired t-test error:". The plugin already
#             refuses well -- the singleton-group modal names the groups, the
#             n and the rule, and keeps the user's selections on Back -- so
#             the finding is not that refusal is hard here. It is that one
#             path did it and another did not.
#
# WHAT THE FAILURE LOOKS LIKE, in one sentence: a green suite, a clean Info
# window, correct arithmetic, and a file on disk that is missing two thirds of
# what the user asked for.
#
# WHAT COULD NOT HAVE CAUGHT IT, and each reason is closed here.
#
#   * EVERY NUMERIC VALIDATOR. v15 recomputes the normality statistics, v03
#     the RM-ANOVA, v05 the paired t. All of them compare a value the plugin
#     printed against a value R computes. Not one of them counts ROWS, and
#     NEW-G1-1 changes no value -- it deletes two of three. A validator built
#     to ask "is this number right" cannot ask "is this number the only one
#     left".
#
#   * v48. It presses Save on every caller of the panel and asserts that files
#     arrive under one folder and one stem. All three files arrived. The audit
#     suggested growing its one-arm check into a row-count-equals-columns-
#     tested assertion, and that is the right home for it eventually -- v48
#     already owns the journey the press belongs to. v48 IS NOT MINE TO EDIT,
#     so the assertion lives here for now, in section 1, and this paragraph is
#     the note that it wants moving. What it needs from v48's side is the
#     column count, which the savepaths harness does not currently record.
#
#   * v20. This one is worse than a gap, and it is the reason NEW-G4-1 lived
#     as long as it did. v20 line 107 reads
#
#         check("v20", "augment .std.resid total deviation",
#               sum(abs(au$.std.resid - residuals(fit) / sl$sigma)), 0, ...)
#
#     -- it PINS the defect. A validator asserting the wrong formula does not
#     merely fail to catch the error; it makes correcting the error turn the
#     suite red, so the defect is defended by the very thing meant to find it.
#     Compare v21:213 and v24, which assert rstandard() for the REGRESSION arm
#     and even pin the old form as WRONG. The plugin had both the right check
#     and the wrong one, on two arms of the same quantity, for six days.
#     v20 IS NOT MINE TO EDIT either. Section 2 below asserts the correct
#     identity against the live drive; v20's line needs changing to
#     `rstandard(fit)` and its committed evidence regenerating, in one commit,
#     by whoever owns it.
#
#   * v07. Its R3 case -- zero variance throughout -- is an attest(), a
#     human's written record that the drive was watched and the plugin
#     refused. It was watched, and the plugin did print the refusal. What no
#     attestation can record is the dialog the user then saw, because the
#     person writing it was reading the Info window. Section 4 asks the
#     orchestrator directly.
#
#   * harness/wrappers, harness/savepaths and every GUI harness. All of them
#     ask whether a press produced files or a page. None of them reads what
#     the refusal SAID, because refusal text is prose and prose is what a
#     harness records rather than checks.
#
# So the population is not values and it is not artefact counts. It is (a) the
# SHAPE of an exported frame against the shape of the press that produced it,
# and (b) the CONTENT of the sentence an orchestrator hands a wrapper at the
# moment it declines. Both come off harness/exportint, which drives the
# shipping orchestrators and the shipping export surface with no dialog in the
# way.
#
#     praat --run harness/exportint/drive.praat
#     Rscript validate/v57_export_integrity.R
#
# BOTH DIRECTIONS, EVERY TIME. A check that only ever sees the failing case
# cannot tell "refuses correctly" from "refuses always", and a disclosure
# printed unconditionally discloses nothing. So the single-column press is
# driven beside the three-column one, a healthy paired run beside the
# zero-variance one, and a complete-case RM refusal beside the incomplete one.
#
# Input: harness/exportint/out/ -- shape.tsv, refusals.tsv, norm/, aug/ --
#        plus the plugin source. $EML_EXPORTINT_DIR and $EML_PLUGIN_DIR
#        override, for break tests.
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
ei <- Sys.getenv("EML_EXPORTINT_DIR", unset = "")
if (!nzchar(ei)) ei <- repo_path(file.path("harness", "exportint", "out"))

fixdir <- repo_path(file.path("harness", "exportint", "fixtures"))

drove <- check_true("v57",
                    "the export-integrity drive was run (praat --run harness/exportint/drive.praat)",
                    file.exists(file.path(ei, "shape.tsv")) &&
                    file.exists(file.path(ei, "refusals.tsv")))

# A two-column lookup over a headerless TSV. read.delim with quote="" because
# the refusal text contains typographic quotation marks around column names
# and R would otherwise swallow a field boundary inside one.
.tsv <- function(f) {
    p <- file.path(ei, f)
    if (!file.exists(p)) return(data.frame(a = character(0), b = character(0),
                                           c = character(0)))
    x <- read.delim(p, header = FALSE, sep = "\t", quote = "",
                    stringsAsFactors = FALSE, fill = TRUE,
                    col.names = c("a", "b", "c"))
    x$a <- trimws(x$a); x$b <- trimws(x$b)
    x$c <- ifelse(is.na(x$c), "", x$c)
    x
}
shape <- .tsv("shape.tsv")
refus <- .tsv("refusals.tsv")

sh <- function(case, key) {
    i <- which(shape$a == case & shape$b == key)
    if (!length(i)) return(NA_character_)
    shape$c[i[1]]
}
rf <- function(case, field) {
    i <- which(refus$a == case & refus$b == field)
    if (!length(i)) return(NA_character_)
    refus$c[i[1]]
}
.csv <- function(sub, f) {
    p <- file.path(ei, sub, f)
    if (!file.exists(p)) return(NULL)
    read.csv(p, stringsAsFactors = FALSE, check.names = FALSE)
}

if (!drove) {
    if (!exists("EML_SUITE")) {
        eml_report("v57 export integrity: NOT RUN -- drive the harness first")
        eml_exit()
    }
}

# ---------------------------------------------------------------------------
# 1. INIT ONCE PER PRESS, ACCUMULATE PER LOOP
# ---------------------------------------------------------------------------
# The structural assertion the audit asked for, in the form it asked for it:
# the number of data rows in the tidy frame equals the number of columns the
# press tested. It is deliberately not a check on any statistic. A press that
# loses a column keeps every remaining number perfect, so the only thing that
# can disagree is the count -- and, below it, the SET, because two counts can
# agree by coincidence while naming different things.
tidy3 <- .csv("norm", "demo_normality_normality_tidy.csv")
nTested <- suppressWarnings(as.integer(sh("normsave", "columns_tested")))
namesTested <- strsplit(sh("normsave", "columns_named"), ",", fixed = TRUE)[[1]]

check_true("v57", "the multi-column normality press wrote a tidy frame",
           !is.null(tidy3))
if (!is.null(tidy3)) {
    check_true("v57",
               sprintf("tidy rows equal the columns tested (%s rows, %s columns)",
                       nrow(tidy3), nTested),
               !is.na(nTested) && nrow(tidy3) == nTested)
    check_true("v57", "the press tested more than one column, so the check has teeth",
               !is.na(nTested) && nTested > 1)
    # SET-BASED, not a count. eml_census's argument, applied to columns: a
    # count cannot say WHICH column fell out of the export, and the audit's
    # failure dropped two specific ones.
    eml_census("v57", "normality column tested in one press",
               namesTested, tidy3$term)
    check_true("v57", "every tidy term is one of the columns tested",
               all(tidy3$term %in% namesTested))
    check_true("v57", "no column is exported twice",
               !any(duplicated(tidy3$term)))
    check_true("v57", "every exported row names its method",
               all(nzchar(tidy3$method)))
}

# THE PAIRING, which the row count alone cannot see. Three rows carrying one
# column's statistic three times would satisfy every check above. So each
# term's W and p are recomputed from the fixture the drive read, in R, and
# matched to the row that claims them.
fix <- file.path(fixdir, "demo_normality.csv")
if (!is.null(tidy3) && file.exists(fix)) {
    dn <- read.csv(fix, stringsAsFactors = FALSE)
    for (tm in tidy3$term) {
        i <- match(tm, tidy3$term)
        if (!(tm %in% names(dn))) {
            check_true("v57", sprintf("tidy term %s is a column of the fixture", tm),
                       FALSE)
            next
        }
        sw <- shapiro.test(dn[[tm]])
        check("v57", sprintf("tidy statistic for %s is that column's W", tm),
              as.numeric(tidy3$statistic[i]), unname(sw$statistic), tol = 1e-6)
        check("v57", sprintf("tidy p.value for %s is that column's p", tm),
              as.numeric(tidy3$p.value[i]), unname(sw$p.value), tol = 1e-6)
    }
}

# THE OTHER DIRECTION. One column tested must still write exactly one row, and
# the glance frame -- which is one row per MODEL and cannot describe three --
# must still carry the full single-model summary when there is one model.
tidy1 <- .csv("norm", "demo_normality_one_normality_tidy.csv")
gl1 <- .csv("norm", "demo_normality_one_normality_glance.csv")
check_true("v57", "a single-column press writes exactly one tidy row",
           !is.null(tidy1) && nrow(tidy1) == 1L)
check_true("v57",
           "a single-column glance still carries the model's own statistic and p",
           !is.null(gl1) && all(c("statistic", "p.value", "skewness",
                                  "kurtosis", "nobs") %in% names(gl1)))

# THE GLANCE ROW ON A MULTI-MODEL RUN. It was the last column's numbers under
# no identifier. It may not be that again: with more than one model it carries
# only what is true of the RUN, and it says so.
gl3 <- .csv("norm", "demo_normality_normality_glance.csv")
check_true("v57", "a multi-column glance carries no unattributed statistic",
           !is.null(gl3) && !("statistic" %in% names(gl3)) &&
           !("p.value" %in% names(gl3)))
check_true("v57", "and says how many columns the run held, and where they are",
           !is.null(gl3) && "warning" %in% names(gl3) &&
           grepl("columns were tested", gl3$warning[1], fixed = TRUE) &&
           grepl("tidy frame", gl3$warning[1], fixed = TRUE))

# WHERE A PRESS ENDS. Two consecutive single-column runs are the wizard's
# shape -- two presses, each with its own Save. They must not merge, or the
# fix for NEW-G1-1 would have traded a frame that loses rows for one that
# invents them.
tidyW <- .csv("norm", "demo_normality_wizard2_normality_tidy.csv")
check_true("v57",
           "two consecutive single-column presses do not accumulate into one frame",
           !is.null(tidyW) && nrow(tidyW) == 1L)

# ---------------------------------------------------------------------------
# 1b. THE HARNESS LOOP IS THE WRAPPER'S LOOP
# ---------------------------------------------------------------------------
# harness/exportint reproduces three lines of scripts/eml-check-normality.praat
# -- the per-column for loop -- because that wrapper's first statement is
# beginPause and `praat --run` cannot reach past one. A reproduction that
# drifts from the original is a check that passes about nothing, which is the
# defect harness/normality's header names in its own terms. So the original is
# read here and pinned to the shape the harness assumes.
wrap <- file.path(plug, "scripts", "eml-check-normality.praat")
check_true("v57", "the check-normality wrapper was read", file.exists(wrap))
if (file.exists(wrap)) {
    w <- readLines(wrap, warn = FALSE)
    wc <- w[!grepl("^\\s*[#;]", w)]
    loopStart <- grep("for\\s+iSel\\s+from\\s+1\\s+to\\s+nNumericCols", wc)
    loopEnd <- grep("^\\s*endfor\\s*$", wc)
    call <- grep("@emlRunNormalityAnalysis:", wc)
    check_true("v57", "the wrapper still tests every numeric column in one loop",
               length(loopStart) == 1)
    check_true("v57",
               "and calls the normality orchestrator from inside that loop",
               length(loopStart) == 1 && length(call) >= 1 &&
               any(call > loopStart[1]) &&
               any(loopEnd > call[call > loopStart[1]][1]))
    # The wrapper must NOT do the clearing itself. If it ever did, the
    # orchestrator's press detection would be clearing state twice and the
    # accumulation would depend on which ran last.
    check_true("v57", "the wrapper does not clear the collectors itself",
               !any(grepl("@emlCSVInit|@emlResultBegin", wc)))
}

# 1c. AND THE ORCHESTRATOR NO LONGER CLEARS UNCONDITIONALLY.
# The static half of the same rule: every @emlCSVInit inside
# @emlRunNormalityAnalysis sits under an accumulation guard. A future edit
# that drops the guard restores the defect exactly, and would otherwise show
# up only as two missing rows in a file nobody diffs.
ana <- file.path(plug, "stats", "eml-analysis.praat")
check_true("v57", "the analysis layer was read", file.exists(ana))
if (file.exists(ana)) {
    a <- readLines(ana, warn = FALSE)
    st <- grep("^procedure emlRunNormalityAnalysis:", a)
    en <- grep("^endproc\\s*$", a)
    check_true("v57", "@emlRunNormalityAnalysis is present", length(st) == 1)
    if (length(st) == 1) {
        stop_at <- en[en > st[1]][1]
        body <- a[st[1]:stop_at]
        bc <- body[!grepl("^\\s*[#;]", body)]
        inits <- grep("@emlCSVInit", bc)
        check_true("v57", "the orchestrator still clears somewhere",
                   length(inits) >= 1)
        guarded <- vapply(inits, function(i) {
            # the nearest preceding non-comment line must open the guard
            prev <- rev(bc[seq_len(i - 1)])
            prev <- prev[nzchar(trimws(prev))]
            length(prev) > 0 && grepl("if\\s+\\.accumulate\\s*=\\s*0", prev[1])
        }, logical(1))
        check_true("v57",
                   sprintf("every @emlCSVInit in it is guarded by the press test (%d of %d)",
                           sum(guarded), length(inits)),
                   length(inits) >= 1 && all(guarded))
    }
    check_true("v57", "the press boundary is decided in one named place",
               sum(grepl("^procedure eml_normalityPress:", a)) == 1)
    # v46 pins that only stats/eml-output.praat may branch on the migration
    # flag. The press test must therefore keep its own state rather than read
    # emlResult_declared -- asserted here so a later simplification back to
    # the obvious form fails HERE, with the reason attached, rather than in
    # v46 with none.
    st2 <- grep("^procedure eml_normalityPress:", a)
    if (length(st2) == 1) {
        en2 <- en[en > st2[1]][1]
        check_true("v57",
                   "the press test does not branch on the migration flag (v46's rule)",
                   !any(grepl("emlResult_declared", a[st2[1]:en2])))
    }
}

# ---------------------------------------------------------------------------
# 2. A COLUMN NAMED .std.resid IS rstandard(), OR IT IS NOT NAMED .std.resid
# ---------------------------------------------------------------------------
# broom's augment(aov) returns rstandard(): e_i / (s * sqrt(1 - h_i)). The two
# ANOVA arms emitted e_i / s. Both identities are asserted -- the right one
# must hold and the wrong one must NOT -- because a check that only says
# "close to rstandard" passes on a balanced design where the two differ by a
# constant a reader could mistake for tolerance.
#
# No hat matrix is needed on either side. Both models fit one mean per cell,
# so leverage is 1 / n_cell exactly; R's hatvalues() is asked anyway, since
# the point is agreement with R rather than agreement with our own algebra.
.augcase <- function(tag, file, fixture, form) {
    au <- .csv("aug", file)
    fx <- file.path(fixdir, fixture)
    if (is.null(au) || !file.exists(fx)) {
        check_true("v57", sprintf("%s: the augment frame was written", tag), FALSE)
        return(invisible(NULL))
    }
    d <- read.csv(fx, stringsAsFactors = FALSE)
    fit <- aov(as.formula(form), data = d)
    sg <- summary.lm(fit)$sigma
    rst <- unname(rstandard(fit))
    hv <- unname(hatvalues(fit))

    check_true("v57", sprintf("%s: augment is one row per observation", tag),
               nrow(au) == nrow(d))
    check_true("v57", sprintf("%s: augment carries .std.resid and .hat", tag),
               all(c(".std.resid", ".hat") %in% names(au)))
    if (!all(c(".std.resid", ".hat") %in% names(au))) return(invisible(NULL))
    check("v57", sprintf("%s: .std.resid is rstandard(), max |diff|", tag),
          max(abs(au$.std.resid - rst)), 0, tol = 1e-9)
    check("v57", sprintf("%s: .hat is hatvalues(), max |diff|", tag),
          max(abs(au$.hat - hv)), 0, tol = 1e-9)
    # THE DEFECT, pinned as wrong. v24 does this for the regression arm and it
    # is why reverting that one cannot pass quietly.
    check("v57",
          sprintf("%s: .std.resid is NOT the uncorrected resid/sigma", tag),
          max(abs(au$.std.resid - residuals(fit) / sg)), 0,
          tol = 1e-9, expect = "differ")
    # .fitted and .resid are the numbers the audit verified and must not have
    # moved: this fix changes one column and no others.
    check("v57", sprintf("%s: .fitted is unchanged", tag),
          max(abs(au$.fitted - unname(fitted(fit)))), 0, tol = 1e-9)
    check("v57", sprintf("%s: .resid is unchanged", tag),
          max(abs(au$.resid - unname(residuals(fit)))), 0, tol = 1e-9)
}
.augcase("one-way ANOVA", "anova1_augment.csv", "demo_3groups.csv",
         "SPL_dB ~ voice_type")
.augcase("two-way ANOVA", "anova2_augment.csv", "demo_twoway.csv",
         "SPL_dB ~ voice_type * task")

# THE ARITHMETIC ITSELF, READ OUT OF THE TREE -- NEW-G4-1's pin.
#
# Everything above this line is measured off harness/exportint/out, which was
# written the afternoon somebody drove it and goes on saying what it said. Put
# the defect back -- both arms' divisor from `.sigma * sqrt (1 - .hat)` to
# `.sigma` -- and every comparison above stays green, because the committed
# CSV still holds the corrected numbers. So the divisor is read out of
# eml-analysis.praat, in each ANOVA arm's OWN body, and the wrong identity is
# refused there as well as in the frame. The continuation lines are joined
# first: the two-way arm writes its divisor on a `...` line and a
# line-at-a-time grep cannot see it.
.ana_join <- function(path) {
    if (!file.exists(path)) return(character(0))
    raw <- readLines(path, warn = FALSE)
    j <- character(0)
    for (ln in raw) {
        if (grepl("^\\s*\\.\\.\\.", ln) && length(j)) {
            j[length(j)] <- paste0(j[length(j)], " ",
                                   sub("^\\s*\\.\\.\\.\\s*", "", ln))
        } else j <- c(j, ln)
    }
    j <- gsub("\\s+", " ", trimws(j))
    j[!grepl("^[#;]", j)]
}
.ana_body <- function(code, name) {
    st <- grep(paste0("^procedure ", name, "\\b"), code)
    if (!length(st)) return(character(0))
    en <- grep("^endproc$", code)
    en <- en[en > st[1]]
    if (!length(en)) return(character(0))
    code[st[1]:en[1]]
}
ana_code <- .ana_join(ana)
for (arm in c("emlDeclareOneWayAnovaResult", "emlDeclareTwoWayResult")) {
    b <- .ana_body(ana_code, arm)
    std <- grep("^\\.std = ", b, value = TRUE)
    lev <- grepl("sqrt \\(1 - \\.hat\\)", std)
    bare <- grepl("/ \\.sigma", std)          # `/ (.sigma * sqrt ...` has a paren
    check_true("v57",
        sprintf("@%s standardises WITH the leverage term -- .sigma * sqrt (1 - .hat), not .sigma alone",
                arm),
        length(b) > 0 && length(std) >= 1 && any(lev) && !any(bare) &&
        any(grepl("@emlAugmentNum: \"\\.hat\"", b)))
}

# THE WHITELIST. emlVocabAugment$ in eml-result-writer.praat is walked by
# @eml_orderedCols, and a column not in it is dropped from the file with no
# error anywhere. `.hat` was already reserved there and merely never emitted,
# which is the only reason section 2 did not need a change in a file this
# work does not own. Asserted rather than assumed, because the next quantity
# added to an augment frame will not be so lucky.
rw <- file.path(plug, "stats", "eml-result-writer.praat")
if (file.exists(rw)) {
    r <- readLines(rw, warn = FALSE)
    vocab <- grep("^emlVocabAugment\\$\\s*=", r, value = TRUE)
    check_true("v57", "the augment vocabulary is a single declaration",
               length(vocab) == 1)
    check_true("v57",
               "and it admits .std.resid and .hat, which the ANOVA frames emit",
               length(vocab) == 1 && grepl("\\.std\\.resid", vocab[1]) &&
               grepl("\\.hat", vocab[1]))
}

# ---------------------------------------------------------------------------
# 3. A REFUSAL MAY ONLY CLAIM WHAT IT MEASURED
# ---------------------------------------------------------------------------
# r1_incomplete_cases.csv has eight rows and four complete cases. The D97
# diagnosis is arithmetically right about those four and says "every subject".
# It must now say which four, in the words describe already uses.
rm1 <- rf("rm_incomplete", "error")
check_true("v57", "the RM path still refuses a zero residual",
           !is.na(rm1) && nzchar(rm1))
check_true("v57", "and still names the zero error term as the cause",
           !is.na(rm1) && grepl("residual is zero", rm1, fixed = TRUE))
check_true("v57",
           "and now discloses that it was assessed on the complete cases only",
           !is.na(rm1) && grepl("Assessed on 4 of 8 rows", rm1, fixed = TRUE))
check_true("v57", "and counts the exclusion in describe's own words",
           !is.na(rm1) && grepl("N excluded 4", rm1, fixed = TRUE) &&
           grepl("Treated as missing data", rm1, fixed = TRUE))
check_true("v57", "and names the columns the rows were lost in",
           !is.na(rm1) && grepl("SPL_medium", rm1, fixed = TRUE) &&
           grepl("SPL_loud", rm1, fixed = TRUE))

# The extractor's own refusal, which is the one Friedman reaches: "Need at
# least 2 complete-case subjects" over a four-row table reads as a data
# shortage the user does not have.
thin <- rf("rm_thin", "error")
check_true("v57", "the complete-case shortage refusal discloses the exclusion",
           !is.na(thin) && grepl("Need at least 2 complete-case", thin,
                                 fixed = TRUE) &&
           grepl("N excluded 3", thin, fixed = TRUE))

# THE OTHER DIRECTION, and this is the check that makes the three above mean
# something. r3_zero_variance.csv is complete. Its refusal must carry no
# exclusion note at all: a disclosure printed unconditionally discloses
# nothing and trains a reader to skip it.
rmc <- rf("rm_complete", "error")
check_true("v57", "a complete table still refuses when the data are degenerate",
           !is.na(rmc) && nzchar(rmc))
check_true("v57",
           "and says nothing about exclusions, because there were none",
           !is.na(rmc) && !grepl("N excluded", rmc, fixed = TRUE) &&
           !grepl("Assessed on", rmc, fixed = TRUE))

# 3b. THE DOMINANCE, READ OUT OF THE TREE -- NEW-G6-1's pin.
#
# Everything above reads harness/exportint/out/refusals.tsv, which records the
# sentences the orchestrators produced on the afternoon they were driven. The
# note EXISTED before this repair; what was missing was that the REFUSAL
# reached it -- it printed under the results, on a path the `goto` skips. Delete
# the disclosure out of the refusal arm today and the committed TSV still holds
# yesterday's sentence, so the checks above cannot see it.
#
# The claim is therefore positional and is asserted as one: once the
# complete-case count is known, EVERY refusal exit carries the disclosure.
# Before it is known there is nothing to disclose -- "Need at least 2 condition
# columns" is refused before a row has been read -- so the population is the
# exits BELOW the line that computes .nExcluded, which is what makes this a
# dominance check rather than a grep for a procedure name.
.discl <- function(proc, lab, marker) {
    b <- .ana_body(ana_code, proc)
    if (!length(b)) {
        check_true("v57", sprintf("@%s was read for its refusal exits", proc), FALSE)
        return(invisible(NULL))
    }
    from <- grep(marker, b)
    gotos <- grep(paste0("^goto ", lab, "$"), b)
    gotos <- gotos[gotos > (if (length(from)) from[1] else Inf)]
    ok <- vapply(gotos, function(i) {
        w <- b[max(1, i - 14):i]
        any(grepl("@eml_completeCaseDisclosure:", w, fixed = TRUE))
    }, logical(1))
    check_true("v57",
        sprintf("@%s: every refusal exit taken AFTER the complete-case count is known discloses the exclusion (%d of %d)",
                proc, sum(ok), length(gotos)),
        length(gotos) >= 1 && all(ok))
}
.discl("emlExtractConditionMatrix", "END_EXTRACT_COND",
       "^\\.nExcluded = \\.nRows - \\.nComplete$")
.discl("emlRunRepeatedMeasuresAnalysis", "END_RM",
       "^\\.nExcluded = emlExtractConditionMatrix\\.nExcluded$")
# FRIEDMAN REFUSES ONLY BY HANDING THE EXTRACTOR'S SENTENCE ON, and that is
# why it has no exit of its own in the population above. Asserted rather than
# left to be inferred from an empty list: a Friedman arm that composed its own
# refusal text would be disclosing nothing and would satisfy a check that only
# counted exits.
.fr <- .ana_body(ana_code, "emlRunFriedmanAnalysis")
check_true("v57",
    "@emlRunFriedmanAnalysis refuses by passing the extractor's disclosed sentence through, not by composing its own",
    length(.fr) > 0 &&
    any(grepl("^\\.error\\$ = emlExtractConditionMatrix\\.error\\$$", .fr)) &&
    sum(grepl("^goto END_FRIED$", .fr)) ==
        sum(grepl("^\\.error\\$ = emlExtractConditionMatrix\\.error\\$$", .fr)))

# ---------------------------------------------------------------------------
# 4. A FAILED ANALYSIS IS A REFUSAL, NOT A RESULT
# ---------------------------------------------------------------------------
# The orchestrator's .error$ is what scripts/eml-compare-paired.praat forks
# on: empty means "Analysis complete" with Save, Draw and New; non-empty means
# @emlErrorDialog. On zero-variance data no test ran and .error$ was empty.
pz <- rf("paired_zerovar", "error")
check_true("v57",
           "paired zero-variance returns a refusal, so the wrapper cannot offer Save",
           !is.na(pz) && nzchar(pz))
# THE GOLD STANDARD'S CONTENT: which columns, what n, and the rule. Named
# individually so a failure says which of the three went missing.
check_true("v57", "the refusal names both columns",
           !is.na(pz) && grepl("SPL_soft", pz, fixed = TRUE) &&
           grepl("SPL_medium", pz, fixed = TRUE))
check_true("v57", "the refusal names the n it was decided on",
           !is.na(pz) && grepl("n = 6 complete pairs", pz, fixed = TRUE))
check_true("v57", "the refusal states the rule in the user's terms",
           !is.na(pz) && grepl("no variation in the differences", pz,
                               fixed = TRUE))
check_true("v57", "and carries each test's own reason, not a paraphrase",
           !is.na(pz) && grepl("zero variance", pz, fixed = TRUE) &&
           grepl("cannot perform test", pz, fixed = TRUE))
check_true("v57",
           "nothing was declared, so there is no half-analysis to export",
           identical(sh("paired_zerovar", "declared"), "0"))
# D97's rule, kept: zero variance is a property of the data, so there is no
# other EML menu entry to send the user to and the dialog must not invent one.
check_true("v57", "and it offers no remedy, because no other test would fit",
           identical(rf("paired_zerovar", "remedy"), ""))

# 4a. AND THE ORCHESTRATOR IS WHERE THAT COMES FROM -- NEW-G12-3's pin.
#
# The wrapper is the wrong half to assert on: eml-compare-paired.praat forked
# on a non-empty .error$ BEFORE this repair too, and 4b below passes on the
# pre-fix wrapper. What changed is the orchestrator. On zero-variance data
# every requested test declined, no test ran, and .error$ was left empty --
# so the wrapper's fork took the branch it was told to take and put "Analysis
# complete", with Save, Draw and New, over a refusal buried in the report.
# The gate that turns "no family produced a test" into a refusal exit is
# therefore read out of @emlRunPairedAnalysis, and so is the guard that stops
# a declaration being made on the way out.
.pa <- .ana_body(ana_code, "emlRunPairedAnalysis")
.gate <- grep("^if \\.ranSomething = 0$", .pa)
.gexit <- if (length(.gate)) {
    w <- .pa[.gate[1]:min(length(.pa), .gate[1] + 25)]
    any(grepl("^\\.error\\$ = \"No paired test could be run", w)) &&
    any(grepl("^goto END_PAIRED$", w))
} else FALSE
check_true("v57",
    "zero-variance paired data takes the orchestrator's REFUSAL exit, not the completion modal",
    length(.pa) > 0 && length(.gate) == 1 && isTRUE(.gexit) &&
    any(grepl("^\\.ranSomething = 0$", .pa)) &&
    any(grepl("^if \\.failParametric\\$ = \"\"$", .pa)) &&
    any(grepl("^if \\.failNonparametric\\$ = \"\"$", .pa)))
check_true("v57",
    "and nothing is declared on that exit, so there is no half-analysis for a Save to export",
    length(.pa) > 0 &&
    any(grepl("^if \\.error\\$ = \"\"$", .pa)) &&
    all(vapply(grep("^@emlDeclarePairedResult:", .pa), function(i)
        any(grepl("^if \\.error\\$ = \"\"$", .pa[max(1, i - 12):i])), logical(1))) &&
    length(grep("^@emlDeclarePairedResult:", .pa)) >= 1)

# Single-family mode refuses too. "both" is what every driver used, which is
# how the nested-if lesson of 6 August 2026 was learned in the first place.
pzp <- rf("paired_zerovar_param", "error")
check_true("v57", "the parametric-only run refuses on the same data",
           !is.na(pzp) && nzchar(pzp))
check_true("v57", "and does not blame the Wilcoxon test, which it never ran",
           !is.na(pzp) && !grepl("Wilcoxon", pzp, fixed = TRUE))

# THE OTHER DIRECTION. A healthy paired run must still complete, still
# declare, and still say nothing.
check_true("v57", "a healthy paired run does not refuse",
           identical(rf("paired_ok", "error"), ""))
check_true("v57", "and still declares a result to export",
           identical(sh("paired_ok", "declared"), "1"))
# The ANOVA legs are here for the same reason: they share the orchestrator
# shape the refusal was added to.
check_true("v57", "the one-way ANOVA leg ran clean", identical(rf("anova1", "error"), ""))
check_true("v57", "the two-way ANOVA leg ran clean", identical(rf("anova2", "error"), ""))

# 4b. AND THE WRAPPER STILL ROUTES IT THE GOLD-STANDARD WAY.
# Setting .error$ only helps if the caller forks on it and keeps the user's
# answers. Both are properties of scripts/eml-compare-paired.praat, which this
# work does not own, so they are read rather than assumed: if either is ever
# removed, the orchestrator's refusal would go somewhere else silently.
cp <- file.path(plug, "scripts", "eml-compare-paired.praat")
check_true("v57", "the paired wrapper was read", file.exists(cp))
if (file.exists(cp)) {
    p <- readLines(cp, warn = FALSE)
    pc <- p[!grepl("^\\s*[#;]", p)]
    i <- grep("emlRunPairedAnalysis\\.error\\$\\s*<>\\s*\"\"", pc)
    check_true("v57", "it forks on the orchestrator's refusal", length(i) >= 1)
    check_true("v57", "and hands it to the shared refusal dialog",
               length(i) >= 1 &&
               any(grepl("@emlErrorDialog: emlRunPairedAnalysis\\.error\\$",
                         pc[i[1]:min(length(pc), i[1] + 6)])))
    check_true("v57", "and keeps the user's column choices for Back (D93)",
               any(grepl("@emlKeepChoice:", pc)))
}

# ---------------------------------------------------------------------------
# COVERAGE
# ---------------------------------------------------------------------------
# Every case the drive recorded is claimed by some check in this file. The
# population is read off the artefact, never re-derived from the list the
# checks were built from -- otherwise the two sides cannot disagree.
if (drove) {
    present <- unique(c(shape$a, refus$a))
    accounted <- c("normsave", "normsave_one", "normsave_wizard2",
                   "anova1", "anova2",
                   "rm_incomplete", "rm_thin", "rm_complete",
                   "friedman_incomplete",
                   "paired_zerovar", "paired_zerovar_param", "paired_ok")
    eml_census("v57", "exportint drive case", present, accounted)
    eml_claim("v57", "exportint_out", present)
}

# friedman_incomplete is in the population and is asserted on here rather than
# above, because what it demonstrates is a NON-refusal: Friedman runs happily
# on the four complete cases, and its exclusion note is the one that already
# printed correctly, on the success path. It is the case that says section 3
# is about the refusal path specifically and not about missing data in
# general.
check_true("v57",
           "Friedman on the same incomplete table runs rather than refusing",
           identical(rf("friedman_incomplete", "error"), ""))

if (!exists("EML_SUITE")) {
    eml_report("v57 export integrity: the frame matches the press, the refusal matches the sample")
    eml_exit()
}
