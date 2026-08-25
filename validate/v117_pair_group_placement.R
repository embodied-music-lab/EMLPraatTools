# ============================================================================
# v117_pair_group_placement.R -- a two-box numeric row sits under the heading
# that tells the suite what it is, and a range filed anywhere else goes red
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# ============================================================================
# THE GAP THIS CLOSES, AS MEASURED ON 24 AUGUST 2026
# ============================================================================
#
# v84_axis_refusal.R makes the max-below-min refusal extend itself. It does
# that by deriving the roster of axis pairs FROM THE DIALOGS rather than from
# a list: every quantity for which the form renders a `left` box and a `right`
# box UNDER THE AXES HEADING must be named to the refusal sweep, so an eighth
# axis added next year joins the roster the moment its two fields exist and
# turns v84 red until the sweep judges it. That is the property, and it is a
# good one.
#
# It rests entirely on the heading. A pair filed under a DIFFERENT heading --
# the layout group, the page group, anything -- is not in the roster, is
# therefore not required to be named to the refusal, and therefore is not
# refused when its maximum is below its minimum. The user gets the silent
# rewrite v84's header describes: a floor of 300 comes back as a ceiling of
# 300, on a figure that looks like a figure.
#
# THIS WAS DRIVEN, NOT INFERRED. A range pair was planted under the layout
# group and ALL TWENTY-FIVE checks that read the graphs form were run against
# it. Nothing objected. The only lines that moved were the photographed
# transcripts' source digests, which move for any edit at all and so are not a
# detector of this or of anything else. v84's own header now names the gap
# instead of claiming the page-composition checks cover it.
#
# ============================================================================
# THE PROPERTY, AND WHY IT IS NOT A LIST OF EXCEPTIONS
# ============================================================================
#
# The obvious repair is a list: "these pairs are allowed to sit outside the
# axis group." This repository has watched that shape go stale more than once
# -- the next exception is added by whoever trips over it, the list stops
# being read, and the extension property it was protecting dies quietly. So
# the question had to be answered instead: WHAT SEPARATES A LEGITIMATE
# NON-AXIS PAIR FROM A MISFILED RANGE?
#
# It is the parenthetical, and the reason it works is geometric rather than
# lexical. RULING_DIALOG_LABELS_v3, heading pattern: "With the heading
# carrying 'both 0 = auto', each range row carries its orientation only:
# `Time (left/right)`, `Value (bottom/top)`." An axis range row's two boxes
# are THE TWO ENDS OF A DIRECTION ON THE PAGE, and its parenthetical says
# which direction. A picture has two directions and each has two ends. There
# is no third orientation to add next year, which is exactly what an
# allow-list cannot say about itself.
#
# The pairs that legitimately are not axes fail that test for a reason a
# reader can state, not because they were excused:
#
#   Figure size (w x h, inches)   two DIMENSIONS of one rectangle
#   Panel origin (x/y, inches)    two COORDINATES of one point
#   Pitch (floor/ceiling, Hz)     the two ends of an ANALYSIS SEARCH RANGE,
#                                 which is not drawn and has no direction on
#                                 the page. @emlGraphsPitchRangeRefusal judges
#                                 it beside the axis sweep rather than inside
#                                 it, and its header says why.
#
# None of the three names a direction, because none of them IS one. Measured
# on the tree the day this file was written: 23 paired numeric rows, 20 with
# an orientation parenthetical and 20 under the axes heading -- the same 20,
# in both directions, with no residue.
#
# SO THE RULE IS A BICONDITIONAL, not a permission. Orientation parenthetical
# if and only if axis heading. Both halves are load-bearing:
#
#   RULE A  an orientation row NOT under the axis heading is the gap above:
#           a range that escapes the roster and therefore the refusal.
#   RULE B  a non-orientation row UNDER the axis heading is the same failure
#           from the other side: it joins the roster and makes v84 demand
#           that a thing which is not an axis be named to the axis refusal.
#
# ============================================================================
# THE RESIDUE, NAMED HONESTLY, AND WHAT IS DONE ABOUT IT
# ============================================================================
#
# A biconditional over the parenthetical is defeated by a pair that is a range
# AND departs from the ruled grammar -- `left Value (min/max)` filed under the
# layout group. Rule A does not see it, because it does not name a direction.
# That residue is real and is not argued away.
#
# RULE C closes most of it WITHOUT A LIST, by reading the tree rather than a
# vocabulary: the nouns that name axis pairs under the axis heading are
# RESERVED. `Value`, `Time`, `Frequency`, `X` are axis quantities on nine
# pages; a two-box row calling itself `Value` under any other heading is
# either the same quantity in the wrong group or a second meaning for a name
# the form already spends, and both are red. The reserved set is DERIVED from
# the axis rows themselves, so an eighth axis noun reserves itself the day it
# is added and nobody edits anything.
#
# WHAT IS LEFT AFTER RULE C, stated plainly rather than covered: a pair that
# is a range, carries a noun no axis has ever used, and words its
# parenthetical outside the ruled grammar. At that point nothing the user
# reads and nothing the label says identifies it as a range, and no
# source-level witness short of following its two numbers into the draw layer
# can call it one. That is a different defect -- a row that does not say what
# it is -- and it is v98_field_names.R's and the dead-controls ruling's
# subject, not this file's. It is recorded here so the next reader knows the
# boundary was measured and not overlooked.
#
# RULE D is the ruling this file enforces the consequences of.
# RULING_LAYOUT_GROUPS rule 1: no field renders outside a named group. For a
# paired numeric row that rule is not housekeeping -- a pair with no heading
# above it on its page is in NEITHER class, so both halves of the
# biconditional are vacuous for it and it escapes exactly as a misfiled pair
# does. A pair rendering under no group at all is therefore red here too.
#
# ============================================================================
# WHAT A HEADING IS -- ONE CANON, IMPORTED
# ============================================================================
#
# This check and v84's roster must agree about what closes a group, or a pair
# can be inside the roster and outside this file at the same time, which is
# the gap again wearing a different hat. The icon list is therefore IMPORTED
# from v84_axis_refusal.R, which owns it, by the same partial-evaluation door
# v113 uses on v98. A rename there gives one red check here naming what
# disappeared, rather than a silent zero.
#
# Two properties of that canon are relied on and are v84's, not this file's:
# the icons are matched AS BYTES (the tree is UTF-8 and R reads it without
# declaring an encoding, so a character-escape pattern matches nothing on a
# machine whose locale is not UTF-8 -- silently), and the current heading
# RESETS AT EACH PAGE, because a group cannot reach across a beginPause into
# the next dialog. The labels sub-heading is not in the list and does not
# close the axis group, per RULING_LAYOUT_GROUPS rule 3.
#
# ============================================================================
# THE REFUTATION
# ============================================================================
#
# A check whose subject is "nothing is misfiled" passes on a tree with no
# pairs in it at all, so this file is built to be able to fail:
#
#   THE WALK IS COUNTED AND THE COUNT IS ASSERTED. Zero paired rows examined
#   is RED, not green, and the number walked is printed on the check line
#   whether it passes or fails.
#   BOTH CLASSES MUST BE OCCUPIED. A classifier that answers "axis" to
#   everything and one that answers "not an axis" to everything both satisfy
#   a biconditional over an empty class. Twenty and three today.
#   THREE SEEDED VIOLATIONS ARE PLANTED AND CAUGHT, through EML_DIALOG_SRC --
#   the door v98's red demonstrations use -- so what is shown red is this
#   file's own machinery over a copy of the shipped tree, not a rehearsal of
#   it written by hand:
#
#     SEED A  a `left/right Value (bottom/top)` pair inserted under the
#             layout heading. This is the planted pair the 25 checks missed.
#             Rule A.
#     SEED B  the same pair labelled `(min/max)` instead. Rule A cannot see
#             it; rule C does, because `Value` is an axis noun. This is the
#             residue paragraph above, demonstrated rather than asserted.
#     SEED C  the pitch group's icon changed to the axis icon, which files an
#             analysis search range in the axis roster. Rule B.
#
#   Each seed is also asserted ABSENT from the shipped tree, so a seed that
#   silently failed to apply cannot pass for a catch.
#
# Input:  the plugin dialog source     ($EML_DIALOG_SRC overrides, per v98)
# Reads:  validate/v84_axis_refusal.R  (the group-heading icon canon)
# Rulings: docs/RULING_LAYOUT_GROUPS.md rules 1 and 3,
#          docs/RULING_DIALOG_LABELS_v3.md (row patterns, heading pattern)
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

