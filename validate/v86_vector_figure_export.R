# ============================================================================
# v86_vector_figure_export.R -- the figure is offered as vector, every save is
# checked onto the disk, and a format this Praat has not got is a sentence
# rather than a crash
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS IS ABOUT. The Save panel wrote PNG and nothing else. A figure
# bound for a journal wants vector, and Praat can produce it -- but not the
# same vector everywhere. Praat's own manual, on "Save as PDF file...": "A
# command in the File menu of the Picture window, on Macintosh and Linux." On
# Windows the command does not exist, and the manual sends the reader to PNG
# or EPS instead.
#
# A COMMAND THAT DOES NOT EXIST ENDS THE SCRIPT. Praat answers "Command ...
# not available for current selection" and nothing after that line runs --
# which, inside @emlSavePanel, means no receipt, no return, and the caller's
# Done | Save | Draw | New loop gone with it. That is the same outage shape
# v56 exists for, and shipping a PDF button without handling it would have
# been that outage on every Windows machine. It is measured rather than
# assumed: harness/vecfig/run.sh drives the bare command in a process of its
# own and this file reads both halves of the answer.
#
# THE WRITER DOES NOT ASK WHICH OPERATING SYSTEM IT IS ON. It attempts the
# save under `nocheck` -- which lets the script survive an absent command --
# and then LOOKS FOR THE FILE. A host that has the format leaves a file
# behind; a host that has not leaves nothing, and one piece of code reads both
# answers. Nothing in @eml_saveFigureFormats names a platform, so a later
# Praat that adds PDF on Windows is handled without an edit, and a Praat that
# withdrew one would be handled too.
#
# AND THE PANEL DOES ASK, ONCE, ABOUT PDF ON WINDOWS. That is not a
# contradiction, it is the difference between guessing and knowing. Praat's
# manual documents the PDF command as Macintosh and Linux only; the author
# confirms it is absent from the menu on his Windows machine and that reaching
# for it crashed. Offering a tickbox that is documented to do nothing, and
# apologising for it afterwards, is worse than not offering it -- so on
# Windows the box is not built and one comment line says why. The landed-file
# check stays on every format regardless, because a full disk, an unwritable
# folder and a path without permission are not platform questions.
#
# NO FORMAT IS THE CONSOLATION PRIZE. EPS is vector and Praat writes it
# wherever Praat runs, so the message a user gets when a format is lost
# reports what landed and points at EPS -- it does not close by reassuring
# them about the PNG they did not ask about.
#
# AND A RECORDING KEEPS THE CHOICE. @emlRecordReplaySave writes the figure
# through the panel's own writer, and the format choice is lifted into the
# emitted script's editable block, one variable per save, so a session that
# saved one figure as EPS and another as PDF replays as both.
#
# AND THE SAME QUESTION IS ASKED OF THE PNG. Praat's Save commands raise
# nothing on success and, under `nocheck`, nothing on failure; a save that
# quietly did nothing is indistinguishable from one that worked unless
# something looks. Every file this panel claims to have written is now a file
# it found.
#
# ============================================================================
# WHAT THIS FILE READS
# ============================================================================
#
# harness/vecfig/out/VECFIG.tsv, a key/value stream from six drives of
# @eml_saveFigureFormats against a real Praat Picture window with a real
# figure in it, and harness/vecfig/out/files/<leg>/, the artefacts themselves.
# The markers are read HERE, out of the bytes, rather than believed from a
# line in the transcript: "%!PS" for EPS, "%PDF" for PDF, and the eight-byte
# PNG signature 89 50 4E 47 0D 0A 1A 0A for PNG. The plugin's own check runs
# through Praat's text reader, which drops the PNG signature's leading 0x89
# byte; R has no such difficulty, so the two are genuinely independent
# instruments rather than the same one twice.
#
# THE FOUR WORKING LEGS ask a Praat that has all three formats for a different
# combination: all, PNG only, PNG+EPS, PNG+PDF. They establish that a ticked
# format arrives and -- just as important -- that an unticked one does not.
#
# THE TWO DEPRIVED LEGS are how the redirect is watched firing. `nopdf` and
# `novector` drive a COPY of eml-output.praat in which the vector save command
# has been renamed to one Praat does not have. That is bit-for-bit the Windows
# condition: the command is absent, `nocheck` lets the script live, and no
# file arrives. Nothing in the landed-file machinery is touched on those legs;
# what changes is whether the format exists to be written, which is the
# variable the user's machine sets. A leg that deleted the file after a
# successful save would prove the check can see a missing file. This proves it
# can see an ABSENT FORMAT, which is the thing the user hits.
#
# THE RECORD LEG is a recording of two figures saved with DIFFERENT format
# choices, replayed, then replayed again with ONE line of its editable block
# changed. It answers the question a recording is kept for -- tick EPS today,
# replay next month, is the EPS there -- and the second replay answers the
# question that makes exposing the variable worth anything: does editing it
# change what comes back, and does it leave the other save alone.
#
# WHAT IS READ FROM THE SOURCE, in sections 8 and 8a, and why it is not a
# substitute for the above. Some claims cannot be driven headlessly, because
# they are claims about a DIALOG and a pause form does not return without a
# display (measured): that the tickboxes exist and sit inside the figure
# branch, that their values are what reach @eml_saveFigureFormats, that the
# PDF box is built only where Praat has the command, and that the redirect is
# shown exactly when a format went missing. Those are read out of the panel's
# text. Everything else here was driven.
#
# ============================================================================
# THE TRAPS THIS FILE IS BUILT AGAINST
# ============================================================================
#
# A CHECK THAT BELIEVES THE TRANSCRIPT. The drive reports which formats it
# thinks landed. If that report were the only evidence, a plugin that counted
# saves instead of files would satisfy every row of it. So each claimed file
# is opened here and its first bytes read, and each UNCLAIMED file is asserted
# ABSENT -- the pngonly leg must have no .eps and no .pdf on disk.
#
# A CHECK THAT MATCHES THE PROSE EXPLAINING THE FIX. Every source rule in
# section 8 runs on the file with Praat's comment lines dropped first. This
# file's own subject is described at length in those comments, and the strings
# it looks for -- "Save as PDF file:", "%PDF" -- appear in them.
#
# A REDIRECT NOBODY WATCHED FIRE. Sections 5 and 6 do not ask whether a
# message exists. They ask what it said, on a leg where the format was really
# taken away, and require it to name the format that failed, to name the
# alternatives, to state what this save did write, and to carry the PNG's own
# path -- reassembled from the wrapped lines and then found on disk.
#
# A MESSAGE TOO WIDE FOR ITS DIALOG. These lines are drawn with `comment:` in
# a pause form, which reserves the height of one line and draws whatever it is
# handed; a line past the dialog's width overprints the line below it. That is
# the SAVED-OVERPRINT defect of 14 August 2026, and this dialog would repeat
# it. The 62-character budget is asserted on the driven lines.
#
# ============================================================================
# THE BREAKS, AS MEASURED
# ============================================================================
# harness/vecfig/break.sh drives seven deliberately broken copies of the tree
# through the whole harness and runs this file against each. Recorded in
# harness/vecfig/out/BREAKS.tsv, out of 263 checks:
#
#   no_landed_check     43 red. The landed-file check removed from the vector
#                       arms, so a file is counted because the Save command
#                       was issued. Both deprived legs then report a PDF the
#                       host has not got, `missing` comes back empty, no
#                       redirect is built at all, and the files named are not
#                       on disk. This is the silent failure the whole feature
#                       is against, and it is caught in three independent
#                       places: the reported sets, the absent message, and
#                       section 8's count of landed checks.
#   no_alternatives     15 red. The closing paragraph replaced by "That format
#                       is not available." Every other part of the message is
#                       untouched -- the format that failed is still named,
#                       what did write is still listed, the files are still
#                       confirmed by path, the dialog still appears, every
#                       line still fits. Only the redirection is gone.
#   no_png_check        4 red. The PNG's landed check dropped and its count
#                       made unconditional. Every DRIVEN leg still passes,
#                       correctly: the PNG does land on this machine, so no
#                       artefact can disagree. Section 8 is the only thing in
#                       the tree that can see it, which is why it exists.
#   pdf_box_on_windows  2 red. The windows guard removed, so the panel offers
#                       a PDF tickbox on a host whose Praat is documented not
#                       to have the command -- and the line that explains the
#                       absence goes with it. Only section 8a can see this
#                       one: the branch is inside a pause form, and this box
#                       is not Windows, so no drive here takes the other arm.
#   png_only_message    13 red. The message back to closing on the PNG: the
#                       file list replaced by the PNG's own path and the
#                       EPS-forward paragraph replaced by the older wording
#                       that treated PNG as the format that survives. Both
#                       deprived legs move, and so do the source checks.
#   recorder_own_save   8 red. @emlRecordReplaySave writing its own 300-dpi
#                       PNG again instead of calling the panel's writer. The
#                       recorded EPS and the recorded PDF both vanish from
#                       every replay, silently, which is exactly the report a
#                       user would get: a PNG and no warning.
#   shared_format_var   11 red. The per-save suffix flattened, so both saves
#                       declare figureFormat$ and the second wins. The first
#                       figure comes back as PDF -- a format its save never
#                       asked for -- and the one-line edit now moves both.
#                       Invisible in any session that saved once.
#
# Input:  harness/vecfig/out/VECFIG.tsv        ($EML_VECFIG_DIR overrides)
#         harness/vecfig/out/files/<leg>/
#         harness/vecfig/out/files/replay_*/
#         harness/vecfig/out/record/emitted.praat
#         plugin/stats/eml-output.praat        ($EML_VECFIG_FILE overrides)
#         plugin/stats/eml-record.praat        ($EML_VECFIG_RECORD_FILE ditto)
# Re-drive: bash harness/vecfig/run.sh
# Break:    bash harness/vecfig/break.sh
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

