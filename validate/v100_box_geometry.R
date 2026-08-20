# ============================================================================
# v100_box_geometry.R -- the frame, the ticks and the data are one rectangle
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# THE DEFECT THIS EXISTS FOR. Praat stores a viewport as an OUTER rectangle.
# `Select inner viewport` converts what it is handed using the MARGINS IN
# EFFECT AT THAT MOMENT, and every later drawing command converts back using
# the margins in effect at ITS moment. Margin width is a function of font
# size. So a figure whose ambient font size changes between two
# coordinate-dependent commands draws those two commands on two DIFFERENT
# rectangles. Measured on Praat 6.6.30, and reproduced on demand by
# harness/boxgeom/break.sh: a viewport selected at 10 point and a box drawn at
# 11 put the box 2.92% narrower and 2.59% shorter than the gridlines drawn at
# 10 -- the
# frame sitting inside its own grid, tick marks standing clear of the axis
# they belong to, and the data hanging out over the edge.
#
# NOTHING ERRORS WHEN THAT HAPPENS, and that is the whole problem. The figure
# saves, the pixel counts every other harness takes come back normal, and the
# only witness is where the ink landed. @emlSetPanelViewport and
# @emlDrawInnerBoxIf both carry comments naming this hazard (BUG-007/008); the
# rule they state -- font size, THEN select the viewport, THEN the axes, THEN
# the box -- had no check behind it until this file.
#
# WHY EPS AND NOT A PNG. Praat's EPS writes every path as device coordinates,
# so the frame, each tick mark and each stroke of data are all readable as
# NUMBERS out of one file. A PNG of the same figure would need a pixel hunt to
# find the frame at all, and could not distinguish a tick anchored on the axis
# from one a thousandth of an inch off it -- which is the size of the honest
# rounding here, three orders of magnitude below the defect.
#
# THE GRAMMAR, READ OFF THE FILES RATHER THAN ASSUMED. Praat's prolog defines
# `N` as newpath, `M` as newpath-moveto and `L` as rlineto, and emits:
#
#   N x0 y0 M x1 y1 lineto x2 y2 lineto x3 y3 lineto closepath stroke
#       a closed quadrilateral, stroked. The INNER BOX is one of these.
#   N x0 y0 M x1 y1 lineto ... closepath fill
#       the same shape, filled: a bar, a box-plot body, a violin slab. DATA.
#   N x y moveto / dx dy L / ... / stroke
#       a polyline in RELATIVE deltas. Gridlines, tick marks and every
#       stroked series are all this shape, so the shape alone decides nothing.
#   N x y r FC   and   N x y r C
#       a filled or stroked disc: a scatter marker. DATA.
#   x y M (text) show
#       a glyph origin. Not ink this file reasons about -- a tick NUMBER sits
#       outside the frame by design and would fail containment.
#
# SO THE THREE FAMILIES ARE TOLD APART BY WHERE THEY LAND, NOT BY THEIR SHAPE:
#
#   the BOX    the largest axis-aligned stroked quadrilateral in the file,
#              once it has been confirmed to ENCLOSE every other one. Bar
#              outlines, box-plot bodies and a legend frame are all the same
#              command, and size alone does not separate them: on the bar
#              chart the frame is 10.0 times the largest bar and on the
#              histogram 8.2 times, so a factor rule written from one of those
#              two figures is wrong on the other. Containment is not a
#              threshold and needs no number.
#   a TICK     a short straight two-point segment whose length matches the
#              length of the segments that FOLLOW A TICK NUMBER in the file.
#              Deliberately not "a segment anchored on the frame": see the
#              long note at the classifier, where a definition of that shape is
#              shown to be one a displaced mark cannot fail.
#   a GRIDLINE a straight two-point segment touching BOTH opposite edges and
#              spanning the frame. Furniture, and excluded from the data so
#              that "the data reaches the edge" cannot be satisfied by a
#              gridline that reaches it by construction.
#   DATA       everything else carrying coordinates.
#
# WHAT IS ASSERTED, per figure:
#
#   1. There is exactly one such frame and it is a rectangle with area.
#   2. Every tick's anchored end lies ON the edge it belongs to, its free end
#      lies OUTSIDE, and its position along the axis lies WITHIN the frame.
#      This is the sharpest single statement here: a margin mark and the frame
#      are converted out of the same viewport, so they agree to four decimal
#      places or the ambient state changed between them.
#   3. The extreme tick on each margin is within one tick spacing of the far
#      edge, in both directions. This is the half of the check that pins the
#      edges the ticks do not touch: shrink the frame and the last bottom tick
#      is suddenly outside it; grow the frame and the gap opens past a step.
#   4. Every data coordinate is inside the frame.
#   5. The data REACHES the frame on the edges the case claims it reaches.
#      (4) catches a frame drawn smaller than the data; (5) catches one drawn
#      larger, which would otherwise pass containment quietly.
#
# THE TOLERANCES, AND WHERE THEY COME FROM. One device unit here is 0.12
# point, or 1/600 inch. Measured across the thirteen figures:
#
#   tick anchoring   worst observed error 0.004 units -- pure decimal rounding
#                    in the EPS, since Praat prints 33280.34 and 19.656 and
#                    the sum has to land on 33300.
#   containment      worst observed overshoot 0.0004 units, on the line chart,
#                    where a series is eleven relative deltas accumulated.
#
# so EPS_TOL is 0.5 units (1/1200 inch, 0.02 mm) -- a hundred times the
# observed error and a hundredth of the ~75 units a single point of font
# difference moves the frame on a six-inch figure.
#
#   reach            worst observed distance from an edge a case CLAIMS is
#                    1.0 unit, the waveform's right edge: the last sample of a
#                    sound is one sample short of the end of the time axis,
#                    which is the object's sampling and not the renderer's
#                    geometry. The nearest distance on an edge no case claims
#                    is 25.9 units.
#
# so REACH_TOL is 2.0 units, thirteen times clear of the nearest thing it
# must NOT admit and still thirty times finer than the defect.
#
# HOW TO RUN IT
#
#     bash harness/boxgeom/run.sh          render the thirteen figures
#     Rscript validate/v100_box_geometry.R
#     bash harness/boxgeom/break.sh        seed the font change, see it red
#
# TWO BREAKS, BECAUSE ONE POINT OF FONT MOVES DIFFERENT THINGS DEPENDING ON
# WHERE IT IS PLANTED. Planted in @emlDrawInnerBoxIf the FRAME goes out of step
# with everything drawn before it: 32 red, on all thirteen types, worst
# overshoot 42.99 device units. Planted in @emlDrawAlignedMarksBottom the
# BOTTOM MARGIN goes out of step with the frame: 17 red on the seven types
# whose x axis is a numeric lattice, every mark standing 23.34 units off its
# own axis, and containment sees none of it -- which is why both directions
# are checked and why the second break exists.
#
# $EML_BG_DIR points this file at a different artefact, which is how the break
# run scores a patched copy of the tree without the working tree being touched.
#
# Base R only. No packages.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