ID <- "v117"

# ---------------------------------------------------------------------------
# THE TWO IMPORTS, AND THE GATE, BEFORE THE FIRST USE
#
# Asserted here rather than at the foot of the file for v113's reason: an
# error reaching run_all.R's handler aborts the whole suite and reports
# nothing about the other validators, while a gate at the top turns a rename
# into ONE red check that names what went missing.
# ---------------------------------------------------------------------------
V84_FILE <- repo_path("validate", "v84_axis_refusal.R")
V98_FILE <- repo_path("validate", "v98_field_names.R")

import_from <- function(path, want) {
    e <- new.env(parent = globalenv())
    if (file.exists(path)) {
        for (x in parse(path)) {
            if (is.call(x) && length(x) >= 3L &&
                identical(as.character(x[[1]]), "<-")) {
                nm <- as.character(x[[2]])
                if (length(nm) == 1L && nm %in% want) try(eval(x, e), silent = TRUE)
            }
        }
    }
    e
}

V84 <- import_from(V84_FILE, ".icons")
V98 <- import_from(V98_FILE, "plugin_files")

have_icons <- exists(".icons", envir = V84, inherits = FALSE)
ICONS <- if (have_icons) get(".icons", envir = V84) else character(0)
AXIS_ICON <- "\U0001F4D0"

