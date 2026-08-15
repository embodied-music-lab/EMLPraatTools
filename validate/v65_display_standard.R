# ============================================================================
# v65_display_standard.R -- one numeric display standard, in the two files
#                           that had no door to it
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS FILE EXISTS. On 15 August 2026 the pairwise reporter, driven on
# three groups with identical means, printed
#
#     Comparison                t (df)              p (raw)    p (adj)    d
#     A vs B                    0 (6.00)            1.000      1.000      0
#
# and the Stats Wizard, previewing normality on a symmetric column and then
# on a strongly skewed one, printed
#
#     Skewness:     0.00000000000000005
#     Shapiro-Wilk: W = 0.5899, p = 0.00000000001
#
# AUTHOR RULING 6, 15 August 2026: statistics print at fixed four decimals, p
# prints in APA style, and full precision belongs to the CSV export -- the
# artefact a reader is meant to compute from. The report is for reading. No
# raw double may reach the Info window.
#
# NEITHER SYMPTOM IS A NUMERIC DEFECT, and that is why this is a display
# validator. A t of two identical means IS zero; a skewness of a symmetric
# column IS zero to within a few ulps; a Shapiro-Wilk p on that skewed column
# IS about 1e-11. Every one of those numbers was right before this change and
# is byte-for-byte the same after it. What was wrong was their WIDTH.
#
# THE MECHANISM, WHICH IS NOT THE LINES. Praat's fixed$ is not a
# fixed-precision formatter. It returns the LARGER of the precision it is
# given and however many decimals are needed to show one significant digit,
# and a bare "0" for an exact zero -- a minimum-significance formatter wearing
# a fixed-precision name. Measured on the binary under test in section 2a
# rather than quoted:
#
#     fixed$ (-1e-16, 4)  ->  "-0.0000000000000001"    17 decimals, not 4
#     fixed$ (0.0004,  2)  ->  "0.0004"                 4 decimals, not 2
#     fixed$ (0.6,     0)  ->  "0.6"                    1 decimal, not 0
#     fixed$ (0,       4)  ->  "0"                      0 decimals, not 4
#
# The measurement and the repair are v64_display_and_coercion.R's -- a sibling
# change added @eml_fixed to stats/eml-output.praat and pinned that it is the
# only caller of fixed$ left in THAT module. v64 owns the formatter and its
# case grid; this file owns the two files the formatter had not reached:
# scripts/eml-wizard.praat and stats/eml-analysis.praat. There is no second
# implementation of the rounding anywhere and this file asserts that there
# never is one.
#
# THE ESCAPE IS ONE LINE PER STATISTIC THAT CAN SIT NEAR ZERO, which in a
# post-hoc table is most of them at once: t, Cohen's d, U, rank-biserial r,
# Scheffe's F, a mean difference, a group mean, an epsilon, a partial eta
# squared, Kendall's W. Fixing the two reported lines would have left the
# mechanism, and the next reader with two similar groups would have reported
# it again from a different cell.
#
# WHAT COULD NOT HAVE CAUGHT IT, AND WHY.
#
#   - THE NUMERIC VALIDATORS. v01, v02, v03, v04 and v18 recompute every one
#     of these statistics in R and compare against the printed value with
#     `check(reported, computed, tol)`. `as.numeric("0")` is 0 and
#     `as.numeric("0.000")` is 0, so both spellings of the defect and the
#     repair are the same number to every one of them. A validator that
#     PARSES before it compares cannot see a width. That is not a gap in
#     those files -- it is what they are for, and v01/v02/v18 were green
#     across this change in both directions.
#
#   - THE PLUGIN'S OWN ORACLED SUITES. dev/tests/phase2 checks the pairwise
#     family against R and scipy references to six decimals, through
#     @emlTestAssertNear, which takes numbers. Same blindness, same reason.
#
#   - v57_export_integrity.R AND EVERY CSV CHECK. They read the exported
#     files, where full precision is not merely permitted but required. "The
#     CSV carries seventeen digits" and "the report carries four" are opposite
#     assertions over two artefacts; only the second one is here, and section
#     5 asserts the first one deliberately so that a future repair cannot
#     satisfy this file by rounding the data instead of the display.
#
#   - v64_display_and_coercion.R, WHICH IS THE CLOSEST THING TO A PREDECESSOR.
#     Its live drive covers the Describe, two-group and normality reports and
#     its static census covers stats/eml-output.praat. The pairwise family,
#     the repeated-measures and Friedman reporters and the whole of the
#     wizard are outside all of it: v64's own sweep on two identical groups
#     drives @emlRunTwoGroupAnalysis, which is a different orchestrator from
#     @emlRunPairwiseAnalysis and prints no matrix at all. The reported
#     symptom was found by a live drive of a wrapper nothing had driven.
#
#   - ANY RED PATH. Nothing fails. No error, no warning, no refusal, no
#     modal. The wrapper opens, runs, prints, offers to save, and exports a
#     correct CSV. The only symptom is a reader's eye on a column that does
#     not line up -- and the number that fails to line up is a zero, which is
#     the one result a reader most wants to recognise at a glance.
#
#   - A GOLDEN-FILE DIFF. It would have shown the strings, and the leak was
#     ALREADY IN the committed evidence when this was written:
#     harness/normality/out/info/g03_severe_wizard.txt carries
#     "Shapiro-Wilk: W = 0.7465, p = 0.000000008" and
#     g02_largen_wizard.txt carries "p = 0.00003", both from a line that asked
#     for four decimals. No validator read those files. A golden file only
#     ever says "this changed"; it cannot say "this was always wrong", which
#     is the whole argument for asserting the SHAPE rather than freezing the
#     bytes.
#
# THE TRAP THIS FILE IS BUILT AROUND: THE FIX-SHAPED FIX. The cheapest way to
# make every width check above pass is to make @eml_fixed return a zero of the
# right width for everything. "0.000" in every cell satisfies "exactly three
# decimals", satisfies "no line carries more than four decimals", satisfies
# "no bare zero", and is catastrophically wrong. So section 4 drives the SAME
# reports over WELL SEPARATED groups and a real repeated-measures effect and
# compares the printed numbers against R, and section 5 asserts that the CSV
# still carries more precision than the report. A break that clamps to zero
# goes red in section 4; a break that rounds the DATA to satisfy section 4
# goes red in section 5. Neither check is worth much alone.
#
# NOTHING HERE IS VALIDATED UNTIL IT HAS BEEN BROKEN. Thirty-one deliberate
# breaks were built as COPIES of the plugin tree and run through $EML_PLUGIN_DIR
# on 15 August 2026; every one of them turned this file red, and between them
# they turn 98 of its 99 checks red at least once. Grouped by what they prove:
#
#   THE DEFECT ITSELF -- both files reverted to HEAD (24 red), the wizard only
#   (8), the analysis module only (16). The split matters: it shows that no
#   check is passing because some other file happens to be right.
#
#   THE MECHANISM RATHER THAN THE TEXT -- @eml_fixed reduced to a pass-through
#   to fixed$ (16 red) with every call site left in place, which is the defect
#   back with the repair's shape intact. And the reverse: a raw fixed$ added to
#   a NEW report line (1 red, the census), one sweep-matrix cell reverted (2),
#   the wizard's skewness line alone (3), the wizard's p alone (5), the group
#   descriptives alone (2). Per-cell resolution: reverting the d matrix leaves
#   the per-pair table green, and the failure says which one.
#
#   THE FIX-SHAPED FIX, which is the trap this file is built around. @eml_fixed
#   made to return a zero of the right width for every input passes every
#   single width assertion in section 3 -- and goes red twelve times in section
#   4, on the group means, the SDs, Cohen's d, Welch's t, the repeated-measures
#   F and the ordinary skewness. A weak version of this file would have shipped
#   green over it.
#
#   THE OTHER FIX-SHAPED FIX -- every CSV writer rounded to four decimals to
#   "match" the report (3 red in section 5). This one cost a revision: the
#   first draft asserted that some exported field carried five or more
#   decimals, and the break PASSED it, because a p-value of 3.4e-05 is one
#   fixed$ refused to round. The check is now a round-trip against R.
#
#   AND THE REPAIR THAT DELETES THE PROBLEM -- @emlFormatP's exact tail
#   removed, i.e. "fixing" NEW-G5-2 by putting back D28/D35 (1 red).
#
#   THE GUARDS. Over-wide formatting by one decimal (47 red) and by six (50),
#   which is what proves the well-separated tables are load-bearing rather than
#   decorative; a reporter that prints nothing (10); the RM and Friedman paths
#   refusing (18); the wizard's preview truncated (8); a per-pair row dropped
#   (6); either source file removed (2 each); a probe that cannot parse (1); a
#   skewness forced to exact zero and a Shapiro-Wilk p forced to .5, which turn
#   the "the case is real" guards red and are the reason those guards exist; a
#   second @eml_fixed defined locally in each file (2 each); the recorder's
#   variable renamed so the census classifier matches nothing (2); the exporter
#   writing nothing (2); effect.size dropped from the tidy frame (2).
#
# ONE CHECK IN THIS FILE CANNOT BE BROKEN BY EDITING THE TREE, and it is worth
# naming: "Praat's fixed$ still ignores the precision it is given near zero".
# Its subject is the BINARY, not the plugin. It goes red on the day a future
# Praat fixes fixed$ itself -- which is the event it exists to announce, and at
# that point everything below it becomes belt and braces rather than
# load-bearing. That is a fact worth having stated rather than discovered.
#
# A break also found a defect in this file: truncating @wizardNormDiag left a
# report line absent, `check` was handed a zero-length value, and R aborted
# mid-run. A validator that dies instead of failing has reported nothing. The
# `one()` helper below is that repair.
#
#     Rscript validate/v65_display_standard.R
#
# NOT A MEMBER of validate/run_all.R's list -- that file is not this change's
# to edit, and v65 launches Praat. Run it directly, and run it on any change
# to a report line, a formatter, or a post-hoc reporter.
#
# Input: the plugin source, driven live. $EML_PLUGIN_DIR overrides the tree
#        under test, which is how the break battery in this file's header
#        note was run. $PRAAT overrides the binary.
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

