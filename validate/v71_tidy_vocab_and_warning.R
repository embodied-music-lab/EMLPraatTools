# ============================================================================
# v71_tidy_vocab_and_warning.R -- two rulings that both turn on the same
#                                 question: which artefact is a string FOR?
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS FILE EXISTS. On 16 August 2026 the author accepted two rulings that
# look unrelated and are not. Ruling 3 says skewness and kurtosis join the tidy
# vocabulary; item 12b says the repeated-measures caution stops being one
# string with two destinations. Both are the same mistake caught twice -- a
# value written once and then asked to satisfy two artefacts that owe the
# reader opposite things. The report owes four decimals and a sentence; the CSV
# owes full precision and a column. Where one string served both, one of the
# two was always being short-changed, and which one it was could not be seen
# from the source.
#
# WHAT THE FAILURES LOOKED LIKE.
#
# RULING 3. A user tested one column for normality, pressed Save, and got a
# glance frame carrying W, p, skewness and kurtosis. The same user tested three
# columns in one press and got a tidy frame carrying W, p and method -- no
# shape at all, in any file. The skewness of column 2 was printed in the Info
# window and existed nowhere else. Nothing errored, nothing was missing from
# the header, and the file was a perfectly well formed broom frame; it was
# simply a smaller answer than the one-column case, which is the wrong
# direction for an export to fail in. The more the user asked for, the less
# they were given.
#
# ITEM 12b. @emlRMAnovaTest builds one `.warning$`. @emlReportRepeatedMeasures
# wraps it into the Info window under "Caution:" and @emlDeclareRMResult hands
# the identical string to @emlGlanceStr as the glance frame's `warning` cell.
# The sentence quotes the Greenhouse-Geisser lower bound through a raw fixed$,
# which author ruling 6 forbids in a report and requires in an export. An agent
# reaching this line in the display sweep saw that reformatting for the report
# would silently edit an exported value and correctly refused to touch it; the
# refusal is recorded in v65_display_standard.R's census as the EXPORT class,
# the only one of its three exemptions that was a deferral rather than a
# judgement. Item 12b lifts the deferral by splitting the string in two.
#
# THE HAZARD RULING 3 WAS FILED AGAINST, AND WHAT IT ACTUALLY IS NOW.
# validate/REGISTRY.md and eml-analysis.praat both warn that emlVocabTidy$ is a
# whitelist walked by @eml_orderedCols and that a column not in it is dropped
# in SILENCE -- the recorded consequence being a file that shipped with `term`
# and `method` and nothing else. That warning is worth its place and its first
# clause is exact, but the word "silence" is out of date and this file says so
# rather than repeating it. Driven on 16 Aug 2026: with the declarations added
# and the vocabulary reverted, the run does not ship a thin file, it HALTS --
# @eml_vocabCheck exits the script naming the column, listing the legal ones,
# and naming both files that have to change in the same commit. The silent path
# closed when that guard was written. What is still silent, and is the reason
# nothing here trusts the vocabulary alone, is @eml_orderedCols' other rule: a
# legal column that is EMPTY IN EVERY ROW is omitted from the written file
# without comment, which is correct -- broom would not have produced it -- and
# is exercised deliberately in section 4 below, where Shapiro-Wilk is out of
# range for every column and `statistic` and `p.value` are properly absent.
#
# WHAT COULD NOT HAVE CAUGHT EITHER OF THEM, AND WHY.
#
#   - v17_broom_parity.R AND EVERY PARITY CHECK. Their subject is the columns
#     that ARE broom's, in broom's order. skewness and kurtosis are neither:
#     broom has no vocabulary for shape anywhere in its shapiro surface,
#     because shapiro.test itself reports a statistic, a p and a method and
#     nothing else. A frame that omits a column broom also omits is a frame in
#     perfect parity, which is exactly what the defective export was. Parity is
#     the wrong instrument for an addition, and this is the general shape of it:
#     a conformance check cannot see the absence of something the standard
#     never had.
#
#   - v57_export_integrity.R. It reads the three-column normality export off
#     harness/exportint and checks that each tidy row's statistic is that
#     column's W. Every one of those checks passed across this change in both
#     directions, because a check that asserts the columns it names says
#     nothing about the columns nobody named. It also asserts the multi-column
#     glance `warning` by two substrings, "columns were tested" and "tidy
#     frame", both of which survive a sentence that has become false.
#
#   - v64_display_and_coercion.R, WHICH IS THE CLOSEST THING TO A PREDECESSOR
#     AND CAME AS CLOSE AS A VALIDATOR CAN COME WITHOUT ASSERTING. It drives
#     the multi-column and single-column presses, reads both files off disk,
#     prints the asymmetry, and pins the PREMISE -- that single-column glance
#     keeps skewness and kurtosis -- so that a repair by deletion goes red and
#     says so. What it deliberately did not do is assert the tidy half, because
#     the repair lived in two files that were not that change's to edit. It
#     recorded the finding as an attestation and printed the repair, file by
#     file and line by line, as a NOTE. This file is the assertion that note
#     was waiting for; v64 needs its NOTE branch retired and its `hasT`
#     promoted, and that is reported rather than done here.
#
#   - A GOLDEN-FILE DIFF, on either ruling. On ruling 3 it would have shown a
#     header gaining two columns and said nothing about whether the numbers
#     under them were right, or whether they were column 1's numbers repeated.
#     On item 12b it would have shown NOTHING AT ALL: the split changes no
#     byte of any artefact at any k this plugin can be driven at, which is the
#     whole reason it is safe and the whole reason a diff cannot see it.
#
#   - ANY RED PATH. Nothing refuses on either ruling. Both presses run, both
#     print, both offer to save, and every file written is well formed.
#
# THE TRAP THIS FILE IS BUILT AROUND: A VOCABULARY CHECK IS NOT A VALUE CHECK.
# The cheapest way to satisfy "the tidy frame has skewness and kurtosis" is to
# write the columns and put anything in them -- column 1's numbers in every
# row, or a zero of the right width, which is the failure mode ruling 6's own
# validator was built around and would satisfy every width assertion ever
# written. So section 3 does not check that the columns exist. It reads the
# values out of the written CSV and compares each one against R's own G1 and G2
# on the same data, per column, and drives three columns chosen so that no
# single wrong implementation survives: one symmetric column whose skewness is
# exactly zero, and two mirror-image columns with equal kurtosis and opposite
# skewness. Copying column 1 into every row fails on all three. Clamping to
# zero passes the symmetric column and fails the other two. Emitting kurtosis
# where skewness belongs passes the mirror pair on kurtosis and fails it on
# skew. The columns being present is a precondition, not the finding.
#
# AND THE SECOND TRAP, WHICH IS ITEM 12b's: A CHECK THAT COULD ONLY PASS.
# Because the two halves of the split render identically at every reachable k,
# a validator that drove the report and measured the width of the printed bound
# would be green on this file and green on HEAD and would be testing nothing.
# It is worth being explicit that no such check is written here. What section 6
# asserts instead is which VARIABLE each destination reads -- statement-joined
# out of the source, not matched against the comment that explains it -- and
# section 7 measures, on the binary under test, the k at which the two
# formatters part company, so the claim "identical today" is a measurement with
# a date on it rather than a belief. Section 6 also freezes the exported bytes
# against HEAD e467824. That literal is the one kind this repository normally
# refuses, and it is correct here for the reason it is usually wrong: the
# assertion IS byte-identity, so a frozen literal is the subject and not a
# shortcut around it.
#
# NOTHING HERE IS VALIDATED UNTIL IT HAS BEEN BROKEN. Thirty-seven deliberate
# breaks were built as COPIES of the plugin tree and run through
# $EML_PLUGIN_DIR on 16 August 2026. Every one of them turned this file red,
# and between them they turn all 73 of its checks red at least once -- the
# coverage was measured by diffing the failing-check names against the green
# run, not asserted, and three checks that the first pass never reached are the
# reason there was a second pass. Grouped by what they prove:
#
#   THE DEFECT ITSELF -- both files reverted to HEAD e467824 (21 red), the
#   declarations only (18), the vocabulary only (4, and the run HALTS rather
#   than shipping a thin file, which is the finding recorded above). The split
#   matters: it shows that no check is passing because the other half happens
#   to be right.
#
#   THE VALUE RATHER THAN THE COLUMN, which is this file's own trap. skewness
#   declared from row 1 instead of the loop index (7 red); kurtosis written
#   into the skewness cell (11); skewness written into the kurtosis cell (9);
#   skewness clamped to a literal zero (7). Every one of those ships a file
#   with the right header, the right row count and the right column order.
#
#   THE MECHANISM RATHER THAN THE TEXT -- @eml_fixed reduced to a pass-through
#   to fixed$ with every call site left in place (2 red, and they are the two
#   threshold checks, which is the only place a pass-through is visible); the
#   report switched back to reading the exported string (1); the export
#   switched to reading the printed one (1, and ONLY the mechanism check sees
#   it, because at this k the two render identically -- which is the whole
#   argument for asserting the variable rather than the output); the printed
#   string aliased to the exported one (2); the clear at entry removed (1).
#
#   THE FIX-SHAPED FIX -- @eml_fixed made to return a zero of the right width
#   for every input (9 red). It satisfies every width assertion in section 6
#   and fails the value check beside each one, and fails four of the six
#   threshold measurements as well.
#
#   THE FORBIDDEN EDIT -- the exported caution reformatted to two decimals (2
#   red on the frozen bytes), and the exported caution routed through
#   @eml_fixed, which changes no byte at this k and is caught only by the
#   census that says the exported family keeps its raw fixed$ (1).
#
#   THE SIGNPOST -- the glance warning left in its pre-ruling wording (1 red);
#   rewritten to name a column the tidy frame does not have (1); stripped of
#   the clause that says where anything is (2).
#
#   THE GUARDS. The declaring procedure renamed (4); the press made never to
#   accumulate (8); the tidy loop cut to one row (6); the exporter made to
#   write nothing (6); either source file removed (2 each); the shared
#   formatter renamed out of eml-output.praat (2); a second formatter defined
#   locally in eml-analysis.praat (1); the two additions moved ahead of `term`
#   (4); one of the two added and not the other (3); either vocabulary
#   assignment made unfindable by the reader (4 and 2); Shapiro-Wilk's ceiling
#   lifted so the no-W arm is never driven (2); the caution computed and never
#   printed (3); the printed bound formatted at two decimals (4); no Praat at
#   or above the floor (1).
#
# TWO BREAKS FOUND DEFECTS IN THIS FILE RATHER THAN IN THE PLUGIN, and both are
# the same defect: a validator that DIES has reported nothing. Reverting both
# files handed `check` a zero-length value, because a frame with no skewness
# column returns nothing rather than NA for that cell, and R aborted mid-run
# with the case scored at zero failures -- on the one break the whole file
# exists to catch. Cutting the tidy loop to one row then did it again through a
# missing ROW rather than a missing column, in a case built to test something
# else. `cell()` and `num1()` below are those two repairs, and the fact that
# both were found by running the battery rather than by reading the code is the
# argument for the battery.
#
# WHAT IS NOT COVERED. Whether skewness and kurtosis are the RIGHT statistics
# for a normality frame is an author's decision and was taken in ruling 3.
# Whether the plugin computes them correctly is v14's and v15's subject, on
# their own data, and is assumed here. This file is about which file they come
# out in and whether the number that arrives is the number that was computed.
#
#     Rscript validate/v71_tidy_vocab_and_warning.R
#
# NOT A MEMBER of validate/run_all.R's list -- that file is not this change's
# to edit, and this one launches Praat. Run it directly, and run it on any
# change to either vocabulary, to @emlDeclareNormalityResult, or to the
# repeated-measures caution.
#
# Input: the plugin source, driven live. $EML_PLUGIN_DIR overrides the tree
#        under test, which is how the break battery in the session report was
#        run. $PRAAT overrides the binary.
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

