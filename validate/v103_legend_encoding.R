# ============================================================================
# v103 — one legend-placement encoding, one registry, and no way for a new
#        graph type to acquire a blank dropdown by omission
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# `config_legendPlacement` is the one persisted legend key — 1 Inside plot /
# 2 Right of plot / 3 Below plot / 4 Separate figure / 5 None — and unlike
# `config_gridlineMode` it has exactly ONE encoding, the same for every graph
# type. So there is no translation defect to point at here, and that is
# precisely why this file exists: the structure that would CATCH one is in
# the tree, is load-bearing, and until now nothing asserted a line of it.
#
# What the structure is for, in the words of the defect that produced it
# (see v31's header for the shipped consequence): a persisted menu index that
# is not an option of the menu it seeds makes Praat draw that optionmenu
# BLANK and then refuse the form — "No option chosen for “Legend placement
# (when drawn)”." — leaving the page with no Draw path out of it, and the bad
# value is on disk, so quitting Praat does not clear it. The gridline key
# reached that state two ways: a per-type encoding nobody registered, and a
# config file carrying a value that was never an option. Legend placement is
# built so neither is reachable —
#
#   · legendPlacementStyle[] registers every one of the 13 types, as 5 (the
#     type draws a legend and offers the full menu) or 0 (it has none);
#   · two file-scope loops refuse to LOAD the file if a type is missing from
#     that registry or carries a value that is neither, so the failure lands
#     on the developer who added the type rather than on a user six months
#     later;
#   · @emlLegendPlacementStyle refuses an unregistered type BY NAME at
#     runtime as well, for a developer who somehow gets past include time;
#   · one @emlSeedLegendPlacement token seeds `tmpLegendPlacement` and one
#     @emlCommitLegendPlacement token writes the config, so a seventh call
#     site cannot be written differently — the hand-copied clamp that C1
#     found in three of thirteen gridline dialogs is the failure mode;
#   · @emlLoadConfig clamps the key into 1..5 AT THE POINT IT PARSES IT, so a
#     hand-edited, truncated or pre-C1 config cannot seed a blank menu.
#
# Every one of those is an invariant of the SOURCE, and every one of them is
# the kind that decays silently: adding a fourteenth graph type, or a second
# shorter menu, or one more dialog, breaks them without breaking any figure
# this suite renders. v32 measures the legend's GEOMETRY — the rectangles, on
# 205 driven figures — and says in its own header that the dialog side is out
# of its scope: "config_legendPlacement's encoding, its clamp on load and its
# optionmenu belong with v31's registry checks, in eml-graphs-form.praat,
# which this script does not read." This file is that half.
#
# Source-level only. It reads one file and drives nothing, so it needs no
# harness and no Praat — run it in under a second, any time:
#
#     Rscript validate/v103_legend_encoding.R
#
# $EML_FORM_PATH overrides the file read, defaulting to
# plugin/graphs/eml-graphs-form.praat. It exists so this validator can be
# shown RED: point it at a copy of the form with a deliberate break in it and
# the relevant checks fail, which is the only way to know the checks are
# checks. Nothing in the suite sets it.
#
# Base R only. No packages.
#
# It is NOT in run_all.R yet.
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

form_p <- Sys.getenv("EML_FORM_PATH",
                     unset = repo_path("plugin", "graphs", "eml-graphs-form.praat"))
if (!file.exists(form_p)) stop("v103: form not found: ", form_p)
form <- readLines(form_p, warn = FALSE)

# Comment lines are excluded from `code` wherever a check is about what the
# file DOES, because the registry and procedure headers quote every pattern
# named below by name — a check run against `form` would match the prose that
# explains why the pattern must not appear.
code <- form[!grepl("^\\s*[#;]", form)]

# ===========================================================================
# 1. The registry covers every graph type, exactly once, with a legal value
# ===========================================================================

n_types <- as.integer(sub(".*=\\s*", "",
                          grep("^nGraphTypes\\s*=", form, value = TRUE)[1]))
check_true("v103", "nGraphTypes is 13", identical(n_types, 13L))