check_true(ID,
           sprintf("the group-heading icon canon imports from v84 (%d icons)",
                   length(ICONS)),
           have_icons && length(ICONS) >= 2L)
check_true(ID, "the axis icon is one of them",
           AXIS_ICON %in% ICONS)
check_true(ID, "the EML_DIALOG_SRC door imports from v98",
           exists("plugin_files", envir = V98, inherits = FALSE) &&
               is.function(get("plugin_files", envir = V98)))

# ---------------------------------------------------------------------------
# THE WALK
#
# A PAIRED NUMERIC ROW is a numeric field whose label begins `left ` whose
# IMMEDIATELY FOLLOWING FIELD DECLARATION is a numeric field whose label
# begins `right ` with the same pre-parenthetical noun. Adjacency is not a
# convenience: Praat renders the two boxes on one row only when the fields are
# adjacent, so a pair separated by anything is not a pair on the screen either.
#
# The four numeric declarators are all of them; a text pair has no ordering
# and no maximum to fall below a minimum, so `sentence:` pairs -- the axis
# LABELS row -- are correctly outside this population and would otherwise
# fail rule B on every page.
# ---------------------------------------------------------------------------
NUM_RE   <- '^[[:space:]]*(real|positive|integer|natural): *"(left|right) ([^"]*)"'
FIELD_RE <- paste0("^[[:space:]]*(real|positive|integer|natural|word|sentence|",
                   "text|boolean|choice|optionmenu|comment|infile|outfile|",
                   "folder): ")
PAGE_RE  <- "^[[:space:]]*(beginPause|form):"

# The heading as a reader can quote it back. Non-ASCII bytes are dropped
# rather than printed: the icon is bytes on disk and R holds it as bytes, so
# printing it raw puts octal escapes in the report on exactly the machines
# the byte-matching above exists for. The ASCII remainder identifies the group
# unambiguously on every page of this form.
ascii_of <- function(s)
    trimws(gsub(" +", " ", gsub("[^ -~]", "", s, useBytes = TRUE)))

heading_text <- function(line) {
    t <- sub('^[^"]*"', "", line)
    t <- sub('"[^"]*$', "", t)
    ascii_of(t)
}

noun_of  <- function(lab) trimws(sub("\\(.*$", "", lab))
paren_of <- function(lab) {
    if (!grepl("(", lab, fixed = TRUE)) return("")
    trimws(sub("\\).*$", "", sub("^[^(]*\\(", "", lab)))
}
# ORIENTATION: the parenthetical OPENS with the two ends of one of the page's
# two directions. Opens, not equals, so `(bottom/top, dB)` is still an axis
# row; the boundary character stops `bottom/topology` counting as one.
is_orientation <- function(p)
    grepl("^(left/right|bottom/top)($|[^A-Za-z0-9/])", p)