srcAna <- file.path(plug, "stats", "eml-analysis.praat")
srcRW  <- file.path(plug, "stats", "eml-result-writer.praat")
srcOut <- file.path(plug, "stats", "eml-output.praat")

# ---------------------------------------------------------------------------
# 0. THE BINARY -- same floor and the same refusal as harness/_env.sh, v64, v65
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

# STATEMENTS, NOT LINES, and the same helper v65 uses for the same reason.
# Praat continues a statement with a leading `...`, the vocabulary is a
# five-line concatenation and the caution sentences are six each, so a
# line-based read would attribute half of every one of them to a continuation.
# Comment and semicolon lines are dropped first: BOTH FILES DISCUSS THIS FILE'S
# SUBJECT AT LENGTH IN THEIR PROSE -- eml-analysis.praat now carries three
# paragraphs naming skewness, kurtosis, .warning$ and .warningPrinted$ -- and a
# check that can be satisfied by a comment is a check that tests the comment.
# That is the failure this repository has hit before and it is the reason not
# one grep below is allowed to see a `#` or `;` line.
praat_statements <- function(path) {
    ln <- readLines(path, warn = FALSE)
    keep <- !grepl("^\\s*[#;]", ln)
    out <- character(0); starts <- integer(0)
    for (i in seq_along(ln)) {
        if (!keep[i]) next
        if (grepl("^\\s*\\.\\.\\.", ln[i]) && length(out)) {
            out[length(out)] <- paste(out[length(out)],
                                      sub("^\\s*\\.\\.\\.", "", ln[i]))
        } else {
            out <- c(out, ln[i]); starts <- c(starts, i)
        }
    }
    list(text = out, line = starts)
}

