# ============================================================================
# v82_generated_barrel.R -- the one include line, and the file that has to be
#                           written for it to exist
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS IS ABOUT. A user writing their own Praat script wants one line,
# not thirteen, and until setup.praat generated one there was no line that could
# work. The reason is a property of Praat, and it is measured rather than
# quoted: `include` is a parse-time text paste, and a relative path inside an
# included file resolves against the TOP-LEVEL script's folder, not against
# the folder of the file the line is written in. Section 1 below re-measures
# that on the live binary. It means the shipped barrel scripts/eml-lib.praat,
# whose lines read "../stats/...", resolves them against the USER's folder --
# correct for the plugin's own wrappers, which live in scripts/, and incapable
# of working for anybody else. A static file cannot compute where it was
# installed to.
#
# setup.praat can. Praat executes it from the plugin's own folder at every
# launch, so it is the one part of the plugin that knows the installed
# location, and it writes scripts/eml-lib-user.praat with full paths.
#
# THE FOUR THINGS THAT CAN GO WRONG, AND ARE THEREFORE WHAT THIS FILE READS.
#
#   1. THE FILE ON DISK IS STALE. The generator writes only when the content
#      would change -- that is a requirement, not an optimisation, see 3 --
#      and the failure mode of any write-only-when-changed rule is a
#      comparison that says "same" when it should say "different". A barrel
#      naming a folder the plugin is no longer in fails at the user's include
#      line with a path they never typed. Section 4 seeds exactly that file
#      and requires the next launch to repair it.
#
#   2. THE INCLUDE LIST DRIFTS FROM THE RECORDER'S. Two places in this plugin
#      write an include block: this generator, and @emlRecordRender, which
#      writes one into every recorded script. They are the same thirteen
#      modules in the same dependency order, and if they stop being the same then one
#      of the two produces a file that dies on "Procedure ... not found" --
#      which is how the draw layer's omission from the recorder's list was
#      found. Section 5 does not compare the barrel against a list retyped
#      here. It RECORDS A SESSION on the same installation, takes the include
#      block out of the emitted script, and compares the two artefacts.
#
#   3. AN UNCHANGED LAUNCH WRITES ANYWAY. Praat 7 challenges a script that
#      touches disk. A plugin that rewrote an identical file at every launch
#      would put a prompt in front of a user who changed nothing, every time
#      they opened Praat. Section 3 launches twice and reads the modification
#      time to nanoseconds: an unchanged second launch must not move it. This
#      is the check a later reader is most likely to think is an optimisation
#      and delete.
#
#   4. THE ROOT IS RESOLVED TWICE. The recorder resolved the plugin root
#      itself; the generator needs the same answer. Two copies of that
#      arithmetic are two things that can disagree about where the plugin is,
#      and a user whose recorded script and whose generated barrel name
#      different folders has no way to tell which is lying. There is one
#      procedure, @emlPluginRoot, in stats/eml-record.praat -- the one module
#      that carries no relative include of its own and can therefore be
#      included from the plugin root, from scripts/, and from a user's folder
#      alike. Section 6 reads the source and requires the arithmetic to appear
#      exactly once.
#
# THE SELF-HEALING PROPERTY IS DRIVEN, NOT ARGUED. Sections 7 and 8 move an
# installed plugin -- carrying its now-wrong barrel with it -- and launch
# Praat at the new location. Section 8's move is the one Praat itself makes
# between 6.x and 7.x, ~/.praat-dir to ~/.config/praat. Both then RUN a user
# script whose only library line is the generated barrel, because a barrel
# with plausible paths in it is not evidence that the paths resolve.
#
#     Rscript validate/v82_generated_barrel.R
#
# Input: none committed. Every sandbox is built here, from plugin/, into
#        tempdir(), and Praat is launched in it. $EML_SETUP_SRC overrides the
#        setup source read by section 6 and $EML_RECORD_SRC the recorder
#        source, both for break tests; $EML_PLUGIN_SRC overrides the tree that
#        is installed into the sandboxes. $PRAAT overrides the binary.
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

