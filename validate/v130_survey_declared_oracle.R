# ===========================================================================
# v130 -- the declared-survey oracle vs a FRESH, INDEPENDENT base-R
#         recomputation (survey-stats lane, Stage 1)
# ===========================================================================
# Settles every "declared_*" / "kr20_*" value in the committed
# validate/oracle/lane_survey_oracle_values.csv against a base-R
# recomputation done FRESH, IN THIS RUN, straight from the three committed
# declaration files (evidence/csv/lane_survey_declared_{data,scales,
# items}.csv) -- not by sourcing lane_survey_oracle_dump.R and trusting its
# arithmetic a second time, but by re-deriving alpha, the Feldt (1965) CI,
# alpha-if-deleted, item-rest, and item-total independently from the
# covariance matrix (the v90 formula), the way v90 recomputes the plain
# alpha oracle fresh rather than trusting a capture. A committed value that
# no longer reproduces here is a FAILURE, not a warning.
#
# STAGE 1 SCOPE, STATED PLAINLY: the reversal transform, per-subscale
# routing, and the report are Stage 2 and do not exist yet in
# scripts/eml-survey.praat or in the plugin. Nothing in this file drives
# Praat, and nothing here checks output Praat has not been asked to
# produce. Every check is ORACLE-SIDE: is the committed oracle right, does
# it still reproduce, and are the checks that will settle Stage 2's
# wrapper against it CAPABLE of catching a wrong answer. No leg here
# passes because nothing ran -- everything below is a real base-R
# computation compared against another real base-R computation (this run
# vs the committed CSV), or documented as oracle-only by construction.
#
# THE RANGE RED-DEMO, AND WHY IT IS NOT WHAT THE PLAN'S PROSE SAYS: the
# plan (SURVEY_MODULE_PLAN_2026-08-25.md, "Oracles and checks") says "a
# wrong declared range must change alpha ... and the leg must catch it."
# This is false, and demonstrably so, not an oversight this file works
# around quietly. The declared-range reversal is y = min + max - x for a
# constant c = min + max; for ANY constant c, Cov(c - x_i, x_j) =
# -Cov(x_i, x_j) and Var(c - x_i) = Var(x_i). Alpha, the Feldt CI,
# alpha-if-deleted, and both item-rest and item-total are pure functions
# of the covariance matrix, so NONE of them can see the specific value of
# c -- only the SIGN of the transform (whether an item is reversed at
# all) reaches them. This is verified empirically below (Confidence at
# the declared range 1-5 vs the wrong range 1-7: identical alpha to
# machine precision) as well as algebraically in this comment, and it
# matches the finding already filed against the oracle-dump session's
# work (see its memo, "IMPORTANT FINDING, reported not fixed"). What a
# wrong declared range DOES move is the scale-score MEAN, which sits on
# the printed response scale rather than in the covariance structure --
# so THAT is what this file's range red-demo asserts differs, with the
# alpha-invariance fact pinned alongside it as a documented, permanent
# "must match" rather than smuggled into a "must differ" that can never
# pass. The SIGN-drop red demo (a reversed item's flag ignored) has no
# such problem: it changes the transform's sign, which alpha-family
# statistics are fully sensitive to, and moves alpha by roughly a full
# point (0.90 -> -0.18 on Confidence) -- see below.
#
# Base R only in this file. A psych cross-check is opportunistic and
# guarded by requireNamespace, exactly as v90 does it -- a second opinion
# on the port, not a dependency of the suite.
#
# NOT registered in validate/run_all.R: this is lane work; the merging
# session registers it after the release round closes.
# ===========================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

red_mode <- nzchar(Sys.getenv("EML_LANE_RED", unset = ""))

havePsych <- requireNamespace("psych", quietly = TRUE)
cat(sprintf("      v130 oracle mode: base R%s\n",
            if (havePsych) " + psych cross-check" else
            " alone (psych not installed; cross-check not run)"))

