# ============================================================================
# v70_p_precision.R -- the exact p tail is three significant figures, and the
#                      significance criterion is not a statistic
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS FILE EXISTS. On 15 August 2026 the wizard's repeated-measures path,
# driven on twenty singers over three SPL conditions, printed
#
#     F(2, 38) = 583.1232, p < .001  (3.0359635874099574e-29)
#
# Seventeen significant digits of raw double in the Info window, on a line
# whose entire job was to say "about 3e-29". The same tail turned up in the
# Friedman line beside it, in the normality reports, in the Kruskal-Wallis
# block and anywhere else a p fell under the APA floor -- twenty-nine
# committed artefacts carried one when this was written, the longest of them
# at seventeen significant figures.
#
# THE TAIL IS NOT THE DEFECT AND MUST NOT BE DELETED, and half of this file
# exists to make that impossible to forget. The APA rendering floors at .001,
# so 5.8e-07, 2.1e-13 and 3.0e-04 all print "p < .001": nine orders of
# magnitude flattened into one string, which is audit findings D28 and D35 and
# which is why @emlFormatP grew a .exact$ output in the first place. Deleting
# the parenthesis makes every width assertion in this file pass and puts D35
# straight back. v65_display_standard.R already asserts the tail is still
# there beside every floored label; this file asserts something stronger --
# that the three D35 values still print three DIFFERENT tails, in the right
# order, each within a fraction of a percent of the p it stands for.
#
# AUTHOR RULING A, 16 August 2026: the tail stays, bounded to three
# significant figures. Three figures carry the whole of what D35 wanted out of
# it -- the order of magnitude -- and carry nothing else.
#
# THE MECHANISM, MEASURED ON 6.6.30 RATHER THAN ASSUMED. The line was
# `.exact$ = string$ (.pValue)` at plugin/stats/eml-output.praat:746, and
# string$ is Praat's ROUND-TRIP renderer: it emits however many digits it
# takes to reconstruct the double exactly. Section 2a drives it on this binary
# rather than quoting it. So the tail's width was never a property of the
# repeated-measures path, or of the wizard, or of that F -- it was a property
# of every p that fell under the floor, and repairing the reported line would
# have left the next reader to report it from somewhere else.
#
# PRAAT HAS NO printf, AND THE OBVIOUS SUBSTITUTE IS THE DEFECT AGAIN. fixed$
# and @eml_fixed give a fixed number of DECIMAL PLACES, and the answer to
# "3e-29 at four decimals" is 0.0000 -- the tail collapsed to zero, nine
# orders of magnitude flattened onto ONE order, which is D35 with the repair's
# name on it. Significant figures and decimal places are different quantities
# and the sub-.001 range is where the difference is the entire point. The
# repair is @eml_sig3 in the same module: floor(log10 |v|) for the exponent,
# the mantissa scaled by that power of ten and rounded to two decimals, and
# the mantissa re-emitted through @eml_fixed so it is two decimals wide even
# when it rounds to a whole number. Section 2b holds all of that as VALUES,
# not as widths, for the reason in the next paragraph but one.
#
# AUTHOR RULING B, 16 August 2026: @emlReportAlpha STAYS AS IT IS. It formats
# the significance CRITERION with a bare fixed$ (.value, 3) and trims trailing
# zeros, which looks exactly like the fixed$ escape @eml_fixed was written to
# close and is not one. Route alpha through @eml_fixed and an alpha of .0001
# prints as "0.000" -- the threshold the report says it marked significance
# against, rendered as zero, which is the one value no threshold can have.
# Section 4 measures that counterfactual on the binary and then asserts the
# four alphas that matter, so a future display sweep that "finishes the job"
# by routing the last holdout in goes RED rather than quiet. A statistic is a
# measurement of the data whose trailing digits are arithmetic noise; a
# criterion is a number the reader chose, and quoting it back at less
# precision than it was set with is not tidying, it is misreporting.
#
# THE TRAP THIS FILE IS BUILT AROUND: THE FIX-SHAPED FIX. The cheapest way to
# satisfy "three significant figures" everywhere is to return a constant of
# the right shape -- "0.00e+00" for every input, or the one string this
# file's example uses. That passes every width assertion, every "the mantissa
# is one digit, a point and two digits" assertion, and every "the tail is
# still present" assertion, and it is D35 restored in full. So every string
# this file pins is ALSO parsed back to a number and compared against the p it
# came from, the D35 trio is asserted DISTINCT and ORDERED both at the
# renderer and at the procedure a report actually calls, and 216 values
# spanning 1e-4 to the smallest subnormal double are compared against glibc's
# %.2e in R -- a genuinely independent correctly-rounded implementation, not a
# second copy of the thing under test. A break that clamps goes red on the
# values; a break that hard-codes the example goes red on the distinctness; a
# break that gets the value right and the width wrong goes red on the
# strings.
#
# WHAT COULD NOT HAVE CAUGHT IT, AND WHY.
#
#   - v03 AND v04, WHICH READ THIS EXACT NUMBER. They assert the printed p
#     against R at tol = 5e-30 and 5e-26, tolerances chosen in August
#     precisely so that a plugin flooring this p to zero could not pass. They
#     are the strictest numeric checks in the suite on this line and they are
#     blind to the whole defect, because `as.numeric` of a seventeen-digit
#     string and `as.numeric` of a three-digit one are the same number to
#     nine decimal places past where either tolerance sits. A validator that
#     PARSES before it compares cannot see a width. That is not a gap in
#     those files, it is what they are for.
#
#   - v65_display_standard.R, WHICH FOUND IT. Its section 3d MEASURES this
#     tail, prints how many significant digits it carries, names the repair by
#     file and line number and attests rather than asserts, because the repair
#     was in a file that change did not own. An attestation is evidence, not a
#     test: v65 goes green whether the tail is seventeen digits or three. Its
#     `stripExact` helper then removes the parenthesis before applying the
#     four-decimal rule, so the tail is the one string in the report that the
#     house width standard explicitly does not reach. This file is what that
#     carve-out was waiting for.
#
#   - v64_display_and_coercion.R, WHICH OWNS THE FORMATTER. Its census asserts
#     that @eml_fixed is the only caller of fixed$ left in this module and its
#     case grid pins thirteen widths. `string$` is not `fixed$`; the tail
#     never went through @eml_fixed at all, so the one-door census counted it
#     as compliant by never looking at it. Section 1 of this file adds the
#     matching assertion for the second renderer -- and asserts that @eml_sig3
#     itself calls no bare fixed$, so v64's door stays a door.
#
#   - EVERY CSV AND EXPORT CHECK. v16, v46, v50 and v57 read the exported
#     files, where full precision is not merely allowed but required, and
#     v65's section 5 asserts it deliberately so that nobody can satisfy a
#     display rule by rounding the data. "The CSV carries seventeen digits"
#     and "the report carries three" are opposite assertions over two
#     artefacts and only the second one is here.
#
#   - A GOLDEN-FILE DIFF. The leak was ALREADY IN the committed evidence when
#     this was written -- harness/normality/out/info/g03_severe_analysis.txt
#     carried "< .001  (7.834095677750921e-09)" and twenty-eight other
#     artefacts carried one like it. A golden file only ever says "this
#     changed"; it cannot say "this was always wrong", which is the whole
#     argument for asserting the shape and the value rather than freezing the
#     bytes.
#
#   - ANY RED PATH. Nothing fails. No error, no warning, no refusal. The
#     report prints, the CSV exports, the suite is green, and the only symptom
#     is a line no human can read at the exact point where the plugin was
#     trying hardest to be informative.
#
# NOTHING HERE IS VALIDATED UNTIL IT HAS BEEN BROKEN. Twenty-six deliberate
# breaks were built as COPIES of the plugin tree and driven through
# $EML_PLUGIN_DIR on 16 August 2026, and every one of them turned this file
# red. Between them they turn 67 of its 70 checks red at least once; the three
# that no break reaches are named at the bottom of this list, and the reason
# is worth reading. Grouped by what they prove:
#
#   THE DEFECT ITSELF -- eml-output.praat reverted to HEAD, and @eml_sig3
#   replaced by string$ with everything else left standing. The second is the
#   more useful of the two: the revert makes the probe fail to compile, so it
#   is caught by the static census and proves nothing about the live drive,
#   while the string$ substitution runs clean and goes red on twenty-one
#   checks including every string in the grid and the sixteen-character bound.
#
#   THE D35 REGRESSION -- the tail deleted outright (.exact$ = ""), the tail
#   replaced by a constant "3.04e-29", and the row printer stripped of the
#   line that appends the parenthesis. The first is the change a future
#   display sweep is most likely to make and the second is the fix-shaped fix;
#   they go red on presence and on distinctness respectively, and NEITHER of
#   them goes red on any width assertion, which is the point of having both.
#
#   THE NAIVE SUBSTITUTE -- @eml_fixed at four decimals in place of @eml_sig3.
#   This is the instructive one. The renderer is untouched and perfect, every
#   width holds, the tail is present and non-empty on every floored p -- and
#   5.8e-07 and 2.1e-13 both arrive at the report as "0.0000", nine orders of
#   magnitude flattened one layer further out than anything section 2 looks
#   at. Only the call-site D35 check and the composed lines catch it, and it
#   is why they exist as well as the renderer-level ones.
#
#   THE ARITHMETIC, ONE PROPERTY AT A TIME -- truncation in place of rounding,
#   the two-step scaling collapsed to a single divide, the mantissa carry
#   dropped, the exponent zero-padding dropped, the mantissa cut to one
#   significant figure, and the whole formatter clamped to "0.00e+00". The
#   scaling break is the subtle one: it is invisible above 1e-150 and returns
#   "--undefined--" at 4.94e-324, so only the subnormal cases in the grid and
#   the tail of the sweep catch it.
#
#   THE APA LABELS, WHICH THIS CHANGE MUST NOT HAVE MOVED -- the floors
#   respelled "p < 0.001", the ordinary branch cut to two decimals, the
#   undefined text changed, a tail attached to every p and a tail attached to
#   an undefined p. The statistics are correct everywhere they are tested and
#   only the tail's width was ever in question, so these five say so.
#
#   RULING B -- @emlReportAlpha routed through @eml_fixed at three decimals
#   and at four, the criterion's VALUE rounded rather than its text, at two
#   decimals and at one, and the procedure renamed. The two routings print an
#   alpha of .0001 as a zero; the value roundings move the number @emlSigMark
#   compares against, which is the version of this mistake that changes what
#   the report MARKS and not merely what it says.
#
#   THE NON-VACUITY GUARDS THEMSELVES -- each module deleted in turn and each
#   procedure renamed, so the four "this was located" checks that make the
#   rest of the census non-vacuous are themselves shown to be falsifiable
#   rather than decorative.
#
#   AND A NO-OP -- an untouched copy of the tree driven through the same
#   override, green at 70 of 70, so a red result from the twenty-five above is
#   a red result about the break and not about the sandbox.
#
#   THE THREE THAT NO BREAK REACHES are section 2a's two measurements of
#   Praat's own renderers and section 2d's measurement of what a single divide
#   does in the subnormal range. They are not assertions about the plugin and
#   no patch to the plugin can move them: they are the PREMISE, and they go
#   red if and only if a future Praat changes underneath this file -- which is
#   the day the repair stops being load-bearing and somebody should be told.
#
# Input: the plugin source, driven live. $EML_PLUGIN_DIR overrides the tree
#        under test, for break tests. $PRAAT overrides the binary.
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
# 0. THE BINARY -- the same floor and the same refusal as v64 and harness/_env.sh
# ---------------------------------------------------------------------------
# A green suite on an unsupported build is not evidence, and least of all for
# this file: its subject is one binary's number-to-string renderers.
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

