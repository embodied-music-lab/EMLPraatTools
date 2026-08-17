# ============================================================================
# v58_recorder_replay.R -- what a recorded workflow does when you RUN it
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# THE RULING THIS FILE IMPLEMENTS (author, 14 August 2026):
#
#     "Recorder replay: NON-INTERACTIVE -- just output the output. A replayed
#      recording must not reopen any dialog. This is the SPSS model (dialogs
#      author syntax; running syntax is headless), same as Stata do-files /
#      R scripts / Praat's own paradigm. Recorded save steps embed the chosen
#      folder and base name as literals; REGENERATE the timestamp at replay;
#      users who want different settings run the workflow fresh, not the
#      recording."
#
# WHY THIS FILE EXISTS AT ALL, which is a separate question from the ruling.
# The recorder had two validators before this one and both of them measure the
# EMISSION -- v39 that a session's steps reach the buffer and the file, v40
# that the draw layer stays clean when the recorder is absent. Neither runs the
# file it produced against anything. The audit ran it, and found that an
# advanced-mode annotated, jittered violin comes back as a plain violin: the
# bracket gone, the points gone, the numbers underneath perfect. A recorder
# exists to preserve a user's work, and the figure is the part of that work
# that a recorded script was silently losing.
#
# FOUR MECHANISMS, AND NOT ONE OF THEM IS AN ERROR:
#
#   1. THE ADVANCED SETTINGS ARE NOT ARGUMENTS. "Show jittered points" is
#      prev_violinShowJitter, a global the graphs form sets and the draw
#      procedure reads. The recorded call carries every argument correctly and
#      still draws a different figure, because what made the figure advanced
#      was never an argument to record.
#
#   2. THE BRACKET IS DRAWN BY A THIRD PARTY. Neither the recorded bridge step
#      nor the recorded draw step draws it: @emlGraphsPostDispatchAnnotations
#      does, in eml-graphs-form.praat, after the draw returns. An emitted file
#      cannot include the form -- including it runs it -- so a recorded
#      annotated figure was structurally incapable of coming back annotated.
#
#   3. THE SAVE STEP REPLAYED AS A DIALOG. It was recorded as a call back into
#      @emlSavePanel, so a recorded workflow containing a save could not run
#      unattended at all; and the panel re-proposed "old stem + new stamp", so
#      each replay generation grew another timestamp onto the base name.
#
#   4. THE INCLUDE BLOCK PROMISED A PORTABILITY IT DID NOT HAVE. The header
#      said home-relative; the eleven include lines were machine-absolute. The
#      rewrite that makes them relative ran in @emlRecordBegin's scope and died
#      with it, so in real menu-driven use -- one command per operation -- the
#      claim was never true.
#
# WHAT COULD NOT HAVE CAUGHT ANY OF IT, and why:
#
#   * harness/record/roundtrip_graph.sh replays a recorded figure and compares
#     the PNGs byte for byte, which is exactly the right check. It draws a
#     BEGINNER violin. annotate is 0 and prev_violinShowJitter is 0 on that
#     journey, so both defects are outside it by construction, and it was
#     green throughout.
#   * harness/record_e2e drives 38 operations across script boundaries and
#     v39 pins every one of them. It asserts what the emitted file SAYS. Every
#     assertion it makes passed on a file whose figure did not reproduce,
#     because the missing thing was a line that was never written -- and no
#     grep finds a line that is absent unless someone knew to look for it.
#   * A file-set check cannot separate the save cases either, and this is the
#     v51 problem again: a replay through the reopened panel and a replay
#     through the headless writer BOTH leave a tidy, a glance and a report on
#     disk under one base name. Same count, same suffixes, same shapes.
#
#   WHAT DOES SEPARATE THEM is an integer, as in v51. For the save it is the
#   number of _YYYYMMDD_HHMMSS stamps in the worst-off written name: one is
#   the panel's convention, two is the accretion. For the figure it is the
#   count of pixels differing by more than 32 grey levels between the replay
#   and each of TWO references -- the original, and a deliberately un-advanced
#   draw of the same data at the same axis. 0 against the original and 2740
#   against the bare one is a faithful replay; the reverse is the defect. That
#   is an identification rather than an inequality: it says which way it
#   failed, not merely that it did.
#
# WHY NOT `cmp`, WHICH IS THE HOUSE RULE FOR A RECORDED FIGURE. Because a
# perfect replay fails it here, and that was measured rather than assumed. The
# jitter x-offsets come from randomUniform, so the harness seeds Praat's
# generator identically before each draw -- without that the two figures are
# not the same picture and no comparison of them means anything. What survives
# the seed is the recorder emitting a resolved axis to six decimal places: the
# replayed draw maps world coordinates through an axis differing in the last
# bits and anti-aliases each mark's edge fractionally differently. Forty
# pixels, one per point, at most 4 of 255. The threshold of 32 sits in the gap
# between that and the 254-level differences of a missing bracket.
#
# ---------------------------------------------------------------------------
# THE SECOND RULING THIS FILE IMPLEMENTS (author, 15 August 2026) -- RULING 9:
#
#     "Lift column names into the editable header block. One variable per
#      distinct ROLE the recording used, with the steps referencing the
#      variables. The block's promise -- nothing below this block names an
#      object -- extends to: nothing below this block names a column."
#
# WHAT THE DEFECT LOOKED LIKE. The block gathered object names and stopped:
#
#     data1$ = "Table vt"   ; steps 1 (analysis), 2 (draw)
#
# under the sentence "edit a name to run the same workflow on other data".
# Every column stayed a literal at its call site --
# `@emlBridgeGroupComparison: data, "val", "grp", ...` -- so a user handed a
# same-shape table with different headers had to hunt literals through the
# steps, which is the hunt the block exists to abolish. The block was telling
# the truth about objects and making a promise about workflows it could not
# keep.
#
# THE ROLE RULE, WHICH IS THE ONLY INTERESTING DECISION IN IT. The identity of
# a variable is the PAIR (role, name), not the name:
#
#   * the same column used for the same purpose in two steps is ONE variable --
#     a value column analysed and then plotted is one decision, and two
#     variables would let the figure stop describing the analysis;
#   * the same STRING used as a two-way factor in one step and a plot's
#     grouping column in another is TWO, because they are two slots that agree
#     today and a user may move one and not the other;
#   * two different columns in one role are two variables of that role,
#     numbered in first-use order.
#
# And a figure's axis LABEL is not a column at all, even when it reads "val"
# because the form defaulted it from the column name. It is text drawn on a
# picture; it stays where the user typed it, and the block says so.
#
# WHAT COULD NOT HAVE CAUGHT IT, AND WHAT STILL CANNOT. Nothing in this suite
# reads an emitted script for what it PROMISES, and no grep ever will: a
# renderer that gathers every column name into a perfect block and leaves the
# steps below reading their own literals passes every static assertion anybody
# would think to write -- the variables are there, spelled right, with the
# right values -- and is worth exactly nothing, because editing them changes
# nothing. Section 8 therefore does not grep the block. It EDITS the block, on
# five lines, and runs the file against a table whose columns are named
# differently; a script that still names the old columns cannot run at all.
#
# ---------------------------------------------------------------------------
# THE THIRD RULING (author, 15 August 2026) -- RULING 4:
#
#     "The recording buffer reads as load-bearing. Deleting it silently stops
#      recording. NO per-step signal: rename the buffer to a name that tells a
#      user it is not scratch, and keep the corrected Stop-command message."
#
# The object was called emlRecordBuffer. Its existence IS the recording -- see
# @emlRecordInit -- so a user tidying the Objects window ends their session,
# and nothing in Praat can tell a script that an object was removed. The ruling
# refuses the obvious remedy (a reminder per step) because that noise would
# land in the Info window the user is reading results in. What is left is the
# name itself, which is in front of the user at the exact moment the mistake is
# available to them, and the two Stop commands, which are all that can explain
# it afterwards.
#
# A VALIDATOR CANNOT READ ENGLISH, and this file does not pretend to. What
# section 9 pins is the half that is falsifiable: that the name the recorder
# CREATES is the name the re-attach LOOKS FOR and the name the Stop commands
# QUOTE, in every one of the four files that mention it. A half-finished rename
# is the failure that matters here and it is silent in the worst way -- a
# recorder that creates one object and re-attaches to another starts a fresh
# recording on every menu command, so each emitted script holds one step and
# no error is ever raised.
#
#     bash harness/record/replay.sh
#     Rscript validate/v58_recorder_replay.R
#
# Input: <replay>/REPLAY.tsv, two tab-separated fields, no header. <replay> is
#        $EML_REPLAY_DIR, default harness/record/replay_out. A missing artefact
#        is a HARD STOP and not a skip -- v27's reason, and v39's: "the driver
#        never ran this" is precisely what a quietly shrinking suite hides.
#        $EML_RECORD_SRC overrides the recorder source read by the static
#        checks, and $EML_OUTPUT_SRC the save emitter they are cross-checked
#        against, both for break tests. $EML_RECORD_PROC_SRC is the recorder
#        core, $EML_RECORD_START_SRC and $EML_RECORD_OPEN_SRC the other two
#        commands that name the recording object, and $EML_RECORD_CALLSITES a
#        plugin directory whose orchestrators the recorder's column map is
#        checked against.
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
    v <- suppressWarnings(as.integer(M[[k]]))
    if (is.null(v) || length(v) != 1L || is.na(v)) -1L else v
}
str_ <- function(k) if (is.null(M[[k]])) "" else M[[k]]

