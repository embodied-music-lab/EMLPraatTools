# ============================================================================
# v85_source_archive_shape.R -- what a user actually receives when they click
#                               "Source code (zip)" on the releases page
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS FILE ASSERTS, in one sentence: this validator BUILDS the archive
# GitHub would attach to a release and measures the result, so every claim
# below is about a zip that exists on disk during the run rather than about
# the text of .gitattributes.
#
# WHY IT IS NOT A TEXT CHECK. .gitattributes is a set of patterns, and a
# pattern is a statement about files that might exist. `harness/ export-ignore`
# reads as obviously correct and would still be wrong if the directory were
# named `harnesses/`, if a stray copy lived at `plugin/harness/`, or if a
# later line re-included part of it. The only thing that settles what a user
# receives is opening the archive, so that is what happens here: a real
# `git archive`, then utils::unzip(list = TRUE) over the output.
#
# WHAT WAS WRONG. On 17 August 2026 the automatic asset was 84 MB across
# 3,945 entries, of which the plugin was 327. The remaining 3,435 were the
# GUI driving rig (74 MB), its screenshots and figures (24 MB), and the audit
# record (1 MB). Nothing chooses that asset's contents at release time --
# GitHub builds it from the tag unasked -- so the only place to fix it is
# `export-ignore`, and the only way to know it stayed fixed is a check that
# opens the zip.
#
# ---------------------------------------------------------------------------
# WHO THE ASSET IS FOR, WHICH IS THE QUESTION UNDER EVERY RULING BELOW
#
# Author ruling, 17 August 2026. THE AUTOMATIC ASSET IS FOR THE PERSON WHO
# CLICKED THE OBVIOUS LINK ON THE RELEASES PAGE BECAUSE THEY WANTED THE
# PLUGIN, not for a reader of the source. Three measurable facts settle it,
# and each of them is already true elsewhere in this repository:
#
#   * a source reader cannot use this asset AS source -- most validators read
#     evidence/ and several read audit/, both excluded, so the suite that
#     ships here cannot be run from here (see the consequence note below);
#   * RELEASE_EXCLUDE.tsv's own row says the suites in plugin/dev/ "are run
#     from a clone of this repository, against plugin/ in place, and never
#     from an installed copy" -- so shipping them serves no one running them;
#   * the 84 MB measurement above is a record of traffic in the OTHER
#     direction. The people who fetch this asset are trying to install.
#
# Where the two audiences pull against each other the installer wins; where
# they do not, the reader is not charged for it. The two rulings pinned below
# land on opposite sides of that line, and the thing that separates them is
# not size -- it is whether the directory sits BESIDE plugin/ or INSIDE it.
#
# ---------------------------------------------------------------------------
# THE TWO EXCLUSION LISTS: ONE AUTHOR, ONE FOLLOWER
#
# This repository has two files that leave things out, and it was burned this
# week by two hand-maintained lists drifting apart. So the relationship
# between them is computed here on every run rather than trusted.
#
# They are not peers. RELEASE_EXCLUDE.tsv's own header says why its scope is
# what it is: its paths are PLUGIN-RELATIVE, because
# plugin/dev/tools/build-release.py stages plugin/ alone, and the repository's
# sibling directories -- audit/, evidence/, harness/, validate/ -- are outside
# the built artefact by the shape of the tree rather than by any list, which is
# why that header forbids naming them in it ("an exclusion that can never
# match", which the builder rejects).
#
# So inside plugin/ there is exactly one author and one follower, and both
# halves below are derived from RELEASE_EXCLUDE.tsv as it is on disk at run
# time -- no path from that file is restated in this one:
#
#   NO EXTENSION. .gitattributes may name a path under plugin/ ONLY IF
#   RELEASE_EXCLUDE.tsv already names it. Enforced by taking every tracked
#   plugin/ file that NO row of RELEASE_EXCLUDE.tsv covers and requiring it in
#   the archive: if one is missing, an export-ignore line has had an opinion of
#   its own inside the region RELEASE_EXCLUDE.tsv governs, and that is where
#   drift starts. The follower may follow; it may not lead.
#
#   CONGRUENCE. Every path RELEASE_EXCLUDE.tsv names must be ABSENT from the
#   source archive. Inside plugin/ the archive and the release artefact
#   therefore hold THE SAME FILES -- not a superset, the same set -- which is
#   what the audience ruling above requires: plugin/ is the folder a user drags
#   into Praat's preferences directory, so everything under it arrives in the
#   install, and plugin/dev/ is the only developer material in the repository
#   that can ride in that way.
#
# WHAT THIS REPLACED, stated because the reasoning is worth keeping and the
# reversal is not an accident. Until 17 August this file asserted the opposite
# containment -- every RELEASE_EXCLUDE.tsv path had to be PRESENT, the archive
# a strict superset of the artefact -- on the argument that a source archive is
# for a source reader and plugin/dev/ is the first thing such a reader wants.
# That argument is sound about a source archive. It is not sound about THIS
# asset, for the three reasons above, and it left 72 files of test scaffolding
# inside the folder a user installs.
#
# THE COUPLING IT CREATES IS NAMED, NOT HIDDEN. `git archive` cannot read a
# TSV, so a new row in RELEASE_EXCLUDE.tsv now needs a matching export-ignore
# line. That is a real cost. It is paid loudly: the congruence check fails on
# the next run and prints the path that is out of step, rather than the archive
# quietly carrying something the artefact drops.
#
# ---------------------------------------------------------------------------
# WHAT export-ignore CANNOT DO, ASSERTED AND NOT MERELY SAID
#
# It removes paths. That is all. It cannot rename the archive's top-level
# folder, cannot set the plugin's install name, and cannot carry a file mode:
# git records the executable bit and nothing else, so `git archive` writes
# every file 0644 (0755 where git says executable) whatever its mode on disk.
# A mode defect on disk therefore cannot be seen in this asset, and the modes
# a user unzips are uniform because git made them so rather than because
# anything checked them.
#
# WHAT THE ASSET IS. Its plugin folder is named the way Praat installs it and
# carries the 257 files an install needs, so a user who unzips it and drags
# that one folder into their preferences directory has installed the plugin.
# The zip from plugin/dev/tools/build-release.py remains the release: it is
# the artefact the documentation points at, it gates every file it stages
# against RELEASE_EXCLUDE.tsv, and it is built deliberately rather than by
# GitHub unasked. Two ways in, one of them supported.
#
# The rename limit is not left as prose. One archive below is built with
# --prefix, the way GitHub builds it from a tag, and the plugin is required to
# arrive at <prefix>plugin_EML_StatsGraphs/ -- the name the SOURCE FOLDER
# carries, which is where the archive gets it. export-ignore did not put it
# there and could not have; it is a `git mv` in the tree.
#
# THE SOURCE FOLDER AND THE INSTALL FOLDER NOW HAVE THE SAME NAME, and the
# reason is this asset. A user unzips it and drags one folder into Praat's
# preferences directory, so the archive has to offer exactly one candidate
# wearing the right name. `plugin` survives at the repository root as a
# SYMLINK to plugin_EML_StatsGraphs, so the paths written as `plugin/...`
# across the harnesses and validators keep resolving in a checkout -- and it
# is export-ignored, because two entries that both look like the plugin is the
# ambiguity the rename removed.
# v47_plugin_folder_name.R holds the INSTALL name against the rigs; this file
# holds what the archive presents.
#
# BOTH HALVES OF THAT ARRANGEMENT ARE ASSERTED BELOW, AND THE SECOND HALF IS
# THE ONE WITH TEETH. "The symlink does not ship" is easy to satisfy: delete
# the link and it is true. What makes the link safe to rely on is that it
# still WORKS in a checkout, and that is the half nothing measured until now.
#
# The failure it guards against is the reason the rename was done this way
# rather than by editing 2,178 paths. If `plugin` stops resolving -- deleted,
# committed as a 22-byte regular file instead of a link, retargeted at a name
# that no longer exists, or replaced by an empty directory -- then every rig
# that opens `plugin/stats/...` finds nothing there. Praat's `include` of a
# missing file, a shell `for f in plugin/*`, a glob that matches zero paths:
# these do not raise. They produce an empty population, and a rig that
# measured an empty population reports success. The suite would stay green
# while measuring nothing, which is the single outcome the split method was
# chosen to make impossible.
#
# So four checks below read the link rather than the archive, and none of them
# is a presence test. git's view: `plugin` is tracked at mode 120000, and the
# blob's bytes are exactly the real folder's name. The checkout's view:
# normalizePath() of both spellings lands on the SAME real directory -- which
# is red for a dangling link, red for a wrong target, red for a plain
# directory, and red for a physical COPY of the tree, the one repair somebody
# would reach for on a checkout that lost the link and the one that would
# start the two names drifting apart; and a named file read through both
# spellings has identical, non-empty bytes, so the paths reach content and not
# merely a resolvable name.
#
# The recorded caveat, kept because it is the cost of the method: git symlinks
# need developer mode on a Windows checkout. The rigs are Linux and the
# ARCHIVE never contains the link, so no user meets this on any platform; a
# Windows contributor who checks out without developer mode gets `plugin` as a
# regular file, and these four checks are what tells them so, by name, instead
# of leaving them to wonder why every rig passes and measures nothing.
#
# ---------------------------------------------------------------------------
# validate/ STAYS IN AND plugin/dev/ GOES OUT, BOTH BY AUTHOR RULING OF
# 17 AUGUST 2026, AND BOTH PINNED IN THE DIRECTION NOBODY WOULD GUARD
#
# validate/ is the largest thing that stays after the plugin -- 2.7 MB, and
# roughly a quarter of the slimmed archive -- and cutting it would be the easy
# further saving. An archive calling itself "source" carries the tests that
# make the source credible, and for this project the validation suite is the
# product's main claim. So this file fails if validate/ gets SMALLER in the
# archive than it is in the tree, which is what an `export-ignore` on it, or on
# any part of it, would do.
#
# plugin/dev/ is the same KIND of material and it goes, because it is INSIDE
# the folder Praat installs. 1.4 MB / 72 files of Praat test suites, Python and
# R reference generators, release tooling, design documents and the history
# ledger, arriving in the user's preferences directory as part of the plugin
# they just dragged in. Measured 17 August 2026: with it, 450 files; without
# it, 378. The pin is the congruence check above -- delete the export-ignore
# line and the row RELEASE_EXCLUDE.tsv already carries turns this file red,
# naming plugin/dev/.
#
# Neither ruling is pinned by weight. A size ceiling would let plugin/dev/ back
# in the moment something else shrank, and would let validate/ out the moment
# something else grew.
#
# A consequence to state rather than let someone discover: the suite that
# ships in this archive CANNOT BE RUN FROM THIS ARCHIVE. Most validators read
# evidence/ and several read audit/, both excluded. The suite is run from a
# clone -- which is what validate/README.md and README.md already say -- and
# shipping 24 MB of PNGs to make an asset nobody should install self-executing
# is the wrong trade. This file is in that same position and says so by
# example: it needs `git` and a repository, so it reports a FAILED check
# rather than a skip when run outside one, the same rule v78 applies to
# python3.
#
# ---------------------------------------------------------------------------
# HOW THE ARCHIVE UNDER TEST IS BUILT
#
# GitHub archives a TAG, so it reads the .gitattributes THAT IS COMMITTED. A
# working-tree edit changes nothing about what github.com serves. But a
# validator that only ever archived HEAD could not see a .gitattributes until
# it was committed, which is the wrong moment to find out.
#
# So the tree under test is HEAD with every non-ignored working-tree change
# laid over it -- whatever `git status --porcelain` reports, with no selection
# applied here -- assembled in a THROWAWAY INDEX (GIT_INDEX_FILE in tempdir)
# so the repository's own index is never touched and nothing is staged. On a
# clean tree the overlay is a no-op and the archive is HEAD's exactly.
#
# The overlay takes everything rather than a chosen file or two on purpose: a
# validator that hand-picked which uncommitted files to include could arrange
# for the archive to contain the very things it goes on to assert are in it.
# Taking git's own answer removes that discretion. The divergence is itself a
# check: if HEAD carries a .gitattributes that differs from the working tree's,
# the archive measured here is NOT the archive github.com is serving, and that
# is reported red rather than measured quietly.
#
# One side effect, named rather than left to be found: building the overlay
# calls `git hash-object -w`, which writes loose objects into .git/objects for
# any uncommitted file. They are unreferenced and a later `git gc` collects
# them. Nothing is staged, no ref moves, and the repository's own index is
# never opened for writing.
#
# ---------------------------------------------------------------------------
# THE BREAKS, AS MEASURED
#
# harness/archshape/break.sh, 18 August 2026. Each break is a COMPLETE CLONE
# of the repository carrying one deliberate defect, committed in that clone,
# with this file run against it. The clone is what keeps the working tree out
# of it; committing the damage is what keeps the HEAD-vs-working-tree
# divergence check from going red in every case and drowning the one red the
# break is for. Counts out of 48 checks, recorded in
# harness/archshape/out/BREAKS.tsv with a log per break beside it.
#
#   control              0 red   an undamaged clone, or every count below is
#                                noise rather than evidence
#
#   THE ARCHIVE'S SHAPE
#   symlink_ships        5 red   `/plugin export-ignore` deleted. The link
#                                arrives beside the plugin in both archives
#                                and the top level stops being a closed set.
#   folder_misnamed      8 red   the folder renamed to plugin_EML_Graphs. The
#                                archive is internally consistent and wrong.
#   dev_returns          2 red   the dev/ export-ignore line deleted; 75 files
#                                of test scaffolding reach the folder a user
#                                drags into Praat.
#   validate_gone        6 red   `validate/ export-ignore` added.
#   validate_thinned     2 red   `validate/v0*.R export-ignore` -- validate/ is
#                                still there, still has its runner, its
#                                registry and this file in it, and 113 of 122
#                                files ship. THE SHARP ONE: every presence
#                                test in this file passes that tree. Only the
#                                two counts fall, which is the argument for
#                                comparing against what git tracks rather than
#                                asserting a floor.
#
#   THE SYMLINK IN THE CHECKOUT -- and in all four, EVERY ARCHIVE CHECK ABOVE
#   STAYED GREEN, which is the whole reason these four exist
#   link_deleted         4 red   the link removed from the index and the disk
#   link_dangling        3 red   retargeted at plugin_EML_Stats_Graphs
#   link_regular_file    4 red   committed at 100644 holding the folder name
#                                -- the Windows-without-developer-mode shape
#   link_is_a_copy       3 red   the link replaced by a physical copy of the
#                                332-file tree. The bytes check PASSES here,
#                                correctly: a copy has the same bytes. The
#                                only thing that separates a copy from a link
#                                is that the two names resolve to two
#                                different real directories, which is why the
#                                third check compares normalizePath() and not
#                                content.
#
#   Re-run:  bash harness/archshape/break.sh [name-substring]
#
#     Rscript validate/v85_source_archive_shape.R
#
# Input: git and this repository. No harness artefact, no Praat, no R package.
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

