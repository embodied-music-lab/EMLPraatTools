# v25 — Ruling 1 at the REPORT level: conditional show-both
#
# v22 checks the three new procedures. This checks the thing a user sees: that
# the equal-spread line is always there, that the alternative block appears
# when and only when the check rejects, and that the standard ANOVA above it
# is bit-for-bit the same test in both cases.
#
# Two captures, same committed input file, same group column, same Tukey
# setting. Only the data column differs:
#
#   v25_showboth_absent_info.txt   SPL_dB           BF p = .678  block absent
#   v25_showboth_present_info.txt  vibrato_rate_Hz  BF p = .030  block present
#
# The ABSENT case carries the ruling's real constraint. "Never replace, never
# auto-switch, never make the reported primary test depend on the data" is not
# demonstrated by the block appearing; it is demonstrated by the block staying
# away, and by the F above it matching aov() rather than oneway.test().
#
# Base R only. No packages.

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

# capture() gives the object printed() reads; the raw lines are needed too,
# because most of what this script asserts is about the PRESENCE, ABSENCE and
# ORDER of blocks rather than about a labelled value.
capo_a <- capture("v25_showboth_absent_info.txt")
capo_p <- capture("v25_showboth_present_info.txt")
cap_a  <- capo_a$lines
cap_p  <- capo_p$lines
d      <- read.csv(repo_path("evidence", "csv", "v09_anova_tukey_input.csv"),
                   stringsAsFactors = FALSE)

# Brown-Forsythe = one-way ANOVA on absolute deviations from the group MEDIAN.
bf <- function(y, g) {
  g <- factor(g)
  z <- abs(y - ave(y, g, FUN = median))
  a <- anova(lm(z ~ g))
  list(F = a[1, 4], df1 = a[1, 1], df2 = a[2, 1], p = a[1, 5])
}

# ---- 1. the equal-spread line is present in BOTH -------------------------
# It is unconditional by ruling. A capture missing it means the line became
# conditional on rejection, which would turn a disclosure into an accusation.
for (nm in c("absent", "present")) {
  cap <- if (nm == "absent") cap_a else cap_p
  check_true("v25", paste0(nm, ": equal-spread F line present"),
             any(grepl("Equal spread\\s+Brown-Forsythe F\\(", cap)))
  check_true("v25", paste0(nm, ": equal-spread p line present"),
             any(grepl("Equal-spread p", cap)))
}

# ---- 2. the BF numbers are R's, in both captures --------------------------
for (nm in c("absent", "present")) {
  cap <- if (nm == "absent") cap_a else cap_p
  col <- if (nm == "absent") "SPL_dB" else "vibrato_rate_Hz"
  r   <- bf(d[[col]], d$voice_type)
  ln  <- grep("Equal spread\\s+Brown-Forsythe F\\(", cap, value = TRUE)[1]
  got <- as.numeric(sub(".*=\\s*", "", ln))
  dfs <- as.numeric(strsplit(sub(".*F\\(([^)]*)\\).*", "\\1", ln), ",\\s*")[[1]])
  check("v25", paste0(nm, ": Brown-Forsythe F"),   got,    r$F,   tol = 5e-5)
  check("v25", paste0(nm, ": Brown-Forsythe df1"), dfs[1], r$df1, tol = 0)
  check("v25", paste0(nm, ": Brown-Forsythe df2"), dfs[2], r$df2, tol = 0)
}

# ---- 3. the conditional, both directions ----------------------------------
# Match the SECTION RULE, not the bare phrase: the note above it quotes the
# section title, so a substring test would report the block present in a
# capture that only mentions it.
sect <- function(cap) any(grepl("── If the spreads are unequal", cap))

check_true("v25", "equal spreads: alternative block is ABSENT",  !sect(cap_a))
check_true("v25", "unequal spreads: alternative block is PRESENT", sect(cap_p))

check_true("v25", "equal spreads: no Welch F anywhere in the capture",
           !any(grepl("Welch's F\\s+F\\(", cap_a)))
check_true("v25", "equal spreads: no Games-Howell anywhere in the capture",
           !any(grepl("Games-Howell", cap_a)))
check_true("v25", "equal spreads: the pointer note is absent too",
           !any(grepl("differ in spread more than", cap_a)))
check_true("v25", "unequal spreads: the pointer note IS there",
           any(grepl("differ in spread more than", cap_p)))

