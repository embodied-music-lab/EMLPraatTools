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
# THE TWO EXCLUSION LISTS, AND WHY THEY ARE NOT THE SAME LIST
#
# This repository now has two files that leave things out, and it was burned
# this week by two hand-maintained lists drifting apart. So the relationship
# between them is computed here on every run rather than trusted.
#
# They cannot be made identical, and forcing that would be dishonest about
# both. RELEASE_EXCLUDE.tsv's own header says why: its paths are
# PLUGIN-RELATIVE, because plugin/dev/tools/build-release.py stages plugin/
# alone. The repository's sibling directories -- audit/, evidence/, harness/,
# validate/ -- are outside the built artefact by the shape of the tree, not by
# any list, and that header forbids naming them in it ("an exclusion that can
# never match", which the builder rejects). The two lists therefore cover
# DIFFERENT SCOPES.
#
# The honest relationship is a partition plus a containment, and both halves
# are checked below, both derived from RELEASE_EXCLUDE.tsv as it is on disk at
# run time -- no path from that file is restated in this one:
#
#   PARTITION. RELEASE_EXCLUDE.tsv is the sole authority inside plugin/.
#   .gitattributes is the sole authority outside it. Enforced by comparing
#   the archive's plugin/ subtree against the tracked plugin/ subtree at HEAD,
#   file for file: if they match, no export-ignore line can have had any
#   effect inside plugin/, whatever it says. That is the structural version of
#   "one source of truth" -- the second list is not asked to agree with the
#   first, it is prevented from operating in the first's territory at all.
#
#   CONTAINMENT. Every path RELEASE_EXCLUDE.tsv names must be PRESENT in the
#   source archive. The artefact list names what a user of the INSTALLED
#   PLUGIN does not need; a SOURCE archive is for someone reading the source,
#   and plugin/dev/ -- the suites, the Praat and Python tooling, the four
#   design documents -- is the first thing such a reader wants. So inside
#   plugin/ the source archive is a strict superset of the artefact, and the
#   two lists are COMPLEMENTARY rather than shared. Adding a row to
#   RELEASE_EXCLUDE.tsv automatically adds a presence requirement here.
#
# Read together: the source archive drops what the plugin's developer tree
# sits beside, and keeps what the plugin's release drops. Neither list has to
# be edited when the other changes, and neither can silently contradict the
# other, because a contradiction in either direction turns this file red.
#
# ---------------------------------------------------------------------------
# WHAT export-ignore CANNOT DO, ASSERTED AND NOT MERELY SAID
#
# It removes paths. That is all. It cannot rename the archive's top-level
# folder, cannot set the plugin's install name, and cannot fix file modes
# (finding P1: 13 of 21 files in plugin/scripts/ are 0600 in the built tree,
# and git stores only the executable bit, so no file in this repository can
# express the fix). THE AUTOMATIC ASSET REMAINS NON-INSTALLABLE. The zip from
# plugin/dev/tools/build-release.py is still the only artefact to install and
# the only one the documentation points at; this work reduces the confusion of
# someone who downloads the automatic asset anyway, and does not open a second
# release channel.
#
# The rename limit is not left as prose. One archive below is built with
# --prefix, the way GitHub builds it from a tag, and checked to confirm the
# plugin still arrives at <prefix>plugin/ -- so the statement "this does not
# produce an installable folder name" is a measurement. It doubles as the pin
# on the 17 August ruling that the source folder stays `plugin/`; the INSTALL
# name plugin_EML_StatsGraphs is a separate thing, set by packaging, and
# v47_plugin_folder_name.R is what holds it.
#
# ---------------------------------------------------------------------------
# validate/ STAYS IN, BY AUTHOR RULING OF 17 AUGUST 2026
#
# It is the largest thing that stays after the plugin -- 2.7 MB, and roughly
# a quarter of the slimmed archive -- and cutting it would be the easy further
# saving. An archive calling itself "source" carries the
# tests that make the source credible, and for this project the validation
# suite is the product's main claim. So the ruling is pinned in the direction
# nobody would think to guard: this file fails if validate/ gets SMALLER in
# the archive than it is in the tree, which is what an `export-ignore` on it,
# or on any part of it, would do.
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
    # The plugin. The reason the asset exists. 4.55 MB / 327 files.
    "plugin/",
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
    "RETRIES.tsv"
)

ALSO_PERMITTED <- c(
    # Authored separately, 17 August 2026. GitHub reads it to render "Cite
    # this repository", and a citation file belongs with the source it cites.
    # Listed as permitted-not-required so this check does not go red in the
    # window before it lands, and does not go green-by-silence after.
    "CITATION.cff"
)

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