srcOut <- file.path(plug, "stats", "eml-output.praat")
srcAna <- file.path(plug, "stats", "eml-analysis.praat")

# ---------------------------------------------------------------------------
# 1. THE STATIC CENSUS -- read from CODE, never from PROSE
# ---------------------------------------------------------------------------
# Comment and semicolon lines are stripped before anything is matched, and
# that is not tidiness. @eml_sig3's own header quotes the defective line
# `.exact$ = string$ (.pValue)` in full, twice, because the header's job is to
# explain what was wrong -- so a census that read the whole file would find
# the defect present in a correctly repaired module and absent in a module
# whose comments had been deleted. A check that matches the COMMENT EXPLAINING
# THE FIX rather than the fix is green for the wrong reason in both
# directions. This is v63's and v64's rule and it is here for the same reason.
check_true("v70", "stats/eml-output.praat is present", file.exists(srcOut))

if (file.exists(srcOut)) {
    out  <- readLines(srcOut, warn = FALSE)
    code <- out[!grepl("^\\s*[#;]", out)]

    # The body of @emlFormatP, isolated, so nothing below can be satisfied by
    # a line somewhere else in a 3600-line module.
    b0 <- grep("^procedure emlFormatP: ", code)
    b1 <- if (length(b0)) grep("^endproc", code)[grep("^endproc", code) > b0[1]][1]
          else NA_integer_
    fpBody <- if (length(b0) == 1 && !is.na(b1)) code[b0[1]:b1] else character(0)

    # NON-VACUITY FIRST. Every assertion below is of the form "this body does
    # not contain X", and an empty body contains nothing. If the extraction
    # failed -- renamed procedure, changed indentation, a stray endproc -- the
    # rest of section 1 would pass by finding nothing to look at, which is
    # the shape of a check that CAN ONLY PASS. So the body is asserted to
    # exist and to be about what it is supposed to be about before it is
    # asserted to be free of anything.
    check_true("v70",
               sprintf("@emlFormatP's body was located and is about .exact$ (%d code lines)",
                       length(fpBody)),
               length(fpBody) > 5 && any(grepl(".exact$", fpBody, fixed = TRUE)))

    check_true("v70",
               "@eml_sig3 is where the significant-figure renderer lives",
               any(grepl("^procedure eml_sig3: ", code)))

    check_true("v70",
               "@emlFormatP no longer builds the exact tail with string$ (D28/D35 tail, NEW-G5-2)",
               length(fpBody) > 5 &&
               !any(grepl("string\\$\\s*\\(\\s*\\.pValue\\s*\\)", fpBody)))

    nSig <- sum(grepl("@eml_sig3:", fpBody))
    check_true("v70",
               sprintf("and builds it through @eml_sig3 instead, on both floors (%d call site(s))",
                       nSig),
               nSig == 2 && any(grepl("eml_sig3.result$", fpBody, fixed = TRUE)))

    # THE TAIL IS STILL THERE. This is the D28/D35 assertion, and it is the
    # one a change that "cleans up the display" is most likely to break: both
    # floor branches must still ASSIGN something to .exact$, and the empty
    # assignment must appear exactly once -- on the ordinary-p branch, where a
    # tail would be redundant, and nowhere else.
    emptyAssign <- sum(grepl('^\\s*\\.exact\\$\\s*=\\s*""\\s*$', fpBody))
    check_true("v70",
               sprintf("the exact tail is assigned empty on exactly the two branches entitled to it -- an undefined p and an ordinary one (%d)",
                       emptyAssign),
               emptyAssign == 2)

    # AND THE ROW PRINTER STILL PRINTS IT. The census above would hold if
    # @emlReportPWithExact had stopped appending the parenthesis, which is
    # D28/D35 restored one call site further out.
    r0 <- grep("^procedure emlReportPWithExact: ", code)
    r1 <- if (length(r0)) grep("^endproc", code)[grep("^endproc", code) > r0[1]][1]
          else NA_integer_
    rpBody <- if (length(r0) == 1 && !is.na(r1)) code[r0[1]:r1] else character(0)
    check_true("v70",
               "@emlReportPWithExact still appends the tail in parentheses",
               length(rpBody) > 3 &&
               any(grepl('.exact$', rpBody, fixed = TRUE)) &&
               any(grepl('"  ("', rpBody, fixed = TRUE)))

    # v64's DOOR STAYS A DOOR. @eml_sig3 rounds and formats, so the lazy way
    # to write it is a bare fixed$ on the mantissa -- which would make it the
    # fifteenth caller of fixed$ in a module whose whole repair was that there
    # is only one.
    s0 <- grep("^procedure eml_sig3: ", code)
    s1 <- if (length(s0)) grep("^endproc", code)[grep("^endproc", code) > s0[1]][1]
          else NA_integer_
    sigBody <- if (length(s0) == 1 && !is.na(s1)) code[s0[1]:s1] else character(0)
    check_true("v70",
               sprintf("@eml_sig3 formats through @eml_fixed and calls no bare fixed$ (%d body lines)",
                       length(sigBody)),
               length(sigBody) > 10 &&
               any(grepl("@eml_fixed:", sigBody, fixed = TRUE)) &&
               !any(grepl("fixed\\$\\s*\\(", sigBody)))
}

