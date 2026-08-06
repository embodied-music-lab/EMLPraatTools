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

# "Data            Starts Line 61" -- the header states where the data begins,
# so the parser never counts header lines itself.
start <- as.integer(sub(".*Starts Line\\s+(\\d+).*", "\\1",
                        grep("Starts Line", L, value = TRUE)[1]))
if (is.na(start)) stop("could not find the 'Starts Line' header in ", dat_file)

body <- L[start:length(L)]
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
cv_start <- grep("^Certified Values", L)[1]
cv_end   <- grep("^Data\\b|^Number of Observations", L)
cv_end   <- cv_end[cv_end > cv_start][1]
if (is.na(cv_start)) stop("no Certified Values block in ", dat_file)
block <- L[cv_start:min(cv_end - 1L, length(L))]

rows <- list()
for (ln in block) {
  m <- regmatches(ln, regexpr("^\\s*([A-Za-z0-9_ ()-]+?)\\s{2,}", ln))
  nums <- suppressWarnings(as.numeric(
            regmatches(ln, gregexpr("[-+]?[0-9]*\\.?[0-9]+([Ee][-+]?[0-9]+)?", ln))[[1]]))
  if (!length(m) || !length(nums)) next
  lab <- trimws(m)
  for (j in seq_along(nums))
    rows[[length(rows) + 1L]] <- data.frame(label = lab, field = j,
                                            certified = nums[j],
                                            stringsAsFactors = FALSE)
}
cert <- do.call(rbind, rows)

out <- file.path("evidence", "nist"); dir.create(out, recursive = TRUE, showWarnings = FALSE)
write.csv(d,    file.path(out, paste0(name, "_data.csv")),      row.names = FALSE)
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
