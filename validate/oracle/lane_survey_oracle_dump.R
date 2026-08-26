# ===========================================================================
# lane_survey_oracle_dump.R — committed oracle record for the survey-stats
# lane (Cronbach's alpha, chi-square + Cramér's V, Wilson intervals)
# ===========================================================================
# Recomputes every oracle value the lane's validators (v90, v91, v92)
# settle the kernels against, from the committed fixtures in
# evidence/csv/, and writes lane_survey_oracle_values.csv next to this
# script. The values come from the actual oracle calls — psych::alpha,
# chisq.test, prop.test(correct = FALSE) — not from a transcription of
# their formulas ("a transcription can silently correct the thing it
# copies"). Run:
#     Rscript lane_survey_oracle_dump.R
# Requires the psych package (r-cran-psych).
# ===========================================================================

here <- (function() {
    a <- commandArgs(FALSE)
    f <- sub("^--file=", "", a[grep("^--file=", a)])
    if (length(f)) dirname(normalizePath(f)) else "."
})()
csvdir <- normalizePath(file.path(here, "..", "..", "evidence", "csv"))

rows <- list()
put <- function(stat, value, tol) {
    rows[[length(rows) + 1L]] <<- data.frame(stat = stat, value = value,
                                             tol = tol)
}

# ---------------------------------------------------------------------------
# THE CONFIDENCE LEVEL (Finding 4) -- stated ONCE, in @emlReportAlpha
# (plugin_EML_StatsGraphs/stats/eml-analysis.praat: "the alpha the report
# marks significance against ... a caller's global emlAlpha when one has
# been set to a usable value, otherwise .05"). Parsed here rather than
# retyped as "0.95", for the same reason v105_pitch_parity.R parses
# @emlPitchArgsFAC instead of restating its tail: a second place for the
# level to live is a second thing that can drift. The committed CSV this
# script writes STILL RECORDS the level it was computed at (stat
# "confidence_level", below) -- the oracle stays reproducible -- but the
# recorded value is DERIVED from the procedure, not hand-typed, and
# validate/v130_survey_declared_oracle.R#7 checks that this parse and its
# own copy of the same parse still agree.
# ---------------------------------------------------------------------------
parse_canon_level <- function(analysis_path) {
    if (!file.exists(analysis_path)) return(NA_real_)
    al <- readLines(analysis_path, warn = FALSE)
    decl <- grep("^\\s*procedure\\s+emlReportAlpha\\b", al)
    if (length(decl) != 1L) return(NA_real_)
    ends <- grep("^\\s*endproc\\b", al)
    ends <- ends[ends > decl]
    if (!length(ends)) return(NA_real_)
    body <- al[seq.int(decl, ends[1])]
    asg <- grep("^\\s*\\.value\\s*=\\s*[0-9.]+\\s*$", body, value = TRUE)
    if (length(asg) != 1L) return(NA_real_)
    alpha <- suppressWarnings(as.numeric(sub("^\\s*\\.value\\s*=\\s*", "", asg)))
    if (is.na(alpha) || alpha <= 0 || alpha >= 1) return(NA_real_)
    1 - alpha
}
analysis_path <- normalizePath(file.path(here, "..", "..",
    "plugin_EML_StatsGraphs", "stats", "eml-analysis.praat"), mustWork = FALSE)
CONFIDENCE_LEVEL <- parse_canon_level(analysis_path)
if (is.na(CONFIDENCE_LEVEL)) {
    stop(sprintf(paste0("could not parse @emlReportAlpha's default level out of %s -- ",
                        "the confidence level has no canon to derive from, refusing ",
                        "to fall back to a silent literal"), analysis_path))
}
put("confidence_level", CONFIDENCE_LEVEL, 0)

# --- Cronbach's alpha ----------------------------------------------------
#
# NOTE (reported, not fixed here): psych::alpha() has no conf.level
# parameter -- its Feldt CI is computed at a level fixed INSIDE the psych
# package itself, unconditionally 0.95, regardless of CONFIDENCE_LEVEL.
# The alpha_{clean,revnotrev,2item,missing}_feldt_{lo,hi} rows below are
# therefore pinned to psych's own internal 95% and do not track
# @emlReportAlpha; there is no argument to pass that would change this.
# This is a real, unfixable-from-here hardcode, distinct from the
# declared_* family below (which uses this file's own base_feldt() and
# does track CONFIDENCE_LEVEL).

