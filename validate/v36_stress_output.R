# ============================================================================
# v36_stress_output.R -- the twenty-nine stress cases that were rendered and
#                        never judged.
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# §17. harness/stress_graphs.sh renders 39 figures.
# validate/v27_empty_frames.R asserts on ten of them -- the `empty_*` cases,
# because that file is about D111 and empty frames. Nothing asserted on the
# other 29. What "29 OK" meant was the DRIVER's verdict: praat exited without
# printing an error, a non-empty PNG appeared, and ImageMagick measured two
# numbers off it. That is a smoke test, and §7 of the tracker is explicit that
# it is not validation -- nothing counts as validated until an authored R
# script tests the output.
#
# The 29 are the cases named after the pathologies. violin_zerovar,
# violin_n1, violin_spanzero, violin_undefined, violin_hugevalues,
# violin_tinyvalues, hist_1bin, hist_200bins, ts_duplicate_times,
# violin_outlier, bar_customerr, legend_cap. Every one of them was rendered
# for five months and the only thing anyone knew about the result was that it
# did not crash.
#
#     bash harness/stress_graphs.sh       regenerate the inputs to this script
#     Rscript validate/v36_stress_output.R
#
# Input:  <stress>/RESULTS.tsv      case, verdict, ink %, chromatic px, first
#         <stress>/<case>.png       the rendered figure
#         <stress>/<case>.log       the Info-window transcript
#         harness/stress_cases/<case>.praat   read here, statically
#
#   <stress> is $EML_STRESS_DIR, default harness/stress_out, exactly as v27
#   reads it. A missing artefact is a HARD STOP, not a skip: "the driver never
#   ran this" is precisely the failure a silently shrinking suite would hide.
#
# WHY THIS FILE COULD NOT BE WRITTEN BEFORE 12 AUGUST 2026
# -------------------------------------------------------
# §14. Twenty-two of the 39 cases called `randomGauss` with no seed, so their
# ink and chroma were a different number every run --
#
#     violin_baseline    OK   11.348%   230063
#     violin_baseline    OK   14.106%   289575
#
# -- two consecutive runs, no code change between them. An R script cannot pin
# a value that is a different number each time. That is why v27 was written as
# INEQUALITIES and never as values, and why the other 29 were left alone. §14
# was not tidiness; it was the blocker on this file. The 22 now carry an
# in-script LCG with a per-case seed, the figures are byte-reproducible (§16,
# 10/10 STABLE), and RESULTS.tsv finally is what it always looked like: a
# baseline. Section 8 pins the precondition itself, so if an unseeded draw
# comes back the failure lands here rather than as an unexplained drift in
# thirty-nine pinned numbers.
#
# HOW THIS COMPLEMENTS v27, WHICH READS THE SAME ARTEFACT
# ------------------------------------------------------
# v27 owns the ten `empty_*` cases and owns them deeply: the exact disclosure
# wording per procedure, the static ban on `goto` in the draw library, the
# per-procedure Axes: call, and the empty-versus-populated-sibling inequality.
# None of that is repeated here.
#
# What this file adds over all 39, including v27's ten, is the two things v27
# deliberately does not do: it pins the MEASUREMENTS, which only became
# pinnable after §14, and it declares the POPULATION through eml_census, so
# the artefact cannot grow or shrink without something failing. The ten are
# not re-examined structurally -- their PNG, log, error scan and SAVED line
# are v27's job and it does them. Sections 4, 6 and 8 are where the ten
# appear, and the census records them as accounted for there.
#
# WHY THE PINS CARRY A TOLERANCE AND WHAT THE TOLERANCE IS
# --------------------------------------------------------
# A pin to six decimal places would be a pin on this machine's freetype build
# and this machine's ImageMagick, and the first reviewer to run the suite
# elsewhere would get 78 red lines that mean nothing. Chromatic pixels are
# pinned to +/-5% RELATIVE, which is the driver's own number: stress_graphs.sh
# clears antialiasing jitter with a 5% margin when it decides whether a figure
# is blank, and a validator reading its output has no business being fussier
# than the instrument. 5% is also comfortably wider than the 6 significant
# figures ImageMagick prints above a million (hist_1bin arrives as
# "1.09312e+06") and comfortably narrower than every gap this file cares
# about: the tightest is violin_n1 at 15% above empty_violin.
#
# Ink is pinned to whichever is larger of 5% relative and 0.10 PERCENTAGE
# POINTS. The floor is there because ink on a nearly-empty frame is mostly
# glyph coverage -- the ten empty frames span 0.879% to 1.011% purely on how
# many tick numbers their axis prints -- so a font-metric change moves the
# small values by more than 5% while changing nothing about what was drawn.
# Ink is the corroborating measure here and chroma is the discriminating one,
# for the reason v27 gives at length: the retired ink < 2% rule condemned
# violin_zerovar and violin_n1, both of which are CORRECT figures.
#
# WHAT IS ASSERTED FROM THE LOG, AND WHAT IS DERIVED RATHER THAN TRANSCRIBED
# -------------------------------------------------------------------------
# Several cases publish a COUNT on the Info channel -- rows skipped, repeated
# observations averaged, bins, groups, time points. Where that count follows
# from literals in the case file it is COMPUTED here from those literals and
# compared, rather than copied out of the log. violin_undefined blanks every
# fourth cell of 24 rows, so 6 is arithmetic, not a transcription; if someone
# changes the fixture to 32 rows this file recomputes 8 and keeps testing the
# plugin instead of testing a stale constant.
#
# What is NOT recomputed is anything downstream of the LCG. The generator is
# `(1103515245 * s + 12345) mod 2147483648` on Praat doubles, and an R-side
# copy of it would be a second implementation at the edge of double precision.
# v33 makes the general argument: a drifted copy agreeing with neither reader
# looks like a failure of the plugin. So the spaghetti summary's means are
# checked against the FIXTURE'S DESIGN -- 20 + 4c + 3s + noise, with the
# coefficient read out of the case file -- and never against a replayed draw.
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

stress_dir <- Sys.getenv("EML_STRESS_DIR", unset = repo_path("harness", "stress_out"))
out_dir    <- stress_dir
res_p      <- file.path(stress_dir, "RESULTS.tsv")
cases_dir  <- repo_path("harness", "stress_cases")

if (!file.exists(res_p))
    stop("stress artefact not found: ", res_p,
         "\n  Run: bash harness/stress_graphs.sh")
if (!dir.exists(cases_dir))
    stop("stress cases not found: ", cases_dir)

res <- read.delim(res_p, header = FALSE, stringsAsFactors = FALSE,
                  col.names = c("case", "verdict", "ink", "chrom", "first"))
res$ink   <- suppressWarnings(as.numeric(sub("%$", "", res$ink)))
res$chrom <- suppressWarnings(as.numeric(res$chrom))
# read.delim types the trailing field as logical NA when the driver recorded
# no error on any case, which is the healthy state. Force it to character so
# section 3 compares strings either way.
res$first <- as.character(res$first)

# ---------------------------------------------------------------------------
# Small readers, all base R.
# ---------------------------------------------------------------------------

# png_size -- width and height out of the IHDR, or NULL if the file is not a
# PNG. The driver's own test is `[ -s file ]`, and v27's is size > 0; neither
# distinguishes a figure from eight bytes of garbage with a .png on the end,
# and neither can see the canvas growing. Both matter here: @emlAssertFullViewport
# saves the DRAWN EXTENT, so a label that escapes the panel does not get
# clipped, it makes the image taller -- which is the only evidence
# violin_longlabels leaves anywhere.
png_size <- function(p) {
    if (!file.exists(p) || file.info(p)$size < 24) return(NULL)
    con <- file(p, "rb"); on.exit(close(con))
    if (!identical(readBin(con, "raw", 8L),
                   as.raw(c(0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a))))
        return(NULL)
    hdr <- readBin(con, "raw", 8L)
    if (!identical(rawToChar(hdr[5:8]), "IHDR")) return(NULL)
    c(readBin(con, "integer", 1L, 4L, endian = "big"),
      readBin(con, "integer", 1L, 4L, endian = "big"))
}

