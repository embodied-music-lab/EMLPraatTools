# ============================================================================
# v69_bracket_disclosure.R -- the layout that puts the p-values ON the picture
#                             must say what produced them
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# THE RULING THIS FILE IMPLEMENTS (author, 16 August 2026). Ruling 1b gave the
# MATRIX layout a sub-line naming the post-hoc test and, on the parametric
# arm, saying where its family-wise control comes from --
# annotMatrixPosthoc$ reads "Tukey HSD (already family-wise)" on one arm and
# "Dunn's test (holm)" on the other. The BRACKET layout was left with nothing:
# neither the test nor the adjustment. That is the wrong way round. Brackets
# are the layout that puts p-values and stars DIRECTLY ON the picture, over
# the data, pair by pair, and it is therefore the layout a reader is most
# likely to take a claim off.
#
# THE AUTHOR ASKED WHAT R AND SPSS DO, AND THE ANSWER IS THE DESIGN. SPSS
# states "Adjustment for multiple comparisons: Bonferroni" beneath its
# pairwise-comparisons display. Base R states nothing at all, but every R
# package that DRAWS significance brackets discloses: ggpubr's
# stat_compare_means prints the method on the plot by default, and
# ggstatsplot carries the pairwise test AND the adjustment method in a caption
# on every figure it makes. The caption is the closest precedent and it is the
# shape the repair takes -- a line under the frame, not a second box inside
# it, because annotTextX/annotTextY is one slot with an alpha background that
# already carries the omnibus line, and a second box inside the frame would be
# placed by @emlPlaceElements, which scores the top quadrants DOWN precisely
# because brackets live there. A caption describing the brackets that lands on
# the brackets is worse than no caption.
#
# WHAT THE FAILURE LOOKED LIKE, AND WHY NOTHING SAW IT. It produced a CORRECT
# figure. Correct data, correct brackets, correct stars, a true omnibus line
# in the corner box naming One-way ANOVA or Kruskal-Wallis -- and no statement
# anywhere on it about which pairwise test drew the brackets or what was done
# about multiplicity. Nothing raises, nothing is missing, no number is wrong.
# The sharpest measurement of it is a byte comparison, taken 16 August 2026 on
# harness/bracketcap before the repair: the SAME figure driven with Dunn's
# test under holm and under bonferroni came back BYTE-IDENTICAL,
# 44ef32b3e893efb2b221ecf6678c0121 both times. The user's choice of correction
# changed the p-values behind the stars and left no trace whatever on the
# artefact that leaves the session. After the repair the two files differ, and
# the difference is the caption.
#
# The author's own note is the reason this is worth doing rather than an
# argument that it is not: the Info-window report ALREADY discloses it, and
# the driven output reads "-- Dunn's Post-Hoc (adjusted p, holm) --". Nothing
# was hidden from anyone reading the report. But the FIGURE is the artefact
# that leaves the session -- into a slide, into a paper, into a supervision --
# and the reader looking at it has no report beside them.
#
# THE TWO ARMS SAY DIFFERENT THINGS AND THAT IS THE CONTENT, NOT THE STYLE.
# Tukey's p comes from the studentized range distribution and is already
# family-wise over the set of pairwise comparisons, so the parametric caption
# states that and claims no further adjustment. Dunn's z-tests carry no
# family-wise control of their own, the form still offers the adjustment menu
# there and @emlDunnTest still honours it, so the nonparametric caption NAMES
# the method the user chose and claims nothing about what it achieves. One
# sentence covering both would be false on one of them whichever way it was
# written, and §3 asserts the asymmetry directly: "family-wise" must appear on
# the Tukey figure and must NOT appear on the Dunn figure.
#
# WHAT COULD NOT HAVE CAUGHT IT, AND WHY. This matters more than usual here,
# because the neighbouring validator looks like it should have.
#
#   - v66_draw_layer.R, WHICH OWNS RULING 1b AND IS THE CLOSEST PREDECESSOR.
#     Its §1d greps annotMatrixPosthoc$ out of the source and its §4 reads
#     posthoc_label and posthoc_subtitle off a driven figure. Every one of
#     those checks is scoped to the MATRIX PANEL: harness/drawlayer's
#     posthoc_tukey and posthoc_dunn legs call @emlBridgeGroupComparison with
#     layoutMode 3, which forces the matrix and leaves annotBracketN at zero,
#     and the subtitle it measures is drawn by @emlDrawMatrixPanel. A bracket
#     figure never enters its universe. It was green over this defect from the
#     day ruling 1b was closed, correctly, because it was never making a claim
#     about the other layout.
#
#   - EVERY NUMERIC VALIDATOR, v01 through v19 and the sweep. The statistics
#     were right. Dunn under holm and Dunn under bonferroni both produce
#     correct adjusted p-values and this file does not touch either. A
#     validator that recomputes a number cannot see that the figure carrying
#     it does not say how it was made.
#
#   - v29_figure_disclosure.R. It holds the three-channel rule -- Info window
#     always, figure only when Annotate is ticked, emlSubtitle$ never -- and
#     counts disclosures per draw procedure. The bracket caption is not a
#     draw-procedure disclosure: it is written by the annotation BRIDGE and
#     rendered by @emlDrawAnnotations after the draw procedure has returned,
#     so it is outside every population v29 counts.
#
#   - A GOLDEN-FILE DIFF over the committed figures. It says "this changed";
#     it cannot say "this was always silent". The two byte-identical
#     correction arms above were sitting in the tree, agreeing with each
#     other, which is exactly what a diff calls healthy.
#
#   - READING THE SOURCE, which is why the author's instruction was to prove
#     it by drawing both arms and reading the text off the picture. A caption
#     composed correctly and then drawn outside the exported region is
#     indistinguishable, in every Praat variable, from one that is there.
#     §4 reads the words back with tesseract.
#
# THE FOUR TRAPS, HUNTED IN THIS FILE'S OWN CHECKS.
#
#   A CHECK THAT COULD ONLY PASS. The expected correction tokens -- holm,
#   bonferroni, bh -- are written as literals here and compared against what
#   OCR reads off three separately driven figures. Nothing in the expectation
#   is derived from the artefact it is checked against. The three legs differ
#   ONLY in the token the user chose, so a caption hardcoded to any one of
#   them fails two of the three.
#
#   A CHECK THAT MATCHES THE COMMENT EXPLAINING THE FIX. The source under test
#   carries a sixty-line header about this ruling and four commented write
#   sites that name annotBracketPosthoc$ and quote the sentences verbatim. An
#   unstripped grep would find the repair in the paragraph describing the
#   repair. §2 reads code with comments removed -- both Praat comment forms,
#   "#" and ";" -- and continuations joined, and every string it matches is
#   matched as an ASSIGNMENT, anchored on the variable at the head of the line.
#
#   A SIZE THRESHOLD. The caption band makes the exported PNG taller and the
#   file bigger whether or not there are any words in it: an empty band is
#   77 px of white and several kilobytes of PNG. §4 counts INK inside the
#   band's own rows and records the byte counts beside it as the trap they
#   are.
#
#   A CHECK ANCHORED ON FIRST INK. Clipping is what a caption too wide for the
#   canvas actually does: it renders, and its tail is not in the file. The
#   words that survive are the ones at the START of the line, so the first ink
#   in the band sits exactly where a correct caption's first ink sits -- the
#   position moves the WRONG WAY for the defect, and would look healthiest on
#   the worst case. §4 measures the ink box on BOTH sides and the verdict is
#   the right edge against the image width, not the left edge against zero.
#
#   AND THE FIX-SHAPED FIX. A caption clamped to the empty string satisfies
#   every assertion about width, placement, band geometry and non-collision,
#   and discloses nothing; so does one clamped to a single space. Presence is
#   asserted as VALUE -- the words, off the picture -- and not as fit.
#
# WHAT AUTHOR RULING C (16 AUGUST 2026) CHANGED IN THIS FILE. §8 recorded a
# finding this ruling did not close: both two-group arms composed an omnibus
# string and set annotTextN on NEITHER path, so a two-group BRACKET figure
# named no test anywhere on it -- the whole-figure OCR of welch_two carried a
# bracket, "***", a Cohen's d and no test name. Ruling C closes it with one
# invariant and no two-group special case: every bracket-bearing figure names
# its test. The arms now set annotTextN, so the corner box carries the test,
# and they write a caption of their own. Three things in this file therefore
# assert the OPPOSITE of what they asserted on 16 August, and each says so
# where it stands: §2 (the source), §4 (which legs draw a band), §5 (where a
# caption must not appear). What did NOT change is the reason the arms were
# silent about adjustment: one comparison is no family, nothing was corrected,
# and §3 asserts that neither two-group figure reports a correction -- mw_two
# is driven with "holm" sitting in the form scope precisely so that a repair
# reaching for .correction$ on that arm goes red rather than passing.
# The general invariant -- every ARM that can produce a bracket sets
# annotTextN -- belongs to validate/v76, which enumerates the arms out of the
# bridge so that an arm added later without a test name goes red.
#
# Input: harness/bracketcap/out/. $EML_BRACKETCAP_DIR overrides it and
#        $EML_ANNOT_SRC overrides the source under test, so a break test drives
#        a COPY of the tree and the working tree is never touched.
#        Regenerate with:
#
#            bash harness/bracketcap/bracketcap.sh
#            Rscript validate/v69_bracket_disclosure.R
#
# NOTHING HERE IS VALIDATED UNTIL IT HAS BEEN BROKEN. Every check in this file
# was shown RED against a deliberately broken COPY of the tree. The breaks and
# their results are in harness/bracketcap/break.sh.
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

