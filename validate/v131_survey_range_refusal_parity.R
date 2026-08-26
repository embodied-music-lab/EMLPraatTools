# ============================================================================
# v131_survey_range_refusal_parity.R -- the three "maximum below minimum"
#                                        refusals state one rule
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# THE RULING THIS FILE ANSWERS TO. On 26 August 2026 Ian, relayed by Fable,
# ruled on the fact that "a declared upper bound below its declared lower
# bound is refused" now exists as three separate, hand-written checks:
#
#   @emlGraphsAxisPairRefusal  -- plugin_EML_StatsGraphs/graphs/
#                                 eml-graphs-form.praat:1854
#   @emlGraphsPitchRangeRefusal -- plugin_EML_StatsGraphs/graphs/
#                                  eml-graphs-form.praat:1955
#   Refusal 10 of @emlSurveyValidateDeclaration -- plugin_EML_StatsGraphs/
#                                  stats/eml-psychometrics.praat
#
# The ruling: refusal 10 stays LOCAL (it is not rewritten to call a graphs
# procedure); a parity check covers all three copies on the v105 pattern;
# extraction into one shared procedure is APPROVED AS THE END STATE, is the
# door round's job, and is filed on that round's punch list. This file is
# the parity check the ruling asked for -- nothing here changes any of the
# three copies, and nothing here pre-empts the extraction.
#
# WHAT THE THREE SHARE, AND WHAT THEY DO NOT. They are not required to say
# the same SENTENCE. The two graphs-form copies ship approved wording; the
# survey copy is explicitly marked "DRAFT LANGUAGE -- awaiting Ian's
# approval" in the source (eml-psychometrics.praat, above refusal 10) and
# will change words at least once before this is over. A check that diffs
# the three headline strings would go red the day the draft is approved,
# for a reason that has nothing to do with whether the RULE the three state
# is the same rule. So this file compares structure, never text:
#
#   ASSERTED, per copy --
#     1. DIRECTION -- the two values compared are named one "the high one"
#        (maximum / ceiling / a subscale's max) and one "the low one"
#        (minimum / floor / a subscale's min), never two of the same kind,
#        so the comparison is between a genuine upper and lower bound and
#        not, say, two maxima.
#     2. RELATION -- the comparison REFUSES whenever the high value is
#        strictly below the low value. This is checked by evaluating the
#        actual comparison operator against which side is which, not by
#        assuming it: a copy that silently inverted its test (refusing on
#        the ORDINARY case instead of the reversed one) is exactly the
#        defect this section exists to catch, and the negative control in
#        section 5 proves it does.
#     3. NAMING -- the refusal's own message construction prints BOTH
#        values (each appears inside a `string$ (...)` call within the
#        refusal) and each of those two printed values is immediately
#        preceded by a label -- a quoted string, or a variable that
#        resolves to nothing but quoted strings, sitting right next to the
#        `string$` call. A refusal that named the values with no label
#        text anywhere would read as two bare numbers with no way to tell
#        which is which; that is checked structurally, never by reading
#        which WORDS the label uses.
#
#   NOT ASSERTED, ON PURPOSE --
#     - The wording of the headline, the remedy, or any other sentence.
#       The survey copy is draft language; the graphs copies are shipped;
#       comparing them as text would be a false positive on day one and a
#       false negative (an approved rewrite that broke the rule would not
#       necessarily change any words this file reads) on every day after.
#     - Whether EQUALITY of the two bounds is also refused. The graphs
#       copies use a strict `<` -- (0, 100) is an ordinary full range and
#       (5, 5) is not refused as a reversed pair on either axis. Refusal
#       10 uses `>=` -- a subscale declared min 3, max 3 has no usable
#       range at all and IS refused. This is not a bug in either family:
#       an axis or a pitch search window has a legitimate (if degenerate)
#       reading at equal bounds; a subscale with equal min and max has no
#       range to score against, ever. Demanding the same choice at
#       equality would demand one of the two families change a decision
#       that is correct where it stands. What all three DO agree on --
#       every case where the high value is strictly below the low one --
#       is asserted at full strength in RELATION, above; equality is
#       simply not part of what they share.
#     - The internal variable names, the accumulator/single-shot shape (the
#       axis check accumulates one refusal per pair across up to seven
#       pairs on a page; the pitch check and refusal 10 report one and
#       stop), or which side of the `if` a given family's bound is written
#       on. Section 2 normalises all of this away before comparing.
#
# HOW THE THREE SITES ARE FOUND -- BY SHAPE, NOT BY NAME. This file does not
# grep for "emlGraphsAxisPairRefusal" or "Refusal 10": a hand-typed list of
# procedure names finds exactly the sites the author already knew about and
# nothing else, which is precisely the failure mode standing behind this
# whole round (see the lane brief on refusals 8 and 12 -- a classifier
# consulted for only part of its answer). Instead, every `.praat` file in
# the tree is scanned (the same footprint as v105: recursive, excluding
# `/out/` snapshots and the `plugin/` symlink to avoid reading the shipped
# plugin twice) for a statement of the shape:
#
#   if <A> <cmp> <B>
#       ... prints string$ (<A>) and string$ (<B>), each preceded by a
#           label, before the matching endif ...
#   endif
#
# where one of <A>, <B> reads as a "high" quantity (its identifier tokenises
# to one of: max, maximum, ceiling, upper, high) and the other as a "low"
# quantity (min, minimum, floor, lower, low), tokenising camelCase and
# snake_case alike so `.scaleMax[.s]`, `.ceiling` and a hypothetical
# `upper_limit_hz` are all recognised the same way. This is a fact about
# the SHAPE of an order-reversal-with-labelled-values refusal, not about
# what anyone chose to call it, and section 4 proves it catches a copy
# written in a naming style nobody here used, before section 5 proves the
# same machinery catches a real copy that has been broken.
#
# WHY THIS DOES NOT ALSO CATCH EVERY OTHER ORDER CHECK IN THE TREE. The
# tree has other "is A after B" refusals that are NOT this rule -- for
# instance eml-batch-process.praat refuses `start_from_file > end_at_file`,
# with both values labelled and printed exactly the way this rule's sites
# are. That site is deliberately NOT found here: neither `start_from_file`
# nor `end_at_file` tokenises to a high/low bound word, so the shape test's
# vocabulary requirement -- not a path exclusion, not a name blacklist --
# is what keeps a file-index range distinct from a measurement-range
# refusal. A future fourth copy of THIS rule, written with `upper`/`lower`
# or `min`/`max` or `floor`/`ceiling` in its variable names -- the only
# vocabulary a person would plausibly reach for when writing this exact
# check -- is caught. A totally unrelated order check that happens to
# share the printing idiom is not swept in by accident.
#
# THE CHECK FAILS LOUDLY IF IT FINDS NOTHING, on purpose (section 1): a scan
# that silently found zero sites would leave every check below it vacuous
# and green, which is the exact shape of failure the standing brief warns
# against. Today it finds exactly three, named in section 3 against the
# ruling's own roster as a witness (not as the derivation -- the witness
# runs AFTER independent discovery and would itself go red if the shape
# scan drifted onto the wrong lines). Finding MORE than three in the future
# is not itself a failure: a fourth copy is asserted on by the same loop as
# the first three, and fails here if and only if it does not actually state
# the shared rule.
#
# NEGATIVE CONTROL (section 5), on the v90 pattern: one of the two graphs
# copies is duplicated into a scratch tree with its comparison operator
# flipped (`.ceiling > .floor` for `.ceiling < .floor`) -- the exact defect
# this file exists to catch, a copy that refuses on the ordinary case
# instead of the reversed one. Re-scanning the scratch tree must find the
# mutated copy's RELATION check false while the other two copies in the
# same tree still pass, and must name the diverging copy. Set
# EML_LANE_RED=1 to instead run the standard (non-inverted) assertion
# against the mutated copy directly and watch it go red (exit status 1).
#
# NOT registered in validate/run_all.R: this is lane work; the merging
# session registers it after the release round closes. UNLIKE the other
# lane files this note appears in, this one is also expected to be RETIRED
# rather than merely registered: when the door round lands the approved
# single shared procedure, all three call sites collapse into calls to it,
# the shape this file hunts for stops existing at more than one call site,
# and this file's job is done by construction rather than by a check. Its
# presence until then is the ruling above, not an oversight.
#
# Run:  Rscript validate/v131_survey_range_refusal_parity.R
#       EML_LANE_RED=1 Rscript validate/v131_survey_range_refusal_parity.R
# Reads: the .praat source of the tree. Nothing needs to have been driven.
#        $EML_RANGE_REFUSAL_ROOT overrides the tree that is read.
#
# Base R only. No packages.
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