V <- "v100"

if (!exists("check_true")) source(file.path(
    Sys.getenv("EML_VALIDATE_DIR", unset = "validate"), "helpers.R"))

OUT  <- Sys.getenv("EML_BG_DIR", unset = repo_path("harness", "boxgeom", "out"))
TSVP <- file.path(OUT, "BOXGEOM.tsv")

EPS_TOL   <- 0.5
REACH_TOL <- 2.0

# One case per graph type, in the form's own order (graphTypeName$[1..13] in
# eml-graphs-form.praat). The census at the foot compares this list against
# what the driver actually wrote: a figure rendered that nothing here reads is
# silent non-coverage, and a name here the driver never rendered is a check
# passing on nothing.
CASES <- c("pitch_contour", "waveform", "spectrum", "ltas", "line_chart",
           "bar_chart", "violin", "scatter", "box_plot", "histogram",
           "grouped_violin", "grouped_box", "spaghetti")

# ---------------------------------------------------------------------------
# THE ARTEFACT MUST EXIST BEFORE ANYTHING IS CLAIMED ABOUT IT.
# A missing TSV is a driver that did not run, and a validator that quietly
# asserts nothing in that case is worse than one that fails: the suite goes
# green on thirteen figures nobody made.
# ---------------------------------------------------------------------------
have_tsv <- file.exists(TSVP) && file.info(TSVP)$size > 0
if (!have_tsv) {
    check_true(V, paste0("BOXGEOM.tsv is missing or empty",
                         "\n  Run: bash harness/boxgeom/run.sh"), FALSE)
}

