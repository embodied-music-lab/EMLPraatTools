# ============================================================================
# v75_legend_single_step.R -- author ruling B, change order 8: one press of
# Draw is one recorded draw step, and the block's note names the axis the
# figure was actually drawn on
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# THE DEFECT, as the audit measured it on 15 August 2026 and as
# harness/formaxis/out/legend_auto/emitted.praat carried it until this change:
#
#     axisYMin = 0.0   ; the y-axis range -- AUTO -- steps 1 (draw), 2 (draw)
#     axisYMax = 0.0   ; on the recorded data it resolved to 195.0000 .. 235.0000
#
#     # --- Step 1 (draw) ---   @emlDrawGroupedViolin: ... axisYMin, axisYMax
#     # --- Step 2 (draw) ---   @emlDrawGroupedViolin: ... axisYMin, axisYMax
#
# One press of Draw. Two steps, the same figure twice -- and the resolved-range
# note naming 235 when the figure on the user's screen was drawn at 275.
#
# WHY THERE WERE TWO STEPS. @emlGraphsDrawWithLegendRoom draws a legend-bearing
# figure, MEASURES where the legend landed and how tall it is, and draws it
# again on a widened axis; the first pass is thrown away. That is not a hack --
# the alternative is for the form to re-derive every legend-bearing type's
# auto-range with its own copy of that type's arithmetic -- and the procedure
# has said so in prose since it was written. What it did not do was tell the
# recorder. NEW-G8-3 found the same shape in the CSV exporter on 15 August
# (every key appearing twice per press), fixed it with @emlCSVMark /
# @emlCSVRewind around the discarded pass, and left the recorder's half open
# because nothing was reading the recorder's half.
#
# WHY THE SECOND HALF IS THE ONE THAT COSTS A READER SOMETHING. The duplicate
# step is visible: a user who opens the file sees the same call twice and can
# delete one. The NOTE is not visible as wrong. @emlRecordColumnManifest quotes
# the FIRST step to use an axis pair, so with two steps sharing one pair the
# note came from the pass that was discarded. Under ruling 10(b) an auto axis
# is emitted as the sentinel 0.0 / 0.0 and that note is the ONLY record in the
# file of where the figure actually sat -- so a user who wants their frame back
# types the note's numbers into the block and gets a frame the figure never
# had. That is what section 3 measures, in bytes.
#
# ============================================================================
# WHAT THIS FILE ASSERTS, AND WHAT IT ASSERTS IT ON
# ============================================================================
# EVERY CHECK BELOW READS THE EMITTED SCRIPT OR A PNG, never the plugin source.
# That is deliberate and it is the difference between this file and a grep:
# @emlRecordMark and @emlRecordRewind could both exist, be called in the right
# order, and still leave two steps in the file -- Praat will not remove a
# Table's only row, and `nocheck` in front of that refusal is a SKIP rather
# than a suppression, so the obvious implementation silently leaves the
# discarded pass in the buffer. It did, on the first run of this change. A
# source check would have called that fixed. Section 5 is the only place a
# source file is opened at all, and it is there to say which primitive is
# doing the work, not to stand in for the artefact.
#
#   1. THE RUN IS NOT VACUOUS. The legend-room loop really made two passes,
#      and making room really moved the axis. Without both, a rig that drew a
#      figure once would satisfy "exactly one draw step" on a broken tree.
#   2. ONE PRESS, ONE STEP. Three integers off the emitted file -- step
#      headings of kind (draw), total step headings, calls to the draw
#      procedure -- because a renderer that emitted one heading over two calls
#      would satisfy any one of them alone. Plus the block's own words: "step
#      1 (draw)" singular, not "steps 1 (draw), 2 (draw)".
#   3. THE NOTE NAMES THE FINAL RANGE, PROVED IN BYTES. The block is edited to
#      the two numbers THE NOTE ITSELF quotes -- nothing else in the file is
#      touched, and the count of changed lines and their position relative to
#      the first step separator are both measured -- and the resulting figure
#      is compared with the one the user got. Byte-identical. On a tree with
#      the defect the note says 235 and the tuned replay is a different
#      picture, which is the break test at the foot of this file.
#   4. THE REWIND DISCARDS THE PASS AND NOTHING ELSE. The same press with an
#      ANOVA in front of it: two steps survive, the analysis is one of them,
#      the draw is step 2, and the note still names the final range. This is
#      also the only sub-leg that reaches @emlRecordRewind's row-removal
#      branch -- a mark at zero rows replaces the buffer object instead.
#   5. THE PRIMITIVE IS GENERAL. @emlRecordMark / @emlRecordRewind name no
#      graph, no legend and no pass, so the next two-pass caller can use them
#      without this file learning what it is for.
#
# WHAT THIS FILE DOES NOT ASSERT, AND SAYS SO IN SECTION 6. An unedited replay
# of an auto legend figure is NOT the picture the user got, and cannot be: the
# emitted script draws once, the legend-room loop belongs to the form, and
# ruling 10(b) emits the request rather than the resolution. The gap is
# measured (legend_plain_vs_orig_over32) and attested rather than hidden, and
# the note is what closes it for a user who wants the frame back.
#
# ARTEFACT
#   harness/record/replay_out/REPLAY.tsv          the measurements
#   harness/record/replay_out/legend_emitted.praat        the file a user runs
#   harness/record/replay_out/legend_after_emitted.praat  the same with a step
#                                                         in front of it
#   Drive with:  bash harness/record/replay.sh
#   $EML_REPLAY_DIR moves the artefact directory, which is how the break
#   tests below read a deliberately broken tree without touching this one.
#   $EML_RECORD_PROC_SRC points section 5 at the recorder core.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
#            https://github.com/embodied-music-lab/PraatGen
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