plug <- Sys.getenv("EML_PLUGIN_SRC", unset = "")
if (!nzchar(plug)) plug <- repo_path("plugin")
setup_src <- Sys.getenv("EML_SETUP_SRC", unset = "")
if (!nzchar(setup_src)) setup_src <- file.path(plug, "setup.praat")
record_src <- Sys.getenv("EML_RECORD_SRC", unset = "")
if (!nzchar(record_src)) record_src <- file.path(plug, "stats", "eml-record.praat")

BARREL <- file.path("scripts", "eml-lib-user.praat")

# THE MODULES, IN THE ORDER THE LAYERS REQUIRE. This list is written
# out here because an order has to be pinned against something, and a
# generator compared only against itself pins nothing. It is not the only
# thing the order is checked against: section 5 compares the same barrel
# against the block a RECORDING emits, which is a second implementation in a
# different file, so a change made in both places still has to get past a
# comparison with this one.
CANON <- c(
    "stats/eml-core-utilities.praat",
    "stats/eml-core-descriptive.praat",
    "stats/eml-extract.praat",
    "stats/eml-output.praat",
    "stats/eml-inferential.praat",
    "stats/eml-psychometrics.praat",
    "stats/eml-categorical.praat",
    "stats/eml-result-writer.praat",
    "stats/eml-record.praat",
    "graphs/eml-graph-procedures.praat",
    "graphs/eml-annotation-procedures.praat",
    "graphs/eml-draw-procedures.praat",
    "stats/eml-analysis.praat",
    "stats/eml-demo-tables.praat")

# ---------------------------------------------------------------------------
# THE BINARY. Same floor and the same refusal as harness/_env.sh: a green live
# drive on a build below the plugin's own floor is not evidence.
# ---------------------------------------------------------------------------
praat <- Sys.getenv("PRAAT", unset = "")
if (!nzchar(praat)) {
    for (cand in c(repo_path("..", "praat"), Sys.which("praat_barren"),
                   Sys.which("praat"))) {
        if (nzchar(cand) && file.exists(cand)) { praat <- cand; break }
    }
}
pvnum <- 0
if (nzchar(praat) && file.exists(praat)) {
    pv <- suppressWarnings(system2(praat, "--version", stdout = TRUE,
                                   stderr = TRUE))[1]
    m <- regmatches(pv, regexpr("[0-9]+\\.[0-9]+(\\.[0-9]+)?", pv))
    if (length(m)) {
        p <- as.integer(strsplit(m, ".", fixed = TRUE)[[1]])
        if (length(p) < 3) p <- c(p, 0L)
        pvnum <- p[1] * 1000 + p[2] * 100 + p[3]
    }
}
canDrive <- pvnum >= 6630
check_true("v82", "a Praat at or above the 6.6.30 floor is available to drive",
           canDrive)

# Every sandbox is built under here and nothing outside it is touched.
# $EML_V82_WORK keeps the sandboxes after the run, for a break test that needs
# to look at what a launch wrote; unset, R's own tempdir takes them away.
work <- Sys.getenv("EML_V82_WORK", unset = "")
if (!nzchar(work)) work <- file.path(tempdir(), "v82")
unlink(work, recursive = TRUE)
dir.create(work, showWarnings = FALSE, recursive = TRUE)

# install -- a COPY of the plugin, never a symlink into the repository. A
# launch writes the barrel into the installed folder, and a symlink would make
# this validator write a generated file into the tree it is measuring.
install <- function(home, prefs) {
    dir.create(home, showWarnings = FALSE, recursive = TRUE)
    dir.create(prefs, showWarnings = FALSE, recursive = TRUE)
    tgt <- file.path(prefs, "plugin_EML_StatsGraphs")
    if (!dir.exists(tgt)) {
        dir.create(tgt, showWarnings = FALSE, recursive = TRUE)
        file.copy(list.files(plug, full.names = TRUE), tgt,
                  recursive = TRUE, copy.date = TRUE)
    }
    tgt
}

