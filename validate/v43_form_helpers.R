# ============================================================================
# v43_form_helpers.R -- the graphs form's own helpers, asserted
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS FILE EXISTS. Three procedures sit inside eml-graphs-form.praat,
# are called only from inside it, and until 13 August 2026 had no test of any
# kind. Not because they need a display -- none of them does -- but because
# the 7000 lines around them do, so nothing had ever loaded that file outside
# a live dialog.
#
# @emlGenerateUniquePath IS THE NON-DESTRUCTIVE-SAVE PROMISE. Every save in
# the plugin routes through it: the figure, the separately-saved legend, the
# CSV export, the recorded workflow script. Its entire job is that an existing
# file is never silently overwritten. Nothing in the tree asserted that. A
# regression here does not produce a red test or a wrong number -- it destroys
# a figure the user drew an hour ago, and the user is the one who finds out.
#
# @emlGraphsCSVDefaultName names the CSV export, and its slug rules are the
# reason an analysis called "Cohen's d / one-way" cannot put a path separator
# into a filename.
#
# @emlGraphsCSVRowAnalysis is the RFC 4180 field-2 reader underneath it. It
# walks the row honouring quoting rather than splitting on commas, because a
# user's table may legitimately be named with a comma in it -- which quotes
# field 1 and shifts every later field for any reader that counts naively.
#
# THE TWO ROUTES TO THE SAME FILENAME. `fromClipboard_results` is produced
# both by a clipboard with no analysis and by a clipboard whose analysis the
# parser failed to read. The filename cannot tell them apart, so the parser is
# probed directly as well -- section 4 exists because section 3 cannot see the
# difference between correct and broken.
#
#     bash harness/formhelpers/run.sh     regenerate the input
#     Rscript validate/v43_form_helpers.R
#
# Input: <dir>/FORMHELPERS.tsv, four fields, no header:
#            case  kind  result  exists
#        kind is uniq | csv | row; exists is 0/1 for uniq and NA otherwise.
#        <dir> is $EML_FORMHELPERS_DIR, default harness/formhelpers/out. A
#        missing artefact is a HARD STOP, not a skip.
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

fh_dir <- Sys.getenv("EML_FORMHELPERS_DIR", unset = "")
if (!nzchar(fh_dir)) fh_dir <- repo_path("harness", "formhelpers", "out")
fh_p <- file.path(fh_dir, "FORMHELPERS.tsv")

if (!file.exists(fh_p)) {
    stop("form-helper artefact not found: ", fh_p,
         "\n  Run: bash harness/formhelpers/run.sh")
}

# quote = "" IS LOAD-BEARING. The row_escaped case's result is  say "ah" test
# -- a literal double quote is the thing being measured, and R's default
# quoting would eat it and silently merge fields.
fh <- read.delim(fh_p, header = FALSE, stringsAsFactors = FALSE,
                 quote = "", comment.char = "",
                 col.names = c("case", "kind", "result", "exists"))
fh$result[is.na(fh$result)] <- ""

CASES <- c("free", "collide1", "collide2", "collide3", "noext", "dotted",
           "dotfile",
           "csv_fallback", "csv_clipboard", "csv_analysis", "csv_slug",
           "csv_shortrow",
           "row_plain", "row_quotedtable", "row_escaped", "row_tail",
           "row_short")
eml_census("v43", "form-helper case", fh$case, CASES)
eml_claim("v43", "formhelpers_out", CASES)
check("v43", "every declared case was driven", nrow(fh), length(CASES),
      tol = 0)

.g <- function(nm) fh$result[match(nm, fh$case)]
.k <- function(nm) fh$kind[match(nm, fh$case)]

# All three procedures were reached. A driver that fell over after the first
# section would still satisfy every check below on the cases it did reach.
check("v43", "the unique-path procedure was driven", 7L,
      sum(fh$kind == "uniq"), tol = 0)
check("v43", "the CSV-name procedure was driven", 5L,
      sum(fh$kind == "csv"), tol = 0)
check("v43", "the row parser was driven directly", 5L,
      sum(fh$kind == "row"), tol = 0)

# ---------------------------------------------------------------------------
# 1. THE PROMISE. Everything else in this section is detail; this is the
#    property the procedure exists to hold.
# ---------------------------------------------------------------------------
# Measured in Praat, at the moment of the call, against the real directory --
# the validator never sees that tree, and a name checked any later would be
# checking a stale world.
uniq <- fh[fh$kind == "uniq", ]
check_true("v43", "no returned path was already on disk",
           all(uniq$exists == "0"))

# THE CONTROL. Without it, a procedure that appended _1 to everything would
# pass every collision check below while being wrong on the common case.
check_true("v43", "free: an unused name is returned untouched",
           .g("free") == "fig.png")

check_true("v43", "collide1: one collision takes the _1 suffix",
           .g("collide1") == "taken_1.png")

# THE COUNTER WALKS. A procedure that only ever tried _1 would hand back
# walk_1.png -- a name that also exists -- which is the exact failure the
# promise forbids, and it would still pass collide1.
check_true("v43", "collide2: _1 taken as well, so the counter advances",
           .g("collide2") == "walk_2.png")