# ---------------------------------------------------------------------------
# 0. THE BINARY -- same floor and the same refusal as harness/_env.sh and v64
# ---------------------------------------------------------------------------
praat <- Sys.getenv("PRAAT", unset = "")
if (!nzchar(praat)) {
    for (cand in c(repo_path("..", "praat"), Sys.which("praat_barren"),
                   Sys.which("praat"))) {
        if (nzchar(cand) && file.exists(cand)) { praat <- cand; break }
    }
}
pv <- NA_character_
pvnum <- 0
if (nzchar(praat) && file.exists(praat)) {
    pv <- suppressWarnings(system2(praat, "--version", stdout = TRUE,
                                   stderr = TRUE))[1]
    m <- regmatches(pv, regexpr("[0-9]+\\.[0-9]+\\.[0-9]+", pv))
    if (length(m)) {
        p <- as.integer(strsplit(m, ".", fixed = TRUE)[[1]])
        pvnum <- p[1] * 1000 + p[2] * 100 + p[3]
    }
}
canDrive <- pvnum >= 6630

srcWiz <- file.path(plug, "scripts", "eml-wizard.praat")
srcAna <- file.path(plug, "stats", "eml-analysis.praat")

# ---------------------------------------------------------------------------
# 1. THE STATIC CENSUS -- one door, and a named list of what is not behind it
# ---------------------------------------------------------------------------
# A convention is what this defect already was: sixty-eight call sites across
# two files, every one written by somebody who believed fixed$ meant fixed. So
# the shape of the repair is itself worth pinning -- not "the d cell is
# routed" but "nothing that PRINTS in these files calls fixed$". A report line
# added next month inherits the fix by having nowhere else to go.
#
# STATEMENTS, NOT LINES. Praat continues a statement with a leading `...`, and
# most of the report lines in eml-analysis.praat are four-line concatenations,
# so a line-based census would mis-attribute half of them to whatever
# continuation they happen to sit on. The lines are joined back into logical
# statements first, and the statement's HEAD is what classifies it.
#
# Comment and semicolon lines are excluded because both files discuss this
# file's own subject at length in their prose, and a census that counts prose
# is a census that moves when somebody edits a comment. That is v63's rule for
# its door count and v64's for its own, and it is here for the same reason.
praat_statements <- function(path) {
    ln <- readLines(path, warn = FALSE)
    keep <- !grepl("^\\s*[#;]", ln)
    out <- character(0)
    starts <- integer(0)
    for (i in seq_along(ln)) {
        if (!keep[i]) next
        if (grepl("^\\s*\\.\\.\\.", ln[i]) && length(out)) {
            out[length(out)] <- paste(out[length(out)],
                                      sub("^\\s*\\.\\.\\.", "", ln[i]))
        } else {
            out <- c(out, ln[i])
            starts <- c(starts, i)
        }
    }
    list(text = out, line = starts)
}

check_true("v65", "scripts/eml-wizard.praat is present", file.exists(srcWiz))
check_true("v65", "stats/eml-analysis.praat is present", file.exists(srcAna))

if (file.exists(srcWiz)) {
    st <- praat_statements(srcWiz)
    hit <- grep("fixed\\$\\s*\\(", st$text)
    # THE WIZARD IS ABSOLUTE. Every number it prints is a report line -- it
    # writes no CSV of its own and builds no recorder string -- so there is no
    # class of statement in this file that is entitled to a raw fixed$, and
    # the count is the check.
    if (length(hit)) {
        cat("      NOTE v65: raw fixed$ in eml-wizard.praat at:\n")
        for (k in hit) cat(sprintf("            %d: %s\n", st$line[k],
                                   trimws(st$text[k])))
    }
    check_true("v65",
               sprintf("eml-wizard.praat calls fixed$ nowhere (%d site(s))",
                       length(hit)),
               length(hit) == 0)
    # AND IT REACHES THE SHARED FORMATTER, because "no fixed$" is also true of
    # a file that has stopped printing numbers.
    st2 <- praat_statements(srcWiz)
    check_true("v65",
               "eml-wizard.praat formats through the shared @eml_fixed",
               any(grepl("@eml_fixed:", st2$text)))
    check_true("v65",
               "and prints its Shapiro-Wilk p through @emlFormatP (APA)",
               any(grepl("@emlFormatP:\\s*emlShapiroWilk\\.p", st2$text)))
    # NO SECOND IMPLEMENTATION. The repair is one procedure in one module; a
    # local copy of the rounding here would pass every width check in this
    # file and be the next thing to drift.
    check_true("v65",
               "and defines no formatter of its own",
               !any(grepl("^\\s*procedure\\s+eml_fixed\\b", st2$text)))
}