# launch -- start Praat with that preferences folder and that HOME, running a
# script that does nothing. The plugin's setup.praat runs regardless, which is
# the whole subject of this file.
launch <- function(home, prefs, script = NULL) {
    unlink(file.path(prefs, c("pid", "message")))
    if (is.null(script)) {
        script <- file.path(home, "noop.praat")
        writeLines('writeInfoLine: "launched"', script)
    }
    out <- suppressWarnings(system2("env",
        c("-u", "DISPLAY", paste0("HOME=", home), shQuote(praat),
          shQuote(paste0("--pref-dir=", prefs)), "--run", shQuote(script)),
        stdout = TRUE, stderr = TRUE))
    status <- attr(out, "status"); if (is.null(status)) status <- 0L
    list(status = status, out = paste(out, collapse = "\n"))
}

mtime_ns <- function(p) {
    v <- suppressWarnings(system2("stat", c("-c", "%.9Y", shQuote(p)),
                                  stdout = TRUE, stderr = TRUE))
    if (length(v) != 1L) "" else v[1]
}

read_raw <- function(p) {
    if (!file.exists(p)) return(NULL)
    readBin(p, "raw", n = file.info(p)$size)
}

includes_of <- function(path) {
    if (!file.exists(path)) return(character(0))
    ln <- readLines(path, warn = FALSE)
    ln <- grep("^include ", ln, value = TRUE)
    trimws(sub("^include ", "", ln))
}

# ---------------------------------------------------------------------------
# 1. THE PROPERTY OF PRAAT THE WHOLE DESIGN RESTS ON, RE-MEASURED
# ---------------------------------------------------------------------------
# If a relative include resolved against the including FILE's folder, the
# shipped barrel would work from a user's folder and none of this would be
# needed. The measurement is two files, one of which is reachable only under
# one of the two rules: lib/a.praat says `include b.praat`, and b.praat exists
# in lib/ and nowhere else. Under the file-relative rule it is found; under
# the top-level rule Praat looks beside the top script and fails.
if (canDrive) {
    d <- file.path(work, "incrule")
    dir.create(file.path(d, "top"), recursive = TRUE, showWarnings = FALSE)
    dir.create(file.path(d, "lib"), recursive = TRUE, showWarnings = FALSE)
    writeLines(c("include b.praat", "procedure a", "endproc"),
               file.path(d, "lib", "a.praat"))
    writeLines(c("procedure b", "endproc"), file.path(d, "lib", "b.praat"))
    writeLines(c("include ../lib/a.praat", 'writeInfoLine: "parsed"'),
               file.path(d, "top", "main.praat"))
    r <- suppressWarnings(system2("env",
        c("-u", "DISPLAY", shQuote(praat), "--run",
          shQuote(file.path(d, "top", "main.praat"))),
        stdout = TRUE, stderr = TRUE))
    txt <- paste(r, collapse = "\n")
    check_true("v82",
               "a relative include resolves against the TOP-LEVEL script's folder",
               grepl("top/b.praat", txt, fixed = TRUE))
    # And the consequence, on the shipped barrel itself: included from a
    # folder that is not scripts/, it cannot find what it names.
    u <- file.path(d, "user"); dir.create(u, showWarnings = FALSE)
    home1 <- file.path(work, "s1", "home")
    prefs1 <- file.path(home1, ".praat-dir")
    install(home1, prefs1)
    writeLines(c(sprintf("include %s",
                         file.path(prefs1, "plugin_EML_StatsGraphs",
                                   "scripts", "eml-lib.praat")),
                 'writeInfoLine: "parsed"'),
               file.path(u, "old.praat"))
    r2 <- launch(home1, prefs1, file.path(u, "old.praat"))
    check_true("v82",
               "the shipped relative barrel cannot be included from a user folder",
               grepl("eml-lib-stats.praat", r2$out, fixed = TRUE) &&
               grepl("not read", r2$out, fixed = TRUE))
}

