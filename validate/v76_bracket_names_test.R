# ============================================================================
# v76_bracket_names_test.R -- EVERY BRACKET-BEARING FIGURE NAMES ITS TEST
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# THE RULING THIS FILE IMPLEMENTS (author ruling C, change order 9, 16 August
# 2026). @emlBridgeGroupComparison has four arms that can put a bracket on a
# figure: Welch's t and Mann-Whitney U at k = 2, one-way ANOVA with Tukey and
# Kruskal-Wallis with Dunn at k >= 3. All four compose an omnibus string --
# "Welch t: t(22.0) = -14.90, p < .001, d = -6.08" -- and hand it back to the
# caller for the Info window. Only the k >= 3 arms set annotTextN. So the
# graphs form's post-dispatch stage, which routes annotTextN into the corner
# block, had NO LINE TO ROUTE on a two-group figure, and the artefact that
# left the session carried a bracket, "***", a Cohen's d and nothing that
# said what produced them. The ruling is one invariant with no two-group
# special case: every bracket-bearing figure names its test.
#
# WHY THE INVARIANT IS THE SUBJECT AND NOT THE TWO ARMS THAT WERE FIXED. This
# is the second time this exact shape has been repaired one arm at a time.
# Ruling 1b (15 August) gave the MATRIX layout a sub-line naming the post-hoc
# and left the bracket layout silent; ruling 11 (16 August, validate/v69) gave
# the BRACKET layout a caption on the k >= 3 arms and left k = 2 silent, and
# recorded that fact as an attestation because closing it was a ruling. Each
# repair was correct and each left a neighbouring path saying nothing. A
# validator that asserted "welch_two names Welch's t-test" would be the third
# in that series: green, true, and blind to the fifth arm. So §2 ENUMERATES
# the arms out of the source -- every site that writes a bracket label -- and
# requires each one to set the corner line. An arm added later without a test
# name goes red without anybody remembering to add a check for it.
#
# ENUMERATING FROM THE SOURCE IS LEGITIMATE HERE AND WOULD NOT BE ANYWHERE
# ELSE, and the distinction is worth stating because most of this suite
# refuses to do it. "Every arm sets annotTextN" is a property OF THE SOURCE:
# the population is the set of arms, which exists only in the file, and no
# rendering can show that a fifth arm is missing a line because a fifth arm
# renders nothing. What a source reading CANNOT show is that the line reaches
# the picture, and that failure has already happened once in this exact
# neighbourhood -- v69's no_extent break composes a perfect caption, reports
# perfect measurements, and the words are cropped off the export by a viewport
# assertion after the last number is taken. So §3 and §4 read the words off
# two DRIVEN two-group figures with tesseract, and §4 does it for every leg
# that has a bracket rather than for the two the ruling named.
#
# THE DOMINANCE RULE, WHICH IS THE ONLY SUBTLE THING IN §2. A grep for
# "annotTextN = 1 appears somewhere in this arm" is satisfied by a line
# sitting inside the arm's `if .useMatrix` branch -- that is, by a build where
# the MATRIX layout names its test and the BRACKET layout, the one this
# ruling is about, does not. That is not a hypothetical and it is not taken on
# argument: text_n_in_matrix in the break rig moves the Welch arm's five lines
# into that branch, and an arm-scoped grep -- "is there an annotTextN = 1
# between this arm's test call and the next one" -- returns TRUE for all four
# arms on that tree, measured 16 August 2026, while §2 goes red on it and
# welch_two loses its corner box. So §2 parses the procedure into a block tree
# and asks a stricter question: is there an `annotTextN = 1` whose execution
# is IMPLIED by execution of the bracket-label write -- a statement at an
# enclosing level, in a block the bracket site sits inside. A sibling of the
# `if .useMatrix` construct qualifies; a statement inside one of its branches
# does not. The bridge contains no goto and no exitScript, checked in §2, so
# "the enclosing block ran" really does mean "this statement ran".
#
# WHAT THE OTHER VALIDATORS IN THIS NEIGHBOURHOOD DO NOT COVER.
#
#   - v69_bracket_disclosure.R owns the CAPTION under the frame -- which
#     post-hoc test drew the brackets and what was done about multiplicity --
#     and after ruling C it asserts the two-group captions too. It is a claim
#     about eight particular figures. It cannot say that the arms are all the
#     arms, and its §8 spent 16 August recording precisely that gap as an
#     attestation rather than a test.
#
#   - v66_draw_layer.R owns ruling 1b and is scoped to the MATRIX panel: its
#     legs force layoutMode 3, which leaves annotBracketN at zero, so no
#     bracket figure enters its universe.
#
#   - v29_figure_disclosure.R counts disclosures per DRAW PROCEDURE. The
#     corner block is written by the annotation bridge and drawn by
#     @emlGraphsPostDispatchAnnotations after the draw procedure has returned,
#     outside every population v29 counts.
#
#   - EVERY NUMERIC VALIDATOR. The statistics were right the whole time. A
#     validator that recomputes a t or a U cannot see that the figure carrying
#     it does not say which of the two it is.
#
# Input: harness/bracketcap/out/. $EML_BRACKETCAP_DIR overrides it and
#        $EML_ANNOT_SRC / $EML_FORM_SRC override the sources under test, so a
#        break test drives a COPY of the tree and the working tree is never
#        touched. Regenerate with:
#
#            bash harness/bracketcap/bracketcap.sh
#            Rscript validate/v76_bracket_names_test.R
#
# NOTHING HERE IS VALIDATED UNTIL IT HAS BEEN BROKEN. Both halves -- the
# enumeration and the rendered evidence -- were shown RED against deliberately
# broken COPIES of the tree. The breaks and their results are in
# harness/bracketcap/break_v76.sh and out/BREAKS_V76.tsv.
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