ID <- "v69"

`%or%` <- function(a, b) if (is.null(a) || length(a) == 0L || is.na(a)) b else a

src <- Sys.getenv("EML_ANNOT_SRC", unset = "")
if (!nzchar(src)) src <- repo_path(file.path("plugin", "graphs",
                                             "eml-annotation-procedures.praat"))
bdir <- Sys.getenv("EML_BRACKETCAP_DIR", unset = "")
if (!nzchar(bdir)) bdir <- repo_path(file.path("harness", "bracketcap", "out"))

tsv_path <- file.path(bdir, "BRACKETCAP.tsv")

have_src <- file.exists(src)
have_tsv <- file.exists(tsv_path)
check_true(ID, "the annotation bridge source is present", have_src)
check_true(ID, "harness/bracketcap has been driven", have_tsv)

# ---------------------------------------------------------------------------
# JOIN PRAAT CONTINUATIONS, THEN STRIP COMMENTS, THEN MATCH.
# ---------------------------------------------------------------------------
# Both halves have bitten this repository. Every caption string in the source
# is written across two lines with a "..." continuation, so a line-at-a-time
# regex would see the head of an assignment and never the sentence -- the
# shape of a check that passes while proving nothing. And the file carries a
# long prose header about this very ruling which quotes the sentences it
# explains, so an unstripped grep finds the repair in its own documentation.
read_code <- function(path) {
    if (!file.exists(path)) return(character(0))
    raw <- readLines(path, warn = FALSE)
    joined <- character(0)
    for (ln in raw) {
        if (grepl("^\\s*\\.\\.\\.", ln) && length(joined)) {
            joined[length(joined)] <- paste0(joined[length(joined)], " ",
                                             sub("^\\s*\\.\\.\\.\\s*", "", ln))
        } else {
            joined <- c(joined, ln)
        }
    }
    norm <- gsub("\\s+", " ", trimws(joined))
    norm[!grepl("^#", norm) & !grepl("^;", norm)]
}

