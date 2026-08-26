# ============================================================================
# v139_fingerprint_store_mutations.R -- the four ruled mutation legs, driven
# THROUGH THE STORE rather than against @emlGroupFingerprint directly
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS IS FOR, AND WHY IT IS NOT A DUPLICATE OF v114.
#
# validate/v114_fingerprint_suite.R runs the 278 phase2 legs against
# @emlGroupFingerprint and its neighbours DIRECTLY -- the fingerprint
# procedures, called as themselves. That answers "does the digest have the
# right mathematical properties". It does not answer "does a caller who only
# ever sees the STORE's own published key get those properties" -- and the
# two questions are not the same one: a bug in @emlResultKeyTake (the wrong
# moment, the wrong door, a stale local not copied) could leave the
# fingerprint procedures perfectly correct and the STORE wrong anyway, and
# nothing in phase2 would ever see it, because phase2 never calls a menu
# door or reads emlResultKey$.
#
# So this file re-asks docs/RULING_RESULT_STORE.md section (a)'s four
# mutation legs -- and the one Ian's 24 August ruling OVERTURNED, which now
# reads the opposite of what section (a)'s text still says -- ONE LEVEL UP:
# through @emlRunAnovaAnalysis (a real menu door) and emlResultKey$ (the
# published name), exactly as harness/resultstore/probe.praat drives it.
# That is the "driven through the store" the work order asked for.
#
# THE TWO RULING AMENDMENTS THIS FILE HONOURS, both stated at the top of the
# work order and neither optional:
#
#   1. The fingerprint is eTF2 (whole table, text, table order, folded scope)
#      -- not a per-group aggregate. This file does not touch that composition
#      and does not re-derive it; it reads the KEY AS TEXT, exactly as
#      @emlFingerprintsAgree does, and asks only whether two keys are equal.
#   2. Row reorder MUST invalidate. REORDER_ROWS is in the REQUIRED set below
#      on that instruction, not on the ruling document's original wording --
#      which still calls it a negative control. A future reader who "fixes"
#      this file to expect reorder_rows to HOLD is reverting exactly the
#      defect Ian's 24 August ruling closed, and this file's comments say so
#      loudly for that reason, the same way test-fingerprint.praat's own
#      header does.
#
# THE STANDARD KIT.
#
#   POPULATION DERIVED, NOT WRITTEN DOWN. The set of legs this file grades is
#   read OUT OF harness/resultstore/probe.praat itself -- every case name that
#   appears with a keyBefore/keyAfter/keysAgree triple -- not typed here by
#   hand. A leg renamed, removed, or added in the probe changes what this file
#   sees on the next run without anyone touching this file.
#
#   ONE PROPERTY PER MEMBER. Every leg in the derived population gets exactly
#   one assertion: keysAgree = 0, i.e. the mutation INVALIDATED the key.
#
#   THE RATCHET, BOTH DIRECTIONS. The derived population is compared to
#   REQUIRED_LEGS, the four names the ruling (as amended) requires, by SET
#   EQUALITY: a leg the ruling requires but the probe stopped emitting is red,
#   and a leg the probe emits that this file does not recognise is ALSO red
#   -- so a fifth leg lands on someone's desk instead of silently riding
#   along ungraded.
#
#   A FAILURE IF IT WALKED ZERO MEMBERS. Section 2's resolver gate fails on an
#   empty population outright, before any per-leg assertion runs, so a probe
#   that silently stopped emitting rows cannot read as "four for four".
#
#   A SEEDED VIOLATION DEMONSTRATED RED, and a resolver that reports how many
#   members were walked. harness/resultstore/break.sh builds a copy of the
#   plugin with @emlResultKeyTake's read of the fingerprint replaced by a
#   constant, re-drives the probe against the copy, and points this file at
#   the shadow artefact via $EML_STORE_OUT -- every leg reads keysAgree = 1
#   (the key held where it must have moved) and every per-leg assertion below
#   goes red, which is what demonstrates this file is measuring the real
#   thing rather than trivially passing.
#
# Reads harness/resultstore/out/STORE.tsv (written by
# harness/resultstore/run.sh) and harness/resultstore/probe.praat itself (to
# derive the population). $EML_STORE_OUT and $EML_STORE_PROBE override both,
# the same shape v112/v127's $EML_*_SRC / $EML_*_OUT pairs use, so a break
# test can point this file at a shadow tree's evidence without touching the
# working tree.
#
# Base R only. Drives nothing; reads two files.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