ID <- "v76"

src <- Sys.getenv("EML_ANNOT_SRC", unset = "")
if (!nzchar(src)) src <- repo_path(file.path("plugin", "graphs",
                                             "eml-annotation-procedures.praat"))
fsrc <- Sys.getenv("EML_FORM_SRC", unset = "")
if (!nzchar(fsrc)) fsrc <- repo_path(file.path("plugin", "graphs",
                                               "eml-graphs-form.praat"))
bdir <- Sys.getenv("EML_BRACKETCAP_DIR", unset = "")
if (!nzchar(bdir)) bdir <- repo_path(file.path("harness", "bracketcap", "out"))

tsv_path <- file.path(bdir, "BRACKETCAP.tsv")

have_src  <- file.exists(src)
have_form <- file.exists(fsrc)
have_tsv  <- file.exists(tsv_path)
check_true(ID, "the annotation bridge source is present", have_src)
check_true(ID, "the graphs form source is present", have_form)
check_true(ID, "harness/bracketcap has been driven", have_tsv)

# ---------------------------------------------------------------------------
# JOIN CONTINUATIONS, STRIP COMMENTS, THEN PARSE.
# ---------------------------------------------------------------------------
# Both halves are load-bearing and both have bitten this repository. The
# assignments below are written across a "..." continuation to stay inside the
# line budget, so a line-at-a-time reader sees the head of an assignment and
# never the sentence. And the file carries a long prose header about ruling C
# which quotes the very lines it explains -- an unstripped search finds the
# repair in the paragraph describing the repair, and would go on finding it
# after the code was deleted.
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
    norm[!grepl("^#", norm) & !grepl("^;", norm) & nzchar(norm)]
}

code  <- read_code(src)
fcode <- read_code(fsrc)

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
# THE BLOCK TREE. Praat has no braces and no indentation rule the interpreter
# enforces, so nesting is read off the keywords and NOT off leading spaces --
# a re-indent must not be able to change a verdict here.
#
# The convention: a statement inside `if X ... endif` is one deeper than the
# `if`, and `else`/`elsif`/`endif` sit at the SAME depth as their `if`. The
# whole procedure is required to come back to zero (§2), which is what makes
# the rest of the arithmetic trustworthy: an unbalanced parse would silently
# put every site at the wrong level and could only make the checks weaker.
# ---------------------------------------------------------------------------
OPENERS <- "^(if |for |while |repeat$)"
CLOSERS <- "^(endif$|endfor$|endwhile$|until )"
MIDDLES <- "^(else$|elsif )"

