# ============================================================================
# nist_ingest.R -- convert a NIST StRD .dat file into (data, certified) CSVs.
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# The certified values are NEVER transcribed by hand. They are parsed out of
# the file NIST publishes, so the only thing this repository asserts about
# them is the SHA-256 of the file they came from. That is the whole reason
# Tier C is worth having: every other check in validate/ is ultimately "R
# agrees with the plugin", and R is a peer, not a referee.
#
#     Rscript validate/tools/nist_ingest.R path/to/Norris.dat lls
#     Rscript validate/tools/nist_ingest.R path/to/SiRstv.dat anova
#
# Writes evidence/nist/<Name>_data.csv, <Name>_certified.csv, and appends the
# file's SHA-256 to evidence/nist/SOURCES.txt.
#
# Get the files (they are not redistributed here):
#     curl -O https://www.itl.nist.gov/div898/strd/lls/data/LINKS/DATA/Norris.dat
#     curl -O https://www.itl.nist.gov/div898/strd/anova/SiRstv.dat
# ============================================================================

args <- commandArgs(TRUE)
if (length(args) < 2L)
  stop("usage: nist_ingest.R <file.dat> <lls|anova>")
dat_file <- args[1]; kind <- args[2]

L <- readLines(dat_file, warn = FALSE)
name <- sub("^Dataset Name:\\s*", "", grep("^Dataset Name:", L, value = TRUE)[1])
name <- trimws(sub("\\(.*", "", name))

# The header states where each block lives, so the parser never counts header
# lines itself. NIST writes this two ways -- "Data (lines 61 to 85)" in the
# ANOVA sets and "Data   Starts Line 61" in some others -- so both are read,
# and a file matching neither is an error rather than a guess.
.span <- function(what) {
  ln <- grep(paste0("^\\s*", what, "\\s"), L, value = TRUE)
  ln <- grep("lines|Starts Line", ln, value = TRUE)
  if (!length(ln)) return(c(NA_integer_, NA_integer_))
  m <- regmatches(ln[1], gregexpr("[0-9]+", ln[1]))[[1]]
  if (grepl("Starts Line", ln[1])) c(as.integer(tail(m, 1)), length(L))
  else if (length(m) >= 2L) as.integer(m[1:2])
  else c(NA_integer_, NA_integer_)
}
dspan <- .span("Data")
if (is.na(dspan[1]))
  stop("could not locate the data block header in ", dat_file)

body <- L[dspan[1]:min(dspan[2], length(L))]
body <- body[nzchar(trimws(body))]
num  <- lapply(strsplit(trimws(body), "[[:space:]]+"), as.numeric)
ncol <- length(num[[1]])
if (any(lengths(num) != ncol))
  stop("ragged data block in ", dat_file)
d <- as.data.frame(do.call(rbind, num))

# NIST orders LLS data as (y, x1, ...) and ANOVA data as (group, y).
names(d) <- if (kind == "lls") {
  c("y", paste0("x", seq_len(ncol - 1L)))
} else {
  c("grp", "value")
}

# --- certified values ------------------------------------------------------
# Every "label   number ..." line inside the Certified Values block, keyed by
# its label. Parameter lines are "B0   <estimate>   <sd>"; the ANOVA table
# lines are "Regression  <df>  <ss>  <ms>  <F>". Both are captured as a
# label plus its numeric fields, and the scorer picks what it needs.
cspan <- .span("Certified Values")
if (is.na(cspan[1])) {
  cv_start <- grep("^Certified Values", L)[1]
  if (is.na(cv_start)) stop("no Certified Values block in ", dat_file)
  cspan <- c(cv_start, dspan[1] - 1L)
}
block <- L[cspan[1]:min(cspan[2], length(L))]

# Label = the leading run of tokens that are not numbers. This survives both
# "Between Instrument  4  5.11E-02 ..." and the LLS parameter rows "B0
# -0.2623 0.2328", where a naive "text before the first digit" rule would cut
# B0 in half. A line with no numeric token at all is a table header and is
# skipped; NIST's own units and blank lines fall out the same way.
rows <- list()
for (ln in block) {
  tok <- strsplit(trimws(ln), "[[:space:]]+")[[1]]
  tok <- tok[nzchar(tok)]
  if (!length(tok)) next
  isnum <- !is.na(suppressWarnings(as.numeric(tok)))
  first <- which(isnum)[1]
  if (is.na(first)) next
  lab  <- if (first == 1L) "" else paste(tok[seq_len(first - 1L)], collapse = " ")
  nums <- as.numeric(tok[first:length(tok)][isnum[first:length(tok)]])
  if (!nzchar(lab)) next
  for (j in seq_along(nums))
    rows[[length(rows) + 1L]] <- data.frame(label = lab, field = j,
                                            certified = nums[j],
                                            stringsAsFactors = FALSE)
}
cert <- do.call(rbind, rows)

out <- file.path("evidence", "nist"); dir.create(out, recursive = TRUE, showWarnings = FALSE)
# quote = FALSE is load-bearing, not cosmetic. Praat's CSV reader does NOT
# strip quotes from header cells: a file whose first line reads "grp","value"
# gives columns literally named `"value"`, and every lookup then fails with
# "Data column not found: value". Writing bare headers is the fix.
write.csv(d, file.path(out, paste0(name, "_data.csv")),
          row.names = FALSE, quote = FALSE)
# 17 significant digits, not write.csv's default 15: NIST publishes 15, and
# rounding the certified value before scoring would cap every LRE at 15 and
# make a genuinely exact routine look inexact.
cert$certified <- vapply(cert$certified, function(v) sprintf("%.17g", v), "")
write.csv(cert, file.path(out, paste0(name, "_certified.csv")),
          row.names = FALSE, quote = c(1L))

sha <- tryCatch(tools::md5sum(dat_file), error = function(e) NA)
cat(sprintf("%s  md5=%s  n=%d  cols=%d  certified_fields=%d\n",
            basename(dat_file), sha, nrow(d), ncol(d), nrow(cert)),
    file = file.path(out, "SOURCES.txt"), append = TRUE)

cat(sprintf("%s: %d rows, %d certified fields -> %s\n",
            name, nrow(d), nrow(cert), out))