# ---------------------------------------------------------------------------
# 1. THE VOCABULARY -- MEMBERSHIP AND POSITION, WHICH ARE THE SAME FACT
# ---------------------------------------------------------------------------
# emlVocabTidy$ is not a set. @eml_orderedCols walks it in order and the order
# it walks is the order the columns are written in, so "skewness is in the
# vocabulary" and "skewness is in the right place" are one assertion made
# twice. The place chosen by ruling 3 is immediately before `method`, which
# puts the two additions in the SAME position relative to the broom tail as
# they already hold in emlVocabGlance$ -- so the one-model file and the
# many-model file agree about column order and differ only in the thing that is
# really different, which is how many models were fitted.
check_true("v71", "stats/eml-result-writer.praat is present", file.exists(srcRW))
check_true("v71", "stats/eml-analysis.praat is present", file.exists(srcAna))

vocabOf <- function(st, name) {
    i <- grep(sprintf("^\\s*%s\\$\\s*=", name), st$text)
    if (!length(i)) return(character(0))
    s <- st$text[i[1]]
    toks <- regmatches(s, gregexpr('"[^"]*"', s))[[1]]
    toks <- gsub('"', "", toks)
    tt <- unlist(strsplit(paste(toks, collapse = " "), "\\s+"))
    tt[nzchar(tt)]
}

if (file.exists(srcRW)) {
    strw <- praat_statements(srcRW)
    vt <- vocabOf(strw, "emlVocabTidy")
    vg <- vocabOf(strw, "emlVocabGlance")
    check_true("v71",
               sprintf("emlVocabTidy$ was read as a list of tokens (%d)", length(vt)),
               length(vt) > 20)
    check_true("v71",
               sprintf("emlVocabGlance$ was read as a list of tokens (%d)", length(vg)),
               length(vg) > 20)
    check_true("v71",
               sprintf("the tidy vocabulary carries skewness and kurtosis (%s)",
                       paste(utils::tail(vt, 6), collapse = " ")),
               all(c("skewness", "kurtosis") %in% vt))
    # POSITION, SAID AS A RELATION AND NOT AS AN INDEX. An index would move
    # every time a column is added anywhere ahead of it, and would then be
    # "fixed" by editing this file rather than by looking at the vocabulary.
    rel <- function(v) {
        if (!all(c("skewness", "kurtosis", "method") %in% v)) return(NA)
        which(v == "kurtosis") == which(v == "skewness") + 1L &&
        which(v == "method") == which(v == "kurtosis") + 1L
    }
    check_true("v71",
               "in tidy, skewness is immediately followed by kurtosis and then by method",
               isTRUE(rel(vt)))
    check_true("v71",
               "and the glance vocabulary holds them in exactly the same relation",
               isTRUE(rel(vg)))
    check_true("v71",
               "so neither addition is written ahead of term, which is broom's first column",
               which(vt == "term") == 1L &&
               which(vt == "skewness") > which(vt == "term"))
    # THE ADDITIONS ARE FLAGGED AS ADDITIONS. broom's shapiro surface is
    # statistic, p.value, method -- there is no shape vocabulary to be in
    # parity with -- so a future reader must not be able to mistake these two
    # for broom names. The file says so in prose; what is checkable is that
    # they trail the broom block rather than sitting inside it.
    check_true("v71",
               "and both trail every column broom's own tidy(shapiro.test) would emit",
               all(which(vt %in% c("skewness", "kurtosis")) >
                   max(which(vt %in% c("statistic", "p.value")))))
}

# ---------------------------------------------------------------------------
# 2. THE DECLARATION -- THE OTHER HALF, AND ON BOTH ARMS OF THE BRANCH
# ---------------------------------------------------------------------------
# Adding the names to the vocabulary writes no cell. @emlDeclareNormalityResult
# has to declare them per row, and it has to do it on BOTH arms of the
# Shapiro-Wilk branch: a column whose n puts W out of range still has a
# skewness and a kurtosis, and those are then the whole of what the analysis
# found. Emitting them only beside a W drops them from precisely the rows that
# have nothing else in them. Section 4 drives that arm; this is the static half.
if (file.exists(srcAna)) {
    sta <- praat_statements(srcAna)
    i0 <- grep("^\\s*procedure\\s+emlDeclareNormalityResult\\b", sta$text)
    i1 <- if (length(i0)) grep("^\\s*endproc\\s*$", sta$text)[
              grep("^\\s*endproc\\s*$", sta$text) > i0[1]][1] else NA_integer_
    body <- if (length(i0) == 1 && !is.na(i1)) sta$text[i0[1]:i1] else character(0)
    check_true("v71",
               sprintf("@emlDeclareNormalityResult was located (%d statements)",
                       length(body)),
               length(body) > 20)
    sk <- grep('@emlTidyNum:\\s*"skewness"', body)
    ku <- grep('@emlTidyNum:\\s*"kurtosis"', body)
    check_true("v71",
               sprintf("it declares skewness on both arms of the Shapiro-Wilk branch (%d site(s))",
                       length(sk)),
               length(sk) == 2)
    check_true("v71",
               sprintf("and kurtosis on both arms (%d site(s))", length(ku)),
               length(ku) == 2)
    # THE VALUE DECLARED IS THE ROW'S OWN. `[.i]` is the loop index; a
    # declaration reading `[1]` would put column 1's shape on every row and
    # pass every check that only looks at the header. Section 3 catches that
    # from the file; this catches it from the source and says which line.
    check_true("v71",
               "and each declaration is subscripted by the loop index, not by 1",
               length(sk) == 2 && length(ku) == 2 &&
               all(grepl("emlNorm_skew\\s*\\[\\s*\\.i\\s*\\]", body[sk])) &&
               all(grepl("emlNorm_kurt\\s*\\[\\s*\\.i\\s*\\]", body[ku])))
}