# ---------------------------------------------------------------------------
# 0. Read the committed oracle CSV and the three declaration files.
# ---------------------------------------------------------------------------
oracle_csv <- repo_path("validate", "oracle", "lane_survey_oracle_values.csv")
check_true("v130", "the committed oracle CSV exists", file.exists(oracle_csv))

odf <- read.csv(oracle_csv, stringsAsFactors = FALSE)
oval <- setNames(odf$value, odf$stat)
otol <- setNames(odf$tol, odf$stat)

# oget: the committed value for a stat name, failing LOUDLY on absence --
# a stat this file expects to check that the CSV no longer carries is a
# suite defect, not a silently-skipped leg.
oget <- function(stat) {
    if (!stat %in% names(oval)) stop(sprintf("oracle stat '%s' not found in %s", stat, oracle_csv))
    unname(oval[[stat]])
}
otolf <- function(stat, default = 1e-10) {
    v <- unname(otol[[stat]])
    if (is.null(v) || is.na(v)) default else v
}

csvdir <- repo_path("evidence", "csv")
decl_data   <- read.csv(file.path(csvdir, "lane_survey_declared_data.csv"),
                        stringsAsFactors = FALSE)
decl_scales <- read.csv(file.path(csvdir, "lane_survey_declared_scales.csv"),
                        stringsAsFactors = FALSE)
decl_items  <- read.csv(file.path(csvdir, "lane_survey_declared_items.csv"),
                        stringsAsFactors = FALSE)

# ---------------------------------------------------------------------------
# 1. Base-R primitives, independently written (not sourced from
#    lane_survey_oracle_dump.R): the v90 covariance-matrix formula.
# ---------------------------------------------------------------------------
base_alpha <- function(cc) {
    k <- ncol(cc); C <- stats::cov(cc)
    (k / (k - 1)) * (1 - sum(diag(C)) / sum(C))
}
base_feldt <- function(a, n, k, level = 0.95) {
    df1 <- n - 1; df2 <- (n - 1) * (k - 1)
    tail <- (1 - level) / 2
    c(lo = 1 - (1 - a) * stats::qf(1 - tail, df1, df2),
      hi = 1 - (1 - a) * stats::qf(tail, df1, df2))
}
base_drop <- function(cc) {
    k <- ncol(cc); C <- stats::cov(cc)
    vapply(seq_len(k), function(j) {
        kk <- k - 1
        if (kk < 2) return(NA_real_)
        Cj <- C[-j, -j, drop = FALSE]
        (kk / (kk - 1)) * (1 - sum(diag(Cj)) / sum(Cj))
    }, numeric(1))
}
base_item_rest_total <- function(cc) {
    total <- rowSums(cc)
    k <- ncol(cc)
    list(rest = vapply(seq_len(k), function(j) stats::cor(cc[, j], total - cc[, j]), numeric(1)),
         tot  = vapply(seq_len(k), function(j) stats::cor(cc[, j], total), numeric(1)))
}
# reverse.code, written out (not psych's): y = min + max - x for a
# reversed item, x unchanged otherwise -- exactly the transform the plan
# pins ("The range is the printed range").
reverse_apply <- function(raw, reversed, smin, smax) {
    out <- raw
    for (j in seq_len(ncol(raw))) {
        if (reversed[j] == 1) out[, j] <- smin + smax - raw[, j]
    }
    out
}

subscale_rows <- function(sname) decl_items[decl_items$role == sname, , drop = FALSE]

# ---------------------------------------------------------------------------
# 2. Per subscale: alpha, Feldt bounds, alpha-if-deleted, n, nExcluded,
#    item-rest, item-total, scale-score counts -- against the COMMITTED
#    oracle, freshly recomputed. Every "declared_*" row the CSV carries is
#    reproduced here; a value that no longer matches fails the run.
# ---------------------------------------------------------------------------
subscale_fresh <- list()

