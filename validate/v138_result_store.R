# ============================================================================
# v138_result_store.R -- one write site, and every door that computes uses it
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS IS FOR.
#
# docs/RULING_RESULT_STORE.md section (d) puts the result store in PUBLISHED
# GLOBALS rather than in an Objects-window Table, and it does so WITH a
# discipline that answers their invisibility:
#
#   "Globals are chosen WITH the discipline that answers their invisibility:
#    ONE write site ... which states the whole result ... on every analysis
#    run, the way the pens are stated on every press."
#
# "Published state under a single-writer contract WITH A VALIDATOR CENSUS is
# not hidden state" is the ruling's sentence. This file is that census. Without
# it the store is exactly what the ruling rejected: state nobody can see, with
# a rule nobody enforces.
#
# THE FOUR THINGS IT ASSERTS, AND WHY EACH IS THE ONE THAT WOULD FAIL SILENTLY
#
#   1. ONE WRITER. Nothing but @emlPublishAnalysisResult assigns a name
#      beginning emlStore, anywhere in the shipped tree. A second writer is
#      how published state stops meaning anything: two paths, two truths, and
#      the reader cannot tell which one it got.
#
#   2. EVERY DOOR THAT COMPUTES PUBLISHES. The population is DERIVED, not
#      listed -- see THE DERIVATION below. A door that computes a group
#      comparison and does not publish leaves the door before it standing as
#      the answer to this question, which is the defect the single-writer
#      contract exists to prevent, and it is silent: the figure draws, the
#      numbers look like numbers.
#
#   3. THE KEY IS TAKEN AT THE READ. The fingerprint's own header names this
#      as the one failure its arithmetic cannot see -- "a key taken late is
#      truthful about the wrong moment, and no amount of digest width detects
#      that ... the fault is in the ORDER of the calls". The order is a text
#      fact, so a text check can hold it, and nothing else can.
#
#   4. EVERY PUBLISHED NAME IS CLASSIFIED, both ways. A name the write site
#      publishes and this file does not classify is red; a classification
#      whose name the write site no longer publishes is red. That is the same
#      ratchet v112 runs over the settings, applied to the store's own names,
#      and it is what stops the vocabulary drifting away from its description.
#
# THE DERIVATION, AND WHY IT IS NOT A LIST.
#
# A run computes a GROUP COMPARISON when it reads one numeric column split by
# the levels of one grouping column and computes an inferential statistic from
# the split. In this tree that is visible in source: such a run calls one of
# the value-by-group kernels -- each of which takes (.tableId, .dataCol$,
# .factorCol$) -- or splits the column itself with @eml_getGroupData or
# @emlExtractGroupVectors and hands the two vectors to @emlTTest or
# @emlMannWhitneyU. This file walks the shipped tree for those calls, maps
# each to the procedure it sits in, and asserts that every such procedure
# either publishes or is named in the exemption table below WITH ITS REASON.
#
# A LIST OF PUBLISHING DOORS WOULD GO STALE ON THE DAY A DOOR WAS ADDED, and
# the symptom would be a figure quoting the previous analysis. Derived, the
# check reddens on the day the door is WRITTEN.
#
# WHAT THE WALK CANNOT SEE, said plainly. Comments and double-quoted strings
# are blanked before calls are read, so a kernel named only inside a string is
# invisible to it -- which is right, that is prose and not a call. A kernel
# reached through a procedure this file does not know is a kernel is invisible
# too, which is why the kernel table below is a table with reasons and not a
# regular expression over names.
#
# THE RED DEMONSTRATION is harness/resultstore/seed_violation.sh: a COPY of
# the repository with one seeded violation per leg -- a second writer, a door
# that computes and does not publish, a key taken after the read, and a
# published name nobody classified -- each audited by THIS FILE UNMODIFIED
# through $EML_STORE_SRC. What goes red is this check, not a rehearsal of it.
#
# THE MEASURED HALF is harness/resultstore/out/STORE.tsv, written by
# harness/resultstore/run.sh, which drives the four menu doors and writes down
# what the store held after each. Source alone cannot say that a publication
# HAPPENED, that a refusal published, or that the key moved when a cell did.
#
# Base R only. Reads source and one measured artefact; drives nothing.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

V <- "v138"

if (!exists("check_true")) source(file.path(
    Sys.getenv("EML_VALIDATE_DIR", unset = "validate"), "helpers.R"))