# ---------------------------------------------------------------------------
# 2. A LAUNCH GENERATES THE BARREL, AND IT SAYS WHAT IT IS
# ---------------------------------------------------------------------------
barrel1 <- NULL
inc1 <- character(0)
if (canDrive) {
    home1 <- file.path(work, "s1", "home")
    prefs1 <- file.path(home1, ".praat-dir")
    root1 <- install(home1, prefs1)
    bp1 <- file.path(root1, BARREL)
    unlink(bp1)
    L <- launch(home1, prefs1)
    check_true("v82", "the launch completed", L$status == 0L)
    check_true("v82", "the launch generated scripts/eml-lib-user.praat",
               file.exists(bp1))
    if (file.exists(bp1)) {
        barrel1 <- readLines(bp1, warn = FALSE)
        inc1 <- includes_of(bp1)
        hdr <- paste(grep("^#", barrel1, value = TRUE), collapse = " ")
        # The header has three jobs the ruling names, and each is read
        # separately so that losing one cannot hide behind the other two.
        check_true("v82", "the header says the file is generated",
                   grepl("GENERATED", hdr))
        check_true("v82", "the header says it is generated at launch",
                   grepl("every Praat launch", hdr, fixed = TRUE))
        check_true("v82", "the header says hand edits are overwritten",
                   grepl("overwritten", hdr, fixed = TRUE))
        # AND IT SHOWS THE USER THE LINE. A barrel whose own include line is
        # not written down anywhere is a file nobody can be told how to use.
        expect_line <- paste0("include ~/.praat-dir/plugin_EML_StatsGraphs/",
                              "scripts/eml-lib-user.praat")
        check_true("v82", "the header quotes the one line a user writes",
                   any(grepl(expect_line, barrel1, fixed = TRUE)))
        # PURE ASCII. Praat chooses an output encoding from the text it is
        # given -- UTF-16 the moment one character needs it -- and a re-encoded
        # file would never compare equal to the string that produced it, so
        # every launch would write. The requirement in section 3 depends on
        # this, which is why it is asserted rather than assumed.
        rw <- read_raw(bp1)
        check_true("v82", "the generated file is pure ASCII, so it re-reads exactly",
                   !is.null(rw) && all(as.integer(rw) < 128L))
    }
    check_true("v82", "the barrel names every module in the list",
               length(inc1) == length(CANON))
    stripped <- sub("^.*/plugin_EML_StatsGraphs/", "", inc1)
    check_true("v82",
               "its include list is the canonical module order",
               identical(stripped, CANON))
    check_true("v82",
               "every include line names the installed root, home-relative",
               length(inc1) > 0 &&
               all(startsWith(inc1, "~/.praat-dir/plugin_EML_StatsGraphs/")))
    # THE POINT OF THE WHOLE ORDER: one line, from a folder that is not the
    # plugin's, and the stack loads. Asserted by RUNNING it.
    if (file.exists(bp1)) {
        u <- file.path(work, "s1", "user"); dir.create(u, recursive = TRUE,
                                                       showWarnings = FALSE)
        writeLines(c("include ~/.praat-dir/plugin_EML_StatsGraphs/scripts/eml-lib-user.praat",
                     "@emlInitializeDrawingDefaults",
                     '@emlFormatP: 0.0123',
                     'writeInfoLine: "BARREL RAN ", emlFormatP.formatted$'),
                   file.path(u, "mine.praat"))
        r <- launch(home1, prefs1, file.path(u, "mine.praat"))
        check_true("v82",
                   "the one generated line loads the stack from a user's folder",
                   r$status == 0L && grepl("BARREL RAN", r$out, fixed = TRUE))
    }
}

# ---------------------------------------------------------------------------
# 3. AN UNCHANGED LAUNCH DOES NOT WRITE
# ---------------------------------------------------------------------------
# Requirement, not optimisation. The modification time is read to nanoseconds
# because a second-resolution read would pass on any pair of writes that
# landed inside the same second, which two launches of a fast script routinely
# do.
if (canDrive && !is.null(barrel1)) {
    home1 <- file.path(work, "s1", "home")
    prefs1 <- file.path(home1, ".praat-dir")
    bp1 <- file.path(prefs1, "plugin_EML_StatsGraphs", BARREL)
    t1 <- mtime_ns(bp1)
    b1 <- read_raw(bp1)
    Sys.sleep(1.1)
    L2 <- launch(home1, prefs1)
    t2 <- mtime_ns(bp1)
    b2 <- read_raw(bp1)
    check_true("v82", "the second launch completed", L2$status == 0L)
    check_true("v82", "an unchanged launch leaves the modification time alone",
               nzchar(t1) && identical(t1, t2))
    check_true("v82", "and the bytes are unchanged",
               !is.null(b1) && identical(b1, b2))
    # The nanosecond read has to be capable of separating two writes at all,
    # or the check above passes on a filesystem that reports one constant.
    probe <- file.path(work, "mtime-probe.txt")
    writeLines("a", probe); p1 <- mtime_ns(probe)
    Sys.sleep(0.05)
    writeLines("b", probe); p2 <- mtime_ns(probe)
    check_true("v82", "the modification-time read can tell two writes apart",
               nzchar(p1) && nzchar(p2) && !identical(p1, p2))
}