for (i in seq_len(nrow(decl_scales))) {
    sname <- decl_scales$scale[i]
    smin  <- decl_scales$min[i]
    smax  <- decl_scales$max[i]
    ritems <- subscale_rows(sname)
    cols <- ritems$item
    reversed_flags <- ritems$reversed

    raw <- as.matrix(decl_data[, cols, drop = FALSE])
    storage.mode(raw) <- "double"
    reversed <- reverse_apply(raw, reversed_flags, smin, smax)

    keep <- stats::complete.cases(reversed)
    cc <- reversed[keep, , drop = FALSE]
    n <- nrow(cc); k <- ncol(cc); nExcluded <- nrow(reversed) - n

    a <- base_alpha(cc)
    fc <- base_feldt(a, n, k)
    drop_v <- if (k >= 3) base_drop(cc) else rep(NA_real_, k)
    ir <- base_item_rest_total(cc)

    subscale_fresh[[sname]] <- list(smin = smin, smax = smax, cols = cols,
                                    raw = raw, reversed = reversed, cc = cc,
                                    n = n, k = k, nExcluded = nExcluded,
                                    alpha = a, feldt = fc, drop = drop_v,
                                    rest = ir$rest, tot = ir$tot)

    check("v130", sprintf("[%s] alpha vs committed oracle", sname),
          a, oget(sprintf("declared_%s_alpha", sname)), tol = otolf(sprintf("declared_%s_alpha", sname)))
    check("v130", sprintf("[%s] Feldt lower (0.95) vs committed oracle", sname),
          fc[["lo"]], oget(sprintf("declared_%s_feldt_lo", sname)), tol = otolf(sprintf("declared_%s_feldt_lo", sname), 1e-8))
    check("v130", sprintf("[%s] Feldt upper (0.95) vs committed oracle", sname),
          fc[["hi"]], oget(sprintf("declared_%s_feldt_hi", sname)), tol = otolf(sprintf("declared_%s_feldt_hi", sname), 1e-8))
    check("v130", sprintf("[%s] n (complete-case) vs committed oracle", sname),
          n, oget(sprintf("declared_%s_n", sname)), tol = 0)
    check("v130", sprintf("[%s] nExcluded vs committed oracle", sname),
          nExcluded, oget(sprintf("declared_%s_nExcluded", sname)), tol = 0)

    for (j in seq_along(cols)) {
        cn <- cols[j]
        if (k >= 3) {
            check("v130", sprintf("[%s] alpha-if-deleted, item %s vs committed oracle", sname, cn),
                  drop_v[j], oget(sprintf("declared_%s_drop_%s", sname, cn)),
                  tol = otolf(sprintf("declared_%s_drop_%s", sname, cn)))
        }
        check("v130", sprintf("[%s] item-rest, item %s vs committed oracle", sname, cn),
              ir$rest[j], oget(sprintf("declared_%s_itemrest_%s", sname, cn)),
              tol = otolf(sprintf("declared_%s_itemrest_%s", sname, cn)))
        check("v130", sprintf("[%s] item-total (uncorrected), item %s vs committed oracle", sname, cn),
              ir$tot[j], oget(sprintf("declared_%s_itemtotal_%s", sname, cn)),
              tol = otolf(sprintf("declared_%s_itemtotal_%s", sname, cn)))
    }

    # Scale scores: complete-case is exactly the same row mask alpha uses
    # (a respondent missing any item in the subscale gets no score for
    # it -- the plan's own wording). scoredN/scoredNone are COUNTS only,
    # never the 24 individual scores (plan: "Emit the count of respondents
    # scored and the count with no score, not the 24 individual scores").
    check("v130", sprintf("[%s] scale-score scoredN (complete-case) vs committed oracle", sname),
          n, oget(sprintf("declared_%s_scoredN", sname)), tol = 0)
    check("v130", sprintf("[%s] scale-score scoredNone vs committed oracle", sname),
          nExcluded, oget(sprintf("declared_%s_scoredNone", sname)), tol = 0)

    # Scale-score SUMMARY statistics (mean, sd, min, max of the per-
    # respondent scale score, complete-case) -- this is the artifact the
    # declared range demo below actually guards, per subscale, against a
    # COMMITTED value (not a value transiently recomputed inside the demo
    # itself, which would guard nothing).
    scores_fresh <- rowMeans(cc)
    subscale_fresh[[sname]]$scoreMean <- mean(scores_fresh)
    check("v130", sprintf("[%s] scale-score mean vs committed oracle", sname),
          mean(scores_fresh), oget(sprintf("declared_%s_scoreMean", sname)),
          tol = otolf(sprintf("declared_%s_scoreMean", sname)))
    check("v130", sprintf("[%s] scale-score sd vs committed oracle", sname),
          stats::sd(scores_fresh), oget(sprintf("declared_%s_scoreSD", sname)),
          tol = otolf(sprintf("declared_%s_scoreSD", sname)))
    check("v130", sprintf("[%s] scale-score min vs committed oracle", sname),
          min(scores_fresh), oget(sprintf("declared_%s_scoreMin", sname)),
          tol = otolf(sprintf("declared_%s_scoreMin", sname)))
    check("v130", sprintf("[%s] scale-score max vs committed oracle", sname),
          max(scores_fresh), oget(sprintf("declared_%s_scoreMax", sname)),
          tol = otolf(sprintf("declared_%s_scoreMax", sname)))

    # The "unreversed" control (declared reversal ignored entirely) is
    # committed for every subscale; reproduced here for all four so a
    # regression anywhere is caught, not only on the subscale the sign-
    # drop red demo below happens to use.
    ccraw <- raw[stats::complete.cases(raw), , drop = FALSE]
    a_unrev <- base_alpha(ccraw)
    check("v130", sprintf("[%s] unreversed alpha (sign dropped) vs committed oracle", sname),
          a_unrev, oget(sprintf("declared_%s_unrev_alpha", sname)),
          tol = otolf(sprintf("declared_%s_unrev_alpha", sname)))
    subscale_fresh[[sname]]$a_unrev <- a_unrev

    # Opportunistic second opinion (v90's pattern): psych::alpha fed the
    # SAME already-reversed matrix, check.keys = FALSE so psych does not
    # re-reverse on its own observed-range guess.
    if (havePsych) {
        p <- suppressWarnings(psych::alpha(as.data.frame(cc), check.keys = FALSE,
                                           warnings = FALSE))
        check("v130", sprintf("[%s] fresh alpha vs psych::alpha (cross-check)", sname),
              a, p$total$raw_alpha, tol = 1e-12)
        check("v130", sprintf("[%s] fresh item-rest vs psych r.drop (cross-check)", sname),
              max(abs(ir$rest - p$item.stats$r.drop)), 0, tol = 1e-10)
    }
}

