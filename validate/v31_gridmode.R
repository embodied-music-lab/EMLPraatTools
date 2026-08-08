# ============================================================================
# v31 — C1: one gridline encoding, translated at the dialog, and no way for a
#       new graph type to reintroduce the old one by omission
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# `.gridMode` has two encodings in this plugin — 1 Both / 2 Horizontal only /
# 3 Vertical only / 4 Off for the six graph types with a continuous x-axis,
# and 1 Horizontal / 2 Off for the seven categorical ones — and ONE persisted
# key, `config_gridlineMode`, written from both. Two shipped consequences:
#
#   1. A four-option type could seed a two-option optionmenu with 3 or 4.
#      Praat draws an optionmenu whose default exceeds its option count BLANK
#      and then refuses the form ("No option chosen for “Gridline mode”."), so
#      the page had no Draw path out of it. The value is on disk, so a restart
#      did not clear it. Bar, violin and box carried a hand-copied clamp;
#      histogram, grouped violin, grouped box and spaghetti did not.
#   2. Where the clamp existed it preserved the INDEX, not the MEANING —
#      "Horizontal only" (4-option 2) arrived as "Off" (2-option 2), "Off"
#      (4-option 4) arrived as "Horizontal" (2-option 1).
#
# Both halves were driven on the parallel GUI rig against the pre-fix tree and
# the working tree, four runs; see evidence/walks/gridmode/README.md and
# manifest.csv. The screenshots are the primary evidence and are not machine
# readable. What IS machine readable, and is what this file asserts:
#
#   · the exhaustive translation table (evidence/walks/gridmode/truth_table.csv,
#     produced by harness/walks/gridmode/truth.praat) — all 13 types x all 4
#     canonical values, never out of range, always round-tripping by meaning;
#   · the config files and driver logs the four GUI runs left behind;
#   · the source invariants that make the fix structural rather than a fourth,
#     fifth, sixth and seventh copy of the clamp.
#
# The source half is the important half. This project has now had five fixes
# propagate by hand and stop short; the assertions at the bottom fail if
# someone adds a graph type without a gridline encoding, declares one that
# disagrees with the dialog it belongs to, or writes a raw
# `tmpGridMode = config_gridlineMode` anywhere again.
#
# Base R only. No packages.
#
# NOT wired into run_all.R — the four captures are GUI-driven.

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

gm_path <- function(name) repo_path("evidence", "walks", "gridmode", name)

gm_read <- function(name) {
    p <- gm_path(name)
    if (!file.exists(p)) stop("gridmode capture not found: ", p)
    readLines(p, warn = FALSE)
}

# gm_cfg — the value of one key in a captured eml-graphs-config.txt
gm_cfg <- function(name, key) {
    ln <- grep(paste0("^", key, ":"), gm_read(name), value = TRUE)
    if (length(ln) != 1L) stop("expected one '", key, "' line in ", name)
    as.integer(trimws(sub("^[^:]+:", "", ln)))
}

# ===========================================================================
# 1. The translation, exhaustively
# ===========================================================================
# 13 types x 4 canonical values. Read as a table rather than recomputed here
# on purpose: the numbers come out of the plugin's own procedures, so this
# section is checking the plugin and not a second implementation of it.

tt <- read.csv(gm_path("truth_table.csv"), stringsAsFactors = FALSE)

check_true("v31", "truth table covers every type x canonical value (52)",
           nrow(tt) == 52L && length(unique(tt$type)) == 13L &&
               all(sort(unique(tt$canonical)) == 1:4))

# Every menu index the plugin will seed is a real option of that menu. This is
# defect 1 in one line: the pre-fix code produced menu = 3 and menu = 4 on
# rows where style is 2, and a Praat optionmenu seeded past its option count
# renders blank and refuses.
check_true("v31", "seeded index is always within the menu's option count",
           all(tt$menu >= 1L & tt$menu <= tt$style))

check_true("v31", "committed value is always a legal canonical value",
           all(tt$back >= 1L & tt$back <= 4L))

# Four-option types are the canonical encoding, so they must be untouched.
four <- tt[tt$style == 4L, ]
check_true("v31", "four-option types translate to themselves (identity)",
           all(four$menu == four$canonical) && all(four$back == four$canonical))

# Defect 2. On a two-option type only two canonical values are expressible;
# both must survive the round trip. `2` (Horizontal only) and `4` (Off) are
# exactly the two the old index-preserving clamp swapped.
two <- tt[tt$style == 2L, ]
check_true("v31", "two-option: Horizontal only (2) round-trips to itself",
           all(two$back[two$canonical == 2L] == 2L))
check_true("v31", "two-option: Off (4) round-trips to itself",
           all(two$back[two$canonical == 4L] == 4L))

# ... and the two that are not expressible collapse by MEANING, not by index:
# gridlines-on values become Horizontal, gridlines-off values become Off.
check_true("v31", "two-option: Both (1) shows Horizontal, not Off",
           all(two$menu[two$canonical == 1L] == 1L))
check_true("v31", "two-option: Vertical only (3) shows Off, not Horizontal",
           all(two$menu[two$canonical == 3L] == 2L))