log_of  <- function(cs) {
    p <- file.path(out_dir, paste0(cs, ".log"))
    if (file.exists(p)) readLines(p, warn = FALSE) else character(0)
}
src_of  <- function(cs) {
    p <- file.path(cases_dir, paste0(cs, ".praat"))
    if (file.exists(p)) readLines(p, warn = FALSE) else character(0)
}
says    <- function(lg, s) any(trimws(lg) == s)
row_of  <- function(cs) res[match(cs, res$case), ]
chrom_of <- function(cs) { r <- row_of(cs); if (nrow(r)) r$chrom else NA_real_ }
ink_of   <- function(cs) { r <- row_of(cs); if (nrow(r)) r$ink   else NA_real_ }

# Arguments of a one-line `@proc: a, b, c` call in a case file. No stress case
# splits a draw call across continuation lines, and none of the arguments
# contains a comma; both are checked before anything is read out of the split.
draw_args <- function(src, proc) {
    ln <- grep(sprintf("^@%s:", proc), src, value = TRUE)
    if (length(ln) != 1L) return(character(0))
    trimws(strsplit(sub(sprintf("^@%s:", proc), "", ln), ",", fixed = TRUE)[[1]])
}
# Row count of the `Create Table with column names: "x", N, "cols"` the case
# builds. The pathology of a stress case is usually a property of N.
table_rows <- function(src) {
    ln <- grep("Create Table with column names:", src, value = TRUE)
    if (length(ln) != 1L) return(NA_integer_)
    m <- regmatches(ln, regexpr("[0-9]+[[:space:]]*,", ln))
    if (!length(m)) return(NA_integer_)
    as.integer(sub("[^0-9]", "", m))
}
# The `Set numeric value:` / `Set string value:` lines only. NOT the whole
# file: every draw call in these cases passes the column NAME as a quoted
# argument too, so a naive search for `"val", <number>` also finds
# `@emlDrawViolinPlot: ... "grp", "val", 0, 0` and reads the trailing 0 as a
# datum. That cost two false failures on the first run of this script.
set_lines <- function(src, kind) grep(sprintf("^ *Set %s value:", kind), src, value = TRUE)

# The key/value rows of an EML summary block: a label, two or more spaces,
# a value. Ruled lines and the timestamp split to one field and drop out.
kv <- function(lg) {
    p <- strsplit(trimws(lg), "[[:space:]]{2,}")
    p <- p[vapply(p, length, 1L) == 2L]
    if (!length(p)) return(data.frame(k = character(0), v = character(0),
                                      stringsAsFactors = FALSE))
    data.frame(k = vapply(p, `[`, "", 1L), v = vapply(p, `[`, "", 2L),
               stringsAsFactors = FALSE)
}

# ---------------------------------------------------------------------------
# 1. THE POPULATION IS DECLARED, NOT WHATEVER TURNED UP
#
# The 39 by name, in two lists that mean different things. THE_TEN is v27's
# territory and appears here only in the census, the verdict grammar and the
# pins. THE_29 is what this file was written for. They are separate lists
# because the verdict rule below differs between them and because a case
# moving from one list to the other should be a deliberate edit.
# ---------------------------------------------------------------------------
THE_TEN <- c("empty_bar", "empty_box", "empty_gbox", "empty_gviolin",
             "empty_hist", "empty_scatter", "empty_spaghetti", "empty_ts",
             "empty_tsci", "empty_violin")

THE_29 <- c("bar_baseline", "bar_customerr", "bar_sd", "box_baseline",
            "gbox_baseline", "gviolin_baseline", "hist_1bin", "hist_200bins",
            "hist_baseline", "legend_cap", "scatter_baseline",
            "scatter_grouped", "spaghetti_baseline", "spaghetti_grouped",
            "ts_baseline", "ts_duplicate_times", "tsci_baseline",
            "violin_12groups", "violin_baseline", "violin_bw",
            "violin_hugevalues", "violin_longlabels", "violin_n1",
            "violin_onegroup", "violin_outlier", "violin_spanzero",
            "violin_tinyvalues", "violin_undefined", "violin_zerovar")

ALL_39 <- c(THE_TEN, THE_29)

eml_census("v36", "stress case", res$case, ALL_39)
check("v36", "the driver rendered 39 cases", nrow(res), 39, tol = 0)
check("v36", "no case appears twice in RESULTS.tsv",
      sum(duplicated(res$case)), 0, tol = 0)
check("v36", "ten empty cases declared", length(THE_TEN), 10, tol = 0)
check("v36", "twenty-nine populated cases declared", length(THE_29), 29, tol = 0)
check_true("v36", "the two declared lists do not overlap",
           length(intersect(THE_TEN, THE_29)) == 0L)

# ---------------------------------------------------------------------------
# 2. The artefact is the shape every check below reads
# ---------------------------------------------------------------------------
check_true("v36", "RESULTS.tsv has the five expected fields",
           identical(names(res), c("case", "verdict", "ink", "chrom", "first")))
check("v36", "every case reports a numeric ink fraction",
      sum(is.finite(res$ink)), 39, tol = 0)
check("v36", "every case reports a numeric chromatic pixel count",
      sum(is.finite(res$chrom)), 39, tol = 0)
check_true("v36", "no ink fraction is negative or above 100%",
           all(is.finite(res$ink) & res$ink >= 0 & res$ink <= 100))

# ---------------------------------------------------------------------------
# 3. THE VERDICT GRAMMAR
#
# stress_graphs.sh can write six verdicts. Three of them (NO_FIGURE,
# DREW_THEN_FAILED, REFUSED) mean the case did not produce a figure it stands
# behind. BLANK_FRAME means a populated case drew no more colour than its own
# empty sibling, which for any of the 29 is the pre-D111 failure.
#
# So the grammar is exact and it is different for the two lists: an `empty_*`
# case MUST read BLANK_FRAME_ABS -- it has no chrome-only baseline of its own
# so it falls through to the absolute ink rule and trips it by design -- and
# every one of the 29 MUST read OK. v27 accepts either verdict for its ten,
# which is right for a file that is about the empty frame and wrong as the
# only statement anyone makes about the artefact.
#
# The fifth field is the driver's transcription of the first error, refusal or
# "not completed" line it found. It has to be empty on all 39, and it is
# checked here as well as in the log scan below because the two are produced
# by different greps and a disagreement between them means the driver lied
# about one of them.
# ---------------------------------------------------------------------------
check_true("v36", "every verdict is one of the two legal values here",
           all(res$verdict %in% c("OK", "BLANK_FRAME_ABS")))
check_true("v36", "every empty_* case is BLANK_FRAME_ABS",
           all(res$verdict[match(THE_TEN, res$case)] == "BLANK_FRAME_ABS"))
check_true("v36", "every populated case is OK",
           all(res$verdict[match(THE_29, res$case)] == "OK"))
check_true("v36", "no case recorded a first error line",
           all(is.na(res$first) | !nzchar(trimws(res$first))))