check_true("v58", "the harness recorded which Praat it drove",
           grepl("^Praat ", str_("praat_version")))

# ---------------------------------------------------------------------------
# 0. THE RUN IS NOT VACUOUS
# ---------------------------------------------------------------------------
# Checked before anything is concluded from it, for v51's reason: a drive that
# silently stayed in beginner mode would produce a perfectly clean chain and
# prove nothing, which is the failure this whole file is about. If the original
# figure and the un-advanced reference are the same picture then the advanced
# settings never took, and every comparison below is satisfied by a plain
# violin agreeing with a plain violin.
check_true("v58",
           sprintf("the advanced figure really is advanced (%s px differ from the bare draw)",
                   str_("adv_orig_vs_bare_over32")),
           num("adv_orig_vs_bare_over32") > 500)
for (k in c("adv_orig_bytes", "adv_bare_bytes", "adv_replay_bytes")) {
    check_true("v58", paste("a figure was drawn for", sub("_bytes$", "", k)),
               num(k) > 1000)
}
# No leg may have aborted. Praat prints "not performed or completed" and quotes
# the plugin's own source when it does, which is the shape NEW-G11-4 names --
# and a leg that died halfway can leave artefacts that look like a pass.
for (k in c("adv_praat_abort", "save_praat_abort", "folder_praat_abort",
            "retarget_praat_abort")) {
    check("v58", paste("no Praat abort in the", sub("_praat_abort", "", k), "leg"),
          0L, num(k), tol = 0)
}