# ---------------------------------------------------------------------------
# 1b. RULING B, STATICALLY -- alpha is exempt, and the exemption is intact
# ---------------------------------------------------------------------------
# @emlReportAlpha lives in stats/eml-analysis.praat, which this change does
# not own. What is asserted here is only that the exemption has not been
# swept away: the criterion is still formatted with its own fixed$ and is NOT
# routed through @eml_fixed. Section 4 drives the consequence.
check_true("v70", "stats/eml-analysis.praat is present", file.exists(srcAna))

if (file.exists(srcAna)) {
    ana  <- readLines(srcAna, warn = FALSE)
    acode <- ana[!grepl("^\\s*[#;]", ana)]
    # Anchored at the END of the line as well as the start. @emlReportAlpha
    # takes no arguments, so its declaration is the whole line -- and an
    # unanchored prefix match would happily accept a procedure called
    # emlReportAlphaX, which is exactly what a rename-and-replace refactor
    # leaves behind. A census that matches the successor of the thing it is
    # guarding has stopped guarding it.
    a0 <- grep("^procedure emlReportAlpha\\s*$", acode)
    a1 <- if (length(a0)) grep("^endproc", acode)[grep("^endproc", acode) > a0[1]][1]
          else NA_integer_
    alBody <- if (length(a0) == 1 && !is.na(a1)) acode[a0[1]:a1] else character(0)

    check_true("v70",
               sprintf("@emlReportAlpha's body was located (%d code lines)",
                       length(alBody)),
               length(alBody) > 5 && any(grepl(".text$", alBody, fixed = TRUE)))
    check_true("v70",
               "AUTHOR RULING B: the significance criterion is NOT routed through @eml_fixed",
               length(alBody) > 5 && !any(grepl("@eml_fixed", alBody, fixed = TRUE)))
    check_true("v70",
               "and it still escalates precision rather than capping, so .0001 is not printed as a zero",
               length(alBody) > 5 &&
               any(grepl("fixed\\$\\s*\\(\\s*\\.value\\s*,\\s*3\\s*\\)", alBody)))
}