# $EML_STORE_SRC names a REPOSITORY ROOT, not a plugin folder -- the same
# shape $EML_SETTINGS_SRC takes, so the seeding script sets one variable and
# both the source read and the artefact read follow it.
src <- Sys.getenv("EML_STORE_SRC", unset = "")
root <- if (nzchar(src)) src else repo_path(".")
plug <- file.path(root, "plugin_EML_StatsGraphs")

measured <- Sys.getenv("EML_STORE_OUT", unset = "")
if (!nzchar(measured))
    measured <- file.path(root, "harness", "resultstore", "out", "STORE.tsv")

WRITE_SITE <- "emlPublishAnalysisResult"
KEY_TAKE   <- "emlStoreKeyTake"

# ---------------------------------------------------------------------------
# THE KERNELS. Each row is a procedure that reads one value column split by
# one grouping column, or a two-sample test fed from such a split. The reason
# is carried because "which calls make a run a group comparison" is a reading,
# and a reading with no reason beside it cannot be audited later.
# ---------------------------------------------------------------------------
KERNELS <- c(
    "emlOneWayAnova"      = "one-way ANOVA on (table, data column, factor column)",
    "emlKruskalWallis"    = "Kruskal-Wallis on the same triple",
    "emlTukeyHSD"         = "Tukey HSD over every pair of levels",
    "emlDunnTest"         = "Dunn's test over every pair of levels",
    "emlPairwiseT"        = "pairwise t over every pair of levels",
    "emlPairwiseWilcoxon" = "pairwise Wilcoxon over every pair of levels",
    "emlScheffe"          = "Scheffe over every pair of levels",
    "emlWelchAnova"       = "Welch's ANOVA on the same triple",
    "emlGamesHowell"      = "Games-Howell over every pair of levels",
    "emlBrownForsythe"    = "Brown-Forsythe on the same triple",
    "emlTTest"            = "two-sample t; a group comparison when fed a split column",
    "emlMannWhitneyU"     = "Mann-Whitney U; likewise"
)

# ---------------------------------------------------------------------------
# THE EXEMPTIONS. A procedure that calls a kernel and does NOT publish, with
# the reason it does not. Every row is a decision; a row with no reason is not
# a decision anyone can check.
# ---------------------------------------------------------------------------
EXEMPT <- c(
    "emlReportAnovaComparison" =
        paste("the REPORT half of a run, not a run. It is called by",
              "@emlRunAnovaAnalysis and by @emlRunAnnotationComparison, and the",
              "extra comparisons it computes -- Brown-Forsythe, Welch's",
              "ANOVA, Games-Howell -- belong to whichever run called it. A",
              "reporter that published would publish twice per run and the",
              "second publication would be the one that stood"),
    "emlOneWayAnova" =
        paste("a KERNEL, and a kernel has no door, no dialog and no settings",
              "of its own: it is handed a table and two column names and",
              "returns numbers. It reaches @emlTukeyHSD when its caller asked",
              "for the post-hoc, which is what puts it in this population.",
              "Publishing from here would publish a fragment of whichever run",
              "called it, under no identity anyone chose"),
    "emlPairwiseT" =
        "a kernel, calling @emlTTest once per pair; see @emlOneWayAnova",
    "emlRankBiserialR" =
        paste("a kernel, calling @emlMannWhitneyU to get U before converting",
              "it; see @emlOneWayAnova"),
    "emlTTestAlt" =
        paste("a kernel wrapper around @emlTTest for one-tailed alternatives;",
              "see @emlOneWayAnova")
)