# --- THE PARTITION: .gitattributes has no opinion inside plugin/ -----------
p_tracked <- tracked_in("plugin")
p_zipped  <- in_zip("plugin/")
missing_p <- setdiff(p_tracked, p_zipped)
check_true("v85",
           sprintf("no export-ignore reaches inside plugin/: %d of %d tracked files ship%s",
                   length(p_zipped), length(p_tracked),
                   if (length(missing_p))
                       paste0(" -- MISSING: ",
                              paste(utils::head(missing_p, 5), collapse = ", ")) else ""),
           length(p_tracked) > 0 && length(missing_p) == 0)
if (length(missing_p)) {
    cat("\n  A path under plugin/ is being dropped by .gitattributes. That makes\n",
        "  it a SECOND authority over the region RELEASE_EXCLUDE.tsv governs,\n",
        "  which is the exact arrangement that produced the manifest/artefact\n",
        "  contradiction earlier this week. Remove the line. If the intent was\n",
        "  to keep something out of the INSTALLED PLUGIN, it belongs in\n",
        "  RELEASE_EXCLUDE.tsv, which the builder both obeys and audits.\n", sep = "")
}

# --- THE CONTAINMENT: everything the artefact drops, the source keeps ------
# Derived. The rows are read here, not restated: add a row to
# RELEASE_EXCLUDE.tsv and a presence requirement appears on the next run.
rx_path <- file.path(ROOT, "RELEASE_EXCLUDE.tsv")
rx <- if (file.exists(rx_path)) readLines(rx_path, warn = FALSE) else character(0)
rx <- rx[!grepl("^\\s*#", rx) & nzchar(trimws(rx))]
rx_paths <- trimws(sub("\t.*$", "", rx))
rx_paths <- rx_paths[nzchar(rx_paths)]

check_true("v85",
           sprintf("RELEASE_EXCLUDE.tsv parses and names %d path(s)", length(rx_paths)),
           length(rx_paths) > 0)

for (p in rx_paths) {
    want <- paste0("plugin/", p)
    present <- if (grepl("/$", p)) any(startsWith(files, want)) else want %in% files
    check_true("v85",
               sprintf("the artefact drops %s and the SOURCE archive keeps it", want),
               present)
}

# The other direction, from RELEASE_EXCLUDE.tsv's own header: the repository's
# sibling directories must never appear in it, because the builder stages
# plugin/ alone and such a row could never match. If one ever did, the two
# lists would be describing the same path and the partition would be gone.
siblings <- c("audit/", "evidence/", "harness/", "validate/", "plugin/", ".github/")
collide  <- intersect(rx_paths, siblings)
check_true("v85",
           sprintf("no RELEASE_EXCLUDE.tsv row names a repository-level directory%s",
                   if (length(collide)) paste0(" -- ", paste(collide, collapse = ", ")) else ""),
           length(collide) == 0)

# --- THE LIMITS, MEASURED WHERE THEY CAN BE ------------------------------
# GitHub names the archive root from the tag. Built the same way here to show
# that the plugin still lands at <prefix>plugin/: export-ignore removes paths
# and renames nothing, so no arrangement of it yields an installable folder.
# This is also the pin on the 17 August ruling that the source folder is
# `plugin/` and stays `plugin/`.
if (file.exists(ZIP_TAG)) {
    tnames <- utils::unzip(ZIP_TAG, list = TRUE)$Name
    check_true("v85",
               "a tag-built archive puts the plugin at <prefix>plugin/ -- export-ignore cannot rename it",
               any(startsWith(tnames, paste0(PREFIX, "plugin/"))))
    check_true("v85",
               "and does NOT produce an installable plugin_EML_StatsGraphs/ folder (that name is set by packaging)",
               !any(startsWith(tnames, paste0(PREFIX, "plugin_EML_StatsGraphs/"))))
}

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
check_true("v85", "the shipped archive states that the automatic asset is NOT installable",
           said("not installable|non-installable"))
check_true("v85", "the shipped archive states that export-ignore cannot rename the folder",
           said("cannot|CANNOT") && said("rename"))
check_true("v85", "the shipped archive states that export-ignore cannot set the install name",
           said("install name"))
check_true("v85", "the shipped archive states that export-ignore cannot fix file modes (P1)",
           said("file mode") && said("P1|0600"))
check_true("v85", "the shipped archive points installers at the built zip instead",
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

}   # end if (built)

if (!exists("EML_SUITE")) {
    eml_report("v85 source archive shape -- what the automatic asset carries")
    eml_exit()
}