V <- "v131"
red_mode <- nzchar(Sys.getenv("EML_LANE_RED", unset = ""))

ROOT <- Sys.getenv("EML_RANGE_REFUSAL_ROOT", unset = "")
if (!nzchar(ROOT)) ROOT <- repo_path()
ROOT <- normalizePath(ROOT, mustWork = FALSE)

# ---------------------------------------------------------------------------
# join_continuations -- one Praat statement per element, however many lines
# it was written across. Identical in behaviour to v105's helper of the same
# name; redefined here rather than imported because it is generic text
# machinery, not domain canon -- the thing DRY forbids restating is a RULE,
# and there is no rule inside this function, only how Praat's "..." line
# continuation is spelled.
# ---------------------------------------------------------------------------
join_continuations <- function(lines) {
    out <- character(0); at <- integer(0)
    i <- 1L
    while (i <= length(lines)) {
        cur <- lines[i]; start <- i
        while (i + 1L <= length(lines) && grepl("^\\s*\\.\\.\\.", lines[i + 1L])) {
            cur <- paste0(sub("\\s+$", "", cur), " ",
                          sub("^\\s*\\.\\.\\.\\s*", "", lines[i + 1L]))
            i <- i + 1L
        }
        out <- c(out, cur); at <- c(at, start); i <- i + 1L
    }
    list(text = out, line = at)
}

