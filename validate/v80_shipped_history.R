# ============================================================================
# v80_shipped_history.R -- a shipped file describes what the code does, never
# what it used to do wrong
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS FILE EXISTS
#
# AUTHOR RULING, pre-release. Defect and change history lives in git and in
# the developer ledger. It does not live in the header of a file a user
# installs. The reason is not tidiness. A header that says "v1.19: the
# undefined error is tested explicitly. Previously the guard was on .nGroups"
# makes two claims at once -- one about today's code and one about a version
# nobody has -- and a reader six months from now cannot tell which sentence
# they are reading. The narration also decays in a way the code cannot: the
# code is exercised by this suite on every run, and the sentence about what
# the code used to be is exercised by nothing, so it is the one part of the
# file that can be wrong indefinitely without anything going red.
#
# WHY THIS IS A LINT AND NOT A REVIEW. The sweep that removed this material
# spans 34 files and roughly 1,400 lines of comment. Completeness of a sweep
# that size cannot be established by reading, because the failure mode of
# reading is a missed line, and a missed line looks exactly like a line that
# was considered and kept. It can be established by a predicate. So the sweep
# is DONE when this file is green, and stays done because this file then
# stands guard: any future fix that writes its own history into a shipped
# header turns the suite red in the same commit that wrote it.
#
# WHAT COUNTS AS SHIPPED. plugin/, minus plugin/dev/. dev/ is the developer
# tree -- tests, tools, retired experiments, and the history ledger itself --
# and is not installed. Its headers may narrate freely; that is where the
# narration was moved TO.
#
# WHAT IS EXAMINED IN A SHIPPED FILE. In a .praat file, comment lines only: a
# string literal that happens to contain "used to" is code the plugin prints,
# not a note to a reader, and rewriting a user-facing message to satisfy a
# lint would be the lint damaging the product. In the shipped prose files
# (.md, .txt, .csv) there is no comment syntax and no code, so every line is
# examined -- those files are nothing but statements to a reader.
#
# THE PATTERN LIST IS SHARED WITH THE CAPTURE TOOL, AND THE SHARING IS
# CHECKED. plugin/dev/tools/extract-history.py copied this material into
# dev/HISTORY_LEDGER.md before it was deleted, and it used the same ten
# patterns to decide what a history block was. If the two lists drift, the
# guarantee the sweep rests on -- everything the lint would reject was first
# captured verbatim -- quietly stops holding. There is no file both R and
# Python can import, so this script re-derives the Python list out of the
# tool's source and asserts the two are identical.
#
# EXCEPTIONS ARE A FILE, NOT A CONDITION. validate/v80_history_allowlist.tsv
# carries path, line-pattern and a one-line justification. Legitimate prose
# that collides with a pattern -- almost always by naming a developer file
# whose NAME contains one -- is excused there, deliberately and in writing.
# An entry that matches nothing is reported as a FAILURE: a stale exception
# tells a reader the tree still holds a line it does not, and stands ready to
# excuse some future line on a justification written about another one.
#
#     Rscript validate/v80_shipped_history.R
#
# Input: the source tree only. No harness artefact, no Praat.
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

ROOT <- repo_path(".")
plug <- Sys.getenv("EML_PLUGIN_DIR", unset = "")
if (!nzchar(plug)) plug <- repo_path("plugin")
ALLOW <- Sys.getenv("EML_V80_ALLOWLIST", unset = "")
if (!nzchar(ALLOW)) ALLOW <- repo_path("validate", "v80_history_allowlist.tsv")
TOOL <- file.path(plug, "dev", "tools", "extract-history.py")

# ---------------------------------------------------------------------------
# THE TEN PATTERNS
# ---------------------------------------------------------------------------
# Written here exactly as the tool writes them, character for character, so
# the agreement check below is a string comparison and not an interpretation.
PATTERNS <- c(
    "v\\d+\\.\\d+:",      # a version-stamped change entry
    "item \\d+ -",        # an audit item number
    "no longer",
    "used to",
    "previously",
    "was broken",
    "changed meaning",
    "deprecat",           # deprecated / deprecation
    "CHANGELOG",
    "FIX_NOTES"
)

# ---------------------------------------------------------------------------
# 1. THE PATTERN LIST MATCHES THE CAPTURE TOOL'S
# ---------------------------------------------------------------------------
py_patterns <- character(0)
if (file.exists(TOOL)) {
    src <- readLines(TOOL, warn = FALSE)
    a <- grep("^PATTERNS = \\[", src)
    b <- grep("^\\]", src)
    if (length(a) && any(b > a[1])) {
        body <- src[(a[1] + 1L):(min(b[b > a[1]]) - 1L)]
        body <- grep('^\\s*r"', body, value = TRUE)
        py_patterns <- sub('^\\s*r"(.*)",.*$', "\\1", body)
    }
}
check_true("v80",
           sprintf("the lint's patterns are the capture tool's (%d here, %d in extract-history.py)",
                   length(PATTERNS), length(py_patterns)),
           length(py_patterns) == length(PATTERNS) &&
           all(py_patterns == PATTERNS))

