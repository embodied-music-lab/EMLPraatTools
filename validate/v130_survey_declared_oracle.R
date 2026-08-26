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
# 0b. THE CONFIDENCE LEVEL, PARSED OUT OF THE PROCEDURE THAT OWNS IT.
#
# @emlReportAlpha (plugin_EML_StatsGraphs/stats/eml-analysis.praat) is the
# one place the significance/confidence level is stated: "the alpha the
# report marks significance against ... a caller's global emlAlpha when
# one has been set to a usable value, otherwise .05." Restating "0.95"
# here as an independent literal would create a second place for the
# level to live and the second thing to drift is exactly Finding 4 (the
# oracle silently pinned to 95% while a user running at a different
# emlAlpha gets a different-width interval from the plugin). So, v105-
# style, the level is PARSED from the procedure body rather than
# retyped, and used as the default below instead of a bare "0.95".
# Section 7 is the parity check that this parse and the literal(s) below
# still agree; it is not this comment's job to enforce that, only to
# explain why the default is an expression and not a number.
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
    # THE BODY IS BOUNDED, NOT GREPPED FOR BY NAME, exactly as v105 bounds
    # @emlPitchArgsFAC's body -- ".value = ..." does not mention the
    # procedure's own name, so a whole-file grep would find every other
    # ".value = " assignment in the module too.
    asg <- grep("^\\s*\\.value\\s*=\\s*[0-9.]+\\s*$", body, value = TRUE)
    if (length(asg) != 1L) return(NA_real_)
    alpha <- suppressWarnings(as.numeric(sub("^\\s*\\.value\\s*=\\s*", "", asg)))
    if (is.na(alpha) || alpha <= 0 || alpha >= 1) return(NA_real_)
    1 - alpha
}

analysis_path <- repo_path("plugin_EML_StatsGraphs", "stats", "eml-analysis.praat")
CONFIDENCE_LEVEL <- parse_canon_level(analysis_path)

