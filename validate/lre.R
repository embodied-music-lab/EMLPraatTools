# ============================================================================
# lre.R -- log relative error, the metric StRD work is reported in.
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# A pass/fail tolerance is the wrong instrument for a certified value. NIST
# publishes 15 significant digits and grades datasets by difficulty precisely
# so that an implementation can be reported as "agrees to 11 digits here, 7
# digits on Filip" rather than "passed". LRE is that number:
#
#     LRE = -log10( |computed - certified| / |certified| )
#
# with the convention that an exact match is capped at 17 (the most a double
# can carry) and that a certified value of zero switches to absolute error,
# since the relative form is undefined there.
#
# Reported, not thresholded, except for a floor low enough that only a real
# defect trips it.
# ============================================================================

lre <- function(computed, certified) {
  if (!is.finite(computed) || !is.finite(certified)) return(NA_real_)
  if (computed == certified) return(17)
  err <- if (certified == 0) abs(computed) else abs(computed - certified) / abs(certified)
  if (err == 0) return(17)
  min(17, max(0, -log10(err)))
}

# check_lre — record an LRE as a suite check. `floor` is the number of correct
# significant digits below which this counts as a failure. 7 is the
# conventional "no worse than single precision" line; a routine that is merely
# unlucky in the last bits scores 12-15 and passes without the floor having to
# be tuned per dataset.
check_lre <- function(id, what, computed, certified, floor_digits = 7) {
  v <- lre(computed, certified)
  # Recorded through check() rather than check_true() so the suite's own
  # reported/computed columns carry the two numbers and a reader can see the
  # disagreement, not just a verdict. The tolerance is the floor expressed as
  # an absolute quantity, so "LRE >= floor" and "within tol" are the same
  # statement rather than two that could drift apart.
  scale <- if (certified == 0 || !is.finite(certified)) 1 else abs(certified)
  check(id, sprintf("%s  [LRE %.2f digits, floor %g]", what, v, floor_digits),
        computed, certified, tol = scale * 10^(-floor_digits))
  invisible(v)
}