stopifnot(requireNamespace("psych", quietly = TRUE))
for (fx in c("clean", "revnotrev", "2item", "missing")) {
    m <- as.matrix(read.csv(file.path(csvdir,
                                      paste0("lane_survey_alpha_", fx, ".csv"))))
    cc <- m[complete.cases(m), , drop = FALSE]
    a <- suppressWarnings(psych::alpha(as.data.frame(cc),
                                       check.keys = FALSE, warnings = FALSE))
    put(paste0("alpha_", fx), a$total$raw_alpha, 1e-10)
    put(paste0("alpha_", fx, "_feldt_lo"), a$feldt$lower.ci[[1]], 1e-8)
    put(paste0("alpha_", fx, "_feldt_hi"), a$feldt$upper.ci[[1]], 1e-8)
    put(paste0("alpha_", fx, "_n"), nrow(cc), 0)
    put(paste0("alpha_", fx, "_nExcluded"), nrow(m) - nrow(cc), 0)
    if (ncol(m) >= 3) {
        for (j in seq_len(ncol(m))) {
            put(sprintf("alpha_%s_drop%d", fx, j),
                a$alpha.drop$raw_alpha[j], 1e-10)
        }
    }
}

# --- Respondent influence on alpha (base R, no packages) -----------------

base_alpha <- function(cc) {
    k <- ncol(cc)
    C <- stats::cov(cc)
    (k / (k - 1)) * (1 - sum(diag(C)) / sum(C))
}
for (fx in c("alpha_clean", "influence_deviant", "influence_missdev",
             "influence_n3")) {
    m <- as.matrix(read.csv(file.path(csvdir,
                                      paste0("lane_survey_", fx, ".csv"))))
    keep <- complete.cases(m)
    cc <- m[keep, , drop = FALSE]
    full <- base_alpha(cc)
    aw <- vapply(seq_len(nrow(cc)), function(i)
        base_alpha(cc[-i, , drop = FALSE]), numeric(1))
    dl <- aw - full
    put(paste0("influence_", fx, "_alphaFull"), full, 1e-10)
    put(paste0("influence_", fx, "_deltaMax"), max(abs(dl)), 1e-10)
    put(paste0("influence_", fx, "_deltaMaxRow"),
        which(keep)[which.max(abs(dl))], 0)
}

# --- Chi-square + Cramér's V --------------------------------------------

for (fx in c("2x2_balanced", "2x2_sparse", "3x4", "zerocell")) {
    m <- as.matrix(read.csv(file.path(csvdir,
                                      paste0("lane_survey_chisq_", fx, ".csv"))))
    for (corr in c(TRUE, FALSE)) {
        r <- suppressWarnings(chisq.test(m, correct = corr))
        key <- sprintf("chisq_%s_c%d", fx, as.integer(corr))
        put(paste0(key, "_stat"), unname(r$statistic), 1e-10)
        put(paste0(key, "_df"), unname(r$parameter), 0)
        put(paste0(key, "_p"), r$p.value, 1e-10)
    }
    r0 <- suppressWarnings(chisq.test(m, correct = FALSE))
    put(paste0("chisq_", fx, "_cramersV"),
        sqrt(unname(r0$statistic) / (sum(m) * (min(dim(m)) - 1))), 1e-10)
    put(paste0("chisq_", fx, "_minExpected"), min(r0$expected), 1e-10)
    put(paste0("chisq_", fx, "_nBelow5"), sum(r0$expected < 5), 0)
}

# --- Wilson intervals ----------------------------------------------------

