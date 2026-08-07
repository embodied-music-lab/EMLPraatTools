# ============================================================================
# v26_twoway_caveat.R -- the interaction caveat, asserted in both directions.
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# Ruling 3(a): when the interaction is significant, the two main-effect rows
# are averages taken across a difference that is itself real, and the report
# has to say so. Like Ruling 1's block this is CONDITIONAL, so one capture
# cannot demonstrate it -- an unconditional caveat and a correct one look
# identical in the capture where it fires.
#
#   v26_caveat_absent_info.txt   v11_twoway_input.csv   interaction p = .116
#   v26_caveat_present_info.txt  dump_demo_twoway.csv   interaction p < .001
#
# Also covers the second unconditional rider: @emlTwoWayAnova.warning$ was
# computed, written to the glance frame, and printed nowhere, so a user
# reading the report never saw it and only a user who exported the CSV did.
#
# Input: evidence/info/v26_caveat_*.txt
#        (regenerate with harness/broom_cases/twoway_caveat_drive.praat)
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

capo_a <- capture("v26_caveat_absent_info.txt")
capo_p <- capture("v26_caveat_present_info.txt")
cap_a  <- capo_a$lines
cap_p  <- capo_p$lines

d_a <- read.csv(repo_path("evidence", "csv", "v11_twoway_input.csv"),
                stringsAsFactors = FALSE)
d_p <- read.csv(repo_path("evidence", "csv", "dump_demo_twoway.csv"),
                stringsAsFactors = FALSE)

# R's own two-way, balanced in both files so Type I / II / III coincide and
# the comparison does not turn on a sums-of-squares convention.
tw <- function(d) {
  a <- anova(lm(SPL_dB ~ factor(voice_type) * factor(task), data = d))
  list(fA = a[1, 4], fB = a[2, 4], fAB = a[3, 4],
       pA = a[1, 5], pB = a[2, 5], pAB = a[3, 5])
}
r_a <- tw(d_a)
r_p <- tw(d_p)

# ---- 1. the fixture is what this script assumes it is ---------------------
# If someone regenerates or replaces either input, the conditional stops
# being tested and every check below still passes. Assert the premise.
check_true("v26", "absent fixture really has a NON-significant interaction",
           r_a$pAB > 0.05)
check_true("v26", "present fixture really has a significant interaction",
           r_p$pAB < 0.001)

# ---- 2. the caveat, both directions ---------------------------------------
cav <- function(cap) any(grepl("the interaction is significant", cap))
check_true("v26", "p_AB = .116: interaction caveat is ABSENT",  !cav(cap_a))
check_true("v26", "p_AB < .001: interaction caveat is PRESENT",  cav(cap_p))

# The caveat's substance, not just its presence: it has to send the reader to
# the cell means, because "the main effects are qualified" without saying
# qualified how is the D36 complaint restated rather than answered.
check_true("v26", "the caveat points at the cell means",
           any(grepl("cell means", cap_p)))
check_true("v26", "the cell-means block it points at actually exists",
           any(grepl("── Cell Means", cap_p)))
check_true("v26", "the caveat comes BEFORE the cell means it points at",
           grep("the interaction is significant", cap_p)[1] <
           grep("── Cell Means", cap_p)[1])

# Placement (D98 ruling): a caveat below the effect sizes reads as being about
# the effect sizes. It must sit under the ANOVA table it qualifies.
check_true("v26", "the caveat sits above the effect-size block",
           grep("the interaction is significant", cap_p)[1] <
           grep("── Effect Sizes", cap_p)[1])

# ---- 3. the three F values are unchanged by the caveat --------------------
# Same argument as v25's primary-F check: the caveat must be additive. If a
# future edit ever made the report DO something different when the
# interaction is significant, this is what catches it.
for (nm in c("absent", "present")) {
  cap <- if (nm == "absent") cap_a else cap_p
  r   <- if (nm == "absent") r_a   else r_p
  # The ANOVA table is a fixed-width block, not label/value lines, so it is
  # parsed positionally from the header row rather than with printed().
  i0   <- grep("^Source\\s+SS\\s+df", cap)[1]
  rows <- cap[(i0 + 1):(i0 + 3)]
  got  <- vapply(rows, function(l) {
            f <- strsplit(trimws(l), "\\s{2,}")[[1]]
            as.numeric(f[length(f) - 1])
          }, numeric(1))
  check("v26", paste0(nm, ": factor 1 F"),     got[1], r$fA,  tol = 5e-5)
  check("v26", paste0(nm, ": factor 2 F"),     got[2], r$fB,  tol = 5e-5)
  check("v26", paste0(nm, ": interaction F"),  got[3], r$fAB, tol = 5e-5)
}

# ---- 4. warning$ reaches the REPORT, not only the CSV ---------------------
# Both committed inputs are balanced and complete, so neither sets warning$
# and neither capture can show it printing. What IS assertable here is that
# the report no longer prints a bare "Caution:" from any other source, and
# that the only Caution in the present capture is the interaction one -- so
# when a warning does fire it will be visible as a second occurrence rather
# than being mistaken for this.
check("v26", "absent capture has no Caution line at all",
      sum(grepl("Caution:", cap_a)), 0, tol = 0)
check("v26", "present capture has exactly one Caution line",
      sum(grepl("Caution:", cap_p)), 1, tol = 0)
check_true("v26", "and that one Caution IS the interaction caveat",
           grepl("interaction is significant",
                 paste(cap_p[grep("Caution:", cap_p)[1] +
                             0:4], collapse = " ")))

# ---- 5. the two captures agree above the ANOVA table ----------------------
# Weaker control than v25's (two files, not two columns of one), so this
# guard matters more here: everything from the header down to the table is
# the same label sequence in both, and a conditional that leaked upward
# breaks it without anyone having to predict how.
upto <- function(cap) {
  i <- grep("^Source\\s+SS\\s+df", cap)[1]
  labs <- sub("^\\s*([A-Za-z][A-Za-z' -]*?)\\s{2,}.*$", "\\1", cap[1:i])
  labs[grepl("^[A-Za-z]", labs)]
}
check_true("v26", "both captures share the same label sequence above the table",
           identical(upto(cap_a), upto(cap_p)))

if (!exists("EML_SUITE")) { eml_report("v26 two-way interaction caveat"); eml_exit() }