# ---------------------------------------------------------------------------
# 4. THE MEASUREMENTS, PINNED
#
# Measured 12 August 2026 from harness/stress_out/RESULTS.tsv, after §14
# seeded the twenty-two. Read out of the artefact, never estimated. Tolerance
# and its justification are in the header block.
#
# All 39, v27's ten included, because pinning a value is exactly the thing
# v27 declines to do and this is where the artefact stops being a smoke test.
# ---------------------------------------------------------------------------
PIN <- rbind(
  data.frame(case = "empty_bar",          ink =  0.893, chrom =    4609),
  data.frame(case = "empty_box",          ink =  0.893, chrom =    4609),
  data.frame(case = "empty_gbox",         ink =  0.893, chrom =    4609),
  data.frame(case = "empty_gviolin",      ink =  0.893, chrom =    4609),
  data.frame(case = "empty_hist",         ink =  0.879, chrom =    5386),
  data.frame(case = "empty_scatter",      ink =  0.879, chrom =    5305),
  data.frame(case = "empty_spaghetti",    ink =  0.895, chrom =    4724),
  data.frame(case = "empty_ts",           ink =  1.011, chrom =    6969),
  data.frame(case = "empty_tsci",         ink =  1.011, chrom =    6969),
  data.frame(case = "empty_violin",       ink =  0.893, chrom =    4609),
  data.frame(case = "bar_baseline",       ink = 25.261, chrom =  531032),
  data.frame(case = "bar_customerr",      ink = 25.572, chrom =  536981),
  data.frame(case = "bar_sd",             ink = 25.255, chrom =  530311),
  data.frame(case = "box_baseline",       ink =  7.130, chrom =  137484),
  data.frame(case = "gbox_baseline",      ink =  4.540, chrom =   82213),
  data.frame(case = "gviolin_baseline",   ink =  9.569, chrom =  190600),
  data.frame(case = "hist_1bin",          ink = 51.370, chrom = 1093120),
  data.frame(case = "hist_200bins",       ink =  5.076, chrom =   89792),
  data.frame(case = "hist_baseline",      ink = 21.260, chrom =  442634),
  data.frame(case = "legend_cap",         ink = 14.618, chrom =  276849),
  data.frame(case = "scatter_baseline",   ink =  2.150, chrom =   31453),
  data.frame(case = "scatter_grouped",    ink =  2.529, chrom =   37897),
  data.frame(case = "spaghetti_baseline", ink =  2.874, chrom =   42419),
  data.frame(case = "spaghetti_grouped",  ink =  3.521, chrom =   54857),
  data.frame(case = "ts_baseline",        ink =  1.408, chrom =   13292),
  data.frame(case = "ts_duplicate_times", ink =  1.493, chrom =   13672),
  data.frame(case = "tsci_baseline",      ink = 32.203, chrom =  677068),
  data.frame(case = "violin_12groups",    ink =  8.974, chrom =  128315),
  data.frame(case = "violin_baseline",    ink = 12.248, chrom =  249669),
  data.frame(case = "violin_bw",          ink = 10.197, chrom =    6130),
  data.frame(case = "violin_hugevalues",  ink = 13.783, chrom =  281560),
  data.frame(case = "violin_longlabels",  ink =  7.797, chrom =  178701),
  data.frame(case = "violin_n1",          ink =  0.905, chrom =    5318),
  data.frame(case = "violin_onegroup",    ink = 22.131, chrom =  464411),
  data.frame(case = "violin_outlier",     ink =  5.647, chrom =  104359),
  data.frame(case = "violin_spanzero",    ink = 12.423, chrom =  252799),
  data.frame(case = "violin_tinyvalues",  ink = 13.778, chrom =  281348),
  data.frame(case = "violin_undefined",   ink = 14.622, chrom =  300397),
  data.frame(case = "violin_zerovar",     ink =  0.995, chrom =    6046),
  stringsAsFactors = FALSE)

# The pin table is itself a declared population. A case dropped from here
# would silently stop being pinned while the census above still passed,
# because the census asks about THE_TEN and THE_29, not about this table.
eml_census("v36", "pinned case", ALL_39, PIN$case)

for (i in seq_len(nrow(PIN))) {
    cs <- PIN$case[i]
    check("v36", sprintf("%s -- chromatic px against baseline", cs),
          reported = chrom_of(cs), computed = PIN$chrom[i],
          tol = 0.05 * PIN$chrom[i])
    check("v36", sprintf("%s -- ink %% against baseline", cs),
          reported = ink_of(cs), computed = PIN$ink[i],
          tol = max(0.10, 0.05 * PIN$ink[i]))
}

# ---------------------------------------------------------------------------
# 5. STRUCTURAL EVIDENCE, THE 29
#
# v27 does the equivalent sweep over its ten; it is not repeated for them.
#
# The canvas is 1800 x 1200 for every case but one: 6 x 4 inches at 300 dpi,
# saved through @emlAssertFullViewport, which covers the DRAWN EXTENT rather
# than a fixed rectangle. violin_longlabels is the exception at 1800 x 1410
# and section 7 is where that is judged rather than merely tolerated.
# ---------------------------------------------------------------------------
TALLER <- c(violin_longlabels = 1410L)

for (cs in THE_29) {
    png_p <- file.path(out_dir, paste0(cs, ".png"))
    dim_p <- png_size(png_p)

    check_true("v36", sprintf("%s -- figure is a readable PNG", cs),
               !is.null(dim_p))
    if (!is.null(dim_p)) {
        exp_h <- if (cs %in% names(TALLER)) TALLER[[cs]] else 1200L
        check("v36", sprintf("%s -- canvas width px", cs),
              reported = dim_p[1], computed = 1800, tol = 0)
        check("v36", sprintf("%s -- canvas height px", cs),
              reported = dim_p[2], computed = exp_h, tol = 0)
    }

    lg <- log_of(cs)
    if (!check_true("v36", sprintf("%s -- transcript written", cs),
                    length(lg) > 0L)) next

    check_true("v36", sprintf("%s -- no Praat error in the transcript", cs),
               !any(grepl("^Error|not completed|Unknown variable", lg)))
    # Exactly one save, and it names THIS case. v27 checks that a SAVED line
    # exists; it does not check which file it names. A case wired to another
    # case's EML_OUT would leave both figures looking fine and one of them
    # would be a picture of the wrong data.
    saved <- grep("^SAVED ", lg, value = TRUE)
    check("v36", sprintf("%s -- saved exactly one figure", cs),
          length(saved), 1, tol = 0)
    check_true("v36", sprintf("%s -- the SAVED line names this case", cs),
               length(saved) == 1L &&
               identical(basename(trimws(sub("^SAVED ", "", saved))),
                         paste0(cs, ".png")))

    # The case file that produced it still exists and still draws. A stress
    # case deleted while its PNG stayed on disk would pass everything above.
    src <- src_of(cs)
    check_true("v36", sprintf("%s -- case file present and non-empty", cs),
               length(src) > 0L)
    check_true("v36", sprintf("%s -- case calls a draw procedure", cs),
               any(grepl("^@eml(Draw|SetColorPalette)", src)))
}

# ---------------------------------------------------------------------------
# 6. THE DRIVER'S BLANK-FRAME RULE, RECOMPUTED
#
# stress_graphs.sh decides "did it draw data" by comparing a case's chromatic
# pixel count against its own family's empty frame with a 5% margin, then
# writes a verdict. Every check in section 3 reads that verdict. Recomputing
# the rule here from the two numbers in the same file is the guard against the
# harness grading its own homework -- the same objection §18 raises about the
# determinism driver, which is the one place in the tree where a verdict is
# still the whole of the evidence.
#
# This is NOT v27's sibling comparison. v27 stands on the empty case and
# asserts that every populated sibling scores higher, full stop. This stands
# on the populated case, applies the driver's actual 5% threshold, and
# additionally requires the verdict column to agree with the arithmetic.
# ---------------------------------------------------------------------------
for (cs in THE_29) {
    fam  <- sub("_.*$", "", cs)
    base <- paste0("empty_", fam)
    if (!base %in% res$case) next          # legend_cap has no empty sibling
    b <- chrom_of(base); c0 <- chrom_of(cs)
    over <- is.finite(b) && is.finite(c0) && b > 0 && c0 > b * 1.05
    check_true("v36", sprintf("%s -- clears its empty frame by the driver's 5%%", cs),
               over)
    check_true("v36", sprintf("%s -- verdict agrees with the recomputed rule", cs),
               identical(over, row_of(cs)$verdict == "OK"))
}
# legend_cap is the one case whose family has no empty_* baseline, so the
# driver fell back to the absolute ink rule for it. Asserted explicitly rather
# than skipped, so that gaining an empty_legend later is a visible change.
check_true("v36", "legend_cap has no empty sibling, so the absolute rule applied",
           !("empty_legend" %in% res$case) && ink_of("legend_cap") >= 2.0)