cases <- read.csv(file.path(csvdir, "lane_survey_wilson_cases.csv"))
for (i in seq_len(nrow(cases))) {
    cs <- cases[i, ]
    ci <- suppressWarnings(prop.test(cs$x, cs$n, conf.level = cs$conf,
                                     correct = FALSE)$conf.int)
    put(paste0("wilson_", cs$case, "_lo"), ci[1], 1e-10)
    put(paste0("wilson_", cs$case, "_hi"), ci[2], 1e-10)
}

# --- Declared-survey subscales (declared-range reversal, per-subscale) ---
# From lane_survey_declared_data.csv plus the two declaration files
# (lane_survey_declared_scales.csv, lane_survey_declared_items.csv). Two
# independent routes to every alpha-family value, agreeing to 1e-12 or the
# run stops:
#   Route A: base R from the covariance matrix (the v90 formula).
#   Route B: psych::alpha on data reversed by psych::reverse.code(keys, ...,
#            mini=, maxi=) using the SUBSCALE'S DECLARED range — not
#            alpha()'s own automatic keys= reversal, which reverse-codes
#            each item against its OBSERVED min/max and would silently
#            diverge from the declared-range rule the plan pins (verified:
#            Q2's observed max is 4 against a declared max of 5; Ease's R1/
#            R3 never touch the declared 0/100 endpoints). reverse.code()
#            is the same psych function alpha() calls internally; feeding
#            it the declared mini/maxi and check.keys=FALSE afterwards is
#            "psych::alpha with keys= carrying the declared reversal" done
#            through psych's own reversal primitive instead of through its
#            observed-range default.
agree_or_stop <- function(label, a, b, tol = 1e-12) {
    d <- abs(a - b)
    bad <- is.na(d) | d > tol
    if (any(bad)) {
        stop(sprintf(paste0("DISAGREEMENT [%s]: base-R vs psych differ by up to %.3e ",
                            "(tol %.3e)\n  base-R: %s\n  psych : %s"),
                     label, suppressWarnings(max(d, na.rm = TRUE)), tol,
                     paste(format(a, digits = 17), collapse = ", "),
                     paste(format(b, digits = 17), collapse = ", ")))
    }
}

base_alpha_cov <- function(cc) {
    k <- ncol(cc); C <- stats::cov(cc)
    (k / (k - 1)) * (1 - sum(diag(C)) / sum(C))
}
base_feldt <- function(a, n, k, level = CONFIDENCE_LEVEL) {
    df1 <- n - 1; df2 <- (n - 1) * (k - 1)
    tail <- (1 - level) / 2
    c(lo = 1 - (1 - a) * stats::qf(1 - tail, df1, df2),
      hi = 1 - (1 - a) * stats::qf(tail, df1, df2))
}
base_alpha_drop <- function(cc) {
    k <- ncol(cc); C <- stats::cov(cc)
    vapply(seq_len(k), function(j) {
        kk <- k - 1
        if (kk < 2) return(NA_real_)
        Cj <- C[-j, -j, drop = FALSE]
        (kk / (kk - 1)) * (1 - sum(diag(Cj)) / sum(Cj))
    }, numeric(1))
}
# item-rest: item j against the sum of the OTHER items in its subscale.
# item-total (uncorrected): item j against the subscale total INCLUDING j.
base_item_rest_total <- function(cc) {
    k <- ncol(cc)
    total <- rowSums(cc)
    rest <- vapply(seq_len(k), function(j)
        stats::cor(cc[, j], total - cc[, j]), numeric(1))
    tot <- vapply(seq_len(k), function(j)
        stats::cor(cc[, j], total), numeric(1))
    list(rest = rest, tot = tot)
}

decl_data   <- read.csv(file.path(csvdir, "lane_survey_declared_data.csv"),
                        stringsAsFactors = FALSE)
decl_scales <- read.csv(file.path(csvdir, "lane_survey_declared_scales.csv"),
                        stringsAsFactors = FALSE)
decl_items  <- read.csv(file.path(csvdir, "lane_survey_declared_items.csv"),
                        stringsAsFactors = FALSE)