VF_DIR <- Sys.getenv("EML_VECFIG_DIR", unset = "")
if (!nzchar(VF_DIR)) VF_DIR <- repo_path("harness", "vecfig", "out")
TSV <- file.path(VF_DIR, "VECFIG.tsv")

SRC <- Sys.getenv("EML_VECFIG_FILE", unset = "")
if (!nzchar(SRC)) SRC <- repo_path("plugin", "stats", "eml-output.praat")

have_tsv <- check_true("v86", sprintf("the driven transcript exists (%s)",
                                      basename(TSV)), file.exists(TSV))

KEY <- character(0); VAL <- character(0)
if (have_tsv) {
    raw <- readLines(TSV, warn = FALSE)
    raw <- raw[nzchar(raw)]
    parts <- regmatches(raw, regexpr("\t", raw), invert = TRUE)
    KEY <- vapply(parts, function(p) p[1], "")
    VAL <- vapply(parts, function(p) if (length(p) > 1) p[2] else "", "")
}
one <- function(k) { v <- VAL[KEY == k]; if (length(v)) v[1] else NA_character_ }
all_of <- function(k) VAL[KEY == k]
num <- function(k) suppressWarnings(as.numeric(one(k)))

# ---------------------------------------------------------------------------
# 1. THE INSTRUMENT
# ---------------------------------------------------------------------------
check_true("v86", "a Praat was found to drive",
           identical(one("meta_praat_found"), "1"))
check_true("v86", sprintf("the transcript names the Praat it drove (%s)",
                          one("all_praat_version")),
           isTRUE(grepl("^[0-9]+\\.[0-9]", one("all_praat_version"))))

# THE STALENESS BINDING. The transcript records the digest of the panel's CODE
# -- comment lines dropped -- as it was when the legs were driven. A
# transcript taken from a different eml-output.praat is not evidence about
# this one, and this whole file is about what that file does at run time.
code_sha <- NA_character_
if (file.exists(SRC) && nzchar(Sys.which("sha256sum"))) {
    src_all <- readLines(SRC, warn = FALSE)
    tmp <- tempfile()
    writeLines(src_all[!grepl("^[[:space:]]*[#;!]", src_all)], tmp)
    o <- suppressWarnings(system2("sha256sum", shQuote(tmp),
                                  stdout = TRUE, stderr = FALSE))
    unlink(tmp)
    if (length(o)) code_sha <- sub(" .*$", "", o[1])
}
check_true("v86",
           sprintf("the transcript was driven on THIS panel's code (%s)",
                   substr(one("meta_output_code_sha256"), 1, 12)),
           !is.na(code_sha) && identical(code_sha, one("meta_output_code_sha256")))

# ---------------------------------------------------------------------------
# 2. THE PLATFORM TRAP, MEASURED
#
# Both halves, because the design is built on the difference between them and
# a reader is entitled to see it rather than take the manual's word. Without
# `nocheck` an absent command ends the script at that line; with it the script
# continues and no file arrives. If either of these ever stopped being true
# the approach would be wrong, and this is where that would show.
# ---------------------------------------------------------------------------
check_true("v86",
           "an UNGUARDED absent command runs its script up to that line",
           identical(one("meta_unguarded_before"), "1"))
check_true("v86",
           "... and stops there: the line after it never ran",
           identical(one("meta_unguarded_after"), "0"))
check_true("v86",
           sprintf("... and Praat's words are \"%s\"",
                   one("meta_unguarded_message")),
           identical(one("meta_unguarded_message"),
                     "not available for current selection"))
check_true("v86",
           "under `nocheck` the same absent command lets the script continue",
           identical(one("all_absent_command_survived"), "1"))
check_true("v86",
           "... and leaves no file behind, which is the whole signal",
           identical(one("all_absent_command_file"), "0"))

# ---------------------------------------------------------------------------
# 3. THE SIX LEGS, AND THE FILES THEY LEFT
#
# One row per leg: what was ticked, what the plugin said landed and went
# missing, and which files must and must not be on disk afterwards. The
# markers are read out of the bytes here.
# ---------------------------------------------------------------------------
MARKERS <- list(
    png = as.raw(c(0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a)),
    eps = charToRaw("%!PS"),
    pdf = charToRaw("%PDF")
)

starts_with_marker <- function(path, marker) {
    if (!file.exists(path)) return(FALSE)
    n <- length(marker)
    con <- file(path, "rb")
    on.exit(close(con))
    head_bytes <- readBin(con, "raw", n = n)
    length(head_bytes) == n && identical(head_bytes, marker)
}

LEGS <- list(
    list(leg = "all",      eps = 1, pdf = 1, mut = "none",
         landed = "PNG, EPS, PDF", missing = "",         n = 3,
         have = c("png", "eps", "pdf"),  hasnt = character(0)),
    list(leg = "pngonly",  eps = 0, pdf = 0, mut = "none",
         landed = "PNG",           missing = "",         n = 1,
         have = c("png"),                hasnt = c("eps", "pdf")),
    list(leg = "epsonly",  eps = 1, pdf = 0, mut = "none",
         landed = "PNG, EPS",      missing = "",         n = 2,
         have = c("png", "eps"),         hasnt = c("pdf")),
    list(leg = "pdfonly",  eps = 0, pdf = 1, mut = "none",
         landed = "PNG, PDF",      missing = "",         n = 2,
         have = c("png", "pdf"),         hasnt = c("eps")),
    # THE DEPRIVED LEGS. `nopdf` is a Praat with EPS and no PDF, which is what
    # Praat's manual says Windows is. `novector` is the harsher case: a host
    # with neither, which no shipping Praat is, driven because the message has
    # a plural form and an untested plural form is a guess.
    list(leg = "nopdf",    eps = 1, pdf = 1, mut = "nopdf",
         landed = "PNG, EPS",      missing = "PDF",      n = 2,
         have = c("png", "eps"),         hasnt = c("pdf")),
    list(leg = "novector", eps = 1, pdf = 1, mut = "novector",
         landed = "PNG",           missing = "EPS, PDF", n = 1,
         have = c("png"),                hasnt = c("eps", "pdf"))
)