walk_pairs <- function(files) {
    rows <- list(); n_head <- 0L; n_field <- 0L
    lone <- character(0)
    for (p in files) {
        src <- readLines(p, warn = FALSE)
        keep <- !grepl("^[[:space:]]*[#;!]", src)
        code <- src[keep]; ln <- which(keep)
        if (!length(code)) next
        hit <- grep(NUM_RE, code)
        if (!length(hit)) next

        head_at <- Reduce(`|`, lapply(ICONS, function(ic)
            grepl(paste0('comment: "', ic), code, fixed = TRUE, useBytes = TRUE)))
        axis_at <- grepl(paste0('comment: "', AXIS_ICON), code,
                         fixed = TRUE, useBytes = TRUE)
        page_at <- grepl(PAGE_RE, code)

        cur <- NA_character_; cur_ax <- NA
        htxt <- rep(NA_character_, length(code))
        hax  <- rep(NA, length(code))
        for (k in seq_along(code)) {
            if (page_at[k]) { cur <- NA_character_; cur_ax <- NA }
            if (head_at[k]) {
                cur <- heading_text(code[k]); cur_ax <- axis_at[k]
                n_head <- n_head + 1L
            }
            htxt[k] <- cur; hax[k] <- cur_ax
        }

        fld <- grep(FIELD_RE, code)
        n_field <- n_field + length(hit)
        m <- regmatches(code[hit], regexec(NUM_RE, code[hit]))
        side <- vapply(m, `[`, "", 3L)
        labl <- vapply(m, `[`, "", 4L)

        for (j in seq_along(hit)) {
            i <- hit[j]
            if (!identical(side[j], "left")) {
                # A right half whose predecessor field is not its left half is
                # a lone box wearing a pairing cue. Reported, never silent.
                prev <- fld[fld < i]
                ok <- length(prev) && (prev[length(prev)] %in% hit) &&
                    identical(side[match(prev[length(prev)], hit)], "left") &&
                    identical(noun_of(labl[match(prev[length(prev)], hit)]),
                              noun_of(labl[j]))
                if (!ok) lone <- c(lone, sprintf("%s:%d  right %s",
                                                 basename(p), ln[i], labl[j]))
                next
            }
            nxt <- fld[fld > i]
            nxt <- if (length(nxt)) nxt[1] else NA_integer_
            partner <- if (!is.na(nxt) && nxt %in% hit) match(nxt, hit) else NA_integer_
            if (is.na(partner) || !identical(side[partner], "right") ||
                !identical(noun_of(labl[partner]), noun_of(labl[j]))) {
                lone <- c(lone, sprintf("%s:%d  left %s",
                                        basename(p), ln[i], labl[j]))
                next
            }
            rows[[length(rows) + 1L]] <- data.frame(
                file = basename(p), line = ln[i], line2 = ln[nxt],
                noun = noun_of(labl[j]), paren = paren_of(labl[j]),
                heading = if (is.na(htxt[i])) "" else htxt[i],
                grouped = !is.na(htxt[i]),
                axis_group = isTRUE(hax[i]),
                stringsAsFactors = FALSE)
        }
    }
    d <- if (length(rows)) do.call(rbind, rows) else
        data.frame(file = character(0), line = integer(0), line2 = integer(0),
                   noun = character(0), paren = character(0),
                   heading = character(0), grouped = logical(0),
                   axis_group = logical(0), stringsAsFactors = FALSE)
    if (nrow(d)) d$orientation <- is_orientation(d$paren) else d$orientation <- logical(0)
    list(pairs = d, n_head = n_head, n_field = n_field, lone = lone,
         n_files = length(files))
}

# The four rules, over any walk. The shipped tree and the seeded copies go
# through the SAME function, so a rule that stops firing on the tree stops
# firing on the demonstrations too.
faults <- function(w) {
    d <- w$pairs
    where <- function(r) sprintf('"%s (%s)" %s:%d under [%s], %s group',
                                 r$noun, ascii_of(r$paren), r$file, r$line,
                                 if (nzchar(r$heading)) r$heading else "NO HEADING",
                                 if (r$axis_group) "AXIS" else "non-axis")
    ax_nouns <- unique(d$noun[d$orientation & d$axis_group])
    a <- if (nrow(d)) d[d$orientation & !d$axis_group, , drop = FALSE] else d
    b <- if (nrow(d)) d[!d$orientation & d$axis_group, , drop = FALSE] else d
    cc <- if (nrow(d)) d[!d$axis_group & d$noun %in% ax_nouns, , drop = FALSE] else d
    dd <- if (nrow(d)) d[!d$grouped, , drop = FALSE] else d
    f <- function(x) if (nrow(x)) vapply(seq_len(nrow(x)),
                                         function(i) where(x[i, ]), "") else character(0)
    list(A = f(a), B = f(b), C = f(cc), D = f(dd), ax_nouns = sort(ax_nouns))
}

named <- function(v) if (length(v)) paste0(" -- ", paste(v, collapse = "; ")) else ""

