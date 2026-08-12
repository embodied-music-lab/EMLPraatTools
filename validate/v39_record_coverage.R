# ============================================================================
# v39_record_coverage.R -- the recorder, driven the way a user drives it
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS FILE EXISTS. On 12 August 2026 the workflow recorder was wired to
# the menu, and every test of it up to that point had started a recording and
# added steps IN THE SAME SCRIPT SCOPE. A menu command does not work that way:
# it ends and takes every variable with it, and the next command starts with
# nothing. Re-attaching to the buffer across that boundary is the entire
# design of the feature, and nothing had ever crossed it.
#
# harness/record_e2e/run.sh crosses it -- ten operations through `runScript:`,
# separate scopes in one process -- and found three things in an hour:
#
#   - three of its own ten operations were CRASHING and being reported as
#     "recorded nothing", so the first coverage number it produced was fiction;
#   - the draw capture hook could never fire from a menu invocation, so every
#     figure drawn from the menu went unrecorded while the recording ran;
#   - the phrase table was never loaded by the shipped plugin, so every
#     recording a user could make said [MISSING PHRASE] on every step.
#
#     bash harness/record_e2e/run.sh      regenerate the input
#     Rscript validate/v39_record_coverage.R
#
# Input: <rec>/RECORD.tsv, four fields, no header:
#            name  stepsBefore  stepsAfter  recorded|silent|DIDNOTRUN
#        <rec> is $EML_RECORD_DIR, default harness/record_e2e/out. A missing
#        artefact is a HARD STOP, not a skip -- v27's reason: "the driver
#        never ran this" is exactly what a silently shrinking suite hides.
#        <rec>/recorded.praat is the script the run emitted.
#
# WHAT IT PINS, AND THE DISTINCTION THAT MATTERS. Coverage is a NUMBER, not a
# boolean, and it is pinned as a floor: it may rise, and a fall has to be
# deliberate enough to edit this file. DIDNOTRUN is not a coverage figure at
# all -- it is a harness failure, and it is checked separately, because an
# operation that crashed and one that ran without a capture hook both leave
# the step count unchanged and only one of them is a fact about the plugin.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

rec_dir <- Sys.getenv("EML_RECORD_DIR", unset = "")
if (!nzchar(rec_dir)) rec_dir <- repo_path("harness", "record_e2e", "out")
rec_p <- file.path(rec_dir, "RECORD.tsv")
emitted_p <- file.path(rec_dir, "recorded.praat")

if (!file.exists(rec_p)) {
    stop("record artefact not found: ", rec_p,
         "\n  Run: bash harness/record_e2e/run.sh")
}

rc <- read.delim(rec_p, header = FALSE, stringsAsFactors = FALSE,
                 col.names = c("op", "before", "after", "verdict"))
rc$before <- as.integer(rc$before)
rc$after  <- as.integer(rc$after)

# ---------------------------------------------------------------------------
# 1. The population, declared
# ---------------------------------------------------------------------------
OPS <- c("anova", "twogroup", "kw", "descriptive", "normality",
         "correlation", "regression", "violin", "scatter", "histogram")
eml_census("v39", "recorded operation", rc$op, OPS)
eml_claim("v39", "record_out", OPS)
check("v39", "every declared operation was driven", nrow(rc), length(OPS),
      tol = 0)

check_true("v39", "the verdict column holds only the three legal values",
           all(rc$verdict %in% c("recorded", "silent", "DIDNOTRUN")))

# ---------------------------------------------------------------------------
# 2. AN OPERATION THAT DID NOT RUN IS A HARNESS FAILURE
# ---------------------------------------------------------------------------
# Checked before coverage and separately from it. The first version of the
# harness had no completion marker, so three crashing operations were reported
# as three operations with no capture hook -- a coverage number computed over
# scripts that never executed. That number was fiction, and this is the check
# that stops it being reported as fact.
dead <- rc[rc$verdict == "DIDNOTRUN", , drop = FALSE]
check("v39", "operations that never completed", 0, nrow(dead), tol = 0)
if (nrow(dead) > 0) {
    check_true("v39", sprintf("  never completed: %s",
                              paste(dead$op, collapse = ", ")), FALSE)
}