for (L in LEGS) {
    lg <- L$leg
    check_true("v86", sprintf("%s: the leg ran to the end", lg),
               identical(one(paste0(lg, "_finished")), "1"))
    check_true("v86", sprintf("%s: it was driven with EPS=%d PDF=%d", lg,
                              L$eps, L$pdf),
               identical(one(paste0(lg, "_want_eps")), as.character(L$eps)) &&
               identical(one(paste0(lg, "_want_pdf")), as.character(L$pdf)))

    # THE DEPRIVATION REALLY HAPPENED. A sed that matched nothing would turn a
    # deprived leg into a copy of the first one, and every assertion below
    # would then be about a Praat that had the format after all.
    want_pdf_attempts <- if (L$mut == "none") "1" else "0"
    want_eps_attempts <- if (L$mut == "novector") "0" else "1"
    check_true("v86",
               sprintf("%s: the tree it drove has %s PDF attempt and %s EPS attempt",
                       lg, want_pdf_attempts, want_eps_attempts),
               identical(one(paste0(lg, "_attempt_pdf_lines")), want_pdf_attempts) &&
               identical(one(paste0(lg, "_attempt_eps_lines")), want_eps_attempts))

    check_true("v86", sprintf("%s: the plugin reports landed = \"%s\"", lg,
                              one(paste0(lg, "_landed"))),
               identical(one(paste0(lg, "_landed")), L$landed))
    check_true("v86", sprintf("%s: the plugin reports missing = \"%s\"", lg,
                              one(paste0(lg, "_missing"))),
               identical(one(paste0(lg, "_missing")), L$missing))
    check_true("v86", sprintf("%s: it counted %d file(s) written", lg, L$n),
               identical(one(paste0(lg, "_n_written")), as.character(L$n)))

    # ── AND THE DISK AGREES, byte by byte ─────────────────────────────────
    for (ext in L$have) {
        p <- file.path(VF_DIR, "files", lg, paste0("fig.", ext))
        sz <- if (file.exists(p)) file.info(p)$size else NA_real_
        check_true("v86", sprintf("%s: fig.%s is on disk", lg, ext),
                   file.exists(p))
        check_true("v86", sprintf("%s: fig.%s is not empty (%s bytes)", lg, ext,
                                  ifelse(is.na(sz), "no file", format(sz))),
                   isTRUE(sz > 0))
        check_true("v86",
                   sprintf("%s: fig.%s begins with its own marker", lg, ext),
                   starts_with_marker(p, MARKERS[[ext]]))
    }
    # AN UNTICKED FORMAT MUST NOT ARRIVE. Half of "the tickbox works" is that
    # the box the user left alone wrote nothing; a procedure that wrote all
    # three every time would satisfy every assertion above.
    for (ext in L$hasnt) {
        p <- file.path(VF_DIR, "files", lg, paste0("fig.", ext))
        check_true("v86", sprintf("%s: no fig.%s was written", lg, ext),
                   !file.exists(p))
    }

    # ── THE SEPARATE LEGEND GOES IN THE SAME FORMATS ──────────────────────
    # The panel writes it through the same procedure with the same arguments,
    # so a legend placed outside the frame is not left behind as a lone PNG
    # beside a vector figure.
    check_true("v86", sprintf("%s: the legend landed the same formats (%s)", lg,
                              one(paste0(lg, "_legend_landed"))),
               identical(one(paste0(lg, "_legend_landed")), L$landed))
    check_true("v86", sprintf("%s: and lost the same ones (\"%s\")", lg,
                              one(paste0(lg, "_legend_missing"))),
               identical(one(paste0(lg, "_legend_missing")), L$missing))
    for (ext in L$have) {
        p <- file.path(VF_DIR, "files", lg, paste0("fig_legend.", ext))
        check_true("v86",
                   sprintf("%s: fig_legend.%s is on disk with its marker", lg, ext),
                   starts_with_marker(p, MARKERS[[ext]]))
    }

    # ── THE OBJECT LIST CAME BACK ─────────────────────────────────────────
    # The landed check reads the saved file back through a Strings object,
    # which means a save now touches the Objects window. Two objects were
    # selected before the call; both must be selected after it, or the panel
    # has handed its caller a different selection than it took.
    check_true("v86",
               sprintf("%s: the caller's selection survived the save (%s)", lg,
                       one(paste0(lg, "_sel_after_ids"))),
               identical(one(paste0(lg, "_sel_before")), "2") &&
               identical(one(paste0(lg, "_sel_after")), "2") &&
               identical(one(paste0(lg, "_sel_after_ids")), "ab"))
}

# EVERY LEG IN THE FILE IS A LEG IN THE TABLE. The set comparison, not a
# count: a leg added to run.sh and not to this file would be driven, would
# produce artefacts, and would be asserted on by nothing.
legs_present <- unique(sub("_finished$", "", grep("_finished$", KEY, value = TRUE)))
legs_asserted <- vapply(LEGS, function(L) L$leg, "")
check_true("v86",
           sprintf("every driven leg is asserted on (%s)",
                   paste(sort(legs_present), collapse = " ")),
           setequal(legs_present, legs_asserted))

# ---------------------------------------------------------------------------
# 4. THE CHECKER ITSELF, ON FILES WHOSE ANSWER WAS KNOWN BEFORE IT RAN
#
# Every claim in section 3 rests on @eml_saveFileLanded. A checker that
# answered 1 to everything would satisfy all of them on this machine, where
# every format works. These nine rows are the only thing that can see it.
# ---------------------------------------------------------------------------
UNITS <- list(
    c("unit_png_right", "1", "a real PNG against the PNG marker"),
    c("unit_eps_right", "1", "a real EPS against the EPS marker"),
    c("unit_pdf_right", "1", "a real PDF against the PDF marker"),
    c("unit_png_wrong", "0", "a real PNG against the PDF marker"),
    c("unit_eps_wrong", "0", "a real EPS against the PDF marker"),
    c("unit_pdf_wrong", "0", "a real PDF against the EPS marker"),
    c("unit_empty",     "0", "a file of nothing"),
    c("unit_junk",      "0", "a file of the wrong content"),
    c("unit_absent",    "0", "a path with no file at it")
)
for (u in UNITS) {
    check_true("v86", sprintf("the landed check answers %s to %s", u[2], u[3]),
               identical(one(paste0("all_", u[1])), u[2]))
}
# NINE READS, NOTHING LEFT BEHIND. Each one makes a Strings object; one left
# selected would hand the panel's caller a stranger, and one left in the list
# would accumulate over a session.
check_true("v86", "and it leaves no object behind (9 reads, 0 objects)",
           identical(one("all_unit_objects_left"), "0"))

# ---------------------------------------------------------------------------
# 5. THE REDIRECT, WATCHED FIRING
#
# On the two legs where the format was really taken away. This is the
# condition of the whole feature: the user gets a helpful sentence instead of
# a crash. Each line is quoted from the message the plugin built during that
# drive.
# ---------------------------------------------------------------------------
ALTERNATIVES <- "Praat's figure formats are PNG, EPS and PDF"
ON_DISK <- "These figure files are on disk:"
UNCHANGED <- "Nothing else about this save changed."
# THE SENTENCE THAT MUST NOT COME BACK. The message used to end by confirming
# the PNG, which told a user who had asked for vector that their raster was
# safe -- the one thing they had not asked about. Named here so a revert to it
# is a red line rather than a quiet change of tone.
PNG_ONLY <- "still saved as PNG"