# ---------------------------------------------------------------------------
# 2. THE LIVE DRIVE
# ---------------------------------------------------------------------------
# The sweep values and their expectations, built here so the probe and the
# comparison cannot drift apart. glibc's %.2e is the oracle: it is a
# correctly-rounded implementation written by somebody else, which is what an
# oracle has to be -- re-deriving the mantissa in R with the same floor/log10
# recipe the plugin uses would be a second copy of the thing under test and
# the two would agree about any shared misunderstanding.
sci3 <- function(v) {
    ifelse(v == 0, "0", {
        s <- sprintf("%.2e", v)
        mm <- sub("e.*$", "", s)
        ee <- suppressWarnings(as.integer(sub("^.*e", "", s)))
        sprintf("%s%s%s%s", mm, "e", ifelse(ee < 0, "-", "+"),
                formatC(abs(ee), width = 2, flag = "0"))
    })
}

set.seed(70)
sweepVals <- c(10^seq(-4, -300, by = -2),
               runif(60, 1, 10) * 10^sample(-300:-4, 60, replace = TRUE),
               3.0359635874099574e-29, 2.4630000000000001e-25,
               5.8e-07, 2.1e-13, 3.0e-04, 1e-320, 4.9406564584124654e-324)
sweepVals <- sweepVals[is.finite(sweepVals) & sweepVals > 0]