# ---------------------------------------------------------------------------
# 7. THE PATHOLOGIES, ONE AT A TIME
#
# Each block asserts (a) the fixture still contains the pathology the case is
# named for, computed from the literals in the case file, and (b) what the
# rendered evidence says about it. Where the log carries a count, the count is
# derived from the fixture and compared; where the log says nothing -- and for
# eight of these it says nothing but SAVED -- the evidence is the measurement,
# and the check says so rather than inventing a disclosure that is not there.
# ---------------------------------------------------------------------------

# --- violin_zerovar: every value identical -------------------------------
# A violin of a constant collapses to a line AT that constant. It is a correct
# figure that measures 0.995% ink, which is why stress_graphs.sh's second
# blank-frame detector -- ink < 2% -- condemned it and had to be retired. That
# retirement is pinned here as a fact about the artefact: the case still trips
# the old rule, so nobody can reinstate it and see green.
{
  src <- set_lines(src_of("violin_zerovar"), "numeric")
  vals <- regmatches(src, regexpr('"val", *[0-9.]+', src))
  vals <- suppressWarnings(as.numeric(sub('.*, *', "", vals)))
  check_true("v36", "violin_zerovar -- fixture sets one constant value",
             length(vals) >= 1L && length(unique(vals)) == 1L && is.finite(vals[1]))
  check("v36", "violin_zerovar -- fixture variance is exactly zero",
        var(c(vals, vals)), 0, tol = 0)
  check_true("v36", "violin_zerovar -- the retired ink<2% rule would still condemn it",
             ink_of("violin_zerovar") < 2.0)
  check_true("v36", "violin_zerovar -- but it is not a blank frame",
             chrom_of("violin_zerovar") > chrom_of("empty_violin") * 1.05)
  check_true("v36", "violin_zerovar -- a line draws under 5% of a full violin",
             chrom_of("violin_zerovar") < 0.05 * chrom_of("violin_baseline"))
  check_true("v36", "violin_zerovar -- the procedure said nothing, and that is the record",
             identical(trimws(log_of("violin_zerovar")[
                 !grepl("^SAVED ", trimws(log_of("violin_zerovar")))]), character(0)))
}

# --- violin_n1: one observation per group --------------------------------
# Three rows, three groups. A violin of n = 1 is a tick at the value, so this
# is the FAINTEST correct figure in the artefact and the tightest margin the
# driver's blank-frame rule has to clear: 5318 against a 4609 baseline, +15%.
# The ladder empty < n1 < zerovar << baseline is asserted as an ordering
# because it is the ordering that says these are degenerate-but-drawn rather
# than blank, and it survives a theme change that moves all four together.
{
  src <- src_of("violin_n1")
  grps <- unique(regmatches(set_lines(src, "string"),
                            regexpr('"grp", *"[^"]+"', set_lines(src, "string"))))
  check("v36", "violin_n1 -- fixture has three rows", table_rows(src), 3, tol = 0)
  check("v36", "violin_n1 -- fixture has three distinct groups",
        length(grps), 3, tol = 0)
  check_true("v36", "violin_n1 -- n = 1 per group",
             length(grps) == table_rows(src))
  check_true("v36", "violin_n1 -- ladder: empty < n1 < zerovar < baseline",
             chrom_of("empty_violin") < chrom_of("violin_n1") &&
             chrom_of("violin_n1")    < chrom_of("violin_zerovar") &&
             chrom_of("violin_zerovar") < chrom_of("violin_baseline"))
  check_true("v36", "violin_n1 -- clears the blank rule, and only just",
             chrom_of("violin_n1") > chrom_of("empty_violin") * 1.05 &&
             chrom_of("violin_n1") < chrom_of("empty_violin") * 1.30)
}

# --- violin_spanzero: the data range crosses zero -------------------------
# The fixture is (i - 15) * 1.5 over 30 rows, so it is deterministic and the
# sign change is arithmetic rather than a claim. The risk with a range that
# spans zero is an axis that collapses or a baseline drawn at the wrong place;
# what that would look like in this artefact is a figure carrying much less
# colour than an ordinary violin, so the check is against violin_baseline.
{
  src <- src_of("violin_spanzero")
  n <- table_rows(src)
  ok_expr <- any(grepl("(i - 15) * 1.5", src, fixed = TRUE))
  vals <- if (ok_expr && is.finite(n)) (seq_len(n) - 15) * 1.5 else NA_real_
  check_true("v36", "violin_spanzero -- fixture still uses the ramp expression", ok_expr)
  check("v36", "violin_spanzero -- fixture has thirty rows", n, 30, tol = 0)
  check_true("v36", "violin_spanzero -- the fixture's range genuinely spans zero",
             all(is.finite(vals)) && min(vals) < 0 && max(vals) > 0)
  check_true("v36", "violin_spanzero -- drew a full violin, not a collapsed one",
             chrom_of("violin_spanzero") > 0.5 * chrom_of("violin_baseline") &&
             chrom_of("violin_spanzero") < 2.0 * chrom_of("violin_baseline"))
}

# --- violin_undefined: one cell in four is blank --------------------------
# THE ONLY PATHOLOGY CASE THAT DISCLOSES ANYTHING. 24 rows, blanked wherever
# i mod 4 = 0, so six rows are unusable and the procedure must say six. The
# six is computed from the row count and the modulus read out of the case
# file, not copied from the log: change the fixture and this recomputes.
{
  src <- src_of("violin_undefined")
  n   <- table_rows(src)
  m   <- regmatches(src, regexpr("i +mod +[0-9]+ *= *0", src))
  k   <- if (length(m)) as.integer(gsub("[^0-9]", "", sub("= *0", "", m[1]))) else NA_integer_
  expected_skipped <- if (is.finite(n) && is.finite(k)) n %/% k else NA_integer_
  check_true("v36", "violin_undefined -- fixture still blanks a cell in every k",
             length(m) == 1L)
  check("v36", "violin_undefined -- fixture has 24 rows", n, 24, tol = 0)
  check("v36", "violin_undefined -- every fourth cell", k, 4, tol = 0)
  check("v36", "violin_undefined -- rows the fixture makes unusable",
        expected_skipped, 6, tol = 0)
  check_true("v36", "violin_undefined -- the plugin discloses the skipped count it should",
             says(log_of("violin_undefined"),
                  sprintf("Violin plot: %d row(s) skipped (missing or non-numeric value).",
                          expected_skipped)))
  check_true("v36", "violin_undefined -- and still drew a populated figure",
             chrom_of("violin_undefined") > 10 * chrom_of("empty_violin"))
}

