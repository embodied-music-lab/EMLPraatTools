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
# harness/record_e2e/run.sh crosses it -- 36 operations through `runScript:`,
# separate scopes in one process -- and every defect below was found by it and
# by nothing else:
#
#   - three of its own operations were CRASHING and being reported as
#     "recorded nothing", so the first coverage number it produced was fiction;
#   - the draw capture hook could never fire from a menu invocation, so every
#     figure drawn from the menu went unrecorded while the recording ran;
#   - the phrase table was never loaded by the shipped plugin, so every
#     recording a user could make said [MISSING PHRASE] on every step;
#   - the recorder asked a Sound for its number of rows, so all four acoustic
#     draw procedures DIED inside a procedure whose contract is to be inert --
#     and only with recording switched on, which no unit test does;
#   - the session's own provenance -- when it was recorded, and on what -- was
#     held in script variables, so a recording made one menu command at a time
#     reached flush with all of them empty. The emitted file said "NOT
#     RECORDED. Nothing in this session named the object it ran on" three
#     lines above a manifest naming that object.
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
# EVERY HOOKED OPERATION, NOT A SAMPLE OF THEM. Thirteen analysis
# orchestrators and fourteen draw procedures carry a capture hook, and all
# twenty-seven are driven. Four of the draws take an acoustic object rather
# than a Table -- waveform a Sound, f0contour a Pitch, spectrum a Spectrum,
# ltas an Ltas -- and they are in this list because they are the ones that
# found the recorder asking a Sound for its number of rows.
#
# THE LAST EIGHT ARE THE FIVE AUTO-CONVERSIONS THE GRAPHS FORM PERFORMS.
# Author, 12 Aug 2026: "fo, waveform, spectrum, and LTAS will all also run
# from just a sound. They auto convert." The four above are handed a ready
# made Pitch/Spectrum/Ltas, which is the API-level call; sound2*, spectrum2*,
# tor2table and matrix2table go through @emlConvertForGraph, which is what the
# menu does. All five conversions lived inline in a beginPause: loop until
# 12 Aug 2026 and could only be reached through a driven dialog, so none had
# ever been driven -- and the recorder was wrong on every one of them.
#
# `bridge` IS THE OTHER DIRECTION OF A BIDIRECTIONAL DESIGN. Stats can lead
# to a graph and a graph can lead to stats -- @emlBridgeGroupComparison runs
# the t-test, Mann-Whitney, ANOVA, Kruskal-Wallis, Tukey and Dunn that a
# figure's brackets are drawn from, reached from four sites in the graphs
# form. Capture hooks were added to all thirteen stats orchestrators on
# 12 Aug 2026 and not to the bridge, so for a few hours the SAME analysis
# recorded from the stats menu and vanished from the figure path. Before that
# neither recorded; fixing one half is what created the asymmetry.
#
# The two Table conversions differ in one respect that is pinned separately:
# they produce a working object the session KEEPS, where the acoustic ones
# produce an intermediate the form removes. Both still have to name the
# object the user selected.
OPS <- c("anova", "twogroup", "kw", "descriptive", "normality",
         "correlation", "regression", "pairwise", "twoway", "paired",
         "reliability", "rm", "friedman",
         "violin", "scatter", "histogram", "timeseries", "timeseriesci",
         "spaghetti", "barchart", "boxplot", "gviolin", "gbox",
         "waveform", "f0contour", "spectrum", "ltas",
         "sound2f0", "sound2spectrum", "sound2ltas",
         "spectrum2ltas", "spectrum2sound", "spectrum2f0",
         "tor2table", "matrix2table",
         "bridge")
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
# step count that never decreases across 36 separate invocations is that
# claim measured rather than argued.
check_true("v39", "the step count never fell across the 36 invocations",
           all(diff(c(rc$before, rc$after[nrow(rc)])) >= 0))
check_true("v39", "each operation's own before/after is consistent",
           all(rc$after >= rc$before))