# ---------------------------------------------------------------------------
# 1. NEW-G11-2 -- THE ADVANCED FIGURE REPLAYS
# ---------------------------------------------------------------------------
# The identification, in two halves. Both are needed: "matches the original"
# alone would be satisfied if the harness had drawn a bare figure twice, and
# "differs from the bare one" alone would be satisfied by any wrong figure.
check("v58",
      "the replayed figure IS the original figure (px differing by >32)",
      0L, num("adv_replay_vs_orig_over32"), tol = 0)
check_true("v58",
           sprintf("the replayed figure is NOT the un-advanced one (%s px)",
                   str_("adv_replay_vs_bare_over32")),
           num("adv_replay_vs_bare_over32") > 500)
# THE RESIDUAL IS STATED, NOT HIDDEN. A faithful replay still differs from its
# original in a few anti-aliased pixel edges, for the reason in the header. If
# that ever climbs, the six-decimal axis emission has stopped being enough and
# somebody should know before a threshold quietly absorbs it.
check_true("v58",
           sprintf("the residual difference is anti-aliasing only (max %s of 255)",
                   str_("adv_replay_vs_orig_max")),
           num("adv_replay_vs_orig_max") >= 0 && num("adv_replay_vs_orig_max") <= 16)

# THE STATIC WITNESSES, deliberately independent of the picture. A change that
# made the original and the replay wrong in the SAME way would satisfy every
# comparison above; these would not follow it there.
check_true("v58", "the emitted script restores the jitter switch it drew with",
           num("emit_jitter_lines") >= 1)
check_true("v58", "the emitted script restores the annotate switch",
           num("emit_annotate_lines") >= 1)
check_true("v58", "the emitted script draws the annotation the form drew",
           num("emit_bracket_render") >= 1)
# Clearing matters for the SECOND figure in a file, not the first: without it
# a later bridge adds its bracket to whatever the previous one left behind.
check_true("v58", "the emitted script clears the annotation state",
           num("emit_clear_annotations") >= 1)

# ---------------------------------------------------------------------------
# 2. THE RULING -- NON-INTERACTIVE REPLAY
# ---------------------------------------------------------------------------
# "A replayed recording must not reopen any dialog." Held as an absolute on
# the emitted text, both for the figure session and for the save session,
# because the ruling is an absolute.
check("v58", "the emitted figure script opens no dialog",
      0L, num("emit_beginpause"), tol = 0)
check("v58", "the emitted save script opens no dialog",
      0L, num("save_emit_beginpause"), tol = 0)
check("v58", "the recorded save no longer replays through the Save panel",
      0L, num("save_emit_savepanel"), tol = 0)
check_true("v58", "the recorded save replays through the headless writer",
           num("save_emit_replaysave") >= 1)

# THE TIMESTAMP IS REGENERATED, AND THE INTEGER IS THE WHOLE RESULT. The
# recorded stem carried a stamp; the replay must strip it and take a fresh
# one. Two stamps in a name is the accretion the ruling dissolves.
check("v58", "each replayed output carries exactly ONE timestamp",
      1L, num("save_max_stamps"), tol = 0)
check("v58", "one base name for the whole replayed save (the panel's rule)",
      1L, num("save_distinct_stems"), tol = 0)
check_true("v58",
           sprintf("the replayed save actually wrote its outputs (%s files)",
                   str_("save_files")),
           num("save_files") >= 3)
check_true("v58", "the replayed report is a real report, not an empty file",
           num("save_report_bytes") > 500)

# ---------------------------------------------------------------------------
# 3. THE NUMBERS DO NOT REGRESS
# ---------------------------------------------------------------------------
# The audit's one unqualified finding about this feature is that the recorder's
# numbers replay perfectly. Everything in this file changes what a replay DRAWS
# and WRITES; nothing in it may change what it COMPUTES, and the cheapest proof
# is that the two transcripts agree line for line on the statistics.
check_true("v58", "the analysis printed statistics in both legs",
           num("save_stat_lines") >= 3)
check("v58", "the replayed analysis prints the same statistics as the original",
      1L, num("save_stats_identical"), tol = 0)

# ---------------------------------------------------------------------------
# 4. NEW-G11-3 -- PROVENANCE BELONGS TO THE LIVE SESSION
# ---------------------------------------------------------------------------
# The sequence is the audit's: remove the buffer from the Objects window, which
# silently ends the recording and orphans the meta table; start a new session;
# then plant a second meta table naming a session that is gone, which is what
# a user reaches by deleting the wrong one of two identically named rows.
check("v58", "removing the buffer leaves exactly one orphaned record table",
      1L, num("meta_orphan_after_buffer_kill"), tol = 0)
check("v58", "the next recording sweeps the orphan rather than inheriting it",
      1L, num("meta_tables_after_new_begin"), tol = 0)
check("v58", "the emitted script carries the LIVE session's stamp",
      1L, num("meta_emitted_has_live_stamp"), tol = 0)
check("v58", "the emitted script carries no trace of the dead session's stamp",
      0L, num("meta_emitted_has_dead_stamp"), tol = 0)