# --- violin_hugevalues / violin_tinyvalues: the scale extremes ------------
# 1.0e12 * (1 + 0.05i) and 1.0e-9 * (1 + 0.05i): the SAME twenty points, 21
# orders of magnitude apart. If axis autoscaling is scale-invariant the two
# figures are the same picture with different tick labels, and that is exactly
# what the artefact says -- 281560 against 281348 chromatic pixels, 0.075%
# apart. This is the strongest statement in the file and it costs nothing to
# make, because the two cases are each other's control. The 0.5% band is six
# times the observed difference and still an order of magnitude tighter than
# any real change in what is drawn.
{
  hs <- src_of("violin_hugevalues"); ts <- src_of("violin_tinyvalues")
  check_true("v36", "violin_hugevalues -- fixture still sits near 1e12",
             any(grepl("1.0e12", hs, fixed = TRUE)))
  check_true("v36", "violin_tinyvalues -- fixture still sits near 1e-9",
             any(grepl("1.0e-9", ts, fixed = TRUE)))
  check_true("v36", "the two fixtures differ only in scale",
             identical(sub("1.0e12", "S", hs, fixed = TRUE)[grepl("Set numeric value", hs)],
                       sub("1.0e-9", "S", ts, fixed = TRUE)[grepl("Set numeric value", ts)]))
  rel <- abs(chrom_of("violin_hugevalues") - chrom_of("violin_tinyvalues")) /
         chrom_of("violin_hugevalues")
  check_true("v36", "1e12 and 1e-9 render the same figure (chroma within 0.5%)",
             is.finite(rel) && rel < 0.005)
  check("v36", "1e12 and 1e-9 render the same figure (ink within 0.05 pp)",
        reported = ink_of("violin_hugevalues"),
        computed = ink_of("violin_tinyvalues"), tol = 0.05)
  check_true("v36", "neither scale extreme collapsed to an empty frame",
             chrom_of("violin_hugevalues") > 10 * chrom_of("empty_violin") &&
             chrom_of("violin_tinyvalues") > 10 * chrom_of("empty_violin"))
}

# --- hist_1bin / hist_200bins / hist_baseline: the bin-count extremes -----
# The bin count is the eleventh argument of @emlDrawHistogram, so the log's
# "Histogram: N bins" is checked against what the case actually asked for
# rather than against a number typed here. 200 bins over 36 points is an abuse
# and it is meant to be: it must still draw, and it must draw hairlines.
#
# The three widths do NOT stand in the ratio of the bin counts -- 16.1703 and
# 0.0736 are 220x apart, not 200x -- because the axis range the plugin settles
# on is not identical at the three bin counts. So the assertion is the
# ORDERING and the order of magnitude, which is what "bin-count extreme"
# means, and not an arithmetic identity the artefact does not support.
{
  hist_bins <- function(cs) {
    a <- draw_args(src_of(cs), "emlDrawHistogram")
    if (length(a) < 11L) return(NA_integer_)
    suppressWarnings(as.integer(a[11]))
  }
  log_bins <- function(cs) {
    ln <- grep("^Histogram: [0-9]+ bins", trimws(log_of(cs)), value = TRUE)
    if (length(ln) != 1L) return(c(NA_real_, NA_real_))
    c(as.numeric(sub("^Histogram: ([0-9]+) bins.*$", "\\1", ln)),
      as.numeric(sub("^.*bin width = ", "", ln)))
  }
  for (cs in c("hist_1bin", "hist_200bins", "hist_baseline")) {
    asked <- hist_bins(cs); got <- log_bins(cs)
    check("v36", sprintf("%s -- the log reports the bin count the case asked for", cs),
          reported = got[1], computed = asked, tol = 0)
    check_true("v36", sprintf("%s -- the log reports a positive bin width", cs),
               is.finite(got[2]) && got[2] > 0)
    # Ungrouped, all three: the group column argument is "". §15 is the reason
    # this is worth stating -- every histogram case in the suite draws
    # ungrouped, and that is how a grouped histogram stayed broken for months.
    check_true("v36", sprintf("%s -- draws ungrouped, and the log agrees", cs),
               identical(draw_args(src_of(cs), "emlDrawHistogram")[10], '""') &&
               says(log_of(cs), "Groups: 1"))
  }
  check("v36", "hist_1bin asks for one bin",     hist_bins("hist_1bin"),   1, tol = 0)
  check("v36", "hist_200bins asks for 200 bins", hist_bins("hist_200bins"), 200, tol = 0)
  w1 <- log_bins("hist_1bin")[2]; w10 <- log_bins("hist_baseline")[2]
  w200 <- log_bins("hist_200bins")[2]
  check_true("v36", "bin width falls as the bin count rises",
             is.finite(w1) && is.finite(w10) && is.finite(w200) &&
             w1 > w10 && w10 > w200)
  check_true("v36", "one bin is more than 100x wider than one of two hundred",
             is.finite(w1) && is.finite(w200) && w1 > 100 * w200)
  # One bin is one bar across the whole panel: the most ink in the artefact.
  # 200 bins over 36 points is mostly empty panel with hairlines in it.
  check_true("v36", "hist_1bin is the most heavily inked figure in the artefact",
             ink_of("hist_1bin") == max(res$ink, na.rm = TRUE) &&
             ink_of("hist_1bin") > 40)
  check_true("v36", "hist_200bins draws hairlines, not bars",
             ink_of("hist_200bins") < 10)
  check_true("v36", "colour falls as the bin count rises",
             chrom_of("hist_1bin") > chrom_of("hist_baseline") &&
             chrom_of("hist_baseline") > chrom_of("hist_200bins"))
  check_true("v36", "hist_1bin carries more than 10x the colour of hist_200bins",
             chrom_of("hist_1bin") > 10 * chrom_of("hist_200bins"))
}

# --- ts_duplicate_times: repeated observations at one time point ----------
# Six rows, two observations at each of three times. @emlDrawTimeSeries
# averages them and must SAY it averaged them, with the count. The count is
# rows minus distinct times, computed from the six literals in the case file.
# The same derivation is applied to ts_baseline (36 rows over 3 times = 33)
# and tsci_baseline (36 rows over 2 groups x 3 times = 30), so all three
# continuous-x cases are judged by one rule rather than three transcriptions.
{
  ts_line <- function(cs, n_rep) sprintf(
    "Time series: Line shows the mean per time point. %d repeated observation(s) were averaged. Use Spaghetti Plot to show individual series, or Time Series (with CI) to show the spread around each mean.",
    n_rep)

  src <- src_of("ts_duplicate_times")
  sl  <- set_lines(src, "numeric")
  tm  <- regmatches(sl, regexpr('"time", *[0-9.]+', sl))
  tm  <- suppressWarnings(as.numeric(sub('.*, *', "", tm)))
  n   <- table_rows(src)
  check("v36", "ts_duplicate_times -- fixture has six rows", n, 6, tol = 0)
  check("v36", "ts_duplicate_times -- six time literals were written", length(tm), 6, tol = 0)
  check("v36", "ts_duplicate_times -- three distinct time points",
        length(unique(tm)), 3, tol = 0)
  rep_dup <- length(tm) - length(unique(tm))
  check("v36", "ts_duplicate_times -- repeated observations the fixture creates",
        rep_dup, 3, tol = 0)
  check_true("v36", "ts_duplicate_times -- the plugin discloses the averaging and the count",
             says(log_of("ts_duplicate_times"), ts_line("ts_duplicate_times", rep_dup)))

  # The shared repeated-measures fixture: N rows, time = (i-1) mod k + 1.
  rm_shape <- function(cs) {
    s <- src_of(cs)
    n <- table_rows(s)
    kc <- regmatches(s, regexpr("c *= *\\(i - 1\\) mod [0-9]+", s))
    ks <- regmatches(s, regexpr("s *= *\\(subj - 1\\) mod [0-9]+", s))
    c(n = n,
      times  = if (length(kc)) as.integer(sub("^.*mod ", "", kc[1])) else NA_integer_,
      groups = if (length(ks)) as.integer(sub("^.*mod ", "", ks[1])) else NA_integer_)
  }
  sh <- rm_shape("ts_baseline")
  check("v36", "ts_baseline -- fixture has 36 rows", sh[["n"]], 36, tol = 0)
  check("v36", "ts_baseline -- fixture has 3 time points", sh[["times"]], 3, tol = 0)
  check_true("v36", "ts_baseline -- the plugin discloses 33 averaged observations",
             says(log_of("ts_baseline"), ts_line("ts_baseline", sh[["n"]] - sh[["times"]])))

  sh <- rm_shape("tsci_baseline")
  cells <- sh[["times"]] * sh[["groups"]]
  check("v36", "tsci_baseline -- fixture has 2 groups", sh[["groups"]], 2, tol = 0)
  check_true("v36", "tsci_baseline -- the plugin reports the group count",
             says(log_of("tsci_baseline"),
                  sprintf("Time Series (with CI): %d group(s)", sh[["groups"]])))
  check_true("v36", "tsci_baseline -- every group reports its time points",
             all(vapply(seq_len(sh[["groups"]]), function(g)
                 says(log_of("tsci_baseline"),
                      sprintf("Group: S%d — %d time points", g, sh[["times"]])),
                 logical(1))))
  check_true("v36", "tsci_baseline -- observations per time point match the fixture",
             says(log_of("tsci_baseline"),
                  sprintf("Observations per time point: up to %d",
                          sh[["n"]] %/% cells)))
  check_true("v36", "tsci_baseline -- discloses the CI and the averaged count",
             says(log_of("tsci_baseline"), sprintf(
               "Time series (with CI): Line shows the mean; band shows the 95%% CI. %d repeated observation(s) were averaged into their time points. Use Spaghetti Plot to show the individual series behind the mean.",
               sh[["n"]] - cells)))
}