# NO EARLY EXIT, AND THAT IS DELIBERATE. run_all.R sources this file with no
# tryCatch around it, on purpose (see the note there), so an exit here would
# take the suite with it. An empty frame instead lets every per-figure check
# below run and go red on its own terms, which names the thirteen figures that
# are missing rather than one line saying a file was not there.
TR <- if (have_tsv) {
    read.delim(TSVP, header = FALSE, sep = "\t", quote = "",
               comment.char = "", stringsAsFactors = FALSE,
               col.names = c("case", "key", "value"), colClasses = "character")
} else {
    data.frame(case = character(0), key = character(0), value = character(0),
               stringsAsFactors = FALSE)
}
val <- function(case, key) {
    v <- TR$value[TR$case == case & TR$key == key]
    if (length(v) == 1L) v else NA_character_
}

# ---------------------------------------------------------------------------
# THE NUMBER TOKENIZER IS NOT A REGEX OVER THE WHOLE LINE, and the first
# version of it was. "[-+0-9.eE]+" matches the "e" in `lineto` and the "e" in
# `moveto`, so every closepath quadrilateral came back with eleven
# coordinates, none of the rectangles parsed, and every figure reported no
# frame at all. Splitting on whitespace and keeping the tokens that ARE
# numbers cannot make that mistake.
# ---------------------------------------------------------------------------
NUMTOK <- "^[-+]?([0-9]+\\.?[0-9]*|\\.[0-9]+)([eE][-+]?[0-9]+)?$"
nums <- function(s) {
    t <- strsplit(trimws(s), "[ \t]+")[[1]]
    as.numeric(t[grepl(NUMTOK, t)])
}

# ---------------------------------------------------------------------------
# parse_eps -- every path in the file, in device coordinates.
#
# Returns three lists: closed polygons (with the operator that ended them),
# polylines (absolute coordinates, with the relative deltas already summed),
# and discs. Everything before %%EndSetup is prolog -- the PraatEncoding
# vector alone is two hundred glyph names -- and reading it as geometry would
# invent paths out of a font table.
# ---------------------------------------------------------------------------
parse_eps <- function(path) {
    L <- trimws(readLines(path, warn = FALSE))
    start <- which(grepl("^%%EndSetup", L))
    if (length(start) == 0L) return(NULL)
    L <- L[seq(start[1] + 1L, length(L))]
    segs <- list(); polys <- list(); discs <- list(); i <- 1L
    while (i <= length(L)) {
        s <- L[i]
        if (grepl("^N .*closepath (stroke|fill)$", s)) {
            v <- nums(s)
            polys[[length(polys) + 1L]] <- list(
                x = v[seq(1, length(v), 2)], y = v[seq(2, length(v), 2)],
                op = sub(".*closepath ", "", s))
            i <- i + 1L; next
        }
        if (grepl("^N .* (FC|C)$", s)) {
            v <- nums(s)
            discs[[length(discs) + 1L]] <- list(x = v[1], y = v[2])
            i <- i + 1L; next
        }
        if (grepl("^N .* moveto$", s)) {
            v <- nums(s); x <- v[1]; y <- v[2]; px <- x; py <- y; j <- i + 1L
            # `L` IS RLINETO, so a polyline's coordinates only exist as a
            # running sum. Reading the deltas as positions put the waveform's
            # whole trace within a few units of the origin, which containment
            # then reported as the figure being drawn outside its own frame.
            while (j <= length(L) && grepl("^[-+0-9.][^a-zA-Z]* L$", L[j])) {
                d <- nums(L[j])
                x <- x + d[1]; y <- y + d[2]
                px <- c(px, x); py <- c(py, y); j <- j + 1L
            }
            segs[[length(segs) + 1L]] <- list(x = px, y = py, at = i)
            i <- j; next
        }
        i <- i + 1L
    }
    # WHERE THE GLYPHS ARE, not what they say. A tick that carries a number
    # is emitted as the number and then the mark, two or three lines apart,
    # and that adjacency is what identifies a mark no matter where it landed.
    list(segs = segs, polys = polys, discs = discs,
         shows = which(grepl("\\) show$", L)))
}

