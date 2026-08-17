# ============================================================================
# v84_axis_refusal.R -- the graphs form refuses an axis pair it cannot read,
# and no axis pair guesses
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS IS ABOUT. Six axis pairs reach the graphs form from its dialogs --
# time, frequency, power, amplitude, value and the scatter's x. A pair whose
# maximum is below its minimum has two readings and no evidence that separates
# them:
#
#   the numbers were entered the wrong way round, or
#   one side was set and the other left at its default.
#
# A Praat form field cannot be left empty. So a user who wants a FLOOR of 300
# and no ceiling types 300 into the minimum, leaves the maximum at its 0
# default, and submits the pair (300, 0) -- which is byte-identical to the
# submission of a user who typed the two numbers backwards. There is nothing
# in the pair that tells them apart.
#
# THE FORM NOW REFUSES IT. The pair goes back to the user with both readings
# named, on a dialog, and NOTHING IS DRAWN. It is not a warning attached to a
# figure; it is the absence of a figure.
#
# WHAT THE FAILURE LOOKED LIKE, AND WHY IT WAS SILENT. The form used to pick
# the first reading and rewrite (300, 0) into (0, 300). A user asking for a
# floor of 300 got a ceiling of 300. No disclosure fired, because the only
# disclosure on that path speaks when a DATA POINT falls outside the range --
# and after the rewrite the data sits comfortably inside it. The figure was
# drawn, it looked like a figure, and its axis was the opposite of the one
# asked for.
#
# WHY THE 0 CASE IS NOT REPAIRED HERE, and this is a design constraint rather
# than an omission. 0 is simultaneously the auto sentinel every axis dialog
# names on its own face -- "both 0 = auto" -- and a perfectly ordinary bound.
# (0, 100) means the full range from zero to one hundred and must keep meaning
# it. So "0 means the other side was left blank" is not a reading the form can
# adopt: it would take the range away from everyone who typed a zero bound.
# The only behaviour that changes is max < min. Section 4 drives (0, 0) and
# (0, 400) and requires both to DRAW.
#
# ============================================================================
# WHAT THIS FILE READS, AND WHY IT IS NOT A READ OF THE SOURCE
# ============================================================================
#
# THE SUBJECT IS A DIALOG THAT APPEARS INSTEAD OF A FIGURE, and the thing
# being asserted is the "instead of". No amount of reading
# eml-graphs-form.praat can establish that: the file could contain a perfect
# refusal procedure, called from the right place, and still draw. So
# harness/axisrefuse/run.sh brings up Xvfb, a window manager and a compositor,
# launches the shipped form seven times, TYPES the reversed pair into the
# dialog field whose label the refusal quotes, and records
#
#   the sequence of dialog titles the form actually showed,
#   the text the refusal dialog actually displayed, read back off the pixels
#     it displayed it in with tesseract, and
#   the fraction of dark pixels in the Praat Picture window at the moment of
#     the refusal, against that same leg's own empty-window reading.
#
# THE INK MEASURE AND THE TITLE SEQUENCE ARE TWO DIFFERENT INSTRUMENTS, and
# the break tests measured which catches what rather than assuming. A form
# that DREW INSTEAD OF REFUSING has a figure on the page where the refusal
# should be: the swap_back and prose_only trees put the ink at the refusal
# step 5x and 140x above the empty reading. A form that refused and then DREW
# ANYWAY has an empty page at the refusal and a "Graph Complete" immediately
# after it: on the refuse_but_draw tree the ink at the refusal was correct to
# the last digit and the sequence read
# "Axis range > Graph Complete". Neither instrument is redundant.
#
# The ink baseline is per-leg rather than a constant written down here,
# because the Picture window is not empty even when nothing has been drawn --
# it carries its own rulers and margin marks, and their share of the frame is
# a property of the window rather than of the plugin.
#
# A COMPOSITOR IS PART OF THE INSTRUMENT. Without one, the region a modal
# dialog covers is not repainted and comes back from XGetImage as a black
# rectangle -- which reads as a very large figure. The harness records whether
# xcompmgr was running and this file requires it, because an ink measure taken
# without one is not a measure of anything.
#
# WHAT THE SOURCE IS STILL READ FOR, in section 5: that the guess is GONE, and
# that no pair can quietly acquire one. Those are claims about code that no
# drive can make, because a seventh pair added next year with a swap in it is
# not on any transcript. The two rules there are written to extend themselves:
#
#   THE SWAP IDIOM, by shape and not by name. Three consecutive statements
#   `a = b`, `b = c`, `c = a` are a swap whatever the variables are called.
#   HEAD has six. A rename does not evade it and a seventh pair cannot add one
#   without turning this red.
#
#   THE PAIR ROSTER, from the dialogs rather than from a list. Every axis for
#   which the form offers BOTH a `real: "<name> minimum"` and a
#   `real: "<name> maximum"` field must be named to the refusal. Add a seventh
#   pair's two fields without adding it to the sweep and this goes red with no
#   new test written, which is the invariant this file is for.
#
# ============================================================================
# THE TRAPS THIS FILE IS BUILT AGAINST
# ============================================================================
#
# A CHECK THAT MATCHES THE PROSE EXPLAINING THE FIX. Every source rule below
# runs on the file with Praat's comment lines dropped first. This repository
# has already shipped one check that matched the paragraph above a repair and
# stayed green when the repair was reverted and the paragraph left behind, and
# its house style puts a long paragraph above every repair, so the failure
# mode is guaranteed rather than possible. harness/axisrefuse/break.sh drives
# `prose_only` for exactly this: the swap restored, every explanatory sentence
# left in place.
#
# A CHECK THAT COUNTS CALL SITES. Breaking one of six and leaving five is the
# mutation that defeats a count, and it is the realistic one -- a partial
# revert, a merge, a pair added later. break.sh's `swap_back` restores the
# swap on the VALUE pair alone. Every other pair still refuses; every count of
# refusal calls is still six; the value leg's transcript is the only thing in
# this file that moves.
#
# A CHECK THAT ASSERTS A DIALOG APPEARED. "A window titled Axis range came up"
# is satisfied by a dialog that says nothing useful. break.sh's `numberless`
# keeps every word of the message and drops both numbers. Section 3 asserts
# the numbers, quoted from the pixels.
#
# A CHECK THAT CANNOT FAIL. The ink assertions are anchored to two readings
# taken in the same run on the same window -- empty and drawn -- and section 6
# requires them to DIFFER before either is believed. The refusal legs and the
# control leg point in opposite directions: six legs must show the refusal and
# the seventh must not, so a form that refused everything and a form that
# refused nothing are both red.
#
# ============================================================================
# THE BREAKS, AS MEASURED
# ============================================================================
# harness/axisrefuse/break.sh drives five deliberately broken copies of the
# tree through the same seven legs and runs this file against each. Recorded
# in harness/axisrefuse/out/BREAKS.tsv, with the count of red checks and which
# section produced them:
#
#   swap_back        11 red  the VALUE pair's swap restored and the other five
#                            left repaired. box_value's transcript reads
#                            "> Graph Complete" where the refusal belongs, its
#                            ink at that step is 0.0037 against an empty
#                            0.0007, the scatter's Y headline is gone, and the
#                            shape scan finds one swap. Five pairs still
#                            refuse, so every count in section 5 that is a
#                            count is still right -- which is the point of
#                            breaking one.
#   head_form        48 red  the whole form at HEAD: six swaps, no refusal
#                            procedure, no leg refused, nothing named.
#   refuse_but_draw  15 red  only `allFormsDone = 0` removed. Every word of
#                            every message is still correct and the ink at the
#                            refusal is still exactly the empty reading; the
#                            transcripts read "Axis range > Graph Complete".
#   numberless        8 red  the headline keeps every word and loses both
#                            numbers. Nothing else moves: the dialog still
#                            appears, the sequence is still right, the ink is
#                            still right. Only the quoted text fails, on all
#                            six pairs.
#   prose_only       46 red  the swap restored with every explanatory sentence
#                            left in place, including the ones that name the
#                            refusal. The shape scan reads code and finds it.
#
# Input:  harness/axisrefuse/out/AXISREFUSE.tsv   ($EML_AR_DIR overrides)
#         plugin/graphs/eml-graphs-form.praat     ($EML_AR_FORM overrides)
# Re-drive: bash harness/axisrefuse/run.sh
# Break:    bash harness/axisrefuse/break.sh
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