# ---------------------------------------------------------------------------
# THE STORE'S CENSUS: every published name, and what it is. This is the
# section (b) census pattern applied to the store's OWN names -- declared as
# DATA in one place, not as comments -- and it ratchets both ways.
#
# NOTE FOR A READER COMING FROM v112. These names are NOT settings and do not
# belong in either of v112's two lists: they are the analysis's OUTPUT. v112's
# own derivation says so and does the classifying mechanically -- a global
# written inside the draw doors' call closure is excluded from its population
# as "what the analysis PRODUCES, not a setting fed into it", and the store's
# names are written there precisely because the draw door publishes. THAT
# EXCLUSION IS LOAD-BEARING AND HOLDS ONLY WHILE THE DRAW DOOR PUBLISHES: the
# day the bridge consumes without publishing, every one of these names enters
# v112's population unclassified and v112 goes red. That is the correct alarm
# and it is worth knowing it is armed.
# ---------------------------------------------------------------------------
PUBLISHED <- c(
    "emlStoreFormat$"     = "format tag; a reader compares it before anything else",
    "emlStoreRun"         = "publication counter; DIAGNOSTIC, never validity",
    "emlStoreValid"       = "1 when the run computed a result, 0 when it refused",
    "emlStoreError$"      = "the producer's own refusal text",
    "emlStoreProducer$"   = "which procedure published; diagnostic",
    "emlStoreDoor$"       = "menu or figure; descriptive, not identity",
    "emlStoreKind$"       = "the analysis family",
    "emlStoreKey$"        = "the section (a) fingerprint, taken at the read",
    "emlStoreKeyError$"   = "why no key could be taken, in the fingerprint's own words",
    "emlStoreKeyError$"   = "why no key could be taken, in the fingerprint's own words",
    "emlStoreTableId"     = "the Table the result was computed on",
    "emlStoreTableName$"  = "its object name, for the Info window",
    # ITEM 1.2, Fable 26 Aug -- the canonical report text, rendered by the
    # minimal renderer (@emlEmit, stats/eml-output.praat) and handed to the
    # write site through emlPublishInReport$. "" means NO REPORT WAS
    # PRINTED for this result, which is not an empty report: it is what the
    # changed-setting path publishes, and a stored "" never matches, so a
    # later run can never fall silent against a report nobody has read.
    "emlStoreReport$"     = paste("the text of the report printed for this",
                                  "result -- factual and disclosure lines",
                                  "only, no explanations, no timestamp;",
                                  "\"\" when no report was printed. The 24",
                                  "August reprint rule is decided against",
                                  "this name, not against the key."),
    "emlStoreDataCol$"    = "IDENTITY (1.4): the value column",
    "emlStoreGroupCol$"   = "IDENTITY (1.4): the grouping column",
    "emlStoreTestType$"   = "IDENTITY (1.4): the test that ran",
    "emlStoreCorrection$" = "IDENTITY (1.4): the adjustment applied",
    "emlStoreAlpha"       = "IDENTITY (1.4): the threshold the verdicts were taken at",
    "emlStoreGroupSort$"  = "IDENTITY (1.4): the group sort order, stamped at the read",
    "emlStoreNGroups"     = "k",
    "emlStoreGroupLabel$" = "the level labels in the order the contrasts were formed",
    "emlStoreOmnibusLabel$" = "what the omnibus statistic is",
    "emlStoreOmnibusStat" = "its value",
    "emlStoreDf1"         = "first df",
    "emlStoreDf2"         = "second df",
    "emlStoreOmnibusP"    = "the omnibus p",
    "emlStoreEffectLabel$" = "what the omnibus effect size is",
    "emlStoreEffect"      = "its value",
    "emlStoreN"           = "the analysed N where the producer states one",
    "emlStoreSecondLabel$" = "the second arm's statistic, where a door ran two tests",
    "emlStoreSecondStat"  = "its value",
    "emlStoreSecondDf1"   = "its df",
    "emlStoreSecondP"     = "its p",
    "emlStoreSecondEffectLabel$" = "the second arm's effect size",
    "emlStoreSecondEffect" = "its value",
    "emlStorePostHoc$"    = "which post-hoc produced the matrices",
    "emlStoreHasMatrix"   = "1 when the matrices are at the group set's shape",
    "emlStoreStatLabel$"  = "what the per-pair statistic matrix holds",
    "emlStorePairEffectLabel$" = "what the per-pair effect matrix holds",
    "emlStorePMatrix##"   = "adjusted p per pair",
    "emlStoreDiffMatrix##" = "signed difference per pair",
    "emlStoreStatMatrix##" = "the per-pair test statistic",
    "emlStoreEffectMatrix##" = "the signed per-pair effect size"
)

# ---------------------------------------------------------------------------
# 1. READ THE TREE
# ---------------------------------------------------------------------------
ok_tree <- check_true(V, "the plugin tree the census reads is present",
                      dir.exists(plug))
if (!ok_tree) {
    if (!exists("EML_SUITE")) { eml_report("v138 -- the result store"); eml_exit() }
}

files <- list.files(plug, pattern = "\\.praat$", recursive = TRUE,
                    full.names = TRUE)
files <- files[!grepl("/dev/", files, fixed = TRUE)]

strip <- function(t) {
    t <- sub("^[[:space:]]*[;#].*$", "", t)
    gsub('"[^"]*"', " ", t)
}