ROOT <- normalizePath(repo_path("."))
GIT  <- Sys.which("git")

# ---------------------------------------------------------------------------
# THE THINGS THIS FILE JUDGES. Each top-level name in the repository was
# judged one at a time; the verdict and its reason are here, next to the name,
# because a reader asking "why does LICENSE ship and RETRIES.tsv not" should
# not have to reconstruct it from a diff.
#
# MUST_SHIP -- a user unzipping the asset must find each of these.
# MUST_NOT_SHIP -- and must not find any of these.
# ALSO_PERMITTED -- judged, allowed, but not required to exist yet. Anything
#   at top level that is in none of the three lists is an UNJUDGED entry and
#   fails the closed-set check, which is the point: the next heavyweight tree
#   somebody adds cannot ride into the asset unnoticed.
# ---------------------------------------------------------------------------
MUST_SHIP <- c(
    # The plugin, under the name Praat installs it by. The reason the asset
    # exists, and the folder a user drags out of it. 332 tracked files, of
    # which 257 ship: dev/ is the 75 the congruence check below keeps out, by
    # the row RELEASE_EXCLUDE.tsv already carries.
    "plugin_EML_StatsGraphs/",
    # The validation suite. Author ruling, above.  2.71 MB / 113 files.
    "validate/",
    # CI configuration, including the workflow that runs the suite. Tiny, and
    # a source archive that cannot show how the source is tested is coy about
    # the one thing this project asks to be judged on.
    ".github/",
    # GPL-3.0-or-later. The licence must accompany a distribution of the work;
    # this is the one entry with no discretion attached to it. 35 KB.
    "LICENSE",
    # The front door. Ships despite the dangling-reference debt measured at
    # the foot of this file, because an archive with no README is worse.
    "README.md",
    # Ships, and must. This file reads it, and this file ships. Its own header
    # says it stays outside plugin/ so it cannot arrive inside the artefact it
    # describes -- no contradiction arises here, because the source archive is
    # not that artefact.
    "RELEASE_EXCLUDE.tsv",
    # Ships. It is small, it is genuine source (it records which harness
    # outputs are scratch and which are evidence), and a checkout made from
    # the archive without it would start dirty.
    ".gitignore",
    # Ships, and carries the "what this cannot do" statement that a reader who
    # goes looking for the archive's shape will meet. Excluding the file that
    # explains the exclusions is the one self-defeating option available.
    ".gitattributes",
    # Ships, on a narrower argument than the rest. It is a session handoff for
    # the audit drive, not source, and its "Next targets" list is dated 5
    # August and already stale. Two things keep it: README.md names it in
    # prose ("the entry point for whoever picks the drive up next"), so
    # dropping it would strand a link in a document that ships; and it is the
    # second of the two places the P1 file-mode obligation is written down.
    # 5.6 KB, so weight is not part of this verdict either way.
    "START_HERE.md"
)