depths_of <- function(b) {
    d <- integer(length(b)); cur <- 0L
    for (k in seq_along(b)) {
        ln <- b[k]
        if (grepl(CLOSERS, ln)) cur <- cur - 1L
        d[k] <- if (grepl(MIDDLES, ln)) cur - 1L else cur
        if (grepl(OPENERS, ln)) cur <- cur + 1L
    }
    list(d = d, final = cur, ok = cur == 0L && all(d >= 0L))
}

body   <- proc_body_of(code, "emlBridgeGroupComparison")
parsed <- depths_of(body)
dep    <- parsed$d

# DOMINATORS OF A LINE: the statements whose execution is implied by that
# line's execution. Walk outward from the site; at each level, every statement
# in the enclosing block is a dominator, because reaching a statement nested
# inside that block means the block was entered. Then step out through the
# construct that opened the block and repeat. Statements in a SIBLING branch
# are never collected, which is the whole point -- an `annotTextN = 1` in the
# matrix branch does not dominate a bracket write in the else branch.
dominators <- function(idx) {
    if (!length(body) || idx < 1 || idx > length(body)) return(integer(0))
    out <- integer(0); cur <- idx; lvl <- dep[idx]
    guard <- 0L
    repeat {
        guard <- guard + 1L
        if (guard > 64L) break
        before <- which(seq_along(body) < cur & dep < lvl)
        after  <- which(seq_along(body) > cur & dep < lvl)
        lo <- if (length(before)) max(before) else 0L
        hi <- if (length(after))  min(after)  else length(body) + 1L
        rng <- seq_along(body)
        out <- c(out, rng[rng > lo & rng < hi & dep == lvl])
        if (lvl <= 0L || lo == 0L) break
        # Walk back from `else`/`elsif` to the `if` that opened the construct,
        # so the next level out is measured around the WHOLE construct rather
        # than around one of its branches.
        k <- lo
        hop <- 0L
        while (k >= 1L && grepl(MIDDLES, body[k]) && hop < 64L) {
            hop <- hop + 1L
            cand <- which(seq_along(body) < k & dep == dep[k] &
                          (grepl(OPENERS, body) | grepl(MIDDLES, body)))
            if (!length(cand)) break
            k <- max(cand)
        }
        cur <- k
        lvl <- lvl - 1L
    }
    sort(unique(out))
}

# ---------------------------------------------------------------------------
# THE DRIVEN ARTEFACT. One row per leg, written by harness/bracketcap.sh.
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

lv <- function(leg, key) {
    if (!nrow(legs)) return(NA_character_)
    r <- legs[legs$leg == leg, , drop = FALSE]
    if (!nrow(r)) return(NA_character_)
    as.character(r[[key]][1])
}
ln_ <- function(leg, key) suppressWarnings(as.numeric(lv(leg, key)))

kvget <- function(leg, key) {
    p <- file.path(bdir, paste0(leg, ".kv"))
    if (!file.exists(p)) return(NA_character_)
    x <- readLines(p, warn = FALSE)
    hit <- grep(paste0("^", key, "\t"), x, value = TRUE)
    if (!length(hit)) return(NA_character_)
    sub(paste0("^", key, "\t"), "", hit[1])
}

# OCR NORMALISATION, AND WHAT IT IS ALLOWED TO FORGIVE. tesseract renders the
# typographic apostrophe as ' or U+2019 and the dashes interchangeably; those
# are the reader's glyphs, not the plugin's claims. Nothing else is touched --
# case is preserved and the test NAMES, which are the whole value check, are
# compared exactly.
norm_ocr <- function(s) {
    if (length(s) != 1 || is.na(s)) return("")
    s <- gsub("’|‘|`", "'", s)
    s <- gsub("—|–", "-", s)
    gsub("\\s+", " ", trimws(s))
}

fig_ocr <- function(leg) {
    p <- file.path(bdir, paste0(leg, ".fig.ocr"))
    if (!file.exists(p)) return("")
    norm_ocr(paste(readLines(p, warn = FALSE), collapse = " "))
}