style_lines <- grep("^legendPlacementStyle\\[[0-9]+\\]\\s*=", form, value = TRUE)
style_idx <- as.integer(sub("^legendPlacementStyle\\[([0-9]+)\\].*", "\\1",
                            style_lines))
style_val <- as.integer(sub(".*=\\s*", "", style_lines))

check_true("v103", "legendPlacementStyle[] declared for every type, once each",
           identical(sort(style_idx), 1:n_types) &&
               length(style_idx) == n_types)

# 5 or 0 and nothing else. A 2 or a 4 here would be a second encoding
# arriving without the translation to go with it, which is C1 exactly.
check_true("v103", "every legendPlacementStyle[] is 5 (full menu) or 0 (none)",
           all(style_val %in% c(0L, 5L)))

declared <- setNames(style_val, style_idx)
legend_types <- sort(style_idx[style_val == 5L])

# The six that draw a legend, named. Not a restatement of the line above: it
# pins WHICH types, so that quietly dropping the menu from Histogram — or
# adding one to Bar Chart, whose group names are already on the x-axis, where
# a key would be a second copy of the same information — is a failure and not
# a silent change of product behaviour.
check_true("v103", "the legend types are line chart, scatter, histogram, grouped violin, grouped box, spaghetti",
           identical(legend_types, c(5L, 8L, 10L, 11L, 12L, 13L)))

# ===========================================================================
# 2. The registry agrees with the dialogs it describes
# ===========================================================================
# This is what makes legendPlacementStyle[] more than a second place to be
# wrong. Attribute each Legend placement optionmenu to the graph type whose
# dispatch branch it is in, count the `option:` lines under it, and require
# the registry to match. A type declared 5 with no menu, or a menu on a type
# declared 0, fails here.

dispatch <- grep("^\\s*(if|elsif) graph_type = [0-9]+\\s*$", form)
dispatch_type <- as.integer(sub(".*graph_type = ([0-9]+).*", "\\1",
                                form[dispatch]))

menus <- grep('^\\s*optionmenu: "Legend placement \\(when drawn\\)"', form)
check_true("v103", "one Legend placement menu per legend-drawing type (6)",
           length(menus) == length(legend_types))

owner_of <- function(line) {
    before <- dispatch[dispatch < line]
    if (!length(before)) return(NA_integer_)
    dispatch_type[length(before)]
}

menu_type <- vapply(menus, owner_of, integer(1))
menu_opts <- integer(0)
menu_list <- character(0)
for (m in menus) {
    k <- m + 1L
    o <- character(0)
    while (k <= length(form) && grepl('^\\s*option: "', form[k])) {
        o <- c(o, trimws(form[k]))
        k <- k + 1L
    }
    menu_opts <- c(menu_opts, length(o))
    menu_list <- c(menu_list, paste(o, collapse = "|"))
}

check_true("v103", "each legend type owns exactly one Legend placement menu",
           identical(sort(menu_type), legend_types))
check_true("v103", "legendPlacementStyle[t] equals type t's real option count",
           all(menu_opts == declared[as.character(menu_type)]))

# ONE ENCODING MEANS ONE OPTION LIST, CHARACTER FOR CHARACTER. Six hand-
# written copies of the same five lines is exactly the shape that drifts:
# reorder two of them in one dialog and the persisted number keeps its value
# and changes its meaning, which is defect 2 of C1 with no menu ever going
# blank to announce it. The order is also the encoding — option n IS
# canonical n — so this line pins the meaning of the numbers on disk.
canonical <- paste(sprintf('option: "%s"',
                           c("Inside plot", "Right of plot", "Below plot",
                             "Separate figure", "None")),
                   collapse = "|")
check_true("v103", "all six dialogs offer one identical option list",
           length(unique(menu_list)) == 1L)
check_true("v103", "and it is the canonical order: Inside / Right / Below / Separate / None",
           all(menu_list == canonical))

# ===========================================================================
# 3. One seed token, one commit token, in the dialogs that have the menu
# ===========================================================================
# Exact counts, because a page that loses its seed is what this catches: the
# menu would then be drawn from whatever `tmpLegendPlacement` a previously
# configured type left behind.