redirect_text <- function(leg) {
    v <- one(paste0(leg, "_redirect_text"))
    if (is.na(v)) "" else gsub("[[:space:]]+", " ", trimws(v))
}
redirect_lines <- function(leg) all_of(paste0(leg, "_redirect_line"))

for (L in LEGS) {
    lg <- L$leg
    if (!nzchar(L$missing)) {
        # A LEG THAT LOST NOTHING MUST SAY NOTHING. A dialog that appeared on
        # a completely successful save would be worse than no dialog: it
        # would teach the user to dismiss it unread.
        check_true("v86",
                   sprintf("%s: nothing went missing, so no redirect was built", lg),
                   identical(one(paste0(lg, "_redirect_lines")), "0"))
        next
    }

    txt <- redirect_text(lg)
    check_true("v86", sprintf("%s: a redirect was built", lg),
               isTRUE(num(paste0(lg, "_redirect_lines")) > 0))

    # ── IT NAMES THE FORMAT THAT DID NOT ARRIVE, each one ─────────────────
    for (fmt in strsplit(L$missing, ", ", fixed = TRUE)[[1]]) {
        sentence <- sprintf("Praat on this system did not write the %s file, so no %s was saved.",
                            fmt, fmt)
        check_true("v86", sprintf("%s: it says \"%s\"", lg, sentence),
                   grepl(sentence, txt, fixed = TRUE))
    }
    # AND NAMES NOTHING ELSE AS MISSING. The nopdf leg wrote a perfectly good
    # EPS; a message that mourned it would send the user looking for a file
    # that is on their disk.
    for (fmt in setdiff(c("PNG", "EPS", "PDF"),
                        strsplit(L$missing, ", ", fixed = TRUE)[[1]])) {
        check_true("v86",
                   sprintf("%s: it does not claim %s failed", lg, fmt),
                   !grepl(sprintf("did not write the %s file", fmt), txt,
                          fixed = TRUE))
    }

    # ── IT NAMES THE ALTERNATIVES ─────────────────────────────────────────
    # All three by name. "This format is unavailable" is a true sentence that
    # leaves the user with nowhere to go; the point of a redirect is the
    # redirection.
    check_true("v86", sprintf("%s: it names the alternatives (\"%s ...\")", lg,
                              ALTERNATIVES),
               grepl(ALTERNATIVES, txt, fixed = TRUE))
    # THE SENTENCE ITSELF, LIFTED OUT OF THE DRIVEN LINES and asked for each
    # format by name. Matching the three names anywhere in the message would
    # be satisfied by the failure sentences above, which name a format too --
    # so the paragraph that offers the alternatives is isolated first, by
    # joining from its opening words to the blank line that ends it.
    alines <- redirect_lines(lg)
    a0 <- which(startsWith(alines, "Praat's figure formats"))
    apara <- ""
    if (length(a0)) {
        k <- a0[1]
        while (k <= length(alines) && nzchar(alines[k])) {
            apara <- paste(apara, alines[k]); k <- k + 1
        }
    }
    for (fmt in c("PNG", "EPS", "PDF")) {
        check_true("v86",
                   sprintf("%s: the alternatives paragraph names %s", lg, fmt),
                   grepl(fmt, apara, fixed = TRUE))
    }
    # AND IT SAYS WHAT TO DO NEXT, WHICH DEPENDS ON WHAT HAPPENED TO EPS.
    # This is the correction of 17 August in one assertion. EPS is vector and
    # Praat writes it wherever Praat runs, so it is the format to recommend
    # and not a consolation -- and a user who ticked PDF alone, on a host with
    # no PDF, must be sent to EPS rather than reassured about their PNG.
    #
    #   EPS landed   the user HAS a vector figure and is told so
    #   EPS missing  the vector copy is what went, and the folder is what to
    #                look at -- "tick EPS" would be nonsense, it was ticked
    #
    # The third arm -- EPS never ticked -- cannot be reached from a leg that
    # loses a format, because a leg only loses what it asked for; it is read
    # off the source in section 8.
    if (grepl("EPS", L$landed, fixed = TRUE)) {
        check_true("v86",
                   sprintf("%s: EPS landed, so it says the user has a vector file", lg),
                   grepl("The EPS above is a vector file", txt, fixed = TRUE))
    } else {
        check_true("v86",
                   sprintf("%s: EPS did not land, so it says no vector copy arrived", lg),
                   grepl("No vector copy arrived this time", txt, fixed = TRUE))
        check_true("v86",
                   sprintf("%s: ... and still calls EPS the vector format Praat writes everywhere", lg),
                   grepl("EPS is the vector format Praat writes wherever it runs",
                         txt, fixed = TRUE))
    }
    # AND IT DOES NOT FALL BACK ON THE PNG. The old closing sentence is named
    # so that reverting to it is red rather than merely different.
    check_true("v86",
               sprintf("%s: it does not offer the PNG as the thing that survived", lg),
               !grepl(PNG_ONLY, txt, fixed = TRUE))
    check_true("v86",
               sprintf("%s: and does not pretend to know which system this is", lg),
               !grepl("Windows|Macintosh|macOS|Linux", txt))

    # ── IT SAYS WHAT THIS SAVE DID WRITE, from what landed ────────────────
    did <- sprintf("This save did write: %s.", L$landed)
    check_true("v86", sprintf("%s: it says \"%s\"", lg, did),
               grepl(did, txt, fixed = TRUE))

    # ── AND NAMES EVERY FILE THAT ARRIVED, BY PATH ────────────────────────
    # Every format and both files, not the PNG alone: the figure and its
    # separate legend, in whichever formats landed. The paths are reassembled
    # from the wrapped lines -- @emlWrapText hard-breaks a path at 62
    # characters, inserting and eliding nothing, so the drawn lines
    # concatenate back to something the user can paste.
    check_true("v86", sprintf("%s: it lists the files that did arrive", lg),
               grepl(ON_DISK, txt, fixed = TRUE))
    lines <- redirect_lines(lg)
    i <- which(lines == ON_DISK)
    joined <- ""
    if (length(i)) {
        j <- i[1] + 1
        while (j <= length(lines) && nzchar(lines[j])) {
            joined <- paste0(joined, lines[j]); j <- j + 1
        }
    }
    figfiles <- strsplit(one(paste0(lg, "_fig_file_list")), " | ",
                         fixed = TRUE)[[1]]
    figfiles <- figfiles[nzchar(figfiles)]
    check_true("v86",
               sprintf("%s: and the paths it quotes are the ones that landed (%d)",
                       lg, length(figfiles)),
               length(figfiles) > 0 &&
               identical(joined, paste(figfiles, collapse = "")))
    # EVERY ONE OF THEM IS REALLY THERE, with its own marker, read here out of
    # the bytes. A message listing a file that is not on disk is the failure
    # this whole feature is against, arriving through the reassurance.
    ext_marker <- function(p) MARKERS[[tolower(sub("^.*\\.", "", p))]]
    # RESOLVED AGAINST THIS CHECKOUT, NOT AGAINST THE PATH IN THE MESSAGE. The
    # quoted path is ABSOLUTE, and correctly so -- it is what the user was told,
    # and telling somebody where their figure landed is the whole point of the
    # line. But it is absolute on the machine that drove the rig, so opening it
    # here only works when this is that machine. It passed for weeks on the
    # box the evidence was recorded on and failed the first time the suite ran
    # anywhere else. The bytes are still read; only the lookup moves.
    here <- function(f) file.path(VF_DIR, "files", lg, basename(f))
    check_true("v86",
               sprintf("%s: and every file it names is on disk with its marker", lg),
               length(figfiles) > 0 &&
               all(vapply(figfiles,
                          function(f) starts_with_marker(here(f), ext_marker(f)),
                          logical(1))))
    # AND THE FIGURE'S OWN PNG IS AMONG THEM. The list is built from what
    # landed, so this is the fact behind the sentence rather than the sentence
    # again.
    check_true("v86", sprintf("%s: the figure's PNG is one of them", lg),
               one(paste0(lg, "_png_path")) %in% figfiles)
    check_true("v86", sprintf("%s: it closes with \"%s\"", lg, UNCHANGED),
               grepl(UNCHANGED, txt, fixed = TRUE))

    # ── AND IT FITS THE DIALOG ────────────────────────────────────────────
    check_true("v86",
               sprintf("%s: no line exceeds the panel's 62 characters (%s)", lg,
                       one(paste0(lg, "_redirect_longest_line"))),
               isTRUE(num(paste0(lg, "_redirect_longest_line")) <= 62))
}

