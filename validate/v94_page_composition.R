# ============================================================================
# v94_page_composition.R -- a page is composed of panels, and the page is the
# extent union
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS IS ABOUT. The draw dialog carries two controls: "Erase page first",
# ticked by default, and a panel origin in typed inches. Unticking the erase
# adds the figure to whatever is on the page instead of replacing it, and the
# extent union -- which is already what Save writes -- grows to hold both.
# There is no page width, no page height and no grid anywhere in the plugin:
# the page is computed from what was drawn on it.
#
# THE CLAIM THAT MATTERS MOST IS THE ONE ABOUT WHAT DID NOT CHANGE. A caller
# that says nothing about the page must get the figure it has always got.
# Section 1 asserts that as a comparison between two files the harness
# produced in the same run -- the same figure drawn once through the page
# controls at their defaults and once with those globals never assigned --
# rather than against a hash written into this file, which would only say that
# nothing had changed since somebody typed a hash.
#
# ============================================================================
# WHAT THIS FILE READS
# ============================================================================
#
# harness/compose/out/COMPOSE.tsv and the PNGs beside it. Every case is one or
# more presses of Draw through @emlGraphsDrawWithLegendRoom -- the graphs
# form's own dispatch loop, at file scope precisely so that a probe can drive
# it without a dialog. The harness supplies the form's globals and nothing
# else; the erase, the origin, the union and the parked legend are all the
# plugin's own.
#
#     bash harness/compose/run.sh      regenerate
#
# and the source of the four files the feature lives in, for the statements
# that are about SHAPE rather than about pixels: that the erase and the extent
# reset are one decision in one procedure, that no viewport in the form is
# selected at a page coordinate any more, and that the recorder states the
# page on draw steps and only on draw steps.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
#            https://github.com/embodied-music-lab/PraatGen
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

V <- "v94"

if (!exists("check_true")) source(file.path(
    Sys.getenv("EML_VALIDATE_DIR", unset = "validate"), "helpers.R"))

OUT <- repo_path("harness", "compose", "out")
TSVP <- file.path(OUT, "COMPOSE.tsv")

CASES <- c("single", "default_untouched", "side_by_side", "stacked",
           "overlay", "legend_band", "erase_offset")

ok_tsv <- check_true(V, "the compose harness has been driven",
                     file.exists(TSVP) && file.info(TSVP)$size > 0)
if (!ok_tsv) {
    check_true(V, paste0("COMPOSE.tsv is missing or empty",
                         "\n  Run: bash harness/compose/run.sh"), FALSE)
}

TR <- if (ok_tsv) {
    read.delim(TSVP, header = FALSE, sep = "\t", stringsAsFactors = FALSE,
               col.names = c("case", "key", "value"), colClasses = "character")
} else {
    data.frame(case = character(0), key = character(0), value = character(0),
               stringsAsFactors = FALSE)
}

# One measurement by name. Returns NA when the driver recorded none, which is
# what makes a check about a missing measurement fail rather than error.
trv <- function(case, key) {
    hit <- TR$value[TR$case == case & TR$key == key]
    if (length(hit) == 1L) hit else NA_character_
}
trn <- function(case, key) suppressWarnings(as.numeric(trv(case, key)))

for (cs in CASES)
    check_true(V, sprintf("%s: the case drew and saved", cs),
               identical(trv(cs, "verdict"), "OK"))