if (file.exists(srcAna)) {
    st <- praat_statements(srcAna)
    hit <- grep("fixed\\$\\s*\\(", st$text)
    # THE ANALYSIS MODULE IS NOT ABSOLUTE, and saying why is the point of this
    # block. Ruling 6 governs the INFO WINDOW. eml-analysis.praat also builds
    # strings for two other artefacts, and both are outside it:
    #
    #   RECORDER  `.recResult$ = ...` and `@emlRecordResult: ...` compose the
    #             one-line result summary the session recorder writes into the
    #             emitted .praat script as a comment. It never reaches the
    #             Info window -- verified: stats/eml-record.praat's only
    #             appendInfoLine calls are the save-path messages, and the
    #             result column is read by the renderer, not printed. It is
    #             also the surface a sibling change owns. Flooring a p there
    #             would be a straight loss: unlike the report, that line has
    #             no APA p and no companion CSV beside it.
    #
    #   EXPORT    @emlRMAnovaTest's .warning$ quotes the Greenhouse-Geisser
    #             lower bound inside a caution SENTENCE, and that same string
    #             is exported verbatim to the glance frame by @emlGlanceStr.
    #             Reformatting it would edit an exported value, which this
    #             change is forbidden to do.
    #
    #   ALPHA     @emlReportAlpha renders the significance CRITERION, not a
    #             statistic, and its escalation is deliberate and commented:
    #             three decimals so .001 survives. Forcing it to the house
    #             width would print an alpha of .0001 as "0.00", and a reader
    #             could no longer tell what the asterisks were marked
    #             against. Left as it is, by judgement, and named here so the
    #             judgement is visible rather than an oversight.
    #
    # So the assertion is not a count. It is that every surviving fixed$ is in
    # one of those three classes -- which goes red the moment somebody writes
    # a new appendInfoLine with a fixed$ in it.
    isRecorder <- grepl("(^|\\s)\\.recResult\\$\\s*=", st$text) |
                  grepl("@emlRecordResult:", st$text)
    isWarning  <- grepl("(^|\\s)\\.warning\\$\\s*=", st$text)
    isAlpha    <- grepl("(^|\\s)\\.text\\$\\s*=\\s*fixed\\$\\s*\\(\\s*\\.value\\s*,",
                        st$text)
    allowed <- isRecorder | isWarning | isAlpha
    stray <- hit[!allowed[hit]]
    if (length(stray)) {
        cat("      NOTE v65: fixed$ outside the recorder/export/alpha classes:\n")
        for (k in stray) cat(sprintf("            %d: %s\n", st$line[k],
                                     trimws(st$text[k])))
    }
    check_true("v65",
               sprintf("every fixed$ left in eml-analysis.praat is a recorder, export or alpha string (%d total, %d stray)",
                       length(hit), length(stray)),
               length(stray) == 0)
    # THE POPULATION IS NOT EMPTY, which is the check that stops the one above
    # from passing because a regex stopped matching anything.
    check_true("v65",
               sprintf("the census found the sites it classifies (%d recorder, %d export, %d alpha)",
                       sum(isRecorder[hit]), sum(isWarning[hit]),
                       sum(isAlpha[hit])),
               length(hit) >= 18 && sum(isRecorder[hit]) >= 15 &&
               sum(isWarning[hit]) == 2 && sum(isAlpha[hit]) == 1)
    # AND THE REPORTERS DO REACH THE FORMATTER. Same reason as the wizard's.
    check_true("v65",
               "the pairwise reporter formats through @eml_fixed",
               any(grepl("@eml_fixed:\\s*\\.dVal", st$text)) &&
               any(grepl("@eml_fixed:\\s*\\.tVal", st$text)))
    check_true("v65",
               "eml-analysis.praat defines no formatter of its own",
               !any(grepl("^\\s*procedure\\s+eml_fixed\\b", st$text)))
}

# ---------------------------------------------------------------------------
# 2. THE LIVE DRIVE
# ---------------------------------------------------------------------------
decs <- function(s) ifelse(grepl("\\.", s), nchar(sub("^.*\\.", "", s)), 0L)

# one -- a scalar or NA, never a zero-length vector. `check` builds a
# data.frame row and dies on a zero-length argument, so a report line that is
# ABSENT would abort this file instead of failing a check -- which is the one
# outcome a validator may not have. Found by the break that truncates
# @wizardNormDiag: the value under test simply was not there.
one <- function(x) if (length(x) == 1) suppressWarnings(as.numeric(x)) else NA_real_

# THE APA EXACT TAIL, AND WHY IT IS CARVED OUT RATHER THAN ASSERTED.
#
# @emlReportPWithExact and @emlInlineP print a floored p and then append the
# unrounded value in parentheses, so a repeated-measures line reads
#
#     F(2, 10) = 101.6667, p < .001  (2.2631138563155704e-07)
#
# That tail is `string$ (.pValue)` -- seventeen significant digits of raw
# double, in the Info window, which is precisely what ruling 6 forbids and
# precisely what audit finding NEW-G5-2 describes. It is REAL and it is NOT
# THIS CHANGE'S TO REPAIR: the string is built at
# plugin/stats/eml-output.praat:746, in @emlFormatP, a file another change
# owns. Section 3d measures it, names the repair and attests it, on
# v64_display_and_coercion.R's precedent for a finding whose fix lives
# elsewhere. Stripping it here rather than ignoring the whole line keeps the
# REST of every such line under the four-decimal rule -- the F beside it was
# `fixed$ (.fStat, 4)` until this change and would otherwise have been able to
# hide behind the carve-out.
#
# The pattern is anchored on the APA floor labels, so it cannot swallow an
# ordinary parenthesis: "(6.00)" after a t, "(2, 9)" after a Scheffe F and
# "(0 = no agreement, 1 = identical rankings)" are all untouched.
stripExact <- function(lines) {
    gsub("(< \\.001|> \\.999)\\s+\\([^)]*\\)", "\\1", lines)
}

# toolong -- v64's rule, restated here because both files need it and neither
# should reach into the other. Four decimals is the house MAXIMUM: counts
# print at 0, statistics at 4, and nothing is entitled to more.
toolong <- function(lines) {
    lines <- stripExact(lines)
    m <- regmatches(lines, gregexpr("[0-9]+\\.[0-9]+", lines))
    bad <- character(0)
    for (i in seq_along(m)) {
        d <- nchar(sub("^.*\\.", "", m[[i]]))
        if (length(d) && any(d > 4)) bad <- c(bad, trimws(lines[i]))
    }
    bad
}