MUST_NOT_SHIP <- c(
    # 1.1 MB / 46 files. A record of work done ON the source, not source.
    # Readable on github.com by anyone who wants it.
    "audit/",
    # 23.6 MB / 625 files. Screenshots and exported figures -- the drive's raw
    # output. See the consequence noted in this file's header.
    "evidence/",
    # 74.4 MB / 2,644 files. 88% of the old asset. Inert without Xvfb,
    # matchbox, xdotool, ImageMagick and Praat standing in a Linux sandbox.
    "harness/",
    # A one-row incident log from an agent session, about a harness that
    # killed its own driving shell. Session bookkeeping for a rig that is
    # itself excluded above.
    "RETRIES.tsv",
    # 124 KB / 12 files: one workstream's report, its proposals, its runner and
    # the committed red/green transcripts behind them. The same class as
    # audit/ -- a record of work done ON the source rather than source -- and
    # judged the same way. What the lane PRODUCED is already in the asset:
    # v90-v93 sit in validate/ and read their inputs from evidence/, not from
    # here, so nothing that ships loses a file it reads. Readable on
    # github.com like the rest.
    "lane/"
)

ALSO_PERMITTED <- c(
    # Authored separately, 17 August 2026. GitHub reads it to render "Cite
    # this repository", and a citation file belongs with the source it cites.
    # Listed as permitted-not-required so this check does not go red in the
    # window before it lands, and does not go green-by-silence after.
    "CITATION.cff",
    # Judged 20 August 2026, all three PERMITTED TO SHIP rather than excluded,
    # and the reason is worth stating because the instinct runs the other way.
    #
    # They are maintainer documents: the working rules this repository is
    # developed under, the phase register for what comes after 1.0.0, and the
    # standing open-defect list with the design rulings behind it. None of it
    # is about USING the plugin, and the documentation a user needs ships
    # inside the plugin folder.
    #
    # But the four trees excluded above are excluded for WEIGHT -- 74 MB of
    # harness, 24 MB of figures, inert without a Linux sandbox to run them in.
    # These three are some sixty kilobytes of text that cost a downloader
    # nothing and answer the two questions a reader of the source actually
    # has: what is known to be broken, and where is this going. Excluding
    # them would also break the reference ratchet below, which cannot tell
    # `docs/` at the root from `plugin/docs/` inside the shipped folder.
    #
    # Permitted-not-required, like CITATION.cff, so this check does not go red
    # in a window where one of them has been renamed and does not go green by
    # silence if one disappears.
    "CLAUDE.md",
    "ROADMAP.md",
    "docs/"
)