# ---------------------------------------------------------------------------
# 1. THE DEFAULT PATH DID NOT MOVE
#
# `single` sets emlEraseFirst = 1 and the origin to 0, 0 -- what the dialog's
# defaults produce. `default_untouched` draws the same figure and assigns none
# of the three, so it renders through @emlInitDrawingDefaults exactly as every
# caller that predates this feature does. The two PNGs are compared BYTE FOR
# BYTE.
#
# A DIFFERENCE OF ONE BYTE IS A FAILURE, deliberately, and it is the right
# strictness here: these are two renders of one figure in one process pair, on
# one Praat, from one seeded fixture. There is no jitter for a tolerance to
# absorb -- either the controls at their defaults are a no-op or they are not.
# ---------------------------------------------------------------------------
p_single <- file.path(OUT, "single.png")
p_untouched <- file.path(OUT, "default_untouched.png")
both_there <- file.exists(p_single) && file.exists(p_untouched)
check_true(V, "both renders of the default figure are on disk", both_there)
if (both_there) {
    a <- readBin(p_single, "raw", file.info(p_single)$size)
    b <- readBin(p_untouched, "raw", file.info(p_untouched)$size)
    check_true(V, sprintf(
        "the page controls at their defaults are a no-op (%d bytes, byte-identical)",
        length(a)),
        length(a) > 0 && identical(a, b))
    check_true(V, "...and the harness agrees the two hashes are one hash",
               identical(trv("single", "png_md5"),
                         trv("default_untouched", "png_md5")))
}
# Both are one press on a page of their own, and the union is the figure.
for (cs in c("single", "default_untouched")) {
    check_true(V, sprintf("%s: one press", cs),
               identical(trv(cs, "presses"), "1"))
    check_true(V, sprintf("%s: the union is the 6 x 4 figure", cs),
               isTRUE(all.equal(c(trn(cs, "union_x0"), trn(cs, "union_x1"),
                                  trn(cs, "union_y0"), trn(cs, "union_y1")),
                                c(0, 6, 0, 4))))
    check_true(V, sprintf("%s: the saved image is the figure at 300 dpi", cs),
               identical(trv(cs, "png_px"), "1800x1200"))
}

# ---------------------------------------------------------------------------
# 2. TWO PRESSES, ONE PAGE
#
# The origin is typed inches and the union is the arithmetic consequence.
# Side by side: a 6-wide panel at 0 and another at 6.5 make a page 12.5 wide
# and still 4 tall. Stacked: 4-tall panels at 0 and at 4.5 make a page 8.5
# tall and still 6 wide. THE PAGE IS NOT DECLARED ANYWHERE -- neither number
# is typed into anything; both fall out of the extent union.
# ---------------------------------------------------------------------------
COMPOSITE <- list(
    side_by_side = c(0, 12.5, 0, 4),
    stacked      = c(0, 6, 0, 8.5),
    overlay      = c(0, 6, 0, 4)
)
for (cs in names(COMPOSITE)) {
    check_true(V, sprintf("%s: two presses of Draw", cs),
               identical(trv(cs, "presses"), "2"))
    check_true(V, sprintf("%s: the page is the union [%s]", cs,
                          paste(COMPOSITE[[cs]], collapse = " ")),
               isTRUE(all.equal(c(trn(cs, "union_x0"), trn(cs, "union_x1"),
                                  trn(cs, "union_y0"), trn(cs, "union_y1")),
                                COMPOSITE[[cs]])))
}
# The saved image follows the union, in pixels, at 300 dpi.
check_true(V, "side_by_side: the file is the whole page, not the last panel",
           identical(trv("side_by_side", "png_px"), "3750x1200"))
check_true(V, "stacked: the file is the whole page, not the last panel",
           identical(trv("stacked", "png_px"), "1800x2550"))

# ---------------------------------------------------------------------------
# ERASE ON, ORIGIN OFFSET -- one panel, placed. The ruling makes these two
# fields independent: erasing and starting a composite are different acts, and
# a user may erase the page and then draw the first panel somewhere other than
# the corner. ONE press, so nothing is being composed yet; what is asserted is
# that the origin reached the drawing rather than being accepted and dropped.
#
# The union is the panel's own rectangle SHIFTED BY THE TYPED ORIGIN -- a 6x4
# panel at (2, 1) spans x 2..8 and y 1..5. Nothing declares those bounds; they
# are the arithmetic consequence of the two numbers the user typed, which is
# the whole point of computing the page rather than declaring it.
#
# A tree that ignored the origin entirely would report 0..6 and 0..4 here and
# would still pass every other check in this file, because every other case
# either uses the default origin or moves a SECOND panel. This is the only
# check that catches an origin accepted and discarded on the first panel.
check_true(V, "erase_offset: one press, so nothing is composed yet",
           identical(trv("erase_offset", "presses"), "1"))