# ---- 4. the PRIMARY test did not change --------------------------------
# The whole ruling rests on this. In both captures the F under "ANOVA Table"
# must be aov()'s pooled F on that column -- NOT oneway.test()'s Welch F --
# even in the capture where the spreads are unequal and a Welch F is printed
# further down. If a future edit ever switches the primary test, every other
# check here still passes and this one does not.
for (nm in c("absent", "present")) {
  cap <- if (nm == "absent") cap_a else cap_p
  col <- if (nm == "absent") "SPL_dB" else "vibrato_rate_Hz"
  fit <- summary(aov(d[[col]] ~ factor(d$voice_type)))[[1]]
  wel <- oneway.test(d[[col]] ~ factor(d$voice_type), var.equal = FALSE)
  capo <- if (nm == "absent") capo_a else capo_p
  got  <- printed(capo, "F")
  check("v25", paste0(nm, ": primary F is aov()'s pooled F"),
        got, fit[["F value"]][1], tol = 5e-5)
  check_true("v25", paste0(nm, ": primary F is NOT the Welch F"),
             abs(got - unname(wel$statistic)) > 1e-3)
}

# ---- 5. the alternative block's own numbers -------------------------------
wel <- oneway.test(d$vibrato_rate_Hz ~ factor(d$voice_type), var.equal = FALSE)
ln  <- grep("Welch's F\\s+F\\(", cap_p, value = TRUE)[1]
check("v25", "Welch F statistic", as.numeric(sub(".*=\\s*", "", ln)),
      unname(wel$statistic), tol = 5e-5)
wdf <- as.numeric(strsplit(sub(".*F\\(([^)]*)\\).*", "\\1", ln), ",\\s*")[[1]])
check("v25", "Welch numerator df",   wdf[1], unname(wel$parameter[1]), tol = 0)
check("v25", "Welch denominator df", wdf[2], unname(wel$parameter[2]), tol = 5e-3)

# Games-Howell: Tukey's q distribution, Welch pairwise SE, Welch-Satterthwaite
# df. Computed here from scratch rather than taken from a package, so the
# check does not depend on one being installed.
gh <- function(y, g) {
  g <- factor(g); L <- levels(g)
  m <- tapply(y, g, mean); v <- tapply(y, g, var); n <- tapply(y, g, length)
  k <- nlevels(g); out <- list()
  for (i in 1:(k - 1)) for (j in (i + 1):k) {
    se <- sqrt((v[i] / n[i] + v[j] / n[j]) / 2)
    q  <- abs(m[i] - m[j]) / se
    df <- (v[i]/n[i] + v[j]/n[j])^2 /
          ((v[i]/n[i])^2 / (n[i]-1) + (v[j]/n[j])^2 / (n[j]-1))
    out[[paste(L[i], L[j])]] <- ptukey(q, k, df, lower.tail = FALSE)
  }
  out
}
ghR <- gh(d$vibrato_rate_Hz, d$voice_type)

# The printed matrix is APA-bare (".584"), unlike the Tukey matrix above it
# which is fixed$(p, 4) ("0.4918"). Parse what is actually there rather than
# assuming the two matrices agree on format -- they do not, and that
# inconsistency is recorded as a finding rather than papered over here.
i0 <- grep("── Games-Howell Pairwise", cap_p)
check_true("v25", "Games-Howell matrix is present", length(i0) == 1)
blk  <- cap_p[(i0 + 1):(i0 + 8)]
hdr  <- grep("Soprano", blk)[1]
labs <- strsplit(trimws(blk[hdr]), "\\s+")[[1]]
rows <- blk[(hdr + 1):(hdr + length(labs))]
M <- matrix(NA_real_, length(labs), length(labs), dimnames = list(labs, labs))
for (r in seq_along(rows)) {
  cells <- strsplit(trimws(rows[r]), "\\s+")[[1]][-1]
  M[r, ] <- suppressWarnings(as.numeric(sub("^\\.", "0.", cells)))
}
for (nm in names(ghR)) {
  ij <- strsplit(nm, " ")[[1]]
  check("v25", paste("Games-Howell p", ij[1], "vs", ij[2]),
        M[ij[1], ij[2]], unname(ghR[[nm]]), tol = 1e-3)
  check("v25", paste("Games-Howell matrix symmetric", ij[1], ij[2]),
        M[ij[1], ij[2]], M[ij[2], ij[1]], tol = 0)
}

# ---- 6. the two captures differ ONLY where they should --------------------
# Everything from the report header down to the equal-spread line is the same
# shape in both. If a future edit made the conditional leak upward -- a
# different heading, a reordered block -- this catches it without anyone
# having to think of the specific way it broke.
upto <- function(cap) {
  i <- grep("Equal spread\\s+Brown-Forsythe", cap)[1]
  labs <- sub("^\\s*([A-Za-z][A-Za-z' -]*?)\\s{2,}.*$", "\\1", cap[1:i])
  labs[grepl("^[A-Za-z]", labs)]
}
check_true("v25", "both captures share the same label sequence above the check",
           identical(upto(cap_a), upto(cap_p)))

if (!exists("EML_SUITE")) { eml_report("v25 conditional show-both (Ruling 1, report level)"); eml_exit() }