for (i in seq_len(nrow(decl_scales))) {
    sname <- decl_scales$scale[i]
    smin  <- decl_scales$min[i]
    smax  <- decl_scales$max[i]
    ritems <- decl_items[decl_items$role == sname, ]
    cols <- ritems$item
    keys <- ifelse(ritems$reversed == 1, -1, 1)

    raw <- as.matrix(decl_data[, cols, drop = FALSE])
    storage.mode(raw) <- "double"

    # -- declared reversal applied: min + max - x on the declared range ---
    reversed <- psych::reverse.code(keys, raw,
                                    mini = rep(smin, length(cols)),
                                    maxi = rep(smax, length(cols)))
    colnames(reversed) <- cols

    keep <- stats::complete.cases(reversed)
    cc <- reversed[keep, , drop = FALSE]
    n <- nrow(cc); k <- ncol(cc); nExcluded <- nrow(reversed) - n

    a_base <- base_alpha_cov(cc)
    fc <- base_feldt(a_base, n, k)
    drop_base <- base_alpha_drop(cc)
    ir <- base_item_rest_total(cc)

    p <- suppressWarnings(psych::alpha(as.data.frame(cc), check.keys = FALSE,
                                       warnings = FALSE))
    agree_or_stop(sprintf("%s alpha", sname), a_base, p$total$raw_alpha)
    agree_or_stop(sprintf("%s feldt lo", sname), fc[["lo"]], p$feldt$lower.ci[[1]])
    agree_or_stop(sprintf("%s feldt hi", sname), fc[["hi"]], p$feldt$upper.ci[[1]])
    if (k >= 3) {
        agree_or_stop(sprintf("%s alpha-if-deleted", sname), drop_base,
                      p$alpha.drop$raw_alpha)
    }
    agree_or_stop(sprintf("%s item-rest", sname), ir$rest, p$item.stats$r.drop)
    agree_or_stop(sprintf("%s item-total (uncorrected)", sname), ir$tot,
                 p$item.stats$raw.r)

    put(sprintf("declared_%s_alpha", sname), a_base, 1e-10)
    put(sprintf("declared_%s_feldt_lo", sname), fc[["lo"]], 1e-8)
    put(sprintf("declared_%s_feldt_hi", sname), fc[["hi"]], 1e-8)
    put(sprintf("declared_%s_n", sname), n, 0)
    put(sprintf("declared_%s_nExcluded", sname), nExcluded, 0)
    for (j in seq_len(k)) {
        if (k >= 3) {
            put(sprintf("declared_%s_drop_%s", sname, cols[j]), drop_base[j], 1e-10)
        }
        put(sprintf("declared_%s_itemrest_%s", sname, cols[j]), ir$rest[j], 1e-10)
        put(sprintf("declared_%s_itemtotal_%s", sname, cols[j]), ir$tot[j], 1e-10)
    }

    # -- respondent scale score: mean of the subscale's items after reverse-
    # scoring, complete-case (missing any item -> no score). Counts only,
    # never the 24 individual scores.
    put(sprintf("declared_%s_scoredN", sname), n, 0)
    put(sprintf("declared_%s_scoredNone", sname), nExcluded, 0)

    # -- respondent scale-score SUMMARY statistics (mean, sd, min, max of
    # the per-respondent scale score, complete-case). This is the one
    # artifact the declared RANGE actually moves (see the unreversed-
    # control comment below for why alpha itself cannot). Committed as
    # summary statistics only, matching this file's existing disclosure
    # discipline for scoredN/scoredNone above -- never the 24 individual
    # scores.
    #   Route A: base R, mean/sd/min/max of rowMeans(cc).
    #   Route B: psych::scoreItems(keys, raw, min=, max=, missing=FALSE,
    #            impute="none", totals=FALSE) -- psych's own scale-scoring
    #            primitive, fed the declared range exactly as reverse.code()
    #            was above, with missing=FALSE so an incomplete respondent
    #            is DROPPED from the returned score vector rather than
    #            imputed from the items they did answer (the same
    #            complete-case rule alpha uses -- verified: scoreItems()
    #            with missing=FALSE returns a vector already shortened to
    #            the complete-case respondents, in their original relative
    #            order, not a full-length vector with NA in the gaps -- so
    #            the two routes' raw score vectors are compared directly,
    #            with no re-indexing by `keep`).
    scores_base <- rowMeans(cc)
    sc <- suppressWarnings(psych::scoreItems(keys, raw, min = smin, max = smax,
                                             missing = FALSE, impute = "none",
                                             totals = FALSE))
    scores_psych <- sc$scores[, 1]
    agree_or_stop(sprintf("%s scale-score (per respondent)", sname),
                 scores_base, scores_psych)

    put(sprintf("declared_%s_scoreMean", sname), mean(scores_base), 1e-10)
    put(sprintf("declared_%s_scoreSD", sname), sd(scores_base), 1e-10)
    put(sprintf("declared_%s_scoreMin", sname), min(scores_base), 1e-10)
    put(sprintf("declared_%s_scoreMax", sname), max(scores_base), 1e-10)

    # -- KR-20 case: Knowledge's declared range spans exactly two values
    # (max = min + 1) and every item is binary within it. Same alpha
    # family; asserts nothing new, just records under a name that says so.
    if ((smax - smin) == 1) {
        put(sprintf("kr20_%s_alpha", sname), a_base, 1e-10)
        put(sprintf("kr20_%s_feldt_lo", sname), fc[["lo"]], 1e-8)
        put(sprintf("kr20_%s_feldt_hi", sname), fc[["hi"]], 1e-8)
        put(sprintf("kr20_%s_n", sname), n, 0)
        put(sprintf("kr20_%s_nExcluded", sname), nExcluded, 0)
    }

    # -- translation invariance: Ease + 1e8, alpha unchanged -------------
    if (sname == "Ease") {
        cc_off <- cc + 1e8
        a_off <- base_alpha_cov(cc_off)
        p_off <- suppressWarnings(psych::alpha(as.data.frame(cc_off),
                                               check.keys = FALSE, warnings = FALSE))
        agree_or_stop("Ease offset alpha", a_off, p_off$total$raw_alpha)
        put("declared_Ease_offset_alpha", a_off, 1e-10)
    }

    # -- unreversed control: alpha WITHOUT the declared reversal. This is
    # the wrong-declaration value; the red demo compares it to
    # declared_<scale>_alpha and the reversed-flag-drop leg needs it to
    # differ. It is NOT what a red demo on the RANGE constant needs: raw
    # alpha, the Feldt CI, alpha-if-deleted, and the item-rest/item-total
    # correlations are all functions of the covariance matrix alone, so
    # they are invariant to the specific numeric endpoints used in
    # min + max - x (only the SIGN of the transform -- whether an item is
    # reversed at all -- moves them; verified empirically and provable
    # algebraically: Cov(a_i + b_i x_i, x_j) = b_i Cov(x_i, x_j) for any
    # constant a_i, so alpha and the item correlations never see a_i).
    # A wrong declared RANGE (right sign, wrong endpoints) therefore never
    # moves alpha; what it moves is the absolute scale-score mean, which
    # sits on the printed response scale. See the report for the demo.
    ccraw <- raw[stats::complete.cases(raw), , drop = FALSE]
    a_unrev <- base_alpha_cov(ccraw)
    fc_unrev <- base_feldt(a_unrev, nrow(ccraw), ncol(ccraw))
    p_unrev <- suppressWarnings(psych::alpha(as.data.frame(ccraw), check.keys = FALSE,
                                             warnings = FALSE))
    agree_or_stop(sprintf("%s unreversed alpha", sname), a_unrev, p_unrev$total$raw_alpha)
    put(sprintf("declared_%s_unrev_alpha", sname), a_unrev, 1e-10)
    put(sprintf("declared_%s_unrev_feldt_lo", sname), fc_unrev[["lo"]], 1e-8)
    put(sprintf("declared_%s_unrev_feldt_hi", sname), fc_unrev[["hi"]], 1e-8)
}

out <- do.call(rbind, rows)
outfile <- file.path(here, "lane_survey_oracle_values.csv")
write.csv(out, outfile, row.names = FALSE)
cat(sprintf("wrote %d oracle values to %s\n", nrow(out), outfile))