norm_operand <- function(x) gsub("\\s+", "", trimws(x))

# ---------------------------------------------------------------------------
# THE VOCABULARY A HIGH/LOW BOUND IS WRITTEN WITH. Not a list of procedure
# names -- a list of the words a person reaches for when naming "the big
# end" or "the small end" of a range, tokenised so camelCase and
# snake_case both split into words before comparison. `.scaleMax[.s]`
# tokenises to {scale, max}; `.ceiling` to {ceiling}; a hypothetical
# `upper_limit_hz` to {upper, limit, hz}. Any one matching word is enough.
# ---------------------------------------------------------------------------
HIGH_WORDS <- c("max", "maximum", "ceiling", "upper", "high")
LOW_WORDS  <- c("min", "minimum", "floor", "lower", "low")

tokenize_operand <- function(s) {
    s <- gsub("[^A-Za-z0-9]+", " ", s)
    s <- gsub("([a-z0-9])([A-Z])", "\\1 \\2", s)
    s <- tolower(s)
    tk <- strsplit(trimws(s), "\\s+")[[1]]
    tk[nzchar(tk)]
}
family_of <- function(s) {
    tk <- tokenize_operand(s)
    if (any(tk %in% HIGH_WORDS)) return("HIGH")
    if (any(tk %in% LOW_WORDS)) return("LOW")
    NA_character_
}

# ---------------------------------------------------------------------------
# literal_var_ids / inline_literals -- the survey copy builds its message
# from named pieces (.msg10a$, .msg10b$, ...) assigned once, earlier in the
# same procedure, to nothing but quoted string literals -- the same
# convention refusals 1-16 all use. At the USE site the label immediately
# before `string$ (.scaleMin[.s])` is the variable `.msg10b$`, not a literal
# in quotes; a check that only looked for a literal in quotes right there
# would call the survey copy unlabelled, which is false -- it is labelled
# through one level of indirection. So every identifier in the file that is
# assigned ONLY a concatenation of quoted literals is found first, and every
# occurrence of that identifier is replaced with an opaque literal marker
# before the label check runs. The graphs copies, which write their labels
# in place, pass through this step unchanged.
# ---------------------------------------------------------------------------
literal_var_ids <- function(statements) {
    ids <- character(0)
    for (s in statements) {
        m <- regmatches(s, regexec("^\\s*([.A-Za-z0-9_]+\\$)\\s*=\\s*(.+)$", s))[[1]]
        if (length(m) != 3L) next
        ident <- m[2]; rhs <- trimws(m[3])
        if (!grepl('"', rhs, fixed = TRUE)) next
        # Strip every quoted run (Praat escapes a literal quote by doubling
        # it; the run pattern below consumes a doubled quote as part of the
        # same literal, exactly as v105's in_string reasons about it) and
        # every "+" and space left over. Nothing should remain if the whole
        # right-hand side is a chain of literals joined by "+".
        stripped <- gsub('"([^"]|"")*"', "", rhs)
        stripped <- gsub("[+\\s]", "", stripped)
        if (nzchar(stripped)) next
        ids <- c(ids, ident)
    }
    unique(ids)
}

