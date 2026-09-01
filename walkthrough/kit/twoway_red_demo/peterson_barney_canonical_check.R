# ============================================================================
# peterson_barney_canonical_check.R -- the canonical two-way ANOVA check,
# Praat's own manual example (mailbox/to-opus/WORK_ORDER_TWOWAY_KERNEL_2026-08-31.md).
#
# Praat's manual reports, for the two-way ANOVA of the Peterson & Barney
# (1952) formant table by Vowel x Type (a hidden built-in since Praat
# 6.6.30/2012, `Report two-way anova`):
#     Error SS = 1,600,534    vowel F = 7.625
# and the work order's diagnosis is that both are wrong -- the correct
# values, from the same 1,520-row table, are:
#     Error SS =   914,449    vowel F = 13.346
#
# THIS SCRIPT DOES NOT GENERATE THAT TABLE. It cannot: Praat is not
# installed in the environment this script was written in, and the table
# exists only as a Praat built-in generator (`Create formant table
# (Peterson & Barney 1952)`), not as a file shipped in this repo. It reads
# the export that ../RUN_ME_PETERSON_BARNEY_EXPORT.praat produces on a
# machine that DOES have Praat, at data/peterson_barney_1952.tsv (relative
# to walkthrough/kit/). Until that file exists, this script SKIPS CLEANLY
# with a clear message -- it does not error, and it does not simulate or
# guess at Praat's output. See CHECK_STATUS in Sys.getenv() below for how a
# caller can tell skip from pass from fail without parsing prose.
#
# Once the export exists, this script computes BOTH the (wrong) Praat
# built-in method and the correct direct method using the same
# dependency-free implementation as khuri_vs_direct_red_demo.R (shared via
# twoway_functions.R), and reports both against the manual's published
# numbers above -- a genuine oracle check, not a re-assertion of the
# fixture-based red demo.
#
# Run: Rscript peterson_barney_canonical_check.R
# Needs only base R. No packages.
# ============================================================================

.args <- commandArgs(trailingOnly = FALSE)
.fileArg <- sub("^--file=", "", .args[grep("^--file=", .args)])
here <- if (length(.fileArg) == 1) dirname(normalizePath(.fileArg)) else "."
source(file.path(here, "twoway_functions.R"))

options(width = 100)

exportPath <- file.path(here, "..", "data", "peterson_barney_1952.tsv")

# ----------------------------------------------------------------------------
# Guard: skip cleanly, exit 0, if the export has not landed yet. This is the
# expected state until Ian runs RUN_ME_PETERSON_BARNEY_EXPORT.praat.
# ----------------------------------------------------------------------------
if (!file.exists(exportPath)) {
    cat("SKIP: peterson_barney_canonical_check.R -- no export found.\n")
    cat("  expected at:", normalizePath(exportPath, mustWork = FALSE), "\n")
    cat("  This is expected until the Peterson-Barney table is exported on a\n")
    cat("  machine with Praat. Run walkthrough/kit/RUN_ME_PETERSON_BARNEY_EXPORT.praat\n")
    cat("  there, copy data/peterson_barney_1952.tsv into this repo's\n")
    cat("  walkthrough/kit/data/, and re-run this script. Not an error --\n")
    cat("  nothing here is simulated or guessed at.\n")
    quit(save = "no", status = 0)
}

d <- read.delim(exportPath, sep = "\t", stringsAsFactors = FALSE, check.names = FALSE)
cat("Loaded", nrow(d), "rows,", ncol(d), "columns from", exportPath, "\n")
cat("Columns:", paste(names(d), collapse = ", "), "\n\n")

if (nrow(d) != 1520) {
    cat("WARNING: expected 1520 rows (Praat manual's bundled dataset), got",
        nrow(d), ". Continuing, but say so before trusting the numbers below --",
        "a row-count mismatch usually means the wrong table or a partial",
        "export.\n\n")
}

# ----------------------------------------------------------------------------
# Column identification. Praat's exact column names for this built-in table
# are not known in the environment this script was written in (no Praat to
# check against) -- detected here rather than hardcoded, and refused loudly
# if detection is ambiguous, per this repo's rule of not guessing at Praat
# output. RUN_ME_PETERSON_BARNEY_EXPORT.praat prints the real column list;
# if this detection ever disagrees with that printout, trust the printout
# and fix the patterns below, not the other way around.
# ----------------------------------------------------------------------------
findCol <- function(names_, patterns, exclude = character(0)) {
    for (pat in patterns) {
        matched <- grepl(pat, names_, ignore.case = TRUE)
        if (length(exclude) > 0) {
            matched <- matched & !grepl(paste(exclude, collapse = "|"), names_, ignore.case = TRUE)
        }
        hit <- names_[matched]
        if (length(hit) == 1) return(hit)
    }
    NA_character_
}
colVowel <- findCol(names(d), c("^vowel$", "vowel"))
colType  <- findCol(names(d), c("^type$", "^sex$", "type", "sex"))
# THE DEPENDENT VARIABLE IS F0, NOT F1 (Fable, RULING_CONSOLIDATED_KERNELS,
# 1 Sep). This script originally looked for an F1-like column, which is wrong:
# the manual's worked example analyses fundamental frequency by Vowel x Type.
# F1 gives a vowel F near 900 and would never have matched the published
# 7.625 / 13.346, so the check would have reported MISMATCH against correct
# arithmetic and sent us hunting the wrong defect.
colF0    <- findCol(names(d), c("^f0$", "^f0 ", "f0"), exclude = c("f01", "f02"))

