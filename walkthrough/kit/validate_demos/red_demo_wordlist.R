# RED DEMO -- task 7, wordlist (second net) check.
# Seeds a clause id into a COPY of a prose document (never touches the live
# results/ or README.md) and asserts the wordlist check catches it.
# Run standalone: Rscript red_demo_wordlist.R

kitDir <- "/home/claude/repo/walkthrough/kit"
tmp <- tempfile("wordlist_demo_"); dir.create(tmp)

WORDLIST_LITERALS <- c("bucket", "enforcement", "DECLARED", "CONTRACT",
                        "vmax", "vmin", "maxrel", "quantities.tsv")
WORDLIST_PATTERNS <- c("@eml\\w+", "D-[A-Z]")
checkWordlist <- function(path) {
    lines <- readLines(path, warn = FALSE)
    hits <- character(0)
    for (w in WORDLIST_LITERALS) {
        m <- which(grepl(w, lines, fixed = TRUE))
        if (length(m)) hits <- c(hits, sprintf("%s: literal \"%s\" on line %d", basename(path), w, m[1]))
    }
    for (p in WORDLIST_PATTERNS) {
        m <- which(grepl(p, lines, perl = TRUE))
        if (length(m)) hits <- c(hits, sprintf("%s: pattern /%s/ on line %d", basename(path), p, m[1]))
    }
    hits
}

# A clean SUMMARY.md-style paragraph, then one seeded clause id (D-PTUKEY)
# of the kind that must never leak into reader-facing prose.
seeded <- file.path(tmp, "SUMMARY.md")
writeLines(c(
    "# Validation summary",
    "",
    "10792 of 10841 values agree to at least nine significant digits.",
    "",
    "The p-value quadrature difference is bounded under D-PTUKEY at 0.5%."
), seeded)

hits <- checkWordlist(seeded)
cat(sprintf("RED DEMO (wordlist): seeded clause id 'D-PTUKEY' into a copy of a SUMMARY.md-style file.\n"))
cat(sprintf("Check found %d hit(s): %s\n", length(hits), paste(hits, collapse = "; ")))
if (length(hits) >= 1 && any(grepl("D-[A-Z]", hits, fixed = TRUE))) {
    cat("RESULT: CAUGHT -- the check correctly flagged the seeded clause id as red.\n")
} else {
    cat("RESULT: NOT CAUGHT -- demo failed to reproduce the intended red condition.\n")
    quit(status = 1)
}
unlink(tmp, recursive = TRUE)