V <- "v139"

if (!exists("check_true")) source(file.path(
    Sys.getenv("EML_VALIDATE_DIR", unset = "validate"), "helpers.R"))

tsv_path <- Sys.getenv("EML_STORE_OUT", unset = "")
if (!nzchar(tsv_path))
    tsv_path <- repo_path("harness", "resultstore", "out", "STORE.tsv")

probe_path <- Sys.getenv("EML_STORE_PROBE", unset = "")
if (!nzchar(probe_path))
    probe_path <- repo_path("harness", "resultstore", "probe.praat")

# ---------------------------------------------------------------------------
# THE FOUR LEGS THE RULING (AS AMENDED) REQUIRES.
# ---------------------------------------------------------------------------
# Ruling section (a): edit one data cell (same n), relabel one group cell,
# swap one value between groups -- three mutation legs the ruling's own text
# names as legs that must invalidate. The fourth, REORDER_ROWS, is what
# section (a)'s text calls the negative control ("reorder rows within a
# group; the cache legitimately holds") and Ian's 24 August ruling OVERTURNED
# outright: "any change to the data including reordering of rows forces the
# mismatch error and redoing of the stats." It is in this REQUIRED set as a
# MUST-INVALIDATE leg for that reason, not the ruling document's original one
# -- see the header above.
REQUIRED_LEGS <- c("edit_one_cell", "relabel_group_cell",
                   "swap_value_between_groups", "reorder_rows")

REASON <- c(
    edit_one_cell =
        "one data cell edited, n unchanged (ruling section a)",
    relabel_group_cell =
        "one group-column cell relabelled (ruling section a)",
    swap_value_between_groups =
        "one value exchanged between two groups' rows, sizes and the value multiset both unchanged (ruling section a)",
    reorder_rows =
        "the whole table's row order reversed, no cell's content changed (Ian's 24 August ruling OVERTURNING the reorder negative control)"
)

# ---------------------------------------------------------------------------
# 1. THE POPULATION -- DERIVED FROM THE PROBE, NOT WRITTEN DOWN HERE
# ---------------------------------------------------------------------------
ok_probe <- check_true(V, "the driving probe is in the tree and is not empty",
                       file.exists(probe_path) && file.size(probe_path) > 0)

probe_src <- if (ok_probe) paste(readLines(probe_path, warn = FALSE),
                                 collapse = "\n") else ""

# A leg is anything that appears with all three fields this file needs to
# grade it. Matched independently per field, and intersected, rather than by
# one brittle multi-line regex -- so a probe that emits the fields in a
# different order, or with something else interleaved, is still read
# correctly.
legs_of <- function(field) {
    m <- gregexpr(paste0('@note:\\s*"([A-Za-z0-9_]+)",\\s*"', field, '"'),
                  probe_src, perl = TRUE)
    g <- regmatches(probe_src, m)[[1]]
    unique(sub(paste0('.*"([A-Za-z0-9_]+)",\\s*"', field, '".*'), "\\1", g))
}
have_before  <- legs_of("keyBefore")
have_after   <- legs_of("keyAfter")
have_agree   <- legs_of("keysAgree")
population   <- sort(Reduce(intersect, list(have_before, have_after, have_agree)))

check_true(V,
           sprintf("RESOLVER: the probe source yields a nonzero population (%d legs found)",
                   length(population)),
           length(population) > 0)

partial <- unique(c(setdiff(have_before, population),
                    setdiff(have_after, population),
                    setdiff(have_agree, population)))