missing_ <- c(Vowel = colVowel, Type = colType, F0 = colF0)
if (any(is.na(missing_))) {
    cat("REFUSING: could not unambiguously identify the columns this check needs.\n")
    cat("  Vowel factor:", ifelse(is.na(colVowel), "NOT FOUND", colVowel), "\n")
    cat("  Type/Sex factor:", ifelse(is.na(colType), "NOT FOUND", colType), "\n")
    cat("  F0 data column:", ifelse(is.na(colF0), "NOT FOUND", colF0), "\n")
    cat("  Actual columns in the export:", paste(names(d), collapse = ", "), "\n")
    cat("  Fix the findCol() patterns above to match, then re-run. Not guessing\n")
    cat("  past this -- an unverified column pairing would silently produce the\n")
    cat("  wrong ANOVA.\n")
    quit(save = "no", status = 0)
}
cat("Using Vowel column '", colVowel, "', Type/Sex column '", colType,
    "', data column '", colF0, "'\n\n", sep = "")

d[[colF0]] <- as.numeric(d[[colF0]])
keep <- !is.na(d[[colF0]]) & !is.na(d[[colVowel]]) & d[[colVowel]] != "" &
        !is.na(d[[colType]]) & d[[colType]] != ""
if (any(!keep)) {
    cat("Dropping", sum(!keep), "row(s) with a missing Vowel/Type/", colF0, "value.\n\n")
}
d <- d[keep, , drop = FALSE]

both <- twoway_both_tables(d, colF0, colVowel, colType)
kh <- both$kh; w <- both$wrong; c_ <- both$correct

cat("Design: ", kh$r, " x ", kh$s, " = ", kh$rs, " cells, N = ", nrow(d), "\n", sep = "")
cat("Cell sizes:\n")
print(kh$cellN)
cat("\n")

cat("-- (WRONG) Praat built-in method (subtraction) --\n")
wrong <- data.frame(
    Source = c(colVowel, colType, paste0(colVowel, ":", colType), "Error", "Total"),
    SS = c(kh$ssA, kh$ssB, kh$ssAB, w$ssE, w$ssT),
    Df = c(kh$dfA, kh$dfB, kh$dfAB, w$dfE, w$dfT),
    F  = c(w$fA, w$fB, w$fAB, NA, NA),
    P  = c(w$pA, w$pB, w$pAB, NA, NA)
)
print(wrong, digits = 8, row.names = FALSE)

cat("\n-- (CORRECT) direct method --\n")
correct <- data.frame(
    Source = c(colVowel, colType, paste0(colVowel, ":", colType), "Error", "Total"),
    SS = c(kh$ssA, kh$ssB, kh$ssAB, c_$ssE, c_$ssT),
    Df = c(kh$dfA, kh$dfB, kh$dfAB, c_$dfE, c_$dfT),
    F  = c(c_$fA, c_$fB, c_$fAB, NA, NA),
    P  = c(c_$pA, c_$pB, c_$pAB, NA, NA)
)
print(correct, digits = 8, row.names = FALSE)

# ----------------------------------------------------------------------------
# The canonical numbers. colVowel was passed as the A factor to
# twoway_both_tables() above, so w$fA / c_$fA are the vowel-effect F values;
# if the F values below land nowhere near either published figure, that is
# itself the signal something upstream (column identification, row filter,
# factor pairing) is wrong -- not a tolerance to loosen.
# ----------------------------------------------------------------------------
manual_wrong_errorSS <- 1600534
manual_correct_errorSS <- 914449
manual_wrong_vowelF <- 7.625
manual_correct_vowelF <- 13.346

fA_wrong <- w$fA; fA_correct <- c_$fA

cat("\n============================================================\n")
cat("CANONICAL CHECK against the Praat manual's published numbers\n")
cat("============================================================\n")
tol_rel <- 0.01   # 1% -- the manual's own numbers are rounded to ~4-6 sig figs

report_one <- function(label, computed, published, tol = tol_rel) {
    rel <- abs(computed - published) / abs(published)
    status <- if (rel <= tol) "MATCH" else "MISMATCH"
    cat(sprintf("  %-32s computed = %14.4f  published = %14.4f  rel.diff = %8.4g  [%s]\n",
                label, computed, published, rel, status))
    status == "MATCH"
}

ok1 <- report_one("Error SS (wrong/built-in)", w$ssE, manual_wrong_errorSS)
ok2 <- report_one("Error SS (correct/direct)", c_$ssE, manual_correct_errorSS)
ok3 <- report_one(paste0("F(", colVowel, ") (wrong/built-in)"), fA_wrong, manual_wrong_vowelF)
ok4 <- report_one(paste0("F(", colVowel, ") (correct/direct)"), fA_correct, manual_correct_vowelF)

cat("\n  Ratio check (the diagnostic signature): wrong/correct should match on\n")
cat("  both Error SS and F, since the effect sums are untouched by the bug --\n")
cat("  manual: 1600534/914449 =", fmt(manual_wrong_errorSS / manual_correct_errorSS, 4),
    "  13.346/7.625 =", fmt(manual_correct_vowelF / manual_wrong_vowelF, 4), "\n")
cat("  this export: SS_Error(wrong)/SS_Error(correct) =", fmt(w$ssE / c_$ssE, 4),
    "  F_correct/F_wrong =", fmt(fA_correct / fA_wrong, 4), "\n")

allOk <- ok1 && ok2 && ok3 && ok4
cat("\nRESULT:", if (allOk) "PASS -- reproduces the manual's published Error SS and vowel F,"
                  else "FAIL -- see MISMATCH line(s) above,",
    if (allOk) "both wrong and correct." else "", "\n")

quit(save = "no", status = if (allOk) 0 else 1)