# ---------------------------------------------------------------------------
# 2. EVERY PATTERN STILL FIRES
# ---------------------------------------------------------------------------
# A pattern that has been broken into never matching would leave this file
# green forever while the rule it names went unenforced -- the same vacuity
# v78 was written about. Each pattern is fired here against a line built to
# match it and only it, so a regex that has stopped working is named.
controls <- c("# v1.19: the guard moved",
              "# item 7 - the cap was added",
              "# this row no longer exists",
              "# the sort used to run inline",
              "# previously hard-coded",
              "# the estimator was broken for n = 1",
              "# the argument changed meaning in the k-group arm",
              "# deprecated: use @emlDrawBoxPlot",
              "# see CHANGELOG for the rest",
              "# see FIX_NOTES.md item 3")
dead <- character(0)
for (i in seq_along(PATTERNS)) {
    if (!grepl(PATTERNS[i], controls[i], perl = TRUE)) {
        dead <- c(dead, PATTERNS[i])
    }
}
check_true("v80",
           sprintf("every history pattern fires on its own control line (%s)",
                   if (length(dead)) paste(dead, collapse = ", ") else "10/10"),
           length(dead) == 0)
# And the other way: a line of ordinary design prose must match NONE of them,
# or the lint would reject the very sentences the ruling says must survive.
innocent <- c("# fixed$ is not a fixed-precision formatter: it returns a bare",
              "# Praat does not short-circuit `and`, so both arms evaluate.",
              "# Praat will not remove a Table's only row.")
false_pos <- innocent[vapply(innocent, function(l)
    any(vapply(PATTERNS, function(p) grepl(p, l, perl = TRUE), logical(1))),
    logical(1))]
check_true("v80",
           sprintf("ordinary design prose matches no pattern (%s)",
                   if (length(false_pos)) paste(false_pos, collapse = " | ")
                   else "3 control sentences clean"),
           length(false_pos) == 0)

# ---------------------------------------------------------------------------
# 3. THE ALLOWLIST PARSES
# ---------------------------------------------------------------------------
allow <- data.frame(path = character(0), pattern = character(0),
                    why = character(0), stringsAsFactors = FALSE)
allow_ok <- file.exists(ALLOW)
if (allow_ok) {
    raw <- readLines(ALLOW, warn = FALSE)
    raw <- raw[!grepl("^\\s*#", raw) & nzchar(trimws(raw))]
    if (length(raw)) {
        parts <- strsplit(raw, "\t", fixed = TRUE)
        good <- vapply(parts, function(p) length(p) >= 3L && all(nzchar(trimws(p[1:3]))),
                       logical(1))
        allow_ok <- all(good)
        parts <- parts[good]
        if (length(parts)) {
            allow <- data.frame(
                path    = vapply(parts, function(p) trimws(p[1]), character(1)),
                pattern = vapply(parts, function(p) p[2], character(1)),
                why     = vapply(parts, function(p) trimws(p[3]), character(1)),
                stringsAsFactors = FALSE)
        }
    }
}
check_true("v80",
           sprintf("the allowlist parses as path/pattern/justification (%s, %d entries)",
                   basename(ALLOW), nrow(allow)),
           allow_ok)
# EVERY ENTRY CARRIES A REASON A READER CAN USE. "legacy" is not a reason.
thin <- allow$path[nchar(allow$why) < 40]
check_true("v80",
           sprintf("every allowlist entry justifies itself in a sentence (%s)",
                   if (length(thin)) paste(thin, collapse = ", ") else "all do"),
           length(thin) == 0)
# EVERY ENTRY NAMES A FILE THAT EXISTS. A path typo would produce an entry
# that can never match, which the staleness check below would report -- but
# it would report it as "the line was cleaned up", which is the wrong story.
missing_path <- allow$path[!file.exists(file.path(ROOT, allow$path))]
check_true("v80",
           sprintf("every allowlist entry names a file in the tree (%s)",
                   if (length(missing_path)) paste(missing_path, collapse = ", ")
                   else "all present"),
           length(missing_path) == 0)

# ---------------------------------------------------------------------------
# 4. THE SCAN
# ---------------------------------------------------------------------------
PROSE <- c("md", "txt", "csv")
CODEY <- c("praat")
files <- list.files(plug, recursive = TRUE, all.files = FALSE, no.. = TRUE)
files <- files[!grepl("^dev/", files)]
files <- files[!grepl("(^|/)__pycache__/", files)]
files <- files[!grepl("(^|/)\\.", files)]
ext <- tolower(sub(".*\\.", "", files))
files <- files[ext %in% c(PROSE, CODEY)]

is_comment <- function(x) grepl("^\\s*[#;]", x)

hits <- data.frame(path = character(0), line = integer(0), text = character(0),
                   stringsAsFactors = FALSE)
n_examined <- 0L
for (rel in files) {
    src <- readLines(file.path(plug, rel), warn = FALSE)
    if (!length(src)) next
    idx <- if (tolower(sub(".*\\.", "", rel)) %in% CODEY) which(is_comment(src))
           else seq_along(src)
    n_examined <- n_examined + length(idx)
    for (i in idx) {
        if (any(vapply(PATTERNS, function(p) grepl(p, src[i], perl = TRUE),
                       logical(1)))) {
            hits <- rbind(hits, data.frame(path = file.path("plugin", rel),
                                           line = i, text = src[i],
                                           stringsAsFactors = FALSE))
        }
    }
}