# The page-2 dispatch chain — the one that carries the per-type dialogs. It
# is identified as the chain the first Legend placement menu belongs to, not
# by a line number, so an edit above it does not move this file's meaning.
page2_start <- max(dispatch[dispatch < menus[1] &
                                dispatch_type == 1L])

seeds <- grep("^\\s*@emlSeedLegendPlacement\\s*$", form)
commits <- grep("^\\s*@emlCommitLegendPlacement:", form)

# The shared seed. It runs before the dispatch, so EVERY type — including the
# seven with no legend at all — enters its dialog with `tmpLegendPlacement`
# holding a real option index rather than whatever the last type left there.
shared <- seeds[seeds < page2_start]
check_true("v103", "exactly one shared @emlSeedLegendPlacement before the dispatch",
           length(shared) == 1L)
check_true("v103", "the shared seed sits immediately above 'if graph_type = 1'",
           length(shared) == 1L && (page2_start - shared) <= 20L)

per_type_seeds <- seeds[seeds > page2_start]
check_true("v103", "one @emlSeedLegendPlacement per legend dialog (6)",
           length(per_type_seeds) == length(legend_types))
check_true("v103", "and each belongs to a type that offers the menu",
           identical(sort(vapply(per_type_seeds, owner_of, integer(1))),
                     legend_types))

check_true("v103", "one @emlCommitLegendPlacement per legend dialog (6)",
           length(commits) == length(legend_types))
check_true("v103", "and each belongs to a type that offers the menu",
           identical(sort(vapply(commits, owner_of, integer(1))), legend_types))

# Every commit is handed the form's own field. A commit passing a `tmp` or a
# literal would persist something the user did not choose.
check_true("v103", "every commit passes the form field `legend_placement`",
           all(grepl("^\\s*@emlCommitLegendPlacement: legend_placement\\s*$",
                     form[commits])))

check_true("v103", "the four legend procedures are each defined exactly once",
           sum(grepl("^procedure emlSeedLegendPlacement\\s*$", form)) == 1L &&
               sum(grepl("^procedure emlCommitLegendPlacement:", form)) == 1L &&
               sum(grepl("^procedure emlLegendPlacementToMenu:", form)) == 1L &&
               sum(grepl("^procedure emlLegendPlacementFromMenu:", form)) == 1L)

# ===========================================================================
# 4. Nothing seeds or commits the key by hand
# ===========================================================================
# These two patterns ARE the C1 defect, transposed. A raw seed is what put a
# four-option index into a two-option gridline menu; a raw commit is what
# wrote a menu index into a key that is supposed to be canonical. Neither can
# be written here without going through the procedures — assert that, because
# both are one obvious line for someone adding a fourteenth dialog.
check_true("v103", "no raw 'tmpLegendPlacement = config_legendPlacement' survives",
           !any(grepl("tmpLegendPlacement\\s*=\\s*config_legendPlacement", code)))
check_true("v103", "no raw 'config_legendPlacement = legend_placement' survives",
           !any(grepl("config_legendPlacement\\s*=\\s*legend_placement", code)))

# The key is WRITTEN in exactly three places and they are named: the default
# in @emlLoadConfig, the parse in @emlLoadConfig, and @emlCommitLegendPlacement.
# A fourth writer is a second author of the persisted value.
writes <- grep("^\\s*config_legendPlacement\\s*=", code)
check_true("v103", "config_legendPlacement is assigned in exactly three places",
           length(writes) == 3L)
check_true("v103", "one of them is the default, and it is 1 (Inside plot)",
           sum(grepl("^\\s*config_legendPlacement\\s*=\\s*1\\s*$",
                     code[writes])) == 1L)
check_true("v103", "one is the clamped parse, one is the commit procedure",
           sum(grepl("config_legendPlacement = emlConfigMenu\\.v",
                     code[writes])) == 1L &&
               sum(grepl("config_legendPlacement = emlLegendPlacementFromMenu\\.canonical",
                         code[writes])) == 1L)

# The draw layer reads the canonical key ONCE, at a boundary the source calls
# out as the only write to `emlLegendPlacement`. More than one read is more
# than one place that could stop agreeing with what the user chose.
check_true("v103", "the draw layer takes the key at exactly one boundary",
           sum(grepl("^\\s*emlLegendPlacement\\s*=\\s*config_legendPlacement",
                     code)) == 1L)