# ---------------------------------------------------------------------------
# 4. A STALE BARREL IS REPAIRED, AND THE REGENERATION MATCHES DISK
# ---------------------------------------------------------------------------
# The file is seeded with a barrel naming a folder the plugin is not in --
# what a move leaves behind -- and the next launch has to replace it. The
# reference it is compared against is not typed here: the barrel is then
# deleted and a further launch regenerates it from nothing, and the repaired
# file and the regenerated file have to be the same bytes.
if (canDrive) {
    home2 <- file.path(work, "s2", "home")
    prefs2 <- file.path(home2, ".praat-dir")
    root2 <- install(home2, prefs2)
    bp2 <- file.path(root2, BARREL)
    stale <- c("# a barrel left behind by an older location",
               "include ~/somewhere-else/plugin_EML_StatsGraphs/stats/eml-analysis.praat")
    writeLines(stale, bp2)
    L <- launch(home2, prefs2)
    repaired <- read_raw(bp2)
    check_true("v82", "a stale barrel is rewritten by the next launch",
               !is.null(repaired) &&
               !any(grepl("somewhere-else", readLines(bp2, warn = FALSE))))
    unlink(bp2)
    launch(home2, prefs2)
    fresh <- read_raw(bp2)
    check_true("v82", "the regenerated barrel exists", !is.null(fresh))
    check_true("v82",
               "regenerating from nothing reproduces the file on disk, byte for byte",
               !is.null(repaired) && !is.null(fresh) && identical(repaired, fresh))
}

# ---------------------------------------------------------------------------
# 5. THE BARREL AND A RECORDED SCRIPT NAME THE SAME MODULES, IN THE SAME ORDER
# ---------------------------------------------------------------------------
# Not against a list retyped in this file: against the block @emlRecordRender
# actually writes, taken off an emitted script produced by a recording on this
# same installation. Two independent writers of the same block, compared.
if (canDrive && length(inc1) == length(CANON)) {
    home1 <- file.path(work, "s1", "home")
    prefs1 <- file.path(home1, ".praat-dir")
    pr <- file.path(prefs1, "plugin_EML_StatsGraphs")
    rec <- file.path(work, "s1", "rec")
    dir.create(rec, recursive = TRUE, showWarnings = FALSE)
    drv <- file.path(rec, "record.praat")
    writeLines(c(
        sprintf("include %s/stats/eml-record.praat", pr),
        "@emlRecordInit",
        sprintf('@emlRecordBegin: "%s"', rec),
        sprintf('@emlRecordLoadPhrases: "%s/data/eml-record-phrases.csv"', pr),
        '@emlRecordHeader: "v82.csv", 3, 2, "v82"',
        # ONE STEP, BECAUSE A FLUSH WITH NOTHING RECORDED WRITES NOTHING --
        # @emlRecordFlush returns .written = 0 below emlRecordN = 1. What the
        # step DOES is beside the point here; the include block is the same
        # block whatever the session held.
        '@emlRecordStep: "analysis", "a v82 step", "", "clearinfo", ""',
        sprintf('@emlRecordFlush: "%s/emitted.praat"', rec),
        "@emlRecordDiscard",
        'writeInfoLine: "recorded"'), drv)
    r <- launch(home1, prefs1, drv)
    em <- file.path(rec, "emitted.praat")
    check_true("v82", "a recording emitted a script on this installation",
               file.exists(em))
    if (file.exists(em)) {
        inc_rec <- includes_of(em)
        check_true("v82",
                   "the recorder's include block and the barrel's are identical",
                   identical(inc_rec, inc1))
        check_true("v82",
                   "and both name the root @emlPluginRoot resolved for this install",
                   length(inc_rec) > 0 &&
                   all(startsWith(inc_rec,
                                  "~/.praat-dir/plugin_EML_StatsGraphs/")))
    }
    # THE SHARED PROCEDURE ANSWERS FOR ITSELF, on the same installation, so
    # that "both agree" cannot be two writers agreeing on a wrong root.
    q <- file.path(rec, "root.praat")
    writeLines(c(sprintf("include %s/stats/eml-record.praat", pr),
                 "@emlPluginRoot",
                 'writeInfoLine: "ROOT=", emlPluginRoot.root$'), q)
    rq <- launch(home1, prefs1, q)
    got <- sub(".*ROOT=", "", sub("\n.*", "", sub(".*?ROOT=", "ROOT=", rq$out)))
    check_true("v82",
               "@emlPluginRoot reports the folder the plugin is installed in",
               grepl("ROOT=~/.praat-dir/plugin_EML_StatsGraphs", rq$out,
                     fixed = TRUE))
    check_true("v82", "and the barrel's lines are built on that answer",
               length(inc1) > 0 && all(startsWith(inc1, trimws(got))))
}