# THE TEST NAME OUT OF AN OMNIBUS LINE. Every omnibus string in the bridge is
# "<test>: <statistics>", so the name is what stands before the first colon.
# Taken from the artefact rather than written down here ON PURPOSE: §4 has to
# hold for a leg this file has never heard of, and a hardcoded map would go
# green on a new arm by never mentioning it. The literal names ARE written
# down, once, in §3, where two specific figures are the subject.
test_name_of <- function(label) {
    if (length(label) != 1 || is.na(label) || !nzchar(label)) return("")
    if (!grepl(":", label, fixed = TRUE)) return("")
    trimws(sub(":.*$", "", label))
}

# ===========================================================================
# 1. THE DRIVE RAN, AND IT RAN CLEAN
# ===========================================================================
# A leg that aborted mid-script writes no PNG, and every measurement after the
# abort reads empty -- which, without this, presents as a figure that simply
# does not name its test. NO_FIGURE and "named nothing" are different verdicts
# and only one of them is a finding about the plugin.
if (have_tsv) {
    check_true(ID, "the driven artefact has legs in it", nrow(legs) > 0)
    for (lg in legs$leg) {
        check_true(ID, sprintf("leg %s rendered without error", lg),
                   identical(lv(lg, "verdict"), "OK"))
    }
}

# ===========================================================================
# 2. THE INVARIANT, ENUMERATED OUT OF THE BRIDGE
# ===========================================================================
# THE INVARIANT IS UNCHANGED AND ITS PROOF MOVED, WHICH IS WHY THIS SECTION
# READS THREE PROCEDURES INSTEAD OF ONE.
#
# The claim has always been: a path that can put a BRACKET on a figure also
# puts the OMNIBUS in the corner box, and that omnibus opens with the name of
# the test which produced the bracket. Until the result store's read side
# landed, each of the four arms of @emlBridgeGroupComparison wrote its own
# bracket loop and its own corner box, so the claim was checked as a
# dominance argument inside one procedure: for every bracket-label write, is
# there an `annotTextN = 1` above it in an enclosing block?
#
# The store added a FIFTH path -- a figure drawn from a published result,
# which runs no arm at all -- and a fifth copy of the bracket loop is how that
# figure would have come to disagree with the same figure drawn from a re-run.
# So the loop is now ONE procedure, @emlBridgeRenderAnnotations, that every
# arm and the consume path call; and the omnibus sentence is one procedure,
# @emlBridgeOmnibusLine, for the same reason.
#
# THAT MAKES THE INVARIANT STRUCTURAL RATHER THAN REPEATED, and the checks
# follow it:
#
#   a. @emlBridgeRenderAnnotations holds exactly ONE bracket-label write, and
#      the corner box it sets is UNCONDITIONAL -- at the procedure's own
#      depth, below the layout branch, so it runs on the bracket layout and
#      the matrix layout alike. Dominance is then trivial rather than
#      argued: there is no path through that procedure which writes a bracket
#      and does not set the box.
#   b. NO OTHER PROCEDURE WRITES A BRACKET LABEL. That is what stops a fifth
#      copy reappearing and quietly escaping this section.
#   c. The bridge still has FOUR ARMS, enumerated the same way as before --
#      by the statistical procedure that dominates the call -- and each one
#      hands the renderer an omnibus it composed through
#      @emlBridgeOmnibusLine rather than a literal.
#   d. @emlBridgeOmnibusLine names FOUR DIFFERENT TESTS, each string opening
#      "<test>: ", which is the source half of "names its test" that §3 and
#      §4 read back off the picture.
BRACKET_SITE <- "^annotBracketLabel\\$\\[[^]]+\\] = "