# ---------------------------------------------------------------------------
# 3. Translation invariance, Ease subscale, offset 1e8.
# ---------------------------------------------------------------------------
ease <- subscale_fresh[["Ease"]]
check_true("v130", "the Ease subscale was recomputed above (precondition for the offset leg)",
           !is.null(ease))
if (!is.null(ease)) {
    cc_off <- ease$cc + 1e8
    a_off <- base_alpha(cc_off)
    check("v130", "[Ease] translation invariance (+1e8) vs committed oracle",
          a_off, oget("declared_Ease_offset_alpha"), tol = otolf("declared_Ease_offset_alpha"))
    check_true("v130", "[Ease] translation invariance holds to 1e-10 against the UNOFFSET alpha too",
               abs(a_off - ease$alpha) < 1e-9)
}

# ---------------------------------------------------------------------------
# 4. KR-20 case: Knowledge's declared range spans exactly two values
#    (max = min + 1), asserted on the COMMITTED declaration files, and its
#    alpha matches the oracle under the kr20_* name as well as declared_*.
# ---------------------------------------------------------------------------
kn_row <- decl_scales[decl_scales$scale == "Knowledge", , drop = FALSE]
check_true("v130", "Knowledge is declared in lane_survey_declared_scales.csv",
           nrow(kn_row) == 1)