check("v58", "the emitted script does not name the dead session's object",
      0L, num("meta_emitted_names_dead_table"), tol = 0)
check_true("v58", "the emitted header line carries a non-empty timestamp",
           grepl("^# \\S.* -- +recorded on Praat ", str_("meta_emitted_stamp_line")))

# THE SEQUENCE RUN TO ITS END, which is where the audit actually was. Having
# planted the second store the user then deleted the LIVE one -- two rows with
# the same name, and they picked the wrong one -- leaving a session whose only
# reachable store belongs to a recording that is gone. Nothing can recover the
# lost start time; what the recorder must not do is present a dead session's
# time as this one's. The sweep cannot help here, because the decoy arrived
# after this session began: only the buffer pairing can refuse it.
check("v58", "a session whose store was deleted takes no stamp from the survivor",
      0L, num("meta2_has_dead_stamp"), tol = 0)
check("v58", "and names none of the dead session's objects",
      0L, num("meta2_names_dead_table"), tol = 0)
check("v58", "and says on the file that its start time was lost, not recorded",
      1L, num("meta2_stamp_recovered_note"), tol = 0)
check_true("v58", "the recovered header line still carries a real timestamp",
           grepl("^# \\S.* -- +recorded on Praat ", str_("meta2_stamp_line")))

# ---------------------------------------------------------------------------
# 5. NEW-G11-1 -- THE INCLUDE BLOCK SAYS WHAT IT IS
# ---------------------------------------------------------------------------
# AUTHOR RULING, 15 AUGUST 2026: THE EMITTED SCRIPT IS HOME-RELATIVE, FULL
# STOP. This section was first written to check something weaker -- that the
# header's claim MATCHED the paths beneath it, whichever way they came out --
# and it passed an emission that announced its own absolute paths as honestly
# not portable. That is the wrong half to make conditional. Where the plugin
# sits on the machine that recorded a session is an accident of that machine;
# the emitted file is for a user, and a file carrying someone else's directory
# layout is worth nothing to them.
#
# So the plugin now guarantees the tilde in TWO places, and this file checks
# both, because one of them alone is what the original defect looked like:
#
#   * @emlRecordBegin resolves a home-relative root, falling back to the
#     platform's canonical location when the live preferences directory sits
#     outside $HOME -- which Praat produces only under an explicit --pref-dir,
#     i.e. in a test rig, never on a user's machine.
#   * @emlRecordRender rewrites the root AGAIN on the value it is about to
#     write. emlRecordPluginRoot$ is a plain global and Begin is not the last
#     writer: these harnesses set it after Begin so the emission points at the
#     working tree. Resolving well and rendering blindly is precisely how the
#     original defect worked -- a correct value computed in one scope and an
#     absolute one written in another, under a header that promised otherwise.
#
# The META leg is the one that flushes in a different scope from the one that
# began the recording, which is the shape of every menu-driven session. The
# ADV leg is the one whose root is overridden after Begin. Between them they
# cover both guarantees, and both must now show a tilde.
check("v58", "the resolved plugin root survives to the flush as home-relative",
      11L, num("meta_emit_root_is_home_relative"), tol = 0)
check_true("v58",
           sprintf("the include root really is written with a tilde (%s)",
                   str_("meta_emit_include_root")),
           grepl("^~/", str_("meta_emit_include_root")))
check("v58", "and the header claims home-relative, which is now true",
      1L, num("meta_emit_claims_home_relative"), tol = 0)
check("v58", "with no contradicting absolute-path notice",
      0L, num("meta_emit_states_absolute"), tol = 0)

# THE OTHER ARM, and the one the ruling changed. The ADV leg overrides the
# root AFTER @emlRecordBegin has resolved it -- the harness points the emission
# at the working tree so the replayed script exercises the code under test. It
# is therefore the only leg that can prove the RENDER-time rewrite, as distinct
# from the resolution-time one, and until 15 Aug it was the leg that emitted
# eleven absolute include lines.
check_true("v58",
           sprintf("a root overridden after Begin is still emitted with a tilde (%s)",
                   str_("emit_include_root")),
           grepl("^~/", str_("emit_include_root")))
check("v58", "and this arm claims home-relative too, because it now is",
      1L, num("emit_claims_home_relative"), tol = 0)
# NO SECOND ARM EXISTS ANY MORE. The renderer has one branch, so a
# machine-absolute notice appearing in ANY emission means the tilde was lost
# and the conditional header came back with it -- the exact pair of defects
# this section was rewritten to retire.
check("v58", "no emission anywhere states that its paths are machine-absolute",
      0L, num("emit_states_absolute") + num("meta_emit_states_absolute"), tol = 0)

# ---------------------------------------------------------------------------
# 6. NEW-G11-4 -- A SAVE ONTO A FOLDER THAT DOES NOT EXIST
# ---------------------------------------------------------------------------
# TWO LEVELS DEEP ON PURPOSE. createFolder: is mkdir and NOT mkdir -p --
# measured on 6.6.30, handed a path whose parents are absent it creates
# nothing -- so a single createFolder: leaves this leg's artefacts missing and
# these checks red. That is what makes them checks rather than formalities.
check("v58", "a replayed save creates the folder it was pointed at, ancestors and all",
      1L, num("folder_created"), tol = 0)
check_true("v58",
           sprintf("and writes its outputs there (%s files)", str_("folder_files")),
           num("folder_files") >= 3)