inline_literals <- function(text, ids) {
    if (!length(ids)) return(text)
    ids <- ids[order(-nchar(ids))]     # longest first: no identifier is a
    for (id in ids) {                  # prefix-substring collision hazard
        core <- gsub("([.$])", "\\\\\\1", id)
        pat <- paste0("(?<![.\\w$])", core, "(?![.\\w$])")
        text <- gsub(pat, '"LIT"', text, perl = TRUE)
    }
    text
}

# label_before_string_call -- after inlining, is THIS operand's printed
# value immediately preceded by a quoted literal (a real one, or one that
# used to be a variable naming nothing but literals)? Read literally: does
# `"..." +` sit right before `string$ (<operand>)` in the block text.
label_before_string_call <- function(inlined_text, operand) {
    m <- gregexpr("string\\$\\s*\\(([^()]*)\\)", inlined_text)[[1]]
    if (m[1] == -1) return(FALSE)
    lens <- attr(m, "match.length")
    for (k in seq_along(m)) {
        whole <- substr(inlined_text, m[k], m[k] + lens[k] - 1L)
        content <- sub("^string\\$\\s*\\(", "", whole); content <- sub("\\)$", "", content)
        if (norm_operand(content) != norm_operand(operand)) next
        before <- substr(inlined_text, 1L, m[k] - 1L)
        if (grepl('"[^"]*"\\s*\\+\\s*$', before)) return(TRUE)
    }
    FALSE
}

# relation_ok -- does THIS comparison, as written (which side is high, which
# operator), refuse in every case where the high value is strictly below the
# low value? The four combinations that satisfy it: high < low, high <= low,
# low > high, low >= high. Anything else -- crucially, the operator pointing
# the other way -- refuses on the ORDINARY case instead of the reversed one,
# which is exactly the defect section 5 seeds.
relation_ok <- function(fl, op, fr) {
    if (fl == "HIGH" && op %in% c("<", "<=")) return(TRUE)
    if (fr == "HIGH" && op %in% c(">", ">=")) return(TRUE)
    FALSE
}