# ===========================================================================
# 5. The refusals — include time and run time
# ===========================================================================

check_true("v103", "a file-scope loop refuses a type with no legendPlacementStyle[]",
           any(grepl('variableExists \\("legendPlacementStyle\\[', form)) &&
               any(grepl("^for iLegChk from 1 to nGraphTypes", form)))
check_true("v103", "and a second refuses a legendPlacementStyle[] that is not 5 or 0",
           sum(grepl("^for iLegChk from 1 to nGraphTypes", form)) == 2L)

# The runtime half, scoped to the procedure body — the form has a second
# `exitScript: "Graph type ", .type` in @emlGridModeStyle, and a check that
# matched either of them would pass with this one deleted.
lp_start <- grep("^procedure emlLegendPlacementStyle:", form)
check_true("v103", "@emlLegendPlacementStyle is defined once",
           length(lp_start) == 1L)
if (length(lp_start) == 1L) {
    lp_end <- grep("^endproc", form)
    lp_end <- lp_end[lp_end > lp_start][1]
    lp_body <- form[lp_start:lp_end]
    check_true("v103", "@emlLegendPlacementStyle refuses an unregistered type by name",
               any(grepl('exitScript: "Graph type ", \\.type', lp_body)))
    # It refuses rather than defaulting. `.style = -1` before the lookup is
    # what makes a missing entry fall into the refusal instead of into 0,
    # which reads as "this type has no legend" and would hide the omission.
    check_true("v103", "an unfound entry falls to -1, so it cannot pass as 0 (no legend)",
               any(grepl("^\\s*\\.style = -1\\s*$", lp_body)))
}

# ===========================================================================
# 6. The clamp, at the point the file is parsed
# ===========================================================================
# A config file can carry anything: hand-edited, truncated mid-write, or
# written by a build that predates this key. THE CLAMP HAS TO BE AT THE
# PARSE. The two gridline clamps that used to sit after the read loop tested
# a value that could already be `undefined` — and no comparison against
# undefined is true, so an empty or truncated line walked straight through
# the guard written to stop it. @emlConfigMenu parses, refuses anything that
# is not a number, and clamps, in one step, bound to the key it feeds.

load_start <- grep("^procedure emlLoadConfig", form)[1]
load_end <- grep("^endproc", form)
load_end <- load_end[load_end > load_start][1]
loader <- form[load_start:load_end]

legClamp <- grep("@emlConfigMenu: \\.value\\$, 1, 5", loader)
legFed <- grep("config_legendPlacement = emlConfigMenu\\.v", loader)
check_true("v103", "@emlLoadConfig clamps legendPlacement into 1..5 as it parses it",
           length(legFed) == 1L && any(legClamp == legFed - 1L))

# The clamp's upper bound is the number of options the dialogs actually
# offer. Add a sixth placement to the menus without widening the clamp and a
# user's choice is silently reset to Inside plot on the next launch; widen
# the clamp without adding the option and the menu goes blank, which is the
# original defect. Neither can happen without this line disagreeing.
check_true("v103", "the clamp's upper bound is the real option count (5)",
           all(menu_opts == 5L) && length(legFed) == 1L)

# The key the loader parses and the key @emlSaveConfig writes are the same
# string. They are separate literals in separate procedures, and a mismatch
# is silent: the setting would simply be back at Inside plot every launch,
# with a perfectly well-formed line in the file that nothing reads.
check_true("v103", "@emlSaveConfig writes the key the loader parses ('legendPlacement')",
           sum(grepl('appendFileLine: \\.configPath\\$, "legendPlacement: ", config_legendPlacement',
                     code)) == 1L &&
               any(grepl('\\.key\\$ = "legendPlacement"', loader)))

# THE BODY OF ONE NAMED PROCEDURE, from its `procedure` line to its `endproc`.
# Used by the wiring checks below, which have to look INSIDE a procedure
# rather than anywhere in the file: `tmpLegendPlacement = ...` appears in more
# than one place, and only the one inside the seed is the join that matters.
proc_body <- function(name) {
    i <- grep(sprintf("^procedure %s[: ]|^procedure %s$", name, name), form)
    if (!length(i)) return(character(0))
    j <- grep("^endproc", form)
    j <- j[j > i[1]]
    if (!length(j)) return(character(0))
    form[i[1]:j[1]]
}