# ---------------------------------------------------------------------------
# 6. ONE RESOLVER, READ OFF THE SOURCE
# ---------------------------------------------------------------------------
# A drive cannot see a second copy of the arithmetic that happens to agree
# today. This section can.
rl <- if (file.exists(record_src)) readLines(record_src, warn = FALSE) else character(0)
sl <- if (file.exists(setup_src)) readLines(setup_src, warn = FALSE) else character(0)
check_true("v82", "the recorder source is present", length(rl) > 0)
check_true("v82", "the setup source is present", length(sl) > 0)

code_r <- rl[!grepl("^\\s*[#;]", rl)]
code_s <- sl[!grepl("^\\s*[#;]", sl)]

check_true("v82", "eml-record.praat defines @emlPluginRoot exactly once",
           sum(grepl("^procedure emlPluginRoot\\s*$", rl)) == 1L)
check_true("v82", "@emlRecordBegin takes its root from that procedure",
           any(grepl("^\\s*@emlPluginRoot\\s*$", code_r)) &&
           any(grepl("emlRecordPluginRoot\\$\\s*=\\s*emlPluginRoot\\.root\\$",
                     code_r)))
# THE ARITHMETIC APPEARS ONCE, AND IT IS THE WHOLE MENTION THAT IS COUNTED.
# preferencesDirectory$ joined to the plugin folder name is the first step of
# the resolution; a second occurrence in either file is a second
# implementation, whatever it currently computes. Counting only the lines that
# put a "+" and a quote immediately after preferencesDirectory$ counts a
# spelling rather than a use: Praat continues an expression with "...", so
#
#     emlRecordPluginRoot$ = preferencesDirectory$
#     ... + "/plugin_EML_StatsGraphs"
#
# is a second join that no such pattern sees. Every mention is counted
# instead, in BOTH files, and the answer for setup.praat is none at all --
# it has a resolver to ask.
#
# STRING LITERALS ARE NOT CODE. A recorded script's header tells the reader to
# run `writeInfoLine: preferencesDirectory$` when they cannot find the plugin;
# that is text the recorder PRINTS, and counting it as a resolution would make
# this check fail on a helpful sentence.
nostr <- function(x) gsub('"[^"]*"', '""', x)
pd <- function(x) sum(grepl('preferencesDirectory\\$', nostr(x)))
check_true("v82",
           sprintf("the recorder mentions preferencesDirectory$ once, where the join happens (%d)",
                   pd(code_r)),
           pd(code_r) == 1L)
check_true("v82",
           "and that one mention is the join, inside @emlPluginRoot",
           sum(grepl('^\\s*\\.abs\\$\\s*=\\s*preferencesDirectory\\$\\s*\\+',
                     code_r)) == 1L)
check_true("v82", "and eml-record.praat carries no relative include of its own",
           !any(grepl("^\\s*include\\s", code_r)))

check_true("v82", "setup.praat includes the module that defines the resolver",
           any(grepl("^include stats/eml-record\\.praat\\s*$", code_s)))