# Every procedure body in the tree, keyed by name, with the file and the line
# each began on -- the ordering leg needs the line numbers.
bodies <- list(); where <- list()
for (p in files) {
    ln <- readLines(p, warn = FALSE)
    starts <- grep("^procedure [A-Za-z]", ln)
    ends   <- grep("^endproc[[:space:]]*$", ln)
    for (s in starts) {
        e <- ends[ends > s]
        if (!length(e)) next
        e <- e[1]
        nm <- sub("^procedure ([A-Za-z0-9_]+).*$", "\\1", ln[s])
        bodies[[nm]] <- ln[s:e]
        where[[nm]]  <- basename(p)
    }
}

check_true(V, sprintf("the walk found procedure bodies (%d)", length(bodies)),
           length(bodies) > 100)
check_true(V, sprintf("the write site @%s is in the tree", WRITE_SITE),
           !is.null(bodies[[WRITE_SITE]]))
check_true(V, sprintf("the key take @%s is in the tree", KEY_TAKE),
           !is.null(bodies[[KEY_TAKE]]))

# ---------------------------------------------------------------------------
# 2. ONE WRITER
# ---------------------------------------------------------------------------
# An undotted assignment to a name beginning emlStore, anywhere outside the
# write site. `emlPublishInLabel$` is an INPUT and is named so that this rule
# needs no exception in it.
WRX <- "^[[:space:]]*(emlStore[A-Za-z0-9_]*[#$]{0,2})[[:space:]]*(\\[[^]]*\\])?[[:space:]]*(\\+=|=)([^=]|$)"
# The same name, without the assignment tail, for reading the name back out.
NMX <- "^[[:space:]]*(emlStore[A-Za-z0-9_]*[#$]{0,2})"
writers <- list()
for (p in files) {
    ln <- strip(readLines(p, warn = FALSE))
    hits <- grep(WRX, ln, perl = TRUE)
    if (!length(hits)) next
    # which procedure each hit sits in
    raw <- readLines(p, warn = FALSE)
    starts <- grep("^procedure [A-Za-z]", raw)
    nms <- sub("^procedure ([A-Za-z0-9_]+).*$", "\\1", raw[starts])
    for (h in hits) {
        owner <- if (any(starts <= h)) nms[max(which(starts <= h))] else "(top level)"
        writers[[length(writers) + 1L]] <- data.frame(
            proc = owner, file = basename(p), line = h,
            text = trimws(raw[h]), stringsAsFactors = FALSE)
    }
}
writers <- if (length(writers)) do.call(rbind, writers) else
    data.frame(proc = character(0), file = character(0), line = integer(0),
               text = character(0), stringsAsFactors = FALSE)

foreign <- writers[writers$proc != WRITE_SITE, , drop = FALSE]
check_true(V,
           sprintf("nothing but @%s assigns an emlStore name (%d assignment(s) walked%s)",
                   WRITE_SITE, nrow(writers),
                   if (nrow(foreign))
                       paste0(" -- SECOND WRITER: ",
                              paste(sprintf("%s:%d in @%s", foreign$file,
                                            foreign$line, foreign$proc),
                                    collapse = "; "))
                   else ""),
           nrow(foreign) == 0)
check_true(V,
           sprintf("the write site actually writes (%d assignments in @%s)",
                   sum(writers$proc == WRITE_SITE), WRITE_SITE),
           sum(writers$proc == WRITE_SITE) > 20)

# ---------------------------------------------------------------------------
# 3. THE STORE'S CENSUS, BOTH WAYS
# ---------------------------------------------------------------------------
published <- unique(sub(NMX, "\\1",
    regmatches(writers$text[writers$proc == WRITE_SITE],
               regexpr(NMX, writers$text[writers$proc == WRITE_SITE]))))
published <- trimws(published)
published <- sort(published)
classified <- sort(names(PUBLISHED))

unclassified <- setdiff(published, classified)
stale        <- setdiff(classified, published)

check_true(V,
           sprintf("every published name is classified (%d published%s)",
                   length(published),
                   if (length(unclassified))
                       paste0(" -- UNCLASSIFIED: ",
                              paste(unclassified, collapse = ", "))
                   else ""),
           length(unclassified) == 0)
check_true(V,
           sprintf("every classification names something the store publishes%s",
                   if (length(stale))
                       paste0(" -- STALE: ", paste(stale, collapse = ", "))
                   else " (no stale rows)"),
           length(stale) == 0)