# The buffer was still there at the end: the last operation saw a live count.
check_true("v39", "the buffer was live at the last invocation",
           rc$after[nrow(rc)] >= 0)

# ---------------------------------------------------------------------------
# 4. COVERAGE, AS A FLOOR
# ---------------------------------------------------------------------------
# 13 analysis orchestrators and 16 draw procedures ship. TWO of them called the
# recorder when this harness was written; a user who switched recording on and
# ran a correlation got an empty script and no warning. Twenty-seven are hooked
# and all thirty-six record, and the floor is stated so that losing one is an
# edit to this line rather than a quieter run.
#
# The two draws not in this population are the ones with no standalone caller
# to drive -- they are reached only through the graphs form's own composition
# path, which harness/gui_e2e covers and v35 asserts on.
nRec <- sum(rc$verdict == "recorded")
COVERAGE_FLOOR <- 36L
check_true("v39",
           sprintf("at least %d of %d operations record (observed %d)",
                   COVERAGE_FLOOR, nrow(rc), nRec),
           nRec >= COVERAGE_FLOOR)
# Named, so a future run cannot meet the floor with a different 36.
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

# SINGLE-BYTE TEXT, which is a real property and not a formality. Praat writes
# a text file as UTF-16 the moment its content is not pure ASCII, and the
# plugin's own refusal string for the LMM path carried an em dash -- so a
# session that touched that path emitted a UTF-16 .praat file. It ran; it was
# also an undiffable blob in git and mojibake to every check below, ALL OF
# WHICH WOULD HAVE PASSED VACUOUSLY by matching nothing. Checked on the raw
# bytes, because every assertion after it depends on the answer.
.raw <- readBin(emitted_p, "raw", n = file.info(emitted_p)$size)
check_true("v39", "the emitted script is single-byte text, not UTF-16",
           length(.raw) > 0 && !any(.raw == as.raw(0)))

check_true("v39", "the emitted script carries its include block",
           any(grepl("^include ", em)))

# ---------------------------------------------------------------------------
# PROVENANCE SURVIVES THE SCRIPT BOUNDARY TOO, and it did not.
# ---------------------------------------------------------------------------
# The buffer re-attaches and the steps survive; emlRecordStamp$ and
# emlRecordHeaderInput$ were ordinary script variables and did not. A
# recording made the way a user makes one therefore emitted an empty
# timestamp and a header block reading "NOT RECORDED. Nothing in this session
# named the object it ran on" -- directly above a manifest naming it. The file
# contradicted itself, and every test passed because every test recorded in
# ONE scope. Both are now rows in a Table that outlives the scope.
# \\S FIRST, and it is not pedantry: the empty stamp this pins produced the
# line "#   --  recorded on Praat 6.6.30", which a `.+` matched happily. The
# first cut of this check passed on the exact artefact it was written to
# reject, and the break test is what said so.
check_true("v39", "the emitted script carries the session's timestamp",
           any(grepl("^# \\S.* -- +recorded on Praat ", em)))
check_true("v39", "the emitted script names the object it was recorded on",
           any(grepl("^# Input: (Table|Matrix|TableOfReal) ", em)))
check_true("v39", "the header does not deny what the manifest states",
           !any(grepl("^# NOT RECORDED\\.", em)))
check_true("v39", "the header carries the object's shape",
           any(grepl("^# Input: .* -- [0-9]+ rows, [0-9]+ columns", em)))

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

# ---------------------------------------------------------------------------
# THE AUTO-CONVERSION IS IN THE RECORD, AND NAMES THE SOUND
# ---------------------------------------------------------------------------
# Three of the four acoustic figures are normally reached from a Sound: the
# plugin converts, draws, and REMOVES the intermediate at the end of the pass.
# The capture hook is inside the draw procedure, so what it saw was the
# intermediate -- and every acoustic figure recorded from the menu wrote
# `data1$ = "Pitch tone"` into the manifest, an object the plugin had just
# deleted and the user never made. The emitted script could not run and told
# its reader to open something that did not exist.
check_true("v39", "the conversion from a Sound is recorded as its own step",
           sum(grepl("^# --- Step [0-9]+ \\(convert\\) ---$", em)) >= 8)