# ---------------------------------------------------------------------------
# 6. THE PNG SURVIVED THE FAILURE
#
# Stated separately from the message, because the message is a claim and this
# is the fact behind it. On both deprived legs the figure is on disk, with its
# signature, at the path the receipt will print -- the save was not lost, one
# extra copy of it was.
# ---------------------------------------------------------------------------
for (lg in c("nopdf", "novector")) {
    p <- file.path(VF_DIR, "files", lg, "fig.png")
    check_true("v86",
               sprintf("%s: the PNG was written even though a format failed", lg),
               starts_with_marker(p, MARKERS$png))
    check_true("v86", sprintf("%s: and the legend PNG with it", lg),
               starts_with_marker(file.path(VF_DIR, "files", lg,
                                            "fig_legend.png"), MARKERS$png))
}

# ---------------------------------------------------------------------------
# 7. THE FORMATS ARE ADDITIONS, NEVER REPLACEMENTS
#
# The panel's ruling, checked against the drives rather than against the
# source: on every leg, whatever else happened, a PNG was written.
# ---------------------------------------------------------------------------
for (L in LEGS) {
    check_true("v86", sprintf("%s: a PNG was written whatever else was asked for",
                              L$leg),
               grepl("PNG", one(paste0(L$leg, "_landed")), fixed = TRUE) &&
               starts_with_marker(file.path(VF_DIR, "files", L$leg, "fig.png"),
                                  MARKERS$png))
}

# ---------------------------------------------------------------------------
# 8. THE PANEL'S OWN TEXT
#
# Three claims a headless drive cannot make, because a pause form does not
# return without a display. Comment lines are dropped first: this file's
# subject is described at length in them and the strings looked for here
# appear there.
# ---------------------------------------------------------------------------
.load <- function(p) {
    raw <- readLines(p, warn = FALSE)
    joined <- character(0)
    for (ln in raw) {
        if (grepl("^\\s*\\.\\.\\.", ln) && length(joined)) {
            joined[length(joined)] <- paste0(joined[length(joined)], " ",
                                             sub("^\\s*\\.\\.\\.\\s*", "", ln))
        } else {
            joined <- c(joined, ln)
        }
    }
    norm <- gsub("\\s+", " ", trimws(joined))
    norm[!grepl("^[#;]", norm)]
}
.body <- function(lines, procname) {
    i <- grep(paste0("^procedure ", procname, "\\b"), lines)
    if (!length(i)) return(character(0))
    j <- grep("^endproc\\b", lines)
    j <- j[j > i[1]]
    if (!length(j)) return(character(0))
    lines[seq(i[1], j[1])]
}

have_src <- check_true("v86", "the panel's module is present", file.exists(SRC))
code <- if (have_src) .load(SRC) else character(0)
panel <- .body(code, "emlSavePanel")
figproc <- .body(code, "eml_saveFigureFormats")
landproc <- .body(code, "eml_saveFileLanded")

check_true("v86", "@eml_saveFigureFormats exists", length(figproc) > 0)
check_true("v86", "@eml_saveFileLanded exists", length(landproc) > 0)

# THE TWO TICKBOXES, IN THE FIGURE BRANCH. Praat derives a field's variable
# from its label by lowercasing the FIRST character only, so "Also EPS" reads
# back as also_EPS. Reading also_eps would raise "Unknown variable" and end
# the save -- the failure a tickbox panel is most able to hide, and the reason
# the label and the readback are both asserted here.
check_true("v86",
           "Praat reads the panel's own three labels back as figure_PNG, also_EPS, also_PDF",
           identical(one("meta_field_figure_PNG"), "1") &&
           identical(one("meta_field_also_EPS"), "1") &&
           identical(one("meta_field_also_PDF"), "0"))
check_true("v86", "the panel offers an EPS tickbox",
           any(grepl('^boolean: "Also EPS", 0$', panel)))
check_true("v86", "the panel offers a PDF tickbox",
           any(grepl('^boolean: "Also PDF", 0$', panel)))
iFigBox <- grep('^boolean: "Figure PNG", 1$', panel)
iEps <- grep('^boolean: "Also EPS", 0$', panel)
iPdf <- grep('^boolean: "Also PDF", 0$', panel)
check_true("v86",
           "and both sit with the figure's own tickbox, not with the numbers",
           length(iFigBox) == 1 && length(iEps) == 1 && length(iPdf) == 1 &&
           iEps > iFigBox && iPdf > iEps)

# ---------------------------------------------------------------------------
# 8a. PDF IS NOT OFFERED ON WINDOWS, BECAUSE PRAAT HAS NOT GOT IT THERE
#
# THE ONE PLACE THE PLUGIN IS ENTITLED TO NAME A PLATFORM. Everywhere else it
# attempts and looks -- see the writer, which names no operating system and is
# checked below for it. The difference is that everywhere else it is GUESSING
# what a host can do. Here it is not: Praat's manual says "Save as PDF file..."
# is "A command in the File menu of the Picture window, on Macintosh and
# Linux", and points Windows users at PNG or EPS instead. Offering a tickbox
# that is documented to do nothing, and apologising for it afterwards, is
# worse than not offering it.
#
# READ FROM THE SOURCE, and there is no other way to read it: the branch lives
# inside a `beginPause` block, and a pause form does not return without a
# display. The flags are measured -- this box answers windows=0 -- so the
# drives above exercised the arm that HAS the tickbox, and this pair of checks
# is what says the other arm exists and what it holds.
check_true("v86",
           sprintf("this box is not Windows (windows=%s macintosh=%s unix=%s)",
                   one("meta_flag_windows"), one("meta_flag_macintosh"),
                   one("meta_flag_unix")),
           identical(one("meta_flag_windows"), "0") &&
           identical(one("meta_flag_unix"), "1"))
iWinGuard <- grep("^if windows = 0$", panel)
iElse <- grep("^else$", panel)
iEndif <- grep("^endif$", panel)
guard_for_pdf <- iWinGuard[iWinGuard < iPdf[1]]
guard_for_pdf <- if (length(guard_for_pdf)) max(guard_for_pdf) else NA_integer_
check_true("v86",
           "the PDF tickbox is built only where Praat has the command",
           !is.na(guard_for_pdf) && length(iPdf) == 1 &&
           iPdf == guard_for_pdf + 1)
# AND THE ABSENCE IS EXPLAINED. A missing box with nothing in its place reads
# as a bug or a version difference; the else arm says which it is, in the
# place the user is standing when they look for it.
pdf_else <- iElse[iElse > guard_for_pdf]
pdf_else <- if (length(pdf_else)) min(pdf_else) else NA_integer_
check_true("v86",
           "and where it is not, one line says why",
           !is.na(pdf_else) &&
           identical(panel[pdf_else + 1],
                     'comment: "PDF is not available in Praat on Windows."'))