# ---------------------------------------------------------------------------
# scan_range_refusal_sites -- every site in `root` matching the shape
# described in the header, with the three per-copy properties (direction is
# implicit in fl/fr already being one HIGH and one LOW; relation and the two
# label checks) computed once, here, so every downstream section reads the
# same evidence rather than re-deriving it.
# ---------------------------------------------------------------------------
scan_range_refusal_sites <- function(root) {
    praat_files <- list.files(root, pattern = "\\.praat$", recursive = TRUE,
                              full.names = FALSE)
    # The plugin/ symlink mirrors plugin_EML_StatsGraphs/; following it would
    # report every site under it twice. /out/ trees are committed snapshots
    # of a past run, not source anyone edits -- the same two exclusions
    # v105 makes, for the same reasons.
    praat_files <- praat_files[!grepl("(^|/)plugin/", praat_files)]
    praat_files <- praat_files[!grepl("/out/", praat_files, fixed = TRUE)]
    praat_files <- sort(praat_files)

    found <- list()
    for (rel in praat_files) {
        raw <- readLines(file.path(root, rel), warn = FALSE)
        if (!any(grepl("if\\b", raw))) next
        j <- join_continuations(raw)
        n <- length(j$text)
        is_if <- grepl("^\\s*if\\b", j$text)
        is_endif <- grepl("^\\s*endif\\b", j$text)
        if (!any(is_if)) next
        lit_ids <- literal_var_ids(j$text)
        seen <- 0L
        for (i in seq_len(n)) {
            if (!is_if[i]) next
            cond <- sub("^\\s*if\\s+", "", j$text[i])
            m <- regmatches(cond, regexec("^(.+?)(<=|>=|<|>|==|<>)(.+)$", cond))[[1]]
            if (length(m) != 4L) next
            left <- trimws(m[2]); op <- trimws(m[3]); right <- trimws(m[4])
            # A compound condition ("if a < b and c") is not a two-value
            # order check on its own terms; leave it alone.
            if (grepl("\\b(or|and|not)\\b", cond, ignore.case = TRUE)) next
            if (op %in% c("==", "<>")) next
            # Neither side may be a bare number -- both must be an actual
            # declared bound, not a threshold compared against a constant.
            if (!is.na(suppressWarnings(as.numeric(left))) ||
                !is.na(suppressWarnings(as.numeric(right)))) next
            fl <- family_of(left); fr <- family_of(right)
            if (is.na(fl) || is.na(fr) || fl == fr) next   # need one of each

            # The matching endif, tracking nested if/endif depth.
            depth2 <- 1L; j2 <- i + 1L; endidx <- NA_integer_
            while (j2 <= n) {
                if (is_if[j2]) depth2 <- depth2 + 1L
                if (is_endif[j2]) {
                    depth2 <- depth2 - 1L
                    if (depth2 == 0L) { endidx <- j2; break }
                }
                j2 <- j2 + 1L
            }
            if (is.na(endidx)) next
            body <- j$text[(i + 1L):(endidx - 1L)]
            bodytxt <- paste(body, collapse = " ")
            sc <- gregexpr("string\\$\\s*\\(([^()]*)\\)", bodytxt)
            mm <- regmatches(bodytxt, sc)[[1]]
            if (length(mm) < 2L) next
            contents <- sub("^string\\$\\s*\\(", "", mm)
            contents <- sub("\\)$", "", contents)
            contents <- vapply(contents, norm_operand, "")
            nl <- norm_operand(left); nr <- norm_operand(right)
            if (!(nl %in% contents && nr %in% contents)) next   # both values printed

            inlined <- inline_literals(bodytxt, lit_ids)
            seen <- seen + 1L
            key <- sprintf("%s#R%d", rel, seen)

            proc_lines <- grep("^\\s*procedure\\s+(\\S+)",
                               raw[seq_len(min(j$line[i], length(raw)))])
            enclosing <- if (length(proc_lines)) {
                nm <- sub("^\\s*procedure\\s+(\\S+).*$", "\\1", raw[max(proc_lines)])
                sub("[:,].*$", "", nm)
            } else NA_character_
            wstart <- max(1L, j$line[i] - 60L)
            witness_text <- paste(raw[wstart:j$line[i]], collapse = "\n")

            found[[key]] <- list(
                file = rel, line = j$line[i], left = left, right = right, op = op,
                fl = fl, fr = fr,
                relation_ok = relation_ok(fl, op, fr),
                label_left_ok = label_before_string_call(inlined, left),
                label_right_ok = label_before_string_call(inlined, right),
                enclosing = enclosing, witness = witness_text
            )
        }
    }
    found
}

# ===========================================================================
# 1. THE SHAPE FINDS SOMETHING, AND FINDS AT LEAST THE RULED-ON THREE
# ===========================================================================
found <- scan_range_refusal_sites(ROOT)

check_true(V, "the shape scan finds at least one range-order refusal site",
           length(found) >= 1L)
check_true(V, "the shape scan finds at least the three sites the ruling names",
           length(found) >= 3L)

attest(V, "range-order refusal sites found",
       paste(sprintf("%s (line %d, if %s %s %s)", names(found),
                     vapply(found, function(s) s$line, 0L),
                     vapply(found, function(s) s$left, ""),
                     vapply(found, function(s) s$op, ""),
                     vapply(found, function(s) s$right, "")),
             collapse = " | "))
attest(V, "tree read", ROOT)