code <- read_code(src)

# The body of one procedure, comments already stripped. Needed because this
# file holds twenty-seven procedures and a check for "the caption is called"
# would otherwise be satisfied by the call appearing anywhere at all.
proc_body_of <- function(code, name) {
    i <- grep(sprintf("^procedure %s(:|$)", name), code)
    if (!length(i)) return(character(0))
    j <- grep("^endproc\\b", code)
    j <- j[j > i[1]]
    if (!length(j)) return(character(0))
    code[(i[1] + 1L):(j[1] - 1L)]
}

has <- function(x, pattern) any(grepl(pattern, x))
cnt <- function(x, pattern) sum(grepl(pattern, x))

# ---------------------------------------------------------------------------
# THE DRIVEN ARTEFACT. One row per leg, written by harness/bracketcap.sh.
# Read as a data frame keyed by leg, not as a flat map: seven legs publish the
# same keys and a flat map would answer every one of them with the first.
# ---------------------------------------------------------------------------
COLS <- c("leg", "verdict", "bracket_n", "cap_ran", "cap_drawn", "cap_lines",
          "cap_width_mm", "cap_avail_mm", "img_w", "img_h",
          "ink_px", "ink_left", "ink_right", "ocr")

legs <- data.frame()
if (have_tsv) {
    raw <- readLines(tsv_path, warn = FALSE)
    raw <- raw[nzchar(raw)]
    parts <- lapply(raw, function(ln) {
        p <- strsplit(ln, "\t", fixed = TRUE)[[1]]
        length(p) <- length(COLS)
        p[is.na(p)] <- ""
        p
    })
    if (length(parts)) {
        legs <- as.data.frame(do.call(rbind, parts), stringsAsFactors = FALSE)
        names(legs) <- COLS
    }
}

# One value out of a leg's key<TAB>value file. The TSV carries what the shell
# measured; the .kv carries what Praat emitted, and the figure width lives
# only there. Read rather than assumed: the narrow leg is 3.2 in and every
# other leg is 6, so a constant here would be wrong on the leg the clipping
# checks exist for.
kvget <- function(leg, key) {
    p <- file.path(bdir, paste0(leg, ".kv"))
    if (!file.exists(p)) return(NA_character_)
    x <- readLines(p, warn = FALSE)
    hit <- grep(paste0("^", key, "\t"), x, value = TRUE)
    if (!length(hit)) return(NA_character_)
    sub(paste0("^", key, "\t"), "", hit[1])
}
kvn <- function(leg, key) suppressWarnings(as.numeric(kvget(leg, key)))

lv <- function(leg, key) {
    if (!nrow(legs)) return(NA_character_)
    r <- legs[legs$leg == leg, , drop = FALSE]
    if (!nrow(r)) return(NA_character_)
    as.character(r[[key]][1])
}
ln_ <- function(leg, key) suppressWarnings(as.numeric(lv(leg, key)))

# OCR NORMALISATION, AND WHAT IT IS ALLOWED TO FORGIVE. tesseract renders the
# typographic apostrophe in "Dunn's" as either ' or U+2019 depending on the
# rasterisation, and the em-dash as an em-dash, an en-dash or a hyphen. Those
# are the reader's glyphs, not the plugin's claims, and normalising them keeps
# the checks about the WORDS. Nothing else is touched: case is preserved, and
# the correction tokens -- which are the whole value check -- are compared
# exactly.
norm_ocr <- function(s) {
    if (is.na(s)) return("")
    s <- gsub("’|‘|`", "'", s)
    s <- gsub("—|–", "-", s)
    gsub("\\s+", " ", trimws(s))
}

# AUTHOR RULING C, 16 August 2026, MOVED welch_two ACROSS THIS LINE and added
# mw_two beside it. Until ruling C the two-group arms wrote empty captions and
# welch_two was the leg that proved a caption correctly DECLINES; §5 asserted
# the decline and §8 recorded, as an attestation and not as a test, that the
# same figure named no test anywhere on it. Ruling C is one invariant with no
# two-group special case: every bracket-bearing figure names its test. So both
# two-group legs now draw, and the leg that proves a caption declines is
# ns_omnibus, which draws no brackets at all. What each two-group caption may
# NOT say is asserted as hard as what it must -- see §3.
DRAWN_LEGS <- c("tukey", "dunn_holm", "dunn_bonferroni", "dunn_bh", "narrow",
                "welch_two", "mw_two")
TWO_GROUP  <- c("welch_two", "mw_two")
QUIET_LEGS <- c("ns_omnibus")
ALL_LEGS   <- c(DRAWN_LEGS, QUIET_LEGS)

# ===========================================================================
# 1. THE DRIVE RAN, AND IT RAN CLEAN
# ===========================================================================
# A leg that aborted mid-script writes no PNG and every measurement after the
# abort reads empty -- which, without this, would present as a caption that
# simply was not drawn. NO_FIGURE and "correctly drew nothing" are different
# verdicts and only one of them is acceptable anywhere in this file.
if (have_tsv) {
    check_true(ID, "all eight legs are present in the driven artefact",
               setequal(legs$leg, ALL_LEGS))
    for (lg in ALL_LEGS) {
        check_true(ID, sprintf("leg %s rendered without error", lg),
                   identical(lv(lg, "verdict"), "OK"))
    }
}