# THE SUFFIX LIST AGREES WITH THE TICKBOXES. A dialog that lists a .pdf it is
# not going to offer three lines later is the same lie in a different font.
# Two lines, and exactly one of them names .pdf -- stated as a count rather
# than as two patterns, because the difference between them is one word and a
# pattern precise enough to tell them apart is a pattern that breaks on a
# rewrap.
sfx <- grep("the same figure as vector", panel, value = TRUE)
check_true("v86",
           sprintf("the suffix list names .pdf on exactly one of its two arms (%d)",
                   length(sfx)),
           length(sfx) == 2 &&
           sum(grepl(".pdf", sfx, fixed = TRUE)) == 1)

# A FIELD THAT WAS NOT DECLARED HAS NO VARIABLE, which is why the value is
# resolved into .alsoPDF and not read from also_PDF at the write. Measured:
# a form declaring only two of the three booleans leaves also_PDF unbound, and
# reading it stops the script at that line -- inside the save, after the
# dialog, with the receipt still to come.
check_true("v86",
           "a form that omits a field leaves its variable unbound",
           identical(one("meta_absent_eps_exists"), "1") &&
           identical(one("meta_absent_pdf_exists"), "0"))
check_true("v86",
           "... and reading the unbound one ends the script there",
           identical(one("meta_absent_before"), "1") &&
           identical(one("meta_absent_after"), "0"))
iAlso <- grep("^\\.alsoPDF = also_PDF$", panel)
iAlsoZero <- grep("^\\.alsoPDF = 0$", panel)
alsoGuard <- iWinGuard[iWinGuard < iAlso[1]]
alsoGuard <- if (length(alsoGuard)) max(alsoGuard) else NA_integer_
check_true("v86",
           "so the panel resolves .alsoPDF under the same guard, defaulting to 0",
           length(iAlso) == 1 && length(iAlsoZero) == 1 &&
           iAlsoZero < iAlso && !is.na(alsoGuard) && iAlso == alsoGuard + 1)

# THE TICKBOXES ARE WHAT REACH THE WRITER. A dialog can offer a field that
# nothing reads; that is the same class of defect as a field read under the
# wrong name, and neither is visible from the artefacts.
check_true("v86",
           "the figure write is handed also_EPS and the resolved .alsoPDF",
           any(grepl("@eml_saveFigureFormats: \\.folder\\$, \\.stem\\$, \\.figureDPI, also_EPS, \\.alsoPDF",
                     panel)))
check_true("v86",
           "and so is the separate legend, under the legend's own name",
           any(grepl("@eml_saveFigureFormats: \\.folder\\$, \\.stem\\$ \\+ \"_legend\", \\.figureDPI, also_EPS, \\.alsoPDF",
                     panel)))

# THE VECTOR ATTEMPTS ARE `nocheck`, WHICH IS THE WHOLE MECHANISM. Without the
# prefix an absent command ends the script inside the panel, which is the
# outage this feature would otherwise have introduced on every Windows
# machine. Asserted per command, so losing one is a named failure.
check_true("v86", "the EPS attempt is nocheck-prefixed",
           any(grepl("^nocheck Save as EPS file:", figproc)))
check_true("v86", "the PDF attempt is nocheck-prefixed",
           any(grepl("^nocheck Save as PDF file:", figproc)))

# NO PLATFORM TEST ANYWHERE IN THE FIGURE PATH. The design is that the plugin
# learns what its host can do by looking at the disk. A `if windows` here
# would be right today and wrong the day Praat's platform support changed, and
# it would be invisible to every artefact this file reads.
check_true("v86",
           "the writer asks the disk, not the operating system",
           !any(grepl("windows|macintosh|unix\\b", figproc, ignore.case = TRUE)))

# EVERY FORMAT IS CHECKED ONTO THE DISK, INCLUDING THE PNG. This is the rule
# the whole of section 3 assumes and that no drive on a machine where PNG
# works can see: three landed checks, one per format, and every increment of
# the written count behind one of them.
markers_asked <- regmatches(figproc,
                            regexpr('@eml_saveFileLanded: [^,]+, "[^"]+"', figproc))
check_true("v86", sprintf("the writer checks all three formats onto the disk (%d)",
                          length(markers_asked)),
           length(markers_asked) == 3)
for (m in c('"PNG"', '"%!PS"', '"%PDF"')) {
    check_true("v86", sprintf("... one of them against %s", m),
               any(grepl(paste0("@eml_saveFileLanded: .*, ", gsub("([%!])", "\\\\\\1", m), "$"),
                         figproc)))
}
inc <- grep("^\\.nWritten = \\.nWritten \\+ 1$", figproc)
guard <- grep("^if eml_saveFileLanded\\.ok = 1$", figproc)
check_true("v86",
           sprintf("nothing is counted as written unless it was found (%d counts, %d guards)",
                   length(inc), length(guard)),
           length(inc) == 3 && length(guard) == 3)
# STATED AS A PAIRING, NOT AS TWO COUNTS. Three guards and three counts
# arranged wrongly -- one count hoisted out of its guard, one guard left
# holding nothing -- is exactly the mutation a pair of counts cannot see, and
# it is the shape a partial revert takes. Each count must be the line directly
# inside its own guard.
check_true("v86", "and each count sits directly inside its own guard",
           length(inc) == 3 && length(guard) == 3 && all(inc == guard + 1))

# THE PNG IS UNCONDITIONAL. "PNG always writes; the vector formats are
# additions, never replacements" is the author's ruling, and in the source it
# means the PNG save is not inside any `if .want...` block.
iPng <- grep("^Save as 300-dpi PNG file: \\.pngPath\\$$", figproc)
iWantEps <- grep("^if \\.wantEPS = 1$", figproc)
check_true("v86", "the PNG is written before either vector format is considered",
           length(iPng) == 1 && length(iWantEps) == 1 && iPng < iWantEps)

# THE COLLISION WALK COVERS THE NEW NAMES. The landed check reads "a file
# exists at this path" as "this press wrote it", and that reading is only true
# because the stem was proved free of every name the panel can write first.
for (suffix in c("\\.eps", "_legend\\.eps", "\\.pdf", "_legend\\.pdf")) {
    check_true("v86",
               sprintf("the stem-uniquing walk carries %s",
                       gsub("\\\\", "", suffix)),
               any(grepl(sprintf('if fileReadable \\(\\.folder\\$ \\+ "/" \\+ \\.try\\$ \\+ "%s"\\)',
                                 suffix), panel)))
}

# THE REDIRECT IS SHOWN EXACTLY WHEN A FORMAT WENT MISSING, and it is built by
# the procedure this file quotes. Both halves: a dialog with no condition
# would fire on every save, and a condition with no dialog is a message the
# user never sees.
check_true("v86", "the panel shows the redirect when a format went missing",
           any(grepl('^if \\.figMissing\\$ <> ""$', panel)) &&
           any(grepl("@eml_saveFormatRedirectLines:", panel)) &&
           any(grepl('^beginPause: "Figure format not available"$', panel)))
iCond <- grep('^if \\.figMissing\\$ <> ""$', panel)
iDlg <- grep('^beginPause: "Figure format not available"$', panel)
check_true("v86", "and the dialog is inside that condition",
           length(iCond) == 1 && length(iDlg) == 1 && iDlg > iCond)

