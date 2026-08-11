# ============================================================================
# v34_label_escape.R -- escaping a label twice must not destroy the character
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# THE DEFECT THIS PINS. @emlSanitizeLabel escapes Praat's text-rendering
# specials (%, #, ^) so a column name displays literally instead of toggling
# italic. Until 11 August 2026 it was not idempotent, and applying it to an
# already-escaped string destroyed the character it was protecting:
#
#     Jitter (\% )     escaped once   ->  renders  Jitter (%)     correct
#     Jitter (\\%  )   escaped twice  ->  renders  Jitter (  )    gone
#
# The middle line is what the AUTO-COMPOSED TITLE of every figure looked like.
# @emlComposeGraphTitle sanitises each part it assembles -- the value column
# via @emlCapitalizeLabel, which already returns "Jitter (\% )" -- and
# @emlDrawAxes then sanitises the finished title again. The y-axis label on
# the same figure was correct, because @emlDrawAxes deliberately does NOT
# re-sanitise axis labels. Its comment says titles are "passed raw"; that was
# true when it was written, and @emlComposeGraphTitle made it false.
#
# HOW IT WAS FOUND, which is the part worth keeping: by installing the plugin
# under Xvfb, clicking New -> +EML Tools -> EML Graphs, and READING THE TITLE
# on the figure that came out. Every intermediate string was correct. Only the
# rendered pixels were wrong, and nothing in this repository had ever looked
# at a figure the plugin's own menu produced.
#
#     bash harness/disclosure/run.sh      regenerate the input
#     Rscript validate/v34_label_escape.R
#
# Input: <disc>/labelescape.log, written by
#        harness/disclosure/probe_label_escape.praat. A missing artefact is a
#        HARD STOP, not a skip -- "the driver never ran this" is exactly the
#        failure a silently shrinking suite would hide.
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

disc_dir <- Sys.getenv("EML_DISCLOSURE_DIR", unset = "")
if (!nzchar(disc_dir)) disc_dir <- repo_path("harness", "disclosure", "out")
le_p <- file.path(disc_dir, "labelescape.log")

if (!file.exists(le_p)) {
    stop("label-escape artefact not found: ", le_p,
         "\n  Run: bash harness/disclosure/run.sh")
}
le <- readLines(le_p, warn = FALSE)

check_true("v34", "label-escape probe ran", length(le) > 0L)
check_true("v34", "label-escape probe: no Praat error",
           !any(grepl("^Error|not completed|Unknown variable", le)))

# ---------------------------------------------------------------------------
# 1. The escaper is a fixed point after one application
# ---------------------------------------------------------------------------
# Applied once, twice and three times must give the same string. THREE, not
# two: a two-application check passes on an escaper that alternates between
# two states, and alternating is a plausible way to get this wrong.
esc <- grep("^LABELESC ", le, value = TRUE)
cases <- sub("^LABELESC ([^ ]+) .*$", "\\1", esc)
verdict <- sub("^LABELESC [^ ]+ (.*)$", "\\1", esc)

# The seven shapes the probe covers. Named here so that a probe which quietly
# stopped testing one has to be dealt with on purpose.
expected <- c("rawcol", "percent", "preescaped", "hash", "caret",
              "allthree", "plain")
check_true("v34", "all seven label shapes were exercised",
           setequal(cases, expected))
for (i in seq_along(esc)) {
    check_true("v34", sprintf("escaping %s is stable under repetition", cases[i]),
               identical(verdict[i], "stable"))
}

# ---------------------------------------------------------------------------
# 2. The composition that actually broke
# ---------------------------------------------------------------------------
# @emlCapitalizeLabel already returns an escaped string, and a title travels
# capitalize -> compose -> sanitise-at-draw. So capitalize's output must be a
# FIXED POINT of sanitise. This is the specific pair that failed; §1 would
# pass on an escaper that was idempotent but disagreed with the capitaliser.
fix <- grep("^LABELFIX ", le, value = TRUE)
check_true("v34", "the capitalize-then-sanitize check ran", length(fix) == 1L)
if (length(fix) == 1L) {
    check_true("v34",
               "@emlCapitalizeLabel output is a fixed point of @emlSanitizeLabel",
               grepl(" fixedpoint$", fix))
}

# ---------------------------------------------------------------------------
# 3. A figure was actually drawn with such a title
# ---------------------------------------------------------------------------
# The string checks above would all have passed on a build where the RENDERER
# swallowed the character -- that is precisely what happened, for however long
# it happened. So the probe draws a real figure with an already-escaped title
# and this asserts the file exists and carries ink.
ink <- grep("^LABELINK ", le, value = TRUE)
check_true("v34", "the title figure was drawn", length(ink) == 1L)
png_p <- file.path(disc_dir, "label_escape.png")
check_true("v34", "the title figure exists on disk", file.exists(png_p))
if (file.exists(png_p)) {
    # A blank 300-dpi PNG of this size is a few kB; a drawn one is tens.
    check_true("v34", "the title figure is not an empty frame",
               file.info(png_p)$size > 15000)
}

if (!exists("EML_SUITE")) {
    eml_report("v34 label escape: escaping twice must not destroy the character")
    eml_exit()
}