# ---------------------------------------------------------------------------
# 7. THE SOURCE, WHERE THE ARTEFACT CANNOT REACH
# ---------------------------------------------------------------------------
# Two things no headless driver can exercise, so they are read from the source
# instead -- and read is the honest word: this is a weaker kind of evidence
# than everything above and it is here because the alternative is nothing.
# THE RESOLUTION-TIME GUARANTEE, which neither leg can reach. Both drives run
# with a preferences directory inside $HOME, so the substitution in
# @emlPluginRoot -- the resolver @emlRecordBegin and setup.praat's barrel
# generator both call -- always fires and its fallback never does. The
# fallback is
# what makes the ruling hold on the one configuration the harness cannot
# occupy without becoming that configuration itself -- a --pref-dir outside
# $HOME, which is what these very harnesses use. A direct probe settles what
# each arm produces: with the fallback the root comes out
# ~/.praat-dir/plugin_EML_StatsGraphs; with it removed, /tmp/outofhome/
# plugin_EML_StatsGraphs. So the four canonical spellings are read from the
# source, and every one of them must carry the tilde -- a fallback that
# resolved to an absolute path would satisfy "a fallback exists" and defeat
# the ruling, which is the shape of mistake this whole file is about.
rsrc <- Sys.getenv("EML_RECORD_PROC_SRC", unset = "")
if (!nzchar(rsrc)) rsrc <- repo_path("plugin", "stats", "eml-record.praat")
if (check_true("v58", "the recorder core is present", file.exists(rsrc))) {
    rl <- readLines(rsrc, warn = FALSE)
    rc <- rl[!grepl("^\\s*[;#]", rl)]
    # READ OFF @emlPluginFolder, the table of canonical locations. Each entry
    # is a leading directory joined to the one folder name the plugin carries,
    # so what is read here is the directory part; the name itself is v47's
    # subject. @emlPluginRoot chooses one entry of this table for the running
    # platform and a recorded script's header prints all of them, and
    # setup.praat's barrel generator calls the same resolver -- so these four
    # entries are the fallback for a generated barrel as well as for a
    # recorded script, and one reading covers both.
    fb <- grep('^\\s*\\.root\\$\\s*\\[[^]]*\\]\\s*=\\s*"', rc, value = TRUE)
    fb <- sub('^[^"]*"([^"]*)".*$', "\\1", fb)
    fb <- fb[nzchar(fb)]
    check_true("v58",
               sprintf("every canonical plugin root the source can fall back to starts with ~ (%s)",
                       paste(fb, collapse = " | ")),
               length(fb) >= 4 && all(grepl("^~", fb)))
    check_true("v58",
               "the fallback covers Windows, macOS and both Praat-era Unix locations",
               any(grepl("^~/Praat/", fb)) &&
               any(grepl("^~/Library/Preferences/", fb)) &&
               any(grepl("^~/\\.config/praat/", fb)) &&
               any(grepl("^~/\\.praat-dir/", fb)))
    # AND THE RESOLVER SPELLS NONE OF ITS OWN. A branch that wrote a root out
    # rather than picking one from the table would be a fifth location, read
    # by nothing above and printed to no user, free to disagree with the four
    # a recorded script's header tells them to look in. The bare "~" that
    # opens the home-relative substitution is a prefix and not a location, so
    # a location is a tilde with a path after it.
    check_true("v58",
               "@emlPluginRoot selects from that table and spells no root itself",
               !any(grepl('\\.root\\$\\s*=\\s*"~[^"]', rc)))
}

src <- Sys.getenv("EML_RECORD_SRC", unset = "")
if (!nzchar(src)) src <- repo_path("plugin", "scripts", "eml-record-save.praat")
if (check_true("v58", "the stop-and-save command is present", file.exists(src))) {
    ss <- readLines(src, warn = FALSE)
    code <- ss[!grepl("^\\s*#", ss)]

    # ONE PLUGIN, ONE NAMING SCHEME. The Save panel proposes a stamped name IN
    # the dialog -- one stamp per press, visible before the press -- and this
    # command used to propose a bare name and resolve collisions afterwards
    # with a silent _1. The stamp must be taken BEFORE beginPause, or the user
    # is not shown the name they are about to get.
    iStamp <- grep("@emlFileStamp", code)
    iPause <- grep("beginPause: \"Stop recording and save\"", code)
    check_true("v58", "the saved script's name is stamped, as the Save panel's is",
               length(iStamp) >= 1 && any(grepl("proposed\\$", code)))
    check_true("v58", "the stamp is taken before the dialog, so the user sees the final name",
               length(iStamp) >= 1 && length(iPause) >= 1 &&
               min(iStamp) < min(iPause))
    check("v58", "exactly one stamp is taken per press", 1L,
          length(iStamp), tol = 0)
    # The numeric suffix survives as a BACKSTOP -- two presses inside one
    # second, or a user who deleted the stamp out of the field -- which is
    # what the panel does too.
    check_true("v58", "the collision backstop is kept behind the stamp",
               any(grepl("@emlGenerateUniquePath", code)))

    # NEW-G11-4 AT THE SOURCE. The folder must be made before the flush, and
    # the target must be PROVED writable rather than assumed: @emlRecordFlush
    # aborts the script on a failed write, and an abort here would destroy the
    # session this command exists to preserve.
    iFolder <- grep("@emlRecordMakeFolder", code)
    iProbe  <- grep("eml_record_write_probe", code)
    iFlush  <- grep("@emlRecordFlush", code)
    check_true("v58", "the target folder is created before the flush",
               length(iFolder) >= 1 && length(iFlush) >= 1 &&
               min(iFolder) < min(iFlush))
    check_true("v58", "and is proved writable with a real write, not assumed",
               length(iProbe) >= 1 && min(iProbe) < min(iFlush))
    # `nocheck @proc:` DOES NOT RUN THE PROCEDURE on 6.6.30 -- measured, and
    # it silently made the folder creation a no-op in this file's first cut.
    # Pinned so it cannot come back looking like defensive programming.
    check_true("v58", "the folder call is not wrapped in nocheck, which would skip it",
               !any(grepl("nocheck\\s+@emlRecordMakeFolder", code)))
}