# THE ALTERNATIVES ARE IN THE MESSAGE ITSELF. Section 5 reads them off a
# driven message; this reads them off the source, because a message built only
# on the deprived path would be untested on any host that loses a format for
# some other reason.
redir <- .body(code, "eml_saveFormatRedirectLines")
check_true("v86", "the message names PNG, EPS and PDF",
           any(grepl("Praat's figure formats are PNG, EPS and PDF", redir)))

# ---------------------------------------------------------------------------
# 8b. THE MESSAGE'S THIRD ARM, AND THE SENTENCE THAT MUST NOT COME BACK
#
# A leg only loses a format it asked for, so no drive can reach the arm where
# EPS was never ticked -- and that arm is the one the correction is about: a
# user who ticked PDF alone, on a host with no PDF, is sent to EPS rather than
# reassured about a PNG they did not ask about. It is read here.
# ---------------------------------------------------------------------------
# THE CONCATENATION IS CLOSED UP FIRST. A sentence longer than a source line
# is written as several literals joined with +, so a phrase this file looks
# for can straddle a join -- "The EPS " + "above is a vector file". Removing
# the joins reads the sentence the user is shown rather than the lines the
# author typed, and it is done here rather than by rewrapping the source to
# suit the check.
unsplit <- function(x) gsub('" *\\+ *"', "", x)
redir_txt <- unsplit(redir)
for (arm in c("The EPS above is a vector file",
              "No vector copy arrived this time",
              "tick Also EPS in the Save panel")) {
    check_true("v86", sprintf("the message carries the arm \"%s ...\"", arm),
               any(grepl(arm, redir_txt, fixed = TRUE)))
}
check_true("v86",
           "and no arm of it offers the PNG as the format that survived",
           !any(grepl(PNG_ONLY, redir_txt, fixed = TRUE)))
# THE MESSAGE IS HANDED EVERY FILE THAT LANDED, not the PNG's list. This is
# the wiring behind section 5's path check, and it is the line a revert would
# touch first.
check_true("v86",
           "the panel hands the message the figure's whole landed list",
           any(grepl("@eml_saveFormatRedirectLines: \\.figMissing\\$, \\.figLanded\\$, \\.figFileList\\$",
                     panel)))
# AND THE LANDED CHECK IS DEFENDED IN WRITING, so that the next reader does
# not delete it as belt-and-braces now that the panel knows about Windows.
# Read from the RAW file, comments and all, because a comment is exactly what
# this asserts.
raw_src <- if (have_src) readLines(SRC, warn = FALSE) else character(0)
check_true("v86",
           "the source says in words why the landed check stays on every format",
           any(grepl("Do not delete it as belt-and-braces", raw_src,
                     fixed = TRUE)))

# ---------------------------------------------------------------------------
# 9. THE RECORDER REPLAYS THE FORMAT IT RECORDED
#
# WHY THIS IS HERE RATHER THAN IN v58. It is the same subject as everything
# above: a format the user asked for, and whether it arrives. A recording is
# just the slowest path to the same question -- tick EPS today, replay next
# month -- and the failure it had was this file's failure one step removed:
# @emlRecordReplaySave carried its own `Save as 300-dpi PNG file:` and dropped
# the choice on the floor, silently, with no warning and no EPS.
#
# ONE WRITER. The replay now calls @eml_saveFigureFormats, so everything that
# procedure does comes with it -- the landed check included -- and the two
# paths cannot drift into disagreeing about what a save is.
#
# THE CHOICE IS SERIALISED PER SAVE. A recording can hold several, with
# different choices, and the emitted block gives each its own variable in
# first-use order: figureFormat$, figureFormat2$, exactly as the axis ranges
# are numbered. One shared variable would hand a session that saved one figure
# as EPS and another as PDF two copies of whichever was recorded last.
# ---------------------------------------------------------------------------
RSRC <- Sys.getenv("EML_VECFIG_RECORD_FILE", unset = "")
if (!nzchar(RSRC)) RSRC <- file.path(dirname(SRC), "eml-record.praat")

have_rsrc <- check_true("v86", "the recorder module is present",
                        file.exists(RSRC))
rcode <- if (have_rsrc) .load(RSRC) else character(0)
replay <- .body(rcode, "emlRecordReplaySave")

# THE TRANSCRIPT WAS DRIVEN ON THIS RECORDER. Same binding as the panel's, and
# for the same reason: the record leg below is a claim about this file.
rec_sha <- NA_character_
if (file.exists(RSRC) && nzchar(Sys.which("sha256sum"))) {
    r_all <- readLines(RSRC, warn = FALSE)
    tmp <- tempfile()
    writeLines(r_all[!grepl("^[[:space:]]*[#;!]", r_all)], tmp)
    o <- suppressWarnings(system2("sha256sum", shQuote(tmp),
                                  stdout = TRUE, stderr = FALSE))
    unlink(tmp)
    if (length(o)) rec_sha <- sub(" .*$", "", o[1])
}
check_true("v86",
           sprintf("the record leg was driven on THIS recorder's code (%s)",
                   substr(one("meta_record_code_sha256"), 1, 12)),
           !is.na(rec_sha) && identical(rec_sha, one("meta_record_code_sha256")))

# ── ONE WRITER, READ FROM THE SOURCE ──────────────────────────────────────
check_true("v86", "@emlRecordReplaySave takes the format choice as an argument",
           any(grepl("^procedure emlRecordReplaySave: \\.offerFigure, \\.stem\\$, \\.folder\\$, \\.formats\\$$",
                     rcode)))
check_true("v86", "and writes the figure through the panel's own writer",
           length(replay) > 0 &&
           any(grepl("^@eml_saveFigureFormats: \\.folder\\$, \\.stem\\$, 1, \\.wantEPS, \\.wantPDF$",
                     replay)))
check_true("v86", "... and the separate legend through it too",
           any(grepl('^@eml_saveFigureFormats: \\.folder\\$, \\.stem\\$ \\+ "_legend", 1, \\.wantEPS, \\.wantPDF$',
                     replay)))
# THE SECOND IMPLEMENTATION IS GONE. A `Save as` of its own is the defect
# itself: the day it comes back the replay drops the choice again, and every
# check in this section that reads a FILE would still pass on a machine where
# only PNG was ever asked for.
check_true("v86", "and carries no figure save command of its own",
           !any(grepl("^Save as .*PNG file:", replay)))
check_true("v86", "the recorded choice is read as EPS and PDF flags",
           any(grepl('^if index \\(\\.formats\\$, "EPS"\\) > 0$', replay)) &&
           any(grepl('^if index \\(\\.formats\\$, "PDF"\\) > 0$', replay)))
# AND A FORMAT THAT DID NOT ARRIVE IS STILL STATED. A replay may not open a
# dialog, so the panel's own lines go to the Info window -- built by the same
# procedure, so the two cannot say different things.
check_true("v86", "a replay that loses a format says so, in the panel's words",
           any(grepl("^@eml_saveFormatRedirectLines: \\.figMissing\\$, \\.figLanded\\$, \\.figFileList\\$$",
                     replay)))
# THE STEM WALK COVERS THE VECTOR NAMES, for the panel's reason: the landed
# check reads "a file exists here" as "this call wrote it".
for (suffix in c("\\.eps", "_legend\\.eps", "\\.pdf", "_legend\\.pdf")) {
    check_true("v86",
               sprintf("the replay's stem walk carries %s",
                       gsub("\\\\", "", suffix)),
               any(grepl(sprintf('if fileReadable \\(\\.folder\\$ \\+ "/" \\+ \\.try\\$ \\+ "%s"\\)',
                                 suffix), replay)))
}