# ---------------------------------------------------------------------------
# 1. Base-R primitives, independently written (not sourced from
#    lane_survey_oracle_dump.R): the v90 covariance-matrix formula.
# ---------------------------------------------------------------------------
base_alpha <- function(cc) {
    k <- ncol(cc); C <- stats::cov(cc)
    (k / (k - 1)) * (1 - sum(diag(C)) / sum(C))
}
base_feldt <- function(a, n, k, level = CONFIDENCE_LEVEL) {
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
    check("v130", sprintf("[%s] Feldt lower (level %s, from @emlReportAlpha) vs committed oracle",
                          sname, format(CONFIDENCE_LEVEL)),
          fc[["lo"]], oget(sprintf("declared_%s_feldt_lo", sname)), tol = otolf(sprintf("declared_%s_feldt_lo", sname), 1e-8))
    check("v130", sprintf("[%s] Feldt upper (level %s, from @emlReportAlpha) vs committed oracle",
                          sname, format(CONFIDENCE_LEVEL)),
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

# ---------------------------------------------------------------------------
# 7. CONFIDENCE-LEVEL PARITY (Finding 4) -- the level in force is
#    @emlReportAlpha's, never a literal restated somewhere else.
#
# THE FAILURE THIS CATCHES. A user running the plugin at emlAlpha = .01
# gets a 99% Feldt interval from @emlCronbachAlpha; a committed oracle
# that independently states "0.95" stays 95% forever, so v130 would
# report the plugin "wrong" against an oracle set to a different level,
# and nothing would name the real cause. Section 0b already closed the
# supply side here (base_feldt's default is PARSED from @emlReportAlpha,
# not typed), and lane_survey_oracle_dump.R does the identical parse,
# independently, and RECORDS what it got as the committed "confidence_level"
# stat -- the oracle stays reproducible (the CSV states the level it was
# computed at) without that record being a second, driftable literal (it
# is written by the same parse, not hand-typed).
#
# TWO THINGS ARE THEREFORE CHECKED, NAMING BOTH SITES ON DISAGREEMENT:
#   (a) this file's own parse of @emlReportAlpha vs the committed CSV's
#       recorded "confidence_level" -- did the CSV get regenerated after
#       the last time the canon changed;
#   (b) a v105-style SCAN of the lane's R sources for the *shape* of a
#       hardcoded confidence-level default (`level = 0.NN`) -- the shape
#       both original hardcodes shared before this section's fix -- so a
#       THIRD site reintroducing that shape later is caught by the scan
#       finding something, rather than requiring a hand-written list of
#       "the two known sites" to be kept in sync by memory.
# ---------------------------------------------------------------------------

check_true("v130", "@emlReportAlpha's file is present", file.exists(analysis_path))
check_true("v130", "@emlReportAlpha's default level parses to a number in (0,1)",
           !is.na(CONFIDENCE_LEVEL) && CONFIDENCE_LEVEL > 0 && CONFIDENCE_LEVEL < 1)

# (a) THE CSV vs THE CANON -- names both sites explicitly.
committed_level <- oget("confidence_level")
check("v130",
      sprintf("committed oracle's recorded level (%s, %s stat \"confidence_level\") vs @emlReportAlpha's default (%s, %s)",
              format(committed_level), oracle_csv,
              format(CONFIDENCE_LEVEL), analysis_path),
      committed_level, CONFIDENCE_LEVEL, tol = 1e-12)

# (b) THE SCAN -- Finding 5's rewrite.
#
# THE DEFECT THIS REPLACES: the old scan matched only the literal SHAPE
# "level = 0.NN" against a HAND-ENUMERATED file list. Verified as not
# caught by that shape: `level <- 0.95`, `LEVEL <- 0.95`,
# `conf_level <- 0.95`, `level = .95` (no leading zero), and the
# positional call `base_feldt(a, n, k, 0.95)` -- every one of these files
# is written in `<-` throughout, the very style the shape-only scan never
# looked for, and a positional call has no "=" in it at all. The file
# list was hand-typed too: v131_survey_range_refusal_parity.R exists in
# this lane RIGHT NOW and the old three-entry list would never have
# scanned it.
#
# THE FIX, two parts:
#
#   File list DERIVED from the directory, not hand-typed: every ".R" file
#   under validate/ (recursive) whose name contains "survey" -- the
#   naming convention every file in this lane already follows (v129,
#   v130, v131, lane_survey_oracle_dump.R) -- so a new lane file is
#   scanned automatically, the same "derived set actually derives"
#   discipline Finding 3 restates for the census above.
#
#   Two detectors, because a confidence level is STATED in R in two
#   shapes an assignment-only scan cannot both see:
#     A. ASSIGNMENT -- a level-ish identifier (case-insensitive,
#        "level" anywhere in the name: level, LEVEL, conf_level,
#        confidenceLevel, ...) immediately followed by "<-" or a bare "="
#        (never "==", "<=", ">="), then a decimal literal strictly
#        between 0 and 1, with or without a leading zero.
#     B. POSITIONAL CALL -- DERIVED from the files' own function
#        signatures, not a hand-named function list: every
#        "name <- function(...)" definition found in these files with a
#        formal parameter matching the same level-ish test is recorded as
#        (function name, that parameter's 1-based position); every call
#        to that function name in these files is then checked at that
#        position for a bare decimal literal in (0,1) rather than a
#        symbol or expression. This is how `base_feldt(a, n, k, 0.95)` is
#        caught without ever hand-naming "base_feldt" -- base_feldt's own
#        "level = CONFIDENCE_LEVEL" default is what gets harvested.
#
#   A line's own "#" comment (the first one outside a quoted string) is
#   stripped before either detector runs, so prose describing a level --
#   including this comment block, and the old scan's own literal shape
#   `level = 0.NN` a few lines above -- is never a hit.
#
# LOUD FAILURE, same requirement as Finding 3's census: if the directory
# scan finds zero files, or the detectors find zero level-ish MENTIONS at
# all across a lane that mentions CONFIDENCE_LEVEL/parse_canon_level/
# base_feldt's own default dozens of times, the scan machinery itself is
# broken (a regex typo, a moved directory) and must not be allowed to
# report that vacuous "nothing found" as a clean "no stray literals" --
# so both halt the run outright rather than let (b)'s pass/fail check
# below run against a scan that looked at nothing.
lane_r_files <- list.files(repo_path("validate"), pattern = "survey.*\\.R$",
                           recursive = TRUE, full.names = TRUE,
                           ignore.case = TRUE)
if (length(lane_r_files) == 0L) {
    stop("v130 (b) confidence-level scan: the directory scan of validate/ ",
         "for '*survey*.R' found ZERO files -- the lane's own R sources ",
         "(v129/v130/v131/lane_survey_oracle_dump.R) should always match ",
         "this. Refusing to run the stray-literal check against an empty ",
         "file list, which would pass vacuously instead of failing.")
}
check_true("v130",
    sprintf("[Finding 5] the lane-R-source directory scan found at least one file (found %d: %s)",
            length(lane_r_files), paste(basename(lane_r_files), collapse = ", ")),
    length(lane_r_files) > 0L)

LEVELISH  <- "(?i)\\b[A-Za-z0-9_.]*level[A-Za-z0-9_.]*\\b"
DECIMAL01 <- "0?\\.[0-9]+"

strip_r_comment <- function(line) {
    # R's "#" starts a comment unless inside a quoted string. None of
    # these files' confidence-level statements need a "#" inside a
    # string on the same line, so tracking quote parity (no escapes to
    # worry about here) is sufficient without a full R tokenizer.
    chars <- strsplit(line, "", fixed = TRUE)[[1]]
    if (length(chars) == 0L) return(line)
    inq <- FALSE; q <- ""
    for (k in seq_along(chars)) {
        ch <- chars[k]
        if (inq) {
            if (ch == q) inq <- FALSE
        } else if (ch == '"' || ch == "'") {
            inq <- TRUE; q <- ch
        } else if (ch == "#") {
            return(paste(chars[seq_len(k - 1L)], collapse = ""))
        }
    }
    line
}

split_toplevel_args <- function(s) {
    chars <- strsplit(s, "", fixed = TRUE)[[1]]
    if (length(chars) == 0L) return(character(0))
    depth <- 0L; cur <- character(0); out <- character(0)
    for (ch in chars) {
        if (ch %in% c("(", "[")) depth <- depth + 1L
        if (ch %in% c(")", "]")) depth <- depth - 1L
        if (ch == "," && depth == 0L) {
            out <- c(out, paste(cur, collapse = "")); cur <- character(0)
        } else {
            cur <- c(cur, ch)
        }
    }
    c(out, paste(cur, collapse = ""))
}

# scan_level_literals -- kept its pre-Finding-5 NAME (the mutant red-demo
# below still calls it), but rewritten inside. `files` may be a named or
# unnamed character vector; a name (when the caller supplies one, as the
# (b) mutant-demo below still does for "dump") is preferred as the label,
# falling back to basename() for the directory-derived list, which has
# none.
#
# Returns ONLY the stray (literal-decimal) hits, matching the pre-Finding-
# 5 contract exactly -- the "did the scan look at anything real" floor is
# asserted separately, right below, via the total mention count.
scan_level_literals <- function(files) {
    stray <- character(0)
    mentions <- character(0)
    fn_param_pos <- list()
    nm <- names(files)
    label_of <- function(i) {
        if (!is.null(nm) && !is.na(nm[i]) && nzchar(nm[i])) nm[i] else basename(files[i])
    }

    file_lines <- vector("list", length(files))
    for (i in seq_along(files)) {
        fp <- files[i]
        if (!file.exists(fp)) next
        file_lines[[i]] <- vapply(readLines(fp, warn = FALSE), strip_r_comment,
                                  character(1), USE.NAMES = FALSE)
    }

    # Detector B, pass 1: harvest "name <- function(args)" signatures with
    # a level-ish formal parameter. Every definition in this lane's files
    # is single-line, so a per-file, single-pass regex is sufficient --
    # this does not attempt to parse a signature split across lines,
    # which does not occur here.
    for (i in seq_along(files)) {
        if (is.null(file_lines[[i]])) next
        txt <- paste(file_lines[[i]], collapse = "\n")
        m <- gregexpr("([A-Za-z_.][A-Za-z0-9_.]*)\\s*(?:<-|=)\\s*function\\s*\\(([^)]*)\\)",
                      txt, perl = TRUE)
        if (m[[1]][1] == -1) next
        cs <- attr(m[[1]], "capture.start"); cl <- attr(m[[1]], "capture.length")
        for (r in seq_len(nrow(cs))) {
            fname  <- substr(txt, cs[r, 1], cs[r, 1] + cl[r, 1] - 1L)
            argtxt <- substr(txt, cs[r, 2], cs[r, 2] + cl[r, 2] - 1L)
            args <- split_toplevel_args(argtxt)
            for (pos in seq_along(args)) {
                pname <- sub("^\\s*([A-Za-z_.][A-Za-z0-9_.]*).*$", "\\1", args[pos])
                if (grepl(LEVELISH, pname, perl = TRUE)) fn_param_pos[[fname]] <- pos
            }
        }
    }

    for (i in seq_along(files)) {
        if (is.null(file_lines[[i]])) next
        lbl <- label_of(i)
        lns <- file_lines[[i]]
        for (ln in seq_along(lns)) {
            line <- lns[ln]
            if (grepl(LEVELISH, line, perl = TRUE)) {
                mentions <- c(mentions, sprintf("%s:%d", lbl, ln))
                # Detector A: assignment.
                if (grepl(paste0(LEVELISH, "\\s*(<-|=(?!=))\\s*", DECIMAL01),
                          line, perl = TRUE)) {
                    stray <- c(stray, sprintf("%s:%d", lbl, ln))
                }
            }
            # Detector B: positional call to a harvested level-ish function.
            for (fname in names(fn_param_pos)) {
                cm <- gregexpr(paste0("\\b", fname, "\\s*\\("), line, perl = TRUE)[[1]]
                if (cm[1] == -1) next
                clens <- attr(cm, "match.length")
                for (k in seq_along(cm)) {
                    popen <- cm[k] + clens[k] - 1L
                    depth <- 1L; j <- popen + 1L; close <- NA_integer_
                    while (j <= nchar(line)) {
                        c2 <- substr(line, j, j)
                        if (c2 == "(") depth <- depth + 1L
                        if (c2 == ")") { depth <- depth - 1L
                                        if (depth == 0L) { close <- j; break } }
                        j <- j + 1L
                    }
                    if (is.na(close)) next
                    inner <- substr(line, popen + 1L, close - 1L)
                    args <- split_toplevel_args(inner)
                    pos <- fn_param_pos[[fname]]
                    if (pos <= length(args) &&
                        grepl(paste0("^\\s*", DECIMAL01, "\\s*$"), trimws(args[pos]))) {
                        stray <- c(stray, sprintf("%s:%d", lbl, ln))
                    }
                }
            }
        }
    }
    result <- unique(stray)
    attr(result, "mentions") <- unique(mentions)
    result
}

stray <- scan_level_literals(lane_r_files)
total_mentions <- attr(stray, "mentions")
if (length(total_mentions) == 0L) {
    stop("v130 (b) confidence-level scan: found ZERO level-ish identifier ",
         "mentions across the lane's own R sources, where CONFIDENCE_LEVEL/",
         "parse_canon_level/base_feldt's default are known to appear -- the ",
         "scan machinery itself is broken. Refusing to trust a vacuous ",
         "'no stray literals' from a scan that looked at nothing.")
}
check_true("v130",
    sprintf("[Finding 5] the scan found level-ish identifier mentions to look at (not vacuously empty -- %d found, proving the scan machinery itself is not silently broken)",
            length(total_mentions)),
    length(total_mentions) >= 10L)
check_true("v130",
    sprintf("no hardcoded confidence-level literal remains in the lane's R sources%s",
            if (length(stray)) sprintf(" (found: %s)", paste(stray, collapse = ", ")) else ""),
    length(stray) == 0L)

# Finding 5's own closing proof: the FIVE STYLES verified as missed by the
# old scan are caught by the new one, on a synthetic scratch file (never
# touching a committed file) that exercises Detector A four ways and
# Detector B once.
#
# Every decimal literal below is ASSEMBLED via paste0, exactly the same
# self-reference dodge the (b) mutant demo further down already uses
# ("Built via sprintf, not written as one contiguous literal") -- this
# file (v130_survey_declared_oracle.R) is itself one of the "survey.*\\.R$"
# files the directory-derived scan reads, so a decimal written out whole
# HERE would make the scan (correctly) flag this very block as a sixth
# stray site the moment it ran against its own source.
verified_missed_styles <- c(
    paste0("base_feldt <- function(a, n, k, level ", "= CONFIDENCE_LEVEL) {"),
    "    tail <- (1 - level) / 2",
    "}",
    paste0("level <- 0", ".95"),
    paste0("LEVEL <- 0", ".95"),
    paste0("conf_level <- 0", ".95"),
    paste0("level = ", ".95"),
    paste0("x <- base_feldt(a, n, k, 0", ".95)")
)
styles_dir <- file.path(tempdir(), "v130-finding5-styles")
dir.create(styles_dir, recursive = TRUE, showWarnings = FALSE)
styles_tf <- file.path(styles_dir, "styles.R")
writeLines(verified_missed_styles, styles_tf)
styles_stray <- scan_level_literals(c(styles = styles_tf))
check_true("v130",
    sprintf("[Finding 5] all five previously-missed styles are now caught on a synthetic file (found %d of 5: %s)",
            length(styles_stray), paste(styles_stray, collapse = ", ")),
    length(styles_stray) == 5L)

# PROOF BOTH CHECKS CAN ACTUALLY FAIL, and that each names its own site.
# Neither committed file is touched -- (a)'s red demo mutates a SCRATCH
# COPY of the oracle CSV; (b)'s mutates a SCRATCH COPY of dump.R by
# reintroducing the shape the scan looks for.
mutant_dir <- file.path(tempdir(), "v130-level-mutant")
unlink(mutant_dir, recursive = TRUE)
dir.create(mutant_dir, recursive = TRUE)

# (a) mutant: CSV's confidence_level row changed to 0.90.
odf_mut <- odf
odf_mut$value[odf_mut$stat == "confidence_level"] <- 0.90
mutant_csv_level <- odf_mut$value[odf_mut$stat == "confidence_level"][1]

if (red_mode) {
    cat("      EML_LANE_RED: comparing a scratch copy of the oracle CSV with\n")
    cat("      confidence_level changed to 0.90 against @emlReportAlpha's level --\n")
    cat("      the next check is EXPECTED to FAIL.\n")
    check("v130", "[RED] mutated oracle-CSV confidence_level (0.90) vs @emlReportAlpha's level (must go red)",
          mutant_csv_level, CONFIDENCE_LEVEL, tol = 1e-12)
} else {
    check("v130",
          "seeded confidence-level defect: mutated oracle-CSV confidence_level (0.90) DIFFERS from @emlReportAlpha's level (proves check (a) can fail)",
          mutant_csv_level, CONFIDENCE_LEVEL, tol = 1e-12, expect = "differ")
}
check_true("v130", "the mutation above touched only the scratch copy -- the committed CSV's own recorded level is untouched and still agrees",
           oget("confidence_level") == CONFIDENCE_LEVEL)

# (b) mutant: dump.R's base_feldt default reverted to a hardcoded literal
# in a scratch copy, reproducing the exact pre-fix line. lane_r_files is
# now DERIVED from the directory (Finding 5), not a named hand list, so
# its one "dump" entry is found by name pattern instead of a `[["dump"]]`
# lookup that no longer has anything to index.
dump_path <- lane_r_files[grepl("lane_survey_oracle_dump\\.R$", lane_r_files)]
check_true("v130", "the directory-derived file list contains exactly one lane_survey_oracle_dump.R",
           length(dump_path) == 1L)
dump_lines <- readLines(dump_path[1], warn = FALSE)
target_ln <- grep("^base_feldt <- function\\(a, n, k, level = CONFIDENCE_LEVEL\\) \\{$", dump_lines)
check_true("v130", "dump.R's base_feldt default line was found to mutate for the scan red-demo",
           length(target_ln) == 1L)
if (length(target_ln) == 1L) {
    # Built via sprintf, not written as one contiguous literal, so this
    # file's OWN source text never spells out a hardcoded confidence-level
    # default in the shape the scan below looks for -- if it did, that
    # scan (correctly) run against v130's own file would flag this
    # red-demo line as a fourth stray site, a self-referential false
    # positive rather than a demonstration.
    wrong_level_text <- paste0("0.", "90")
    dump_lines[target_ln] <- sprintf("base_feldt <- function(a, n, k, level = %s) {",
                                     wrong_level_text)
    mutant_path <- file.path(mutant_dir, "dump_mutant.R")
    writeLines(dump_lines, mutant_path)
    v130_path <- lane_r_files[grepl("v130_survey_declared_oracle\\.R$", lane_r_files)]
    check_true("v130", "the directory-derived file list contains exactly one v130_survey_declared_oracle.R",
               length(v130_path) == 1L)
    stray_mut <- scan_level_literals(c(v130 = v130_path[1], dump = mutant_path))

    if (red_mode) {
        cat("      EML_LANE_RED: scanning a scratch copy of dump.R with its default\n")
        cat("      reverted to a hardcoded 0.90 literal -- the next check is EXPECTED\n")
        cat("      to FAIL, naming the mutated dump.R site.\n")
        check_true("v130",
            sprintf("[RED] scan finds no hardcoded literal in the reverted dump.R scratch copy (must go red, naming: %s)",
                    paste(stray_mut, collapse = ", ")),
            length(stray_mut) == 0L)
    } else {
        check_true("v130",
            sprintf("seeded stray-literal defect: the scan DOES find the reverted dump.R literal (%s) (proves check (b) can fail)",
                    paste(stray_mut, collapse = ", ")),
            length(stray_mut) == 1L && startsWith(stray_mut[1], "dump:"))
    }
}

# ---------------------------------------------------------------------------
# 8. LIVE PRAAT DRIVE -- @emlSurveyScoreScales (Stage 2's own wiring,
#    plugin_EML_StatsGraphs/stats/eml-psychometrics.praat) vs the SAME
#    committed oracle CSV every section above already reproduces in base R.
#
# Everything above this line is oracle-side only -- this file's own
# original header said so plainly ("nothing in this file drives Praat"),
# because Stage 2 did not exist yet. It exists now. This section drives it
# LIVE on the three committed declaration files (unmodified) and checks
# every quantity the oracle CSV records for the four declared subscales:
# alpha, Feldt bounds, alpha-if-deleted, n, nExcluded, item-rest,
# item-total, and the scale-score summaries (mean/SD/min/max) -- the exact
# list the task itself names.
#
# @emlSurveyScoreScales reads @emlSurveyValidateDeclaration's own leftover
# output rather than re-deriving the declaration, so every probe below
# calls both, in that order, on the SAME dataT -- exactly the access
# pattern @emlSurveyScoreScales's own header documents.
# ---------------------------------------------------------------------------

praat8 <- Sys.getenv("PRAAT", unset = "")
if (!nzchar(praat8)) {
    for (cand in c(repo_path("..", "praat"), Sys.which("praat_barren"),
                   Sys.which("praat"))) {
        if (nzchar(cand) && file.exists(cand)) { praat8 <- cand; break }
    }
}
pv8 <- NA_character_; pvnum8 <- 0
if (nzchar(praat8) && file.exists(praat8)) {
    pv8 <- suppressWarnings(system2(praat8, "--version", stdout = TRUE, stderr = TRUE))[1]
    m8 <- regmatches(pv8, regexpr("[0-9]+\\.[0-9]+\\.[0-9]+", pv8))
    if (length(m8)) {
        p8 <- as.integer(strsplit(m8, ".", fixed = TRUE)[[1]])
        pvnum8 <- p8[1] * 1000 + p8[2] * 100 + p8[3]
    }
}
canDrive8 <- pvnum8 >= 6630

if (!canDrive8) {
    cat(paste0("      SKIP: v130 section 8 needs Praat >= 6.6.30 to drive\n",
               "            @emlSurveyScoreScales; found ",
               if (is.na(pv8)) "none" else pv8, ".\n"))
    check_true("v130",
        sprintf("a Praat at or above the plugin's floor is available for the live Stage-2 drive (found %s)",
                if (is.na(pv8)) "none" else pv8),
        FALSE)
} else {

    work8 <- file.path(tempdir(), "v130-stage2-drive")
    unlink(work8, recursive = TRUE)
    dir.create(file.path(work8, "scripts"), recursive = TRUE, showWarnings = FALSE)
    prefs8 <- file.path(work8, "prefs")
    dir.create(prefs8, showWarnings = FALSE)
    unlink(file.path(prefs8, c("pid", "message")))

    plug8 <- Sys.getenv("EML_PLUGIN_DIR", unset = "")
    if (!nzchar(plug8)) plug8 <- repo_path("plugin_EML_StatsGraphs")
    statsdir8 <- file.path(plug8, "stats")

    # link_stats8: symlinks the three untouched dependencies and either
    # symlinks the real eml-psychometrics.praat (the "clean" build) or
    # copies in a MUTATED scratch text (a mutant build, section 9 below) --
    # never editing the committed file itself either way.
    link_stats8 <- function(dirpath, psych_text = NULL) {
        dir.create(dirpath, recursive = TRUE, showWarnings = FALSE)
        file.symlink(normalizePath(file.path(statsdir8, "eml-extract.praat")),
                     file.path(dirpath, "eml-extract.praat"))
        file.symlink(normalizePath(file.path(statsdir8, "eml-inferential.praat")),
                     file.path(dirpath, "eml-inferential.praat"))
        file.symlink(normalizePath(file.path(statsdir8, "eml-analysis.praat")),
                     file.path(dirpath, "eml-analysis.praat"))
        if (is.null(psych_text)) {
            file.symlink(normalizePath(file.path(statsdir8, "eml-psychometrics.praat")),
                         file.path(dirpath, "eml-psychometrics.praat"))
        } else {
            writeLines(psych_text, file.path(dirpath, "eml-psychometrics.praat"))
        }
    }

    clean_dir8 <- file.path(work8, "clean")
    link_stats8(clean_dir8)

    esc8 <- function(p) gsub('"', '""', p)
    data_path8   <- file.path(csvdir, "lane_survey_declared_data.csv")
    scales_path8 <- file.path(csvdir, "lane_survey_declared_scales.csv")
    items_path8  <- file.path(csvdir, "lane_survey_declared_items.csv")

    # drive_score8: writes a probe script that validates the declaration,
    # confirms refusal = 0 (exactly @emlSurveyScoreScales's own documented
    # precondition), then calls @emlSurveyScoreScales once and dumps a
    # tagged line per subscale ("SC|...") and per subscale item ("IT|...").
    # Scale/item names never contain "|" in this fixture (same assumption
    # v129's own driver already relies on for the identical reason).
    drive_score8 <- function(dirlabel, tag) {
        probe <- file.path(work8, "scripts", paste0("v130-", tag, ".praat"))
        writeLines(c(
            paste0("include ../", dirlabel, "/eml-extract.praat"),
            paste0("include ../", dirlabel, "/eml-inferential.praat"),
            paste0("include ../", dirlabel, "/eml-analysis.praat"),
            paste0("include ../", dirlabel, "/eml-psychometrics.praat"),
            "",
            sprintf('dataT = Read Table from comma-separated file: "%s"', esc8(data_path8)),
            sprintf('scalesT = Read Table from comma-separated file: "%s"', esc8(scales_path8)),
            sprintf('itemsT = Read Table from comma-separated file: "%s"', esc8(items_path8)),
            "",
            "@emlSurveyValidateDeclaration: dataT, scalesT, itemsT",
            'writeInfoLine: "refusal|", emlSurveyValidateDeclaration.refusal, "|END"',
            "if emlSurveyValidateDeclaration.refusal = 0",
            "    @emlSurveyScoreScales: dataT",
            '    appendInfoLine: "CONF|", emlSurveyScoreScales.confidence, "|END"',
            "    for s from 1 to emlSurveyScoreScales.nScales",
            '        name$ = emlSurveyValidateDeclaration.scaleName$[s]',
            '        appendInfoLine: "SC|", name$, "|",',
            "        ... emlSurveyScoreScales.subK[s], \"|\",",
            "        ... emlSurveyScoreScales.subAlpha[s], \"|\",",
            "        ... emlSurveyScoreScales.subCiLow[s], \"|\",",
            "        ... emlSurveyScoreScales.subCiHigh[s], \"|\",",
            "        ... emlSurveyScoreScales.subN[s], \"|\",",
            "        ... emlSurveyScoreScales.subNExcluded[s], \"|\",",
            "        ... length (emlSurveyScoreScales.subAlphaError$[s]), \"|\",",
            "        ... emlSurveyScoreScales.subScoredN[s], \"|\",",
            "        ... emlSurveyScoreScales.subScoredNone[s], \"|\",",
            "        ... emlSurveyScoreScales.subScoreMean[s], \"|\",",
            "        ... emlSurveyScoreScales.subScoreSD[s], \"|\",",
            "        ... emlSurveyScoreScales.subScoreMin[s], \"|\",",
            "        ... emlSurveyScoreScales.subScoreMax[s], \"|\",",
            "        ... emlSurveyScoreScales.subIsKR20[s], \"|END\"",
            "        for j from 1 to emlSurveyScoreScales.subK[s]",
            "            origIdx = emlSurveyScoreScales.subItemOrigIdx[s,j]",
            '            iname$ = emlSurveyValidateDeclaration.itemName$[origIdx]',
            '            appendInfoLine: "IT|", name$, "|", iname$, "|",',
            "            ... emlSurveyScoreScales.subAlphaIfDeleted[s,j], \"|\",",
            "            ... emlSurveyScoreScales.subItemRest[s,j], \"|\",",
            "            ... emlSurveyScoreScales.subItemTotal[s,j], \"|\",",
            "            ... emlSurveyScoreScales.subItemFlag[s,j], \"|END\"",
            "        endfor",
            "    endfor",
            "endif"),
            probe)
        suppressWarnings(system2("env",
            c("-u", "DISPLAY", shQuote(praat8),
              shQuote(paste0("--pref-dir=", prefs8)), "--run", shQuote(probe)),
            stdout = TRUE, stderr = TRUE))
    }

    fld8 <- function(out, tag) {
        h <- grep(paste0("^", tag, "\\|"), out, value = TRUE)
        if (!length(h)) return(character(0))
        strsplit(sub(paste0("^", tag, "\\|"), "", h[1]), "|", fixed = TRUE)[[1]]
    }
    # sc_field8/it_field8: locate the ONE "SC|<scale>|..." / "IT|<scale>|<item>|..."
    # line matching the given scale (and item) name, then return field i
    # (1-based, counting AFTER the name column(s)).
    sc_line8 <- function(out, scale) {
        h <- grep(paste0("^SC\\|", scale, "\\|"), out, value = TRUE)
        if (!length(h)) return(character(0))
        strsplit(sub(paste0("^SC\\|", scale, "\\|"), "", h[1]), "|", fixed = TRUE)[[1]]
    }
    it_line8 <- function(out, scale, item) {
        h <- grep(paste0("^IT\\|", scale, "\\|", item, "\\|"), out, value = TRUE)
        if (!length(h)) return(character(0))
        strsplit(sub(paste0("^IT\\|", scale, "\\|", item, "\\|"), "", h[1]), "|", fixed = TRUE)[[1]]
    }
    numf8 <- function(v, i) {
        if (length(v) < i) return(NA_real_)
        x <- v[i]
        if (is.na(x) || identical(x, "--undefined--")) return(NA_real_)
        suppressWarnings(as.numeric(x))
    }

    out_clean8 <- drive_score8("clean", "clean")
    ran_clean8 <- !any(grepl("^Error", out_clean8)) && length(fld8(out_clean8, "refusal")) >= 1
    check_true("v130", "[Stage 2] the live probe ran on the committed declaration",
               ran_clean8)
    check_true("v130", "[Stage 2] the live probe's own declaration refusal is 0",
               ran_clean8 && numf8(fld8(out_clean8, "refusal"), 1) == 0)

    if (ran_clean8) {
        check("v130", "[Stage 2] @emlSurveyScoreScales.confidence vs @emlReportAlpha (this file's own parse)",
              numf8(fld8(out_clean8, "CONF"), 1), CONFIDENCE_LEVEL, tol = 1e-12)

        # SC field order: 1 k, 2 alpha, 3 ciLow, 4 ciHigh, 5 n, 6 nExcluded,
        # 7 length(alphaError$), 8 scoredN, 9 scoredNone, 10 scoreMean,
        # 11 scoreSD, 12 scoreMin, 13 scoreMax, 14 isKR20.
        # IT field order (after scale, item): 1 alphaIfDeleted, 2 itemRest,
        # 3 itemTotal, 4 itemFlag.
        for (sname in decl_scales$scale) {
            sc <- sc_line8(out_clean8, sname)
            check_true("v130", sprintf("[Stage 2, %s] the live probe printed an SC line", sname),
                       length(sc) >= 14)
            if (length(sc) < 14) next

            check("v130", sprintf("[Stage 2, %s] LIVE alpha vs committed oracle", sname),
                  numf8(sc, 2), oget(sprintf("declared_%s_alpha", sname)),
                  tol = otolf(sprintf("declared_%s_alpha", sname)))
            check("v130", sprintf("[Stage 2, %s] LIVE Feldt lower vs committed oracle", sname),
                  numf8(sc, 3), oget(sprintf("declared_%s_feldt_lo", sname)),
                  tol = otolf(sprintf("declared_%s_feldt_lo", sname), 1e-8))
            check("v130", sprintf("[Stage 2, %s] LIVE Feldt upper vs committed oracle", sname),
                  numf8(sc, 4), oget(sprintf("declared_%s_feldt_hi", sname)),
                  tol = otolf(sprintf("declared_%s_feldt_hi", sname), 1e-8))
            check("v130", sprintf("[Stage 2, %s] LIVE n vs committed oracle", sname),
                  numf8(sc, 5), oget(sprintf("declared_%s_n", sname)), tol = 0)
            check("v130", sprintf("[Stage 2, %s] LIVE nExcluded vs committed oracle", sname),
                  numf8(sc, 6), oget(sprintf("declared_%s_nExcluded", sname)), tol = 0)
            check_true("v130", sprintf("[Stage 2, %s] LIVE alphaError$ empty (kernel did not refuse)", sname),
                       numf8(sc, 7) == 0)
            check("v130", sprintf("[Stage 2, %s] LIVE scoredN vs committed oracle", sname),
                  numf8(sc, 8), oget(sprintf("declared_%s_scoredN", sname)), tol = 0)
            check("v130", sprintf("[Stage 2, %s] LIVE scoredNone vs committed oracle", sname),
                  numf8(sc, 9), oget(sprintf("declared_%s_scoredNone", sname)), tol = 0)
            check("v130", sprintf("[Stage 2, %s] LIVE scale-score mean vs committed oracle", sname),
                  numf8(sc, 10), oget(sprintf("declared_%s_scoreMean", sname)),
                  tol = otolf(sprintf("declared_%s_scoreMean", sname)))
            check("v130", sprintf("[Stage 2, %s] LIVE scale-score sd vs committed oracle", sname),
                  numf8(sc, 11), oget(sprintf("declared_%s_scoreSD", sname)),
                  tol = otolf(sprintf("declared_%s_scoreSD", sname)))
            check("v130", sprintf("[Stage 2, %s] LIVE scale-score min vs committed oracle", sname),
                  numf8(sc, 12), oget(sprintf("declared_%s_scoreMin", sname)),
                  tol = otolf(sprintf("declared_%s_scoreMin", sname)))
            check("v130", sprintf("[Stage 2, %s] LIVE scale-score max vs committed oracle", sname),
                  numf8(sc, 13), oget(sprintf("declared_%s_scoreMax", sname)),
                  tol = otolf(sprintf("declared_%s_scoreMax", sname)))

            expectKR20 <- if (sname == "Knowledge") 1 else 0
            check("v130", sprintf("[Stage 2, %s] LIVE isKR20 (carried, not recomputed) vs the declared range's own span", sname),
                  numf8(sc, 14), expectKR20, tol = 0)

            ritems <- subscale_rows(sname)
            for (cn in ritems$item) {
                it <- it_line8(out_clean8, sname, cn)
                check_true("v130", sprintf("[Stage 2, %s] LIVE probe printed an IT line for item %s", sname, cn),
                           length(it) >= 4)
                if (length(it) < 4) next
                if (nrow(ritems) >= 3) {
                    check("v130", sprintf("[Stage 2, %s] LIVE alpha-if-deleted, item %s vs committed oracle", sname, cn),
                          numf8(it, 1), oget(sprintf("declared_%s_drop_%s", sname, cn)),
                          tol = otolf(sprintf("declared_%s_drop_%s", sname, cn)))
                }
                check("v130", sprintf("[Stage 2, %s] LIVE item-rest, item %s vs committed oracle", sname, cn),
                      numf8(it, 2), oget(sprintf("declared_%s_itemrest_%s", sname, cn)),
                      tol = otolf(sprintf("declared_%s_itemrest_%s", sname, cn)))
                check("v130", sprintf("[Stage 2, %s] LIVE item-total, item %s vs committed oracle", sname, cn),
                      numf8(it, 3), oget(sprintf("declared_%s_itemtotal_%s", sname, cn)),
                      tol = otolf(sprintf("declared_%s_itemtotal_%s", sname, cn)))
                check_true("v130", sprintf("[Stage 2, %s] LIVE misdeclared-reversal flag, item %s (item-rest strictly below zero)", sname, cn),
                           numf8(it, 4) == as.numeric(oget(sprintf("declared_%s_itemrest_%s", sname, cn)) < 0))
            }
        }
    }

    # -------------------------------------------------------------------
    # 9. NEGATIVE CONTROLS, v90-mutant style -- one seeded source defect
    #    per quantity named in the task, each isolating ONE wiring line in
    #    @eml_reverseScoreMatrix / @emlSurveyScoreScales (never re-testing
    #    @emlCronbachAlpha / @emlAlphaInfluence's OWN arithmetic, which is
    #    v90/v93's job, not this section's). DRIVEN FROM A TABLE, not eight
    #    hand-written blocks (CLAUDE.md: "Where a structure repeats, drive
    #    it from an indexed array"): every mutant shares one runner that
    #    substitutes ONE needle for ONE replacement in a scratch copy of
    #    eml-psychometrics.praat, drives it on the committed declaration,
    #    and compares ONE named field against the correct value the clean
    #    drive above already fetched (Confidence, chosen throughout only
    #    because every quantity below is non-trivial on it: k = 4, no zero
    #    item-rest, alpha != feldt bounds != item-rest != item-total).
    # -------------------------------------------------------------------
    src8 <- readLines(file.path(statsdir8, "eml-psychometrics.praat"))
    conf_sc8 <- if (ran_clean8) sc_line8(out_clean8, "Confidence") else character(0)
    conf_it_q18 <- if (ran_clean8) it_line8(out_clean8, "Confidence", "Q1") else character(0)

    mutants8 <- list(
        list(id = "sign",
             what = "reversal sign flipped (a reversed item is scored as forward) -- covers alpha, Feldt bounds, and alpha-if-deleted, which all move together because they are pure functions of the covariance matrix and the sign is the one thing about the transform they can see",
             needle = ".sign# [.j] = -1", repl = ".sign# [.j] = 1",
             correct = function() numf8(conf_sc8, 2), field = function(o) numf8(sc_line8(o, "Confidence"), 2),
             tol = 1e-10),
        list(id = "feldt_swap",
             what = "Feldt lower/upper bounds swapped at the passthrough -- covers the Feldt bounds specifically (distinct from alpha moving, which the sign mutant above already covers)",
             needle = ".subCiLow[.s] = emlCronbachAlpha.ciLow\n            .subCiHigh[.s] = emlCronbachAlpha.ciHigh",
             repl = ".subCiLow[.s] = emlCronbachAlpha.ciHigh\n            .subCiHigh[.s] = emlCronbachAlpha.ciLow",
             correct = function() numf8(conf_sc8, 3), field = function(o) numf8(sc_line8(o, "Confidence"), 3),
             tol = 1e-10),
        list(id = "drop_index",
             what = "alpha-if-deleted always reads the LAST item's slot instead of the item's own -- covers alpha-if-deleted specifically",
             needle = ".subAlphaIfDeleted[.s,.j] = emlCronbachAlpha.alphaIfDeleted# [.j]",
             repl = ".subAlphaIfDeleted[.s,.j] = emlCronbachAlpha.alphaIfDeleted# [.k]",
             correct = function() numf8(conf_it_q18, 1), field = function(o) numf8(it_line8(o, "Confidence", "Q1"), 1),
             tol = 1e-10),
        list(id = "n_field",
             what = "n reads the wrong kernel field (item count k, not complete-case n) -- covers n specifically",
             needle = ".subN[.s] = emlCronbachAlpha.n", repl = ".subN[.s] = emlCronbachAlpha.k",
             correct = function() numf8(conf_sc8, 5), field = function(o) numf8(sc_line8(o, "Confidence"), 5),
             tol = 0),
        list(id = "nexcluded_swap",
             what = "nExcluded reads @emlCronbachAlpha.n (the complete-case count) instead of its own .nExcluded field -- covers nExcluded specifically, distinct from the n_field mutant above (which targets .subN[], reading .k instead of .n)",
             needle = ".subNExcluded[.s] = emlCronbachAlpha.nExcluded",
             repl = ".subNExcluded[.s] = emlCronbachAlpha.n",
             correct = function() numf8(conf_sc8, 6), field = function(o) numf8(sc_line8(o, "Confidence"), 6),
             tol = 0),
        list(id = "itemrest_reads_total",
             what = "item-rest is computed against the FULL total (including itself) instead of against the rest -- covers item-rest specifically, leaving item-total (computed by the very next, untouched line) at its own correct value",
             needle = "@emlPearsonCorrelation: .colJ#, .rest#, 2",
             repl = "@emlPearsonCorrelation: .colJ#, .total#, 2",
             correct = function() numf8(conf_it_q18, 2), field = function(o) numf8(it_line8(o, "Confidence", "Q1"), 2),
             tol = 1e-10),
        list(id = "scoremean_sum",
             what = "the scale score is the SUM of the subscale's items, not the mean -- covers the scale-score summaries (mean/sd/min/max all move by the same factor of k); the task's own stated reason for using the mean (\"so scores compare across subscales of different lengths\") is exactly what this defect breaks",
             needle = ".scores# = .total# * (1 / .k)", repl = ".scores# = .total#",
             correct = function() numf8(conf_sc8, 10), field = function(o) numf8(sc_line8(o, "Confidence"), 10),
             tol = 1e-6),
        list(id = "kr20_recompute",
             what = "isKR20 is recomputed inline (with a deliberately wrong condition, max < min) instead of carried from @emlSurveyValidateDeclaration.scaleIsKR20[] -- covers the \"carry it, do not recompute it\" ruling directly: Knowledge (the one declared subscale that IS KR-20) is checked, expecting the wrong condition to report 0 where the carried value reports 1",
             needle = ".subIsKR20[.s] = emlSurveyValidateDeclaration.scaleIsKR20[.s]",
             repl = ".subIsKR20[.s] = (emlSurveyValidateDeclaration.scaleMax[.s] < emlSurveyValidateDeclaration.scaleMin[.s])",
             correct = function() 1, field = function(o) numf8(sc_line8(o, "Knowledge"), 14),
             tol = 0)
    )

    for (mu in mutants8) {
        hits8 <- sum(grepl(mu$needle, src8, fixed = TRUE))
        # The Feldt-swap needle spans two lines; grepl per-line never
        # matches it, so that one mutant is located and substituted on the
        # PASTED whole-file text instead of line-by-line, and its own
        # occurrence count is taken on that same pasted text.
        if (grepl("\n", mu$needle, fixed = TRUE)) {
            whole8 <- paste(src8, collapse = "\n")
            hits8 <- lengths(regmatches(whole8, gregexpr(mu$needle, whole8, fixed = TRUE)))
        }
        check_true("v130", sprintf("[Stage 2 mutant %s] the negative-control seed site exists exactly once in source", mu$id),
                   hits8 == 1)
        if (hits8 != 1) next

        if (grepl("\n", mu$needle, fixed = TRUE)) {
            mut_text8 <- sub(mu$needle, mu$repl, paste(src8, collapse = "\n"), fixed = TRUE)
            mut_src8 <- strsplit(mut_text8, "\n", fixed = TRUE)[[1]]
        } else {
            mut_src8 <- sub(mu$needle, mu$repl, src8, fixed = TRUE)
        }

        mut_dir8 <- file.path(work8, paste0("mutant_", mu$id))
        link_stats8(mut_dir8, psych_text = mut_src8)
        out_mut8 <- drive_score8(paste0("mutant_", mu$id), paste0("mutant-", mu$id))
        mut_ran8 <- !any(grepl("^Error", out_mut8)) && length(fld8(out_mut8, "refusal")) >= 1
        check_true("v130", sprintf("[Stage 2 mutant %s] the mutant probe ran", mu$id), mut_ran8)
        if (!mut_ran8) next

        mut_val8 <- mu$field(out_mut8)
        correct_val8 <- mu$correct()

        if (red_mode) {
            cat(sprintf("      EML_LANE_RED: driving mutant '%s' (%s) -- the next\n      check is EXPECTED to FAIL.\n",
                        mu$id, mu$what))
            check("v130", sprintf("[RED] mutant %s vs the correct live value (must go red)", mu$id),
                  mut_val8, correct_val8, tol = mu$tol)
        } else {
            check("v130",
                  sprintf("seeded defect '%s' DIFFERS from the correct live value (%s)", mu$id, mu$what),
                  mut_val8, correct_val8, tol = mu$tol, expect = "differ")
        }
    }
}

if (!exists("EML_SUITE")) {
    eml_report("v130 declared-survey oracle")

    # -------------------------------------------------------------------
    # Stage 3 ruling, item 6: v130 carries 8 opportunistic `psych`-package
    # legs (2 per subscale x 4 subscales), each guarded by
    # requireNamespace and run only inside `if (havePsych)`, so this
    # file's own total differs across machines with and without `psych`
    # installed. Print the split so the total explains itself. Both
    # counts are DERIVED from this file's own recorded rows -- never
    # hardcoded.
    #
    # THIS IS A TEXT-MATCH PROXY FOR THE GUARD, NOT A READ OF THE GUARD
    # ITSELF, and that is a real gap, not fixed here. What decides "psych
    # or core" below is `grepl("psych", quantity)` against each row's own
    # recorded message -- today that is true of exactly the two check()
    # calls inside `if (havePsych)` above (both messages literally say
    # "psych::alpha" / "psych r.drop"), and true of nothing else this file
    # records, so the split happens to come out right. Nothing enforces
    # that correspondence: a future check message that happens to mention
    # "psych" while sitting OUTSIDE the guard would be counted as
    # opportunistic when it always runs, and a future guarded check whose
    # message does not happen to say "psych" would be counted as core when
    # it does not always run -- either way the printed split would
    # silently misreport itself, with nothing here to notice. A read of
    # the guard itself (e.g. parsing which check() calls sit inside the
    # `if (havePsych)  { ... }` block in source, the way v105/Finding 2's
    # parity checks parse their own procedure bodies rather than trust a
    # proxy) would close this; that has not been built.
    # -------------------------------------------------------------------
    v130_split_df <- do.call(rbind, EML_RESULTS$rows)
    if (!is.null(v130_split_df)) {
        v130_split_rows <- v130_split_df[v130_split_df$id == "v130" &
                                         v130_split_df$expect != "attested", , drop = FALSE]
        v130_is_psych <- grepl("psych", v130_split_rows$quantity, fixed = TRUE)
        v130_psych_checks <- sum(v130_is_psych)
        v130_core_checks <- sum(!v130_is_psych)
        v130_total_checks <- nrow(v130_split_rows)
        cat(sprintf(
            "%d checks = %d core + %d opportunistic psych cross-check%s (psych package %s)\n",
            v130_total_checks, v130_core_checks, v130_psych_checks,
            if (v130_psych_checks == 1) "" else "s",
            if (havePsych) "installed, so these ran" else "NOT installed, so these did not run"))
    }

    eml_exit()
}