ID <- "v75"

rp_dir <- Sys.getenv("EML_REPLAY_DIR", unset = "")
if (!nzchar(rp_dir)) rp_dir <- repo_path("harness", "record", "replay_out")
rp <- file.path(rp_dir, "REPLAY.tsv")

if (!file.exists(rp)) {
    stop("replay artefact not found: ", rp,
         "\n  Run: bash harness/record/replay.sh")
}

.tsv <- read.delim(rp, header = FALSE, sep = "\t", quote = "",
                   stringsAsFactors = FALSE, fill = TRUE)
M <- setNames(as.list(trimws(as.character(.tsv[[2]]))),
              trimws(as.character(.tsv[[1]])))
num <- function(k) {
    v <- suppressWarnings(as.numeric(M[[k]]))
    if (is.null(v) || length(v) != 1L || is.na(v)) -1 else v
}
int <- function(k) {
    v <- suppressWarnings(as.integer(M[[k]]))
    if (is.null(v) || length(v) != 1L || is.na(v)) -1L else v
}
str_ <- function(k) if (is.null(M[[k]])) "" else M[[k]]

emitted <- file.path(rp_dir, "legend_emitted.praat")
after   <- file.path(rp_dir, "legend_after_emitted.praat")
rd <- function(p) if (file.exists(p)) readLines(p, warn = FALSE) else character(0)
L_emit  <- rd(emitted)
L_after <- rd(after)

# ===========================================================================
# 0. THE RUN HAPPENED, AND IT IS NOT VACUOUS
# ===========================================================================
# Checked before anything is concluded from it. "Exactly one draw step" is a
# claim that a rig which never engaged the two-pass loop satisfies trivially,
# and a rig whose legend needed no room would never engage it -- so both facts
# that make the leg the reported scenario are integers here, not assumptions.
check_true(ID, "the harness recorded which Praat it drove",
           grepl("^Praat ", str_("praat_version")))
check(ID, "no Praat abort in the legend leg", 0L, int("legend_praat_abort"),
      tol = 0)