check_true(V, "every classification carries a reason",
           all(nzchar(PUBLISHED)))
check_true(V,
           sprintf("the census is not empty (%d classified names)", length(classified)),
           length(classified) > 20)

# THE IDENTITY IS THE FIVE FIELDS ITEM 1.4 NAMES, AND NO OTHERS. A sixth
# field slipped into the identity would make two runs of one analysis compare
# as two; a missing one would serve a result computed under other settings.
identity <- sort(names(PUBLISHED)[grepl("^IDENTITY", PUBLISHED)])
expected_identity <- sort(c("emlStoreDataCol$", "emlStoreGroupCol$",
                            "emlStoreTestType$", "emlStoreCorrection$",
                            "emlStoreAlpha", "emlStoreGroupSort$"))
check_true(V,
           sprintf("the identity is exactly punch item 1.4's fields (%s)",
                   paste(identity, collapse = ", ")),
           identical(identity, expected_identity))

# ---------------------------------------------------------------------------
# 4. EVERY DOOR THAT COMPUTES PUBLISHES
# ---------------------------------------------------------------------------
calls_in <- function(t) unique(sub("^@", "",
    unlist(regmatches(t, gregexpr("@[A-Za-z0-9_]+", t)))))

computes <- character(0)
for (nm in names(bodies)) {
    cl <- calls_in(strip(bodies[[nm]]))
    if (any(names(KERNELS) %in% cl)) computes <- c(computes, nm)
}
computes <- sort(computes)

publishes <- names(bodies)[vapply(names(bodies), function(nm)
    WRITE_SITE %in% calls_in(strip(bodies[[nm]])), logical(1))]
publishes <- sort(publishes)

check_true(V,
           sprintf("the derivation found doors that compute a group comparison (%d: %s)",
                   length(computes), paste(computes, collapse = ", ")),
           length(computes) >= 5)

silent <- setdiff(computes, c(publishes, names(EXEMPT)))
check_true(V,
           sprintf("every procedure that computes a group comparison publishes or is exempt with a reason%s",
                   if (length(silent))
                       paste0(" -- COMPUTES AND DOES NOT PUBLISH: ",
                              paste(silent, collapse = ", "))
                   else sprintf(" (%d publish, %d exempt)",
                                length(intersect(computes, publishes)),
                                length(intersect(computes, names(EXEMPT))))),
           length(silent) == 0)

# An exemption for a procedure that no longer computes is a row describing
# nothing, which is how a list starts lying.
dead_exempt <- setdiff(names(EXEMPT), computes)
check_true(V,
           sprintf("no exemption describes a procedure that does not compute%s",
                   if (length(dead_exempt))
                       paste0(" -- DEAD ROWS: ", paste(dead_exempt, collapse = ", "))
                   else ""),
           length(dead_exempt) == 0)
check_true(V, "every exemption carries a reason", all(nzchar(EXEMPT)))

# A procedure cannot be both.
both <- intersect(publishes, names(EXEMPT))
check_true(V,
           sprintf("nothing is both a publisher and an exemption%s",
                   if (length(both)) paste0(" -- BOTH: ", paste(both, collapse = ", ")) else ""),
           length(both) == 0)

# ---------------------------------------------------------------------------
# 5. THE KEY IS TAKEN AT THE READ
# ---------------------------------------------------------------------------
# In every publishing procedure, @emlStoreKeyTake must come BEFORE the first
# line that reads a value by group -- a kernel call, @eml_getGroupData or
# @emlExtractGroupVectors. This is the fingerprint's one uncheckable failure
# made checkable: the fault is in the ORDER of the calls, and order is text.
READS <- c(names(KERNELS), "eml_getGroupData", "emlExtractGroupVectors")
ord_rows <- list()
for (nm in publishes) {
    b <- strip(bodies[[nm]])
    take <- grep(paste0("@", KEY_TAKE, "\\b"), b)
    rd <- integer(0)
    for (k in READS) rd <- c(rd, grep(paste0("@", k, "\\b"), b))
    first_read <- if (length(rd)) min(rd) else NA_integer_
    ord_rows[[length(ord_rows) + 1L]] <- data.frame(
        proc = nm, take = if (length(take)) min(take) else NA_integer_,
        read = first_read, stringsAsFactors = FALSE)
}
ord <- if (length(ord_rows)) do.call(rbind, ord_rows) else
    data.frame(proc = character(0), take = integer(0), read = integer(0))