# THE PLUGIN FOLDER'S NAME, WRITTEN ONCE. Everything below that has to form a
# path inside the plugin takes it from here, so this file names the folder in
# one place rather than in eight. It is the install name as well -- the source
# folder and the folder Praat installs are the same folder now, which is what
# lets a user drag the archive's plugin directly into a preferences directory.
PLUGIN_DIR <- "plugin_EML_StatsGraphs/"

# THE COMPATIBILITY SYMLINK. `plugin` at the repository root is a git symlink
# (mode 120000) to plugin_EML_StatsGraphs, kept so that the paths written as
# `plugin/...` throughout the harnesses, validators and documents keep
# resolving in a checkout. It is export-ignored and must not reach the asset.
SYMLINK <- "plugin"

# ---------------------------------------------------------------------------
# git plumbing. Everything runs with -C ROOT; the overlay index is a temp file
# and GIT_INDEX_FILE is passed per-call, never exported into this process.
# ---------------------------------------------------------------------------
git_ok <- nzchar(GIT)
check_true("v85", "git is available (this check cannot be skipped quietly)", git_ok)

gitq <- function(..., idx = NULL, stdout = TRUE) {
    e <- if (is.null(idx)) character(0) else paste0("GIT_INDEX_FILE=", idx)
    suppressWarnings(system2(GIT, c("-C", shQuote(ROOT), ...),
                             stdout = stdout, stderr = FALSE, env = e))
}

# --- THE SYMLINK WORKS IN THE CHECKOUT -------------------------------------
# The half of the ruling that the rest of this file's greenness depends on.
# See the header: a link that has stopped resolving does not raise anywhere,
# it empties the population every other rig measures, and an empty population
# is reported as a pass. Four checks, none of them a presence test.
#
# git's view first, because that is what a fresh clone gets. A tracked entry
# at mode 120000 IS a symlink to git; anything else -- 100644, 100755, a tree
# -- is not, and 100644 is exactly what a Windows checkout without developer
# mode commits back.
sym_ls <- if (git_ok) gitq("ls-files", "-s", "--", SYMLINK) else character(0)
sym_ls <- sym_ls[nzchar(sym_ls)]
sym_mode <- if (length(sym_ls) == 1L) sub("^([0-9]+) .*$", "\\1", sym_ls[1]) else NA_character_
check_true("v85",
           sprintf("git tracks `%s` as a symlink, mode 120000 (found %s)",
                   SYMLINK,
                   if (length(sym_ls) == 0L) "no such entry"
                   else if (length(sym_ls) > 1L)
                       sprintf("%d tracked entries under that name -- a DIRECTORY, not a link",
                               length(sym_ls))
                   else sym_mode),
           identical(sym_mode, "120000"))

# The blob's bytes are the target. Compared to the folder name this file
# already uses everywhere else, so a rename that moves one and not the other
# is red here rather than silently dangling.
sym_target <- if (identical(sym_mode, "120000"))
    paste(gitq("cat-file", "-p", sub("^[0-9]+ ([0-9a-f]+).*$", "\\1", sym_ls[1])),
          collapse = "") else NA_character_
want_target <- sub("/$", "", PLUGIN_DIR)
check_true("v85",
           sprintf("and it points at `%s` (tracked target: %s)",
                   want_target, if (is.na(sym_target)) "unreadable" else sym_target),
           identical(sym_target, want_target))

# The checkout's view. normalizePath resolves links, so this is one comparison
# that is red for every way the link can be wrong INCLUDING the one that looks
# right: a physical copy of the tree resolves to a different real directory.
sym_p  <- file.path(ROOT, SYMLINK)
real_p <- file.path(ROOT, want_target)
np <- function(p) tryCatch(normalizePath(p, mustWork = TRUE),
                           error = function(e) NA_character_,
                           warning = function(w) NA_character_)
sym_np  <- np(sym_p)
real_np <- np(real_p)
check_true("v85",
           sprintf("in this checkout `%s` and `%s` are the SAME directory, not two (%s)",
                   SYMLINK, want_target,
                   if (is.na(sym_np)) "the link does not resolve"
                   else if (identical(sym_np, real_np)) "same real path"
                   else "TWO DIFFERENT REAL PATHS -- a copy, or a wrong target"),
           !is.na(sym_np) && !is.na(real_np) && identical(sym_np, real_np))