AR_DIR <- Sys.getenv("EML_AR_DIR", unset = "")
if (!nzchar(AR_DIR)) AR_DIR <- repo_path("harness", "axisrefuse", "out")
TSV <- file.path(AR_DIR, "AXISREFUSE.tsv")

FORM <- Sys.getenv("EML_AR_FORM", unset = "")
if (!nzchar(FORM)) FORM <- repo_path("plugin", "graphs", "eml-graphs-form.praat")

# ---------------------------------------------------------------------------
# THE TRANSCRIPT. Keys repeat -- one `leg` line per leg, one `..._shown` line
# per line of displayed text -- so it is read as a key/value stream rather
# than as a table.
# ---------------------------------------------------------------------------
have_tsv <- check_true("v84", sprintf("the driven transcript exists (%s)",
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

# Whitespace-normalised join of every line a dialog displayed. tesseract emits
# the dialog's own line breaks, and the message is one sentence run that GTK
# wraps where it likes, so comparing line by line would be comparing the
# window's width.
shown <- function(leg, step) {
    v <- all_of(sprintf("%s_s%d_shown", leg, step))
    if (!length(v)) return("")
    gsub("[[:space:]]+", " ", trimws(paste(v, collapse = " ")))
}

# ---------------------------------------------------------------------------
# 1. THE INSTRUMENT
# ---------------------------------------------------------------------------
check_true("v84", sprintf("the transcript names the Praat it drove (%s)",
                          one("praat_version")),
           isTRUE(grepl("^Praat ", one("praat_version"))))

# THE COMPOSITOR IS NOT OPTIONAL. See the header: without it the ink measure
# reads a dialog's unrepainted footprint as a figure, in the direction that
# makes a refusal that drew look like a refusal that did not.
check_true("v84", sprintf("a compositor was running for the ink measure (%s)",
                          one("compositor")),
           identical(one("compositor"), "running"))

# THE STALENESS BINDING. The transcript records the digest of the form's CODE
# -- comment lines dropped -- as it was when the legs were driven. A
# transcript taken from a different form is not evidence about this one. The
# digest ignores comments so that rewrapping a paragraph does not demand a
# fifteen-minute GUI re-drive; a change to any statement does.
code_sha <- NA_character_
if (file.exists(FORM) && nzchar(Sys.which("sha256sum"))) {
    src_all <- readLines(FORM, warn = FALSE)
    tmp <- tempfile()
    writeLines(src_all[!grepl("^[[:space:]]*[#;!]", src_all)], tmp)
    o <- suppressWarnings(system2("sha256sum", shQuote(tmp),
                                  stdout = TRUE, stderr = FALSE))
    unlink(tmp)
    if (length(o)) code_sha <- sub(" .*$", "", o[1])
}
check_true("v84",
           sprintf("the transcript was driven on THIS form's code (%s)",
                   substr(one("form_code_sha256"), 1, 12)),
           !is.na(code_sha) && identical(code_sha, one("form_code_sha256")))

check_true("v84", sprintf("every leg was driven (%s)", one("legs_driven")),
           identical(one("legs_driven"), "7"))

# ---------------------------------------------------------------------------
# 2. THE SIX PAIRS, EACH DRIVEN THROUGH ITS OWN DIALOG FIELD
#
# One row per leg: the page the pair lives on, the axis NAME the refusal must
# quote -- which is the label of the field that was typed into -- the minimum
# that was typed, and the pair VARIABLES in the form that the label stands
# for. The last column is what makes this a check of six pairs rather than of
# six sentences: section 5 requires exactly this set of variable pairs to be
# swept, so a leg naming an axis the sweep does not carry, or a sweep carrying
# a pair no leg drives, is visible.
# ---------------------------------------------------------------------------
LEGS <- list(
    list(leg = "pitch_time",  page = "Pitch Contour Settings",
         axes = list(c("Time", "0.3")),          pair = "time"),
    list(leg = "pitch_freq",  page = "Pitch Contour Settings",
         axes = list(c("Frequency", "300")),     pair = "freq"),
    list(leg = "wave_amp",    page = "Waveform Settings",
         axes = list(c("Amplitude", "0.2")),     pair = "amp"),
    list(leg = "spec_power",  page = "Spectrum Settings",
         axes = list(c("Power", "20")),          pair = "power"),
    list(leg = "box_value",   page = "Box Plot -- Column Mapping",
         axes = list(c("Value", "300")),         pair = "value"),
    # TWO PAIRS ON ONE PAGE, REVERSED TOGETHER. The scatter is the only page
    # carrying two, and it is the page that labels the value pair "Y" -- the
    # label the user reads is the label the message quotes.
    list(leg = "scatter_xy",  page = "Scatter Plot -- Column Mapping",
         axes = list(c("X", "300"), c("Y", "5")), pair = "scatterX+value")
)

REMEDY_1 <- "To set a full range, enter both values."
REMEDY_2 <- "For automatic scaling leave both at 0."
REMEDY_3 <- "(A one-sided limit isn't possible: 0 means auto, so the other side can't be left blank.)"

named_axes <- character(0)

for (L in LEGS) {
    lg <- L$leg

    # --- THE SEQUENCE THE FORM SHOWED -------------------------------------
    # Six dialogs, in this order, and the third one is a refusal rather than a
    # figure. Asserted as the whole sequence: a form that showed the refusal
    # and then went on to draw has the same third title and a different
    # fourth.
    seq_want <- c("EML Graphs", L$page, "Axis range",
                  "EML Graphs", L$page, "Graph Complete")
    seq_got <- vapply(1:6, function(i) {
        v <- one(sprintf("%s_s%d_title", lg, i))
        if (is.na(v)) "<missing>" else v
    }, "")
    check_true("v84",
               sprintf("%s: the form showed [%s]", lg,
                       paste(seq_got, collapse = " > ")),
               identical(seq_got, seq_want))

    # --- WHAT THE REFUSAL DISPLAYED ---------------------------------------
    txt <- shown(lg, 3)
    for (ax in L$axes) {
        headline <- sprintf("%s maximum (0) is below %s minimum (%s).",
                            ax[1], ax[1], ax[2])
        check_true("v84",
                   sprintf("%s: the dialog displayed \"%s\"", lg, headline),
                   grepl(headline, txt, fixed = TRUE))
        named_axes <- c(named_axes, ax[1])
    }
    # BOTH READINGS, NOT ONE. The user who reversed the pair needs the order;
    # the user who wanted a floor needs to be told a floor is not available
    # here and why. A message that named only one of them would leave the
    # other user with no next step.
    check_true("v84", sprintf("%s: ... and the full-range reading", lg),
               grepl(REMEDY_1, txt, fixed = TRUE))
    check_true("v84", sprintf("%s: ... and the auto reading", lg),
               grepl(REMEDY_2, txt, fixed = TRUE))
    check_true("v84", sprintf("%s: ... and why one-sided is not on offer", lg),
               grepl(REMEDY_3, txt, fixed = TRUE))

    # --- NOTHING WAS DRAWN ------------------------------------------------
    empty <- suppressWarnings(as.numeric(one(sprintf("%s_ink_empty", lg))))
    at_refusal <- suppressWarnings(as.numeric(one(sprintf("%s_s3_ink", lg))))
    at_draw <- suppressWarnings(as.numeric(one(sprintf("%s_s6_ink", lg))))
    check_true("v84",
               sprintf("%s: the Picture window at the refusal is the empty one (%s vs %s)",
                       lg, format(at_refusal), format(empty)),
               is.finite(empty) && is.finite(at_refusal) &&
                   isTRUE(all.equal(at_refusal, empty, tolerance = 1e-6)))
    # THE OTHER DIRECTION, IN THE SAME RUN ON THE SAME WINDOW. Without this
    # the ink check above is satisfied by an instrument that reads the same
    # number whatever is on the screen.
    check_true("v84",
               sprintf("%s: the corrected resubmission drew (%s vs %s)",
                       lg, format(at_draw), format(empty)),
               is.finite(at_draw) && is.finite(empty) && at_draw > empty * 2)

    check_true("v84",
               sprintf("%s: the workflow ran to Done rather than hanging", lg),
               lg %in% all_of("leg_returned"))
    check_true("v84", sprintf("%s: the display was clear for the next leg", lg),
               identical(one(sprintf("%s_display_clear", lg)), "yes"))
}

# ---------------------------------------------------------------------------
# 3. ONE PAGE, TWO CONFLICTS, ONE ROUND TRIP
#
# The scatter leg reverses both of its pairs at once. A sweep that stopped at
# the first refusal would name X and be silent about Y, and the user would fix
# X, press Draw, and be refused again -- which is the same dialog twice for
# one submission. Both headlines are asserted above; that they arrived
# together, on ONE dialog, is asserted here.
# ---------------------------------------------------------------------------
sc <- shown("scatter_xy", 3)
check_true("v84",
           "the scatter's two reversed pairs were named on the same dialog",
           grepl("X maximum (0) is below X minimum (300).", sc, fixed = TRUE) &&
           grepl("Y maximum (0) is below Y minimum (5).", sc, fixed = TRUE))

# ---------------------------------------------------------------------------
# 4. 0 IS STILL A BOUND, AND (0, 0) IS STILL AUTO
#
# The control leg draws twice and is refused neither time: once on (0, 0),
# which is the auto sentinel, and once on (0, 400), which is the ordinary full
# range from zero to four hundred. A "repair" that read 0 as "left blank"
# would refuse the second, and every assertion in section 2 would still pass.
# ---------------------------------------------------------------------------
bb_seq <- vapply(1:6, function(i) {
    v <- one(sprintf("box_bound_s%d_title", i))
    if (is.na(v)) "<missing>" else v
}, "")
check_true("v84",
           sprintf("box_bound: auto and a zero bound both drew [%s]",
                   paste(bb_seq, collapse = " > ")),
           identical(bb_seq, c("EML Graphs", "Box Plot -- Column Mapping",
                               "Graph Complete", "EML Graphs",
                               "Box Plot -- Column Mapping", "Graph Complete")))
check_true("v84", "box_bound: no refusal was shown on either submission",
           !("Axis range" %in% bb_seq))
bb_empty <- suppressWarnings(as.numeric(one("box_bound_ink_empty")))
for (st in c(3, 6)) {
    v <- suppressWarnings(as.numeric(one(sprintf("box_bound_s%d_ink", st))))
    check_true("v84",
               sprintf("box_bound: step %d put ink on the page (%s vs %s)",
                       st, format(v), format(bb_empty)),
               is.finite(v) && is.finite(bb_empty) && v > bb_empty * 2)
}

# ---------------------------------------------------------------------------
# 5. THE GUESS IS GONE, AND NO PAIR CAN ACQUIRE ONE
#
# Comments are dropped FIRST. See the header: a check that matches the
# paragraph explaining a repair goes green on a tree where the repair was
# reverted and the paragraph left behind, and this file's subject sits under
# one of the longest paragraphs in the plugin.
# ---------------------------------------------------------------------------
src <- if (file.exists(FORM)) readLines(FORM, warn = FALSE) else character(0)
check_true("v84", sprintf("the form is readable (%s)", basename(FORM)),
           length(src) > 0)
code <- src[!grepl("^[[:space:]]*[#;!]", src)]
stmt <- trimws(code); stmt <- stmt[nzchar(stmt)]

# THE SWAP IDIOM, BY SHAPE. `a = b` / `b = c` / `c = a` on three consecutive
# statements is a swap whatever the three names are. HEAD carries six of them;
# a renamed temporary, a seventh pair, or a partial revert all show up here.
asgn <- regmatches(stmt, regexec("^([A-Za-z_][[:alnum:]_.$]*) *= *([A-Za-z_][[:alnum:]_.$]*)$",
                                 stmt))
lhs <- vapply(asgn, function(m) if (length(m) == 3) m[2] else NA_character_, "")
rhs <- vapply(asgn, function(m) if (length(m) == 3) m[3] else NA_character_, "")
n_swap <- 0L
swap_where <- character(0)
if (length(stmt) >= 3) {
    for (i in seq_len(length(stmt) - 2L)) {
        if (is.na(lhs[i]) || is.na(lhs[i + 1L]) || is.na(lhs[i + 2L])) next
        if (identical(lhs[i + 1L], rhs[i]) &&
            identical(lhs[i + 2L], rhs[i + 1L]) &&
            identical(rhs[i + 2L], lhs[i])) {
            n_swap <- n_swap + 1L
            swap_where <- c(swap_where, stmt[i])
        }
    }
}
check_true("v84",
           sprintf("no three statements in the form swap a pair%s",
                   if (n_swap) paste0(" -- found ", n_swap, ": ",
                                      paste(swap_where, collapse = "; "))
                   else ""),
           n_swap == 0L)

# ONE JUDGE. The comparison that decides a pair is unusable exists once. Six
# copies of it is five pairs repaired and a sixth found next year.
n_cmp <- sum(grepl("^if +[[:alnum:]_.$]*[Mm]ax[[:alnum:]_.$]* *< *[[:alnum:]_.$]*[Mm]in[[:alnum:]_.$]* *$",
                   stmt))
check_true("v84", sprintf("the max-below-min test is written once (%d)", n_cmp),
           n_cmp == 1L)
check_true("v84", "the refusal procedure is defined once",
           sum(grepl("^procedure emlGraphsAxisPairRefusal\\b", stmt)) == 1L)
check_true("v84", "the sweep procedure is defined once",
           sum(grepl("^procedure emlGraphsCheckAxisRanges\\b", stmt)) == 1L)

# THE PAIR ROSTER, DERIVED FROM THE DIALOGS. Every axis the form offers a
# minimum AND a maximum field for must be named to the refusal. This is the
# rule a seventh pair trips without anyone writing a new test.
lab <- function(side) {
    pat <- sprintf('real: "([^"]*) %s"', side)
    hits <- grep(pat, code, value = TRUE)
    unique(sub(sprintf('.*real: "([^"]*) %s".*', side), "\\1", hits))
}
pair_labels <- sort(intersect(lab("minimum"), lab("maximum")))
check_true("v84",
           sprintf("the form's dialogs offer %d min/max pairs [%s]",
                   length(pair_labels), paste(pair_labels, collapse = ", ")),
           length(pair_labels) >= 6)

i0 <- grep("^procedure emlGraphsCheckAxisRanges\\b", stmt)
i1 <- if (length(i0)) which(stmt == "endproc" & seq_along(stmt) > i0[1])[1] else NA
sweep_body <- if (length(i0) && !is.na(i1)) stmt[i0[1]:i1] else character(0)
sweep_names <- unique(gsub('"', "",
    unlist(regmatches(sweep_body, gregexpr('"[^"]*"', sweep_body)))))
missing_lab <- setdiff(pair_labels, sweep_names)
check_true("v84",
           sprintf("every axis the dialogs offer a pair for is named to the refusal%s",
                   if (length(missing_lab))
                       paste0(" -- not named: ", paste(missing_lab, collapse = ", "))
                   else ""),
           length(missing_lab) == 0L)

# AND THE VARIABLES BEHIND THE LABELS. The roster above is about names the
# user reads; this is about the six pairs the draw layer is handed. Both are
# needed: a sweep could name every label and pass the same variables twice.
calls <- grep("@emlGraphsAxisPairRefusal:", stmt, value = TRUE)
args <- sub(".*@emlGraphsAxisPairRefusal: *", "", calls)
pair_vars <- vapply(strsplit(args, " *, *"), function(a) {
    if (length(a) < 3) return(NA_character_)
    paste(a[2], a[3], sep = "/")
}, "")
want_vars <- c("timeMin/timeMax", "freqMin/freqMax", "powerMin/powerMax",
               "ampMin/ampMax", "valueMin/valueMax",
               "scatterXMin/scatterXMax")
check_true("v84",
           sprintf("all six pair variables are swept, each once [%s]",
                   paste(sort(pair_vars), collapse = ", ")),
           setequal(pair_vars, want_vars) &&
               length(pair_vars) == length(want_vars))
check_true("v84", "the sweep is the only caller of the refusal",
           length(calls) == length(want_vars) &&
               all(calls %in% sweep_body))

# THE SWEEP IS INSIDE THE FORM LOOP AND THE PUBLICATION IS AFTER IT. A sweep
# that ran after `until allFormsDone = 1` could still show the dialog and
# could not send the form back, because the loop it would have to re-enter has
# already ended.
i_sweep <- grep("^@emlGraphsCheckAxisRanges$", stmt)
i_until <- grep("^until allFormsDone = 1$", stmt)
i_pub <- grep("^@emlGraphsPublishAxisRequest$", stmt)
check_true("v84",
           "the sweep runs inside the form loop, ahead of the publication",
           length(i_sweep) == 1L && length(i_until) == 1L && length(i_pub) == 1L &&
               i_sweep < i_until && i_until < i_pub)

# THE REFUSAL SENDS THE FORM BACK. The driven legs are what prove it took
# effect; this is what stops the line being deleted in an edit that no leg of
# this rig happens to cover.
i_show <- grep("^@emlGraphsShowAxisRefusal$", stmt)
check_true("v84", "a refusal clears the form-complete flag",
           length(i_show) == 1L && any(stmt[i_show + 1L] == "allFormsDone = 0"))

# ---------------------------------------------------------------------------
# 6. VACUITY GUARDS
#
# Two ways this file could be green and mean nothing, and both are asserted
# against rather than trusted.
# ---------------------------------------------------------------------------
# ONE: the axis roster the legs actually exercised. A transcript missing a leg
# would quietly reduce this file to five pairs.
check_true("v84",
           sprintf("the drive named all seven axis labels [%s]",
                   paste(sort(unique(named_axes)), collapse = ", ")),
           setequal(unique(named_axes),
                    c("Time", "Frequency", "Power", "Amplitude", "Value", "X", "Y")))

# TWO: the instrument distinguishes. The refusal legs must show the refusal
# and the control leg must not -- a partition, which no constant satisfies.
n_refusals <- sum(vapply(LEGS, function(L)
    identical(one(sprintf("%s_s3_title", L$leg)), "Axis range"), TRUE))
check_true("v84",
           sprintf("six legs were refused and the control leg was not (%d)",
                   n_refusals),
           n_refusals == 6L &&
               !identical(one("box_bound_s3_title"), "Axis range"))

if (!exists("EML_SUITE")) {
    eml_report("v84 axis refusal — the form refuses a pair it cannot read")
    eml_exit()
}
