# ============================================================================
# v37_determinism.R -- the same data draws the same picture twice, checked here
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS FILE EXISTS. harness/determinism/run.sh renders each of the ten
# Table-consuming draw procedures TWICE, in two separate Praat processes, from
# one seeded fixture, and compares the two PNGs. Until 12 August 2026 it was
# the only harness in the tree that no R script read: it printed STABLE or
# VARIES to stdout, exited non-zero on failure, and that was the whole of the
# evidence. The "10/10 byte-identical" line quoted in the audit's baseline was
# the harness reporting on itself. See §18 of
# audit/GRAPHING_PUSH_REMAINING.md.
#
# THAT IS NOT A COSMETIC GAP, because of what determinism is used for. It is
# what licenses reading a diff of two renders as a regression. Every
# byte-for-byte claim made elsewhere in this audit -- §2's "pixel-neutral",
# §2b's and §2c's "10/10 determinism byte-identical" -- rests on the premise
# that a draw procedure given the same data produces the same bytes. If that
# premise is the one result nobody independently checks, everything downstream
# inherits the weakness.
#
# SO THE LOAD-BEARING CHECK IN THIS FILE IS THE ONE THAT IGNORES THE DRIVER.
# Section 3 opens both PNGs off disk and compares them raw byte by raw byte in
# R, and then asserts that the driver's own verdict agrees with what R found.
# A file that only read the verdict column would be the harness grading its
# own homework a second time, which is the defect §18 describes rather than a
# fix for it. Both halves are asserted, because either one alone can pass on a
# broken pair: the verdict alone believes the driver, and the comparison alone
# would not notice a driver that had stopped comparing anything.
#
#     bash harness/determinism/run.sh      regenerate the input
#     Rscript validate/v37_determinism.R
#
# Input: <det>/DETERMINISM.tsv, five fields, no header:
#            name  verdict  bytesA  bytesB  diffPx
#        and, beside it, the files the row describes:
#            <det>/<name>_a.png  <det>/<name>_b.png
#            <det>/<name>_a.log  <det>/<name>_b.log
#        <det> is $EML_DETERMINISM_DIR, default harness/determinism/out. The
#        override exists so a break test can plant a defect in a COPY of the
#        directory rather than in the committed evidence.
#
# A missing artefact is a HARD STOP, not a skip, for v27's and v35's reason:
# "the driver never ran this" is exactly the failure a silently shrinking
# suite would hide, and a skip here would restore the §18 state -- no
# independent check -- while the suite still went green.
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

det_dir <- Sys.getenv("EML_DETERMINISM_DIR", unset = "")
if (!nzchar(det_dir)) det_dir <- repo_path("harness", "determinism", "out")
det_p <- file.path(det_dir, "DETERMINISM.tsv")

if (!file.exists(det_p)) {
    stop("determinism artefact not found: ", det_p,
         "\n  Run: bash harness/determinism/run.sh")
}

# Every field is read as TEXT, and na.strings is emptied, because "NA" is a
# VALUE this artefact writes -- the driver puts it in bytesA/bytesB when a pass
# produced no file and in diffPx when ImageMagick is not installed. Letting R
# coerce the columns would turn a literal "NA" into a missing value and make
# "the file is absent" indistinguishable from "the driver did not say".
dt <- read.delim(det_p, header = FALSE, stringsAsFactors = FALSE,
                 colClasses = "character", na.strings = character(0),
                 col.names = c("name", "verdict", "bytesA", "bytesB", "diffPx"))

# ---------------------------------------------------------------------------
# 1. The artefact is the shape this script expects
# ---------------------------------------------------------------------------
# Asserted before anything is read out of it, because every check below reads
# a column by name and would otherwise fail for the wrong reason -- a driver
# that grew a column would look like a determinism failure.
check_true("v37", "determinism artefact has rows", nrow(dt) > 0L)
check_true("v37", "determinism artefact has the five expected fields",
           identical(names(dt),
                     c("name", "verdict", "bytesA", "bytesB", "diffPx")))

# ---------------------------------------------------------------------------
# 1b. THE POPULATION IS DECLARED, NOT WHATEVER TURNED UP
# ---------------------------------------------------------------------------
# Section 3 loops over every row the artefact contains, so no rendered type
# can be ignored. The failure that leaves is the opposite one: a type dropped
# from harness/determinism/run.sh renders nothing, the loop runs over nine
# rows, and every check still passes while the suite says "determinism holds".
#
# So the ten Table-consuming draw procedures are named. They are the ten the
# driver's NAMES array holds and the ten @emlDraw* procedures that take a
# Table; a type added or removed has to be dealt with here on purpose.
DET_TYPES <- c("ts", "tsci", "spaghetti", "bar", "violin",
               "box", "gviolin", "gbox", "scatter", "histogram")
eml_census("v37", "draw procedure", dt$name, DET_TYPES)
check("v37", "all ten Table-consuming draw procedures were rendered",
      reported = nrow(dt), computed = length(DET_TYPES), tol = 0)
check_true("v37", "each type appears exactly once", !any(duplicated(dt$name)))