if (nrow(kn_row) == 1) {
    span <- kn_row$max[1] - kn_row$min[1]
    check("v130", "Knowledge's declared range spans exactly two values (max = min + 1)",
          span, 1, tol = 0)
    kn <- subscale_fresh[["Knowledge"]]
    check_true("v130", "Knowledge was recomputed above (precondition for the KR-20 leg)",
               !is.null(kn))
    if (!is.null(kn)) {
        check("v130", "[Knowledge/KR-20] alpha vs committed kr20_Knowledge_alpha",
              kn$alpha, oget("kr20_Knowledge_alpha"), tol = otolf("kr20_Knowledge_alpha"))
        check("v130", "[Knowledge/KR-20] Feldt lower vs committed kr20_Knowledge_feldt_lo",
              kn$feldt[["lo"]], oget("kr20_Knowledge_feldt_lo"), tol = otolf("kr20_Knowledge_feldt_lo", 1e-8))
        check("v130", "[Knowledge/KR-20] Feldt upper vs committed kr20_Knowledge_feldt_hi",
              kn$feldt[["hi"]], oget("kr20_Knowledge_feldt_hi"), tol = otolf("kr20_Knowledge_feldt_hi", 1e-8))
        check("v130", "[Knowledge/KR-20] n vs committed kr20_Knowledge_n",
              kn$n, oget("kr20_Knowledge_n"), tol = 0)
        check("v130", "[Knowledge/KR-20] nExcluded vs committed kr20_Knowledge_nExcluded",
              kn$nExcluded, oget("kr20_Knowledge_nExcluded"), tol = 0)
    }
    # Every OTHER declared subscale must NOT qualify, so the naming
    # condition is a real gate and not vacuously true of everything.
    for (sname in setdiff(decl_scales$scale, "Knowledge")) {
        row <- decl_scales[decl_scales$scale == sname, , drop = FALSE]
        check_true("v130", sprintf("[%s] does NOT qualify for the KR-20 name (range span != 1)", sname),
                   (row$max[1] - row$min[1]) != 1)
    }
}

# ---------------------------------------------------------------------------
# 5. RED DEMO 1 -- dropped reversed flag (Confidence's Q3 treated as
#    forward-scored instead of reversed). This is the demo that actually
#    moves alpha: the sign of the transform is what alpha-family statistics
#    see, and dropping it moves Confidence from ~0.90 to ~-0.18.
# ---------------------------------------------------------------------------
conf <- subscale_fresh[["Confidence"]]
check_true("v130", "Confidence was recomputed above (precondition for the sign-drop red demo)",
           !is.null(conf))
if (!is.null(conf)) {
    # conf$a_unrev is exactly "every reversed flag in Confidence dropped".
    # The oracle-dump session's committed value already IS this defect's
    # oracle (declared_Confidence_unrev_alpha); recomputed fresh above.
    if (red_mode) {
        cat("      EML_LANE_RED: running the standard agreement check with the\n")
        cat("      reversed flag dropped -- the next check is EXPECTED to FAIL.\n")
        check("v130", "[RED] Confidence alpha with Q3's reversed flag dropped vs the correct oracle (must go red)",
              conf$a_unrev, conf$alpha, tol = 1e-10)
    } else {
        check("v130",
              "seeded dropped-reversed-flag defect: Confidence alpha DIFFERS from the correct oracle (proves the leg can fail)",
              conf$a_unrev, conf$alpha, tol = 1e-10, expect = "differ")
    }
}