check(ID, "no Praat abort in the after-analysis sub-leg", 0L,
      int("legend_after_abort"), tol = 0)
check_true(ID, "the emitted script exists and is a real file",
           length(L_emit) > 20)
check_true(ID, "the after-analysis emitted script exists too",
           length(L_after) > 20)

# THE LOOP REALLY RAN TWICE. legendRoomPass is the form's own counter, read
# out of the process after @emlGraphsDrawWithLegendRoom returned.
check(ID, "the legend-room loop made two passes (this IS the two-pass case)",
      2L, int("legend_passes"), tol = 0)
# AND MAKING ROOM REALLY MOVED THE AXIS. Without this, a figure whose legend
# fitted would leave first pass and second pass drawing the same range, the
# note would be right either way, and section 3 would be a check that cannot
# fail.
check(ID, "the axis the figure was finally drawn on is 195 .. 275",
      195, num("legend_final_min"), tol = 1e-4)
check(ID, "and the ceiling moved from the first pass's 235 to 275",
      275, num("legend_final_max"), tol = 1e-4)

# ===========================================================================
# 1. RULING B -- ONE USER ACTION, ONE EMITTED DRAW STEP
# ===========================================================================
# Three integers rather than one. A renderer that emitted a single step
# heading over two draw calls would satisfy the first; one that emitted two
# headings over one call would satisfy the second; neither is one press, one
# step. They are counted off the file rather than off the TSV where the file
# is the thing a user runs.
n_draw_head <- sum(grepl("^# --- Step [0-9]+ \\(draw\\) ---$", L_emit))
n_all_head  <- sum(grepl("^# --- Step [0-9]+ ", L_emit))
n_draw_call <- sum(grepl("^@emlDrawGroupedViolin: data", L_emit))
check(ID, "the emitted script carries exactly ONE draw step heading",
      1L, n_draw_head, tol = 0)
check(ID, "and exactly one step heading of any kind (nothing else was recorded)",
      1L, n_all_head, tol = 0)
check(ID, "and exactly one call to the draw procedure",
      1L, n_draw_call, tol = 0)
# The same three, as the harness read them, so a disagreement between this
# file's parse and the harness's is visible rather than silently resolved in
# favour of whichever ran second.
check(ID, "the harness counted the same one draw heading",
      1L, int("legend_step_headings"), tol = 0)
check(ID, "the harness counted the same one draw call",
      1L, int("legend_draw_calls"), tol = 0)

# THE BLOCK'S OWN WORDS. This is the string the audit quoted, and it is
# checked as text because text is what a user reads: "steps 1 (draw), 2
# (draw)" is the defect and "step 1 (draw)" is the repair. The renderer picks
# the singular or the plural from whether the step list contains a comma, so
# the word and the list are one fact and either one betrays the other.
check_true(ID,
    sprintf("the block names ONE step in the singular ('%s')",
            str_("legend_block_steps")),
    identical(str_("legend_block_steps"), "step 1 (draw)"))
# AND IT NAMES ONE RUN. The block's variables are named by the run they came
# from, so the discarded first pass has a second way to leave a mark: if it
# had spent a run number on its way out, this figure -- the only one in the
# file -- would come back as run 2, with the block reading axisYMin2 over a
# recording whose first run is nowhere in it.
check_true(ID,
    sprintf("and names it as run 1, so the discarded pass spent no run number ('%s')",
            str_("legend_block_run")),
    identical(str_("legend_block_run"), "1"))
check_true(ID,
    "and no declaration line anywhere in the block says 'steps 1 (draw), 2 (draw)'",
    !any(grepl("steps 1 \\(draw\\), 2 \\(draw\\)", L_emit, fixed = FALSE)))