check_true(V, "erase_offset: the union is the panel shifted to the typed origin [2 8 1 5]",
           isTRUE(all.equal(c(trn("erase_offset", "union_x0"),
                              trn("erase_offset", "union_x1"),
                              trn("erase_offset", "union_y0"),
                              trn("erase_offset", "union_y1")),
                            c(2, 8, 1, 5))))
# The saved image is one panel's worth of pixels -- offsetting the origin
# places the panel, it does not grow the page to reach it from the corner.
check_true(V, "erase_offset: the file is one panel, not the corner-to-panel span",
           identical(trv("erase_offset", "png_px"), "1800x1200"))

# THE OVERLAY IS PERMITTED, AND IT IS PERMITTED TO LOOK LIKE AN OVERLAY. Two
# presses at one origin with the erase off leave a page the size of one panel
# holding both figures' ink. Author ruling: a compositor who points two panels
# at one origin is doing manual layout and owns the result. The assertion is
# that the plugin did NOT quietly do something else -- refuse it, erase, or
# grow the page.
check_true(V, "overlay: the page is one panel wide and one panel tall",
           identical(trv("overlay", "png_px"), "1800x1200"))
check_true(V, "overlay: and it is not the same picture as one panel alone",
           !identical(trv("overlay", "png_md5"), trv("single", "png_md5")))

# ---------------------------------------------------------------------------
# 3. THE PARKED SEPARATE LEGEND CLEARS THE WHOLE PAGE
#
# `legend_band` draws three 6 x 9 panels down the left of the page, reaching
# 28 inches, and then a short 6 x 4 panel at the top right whose legend is set
# to "Separate figure". That legend is parked off the figure and saved as a
# second file, and the band it is parked in must be clear of EVERYTHING on the
# page -- not merely of the panel whose legend it is.
#
# The old rule took the band twelve inches below that panel's own bottom,
# floored at 24, which put it at 24.0 and drew it through the third left-hand
# panel (19 to 28). The rule now takes it twelve inches below the union.
# ---------------------------------------------------------------------------
check_true(V, "legend_band: four presses of Draw",
           identical(trv("legend_band", "presses"), "4"))
check_true(V, "legend_band: the page reaches 28 inches",
           isTRUE(all.equal(c(trn("legend_band", "union_x1"),
                              trn("legend_band", "union_y1")),
                            c(13, 28))))
park_top <- trn("legend_band", "park_y0")
park_bot <- trn("legend_band", "park_y1")
page_bot <- trn("legend_band", "union_y1")
check_true(V, "legend_band: a legend was parked", is.finite(park_top))
check_true(V, sprintf("legend_band: the band starts 12 in below the page (%s)",
                      format(park_top)),
           isTRUE(all.equal(park_top, page_bot + 12)))
check_true(V, "legend_band: and therefore below every panel on the page",
           isTRUE(park_top > page_bot))
# THE OLD NUMBER, NAMED. Had the band been taken from the legend-bearing
# panel's own bottom (4 inches) it would have been floored at 24 and drawn
# inside the third left-hand panel. This is the check that goes red if the
# union term is removed.
check_true(V, "legend_band: the band is not at the 24-inch floor",
           is.finite(park_top) && park_top > 24)
check_true(V, "legend_band: the band is a band, not a point",
           is.finite(park_bot) && park_bot > park_top)