# ---------------------------------------------------------------------------
# 3. THE MECHANISM: a recording survives every script boundary
# ---------------------------------------------------------------------------
# The load-bearing claim of the whole feature. Praat objects outlive the scope
# that made them, script variables do not, so the buffer IS the state -- and a
# step count that never decreases across ten separate invocations is that
# claim measured rather than argued.
check_true("v39", "the step count never fell across the ten invocations",
           all(diff(c(rc$before, rc$after[nrow(rc)])) >= 0))
check_true("v39", "each operation's own before/after is consistent",
           all(rc$after >= rc$before))
# The buffer was still there at the end: the last operation saw a live count.
check_true("v39", "the buffer was live at the last invocation",
           rc$after[nrow(rc)] >= 0)

# ---------------------------------------------------------------------------
# 4. COVERAGE, AS A FLOOR
# ---------------------------------------------------------------------------
# 13 analysis orchestrators and 16 draw procedures ship. Two of them called the
# recorder when this harness was written; a user who switched recording on and
# ran a correlation got an empty script and no warning. All ten operations
# driven here record now, and the floor is stated so that losing one is an
# edit to this line rather than a quieter run.
nRec <- sum(rc$verdict == "recorded")
COVERAGE_FLOOR <- 10L
check_true("v39",
           sprintf("at least %d of %d operations record (observed %d)",
                   COVERAGE_FLOOR, nrow(rc), nRec),
           nRec >= COVERAGE_FLOOR)
# Named, so a future run cannot meet the floor with a different ten.
for (op in OPS) {
    r <- rc[rc$op == op, ]
    if (nrow(r) != 1) next
    check_true("v39", paste(op, "captures a step"), r$verdict[1] == "recorded")
}

# ---------------------------------------------------------------------------
# 5. THE EMITTED SCRIPT
# ---------------------------------------------------------------------------
if (!file.exists(emitted_p)) {
    stop("emitted script not found: ", emitted_p,
         "\n  Run: bash harness/record_e2e/run.sh")
}
em <- readLines(emitted_p, warn = FALSE)

check_true("v39", "the emitted script carries its include block",
           any(grepl("^include ", em)))

# THE MANIFEST, whether the session used one object or five (author ruling,
# 12 Aug 2026 -- one format, always).
check_true("v39", "the emitted script names its objects in a manifest",
           any(grepl('^data1\\$ = "', em)))
check_true("v39", "the manifest carries the type, not just the name",
           any(grepl('^data1\\$ = "(Table|Matrix|TableOfReal) ', em)))
check_true("v39", "the manifest says what each object was used for",
           any(grepl('^data1\\$ = .*;\\s*steps? ', em)))
check_true("v39", "every step selects through the manifest",
           sum(grepl("^selectObject: data[0-9]+\\$$", em)) == nRec)
check_true("v39", "no step selects a hardcoded object type",
           !any(grepl('selected \\("Table"\\)', em)))

# NO MISSING PHRASES. The registry was never loaded by the shipped plugin
# until 12 Aug 2026, and the two phase1 tests that exercised it loaded it
# themselves, so this failure was invisible to every check that existed.
check("v39", "steps whose phrase was not found", 0,
      sum(grepl("MISSING PHRASE", em)), tol = 0)

# The emitted file calls the ORCHESTRATOR, not the wrapper: §8 -- a wrapper
# uses beginPause: and cannot take arguments from runScript:, so a wrapper-level
# call is a line that cannot run anywhere.
check_true("v39", "the emitted analyses call orchestrators, not wrappers",
           any(grepl("^@emlRun[A-Za-z]+: data,", em)) &&
           !any(grepl("^runScript:", em)))
check_true("v39", "the emitted figures call draw procedures",
           any(grepl("^@emlDraw[A-Za-z]+: data,", em)))

if (!exists("EML_SUITE")) {
    eml_report("v39 record coverage: the recorder, driven as a user drives it")
    eml_exit()
}