no_take <- ord$proc[is.na(ord$take)]
check_true(V,
           sprintf("every publisher takes the key itself (%d publisher(s)%s)",
                   nrow(ord),
                   if (length(no_take))
                       paste0(" -- NO KEY TAKEN IN: ", paste(no_take, collapse = ", "))
                   else ""),
           length(no_take) == 0 && nrow(ord) > 0)

late <- ord$proc[!is.na(ord$take) & !is.na(ord$read) & ord$take > ord$read]
check_true(V,
           sprintf("the key is taken before the first value-by-group read%s",
                   if (length(late))
                       paste0(" -- KEY TAKEN LATE IN: ", paste(late, collapse = ", "))
                   else sprintf(" (checked in %d publisher(s))",
                                sum(!is.na(ord$take) & !is.na(ord$read)))),
           length(late) == 0)

# ANTI-VACUOUS: the ordering leg is true of a publisher that reads nothing.
check_true(V,
           sprintf("the ordering leg had something to order (%d publisher(s) read a value by group)",
                   sum(!is.na(ord$read))),
           sum(!is.na(ord$read)) > 0)

# ---------------------------------------------------------------------------
# 6. THE PUBLICATION STATES THE WHOLE RESULT
# ---------------------------------------------------------------------------
# Praat refuses a call whose argument count does not match the signature, so
# an incomplete publication does not run -- but it does not run at the moment
# the door is USED, which may be months later. Counted here instead.
sig <- bodies[[WRITE_SITE]]
sig_end <- which(!grepl("^[[:space:]]*\\.\\.\\.", sig))[2] - 1
sig_txt <- paste(sig[1:sig_end], collapse = " ")
n_params <- length(unlist(regmatches(sig_txt,
                    gregexpr("\\.[A-Za-z][A-Za-z0-9_]*[#$]{0,2}", sig_txt))))
check_true(V, sprintf("the write site takes the whole result (%d parameters)", n_params),
           n_params >= 30)

call_rows <- list()
for (nm in publishes) {
    b <- bodies[[nm]]
    st <- grep(paste0("@", WRITE_SITE, ":"), b)
    for (s in st) {
        e <- s
        while (e + 1 <= length(b) && grepl("^[[:space:]]*\\.\\.\\.", b[e + 1])) e <- e + 1
        txt <- paste(b[s:e], collapse = " ")
        txt <- sub(paste0("^.*@", WRITE_SITE, ":"), "", txt)
        txt <- gsub('"[^"]*"', "S", txt)
        txt <- gsub("\\.\\.\\.", " ", txt)
        call_rows[[length(call_rows) + 1L]] <- data.frame(
            proc = nm, args = length(strsplit(txt, ",")[[1]]),
            stringsAsFactors = FALSE)
    }
}
calls <- if (length(call_rows)) do.call(rbind, call_rows) else
    data.frame(proc = character(0), args = integer(0))
bad <- calls[calls$args != n_params, , drop = FALSE]
check_true(V,
           sprintf("every publication passes the whole result (%d call site(s)%s)",
                   nrow(calls),
                   if (nrow(bad))
                       paste0(" -- SHORT: ",
                              paste(sprintf("%s passes %d of %d", bad$proc,
                                            bad$args, n_params), collapse = "; "))
                   else ""),
           nrow(bad) == 0 && nrow(calls) > 0)

# ---------------------------------------------------------------------------
# 7. NO PUBLICATION IS INSIDE A BRANCH
# ---------------------------------------------------------------------------
# A reader guards on ONE name and takes the rest on the write site's word:
# they are written in one pass with no goto and no early exit. That is only
# true while no published assignment sits inside an `if`, so it is checked
# rather than promised.
b <- strip(bodies[[WRITE_SITE]])
depth <- 0; inside <- character(0)
raw <- bodies[[WRITE_SITE]]
for (i in seq_along(b)) {
    line <- b[i]
    if (grepl("^[[:space:]]*(if|for|while|repeat)\\b", line)) depth <- depth + 1
    if (grepl("^[[:space:]]*(endif|endfor|endwhile|until)\\b", line)) depth <- depth - 1
    if (grepl(WRX, line, perl = TRUE) && depth > 0)
        inside <- c(inside, trimws(raw[i]))
}
# The two label loops are the documented exception: a loop with an empty range
# writes nothing, which is the same statement as writing nothing.
inside <- inside[!grepl("emlStoreGroupLabel\\$", inside)]
check_true(V,
           sprintf("no published name is written inside a branch%s",
                   if (length(inside))
                       paste0(" -- CONDITIONAL: ", paste(inside, collapse = "; "))
                   else ""),
           length(inside) == 0)