# ---------------------------------------------------------------------------
# 4. THE ERASE AND THE EXTENT RESET ARE ONE DECISION, IN ONE PROCEDURE
#
# @emlAssertFullViewport saves the union. A union that survived an erase would
# save a rectangle larger than the ink; a union reset without an erase would
# save the last panel and crop the rest of the page off. The two have to move
# together or the saved image stops describing the page, so they are one
# procedure and the census below is what keeps them that way.
# ---------------------------------------------------------------------------
strip <- function(f) trimws(sub("[#;!].*$", "", readLines(f, warn = FALSE)))
fold_continuations <- function(x) {
    out <- character(0)
    for (ln in x) {
        if (startsWith(ln, "...") && length(out))
            out[length(out)] <- paste(out[length(out)], sub("^\\.\\.\\.", "", ln))
        else out <- c(out, ln)
    }
    out
}
proc_body <- function(src, name) {
    starts <- grep(sprintf("^procedure[[:space:]]+%s([[:space:]:]|$)", name), src)
    if (length(starts) != 1L) return(NULL)
    ends <- grep("^endproc[[:space:]]*$", src)
    to <- ends[ends > starts[1]][1]
    if (is.na(to)) return(NULL)
    fold_continuations(src[starts[1]:to])
}
# Which procedure each line sits in, for the inventories below.
owner_of <- function(src) {
    cur <- "<top level>"
    vapply(src, function(ln) {
        if (grepl("^procedure[[:space:]]+", ln))
            cur <<- sub("^procedure[[:space:]]+([A-Za-z0-9_]+).*$", "\\1", ln)
        cur
    }, character(1), USE.NAMES = FALSE)
}

GP <- repo_path("plugin_EML_StatsGraphs", "graphs", "eml-graph-procedures.praat")
FORM <- repo_path("plugin_EML_StatsGraphs", "graphs", "eml-graphs-form.praat")
REC <- repo_path("plugin_EML_StatsGraphs", "stats", "eml-record.praat")
OUTP <- repo_path("plugin_EML_StatsGraphs", "stats", "eml-output.praat")
GRAPHS_DIR <- repo_path("plugin_EML_StatsGraphs", "graphs")

gp <- strip(GP)
begin <- proc_body(gp, "emlBeginPanel")
check_true(V, "@emlBeginPanel exists and its body is closed", !is.null(begin))
if (!is.null(begin)) {
    check_true(V, "@emlBeginPanel sets the origin",
               any(grepl("^@emlSetPanelOrigin: \\.originX, \\.originY$", begin)))
    check_true(V, "@emlBeginPanel erases and resets the union together",
               any(grepl("^Erase all$", begin)) &&
               any(grepl("^@emlResetDrawnExtent$", begin)))
    # BOTH INSIDE THE SAME `if .erase = 1`, which is the statement. The two
    # lines being present says nothing on its own; being unreachable
    # separately is the whole of the guarantee.
    i_if <- grep("^if \\.erase = 1$", begin)
    i_else <- grep("^else$", begin)
    i_er <- grep("^Erase all$", begin)
    i_rs <- grep("^@emlResetDrawnExtent$", begin)
    check_true(V, "...and both sit in the erase arm, so neither can happen alone",
               length(i_if) == 1L && length(i_else) >= 1L &&
               length(i_er) == 1L && length(i_rs) == 1L &&
               i_er > i_if && i_rs > i_if &&
               i_er < i_else[1] && i_rs < i_else[1])
    check_true(V, "@emlBeginPanel counts the panels on the page",
               any(grepl("^emlPagePanelN = 1$", begin)) &&
               any(grepl("^emlPagePanelN = emlPagePanelN \\+ 1$", begin)))
}
check_true(V, "the defaults are erase-on at the origin",
           any(grepl("^emlEraseFirst = 1$", proc_body(gp, "emlInitDrawingDefaults"))))