# THE SCAN MUST HAVE HAPPENED. Both figures are asserted because a walk that
# found no files and a walk that found files with no comments both produce
# "no violations", and neither is the same statement as "the tree is clean".
check_true("v80",
           sprintf("the scan walked the shipped tree (%d files)", length(files)),
           length(files) >= 25)
check_true("v80",
           sprintf("the scan examined lines (%d comment or prose lines)", n_examined),
           n_examined >= 2000)

# ---------------------------------------------------------------------------
# 5. THE VERDICT
# ---------------------------------------------------------------------------
excused <- rep(FALSE, nrow(hits))
used <- rep(FALSE, nrow(allow))
breadth <- integer(nrow(allow))
if (nrow(hits) && nrow(allow)) {
    for (h in seq_len(nrow(hits))) {
        for (a in seq_len(nrow(allow))) {
            if (hits$path[h] == allow$path[a] &&
                grepl(allow$pattern[a], hits$text[h], perl = TRUE)) {
                excused[h] <- TRUE
                used[a] <- TRUE
                breadth[a] <- breadth[a] + 1L
            }
        }
    }
}
bad <- hits[!excused, , drop = FALSE]
name_hits <- function(df, n = 8L) {
    if (!nrow(df)) return("none")
    shown <- utils::head(df, n)
    s <- paste(sprintf("%s:%d: %s", shown$path, shown$line,
                       substr(trimws(shown$text), 1, 70)), collapse = " | ")
    if (nrow(df) > n) s <- paste0(s, sprintf(" | ... and %d more", nrow(df) - n))
    s
}
check_true("v80",
           sprintf("no shipped file narrates its own history (%d violation%s: %s)",
                   nrow(bad), if (nrow(bad) == 1L) "" else "s", name_hits(bad)),
           nrow(bad) == 0)

# EVERY ALLOWLIST ENTRY IS EARNING ITS PLACE. Reported separately from the
# violations because it is the opposite failure: not a line that slipped
# through, but an exception nobody withdrew.
stale <- if (nrow(allow)) allow$path[!used] else character(0)
stale_p <- if (nrow(allow)) allow$pattern[!used] else character(0)
check_true("v80",
           sprintf("no allowlist entry is stale (%s)",
                   if (length(stale))
                       paste(sprintf("%s ~ /%s/ matches nothing", stale, stale_p),
                             collapse = "; ")
                   else sprintf("all %d entries matched", nrow(allow))),
           length(stale) == 0)

# NO ENTRY IS A BLANKET. An over-broad pattern -- "." in the pattern column,
# say -- would excuse every line in its file, every other check here would
# still pass, and the lint would be off for that file with nothing saying so.
# An exception is written about a LINE; an entry standing over more than a
# handful of them is not an exception, it is an opt-out. The excused lines
# are named in the message either way, so a reader of the suite output sees
# what the tree is being forgiven without opening the allowlist.
wide <- if (nrow(allow)) allow$path[breadth > 5L] else character(0)
check_true("v80",
           sprintf("no allowlist entry blankets its file (%s | excused: %s)",
                   if (length(wide)) paste(wide, collapse = ", ")
                   else sprintf("widest covers %d line(s)",
                                if (length(breadth)) max(breadth) else 0L),
                   name_hits(hits[excused, , drop = FALSE])),
           length(wide) == 0)

# ---------------------------------------------------------------------------
# 6. THE HISTORY WENT SOMEWHERE
# ---------------------------------------------------------------------------
# The rule is "move it", not "delete it". If the ledger disappears, every
# check above still passes and the ruling has been half-obeyed in the
# direction that loses the material, so the ledger's presence is asserted
# here rather than assumed.
ledger <- file.path(plug, "dev", "HISTORY_LEDGER.md")
led <- if (file.exists(ledger)) readLines(ledger, warn = FALSE) else character(0)
check_true("v80",
           sprintf("dev/HISTORY_LEDGER.md holds the captured history (%d lines)",
                   length(led)),
           length(led) >= 1000)
# It must carry BOTH captures. The pre-sweep tree is where the material the
# 16 August sweeps removed lives; a ledger built from HEAD alone would look
# complete and be missing all of it.
check_true("v80",
           "the ledger carries both the pre-sweep capture and the HEAD capture",
           sum(grepl("^# CAPTURE:", led)) >= 2)
check_true("v80",
           "the ledger stamps every block with the commit it came from",
           sum(grepl("^## .+ @ [0-9a-f]{7}", led)) >= 100)
check_true("v80",
           "FIX_NOTES.md was moved into dev/, not deleted",
           file.exists(file.path(plug, "dev", "FIX_NOTES.md")) &&
           !file.exists(file.path(plug, "FIX_NOTES.md")))

if (!exists("EML_SUITE")) { eml_report("v80 — shipped files do not narrate history"); eml_exit() }