# ── THE LIFT, AND THE KEY IT IS UNDER ─────────────────────────────────────
# The format table is keyed on .fmtProc$ and not on .proc$, and that is not a
# style choice: validate/v58 §8 censuses this file by reading every line
# spelled `if .proc$ = "..."` and requiring each name it finds to be a
# procedure whose recorded call template interpolates a COLUMN variable.
# @emlSavePanel names no column, so under .proc$ it would be reported as a
# dead entry there -- the axis table has a key of its own for the same reason.
check_true("v86", "the format lift is a table entry of its own",
           any(grepl('^if \\.fmtProc\\$ = "emlSavePanel"$', rcode)) &&
           any(grepl('^\\.formatSpec\\$ = "4 figureFormat"$', rcode)))
check_true("v86", "and it is not keyed on .proc$, which v58 censuses",
           !any(grepl('\\.proc\\$ = "emlSavePanel"', rcode)))
# A SECOND SAVE IS NOT THE FIRST SAVE'S VARIABLE, and the shape that makes
# that true is read here. The slot a save reuses is the one its OWN RUN
# opened -- one pass through the form, one format choice -- and the name is
# built by the shared suffix procedure every variable in the block goes
# through, so a second run's save is figureFormat2$ and cannot silently
# replay the first run's choice.
check_true("v86", "a second distinct choice is numbered, not shared",
           any(grepl("^if \\.fmtRun\\[\\.k\\] = \\.run$", rcode)) &&
           any(grepl("^@emlRecordRunSuffix: \\.run, \\.fSame$", rcode)) &&
           any(grepl("^\\.fmtName\\$\\[\\.nFmt\\] = \\.fBase\\$ \\+ emlRecordRunSuffix\\.suffix\\$ \\+ \"\\$\"$",
                     rcode)))

# ── THE FIXTURE MUST NOT DRIFT FROM THE CODE IT STANDS IN FOR ─────────────
# harness/vecfig's record leg synthesises the save step, because @emlSavePanel
# records its own from inside a dialog and no headless driver can make the
# plugin produce one. That is a fixture standing in for real emission, and a
# fixture that quietly stops matching its original is a test of nothing -- so
# the emitter is re-read and its shape compared, exactly as v58 does.
check_true("v86", "the panel still emits the save step as an @emlSavePanel: call",
           any(grepl('"@emlSavePanel: "', code, fixed = TRUE)))
check_true("v86", "and now emits the format choice as its fourth argument",
           any(grepl('outputFolder\\$, " \\+ """" \\+ \\.recFormats\\$', code)))
check_true("v86", "which is the request, PNG plus whatever was ticked",
           any(grepl('^\\.recFormats\\$ = "PNG"$', panel)) &&
           any(grepl('^\\.recFormats\\$ = \\.recFormats\\$ \\+ ", EPS"$', panel)) &&
           any(grepl('^\\.recFormats\\$ = \\.recFormats\\$ \\+ ", PDF"$', panel)))

# ── THE RECORDING, DRIVEN ─────────────────────────────────────────────────
check_true("v86", "the recording leg ran and flushed a script",
           identical(one("rec_complete"), "1") &&
           identical(one("rec_flushed"), "1") &&
           identical(one("rec_emitted"), "1"))
check_true("v86", "the emitted script opens no dialog",
           identical(one("rec_beginpause"), "0"))
check_true("v86", "and replays both saves through the headless writer",
           identical(one("rec_savepanel_left"), "0") &&
           identical(one("rec_replaysave"), "2"))
check_true("v86", "the block still promises to hold every name below it",
           identical(one("rec_block_promise"), "1"))

# THE TWO DECLARATIONS, QUOTED FROM THE FILE A USER WOULD OPEN.
blk <- all_of("rec_blockline")
check_true("v86",
           sprintf("the block declares one format variable per save (%d)", length(blk)),
           length(blk) == 2)
if (length(blk) == 2) {
    check_true("v86",
               sprintf("the first is the first save's choice (%s)", blk[1]),
               grepl('^figureFormat\\$ *= "PNG, EPS"', blk[1]))
    check_true("v86", "... and its comment names the step it belongs to",
               grepl("step 2 \\(save\\)$", blk[1]))
    check_true("v86",
               sprintf("the second is the second save's, under its own name (%s)",
                       blk[2]),
               grepl('^figureFormat2\\$ *= "PNG, PDF"', blk[2]))
    check_true("v86", "... and its comment names its own step",
               grepl("step 4 \\(save\\)$", blk[2]))
    # THE NAMES DIFFER, WHICH IS THE WHOLE OF THE SERIALISATION. Two saves
    # sharing one variable is the collision this numbering exists to prevent,
    # and it would be invisible in a session that saved once.
    check_true("v86", "the two saves do not share one variable",
               !identical(sub(" *=.*$", "", blk[1]), sub(" *=.*$", "", blk[2])))
}
# AND THE STEPS READ THEM. A block that declares the variables and leaves the
# steps below holding their own literals passes every grep and is worth
# nothing.
check_true("v86",
           sprintf("the first save reads figureFormat$ (%s)", one("rec_save_call1")),
           grepl("outputFolder\\$, figureFormat\\$$", one("rec_save_call1")))
check_true("v86",
           sprintf("the second reads figureFormat2$ (%s)", one("rec_save_call2")),
           grepl("outputFolder\\$, figureFormat2\\$$", one("rec_save_call2")))

# ── THE REPLAY, AND WHAT IT LEFT ON THE DISK ──────────────────────────────
# The question a recording is kept for. Each figure must come back in ITS OWN
# formats -- and just as important, not in the other one's.
REPLAY <- list(
    list(arm = "same",
         want = list(figA = c("png", "eps"), figB = c("png", "pdf"))),
    # THE EDIT IS THE POINT OF EXPOSING THE VARIABLE AT ALL. One line of the
    # block changed -- the second save's format, PDF swapped for EPS -- and
    # nothing else in the file touched. If the second figure does not change
    # format, the block is decoration; if the FIRST one changes too, the
    # variables are shared and the serialisation is a fiction.
    list(arm = "edited",
         want = list(figA = c("png", "eps"), figB = c("png", "eps")))
)
for (R in REPLAY) {
    arm <- R$arm
    check_true("v86", sprintf("the %s replay ran without aborting", arm),
               identical(one(paste0("rec_", arm, "_ran")), "1") &&
               identical(one(paste0("rec_", arm, "_abort")), "0"))
    for (stem in names(R$want)) {
        for (ext in c("png", "eps", "pdf")) {
            k <- sprintf("rec_%s_%s_%s", arm, stem, ext)
            want <- if (ext %in% R$want[[stem]]) "1" else "0"
            check_true("v86",
                       sprintf("%s replay: %s came back %s %s", arm, stem,
                               if (want == "1") "with its" else "with no", ext),
                       identical(one(k), want))
        }
    }
    # AND THE FILES ARE WHAT THEY CLAIM TO BE, read here out of the bytes.
    files <- all_of(paste0("rec_", arm, "_file"))
    figs <- files[grepl("\\.(png|eps|pdf)$", files)]
    # Resolved against this checkout for the reason given at the leg check
    # above: the recorded path is absolute on the machine that drove the rig.
    rhere <- function(f) file.path(VF_DIR, "files", paste0("replay_", arm),
                                   basename(f))
    check_true("v86",
               sprintf("%s replay: every figure it wrote carries its own marker (%d)",
                       arm, length(figs)),
               length(figs) == 4 &&
               all(vapply(figs,
                          function(f) starts_with_marker(
                              rhere(f), MARKERS[[tolower(sub("^.*\\.", "", f))]]),
                          logical(1))))
}
check_true("v86", "the edit changed exactly one line of the block",
           identical(one("rec_edit_lines_changed"), "1"))
check_true("v86", "and nothing at all below it",
           identical(one("rec_edit_below_block"), "0"))

if (!exists("EML_SUITE")) {
    eml_report("v86 vector figure export")
    eml_exit()
}