if (!canDrive) {
    cat(sprintf(paste0("      NOTE v65: LIVE EVIDENCE MISSING.\n",
                       "            Praat here is %s; the plugin floors at 6.6.30\n",
                       "            (plugin/setup.praat), and a drive below the floor\n",
                       "            is not evidence -- least of all for this file,\n",
                       "            whose subject is one binary's formatter.\n",
                       "            Static checks above still hold.\n"),
                if (is.na(pv)) "not found" else pv))
    check_true("v65",
               sprintf("a Praat at or above the plugin's floor is available (found %s)",
                       if (is.na(pv)) "none" else pv),
               FALSE)
} else {
    work <- file.path(tempdir(), "v65")
    unlink(work, recursive = TRUE)
    dir.create(file.path(work, "scripts"), showWarnings = FALSE, recursive = TRUE)
    dir.create(file.path(work, "out"), showWarnings = FALSE, recursive = TRUE)
    prefs <- file.path(work, "prefs")
    dir.create(prefs, showWarnings = FALSE)
    # A stale lock from a crashed run makes the next Praat refuse to start, and
    # a refusal at startup reads here as a report that printed nothing. Only
    # these two files, and only in this scratch folder.
    unlink(file.path(prefs, c("pid", "message")))

    # THE SANDBOX IS SYMLINKS, as v63's and v64's are: Praat resolves a
    # relative include against the TOP-LEVEL script's folder, and a validator
    # that writes its scratch into the tree it is measuring has started
    # changing that tree.
    for (d in c("stats", "graphs")) {
        tgt <- file.path(work, d)
        if (!file.exists(tgt)) file.symlink(normalizePath(file.path(plug, d)), tgt)
    }
    # REACHING THE SHIPPING WIZARD. eml-wizard.praat is a top-level script,
    # not a library: its body starts at `emlShowExplanations = 1` and runs
    # into a `beginPause:`, which hard-crashes under `praat --run`. The `goto`
    # in the probe jumps the body; Praat resolves `@name` by scanning the
    # whole script text for `procedure name`, so every procedure the file
    # defines stays callable from after the label. That is exactly
    # harness/normality/case.praat's route, and it is used here for the same
    # reason it is used there: the alternative is transcribing @wizardNormDiag
    # into the harness, and a transcription passes every check in this file on
    # the day somebody reverts the shipping one.
    file.symlink(normalizePath(srcWiz),
                 file.path(work, "scripts", "eml-wizard.praat"))
    # The wizard's own `include eml-lib-lmm.praat` resolves against the
    # TOP-LEVEL script's folder -- work/scripts -- and is answered by this
    # deliberate stub. The probe has already included the stats layer by
    # explicit relative path; including the real loader here would re-enter
    # every module a second time. NOTHING may be defined in it: a procedure
    # here would shadow the plugin, which is the class of defect this file
    # exists to catch.
    writeLines(c("# v65: deliberate stub. See harness/normality/eml-lib-lmm.praat.",
                 "# Nothing may be defined here."),
               file.path(work, "scripts", "eml-lib-lmm.praat"))

    probe <- file.path(work, "scripts", "v65-probe.praat")
    writeLines(c(
        'include ../stats/eml-core-utilities.praat',
        'include ../stats/eml-core-descriptive.praat',
        'include ../stats/eml-extract.praat',
        'include ../stats/eml-output.praat',
        'include ../stats/eml-inferential.praat',
        'include ../stats/eml-result-writer.praat',
        'include ../stats/eml-analysis.praat',
        'include ../graphs/eml-graph-procedures.praat',
        'include ../graphs/eml-annotation-procedures.praat',
        'include ../graphs/eml-draw-procedures.praat',
        '',
        'goto V65_DRIVER',
        'include eml-wizard.praat',
        'label V65_DRIVER',
        '',
        'outDir$ = "../out"',
        '; Alphabetical group order, so group i here is group i in R.',
        'emlGroupSortAlphabetical = 1',
        '',
        'procedure cap: .kind$, .name$',
        '    .txt$ = info$ ()',
        '    writeInfoLine: "v65"',
        '    appendInfoLine: .kind$, "|BEGIN|", .name$',
        '    appendInfo: .txt$',
        '    appendInfoLine: .kind$, "|END|", .name$',
        'endproc',
        '',
        '# --- 2a. PRAAT S OWN fixed$, MEASURED ON THIS BINARY ---------------',
        '# The premise of the whole file, driven rather than remembered. If a',
        '# future Praat fixes this itself these lines say so, and the repair',
        '# becomes belt and braces rather than load-bearing.',
        'writeInfoLine: "v65"',
        'appendInfoLine: "raw|tiny4|", fixed$ (-1e-16, 4)',
        'appendInfoLine: "raw|small2|", fixed$ (0.0004, 2)',
        'appendInfoLine: "raw|sixth0|", fixed$ (0.6, 0)',
        'appendInfoLine: "raw|zero4|", fixed$ (0, 4)',
        '',
        '# --- 2b. THE WIZARD S OWN REPORT LINES ------------------------------',
        '# @wizardNormDiag is the preview the wizard prints before it',
        '# recommends parametric or nonparametric. Three vectors: a symmetric',
        '# one whose skewness is a genuine zero a few ulps off zero, a',
        '# strongly skewed one whose Shapiro-Wilk p is far below the APA',
        '# floor, and an ordinary one that must be untouched by all of this.',
        'sym# = zero# (11)',
        'for i from 1 to 11',
        '    sym# [i] = i - 6',
        'endfor',
        'clearinfo',
        '@wizardNormDiag: sym#, "symmetric"',
        '@cap: "wiz", "symmetric"',
        '; Recomputed HERE rather than read off the wizard s own call, so that',
        '; the guard cannot be satisfied -- or destroyed -- by a change inside',
        '; @wizardNormDiag. The guard is about the DATA, not about the caller.',
        '@emlSkewness: sym#',
        'appendInfoLine: "under|sym_skew|", string$ (emlSkewness.result)',
        '',
        'sev# = zero# (60)',
        'for i from 1 to 60',
        '    sev# [i] = (i / 60) ^ 8 * 100',
        'endfor',
        'clearinfo',
        '@wizardNormDiag: sev#, "severe"',
        '@cap: "wiz", "severe"',
        '@emlShapiroWilk: sev#',
        'appendInfoLine: "under|sev_p|", string$ (emlShapiroWilk.p)',
        '',
        'ord# = {2, 3, 5, 6, 8, 9, 11, 14, 15, 19, 21, 26}',
        'clearinfo',
        '@wizardNormDiag: ord#, "ordinary"',
        '@cap: "wiz", "ordinary"',
        '@emlSkewness: ord#',
        'appendInfoLine: "under|ord_skew|", string$ (emlSkewness.result)',
        '@emlShapiroWilk: ord#',
        'appendInfoLine: "under|ord_p|", string$ (emlShapiroWilk.p)',
        '',
        '# --- 2c. THE PAIRWISE FAMILY ON THREE IDENTICAL GROUPS -------------',
        '# The reported case. t, Cohen s d, U, rank-biserial r, Scheffe s F',
        '# and every mean difference are zero at once, which is where fixed$',
        '# returns a bare "0" into a three-decimal column.',
        'Create Table with column names: "v65flat", 12, "grp val"',
        'flatId = selected ("Table")',
        'for r from 1 to 12',
        '    if r <= 4',
        '        Set string value: r, "grp", "A"',
        '        Set numeric value: r, "val", r',
        '    elsif r <= 8',
        '        Set string value: r, "grp", "B"',
        '        Set numeric value: r, "val", r - 4',
        '    else',
        '        Set string value: r, "grp", "C"',
        '        Set numeric value: r, "val", r - 8',
        '    endif',
        'endfor',
        'for t$ from 1 to 1',
        'endfor',
        'clearinfo',
        '@emlRunPairwiseAnalysis: flatId, "val", "grp", "welch", "bonferroni"',
        '@cap: "flat", "welch"',
        'clearinfo',
        '@emlRunPairwiseAnalysis: flatId, "val", "grp", "wilcoxon", "bonferroni"',
        '@cap: "flat", "wilcoxon"',
        'clearinfo',
        '@emlRunPairwiseAnalysis: flatId, "val", "grp", "scheffe", "none"',
        '@cap: "flat", "scheffe"',
        '',
        '# --- 2d. THE SAME REPORTS ON WELL SEPARATED GROUPS -----------------',
        '# THE ANTI-CLAMP CONTROL. A formatter that returns a zero of the',
        '# right width for everything passes every width check above. These',
        '# three reports carry no zero anywhere, and section 4 compares their',
        '# numbers against R.',
        'Create Table with column names: "v65sep", 12, "grp val"',
        'sepId = selected ("Table")',
        'for r from 1 to 12',
        '    if r <= 4',
        '        Set string value: r, "grp", "A"',
        '        Set numeric value: r, "val", r',
        '    elsif r <= 8',
        '        Set string value: r, "grp", "B"',
        '        Set numeric value: r, "val", r + 6',
        '    else',
        '        Set string value: r, "grp", "C"',
        '        Set numeric value: r, "val", r + 12',
        '    endif',
        'endfor',
        'clearinfo',
        '@emlRunPairwiseAnalysis: sepId, "val", "grp", "welch", "bonferroni"',
        '@cap: "sep", "welch"',
        'clearinfo',
        '@emlRunPairwiseAnalysis: sepId, "val", "grp", "wilcoxon", "bonferroni"',
        '@cap: "sep", "wilcoxon"',
        'clearinfo',
        '@emlRunPairwiseAnalysis: sepId, "val", "grp", "scheffe", "none"',
        '@cap: "sep", "scheffe"',
        '',
        '# --- 2d2. GROUPS WHOSE MEANS ARE EXACTLY ZERO ----------------------',
        '# The descriptives block is its own pair of call sites and its own',
        '# column, and a group mean of zero is not exotic: centred data,',
        '# residuals and difference scores all produce it.',
        'Create Table with column names: "v65zero", 12, "grp val"',
        'zeroId = selected ("Table")',
        'for r from 1 to 12',
        '    if r <= 4',
        '        Set string value: r, "grp", "A"',
        '        Set numeric value: r, "val", r - 2.5',
        '    elsif r <= 8',
        '        Set string value: r, "grp", "B"',
        '        Set numeric value: r, "val", r - 6.5',
        '    else',
        '        Set string value: r, "grp", "C"',
        '        Set numeric value: r, "val", r - 10.5',
        '    endif',
        'endfor',
        'clearinfo',
        '@emlRunPairwiseAnalysis: zeroId, "val", "grp", "welch", "bonferroni"',
        '@cap: "zero", "welch"',
        '',
        '# --- 2e. REPEATED MEASURES AND FRIEDMAN ----------------------------',
        '# Equal condition means with real within-subject variation: F, the',
        '# partial eta squared, the chi-square and Kendall s W are all zero',
        '# and the design is NOT degenerate, so the reporters run rather than',
        '# refuse. Then the same two on a real effect, as the control.',
        'Create Table with column names: "v65rm", 6, "Subject c1 c2 c3"',
        'rmFlatId = selected ("Table")',
        'for r from 1 to 6',
        '    Set string value: r, "Subject", "S" + string$ (r)',
        '    Set numeric value: r, "c1", r',
        '    Set numeric value: r, "c2", r + (-1) ^ r',
        '    Set numeric value: r, "c3", r - (-1) ^ r',
        'endfor',
        'clearinfo',
        '@emlRunRepeatedMeasuresAnalysis: rmFlatId, "Subject", "c1|c2|c3", 0, "holm"',
        '@cap: "rm", "flat"',
        'clearinfo',
        '@emlRunFriedmanAnalysis: rmFlatId, "Subject", "c1|c2|c3", 0, "holm"',
        '@cap: "fr", "flat"',
        '',
        'Create Table with column names: "v65rme", 6, "Subject c1 c2 c3"',
        'rmEffId = selected ("Table")',
        'for r from 1 to 6',
        '    Set string value: r, "Subject", "S" + string$ (r)',
        '    Set numeric value: r, "c1", r',
        '    Set numeric value: r, "c2", r + 4 + (-1) ^ r',
        '    Set numeric value: r, "c3", r + 9 - (-1) ^ r',
        'endfor',
        'clearinfo',
        '@emlRunRepeatedMeasuresAnalysis: rmEffId, "Subject", "c1|c2|c3", 0, "holm"',
        '@cap: "rm", "effect"',
        'clearinfo',
        '@emlRunFriedmanAnalysis: rmEffId, "Subject", "c1|c2|c3", 0, "holm"',
        '@cap: "fr", "effect"',
        '',
        '# --- 2f. THE EXPORT, WHICH IS WHERE FULL PRECISION LIVES -----------',
        '# Driven last so it cannot disturb a capture. The tidy frame from the',
        '# separated table is read back off disk in section 5.',
        'clearinfo',
        '@emlRunPairwiseAnalysis: sepId, "val", "grp", "welch", "bonferroni"',
        '@emlExportResultFiles: outDir$, "v65_sep"',
        'writeInfoLine: "v65"',
        'appendInfoLine: "export|written|", emlExportResultFiles.nWritten',
        '',
        'removeObject: flatId',
        'removeObject: sepId',
        'removeObject: zeroId',
        'removeObject: rmFlatId',
        'removeObject: rmEffId'), probe)

    outTxt <- suppressWarnings(system2("env",
        c("-u", "DISPLAY", shQuote(praat),
          shQuote(paste0("--pref-dir=", prefs)), "--run", shQuote(probe)),
        stdout = TRUE, stderr = TRUE))

    got <- function(tag, field) {
        p <- sprintf("^%s\\|%s\\|", tag, field)
        sub(p, "", grep(p, outTxt, value = TRUE))
    }
    block <- function(kind, name) {
        b <- grep(sprintf("^%s\\|BEGIN\\|%s$", kind, name), outTxt)
        e <- grep(sprintf("^%s\\|END\\|%s$", kind, name), outTxt)
        if (!length(b) || !length(e)) return(character(0))
        if (e[1] - b[1] < 2) return(character(0))
        outTxt[(b[1] + 1):(e[1] - 1)]
    }
    ran <- !any(grepl("^Error", outTxt)) && length(got("raw", "tiny4")) == 1
    if (!ran) cat(sprintf("      v65 probe output: %s\n",
                          paste(utils::tail(outTxt, 10), collapse = " / ")))
    check_true("v65", "the display probe ran", ran)

if (ran) {
    # -- 2a. THE PREMISE IS TRUE OF THIS BINARY -----------------------------
    raw <- c(tiny4 = got("raw", "tiny4"), small2 = got("raw", "small2"),
             sixth0 = got("raw", "sixth0"), zero4 = got("raw", "zero4"))
    check_true("v65",
               sprintf("Praat's fixed$ still ignores the precision it is given near zero (%s)",
                       paste(sprintf("%s=%s", names(raw), raw), collapse = " ")),
               decs(raw[["tiny4"]]) > 4 && decs(raw[["small2"]]) > 2 &&
               decs(raw[["sixth0"]]) > 0 && decs(raw[["zero4"]]) < 4)

    # ---------------------------------------------------------------------
    # 3. THE TWO REPORTED SYMPTOMS, NAMED
    # ---------------------------------------------------------------------
    # These are the lines the ruling was written over. They are asserted one
    # at a time and by name, so a failure says WHICH surface leaked rather
    # than "a report was too wide somewhere".

    # -- 3a. THE WIZARD ----------------------------------------------------
    wsym <- block("wiz", "symmetric")
    check_true("v65", sprintf("the wizard's symmetric preview was captured (%d lines)",
                              length(wsym)),
               length(wsym) >= 4)
    skewLine <- grep("^\\s*Skewness:", wsym, value = TRUE)
    skewVal <- trimws(sub("^\\s*Skewness:\\s*", "", skewLine))
    under <- got("under", "sym_skew")
    # THE CASE IS A REAL ONE. Without this the check below is satisfied by a
    # column whose skewness happens to be exactly zero, and it would prove
    # nothing about the formatter.
    check_true("v65",
               sprintf("the case is real: the underlying skewness is a non-zero double (%s)",
                       paste(under, collapse = "")),
               length(under) == 1 &&
               !is.na(suppressWarnings(as.numeric(under))) &&
               as.numeric(under) != 0)
    check_true("v65",
               sprintf("the wizard's Skewness line prints at exactly three decimals (%s)",
                       paste(skewVal, collapse = "|")),
               length(skewVal) == 1 && grepl("^-?[0-9]+\\.[0-9]{3}$", skewVal))
    check_true("v65",
               sprintf("and it is the zero it should be, with no minus sign in front of nothing (%s)",
                       paste(skewVal, collapse = "|")),
               identical(skewVal, "0.000"))

    wsev <- block("wiz", "severe")
    swLine <- grep("Shapiro-Wilk: W =", wsev, value = TRUE)
    sevP <- got("under", "sev_p")
    check_true("v65",
               sprintf("the case is real: the underlying Shapiro-Wilk p is far below the APA floor (%s)",
                       paste(sevP, collapse = "")),
               length(sevP) == 1 &&
               !is.na(suppressWarnings(as.numeric(sevP))) &&
               as.numeric(sevP) < 0.001 && as.numeric(sevP) > 0)
    # THE RULING'S SECOND CLAUSE: p prints in APA style. This line used to
    # read "p = 0.00000000001" -- eleven decimals from a call that asked for
    # four, and a raw double where the house form is "p < .001".
    check_true("v65",
               sprintf("the wizard's Shapiro-Wilk line prints p in APA style (%s)",
                       paste(trimws(swLine), collapse = "|")),
               length(swLine) == 1 && grepl("p < \\.001\\s*$", swLine))
    check_true("v65",
               sprintf("and its W is at exactly four decimals (%s)",
                       paste(trimws(swLine), collapse = "|")),
               length(swLine) == 1 &&
               grepl("W = -?[0-9]+\\.[0-9]{4},", swLine))

    # THE ORDINARY CASE IS UNCHANGED, which is half of what "keeps fixed$'s
    # answer when fixed$ honoured the request" means. A p of .27 must still
    # print as a number and not as a floor.
    word <- block("wiz", "ordinary")
    oskew <- trimws(sub("^\\s*Skewness:\\s*", "",
                        grep("^\\s*Skewness:", word, value = TRUE)))
    osw <- grep("Shapiro-Wilk: W =", word, value = TRUE)
    oskewU <- suppressWarnings(as.numeric(got("under", "ord_skew")))
    opU <- suppressWarnings(as.numeric(got("under", "ord_p")))
    check(     "v65", "an ordinary skewness still prints its own value",
               one(oskew), round(oskewU, 3), tol = 1e-9)
    check_true("v65",
               sprintf("an ordinary p prints as an APA number rather than a floor (%s)",
                       paste(trimws(osw), collapse = "|")),
               length(osw) == 1 && grepl("p = \\.[0-9]{3}\\s*$", osw))
    check(     "v65", "and it is the p that was computed",
               one(sub(".*p = ", "0", osw)), round(opU, 3), tol = 1e-9)

    # -- 3b. THE PAIRWISE TABLES -------------------------------------------
    # The reported line, cell by cell. `parsePairs` reads the per-pair block
    # of a report; `sweepCells` reads every off-diagonal cell of the matrices
    # underneath it. Both return the cells AS PRINTED -- no as.numeric
    # anywhere, because a width is what is under test.
    parsePairs <- function(rep) {
        i <- grep("Per-pair results", rep)
        if (!length(i)) return(character(0))
        j <- grep("^\\s*\\*", rep)
        j <- j[j > i[1]]
        if (!length(j)) return(character(0))
        rows <- rep[(i[1] + 1):(j[1] - 1)]
        rows <- rows[grepl(" vs ", rows)]
        rows
    }
    sweepCells <- function(rep, heading) {
        i <- grep(heading, rep)
        if (!length(i)) return(character(0))
        tail <- rep[(i[1] + 1):min(length(rep), i[1] + 12)]
        rows <- tail[grepl("^[A-Za-z]", tail)]
        cells <- unlist(strsplit(trimws(paste(rows, collapse = "  ")), "\\s\\s+"))
        cells <- cells[!cells %in% c("---", "A", "B", "C", "")]
        cells
    }

    # The three per-pair columns that were bare zeros, by test. The regex is
    # the COLUMN WIDTH the report's own header promises.
    pairSpec <- list(
        welch    = list(stat = "^-?[0-9]+\\.[0-9]{3} \\(-?[0-9]+\\.[0-9]{2}\\)$",
                        eff  = "^-?[0-9]+\\.[0-9]{3}$",
                        sweep = "Cohen's d \\(effect sizes\\)"),
        wilcoxon = list(stat = "^-?[0-9]+\\.[0-9]{2}$",
                        eff  = "^-?[0-9]+\\.[0-9]{3}$",
                        sweep = "Rank-biserial r \\(effect sizes\\)"),
        scheffe  = list(stat = "^-?[0-9]+\\.[0-9]{3} \\([0-9]+, [0-9]+\\)$",
                        eff  = "^-?[0-9]+\\.[0-9]{3}$",
                        sweep = "Mean Differences"))

    for (tbl in c("flat", "sep")) {
      for (tst in names(pairSpec)) {
        rep <- block(tbl, tst)
        check_true("v65",
                   sprintf("the %s/%s pairwise report was captured (%d lines)",
                           tbl, tst, length(rep)),
                   length(rep) > 20)
        if (!length(rep)) next
        rows <- parsePairs(rep)
        check_true("v65",
                   sprintf("the %s/%s per-pair table has its three rows (%d)",
                           tbl, tst, length(rows)),
                   length(rows) == 3)
        # Split each row on runs of two-or-more spaces: comparison, statistic,
        # p (raw), p (adj), effect. Scheffe prints one p, not two.
        okStat <- TRUE; okEff <- TRUE; badS <- character(0); badE <- character(0)
        for (r in rows) {
            f <- unlist(strsplit(trimws(r), "\\s\\s+"))
            if (length(f) < 4) { okStat <- FALSE; badS <- c(badS, trimws(r)); next }
            s <- f[2]; e <- f[length(f)]
            e <- sub("\\s*\\*$", "", e)
            if (!grepl(pairSpec[[tst]]$stat, s)) { okStat <- FALSE; badS <- c(badS, s) }
            if (!grepl(pairSpec[[tst]]$eff, e))  { okEff  <- FALSE; badE <- c(badE, e) }
        }
        check_true("v65",
                   sprintf("%s/%s: every test statistic cell is at its column's width (%s)",
                           tbl, tst,
                           if (okStat) "all three" else paste(badS, collapse = ",")),
                   okStat)
        check_true("v65",
                   sprintf("%s/%s: every effect-size cell is at its column's width (%s)",
                           tbl, tst,
                           if (okEff) "all three" else paste(badE, collapse = ",")),
                   okEff)
        # THE SWEEP MATRIX IS A SEPARATE SURFACE from the per-pair table and
        # was a separate call site. A matrix is read DOWN the column, so one
        # cell of a different width is worse here than anywhere else.
        cells <- sweepCells(rep, pairSpec[[tst]]$sweep)
        badC <- cells[!grepl("^-?[0-9]+\\.[0-9]{3}$", cells)]
        check_true("v65",
                   sprintf("%s/%s: every effect-size sweep cell is three decimals (%d cells, %d wrong: %s)",
                           tbl, tst, length(cells), length(badC),
                           paste(utils::head(badC, 4), collapse = ",")),
                   length(cells) == 6 && length(badC) == 0)
        # AND THE WHOLE REPORT. This is the assertion that would have caught
        # the defect wherever it surfaced first.
        bad <- toolong(rep)
        if (length(bad))
            cat(sprintf("      NOTE v65: %s/%s line(s) past four decimals:\n%s\n",
                        tbl, tst, paste("           ", bad, collapse = "\n")))
        check_true("v65",
                   sprintf("%s/%s: no report line carries more than four decimals (%d offender(s))",
                           tbl, tst, length(bad)),
                   length(bad) == 0)
      }
    }

    # -- 3b2. THE DESCRIPTIVES BLOCK, ON GROUPS CENTRED AT ZERO -----------
    # Its own two call sites and its own column. fixed$ (0, 4) is "0", so the
    # Mean column of centred data was a column of bare zeros beside a column
    # of "1.2910"-shaped SDs.
    zrep <- block("zero", "welch")
    check_true("v65", sprintf("the centred-groups report was captured (%d lines)",
                              length(zrep)),
               length(zrep) > 20)
    zd <- zrep[grepl("^\\s*[ABC]\\s+4\\s", zrep)]
    zmeans <- vapply(zd, function(r) {
        f <- unlist(strsplit(trimws(r), "\\s\\s+")); if (length(f) >= 3) f[3] else ""
    }, character(1))
    check_true("v65",
               sprintf("every group mean of exactly zero prints at four decimals (%s)",
                       paste(zmeans, collapse = ",")),
               length(zmeans) == 3 && all(zmeans == "0.0000"))
    zsds <- vapply(zd, function(r) {
        f <- unlist(strsplit(trimws(r), "\\s\\s+")); if (length(f) >= 4) f[4] else ""
    }, character(1))
    check_true("v65",
               sprintf("and the SD beside it is unchanged and its own value (%s)",
                       paste(zsds, collapse = ",")),
               length(zsds) == 3 && all(grepl("^[0-9]+\\.[0-9]{4}$", zsds)) &&
               all(zsds != "0.0000"))

    # -- 3c. REPEATED MEASURES AND FRIEDMAN --------------------------------
    rmSpec <- list(
        list(kind = "rm", pat = "F\\([0-9]+, [0-9]+\\) = (-?[0-9.]+),",
             what = "F"),
        list(kind = "rm", pat = "Greenhouse-Geisser epsilon = (-?[0-9.]+),",
             what = "Greenhouse-Geisser epsilon"),
        list(kind = "rm", pat = "Partial eta squared = (-?[0-9.]+)",
             what = "partial eta squared"),
        list(kind = "fr", pat = "chi-square\\([0-9]+\\) = (-?[0-9.]+),",
             what = "chi-square"),
        list(kind = "fr", pat = "Kendall's W = (-?[0-9.]+)",
             what = "Kendall's W"))
    for (case in c("flat", "effect")) {
        for (k in c("rm", "fr")) {
            rep <- block(k, case)
            check_true("v65",
                       sprintf("the %s/%s report was captured (%d lines)",
                               k, case, length(rep)),
                       length(rep) > 4)
            bad <- toolong(rep)
            if (length(bad))
                cat(sprintf("      NOTE v65: %s/%s line(s) past four decimals:\n%s\n",
                            k, case, paste("           ", bad, collapse = "\n")))
            check_true("v65",
                       sprintf("%s/%s: no report line carries more than four decimals (%d offender(s))",
                               k, case, length(bad)),
                       length(bad) == 0)
        }
        for (sp in rmSpec) {
            rep <- block(sp$kind, case)
            m <- regmatches(rep, regexpr(sp$pat, rep))
            v <- if (length(m)) sub(paste0(".*?", sp$pat, ".*"), "\\1", m[1]) else NA
            check_true("v65",
                       sprintf("%s/%s: %s prints at exactly four decimals (%s)",
                               sp$kind, case, sp$what,
                               if (is.na(v)) "not found" else v),
                       !is.na(v) && grepl("^-?[0-9]+\\.[0-9]{4}$", v))
        }
        # The rank sums are a one-decimal column of their own.
        fr <- block("fr", case)
        rs <- regmatches(fr, regexpr("rank sum = (-?[0-9.]+)", fr))
        rs <- sub("rank sum = ", "", rs)
        check_true("v65",
                   sprintf("fr/%s: every rank sum prints at one decimal (%s)",
                           case, paste(rs, collapse = ",")),
                   length(rs) == 3 && all(grepl("^-?[0-9]+\\.[0-9]$", rs)))
    }

    # -- 3d. NEW-G5-2, MEASURED --------------------------------------------
    # The one leak this change found and could not close. Every report driven
    # above is searched for the APA exact tail, and what it carries is
    # printed rather than asserted -- see the note above stripExact.
    allRep <- c(block("wiz", "symmetric"), block("wiz", "severe"),
                block("wiz", "ordinary"),
                unlist(lapply(c("flat", "sep"), function(t)
                    unlist(lapply(c("welch", "wilcoxon", "scheffe"),
                                  function(s) block(t, s))))),
                unlist(lapply(c("flat", "effect"), function(c)
                    c(block("rm", c), block("fr", c)))))
    tails <- unlist(regmatches(allRep,
                gregexpr("(< \\.001|> \\.999)\\s+\\([^)]*\\)", allRep)))
    tailDigits <- 0L
    if (length(tails)) {
        # Significant digits, so leading zeros do not inflate the count:
        # "0.00016430257817153237" is seventeen significant figures, not
        # twenty-one characters of them.
        mant <- gsub("[^0-9]", "", sub("[eE].*$", "", sub("^[^(]*\\(", "", tails)))
        tailDigits <- max(nchar(sub("^0+", "", mant)))
    }
    if (tailDigits > 5) {
        cat(sprintf(paste0(
            "      NOTE v65: NEW-G5-2 IS NOT REPAIRED, and not by this change.\n",
            "            %d report line(s) print a floored p and then the\n",
            "            UNROUNDED value in parentheses, at up to %d\n",
            "            significant digits -- a raw double in the Info\n",
            "            window, which is what ruling 6 forbids. Example:\n",
            "                %s\n",
            "            REPAIR, one line, and it is not in either file this\n",
            "            change owns:\n",
            "            plugin/stats/eml-output.praat:746 --\n",
            "                .exact$ = string$ (.pValue)\n",
            "            string$ is Praat's ROUND-TRIP renderer: it emits as\n",
            "            many digits as it takes to reconstruct the double,\n",
            "            which for a p just under the floor is seventeen. The\n",
            "            information D35 wanted from this tail is the ORDER OF\n",
            "            MAGNITUDE -- 5.8e-07 and 2.1e-13 must stop reading\n",
            "            alike -- and three significant figures carry all of\n",
            "            it. Anything that bounds the mantissa serves; what\n",
            "            must NOT happen is deleting the tail, which would put\n",
            "            back the D28/D35 defect the tail was added to fix.\n",
            "            Reached from the wizard: its repeated-measures,\n",
            "            Friedman, two-group and normality paths all print it.\n"),
            length(tails), tailDigits, trimws(grep(tails[1], allRep,
                fixed = TRUE, value = TRUE)[1])))
    }
    attest("v65",
           sprintf("NEW-G5-2 measured: %d APA exact tail(s) in the driven reports, longest mantissa %d significant digits",
                   length(tails), tailDigits),
           "driven live; the repair is plugin/stats/eml-output.praat:746 (@emlFormatP .exact$ = string$), out of scope for this change")
    # ASSERTED EITHER WAY, because the tail's PRESENCE is D28/D35's repair and
    # a later change must not satisfy the note above by deleting it: whenever
    # a p floors, the floored label is well formed and the tail is still there
    # to be read.
    # The ORCHESTRATOR reports only. The wizard's own Shapiro-Wilk preview
    # floors its p and deliberately prints no tail: it is a two-line
    # diagnostic whose only consequence is the binary recommendation printed
    # underneath it, and the same p is reported and exported in full by
    # @emlRunNormalityAnalysis. That is a decision of this change and it is
    # asserted separately in 3a, not folded in here where it would read as
    # the D28/D35 tail going missing.
    orchRep <- allRep[!allRep %in% c(block("wiz", "symmetric"),
                                     block("wiz", "severe"),
                                     block("wiz", "ordinary"))]
    floored <- grep("p (< \\.001|> \\.999)", orchRep, value = TRUE)
    check_true("v65",
               sprintf("every floored p in the orchestrator reports is labelled in APA form (%d line(s))",
                       length(floored)),
               length(floored) > 0)
    check_true("v65",
               sprintf("and each of them still carries the unrounded value beside it, D28/D35 (%d tail(s) for %d floor(s))",
                       length(tails), length(floored)),
               length(tails) == length(floored))

    # ---------------------------------------------------------------------
    # 4. THE ANTI-CLAMP: THE NUMBERS ARE STILL THE NUMBERS
    # ---------------------------------------------------------------------
    # Everything above asserts a WIDTH, and a formatter that returned a zero
    # of the right width for every input would pass all of it. This section is
    # the one that goes red on that break: the separated table's descriptives
    # and effect sizes are recomputed here from the same synthetic data and
    # compared against what the report printed.
    #
    # This is the one place in this file that asserts a VALUE, and it is here
    # for exactly one reason -- see the header's note on the fix-shaped fix.
    grp <- rep(c("A", "B", "C"), each = 4)
    val <- c(1:4, (5:8) + 6, (9:12) + 12)
    rep <- block("sep", "welch")
    dscr <- rep[grepl("^\\s*[ABC]\\s+4\\s", rep)]
    check_true("v65",
               sprintf("the separated report printed its three group descriptive rows (%d)",
                       length(dscr)),
               length(dscr) == 3)
    for (i in seq_along(c("A", "B", "C"))) {
        g <- c("A", "B", "C")[i]
        row <- dscr[grepl(paste0("^\\s*", g, "\\s"), dscr)]
        if (!length(row)) next
        f <- unlist(strsplit(trimws(row), "\\s\\s+"))
        check("v65", sprintf("group %s mean, as printed", g),
              one(f[3]), mean(val[grp == g]), tol = 5e-5)
        check("v65", sprintf("group %s SD, as printed", g),
              one(f[4]), sd(val[grp == g]), tol = 5e-5)
    }
    # Cohen's d for A vs B, pooled -- the cell that read "0" in the report the
    # ruling was written over, here on data where it is emphatically not zero.
    rows <- parsePairs(rep)
    ab <- rows[grepl("^\\s*A vs B", rows)]
    if (length(ab)) {
        f <- unlist(strsplit(trimws(ab[1]), "\\s\\s+"))
        dPrinted <- one(sub("\\s*\\*$", "", f[length(f)]))
        a <- val[grp == "A"]; b <- val[grp == "B"]
        sp <- sqrt(((length(a) - 1) * var(a) + (length(b) - 1) * var(b)) /
                   (length(a) + length(b) - 2))
        check("v65", "Cohen's d for A vs B, as printed",
              dPrinted, (mean(a) - mean(b)) / sp, tol = 5e-4)
        tPrinted <- one(sub(" .*", "", f[2]))
        tt <- t.test(a, b, var.equal = FALSE)
        check("v65", "Welch t for A vs B, as printed",
              tPrinted, unname(tt$statistic), tol = 5e-4)
    }
    # The repeated-measures effect case, same argument on a different reporter.
    rmRep <- block("rm", "effect")
    mF <- regmatches(rmRep, regexpr("F\\([0-9]+, [0-9]+\\) = (-?[0-9.]+),", rmRep))
    fPrinted <- one(sub(".*= ", "", sub(",$", "", mF[1])))
    # A PERFECTLY ADDITIVE EFFECT IS DEGENERATE -- zero error term, and the
    # reporter refuses rather than printing, which is D97 and correct. The
    # alternating term gives the design a real error variance so that there is
    # an F to print at all.
    y <- c(1:6, (1:6) + 4 + (-1)^(1:6), (1:6) + 9 - (-1)^(1:6))
    cond <- factor(rep(c("c1", "c2", "c3"), each = 6))
    subj <- factor(rep(1:6, 3))
    ssC <- sum(6 * (tapply(y, cond, mean) - mean(y))^2)
    ssS <- sum(3 * (tapply(y, subj, mean) - mean(y))^2)
    ssT <- sum((y - mean(y))^2)
    ssE <- ssT - ssC - ssS
    fR <- (ssC / 2) / (ssE / 10)
    check("v65", "repeated-measures F on a real effect, as printed",
          fPrinted, fR, tol = 5e-3)

    # ---------------------------------------------------------------------
    # 5. AND FULL PRECISION IS STILL IN THE CSV
    # ---------------------------------------------------------------------
    # The opposite assertion to everything above, over the other artefact.
    # The ruling relocates precision; it does not delete it. Without this
    # check the cheapest way to satisfy section 3 is to round the exported
    # numbers too, and the plugin would then have no artefact a reader could
    # compute from -- which is a worse defect than the one being fixed.
    nW <- got("export", "written")
    check_true("v65",
               sprintf("the separated pairwise analysis exported its files (%s written)",
                       paste(nW, collapse = "")),
               length(nW) == 1 && suppressWarnings(as.integer(nW)) >= 2)
    tidy <- file.path(work, "out", "v65_sep_tidy.csv")
    check_true("v65", sprintf("the tidy frame is on disk (%s)", basename(tidy)),
               file.exists(tidy))
    if (file.exists(tidy)) {
        td <- read.csv(tidy, stringsAsFactors = FALSE, check.names = FALSE)
        check_true("v65",
                   sprintf("the tidy frame carries the statistic and the effect size (%s)",
                           paste(names(td), collapse = ",")),
                   all(c("contrast", "statistic", "effect.size") %in% names(td)) &&
                   nrow(td) == 3)
        # THE ASSERTION IS ROUND-TRIP, NOT LENGTH, and the distinction cost a
        # break test. "some field in this file has five or more decimals" is
        # satisfied by a p-value of 3.4e-05 that fixed$ REFUSED to round -- the
        # very escalation this whole file is about -- so a break that rounds
        # every CSV writer to four decimals passed it. What the ruling
        # actually promises a reader is that the exported number reconstructs
        # the computed one, so that is what is checked: the exported Welch t
        # against R's, to a tolerance the report's three decimals could never
        # meet.
        a <- val[grp == "A"]; b <- val[grp == "B"]
        if ("A-B" %in% td$contrast) {
            r <- td[td$contrast == "A-B", ][1, ]
            check("v65", "the exported Welch t round-trips to full precision",
                  one(r$statistic),
                  unname(t.test(a, b, var.equal = FALSE)$statistic),
                  tol = 1e-9)
            spAB <- sqrt(((length(a) - 1) * var(a) + (length(b) - 1) * var(b)) /
                         (length(a) + length(b) - 2))
            check("v65", "and so does the exported Cohen's d",
                  one(r$effect.size),
                  (mean(a) - mean(b)) / spAB, tol = 1e-9)
            # Said the other way as well, because a round-trip check would
            # also pass if the exporter happened to print exactly the digits R
            # needs: the field as WRITTEN carries more than the report's width.
            asWritten <- readLines(tidy, warn = FALSE)
            stat <- sub(",.*$", "",
                        sub("^[^,]*,[^,]*,", "", grep("A-B", asWritten,
                                                      value = TRUE)[1]))
            check_true("v65",
                       sprintf("and the field as written is wider than any report cell (%s)",
                               stat),
                       decs(stat) > 4)
        }
    }
}
}

if (!exists("EML_SUITE")) {
    eml_report("v65 display standard: the wizard and the post-hoc reporters")
    eml_exit()
}