# The axis pair is still the auto sentinel, which is ruling 10(b) and is what
# makes the note load-bearing. If a future change emitted the resolution here
# instead, the note would stop mattering and section 3 would be measuring
# something else.
check_true(ID, "the block still declares the auto sentinel 0.0 / 0.0",
           identical(str_("legend_block_min"), "0.0") &&
           identical(str_("legend_block_max"), "0.0"))

# ===========================================================================
# 2. THE NOTE NAMES THE FINAL RANGE, NOT THE MEASURING PASS
# ===========================================================================
# The other half of the ruling, read off the note as text first and proved in
# bytes in section 3. 235 is the discarded pass's ceiling; it must appear
# nowhere in the note.
check_true(ID,
    sprintf("the resolved-range note reads 195.0000 .. 275.0000 ('%s')",
            str_("legend_note")),
    identical(str_("legend_note"), "195.0000 .. 275.0000"))
check(ID, "the note's floor is the final floor", 195,
      suppressWarnings(as.numeric(str_("legend_note_min"))), tol = 1e-4)
check(ID, "the note's ceiling is the FINAL ceiling, not the measuring pass's",
      275, suppressWarnings(as.numeric(str_("legend_note_max"))), tol = 1e-4)
check_true(ID,
    "and the discarded pass's ceiling (235) appears nowhere in the emitted file",
    !any(grepl("235", L_emit, fixed = TRUE)))

# ===========================================================================
# 3. THE NOTE IS TRUE IN BYTES -- EDIT THE BLOCK, GET YOUR FIGURE BACK
# ===========================================================================
# This is the check the ruling's test requirement asks for, and it is the one
# a text comparison cannot make. The harness copies the emitted file, replaces
# the two axis declarations with THE TWO NUMBERS THE NOTE ITSELF QUOTES --
# parsed out of the file, so the leg cannot tune the replay to anything the
# file did not say -- runs it, and compares the PNG with the figure the
# recording drew.
#
# THE EDIT IS BOUNDED FIRST. Two lines changed, and none of them at or below
# the first step separator: without that, "the replay matches" could be
# obtained by editing the draw call.
check(ID, "exactly two lines were edited to tune the replay", 2L,
      int("legend_tuned_lines_changed"), tol = 0)
check(ID, "and none of them is at or below the first step separator", 0L,
      int("legend_tuned_edits_below_block"), tol = 0)
# THE COMPARISON IS `cmp`, not a pixel count. v58 uses a threshold because a
# jittered violin's replay differs in forty anti-aliased edges; there is
# nothing here for that to happen to -- the grouped violin draws no random
# marks, and the tuned axis is the recorded axis to the digit -- so byte
# equality is the honest standard and it is met.
check(ID,
      "the tuned replay is BYTE-IDENTICAL to the figure the recording drew",
      1L, int("legend_tuned_is_orig_bytes"), tol = 0)
check(ID, "and zero pixels differ by more than 32 grey levels", 0L,
      int("legend_tuned_vs_orig_over32"), tol = 0)
check(ID, "with a maximum per-pixel difference of zero", 0L,
      int("legend_tuned_vs_orig_max"), tol = 0)
# THE VACUITY GUARD FOR SECTION 3. If the untuned replay were also the
# original, then the tuning changed nothing and the byte equality above says
# nothing about the note. The gap is large -- the legend sits on the data
# without the extra room -- and it is asserted as a floor rather than a value
# because it is a pixel count over a figure, not a quantity this file owns.
check_true(ID,
    sprintf("tuning the block CHANGED the picture (%s px differ untuned)",
            str_("legend_plain_vs_orig_over32")),
    int("legend_plain_vs_orig_over32") > 1000)
# Determinism, which the ruling's "byte-identical on the same data" also asks
# for: the same emitted script, run twice on the same fixture, is the same
# file.
check(ID, "two runs of the emitted script produce byte-identical figures",
      1L, int("legend_replay_deterministic"), tol = 0)