# ---------------------------------------------------------------------------
# 2. The comparison this file performs itself
# ---------------------------------------------------------------------------
# Read as raw bytes, not as an image: the claim being checked is that the two
# processes wrote the SAME FILE, which is stricter than "the same picture" and
# is the claim every downstream byte-for-byte statement depends on.
same_bytes <- function(fa, fb) {
    if (!file.exists(fa) || !file.exists(fb)) return(FALSE)
    na <- file.size(fa); nb <- file.size(fb)
    if (is.na(na) || is.na(nb) || na == 0 || nb == 0) return(FALSE)
    identical(readBin(fa, "raw", na), readBin(fb, "raw", nb))
}

# A Praat error in a transcript, by the same three phrases the drivers in this
# tree match on. A run that errored and still wrote a PNG -- the
# DREW_THEN_FAILED shape harness/legend/run.sh names -- is not a stable render,
# it is two identical failures.
PRAAT_ERROR <- "^Error|not completed|Unknown variable"
log_clean <- function(f) {
    if (!file.exists(f)) return(FALSE)
    !any(grepl(PRAAT_ERROR, readLines(f, warn = FALSE)))
}

# ---------------------------------------------------------------------------
# 3. Every type, one row at a time
# ---------------------------------------------------------------------------
for (i in seq_len(nrow(dt))) {
    r  <- dt[i, ]
    nm <- r$name
    fa <- file.path(det_dir, paste0(nm, "_a.png"))
    fb <- file.path(det_dir, paste0(nm, "_b.png"))
    la <- file.path(det_dir, paste0(nm, "_a.log"))
    lb <- file.path(det_dir, paste0(nm, "_b.log"))

    # -- both passes produced a figure at all. NO_FIGURE is a real outcome of
    #    this harness: §15 was found by it, a grouped histogram that aborted
    #    for every caller but the form.
    sa <- if (file.exists(fa)) file.size(fa) else NA_real_
    sb <- if (file.exists(fb)) file.size(fb) else NA_real_
    check_true("v37", sprintf("%s -- pass A wrote a non-empty PNG", nm),
               !is.na(sa) && sa > 0)
    check_true("v37", sprintf("%s -- pass B wrote a non-empty PNG", nm),
               !is.na(sb) && sb > 0)
    check("v37", sprintf("%s -- the two passes are the same size on disk", nm),
          reported = if (is.na(sa)) -1 else sa,
          computed = if (is.na(sb)) -2 else sb, tol = 0)

    # -- the sizes the driver recorded are the sizes on disk. The driver's
    #    numbers are checked against the files rather than taken as read, for
    #    the same reason its verdict is below.
    check_true("v37", sprintf("%s -- recorded byte counts match the files", nm),
               !is.na(sa) && !is.na(sb) &&
               identical(r$bytesA, format(sa, scientific = FALSE, trim = TRUE)) &&
               identical(r$bytesB, format(sb, scientific = FALSE, trim = TRUE)))

    # -- neither process errored on its way to that figure
    check_true("v37", sprintf("%s -- pass A's log is free of Praat errors", nm),
               log_clean(la))
    check_true("v37", sprintf("%s -- pass B's log is free of Praat errors", nm),
               log_clean(lb))

    # -- THE ONE THAT MATTERS. Compared here, from the files, with the driver's
    #    verdict column not consulted.
    identical_here <- same_bytes(fa, fb)
    check_true("v37",
               sprintf("%s -- the two PNGs are byte-identical, compared here", nm),
               identical_here)

    # -- and the driver said the same thing. This is the cross-check, not the
    #    evidence: a driver whose verdict disagrees with the files beside it is
    #    broken, and every other harness in this tree would then be suspect too.
    check_true("v37", sprintf("%s -- driver verdict is STABLE", nm),
               identical(r$verdict, "STABLE"))
    check_true("v37",
               sprintf("%s -- driver verdict agrees with this file's own comparison", nm),
               identical(r$verdict == "STABLE", identical_here))

    # -- an identical pair has no differing pixels. 0 means measured and equal;
    #    NA would mean ImageMagick was absent, which cannot be the case on a
    #    pair the driver called STABLE because it never measures one.
    check_true("v37", sprintf("%s -- differing-pixel count recorded as 0", nm),
               !identical_here || identical(r$diffPx, "0"))
}

# ---------------------------------------------------------------------------
# 4. The suite-level statement
# ---------------------------------------------------------------------------
# The per-type checks above each speak for one type. This is the sentence the
# audit quotes, asserted once, over the whole population, from this file's own
# comparisons rather than from the driver's verdict column.
own <- vapply(dt$name, function(nm)
    same_bytes(file.path(det_dir, paste0(nm, "_a.png")),
               file.path(det_dir, paste0(nm, "_b.png"))), logical(1))
check("v37", "types that do NOT render identically twice",
      reported = 0, computed = sum(!own), tol = 0)
check_true("v37", "every type the driver called STABLE really is",
           all(dt$verdict == "STABLE") && all(own))

if (!exists("EML_SUITE")) {
    eml_report("v37 determinism: the same data draws the same picture twice")
    eml_exit()
}