# ---------------------------------------------------------------------------
# THE WIRING, NOT JUST THE PARTS
# ---------------------------------------------------------------------------
# EVERY CHECK ABOVE PASSES ON A BUILD WHERE THE SETTING IS IGNORED. Measured,
# not supposed: replacing the one line
#
#     tmpLegendPlacement = emlLegendPlacementToMenu.menu
#
# with `tmpLegendPlacement = 1` leaves all of them green, and every legend
# dialog in the plugin then opens on "Inside plot" whatever the user saved.
# The registry can be perfect, the option lists identical, the seed and commit
# called in the right places, and the value still never travel -- because what
# those checks assert is that the PARTS exist, and a stored setting is only
# honoured if the parts are JOINED.
#
# So the two joins are pinned here as source, by shape rather than by line:
# the seed takes its value out of the translation procedure's own output, and
# the commit puts the dialog's answer back through the reverse one. A literal
# on either side of either assignment is the defect, and it is exactly what a
# well-meant "just default it" edit looks like.
seedBody <- proc_body("emlSeedLegendPlacement")
commitBody <- proc_body("emlCommitLegendPlacement")

check_true("v103", "the seed exists as one procedure", length(seedBody) > 0)
check_true("v103",
           "the seed calls the translation with the STORED value and the type",
           any(grepl("@emlLegendPlacementToMenu:\\s*graph_type,\\s*config_legendPlacement",
                     seedBody)))
check_true("v103",
           "and takes what the dialog opens on FROM that call, not from a literal",
           any(grepl("^\\s*tmpLegendPlacement\\s*=\\s*emlLegendPlacementToMenu\\.menu\\s*$",
                     seedBody)) &&
               !any(grepl("^\\s*tmpLegendPlacement\\s*=\\s*[0-9]", seedBody)))

check_true("v103", "the commit exists as one procedure", length(commitBody) > 0)
check_true("v103",
           "the commit puts the dialog's answer back through the reverse translation",
           any(grepl("@emlLegendPlacementFromMenu:\\s*graph_type,\\s*\\.chosen",
                     commitBody)))
check_true("v103",
           "and stores what that call returned, not a literal",
           any(grepl("^\\s*config_legendPlacement\\s*=\\s*emlLegendPlacementFromMenu\\.canonical\\s*$",
                     commitBody)) &&
               !any(grepl("^\\s*config_legendPlacement\\s*=\\s*[0-9]", commitBody)))

# AND THE TWO TRANSLATIONS ARE INVERSES OVER THE WHOLE RANGE. Today both are
# the identity plus a clamp, which is what makes the stored number readable as
# itself -- but "today it is the identity" is the kind of fact that stops being
# true quietly. Each is asserted to carry the clamp at the real option count
# and to pass its input through, so a translation that started mapping 3 to 2
# would be visible here rather than in a figure.
toBody <- proc_body("emlLegendPlacementToMenu")
fromBody <- proc_body("emlLegendPlacementFromMenu")
check_true("v103", "the forward translation passes the canonical value through",
           any(grepl("^\\s*\\.menu\\s*=\\s*\\.canonical\\s*$", toBody)))
check_true("v103", "the reverse translation passes the menu index through",
           any(grepl("^\\s*\\.canonical\\s*=\\s*\\.menu\\s*$", fromBody)))
for (nm in list(c("forward", "toBody", ".menu"), c("reverse", "fromBody", ".canonical"))) {
    b <- get(nm[2]); v <- nm[3]
    check_true("v103",
               sprintf("the %s translation clamps into 1..5, the real option count",
                       nm[1]),
               any(grepl(sprintf("if %s < 1", gsub("\\.", "\\\\.", v)), b)) &&
                   any(grepl(sprintf("if %s > 5", gsub("\\.", "\\\\.", v)), b)))
}

if (!exists("EML_SUITE")) { eml_report("v103 legend placement: one encoding, one registry, one clamp"); eml_exit() }