check_true("v82", "setup.praat calls @emlPluginRoot rather than resolving again",
           any(grepl("^\\s*@emlPluginRoot\\s*$", code_s)) &&
           any(grepl("emlSetupRoot\\$\\s*=\\s*emlPluginRoot\\.root\\$", code_s)))
# THE WRITE TARGET COMES FROM THE SAME ANSWER. This is the one that decides
# whether a launch produces a barrel at all: setup.praat computing its own
# path lands the write in a folder that need not exist, and a failed write is
# unchecked here on purpose, so the whole feature disappears with Praat
# exiting 0 and nothing said.
check_true("v82",
           sprintf("setup.praat mentions preferencesDirectory$ nowhere (%d)",
                   pd(code_s)),
           pd(code_s) == 0L)
check_true("v82", "and takes the file it writes from emlPluginRoot.abs$",
           any(grepl("emlSetupPath\\$\\s*=\\s*emlPluginRoot\\.abs\\$", code_s)))
check_true("v82", "setup.praat names the generated barrel",
           any(grepl("scripts/eml-lib-user\\.praat", code_s)))
# THE COMPARISON BEFORE THE WRITE, IN THE SOURCE. Section 3 drives it; this
# reads it, because a launch that happened not to differ would pass section 3
# with the comparison deleted.
check_true("v82", "the write is guarded by a comparison against the file on disk",
           any(grepl("emlSetupOnDisk\\$\\s*=\\s*readFile\\$", code_s)) &&
           any(grepl("if\\s+emlSetupOnDisk\\$\\s*<>\\s*emlSetupText\\$", code_s)))
check_true("v82", "and the write is the only one, inside that guard",
           sum(grepl("writeFile", code_s)) == 1L)
# THE MODULES ARE WRITTEN DOWN IN setup.praat, in order.
mods_s <- regmatches(code_s,
    regexpr('(stats|graphs)/eml-[a-z-]+\\.praat', code_s))
mods_s <- mods_s[nzchar(mods_s)]
mods_s <- mods_s[mods_s != "stats/eml-record.praat" |
                 seq_along(mods_s) > 1]
check_true("v82", "setup.praat's module table is the canonical order",
           identical(unname(mods_s[mods_s %in% CANON])[seq_along(CANON)], CANON))

# ---------------------------------------------------------------------------
# 7. SELF-HEALING: THE PLUGIN MOVED
# ---------------------------------------------------------------------------
# The installed folder, barrel and all, is copied to a preferences folder with
# a different name under the same home -- what a user does when they move a
# Praat installation. The barrel that travels with it names the old folder.
if (canDrive) {
    home3 <- file.path(work, "s3", "home")
    old3 <- file.path(home3, ".praat-dir")
    install(home3, old3)
    launch(home3, old3)
    new3 <- file.path(home3, "moved-prefs")
    dir.create(new3, showWarnings = FALSE, recursive = TRUE)
    file.copy(file.path(old3, "plugin_EML_StatsGraphs"), new3,
              recursive = TRUE, copy.date = TRUE)
    bp <- file.path(new3, "plugin_EML_StatsGraphs", BARREL)
    check_true("v82", "the barrel that travelled names the old folder",
               file.exists(bp) &&
               any(grepl("^include ~/\\.praat-dir/", readLines(bp, warn = FALSE))))
    launch(home3, new3)
    inc3 <- includes_of(bp)
    check_true("v82",
               "a launch at the new location regenerates every line for it",
               length(inc3) == length(CANON) &&
               all(startsWith(inc3, "~/moved-prefs/plugin_EML_StatsGraphs/")))
    u <- file.path(work, "s3", "user")
    dir.create(u, recursive = TRUE, showWarnings = FALSE)
    writeLines(c("include ~/moved-prefs/plugin_EML_StatsGraphs/scripts/eml-lib-user.praat",
                 "@emlInitializeDrawingDefaults",
                 'writeInfoLine: "MOVED BARREL RAN"'), file.path(u, "m.praat"))
    r <- launch(home3, new3, file.path(u, "m.praat"))
    check_true("v82", "and the repaired barrel runs from a user's folder",
               r$status == 0L && grepl("MOVED BARREL RAN", r$out, fixed = TRUE))
}