# ---------------------------------------------------------------------------
# 6. RED DEMO 2 -- wrong declared range, Confidence 1-7 instead of 1-5.
#
# First, the documented invariance fact is PINNED as a "must match": alpha
# under the wrong range equals alpha under the correct range to machine
# precision. This is not the red demo -- it is the reason the red demo
# below is built on the scale-score mean rather than on alpha. Removing
# this pin would let a future edit quietly assume alpha DOES move with
# range and rebuild a red demo that can never pass.
# ---------------------------------------------------------------------------
if (!is.null(conf)) {
    wrong_min <- 1; wrong_max <- 7
    raw <- conf$raw
    reversed_flags <- subscale_rows("Confidence")$reversed
    reversed_wrong <- reverse_apply(raw, reversed_flags, wrong_min, wrong_max)
    cc_wrong <- reversed_wrong[stats::complete.cases(reversed_wrong), , drop = FALSE]
    alpha_wrong <- base_alpha(cc_wrong)

    # The invariance fact, pinned as a load-bearing "must match" -- not
    # advisory prose. alpha for Confidence computed with the CORRECT
    # declared range (1-5, the committed oracle's own basis) and with a
    # deliberately WRONG range (1-7) must be EQUAL, because alpha is a
    # pure function of the covariance matrix and the range shift is a
    # constant. This is the single pair that records the true consumer of
    # the declared range (the scale-score mean, checked immediately
    # below, which DOES move) and would catch a future change that
    # accidentally made alpha depend on the range's specific endpoints.
    check("v130", "[documented] alpha is invariant to the declared range's specific endpoints (Confidence, correct 1-5 vs wrong-declared 1-7)",
          alpha_wrong, conf$alpha, tol = 1e-10)
    ir_wrong <- base_item_rest_total(cc_wrong)
    check("v130", "[documented] item-rest is likewise invariant to the range endpoints (max abs difference)",
          max(abs(ir_wrong$rest - conf$rest)), 0, tol = 1e-10)

    # The actual red demo: the complete-case MEAN scale score (mean of the
    # subscale's reverse-scored items, matching the plan's "Scale scores"
    # rule) computed under the correct range vs the wrong one. This DOES
    # move, because it lives on the printed response scale rather than in
    # the covariance structure that alpha reads.
    #
    # The correct-range side is now settled against the COMMITTED oracle
    # value (declared_Confidence_scoreMean, checked above against this
    # same recomputation) rather than against another transient
    # computation done inline here -- so this leg guards the committed
    # scale-score artifact, not just internal self-consistency of this
    # file's own arithmetic. The wrong-range side has nothing committed
    # to read (the CSV records only the correctly-declared range's
    # statistics), so it is recomputed fresh, once, right here.
    mean_correct <- conf$scoreMean
    keep_correct <- stats::complete.cases(conf$reversed)
    keep_wrong <- stats::complete.cases(reversed_wrong)
    check_true("v130", "the wrong-range and correct-range scale-score means are computed over the same respondents (same complete-case mask)",
               identical(keep_correct, keep_wrong))
    mean_wrong <- mean(rowMeans(reversed_wrong[keep_wrong, , drop = FALSE]))

    if (red_mode) {
        cat("      EML_LANE_RED: running the standard agreement check on the\n")
        cat("      scale-score mean under the wrong declared range -- the next\n")
        cat("      check is EXPECTED to FAIL.\n")
        check("v130", "[RED] Confidence scale-score mean under the wrong declared range (1-7) vs the COMMITTED correct-range oracle (must go red)",
              mean_wrong, mean_correct, tol = 1e-6)
    } else {
        check("v130",
              "seeded wrong-declared-range defect: Confidence scale-score mean DIFFERS from the COMMITTED correct-range oracle (proves the leg can fail)",
              mean_wrong, mean_correct, tol = 1e-6, expect = "differ")
    }
}

if (!exists("EML_SUITE")) { eml_report("v130 declared-survey oracle"); eml_exit() }