# THE FORMATTER IS SOMEWHERE ELSE AND STAYS THERE. Checked here rather than
# inside the drive, and the reason is a break: reduced to a live check it could
# only be reported when the probe RAN, and a tree whose formatter has been
# renamed is a tree whose probe cannot run. A file that can only report a
# failure when everything else is working reports it never.
check_true("v71",
           "and @eml_fixed is still the shared one, in stats/eml-output.praat",
           file.exists(srcOut) &&
           any(grepl("^\\s*procedure\\s+eml_fixed\\b",
                     readLines(srcOut, warn = FALSE))))

# ---------------------------------------------------------------------------
# 3-7. THE LIVE DRIVE
# ---------------------------------------------------------------------------
if (!canDrive) {
    cat(sprintf(paste0("      NOTE v71: LIVE EVIDENCE MISSING.\n",
                       "            Praat here is %s; the plugin floors at 6.6.30\n",
                       "            (plugin/setup.praat). Every finding below this\n",
                       "            line is about what a written file CONTAINS, and\n",
                       "            a file written by an unsupported build is not\n",
                       "            evidence about the supported one. The static\n",
                       "            checks above still hold.\n"),
                if (is.na(pv)) "not found" else pv))
    check_true("v71",
               sprintf("a Praat at or above the plugin's floor is available (found %s)",
                       if (is.na(pv)) "none" else pv),
               FALSE)
} else {
    work <- file.path(tempdir(), "v71")
    unlink(work, recursive = TRUE)
    dir.create(file.path(work, "scripts"), showWarnings = FALSE, recursive = TRUE)
    dir.create(file.path(work, "out"), showWarnings = FALSE, recursive = TRUE)
    prefs <- file.path(work, "prefs")
    dir.create(prefs, showWarnings = FALSE)
    # A stale lock from a crashed run makes the next Praat refuse to start, and
    # a refusal at startup reads here as an export that wrote nothing. Only
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
    for (f in list.files(file.path(plug, "scripts"), pattern = "^eml-lib.*\\.praat$")) {
        tgt <- file.path(work, "scripts", f)
        if (!file.exists(tgt))
            file.symlink(normalizePath(file.path(plug, "scripts", f)), tgt)
    }

    # THE DATA, AND WHY IT IS THIS DATA. Three columns of nine:
    #   sym    1..9            symmetric, so G1 is exactly zero
    #   rskew  heavy right tail
    #   lskew  21 - rskew      the mirror: G2 identical, G1 negated
    # A frame that clamps every cell to zero passes sym and fails both others.
    # A frame that repeats column 1 fails all three. A frame that writes
    # kurtosis into the skewness cell passes the mirror pair on G2 and fails it
    # on G1, which no single-column fixture could have separated.
    sym   <- 1:9
    rskew <- c(1, 1, 1, 2, 2, 3, 4, 7, 20)
    lskew <- 21 - rskew
    big   <- (1:5001)^2

    probe <- file.path(work, "scripts", "v71-probe.praat")
    writeLines(c(
        'include eml-lib.praat',
        'outDir$ = "../out"',
        'writeInfoLine: "v71 probe"',
        '',
        '# --- 3. RULING 3: A MULTI-COLUMN PRESS, EXPORTED -------------------',
        'Create Table with column names: "v71norm", 9, "sym rskew lskew"',
        'v71t = selected ("Table")',
        paste0('sym# = { ', paste(sym, collapse = ", "), ' }'),
        paste0('rsk# = { ', paste(rskew, collapse = ", "), ' }'),
        paste0('lsk# = { ', paste(lskew, collapse = ", "), ' }'),
        'for r from 1 to 9',
        '    Set numeric value: r, "sym",   sym# [r]',
        '    Set numeric value: r, "rskew", rsk# [r]',
        '    Set numeric value: r, "lskew", lsk# [r]',
        'endfor',
        'clearinfo',
        '@emlRunNormalityAnalysis: v71t, "sym",   "both"',
        '@emlRunNormalityAnalysis: v71t, "rskew", "both"',
        '@emlRunNormalityAnalysis: v71t, "lskew", "both"',
        'v71rep$ = info$ ()',
        '@emlExportResultFiles: outDir$, "v71_multi"',
        'writeInfoLine: "v71 probe resumed"',
        'appendInfoLine: "n|multi|", emlExportResultFiles.nWritten',
        '# The press really did hold three columns, and the numbers under test',
        '# really are three different numbers. Read off the press, not off the',
        '# file -- otherwise the file is being compared with itself.',
        'appendInfoLine: "press|n|", emlNorm_n',
        'for i from 1 to emlNorm_n',
        '    appendInfoLine: "press|", emlNorm_col$ [i], "|",',
        '    ... string$ (emlNorm_skew [i]), "|", string$ (emlNorm_kurt [i])',
        'endfor',
        '',
        '# --- 3b. AND THE ONE-COLUMN PRESS IT USED TO DISAGREE WITH ---------',
        '@emlRunNormalityAnalysis: v71t, "rskew", "single"',
        '@emlExportResultFiles: outDir$, "v71_single"',
        'appendInfoLine: "n|single|", emlExportResultFiles.nWritten',
        'removeObject: v71t',
        '',
        '# --- 4. THE ARM WITH NO SHAPIRO-WILK -------------------------------',
        '# Shapiro-Wilk refuses above n = 5000, so both columns take the error',
        '# branch and the shape statistics are the whole answer. This also',
        "# drives @eml_orderedCols' OTHER rule: statistic and p.value are empty",
        '# in every row and are properly absent from the written header.',
        'Create Table with column names: "v71big", 5001, "big1 big2"',
        'v71b = selected ("Table")',
        'Formula: "big1", "row * row"',
        'Formula: "big2", "row * row"',
        'clearinfo',
        '@emlRunNormalityAnalysis: v71b, "big1", "both"',
        '@emlRunNormalityAnalysis: v71b, "big2", "both"',
        '@emlExportResultFiles: outDir$, "v71_big"',
        'writeInfoLine: "v71 probe resumed 2"',
        'appendInfoLine: "n|big|", emlExportResultFiles.nWritten',
        'appendInfoLine: "press|bigerr|", emlNorm_err$ [1]',
        'removeObject: v71b',
        '',
        '# --- 6. ITEM 12b: THE CAUTION, PRINTED AND EXPORTED ----------------',
        '# Branch one: n = 2 subjects.',
        'Create Table with column names: "v71rm", 2, "c1 c2 c3"',
        'v71r = selected ("Table")',
        'Set numeric value: 1, "c1", 3.1',
        'Set numeric value: 1, "c2", 5.4',
        'Set numeric value: 1, "c3", 9.2',
        'Set numeric value: 2, "c1", 4.7',
        'Set numeric value: 2, "c2", 4.1',
        'Set numeric value: 2, "c3", 7.8',
        'clearinfo',
        '@emlRunRepeatedMeasuresAnalysis: v71r, "s", "c1|c2|c3", 0, "holm"',
        'v71rm1$ = info$ ()',
        '@emlExportResultFiles: outDir$, "v71_rm1"',
        'writeInfoLine: "v71 probe resumed 3"',
        'appendInfoLine: "rm1|BEGIN|"',
        'appendInfo: v71rm1$',
        'appendInfoLine: "rm1|END|"',
        'removeObject: v71r',
        '',
        '# Branch two: k = 2, where Greenhouse-Geisser epsilon is 1 by',
        '# construction and therefore sits on its own lower bound.',
        'Create Table with column names: "v71rm2", 4, "c1 c2"',
        'v71r2 = selected ("Table")',
        'Set numeric value: 1, "c1", 3.1',
        'Set numeric value: 2, "c1", 4.7',
        'Set numeric value: 3, "c1", 2.2',
        'Set numeric value: 4, "c1", 5.9',
        'Set numeric value: 1, "c2", 6.4',
        'Set numeric value: 2, "c2", 5.1',
        'Set numeric value: 3, "c2", 7.7',
        'Set numeric value: 4, "c2", 6.0',
        'clearinfo',
        '@emlRunRepeatedMeasuresAnalysis: v71r2, "s", "c1|c2", 0, "holm"',
        'v71rm2$ = info$ ()',
        '@emlExportResultFiles: outDir$, "v71_rm2"',
        'writeInfoLine: "v71 probe resumed 4"',
        'appendInfoLine: "rm2|BEGIN|"',
        'appendInfo: v71rm2$',
        'appendInfoLine: "rm2|END|"',
        'removeObject: v71r2',
        '',
        '# --- 7. WHERE THE TWO FORMATTERS PART COMPANY ----------------------',
        '# The bound is 1 / (k - 1). Measured on THIS binary rather than',
        '# quoted from a comment, so the day a future Praat changes fixed$',
        '# this line says so instead of the source being quietly wrong.',
        'k71# = { 3, 12, 1002, 10001, 10002, 20002 }',
        'for i from 1 to size (k71#)',
        '    kk = k71# [i]',
        '    @eml_fixed: 1 / (kk - 1), 4',
        '    appendInfoLine: "eps|", kk, "|", fixed$ (1 / (kk - 1), 4), "|",',
        '    ... eml_fixed.result$',
        'endfor'), probe)

    outTxt <- suppressWarnings(system2("env",
        c("-u", "DISPLAY", shQuote(praat),
          shQuote(paste0("--pref-dir=", prefs)), "--run", shQuote(probe)),
        stdout = TRUE, stderr = TRUE))

    got <- function(tag, field) {
        p <- sprintf("^%s\\|%s\\|", tag, field)
        sub(p, "", grep(p, outTxt, value = TRUE))
    }
    block <- function(name) {
        b <- grep(sprintf("^%s\\|BEGIN\\|$", name), outTxt)
        e <- grep(sprintf("^%s\\|END\\|$", name), outTxt)
        if (!length(b) || !length(e) || e[1] - b[1] < 2) return(character(0))
        outTxt[(b[1] + 1):(e[1] - 1)]
    }
    one <- function(x, default = NA_character_) {
        if (length(x) == 1 && nzchar(x)) x else default
    }
    # A VALIDATOR THAT DIES HAS REPORTED NOTHING, and this file learned that
    # from its own break battery rather than from a principle. B01 -- both
    # files reverted to HEAD, which is the defect this file exists to catch --
    # handed `check` a zero-length value, because `frame$skewness[1]` on a
    # frame with no skewness column is not NA, it is nothing at all. R aborted
    # mid-run and the case reported zero failures. Every CSV cell read below
    # goes through one of these two, so a missing column fails a check instead
    # of ending the run. It is the same repair v65's `one()` is, found the same
    # way, and it is why a break battery is run against the file rather than
    # reasoned about.
    # A ROW INDEX THAT IS ITSELF MISSING IS THE SECOND HALF OF THE SAME
    # LESSON. B21 -- the tidy loop cut to one row -- makes match("rskew", term)
    # return NA, and `nrow(df) < NA` is NA, which is not a condition R will
    # branch on. The first version of this guard survived a missing COLUMN and
    # died on a missing ROW, in a case built to test something else entirely.
    cell <- function(df, col, row = 1L) {
        if (is.null(df) || length(row) != 1L || is.na(row) ||
            !(col %in% names(df)) || nrow(df) < row)
            return(NA_character_)
        as.character(df[[col]][row])
    }
    num1 <- function(x) {
        v <- suppressWarnings(as.numeric(x))
        if (length(v) != 1L) NA_real_ else v
    }
    ran <- !any(grepl("^Error", outTxt)) && length(got("n", "multi")) == 1
    if (!ran) cat(sprintf("      v71 probe output: %s\n",
                          paste(utils::tail(outTxt, 10), collapse = " / ")))
    check_true("v71", "the probe ran", ran)

    csv <- function(nm) {
        f <- file.path(work, "out", nm)
        if (!file.exists(f)) return(NULL)
        read.csv(f, stringsAsFactors = FALSE, check.names = FALSE)
    }
    # AND THE SAME FILE UNPARSED. read.csv turns 2.490080947185459 into a
    # double and back into "2.49008094718546", which is a fifteen-digit
    # rendering of R's own making. A check on the BYTES the plugin wrote has to
    # see the bytes, so the round-trip comparison below reads a second,
    # character-typed copy rather than R's reprint of its own parse.
    csvRaw <- function(nm) {
        f <- file.path(work, "out", nm)
        if (!file.exists(f)) return(NULL)
        read.csv(f, stringsAsFactors = FALSE, check.names = FALSE,
                 colClasses = "character")
    }

    if (ran) {
        # -- 3. THE VALUES, READ OUT OF THE WRITTEN FILE --------------------
        tm <- csv("v71_multi_tidy.csv")
        check_true("v71",
                   "the three-column press wrote its tidy frame",
                   !is.null(tm))
        if (!is.null(tm)) {
            check_true("v71",
                       sprintf("it is one row per column tested (%d rows)", nrow(tm)),
                       nrow(tm) == 3L)
            check_true("v71",
                       sprintf("and it names them (%s)",
                               paste(tm$term, collapse = ",")),
                       identical(tm$term, c("sym", "rskew", "lskew")))
            check_true("v71",
                       sprintf("the written header carries the two additions (%s)",
                               paste(names(tm), collapse = ",")),
                       all(c("skewness", "kurtosis") %in% names(tm)))
            # THE ORDER OF THE FILE IS THE ORDER OF THE VOCABULARY, which is
            # the property @eml_orderedCols exists to give and the one a
            # reader diffing against broom's own frame would notice first.
            check_true("v71",
                       sprintf("in the vocabulary's order, shape between p.value and method (%s)",
                               paste(names(tm), collapse = ",")),
                       identical(names(tm),
                                 c("term", "statistic", "p.value",
                                   "skewness", "kurtosis", "method")))
            if (all(c("skewness", "kurtosis") %in% names(tm)) && nrow(tm) == 3L) {
                dat <- list(sym = sym, rskew = rskew, lskew = lskew)
                for (i in seq_len(nrow(tm))) {
                    nm <- tm$term[i]
                    x <- dat[[nm]]
                    check("v71", sprintf("exported skewness for %s is that column's G1", nm),
                          num1(cell(tm, "skewness", i)), skewness_g1(x), tol = 1e-9)
                    check("v71", sprintf("exported kurtosis for %s is that column's G2", nm),
                          num1(cell(tm, "kurtosis", i)), excess_kurtosis(x), tol = 1e-9)
                }
                # THE FIXTURE IS DOING ITS JOB. Said as a property of the data
                # rather than of the plugin: if a future edit to this file made
                # the three columns agree, the six checks above would still
                # pass and would have stopped separating anything.
                sk <- suppressWarnings(as.numeric(tm$skewness))
                ku <- suppressWarnings(as.numeric(tm$kurtosis))
                check("v71", "the symmetric column really is symmetric (G1 = 0)",
                      num1(sk[1]), 0, tol = 1e-12)
                check("v71",
                      "the mirror pair really is a mirror: equal G2",
                      num1(ku[2]), num1(ku[3]), tol = 1e-12)
                check("v71",
                      "and opposite G1, so a clamp or a copy cannot satisfy both",
                      num1(sk[2]), num1(-sk[3]), tol = 1e-12)
                check_true("v71",
                           sprintf("no two of the three rows share a skewness (%s)",
                                   paste(signif(sk, 6), collapse = ",")),
                           length(unique(signif(sk, 12))) == 3L)
            }
            # AND THE FILE AGREES WITH THE PRESS THAT PRODUCED IT. The press's
            # own arrays are printed above; comparing the file against them
            # closes the gap between "R and the plugin agree" and "the value
            # that reached the file is the value the analysis computed".
            pn <- suppressWarnings(as.integer(one(got("press", "n"))))
            check_true("v71",
                       sprintf("the press held three columns (%s)",
                               if (is.na(pn)) "unreadable" else pn),
                       identical(pn, 3L))
            tmRaw <- csvRaw("v71_multi_tidy.csv")
            for (nm in c("sym", "rskew", "lskew")) {
                p <- strsplit(one(got("press", nm), "|"), "|", fixed = TRUE)[[1]]
                i <- if (is.null(tmRaw)) NA_integer_ else match(nm, tmRaw$term)
                check_true("v71",
                           sprintf("the file's %s row carries the press's own skewness and kurtosis, digit for digit",
                                   nm),
                           length(p) == 2 && !is.na(i) &&
                           identical(tmRaw$skewness[i], p[1]) &&
                           identical(tmRaw$kurtosis[i], p[2]))
            }
        }

        # -- 3b. THE ASYMMETRY RULING 3 WAS ABOUT IS GONE ------------------
        # Not "tidy has them" but "tidy and glance now say the same thing
        # about the same column", which is the sentence the ruling is written
        # in. A repair that added the columns to tidy and dropped them from
        # glance would pass every check above and fail this one.
        ts <- csv("v71_single_tidy.csv"); gs <- csv("v71_single_glance.csv")
        check_true("v71", "the one-column press wrote both frames",
                   !is.null(ts) && !is.null(gs))
        if (!is.null(ts) && !is.null(gs) && !is.null(tm)) {
            check_true("v71",
                       sprintf("single-column glance still carries shape (%s)",
                               paste(names(gs), collapse = ",")),
                       all(c("skewness", "kurtosis") %in% names(gs)))
            check_true("v71",
                       "single-column tidy carries it too, so the two presses no longer disagree",
                       all(c("skewness", "kurtosis") %in% names(ts)))
            i <- match("rskew", tm$term)
            check("v71",
                  "and the one-column and three-column files give rskew the same skewness",
                  num1(cell(ts, "skewness")), num1(cell(tm, "skewness", i)), tol = 1e-12)
            check("v71",
                  "and the same kurtosis",
                  num1(cell(ts, "kurtosis")), num1(cell(tm, "kurtosis", i)), tol = 1e-12)
        }

        # -- 4. THE ARM WITH NO SHAPIRO-WILK -------------------------------
        tb <- csv("v71_big_tidy.csv")
        check_true("v71",
                   sprintf("Shapiro-Wilk really did decline on the n = 5001 columns (%s)",
                           one(got("press", "bigerr"), "nothing")),
                   nzchar(one(got("press", "bigerr"), "")))
        check_true("v71", "the out-of-range press still wrote a tidy frame",
                   !is.null(tb))
        if (!is.null(tb)) {
            check_true("v71",
                       sprintf("with shape on every row and no W (%s)",
                               paste(names(tb), collapse = ",")),
                       all(c("skewness", "kurtosis") %in% names(tb)) &&
                       !("statistic" %in% names(tb)) &&
                       !("p.value" %in% names(tb)))
            check("v71",
                  "and the skewness written on the no-W arm is the real one",
                  num1(cell(tb, "skewness")), skewness_g1(big), tol = 1e-6)
            check("v71",
                  "and so is the kurtosis",
                  num1(cell(tb, "kurtosis")), excess_kurtosis(big), tol = 1e-6)
        }

        # -- 5. THE EXPORT'S OWN SIGNPOST IS TRUE OF THE EXPORT -------------
        # The multi-column glance `warning` tells the reader where the
        # per-column numbers are. It is the only exported string in the
        # normality path whose content is a claim ABOUT the artefact, so it
        # goes stale the moment the artefact moves -- and it did go stale on
        # the morning of this change, when it still sent the reader to the
        # Info window for two numbers that had just become columns. What is
        # checked is not its wording but its truth: every column it names as
        # being in the tidy frame is a column of the tidy frame.
        gm <- csv("v71_multi_glance.csv")
        check_true("v71", "the three-column press wrote its glance frame",
                   !is.na(cell(gm, "warning")))
        if (!is.null(gm) && "warning" %in% names(gm) && !is.null(tm)) {
            w <- cell(gm, "warning")
            said <- sub(".*;\\s*the per-column\\s*", "", w)
            said <- sub("\\s*are in the tidy frame.*", "", said)
            named <- unlist(strsplit(said, "\\s*,\\s*|\\s+and\\s+"))
            named <- tolower(trimws(named)); named <- named[nzchar(named)]
            wanted <- ifelse(named == "w", "statistic",
                      ifelse(named == "p", "p.value", named))
            check_true("v71",
                       sprintf("the glance warning names where the per-column numbers are (%d named)",
                               length(named)),
                       length(named) >= 2 && grepl("tidy frame", w, fixed = TRUE))
            check_true("v71",
                       sprintf("and every column it sends the reader to is really in the tidy file (%d named, file has %d)",
                               length(wanted), length(names(tm))),
                       length(wanted) >= 2 && all(wanted %in% names(tm)))
            check_true("v71",
                       "and it no longer sends them to the report for the shape statistics",
                       !grepl("skewness, kurtosis and recommendation", w, fixed = TRUE))
        }

        # -- 6. ITEM 12b: TWO STRINGS, TWO DESTINATIONS --------------------
        # THE EXPORTED BYTES ARE FROZEN. This repository normally refuses a
        # typed literal, for the reason REGISTRY.md gives: a literal copied
        # from the wrong side of the chain makes a check that validates
        # nothing. The exception is a check whose SUBJECT is byte-identity,
        # which is this one. Both strings below were driven out of HEAD
        # e467824 -- the tree before the split -- on 16 August 2026 and read
        # off the written glance CSV, and the whole assertion of item 12b is
        # that a reader who exported this analysis yesterday and again today
        # gets the same cell.
        rm1exp <- paste0(
            "n = 2 subjects. Greenhouse-Geisser epsilon is forced to its lower ",
            "bound 0.5000 for any data at this n, so the sphericity correction ",
            "carries no information. Read F, p and the corrected p as ",
            "description of these two subjects, not as a test.")
        rm2exp <- paste0(
            "Greenhouse-Geisser epsilon is at its lower bound 1.0000, the ",
            "maximum possible departure from sphericity. The corrected p is ",
            "the most conservative value the correction can produce.")
        for (leg in list(list("rm1", rm1exp, 3L), list("rm2", rm2exp, 2L))) {
            nm <- leg[[1]]; want <- leg[[2]]; kk <- leg[[3]]
            g <- csv(sprintf("v71_%s_glance.csv", nm))
            check_true("v71",
                       sprintf("%s: the repeated-measures glance frame was written with a warning",
                               nm),
                       !is.na(cell(g, "warning")) && nzchar(cell(g, "warning")))
            if (!is.null(g) && "warning" %in% names(g)) {
                check_true("v71",
                           sprintf("%s: the exported caution is byte-identical to HEAD e467824",
                                   nm),
                           identical(cell(g, "warning"), want))
            }
            # THE PRINTED ONE. Located by its own prefix, joined back out of
            # @emlWrapText's line breaks, and asserted to be the same sentence
            # -- not merely to exist. Then the bound it quotes is checked as a
            # VALUE against R, because a formatter clamped to a zero of the
            # right width would satisfy any width assertion written here.
            b <- block(nm)
            ci <- grep("^\\s*Caution:", b)
            joined <- if (length(ci)) {
                stop <- length(b)
                paste(trimws(b[ci[1]:stop]), collapse = " ")
            } else NA_character_
            joined <- if (is.na(joined)) NA_character_ else
                      trimws(sub("^Caution:\\s*", "", joined))
            check_true("v71",
                       sprintf("%s: the report printed the caution", nm),
                       !is.na(joined) && nzchar(joined))
            if (!is.na(joined)) {
                check_true("v71",
                           sprintf("%s: and it is the same sentence the file carries", nm),
                           identical(joined, want))
                tok <- regmatches(joined, regexpr("[0-9]+\\.[0-9]+", joined))
                dec <- if (length(tok)) nchar(sub("^.*\\.", "", tok)) else NA_integer_
                check_true("v71",
                           sprintf("%s: the epsilon bound prints at exactly four decimals (%s)",
                                   nm, if (length(tok)) tok else "no number found"),
                           length(tok) == 1 && identical(dec, 4L))
                check("v71",
                      sprintf("%s: and it is the bound, 1/(k-1), not a zero of the right width",
                              nm),
                      num1(if (length(tok)) tok else NA_character_),
                      1 / (kk - 1), tol = 5e-5)
            }
        }
        # WHICH VARIABLE EACH DESTINATION READS. This is the assertion the
        # split actually consists of, and the only one that goes red on a
        # revert: because the two strings render identically at every k the
        # plugin can be driven at, no measurement of the printed output can
        # tell a split tree from HEAD. Statement-joined, comments stripped.
        if (file.exists(srcAna)) {
            sta <- praat_statements(srcAna)
            prt <- grep('@emlWrapText:\\s*"Caution:\\s*"\\s*\\+\\s*emlRMAnovaTest\\.',
                        sta$text)
            exp <- grep('@emlGlanceStr:\\s*"warning",\\s*emlRMAnovaTest\\.',
                        sta$text)
            check_true("v71",
                       sprintf("the report reads .warningPrinted$ (%d site(s))", length(prt)),
                       length(prt) == 1 &&
                       grepl("emlRMAnovaTest\\.warningPrinted\\$", sta$text[prt]))
            check_true("v71",
                       sprintf("the glance frame reads .warning$ (%d site(s))", length(exp)),
                       length(exp) == 1 &&
                       grepl("emlRMAnovaTest\\.warning\\$", sta$text[exp]) &&
                       !grepl("warningPrinted", sta$text[exp]))
            # AND THE TWO ARE BUILT DIFFERENTLY, which is what makes them two
            # strings rather than one aliased twice. The exported family keeps
            # the raw fixed$ that v65's census classifies and exempts; the
            # printed family goes through the shared @eml_fixed and through no
            # other rounding.
            wex <- grep('(^|\\s)\\.warning\\$\\s*=.*fixed\\$\\s*\\(', sta$text)
            wprAll <- grep('(^|\\s)\\.warningPrinted\\$\\s*=', sta$text)
            wprClear <- wprAll[grepl('\\.warningPrinted\\$\\s*=\\s*""\\s*$',
                                     trimws(sta$text[wprAll]))]
            wpr <- setdiff(wprAll, wprClear)
            check_true("v71",
                       sprintf("both exported cautions are built with the raw fixed$ v65 exempts (%d)",
                               length(wex)),
                       length(wex) == 2)
            check_true("v71",
                       sprintf("both printed cautions are built with eml_fixed.result$ (%d built, %d cleared)",
                               length(wpr), length(wprClear)),
                       length(wpr) == 2 &&
                       all(grepl("eml_fixed\\.result\\$", sta$text[wpr])) &&
                       !any(grepl("fixed\\$\\s*\\(", sta$text[wpr])))
            # THE CLEAR IS PART OF THE SPLIT, not housekeeping. A Praat
            # procedure's locals survive from the previous invocation and the
            # degenerate arm jumps past both assignments, so a run that
            # refuses would otherwise print the PREVIOUS analysis's caution
            # under this one's numbers. The exported string has always been
            # cleared at the top; the printed one has to be cleared beside it
            # or the split introduces the very staleness it is tidying up.
            check_true("v71",
                       sprintf("and the printed one is cleared at entry beside the exported one (%d clear(s))",
                               length(wprClear)),
                       length(wprClear) == 1 &&
                       any(grepl('(^|\\s)\\.warning\\$\\s*=\\s*""\\s*$',
                                 trimws(sta$text))))
            check_true("v71",
                       "and the printed one is not simply assigned from the exported one",
                       !any(grepl('\\.warningPrinted\\$\\s*=\\s*\\.warning\\$\\s*$',
                                  trimws(sta$text))))
            check_true("v71",
                       "eml-analysis.praat still defines no formatter of its own",
                       !any(grepl("^\\s*procedure\\s+eml_fixed\\b", sta$text)))
        }
        # -- 7. WHERE THE TWO FORMATTERS PART COMPANY, MEASURED ------------
        # The split changes nothing a user can see today. That is a claim
        # about this binary's fixed$, so it is measured on this binary rather
        # than asserted from a comment, and the k at which it stops being true
        # is recorded. A future Praat that fixes fixed$ turns the last check
        # here red, which is the event it exists to announce.
        eps <- function(k) {
            v <- one(got("eps", as.character(k)), "|")
            strsplit(v, "|", fixed = TRUE)[[1]]
        }
        agree <- c(3, 12, 1002, 10001)
        for (k in agree) {
            p <- eps(k)
            check_true("v71",
                       sprintf("at k = %d the two renderings of 1/(k-1) agree (%s)",
                               k, paste(p, collapse = " vs ")),
                       length(p) == 2 && identical(p[1], p[2]))
        }
        p1 <- eps(10002); p2 <- eps(20002)
        check_true("v71",
                   sprintf("at k = 10002 they part company (fixed$ %s, @eml_fixed %s)",
                           if (length(p1) == 2) p1[1] else "?",
                           if (length(p1) == 2) p1[2] else "?"),
                   length(p1) == 2 && !identical(p1[1], p1[2]) &&
                   identical(p1[2], "0.0001"))
        check_true("v71",
                   sprintf("and by k = 20002 the gap is a whole significant digit (%s vs %s)",
                           if (length(p2) == 2) p2[1] else "?",
                           if (length(p2) == 2) p2[2] else "?"),
                   length(p2) == 2 && identical(p2[1], "0.00005") &&
                   identical(p2[2], "0.0000"))
        attest("v71",
               sprintf("no repeated-measures design reaches k = 10002, so the split moves no printed byte today (measured on %s)",
                       if (is.na(pv)) "an unknown build" else pv),
               "driven live; the divergence threshold is a property of Praat's fixed$, re-measured on every run of this file")
    }
}

eml_report("v71 -- the tidy vocabulary and the repeated-measures caution")
