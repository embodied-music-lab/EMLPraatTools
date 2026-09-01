# ---------------------------------------------------------------------------
# The cancellation-signature analysis (Fable, RULING_UNIQUENESS_SWEEP).
#
# For each retained host special function, compare Praat's value to R's and
# ask what the ABSOLUTE error does as p shrinks:
#   flat at ULP-of-1.0  -> upper tail computed as 1 - CDF; cancellation
#   shrinking with p    -> tail computed directly; function is clean
# ---------------------------------------------------------------------------
oracle <- function(fn, a1, a2, a3) switch(fn,
    gaussQ        = pnorm (a1, lower.tail = FALSE),
    studentQ      = pt    (a1, a2, lower.tail = FALSE),
    chiSquareQ    = pchisq(a1, a2, lower.tail = FALSE),
    fisherQ       = pf    (a1, a2, a3, lower.tail = FALSE),
    TukeyQ        = ptukey(a1, nmeans = a2, df = a3, lower.tail = FALSE),
    invGaussQ     = qnorm (a1, lower.tail = FALSE),
    invStudentQ   = qt    (a1, a2, lower.tail = FALSE),
    invChiSquareQ = qchisq(a1, a2, lower.tail = FALSE),
    invFisherQ    = qf    (a1, a2, a3, lower.tail = FALSE),
    invTukeyQ     = qtukey(a1, nmeans = a2, df = a3, lower.tail = FALSE),
    NA_real_)

report <- function(path, label) {
    d <- read.delim(path, colClasses = "character")
    for (nm in c("arg1","arg2","arg3","value")) d[[nm]] <- suppressWarnings(as.numeric(d[[nm]]))
    d$r <- mapply(oracle, d$fn, d$arg1, d$arg2, d$arg3)
    d$abs <- abs(d$value - d$r)
    d$rel <- ifelse(d$r != 0, d$abs / abs(d$r), NA)

    cat("\n############ ", label, " ############\n")
    for (fn in unique(d$fn)) {
        s <- d[d$fn == fn & is.finite(d$r) & is.finite(d$value), ]
        isInv <- grepl("^inv", fn)
        # the diagnostic band: where the result (or its p) is genuinely small
        small <- if (isInv) s[s$arg1 <= 1e-6, ] else s[s$r > 0 & s$r <= 1e-6, ]
        big   <- if (isInv) s[s$arg1 >= 1e-2, ] else s[s$r >= 1e-2, ]
        if (nrow(small) == 0) { cat(sprintf("  %-14s (no far-tail points)\n", fn)); next }

        # signature: does absolute error stay flat while the value shrinks?
        aBig <- median(big$abs, na.rm = TRUE); aSml <- median(small$abs, na.rm = TRUE)
        worstRel <- max(small$rel, na.rm = TRUE)
        verdict <- if (isInv) {
            if (worstRel < 1e-9) "CLEAN (quantile accurate in the far tail)" else "**RELATIVE ERROR IN FAR TAIL**"
        } else if (aSml > 1e-17 && aSml > aBig / 100) {
            "**CANCELLATION SIGNATURE -- absolute error flat**"
        } else "CLEAN (absolute error shrinks with p)"

        cat(sprintf("  %-14s abs.err mid=%8.2e far=%8.2e   worst rel (far)=%8.2e   %s\n",
                    fn, aBig, aSml, worstRel, verdict))
    }
    invisible(d)
}
a <- report("sweep_host_6.6.30.tsv", "Praat 6.6.30  (linux x64v3)")
b <- report("sweep_host_6.4.30.tsv", "Praat 6.4.30  (linux intel64)")

cat("\n############  CROSS-BUILD DISAGREEMENT  ############\n")
m <- merge(a[,c("fn","arg1","arg2","arg3","value")], b[,c("fn","arg1","arg2","arg3","value")],
           by = c("fn","arg1","arg2","arg3"), suffixes = c(".v3",".i64"))
m$rel <- ifelse(m$value.i64 != 0, abs(m$value.v3 - m$value.i64)/abs(m$value.i64), NA)
for (fn in unique(m$fn)) {
    s <- m[m$fn == fn & is.finite(m$rel), ]
    w <- max(s$rel, na.rm = TRUE)
    cat(sprintf("  %-14s worst cross-build relative difference = %8.2e   %s\n",
                fn, w, if (w > 1e-12) "**BUILDS DISAGREE IN LEADING DIGITS**" else "last-ULP only"))
}