# ===========================================================================
# 2. THE SOURCE: FOUR ARMS, FOUR DECISIONS, COMMENTS STRIPPED
# ===========================================================================
# Static, and it is the weaker half on purpose -- it says the code contains
# the repair, not that the repair reaches the picture. §3 and §4 are the
# claim; this section is what makes a failure legible when they go red.
if (have_src) {
    body_caption <- proc_body_of(code, "emlDrawBracketCaption")
    body_annots  <- proc_body_of(code, "emlDrawAnnotations")
    body_clear   <- proc_body_of(code, "emlClearAnnotations")

    check_true(ID, "@emlDrawBracketCaption exists",
               length(body_caption) > 0)

    # THE CALL SITE, IN THE UMBRELLA AND NOWHERE ELSE. A procedure that is
    # defined and never called renders nothing, and the source still contains
    # every sentence a text search would look for.
    check_true(ID, "@emlDrawAnnotations calls @emlDrawBracketCaption",
               has(body_annots, "^@emlDrawBracketCaption:"))
    check_true(ID, "the caption call is gated on there being brackets to describe",
               has(body_annots, "^if annotBracketN > 0$"))

    # The strings, as ASSIGNMENTS. Anchored at the start of the (joined,
    # comment-stripped) line so a mention inside another statement cannot
    # satisfy them.
    tuk <- grep("^annotBracketPosthoc\\$ = \"Pairwise comparisons: Tukey",
                code, value = TRUE)
    dun <- grep("^annotBracketPosthoc\\$ = \"Pairwise comparisons: Dunn",
                code, value = TRUE)
    check_true(ID, "the parametric arm names Tukey HSD as the pairwise test",
               length(tuk) == 1)
    check_true(ID, "the nonparametric arm names Dunn's test",
               length(dun) == 1)

    adj_tuk <- grep("^annotBracketAdjust\\$ = \"already family-wise", code,
                    value = TRUE)
    adj_dun <- grep("^annotBracketAdjust\\$ = \"adjustment for multiple", code,
                    value = TRUE)
    check_true(ID, "the Tukey arm's clause claims its own family-wise control",
               length(adj_tuk) == 1)
    check_true(ID, "the Dunn arm's clause is the SPSS-shaped adjustment line",
               length(adj_dun) == 1)

    # THE ADJUSTMENT IS A VARIABLE, NOT A LITERAL, AND THIS IS THE STATIC HALF
    # OF THE VALUE CHECK. A caption that reads "holm" whatever the user picked
    # satisfies every other assertion in this file except the three driven
    # tokens in §3. Both halves are kept: this one names the defect, that one
    # proves it.
    check_true(ID, "the Dunn clause interpolates .correction$ rather than a literal",
               length(adj_dun) == 1 && grepl("\\+ \\.correction\\$", adj_dun[1]))
    check_true(ID, "no bracket caption hardcodes a correction name",
               !has(grep("^annotBracketAdjust\\$ =", code, value = TRUE),
                    "holm|bonferroni|\"bh\""))

    # THE TWO-GROUP ARMS NAME THEIR TEST TOO -- AUTHOR RULING C, and this
    # block used to assert the opposite. It read "both two-group arms write an
    # empty bracket caption" and counted two empty assignments to each half,
    # on the argument that two groups is one comparison and a ruling about a
    # post-hoc method and a correction had nothing to say. The half of that
    # argument that held is the ADJUSTMENT: nothing was corrected and the
    # caption must not pretend otherwise, which is why the sentences below are
    # not the Tukey sentence and are checked for not being it. The half that
    # did not is the TEST NAME, and §8 of this file measured the cost of the
    # silence before the ruling closed it.
    #
    # Counted INSIDE THE BRIDGE, not across the file: @emlClearAnnotations
    # writes the empty assignments the reset needs, and a file-wide count
    # would read them as arms.
    body_bridge <- proc_body_of(code, "emlBridgeGroupComparison")
    # ADJACENT STRING LITERALS ARE ONE STRING, and the source splits these
    # sentences across a continuation to stay inside the line budget, so the
    # joined line reads  ... "one comparison; no adjustment " + "applied".
    # Collapsing quote-plus-quote is exactly Praat's literal concatenation and
    # nothing else: `+ .correction$` has no quote on its left and survives,
    # which is what keeps the "interpolates a variable" check above honest.
    unsplit <- function(x) gsub("\" \\+ \"", "", x)
    body_bridge <- unsplit(body_bridge)
    check_true(ID, "the two-group parametric arm names Welch's t-test",
               cnt(body_bridge,
                   "^annotBracketPosthoc\\$ = \"Comparison: Welch t-test\"$") == 1)
    check_true(ID, "the two-group nonparametric arm names the Mann-Whitney U test",
               cnt(body_bridge,
                   "^annotBracketPosthoc\\$ = \"Comparison: Mann-Whitney U test\"$") == 1)
    check_true(ID, "both two-group arms state that one comparison needs no adjustment",
               cnt(body_bridge,
                   "^annotBracketAdjust\\$ = \"one comparison; no adjustment applied\"$") == 2)
    # AND NEITHER BORROWS THE k >= 3 SENTENCE. "already family-wise" is a
    # claim about the studentized range distribution; a Welch t makes no such
    # claim and there is no family here to be wise about. The over-sweep this
    # guards is a repair that gave the two-group arms the Tukey caption
    # because it was the nearest one to hand.
    check_true(ID, "no two-group arm claims family-wise control",
               cnt(body_bridge, "^annotBracketAdjust\\$ = \"already family-wise") == 1)
    check_true(ID, "the bridge no longer writes an empty bracket caption anywhere",
               cnt(body_bridge, "^annotBracketPosthoc\\$ = \"\"$") == 0 &&
               cnt(body_bridge, "^annotBracketAdjust\\$ = \"\"$") == 0)

    check_true(ID, "@emlClearAnnotations resets both caption halves",
               has(body_clear, "^annotBracketPosthoc\\$ = \"\"$") &&
               has(body_clear, "^annotBracketAdjust\\$ = \"\"$"))

    # THE BAND IS REPORTED TO THE EXTENT TRACKER. Without this line the
    # caption is drawn into the picture window and then cropped off the
    # export by @emlAssertFullViewport, which is the failure mode no Praat
    # variable can see -- every measurement the drive emits is identical
    # either way. §4 catches it on the file; this catches it in the source.
    check_true(ID, "the caption band is reported to @emlExpandDrawnExtent",
               has(body_caption, "^@emlExpandDrawnExtent:"))
    # And the viewport is put back, or every axis drawn after it lands in the
    # caption's band instead of the plot's.
    check_true(ID, "the caption restores the caller's viewport and axes",
               has(body_caption, "^@emlSetPanelViewport$") &&
               has(body_caption, "^Axes: \\.axXMin, \\.axXMax, \\.axYMin, \\.axYMax$"))
}