# --- bar_customerr / bar_sd / bar_baseline: the error-bar selector --------
# The eleventh argument of @emlDrawBarChart is the error-bar mode and the
# twelfth is the custom column. The disclosure is DERIVED from those two and
# compared with the log, so the check is that the selector reaches the
# disclosure -- not that a particular string appears somewhere. All three also
# have to carry the "bars are means" caveat, which is the disclosure ruling's
# whole point, and all three must differ from each other: three modes that
# printed the same line would pass any per-case check written separately.
{
  err_line <- function(cs) {
    a <- draw_args(src_of(cs), "emlDrawBarChart")
    mode <- suppressWarnings(as.integer(a[11]))
    col  <- gsub('"', "", a[12])
    if (identical(mode, 1L)) "Bar chart: Error bars: +/-1 SE."
    else if (identical(mode, 2L)) "Bar chart: Error bars: +/-1 SD."
    else if (identical(mode, 3L)) sprintf("Bar chart: Error bars: %s (custom).", col)
    else NA_character_
  }
  CAVEAT <- "Bar chart: Bars show the group mean, not individual values. Use Violin Plot or Box Plot to show the distribution within each group."
  lines <- character(0)
  for (cs in c("bar_baseline", "bar_sd", "bar_customerr")) {
    e <- err_line(cs); lines <- c(lines, e)
    check_true("v36", sprintf("%s -- error-bar mode is one the plugin knows", cs),
               !is.na(e))
    check_true("v36", sprintf("%s -- the log states the error bars the case asked for", cs),
               !is.na(e) && says(log_of(cs), e))
    check_true("v36", sprintf("%s -- carries the bars-are-means caveat", cs),
               says(log_of(cs), CAVEAT))
  }
  check("v36", "the three bar modes print three different disclosures",
        length(unique(lines)), 3, tol = 0)
  check_true("v36", "bar_customerr names its own error column",
             grepl("err (custom)", lines[3], fixed = TRUE))
  # Same fixture, same bars, whiskers of different lengths: the three figures
  # must be near-identical in coverage. A mode that silently drew no error
  # bars at all would still pass the log check above if the line were printed
  # unconditionally; this is the picture agreeing with the words.
  bc <- c(chrom_of("bar_baseline"), chrom_of("bar_sd"), chrom_of("bar_customerr"))
  check_true("v36", "the three bar figures agree in coverage to within 5%",
             all(is.finite(bc)) && (max(bc) - min(bc)) / min(bc) < 0.05)
}

# --- violin_outlier: one value a hundred times the rest -------------------
# 5000 among values near 50. The axis has to stretch to hold it, which
# squeezes every violin into a fraction of the panel -- so the case is CORRECT
# when it draws much less than an ordinary violin, and would be suspicious if
# it drew the same. There is no disclosure; the measurement is the evidence.
{
  src <- src_of("violin_outlier")
  vs  <- suppressWarnings(as.numeric(sub('.*, *', "", regmatches(
           set_lines(src, "numeric"), regexpr('"val", *[0-9]+ *$',
                                              set_lines(src, "numeric"))))))
  check_true("v36", "violin_outlier -- fixture still plants an extreme value",
             length(vs) >= 1L && max(vs) >= 1000)
  check_true("v36", "violin_outlier -- the extreme is ~100x the bulk",
             length(vs) >= 1L && max(vs) / 50 >= 50)
  check_true("v36", "violin_outlier -- the stretched axis compresses the violins",
             chrom_of("violin_outlier") < 0.6 * chrom_of("violin_baseline"))
  check_true("v36", "violin_outlier -- but the figure is fully populated",
             chrom_of("violin_outlier") > 10 * chrom_of("empty_violin"))
}

# --- violin_longlabels: the labels are not clipped ------------------------
# THE ONE CASE THAT LEAVES REAL EVIDENCE IN A PLACE NOBODY WAS LOOKING. Three
# category labels of 22 to 28 characters do not fit under a 6 x 4 panel, and
# @emlAssertFullViewport saves the drawn extent rather than a fixed rectangle
# -- so the correct outcome is a TALLER IMAGE, not a clipped one. 1800 x 1410
# against everyone else's 1800 x 1200: 210 px, 0.7 inch, of label below the
# panel. If the labels were ever clipped instead, this canvas would come back
# to 1200 and nothing else in the tree would notice.
{
  src <- src_of("violin_longlabels")
  labs <- gsub('"', "", regmatches(src, regexpr('g\\$ *= *"[^"]+"', src)))
  labs <- sub('^g\\$ *= *', "", labs)
  d <- png_size(file.path(out_dir, "violin_longlabels.png"))
  check("v36", "violin_longlabels -- fixture still uses three labels",
        length(labs), 3, tol = 0)
  check_true("v36", "violin_longlabels -- every label is over 20 characters",
             length(labs) == 3L && all(nchar(labs) > 20))
  check_true("v36", "violin_longlabels -- the canvas grew to hold them",
             !is.null(d) && d[2] > 1200)
  check("v36", "violin_longlabels -- and grew by the measured amount",
        reported = if (is.null(d)) NA_real_ else d[2], computed = 1410, tol = 0)
  check_true("v36", "violin_longlabels -- it is the only case whose canvas grew",
             identical(sort(ALL_39[vapply(ALL_39, function(cs) {
                 q <- png_size(file.path(out_dir, paste0(cs, ".png")))
                 !is.null(q) && q[2] != 1200L
             }, logical(1))]), "violin_longlabels"))
}

# --- violin_12groups / violin_onegroup: the group-count extremes ----------
# Twelve categories on one categorical axis against one. The palette holds 24
# styles so twelve is inside it, and the figure is expected to draw twelve
# narrow violins rather than to give up. One fat violin covers more of the
# panel than twelve thin ones, which is the ordering asserted; the 2x margin
# is half the observed 3.6x, because the two cases hold different draws and
# the claim is about violin WIDTH, not about the data.
{
  src <- src_of("violin_12groups")
  m <- regmatches(src, regexpr("mod +[0-9]+ *\\+ *1", src))
  k <- if (length(m)) as.integer(gsub("[^0-9]", "", sub("\\+ *1", "", m[1]))) else NA_integer_
  n <- table_rows(src)
  check("v36", "violin_12groups -- fixture cycles twelve groups", k, 12, tol = 0)
  check("v36", "violin_12groups -- fixture has 120 rows", n, 120, tol = 0)
  check("v36", "violin_12groups -- ten observations per group",
        if (is.finite(n) && is.finite(k)) n / k else NA_real_, 10, tol = 0)
  check_true("v36", "violin_12groups -- twelve violins still draw a full figure",
             chrom_of("violin_12groups") > 10 * chrom_of("empty_violin"))
  check_true("v36", "one violin covers more panel than twelve",
             chrom_of("violin_onegroup") > 2 * chrom_of("violin_12groups"))
  og <- set_lines(src_of("violin_onegroup"), "string")
  check("v36", "violin_onegroup -- fixture really has one group",
        length(unique(regmatches(og, regexpr('"grp", *"[^"]+"', og)))), 1, tol = 0)
}