# THE FIXTURE MUST NOT DRIFT FROM THE CODE IT STANDS IN FOR. harness/record's
# save leg synthesises the save step, because @emlSavePanel records its own
# step from inside the dialog and no headless driver can make the plugin
# produce one. That is a fixture standing in for real emission, and a fixture
# that quietly stops matching its original is a test of nothing -- so the
# emitter is re-read here and the shape compared.
osrc <- Sys.getenv("EML_OUTPUT_SRC", unset = "")
if (!nzchar(osrc)) osrc <- repo_path("plugin", "stats", "eml-output.praat")
if (check_true("v58", "the save emitter is present", file.exists(osrc))) {
    os <- readLines(osrc, warn = FALSE)
    check_true("v58",
               "the recorded save step is still emitted as an @emlSavePanel: call",
               any(grepl('"@emlSavePanel: "', os, fixed = TRUE)))
    check_true("v58", "and still declares the folder as outputFolder$",
               any(grepl('"outputFolder\\$ = "', os)))
}

# ---------------------------------------------------------------------------
# 8. RULING 9 -- THE COLUMNS ARE IN THE BLOCK, AND THE BLOCK IS LOAD-BEARING
# ---------------------------------------------------------------------------
# THE ORDER OF THESE CHECKS IS THE ARGUMENT. First that the block SAYS the
# right thing, then -- and this is the half a grep cannot reach -- that editing
# what it says changes what the file DOES.
#
# THE BLOCK, READ FROM THE EMITTED FILE BEFORE THE EDIT. The recorded session
# is chosen so that the role rule is visible in it rather than argued for: a
# two-way ANOVA of val by grp and site, then a violin of val by grp. "val" is a
# value column twice and must be ONE variable; "grp" is a factor in one step
# and a grouping column in the other and must be TWO. Each check is an exact
# line, including the inline note, because the note is what tells a user which
# steps an edit will move.
check("v58", "the block declares the object the session ran on",
      1L, num("retarget_block_data"), tol = 0)
check("v58", "one value column, shared by the analysis and the figure",
      1L, num("retarget_block_value"), tol = 0)
check("v58", "the two-way's factors are declared, each in its own role",
      2L, num("retarget_block_factorA") + num("retarget_block_factorB"),
      tol = 0)
# THE HALF THAT SEPARATES ROLE FROM LITERAL. "grp" is already in the block as
# factorACol$. It appears AGAIN as groupCol$ because the figure uses it for
# something else, and a user re-pointing the ANOVA's first factor must not
# silently re-point the figure's grouping with it.
check("v58", "the same column in a second role gets a second variable",
      1L, num("retarget_block_group"), tol = 0)

# THE STEPS READ THEM. Exact call lines: every column slot a variable, and --
# on the violin's own line -- the y-axis label still the literal "val", which
# is the role rule written out. Same string; one of them is a column and one of
# them is a caption.
check("v58", "the analysis step reads its three columns from the block",
      1L, num("retarget_call_twoway"), tol = 0)
check("v58", "the draw step reads its columns, and keeps its axis label a label",
      1L, num("retarget_call_violin"), tol = 0)
check("v58", "no column slot below the block still holds a literal",
      0L, num("retarget_literal_slots"), tol = 0)

# ---- THE DRIVE, which is the actual proof --------------------------------
# The block is edited on five lines -- one object, four columns -- and nothing
# else in the file is touched. Both halves are measured: how many lines
# changed, and whether any of them was below the first step separator.
check("v58", "the retarget edited exactly the five declarations",
      5L, num("retarget_lines_changed"), tol = 0)
check("v58", "and edited nothing below the block",
      0L, num("retarget_edits_below_block"), tol = 0)
# THE FILE RAN. A script still naming "val" and "grp" cannot: the twin table
# has no such columns, so an abort is not a flaky result here, it is the
# defect. (The abort count itself is checked in section 0 with the others.)
check_true("v58", "the retargeted script drew its figure",
           num("ret_replay_bytes") > 1000 && num("ret_orig_bytes") > 1000)
# IT READ THE NEW NAMES, one layer below the numbers: the two-way report
# echoes the columns it was asked for, so these three lines exist only if the
# variables were read.
check("v58", "the retargeted report names all three NEW columns",
      3L, num("retarget_report_new_cols"), tol = 0)