# ===========================================================================
# 3. WHAT THE FIGURE SAYS, READ OFF THE FIGURE
# ===========================================================================
# The author's instruction: prove it by drawing both arms and reading the text
# off the picture, not out of the source. Everything in this section comes
# from tesseract's reading of the caption band cropped out of the exported
# PNG. Nothing here consults the strings the plugin emitted.
if (have_tsv) {
    o_tuk <- norm_ocr(lv("tukey", "ocr"))
    o_hol <- norm_ocr(lv("dunn_holm", "ocr"))
    o_bon <- norm_ocr(lv("dunn_bonferroni", "ocr"))
    o_bh  <- norm_ocr(lv("dunn_bh", "ocr"))
    o_nar <- norm_ocr(lv("narrow", "ocr"))

    check_true(ID, "the Tukey figure names Tukey HSD as the pairwise test",
               grepl("Pairwise comparisons: Tukey HSD", o_tuk, fixed = TRUE))
    check_true(ID, "the Tukey figure states its own family-wise control",
               grepl("already family-wise", o_tuk, fixed = TRUE) &&
               grepl("no further adjustment", o_tuk, fixed = TRUE))
    check_true(ID, "the Dunn figure names Dunn's test as the pairwise test",
               grepl("Pairwise comparisons: Dunn's test", o_hol, fixed = TRUE))

    # THE ASYMMETRY, ASSERTED IN BOTH DIRECTIONS. The ruling is that the two
    # arms say DIFFERENT things and that one sentence must not serve both. A
    # generic caption -- "Pairwise comparisons corrected for multiplicity" --
    # would satisfy a check that only asked whether each figure carries a
    # caption, and would be false on the Dunn arm or vacuous on the Tukey one.
    check_true(ID, "the Dunn figure claims NO family-wise control of its own",
               !grepl("family-wise", o_hol, fixed = TRUE))
    check_true(ID, "the Tukey figure does not report an adjustment it never made",
               !grepl("adjustment for multiple comparisons", o_tuk, fixed = TRUE))
    check_true(ID, "the two arms' captions are not the same sentence",
               nzchar(o_tuk) && nzchar(o_hol) && !identical(o_tuk, o_hol))

    # THE VALUE CHECK. Three figures that differ ONLY in the correction the
    # user chose. A caption clamped to any single token -- the exact shape of
    # the fix-shaped fix -- satisfies presence, width, placement, band
    # geometry and the asymmetry above, and fails here twice.
    want <- c(dunn_holm = "holm", dunn_bonferroni = "bonferroni",
              dunn_bh = "bh")
    read_tok <- c(dunn_holm = sub(".*adjustment for multiple comparisons: ", "", o_hol),
                  dunn_bonferroni = sub(".*adjustment for multiple comparisons: ", "", o_bon),
                  dunn_bh = sub(".*adjustment for multiple comparisons: ", "", o_bh))
    for (lg in names(want)) {
        check_true(ID, sprintf("leg %s reports the correction the user chose (read: '%s')",
                               lg, read_tok[[lg]]),
                   identical(trimws(read_tok[[lg]]), want[[lg]]))
    }
    check_true(ID, "the three corrections produce three different captions",
               length(unique(c(o_hol, o_bon, o_bh))) == 3)

    # The narrow figure carries the SAME claim, broken over two lines. The
    # wrap must not cost a word.
    check_true(ID, "the wrapped caption still carries the whole claim",
               grepl("Pairwise comparisons: Dunn's test", o_nar, fixed = TRUE) &&
               grepl("adjustment for multiple comparisons: bonferroni",
                     o_nar, fixed = TRUE))

    # THE TWO-GROUP ARMS, READ OFF THEIR OWN PICTURES -- AUTHOR RULING C.
    # Both must name the test; neither may claim an adjustment, and mw_two is
    # the leg that makes the second half of that a real check rather than a
    # tautology. It is driven with annotCorrectionMethod$ = "holm", so the
    # token is sitting in the form scope where the k >= 3 nonparametric arm
    # reads it from. A repair that reached for .correction$ on this arm too
    # would put "holm" on a figure where one comparison was made and nothing
    # was adjusted, and it would pass every other line in this file.
    o_wt <- norm_ocr(lv("welch_two", "ocr"))
    o_mw <- norm_ocr(lv("mw_two", "ocr"))
    check_true(ID, "the two-group parametric figure names Welch's t-test",
               grepl("Comparison: Welch t-test", o_wt, fixed = TRUE))
    check_true(ID, "the two-group nonparametric figure names the Mann-Whitney U test",
               grepl("Comparison: Mann-Whitney U test", o_mw, fixed = TRUE))
    check_true(ID, "both two-group figures state one comparison and no adjustment",
               grepl("one comparison; no adjustment applied", o_wt, fixed = TRUE) &&
               grepl("one comparison; no adjustment applied", o_mw, fixed = TRUE))
    check_true(ID, "neither two-group figure reports a correction it never applied",
               !grepl("holm", o_mw, fixed = TRUE) &&
               !grepl("holm", o_wt, fixed = TRUE) &&
               !grepl("adjustment for multiple comparisons", o_mw, fixed = TRUE))
    check_true(ID, "no two-group figure claims family-wise control",
               !grepl("family-wise", o_wt, fixed = TRUE) &&
               !grepl("family-wise", o_mw, fixed = TRUE))
    check_true(ID, "the two two-group arms' captions are not the same sentence",
               nzchar(o_wt) && nzchar(o_mw) && !identical(o_wt, o_mw))
}

