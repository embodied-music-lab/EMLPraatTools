# RED DEMO -- task 6, reader-sentence membership check.
# Seeds one working-paper reason into a COPY of a real results/ file (never
# touches the live results/ directory) and asserts the membership check
# catches it. Run standalone: Rscript red_demo_membership.R

kitDir <- "/home/claude/repo/walkthrough/kit"
tmp <- tempfile("membership_demo_"); dir.create(tmp)

# Reuse the same parser and set-membership logic compare.R uses.
.parseReaderSentences <- function(path) {
    lines <- readLines(path, warn = FALSE)
    out <- list(); cur <- NULL; buf <- character(0)
    flush <- function() {
        if (!is.null(cur)) {
            body <- trimws(paste(buf, collapse = " "))
            body <- sub("^Rows:\\s*~?[0-9,]+\\.\\s*", "", body)
            out[[cur]] <<- body
        }
    }
    for (ln in lines) {
        if (grepl("^## ", ln)) { flush(); cur <- trimws(sub("^## ", "", ln)); buf <- character(0) }
        else if (!is.null(cur) && !grepl("^---\\s*$", ln)) buf <- c(buf, ln)
    }
    flush(); out
}
READER <- .parseReaderSentences(file.path(kitDir, "results_templates", "reader_sentences.md"))
readerSentenceSet <- unique(unname(unlist(READER)))

extractReasonStrings <- function(path) {
    d <- utils::read.delim(path, sep = "\t", colClasses = "character",
                            quote = "", na.strings = NULL, check.names = FALSE)
    if (!"reason" %in% names(d)) return(character(0))
    unique(d$reason[nzchar(d$reason)])
}
checkReasonMembership <- function(files) {
    bad <- list()
    for (f in files) for (r in extractReasonStrings(f))
        if (!(r %in% readerSentenceSet)) bad[[length(bad) + 1]] <- list(file = basename(f), reason = r)
    bad
}

# Copy a real exceptions.tsv, then seed one row with working-paper voice --
# the raw DECLARED `why` text, never meant to reach a results/ file.
realExc <- file.path(kitDir, "results", "exceptions.tsv")
stopifnot(file.exists(realExc))
seeded <- file.path(tmp, "exceptions.tsv")
file.copy(realExc, seeded)
badReason <- "TIER 2 OF THE ptukey QUADRATURE FAMILY, ruled 27 August 2026. Same defect as D-PTUKEY, milder: R's ptukey diverges from the plugin's own quadrature below p ~ 1e-5."
cat(sprintf("c9999\tposthoc_test_padj\t0.1\t0.1000001\t1.00e-06\t%s\n", badReason),
    file = seeded, append = TRUE)

bad <- checkReasonMembership(seeded)
cat(sprintf("RED DEMO (membership): seeded 1 working-paper reason into a copy of exceptions.tsv.\n"))
cat(sprintf("Check found %d non-member reason string(s).\n", length(bad)))
if (length(bad) >= 1 && any(vapply(bad, function(b) b$reason, "") == badReason)) {
    cat("RESULT: CAUGHT -- the check correctly flagged the seeded working-paper reason as red.\n")
} else {
    cat("RESULT: NOT CAUGHT -- demo failed to reproduce the intended red condition.\n")
    quit(status = 1)
}
unlink(tmp, recursive = TRUE)