arm_ids <- character(0)
if (have_src) {
    check_true(ID, "@emlBridgeGroupComparison is present and parses balanced",
               length(body) > 0 && parsed$ok)

    body_rend <- proc_body_of(code, "emlBridgeRenderAnnotations")
    body_omni <- proc_body_of(code, "emlBridgeOmnibusLine")
    check_true(ID, "@emlBridgeRenderAnnotations is present",
               length(body_rend) > 0)
    check_true(ID, "@emlBridgeOmnibusLine is present",
               length(body_omni) > 0)

    # THE DOMINANCE ARGUMENT DEPENDS ON THERE BEING NO EARLY EXIT. A goto or
    # an exitScript between the annotTextN line and the end of the procedure
    # would make "the enclosing block ran" stop implying "this statement ran",
    # and every check below would be measuring a control-flow graph the file
    # does not have.
    check_true(ID, "the bridge has no goto, label or exitScript to jump over the invariant",
               !has(body, "^goto ") && !has(body, "^label ") &&
               !has(body, "exitScript"))
    check_true(ID, "nor does the renderer the arms hand their result to",
               !has(body_rend, "^goto ") && !has(body_rend, "^label ") &&
               !has(body_rend, "exitScript"))

    # ---- (a) ONE BRACKET SITE, AND AN UNCONDITIONAL BOX -------------------
    rend_parsed <- depths_of(body_rend)
    rend_sites <- grep(BRACKET_SITE, body_rend)
    check_true(ID, sprintf("the renderer holds exactly one bracket-label write (found %d)",
                           length(rend_sites)),
               length(rend_sites) == 1)

    # "Unconditional" is depth 0 in the procedure's own body: outside the
    # layout branch and outside both pair loops, so neither the choice of
    # layout nor the presence of a significant pair can skip it.
    box_lines <- list(
        "annotTextN"        = "^annotTextN = 1$",
        "annotTextLabel$[1]" = "^annotTextLabel\\$\\[1\\] = \\.omnibus\\$$",
        "annotTextX[1]"     = "^annotTextX\\[1\\] = ",
        "annotTextY[1]"     = "^annotTextY\\[1\\] = ",
        "annotTextAnchor$[1]" = "^annotTextAnchor\\$\\[1\\] = ")
    for (nm in names(box_lines)) {
        at <- grep(box_lines[[nm]], body_rend)
        check_true(ID,
            sprintf("the renderer sets %s at its own depth, so no layout can skip it",
                    nm),
            length(at) >= 1 && rend_parsed$ok && any(rend_parsed$d[at] == 0L))
    }

    # ---- (b) AND NOWHERE ELSE ---------------------------------------------
    # Counted over the WHOLE annotation file, not over one procedure: a fifth
    # copy of the bracket loop would most likely arrive as a new procedure,
    # and that is exactly the shape this line refuses.
    check_true(ID,
        sprintf("no other procedure in the file writes a bracket label (%d file-wide)",
                length(grep(BRACKET_SITE, code))),
        length(grep(BRACKET_SITE, code)) == 1)
    check_true(ID, "and @emlBridgeGroupComparison no longer writes one itself",
               length(grep(BRACKET_SITE, body)) == 0)

    # ---- (c) FOUR ARMS, ENUMERATED THE SAME WAY ---------------------------
    # The population is every site in the bridge that hands a result to the
    # renderer. Each arm is NAMED by the statistical procedure that dominates
    # it, so a failure below says "the Mann-Whitney arm" rather than "line
    # 92". The name is read out of the source, not out of a list kept here: a
    # fifth arm calling a fifth procedure names itself.
    #
    # THE CONSUME PATH IS IN THIS POPULATION AND HAS NO TEST CALL ABOVE IT,
    # which is the point of it -- it runs no test. It is therefore named
    # "arm@<line>" by the fallback below and is EXCLUDED from the four-arm
    # census, and its own behaviour is measured by harness/bridgeconsume.
    TESTCALL <- "^@(eml[A-Za-z]+):.*$"
    KNOWN_TESTS <- c("emlTTest", "emlRankBiserialR", "emlOneWayAnova",
                     "emlKruskalWallis")
    callee <- function(x) ifelse(grepl(TESTCALL, x), sub(TESTCALL, "\\1", x), "")

    sites <- grep("^@emlBridgeRenderAnnotations:", body)
    check_true(ID, sprintf("every path that annotates goes through the one renderer (%d call sites)",
                           length(sites)),
               length(sites) >= 5)

    for (s in sites) {
        dom <- dominators(s)
        tc  <- dom[callee(body[dom]) %in% KNOWN_TESTS]
        if (!length(tc)) next
        arm <- callee(body[tc[length(tc)]])
        arm_ids <- c(arm_ids, arm)

        # THE ARM HANDS OVER THE OMNIBUS IT COMPOSED, not a literal and not
        # whatever was left in .omnibus$ by the last figure. A constant here
        # would name the test and say nothing true about the data -- and it
        # would survive every OCR check in §3 and §4, which look for the test
        # NAME.
        om <- dom[grepl("^\\.omnibus\\$ = emlBridgeOmnibusLine\\.result\\$$",
                        body[dom])]
        check_true(ID, sprintf("%s: the arm composes its omnibus through @emlBridgeOmnibusLine",
                               arm),
                   length(om) >= 1)

        # AND IT FED THAT COMPOSER THE STATISTICS IT JUST COMPUTED. The
        # composer takes five numbers; an arm that called it without naming
        # them would be quoting the previous arm's omnibus.
        oc <- dom[grepl("^@emlBridgeOmnibusLine:", body[dom])]
        check_true(ID, sprintf("%s: and calls the composer inside the same block", arm),
                   length(oc) >= 1)
        for (fld in c("\\.omniStat = ", "\\.omniP = ")) {
            check_true(ID,
                sprintf("%s: the arm names %s for the composer and the store",
                        arm, sub("\\\\\\.", ".", sub(" = $", "", fld))),
                any(grepl(paste0("^", fld), body[dom])))
        }
    }

    check_true(ID, sprintf("the bridge has four bracket-producing arms (found %d)",
                           length(arm_ids)),
               length(arm_ids) == 4)

    # ---- (d) FOUR TESTS, NAMED IN THE COMPOSER ----------------------------
    # Every omnibus string in the plugin is "<test>: <statistics>", and this
    # is the one place the four are written. Read out of the source rather
    # than listed here, for the reason §4's note gives: a hardcoded map goes
    # green on a new arm by never mentioning it.
    omni_lits <- grep("^\\.result\\$ = \"[^\"]+: ", body_omni, value = TRUE)
    omni_names <- unique(trimws(sub("^\\.result\\$ = \"([^\":]+):.*$", "\\1",
                                    omni_lits)))
    check_true(ID, sprintf("@emlBridgeOmnibusLine names four tests (%s)",
                           paste(omni_names, collapse = ", ")),
               length(omni_names) == 4 && all(nzchar(omni_names)) &&
               all(grepl("[A-Za-z]", omni_names)))

    # NO ARM IS COUNTED TWICE. Four sites naming four distinct tests is what
    # makes the enumeration a census rather than one arm found four times --
    # and it is how a copy-paste of an existing arm, which is how a fifth arm
    # would most likely arrive, shows up here.
    check_true(ID, sprintf("the four arms are four different tests (%s)",
                           paste(arm_ids, collapse = ", ")),
               length(unique(arm_ids)) == length(arm_ids))
    check_true(ID, "the enumerated arms are the two-group pair and the k >= 3 pair",
               setequal(arm_ids, c("emlTTest", "emlRankBiserialR",
                                   "emlOneWayAnova", "emlKruskalWallis")))
}