# ---------------------------------------------------------------------------
# THE SHIPPED TREE
# ---------------------------------------------------------------------------
FILES <- tryCatch(get("plugin_files", envir = V98)(), error = function(e) character(0))
W <- walk_pairs(FILES)
D <- W$pairs
F0 <- faults(W)

if (nrow(D)) {
    cat("\nPAIRED NUMERIC ROWS, AS CLASSIFIED (", nrow(D), " rows, ",
        W$n_files, " source files)\n", sep = "")
    show <- data.frame(noun = D$noun, parenthetical = ascii_of(D$paren),
                       class = ifelse(D$orientation, "axis range", "not a range"),
                       group = ifelse(D$axis_group, "AXIS", "other"),
                       heading = D$heading, at = sprintf("%s:%d", D$file, D$line),
                       stringsAsFactors = FALSE)
    print(show, row.names = FALSE, right = FALSE)
    cat("\n")
}

# THE COUNT IS THE VACUITY GATE. Zero pairs walked is red, and the number is
# on the line whether it passes or fails.
check_true(ID,
           sprintf("the sweep walked %d paired numeric rows from %d left/right fields across %d source files, under %d group headings",
                   nrow(D), W$n_field, W$n_files, W$n_head),
           nrow(D) > 0L && W$n_head > 0L)

# AND BOTH ANSWERS MUST BE OCCUPIED. A classifier with one empty class
# satisfies the biconditional without deciding anything.
check_true(ID,
           sprintf("the classifier separates both ways: %d axis-range rows, %d that are not [%s]",
                   sum(D$orientation), sum(!D$orientation),
                   paste(sprintf("%s (%s)", unique(D$noun[!D$orientation]),
                                 ascii_of(D$paren[!D$orientation])),
                         collapse = ", ")),
           any(D$orientation) && any(!D$orientation))

check_true(ID,
           sprintf("the axis nouns the roster is derived from [%s]",
                   paste(F0$ax_nouns, collapse = ", ")),
           length(F0$ax_nouns) > 0L)

check_true(ID,
           sprintf("RULE A -- every axis range row renders under the axis heading%s",
                   named(F0$A)),
           length(F0$A) == 0L)
check_true(ID,
           sprintf("RULE B -- every row under the axis heading is an axis range%s",
                   named(F0$B)),
           length(F0$B) == 0L)
check_true(ID,
           sprintf("RULE C -- no pair outside the axis group takes an axis noun%s",
                   named(F0$C)),
           length(F0$C) == 0L)
check_true(ID,
           sprintf("RULE D -- every paired numeric row renders inside a named group%s",
                   named(F0$D)),
           length(F0$D) == 0L)
check_true(ID,
           sprintf("every left box has its right box on the next field line%s",
                   named(W$lone)),
           length(W$lone) == 0L)

# ---------------------------------------------------------------------------
# THE SEEDED VIOLATIONS
#
# A copy of whatever tree plugin_files() just read, one edit planted in it,
# and the SAME walk pointed at the copy through EML_DIALOG_SRC.
# ---------------------------------------------------------------------------
src_root <- Sys.getenv("EML_DIALOG_SRC", unset = "")
if (!nzchar(src_root)) src_root <- repo_path("plugin_EML_StatsGraphs")
src_root <- sub("/+$", "", normalizePath(src_root, mustWork = FALSE))

seed_tree <- function(tag) {
    root <- file.path(tempdir(), paste0("v117_seed_", tag))
    unlink(root, recursive = TRUE)
    for (f in FILES) {
        rel <- sub(paste0("^", src_root, "/"), "", normalizePath(f, mustWork = FALSE))
        dst <- file.path(root, rel)
        dir.create(dirname(dst), recursive = TRUE, showWarnings = FALSE)
        file.copy(f, dst, overwrite = TRUE)
    }
    root
}

# THE ANCHOR IS THE ROW PATTERN, NOT A LINE NUMBER. Other work lands in this
# form continuously; an anchor by content survives it, and a seed that failed
# to apply is failed rather than counted as a catch.
plant_pair <- function(root, paren) {
    tgt <- file.path(root, "graphs", "eml-graphs-form.praat")
    if (!file.exists(tgt)) return(FALSE)
    sl <- readLines(tgt, warn = FALSE)
    at <- grep('comment: "\U0001F39B', sl, fixed = TRUE, useBytes = TRUE)
    if (!length(at)) return(FALSE)
    at <- at[1]
    pad <- sub("[^ ].*$", "", sl[at])
    sl <- append(sl, c(sprintf('%sreal: "left Value (%s)", "0"', pad, paren),
                       sprintf('%sreal: "right Value (%s)", "0"', pad, paren)),
                 after = at)
    writeLines(sl, tgt)
    TRUE
}