# And the paths reach CONTENT. setup.praat is the file Praat itself opens when
# it registers the plugin, so if any one path has to work through the link it
# is this one. Bytes compared, not existence, and required non-empty: a
# zero-byte file at both spellings would satisfy an equality test and install
# nothing.
probe <- "setup.praat"
b_sym  <- tryCatch(readBin(file.path(sym_p, probe), "raw",
                           file.info(file.path(sym_p, probe))$size),
                   error = function(e) raw(0))
b_real <- tryCatch(readBin(file.path(real_p, probe), "raw",
                           file.info(file.path(real_p, probe))$size),
                   error = function(e) raw(0))
check_true("v85",
           sprintf("`%s/%s` and `%s/%s` are the same non-empty bytes (%d vs %d)",
                   SYMLINK, probe, want_target, probe, length(b_sym), length(b_real)),
           length(b_real) > 0 && identical(b_sym, b_real))

zipdir  <- file.path(tempdir(), "v85")
dir.create(zipdir, showWarnings = FALSE, recursive = TRUE)
ZIP     <- file.path(zipdir, "source.zip")
ZIP_TAG <- file.path(zipdir, "tagged.zip")
PREFIX  <- "EMLPraatTools-v0.0.0-v85probe/"

ga_head <- if (git_ok) gitq("cat-file", "-p", "HEAD:.gitattributes") else character(0)
ga_head <- if (is.null(attr(ga_head, "status"))) ga_head else character(0)
ga_work_p <- file.path(ROOT, ".gitattributes")
ga_work <- if (file.exists(ga_work_p)) readLines(ga_work_p, warn = FALSE) else character(0)

head_has  <- length(ga_head) > 0
work_has  <- length(ga_work) > 0
divergent <- head_has && !identical(ga_head, ga_work)

# The archive GitHub is serving RIGHT NOW is built from HEAD's .gitattributes.
# The archive measured below is built from the working tree's. When HEAD has
# one and it disagrees, those are two different zips and the measurement does
# not describe the asset -- red. When HEAD has none yet, the file is authored
# and not yet committed; that is reported loudly and is not a failure, because
# a validator that could not run until after the commit is a validator that
# tells you too late.
check_true("v85",
           "the .gitattributes measured here is the one HEAD carries (else the measurement is not the asset)",
           !divergent)
cat(sprintf("\n  .gitattributes: HEAD %s, working tree %s -> archive under test is %s\n",
            if (head_has) "present" else "ABSENT",
            if (work_has) "present" else "ABSENT",
            if (!head_has && work_has) "the PENDING-COMMIT preview"
            else if (divergent) "NOT what github.com serves"
            else "what github.com serves"), sep = "")

# The overlay is GENERIC, and deliberately so. It is HEAD plus every
# non-ignored working-tree change git reports -- not a hand-picked list of the
# files this validator would like to see present. Cherry-picking .gitattributes
# alone would let this file assert its own presence in an archive it had
# arranged to contain it; taking whatever `git status` reports makes the tree
# under test simply "HEAD as it would be if the current work were committed",
# with no say from here about what that includes. Ignored scratch is excluded
# by .gitignore, and anything genuinely stray that lands at top level is
# caught by the closed-set check rather than waved through.
tree <- NA_character_
IDX <- file.path(zipdir, "overlay.index")
if (git_ok) {
    idx <- IDX
    unlink(idx)
    gitq("read-tree", "HEAD", idx = idx, stdout = FALSE)
    st <- gitq("status", "--porcelain", "-uall")
    for (line in st) {
        if (nchar(line) < 4) next
        code <- substr(line, 1, 2)
        p    <- substr(line, 4, nchar(line))
        if (grepl("->", p, fixed = TRUE)) p <- sub("^.*-> ", "", p)   # rename
        p <- gsub('^"|"$', "", p)
        full <- file.path(ROOT, p)
        if (file.exists(full)) {
            # hash-object + update-index --cacheinfo, rather than `add`, so the
            # call is independent of the process working directory.
            sha <- gitq("hash-object", "-w", shQuote(full))
            mode <- if (file.access(full, 1) == 0) "100755" else "100644"
            if (length(sha) == 1L && nzchar(sha)) {
                gitq("update-index", "--add",
                     "--cacheinfo", paste0(mode, ",", sha, ",", p),
                     idx = idx, stdout = FALSE)
            }
        } else if (grepl("D", code)) {
            gitq("update-index", "--force-remove", "--", p,
                 idx = idx, stdout = FALSE)
        }
    }
    t <- gitq("write-tree", idx = idx)
    if (length(t) == 1L && nzchar(t)) tree <- t
}

built <- FALSE
if (!is.na(tree)) {
    gitq("archive", "--format=zip", "-o", shQuote(ZIP), tree, stdout = FALSE)
    gitq("archive", "--format=zip", paste0("--prefix=", PREFIX),
         "-o", shQuote(ZIP_TAG), tree, stdout = FALSE)
    built <- file.exists(ZIP) && file.size(ZIP) > 0
}
check_true("v85", "the release archive builds from the tree under test", built)