# ===========================================================================
# 2b. THE SEAM: THE FORM ROUTES THE LINE, AND IT DOES NOT ASK HOW MANY GROUPS
# ===========================================================================
# The bridge setting annotTextN is worth nothing unless the form moves it into
# the corner block. That route is one `if annotTextN > 0` inside
# @emlGraphsPostDispatchAnnotations, and it is asserted here because the whole
# ruling rests on it being unconditional in the group count: a route gated on
# k >= 3 would be a second place to write the special case the ruling refuses,
# and the two-group figures would go silent again with the bridge still
# correct.
if (have_form) {
    body_pd <- proc_body_of(fcode, "emlGraphsPostDispatchAnnotations")
    check_true(ID, "@emlGraphsPostDispatchAnnotations is present",
               length(body_pd) > 0)
    check_true(ID, "the omnibus line is routed into the corner block",
               has(body_pd, "^annotBlockLabel\\$\\[annotBlockN\\] = annotTextLabel\\$\\[1\\]$") &&
               has(body_pd, "^annotBlockDraw\\$\\[annotBlockN\\] = annotTextLabel\\$\\[1\\]$"))
    check_true(ID, "the route is gated on there being a line, and on nothing else",
               has(body_pd, "^if annotTextN > 0$"))
    check_true(ID, "the post-dispatch stage never branches on the group count",
               !has(body_pd, "nGroups") && !has(body_pd, "annotMatrixN = 2"))
    # And the line is consumed, so it cannot be drawn twice by a second pass
    # over the same figure -- the legend-headroom loop is exactly such a pass
    # (author ruling B, validate/v75).
    check_true(ID, "the routed line is consumed so a second pass cannot redraw it",
               has(body_pd, "^annotTextN = 0$"))
}