# ===========================================================================
# 4. THE CAPTION IS IN THE FILE, IT FITS, AND IT IS NOT CLIPPED
# ===========================================================================
# §3 proves the words are right. This section proves they are all there.
if (have_tsv) {
    for (lg in DRAWN_LEGS) {
        check_true(ID, sprintf("leg %s: the caption procedure ran and drew", lg),
                   identical(lv(lg, "cap_ran"), "1") &&
                   identical(lv(lg, "cap_drawn"), "1"))

        # INK, NOT BYTES. The band makes the PNG taller and the file bigger
        # whether or not anything is written in it -- an empty caption strip
        # is several kilobytes of white, which is how a 52 KB empty frame
        # sails through a 20 KB gate. Ink is counted inside the band's own
        # rows, and the byte count is recorded as a NOTE beside it.
        check_true(ID, sprintf("leg %s: there is ink inside the caption band", lg),
                   is.finite(ln_(lg, "ink_px")) && ln_(lg, "ink_px") > 0)

        # FIT, FROM THE PLUGIN'S OWN MEASUREMENT. Necessary and not
        # sufficient: a caption clamped to the empty string measures zero
        # against a positive budget and passes this line, which is why
        # cap_avail_mm is required to be positive and why §3 asserts the
        # words.
        w <- ln_(lg, "cap_width_mm"); a <- ln_(lg, "cap_avail_mm")
        check_true(ID, sprintf("leg %s: the caption fits the room it has (%.1f <= %.1f mm)",
                               lg, w %or% NA, a %or% NA),
                   is.finite(w) && is.finite(a) && a > 0 && w <= a)

        # CLIPPING, MEASURED ON THE RIGHT. This is the check the header's
        # fourth trap is about. A caption too wide for the canvas renders its
        # opening words in exactly the place a correct caption's opening words
        # go; ink_left is therefore blind to it and would read HEALTHIEST on
        # the worst case. The verdict is the gap between the rightmost inked
        # column and the image edge. Both edges are asserted, and the right
        # one is the one that can fail for the reason it exists.
        il <- ln_(lg, "ink_left"); ir <- ln_(lg, "ink_right")
        iw <- ln_(lg, "img_w")
        # The clearance is not a constant and must not be. It is the padding
        # the caption itself claims -- half the difference between the figure
        # width and the room it measured against -- so a narrow figure is held
        # to a narrow margin and a wide one to a wide margin, and neither
        # number is invented here. "ir < iw - 1" alone is not enough: a
        # caption clipped by the canvas ends one pixel inside the canvas by
        # definition, which is the shape of a bound that can only be met.
        figw <- kvn(lg, "figure_w_in")
        ppi  <- if (is.finite(figw) && figw > 0 && is.finite(iw)) iw / figw else NA
        pad_px <- if (is.finite(ppi) && is.finite(a) && is.finite(figw))
                      (figw - a / 25.4) / 2 * ppi else NA
        check_true(ID, sprintf("leg %s: caption ink clears the RIGHT edge by its own padding (right %s, limit %.0f of %s px)",
                               lg, ir %or% NA, (iw - pad_px) %or% NA, iw %or% NA),
                   is.finite(ir) && is.finite(pad_px) && ir > 0 &&
                   ir < iw - pad_px)
        check_true(ID, sprintf("leg %s: caption ink clears the left edge by its own padding", lg),
                   is.finite(il) && is.finite(pad_px) && il > pad_px)

        # THE PICTURE'S OWN WIDTH, AGAINST THE PLUGIN'S CLAIM ABOUT IT. Every
        # check above this line reads a number the plugin emitted, so a build
        # that measures wrongly and then reports that it fits satisfies all of
        # them -- that is the fix-shaped fix in its width form, and it is the
        # one break in harness/bracketcap/break.sh built specifically to walk
        # past a first-ink check. The ink span is measured on the file, in mm,
        # and held to two things: it must fit the room, and it must AGREE with
        # what the plugin said it measured. Antialiasing and side bearings put
        # the honest ratio near 0.99, never near 2.
        span_mm <- if (is.finite(il) && is.finite(ir) && is.finite(ppi) && ir > il)
                       (ir - il) / ppi * 25.4 else NA
        check_true(ID, sprintf("leg %s: the ink on the page fits the room (%.1f <= %.1f mm)",
                               lg, span_mm %or% NA, a %or% NA),
                   is.finite(span_mm) && is.finite(a) && span_mm <= a)
        ratio <- if (is.finite(span_mm) && is.finite(w) && w > 0) span_mm / w else NA
        check_true(ID, sprintf("leg %s: the measured ink width agrees with the reported one (ratio %.3f)",
                               lg, ratio %or% NA),
                   is.finite(ratio) && ratio > 0.85 && ratio < 1.10)
    }

    # THE WRAP PATH IS EXERCISED, NOT MERELY AVAILABLE. A two-line branch that
    # no leg reaches is untested code that a validator's green count claims
    # credit for. The narrow figure is 3.2 in wide and the caption does not
    # fit at the annotation size on one line at the 5 pt floor.
    check_true(ID, "the narrow figure wraps the caption onto two lines",
               identical(lv("narrow", "cap_lines"), "2"))
    check_true(ID, "the wide figures keep the caption on one line",
               all(vapply(setdiff(DRAWN_LEGS, "narrow"),
                          function(lg) identical(lv(lg, "cap_lines"), "1"),
                          logical(1))))

    # The band is taken OUTSIDE the plot, so the export grows. If it did not,
    # the caption would be drawn and cropped -- and every emitted measurement
    # would be identical. The control is ns_omnibus, which draws no brackets
    # and reaches no caption; it was welch_two until ruling C gave the
    # two-group arms a caption of their own. Both figures are 6 x 4 in, so
    # the only thing the extra height can be is the band.
    check_true(ID, "the export grew to include the caption band",
               is.finite(ln_("tukey", "img_h")) &&
               is.finite(ln_("ns_omnibus", "img_h")) &&
               ln_("tukey", "img_h") > ln_("ns_omnibus", "img_h"))
    check_true(ID, "the two-group export grew for the same reason",
               is.finite(ln_("welch_two", "img_h")) &&
               is.finite(ln_("ns_omnibus", "img_h")) &&
               ln_("welch_two", "img_h") > ln_("ns_omnibus", "img_h"))
}