# ---------------------------------------------------------------------------
# 8. SELF-HEALING: THE PREFERENCES FOLDER PRAAT ITSELF MOVED
# ---------------------------------------------------------------------------
# 6.x keeps its preferences in ~/.praat-dir and 7.x in ~/.config/praat, both
# measured on this machine. A user who upgrades and carries their plugin
# across arrives with a barrel naming the 6.x folder.
if (canDrive) {
    home4 <- file.path(work, "s4", "home")
    old4 <- file.path(home4, ".praat-dir")
    install(home4, old4)
    launch(home4, old4)
    new4 <- file.path(home4, ".config", "praat")
    dir.create(new4, showWarnings = FALSE, recursive = TRUE)
    file.copy(file.path(old4, "plugin_EML_StatsGraphs"), new4,
              recursive = TRUE, copy.date = TRUE)
    bp <- file.path(new4, "plugin_EML_StatsGraphs", BARREL)
    check_true("v82", "the barrel carried into the 7.x folder still names the 6.x one",
               file.exists(bp) &&
               any(grepl("^include ~/\\.praat-dir/", readLines(bp, warn = FALSE))))
    launch(home4, new4)
    inc4 <- includes_of(bp)
    check_true("v82",
               "a launch on the 7.x preferences folder regenerates for it",
               length(inc4) == length(CANON) &&
               all(startsWith(inc4, "~/.config/praat/plugin_EML_StatsGraphs/")))
    u <- file.path(work, "s4", "user")
    dir.create(u, recursive = TRUE, showWarnings = FALSE)
    writeLines(c("include ~/.config/praat/plugin_EML_StatsGraphs/scripts/eml-lib-user.praat",
                 "@emlInitializeDrawingDefaults",
                 'writeInfoLine: "V7 BARREL RAN"'), file.path(u, "m.praat"))
    r <- launch(home4, new4, file.path(u, "m.praat"))
    check_true("v82", "and that barrel runs from a user's folder too",
               r$status == 0L && grepl("V7 BARREL RAN", r$out, fixed = TRUE))
}

# ---------------------------------------------------------------------------
# 9. THE GENERATED FILE IS NOT A REPOSITORY FILE
# ---------------------------------------------------------------------------
# It is written into whatever folder the plugin is installed in, and on a
# development machine that folder can be this working tree -- harness/walks
# symlinks the repository into a preferences directory. A generated,
# machine-specific barrel committed alongside the shipped ones would be a
# fourth barrel in scripts/ that no other machine's paths match.
#
# The repository is read here by repo_path and not through $EML_PLUGIN_SRC: a
# break test points that at a shadow tree, and a shadow tree is not a git
# checkout, so reading it would turn this section red for a reason that has
# nothing to do with what it is about.
repo <- repo_path(".")
# THE PATH GIT IS ASKED ABOUT IS THE REAL FOLDER. `plugin` beside it is a
# symlink to plugin_EML_StatsGraphs, and git refuses a pathspec that goes
# through one -- check-ignore exits 128 with "beyond a symbolic link", and
# ls-files silently returns nothing, which would make the second check below
# pass whatever is tracked. Both questions are about git's own namespace, so
# both are asked in git's own spelling.
PLUGIN_DIR <- "plugin_EML_StatsGraphs"
ign <- suppressWarnings(system2("git",
    c("-C", shQuote(repo), "check-ignore", "-q",
      shQuote(file.path(PLUGIN_DIR, BARREL))), stdout = TRUE, stderr = TRUE))
ign_status <- attr(ign, "status"); if (is.null(ign_status)) ign_status <- 0L
check_true("v82", "the generated barrel is git-ignored",
           ign_status == 0L)
tracked <- suppressWarnings(system2("git",
    c("-C", shQuote(repo), "ls-files",
      shQuote(file.path(PLUGIN_DIR, BARREL))), stdout = TRUE, stderr = TRUE))
check_true("v82", "and no copy of it is tracked",
           length(tracked) == 0L || !any(nzchar(tracked)))

eml_claim("v82", "generated_barrel", CANON)

if (!exists("EML_SUITE")) {
    eml_report("v82 generated barrel: the one include line, written at launch")
    eml_exit()
}