check_true("v39", "the manifest names the Sound, not the intermediate",
           any(grepl('^data[0-9]+\\$ = "Sound ', em)))
# THE PRECISE FORM, because the loose one above passes either way: the
# waveform step is handed a Sound directly, so "Sound" appears in the
# manifest whether or not the conversion is attributed correctly. What
# distinguishes a fixed run from a broken one is that the figure FOLLOWING a
# convert selects nothing -- the object it uses is in `data` and has no name
# that outlives the session. Verified by breaking it: with the attribution
# disabled the derived draws take a manifest slot of their own and this fails.
.hdr <- grep("^# --- Step [0-9]+ \\(", em)
.after_convert_has_select <- vapply(
    grep("^# --- Step [0-9]+ \\(convert\\) ---$", em),
    function(i) {
        k <- .hdr[.hdr > i]
        if (!length(k)) return(NA)
        a <- k[1]
        b <- if (length(k) > 1) k[2] - 1L else length(em)
        any(grepl("^selectObject: data[0-9]+\\$$", em[a:b]))
    }, logical(1))
check_true("v39", "the figure after a conversion selects nothing of its own",
           length(.after_convert_has_select) >= 8 &&
           !any(.after_convert_has_select, na.rm = TRUE))
check_true("v39", "every converted-from type is named in the manifest",
           all(vapply(c("Sound", "Spectrum", "TableOfReal", "Matrix"),
                      function(t) any(grepl(sprintf('^data[0-9]+\\$ = "%s ', t),
                                            em)), logical(1))))
check_true("v39", "the two-step conversion emits both steps and cleans up",
           any(grepl("^tmp = To Sound$", em)) &&
           any(grepl("^removeObject: tmp$", em)))
check_true("v39", "the conversion carries its parameters",
           any(grepl("^data = To Pitch \\(filtered autocorrelation\\): ", em)))
# REPLACED, because it fired on correct output (12 Aug 2026). It tried to spot
# an intermediate in the manifest by matching a manifest line naming a Pitch,
# Spectrum or Ltas whose steps include a draw -- but a session may legitimately
# draw a Spectrum directly AND convert from that same Spectrum, and the fixture
# does exactly that. The precise assertion is the one below it: the figure
# AFTER a conversion selects nothing of its own. A check that fails on a
# correct run teaches people to ignore it.
# A convert step is followed immediately by the figure that needed it, with no
# manifest select in between: the object it produced is in `data` and cannot
# be named, because it does not survive the session.
.iconv <- grep("^# --- Step [0-9]+ \\(convert\\) ---$", em)
.next_sel <- vapply(.iconv, function(i) {
    j <- i + 1L
    while (j <= length(em) && !grepl("^# --- Step ", em[j])) {
        if (grepl("^selectObject: data[0-9]+\\$$", em[j])) return(TRUE)
        j <- j + 1L
    }
    FALSE
}, logical(1))
check_true("v39", "each convert step selects its source through the manifest",
           length(.iconv) >= 8 && all(.next_sel))

# BOTH DIRECTIONS OF THE BIDIRECTIONAL PATH ARE IN THE RECORD. Stats-to-graph
# and graph-to-stats are one feature, and a recording that captures an ANOVA
# from the menu but not the identical ANOVA behind a figure's brackets is
# half a feature. Named rather than counted, so losing either is an edit here.
check_true("v39", "the stats-menu path records its analyses",
           any(grepl("^@emlRun[A-Za-z]+: data,", em)))
check_true("v39", "the graph-to-stats path records its analyses too",
           any(grepl("^@emlBridgeGroupComparison: data,", em)))

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