# is_frame -- a closed path that is an axis-aligned rectangle, stroked.
is_frame <- function(p) {
    p$op == "stroke" && length(p$x) == 4L && length(p$y) == 4L &&
        !any(is.na(c(p$x, p$y))) &&
        length(unique(round(p$x, 3))) == 2L &&
        length(unique(round(p$y, 3))) == 2L
}

# ---------------------------------------------------------------------------
# THE WALK. Every figure is measured, then the assertions are made per figure
# so that a red line names the type it is about.
# ---------------------------------------------------------------------------
present <- unique(TR$case)
n_tick <- 0L; n_grid <- 0L; n_data <- 0L
worst_anchor <- 0; worst_out <- 0; worst_reach <- 0

for (case in CASES) {
    epsf <- file.path(OUT, paste0(case, ".eps"))
    if (!file.exists(epsf)) {
        check_true(V, sprintf("%s: the driver saved a vector figure", case),
                   FALSE)
        next
    }
    P <- parse_eps(epsf)
    frames <- Filter(is_frame, P$polys)
    areas <- vapply(frames, function(r) diff(range(r$x)) * diff(range(r$y)),
                    numeric(1))

    # (1) THE FRAME. The largest axis-aligned stroked rectangle in the file --
    # and then that identification is CHECKED rather than assumed, because a
    # stroked rectangle is not a rare shape here: a bar chart outlines every
    # bar with the same command, a box plot outlines every body, and a legend
    # draws a frame. What separates the inner box from all of them is that it
    # CONTAINS them. A file in which the largest stroked rectangle does not
    # enclose the others has furniture this file does not understand, and
    # saying so is better than measuring the wrong rectangle.
    ok_one <- length(frames) >= 1L && max(areas) > 0
    if (!check_true(V, sprintf("%s: the figure carries an inner box", case),
                    ok_one)) next
    B <- frames[[which.max(areas)]]
    x0 <- min(B$x); x1 <- max(B$x); y0 <- min(B$y); y1 <- max(B$y)
    encloses <- all(vapply(frames, function(r)
        min(r$x) >= x0 - EPS_TOL && max(r$x) <= x1 + EPS_TOL &&
        min(r$y) >= y0 - EPS_TOL && max(r$y) <= y1 + EPS_TOL, logical(1)))
    check_true(V, sprintf(
        "%s: the inner box encloses every other stroked rectangle", case),
        encloses)

    on <- function(a, b) abs(a - b) <= EPS_TOL
    bw <- x1 - x0; bh <- y1 - y0

    # (2) FINDING THE TICK MARKS, AND WHY NOT BY WHERE THEY LANDED.
    #
    # The first version of this defined a tick as a short segment with one end
    # ON an edge of the frame. That definition cannot fail: a mark that missed
    # the axis is simply not a tick any more, and falls through to the data,
    # where it passes containment because it is still inside the frame. The
    # break that puts the BOTTOM MARGIN one point out of step with the frame
    # scored zero red against it -- eleven tick marks floating a fortieth of an
    # inch clear of the axis, every one of them counted as a data point.
    #
    # So the marks are identified by something no displacement can change:
    # ADJACENCY TO THEIR OWN NUMBER. Praat writes a numbered mark as the glyph
    # run and then the mark's path, two or three lines apart in the file. Every
    # mark that follows a `show` is a mark, whatever rectangle it ended up on;
    # its length is then the signature of the whole lattice, which is how the
    # unnumbered minor marks between the numbered ones are picked up too --
    # Praat draws every mark on a margin at one length.
    is_short <- function(sg) {
        d1 <- abs(sg$x[2] - sg$x[1]); d2 <- abs(sg$y[2] - sg$y[1])
        if (d2 <= EPS_TOL) d1 <= 0.10 * bw else if (d1 <= EPS_TOL) d2 <= 0.10 * bh
        else FALSE
    }
    cand <- Filter(function(sg) length(sg$x) == 2L && is_short(sg), P$segs)
    seglen <- function(sg) round(max(abs(sg$x[2] - sg$x[1]),
                                     abs(sg$y[2] - sg$y[1])), 3)
    led <- vapply(cand, function(sg) any(P$shows >= sg$at - 4L & P$shows < sg$at),
                  logical(1))
    marklen <- unique(vapply(cand[led], seglen, numeric(1)))
    check_true(V, sprintf("%s: some tick mark follows its own number", case),
               length(marklen) > 0L)
    is_tick <- vapply(cand, function(sg) seglen(sg) %in% marklen, logical(1))

    ticks <- list()
    for (sg in cand[is_tick]) {
        vertical <- abs(sg$x[2] - sg$x[1]) <= EPS_TOL
        if (vertical) {
            mid <- mean(sg$y)
            edge <- if (abs(mid - y0) <= abs(mid - y1)) "bottom" else "top"
            anch <- if (edge == "bottom") max(sg$y) else min(sg$y)
            free <- if (edge == "bottom") min(sg$y) else max(sg$y)
            ref  <- if (edge == "bottom") y0 else y1
            outward <- if (edge == "bottom") free < y0 - EPS_TOL else free > y1 + EPS_TOL
            along <- sg$x[1]
        } else {
            mid <- mean(sg$x)
            edge <- if (abs(mid - x0) <= abs(mid - x1)) "left" else "right"
            anch <- if (edge == "left") max(sg$x) else min(sg$x)
            free <- if (edge == "left") min(sg$x) else max(sg$x)
            ref  <- if (edge == "left") x0 else x1
            outward <- if (edge == "left") free < x0 - EPS_TOL else free > x1 + EPS_TOL
            along <- sg$y[1]
        }
        ticks[[length(ticks) + 1L]] <- list(edge = edge, err = abs(anch - ref),
                                            outward = outward, along = along)
    }

    # THE REST OF THE INK. A gridline is a straight segment touching both
    # opposite edges and spanning the frame; it is furniture and is kept out of
    # the data so that "the data reaches this edge" cannot be satisfied by a
    # line that reaches it by construction. Note what happens to a gridline
    # when the frame is drawn on a different rectangle: it stops touching both
    # edges, stops being furniture, and joins the data -- where containment
    # sees it. That is the right answer, not a loophole.
    tick_at <- vapply(cand[is_tick], function(sg) sg$at, numeric(1))
    data_x <- numeric(0); data_y <- numeric(0); ngrid <- 0L
    for (sg in P$segs) {
        if (sg$at %in% tick_at) next
        if (length(sg$x) == 2L) {
            dx <- sg$x[2] - sg$x[1]; dy <- sg$y[2] - sg$y[1]
            if (abs(dy) <= EPS_TOL && on(min(sg$x), x0) && on(max(sg$x), x1)) {
                ngrid <- ngrid + 1L; next
            }
            if (abs(dx) <= EPS_TOL && on(min(sg$y), y0) && on(max(sg$y), y1)) {
                ngrid <- ngrid + 1L; next
            }
        }
        data_x <- c(data_x, sg$x); data_y <- c(data_y, sg$y)
    }
    for (p in P$polys) {
        if (identical(p, B)) next
        data_x <- c(data_x, p$x); data_y <- c(data_y, p$y)
    }
    for (d in P$discs) { data_x <- c(data_x, d$x); data_y <- c(data_y, d$y) }
    n_tick <- n_tick + length(ticks); n_grid <- n_grid + ngrid
    n_data <- n_data + length(data_x)

    check_true(V, sprintf("%s: the figure carries tick marks to check", case),
               length(ticks) >= 2L)
    check_true(V, sprintf("%s: the figure carries plotted data to check", case),
               length(data_x) >= 2L)

    # (3) EVERY TICK IS ANCHORED ON THE FRAME, points away from it, and stands
    # somewhere along the axis it belongs to. The anchoring is the sharpest
    # single statement in this file: a margin mark and the box are converted
    # from the same viewport, so they agree exactly or the ambient state
    # changed between them.
    aerr <- if (length(ticks)) max(vapply(ticks, function(t) t$err, numeric(1))) else NA
    worst_anchor <- max(worst_anchor, aerr, na.rm = TRUE)
    if (!check_true(V, sprintf("%s: every tick is anchored on the inner box",
                               case),
                    length(ticks) > 0L && aerr <= EPS_TOL)) {
        cat(sprintf("      %s: worst mark stands %.3f device units off its axis\n",
                    case, aerr))
    }
    check_true(V, sprintf("%s: every tick points out of the box, not into it",
                          case),
               all(vapply(ticks, function(t) t$outward, logical(1))))
    within <- vapply(ticks, function(t) {
        if (t$edge %in% c("left", "right"))
            t$along >= y0 - EPS_TOL && t$along <= y1 + EPS_TOL
        else t$along >= x0 - EPS_TOL && t$along <= x1 + EPS_TOL
    }, logical(1))
    check_true(V, sprintf("%s: every tick stands within the box's own span",
                          case),
               all(within))

    # (4) THE LATTICE BRACKETS THE FRAME. The far edges of the frame carry no
    # ticks of their own on these figures, so this is what pins them: the
    # first and last mark on a margin must be no further from the ends than
    # one step of the same lattice. The step is the LARGEST gap between
    # consecutive marks rather than the mean, because a categorical axis puts
    # three marks on a frame with half a slot spare at each end and a mean
    # would call that spare half slot a violation.
    for (e in c("left", "right", "bottom", "top")) {
        pos <- vapply(Filter(function(t) t$edge == e, ticks),
                      function(t) t$along, numeric(1))
        if (length(pos) < 2L) next
        pos <- sort(unique(round(pos, 4)))
        if (length(pos) < 2L) next
        step <- max(diff(pos))
        lo <- if (e %in% c("left", "right")) y0 else x0
        hi <- if (e %in% c("left", "right")) y1 else x1
        check_true(V, sprintf(
            "%s: the %s lattice reaches both ends of the box within one step",
            case, e),
            pos[1] - lo <= step + EPS_TOL &&
            hi - pos[length(pos)] <= step + EPS_TOL)
    }

    # (5) CONTAINMENT. Nothing plotted is outside the frame. This is the check
    # the seeded font change trips first and hardest: the frame contracts
    # about 2.9% and the series, converted at the other size, hangs over both
    # sides of it.
    ov <- max(c(0, x0 - data_x, data_x - x1, y0 - data_y, data_y - y1))
    worst_out <- max(worst_out, ov)
    if (!check_true(V, sprintf("%s: every plotted point is inside the inner box",
                               case),
                    ov <= EPS_TOL)) {
        k <- which.max(pmax(x0 - data_x, data_x - x1, y0 - data_y, data_y - y1))
        cat(sprintf("      %s: worst point (%.3f, %.3f) against box x[%.3f, %.3f] y[%.3f, %.3f]\n",
                    case, data_x[k], data_y[k], x0, x1, y0, y1))
    }

    # (6) REACH. The edges this case's fixture earns, and only those. The
    # claim is made in the case script beside the reason for it and printed
    # from there, never restated here -- a validator that retyped the claim
    # could disagree with the figure it is reading and nothing would notice.
    claim <- val(case, "reach")
    check_true(V, sprintf("%s: the case declared what its data reaches", case),
               !is.na(claim) && nzchar(claim))
    if (!is.na(claim) && claim != "none") {
        for (e in strsplit(claim, " +")[[1]]) {
            d <- switch(e,
                        left   = min(abs(data_x - x0)),
                        right  = min(abs(data_x - x1)),
                        bottom = min(abs(data_y - y0)),
                        top    = min(abs(data_y - y1)))
            worst_reach <- max(worst_reach, d)
            check_true(V, sprintf("%s: the data reaches the %s edge", case, e),
                       d <= REACH_TOL)
        }
    }
}

cat(sprintf("  [figures %d | ticks %d | gridlines %d | plotted points %d]\n",
            length(CASES), n_tick, n_grid, n_data))
cat(sprintf("  [worst anchoring error %.4f | worst overshoot %.4f | worst claimed reach %.4f device units, tol %.1f / %.1f]\n",
            worst_anchor, worst_out, worst_reach, EPS_TOL, REACH_TOL))

# EVERY FIGURE THE DRIVER RENDERED IS LOOKED AT. A case added to run.sh and
# not to CASES would be thirteen green checks and one unread figure.
eml_census(V, "boxgeom figures", present, CASES)

if (!exists("EML_SUITE")) eml_report("v100 -- one rectangle per figure")