if (!canDrive) {
    cat(sprintf(paste0("      NOTE v70: LIVE EVIDENCE MISSING.\n",
                       "            Praat here is %s; the plugin floors at 6.6.30\n",
                       "            (plugin/setup.praat). This file's subject is one\n",
                       "            binary's number-to-string renderers, so a drive\n",
                       "            below the floor is not evidence about it.\n",
                       "            Static checks above still hold.\n"),
                if (is.na(pv)) "not found" else pv))
    check_true("v70",
               sprintf("a Praat at or above the plugin's floor is available (found %s)",
                       if (is.na(pv)) "none" else pv),
               FALSE)
} else {
    work <- file.path(tempdir(), "v70")
    unlink(work, recursive = TRUE)
    dir.create(file.path(work, "scripts"), showWarnings = FALSE, recursive = TRUE)
    prefs <- file.path(work, "prefs")
    dir.create(prefs, showWarnings = FALSE)
    # A stale lock from a crashed run makes the next Praat refuse to start,
    # and a refusal at startup reads here as a probe that printed nothing.
    # Only these two files, and only in this scratch folder.
    unlink(file.path(prefs, c("pid", "message")))

    # THE SANDBOX IS SYMLINKS, as v63's and v64's are: Praat resolves a
    # relative include against the TOP-LEVEL script's folder, so a validator
    # that writes its probe into the tree it is measuring has started changing
    # that tree.
    for (d in c("stats", "graphs")) {
        tgt <- file.path(work, d)
        if (!file.exists(tgt)) file.symlink(normalizePath(file.path(plug, d)), tgt)
    }
    for (f in list.files(file.path(plug, "scripts"), pattern = "^eml-lib.*\\.praat$")) {
        tgt <- file.path(work, "scripts", f)
        if (!file.exists(tgt))
            file.symlink(normalizePath(file.path(plug, "scripts", f)), tgt)
    }

    # %.17g, so Praat parses the same double R is holding. A literal written
    # at fewer digits is a DIFFERENT number and the comparison below would be
    # measuring the transcription.
    lit <- function(v) sprintf("%.17g", v)

    probe <- file.path(work, "scripts", "v70-probe.praat")
    writeLines(c(
        'include eml-lib.praat',
        '',
        '# --- 2a. PRAAT\'S OWN RENDERERS, MEASURED ON THIS BINARY -----------',
        '# The premise of the whole file, driven rather than remembered. If a',
        '# future Praat bounds string$ itself, these lines say so and the',
        '# repair becomes belt and braces rather than load-bearing.',
        'v70p = fisherQ (583.1232, 2, 38)',
        'writeInfoLine: "v70 probe"',
        'appendInfoLine: "raw|string_rm|", string$ (v70p)',
        'appendInfoLine: "raw|fixed4_rm|", fixed$ (v70p, 4)',
        'appendInfoLine: "raw|string_d35a|", string$ (5.8e-07)',
        '',
        '# --- 2b/2c. @eml_sig3 AND @emlFormatP ------------------------------',
        'procedure v70sig: .tag$, .v',
        '    @eml_sig3: .v',
        '    appendInfoLine: "sig|", .tag$, "|", eml_sig3.result$',
        'endproc',
        'procedure v70fp: .tag$, .p',
        '    @emlFormatP: .p',
        '    appendInfoLine: "fp|", .tag$, "|", emlFormatP.formatted$, "|",',
        '    ... emlFormatP.bare$, "|", emlFormatP.exact$',
        'endproc',
        '',
        '# The hand-written grid. Every case is a property some plausible',
        '# wrong implementation gets wrong: rm/d35a/d35b/d35c are the D35',
        '# trio and the line that reported this; carry is 9.999 rounding up',
        '# into the next decade; tiny300 and sub320 and minsub are the',
        '# subnormal range where a single divide by 10^e loses the divisor;',
        '# exact5 is a power of ten, where floor(log10) can land either side;',
        '# roundup and rounddown straddle the third-figure boundary; zero is',
        '# an underflowed p, which is a real thing for a report to print.',
        sprintf('@v70sig: "rm", %s', lit(3.0359635874099574e-29)),
        sprintf('@v70sig: "gg", %s', lit(2.463e-25)),
        '@v70sig: "d35a", 5.8e-07',
        '@v70sig: "d35b", 2.1e-13',
        '@v70sig: "d35c", 3.0e-04',
        '@v70sig: "carry", 9.999e-13',
        '@v70sig: "exact5", 1e-5',
        '@v70sig: "tiny300", 1e-300',
        '@v70sig: "sub320", 1e-320',
        sprintf('@v70sig: "minsub", %s', lit(4.9406564584124654e-324)),
        '@v70sig: "roundup", 1.0050000000000001e-07',
        '@v70sig: "rounddown", 1.0049e-07',
        '@v70sig: "nine", 9.9949e-07',
        '@v70sig: "zero", 0',
        '@v70sig: "neg", -3.5e-09',
        '@v70sig: "undef", undefined',
        '',
        '# --- 2d. THE SUBNORMAL SCALING, AS A COUNTERFACTUAL ----------------',
        '# The single-divide form of the same arithmetic, driven beside the',
        '# real one so the two-step scaling in @eml_sig3 is a MEASURED',
        '# requirement rather than a claim in its header.',
        'v70e = floor (log10 (4.9406564584124654e-324))',
        'appendInfoLine: "raw|onestep_minsub|",',
        '... string$ (4.9406564584124654e-324 / 10 ^ v70e)',
        '',
        '# --- 3. @emlFormatP END TO END -------------------------------------',
        sprintf('@v70fp: "rm", %s', lit(3.0359635874099574e-29)),
        '@v70fp: "d35a", 5.8e-07',
        '@v70fp: "d35b", 2.1e-13',
        '@v70fp: "d35c", 3.0e-04',
        '@v70fp: "ordinary", 0.032',
        '@v70fp: "boundary", 0.001',
        '@v70fp: "hi", 0.99987',
        '@v70fp: "hi2", 0.999999',
        '@v70fp: "one", 1',
        '@v70fp: "undef", undefined',
        '',
        '# The composed shapes, which are what v03, v04 and v65 read.',
        sprintf('@emlInlineP: %s', lit(3.0359635874099574e-29)),
        'appendInfoLine: "line|rm|F(2, 38) = 583.1232, ", emlInlineP.text$',
        sprintf('@emlInlineP: %s', lit(2.463e-25)),
        'appendInfoLine: "line|gg|Greenhouse-Geisser epsilon = 0.8486, GG-corrected ",',
        '... emlInlineP.text$',
        '',
        '# --- 4. RULING B: THE SIGNIFICANCE CRITERION -----------------------',
        'procedure v70al: .tag$, .a',
        '    emlAlpha = .a',
        '    @emlReportAlpha',
        '    appendInfoLine: "alpha|", .tag$, "|", string$ (emlReportAlpha.value),',
        '    ... "|", emlReportAlpha.text$',
        'endproc',
        '@v70al: "a05", 0.05',
        '@v70al: "a01", 0.01',
        '@v70al: "a001", 0.001',
        '@v70al: "a0001", 0.0001',
        '@v70al: "a00001", 0.00001',
        '# THE COUNTERFACTUAL, measured: what the criterion would print if a',
        '# display sweep routed it through the statistics formatter.',
        '@eml_fixed: 0.0001, 3',
        'appendInfoLine: "raw|efixed_a0001|", eml_fixed.result$',
        '@eml_fixed: 0.00001, 4',
        'appendInfoLine: "raw|efixed_a00001|", eml_fixed.result$',
        '',
        '# --- 5. THE OPEN SWEEP ---------------------------------------------',
        sprintf('@v70sig: "sw%03d", %s', seq_along(sweepVals), lit(sweepVals))),
        probe)

    outTxt <- suppressWarnings(system2("env",
        c("-u", "DISPLAY", shQuote(praat),
          shQuote(paste0("--pref-dir=", prefs)), "--run", shQuote(probe)),
        stdout = TRUE, stderr = TRUE))

    got <- function(tag, field) {
        p <- sprintf("^%s\\|%s\\|", tag, field)
        sub(p, "", grep(p, outTxt, value = TRUE))
    }
    # got() has already stripped "fp|<tag>|", so what is left is
    # formatted$|bare$|exact$ -- three fields, numbered from one. strsplit
    # DROPS a trailing empty field, which is exactly the ordinary-p case
    # where exact$ is deliberately empty, so a short vector reads as "" here
    # rather than as a missing measurement.
    fpField <- function(tag, i) {
        v <- got("fp", tag)
        if (!length(v)) return(NA_character_)
        parts <- strsplit(v[1], "|", fixed = TRUE)[[1]]
        if (length(parts) < i) "" else parts[i]
    }

    ran <- !any(grepl("^Error", outTxt)) && length(got("raw", "string_rm")) == 1
    if (!ran) cat(sprintf("      v70 probe output: %s\n",
                          paste(utils::tail(outTxt, 8), collapse = " / ")))
    check_true("v70", "the p-precision probe ran", ran)

    if (ran) {
        # -- 2a. THE PREMISE IS TRUE OF THIS BINARY -------------------------
        # Significant digits, not characters: "0.000000000000000000000000000030"
        # is thirty-one characters and two significant figures, and it is the
        # second number that says whether a reader can read the line.
        sigfigs <- function(s) {
            mant <- sub("[eE].*$", "", s)
            nchar(sub("^0+", "", gsub("[^0-9]", "", mant)))
        }
        strRm <- got("raw", "string_rm")
        fixRm <- got("raw", "fixed4_rm")
        check_true("v70",
                   sprintf("Praat's string$ is a ROUND-TRIP renderer, not a bounded one (%s, %d significant figures)",
                           strRm, sigfigs(strRm)),
                   sigfigs(strRm) >= 15)
        check_true("v70",
                   sprintf("and fixed$ at four decimals is not the substitute -- it renders the same p as %s",
                           fixRm),
                   sigfigs(fixRm) <= 3 && nchar(fixRm) > 20)

        # -- 2b. THE GRID, AS STRINGS ---------------------------------------
        # Written out rather than recomputed, so a shared misunderstanding
        # between two implementations cannot make both of them agree.
        grid <- list(
            rm        = "3.04e-29",
            gg        = "2.46e-25",
            d35a      = "5.80e-07",
            d35b      = "2.10e-13",
            d35c      = "3.00e-04",
            carry     = "1.00e-12",
            exact5    = "1.00e-05",
            tiny300   = "1.00e-300",
            sub320    = "1.00e-320",
            minsub    = "4.94e-324",
            roundup   = "1.01e-07",
            rounddown = "1.00e-07",
            nine      = "9.99e-07",
            zero      = "0",
            neg       = "-3.50e-09",
            undef     = "--undefined--")
        for (nm in names(grid)) {
            g <- got("sig", nm)
            check_true("v70",
                       sprintf("@eml_sig3 %s -> %s (got %s)", nm, grid[[nm]],
                               if (length(g)) paste(g, collapse = "/") else "nothing"),
                       length(g) == 1 && identical(g, grid[[nm]]))
        }

        # SAID AS A PROPERTY AS WELL AS A TABLE, so a seventeenth case added
        # later cannot quietly be the one exception: every finite non-zero
        # answer is one digit, a point, two digits, "e", a sign and at least
        # two exponent digits.
        finiteTags <- setdiff(names(grid), c("zero", "undef"))
        shapes <- vapply(finiteTags, function(nm) {
            g <- got("sig", nm); if (length(g) == 1) g else ""
        }, character(1))
        check_true("v70",
                   sprintf("every finite answer is exactly three significant figures in scientific form (%d case(s))",
                           length(shapes)),
                   length(shapes) == length(finiteTags) &&
                   all(grepl("^-?[0-9]\\.[0-9]{2}e[-+][0-9]{2,3}$", shapes)))

        # -- 2c. AND THE STRINGS ARE THE NUMBERS ----------------------------
        # THE ANTI-CLAMP. Everything above is a WIDTH, and a renderer that
        # returned "0.00e+00" for every input satisfies all of it -- as does
        # one that returns the example from this file's header. So each
        # printed tail is parsed back and compared against the value it was
        # given. The bound is 6e-3 relative, which is one half-unit in the
        # third significant figure of a mantissa of 1.00 plus room for the
        # ulp-level disagreement described below; the observed maximum over
        # this grid and the sweep is 5.0e-3.
        gridTrue <- c(rm = 3.0359635874099574e-29, gg = 2.463e-25,
                      d35a = 5.8e-07, d35b = 2.1e-13, d35c = 3.0e-04,
                      carry = 9.999e-13, exact5 = 1e-5, tiny300 = 1e-300,
                      sub320 = 1e-320, minsub = 4.9406564584124654e-324,
                      roundup = 1.0050000000000001e-07, rounddown = 1.0049e-07,
                      nine = 9.9949e-07, neg = -3.5e-09)
        relerr <- vapply(names(gridTrue), function(nm) {
            g <- got("sig", nm)
            if (length(g) != 1) return(Inf)
            n <- suppressWarnings(as.numeric(g))
            if (!is.finite(n)) return(Inf)
            abs(n - gridTrue[[nm]]) / abs(gridTrue[[nm]])
        }, numeric(1))
        check_true("v70",
                   sprintf("each printed tail IS the value it stands for, to three figures (max relative error %.2g over %d case(s))",
                           max(relerr), length(relerr)),
                   all(is.finite(relerr)) && max(relerr) <= 6e-3)

        # THE D35 ASSERTION ITSELF, which is the reason the tail exists and
        # the one thing no width check can express: three p-values nine orders
        # of magnitude apart, all three floored to the identical APA label,
        # must still print three DIFFERENT tails in the right order.
        trio <- c(got("sig", "d35a"), got("sig", "d35b"), got("sig", "d35c"))
        trioN <- suppressWarnings(as.numeric(trio))
        check_true("v70",
                   sprintf("D35: 5.8e-07, 2.1e-13 and 3.0e-04 print three DISTINCT tails (%s)",
                           paste(trio, collapse = ", ")),
                   length(trio) == 3 && length(unique(trio)) == 3)
        check_true("v70",
                   "D35: and in the right order, so the tail can be read as a magnitude",
                   length(trioN) == 3 && all(is.finite(trioN)) &&
                   trioN[2] < trioN[1] && trioN[1] < trioN[3])

        # -- 2d. THE TWO-STEP SCALING IS LOAD-BEARING, MEASURED --------------
        one <- got("raw", "onestep_minsub")
        check_true("v70",
                   sprintf("a single divide by 10^e fails in the subnormal range on this binary (got %s)",
                           if (length(one)) one else "nothing"),
                   length(one) == 1 && !grepl("^4\\.9", one))

        # -- 2e. THE OPEN SWEEP AGAINST glibc --------------------------------
        # Two hundred and sixteen values across the whole reportable range,
        # compared against %.2e in R. The count is asserted as well as the
        # mismatches: "0 mismatches" over an empty set is the shape of a check
        # that can only pass, and a probe that died halfway would produce
        # exactly that.
        swTags <- sprintf("sw%03d", seq_along(sweepVals))
        swGot  <- vapply(swTags, function(t) {
            g <- got("sig", t); if (length(g) == 1) g else NA_character_
        }, character(1))
        swRef  <- sci3(sweepVals)
        swBad  <- which(is.na(swGot) | swGot != swRef)
        check_true("v70",
                   sprintf("the whole reportable range agrees with glibc's %%.2e: %d value(s) from 1e-4 to 1e-324, %d mismatch(es)",
                           length(sweepVals), length(swBad)),
                   length(sweepVals) >= 100 && sum(!is.na(swGot)) == length(sweepVals) &&
                   length(swBad) == 0)
        if (length(swBad)) {
            cat("      NOTE v70: sweep mismatches\n")
            for (i in utils::head(swBad, 8))
                cat(sprintf("            %.17g -> got %s, expected %s\n",
                            sweepVals[i], swGot[i], swRef[i]))
        }

        # -- 3. @emlFormatP END TO END --------------------------------------
        # The APA labels are NOT this change's to move and are pinned so it
        # cannot have moved them: the statistics are correct everywhere they
        # are tested and only the tail's width was in question.
        apa <- list(rm = "p < .001", d35a = "p < .001", d35c = "p < .001",
                    ordinary = "p = .032", boundary = "p = .001",
                    hi = "p > .999", one = "p = 1.000",
                    undef = "p = undefined")
        for (nm in names(apa)) {
            check_true("v70",
                       sprintf("@emlFormatP %s still labels in APA form: %s (got %s)",
                               nm, apa[[nm]], fpField(nm, 1)),
                       identical(fpField(nm, 1), apa[[nm]]))
        }

        # THE TAIL APPEARS ON THE FLOORS AND NOWHERE ELSE. Both halves matter:
        # missing on a floor is D35 back, present on an ordinary p is a
        # parenthesis repeating a number the label already shows exactly.
        for (nm in c("rm", "d35a", "d35b", "d35c")) {
            check_true("v70",
                       sprintf("@emlFormatP %s carries an exact tail (%s)", nm,
                               fpField(nm, 3)),
                       nzchar(fpField(nm, 3)))
        }
        for (nm in c("ordinary", "boundary", "one", "undef")) {
            check_true("v70",
                       sprintf("@emlFormatP %s carries NO tail, the label is already exact", nm),
                       identical(fpField(nm, 3), ""))
        }

        # D35 AGAIN, AT THE CALL SITE THIS TIME. The trio in 2c drives
        # @eml_sig3 directly, which is the renderer; this drives the procedure
        # a report actually calls. The two are not the same assertion and one
        # of the deliberate breaks proves it: substituting @eml_fixed at four
        # decimals for @eml_sig3 leaves the renderer perfect and turns
        # 5.8e-07 and 2.1e-13 into the identical string "0.0000" one layer
        # further out -- a tail that is present, non-empty, correctly shaped
        # and nine orders of magnitude flattened, which is exactly the defect
        # the tail was added to fix wearing the repair's clothes.
        fpTrio <- vapply(c("d35a", "d35b", "d35c"), function(n) fpField(n, 3),
                         character(1))
        check_true("v70",
                   sprintf("D35 at the call site: the three floored p-values still reach the report as three DISTINCT tails (%s)",
                           paste(fpTrio, collapse = ", ")),
                   all(nzchar(fpTrio)) && length(unique(fpTrio)) == 3)
        fpTrioN <- suppressWarnings(as.numeric(fpTrio))
        check_true("v70",
                   "D35 at the call site: and each tail is the p it stands for, to three figures",
                   all(is.finite(fpTrioN)) &&
                   max(abs(fpTrioN - c(5.8e-07, 2.1e-13, 3.0e-04)) /
                       c(5.8e-07, 2.1e-13, 3.0e-04)) <= 6e-3)

        # THE UPPER FLOOR IS THE SAME DEFECT MIRRORED. Three significant
        # figures OF p is 1.00 for everything in [0.9995, 1), so the tail up
        # there bounds the DISTANCE from one instead. Asserted distinct for
        # the same reason the D35 trio is.
        hiTails <- c(fpField("hi", 3), fpField("hi2", 3))
        check_true("v70",
                   sprintf("the > .999 floor carries a bounded tail too, and two p-values there do not print alike (%s)",
                           paste(hiTails, collapse = " / ")),
                   all(nzchar(hiTails)) && hiTails[1] != hiTails[2] &&
                   all(nchar(hiTails) <= 16))

        # NOTHING IN THE TAIL IS LONGER THAN IT NEEDS TO BE. The defect was a
        # width and this is the width, said once for the whole family.
        allTails <- c(vapply(c("rm", "d35a", "d35b", "d35c"),
                             function(n) fpField(n, 3), character(1)), hiTails)
        check_true("v70",
                   sprintf("no exact tail exceeds sixteen characters (longest %d)",
                           max(nchar(allTails))),
                   max(nchar(allTails)) <= 16)

        # -- 3b. THE COMPOSED LINES, which are what v03/v04/v65 read ---------
        lineRm <- got("line", "rm")
        lineGg <- got("line", "gg")
        check_true("v70",
                   sprintf("the repeated-measures line reads as one readable sentence (%s)",
                           if (length(lineRm)) lineRm else "nothing"),
                   length(lineRm) == 1 &&
                   identical(lineRm,
                             "F(2, 38) = 583.1232, p < .001  (3.04e-29)"))
        check_true("v70",
                   sprintf("and the Greenhouse-Geisser line likewise (%s)",
                           if (length(lineGg)) lineGg else "nothing"),
                   length(lineGg) == 1 &&
                   identical(lineGg,
                             "Greenhouse-Geisser epsilon = 0.8486, GG-corrected p < .001  (2.46e-25)"))
        # AND THEY STILL CLEAR v03's AND v04's TOLERANCES, which were set at
        # 5e-30 and 5e-26 in August so that a plugin flooring this p to zero
        # could not pass. A tail bounded to three figures has to survive the
        # check that was built to catch a tail bounded to nothing.
        tailRm <- suppressWarnings(as.numeric(
            sub("^.*\\((.*)\\).*$", "\\1", if (length(lineRm)) lineRm else "")))
        tailGg <- suppressWarnings(as.numeric(
            sub("^.*\\((.*)\\).*$", "\\1", if (length(lineGg)) lineGg else "")))
        check("v70", "the printed RM tail still meets v03's tol = 5e-30",
              tailRm, 3.0359635874099574e-29, tol = 5e-30)
        check("v70", "the printed GG tail still meets v03's tol = 5e-26",
              tailGg, 2.463e-25, tol = 5e-26)

        # -- 4. RULING B: ALPHA IS A CRITERION, NOT A STATISTIC --------------
        # The counterfactual first, MEASURED, so the ruling is argued from
        # this binary's behaviour and not from a recollection of it.
        cf3 <- got("raw", "efixed_a0001")
        cf4 <- got("raw", "efixed_a00001")
        check_true("v70",
                   sprintf("routing the criterion through the statistics formatter would print .0001 as %s and .00001 as %s",
                           if (length(cf3)) cf3 else "nothing",
                           if (length(cf4)) cf4 else "nothing"),
                   length(cf3) == 1 && length(cf4) == 1 &&
                   suppressWarnings(as.numeric(cf3)) == 0 &&
                   suppressWarnings(as.numeric(cf4)) == 0)

        alphaGrid <- list(a05 = "0.05", a01 = "0.01", a001 = "0.001",
                          a0001 = "0.0001", a00001 = "0.00001")
        alField <- function(tag, i) {
            v <- got("alpha", tag)
            if (!length(v)) return(NA_character_)
            parts <- strsplit(v[1], "|", fixed = TRUE)[[1]]
            if (length(parts) < i) NA_character_ else parts[i]
        }
        for (nm in names(alphaGrid)) {
            check_true("v70",
                       sprintf("AUTHOR RULING B: @emlReportAlpha %s prints %s (got %s)",
                               nm, alphaGrid[[nm]], alField(nm, 2)),
                       identical(alField(nm, 2), alphaGrid[[nm]]))
        }
        # SAID AS THE PROPERTY IT IS, so a sixth alpha cannot be the
        # exception: no criterion is ever printed as a zero.
        alphaTexts <- vapply(names(alphaGrid), function(n) alField(n, 2),
                             character(1))
        check_true("v70",
                   sprintf("no significance criterion is printed as a zero (%s)",
                           paste(alphaTexts, collapse = " ")),
                   all(!is.na(alphaTexts)) &&
                   all(suppressWarnings(as.numeric(alphaTexts)) > 0))
        # AND THE NUMBER IS UNTOUCHED. The ruling is about the printed form;
        # @emlSigMark compares against .value, and if that had moved the
        # marking would have moved with it.
        alphaVals <- vapply(names(alphaGrid),
                            function(n) suppressWarnings(as.numeric(alField(n, 1))),
                            numeric(1))
        check("v70", "and .value itself is unchanged at alpha = .0001",
              alphaVals[["a0001"]], 1e-4, tol = 0)
        check("v70", "and at alpha = .05",
              alphaVals[["a05"]], 0.05, tol = 0)
    }
}

if (!exists("EML_SUITE")) {
    eml_report("v70 p precision: the exact tail is three significant figures")
    eml_exit()
}