# THE COMPLEMENT IS MEASURED AND NOT ASSERTED, which is worth a sentence
# rather than a silent omission. retarget_report_old_cols is in the artefact
# and it is 0, but no mutation can make it anything else: a script that still
# names "val" against a table that has no such column does not print a report
# with the wrong headings, it stops --
#     Error: Table "rt": there is no column named "val".
# -- measured on 6.6.30 while breaking this section. An assertion that cannot
# fail is not a check, so this one is a note.
# AND IT IS THE SAME ANALYSIS. Two comparisons, because they fail differently:
# against the plugin run directly on the twin with the new names -- label for
# label, digit for digit -- and against the ORIGINAL recording's own numbers,
# which must not have moved, since only the headers changed.
check_true("v58", "the retargeted transcript is a real report, not a stub",
           num("retarget_report_lines") > 40)
check("v58", "the retargeted run matches the plugin told the new names directly",
      1L, num("retarget_matches_reference"), tol = 0)
check_true("v58", "the ANOVA table was read for the comparison",
           num("retarget_anova_rows") >= 4)
check("v58", "retargeting changed what is READ and not what is COMPUTED",
      1L, num("retarget_numbers_unchanged"), tol = 0)
# THE FIGURE, on the ADV leg's terms: same numbers under different headers is
# the same picture, and the residual is the recorder's six-decimal axis.
check("v58", "the retargeted figure is the recorded figure (px differing by >32)",
      0L, num("retarget_fig_vs_orig_over32"), tol = 0)
check_true("v58",
           sprintf("and its residual is anti-aliasing only (max %s of 255)",
                   str_("retarget_fig_vs_orig_max")),
           num("retarget_fig_vs_orig_max") >= 0 &&
           num("retarget_fig_vs_orig_max") <= 16)

# ---- THE MAP THAT MAKES IT POSSIBLE, AND ITS ONE WEAKNESS ----------------
# @emlRecordColumnSpec is a hand-maintained table of which argument of which
# procedure is a column. It is the right place for it -- one table beats
# twenty-six call sites each deciding for itself -- and the price is that it
# can fall behind the signatures it does not own. An orchestrator that starts
# recording without an entry here lifts nothing, and its emitted script keeps
# the literals under a block that promises otherwise: the original defect,
# returning one analysis at a time.
#
# So the two sources are compared in BOTH directions. A recorded call template
# that interpolates a column variable must have an entry; an entry must name a
# procedure that some template actually emits, which is what catches the
# typo -- a misspelled key never matches, lifts nothing, and is invisible.
csdir <- Sys.getenv("EML_RECORD_CALLSITES", unset = "")
if (!nzchar(csdir)) csdir <- repo_path("plugin")
cs_files <- file.path(csdir, c("stats/eml-analysis.praat",
                               "graphs/eml-draw-procedures.praat",
                               "graphs/eml-annotation-procedures.praat"))
if (check_true("v58", "the recording call sites are present",
               all(file.exists(cs_files))) &&
    check_true("v58", "the recorder core is readable for the column map",
               file.exists(rsrc))) {
    # CONTINUATIONS ARE FOLDED FIRST, and that is not tidiness. The violin's
    # template is six physical lines: the procedure name is on the first and
    # its column arguments are on the fourth, so a line-by-line read sees a
    # call with no columns and a column with no call. Both halves of this
    # check would then be wrong, in opposite directions, and the pair would
    # still look coherent.
    fold <- function(f) {
        x <- readLines(f, warn = FALSE)
        out <- character(0)
        for (ln in x) {
            if (grepl("^\\s*\\.\\.\\.", ln) && length(out))
                out[length(out)] <- paste0(out[length(out)], " ",
                                           sub("^\\s*\\.\\.\\.\\s*", "", ln))
            else out <- c(out, ln)
        }
        out
    }
    tmpl <- unlist(lapply(cs_files, fold))
    tmpl <- tmpl[grepl('"@eml[A-Za-z]+: ', tmpl)]
    # A template that interpolates a column VARIABLE takes a column: .dataCol$,
    # .raterCols$, .colX$, .col1$. `.colorMode$` is not one of those and
    # neither is `.xLabel$`, which is how the waveform, the spectrum and the
    # LTAS stay correctly outside the map -- they draw an object whole.
    withcol <- tmpl[grepl("[.]([A-Za-z]*Col[0-9]*|[A-Za-z]*Cols|col[0-9XY]+)[$]",
                          tmpl)]
    procs <- unique(sub('.*"@(eml[A-Za-z]+): .*', "\\1", withcol))
    procs <- sort(procs[grepl("^eml", procs)])
    rmap <- readLines(rsrc, warn = FALSE)
    spec <- rmap[grepl('^\\s*(els)?if \\.proc\\$ = "', rmap)]
    spec <- sort(unique(sub('.*\\.proc\\$ = "([^"]*)".*', "\\1", spec)))
    missing <- setdiff(procs, spec)
    dead    <- setdiff(spec, procs)
    check_true("v58",
               sprintf("every recording call site that names a column is in the map (%d found)",
                       length(procs)),
               length(procs) >= 20 && length(missing) == 0)
    if (length(missing)) {
        check_true("v58", paste("unmapped:", paste(missing, collapse = ", ")),
                   FALSE)
    }
    check_true("v58",
               sprintf("and every entry in the map names a call site that exists (%s)",
                       if (length(dead)) paste(dead, collapse = ", ") else "none dead"),
               length(dead) == 0)
}