for (k in c("leg_orig_bytes", "leg_replay_bytes", "leg_tuned_bytes")) {
    check_true(ID, paste("a figure was actually written for",
                         sub("_bytes$", "", k)),
               int(k) > 1000)
}

# ===========================================================================
# 4. THE REWIND DISCARDS THE PASS, AND NOTHING THAT PRECEDED IT
# ===========================================================================
# A rewind that emptied the buffer would pass every check above, because the
# leg above marks at ZERO rows -- a figure drawn as the first thing in a
# recording, which is the ordinary case and also the one that hides the
# failure. So the same press with an ANOVA in front of it.
#
# It is also the only sub-leg that reaches @emlRecordRewind's row-removal
# branch. Praat refuses to remove a Table's only row, so a mark at zero rows
# replaces the buffer object and a mark at one row removes rows; two paths,
# and a rig that only ever drove the first would leave the second unexecuted.
n_after_all  <- sum(grepl("^# --- Step [0-9]+ ", L_after))
n_after_draw <- sum(grepl("^# --- Step [0-9]+ \\(draw\\) ---$", L_after))
n_after_anl  <- sum(grepl("^# --- Step [0-9]+ \\(analysis\\) ---$", L_after))
check(ID, "one analysis then one legend figure emits TWO steps in total",
      2L, n_after_all, tol = 0)
check(ID, "exactly one of them is a draw step", 1L, n_after_draw, tol = 0)
check(ID, "and exactly one is the analysis, which the rewind did not touch",
      1L, n_after_anl, tol = 0)
check(ID, "the analysis step still calls the orchestrator that recorded it",
      1L, int("legend_after_anova_calls"), tol = 0)
check(ID, "and the draw step still calls the draw procedure once",
      1L, int("legend_after_draw_calls"), tol = 0)
# THE NUMBERING. The draw is step TWO -- so the rewind put the step counter
# back to the mark rather than to zero, and the analysis kept its place. The
# block's step list and the file's own heading are read separately and
# compared, because the block naming "step 2" over a file whose only heading
# says "Step 1" is a renderer disagreeing with itself.
check_true(ID,
    sprintf("the block names the draw as step 2 ('%s')",
            str_("legend_after_block_steps")),
    identical(str_("legend_after_block_steps"), "step 2 (draw)"))
check_true(ID, "and the file's own step heading agrees it is step 2",
           identical(str_("legend_after_draw_heading"),
                     "# --- Step 2 (draw) ---"))
# The analysis and the draw are one pass of the form here, so they are one
# run: this leg's block is run 1 throughout, and a rewind that had spent a
# number would show up as run 2 over a two-step file.
check_true(ID,
    sprintf("and the block names that step's run as run 1 ('%s')",
            str_("legend_after_block_run")),
    identical(str_("legend_after_block_run"), "1"))
check_true(ID,
    sprintf("the note names the final range here too ('%s')",
            str_("legend_after_note")),
    identical(str_("legend_after_note"), "195.0000 .. 275.0000"))