check_true("v43", "collide3: the counter iterates rather than stopping at _2",
           .g("collide3") == "deep_3.png")

# THE SUFFIX GOES BEFORE THE EXTENSION, not after it. A png that came back as
# fig.png_1 would not open, and the save dialog would not warn.
check_true("v43", "every collided name keeps its original extension",
           all(grepl("\\.png$", c(.g("collide1"), .g("collide2"),
                                  .g("collide3")))))

# ---------------------------------------------------------------------------
# 2. WHERE THE NAME IS SPLIT, which is the part with branches in it
# ---------------------------------------------------------------------------
check_true("v43", "noext: with no extension the suffix lands at the end",
           .g("noext") == "noext_1")

# ONLY THE LAST DOT IS THE EXTENSION. Splitting on the first would give
# my_1.data.csv, which is a different file in a different format.
check_true("v43", "dotted: my.data.csv becomes my.data_1.csv",
           .g("dotted") == "my.data_1.csv")
check_true("v43", "dotted: the split did not take the first dot",
           .g("dotted") != "my_1.data.csv")

# THE BOUNDARY, RECORDED AS ONE. A leading-dot name has rindex at position 1,
# so left$(name, 0) leaves the base empty and the whole name is extension:
# ".hidden" -> "_1.hidden". Cosmetically odd. The promise still holds (checked
# above, on disk), and the plugin's save dialogs never offer a bare-extension
# name, so this is documented rather than fixed -- but it is asserted, so a
# future edit to the split cannot change it without saying so.
check_true("v43", "dotfile: the leading-dot boundary is where it was",
           .g("dotfile") == "_1.hidden")

# ---------------------------------------------------------------------------
# 3. THE EXPORT FILENAME
# ---------------------------------------------------------------------------
# The false arm of the variableExists guard -- a fresh session, nothing on the
# clipboard, which is the state the first export of the day actually runs in.
check_true("v43", "csv_fallback: with no clipboard the caller's name is used",
           .g("csv_fallback") == "voiceA_results")
check_true("v43", "csv_clipboard: a clipboard table overrides the fallback",
           .g("csv_clipboard") == "fromClipboard_results")
check_true("v43", "csv_analysis: the analysis is slugged into the name",
           .g("csv_analysis") == "fromClipboard_One-way_ANOVA")

# THE SLUG RULES, all three at once: spaces to underscores, slash to hyphen,
# apostrophe dropped. The slash rule is not cosmetic -- an analysis named
# "Cohen's d / one-way" would otherwise write a path separator into a
# filename, and the save would land somewhere the user did not choose.
check_true("v43", "csv_slug: spaces, slash and apostrophe are all handled",
           .g("csv_slug") == "fromClipboard_Cohens_d_-_one-way")
csvn <- fh$result[fh$kind == "csv"]
check_true("v43", "no suggested filename contains a path separator",
           !any(grepl("[/\\\\]", csvn)))
check_true("v43", "no suggested filename contains a space or an apostrophe",
           !any(grepl("[ ']", csvn)))

# A MALFORMED ROW must fall back rather than slug the whole row into the name.
check_true("v43", "csv_shortrow: a row with no fields falls back",
           .g("csv_shortrow") == "fromClipboard_results")

# ---------------------------------------------------------------------------
# 4. THE PARSER, PROBED DIRECTLY -- see the header. csv_clipboard and
#    csv_shortrow are the same string by two different routes, and only these
#    checks can tell a working parser from one that returns "" for everything.
# ---------------------------------------------------------------------------
check_true("v43", "row_plain: field 2 is the analysis",
           .g("row_plain") == "One-way ANOVA")

# THE CASE WITH TEETH. Field 1 is quoted and contains a comma. A splitter
# returns " take 2" here; the whole reason this is a walker and not a split.
check_true("v43", "row_quotedtable: a comma inside quoted field 1 shifts nothing",
           .g("row_quotedtable") == "Pearson r")
check_true("v43", "row_quotedtable: and it did not return the shifted field",
           .g("row_quotedtable") != " take 2")

# RFC 4180's doubled quote is one literal quote, and the field does not end
# at it.
check_true("v43", "row_escaped: a doubled quote is one quote, mid-field",
           .g("row_escaped") == "say \"ah\" test")

# THE TAIL BRANCH, after the while loop: the row ends inside field 2 with no
# trailing comma, so the loop never sees the separator that would commit it.
check_true("v43", "row_tail: a row ending inside field 2 still yields it",
           .g("row_tail") == "Pearson r")

check_true("v43", "row_short: fewer than two fields yields empty",
           .g("row_short") == "")

# AND THE TWO ROUTES ARE DISTINGUISHED, which is this section's reason to
# exist: a parser stuck at "" would make section 3 pass unchanged.
check_true("v43", "an empty result is not the parser's answer to everything",
           nzchar(.g("row_plain")) && nzchar(.g("row_tail")) &&
           nzchar(.g("row_quotedtable")))

if (!exists("EML_SUITE")) {
    eml_report("v43 form helpers: the non-destructive-save promise, asserted")
    eml_exit()
}