# ===========================================================================
# 2. EVERY FOUND SITE STATES THE SAME RULE
# ===========================================================================
# Direction, relation and naming, asserted for EVERY site the scan found --
# not just the three named in the ruling. A fourth copy that showed up here
# tomorrow is judged by the exact same three checks the first three are
# judged by, with no separate, weaker path for "sites nobody was expecting".
for (key in names(found)) {
    s <- found[[key]]
    check_true(V, sprintf("%s: compares a high bound against a low bound (not two of a kind)", key),
               setequal(c(s$fl, s$fr), c("HIGH", "LOW")))
    check_true(V, sprintf("%s: refuses whenever the high bound is strictly below the low bound", key),
               isTRUE(s$relation_ok))
    check_true(V, sprintf("%s: the high bound's printed value is labelled", key),
               isTRUE(s$label_left_ok) && s$fl == "HIGH" ||
               isTRUE(s$label_right_ok) && s$fr == "HIGH")
    check_true(V, sprintf("%s: the low bound's printed value is labelled", key),
               isTRUE(s$label_left_ok) && s$fl == "LOW" ||
               isTRUE(s$label_right_ok) && s$fr == "LOW")
}

# ===========================================================================
# 3. WITNESS -- THE THREE THE RULING NAMES ARE AMONG WHAT WAS FOUND
# ===========================================================================
# This runs AFTER independent discovery and is not how the sites were found;
# it is the same "second witness" v105 keeps beside its procedure-derived
# canon (section 1 there) -- proof that the shape scan landed on the actual
# ruled-on lines and not merely on three lines that happened to add up to
# three. If the scan ever drifted onto the wrong statements this section,
# not section 1's count, is what would say so.
has_site <- function(file_pat, enclosing_name, extra_grepl = NULL) {
    for (s in found) {
        if (!grepl(file_pat, s$file, fixed = TRUE)) next
        if (!identical(s$enclosing, enclosing_name)) next
        if (!is.null(extra_grepl) && !grepl(extra_grepl, s$witness)) next
        return(TRUE)
    }
    FALSE
}
check_true(V, "the axis-pair copy (eml-graphs-form.praat, @emlGraphsAxisPairRefusal) was found",
           has_site("eml-graphs-form.praat", "emlGraphsAxisPairRefusal"))
check_true(V, "the pitch-range copy (eml-graphs-form.praat, @emlGraphsPitchRangeRefusal) was found",
           has_site("eml-graphs-form.praat", "emlGraphsPitchRangeRefusal"))
check_true(V, "the survey copy (eml-psychometrics.praat, refusal 10 of @emlSurveyValidateDeclaration) was found",
           has_site("eml-psychometrics.praat", "emlSurveyValidateDeclaration", "Refusal 10"))

# ===========================================================================
# 4. THE SHAPE GENERALISES -- PROOF ON A STYLE NOBODY HERE WROTE
# ===========================================================================
# A regex tuned against the three known files, and only ever run against
# them, proves nothing about a fourth copy written differently. A scratch
# file is written in a style deliberately unlike all three real copies --
# snake_case and camelCase mixed, a one-line `if`, tab indentation, the
# comparison written with the LOW operand on the left and `>` instead of
# `<`, and a plain `exitScript:` instead of an accumulator or a `goto` -- and
# the same scan must still find it and judge it correctly.
style_root <- file.path(tempdir(), "v131_style_proof")
unlink(style_root, recursive = TRUE)
dir.create(file.path(style_root), recursive = TRUE)
writeLines(c(
    "# a style this file's author did not write and did not tune the scan to.",
    "procedure emlUnfamiliarRangeCheck: .lowerLimitHz, .upperLimitHz",
    "\tif .lowerLimitHz > .upperLimitHz",
    "\t\texitScript: \"lower limit (\" + string$ (.lowerLimitHz) + \") exceeds \" + \"upper limit (\" + string$ (.upperLimitHz) + \").\"",
    "\tendif",
    "endproc"
), file.path(style_root, "unfamiliar_style.praat"))

style_found <- scan_range_refusal_sites(style_root)
check_true(V, "the unfamiliar-style scratch copy is found by shape alone",
           length(style_found) == 1L)
if (length(style_found) == 1L) {
    ss <- style_found[[1]]
    check_true(V, "the unfamiliar-style copy is judged to state the same rule",
               isTRUE(ss$relation_ok) && isTRUE(ss$label_left_ok) && isTRUE(ss$label_right_ok))
}
unlink(style_root, recursive = TRUE)