if (!built) {
    if (!exists("EML_SUITE")) {
        eml_report("v85 source archive shape -- what the automatic asset carries")
        eml_exit()
    }
} else {

zl    <- utils::unzip(ZIP, list = TRUE)
names <- zl$Name
files <- names[!grepl("/$", names)]
bytes <- file.size(ZIP)

top <- unique(ifelse(grepl("/", names),
                     paste0(sub("/.*$", "", names), "/"),
                     names))

cat(sprintf("  archive: %s bytes, %d entries (%d files), %d top-level\n\n",
            format(bytes, big.mark = ","), length(names), length(files), length(top)))

# --- SHAPE: what a user meets at the top level -----------------------------
for (want in MUST_SHIP) {
    check_true("v85", sprintf("archive top level carries %s", want), want %in% top)
}
for (nope in MUST_NOT_SHIP) {
    check_true("v85", sprintf("archive top level is free of %s", nope), !(nope %in% top))
}
unjudged <- setdiff(top, c(MUST_SHIP, MUST_NOT_SHIP, ALSO_PERMITTED))
check_true("v85",
           sprintf("every top-level entry has been judged%s",
                   if (length(unjudged))
                       paste0(" -- UNJUDGED: ", paste(unjudged, collapse = ", ")) else ""),
           length(unjudged) == 0)
if (length(unjudged)) {
    cat("\n  An entry named above reached the automatic asset without anyone\n",
        "  deciding it should. Add it to MUST_SHIP or MUST_NOT_SHIP in this\n",
        "  file WITH THE REASON, and if it is MUST_NOT_SHIP give it a line in\n",
        "  .gitattributes. Do not widen ALSO_PERMITTED to make this quiet.\n", sep = "")
}

# --- THE SYMLINK DOES NOT SHIP --------------------------------------------
# A user unzips this asset and drags ONE folder into Praat's preferences
# directory, so the archive must offer exactly one thing that looks like the
# plugin. The root symlink is the second thing that looks like it, and on a
# checkout that did not preserve symlinks it looks like a 22-byte text file
# with a folder name in it. Both shapes are asserted away: no top-level entry
# called `plugin`, and no archive path under a `plugin/` folder.
#
# ASSERTED HERE RATHER THAN ADDED TO MUST_NOT_SHIP, for a reason worth writing
# down: MUST_NOT_SHIP doubles as the vocabulary of the dangling-reference
# ratchet at the foot of this file, where a bare entry becomes a word-boundary
# regex run over every shipped document. `plugin` as a bare entry would match
# the English word in every sentence README.md writes about the plugin, and
# the ratchet would start measuring prose instead of paths.
check_true("v85",
           sprintf("the archive carries no top-level `%s` entry -- the compatibility symlink does not ship",
                   SYMLINK),
           !(SYMLINK %in% top) && !(paste0(SYMLINK, "/") %in% top))
n_under <- sum(startsWith(files, paste0(SYMLINK, "/")))
check_true("v85",
           sprintf("and no archive path sits under a `%s/` folder (%d found)",
                   SYMLINK, n_under),
           n_under == 0)
check_true("v85",
           sprintf("exactly one top-level entry looks like the plugin folder (%s)",
                   paste(grep("^plugin", top, value = TRUE), collapse = ", ")),
           length(grep("^plugin", top, value = TRUE)) == 1L)

# --- WEIGHT: the saving is real and stays real -----------------------------
# Ceilings, not equalities: plugin/ and validate/ both grow, and a check that
# has to be edited every time a validator is added is a check that gets edited
# without being read. The margins are wide for growth and far below the
# smallest excluded tree -- audit/ alone is 46 files and 1.1 MB, so no
# excluded tree can return without one of these tripping even if its
# MUST_NOT_SHIP line above were deleted too.
check_below("v85", "archive size in MB (was 83.95 at 84 MB / 3,945 entries)",
            6, bytes / 1e6)
check_below("v85", "archive file count (was 3,762)", 600, length(files))

# --- THE RULING: validate/ ships, whole ------------------------------------
# Line-per-path rather than -z: R's system2 cannot carry NUL bytes through
# stdout = TRUE. Safe here because git quotes any path that would need it, and
# the closed-set check above would flag a quoted top-level name as unjudged.
# NOTE the idx = IDX. This lists the OVERLAY index -- the same tree the
# archive under test was built from -- not the repository's real index. Those
# differ by exactly the uncommitted work, so reading the real one here would
# compare a pending archive against a committed file list and report a
# mismatch that is an artefact of the comparison rather than of the archive.
tracked_in <- function(sub) {
    x <- gitq("ls-files", "--", sub, idx = IDX)
    x[nzchar(x)]
}
in_zip <- function(sub) files[startsWith(files, sub)]

v_tracked <- tracked_in("validate")
v_zipped  <- in_zip("validate/")
check_true("v85",
           sprintf("validate/ ships COMPLETE: %d of %d tracked files (author ruling, 17 Aug 2026)",
                   length(v_zipped), length(v_tracked)),
           length(v_tracked) > 0 && length(v_zipped) == length(v_tracked))
check_true("v85", "the suite runner ships", "validate/run_all.R" %in% files)
check_true("v85", "the suite registry ships", "validate/REGISTRY.md" %in% files)
# The check that says the tests ship, ships. If someone excludes validate/,
# this is the line whose own subject disappears.
check_true("v85", "this validator is itself inside the archive it measures",
           "validate/v85_source_archive_shape.R" %in% files)

# --- THE LIST THAT LEADS. Read first, because both checks below are derived
# from it and neither restates a path from it. Add a row to
# RELEASE_EXCLUDE.tsv and both requirements move on the next run.
rx_path <- file.path(ROOT, "RELEASE_EXCLUDE.tsv")
rx <- if (file.exists(rx_path)) readLines(rx_path, warn = FALSE) else character(0)
rx <- rx[!grepl("^\\s*#", rx) & nzchar(trimws(rx))]
rx_paths <- trimws(sub("\t.*$", "", rx))
rx_paths <- rx_paths[nzchar(rx_paths)]

check_true("v85",
           sprintf("RELEASE_EXCLUDE.tsv parses and names %d path(s)", length(rx_paths)),
           length(rx_paths) > 0)

# A path ending "/" is a directory and covers everything beneath it; anything
# else is one exact file. That is RELEASE_EXCLUDE.tsv's own rule, quoted from
# its header, and it is the only place this file interprets that format.
rx_covers <- function(f) {
    if (!length(rx_paths)) return(FALSE)
    any(vapply(rx_paths, function(p) {
        w <- paste0(PLUGIN_DIR, p)
        if (grepl("/$", p)) startsWith(f, w) else identical(f, w)
    }, logical(1)))
}

p_tracked <- tracked_in("plugin_EML_StatsGraphs")
p_zipped  <- in_zip("plugin_EML_StatsGraphs/")
p_covered <- p_tracked[vapply(p_tracked, rx_covers, logical(1))]
p_kept    <- setdiff(p_tracked, p_covered)

# --- NO EXTENSION: .gitattributes may follow that list, not lead it --------
# Every tracked plugin/ file NO row covers must be in the archive. One that is
# not means an export-ignore line reached into plugin/-space on its own
# authority, which is where two hand-maintained lists start to drift.
missing_p <- setdiff(p_kept, p_zipped)
check_true("v85",
           sprintf("no export-ignore drops a plugin path RELEASE_EXCLUDE.tsv does not name: %d of %d uncovered files ship%s",
                   length(intersect(p_kept, p_zipped)), length(p_kept),
                   if (length(missing_p))
                       paste0(" -- MISSING: ",
                              paste(utils::head(missing_p, 5), collapse = ", ")) else ""),
           length(p_tracked) > 0 && length(missing_p) == 0)
if (length(missing_p)) {
    cat("\n  A path under plugin/ is being dropped by .gitattributes that\n",
        "  RELEASE_EXCLUDE.tsv says nothing about. That makes .gitattributes a\n",
        "  SECOND authority over the region RELEASE_EXCLUDE.tsv governs, which\n",
        "  is the exact arrangement that produced the manifest/artefact\n",
        "  contradiction earlier this week. If the path should leave the\n",
        "  INSTALLED PLUGIN, give it a row in RELEASE_EXCLUDE.tsv -- which the\n",
        "  builder both obeys and audits -- and then this line may follow it.\n",
        "  If it should not, delete the line.\n", sep = "")
}

# --- CONGRUENCE: what the artefact drops, the source archive drops too -----
# The audience ruling of 17 August 2026, pinned. Inside plugin/ the archive and
# the release artefact hold the same files, because plugin/ is the folder a
# user drags into Praat and everything under it arrives in the install.
for (p in rx_paths) {
    want <- paste0(PLUGIN_DIR, p)
    hits <- if (grepl("/$", p)) files[startsWith(files, want)] else files[files == want]
    ntracked <- sum(vapply(p_tracked,
                           function(f) if (grepl("/$", p)) startsWith(f, want)
                                       else identical(f, want), logical(1)))
    check_true("v85",
               sprintf("the artefact drops %s and so does the SOURCE archive (%d tracked file(s), %d in the zip)",
                       want, ntracked, length(hits)),
               length(hits) == 0)
}
if (any(vapply(rx_paths, function(p) {
        w <- paste0(PLUGIN_DIR, p)
        if (grepl("/$", p)) any(startsWith(files, w)) else w %in% files
    }, logical(1)))) {
    cat("\n  A tree RELEASE_EXCLUDE.tsv drops from the installable artefact is\n",
        "  still in the source archive, so a user who unzips the asset and\n",
        "  drags plugin/ into Praat installs it. Give it an export-ignore line\n",
        "  in .gitattributes. `git archive` cannot read RELEASE_EXCLUDE.tsv,\n",
        "  which is why the line has to exist and why this check exists.\n", sep = "")
}

# The other direction, from RELEASE_EXCLUDE.tsv's own header: the repository's
# sibling directories must never appear in it, because the builder stages
# plugin/ alone and such a row could never match. If one ever did, the two
# lists would be describing the same path and the partition would be gone.
siblings <- c("audit/", "evidence/", "harness/", "validate/", "lane/",
               "plugin_EML_StatsGraphs/", ".github/")
collide  <- intersect(rx_paths, siblings)
check_true("v85",
           sprintf("no RELEASE_EXCLUDE.tsv row names a repository-level directory%s",
                   if (length(collide)) paste0(" -- ", paste(collide, collapse = ", ")) else ""),
           length(collide) == 0)

# --- THE LIMITS, MEASURED WHERE THEY CAN BE ------------------------------
# GitHub names the archive root from the tag and nothing else. Built the same
# way here: under the tag prefix the plugin lands at its own name, because
# export-ignore removes paths and renames nothing -- the name comes from the
# tree. The same probe says the symlink is not there under the prefix either,
# which is the shape a user actually unzips.
# THE TAG ARCHIVE IS THE ASSET, so its four shape rulings are re-measured on
# it rather than inferred from the unprefixed zip above. Its build is asserted
# rather than guarded by `if (file.exists(...))`: a conditional here does not
# fail when the archive is missing, it DELETES the checks, and a block of
# assertions that quietly stops running is the failure mode this project keeps
# meeting. If the tagged build breaks, that is red, and the reds below follow.
check_true("v85", "the tag-built archive -- the one GitHub serves -- builds",
           file.exists(ZIP_TAG) && file.size(ZIP_TAG) > 0)
tnames <- if (file.exists(ZIP_TAG) && file.size(ZIP_TAG) > 0)
    utils::unzip(ZIP_TAG, list = TRUE)$Name else character(0)
tfiles <- tnames[!grepl("/$", tnames)]
tbare  <- sub(paste0("^", PREFIX), "", tfiles)
ttop   <- unique(sub("/.*$", "", sub(paste0("^", PREFIX), "", tnames)))

# NAMED. export-ignore removes paths and renames nothing, so this name can
# only have come from the tree.
check_true("v85",
           sprintf("a tag-built archive puts the plugin at <prefix>%s -- the name comes from the tree, not from export-ignore",
                   PLUGIN_DIR),
           any(startsWith(tfiles, paste0(PREFIX, PLUGIN_DIR))))
# NO SYMLINK. Both shapes: the link as git stores it, and the folder it would
# be on a checkout that resolved it before archiving.
check_true("v85",
           sprintf("and carries no <prefix>%s entry beside it", SYMLINK),
           !any(tnames == paste0(PREFIX, SYMLINK)) &&
           !any(startsWith(tnames, paste0(PREFIX, SYMLINK, "/"))))
# EXACTLY ONE CANDIDATE. Not "at least one": a user drags one folder in, and
# two that both look like the plugin is the ambiguity the rename removed.
check_true("v85",
           sprintf("so a user unzipping a tagged asset meets exactly one plugin folder (%s)",
                   paste(grep("^plugin", ttop, value = TRUE), collapse = ", ")),
           length(grep("^plugin", ttop, value = TRUE)) == 1L)
# NO dev/. Counted, and the count is printed, because "0 of 75" and "0 of 0"
# are the same green and only one of them means anything -- the second says
# the plugin tree is not in this archive at all.
t_dev  <- tbare[startsWith(tbare, paste0(PLUGIN_DIR, "dev/"))]
t_plug <- tbare[startsWith(tbare, PLUGIN_DIR)]
check_true("v85",
           sprintf("the tagged asset carries %d dev/ file(s) inside a plugin folder of %d",
                   length(t_dev), length(t_plug)),
           length(t_plug) > 0 && length(t_dev) == 0)
# validate/ WHOLE. Compared against what git tracks in the same tree the
# archive was built from, so it moves when the suite grows and cannot be
# satisfied by a floor or by one surviving file.
t_val <- tbare[startsWith(tbare, "validate/")]
check_true("v85",
           sprintf("and validate/ whole: %d of %d tracked files reach the tagged asset",
                   length(t_val), length(v_tracked)),
           length(v_tracked) > 0 && length(t_val) == length(v_tracked))

# The statement of those limits has to arrive with the archive, or a reader
# meets a slimmer asset and reasonably concludes it is now the download. The
# shipped .gitattributes is where it rides; this reads the copy INSIDE the
# zip, not the one on disk.
ex <- file.path(zipdir, "x"); unlink(ex, recursive = TRUE)
ga_ship <- character(0)
if (".gitattributes" %in% files) {
    utils::unzip(ZIP, files = ".gitattributes", exdir = ex)
    ga_ship <- readLines(file.path(ex, ".gitattributes"), warn = FALSE)
}
said <- function(re) any(grepl(re, ga_ship, ignore.case = TRUE))
check_true("v85", "the shipped archive names the one folder a user drags into Praat",
           said("plugin_EML_StatsGraphs"))
check_true("v85", "the shipped archive states that export-ignore cannot rename the folder",
           said("cannot|CANNOT") && said("rename"))
check_true("v85", "the shipped archive states that export-ignore cannot set the install name",
           said("install name"))
# Git records the executable bit and nothing else, so `git archive` writes
# every file 0644 (0755 where git says executable) whatever its mode on disk.
# That is why the modes in this asset are uniform and why a mode defect on
# disk cannot be seen in it -- a statement about a limit, which is what this
# block is for, and one a reader needs before trusting the asset's modes.
check_true("v85", "the shipped archive states that git carries no file mode but the executable bit",
           said("file mode") && said("0644"))
check_true("v85", "the shipped archive still points at the built zip as the release",
           said("build-release\\.py"))

# --- THE DEBT THIS CHANGE CREATES, RATCHETED ------------------------------
# README.md and START_HERE.md both ship, and both describe trees that no
# longer arrive with them: README's "Layout" section walks audit/, harness/
# and evidence/, and START_HERE points at harness/GUI_HARNESS_RECIPE.md.
# Measured 17 August 2026: 13 distinct references. Neither file is repaired
# here -- that is prose work outside this change -- so the count is PINNED as
# a ratchet. It may fall to zero; it may not grow. A new document that ships
# and links into an excluded tree turns this red on the run that adds it.
#
# The fix, for whoever takes it: give the excluded trees one sentence in
# README saying they are in the repository and not in the archive, and turn
# the links into github.com URLs, which resolve for a reader of either.
REF_CEILING <- 13L
shipped_docs <- intersect(c("README.md", "START_HERE.md"), files)
unlink(ex, recursive = TRUE)
refs <- character(0)
if (length(shipped_docs)) {
    utils::unzip(ZIP, files = shipped_docs, exdir = ex)
    # A REFERENCE, not a mention. README says "audit/ the audit record" -- the
    # first is a path a reader may try to open in the archive, the second is
    # English. So a directory only counts with its slash and something after
    # it or not, and a file only as its literal name.
    dirs  <- sub("/$", "", grep("/$", MUST_NOT_SHIP, value = TRUE))
    fils  <- grep("/$", MUST_NOT_SHIP, value = TRUE, invert = TRUE)
    parts <- c(if (length(dirs))
                   sprintf("\\b(%s)/[A-Za-z0-9_./-]*", paste(dirs, collapse = "|")),
               if (length(fils))
                   sprintf("\\b(%s)\\b", paste(gsub("\\.", "\\\\.", fils), collapse = "|")))
    excl_re <- paste(parts, collapse = "|")
    for (d in shipped_docs) {
        txt <- paste(readLines(file.path(ex, d), warn = FALSE), collapse = "\n")
        m <- regmatches(txt, gregexpr(excl_re, txt))[[1]]
        refs <- c(refs, unique(m))
    }
}
refs <- unique(refs)
check_true("v85",
           sprintf("shipped root docs reference %d path(s) in excluded trees; ratchet is %d (must not grow)",
                   length(refs), REF_CEILING),
           length(refs) <= REF_CEILING)
if (length(refs) > REF_CEILING) {
    cat("\n  A document that SHIPS in the source archive now links into a tree\n",
        "  that does not. Either repair the link to a github.com URL, or do not\n",
        "  ship the document. Raising REF_CEILING is not a repair.\n", sep = "")
}

# --- THE SAME DEBT, ONE LEVEL DOWN, AND WHY IT IS A SECOND RATCHET --------
# Dropping plugin/dev/ created references of exactly the shape above, inside
# plugin/ rather than beside it, and the ratchet above CANNOT SEE THEM: it is
# built from MUST_NOT_SHIP, which is a list of TOP-LEVEL names. Widening that
# list to hold plugin/dev/ would be wrong twice over -- plugin/ is a
# MUST_SHIP top-level entry, and the count would then have to be raised, which
# this file has just said is not a repair.
#
# So it is its own ratchet at its own measured value. 17 August 2026: ONE
# reference, README.md -> plugin/dev/ARCHITECTURE.md. It may fall to zero; it
# may not grow. The repair is the same one -- a github.com URL resolves for a
# reader of the archive and a reader of the repository alike.
DEV_REF_CEILING <- 1L
dev_refs <- character(0)
if (length(shipped_docs)) {
    for (d in shipped_docs) {
        txt <- paste(readLines(file.path(ex, d), warn = FALSE), collapse = "\n")
        m <- regmatches(txt, gregexpr(
            "\\b(plugin|plugin_EML_StatsGraphs)/dev/[A-Za-z0-9_./-]*", txt))[[1]]
        dev_refs <- c(dev_refs, unique(m))
    }
}
dev_refs <- unique(dev_refs)
check_true("v85",
           sprintf("shipped root docs reference %d path(s) inside plugin/dev/, which no longer ships; ratchet is %d",
                   length(dev_refs), DEV_REF_CEILING),
           length(dev_refs) <= DEV_REF_CEILING)

}   # end if (built)

if (!exists("EML_SUITE")) {
    eml_report("v85 source archive shape -- what the automatic asset carries")
    eml_exit()
}