# --- legend_cap: the legend stays inside the frame ------------------------
# D123. The case prints the frame rectangle and the legend box rectangle in
# PIXELS of the saved PNG, then prints its own LEGENDFIT verdict. The verdict
# is NOT taken: the four slacks are recomputed here from FRAMEPX and BOXPX,
# and the case's own four numbers are compared against the recomputation. Two
# sides of an arithmetic identity computed by the same code move together --
# @emlDrawLegend v1.23 measured itself at one font size and drew itself at
# another and it looked right, which is v32's argument and it applies here.
#
# v32 owns legend GEOMETRY off harness/legend/out and says in its own header
# that reading @emlDrawLegend's reported box is the right check for
# CONTAINMENT and the wrong one for geometry. Containment is what this is, on
# the artefact v32 does not read.
{
  lg <- log_of("legend_cap")
  field <- function(prefix, key) {
    ln <- grep(paste0("^", prefix, " "), trimws(lg), value = TRUE)
    if (length(ln) != 1L) return(NA_real_)
    m <- regmatches(ln, regexpr(paste0("(^| )", key, "=-?[0-9.]+"), ln))
    if (!length(m)) return(NA_real_)
    as.numeric(sub(".*=", "", m))
  }
  n      <- field("LEGENDCASE", "n")
  cols   <- field("LEGENDCASE", "cols")
  rows   <- field("LEGENDCASE", "rows")
  shown  <- field("LEGENDCASE", "shown")
  hidden <- field("LEGENDCASE", "hidden")
  fx <- field("FRAMEPX", "x"); fy <- field("FRAMEPX", "y")
  fw <- field("FRAMEPX", "w"); fh <- field("FRAMEPX", "h")
  bx <- field("BOXPX", "x");   by <- field("BOXPX", "y")
  bw <- field("BOXPX", "w");   bh <- field("BOXPX", "h")

  check("v36", "legend_cap -- 24 entries, the full palette", n, 24, tol = 0)
  check("v36", "legend_cap -- every entry was shown", shown, 24, tol = 0)
  check("v36", "legend_cap -- nothing was hidden", hidden, 0, tol = 0)
  check("v36", "legend_cap -- the layout accounts for all 24 entries",
        cols * rows, n, tol = 0)
  check_true("v36", "legend_cap -- the cap chose more than one column", cols > 1)
  check("v36", "legend_cap -- the case's own fit verdict is ok",
        field("LEGENDFIT", "ok"), 1, tol = 0)

  ok_rects <- all(is.finite(c(fx, fy, fw, fh, bx, by, bw, bh)))
  check_true("v36", "legend_cap -- both rectangles were reported in pixels", ok_rects)
  if (ok_rects) {
    sl <- bx - fx; sr <- (fx + fw) - (bx + bw)
    st <- by - fy; sb <- (fy + fh) - (by + bh)
    check_true("v36", "legend_cap -- the box is inside the frame, recomputed",
               sl >= 0 && sr >= 0 && st >= 0 && sb >= 0)
    check("v36", "legend_cap -- left slack matches the case's own arithmetic",
          field("LEGENDFIT", "left"),   sl, tol = 0)
    check("v36", "legend_cap -- right slack matches the case's own arithmetic",
          field("LEGENDFIT", "right"),  sr, tol = 0)
    check("v36", "legend_cap -- top slack matches the case's own arithmetic",
          field("LEGENDFIT", "top"),    st, tol = 0)
    check("v36", "legend_cap -- bottom slack matches the case's own arithmetic",
          field("LEGENDFIT", "bottom"), sb, tol = 0)
    # And the frame is inside the canvas. The rectangles are computed in
    # inches and rounded to pixels by the case; nothing else checks that the
    # result lands on the image the case then saved.
    d <- png_size(file.path(out_dir, "legend_cap.png"))
    check_true("v36", "legend_cap -- the frame lies within the saved canvas",
               !is.null(d) && fx >= 0 && fy >= 0 &&
               fx + fw <= d[1] && fy + fh <= d[2])
    check_true("v36", "legend_cap -- the legend box has area",
               bw > 0 && bh > 0)
  }
}

# --- violin_bw: the greyscale palette really removed the colour -----------
# Not on §17's list of pathologies and it belongs there. violin_bw is the only
# case that draws a full figure with almost no colour in it: 10.197% ink --
# five sixths of violin_baseline's -- against 6130 chromatic pixels, which is
# 2.5% of violin_baseline's. That pair of numbers IS the greyscale palette
# working, and it is also the case sitting closest to the driver's blank-frame
# threshold with a fully drawn figure: 6130 against a 4609 baseline. A palette
# regression that put colour back would move chroma by two orders of
# magnitude; one that stopped drawing would move ink.
{
  a <- draw_args(src_of("violin_bw"), "emlDrawViolinPlot")
  check_true("v36", "violin_bw -- the case still asks for the bw palette",
             length(a) >= 7L && identical(a[7], '"bw"'))
  check_true("v36", "violin_baseline -- the control still asks for colour",
             identical(draw_args(src_of("violin_baseline"), "emlDrawViolinPlot")[7],
                       '"color"'))
  check_true("v36", "violin_bw -- draws as much as a colour violin",
             ink_of("violin_bw") > 0.6 * ink_of("violin_baseline"))
  check_true("v36", "violin_bw -- with under 5% of the colour",
             chrom_of("violin_bw") < 0.05 * chrom_of("violin_baseline"))
  check_true("v36", "violin_bw -- and is still not a blank frame",
             chrom_of("violin_bw") > chrom_of("empty_violin") * 1.05)
}

# ---------------------------------------------------------------------------
# 8. RELATIONSHIPS ACROSS THE ARTEFACT
#
# Statements no per-case check can make.
# ---------------------------------------------------------------------------

# The stipple NOTE is printed by the platform's on-figure box background, so
# it appears in exactly the cases that draw a box on the figure: the four
# grouped types, the grouped scatter and the legend case. Asserted as a SET
# over all 39. A grouped type that stopped drawing its legend would lose its
# note here, and an ungrouped one that gained a box would gain one.
STIPPLE <- c("gbox_baseline", "gviolin_baseline", "legend_cap",
             "scatter_grouped", "spaghetti_grouped", "tsci_baseline")
have_note <- ALL_39[vapply(ALL_39, function(cs)
    any(grepl("stipple screen", log_of(cs), fixed = TRUE)), logical(1))]
check_true("v36", "exactly the box-drawing cases print the stipple NOTE",
           setequal(have_note, STIPPLE))

# Grouping adds series, and series add colour. Two independent pairs drawn
# from the same fixture, differing only in whether a group column was passed.
check_true("v36", "scatter_grouped carries more colour than scatter_baseline",
           chrom_of("scatter_grouped") > chrom_of("scatter_baseline"))
check_true("v36", "spaghetti_grouped carries more colour than spaghetti_baseline",
           chrom_of("spaghetti_grouped") > chrom_of("spaghetti_baseline"))
check_true("v36", "scatter_grouped is the only one of the pair with a group column",
           identical(draw_args(src_of("scatter_grouped"), "emlDrawScatterPlot")[11], '"cat"') &&
           identical(draw_args(src_of("scatter_baseline"), "emlDrawScatterPlot")[11], '""'))