# ---------------------------------------------------------------------------
# 9. RULING 4 -- THE NAME IS THE WARNING
# ---------------------------------------------------------------------------
# The recording object is created in one file and looked for by name in four.
# What is checkable is that they agree, and the reason to check it is that
# disagreement is silent: a recorder that creates emlRecording_DO_NOT_REMOVE
# and re-attaches to "Table emlRecordBuffer" never finds a live recording, so
# every menu command starts a new one, every emitted script holds a single
# step, and no error is raised anywhere. That is a worse failure than the one
# the rename fixes, and it is exactly what a half-finished rename produces.
#
# Whether a name READS as load-bearing is the author's judgement and not a
# measurement. The proxy pinned here is narrow and stated as a proxy: the name
# carries a shouted segment, so that it does not sit in the Objects window
# looking like the plugin's other scratch, and the same spelling appears in the
# messages the user is given.
start_src <- Sys.getenv("EML_RECORD_START_SRC", unset = "")
if (!nzchar(start_src)) start_src <- repo_path("plugin", "scripts",
                                               "eml-record-start.praat")
open_src <- Sys.getenv("EML_RECORD_OPEN_SRC", unset = "")
if (!nzchar(open_src)) open_src <- repo_path("plugin", "scripts",
                                             "eml-record-open.praat")
if (check_true("v58", "the three recording commands are present",
               file.exists(start_src) && file.exists(open_src) &&
               file.exists(src) && file.exists(rsrc))) {
    rl2 <- readLines(rsrc, warn = FALSE)
    st  <- readLines(start_src, warn = FALSE)
    op  <- readLines(open_src,  warn = FALSE)
    sv  <- readLines(src, warn = FALSE)

    # The buffer is identified by its COLUMNS, not by a name this file already
    # believes in -- so a rename is followed rather than assumed.
    icreate <- grep('Create Table with column names: "[^"]*", 0,', rl2)
    icols   <- grep('"n kind intent caveat code', rl2)
    ibuf <- icreate[icreate %in% (icols - 1)]
    bufname <- if (length(ibuf) == 1)
        sub('.*Create Table with column names: "([^"]*)".*', "\\1", rl2[ibuf])
        else ""
    if (check_true("v58",
                   sprintf("the recording object is created exactly once (%s)",
                           bufname),
                   nzchar(bufname))) {
        check_true("v58",
                   "its name is no longer the one that read as scratch",
                   bufname != "emlRecordBuffer")
        check_true("v58",
                   sprintf("the name shouts, which is the whole of the signal (%s)",
                           bufname),
                   grepl("[A-Z]{3,}", bufname))
        # EVERY LOOKUP FOLLOWS IT. The re-attach, the orphan sweep and the
        # orphan check all match on the full object name; a stale one is the
        # silent failure described above.
        nlook <- sum(grepl(paste0('"Table ', bufname, '"'), rl2, fixed = TRUE))
        check_true("v58",
                   sprintf("every lookup in the recorder uses that name (%d)", nlook),
                   nlook >= 3)
        # THE OLD NAME IS GONE FROM EVERY EXECUTABLE LINE of all four files.
        # Comments are excluded on purpose -- the rename is explained in them,
        # and a check that forbade the explanation would be a check against
        # writing down why. emlRecordBufferId, the script variable, is not the
        # object name and does not move.
        allcode <- c(rl2, st, op, sv)
        allcode <- allcode[!grepl("^\\s*[#;]", allcode)]
        check("v58", "and no executable line anywhere still uses the old one",
              0L,
              sum(grepl("emlRecordBuffer(?!Id)", allcode, perl = TRUE)),
              tol = 0)
        # THE MESSAGES QUOTE IT. A user told to look for an object that is not
        # what the Objects window calls it has been given a wrong answer with
        # the confidence of a right one.
        #
        # PRINTED LINES ONLY, for the reason the meta check below records: all
        # three files EXPLAIN the name in a comment, so reading the whole file
        # would pass on a command that had stopped telling the user anything.
        nocomment <- function(x) x[!grepl("^\\s*[#;]", x)]
        check_true("v58", "'Stop recording and save' names the object it means",
                   any(grepl(bufname, nocomment(sv), fixed = TRUE)))
        check_true("v58", "'Stop recording and open' names it too",
                   any(grepl(bufname, nocomment(op), fixed = TRUE)))
        check_true("v58", "and the start message tells the user about it",
                   any(grepl(bufname, nocomment(st), fixed = TRUE)))
    }

    # THE CORRECTED STOP MESSAGE IS KEPT, which the ruling says in as many
    # words. The name warns before the act; only this sentence can explain it
    # afterwards, and it was the audit's finding that there was none.
    check_true("v58",
               "both Stop commands still say the recording ended when it was removed",
               any(grepl("recording ended when its buffer was removed", sv)) &&
               any(grepl("recording ended when its buffer was removed", op)))
    # AND BOTH TABLES ARE EXPLAINED AT THE START. Two objects appear in the
    # Objects window and the message used to name one of them, which reads as
    # though the other arrived from somewhere else.
    # Read from what the command PRINTS, not from what it explains to a
    # maintainer in a comment: the first version of this check passed on a
    # message that had stopped naming the meta table, because the paragraph
    # above the message still discussed it.
    st_code <- st[!grepl("^\\s*[#;]", st)]
    check_true("v58", "the start message accounts for the meta table as well",
               any(grepl("emlRecordMeta", st_code, fixed = TRUE)))
}

if (!exists("EML_SUITE")) {
    eml_report("v58 recorder replay: a recorded workflow, run rather than read")
    eml_exit()
}