# ===========================================================================
# 5. THE PRIMITIVE IS THE RECORDER'S, AND IT KNOWS NOTHING ABOUT LEGENDS
# ===========================================================================
# The only source reading in this file, and it is not a substitute for
# anything above: every behavioural claim is already made against the emitted
# script. What it adds is WHERE the behaviour lives. The change order asked
# for a primitive "the next two-pass caller can use without knowing about
# legends", and a repair that special-cased the legend inside the recorder
# would satisfy every check in sections 1-4 while making the next caller write
# it again.
rsrc <- Sys.getenv("EML_RECORD_PROC_SRC", unset = "")
if (!nzchar(rsrc)) rsrc <- repo_path("plugin", "stats", "eml-record.praat")
if (check_true(ID, "the recorder core is present", file.exists(rsrc))) {
    R <- readLines(rsrc, warn = FALSE)
    code <- R[!grepl("^[[:space:]]*[#;!]", R)]
    check(ID, "@emlRecordMark is declared exactly once", 1L,
          sum(grepl("^procedure emlRecordMark$", code)), tol = 0)
    check(ID, "@emlRecordRewind is declared exactly once", 1L,
          sum(grepl("^procedure emlRecordRewind$", code)), tol = 0)
    # THE BODIES, on stripped code, because this repository's house style puts
    # a long paragraph above every repair and a sibling check went green this
    # week on a tree where the code had been reverted and the paragraph left
    # behind.
    body <- function(name) {
        i <- grep(paste0("^procedure ", name, "$"), code)
        if (!length(i)) return(character(0))
        j <- grep("^endproc$", code)
        j <- j[j > i[1]]
        if (!length(j)) return(character(0))
        code[i[1]:j[1]]
    }
    bm <- body("emlRecordMark"); br <- body("emlRecordRewind")
    check_true(ID, "the mark remembers the buffer's row count",
               any(grepl("emlRecordMark_rows[[:space:]]*=[[:space:]]*Get number of rows",
                         bm)))
    check_true(ID, "and the step counter beside it",
               any(grepl("emlRecordMark_n[[:space:]]*=[[:space:]]*emlRecordN", bm)))
    check_true(ID, "the rewind removes rows from the buffer",
               any(grepl("^[[:space:]]*Remove row:", br)))
    # THE COUNTER IS WHAT THE RENDERER NUMBERS STEPS FROM. Breaking exactly
    # this line (harness/record/replay_break.sh's rows_only leg) leaves the
    # right number of steps carrying the wrong numbers: the only step in the
    # file becomes "# --- Step 2 (draw) ---" and, with an ANOVA in front of
    # it, step 3 of two. Section 4's heading check is the behavioural half.
    #
    # IT DOES NOT BREAK THE AXIS STAMP, and that was measured rather than
    # assumed: @emlGraphsStampAxisRequest writes emlRecordN + 1 and
    # @emlRecordAxisRequest compares against emlRecordN + 1, so both sides read
    # the same counter and a counter left one too high is still consistent
    # with itself. The rows_only tree still emits the user's own 0.0 / 0.0.
    check_true(ID, "and puts the step counter back, which is what numbers the steps",
               any(grepl("emlRecordN[[:space:]]*=[[:space:]]*emlRecordMark_n", br)))
    # THE BUFFER CAN BE REPLACED, SO THE SELECTION SNAPSHOT HAS TO FOLLOW IT.
    # @emlRecordStep leaves the buffer selected, so a caller that rewinds with
    # that selection live would have this procedure restore an object it had
    # just removed -- "No object with number N" in the middle of a draw. Found
    # by the rewind_after_draw break, which is the placement where that IS the
    # live selection.
    check_true(ID, "and remaps the selection snapshot when it replaces the buffer",
               any(grepl("\\.sel0\\[\\.i\\][[:space:]]*=[[:space:]]*emlRecordBufferId", br)))
    # NEITHER PROCEDURE NAMES WHAT IT IS FOR. Executable lines only: the
    # headers above them talk about legends at length, and should.
    for (nm in c("emlRecordMark", "emlRecordRewind")) {
        b <- body(nm)
        check(ID, sprintf("@%s's code names no legend, pass or graph", nm),
              0L, sum(grepl("legend|Legend|graph_type|emlGraphs", b)), tol = 0)
    }
    # AND THE RECORDER DOES NOT REACH BACK INTO THE FORM.
    check(ID, "the recorder calls nothing in the graphs form", 0L,
          sum(grepl("@emlGraphs", code)), tol = 0)
}