# THE INVENTORY OF EVERY `Erase all` IN THE GRAPHS LAYER, attributed to its
# enclosing procedure, in the style v32 uses for @emlExpandDrawnExtent. An
# entry here that is not in the list below is a second place deciding whether
# the page is cleared, which is how the erase and the union come apart.
erasers <- character(0)
for (gf in sort(list.files(GRAPHS_DIR, pattern = "\\.praat$", full.names = TRUE))) {
    src <- strip(gf)
    own <- owner_of(src)
    hit <- which(grepl("^Erase all$", src))
    if (length(hit))
        erasers <- c(erasers, sprintf("%s @%s", basename(gf), own[hit]))
}
# @emlDrawLMMForest IS ON THIS LIST AND IS NOT A MISTAKE. It erases the page
# and does not reset the extent, and it draws at the raw origin while
# @emlSetAdaptiveTheme reports it at the panel origin -- D136, severity 3,
# measured and filed, fix DEFERRED to the mixed-model phase by author ruling
# because pinning it needs that phase's machinery. It is named here so the
# inventory is the truth rather than the intention; the day it is repaired,
# this line comes out and this check says so.
EXPECT_ERASERS <- c(
    "eml-draw-procedures.praat @emlDrawLMMForest",
    "eml-graph-procedures.praat @emlBeginPanel"
)
eml_census(V, "Erase all sites in plugin graphs/", erasers, EXPECT_ERASERS)

# ---------------------------------------------------------------------------
# 5. NO VIEWPORT IN THE FORM IS SELECTED AT A PAGE COORDINATE
#
# The form used to open its panel with a literal `0, figure_width, 0,
# totalCanvasHeight`, which is the one place a panel's rectangle was written
# down rather than derived. Every viewport it selects is now offset by the
# origin, so the rectangle the form opens and the rectangle
# @emlSetAdaptiveTheme lays out in are the same one.
# ---------------------------------------------------------------------------
form <- fold_continuations(strip(FORM))
form_vp <- grep("^Select[[:space:]]+(inner|outer)[[:space:]]+viewport:", form,
                value = TRUE)
check_true(V, sprintf("the form selects a viewport [%d]", length(form_vp)),
           length(form_vp) >= 1L)
check_true(V, "every viewport the form selects starts at the panel origin",
           length(form_vp) >= 1L &&
           all(grepl("viewport:[[:space:]]*emlPanelOriginX", form_vp)))
check_true(V, "the form's dispatch opens the panel through @emlBeginPanel",
           any(grepl("^@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst$",
                     form)))
check_true(V, "the form's dispatch does not erase for itself",
           !any(grepl("^Erase all$", form)))

# THE DIALOG'S THREE FIELDS. A field is what makes the choice per-draw and
# visible; a global set somewhere else would be the session mode this design
# refused.
form_raw <- readLines(FORM, warn = FALSE)
check_true(V, 'the draw dialog carries "Erase page first", ticked',
           any(grepl('^[[:space:]]*boolean: "Erase page first", 1$', form_raw)))
check_true(V, "the draw dialog carries a typed origin defaulting to 0, 0",
           any(grepl('^[[:space:]]*real: "Panel origin x \\(inches\\)", "0"$', form_raw)) &&
           any(grepl('^[[:space:]]*real: "Panel origin y \\(inches\\)", "0"$', form_raw)))
# NOT PERSISTED. Width and height are remembered across sessions because they
# describe the figure; erase and origin describe one step of one page and are
# asked again every press. A config_ key for either would be the hidden state
# the per-draw fields exist to avoid.
check_true(V, "neither control is written to the persisted config",
           !any(grepl("config_erase|config_panelOrigin", form_raw)))
check_true(V, "the fields reach the drawing layer's globals",
           any(grepl("^emlEraseFirst = erase_page_first$", form)) &&
           any(grepl("^emlPanelOriginX = panel_origin_x$", form)) &&
           any(grepl("^emlPanelOriginY = panel_origin_y$", form)))