# ===========================================================================
# 3. THE TWO-GROUP FIGURES, READ OFF THE PICTURE
# ===========================================================================
# §2 proves the source sets the line. This proves it arrives. The evidence is
# tesseract's reading of the region ABOVE the caption band -- the frame -- of
# two figures driven through the shipped @emlGraphsPostDispatchAnnotations,
# and the earlier bug in this neighbourhood is exactly the reason it is not
# taken on the source's word: a string composed correctly and then drawn
# outside the exported region is indistinguishable, in every Praat variable,
# from one that is there.
#
# The expected names are LITERALS here. Nothing in the expectation is derived
# from the artefact it is checked against, and the two legs differ only in the
# test, so a build that names one test on both figures fails one of them.
TWO_GROUP <- c(welch_two = "Welch t", mw_two = "Mann-Whitney")
if (have_tsv) {
    for (lg in names(TWO_GROUP)) {
        # THE FIGURE HAS A BRACKET ON IT. Without this the two checks below
        # are satisfied by a figure with no p-values at all, which is the one
        # case the invariant does not govern -- and it is reachable by
        # accident: a non-significant comparison with showNS off sets
        # annotBracketN back to 0 inside the same arm.
        check_true(ID, sprintf("leg %s: the figure carries a bracket", lg),
                   identical(lv(lg, "bracket_n"), "1"))

        # THE BRIDGE COMPOSED A LINE, read from the .kv BEFORE the form
        # consumed it.
        tl <- kvget(lg, "text_label")
        check_true(ID, sprintf("leg %s: the bridge composed a corner line", lg),
                   identical(kvget(lg, "text_n"), "1") &&
                   !is.na(tl) && nzchar(tl))

        # AND THE TEST NAME IS ON THE FIGURE. Read off the frame, not the
        # caption band: the band is v69's subject, and a caption naming the
        # test would satisfy a whole-image search while the corner box stayed
        # empty.
        got <- fig_ocr(lg)
        check_true(ID, sprintf("leg %s: the frame names the test ('%s')",
                               lg, TWO_GROUP[[lg]]),
                   nzchar(got) && grepl(TWO_GROUP[[lg]], got, fixed = TRUE))

        # THE NAME ON THE PICTURE IS THE ONE THE BRIDGE COMPOSED. Pins the two
        # sides to each other rather than each to a constant: a figure drawn
        # from a stale global would still carry A test name, and it would be
        # the previous figure's.
        check_true(ID, sprintf("leg %s: the drawn name is the one the bridge composed", lg),
                   identical(test_name_of(tl), TWO_GROUP[[lg]]))
    }

    # THE TWO FIGURES DO NOT NAME THE SAME TEST. A repair that set annotTextN
    # from one shared string -- or an arm that read the other arm's
    # .omnibus$ -- passes every line above and is wrong on one of the two.
    check_true(ID, "the two two-group figures name different tests",
               !identical(test_name_of(kvget("welch_two", "text_label")),
                          test_name_of(kvget("mw_two", "text_label"))))

    # AND NEITHER NAMES THE OTHER'S. Asserted in the negative as well, because
    # "different" is satisfied by two figures that have swapped.
    check_true(ID, "no two-group figure carries the other arm's test",
               !grepl("Mann-Whitney", fig_ocr("welch_two"), fixed = TRUE) &&
               !grepl("Welch", fig_ocr("mw_two"), fixed = TRUE))
}