# ===========================================================================
# 4b. THE CAPTION IS ADDITIVE: THE FIGURE KEEPS WHAT IT ALREADY SAID
# ===========================================================================
# @emlDrawBracketCaption moves the viewport to draw its band, and everything
# the caller draws afterwards lands in that band if the world is not put back.
# Measured 16 August 2026 against a copy with the restore deleted: the caption
# was perfect, the plot was perfect, the band was exactly the right size with
# exactly the right ink in it -- and the omnibus box, "One-way ANOVA: F(3, 44)
# = 559.05, p < .001", was not on the figure at all. Every measurement scoped
# to the caption said the caption was fine, and it was; what the caption cost
# was somewhere else. A disclosure that is paid for out of another disclosure
# is not an improvement.
#
# Read off the region ABOVE the band, so the caption's own words cannot
# satisfy it.
if (have_tsv) {
    fig_ocr <- function(leg) {
        p <- file.path(bdir, paste0(leg, ".fig.ocr"))
        if (!file.exists(p)) return("")
        norm_ocr(paste(readLines(p, warn = FALSE), collapse = " "))
    }
    # welch_two and mw_two ARE in this list as of ruling C, and their absence
    # from it was the finding §8 used to record: every other leg carried its
    # omnibus in the corner box and the two-group legs carried nothing, so
    # this loop -- which is about the caption not COSTING the figure a line it
    # already had -- had no line of theirs to protect. It has one now, and it
    # is the same evidence v76 asserts the ruling on.
    want_omni <- c(tukey = "One-way ANOVA", dunn_holm = "Kruskal-Wallis",
                   dunn_bonferroni = "Kruskal-Wallis", dunn_bh = "Kruskal-Wallis",
                   narrow = "Kruskal-Wallis", ns_omnibus = "One-way ANOVA",
                   welch_two = "Welch t", mw_two = "Mann-Whitney")
    for (lg in names(want_omni)) {
        check_true(ID, sprintf("leg %s: the omnibus line is still on the figure", lg),
                   grepl(want_omni[[lg]], fig_ocr(lg), fixed = TRUE))
    }
    # And the caption is BELOW the frame, not inside it: its sentence must not
    # be readable in the region above the band. This is the collision the
    # author named -- a second box inside the frame landing on the brackets it
    # describes -- asserted rather than assumed from the geometry.
    #
    # The sentence looked for is the leg's OWN opening clause, taken from the
    # .kv the bridge wrote, not the literal "Pairwise comparisons": the
    # two-group arms open with "Comparison:" and a fixed literal would have
    # quietly stopped making a claim about them the moment they gained a
    # caption. Reading it from the artefact is safe here because the strings
    # themselves are asserted as literals in §3 -- this line is about WHERE
    # the words are, and it borrows the words §3 already pinned.
    for (lg in DRAWN_LEGS) {
        head_clause <- kvget(lg, "posthoc")
        check_true(ID, sprintf("leg %s: the caption is outside the frame, not in it", lg),
                   !is.na(head_clause) && nzchar(head_clause) &&
                   !grepl(norm_ocr(head_clause), fig_ocr(lg), fixed = TRUE))
    }
}