# ===========================================================================
# 5. NEGATIVE CONTROL -- ONE COPY PERTURBED SO THE THREE DISAGREE
# ===========================================================================
# The two graphs-form sites and the survey site are copied, byte for byte,
# into a scratch tree, and the pitch copy's comparison is flipped:
# `.ceiling < .floor` becomes `.ceiling > .floor` -- the exact defect this
# file exists to catch, a copy that now refuses on the ORDINARY case and
# lets the reversed one through. The other two copies in the same scratch
# tree are untouched, so a real disagreement exists among three sites that
# agreed before the edit.
work <- file.path(tempdir(), "v131_negative_control")
unlink(work, recursive = TRUE)
graphs_dir <- file.path(work, "plugin_EML_StatsGraphs", "graphs")
stats_dir  <- file.path(work, "plugin_EML_StatsGraphs", "stats")
dir.create(graphs_dir, recursive = TRUE)
dir.create(stats_dir, recursive = TRUE)

graphs_src_path <- file.path(ROOT, "plugin_EML_StatsGraphs", "graphs", "eml-graphs-form.praat")
stats_src_path  <- file.path(ROOT, "plugin_EML_StatsGraphs", "stats", "eml-psychometrics.praat")
check_true(V, "the real graphs-form source is present to seed the negative control",
           file.exists(graphs_src_path))
check_true(V, "the real psychometrics source is present to seed the negative control",
           file.exists(stats_src_path))

if (file.exists(graphs_src_path) && file.exists(stats_src_path)) {
    graphs_src <- readLines(graphs_src_path, warn = FALSE)
    needle <- "if .ceiling < .floor"
    hit <- grepl(needle, graphs_src, fixed = TRUE)
    check_true(V, "the negative-control seed site (@emlGraphsPitchRangeRefusal's comparison) exists in source",
               sum(hit) == 1L)
    mutated <- sub(needle, "if .ceiling > .floor", graphs_src, fixed = TRUE)
    writeLines(mutated, file.path(graphs_dir, "eml-graphs-form.praat"))
    file.copy(stats_src_path, file.path(stats_dir, "eml-psychometrics.praat"), overwrite = TRUE)

    mutant_found <- scan_range_refusal_sites(work)
    check_true(V, "the negative-control scratch tree still yields three sites",
               length(mutant_found) == 3L)

    if (length(mutant_found) == 3L) {
        bad <- vapply(mutant_found, function(s) !isTRUE(s$relation_ok), logical(1))
        good_axis   <- vapply(mutant_found, function(s) s$enclosing, "") == "emlGraphsAxisPairRefusal"
        good_survey <- vapply(mutant_found, function(s) s$enclosing, "") == "emlSurveyValidateDeclaration"
        diverging_key <- names(mutant_found)[bad]

        if (red_mode) {
            cat("      EML_LANE_RED: asserting the standard relation check against\n")
            cat("      the mutated pitch copy directly -- the next check is EXPECTED to FAIL.\n")
            mkey <- names(mutant_found)[grepl("eml-graphs-form.praat", vapply(mutant_found, function(s) s$file, ""), fixed = TRUE) &
                                        vapply(mutant_found, function(s) identical(s$enclosing, "emlGraphsPitchRangeRefusal"), logical(1))]
            for (k in mkey) {
                s <- mutant_found[[k]]
                check_true(V, sprintf("[RED] %s: refuses whenever the high bound is strictly below the low bound", k),
                           isTRUE(s$relation_ok))
            }
        } else {
            check_true(V, "negative control: exactly one of the three copies in the mutant tree diverges",
                       sum(bad) == 1L)
            check_true(V, sprintf("negative control: the diverging copy is the mutated pitch copy (%s)",
                                  paste(diverging_key, collapse = ", ")),
                       sum(bad) == 1L &&
                       identical(mutant_found[[diverging_key[1]]]$enclosing, "emlGraphsPitchRangeRefusal"))
            check_true(V, "negative control: the untouched axis copy still agrees",
                       any(good_axis & !bad))
            check_true(V, "negative control: the untouched survey copy still agrees",
                       any(good_survey & !bad))
        }
    }
}
unlink(work, recursive = TRUE)

if (!exists("EML_SUITE")) {
    eml_report("v131 the three \"maximum below minimum\" refusals state one rule")
    eml_exit()
}