check_true(V, "the write site contains no goto",
           !any(grepl("^[[:space:]]*goto\\b", b)))

# ---------------------------------------------------------------------------
# 8. THE MEASURED HALF
# ---------------------------------------------------------------------------
# Source cannot say that a publication HAPPENED. harness/resultstore/run.sh
# drives the four menu doors and writes down what the store held after each.
if (!file.exists(measured)) {
    check_true(V, sprintf("the measured store artefact is present (%s)", measured),
               FALSE)
} else {
    tsv <- read.delim(measured, stringsAsFactors = FALSE, quote = "",
                      colClasses = "character")
    get <- function(case, field) {
        v <- tsv$value[tsv$case == case & tsv$field == field]
        if (!length(v)) NA_character_ else v[1]
    }
    cases <- unique(tsv$case)

    check_true(V, sprintf("the probe drove cases (%d)", length(cases)),
               length(cases) >= 12)

    # EVERY DOOR ACTUALLY PUBLISHED, and named itself.
    for (d in c("emlRunTwoGroupAnalysis", "emlRunAnovaAnalysis",
                "emlRunKruskalWallisAnalysis", "emlRunPairwiseAnalysis")) {
        check_true(V, sprintf("@%s published on the drive", d),
                   d %in% tsv$value[tsv$field == "producer"])
    }

    # THE COUNTER MOVES ON EVERY RUN -- which is how "this door published"
    # is distinguishable from "the door before it did".
    # THE COUNTER STARTS AT 1 IN A FRESH SESSION AND ONLY RISES. It is not
    # the case count: the probe drives analyses BETWEEN snapshots on purpose
    # -- the stale-slot and key-move legs each need a run in front of them --
    # so a gap in the sequence is a publication this file did not photograph,
    # not a publication that did not happen. What would be wrong is a repeat
    # or a fall, either of which means a door left the store alone.
    runs <- as.integer(tsv$value[tsv$field == "run"])
    runs <- runs[!is.na(runs)]
    check_true(V,
               sprintf("the publication counter starts at 1 and only rises (%s)",
                       paste(runs, collapse = ", ")),
               length(runs) > 0 && runs[1] == 1L && all(diff(runs) > 0))

    # A REFUSAL PUBLISHES. Both refusal cases follow a VALID three-group run;
    # if a refusal published nothing, that result would still be standing.
    for (r in c("refusal_missing_group_column", "refusal_missing_data_column")) {
        check_true(V, sprintf("%s published a refusal, not the run before it", r),
                   identical(get(r, "valid"), "0") &&
                   nzchar(get(r, "error")) &&
                   identical(get(r, "key"), ""))
        check_true(V, sprintf("%s left no group set behind", r),
                   identical(get(r, "nGroups"), "0"))
    }

    # THE STALE SLOT IS BLANKED.
    check_true(V, "a two-group result after a three-group one leaves no third label",
               identical(get("twogroup_after_threegroup", "label3_after"), ""))

    # THE KEY MOVES WITH THE DATA -- one cell, same n, same shape.
    check_true(V, "editing one cell moves the key",
               identical(get("edit_one_cell", "keysAgree"), "0"))
    check_true(V, "the two keys differ only in the digest (same r, c and n)",
               identical(sub("\\|d=.*$", "", get("edit_one_cell", "keyBefore")),
                         sub("\\|d=.*$", "", get("edit_one_cell", "keyAfter"))))

    # THE RULING'S SECTION (a) PINS, SEEN THROUGH THE STORE'S OWN PUBLISHED
    # KEY rather than through the fingerprint procedures directly. That is
    # the point of running them here as well as in the phase2 fingerprint
    # suite: what a figure will consult is emlStoreKey$, and a store that
    # stamped the key at the wrong moment would pass every fingerprint test
    # and fail these.
    #
    # THE REORDER LEG ASSERTS THE OPPOSITE OF THE RULING'S FIRST DRAFT, and
    # that is deliberate: Ian's 24 August amendment reads "any change to the
    # data including reordering of rows forces the mismatch error and redoing
    # of the stats." A green here on the old rationale would be the
    # regression the amendment exists to forbid.
    for (leg in c("edit_one_cell", "relabel_group_cell",
                  "swap_value_between_groups", "reorder_rows")) {
        check_true(V, sprintf("%s moves the stored key", leg),
                   identical(get(leg, "keysAgree"), "0"))
        check_true(V, sprintf("%s was measured against a key at all", leg),
                   nzchar(get(leg, "keyBefore")) && nzchar(get(leg, "keyAfter")))
    }

    # THE SETTINGS THE KEY CANNOT SEE, MEASURED. Same key, different result:
    # this is the whole reason a stored result carries an identity as well as
    # a key, and it is measured rather than argued.
    check_true(V, "holm and bonferroni share a key",
               identical(get("kw_dunn_holm", "key"), get("kw_dunn_bonferroni", "key")))
    check_true(V, "and move the adjusted p",
               !identical(get("kw_dunn_holm", "p12"), get("kw_dunn_bonferroni", "p12")))
    check_true(V, "and the store distinguishes them by identity, not by key",
               !identical(get("kw_dunn_holm", "correction"),
                          get("kw_dunn_bonferroni", "correction")))

    check_true(V, "ANOVA with and without Tukey share a key",
               identical(get("anova_tukey", "key"), get("anova_only", "key")))
    check_true(V, "and are different analyses by identity",
               !identical(get("anova_tukey", "testType"),
                          get("anova_only", "testType")))
    check_true(V, "the post-hoc that did not run publishes as undefined, never as 0",
               identical(get("anova_only", "p12"), "--undefined--"))

    # THE GROUP SORT ORDER: no dialog of its own, and it flips the sign and
    # the names of every comparison. Same key, both times.
    check_true(V, "the sort order does not move the key",
               identical(get("anova_tukey", "key"),
                         get("anova_tukey_alphabetical", "key")))
    check_true(V, "the sort order is published, and it moved",
               identical(get("anova_tukey", "groupSort"), "table") &&
               identical(get("anova_tukey_alphabetical", "groupSort"), "alphabetical"))
    check_true(V, "and it reordered the levels",
               !identical(get("anova_tukey", "label1"),
                          get("anova_tukey_alphabetical", "label1")))
    check_true(V, "and flipped the sign of the pairwise difference",
               sign(as.numeric(get("anova_tukey", "diff12"))) !=
               sign(as.numeric(get("anova_tukey_alphabetical", "diff12"))))

    # BOTH ARMS OF A "BOTH" RUN ARE PUBLISHED.
    check_true(V, "a both run publishes both arms",
               identical(get("twogroup_both", "omnibusLabel"), "t") &&
               identical(get("twogroup_both", "secondLabel"), "U"))
    check_true(V, "and a single-arm run after it states the second arm as absent",
               identical(get("twogroup_student", "secondLabel"), ""))

    # EVERY CASE THE PROBE DROVE IS READ BY SOMETHING ABOVE. The probe writes
    # the artefact and this file asserts on it; a case nobody reads is a case
    # rendered for nothing, which is the failure validate/coverage.R exists
    # for at the suite level.
    read_cases <- c("twogroup_both", "twogroup_student", "anova_tukey",
                    "anova_only", "kw_dunn_holm", "kw_dunn_bonferroni",
                    "kw_only", "pairwise_welch_holm", "pairwise_wilcoxon_bh",
                    "pairwise_scheffe", "anova_tukey_alphabetical",
                    "refusal_missing_group_column", "refusal_missing_data_column",
                    "twogroup_after_threegroup", "edit_one_cell",
                    "relabel_group_cell", "swap_value_between_groups",
                    "reorder_rows")
    unread <- setdiff(cases, read_cases)
    check_true(V,
               sprintf("every case the probe drove is named by this file%s",
                       if (length(unread))
                           paste0(" -- UNREAD: ", paste(unread, collapse = ", "))
                       else sprintf(" (%d)", length(cases))),
               length(unread) == 0)

    # The three cases named above but not individually asserted still have to
    # have published a result, or the list would be a way of claiming coverage
    # without giving any.
    for (c3 in c("kw_only", "pairwise_welch_holm", "pairwise_wilcoxon_bh")) {
        check_true(V, sprintf("%s published a valid result", c3),
                   identical(get(c3, "valid"), "1") &&
                   nzchar(get(c3, "testType")) && nzchar(get(c3, "key")))
    }
}

if (!exists("EML_SUITE")) { eml_report("v138 -- the result store's write site"); eml_exit() }