# ===========================================================================
# 5. WHERE THE CAPTION MUST NOT APPEAR
# ===========================================================================
# A disclosure that turns up where nothing was disclosed is a false claim, and
# it is the cost of getting §3 green by drawing a caption unconditionally.
if (have_tsv) {
    # THE TWO-GROUP LEGS USED TO BE THIS SECTION'S SUBJECT and are now §3's.
    # They asserted that the caption procedure ran, found two empty halves and
    # correctly declined. Ruling C says a bracket-bearing figure names its
    # test whatever k is, so what remains here is the case where there is no
    # bracket at all -- and that case is unchanged by the ruling, which is the
    # thing worth pinning: the sweep must not have widened past figures that
    # HAVE brackets.

    # A non-significant omnibus runs no post-hoc and draws no brackets, so
    # @emlDrawAnnotations is never entered at all: cap_ran = 0. A figure with
    # no p-values on it must not carry a sentence about how they were
    # corrected.
    check_true(ID, "a non-significant omnibus draws no brackets",
               identical(lv("ns_omnibus", "bracket_n"), "0"))
    check_true(ID, "a non-significant omnibus reaches no caption at all",
               identical(lv("ns_omnibus", "cap_ran"), "0") &&
               identical(lv("ns_omnibus", "ink_px"), "0"))
}

# ===========================================================================
# 6. THE FIGURE AND THE REPORT AGREE
# ===========================================================================
# The author's note is that the Info-window report already discloses this. It
# follows that the two must not be able to drift: a figure saying "holm" over
# a report saying "bonferroni" is worse than the silence being repaired, and
# it is reachable the moment either side stops reading .correction$. The
# report's token comes from @emlDunnTest via the same variable; asserted here
# against the picture's, per leg, so the two are pinned to each other rather
# than each to a constant.
if (have_tsv) {
    for (lg in c("dunn_holm", "dunn_bonferroni", "dunn_bh")) {
        kv <- file.path(bdir, paste0(lg, ".kv"))
        composed <- NA_character_
        if (file.exists(kv)) {
            x <- readLines(kv, warn = FALSE)
            hit <- grep("^adjust\t", x, value = TRUE)
            if (length(hit)) composed <- sub("^adjust\t", "", hit[1])
        }
        drawn <- norm_ocr(lv(lg, "ocr"))
        check_true(ID, sprintf("leg %s: the drawn caption carries the clause the bridge composed", lg),
                   !is.na(composed) && nzchar(composed) &&
                   grepl(norm_ocr(composed), drawn, fixed = TRUE))
    }
}

# ===========================================================================
# 7. EVERY LEG THE DRIVER RENDERED IS LOOKED AT BY SOMETHING
# ===========================================================================
# Add a leg to bracketcap.sh and every assertion above keeps passing, because
# none of them was ever making a claim about anything outside itself. The
# census is the only line that can say the artefact grew and the checks did
# not.
if (have_tsv) {
    eml_census(ID, "bracketcap leg", legs$leg, ALL_LEGS)
    eml_claim(ID, "bracketcap", legs$leg)
}

# ===========================================================================
# 8. WHAT THIS CHANGE FOUND AND DID NOT CLOSE -- CLOSED, 16 AUGUST 2026
# ===========================================================================
# THE FINDING. A two-group bracket figure named no test anywhere on it. Both
# two-group arms of @emlBridgeGroupComparison composed .omnibus$ -- "Welch t:
# t(22.0) = -14.90, p < .001, d = -6.08" -- and handed it back for the Info
# window, and NEITHER set annotTextN. Only the k >= 3 arms did. So the form's
# post-dispatch stage had no omnibus line to route into the corner box, and
# the figure that left the session carried a bracket, a star triple and a
# Cohen's d with nothing saying what produced them. This file recorded it as
# an attestation, printed a NOTE beside it, and asserted nothing either way,
# because the remedy named two possible rulings and choosing between them was
# the author's call.
#
# THE RULING. Author ruling C, 16 August 2026, took BOTH remedies and refused
# the special case: every bracket-bearing figure names its test, k = 2
# included. The arms set annotTextN, so the corner box carries the test, AND
# they write a caption of their own stating one comparison and no adjustment.
# What that leaves this file asserting is spread over three sections rather
# than gathered here -- §2 for the source, §3 for the words, §4b for the
# corner box -- and the invariant itself, "every arm that can produce a
# bracket sets annotTextN", is validate/v76's, because it is a property of
# the ARMS and not of these eight figures.
#
# The attestation is gone rather than kept as history: an attestation is a
# standing claim that something is still true and unasserted, and neither half
# of that is true now. What replaces it is the check below, which is the
# attestation's own measurement turned the right way up.
if (have_tsv) {
    wt <- ""
    p_wt <- file.path(bdir, "welch_two.fig.ocr")
    if (file.exists(p_wt)) wt <- norm_ocr(paste(readLines(p_wt, warn = FALSE),
                                                collapse = " "))
    check_true(ID, "the finding of 16 Aug is closed: the whole two-group figure names its test",
               nzchar(wt) && grepl("Welch t", wt, fixed = TRUE))
}

# NOTES, NOT CHECKS. The byte counts are here so the size trap stays on the
# record: the caption band adds height and weight to every drawn leg, and
# nothing in this file thresholds on either.
if (have_tsv) {
    for (lg in DRAWN_LEGS) {
        p <- file.path(bdir, paste0(lg, ".png"))
        if (file.exists(p)) {
            cat(sprintf("NOTE  v69  %-16s %sx%s px, %d bytes, %s ink in band\n",
                        lg, lv(lg, "img_w"), lv(lg, "img_h"),
                        file.info(p)$size, lv(lg, "ink_px")))
        }
    }
}

if (!exists("EML_SUITE")) {
    eml_report("v69 bracket disclosure: what the bracket layout says about its post-hoc")
    eml_exit()
}