move_pitch_into_axes <- function(root) {
    tgt <- file.path(root, "graphs", "eml-graphs-form.praat")
    if (!file.exists(tgt)) return(FALSE)
    sl <- readLines(tgt, warn = FALSE)
    at <- grep('comment: "\U0001F3B5', sl, fixed = TRUE, useBytes = TRUE)
    if (!length(at)) return(FALSE)
    sl[at] <- sub('comment: "\U0001F3B5', 'comment: "\U0001F4D0', sl[at],
                  fixed = TRUE, useBytes = TRUE)
    writeLines(sl, tgt)
    TRUE
}

walk_seeded <- function(root) {
    old <- Sys.getenv("EML_DIALOG_SRC", unset = NA)
    Sys.setenv(EML_DIALOG_SRC = root)
    on.exit(if (is.na(old)) Sys.unsetenv("EML_DIALOG_SRC") else
        Sys.setenv(EML_DIALOG_SRC = old), add = TRUE)
    walk_pairs(get("plugin_files", envir = V98)())
}

# ---- SEED A: an axis range row filed under the layout group ----------------
rootA <- seed_tree("a")
okA <- plant_pair(rootA, "bottom/top")
check_true(ID, "SEED A planted: a bottom/top Value pair under the layout heading",
           okA)
WA <- if (okA) walk_seeded(rootA) else W
FA <- faults(WA)
check_true(ID,
           sprintf("SEED A: the same walk saw the seeded tree (%d rows vs %d shipped)",
                   nrow(WA$pairs), nrow(D)),
           nrow(WA$pairs) == nrow(D) + 1L)
if (length(FA$A)) cat("SEEDED VIOLATION A, CAUGHT:", FA$A, "\n")
check_true(ID,
           sprintf("SEED A: RULE A goes red and names the pair and its heading%s",
                   named(FA$A)),
           length(FA$A) == 1L && grepl("Value", FA$A[1], fixed = TRUE) &&
               grepl("Layout", FA$A[1], fixed = TRUE))

# ---- SEED B: the same range, worded outside the ruled grammar --------------
rootB <- seed_tree("b")
okB <- plant_pair(rootB, "min/max")
check_true(ID, "SEED B planted: the same pair labelled (min/max)", okB)
WB <- if (okB) walk_seeded(rootB) else W
FB <- faults(WB)
check_true(ID,
           "SEED B: RULE A is blind to it, which is the residue this file names",
           length(FB$A) == 0L)
if (length(FB$C)) cat("SEEDED VIOLATION B, CAUGHT:", FB$C, "\n")
check_true(ID,
           sprintf("SEED B: RULE C goes red on the reserved noun%s", named(FB$C)),
           length(FB$C) == 1L && grepl("Value", FB$C[1], fixed = TRUE) &&
               grepl("Layout", FB$C[1], fixed = TRUE))

# ---- SEED C: a non-range filed INTO the axis group -------------------------
rootC <- seed_tree("c")
okC <- move_pitch_into_axes(rootC)
check_true(ID, "SEED C planted: the pitch group wearing the axis icon", okC)
WC <- if (okC) walk_seeded(rootC) else W
FC <- faults(WC)
if (length(FC$B)) cat("SEEDED VIOLATION C, CAUGHT:", FC$B, "\n")
check_true(ID,
           sprintf("SEED C: RULE B goes red on the search range now inside the roster%s",
                   named(FC$B)),
           length(FC$B) >= 1L &&
               any(grepl("floor/ceiling", FC$B, fixed = TRUE)))

# EVERY SEED IS ALSO ASSERTED ABSENT FROM THE SHIPPED TREE. A seed that failed
# to apply, or a rule that fires on everything, both look like a catch without
# this line.
check_true(ID,
           "none of the three seeded faults is present in the shipped tree",
           length(F0$A) == 0L && length(F0$B) == 0L && length(F0$C) == 0L)

unlink(c(rootA, rootB, rootC), recursive = TRUE)

if (!exists("EML_SUITE")) {
    eml_report("v117 pair group placement — a range filed outside the axis group")
    eml_exit()
}