# ---------------------------------------------------------------------------
# 6. THE HEADROOM NEGOTIATION STANDS DOWN ON A COMPOSED PAGE
#
# The loop draws, measures, ERASES and draws again on a widened axis. There is
# no way to erase one panel of a page, so a composed page takes one pass and
# the legend goes where it falls. The dialog says so beside the tickbox that
# causes it and the Info window says so at the moment it happens, both
# pointing at the two placements that keep the plot clear.
# ---------------------------------------------------------------------------
room <- proc_body(form, "emlGraphsDrawWithLegendRoom")
check_true(V, "@emlGraphsDrawWithLegendRoom's body is closed", !is.null(room))
if (!is.null(room)) {
    check_true(V, "the second pass is gated on the erase",
               any(grepl("^if emlEraseFirst = 0$", room)) &&
               any(grepl("^legendRoomMeasure = 0$", room)))
    check_true(V, "...and the measurement block is what the gate governs",
               any(grepl("^if legendRoomMeasure = 1$", room)))
    check_true(V, "the composed page is told, not left to find out",
               any(grepl("added to a", room)) &&
               any(grepl("Right \\|\\| \"of plot or Below plot", room) |
                   grepl("Right ", room)))
}
check_true(V, "the dialog says it beside the tickbox",
           any(grepl("composed page a legend inside the plot is not", form_raw)))

# ---------------------------------------------------------------------------
# 7. THE SAVE PANEL NAMES A PAGE
#
# A save writes the union, which is what it has always written. When the union
# holds more than one panel the title says "Save page" and one line gives the
# union's size, so nobody finds panel 1 in the file unwarned. There is
# deliberately no "finish page" action: that would be a mode to remember to
# leave, and an early save of a half-built page is a smaller image rather than
# a wrong one.
# ---------------------------------------------------------------------------
outp <- fold_continuations(strip(OUTP))
save_body <- proc_body(outp, "emlSavePanel")
check_true(V, "@emlSavePanel's body is closed", !is.null(save_body))
if (!is.null(save_body)) {
    check_true(V, "the panel title is a variable, not a literal",
               any(grepl("^beginPause: \\.saveTitle\\$$", save_body)))
    check_true(V, 'one panel is titled "Save" and several "Save page"',
               any(grepl('^\\.saveTitle\\$ = "Save"$', save_body)) &&
               any(grepl('^\\.saveTitle\\$ = "Save page"$', save_body)))
    check_true(V, "the page count is read through variableExists",
               any(grepl('variableExists \\("emlPagePanelN"\\)', save_body)))
    check_true(V, "the disclosure states the union's own measurements",
               any(grepl("emlDrawnMaxX - emlDrawnMinX", save_body)) &&
               any(grepl("emlDrawnMaxY - emlDrawnMinY", save_body)))
    check_true(V, "...through @eml_fixed, not fixed$",
               any(grepl("^@eml_fixed: \\.pageW, 2$", save_body)) &&
               !any(grepl("fixed\\$ \\(\\.pageW", save_body)))
    # NO FINISH-PAGE ACTION, anywhere the user can press one. Read out of the
    # CODE, comments stripped: both files argue in prose about why there is no
    # such action, and a search of the raw text would find the argument and
    # report it as the thing being argued against.
    check_true(V, "there is no finish-page action to remember to press",
               !any(grepl("[Ff]inish page", outp)) &&
               !any(grepl("[Ff]inish page", form)))
}