# The specific inversion C1 names, stated as the user would: turning gridlines
# off on a scatter plot must not turn them on for the next bar chart.
scatter_off <- tt$menu[tt$type == 8L & tt$canonical == 4L]
bar_from_off <- tt$menu[tt$type == 6L & tt$canonical == 4L]
check_true("v31", "scatter Off -> bar chart Off (was: bar chart Horizontal)",
           length(bar_from_off) == 1L && bar_from_off == 2L)
check_true("v31", "scatter's own Off is unchanged at 4",
           length(scatter_off) == 1L && scatter_off == 4L)

# ===========================================================================
# 2. What the four GUI runs left on disk
# ===========================================================================
# Each run drew a Scatter Plot with a chosen gridline setting, finished the
# workflow so the config was written, RELAUNCHED Praat, and opened a
# Histogram. The relaunch is why the config files matter: the value crosses
# the two dialogs on disk, which is why the pre-fix failure survived a restart.

check_true("v31", "pre-fix scatter wrote Off as gridlineMode: 4",
           gm_cfg("prefix_off_config_after_scatter.txt", "gridlineMode") == 4L)
check_true("v31", "fixed scatter wrote Off as gridlineMode: 4 (unchanged)",
           gm_cfg("fixed_off_config_after_scatter.txt", "gridlineMode") == 4L)
check_true("v31", "pre-fix scatter is on graph type 8",
           gm_cfg("prefix_off_config_after_scatter.txt", "graphType") == 8L)

# The pre-fix histogram never reached a config write, because it never got
# past its own dialog. Its absence is part of the record.
check_true("v31", "pre-fix run produced no post-histogram config (never drew)",
           !file.exists(gm_path("prefix_off_config_after_histogram.txt")))
check_true("v31", "fixed run did produce one (the histogram drew)",
           file.exists(gm_path("fixed_off_config_after_histogram.txt")))
check_true("v31", "fixed histogram committed Off back as Off, not Horizontal",
           gm_cfg("fixed_off_config_after_histogram.txt", "gridlineMode") == 4L)
check_true("v31", "fixed post-histogram config is on graph type 10",
           gm_cfg("fixed_off_config_after_histogram.txt", "graphType") == 10L)

# Horizontal only: 2 is IN range on a two-option menu, so nothing refuses in
# either tree — the difference is what the menu means, which is visible only
# in the screenshots. What the logs can carry is that both runs completed and
# that the key kept the value the scatter set.
for (tag in c("prefix_horiz", "fixed_horiz")) {
    check_true("v31", paste(tag, "scatter wrote Horizontal only as 2"),
               gm_cfg(paste0(tag, "_config_after_scatter.txt"), "gridlineMode") == 2L)
    check_true("v31", paste(tag, "histogram accepted and kept the key at 2"),
               gm_cfg(paste0(tag, "_config_after_histogram.txt"), "gridlineMode") == 2L)
}

po <- gm_read("prefix_off.log")
fo <- gm_read("fixed_off.log")
check_true("v31", "pre-fix: Draw on the histogram was REFUSED",
           any(grepl("^\\[prefix_off\\] REFUSED", po)))
check_true("v31", "pre-fix: the page after Draw is still the histogram dialog",
           any(grepl("after Draw: Pause: Histogram", po)))
check_true("v31", "fixed: Draw on the histogram was accepted",
           any(grepl("^\\[fixed_off\\] accepted", fo)))
check_true("v31", "fixed: the page after Draw is Graph Complete",
           any(grepl("after Draw: Pause: Graph Complete", fo)))
# The differential is the whole argument: a passing fixed run proves only that
# the walk reached the page unless the same walk failed against the old code.
check_true("v31", "the two runs disagree — the walk could catch the defect",
           any(grepl("REFUSED", po)) && !any(grepl("REFUSED", fo)))

check_true("v31", "the refusal screenshot is committed",
           file.exists(gm_path("prefix_off_6_refusal.png")))
check_true("v31", "the blank-dropdown screenshot is committed",
           file.exists(gm_path("prefix_off_3_histogram_dialog.png")))
check_true("v31", "both meaning-preservation screenshots are committed",
           file.exists(gm_path("prefix_horiz_4_histogram_dropped.png")) &&
               file.exists(gm_path("fixed_horiz_4_histogram_dropped.png")))

# ===========================================================================
# 3. The source invariants — what stops a fourteenth graph type doing this
#    again by omission
# ===========================================================================

form <- readLines(repo_path("plugin", "graphs", "eml-graphs-form.praat"),
                  warn = FALSE)

n_types <- as.integer(sub(".*=\\s*", "",
                          grep("^nGraphTypes\\s*=", form, value = TRUE)[1]))
check_true("v31", "nGraphTypes is 13", identical(n_types, 13L))