# ===========================================================================
# 4. THE INVARIANT ON EVERY DRIVEN FIGURE THAT HAS A BRACKET
# ===========================================================================
# §3 names two legs. This section names none: it takes every leg the harness
# rendered, keeps the ones with at least one bracket, and requires each to
# carry, in its frame, the test name out of its OWN emitted omnibus line.
# Nothing here knows what tests exist. Add a leg driving a fifth arm and this
# section covers it on the first run; hardcode a map instead and the fifth
# leg is silently exempt, which is the failure mode this whole file is a
# reaction to.
BRACKET_LEGS <- character(0)
if (have_tsv && nrow(legs)) {
    bn <- suppressWarnings(as.numeric(legs$bracket_n))
    BRACKET_LEGS <- legs$leg[is.finite(bn) & bn > 0]

    # A VACUITY GUARD, AND IT IS NOT OPTIONAL. Every check in the loop below
    # is over an empty set if bracket_n is unreadable or every leg drew
    # nothing -- and an empty loop is green. The harness renders five k >= 3
    # bracket legs and two two-group ones.
    check_true(ID, sprintf("the harness rendered bracket-bearing figures to check (%d)",
                           length(BRACKET_LEGS)),
               length(BRACKET_LEGS) >= 7)

    for (lg in BRACKET_LEGS) {
        tl   <- kvget(lg, "text_label")
        name <- test_name_of(tl)
        check_true(ID, sprintf("leg %s: the bridge composed a named omnibus ('%s')",
                               lg, name),
                   nzchar(name))
        check_true(ID, sprintf("leg %s: the corner line is anchored, so it is placed not defaulted", lg),
                   identical(kvget(lg, "text_anchor"), "right"))
        check_true(ID, sprintf("leg %s: the figure names its test ('%s')", lg, name),
                   nzchar(name) && grepl(name, fig_ocr(lg), fixed = TRUE))
    }
}

# ===========================================================================
# 5. WHERE THE INVARIANT DOES NOT REACH, ASSERTED SO THE SWEEP IS BOUNDED
# ===========================================================================
# "Every bracket-bearing figure names its test" is not "every figure carries a
# statistics box". ns_omnibus draws no brackets at all -- the omnibus did not
# reject, no post-hoc ran -- and it still carries its omnibus line, which it
# did before this ruling and must go on doing: the ruling adds a case, it does
# not move the existing one. Asserted here so that a repair which reached the
# figure by drawing the box unconditionally is visible as the over-sweep it
# would be.
if (have_tsv) {
    check_true(ID, "a figure with no brackets is outside the invariant",
               identical(lv("ns_omnibus", "bracket_n"), "0"))
    check_true(ID, "and it still carries its own omnibus line",
               grepl("One-way ANOVA", fig_ocr("ns_omnibus"), fixed = TRUE))
}

# ===========================================================================
# 6. COVERAGE
# ===========================================================================
# The arm census is the one that matters and it is made against the source
# population §2 read, not against a list written here. The leg claim is
# recorded for the suite-wide coverage pass; v69 claims the same artefact and
# the overlap is deliberate -- the two files ask different questions of the
# same eight figures.
if (have_src) {
    eml_census(ID, "bracket-producing bridge arm", arm_ids, arm_ids)
}
if (have_tsv && nrow(legs)) {
    eml_claim(ID, "bracketcap", c(BRACKET_LEGS, "ns_omnibus"))
    for (lg in BRACKET_LEGS) {
        cat(sprintf("NOTE  v76  %-16s brackets=%-2s corner line: %s\n",
                    lg, lv(lg, "bracket_n"), kvget(lg, "text_label")))
    }
}

if (!exists("EML_SUITE")) {
    eml_report("v76 bracket names test: every bracket-bearing figure names its test")
    eml_exit()
}