# ---------------------------------------------------------------------------
# 8. A RECORDED DRAWING CARRIES THE PAGE IT WENT ON
#
# Erase and origin are globals rather than arguments, so a recorded call
# carrying every argument faithfully still replays a different picture. The
# recorder writes the three values and the @emlBeginPanel call in front of
# every DRAW step, on the code column so that the manifest lifts them into the
# editable block by name, under the same run numbering as the columns and the
# axis pair. validate/v87 asserts the block that comes out; this asserts the
# machinery that puts it there.
# ---------------------------------------------------------------------------
rec <- fold_continuations(strip(REC))
cap <- proc_body(rec, "emlRecordCapturePage")
check_true(V, "@emlRecordCapturePage's body is closed", !is.null(cap))
if (!is.null(cap)) {
    check_true(V, "it states all three settings and the call that acts on them",
               any(grepl('"emlEraseFirst = "', cap)) &&
               any(grepl('"emlPanelOriginX = "', cap)) &&
               any(grepl('"emlPanelOriginY = "', cap)) &&
               any(grepl("@emlBeginPanel:", cap)))
    # A STATS-ONLY SCRIPT HAS NONE OF THEM, and reading one unconditionally is
    # what kills such a caller with "Unknown variable".
    check_true(V, "...and reads every one through variableExists",
               all(vapply(c("emlEraseFirst", "emlPanelOriginX", "emlPanelOriginY"),
                          function(g) any(grepl(sprintf('variableExists \\("%s"\\)', g), cap)),
                          logical(1))))
}
step <- proc_body(rec, "emlRecordStep")
check_true(V, "the page is stated on draw steps and only on draw steps",
           !is.null(step) &&
           any(grepl('^if \\.kind\\$ = "draw"$', step)) &&
           any(grepl("^@emlRecordCapturePage$", step)))
spec <- proc_body(rec, "emlRecordPageSpec")
check_true(V, "the manifest matches the page lines by name, not by position",
           !is.null(spec) &&
           any(grepl('^\\.base\\$ = "eraseFirst"$', spec)) &&
           any(grepl('^\\.base\\$ = "panelOriginX"$', spec)) &&
           any(grepl('^\\.base\\$ = "panelOriginY"$', spec)))
check_true(V, "...and refuses a right-hand side that is not a plain number",
           !is.null(spec) &&
           any(grepl("^if emlRecordQuotedLiteral\\.isNum = 1$", spec)))

# ---------------------------------------------------------------------------
# 9. THE Q-Q PLOT SAYS WHAT IT CLEARS
#
# @emlDrawQQPlot's self-erase goes through @emlBeginPanel, so the form's page
# controls reach it whenever a caller sets them. Nothing in the plugin does on
# that route -- the normality checker's dialog has no page controls -- so the
# header states plainly that a Q-Q drawn from there clears the page. "Known
# gap" is not an option this project uses.
# ---------------------------------------------------------------------------
QQ <- repo_path("plugin_EML_StatsGraphs", "graphs", "eml-draw-qq.praat")
qq_raw <- readLines(QQ, warn = FALSE)
qq <- fold_continuations(strip(QQ))
check_true(V, "@emlDrawQQPlot opens its panel through @emlBeginPanel",
           any(grepl("^@emlBeginPanel: \\.pageX, \\.pageY, \\.pageErase$", qq)))
check_true(V, "...and erases for itself nowhere",
           !any(grepl("^Erase all$", qq)))
check_true(V, "...and its viewport is offset by the origin it was given",
           any(grepl("^Select outer viewport: \\.pageX, \\.pageX \\+ \\.vpW, \\.pageY, \\.pageY \\+ \\.vpH$", qq)))
check_true(V, "the header says the figure clears the page",
           any(grepl("CLEARS THE PICTURE WINDOW", qq_raw)) &&
           any(grepl("eml-check-normality", qq_raw)))

# ---------------------------------------------------------------------------
# EVERY CASE THE DRIVER RECORDED IS ASSERTED ON
# ---------------------------------------------------------------------------
eml_census(V, "cases the compose harness drove", unique(TR$case), CASES)

# THE GUARD IS NOT DECORATION -- see v87's copy of this paragraph. eml_exit()
# quits as soon as any check in the run has failed, so an unguarded call here
# would end a red suite at this file and take everything after it with it.
if (!exists("EML_SUITE")) {
    eml_report("v94 -- a page is composed of panels")
    eml_exit()
}