check_true(V,
           sprintf("every case the probe names carries all three fields (keyBefore, keyAfter, keysAgree)%s",
                   if (length(partial))
                       paste0(" -- INCOMPLETE: ", paste(partial, collapse = ", "))
                   else ""),
           length(partial) == 0)

# ---------------------------------------------------------------------------
# 2. THE RATCHET, BOTH DIRECTIONS
# ---------------------------------------------------------------------------
missing <- setdiff(REQUIRED_LEGS, population)
extra   <- setdiff(population, REQUIRED_LEGS)

check_true(V,
           sprintf("every ruled leg is present in the probe%s",
                   if (length(missing))
                       paste0(" -- MISSING: ", paste(missing, collapse = ", "))
                   else ""),
           length(missing) == 0)

check_true(V,
           sprintf("no leg is present that this file does not recognise%s",
                   if (length(extra))
                       paste0(" -- UNGRADED, add it to REQUIRED_LEGS: ",
                              paste(extra, collapse = ", "))
                   else ""),
           length(extra) == 0)

# ---------------------------------------------------------------------------
# 3. THE EVIDENCE
# ---------------------------------------------------------------------------
ok_tsv <- check_true(V, "the resultstore probe's artefact is present",
                     file.exists(tsv_path))

ev <- data.frame(case = character(0), field = character(0),
                 value = character(0), stringsAsFactors = FALSE)
if (ok_tsv) {
    raw <- readLines(tsv_path, warn = FALSE)
    raw <- raw[nzchar(raw)]
    raw <- raw[-1] # header
    rows <- strsplit(raw, "\t", fixed = TRUE)
    ev <- data.frame(
        case  = vapply(rows, function(r) if (length(r) >= 1) r[1] else "", ""),
        field = vapply(rows, function(r) if (length(r) >= 2) r[2] else "", ""),
        value = vapply(rows, function(r) if (length(r) >= 3) r[3] else "", ""),
        stringsAsFactors = FALSE)
}

val <- function(cs, fl) {
    i <- which(ev$case == cs & ev$field == fl)
    if (!length(i)) NA_character_ else ev$value[i[length(i)]]
}

# ---------------------------------------------------------------------------
# 4. ONE PROPERTY PER MEMBER: THE MUTATION INVALIDATED THE PUBLISHED KEY
# ---------------------------------------------------------------------------
for (leg in REQUIRED_LEGS) {
    kb <- val(leg, "keyBefore")
    ka <- val(leg, "keyAfter")
    agree <- val(leg, "keysAgree")

    check_true(V,
               sprintf("%s: both keys were measured (%s)", leg, REASON[[leg]]),
               !is.na(kb) && !is.na(ka) && nzchar(kb) && nzchar(ka))

    check_true(V,
               sprintf("%s: the published key changed -- INVALIDATED, as ruled (before %s, after %s)",
                       leg,
                       if (is.na(kb)) "no measurement" else kb,
                       if (is.na(ka)) "no measurement" else ka),
               !is.na(kb) && !is.na(ka) && kb != ka)

    check_true(V,
               sprintf("%s: the probe's own keysAgree flag says so too (0 = moved, saw %s)",
                       leg, if (is.na(agree)) "no measurement" else agree),
               identical(agree, "0"))
}

# ---------------------------------------------------------------------------
# 5. THE RESOLVER GATE
# ---------------------------------------------------------------------------
n_walked <- length(intersect(population, REQUIRED_LEGS))
check_true(V,
           sprintf("RESOLVER: %d of %d required mutation legs were walked and graded",
                   n_walked, length(REQUIRED_LEGS)),
           n_walked > 0)

attest(V, "the resultstore probe evidence these numbers came from",
       sprintf("%s | %s", tsv_path, probe_path))

if (!exists("EML_SUITE")) {
    eml_report(sprintf(
        "v139 fingerprint-store mutations: %d/%d required legs walked",
        n_walked, length(REQUIRED_LEGS)))
    eml_exit()
}