# Every populated case must out-draw EVERY empty frame, not merely its own
# family's. The dimmest of the 29 is violin_n1 at 5318 and the brightest empty
# frame is empty_ts at 6969, so this is FALSE as stated for two cases -- which
# is the honest finding, and it is the reason v27 compares within a family and
# not across the artefact. What is true across the artefact is the ink floor:
# no populated case draws less ink than the emptiest frame.
check_true("v36", "no populated case inks less than the emptiest frame",
           min(res$ink[res$case %in% THE_29], na.rm = TRUE) >=
           min(res$ink[res$case %in% THE_TEN], na.rm = TRUE))
check("v36", "the three degenerate-but-drawn cases are the faintest of the 29",
      length(intersect(THE_29[order(res$chrom[match(THE_29, res$case)])][1:3],
                       c("violin_n1", "violin_zerovar", "violin_bw"))),
      3, tol = 0)

# ---------------------------------------------------------------------------
# 9. THE PRECONDITION: EVERY CASE IS SEEDED
#
# §14, and it is what licenses section 4. If an unseeded `randomGauss` comes
# back, thirty-nine pinned numbers start drifting and the failure would read
# as thirty-nine unrelated regressions. It fails here instead, once, by name.
#
# Seventeen cases have no random component at all -- the ten empty tables, the
# six violin and time-series fixtures built from literals, and legend_cap,
# which samples the normal quantile function at 120 fixed probabilities. The
# other twenty-two carry the LCG. Both lists are declared, because a case
# moving between them is exactly the change that would go unnoticed.
# ---------------------------------------------------------------------------
NO_RNG <- c(THE_TEN, "legend_cap", "ts_duplicate_times", "violin_hugevalues",
            "violin_n1", "violin_spanzero", "violin_tinyvalues",
            "violin_zerovar")
SEEDED <- setdiff(ALL_39, NO_RNG)

check("v36", "seventeen cases need no generator", length(NO_RNG), 17, tol = 0)
check("v36", "twenty-two cases carry the seeded LCG", length(SEEDED), 22, tol = 0)

praat_files <- list.files(cases_dir, pattern = "\\.praat$", full.names = TRUE)
check("v36", "one case file per rendered case, plus the prelude",
      length(praat_files), 40, tol = 0)

unseeded <- character(0); seeds <- integer(0); lcg <- character(0)
for (p in praat_files) {
    s <- readLines(p, warn = FALSE)
    if (any(grepl("randomGauss|randomUniform|randomInteger", s))) {
        unseeded <- c(unseeded, basename(p))
    }
    ln <- grep("^rngState *=", s, value = TRUE)
    if (length(ln)) seeds <- c(seeds, as.integer(sub(".*= *", "", ln[1])))
    ln <- grep("rngState *= *\\(", s, value = TRUE)
    if (length(ln)) lcg <- c(lcg, trimws(ln[1]))
}
check("v36", "no stress case calls Praat's unseeded generator",
      length(unseeded), 0, tol = 0)
if (length(unseeded))
    check_true("v36", sprintf("  still unseeded: %s",
                              paste(utils::head(unseeded, 8), collapse = ", ")),
               FALSE)
check("v36", "every seeded case declares a seed", length(seeds), 22, tol = 0)
check("v36", "no two cases share a seed",
      length(unique(seeds)), length(seeds), tol = 0)
check("v36", "every seeded case uses the same generator",
      length(unique(lcg)), 1, tol = 0)
check_true("v36", "the generator is the LCG the tracker specifies",
           length(lcg) > 0 &&
           grepl("(1103515245 * rngState + 12345) mod 2147483648",
                 lcg[1], fixed = TRUE))

for (cs in SEEDED) {
    check_true("v36", sprintf("%s -- carries a seed", cs),
               any(grepl("^rngState *=", src_of(cs))))
}
for (cs in NO_RNG) {
    check_true("v36", sprintf("%s -- is deterministic without a generator", cs),
               !any(grepl("^rngState *=", src_of(cs))))
}

# ---------------------------------------------------------------------------
# 10. THE SPAGHETTI SUMMARY -- the only case that prints a statistics block
#
# spaghetti_baseline and spaghetti_grouped write a full EML Stats summary to
# the Info channel beside the figure. Its structure is derived from the
# fixture: 36 rows over 3 conditions is N = 12 each. Its NUMBERS are checked
# against the fixture's DESIGN -- val = 20 + 4c + 3s + noise, coefficient read
# out of the case file -- and never against a replayed LCG draw, for the
# reason in the header block. So the claim is "the condition effect the
# fixture builds in is the one the summary reports", which is a statement
# about the plugin, and not "the mean is 28.221", which is a statement about
# double precision in Praat's modulo.
# ---------------------------------------------------------------------------
for (cs in c("spaghetti_baseline", "spaghetti_grouped")) {
    lg <- log_of(cs); tab <- kv(lg); src <- src_of(cs)
    n <- table_rows(src)
    kc <- regmatches(src, regexpr("c *= *\\(i - 1\\) mod [0-9]+", src))
    ncond <- if (length(kc)) as.integer(sub("^.*mod ", "", kc[1])) else NA_integer_
    coef <- regmatches(src, regexpr("20 \\+ [0-9]+ \\* c", src))
    coef <- if (length(coef)) as.numeric(gsub("[^0-9]", "", sub("20 \\+ ", "", coef[1]))) else NA_real_

    check_true("v36", sprintf("%s -- printed a summary block", cs), nrow(tab) > 0L)
    check("v36", sprintf("%s -- summary reports the fixture's condition count", cs),
          reported = suppressWarnings(as.numeric(tab$v[tab$k == "Conditions"][1])),
          computed = ncond, tol = 0)

    ns <- suppressWarnings(as.numeric(tab$v[tab$k == "N"]))
    check("v36", sprintf("%s -- one N per condition", cs), length(ns), ncond, tol = 0)
    check_true("v36", sprintf("%s -- every condition has n = rows/conditions", cs),
               is.finite(n) && is.finite(ncond) && all(ns == n / ncond))

    ms <- suppressWarnings(as.numeric(tab$v[tab$k == "Mean"]))
    sds <- suppressWarnings(as.numeric(tab$v[tab$k == "SD"]))
    check("v36", sprintf("%s -- one mean per condition", cs), length(ms), ncond, tol = 0)
    check_true("v36", sprintf("%s -- means rise with condition, as the fixture builds them", cs),
               length(ms) == ncond && all(diff(ms) > 0))
    # The step is the fixture's coefficient. +/-1.5 is the band, not a
    # measurement: each mean is over twelve draws of a uniform on +/-3.4 plus a
    # 3-unit between-subject offset, so the standard error of a difference is
    # about 0.9 and the tolerance is under two of them. Wide enough that the
    # check is about the DESIGN and not about the generator.
    check_true("v36", sprintf("%s -- each step matches the fixture's coefficient", cs),
               is.finite(coef) && length(ms) == ncond &&
               all(abs(diff(ms) - coef) < 1.5))
    # SD band from the fixture's own arithmetic: noise is uniform on +/-3.4
    # (SD 1.96) and the between-subject term adds 3 units split two ways
    # (SD 1.5), so a correct SD is near sqrt(1.96^2 + 1.5^2) = 2.47.
    check_true("v36", sprintf("%s -- every SD is near the fixture's built-in spread", cs),
               length(sds) == ncond && all(sds > 1.5 & sds < 3.5))
}
check_true("v36", "only the grouped spaghetti reports a group count",
           length(kv(log_of("spaghetti_grouped"))$v[
                    kv(log_of("spaghetti_grouped"))$k == "Groups"]) == 1L &&
           length(kv(log_of("spaghetti_baseline"))$v[
                    kv(log_of("spaghetti_baseline"))$k == "Groups"]) == 0L)

if (!exists("EML_SUITE")) {
    eml_report("v36 stress output: the twenty-nine cases nobody was judging (§17)")
    eml_exit()
}