# (a) every registered type has a gridline encoding, and it is 2 or 4.
style_lines <- grep("^gridModeStyle\\[[0-9]+\\]\\s*=", form, value = TRUE)
style_idx <- as.integer(sub("^gridModeStyle\\[([0-9]+)\\].*", "\\1", style_lines))
style_val <- as.integer(sub(".*=\\s*", "", style_lines))
check_true("v31", "gridModeStyle[] declared for every type, once each",
           identical(sort(style_idx), 1:n_types) &&
               length(style_idx) == n_types)
check_true("v31", "every gridModeStyle[] is 2 or 4",
           all(style_val %in% c(2L, 4L)))

declared <- setNames(style_val, style_idx)

# (b) the declaration agrees with the dialog it describes. This is the check
# that makes the registry more than a second place to be wrong: attribute each
# `optionmenu: "Gridline mode"` to the graph type whose branch it is in, count
# the `option:` lines under it, and compare.
dispatch <- grep("^\\s*(if|elsif) graph_type = [0-9]+\\s*$", form)
dispatch_type <- as.integer(sub(".*graph_type = ([0-9]+).*", "\\1",
                                form[dispatch]))
menus <- grep('^\\s*optionmenu: "Gridline mode"', form)
check_true("v31", "one Gridline mode menu per graph type (13)",
           length(menus) == n_types)

menu_type <- integer(0)
menu_opts <- integer(0)
for (m in menus) {
    before <- dispatch[dispatch < m]
    menu_type <- c(menu_type, dispatch_type[length(before)])
    k <- m + 1L
    n <- 0L
    while (k <= length(form) && grepl('^\\s*option: "', form[k])) {
        n <- n + 1L
        k <- k + 1L
    }
    menu_opts <- c(menu_opts, n)
}
check_true("v31", "each type owns exactly one Gridline mode menu",
           identical(sort(menu_type), 1:n_types))
check_true("v31", "every menu offers either 4 options or 2",
           all(menu_opts %in% c(2L, 4L)))
check_true("v31", "gridModeStyle[t] equals type t's real option count",
           all(menu_opts == declared[as.character(menu_type)]))

# (c) the file refuses to load if (a) is ever violated. Two file-scope loops
# over 1..nGraphTypes, one for a missing entry and one for an illegal value.
check_true("v31", "a file-scope loop refuses a type with no gridModeStyle[]",
           any(grepl('variableExists \\("gridModeStyle\\["', form)) &&
               any(grepl("^for iGridChk from 1 to nGraphTypes", form)))
check_true("v31", "and a second refuses a gridModeStyle[] that is not 2 or 4",
           sum(grepl("^for iGridChk from 1 to nGraphTypes", form)) == 2L)

# (d) nothing seeds or commits the key by hand any more. These two patterns
# ARE the defect: a raw copy either way is what put a four-option index into a
# two-option menu and what wrote a categorical index into a canonical key.
# Comment lines are excluded — the registry block quotes both by name.
code <- form[!grepl("^\\s*[#;]", form)]
check_true("v31", "no raw 'tmpGridMode = config_gridlineMode' survives",
           !any(grepl("tmpGridMode\\s*=\\s*config_gridlineMode", code)))
check_true("v31", "no raw 'config_gridlineMode = gridline_mode' survives",
           !any(grepl("config_gridlineMode\\s*=\\s*gridline_mode", code)))
# The three index-preserving clamps in bar / violin / box, by their signature.
check_true("v31", "the three per-type clamps are gone",
           !any(grepl("if config_gridlineMode = 2", code)))

# (e) one seed per dialog plus the shared seed; one commit per dialog. Exact
# counts, because a page that loses its call is exactly what this catches.
check_true("v31", "one @emlSeedGridMode per dialog plus the shared seed (14)",
           sum(grepl("^\\s*@emlSeedGridMode\\s*$", code)) == n_types + 1L)
check_true("v31", "one @emlCommitGridMode per dialog (13)",
           sum(grepl("^\\s*@emlCommitGridMode:", code)) == n_types)
check_true("v31", "@emlSeedGridMode and @emlCommitGridMode defined once each",
           sum(grepl("^procedure emlSeedGridMode\\s*$", form)) == 1L &&
               sum(grepl("^procedure emlCommitGridMode:", form)) == 1L)

# (f) the translation refuses an unregistered type by name at runtime too, so
# a developer who somehow gets past the load-time loop still cannot reach a
# blank dropdown.
check_true("v31", "@emlGridModeStyle refuses an unregistered type",
           sum(grepl("^procedure emlGridModeStyle:", form)) == 1L &&
               any(grepl("exitScript: \"Graph type \", \\.type", form)))

# (g) the config reader clamps a value that is not an option at all, so a
# hand-edited or truncated file cannot seed a blank menu either.
load_start <- grep("^procedure emlLoadConfig", form)[1]
load_end <- grep("^endproc", form)
load_end <- load_end[load_end > load_start][1]
loader <- form[load_start:load_end]
check_true("v31", "@emlLoadConfig clamps gridlineMode into 1..4",
           any(grepl("if config_gridlineMode < 1", loader)) &&
               any(grepl("if config_gridlineMode > 4", loader)))

if (!exists("EML_SUITE")) { eml_report("v31 gridline mode: one encoding, translated at the dialog (C1)"); eml_exit() }