# THE CALLER'S HALF, in the file that owns the two-pass loop. One mark before
# the loop and one rewind inside it, and the rewind ABOVE the dispatch: the
# stamp is re-taken in @emlGraphsDispatchDraw from emlRecordN, so a rewind
# that ran after the draw would restore the counter too late to matter.
fsrc <- Sys.getenv("EML_GRAPHS_FORM_SRC", unset = "")
if (!nzchar(fsrc)) fsrc <- repo_path("plugin", "graphs", "eml-graphs-form.praat")
if (check_true(ID, "the graphs form is present", file.exists(fsrc))) {
    F <- readLines(fsrc, warn = FALSE)
    fcode <- F[!grepl("^[[:space:]]*[#;!]", F)]
    check(ID, "the form takes the record mark exactly once", 1L,
          sum(grepl("^[[:space:]]*@emlRecordMark$", fcode)), tol = 0)
    check(ID, "and rewinds exactly once", 1L,
          sum(grepl("^[[:space:]]*@emlRecordRewind$", fcode)), tol = 0)
    i_mark <- grep("^[[:space:]]*@emlRecordMark$", fcode)
    i_rew  <- grep("^[[:space:]]*@emlRecordRewind$", fcode)
    i_disp <- grep("^[[:space:]]*@emlGraphsDispatchDraw$", fcode)
    i_disp <- if (length(i_rew)) i_disp[i_disp > i_rew[1]] else integer(0)
    check_true(ID, "the mark is taken before the rewind, outside the loop",
               length(i_mark) == 1L && length(i_rew) == 1L && i_mark < i_rew)
    check_true(ID,
        "and the rewind runs BEFORE the dispatch it precedes, so the axis stamp is re-armed",
        length(i_rew) == 1L && length(i_disp) >= 1L && i_rew[1] < i_disp[1])
    # The CSV pair is still there. This change sits beside NEW-G8-3, not on
    # top of it, and a merge that replaced one with the other would put the
    # duplicate-export defect back.
    check(ID, "the CSV collector's own mark is untouched", 1L,
          sum(grepl("^[[:space:]]*@emlCSVMark$", fcode)), tol = 0)
    check(ID, "and its rewind too", 1L,
          sum(grepl("^[[:space:]]*@emlCSVRewind$", fcode)), tol = 0)
}

# ===========================================================================
# 6. WHAT THIS CHANGE DOES NOT FIX, STATED
# ===========================================================================
attest(ID,
    "an UNEDITED replay of an auto legend figure is not the picture the user got, and cannot be",
    sprintf("measured this run: %s pixels differ by more than 32 between the plain replay and the original. The emitted script draws once; the two-pass loop is @emlGraphsDrawWithLegendRoom's and lives in the form, which an emitted file cannot include. Ruling 10(b) emits the REQUEST rather than the resolution, so an auto replay resolves to the axis the figure had before room was made for the legend -- 195 .. 235. The note is what closes the gap for a user who wants the frame back, and section 3 proves it closes it exactly.",
            str_("legend_plain_vs_orig_over32")))
attest(ID,
    "the figure the user gets is unchanged by this change",
    "harness/record/replay_break.sh records LEG_ORIG.png's md5 for every tree it drives, and on 16 August 2026 all six break trees -- including no_wiring, which is the defect itself, with neither call present -- produced 04e0e6457ea60091222ee4c3e420ae5d, the same md5 as the working tree. The repair is recorded state only; nothing in it reaches the drawing layer, and that is an artefact in harness/record/replay_out/breaks/BREAKS.tsv rather than an argument.")
attest(ID,
    "harness/formaxis/out/legend_auto and legend_typed were re-driven and their blocks changed",
    "legend_auto: 'steps 1 (draw), 2 (draw)' -> 'step 1 (draw)', and the note 195.0000 .. 235.0000 -> 195.0000 .. 275.0000. legend_typed: the note 100.0000 .. 300.0000 -> -100.0000 .. 300.0000, which is where that figure was drawn -- its legend took room BELOW a typed floor of 100. validate/v68 reads both files and is green on the new ones; its attestation that this defect was open has been rewritten.")

if (!exists("EML_SUITE")) {
    eml_report("v75 one press of Draw, one recorded step")
    eml_exit()
}
